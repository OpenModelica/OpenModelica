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

#ifndef OMSSIMULATIONDIALOG_H
#define OMSSIMULATIONDIALOG_H

#include "Util/Utilities.h"
#include "Util/Helper.h"

#include <QDateTime>
#include <QDialog>
#include <QTreeWidget>
#include <QDialogButtonBox>
#include <QHBoxLayout>

class LibraryTreeItem;
class OMSSimulationOutputWidget;
class SystemSimulationInformationWidget;

class OMSSimulationDialog : public QDialog
{
  Q_OBJECT
public:
  OMSSimulationDialog(QWidget *pParent = 0);
  using QDialog::exec;
  int exec(const QString &modelCref, LibraryTreeItem *pLibraryTreeItem);
  void simulate(LibraryTreeItem *pLibraryTreeItem, bool interactive = false);
  void simulationFinished(const QString &resultFilePath, QDateTime resultFileLastModifiedDateTime);
private:
  QString mModelCref;
  LibraryTreeItem *mpLibraryTreeItem;
  Label *mpSimulationHeading;
  QFrame *mpHorizontalLine;
  SystemSimulationInformationWidget *mpSystemSimulationInformationWidget;
  QGroupBox *mpSystemSimulationInformationGroupBox;
  Label *mpStartTimeLabel;
  QLineEdit *mpStartTimeTextBox;
  Label *mpStopTimeLabel;
  QLineEdit *mpStopTimeTextBox;
  Label *mpResultFileLabel;
  QLineEdit *mpResultFileTextBox;
  Label *mpResultFileBufferSizeLabel;
  QSpinBox *mpResultFileBufferSizeSpinBox;
  Label *mpLoggingIntervalLabel;
  QLineEdit *mpLoggingIntervalTextBox;
  // buttons
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QList<OMSSimulationOutputWidget*> mOMSSimulationOutputWidgetsList;
public slots:
  void saveSimulationSettings();
};

#endif // OMSSIMULATIONDIALOG_H
