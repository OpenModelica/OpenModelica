//! Input expressions in `t`, the form a master needs to drive an FMU with
//! something other than a constant: `sin(2*PI*t)`, `t < 1 ? 0 : 1`.
//!
//! A Model Exchange run asks for input values at times the solver picks, so a
//! sampled table would have to be interpolated; an expression is evaluated where
//! it is needed instead. Parsed once into a tree, then evaluated per time point.

use std::fmt;

#[derive(Clone, Debug)]
pub enum Expr {
    Const(f64),
    Time,
    Unary(UnOp, Box<Expr>),
    Binary(BinOp, Box<Expr>, Box<Expr>),
    Call(Func, Vec<Expr>),
    /// `cond ? a : b`.
    If(Box<Expr>, Box<Expr>, Box<Expr>),
}

#[derive(Clone, Copy, Debug)]
pub enum UnOp {
    Neg,
    Not,
}

#[derive(Clone, Copy, Debug)]
pub enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
    Pow,
    Lt,
    Le,
    Gt,
    Ge,
    Eq,
    Ne,
    And,
    Or,
}

#[derive(Clone, Copy, Debug)]
pub enum Func {
    Sin,
    Cos,
    Tan,
    Asin,
    Acos,
    Atan,
    Atan2,
    Exp,
    Log,
    Log10,
    Sqrt,
    Abs,
    Floor,
    Ceil,
    Round,
    Sign,
    Min,
    Max,
    Mod,
}

impl Func {
    fn arity(self) -> usize {
        match self {
            Func::Atan2 | Func::Min | Func::Max | Func::Mod => 2,
            _ => 1,
        }
    }

    fn lookup(name: &str) -> Option<Func> {
        Some(match name {
            "sin" => Func::Sin,
            "cos" => Func::Cos,
            "tan" => Func::Tan,
            "asin" => Func::Asin,
            "acos" => Func::Acos,
            "atan" => Func::Atan,
            "atan2" => Func::Atan2,
            "exp" => Func::Exp,
            "log" | "ln" => Func::Log,
            "log10" => Func::Log10,
            "sqrt" => Func::Sqrt,
            "abs" => Func::Abs,
            "floor" => Func::Floor,
            "ceil" => Func::Ceil,
            "round" => Func::Round,
            "sign" => Func::Sign,
            "min" => Func::Min,
            "max" => Func::Max,
            "mod" | "rem" => Func::Mod,
            _ => return None,
        })
    }
}

impl Expr {
    /// Parse an expression in `t`. Constants: `PI`, `e`, `inf`.
    pub fn parse(text: &str) -> Result<Expr, ParseError> {
        let mut p = Parser { s: text.as_bytes(), i: 0 };
        p.space();
        let e = p.ternary()?;
        p.space();
        if p.i != p.s.len() {
            return Err(p.error("unexpected trailing input"));
        }
        Ok(e)
    }

    pub fn eval(&self, t: f64) -> f64 {
        match self {
            Expr::Const(v) => *v,
            Expr::Time => t,
            Expr::Unary(op, a) => {
                let a = a.eval(t);
                match op {
                    UnOp::Neg => -a,
                    UnOp::Not => bool_of(a == 0.0),
                }
            }
            Expr::Binary(op, a, b) => {
                let (a, b) = (a.eval(t), b.eval(t));
                match op {
                    BinOp::Add => a + b,
                    BinOp::Sub => a - b,
                    BinOp::Mul => a * b,
                    BinOp::Div => a / b,
                    BinOp::Pow => a.powf(b),
                    BinOp::Lt => bool_of(a < b),
                    BinOp::Le => bool_of(a <= b),
                    BinOp::Gt => bool_of(a > b),
                    BinOp::Ge => bool_of(a >= b),
                    BinOp::Eq => bool_of(a == b),
                    BinOp::Ne => bool_of(a != b),
                    BinOp::And => bool_of(a != 0.0 && b != 0.0),
                    BinOp::Or => bool_of(a != 0.0 || b != 0.0),
                }
            }
            Expr::Call(f, args) => {
                let a = args[0].eval(t);
                let b = || args[1].eval(t);
                match f {
                    Func::Sin => a.sin(),
                    Func::Cos => a.cos(),
                    Func::Tan => a.tan(),
                    Func::Asin => a.asin(),
                    Func::Acos => a.acos(),
                    Func::Atan => a.atan(),
                    Func::Atan2 => a.atan2(b()),
                    Func::Exp => a.exp(),
                    Func::Log => a.ln(),
                    Func::Log10 => a.log10(),
                    Func::Sqrt => a.sqrt(),
                    Func::Abs => a.abs(),
                    Func::Floor => a.floor(),
                    Func::Ceil => a.ceil(),
                    Func::Round => a.round(),
                    Func::Sign => {
                        if a == 0.0 {
                            0.0
                        } else {
                            a.signum()
                        }
                    }
                    Func::Min => a.min(b()),
                    Func::Max => a.max(b()),
                    Func::Mod => a - b() * (a / b()).floor(),
                }
            }
            Expr::If(c, a, b) => {
                if c.eval(t) != 0.0 {
                    a.eval(t)
                } else {
                    b.eval(t)
                }
            }
        }
    }

    /// Whether the value depends on time at all; a constant input is set once.
    pub fn is_constant(&self) -> bool {
        match self {
            Expr::Const(_) => true,
            Expr::Time => false,
            Expr::Unary(_, a) => a.is_constant(),
            Expr::Binary(_, a, b) => a.is_constant() && b.is_constant(),
            Expr::Call(_, args) => args.iter().all(Expr::is_constant),
            Expr::If(c, a, b) => c.is_constant() && a.is_constant() && b.is_constant(),
        }
    }
}

fn bool_of(b: bool) -> f64 {
    if b { 1.0 } else { 0.0 }
}

#[derive(Debug)]
pub struct ParseError {
    pub message: String,
    pub position: usize,
}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} at character {}", self.message, self.position + 1)
    }
}

impl std::error::Error for ParseError {}

/// Recursive descent, precedence climbing from `||` down to `^`.
struct Parser<'a> {
    s: &'a [u8],
    i: usize,
}

impl Parser<'_> {
    fn error(&self, message: &str) -> ParseError {
        ParseError { message: message.to_string(), position: self.i }
    }

    fn space(&mut self) {
        while self.i < self.s.len() && self.s[self.i].is_ascii_whitespace() {
            self.i += 1;
        }
    }

    fn eat(&mut self, token: &str) -> bool {
        self.space();
        if self.s[self.i..].starts_with(token.as_bytes()) {
            self.i += token.len();
            return true;
        }
        false
    }

    fn peek(&mut self) -> u8 {
        self.space();
        self.s.get(self.i).copied().unwrap_or(0)
    }

    fn ternary(&mut self) -> Result<Expr, ParseError> {
        let c = self.or()?;
        if self.eat("?") {
            let a = self.ternary()?;
            if !self.eat(":") {
                return Err(self.error("expected `:`"));
            }
            let b = self.ternary()?;
            return Ok(Expr::If(Box::new(c), Box::new(a), Box::new(b)));
        }
        Ok(c)
    }

    fn or(&mut self) -> Result<Expr, ParseError> {
        let mut a = self.and()?;
        while self.eat("||") || self.eat("or") {
            a = Expr::Binary(BinOp::Or, Box::new(a), Box::new(self.and()?));
        }
        Ok(a)
    }

    fn and(&mut self) -> Result<Expr, ParseError> {
        let mut a = self.compare()?;
        while self.eat("&&") || self.eat("and") {
            a = Expr::Binary(BinOp::And, Box::new(a), Box::new(self.compare()?));
        }
        Ok(a)
    }

    fn compare(&mut self) -> Result<Expr, ParseError> {
        let a = self.sum()?;
        // The two-character operators first: `<` would otherwise eat `<=`.
        for (token, op) in [
            ("<=", BinOp::Le),
            (">=", BinOp::Ge),
            ("==", BinOp::Eq),
            ("!=", BinOp::Ne),
            ("<>", BinOp::Ne),
            ("<", BinOp::Lt),
            (">", BinOp::Gt),
        ] {
            if self.eat(token) {
                return Ok(Expr::Binary(op, Box::new(a), Box::new(self.sum()?)));
            }
        }
        Ok(a)
    }

    fn sum(&mut self) -> Result<Expr, ParseError> {
        let mut a = self.product()?;
        loop {
            self.space();
            let op = match self.peek() {
                b'+' => BinOp::Add,
                b'-' => BinOp::Sub,
                _ => return Ok(a),
            };
            self.i += 1;
            a = Expr::Binary(op, Box::new(a), Box::new(self.product()?));
        }
    }

    fn product(&mut self) -> Result<Expr, ParseError> {
        let mut a = self.unary()?;
        loop {
            self.space();
            let op = match self.peek() {
                b'*' => BinOp::Mul,
                b'/' => BinOp::Div,
                _ => return Ok(a),
            };
            self.i += 1;
            a = Expr::Binary(op, Box::new(a), Box::new(self.unary()?));
        }
    }

    fn unary(&mut self) -> Result<Expr, ParseError> {
        self.space();
        match self.peek() {
            b'-' => {
                self.i += 1;
                Ok(Expr::Unary(UnOp::Neg, Box::new(self.unary()?)))
            }
            b'+' => {
                self.i += 1;
                self.unary()
            }
            b'!' if !self.s[self.i..].starts_with(b"!=") => {
                self.i += 1;
                Ok(Expr::Unary(UnOp::Not, Box::new(self.unary()?)))
            }
            _ => self.power(),
        }
    }

    /// Right-associative, and binding tighter than unary minus on its right:
    /// `2^-1` parses, `-2^2` is `-(2^2)`.
    fn power(&mut self) -> Result<Expr, ParseError> {
        let a = self.atom()?;
        if self.eat("^") || self.eat("**") {
            return Ok(Expr::Binary(BinOp::Pow, Box::new(a), Box::new(self.unary()?)));
        }
        Ok(a)
    }

    fn atom(&mut self) -> Result<Expr, ParseError> {
        self.space();
        match self.peek() {
            b'(' => {
                self.i += 1;
                let e = self.ternary()?;
                if !self.eat(")") {
                    return Err(self.error("expected `)`"));
                }
                Ok(e)
            }
            c if c.is_ascii_digit() || c == b'.' => self.number(),
            c if c.is_ascii_alphabetic() || c == b'_' => self.name(),
            0 => Err(self.error("expected an expression")),
            _ => Err(self.error("unexpected character")),
        }
    }

    fn number(&mut self) -> Result<Expr, ParseError> {
        let start = self.i;
        while self.i < self.s.len()
            && (self.s[self.i].is_ascii_digit() || self.s[self.i] == b'.')
        {
            self.i += 1;
        }
        // An exponent, and the sign that may follow it.
        if self.i < self.s.len() && (self.s[self.i] | 32) == b'e' {
            let mark = self.i;
            self.i += 1;
            if self.i < self.s.len() && (self.s[self.i] == b'+' || self.s[self.i] == b'-') {
                self.i += 1;
            }
            if self.i < self.s.len() && self.s[self.i].is_ascii_digit() {
                while self.i < self.s.len() && self.s[self.i].is_ascii_digit() {
                    self.i += 1;
                }
            } else {
                self.i = mark;
            }
        }
        let text = std::str::from_utf8(&self.s[start..self.i]).unwrap_or_default();
        text.parse().map(Expr::Const).map_err(|_| ParseError {
            message: format!("`{text}` is not a number"),
            position: start,
        })
    }

    fn name(&mut self) -> Result<Expr, ParseError> {
        let start = self.i;
        while self.i < self.s.len()
            && (self.s[self.i].is_ascii_alphanumeric() || self.s[self.i] == b'_')
        {
            self.i += 1;
        }
        let name = std::str::from_utf8(&self.s[start..self.i]).unwrap_or_default().to_string();
        match name.as_str() {
            "t" | "time" => return Ok(Expr::Time),
            "PI" | "pi" => return Ok(Expr::Const(std::f64::consts::PI)),
            "e" => return Ok(Expr::Const(std::f64::consts::E)),
            "inf" | "Inf" => return Ok(Expr::Const(f64::INFINITY)),
            "true" => return Ok(Expr::Const(1.0)),
            "false" => return Ok(Expr::Const(0.0)),
            _ => {}
        }
        let Some(f) = Func::lookup(&name) else {
            return Err(ParseError {
                message: format!("unknown name `{name}` (the time is `t`)"),
                position: start,
            });
        };
        if !self.eat("(") {
            return Err(self.error("expected `(`"));
        }
        let mut args = vec![self.ternary()?];
        while self.eat(",") {
            args.push(self.ternary()?);
        }
        if !self.eat(")") {
            return Err(self.error("expected `)`"));
        }
        if args.len() != f.arity() {
            return Err(ParseError {
                message: format!("{name} takes {} argument(s), got {}", f.arity(), args.len()),
                position: start,
            });
        }
        Ok(Expr::Call(f, args))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn at(text: &str, t: f64) -> f64 {
        Expr::parse(text).expect("parse").eval(t)
    }

    #[test]
    fn arithmetic_follows_precedence() {
        assert_eq!(at("1 + 2 * 3", 0.0), 7.0);
        assert_eq!(at("(1 + 2) * 3", 0.0), 9.0);
        assert_eq!(at("-2^2", 0.0), -4.0);
        assert_eq!(at("2^3^2", 0.0), 512.0);
        assert_eq!(at("2^-1", 0.0), 0.5);
        assert_eq!(at("1e-3", 0.0), 0.001);
    }

    #[test]
    fn the_time_drives_the_value() {
        assert_eq!(at("t", 2.5), 2.5);
        assert!((at("sin(2*PI*t)", 0.25) - 1.0).abs() < 1e-12);
        assert_eq!(at("t < 1 ? 0 : 1", 0.5), 0.0);
        assert_eq!(at("t < 1 ? 0 : 1", 1.5), 1.0);
        assert_eq!(at("max(t, 1)", 0.5), 1.0);
    }

    #[test]
    fn a_constant_expression_is_recognised() {
        assert!(Expr::parse("2*PI").unwrap().is_constant());
        assert!(!Expr::parse("2*t").unwrap().is_constant());
    }

    #[test]
    fn a_bad_expression_names_the_position() {
        assert!(Expr::parse("2 +").is_err());
        assert!(Expr::parse("foo(1)").is_err());
        assert!(Expr::parse("sin(1, 2)").is_err());
        assert!(Expr::parse("1 2").is_err());
    }
}
