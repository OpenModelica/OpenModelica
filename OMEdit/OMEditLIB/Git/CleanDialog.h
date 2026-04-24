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

#ifndef CLEANDIALOG_H
#define CLEANDIALOG_H


#include <QDialog>
#include <QLineEdit>
#include <QCheckBox>
#include <QTreeView>
#include <QPushButton>
#include <QDialogButtonBox>
#include <QStandardItemModel>
#include<QProcess>


class CleanDialog : public QDialog
{
  Q_OBJECT
public:
  CleanDialog(QWidget *pParent = 0);
private:
  QStandardItemModel *mpCleanFilesModel;
  QTreeView * mpCleanFilesTreeView;
  QString *mpworkingDirectory;
  void getUntrackedFiles();
  QStringList checkedFiles() const;
  void addFile(const QString &workingDirectory, QString fileName, bool checked);
  QCheckBox *mpSelectAllCheckBox;
  QPushButton *mpCleanRepositoryButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QProcess *mpProcess;
//private slots:
//  void revertCommit();
//  void browseCommitLog();
//  void workingDirectoryChanged(const QString &workingDirectory);
//  void browseWorkingDirectory();
//  void commitTextChanged(const QString &commit);
public slots:
  void selectAllItems(bool checked);
  void updateSelectAllCheckBox(void);
};

#endif // CLEANDIALOG_H
