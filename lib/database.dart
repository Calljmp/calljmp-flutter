import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;

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

  /// Creates a new Database instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  Database(this._config);

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
}
