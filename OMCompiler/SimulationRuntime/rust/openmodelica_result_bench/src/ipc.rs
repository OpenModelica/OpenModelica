//! Just enough Arrow IPC to write a stream whose dictionary-encoded fields can
//! name the *same* dictionary.
//!
//! The Arrow columnar spec is explicit that they may: "The dictionary id in the
//! message metadata can be referenced one or more times in the schema, so that
//! dictionaries can even be used for multiple fields." Neither arrow-rs nor
//! pyarrow will write that, though - both hand out one id per dictionary-typed
//! field as they walk the schema (`DictionaryTracker::next_dict_id`), so two
//! columns of one Modelica enumeration type carry two copies of its literals.
//!
//! Writing the messages here costs less than it sounds: `arrow_ipc::gen` is
//! public, so the flatbuffer types are arrow-rs's own, and `write_message`
//! frames and pads. What this module adds is the schema, the record batch and
//! the dictionary batch headers, and the body layout behind them - for the five
//! column types a result file needs and nothing else.

use std::io::Write;

use arrow_ipc::writer::{EncodedData, IpcWriteOptions, write_message};
use arrow_schema::ArrowError;
use flatbuffers::{FlatBufferBuilder, WIPOffset};

/// A column type, as it appears in the schema.
///
/// `Utf8` and `Dict` are the enumeration path, which nothing builds yet - the
/// input carries no literals (see `crate::arrow_modelica`) - so the tests below
/// are what exercise them.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
#[allow(dead_code)]
pub enum Ty {
    F64,
    I32,
    Bool,
    Utf8,
    /// `Dictionary<Int32, Utf8>` reading the dictionary with this id. Several
    /// fields may name one id; that is the whole point of the module.
    Dict(i64),
}

pub struct FieldSpec {
    pub name: String,
    pub ty: Ty,
    pub nullable: bool,
}

/// One column of one record batch. `Codes` is the index array of a [`Ty::Dict`]
/// field; the literals travel once, in a dictionary batch.
#[allow(dead_code)]
pub enum Col<'a> {
    F64(&'a [f64]),
    I32(&'a [i32]),
    Bool(&'a [bool]),
    Utf8(&'a [String]),
    Codes(&'a [i32]),
}

impl Col<'_> {
    fn len(&self) -> usize {
        match self {
            Col::F64(v) => v.len(),
            Col::I32(v) | Col::Codes(v) => v.len(),
            Col::Bool(v) => v.len(),
            Col::Utf8(v) => v.len(),
        }
    }
}

/// The body of a message: the buffers back to back, each padded, and the
/// `(offset, length)` pairs the header needs to find them again.
///
/// Under a codec each buffer becomes `[i64 uncompressed length][codec bytes]`,
/// which is what `BodyCompression` with `method: BUFFER` means; an empty buffer
/// stays empty and carries no prefix.
#[derive(Default)]
struct Body {
    bytes: Vec<u8>,
    buffers: Vec<arrow_ipc::Buffer>,
}

/// One compressor for the writer's whole life, as arrow-rs does it:
/// `zstd::encode_all` builds one per call, and a result file is thousands of
/// small buffers.
type Zstd = Option<zstd::bulk::Compressor<'static>>;

impl Body {
    /// Buffers are 8-aligned, which is what the spec asks and what keeps an
    /// `f64` buffer directly addressable in the reader's copy of the body.
    const ALIGN: usize = 8;
    /// The body as a whole is padded to arrow-rs's default write alignment,
    /// which its writer insists on before it will frame a message.
    const BODY_ALIGN: usize = 64;

    /// Pad the tail; call once, when every buffer is in.
    fn seal(mut self) -> Body {
        let pad = self.bytes.len().next_multiple_of(Self::BODY_ALIGN) - self.bytes.len();
        self.bytes.extend(std::iter::repeat_n(0u8, pad));
        self
    }

    fn push(&mut self, data: &[u8], zstd: &mut Zstd) {
        let offset = self.bytes.len() as i64;
        match zstd {
            Some(c) if !data.is_empty() => {
                self.bytes.extend_from_slice(&(data.len() as i64).to_le_bytes());
                self.bytes.extend_from_slice(&c.compress(data).expect("zstd"));
            }
            _ => self.bytes.extend_from_slice(data),
        }
        let len = self.bytes.len() as i64 - offset;
        self.buffers.push(arrow_ipc::Buffer::new(offset, len));
        let pad = self.bytes.len().next_multiple_of(Self::ALIGN) - self.bytes.len();
        self.bytes.extend(std::iter::repeat_n(0u8, pad));
    }

    /// A validity buffer for a column with no nulls: the spec keeps the slot
    /// and gives it no bytes.
    fn none(&mut self, zstd: &mut Zstd) {
        self.push(&[], zstd);
    }

    fn column(&mut self, col: &Col<'_>, zstd: &mut Zstd) {
        self.none(zstd);
        match col {
            Col::F64(v) => self.push(as_bytes(v), zstd),
            Col::I32(v) | Col::Codes(v) => self.push(as_bytes(v), zstd),
            Col::Bool(v) => {
                let mut bits = vec![0u8; v.len().div_ceil(8)];
                for (i, b) in v.iter().enumerate() {
                    if *b {
                        bits[i / 8] |= 1 << (i % 8);
                    }
                }
                self.push(&bits, zstd);
            }
            Col::Utf8(v) => {
                let mut offsets: Vec<i32> = Vec::with_capacity(v.len() + 1);
                let mut at = 0i32;
                offsets.push(0);
                for s in *v {
                    at += s.len() as i32;
                    offsets.push(at);
                }
                self.push(as_bytes(&offsets), zstd);
                let mut values = Vec::with_capacity(at as usize);
                for s in *v {
                    values.extend_from_slice(s.as_bytes());
                }
                self.push(&values, zstd);
            }
        }
    }
}

fn as_bytes<T>(v: &[T]) -> &[u8] {
    // SAFETY: every element type here is a plain scalar with no padding, and
    // the result is only ever written out.
    unsafe { std::slice::from_raw_parts(v.as_ptr().cast::<u8>(), std::mem::size_of_val(v)) }
}

pub struct StreamWriter<W: Write> {
    out: W,
    opts: IpcWriteOptions,
    zstd: Zstd,
    finished: bool,
}

impl<W: Write> StreamWriter<W> {
    /// Writes the schema message; the stream is open from here.
    pub fn new(
        mut out: W,
        fields: &[FieldSpec],
        metadata: &[(&str, String)],
        zstd: Option<i32>,
    ) -> Result<StreamWriter<W>, ArrowError> {
        let opts = IpcWriteOptions::default();
        let message = schema_message(fields, metadata);
        write_message(&mut out, EncodedData { ipc_message: message, arrow_data: Vec::new() }, &opts)?;
        let zstd = zstd
            .map(zstd::bulk::Compressor::new)
            .transpose()
            .map_err(|e| ArrowError::ExternalError(Box::new(e)))?;
        Ok(StreamWriter { out, opts, zstd, finished: false })
    }

    /// The literals behind one dictionary id. Every field that names the id
    /// reads these, and it is sent once.
    #[allow(dead_code)]
    pub fn dictionary(&mut self, id: i64, values: &[String]) -> Result<(), ArrowError> {
        let mut body = Body::default();
        body.column(&Col::Utf8(values), &mut self.zstd);
        let body = body.seal();
        let message = dictionary_message(id, values.len(), &body, self.zstd.is_some());
        write_message(
            &mut self.out,
            EncodedData { ipc_message: message, arrow_data: body.bytes },
            &self.opts,
        )?;
        Ok(())
    }

    pub fn batch(&mut self, cols: &[Col<'_>]) -> Result<(), ArrowError> {
        let rows = cols.first().map_or(0, Col::len);
        if let Some(bad) = cols.iter().find(|c| c.len() != rows) {
            return Err(ArrowError::InvalidArgumentError(format!(
                "column of {} rows in a batch of {rows}",
                bad.len()
            )));
        }
        let mut body = Body::default();
        for col in cols {
            body.column(col, &mut self.zstd);
        }
        let body = body.seal();
        let message = record_batch_message(rows, cols.len(), &body, self.zstd.is_some());
        write_message(
            &mut self.out,
            EncodedData { ipc_message: message, arrow_data: body.bytes },
            &self.opts,
        )?;
        Ok(())
    }

    /// The end-of-stream marker, after which another stream may follow.
    pub fn finish(mut self) -> Result<W, ArrowError> {
        self.write_end()?;
        Ok(self.out)
    }

    fn write_end(&mut self) -> Result<(), ArrowError> {
        if !self.finished {
            self.out.write_all(&[0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0])?;
            self.out.flush()?;
            self.finished = true;
        }
        Ok(())
    }
}

fn schema_message(fields: &[FieldSpec], metadata: &[(&str, String)]) -> Vec<u8> {
    let mut fbb = FlatBufferBuilder::new();
    let fbs: Vec<WIPOffset<arrow_ipc::Field>> = fields.iter().map(|f| field(&mut fbb, f)).collect();
    let fields_vec = fbb.create_vector(&fbs);
    let meta = key_values(&mut fbb, metadata);
    let schema = arrow_ipc::Schema::create(
        &mut fbb,
        &arrow_ipc::SchemaArgs {
            endianness: arrow_ipc::Endianness::Little,
            fields: Some(fields_vec),
            custom_metadata: meta,
            features: None,
        },
    );
    message(fbb, arrow_ipc::MessageHeader::Schema, schema.as_union_value(), 0)
}

fn field<'a>(
    fbb: &mut FlatBufferBuilder<'a>,
    spec: &FieldSpec,
) -> WIPOffset<arrow_ipc::Field<'a>> {
    let name = fbb.create_string(&spec.name);
    let children = fbb.create_vector::<WIPOffset<arrow_ipc::Field>>(&[]);
    // A dictionary-encoded field carries the *value* type here; the index type
    // rides in the DictionaryEncoding, as arrow-rs's own encoder does it.
    let (kind, ty) = match spec.ty {
        Ty::F64 => {
            let b = arrow_ipc::FloatingPoint::create(
                fbb,
                &arrow_ipc::FloatingPointArgs { precision: arrow_ipc::Precision::DOUBLE },
            );
            (arrow_ipc::Type::FloatingPoint, b.as_union_value())
        }
        Ty::I32 => {
            let b = arrow_ipc::Int::create(
                fbb,
                &arrow_ipc::IntArgs { bitWidth: 32, is_signed: true },
            );
            (arrow_ipc::Type::Int, b.as_union_value())
        }
        Ty::Bool => {
            let b = arrow_ipc::Bool::create(fbb, &arrow_ipc::BoolArgs {});
            (arrow_ipc::Type::Bool, b.as_union_value())
        }
        Ty::Utf8 | Ty::Dict(_) => {
            let b = arrow_ipc::Utf8::create(fbb, &arrow_ipc::Utf8Args {});
            (arrow_ipc::Type::Utf8, b.as_union_value())
        }
    };
    let dictionary = match spec.ty {
        Ty::Dict(id) => {
            let index = arrow_ipc::Int::create(
                fbb,
                &arrow_ipc::IntArgs { bitWidth: 32, is_signed: true },
            );
            Some(arrow_ipc::DictionaryEncoding::create(
                fbb,
                &arrow_ipc::DictionaryEncodingArgs {
                    id,
                    indexType: Some(index),
                    isOrdered: false,
                    dictionaryKind: arrow_ipc::DictionaryKind::DenseArray,
                },
            ))
        }
        _ => None,
    };
    arrow_ipc::Field::create(
        fbb,
        &arrow_ipc::FieldArgs {
            name: Some(name),
            nullable: spec.nullable,
            type_type: kind,
            type_: Some(ty),
            dictionary,
            children: Some(children),
            custom_metadata: None,
        },
    )
}

fn record_batch_message(rows: usize, n_cols: usize, body: &Body, zstd: bool) -> Vec<u8> {
    let mut fbb = FlatBufferBuilder::new();
    let batch = record_batch(&mut fbb, rows, n_cols, body, zstd);
    message(fbb, arrow_ipc::MessageHeader::RecordBatch, batch.as_union_value(), body.bytes.len())
}

#[allow(dead_code)]
fn dictionary_message(id: i64, rows: usize, body: &Body, zstd: bool) -> Vec<u8> {
    let mut fbb = FlatBufferBuilder::new();
    let data = record_batch(&mut fbb, rows, 1, body, zstd);
    let dict = arrow_ipc::DictionaryBatch::create(
        &mut fbb,
        &arrow_ipc::DictionaryBatchArgs { id, data: Some(data), isDelta: false },
    );
    message(fbb, arrow_ipc::MessageHeader::DictionaryBatch, dict.as_union_value(), body.bytes.len())
}

fn record_batch<'a>(
    fbb: &mut FlatBufferBuilder<'a>,
    rows: usize,
    n_cols: usize,
    body: &Body,
    zstd: bool,
) -> WIPOffset<arrow_ipc::RecordBatch<'a>> {
    // No nulls anywhere in a result file, so every node's null count is zero.
    let nodes: Vec<arrow_ipc::FieldNode> =
        (0..n_cols).map(|_| arrow_ipc::FieldNode::new(rows as i64, 0)).collect();
    let nodes = fbb.create_vector(&nodes);
    let buffers = fbb.create_vector(&body.buffers);
    let compression = zstd.then(|| {
        arrow_ipc::BodyCompression::create(
            fbb,
            &arrow_ipc::BodyCompressionArgs {
                codec: arrow_ipc::CompressionType::ZSTD,
                method: arrow_ipc::BodyCompressionMethod::BUFFER,
            },
        )
    });
    arrow_ipc::RecordBatch::create(
        fbb,
        &arrow_ipc::RecordBatchArgs {
            length: rows as i64,
            nodes: Some(nodes),
            buffers: Some(buffers),
            compression,
            variadicBufferCounts: None,
        },
    )
}

fn key_values<'a>(
    fbb: &mut FlatBufferBuilder<'a>,
    metadata: &[(&str, String)],
) -> Option<WIPOffset<flatbuffers::Vector<'a, flatbuffers::ForwardsUOffset<arrow_ipc::KeyValue<'a>>>>>
{
    if metadata.is_empty() {
        return None;
    }
    let kvs: Vec<_> = metadata
        .iter()
        .map(|(k, v)| {
            let key = fbb.create_string(k);
            let value = fbb.create_string(v);
            arrow_ipc::KeyValue::create(
                fbb,
                &arrow_ipc::KeyValueArgs { key: Some(key), value: Some(value) },
            )
        })
        .collect();
    Some(fbb.create_vector(&kvs))
}

fn message(
    mut fbb: FlatBufferBuilder<'_>,
    header_type: arrow_ipc::MessageHeader,
    header: WIPOffset<flatbuffers::UnionWIPOffset>,
    body_len: usize,
) -> Vec<u8> {
    let root = arrow_ipc::Message::create(
        &mut fbb,
        &arrow_ipc::MessageArgs {
            version: arrow_ipc::MetadataVersion::V5,
            header_type,
            header: Some(header),
            bodyLength: body_len as i64,
            custom_metadata: None,
        },
    );
    fbb.finish(root, None);
    fbb.finished_data().to_vec()
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use arrow_array::{Array, Float64Array, StringArray, cast::AsArray, types::Int32Type};
    use arrow_ipc::reader::StreamReader;

    use super::*;

    /// Two fields naming one dictionary: one copy of the literals in the file,
    /// and arrow-rs resolves both columns from it.
    #[test]
    fn two_fields_share_one_dictionary() {
        let literals: Vec<String> = ["red", "green", "blue"].iter().map(|s| (*s).to_owned()).collect();
        let fields = vec![
            FieldSpec { name: "t".into(), ty: Ty::F64, nullable: false },
            FieldSpec { name: "a".into(), ty: Ty::Dict(7), nullable: false },
            FieldSpec { name: "b".into(), ty: Ty::Dict(7), nullable: false },
        ];
        let mut out = Vec::new();
        {
            let mut w = StreamWriter::new(
                &mut out,
                &fields,
                &[("modelica.table", "data".to_owned())],
                None,
            )
            .unwrap();
            w.dictionary(7, &literals).unwrap();
            w.batch(&[
                Col::F64(&[0.0, 0.5, 1.0]),
                Col::Codes(&[0, 1, 2]),
                Col::Codes(&[2, 2, 0]),
            ])
            .unwrap();
            w.finish().unwrap();
        }

        // Exactly one dictionary message, whatever the field count.
        assert_eq!(count_messages(&out, arrow_ipc::MessageHeader::DictionaryBatch), 1);
        // Left behind so the same bytes can be checked against another
        // implementation; nothing reads it back here.
        let _ = std::fs::write(std::env::temp_dir().join("omc_shared_dict.arrows"), &out);

        let mut r = StreamReader::try_new(Cursor::new(&out), None).unwrap();
        assert_eq!(
            r.schema().metadata().get("modelica.table").map(String::as_str),
            Some("data")
        );
        let batch = r.next().unwrap().unwrap();
        assert_eq!(batch.num_rows(), 3);
        let time = batch.column(0).as_any().downcast_ref::<Float64Array>().unwrap();
        assert_eq!(time.values(), &[0.0, 0.5, 1.0]);
        for (col, want) in [(1, ["red", "green", "blue"]), (2, ["blue", "blue", "red"])] {
            let d = batch.column(col).as_dictionary::<Int32Type>();
            let values = d.values().as_any().downcast_ref::<StringArray>().unwrap();
            let got: Vec<&str> = d.keys().values().iter().map(|k| values.value(*k as usize)).collect();
            assert_eq!(got, want, "column {col}");
        }
    }

    #[test]
    fn every_column_type_round_trips() {
        let fields = vec![
            FieldSpec { name: "r".into(), ty: Ty::F64, nullable: false },
            FieldSpec { name: "i".into(), ty: Ty::I32, nullable: false },
            FieldSpec { name: "b".into(), ty: Ty::Bool, nullable: false },
            FieldSpec { name: "s".into(), ty: Ty::Utf8, nullable: false },
        ];
        let strings: Vec<String> = ["a", "", "long enough to cross"].iter().map(|s| (*s).to_owned()).collect();
        let mut out = Vec::new();
        {
            let mut w =
                StreamWriter::new(&mut out, &fields, &[], None).unwrap();
            w.batch(&[
                Col::F64(&[1.5, -2.0, 3.25]),
                Col::I32(&[7, -8, 9]),
                Col::Bool(&[true, false, true]),
                Col::Utf8(&strings),
            ])
            .unwrap();
            w.finish().unwrap();
        }
        let mut r = StreamReader::try_new(Cursor::new(&out), None).unwrap();
        let batch = r.next().unwrap().unwrap();
        assert_eq!(batch.column(0).as_primitive::<arrow_array::types::Float64Type>().values(), &[1.5, -2.0, 3.25]);
        assert_eq!(batch.column(1).as_primitive::<Int32Type>().values(), &[7, -8, 9]);
        let b = batch.column(2).as_boolean();
        assert_eq!((b.value(0), b.value(1), b.value(2)), (true, false, true));
        let s = batch.column(3).as_string::<i32>();
        assert_eq!((s.value(0), s.value(1), s.value(2)), ("a", "", "long enough to cross"));
    }

    /// The same bytes, through the codec: what the reader gets back must not
    /// depend on whether the buffers were compressed.
    #[test]
    fn zstd_buffers_round_trip() {
        let fields = vec![
            FieldSpec { name: "r".into(), ty: Ty::F64, nullable: false },
            FieldSpec { name: "s".into(), ty: Ty::Utf8, nullable: false },
        ];
        let values: Vec<f64> = (0..4096).map(|i| f64::from(i % 7)).collect();
        let strings: Vec<String> = (0..4096).map(|i| format!("body.joint{}.phi", i % 9)).collect();
        let mut plain = Vec::new();
        let mut small = Vec::new();
        for (out, level) in [(&mut plain, None), (&mut small, Some(6))] {
            let mut w = StreamWriter::new(&mut *out, &fields, &[], level).unwrap();
            w.batch(&[Col::F64(&values), Col::Utf8(&strings)]).unwrap();
            w.finish().unwrap();
        }
        assert!(small.len() * 4 < plain.len(), "{} vs {}", small.len(), plain.len());
        for out in [&plain, &small] {
            let mut r = StreamReader::try_new(Cursor::new(out), None).unwrap();
            let batch = r.next().unwrap().unwrap();
            assert_eq!(batch.column(0).as_primitive::<arrow_array::types::Float64Type>().values(), &values[..]);
            let s = batch.column(1).as_string::<i32>();
            assert_eq!(s.value(4095), strings[4095]);
        }
    }

    fn count_messages(blob: &[u8], want: arrow_ipc::MessageHeader) -> usize {
        let mut at = 0;
        let mut n = 0;
        while at + 8 <= blob.len() {
            let cont = u32::from_le_bytes(blob[at..at + 4].try_into().unwrap());
            let len = i32::from_le_bytes(blob[at + 4..at + 8].try_into().unwrap());
            if cont != 0xffff_ffff || len == 0 {
                break;
            }
            let meta = &blob[at + 8..at + 8 + len as usize];
            let msg = arrow_ipc::root_as_message(meta).unwrap();
            if msg.header_type() == want {
                n += 1;
            }
            at += 8 + len as usize + msg.bodyLength() as usize;
        }
        n
    }
}
