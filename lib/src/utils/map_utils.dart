import 'dart:collection';
import 'dart:convert';

class MapUtils {
  static String printPrettyMap(Map mapData, {bool sort = true}) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');

    // display map in alphabetic order
    if (sort){
      mapData = new SplayTreeMap<String, dynamic>.from(
          mapData, (a, b) => a.compareTo(b));
    }
    String prettyPrint = encoder.convert(mapData);

    return prettyPrint;
  }
}
