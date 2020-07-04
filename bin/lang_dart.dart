import 'dart:io';

import 'lexer.dart' as lexer;

void main(List<String> arguments) {
  var file = new File("./examples/fib.ln");
  var contents = file.readAsStringSync();

  lexer.lex(contents).forEach((element) {
    print('${element.ty} -> ${element.literal}');
  });
}
