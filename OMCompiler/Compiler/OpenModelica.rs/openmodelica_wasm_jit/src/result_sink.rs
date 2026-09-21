//! The host's result file, written as the rows arrive. The host driver reaches it
//! through the driver's row sink; an in-wasm session writes its own file
//! (`rt_sim_set_result`) and reports the same [`Written`] back.

use std::cell::RefCell;

use openmodelica_sim_meta::result::{Precision, ResultOut, ResultStream};
use openmodelica_sim_meta::{SimMeta, driver};
use openmodelica_wasi::fs;

/// The result file of the next run: the resolved path, the writer its name asks
/// for, the `-variableFilter` decision per result signal, and `-single`.
#[derive(Clone)]
pub struct ResultTarget {
    pub path: String,
    pub format: String,
    pub keep: Vec<bool>,
    pub single: bool,
}

impl ResultTarget {
    pub fn precision(&self) -> Precision {
        if self.single { Precision::Single } else { Precision::Double }
    }
}

/// What a run wrote: how many rows, and the initial result row.
#[derive(Default)]
pub struct Written {
    pub n_rows: usize,
    pub first_row: Vec<f64>,
}

struct FileOut(fs::Writer);

impl ResultOut for FileOut {
    fn write(&mut self, bytes: &[u8]) -> bool {
        self.0.write_all(bytes).is_ok()
    }
    fn write_at(&mut self, pos: u64, bytes: &[u8]) -> bool {
        self.0.write_at(pos, bytes).is_ok()
    }
    fn flush(&mut self) -> bool {
        self.0.flush().is_ok()
    }
    fn close(&mut self) -> bool {
        self.0.flush().is_ok()
    }
}

thread_local! {
    static TARGET: RefCell<Option<ResultTarget>> = const { RefCell::new(None) };
    static STREAM: RefCell<Option<ResultStream>> = const { RefCell::new(None) };
}

fn open(e: &mut dyn driver::SimEngine, model: &SimMeta, sim_data: u32) -> driver::Result<()> {
    let Some(t) = TARGET.with(|c| c.borrow_mut().take()) else { return Ok(()) };
    let st = openmodelica_sim_meta::result::open_stream(e, model, sim_data, &t.format, &t.keep, t.precision(), || {
        fs::Writer::create(&t.path).ok().map(|w| Box::new(FileOut(w)) as Box<dyn ResultOut>)
    })?;
    STREAM.with(|c| *c.borrow_mut() = Some(st));
    Ok(())
}

fn rows(rows: &[f64]) -> bool {
    STREAM.with(|c| match c.borrow_mut().as_mut() {
        Some(st) => {
            st.push_rows(rows);
            true
        }
        None => false,
    })
}

fn finish() {
    STREAM.with(|c| {
        if let Some(st) = c.borrow_mut().as_mut() {
            st.finish();
        }
    });
}

/// Route the next host-driven run's rows to `target`. The file opens once
/// initialization is done ([`driver::open_result`], which `drive` calls itself).
pub fn arm(target: ResultTarget) {
    STREAM.with(|c| *c.borrow_mut() = None);
    TARGET.with(|c| *c.borrow_mut() = Some(target));
    driver::set_result_opener(Some(open));
    driver::set_row_sink(Some(rows), Some(finish));
}

/// Close the run's file (if the driver has not) and report what it holds.
pub fn take() -> Written {
    driver::set_result_opener(None);
    driver::set_row_sink(None, None);
    TARGET.with(|c| *c.borrow_mut() = None);
    match STREAM.with(|c| c.borrow_mut().take()) {
        Some(mut st) => {
            st.finish();
            Written { n_rows: st.n_rows(), first_row: st.first_row().to_vec() }
        }
        None => Written::default(),
    }
}
