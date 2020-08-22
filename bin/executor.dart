import 'package:quiver/iterables.dart';

import 'parser.dart';
import 'lexer.dart';
import 'dart:io';

Context globalCtx = Context();
Context curCtx = globalCtx;
List<Context> stack = [globalCtx];

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
  curCtx.variables['a'] = 10;
  print(curCtx.tryGet(Node.withSelf(NodeTy.Identifier, 'a')));
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
  if (node.right().ty == NodeTy.FunctionDecl) {
    curCtx.parse_and_push_function(node);
  } else {
    switch (node.ty) {
      case NodeTy.Operation:
      case NodeTy.Assignment:
        var value = executeNode(node.right());
        curCtx.push_variable(node.left().self, value);
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
}

void executeFunction(Node node) {
  List<dynamic> args = [];
  String ident = node.left().self;
  Node cur = node.right();
  while (cur.right().ty != NodeTy.Null) {
    args.add(executeNode(cur.left()));
    cur = cur.right();
  }

  var function = curCtx.functions[ident];
  if (function == null) {
    var global = globalCtx.functions[ident];
    if (global == null) {
      throw "Unrecognized function $ident";
    } else {
      global.execute(args);
    }
  }
  function.execute(args);
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
  if (!curCtx.varUsed(assn.left().self.toString())) {
    curCtx.parse_and_push_variable(assn);
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
    // case NodeTy.FunctionDecl:
    //   curCtx.parse_and_push_function(node);
    //   return Node(NodeTy.Null);
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
      // print(curCtx.tryGet(node.self));
      return curCtx.tryGet(node.self);
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
    var res = executeNode(cur.left());
    res != null ? print(res) : null;
    cur = cur.right();
  }
}

class Context {
  Map<String, dynamic> variables;
  Map<String, Function> functions;

  Context() {
    variables = new Map();
    functions = {
      'print': Function([],
          (List<dynamic> args, {String sep = ', '}) => print(args.join(sep))),
    };
  }

  Context.withGlobal() {
    this.variables = new Map();
    this.functions = new Map();
    globalCtx.functions.forEach((key, value) => this.functions[key] = value);
    globalCtx.variables.forEach((key, value) => this.variables[key] = value);
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

  void push_function(String fnIdent, Function fn) {
    functions[fnIdent] = fn;
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

  void parse_and_push_function(Node tree) {
    String ident = tree.left().self;
    functions[ident] = Function.fromNode(tree);
  }

  void parse_and_push_variable(Node tree) {}
}

void startInterpreter() {
  String line = "";
  while (true) {
    stdout.write(">> ");
    line = stdin.readLineSync();
    executeTree(parse(lex(line)));
  }
}

class Function {
  List<String> args;
  dynamic body;

  Function(this.args, this.body);

  Function.fromNode(Node root) {
    this.body = root.right().right();
    this.args = [];
    Node curArg = root.right().left();
    while (curArg.left().ty != NodeTy.Null) {
      this.args.add(curArg.left().self);
      curArg = curArg.right();
    }
  }

  dynamic execute(List<dynamic> args) {
    if (this.body.runtimeType == Node) {
      stack.add(curCtx);
      curCtx = Context.withGlobal();
      zip([args, this.args]).forEach((element) {
        // Initialize the current stack frame
        var input = element[0];
        var ident = element[1];
        curCtx.push_variable(ident, input);
      });
      executeNode(this.body);
      curCtx = stack.removeLast();
    } else {
      // Assume its a closure / builtin
      this.body(args);
    }
  }
}
