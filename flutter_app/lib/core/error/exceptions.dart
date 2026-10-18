/// Thrown by data sources when a remote call fails.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server exception']);

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown by data sources when a local cache operation fails.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache exception']);

  @override
  String toString() => 'CacheException: $message';
}
