# Calljmp Flutter SDK

**Secure backend-as-a-service for mobile developers. No API keys. Full SQLite control.**

[![pub version](https://img.shields.io/pub/v/calljmp_flutter)](https://pub.dev/packages/calljmp_flutter)
[![GitHub license](https://img.shields.io/github/license/Calljmp/calljmp-flutter)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-blue)](https://flutter.dev/)

## 🚀 Overview

Calljmp is a **secure backend designed for mobile developers**, providing:

- ✅ **Authentication** via **App Attestation (iOS)** and **Play Integrity (Android)**
- ✅ **Full SQLite database access** (no restrictions, run raw SQL)
- ✅ **Dynamic permissions** for users & roles
- ✅ **Flutter SDK** for seamless integration

🔹 **Website**: [calljmp.com](https://calljmp.com)  
🔹 **Follow**: [@calljmpdev](https://x.com/calljmpdev)

---

## 📦 Installation

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

## 🛠️ Setup & Usage

### 1️⃣ Initialize Calljmp

Import and initialize Calljmp in your Flutter app:

```dart
import 'package:calljmp/calljmp.dart';

final calljmp = Calljmp();
```

### 2️⃣ Authenticate User

Authenticate a user with Calljmp:

```dart
final auth = await calljmp.users.auth.email.authenticate(
  email: 'test@email.com',
  name: 'Tester',
  password: 'password',
  policy: UserAuthenticationPolicy.signInOrCreate,
  tags: ['role:member'],
);

if (auth.error != null) {
  print(auth.error);
  return;
}

final user = auth.data.user;
print('Authenticated user: $user');
```

### 3️⃣ Run Direct SQL Queries

Access your SQLite database without restrictions:

```dart
final result = await calljmp.database.query(
  sql: 'SELECT id, email, auth_provider, provider_user_id, tags, created_at FROM users',
  params: [],
);

if (result.error != null) {
  print(result.error);
  return;
}

print(result.data);
```

### 4️⃣ Access service

If you are deploying your own service, you can access it via the `service` property.

```typescript
// ./src/services/main.ts

import { Service } from './service';

const service = Service();

service.get('/hello', async c => {
  return c.json({
    message: 'Hello, world!',
  });
});

export default service;
```

Then in your Flutter app, you can call the service like this:

```dart
// ./lib/main.dart

final result = await calljmp.service
    .request('/hello')
    .get()
    .json<Map<String, dynamic>>();

if (result.error != null) {
  print(result.error);
  return;
}

print(result.data);
```

## 🔒 Security & App Attestation

Calljmp does not use API keys. Instead, it relies on App Attestation (iOS) and Play Integrity (Android) to verify that only legitimate apps can communicate with the backend.

For more details, check the [Apple App Attestations docs](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity) and/or [Google Play Integrity docs](https://developer.android.com/google/play/integrity).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support & Community

If you have any questions or feedback:

- Follow [@calljmpdev](https://x.com/calljmpdev)
- Join the [Calljmp Discord](https://discord.gg/DHsrADPUC6)
- Open an issue in the [GitHub repo](https://github.com/Calljmp/calljmp-flutter/issues)
