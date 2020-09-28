/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
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

class ArchivedOMSSimulationItem : public QTreeWidgetItem
{
public:
  ArchivedOMSSimulationItem(const QString &cref, const double startTime, const double stopTime, OMSSimulationOutputWidget *pOMSSimulationOutputWidget)
    : mpOMSSimulationOutputWidget(pOMSSimulationOutputWidget)
  {
    setText(0, cref);
    setToolTip(0, cref);
    setText(1, QDateTime::currentDateTime().toString());
    setToolTip(1, QDateTime::currentDateTime().toString());
    setText(2, QString::number(startTime));
    setToolTip(2, QString::number(startTime));
    setText(3, QString::number(stopTime));
    setToolTip(3, QString::number(stopTime));
    setStatus(Helper::running);
  }
  OMSSimulationOutputWidget* getOMSSimulationOutputWidget() {return mpOMSSimulationOutputWidget;}
  void setStatus(QString status) {
    setText(4, status);
    setToolTip(4, status);
  }
private:
  OMSSimulationOutputWidget *mpOMSSimulationOutputWidget;
};

class OMSSimulationDialog : public QDialog
{
  Q_OBJECT
public:
  OMSSimulationDialog(QWidget *pParent = 0);
  ~OMSSimulationDialog();
  int exec(const QString &modelCref, LibraryTreeItem *pLibraryTreeItem);
  void simulate(LibraryTreeItem *pLibraryTreeItem);
  void simulationFinished(const QString &resultFilePath, QDateTime resultFileLastModifiedDateTime);

  QTreeWidget* getArchivedSimulationsTreeWidget() {return mpArchivedSimulationsTreeWidget;}
  QList<OMSSimulationOutputWidget*> getOMSSimulationOutputWidgetsList() {return mOMSSimulationOutputWidgetsList;}
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
  Label *mpSignalFilterLabel;
  QLineEdit *mpSignalFilterTextBox;
  QTreeWidget *mpArchivedSimulationsTreeWidget;
  // buttons
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QList<OMSSimulationOutputWidget*> mOMSSimulationOutputWidgetsList;
public slots:
  void showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem);
  void saveSimulationSettings();
};

#endif // OMSSIMULATIONDIALOG_H
