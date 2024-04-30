import 'package:json5/json5.dart';
import 'package:test/test.dart';

void main() {
  test('Should replace simple values', shoudReplaceSimpleValues);
  test('Should add new items', shoudAddNewItems);
  test('Should replace nested values', shoudReplaceNestedValues);
}

void shoudReplaceSimpleValues() {
  final json = '''{
  "backendUrl": "https://192.168.1.10:8443", // store controller IP address
  "videoDarkening": 0.8,                     // draws black overlay with this alpha value over the video
  "storeStateCheckPeriodMs": 1000,           // how ofteh to call the store controllers /api/gateKeeper/getState enpoint
  "loggingEnabled": true,                    // log to file
  "doorOpeningDurationMs": 7000,             // how long to keep the door open (max 20s to prevent lock overheating)
  "faceDetectionEnabled": true,              // detect human faces in the camera feed (sleep when presence not detected, wake if face seen)
  "batteryDischargingEnabled": false,        // true - run on battery when discharging between 80% and 20%, then charge till 80%, false - turn off the phone when unplugged
  "apiPort": 8082                            // api port
}''';

  var patched = JSON5.patch(json, {
    "videoDarkening": 1.0,
    "loggingEnabled": false,
  });

  expect(() => JSON5.parse(patched), returnsNormally);
  expect(patched, contains('"videoDarkening": 1.0,                     // draws black overlay with this alpha value over the video'));
  expect(patched, contains('"loggingEnabled": false,                    // log to file'));

  final parsed = JSON5.parse(patched);
  expect(parsed, containsPair("videoDarkening", 1.0));
  expect(parsed, containsPair("loggingEnabled", false));
}

void shoudAddNewItems() {
  final json = '''{
  "foo": { "bar": "baz" }
}''';

  var patched = JSON5.patch(json, {
    "bool": true,
    "number": 1,
    "string": "",
    "null": null,
    "array": [],
    "object": {},
  });

  expect(() => JSON5.parse(patched), returnsNormally);
  expect(patched, contains('"bool": true'));
  expect(patched, contains('"number": 1'));
  expect(patched, contains('"string": ""'));
  expect(patched, contains('"null": null'));
  expect(patched, contains('"array": []'));
  expect(patched, contains('"object": {}'));

  final parsed = JSON5.parse(patched);
  expect(parsed, containsPair("bool", true));
  expect(parsed, containsPair("number", 1));
  expect(parsed, containsPair("string", ""));
  expect(parsed, containsPair("null", null));
  expect(parsed, containsPair("array", []));
  expect(parsed, containsPair("object", {}));
}

void shoudReplaceNestedValues() {
  final json = '''{
  "test": "test", 
  "first": {
    "test": "test", 
    "second": {
      "test": "test", 
     }
  }
}''';

  var patched = JSON5.patch(json, {
    "test": 'test1',
    "first": {
      "test": 'test2',
      "second": {
        "test": 'test3',
      }
    }
  });

  expect(() => JSON5.parse(patched), returnsNormally);

  final parsed = JSON5.parse(patched);
  expect(parsed, containsPair("test", "test1"));
  expect(parsed, containsPair("first", containsPair("test", "test2")));
  expect(parsed, containsPair("first", containsPair("second", containsPair("test", "test3"))));
}
