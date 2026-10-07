String formatPkr(int paisa) {
  final rupees = paisa.abs() ~/ 100;
  final cents = paisa.abs() % 100;
  final digits = rupees.toString();
  final grouped = digits.length <= 3
      ? digits
      : '${digits.substring(0, digits.length - 3).replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (match) => ',')},${digits.substring(digits.length - 3)}';
  return '${paisa < 0 ? '-' : ''}Rs $grouped.${cents.toString().padLeft(2, '0')}';
}

int? parsePaisa(String value) {
  final normalized = value.replaceAll(',', '').trim();
  final rupees = double.tryParse(normalized);
  if (rupees == null || !rupees.isFinite || rupees <= 0) return null;
  return (rupees * 100).round();
}
