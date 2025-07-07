/// The Calljmp Flutter SDK provides secure backend-as-a-service capabilities for mobile developers.
///
/// This SDK offers:
/// - Authentication via App Attestation (iOS) and Play Integrity (Android)
/// - Full SQLite database access with no restrictions
/// - Real-time database subscriptions and custom pub/sub messaging
/// - Dynamic permissions for users and roles
/// - Seamless Flutter integration
///
/// ## Getting Started
///
/// ```dart
/// import 'package:calljmp/calljmp.dart';
///
/// final calljmp = Calljmp();
///
/// // Type-safe database operations
/// final users = await calljmp.database.query(
///   sql: 'SELECT * FROM users WHERE age > ?',
///   params: [21],
/// );
///
/// // Real-time database subscriptions
/// final subscription = await calljmp.database.observe<User>('users.insert')
///   .onInsert((event) {
///     print('New users: ${event.rows}');
///   })
///   .filter(DatabaseGtFilter('age', 18))
///   .subscribe();
///
/// // Real-time pub/sub messaging
/// final rtSubscription = await calljmp.realtime.observe<Message>('chat.room1')
///   .onData((event) {
///     print('Message: ${event.data}');
///   })
///   .filter(RealtimeEqFilter('room_id', 'room123'))
///   .subscribe();
/// ```
///
/// For more information, visit [calljmp.com](https://calljmp.com)
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CORE SDK
// ═══════════════════════════════════════════════════════════════════════════════

/// Main Calljmp client - your entry point to all SDK functionality
export 'client.dart' show Calljmp;

/// Configuration classes for different environments and platforms
export 'config.dart'
    show ServiceConfig, AndroidConfig, DevelopmentConfig, Config;

// ═══════════════════════════════════════════════════════════════════════════════
// AUTHENTICATION & USERS
// ═══════════════════════════════════════════════════════════════════════════════

/// User management and authentication
export 'users/users.dart' show User, Users;
export 'users/auth.dart'
    show Auth, UserAuthenticationProvider, UserAuthenticationPolicy;
export 'users/email.dart' show Email;
export 'users/provider.dart' show Provider;

/// Access tokens and integrity verification
export 'access.dart' show AccessToken;
export 'integrity.dart' show Integrity;

// ═══════════════════════════════════════════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Main database service for SQL operations and real-time subscriptions
export 'database.dart' show Database;

/// Database type definitions and interfaces
export 'database_types.dart'
    show
        // Core types
        DatabaseRowId,
        DatabaseRow,
        DatabaseTable,
        DatabaseSubscriptionEvent,
        // Event data classes for real-time subscriptions
        DatabaseInsertEventData,
        DatabaseUpdateEventData,
        DatabaseDeleteEventData,
        // Handler types for event processing
        DatabaseInsertHandler,
        DatabaseUpdateHandler,
        DatabaseDeleteHandler,
        // Type-safe filter system
        DatabaseFilter,
        DatabaseEqFilter,
        DatabaseNeFilter,
        DatabaseGtFilter,
        DatabaseGteFilter,
        DatabaseLtFilter,
        DatabaseLteFilter,
        DatabaseInFilter,
        DatabaseLikeFilter,
        DatabaseAndFilter,
        DatabaseOrFilter,
        DatabaseNotFilter,
        // Subscription management
        DatabaseSubscription,
        DatabaseSubscriptionOptions,
        DatabaseObservePath,
        // Utility functions
        databaseFilterToJson;

// ═══════════════════════════════════════════════════════════════════════════════
// REALTIME & PUB/SUB
// ═══════════════════════════════════════════════════════════════════════════════

/// Real-time messaging and pub/sub functionality
export 'realtime.dart' show Realtime, RealtimeObserver;

/// Realtime type definitions and interfaces
export 'realtime_types.dart'
    show
        // Core types
        RealtimeTopic,
        // Event classes for real-time data
        RealtimeDataEvent,
        RealtimeErrorEvent,
        // Handler types for event processing
        RealtimeDataHandler,
        RealtimeErrorHandler,
        RealtimeEventHandler,
        // Observer types for type-safe event handling
        RealtimeObserverEvent,
        // Type-safe filter system
        RealtimeFilter,
        RealtimeEqFilter,
        RealtimeNeFilter,
        RealtimeInFilter,
        RealtimeGtFilter,
        RealtimeGteFilter,
        RealtimeLtFilter,
        RealtimeLteFilter,
        RealtimeLikeFilter,
        RealtimeIlikeFilter,
        RealtimeRegexFilter,
        RealtimeExistsFilter,
        RealtimeAndFilter,
        RealtimeOrFilter,
        RealtimeNotFilter,
        // Subscription management
        RealtimeSubscription,
        RealtimeSubscriptionOptions,
        RealtimeSubscriptionConfig,
        // Utility functions
        filterToJson;

// ═══════════════════════════════════════════════════════════════════════════════
// SIGNAL/WEBSOCKET COMMUNICATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Low-level WebSocket communication for advanced use cases
export 'signal.dart'
    show
        Signal,
        SignalLock,
        SignalResult,
        SignalResultOptions,
        SignalMessageHandler,
        createSignal;

/// Signal message types and data structures
export 'signal_types.dart'
    show
        // Enums for message classification
        SignalMessageType,
        SignalDatabaseEventType,
        SignalErrorCode,
        // Core message classes
        SignalMessage,
        SignalMessageAck,
        SignalMessagePing,
        SignalMessagePong,
        SignalMessageSubscribe,
        SignalMessageUnsubscribe,
        SignalMessagePublish,
        SignalMessageData,
        SignalMessageError,
        // Database-specific message types
        SignalDatabaseMessage,
        SignalDatabaseInsert,
        SignalDatabaseUpdate,
        SignalDatabaseDelete,
        SignalDatabaseSubscribe,
        SignalDatabaseUnsubscribe,
        // Type aliases for clarity
        SignalDatabaseTopic,
        SignalDatabaseRowId,
        // Utility functions
        parseSignalMessage;

// ═══════════════════════════════════════════════════════════════════════════════
// FILE STORAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// File storage and bucket management
export 'storage.dart' show Storage, Bucket, BucketFile;

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM SERVICES & PROJECT MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

/// Custom service endpoints for serverless functions
export 'service.dart' show Service;

/// Project configuration and management
export 'project.dart' show Project;

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR HANDLING
// ═══════════════════════════════════════════════════════════════════════════════

/// Comprehensive error handling and status codes
export 'error.dart' show ServiceError, ServiceErrorCode;
