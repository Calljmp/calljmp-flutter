## 0.0.7

- **Enhanced Real-time & Observer API Improvements**
  - Added configurable heartbeat functionality and auto-disconnect settings
  - Implemented sequential message sending queue for better reliability

## 0.0.6

- **Real-time Features & Type Safety Improvements**
  - Added comprehensive real-time database subscriptions with `database.observe()`
  - Implemented real-time pub/sub messaging with `realtime.observe()`
  - Enhanced type safety with event-specific observers and strongly-typed filters
  - Added WebSocket communication layer with auto-reconnection
  - Implemented type-safe filter system with sealed class hierarchy
  - Added structured event data classes for database and realtime events
  - Removed UUID dependency in favor of native platform UUID generation
  - Comprehensive API cleanup and organization
  - All lint warnings and compilation issues resolved

## 0.0.5

- **Storage Enhancements**
  - Updated storage parameters to remove uuid.

## 0.0.4

- **Apple and Google Authentication**
  - Added support for Apple and Google authentication
  - New methods: `calljmp.users.auth.apple.authenticate()` and `calljmp.users.auth.google.authenticate()`

## 0.0.3

- **Bug Fixes & Improvements**
  - Extended storage functionality
  - Updated documentation for better clarity

## 0.0.2

- **Documentation & Package Improvements**
  - Enhanced package description and metadata
  - Improved code formatting and documentation

## 0.0.1

- **Initial release** of Calljmp Flutter SDK - Secure backend-as-a-service for mobile developers
- **Authentication System**
  - Email/password authentication with `calljmp.users.auth.email.authenticate()`
  - Support for user creation and sign-in policies
  - User tagging system for roles and permissions
  - User retrieval functionality with `calljmp.users.retrieve()`
- **Security & App Attestation**
  - App Attestation support for iOS devices
  - Play Integrity API support for Android devices
  - No API keys required - attestation-based security model
  - Integrity verification with `calljmp.integrity.access()` and `calljmp.integrity.authenticated()`
- **Database Access**
  - Full SQLite database control with raw SQL queries
  - Execute any SQL statement with `calljmp.database.query()`
  - Support for parameterized queries for security
  - No database restrictions or limitations
- **Custom Service Integration**
  - HTTP client for custom service endpoints
  - Fluent API with `calljmp.service.request().get().json()`
  - Support for custom backend deployments
- **Storage Management**
  - File upload functionality with `calljmp.storage.upload()`
  - File retrieval with `calljmp.storage.retrieve()`
  - File metadata updates with `calljmp.storage.update()`
  - File deletion with `calljmp.storage.delete()`
  - Support for buckets, content types, descriptions, and tags
- **Project Management**
  - Project connection handling with `calljmp.project.connect()`
  - Development mode support for local testing
  - Configurable service endpoints
- **Flutter Integration**
  - Native Flutter SDK with async/await support
  - Type-safe API responses
  - Comprehensive error handling
  - Easy installation via pub.dev
