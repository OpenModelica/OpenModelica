# Result-file formats: a read/write benchmark

Five ways to store the same simulation result, measured against each other:

| format | shape | writer / reader |
|--------|-------|-----------------|
| MATLAB v4 (`.mat`) | a transposed `data_2` matrix plus `name`/`description`/`dataInfo` tables | `openmodelica_mat_writer`, `openmodelica_mat_reader` |
| `arrow` (`.arrow`) | `arrow.modelica`: several Arrow IPC *streams* in one file, the variable table among them | `openmodelica_arrow_writer`, `openmodelica_result_files::ArrowReader`; `src/arrow_modelica.rs` reads it the projected way |
| `arrow-json` (`.arrow-json`) | the unreleased layout `.arrow` had for a few days: one Arrow IPC file, the variable table JSON in its schema metadata | `openmodelica_arrow_writer::json`, `openmodelica_result_files::ArrowJsonReader`, both behind the `json-layout` feature |
| SDF (`.sdf`) | HDF5, one 1-D dataset per variable in a group tree from the dotted name | `openmodelica_hdf5_result::sdf` |
| MTSF (`.mtsf`) | HDF5, a `/ModelDescription` variable table over 2-D `/Results` matrices | `openmodelica_hdf5_result::mtsf` |
| minarrow (`.minarrow`, `--features minarrow`) | Arrow IPC again, written and read through minarrow + lightstream instead of arrow-rs | `src/minarrow.rs` |

`.mat` and `arrow` are the writers OpenModelica ships; SDF and MTSF are this
repository's, behind the `library` feature of `openmodelica_hdf5_result`;
`arrow-json` is the product's too, but only this benchmark enables the feature
that compiles it; `minarrow` is here. All are driven from one in-memory description,
so nothing but the serialization differs between the columns of the report.

## Running it

```
cargo run --release --manifest-path OMCompiler/SimulationRuntime/rust/openmodelica_result_bench/Cargo.toml -- \
    --data <dir of _res.mat files> --out <dir on the disk you mean to measure> \
    --reps 5 --deflate none,6,6s --json results.json --html results.html > results.md
```

It prints, per model, an estimate of how much busy-wait the configuration asks
for before it starts. That estimate is a floor and it is usually most of the
run: the delay is paid once per row, once per cell and once more per repetition
for the control pass, so `--delays 0,10us,100us,1ms` over a 6000-row model is
minutes per repetition before any format has written a byte. Cut `--delays`
first when a run is too slow.

Put `--out` on the filesystem the numbers are meant to describe and check the
line the report prints about it: a container's overlay mount is not the disk
under it, and a tmpfs is not a disk at all.

It needs the HDF5 development package (`libhdf5-dev`; the build script finds it
through `pkg-config`). `--features static-hdf5` builds HDF5 from the
`hdf5-metno-src` crate instead, which is the same 2.2.0 the wasm target uses.

The crate has its own `[workspace]`, so a normal build of the compiler or of the
simulation runtime neither needs nor builds HDF5.

## The two arrow columns

`arrow` is the format, specified in
`openmodelica_arrow_writer/SPECIFICATION.md`: several Arrow IPC **streams** in
one file, the variable table among them as a real table, the parameters as one
dense-union column, `modelica.format` `0.1` while the layout is still moving. It is written by the product's `openmodelica_arrow_writer`,
the same crate the C runtime and the wasm simulator write through, so the
column measures what OpenModelica actually produces. `src/arrow_modelica.rs`
is the *reader* here: it reads the variable table and stops, then projects the
data stream per name or divides its batches over threads through
`modelica.index` - what a plotting tool would do, and what the product's
`ArrowReader`, which decodes the whole file at open behind `ResultTable`, is
not built to time.

`arrow-json` is what master carried for the few days between the `.arrow` writer
landing and `arrow.modelica`: one IPC file with that table as JSON in its schema
metadata. **It was never released**, so nothing has to keep reading it. The
product keeps the writer and the reader only behind a `json-layout` cargo
feature that this benchmark enables and nothing else does, so it cannot be
written by accident. It is here as the *before* of the comparison.

Two properties of the *file* format separate them, and neither is the writer's
fault: an IPC file stores its schema **twice**, once as the leading message and
once inside the footer, and a record batch can be compressed by the format where
schema metadata never can. On FullRobot that is 1,538,914 B of schema in a
5,097,898-byte file, 30% of it. `--deflate` reaches `arrow`: the number that is
a gzip level for the HDF5 formats is a ZSTD level here.

Neither layout has *column* random access, because Arrow IPC has none:
`arrow_ipc::reader::read_block` seeks to a batch and reads its whole body, every
column, and a projection only skips the decode. That is why reading one
trajectory costs nearly what reading all of them does.

Enumerations are the one thing the benchmark cannot exercise: `arrow` stores an
enumeration as a `Dictionary<Int32, Utf8>` column, or as a dictionary child of
the parameter union, whose dictionary is the literal list - but the input here
is a `.mat` and an `_init.xml`, and OpenModelica writes an enumeration variable
into `_init.xml` as a plain `<Integer>`, with neither its literals nor its type
name. So every enumeration in these files is an `Int32`, which the format allows
a writer without literals to do.

**Compression is a writer's choice, not the format's**, so the specification says
nothing about it - Arrow defines `BodyCompression` and every implementation
handles it. What the measurements say a writer should choose:

* not by default. It makes a single-threaded full read 2.3-2.9x slower -
  FullRobot's 753 trajectories go 8.2 to 19.1 ms, ElectroChromicWindow's 298 go
  13.6 to 39.5 - for a saving that matters when a file is archived, not when it
  is plotted. A reader that splits the batches over threads takes most of that
  back, and then some (below).
* level 3 rather than 6 when it is used. They give the same file, 3.2 MB on
  FullRobot and 8.5 against 8.4 MB on ElectroChromicWindow, and level 6 costs
  twice the `emit`: at 1 ms steps the totals are 20.4 (none), 97.9 (zstd 3) and
  202.3 ms (zstd 6).
* never when the run has no spare core - `-n=1`, and the testsuite - because
  compression is only free when it overlaps the step after the row it
  compresses. With a writer thread those same totals are 14.0, 35.1 and 72.7 ms.

Two Arrow IPC streams concatenated in one file really do read back - checked
against both pyarrow and arrow-rs, which each consume exactly the end-of-stream
marker and leave the position at the next stream. The streaming format itself
is stable (columnar/IPC V5 since Arrow 1.0.0); a *container* of several streams
is not in the spec, so a generic tool handed the file reads the first stream
and stops - which, with the variable table first, is a readable listing of what
the file contains.

## The minarrow column

`--features minarrow` adds a fifth format: the same Arrow IPC bytes through
[minarrow](https://crates.io/crates/minarrow) and
[lightstream](https://crates.io/crates/lightstream) rather than arrow-rs, so the
two libraries can be compared on the same rows.

It is **not** `arrow.modelica` and cannot be. lightstream's IPC encoder writes
`custom_metadata: None` for the schema and for every field, so the variable
table and the units have nowhere to live; it has no run-end encoding, no
dense union for the parameters, and the dictionary id it does keep is hardcoded
to the column index. What the column measures is
the two libraries' cost of moving the stored columns, which is the interesting
part; the file it leaves is smaller than the `.arrow` one by the whole variable
table, and the round-trip check verifies only the stored columns and says so.

The two access patterns are the ones each library offers: `bulk` is one
projected read of every name (`load_table_cols` against `arrow-ipc`'s
`FileReader` projection), `per var` is one projected read per name against
`ArrowReader`, which decodes every column when it opens.

minarrow needs a nightly rustc (`allocator_api`, `portable_simd`) and
lightstream depends on tokio, so neither can go anywhere near the simulation
runtime, which builds on stable and for wasm. That is why this is a benchmark
feature and nothing else.

## Making the data

`./make-data.sh [directory] [model ...]` simulates the three models the report
is built on and leaves `<name>_res.mat` and `<name>_init.xml` in the directory
(default `/projects/result-bench-data`, deliberately outside any working tree).
`BouncingBall` is written out by the script; the other two come from the
Modelica Standard Library and from `Buildings`, and are installed only if
`loadModel` cannot already find them. `omc` comes from `$OMC` or from the path.

The three cover the shapes that behave differently: small, wide and short (5535
variables over 565 rows), narrow and tall (4468 variables, 299 of them stored,
over 6344 rows).

## What the input is

An OpenModelica `_res.mat`, read into memory once. A `.mat` records no units and
no types, so the `_init.xml` beside it is scanned for both; without it every
variable is an unqualified `Real` and the metadata of the other three formats is
understated. Aliases, parameters and the sign convention come from `dataInfo`,
so each format is given the same alias structure to represent however it likes.

`--scale 1,4,16` repeats a dataset's rows n times and reports each as its own
model, which grows the payload without touching the variable table: the shape of
`open` and `emit` across the scales separates the fixed cost from the per-row
cost by measurement rather than by construction. It also crosses the block
boundary - at one scale a run may fit in a single HDF5 chunk or Arrow batch and
at the next it may not, which moves work from `close` into `emit`.

## What is measured

**Writing.** A row at a time, with a calibrated busy-wait between consecutive
rows standing in for the integration step. **The delay is per row, not per
value**: a step produces one whole result row, which is also why a simulation
hands a writer a whole row at a time. The busy-wait matters: it evicts the
writer's working set the way a real step does, and the per-row cost rises with
it - up to about double at a 1 ms step. The row loop is also run once without
the writer in it, and the two clock sums are subtracted, so the cost of reading
the clock cancels instead of being estimated; that control pass is measured once
per delay per repetition and shared by every cell at that delay, since it does
not depend on the format. Reported per format and delay:

* `open` - everything written before the first row: the variable table.
* `emit` - the sum of the per-row calls.
* `close` - the format's own finalisation.
* `fsync` - putting the file on the device, timed apart because it is the same
  operating-system cost for every format.
* `MB/s` - the payload (rows x stored columns x 8 B) over `open + emit + close`.
  Not over `emit`: where a format actually serializes the payload differs, and a
  block bigger than the run leaves `emit` copying into a builder that has not
  written anything yet, which would read as an enormous throughput. `fsync` is
  left out because it is the device, not the format.
* `step %` - open + emit + close + fsync as a fraction of the same loop with no
  writer in it, i.e. what the result file costs a run whose steps take that long.
* `ns/value` - `emit` over the values written, which is the number to carry
  between models.

`--deflate none,6,6s` runs the HDF5 formats through each filter pipeline - no
filter, gzip 6, gzip 6 behind the byte-shuffle filter - and reports one row per
setting; the `.mat` and `.arrow` writers have no compression to turn on, so they
appear once. Cells are measured round-robin rather than one cell at a
time, so a thermal or scheduling transient over a run that takes minutes
spreads across all of them instead of landing on whichever was current.

`--block-rows` is the batch size (an Arrow record batch, an HDF5 chunk); the
default 1024 is what the Arrow writer uses in production. A block **larger than
the run** puts every format's work in `close` rather than `emit`, where a writer
thread cannot overlap it and there is one batch to divide a read over, so the
benchmark says so when it happens. An HDF5 chunk taller than the run is worse
still - an unfilled chunk occupies its whole size in the file - so the HDF5
writers are told how many rows are coming, as a simulation that knows
`numberOfIntervals` would.

What the size costs, on ElectroChromicWindow's 6344 rows and 299 columns:

| block | batches | file | read, 1 thread | read, 8 | write, thread |
|------:|--------:|-----:|---------------:|--------:|--------------:|
| 64 | 103 | 17.45 MB | 29.14 ms | 11.15 ms | 20.0 ms |
| 256 | 28 | 16.36 MB | 14.09 | 10.03 | 24.6 |
| 1024 | 10 | 16.10 MB | **12.35** | 10.28 | 26.1 |
| 4096 | 5 | **16.03 MB** | 14.47 | 11.42 | 27.4 |

Every batch carries a message header with a node and a buffer entry per column,
so small blocks cost file size - 103 of them are 8.8% more file than 5. They
also cost a single-threaded read, which has that many more headers to parse.
Large ones give a writer thread less to overlap and a reader fewer pieces to
divide. 1024 is the sensible middle and it is the default; a writer that wants
the file readable while it runs (`-mat_sync`) trades size for latency.

**Reading.** No delay. Each file is read for 1, 100 or every trajectory, from a
page cache dropped before each repetition (`posix_fadvise(DONTNEED)`), in two
access patterns:

* `per var` - one `read_vals` per name, which is what `readSimulationResult`,
  OMPlot and OMEdit's variable browser do;
* `bulk` - the best path the format offers for a known set: the `.mat`'s
  `read_all`, MTSF's whole-matrix read, Arrow's column projection. SDF has none,
  since every variable is a dataset of its own, so its two rows agree;
* `list` - name every variable in the file and read no values, which is what a
  variable browser does when a file is opened. Each format is asked through the
  cheapest reader it has that can answer: for `.arrow` that is the projected
  reader rather than the `ResultTable` one, which decodes every column before it
  will say anything. `vars` is then how many variables the file could name and
  `read` is zero by construction.

`--warm` adds a second row per cell that repeats the identical read straight
after the cold one, so what it finds cached is exactly what that read needs:
what a second plot of the same variable costs, not a second pass over the file.
`held` is what the reader still has allocated once it has answered, taken from
the C allocator's own in-use counter rather than from resident memory, which
after the first few cells only reports what the allocator has kept back for
reuse. On FullRobot that is 30 MB for SDF to answer about a single variable
against 0.3 MB for Arrow read through projection.

`open` is again the fixed cost - what the reader must read before it can answer
a question about any variable. The same variable names are asked of every
format, taken from the source, so `delivered` is comparable across rows, and
`MB/s` divides it by `open + read` rather than by `read`: `ArrowReader` decodes
every column while it opens and its `read` is then only a lookup, so dividing by
`read` would rank the readers by where they choose to do the work instead of by
how long the answer took.

**Writing on a thread of its own.** `--writer sync,thread` measures the same
cells both ways. `sync` is what a simulation does today: the step calls the
writer and waits for it. `thread` hands the rows to a writer thread and returns,
so the serialization runs during the step that follows it. Then

* `emit` is what the row loop still pays - a copy of the row and, once per
  handover, a channel send;
* `stall` is the part of `emit` spent waiting for the writer to hand a buffer
  back, i.e. the writing that could *not* be hidden behind the steps;
* `close` grows by whatever was still in the queue when the run ended.

`--handoff` (default 64 rows) is how many rows go over at a time and `--queue`
(default 4) how many such blocks may be in flight. The handover size is not a
detail: one row per handover means the writer is asleep at every step boundary
and every row pays a futex wake, which at a 100 us step cost more than the
writing it was hiding - 8 ms against 0.03 ms for 512 rows of `BouncingBall`.
Sixty-four rows amortise the wake to nothing and cost 64 rows of memory.

**Reading with more than one thread.** `--threads 1,4,8` divides a read over
that many readers of the same file.

Only `arrow` and `minarrow` are swept. The rest is settled and a run should not
pay for it again: HDF5 serialises every call on one global lock and its
per-thread opens convoy on top of that, so four readers of FullRobot cost 12x
one and eight cost 34x; `arrow-json` re-reads every batch body it crosses in
each thread, whichever way it is split, so eight cost 3.6x one. The `.mat`'s
`read_all` is one whole-store fetch and does not divide by variable either,
though its per-variable path does.

`arrow` divides two ways. Per variable the names divide the passes over the
stream. In bulk it splits by **batch range** through `modelica.index`, so the
ranges are disjoint and nothing is read twice - the split every other format
lacks. On ElectroChromicWindow's 25 batches, reading all 298 trajectories:

| threads | uncompressed | zstd 3 |
|--------:|-------------:|-------:|
| 1 | 10.74 ms | 36.18 ms |
| 2 |  9.30 | 18.78 |
| 4 |  6.77 | 13.45 |
| 8 |  6.56 |  9.96 |

Uncompressed the read is memory-bound and eight threads buy 1.6x. Compressed it
is CPU-bound - the difference is decompression - and they buy 3.6x, which brings
a compressed read below an uncompressed single-threaded one at 0.56x the file
size. Threads are worth having where there is decoding to divide.

**Structure.** A table ahead of the timings counts what each format builds for
each dataset from the format's own rules: `objects` the named things in the file
(HDF5 groups and datasets, Arrow fields, MATLAB matrices) and `blocks` the
independently stored - and under gzip independently compressed - pieces of the
data. On FullRobot that is 6531 objects and 2921 blocks for SDF against 9 and 2
for MTSF, which is what the write and read timings are really measuring.

**Correctness.** Before the read benchmark, every trajectory and every parameter
is read back from each written file and compared with what the writer was given.
A non-zero mismatch count invalidates the timings above it.

**What is not being compared.** The SDF and MTSF writers here are this
repository's, not the reference tools': SDF's and MTSF's own implementations are
Python, so timing them against a Rust `.mat` writer would measure the language
and not the format. What the tables compare is the work each *format* forces on
a writer and a reader - objects created, blocks written, bytes stored, and how
much of a file a reader must touch to answer for one variable.

## What the libraries' own parallel options do

Neither library reads or writes in parallel by itself, and neither has a switch
that would make it. This is worth stating plainly, because both projects have a
"parallel" story that is about something else.

**HDF5.** The build here reports `Threadsafety: yes` and `Parallel HDF5: no`,
which the report header repeats. The two are unrelated:

* *Thread safety* in 1.14 is one global lock around the whole library. It makes
  concurrent callers correct, not faster: two threads reading two different
  datasets take turns, and so do the filter pipelines they drive. There is no
  internal thread pool and no parallel chunk decompression.
* *Parallel HDF5* means MPI-IO - a communicator of **processes** opening one
  file collectively through `H5Pset_fapl_mpio`, for a cluster writing one file
  onto a parallel filesystem. It needs an MPI build, every participating process
  has to make the same calls in the same order, and this build additionally
  reports `Parallel Filtered Dataset Writes: no`, so a compressed dataset is out
  of its reach anyway. Nothing in it helps one `omc`, one OMEdit or one plot.

What does make HDF5 faster here is structural and is what the tables measure:
fewer objects and fewer chunks, a chunk cache big enough for the chunk being
written (`H5Pset_chunk_cache`; the 1 MB default is smaller than one MTSF chunk),
and reading a whole chunk instead of a one-column hyperslab that crosses every
chunk in the file.

**arrow-rs.** `arrow-ipc` has no threading and no feature to turn any on:
`FileReader` decodes one record batch at a time on the calling thread. There is
little to parallelise, either - the IPC body *is* the in-memory layout, so
reading a column is a bounds check and a pointer, not a decode. arrow-rs's
concurrency lives in `parquet` (row-group and column-chunk streams) and in
DataFusion, neither of which is on the path a `.arrow` result file takes.

So caller-side threading is the only parallelism available to either format, and
`--threads` is there to measure how much of it survives: Arrow's column
projection and SDF's dataset-per-variable divide by variable and genuinely run
at the same time, while every HDF5 call still queues behind the same lock.

## The HTML report

`--html results.html` writes a page over the same measurements the JSON carries.
Every measurement keeps every dimension it was taken at - model, format, filter
pipeline, block size, chunk width, writer, delay, threads, access pattern - and
the controls choose which one runs along the x axis, which one separates the
lines, and what each of the rest is held at.

That is the whole point of the pivot, and it is meant to be used both ways:

* **hold the settings, colour by format** - "which format is better for this?" -
  the `Compare formats` preset;
* **hold the format, colour by a setting** - "what is this format sensitive
  to?" - the `Compare settings, one format` preset, which pins the format that
  has the most settings measured on it rather than the alphabetically first.

A dimension left at `(all)` is averaged over, and the line under the chart says
which ones those are, so a chart never quietly mixes two things. Plotly comes
off a CDN, so the page needs the network the first time it is opened; the
measurements are embedded in it, so nothing else does.
