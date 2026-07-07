// Manually written file.
//
// Pure-Rust reimplementation of `OMCompiler/Compiler/FrontEnd/UnitParserExt.mo`'s
// `external "C"` declarations. The MetaModelica module is only a set of FFI
// shims into the unit parser/scanner runtime
// (`OMCompiler/Compiler/runtime/unitparser.cpp`, `unitparserext.cpp` and
// `UnitParserExt_omc.cpp`), so the auto-generator can only emit `todo!()`
// bodies. We reimplement the parser natively here rather than marshalling
// MetaModelica heap objects through a C ABI.
//
// The parser maintains a database of SI base/derived units and is used by the
// old front-end's unit checking (`FrontEnd/UnitAbsynBuilder.mo`) and by the
// scripting API `convertUnits`/`getDerivedUnits`. The C++ runtime kept a single
// process-global `UnitParser` plus a checkpoint stack; we mirror that per
// thread (`thread_local!`) so unit checking of one compilation stays isolated
// without taking a lock on the parse path. All external calls for a single
// operation run on the same thread, so this preserves the original semantics.
//
// Integer arithmetic uses `i64` to match `mmc_sint_t` on 64-bit targets (the
// scale-factor literals for `deg`, `rev`, `rpm`, `mmHg`, `psi`, `inWG` only fit
// in 64 bits, so we follow the upstream `MMC_SIZE_INT == 8` branch). The unit
// exponent vectors marshalled back to MetaModelica as `list<Integer>` only ever
// hold small values; we narrow them to `i32` there to match the port's
// `Integer` width.

#![allow(non_snake_case)]

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::{ArcStr, literal};
use metamodelica::{List, OrderedFloat, Real, cons, nil};
use openmodelica_util::Error;
use openmodelica_error::ErrorTypes;

/// Signed integer matching the C++ `mmc_sint_t` used throughout the parser.
type Sint = i64;

// ─────────────────────────────────────────────────────────────────────────
// Rational
// ─────────────────────────────────────────────────────────────────────────

/// A rational number kept in (not necessarily reduced) `num/denom` form, with
/// the sign normalised onto the numerator (`fixsign`). Mirrors the C++
/// `Rational` class.
#[derive(Clone, Copy, Debug)]
struct Rational {
    num: Sint,
    denom: Sint,
}

impl Rational {
    fn new(num: Sint, denom: Sint) -> Rational {
        let mut r = Rational { num, denom };
        r.fixsign();
        r
    }

    fn whole(num: Sint) -> Rational {
        Rational::new(num, 1)
    }

    fn is_zero(&self) -> bool {
        self.num == 0
    }

    /// Whether the value equals `num/denom` *without* reducing — the C++
    /// `is()` compares the stored representation, e.g. `(1/1)` is not `(2/2)`.
    fn is(&self, num: Sint, denom: Sint) -> bool {
        self.num == num && self.denom == denom
    }

    fn equal(&self, other: Rational) -> bool {
        self.num == other.num && self.denom == other.denom
    }

    fn to_string(&self) -> String {
        if self.denom == 1 {
            format!("{}", self.num)
        } else {
            format!("({}/{})", self.num, self.denom)
        }
    }

    fn to_real(&self) -> f64 {
        // The C++ prints a diagnostic and still divides on a zero denominator,
        // yielding inf/nan; plain f64 division reproduces that.
        self.num as f64 / self.denom as f64
    }

    fn fixsign(&mut self) {
        if self.denom < 0 {
            self.denom = -self.denom;
            self.num = -self.num;
        }
    }

    fn gcd(mut a: Sint, mut b: Sint) -> Sint {
        while b != 0 {
            let t = b;
            b = a % b;
            a = t;
        }
        a
    }

    fn simplify(q: Rational) -> Rational {
        let g = Rational::gcd(q.num, q.denom);
        let mut q2 = Rational { num: q.num / g, denom: q.denom / g };
        q2.fixsign();
        q2
    }

    fn sub(q1: Rational, q2: Rational) -> Rational {
        Rational::simplify(Rational {
            num: q1.num * q2.denom - q2.num * q1.denom,
            denom: q1.denom * q2.denom,
        })
    }

    fn add(q1: Rational, q2: Rational) -> Rational {
        Rational::simplify(Rational {
            num: q1.num * q2.denom + q2.num * q1.denom,
            denom: q1.denom * q2.denom,
        })
    }

    fn mul(q1: Rational, q2: Rational) -> Rational {
        Rational::simplify(Rational { num: q1.num * q2.num, denom: q1.denom * q2.denom })
    }

    fn div(q1: Rational, q2: Rational) -> Rational {
        Rational::simplify(Rational { num: q1.num * q2.denom, denom: q1.denom * q2.num })
    }

    fn powint(mut base: Sint, mut exp: Sint) -> Sint {
        let mut res: Sint = 1;
        while exp != 0 {
            if exp & 1 != 0 {
                res *= base;
            }
            exp >>= 1;
            base *= base;
        }
        res
    }

    /// `q1` raised to an integer power. The only caller (`Unit::pow`) already
    /// guarantees `q2.denom == 1`.
    fn pow(q1: Rational, q2: Rational) -> Rational {
        debug_assert_eq!(q2.denom, 1, "Rational::pow with non-integer exponent");
        if q2.num < 0 {
            Rational::simplify(Rational {
                num: Rational::powint(q1.denom, -q2.num),
                denom: Rational::powint(q1.num, -q2.num),
            })
        } else {
            Rational::simplify(Rational {
                num: Rational::powint(q1.num, q2.num),
                denom: Rational::powint(q1.denom, q2.num),
            })
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// UnitRes (parse result codes)
// ─────────────────────────────────────────────────────────────────────────

/// Parse error codes, mirroring `UnitRes::ResVal`. `UNIT_OK` is modelled as the
/// `Ok` arm of `Result`, so this enum only enumerates the failure cases. A few
/// codes (`UnknownToken`, `UnknownIdent`, `BaseAlreadyDefined`) are never
/// produced by the parser — they exist in the upstream enum too — but are kept
/// for parity and complete `message()` coverage.
#[allow(dead_code)]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum UnitErr {
    UnknownToken,
    UnknownIdent,
    ParseError,
    OffsetError,
    ExponentNotInt,
    WrongBase,
    NotFound,
    PrefixNotFound,
    InvalidInt,
    PrefixNotAllowed,
    BaseAlreadyDefined,
    ErrorAddingUnit,
    DefinedWithDifferentExpr,
}

impl UnitErr {
    /// The human-readable text used in `Error parsing unit ...` messages,
    /// matching `UnitRes::toString`.
    fn message(self) -> &'static str {
        match self {
            UnitErr::UnknownToken => "Unknown token",
            UnitErr::UnknownIdent => "Unknown ident",
            UnitErr::ParseError => "Parse error",
            UnitErr::OffsetError => "Offset error",
            UnitErr::ExponentNotInt => "Exponent is not an integer",
            UnitErr::WrongBase => "Wrong base",
            UnitErr::NotFound => "Unit not found",
            UnitErr::PrefixNotFound => "Prefix not found",
            UnitErr::InvalidInt => "Invalid integer",
            UnitErr::PrefixNotAllowed => "Prefix not allowed",
            UnitErr::BaseAlreadyDefined => "Base already defined",
            UnitErr::ErrorAddingUnit => "Error adding unit",
            UnitErr::DefinedWithDifferentExpr => "Unknown error",
        }
    }
}

type UnitResult<T> = std::result::Result<T, UnitErr>;

// ─────────────────────────────────────────────────────────────────────────
// Unit
// ─────────────────────────────────────────────────────────────────────────

/// A parsed unit: an exponent vector over the base units, plus prefix/scale/
/// offset rationals and a map of symbolic type parameters. Mirrors `Unit`.
#[derive(Clone, Debug)]
struct Unit {
    /// Exponents over the base-unit vector.
    unit_vec: Vec<Rational>,
    /// Exponent of the SI prefix, e.g. `mm` ⇒ `10^-3 m` ⇒ `prefix_expo = -3`.
    prefix_expo: Rational,
    /// Scalar factor (SI prefix and unit scaling, e.g. feet ⇒ metre).
    scale_factor: Rational,
    /// Additive offset to the base unit (e.g. `degC` ⇒ 273.15).
    offset: Rational,
    /// Symbolic type parameters; the key includes the leading apostrophe.
    type_param_vec: BTreeMap<String, Rational>,
    quantity_name: String,
    unit_name: String,
    unit_symbol: String,
    /// Whether an SI prefix may be applied (false for `kg`).
    prefix_allowed: bool,
    /// Weight used by the (currently unused) pretty-printer.
    weight: f64,
}

impl Default for Unit {
    fn default() -> Unit {
        Unit {
            unit_vec: Vec::new(),
            prefix_expo: Rational::whole(0),
            scale_factor: Rational::whole(1),
            offset: Rational::whole(0),
            type_param_vec: BTreeMap::new(),
            quantity_name: String::new(),
            unit_name: String::new(),
            unit_symbol: String::new(),
            prefix_allowed: true,
            weight: 1.0,
        }
    }
}

impl Unit {
    fn is_dimensionless(&self) -> bool {
        self.unit_vec.iter().all(|r| r.is_zero()) && self.type_param_vec.is_empty()
    }

    /// True for a base unit: exactly one exponent is `1`, the rest are `0`.
    fn is_base_unit(&self) -> bool {
        let mut onefound = false;
        for r in &self.unit_vec {
            if r.denom != 1 {
                return false;
            }
            if r.num == 1 {
                if onefound {
                    return false;
                }
                onefound = true;
            } else if r.num != 0 {
                return false;
            }
        }
        true
    }

    /// Structural equality of two units ignoring `weight` and prefix.
    fn equal_no_weight(&self, other: &Unit) -> bool {
        if self.unit_vec.len() != other.unit_vec.len() {
            return false;
        }
        for (a, b) in self.unit_vec.iter().zip(other.unit_vec.iter()) {
            if !a.equal(*b) {
                return false;
            }
        }
        self.scale_factor.equal(other.scale_factor) && self.offset.equal(other.offset)
    }

    /// Combined multiplication/division of two units (`mulop` selects which).
    fn paramutil(u1: &Unit, u2: &Unit, mulop: bool) -> UnitResult<Unit> {
        if !u1.offset.is_zero() || !u2.offset.is_zero() {
            return Err(UnitErr::OffsetError);
        }
        let mut ur = Unit::default();
        ur.offset = Rational::whole(0);
        ur.prefix_expo = if mulop {
            Rational::add(u1.prefix_expo, u2.prefix_expo)
        } else {
            Rational::sub(u1.prefix_expo, u2.prefix_expo)
        };
        ur.scale_factor = if mulop {
            Rational::mul(u1.scale_factor, u2.scale_factor)
        } else {
            Rational::div(u1.scale_factor, u2.scale_factor)
        };
        ur.unit_vec.clear();
        let n = u1.unit_vec.len().max(u2.unit_vec.len());
        for i in 0..n {
            let q1 = u1.unit_vec.get(i).copied().unwrap_or(Rational::whole(0));
            let q2 = u2.unit_vec.get(i).copied().unwrap_or(Rational::whole(0));
            ur.unit_vec
                .push(if mulop { Rational::add(q1, q2) } else { Rational::sub(q1, q2) });
        }
        // Merge the sorted type-parameter maps. Both BTreeMaps iterate in key
        // order, so we keep the C++ merge that adds matching exponents and (for
        // division) negates exponents present only in the divisor.
        for (k, v2) in &u2.type_param_vec {
            match u1.type_param_vec.get(k) {
                Some(v1) => {
                    let combined =
                        if mulop { Rational::add(*v1, *v2) } else { Rational::sub(*v1, *v2) };
                    ur.type_param_vec.insert(k.clone(), combined);
                }
                None => {
                    let v = if mulop { *v2 } else { Rational::mul(*v2, Rational::whole(-1)) };
                    ur.type_param_vec.insert(k.clone(), v);
                }
            }
        }
        for (k, v1) in &u1.type_param_vec {
            ur.type_param_vec.entry(k.clone()).or_insert(*v1);
        }
        Ok(ur)
    }

    fn div(u1: &Unit, u2: &Unit) -> UnitResult<Unit> {
        Unit::paramutil(u1, u2, false)
    }

    fn mul(u1: &Unit, u2: &Unit) -> UnitResult<Unit> {
        Unit::paramutil(u1, u2, true)
    }

    /// Raise a unit to an integer power.
    fn pow(u: &Unit, e: Rational) -> UnitResult<Unit> {
        if !u.offset.is_zero() {
            return Err(UnitErr::OffsetError);
        }
        if e.denom != 1 {
            return Err(UnitErr::ExponentNotInt);
        }
        let mut ur = u.clone();
        ur.prefix_expo = Rational::mul(u.prefix_expo, e);
        ur.scale_factor = Rational::pow(u.scale_factor, e);
        ur.unit_vec = u.unit_vec.iter().map(|q| Rational::mul(*q, e)).collect();
        for v in ur.type_param_vec.values_mut() {
            *v = Rational::mul(*v, e);
        }
        Ok(ur)
    }
}

/// A base quantity/unit definition.
#[derive(Clone, Debug)]
struct Base {
    unit_symbol: String,
}

/// A pending derived-unit definition, deferred until `commit`.
#[derive(Clone, Debug)]
struct DerivedInfo {
    quantity_name: String,
    unit_name: String,
    unit_symbol: String,
    unit_str_exp: String,
    prefix_expo: Rational,
    scale_factor: Rational,
    offset: Rational,
    prefix_allowed: bool,
    weight: f64,
}

// ─────────────────────────────────────────────────────────────────────────
// Scanner
// ─────────────────────────────────────────────────────────────────────────

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Token {
    Div,
    Lparan,
    Rparan,
    Dot,
    Expo,
    Id,
    Param,
    Int,
    Unknown,
    Eos,
}

/// A scanner over a unit string. Unit strings are ASCII, so byte indexing
/// matches the C++ `std::string` semantics exactly. Mirrors `Scanner`.
struct Scanner {
    str: Vec<u8>,
    index: usize,
}

impl Scanner {
    fn new(s: &str) -> Scanner {
        Scanner { str: s.as_bytes().to_vec(), index: 0 }
    }

    fn is_text_char(&self, i: usize) -> bool {
        let c = self.str[i];
        c.is_ascii_alphabetic()
    }

    fn is_eos(&self, i: usize) -> bool {
        i >= self.str.len()
    }

    fn is_digit(&self, i: usize) -> bool {
        self.str[i].is_ascii_digit()
    }

    fn getpos(&self) -> usize {
        self.index
    }

    fn setpos(&mut self, pos: usize) {
        self.index = pos;
    }

    fn finished(&self) -> bool {
        self.index >= self.str.len()
    }

    fn peek_token(&self, tokstr: &mut String) -> Token {
        let mut tmp = self.index;
        self.token_internal(tokstr, &mut tmp)
    }

    fn get_token(&mut self, tokstr: &mut String) -> Token {
        let mut idx = self.index;
        let tok = self.token_internal(tokstr, &mut idx);
        self.index = idx;
        tok
    }

    fn token_internal(&self, tokstr: &mut String, index: &mut usize) -> Token {
        // Skip whitespace. Unit strings never contain newlines, so the C++
        // quirk of testing `_str[_index]` for '\n' is irrelevant; we test the
        // running index for all whitespace.
        while *index < self.str.len()
            && (self.str[*index] == b' ' || self.str[*index] == b'\t' || self.str[*index] == b'\n')
        {
            *index += 1;
        }

        if self.is_eos(*index) {
            return Token::Eos;
        }

        match self.str[*index] {
            b'/' => {
                *index += 1;
                return Token::Div;
            }
            b'(' => {
                *index += 1;
                return Token::Lparan;
            }
            b')' => {
                *index += 1;
                return Token::Rparan;
            }
            b'.' => {
                *index += 1;
                return Token::Dot;
            }
            b'^' => {
                *index += 1;
                return Token::Expo;
            }
            _ => {}
        }

        // Identifier or type parameter (leading apostrophe).
        if self.is_text_char(*index) || self.str[*index] == b'\'' {
            let idx = *index;
            *index += 1;
            while !self.is_eos(*index) && self.is_text_char(*index) {
                *index += 1;
            }
            *tokstr = String::from_utf8_lossy(&self.str[idx..*index]).into_owned();
            if self.str[idx] == b'\'' {
                if *index - idx == 1 {
                    *index -= 1;
                    return Token::Unknown;
                }
                return Token::Param;
            }
            return Token::Id;
        }

        // Optionally-signed integer.
        let idx = *index;
        if self.str[*index] == b'+' || self.str[*index] == b'-' {
            *index += 1;
        }
        if !self.is_eos(*index) && self.is_digit(*index) {
            while !self.is_eos(*index) && self.is_digit(*index) {
                *index += 1;
            }
            *tokstr = String::from_utf8_lossy(&self.str[idx..*index]).into_owned();
            return Token::Int;
        }

        Token::Unknown
    }
}

// ─────────────────────────────────────────────────────────────────────────
// UnitParser
// ─────────────────────────────────────────────────────────────────────────

/// The unit database and recursive-descent parser. Mirrors `UnitParser`.
#[derive(Clone, Debug)]
struct UnitParser {
    prefix: BTreeMap<String, Rational>,
    temp_derived: Vec<DerivedInfo>,
    base: Vec<Base>,
    /// Symbol → unit (base and derived). A `BTreeMap` reproduces the C++
    /// `std::map` ordering relied on by `unit2str` and `allUnitSymbols`.
    units: BTreeMap<String, Unit>,
}

impl UnitParser {
    fn new() -> UnitParser {
        UnitParser {
            prefix: BTreeMap::new(),
            temp_derived: Vec::new(),
            base: Vec::new(),
            units: BTreeMap::new(),
        }
    }

    fn add_prefix(&mut self, symbol: &str, exponent: Rational) {
        self.prefix.insert(symbol.to_string(), exponent);
    }

    /// All unit symbols, in reverse key order (the C++ prepends while iterating
    /// the sorted map). `getDerivedUnits` relies on this to ultimately produce
    /// an ascending list.
    fn all_unit_symbols(&self) -> Arc<List<ArcStr>> {
        let mut res = nil();
        for u in self.units.values() {
            res = cons(ArcStr::from(u.unit_symbol.as_str()), res);
        }
        res
    }

    fn add_base(&mut self, quantity_name: &str, unit_name: &str, unit_symbol: &str, prefix_allowed: bool) {
        if self.units.contains_key(unit_symbol) {
            return;
        }
        self.base.push(Base { unit_symbol: unit_symbol.to_string() });
        let mut u = Unit::default();
        u.prefix_allowed = prefix_allowed;
        u.quantity_name = quantity_name.to_string();
        u.unit_name = unit_name.to_string();
        u.unit_symbol = unit_symbol.to_string();
        let n = self.base.len();
        for j in 0..n {
            u.unit_vec.push(Rational::whole(if n - 1 == j { 1 } else { 0 }));
        }
        // Extend every previously-defined unit's vector with a trailing zero.
        for old in self.units.values_mut() {
            old.unit_vec.push(Rational::whole(0));
        }
        self.units.insert(unit_symbol.to_string(), u);
    }

    fn add_derived(&mut self, d: DerivedInfo) {
        self.temp_derived.push(d);
    }

    fn add_derived_internal(&mut self, d: &DerivedInfo) -> UnitResult<()> {
        let mut u = Unit::default();
        self.str2unit(&d.unit_str_exp, &mut u)?;
        u.quantity_name = d.quantity_name.clone();
        u.unit_name = d.unit_name.clone();
        u.unit_symbol = d.unit_symbol.clone();
        u.prefix_allowed = d.prefix_allowed;
        u.prefix_expo = d.prefix_expo;
        u.scale_factor = d.scale_factor;
        u.offset = d.offset;
        u.weight = d.weight;

        match self.units.get(&d.unit_symbol) {
            None => {
                self.units.insert(d.unit_symbol.clone(), u);
            }
            Some(existing) => {
                if u.equal_no_weight(existing) {
                    let entry = self.units.get_mut(&d.unit_symbol).unwrap();
                    entry.weight *= d.weight;
                } else {
                    return Err(UnitErr::DefinedWithDifferentExpr);
                }
            }
        }
        Ok(())
    }

    fn accumulate_weight(&mut self, unit_symbol: &str, weight: f64) {
        if let Some(u) = self.units.get_mut(unit_symbol) {
            u.weight *= weight;
        }
    }

    /// Resolve all pending derived units. Units whose expression references a
    /// not-yet-defined unit are retried until a full pass makes no progress.
    fn commit(&mut self) -> UnitResult<()> {
        while !self.temp_derived.is_empty() {
            let start_size = self.temp_derived.len();
            let mut tmp: Vec<DerivedInfo> = Vec::new();
            for d in std::mem::take(&mut self.temp_derived) {
                if self.add_derived_internal(&d).is_err() {
                    tmp.push(d);
                }
            }
            if tmp.len() == start_size {
                return Err(UnitErr::ErrorAddingUnit);
            }
            self.temp_derived = tmp;
        }
        Ok(())
    }

    fn pretty_print_unit2str(&self, unit: &Unit) -> String {
        // Upstream's MIP-based pretty-printer is a stub that delegates to the
        // plain unparser, so we do the same.
        self.unit2str(unit)
    }

    /// Unparse a unit to its textual form. Mirrors `UnitParser::unit2str`.
    fn unit2str(&self, unit: &Unit) -> String {
        let mut first = true;
        let mut ss = String::new();

        if !unit.scale_factor.is(1, 1) || (unit.is_dimensionless() && unit.prefix_expo.is_zero()) {
            ss.push_str(&unit.scale_factor.to_string());
            first = false;
        }

        if unit.prefix_expo.is(1, 1) {
            if !first {
                ss.push('.');
            }
            ss.push_str("10");
            first = false;
        } else if !unit.prefix_expo.is_zero() {
            if !first {
                ss.push('.');
            }
            ss.push_str("10^");
            ss.push_str(&unit.prefix_expo.to_string());
            first = false;
        }

        for (k, v) in &unit.type_param_vec {
            if !v.is_zero() {
                if !first {
                    ss.push('.');
                }
                ss.push_str(k);
                if !v.is(1, 1) {
                    ss.push_str(&v.to_string());
                }
                first = false;
            }
        }

        // Base units.
        let mut i = 0usize;
        let nbase = unit.unit_vec.len().min(self.base.len());
        while i < nbase {
            let q = unit.unit_vec[i];
            if !q.is_zero() {
                if !first {
                    ss.push('.');
                }
                ss.push_str(&self.base[i].unit_symbol);
                if !q.is(1, 1) {
                    ss.push_str(&q.to_string());
                }
                first = false;
            }
            i += 1;
        }

        // Derived units occupy the remaining vector slots, in map order.
        for u in self.units.values() {
            if !u.is_base_unit() {
                let q = unit.unit_vec.get(i).copied().unwrap_or(Rational { num: 0, denom: 0 });
                if !q.is_zero() {
                    if !first {
                        ss.push('.');
                    }
                    ss.push_str(&u.unit_symbol);
                    if !q.is(1, 1) {
                        ss.push_str(&q.to_string());
                    }
                    first = false;
                }
                i += 1;
            }
        }

        ss
    }

    /// Parse a unit string into `unit`. Mirrors `UnitParser::str2unit`.
    fn str2unit(&self, unitstr: &str, unit: &mut Unit) -> UnitResult<()> {
        if unitstr.is_empty() {
            return Ok(());
        }
        let mut scan = Scanner::new(unitstr);
        *unit = self.parse_expression(&mut scan)?;
        if scan.finished() { Ok(()) } else { Err(UnitErr::ParseError) }
    }

    fn parse_expression(&self, scan: &mut Scanner) -> UnitResult<Unit> {
        let u1 = self.parse_factors(scan)?;
        let mut unit = u1.clone();
        let mut str = String::new();
        let tok = scan.peek_token(&mut str);
        match tok {
            Token::Eos => {
                scan.get_token(&mut str);
                Ok(unit)
            }
            Token::Div => {
                scan.get_token(&mut str);
                let u2 = self.parse_denominator(scan)?;
                Unit::div(&u1, &u2)
            }
            _ => {
                unit = u1;
                Ok(unit)
            }
        }
    }

    fn parse_denominator(&self, scan: &mut Scanner) -> UnitResult<Unit> {
        let mut str = String::new();
        let tok = scan.peek_token(&mut str);
        if tok == Token::Lparan {
            scan.get_token(&mut str);
            let u = self.parse_expression(scan)?;
            if scan.get_token(&mut str) != Token::Rparan {
                return Err(UnitErr::ParseError);
            }
            return Ok(u);
        }
        self.parse_factor(scan)
    }

    fn parse_factors(&self, scan: &mut Scanner) -> UnitResult<Unit> {
        let mut str = String::new();
        let u1 = self.parse_factor(scan)?;
        if scan.peek_token(&mut str) == Token::Dot {
            scan.get_token(&mut str);
            let u2 = self.parse_factors(scan)?;
            Unit::mul(&u1, &u2)
        } else {
            Ok(u1)
        }
    }

    fn parse_factor(&self, scan: &mut Scanner) -> UnitResult<Unit> {
        let mut str = String::new();
        let tok = scan.peek_token(&mut str);
        match tok {
            Token::Id => {
                let u1 = self.parse_symbol(scan)?;
                let scanpostemp = scan.getpos();
                match self.parse_rational(scan) {
                    Ok(q) => Unit::pow(&u1, q),
                    Err(_) => {
                        scan.setpos(scanpostemp);
                        Ok(u1)
                    }
                }
            }
            Token::Param => {
                scan.get_token(&mut str);
                let mut unit = Unit::default();
                let scanpostemp = scan.getpos();
                match self.parse_rational(scan) {
                    Ok(q) => {
                        unit.type_param_vec.insert(str.clone(), q);
                        Ok(unit)
                    }
                    Err(_) => {
                        unit.type_param_vec.insert(str.clone(), Rational::whole(1));
                        scan.setpos(scanpostemp);
                        Ok(unit)
                    }
                }
            }
            _ => {
                // Scale factor, optionally with a `10^n` prefix exponent.
                let q = self.parse_rational(scan)?;
                let mut unit = Unit::default();
                if scan.peek_token(&mut str) != Token::Expo {
                    unit.scale_factor = q;
                    return Ok(unit);
                }
                scan.get_token(&mut str);
                let q2 = self.parse_rational(scan)?;
                if !q.is(10, 1) {
                    return Err(UnitErr::WrongBase);
                }
                unit.prefix_expo = q2;
                Ok(unit)
            }
        }
    }

    fn parse_symbol(&self, scan: &mut Scanner) -> UnitResult<Unit> {
        let mut str = String::new();
        let tok = scan.get_token(&mut str);
        if tok != Token::Id {
            return Err(UnitErr::ParseError);
        }

        // Exact unit symbol (base or derived) takes precedence over prefixing.
        if let Some(u) = self.units.get(&str) {
            return Ok(u.clone());
        }

        // Otherwise try the shortest leading prefix that resolves.
        let bytes = str.as_bytes();
        for i in 1..=bytes.len() {
            let head = &str[0..i];
            if let Some(prefix_expo) = self.prefix.get(head) {
                let tail = &str[i..];
                if let Some(u) = self.units.get(tail) {
                    let mut u = u.clone();
                    if !u.prefix_allowed {
                        return Err(UnitErr::PrefixNotAllowed);
                    }
                    u.prefix_expo = Rational::add(u.prefix_expo, *prefix_expo);
                    return Ok(u);
                }
                return Err(UnitErr::NotFound);
            }
        }
        Err(UnitErr::PrefixNotFound)
    }

    fn parse_rational(&self, scan: &mut Scanner) -> UnitResult<Rational> {
        let mut str = String::new();
        let tok = scan.get_token(&mut str);
        if tok == Token::Int {
            let l1: Sint = str.parse().map_err(|_| UnitErr::InvalidInt)?;
            Ok(Rational::whole(l1))
        } else if tok == Token::Lparan {
            if scan.get_token(&mut str) != Token::Int {
                return Err(UnitErr::ParseError);
            }
            let l1: Sint = str.parse().map_err(|_| UnitErr::InvalidInt)?;
            if scan.get_token(&mut str) != Token::Div {
                return Err(UnitErr::ParseError);
            }
            if scan.get_token(&mut str) != Token::Int {
                return Err(UnitErr::ParseError);
            }
            let l2: Sint = str.parse().map_err(|_| UnitErr::InvalidInt)?;
            if scan.get_token(&mut str) != Token::Rparan {
                return Err(UnitErr::ParseError);
            }
            Ok(Rational::new(l1, l2))
        } else {
            Err(UnitErr::ParseError)
        }
    }

    fn init_prefixes(&mut self) {
        self.add_prefix("da", Rational::whole(1));
        self.add_prefix("h", Rational::whole(2));
        self.add_prefix("k", Rational::whole(3));
        self.add_prefix("M", Rational::whole(6));
        self.add_prefix("G", Rational::whole(9));
        self.add_prefix("T", Rational::whole(12));
        self.add_prefix("P", Rational::whole(15));
        self.add_prefix("E", Rational::whole(18));
        self.add_prefix("Z", Rational::whole(21));
        self.add_prefix("Y", Rational::whole(24));
        self.add_prefix("d", Rational::whole(-1));
        self.add_prefix("c", Rational::whole(-2));
        self.add_prefix("m", Rational::whole(-3));
        self.add_prefix("u", Rational::whole(-6));
        self.add_prefix("n", Rational::whole(-9));
        self.add_prefix("p", Rational::whole(-12));
        self.add_prefix("f", Rational::whole(-15));
        self.add_prefix("a", Rational::whole(-18));
        self.add_prefix("z", Rational::whole(-21));
        self.add_prefix("y", Rational::whole(-24));
    }

    /// Populate the SI base/derived units. Mirrors `UnitParser::initSIUnits`,
    /// following the 64-bit (`MMC_SIZE_INT == 8`) scale-factor constants.
    fn init_si_units(&mut self) {
        self.init_prefixes();

        self.add_base("length", "metre", "m", true);
        self.add_base("mass", "kilogram", "kg", false);
        self.add_base("time", "second", "s", true);
        self.add_base("electric current", "ampere", "A", true);
        self.add_base("thermodynamic temperature", "kelvin", "K", true);
        self.add_base("amount of substance", "mole", "mol", true);
        self.add_base("luminous intensity", "candela", "cd", true);

        // (quantity, unit name, symbol, expression, prefixExpo, scale n, scale d, offset n, offset d, weight)
        let d = |q: &str, un: &str, us: &str, ex: &str, pe: Sint, sn: Sint, sd: Sint, on: Sint, od: Sint, w: f64| DerivedInfo {
            quantity_name: q.to_string(),
            unit_name: un.to_string(),
            unit_symbol: us.to_string(),
            unit_str_exp: ex.to_string(),
            prefix_expo: Rational::whole(pe),
            scale_factor: Rational::new(sn, sd),
            offset: Rational::new(on, od),
            prefix_allowed: true,
            weight: w,
        };

        // Special derived unit for handling gram.
        self.add_derived(d("mass", "gram", "g", "kg", -3, 1, 1, 0, 1, 1.0));

        // Standard derived units (SI brochure 8th ed., page 118).
        self.add_derived(d("plane angle", "radian", "rad", "m/m", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("solid angle", "steradian", "sr", "m2/m2", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("frequency", "hertz", "Hz", "s-1", 0, 1, 1, 0, 1, 0.8));
        self.add_derived(d("force", "newton", "N", "m.kg.s-2", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("pressure, stress", "pascal", "Pa", "N/m2", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("power, radiant flux", "watt", "W", "J/s", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("energy, work, amount of heat", "joule", "J", "N.m", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("electric charge, amount of electricity", "coulomb", "C", "s.A", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("electric potential difference, electromotive force", "volt", "V", "W/A", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("capacitance", "farad", "F", "C/V", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("electric resistance", "ohm", "Ohm", "V/A", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("electric conductance", "siemens", "S", "A/V", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("magnetic flux", "weber", "Wb", "V.s", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("magnetic flux density", "tesla", "T", "Wb/m2", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("inductance", "henry", "H", "Wb/A", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("thermodynamic temperature", "degree Celsius", "degC", "K", 0, 1, 1, 27315, 100, 1.0));
        self.add_derived(d("luminous flux", "lumen", "lm", "cd.sr", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("illuminance", "lux", "lx", "lm/m2", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("activity referred to a radionuclide", "becquerel", "Bq", "s-1", 0, 1, 1, 0, 1, 0.8));
        self.add_derived(d("absorbed dose, specific energy (imparted), kerma", "gray", "Gy", "J/kg", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d(
            "dose equivalent, ambient dose equivalent, directional dose equivalent, personal dose equivalent",
            "sievert", "Sv", "J/kg", 0, 1, 1, 0, 1, 1.0,
        ));
        self.add_derived(d("catalyctic activity", "katal", "kat", "s-1.mol", 0, 1, 1, 0, 1, 1.0));

        // More derived units (64-bit scale factors).
        self.add_derived(d("plane angle", "degree", "deg", "rad", 0, 31415926535897932, 1800000000000000000, 0, 1, 1.0));
        self.add_derived(d("plane angle", "revolutions", "rev", "rad", 0, 31415926535897932, 5000000000000000, 0, 1, 1.0));
        self.add_derived(d("angular velocity", "revolutions per minute", "rpm", "rad/s", 0, 31415926535897932, 300000000000000000, 0, 1, 1.0));
        self.add_derived(d("energy", "watt hour", "Wh", "J", 0, 3600, 1, 0, 1, 1.0));
        self.add_derived(d("velocity", "knot", "kn", "m/s", 0, 1852, 3600, 0, 1, 1.0));
        self.add_derived(d("mass", "metric ton", "t", "kg", 3, 1, 1, 0, 1, 1.0));
        self.add_derived(d("volume", "litre", "l", "m3", 0, 1, 1000, 0, 1, 1.0));
        self.add_derived(d("apparent power", "volt-ampere", "VA", "J/s", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("reactive power", "volt-ampere reactive", "var", "J/s", 0, 1, 1, 0, 1, 1.0));
        self.add_derived(d("thermodynamic temperature", "degree Fahrenheit", "degF", "K", 0, 5, 9, 27315 * 9 - 3200 * 5, 900, 1.0));
        self.add_derived(d("thermodynamic temperature", "degree Rankine", "degRk", "K", 0, 5, 9, 0, 1, 1.0));
        self.add_derived(d("pressure", "bar", "bar", "Pa", 0, 100000, 1, 0, 1, 1.0));
        self.add_derived(d("pressure", "millimeter of mercury", "mmHg", "Pa", 0, 133322387415, 1000000000, 0, 1, 1.0));
        self.add_derived(d("time", "minute", "min", "s", 0, 60, 1, 0, 1, 1.0));
        self.add_derived(d("time", "hour", "h", "s", 0, 60 * 60, 1, 0, 1, 1.0));
        self.add_derived(d("time", "day", "d", "s", 0, 60 * 60 * 24, 1, 0, 1, 1.0));
        self.add_derived(d("length", "inch", "in", "m", 0, 254, 10000, 0, 1, 1.0));
        self.add_derived(d("length", "foot", "ft", "m", 0, 3048, 10000, 0, 1, 1.0));
        self.add_derived(d("velocity", "miles per hour", "mph", "m/s", 0, 44704, 100000, 0, 1, 1.0));
        self.add_derived(d("mass", "pound", "lb", "kg", 0, 45359237, 100000000, 0, 1, 1.0));
        self.add_derived(d("pressure", "pound per square inch", "psi", "Pa", 0, 689475729, 100000, 0, 1, 1.0));
        self.add_derived(d("pressure", "inch water gauge", "inWG", "Pa", 0, 249088908333, 1000000000, 0, 1, 1.0));

        let _ = self.commit();
    }
}

// ─────────────────────────────────────────────────────────────────────────
// Per-thread parser state
// ─────────────────────────────────────────────────────────────────────────

struct State {
    parser: UnitParser,
    rollback: Vec<UnitParser>,
}

thread_local! {
    static STATE: RefCell<State> =
        RefCell::new(State { parser: UnitParser::new(), rollback: Vec::new() });
}

fn with_state<F, R>(f: F) -> R
where
    F: FnOnce(&mut State) -> R,
{
    STATE.with(|s| f(&mut s.borrow_mut()))
}

// ─────────────────────────────────────────────────────────────────────────
// External function entry points (signatures match the generated stubs)
// ─────────────────────────────────────────────────────────────────────────

static ERROR_PARSING_UNIT: ErrorTypes::Message = ErrorTypes::Message {
    id: -1,
    ty: ErrorTypes::MessageType::SCRIPTING,
    severity: ErrorTypes::Severity::ERROR,
    message: literal!("Error parsing unit %s: %s"),
};

pub fn initSIUnits() {
    with_state(|s| s.parser.init_si_units());
}

pub fn unit2str(
    noms: Arc<List<i32>>,
    denoms: Arc<List<i32>>,
    tpnoms: Arc<List<i32>>,
    tpdenoms: Arc<List<i32>>,
    tpstrs: Arc<List<ArcStr>>,
    _scaleFactor: Real,
    _offset: Real,
) -> ArcStr {
    let mut unit = Unit::default();
    // Base-unit exponent vector.
    for (n, dn) in (&*noms).into_iter().zip(&*denoms) {
        unit.unit_vec.push(Rational::new(*n as Sint, *dn as Sint));
    }
    // Symbolic type parameters.
    let mut tpn = (&*tpnoms).into_iter();
    let mut tpd = (&*tpdenoms).into_iter();
    for sym in (&*tpstrs).into_iter() {
        let (Some(n), Some(dn)) = (tpn.next(), tpd.next()) else { break };
        unit.type_param_vec
            .insert(sym.as_str().to_string(), Rational::new(*n as Sint, *dn as Sint));
    }
    let res = with_state(|s| s.parser.pretty_print_unit2str(&unit));
    ArcStr::from(res)
}

pub fn str2unit(
    res: ArcStr,
) -> Result<(
    Arc<List<i32>>,
    Arc<List<i32>>,
    Arc<List<i32>>,
    Arc<List<i32>>,
    Arc<List<ArcStr>>,
    Real,
    Real,
)> {
    let input = res.as_str();
    let mut unit = Unit::default();
    let parse = with_state(|s| s.parser.str2unit(input, &mut unit));
    if let Err(e) = parse {
        // Matches the C++ `Error parsing unit <str>: <reason>` message.
        Error::addMessage(
            ERROR_PARSING_UNIT.clone(),
            Arc::new(List::from_iter([ArcStr::from(input), ArcStr::from(e.message())])),
        )?;
        bail!("Error parsing unit {}: {}", input, e.message());
    }

    let scale_factor = unit.scale_factor.to_real() * 10f64.powf(unit.prefix_expo.to_real());
    let offset = unit.offset.to_real();

    let noms = Arc::new(List::from_iter(unit.unit_vec.iter().map(|r| r.num as i32)));
    let denoms = Arc::new(List::from_iter(unit.unit_vec.iter().map(|r| r.denom as i32)));
    let tpnoms = Arc::new(List::from_iter(unit.type_param_vec.values().map(|r| r.num as i32)));
    let tpdenoms = Arc::new(List::from_iter(unit.type_param_vec.values().map(|r| r.denom as i32)));
    let tpstrs = Arc::new(List::from_iter(
        unit.type_param_vec.keys().map(|k| ArcStr::from(k.as_str())),
    ));

    Ok((noms, denoms, tpnoms, tpdenoms, tpstrs, OrderedFloat(scale_factor), OrderedFloat(offset)))
}

pub fn allUnitSymbols() -> Arc<List<ArcStr>> {
    with_state(|s| s.parser.all_unit_symbols())
}

pub fn addBase(name: ArcStr) {
    let prefix_allowed = name.as_str() != "kg";
    with_state(|s| s.parser.add_base("", "", name.as_str(), prefix_allowed));
}

pub fn registerWeight(name: ArcStr, weight: Real) {
    with_state(|s| s.parser.accumulate_weight(name.as_str(), weight.into_inner()));
}

pub fn addDerived(name: ArcStr, exp: ArcStr) {
    addDerivedWeight(name, exp, OrderedFloat(1.0));
}

pub fn addDerivedWeight(name: ArcStr, exp: ArcStr, weight: Real) {
    let info = DerivedInfo {
        quantity_name: name.as_str().to_string(),
        unit_name: name.as_str().to_string(),
        unit_symbol: name.as_str().to_string(),
        unit_str_exp: exp.as_str().to_string(),
        prefix_expo: Rational::whole(0),
        scale_factor: Rational::whole(1),
        offset: Rational::whole(0),
        prefix_allowed: true,
        weight: weight.into_inner(),
    };
    with_state(|s| s.parser.add_derived(info));
}

pub fn checkpoint() {
    with_state(|s| {
        let snapshot = s.parser.clone();
        s.rollback.push(snapshot);
    });
}

pub fn rollback() {
    with_state(|s| match s.rollback.pop() {
        Some(old) => s.parser = old,
        None => eprintln!("Error, rollback on empty stack"),
    });
}

pub fn clear() {
    with_state(|s| s.parser = UnitParser::new());
}

pub fn commit() {
    with_state(|s| {
        let _ = s.parser.commit();
    });
}
