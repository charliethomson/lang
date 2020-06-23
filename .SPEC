
Identifier:
    Any string of characters matching /^[_a-zA-Z0-9]+/
    ex:
        _apple
        banana
        yes
        a1
        s1s2
    !ex:
        1q
        !wqe
        ;aa
        $asad
        12313$aa

Literal:
    Number: 
        Any string matching /.[0-9]+/
        ex:
            1
            1.2
            2.5
            52.100
        !ex:
            a1
            0x10
            0b00100010
    String:
        Any string matching /(" | ').*(" | ')/
        ex:
            "Hello World!"
            "banana"
            'lemon'
            "cool beans guy"
            "let a = 10;"
            ''
        !ex:
            "Hello world!'
            lmao hey
    Boolean:
        reserved keywords
        list:
            true
            false
        

Operators:
    list:
        *: mul
        +: add
        -: sub
        /: div
        ^: pow
        %: modulo
        <literal>..<literal>: range

Keywords:
    reserved, may not be used for identifiers, may be used in strings
    list: 
        if, elseif, else:
            if (<condition>) {
                ..
            } elseif (<condition>) {
                ..
            } else {

            }
        for:
            for (i in <range>) { .. }
            for (let i = 0; <condition> ; <modifier>) { .. }
        while:
            while (cond) { .. }
            while (<dyn ToBool> expr) { .. }
        let, const:
            let makes a variable mutable, const immutable
            let <identifier> = <literal> | <expr> ;
            let <identifier>* = < <literal> | <expr> >*;
            const <identifier> = <literal> | <expr>;
            const <identifier>* = < <literal> | <expr> >*;
        function:
            let <identifier> = function(<args>*) { .. }
        struct:
            let <identifier> = struct { <identifier> : <type>, .. }
            instantiation:
                let <identifier> = <identifier (struct ident)> { <identifier>: <literal of correct (or elidable) type>, .. }
        return:
            return <identifier> | <expr>;
            return < <identifier> | <expr> >*;
        continue:
            continues an iteration
        break:
            breaks an iteration

Builtins:
    Builtin functions you can use (or override by redefining (if you're crazy, what i mean is they're not reserved))
    list:
        print:
            prints the arguments (formatted with the rust formatter (maybe, TODO))
        input:
            returns a string from stdin