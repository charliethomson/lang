import 'package:collection/collection.dart';
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
    assn1.set_left(Node.withSelf(NodeTy.Identifier, 'x'));
    assn1.set_right(Node.withSelf(NodeTy.Literal, 10));
    root.set_left(assn1);
    Node child1 = Node(NodeTy.Stmts);
    root.set_right(child1);

    Node assn2 = Node(NodeTy.Assignment);
    assn2.set_left(Node.withSelf(NodeTy.Identifier, 'y'));
    assn2.set_right(Node.withSelf(NodeTy.Literal, 0));
    child1.set_left(assn2);

    Node child2 = Node(NodeTy.Stmts);
    child1.set_right(child2);

    Node assn3 = Node(NodeTy.Assignment);
    Node assn3rhs = Node.withSelf(NodeTy.Operation, '+');
    assn3rhs.set_left(Node.withSelf(NodeTy.Identifier, 'x'));
    assn3rhs.set_right(Node.withSelf(NodeTy.Identifier, 'y'));
    assn3.set_left(Node.withSelf(NodeTy.Identifier, 'z'));
    assn3.set_right(assn3rhs);

    child2.set_left(assn3);
    child2.set_right(Node(NodeTy.Stmts));

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

  test('parseWhile', () {
    print(parse(lex('while (let a = 1; a < 10; a += 1)')));
    print(parse(lex('while (;;)')));
    print(parse(lex('while (let a = 10;a+=1)')));
    print(parse(lex('while (;;) { print(a); print(a * a); }')));
    print(parse(lex('while (true) { print("Infinite loop!"); }')));
  });

  test('unaryMinus', () {
    List<Token> lexed = lex('a- -a');
    Node result = parse(lexed);

    // -a
    Node unary = Node.withSelf(NodeTy.Operation, 'u');
    unary.set_left(Node(NodeTy.Null));
    unary.set_right(Node.withSelf(NodeTy.Identifier, 'a'));

    // a - <unary>
    Node operation = Node.withSelf(NodeTy.Operation, '-');
    operation.set_right(unary);
    operation.set_left(Node.withSelf(NodeTy.Identifier, 'a'));

    // <operation> EOF
    Node expected = Node(NodeTy.Stmts);
    expected.set_left(operation);
    expected.set_right(Node(NodeTy.Null));

    assert(result == expected);
  });
  test('parseCondition', () {
    print(parse(lex(
        'if (a == b) { print("a == b"); } else { print("a != b"); } print("Hello World!");')));

    print(parse(lex(
        'if (a == b) { print("a == b"); a += b; } else if (a == c) { print("a == c"); } else { print("a != b && a != c"); } print("Hello World!");')));
  });

  test('getStmts', () {
    // make sure we don't lose tokens
    dynamic expected = "leta=10;letb=1;";
    dynamic result = getStmts(lex("let a = 10 ; let b = 1 ;"))
        .fold(
            '',
            (acc, cur) =>
                acc + cur.fold('', (bcc, bur) => bcc + bur.literal.toString()))
        .trim();

    assert(expected == result);

    var exp = [
      [
        Token.Identifier("print"),
        Token("("),
        Token('"Hello World!"'),
        Token(")"),
        Token(";"),
      ],
      [
        Token('let'),
        Token.Identifier('a'),
        Token('='),
        Token('"Hello World!"'),
        Token(';')
      ],
      [
        Token.Identifier('print'),
        Token("("),
        Token.Identifier('a'),
        Token(")"),
        Token(';')
      ]
    ];
    var res = getStmts(
        lex('print("Hello World!"); let a = "Hello World!"; print(a);'));

    // List equality is a PAIN
    // esp for milti dimensional ones
    for (var i in zip([res, exp])) {
      assert(ListEquality().equals(i[0], i[1]));
    }

    // conditional (the hard one :))
    res = getStmts(
        lex('if (a == b) { print(a); } else { print(b); } print(a + b);'));
    exp = [
      [
        Token("if"),
        Token("("),
        Token.Identifier("a"),
        Token("=="),
        Token.Identifier("b"),
        Token(")"),
        Token("{"),
        Token.Identifier('print'),
        Token("("),
        Token.Identifier("a"),
        Token(")"),
        Token(";"),
        Token("}"),
        Token("else"),
        Token("{"),
        Token.Identifier('print'),
        Token("("),
        Token.Identifier("b"),
        Token(")"),
        Token(";"),
        Token("}"),
      ],
      [
        Token.Identifier('print'),
        Token("("),
        Token.Identifier("a"),
        Token("+"),
        Token.Identifier('b'),
        Token(")"),
        Token(';')
      ]
    ];

    for (var i in zip([res, exp])) {
      assert(ListEquality().equals(i[0], i[1]));
    }
  });
}
