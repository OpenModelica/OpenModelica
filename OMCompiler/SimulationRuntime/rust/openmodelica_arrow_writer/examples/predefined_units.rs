//! Writes the predefined units of `arrow.modelica` format version 1 as the
//! `modelica.units` and `modelica.displayUnits` tables a file would carry if it
//! spelled them all out.
//!
//!     cargo run --example predefined_units -- predefined-units.arrow
//!
//! The specification does not list the definitions, because a table copied into
//! prose drifts from the code that implements it. This is the same data, from
//! the same `units::predefined_units()` a writer uses to decide what it may
//! leave out, in the format an implementer is going to read anyway.

use std::fs::File;
use std::io::BufWriter;
use std::sync::Arc;

use arrow_array::{ArrayRef, BooleanArray, Float64Array, Int32Array, RecordBatch, StringArray};
use arrow_ipc::CompressionType;
use arrow_ipc::writer::{IpcWriteOptions, StreamWriter};
use arrow_schema::{DataType, Field, Schema, SchemaRef};
use openmodelica_arrow_writer::units::{BASE_EXPONENTS, predefined_units};

fn main() {
    let path = std::env::args().nth(1).unwrap_or_else(|| "predefined-units.arrow".to_owned());
    let units: Vec<_> = predefined_units().collect();

    let mut name = Vec::new();
    let mut exponents: Vec<Vec<Option<i32>>> = vec![Vec::new(); BASE_EXPONENTS.len()];
    let (mut factor, mut offset) = (Vec::new(), Vec::new());
    let (mut d_unit, mut d_name, mut d_factor, mut d_offset, mut d_inverse) =
        (Vec::new(), Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for (i, u) in units.iter().enumerate() {
        name.push(u.name.clone());
        for (e, out) in exponents.iter_mut().enumerate() {
            out.push(u.base.as_ref().map(|b| b.exponents[e]));
        }
        factor.push(u.base.as_ref().map(|b| b.factor));
        offset.push(u.base.as_ref().map(|b| b.offset));
        for d in &u.display_units {
            d_unit.push(i as i32);
            d_name.push(d.name.clone());
            d_factor.push((d.factor != 1.0).then_some(d.factor));
            d_offset.push((d.offset != 0.0).then_some(d.offset));
            d_inverse.push(d.inverse.then_some(true));
        }
    }

    let mut cols: Vec<ArrayRef> = vec![Arc::new(StringArray::from(name))];
    for e in exponents {
        cols.push(Arc::new(Int32Array::from(e)));
    }
    cols.push(Arc::new(Float64Array::from(factor)));
    cols.push(Arc::new(Float64Array::from(offset)));

    let display: Vec<ArrayRef> = vec![
        Arc::new(Int32Array::from(d_unit)),
        Arc::new(StringArray::from(d_name)),
        Arc::new(Float64Array::from(d_factor)),
        Arc::new(Float64Array::from(d_offset)),
        Arc::new(BooleanArray::from(d_inverse)),
    ];

    let file = BufWriter::new(File::create(&path).expect("create"));
    let file = write(file, units_schema(), cols, "units");
    let file = write(file, display_schema(), display, "displayUnits");
    drop(file);
    println!(
        "{path}: {} units, {} display units",
        units.len(),
        units.iter().map(|u| u.display_units.len()).sum::<usize>()
    );
}

/// One stream per table, as the format has it, so the output is a file rather
/// than two of them. Compressed, because there is no reason for a reference
/// artefact to be bigger than it has to be.
fn write<W: std::io::Write>(out: W, schema: SchemaRef, cols: Vec<ArrayRef>, what: &str) -> W {
    let batch = RecordBatch::try_new(schema.clone(), cols)
        .unwrap_or_else(|e| panic!("{what}: {e}"));
    let opts = IpcWriteOptions::default()
        .try_with_compression(Some(CompressionType::ZSTD))
        .unwrap_or_else(|e| panic!("{what}: {e}"));
    let mut w = StreamWriter::try_new_with_options(out, &schema, opts)
        .unwrap_or_else(|e| panic!("{what}: {e}"));
    w.write(&batch).unwrap_or_else(|e| panic!("{what}: {e}"));
    w.finish().unwrap_or_else(|e| panic!("{what}: {e}"));
    w.into_inner().unwrap_or_else(|e| panic!("{what}: {e}"))
}

fn units_schema() -> SchemaRef {
    let mut fields = vec![Field::new("name", DataType::Utf8, false)];
    for e in BASE_EXPONENTS {
        fields.push(Field::new(e, DataType::Int32, true));
    }
    fields.push(Field::new("factor", DataType::Float64, true));
    fields.push(Field::new("offset", DataType::Float64, true));
    Arc::new(Schema::new_with_metadata(fields, table("units")))
}

fn display_schema() -> SchemaRef {
    Arc::new(Schema::new_with_metadata(
        vec![
            Field::new("unit", DataType::Int32, false),
            Field::new("name", DataType::Utf8, false),
            Field::new("factor", DataType::Float64, true),
            Field::new("offset", DataType::Float64, true),
            Field::new("inverse", DataType::Boolean, true),
        ],
        table("displayUnits"),
    ))
}

fn table(name: &str) -> std::collections::HashMap<String, String> {
    std::collections::HashMap::from([("modelica.table".to_owned(), name.to_owned())])
}
