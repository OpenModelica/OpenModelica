//! `cargo run --example fmuprobe -- <file.fmu> t x0 x1 …` — put a Model
//! Exchange FMU at one point and print what it says there: the derivatives, the
//! event indicators, the counts. What to reach for when a run's events land in
//! the wrong place and the question is whether the master or the FMU is wrong.

use openmodelica_fmi::{Fmu, InterfaceKind};
use openmodelica_fmi_driver::api::{Fmi3, Fmi3ModelExchange};
use openmodelica_fmi_driver::ffi;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args().skip(1);
    let path = args.next().ok_or("usage: fmuprobe <file.fmu> [t x0 x1 …]")?;
    let numbers: Vec<f64> = args.map(|a| a.parse().unwrap_or(f64::NAN)).collect();
    let fmu = Fmu::from_path(std::path::Path::new(&path))?;
    let md = &fmu.model_description;
    let mut dir = std::path::PathBuf::from(&path);
    dir.set_extension("fmu.d");
    let (lib, resources) = ffi::open_fmu(&fmu, InterfaceKind::ModelExchange, &dir)?;
    let mut inst = lib.instantiate_model_exchange(
        &md.model_name,
        &md.instantiation_token,
        resources.as_deref(),
        false,
    )?;

    let e = md.default_experiment.unwrap_or_default();
    let start = numbers.first().copied().unwrap_or(e.start_time.unwrap_or(0.0));
    inst.enter_initialization_mode(e.tolerance, start, e.stop_time)?;
    inst.exit_initialization_mode()?;
    while inst.update_discrete_states()?.need_update {}
    inst.enter_continuous_time_mode()?;

    let nx = inst
        .get_number_of_continuous_states()
        .unwrap_or(md.number_of_continuous_states() as usize);
    let nz = inst
        .get_number_of_event_indicators()
        .unwrap_or(md.number_of_event_indicators as usize);
    println!("{nx} continuous states, {nz} event indicators");
    let (colors, rows) = openmodelica_fmi_driver::me::jacobian_sparsity(md, &md.continuous_states());
    let nonzeros: usize = rows.iter().map(Vec::len).sum();
    println!(
        "Jacobian sparsity: {} colours over {} columns, {nonzeros} nonzeros of {}",
        colors.len(),
        rows.len(),
        nx * nx
    );

    let mut x = vec![0.0; nx];
    inst.get_continuous_states(&mut x)?;
    if numbers.len() > 1 {
        for (slot, v) in x.iter_mut().zip(&numbers[1..]) {
            *slot = *v;
        }
    }
    inst.set_time(start)?;
    inst.set_continuous_states(&x)?;

    let mut dx = vec![0.0; nx];
    inst.get_continuous_state_derivatives(&mut dx)?;
    let mut z = vec![0.0; nz];
    inst.get_event_indicators(&mut z)?;
    println!("t = {start}\nx  = {x:?}\ndx = {dx:?}\nz  = {z:?}");

    // Does the FMU answer `fmi3GetDirectionalDerivative`, and with what?
    let states = md.continuous_states();
    let derivatives: Vec<u32> = md
        .model_structure
        .continuous_state_derivatives
        .iter()
        .map(|u| u.value_reference)
        .collect();
    if !states.is_empty() && derivatives.len() == states.len() {
        let mut seed = vec![0.0; states.len()];
        seed[0] = 1.0;
        let mut out = vec![0.0; derivatives.len()];
        match inst.get_directional_derivative(&derivatives, &states, &seed, &mut out) {
            Ok(()) => println!("directional derivative for the first state: {out:?}"),
            Err(e) => println!("directional derivative: {e}"),
        }
    }

    // `OMC_FMU_BENCH=<calls>`: what one solver evaluation costs through this
    // binary, to compare against the same FMU driven through a wasm runtime.
    if let Some(n) = std::env::var("OMC_FMU_BENCH").ok().and_then(|v| v.parse::<u32>().ok()) {
        let now = std::time::Instant::now();
        for i in 0..n {
            inst.set_time(start + i as f64 * 1e-9)?;
            inst.set_continuous_states(&x)?;
            inst.get_continuous_state_derivatives(&mut dx)?;
        }
        let per = now.elapsed().as_secs_f64() / n as f64;
        println!("one solver evaluation (set+set+get): {:.1} ns/call", per * 1e9);
        let now = std::time::Instant::now();
        for _ in 0..n {
            inst.get_continuous_state_derivatives(&mut dx)?;
        }
        let per = now.elapsed().as_secs_f64() / n as f64;
        println!("get-continuous-state-derivatives:    {:.1} ns/call", per * 1e9);
        if !states.is_empty() && derivatives.len() == states.len() {
            let mut seed = vec![0.0; states.len()];
            seed[0] = 1.0;
            let mut out = vec![0.0; derivatives.len()];
            if inst.get_directional_derivative(&derivatives, &states, &seed, &mut out).is_ok() {
                let now = std::time::Instant::now();
                for _ in 0..n {
                    inst.get_directional_derivative(&derivatives, &states, &seed, &mut out)?;
                }
                let per = now.elapsed().as_secs_f64() / n as f64;
                println!("directional derivative (cached):     {:.1} ns/call", per * 1e9);
                // The first seed after a move pays for the assembly.
                let now = std::time::Instant::now();
                for i in 0..n {
                    inst.set_time(start + i as f64 * 1e-9)?;
                    inst.get_directional_derivative(&derivatives, &states, &seed, &mut out)?;
                }
                let per = now.elapsed().as_secs_f64() / n as f64;
                println!("directional derivative (assembled):  {:.1} ns/call", per * 1e9);
            }
        }
    }
    Ok(())
}
