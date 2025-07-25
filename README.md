# Calljmp Flutter SDK

**Secure backend-as-a-service for mobile developers. No API keys. Full SQLite control.**

[![pub version](https://img.shields.io/pub/v/calljmp)](https://pub.dev/packages/calljmp)
[![GitHub license](https://img.shields.io/github/license/Calljmp/calljmp-flutter)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-blue)](https://flutter.dev/)

## Overview

**Calljmp** is a secure backend-as-a-service designed for mobile developers. The **Flutter SDK** provides seamless integration with Calljmp services for your Flutter applications.

### Key Features

- **Authentication** via **App Attestation (iOS)** and **Play Integrity (Android)**
- **Full SQLite database access** with no restrictions - run raw SQL
- **Secure cloud storage** with organized bucket management
- **Real-time database subscriptions** for live data updates
- **Dynamic permissions** for users & roles
- **OAuth integration** (Apple, Google, and more)
- **Custom service endpoints** for your business logic

**Website**: [calljmp.com](https://calljmp.com)  
**Documentation**: [docs.calljmp.com](https://docs.calljmp.com)  
**Follow**: [@calljmpdev](https://x.com/calljmpdev)

---

## Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  calljmp: ^latest
```

Then run:

```sh
flutter pub get
```

---

## Getting Started

Initialize Calljmp in your Flutter app and start using its features:

```dart
import 'package:calljmp/calljmp.dart';

final calljmp = Calljmp();
```

### Available Features

- **User Authentication**: Email/password, OAuth providers (Apple, Google)
- **Database Operations**: Direct SQLite queries, real-time subscriptions
- **Cloud Storage**: File upload, download, metadata management
- **Custom Services**: Call your own backend endpoints
- **Security**: App Attestation and Play Integrity verification

For detailed usage examples, API reference, and comprehensive guides, visit our [documentation](https://docs.calljmp.com).

## Security & App Attestation

Calljmp doesn't use API keys. Instead, it relies on **App Attestation (iOS)** and **Play Integrity (Android)** to verify that only legitimate apps can communicate with the backend.

Learn more about security in our [documentation](https://docs.calljmp.com/security).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support & Community

If you have any questions or feedback:

- Follow [@calljmpdev](https://x.com/calljmpdev)
- Join the [Calljmp Discord](https://discord.gg/DHsrADPUC6)
- Open an issue in the [GitHub repo](https://github.com/Calljmp/calljmp-flutter/issues)
