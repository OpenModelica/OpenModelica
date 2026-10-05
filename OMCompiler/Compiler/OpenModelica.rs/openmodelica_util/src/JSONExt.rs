// Manually written
//! `JSON.parse` and `JSON.parseFile` for the Rust port (Parsers/JSON.rust.mo):
//! serde_json drives a visitor that builds the MetaModelica values directly.
#![allow(non_snake_case)]

use std::fmt;
use std::sync::Arc;

use arcstr::ArcStr;
use metamodelica::{Ref, Result};
use serde::de::{self, DeserializeSeed, Deserializer, MapAccess, SeqAccess, Visitor};

use crate::JSON::JSON;
use crate::{Error, System, UnorderedMap, Vector};

pub(crate) fn parseFile(fileName: ArcStr) -> Result<Ref<JSON>> {
    parse(System::readFile(fileName.clone())?, fileName)
}

pub(crate) fn parse(content: ArcStr, fileName: ArcStr) -> Result<Ref<JSON>> {
    let mut de = serde_json::Deserializer::from_str(&content);
    match Value.deserialize(&mut de).and_then(|v| de.end().map(|()| v)) {
        Ok(v) => Ok(v),
        Err(e) => {
            Error::addCompilerError(ArcStr::from(format!("{fileName}: JSON {e}")))?;
            Err("JSON parse error")
        }
    }
}

struct Value;

impl<'de> DeserializeSeed<'de> for Value {
    type Value = Ref<JSON>;
    fn deserialize<D: Deserializer<'de>>(self, d: D) -> std::result::Result<Ref<JSON>, D::Error> {
        d.deserialize_any(self)
    }
}

impl<'de> Visitor<'de> for Value {
    type Value = Ref<JSON>;

    fn expecting(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str("a JSON value")
    }

    fn visit_bool<E>(self, b: bool) -> std::result::Result<Ref<JSON>, E> {
        Ok(Ref::new(if b { JSON::TRUE } else { JSON::FALSE }))
    }

    fn visit_i64<E: de::Error>(self, i: i64) -> std::result::Result<Ref<JSON>, E> {
        let i = i32::try_from(i).map_err(|_| E::custom(format!("integer {i} out of range")))?;
        Ok(Ref::new(JSON::INTEGER { i }))
    }

    fn visit_u64<E: de::Error>(self, i: u64) -> std::result::Result<Ref<JSON>, E> {
        let i = i32::try_from(i).map_err(|_| E::custom(format!("integer {i} out of range")))?;
        Ok(Ref::new(JSON::INTEGER { i }))
    }

    fn visit_f64<E>(self, r: f64) -> std::result::Result<Ref<JSON>, E> {
        Ok(Ref::new(JSON::NUMBER { r: r.into() }))
    }

    fn visit_str<E>(self, s: &str) -> std::result::Result<Ref<JSON>, E> {
        Ok(Ref::new(JSON::STRING { r#str: ArcStr::from(s) }))
    }

    fn visit_unit<E>(self) -> std::result::Result<Ref<JSON>, E> {
        Ok(Ref::new(JSON::NULL))
    }

    fn visit_seq<A: SeqAccess<'de>>(self, mut seq: A) -> std::result::Result<Ref<JSON>, A::Error> {
        let values = Vector::new(seq.size_hint().unwrap_or(0) as i32);
        while let Some(v) = seq.next_element_seed(Value)? {
            Vector::push(values.clone(), v);
        }
        Ok(Ref::new(JSON::ARRAY { values }))
    }

    fn visit_map<A: MapAccess<'de>>(self, mut map: A) -> std::result::Result<Ref<JSON>, A::Error> {
        let values = UnorderedMap::new(
            Arc::new(|k: ArcStr| Ok(metamodelica::stringHashDjb2(k))),
            Arc::new(|a: ArcStr, b: ArcStr| Ok(a == b)),
            1,
        );
        while let Some(k) = map.next_key_seed(Key)? {
            let v = map.next_value_seed(Value)?;
            UnorderedMap::add(k, v, values.clone()).map_err(de::Error::custom)?;
        }
        Ok(Ref::new(JSON::OBJECT { values }))
    }
}

struct Key;

impl<'de> DeserializeSeed<'de> for Key {
    type Value = ArcStr;
    fn deserialize<D: Deserializer<'de>>(self, d: D) -> std::result::Result<ArcStr, D::Error> {
        d.deserialize_str(self)
    }
}

impl<'de> Visitor<'de> for Key {
    type Value = ArcStr;

    fn expecting(&self, f: &mut fmt::Formatter) -> fmt::Result {
        f.write_str("an object key")
    }

    fn visit_str<E>(self, s: &str) -> std::result::Result<ArcStr, E> {
        Ok(ArcStr::from(s))
    }
}
