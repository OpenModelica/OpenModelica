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

#include "Cloud/GoogleDriveProvider.h"
#include "Cloud/OAuth2Client.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>

namespace {

const char *const kApiBase = "https://www.googleapis.com/drive/v3";
const char *const kUploadBase = "https://www.googleapis.com/upload/drive/v3";
const char *const kFolderMimeType = "application/vnd.google-apps.folder";
const char *const kAppFolderName = "OpenModelica";

// Everything the sync engine needs, and nothing else: Drive charges for wide
// field masks in latency.
const char *const kItemFields = "id,name,mimeType,size,modifiedTime,md5Checksum,headRevisionId,parents,trashed";

// Above this a single request is a bad idea, so the upload becomes resumable.
const qint64 kResumableThreshold = 5 * 1024 * 1024;

QString quoteForQuery(const QString &value)
{
  QString escaped = value;
  escaped.replace(QLatin1Char('\\'), QLatin1String("\\\\"));
  escaped.replace(QLatin1Char('\''), QLatin1String("\\'"));
  return escaped;
}

RemoteItem itemFromJson(const QJsonObject &object)
{
  RemoteItem item;
  item.id = object.value(QStringLiteral("id")).toString();
  item.name = object.value(QStringLiteral("name")).toString();
  item.isFolder = object.value(QStringLiteral("mimeType")).toString() == QLatin1String(kFolderMimeType);
  item.size = object.value(QStringLiteral("size")).toString(QStringLiteral("-1")).toLongLong();
  item.modified = QDateTime::fromString(object.value(QStringLiteral("modifiedTime")).toString(), Qt::ISODateWithMs);
  item.contentHash = object.value(QStringLiteral("md5Checksum")).toString();
  // A folder has no revision of its own; its identity is enough.
  item.revision = object.value(QStringLiteral("headRevisionId")).toString();
  const QJsonArray parents = object.value(QStringLiteral("parents")).toArray();
  if (!parents.isEmpty()) {
    item.parentId = parents.first().toString();
  }
  return item;
}

QNetworkRequest jsonRequest(const QUrl &url)
{
  QNetworkRequest request(url);
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
  return request;
}

} // namespace

GoogleDriveProvider::GoogleDriveProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager,
                                         QObject *pParent)
  : CloudProvider(pOAuth2Client, pNetworkAccessManager, pParent)
{
}

CloudError GoogleDriveProvider::classifyError(int status, const QByteArray &payload, const QString &fallback) const
{
  CloudError error = CloudProvider::classifyError(status, payload, fallback);
  if (status != 403) {
    return error;
  }
  // Drive overloads 403: a quota or rate problem is worth retrying, a permission
  // problem is not, and neither is a reason to make the user sign in again.
  const QJsonArray errors = QJsonDocument::fromJson(payload)
                                .object()
                                .value(QStringLiteral("error"))
                                .toObject()
                                .value(QStringLiteral("errors"))
                                .toArray();
  for (const QJsonValue &value : errors) {
    const QString reason = value.toObject().value(QStringLiteral("reason")).toString();
    if (reason == QLatin1String("rateLimitExceeded") || reason == QLatin1String("userRateLimitExceeded")) {
      error.code = CloudError::RateLimited;
      return error;
    }
  }
  return error;
}

CloudReply *GoogleDriveProvider::userInfo()
{
  // Drive's about endpoint, not oauth2/v3/userinfo: that one needs the
  // openid/email/profile scopes, which drive.file exists to avoid asking for.
  QUrl url(QStringLiteral("%1/about").arg(QLatin1String(kApiBase)));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("fields"), QStringLiteral("user(displayName,emailAddress,permissionId)"));
  url.setQuery(query);
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    const QJsonObject user = QJsonDocument::fromJson(payload).object().value(QStringLiteral("user")).toObject();
    const QString email = user.value(QStringLiteral("emailAddress")).toString();
    const QString permissionId = user.value(QStringLiteral("permissionId")).toString();
    RemoteItem account;
    // Whichever identifiers this scope actually yields; the account key only has
    // to be stable, and the name only has to be recognisable.
    account.id = permissionId.isEmpty() ? email : permissionId;
    account.name = email.isEmpty() ? user.value(QStringLiteral("displayName")).toString() : email;
    pReply->setItem(account);
  });
}

CloudReply *GoogleDriveProvider::appRootFolder()
{
  if (!mAppRootId.isEmpty()) {
    CloudReply *pReply = CloudReply::pending(this);
    RemoteItem item;
    item.id = mAppRootId;
    item.name = QLatin1String(kAppFolderName);
    item.isFolder = true;
    pReply->setItem(item);
    pReply->finish(CloudError());
    return pReply;
  }

  CloudReply *pOuter = CloudReply::pending(this);
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("q"), QStringLiteral("name='%1' and mimeType='%2' and trashed=false and 'root' in parents")
                                              .arg(QLatin1String(kAppFolderName), QLatin1String(kFolderMimeType)));
  query.addQueryItem(QStringLiteral("fields"), QStringLiteral("files(%1)").arg(QLatin1String(kItemFields)));
  QUrl url(QStringLiteral("%1/files").arg(QLatin1String(kApiBase)));
  url.setQuery(query);

  CloudReply *pSearch = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    const QJsonArray files = QJsonDocument::fromJson(payload).object().value(QStringLiteral("files")).toArray();
    if (!files.isEmpty()) {
      pReply->setItem(itemFromJson(files.first().toObject()));
    }
  });
  connect(pSearch, &CloudReply::finished, pOuter, [this, pOuter, pSearch]() {
    if (pSearch->error().isError()) {
      pOuter->finish(pSearch->error());
      return;
    }
    if (pSearch->item().isValid()) {
      mAppRootId = pSearch->item().id;
      pOuter->setItem(pSearch->item());
      pOuter->finish(CloudError());
      return;
    }
    // First run for this account: make the folder the application works in.
    cloudLog(QStringLiteral("no application folder yet; creating it"));
    CloudReply *pCreate = createFolder(QStringLiteral("root"), QLatin1String(kAppFolderName));
    connect(pCreate, &CloudReply::finished, pOuter, [this, pOuter, pCreate]() {
      if (!pCreate->error().isError()) {
        mAppRootId = pCreate->item().id;
      }
      pOuter->setItem(pCreate->item());
      pOuter->finish(pCreate->error());
    });
  });
  return pOuter;
}

CloudReply *GoogleDriveProvider::listFolder(const QString &folderId)
{
  CloudReply *pReply = CloudReply::pending(this);
  listPage(pReply, folderId, QString(), QList<RemoteItem>());
  return pReply;
}

void GoogleDriveProvider::listPage(CloudReply *pReply, const QString &folderId, const QString &pageToken,
                                   const QList<RemoteItem> &sofar)
{
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("q"), QStringLiteral("'%1' in parents and trashed=false").arg(quoteForQuery(folderId)));
  query.addQueryItem(QStringLiteral("fields"), QStringLiteral("nextPageToken,files(%1)").arg(QLatin1String(kItemFields)));
  query.addQueryItem(QStringLiteral("pageSize"), QStringLiteral("1000"));
  query.addQueryItem(QStringLiteral("spaces"), QStringLiteral("drive"));
  if (!pageToken.isEmpty()) {
    query.addQueryItem(QStringLiteral("pageToken"), pageToken);
  }
  QUrl url(QStringLiteral("%1/files").arg(QLatin1String(kApiBase)));
  url.setQuery(query);

  CloudReply *pPage = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pInner, const QByteArray &payload) {
    const QJsonObject object = QJsonDocument::fromJson(payload).object();
    QList<RemoteItem> items;
    const QJsonArray files = object.value(QStringLiteral("files")).toArray();
    for (const QJsonValue &value : files) {
      items << itemFromJson(value.toObject());
    }
    pInner->setItems(items);
    pInner->setDeltaToken(object.value(QStringLiteral("nextPageToken")).toString());
  });
  connect(pPage, &CloudReply::finished, pReply, [this, pReply, pPage, folderId, sofar]() {
    if (pPage->error().isError()) {
      pReply->finish(pPage->error());
      return;
    }
    QList<RemoteItem> items = sofar;
    items << pPage->items();
    const QString next = pPage->deltaToken();
    if (next.isEmpty()) {
      pReply->setItems(items);
      pReply->finish(CloudError());
      return;
    }
    listPage(pReply, folderId, next, items);
  });
}

CloudReply *GoogleDriveProvider::metadata(const QString &itemId)
{
  QUrl url(QStringLiteral("%1/files/%2").arg(QLatin1String(kApiBase), itemId));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("fields"), QLatin1String(kItemFields));
  url.setQuery(query);
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
}

CloudReply *GoogleDriveProvider::download(const QString &fileId)
{
  QUrl url(QStringLiteral("%1/files/%2").arg(QLatin1String(kApiBase), fileId));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("alt"), QStringLiteral("media"));
  url.setQuery(query);
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setData(payload);
  });
}

CloudReply *GoogleDriveProvider::createFolder(const QString &parentId, const QString &name)
{
  QJsonObject fileMetadata;
  fileMetadata.insert(QStringLiteral("name"), name);
  fileMetadata.insert(QStringLiteral("mimeType"), QLatin1String(kFolderMimeType));
  fileMetadata.insert(QStringLiteral("parents"), QJsonArray() << parentId);

  QUrl url(QStringLiteral("%1/files").arg(QLatin1String(kApiBase)));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("fields"), QLatin1String(kItemFields));
  url.setQuery(query);
  return send(jsonRequest(url), "POST", QJsonDocument(fileMetadata).toJson(QJsonDocument::Compact),
              [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
}

CloudReply *GoogleDriveProvider::uploadNew(const QString &parentId, const QString &name, const QByteArray &contents)
{
  if (contents.size() >= kResumableThreshold) {
    CloudReply *pReply = CloudReply::pending(this);
    startResumableUpload(pReply, QString(), parentId, name, contents);
    return pReply;
  }

  QJsonObject fileMetadata;
  fileMetadata.insert(QStringLiteral("name"), name);
  fileMetadata.insert(QStringLiteral("parents"), QJsonArray() << parentId);

  // multipart/related: the metadata and the bytes in one request.
  const QByteArray boundary = "omedit-" + QByteArray::number(QDateTime::currentMSecsSinceEpoch(), 16);
  QByteArray body;
  body += "--" + boundary + "\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n";
  body += QJsonDocument(fileMetadata).toJson(QJsonDocument::Compact);
  body += "\r\n--" + boundary + "\r\nContent-Type: application/octet-stream\r\n\r\n";
  body += contents;
  body += "\r\n--" + boundary + "--\r\n";

  QUrl url(QStringLiteral("%1/files").arg(QLatin1String(kUploadBase)));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("uploadType"), QStringLiteral("multipart"));
  query.addQueryItem(QStringLiteral("fields"), QLatin1String(kItemFields));
  url.setQuery(query);

  QNetworkRequest request(url);
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("multipart/related; boundary=%1").arg(QString::fromLatin1(boundary)));
  return send(request, "POST", body, [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
}

CloudReply *GoogleDriveProvider::uploadUpdate(const QString &fileId, const QByteArray &contents,
                                              const QString &expectedRevision)
{
  CloudReply *pReply = CloudReply::pending(this);
  if (expectedRevision.isEmpty()) {
    putContents(pReply, fileId, contents);
    return pReply;
  }
  // Drive v3 offers no conditional write, so the revision is checked first. The
  // gap is real; the next pass closes it and the trash makes a lost race
  // recoverable.
  CloudReply *pCheck = metadata(fileId);
  connect(pCheck, &CloudReply::finished, pReply, [this, pReply, pCheck, fileId, contents, expectedRevision]() {
    if (pCheck->error().isError()) {
      pReply->finish(pCheck->error());
      return;
    }
    if (pCheck->item().revision != expectedRevision) {
      pReply->setItem(pCheck->item());
      pReply->finish(CloudError(CloudError::Conflict, tr("The file changed in Google Drive since it was last synchronised.")));
      return;
    }
    putContents(pReply, fileId, contents);
  });
  return pReply;
}

void GoogleDriveProvider::putContents(CloudReply *pReply, const QString &fileId, const QByteArray &contents)
{
  if (contents.size() >= kResumableThreshold) {
    startResumableUpload(pReply, fileId, QString(), QString(), contents);
    return;
  }
  QUrl url(QStringLiteral("%1/files/%2").arg(QLatin1String(kUploadBase), fileId));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("uploadType"), QStringLiteral("media"));
  query.addQueryItem(QStringLiteral("fields"), QLatin1String(kItemFields));
  url.setQuery(query);

  QNetworkRequest request(url);
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
  CloudReply *pUpload = send(request, "PATCH", contents, [](CloudReply *pInner, const QByteArray &payload) {
    pInner->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
  connect(pUpload, &CloudReply::progress, pReply, &CloudReply::progress);
  connect(pUpload, &CloudReply::finished, pReply, [pReply, pUpload]() {
    pReply->setItem(pUpload->item());
    pReply->finish(pUpload->error());
  });
}

/*!
 * \brief Two-step upload for a file too big to push in one request. The first
 * request returns a one-off URL in Location; the bytes then go there.
 */
void GoogleDriveProvider::startResumableUpload(CloudReply *pReply, const QString &fileId, const QString &parentId,
                                               const QString &name, const QByteArray &contents)
{
  QJsonObject fileMetadata;
  if (fileId.isEmpty()) {
    fileMetadata.insert(QStringLiteral("name"), name);
    fileMetadata.insert(QStringLiteral("parents"), QJsonArray() << parentId);
  }
  QUrl url(fileId.isEmpty() ? QStringLiteral("%1/files").arg(QLatin1String(kUploadBase))
                            : QStringLiteral("%1/files/%2").arg(QLatin1String(kUploadBase), fileId));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("uploadType"), QStringLiteral("resumable"));
  query.addQueryItem(QStringLiteral("fields"), QLatin1String(kItemFields));
  url.setQuery(query);

  QNetworkRequest request = jsonRequest(url);
  request.setRawHeader("X-Upload-Content-Type", "application/octet-stream");
  request.setRawHeader("X-Upload-Content-Length", QByteArray::number(static_cast<qlonglong>(contents.size())));

  // The session URL only comes back in a header, which send()'s parse hook does
  // not see, so this one request is made directly.
  mpOAuth2Client->withAccessToken(pReply, [this, pReply, request, fileMetadata, contents, fileId](const CloudError &tokenError) {
    if (tokenError.isError()) {
      pReply->finish(tokenError);
      return;
    }
    QNetworkRequest authorized(request);
    authorized.setRawHeader("Authorization", "Bearer " + mpOAuth2Client->accessToken().toUtf8());
    QNetworkReply *pStart = mpNetworkAccessManager->sendCustomRequest(
        authorized, fileId.isEmpty() ? "POST" : "PATCH", QJsonDocument(fileMetadata).toJson(QJsonDocument::Compact));
    connect(pStart, &QNetworkReply::finished, pReply, [this, pReply, pStart, contents]() {
      pStart->deleteLater();
      const int status = pStart->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      const QUrl sessionUrl(QString::fromUtf8(pStart->rawHeader("Location")));
      if (status < 200 || status >= 300 || sessionUrl.isEmpty()) {
        pReply->finish(classifyError(status, pStart->readAll(), pStart->errorString()));
        return;
      }
      QNetworkRequest put(sessionUrl);
      put.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
      // The session URL carries its own authorization; Google documents the
      // bearer token as not required here.
      QNetworkReply *pPut = mpNetworkAccessManager->put(put, contents);
      pReply->trackNetworkReply(pPut);
      connect(pPut, &QNetworkReply::finished, pReply, [this, pReply, pPut]() {
        pPut->deleteLater();
        const int putStatus = pPut->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        const QByteArray payload = pPut->readAll();
        if (putStatus < 200 || putStatus >= 300) {
          pReply->finish(classifyError(putStatus, payload, pPut->errorString()));
          return;
        }
        pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
        pReply->finish(CloudError());
      });
    });
  });
}

CloudReply *GoogleDriveProvider::trashItem(const QString &itemId, const QString &expectedRevision)
{
  QJsonObject patch;
  patch.insert(QStringLiteral("trashed"), true);
  QUrl url(QStringLiteral("%1/files/%2").arg(QLatin1String(kApiBase), itemId));

  auto issueTrash = [this, url, patch](CloudReply *pOuter) {
    CloudReply *pTrash = send(jsonRequest(url), "PATCH", QJsonDocument(patch).toJson(QJsonDocument::Compact), 0);
    connect(pTrash, &CloudReply::finished, pOuter, [pOuter, pTrash]() { pOuter->finish(pTrash->error()); });
  };

  CloudReply *pReply = CloudReply::pending(this);
  if (expectedRevision.isEmpty()) {
    issueTrash(pReply);
    return pReply;
  }
  CloudReply *pCheck = metadata(itemId);
  connect(pCheck, &CloudReply::finished, pReply, [pReply, pCheck, expectedRevision, issueTrash]() {
    if (pCheck->error().isError()) {
      pReply->finish(pCheck->error());
      return;
    }
    if (pCheck->item().revision != expectedRevision) {
      pReply->setItem(pCheck->item());
      pReply->finish(CloudError(CloudError::Conflict, tr("The file changed in Google Drive since it was last synchronised.")));
      return;
    }
    issueTrash(pReply);
  });
  return pReply;
}

CloudReply *GoogleDriveProvider::currentDeltaToken(const QString &rootId)
{
  Q_UNUSED(rootId)
  QUrl url(QStringLiteral("%1/changes/startPageToken").arg(QLatin1String(kApiBase)));
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setDeltaToken(QJsonDocument::fromJson(payload).object().value(QStringLiteral("startPageToken")).toString());
  });
}

CloudReply *GoogleDriveProvider::changes(const QString &rootId, const QString &deltaToken)
{
  // Drive reports changes per account rather than per folder; the sync engine
  // only looks at the ids its manifest knows, so the extra noise is harmless.
  Q_UNUSED(rootId)
  CloudReply *pReply = CloudReply::pending(this);
  changesPage(pReply, deltaToken, QList<RemoteItem>(), QStringList());
  return pReply;
}

void GoogleDriveProvider::changesPage(CloudReply *pReply, const QString &pageToken, const QList<RemoteItem> &sofar,
                                      const QStringList &removed)
{
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("pageToken"), pageToken);
  query.addQueryItem(QStringLiteral("pageSize"), QStringLiteral("1000"));
  query.addQueryItem(QStringLiteral("spaces"), QStringLiteral("drive"));
  query.addQueryItem(QStringLiteral("fields"),
                     QStringLiteral("nextPageToken,newStartPageToken,changes(fileId,removed,file(%1))")
                         .arg(QLatin1String(kItemFields)));
  QUrl url(QStringLiteral("%1/changes").arg(QLatin1String(kApiBase)));
  url.setQuery(query);

  CloudReply *pPage = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pInner, const QByteArray &payload) {
    const QJsonObject object = QJsonDocument::fromJson(payload).object();
    QList<RemoteItem> items;
    QStringList removedIds;
    const QJsonArray changes = object.value(QStringLiteral("changes")).toArray();
    for (const QJsonValue &value : changes) {
      const QJsonObject change = value.toObject();
      const QJsonObject file = change.value(QStringLiteral("file")).toObject();
      // "removed" covers a delete; a file moved to the trash is still reported as
      // a normal change, so trashed has to be read as removal too.
      if (change.value(QStringLiteral("removed")).toBool() || file.value(QStringLiteral("trashed")).toBool()) {
        removedIds << change.value(QStringLiteral("fileId")).toString();
      } else if (!file.isEmpty()) {
        items << itemFromJson(file);
      }
    }
    pInner->setItems(items);
    pInner->setRemovedIds(removedIds);
    pInner->setDeltaToken(object.value(QStringLiteral("nextPageToken")).toString());
    pInner->setData(object.value(QStringLiteral("newStartPageToken")).toString().toUtf8());
  });
  connect(pPage, &CloudReply::finished, pReply, [this, pReply, pPage, sofar, removed]() {
    if (pPage->error().isError()) {
      pReply->finish(pPage->error());
      return;
    }
    QList<RemoteItem> items = sofar;
    items << pPage->items();
    QStringList removedIds = removed;
    removedIds << pPage->removedIds();
    const QString next = pPage->deltaToken();
    if (!next.isEmpty()) {
      changesPage(pReply, next, items, removedIds);
      return;
    }
    pReply->setItems(items);
    pReply->setRemovedIds(removedIds);
    // The last page carries the token the next run resumes from.
    pReply->setDeltaToken(QString::fromUtf8(pPage->data()));
    pReply->finish(CloudError());
  });
}
