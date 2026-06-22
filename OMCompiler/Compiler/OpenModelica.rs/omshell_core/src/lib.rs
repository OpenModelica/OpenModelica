mod backend;
mod completion;
mod driver;
mod shell;

pub use backend::{Eval, Init, OmcBackend};
pub use shell::{SegKind, Segment, Shell};
