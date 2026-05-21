import '../../models/maintenance.dart';

enum HistoryFilter {
  all,
  last30Days,
  lastWeek,
  last3Days,
}

extension HistoryFilterLabel on HistoryFilter {
  String get label {
    switch (this) {
      case HistoryFilter.all:
        return 'Todos';
      case HistoryFilter.last30Days:
        return 'Últimos 30 días';
      case HistoryFilter.lastWeek:
        return 'Última semana';
      case HistoryFilter.last3Days:
        return 'Últimos 3 días';
    }
  }
}

List<Maintenance> filterHistory({
  required List<Maintenance> history,
  required HistoryFilter filter,
  required DateTime now,
}) {
  if (filter == HistoryFilter.all) return history;

  final Duration cutoff;
  switch (filter) {
    case HistoryFilter.last30Days:
      cutoff = const Duration(days: 30);
      break;
    case HistoryFilter.lastWeek:
      cutoff = const Duration(days: 7);
      break;
    case HistoryFilter.last3Days:
      cutoff = const Duration(days: 3);
      break;
    case HistoryFilter.all:
      return history;
  }

  final threshold = now.subtract(cutoff);
  return history.where((m) => m.fecha.isAfter(threshold)).toList();
}

DateTime? latestMaintenanceDate(List<Maintenance> history) {
  if (history.isEmpty) return null;
  final sorted = List<Maintenance>.from(history)
    ..sort((a, b) => b.fecha.compareTo(a.fecha));
  return sorted.first.fecha;
}

String userInitials(Map<String, dynamic>? user) {
  final rawName = (user?['name'] as String?)?.trim();
  if (rawName == null || rawName.isEmpty) return 'U';

  final parts = rawName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String formatHistoryDate(DateTime date, {DateTime? now}) {
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final target = DateTime(date.year, date.month, date.day);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  if (target == today) return 'Hoy, $hour:$minute';
  if (target == today.subtract(const Duration(days: 1))) {
    return 'Ayer, $hour:$minute';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year;
  return '$day $month $year, $hour:$minute';
}
