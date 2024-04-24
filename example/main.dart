import 'dart:convert';

import 'package:json5/json5.dart';

void main() {
  /*
  var obj = JSON5.parse('{                '
      '  /*  comment block  */            '
      '  name: {first: "phat"},           '
      '  lang: ["C++", "dart", "kotlin"], '
      '  nums: [NaN, Infinity, -Infinity] '
      '} // end object                    ');

  var compact = JSON5.stringify(obj);

  print(compact);

  var pretty = JSON5.stringify(obj, space: 2);

  print(pretty);
  */

  final json = '''
{
  "scoId": "SCO_JIP_2",
  //"scoId": "{\"locId\": 2, \"tilNum\": \"11\"}",
  //"scoCenterUrl": "wss://localhost:4000",
  //"scoCenterUrl": "wss://non-stop-get24.4max.com:4000",
  "scoCenterUrl": "wss://85.255.9.192:4000",
  "scoBackendType": "http", // "simulator",
  "pickListDirectoryPath": "~/sco_picklist_test_data",
  "pickListItemBackgroundColor": "0xFFFFFFFF",
  "picklistUpdateSchedule": "* * * * *", // koko
  "askToScanCustomerCard": true,
  "paymentCompletedScreenReceiptForGate": true,
  "poleLightType": "none", // none, ccl, dnElectronics
  "forceFinishDialogEnabled": true, // default is false, changing this setting to true will enable a "force finish" option, if finishSession call to backend fails on the payment completed
  "currency": "CZK",
  "controlScale": {
    "controlScaleType": "simulator",
    "controlScalePortAddress": "",
    "weightLogFilePath": "~/sco/logs/weights.txt",
    "controlScaleTolerance": 10,
    "maxControlScaleWeightLimit": 50000
  },
  "pss": {           // Used to import products from PSS session (we directly contact the PSS backend)
    "pssBranchId": "4",
    "eotQrCode": {
      "enabled": true,
      "scoId": null, // string - if null, scoId will be used
      "totpSecret": "MZQWMYLGMFZWMYLDMFRWC43DMFYXO===",
      "eotCodeTemplate": "VEOT|%id%|%totp%", // available placeholders: %id%, %timestamp%, %totp%
      "timeCorrectionInMinutes": -60
    }
  },
  "weighing": {
    "type": "disabled", // sco, backend, disabled, unspecified
    "moduleChecksum": "1e4dce806463d86c5be8217522f8154f"
  },
  "barcodeReader": {
	"barcodeReaderType": "simulator",
    "barcodeReaderSerialPorts": ["COM9"],
    "barcodeReaderHIDEnabled": true,   // enable or disable HID barcode reader
    "barcodeReaderHIDTimeoutMs": 200,
	"barcodeSimulator": {
		//"f1": { "code": "eyJjdXN0b21lclRva2VuIjoiZWM4NTE2NmEtNTc0Ny00Nzc4LWE5MTctNTU2ODQ2Y2FhNTAxIiwiYWdlR3JvdXAiOiIyMS05OTkiLCJleHBpcmF0aW9uIjoiMjAyMy0xMS0xNFQxNzo1Mjo0Ni4wMDAifQ==", "type": "QR" },
		//"f1": { "code": "NS|CNGq47BhQJSBHKLoasD6ag", "type": "QR" },
		"f1": { "code": "41211502", "type": "EAN13" },			// zakaznicka karta JIP
		//"f1": { "code": "23005099", "type": "EAN13" },		// zakaznicka karta JIP retail
		//"f1": { "code": "21029271", "type": "EAN13" },		// zakaznicka karta JIP retail + wholesale
		//"f1": { "code": "99912345", "type": "EAN13" },		 // zakaznicka karta DEMO
		"f2": { "code": "8594003848445", "type": "EAN13" },		// pivo + lahev
		"f3": { "code": "2826410020005", "type": "EAN13" },     // 2ks větrník
		"f4": { "code": "2816844003705", "type": "EAN13" },
		"f5": { "code": "8594403110418", "type": "EAN13" },
		"f6": { "code": "2000950251017", "type": "EAN13" },
		"f7": { "code": "2417100893209", "type": "EAN13" },
		"f8": { "code": "9820261405113", "type": "EAN13" },
		"f9": { "code": "2400020001342", "type": "EAN13" }, 
		"f10": { "code": "2400010009587", "type": "EAN13" }, 
		"f11": { "code": "2103480010687", "type": "EAN13" }, 
		"f12": { "code": "{\\"PurchaseId\\":\\"73fe688e-1a4f-4f9d-ae95-cd588251c78a\\",\\"TransactionNumber\\":182,\\"StoreNumber\\":326}", "type": "QR" }
	  },
  },
  "displayStreaming": { 
    "streamingEnabled": true,
    "port": 8001,
    "fps": 20,
    "pixelRatio": 4.0,
    "streamUrlForScoCenter": "http://localhost:8001/stream.mjpeg"
  },  
  "logFilePath": "~/sco/logs/log.txt",
  //"customAssetsFolder": "c:\\Users\\HonzaF\\Documents\\sco\\GET24\\",
  "showPvaInAbout": false,
  "securityTokens": ["01:56:32:a0:1b:00:00:84"],
  "timeBeforeShowingBackendBusyOverlayMs": 1500,
  "showCashPaymentButton": true,
  "checkPosProcessRunning": false,
  "allowPayNegativePrice": false,
  //"windowScaleX": 0.6,
  //"windowScaleY": 1.0,
  "users": {"5": "5"},
  "defaultLanguage": "cs", // en, cs, de, sk, ru, uk, ky
  "availableLanguages": ["cs","en","de", "sk"],//The language list will be displayed in the order it is configured
  "paymentTypes": ["creditCard", "cash"],
  "autoStartCreditCardPayment": false,
  "beerCrateBarcode": "PP20",
  "httpPos": {
    "url": "http://localhost:8080", // http backend
    //"url": "http://localhost:5145", // weighing proxy
	//"url": "http://localhost:8088", // Delmart through SSH tunnel
    //"url": "http://192.168.4.224:8088", // Kancl unipi
    "notificationsPort": 8081,
	"testPurchasesSupported": true // does the http POS support test/training purchases?
  },
  "scoNetworkPrinter": {
	"port": 9150, // default port, 9100 is blocked on windows, let's see on Linux
	"printerConnection": "COM7"
  },
  "scanFindButtons": [
    { "type": "pickList" },
    { "type": "find" }
  ],
  "pickListButtons": [
    { "type": "pickList" }
  ],
}      ''';

  /*var test1 = JSON5.patch(json, {});

  print('Patched data: $test1');

  var original = JSON5.parse(json);
  var parsed1 = JSON5.parse(test1);

  print('\n\nNo change - equals: ${json5Encode(original) == json5Encode(parsed1)}');*/

  var test2 = JSON5.patch(json, {
    "picklistUpdateSchedule": "123456987",
    "barcodeReader": {
      "barcodeSimulator": null,
      "foo": {"bar": "baz"},
    },
    "koko": 0,
  });

  var parsed2 = JSON5.parse(test2);
  print(JsonEncoder.withIndent('  ').convert(parsed2));

  print('picklistUpdateSchedule: ' + (parsed2['picklistUpdateSchedule'] == "123456987").toString());
  print('koko: ' + (parsed2['koko'] == 0).toString());
  print('foo.bar: ' + (parsed2['barcodeReader']?['foo']?['bar'] == "baz").toString());

  print(test2);
}
