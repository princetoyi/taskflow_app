class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Exception? originalError;
  final Map<String, dynamic>? additionalInfo;

  AppException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.additionalInfo,
  });

  @override
  String toString() => message;
  
  /// Returns a detailed error message for debugging
  String toDetailedString() {
    final buffer = StringBuffer(message);
    
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    
    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      buffer.write('\nDetails: ${additionalInfo.toString()}');
    }
    
    if (originalError != null) {
      buffer.write('\nOriginal error: ${originalError.toString()}');
    }
    
    return buffer.toString();
  }
}
