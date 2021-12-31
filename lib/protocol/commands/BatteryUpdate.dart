import 'package:dgtdriver/models/BatteryStatus.dart';
import 'package:dgtdriver/protocol/Answer.dart';

class BatteryUpdateAnswer extends Answer<BatteryStatus> {
  final int code = 0x20;

  @override
  process(List<int> msg) {
    double charge = msg[0] / 100;
    bool isCharging = msg.last == 1;
    return BatteryStatus(charge, isCharging);
  }
}