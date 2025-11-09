import 'package:intl/intl.dart';

String formatTimeOfDay(DateTime dateTime, {required String locale}) {
  final formatter = DateFormat('HH:mm', locale);
  return formatter.format(dateTime.toLocal());
}

String formatFullDateTime(DateTime dateTime, {required String locale}) {
  final formatter = DateFormat('d MMMM yyyy, HH:mm', locale);
  return formatter.format(dateTime.toLocal());
}
