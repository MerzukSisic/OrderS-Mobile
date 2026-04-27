class UserMessage {
  static String friendly(
    Object? raw, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final original = raw?.toString().trim() ?? '';
    if (original.isEmpty) return fallback;

    var message = original;

    if (message.startsWith('Exception:')) {
      return friendly(message.substring('Exception:'.length),
          fallback: fallback);
    }

    final lower = message.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network error') ||
        lower.contains('no internet') ||
        lower.contains('connection error')) {
      return 'We could not connect to the server. Please check your connection and try again.';
    }

    if (lower.contains('timeoutexception') ||
        lower.contains('request timeout') ||
        lower.contains('connection timeout') ||
        lower.contains('receive timeout')) {
      return 'The request took too long. Please try again.';
    }

    if (lower.contains('unauthorized') ||
        lower.contains('status code of 401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (lower.contains('forbidden') || lower.contains('status code of 403')) {
      return 'You do not have permission to perform this action.';
    }

    if (lower.contains('not found') || lower.contains('status code of 404')) {
      return 'We could not find the requested item.';
    }

    if (lower.contains('dioexception') ||
        lower.contains('typeerror') ||
        lower.contains('type ') ||
        lower.contains('null check operator') ||
        lower.contains('formatexception') ||
        lower.contains('unexpected error') ||
        lower.contains('stack trace') ||
        lower.contains('http ') ||
        lower.contains('http://') ||
        lower.contains('https://')) {
      return fallback;
    }

    if (lower.startsWith('failed:')) {
      return fallback;
    }

    final actionMatch = RegExp(
            r'^Error (fetching|creating|updating|deleting|loading) ([^:]+):?',
            caseSensitive: false)
        .firstMatch(message);
    if (actionMatch != null) {
      final verb = actionMatch.group(1)!.toLowerCase();
      final target = actionMatch.group(2)!.trim();
      final friendlyVerb = switch (verb) {
        'fetching' || 'loading' => 'load',
        'creating' => 'create',
        'updating' => 'update',
        'deleting' => 'delete',
        _ => 'complete',
      };
      return 'We could not $friendlyVerb $target. Please try again.';
    }

    final failedMatch = RegExp(r'^Failed to ([^.:]+)', caseSensitive: false)
        .firstMatch(message);
    if (failedMatch != null) {
      final action = failedMatch.group(1)!.trim();
      return 'We could not $action. Please try again.';
    }

    if (message.length > 160) {
      return fallback;
    }

    return message;
  }
}
