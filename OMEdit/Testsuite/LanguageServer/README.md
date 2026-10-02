# OMEdit language-server tests

`LanguageServer` checks executable discovery and required runtime files.
`LanguageServerNavigation` starts the real OMEdit application and a real Modelica
language server, then Ctrl+clicks a reference in the editor. It requires both an
LSP definition response and navigation to the expected model, file and declaration
line. The target cursor starts on another line so merely opening the target via
class-tree fallback cannot pass the LSP case. A separate case checks navigation
with no language server attached.

A small Qt Core stdio server supplies the negative case: its first definition
response is `null`, and its next response resolves the target. The GUI test
checks fallback immediately after handling the empty response (rather than
accepting the later timeout fallback), then Ctrl+clicks again using the same
editor and client. A second response with a different request ID and navigation
to the declaration prove that the empty response did not leave navigation stuck.
The positive integration case continues to use the real language server.

Settings are redirected before application startup. Models live in a temporary
package; the test stops its own server after each case. Responses have bounded
waits. Failed cases save a screenshot in the test's temporary output directory
and print its path. OMEdit currently navigates to the start of the returned line;
this test does not claim column-accurate navigation.

## CMake

Configure the normal OpenModelica build with `OM_OMEDIT_ENABLE_TESTS=ON`.
The navigation test uses the language server selected by the OMEdit build. To
exercise a local server revision, supply `-DMODELICA_LS_DIR=/path/to/server/out`;
that directory must contain the executable and both tree-sitter WASM files.
The test is registered only for native builds with a staged language server.

```sh
cmake --build build --target LanguageServerNavigation
ctest --test-dir build/OMEdit/Testsuite -R '^LanguageServerNavigation$' --output-on-failure
```

Use the same display setup as the other OMEdit tests (for example `xvfb-run` on
Linux CI). CTest applies a 60-second timeout.

The existing OMEdit Jenkins job runs this CTest suite under Xvfb. No separate
GUI automation service is needed. `OMEDIT_TEST_LSP_EXECUTABLE` can override the
configured executable for a local run; it must name an absolute executable path.
A missing executable or missing WASM files fails the test.

This complements the language-server repository's Qt client compatibility test:
that test checks protocol behavior against the server revision under test, while
this one covers the actual editor input and navigation wiring. No MCP service is
required.
