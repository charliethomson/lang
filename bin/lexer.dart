import 'package:tuple/tuple.dart';

enum TokenTy {
  Operator,
  Literal,
  Identifier,
  Punctuation,
  Keyword,
}

class Token {
  TokenTy ty;
  var literal;

  Token(this.literal) {
    if (isKeyword(literal)) {
      ty = TokenTy.Keyword;
    } else if (isOperator(literal)) {
      ty = TokenTy.Operator;
    } else if (isPunctuation(literal)) {
      ty = TokenTy.Punctuation;
    } else if (isLiteral(literal)) {
      literal = parseLiteral(literal);
      ty = TokenTy.Literal;
    } else {
      ty = null;
    }
  }

  Token.Identifier(this.literal) {
    this.ty = TokenTy.Identifier;
  }

  bool get hasTy => ty != null;

  bool get isOperation =>
      [
        '+',
        '-',
        'u', // Unary minus
        '*',
        '/',
        '^',
        '%',
        '+=',
        '-=',
        '*=',
        '/=',
        '^=',
        '%=',
      ].contains(literal) ||
      isUnaryOperation;

  bool get isBooleanOperation =>
      [
        '=',
        '<',
        '<=',
        '==',
        '>=',
        '>',
        '!=',
      ].contains(literal) ||
      isBang;

  bool get isUnaryOperation => [
        '++',
        '--',
        'u',
      ].contains(literal);

  bool get isBang => literal == '!';

  bool operator ==(other) =>
      other is Token && (other.literal == literal && other.ty == ty);

  bool get isValidOperatorTy =>
      [TokenTy.Literal, TokenTy.Identifier].contains(ty) ||
      '()'.contains(literal) ||
      this.isOperation ||
      this.isBooleanOperation;

  bool get isRightAssociative => literal == '^';

  int precedence() {
    switch (literal) {
      case '+':
      case '-':
      case '+=':
      case '-=':
        return 2;
      case '*':
      case '/':
      case '*=':
      case '/=':
        return 3;
      case '^':
        return 4;
      case '%':
        return 5;
      case 'u': // Unary minus
        return 6;
      default:
        return 0;
    }
  }

  bool get isParen => '()'.contains(literal);
}

bool isKeyword(String literal) {
  return [
    'if',
    'elseif',
    'else',
    'let',
    'const',
    'function',
    'struct',
    'return',
    'continue',
    'break',
    'while',
    'in',
  ].contains(literal.toLowerCase());
}

bool isOperator(String literal) {
  return [
    '+',
    '-',
    '*',
    '/',
    '^',
    '%',
    '..',
    '=',
    '<',
    '<=',
    '==',
    '>=',
    '>',
    '!=',
    '+=',
    '-=',
    '*=',
    '/=',
    '^=',
    '%=',
    '++',
    '--',
  ].contains(literal);
}

bool isPunctuation(String literal) {
  return [
    '(',
    ')',
    '{',
    '}',
    '[',
    ']',
    ';',
    ',',
    '\n',
  ].contains(literal);
}

bool isLiteral(String literal) {
  if (RegExp("(^'.*'\$)|(^\".*\"\$)").hasMatch(literal)) {
    // String
    return true;
  } else if (literal.runes.every(
      (element) => '1234567890.'.contains(String.fromCharCode(element)))) {
    // Number
    return true;
  } else if ([
    'true',
    'false',
  ].contains(literal)) {
    // Boolean
    return true;
  }
  return false;
}

dynamic parseLiteral(String literal) {
  if (literal == 'true') {
    return true;
  } else if (literal == 'false') {
    return false;
  } else {
    int tryInt = int.tryParse(literal);
    double tryDouble = double.tryParse(literal);
    if (tryInt != null) {
      return tryInt;
    } else if (tryDouble != null) {
      return tryDouble;
    } else {
      return literal;
    }
  }
}

bool isValidIdent(String literal) {
  return RegExp('[a-zA-Z0-9_[^ \n\t]]*').hasMatch(literal);
}

bool isWhitespace(String c) {
  return c.isEmpty || RegExp('[ \n\t]').hasMatch(c);
}

Tuple2<Token, int> scan_number(String c, String rest) {
  var good_chars = '1234567890.';
  var buffer = c;

  for (c in rest.split('')) {
    if (good_chars.contains(c) && !isWhitespace(c)) {
      buffer += c;
    } else {
      break;
    }
  }

  if (isLiteral(buffer)) {
    return Tuple2(Token(buffer), buffer.length);
  } else {
    return null;
  }
}

Tuple2<Token, int> scan_string(String c, String rest) {
  if (!'"\''.contains(c)) {
    return null;
  }

  var match = c;
  var buffer = c;
  var inEscape = false;
  var offset = 1;

  for (c in rest.split('')) {
    offset++;
    if (inEscape) {
      buffer += c;
      inEscape = false;
      continue;
    } else {
      if (c == '\\') {
        inEscape = true;
        continue;
      } else if (c == match) {
        buffer += c;
        break;
      } else {
        buffer += c;
      }
    }
  }

  if (!buffer.endsWith(match)) {
    return null;
  } else {
    return Tuple2(Token(buffer), offset);
  }
}

Tuple2<Token, int> scan(String c, String rest) {
  var buffer = c;
  var ty;
  if (isValidIdent(c)) {
    ty = 'i';
  } else if (isOperator(c)) {
    ty = 'o';
  }

  for (var c in rest.split('')) {
    if (isWhitespace(c)) {
      break;
    } else if (ty == 'i') {
      if (isValidIdent(c)) {
        buffer += c;
      } else {
        break;
      }
    } else if (ty == 'o') {
      if (isOperator(c)) {
        buffer += c;
      } else {
        break;
      }
    } else {
      var tok = Token(buffer);
      if (tok.hasTy) {
        break;
      } else {
        buffer += c;
      }
    }
  }

  if (ty == 'o') {
    var tok = Token(buffer);
    if (tok.hasTy) {
      return Tuple2(tok, buffer.length);
    } else {
      throw ('unable to tokenize buffer: ' + buffer);
    }
  } else {
    var tok = Token(buffer);
    if (tok.hasTy) {
      return Tuple2(tok, buffer.length);
    } else {
      return Tuple2(Token.Identifier(buffer), buffer.length);
    }
  }
}

List<Token> lex(String input) {
  List<Token> toks = [];

  var offset = 0;
  var c;
  while (offset < input.length) {
    c = input[offset];
    if (isWhitespace(c)) {
      offset++;
      continue;
    } else if (RegExp('[0-9.]').hasMatch(c)) {
      var res = scan_number(c, input.substring(offset + 1));
      if (res != null) {
        offset += res.item2;
        toks.add(res.item1);
      }
    } else if ("'\"".contains(c)) {
      var res = scan_string(c, input.substring(offset + 1));
      if (res != null) {
        offset += res.item2;
        toks.add(res.item1);
      }
    } else {
      var res = scan(c, input.substring(offset + 1));
      if (res != null) {
        // Check for unary minus
        if (res.item1.literal == '-') {
          if (toks.isEmpty) {
            res.item1.literal = 'u';
          } else if (toks.last.ty == TokenTy.Operator) {
            res.item1.literal = 'u';
          }
        }
        offset += res.item2;
        toks.add(res.item1);
      }
    }
  }

  return toks;
}
