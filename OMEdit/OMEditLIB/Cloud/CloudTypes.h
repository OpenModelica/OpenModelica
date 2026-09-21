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

#ifndef CLOUDTYPES_H
#define CLOUDTYPES_H

#include <QDateTime>
#include <QMetaType>
#include <QString>

//! Which service an account belongs to.
enum class CloudProviderKind {
  GoogleDrive,
  OneDrive
};

//! Diagnostics; reaches the browser console, which qInfo does not.
void cloudLog(const QString &message);

QString cloudProviderKindToString(CloudProviderKind kind);
bool cloudProviderKindFromString(const QString &text, CloudProviderKind *kind);
QString cloudProviderDisplayName(CloudProviderKind kind);

/*!
 * \brief One file or folder as the service describes it.
 *
 * revision changes on every write (Drive's headRevisionId, Graph's cTag) and is
 * what the sync engine compares against the manifest. contentHash is stronger
 * where it exists, but both services omit it often enough not to rely on it.
 */
struct RemoteItem
{
  QString id;
  QString name;
  QString parentId;
  bool isFolder = false;
  qint64 size = -1;
  QDateTime modified;
  QString revision;
  QString contentHash;

  bool isValid() const { return !id.isEmpty(); }
};

/*!
 * \brief A failure worth telling the user about, or reacting to. Auth means the
 * user has to sign in again; Conflict is a failed precondition on a write, which
 * the sync engine turns into a conflict rather than an error.
 */
struct CloudError
{
  enum Code {
    NoError,
    Network,
    Auth,
    NotFound,
    Conflict,
    RateLimited,
    Protocol,
    Cancelled,
    Provider
  };

  Code code = NoError;
  QString message;
  int httpStatus = 0;

  CloudError() = default;
  CloudError(Code errorCode, const QString &errorMessage, int status = 0)
    : code(errorCode), message(errorMessage), httpStatus(status) {}

  bool isError() const { return code != NoError; }
  static CloudError fromHttpStatus(int status, const QString &message);
};

Q_DECLARE_METATYPE(RemoteItem)
Q_DECLARE_METATYPE(CloudError)

#endif // CLOUDTYPES_H
