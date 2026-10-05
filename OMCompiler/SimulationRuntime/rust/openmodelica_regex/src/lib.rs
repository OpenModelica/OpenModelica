//! POSIX regular expressions over the [`regex`] crate, whose syntax is not quite
//! what `regcomp` accepts: [`posix_to_rust`] reconciles the two and
//! [`regex_builder`] carries the flags `regcomp` implies. [`Regex`] is both, for
//! the common case of one ERE tested against many strings.

/// Two incompatibilities to reconcile: in BRE the grouping and quantifier
/// metacharacters are the *escaped* forms and the bare ones literal, the reverse
/// of ERE and of the crate; and a bracket expression's leading `]` or bare `[` is
/// an ordinary member, which the crate needs escaped. ERE otherwise passes
/// through. Backreferences occur in neither.
pub fn posix_to_rust(re: &str, extended: bool) -> String {
    let mut out = String::with_capacity(re.len() + 8);
    let mut chars = re.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '\\' => match chars.next() {
                // In BRE these escapes are the operators.
                Some(m @ ('(' | ')' | '{' | '}' | '+' | '?' | '|')) if !extended => out.push(m),
                Some(other) => {
                    out.push('\\');
                    out.push(other);
                }
                None => out.push('\\'),
            },
            // ... and their bare forms are literal.
            '(' | ')' | '{' | '}' | '+' | '?' | '|' if !extended => {
                out.push('\\');
                out.push(c);
            }
            '[' => {
                out.push('[');
                if chars.peek() == Some(&'^') {
                    out.push(chars.next().unwrap());
                }
                // A leading ']' is a literal member; the crate needs it escaped.
                if chars.peek() == Some(&']') {
                    chars.next();
                    out.push_str("\\]");
                }
                while let Some(c2) = chars.next() {
                    if c2 == '[' && matches!(chars.peek(), Some(':' | '.' | '=')) {
                        // POSIX [:class:] / [.coll.] / [=eq=]: copy to its close.
                        out.push('[');
                        let kind = chars.next().unwrap();
                        out.push(kind);
                        while let Some(c3) = chars.next() {
                            out.push(c3);
                            if c3 == kind && chars.peek() == Some(&']') {
                                out.push(chars.next().unwrap());
                                break;
                            }
                        }
                    } else if c2 == '[' {
                        out.push_str("\\[");
                    } else {
                        out.push(c2);
                        if c2 == ']' {
                            break;
                        }
                    }
                }
            }
            _ => out.push(c),
        }
    }
    out
}

/// The C runtime passes no `REG_NEWLINE`, so `.` spans newlines and `^`/`$`
/// anchor the subject. The crate's fixed size budgets are far too small for a
/// pattern naming every variable of a large model, so they scale with its length.
pub fn regex_builder(pattern: &str) -> regex::RegexBuilder {
    let budget = pattern.len().saturating_mul(512);
    let mut b = regex::RegexBuilder::new(pattern);
    b.dot_matches_new_line(true).size_limit(budget.max(10 << 20)).dfa_size_limit(budget.max(2 << 20));
    b
}

/// One ERE against many strings; [`regex`] compiles per call.
pub struct Regex {
    re: regex::Regex,
}

impl Regex {
    /// No captures (`REG_NOSUB`); the error is the backend's own message.
    pub fn new(re: &str) -> Result<Self, String> {
        regex_builder(&posix_to_rust(re, true))
            .build()
            .map(|re| Regex { re })
            .map_err(|e| e.to_string())
    }

    pub fn is_match(&self, s: &str) -> bool {
        self.re.is_match(s)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ere_bracket_expressions() {
        // A leading `]` and a bare `[` are ordinary members to POSIX.
        assert_eq!(posix_to_rust("[]a]", true), "[\\]a]");
        assert_eq!(posix_to_rust("y[[]3[]]", true), "y[\\[]3[\\]]");
        // A character class keeps its own `]`.
        assert_eq!(posix_to_rust("[[:alpha:]]+", true), "[[:alpha:]]+");
        // ERE is otherwise the crate's own syntax.
        assert_eq!(posix_to_rust("x.*|y\\[[12]\\]", true), "x.*|y\\[[12]\\]");
    }

    #[test]
    fn bre_swaps_the_operator_forms() {
        assert_eq!(posix_to_rust("a\\(b\\)\\+", false), "a(b)+");
        assert_eq!(posix_to_rust("a(b)+", false), "a\\(b\\)\\+");
    }

    #[test]
    fn matches_like_regexec() {
        let re = Regex::new("^([[:alpha:]]+)$").unwrap();
        assert!(re.is_match("xa"));
        assert!(!re.is_match("y[1]"));
        // No REG_NEWLINE, so `.` spans a newline and `^`/`$` anchor the subject.
        assert!(Regex::new("^(a.b)$").unwrap().is_match("a\nb"));
        assert!(Regex::new("bad(").is_err());
    }
}
