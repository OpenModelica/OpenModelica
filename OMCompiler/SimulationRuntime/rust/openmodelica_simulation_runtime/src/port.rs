//! `-port` and `-logFormat=xmltcp`: C's `sim_communication_port`, the TCP
//! connection OMEdit listens on for the log and the progress bar.

use std::io::Write;
use std::net::TcpStream;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, AtomicPtr, Ordering};

use openmodelica_sim_meta::omclog;

use crate::abi::*;

static STREAM: Mutex<Option<TcpStream>> = Mutex::new(None);
static XMLTCP: AtomicBool = AtomicBool::new(false);
/// The log of an element that is still open, sent once it closes.
static PENDING: Mutex<String> = Mutex::new(String::new());
static DATA_PTR: AtomicPtr<DATA> = AtomicPtr::new(core::ptr::null_mut());

pub fn connect(port: u16, xmltcp: bool) -> bool {
    let Ok(s) = TcpStream::connect(("127.0.0.1", port)) else { return false };
    let _ = s.set_nodelay(true);
    *STREAM.lock().unwrap() = Some(s);
    XMLTCP.store(xmltcp, Ordering::Relaxed);
    true
}

pub fn is_open() -> bool {
    STREAM.lock().unwrap().is_some()
}

pub fn xmltcp() -> bool {
    XMLTCP.load(Ordering::Relaxed)
}

fn send(s: &str) {
    if let Some(stream) = STREAM.lock().unwrap().as_mut() {
        let _ = stream.write_all(s.as_bytes());
    }
}

/// A piece of the XML log: whole top-level elements are sent as they complete.
pub fn log(s: &str) {
    let mut pending = PENDING.lock().unwrap();
    pending.push_str(s);
    if omclog::xml_depth() == 0 {
        send(&pending);
        pending.clear();
    }
}

/// C's `communicateStatus`.
pub fn status(phase: &str, completion: f64, time: f64, step_size: f64) {
    let progress = (completion * 10000.0) as i32;
    if xmltcp() {
        send(&format!(
            "<status phase=\"{phase}\" currentStepSize=\"{}\" time=\"{}\" progress=\"{progress}\" />\n",
            omclog::g(step_size, 0, 6),
            omclog::g(time, 0, 6)
        ));
    } else {
        send(&format!("{progress} {phase}\n"));
    }
}

/// Report progress per step from the model's own clock.
pub fn watch(data: *mut DATA) {
    DATA_PTR.store(data, Ordering::Relaxed);
    openmodelica_sim_meta::driver::set_step_hook(running);
}

fn running() {
    let (completion, time) = position();
    status("Running", completion, time, 0.0);
}

/// Where the run is, as `(fraction of [startTime, stopTime], time)`.
pub fn position() -> (f64, f64) {
    let data = DATA_PTR.load(Ordering::Relaxed);
    if data.is_null() {
        return (0.0, 0.0);
    }
    let (si, time) = unsafe { (&*(*data).simulationInfo, (**(*data).localData).timeValue) };
    ((time - si.startTime) / (si.stopTime - si.startTime), time)
}

pub fn close() {
    let mut rest = std::mem::take(&mut *PENDING.lock().unwrap());
    // An element a failure left open would keep OMEdit from parsing the rest.
    if !rest.is_empty() {
        for _ in 0..omclog::xml_depth() {
            rest.push_str("</message>\n");
        }
        send(&rest);
    }
    *STREAM.lock().unwrap() = None;
}
