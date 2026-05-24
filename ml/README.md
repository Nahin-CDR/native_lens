# NativeLens ML Workspace

This folder is a lightweight workspace for future NativeLens AI/ML training work.
It currently contains documentation and a small sample dataset template only.

## Dataset Template

The sample CSV at `dataset/sample_native_lens_dataset.csv` shows the stable
columns expected from `NativeLensDatasetRow`. Each row represents a NativeLens
snapshot with platform, battery, power, network, media, camera, sensor, codec,
score, risk, label, and creation timestamp fields.

The CSV column names match the field names emitted by `NativeLensDatasetRow`
and `NativeLensDatasetExporter`:

```text
schemaVersion,platform,batteryLevel,isCharging,isPowerSaveMode,networkConnected,networkValidated,networkMetered,hasHevcEncoder,maxRefreshRate,cameraCount,sensorCount,codecCount,overallScore,riskLevel,labelSource,createdAtMillis
```

## Current Status

This workspace prepares the repository for future AI/ML experiments and training
pipelines. No AI model, training code, Python environment, or extra dependency is
added yet.

The included CSV rows are fake demo samples only. They must not be treated as
real device telemetry or personal data.

## Dataset Validation

Validation is required before future ML training so malformed CSV files, missing
schema fields, out-of-range scores, invalid platform values, and invalid risk
labels are caught before they can affect experiments or model quality.

Run the standard-library validation script against a dataset CSV:

```sh
python3 ml/scripts/validate_dataset.py ml/dataset/sample_native_lens_dataset.csv
```

The script reports total rows, valid rows, invalid rows, and the `riskLevel`
distribution. It does not train a model or add any Python dependencies.
