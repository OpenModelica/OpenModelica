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

#ifndef COMMITCHANGESDIALOG_H
#define COMMITCHANGESDIALOG_H

#include "QDialog"
#include "QStandardItemModel"
#include "QTreeView"
#include "QPlainTextEdit"
#include "QLineEdit"
#include "QCheckBox"
#include "QDialogButtonBox"

class Label;
class CommitChangesDialog : public QDialog
{
  Q_OBJECT
public:
  CommitChangesDialog(QWidget *pParent = 0);
  void generateTraceabilityURI(QString activity, QString modelFileName, QString nameStructure, QString fmuFileName);
  void commitAndGenerateTraceabilityURI(QString fileName);
private:
  QStandardItemModel *mpCommitChangedFilesModel;
  QTreeView * mpCommitChangedFilesTreeView;
  void getChangedFiles();
  void addFile(QString fileStatus, QString fileName, bool checked);
  QString getFileStatus(QString status);
  QStringList mpModifiedFiles;
  Label *mpRepositoryLabel;
  QLineEdit *mpRepositoryNameTextBox;
  Label *mpBranchLabel;
  QLineEdit *mpBranchNameTextBox;
  Label *mpAuthorLabel;
  QLineEdit *mpAuthorTextBox;
  Label *mpEmailLabel;
  QLineEdit *mpEmailTextBox;
  Label *mpCommitDescriptionLabel;
  QPlainTextEdit *mpCommitDescriptionTextBox;
  QCheckBox *mpSelectAllCheckBox;
  QPushButton *mpCommitButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void commitFiles();
  void commitDescriptionTextChanged();
};

#endif // COMMITCHANGESDIALOG_H
