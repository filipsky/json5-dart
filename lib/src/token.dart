class Token {
  final String type;
  final Object? value;
  final int? line;
  final int? column;
  final bool doubleQuote;
  Token(this.type, this.value, this.line, this.column, {this.doubleQuote = false});

  @override
  String toString() => '[$type: $value]';
}
