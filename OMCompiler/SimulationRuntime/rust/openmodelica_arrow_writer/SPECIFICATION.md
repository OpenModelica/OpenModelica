# `arrow.modelica` — a result file format

A simulation result as Apache Arrow: the trajectories as typed columns, and
everything needed to interpret them as ordinary Arrow tables beside them.

Nothing in the layout is specific to OpenModelica. It is meant to carry a
Modelica result or an FMI one, and to be readable by any Arrow implementation
without a Modelica tool in the loop.

This is `modelica.format` **`0.1`**.

---

## 1. The container

A file is a sequence of Arrow IPC **streams**, one per table, followed by a
16-byte trailer:

```
[ modelica.variables   ]   required, first
[ modelica.units       ]   optional
[ modelica.displayUnits]   optional
[ modelica.parameters  ]   optional
[ modelica.data        ]   required
[ modelica.index       ]   optional, last before the trailer
[ i64 little-endian    ]   byte offset of modelica.index
[ "MODELICA"           ]   the run finished
```

Each stream is a complete IPC stream — schema message, dictionary batches,
record batches, then the 8-byte end-of-stream marker — so the next one begins
where the previous ended. Concatenating streams this way is not something the
IPC spec names, but it follows from it: a reader consumes exactly the
end-of-stream marker and stops, which both arrow-rs and pyarrow do.

**A stream says what it is** in its schema metadata under `modelica.table`:
`variables`, `units`, `displayUnits`, `parameters`, `data`, `index`. A reader
walks the streams and dispatches on that key; it must skip a table it does not
recognise, and must not assume a position. The order above is the order a writer
produces, and the only ordering a reader may rely on is that
`modelica.variables` comes first and `modelica.data` after every table it
refers to.

A reader that only wants to know what is in the file reads the first stream and
stops.

### Versioning

`modelica.format` is `major.minor`, two decimal integers. A reader accepts a
file whose major version it knows. A larger minor version may add tables,
columns, value types and predefined units, none of which an older reader has to
understand, and never changes the meaning of anything an earlier minor defined.
A larger major version may.

Major version `0` is development: every change to the layout bumps the minor,
compatible or not, and a reader accepts only the exact version it was written
for. `1.0` is the first version anything is promised about.

### Why not one Arrow IPC *file*

An IPC file (the `ARROW1` magic and a footer) has exactly one schema, so a
second table is not expressible; and it stores that schema **twice**, once as
the leading message and once inside the footer, where nothing compresses it.
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

One row per result variable, in the order the writer lists them. No column is
nullable: what is absent is the empty string or the default.

| column        | type      | meaning |
|---------------|-----------|---------|
| `name`        | `Utf8`    | The variable's name. |
| `description` | `Utf8`    | Free text. |
| `unit`        | `Utf8`    | A unit name: an entry of `modelica.units`, or a predefined unit. |
| `displayUnit` | `Utf8`    | The `name` of one of the display units of `unit`. |
| `parameter`   | `Boolean` | Where `column` points: `false` is `modelica.data`, `true` is `modelica.parameters`. |
| `column`      | `Int32`   | Field index in `modelica.data`, or row index in `modelica.parameters`. |
| `scale`       | `Float64` | Default `1`. |
| `offset`      | `Float64` | Default `0`. |
| `relativeQuantity` | `Boolean` | Default `false`. |

`parameter` alone tells a time-variant variable from a parameter. Nothing else
distinguishes them, and in particular nothing distinguishes the time variable:
`time` is field 0 of `modelica.data`, and the time variable and any alias of it
simply name it.

**Aliases.** Several rows may name the same `column`: the value is
`scale * column + offset` and the data is stored once. A negated `Real` or
`Integer` alias is `scale = -1`; a negated `Boolean` alias is `scale = -1,
offset = 1`, which over the 0/1 encoding is the logical negation. A writer need
only detect those; a reader must apply any `scale` and `offset` it finds. The
value types the transformation applies to are listed under *Value types*.

**`relativeQuantity`** says the value is a difference in its unit, so converting
it to another unit applies the factor and drops the offset.

There is **no `type` column**: a variable has the Arrow type of what `column`
names — a field of `modelica.data`, or a row of `modelica.parameters`.

The schema metadata of this stream carries the file's own keys:

| key                    | meaning |
|------------------------|---------|
| `modelica.table`       | `variables` |
| `modelica.format`      | `0.1` |
| `modelica.startTime`   | Decimal. The start of the run. |
| `modelica.stopTime`    | Decimal. The time column may end past it, when the last output point is an event. |

---

## 3. Value types

Every value in the file — a field of `modelica.data`, a child of the
`modelica.parameters` union — has one of these Arrow types:

| variable | Arrow type |
|----------|------------|
| FMI `Float64`, Modelica `Real` | `Float64`, or `Float32` when stored in single precision |
| FMI `Float32` | `Float32` |
| FMI `Int8`…`Int64`, `UInt8`…`UInt64`, Modelica `Integer` | the same-named integer type |
| FMI `Boolean` or `Clock`, Modelica `Boolean` | `Boolean` |
| FMI `String`, Modelica `String` | `Utf8` |
| FMI `Binary` | `Binary` |
| an enumeration | `Dictionary<Int32, Utf8>` |

Types are named the way Arrow names them, this being an Arrow file: there is no
second vocabulary to translate.

**An enumeration** is a dictionary-encoded string: the dictionary is the
type's literal list in declaration order, and the key is the Modelica value
minus one, so the first literal is value `1`. Two variables of one enumeration
type carry the same dictionary. A writer that cannot produce dictionaries may
store an enumeration as `Int32`; the literals are then not in the file.

**`scale` and `offset`** apply to the floating-point, integer and `Boolean`
types, and the result has the type of the column: `-1 * x + 1` over a `Boolean`
is its logical negation. They do not apply to `Utf8`, `Binary` or an
enumeration; a writer writes `1` and `0` for those.

Arrow has more types than these. A writer may use them; a reader is only
required to handle the ones listed.

### Discrete-time variables

A variable whose value changes only at events is stored run-end encoded,
`RunEndEncoded<Int32, T>` over the type above: one value per change together
with the row index where that value ends, indexed against the shared `time`
column. Expanding the runs gives the value at every row with hold semantics.

**The encoding is the statement.** A run-end encoded column is a discrete-time
variable and must be held between its stored points; any other column may change
at every row. This is independent of type: an `Integer` that varies at every
row is a plain `Int32` column, and a `Real` that changes only at events is
run-end encoded.

Run-end encoded columns were added in **Arrow columnar format 1.3** (Arrow
12.0), so a file holding one needs an implementation of that version. A file
without one needs only 1.0. The version is not recorded — the IPC metadata
version has been `V5` since Arrow 1.0 — so an older reader fails on the column
type rather than on a version check.

---

## 4. `modelica.units` and `modelica.displayUnits` — optional

The units the file has to spell out. Everything in *Predefined units* below may
be left out, and a file whose variables all name predefined units has neither
stream.

An entry carries **only what it declares**, and a reader **adds** the predefined
display units of the same name to it. So a unit that has to be spelled out for
one display unit the predefined set lacks does not repeat the twenty it already
has — which is what makes prefixing every unit affordable.

Where an entry's base unit disagrees with the predefined one of that name they
are different units that happen to share a name: the entry stands alone and
nothing is merged into it. That is how a writer says it means something else by
a name.

`modelica.units`, no column nullable:

| column   | type      | meaning |
|----------|-----------|---------|
| `name`   | `Utf8`    | The unit name a variable's `unit` matches. |
| `baseUnit` | `Boolean` | Whether the next ten columns are given. `false` is a unit whose dimensions the writer could not derive; the columns then hold `0`, `1` and `0`. |
| `kg` `m` `s` `A` `K` `mol` `cd` `rad` | `Int8` | Base-unit exponents. |
| `factor` | `Float64` | Default `1`. |
| `offset` | `Float64` | Default `0`. |

`v_SI = factor * v_unit + offset`, over FMI 3.0's `<BaseUnit>` exponents, `rad`
included.

A **display unit** belongs to the unit it displays and is not itself a unit; no
variable may name one as its `unit`. They live in `modelica.displayUnits` so
that `modelica.units` stays flat, and they name their unit, so a display unit
may be added to a predefined unit without redefining it:

| column    | type      | meaning |
|-----------|-----------|---------|
| `unit`    | `Utf8`    | The unit this displays: an entry of `modelica.units`, or a predefined unit. |
| `name`    | `Utf8`    | The display unit's name. |
| `factor`  | `Float64` | Default `1`. |
| `offset`  | `Float64` | Default `0`. |
| `inverse` | `Boolean` | Default `false`. |

`v_display = factor * v_unit + offset`, or `factor * (1 / v_unit)` when
`inverse` — which FMI allows only with a zero offset, and which is meant for
reciprocal units such as Siemens, not a re-association.

### Predefined units

Every reader of this format knows these without the file saying anything. The
set is tied to the version: it may only grow, and only together with the minor
version, since an older reader would not know a unit a newer writer left out.
A unit it does not know is one it has no definition for, nothing worse.

Exponents in the order `kg m s A K mol cd rad`; factor `1` and offset `0`
throughout. The display units listed are the irregular ones; every unit also
takes the SI prefixes, below.

| unit  | exponents | display units |
|-------|-----------|---------------|
| `1`   | `0 0 0 0 0 0 0 0` | |
| `kg`  | `1 0 0 0 0 0 0 0` | `g` ×1e3, `t` ×1e-3 |
| `m`   | `0 1 0 0 0 0 0 0` | `mm` ×1e3, `cm` ×1e2, `km` ×1e-3 |
| `s`   | `0 0 1 0 0 0 0 0` | `ms` ×1e3, `min` ×1/60, `h` ×1/3600, `d` ×1/86400 |
| `A`   | `0 0 0 1 0 0 0 0` | `mA` ×1e3, `kA` ×1e-3 |
| `K`   | `0 0 0 0 1 0 0 0` | `degC` ×1 −273.15 |
| `mol` | `0 0 0 0 0 1 0 0` | |
| `cd`  | `0 0 0 0 0 0 1 0` | |
| `rad` | `0 0 0 0 0 0 0 1` | `deg` ×180/π |
| `sr`  | `0 0 0 0 0 0 0 2` | |
| `Hz`  | `0 0 -1 0 0 0 0 0` | `kHz` ×1e-3, `MHz` ×1e-6 |
| `N`   | `1 1 -2 0 0 0 0 0` | `kN` ×1e-3 |
| `Pa`  | `1 -1 -2 0 0 0 0 0` | `bar` ×1e-5, `kPa` ×1e-3, `MPa` ×1e-6 |
| `J`   | `1 2 -2 0 0 0 0 0` | `kJ` ×1e-3, `MJ` ×1e-6 |
| `W`   | `1 2 -3 0 0 0 0 0` | `kW` ×1e-3, `MW` ×1e-6 |
| `C`   | `0 0 1 1 0 0 0 0` | |
| `V`   | `1 2 -3 -1 0 0 0 0` | `mV` ×1e3, `kV` ×1e-3 |
| `F`   | `-1 -2 4 2 0 0 0 0` | `uF` ×1e6, `nF` ×1e9, `pF` ×1e12 |
| `Ohm` | `1 2 -3 -2 0 0 0 0` | `kOhm` ×1e-3, `MOhm` ×1e-6 |
| `S`   | `-1 -2 3 2 0 0 0 0` | |
| `Wb`  | `1 2 -2 -1 0 0 0 0` | |
| `T`   | `1 0 -2 -1 0 0 0 0` | |
| `H`   | `1 2 -2 -2 0 0 0 0` | `mH` ×1e3 |
| `lm`  | `0 0 0 0 0 0 1 2` | |
| `lx`  | `0 -2 0 0 0 0 1 2` | |
| `Bq`  | `0 0 -1 0 0 0 0 0` | |
| `Gy`  | `0 2 -2 0 0 0 0 0` | |
| `Sv`  | `0 2 -2 0 0 0 0 0` | |
| `kat` | `0 0 -1 0 0 1 0 0` | |
| `m/s` | `0 1 -1 0 0 0 0 0` | `km/h` ×3.6 |
| `m/s2` | `0 1 -2 0 0 0 0 0` | |
| `m2`  | `0 2 0 0 0 0 0 0` | |
| `m3`  | `0 3 0 0 0 0 0 0` | `l` ×1e3, `ml` ×1e6 |
| `m3/s` | `0 3 -1 0 0 0 0 0` | `l/s` ×1e3 |
| `kg/s` | `1 0 -1 0 0 0 0 0` | |
| `kg/m3` | `1 -3 0 0 0 0 0 0` | `g/cm3` ×1e-3 |
| `rad/s` | `0 0 -1 0 0 0 0 1` | `rpm` ×30/π, `rev/min` ×30/π, `1/min` ×30/π, `deg/s` ×180/π |
| `N.m` | `1 2 -2 0 0 0 0 0` | |
| `J/K` | `1 2 -2 0 -1 0 0 0` | |
| `J/(kg.K)` | `0 2 -2 0 -1 0 0 0` | |
| `W/(m.K)` | `1 1 -3 0 -1 0 0 0` | |
| `W/(m2.K)` | `1 0 -3 0 -1 0 0 0` | |

**Prefixes.** The base units and the named derived units — `kg` through `kat`
above, not the compound ones from `m/s` on — each have a display unit for every
SI prefix: `y z a f p n u m c d da h k M G T P E Z Y` for 10^-24 … 10^24, `u`
standing for micro since a unit name is written in a source file. A prefix of
10^n is a display factor of 10^-n. The prefixes attach to `g`, not `kg`, so the
prefixed forms of `kg` are `mg` ×1e6, `Mg` ×1e-3 and so on, and a name the
table already lists (`km`, `kHz`) is not added twice. That is 42 units and 576
display units.

---

## 5. `modelica.parameters` — optional

The values of every variable that is a `parameter` in the variable table. Row
order is what that table's `column` indexes.

| column  | type | meaning |
|---------|------|---------|
| `value` | `DenseUnion` | The value, in its own type. |

The union has one child per value type the file's parameters use — a `Float64`
child, an `Int32` child, one `Dictionary<Int32, Utf8>` child per enumeration
type, and so on — each holding just the values of that type, densely. A row is
a type id and an offset into that child, so reading a parameter is two lookups
and does not depend on how many types there are, and a parameter's type is the
child its row points at. The child names carry no meaning. The type ids are
whatever the schema declares; a writer numbers them from `0` in child order.

This is one *row* per parameter, not one field. A field costs about 90 bytes of
schema and record-batch header before it holds a value, which no codec touches;
a row of a dense union costs five.

Variables computed once during initialization are parameters here — including
one that *could* have changed but did not. The file records the trajectory, not
the declaration. In FMI's terms `constant` and `fixed` variables are parameters;
`discrete` and `tunable` ones have a column in `modelica.data`.

---

## 6. `modelica.data` — required

The trajectories. Field *i* of this schema is `column` *i* of a variable that
is not a `parameter`.

Field 0 is time. Every other field is one **stored** time-variant signal, in a
*Value type* above; a variable that is an affine function of a stored one has no
field of its own.

The fields are identified by position. Their names carry no meaning: the
variable table is the only naming authority, since several variables may share a
column and a field could carry only one of their names. A field name is schema,
which no codec compresses, so a writer leaves the names empty; the IPC schema
does not require them to be distinct or non-empty, and neither does this
format. A reader that wants a data frame names the columns itself, from the
variable table — it has to consult it anyway to expand the aliases and the
parameters into columns — so the file does not pay for names it would replace.

The rows are written as record batches as the simulation produces them: one row
per output point, plus one per event.

---

## 7. `modelica.index` — optional, last

The byte offset of every record batch of `modelica.data`, so a reader can seek
to a batch instead of walking to it.

| column   | type    | meaning |
|----------|---------|---------|
| `offset` | `Int64` | Byte offset from the start of the file. |

It does not help a full-trajectory read, which crosses every batch anyway. It is
for a time-window query, for dividing a read over threads by batch range, and
for telling a finished file from a truncated one.

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

variables = tables["variables"]
row = variables.filter(pc.equal(variables["name"], "y")).to_pylist()[0]
if row["parameter"]:
    values = tables["parameters"]["value"][row["column"]].as_py()
else:
    values = tables["data"].column(row["column"])
    if isinstance(values.type, pa.RunEndEncodedType):
        values = pc.run_end_decode(values)   # no kernel for dictionary values: expand the runs yourself
    values = pc.add(pc.multiply(values, row["scale"]), row["offset"])
```
