import 'package:flutter/foundation.dart';

import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/signal.dart';
import 'package:calljmp/signal_types.dart';
import 'package:calljmp/database_types.dart';

// Re-export types from database_types.dart
export 'package:calljmp/database_types.dart'
    show
        DatabaseRowId,
        DatabaseRow,
        DatabaseTable,
        DatabaseSubscriptionEvent,
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
        DatabaseInsertEventData,
        DatabaseUpdateEventData,
        DatabaseDeleteEventData,
        DatabaseInsertHandler,
        DatabaseUpdateHandler,
        DatabaseDeleteHandler,
        DatabaseObservePath,
        databaseFilterToJson;

/// Provides direct SQLite database access with no restrictions.
///
/// The Database class allows you to execute raw SQL queries against your
/// Calljmp database. This gives you complete control over your data with
/// full SQLite functionality including complex queries, joins, transactions,
/// and schema modifications.
///
/// ## Security
///
/// Database queries are executed with the permissions of the authenticated user.
/// The system enforces access control based on user roles and tags, ensuring
/// that users can only access data they are authorized to see.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Simple SELECT query
/// final users = await calljmp.database.query(
///   sql: 'SELECT id, email, name FROM users WHERE active = ?',
///   params: [true],
/// );
///
/// // INSERT query
/// final result = await calljmp.database.query(
///   sql: 'INSERT INTO posts (title, content, user_id) VALUES (?, ?, ?)',
///   params: ['My Title', 'Post content', 123],
/// );
/// print('Inserted post with ID: ${result.insertId}');
///
/// // Complex query with joins
/// final posts = await calljmp.database.query(
///   sql: '''
///     SELECT p.id, p.title, u.name as author_name
///     FROM posts p
///     JOIN users u ON p.user_id = u.id
///     WHERE p.created_at > ?
///     ORDER BY p.created_at DESC
///   ''',
///   params: [DateTime.now().subtract(Duration(days: 7)).toIso8601String()],
/// );
/// ```
class Database {
  final Config _config;
  final Signal _signal;

  SignalLock? _signalLock;
  final List<DatabaseSubscription> _subscriptions = [];

  static const String _databaseComponent = 'database';

  /// Creates a new Database instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_signal]: Signal instance for managing real-time updates and events
  Database(this._config, this._signal);

  /// Executes a SQL query against the database.
  ///
  /// This method allows you to run any valid SQLite query including SELECT,
  /// INSERT, UPDATE, DELETE, and DDL statements. Parameters can be passed
  /// safely to prevent SQL injection attacks.
  ///
  /// ## Parameters
  ///
  /// - [sql]: The SQL query to execute (required)
  /// - [params]: Optional list of parameters to bind to the query
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing:
  /// - `insertId`: The ID of the last inserted row (for INSERT queries)
  /// - `numAffectedRows`: The number of rows affected by the query
  /// - `rows`: The result rows as a list of dynamic objects
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the user lacks permissions or the SQL is invalid
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // SELECT query
  /// final result = await calljmp.database.query(
  ///   sql: 'SELECT * FROM users WHERE role = ?',
  ///   params: ['admin'],
  /// );
  ///
  /// for (final row in result.rows) {
  ///   print('User: ${row['name']} (${row['email']})');
  /// }
  ///
  /// // INSERT query
  /// final insert = await calljmp.database.query(
  ///   sql: 'INSERT INTO products (name, price) VALUES (?, ?)',
  ///   params: ['Widget', 19.99],
  /// );
  /// print('Created product with ID: ${insert.insertId}');
  ///
  /// // UPDATE query
  /// final update = await calljmp.database.query(
  ///   sql: 'UPDATE users SET last_login = ? WHERE id = ?',
  ///   params: [DateTime.now().toIso8601String(), 123],
  /// );
  /// print('Updated ${update.numAffectedRows} users');
  /// ```
  Future<({int? insertId, int? numAffectedRows, List<dynamic> rows})> query({
    required String sql,
    List<dynamic>? params,
  }) => http
      .request("${_config.serviceUrl}/database/query")
      .use(http.context(_config))
      .use(http.access())
      .post({"sql": sql, "params": params ?? []})
      .json(
        (json) => (
          insertId: json['insertId'] as int?,
          numAffectedRows: json['numAffectedRows'] as int?,
          rows: json['rows'] as List<dynamic>,
        ),
      );

  Future<void> _acquireSignalLock() async {
    _signalLock ??=
        _signal.findLock(_databaseComponent) ??
        await _signal.acquireLock(_databaseComponent);
  }

  Future<void> _releaseSignalLock() async {
    if (_signalLock != null) {
      _signal.releaseLock(_signalLock!);
      _signalLock = null;
    }
  }

  /// Observe database changes for a specific table and event type with type safety.
  ///
  /// @param path - Table name followed by event type (e.g., "users.insert", "posts.update")
  /// @returns A type-safe DatabaseObserver for setting up event handlers and subscriptions
  ///
  /// ## Example Insert Events
  /// ```dart
  /// final subscription = await db.observe<User>('users.insert')
  ///   .onInsert((event) {
  ///     for (final user in event.rows) {
  ///       print('New user: ${user.name}');
  ///     }
  ///   })
  ///   .filter(DatabaseGtFilter('age', 18))
  ///   .subscribe();
  /// ```
  ///
  /// ## Example Update Events
  /// ```dart
  /// final subscription = await db.observe<User>('users.update')
  ///   .onUpdate((event) {
  ///     for (final user in event.rows) {
  ///       print('Updated user: ${user.name}');
  ///     }
  ///   })
  ///   .subscribe();
  /// ```
  ///
  /// ## Example Delete Events
  /// ```dart
  /// final subscription = await db.observe('users.delete')
  ///   .onDelete((event) {
  ///     print('Deleted user IDs: ${event.rowIds}');
  ///   })
  ///   .subscribe();
  /// ```
  DatabaseObserver<T> observe<T>(String path) {
    final observePath = DatabaseObservePath(path);
    return DatabaseObserver<T>._(
      this,
      observePath.table,
      observePath.eventType,
    );
  }

  Future<DatabaseSubscription> _subscribe<T>(
    DatabaseSubscriptionOptions<T> options,
  ) async {
    final topic = 'database.${options.table}.${options.event.value}';
    final subscriptionId = await Signal.messageId();
    final subscription = DatabaseSubscriptionInternal(
      topic,
      options.table,
      options.event,
    );
    _subscriptions.add(subscription);

    // Declare handler variables first
    late Future<SignalResult?> Function(SignalMessage) handleAck;
    late Future<SignalResult?> Function(SignalMessage) handleError;
    late Future<SignalResult?> Function(SignalMessage) handleData;
    late Future<void> Function() removeSubscription;

    // Define functions
    handleData = (SignalMessage message) async {
      if (!subscription.active) return null;

      if (message is SignalDatabaseInsert && message.topic == topic) {
        if (options.onInsert != null) {
          try {
            // Safer type casting with validation
            final rows = message.rows.map((row) {
              try {
                return row as T;
              } catch (e) {
                debugPrint('Warning: Failed to cast row to type $T: $e');
                return row; // Return as dynamic if casting fails
              }
            }).toList();

            await options.onInsert!(
              DatabaseInsertEventData(rows: rows.cast<T>()),
            );
          } catch (error) {
            debugPrint(
              'Error handling insert for table ${options.table}: $error',
            );
          }
        }
      } else if (message is SignalDatabaseUpdate && message.topic == topic) {
        if (options.onUpdate != null) {
          try {
            // Safer type casting with validation
            final rows = message.rows.map((row) {
              try {
                return row as T;
              } catch (e) {
                debugPrint('Warning: Failed to cast row to type $T: $e');
                return row; // Return as dynamic if casting fails
              }
            }).toList();

            await options.onUpdate!(
              DatabaseUpdateEventData(rows: rows.cast<T>()),
            );
          } catch (error) {
            debugPrint(
              'Error handling update for table ${options.table}: $error',
            );
          }
        }
      } else if (message is SignalDatabaseDelete && message.topic == topic) {
        if (options.onDelete != null) {
          try {
            await options.onDelete!(
              DatabaseDeleteEventData(rowIds: message.rowIds),
            );
          } catch (error) {
            debugPrint(
              'Error handling delete for table ${options.table}: $error',
            );
          }
        }
      }

      return null;
    };

    removeSubscription = () async {
      _signal.off(SignalMessageType.ack, handleAck);
      _signal.off(SignalMessageType.error, handleError);
      _signal.off(SignalMessageType.data, handleData);

      subscription._active = false;
      _subscriptions.remove(subscription);

      if (_subscriptions.isEmpty) {
        await _releaseSignalLock();
      }
    };

    handleAck = (SignalMessage message) async {
      if (message is SignalMessageAck && message.id == subscriptionId) {
        _signal.off(SignalMessageType.ack, handleAck);
        _signal.off(SignalMessageType.error, handleError);
        return SignalResult.handled;
      }
      return null;
    };

    handleError = (SignalMessage message) async {
      if (message is SignalMessageError && message.id == subscriptionId) {
        await removeSubscription();
        return SignalResult.handled;
      }
      return null;
    };

    Future<void> unsubscribe() async {
      try {
        await _signal.send(
          SignalDatabaseUnsubscribe(id: subscriptionId, topic: topic),
        );
      } catch (error) {
        debugPrint(
          'Failed to unsubscribe from table ${options.table} event ${options.event.value}: $error',
        );
      }
    }

    subscription._onUnsubscribe = () async {
      await unsubscribe();
      await removeSubscription();
    };

    _signal.on(SignalMessageType.ack, handleAck);
    _signal.on(SignalMessageType.error, handleError);
    _signal.on(SignalMessageType.data, handleData);

    await _acquireSignalLock();
    await _signal.send(
      SignalDatabaseSubscribe(
        id: subscriptionId,
        topic: topic,
        fields: options.fields,
        filter: options.filter != null
            ? databaseFilterToJson(options.filter!)
            : null,
      ),
    );

    return subscription;
  }
}

/// Internal implementation of database subscription
class DatabaseSubscriptionInternal implements DatabaseSubscription {
  @override
  final String topic;

  @override
  final DatabaseTable table;

  @override
  final DatabaseSubscriptionEvent event;

  bool _active = true;
  Future<void> Function()? _onUnsubscribe;

  DatabaseSubscriptionInternal(this.topic, this.table, this.event);

  @override
  bool get active => _active;

  @override
  Future<void> unsubscribe() async {
    if (_active) {
      _active = false;
      if (_onUnsubscribe != null) {
        await _onUnsubscribe!();
      }
    }
  }
}

/// Database observer for setting up event handlers and subscriptions with type safety
class DatabaseObserver<T> {
  final Database _database;
  final DatabaseTable _table;
  final DatabaseSubscriptionEvent _event;

  List<String>? _fields;
  DatabaseFilter? _filter;
  DatabaseInsertHandler<T>? _insertHandler;
  DatabaseUpdateHandler<T>? _updateHandler;
  DatabaseDeleteHandler? _deleteHandler;

  DatabaseObserver._(this._database, this._table, this._event);

  /// Set up insert event handler with type safety
  DatabaseObserver<T> onInsert(DatabaseInsertHandler<T> handler) {
    _insertHandler = handler;
    return this;
  }

  /// Set up update event handler with type safety
  DatabaseObserver<T> onUpdate(DatabaseUpdateHandler<T> handler) {
    _updateHandler = handler;
    return this;
  }

  /// Set up delete event handler with type safety
  DatabaseObserver<T> onDelete(DatabaseDeleteHandler handler) {
    _deleteHandler = handler;
    return this;
  }

  /// Set field projection for the subscription
  DatabaseObserver<T> fields(List<String> fields) {
    _fields = fields;
    return this;
  }

  /// Set filter conditions with type safety
  DatabaseObserver<T> filter(DatabaseFilter filter) {
    _filter = filter;
    return this;
  }

  /// Subscribe to database events with type safety
  Future<DatabaseSubscription> subscribe() async {
    return _database._subscribe(
      DatabaseSubscriptionOptions<T>(
        table: _table,
        event: _event,
        fields: _fields,
        filter: _filter,
        onInsert: _insertHandler,
        onUpdate: _updateHandler,
        onDelete: _deleteHandler,
      ),
    );
  }
}
