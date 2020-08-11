import 'dart:io';

import 'lexer.dart';
import 'parser.dart';

void main(List<String> arguments) {
  var file = new File("./examples/fib.ln");
  var contents = file.readAsStringSync();

  print(parse(lex(contents)));
}
