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

/// severity of message
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Severity {
    /// Error because of a failure in the tool
    INTERNAL,
    /// Error when tool can not succeed in translation because of a user error
    ERROR,
    /// Warning when tool succeeds but with warning
    WARNING,
    /// Additional information to user, e.g. what
    ///             actions tool has taken to succeed in translation
    NOTIFICATION,
}
impl metamodelica::gc::MMTrace for Severity {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Severity::INTERNAL => Ok(()),
            Severity::ERROR => Ok(()),
            Severity::WARNING => Ok(()),
            Severity::NOTIFICATION => Ok(()),
        }
    }
}
impl Default for Severity {
    fn default() -> Self { Self::INTERNAL }
}
pub use self::Severity::{INTERNAL,ERROR,WARNING,NOTIFICATION};

/// runtime scripting /interpretation error
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum MessageType {
    /// syntax errors
    SYNTAX,
    /// grammar errors
    GRAMMAR,
    /// instantiation errors: up to
    ///           flat modelica
    TRANSLATION,
    /// Symbolic manipulation error,
    ///           simcodegen, up to .exe file
    SYMBOLIC,
    /// Runtime simulation error
    SIMULATION,
    /// runtime scripting /interpretation error
    SCRIPTING,
}
impl metamodelica::gc::MMTrace for MessageType {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            MessageType::SYNTAX => Ok(()),
            MessageType::GRAMMAR => Ok(()),
            MessageType::TRANSLATION => Ok(()),
            MessageType::SYMBOLIC => Ok(()),
            MessageType::SIMULATION => Ok(()),
            MessageType::SCRIPTING => Ok(()),
        }
    }
}
impl Default for MessageType {
    fn default() -> Self { Self::SYNTAX }
}
pub use self::MessageType::{SYNTAX,GRAMMAR,TRANSLATION,SYMBOLIC,SIMULATION,SCRIPTING};

/// Unique error id. Used to
///        look up message string and type and severity
pub type ErrorID = i32;

#[derive(Clone, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Message {
    pub id: ErrorID,
    pub ty: MessageType,
    pub severity: Severity,
    pub message: ArcStr,
}

impl metamodelica::gc::MMTrace for Message {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.id, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.ty, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.severity, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.message, __mmv)?;
        Ok(())
    }
}
impl Default for Message {
    fn default() -> Self {
        Self {
            id: Default::default(),
            ty: Default::default(),
            severity: Default::default(),
            message: Default::default(),
        }
    }
}

pub type MESSAGE = Message;


#[derive(Clone, Debug, Eq, Hash, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct TotalMessage {
    pub msg: Message,
    pub info: SourceInfo,
}

impl metamodelica::gc::MMTrace for TotalMessage {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.msg, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.info, __mmv)?;
        Ok(())
    }
}
pub type TOTALMESSAGE = TotalMessage;


/// \"Tokens\" to insert into message at
///            positions identified by
///            - %s for string
///            - %n for string number n
pub type MessageTokens = Arc<metamodelica::List<ArcStr>>;

