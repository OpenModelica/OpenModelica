//! Runs the backend off the UI. Native: a dedicated worker thread with a large
//! stack (capi needs init+eval on one thread, and the port overflows the default
//! 8 MiB). Wasm: single-threaded, so evaluate synchronously and queue the reply.

use crate::backend::{Eval, Init, OmcBackend};

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
    use std::collections::VecDeque;

    pub struct Driver {
        backend: Box<dyn OmcBackend + Send>,
        queue: VecDeque<DriverMsg>,
        pending: Option<String>,
    }

    impl Driver {
        pub fn spawn(
            mut backend: Box<dyn OmcBackend + Send>,
            _repaint: impl Fn() + Send + 'static,
        ) -> Self {
            let mut queue = VecDeque::new();
            queue.push_back(DriverMsg::Ready(backend.init()));
            Driver {
                backend,
                queue,
                pending: None,
            }
        }

        pub fn submit(&mut self, cmd: String) {
            // eval is synchronous and blocks the single UI thread here, so don't
            // run it now: just record the command. The shell has already pushed
            // it to the scrollback and set `busy`, so the UI paints the command +
            // spinner first; the eval then runs on the next `try_recv` (below).
            self.pending = Some(cmd);
        }

        pub fn try_recv(&mut self) -> Option<DriverMsg> {
            if let Some(msg) = self.queue.pop_front() {
                return Some(msg);
            }
            // Run the deferred command now — on a poll *after* the one that
            // painted the busy state. (Still blocks while omc runs; a non-frozen
            // spinner would need omc on a Web Worker.)
            if let Some(cmd) = self.pending.take() {
                let Eval {
                    result,
                    error,
                    keep_running,
                } = self.backend.eval(&cmd);
                return Some(DriverMsg::Done {
                    result,
                    error,
                    keep_running,
                });
            }
            None
        }
    }
}
