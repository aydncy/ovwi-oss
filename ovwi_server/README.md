# OVWI Server

Append-only, audit-ready workflow and API gateway platform built with Dart + Shelf.

## Features

- Ed25519 cryptographic signing
- Hash chain validation
- Immutable event log
- Verifiable workflow execution
- API Gateway for microservices
- Request analytics
- Rate limiting
- Audit-ready operations

## Installation

cd ovwi_server
dart pub get
dart run bin/server.dart

## Endpoints

/health - Health check  
/webhook/purchase - Purchase events  
/api/workflow - Workflow operations  

## License

MIT License
