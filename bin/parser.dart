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

  String formatString(int indent) {
    String buffer = '';
    if (this.left != null)
      buffer += 'lhs: ${this.left.formatString(indent + 4)}';
    if (this.right != null)
      buffer += 'rhs: ${this.right.formatString(indent + 4)}';
    if (indent != 0) {
      buffer += ' ' * indent;
    }
    buffer += '${this.ty} -> ${this.ty}\n';

    return buffer;
  }

  void addRLChild(Node child) {
    this.right = Node(NodeTy.Stmts);
    this.right.left = child;
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

Tuple2<Node, int> parseOperation(List<Token> toks, int cursor) {
  Node root = Node(NodeTy.Operation);
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

  Token lhsTok = opToks[0];
  NodeTy nodeTy = toNodeTy(lhsTok.ty);
  if (![NodeTy.Literal, NodeTy.Identifier]
      .contains(nodeTy != null ? nodeTy : NodeTy.If)) {
    throw 'Unparsable lhs: ${lhsTok.literal}';
  }
  Node lhs = Node.withSelf(nodeTy, lhsTok.literal);

  Token rhsTok = opToks[2];
  nodeTy = toNodeTy(rhsTok.ty);
  if (![NodeTy.Literal, NodeTy.Identifier]
      .contains(nodeTy != null ? nodeTy : NodeTy.If)) {
    throw 'Unparsable rhs: ${rhsTok.literal}';
  }
  Node rhs = Node.withSelf(nodeTy, rhsTok.literal);

  Token opTok = opToks[1];
  nodeTy = toNodeTy(opTok.ty);
  if (nodeTy != NodeTy.Operation) {
    throw 'Unknown operator ${opTok.literal}';
  }

  root.self = opTok.literal;
  root.left = lhs;
  root.right = rhs;

  return Tuple2(root, cursor);
}

Tuple2<Node, int> parseAssignment(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseMultiAssignment(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseCollection(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseCondition(List<Token> toks, int cursor) {}
Tuple2<Node, int> parseWhile(List<Token> toks, int cursor) {}
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
    tok = toks[++cursor];
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

  Tuple2<Node, int> res = parse(body);

  root.right = res.item1;
  root.left = lhs;

  return Tuple2(root, cursor + res.item2);
}

Tuple2<Node, int> parseFunctionCall(List<Token> toks, int cursor) {}

Tuple2<Node, int> parse(List<Token> toks) {
  int cursor = 0;
  bool halt = false;
  Node root = Node(NodeTy.Stmts);
  Node curNode = root;

  int buffer = 0;

  TokenTy last = TokenTy.Identifier;

  while (cursor < toks.length && !halt) {
    Token curTok = toks[cursor];
    switch (curTok.ty) {
      case TokenTy.Punctuation:
        // TODO
        if (last == TokenTy.Punctuation) {
          throw 'Syntax error: Unexpected "${curTok.literal}"';
        }

        switch (curTok.literal) {
          case '(':
          case ')':
          case '{':
          case '}':
          case '[':
          case ']':
          case ';':
          case ',':
            break;
        }

        break;
      case TokenTy.Identifier:
        if (last == TokenTy.Identifier) {
          throw 'Syntax error: Unexpected identifier "${curTok.literal}"';
        }
        buffer++;

        break;
      case TokenTy.Operator:
        if (last == TokenTy.Operator) {
          throw 'Syntax error: Unexpected operator "${curTok.literal}"';
        }
        buffer++;

        Tuple2<Node, int> res = parseOperation(toks, cursor - buffer);
        cursor += res.item2;
        curNode.left = res.item1;
        curNode.right = Node(NodeTy.Stmts);
        curNode = curNode.right;

        break;
      case TokenTy.Literal:
        if (last == TokenTy.Literal) {
          throw 'Syntax error: Unexpected literal "${curTok.literal}"';
        }
        buffer++;
        break;
      case TokenTy.Keyword:
        switch (curTok.literal) {
          // TODO: Impl the rest of the kws
          case 'let':
            Tuple2<Node, int> res = parseAssignment(toks, cursor);
            cursor += res.item2;
            // Set the left child to the result
            curNode.left = res.item1;
            // Set and move to the new right child.
            curNode.right = Node(NodeTy.Stmts);
            curNode = curNode.right;
            break;
          case 'while':
            Tuple2<Node, int> res = parseWhile(toks, cursor);
            cursor += res.item2;
            // Set the left child to the result
            curNode.left = res.item1;
            // Set and move to the new right child.
            curNode.right = Node(NodeTy.Stmts);
            curNode = curNode.right;
            break;
          case 'function':
            // Parse the function declaration
            Tuple2<Node, int> res = parseFunctionDecl(toks, cursor);
            cursor += res.item2;
            // Set the left child to the result
            curNode.left = res.item1;
            // Set and move to the new right child.
            curNode.right = Node(NodeTy.Stmts);
            curNode = curNode.right;

            break;
          case 'return':
            // TODO
            // This is probably a bug, please look
            List<Token> returnExpr = [];
            curTok = toks[++cursor];
            while (curTok.literal != ';' && !(cursor < toks.length - 1)) {
              returnExpr.add(curTok);
              curTok = toks[++cursor];
            }

            Node returnNode = Node(NodeTy.Return);
            Tuple2<Node, int> res = parse(returnExpr);
            returnNode.left = res.item1;
            cursor += res.item2;
            curNode.left = returnNode;
            curNode.right = Node(NodeTy.Stmts);
            curNode = curNode.right;

            break;
        }
    }

    last = curTok.ty;
    cursor++;
  }

  return Tuple2(root, cursor);
}
