//! How many threads a result file may be read or written with.
//!
//! Nothing here can see the compiler's flags - `libomc_result` is loaded by a
//! simulation, by OMEdit and by OMPlot alike - so the budget arrives in the
//! environment: `OPENMODELICA_NUM_PROC`, which is what `omc` should export from
//! `--numProcs` (`-n`) so a simulation it launches inherits it, else
//! `OMP_NUM_THREADS`, which is how a user or a batch scheduler says the same
//! thing and which the runtime's other parallel paths already honour. Unset or
//! `0` means the machine's parallelism.
//!
//! It governs dividing *work*, which is the read side. A writer thread is not
//! that and does not consult it; see [`write`].
//!
//! `omc` does not export it yet, so today the limit only arrives through
//! `OMP_NUM_THREADS`.

use std::sync::OnceLock;

/// Threads this process may use: what the environment allows, never more than
/// the platform can run.
///
/// The floor matters more than the ceiling. `available_parallelism` fails where
/// there are no threads to have - both wasm targets - so a budget taken from
/// the environment alone would promise a reader threads it cannot spawn. Under
/// WASI this returns 1 whatever `OMP_NUM_THREADS` says.
pub fn budget() -> usize {
    static BUDGET: OnceLock<usize> = OnceLock::new();
    *BUDGET.get_or_init(|| {
        let machine = std::thread::available_parallelism().map_or(1, std::num::NonZero::get);
        let limit = ["OPENMODELICA_NUM_PROC", "OMP_NUM_THREADS"]
            .iter()
            .find_map(|k| std::env::var(k).ok()?.trim().parse::<usize>().ok())
            .filter(|n| *n > 0);
        limit.unwrap_or(machine).min(machine).max(1)
    })
}

/// Threads to read `pieces` independently decodable pieces with.
///
/// No caller yet: the reader that will use it divides the format's record
/// batches, and the format is not in the product until the writer follows. The
/// rule is here because it is measured, and measuring it again would cost an
/// hour.
///
/// Measured on `arrow.modelica`: uncompressed a read is memory-bound and stops
/// improving at four - eight threads were 1.14x against 1.16x on one model and
/// 1.45x against 1.32x on another - so it is capped there. Compressed the work
/// is decompression, which keeps dividing (2.08x at four, 2.58x at eight), so
/// only the budget and the number of pieces cap it.
pub fn read(pieces: usize, compressed: bool) -> usize {
    let cap = if compressed { budget() } else { budget().min(4) };
    cap.min(pieces).max(1)
}

/// Whether a writer may hand its rows to a thread of its own. False wherever
/// there is no second thread to put it on, wasm included.
///
/// Deliberately *not* the budget. A writer thread is not parallel compute: it
/// wakes once per 64 rows to serialize them and sleeps again, measured at 0.3
/// to 1.1% duty for `mat`, `arrow` and MTSF over a run, so twelve parallel
/// simulations add about a tenth of a core between them. `--numProcs` limits
/// how many cores to compute on, and this is not that.
///
/// The testsuite is the reason it matters. Tying it to the budget would mean
/// the threaded path never runs there - `-n=1` - and code that CI never
/// executes is a worse risk than the one thread. What it does change is how
/// much of the tail a simulation loses if it dies without closing the file: up
/// to four handovers of 64 rows, against the `BufWriter` the direct path
/// already buffers into.
pub fn write() -> bool {
    std::thread::available_parallelism().map_or(1, std::num::NonZero::get) > 1
}
