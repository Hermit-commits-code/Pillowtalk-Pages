class ProUpgradeRequiredException implements Exception {
  final String message;
  ProUpgradeRequiredException(this.message);

  @override
  String toString() => 'ProUpgradeRequiredException: $message';
}
