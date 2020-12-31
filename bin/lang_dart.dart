import 'dart:io';

import 'lexer.dart';
import 'parser.dart';
import 'executor.dart';

void main(List<String> arguments) {
  // var file = new File("./examples/fib.ln");
  // var contents = file.readAsStringSync();

  // var lexed = lex(contents);
  // print(lexed.fold(
  //     "".toString(),
  //     (previousValue, element) =>
  //         previousValue.toString() + element.literal.toString()));
  // var parsed = parse(lexed);
  // print(parsed);

  // executeTree(parsed);

  startInterpreter();

//   // print(parse(lex("let foo = function(a, b) { return a + b; }")));
//   executeTree(parse(lex("""
// let foo = function(a, b) {
//   return a + b;
// }
// print(foo(foo(9, 5 + 5), 21));
//     """)));
}
