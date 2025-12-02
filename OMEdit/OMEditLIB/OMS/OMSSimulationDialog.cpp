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

#include "OMSSimulationDialog.h"
#include "MainWindow.h"
#include "Util/Helper.h"
#include "SystemSimulationInformationDialog.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "OMSSimulationOutputWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Plotting/VariablesWidget.h"
#include "Options/OptionsDialog.h"

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class OMSSimulationDialog
 * \brief Displays a dialog with simulation options for OMSimulator.
 */
/*!
 * \brief OMSSimulationDialog::OMSSimulationDialog
 * \param pParent
 */
OMSSimulationDialog::OMSSimulationDialog(QWidget *pParent)
  : QDialog(pParent)
{
  // heading
  mpSimulationHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::simulationSetup, mModelCref));
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // tab widget
  QTabWidget *pTabWidget = new QTabWidget;
  // General tab
  QWidget *pGeneralWidget = new QWidget;
  // system simulation information groupbox
  mpSystemSimulationInformationWidget = 0;
  mpSystemSimulationInformationGroupBox = new QGroupBox(Helper::systemSimulationInformation);
  // start time
  mpStartTimeLabel = new Label(QString("%1:").arg(Helper::startTime));
  mpStartTimeTextBox = new QLineEdit;
  // stop time
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit;
  // result file
  mpResultFileLabel = new Label(tr("Result File:"));
  mpResultFileTextBox = new QLineEdit;
  // result file buffer size
  mpResultFileBufferSizeLabel = new Label(tr("Result File Buffer Size:"));
  mpResultFileBufferSizeSpinBox = new QSpinBox;
  mpResultFileBufferSizeSpinBox->setRange(1, INT_MAX);
  // logging interval
  mpLoggingIntervalLabel = new Label(tr("Logging Interval:"));
  mpLoggingIntervalTextBox = new QLineEdit("0");
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  // General tab widget layout
  QGridLayout *pGeneralTabWidgetGridLayout = new QGridLayout;
  pGeneralTabWidgetGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pGeneralTabWidgetGridLayout->addWidget(mpSystemSimulationInformationGroupBox, 1, 0, 1, 2);
  pGeneralTabWidgetGridLayout->addWidget(mpStartTimeLabel, 2, 0);
  pGeneralTabWidgetGridLayout->addWidget(mpStartTimeTextBox, 2, 1);
  pGeneralTabWidgetGridLayout->addWidget(mpStopTimeLabel, 3, 0);
  pGeneralTabWidgetGridLayout->addWidget(mpStopTimeTextBox, 3, 1);
  pGeneralTabWidgetGridLayout->addWidget(mpResultFileLabel, 4, 0);
  pGeneralTabWidgetGridLayout->addWidget(mpResultFileTextBox, 4, 1);
  pGeneralTabWidgetGridLayout->addWidget(mpResultFileBufferSizeLabel, 5, 0);
  pGeneralTabWidgetGridLayout->addWidget(mpResultFileBufferSizeSpinBox, 5, 1);
  pGeneralTabWidgetGridLayout->addWidget(mpLoggingIntervalLabel, 6, 0);
  pGeneralTabWidgetGridLayout->addWidget(mpLoggingIntervalTextBox, 6, 1);
  pGeneralWidget->setLayout(pGeneralTabWidgetGridLayout);
  pTabWidget->addTab(pGeneralWidget, Helper::general);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(saveSimulationSettings()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainGridLayout->addWidget(mpSimulationHeading, 0, 0);
  pMainGridLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainGridLayout->addWidget(pTabWidget, 2, 0);
  pMainGridLayout->addWidget(mpButtonBox, 3, 0);
  setLayout(pMainGridLayout);
}

int OMSSimulationDialog::exec(const QString &modelCref, LibraryTreeItem *pLibraryTreeItem)
{
  mModelCref = modelCref;
  mpLibraryTreeItem = pLibraryTreeItem;

  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::simulationSetup, mModelCref));
  mpSimulationHeading->setText(QString("%1 - %2").arg(Helper::simulationSetup, mModelCref));
  // initialize system simulation information
  if (mpSystemSimulationInformationWidget) {
    delete mpSystemSimulationInformationGroupBox->layout();
    delete mpSystemSimulationInformationWidget;
    mpSystemSimulationInformationWidget = 0;
  }
  LibraryTreeItem *pTopLibraryTreeItem = LibraryTreeModel::getTopLevelLibraryTreeItem(mpLibraryTreeItem);
  LibraryTreeItem *pRootSystemLibraryTreeItem = 0;
  if (pTopLibraryTreeItem && pTopLibraryTreeItem->childrenSize() > 0) {
    pRootSystemLibraryTreeItem = pTopLibraryTreeItem->childAt(0);
    if (pRootSystemLibraryTreeItem) {
      if (!pRootSystemLibraryTreeItem->getModelWidget()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pRootSystemLibraryTreeItem, false);
      }
      mpSystemSimulationInformationWidget = new SystemSimulationInformationWidget(pRootSystemLibraryTreeItem->getModelWidget());
      QHBoxLayout *pSystemSimulationInformationGroupBoxLayout = new QHBoxLayout;
      pSystemSimulationInformationGroupBoxLayout->addWidget(mpSystemSimulationInformationWidget);
      mpSystemSimulationInformationGroupBox->setLayout(pSystemSimulationInformationGroupBoxLayout);
    }
  }
  // start time
  double startTime;
  OMSProxy::instance()->getStartTime(mModelCref, &startTime);
  mpStartTimeTextBox->setText(QString::number(startTime));
  // stop time
  double stopTime;
  OMSProxy::instance()->getStopTime(mModelCref, &stopTime);
  mpStopTimeTextBox->setText(QString::number(stopTime));
  // result file
  char *fileName = (char*)"";
  int bufferSize;
  OMSProxy::instance()->getResultFile(mModelCref, &fileName, &bufferSize);
  mpResultFileTextBox->setText(QString(fileName));
  // result file buffer size
  mpResultFileBufferSizeSpinBox->setValue(bufferSize);
  mpOkButton->setEnabled(!mpLibraryTreeItem->isSystemLibrary());

  return QDialog::exec();
}

/*!
 * \brief OMSSimulationDialog::simulate
 * Simulates the OMSimulator model.
 * \param pLibraryTreeItem
 */
void OMSSimulationDialog::simulate(LibraryTreeItem *pLibraryTreeItem, bool interactive)
{
  // export the model to a temp directory and send the file location.
  QString fileName = QString("%1/%2.ssp").arg(Utilities::tempDirectory(), pLibraryTreeItem->getNameStructure());
  if (OMSProxy::instance()->saveModel(pLibraryTreeItem->getNameStructure(), fileName)) {
    OMSSimulationOutputWidget *pOMSSimulationOutputWidget = new OMSSimulationOutputWidget(pLibraryTreeItem->getNameStructure(), fileName, interactive);
    MessagesWidget::instance()->addSimulationOutputTab(pOMSSimulationOutputWidget, pLibraryTreeItem->getNameStructure());
    MainWindow::instance()->switchToPlottingPerspectiveSlot();
  }
}

/*!
 * \brief OMSSimulationDialog::simulationFinished
 * Called by OMSSimulationOutputWidget when the simulation is finished.\n
 * Reads the result file and plots the result.
 * \param resultFilePath
 * \param resultFileLastModifiedDateTime
 */
void OMSSimulationDialog::simulationFinished(const QString &resultFilePath, QDateTime resultFileLastModifiedDateTime)
{
  // read the result file
  QFileInfo resultFileInfo(resultFilePath);
  resultFileInfo.setCaching(false);
  QDateTime resultFileModificationTime = resultFileInfo.lastModified();
  bool resultFileExists = resultFileInfo.exists();
  // use secsTo as lastModified returns to second not to mili/nanoseconds, see #5251
  bool resultFileNewer = resultFileLastModifiedDateTime.secsTo(resultFileModificationTime) >= 0;
  if (resultFileExists && resultFileNewer) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileInfo.absoluteFilePath());
    MainWindow::instance()->switchToPlottingPerspectiveSlot();
    pVariablesWidget->insertVariablesItemsToTree(resultFileInfo.fileName(), resultFileInfo.absoluteDir().absolutePath(), list, SimulationOptions());
  }
}

/*!
 * \brief OMSSimulationDialog::saveSimulationSettings
 * Saves the simulation settings.
 */
void OMSSimulationDialog::saveSimulationSettings()
{
  if (mpStartTimeTextBox->text().isEmpty()) {
    mpStartTimeTextBox->setText("0");
  }
  if (mpStopTimeTextBox->text().isEmpty()) {
    mpStopTimeTextBox->setText("1");
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), QMessageBox::Ok);
    return;
  }

  if (mpSystemSimulationInformationWidget) {
    mpSystemSimulationInformationWidget->setSystemSimulationInformation(false);
  }

  // set the simulation settings
  OMSProxy::instance()->setStartTime(mModelCref, mpStartTimeTextBox->text().toDouble());
  OMSProxy::instance()->setStopTime(mModelCref, mpStopTimeTextBox->text().toDouble());
  OMSProxy::instance()->setResultFile(mModelCref, mpResultFileTextBox->text(), mpResultFileBufferSizeSpinBox->value());
  OMSProxy::instance()->setLoggingInterval(mModelCref, mpLoggingIntervalTextBox->text().toDouble());

  ModelWidget *pModelWidget = mpLibraryTreeItem->getModelWidget();
  pModelWidget->createOMSimulatorUndoCommand(QString("Simulation setup %1").arg(mModelCref));
  pModelWidget->updateModelText();
  accept();
}
