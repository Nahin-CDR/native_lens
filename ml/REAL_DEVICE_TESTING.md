# NativeLens Real Device Testing

NativeLens currently includes a fake, demo-only sample dataset. The demo rows are
useful for validating file formats and script workflows, but the resulting demo
accuracy is not meaningful yet.

Real device data is required before trusting ML results. Treat current model
training, prediction, and evaluation output as workflow checks only until the
dataset contains enough representative rows from actual devices.

## Android Checklist

1. Connect an Android device.
2. Enable USB debugging on the device.
3. Run the example app:

```sh
cd example
fvm flutter devices
fvm flutter run
```

4. Verify the dashboard loads.
5. Verify platform summary values.
6. Verify the compatibility score.
7. Verify the battery gauge.
8. Verify capability charts.
9. Verify network speed updates.
10. Verify Copy Dataset JSON.
11. Verify Copy Dataset CSV.

## iOS Checklist

Run the example app on an iOS real device or simulator:

```sh
cd example
fvm flutter devices
fvm flutter run
```

Verify the iOS-supported modules in the dashboard. NativeLens has foundation iOS
support, and some Android-deep modules safely fall back when the equivalent iOS
capability is not available.

## Dataset Collection Process

1. Run the example app on a real device.
2. Copy Dataset CSV from the dashboard.
3. Append copied rows into a local CSV file.
4. Suggested local file:

```text
ml/dataset/local_real_device_dataset.csv
```

Do not commit real local dataset files. Local real-device CSV files should stay
on your machine unless they have been reviewed and intentionally sanitized for a
specific sharing process.

## Suggested Dataset Size

- 20+ rows for smoke testing.
- 50-100 rows for demo training.
- 500+ rows for better ML quality.

## Privacy

Keep dataset collection capability- and risk-focused only. Do not collect
personal identifiers, user names, phone numbers, email addresses, precise
locations, device serial numbers, or other directly identifying values.
