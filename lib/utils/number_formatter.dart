class NumberFormatter {
  static String formatNumber(double number) {
    // Convert to integer since we're already using toStringAsFixed(0) everywhere
    int numberInt = number.round();
    String numStr = numberInt.abs().toString();
    String result = '';
    int count = 0;

    // Process digits from right to left
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        result = ' $result';
      }
      result = numStr[i] + result;
      count++;
    }

    // Add negative sign if needed
    if (numberInt < 0) {
      result = '-$result';
    }

    return result;
  }
}
