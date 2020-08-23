import 'dart:io';

import 'lexer.dart';
import 'parser.dart';
import 'executor.dart';

void main(List<String> arguments) {
  // var file = new File("./examples/fib.ln");
  // var contents = file.readAsStringSync();

  // var test = '';
  // lex(contents).forEach((el) => test += el.literal.toString() + ' ');
  // print(test);

  // print(parse(lex(contents)));

  // executeTree(parse(lex(contents)));

  // startInterpreter();

  // print(parse(lex("let foo = function(a, b) { return a + b; }")));
  executeTree(parse(lex("""
let foo = function(a, b) {
  return a + b; 
}
print(foo(foo(9, 5 + 5), 21));
    """)));
}
