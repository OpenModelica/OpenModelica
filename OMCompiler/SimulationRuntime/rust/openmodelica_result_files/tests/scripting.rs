//! The scripting functions on small files written here.

use std::path::PathBuf;

use openmodelica_mat_writer::{MatKind, MatVar, Neg, Precision, write_mat4};
use openmodelica_result_files::cmp::Algorithm;
use openmodelica_result_files::file::{ResultFile, Tolerances, diff_all};
use openmodelica_result_files::scripting::{self, Messages, Severity};

#[derive(Default)]
struct Collect(Vec<(Severity, String)>);

impl Messages for Collect {
    fn add(&mut self, severity: Severity, format: &str, tokens: &[&str]) {
        let mut text = format.to_owned();
        for t in tokens {
            text = text.replacen("%s", t, 1);
        }
        self.0.push((severity, text));
    }
}

fn dir(test: &str) -> PathBuf {
    let d = std::env::temp_dir().join(format!("omc_result_scripting_{}_{test}", std::process::id()));
    std::fs::create_dir_all(&d).unwrap();
    d
}

fn path(d: &PathBuf, name: &str) -> String {
    d.join(name).to_str().unwrap().to_owned()
}

#[test]
fn diff_all_reports_missing_variables() {
    let d = dir("diff");
    let actual = path(&d, "actual.csv");
    let reference = path(&d, "reference.csv");
    std::fs::write(&actual, "time,x,y\n0,1,0\n0.5,2,0\n1,3,0\n").unwrap();
    std::fs::write(&reference, "time,x,y,z\n0,1,0,0\n0.5,2,1,0\n1,3,2,0\n").unwrap();
    let mut a = ResultFile::open(&actual).unwrap();
    let mut r = ResultFile::open(&reference).unwrap();
    let vars = ["x", "y", "z"].map(String::from).to_vec();
    assert_eq!(
        diff_all(&mut a, &mut r, vars, Tolerances::default()).unwrap(),
        ["y", "z"]
    );
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn csv_booleans_are_numbers() {
    let d = dir("booleans");
    let file = path(&d, "fmpy.csv");
    std::fs::write(&file, "\"time\",\"b\"\n0.0,True\n1.0,False\n").unwrap();
    let mut f = ResultFile::open(&file).unwrap();
    assert_eq!(f.trajectory("b").unwrap(), [1.0, 0.0]);
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn csv_val() {
    let d = dir("val");
    let file = path(&d, "res.csv");
    std::fs::write(&file, "\"time\",\"x\",\"der(b.x)\"\n0,0,1\n0.5,1,1\n0.5,3,1\n1,5,2\n").unwrap();
    let mut m = Collect::default();
    let val = |m: &mut Collect, var: &str, t: f64| scripting::val(m, &file, var, t);
    assert_eq!(
        [0.0, 0.25, 0.5, 0.75, 1.0].map(|t| val(&mut m, "x", t)),
        [0.0, 0.5, 3.0, 4.0, 5.0]
    );
    assert_eq!(val(&mut m, "time", 0.3), 0.3);
    assert_eq!(val(&mut m, "b.der(x)", 0.75), 1.5);
    assert!(m.0.is_empty());
    assert!(val(&mut m, "x", 1.5).is_nan());
    assert!(val(&mut m, "y", 0.5).is_nan());
    assert_eq!(
        m.0.iter().map(|(_, s)| s.as_str()).collect::<Vec<_>>(),
        [
            "x not defined at time 1.5 (startTime=0, stopTime=1).".to_owned(),
            format!("y not found in {file}\n"),
        ]
    );
    scripting::close();
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn diff_all_finds_csv_names_as_in_mat_files() {
    let d = dir("names");
    let actual = path(&d, "actual.csv");
    let reference = path(&d, "reference.csv");
    std::fs::write(&actual, "time,\"a[1,2]\",der(b.x)\n0,1,0\n1,2,0\n").unwrap();
    std::fs::write(&reference, "time,\"a[1, 2]\",b.der(x)\n0,1,0\n1,2,0\n").unwrap();
    let mut a = ResultFile::open(&actual).unwrap();
    let mut r = ResultFile::open(&reference).unwrap();
    assert!(
        diff_all(&mut a, &mut r, Vec::new(), Tolerances::default())
            .unwrap()
            .is_empty()
    );
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn filter_without_descriptions_reads_back() {
    let d = dir("filter");
    let input = path(&d, "in.mat");
    let output = path(&d, "out.mat");
    let column = |col| MatKind::Column { col, negate: Neg::None };
    let vars = [
        MatVar {
            name: "time",
            comment: "Time",
            kind: MatKind::Time,
            unvarying: false,
        },
        MatVar {
            name: "x",
            comment: "a state",
            kind: column(1),
            unvarying: false,
        },
        MatVar {
            name: "k",
            comment: "a parameter",
            kind: MatKind::Param { negate: Neg::None },
            unvarying: false,
        },
    ];
    let rows = [0.0, 1.0, 1.0, 0.5];
    std::fs::write(&input, write_mat4(&vars, 0.0, 1.0, &rows, 2, &[2.0], Precision::Double)).unwrap();

    let mut msgs = Collect::default();
    let vars = ["x", "k"].map(String::from);
    assert!(scripting::filter(&mut msgs, &input, &output, &vars, 0, true));
    assert_eq!(
        scripting::read_variables(&mut msgs, &output, true, false, true),
        ["k", "time", "x"]
    );
    assert_eq!(scripting::val(&mut msgs, &output, "x", 1.0), 0.5);
    assert_eq!(scripting::val(&mut msgs, &output, "k", 1.0), 2.0);
    assert!(msgs.0.is_empty(), "{:?}", msgs.0);
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn read_variables_without_derivatives() {
    let d = dir("derivatives");
    let mat = path(&d, "res.mat");
    let csv = path(&d, "res.csv");
    let column = |col| MatKind::Column { col, negate: Neg::None };
    let var = |name, kind| MatVar {
        name,
        comment: "",
        kind,
        unvarying: false,
    };
    let vars = [
        var("time", MatKind::Time),
        var("x", column(1)),
        var("der(x)", column(2)),
        var("a.der(b)", column(3)),
        var("k", MatKind::Param { negate: Neg::None }),
    ];
    let rows = [0.0, 1.0, -1.0, 0.0, 1.0, 0.5, -0.5, 1.0];
    std::fs::write(&mat, write_mat4(&vars, 0.0, 1.0, &rows, 4, &[2.0], Precision::Double)).unwrap();
    std::fs::write(&csv, "\"time\",\"x\",\"der(x)\",\"a.der(b)\"\n0,1,-1,0\n1,0.5,-0.5,1\n").unwrap();

    let mut msgs = Collect::default();
    let mut read =
        |file: &str, omc_style, derivatives| scripting::read_variables(&mut msgs, file, true, omc_style, derivatives);
    assert_eq!(read(&mat, false, true), ["a.der(b)", "der(x)", "k", "time", "x"]);
    assert_eq!(read(&mat, true, true), ["der(a.b)", "der(x)", "k", "time", "x"]);
    assert_eq!(read(&mat, false, false), ["k", "time", "x"]);
    assert_eq!(read(&mat, true, false), ["k", "time", "x"]);
    assert_eq!(read(&csv, false, false), ["time", "x"]);
    assert_eq!(read(&csv, true, true), ["time", "x", "der(x)", "der(a.b)"]);
    assert!(msgs.0.is_empty(), "{:?}", msgs.0);
    scripting::close();
    std::fs::remove_dir_all(d).unwrap();
}

#[test]
fn csv_compare_tubes_keep_an_event_at_the_start_of_the_reference() {
    let d = dir("start_event");
    let actual = path(&d, "actual.csv");
    let reference = path(&d, "reference.csv");
    std::fs::write(&actual, "time,x\n0,0\n1e-9,0\n1e-9,1\n0.5,1\n1,1\n").unwrap();
    std::fs::write(&reference, "time,x\n0,0\n0,1\n0.5,1\n1,1\n").unwrap();
    let mut a = ResultFile::open(&actual).unwrap();
    let mut r = ResultFile::open(&reference).unwrap();
    let rectangle = Tolerances {
        algorithm: Algorithm::Rectangle,
        ..Tolerances::default()
    };
    assert!(diff_all(&mut a, &mut r, Vec::new(), rectangle).unwrap().is_empty());
    std::fs::remove_dir_all(d).unwrap();
}
