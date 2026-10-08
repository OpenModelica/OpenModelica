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

// Native side: the settings directory already survives a restart, so restore()
// and the snapshots are no-ops. Only the secret store is real work — it must not
// end up in the plain settings ini. The web target implements the same functions
// over IndexedDB in OMEditGUI/wasm/persist_store.cpp.

#if !defined(__EMSCRIPTEN__)

#include "Util/PersistentStorage.h"
#include "Util/Helper.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QSettings>

#if defined(Q_OS_WIN)
#include <windows.h>
#include <wincrypt.h>
#endif

namespace {

QString secretsFilePath()
{
  return PersistentStorage::root() + QStringLiteral("/cloud-tokens.json");
}

#if defined(Q_OS_WIN)
// The file is readable by the user's other processes, so wrap each value with the
// user's logon secret rather than storing a usable token.
QByteArray dpapi(const QByteArray &in, bool protect)
{
  DATA_BLOB inBlob;
  inBlob.pbData = reinterpret_cast<BYTE *>(const_cast<char *>(in.constData()));
  inBlob.cbData = static_cast<DWORD>(in.size());
  DATA_BLOB outBlob = {0, nullptr};
  const BOOL ok = protect ? CryptProtectData(&inBlob, L"OMEdit cloud token", nullptr, nullptr, nullptr, 0, &outBlob)
                          : CryptUnprotectData(&inBlob, nullptr, nullptr, nullptr, nullptr, 0, &outBlob);
  if (!ok) {
    return QByteArray();
  }
  const QByteArray out(reinterpret_cast<const char *>(outBlob.pbData), static_cast<int>(outBlob.cbData));
  LocalFree(outBlob.pbData);
  return out;
}
#endif

QByteArray encode(const QByteArray &value)
{
#if defined(Q_OS_WIN)
  return dpapi(value, true).toBase64();
#else
  return value.toBase64();
#endif
}

QByteArray decode(const QByteArray &stored)
{
  const QByteArray raw = QByteArray::fromBase64(stored);
#if defined(Q_OS_WIN)
  return dpapi(raw, false);
#else
  return raw;
#endif
}

QJsonObject readSecrets()
{
  QFile file(secretsFilePath());
  if (!file.open(QIODevice::ReadOnly)) {
    return QJsonObject();
  }
  return QJsonDocument::fromJson(file.readAll()).object();
}

bool writeSecrets(const QJsonObject &object)
{
  QDir().mkpath(PersistentStorage::root());
  QSaveFile file(secretsFilePath());
  if (!file.open(QIODevice::WriteOnly)) {
    return false;
  }
  file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
  if (!file.commit()) {
    return false;
  }
  return QFile::setPermissions(secretsFilePath(), QFileDevice::ReadOwner | QFileDevice::WriteOwner);
}

} // namespace

QString PersistentStorage::root()
{
  static const QString dir =
      QFileInfo(QSettings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application).fileName())
          .absolutePath();
  return dir;
}

bool PersistentStorage::restore()
{
  QDir().mkpath(root());
  return true;
}

void PersistentStorage::scheduleSnapshot() {}

bool PersistentStorage::snapshotNow()
{
  return true;
}

void PersistentStorage::startAutoSnapshot() {}

QByteArray PersistentStorage::secret(const QString &key)
{
  const QJsonValue value = readSecrets().value(key);
  return value.isString() ? decode(value.toString().toUtf8()) : QByteArray();
}

bool PersistentStorage::setSecret(const QString &key, const QByteArray &value)
{
  QJsonObject secrets = readSecrets();
  secrets.insert(key, QString::fromUtf8(encode(value)));
  return writeSecrets(secrets);
}

bool PersistentStorage::removeSecret(const QString &key)
{
  QJsonObject secrets = readSecrets();
  secrets.remove(key);
  return writeSecrets(secrets);
}

QStringList PersistentStorage::secretKeys()
{
  return readSecrets().keys();
}

#endif // !__EMSCRIPTEN__
