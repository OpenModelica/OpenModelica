# FMI settings guide

A guide that leads a user from what they know about their use case to the FMI
export settings of OpenModelica. The knowledge is in one JSON file. This crate
evaluates it inside omc, so that every client gives the same advice: the
simulator of the web build and OMEdit open the guide from their *Export FMU*
dialog.

| File                       | Contents                                              |
| -------------------------- | ----------------------------------------------------- |
| `fmi-settings.json`        | The questions, the settings and the rules. Edit this  |
| `fmi-settings.schema.json` | JSON Schema: completion and checks in an editor       |
| `src/`                     | The evaluator                                         |
| `../wasm/fmi-guide/`       | The dialog of a web page that exports FMUs            |
| `OMEdit/OMEditLIB/FMI/`    | The dialogs of OMEdit                                 |

Check the file after an edit, in `OMCompiler/Compiler/runtime/rust`:

```sh
FMI_GUIDE_WRITE_TEXTS=1 cargo test -p openmodelica_fmi_guide
```

The tests fail when the file has a mistake, and name it. `FMI_GUIDE_WRITE_TEXTS`
writes the texts again for the translators, see [Translations](#translations).

## The file

### inputs

The questions. `type` is `choice` (one answer) or `multi` (any number of
answers; none selected means *unknown*).

```json
{ "id": "coupling", "group": "system", "type": "choice",
  "label": "How tightly is it coupled to the rest?",
  "enabledWhen": { "topology": ["component", "multi"] },
  "disabledNote": "A single FMU has nothing to couple to.",
  "default": "unknown",
  "options": [ { "value": "loose", "label": "Loosely" }, ... ] }
```

`enabledWhen` on an input or on one of its options turns it off. It can test
earlier inputs only. An input that is off has no value.

### settings

What the answers decide. They are decided in file order, so a setting can
depend on an earlier one (`csSolver` depends on `fmiType`).

- `relevantWhen`: the setting exists only when this holds.
- `requires` on an option: the option is impossible otherwise, for example an
  FMI 3.0 feature when the FMI version is 2.0.
- `support` on an option: `yes` (default), `experimental`, `partial`,
  `planned` or `no`; see `supportLevels`. It can depend on other choices:

  ```json
  "support": [ { "when": { "fmiVersion": "3.0" }, "level": "yes" },
               { "level": "no", "note": "Only for FMI 3.0." } ]
  ```

  Options with `planned` or `no` are the ones OpenModelica does not have. Keep
  them in the file: they show what a use case needs.
- `default`: wins a tie. Normally what OpenModelica does if nothing is set.
- `omc`: how to select the option. `args` are arguments of `buildModelFMU`,
  `flags` go to `setCommandLineOptions`, `fmiFlags` are joined into one
  `--fmiFlags=`. `how` is free text for everything else.

### rules

```json
{ "id": "tight-coupling-one-solver",
  "when": { "coupling": "tight" },
  "because": "Tightly coupled parts need one solver for the whole system.",
  "score": { "interface": { "me": 3, "cs": -1 } } }
```

| Key       | Effect when `when` holds                                         |
| --------- | ---------------------------------------------------------------- |
| `exclude` | Rules options out: `{ "fmiVersion": ["1.0"] }`                   |
| `score`   | Adds points: 1 slight, 2 clear, 3 strong; negative speaks against |
| `warn`    | Shows a warning                                                  |
| `advice`  | Shows a tip                                                      |
| `because` | The reason the user sees. Needed with `exclude` and `score`      |
| `enables` | See below                                                        |

A rule can test inputs, and settings that come before the settings it changes.

`enables` marks a rule that only exists to make one option possible:
"adjoint derivatives need FMI 3.0" has
`"enables": { "derivatives": "adjoint" }`. When the tool does not have that
option, the rule is skipped for the recommendation of what works today.
Otherwise the guide would send the user to FMI 3.0 for a feature that is not
there.

### Conditions

`when`, `enabledWhen`, `relevantWhen` and `requires` use the same form. All
entries must hold.

| Form                                   | Meaning                              |
| -------------------------------------- | ------------------------------------ |
| `{ "a": "x" }`                         | a is x (multi: x is selected)        |
| `{ "a": ["x", "y"] }`                  | a is x or y                          |
| `{ "a": "x", "b": "y" }`               | a is x and b is y                    |
| `{ "a": { "lacks": "x" } }`            | a is known and is not / has not x    |
| `{ "a": { "unknown": true } }`         | nothing selected, or `"unknown"`     |
| `{ "a": { "not": "x" } }`              | a has a value and it is not x        |
| `{ "any": [ {...}, {...} ] }`          | at least one holds                   |
| `{ "all": [ {...}, {...} ] }`          | all hold (to test one id twice)      |
| `{ "not": {...} }`                     | does not hold                        |
| `{}`                                   | always                               |

A test on an input that is off, or on a setting that is not relevant, is false.

## How a setting is decided

1. Options whose `requires` does not hold are impossible.
2. Options that a rule excludes are ruled out.
3. Each remaining option gets the sum of its points.
4. The highest sum wins. A tie goes to the `default` option, then to an option
   the tool has, then to the first in the file.

This is done twice. *Today* takes the best option that the tool has. *Ideal*
takes the best option, also when the tool does not have it. The options that
*ideal* picks and the tool does not have are the gaps for that use case.

## The evaluator

The crate has the file built in and answers JSON requests (`call`):

| Request                                              | Reply                                      |
| ---------------------------------------------------- | ------------------------------------------ |
| `{"op": "model"}`                                    | The file, to show the questions            |
| `{"op": "advise", "answers": {...}, "host": {...}}` | The settings, the reasons, the omc script |
| `{"op": "validate"}`                                 | The mistakes in the file                   |
| `{"op": "strings"}`                                  | Every text a user can see                  |

It is part of omc, but it is not a scripting function:

- The C omc has it in `libomcruntime_rust` as `omcrs_fmi_guide(request)`.
  Desktop OMEdit calls that.
- The Rust omc exports `omc_fmi_guide(request)` from its WebAssembly module.
  The workers of the web clients pass requests to it (`fmiGuide`).

### A client that cannot set everything

A client says what it can export and which settings it has controls for:

```json
{ "name": "the Simulator",
  "offers": { "fmiVersion": ["3.0"], "csSolver": ["dassl", "euler", "ida", "cvode"] },
  "applies": ["fmiType", "daeMode", "csSolver"] }
```

An option that is not offered counts as missing. The reply lists in `asked`
the questions that can change a setting in `applies`; the client shows only
those.

### Translations

The texts are in the file, where Qt's `lupdate` does not look. The crate
writes `OMEdit/OMEditLIB/FMI/FMIGuideTexts.cpp`, which names each text to
`lupdate` in the context `FMIGuide`, with the place of use as a comment for
the translator. OMEdit shows a text with
`QCoreApplication::translate("FMIGuide", text)`. A test of the crate fails
when that file is out of date.
