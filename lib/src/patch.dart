import 'dart:convert';
import 'dart:math';

import 'package:json5/json5.dart';
import 'package:json5/src/token.dart';

import 'parse.dart' as parser;
import 'stringify.dart' as render;

class _StackMember {
  final String propertyName;
  String valueType;
  bool hasReplacement = false;
  bool hasReplacementChildren = false;
  bool hasCommaAfter = false;
  bool hasChildren = false;

  _StackMember({required this.propertyName, required this.valueType});

  @override
  String toString() => "$propertyName: $valueType";
}

String patch(String jsonStr, dynamic newValues) {
  final tokens = parser.split(jsonStr, excludeCommentsAndWhitespace: false);

  var outputBuffer = '';
  var propertyStack = <_StackMember>[];
  var lastStringValue = 'root';
  var patchList = _buildPatchList(newValues);

  if (patchList.isEmpty) {
    return jsonStr;
  }

  void push(String propertyName, String valueType) {
    if (propertyStack.isNotEmpty) {
      final parent = propertyStack.last;
      if (parent.valueType == "object" || parent.valueType == "array") {
        parent.hasChildren = true;
      }
    }

    propertyStack.add(_StackMember(propertyName: propertyName, valueType: valueType));

    if (valueType == 'property') {
      final currentId = propertyStack.skip(1).map((e) => e.propertyName).join('.');
      final repl = patchList[currentId];
      if (repl != null) {
        propertyStack.last.hasReplacement = true;
      } else if (patchList.keys.where((key) => key.startsWith('$currentId.') && !key.substring(currentId.length + 1).contains('.')).isNotEmpty) {
        propertyStack.last.hasReplacementChildren = true;
      }
    }
  }

  void pop() {
    String currentId = propertyStack.skip(1).map((e) => e.propertyName).join('.');

    if (propertyStack.lastOrNull?.hasReplacement == true) {
      final replacement = patchList[currentId];
      patchList.remove(currentId);

      outputBuffer += replacement ?? '';
    }

    bool addComma = false;
    final parent = propertyStack.lastOrNull;
    if (parent != null) {
      addComma = parent.hasChildren && !parent.hasCommaAfter;
    }

    propertyStack.removeLast();

    final patches = patchList.entries
        .where((k) => k.key.startsWith(currentId))
        .map((e) => MapEntry(e.key.substring(currentId.isEmpty ? 0 : currentId.length + 1), e.value))
        .toList();

    if (patches.isNotEmpty) {
      final addBraces = parent?.valueType != 'object';
      var indent = addBraces ? 2 : 0;
      var lastLine = outputBuffer.split('\n').where((line) => line.trim().isNotEmpty).lastOrNull ?? '';
      indent += lastLine.length - lastLine.trimLeft().length;
      lastLine = lastLine.trimRight();
      if (lastLine.endsWith('{') || lastLine.endsWith('[')) {
        indent += 2;
      }

      var addNewLineAfter = false;

      var data = _stringifyPatches(_mergePatches(patches), addBraces: addBraces, indent: max(0, indent));
      if (addComma) {
        String newLines = '';
        while (outputBuffer.endsWith('\n') || outputBuffer.endsWith('\r') || outputBuffer.endsWith(' ')) {
          newLines += outputBuffer[outputBuffer.length - 1];
          outputBuffer = outputBuffer.substring(0, outputBuffer.length - 1);
        }
        if (newLines.isEmpty) {
          newLines = '\n';
        }
        outputBuffer += ',' + newLines;
      } else if (lastLine.endsWith('{') || lastLine.endsWith('[')) {
        outputBuffer += '\n';
        addNewLineAfter = true;
      }
      outputBuffer += data;
      if (addNewLineAfter) {
        outputBuffer += '\n${' ' * indent}';
      }

      for (var key in patches.map((kvp) => kvp.key)) {
        patchList.remove('${currentId.isEmpty ? '' : currentId + '.'}$key');
      }
    }
  }

  void changeType(String valueType) {
    propertyStack.lastOrNull?.valueType = valueType;
  }

  bool isReplacing() {
    return propertyStack.where((e) => e.hasReplacement || (e.valueType != 'object' && e.hasReplacementChildren)).isNotEmpty;
  }

  Token? lastToken = null;

  for (var token in tokens) {
    String tokenStr = (token!.value?.toString() ?? (token.type == 'null' ? 'null' : ''));

    bool replacing = isReplacing();

    switch (token.type) {
      case "whitespace":
        if (replacing && lastToken?.type == "punctuator" && lastToken!.value == ":") {
          replacing = false;
        }
        break;

      case "identifier":
      case "string":
        lastStringValue = tokenStr;
        tokenStr = render.quoteString(tokenStr, preferredQuote: token.doubleQuote ? '"' : ":");
        break;

      case "punctuator":
        switch (tokenStr) {
          case "{":
            if (propertyStack.isNotEmpty && propertyStack.last.propertyName == lastStringValue && propertyStack.last.valueType == 'property') {
              changeType('object');
              replacing = isReplacing();
            } else {
              push(lastStringValue, 'object');
            }
            break;
          case "[":
            if (propertyStack.isNotEmpty && propertyStack.last.propertyName == lastStringValue && propertyStack.last.valueType == 'property') {
              changeType('array');
              replacing = isReplacing();
            } else {
              push(lastStringValue, 'array');
            }
            break;
          case ":":
            push(lastStringValue, 'property');
            break;
          case "}":
          case "]":
            if (propertyStack.isNotEmpty) {
              if (propertyStack.last.valueType == 'property') {
                pop();
                replacing = isReplacing();
                //if (!replacing) {
                //  outputBuffer += tokenStr;
                //  tokenStr = '';
                //}
              }
              pop();
            }
            break;
          case ",":
            propertyStack.last.hasCommaAfter = true;
            if (propertyStack.last.valueType == 'property') {
              pop();
              replacing = isReplacing();
            }
            break;
        }
        break;

      default:
        break;
    }

    if (!replacing) {
      outputBuffer += tokenStr;
    }

    lastToken = token;
  }

  assert(() {
    try {
      JSON5.parse(outputBuffer);
      return true;
    } catch (e) {
      print(outputBuffer);
      throw Exception('Error patching JSON string, the result is not valid: $e');
    }
  }());

  return outputBuffer;
}

Map<String, String> _buildPatchList(dynamic newValues) {
  var result = <String, String>{};

  if (newValues is Map<String, dynamic>) {
    for (var kvp in newValues.entries) {
      var value = kvp.value;
      if (value is List) {
        if (value.isEmpty) {
          result[kvp.key] = jsonEncode(value);
        } else {
          for (var idx = 0; idx < value.length; idx++) {
            final val = value[idx];
            if (val is List || val is Map<String, dynamic>) {
              var data = _buildPatchList(val);
              for (var innerKey in data.keys) {
                result['${kvp.key}.$idx.$innerKey'] = data[innerKey] ?? '"null"';
              }
            } else {
              result['${kvp.key}.$idx'] = jsonEncode(val);
            }
          }
        }
      } else if (value is Map<String, dynamic>) {
        var data = _buildPatchList(value);
        for (var innerKey in data.keys) {
          result['${kvp.key}.$innerKey'] = data[innerKey] ?? '"null"';
        }
      } else {
        result[kvp.key] = jsonEncode(value);
      }
    }
  }

  return result;
}

Map<String, dynamic> _mergePatches(Iterable<MapEntry<String, String>> data) {
  final result = <String, dynamic>{};

  for (var entry in data) {
    var parts = entry.key.split('.');
    if (parts.length == 1) {
      result[parts.first] = entry.value;
    } else {
      final prefix = parts.first + '.';
      result[parts.first] =
          _mergePatches(data.where((kvp) => kvp.key.startsWith(prefix)).map((kvp) => MapEntry(kvp.key.substring(prefix.length), kvp.value)));
    }
  }

  return result;
}

String _stringifyPatches(Map<String, dynamic> merged, {bool addBraces = false, int indent = 2}) {
  var isArray = !merged.keys.any((prop) => int.tryParse(prop) == null);

  if (isArray) {
    return '[\n' +
        merged.values.map((e) {
          var valueStr = e is List || e is Map<String, dynamic> ? _stringifyPatches(e, addBraces: true, indent: indent + 2) : e.toString();
          return '${' ' * indent}$valueStr';
        }).join(',\n') +
        '\n${' ' * max(indent - 2, 0)}]';
  } else {
    return (addBraces ? '{\n' : '') +
        merged.entries.map((e) {
          var valueStr = e.value is List || e.value is Map<String, dynamic>
              ? _stringifyPatches(e.value, addBraces: true, indent: indent + 2)
              : e.value?.toString();
          return '${' ' * indent}"${e.key}": $valueStr';
        }).join(',\n') +
        (addBraces ? '\n${' ' * max(indent - 2, 0)}}' : '');
  }
}
