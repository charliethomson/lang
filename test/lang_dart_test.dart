import 'package:quiver/iterables.dart';
import '../bin/lexer.dart';
import '../bin/parser.dart';
import 'package:test/test.dart';

void main() {
  test('scan_number', () {
    var offset = 1;
    var str = '1.213aaa';
    var expected = 'aaa';
    var res = scan_number(str.substring(0, offset), str.substring(offset));
    var outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1.hasTy);
  });

  test('scan_string', () {
    var offset = 1;
    var str = '"Hello World!"';
    var expected = '';
    var expected_output = Token('"Hello World!"');
    var res = scan_string(str.substring(0, offset), str.substring(offset));
    var outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    // With escapes
    offset = 1;
    str = '"Hello \\"World!\\""';
    expected = '';
    expected_output = Token('"Hello \"World!\""');
    res = scan_string(str.substring(0, offset), str.substring(offset));
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    // With random 's
    offset = 1;
    str = '"Hello \\"\'\'\'World!\\""';
    expected = '';
    expected_output = Token('"Hello \"\'\'\'World!\""');
    res = scan_string(str.substring(0, offset), str.substring(offset));
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    // Error
    offset = 1;
    str = '\'Hello World!"';
    res = scan_string(str.substring(0, offset), str.substring(offset));
    assert(res == null);
  });

  test('scan', () {
    var offset = 1;
    var str = 'let x = 10;';
    var expected = ' x = 10;';
    var expected_output = Token('let');
    var res = scan(str.substring(0, offset), str.substring(offset));
    var outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    str = outStr.substring(1);
    offset = 1;
    expected = ' = 10;';
    expected_output = Token.Identifier('x');
    res = scan(str.substring(0, offset), str.substring(offset));
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    str = outStr.substring(1);
    offset = 1;
    expected = ' 10;';
    expected_output = Token('=');
    res = scan(str.substring(0, offset), str.substring(offset));
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    str = outStr.substring(1);
    offset = 1;
    expected = ';';
    expected_output = Token('10');
    res = scan(str.substring(0, offset), str.substring(offset));
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);

    str = outStr.substring(0);
    offset = 1;
    expected = '';
    expected_output = Token(';');
    var c = str.substring(0, offset);
    res = scan(c, '');
    outStr = str.substring(res.item2);
    assert(res != null);
    assert(outStr == expected);
    assert(res.item1 == expected_output);
  });

  test('lex', () {
    var input_str = 'let x = 10;';
    var expected_toks = [
      Token('let'),
      Token.Identifier('x'),
      Token('='),
      Token('10'),
      Token(';'),
    ];

    var res = lex(input_str);

    assert(res.isNotEmpty);
    assert(zip([res, expected_toks]).every((pair) => pair[0] == pair[1]));
  });

  test('lex_multiline', () {
    var input_str = '''
        let x = 10;
        let y = 0;
        while ( y < x ) {
                y += 1;
        }
        print(y);
        ''';

    var expected_toks = [
      Token('let'),
      Token.Identifier('x'),
      Token('='),
      Token('10'),
      Token(';'),
      Token('let'),
      Token.Identifier('y'),
      Token('='),
      Token('0'),
      Token(';'),
      Token('while'),
      Token('('),
      Token.Identifier('y'),
      Token('<'),
      Token.Identifier('x'),
      Token(')'),
      Token('{'),
      Token.Identifier('y'),
      Token('+='),
      Token('1'),
      Token(';'),
      Token('}'),
      Token.Identifier('print'),
      Token('('),
      Token.Identifier('y'),
      Token(')'),
      Token(';'),
    ];

    var res = lex(input_str);
    assert(res.isNotEmpty);
    assert(zip([res, expected_toks]).every((pair) => pair[0] == pair[1]));
  });

  test('node thing', () {
    var res = parse(lex('let foo = function(a,b) { return a + b }'));
    print(res.item1.formatString(0));
  });
}
/*


          stmts
          /   \
        Assn  null
      /     \
    foo     stmts
          /     \
        fndecl  null
      /     \--------->\
    stmts             stmts
  /     \            /     \
a       stmts     return  operation(+)
      /     \             /     \
    b       null         a       b






  NodeTy.Stmts:null
NodeTy.Stmts:null
      NodeTy.Stmts:null
    NodeTy.Stmts:null
            NodeTy.Stmts:null
          NodeTy.Stmts:null
              NodeTy.Identifier:b
            NodeTy.Operation:+
              NodeTy.Identifier:a
        NodeTy.Stmts:null
          NodeTy.Return:null
            NodeTy.Stmts:null
      NodeTy.FunctionDecl:null
            NodeTy.Stmts:null
          NodeTy.Stmts:null
            NodeTy.Identifier:b
        NodeTy.Stmts:null
          NodeTy.Identifier:a
  NodeTy.Assignment:null
    NodeTy.Identifier:foo
*/
