#!/usr/bin/env python3
"""Predict NativeLens riskLevel values from a dataset CSV."""

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path

import joblib


FEATURE_COLUMNS = [
    "batteryLevel",
    "isCharging",
    "isPowerSaveMode",
    "networkConnected",
    "networkValidated",
    "networkMetered",
    "hasHevcEncoder",
    "maxRefreshRate",
    "cameraCount",
    "sensorCount",
    "codecCount",
    "overallScore",
]

BOOLEAN_FEATURES = {
    "isCharging",
    "isPowerSaveMode",
    "networkConnected",
    "networkValidated",
    "networkMetered",
    "hasHevcEncoder",
}

TARGET_COLUMN = "riskLevel"
MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "risk_model.joblib"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Predict NativeLens riskLevel values from a dataset CSV.",
    )
    parser.add_argument("csv_path", help="Path to the NativeLens dataset CSV file.")
    return parser.parse_args()


def parse_bool(value: str) -> float:
    normalized = value.strip().lower()
    if normalized == "true":
        return 1.0
    if normalized == "false":
        return 0.0
    raise ValueError(f"expected boolean string, got {value!r}")


def parse_feature(column: str, value: str) -> float:
    if column in BOOLEAN_FEATURES:
        return parse_bool(value)

    return float(value)


def row_to_features(row: dict[str, str], feature_columns: list[str]) -> list[float]:
    return [parse_feature(column, row[column]) for column in feature_columns]


def load_model(model_path: Path) -> tuple[object, list[str]]:
    if not model_path.is_file():
        raise FileNotFoundError(
            "Model file not found: "
            f"{model_path}\n"
            "Run training first:\n"
            "python3 ml/scripts/train_risk_model.py "
            "ml/dataset/sample_native_lens_dataset.csv"
        )

    model_bundle = joblib.load(model_path)
    if isinstance(model_bundle, dict):
        model = model_bundle.get("model")
        feature_columns = model_bundle.get("feature_columns", FEATURE_COLUMNS)
        return model, list(feature_columns)

    return model_bundle, FEATURE_COLUMNS


def predict_rows(csv_path: Path, model: object, feature_columns: list[str]) -> int:
    if not csv_path.is_file():
        raise FileNotFoundError(f"Dataset not found: {csv_path}")

    prediction_distribution: Counter[str] = Counter()
    predicted_rows = 0

    with csv_path.open(newline="", encoding="utf-8") as dataset_file:
        reader = csv.DictReader(dataset_file)
        fieldnames = reader.fieldnames or []
        missing_columns = [
            column for column in feature_columns if column not in fieldnames
        ]

        if missing_columns:
            missing = ", ".join(missing_columns)
            raise ValueError(f"Missing required feature columns: {missing}")

        print("predictions:")
        for row_number, row in enumerate(reader, start=2):
            try:
                features = row_to_features(row, feature_columns)
            except (KeyError, ValueError) as error:
                print(f"row {row_number}: skipped ({error})")
                continue

            predicted_label = str(model.predict([features])[0])
            actual_label = row.get(TARGET_COLUMN, "").strip()
            actual_text = actual_label if actual_label else "not provided"

            print(
                f"row {row_number}: "
                f"predicted riskLevel={predicted_label}, "
                f"actual riskLevel={actual_text}"
            )
            prediction_distribution[predicted_label] += 1
            predicted_rows += 1

    print("prediction distribution:")
    for label, count in sorted(prediction_distribution.items()):
        print(f"- {label}: {count}")

    return predicted_rows


def main() -> int:
    args = parse_args()

    try:
        model, feature_columns = load_model(MODEL_PATH)
        predicted_rows = predict_rows(Path(args.csv_path), model, feature_columns)
    except (FileNotFoundError, OSError, ValueError, csv.Error) as error:
        print(error, file=sys.stderr)
        return 1

    if predicted_rows == 0:
        print("No rows were available for prediction.", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
