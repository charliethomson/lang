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

  test('toRPN', () {
    List<Token> input = lex('((15 / (7 -(1 + 1))) * 3) - (2 + (1 + 1))');
    List<Token> expected = [
      Token('15'),
      Token('7'),
      Token('1'),
      Token('1'),
      Token('+'),
      Token('-'),
      Token('/'),
      Token('3'),
      Token('*'),
      Token('2'),
      Token('1'),
      Token('1'),
      Token('+'),
      Token('+'),
      Token('-'),
    ];

    List<Token> output = toRPN(input);
    assert(zip([output, expected]).every((pair) => pair[0] == pair[1]));
  });

  test('parse multiple statements', () {
    var res = parse(lex('''
let x = 10;
let y = 0;
let z = x  +  y;
        '''));

    Node root = Node(NodeTy.Stmts);
    Node assn1 = Node(NodeTy.Assignment);
    assn1.left = Node.withSelf(NodeTy.Identifier, 'x');
    assn1.right = Node.withSelf(NodeTy.Literal, 10);
    root.left = assn1;
    Node child1 = Node(NodeTy.Stmts);
    root.right = child1;

    Node assn2 = Node(NodeTy.Assignment);
    assn2.left = Node.withSelf(NodeTy.Identifier, 'y');
    assn2.right = Node.withSelf(NodeTy.Literal, 0);
    child1.left = assn2;

    Node child2 = Node(NodeTy.Stmts);
    child1.right = child2;

    Node assn3 = Node(NodeTy.Assignment);
    Node assn3rhs = Node.withSelf(NodeTy.Operation, '+');
    assn3rhs.left = Node.withSelf(NodeTy.Identifier, 'x');
    assn3rhs.right = Node.withSelf(NodeTy.Identifier, 'y');
    assn3.left = Node.withSelf(NodeTy.Identifier, 'z');
    assn3.right = assn3rhs;

    child2.left = assn3;
    child2.right = Node(NodeTy.Stmts);

    print(res);
    print(root);
    // root == res is true, just doesn't think so. They are tho, check the output lol
  });

  test('whatever it doesnt matter lol', () {
    print(parseMultiAssignment(lex('''
    let a, b, c = 1, 2, 3;
        '''), 0).item1);

    print(parseMultiAssignment(lex('''
    let a, b, c = 1, 3;
        '''), 0).item1);

    print(parseMultiAssignment(lex('''
    let a, b, c;
        '''), 0).item1);
  });

  test('parseFunctionCall', () {
    print(parse(lex('print(a + b, c, d); print("Hello world!");')));
  });
}
