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

#ifndef CLOUDBROWSERDIALOG_H
#define CLOUDBROWSERDIALOG_H

#include "Cloud/CloudTypes.h"

#include <QDialog>
#include <QString>

class CloudAccount;
class QComboBox;
class QDialogButtonBox;
class QLabel;
class QPushButton;
class QTreeWidget;
class QTreeWidgetItem;

/*!
 * \brief Browse the folders of a cloud account and pick one.
 *
 * The tree starts at the application's own folder, which under drive.file is all
 * OMEdit can see. Children are listed when a folder is first expanded.
 */
class CloudBrowserDialog : public QDialog
{
  Q_OBJECT
public:
  enum Mode {
    //! Pick an existing folder to open as a package.
    OpenFolder,
    //! Pick the folder to save into. A new one can be made from the context menu,
    //! rather than being forced on every save.
    SaveFolder
  };

  CloudBrowserDialog(Mode mode, QWidget *pParent = 0);

  CloudAccount *selectedAccount() const;
  //! The folder to mount: the selection itself, or its parent when a file is picked.
  QString selectedFolderId() const { return mSelectedFolderId; }
  QString selectedFolderName() const { return mSelectedFolderName; }
  //! Set when a file is selected rather than a folder, so it can be opened directly.
  QString selectedFileName() const { return mSelectedFileName; }

private slots:
  void accountChanged();
  void itemExpanded(QTreeWidgetItem *pItem);
  void selectionChanged();
  void showContextMenu(const QPoint &position);
  void createFolder();

private:
  void loadRoot();
  void listInto(QTreeWidgetItem *pItem, const QString &folderId);
  void setBusy(bool busy, const QString &message = QString());

  Mode mMode;
  QComboBox *mpAccountComboBox;
  QTreeWidget *mpTreeWidget;
  QLabel *mpStatusLabel;
  QDialogButtonBox *mpButtonBox;
  QPushButton *mpOkButton;
  QString mSelectedFolderId;
  QString mSelectedFolderName;
  QString mSelectedFileName;
  int mPendingRequests = 0;
};

#endif // CLOUDBROWSERDIALOG_H
