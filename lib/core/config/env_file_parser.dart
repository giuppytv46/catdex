class EnvFileParser {
  const EnvFileParser();

  Map<String, String> parse(String source) {
    final values = <String, String>{};

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      if (key.isEmpty) {
        continue;
      }

      values[key] = _unquote(value);
    }

    return values;
  }

  String _unquote(String value) {
    if (value.length < 2) {
      return value;
    }

    final startsWithSingleQuote = value.startsWith("'");
    final startsWithDoubleQuote = value.startsWith('"');
    final endsWithSingleQuote = value.endsWith("'");
    final endsWithDoubleQuote = value.endsWith('"');
    if ((startsWithSingleQuote && endsWithSingleQuote) ||
        (startsWithDoubleQuote && endsWithDoubleQuote)) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }
}
