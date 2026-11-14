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
 * @author John Tinnerholm
 */

#ifndef AUTOLAYOUTDIALOG_H
#define AUTOLAYOUTDIALOG_H

#include <QCheckBox>
#include <QComboBox>
#include <QDialog>
#include <QDoubleSpinBox>
#include <QSpinBox>
#include <QFrame>
#include <QLineEdit>
#include <QPushButton>

#include "AutoLayout.h"

class Label;
class LibraryTreeItem;
class AutoLayoutDialog : public QDialog
{
  Q_OBJECT
public:
  AutoLayoutDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
  static bool apply(LibraryTreeItem *pLibraryTreeItem, const AutoLayout::Options &options, QString *pMessage);
  static bool canUndo(LibraryTreeItem *pLibraryTreeItem);
  static bool changedSinceLayout(LibraryTreeItem *pLibraryTreeItem);
  static bool undo(LibraryTreeItem *pLibraryTreeItem, bool force, QString *pMessage);
private:
  static bool loadClassText(LibraryTreeItem *pLibraryTreeItem, const QString &text, QString *pMessage);
  static void updateUndoAction();
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpClassLabel;
  Label *mpClassNameLabel;
  Label *mpLayoutLabel;
  QComboBox *mpLayoutComboBox;
  Label *mpRouteLabel;
  QComboBox *mpRouteComboBox;
  Label *mpDirectionLabel;
  QComboBox *mpDirectionComboBox;
  Label *mpSpacingLabel;
  QDoubleSpinBox *mpDxSpinBox;
  QDoubleSpinBox *mpDySpinBox;
  Label *mpScaleLabel;
  QDoubleSpinBox *mpScaleSpinBox;
  QCheckBox *mpKeepCheckBox;
  QCheckBox *mpRotateCheckBox;
  Label *mpGraphicsLabel;
  QComboBox *mpGraphicsComboBox;
  Label *mpStackLabel;
  QSpinBox *mpStackSpinBox;
  Label *mpProgramLabel;
  QLineEdit *mpProgramTextBox;
  QPushButton *mpBrowseProgramButton;
  QPushButton *mpLayoutButton;
  QPushButton *mpCancelButton;
private slots:
  void browseProgram();
  void autoLayout();
};

#endif // AUTOLAYOUTDIALOG_H
