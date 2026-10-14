// Tests for crate::JSONExt (JSON.parse in the Rust port).

use arcstr::{literal, ArcStr};
use crate::JSON::{toString, JSON};
use crate::JSONExt::parse;

fn round_trip(s: &str) -> ArcStr {
    toString(&parse(ArcStr::from(s), literal!("<test>")).unwrap(), false).unwrap()
}

#[test]
fn keeps_key_order_and_kinds() {
    assert_eq!(
        round_trip(r#"{"b": 1, "a": [1.5, -2, true, false, null], "c": {}}"#),
        round_trip(r#"{"b":1,"a":[1.5,-2,true,false,null],"c":{}}"#)
    );
    let v = parse(literal!("[3, 3.0]"), literal!("<test>")).unwrap();
    let JSON::ARRAY { values } = &*v else { panic!("not an array") };
    let at = |i| crate::Vector::get(values.clone(), i).unwrap();
    assert!(matches!(&*at(1), JSON::INTEGER { i: 3 }));
    assert!(matches!(&*at(2), JSON::NUMBER { .. }));
}

#[test]
fn decodes_escapes() {
    let v = parse(literal!(r#""aé\/\n""#), literal!("<test>")).unwrap();
    let JSON::STRING { r#str } = &*v else { panic!("not a string") };
    assert_eq!(r#str.as_str(), "aé/\n");
}

#[test]
fn rejects_trailing_tokens() {
    assert!(parse(literal!("{} {}"), literal!("<test>")).is_err());
}
