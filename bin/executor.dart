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

var OPERATIONS = {
  '+ String String': (a, b) => '"${stripQuotes(a) + stripQuotes(b)}"',
  '+ double double': (a, b) => a + b,
  '+ int int': (a, b) => a + b,
  '- int int': (a, b) => a - b,
  '+ bool bool': (a, b) => {
        a
            ? true
            : b
                ? true
                : false
      },
  '* double double': (a, b) => a * b,
  '* int int': (a, b) => a * b,
  '* String int': (a, b) => a * b,
  '/ double double': (a, b) => a / b,
  '/ int int': (a, b) => a / b,
  '< int int': (a, b) => a < b,
  '== int int': (a, b) => a == b,
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
    return executeAssignment(node);
  } else {
    var operation =
        OPERATIONS['${node.self} ${left.runtimeType} ${right.runtimeType}'];

    if (operation == null) {
      throw "No implementation found for ${left.runtimeType} ${node.self} ${right.runtimeType}";
    } else {
      var res = operation(left, right);
      return res;
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

dynamic executeFunction(Node node) {
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
      return global.execute(args);
    }
  }
  return function.execute(args);
}

void executeWhile(Node node) {
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
}

dynamic executeIf(Node node) {
  // if the if is an else
  if (node.left().left().ty == NodeTy.Null && node.right().ty == NodeTy.Null) {
    return executeNode(node.left().right());
  }
  var result = executeNode(node.left().left());
  // if the condition is true
  if (result.runtimeType == bool && result) {
    return executeNode(node.left().right());
  } else {
    while (result.runtimeType == Node) {
      result = executeNode(result);
    }
    if (result.runtimeType == bool && result) {
      if (result) {
        return executeNode(node.left().right());
      }
    } else {
      var output = executeNode(node.right());
      return output;
    }
  }
}

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
      var val = curCtx.tryGet(node.self);
      if (val != null) {
        return val;
      } else {
        throw "unknown identifier ${node.self}";
      }
      break;
//TODO:    case NodeTy.Collection:
    case NodeTy.Return:
      return executeNode(node.left());
    default:
      return Node(NodeTy.Null);
  }
}

void executeTree(Node tree) {
  Node cur = tree;
  while (cur != null && cur.ty != NodeTy.Null) {
    dynamic res = executeNode(cur.left());
    if (!isNull(res)) {
      print(res);
    }
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
    return tryVar != null
        ? tryVar
        : tryFunc != null
            ? tryFunc
            : null;
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
    try {
      executeTree(parse(lex(line)));
    } catch (e) {
      print(e);
    }
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
      dynamic res = executeNode(this.body);
      curCtx = stack.removeLast();
      return res;
    } else {
      // Assume its a closure / builtin
      return this.body(args);
    }
  }
}

bool isNull(var item) {
  return [
        Node,
      ].contains(item.runtimeType) ||
      item == null;
}

// extension NullableNode on Node {
//   bool isNull() => true;
// }

// extension NullableNode on Node {
//   bool isNull() => true;
// }

// extension NullableNode on Node {
//   bool isNull() => true;
// }
