# Contributing to OVWI & ClinicFlowAC

Thank you for interest in contributing to our healthcare platform!

## Getting Started

### Prerequisites
- Dart SDK 3.0+
- PostgreSQL 14+
- Docker (for local development)
- Git

### Development Setup
```bash
# Clone repository
git clone https://github.com/aydncy/ovwi-oss.git
cd ovwi-oss

# Install dependencies
dart pub get

# Run tests
dart test

# Start development server
dart run bin/server.dart
```

### Code Style
- Follow Dart style guide
- Use meaningful variable names
- Write self-documenting code
- Add comments for complex logic
- Maximum 80 characters per line

### Testing Requirements
- Write unit tests for new functions
- Achieve 80%+ code coverage
- Test error scenarios
- Test edge cases

### Pull Request Process

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Reporting Bugs

Use GitHub Issues with:
- Clear description
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details

### Suggesting Features

Use GitHub Discussions with:
- Use case description
- Benefits for healthcare providers
- Potential implementation approach

### Code of Conduct

Be respectful, inclusive, and professional. We're building tools for global healthcare.

---

**Help us build the future of healthcare!**
