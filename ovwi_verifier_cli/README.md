# OVWI Verifier CLI

Command-line tool for verifying cryptographic proofs and audit trails.

## Features

- Proof verification
- Signature validation
- Hash chain verification
- Audit trail inspection
- Export capabilities

## Installation
```bash
cd ovwi_verifier_cli
dart pub get
dart run bin/verifier.dart
```

## Usage
```bash
dart run bin/verifier.dart verify <proof_file>
dart run bin/verifier.dart validate <signature>
dart run bin/verifier.dart audit <log_file>
```

## License

MIT License
