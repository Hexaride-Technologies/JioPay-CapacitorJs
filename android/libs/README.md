Place the proprietary `jio_payments_sdk.aar` (obtained from JioPay) here as
`jio_payments_sdk.aar`.

This directory is referenced by `android/build.gradle` via a `flatDir` repo +
`fileTree`/`files(...)` dependency. The AAR itself is not committed to this
repo (see root `.gitignore`) because JioPay's SDK is licensed per-merchant
and must not be redistributed.
