/// Manages Xcode configuration files
class XcodeConfigManager {
  /// Validates configuration structure
  bool validateConfiguration(String content) {
    // Basic validation for matching braces
    var braceCount = 0;
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '{') braceCount++;
      if (content[i] == '}') braceCount--;
      if (braceCount < 0) return false;
    }
    return braceCount == 0;
  }

  /// Finds matching closing brace
  int? findMatchingCloseBrace(String content, int openBraceIndex) {
    var braceCount = 1;
    var pos = openBraceIndex + 1;

    while (pos < content.length && braceCount > 0) {
      if (content[pos] == '{') {
        braceCount++;
      } else if (content[pos] == '}') {
        braceCount--;
      }
      pos++;
    }

    return braceCount == 0 ? pos - 1 : null;
  }
}
