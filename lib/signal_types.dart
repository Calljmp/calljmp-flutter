/// Signal message types and data structures for real-time communication
/// This mirrors the signal types from the common library
library;

enum SignalMessageType {
  ping('ping'),
  pong('pong'),
  subscribe('subscribe'),
  unsubscribe('unsubscribe'),
  publish('publish'),
  data('data'),
  error('error'),
  ack('ack'),
  config('config');

  const SignalMessageType(this.value);
  final String value;
}

enum SignalDatabaseEventType {
  insert('insert'),
  update('update'),
  delete('delete');

  const SignalDatabaseEventType(this.value);
  final String value;
}

enum SignalErrorCode {
  notFound('not_found'),
  internalError('internal_error'),
  invalidMessage('invalid_message');

  const SignalErrorCode(this.value);
  final String value;
}

/// Base class for all signal messages
abstract class SignalMessage {
  final SignalMessageType type;
  final String id;

  const SignalMessage({required this.type, required this.id});

  Map<String, dynamic> toJson();
}

/// Acknowledgment message
class SignalMessageAck extends SignalMessage {
  const SignalMessageAck({required super.id})
    : super(type: SignalMessageType.ack);

  @override
  Map<String, dynamic> toJson() => {'type': type.value, 'id': id};
}

/// Ping message
class SignalMessagePing extends SignalMessage {
  const SignalMessagePing({required super.id})
    : super(type: SignalMessageType.ping);

  @override
  Map<String, dynamic> toJson() => {'type': type.value, 'id': id};
}

/// Pong message
class SignalMessagePong extends SignalMessage {
  const SignalMessagePong({required super.id})
    : super(type: SignalMessageType.pong);

  @override
  Map<String, dynamic> toJson() => {'type': type.value, 'id': id};
}

/// Subscribe message
class SignalMessageSubscribe extends SignalMessage {
  final String topic;
  final List<String>? fields;
  final Map<String, dynamic>? filter;

  const SignalMessageSubscribe({
    required super.id,
    required this.topic,
    this.fields,
    this.filter,
  }) : super(type: SignalMessageType.subscribe);

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type.value,
      'id': id,
      'topic': topic,
    };
    if (fields != null) json['fields'] = fields;
    if (filter != null) json['filter'] = filter;
    return json;
  }
}

/// Unsubscribe message
class SignalMessageUnsubscribe extends SignalMessage {
  final String topic;

  const SignalMessageUnsubscribe({required super.id, required this.topic})
    : super(type: SignalMessageType.unsubscribe);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
  };
}

/// Publish message
class SignalMessagePublish extends SignalMessage {
  final String topic;
  final Map<String, dynamic> data;

  const SignalMessagePublish({
    required super.id,
    required this.topic,
    required this.data,
  }) : super(type: SignalMessageType.publish);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
    'data': data,
  };
}

/// Data message
class SignalMessageData extends SignalMessage {
  final String topic;
  final Map<String, dynamic> data;

  const SignalMessageData({
    required super.id,
    required this.topic,
    required this.data,
  }) : super(type: SignalMessageType.data);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
    'data': data,
  };
}

/// Error message
class SignalMessageError extends SignalMessage {
  final SignalErrorCode code;
  final String message;

  const SignalMessageError({
    required super.id,
    required this.code,
    required this.message,
  }) : super(type: SignalMessageType.error);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'code': code.value,
    'message': message,
  };
}

/// Database-specific messages
typedef SignalDatabaseTopic = String; // database.${table}.${eventType}
typedef SignalDatabaseRowId = int;

/// Base class for database-specific data messages
abstract class SignalDatabaseMessage extends SignalMessage {
  final String topic;
  final SignalDatabaseEventType eventType;

  const SignalDatabaseMessage({
    required super.id,
    required this.topic,
    required this.eventType,
  }) : super(type: SignalMessageType.data);
}

/// Database insert message
class SignalDatabaseInsert extends SignalDatabaseMessage {
  final List<Map<String, dynamic>> rows;

  const SignalDatabaseInsert({
    required super.id,
    required super.topic,
    required this.rows,
  }) : super(eventType: SignalDatabaseEventType.insert);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
    'eventType': eventType.value,
    'rows': rows,
  };
}

/// Database update message
class SignalDatabaseUpdate extends SignalDatabaseMessage {
  final List<Map<String, dynamic>> rows;

  const SignalDatabaseUpdate({
    required super.id,
    required super.topic,
    required this.rows,
  }) : super(eventType: SignalDatabaseEventType.update);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
    'eventType': eventType.value,
    'rows': rows,
  };
}

/// Database delete message
class SignalDatabaseDelete extends SignalDatabaseMessage {
  final List<SignalDatabaseRowId> rowIds;

  const SignalDatabaseDelete({
    required super.id,
    required super.topic,
    required this.rowIds,
  }) : super(eventType: SignalDatabaseEventType.delete);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.value,
    'id': id,
    'topic': topic,
    'eventType': eventType.value,
    'rowIds': rowIds,
  };
}

/// Database subscribe message
class SignalDatabaseSubscribe extends SignalMessageSubscribe {
  const SignalDatabaseSubscribe({
    required super.id,
    required super.topic,
    super.fields,
    super.filter,
  });
}

/// Database unsubscribe message
class SignalDatabaseUnsubscribe extends SignalMessageUnsubscribe {
  const SignalDatabaseUnsubscribe({required super.id, required super.topic});
}

/// Helper function to parse signal messages from JSON
SignalMessage? parseSignalMessage(Map<String, dynamic> json) {
  final typeStr = json['type'] as String?;
  final id = json['id'] as String?;

  if (typeStr == null || id == null) return null;

  switch (typeStr) {
    case 'ack':
      return SignalMessageAck(id: id);
    case 'ping':
      return SignalMessagePing(id: id);
    case 'pong':
      return SignalMessagePong(id: id);
    case 'data':
      final topic = json['topic'] as String?;
      final data = json['data'] as Map<String, dynamic>?;
      final eventType = json['eventType'] as String?;

      if (topic == null) return null;

      // Handle database-specific events
      if (eventType != null) {
        switch (eventType) {
          case 'insert':
            final rows = (json['rows'] as List?)?.cast<Map<String, dynamic>>();
            if (rows != null) {
              return SignalDatabaseInsert(id: id, topic: topic, rows: rows);
            }
            break;
          case 'update':
            final rows = (json['rows'] as List?)?.cast<Map<String, dynamic>>();
            if (rows != null) {
              return SignalDatabaseUpdate(id: id, topic: topic, rows: rows);
            }
            break;
          case 'delete':
            final rowIds = (json['rowIds'] as List?)?.cast<int>();
            if (rowIds != null) {
              return SignalDatabaseDelete(id: id, topic: topic, rowIds: rowIds);
            }
            break;
        }
      }

      // Regular data message
      if (data != null) {
        return SignalMessageData(id: id, topic: topic, data: data);
      }
      break;
    case 'error':
      final codeStr = json['code'] as String?;
      final message = json['message'] as String?;
      if (codeStr != null && message != null) {
        final code = SignalErrorCode.values.firstWhere(
          (e) => e.value == codeStr,
          orElse: () => SignalErrorCode.internalError,
        );
        return SignalMessageError(id: id, code: code, message: message);
      }
      break;
  }

  return null;
}
