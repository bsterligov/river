import 'package:flutter/foundation.dart';

class TimeRangeController extends ChangeNotifier {
  TimeRangeController() {
    final now = DateTime.now().toUtc();
    _from = now.subtract(const Duration(hours: 1));
    _to = now;
  }

  late DateTime _from;
  late DateTime _to;

  DateTime get from => _from;
  DateTime get to => _to;

  void setRange(DateTime from, DateTime to) {
    _from = from;
    _to = to;
    notifyListeners();
  }
}
