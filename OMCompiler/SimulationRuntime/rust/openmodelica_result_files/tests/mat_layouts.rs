//! `write_mat4`'s binNormal file reads back like the binTrans one `Mat4Stream`
//! writes for a simulation.

use openmodelica_mat_reader::MatReader;
use openmodelica_mat_writer::{Mat4Stream, MatKind, MatVar, Neg, Precision, write_mat4};

#[test]
fn whole_and_streamed_files_agree() {
    let var = |name, kind, unvarying| MatVar {
        name,
        comment: "c",
        kind,
        unvarying,
    };
    let vars = [
        var("time", MatKind::Time, false),
        var(
            "x",
            MatKind::Column {
                col: 1,
                negate: Neg::None,
            },
            false,
        ),
        var(
            "y",
            MatKind::Column {
                col: 1,
                negate: Neg::Arith,
            },
            false,
        ),
        var(
            "b",
            MatKind::Column {
                col: 2,
                negate: Neg::Not,
            },
            false,
        ),
        var(
            "u",
            MatKind::Column {
                col: 3,
                negate: Neg::None,
            },
            true,
        ),
        var("p", MatKind::Param { negate: Neg::None }, false),
        var("k", MatKind::Const { value: 4.5 }, false),
    ];
    let rows = [
        0.0, 1.0, 0.0, 9.0, 0.5, 2.0, 1.0, 9.0, 0.5, 3.0, 1.0, 9.0, 1.0, 5.0, 0.0, 9.0,
    ];
    for precision in [Precision::Double, Precision::Single] {
        let whole = write_mat4(&vars, 0.0, 1.0, &rows, 4, &[2.5], precision);
        let mut streamed = Vec::new();
        let mut s = Mat4Stream::begin(&mut streamed, &vars, 0.0, 1.0, &rows[..4], 4, &[2.5], precision);
        s.push_rows(&mut streamed, &rows);
        s.finish(&mut streamed);
        // Aclass is the first matrix: a 20-byte header, its name, then 4 x 11 chars.
        let order = |f: &[u8]| {
            (0..11)
                .map(|c| f[20 + 7 + c * 4 + 3])
                .filter(|&b| b != 0)
                .collect::<Vec<u8>>()
        };
        assert_eq!(
            (order(&whole), order(&streamed)),
            (b"binNormal".to_vec(), b"binTrans".to_vec())
        );
        let open = |bytes: &[u8], tag: &str| {
            let path = std::env::temp_dir().join(format!("omc_mat_layouts_{tag}_{}.mat", std::process::id()));
            std::fs::write(&path, bytes).unwrap();
            let r = MatReader::open(path.to_str().unwrap()).unwrap();
            let _ = std::fs::remove_file(&path);
            r
        };
        let (mut a, mut b) = (open(&whole, "whole"), open(&streamed, "streamed"));
        assert_eq!(
            (a.nrows, a.nvar, &a.params),
            (b.nrows, b.nvar, &b.params),
            "{precision:?}"
        );
        for i in 0..vars.len() {
            let (va, vb) = (a.allInfo[i].clone(), b.allInfo[i].clone());
            assert_eq!(
                (&va.name, &va.descr, va.isParam, va.index),
                (&vb.name, &vb.descr, vb.isParam, vb.index)
            );
            if !va.isParam {
                assert_eq!(a.read_vals(va.index), b.read_vals(vb.index), "{}", va.name);
            }
            for t in [0.0, 0.25, 0.5, 1.0] {
                assert_eq!(a.val(i, t), b.val(i, t), "{} at {t}", va.name);
            }
        }
        let x = a.find_var("x").unwrap();
        assert_eq!(a.read_vals(a.allInfo[x].index), Some(vec![1.0, 2.0, 3.0, 5.0]));
    }
}
