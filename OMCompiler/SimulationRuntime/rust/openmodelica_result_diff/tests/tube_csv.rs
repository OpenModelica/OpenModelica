use openmodelica_result_diff::{Algorithm, Settings, compare, tube_csv};

#[test]
fn a_rectangle_csv_keeps_both_timelines_in_order() {
    let reftime = [0.0, 1.0, 2.0, 3.0];
    let refvalues = [0.0; 4];
    let time = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0];
    let values = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0];
    let settings = Settings {
        algorithm: Algorithm::Rectangle,
        ..Settings::default()
    };
    let c = compare(&time, &values, &reftime, &refvalues, &settings).unwrap();
    assert!(c.differs());
    let csv = tube_csv(&time, &values, &c);
    let rows: Vec<Vec<&str>> = csv
        .lines()
        .skip(1)
        .filter(|l| !l.is_empty())
        .map(|l| l.split(',').collect())
        .collect();
    let times: Vec<f64> = rows.iter().map(|r| r[0].parse().unwrap()).collect();
    assert_eq!(times, time, "{csv}");
    assert!(rows.iter().all(|r| r.len() == 7), "{csv}");
    assert_eq!(rows.iter().filter(|r| !r[1].is_empty()).count(), reftime.len(), "{csv}");
    let spike = &rows[3];
    assert_eq!((spike[2], spike[1]), ("1", ""), "{csv}");
    assert!(spike[5].parse::<f64>().unwrap() > 0.0, "{csv}");
}
