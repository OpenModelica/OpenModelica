//! `DLARUV`/`DLARNV`, LAPACK's random-number generators.
//!
//! Bit-exact with the reference, because PRIMME seeds its initial search space
//! from `DLARNV`: any comparison against a run on a system LAPACK depends on both
//! taking the same iterates.
//!
//! `DLARUV` is a multiplicative congruential generator with modulus `2^48` and
//! multiplier `33952834046453`. The reference carries the `i`-th power of the
//! multiplier as a table of base-4096 digits; they are the powers themselves, so
//! this computes them instead of copying the table.

/// Reference `DLARUV`'s block length.
const LV: usize = 128;
const IPW2: f64 = 4096.0;
/// `2^48`, the generator's modulus.
const M48: u64 = 1 << 48;
/// The multiplier the reference table's rows are the powers of.
const MULT: u64 = 33952834046453;

/// `n <= 128` uniform `(0,1)` numbers, advancing `iseed` (four base-4096 digits,
/// the last odd).
pub fn dlaruv(iseed: &mut [i32; 4], x: &mut [f64]) {
    let seed = iseed.iter().fold(0u64, |acc, d| (acc << 12) | (*d as u64 & 0xFFF));
    let mut p = 1u64;
    for v in x.iter_mut().take(LV) {
        p = p.wrapping_mul(MULT) % M48;
        let it = p.wrapping_mul(seed) % M48;
        // The reference accumulates the same value digit by digit from the top.
        let d = |k: u32| ((it >> (12 * k)) & 0xFFF) as f64;
        *v = (d(3) + (d(2) + (d(1) + d(0) / IPW2) / IPW2) / IPW2) / IPW2;
    }
    let n = x.len().min(LV) as u32;
    let advanced = pow_mod(MULT, n as u64).wrapping_mul(seed) % M48;
    for (k, d) in iseed.iter_mut().enumerate() {
        *d = ((advanced >> (12 * (3 - k))) & 0xFFF) as i32;
    }
}

fn pow_mod(mut base: u64, mut e: u64) -> u64 {
    let mut acc = 1u64;
    base %= M48;
    while e > 0 {
        if e & 1 == 1 {
            acc = acc.wrapping_mul(base) % M48;
        }
        base = base.wrapping_mul(base) % M48;
        e >>= 1;
    }
    acc
}

/// `DLARNV`: `x` filled from the distribution `idist` — 1 uniform `(0,1)`,
/// 2 uniform `(-1,1)`, 3 normal `(0,1)`.
pub fn dlarnv(idist: i32, iseed: &mut [i32; 4], x: &mut [f64]) {
    let mut u = [0.0f64; LV];
    let mut done = 0;
    while done < x.len() {
        let take = (x.len() - done).min(LV / 2);
        // A normal deviate consumes two uniforms; the others one, and the seed
        // advances by exactly what was drawn.
        let drawn = if idist == 3 { 2 * take } else { take };
        dlaruv(iseed, &mut u[..drawn]);
        for i in 0..take {
            x[done + i] = match idist {
                1 => u[i],
                2 => 2.0 * u[i] - 1.0,
                _ => {
                    let r = crate::sqrt(-2.0 * libm::log(u[2 * i]));
                    r * libm::cos(2.0 * core::f64::consts::PI * u[2 * i + 1])
                }
            };
        }
        done += take;
    }
}
