# Calljmp Flutter SDK

**Secure backend-as-a-service for mobile developers. No API keys. Full SQLite control.**

[![pub version](https://img.shields.io/pub/v/calljmp)](https://pub.dev/packages/calljmp)
[![GitHub license](https://img.shields.io/github/license/Calljmp/calljmp-flutter)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-blue)](https://flutter.dev/)

## 🚀 Overview

Calljmp is a **secure backend designed for mobile developers**, providing:

- ✅ **Authentication** via **App Attestation (iOS)** and **Play Integrity (Android)**
- ✅ **Full SQLite database access** (no restrictions, run raw SQL)
- ✅ **Secure file storage** with organized bucket management
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
final user = await calljmp.users.auth.email.authenticate(
  email: "test@email.com",
  name: "Tester",
  password: "password",
  policy: UserAuthenticationPolicy.signInOrCreate,
  tags: ["role:member"],
);

print(user);
```

### 3️⃣ Run Direct SQL Queries

Access your SQLite database without restrictions:

```dart
final result = await calljmp.database.query(
  sql: 'SELECT id, email, auth_provider, provider_user_id, tags, created_at FROM users',
);

print(result);
```

### 4️⃣ File Storage & Management

Calljmp provides secure cloud storage for your files with organized bucket management. Upload, download, and manage files with metadata, tags, and access controls.

```dart
// Upload a file from bytes
final file = await calljmp.storage.upload(
  content: imageBytes,
  contentType: MediaType('image', 'jpeg'),
  bucketId: 'user-uploads',
  key: 'profile/avatar.jpg',
  description: 'User profile picture',
  tags: ['profile', 'avatar'],
);

// Upload from file path
final document = await calljmp.storage.upload(
  filePath: '/path/to/document.pdf',
  bucketId: 'documents',
  key: 'contracts/agreement.pdf',
  tags: ['legal', 'contract'],
);

// Upload text content
final textFile = await calljmp.storage.upload(
  content: 'Hello, world!',
  contentType: MediaType('text', 'plain'),
  bucketId: 'text-files',
  key: 'messages/hello.txt',
);
```

#### List Files in a Bucket

```dart
final result = await calljmp.storage.list(
  bucketId: 'user-uploads',
  limit: 50,
  offset: 0,
  orderField: 'createdAt',
  orderDirection: 'desc',
);

print('Found ${result.files.length} files');
for (final file in result.files) {
  print('${file.key}: ${file.size} bytes, created ${file.createdAt}');
}
```

#### Download Files

```dart
// Get file metadata without downloading content
final fileInfo = await calljmp.storage.peek(
  bucketId: 'user-uploads',
  key: 'profile/avatar.jpg',
);
print('File size: ${fileInfo.size} bytes');

// Download file content
final stream = await calljmp.storage.retrieve(
  bucketId: 'user-uploads',
  key: 'profile/avatar.jpg',
);

// Convert to bytes for processing
final bytes = await stream.toBytes();
```

#### Update File Metadata

```dart
final updatedFile = await calljmp.storage.update(
  bucketId: 'user-uploads',
  key: 'profile/avatar.jpg',
  description: 'Updated profile picture',
  tags: ['profile', 'avatar', 'updated'],
);
```

#### Delete Files

```dart
await calljmp.storage.delete(
  bucketId: 'user-uploads',
  key: 'profile/avatar.jpg',
);
```

### 5️⃣ Access service

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

final message = await calljmp.service
  .request(route: "/hello")
  .get()
  .json((json) => json['message'] as String);

print(message);
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
