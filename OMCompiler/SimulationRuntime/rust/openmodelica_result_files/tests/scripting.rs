//! The scripting functions on small files written here.

use std::path::PathBuf;

use openmodelica_mat_writer::{MatKind, MatVar, Neg, Precision, write_mat4};
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
        scripting::read_variables(&mut msgs, &output, true, false),
        ["k", "time", "x"]
    );
    assert_eq!(scripting::val(&mut msgs, &output, "x", 1.0), 0.5);
    assert_eq!(scripting::val(&mut msgs, &output, "k", 1.0), 2.0);
    assert!(msgs.0.is_empty(), "{:?}", msgs.0);
    std::fs::remove_dir_all(d).unwrap();
}
