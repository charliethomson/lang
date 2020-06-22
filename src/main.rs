pub mod execute;
pub mod lex;
pub mod parse;

fn main() {
    println!(
        "{:#?}",
        lex::lex(
            r#"
let xyz, y, z;

while true {
    x, y = 0, 1;
    while z < 255 {
        print(z);
        z = x + y;
        x = y;
        y = z;
    }
}"#
            .to_owned(),
        )
    )
}
