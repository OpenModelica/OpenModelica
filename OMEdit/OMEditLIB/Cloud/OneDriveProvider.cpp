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

#include "Cloud/OneDriveProvider.h"
#include "Cloud/OAuth2Client.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>

namespace {

const char *const kGraphBase = "https://graph.microsoft.com/v1.0";
const char *const kAppFolderName = "OpenModelica";

const char *const kItemSelect = "id,name,size,lastModifiedDateTime,eTag,cTag,file,folder,parentReference";

// Graph's own limit for a plain content PUT; anything larger needs a session.
const qint64 kUploadSessionThreshold = 4 * 1024 * 1024;

RemoteItem itemFromJson(const QJsonObject &object)
{
  RemoteItem item;
  item.id = object.value(QStringLiteral("id")).toString();
  item.name = object.value(QStringLiteral("name")).toString();
  item.isFolder = object.contains(QStringLiteral("folder"));
  // toDouble, not the Qt 6 only toInteger; a size is exact as a double.
  item.size = qint64(object.value(QStringLiteral("size")).toDouble(-1));
  item.modified = QDateTime::fromString(object.value(QStringLiteral("lastModifiedDateTime")).toString(), Qt::ISODateWithMs);
  item.parentId = object.value(QStringLiteral("parentReference")).toObject().value(QStringLiteral("id")).toString();
  // cTag changes only when the contents change; eTag also moves on a metadata
  // edit, so cTag is the better "did the file change" signal where it exists.
  const QString cTag = object.value(QStringLiteral("cTag")).toString();
  item.revision = cTag.isEmpty() ? object.value(QStringLiteral("eTag")).toString() : cTag;
  const QJsonObject hashes = object.value(QStringLiteral("file")).toObject().value(QStringLiteral("hashes")).toObject();
  item.contentHash = hashes.value(QStringLiteral("quickXorHash")).toString(
      hashes.value(QStringLiteral("sha256Hash")).toString());
  return item;
}

QNetworkRequest jsonRequest(const QUrl &url)
{
  QNetworkRequest request(url);
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
  return request;
}

//! Graph puts a name into the path; a Modelica class name never needs more, but
//! a colon would end the addressing segment, so it is encoded regardless.
QString encodePathSegment(const QString &name)
{
  return QString::fromUtf8(QUrl::toPercentEncoding(name));
}

QUrl itemUrl(const QString &itemId, const QString &suffix = QString())
{
  QUrl url(QStringLiteral("%1/me/drive/items/%2%3").arg(QLatin1String(kGraphBase), itemId, suffix));
  return url;
}

} // namespace

OneDriveProvider::OneDriveProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager,
                                   QObject *pParent)
  : CloudProvider(pOAuth2Client, pNetworkAccessManager, pParent)
{
}

CloudReply *OneDriveProvider::userInfo()
{
  QUrl url(QStringLiteral("%1/me").arg(QLatin1String(kGraphBase)));
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    const QJsonObject object = QJsonDocument::fromJson(payload).object();
    RemoteItem account;
    account.id = object.value(QStringLiteral("id")).toString();
    account.name = object.value(QStringLiteral("mail")).toString(
        object.value(QStringLiteral("userPrincipalName")).toString());
    pReply->setItem(account);
  });
}

CloudReply *OneDriveProvider::appRootFolder()
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
  QUrl url(QStringLiteral("%1/me/drive/root:/%2").arg(QLatin1String(kGraphBase), QLatin1String(kAppFolderName)));
  CloudReply *pLookup = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
  connect(pLookup, &CloudReply::finished, pOuter, [this, pOuter, pLookup]() {
    if (!pLookup->error().isError()) {
      mAppRootId = pLookup->item().id;
      pOuter->setItem(pLookup->item());
      pOuter->finish(CloudError());
      return;
    }
    if (pLookup->error().code != CloudError::NotFound) {
      pOuter->finish(pLookup->error());
      return;
    }
    // First run for this account.
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

CloudReply *OneDriveProvider::listFolder(const QString &folderId)
{
  CloudReply *pReply = CloudReply::pending(this);
  QUrl url(QStringLiteral("%1/me/drive/items/%2/children").arg(QLatin1String(kGraphBase), folderId));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("$select"), QLatin1String(kItemSelect));
  url.setQuery(query);
  listPage(pReply, url, QList<RemoteItem>());
  return pReply;
}

void OneDriveProvider::listPage(CloudReply *pReply, const QUrl &url, const QList<RemoteItem> &sofar)
{
  CloudReply *pPage = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pInner, const QByteArray &payload) {
    const QJsonObject object = QJsonDocument::fromJson(payload).object();
    QList<RemoteItem> items;
    const QJsonArray values = object.value(QStringLiteral("value")).toArray();
    for (const QJsonValue &value : values) {
      items << itemFromJson(value.toObject());
    }
    pInner->setItems(items);
    // Graph hands back a full URL for the next page rather than a token.
    pInner->setDeltaToken(object.value(QStringLiteral("@odata.nextLink")).toString());
  });
  connect(pPage, &CloudReply::finished, pReply, [this, pReply, pPage, sofar]() {
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
    listPage(pReply, QUrl(next), items);
  });
}

CloudReply *OneDriveProvider::metadata(const QString &itemId)
{
  QUrl url = itemUrl(itemId);
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("$select"), QLatin1String(kItemSelect));
  url.setQuery(query);
  return send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
}

/*!
 * \brief Fetch a file's bytes, in two steps and deliberately: /content redirects
 * to a pre-authenticated URL that refuses a request also carrying an
 * Authorization header, which is what following the redirect would send.
 */
CloudReply *OneDriveProvider::download(const QString &fileId)
{
  CloudReply *pReply = CloudReply::pending(this);
  QUrl url = itemUrl(fileId);
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("$select"), QStringLiteral("id,@microsoft.graph.downloadUrl"));
  url.setQuery(query);
  CloudReply *pLookup = send(QNetworkRequest(url), "GET", QByteArray(),
                             [](CloudReply *pInner, const QByteArray &payload) {
    pInner->setData(QJsonDocument::fromJson(payload)
                        .object()
                        .value(QStringLiteral("@microsoft.graph.downloadUrl"))
                        .toString()
                        .toUtf8());
  });
  connect(pLookup, &CloudReply::finished, pReply, [this, pReply, pLookup]() {
    if (pLookup->error().isError()) {
      pReply->finish(pLookup->error());
      return;
    }
    const QUrl downloadUrl(QString::fromUtf8(pLookup->data()));
    if (!downloadUrl.isValid() || downloadUrl.isEmpty()) {
      pReply->finish(CloudError(CloudError::Protocol, tr("OneDrive returned no download URL.")));
      return;
    }
    QNetworkReply *pGet = mpNetworkAccessManager->get(QNetworkRequest(downloadUrl));
    pReply->trackNetworkReply(pGet);
    connect(pGet, &QNetworkReply::finished, pReply, [this, pReply, pGet]() {
      pGet->deleteLater();
      const int status = pGet->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      const QByteArray payload = pGet->readAll();
      if (status < 200 || status >= 300) {
        pReply->finish(classifyError(status, payload, pGet->errorString()));
        return;
      }
      pReply->setData(payload);
      pReply->finish(CloudError());
    });
  });
  return pReply;
}

CloudReply *OneDriveProvider::createFolder(const QString &parentId, const QString &name)
{
  QJsonObject folder;
  folder.insert(QStringLiteral("name"), name);
  folder.insert(QStringLiteral("folder"), QJsonObject());
  // Two mounts of the same package must not silently merge into one folder.
  folder.insert(QStringLiteral("@microsoft.graph.conflictBehavior"), QStringLiteral("fail"));

  const QUrl url = parentId == QLatin1String("root")
                       ? QUrl(QStringLiteral("%1/me/drive/root/children").arg(QLatin1String(kGraphBase)))
                       : itemUrl(parentId, QStringLiteral("/children"));
  return send(jsonRequest(url), "POST", QJsonDocument(folder).toJson(QJsonDocument::Compact),
              [](CloudReply *pReply, const QByteArray &payload) {
    pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
}

CloudReply *OneDriveProvider::uploadNew(const QString &parentId, const QString &name, const QByteArray &contents)
{
  CloudReply *pReply = CloudReply::pending(this);
  if (contents.size() < kUploadSessionThreshold) {
    const QUrl url(QStringLiteral("%1/me/drive/items/%2:/%3:/content")
                       .arg(QLatin1String(kGraphBase), parentId, encodePathSegment(name)));
    uploadSmall(pReply, url, contents, QString());
    return pReply;
  }
  const QUrl sessionUrl(QStringLiteral("%1/me/drive/items/%2:/%3:/createUploadSession")
                            .arg(QLatin1String(kGraphBase), parentId, encodePathSegment(name)));
  uploadLarge(pReply, sessionUrl, contents);
  return pReply;
}

CloudReply *OneDriveProvider::uploadUpdate(const QString &fileId, const QByteArray &contents,
                                           const QString &expectedRevision)
{
  CloudReply *pReply = CloudReply::pending(this);
  if (contents.size() < kUploadSessionThreshold) {
    uploadSmall(pReply, itemUrl(fileId, QStringLiteral("/content")), contents, expectedRevision);
    return pReply;
  }
  // An upload session takes no If-Match, so the guard is a conditional metadata
  // read first. Unlike Drive this is the exception rather than the rule.
  const QUrl sessionUrl = itemUrl(fileId, QStringLiteral("/createUploadSession"));
  if (expectedRevision.isEmpty()) {
    uploadLarge(pReply, sessionUrl, contents);
    return pReply;
  }
  CloudReply *pCheck = metadata(fileId);
  connect(pCheck, &CloudReply::finished, pReply, [this, pReply, pCheck, sessionUrl, contents, expectedRevision]() {
    if (pCheck->error().isError()) {
      pReply->finish(pCheck->error());
      return;
    }
    if (pCheck->item().revision != expectedRevision) {
      pReply->setItem(pCheck->item());
      pReply->finish(CloudError(CloudError::Conflict, tr("The file changed in OneDrive since it was last synchronised.")));
      return;
    }
    uploadLarge(pReply, sessionUrl, contents);
  });
  return pReply;
}

void OneDriveProvider::uploadSmall(CloudReply *pReply, const QUrl &url, const QByteArray &contents,
                                   const QString &expectedRevision)
{
  QNetworkRequest request(url);
  request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
  if (!expectedRevision.isEmpty()) {
    // Graph refuses the write with 412 if the file moved on; that is exactly the
    // conflict the sync engine wants to hear about.
    request.setRawHeader("If-Match", expectedRevision.toUtf8());
  }
  CloudReply *pUpload = send(request, "PUT", contents, [](CloudReply *pInner, const QByteArray &payload) {
    pInner->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
  });
  connect(pUpload, &CloudReply::progress, pReply, &CloudReply::progress);
  connect(pUpload, &CloudReply::finished, pReply, [pReply, pUpload]() {
    pReply->setItem(pUpload->item());
    pReply->finish(pUpload->error());
  });
}

void OneDriveProvider::uploadLarge(CloudReply *pReply, const QUrl &sessionUrl, const QByteArray &contents)
{
  QJsonObject item;
  item.insert(QStringLiteral("@microsoft.graph.conflictBehavior"), QStringLiteral("replace"));
  QJsonObject body;
  body.insert(QStringLiteral("item"), item);

  CloudReply *pSession = send(jsonRequest(sessionUrl), "POST", QJsonDocument(body).toJson(QJsonDocument::Compact),
                              [](CloudReply *pInner, const QByteArray &payload) {
    pInner->setData(QJsonDocument::fromJson(payload).object().value(QStringLiteral("uploadUrl")).toString().toUtf8());
  });
  connect(pSession, &CloudReply::finished, pReply, [this, pReply, pSession, contents]() {
    if (pSession->error().isError()) {
      pReply->finish(pSession->error());
      return;
    }
    const QUrl uploadUrl(QString::fromUtf8(pSession->data()));
    if (uploadUrl.isEmpty()) {
      pReply->finish(CloudError(CloudError::Protocol, tr("OneDrive returned no upload URL.")));
      return;
    }
    // One PUT of the whole file is within what Graph accepts; chunking only
    // matters for resuming, which a failed pass redoes from the start anyway.
    QNetworkRequest put(uploadUrl);
    put.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
    put.setRawHeader("Content-Range", QStringLiteral("bytes 0-%1/%2")
                                          .arg(contents.size() - 1)
                                          .arg(contents.size())
                                          .toUtf8());
    QNetworkReply *pPut = mpNetworkAccessManager->put(put, contents);
    pReply->trackNetworkReply(pPut);
    connect(pPut, &QNetworkReply::finished, pReply, [this, pReply, pPut]() {
      pPut->deleteLater();
      const int status = pPut->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
      const QByteArray payload = pPut->readAll();
      if (status < 200 || status >= 300) {
        pReply->finish(classifyError(status, payload, pPut->errorString()));
        return;
      }
      pReply->setItem(itemFromJson(QJsonDocument::fromJson(payload).object()));
      pReply->finish(CloudError());
    });
  });
}

CloudReply *OneDriveProvider::trashItem(const QString &itemId, const QString &expectedRevision)
{
  // DELETE on Graph is the recycle bin, not a permanent removal.
  QNetworkRequest request(itemUrl(itemId));
  if (!expectedRevision.isEmpty()) {
    request.setRawHeader("If-Match", expectedRevision.toUtf8());
  }
  return send(request, "DELETE", QByteArray(), 0);
}

CloudReply *OneDriveProvider::currentDeltaToken(const QString &rootId)
{
  CloudReply *pReply = CloudReply::pending(this);
  // token=latest answers with just the token for "now", skipping the listing.
  QUrl url = itemUrl(rootId, QStringLiteral("/delta"));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("token"), QStringLiteral("latest"));
  url.setQuery(query);
  deltaPage(pReply, url, QList<RemoteItem>(), QStringList(), true);
  return pReply;
}

CloudReply *OneDriveProvider::changes(const QString &rootId, const QString &deltaToken)
{
  CloudReply *pReply = CloudReply::pending(this);
  QUrl url = itemUrl(rootId, QStringLiteral("/delta"));
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("token"), deltaToken);
  url.setQuery(query);
  deltaPage(pReply, url, QList<RemoteItem>(), QStringList(), false);
  return pReply;
}

void OneDriveProvider::deltaPage(CloudReply *pReply, const QUrl &url, const QList<RemoteItem> &sofar,
                                 const QStringList &removed, bool tokenOnly)
{
  CloudReply *pPage = send(QNetworkRequest(url), "GET", QByteArray(), [](CloudReply *pInner, const QByteArray &payload) {
    const QJsonObject object = QJsonDocument::fromJson(payload).object();
    QList<RemoteItem> items;
    QStringList removedIds;
    const QJsonArray values = object.value(QStringLiteral("value")).toArray();
    for (const QJsonValue &value : values) {
      const QJsonObject entry = value.toObject();
      if (entry.contains(QStringLiteral("deleted"))) {
        removedIds << entry.value(QStringLiteral("id")).toString();
      } else {
        items << itemFromJson(entry);
      }
    }
    pInner->setItems(items);
    pInner->setRemovedIds(removedIds);
    pInner->setDeltaToken(object.value(QStringLiteral("@odata.nextLink")).toString());
    pInner->setData(object.value(QStringLiteral("@odata.deltaLink")).toString().toUtf8());
  });
  connect(pPage, &CloudReply::finished, pReply, [this, pReply, pPage, sofar, removed, tokenOnly]() {
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
      deltaPage(pReply, QUrl(next), items, removedIds, tokenOnly);
      return;
    }
    if (!tokenOnly) {
      pReply->setItems(items);
      pReply->setRemovedIds(removedIds);
    }
    // The deltaLink is a full URL; only its token is worth keeping, so that a
    // stored token stays valid if the service moves its endpoints.
    const QUrlQuery deltaQuery(QUrl(QString::fromUtf8(pPage->data())).query());
    pReply->setDeltaToken(deltaQuery.queryItemValue(QStringLiteral("token"), QUrl::FullyDecoded));
    pReply->finish(CloudError());
  });
}
