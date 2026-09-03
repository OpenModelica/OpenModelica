//! The result file of a wasip1 runtime: a buffered WASI file behind the
//! `ResultStream`, shared by the in-wasm session and the standalone command.

use alloc::boxed::Box;
use std::io::{BufWriter, Seek, SeekFrom, Write};

use openmodelica_sim_meta::result::ResultOut;

pub(crate) struct FileOut(BufWriter<std::fs::File>);

impl ResultOut for FileOut {
    fn write(&mut self, bytes: &[u8]) -> bool {
        self.0.write_all(bytes).is_ok()
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) -> bool {
        let w = &mut self.0;
        (|| {
            let end = w.seek(SeekFrom::End(0))?;
            w.seek(SeekFrom::Start(pos))?;
            w.write_all(bytes)?;
            w.seek(SeekFrom::Start(end.max(pos + bytes.len() as u64)))?;
            w.flush()
        })()
        .is_ok()
    }
    fn close(&mut self) -> bool {
        self.0.flush().is_ok()
    }
}

pub(crate) fn open(path: &str) -> Option<Box<dyn ResultOut>> {
    let f = std::fs::File::create(path).ok()?;
    Some(Box::new(FileOut(BufWriter::with_capacity(1 << 18, f))))
}
