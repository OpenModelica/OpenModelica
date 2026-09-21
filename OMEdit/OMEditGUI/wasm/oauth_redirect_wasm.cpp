/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

// Browser half of OAuth2Redirect.
//
// The page is served cross-origin isolated (COOP: same-origin) because the omc
// worker bridge needs SharedArrayBuffer. That severs window.opener in both
// directions, so the usual "popup posts the code back to its opener" does not
// work at all here: the popup returns to oauth-callback.html, a static page of
// our own origin, which republishes the code on a BroadcastChannel. Same origin
// is all a BroadcastChannel needs - no opener, no postMessage.
//
// localStorage carries the same payload as a fallback for the rare browser with
// no BroadcastChannel, and it is what lets a popup that the user closed manually
// still be noticed.

#if defined(__EMSCRIPTEN__)

#include "Cloud/OAuth2Redirect.h"

#include <QPointer>

#include <emscripten.h>
#include <emscripten/em_js.h>

#include <cstdlib>

namespace {

// Where the service sends the user back to.
//
// At the origin root, not beside the application: neither Google nor Microsoft
// allows a wildcard in a redirect URI, and the application is deployed under a
// versioned path (/latest/, /v1.28/, ...). A callback page at the root is one
// registered URI that every version shares - which works because the code comes
// back over a BroadcastChannel, and those are scoped to the origin, not the path.
EM_JS(char *, omedit_oauth_redirect_uri, (), {
  try {
    return stringToNewUTF8(new URL("/oauth-callback.html", location.href).href);
  } catch (e) {
    return stringToNewUTF8("");
  }
});

/*!
 * \brief Open the popup and hand the result back by calling into wasm.
 *
 * Deliberately not a blocking wait. Sitting in a nested QEventLoop while the user
 * spends a minute on a consent screen leaves Qt's Asyncify machinery suspended,
 * queueing pointer events the whole time; replaying them afterwards against DOM
 * state that has since changed crashes inside QWasmWindow::processPointerEnterLeave
 * and wedges the page. So the application stays live and JS calls _omedit_oauth_deliver
 * when there is something to report.
 */
EM_JS(void, omedit_oauth_start, (const char *url, const char *expectedState), {
  const KEY = "omedit-oauth-result";
  const want = UTF8ToString(expectedState);
  let settled = false;
  console.log("[OMEdit] sign-in started, expecting state", JSON.stringify(want));
  // A result left over from an earlier attempt carries that attempt's state, and
  // consuming it would fail the new one as a mismatched response.
  try { localStorage.removeItem(KEY); } catch (e) { /* private mode */ }
  // Ignore anything that is not the answer to *this* request - a second OMEdit
  // tab signing in shares the channel.
  const isOurs = (r) => !want || !r || !r.state || r.state === want;

  const deliver = (code, state, error) => {
    if (settled) return;
    settled = true;
    try { channel.close(); } catch (e) { /* already closed */ }
    removeEventListener("storage", onStorage);
    clearTimeout(timer);
    try { localStorage.removeItem(KEY); } catch (e) { /* private mode */ }
    const pCode = stringToNewUTF8(code || "");
    const pState = stringToNewUTF8(state || "");
    const pError = stringToNewUTF8(error || "");
    try {
      Module._omedit_oauth_deliver(pCode, pState, pError);
    } finally {
      _free(pCode); _free(pState); _free(pError);
    }
  };
  const settle = (r) => deliver(r && r.code, r && r.state, r && r.error);

  let channel;
  try {
    channel = new BroadcastChannel("omedit-oauth");
    channel.onmessage = (e) => {
      const got = (e.data && e.data.state) || "";
      if (!isOurs(e.data)) {
        console.warn("[OMEdit] ignoring a sign-in result: state", JSON.stringify(got),
                     "does not match", JSON.stringify(want));
        return;
      }
      console.log("[OMEdit] sign-in result received over BroadcastChannel");
      settle(e.data);
    };
  } catch (e) {
    console.warn("[OMEdit] no BroadcastChannel; falling back to localStorage", e);
    channel = { close() {} };
  }
  const onStorage = (e) => {
    if (e.key !== KEY || !e.newValue) return;
    try {
      const result = JSON.parse(e.newValue);
      if (isOurs(result)) settle(result);
    } catch (err) { /* not ours */ }
  };
  addEventListener("storage", onStorage);

  // No closed-detection: under COOP the handle is severed as soon as the popup
  // navigates cross-origin, and a severed handle reports itself closed - which
  // aborted every real sign-in the moment it left our origin.
  const popup = window.open(UTF8ToString(url), "omedit-oauth", "popup,width=520,height=680");
  if (!popup) {
    deliver("", "", "The browser blocked the sign-in window. Allow pop-ups for this site and try again.");
    return;
  }
  const timer = setTimeout(() => {
    console.log("[OMEdit] timed out waiting for the sign-in result");
    deliver("", "", "Timed out waiting for the sign-in to finish. If you closed the sign-in window, try again.");
  }, 300000);
});

class PopupRedirect;
//! The sign-in in flight, if any; JS calls back into this one.
QPointer<PopupRedirect> gActiveRedirect;

class PopupRedirect : public OAuth2Redirect
{
public:
  PopupRedirect(const QString &configuredUri, QObject *pParent)
    : OAuth2Redirect(pParent), mConfiguredUri(configuredUri) {}

  QString redirectUri() override
  {
    // A deployment that cannot serve the root - behind a path-mapping proxy, say -
    // names its own callback URL in cloud_config.json.
    if (!mConfiguredUri.isEmpty()) {
      return mConfiguredUri;
    }
    char *raw = omedit_oauth_redirect_uri();
    const QString uri = QString::fromUtf8(raw);
    free(raw);
    return uri;
  }

  bool start(const QUrl &authorizationUrl, const QString &state) override
  {
    gActiveRedirect = this;
    // Returns at once; the answer arrives through deliver().
    omedit_oauth_start(authorizationUrl.toString().toUtf8().constData(), state.toUtf8().constData());
    return true;
  }

  void cancel() override { deliver(QString(), QString(), tr("Sign-in was cancelled.")); }

  void deliver(const QString &code, const QString &state, const QString &error)
  {
    if (mSettled) {
      return;
    }
    mSettled = true;
    emit finished(code, state, error.isEmpty() && code.isEmpty() ? tr("No authorization code was returned.") : error);
  }

private:
  QString mConfiguredUri;
  bool mSettled = false;
};

} // namespace

extern "C" EMSCRIPTEN_KEEPALIVE void omedit_oauth_deliver(const char *code, const char *state, const char *error)
{
  if (gActiveRedirect) {
    gActiveRedirect->deliver(QString::fromUtf8(code), QString::fromUtf8(state), QString::fromUtf8(error));
  }
}

OAuth2Redirect *OAuth2Redirect::create(const QString &configuredUri, QObject *pParent)
{
  return new PopupRedirect(configuredUri, pParent);
}

#endif // __EMSCRIPTEN__
