import 'dart:convert';

import 'parse.dart' as parser;
import 'stringify.dart' as render;

class _StackMember {
  final String propertyName;
  String valueType;
  bool shouldReplace = false;
  bool hasCommaAfter = false;

  _StackMember({required this.propertyName, required this.valueType});

  @override
  String toString() => "$propertyName: $valueType";
}

String patch(String string, dynamic newValues) {
  final tokens = parser.split(string);

  var buffer = '';
  var stack = <_StackMember>[];
  var lastString = 'root';
  var patchList = _buildPatchList(newValues);

  void push(String propertyName, String valueType) {
    stack.add(_StackMember(propertyName: propertyName, valueType: valueType));

    if (valueType == 'property') {
      final currentId = stack.skip(1).map((e) => e.propertyName).join('.');
      final repl = patchList[currentId];
      if (repl != null) {
        stack.last.shouldReplace = true;
      }
    }
  }

  void pop() {
    String currentId = stack.skip(1).map((e) => e.propertyName).join('.');

    if (stack.lastOrNull?.shouldReplace == true) {
      final replacement = patchList[currentId];
      patchList.remove(currentId);

      buffer += replacement ?? '';
    }

    bool addComma = !(stack.lastOrNull?.hasCommaAfter ?? false);
    stack.removeLast();

    final patches = patchList.entries
        .where((k) => k.key.startsWith(currentId))
        .map((e) => MapEntry(e.key.substring(currentId.isEmpty ? 0 : currentId.length + 1), e.value))
        .toList();
    if (patches.isNotEmpty) {
      var data = _stringifyPatches(_mergePatches(patches));
      buffer += '${addComma ? ', ' : ''}$data\n';

      for (var key in patches.map((kvp) => kvp.key)) {
        patchList.remove('${currentId.isEmpty ? '' : currentId + '.'}$key');
      }
    }
  }

  void changeType(String valueType) {
    stack.lastOrNull?.valueType = valueType;
  }

  bool isReplacing() {
    return stack.where((e) => e.shouldReplace).isNotEmpty;
  }

  for (var token in tokens) {
    String tokenStr = (token!.value?.toString() ?? (token.type == 'null' ? 'null' : ''));

    bool ignore = isReplacing();

    switch (token.type) {
      case "identifier":
      case "string":
        lastString = tokenStr;
        tokenStr = render.quoteString(tokenStr, preferredQuote: token.doubleQuote ? '"' : ":");
        break;
      case "punctuator":
        switch (tokenStr) {
          case "{":
            if (stack.isNotEmpty && stack.last.propertyName == lastString && stack.last.valueType == 'property') {
              changeType('object');
            } else {
              push(lastString, 'object');
            }
            break;
          case "[":
            if (stack.isNotEmpty && stack.last.propertyName == lastString && stack.last.valueType == 'property') {
              changeType('object');
            } else {
              push(lastString, 'array');
            }
            break;
          case ":":
            push(lastString, 'property');
            break;
          case "}":
          case "]":
            if (stack.isNotEmpty) {
              if (stack.last.valueType == 'property') {
                pop();
                ignore = isReplacing();
              }
              pop();
            }
            break;
          case ",":
            stack.last.hasCommaAfter = true;
            if (stack.last.valueType == 'property') {
              pop();
              ignore = isReplacing();
            }
            break;
        }
        break;

      default:
        break;
    }

    if (!ignore) {
      buffer += tokenStr;
    }
  }

  return buffer;
}

Map<String, String> _buildPatchList(dynamic newValues) {
  var result = <String, String>{};

  if (newValues is Map<String, dynamic>) {
    for (var kvp in newValues.entries) {
      var value = kvp.value;
      if (value is List) {
        for (var idx = 0; idx < value.length; idx++) {
          final val = value[idx];
          if (val is List || val is Map<String, dynamic>) {
            var data = _buildPatchList(val);
            for (var innerKey in data.keys) {
              result['${kvp.key}.$idx.$innerKey'] = data[innerKey] ?? '"null"';
            }
          } else {
            result['${kvp.key}.$idx'] = jsonEncode(val);
            ;
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
        '\n]';
  } else {
    return (addBraces ? '{\n' : '') +
        merged.entries.map((e) {
          var valueStr = e.value is List || e.value is Map<String, dynamic>
              ? _stringifyPatches(e.value, addBraces: true, indent: indent + 2)
              : e.value?.toString();
          return '${' ' * indent}"${e.key}": $valueStr';
        }).join(',\n') +
        (addBraces ? '\n}' : '');
  }
}
