import 'package:flutter/foundation.dart';

import 'package:calljmp/signal.dart';
import 'package:calljmp/signal_types.dart';
import 'package:calljmp/realtime_types.dart';

// Re-export types from realtime_types.dart
export 'package:calljmp/realtime_types.dart'
    show
        RealtimeTopic,
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
        RealtimeDataEvent,
        RealtimeErrorEvent,
        RealtimeDataHandler,
        RealtimeErrorHandler,
        RealtimeEventHandler,
        RealtimeObserverEvent,
        filterToJson;

/// Internal implementation of realtime subscription
class RealtimeSubscriptionInternal implements RealtimeSubscription {
  @override
  final RealtimeTopic topic;

  bool _active = true;
  Future<void> Function()? _onUnsubscribe;

  RealtimeSubscriptionInternal(this.topic);

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

/// Main Realtime class for pub/sub messaging
class Realtime {
  final Signal _signal;

  SignalLock? _signalLock;
  final List<RealtimeSubscriptionInternal> _subscriptions = [];

  static const String _realtimeComponent = 'realtime';

  Realtime(this._signal);

  Future<void> _acquireSignalLock() async {
    _signalLock ??=
        _signal.findLock(_realtimeComponent) ??
        await _signal.acquireLock(_realtimeComponent);
  }

  Future<void> _releaseSignalLock() async {
    if (_signalLock != null) {
      _signal.releaseLock(_signalLock!);
      _signalLock = null;
    }
  }

  /// Publish data to a real-time topic
  ///
  /// ## Example
  /// ```dart
  /// await realtime.publish(
  ///   topic: 'chat.room1',
  ///   data: {'message': 'Hello World', 'user': 'john'},
  /// );
  /// ```
  Future<void> publish<T>({
    required RealtimeTopic topic,
    required T data,
  }) async {
    await _signal.send(
      SignalMessagePublish(
        id: await Signal.messageId(),
        topic: topic,
        data: data as Map<String, dynamic>,
      ),
    );
  }

  /// Unsubscribe from a specific topic
  ///
  /// ## Example
  /// ```dart
  /// await realtime.unsubscribe(topic: 'chat.room1');
  /// ```
  Future<void> unsubscribe({RealtimeTopic? topic}) async {
    if (topic != null) {
      try {
        final subscription = _subscriptions.firstWhere(
          (sub) => sub.topic == topic,
        );
        await subscription.unsubscribe();
      } catch (e) {
        // Subscription not found, ignore
      }
    }
  }

  /// Observe real-time data for a specific topic with type safety
  ///
  /// ## Example with data and error handling (synchronous handlers)
  /// ```dart
  /// final subscription = await realtime.observe<Message>('chat.room1')
  ///   .onData((event) {
  ///     print('Received message: ${event.data.text}');
  ///   })
  ///   .onError((event) {
  ///     print('Error: ${event.message}');
  ///   })
  ///   .filter(RealtimeEqFilter('room_id', 'room123'))
  ///   .subscribe();
  /// ```
  ///
  /// ## Example with async handlers
  /// ```dart
  /// final subscription = await realtime.observe<Message>('chat.room1')
  ///   .onData((event) async {
  ///     await processMessage(event.data);
  ///   })
  ///   .onError((event) async {
  ///     await logError(event.message);
  ///   })
  ///   .subscribe();
  /// ```
  ///
  /// ## Example with enum-based events
  /// ```dart
  /// final subscription = await realtime.observe<Message>('chat.room1')
  ///   .on(RealtimeObserverEvent.data, (event) {
  ///     print('Message: ${event.data}');
  ///   })
  ///   .on(RealtimeObserverEvent.error, (event) {
  ///     print('Error: ${event.message}');
  ///   })
  ///   .subscribe();
  /// ```
  RealtimeObserver<T> observe<T>(RealtimeTopic topic) {
    return RealtimeObserver<T>._(this, topic);
  }

  Future<RealtimeSubscription> _subscribe<T>(
    RealtimeSubscriptionOptions<T> options,
  ) async {
    final subscriptionId = await Signal.messageId();
    final subscription = RealtimeSubscriptionInternal(options.topic);
    _subscriptions.add(subscription);

    // Declare handler variables first
    late Future<SignalResult?> Function(SignalMessage) handleAck;
    late Future<SignalResult?> Function(SignalMessage) handleError;
    late Future<SignalResult?> Function(SignalMessage) handleData;
    late Future<void> Function() removeSubscription;

    // Define functions
    handleData = (SignalMessage message) async {
      if (!subscription.active) return null;

      if (message is SignalMessageData && message.topic == options.topic) {
        try {
          await options.onData?.call(
            RealtimeDataEvent(topic: message.topic, data: message.data as T),
          );
        } catch (error) {
          debugPrint('Error handling data for topic ${message.topic}: $error');
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
        try {
          await options.onError?.call(
            RealtimeErrorEvent(code: message.code, message: message.message),
          );
        } catch (error) {
          debugPrint('Error handling error event: $error');
        }
        await removeSubscription();
        return SignalResult.handled;
      }
      return null;
    };

    Future<void> unsubscribe() async {
      try {
        await _signal.send(
          SignalMessageUnsubscribe(id: subscriptionId, topic: options.topic),
        );
      } catch (error) {
        debugPrint('Failed to unsubscribe from topic ${options.topic}: $error');
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
      SignalMessageSubscribe(
        id: subscriptionId,
        topic: options.topic,
        fields: options.fields,
        filter: options.filter != null ? filterToJson(options.filter!) : null,
      ),
    );

    return subscription;
  }
}

/// Observer for setting up real-time subscriptions with type safety
class RealtimeObserver<T> {
  final Realtime _realtime;
  final RealtimeTopic _topic;

  List<String>? _fields;
  RealtimeFilter? _filter;
  RealtimeDataHandler<T>? _dataHandler;
  RealtimeErrorHandler? _errorHandler;

  RealtimeObserver._(this._realtime, this._topic);

  /// Set field projection for the subscription
  ///
  /// ## Example
  /// ```dart
  /// realtime.observe<User>('users.updates')
  ///   ..fields(['name', 'email'])
  ///   ..on('data', (topic, user) {
  ///     print('User updated: ${user.name}');
  ///   });
  /// ```
  RealtimeObserver<T> fields(List<String> fields) {
    _fields = fields;
    return this;
  }

  /// Set filter conditions for the subscription with type safety
  ///
  /// ## Example
  /// ```dart
  /// realtime.observe<Map<String, dynamic>>('messages.chat')
  ///   ..filter(RealtimeEqFilter('room_id', 'room123'))
  ///   ..on(RealtimeObserverEvent.data, (event) {
  ///     print('Message in room123: ${event.data}');
  ///   });
  /// ```
  RealtimeObserver<T> filter(RealtimeFilter filter) {
    _filter = filter;
    return this;
  }

  /// Set up event handlers with enum-based events
  ///
  /// ## Example
  /// ```dart
  /// realtime.observe<ChatMessage>('chat.room1')
  ///   ..on(RealtimeObserverEvent.data, (event) {
  ///     print('New message: ${event.data.text}');
  ///   })
  ///   ..on(RealtimeObserverEvent.error, (event) {
  ///     print('Error: ${event.message}');
  ///   });
  /// ```
  RealtimeObserver<T> on(RealtimeObserverEvent event, dynamic handler) {
    switch (event) {
      case RealtimeObserverEvent.data:
        _dataHandler = handler as RealtimeDataHandler<T>;
        break;
      case RealtimeObserverEvent.error:
        _errorHandler = handler as RealtimeErrorHandler;
        break;
    }
    return this;
  }

  /// Set up data event handler with type safety
  RealtimeObserver<T> onData(RealtimeDataHandler<T> handler) {
    _dataHandler = handler;
    return this;
  }

  /// Set up error event handler with type safety
  RealtimeObserver<T> onError(RealtimeErrorHandler handler) {
    _errorHandler = handler;
    return this;
  }

  /// Subscribe to real-time events with type safety
  ///
  /// ## Example
  /// ```dart
  /// final subscription = await realtime.observe<Message>('chat.room1')
  ///   .on(RealtimeObserverEvent.data, (event) => print('Message: ${event.data}'))
  ///   .subscribe();
  /// ```
  Future<RealtimeSubscription> subscribe() async {
    return _realtime._subscribe(
      RealtimeSubscriptionOptions<T>(
        topic: _topic,
        fields: _fields,
        filter: _filter,
        onData: _dataHandler,
        onError: _errorHandler,
      ),
    );
  }
}
