import 'package:quiver/iterables.dart';

import 'lexer.dart';
import 'package:tuple/tuple.dart';

class Node {
  Node _left;
  Node _right;
  NodeTy ty;
  var self;

  bool get isAssignment =>
      [NodeTy.Assignment, NodeTy.MultiAssignment].contains(ty) ||
      '=,+=,-=,/=,*='.split(',').contains(self);

  void set_left(Node left) {
    if (ty == NodeTy.Null) {
      ty = NodeTy.Stmts;
    }
    _left = left;
  }

  void set_right(Node right) {
    if (ty == NodeTy.Null) {
      ty = NodeTy.Stmts;
    }
    _right = right;
  }

  Node left() {
    if (_left == null) {
      return Node(NodeTy.Null);
    }
    return _left;
  }

  Node right() {
    if (_right == null) {
      return Node(NodeTy.Null);
    }
    return _right;
  }

  Node(this.ty);
  Node.withSelf(this.ty, this.self);

  bool operator ==(other) =>
      other is Node &&
      this._left == other._left &&
      this._right == other._right &&
      this.self == other.self;

  @override
  String toString({int indent = 0}) {
    String buffer = '';

    indent += 2;

    if (this._right != null) {
      buffer += this._right.toString(indent: indent);
    }

    buffer += '\n';

    buffer += ' ' * (indent - 2);
    buffer += '${nodeTyToString(this.ty)}';
    if (this.self != null) {
      if (this.self.runtimeType == Node) {
        String childString = this.self.toString(indent: indent);
        buffer += " " * indent + childString;
      } else {
        buffer += ':${this.self}';
      }
    }

    if (this._left != null) buffer += this._left.toString(indent: indent);

    return buffer;
  }
}

enum NodeTy {
  // stmt: Node

  Stmts,
  // Children: stmt, stmts

  Operation,
  // Children: lhs, rhs; self set.

  FunctionCall,
  // Children: ident, stmts

  FunctionDecl,
  // Children: ident, stmts (args, body)

  Assignment,
  // Children: lhs, rhs

  MultiAssignment,
  // Children: Assignment, MultiAssignment

  While,
  // Children: cond, body

  ComplexWhileCondition,
  // while (Assignment; BooleanCondition; onEach)
  // Children: Assignment, Stmts: BooleanCondition, Stmts (onEach)

  BooleanCondition,

  If,
  // Children: stmts: (cond, body), if|null

  Literal,

  Identifier,

  Object,

  Collection,

  Return,
  // Children: stmts, null

  Null,
}

NodeTy toNodeTy(TokenTy ty) {
  switch (ty) {
    case TokenTy.Identifier:
      return NodeTy.Identifier;
    case TokenTy.Operator:
      return NodeTy.Operation;
    case TokenTy.Literal:
      return NodeTy.Literal;
    case TokenTy.Punctuation:
    case TokenTy.Keyword:
      return null;
  }
  return null;
}

String nodeTyToString(NodeTy ty) {
  switch (ty) {
    case NodeTy.Stmts:
      return 'Stmts';
    case NodeTy.Operation:
      return 'Operation';
    case NodeTy.FunctionCall:
      return 'FunctionCall';
    case NodeTy.FunctionDecl:
      return 'FunctionDecl';
    case NodeTy.Assignment:
      return 'Assignment';
    case NodeTy.While:
      return 'While';
    case NodeTy.BooleanCondition:
      return 'BooleanCondition';
    case NodeTy.If:
      return 'If';
    case NodeTy.Literal:
      return 'Literal';
    case NodeTy.Identifier:
      return 'Identifier';
    case NodeTy.Object:
      return 'Object';
    case NodeTy.Collection:
      return 'Collection';
    case NodeTy.Return:
      return 'Return';
    case NodeTy.MultiAssignment:
      return 'MultiAssignment';
    case NodeTy.ComplexWhileCondition:
      return 'ComplexWhileCondition';
    case NodeTy.Null:
      return 'Null';
  }
}

List<Token> toRPN(List<Token> toks) {
  List<Token> output = [];
  List<Token> stack = [];

  for (Token token in toks) {
    switch (token.ty) {
      case TokenTy.Literal:
      case TokenTy.Identifier:
        output.add(token);
        break;
      case TokenTy.Operator:
        int p = token.precedence();

        while (stack.isNotEmpty) {
          // List.last _can_ throw, but the above condition asserts that it never will
          Token top = stack.last;

          if (top.isParen) {
            break;
          } else {
            bool cond = token.isRightAssociative
                ? top.precedence() <= p
                : top.precedence() < p;

            if (cond) {
              break;
            } else {
              output.add(stack.removeLast());
            }
          }
        }

        stack.add(token);

        break;
      default:
        if (token.isParen) {
          switch (token.literal) {
            case '(':
              stack.add(token);
              break;
            case ')':
              while (stack.isNotEmpty) {
                Token top = stack.removeLast();
                if (top.literal == '(') {
                  break;
                } else {
                  output.add(top);
                }
              }
              break;
            default:
          }
        } else {
          throw 'unexpected ${token.ty}: ${token.literal}';
        }
    }
  }

  while (stack.isNotEmpty) {
    var toAdd = stack.removeLast();
    if (toAdd.isParen) {
      throw 'mismatched paren';
    }
    output.add(toAdd);
  }

  return output;
}

Node RPNtoNode(List<Token> rpnToks) {
  List<Node> stack = [];
  bool unaryFlag = false;

  for (Token token in rpnToks) {
    switch (token.ty) {
      case TokenTy.Literal:
      case TokenTy.Identifier:
        stack.add(Node.withSelf(toNodeTy(token.ty), token.literal));
        break;
      case TokenTy.Operator:
        Node node = Node.withSelf(NodeTy.Operation, token.literal);
        if (stack.isEmpty) {
          throw 'stack shouldnt be empty';
        } else if (token.isUnaryOperation) {
          // a ++ b, a u b
          // gets cleared if a - u b -> the unary operator is followed (rpn) by a binary operator
          if (stack.length.isEven) {
            unaryFlag = true;
          }
          Node rhs = stack.removeLast();
          node.set_right(rhs);
          node.set_left(Node(NodeTy.Null));
        } else {
          if (unaryFlag) unaryFlag = false;

          Node rhs = stack.removeLast();
          Node lhs = stack.removeLast();

          node.set_left(lhs);
          node.set_right(rhs);
        }

        stack.add(node);
        break;
      default:
        throw 'unexpected ${token.ty}: ${token.literal}';
    }
  }

  if (stack.isEmpty) {
    throw 'stack should not be empty';
  } else if (unaryFlag) {
    throw 'Syntax error: Attempt to use unary operator as binary operator';
  } else {
    return stack.removeLast();
  }
}

Tuple2<Node, int> parseOperation(List<Token> toks, int cursor) {
  List<Token> opToks = [];
  Token tok = toks[cursor];

  while (tok.isValidOperatorTy) {
    opToks.add(tok);
    if (cursor < toks.length - 1) {
      tok = toks[++cursor];
    } else {
      break;
    }
  }

  List<Token> rpnToks = toRPN(opToks);
  Node root = RPNtoNode(rpnToks);

  return Tuple2(root, cursor);
}

Tuple2<Node, int> parseAssignment(List<Token> toks, int cursor) {
  // let foo = 10;
  // called when `cursor` on "let"
  Token tok = toks[cursor];
  if (tok.literal != 'let') {
    throw 'Entered unreachable code in parseAssignment (e.c 8) (${tok.literal})';
  }

  if (toks
      .skip(cursor)
      .takeWhile((value) => value.literal != '=')
      .map((e) => e.literal)
      .contains(',')) {
    return parseMultiAssignment(toks, cursor);
  }

  Token lhs = toks[++cursor];
  Node lhsNode = Node.withSelf(toNodeTy(lhs.ty), lhs.literal);

  // Skip the =
  cursor++;

  bool requiresSemicolon = true;
  int depth = 0;
  List<Token> rhs = [];

  while (++cursor < toks.length) {
    Token tok = toks[cursor];

    if (tok.literal == ';' && requiresSemicolon) {
      break;
    } else if (tok.literal == '{') {
      requiresSemicolon = false;
      depth++;
    } else if (tok.literal == '}') {
      depth--;
    }

    rhs.add(tok);

    if (!requiresSemicolon && depth == 0) {
      break;
    }
  }

  Tuple2 res = parseStmt(rhs);
  Node rhsNode = res.item1;
  cursor += res.item2;

  Node root = Node(NodeTy.Assignment);
  root.set_left(lhsNode);
  root.set_right(rhsNode);

  return Tuple2(root, cursor);
}

Tuple2<Node, int> parseMultiAssignment(List<Token> toks, int cursor) {
  // let a, b, c = 10, 11, 12;
  // called when `cursor` on "let"

  List<List<Token>> lhs = [];
  List<List<Token>> rhs = [];

  List<Token> cur = [];

  bool inRhs = false;
  while (++cursor < toks.length) {
    Token tok = toks[cursor];

    if (tok.literal == '=') {
      if (inRhs) {
        // throw
      }
      lhs.add(cur);
      cur = [];
      inRhs = true;
    } else if (tok.literal == ',') {
      if (inRhs) {
        rhs.add(cur);
      } else {
        lhs.add(cur);
      }

      cur = [];
    } else if (tok.literal == ';') {
      if (inRhs) {
        rhs.add(cur);
      } else {
        lhs.add(cur);
      }
      break;
    } else {
      cur.add(tok);
    }
  }

  // Require that lhs and rhs are equal lengths. fill missing rhs values with `null`. Throw if lhs < rhs

  if (lhs.length != rhs.length) {
    if (lhs.length < rhs.length) {
      // throw
    } else {
      while (lhs.length > rhs.length) {
        rhs.add([null]);
      }
    }
  }

  List<Node> lhsNodes = lhs.map((toks) => parseStmt(toks).item1).toList();
  List<Node> rhsNodes = rhs.map((toks) => parseStmt(toks).item1).toList();

  Node root = Node(NodeTy.MultiAssignment);
  Node current = root;
  Node parent = root;

  for (var tuple in zip([lhsNodes, rhsNodes])) {
    var lhs = tuple[0];
    var rhs = tuple[1];

    Node assn = Node(NodeTy.Assignment);
    assn.set_left(lhs);
    assn.set_right(rhs);

    current.set_left(assn);
    current.set_right(Node(NodeTy.MultiAssignment));
    parent = current;
    current = current.right();
  }

  parent.set_right(null);

  return Tuple2(root, cursor);
}

// TODO: collections
Tuple2<Node, int> parseCollection(List<Token> toks, int cursor) {}

Tuple2<Node, int> parseCondition(List<Token> toks, int cursor) {
  // if (a == b) { .. } else if ( a == c) { .. } else { .. }
  /*
        null
      if
          stmts:body
        stmts
          null
      stmts:body
    if
      stmts     ident:a
        operation:==
                ident:c
  if  stmts:body
    stmts     ident:a
      operation:==
              ident:b
  */
  // called when `cursor` on "if"
  if (cursor >= toks.length || !toks[cursor].isConditionMarker) {
    return null;
  }

  List<Token> condition = [];
  List<Token> body = [];

  // Skip to the first ( or {
  while (!'({'.contains(toks[++cursor].literal.toString()));

  bool inCond = toks[cursor].literal == '(';
  int depth = 0;

  while (cursor < toks.length) {
    Token tok = toks[cursor];
    bool skip = true;
    switch (tok.literal) {
      case '(':
        if (depth == 0) {
          inCond = true;
        } else {
          skip = false;
        }
        break;
      case ')':
        if (depth == 0) {
          inCond = false;
        } else {
          skip = false;
        }
        break;
      case '{':
        depth++;
        break;
      case '}':
        depth--;
        break;
      default:
        skip = false;
    }
    if (skip) {
      cursor++;
      continue;
    }

    if (depth != 0 && inCond) {
      throw 'Syntax Error: Possibly missing a closing paren on the condition there bud';
    } else if (depth != 0) {
      body.add(tok);
    } else if (inCond) {
      condition.add(tok);
    } else {
      break;
    }
    cursor++;
  }

  Node root = Node(NodeTy.If);
  Node child = Node(NodeTy.Stmts);
  child.set_left(condition.isNotEmpty
      ? parseOperation(condition, 0).item1
      : Node(NodeTy.Null));
  child.set_right(body.isNotEmpty ? parse(body) : Node(NodeTy.Null));

  root.set_left(child);
  var res = parseCondition(toks, cursor);
  if (res != null) {
    root.set_right(res.item1);
    cursor += res.item2;
  } else {
    root.set_right(Node(NodeTy.Null));
  }

  return Tuple2(root, cursor);
}

// TODO: Reformat
Tuple2<Node, int> parseWhile(List<Token> toks, int cursor) {
  // while (let i = 0; i < 10; i++) { <body?> }
  // OR
  // while (condition) { <body?> }
  // called when `cursor` on "while"

  if (cursor >= toks.length || toks[cursor].literal != "while") {
    throw "unreachable (e.c 8, parseWhile)";
  }

  var parts = toks
      .skip(cursor)
      .skipWhile((value) => value.literal != '(')
      .skip(1)
      .takeWhile((value) => value.literal != ')')
      .toList();

  Node ret = Node(NodeTy.While);

  if (parts.any((element) => element.literal == ';')) {
    // CASE 1
    // while (<assignment?>;<condition?>;<onEach?>) { <body?> }
    var assignment = parts.takeWhile((value) => value.literal != ';').toList();
    cursor += assignment.length + 1;

    var condition =
        parts.skip(cursor).takeWhile((value) => value.literal != ';').toList();
    cursor += condition.length + 1;

    var onEach =
        parts.skip(cursor).takeWhile((value) => value.literal != ';').toList();
    cursor += onEach.length + 1;

    var assignmentResult = parseStmt(assignment);
    var conditionResult = parseStmt(condition);
    var onEachResult = parseStmt(onEach);

    if ([assignmentResult, conditionResult, onEachResult]
        .any((element) => element == null || element.item1 == null)) {
      Node left = Node(NodeTy.ComplexWhileCondition);
      left.set_left(assignmentResult != null && assignmentResult.item1 != null
          ? assignmentResult.item1
          : Node(NodeTy.Null));

      Node right = Node(NodeTy.Null);
      right.set_left(Node.withSelf(
          NodeTy.BooleanCondition,
          conditionResult != null && conditionResult.item1 != null
              ? conditionResult.item1
              : Node(NodeTy.Null)));
      right.set_right(onEachResult != null && onEachResult.item1 != null
          ? onEachResult.item1
          : Node(NodeTy.Null));
      ;
      left.set_right(right);

      ret.set_left(left);
      ret.set_right(null);
    } else {
      Node left = Node(NodeTy.ComplexWhileCondition);
      left.set_left(assignmentResult.item1);

      Node right = Node(NodeTy.Stmts);
      right.set_left(
          Node.withSelf(NodeTy.BooleanCondition, conditionResult.item1));
      right.set_right(onEachResult.item1);

      left.set_right(right);

      ret.set_left(left);
      ret.set_right(null);
    }
  } else {
    // CASE 2
    // while(<cond>) {<body?>}

    var condResult = parseStmt(parts);
    Node cond = condResult != null || condResult.item1 != null
        ? condResult.item1
        : Node(NodeTy.Null);

    ret.set_left(Node.withSelf(NodeTy.BooleanCondition, cond));
  }

  // Body

  List<Token> body = [];
  int depth = 0;
  for (var tok
      in toks.skip(cursor).skipWhile((value) => value.literal != '{')) {
    if (tok.literal == '{') {
      depth++;
    } else if (tok.literal == '}') {
      depth--;
    }
    body.add(tok);

    if (depth == 0) {
      break;
    }
  }

  cursor += body.length;
  if (body.isNotEmpty) {
    body = body.getRange(1, body.length - 1).toList();
    Node bodyResult = parse(body);

    ret.set_right(bodyResult);
  } else {
    ret.set_right(Node(NodeTy.Null));
  }

  return Tuple2(ret, cursor);
}

Tuple2<Node, int> parseFunctionCall(List<Token> toks, int cursor) {
  // print("Hello World!");
  // called when `cursor` on "print"

  Token tok = toks[cursor];

  if (tok.ty != TokenTy.Identifier) {
    throw "Entered unreachable code in parseFunctionCall (e.c 5) (${tok.literal})";
  }
  Node lhs = Node.withSelf(NodeTy.Identifier, tok.literal);

  tok = toks[++cursor];

  if (tok.literal != '(') {
    throw 'Syntax error: encountered ${tok.literal}, expected \'(\'';
  }

  List<List<Token>> args = [];
  List<Token> arg = [];
  int depth = 1;

  while (++cursor < toks.length) {
    tok = toks[cursor];
    if (tok.literal == ')') {
      if (--depth == 0) {
        break;
      } else {
        arg.add(tok);
      }
    } else if (tok.literal == '(') {
      // function call as argument
      arg.add(tok);
      depth++;
    } else if (tok.literal == ',') {
      if (depth == 1) {
        args.add(arg);
        arg = [];
      } else {
        arg.add(tok);
      }
    } else {
      arg.add(tok);
    }
  }

  if (arg.isNotEmpty) {
    args.add(arg);
    arg = [];
  }

  Node rhs = Node(NodeTy.Stmts);
  Node curRhs = rhs;

  for (List<Token> arg in args) {
    Node node = parseStmt(arg).item1;

    curRhs.set_left(node);
    curRhs.set_right(Node(NodeTy.Stmts));
    curRhs = curRhs.right();
  }

  Node root = Node(NodeTy.FunctionCall);
  root.set_left(lhs);
  root.set_right(rhs);

  return Tuple2(root, cursor + 2);
}

Tuple2<Node, int> parseFunctionDecl(List<Token> toks, int cursor) {
  // let foo = function(a, b) { return a + b; }
  // called when `cursor` on "function"

  Token tok = toks[cursor];

  if (tok.literal != 'function') {
    throw 'Entered unreachable code in parseFunctionDecl (e.c 1) (${tok.literal})';
  }

  tok = toks[++cursor];
  if (tok.literal != '(') {
    throw 'Syntax error: encountered ${tok.literal}, expected \'(\'';
  }

  tok = toks[++cursor];
  List<Token> args = [];

  while (tok.literal == ',' || tok.ty == TokenTy.Identifier) {
    if (tok.ty == TokenTy.Identifier) {
      args.add(tok);
    }
    tok = toks[++cursor];
  }

  tok = toks[++cursor];
  if (tok.literal != '{') {
    throw '';
  }

  tok = toks[++cursor];

  List<Token> body = [];

  int depth = 1;
  while (true) {
    if (tok.literal == '{') {
      depth++;
    } else if (tok.literal == '}') {
      depth--;
    }

    if (depth <= 0) break;

    body.add(tok);
    if (++cursor >= toks.length) break;

    tok = toks[cursor];
  }

  Node root = Node(NodeTy.FunctionDecl);
  Node lhs = Node(NodeTy.Stmts);

  Node curLhs = lhs;
  for (Token tok in args) {
    if (!isValidIdent(tok.literal)) {
      throw 'expected identifier, got ${tok.literal} (${tok.ty})';
    }

    Node newNode = Node.withSelf(NodeTy.Identifier, tok.literal);
    curLhs.set_left(newNode);
    curLhs.set_right(Node(NodeTy.Stmts));
    curLhs = curLhs.right();
  }

  Tuple2<Node, int> res = parseStmt(body);

  root.set_right(res.item1);
  root.set_left(lhs);

  return Tuple2(root, cursor + res.item2);
}

Tuple2<Node, int> parseStmt(List<Token> toks) {
  int cursor = 0;
  int buffer = 0;

  Node node = null;

  TokenTy last = null;

  while (cursor < toks.length) {
    Token curTok = toks[cursor];
    if (curTok == null) {
      if (node != null) {
        node.set_left(Node(NodeTy.Null));
        node.set_right(Node(NodeTy.Stmts));
        node = node.right();
      } else {
        node = Node(NodeTy.Null);
      }
      cursor++;
      continue;
    }
    switch (curTok.ty) {
      case TokenTy.Punctuation:
        // TODO
        switch (curTok.literal) {
          case '(':
            if (last == TokenTy.Identifier) {
              return parseFunctionCall(toks, cursor - 1);
              // function call
            }
            break;
          case '[':
            if (last == TokenTy.Identifier) {
              // index
            }
            break;
        }

        break;
      case TokenTy.Identifier:
        if (last == TokenTy.Identifier) {
          throw 'Syntax error: Unexpected identifier "${curTok.literal}"';
        }
        node = Node.withSelf(NodeTy.Identifier, curTok.literal);
        buffer++;

        break;
      case TokenTy.Operator:
        if (last == TokenTy.Operator) {
          throw 'Syntax error: Unexpected operator "${curTok.literal}"';
        } else if (last == TokenTy.Punctuation) {
          buffer--;
        }
        buffer++;

        int offs = cursor - buffer >= 0 ? cursor - buffer : 0;
        return parseOperation(toks, offs);
      case TokenTy.Literal:
        if (last == TokenTy.Literal) {
          throw 'Syntax error: Unexpected literal "${curTok.literal}"';
        }
        buffer++;
        node = Node.withSelf(NodeTy.Literal, curTok.literal);
        break;
      case TokenTy.Keyword:
        switch (curTok.literal) {
          // TODO: Impl the rest of the kws
          case 'let':
            return parseAssignment(toks, cursor);
          case 'while':
            return parseWhile(toks, cursor);
          case 'function':
            return parseFunctionDecl(toks, cursor);
          case 'if':
          case 'elseif':
          case 'else':
            return parseCondition(toks, cursor);
          case 'return':
            List<Token> returnExpr = [];
            curTok = toks[++cursor];
            while (curTok.literal != ';' && (++cursor <= toks.length)) {
              returnExpr.add(curTok);
              curTok = toks[cursor];
            }

            Node returnNode = Node(NodeTy.Return);
            Tuple2<Node, int> res = parseStmt(returnExpr);
            returnNode.set_left(res.item1);
            cursor += res.item2;
            node = returnNode;
            return Tuple2(node, cursor);
        }
    }

    last = curTok.ty;
    cursor++;
  }

  return Tuple2(node, cursor);
}

List<List<Token>> getStmts(List<Token> code) {
  int state = 0;

  List<List<Token>> stmts = [];
  List<Token> stmt = [];

  int depth = 0;
  int cursor = -1;
  Token tok;

  var semicolonsRequired = () => state == 0 && depth == 0;

  while (++cursor < code.length) {
    tok = code[cursor];
    if (['while', 'function'].contains(tok.literal.toString())) {
      state = 1;
    } else if (['if', 'elseif', 'else'].contains(tok.literal.toString())) {
      state = 2;
    }

    if (tok.literal == ';' && semicolonsRequired()) {
      stmt.add(tok);
      stmts.add(stmt);
      stmt = [];
    } else {
      if ('{}'.contains(tok.literal.toString()) &&
          tok.literal.toString().isNotEmpty) {
        depth += tok.literal == '{' ? 1 : -1;
        if (depth == 0) {
          if (state == 2 &&
              cursor + 1 < code.length &&
              !['elseif', 'else']
                  .contains(code[cursor + 1].literal.toString())) {
            // Peek for an else/elseif if we're in a condition stmt
            state = 0;
          }
          stmt.add(tok);
          stmts.add(stmt);
          stmt = [];
          continue;
        }
      } else if (state == 1 && tok.literal.toString() == ')') {
        state = 0;
      }

      stmt.add(tok);
    }
  }

  if (stmt.isNotEmpty) {
    stmts.add(stmt);
  }

  if (state != 0) {
    throw 'Syntax Error: Unexpected EOF';
  }

  return stmts;
}

Node parse(List<Token> toks) {
  Node root = Node(NodeTy.Stmts);
  Node curNode = root;

  List<List<Token>> stmts = getStmts(toks);

  for (List<Token> stmt in stmts) {
    Tuple2<Node, int> res = parseStmt(stmt);
    curNode.set_left(res.item1);
    curNode.set_right(Node(NodeTy.Stmts));
    curNode = curNode.right();
  }

  return root;
}
