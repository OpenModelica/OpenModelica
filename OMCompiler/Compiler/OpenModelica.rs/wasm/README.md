# OpenModelica in the web browser

This file tells how to host the web build of OpenModelica, which runs in the
browser of the user. The
[User's Guide](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/webbrowser.html)
describes the web build and the services that the pages connect to.

The builds are published at <https://playground.openmodelica.org>. Each version
is a directory (`latest/` is built from the master branch) and a zip file with
the same files, `OpenModelicaCompiler-web-<version>.zip`. To host your own copy,
extract the zip file and serve the directory with a web server. The zip file
contains this file as `README.md`.

## What the web server must do

- Send these two headers with every file:

  ```text
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
  ```

  They make the pages *cross-origin isolated*. Without them the pages work,
  but you cannot cancel a running command, long commands show no progress, and
  the pages cannot export FMUs for native platforms.
- Use HTTPS, or `http://localhost`. Browsers do not isolate a page that comes
  over plain HTTP from another address.
- Send `.wasm` files with the content type `application/wasm`.
- Optional: compress the `.wasm` files. The extracted bundle is about 290 MB.
  Compression makes the transfer approximately three times smaller.

## On your own computer, with Python

`coi_server.py` is a small web server that sends the headers. It needs only
Python 3. It sends `Cross-Origin-Embedder-Policy: credentialless`, which also
isolates the pages, but fewer browsers support it than `require-corp`.

```sh
unzip OpenModelicaCompiler-web-latest.zip -d openmodelica-web
python3 openmodelica-web/coi_server.py 8000 openmodelica-web
```

Then open <http://localhost:8000/>. If port 8000 is in use, use a different
port.

Do not use `python3 -m http.server`, because it does not send the headers. Use
`coi_server.py` only on your own computer: the Python web server is not made
for a public server.

## On a server, with Apache

Extract each version into its own directory below the document root, for
example `/var/www/openmodelica/latest`. Then add the headers to the virtual
host:

```apache
<VirtualHost *:443>
    ServerName openmodelica.example.org
    DocumentRoot /var/www/openmodelica
    # The SSLEngine and SSLCertificateFile lines of your HTTPS setup go here.

    # Enable cross-origin isolation
    Header set Cross-Origin-Opener-Policy "same-origin"
    Header set Cross-Origin-Embedder-Policy "require-corp"

    AddType application/wasm .wasm
    AddOutputFilterByType DEFLATE application/wasm
</VirtualHost>
```

On Debian and Ubuntu, enable the modules and load the new configuration:

```sh
sudo a2enmod headers deflate ssl
sudo systemctl reload apache2
```

Then open `https://openmodelica.example.org/latest/`.

The server only sends static files. No OpenModelica code runs on it and the
pages send no data to it, so an old version of the bundle does not make the
server open to attacks. Keep the web server itself up to date. The models run
in the sandbox of the browser, like all other web pages.

### Updating

Extract the new zip file into an empty directory and replace the old
directory with it. Then copy your changed files (see
[Customization](#customization)) into the new directory again.

## Cloud storage in OMEdit (optional)

OMEdit can open and save files in Google Drive and OneDrive. This needs OAuth
applications that are registered for the address of your server.
`OMEdit-qt/cloud_config.json` in the zip file contains the registrations of
playground.openmodelica.org, which do not work at another address.

- To use cloud storage, register your own applications as
  [CLOUD-STORAGE.md](https://github.com/OpenModelica/OpenModelica/blob/master/OMEdit/OMEditGUI/wasm/CLOUD-STORAGE.md)
  describes and put their IDs into `OMEdit-qt/cloud_config.json`. Then copy
  `oauth-callback.html` from the zip file to the root of the server, so that it
  is at `https://openmodelica.example.org/oauth-callback.html`. One copy serves
  all versions.
- If you do not want cloud storage, delete `OMEdit-qt/cloud_config.json`.
  OMEdit then tells the user that cloud storage is not set up.

## Customization

You can change these files after you extract the zip file. The pages read them
when they load, so you do not have to build anything.

<!-- Add each new file that a deployment can change to this table, with a
     section below. -->

| File                          | What it controls                                                                         |
| ----------------------------- | ---------------------------------------------------------------------------------------- |
| `simulator/config.json`       | The title and the examples of the simulator                                              |
| `OMEdit-qt/cloud_config.json` | The OAuth applications for cloud storage, see [above](#cloud-storage-in-omedit-optional) |

### Simulator examples: `simulator/config.json`

```json
{
  "title": "Simulator",
  "defaultExample": "bouncing",
  "examples": [
    { "id": "bouncing", "label": "Bouncing ball", "sourceFile": "examples/BouncingBall.mo" },
    { "id": "pid", "label": "PID controller (MSL)", "library": "Modelica.Blocks.Examples.PID_Controller" }
  ]
}
```

| Key              | Meaning                                                                 |
| ---------------- | ----------------------------------------------------------------------- |
| `title`          | The title of the page                                                   |
| `defaultExample` | The `id` of the example that the page shows first                       |
| `id`             | The name of the example, also used in links (`?id=pid`)                 |
| `label`          | The text in the list of examples                                        |
| `source`         | The Modelica text of the model                                          |
| `sourceFile`     | A `.mo` file that contains the model, relative to `config.json`         |
| `library`        | A class in the Modelica Standard Library. The user edits a copy of it   |
| `figures`        | Optional, with `library`: a `figures` annotation that selects the plots |
| `daeMode`        | Optional: `true` simulates the model in DAE mode                        |

Each example has one of `source`, `sourceFile` and `library`.

To keep your examples separate from the bundle, so that an update does not
replace them, put them in a file outside the version directory and give its
address in the link to the simulator:
`https://openmodelica.example.org/latest/simulator/index.html?config=/my-examples/config.json`.
