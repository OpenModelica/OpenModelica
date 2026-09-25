// mmtorust-replaces: isSet getConfigValue getConfigBool
//
// Flag reads that borrow the global flag arrays.

use super::*;

fn flag_at<A, T>(arr: &metamodelica::Array<A>, index: i32, f: impl FnOnce(&A) -> Result<T>) -> Result<T> {
    match arr.borrow().get((index - 1) as usize) {
        Some(v) => f(v),
        None => Err("Index {} out of bounds for array of length {}"),
    }
}

pub fn isSet(inFlag: DebugFlag) -> Result<bool> {
    crate::Globals::flagsIndex.with(|root| match &*root.borrow() {
        Flag::FLAGS { debugFlags, .. } => flag_at(debugFlags, inFlag.index, |b| Ok(*b)),
        _ => Err("pattern mismatch"),
    })
}

pub fn getConfigValue(inFlag: ConfigFlag) -> Result<FlagData> {
    crate::Globals::flagsIndex.with(|root| match &*root.borrow() {
        Flag::FLAGS { configFlags, .. } => flag_at(configFlags, inFlag.index, |d| Ok(d.clone())),
        _ => Err("pattern mismatch"),
    })
}

pub fn getConfigBool(inFlag: ConfigFlag) -> Result<bool> {
    crate::Globals::flagsIndex.with(|root| match &*root.borrow() {
        Flag::FLAGS { configFlags, .. } => flag_at(configFlags, inFlag.index, |d| match d {
            FlagData::BOOL_FLAG { data } => Ok(*data),
            _ => Err("pattern mismatch"),
        }),
        _ => Err("pattern mismatch"),
    })
}
