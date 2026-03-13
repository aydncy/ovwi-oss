# OVWI Server

Append-only, audit-ready workflow and API gateway platform built with Dart + Shelf.

## Features

- Ed25519 cryptographic signing
- Hash chain validation
- Immutable event log
- Verifiable workflow execution
- API Gateway for backend services
- Request analytics
- Rate limiting
- Developer authentication

## Installation

cd ovwi_server
dart pub get
dart run bin/server.dart

## Endpoints

/health
/api/v1/dashboard/stats
/api/v1/gateway/patients
/api/workflow
/webhook/purchase

## License

MIT License
