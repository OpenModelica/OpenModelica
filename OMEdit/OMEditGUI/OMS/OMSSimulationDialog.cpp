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
#include "Modeling/LibraryTreeWidget.h"
#include "OMSSimulationOutputWidget.h"
#include "Options/OptionsDialog.h"
#include "Plotting/VariablesWidget.h"

#include <QGridLayout>
#include <QMessageBox>
#include <QDesktopWidget>

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
  mpLibraryTreeItem = 0;
  // simulation widget heading
  mpSimulationHeading = Utilities::getHeadingLabel("");
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // simulation tab widget
  mpSimulationTabWidget = new QTabWidget;
  // General Tab
  mpGeneralTab = new QWidget;
  // Simulation settings
  // start time
  mpStartTimeLabel = new Label(QString("%1:").arg(Helper::startTime));
  mpStartTimeTextBox = new QLineEdit("0");
  // stop time
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit("1");
  // communication interval
  mpCommunicationIntervalLabel = new Label(tr("Communication Interval"));
  mpCommunicationIntervalTextBox = new QLineEdit("1e-4");
  // master algorithm
  mpMasterAlgorithmLabel = new Label(tr("Master Algorithm:"));
  mpMasterAlgorithmComboBox = new QComboBox;
  mpMasterAlgorithmComboBox->addItem("standard", "standard");
  mpMasterAlgorithmComboBox->addItem("pctpl (experimental)", "pctpl");
  mpMasterAlgorithmComboBox->addItem("pmrchannela (experimental)", "pmrchannela");
  mpMasterAlgorithmComboBox->addItem("pmrchannelcv (experimental)", "pmrchannelcv");
  mpMasterAlgorithmComboBox->addItem("pmrchannelm (experimental)", "pmrchannelm");
  // result file
  mpResultFileLabel = new Label(tr("Result File:"));
  mpResultFileTextBox = new QLineEdit;
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  mpCommunicationIntervalTextBox->setValidator(pDoubleValidator);
  // set General Tab Layout
  QGridLayout *pGeneralTabLayout = new QGridLayout;
  pGeneralTabLayout->setAlignment(Qt::AlignTop);
  pGeneralTabLayout->addWidget(mpStartTimeLabel, 0, 0);
  pGeneralTabLayout->addWidget(mpStartTimeTextBox, 0, 1);
  pGeneralTabLayout->addWidget(mpStopTimeLabel, 1, 0);
  pGeneralTabLayout->addWidget(mpStopTimeTextBox, 1, 1);
  pGeneralTabLayout->addWidget(mpCommunicationIntervalLabel, 2, 0);
  pGeneralTabLayout->addWidget(mpCommunicationIntervalTextBox, 2, 1);
  pGeneralTabLayout->addWidget(mpMasterAlgorithmLabel, 3, 0);
  pGeneralTabLayout->addWidget(mpMasterAlgorithmComboBox, 3, 1);
  pGeneralTabLayout->addWidget(mpResultFileLabel, 4, 0);
  pGeneralTabLayout->addWidget(mpResultFileTextBox, 4, 1);
  mpGeneralTab->setLayout(pGeneralTabLayout);
  // add General Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpGeneralTab, Helper::general);
  // Archived Simulations tab
  mpArchivedSimulationsTab = new QWidget;
  mpArchivedSimulationsTreeWidget = new QTreeWidget;
  mpArchivedSimulationsTreeWidget->setItemDelegate(new ItemDelegate(mpArchivedSimulationsTreeWidget));
  mpArchivedSimulationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpArchivedSimulationsTreeWidget->setColumnCount(4);
  QStringList headers;
  headers << tr("Composite Model") << Helper::dateTime << Helper::startTime << Helper::stopTime << Helper::status;
  mpArchivedSimulationsTreeWidget->setHeaderLabels(headers);
  mpArchivedSimulationsTreeWidget->setIndentation(0);
  connect(mpArchivedSimulationsTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showArchivedSimulation(QTreeWidgetItem*)));
  QGridLayout *pArchivedSimulationsTabLayout = new QGridLayout;
  pArchivedSimulationsTabLayout->setAlignment(Qt::AlignTop);
  pArchivedSimulationsTabLayout->addWidget(mpArchivedSimulationsTreeWidget, 0, 0);
  mpArchivedSimulationsTab->setLayout(pArchivedSimulationsTabLayout);
  // add Archived simulations Tab to Simulation TabWidget
  mpSimulationTabWidget->addTab(mpArchivedSimulationsTab, tr("Archived Simulations"));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(simulate()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(mpSimulationHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpSimulationTabWidget, 2, 0);
  pMainLayout->addWidget(mpButtonBox, 3, 0);
  setLayout(pMainLayout);
}

/*!
 * \brief OMSSimulationDialog::~OMSSimulationDialog
 * OMSSimulationDialog destructor.
 */
OMSSimulationDialog::~OMSSimulationDialog()
{
  foreach (OMSSimulationOutputWidget *pOMSSimulationOutputWidget, mOMSSimulationOutputWidgetsList) {
    delete pOMSSimulationOutputWidget;
  }
  mOMSSimulationOutputWidgetsList.clear();
}

/*!
 * \brief OMSSimulationDialog::show
 * Shows the OMSimulator simulation setup.
 * \param pLibraryTreeItem
 */
void OMSSimulationDialog::show(LibraryTreeItem *pLibraryTreeItem)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  initializeFields();
  setVisible(true);
}

/*!
 * \brief OMSSimulationDialog::createOMSSimulationOptions
 * Creates a OMSSimulationOptions object.
 */
OMSSimulationOptions OMSSimulationDialog::createOMSSimulationOptions()
{
  OMSSimulationOptions omsSimulationOptions;
  omsSimulationOptions.setCompositeModelName(mpLibraryTreeItem->getNameStructure());
  omsSimulationOptions.setStartTime(mpStartTimeTextBox->text().toDouble());
  omsSimulationOptions.setStopTime(mpStopTimeTextBox->text().toDouble());
  omsSimulationOptions.setMasterAlgorithm(mpMasterAlgorithmComboBox->currentText());
  omsSimulationOptions.setWorkingDirectory(OptionsDialog::instance()->getOMSimulatorPage()->getWorkingDirectory());
  omsSimulationOptions.setResultFileName(mpResultFileTextBox->text());
  return omsSimulationOptions;
}

/*!
 * \brief OMSSimulationDialog::simulationFinished
 * Called by OMSSimulationOutputWidget when the simulation is finished.\n
 * Reads the result file and plots the result.
 * \param omsSimulationOptions
 * \param resultFileLastModifiedDateTime
 */
void OMSSimulationDialog::simulationFinished(OMSSimulationOptions omsSimulationOptions, QDateTime resultFileLastModifiedDateTime)
{
  // read the result file
  QFileInfo resultFileInfo(omsSimulationOptions.getWorkingDirectory() + "/" + omsSimulationOptions.getResultFileName());
  if (resultFileInfo.exists() && resultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileInfo.absoluteFilePath());
    // close the simulation result file.
    pOMCProxy->closeSimulationResultFile();
    if (list.size() > 0) {
      MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(2);
      pVariablesWidget->insertVariablesItemsToTree(resultFileInfo.fileName(), omsSimulationOptions.getWorkingDirectory(),
                                                   list, SimulationOptions());
      MainWindow::instance()->getVariablesDockWidget()->show();
    }
  }
}

/*!
 * \brief OMSSimulationDialog::initializeFields
 * Initialize the fields with the default values.
 */
void OMSSimulationDialog::initializeFields()
{
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, Helper::OMSSimulationSetup, mpLibraryTreeItem->getNameStructure()));
  mpSimulationHeading->setText(QString("%1 - %2").arg(Helper::OMSSimulationSetup, mpLibraryTreeItem->getNameStructure()));
  // read the simulation start and stop time
  double startTime = 0;
  if (OMSProxy::instance()->getStartTime(mpLibraryTreeItem->getNameStructure(), &startTime)) {
    mpStartTimeTextBox->setText(QString::number(startTime));
  }
  double stopTime = 1;
  if (OMSProxy::instance()->getStopTime(mpLibraryTreeItem->getNameStructure(), &stopTime)) {
    mpStopTimeTextBox->setText(QString::number(stopTime));
  }
  // set the result file
  mpResultFileTextBox->setText(QString("%1_res.mat").arg(mpLibraryTreeItem->getNameStructure()));
}

/*!
 * \brief OMSSimulationDialog::showArchivedSimulation
 * Slot activated when mpArchivedSimulationsListWidget itemDoubleClicked signal is raised.\n
 * Shows the archived OMSSimulationOutputWidget.
 * \param pTreeWidgetItem
 */
void OMSSimulationDialog::showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem)
{
  ArchivedOMSSimulationItem *pArchivedOMSSimulationItem = dynamic_cast<ArchivedOMSSimulationItem*>(pTreeWidgetItem);
  if (pArchivedOMSSimulationItem) {
    OMSSimulationOutputWidget *pSimulationOutputWidget = pArchivedOMSSimulationItem->getOMSSimulationOutputWidget();
    pSimulationOutputWidget->show();
    pSimulationOutputWidget->raise();
    pSimulationOutputWidget->setWindowState(pSimulationOutputWidget->windowState() & (~Qt::WindowMinimized));
  }
}

/*!
 * \brief OMSSimulationDialog::simulate
 * Slot activated when mpOkButton clicked SIGNAL is triggered.
 * Simulate the OMSimulator composite model.
 */
void OMSSimulationDialog::simulate()
{
  if (mpStartTimeTextBox->text().isEmpty()) {
    mpStartTimeTextBox->setText("0");
  }
  if (mpStopTimeTextBox->text().isEmpty()) {
    mpStopTimeTextBox->setText("1");
  }
  if (mpCommunicationIntervalTextBox->text().isEmpty()) {
    mpCommunicationIntervalTextBox->setText("1e-4");
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
    return;
  }
  bool failed = false;
  // set the simulation settings
  if (OMSProxy::instance()->setStartTime(mpLibraryTreeItem->getNameStructure(), mpStartTimeTextBox->text().toDouble())
      && OMSProxy::instance()->setStopTime(mpLibraryTreeItem->getNameStructure(), mpStopTimeTextBox->text().toDouble())
      && OMSProxy::instance()->setCommunicationInterval(mpLibraryTreeItem->getNameStructure(), mpCommunicationIntervalTextBox->text().toDouble())
      && OMSProxy::instance()->setMasterAlgorithm(mpLibraryTreeItem->getNameStructure(), mpMasterAlgorithmComboBox->currentText())
      && OMSProxy::instance()->setResultFile(mpLibraryTreeItem->getNameStructure(), mpResultFileTextBox->text()))
  {
    OMSSimulationOptions omsSimulationOptions = createOMSSimulationOptions();
    OMSSimulationOutputWidget *pOMSSimulationOutputWidget = new OMSSimulationOutputWidget(omsSimulationOptions);
    mOMSSimulationOutputWidgetsList.append(pOMSSimulationOutputWidget);
    int xPos = QApplication::desktop()->availableGeometry().width() - pOMSSimulationOutputWidget->frameSize().width() - 20;
    int yPos = QApplication::desktop()->availableGeometry().height() - pOMSSimulationOutputWidget->frameSize().height() - 20;
    pOMSSimulationOutputWidget->setGeometry(xPos, yPos, pOMSSimulationOutputWidget->width(), pOMSSimulationOutputWidget->height());
    pOMSSimulationOutputWidget->show();
    accept();
  } else {
    failed = true;
  }
  if (failed) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          QString("%1 %2").arg(tr("Simulation failed."), GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER)),
                          Helper::ok);
    reject();
  }
}
