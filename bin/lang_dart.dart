import 'dart:io';

import 'lexer.dart';
import 'parser.dart';

void main(List<String> arguments) {
  var file = new File("./examples/fib.ln");
  var contents = file.readAsStringSync();

  print(parse(lex(contents)));
}

/*

    Stmts
  Stmts
                  Stmts
                Stmts
                    Identifier:z
                  Operation:=
                    Identifier:y
              Stmts
                  Identifier:y
                Operation:=
                  Identifier:x
            Stmts
                  Identifier:y
                Operation:+
                  Identifier:x
              Operation:=
                Identifier:z
          Stmts
              Stmts
            While
              BooleanCondition
                  Literal:255
                Operation:<
                  Identifier:z
        Stmts
            Literal:1
          Operation:=
            Identifier:y
      Stmts
          Literal:0
        Operation:=
          Identifier:x
    While
      BooleanCondition
        Literal:true
Stmts
      MultiAssignment
          Null
        Assignment
          Identifier:z
    MultiAssignment
        Null
      Assignment
        Identifier:y
  MultiAssignment
      Null
    Assignment
      Identifier:x
*/
