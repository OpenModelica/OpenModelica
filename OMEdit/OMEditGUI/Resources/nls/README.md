## Creating and maintaining a new Translation File .ts

- Open OMEditGUI.pro and add a new language entry in `TRANSLATIONS` variable.
- The format for the language entry is `<OMEdit_<language_code>.ts>`. For correct `<language_code>` see http://www.loc.gov/standards/iso639-2/php/code_list.php.
- To generate and update translation files (Note :: The following command updates all the new translation strings. Do not try to create the ts-file manually.)

### Unix
```bash
lupdate -noobsolete ../../OMEditGUI.pro
```

### Windows
Open `Qt Command Prompt` or add `lupdate` in `PATH`.
```bash
tsupdate.bat
```

- Open your generated file with `Qt Linguist` for writing translations
  - Mark finished translations (green checkbox)
- Do not try to edit the ts-files manually. You will forget things.

## Creating a .qm file

- Generating .qm files from .ts files is performed by the Makefile. You don't need to worry.
