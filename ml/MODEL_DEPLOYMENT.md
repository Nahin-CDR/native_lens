# NativeLens ML Model Deployment Strategy

NativeLens currently works without an ML model. The package uses rule-based
compatibility analysis to generate scores, risk levels, reports, and dataset
rows. The ML scripts in this folder are for local research and development
workflows around dataset validation, model training, prediction, and evaluation.

The generated model file at `ml/models/risk_model.joblib` is created locally and
is intentionally ignored by git. It should not be committed yet because the
current dataset is small and demo-level. A committed model would imply a level of
quality and stability that the dataset does not support.

The current training script uses scikit-learn and writes a `joblib` model.
`joblib` models cannot run directly inside Flutter mobile apps, so deployment
needs a separate strategy before any user-facing ML prediction is added.

## Option A: Server-Side ML

1. Flutter generates or exports a `NativeLensDatasetRow`.
2. The app sends the row, or selected capability fields, to a backend.
3. The backend loads `ml/models/risk_model.joblib`.
4. The backend returns the predicted `riskLevel`.

This is the best fit for the current scikit-learn workflow because Python,
scikit-learn, and `joblib` are natural backend tools.

## Option B: On-Device ML

1. Convert or export the trained model to a mobile-friendly format.
2. Load that model from Flutter or the native Android/iOS layer.
3. Run prediction locally on the device.

For a very small model, another option is to implement simple trained rules in
Dart once the rule shape is proven. This is best for offline prediction, but it
requires a mobile-compatible model format or a carefully reviewed Dart
implementation.

## Option C: Dev/Research Tool Only

Keep the ML scripts as local tools for dataset analysis, experimentation, and
quality checks. NativeLens can continue to ship rule-based compatibility analysis
while ML work matures separately.

This is the safest option until a larger real-device dataset exists and model
quality can be measured more seriously.

## Ollama Explanation Plan

Ollama is not for training the NativeLens risk model. It can be useful later for
explaining predictions in natural language, such as turning a predicted
`riskLevel` and key device signals into a short developer-friendly explanation.

Ollama could run locally during development or server-side in a future workflow.
It should explain model outputs or rule-based results, not replace the dataset
training process.
