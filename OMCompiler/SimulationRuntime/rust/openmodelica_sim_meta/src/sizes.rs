//! Sizes of resizable arrays (`--resizableArrays`): integer expressions over the
//! Integer size parameters, which `-override` may change after translation.
//!
//! An [`Sz`] is a polynomial with integer coefficients whose variables are
//! [`Atom`]s: a size parameter, or an operation the polynomial cannot express
//! (alignment, division, min/max), kept opaque. Equal sizes compare equal, so
//! the codegen can share one runtime value between them.

use alloc::boxed::Box;
use alloc::vec::Vec;
use core::ops::{Add, Mul, Neg, Sub};

#[derive(Clone, Debug, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum Atom {
    /// The size parameter with this index in [`Resize::params`](crate::Resize::params).
    Param(u32),
    /// Rounded up to a multiple of 8.
    Align8(Box<Sz>),
    /// Integer division, truncating like Modelica's `div`.
    Div(Box<Sz>, Box<Sz>),
    Max(Box<Sz>, Box<Sz>),
    Min(Box<Sz>, Box<Sz>),
}

#[derive(Clone, Debug, PartialEq, Eq, Hash, PartialOrd, Ord, Default)]
pub struct Sz {
    c: i64,
    /// Sorted by monomial; no zero coefficient, no empty monomial.
    terms: Vec<(Vec<Atom>, i64)>,
}

impl Sz {
    pub const fn lit(c: i64) -> Sz {
        Sz { c, terms: Vec::new() }
    }

    pub fn param(i: u32) -> Sz {
        Sz::atom(Atom::Param(i))
    }

    fn atom(a: Atom) -> Sz {
        Sz { c: 0, terms: alloc::vec![(alloc::vec![a], 1)] }
    }

    pub fn as_const(&self) -> Option<i64> {
        self.terms.is_empty().then_some(self.c)
    }

    pub fn is_const(&self) -> bool {
        self.terms.is_empty()
    }

    /// The constant term and the rest.
    pub fn split_const(&self) -> (Sz, i64) {
        (Sz { c: 0, terms: self.terms.clone() }, self.c)
    }

    pub fn align8(self) -> Sz {
        if self.terms.iter().all(|(_, k)| k % 8 == 0) {
            return Sz { c: (self.c + 7).div_euclid(8) * 8, terms: self.terms };
        }
        Sz::atom(Atom::Align8(Box::new(self)))
    }

    pub fn div(self, d: Sz) -> Sz {
        match (self.as_const(), d.as_const()) {
            (Some(a), Some(b)) if b != 0 => Sz::lit(a / b),
            (_, Some(1)) => self,
            _ => Sz::atom(Atom::Div(Box::new(self), Box::new(d))),
        }
    }

    pub fn max(self, o: Sz) -> Sz {
        match (self.as_const(), o.as_const()) {
            (Some(a), Some(b)) => Sz::lit(a.max(b)),
            _ if self == o => self,
            _ => Sz::atom(Atom::Max(Box::new(self), Box::new(o))),
        }
    }

    pub fn min(self, o: Sz) -> Sz {
        match (self.as_const(), o.as_const()) {
            (Some(a), Some(b)) => Sz::lit(a.min(b)),
            _ if self == o => self,
            _ => Sz::atom(Atom::Min(Box::new(self), Box::new(o))),
        }
    }

    /// The value for size parameter values `params`.
    pub fn eval(&self, params: &[i64]) -> i64 {
        let mut v = self.c;
        for (mono, k) in &self.terms {
            v += k * mono.iter().map(|a| a.eval(params)).product::<i64>();
        }
        v
    }

    /// The parameters it depends on, each once.
    pub fn params(&self, out: &mut Vec<u32>) {
        for (mono, _) in &self.terms {
            for a in mono {
                a.params(out);
            }
        }
    }

    fn normalize(mut self) -> Sz {
        self.terms.sort();
        let mut out: Vec<(Vec<Atom>, i64)> = Vec::with_capacity(self.terms.len());
        for (m, k) in self.terms {
            match out.last_mut() {
                Some((lm, lk)) if *lm == m => *lk += k,
                _ => out.push((m, k)),
            }
        }
        out.retain(|(_, k)| *k != 0);
        Sz { c: self.c, terms: out }
    }

    pub fn encode(&self, o: &mut Vec<u8>) {
        o.extend_from_slice(&self.c.to_le_bytes());
        o.extend_from_slice(&(self.terms.len() as u32).to_le_bytes());
        for (mono, k) in &self.terms {
            o.extend_from_slice(&k.to_le_bytes());
            o.extend_from_slice(&(mono.len() as u32).to_le_bytes());
            for a in mono {
                a.encode(o);
            }
        }
    }

    pub fn decode(b: &[u8], p: &mut usize) -> Result<Sz, &'static str> {
        let c = take_i64(b, p)?;
        let n = take_u32(b, p)?;
        let mut terms = Vec::new();
        for _ in 0..n {
            let k = take_i64(b, p)?;
            let m = take_u32(b, p)?;
            let mut mono = Vec::new();
            for _ in 0..m {
                mono.push(Atom::decode(b, p)?);
            }
            terms.push((mono, k));
        }
        Ok(Sz { c, terms })
    }
}

impl Atom {
    fn eval(&self, params: &[i64]) -> i64 {
        match self {
            Atom::Param(i) => params.get(*i as usize).copied().unwrap_or(0),
            Atom::Align8(e) => (e.eval(params) + 7).div_euclid(8) * 8,
            Atom::Div(a, b) => {
                let d = b.eval(params);
                if d == 0 { 0 } else { a.eval(params) / d }
            }
            Atom::Max(a, b) => a.eval(params).max(b.eval(params)),
            Atom::Min(a, b) => a.eval(params).min(b.eval(params)),
        }
    }

    fn params(&self, out: &mut Vec<u32>) {
        match self {
            Atom::Param(i) => {
                if !out.contains(i) {
                    out.push(*i);
                }
            }
            Atom::Align8(e) => e.params(out),
            Atom::Div(a, b) | Atom::Max(a, b) | Atom::Min(a, b) => {
                a.params(out);
                b.params(out);
            }
        }
    }

    fn encode(&self, o: &mut Vec<u8>) {
        match self {
            Atom::Param(i) => {
                o.push(0);
                o.extend_from_slice(&i.to_le_bytes());
            }
            Atom::Align8(e) => {
                o.push(1);
                e.encode(o);
            }
            Atom::Div(a, b) | Atom::Max(a, b) | Atom::Min(a, b) => {
                o.push(match self {
                    Atom::Div(..) => 2,
                    Atom::Max(..) => 3,
                    _ => 4,
                });
                a.encode(o);
                b.encode(o);
            }
        }
    }

    fn decode(b: &[u8], p: &mut usize) -> Result<Atom, &'static str> {
        let tag = *b.get(*p).ok_or("sim_meta: truncated size")?;
        *p += 1;
        Ok(match tag {
            0 => Atom::Param(take_u32(b, p)?),
            1 => Atom::Align8(Box::new(Sz::decode(b, p)?)),
            2..=4 => {
                let x = Box::new(Sz::decode(b, p)?);
                let y = Box::new(Sz::decode(b, p)?);
                match tag {
                    2 => Atom::Div(x, y),
                    3 => Atom::Max(x, y),
                    _ => Atom::Min(x, y),
                }
            }
            _ => return Err("sim_meta: bad size atom"),
        })
    }
}

fn take_i64(b: &[u8], p: &mut usize) -> Result<i64, &'static str> {
    let s = b.get(*p..*p + 8).ok_or("sim_meta: truncated size")?;
    *p += 8;
    Ok(i64::from_le_bytes(s.try_into().unwrap()))
}

fn take_u32(b: &[u8], p: &mut usize) -> Result<u32, &'static str> {
    let s = b.get(*p..*p + 4).ok_or("sim_meta: truncated size")?;
    *p += 4;
    Ok(u32::from_le_bytes(s.try_into().unwrap()))
}

impl From<u32> for Sz {
    fn from(v: u32) -> Sz {
        Sz::lit(v as i64)
    }
}

impl Add for Sz {
    type Output = Sz;
    fn add(mut self, o: Sz) -> Sz {
        self.c += o.c;
        self.terms.extend(o.terms);
        self.normalize()
    }
}

impl Sub for Sz {
    type Output = Sz;
    fn sub(self, o: Sz) -> Sz {
        self + -o
    }
}

impl Neg for Sz {
    type Output = Sz;
    fn neg(mut self) -> Sz {
        self.c = -self.c;
        for (_, k) in &mut self.terms {
            *k = -*k;
        }
        self
    }
}

impl Mul<i64> for Sz {
    type Output = Sz;
    fn mul(mut self, k: i64) -> Sz {
        if k == 0 {
            return Sz::lit(0);
        }
        self.c *= k;
        for (_, t) in &mut self.terms {
            *t *= k;
        }
        self
    }
}

impl Mul for Sz {
    type Output = Sz;
    fn mul(self, o: Sz) -> Sz {
        if let Some(k) = o.as_const() {
            return self * k;
        }
        if let Some(k) = self.as_const() {
            return o * k;
        }
        let mut terms = Vec::new();
        for (m, k) in &self.terms {
            terms.push((m.clone(), k * o.c));
            for (n, j) in &o.terms {
                let mut mn: Vec<Atom> = m.iter().chain(n).cloned().collect();
                mn.sort();
                terms.push((mn, k * j));
            }
        }
        for (n, j) in &o.terms {
            terms.push((n.clone(), self.c * j));
        }
        Sz { c: self.c * o.c, terms }.normalize()
    }
}

/// What [`Layout`](crate::Layout) is built over: `u32` for a concrete model,
/// [`Sz`] while the codegen lays out one with resizable arrays.
pub trait LayoutNum: Clone + Add<Output = Self> {
    fn lit(v: u32) -> Self;
    fn times(self, k: u32) -> Self;
    fn align8(self) -> Self;
    /// `self + k` if `self > 0`, else 0.
    fn plus_if_positive(self, k: u32) -> Self;
}

impl LayoutNum for u32 {
    fn lit(v: u32) -> u32 {
        v
    }
    fn times(self, k: u32) -> u32 {
        self * k
    }
    fn align8(self) -> u32 {
        (self + 7) & !7
    }
    fn plus_if_positive(self, k: u32) -> u32 {
        if self > 0 { self + k } else { 0 }
    }
}

impl LayoutNum for Sz {
    fn lit(v: u32) -> Sz {
        Sz::lit(v as i64)
    }
    fn times(self, k: u32) -> Sz {
        self * k as i64
    }
    fn align8(self) -> Sz {
        Sz::align8(self)
    }
    fn plus_if_positive(self, k: u32) -> Sz {
        match self.as_const() {
            Some(n) => Sz::lit(if n > 0 { n + k as i64 } else { 0 }),
            None => self.clone() + self.min(Sz::lit(1)) * k as i64,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn folds_and_evaluates() {
        let n = Sz::param(0);
        let m = Sz::param(1);
        let e = (n.clone() * 2 + Sz::lit(3)) * 8 + Sz::lit(8);
        assert_eq!(e.clone().align8(), e);
        assert_eq!(e.eval(&[10, 0]), 8 * 23 + 8);
        let p = (n.clone() + Sz::lit(1)) * (m.clone() - Sz::lit(1));
        assert_eq!(p.eval(&[4, 3]), 10);
        assert_eq!(n.clone() - n.clone(), Sz::lit(0));
        let a = (n.clone() * 4 + Sz::lit(4)).align8();
        assert_eq!(a.eval(&[1, 0]), 8);
        assert_eq!(a.eval(&[2, 0]), 16);
        let mut b = Vec::new();
        a.encode(&mut b);
        let mut pos = 0;
        assert_eq!(Sz::decode(&b, &mut pos).unwrap(), a);
        assert_eq!(n.clone().plus_if_positive(2).eval(&[0, 0]), 0);
        assert_eq!(n.plus_if_positive(2).eval(&[5, 0]), 7);
    }
}
