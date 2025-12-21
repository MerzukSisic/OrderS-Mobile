class Validators {
  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  // Password validator
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Required field validator
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return ' is required';
    }
    return null;
  }

  // Phone number validator
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^\d+]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Min length validator
  static String? minLength(String? value, int length) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < length) {
      return 'Must be at least  characters';
    }
    return null;
  }

  // Max length validator
  static String? maxLength(String? value, int length) {
    if (value != null && value.length > length) {
      return 'Must be at most  characters';
    }
    return null;
  }

  // Number validator
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  // Min value validator
  static String? minValue(String? value, double min) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final number = double.tryParse(value);
    if (number == null || number < min) {
      return 'Value must be at least ';
    }
    return null;
  }
}
