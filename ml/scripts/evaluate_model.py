#!/usr/bin/env python3
"""Evaluate a trained NativeLens riskLevel model against a dataset CSV."""

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
IGNORED_LABEL = "unknown"
MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "risk_model.joblib"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate a trained NativeLens riskLevel model.",
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


def load_evaluation_rows(
    csv_path: Path,
    feature_columns: list[str],
) -> tuple[list[list[float]], list[str]]:
    if not csv_path.is_file():
        raise FileNotFoundError(f"Dataset not found: {csv_path}")

    features: list[list[float]] = []
    labels: list[str] = []

    with csv_path.open(newline="", encoding="utf-8") as dataset_file:
        reader = csv.DictReader(dataset_file)
        fieldnames = reader.fieldnames or []
        required_columns = [*feature_columns, TARGET_COLUMN]
        missing_columns = [
            column for column in required_columns if column not in fieldnames
        ]

        if missing_columns:
            missing = ", ".join(missing_columns)
            raise ValueError(f"Missing required columns: {missing}")

        for row_number, row in enumerate(reader, start=2):
            label = row[TARGET_COLUMN].strip().lower()
            if label == IGNORED_LABEL:
                continue

            try:
                feature_values = row_to_features(row, feature_columns)
            except (KeyError, ValueError) as error:
                print(f"skipping row {row_number}: {error}", file=sys.stderr)
                continue

            features.append(feature_values)
            labels.append(label)

    if not features:
        raise ValueError(
            "CSV has no usable rows. Provide rows with a non-unknown riskLevel "
            "and valid feature values."
        )

    return features, labels


def print_confusion_matrix(
    labels: list[str],
    predictions: list[str],
    all_labels: list[str],
) -> None:
    print("confusion matrix:")
    print("actual\\predicted," + ",".join(all_labels))
    for actual_label in all_labels:
        row_counts = [
            sum(
                1
                for actual, predicted in zip(labels, predictions)
                if actual == actual_label and predicted == predicted_label
            )
            for predicted_label in all_labels
        ]
        print(f"{actual_label}," + ",".join(str(count) for count in row_counts))


def print_evaluation(labels: list[str], predictions: list[str]) -> None:
    total_rows = len(labels)
    correct_rows = sum(
        1 for actual, predicted in zip(labels, predictions) if actual == predicted
    )
    accuracy = correct_rows / total_rows
    all_labels = sorted(set(labels) | set(predictions))
    per_label_total: Counter[str] = Counter(labels)
    per_label_correct: Counter[str] = Counter(
        actual
        for actual, predicted in zip(labels, predictions)
        if actual == predicted
    )

    print(f"total evaluated rows: {total_rows}")
    print(f"accuracy: {accuracy:.3f}")
    print("labels found:")
    for label in all_labels:
        print(f"- {label}")

    print("per-label correct/total:")
    for label in all_labels:
        print(f"- {label}: {per_label_correct[label]}/{per_label_total[label]}")

    print_confusion_matrix(labels, predictions, all_labels)


def main() -> int:
    args = parse_args()

    try:
        model, feature_columns = load_model(MODEL_PATH)
        features, labels = load_evaluation_rows(Path(args.csv_path), feature_columns)
        predictions = [str(prediction) for prediction in model.predict(features)]
    except (FileNotFoundError, OSError, ValueError, csv.Error) as error:
        print(error, file=sys.stderr)
        return 1

    print_evaluation(labels, predictions)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
