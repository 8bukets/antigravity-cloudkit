# Contributing

Thanks for contributing to Antigravity CloudKit! This project uses placeholder identifiers by default. Before submitting a PR or running tests on CI, ensure the following:

- Replace iCloud container placeholder identifiers with a real container in DataController.swift and entitlements.
- Do NOT commit your private provisioning profiles or Apple credentials.
- Tests run on macOS GitHub Actions runners using the iOS simulator; some iCloud features require a real device.

If you add features, update BEST_PRACTICES.md accordingly.
