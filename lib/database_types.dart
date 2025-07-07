/// Enhanced type safety for database event handling
library;

import 'dart:async';

/// Database row ID type
typedef DatabaseRowId = int;

/// Database row type
typedef DatabaseRow = Map<String, dynamic>;

/// Database table name
typedef DatabaseTable = String;

/// Database subscription event types
enum DatabaseSubscriptionEvent {
  insert('insert'),
  update('update'),
  delete('delete');

  const DatabaseSubscriptionEvent(this.value);
  final String value;
}

/// Base interface for database event data
abstract class DatabaseEventData {
  const DatabaseEventData();
}

/// Database insert event data
class DatabaseInsertEventData<T> extends DatabaseEventData {
  final List<T> rows;

  const DatabaseInsertEventData({required this.rows});
}

/// Database update event data
class DatabaseUpdateEventData<T> extends DatabaseEventData {
  final List<T> rows;

  const DatabaseUpdateEventData({required this.rows});
}

/// Database delete event data
class DatabaseDeleteEventData extends DatabaseEventData {
  final List<DatabaseRowId> rowIds;

  const DatabaseDeleteEventData({required this.rowIds});
}

/// Type-safe event handlers for database operations
typedef DatabaseInsertHandler<T> =
    FutureOr<void> Function(DatabaseInsertEventData<T> event);
typedef DatabaseUpdateHandler<T> =
    FutureOr<void> Function(DatabaseUpdateEventData<T> event);
typedef DatabaseDeleteHandler =
    FutureOr<void> Function(DatabaseDeleteEventData event);

/// Database filter conditions
sealed class DatabaseFilter {
  const DatabaseFilter();
}

/// Equality filter
class DatabaseEqFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseEqFilter(this.field, this.value);
}

/// Not equal filter
class DatabaseNeFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseNeFilter(this.field, this.value);
}

/// Greater than filter
class DatabaseGtFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseGtFilter(this.field, this.value);
}

/// Greater than or equal filter
class DatabaseGteFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseGteFilter(this.field, this.value);
}

/// Less than filter
class DatabaseLtFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseLtFilter(this.field, this.value);
}

/// Less than or equal filter
class DatabaseLteFilter extends DatabaseFilter {
  final String field;
  final dynamic value;

  const DatabaseLteFilter(this.field, this.value);
}

/// In filter for multiple values
class DatabaseInFilter extends DatabaseFilter {
  final String field;
  final List<dynamic> values;

  const DatabaseInFilter(this.field, this.values);
}

/// Like filter for pattern matching
class DatabaseLikeFilter extends DatabaseFilter {
  final String field;
  final String pattern;

  const DatabaseLikeFilter(this.field, this.pattern);
}

/// Logical AND filter
class DatabaseAndFilter extends DatabaseFilter {
  final List<DatabaseFilter> filters;

  const DatabaseAndFilter(this.filters);
}

/// Logical OR filter
class DatabaseOrFilter extends DatabaseFilter {
  final List<DatabaseFilter> filters;

  const DatabaseOrFilter(this.filters);
}

/// NOT filter
class DatabaseNotFilter extends DatabaseFilter {
  final DatabaseFilter filter;

  const DatabaseNotFilter(this.filter);
}

/// Convert filter to JSON map
Map<String, dynamic> databaseFilterToJson(DatabaseFilter filter) {
  return switch (filter) {
    DatabaseEqFilter() => {
      filter.field: {'eq': filter.value},
    },
    DatabaseNeFilter() => {
      filter.field: {'ne': filter.value},
    },
    DatabaseGtFilter() => {
      filter.field: {'gt': filter.value},
    },
    DatabaseGteFilter() => {
      filter.field: {'gte': filter.value},
    },
    DatabaseLtFilter() => {
      filter.field: {'lt': filter.value},
    },
    DatabaseLteFilter() => {
      filter.field: {'lte': filter.value},
    },
    DatabaseInFilter() => {
      filter.field: {'in': filter.values},
    },
    DatabaseLikeFilter() => {
      filter.field: {'like': filter.pattern},
    },
    DatabaseAndFilter() => {
      '\$and': filter.filters.map(databaseFilterToJson).toList(),
    },
    DatabaseOrFilter() => {
      '\$or': filter.filters.map(databaseFilterToJson).toList(),
    },
    DatabaseNotFilter() => {'\$not': databaseFilterToJson(filter.filter)},
  };
}

/// Database subscription options with type safety
class DatabaseSubscriptionOptions<T> {
  final DatabaseTable table;
  final DatabaseSubscriptionEvent event;
  final List<String>? fields;
  final DatabaseFilter? filter;
  final DatabaseInsertHandler<T>? onInsert;
  final DatabaseUpdateHandler<T>? onUpdate;
  final DatabaseDeleteHandler? onDelete;

  const DatabaseSubscriptionOptions({
    required this.table,
    required this.event,
    this.fields,
    this.filter,
    this.onInsert,
    this.onUpdate,
    this.onDelete,
  });
}

// Removed specific observer interfaces - use generic DatabaseObserver instead

/// Database subscription interface
abstract class DatabaseSubscription {
  bool get active;
  String get topic;
  DatabaseTable get table;
  DatabaseSubscriptionEvent get event;
  Future<void> unsubscribe();
}

/// Path-based type inference for database observers
extension type DatabaseObservePath._(String path) implements String {
  DatabaseObservePath(this.path) {
    final parts = path.split('.');
    if (parts.length != 2) {
      throw ArgumentError('Path must be in format "table.event"');
    }
    if (!['insert', 'update', 'delete'].contains(parts[1])) {
      throw ArgumentError('Invalid event type: ${parts[1]}');
    }
  }

  String get table => path.split('.')[0];
  String get event => path.split('.')[1];

  DatabaseSubscriptionEvent get eventType =>
      DatabaseSubscriptionEvent.values.firstWhere((e) => e.value == event);
}

// Removed DatabaseObserverFactory - use Database.observe() method instead
