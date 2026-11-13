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

#ifndef FMUEXPORTDIALOG_H
#define FMUEXPORTDIALOG_H

#include <QDialog>
#include <QList>
#include <QStringList>

class QCheckBox;
class QComboBox;
class QLineEdit;
class QPushButton;
class LibraryTreeItem;

/*!
 * \class FMUExportDialog
 * \brief The settings of one FMU export. They start as the defaults of the FMI page of the options.
 */
class FMUExportDialog : public QDialog
{
  Q_OBJECT
public:
  FMUExportDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent = 0);
private:
  struct Choices
  {
    QString version;
    QString type;
    int solver;
    int filter;
    bool includeSourceCode;
    QStringList platforms;
  };
  LibraryTreeItem *mpLibraryTreeItem;
  Choices mDefaults;
  bool mDaeModeBefore;
  QString mTargetLanguage;
  bool mWasmTarget;
  QComboBox *mpVersionComboBox;
  QCheckBox *mpModelExchangeCheckBox;
  QCheckBox *mpCoSimulationCheckBox;
  QComboBox *mpSolverComboBox;
  QCheckBox *mpDaeModeCheckBox;
  QComboBox *mpFilterComboBox;
  QCheckBox *mpIncludeSourceCodeCheckBox;
  QList<QCheckBox*> mPlatformCheckBoxes;
  QLineEdit *mpCustomPlatformsTextBox;
  QCheckBox *mpSaveAsDefaultCheckBox;
  QPushButton *mpExportButton;
  Choices choices() const;
  static void writeToOptions(const Choices &choices);
private slots:
  void updateControls();
  void recommendSettings();
  void exportFMU();
};

#endif // FMUEXPORTDIALOG_H
