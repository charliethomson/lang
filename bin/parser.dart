import 'lexer.dart';

class Node {
  Node _left;
  Node _right;
  NodeTy ty;
  dynamic self;

  void set left(Node left) => _left = left;
  void set right(Node right) => _right = right;

  Node get left => _left;
  Node get right => _right;

  Node(this.ty);
  Node.withSelf(this.ty, this.self);
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

  Ident,

  Literal,

  Obj,

  Null,

  Return,
  // Children: stmts, null

}

class RangeCollection {
  int start;
  int stop;
  int step;

  RangeCollection(this.start, this.stop, this.step);
}

class ElemCollection {
  List<Token> els;

  ElemCollection(this.els);
}

Node parse(List<Token> toks) {
  Node root = Node(NodeTy.Stmts);
  Node cur = root;

  return root;
}
