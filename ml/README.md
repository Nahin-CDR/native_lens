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
pipelines. The current scripts are intentionally small and local-first; no
production AI model is added yet.

The included CSV rows are fake demo samples only. They must not be treated as
real device telemetry or personal data.

For real-device checks and local dataset collection guidance, see
`REAL_DEVICE_TESTING.md`.

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

## Risk Model Training

Install the ML dependencies from the dedicated ML requirements file:

```sh
python3 -m pip install -r ml/requirements.txt
```

Train a simple local `riskLevel` model from a NativeLens CSV dataset:

```sh
python3 ml/scripts/train_risk_model.py ml/dataset/sample_native_lens_dataset.csv
```

The training script saves the generated model to `ml/models/risk_model.joblib`.
Generated `.joblib` model files are ignored by git.

Train first, then run predictions against a NativeLens CSV dataset:

```sh
python3 ml/scripts/train_risk_model.py ml/dataset/sample_native_lens_dataset.csv
python3 ml/scripts/predict_risk.py ml/dataset/sample_native_lens_dataset.csv
```

Evaluate the trained model against labeled dataset rows:

```sh
python3 ml/scripts/evaluate_model.py ml/dataset/sample_native_lens_dataset.csv
```

The current sample dataset is demo-only and intentionally tiny. Real accuracy
and predictions require a larger, representative NativeLens dataset before the
model should be used for meaningful decisions.
