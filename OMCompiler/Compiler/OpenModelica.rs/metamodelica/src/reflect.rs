//! A read-only view of MetaModelica values for foreign callers, derived with
//! `#[derive(MMReflect)]`. A record or uniontype value is a [`Node`]; its
//! fields are converted one level deep on request, so a caller walks a value
//! graph lazily and never follows a cycle it does not ask for.

use crate::{Array, List, Real, SourceInfo};
use arcstr::ArcStr;
use std::sync::Arc;

pub use metamodelica_derive::MMReflect;

pub type Node = Arc<dyn MMReflect>;

pub trait MMReflect: AsAny {
    fn mm_type_name(&self) -> &'static str;
    fn mm_ctor_name(&self) -> &'static str;
    fn mm_field_names(&self) -> &'static [&'static str];
    fn mm_field(&self, i: usize) -> Option<MMField>;
}

/// Lets a caller holding a [`Node`] get the concrete value back.
pub trait AsAny: 'static {
    fn as_any(&self) -> &dyn std::any::Any;
}

impl<T: 'static> AsAny for T {
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
}

/// A clone of the value behind `n` if it is a `T`.
pub fn downcast<T: Clone + 'static>(n: &Node) -> Option<Arc<T>> {
    (**n).as_any().downcast_ref::<T>().map(|v| Arc::new(v.clone()))
}

#[derive(Clone)]
pub enum MMField {
    Integer(i64),
    Real(f64),
    Boolean(bool),
    String(ArcStr),
    Enum {
        type_name: &'static str,
        literal: &'static str,
        index: i32,
    },
    Node(Node),
    List(Vec<MMField>),
    Array(Vec<MMField>),
    Tuple(Vec<MMField>),
    Option(Option<Box<MMField>>),
    /// A value of a type without a view; the payload is its Rust type name.
    Opaque(&'static str),
}

pub trait ToMMField {
    fn to_mm_field(&self) -> MMField;
}

impl ToMMField for i32 {
    fn to_mm_field(&self) -> MMField {
        MMField::Integer(*self as i64)
    }
}

impl ToMMField for i64 {
    fn to_mm_field(&self) -> MMField {
        MMField::Integer(*self)
    }
}

impl ToMMField for bool {
    fn to_mm_field(&self) -> MMField {
        MMField::Boolean(*self)
    }
}

impl ToMMField for Real {
    fn to_mm_field(&self) -> MMField {
        MMField::Real(self.0)
    }
}

impl ToMMField for f64 {
    fn to_mm_field(&self) -> MMField {
        MMField::Real(*self)
    }
}

impl ToMMField for ArcStr {
    fn to_mm_field(&self) -> MMField {
        MMField::String(self.clone())
    }
}

impl<T: MMReflect> ToMMField for Arc<T> {
    fn to_mm_field(&self) -> MMField {
        MMField::Node(self.clone())
    }
}

impl<T: ToMMField + Clone> ToMMField for List<T> {
    fn to_mm_field(&self) -> MMField {
        MMField::List(self.iter().map(ToMMField::to_mm_field).collect())
    }
}

impl<T: ToMMField> ToMMField for Vec<T> {
    fn to_mm_field(&self) -> MMField {
        MMField::Array(self.iter().map(ToMMField::to_mm_field).collect())
    }
}

impl<T: ToMMField> ToMMField for Array<T> {
    fn to_mm_field(&self) -> MMField {
        MMField::Array(self.borrow().iter().map(ToMMField::to_mm_field).collect())
    }
}

impl<T: ToMMField> ToMMField for Option<T> {
    fn to_mm_field(&self) -> MMField {
        MMField::Option(self.as_ref().map(|v| Box::new(v.to_mm_field())))
    }
}

macro_rules! tuple_to_mm_field {
    ($($name:ident $idx:tt),+) => {
        impl<$($name: ToMMField),+> ToMMField for ($($name,)+) {
            fn to_mm_field(&self) -> MMField {
                MMField::Tuple(vec![$(self.$idx.to_mm_field()),+])
            }
        }
    };
}
tuple_to_mm_field!(A 0, B 1);
tuple_to_mm_field!(A 0, B 1, C 2);
tuple_to_mm_field!(A 0, B 1, C 2, D 3);
tuple_to_mm_field!(A 0, B 1, C 2, D 3, E 4);
tuple_to_mm_field!(A 0, B 1, C 2, D 3, E 4, F 5);

impl MMReflect for SourceInfo {
    fn mm_type_name(&self) -> &'static str {
        "SourceInfo"
    }
    fn mm_ctor_name(&self) -> &'static str {
        "SOURCEINFO"
    }
    fn mm_field_names(&self) -> &'static [&'static str] {
        &[
            "fileName",
            "isReadOnly",
            "lineNumberStart",
            "columnNumberStart",
            "lineNumberEnd",
            "columnNumberEnd",
        ]
    }
    fn mm_field(&self, i: usize) -> Option<MMField> {
        Some(match i {
            0 => self.fileName.to_mm_field(),
            1 => self.isReadOnly.to_mm_field(),
            2 => self.lineNumberStart.to_mm_field(),
            3 => self.columnNumberStart.to_mm_field(),
            4 => self.lineNumberEnd.to_mm_field(),
            5 => self.columnNumberEnd.to_mm_field(),
            _ => return None,
        })
    }
}

impl ToMMField for SourceInfo {
    fn to_mm_field(&self) -> MMField {
        MMField::Node(Arc::new(self.clone()))
    }
}

/// Autoref specialization for the derive: `(&Probe(&field)).mm_probe()`
/// converts a field whose type implements [`ToMMField`] and falls back to
/// [`MMField::Opaque`] for any other type.
pub struct Probe<'a, T: ?Sized>(pub &'a T);

pub trait ProbeField {
    fn mm_probe(&self) -> MMField;
}

impl<T: ToMMField> ProbeField for Probe<'_, T> {
    fn mm_probe(&self) -> MMField {
        self.0.to_mm_field()
    }
}

pub trait ProbeOpaque {
    fn mm_probe(&self) -> MMField;
}

impl<T: ?Sized> ProbeOpaque for &Probe<'_, T> {
    fn mm_probe(&self) -> MMField {
        MMField::Opaque(std::any::type_name::<T>())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate as metamodelica;
    use crate::{MMReflect, Ref};

    struct NoView;

    #[derive(Clone, MMReflect)]
    enum E {
        A { x: i32, l: List<Ref<E>> },
        B(Option<ArcStr>),
        C,
    }

    #[derive(Clone, Copy, MMReflect)]
    #[repr(i32)]
    enum Lit {
        ONE = 1,
        TWO = 2,
    }

    #[derive(Clone, MMReflect)]
    struct R {
        e: Ref<E>,
        lit: Lit,
        t: (i32, Real),
        #[allow(dead_code)]
        opaque: Arc<NoView>,
    }

    fn node(f: MMField) -> Node {
        match f {
            MMField::Node(n) => n,
            _ => panic!("not a node"),
        }
    }

    #[test]
    fn walk() {
        let leaf = Arc::new(E::C);
        let e = Arc::new(E::A {
            x: 7,
            l: List::from_iter([leaf.clone()]),
        });
        let r: Node = Arc::new(R {
            e,
            lit: Lit::TWO,
            t: (1, Real::from(2.5)),
            opaque: Arc::new(NoView),
        });
        assert_eq!(r.mm_type_name(), "R");
        assert_eq!(r.mm_ctor_name(), "R");
        assert_eq!(r.mm_field_names(), &["e", "lit", "t", "opaque"]);
        let e = node(r.mm_field(0).unwrap());
        assert_eq!((e.mm_type_name(), e.mm_ctor_name()), ("E", "A"));
        assert!(matches!(e.mm_field(0), Some(MMField::Integer(7))));
        match e.mm_field(1) {
            Some(MMField::List(v)) => assert_eq!(node(v.into_iter().next().unwrap()).mm_ctor_name(), "C"),
            _ => panic!("not a list"),
        }
        assert!(e.mm_field(2).is_none());
        assert!(matches!(
            r.mm_field(1),
            Some(MMField::Enum {
                type_name: "Lit",
                literal: "TWO",
                index: 2
            })
        ));
        assert!(matches!(r.mm_field(2), Some(MMField::Tuple(_))));
        assert!(matches!(r.mm_field(3), Some(MMField::Opaque(_))));
        let b: Node = Arc::new(E::B(Some(ArcStr::from("s"))));
        assert_eq!(b.mm_field_names(), &["_0"]);
        assert!(matches!(b.mm_field(0), Some(MMField::Option(Some(_)))));
        assert!(matches!(downcast::<E>(&b).as_deref(), Some(E::B(Some(_)))));
        assert!(downcast::<R>(&b).is_none());
    }
}
