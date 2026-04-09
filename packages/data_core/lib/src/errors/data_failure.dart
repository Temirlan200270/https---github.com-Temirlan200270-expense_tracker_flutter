/// Базовая ошибка слоя данных.
class DataFailure implements Exception {
  DataFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'DataFailure(message: $message, cause: $cause)';
}

