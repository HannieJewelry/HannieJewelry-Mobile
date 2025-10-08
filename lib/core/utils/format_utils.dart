class FormatUtils {
  /// Format currency amount to Vietnamese dong format
  /// Example: 1000000 -> "1.000.000đ"
  static String formatCurrency(double price) {
    String priceString = price.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < priceString.length; i++) {
      if ((priceString.length - i) % 3 == 0 && i > 0) {
        result.write('.');
      }
      result.write(priceString[i]);
    }
    return '${result.toString()}đ';
  }

  /// Format DateTime to Vietnam timezone and display format
  /// Example: "21:56, 10/09/2025"
  static String formatDateTime(DateTime dateTime) {
    // Convert to Vietnam timezone (UTC+7)
    final vietnamTime = dateTime.toUtc().add(const Duration(hours: 7));
    return '${vietnamTime.hour.toString().padLeft(2, '0')}:${vietnamTime.minute.toString().padLeft(2, '0')}, ${vietnamTime.day.toString().padLeft(2, '0')}/${vietnamTime.month.toString().padLeft(2, '0')}/${vietnamTime.year}';
  }

  /// Format DateTime to Vietnam timezone for timeline display
  /// Example: "10/09/2025 21:56"
  static String formatDateTimeForTimeline(DateTime dateTime) {
    // Convert to Vietnam timezone (UTC+7)
    final vietnamTime = dateTime.toUtc().add(const Duration(hours: 7));
    return '${vietnamTime.day.toString().padLeft(2, '0')}/${vietnamTime.month.toString().padLeft(2, '0')}/${vietnamTime.year} ${vietnamTime.hour.toString().padLeft(2, '0')}:${vietnamTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format phone number for display
  /// Example: "0914696665" -> "091 469 6665"
  static String formatPhoneNumber(String phone) {
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  /// Format address components into a single string
  /// Example: ["123 Le Loi", "Ward 1", "District 1", "Ho Chi Minh"] -> "123 Le Loi, Ward 1, District 1, Ho Chi Minh"
  static String formatAddress(List<String> addressParts) {
    return addressParts.where((part) => part.isNotEmpty).join(', ');
  }
}
