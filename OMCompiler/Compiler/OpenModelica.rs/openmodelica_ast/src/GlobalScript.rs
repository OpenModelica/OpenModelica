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

use crate::Absyn;

/// An Statement given in the interactive environment can either be
/// an Algorithm statement or an expression.
/// - GlobalScript.Statement
#[derive(Clone, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Statement {
    IALG {
        algItem: Arc<Absyn::AlgorithmItem>,
    },
    IEXP {
        exp: Arc<Absyn::Exp>,
        info: SourceInfo,
    },
}
impl metamodelica::gc::MMTrace for Statement {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Statement::IALG { algItem } => {
                metamodelica::gc::MMTrace::mm_accept(algItem, __mmv)?;
                Ok(())
            }
            Statement::IEXP { exp, info } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
        }
    }
}
impl Default for Statement {
    fn default() -> Self {
        Self::IALG {
            algItem: Default::default(),
        }
    }
}
pub use self::Statement::{IALG,IEXP};

/// Several interactive statements are used in Modelica scripts.
///  - GlobalScript.Statements
#[derive(Clone, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Statements {
    /// interactiveStmtLst
    pub interactiveStmtLst: Arc<metamodelica::List<Statement>>,
    /// semicolon; true = statement ending with a semicolon. The result will not be shown in the interactive environment.
    pub semicolon: bool,
}

impl metamodelica::gc::MMTrace for Statements {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.interactiveStmtLst, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.semicolon, __mmv)?;
        Ok(())
    }
}
impl Default for Statements {
    fn default() -> Self {
        Self {
            interactiveStmtLst: Default::default(),
            semicolon: Default::default(),
        }
    }
}

pub type ISTMTS = Statements;


