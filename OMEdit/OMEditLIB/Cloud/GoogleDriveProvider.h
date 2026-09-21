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

#ifndef GOOGLEDRIVEPROVIDER_H
#define GOOGLEDRIVEPROVIDER_H

#include "Cloud/CloudProvider.h"

/*!
 * \brief Google Drive, over the v3 REST API.
 *
 * The drive.file scope only sees what the application created, which is what
 * keeps it non-sensitive (no Google app verification) and why everything lives
 * under one folder. Drive v3 has no conditional writes - no If-Match, no ETag on
 * files - so a guarded update is read-revision-then-write and is not atomic.
 */
class GoogleDriveProvider : public CloudProvider
{
  Q_OBJECT
public:
  GoogleDriveProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent = 0);

  CloudProviderKind kind() const override { return CloudProviderKind::GoogleDrive; }

  CloudReply *userInfo() override;
  CloudReply *appRootFolder() override;
  CloudReply *listFolder(const QString &folderId) override;
  CloudReply *metadata(const QString &itemId) override;
  CloudReply *download(const QString &fileId) override;
  CloudReply *createFolder(const QString &parentId, const QString &name) override;
  CloudReply *uploadNew(const QString &parentId, const QString &name, const QByteArray &contents) override;
  CloudReply *uploadUpdate(const QString &fileId, const QByteArray &contents, const QString &expectedRevision) override;
  CloudReply *trashItem(const QString &itemId, const QString &expectedRevision) override;
  CloudReply *currentDeltaToken(const QString &rootId) override;
  CloudReply *changes(const QString &rootId, const QString &deltaToken) override;

protected:
  CloudError classifyError(int status, const QByteArray &payload, const QString &fallback) const override;

private:
  void listPage(CloudReply *pReply, const QString &folderId, const QString &pageToken, const QList<RemoteItem> &sofar);
  void changesPage(CloudReply *pReply, const QString &pageToken, const QList<RemoteItem> &sofar,
                   const QStringList &removed);
  void putContents(CloudReply *pReply, const QString &fileId, const QByteArray &contents);
  void startResumableUpload(CloudReply *pReply, const QString &fileId, const QString &parentId, const QString &name,
                            const QByteArray &contents);

  QString mAppRootId;
};

#endif // GOOGLEDRIVEPROVIDER_H
