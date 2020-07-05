import 'lexer.dart';
import 'package:tuple/tuple.dart';

class Node {
  Node _left;
  Node _right;
  NodeTy ty;
  var self;

  void set left(Node left) => _left = left;
  void set right(Node right) => _right = right;

  Node get left => _left;
  Node get right => _right;

  Node(this.ty);
  Node.withSelf(this.ty, this.self);

  bool operator ==(other) =>
      other is Node &&
      this.left == other.left &&
      this.right == other.right &&
      this.self == other.self;

  @override
  String toString({int indent = 0}) {
    String buffer = '';

    indent += 2;

    if (this.right != null) {
      buffer += this.right.toString(indent: indent);
    }

    buffer += '\n';

    buffer += ' ' * (indent - 2);
    buffer += '${this.ty}';
    if (this.self != null) {
      buffer += ':${this.self}';
    }

    if (this.left != null) buffer += this.left.toString(indent: indent);

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

  While,
  // Children: cond, body

  BooleanCondition,
  // Children: stmt (operation), stmts (null)

  If,
  // Children: stmt (booleancondition), stmts (body, else/elseif)

  Literal,

  Identifier,

  Object,

  Collection,

  Return,
  // Children: stmts, null

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
    output.add(stack.removeLast());
  }

  return output;
}

Node RPNtoNode(List<Token> rpnToks) {
  List<Node> stack = [];

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
        }
        Node lhs = stack.removeLast();
        Node rhs = stack.removeLast();

        node.left = lhs;
        node.right = rhs;

        stack.add(node);
        break;
      default:
        throw 'unexpected ${token.ty}: ${token.literal}';
    }
  }

  if (stack.isEmpty) {
    throw 'stack should not be empty';
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
  root.left = lhsNode;
  root.right = rhsNode;

  return Tuple2(root, cursor);
}

// TODO: Kill self
Tuple2<Node, int> parseMultiAssignment(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseCollection(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseCondition(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseWhile(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseFunctionCall(List<Token> toks, int cursor) {}
// TODO: Kill self again

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
    switch (tok.literal) {
      case '{':
        depth++;
        break;
      case '}':
        depth--;
        break;
      default:
        break;
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
    curLhs.left = newNode;
    curLhs.right = Node(NodeTy.Stmts);
    curLhs = curLhs.right;
  }

  Tuple2<Node, int> res = parseStmt(body);

  root.right = res.item1;
  root.left = lhs;

  return Tuple2(root, cursor + res.item2);
}

Tuple2<Node, int> parseStmt(List<Token> toks) {
  int cursor = 0;
  int buffer = 0;

  Node node = null;

  TokenTy last = null;

  while (cursor < toks.length) {
    Token curTok = toks[cursor];
    switch (curTok.ty) {
      case TokenTy.Punctuation:
        // TODO
        switch (curTok.literal) {
          case '(':
            if (last == TokenTy.Identifier) {
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
          case 'return':
            List<Token> returnExpr = [];
            curTok = toks[++cursor];
            while (curTok.literal != ';' && (++cursor <= toks.length)) {
              returnExpr.add(curTok);
              curTok = toks[cursor];
            }

            Node returnNode = Node(NodeTy.Return);
            Tuple2<Node, int> res = parseStmt(returnExpr);
            returnNode.left = res.item1;
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

Node parse(List<Token> toks) {
  int cursor = 0;
  Node root = Node(NodeTy.Stmts);
  Node curNode = root;

  while (cursor < toks.length) {
    bool requiresSemicolon = true;
    int depth = 0;
    List<Token> passToks = [];

    while (cursor < toks.length) {
      Token tok = toks[cursor];

      if (tok.literal == ';' && requiresSemicolon) {
        break;
      } else if (tok.literal == '{') {
        requiresSemicolon = false;
        depth++;
      } else if (tok.literal == '}') {
        depth--;
      }

      passToks.add(tok);

      if (!requiresSemicolon && depth == 0) {
        break;
      }

      cursor++;
    }

    Tuple2<Node, int> res = parseStmt(passToks);
    // Skip the ;
    cursor += 1;
    curNode.left = res.item1;
    curNode.right = Node(NodeTy.Stmts);
    curNode = curNode.right;
  }

  return root;
}
