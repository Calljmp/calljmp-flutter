import 'package:flutter/foundation.dart';

import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/signal.dart';
import 'package:calljmp/signal_types.dart';
import 'package:calljmp/database_types.dart';

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

  /// Observe database changes for a specific table with type safety.
  ///
  /// Returns a DatabaseObserver that allows setting up multiple event handlers
  /// for insert, update, and delete operations on the specified table.
  ///
  /// @param table - Table name to observe
  /// @returns A type-safe DatabaseObserver for setting up event handlers and subscriptions
  ///
  /// ## Example with multiple event handlers
  /// ```dart
  /// final subscription = await database.observe<User>('users')
  ///   .on('insert', (event) {
  ///     print('New users: ${event.rows}');
  ///   })
  ///   .on('update', (event) {
  ///     print('Updated users: ${event.rows}');
  ///   })
  ///   .on('delete', (event) {
  ///     print('Deleted user IDs: ${event.rowIds}');
  ///   })
  ///   .subscribe();
  /// ```
  ///
  /// ## Example with field projection and filtering
  /// ```dart
  /// final subscription = await database.observe<User>('users')
  ///   .fields(['id', 'name', 'email'])
  ///   .filter(DatabaseEqFilter('active', true))
  ///   .on('update', (event) {
  ///     print('Active user updated: ${event.rows}');
  ///   })
  ///   .subscribe();
  /// ```
  DatabaseObserver<T> observe<T>(String table) {
    return DatabaseObserver<T>._(this, table);
  }

  Future<DatabaseSubscription> _subscribeMultiple<T>(
    DatabaseSubscriptionOptions<T> options,
  ) async {
    final subscriptions = <DatabaseSubscription>[];

    if (options.onInsert != null) {
      subscriptions.add(
        await _subscribeSingle(
          DatabaseSubscriptionOptions<T>(
            table: options.table,
            fields: options.fields,
            filter: options.filter,
            onInsert: options.onInsert,
          ),
          DatabaseSubscriptionEvent.insert,
        ),
      );
    }

    if (options.onUpdate != null) {
      subscriptions.add(
        await _subscribeSingle(
          DatabaseSubscriptionOptions<T>(
            table: options.table,
            fields: options.fields,
            filter: options.filter,
            onUpdate: options.onUpdate,
          ),
          DatabaseSubscriptionEvent.update,
        ),
      );
    }

    if (options.onDelete != null) {
      subscriptions.add(
        await _subscribeSingle(
          DatabaseSubscriptionOptions<T>(
            table: options.table,
            fields: options.fields,
            filter: options.filter,
            onDelete: options.onDelete,
          ),
          DatabaseSubscriptionEvent.delete,
        ),
      );
    }

    return ComposedDatabaseSubscription(subscriptions);
  }

  Future<DatabaseSubscription> _subscribeSingle<T>(
    DatabaseSubscriptionOptions<T> options,
    DatabaseSubscriptionEvent event,
  ) async {
    final topic = 'database.${options.table}.${event.value}';
    final subscriptionId = await Signal.messageId();
    final subscription = DatabaseSubscriptionInternal(options.table);
    _subscriptions.add(subscription);

    late Future<SignalResult?> Function(SignalMessage) handleAck;
    late Future<SignalResult?> Function(SignalMessage) handleError;
    late Future<SignalResult?> Function(SignalMessage) handleData;
    late Future<void> Function() removeSubscription;

    handleData = (SignalMessage message) async {
      if (!subscription.active) return null;

      E Function(dynamic) createSafeCaster<E>() {
        return (dynamic item) {
          try {
            return item as E;
          } catch (e) {
            debugPrint('Warning: Failed to cast item to type $E: $e');
            return item;
          }
        };
      }

      final safeCast = createSafeCaster<T>();

      if (message is SignalDatabaseInsert && message.topic == topic) {
        if (options.onInsert != null) {
          try {
            final rows = message.rows.map(safeCast).toList().cast<T>();
            await options.onInsert!(DatabaseInsertEventData(rows: rows));
          } catch (error) {
            debugPrint(
              'Error handling insert for table ${options.table}: $error',
            );
          }
        }
      } else if (message is SignalDatabaseUpdate && message.topic == topic) {
        if (options.onUpdate != null) {
          try {
            final rows = message.rows.map(safeCast).toList().cast<T>();
            await options.onUpdate!(DatabaseUpdateEventData(rows: rows));
          } catch (error) {
            debugPrint(
              'Error handling update for table ${options.table}: $error',
            );
          }
        }
      } else if (message is SignalDatabaseDelete && message.topic == topic) {
        if (options.onDelete != null) {
          try {
            final rows = message.rowIds.map(safeCast).toList().cast<T>();
            await options.onDelete!(DatabaseDeleteEventData(rows: rows));
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
          'Failed to unsubscribe from table ${options.table} event ${event.value}: $error',
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
  final DatabaseTable table;

  bool _active = true;
  Future<void> Function()? _onUnsubscribe;

  DatabaseSubscriptionInternal(this.table);

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

/// Composed database subscription that manages multiple event subscriptions
class ComposedDatabaseSubscription implements DatabaseSubscription {
  final List<DatabaseSubscription> _subscriptions;

  ComposedDatabaseSubscription(this._subscriptions);

  @override
  DatabaseTable get table =>
      _subscriptions.isNotEmpty ? _subscriptions.first.table : '';

  @override
  bool get active => _subscriptions.any((sub) => sub.active);

  @override
  Future<void> unsubscribe() async {
    if (_subscriptions.isNotEmpty) {
      await Future.wait(_subscriptions.map((sub) => sub.unsubscribe()));
      _subscriptions.clear();
    }
  }
}

/// Database observer for setting up event handlers and subscriptions with type safety
class DatabaseObserver<T> {
  final Database _database;
  final DatabaseTable _table;

  List<String>? _fields;
  DatabaseFilter? _filter;
  DatabaseInsertHandler<T>? _insertHandler;
  DatabaseUpdateHandler<T>? _updateHandler;
  DatabaseDeleteHandler? _deleteHandler;

  DatabaseObserver._(this._database, this._table);

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

  /// Set up event handlers for database changes
  ///
  /// ## Example
  /// ```dart
  /// final subscription = await database.observe<User>('users')
  ///   .on('insert', (event) {
  ///     print('New users: ${event.rows}');
  ///   })
  ///   .on('update', (event) {
  ///     print('Updated users: ${event.rows}');
  ///   })
  ///   .on('delete', (event) {
  ///     print('Deleted user IDs: ${event.rowIds}');
  ///   })
  ///   .subscribe();
  /// ```
  DatabaseObserver<T> on(String event, dynamic handler) {
    switch (event) {
      case 'insert':
        _insertHandler = handler as DatabaseInsertHandler<T>;
        break;
      case 'update':
        _updateHandler = handler as DatabaseUpdateHandler<T>;
        break;
      case 'delete':
        _deleteHandler = handler as DatabaseDeleteHandler;
        break;
      default:
        throw ArgumentError('Unsupported event type: $event');
    }
    return this;
  }

  /// Set up insert event handler with type safety
  ///
  /// @deprecated Use on('insert', handler) instead
  DatabaseObserver<T> onInsert(DatabaseInsertHandler<T> handler) {
    _insertHandler = handler;
    return this;
  }

  /// Set up update event handler with type safety
  ///
  /// @deprecated Use on('update', handler) instead
  DatabaseObserver<T> onUpdate(DatabaseUpdateHandler<T> handler) {
    _updateHandler = handler;
    return this;
  }

  /// Set up delete event handler with type safety
  ///
  /// @deprecated Use on('delete', handler) instead
  DatabaseObserver<T> onDelete(DatabaseDeleteHandler handler) {
    _deleteHandler = handler;
    return this;
  }

  /// Subscribe to database events with type safety
  Future<DatabaseSubscription> subscribe() async {
    return _database._subscribeMultiple(
      DatabaseSubscriptionOptions<T>(
        table: _table,
        fields: _fields,
        filter: _filter,
        onInsert: _insertHandler,
        onUpdate: _updateHandler,
        onDelete: _deleteHandler,
      ),
    );
  }
}
