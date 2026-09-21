//! What the three algorithms are expected to agree and disagree on.

use openmodelica_result_diff::{Algorithm, Settings, TubeSize, compare, rectangle, tube_size};

/// A ramp with `n` points over [0, 1].
fn ramp(n: usize, slope: f64) -> (Vec<f64>, Vec<f64>) {
    let t: Vec<f64> = (0..n).map(|i| i as f64 / (n - 1) as f64).collect();
    let v = t.iter().map(|x| slope * x).collect();
    (t, v)
}

fn settings(algorithm: Algorithm, tolerance: f64) -> Settings {
    Settings { algorithm, tolerance, ..Settings::default() }
}

#[test]
fn legacy_and_standard_base_differ_on_an_offset_signal() {
    let t = [0.0, 1.0];
    let y = [10.0, 11.0];
    // legacy takes |min| into account, standard only the range
    let legacy = TubeSize::legacy(&t, &y, tube_size::DEFAULT_NOMINAL_VALUE);
    let standard = TubeSize::standard(&t, &y, tube_size::DEFAULT_NOMINAL_VALUE);
    assert_eq!(legacy.base_y, 10.0);
    assert_eq!(standard.base_y, 1.0);
    assert_eq!(legacy.base_x, 1.0);
}

#[test]
fn the_nominal_value_floors_the_tube_of_a_flat_zero_signal() {
    let t = [0.0, 1.0];
    let y = [0.0, 0.0];
    let size = TubeSize::legacy(&t, &y, 0.001);
    assert_eq!(size.base_y, 0.001);
}

#[test]
fn rectangle_tube_stays_within_the_reference_time_span() {
    let (t, y) = ramp(11, 1.0);
    let mut size = TubeSize::legacy(&t, &y, 0.001);
    size.calculate_relative_x(0.01).unwrap();
    let (low, high) = rectangle::rectangle_tube(&t, &y, &size);
    for c in [&low, &high] {
        assert_eq!(c.x.len(), c.y.len());
        assert!(c.x[0] >= t[0], "tube starts at {} before {}", c.x[0], t[0]);
        assert!(*c.x.last().unwrap() <= *t.last().unwrap());
        assert!(c.x.windows(2).all(|w| w[0] <= w[1]), "tube x is not monotonic: {:?}", c.x);
    }
    assert!(low.y.iter().zip(&high.y).all(|(l, h)| l < h) || low.y.len() != high.y.len());
}

#[test]
fn every_algorithm_passes_a_curve_compared_with_itself() {
    let (t, y) = ramp(101, 2.0);
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let c = compare(&t, &y, &t, &y, &settings(algorithm, 0.002)).unwrap();
        assert!(!c.differs(), "{} flagged an identical curve ({} points)", algorithm.name(), c.error_count);
        assert_eq!(c.delta_error, 0.0);
    }
}

#[test]
fn every_algorithm_fails_a_curve_far_outside_the_tube() {
    let (t, y) = ramp(101, 2.0);
    let off: Vec<f64> = y.iter().map(|v| v + 1.0).collect();
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let c = compare(&t, &off, &t, &y, &settings(algorithm, 0.002)).unwrap();
        assert!(c.differs(), "{} accepted a curve one unit off", algorithm.name());
        assert!(c.delta_error > 0.0);
    }
}

/// The tube height csv-compare's algorithms get from `TubeSize` is
/// `tolerance * baseY`, which for `ellipse2014` is instead driven by the time
/// span and the slope scale `S` — the two do not have the same sensitivity, and
/// this is what makes the tools disagree.
#[test]
fn the_algorithms_have_different_sensitivity() {
    let (t, y) = ramp(201, 1.0);
    let mut differs = Vec::new();
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let off: Vec<f64> = y.iter().map(|v| v + 0.003).collect();
        let c = compare(&t, &off, &t, &y, &settings(algorithm, 0.002)).unwrap();
        differs.push(c.differs());
    }
    assert_ne!(differs[0], differs[2], "rectangle and ellipse2014 agreed at an offset of 0.003: {differs:?}");
}

/// `RemoveLoop` used to spin forever on a reference that reverses often
/// (csv-compare 8c97f9c, "Fix endless loop").
#[test]
fn a_sawtooth_reference_terminates() {
    let n = 400;
    let t: Vec<f64> = (0..n).map(|i| i as f64 / (n - 1) as f64).collect();
    let y: Vec<f64> = t.iter().enumerate().map(|(i, _)| if i % 2 == 0 { 0.0 } else { 1.0 }).collect();
    let mut size = TubeSize::legacy(&t, &y, 0.001);
    // wide enough that the rectangles overlap several neighbours
    size.calculate_relative_x(0.05).unwrap();
    let (low, high) = rectangle::rectangle_tube(&t, &y, &size);
    assert!(!low.x.is_empty() && !high.x.is_empty());
}

#[test]
fn an_empty_curve_is_rejected_rather_than_panicking() {
    let t = [0.0, 1.0];
    let y = [1.0, 1.0];
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let s = settings(algorithm, 0.002);
        assert!(compare(&[], &[], &t, &y, &s).is_err());
        assert!(compare(&t, &y, &[], &[], &s).is_err());
    }
}

/// A one-sample reference: the tube degenerates to a flat one rather than
/// erroring. A one-sample curve *under test* is only usable by the algorithms
/// that do not resample from it.
#[test]
fn a_single_sample_reference_still_compares() {
    let (t, y) = ramp(21, 1.0);
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let c = compare(&t, &y, &[0.0], &[0.0], &settings(algorithm, 0.002)).unwrap();
        assert!(!c.differs(), "{} flagged a flat one-sample reference", algorithm.name());
    }
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse] {
        compare(&[0.0], &[0.0], &t, &y, &settings(algorithm, 0.002)).unwrap();
    }
    assert!(compare(&[0.0], &[0.0], &t, &y, &settings(Algorithm::Ellipse2014, 0.002)).is_err());
}

/// A trajectory one value short of its timeline (a truncated last CSV row).
#[test]
fn a_short_trajectory_is_compared_as_far_as_it_goes() {
    let (t, y) = ramp(51, 1.0);
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let c = compare(&t, &y[..50], &t, &y[..50], &settings(algorithm, 0.002)).unwrap();
        assert!(!c.differs(), "{}", algorithm.name());
    }
}

/// stopTime == startTime: the time column never advances, which is where the C
/// in `SimulationResultsCmpTubes.c` reads out of bounds.
#[test]
fn a_zero_length_run_does_not_panic() {
    let t = [0.0, 0.0];
    let y = [1.0, 1.0];
    for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
        let _ = compare(&t, &y, &t, &y, &settings(algorithm, 0.002));
    }
}

fn noise(n: usize, seed: u64) -> Vec<f64> {
    let mut s = seed | 1;
    (0..n)
        .map(|_| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            (s >> 11) as f64 / (1u64 << 53) as f64 * 2.0 - 1.0
        })
        .collect()
}

fn grid(n: usize) -> Vec<f64> {
    (0..n).map(|i| i as f64 / (n - 1) as f64).collect()
}

/// A tube built around a reference has to contain that reference: a file
/// compared with itself passes. This is the invariant real result files rely on.
///
/// `Ellipse` is left out, and that is a property of the algorithm rather than of
/// this port. Its consolidation step drops the slopes of the intervals it merges,
/// so where the reference turns faster than the tube can follow, the local
/// extremum loses its own node and the interpolated tube cuts across it — a
/// reference compared with itself then reports the odd point outside. csv-compare
/// replaced it with `Rectangle` in 2015 and keeps it only as an option, and
/// OpenModelica's C guards the same loop against reaching the first interval.
#[test]
fn a_reference_is_always_inside_its_own_tube() {
    for seed in 1..12u64 {
        let n = 40 + 13 * seed as usize;
        let t = grid(n);
        // integrated noise: continuous, with slopes of order 1
        let mut acc = 0.0;
        let y: Vec<f64> = noise(n, seed).iter().map(|d| {
            acc += d / n as f64;
            acc
        })
        .collect();
        for tol in [1e-4, 0.002, 0.02, 0.2] {
            for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse2014] {
                let c = compare(&t, &y, &t, &y, &settings(algorithm, tol)).unwrap();
                assert!(!c.differs(), "{} at tol {tol}, n {n}: {} points outside", algorithm.name(), c.error_count);
            }
        }
    }
}

/// The consolidation loops walk their index back towards the first interval, so
/// they only terminate because the polyline shrinks; white noise is the cheapest
/// way to keep that honest. The tube must also stay a tube: x non-decreasing,
/// lower never above upper.
///
/// Containment is not asserted here; see
/// [`a_reference_is_always_inside_its_own_tube`] for which algorithms guarantee
/// it.
#[test]
fn a_spiky_reference_still_yields_a_tube() {
    for seed in 1..20u64 {
        let n = 30 + 7 * seed as usize;
        let t = grid(n);
        let y = noise(n, seed);
        for tol in [1e-4, 0.002, 0.02, 0.2] {
            for algorithm in [Algorithm::Rectangle, Algorithm::Ellipse, Algorithm::Ellipse2014] {
                let c = compare(&t, &y, &t, &y, &settings(algorithm, tol)).unwrap();
                let what = algorithm.name();
                assert_eq!(c.low.len(), c.high.len(), "{what}");
                assert!(c.lower.x.windows(2).all(|w| w[0] <= w[1]), "{what} at tol {tol}: lower x not monotonic");
                assert!(c.upper.x.windows(2).all(|w| w[0] <= w[1]), "{what} at tol {tol}: upper x not monotonic");
                assert!(c.low.iter().zip(&c.high).all(|(l, h)| l <= h), "{what} at tol {tol}: tube inverted");
            }
        }
    }
}
