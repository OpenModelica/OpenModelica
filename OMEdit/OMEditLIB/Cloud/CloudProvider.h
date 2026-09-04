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

#ifndef CLOUDPROVIDER_H
#define CLOUDPROVIDER_H

#include "Cloud/CloudTypes.h"

#include <QByteArray>

#include <functional>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QString>

class OAuth2Client;
class QNetworkAccessManager;
class QNetworkReply;
class QNetworkRequest;

/*!
 * \brief One in-flight cloud operation.
 *
 * Emits finished() exactly once and then deletes itself, so hold one across
 * anything else with a QPointer.
 */
class CloudReply : public QObject
{
  Q_OBJECT
public:
  explicit CloudReply(QObject *pParent = 0) : QObject(pParent) {}

  bool isFinished() const { return mFinished; }
  CloudError error() const { return mError; }

  QList<RemoteItem> items() const { return mItems; }
  RemoteItem item() const { return mItem; }
  QByteArray data() const { return mData; }
  //! Where the next changes() call should resume from.
  QString deltaToken() const { return mDeltaToken; }
  //! Ids the service reported as removed since the delta token.
  QStringList removedIds() const { return mRemovedIds; }

  void abort();

  //! Called by the provider; public so a provider can compose replies.
  void finish(const CloudError &error);
  void setItems(const QList<RemoteItem> &items) { mItems = items; }
  void setItem(const RemoteItem &item) { mItem = item; }
  void setData(const QByteArray &data) { mData = data; }
  void setDeltaToken(const QString &token) { mDeltaToken = token; }
  void setRemovedIds(const QStringList &ids) { mRemovedIds = ids; }
  void trackNetworkReply(QNetworkReply *pNetworkReply);
  //! For an operation that needs several round trips before it can report.
  static CloudReply *pending(QObject *pParent) { return new CloudReply(pParent); }

signals:
  void finished();
  void progress(qint64 done, qint64 total);

private:
  bool mFinished = false;
  bool mAborted = false;
  CloudError mError;
  QList<RemoteItem> mItems;
  RemoteItem mItem;
  QByteArray mData;
  QString mDeltaToken;
  QStringList mRemovedIds;
  QPointer<QNetworkReply> mpNetworkReply;
};

/*!
 * \brief A file service, reduced to what a Modelica package needs.
 *
 * Path-free by design: the sync engine owns the path-to-id mapping, since Drive
 * has no paths and allows two children of one folder to share a name. Deletion is
 * always to the service's trash, never permanent.
 */
class CloudProvider : public QObject
{
  Q_OBJECT
public:
  CloudProvider(OAuth2Client *pOAuth2Client, QNetworkAccessManager *pNetworkAccessManager, QObject *pParent = 0);

  virtual CloudProviderKind kind() const = 0;

  //! The signed-in user, for showing which account this is.
  virtual CloudReply *userInfo() = 0;

  //! The folder this application works in, created on first use. With Drive's
  //! drive.file scope it can only see what it created, so everything lives here.
  virtual CloudReply *appRootFolder() = 0;

  virtual CloudReply *listFolder(const QString &folderId) = 0;
  virtual CloudReply *metadata(const QString &itemId) = 0;
  virtual CloudReply *download(const QString &fileId) = 0;
  virtual CloudReply *createFolder(const QString &parentId, const QString &name) = 0;
  virtual CloudReply *uploadNew(const QString &parentId, const QString &name, const QByteArray &contents) = 0;

  //! Overwrite, but only if the file still has the revision we last saw. Empty
  //! means unguarded, which only happens after the user resolved a conflict.
  virtual CloudReply *uploadUpdate(const QString &fileId, const QByteArray &contents, const QString &expectedRevision) = 0;

  virtual CloudReply *trashItem(const QString &itemId, const QString &expectedRevision) = 0;

  //! A token marking "now", to hand to changes() later.
  virtual CloudReply *currentDeltaToken(const QString &rootId) = 0;
  virtual CloudReply *changes(const QString &rootId, const QString &deltaToken) = 0;

protected:
  //! Send a request with a fresh access token, retrying once on a 401. parse()
  //! turns a successful payload into the reply's result.
  CloudReply *send(const QNetworkRequest &request, const QByteArray &verb, const QByteArray &body,
                   const std::function<void(CloudReply *, const QByteArray &)> &parse);

  //! Status alone is ambiguous on Drive, where 403 covers rate limiting too.
  virtual CloudError classifyError(int status, const QByteArray &payload, const QString &fallback) const;

  OAuth2Client *mpOAuth2Client;
  QNetworkAccessManager *mpNetworkAccessManager;

private:
  void dispatch(CloudReply *pReply, const QNetworkRequest &request, const QByteArray &verb, const QByteArray &body,
                const std::function<void(CloudReply *, const QByteArray &)> &parse, bool isRetry);
};

#endif // CLOUDPROVIDER_H
