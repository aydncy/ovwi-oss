# OVWI Server

Append-only audit-ready workflow engine.

## Features

- Ed25519 cryptographic signing
- Hash chain validation
- Immutable event log
- Verifiable workflow execution
- Audit-ready operations

## Installation
```bash
cd ovwi_server
dart pub get
dart run bin/server.dart
```

## Endpoints

- `/health` - Health check
- `/webhook/purchase` - Purchase events
- `/api/workflow` - Workflow operations

## License

MIT License
