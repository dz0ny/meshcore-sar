/// Centralized validation service for form validation, coordinate validation,
/// input sanitization, and common validation patterns used across the app.
///
/// This service provides structured validation results with helpful error messages
/// and includes parse + validate methods for complex inputs.
class ValidationService {
  // Singleton pattern
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  // ============================================================================
  // COORDINATE VALIDATION
  // ============================================================================

  /// Validates latitude value (-90.0 to +90.0)
  ValidationResult validateLatitude(double? lat) {
    if (lat == null) {
      return const ValidationResult.invalid('Latitude is required');
    }
    if (lat < -90.0 || lat > 90.0) {
      return const ValidationResult.invalid(
        'Latitude must be between -90.0 and +90.0',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates longitude value (-180.0 to +180.0)
  ValidationResult validateLongitude(double? lon) {
    if (lon == null) {
      return const ValidationResult.invalid('Longitude is required');
    }
    if (lon < -180.0 || lon > 180.0) {
      return const ValidationResult.invalid(
        'Longitude must be between -180.0 and +180.0',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates both latitude and longitude coordinates
  ValidationResult validateCoordinates(double? lat, double? lon) {
    final latResult = validateLatitude(lat);
    if (!latResult.isValid) return latResult;

    final lonResult = validateLongitude(lon);
    if (!lonResult.isValid) return lonResult;

    return const ValidationResult.valid();
  }

  // ============================================================================
  // COORDINATE BOUNDS VALIDATION (for region downloads)
  // ============================================================================

  /// Validates coordinate bounds for map region downloads
  ///
  /// Checks:
  /// - All coordinates are valid numbers
  /// - North > South
  /// - East > West
  /// - Coordinates are within valid ranges
  ValidationResult validateBounds({
    required double? north,
    required double? south,
    required double? east,
    required double? west,
  }) {
    // Validate all coordinates exist
    if (north == null || south == null || east == null || west == null) {
      return const ValidationResult.invalid(
        'All coordinates are required (North, South, East, West)',
      );
    }

    // Validate individual coordinate ranges
    final northResult = validateLatitude(north);
    if (!northResult.isValid) {
      return ValidationResult.invalid('North: ${northResult.errorMessage}');
    }

    final southResult = validateLatitude(south);
    if (!southResult.isValid) {
      return ValidationResult.invalid('South: ${southResult.errorMessage}');
    }

    final eastResult = validateLongitude(east);
    if (!eastResult.isValid) {
      return ValidationResult.invalid('East: ${eastResult.errorMessage}');
    }

    final westResult = validateLongitude(west);
    if (!westResult.isValid) {
      return ValidationResult.invalid('West: ${westResult.errorMessage}');
    }

    // Validate bounds relationships
    if (north <= south) {
      return const ValidationResult.invalid(
        'North must be greater than South',
      );
    }

    if (east <= west) {
      return const ValidationResult.invalid(
        'East must be greater than West',
      );
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // RADIO PARAMETER VALIDATION
  // ============================================================================

  /// Validates LoRa radio frequency in MHz (137.0 to 1020.0 MHz)
  ValidationResult validateFrequency(double? freqMhz) {
    if (freqMhz == null) {
      return const ValidationResult.invalid('Frequency is required');
    }
    if (freqMhz < 137.0 || freqMhz > 1020.0) {
      return const ValidationResult.invalid(
        'Frequency must be between 137.0 and 1020.0 MHz',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates TX power in dBm (-9 to +22 dBm typical, or up to maxPower)
  ///
  /// If maxPower is provided, uses that as upper limit.
  /// Otherwise defaults to +22 dBm.
  ValidationResult validateTxPower(int? powerDbm, int? maxPower) {
    if (powerDbm == null) {
      return const ValidationResult.invalid('TX power is required');
    }

    final max = maxPower ?? 22;

    if (powerDbm < -9) {
      return const ValidationResult.invalid(
        'TX power must be at least -9 dBm',
      );
    }

    if (powerDbm > max) {
      return ValidationResult.invalid(
        'TX power must not exceed $max dBm',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates LoRa bandwidth index (0-9)
  ///
  /// Valid bandwidth indices:
  /// 0=7.8kHz, 1=10.4kHz, 2=15.6kHz, 3=20.8kHz, 4=31.25kHz,
  /// 5=41.7kHz, 6=62.5kHz, 7=125kHz, 8=250kHz, 9=500kHz
  ValidationResult validateBandwidth(int? bwIndex) {
    if (bwIndex == null) {
      return const ValidationResult.invalid('Bandwidth is required');
    }
    if (bwIndex < 0 || bwIndex > 9) {
      return const ValidationResult.invalid(
        'Bandwidth index must be between 0 and 9',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates LoRa spreading factor (7-12)
  ValidationResult validateSpreadingFactor(int? sf) {
    if (sf == null) {
      return const ValidationResult.invalid('Spreading factor is required');
    }
    if (sf < 7 || sf > 12) {
      return const ValidationResult.invalid(
        'Spreading factor must be between 7 and 12',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates LoRa coding rate (5-8)
  ValidationResult validateCodingRate(int? cr) {
    if (cr == null) {
      return const ValidationResult.invalid('Coding rate is required');
    }
    if (cr < 5 || cr > 8) {
      return const ValidationResult.invalid(
        'Coding rate must be between 5 and 8',
      );
    }
    return const ValidationResult.valid();
  }

  // ============================================================================
  // DISTANCE AND TIME VALIDATION
  // ============================================================================

  /// Validates distance in meters
  ///
  /// Optional min and max bounds can be provided.
  /// Defaults to 1m minimum if not specified.
  ValidationResult validateDistance(
    double? meters, {
    double? min,
    double? max,
  }) {
    if (meters == null) {
      return const ValidationResult.invalid('Distance is required');
    }

    final minValue = min ?? 1.0;

    if (meters < minValue) {
      return ValidationResult.invalid(
        'Distance must be at least ${minValue.toStringAsFixed(0)}m',
      );
    }

    if (max != null && meters > max) {
      return ValidationResult.invalid(
        'Distance must not exceed ${max.toStringAsFixed(0)}m',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates time interval in seconds
  ///
  /// Optional min and max bounds can be provided.
  /// Defaults to 10 seconds minimum if not specified.
  ValidationResult validateTimeInterval(
    int? seconds, {
    int? min,
    int? max,
  }) {
    if (seconds == null) {
      return const ValidationResult.invalid('Time interval is required');
    }

    final minValue = min ?? 10;

    if (seconds < minValue) {
      return ValidationResult.invalid(
        'Time interval must be at least ${minValue}s',
      );
    }

    if (max != null && seconds > max) {
      return ValidationResult.invalid(
        'Time interval must not exceed ${max}s',
      );
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // ZOOM LEVEL VALIDATION
  // ============================================================================

  /// Validates map zoom level (1-19 for most tile sources)
  ValidationResult validateZoomLevel(int? zoom) {
    if (zoom == null) {
      return const ValidationResult.invalid('Zoom level is required');
    }
    if (zoom < 1 || zoom > 19) {
      return const ValidationResult.invalid(
        'Zoom level must be between 1 and 19',
      );
    }
    return const ValidationResult.valid();
  }

  // ============================================================================
  // NAME AND TEXT VALIDATION
  // ============================================================================

  /// Validates name/text field
  ///
  /// Checks for:
  /// - Non-empty after trimming
  /// - Maximum length (defaults to 32 characters)
  ValidationResult validateName(String? name, {int? maxLength}) {
    if (name == null || name.trim().isEmpty) {
      return const ValidationResult.invalid('Name cannot be empty');
    }

    final max = maxLength ?? 32;

    if (name.length > max) {
      return ValidationResult.invalid(
        'Name must not exceed $max characters',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates password field
  ///
  /// Checks for:
  /// - Non-empty
  /// - Maximum length of 15 characters (MeshCore protocol limit)
  ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return const ValidationResult.invalid('Password cannot be empty');
    }

    if (password.length > 15) {
      return const ValidationResult.invalid(
        'Password must not exceed 15 characters',
      );
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // PARSE AND VALIDATE METHODS
  // ============================================================================

  /// Parses and validates latitude string
  ///
  /// Returns ParseResult with parsed value or error message.
  ParseResult<double> parseLatitude(String text) {
    if (text.trim().isEmpty) {
      return const ParseResult.error('Latitude is required');
    }

    final value = double.tryParse(text.trim());
    if (value == null) {
      return const ParseResult.error('Invalid number format');
    }

    final validation = validateLatitude(value);
    if (!validation.isValid) {
      return ParseResult.error(validation.errorMessage!);
    }

    return ParseResult.success(value);
  }

  /// Parses and validates longitude string
  ///
  /// Returns ParseResult with parsed value or error message.
  ParseResult<double> parseLongitude(String text) {
    if (text.trim().isEmpty) {
      return const ParseResult.error('Longitude is required');
    }

    final value = double.tryParse(text.trim());
    if (value == null) {
      return const ParseResult.error('Invalid number format');
    }

    final validation = validateLongitude(value);
    if (!validation.isValid) {
      return ParseResult.error(validation.errorMessage!);
    }

    return ParseResult.success(value);
  }

  /// Parses and validates frequency string (in MHz)
  ///
  /// Returns ParseResult with parsed value or error message.
  ParseResult<double> parseFrequency(String text) {
    if (text.trim().isEmpty) {
      return const ParseResult.error('Frequency is required');
    }

    final value = double.tryParse(text.trim());
    if (value == null) {
      return const ParseResult.error('Invalid number format');
    }

    final validation = validateFrequency(value);
    if (!validation.isValid) {
      return ParseResult.error(validation.errorMessage!);
    }

    return ParseResult.success(value);
  }

  /// Parses and validates TX power string (in dBm)
  ///
  /// Returns ParseResult with parsed value or error message.
  ParseResult<int> parseTxPower(String text, {int? maxPower}) {
    if (text.trim().isEmpty) {
      return const ParseResult.error('TX power is required');
    }

    final value = int.tryParse(text.trim());
    if (value == null) {
      return const ParseResult.error('Invalid number format');
    }

    final validation = validateTxPower(value, maxPower);
    if (!validation.isValid) {
      return ParseResult.error(validation.errorMessage!);
    }

    return ParseResult.success(value);
  }

  // ============================================================================
  // SANITIZATION METHODS
  // ============================================================================

  /// Sanitizes name string
  ///
  /// - Trims whitespace
  /// - Removes control characters
  /// - Truncates to maxLength if specified (defaults to 32)
  String sanitizeName(String name, {int? maxLength}) {
    final max = maxLength ?? 32;

    // Trim whitespace
    String sanitized = name.trim();

    // Remove control characters (0x00-0x1F, 0x7F)
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Truncate if too long
    if (sanitized.length > max) {
      sanitized = sanitized.substring(0, max);
    }

    return sanitized;
  }

  /// Sanitizes password string
  ///
  /// - Removes whitespace
  /// - Removes control characters
  /// - Truncates to 15 characters (MeshCore protocol limit)
  String sanitizePassword(String password) {
    // Remove all whitespace
    String sanitized = password.replaceAll(RegExp(r'\s'), '');

    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Truncate to protocol limit
    if (sanitized.length > 15) {
      sanitized = sanitized.substring(0, 15);
    }

    return sanitized;
  }
}

// ==============================================================================
// RESULT CLASSES
// ==============================================================================

/// Result of a validation operation
///
/// Contains either success (isValid=true) or failure with error message.
class ValidationResult {
  /// Whether the validation passed
  final bool isValid;

  /// Error message if validation failed (null if valid)
  final String? errorMessage;

  /// Creates a valid result
  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  /// Creates an invalid result with error message
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $errorMessage';
  }
}

/// Result of a parse operation
///
/// Contains either parsed value (success) or error message (failure).
class ParseResult<T> {
  /// Parsed value if successful (null if error)
  final T? value;

  /// Error message if parsing failed (null if successful)
  final String? errorMessage;

  /// Creates a successful parse result
  const ParseResult.success(this.value) : errorMessage = null;

  /// Creates a failed parse result with error message
  const ParseResult.error(this.errorMessage) : value = null;

  /// Whether the parse operation succeeded
  bool get isSuccess => value != null;

  @override
  String toString() {
    return isSuccess ? 'Success: $value' : 'Error: $errorMessage';
  }
}
