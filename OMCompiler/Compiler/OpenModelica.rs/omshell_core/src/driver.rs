//! Runs the backend off the UI. Native: a dedicated worker thread with a large
//! stack (capi needs init+eval on one thread, and the port overflows the default
//! 8 MiB). Wasm: a dedicated Web Worker (omc_worker.js) runs the omc module, so a
//! command never blocks the UI thread; replies arrive asynchronously via
//! postMessage and are drained by `try_recv`.

use crate::backend::Init;

pub enum DriverMsg {
    Ready(Result<Init, String>),
    Done {
        result: String,
        error: String,
        keep_running: bool,
    },
}

#[cfg(not(target_arch = "wasm32"))]
pub use native::Driver;
#[cfg(target_arch = "wasm32")]
pub use wasm::Driver;

#[cfg(not(target_arch = "wasm32"))]
mod native {
    use super::*;
    use crate::backend::{Eval, OmcBackend};
    use std::sync::mpsc::{Receiver, Sender, channel};
    use std::thread;

    const OMC_STACK: usize = 512 * 1024 * 1024;

    pub struct Driver {
        tx: Sender<String>,
        rx: Receiver<DriverMsg>,
    }

    impl Driver {
        pub fn spawn(
            mut backend: Box<dyn OmcBackend + Send>,
            repaint: impl Fn() + Send + 'static,
        ) -> Self {
            let (tx_in, rx_in) = channel::<String>();
            let (tx_out, rx_out) = channel::<DriverMsg>();
            thread::Builder::new()
                .name("omc".to_owned())
                .stack_size(OMC_STACK)
                .spawn(move || {
                    let _ = tx_out.send(DriverMsg::Ready(backend.init()));
                    repaint();
                    while let Ok(cmd) = rx_in.recv() {
                        let Eval {
                            result,
                            error,
                            keep_running,
                        } = backend.eval(&cmd);
                        let _ = tx_out.send(DriverMsg::Done {
                            result,
                            error,
                            keep_running,
                        });
                        repaint();
                    }
                })
                .expect("failed to spawn omc worker thread");
            Driver {
                tx: tx_in,
                rx: rx_out,
            }
        }

        pub fn submit(&mut self, cmd: String) {
            let _ = self.tx.send(cmd);
        }

        pub fn try_recv(&mut self) -> Option<DriverMsg> {
            self.rx.try_recv().ok()
        }
    }
}

#[cfg(target_arch = "wasm32")]
mod wasm {
    use super::*;
    use crate::backend::OmcBackend;
    use std::cell::RefCell;
    use std::collections::VecDeque;
    use std::rc::Rc;
    use wasm_bindgen::JsCast;
    use wasm_bindgen::prelude::*;
    use web_sys::{MessageEvent, Worker, WorkerOptions, WorkerType};

    pub struct Driver {
        worker: Worker,
        queue: Rc<RefCell<VecDeque<DriverMsg>>>,
        // The worker calls this for the lifetime of the Driver, so it must be kept
        // alive here (dropping it would invalidate the JS callback).
        _onmessage: Closure<dyn FnMut(MessageEvent)>,
    }

    fn field(data: &JsValue, key: &str) -> String {
        js_sys::Reflect::get(data, &JsValue::from_str(key))
            .ok()
            .and_then(|v| v.as_string())
            .unwrap_or_default()
    }

    fn flag(data: &JsValue, key: &str) -> bool {
        js_sys::Reflect::get(data, &JsValue::from_str(key))
            .ok()
            .and_then(|v| v.as_bool())
            .unwrap_or(false)
    }

    // Decode a worker reply (see omc_worker.js for the message shapes).
    fn decode(data: &JsValue) -> Option<DriverMsg> {
        match field(data, "kind").as_str() {
            "ready" => Some(if flag(data, "ok") {
                DriverMsg::Ready(Ok(Init {
                    version: field(data, "version"),
                    message: field(data, "message"),
                }))
            } else {
                DriverMsg::Ready(Err(field(data, "error")))
            }),
            "done" => Some(DriverMsg::Done {
                result: field(data, "result"),
                error: field(data, "error"),
                keep_running: flag(data, "keep"),
            }),
            _ => None,
        }
    }

    fn message(pairs: &[(&str, JsValue)]) -> JsValue {
        let o = js_sys::Object::new();
        for (k, v) in pairs {
            let _ = js_sys::Reflect::set(&o, &JsValue::from_str(k), v);
        }
        o.into()
    }

    impl Driver {
        pub fn spawn(
            _backend: Box<dyn OmcBackend + Send>,
            repaint: impl Fn() + Send + 'static,
        ) -> Self {
            // omc lives in a dedicated Web Worker, so the passed-in backend is
            // unused on wasm (it is an inert placeholder; see omshell_omc). The
            // worker script is staged at the web root next to the omc module it
            // imports, so the URL is relative to the GUI page.
            let opts = WorkerOptions::new();
            opts.set_type(WorkerType::Module);
            let worker = Worker::new_with_options("omc_worker.js", &opts)
                .expect("failed to spawn omc Web Worker");

            let queue: Rc<RefCell<VecDeque<DriverMsg>>> = Rc::new(RefCell::new(VecDeque::new()));
            let q = queue.clone();
            let onmessage = Closure::<dyn FnMut(MessageEvent)>::new(move |e: MessageEvent| {
                if let Some(msg) = decode(&e.data()) {
                    q.borrow_mut().push_back(msg);
                    repaint();
                }
            });
            worker.set_onmessage(Some(onmessage.as_ref().unchecked_ref()));

            let _ = worker.post_message(&message(&[("cmd", JsValue::from_str("init"))]));

            Driver {
                worker,
                queue,
                _onmessage: onmessage,
            }
        }

        pub fn submit(&mut self, cmd: String) {
            let _ = self.worker.post_message(&message(&[
                ("cmd", JsValue::from_str("eval")),
                ("src", JsValue::from_str(&cmd)),
            ]));
        }

        pub fn try_recv(&mut self) -> Option<DriverMsg> {
            self.queue.borrow_mut().pop_front()
        }
    }
}
