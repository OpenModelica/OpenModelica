//! `method="optimization"`: the collocation NLP `optimize()` solves with Ipopt.
//!
//! The port of `SimulationRuntime/c/optimization/`, structured like it:
//! [`setup`] is `MoveData.c`/`DerStructure.c`/`InitialGuess.c`, [`eval`] is
//! `eval_all/`, and this module is `optimizer_main.c` plus the shared data.
//!
//! Host-only, because Ipopt's only open linear solver (MUMPS) is Fortran and has
//! no wasm build — an in-wasm runtime reports what a C runtime built without
//! `OMC_HAVE_IPOPT` reports.
//!
//! **Precision.** The C code carries the time grid, the scaling factors and the
//! Hessian accumulation in `long double` (x87 80-bit). wasm has no such type and
//! neither does Rust, so those are `f64` here; the difference is in the last few
//! bits of quantities that are then used to converge an NLP to `tol`.

// Ipopt is linked only into a native (`std`) build; `build.rs` never sets the cfg
// for wasm32.
#[cfg(all(ipopt, feature = "std"))]
pub mod ipopt;
#[cfg(all(ipopt, feature = "std"))]
mod ipopt_out;
#[cfg(all(ipopt, feature = "std"))]
mod eval;
#[cfg(all(ipopt, feature = "std"))]
mod model;
#[cfg(all(ipopt, feature = "std"))]
mod setup;

/// C's `solver_main.c` when `OMC_HAVE_IPOPT` is undefined.
pub const UNAVAILABLE: &str = "Ipopt is needed but not available.";

/// Whether this build can run `method="optimization"`.
pub const AVAILABLE: bool = cfg!(all(ipopt, feature = "std"));

#[cfg(all(ipopt, feature = "std"))]
pub use run::run_optimizer;

#[cfg(all(ipopt, feature = "std"))]
mod run {
    use alloc::format;
    use alloc::string::String;
    use alloc::vec;
    use alloc::vec::Vec;

    use super::ipopt::{self, Bounds, Callbacks, Nlp};
    use super::model::Model;
    use super::{eval, setup};
    use crate::driver::{self, Result, SimEngine};
    use crate::{omclog, OptInfo, SimMeta};

    /// C's `OptDataDim`.
    #[derive(Default)]
    pub(crate) struct Dim {
        /// States, inputs and their sum: the variables at one collocation point.
        pub nx: usize,
        pub nu: usize,
        pub nv: usize,
        /// Path and final constraints.
        pub nc: usize,
        pub ncf: usize,
        /// Rows of the constraint Jacobian per point: states + path constraints.
        pub n_j: usize,
        /// `n_j + 2`: the Lagrange and Mayer gradient rows sit above them.
        pub n_j2: usize,
        /// Collocation: `nsi` intervals of `np` points each.
        pub nsi: usize,
        pub np: usize,
        pub nt: usize,
        /// NLP sizes: variables and constraints.
        pub nv_total: usize,
        pub n_res: usize,
        pub n_real: usize,
        /// First real index of a path / final constraint.
        pub index_con: usize,
        pub index_conf: usize,
        pub index_lagrange: usize,
        pub index_mayer: usize,
        /// Nonzeros of one point's constraint Jacobian, and of the final one.
        pub n_jderx: usize,
        pub n_jfderx: usize,
        /// Hessian nonzeros: all of them, and the upper triangle (`_`), for a
        /// generic point (`0`) and for the last one (`1`).
        pub nh0: usize,
        pub nh1: usize,
        pub nh0_: usize,
        pub nh1_: usize,
        /// `-keepHessian`: reuse the Hessian for this many iterations.
        pub update_hessian: i32,
        pub iter_update_hessian: i32,
        /// `-optimizerTimeGrid` supplied a grid.
        pub ex_time_grid: bool,
        pub iter: u32,
    }

    /// C's `OptDataTime`.
    #[derive(Default)]
    pub(crate) struct Time {
        pub t0: f64,
        pub tf: f64,
        /// Length of each interval (`nsi + 1` entries, as in C).
        pub dt: Vec<f64>,
        /// Collocation times, `nsi × np`.
        pub t: Vec<Vec<f64>>,
        /// The model supplied the grid through `$OPT_TGRID`.
        pub model_grid: bool,
        pub tt: Vec<f64>,
    }

    /// C's `OptDataBounds`. `v*` are per-variable (`nv`), `V*` per NLP variable.
    #[derive(Default)]
    pub(crate) struct BoundsData {
        pub vmin: Vec<f64>,
        pub vmax: Vec<f64>,
        pub v_min_all: Vec<f64>,
        pub v_max_all: Vec<f64>,
        pub vnom: Vec<f64>,
        pub scal_f: Vec<f64>,
        /// `scal_f[j] * dt[i]`, `nsi × nx`.
        pub scaldt: Vec<Vec<f64>>,
        /// `dt[i] * b[j]`, `nsi × np`.
        pub scalb: Vec<Vec<f64>>,
        pub u0: Vec<f64>,
        /// C's `preSim`: the Optimica `startTime`, before which a pre-simulation runs.
        pub pre_sim: f64,
    }

    /// C's `OptDataRK`: the Radau IIA coefficients for `np` collocation points.
    #[derive(Default)]
    pub(crate) struct Rk {
        pub a: [[f64; 5]; 5],
        pub b: [f64; 5],
    }

    /// C's `OptDataIpopt`.
    #[derive(Default)]
    pub(crate) struct Ipop {
        pub vopt: Vec<f64>,
        pub gmin: Vec<f64>,
        pub gmax: Vec<f64>,
        pub mult_g: Vec<f64>,
        pub mult_x_l: Vec<f64>,
        pub mult_x_u: Vec<f64>,
        /// `-csvOstep` / `-optDebugJac`: dump each step / compare the Jacobian.
        pub csv_ostep: Option<String>,
        pub debug_jac: Option<String>,
    }

    /// C's `OptDataStructure`: which entries of the Jacobians, gradients and
    /// Hessians can be nonzero. Flat bit maps with the C shapes.
    #[derive(Default)]
    pub(crate) struct Structure {
        /// C's `matrix[0..4]`, indexed like its `indexABCD`.
        pub matrix: [bool; 5],
        /// `J[0]`: `(n_j + 1) × nv` (B), `J[1]`: `n_j2 × nv` (C), `J[2]`: `ncf × nv` (D).
        pub j: [Vec<bool>; 3],
        /// `nv × nv` each.
        pub h0: Vec<bool>,
        pub h1: Vec<bool>,
        pub hm: Vec<bool>,
        pub hl: Vec<bool>,
        /// `n_j × nv × nv` and `ncf × nv × nv`.
        pub hg: Vec<bool>,
        pub hcf: Vec<bool>,
        pub lagrange: bool,
        pub mayer: bool,
        /// C's `derIndex`: the Mayer row in C, the Lagrange rows in B and C.
        pub der_index: [i32; 3],
        pub grad_m: Vec<bool>,
        pub grad_l: Vec<bool>,
        /// Rows of B / C holding the path constraints (skipping the objective rows).
        pub index_con2: Vec<usize>,
        pub index_con3: Vec<usize>,
        /// Row remapping for B / C: a matrix row -> its slot in `J[i][j]`.
        pub index_j2: Vec<usize>,
        pub index_j3: Vec<usize>,
        /// The constraint Jacobian's own pattern, `n_j × nv`.
        pub jder_con: Vec<bool>,
    }

    /// C's `OptData`: everything the callbacks share.
    pub(crate) struct OptData {
        pub dim: Dim,
        pub time: Time,
        pub bounds: BoundsData,
        pub rk: Rk,
        pub s: Structure,
        pub ipop: Ipop,
        /// Real variables at each collocation point, `nsi × np × n_real`, flat.
        pub v: Vec<f64>,
        /// The initial real variables, and the scaled initial states.
        pub v0: Vec<f64>,
        pub sv0: Vec<f64>,
        /// The discrete state (`pre` values, relations, integers, booleans) as the
        /// initialization left it; C's `copy_initial_values` restores it per point.
        pub snapshot: Vec<u8>,
        /// Constraint Jacobians per point, `nsi × np × n_j2 × nv`, flat.
        pub j: Vec<f64>,
        /// Scratch for the perturbed Jacobian the Hessian differences.
        pub tmp_j: Vec<f64>,
        /// Final-constraint Jacobian, `ncf × nv`, and its scratch.
        pub jf: Vec<f64>,
        pub tmp_jf: Vec<f64>,
        /// Hessian contributions: constraints (`n_j × nv × nv`), Lagrange and Mayer
        /// (`nv × nv`), final constraints (`ncf × nv × nv`).
        pub h: Vec<f64>,
        pub hl: Vec<f64>,
        pub hm: Vec<f64>,
        pub hcf: Vec<f64>,
        /// `-keepHessian`'s saved values.
        pub old_h: Vec<f64>,
        /// C's `iter_`: `evalfDiffG` calls, for `-optDebugJac`.
        pub iter_: i32,
        /// C's `index`: whether the Jacobians are evaluated along with the system.
        pub index: i32,
        pub model: Model,
        pub opt: OptInfo,
        /// Real-variable names, for the log messages.
        pub names: Vec<String>,
        /// The rows `res2file` produced, in the driver's result-row layout.
        pub rows: Vec<f64>,
        /// `optimizeInput.csv`, which C writes alongside the result file.
        pub input_csv: String,
        /// Ipopt's redirected `stdout` while it solves; the callbacks drain it so its
        /// banner keeps its place in the log.
        pub out: Option<super::ipopt_out::Capture>,
        /// The model's metadata, for the initial guess's integrator.
        pub meta: SimMeta,
        /// Run scalars the C code reads off `simulationInfo`.
        pub tol: f64,
        pub start_time: f64,
        pub stop_time: f64,
        pub num_steps: u32,
    }

    impl OptData {
        /// `v[i][j]` — one collocation point's real variables.
        pub fn v(&self, i: usize, j: usize) -> &[f64] {
            let n = self.dim.n_real;
            let base = (i * self.dim.np + j) * n;
            &self.v[base..base + n]
        }
        pub fn v_mut(&mut self, i: usize, j: usize) -> &mut [f64] {
            let n = self.dim.n_real;
            let base = (i * self.dim.np + j) * n;
            &mut self.v[base..base + n]
        }
        /// `J[i][j]` — one point's constraint Jacobian, `n_j2 × nv` row-major.
        pub fn jac(&self, i: usize, j: usize) -> &[f64] {
            let n = self.dim.n_j2 * self.dim.nv;
            let base = (i * self.dim.np + j) * n;
            &self.j[base..base + n]
        }
        pub fn jac_mut(&mut self, i: usize, j: usize) -> &mut [f64] {
            let n = self.dim.n_j2 * self.dim.nv;
            let base = (i * self.dim.np + j) * n;
            &mut self.j[base..base + n]
        }
        pub fn jac_row(&self, i: usize, j: usize, row: usize) -> &[f64] {
            let nv = self.dim.nv;
            &self.jac(i, j)[row * nv..row * nv + nv]
        }
    }

    /// C's `runOptimizer`. Returns the result rows; the caller writes them out.
    pub fn run_optimizer(
        e: &mut (dyn SimEngine + 'static),
        meta: &SimMeta,
        sim_data: u32,
    ) -> Result<Vec<f64>> {
        let Some(opt) = meta.opt.clone() else {
            // C's generated stubs when the model was translated without Optimica.
            return Err("The model was not compiled with -g=Optimica and the corresponding goal \
                        function. The optimization solver cannot be used.");
        };
        // C sets `noThrowDivZero` for the whole optimization: a division by zero at a
        // trial point must not abort the solve.
        let div_flag = e.no_throw_div_zero_addr();
        if div_flag != 0 {
            driver::write_i32(e, div_flag, 1)?;
        }
        let res = run_solve(e, meta, sim_data, opt);
        if div_flag != 0 {
            driver::write_i32(e, div_flag, 0)?;
        }
        res
    }

    fn run_solve(
        e: &mut (dyn SimEngine + 'static),
        meta: &SimMeta,
        sim_data: u32,
        opt: OptInfo,
    ) -> Result<Vec<f64>> {
        let mut data = setup::pick_up_model_data(e, meta, sim_data, opt)?;
        setup::initial_guess(&mut data)?;
        setup::allocate_der_struct(&mut data)?;
        let status = solve(&mut data);
        setup::res2file(&mut data)?;
        if let Some(err) = data.model.err {
            return Err(err);
        }
        if status != ipopt::SOLVE_SUCCEEDED && status != ipopt::SOLVED_TO_ACCEPTABLE_LEVEL {
            return Err(OPTIMIZATION_FAILED);
        }
        Ok(core::mem::take(&mut data.rows))
    }

    /// What `performSimulation` reports when the step returns nonzero.
    pub const OPTIMIZATION_FAILED: &str = "model terminate | optimization failed.";

    /// Ipopt's own banner (`IpoptApplication::PrintCopyrightMessage`), verbatim.
    const IPOPT_BANNER: &str = "\n\
        ******************************************************************************\n\
        This program contains Ipopt, a library for large-scale nonlinear optimization.\n\
        \u{20}Ipopt is released as open source code under the Eclipse Public License (EPL).\n\
        \u{20}        For more information visit https://github.com/coin-or/Ipopt\n\
        ******************************************************************************\n\n";

    /// C's `optimizationWithIpopt`: the options it sets, then `IpoptSolve`.
    fn solve(data: &mut OptData) -> i32 {
        let d = &data.dim;
        let (nsi, np, nx) = (d.nsi, d.np, d.nx);
        let njac = np * (d.n_jderx * nsi + nx * (np * nsi - 1)) + d.n_jfderx;
        let nhess = (nsi * np - 1) * d.nh0_ + d.nh1_;
        let tol = data.tol;
        let mut max_iter = 5000i32;

        let mut x_min = core::mem::take(&mut data.bounds.v_min_all);
        let mut x_max = core::mem::take(&mut data.bounds.v_max_all);
        let mut g_min = core::mem::take(&mut data.ipop.gmin);
        let mut g_max = core::mem::take(&mut data.ipop.gmax);
        let nlp = Nlp::new(
            Bounds {
                x_min: &mut x_min,
                x_max: &mut x_max,
                g_min: &mut g_min,
                g_max: &mut g_max,
                nele_jac: njac,
                nele_hess: nhess,
            },
            Callbacks {
                f: eval::eval_f,
                g: eval::eval_g,
                grad_f: eval::eval_grad_f,
                jac_g: eval::eval_jac_g,
                h: eval::eval_h,
            },
        );
        let nlp = match nlp {
            Ok(n) => n,
            Err(e) => {
                omclog::error(omclog::STDOUT, false, e);
                return -1;
            }
        };
        // The bounds are copied by Ipopt; `gmin`/`gmax` are read again by
        // `printMaxError`, so they go back.
        data.ipop.gmin = g_min;
        data.ipop.gmax = g_max;

        nlp.num_option("tol", tol);
        nlp.str_option("evaluate_orig_obj_at_resto_trial", "yes");
        // Ipopt prints its banner from a `static` guard, i.e. once per process. The C
        // target forks a fresh executable per run, so every run shows it; here the
        // runs share omc's process, so it is suppressed and written by hand where
        // Ipopt would have printed it -- inside the solve, which `-ipopt_max_iter`
        // below a zero skips entirely.
        nlp.str_option("sb", "yes");

        let print_level = if omclog::active(omclog::IPOPT_FULL) {
            7
        } else if omclog::active(omclog::IPOPT) {
            5
        } else if omclog::active(omclog::STATS) {
            3
        } else {
            2
        };
        nlp.int_option("print_level", print_level);
        nlp.int_option("file_print_level", 0);

        let (jac_test, hesse_test) =
            (omclog::active(omclog::IPOPT_JAC), omclog::active(omclog::IPOPT_HESSE));
        match (jac_test, hesse_test) {
            (true, true) => {
                nlp.int_option("print_level", 4);
                nlp.str_option("derivative_test", "second-order");
            }
            (true, false) => {
                nlp.int_option("print_level", 4);
                nlp.str_option("derivative_test", "first-order");
            }
            (false, true) => {
                nlp.int_option("print_level", 4);
                nlp.str_option("derivative_test", "only-second-order");
            }
            (false, false) => {
                nlp.str_option("derivative_test", "none");
            }
        }

        let flags = crate::simflags::with_flags(|f| f.clone());
        match flags.ipopt_hesse.as_deref() {
            Some("BFGS") => {
                nlp.str_option("hessian_approximation", "limited-memory");
            }
            Some("const") | Some("CONST") => {
                nlp.str_option("hessian_constant", "yes");
            }
            Some("num") | Some("NUM") | None => {}
            Some(other) => omclog::warning(
                omclog::STDOUT,
                false,
                &format!("not support ipopt_hesse={other}"),
            ),
        }

        if let Some(ls) = flags.ls_ipopt.as_deref() {
            nlp.str_option("linear_solver", ls);
        }
        nlp.num_option("mumps_pivtolmax", 1e-5);

        match flags.ipopt_max_iter.as_deref() {
            Some(v) => {
                // C accepts `<digits>e<digits>` as well as a plain integer, and
                // prints what it parsed.
                match v.split_once('e') {
                    None => {
                        max_iter = v.parse().unwrap_or(0);
                        if max_iter >= 0 {
                            nlp.int_option("max_iter", max_iter);
                        }
                        driver::log_line(omclog::STDOUT, omclog::INFO, &format!(
                            "\nmax_iter = {}",
                            v.parse::<i32>().unwrap_or(0)
                        ));
                    }
                    Some((m, x)) => {
                        let (m, x): (i32, i32) = (m.parse().unwrap_or(0), x.parse().unwrap_or(0));
                        let scaled = (m as f64) * libm::pow(10.0, x as f64);
                        max_iter = scaled as i32;
                        if max_iter >= 0 {
                            nlp.int_option("max_iter", max_iter);
                        }
                        driver::log_line(omclog::STDOUT, omclog::INFO, &format!(
                            "\nmax_iter = (int) {} | (double) {}",
                            max_iter,
                            crate::driver::format_g(scaled, 6)
                        ));
                    }
                }
            }
            None => {
                nlp.int_option("max_iter", 5000);
            }
        }

        // Heuristics: a warm start shifts the barrier parameter and the bound
        // multipliers toward the given decade.
        let ws: i32 = flags.ipopt_warm_start.as_deref().and_then(|v| v.parse().ok()).unwrap_or(0);
        if ws > 0 {
            let shift = libm::pow(10.0, -(ws as f64));
            nlp.num_option("mu_init", shift);
            nlp.num_option("bound_mult_init_val", shift);
            nlp.str_option("mu_strategy", "monotone");
            nlp.num_option("bound_push", 1e-5);
            nlp.num_option("bound_frac", 1e-5);
            nlp.num_option("slack_bound_push", 1e-5);
            nlp.num_option("constr_mult_init_max", 1e-5);
            nlp.str_option("bound_mult_init_method", "mu-based");
        } else {
            nlp.str_option("mu_strategy", "adaptive");
            nlp.str_option("bound_mult_init_method", "constant");
        }
        nlp.str_option("fixed_variable_treatment", "make_parameter");
        nlp.str_option("dependency_detection_with_rhs", "yes");
        nlp.num_option("nu_init", 1e-9);
        nlp.num_option("eta_phi", 1e-10);

        let mut res = 0;
        if max_iter >= 0 {
            data.iter_ = 0;
            data.index = 1;
            driver::log_line(omclog::STDOUT, omclog::INFO, IPOPT_BANNER);
            data.out = super::ipopt_out::Capture::begin();
            let mut vopt = core::mem::take(&mut data.ipop.vopt);
            let mut mult_g = core::mem::take(&mut data.ipop.mult_g);
            let mut mult_l = core::mem::take(&mut data.ipop.mult_x_l);
            let mut mult_u = core::mem::take(&mut data.ipop.mult_x_u);
            let mut obj = 0.0;
            let user = data as *mut OptData as *mut core::ffi::c_void;
            res = nlp.solve(&mut vopt, &mut obj, &mut mult_g, &mut mult_l, &mut mult_u, user);
            data.ipop.vopt = vopt;
            data.ipop.mult_g = mult_g;
            data.ipop.mult_x_l = mult_l;
            data.ipop.mult_x_u = mult_u;
            // Restores `stdout` and drains the tail (Ipopt's final summary).
            data.out = None;
        }
        if res != 0 && !omclog::active(omclog::IPOPT) {
            omclog::warning(
                omclog::STDOUT,
                false,
                "No optimal solution found!\nUse -lv=LOG_IPOPT for more information.",
            );
        }
        // The bounds Ipopt copied are ours again, for a caller that re-solves.
        data.bounds.v_min_all = x_min;
        data.bounds.v_max_all = x_max;
        res
    }

    /// Zeroed vectors of `n` elements, the C `calloc` idiom.
    pub(crate) fn zeros(n: usize) -> Vec<f64> {
        vec![0.0; n]
    }

    pub(crate) fn flags_bool(n: usize) -> Vec<bool> {
        vec![false; n]
    }
}
