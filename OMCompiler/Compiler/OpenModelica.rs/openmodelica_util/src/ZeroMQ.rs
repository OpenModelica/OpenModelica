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

//! Hand-written port of the `ZeroMQ` package (`Compiler/Util/ZeroMQ.mo`),
//! whose bodies are `external "C"` wrappers over `runtime/zeromqimpl.c`.
//!
//! Used by the interactive server loop (`Main.interactivemodeZMQ`, enabled by
//! `--interactive=zmq`) to talk to clients such as OMEdit: omc creates a
//! `ZMQ_REP` socket bound to a TCP port, writes the resolved endpoint to a file
//! under the temp directory, then loops `handleRequest`/`sendReply`.
//!
//! ## Feature gate
//! The whole interactive-ZMQ server is behind the `zeromq` cargo feature of
//! `openmodelica_util` (on by default). With the feature off, the `zmq` crate
//! (and the bundled libzmq it builds) is not pulled in and `initialize`
//! reports failure, which the MM loop treats as "could not start the server".
//!
//! ## Handle representation
//! The MetaModelica interface stores the socket in an `Option<Integer>`. The C
//! runtime boxes the raw `void*` socket pointer there (a 64-bit value), but in
//! this port `Integer` is `i32`, which cannot hold a pointer. The MM code only
//! ever treats the value opaquely (it checks for the failure sentinel `SOME(0)`
//! and threads the handle back to the other calls), so we keep the real socket
//! objects in a process-global registry keyed by a small non-zero `i32` handle
//! and return that handle instead. `Some(0)` is reserved for the failure case,
//! matching `mmc_mk_some(0)` in the C code.
#![allow(non_snake_case)] // keep the MetaModelica interface parameter names

use arcstr::ArcStr;

#[cfg(feature = "zeromq")]
mod imp {
    use super::*;
    use crate::Settings;
    use std::collections::HashMap;
    use std::sync::{LazyLock, Mutex};

    /// Per-socket state, mirroring the process-globals of `zeromqimpl.c` (the
    /// socket plus the global `zeroMQFilePath` removed on close). Dropping the
    /// `Socket`/`Context` closes and terminates them.
    struct ZmqState {
        // The context must outlive the socket; both are dropped together when
        // the entry is removed in `close`. Kept solely to own its lifetime.
        _context: zmq::Context,
        socket: zmq::Socket,
        /// The port file written in `initialize`, removed in `close`.
        file_path: Option<String>,
    }

    struct Registry {
        sockets: HashMap<i32, ZmqState>,
        next_handle: i32,
    }

    static REGISTRY: LazyLock<Mutex<Registry>> = LazyLock::new(|| {
        Mutex::new(Registry {
            sockets: HashMap::new(),
            next_handle: 1,
        })
    });

    /// Port of `ZeroMQ_initialize` / `zeromqimpl.c:ZeroMQ_initialize`.
    pub fn initialize(fileSuffix: ArcStr, listenToAll: bool, port: i32) -> Option<i32> {
        let context = zmq::Context::new();
        let socket = match context.socket(zmq::REP) {
            Ok(s) => s,
            Err(_) => return Some(0),
        };

        let host = if listenToAll { "*" } else { "127.0.0.1" };
        let bindstr = if port == 0 {
            format!("tcp://{host}:*")
        } else {
            format!("tcp://{host}:{port}")
        };
        if let Err(e) = socket.bind(&bindstr) {
            // C prints the errno string and returns the failure sentinel.
            println!("Error creating ZeroMQ Server. zmq_bind failed: {e}");
            return Some(0);
        }

        // Query the actually-bound endpoint (e.g. "tcp://127.0.0.1:34567").
        let endpoint = match socket.get_last_endpoint() {
            // Ok(Ok(s)) is a valid-UTF-8 endpoint; Ok(Err(bytes)) the raw form.
            Ok(Ok(s)) => s,
            Ok(Err(bytes)) => String::from_utf8_lossy(&bytes).into_owned(),
            Err(_) => return Some(0),
        };

        // Build the port-file path. Matches the POSIX branch of the C code:
        //   <tempPath>/openmodelica.<USER or "nobody">.port<suffix>
        let temp_path = Settings::getTempDirectoryPath();
        let user = std::env::var("USER").unwrap_or_else(|_| "nobody".to_string());
        let file_path = format!("{temp_path}/openmodelica.{user}.port{fileSuffix}");

        if std::fs::write(&file_path, &endpoint).is_err() {
            // C aborts via assertion if the file cannot be opened; we treat it
            // as an initialization failure instead.
            return Some(0);
        }
        use std::io::Write;
        print!("Created ZeroMQ Server.\nDumped server port in file: {file_path}");
        let _ = std::io::stdout().flush();

        // Register and return a small non-zero handle.
        let mut reg = REGISTRY.lock().unwrap();
        let handle = reg.next_handle;
        reg.next_handle += 1;
        reg.sockets.insert(
            handle,
            ZmqState {
                _context: context,
                socket,
                file_path: Some(file_path),
            },
        );
        Some(handle)
    }

    /// Port of `ZeroMQ_handleRequest` / `ZeroMQImpl_handleRequest`.
    ///
    /// Blocks until a request arrives and returns it as a string. An unknown
    /// handle (never expected after a successful `initialize`) yields "".
    pub fn handleRequest(zmqSocket: Option<i32>) -> ArcStr {
        let Some(handle) = zmqSocket else {
            return ArcStr::new();
        };
        let reg = REGISTRY.lock().unwrap();
        let Some(state) = reg.sockets.get(&handle) else {
            return ArcStr::new();
        };
        match state.socket.recv_bytes(0) {
            Ok(bytes) => ArcStr::from(String::from_utf8_lossy(&bytes)),
            Err(_) => ArcStr::new(),
        }
    }

    /// Port of `ZeroMQ_sendReply` / `zeromqimpl.c:ZeroMQ_sendReply`.
    ///
    /// The C code runs the reply through `iconv("UTF-8","UTF-8")` to validate;
    /// an `ArcStr` is already valid UTF-8, so we send its bytes directly.
    pub fn sendReply(zmqSocket: Option<i32>, reply: ArcStr) {
        let Some(handle) = zmqSocket else {
            return;
        };
        let reg = REGISTRY.lock().unwrap();
        let Some(state) = reg.sockets.get(&handle) else {
            return;
        };
        let _ = state.socket.send(reply.as_bytes(), 0);
    }

    /// Port of `ZeroMQ_close` / `zeromqimpl.c:ZeroMQ_close`.
    ///
    /// Removes the port file and drops the socket and context (closing them).
    pub fn close(zmqSocket: Option<i32>) {
        let Some(handle) = zmqSocket else {
            return;
        };
        let state = {
            let mut reg = REGISTRY.lock().unwrap();
            reg.sockets.remove(&handle)
        };
        if let Some(state) = state {
            if let Some(path) = &state.file_path {
                let _ = std::fs::remove_file(path);
            }
            // `state` (socket + context) drops here, closing them cleanly.
        }
    }
}

/// Stubs used when the `zeromq` feature is disabled: the interactive ZMQ server
/// is unavailable, so `initialize` reports the failure sentinel and the rest
/// are no-ops (they are never reached after a failed `initialize`).
#[cfg(not(feature = "zeromq"))]
mod imp {
    use super::*;

    pub fn initialize(_fileSuffix: ArcStr, _listenToAll: bool, _port: i32) -> Option<i32> {
        println!(
            "ZeroMQ support is disabled in this build (the `zeromq` feature of \
             openmodelica_util was turned off)."
        );
        Some(0)
    }

    pub fn handleRequest(_zmqSocket: Option<i32>) -> ArcStr {
        ArcStr::new()
    }

    pub fn sendReply(_zmqSocket: Option<i32>, _reply: ArcStr) {}

    pub fn close(_zmqSocket: Option<i32>) {}
}

pub use imp::{close, handleRequest, initialize, sendReply};

#[cfg(all(test, feature = "zeromq"))]
mod tests {
    use super::*;

    /// Full round-trip: start the server, connect a REQ client to the endpoint
    /// recorded in the port file, and exercise handleRequest/sendReply/close.
    #[test]
    fn zmq_round_trip() {
        // Bind a server on a random loopback port.
        let handle = initialize(arcstr::literal!(".test"), false, 0)
            .expect("initialize returned None");
        assert_ne!(handle, 0, "initialize reported the failure sentinel SOME(0)");

        // The endpoint was written to the port file; read it back the same way
        // a client (OMEdit) would.
        let temp = crate::Settings::getTempDirectoryPath();
        let user = std::env::var("USER").unwrap_or_else(|_| "nobody".to_string());
        let port_file = format!("{temp}/openmodelica.{user}.port.test");
        let endpoint = std::fs::read_to_string(&port_file).expect("port file missing");
        assert!(endpoint.starts_with("tcp://127.0.0.1:"), "bad endpoint {endpoint:?}");

        // Run the REQ client on another thread; the server side blocks in
        // handleRequest on this thread.
        let ep = endpoint.clone();
        let client = std::thread::spawn(move || {
            let ctx = zmq::Context::new();
            let req = ctx.socket(zmq::REQ).unwrap();
            req.connect(&ep).unwrap();
            req.send("getVersion()", 0).unwrap();
            req.recv_string(0).unwrap().unwrap()
        });

        let request = handleRequest(Some(handle));
        assert_eq!(request.as_str(), "getVersion()");
        sendReply(Some(handle), arcstr::literal!("v1.42.0"));

        let reply = client.join().unwrap();
        assert_eq!(reply, "v1.42.0");

        // close removes the port file and tears down the socket.
        close(Some(handle));
        assert!(!std::path::Path::new(&port_file).exists(), "port file not removed");
    }
}
