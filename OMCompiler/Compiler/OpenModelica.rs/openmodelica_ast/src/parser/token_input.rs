/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

//! Helpers for driving winnow parsers from a slice of [`lexer::Token`]s.
//!
//! [`&\[Token\]`] already implements [`winnow::stream::Stream`] for `Token: Clone + Debug`,
//! so all winnow combinators (`opt`, `alt`, `cut_err`, `peek`, …) work out of
//! the box.  This module adds typed helper combinators on top.

use super::lexer::{Token as LexToken, TokenKind as TK, keyword_as_str};
use winnow::{ModalResult, error::{ContextError, ErrMode}};
use arcstr::{ArcStr, literal};

/// The parser input type: a slice of already-lexed tokens.
pub type TokenInput<'a> = &'a [LexToken];

// ---------------------------------------------------------------------------
// Primitive token consumers
// ---------------------------------------------------------------------------

/// Consume the next token if its kind equals `kind`; otherwise backtrack.
#[inline]
pub fn t(kind: TK) -> impl Fn(&mut &[LexToken]) -> ModalResult<TK> {
    move |input: &mut &[LexToken]| {
        match input.first() {
            Some(tok) if tok.kind == kind => { let k = tok.kind.clone(); *input = &input[1..]; Ok(k) }
            _ => Err(ErrMode::Backtrack(ContextError::default())),
        }
    }
}

/// Consume the next token unconditionally, returning its kind.  Backtrack on
/// EOF.
#[inline]
pub fn next_tok(input: &mut &[LexToken]) -> ModalResult<TK> {
    match input.first() {
        Some(tok) => { let k = tok.kind.clone(); *input = &input[1..]; Ok(k) }
        None => Err(ErrMode::Backtrack(ContextError::default())),
    }
}

/// Peek at the next token's kind without consuming it.
#[inline]
pub fn peek_kind<'a>(input: &'a &[LexToken]) -> Option<&'a TK> {
    input.first().map(|t| &t.kind)
}

/// Consume the next token only if `f` returns `Some`; otherwise leave the
/// input unchanged.  Returns the mapped value.
#[inline]
pub fn try_tok<F, T>(input: &mut &[LexToken], f: F) -> Option<T>
where
    F: Fn(&TK) -> Option<T>,
{
    match input.first() {
        Some(tok) => match f(&tok.kind) {
            Some(v) => { *input = &input[1..]; Some(v) }
            None => None,
        },
        None => None,
    }
}

// ---------------------------------------------------------------------------
// Typed literal consumers
// ---------------------------------------------------------------------------

/// Consume an `Ident` token and return its string value.
#[inline]
pub fn t_ident(input: &mut &[LexToken]) -> ModalResult<ArcStr> {
    let s: ArcStr = match input.first() {
        // Mirrors the ANTLR `identifier` rule:
        // `IDENT | DER | CODE | EQUALITY | INITIAL`.
        Some(LexToken { kind: TK::Der, .. }) => literal!("der"),
        Some(LexToken { kind: TK::Initial, .. }) => literal!("initial"),
        Some(LexToken { kind: TK::Code, .. }) => literal!("$Code"),
        Some(LexToken { kind: TK::Equality, .. }) => literal!("equality"),
        Some(LexToken { kind: TK::Ident(s), .. })
        => s.clone(),
        _ => return Err(ErrMode::Backtrack(ContextError::default())),
    };
    *input = &input[1..];
    Ok(s)
}

/// Consume a name-path component: `IDENT | CODE` only (ANTLR `name_path2`).
/// Unlike [`t_ident`] this does *not* accept `der`/`initial`/`equality`, which
/// the grammar admits as declaration names but not inside a qualified name or
/// type reference (so `Real x(initial = 1)` is correctly a syntax error).
#[inline]
pub fn t_path_ident(input: &mut &[LexToken]) -> ModalResult<ArcStr> {
    match input.first() {
        Some(LexToken { kind: TK::Ident(s), .. }) => {
            let s = s.clone(); *input = &input[1..]; Ok(s)
        }
        Some(LexToken { kind: TK::Code, .. }) => {
            *input = &input[1..]; Ok(literal!("$Code"))
        }
        _ => Err(ErrMode::Backtrack(ContextError::default())),
    }
}

/// Consume an `Ident` *or* any keyword token, returning the source spelling.
/// Used where keywords may appear as field/record names (e.g. named arguments).
#[inline]
pub fn t_any_ident(input: &mut &[LexToken]) -> ModalResult<ArcStr> {
    match input.first() {
        Some(LexToken { kind: TK::Ident(s), .. }) => {
            let s = s.clone(); *input = &input[1..]; Ok(s)
        }
        Some(LexToken { kind, .. }) => {
            if let Some(spelling) = keyword_as_str(kind) {
                *input = &input[1..];
                Ok(spelling.into())
            } else {
                Err(ErrMode::Backtrack(ContextError::default()))
            }
        }
        None => Err(ErrMode::Backtrack(ContextError::default())),
    }
}

/// Consume a `Str` token and return its raw content (escape sequences preserved).
#[inline]
pub fn t_str_token(input: &mut &[LexToken]) -> ModalResult<ArcStr> {
    match input.first() {
        Some(LexToken { kind: TK::Str(s), .. }) => {
            let s = s.clone(); *input = &input[1..]; Ok(s)
        }
        _ => Err(ErrMode::Backtrack(ContextError::default())),
    }
}

// ---------------------------------------------------------------------------
// Position helper
// ---------------------------------------------------------------------------

/// Return the source position (line, col) of the next token, or (0,0) at EOF.
#[inline]
pub fn current_pos(input: &&[LexToken]) -> (u32, u32) {
    input.first().map(|t| (t.line, t.col)).unwrap_or((0, 0))
}
