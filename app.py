import logging
import os
from datetime import datetime
from pathlib import Path
import json

import joblib
import pandas as pd
from flask import Flask, render_template, request, send_from_directory, abort

app = Flask(__name__, template_folder="templates", static_folder="static")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parent
MODEL_PATH = PROJECT_ROOT / "covid_new_cases_model.joblib"
DATASET_PATH = PROJECT_ROOT / "Dataset" / "covid_deaths_clean.csv"


def load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Model file not found at {MODEL_PATH}. Run `python train_model.py` first."
        )
    return joblib.load(MODEL_PATH)


def load_dataset():
    if not DATASET_PATH.exists():
        raise FileNotFoundError(f"Dataset file not found at {DATASET_PATH}.")
    df = pd.read_csv(DATASET_PATH, parse_dates=["date"])
    required_columns = {
        "location", "continent", "date", "population",
        "total_cases", "total_deaths", "new_cases", "new_deaths",
    }
    missing = required_columns - set(df.columns)
    if missing:
        raise ValueError(f"Dataset is missing required columns: {sorted(missing)}")
    return df


def build_country_presets(df: pd.DataFrame):
    latest = df.sort_values(["location", "date"]).groupby("location").last().reset_index()
    presets = {}
    for _, row in latest.iterrows():
        presets[row["location"]] = {
            "continent": row["continent"] if pd.notna(row["continent"]) else "Unknown",
            "population": int(row["population"] if pd.notna(row["population"]) else 0),
            "total_cases": int(row["total_cases"] if pd.notna(row["total_cases"]) else 0),
            "total_deaths": int(row["total_deaths"] if pd.notna(row["total_deaths"]) else 0),
        }
    return presets


# Fail fast with a clear message at startup rather than a raw traceback
# halfway through import — this matters once the app is run under a
# process manager (gunicorn, systemd) where a bare crash trace is easy to miss.
try:
    df_data = load_dataset()
    COUNTRIES = sorted(df_data["location"].dropna().unique())
    CONTINENTS = sorted(df_data["continent"].dropna().unique())
    COUNTRY_PRESETS = build_country_presets(df_data)
    model = load_model()
except (FileNotFoundError, ValueError) as exc:
    logger.error("Startup failed: %s", exc)
    raise SystemExit(1) from exc


@app.route("/", methods=["GET"])
@app.route("/home", methods=["GET"])
def home():
    latest_by_country = (
        df_data.sort_values(["location", "date"]).groupby("location", as_index=False).last()
    )
    summary = {
        "countries": latest_by_country["location"].nunique(),
        "total_cases": int(latest_by_country["total_cases"].fillna(0).sum()),
        "total_deaths": int(latest_by_country["total_deaths"].fillna(0).sum()),
        "first_date": str(df_data["date"].min().date()),
        "last_date": str(df_data["date"].max().date()),
    }
    return render_template("home.html", summary=summary)


@app.route("/dashboard", methods=["GET"])
def dashboard():
    selected_continent = request.args.get("continent", "All")
    start_date = request.args.get("start_date", str(df_data["date"].min().date()))
    end_date = request.args.get("end_date", str(df_data["date"].max().date()))

    try:
        start = pd.to_datetime(start_date)
        end = pd.to_datetime(end_date)
        if pd.isna(start) or pd.isna(end):
            raise ValueError("Unparseable date")
    except (ValueError, TypeError):
        logger.info("Invalid date range %r-%r, falling back to full range", start_date, end_date)
        start = df_data["date"].min()
        end = df_data["date"].max()
        start_date, end_date = str(start.date()), str(end.date())

    # Swap silently if the user submitted an inverted range, instead of
    # returning an empty dataset with no explanation.
    if end < start:
        start, end = end, start
        start_date, end_date = str(start.date()), str(end.date())

    filtered = df_data[(df_data["date"] >= start) & (df_data["date"] <= end)].copy()
    if selected_continent != "All":
        filtered = filtered[filtered["continent"] == selected_continent]

    latest_by_country = (
        filtered.sort_values(["location", "date"]).groupby("location", as_index=False).last()
    )

    total_cases = int(latest_by_country["total_cases"].fillna(0).sum())
    total_deaths = int(latest_by_country["total_deaths"].fillna(0).sum())
    death_rate = round(total_deaths / total_cases * 100, 1) if total_cases else 0.0

    chart_data = {
        "top_cases": latest_by_country.nlargest(6, "total_cases")[
            ["location", "total_cases"]
        ].to_dict(orient="records"),
        "top_deaths": latest_by_country.nlargest(6, "total_deaths")[
            ["location", "total_deaths"]
        ].to_dict(orient="records"),
        "continent_deaths": (
            latest_by_country.groupby("continent", as_index=False)["total_deaths"]
            .sum()
            .sort_values("total_deaths", ascending=False)
            .to_dict(orient="records")
        ),
        "recent_trend": {
            "labels": filtered["date"].dt.strftime("%b %d").unique().tolist()[-20:],
            # .fillna(0) added here too — previously missing, so a date where
            # every row's new_cases was NaN made .sum() return NaN, and
            # .astype(int) on a NaN crashes with "cannot convert float NaN
            # to integer". The new_deaths line below already had this guard;
            # new_cases didn't, so it was one bad data day away from a 500.
            "cases": filtered.groupby("date")["new_cases"].sum().sort_index().fillna(0).astype(int).tolist()[-20:],
            "deaths": filtered.groupby("date")["new_deaths"].sum().sort_index().fillna(0).astype(int).tolist()[-20:],
        },
    }

    table_data = latest_by_country[
        ["location", "continent", "total_cases", "total_deaths"]
    ].sort_values("total_cases", ascending=False).head(20).to_dict(orient="records")

    totals = {
        "total_cases_str": f"{total_cases:,}",
        "total_deaths_str": f"{total_deaths:,}",
        "death_rate": f"{death_rate}",
        "country_count": latest_by_country["location"].nunique(),
    }

    return render_template(
        "dashboard.html",
        continents=CONTINENTS,
        chart_data=chart_data,
        table_data=table_data,
        totals=totals,
        start_date=start_date,
        end_date=end_date,
    )


def _parse_positive_float(raw_value, fallback, field_name):
    """Parse a form value as a non-negative float, raising a clear,
    user-facing error instead of a bare ValueError/TypeError string."""
    if raw_value in (None, ""):
        return fallback
    try:
        value = float(raw_value)
    except (TypeError, ValueError):
        raise ValueError(f"{field_name} must be a number.")
    if value < 0:
        raise ValueError(f"{field_name} cannot be negative.")
    return value


@app.route("/predict", methods=["GET", "POST"])
def predict():
    result = None
    error = None
    values = {
        "country": "India",
        "continent": "Asia",
        "location": "India",
        "population": 1400000000,
        "total_cases": 45000000,
        "total_deaths": 530000,
        "date": datetime.today().strftime("%Y-%m-%d"),
    }

    if request.method == "POST":
        try:
            selected_country = request.form.get("country", "India") or "India"
            values["country"] = selected_country
            values["location"] = selected_country
            values["continent"] = request.form.get("continent", values["continent"]) or values["continent"]
            values["population"] = _parse_positive_float(
                request.form.get("population"), values["population"], "Population"
            )
            values["total_cases"] = _parse_positive_float(
                request.form.get("total_cases"), values["total_cases"], "Total cases"
            )
            values["total_deaths"] = _parse_positive_float(
                request.form.get("total_deaths"), values["total_deaths"], "Total deaths"
            )
            values["date"] = request.form.get("date") or values["date"]

            try:
                date = datetime.fromisoformat(values["date"])
            except ValueError:
                raise ValueError("Date must be in YYYY-MM-DD format.")

            features = pd.DataFrame([
                {
                    "continent": values["continent"],
                    "location": values["location"],
                    "population": values["population"],
                    "total_cases": values["total_cases"],
                    "total_deaths": values["total_deaths"],
                    "year": date.year,
                    "month": date.month,
                    "day": date.day,
                }
            ])

            predicted = model.predict(features)[0]
            result = max(0, int(round(predicted)))
        except ValueError as exc:
            # Expected, user-facing validation errors — safe to show as-is.
            error = str(exc)
        except Exception:
            # Anything else (model errors, unexpected shapes, etc.) is
            # logged with a full trace for debugging, but the user only
            # sees a generic message — the old code showed str(exc)
            # straight from any exception, which can leak internal details
            # (file paths, library internals) to the browser.
            logger.exception("Prediction failed")
            error = "Something went wrong while generating the prediction. Please check your inputs and try again."

    return render_template(
        "index.html",
        result=result,
        error=error,
        values=values,
        countries=COUNTRIES,
        continents=CONTINENTS,
        presets=json.dumps(COUNTRY_PRESETS),
    )


@app.route("/results/<path:filename>")
def serve_results(filename):
    results_folder = PROJECT_ROOT / "Results"
    target = results_folder / filename
    if not target.exists() or not target.is_file():
        abort(404)
    return send_from_directory(results_folder, filename)


@app.route("/data")
def data_file():
    return send_from_directory(PROJECT_ROOT / "Dataset", "covid_deaths_clean.csv", as_attachment=False)


@app.route("/sql")
def sql_file():
    return send_from_directory(PROJECT_ROOT / "SQL Script", "Project 2 Data Exploration.sql", as_attachment=False)


@app.errorhandler(404)
def not_found(_exc):
    return "Page not found.", 404


@app.errorhandler(500)
def server_error(exc):
    logger.exception("Unhandled server error", exc_info=exc)
    return "Something went wrong on our end. Please try again shortly.", 500


if __name__ == "__main__":
    # debug=True enables Werkzeug's interactive debugger, which allows
    # arbitrary code execution from the browser if the app is reachable by
    # anyone else — dangerous combined with host="0.0.0.0" (all interfaces).
    # Both are now driven by environment variables so the safe defaults
    # (debug off) apply unless explicitly opted into for local development.
    debug_mode = os.environ.get("FLASK_DEBUG", "0") == "1"
    host = os.environ.get("FLASK_HOST", "127.0.0.1" if debug_mode else "0.0.0.0")
    port = int(os.environ.get("PORT", 5000))
    app.run(host=host, port=port, debug=debug_mode)
    