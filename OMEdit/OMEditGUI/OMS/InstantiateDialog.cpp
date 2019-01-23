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

#include "InstantiateDialog.h"
#include "Modeling/LibraryTreeWidget.h"
#include "SystemSimulationInformationDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Options/OptionsDialog.h"

#include <QGridLayout>
#include <QMessageBox>

InstantiateDialog::InstantiateDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::instantiateModel, mpLibraryTreeItem->getNameStructure()));
  // heading
  mpSimulationHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::instantiateModel, mpLibraryTreeItem->getNameStructure()));
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  if (!mpLibraryTreeItem->mOMSSimulationOptions.isValid()) {
    // read the start and stop time from the OMS model via API.
    double startTime;
    OMSProxy::instance()->getStartTime(mpLibraryTreeItem->getNameStructure(), &startTime);
    mpLibraryTreeItem->mOMSSimulationOptions.setStartTime(startTime);
    double stopTime;
    OMSProxy::instance()->getStopTime(mpLibraryTreeItem->getNameStructure(), &stopTime);
    mpLibraryTreeItem->mOMSSimulationOptions.setStopTime(stopTime);
    mpLibraryTreeItem->mOMSSimulationOptions.setModelName(mpLibraryTreeItem->getNameStructure());
    mpLibraryTreeItem->mOMSSimulationOptions.setWorkingDirectory(OptionsDialog::instance()->getOMSimulatorPage()->getWorkingDirectory());
    mpLibraryTreeItem->mOMSSimulationOptions.setResultFileName(QString("%1.mat").arg(mpLibraryTreeItem->getNameStructure()));
    mpLibraryTreeItem->mOMSSimulationOptions.setIsValid(true);
  }
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // system simulation information
  mpSystemSimulationInformationWidget = 0;
  QGroupBox *pSystemSimulationInformationGroupBox = 0;
  LibraryTreeItem *pRootSystemLibraryTreeItem = 0;
  if (mpLibraryTreeItem->childrenSize() > 0) {
    pRootSystemLibraryTreeItem = mpLibraryTreeItem->childAt(0);
    if (pRootSystemLibraryTreeItem && pRootSystemLibraryTreeItem->getModelWidget()) {
      mpSystemSimulationInformationWidget = new SystemSimulationInformationWidget(pRootSystemLibraryTreeItem->getModelWidget());
      pSystemSimulationInformationGroupBox = new QGroupBox(Helper::systemSimulationInformation);
      QHBoxLayout *pSystemSimulationInformationGroupBoxLayout = new QHBoxLayout;
      pSystemSimulationInformationGroupBoxLayout->addWidget(mpSystemSimulationInformationWidget);
      pSystemSimulationInformationGroupBox->setLayout(pSystemSimulationInformationGroupBoxLayout);
    }
  }
  // start time
  mpStartTimeLabel = new Label(QString("%1:").arg(Helper::startTime));
  mpStartTimeTextBox = new QLineEdit(QString::number(mpLibraryTreeItem->mOMSSimulationOptions.getStartTime()));
  // stop time
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit(QString::number(mpLibraryTreeItem->mOMSSimulationOptions.getStopTime()));
  // result file
  mpResultFileLabel = new Label(tr("Result File:"));
  mpResultFileTextBox = new QLineEdit(mpLibraryTreeItem->mOMSSimulationOptions.getResultFileName());
  // result file buffer size
  mpResultFileBufferSizeLabel = new Label(tr("Result File Buffer Size:"));
  mpResultFileBufferSizeSpinBox = new QSpinBox;
  mpResultFileBufferSizeSpinBox->setRange(1, INT_MAX);
  mpResultFileBufferSizeSpinBox->setValue(mpLibraryTreeItem->mOMSSimulationOptions.getResultFileBufferSize());
  // logging interval
  mpLoggingIntervalLabel = new Label(tr("Logging Interval:"));
  mpLoggingIntervalTextBox = new QLineEdit("0");
  // signal filter
  mpSignalFilterLabel = new Label(tr("Signal Filter:"));
  mpSignalFilterTextBox = new QLineEdit;
  mpSignalFilterTextBox->setToolTip(tr("Leave empty to include all signals otherwise use a regex to filter."));
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(instantiate()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpSimulationHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  if (pSystemSimulationInformationGroupBox) {
    pMainLayout->addWidget(pSystemSimulationInformationGroupBox, 2, 0, 1, 2);
  }
  pMainLayout->addWidget(mpStartTimeLabel, 3, 0);
  pMainLayout->addWidget(mpStartTimeTextBox, 3, 1);
  pMainLayout->addWidget(mpStopTimeLabel, 4, 0);
  pMainLayout->addWidget(mpStopTimeTextBox, 4, 1);
  pMainLayout->addWidget(mpResultFileLabel, 5, 0);
  pMainLayout->addWidget(mpResultFileTextBox, 5, 1);
  pMainLayout->addWidget(mpResultFileBufferSizeLabel, 6, 0);
  pMainLayout->addWidget(mpResultFileBufferSizeSpinBox, 6, 1);
  pMainLayout->addWidget(mpLoggingIntervalLabel, 7, 0);
  pMainLayout->addWidget(mpLoggingIntervalTextBox, 7, 1);
  pMainLayout->addWidget(mpSignalFilterLabel, 8, 0);
  pMainLayout->addWidget(mpSignalFilterTextBox, 8, 1);
  pMainLayout->addWidget(mpButtonBox, 9, 0, 1, 2);
  setLayout(pMainLayout);
}

void InstantiateDialog::instantiate()
{
  if (mpStartTimeTextBox->text().isEmpty()) {
    mpStartTimeTextBox->setText("0");
  }
  if (mpStopTimeTextBox->text().isEmpty()) {
    mpStopTimeTextBox->setText("1");
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
    return;
  }

  if (mpSystemSimulationInformationWidget) {
    mpSystemSimulationInformationWidget->setSystemSimulationInformation();
  }

  // set the simulation settings
  OMSProxy::instance()->setStartTime(mpLibraryTreeItem->getNameStructure(), mpStartTimeTextBox->text().toDouble());
  mpLibraryTreeItem->mOMSSimulationOptions.setStartTime(mpStartTimeTextBox->text().toDouble());
  OMSProxy::instance()->setStopTime(mpLibraryTreeItem->getNameStructure(), mpStopTimeTextBox->text().toDouble());
  mpLibraryTreeItem->mOMSSimulationOptions.setStopTime(mpStopTimeTextBox->text().toDouble());
  OMSProxy::instance()->setResultFile(mpLibraryTreeItem->getNameStructure(), mpResultFileTextBox->text(),
                                      mpResultFileBufferSizeSpinBox->value());
  mpLibraryTreeItem->mOMSSimulationOptions.setResultFileName(mpResultFileTextBox->text());
  mpLibraryTreeItem->mOMSSimulationOptions.setResultFileBufferSize(mpResultFileBufferSizeSpinBox->value());
  OMSProxy::instance()->setLoggingInterval(mpLibraryTreeItem->getNameStructure(), mpLoggingIntervalTextBox->text().toDouble());
  if (!mpSignalFilterTextBox->text().isEmpty()) {
    OMSProxy::instance()->setSignalFilter(mpLibraryTreeItem->getNameStructure(), mpSignalFilterTextBox->text());
  }

  if (mpLibraryTreeItem->getModelWidget()) {
    mpLibraryTreeItem->getModelWidget()->updateModelText();
  }

  if (!OMSProxy::instance()->instantiate(mpLibraryTreeItem->getNameStructure())) {
    MainWindow::instance()->getOMSInstantiateModelAction()->setChecked(false);
  } else {
    MainWindow::instance()->getOMSInstantiateModelAction()->setText(Helper::terminateInstantiation);
    MainWindow::instance()->getOMSInstantiateModelAction()->setText(Helper::terminateInstantiationTip);
    MainWindow::instance()->getOMSSimulationSetupAction()->setEnabled(true);
    mpLibraryTreeItem->setModelState(oms_modelState_instantiated);
  }
  accept();
}
