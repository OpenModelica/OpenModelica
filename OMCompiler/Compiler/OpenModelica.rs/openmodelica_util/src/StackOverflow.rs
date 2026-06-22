// Auto-generated from MetaModelica source
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
#![allow(warnings)]
#![allow(unreachable_patterns, unreachable_code, non_camel_case_types, non_snake_case, dead_code, unused_imports, unused_variables, non_upper_case_globals, unused_mut)]

use std::sync::Arc;
use anyhow::{Result, bail};
use loop_unwrap::unwrap_break_err;
use metamodelica::*; // Built-in types and functions
use const_str;
use arcstr::{ArcStr, literal, format};

use crate::StringUtil;
use crate::System;
use crate::Testsuite;

fn unmangle(mut inSymbol: ArcStr) -> Result<ArcStr> {
    let mut outSymbol: ArcStr = arcstr::literal!("");
    outSymbol = (inSymbol.clone()).clone();
    if StringUtil::startsWith((inSymbol.clone()).clone(), (literal!("omc_")).clone()) {
        outSymbol = substring((outSymbol.clone()).clone(), 5, ((outSymbol.clone()).clone().len() as i32))?;
        outSymbol = (System::stringReplace((outSymbol.clone()).clone(), (literal!("__")).clone(), (literal!("#")).clone())?).clone();
        outSymbol = (System::stringReplace((outSymbol.clone()).clone(), (literal!("_")).clone(), (literal!(".")).clone())?).clone();
        outSymbol = (System::stringReplace((outSymbol.clone()).clone(), (literal!("#")).clone(), (literal!("_")).clone())?).clone();
    }
    Ok(outSymbol)
}

fn stripAddresses(mut inSymbol: ArcStr) -> Result<ArcStr> {
    let mut outSymbol: ArcStr = arcstr::literal!("");
    let mut n: i32 = 0;
    let mut strs: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
    let mut so: ArcStr = arcstr::literal!("");
    let mut fun: ArcStr = arcstr::literal!("");
    (n, strs) = System::regex((inSymbol.clone()).clone(), (literal!("^([^(]*)[(]([^+]*[^+]*)[+][^)]*[)] *[[]0x[0-9a-fA-F]*[]]$")).clone(), 3, true, false);
    if n.clone() == 3 {
        let (__pa0, __pa1) = ::match_deref::match_deref! { match &(strs.clone()) {
            Deref @ metamodelica::List::Cons { head: _, tail: Deref @ metamodelica::List::Cons { head: __pa0, tail: Deref @ metamodelica::List::Cons { head: __pa1, tail: Deref @ metamodelica::List::Nil } } } => (__pa0.clone(), __pa1.clone()),
            _ => bail!("pattern mismatch"),
        } };
        so = __pa0.clone();
        fun = __pa1.clone();
        outSymbol = ({ let mut __mm_s = String::new(); __mm_s.push_str(&*so.clone()); __mm_s.push_str(&*literal!("(")); __mm_s.push_str(&*unmangle((fun.clone()).clone())?); __mm_s.push_str(&*literal!(")")); ArcStr::from(__mm_s) }).clone();
    } else {
        (n, strs) = System::regex((inSymbol.clone()).clone(), (literal!("^[0-9 ]*([A-Za-z0-9.]*) *0x[0-9a-fA-F]* ([A-Za-z0-9_]*) *[+] *[0-9]*$")).clone(), 3, true, false);
        if n.clone() == 3 {
            let (__pa3, __pa4) = ::match_deref::match_deref! { match &(strs.clone()) {
                Deref @ metamodelica::List::Cons { head: _, tail: Deref @ metamodelica::List::Cons { head: __pa3, tail: Deref @ metamodelica::List::Cons { head: __pa4, tail: Deref @ metamodelica::List::Nil } } } => (__pa3.clone(), __pa4.clone()),
                _ => bail!("pattern mismatch"),
            } };
            so = __pa3.clone();
            fun = __pa4.clone();
            outSymbol = ({ let mut __mm_s = String::new(); __mm_s.push_str(&*so.clone()); __mm_s.push_str(&*literal!("(")); __mm_s.push_str(&*unmangle((fun.clone()).clone())?); __mm_s.push_str(&*literal!(")")); ArcStr::from(__mm_s) }).clone();
        } else {
            outSymbol = (inSymbol.clone()).clone();
        }
    }
    Ok(outSymbol)
}

pub fn triggerStackOverflow() -> Result<()> {
    todo!(); // ExternalSection { decl: ExternalDecl { funcName: Some("mmc_do_stackoverflow"), lang: Some("C"), output_: None, args: Cons { head: CALL { function_: CREF_QUAL { name: "OpenModelica", subscripts: Nil, componentRef: CREF_IDENT { name: "threadData", subscripts: Nil } }, functionArgs: FUNCTIONARGS { args: Nil, argNames: Nil }, typeVars: Nil }, tail: Nil }, annotation_: Some(Annotation { elementArgs: Cons { head: MODIFICATION { finalPrefix: false, eachPrefix: NON_EACH, path: IDENT { name: "Documentation" }, modification: Some(Modification { elementArgLst: Cons { head: MODIFICATION { finalPrefix: false, eachPrefix: NON_EACH, path: IDENT { name: "info" }, modification: Some(Modification { elementArgLst: Nil, eqMod: EQMOD { exp: STRING { value: "<html>\n<p>Fakes a stack overflow (useful for debugging; forces earlier exit\nsince most functions do not catch stack overflow, and gives you a\nstacktrace of the position you triggered this from).</p>\n</html>" }, info: SourceInfo { fileName: "/projects/OpenModelica/OMCompiler/Compiler/Util/StackOverflow.mo", isReadOnly: false, lineNumberStart: 85, columnNumberStart: 93, lineNumberEnd: 89, columnNumberEnd: 8, lastModification: 0.0 } } }), comment: None, info: SourceInfo { fileName: "/projects/OpenModelica/OMCompiler/Compiler/Util/StackOverflow.mo", isReadOnly: false, lineNumberStart: 85, columnNumberStart: 89, lineNumberEnd: 89, columnNumberEnd: 8, lastModification: 0.0 } }, tail: Nil }, eqMod: NOMOD }), comment: None, info: SourceInfo { fileName: "/projects/OpenModelica/OMCompiler/Compiler/Util/StackOverflow.mo", isReadOnly: false, lineNumberStart: 85, columnNumberStart: 75, lineNumberEnd: 89, columnNumberEnd: 9, lastModification: 0.0 } }, tail: Nil } }) }, annotation: None }
    Ok(())
}

pub fn generateReadableMessage(mut numFrames: i32, mut numSkip: i32, mut delimiter: ArcStr) -> Result<ArcStr> {
    let mut r#str: ArcStr = arcstr::literal!("");
    setStacktraceMessages(numSkip.clone(), numFrames.clone());
    r#str = (getReadableMessage((delimiter.clone()).clone())?).clone();
    Ok(r#str)
}

pub fn getReadableMessage(mut delimiter: ArcStr) -> Result<ArcStr> {
    let mut r#str: ArcStr = arcstr::literal!("");
    r#str = stringDelimitList(readableStacktraceMessages()?, (delimiter.clone()).clone());
    Ok(r#str)
}

pub fn readableStacktraceMessages() -> Result<Arc<metamodelica::List<ArcStr>>> {
    let mut symbols: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
    let mut prev: ArcStr = literal!("");
    let mut n: i32 = 1;
    let mut prevN: i32 = 1;
    if Testsuite::isRunning()? {
        symbols = list![(literal!("[bt] [Symbols are not generated when running the test suite]")).clone()];
        return Ok(symbols.clone());
    }
    for mut symbol in &*({
        let mut __acc: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
        for mut s in (getStacktraceMessages()).into_iter().cloned() {
            let __x = stripAddresses((s.clone()).clone())?;
            __acc = cons(__x, __acc);
        }
        __acc.reverse()
    }) {
        let mut symbol = symbol.clone();
        if prev.clone() == literal!("") {
        } else if symbol.clone() != prev.clone() {
            symbols = metamodelica::cons(({ let mut __mm_s = String::new(); __mm_s.push_str(&*literal!("[bt] #")); __mm_s.push_str(&*ArcStr::from(::std::format!("{}", prevN.clone()))); __mm_s.push_str(&*if (n.clone() != prevN.clone()) {{ let mut __mm_s = String::new(); __mm_s.push_str(&*literal!("...")); __mm_s.push_str(&*ArcStr::from(::std::format!("{}", n.clone()))); ArcStr::from(__mm_s) }} else {literal!("")}); __mm_s.push_str(&*literal!(" ")); __mm_s.push_str(&*prev.clone()); ArcStr::from(__mm_s) }).clone(), symbols.clone());
            n = n.clone() + 1;
            prevN = n.clone();
        } else {
            n = n.clone() + 1;
        }
        prev = (symbol.clone()).clone();
    }
    symbols = metamodelica::cons(({ let mut __mm_s = String::new(); __mm_s.push_str(&*literal!("[bt] #")); __mm_s.push_str(&*ArcStr::from(::std::format!("{}", prevN.clone()))); __mm_s.push_str(&*if (n.clone() != prevN.clone()) {{ let mut __mm_s = String::new(); __mm_s.push_str(&*literal!("...")); __mm_s.push_str(&*ArcStr::from(::std::format!("{}", n.clone()))); ArcStr::from(__mm_s) }} else {literal!("")}); __mm_s.push_str(&*literal!(" ")); __mm_s.push_str(&*prev.clone()); ArcStr::from(__mm_s) }).clone(), symbols.clone());
    symbols = symbols.clone().reverse();
    Ok(symbols)
}

pub fn getStacktraceMessages() -> Arc<metamodelica::List<ArcStr>> {
    let mut symbols: Arc<metamodelica::List<ArcStr>> = metamodelica::nil();
    symbols
}

pub fn setStacktraceMessages(mut numSkip: i32, mut numFrames: i32) -> () {
    ()
}

pub fn hasStacktraceMessages() -> bool {
    let mut b: bool = false;
    b
}

pub fn clearStacktraceMessages() -> () {
    ()
}
