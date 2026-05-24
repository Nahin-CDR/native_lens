#!/usr/bin/env python3
"""Validate NativeLens CSV datasets before ML training."""

import argparse
import csv
import sys
from collections import Counter
from pathlib import Path


REQUIRED_COLUMNS = [
    "schemaVersion",
    "platform",
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
    "riskLevel",
    "labelSource",
    "createdAtMillis",
]

ALLOWED_PLATFORMS = {"android", "ios"}
ALLOWED_RISK_LEVELS = {"low", "medium", "high", "unknown"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate a NativeLens CSV dataset.",
    )
    parser.add_argument("csv_path", help="Path to the NativeLens dataset CSV file.")
    return parser.parse_args()


def int_in_range(value: str, minimum: int, maximum: int) -> bool:
    try:
        number = int(value)
    except ValueError:
        return False

    return minimum <= number <= maximum


def positive_int(value: str) -> bool:
    try:
        number = int(value)
    except ValueError:
        return False

    return number > 0


def validate_row(row: dict[str, str], row_number: int) -> list[str]:
    errors: list[str] = []

    platform = row.get("platform", "")
    if platform not in ALLOWED_PLATFORMS:
        errors.append(
            f"row {row_number}: platform must be one of "
            f"{sorted(ALLOWED_PLATFORMS)}"
        )

    risk_level = row.get("riskLevel", "")
    if risk_level not in ALLOWED_RISK_LEVELS:
        errors.append(
            f"row {row_number}: riskLevel must be one of "
            f"{sorted(ALLOWED_RISK_LEVELS)}"
        )

    if not int_in_range(row.get("batteryLevel", ""), 0, 100):
        errors.append(f"row {row_number}: batteryLevel must be 0-100")

    if not int_in_range(row.get("overallScore", ""), 0, 100):
        errors.append(f"row {row_number}: overallScore must be 0-100")

    if not positive_int(row.get("createdAtMillis", "")):
        errors.append(f"row {row_number}: createdAtMillis must be greater than 0")

    return errors


def validate_dataset(csv_path: Path) -> int:
    if not csv_path.is_file():
        print(f"Dataset not found: {csv_path}", file=sys.stderr)
        return 2

    total_rows = 0
    valid_rows = 0
    invalid_rows = 0
    risk_distribution: Counter[str] = Counter()
    all_errors: list[str] = []

    try:
        with csv_path.open(newline="", encoding="utf-8") as dataset_file:
            reader = csv.DictReader(dataset_file)
            fieldnames = reader.fieldnames or []
            missing_columns = [
                column for column in REQUIRED_COLUMNS if column not in fieldnames
            ]

            if missing_columns:
                print("Missing required columns:")
                for column in missing_columns:
                    print(f"- {column}")
                return 1

            for row_number, row in enumerate(reader, start=2):
                total_rows += 1
                row_errors = validate_row(row, row_number)
                risk_level = row.get("riskLevel", "")

                if risk_level in ALLOWED_RISK_LEVELS:
                    risk_distribution[risk_level] += 1

                if row_errors:
                    invalid_rows += 1
                    all_errors.extend(row_errors)
                    continue

                valid_rows += 1
    except csv.Error as error:
        print(f"CSV read error: {error}", file=sys.stderr)
        return 2
    except OSError as error:
        print(f"Unable to read dataset: {error}", file=sys.stderr)
        return 2

    print(f"total rows: {total_rows}")
    print(f"valid rows: {valid_rows}")
    print(f"invalid rows: {invalid_rows}")
    print("riskLevel distribution:")
    for risk_level in sorted(ALLOWED_RISK_LEVELS):
        print(f"- {risk_level}: {risk_distribution[risk_level]}")

    if all_errors:
        print("validation errors:")
        for error in all_errors:
            print(f"- {error}")

    return 1 if invalid_rows else 0


def main() -> int:
    args = parse_args()
    return validate_dataset(Path(args.csv_path))


if __name__ == "__main__":
    raise SystemExit(main())
