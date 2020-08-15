import 'parser.dart';
import 'lexer.dart';

// TODO: Make less bad
Node replaceSelfInChildren(Node node, dynamic from, dynamic to) {
  if (node.self == from) {
    node.self = to;
  }

  node.left().ty != NodeTy.Null
      ? node.set_left(replaceSelfInChildren(node.left(), from, to))
      : null;
  node.right().ty != NodeTy.Null
      ? node.set_right(replaceSelfInChildren(node.right(), from, to))
      : null;

  return node;
}

String stripQuotes(dynamic s) {
  assert(s.runtimeType == String);
  return s.toString().replaceAll('"', '').replaceAll("'", '');
}

void main() {
  ctx.variables['a'] = 10;
  print(ctx.tryGet(Node.withSelf(NodeTy.Identifier, 'a')));
}

var OPERATIONS = {
  '+ String String': (a, b) => '"${stripQuotes(a) + stripQuotes(b)}"',
  '+ double double': (a, b) => a + b,
  '+ int int': (a, b) => a + b,
  '+ bool bool': (a, b) => {a ? true : b ? true : false},
  '* double double': (a, b) => a * b,
  '* int int': (a, b) => a * b,
  '* String int': (a, b) => a * b,
  '/ double double': (a, b) => a / b,
  '/ int int': (a, b) => a / b,
  '< int int': (a, b) => a < b,
  // TODO
};

// TODO: This whole thing
// also some of parser
// im mentally drained rn :)

Context ctx = new Context();

// int || String || bool
dynamic executeOperation(Node node) {
  dynamic left = executeNode(node.left());
  dynamic right = executeNode(node.right());

  if (node.isAssignment) {
    executeAssignment(node);
  } else {
    var operation =
        OPERATIONS['${node.self} ${left.runtimeType} ${right.runtimeType}'];

    if (operation == null) {
      throw "No implementation found for ${left.runtimeType} ${node.self} ${right.runtimeType}";
    } else {
      return operation(left, right);
    }
  }
}

String executeAssignment(Node node) {
  switch (node.ty) {
    case NodeTy.Operation:
    case NodeTy.Assignment:
      var value = executeNode(node.right());
      ctx.push_variable(node.left().self, value);
      // print("${node.left().self} = $value;");
      return "${node.left().self} = $value;";
    case NodeTy.MultiAssignment:
      // print(
      // "${executeAssignment(node.left())}\n${executeAssignment(node.right())}");
      return "${executeAssignment(node.left())}\n${executeAssignment(node.right())}";
    default:
      return null;
  }
}

void executeFunction(Node node) {
  List<dynamic> args = [];
  String ident = node.left().self;
  Node cur = node.right();
  while (cur.right().ty != NodeTy.Null) {
    args.add(executeNode(cur.left()));
    cur = cur.right();
  }

  var function = ctx.functions[ident];
  if (function.runtimeType == Node) {
    Node cur = function;
    while (cur.right().ty != NodeTy.Null) {
      if (cur.ty == NodeTy.Identifier) {}
    }
  } else {
    function(args);
  }
}

dynamic executeWhile(Node node) {
  Node condition = node.left();
  while (executeNode(condition)) {
    executeTree(node.right());
  }
}

bool executeComplexCondition(node) {
  Node assn = node.left();
  Node cond = node.right().left();
  Node onEach = node.right().right();
  if (!ctx.varUsed(assn.left().self.toString())) {
    ctx.parse_and_push_variable(assn);
  }

  if (!executeNode(cond)) {
    return false;
  } else {
    executeNode(onEach);
    return true;
  }

  ;
}

dynamic executeIf(Node node) {}

dynamic executeNode(Node node) {
  switch (node.ty) {
    case NodeTy.Stmts:
      return executeNode(node.left());

    case NodeTy.Operation:
      return executeOperation(node);
    case NodeTy.FunctionCall:
      return executeFunction(node);
    case NodeTy.FunctionDecl:
      ctx.parse_and_push_function(node);
      return Node(NodeTy.Null);
    case NodeTy.Assignment:
    case NodeTy.MultiAssignment:
      return executeAssignment(node);
    case NodeTy.While:
      return executeWhile(node);
    case NodeTy.ComplexWhileCondition:
      return executeComplexCondition(node);
    case NodeTy.BooleanCondition:
      // on BooleanCondition, self is the node for the condition
      return executeNode(node.self);
    case NodeTy.If:
      return executeIf(node);
    case NodeTy.Literal:
      return node.self;
    case NodeTy.Identifier:
      // print(ctx.tryGet(node.self));
      return ctx.tryGet(node.self);
//TODO:    case NodeTy.Collection:
    case NodeTy.Return:
    default:
      return Node(NodeTy.Null);
  }
}

void executeTree(Node tree) {
  Node cur = tree;
  while (cur != null && cur.ty != NodeTy.Null) {
    // print("cur: ${cur.ty.toString()}:${cur.self}");
    executeNode(cur.left());
    cur = cur.right();
  }
}

class Context {
  Map<String, dynamic> variables;
  Map<String, dynamic> functions;

  Context() {
    variables = new Map();
    functions = {
      'print': (List<dynamic> args, {String sep = ''}) => print(args.join(sep)),
    };
  }

  void push_variable(String varName, var value) {
    var clean_value;
    if (value == null) {
      clean_value = null;
    } else if (value.runtimeType == Node) {
      if (value.ty == NodeTy.Null) {
        clean_value = null;
      } else {
        clean_value = executeNode(value);
      }
    } else {
      clean_value = value;
    }
    variables[varName] = clean_value;
  }

  void push_function(String fnIdent, Node tree) {
    functions[fnIdent] = tree;
  }

  Type varType(String varName) {
    var value = variables[varName];
    return value != null ? value.runtimeType : null;
  }

  bool varUsed(String varName) {
    return variables[varName] != null;
  }

  dynamic tryGet(dynamic key) {
    var tryVar = variables[key];
    var tryFunc = functions[key];
    return tryVar != null ? tryVar : tryFunc != null ? tryFunc : null;
  }

  void parse_and_push_function(Node tree) {}
  void parse_and_push_variable(Node tree) {}
}

class Interpreter {
  Node tree;
  Node curNode;
  Context ctx;

  Interpreter() {}
}
