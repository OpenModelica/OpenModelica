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

#ifndef OAUTH2REDIRECT_H
#define OAUTH2REDIRECT_H

#include <QObject>
#include <QString>
#include <QUrl>

/*!
 * \brief Shows the user the authorization page and brings the code back.
 *
 * Desktop opens the system browser and catches the redirect on a loopback
 * socket. The browser build opens a popup that returns to a callback page of our
 * own origin; COOP: same-origin severs the popup's opener in both directions, so
 * the code travels back over a BroadcastChannel rather than postMessage.
 */
class OAuth2Redirect : public QObject
{
  Q_OBJECT
public:
  explicit OAuth2Redirect(QObject *pParent = 0) : QObject(pParent) {}

  //! The platform's implementation; the caller takes ownership. configuredUri is
  //! ignored on desktop, whose port is only known once bound.
  static OAuth2Redirect *create(const QString &configuredUri, QObject *pParent = 0);

  //! Empty if the listener could not be set up. On desktop this reserves the
  //! loopback port, so nothing else knows the URI until this has been called.
  virtual QString redirectUri() = 0;

  //! The return value only says whether a browser window was launched; the
  //! outcome, failures included, always arrives as finished().
  virtual bool start(const QUrl &authorizationUrl, const QString &state) = 0;
  virtual void cancel() = 0;

signals:
  //! One of code or error is set; state is echoed back for checking. Emitted
  //! exactly once per start(), cancellation included, so nobody waits forever.
  void finished(const QString &code, const QString &state, const QString &error);
};

#endif // OAUTH2REDIRECT_H
