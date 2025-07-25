import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:calljmp/common.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

import 'package:calljmp/calljmp_device_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/signal_types.dart';

/// Signal result options for controlling handler behavior
class SignalResultOptions {
  final bool handled;
  final bool autoRemove;

  const SignalResultOptions({this.handled = false, this.autoRemove = false});
}

/// Result returned by signal message handlers
class SignalResult {
  final SignalResultOptions options;

  const SignalResult([this.options = const SignalResultOptions()]);

  static const SignalResult none = SignalResult();
  static const SignalResult handled = SignalResult(
    SignalResultOptions(handled: true),
  );

  SignalResult get markHandled => SignalResult(
    SignalResultOptions(handled: true, autoRemove: options.autoRemove),
  );

  SignalResult get autoRemove => SignalResult(
    SignalResultOptions(handled: options.handled, autoRemove: true),
  );
}

/// Handler for signal messages
typedef SignalMessageHandler<T extends SignalMessage> =
    Future<SignalResult?> Function(T message);

/// Signal lock for managing component-specific connections
class SignalLock {
  final String id;
  final String component;
  final DateTime timestamp;

  const SignalLock({
    required this.id,
    required this.component,
    required this.timestamp,
  });
}

/// Main Signal class for WebSocket-based real-time communication
class Signal {
  final Config _config;
  IOWebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  int _reconnectDelay = 1000;
  final bool _autoConnect = true;
  Completer<void>? _connectionCompleter;
  final Map<SignalMessageType, List<SignalMessageHandler>> _messageHandlers =
      {};
  final Map<String, SignalLock> _locks = {};
  Timer? _autoDisconnectTimer;
  Timer? _heartbeatTimer;
  Future<void> _sendQueue = Future.value();

  Signal(this._config);

  /// Generate a unique message ID
  static Future<String> messageId() => CalljmpDevice.instance.generateUuid();

  /// Connect to the Signal WebSocket endpoint
  Future<void> connect() async {
    if (_channel != null && _channel!.closeCode == null) {
      return;
    }

    if (_connectionCompleter != null) {
      return _connectionCompleter!.future;
    }

    _connectionCompleter = Completer<void>();

    void completeOnce([dynamic result]) {
      if (_connectionCompleter != null) {
        if (result is Exception || result is Error) {
          _connectionCompleter!.completeError(result);
        } else {
          _connectionCompleter!.complete();
        }
        _connectionCompleter = null;
      }
    }

    try {
      final url = _config.serviceUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      final headers = await aggregate(_config);

      final uri = Uri.parse('$url/signal');
      _channel = IOWebSocketChannel.connect(uri, headers: headers);

      _channel!.ready
          .then((_) {
            _reconnectAttempts = 0;
            _reconnectDelay = 1000;
            _scheduleAutoDisconnect();
            _scheduleHeartbeat();
            completeOnce();
          })
          .catchError((error) {
            completeOnce(error);
          });

      _channel!.stream.listen(
        (data) {
          _handleMessage(data);
        },
        onError: (error) {
          completeOnce(error);
        },
        onDone: () {
          final wasCleanClose = _channel?.closeCode == 1000;
          _channel = null;
          _clearAutoDisconnect();
          _clearHeartbeat();

          if (!wasCleanClose && _reconnectAttempts < _maxReconnectAttempts) {
            _attemptReconnect();
          }
        },
      );
    } catch (error) {
      completeOnce(error);
    }

    return _connectionCompleter!.future;
  }

  /// Disconnect from the Signal WebSocket
  Future<void> _disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(1000, 'Client disconnect');
      _channel = null;
    }
    _clearAutoDisconnect();
    _clearHeartbeat();
  }

  /// Send a message through the Signal connection
  Future<void> send<T extends SignalMessage>(T message) async {
    _sendQueue = _sendQueue.then((_) async {
      if (_autoConnect && !connected && !connecting) {
        await connect();
      }
      _send(message);
    });
    return _sendQueue;
  }

  void _send(SignalMessage message) {
    if (_channel == null || _channel!.closeCode != null) {
      throw Exception('WebSocket connection is not available');
    }

    final data = json.encode(message.toJson());
    _channel!.sink.add(data);
  }

  /// Check if the connection is active
  bool get connected => _channel != null && _channel!.closeCode == null;

  /// Check if currently connecting
  bool get connecting => _connectionCompleter != null;

  /// Check if currently reconnecting
  bool get reconnecting => connecting && _reconnectAttempts > 0;

  Future<void> _handleMessage(dynamic data) async {
    if (data is! String) return;

    try {
      final jsonData = json.decode(data) as Map<String, dynamic>;
      final message = parseSignalMessage(jsonData);

      if (message == null) return;

      final handlers = List<SignalMessageHandler>.from(
        _messageHandlers[message.type] ?? [],
      );

      for (final handler in handlers) {
        final result = await handler(message);
        if (result != null) {
          if (result.options.autoRemove) {
            off(message.type, handler);
          }
          if (result.options.handled) {
            return;
          }
        }
      }
    } catch (e) {
      // Log error but don't throw
      debugPrint('Error handling signal message: $e');
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * pow(2, _reconnectAttempts - 1);

    Timer(Duration(milliseconds: delay.toInt()), () {
      connect().catchError((error) {
        debugPrint('Reconnection failed: $error');
      });
    });
  }

  /// Register a handler for a specific message type
  void on<T extends SignalMessage>(
    SignalMessageType type,
    SignalMessageHandler<T> handler,
  ) {
    final handlers = _messageHandlers[type] ?? [];
    handlers.add(handler as SignalMessageHandler);
    _messageHandlers[type] = handlers;
  }

  /// Remove a handler for a specific message type
  void off<T extends SignalMessage>(
    SignalMessageType type,
    SignalMessageHandler<T> handler,
  ) {
    final handlers = _messageHandlers[type];
    if (handlers != null) {
      handlers.remove(handler as SignalMessageHandler);
      if (handlers.isEmpty) {
        _messageHandlers.remove(type);
      }
    }
  }

  /// Find an existing lock for a component
  SignalLock? findLock(String component) {
    try {
      return _locks.values.firstWhere((lock) => lock.component == component);
    } catch (e) {
      return null;
    }
  }

  /// Acquire a lock for a component
  Future<SignalLock> acquireLock(String component) async {
    final lockId = await messageId();
    final lock = SignalLock(
      id: lockId,
      component: component,
      timestamp: DateTime.now(),
    );

    _locks[lockId] = lock;
    _clearAutoDisconnect();
    return lock;
  }

  /// Release a lock
  void releaseLock(SignalLock lock) {
    _locks.remove(lock.id);
    _scheduleAutoDisconnect();
  }

  void _scheduleAutoDisconnect() {
    _clearAutoDisconnect();

    final delay = _config.realtime?.autoDisconnectDelay == null
        ? 60_000 // Default to 60 seconds
        : _config.realtime!.autoDisconnectDelay! * 1000;

    if (connected && _locks.isEmpty && delay > 0) {
      _autoDisconnectTimer = Timer(Duration(milliseconds: delay), () {
        if (connected && _locks.isEmpty) {
          _disconnect().catchError((error) {
            debugPrint('Auto-disconnect failed: $error');
          });
        }
      });
    }
  }

  void _clearAutoDisconnect() {
    _autoDisconnectTimer?.cancel();
    _autoDisconnectTimer = null;
  }

  void _scheduleHeartbeat() {
    _clearHeartbeat();

    final interval = _config.realtime?.heartbeatInterval == null
        ? 0
        : _config.realtime!.heartbeatInterval! * 1000;

    if (connected && interval > 0) {
      _heartbeatTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
        if (connected) {
          _heartbeat().catchError((error) {
            debugPrint('Heartbeat failed: $error');
            _disconnect().catchError((error) {
              debugPrint('Failed to disconnect after heartbeat error: $error');
            });
          });
        }
      });
    }
  }

  void _clearHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _heartbeat() async {
    await send(SignalMessagePing(id: await messageId()));
  }

  /// Dispose of the Signal instance
  Future<void> dispose() async {
    // Wait for send queue to complete, ignoring errors
    try {
      await _sendQueue;
    } catch (e) {
      // Ignore send errors during disposal
    }

    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.completeError(Exception('Signal disposed'));
      _connectionCompleter = null;
    }

    await _disconnect();
    _messageHandlers.clear();
    _locks.clear();
    _clearAutoDisconnect();
    _clearHeartbeat();
    _sendQueue = Future.value();
  }
}

/// Create a Signal instance with proper configuration
Signal createSignal(Config config) {
  return Signal(config);
}
