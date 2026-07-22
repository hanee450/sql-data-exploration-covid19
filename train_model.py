from pathlib import Path

import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OrdinalEncoder, StandardScaler
import joblib


def load_dataset(csv_path: Path) -> pd.DataFrame:
    df = pd.read_csv(csv_path, parse_dates=["date"])
    return df


def prepare_data(df: pd.DataFrame):
    df = df.copy()
    df["continent"] = df["continent"].fillna("Unknown")
    df["population"] = df["population"].fillna(df["population"].median())

    df["year"] = df["date"].dt.year
    df["month"] = df["date"].dt.month
    df["day"] = df["date"].dt.day

    target = "new_cases"
    df = df[df[target].notna()].reset_index(drop=True)

    features = [
        "continent",
        "location",
        "population",
        "total_cases",
        "total_deaths",
        "year",
        "month",
        "day",
    ]

    X = df[features]
    y = df[target]
    return X, y


def build_pipeline():
    numeric_features = ["population", "total_cases", "total_deaths", "year", "month", "day"]
    categorical_features = ["continent", "location"]

    numeric_transformer = Pipeline(
        [
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ]
    )

    categorical_transformer = Pipeline(
        [
            ("imputer", SimpleImputer(strategy="constant", fill_value="Unknown")),
            (
                "encoder",
                OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1),
            ),
        ]
    )

    preprocessor = ColumnTransformer(
        [
            ("numeric", numeric_transformer, numeric_features),
            ("categorical", categorical_transformer, categorical_features),
        ]
    )

    pipeline = Pipeline(
        [
            ("preprocessor", preprocessor),
            (
                "model",
                RandomForestRegressor(
                    n_estimators=100,
                    max_depth=12,
                    random_state=42,
                    n_jobs=-1,
                ),
            ),
        ]
    )
    return pipeline


import numpy as np

def evaluate_model(model, X_test, y_test):
    y_pred = model.predict(X_test)
    print("Evaluation results")
    print("------------------")
    print(f"MAE: {mean_absolute_error(y_test, y_pred):.2f}")
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    print(f"RMSE: {rmse:.2f}")
    print(f"R2: {r2_score(y_test, y_pred):.4f}")


def main():
    project_root = Path(__file__).resolve().parent
    dataset_path = project_root / "Dataset" / "covid_deaths_clean.csv"

    if not dataset_path.exists():
        raise FileNotFoundError(f"Dataset not found at {dataset_path}")

    df = load_dataset(dataset_path)
    X, y = prepare_data(df)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)

    evaluate_model(pipeline, X_test, y_test)

    model_path = project_root / "covid_new_cases_model.joblib"
    joblib.dump(pipeline, model_path)
    print(f"Saved trained model to {model_path}")


if __name__ == "__main__":
    main()
