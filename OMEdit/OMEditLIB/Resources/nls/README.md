## Creating and maintaining the translation files (.ts)

The `.ts` files of OMEdit, OMNotebook and OMShell are updated by the CMake build: when the
GUI clients are built, `lupdate` (`qt_add_lupdate`, Qt 6.2 or newer) scans the sources and
merges new, changed and removed strings into the `.ts` files in the source tree.
Source locations (file and line) are not stored, so a small code change does not touch
thousands of lines.

After building, `git status` shows whether the translation files were out of date.
Commit the updated `.ts` files together with the code change. The CI fails if they are not.

Use `-DOM_UPDATE_TRANSLATIONS=OFF` to switch this off (for example for read-only source trees)
and `-DOM_LUPDATE_OPTIONS="..."` to change the `lupdate` arguments.
To update only the translations: `cmake --build <build-dir> --target update_translations`.

### Adding a new language

- Add `<OMEdit_<language_code>.ts>` to the `TS_FILES` list in `OMEditLIB/CMakeLists.txt`.
  For the correct `<language_code>` see http://www.loc.gov/standards/iso639-2/php/code_list.php.
- Build once. `lupdate` creates the file. Do not try to create the ts-file manually.
- OMNotebook and OMShell have their `TS_FILES` list in their own `CMakeLists.txt`.
- Open your generated file with `Qt Linguist` for writing translations
- Mark finished translations (green checkbox)
- Do not try to edit the ts-files manually. You will forget things.

## Creating a .qm file

- Generating .qm files from .ts files is performed by the CMake build. You don't need to worry.
