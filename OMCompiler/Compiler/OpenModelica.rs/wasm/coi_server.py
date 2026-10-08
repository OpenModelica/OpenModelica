#!/usr/bin/env python3

# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
# RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium)
# Public License (OSMC-PL) are obtained from OSMC, either from the above
# address, from the URLs:
# http://www.openmodelica.org or
# https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica,
# and in the OpenModelica distribution.
#
# GNU AGPL version 3 is obtained from:
# https://www.gnu.org/licenses/licenses.html#GPL
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.

"""Static file server with cross-origin isolation (COI) headers, for serving a
local OpenModelica web build (OMEdit-qt / OMShell / OMNotebook / the omc page).

COI (COOP + COEP) is what enables SharedArrayBuffer, and with it the wasm-jit
cancel flag, live compile progress, the FMU native-platform compiler and (in the
threaded builds) wasm threads. `python3 -m http.server` sends none of these
headers, so those features silently degrade.

Usage:
    coi_server.py [PORT] [DIR]      # PORT default 8000, DIR default "."

Serving an installed bundle from the repository root:
    python3 OMCompiler/Compiler/OpenModelica.rs/wasm/coi_server.py 8000 \\
      build-web/install_cmake/share/omc/web

COEP is `credentialless` so cross-origin library downloads (CORS fetches from an
openmodelica.org subdomain) still load; `Cross-Origin-Resource-Policy:
cross-origin` lets same-origin subresources load under either COEP value.
`Cache-Control: no-store` so a rebuilt wasm is always picked up on reload.
"""
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
DIR = sys.argv[2] if len(sys.argv) > 2 else "."


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=DIR, **k)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "credentialless")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


class Server(ThreadingHTTPServer):
    allow_reuse_address = True


print(f"Serving {DIR} on http://0.0.0.0:{PORT} (COI: COOP=same-origin, COEP=credentialless)")
Server(("0.0.0.0", PORT), Handler).serve_forever()
