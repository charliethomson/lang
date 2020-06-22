use regex::Regex;
use std::convert::TryFrom;

pub const NUMBER_REGEX_STR: &str = r"[-.0-9]+";
pub const BOOLEAN_REGEX_STR: &str = r"(true)|(false)";
pub const STRING_REGEX_STR: &str = r#"(".*")|('.*')"#;
pub const IDENT_REGEX_STR: &str = r"^\$[_a-zA-Z0-9]+";
pub type TokenStream = Vec<Token>;

#[derive(Clone, Debug, PartialEq)]
pub enum Token {
    Operator(Operator),
    Literal(Literal),
    Keyword(Keyword),
    Identifier(String),
    Punctuation(Punctuation),
}
impl ToString for Token {
    fn to_string(&self) -> String {
        match self {
            Self::Operator(r) => r.to_string(),
            Self::Literal(l) => l.to_string(),
            Self::Keyword(d) => d.to_string(),
            Self::Identifier(g) => g.to_string(),
            Self::Punctuation(n) => n.to_string(),
        }
    }
}
impl TryFrom<&String> for Token {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        if let Ok(op) = Operator::try_from(s) {
            Ok(Self::Operator(op))
        } else if let Ok(lit) = Literal::try_from(s) {
            Ok(Self::Literal(lit))
        } else if let Ok(kw) = Keyword::try_from(s) {
            Ok(Self::Keyword(kw))
        } else if let Ok(punc) = Punctuation::try_from(s) {
            Ok(Self::Punctuation(punc))
        } else {
            Err(())
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum Operator {
    Add,
    Sub,
    Mul,
    Div,
    Pow,
    Mod,
    Range,
    Assign,
    Less,
    LessEquals,
    Equals,
    GreaterEquals,
    Greater,
    NotEquals,
}
impl ToString for Operator {
    fn to_string(&self) -> String {
        match self {
            Self::Add => "+".to_owned(),
            Self::Sub => "-".to_owned(),
            Self::Mul => "*".to_owned(),
            Self::Div => "/".to_owned(),
            Self::Pow => "^".to_owned(),
            Self::Mod => "%".to_owned(),
            Self::Range => "..".to_owned(),
            Self::Assign => "=".to_owned(),
            Self::Less => "<".to_owned(),
            Self::LessEquals => "<=".to_owned(),
            Self::Equals => "==".to_owned(),
            Self::GreaterEquals => ">=".to_owned(),
            Self::Greater => ">".to_owned(),
            Self::NotEquals => "!=".to_owned(),
        }
    }
}
impl TryFrom<&String> for Operator {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        match s.as_str() {
            "+" => Ok(Self::Add),
            "-" => Ok(Self::Sub),
            "*" => Ok(Self::Mul),
            "/" => Ok(Self::Div),
            "^" => Ok(Self::Pow),
            "%" => Ok(Self::Mod),
            ".." => Ok(Self::Range),
            "=" => Ok(Self::Assign),
            "<" => Ok(Self::Less),
            "<=" => Ok(Self::LessEquals),
            "==" => Ok(Self::Equals),
            ">=" => Ok(Self::GreaterEquals),
            ">" => Ok(Self::Greater),
            "!=" => Ok(Self::NotEquals),
            _ => Err(()),
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct Literal {
    pub(crate) ty: LiteralType,
    pub(crate) literal: String,
}
impl ToString for Literal {
    fn to_string(&self) -> String {
        format!("{}", self.literal)
    }
}
impl TryFrom<&String> for Literal {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        match LiteralType::try_from(s) {
            Ok(ty) => Ok(Self {
                ty,
                literal: s.clone(),
            }),
            Err(_) => Err(()),
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum LiteralType {
    Number,
    String,
    Boolean,
}
impl ToString for LiteralType {
    fn to_string(&self) -> String {
        match self {
            Self::Number => "Number".to_owned(),
            Self::String => "String".to_owned(),
            Self::Boolean => "Boolean".to_owned(),
        }
    }
}
impl TryFrom<&String> for LiteralType {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        if Regex::new(NUMBER_REGEX_STR).unwrap().is_match(&s) {
            Ok(Self::Number)
        } else if Regex::new(BOOLEAN_REGEX_STR).unwrap().is_match(&s) {
            Ok(Self::Boolean)
        } else if Regex::new(STRING_REGEX_STR).unwrap().is_match(&s) {
            Ok(Self::String)
        } else {
            Err(())
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum Keyword {
    If,
    Elseif,
    Else,
    For,
    Let,
    Const,
    Function,
    Struct,
    Return,
    Continue,
    Break,
    While,
}
impl ToString for Keyword {
    fn to_string(&self) -> String {
        match self {
            Self::If => "If".to_owned(),
            Self::Elseif => "Elseif".to_owned(),
            Self::Else => "Else".to_owned(),
            Self::For => "For".to_owned(),
            Self::Let => "Let".to_owned(),
            Self::Const => "Const".to_owned(),
            Self::Function => "Function".to_owned(),
            Self::Struct => "Struct".to_owned(),
            Self::Return => "Return".to_owned(),
            Self::Continue => "Continue".to_owned(),
            Self::Break => "Break".to_owned(),
            Self::While => "While".to_owned(),
        }
    }
}
impl TryFrom<&String> for Keyword {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        match s.to_lowercase().as_str() {
            "if" => Ok(Self::If),
            "elseif" => Ok(Self::Elseif),
            "else" => Ok(Self::Else),
            "for" => Ok(Self::For),
            "let" => Ok(Self::Let),
            "const" => Ok(Self::Const),
            "function" => Ok(Self::Function),
            "struct" => Ok(Self::Struct),
            "return" => Ok(Self::Return),
            "continue" => Ok(Self::Continue),
            "break" => Ok(Self::Break),
            "while" => Ok(Self::While),
            _ => Err(()),
        }
    }
}
#[derive(Clone, Debug, PartialEq)]
pub enum Punctuation {
    LeftParen,
    RightParen,
    LeftCurly,
    RightCurly,
    LeftSquare,
    RightSquare,
    Semicolon,
    Comma,
    EOL,
}
impl ToString for Punctuation {
    fn to_string(&self) -> String {
        match self {
            Self::LeftParen => "(".to_owned(),
            Self::RightParen => ")".to_owned(),
            Self::LeftCurly => "{".to_owned(),
            Self::RightCurly => "}".to_owned(),
            Self::LeftSquare => "[".to_owned(),
            Self::RightSquare => "]".to_owned(),
            Self::Semicolon => ";".to_owned(),
            Self::Comma => ",".to_owned(),
            Self::EOL => "\n".to_owned(),
        }
    }
}
impl TryFrom<&String> for Punctuation {
    type Error = ();
    fn try_from(s: &String) -> Result<Self, Self::Error> {
        match s.as_str() {
            "(" => Ok(Self::LeftParen),
            ")" => Ok(Self::RightParen),
            "{" => Ok(Self::LeftCurly),
            "}" => Ok(Self::RightCurly),
            "[" => Ok(Self::LeftSquare),
            "]" => Ok(Self::RightSquare),
            ";" => Ok(Self::Semicolon),
            "," => Ok(Self::Comma),
            "\n" => Ok(Self::EOL),
            _ => Err(()),
        }
    }
}
