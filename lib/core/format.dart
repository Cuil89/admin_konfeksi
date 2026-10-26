/// Locale helpers for Indonesian formatting (IDR, dates) without extra deps.
/// All money is handled as integer Rupiah to avoid floating point errors.
abstract final class Fmt {
  static const monthsLong = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const weekdays = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  /// 88000000 -> "88.000.000"
  static String thousands(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
    }
    return negative ? '-$buf' : buf.toString();
  }

  /// 88000000 -> "Rp88.000.000", negative -> "−Rp4.000.000"
  static String rupiah(int value, {bool forceNegative = false}) {
    final neg = value < 0 || (forceNegative && value != 0);
    return '${neg ? '−' : ''}Rp${thousands(value.abs())}';
  }

  /// Compact form for charts: 88000000 -> "88 jt", 1250000000 -> "1,3 M"
  static String compact(int value) {
    final v = value.abs();
    String trim(double d) {
      final s = d.toStringAsFixed(1);
      return s.endsWith('.0')
          ? s.substring(0, s.length - 2)
          : s.replaceAll('.', ',');
    }

    if (v >= 1000000000) return '${trim(v / 1e9)} M';
    if (v >= 1000000) return '${trim(v / 1e6)} jt';
    if (v >= 1000) return '${trim(v / 1e3)} rb';
    return v.toString();
  }

  static String percent(double ratio, {int decimals = 1}) {
    final p = (ratio * 100);
    var s = p.toStringAsFixed(decimals);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return '${s.replaceAll('.', ',')}%';
  }

  static String two(int n) => n.toString().padLeft(2, '0');

  /// "25 Okt 2026"
  static String date(DateTime d) =>
      '${two(d.day)} ${monthsShort[d.month - 1]} ${d.year}';

  /// "25 Oktober 2026"
  static String dateLong(DateTime d) =>
      '${d.day} ${monthsLong[d.month - 1]} ${d.year}';

  /// "Senin, 26 Okt 2026"
  static String dateWithDay(DateTime d) =>
      '${weekdays[d.weekday - 1]}, ${d.day} ${monthsShort[d.month - 1]} ${d.year}';

  /// "Oktober 2026"
  static String monthYear(int year, int month) =>
      '${monthsLong[month - 1]} $year';

  /// "23 Okt, 09.41 WIB"
  static String updatedAt(DateTime d) =>
      '${d.day} ${monthsShort[d.month - 1]}, ${two(d.hour)}.${two(d.minute)} WIB';

  /// "26 Okt 2026, 13.05"
  static String dateTime(DateTime d) =>
      '${date(d)}, ${two(d.hour)}.${two(d.minute)}';

  static String isoDay(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)}';

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Aditya Pratama" -> "AP"
  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String firstName(String name) => name.trim().split(RegExp(r'\s+')).first;

  /// Masks phone numbers for list views (data minimisation):
  /// "081234561234" -> "0812-****-1234"
  static String maskPhone(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.length < 8) return '****';
    return '${d.substring(0, 4)}-****-${d.substring(d.length - 4)}';
  }
}
