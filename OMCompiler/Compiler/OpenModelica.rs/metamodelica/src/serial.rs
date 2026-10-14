//! Binary encoding of MetaModelica values, derived with `#[derive(MMSerial)]`.
//! Strings are written once per encoder and referenced by index after that.

use crate::{List, Real, Ref, SourceInfo};
use arcstr::ArcStr;
use std::collections::HashMap;

pub struct Encoder {
    pub buf: Vec<u8>,
    strings: HashMap<ArcStr, u32>,
}

pub struct Decoder<'a> {
    buf: &'a [u8],
    pos: usize,
    strings: Vec<ArcStr>,
}

pub trait MMSerial: Sized {
    fn mm_encode(&self, e: &mut Encoder);
    fn mm_decode(d: &mut Decoder) -> Self;
}

impl Encoder {
    pub fn new() -> Self {
        Encoder { buf: Vec::new(), strings: HashMap::new() }
    }

    #[inline]
    pub fn varint(&mut self, mut v: u64) {
        while v >= 0x80 {
            self.buf.push(v as u8 | 0x80);
            v >>= 7;
        }
        self.buf.push(v as u8);
    }
}

impl Default for Encoder {
    fn default() -> Self {
        Self::new()
    }
}

impl<'a> Decoder<'a> {
    pub fn new(buf: &'a [u8]) -> Self {
        Decoder { buf, pos: 0, strings: Vec::new() }
    }

    #[inline]
    pub fn varint(&mut self) -> u64 {
        let mut v = 0u64;
        let mut shift = 0;
        loop {
            let b = self.buf[self.pos];
            self.pos += 1;
            v |= ((b & 0x7f) as u64) << shift;
            if b < 0x80 {
                return v;
            }
            shift += 7;
        }
    }

    fn bytes(&mut self, n: usize) -> &'a [u8] {
        let s = &self.buf[self.pos..self.pos + n];
        self.pos += n;
        s
    }
}

impl MMSerial for bool {
    fn mm_encode(&self, e: &mut Encoder) { e.buf.push(*self as u8) }
    fn mm_decode(d: &mut Decoder) -> Self { d.bytes(1)[0] != 0 }
}

impl MMSerial for i32 {
    fn mm_encode(&self, e: &mut Encoder) { e.varint(((*self << 1) ^ (*self >> 31)) as u32 as u64) }
    fn mm_decode(d: &mut Decoder) -> Self {
        let v = d.varint() as u32;
        ((v >> 1) as i32) ^ -((v & 1) as i32)
    }
}

impl MMSerial for f64 {
    fn mm_encode(&self, e: &mut Encoder) { e.buf.extend_from_slice(&self.to_le_bytes()) }
    fn mm_decode(d: &mut Decoder) -> Self { f64::from_le_bytes(d.bytes(8).try_into().unwrap()) }
}

impl MMSerial for Real {
    fn mm_encode(&self, e: &mut Encoder) { self.0.mm_encode(e) }
    fn mm_decode(d: &mut Decoder) -> Self { Real::from(f64::mm_decode(d)) }
}

impl MMSerial for ArcStr {
    fn mm_encode(&self, e: &mut Encoder) {
        let next = e.strings.len() as u32;
        match e.strings.get(self) {
            Some(&i) => e.varint(i as u64 + 1),
            None => {
                e.strings.insert(self.clone(), next);
                e.varint(0);
                e.varint(self.len() as u64);
                e.buf.extend_from_slice(self.as_bytes());
            }
        }
    }
    fn mm_decode(d: &mut Decoder) -> Self {
        match d.varint() {
            0 => {
                let n = d.varint() as usize;
                let s: ArcStr = std::str::from_utf8(d.bytes(n)).unwrap().into();
                d.strings.push(s.clone());
                s
            }
            i => d.strings[i as usize - 1].clone(),
        }
    }
}

impl<T: MMSerial> MMSerial for Option<T> {
    fn mm_encode(&self, e: &mut Encoder) {
        match self {
            None => e.buf.push(0),
            Some(v) => {
                e.buf.push(1);
                v.mm_encode(e);
            }
        }
    }
    fn mm_decode(d: &mut Decoder) -> Self {
        if d.bytes(1)[0] == 0 { None } else { Some(T::mm_decode(d)) }
    }
}

impl<T: MMSerial> MMSerial for Ref<T> {
    fn mm_encode(&self, e: &mut Encoder) { (**self).mm_encode(e) }
    fn mm_decode(d: &mut Decoder) -> Self { Ref::new(T::mm_decode(d)) }
}

impl<T: MMSerial + Clone> MMSerial for List<T> {
    fn mm_encode(&self, e: &mut Encoder) {
        let items: Vec<&T> = self.iter().collect();
        e.varint(items.len() as u64);
        for v in items.into_iter().rev() {
            v.mm_encode(e);
        }
    }
    fn mm_decode(d: &mut Decoder) -> Self {
        let n = d.varint();
        let mut l = crate::nil();
        for _ in 0..n {
            l = crate::cons(T::mm_decode(d), l);
        }
        l
    }
}

impl<A: MMSerial, B: MMSerial> MMSerial for (A, B) {
    fn mm_encode(&self, e: &mut Encoder) {
        self.0.mm_encode(e);
        self.1.mm_encode(e);
    }
    fn mm_decode(d: &mut Decoder) -> Self {
        let a = A::mm_decode(d);
        (a, B::mm_decode(d))
    }
}

impl MMSerial for SourceInfo {
    fn mm_encode(&self, e: &mut Encoder) {
        self.fileName.mm_encode(e);
        self.isReadOnly.mm_encode(e);
        self.lineNumberStart.mm_encode(e);
        self.columnNumberStart.mm_encode(e);
        self.lineNumberEnd.mm_encode(e);
        self.columnNumberEnd.mm_encode(e);
        self.lastModification.mm_encode(e);
    }
    fn mm_decode(d: &mut Decoder) -> Self {
        SourceInfo {
            fileName: MMSerial::mm_decode(d),
            isReadOnly: MMSerial::mm_decode(d),
            lineNumberStart: MMSerial::mm_decode(d),
            columnNumberStart: MMSerial::mm_decode(d),
            lineNumberEnd: MMSerial::mm_decode(d),
            columnNumberEnd: MMSerial::mm_decode(d),
            lastModification: MMSerial::mm_decode(d),
        }
    }
}

pub use metamodelica_derive::MMSerial;
