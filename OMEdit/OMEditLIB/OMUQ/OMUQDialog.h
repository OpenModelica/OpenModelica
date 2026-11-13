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

#ifndef OMUQDIALOG_H
#define OMUQDIALOG_H

#include <QCheckBox>
#include <QComboBox>
#include <QDialog>
#include <QDialogButtonBox>
#include <QJsonArray>
#include <QLineEdit>
#include <QPushButton>
#include <QSpinBox>
#include <QTreeWidget>

class Label;
class LibraryTreeItem;

class OMUQDialog : public QDialog
{
  Q_OBJECT
public:
  OMUQDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  static QString pythonExecutable();
public slots:
  int exec() override;
private:
  LibraryTreeItem *mpLibraryTreeItem;
  QString mPackage;
  QJsonArray mStudies;
  Label *mpHeadingLabel;
  QFrame *mpHorizontalLine;
  Label *mpStudyLabel;
  QComboBox *mpStudyComboBox;
  Label *mpActivityLabel;
  QComboBox *mpActivityComboBox;
  Label *mpActivityInformationLabel;
  QTreeWidget *mpDomainsTreeWidget;
  Label *mpStopTimeLabel;
  QLineEdit *mpStopTimeTextBox;
  Label *mpStepSizeLabel;
  QLineEdit *mpStepSizeTextBox;
  Label *mpReportEveryLabel;
  QSpinBox *mpReportEverySpinBox;
  Label *mpDriverLabel;
  QComboBox *mpDriverComboBox;
  QCheckBox *mpRecordResultsCheckBox;
  QLineEdit *mpResultsFileTextBox;
  QPushButton *mpBrowseResultsFileButton;
  Label *mpLiveViewLabel;
  QComboBox *mpLiveViewComboBox;
  QPushButton *mpRunButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  bool exportPackage();
  bool listStudies();
  QString activityLabel(const QJsonObject &activity) const;
private slots:
  void studyChanged(int index);
  void activityChanged(int index);
  void browseResultsFile();
  void runActivity();
};

#endif // OMUQDIALOG_H
