import 'dart:io';

import 'lexer.dart';
import 'parser.dart';

void main(List<String> arguments) {
  print(parse(lex('a - - 2')));
}
