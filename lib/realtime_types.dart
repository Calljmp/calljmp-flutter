/// Enhanced type safety for realtime event handling
library;

import 'dart:async';
import 'package:calljmp/signal_types.dart';

/// Topic for real-time messaging
typedef RealtimeTopic = String;

/// Base interface for realtime event data
abstract class RealtimeEventData {
  const RealtimeEventData();
}

/// Data event containing payload
class RealtimeDataEvent<T> extends RealtimeEventData {
  final RealtimeTopic topic;
  final T data;

  const RealtimeDataEvent({required this.topic, required this.data});
}

/// Error event
class RealtimeErrorEvent extends RealtimeEventData {
  final SignalErrorCode code;
  final String message;

  const RealtimeErrorEvent({required this.code, required this.message});
}

/// Handler for realtime data events
typedef RealtimeDataHandler<T> =
    FutureOr<void> Function(RealtimeDataEvent<T> event);

/// Handler for realtime error events
typedef RealtimeErrorHandler =
    FutureOr<void> Function(RealtimeErrorEvent event);

/// Type-safe event handler interface
abstract class RealtimeEventHandler<T> {
  /// Handle data events
  FutureOr<void> onData(RealtimeDataEvent<T> event) async {}

  /// Handle error events
  FutureOr<void> onError(RealtimeErrorEvent event) async {}
}

/// Event types for realtime observers
enum RealtimeObserverEvent {
  data('data'),
  error('error');

  const RealtimeObserverEvent(this.value);
  final String value;
}

// Removed TypedRealtimeObserver interface - use generic RealtimeObserver instead

/// Filter conditions for realtime subscriptions
sealed class RealtimeFilter {
  const RealtimeFilter();
}

/// Equality filter
class RealtimeEqFilter extends RealtimeFilter {
  final String field;
  final dynamic value;

  const RealtimeEqFilter(this.field, this.value);
}

/// In filter for multiple values
class RealtimeInFilter extends RealtimeFilter {
  final String field;
  final List<dynamic> values;

  const RealtimeInFilter(this.field, this.values);
}

/// Case-insensitive like filter for pattern matching
class RealtimeIlikeFilter extends RealtimeFilter {
  final String field;
  final String pattern;

  const RealtimeIlikeFilter(this.field, this.pattern);
}

/// Case-sensitive like filter for pattern matching
class RealtimeLikeFilter extends RealtimeFilter {
  final String field;
  final String pattern;

  const RealtimeLikeFilter(this.field, this.pattern);
}

/// Not equal filter
class RealtimeNeFilter extends RealtimeFilter {
  final String field;
  final dynamic value;

  const RealtimeNeFilter(this.field, this.value);
}

/// Greater than filter
class RealtimeGtFilter extends RealtimeFilter {
  final String field;
  final num value;

  const RealtimeGtFilter(this.field, this.value);
}

/// Greater than or equal filter
class RealtimeGteFilter extends RealtimeFilter {
  final String field;
  final num value;

  const RealtimeGteFilter(this.field, this.value);
}

/// Less than filter
class RealtimeLtFilter extends RealtimeFilter {
  final String field;
  final num value;

  const RealtimeLtFilter(this.field, this.value);
}

/// Less than or equal filter
class RealtimeLteFilter extends RealtimeFilter {
  final String field;
  final num value;

  const RealtimeLteFilter(this.field, this.value);
}

/// Regular expression filter
class RealtimeRegexFilter extends RealtimeFilter {
  final String field;
  final String pattern;

  const RealtimeRegexFilter(this.field, this.pattern);
}

/// Exists filter (checks if field exists)
class RealtimeExistsFilter extends RealtimeFilter {
  final String field;
  final bool exists;

  const RealtimeExistsFilter(this.field, this.exists);
}

/// Logical AND filter
class RealtimeAndFilter extends RealtimeFilter {
  final List<RealtimeFilter> filters;

  const RealtimeAndFilter(this.filters);
}

/// Logical OR filter
class RealtimeOrFilter extends RealtimeFilter {
  final List<RealtimeFilter> filters;

  const RealtimeOrFilter(this.filters);
}

/// NOT filter
class RealtimeNotFilter extends RealtimeFilter {
  final RealtimeFilter filter;

  const RealtimeNotFilter(this.filter);
}

/// Convert filter to JSON map
Map<String, dynamic> filterToJson(RealtimeFilter filter) {
  return switch (filter) {
    RealtimeEqFilter() => {
      filter.field: {'\$eq': filter.value},
    },
    RealtimeInFilter() => {
      filter.field: {'\$in': filter.values},
    },
    RealtimeIlikeFilter() => {
      filter.field: {'\$ilike': filter.pattern},
    },
    RealtimeLikeFilter() => {
      filter.field: {'\$like': filter.pattern},
    },
    RealtimeNeFilter() => {
      filter.field: {'\$ne': filter.value},
    },
    RealtimeGtFilter() => {
      filter.field: {'\$gt': filter.value},
    },
    RealtimeGteFilter() => {
      filter.field: {'\$gte': filter.value},
    },
    RealtimeLtFilter() => {
      filter.field: {'\$lt': filter.value},
    },
    RealtimeLteFilter() => {
      filter.field: {'\$lte': filter.value},
    },
    RealtimeRegexFilter() => {
      filter.field: {'\$regex': filter.pattern},
    },
    RealtimeExistsFilter() => {
      filter.field: {'\$exists': filter.exists},
    },
    RealtimeAndFilter() => {'\$and': filter.filters.map(filterToJson).toList()},
    RealtimeOrFilter() => {'\$or': filter.filters.map(filterToJson).toList()},
    RealtimeNotFilter() => {'\$not': filterToJson(filter.filter)},
  };
}

/// Subscription options with type safety
class RealtimeSubscriptionOptions<T> {
  final RealtimeTopic topic;
  final List<String>? fields;
  final RealtimeFilter? filter;
  final RealtimeDataHandler<T>? onData;
  final RealtimeErrorHandler? onError;

  const RealtimeSubscriptionOptions({
    required this.topic,
    this.fields,
    this.filter,
    this.onData,
    this.onError,
  });
}

/// Real-time subscription interface
abstract class RealtimeSubscription {
  RealtimeTopic get topic;
  bool get active;
  Future<void> unsubscribe();
}

/// Type-safe subscription configuration
class RealtimeSubscriptionConfig<T> {
  final RealtimeSubscriptionOptions<T> options;
  final String subscriptionId;

  const RealtimeSubscriptionConfig({
    required this.options,
    required this.subscriptionId,
  });
}
