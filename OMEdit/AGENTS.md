# Instructions for coding agents: OMEdit

See also the top-level [AGENTS.md](../AGENTS.md).

## The web build

The OMEdit web page is built by
[OMEditGUI/wasm/CMakeLists.txt](OMEditGUI/wasm/CMakeLists.txt), not by
`OMEditLIB/CMakeLists.txt`. It compiles every `OMEditLIB/**/*.cpp` except the
files that match `WASM_EXCLUDE_PATTERNS` and `WASM_EXCLUDE_FILES`.

- Add a new file to `OMEditLIB/CMakeLists.txt`. The web build finds it
  automatically, unless it matches an exclude pattern.
- Code that only works on the desktop (`QProcess`, sockets, fmilib) must be
  guarded with `#if !defined(__EMSCRIPTEN__)`, or be in an excluded file whose
  callers are all guarded.
- The link fails on an undefined symbol, e.g.
  `undefined symbol: FMUExportDialog::FMUExportDialog(...)` when a file that
  is used is excluded. Check changes with the `rust_omedit_qt_web` target of
  the web build ("Web bundle only" in
  [OpenModelica.rs/README.md](../OMCompiler/Compiler/OpenModelica.rs/README.md)),
  which needs the Qt-for-WebAssembly toolchain (`-DOMSHELL_QT_WASM_PREFIX`).
  `-DOMEDIT_WASM_OPTIMIZE=OFF` links faster, but the page then does not run in
  the browser.

## Translations

The translations are Qt `.ts` files in `OMEditLIB/Resources/nls` (OMEdit) and
`../OMPlot/OMPlot/OMPlotGUI/Resources/nls` (the plot widgets). The build runs
`lupdate` on them and CI fails if that changes a file, see
[the README](OMEditLIB/Resources/nls/README.md).

`lupdate` fills in a guess from a similar string for a new message and marks it
`unfinished`. `lrelease` puts unfinished translations in the `.qm` file, so
users see these guesses. Many are wrong, e.g. a guess with a `%2` that the
source does not have. Each run also copies a finished translation into the
empty unfinished messages with the same source text, if all finished
translations of that text agree.

### Translating unfinished messages

Use [tstool.py](OMEditLIB/Resources/nls/tstool.py). It writes the file as
`lupdate` does, including the same-text copies, so the CI check stays clean.
`apply` refuses a translation whose `%1`/`%n` placeholders, `&` mnemonics,
HTML tags, line breaks or leading and trailing whitespace do not match the
source. It prints the same-text copies it made: review them like any other
guess.

```sh
cd OMEdit/OMEditLIB/Resources/nls
./tstool.py list OMEdit_sv.ts --limit 20     # unfinished messages, JSON lines
./tstool.py list OMEdit_sv.ts --guessed      # only those with a guess
./tstool.py apply OMEdit_sv.ts edits.json    # see ./tstool.py -h
./tstool.py check OMEdit_*.ts                # all translations with text
```

For each message:

1. Find every use: `git grep -F` the source text (a long string can be split
   over several literals) in the class named by the context. A string in a
   `Helper::` or `GUIMessages::` variable is used in many places.
2. Read the code around each use. Know the widget (menu item, button, tooltip,
   dialog title, message box, table header) and what fills in each `%1`.
   Short strings such as "Name", "Value" or "Start" are ambiguous without it.
3. Keep the terms of the finished translations in the same file. `git grep`
   the term in the `.ts` file before you choose a word for it. Modelica
   keywords and names (`model`, `connector`, `Modelica`, flag names, file
   extensions) stay in English.
4. Translate only when you are sure of the meaning and of the wording in the
   language. Otherwise leave the message unfinished. A wrong guess is worse
   than none: clear it (`"clear": true`), so the English source text shows.
5. Keep the punctuation, the `...` of menu items and the line breaks of the
   source. Use the capitalization rules of the language, not English title
   case: Swedish "Avbryt simulering", not "Avbryt Simulering". Choose a mnemonic letter that is not taken in the same menu or
   dialog.

Do not change what the code compares or stores: a string used as a settings
value, an omc argument or a key must not go through `tr()`.

Before you commit, build the `update_translations` target (or run `lupdate`
as the build does) and make sure that it does not change the file.
Commit each language separately. List the messages you changed, the cleared
guesses and why in the pull request, and ask for a review by a speaker of the
language.
