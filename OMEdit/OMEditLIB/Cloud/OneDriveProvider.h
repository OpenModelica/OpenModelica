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

#ifndef ONEDRIVEPROVIDER_H
#define ONEDRIVEPROVIDER_H

#include "Cloud/CloudProvider.h"

/*!
 * \brief OneDrive, over Microsoft Graph.
 *
 * Unlike Drive, Graph has real optimistic concurrency: If-Match on the eTag or
 * cTag, so a guarded write either lands or is refused. DELETE is the recycle bin.
 * The application keeps to one folder of its own, as it does on Drive.
 */
class OneDriveProvider : public CloudProvider
{
  Q_OBJECT
public:
  OneDriveProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent = 0);

  CloudProviderKind kind() const override { return CloudProviderKind::OneDrive; }

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

private:
  void listPage(CloudReply *pReply, const QUrl &url, const QList<RemoteItem> &sofar);
  void deltaPage(CloudReply *pReply, const QUrl &url, const QList<RemoteItem> &sofar, const QStringList &removed,
                 bool tokenOnly);
  void uploadSmall(CloudReply *pReply, const QUrl &url, const QByteArray &contents, const QString &expectedRevision);
  void uploadLarge(CloudReply *pReply, const QUrl &sessionUrl, const QByteArray &contents);

  QString mAppRootId;
};

#endif // ONEDRIVEPROVIDER_H
