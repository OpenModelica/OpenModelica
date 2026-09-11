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

use metamodelica::Result;
use loop_unwrap::unwrap_break_err;
use metamodelica::*; // Built-in types and functions
use const_str;
use arcstr::{ArcStr, literal, format};

/// An identifier, for example a variable name
pub type Ident = ArcStr;

/// For Iterator - these are used in:
///   * for loops where the expression part can be NONE() and then the range
///     is taken from an array variable that the iterator is used to index,
///     see 3.3.3.2 Several Iterators from Modelica Specification.
///   * in array iterators where the expression should always be SOME(Exp),
///     see 3.4.4.2 Array constructor with iterators from Specification
///   * the guard is a MetaModelica extension; it's a Boolean expression that
///     filters out items in the range.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct ForIterator {
    pub name: ArcStr,
    pub guardExp: Option<metamodelica::Ref<Exp>>,
    pub range: Option<metamodelica::Ref<Exp>>,
}

impl metamodelica::gc::MMTrace for ForIterator {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.name, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.guardExp, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.range, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for ForIterator {
    // Absyn.ForIterator
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ForIterator {
    fn default() -> Self {
        Self {
            name: Default::default(),
            guardExp: Default::default(),
            range: Default::default(),
        }
    }
}

pub type ITERATOR = ForIterator;


/// For Iterators -
///   these are used in:
///   * for loops where the expression part can be NONE() and then the range
///     is taken from an array variable that the iterator is used to index,
///     see 3.3.3.2 Several Iterators from Modelica Specification.
///   * in array iterators where the expression should always be SOME(Exp),
///     see 3.4.4.2 Array constructor with iterators from Specification
pub type ForIterators = metamodelica::List<metamodelica::Ref<ForIterator>>;

/// - Programs, the top level construct
///   A program is simply a list of class definitions declared at top
///   level in the source file, combined with a within statement that
///   indicates the hieractical position of the program.
/// PROGRAM, the top level construct
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Program {
    /// List of classes
    pub classes: metamodelica::List<metamodelica::Ref<Class>>,
    /// Within clause
    pub within_: Within,
}

impl metamodelica::gc::MMTrace for Program {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.classes, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.within_, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Program {
    // Absyn.Program
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Program {
    fn default() -> Self {
        Self {
            classes: Default::default(),
            within_: Default::default(),
        }
    }
}

pub type PROGRAM = Program;


/// Within Clauses
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Within {
    /// the within clause
    WITHIN {
        /// the path for within
        path: metamodelica::Ref<Path>,
    },
    TOP,
}
impl metamodelica::gc::MMTrace for Within {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Within::WITHIN { path } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            Within::TOP => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Within {
    // Absyn.Within
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Within {
    fn default() -> Self { Self::TOP }
}
pub use self::Within::{WITHIN,TOP};

pub type Info = SourceInfo;

/// A class definition consists of a name, a flag to indicate
///  if this class is declared as partial, the declared class restriction,
///  and the body of the declaration.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Class {
    pub name: Ident,
    /// true if partial
    pub partialPrefix: bool,
    /// true if final
    pub finalPrefix: bool,
    /// true if encapsulated
    pub encapsulatedPrefix: bool,
    /// Restriction
    pub restriction: Restriction,
    pub body: metamodelica::Ref<ClassDef>,
    /// when a class is the first one in the file and has a comment before it
    pub commentsBeforeClass: metamodelica::List<ArcStr>,
    /// when a class has comments before its end
    pub commentsBeforeEnd: metamodelica::List<ArcStr>,
    /// when the class has comments after its end, before the next class or the end of the file
    pub commentsAfterEnd: metamodelica::List<ArcStr>,
    /// Information: FileName is the class is defined in +
    ///               isReadOnly bool + start line no + start column no +
    ///               end line no + end column no
    pub info: Info,
}

impl metamodelica::gc::MMTrace for Class {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.name, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.partialPrefix, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.finalPrefix, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.encapsulatedPrefix, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.restriction, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.body, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.commentsBeforeClass, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.commentsBeforeEnd, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.commentsAfterEnd, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.info, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Class {
    // Absyn.Class
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Class {
    fn default() -> Self {
        Self {
            name: Default::default(),
            partialPrefix: Default::default(),
            finalPrefix: Default::default(),
            encapsulatedPrefix: Default::default(),
            restriction: Default::default(),
            body: Default::default(),
            commentsBeforeClass: Default::default(),
            commentsBeforeEnd: Default::default(),
            commentsAfterEnd: Default::default(),
            info: Default::default(),
        }
    }
}

pub type CLASS = Class;


/// The ClassDef type contains thClasse definition part of a class declaration.
/// The definition is either explicit, with a list of parts
/// (public, protected, equation, and algorithm), or it is a definition
/// derived from another class or an enumeration type.
/// For a derived type, the  type contains the name of the derived class
/// and an optional array dimension and a list of modifications.
///
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ClassDef {
    PARTS {
        /// class A<B,C> ... has type variables B,C
        typeVars: metamodelica::List<ArcStr>,
        /// optimization Op (objective=...) end Op. A list arguments attributing a
        ///    class declaration. Currently used only for Optimica extensions
        classAttrs: metamodelica::List<metamodelica::Ref<NamedArg>>,
        classParts: metamodelica::List<metamodelica::Ref<ClassPart>>,
        /// Modelica2 allowed multiple class-annotations
        ann: metamodelica::List<metamodelica::Ref<Annotation>>,
        comment: Option<ArcStr>,
    },
    DERIVED {
        /// typeSpec specification includes array dimensions
        typeSpec: metamodelica::Ref<TypeSpec>,
        attributes: ElementAttributes,
        arguments: metamodelica::List<metamodelica::Ref<ElementArg>>,
        comment: Option<metamodelica::Ref<Comment>>,
    },
    ENUMERATION {
        enumLiterals: metamodelica::Ref<EnumDef>,
        comment: Option<metamodelica::Ref<Comment>>,
    },
    OVERLOAD {
        functionNames: metamodelica::List<metamodelica::Ref<Path>>,
        comment: Option<metamodelica::Ref<Comment>>,
    },
    CLASS_EXTENDS {
        /// name of class to extend
        baseClassName: Ident,
        /// modifications to be applied to the base class
        modifications: metamodelica::List<metamodelica::Ref<ElementArg>>,
        /// comment
        comment: Option<ArcStr>,
        /// class parts
        parts: metamodelica::List<metamodelica::Ref<ClassPart>>,
        ann: metamodelica::List<metamodelica::Ref<Annotation>>,
    },
    PDER {
        functionName: metamodelica::Ref<Path>,
        /// derived variables
        vars: metamodelica::List<ArcStr>,
        /// comment
        comment: Option<metamodelica::Ref<Comment>>,
    },
}
impl metamodelica::gc::MMTrace for ClassDef {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ClassDef::PARTS { typeVars, classAttrs, classParts, ann, comment } => {
                metamodelica::gc::MMTrace::mm_accept(typeVars, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(classAttrs, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(classParts, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(ann, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            ClassDef::DERIVED { typeSpec, attributes, arguments, comment } => {
                metamodelica::gc::MMTrace::mm_accept(typeSpec, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(attributes, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(arguments, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            ClassDef::ENUMERATION { enumLiterals, comment } => {
                metamodelica::gc::MMTrace::mm_accept(enumLiterals, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            ClassDef::OVERLOAD { functionNames, comment } => {
                metamodelica::gc::MMTrace::mm_accept(functionNames, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            ClassDef::CLASS_EXTENDS { baseClassName, modifications, comment, parts, ann } => {
                metamodelica::gc::MMTrace::mm_accept(baseClassName, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(modifications, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(parts, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(ann, __mmv)?;
                Ok(())
            }
            ClassDef::PDER { functionName, vars, comment } => {
                metamodelica::gc::MMTrace::mm_accept(functionName, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(vars, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for ClassDef {
    // Absyn.ClassDef
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ClassDef {
    fn default() -> Self {
        Self::ENUMERATION {
            enumLiterals: Default::default(),
            comment: Default::default(),
        }
    }
}
pub use self::ClassDef::{PARTS,DERIVED,ENUMERATION,OVERLOAD,CLASS_EXTENDS,PDER};

/// Component attributes are
///  properties of components which are applied by type prefixes.
///  As an example, declaring a component as `input Real x;\' will
///  give the attributes `ATTR({},false,VAR,INPUT)\'.
///  Components in Modelica can be scalar or arrays with one or more
///  dimensions. This type is used to indicate the dimensionality
///  of a component or a type definition.
/// - Array dimensions
pub type ArrayDim = metamodelica::List<metamodelica::Ref<Subscript>>;

/// ModExtension: new MetaModelica type specification!
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum TypeSpec {
    TPATH {
        path: metamodelica::Ref<Path>,
        arrayDim: Option<metamodelica::List<metamodelica::Ref<Subscript>>>,
    },
    TCOMPLEX {
        path: metamodelica::Ref<Path>,
        typeSpecs: metamodelica::List<metamodelica::Ref<TypeSpec>>,
        arrayDim: Option<metamodelica::List<metamodelica::Ref<Subscript>>>,
    },
}
impl metamodelica::gc::MMTrace for TypeSpec {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            TypeSpec::TPATH { path, arrayDim } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(arrayDim, __mmv)?;
                Ok(())
            }
            TypeSpec::TCOMPLEX { path, typeSpecs, arrayDim } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(typeSpecs, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(arrayDim, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for TypeSpec {
    // Absyn.TypeSpec
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for TypeSpec {
    fn default() -> Self {
        Self::TPATH {
            path: Default::default(),
            arrayDim: Default::default(),
        }
    }
}
pub use self::TypeSpec::{TPATH,TCOMPLEX};

/// The definition of an enumeration is either a list of literals
///     or a colon, \':\', which defines a supertype of all enumerations
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum EnumDef {
    ENUMLITERALS {
        enumLiterals: metamodelica::List<metamodelica::Ref<EnumLiteral>>,
    },
    ENUM_COLON,
}
impl metamodelica::gc::MMTrace for EnumDef {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            EnumDef::ENUMLITERALS { enumLiterals } => {
                metamodelica::gc::MMTrace::mm_accept(enumLiterals, __mmv)?;
                Ok(())
            }
            EnumDef::ENUM_COLON => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for EnumDef {
    // Absyn.EnumDef
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl EnumDef {
    pub fn interned_ENUM_COLON() -> metamodelica::Ref<EnumDef> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<EnumDef>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(EnumDef::ENUM_COLON));
        (*INTERNED).clone()
    }
}
pub fn interned_ENUM_COLON() -> metamodelica::Ref<EnumDef> { EnumDef::interned_ENUM_COLON() }
impl Default for EnumDef {
    fn default() -> Self { Self::ENUM_COLON }
}
pub use self::EnumDef::{ENUMLITERALS,ENUM_COLON};

/// EnumLiteral, which is a name in an enumeration and an optional
///   Comment.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct EnumLiteral {
    pub literal: Ident,
    pub comment: Option<metamodelica::Ref<Comment>>,
}

impl metamodelica::gc::MMTrace for EnumLiteral {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.literal, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.comment, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for EnumLiteral {
    // Absyn.EnumLiteral
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
pub type ENUMLITERAL = EnumLiteral;


/// A class definition contains several parts.  There are public and
///  protected component declarations, type definitions and `extends\'
///  clauses, collectively called elements.  There are also equation
///  sections and algorithm sections. The EXTERNAL part is used only by functions
///  which can be declared as external C or FORTRAN functions.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ClassPart {
    PUBLIC {
        contents: metamodelica::List<metamodelica::Ref<ElementItem>>,
    },
    PROTECTED {
        contents: metamodelica::List<metamodelica::Ref<ElementItem>>,
    },
    CONSTRAINTS {
        contents: metamodelica::List<metamodelica::Ref<Exp>>,
    },
    EQUATIONS {
        contents: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    INITIALEQUATIONS {
        contents: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    ALGORITHMS {
        contents: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    INITIALALGORITHMS {
        contents: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    EXTERNAL {
        /// externalDecl
        externalDecl: metamodelica::Ref<ExternalDecl>,
        /// annotation
        annotation_: Option<metamodelica::Ref<Annotation>>,
    },
}
impl metamodelica::gc::MMTrace for ClassPart {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ClassPart::PUBLIC { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::PROTECTED { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::CONSTRAINTS { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::EQUATIONS { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::INITIALEQUATIONS { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::ALGORITHMS { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::INITIALALGORITHMS { contents } => {
                metamodelica::gc::MMTrace::mm_accept(contents, __mmv)?;
                Ok(())
            }
            ClassPart::EXTERNAL { externalDecl, annotation_ } => {
                metamodelica::gc::MMTrace::mm_accept(externalDecl, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(annotation_, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for ClassPart {
    // Absyn.ClassPart
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ClassPart {
    fn default() -> Self {
        Self::PUBLIC {
            contents: Default::default(),
        }
    }
}
pub use self::ClassPart::{PUBLIC,PROTECTED,CONSTRAINTS,EQUATIONS,INITIALEQUATIONS,ALGORITHMS,INITIALALGORITHMS,EXTERNAL};

/// An element item is either an element or an annotation
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ElementItem {
    ELEMENTITEM {
        element: metamodelica::Ref<Element>,
    },
    LEXER_COMMENT {
        comment: ArcStr,
    },
}
impl metamodelica::gc::MMTrace for ElementItem {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ElementItem::ELEMENTITEM { element } => {
                metamodelica::gc::MMTrace::mm_accept(element, __mmv)?;
                Ok(())
            }
            ElementItem::LEXER_COMMENT { comment } => {
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for ElementItem {
    // Absyn.ElementItem
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ElementItem {
    fn default() -> Self {
        Self::ELEMENTITEM {
            element: Default::default(),
        }
    }
}
pub use self::ElementItem::{ELEMENTITEM,LEXER_COMMENT};

/// Elements
///  The basic element type in Modelica
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Element {
    ELEMENT {
        finalPrefix: bool,
        /// replaceable, redeclare
        redeclareKeywords: Option<RedeclareKeywords>,
        /// inner/outer
        innerOuter: InnerOuter,
        /// Actual element specification
        specification: metamodelica::Ref<ElementSpec>,
        /// File name the class is defined in + line no + column no
        info: Info,
        /// only valid for classdef and component
        constrainClass: Option<metamodelica::Ref<ConstrainClass>>,
    },
    DEFINEUNIT {
        name: Ident,
        args: metamodelica::List<metamodelica::Ref<NamedArg>>,
        info: Info,
    },
    TEXT {
        /// optName : optional name of text, e.g. model with syntax error.
        ///                                       We need the name to be able to browse it...
        optName: Option<ArcStr>,
        string: ArcStr,
        info: Info,
    },
}
impl metamodelica::gc::MMTrace for Element {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Element::ELEMENT { finalPrefix, redeclareKeywords, innerOuter, specification, info, constrainClass } => {
                metamodelica::gc::MMTrace::mm_accept(finalPrefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(redeclareKeywords, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(innerOuter, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(specification, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(constrainClass, __mmv)?;
                Ok(())
            }
            Element::DEFINEUNIT { name, args, info } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(args, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            Element::TEXT { optName, string, info } => {
                metamodelica::gc::MMTrace::mm_accept(optName, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(string, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Element {
    // Absyn.Element
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Element {
    fn default() -> Self {
        Self::DEFINEUNIT {
            name: Default::default(),
            args: Default::default(),
            info: Default::default(),
        }
    }
}
pub use self::Element::{ELEMENT,DEFINEUNIT,TEXT};

/// Constraining type, must be extends
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct ConstrainClass {
    /// must be extends
    pub elementSpec: metamodelica::Ref<ElementSpec>,
    /// comment
    pub comment: Option<metamodelica::Ref<Comment>>,
}

impl metamodelica::gc::MMTrace for ConstrainClass {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.elementSpec, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.comment, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for ConstrainClass {
    // Absyn.ConstrainClass
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ConstrainClass {
    fn default() -> Self {
        Self {
            elementSpec: Default::default(),
            comment: Default::default(),
        }
    }
}

pub type CONSTRAINCLASS = ConstrainClass;


/// An element is something that occurs in a public or protected
///    section in a class definition.  There is one constructor in the
///    `ElementSpec\' type for each possible element type.  There are
///    class definitions (`CLASSDEF\'), `extends\' clauses (`EXTENDS\')
///    and component declarations (`COMPONENTS\').
///
///    As an example, if the element `extends TwoPin;\' appears
///    in the source, it is represented in the AST as
///    `EXTENDS(IDENT(\"TwoPin\"),{})\'.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ElementSpec {
    CLASSDEF {
        /// replaceable
        replaceable_: bool,
        /// class
        class_: metamodelica::Ref<Class>,
    },
    EXTENDS {
        /// path
        path: metamodelica::Ref<Path>,
        /// elementArg
        elementArg: metamodelica::List<metamodelica::Ref<ElementArg>>,
        /// optional annotation
        annotationOpt: Option<metamodelica::Ref<Annotation>>,
    },
    IMPORT {
        /// import
        import_: Import,
        /// comment
        comment: Option<metamodelica::Ref<Comment>>,
        info: Info,
    },
    COMPONENTS {
        /// attributes
        attributes: ElementAttributes,
        /// typeSpec
        typeSpec: metamodelica::Ref<TypeSpec>,
        /// components
        components: metamodelica::List<metamodelica::Ref<ComponentItem>>,
    },
}
impl metamodelica::gc::MMTrace for ElementSpec {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ElementSpec::CLASSDEF { replaceable_, class_ } => {
                metamodelica::gc::MMTrace::mm_accept(replaceable_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(class_, __mmv)?;
                Ok(())
            }
            ElementSpec::EXTENDS { path, elementArg, annotationOpt } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elementArg, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(annotationOpt, __mmv)?;
                Ok(())
            }
            ElementSpec::IMPORT { import_, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(import_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            ElementSpec::COMPONENTS { attributes, typeSpec, components } => {
                metamodelica::gc::MMTrace::mm_accept(attributes, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(typeSpec, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(components, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for ElementSpec {
    // Absyn.ElementSpec
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ElementSpec {
    fn default() -> Self {
        Self::CLASSDEF {
            replaceable_: Default::default(),
            class_: Default::default(),
        }
    }
}
pub use self::ElementSpec::{CLASSDEF,EXTENDS,IMPORT,COMPONENTS};

/// One of the keyword inner and outer CAN be given to reference an
///   inner or outer element. Thus there are three disjoint possibilities.
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum InnerOuter {
    /// an inner prefix
    INNER,
    /// an outer prefix
    OUTER,
    /// an inner outer prefix
    INNER_OUTER,
    /// no inner outer prefix
    NOT_INNER_OUTER,
}
impl metamodelica::gc::MMTrace for InnerOuter {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            InnerOuter::INNER => Ok(()),
            InnerOuter::OUTER => Ok(()),
            InnerOuter::INNER_OUTER => Ok(()),
            InnerOuter::NOT_INNER_OUTER => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for InnerOuter {
    // Absyn.InnerOuter
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for InnerOuter {
    fn default() -> Self { Self::INNER }
}
pub use self::InnerOuter::{INNER,OUTER,INNER_OUTER,NOT_INNER_OUTER};

/// Import statements, different kinds
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Import {
    NAMED_IMPORT {
        /// name
        name: Ident,
        /// path
        path: metamodelica::Ref<Path>,
    },
    QUAL_IMPORT {
        /// path
        path: metamodelica::Ref<Path>,
    },
    UNQUAL_IMPORT {
        /// path
        path: metamodelica::Ref<Path>,
    },
    GROUP_IMPORT {
        prefix: metamodelica::Ref<Path>,
        groups: metamodelica::List<GroupImport>,
    },
}
impl metamodelica::gc::MMTrace for Import {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Import::NAMED_IMPORT { name, path } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            Import::QUAL_IMPORT { path } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            Import::UNQUAL_IMPORT { path } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            Import::GROUP_IMPORT { prefix, groups } => {
                metamodelica::gc::MMTrace::mm_accept(prefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(groups, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Import {
    // Absyn.Import
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Import {
    fn default() -> Self {
        Self::QUAL_IMPORT {
            path: Default::default(),
        }
    }
}
pub use self::Import::{NAMED_IMPORT,QUAL_IMPORT,UNQUAL_IMPORT,GROUP_IMPORT};

#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum GroupImport {
    GROUP_IMPORT_NAME {
        name: ArcStr,
    },
    GROUP_IMPORT_RENAME {
        rename: ArcStr,
        name: ArcStr,
    },
}
impl metamodelica::gc::MMTrace for GroupImport {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            GroupImport::GROUP_IMPORT_NAME { name } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                Ok(())
            }
            GroupImport::GROUP_IMPORT_RENAME { rename, name } => {
                metamodelica::gc::MMTrace::mm_accept(rename, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for GroupImport {
    // Absyn.GroupImport
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for GroupImport {
    fn default() -> Self {
        Self::GROUP_IMPORT_NAME {
            name: Default::default(),
        }
    }
}
pub use self::GroupImport::{GROUP_IMPORT_NAME,GROUP_IMPORT_RENAME};

/// A componentItem can have a condition that must be fulfilled if
///  the component should be instantiated.
pub type ComponentCondition = metamodelica::Ref<Exp>;

/// Collection of component and an optional comment
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct ComponentItem {
    /// component
    pub component: Component,
    /// condition
    pub condition: Option<metamodelica::Ref<Exp>>,
    /// comment
    pub comment: Option<metamodelica::Ref<Comment>>,
}

impl metamodelica::gc::MMTrace for ComponentItem {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.component, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.condition, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.comment, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for ComponentItem {
    // Absyn.ComponentItem
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ComponentItem {
    fn default() -> Self {
        Self {
            component: Default::default(),
            condition: Default::default(),
            comment: Default::default(),
        }
    }
}

pub type COMPONENTITEM = ComponentItem;


/// Some kind of Modelica entity (object or variable)
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Component {
    /// name
    pub name: Ident,
    /// Array dimensions, if any
    pub arrayDim: ArrayDim,
    /// Optional modification
    pub modification: Option<metamodelica::Ref<Modification>>,
}

impl metamodelica::gc::MMTrace for Component {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.name, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.arrayDim, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.modification, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Component {
    // Absyn.Component
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Component {
    fn default() -> Self {
        Self {
            name: Default::default(),
            arrayDim: Default::default(),
            modification: Default::default(),
        }
    }
}

pub type COMPONENT = Component;


/// Several component declarations can be grouped together in one
///  `ElementSpec\' by writing them on the same line in the source.
///  This type contains the information specific to one component.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum EquationItem {
    EQUATIONITEM {
        /// equation
        equation_: metamodelica::Ref<Equation>,
        /// comment
        comment: Option<metamodelica::Ref<Comment>>,
        /// line number
        info: Info,
    },
    EQUATIONITEMCOMMENT {
        comment: ArcStr,
    },
}
impl metamodelica::gc::MMTrace for EquationItem {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            EquationItem::EQUATIONITEM { equation_, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(equation_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            EquationItem::EQUATIONITEMCOMMENT { comment } => {
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for EquationItem {
    // Absyn.EquationItem
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for EquationItem {
    fn default() -> Self {
        Self::EQUATIONITEMCOMMENT {
            comment: Default::default(),
        }
    }
}
pub use self::EquationItem::{EQUATIONITEM,EQUATIONITEMCOMMENT};

/// Info specific for an algorithm item.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum AlgorithmItem {
    ALGORITHMITEM {
        /// algorithm
        algorithm_: metamodelica::Ref<Algorithm>,
        /// comment
        comment: Option<metamodelica::Ref<Comment>>,
        /// line number
        info: Info,
    },
    /// A comment from the lexer
    ALGORITHMITEMCOMMENT {
        comment: ArcStr,
    },
}
impl metamodelica::gc::MMTrace for AlgorithmItem {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            AlgorithmItem::ALGORITHMITEM { algorithm_, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(algorithm_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            AlgorithmItem::ALGORITHMITEMCOMMENT { comment } => {
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for AlgorithmItem {
    // Absyn.AlgorithmItem
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for AlgorithmItem {
    fn default() -> Self {
        Self::ALGORITHMITEMCOMMENT {
            comment: Default::default(),
        }
    }
}
pub use self::AlgorithmItem::{ALGORITHMITEM,ALGORITHMITEMCOMMENT};

/// Information on one (kind) of equation, different constructors for different
///     kinds of equations
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Equation {
    EQ_IF {
        /// Conditional expression
        ifExp: metamodelica::Ref<Exp>,
        /// true branch
        equationTrueItems: metamodelica::List<metamodelica::Ref<EquationItem>>,
        /// elseIfBranches
        elseIfBranches: metamodelica::List<(metamodelica::Ref<Exp>, metamodelica::List<metamodelica::Ref<EquationItem>>)>,
        /// equationElseItems Standard 2-side eqn
        equationElseItems: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    EQ_EQUALS {
        /// leftSide
        leftSide: metamodelica::Ref<Exp>,
        /// rightSide Connect stmt
        rightSide: metamodelica::Ref<Exp>,
    },
    EQ_PDE {
        /// leftSide
        leftSide: metamodelica::Ref<Exp>,
        /// rightSide Connect stmt
        rightSide: metamodelica::Ref<Exp>,
        /// domain for PDEs
        domain: metamodelica::Ref<ComponentRef>,
    },
    EQ_CONNECT {
        /// connector1
        connector1: metamodelica::Ref<ComponentRef>,
        /// connector2
        connector2: metamodelica::Ref<ComponentRef>,
    },
    EQ_FOR {
        iterators: ForIterators,
        /// forEquations
        forEquations: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    EQ_WHEN_E {
        /// whenExp
        whenExp: metamodelica::Ref<Exp>,
        /// whenEquations
        whenEquations: metamodelica::List<metamodelica::Ref<EquationItem>>,
        /// elseWhenEquations
        elseWhenEquations: metamodelica::List<(metamodelica::Ref<Exp>, metamodelica::List<metamodelica::Ref<EquationItem>>)>,
    },
    EQ_NORETCALL {
        /// functionName
        functionName: metamodelica::Ref<ComponentRef>,
        /// functionArgs; fcalls without return value
        functionArgs: metamodelica::Ref<FunctionArgs>,
    },
    EQ_FAILURE {
        equ: metamodelica::Ref<EquationItem>,
    },
}
impl metamodelica::gc::MMTrace for Equation {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Equation::EQ_IF { ifExp, equationTrueItems, elseIfBranches, equationElseItems } => {
                metamodelica::gc::MMTrace::mm_accept(ifExp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(equationTrueItems, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseIfBranches, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(equationElseItems, __mmv)?;
                Ok(())
            }
            Equation::EQ_EQUALS { leftSide, rightSide } => {
                metamodelica::gc::MMTrace::mm_accept(leftSide, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(rightSide, __mmv)?;
                Ok(())
            }
            Equation::EQ_PDE { leftSide, rightSide, domain } => {
                metamodelica::gc::MMTrace::mm_accept(leftSide, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(rightSide, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(domain, __mmv)?;
                Ok(())
            }
            Equation::EQ_CONNECT { connector1, connector2 } => {
                metamodelica::gc::MMTrace::mm_accept(connector1, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(connector2, __mmv)?;
                Ok(())
            }
            Equation::EQ_FOR { iterators, forEquations } => {
                metamodelica::gc::MMTrace::mm_accept(iterators, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(forEquations, __mmv)?;
                Ok(())
            }
            Equation::EQ_WHEN_E { whenExp, whenEquations, elseWhenEquations } => {
                metamodelica::gc::MMTrace::mm_accept(whenExp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(whenEquations, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseWhenEquations, __mmv)?;
                Ok(())
            }
            Equation::EQ_NORETCALL { functionName, functionArgs } => {
                metamodelica::gc::MMTrace::mm_accept(functionName, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(functionArgs, __mmv)?;
                Ok(())
            }
            Equation::EQ_FAILURE { equ } => {
                metamodelica::gc::MMTrace::mm_accept(equ, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Equation {
    // Absyn.Equation
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Equation {
    fn default() -> Self {
        Self::EQ_FAILURE {
            equ: Default::default(),
        }
    }
}
pub use self::Equation::{EQ_IF,EQ_EQUALS,EQ_PDE,EQ_CONNECT,EQ_FOR,EQ_WHEN_E,EQ_NORETCALL,EQ_FAILURE};

/// The Algorithm type describes one algorithm statement in an
///  algorithm section.  It does not describe a whole algorithm.  The
///  reason this type is named like this is that the name of the
///  grammar rule for algorithm statements is `algorithm\'.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Algorithm {
    ALG_ASSIGN {
        /// assignComponent
        assignComponent: metamodelica::Ref<Exp>,
        /// value
        value: metamodelica::Ref<Exp>,
    },
    ALG_IF {
        /// ifExp
        ifExp: metamodelica::Ref<Exp>,
        /// trueBranch
        trueBranch: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
        /// elseIfAlgorithmBranch
        elseIfAlgorithmBranch: metamodelica::List<(metamodelica::Ref<Exp>, metamodelica::List<metamodelica::Ref<AlgorithmItem>>)>,
        /// elseBranch
        elseBranch: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_FOR {
        iterators: ForIterators,
        /// forBody
        forBody: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_PARFOR {
        iterators: ForIterators,
        /// parallel for loop Body
        parforBody: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_WHILE {
        /// boolExpr
        boolExpr: metamodelica::Ref<Exp>,
        /// whileBody
        whileBody: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_WHEN_A {
        /// boolExpr
        boolExpr: metamodelica::Ref<Exp>,
        /// whenBody
        whenBody: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
        /// elseWhenAlgorithmBranch
        elseWhenAlgorithmBranch: metamodelica::List<(metamodelica::Ref<Exp>, metamodelica::List<metamodelica::Ref<AlgorithmItem>>)>,
    },
    ALG_NORETCALL {
        /// functionCall
        functionCall: metamodelica::Ref<ComponentRef>,
        /// functionArgs; general fcalls without return value
        functionArgs: metamodelica::Ref<FunctionArgs>,
    },
    ALG_RETURN,
    ALG_BREAK,
    ALG_FAILURE {
        equ: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_TRY {
        body: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
        elseBody: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    ALG_CONTINUE,
}
impl metamodelica::gc::MMTrace for Algorithm {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Algorithm::ALG_ASSIGN { assignComponent, value } => {
                metamodelica::gc::MMTrace::mm_accept(assignComponent, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(value, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_IF { ifExp, trueBranch, elseIfAlgorithmBranch, elseBranch } => {
                metamodelica::gc::MMTrace::mm_accept(ifExp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(trueBranch, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseIfAlgorithmBranch, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseBranch, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_FOR { iterators, forBody } => {
                metamodelica::gc::MMTrace::mm_accept(iterators, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(forBody, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_PARFOR { iterators, parforBody } => {
                metamodelica::gc::MMTrace::mm_accept(iterators, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(parforBody, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_WHILE { boolExpr, whileBody } => {
                metamodelica::gc::MMTrace::mm_accept(boolExpr, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(whileBody, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_WHEN_A { boolExpr, whenBody, elseWhenAlgorithmBranch } => {
                metamodelica::gc::MMTrace::mm_accept(boolExpr, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(whenBody, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseWhenAlgorithmBranch, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_NORETCALL { functionCall, functionArgs } => {
                metamodelica::gc::MMTrace::mm_accept(functionCall, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(functionArgs, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_RETURN => Ok(()),
            Algorithm::ALG_BREAK => Ok(()),
            Algorithm::ALG_FAILURE { equ } => {
                metamodelica::gc::MMTrace::mm_accept(equ, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_TRY { body, elseBody } => {
                metamodelica::gc::MMTrace::mm_accept(body, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseBody, __mmv)?;
                Ok(())
            }
            Algorithm::ALG_CONTINUE => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Algorithm {
    // Absyn.Algorithm
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Algorithm {
    pub fn interned_ALG_RETURN() -> metamodelica::Ref<Algorithm> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Algorithm>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Algorithm::ALG_RETURN));
        (*INTERNED).clone()
    }
    pub fn interned_ALG_BREAK() -> metamodelica::Ref<Algorithm> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Algorithm>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Algorithm::ALG_BREAK));
        (*INTERNED).clone()
    }
    pub fn interned_ALG_CONTINUE() -> metamodelica::Ref<Algorithm> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Algorithm>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Algorithm::ALG_CONTINUE));
        (*INTERNED).clone()
    }
}
pub fn interned_ALG_RETURN() -> metamodelica::Ref<Algorithm> { Algorithm::interned_ALG_RETURN() }
pub fn interned_ALG_BREAK() -> metamodelica::Ref<Algorithm> { Algorithm::interned_ALG_BREAK() }
pub fn interned_ALG_CONTINUE() -> metamodelica::Ref<Algorithm> { Algorithm::interned_ALG_CONTINUE() }
impl Default for Algorithm {
    fn default() -> Self { Self::ALG_RETURN }
}
pub use self::Algorithm::{ALG_ASSIGN,ALG_IF,ALG_FOR,ALG_PARFOR,ALG_WHILE,ALG_WHEN_A,ALG_NORETCALL,ALG_RETURN,ALG_BREAK,ALG_FAILURE,ALG_TRY,ALG_CONTINUE};

pub static emptyMod: std::sync::LazyLock<metamodelica::Ref<Modification>> = std::sync::LazyLock::new(|| { metamodelica::Ref::new(Modification { elementArgLst: metamodelica::nil(), eqMod: crate::Absyn::EqMod::interned_NOMOD() }) });

/// Modifications are described by the `Modification\' type.  There
///  are two forms of modifications: redeclarations and component
///  modifications.
///  - Modifications
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Modification {
    pub elementArgLst: metamodelica::List<metamodelica::Ref<ElementArg>>,
    pub eqMod: metamodelica::Ref<EqMod>,
}

impl metamodelica::gc::MMTrace for Modification {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.elementArgLst, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.eqMod, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Modification {
    // Absyn.Modification
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Modification {
    fn default() -> Self {
        Self {
            elementArgLst: Default::default(),
            eqMod: Default::default(),
        }
    }
}

pub type CLASSMOD = Modification;


#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum EqMod {
    NOMOD,
    EQMOD {
        exp: metamodelica::Ref<Exp>,
        info: Info,
    },
}
impl metamodelica::gc::MMTrace for EqMod {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            EqMod::NOMOD => Ok(()),
            EqMod::EQMOD { exp, info } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for EqMod {
    // Absyn.EqMod
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl EqMod {
    pub fn interned_NOMOD() -> metamodelica::Ref<EqMod> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<EqMod>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(EqMod::NOMOD));
        (*INTERNED).clone()
    }
}
pub fn interned_NOMOD() -> metamodelica::Ref<EqMod> { EqMod::interned_NOMOD() }
impl Default for EqMod {
    fn default() -> Self { Self::NOMOD }
}
pub use self::EqMod::{NOMOD,EQMOD};

/// Wrapper for things that modify elements, modifications and redeclarations
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ElementArg {
    MODIFICATION {
        /// final prefix
        finalPrefix: bool,
        /// each
        eachPrefix: Each,
        path: metamodelica::Ref<Path>,
        /// modification
        modification: Option<metamodelica::Ref<Modification>>,
        /// comment
        comment: Option<ArcStr>,
        info: Info,
    },
    REDECLARATION {
        /// final prefix
        finalPrefix: bool,
        /// redeclare  or replaceable
        redeclareKeywords: RedeclareKeywords,
        /// each prefix
        eachPrefix: Each,
        /// elementSpec
        elementSpec: metamodelica::Ref<ElementSpec>,
        /// class definition or declaration
        constrainClass: Option<metamodelica::Ref<ConstrainClass>>,
        /// needed because ElementSpec does not contain this info; Element does
        info: Info,
    },
    /// A lexer comment
    ELEMENTARGCOMMENT {
        comment: ArcStr,
    },
    /// break is either an ident or an equation
    ///    we save the ident as connect(ident, break) to keep it simple
    INHERITANCEBREAK {
        cnct: metamodelica::Ref<Equation>,
        info: Info,
    },
}
impl metamodelica::gc::MMTrace for ElementArg {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ElementArg::MODIFICATION { finalPrefix, eachPrefix, path, modification, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(finalPrefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(eachPrefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(modification, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            ElementArg::REDECLARATION { finalPrefix, redeclareKeywords, eachPrefix, elementSpec, constrainClass, info } => {
                metamodelica::gc::MMTrace::mm_accept(finalPrefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(redeclareKeywords, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(eachPrefix, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elementSpec, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(constrainClass, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            ElementArg::ELEMENTARGCOMMENT { comment } => {
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            ElementArg::INHERITANCEBREAK { cnct, info } => {
                metamodelica::gc::MMTrace::mm_accept(cnct, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for ElementArg {
    // Absyn.ElementArg
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ElementArg {
    fn default() -> Self {
        Self::ELEMENTARGCOMMENT {
            comment: Default::default(),
        }
    }
}
pub use self::ElementArg::{MODIFICATION,REDECLARATION,ELEMENTARGCOMMENT,INHERITANCEBREAK};

/// The keywords redeclare and replacable can be given in three different kombinations, each one by themself or the both combined.
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum RedeclareKeywords {
    REDECLARE,
    REPLACEABLE,
    REDECLARE_REPLACEABLE,
}
impl metamodelica::gc::MMTrace for RedeclareKeywords {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            RedeclareKeywords::REDECLARE => Ok(()),
            RedeclareKeywords::REPLACEABLE => Ok(()),
            RedeclareKeywords::REDECLARE_REPLACEABLE => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for RedeclareKeywords {
    // Absyn.RedeclareKeywords
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for RedeclareKeywords {
    fn default() -> Self { Self::REDECLARE }
}
pub use self::RedeclareKeywords::{REDECLARE,REPLACEABLE,REDECLARE_REPLACEABLE};

/// The each keyword can be present in both MODIFICATION\'s and REDECLARATION\'s.
///  - Each attribute
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Each {
    EACH,
    NON_EACH,
}
impl metamodelica::gc::MMTrace for Each {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Each::EACH => Ok(()),
            Each::NON_EACH => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Each {
    // Absyn.Each
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Each {
    fn default() -> Self { Self::EACH }
}
pub use self::Each::{EACH,NON_EACH};

/// Element attributes
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct ElementAttributes {
    /// flow
    pub flowPrefix: bool,
    /// stream
    pub streamPrefix: bool,
    /// for OpenCL/CUDA parglobal, parlocal ...
    pub parallelism: Parallelism,
    /// parameter, constant etc.
    pub variability: Variability,
    /// input/output
    pub direction: Direction,
    /// non-field / field
    pub isField: IsField,
    /// array dimensions
    pub arrayDim: ArrayDim,
}

impl metamodelica::gc::MMTrace for ElementAttributes {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.flowPrefix, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.streamPrefix, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.parallelism, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.variability, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.direction, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.isField, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.arrayDim, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for ElementAttributes {
    // Absyn.ElementAttributes
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ElementAttributes {
    fn default() -> Self {
        Self {
            flowPrefix: Default::default(),
            streamPrefix: Default::default(),
            parallelism: Default::default(),
            variability: Default::default(),
            direction: Default::default(),
            isField: Default::default(),
            arrayDim: Default::default(),
        }
    }
}

pub type ATTR = ElementAttributes;


/// Is field
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum IsField {
    /// variable is not a field
    NONFIELD,
    /// variable is a field
    FIELD,
}
impl metamodelica::gc::MMTrace for IsField {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            IsField::NONFIELD => Ok(()),
            IsField::FIELD => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for IsField {
    // Absyn.IsField
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for IsField {
    fn default() -> Self { Self::NONFIELD }
}
pub use self::IsField::{NONFIELD,FIELD};

/// Parallelism
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Parallelism {
    /// Global variables for CUDA and OpenCL
    PARGLOBAL,
    /// Shared for CUDA and local for OpenCL
    PARLOCAL,
    /// Non parallel/Normal variables
    NON_PARALLEL,
}
impl metamodelica::gc::MMTrace for Parallelism {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Parallelism::PARGLOBAL => Ok(()),
            Parallelism::PARLOCAL => Ok(()),
            Parallelism::NON_PARALLEL => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Parallelism {
    // Absyn.Parallelism
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Parallelism {
    fn default() -> Self { Self::PARGLOBAL }
}
pub use self::Parallelism::{PARGLOBAL,PARLOCAL,NON_PARALLEL};

#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub(crate) enum FlowStream {
    FLOW,
    STREAM,
    NOT_FLOW_STREAM,
}
impl metamodelica::gc::MMTrace for FlowStream {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            FlowStream::FLOW => Ok(()),
            FlowStream::STREAM => Ok(()),
            FlowStream::NOT_FLOW_STREAM => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for FlowStream {
    // Absyn.FlowStream
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
pub(crate) use self::FlowStream::{FLOW,STREAM,NOT_FLOW_STREAM};

/// Variability
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Variability {
    VAR,
    DISCRETE,
    PARAM,
    CONST,
}
impl metamodelica::gc::MMTrace for Variability {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Variability::VAR => Ok(()),
            Variability::DISCRETE => Ok(()),
            Variability::PARAM => Ok(()),
            Variability::CONST => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Variability {
    // Absyn.Variability
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Variability {
    fn default() -> Self { Self::VAR }
}
pub use self::Variability::{VAR,DISCRETE,PARAM,CONST};

/// Direction
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Direction {
    /// direction is input
    INPUT,
    /// direction is output
    OUTPUT,
    /// direction is not specified, neither input nor output
    BIDIR,
    /// direction is both input and output (OM extension; syntactic sugar for functions)
    INPUT_OUTPUT,
}
impl metamodelica::gc::MMTrace for Direction {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Direction::INPUT => Ok(()),
            Direction::OUTPUT => Ok(()),
            Direction::BIDIR => Ok(()),
            Direction::INPUT_OUTPUT => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Direction {
    // Absyn.Direction
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Direction {
    fn default() -> Self { Self::INPUT }
}
pub use self::Direction::{INPUT,OUTPUT,BIDIR,INPUT_OUTPUT};

/// The Exp uniontype is the container of a Modelica expression.
///  - Expressions
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Exp {
    INTEGER {
        value: i32,
    },
    REAL {
        /// String representation of a Real, in order to unparse without changing the user's display preference
        value: ArcStr,
    },
    CREF {
        componentRef: metamodelica::Ref<ComponentRef>,
    },
    STRING {
        value: ArcStr,
    },
    BOOL {
        value: bool,
    },
    /// Binary operations, e.g. a*b
    BINARY {
        exp1: metamodelica::Ref<Exp>,
        op: Operator,
        exp2: metamodelica::Ref<Exp>,
    },
    /// Unary operations, e.g. -(x), +(x)
    UNARY {
        /// op
        op: Operator,
        /// exp - any arithmetic expression
        exp: metamodelica::Ref<Exp>,
    },
    LBINARY {
        /// exp1
        exp1: metamodelica::Ref<Exp>,
        /// op
        op: Operator,
        exp2: metamodelica::Ref<Exp>,
    },
    /// Logical unary operations: not
    LUNARY {
        /// op
        op: Operator,
        /// exp - any logical or relation expression
        exp: metamodelica::Ref<Exp>,
    },
    RELATION {
        /// exp1
        exp1: metamodelica::Ref<Exp>,
        /// op
        op: Operator,
        exp2: metamodelica::Ref<Exp>,
    },
    /// If expressions
    IFEXP {
        /// ifExp
        ifExp: metamodelica::Ref<Exp>,
        /// trueBranch
        trueBranch: metamodelica::Ref<Exp>,
        /// elseBranch
        elseBranch: metamodelica::Ref<Exp>,
        /// elseIfBranch Function calls
        elseIfBranch: metamodelica::List<(metamodelica::Ref<Exp>, metamodelica::Ref<Exp>)>,
    },
    CALL {
        /// function
        function_: metamodelica::Ref<ComponentRef>,
        functionArgs: metamodelica::Ref<FunctionArgs>,
        typeVars: metamodelica::List<metamodelica::Ref<Path>>,
    },
    /// Partially evaluated function
    PARTEVALFUNCTION {
        /// function
        function_: metamodelica::Ref<ComponentRef>,
        functionArgs: metamodelica::Ref<FunctionArgs>,
    },
    /// Array construction using {, }, or array
    ARRAY {
        arrayExp: metamodelica::List<metamodelica::Ref<Exp>>,
    },
    /// Matrix construction using {, }
    MATRIX {
        matrix: metamodelica::List<metamodelica::List<metamodelica::Ref<Exp>>>,
    },
    /// Range expressions, e.g. 1:10 or 1:0.5:10
    RANGE {
        /// start
        start: metamodelica::Ref<Exp>,
        /// step
        step: Option<metamodelica::Ref<Exp>>,
        /// stop
        stop: metamodelica::Ref<Exp>,
    },
    /// Tuples used in function calls returning several values
    TUPLE {
        /// comma-separated expressions
        expressions: metamodelica::List<metamodelica::Ref<Exp>>,
    },
    /// array access operator for last element, e.g. a{end}:=1;
    END,
    /// Modelica AST Code constructors - OpenModelica extension
    CODE {
        code: metamodelica::Ref<CodeNode>,
    },
    /// as operator
    AS {
        /// only an id
        id: Ident,
        /// expression to bind to the id
        exp: metamodelica::Ref<Exp>,
    },
    /// list cons or :: operator
    CONS {
        /// head of the list
        head: metamodelica::Ref<Exp>,
        /// rest of the list
        rest: metamodelica::Ref<Exp>,
    },
    /// matchcontinue expression
    MATCHEXP {
        /// match or matchcontinue
        matchTy: MatchType,
        /// match expression of
        inputExp: metamodelica::Ref<Exp>,
        /// local declarations
        localDecls: metamodelica::List<metamodelica::Ref<ElementItem>>,
        /// case list + else in the end
        cases: metamodelica::List<metamodelica::Ref<Case>>,
        /// TODO: Remove this as it was removed from the grammar
        comment: Option<ArcStr>,
    },
    /// Part of MetaModelica extension
    LIST {
        exps: metamodelica::List<metamodelica::Ref<Exp>>,
    },
    /// exp.index
    DOT {
        exp: metamodelica::Ref<Exp>,
        index: metamodelica::Ref<Exp>,
    },
    EXPRESSIONCOMMENT {
        commentsBefore: metamodelica::List<ArcStr>,
        exp: metamodelica::Ref<Exp>,
        commentsAfter: metamodelica::List<ArcStr>,
    },
    SUBSCRIPTED_EXP {
        exp: metamodelica::Ref<Exp>,
        subscripts: metamodelica::List<metamodelica::Ref<Subscript>>,
    },
    BREAK,
}
impl metamodelica::gc::MMTrace for Exp {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Exp::INTEGER { value } => {
                metamodelica::gc::MMTrace::mm_accept(value, __mmv)?;
                Ok(())
            }
            Exp::REAL { value } => {
                metamodelica::gc::MMTrace::mm_accept(value, __mmv)?;
                Ok(())
            }
            Exp::CREF { componentRef } => {
                metamodelica::gc::MMTrace::mm_accept(componentRef, __mmv)?;
                Ok(())
            }
            Exp::STRING { value } => {
                metamodelica::gc::MMTrace::mm_accept(value, __mmv)?;
                Ok(())
            }
            Exp::BOOL { value } => {
                metamodelica::gc::MMTrace::mm_accept(value, __mmv)?;
                Ok(())
            }
            Exp::BINARY { exp1, op, exp2 } => {
                metamodelica::gc::MMTrace::mm_accept(exp1, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(op, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp2, __mmv)?;
                Ok(())
            }
            Exp::UNARY { op, exp } => {
                metamodelica::gc::MMTrace::mm_accept(op, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                Ok(())
            }
            Exp::LBINARY { exp1, op, exp2 } => {
                metamodelica::gc::MMTrace::mm_accept(exp1, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(op, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp2, __mmv)?;
                Ok(())
            }
            Exp::LUNARY { op, exp } => {
                metamodelica::gc::MMTrace::mm_accept(op, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                Ok(())
            }
            Exp::RELATION { exp1, op, exp2 } => {
                metamodelica::gc::MMTrace::mm_accept(exp1, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(op, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp2, __mmv)?;
                Ok(())
            }
            Exp::IFEXP { ifExp, trueBranch, elseBranch, elseIfBranch } => {
                metamodelica::gc::MMTrace::mm_accept(ifExp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(trueBranch, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseBranch, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(elseIfBranch, __mmv)?;
                Ok(())
            }
            Exp::CALL { function_, functionArgs, typeVars } => {
                metamodelica::gc::MMTrace::mm_accept(function_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(functionArgs, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(typeVars, __mmv)?;
                Ok(())
            }
            Exp::PARTEVALFUNCTION { function_, functionArgs } => {
                metamodelica::gc::MMTrace::mm_accept(function_, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(functionArgs, __mmv)?;
                Ok(())
            }
            Exp::ARRAY { arrayExp } => {
                metamodelica::gc::MMTrace::mm_accept(arrayExp, __mmv)?;
                Ok(())
            }
            Exp::MATRIX { matrix } => {
                metamodelica::gc::MMTrace::mm_accept(matrix, __mmv)?;
                Ok(())
            }
            Exp::RANGE { start, step, stop } => {
                metamodelica::gc::MMTrace::mm_accept(start, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(step, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(stop, __mmv)?;
                Ok(())
            }
            Exp::TUPLE { expressions } => {
                metamodelica::gc::MMTrace::mm_accept(expressions, __mmv)?;
                Ok(())
            }
            Exp::END => Ok(()),
            Exp::CODE { code } => {
                metamodelica::gc::MMTrace::mm_accept(code, __mmv)?;
                Ok(())
            }
            Exp::AS { id, exp } => {
                metamodelica::gc::MMTrace::mm_accept(id, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                Ok(())
            }
            Exp::CONS { head, rest } => {
                metamodelica::gc::MMTrace::mm_accept(head, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(rest, __mmv)?;
                Ok(())
            }
            Exp::MATCHEXP { matchTy, inputExp, localDecls, cases, comment } => {
                metamodelica::gc::MMTrace::mm_accept(matchTy, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(inputExp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(localDecls, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(cases, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                Ok(())
            }
            Exp::LIST { exps } => {
                metamodelica::gc::MMTrace::mm_accept(exps, __mmv)?;
                Ok(())
            }
            Exp::DOT { exp, index } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(index, __mmv)?;
                Ok(())
            }
            Exp::EXPRESSIONCOMMENT { commentsBefore, exp, commentsAfter } => {
                metamodelica::gc::MMTrace::mm_accept(commentsBefore, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(commentsAfter, __mmv)?;
                Ok(())
            }
            Exp::SUBSCRIPTED_EXP { exp, subscripts } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(subscripts, __mmv)?;
                Ok(())
            }
            Exp::BREAK => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Exp {
    // Absyn.Exp
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Exp {
    pub fn interned_END() -> metamodelica::Ref<Exp> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Exp>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Exp::END));
        (*INTERNED).clone()
    }
    pub fn interned_BREAK() -> metamodelica::Ref<Exp> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Exp>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Exp::BREAK));
        (*INTERNED).clone()
    }
}
pub fn interned_END() -> metamodelica::Ref<Exp> { Exp::interned_END() }
pub fn interned_BREAK() -> metamodelica::Ref<Exp> { Exp::interned_BREAK() }
impl Default for Exp {
    fn default() -> Self { Self::END }
}
pub use self::Exp::{INTEGER,REAL,CREF,STRING,BOOL,BINARY,UNARY,LBINARY,LUNARY,RELATION,IFEXP,CALL,PARTEVALFUNCTION,ARRAY,MATRIX,RANGE,TUPLE,END,CODE,AS,CONS,MATCHEXP,LIST,DOT,EXPRESSIONCOMMENT,SUBSCRIPTED_EXP,BREAK};

/// case in match or matchcontinue
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Case {
    CASE {
        /// patterns to be matched
        pattern: metamodelica::Ref<Exp>,
        patternGuard: Option<metamodelica::Ref<Exp>>,
        /// file information of the pattern
        patternInfo: Info,
        /// TODO: Remove this as it was removed from the grammar
        localDecls: metamodelica::List<metamodelica::Ref<ElementItem>>,
        /// equation or algorithm section
        classPart: metamodelica::Ref<ClassPart>,
        /// result
        result: metamodelica::Ref<Exp>,
        /// file information of the result-exp
        resultInfo: Info,
        /// TODO: Remove this as it was removed from the grammar
        comment: Option<ArcStr>,
        /// file information of the whole case
        info: Info,
    },
    /// else in match or matchcontinue
    ELSE {
        /// TODO: Remove this as it was removed from the grammar
        localDecls: metamodelica::List<metamodelica::Ref<ElementItem>>,
        /// equation or algorithm section
        classPart: metamodelica::Ref<ClassPart>,
        /// result
        result: metamodelica::Ref<Exp>,
        /// file information of the result-exp
        resultInfo: Info,
        /// TODO: Remove this as it was removed from the grammar
        comment: Option<ArcStr>,
        /// file information of the whole case
        info: Info,
    },
}
impl metamodelica::gc::MMTrace for Case {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Case::CASE { pattern, patternGuard, patternInfo, localDecls, classPart, result, resultInfo, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(pattern, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(patternGuard, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(patternInfo, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(localDecls, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(classPart, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(result, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(resultInfo, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            Case::ELSE { localDecls, classPart, result, resultInfo, comment, info } => {
                metamodelica::gc::MMTrace::mm_accept(localDecls, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(classPart, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(result, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(resultInfo, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(comment, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Case {
    // Absyn.Case
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Case {
    fn default() -> Self {
        Self::ELSE {
            localDecls: Default::default(),
            classPart: Default::default(),
            result: Default::default(),
            resultInfo: Default::default(),
            comment: Default::default(),
            info: Default::default(),
        }
    }
}
pub use self::Case::{CASE,ELSE};

#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum MatchType {
    MATCH,
    MATCHCONTINUE,
}
impl metamodelica::gc::MMTrace for MatchType {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            MatchType::MATCH => Ok(()),
            MatchType::MATCHCONTINUE => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for MatchType {
    // Absyn.MatchType
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for MatchType {
    fn default() -> Self { Self::MATCH }
}
pub use self::MatchType::{MATCH,MATCHCONTINUE};

/// The Code uniontype is used for Meta-programming. It originates from the $Code quoting mechanism. See paper in Modelica2003 conference
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum CodeNode {
    /// Cannot be parsed; used by Static for API calls
    C_TYPENAME {
        path: metamodelica::Ref<Path>,
    },
    /// Cannot be parsed; used by Static for API calls
    C_VARIABLENAME {
        componentRef: metamodelica::Ref<ComponentRef>,
    },
    C_CONSTRAINTSECTION {
        boolean: bool,
        equationItemLst: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    C_EQUATIONSECTION {
        boolean: bool,
        equationItemLst: metamodelica::List<metamodelica::Ref<EquationItem>>,
    },
    C_ALGORITHMSECTION {
        boolean: bool,
        algorithmItemLst: metamodelica::List<metamodelica::Ref<AlgorithmItem>>,
    },
    C_ELEMENT {
        element: metamodelica::Ref<Element>,
    },
    C_EXPRESSION {
        exp: metamodelica::Ref<Exp>,
    },
    C_MODIFICATION {
        modification: metamodelica::Ref<Modification>,
    },
}
impl metamodelica::gc::MMTrace for CodeNode {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            CodeNode::C_TYPENAME { path } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            CodeNode::C_VARIABLENAME { componentRef } => {
                metamodelica::gc::MMTrace::mm_accept(componentRef, __mmv)?;
                Ok(())
            }
            CodeNode::C_CONSTRAINTSECTION { boolean, equationItemLst } => {
                metamodelica::gc::MMTrace::mm_accept(boolean, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(equationItemLst, __mmv)?;
                Ok(())
            }
            CodeNode::C_EQUATIONSECTION { boolean, equationItemLst } => {
                metamodelica::gc::MMTrace::mm_accept(boolean, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(equationItemLst, __mmv)?;
                Ok(())
            }
            CodeNode::C_ALGORITHMSECTION { boolean, algorithmItemLst } => {
                metamodelica::gc::MMTrace::mm_accept(boolean, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(algorithmItemLst, __mmv)?;
                Ok(())
            }
            CodeNode::C_ELEMENT { element } => {
                metamodelica::gc::MMTrace::mm_accept(element, __mmv)?;
                Ok(())
            }
            CodeNode::C_EXPRESSION { exp } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                Ok(())
            }
            CodeNode::C_MODIFICATION { modification } => {
                metamodelica::gc::MMTrace::mm_accept(modification, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for CodeNode {
    // Absyn.CodeNode
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for CodeNode {
    fn default() -> Self {
        Self::C_TYPENAME {
            path: Default::default(),
        }
    }
}
pub use self::CodeNode::{C_TYPENAME,C_VARIABLENAME,C_CONSTRAINTSECTION,C_EQUATIONSECTION,C_ALGORITHMSECTION,C_ELEMENT,C_EXPRESSION,C_MODIFICATION};

/// The FunctionArgs uniontype consists of a list of positional arguments
///  followed by a list of named arguments (Modelica v2.0)
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum FunctionArgs {
    FUNCTIONARGS {
        /// args
        args: metamodelica::List<metamodelica::Ref<Exp>>,
        /// argNames
        argNames: metamodelica::List<metamodelica::Ref<NamedArg>>,
    },
    FOR_ITER_FARG {
        /// iterator expression
        exp: metamodelica::Ref<Exp>,
        iterType: ReductionIterType,
        iterators: ForIterators,
    },
}
impl metamodelica::gc::MMTrace for FunctionArgs {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            FunctionArgs::FUNCTIONARGS { args, argNames } => {
                metamodelica::gc::MMTrace::mm_accept(args, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(argNames, __mmv)?;
                Ok(())
            }
            FunctionArgs::FOR_ITER_FARG { exp, iterType, iterators } => {
                metamodelica::gc::MMTrace::mm_accept(exp, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(iterType, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(iterators, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for FunctionArgs {
    // Absyn.FunctionArgs
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for FunctionArgs {
    fn default() -> Self {
        Self::FUNCTIONARGS {
            args: Default::default(),
            argNames: Default::default(),
        }
    }
}
pub use self::FunctionArgs::{FUNCTIONARGS,FOR_ITER_FARG};

pub static emptyFunctionArgs: std::sync::LazyLock<metamodelica::Ref<FunctionArgs>> = std::sync::LazyLock::new(|| { metamodelica::Ref::new(FunctionArgs::FUNCTIONARGS { args: metamodelica::nil(), argNames: metamodelica::nil() }) });

#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ReductionIterType {
    /// Reductions are by default calculated as all combinations of the iterators
    COMBINE,
    /// With this option, all iterators must have the same length
    THREAD,
}
impl metamodelica::gc::MMTrace for ReductionIterType {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ReductionIterType::COMBINE => Ok(()),
            ReductionIterType::THREAD => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for ReductionIterType {
    // Absyn.ReductionIterType
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
pub use self::ReductionIterType::{COMBINE,THREAD};

/// The NamedArg uniontype consist of an Identifier for the argument and an expression
///  giving the value of the argument
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct NamedArg {
    /// argName
    pub argName: Ident,
    /// argValue
    pub argValue: metamodelica::Ref<Exp>,
}

impl metamodelica::gc::MMTrace for NamedArg {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.argName, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.argValue, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for NamedArg {
    // Absyn.NamedArg
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for NamedArg {
    fn default() -> Self {
        Self {
            argName: Default::default(),
            argValue: Default::default(),
        }
    }
}

pub type NAMEDARG = NamedArg;


/// Expression operators
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Operator {
    /// addition
    ADD,
    /// subtraction
    SUB,
    /// multiplication
    MUL,
    /// division
    DIV,
    /// power
    POW,
    /// unary plus
    UPLUS,
    /// unary minus
    UMINUS,
    /// element-wise addition
    ADD_EW,
    /// element-wise subtraction
    SUB_EW,
    /// element-wise multiplication
    MUL_EW,
    /// element-wise division
    DIV_EW,
    /// element-wise power
    POW_EW,
    /// element-wise unary minus
    UPLUS_EW,
    /// element-wise unary plus
    UMINUS_EW,
    /// logical and
    AND,
    /// logical or
    OR,
    /// logical not
    NOT,
    /// less than
    LESS,
    /// less than or equal
    LESSEQ,
    /// greater than
    GREATER,
    /// greater than or equal
    GREATEREQ,
    /// relational equal
    EQUAL,
    /// relational not equal
    NEQUAL,
}
impl metamodelica::gc::MMTrace for Operator {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Operator::ADD => Ok(()),
            Operator::SUB => Ok(()),
            Operator::MUL => Ok(()),
            Operator::DIV => Ok(()),
            Operator::POW => Ok(()),
            Operator::UPLUS => Ok(()),
            Operator::UMINUS => Ok(()),
            Operator::ADD_EW => Ok(()),
            Operator::SUB_EW => Ok(()),
            Operator::MUL_EW => Ok(()),
            Operator::DIV_EW => Ok(()),
            Operator::POW_EW => Ok(()),
            Operator::UPLUS_EW => Ok(()),
            Operator::UMINUS_EW => Ok(()),
            Operator::AND => Ok(()),
            Operator::OR => Ok(()),
            Operator::NOT => Ok(()),
            Operator::LESS => Ok(()),
            Operator::LESSEQ => Ok(()),
            Operator::GREATER => Ok(()),
            Operator::GREATEREQ => Ok(()),
            Operator::EQUAL => Ok(()),
            Operator::NEQUAL => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Operator {
    // Absyn.Operator
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Operator {
    fn default() -> Self { Self::ADD }
}
pub use self::Operator::{ADD,SUB,MUL,DIV,POW,UPLUS,UMINUS,ADD_EW,SUB_EW,MUL_EW,DIV_EW,POW_EW,UPLUS_EW,UMINUS_EW,AND,OR,NOT,LESS,LESSEQ,GREATER,GREATEREQ,EQUAL,NEQUAL};

/// The Subscript uniontype is used both in array declarations and
///  component references.  This might seem strange, but it is
///  inherited from the grammar.  The NOSUB constructor means that
///  the dimension size is undefined when used in a declaration, and
///  when it is used in a component reference it means a slice of the
///  whole dimension.
///  - Subscripts
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Subscript {
    /// unknown array dimension
    NOSUB,
    /// dimension as an expression
    SUBSCRIPT {
        /// subscript
        subscript: metamodelica::Ref<Exp>,
    },
}
impl metamodelica::gc::MMTrace for Subscript {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Subscript::NOSUB => Ok(()),
            Subscript::SUBSCRIPT { subscript } => {
                metamodelica::gc::MMTrace::mm_accept(subscript, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Subscript {
    // Absyn.Subscript
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Subscript {
    pub fn interned_NOSUB() -> metamodelica::Ref<Subscript> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<Subscript>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(Subscript::NOSUB));
        (*INTERNED).clone()
    }
}
pub fn interned_NOSUB() -> metamodelica::Ref<Subscript> { Subscript::interned_NOSUB() }
impl Default for Subscript {
    fn default() -> Self { Self::NOSUB }
}
pub use self::Subscript::{NOSUB,SUBSCRIPT};

/// A component reference is the fully or partially qualified name of
///  a component.  It is represented as a list of
///  identifier--subscript pairs.
///  - Component references and paths
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum ComponentRef {
    CREF_FULLYQUALIFIED {
        componentRef: metamodelica::Ref<ComponentRef>,
    },
    CREF_QUAL {
        /// name
        name: Ident,
        /// subscripts
        subscripts: metamodelica::List<metamodelica::Ref<Subscript>>,
        /// componentRef
        componentRef: metamodelica::Ref<ComponentRef>,
    },
    CREF_IDENT {
        /// name
        name: Ident,
        /// subscripts
        subscripts: metamodelica::List<metamodelica::Ref<Subscript>>,
    },
    WILD,
    ALLWILD,
}
impl metamodelica::gc::MMTrace for ComponentRef {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            ComponentRef::CREF_FULLYQUALIFIED { componentRef } => {
                metamodelica::gc::MMTrace::mm_accept(componentRef, __mmv)?;
                Ok(())
            }
            ComponentRef::CREF_QUAL { name, subscripts, componentRef } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(subscripts, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(componentRef, __mmv)?;
                Ok(())
            }
            ComponentRef::CREF_IDENT { name, subscripts } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(subscripts, __mmv)?;
                Ok(())
            }
            ComponentRef::WILD => Ok(()),
            ComponentRef::ALLWILD => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for ComponentRef {
    // Absyn.ComponentRef
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl ComponentRef {
    pub fn interned_WILD() -> metamodelica::Ref<ComponentRef> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<ComponentRef>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(ComponentRef::WILD));
        (*INTERNED).clone()
    }
    pub fn interned_ALLWILD() -> metamodelica::Ref<ComponentRef> {
        static INTERNED: std::sync::LazyLock<metamodelica::Ref<ComponentRef>> = std::sync::LazyLock::new(|| metamodelica::Ref::new(ComponentRef::ALLWILD));
        (*INTERNED).clone()
    }
}
pub fn interned_WILD() -> metamodelica::Ref<ComponentRef> { ComponentRef::interned_WILD() }
pub fn interned_ALLWILD() -> metamodelica::Ref<ComponentRef> { ComponentRef::interned_ALLWILD() }
impl Default for ComponentRef {
    fn default() -> Self { Self::WILD }
}
pub use self::ComponentRef::{CREF_FULLYQUALIFIED,CREF_QUAL,CREF_IDENT,WILD,ALLWILD};

/// The type `Path\', on the other hand,
///  is used to store references to class names, or names inside
///  class definitions.
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Path {
    QUALIFIED {
        /// name
        name: Ident,
        /// path
        path: metamodelica::Ref<Path>,
    },
    IDENT {
        /// name
        name: Ident,
    },
    /// Used during instantiation for names that are fully qualified,
    ///    i.e. the names are looked up from top scope directly like for instance Modelica.SIunits.Voltage
    ///    Note: Not created during parsing, only during instantation to speedup/simplify lookup.
    ///
    FULLYQUALIFIED {
        path: metamodelica::Ref<Path>,
    },
}
impl metamodelica::gc::MMTrace for Path {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Path::QUALIFIED { name, path } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
            Path::IDENT { name } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                Ok(())
            }
            Path::FULLYQUALIFIED { path } => {
                metamodelica::gc::MMTrace::mm_accept(path, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Path {
    // Absyn.Path
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Path {
    fn default() -> Self {
        Self::IDENT {
            name: Default::default(),
        }
    }
}
pub use self::Path::{QUALIFIED,IDENT,FULLYQUALIFIED};

/// These constructors each correspond to a different kind of class
///  declaration in Modelica, except the last four, which are used
///  for the predefined types.  The parser assigns each class
///  declaration one of the restrictions, and the actual class
///  definition is checked for conformance during translation.  The
///  predefined types are created in the Builtin module and are
///  assigned special restrictions.
///
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Restriction {
    R_CLASS,
    R_OPTIMIZATION,
    R_MODEL,
    R_RECORD,
    R_BLOCK,
    /// connector class
    R_CONNECTOR,
    /// expandable connector class
    R_EXP_CONNECTOR,
    R_TYPE,
    R_PACKAGE,
    R_FUNCTION {
        functionRestriction: FunctionRestriction,
    },
    /// an operator
    R_OPERATOR,
    /// an operator record
    R_OPERATOR_RECORD,
    R_ENUMERATION,
    R_PREDEFINED_INTEGER,
    R_PREDEFINED_REAL,
    R_PREDEFINED_STRING,
    R_PREDEFINED_BOOLEAN,
    R_PREDEFINED_ENUMERATION,
    R_PREDEFINED_CLOCK,
    /// MetaModelica uniontype
    R_UNIONTYPE,
    /// Metamodelica record
    R_METARECORD {
        name: metamodelica::Ref<Path>,
        index: i32,
        singleton: bool,
        moved: bool,
        typeVars: metamodelica::List<ArcStr>,
    },
    /// Helper restriction
    R_UNKNOWN,
}
impl metamodelica::gc::MMTrace for Restriction {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Restriction::R_CLASS => Ok(()),
            Restriction::R_OPTIMIZATION => Ok(()),
            Restriction::R_MODEL => Ok(()),
            Restriction::R_RECORD => Ok(()),
            Restriction::R_BLOCK => Ok(()),
            Restriction::R_CONNECTOR => Ok(()),
            Restriction::R_EXP_CONNECTOR => Ok(()),
            Restriction::R_TYPE => Ok(()),
            Restriction::R_PACKAGE => Ok(()),
            Restriction::R_FUNCTION { functionRestriction } => {
                metamodelica::gc::MMTrace::mm_accept(functionRestriction, __mmv)?;
                Ok(())
            }
            Restriction::R_OPERATOR => Ok(()),
            Restriction::R_OPERATOR_RECORD => Ok(()),
            Restriction::R_ENUMERATION => Ok(()),
            Restriction::R_PREDEFINED_INTEGER => Ok(()),
            Restriction::R_PREDEFINED_REAL => Ok(()),
            Restriction::R_PREDEFINED_STRING => Ok(()),
            Restriction::R_PREDEFINED_BOOLEAN => Ok(()),
            Restriction::R_PREDEFINED_ENUMERATION => Ok(()),
            Restriction::R_PREDEFINED_CLOCK => Ok(()),
            Restriction::R_UNIONTYPE => Ok(()),
            Restriction::R_METARECORD { name, index, singleton, moved, typeVars } => {
                metamodelica::gc::MMTrace::mm_accept(name, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(index, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(singleton, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(moved, __mmv)?;
                metamodelica::gc::MMTrace::mm_accept(typeVars, __mmv)?;
                Ok(())
            }
            Restriction::R_UNKNOWN => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Restriction {
    // Absyn.Restriction
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Restriction {
    fn default() -> Self { Self::R_CLASS }
}
pub use self::Restriction::{R_CLASS,R_OPTIMIZATION,R_MODEL,R_RECORD,R_BLOCK,R_CONNECTOR,R_EXP_CONNECTOR,R_TYPE,R_PACKAGE,R_FUNCTION,R_OPERATOR,R_OPERATOR_RECORD,R_ENUMERATION,R_PREDEFINED_INTEGER,R_PREDEFINED_REAL,R_PREDEFINED_STRING,R_PREDEFINED_BOOLEAN,R_PREDEFINED_ENUMERATION,R_PREDEFINED_CLOCK,R_UNIONTYPE,R_METARECORD,R_UNKNOWN};

/// function purity
#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum FunctionPurity {
    PURE,
    IMPURE,
    NO_PURITY,
}
impl metamodelica::gc::MMTrace for FunctionPurity {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            FunctionPurity::PURE => Ok(()),
            FunctionPurity::IMPURE => Ok(()),
            FunctionPurity::NO_PURITY => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for FunctionPurity {
    // Absyn.FunctionPurity
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for FunctionPurity {
    fn default() -> Self { Self::PURE }
}
pub use self::FunctionPurity::{PURE,IMPURE,NO_PURITY};

#[derive(Clone, Copy, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum FunctionRestriction {
    /// a normal function
    FR_NORMAL_FUNCTION {
        /// function purity
        purity: FunctionPurity,
    },
    /// an operator function
    FR_OPERATOR_FUNCTION,
    /// an OpenCL/CUDA parallel/device function
    FR_PARALLEL_FUNCTION,
    /// an OpenCL/CUDA kernel function
    FR_KERNEL_FUNCTION,
}
impl metamodelica::gc::MMTrace for FunctionRestriction {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            FunctionRestriction::FR_NORMAL_FUNCTION { purity } => {
                metamodelica::gc::MMTrace::mm_accept(purity, __mmv)?;
                Ok(())
            }
            FunctionRestriction::FR_OPERATOR_FUNCTION => Ok(()),
            FunctionRestriction::FR_PARALLEL_FUNCTION => Ok(()),
            FunctionRestriction::FR_KERNEL_FUNCTION => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for FunctionRestriction {
    // Absyn.FunctionRestriction
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
pub use self::FunctionRestriction::{FR_NORMAL_FUNCTION,FR_OPERATOR_FUNCTION,FR_PARALLEL_FUNCTION,FR_KERNEL_FUNCTION};

/// An Annotation is a class_modification.
///  - Annotation
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Annotation {
    /// elementArgs
    pub elementArgs: metamodelica::List<metamodelica::Ref<ElementArg>>,
}

impl metamodelica::gc::MMTrace for Annotation {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.elementArgs, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Annotation {
    // Absyn.Annotation
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Annotation {
    fn default() -> Self {
        Self {
            elementArgs: Default::default(),
        }
    }
}

pub type ANNOTATION = Annotation;


/// Comment
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct Comment {
    /// annotation
    pub annotation_: Option<metamodelica::Ref<Annotation>>,
    /// comment
    pub comment: Option<ArcStr>,
}

impl metamodelica::gc::MMTrace for Comment {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.annotation_, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.comment, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for Comment {
    // Absyn.Comment
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Comment {
    fn default() -> Self {
        Self {
            annotation_: Default::default(),
            comment: Default::default(),
        }
    }
}

pub type COMMENT = Comment;


/// Declaration of an external function call - ExternalDecl
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub struct ExternalDecl {
    /// The name of the external function
    pub funcName: Option<ArcStr>,
    /// Language of the external function
    pub lang: Option<ArcStr>,
    /// output parameter as return value
    pub output_: Option<metamodelica::Ref<ComponentRef>>,
    /// only positional arguments, i.e. expression list
    pub args: metamodelica::List<metamodelica::Ref<Exp>>,
    pub annotation_: Option<metamodelica::Ref<Annotation>>,
}

impl metamodelica::gc::MMTrace for ExternalDecl {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        metamodelica::gc::MMTrace::mm_accept(&self.funcName, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.lang, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.output_, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.args, __mmv)?;
        metamodelica::gc::MMTrace::mm_accept(&self.annotation_, __mmv)?;
        Ok(())
    }
}
impl metamodelica::mmval::MmVal for ExternalDecl {
    // Absyn.ExternalDecl
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for ExternalDecl {
    fn default() -> Self {
        Self {
            funcName: Default::default(),
            lang: Default::default(),
            output_: Default::default(),
            args: Default::default(),
            annotation_: Default::default(),
        }
    }
}

pub type EXTERNALDECL = ExternalDecl;


#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Ref {
    RCR {
        cr: metamodelica::Ref<ComponentRef>,
    },
    RTS {
        ts: metamodelica::Ref<TypeSpec>,
    },
    RIM {
        im: Import,
    },
}
impl metamodelica::gc::MMTrace for Ref {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Ref::RCR { cr } => {
                metamodelica::gc::MMTrace::mm_accept(cr, __mmv)?;
                Ok(())
            }
            Ref::RTS { ts } => {
                metamodelica::gc::MMTrace::mm_accept(ts, __mmv)?;
                Ok(())
            }
            Ref::RIM { im } => {
                metamodelica::gc::MMTrace::mm_accept(im, __mmv)?;
                Ok(())
            }
        }
    }
}
impl metamodelica::mmval::MmVal for Ref {
    // Absyn.Ref
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
pub use self::Ref::{RCR,RTS,RIM};

/// Controls output of error-messages
#[derive(Clone, Debug, Eq, Hash, metamodelica::MMCtor, metamodelica::MetaCmp, metamodelica::ReferenceEq)]
pub enum Msg {
    /// Give error message
    MSG {
        info: Info,
    },
    /// Do not give error message
    NO_MSG,
}
impl metamodelica::gc::MMTrace for Msg {
    fn mm_accept(&self, __mmv: &mut dyn metamodelica::gc::MMVisitor) -> Result<(), ()> {
        match self {
            Msg::MSG { info } => {
                metamodelica::gc::MMTrace::mm_accept(info, __mmv)?;
                Ok(())
            }
            Msg::NO_MSG => Ok(()),
        }
    }
}
impl metamodelica::mmval::MmVal for Msg {
    // Absyn.Msg
    type Traced = metamodelica::mmval::No;
    fn mm_accept<__V: metamodelica::mmval::Visitor>(&self, __mmv: &mut __V) -> Result<(), ()> {
        let _ = __mmv;
        Ok(())
    }
}
impl Default for Msg {
    fn default() -> Self { Self::NO_MSG }
}
pub use self::Msg::{MSG,NO_MSG};

pub static dummyParts: std::sync::LazyLock<metamodelica::Ref<ClassDef>> = std::sync::LazyLock::new(|| { metamodelica::Ref::new(ClassDef::PARTS { typeVars: metamodelica::nil(), classAttrs: metamodelica::nil(), classParts: metamodelica::nil(), ann: metamodelica::nil(), comment: None }) });

pub static dummyInfo: SourceInfo = SourceInfo { fileName: literal!(""), isReadOnly: false, lineNumberStart: 0, columnNumberStart: 0, lineNumberEnd: 0, columnNumberEnd: 0, lastModification: metamodelica::OrderedFloat(0.0_f64) };

pub static dummyProgram: std::sync::LazyLock<Program> = std::sync::LazyLock::new(|| { Program { classes: metamodelica::nil(), within_: crate::Absyn::Within::TOP } });

