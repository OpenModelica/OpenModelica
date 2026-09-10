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

#ifndef PERSISTENTSTORAGE_H
#define PERSISTENTSTORAGE_H

#include <QByteArray>
#include <QString>
#include <QStringList>

/*!
 * \brief Storage that survives a restart of the application.
 *
 * Natively that is just the settings directory. On the web target nothing does:
 * the page filesystem and the omc worker's VFS are both in memory and go away on
 * reload, so the tree under root() is mirrored into IndexedDB and pulled back at
 * startup. Callers see the same ordinary paths on both.
 *
 * Secrets (OAuth refresh tokens) are kept apart from the tree so that clearing
 * settings does not sign the user out, and clearing sign-ins does not lose
 * settings.
 */
namespace PersistentStorage
{
  QString root();

  /*!
   * \brief Bring the persisted tree into place.
   * Must run before anything reads QSettings. Returns false if the store could not
   * be reached, in which case this session simply starts empty.
   */
  bool restore();

  //! Coalesced write-back; safe to call after every change.
  void scheduleSnapshot();
  bool snapshotNow();

  /*!
   * \brief Write the tree back by itself whenever it changes.
   * QSettings reports no changes and there is no filesystem watcher on the web
   * target, so this polls a cheap fingerprint of the tree rather than asking every
   * writer to remember to call scheduleSnapshot(). Call once, after the
   * QApplication exists.
   */
  void startAutoSnapshot();

  QByteArray secret(const QString &key);
  bool setSecret(const QString &key, const QByteArray &value);
  bool removeSecret(const QString &key);
  QStringList secretKeys();
}

#endif // PERSISTENTSTORAGE_H
