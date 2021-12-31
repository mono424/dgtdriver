import 'package:dgtdriver/protocol/DGTProtocol.dart';

class LEDPattern {
  final LEDPatternSpeed speed;
  final LEDPatternRepeat repeat;
  final LEDPatternBrightness brightness;
  final List<LEDPatternField> fields;

  LEDPattern({this.speed = LEDPatternSpeed.speed2, this.repeat = LEDPatternRepeat.forever, this.brightness = LEDPatternBrightness.middle, this.fields = const []});
}

class LEDPatternField {
  final int index;

  LEDPatternField(this.index);

  static LEDPatternField fromAlgebra(String field) {
    return LEDPatternField(DGTProtocol.squares.indexOf(field.toLowerCase()));
  }
}

enum LEDPatternSpeed {
  speed1, speed2, speed3, speed4, speed5, speed6, speed7
}

enum LEDPatternRepeat {
  forever, once, twice, three_times  
}

enum LEDPatternBrightness {
  highest, high, middle, low
}
