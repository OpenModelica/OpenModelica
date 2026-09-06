# `arrow.modelica` — a result file format

A simulation result as Apache Arrow: the trajectories as typed columns, and
everything needed to interpret them as ordinary Arrow tables beside them.

Nothing in the layout is specific to OpenModelica. It is meant to carry a
Modelica result or an FMI one, and to be readable by any Arrow implementation
without a Modelica tool in the loop.

`modelica.format` is **`1`**.

---

## 1. The container

A file is a sequence of Arrow IPC **streams**, one per table, followed by a
16-byte trailer:

```
[ modelica.variables   ]   required, first
[ modelica.units       ]   optional
[ modelica.enumerations]   optional
[ modelica.parameters  ]   optional
[ modelica.data        ]   required
[ modelica.index       ]   optional, last before the trailer
[ u64 little-endian    ]   byte offset of modelica.index
[ "MODELICA"           ]   the run finished
```

Each stream is a complete IPC stream — schema message, dictionary batches,
record batches, then the 8-byte end-of-stream marker — so the next one begins
where the previous ended. Concatenating streams this way is not something the
IPC spec names, but it follows from it: a reader consumes exactly the
end-of-stream marker and stops, which both arrow-rs and pyarrow do.

**A stream says what it is** in its schema metadata under `modelica.table`:
`variables`, `units`, `enumerations`, `parameters`, `data`, `index`. A reader
walks the streams and dispatches on that key; it must skip a table it does not
recognise, and must not assume a position. The order above is the order a writer
produces, and the only ordering a reader may rely on is that
`modelica.variables` comes first and `modelica.data` after every table it
refers to.

A reader that only wants to know what is in the file reads the first stream and
stops.

### Why not one Arrow IPC *file*

An IPC file (the `ARROW1` magic and a footer) has exactly one schema, so a
second table is not expressible; and it stores that schema **twice**, once as
the leading message and once inside the footer. On a 5535-variable model with
the variable table in schema metadata that came to 1,538,914 bytes of schema in
a 5,097,898-byte file — 30% of it, none of it compressible, because Arrow never
compresses schema metadata.

The footer buys batch-level random access, which `modelica.index` restores. It
buys no *column* random access: a projected read still reads every batch body it
crosses whole, in either layout. Arrow IPC has no column-level random access at
all.

The cost is that a generic tool opening the file with a *file* reader fails, and
with a *stream* reader sees the first table only — which, the variable table
being first, is a readable listing of what the file holds.

### The trailer

The last 16 bytes are the byte offset of `modelica.index` and the ASCII mark
`MODELICA`. A file without them is a run that did not finish; it is still
readable forward, one stream at a time, up to the last complete record batch.

---

## 2. `modelica.variables` — required, first

One row per result variable, in the order the writer lists them. This is what
`dataInfo` is in the MATv4 file, plus each variable's own metadata.

| column        | type      | null | meaning |
|---------------|-----------|------|---------|
| `name`        | `Utf8`    | no   | The variable's name. |
| `description` | `Utf8`    | yes  | Free text. Null and empty mean the same. |
| `unit`        | `Utf8`    | yes  | A name into `modelica.units` or the predefined set. |
| `displayUnit` | `Utf8`    | yes  | The `name` of one of the `displayUnits` of `unit`. |
| `column`      | `Int32`   | yes  | Field index in `modelica.data` holding the values. |
| `scale`       | `Float64` | yes  | Default `1`. |
| `offset`      | `Float64` | yes  | Default `0`. |
| `parameter`   | `Int32`   | yes  | Row index in `modelica.parameters` holding the value. |
| `relativeQuantity` | `Boolean` | yes | Default `false`. |

A row names **either** a `column` **or** a `parameter`, and that alone tells a
time-variant variable from a parameter. Nothing else distinguishes them, and in
particular nothing distinguishes the time variable: `time` is column 0, and the
time variable and any alias of it simply name it.

**Aliases.** Several rows may name the same `column`: the value is
`scale * column + offset` and the data is stored once. A negated `Real` or
`Integer` alias is `scale = -1`; a negated `Boolean` alias is `scale = -1,
offset = 1`, which over the 0/1 encoding is the logical negation. A writer need
only detect those; a reader must apply any `scale` and `offset` it finds.

**`relativeQuantity`** says the value is a difference in its unit, so converting
it to another unit applies the factor and drops the offset.

There is **no `type` column**: a variable that names a `column` has that
column's Arrow type, and one that names a `parameter` has the type of whichever
value column of that row is non-null.

The schema metadata of this stream carries the file's own keys:

| key                    | meaning |
|------------------------|---------|
| `modelica.table`       | `variables` |
| `modelica.format`      | The layout version, `1`. |
| `modelica.startTime`   | Decimal. What `data_1(:,1)` holds in the MATv4 file. |
| `modelica.stopTime`    | Decimal. The time column may end past it, when the last output point is an event. |

---

## 3. `modelica.units` — optional

The units the file has to spell out. Everything in *Predefined units* below may
be left out, and a file whose variables all name predefined units has no units
stream at all.

An entry carries **only what it declares**, and a reader **adds** the predefined
display units of the same name to it. So a unit that has to be spelled out for
one display unit the predefined set lacks does not repeat the twenty it already
has — which is what makes prefixing every unit affordable.

Where an entry's `baseUnit` disagrees with the predefined one of that name they
are different units that happen to share a name: the entry stands alone and
nothing is merged into it. That is how a writer says it means something else by
a name.

| column   | type      | null | meaning |
|----------|-----------|------|---------|
| `name`   | `Utf8`    | no   | The unit name a variable's `unit` matches. |
| `kg` `m` `s` `A` `K` `mol` `cd` `rad` | `Int32` | yes | Base-unit exponents. Null means the whole `baseUnit` is absent — a unit whose dimensions the writer could not derive. |
| `factor` | `Float64` | yes  | Default `1`. |
| `offset` | `Float64` | yes  | Default `0`. |

`v_SI = factor * v_unit + offset`, over FMI 3.0's `<BaseUnit>` exponents.

A **display unit** belongs to the unit it displays and is not itself a unit; no
variable may name one as its `unit`. Display units live in a separate optional
table, `modelica.displayUnits`, so that this one stays flat:

| column    | type      | null | meaning |
|-----------|-----------|------|---------|
| `unit`    | `Int32`   | no   | Row index in `modelica.units`, or into the predefined set when this file does not redefine it. |
| `name`    | `Utf8`    | no   | The display unit's name. |
| `factor`  | `Float64` | yes  | Default `1`. |
| `offset`  | `Float64` | yes  | Default `0`. |
| `inverse` | `Boolean` | yes  | Default `false`. |

`v_display = factor * v_unit + offset`, or `factor * (1 / v_unit)` when
`inverse` — which FMI allows only with a zero offset, and which is meant for
reciprocal units such as Siemens, not a re-association.

### Predefined units

Every reader of `modelica.format` version 1 knows these without the file saying
anything. The set is tied to the version: growing it would leave an older reader
not knowing a unit a newer writer omitted, so it may only grow together with the
version.

Forty-two units and 576 display units — every SI prefix on each of the base and
named derived units, together with the ones that are not a prefix at all
(`degC`, `deg`, `min`, `h`, `d`, `bar`, `t`, `l`, `ml`, `rpm`, `rev/min`,
`1/min`, `deg/s`, `km/h`, `g/cm3`, `l/s`):

> `1`
> `kg` `m` `s` `A` `K` `mol` `cd` `rad`
> `sr` `Hz` `N` `Pa` `J` `W` `C` `V` `F` `Ohm` `S` `Wb` `T` `H` `lm` `lx` `Bq`
> `Gy` `Sv` `kat`
> `m/s` `m/s2` `m2` `m3` `m3/s` `kg/s` `kg/m3` `rad/s` `N.m`
> `J/K` `J/(kg.K)` `W/(m.K)` `W/(m2.K)`

The **definitions** are not written out here, because a table copied into prose
drifts from the code that implements it. They are generated, as the two tables a
file would carry if it spelled them all out:

```
cargo run --example predefined_units -- predefined-units.arrow
```

That is 7.5 KB compressed, from the same `units::predefined_units()` a writer
uses to decide what it may leave out, and it is the normative form: an implementer reads it
with the Arrow library they are already using rather than transcribing a table.

OpenModelica has no `rad` dimension and computes `0` for it, so the `rad`
exponents there are FMI's, which treats `rad` as `1` for dimensional analysis.

---

## 4. `modelica.enumerations` — optional

The literals of every enumeration type the file uses. A type is identified by
its ordered literal list alone, so two variables listing the same literals share
one entry.

| column        | type    | null | meaning |
|---------------|---------|------|---------|
| `enumeration` | `Int32` | no   | Which type. Rows of one type are contiguous and in declaration order. |
| `literal`     | `Utf8`  | no   | The literal name. The first literal of a type is Modelica value `1`. |

A file with no enumeration variable has no enumerations stream.

Enumeration **values** are stored either way:

* as an `Int32` column or parameter holding the Modelica value, together with an
  `enumeration` index — the form to use when the writer cannot share one
  dictionary between columns;
* as a `Dictionary<Int32, Utf8>` whose dictionary is that literal list and whose
  key is the value minus one.

A reader must accept both. The dictionary form is preferable, and the IPC format
supports doing it once for a whole type: *"The dictionary id in the message
metadata can be referenced one or more times in the schema, so that dictionaries
can even be used for multiple fields."* Neither arrow-rs nor pyarrow will
**write** that — both hand out one id per dictionary-typed field — so a writer
that wants it emits the IPC messages itself; both **read** it, resolving a
field's dictionary by id.

---

## 5. `modelica.parameters` — optional

The values of every variable that has no column: what `data_1` is in the MATv4
file. Row order is what the variable table's `parameter` indexes.

| column        | type      | null | meaning |
|---------------|-----------|------|---------|
| `real`        | `Float64` | yes  | |
| `int`         | `Int32`   | yes  | |
| `bool`        | `Boolean` | yes  | |
| `string`      | `Utf8`    | yes  | |
| `enumeration` | `Int32`   | yes  | The `enumeration` index; the value is in `int`. |

**Exactly one value column is non-null per row, and which one it is is the
variable's type.** That is why no table carries a `type` string.

A writer may add a value column for any other Arrow type it needs — an FMI
exporter writing `Float32` or `UInt64` — and a reader takes the type from
whichever column it finds.

This is one column per **type**, not one per parameter as the MATv4 file has it.
One field per parameter would move every name out of a compressible string array
and into a flatbuffer field name: measured on a 2614-parameter model, 2614
fields cost 326,008 bytes of schema, which no codec compresses, against 16,288
bytes for the same values as rows under ZSTD.

Variables computed once during initialization are parameters here, as in
`data_1` — including one that *could* have changed but did not. The file records
the trajectory, not the declaration. In FMI's terms `constant` and `fixed`
variables are parameters; `discrete` and `tunable` ones have a column.

---

## 6. `modelica.data` — required

The trajectories. Field *i* of this schema is column *i* of the variable table.

Field 0 is `time`. Every other field is one **stored** time-variant signal; a
variable that is an affine function of a stored one has no field of its own.

Fields are named `c0`, `c1`, … by position, and carry no metadata. The variable
table is the only naming authority: several variables may share a column, so a
field could carry only one of their names, and a name there would be paid twice
over — once in the schema, which no codec can compress, and once in the variable
table, which one can. On a 754-column model that was 20,522 bytes of schema
against 2,906.

Nobody is deprived of it. A tool that opens the file with a plain stream reader
sees the **first** stream, `modelica.variables`, and stops — a readable listing
of what the file holds. Anything that reaches this stream has walked the streams
by `modelica.table`, and so has the variable table already.

The rows are written as record batches as the simulation produces them: one row
per output point, plus one per event.

### Column types

A column holds its variable's values in the Arrow type matching the variable's
own, so the whole range of FMI variable types is expressible:

| variable | Arrow column type |
|----------|-------------------|
| FMI `Float64`, Modelica `Real` | `Float64`, or `Float32` under `-single` |
| FMI `Float32` | `Float32` |
| FMI `Int8`…`Int64`, `UInt8`…`UInt64`, Modelica `Integer` | the same type |
| FMI `Boolean` or `Clock`, Modelica `Boolean` | `Boolean` |
| FMI `String`, Modelica `String` | `Utf8` |
| FMI `Binary` | `Binary` |
| an enumeration | `Int32`, or `Dictionary<Int32, Utf8>` |

Types are named the way Arrow names them, this being an Arrow file: there is no
second vocabulary to translate. OpenModelica writes the subset a Modelica model
needs — `Float64`, `Int32`, `Boolean`, `Utf8` — and a reader should accept the
rest, since a writer describing an FMU has them.

### Discrete-time variables

A variable whose value changes only at events is stored run-end encoded,
`RunEndEncoded<Int32, T>` over the type above: one value per change together
with the row index where that value ends, indexed against the shared `time`
column. Expanding the runs gives the value at every row with hold semantics,
which Arrow readers do on request (`pyarrow.compute.run_end_decode`).

**The encoding is the statement.** A run-end encoded column is a discrete-time
variable and must be held between its stored points; any other column may change
at every row. Nothing in any table repeats this, so there is nothing that can
disagree with it.

This is independent of type: an `Integer` that varies at every row is a plain
`Int32` column, and a `Real` that changes only at events is run-end encoded.

Run-end encoded columns were added in **Arrow columnar format 1.3** (Arrow
12.0), so a file holding one needs an implementation of that version. A file
without one needs only 1.0. The version is not recorded — the IPC metadata
version has been `V5` since Arrow 1.0 — so an older reader fails on the column
type rather than on a version check.

---

## 7. `modelica.index` — optional, last

The byte offset of every record batch of `modelica.data`, so a reader can seek
to a batch instead of walking to it.

| column   | type      | null | meaning |
|----------|-----------|------|---------|
| `offset` | `Float64` | no   | Byte offset from the start of the file. |

It does not help a full-trajectory read, which crosses every batch anyway. It is
for a time-window query, and for telling a finished file from a truncated one.

---

## Reading one, with pyarrow

```python
import pyarrow as pa, pyarrow.ipc as ipc, pyarrow.compute as pc

tables = {}
src = pa.OSFile("Model_res.arrow", "rb")
while True:
    try:
        reader = ipc.open_stream(src)
    except pa.ArrowInvalid:          # past the last stream: the trailer
        break
    md = {k.decode(): v.decode() for k, v in (reader.schema.metadata or {}).items()}
    tables[md.get("modelica.table")] = reader.read_all()

variables, data = tables["variables"], tables["data"]
row = variables.filter(pc.equal(variables["name"], "y")).to_pylist()[0]
if row["column"] is not None:
    values = data.column(row["column"])
    if isinstance(values.type, pa.RunEndEncodedType):
        values = pc.run_end_decode(values)
    values = pc.add(pc.multiply(values, row["scale"] or 1.0), row["offset"] or 0.0)
else:
    p = tables["parameters"].slice(row["parameter"], 1).to_pylist()[0]
    values = next(v for v in p.values() if v is not None)
```

---

## What OpenModelica writes

`outputFormat="arrow"` (`-outputFormat=arrow`). A file written by the C runtime
carries no `modelica.units`: the runtime reads its variable attributes from
`<model>_init.xml`, which names each variable's unit but defines none.

Under `-mat_sync=N` a batch holds at most `N` rows and reaches the file as soon
as it is complete, so the file can be read while the simulation runs. Such a
file has no trailer and no `modelica.index` yet; it is read forward, up to the
last complete batch.
