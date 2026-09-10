//! Write a small file in each format and read every variable back through the
//! crate's own reader.

#![cfg(feature = "library")]

use openmodelica_hdf5_result::{Affine, Kind, Meta, MtsfStream, Options, SdfStream, Var, VarTy, mtsf, sdf};

/// Three stored columns: time, `a.x`, `a.b.n`. `a.y` is `-a.x`, and the alias
/// comes before its target in the table, which is the case that decides whether
/// a format stores one column or two.
fn vars() -> Vec<Var<'static>> {
    vec![
        Var { name: "time", unit: "s", kind: Kind::Time, ..Default::default() },
        Var {
            name: "a.b.n",
            ty: VarTy::Integer,
            kind: Kind::Column { col: 2, affine: Affine::IDENTITY },
            ..Default::default()
        },
        Var {
            name: "a.y",
            comment: "an alias",
            unit: "m",
            kind: Kind::Column { col: 1, affine: Affine::negated() },
            ..Default::default()
        },
        Var {
            name: "a.x",
            comment: "the state",
            unit: "m",
            kind: Kind::Column { col: 1, affine: Affine::IDENTITY },
            ..Default::default()
        },
        Var { name: "c", kind: Kind::Const { value: 42.0 }, ..Default::default() },
        // Dropped by both writers, but it still owns the first `params` slot.
        Var { name: "s", ty: VarTy::String, kind: Kind::Param { affine: Affine::IDENTITY }, ..Default::default() },
        Var { name: "p", unit: "kg", kind: Kind::Param { affine: Affine::IDENTITY }, ..Default::default() },
    ]
}

const N_ROWS: usize = 10;
const PARAMS: [f64; 2] = [0.0, 7.5];

fn rows() -> Vec<f64> {
    (0..N_ROWS).flat_map(|i| [i as f64 * 0.5, (i as f64).sin(), (i % 3) as f64]).collect()
}

fn expected(name: &str, rows: &[f64]) -> Vec<f64> {
    let col = match name {
        "time" => 0,
        "a.x" | "a.y" => 1,
        "a.b.n" => 2,
        other => panic!("no column for {other}"),
    };
    let sign = if name == "a.y" { -1.0 } else { 1.0 };
    (0..N_ROWS).map(|r| sign * rows[r * 3 + col]).collect()
}

fn path(name: &str) -> String {
    let dir = std::env::var("OMC_H5_TEST_DIR")
        .map_or_else(|_| std::env::temp_dir().join("omc_h5_roundtrip"), Into::into);
    std::fs::create_dir_all(&dir).expect("test dir");
    dir.join(name).to_string_lossy().into_owned()
}

fn assert_close(name: &str, got: &[f64], want: &[f64]) {
    assert_eq!(got.len(), want.len(), "{name}: length");
    for (i, (a, b)) in got.iter().zip(want).enumerate() {
        assert!((a - b).abs() <= 1e-12 * b.abs().max(1.0), "{name}[{i}]: {a} != {b}");
    }
}

#[test]
fn sdf_roundtrip() {
    sdf_with(Options { chunk_rows: 4, ..Default::default() }, "t.sdf");
    // Reserving more rows than arrive: the datasets must shrink at finish.
    sdf_with(Options { chunk_rows: 4, expected_rows: Some(N_ROWS + 5), ..Default::default() }, "t-reserved.sdf");
}

fn sdf_with(opts: Options, name: &str) {
    let (path, vars, rows) = (path(name), vars(), rows());
    let meta = Meta { model_name: "T", description: "a test", ..Default::default() };
    let mut s = SdfStream::begin(&path, &vars, &PARAMS, &rows[..3], 3, &meta, &opts).unwrap();
    s.push_rows(&rows).unwrap();
    s.finish().unwrap();
    assert_eq!(s.n_rows(), N_ROWS);
    drop(s);

    let file = sdf::SdfFile::open(&path).unwrap();
    assert_eq!(file.n_rows, N_ROWS);
    assert_eq!(file.vars[file.time].name, "time");
    for (i, v) in file.vars.iter().enumerate() {
        let got = file.read_column(i).unwrap();
        match v.name.as_str() {
            "c" => assert_eq!(v.value, Some(42.0)),
            "p" => {
                assert_eq!(v.value, Some(7.5));
                assert_eq!(v.unit, "kg");
            }
            name => assert_close(name, &got, &expected(name, &rows)),
        }
    }
    // SDF writes an alias out in full, so it costs a dataset of its own; the
    // String variable is not there at all.
    assert_eq!(file.vars.len(), 6);
    assert!(file.vars.iter().all(|v| v.name != "s"));
}

#[test]
fn mtsf_roundtrip() {
    mtsf_with(Options { chunk_rows: 4, deflate: Some(1), ..Default::default() }, "t.mtsf");
    mtsf_with(
        Options { chunk_rows: 4, deflate: Some(1), expected_rows: Some(N_ROWS + 5), ..Default::default() },
        "t-reserved.mtsf",
    );
}

fn mtsf_with(opts: Options, name: &str) {
    let (path, vars, rows) = (path(name), vars(), rows());
    let meta = Meta { model_name: "T", description: "a test", ..Default::default() };
    let mut s = MtsfStream::begin(&path, &vars, &PARAMS, &rows[..3], 3, &meta, &opts).unwrap();
    s.push_rows(&rows).unwrap();
    s.finish().unwrap();
    assert_eq!(s.n_rows(), N_ROWS);
    drop(s);

    let file = mtsf::MtsfFile::open(&path).unwrap();
    assert_eq!(file.n_rows, N_ROWS);
    for (i, v) in file.vars.iter().enumerate() {
        let series = file.matrices[v.matrix].series;
        let got = file.read_column(i).unwrap();
        match v.name.as_str() {
            "c" => {
                assert_eq!(series, mtsf::Series::Fixed);
                assert_eq!(got, vec![42.0]);
            }
            "p" => {
                assert_eq!(series, mtsf::Series::Fixed);
                assert_eq!(got, vec![7.5]);
            }
            name => assert_close(name, &got, &expected(name, &rows)),
        }
    }
    assert_eq!(file.vars.iter().find(|v| v.name == "p").map(|v| v.unit.as_str()), Some("kg"));
    assert!(file.vars.iter().all(|v| v.name != "s"));
    // `a.x` and `a.y` share one column, whichever of the two is listed first.
    let reals = file
        .matrices
        .iter()
        .find(|m| m.series == mtsf::Series::Continuous && m.ty == VarTy::Real)
        .expect("continuous reals");
    assert_eq!(reals.n_cols, 2);
    assert_eq!(file.read_matrix(0).unwrap().len(), file.matrices[0].n_rows * file.matrices[0].n_cols);
}
