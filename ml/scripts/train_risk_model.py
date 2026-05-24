#!/usr/bin/env python3
"""Train a simple NativeLens riskLevel prediction model."""

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path

import joblib
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier


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
        description="Train a NativeLens riskLevel prediction model.",
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


def row_to_features(row: dict[str, str]) -> list[float]:
    return [parse_feature(column, row[column]) for column in FEATURE_COLUMNS]


def load_dataset(csv_path: Path) -> tuple[list[list[float]], list[str], Counter[str], int]:
    if not csv_path.is_file():
        raise FileNotFoundError(f"Dataset not found: {csv_path}")

    features: list[list[float]] = []
    labels: list[str] = []
    skipped_rows = 0
    label_distribution: Counter[str] = Counter()

    with csv_path.open(newline="", encoding="utf-8") as dataset_file:
        reader = csv.DictReader(dataset_file)
        fieldnames = reader.fieldnames or []
        required_columns = [*FEATURE_COLUMNS, TARGET_COLUMN]
        missing_columns = [
            column for column in required_columns if column not in fieldnames
        ]

        if missing_columns:
            missing = ", ".join(missing_columns)
            raise ValueError(f"Missing required columns: {missing}")

        for row_number, row in enumerate(reader, start=2):
            label = row[TARGET_COLUMN].strip().lower()

            if label == IGNORED_LABEL:
                skipped_rows += 1
                continue

            try:
                feature_values = row_to_features(row)
            except (KeyError, ValueError) as error:
                skipped_rows += 1
                print(f"skipping row {row_number}: {error}", file=sys.stderr)
                continue

            features.append(feature_values)
            labels.append(label)
            label_distribution[label] += 1

    return features, labels, label_distribution, skipped_rows


def print_training_summary(
    features: list[list[float]],
    labels: list[str],
    label_distribution: Counter[str],
    skipped_rows: int,
) -> None:
    print(f"total usable rows: {len(labels)}")
    print("features used:")
    for column in FEATURE_COLUMNS:
        print(f"- {column}")

    print("labels distribution:")
    for label, count in sorted(label_distribution.items()):
        print(f"- {label}: {count}")

    if skipped_rows:
        print(f"ignored/skipped rows: {skipped_rows}")

    if not features:
        print("train/test split result: skipped, no usable rows")


def run_train_test_split(features: list[list[float]], labels: list[str]) -> None:
    unique_labels = set(labels)
    if len(labels) < 4 or len(unique_labels) < 2:
        print("train/test split result: skipped, not enough usable rows")
        return

    train_features, test_features, train_labels, test_labels = train_test_split(
        features,
        labels,
        test_size=0.25,
        random_state=42,
    )
    split_model = DecisionTreeClassifier(random_state=42)
    split_model.fit(train_features, train_labels)
    predictions = split_model.predict(test_features)
    accuracy = accuracy_score(test_labels, predictions)

    print(
        "train/test split result: "
        f"train rows={len(train_labels)}, "
        f"test rows={len(test_labels)}, "
        f"accuracy={accuracy:.3f}"
    )


def train_model(features: list[list[float]], labels: list[str]) -> DecisionTreeClassifier:
    model = DecisionTreeClassifier(random_state=42)
    model.fit(features, labels)
    return model


def main() -> int:
    args = parse_args()
    csv_path = Path(args.csv_path)

    try:
        features, labels, label_distribution, skipped_rows = load_dataset(csv_path)
    except (FileNotFoundError, OSError, ValueError, csv.Error) as error:
        print(error, file=sys.stderr)
        return 1

    print_training_summary(features, labels, label_distribution, skipped_rows)
    if not features:
        return 1

    run_train_test_split(features, labels)

    model = train_model(features, labels)
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {
            "model": model,
            "feature_columns": FEATURE_COLUMNS,
            "target_column": TARGET_COLUMN,
        },
        MODEL_PATH,
    )
    print(f"saved model: {MODEL_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
