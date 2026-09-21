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

#ifndef CLOUDCONFLICTDIALOG_H
#define CLOUDCONFLICTDIALOG_H

#include "Cloud/CloudManifest.h"

#include <QDialog>
#include <QHash>
#include <QList>
#include <QString>

class QComboBox;
class QDialogButtonBox;
class QTreeWidget;

/*!
 * \brief Asks what to do with each file that changed on both sides.
 *
 * Three-way: the sync engine has already established that the local copy and the
 * remote one both moved away from the last synced state, so there is no answer
 * that is right by construction and the user picks per file. Keeping both is the
 * default because it is the only choice that discards nothing.
 */
class CloudConflictDialog : public QDialog
{
  Q_OBJECT
public:
  CloudConflictDialog(const QString &remoteName, const QList<SyncAction> &conflicts, QWidget *pParent = 0);

  //! Relative path to a CloudSyncEngine::Resolution.
  QHash<QString, int> resolutions() const;

private:
  void applyToAll(int resolution);

  QTreeWidget *mpTreeWidget;
  QDialogButtonBox *mpButtonBox;
  QHash<QString, QComboBox *> mChoices;
};

#endif // CLOUDCONFLICTDIALOG_H
