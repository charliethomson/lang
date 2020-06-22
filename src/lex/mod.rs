pub mod types;
use std::{convert::TryFrom, str::Chars};
use types::{
    Keyword, Literal, LiteralType, Operator, Punctuation, Token, TokenStream, IDENT_REGEX_STR,
};

fn is_valid_ident_char(c: char) -> bool {
    match c {
        'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => true,
        _ => false,
    }
}

fn scan_number(c: char, chars: Chars<'_>) -> Option<(Token, usize)> {
    let mut chars = chars;
    let mut buffer = c.to_string();

    let good_chars = "1234567890.";
    while let Some(c) = chars.next() {
        if good_chars.contains(c) && !c.is_whitespace() {
            buffer.push(c);
        } else {
            break;
        }
    }

    match Token::try_from(&buffer) {
        Ok(tok) => Some((tok, buffer.len().checked_sub(2).unwrap_or(0))),
        Err(_) => None,
    }
}

fn scan_string(c: char, chars: Chars<'_>) -> Option<(Token, usize)> {
    let mut chars = chars;
    let mut buffer = c.to_string();

    while let Some(c) = chars.next() {
        buffer.push(c);
        if c == '\'' || c == '"' {
            break;
        }
    }

    match Token::try_from(&buffer) {
        Ok(tok) => Some((tok, buffer.len().checked_sub(2).unwrap_or(0))),
        Err(_) => None,
    }
}

fn scan_ident(chars: Chars<'_>) -> Option<(Token, usize)> {
    let mut chars = chars;
    let mut buffer = String::new();

    while let Some(c) = chars.next() {
        if let Ok(tok) = Token::try_from(&buffer) {
            return Some((tok, buffer.len() - 1));
        } else if is_valid_ident_char(c) {
            buffer.push(c);
        } else {
            break;
        }
    }

    Some((Token::Identifier(buffer.clone()), buffer.len() - 1))
}

fn scan(c: char, chars: Chars<'_>) -> Result<(Token, usize), String> {
    let mut chars = chars;
    let mut buffer = c.to_string();

    while let Some(c) = chars.next() {
        if c.is_whitespace() {
            if let Ok(tok) = Token::try_from(&buffer) {
                return Ok((tok, buffer.len() - 2));
            } else if let Some(m) = regex::Regex::new(IDENT_REGEX_STR).unwrap().find(&buffer) {
                return Ok((Token::Identifier(m.as_str().to_owned()), buffer.len() - 2));
            } else {
                println!("hit whitespace");
                return Err(buffer);
            }
        } else if let Ok(tok) = Token::try_from(&buffer) {
            return Ok((tok, buffer.len() - 2));
        } else if let Some(m) = regex::Regex::new(IDENT_REGEX_STR).unwrap().find(&buffer) {
            return Ok((Token::Identifier(m.as_str().to_owned()), buffer.len() - 2));
        } else {
            buffer.push(c);
        }
    }
    if let Ok(tok) = Token::try_from(&buffer) {
        Ok((tok, buffer.len() - 2))
    } else {
        println!("failed");
        Err(buffer)
    }
}

pub fn lex(input: String) -> TokenStream {
    let mut chars = input.chars();
    let mut tokens: TokenStream = Vec::new();

    let mut c: char;
    loop {
        c = match chars.next() {
            Some(c) => c,
            None => break,
        };

        if c.is_whitespace() {
            continue;
        } else if c.is_numeric() {
            if let Some((tok, amt)) = scan_number(c, chars.clone()) {
                // Slightly weird behaviour, `nth` consumes `amt` elements of the iterator and yeilds the `amt`'th one.
                // So this is equivalent to chars.skip(amt), but it doesn't consume the iterator and return a Skip
                // :shrug: lol
                chars.nth(amt);
                tokens.push(tok);
            } else {
            }
        } else if let Ok(tok) = Token::try_from(&c.to_string()) {
            tokens.push(tok);
        } else if c == '"' || c == '\'' {
            if let Some((tok, amt)) = scan_string(c, chars.clone()) {
                if amt != 0 {
                    chars.nth(amt);
                }
                tokens.push(tok);
            } else {
            }
        } else if c == '$' {
            if let Some((tok, amt)) = scan_ident(chars.clone()) {
                chars.nth(amt);
                tokens.push(tok);
            } else {
            }
        } else {
            match scan(c, chars.clone()) {
                Ok((tok, amt)) => {
                    chars.nth(amt);
                    tokens.push(tok);
                }
                Err(buffer) => {
                    eprintln!("{:?}", tokens);
                    panic!("Unable to tokenize buffer: {:?}", buffer);
                }
            }
        }
    }

    tokens
}

#[cfg(test)]
pub mod tests {
    use super::*;
    #[test]
    fn test_scan_string() {
        let test_str = "'Hello World!'aaaaaa".to_owned();
        let mut chars = test_str.chars();
        let c = chars.next().unwrap();
        let res = scan_string(c, chars.clone()).unwrap();
        assert_eq!(
            res.0,
            Token::Literal(Literal {
                ty: LiteralType::String,
                literal: "'Hello World!'".to_owned()
            })
        );
        chars.nth(res.1);
        assert_eq!(chars.collect::<String>(), "aaaaaa".to_owned(),)
    }
    #[test]
    fn test_scan_number() {
        let test_str = "1.1211231233aaaaaaa";
        let mut chars = test_str.chars();
        let c = chars.next().unwrap();
        let res = scan_number(c, chars.clone()).unwrap();
        assert_eq!(
            res.0,
            Token::Literal(Literal {
                ty: LiteralType::Number,
                literal: "1.1211231233".to_owned(),
            })
        );
        chars.nth(res.1);
        assert_eq!(chars.collect::<String>(), "aaaaaaa".to_owned(),)
    }
    #[test]
    fn test_scan() {
        let test_str = "let";
        let mut chars = test_str.chars();
        let c = chars.next().unwrap();
        let res = scan(c, chars.clone()).unwrap();
        assert_eq!(res.0, Token::Keyword(Keyword::Let),);
        chars.nth(res.1);
        let test_str = "return a;";
        let mut chars = test_str.chars();
        let c = chars.next().unwrap();
        let res = scan(c, chars.clone()).unwrap();
        assert_eq!(res.0, Token::Keyword(Keyword::Return),);
        chars.nth(res.1);
        let test_str = "for";
        let mut chars = test_str.chars();
        let c = chars.next().unwrap();
        let res = scan(c, chars.clone()).unwrap();
        assert_eq!(res.0, Token::Keyword(Keyword::For),);
        chars.nth(res.1);
    }
    #[test]
    fn test_lex() {
        let expected = vec![
            Token::Keyword(Keyword::Let),
            Token::Identifier("x".to_owned()),
            Token::Operator(Operator::Assign),
            Token::Literal(Literal {
                ty: LiteralType::Number,
                literal: "10".to_owned(),
            }),
            Token::Punctuation(Punctuation::Semicolon),
            Token::Keyword(Keyword::Let),
            Token::Identifier("y".to_owned()),
            Token::Operator(Operator::Assign),
            Token::Literal(Literal {
                ty: LiteralType::Number,
                literal: "11".to_owned(),
            }),
            Token::Punctuation(Punctuation::Semicolon),
            Token::Keyword(Keyword::Let),
            Token::Identifier("z".to_owned()),
            Token::Operator(Operator::Assign),
            Token::Identifier("x".to_owned()),
            Token::Operator(Operator::Add),
            Token::Identifier("y".to_owned()),
            Token::Punctuation(Punctuation::Semicolon),
            Token::Identifier("print".to_owned()),
            Token::Punctuation(Punctuation::LeftParen),
            Token::Identifier("z".to_owned()),
            Token::Punctuation(Punctuation::RightParen),
            Token::Punctuation(Punctuation::Semicolon),
        ];

        let result = lex(r#"
            let $x = 10;
            let $y = 11;
            let $z = $x + $y;
            $print($z);
            "#
        .to_owned());

        assert_eq!(expected, result);
    }
}
