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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "TLMCoSimulationDialog.h"
#include "TLMCoSimulationOutputWidget.h"
#include "VariablesWidget.h"

TLMCoSimulationDialog::TLMCoSimulationDialog(MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  mpMainWindow = pMainWindow;
  // simulation widget heading
  mpHeadingLabel = new Label;
  mpHeadingLabel->setElideMode(Qt::ElideMiddle);
  mpHeadingLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  // Horizontal separator
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // tlm manager groupbox
  mpTLMManagerGroupBox = new QGroupBox(tr("TLM Manager"));
  // manager server port
  mpServerPortLabel = new Label(tr("Server Port:"));
  mpServerPortLabel->setToolTip(tr("Set the server network port for communication with the simulation tools"));
  mpServerPortTextBox = new QLineEdit("11111");
  // manager monitor port
  mpMonitorPortLabel = new Label(tr("Monitor Port:"));
  mpMonitorPortLabel->setToolTip(tr("Set the port for monitoring connections"));
  mpMonitorPortTextBox = new QLineEdit("5010");
  // interface request mode
  mpInterfaceRequestModeCheckBox = new QCheckBox(tr("Interface Request Mode"));
  mpInterfaceRequestModeCheckBox->setToolTip(tr("Run manager in interface request mode, get information about interface locations"));
  // tlm manager debug mode
  mpManagerDebugModeCheckBox = new QCheckBox(tr("Debug Mode"));
  // tlm manager layout
  QGridLayout *pTLMManagerGridLayout = new QGridLayout;
  pTLMManagerGridLayout->addWidget(mpServerPortLabel, 0, 0);
  pTLMManagerGridLayout->addWidget(mpServerPortTextBox, 0, 1);
  pTLMManagerGridLayout->addWidget(mpMonitorPortLabel, 1, 0);
  pTLMManagerGridLayout->addWidget(mpMonitorPortTextBox, 1, 1);
  pTLMManagerGridLayout->addWidget(mpInterfaceRequestModeCheckBox, 2, 0, 1, 2);
  pTLMManagerGridLayout->addWidget(mpManagerDebugModeCheckBox, 3, 0, 1, 2);
  mpTLMManagerGroupBox->setLayout(pTLMManagerGridLayout);
  // tlm monitor groupBox
  mpTLMMonitorGroupBox = new QGroupBox(tr("TLM Monitor"));
  // number of steps
  mpNumberOfStepsLabel = new Label(tr("Number Of Steps:"));
  mpNumberOfStepsTextBox = new QLineEdit;
  // time step size
  mpTimeStepSizeLabel = new Label(tr("Time Step Size:"));
  mpTimeStepSizeTextBox = new QLineEdit;
  // tlm monitor debug mode
  mpMonitorDebugModeCheckBox = new QCheckBox(tr("Debug Mode"));
  // tlm monitor layout
  QGridLayout *pTLMMonitorGridLayout = new QGridLayout;
  pTLMMonitorGridLayout->addWidget(mpNumberOfStepsLabel, 0, 0);
  pTLMMonitorGridLayout->addWidget(mpNumberOfStepsTextBox, 0, 1);
  pTLMMonitorGridLayout->addWidget(mpTimeStepSizeLabel, 1, 0);
  pTLMMonitorGridLayout->addWidget(mpTimeStepSizeTextBox, 1, 1);
  pTLMMonitorGridLayout->addWidget(mpMonitorDebugModeCheckBox, 2, 0, 1, 2);
  mpTLMMonitorGroupBox->setLayout(pTLMMonitorGridLayout);
  // Create the buttons
  mpSimulateButton = new QPushButton(Helper::simulate);
  mpSimulateButton->setAutoDefault(true);
  connect(mpSimulateButton, SIGNAL(clicked()), this, SLOT(simulate()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpSimulateButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // validators
  QIntValidator *pIntegerValidator = new QIntValidator(this);
  pIntegerValidator->setBottom(0);
  mpServerPortTextBox->setValidator(pIntegerValidator);
  mpMonitorPortTextBox->setValidator(pIntegerValidator);
  mpNumberOfStepsTextBox->setValidator(pIntegerValidator);
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  pDoubleValidator->setBottom(0);
  mpTimeStepSizeTextBox->setValidator(pDoubleValidator);
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeadingLabel, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpTLMManagerGroupBox, 2, 0);
  pMainLayout->addWidget(mpTLMMonitorGroupBox, 3, 0);
  pMainLayout->addWidget(mpButtonBox, 4, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

TLMCoSimulationDialog::~TLMCoSimulationDialog()
{

}

/*!
  Reimplementation of QDialog::show method.
  \param pLibraryTreeNode - pointer to LibraryTreeNode
  */
void TLMCoSimulationDialog::show(LibraryTreeNode *pLibraryTreeNode)
{
  mpLibraryTreeNode = pLibraryTreeNode;
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName).arg(Helper::tlmCoSimulation).arg(mpLibraryTreeNode->getNameStructure()));
  mpHeadingLabel->setText(QString("%1 - %2").arg(Helper::tlmCoSimulation).arg(mpLibraryTreeNode->getNameStructure()));
  setVisible(true);
}

void TLMCoSimulationDialog::simulationProcessFinished(TLMCoSimulationOptions tlmCoSimulationOptions, QDateTime resultFileLastModifiedDateTime)
{
  // read the result file
  QFileInfo fileInfo(tlmCoSimulationOptions.getFileName());
  QFileInfo resultFileInfo(fileInfo.absoluteDir().absolutePath() + "/" + fileInfo.completeBaseName() + ".csv");
  if (resultFileInfo.exists() && resultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = mpMainWindow->getVariablesWidget();
    OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
    QString currentDirectory = pOMCProxy->changeDirectory();
    pOMCProxy->changeDirectory(fileInfo.absoluteDir().absolutePath());
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileInfo.fileName());
    // close the simulation result file.
    pOMCProxy->closeSimulationResultFile();
    pOMCProxy->changeDirectory(currentDirectory);
    if (list.size() > 0) {
      mpMainWindow->getPerspectiveTabBar()->setCurrentIndex(2);
      pVariablesWidget->insertVariablesItemsToTree(resultFileInfo.fileName(), fileInfo.absoluteDir().absolutePath(), list, SimulationOptions());
      mpMainWindow->getVariablesDockWidget()->show();
    }
  }
}

/*!
  Validates the simulation values entered by the user.
  */
bool TLMCoSimulationDialog::validate()
{
  if (mpMonitorPortTextBox->text().isEmpty()) {
    QMessageBox::critical(mpMainWindow, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Enter a monitor port."), Helper::ok);
    mpMonitorPortTextBox->setFocus();
    return false;
  }
  return true;
}

TLMCoSimulationOptions TLMCoSimulationDialog::createTLMCoSimulationOptions()
{
  TLMCoSimulationOptions tlmCoSimulationOptions;
  tlmCoSimulationOptions.setClassName(mpLibraryTreeNode->getNameStructure());
  tlmCoSimulationOptions.setFileName(mpLibraryTreeNode->getFileName());
  tlmCoSimulationOptions.setServerPort(mpServerPortTextBox->text());
  tlmCoSimulationOptions.setMonitorPort(mpMonitorPortTextBox->text());
  tlmCoSimulationOptions.setInterfaceRequestMode(mpInterfaceRequestModeCheckBox->isChecked());
  tlmCoSimulationOptions.setManagerDebugMode(mpManagerDebugModeCheckBox->isChecked());
  tlmCoSimulationOptions.setNumberOfSteps(mpNumberOfStepsTextBox->text().toInt());
  tlmCoSimulationOptions.setTimeStepSize(mpTimeStepSizeTextBox->text().toDouble());
  tlmCoSimulationOptions.setMonitorDebugMode(mpMonitorDebugModeCheckBox->isChecked());

  QStringList managerArgs;
  QStringList monitorArgs;
  if (mpManagerDebugModeCheckBox->isChecked()) {
    managerArgs.append("-d");
  }
  if (!mpMonitorPortTextBox->text().isEmpty()) {
    // set monitor port for manager process
    managerArgs.append("-m");
    managerArgs.append(mpMonitorPortTextBox->text());
    // set monitor server:port for monitor process
    QString monitorPort = "130.236.182.49:";
    monitorPort.append(mpMonitorPortTextBox->text());
    monitorArgs.append(monitorPort);
  }
  if (!mpServerPortTextBox->text().isEmpty()) {
    managerArgs.append("-p");
    managerArgs.append(mpServerPortTextBox->text());
  }
  if (mpInterfaceRequestModeCheckBox->isChecked()) {
    managerArgs.append("-r");
  }
  if (mpMonitorDebugModeCheckBox->isChecked()) {
    monitorArgs.append("-d");
  }
  if (!mpNumberOfStepsTextBox->text().isEmpty()) {
    monitorArgs.append("-n");
    monitorArgs.append(mpNumberOfStepsTextBox->text());
  }
  if (!mpTimeStepSizeLabel->text().isEmpty()) {
    monitorArgs.append("-t");
    monitorArgs.append(mpTimeStepSizeTextBox->text());
  }
  tlmCoSimulationOptions.setManagerArgs(managerArgs);
  tlmCoSimulationOptions.setMonitorArgs(monitorArgs);
  return tlmCoSimulationOptions;
}

void TLMCoSimulationDialog::simulate()
{
  if (validate()) {
    TLMCoSimulationOptions tlmCoSimulationOptions = createTLMCoSimulationOptions();
    TLMCoSimulationOutputWidget *pTLMCoSimulationOutputWidget = new TLMCoSimulationOutputWidget(tlmCoSimulationOptions, mpMainWindow);
    int xPos = QApplication::desktop()->availableGeometry().width() - pTLMCoSimulationOutputWidget->frameSize().width() - 20;
    int yPos = QApplication::desktop()->availableGeometry().height() - pTLMCoSimulationOutputWidget->frameSize().height() - 20;
    pTLMCoSimulationOutputWidget->setGeometry(xPos, yPos, pTLMCoSimulationOutputWidget->width(), pTLMCoSimulationOutputWidget->height());
    pTLMCoSimulationOutputWidget->show();
    accept();
  }
}
