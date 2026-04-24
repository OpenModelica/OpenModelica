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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef BREAKPOINTDIALOG_H
#define BREAKPOINTDIALOG_H

#include <QDialog>
#include <QLineEdit>
#include <QCheckBox>
#include <QSpinBox>
#include <QDialogButtonBox>

class BreakpointTreeItem;
class BreakpointsTreeModel;
class Label;

class BreakpointDialog : public QDialog
{
  Q_OBJECT
public:
  BreakpointDialog(BreakpointTreeItem *pBreakpointTreeItem, BreakpointsTreeModel* pBreakpointsTreeModel);
private:
  BreakpointTreeItem *mpBreakpointTreeItem;
  BreakpointsTreeModel *mpBreakpointsTreeModel;
  Label *mpFileNameLabel;
  QLineEdit *mpFileNameTextBox;
  QPushButton *mpBrowseClassesButton;
  QPushButton *mpBrowseFileSystemButton;
  Label *mpLineNumberLabel;
  QLineEdit *mpLineNumberTextBox;
  Label *mpEnableLabel;
  QCheckBox *mpEnableCheckBox;
  Label *mpIgnoreCountLabel;
  QSpinBox *mpIgnoreCountSpinBox;
  Label *mpConditionLabel;
  QLineEdit *mpConditionTextBox;
  Label *mpConditionHintLabel;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void browseClasses();
  void browseFileSystem();
  void addOrEditBreakpoint();
};

#endif // BREAKPOINTDIALOG_H
