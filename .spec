
:SYNTAX:
    <TokenStream>?:
        <LParen Expr RParen>?
        Optional tokens
    <<>?TokenStream<>>?*:
        Expr*
        any 0+ tokens


Identifier:
    [a-zA-Z_][a-zA-Z_0-9]

Assignment:
      let Identifier = Expr;
    | let Identifier;

Expr:
      FunctionDecl 
    | LParen Expr RParen
    | Expr Operator Expr
    | Expr BinaryOperator
    | BinaryOperator Expr
    | Literal
    | Identifier
    | return Expr
    | Expr;

FunctionDecl:
    Identifier LParen Identifier,* RParen LCurly Expr* RCurly

Operator:
      +
    | -
    | /
    | *
    | ^
    | &
    | +=
    | -=
    | /=
    | *=
    | %=

CmpOperator:
      ==
    | <
    | <=
    | >
    | >=
    | !=
    | &
    | \|
    | ^


BinaryOperator:
      ++ 
    | --
    | !
    | -


IfStmt:
    if Condition LCurly Expr* RCurly

~ CHOPPING_BLOCK
While:
      while Condition LCurly Expr* RCurly
    | while <LParen Assignment RParen>? : <LParen Condition RParen>? : <LParen Expr RParen>? LCurly Expr* RCurly
    | while <LParen let Identifier RParen>? : <LParen Identifier TODO_CONTAINS_KEYWORD Collection>? RParen LCurly Expr* RCurly

Condition:
      Expr CmpOperator Expr
    | LParen Condition RParen

Literal:
    Integer:
        [0-9]
    Float:
        [0-9.]
    String:
        " chars " | ' chars '
        chars:
            any n characters
    Collection:
          lbound start .. stop <: step>? rbound
            lbound:
                ( | [
                inclusive | exclusive
            rbound:
                ) | ]
                inclusive | exclusive
            start:
                Integer
            stop:
                Integer
            step:
                Integer
        | LSquare Integer,* RSquare