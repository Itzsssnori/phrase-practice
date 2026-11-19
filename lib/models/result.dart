/// A discriminated result type distinguishing success, empty, and error states.
sealed class RepoResult<T> {
  const RepoResult();

  const factory RepoResult.success(T data) = SuccessResult<T>;
  const factory RepoResult.empty([String message]) = EmptyResult<T>;
  const factory RepoResult.error(String message, [Object? error, StackTrace? stackTrace]) = ErrorResult<T>;

  bool get isSuccess => this is SuccessResult<T>;
  bool get isEmpty => this is EmptyResult<T>;
  bool get isError => this is ErrorResult<T>;

  T? get dataOrNull {
    final self = this;
    if (self is SuccessResult<T>) return self.data;
    return null;
  }

  String? get errorMessageOrNull {
    final self = this;
    if (self is ErrorResult<T>) return self.message;
    if (self is EmptyResult<T>) return self.message;
    return null;
  }
}

/// Represents a successful operation returning [data].
class SuccessResult<T> extends RepoResult<T> {
  final T data;
  const SuccessResult(this.data);

  @override
  String toString() => 'SuccessResult($data)';
}

/// Represents an operation that completed with no data found.
class EmptyResult<T> extends RepoResult<T> {
  final String message;
  const EmptyResult([this.message = 'No data available']);

  @override
  String toString() => 'EmptyResult($message)';
}

/// Represents a failed operation with an error [message] and optional exception/stack trace.
class ErrorResult<T> extends RepoResult<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const ErrorResult(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'ErrorResult($message, error: $error)';
}
