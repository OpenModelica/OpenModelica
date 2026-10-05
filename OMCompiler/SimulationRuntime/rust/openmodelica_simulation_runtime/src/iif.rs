//! `-iif=<file>`: the start values to import, resolved against the model's
//! [`SimMeta::import_roster`] with the shared MAT4 reader. The driver applies and
//! logs them where C's `importStartValues` does.

use openmodelica_mat_reader::MatReader;
use openmodelica_sim_meta::{SimMeta, driver, omclog, simflags};

/// C's `mapToDymolaVars`: `der(a.b)` -> `a.der(b)`, and a space after each
/// subscript comma.
fn dymola_name(name: &str) -> String {
    let mut out = String::with_capacity(name.len() + 8);
    let mut level = 0;
    let bytes = name.as_bytes();
    for (i, &b) in bytes.iter().enumerate() {
        match b {
            b'[' => level += 1,
            b']' => level -= 1,
            _ => {}
        }
        out.push(b as char);
        if level > 0 && b == b',' && bytes.get(i + 1) != Some(&b' ') {
            out.push(' ');
        }
    }
    while let Some(rest) = out.strip_prefix("der(") {
        let Some(dot) = rest.rfind('.') else { break };
        out = format!("{}.der({}", &rest[..dot], &rest[dot + 1..]);
    }
    out
}

/// Resolve the file once, before initialization, or report why not the way C does.
/// Returns false when C would have failed the initialization.
pub fn resolve(meta: &SimMeta, result_file: &str) -> bool {
    let (file, time) = simflags::with_flags(|f| (f.init_file.clone(), f.init_time));
    let Some(file) = file else { return true };
    let time = time.unwrap_or(meta.start_time);
    if file == result_file {
        omclog::error!(
            omclog::INIT,
            false,
            "Cannot import a result file for initialization that is also the current output file <{file}>.\nConsider redirecting the output result file (-r=<new_res.mat>) or renaming the result file that is used for initialization import.",
        );
        return false;
    }
    let mut reader = match MatReader::open(&file) {
        Ok(r) => r,
        Err(why) => {
            omclog::debug!(omclog::ASSERT, false, "unable to read input-file <{file}> [{why}]");
            return false;
        }
    };
    let overridden = |n: &str| simflags::with_flags(|f| f.overrides.iter().any(|(o, _)| o == n));
    let mut values = Vec::new();
    for (i, (name, _, _)) in meta.import_roster().iter().flatten().enumerate() {
        if overridden(name) {
            continue;
        }
        let var = reader.find_var(name).or_else(|| reader.find_var(&dymola_name(name)));
        if let Some(v) = var.and_then(|idx| reader.val(idx, time)) {
            values.push((i as u32, v));
        }
    }
    driver::set_start_imports(Some(driver::StartImports { file, time, values }));
    true
}

std::thread_local! {
    /// The result file `-ipopt_init=file` reads at every collocation point, opened once.
    static OPENED: core::cell::RefCell<Option<(String, MatReader)>> = const { core::cell::RefCell::new(None) };
}

/// The driver's `ResultFileReader`: C's `importStartValues` for the real variables.
/// A name the file does not carry keeps the value `out` arrived with.
pub fn read_result_values(file: &str, names: &[&str], t: f64, out: &mut [f64]) -> Result<(), String> {
    OPENED.with(|cell| {
        let mut cell = cell.borrow_mut();
        if cell.as_ref().is_none_or(|(f, _)| f != file) {
            let reader = MatReader::open(file).map_err(|e| format!("unable to read input-file <{file}> [{e}]"))?;
            *cell = Some((file.to_string(), reader));
        }
        let (_, reader) = cell.as_mut().expect("just opened");
        for (name, slot) in names.iter().zip(out) {
            if let Some(v) = reader.find_var(name).and_then(|i| reader.val(i, t)) {
                *slot = v;
            }
        }
        Ok(())
    })
}
