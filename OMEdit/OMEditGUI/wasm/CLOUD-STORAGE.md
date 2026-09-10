# Cloud storage in OMEdit

OMEdit can open and save Modelica packages in Google Drive and OneDrive, keeping
the whole directory structure. It works the same way on the desktop and in the
browser, and on the web build it is the only place work survives a reload.

A cloud folder is *mounted*: its contents are brought down to an ordinary local
directory (the working copy), and everything else in OMEdit - the editors, the
library browser, omc - sees a normal path. Synchronising is a three-way
comparison of the working copy, the remote folder, and a manifest of the last
synced state, so a file that changed on both sides is reported rather than
guessed at, and a missing file is only ever treated as deleted when the working
copy is otherwise intact.

## Using it

- **File > Open Model/Library from Cloud Storage** picks a folder (or a file in
  one), brings it down, and opens it.
- **File > Save to Cloud Storage** saves the active class into a folder you pick.
  Make a new folder from the tree's context menu.
- After that the folder stays mounted and every save is pushed automatically a
  few seconds later. **Tools > Options > Cloud Storage** lists the mounted
  folders; untick one to synchronise it only when asked, or forget it entirely
  (which removes the local copy and touches nothing in the cloud).
- If a file changed both locally and in the cloud, a dialog asks per file: keep
  yours, take theirs, or keep both. Keeping both puts the cloud version at the
  original name and yours beside it as `<name>.conflict-<timestamp>.<ext>`.

On the web build the working copy is also mirrored into IndexedDB, so reopening a
package after a reload revalidates rather than downloading everything again.
Nothing is uploaded from that cache on its own: an edit that was cached but never
pushed is uploaded by the next synchronisation.

## Setting up the OAuth applications

OMEdit ships no client registration. Each deployment registers its own, because
the consent screen names the registering organisation. Registrations are runtime
configuration - see `cloud_config.json.example` beside this file - and never
compiled in.

Two registrations per provider: the web build and the desktop build use different
redirect mechanisms.

### Google Drive

At <https://console.cloud.google.com/apis/credentials>, in a project with the
Google Drive API enabled:

1. **Web application** client, for the web build.
   - Authorised JavaScript origins: the origin the page is served from, e.g.
     `https://playground.openmodelica.org` and `http://localhost:8110` for local
     testing. Wildcards are not accepted.
   - Authorised redirect URI: `<origin>/oauth-callback.html`. One URI covers
     every versioned path (`/latest/`, `/v1.28/`, ...) because the page lives at
     the origin root; see the note about the symlink in the deployment section.
2. **Desktop app** client, for the desktop build. It uses a loopback port, which
   Google allows without registering a URI.

Both give a client ID and a client secret. Google's token endpoint rejects a PKCE
exchange without the secret even for a public client, so both go into
`cloud_config.json`. The secret is not confidential - the web build serves it to
every visitor - and what protects the application is the registered redirect URI
and origin.

The scope is `drive.file`, which is non-sensitive: no app verification and no
annual security assessment. OMEdit sees only the folder it creates
(`OpenModelica`) and what it puts there. While the application is in *Testing*
mode, add yourself under *Audience > Test users* or sign-in is refused.

### OneDrive

At <https://portal.azure.com> > *Microsoft Entra ID* > *App registrations* >
*New registration*:

1. Supported account types: personal Microsoft accounts, or personal plus work
   and school, depending on who should be able to sign in.
2. Platform **Single-page application**, redirect URI `<origin>/oauth-callback.html`.
   The SPA platform is what makes the token endpoint send CORS headers; a "Web"
   platform registration will fail in the browser.
3. Add a second platform, **Mobile and desktop applications**, with the loopback
   redirect `http://localhost` for the desktop build.
4. API permissions, delegated: `Files.ReadWrite`, `offline_access`, `User.Read`.

Microsoft needs no client secret for a public client, so only the client ID goes
into `cloud_config.json`.

## Deploying the configuration

- **Web**: point the build at the file with
  `-DOMEDIT_CLOUD_CONFIG=/path/to/cloud_config.json`; it is staged beside the
  page. `oauth-callback.html` is staged at the **web bundle root**. That is the
  origin root only on localhost - on a deployment that unpacks under `/latest/`,
  serve the root copy as a symlink into it, and make sure the server follows
  symlinks. If the origin root is not yours to serve, set `redirectUri` in
  `cloud_config.json` and register that URI instead.
- **Desktop**: put `cloud_config.json` in the directory that holds `omedit.ini`
  (`~/.config/openmodelica` on Linux). Without it, cloud storage reports that it
  has not been set up; individual users can also fill the fields in
  *Tools > Options > Cloud Storage*.

The callback page's channel name (`omedit-oauth`) and its `{code, state, error}`
payload are a contract with every still-deployed version, since they all share
the one page. Change them by adding a new channel alongside the old one, never by
swapping.

## Where the pieces live

| | |
|---|---|
| OAuth, providers, sync | `OMEdit/OMEditLIB/Cloud/` |
| Desktop redirect (loopback socket) | `Cloud/OAuth2RedirectLoopback.cpp` |
| Web redirect (popup + BroadcastChannel) | `OMEditGUI/wasm/oauth_redirect_wasm.cpp`, `oauth-callback.html` |
| Settings and token persistence | `OMEditLIB/Util/PersistentStorage.{h,cpp}`, `OMEditGUI/wasm/persist_store.cpp` |
| Working-copy cache (web) | `OMEditGUI/wasm/cloud_cache_idb.cpp` |
| Tests | `OMEdit/Testsuite/Cloud/` |
