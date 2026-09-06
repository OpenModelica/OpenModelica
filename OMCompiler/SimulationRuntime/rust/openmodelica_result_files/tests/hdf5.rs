//! The SDF and MTSF readers through the `.mat` data model every consumer of
//! `ResultTable` uses: the signed index convention, parameter lookup and the
//! alias handling each format represents differently.

#![cfg(feature = "hdf5")]

use openmodelica_hdf5_result::{Affine, Kind, Meta, MtsfStream, Options, SdfStream, Var, VarTy};
use openmodelica_result_files::{ResultReader, time_var_name};

const N_ROWS: usize = 8;
const PARAMS: [f64; 1] = [2.5];

fn vars() -> Vec<Var<'static>> {
    vec![
        Var { name: "time", unit: "s", kind: Kind::Time, ..Default::default() },
        // The negated alias comes first, so a format that lets its first
        // reference decide the stored sign gets caught here.
        Var { name: "b.minus_x", kind: Kind::Column { col: 1, affine: Affine::negated() }, ..Default::default() },
        Var { name: "b.x", unit: "m", kind: Kind::Column { col: 1, affine: Affine::IDENTITY }, ..Default::default() },
        Var { name: "n", ty: VarTy::Integer, kind: Kind::Column { col: 2, affine: Affine::IDENTITY }, ..Default::default() },
        Var { name: "p", unit: "kg", kind: Kind::Param { affine: Affine::IDENTITY }, ..Default::default() },
    ]
}

fn rows() -> Vec<f64> {
    (0..N_ROWS).flat_map(|i| [i as f64, 10.0 + i as f64, (i % 4) as f64]).collect()
}

fn write(suffix: &str) -> String {
    let dir = std::env::var("OMC_H5_TEST_DIR")
        .map_or_else(|_| std::env::temp_dir().join("omc_result_files_hdf5"), Into::into);
    std::fs::create_dir_all(&dir).expect("test dir");
    let path = dir.join(format!("t{suffix}")).to_string_lossy().into_owned();
    let (vars, rows) = (vars(), rows());
    let meta = Meta { model_name: "T", stop_time: 7.0, ..Default::default() };
    let opts = Options { chunk_rows: 4, expected_rows: Some(N_ROWS), ..Default::default() };
    match suffix {
        ".sdf" => {
            let mut s = SdfStream::begin(&path, &vars, &PARAMS, &rows[..3], 3, &meta, &opts).unwrap();
            s.push_rows(&rows).unwrap();
            s.finish().unwrap();
        }
        _ => {
            let mut s = MtsfStream::begin(&path, &vars, &PARAMS, &rows[..3], 3, &meta, &opts).unwrap();
            s.push_rows(&rows).unwrap();
            s.finish().unwrap();
        }
    }
    path
}

fn check(suffix: &str) {
    let path = write(suffix);
    let mut reader = match ResultReader::open(&path) {
        Ok(r) => r,
        Err(_) => panic!("{suffix}: open failed"),
    };
    assert_eq!(reader.nrows(), Some(N_ROWS), "{suffix}: rows");

    let names = reader.vars_filter_aliases();
    assert_eq!(time_var_name(&names), "time");
    for name in ["time", "b.x", "n", "p"] {
        assert!(names.iter().any(|n| n == name), "{suffix}: {name} missing from {names:?}");
    }

    let x: Vec<f64> = (0..N_ROWS).map(|i| 10.0 + i as f64).collect();
    assert_eq!(reader.trajectory("b.x").unwrap(), x, "{suffix}: b.x");
    let negated: Vec<f64> = x.iter().map(|v| -v).collect();
    assert_eq!(reader.trajectory("b.minus_x").unwrap(), negated, "{suffix}: alias");
    assert_eq!(reader.trajectory("n").unwrap(), vec![0.0, 1.0, 2.0, 3.0, 0.0, 1.0, 2.0, 3.0], "{suffix}: n");
    assert_eq!(reader.trajectory("p").unwrap(), vec![2.5; N_ROWS], "{suffix}: parameter");

    let table = reader.table_mut().expect("column store");
    assert_eq!(table.start_time(), 0.0);
    assert_eq!(table.stop_time(), (N_ROWS - 1) as f64);
    let idx = table.find_var("b.x").expect("b.x");
    assert_eq!(table.unit(idx), ("m", "m"), "{suffix}: unit");
    assert_eq!(table.val(idx, 3.5), Some(13.5), "{suffix}: interpolated");
    assert_eq!(table.var_type(table.find_var("n").expect("n")), "Integer");
    assert!(table.read_all(), "{suffix}: read_all");
}

#[test]
fn sdf_through_result_table() {
    check(".sdf");
}

#[test]
fn mtsf_through_result_table() {
    check(".mtsf");
}
