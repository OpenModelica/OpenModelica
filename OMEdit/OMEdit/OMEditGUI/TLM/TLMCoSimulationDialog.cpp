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

#ifdef WIN32
#include <winsock2.h>
#else
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#endif

#include "TLMCoSimulationDialog.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Plotting/PlotWindowContainer.h"
#include "Modeling/Commands.h"
#include "TLMCoSimulationOutputWidget.h"
#if !defined(WITHOUT_OSG)
#include "Animation/AnimationWindow.h"
#endif

TLMCoSimulationDialog::TLMCoSimulationDialog(QWidget *pParent)
  : QDialog(pParent)
{
  resize(450, 350);
  setIsTLMCoSimulationRunning(false);
  // simulation widget heading
  mpHeadingLabel = Utilities::getHeadingLabel("");
  mpHeadingLabel->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // TLM Plugin Path
  mpTLMPluginPathLabel = new Label(tr("TLM Plugin Path:"));
  mpTLMPluginPathTextBox = new QLineEdit;
  mpBrowseTLMPluginPathButton = new QPushButton(Helper::browse);
  mpBrowseTLMPluginPathButton->setAutoDefault(false);
  connect(mpBrowseTLMPluginPathButton, SIGNAL(clicked()), SLOT(browseTLMPluginPath()));
  // tlm manager groupbox
  mpTLMManagerGroupBox = new QGroupBox(tr("TLM Manager"));
  // TLM Manager Process
  mpManagerProcessLabel = new Label(tr("Manager Process:"));
  mpManagerProcessTextBox = new QLineEdit;
  mpBrowseManagerProcessButton = new QPushButton(Helper::browse);
  mpBrowseManagerProcessButton->setAutoDefault(false);
  connect(mpBrowseManagerProcessButton, SIGNAL(clicked()), SLOT(browseManagerProcess()));
  // TLM Monitor Process
  mpMonitorProcessLabel = new Label(tr("Monitor Process:"));
  mpMonitorProcessTextBox = new QLineEdit;
  mpBrowseMonitorProcessButton = new QPushButton(Helper::browse);
  mpBrowseMonitorProcessButton->setAutoDefault(false);
  connect(mpBrowseMonitorProcessButton, SIGNAL(clicked()), SLOT(browseMonitorProcess()));
  // manager server port
  mpServerPortLabel = new Label(tr("Server Port:"));
  mpServerPortLabel->setToolTip(tr("Set the server network port for communication with the simulation tools"));
  mpServerPortTextBox = new QLineEdit("11111");
  // manager monitor port
  mpMonitorPortLabel = new Label(tr("Monitor Port:"));
  mpMonitorPortLabel->setToolTip(tr("Set the port for monitoring connections"));
  mpMonitorPortTextBox = new QLineEdit("12111");
  // tlm manager debug mode
  mpManagerDebugModeCheckBox = new QCheckBox(tr("Debug Mode"));
  // tlm manager layout
  QGridLayout *pTLMManagerGridLayout = new QGridLayout;
  pTLMManagerGridLayout->addWidget(mpManagerProcessLabel, 0, 0);
  pTLMManagerGridLayout->addWidget(mpManagerProcessTextBox, 0, 1);
  pTLMManagerGridLayout->addWidget(mpBrowseManagerProcessButton, 0, 2);
  pTLMManagerGridLayout->addWidget(mpServerPortLabel, 1, 0);
  pTLMManagerGridLayout->addWidget(mpServerPortTextBox, 1, 1, 1, 2);
  pTLMManagerGridLayout->addWidget(mpMonitorPortLabel, 2, 0);
  pTLMManagerGridLayout->addWidget(mpMonitorPortTextBox, 2, 1, 1, 2);
  pTLMManagerGridLayout->addWidget(mpManagerDebugModeCheckBox, 3, 0, 1, 3);
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
  pTLMMonitorGridLayout->addWidget(mpMonitorProcessLabel, 0, 0);
  pTLMMonitorGridLayout->addWidget(mpMonitorProcessTextBox, 0, 1);
  pTLMMonitorGridLayout->addWidget(mpBrowseMonitorProcessButton, 0, 2);
  pTLMMonitorGridLayout->addWidget(mpNumberOfStepsLabel, 1, 0);
  pTLMMonitorGridLayout->addWidget(mpNumberOfStepsTextBox, 1, 1, 1, 2);
  pTLMMonitorGridLayout->addWidget(mpTimeStepSizeLabel, 2, 0);
  pTLMMonitorGridLayout->addWidget(mpTimeStepSizeTextBox, 2, 1, 1, 2);
  pTLMMonitorGridLayout->addWidget(mpMonitorDebugModeCheckBox, 3, 0, 1, 3);
  mpTLMMonitorGroupBox->setLayout(pTLMMonitorGridLayout);
  // Create the buttons
  // show TLM Co-simulation output window button
  mpShowTLMCoSimulationOutputWindowButton = new QPushButton(tr("Show TLM Co-Simulation Output Window"));
  mpShowTLMCoSimulationOutputWindowButton->setAutoDefault(false);
  connect(mpShowTLMCoSimulationOutputWindowButton, SIGNAL(clicked()), this, SLOT(showTLMCoSimulationOutputWindow()));
  // run TLM co-simulation button.
  mpRunButton = new QPushButton(Helper::simulate);
  mpRunButton->setAutoDefault(true);
  connect(mpRunButton, SIGNAL(clicked()), this, SLOT(runTLMCoSimulation()));
  // cancel TLM co-simulation dialog button.
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpRunButton, QDialogButtonBox::ActionRole);
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
  pMainLayout->addWidget(mpHeadingLabel, 0, 0, 1, 3);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 3);
  pMainLayout->addWidget(mpTLMPluginPathLabel, 2, 0);
  pMainLayout->addWidget(mpTLMPluginPathTextBox, 2, 1);
  pMainLayout->addWidget(mpBrowseTLMPluginPathButton, 2, 2);
  pMainLayout->addWidget(mpTLMManagerGroupBox, 3, 0, 1, 3);
  pMainLayout->addWidget(mpTLMMonitorGroupBox, 4, 0, 1, 3);
  pMainLayout->addWidget(mpShowTLMCoSimulationOutputWindowButton, 5, 0, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
  // create TLMCoSimulationOutputWidget
  mpTLMCoSimulationOutputWidget = new TLMCoSimulationOutputWidget;
  int xPos = QApplication::desktop()->availableGeometry().width() - mpTLMCoSimulationOutputWidget->frameSize().width() - 20;
  int yPos = QApplication::desktop()->availableGeometry().height() - mpTLMCoSimulationOutputWidget->frameSize().height() - 20;
  mpTLMCoSimulationOutputWidget->setGeometry(xPos, yPos, mpTLMCoSimulationOutputWidget->width(), mpTLMCoSimulationOutputWidget->height());
}

TLMCoSimulationDialog::~TLMCoSimulationDialog()
{
  delete mpTLMCoSimulationOutputWidget;
}

/*!
  Reimplementation of QDialog::show method.
  \param pLibraryTreeItem - pointer to LibraryTreeItem
  */
void TLMCoSimulationDialog::show(LibraryTreeItem *pLibraryTreeItem)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName).arg(Helper::tlmCoSimulationSetup).arg(mpLibraryTreeItem->getName()));
  mpHeadingLabel->setText(QString("%1 - %2").arg(Helper::tlmCoSimulationSetup).arg(mpLibraryTreeItem->getName()));
  // if user has nothing in TLM plugin path then read from OptionsDialog
  if (mpTLMPluginPathTextBox->text().isEmpty()) {
    mpTLMPluginPathTextBox->setText(OptionsDialog::instance()->getTLMPage()->getOMTLMSimulatorPath());
  }
  // if user has nothing in manager process box then read from OptionsDialog
  if (mpManagerProcessTextBox->text().isEmpty()) {
    mpManagerProcessTextBox->setText(OptionsDialog::instance()->getTLMPage()->getOMTLMSimulatorManagerPath());
  }
  // if user has nothing in monitor process box then read from OptionsDialog
  if (mpMonitorProcessTextBox->text().isEmpty()) {
    mpMonitorProcessTextBox->setText(OptionsDialog::instance()->getTLMPage()->getOMTLMSimulatorMonitorPath());
  }
  setVisible(true);
}

void TLMCoSimulationDialog::simulationProcessFinished(TLMCoSimulationOptions tlmCoSimulationOptions, QDateTime resultFileLastModifiedDateTime)
{
  mpTLMCoSimulationOutputWidget->clear();
  // read the result file
  QFileInfo fileInfo(tlmCoSimulationOptions.getFileName());
  QFileInfo resultFileInfo(fileInfo.absoluteDir().absolutePath() + "/" + fileInfo.completeBaseName() + ".csv");
  if (resultFileInfo.exists() && resultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileInfo.absoluteFilePath());
    if (list.size() > 0) {
#if !defined(WITHOUT_OSG)
      // only show the AnimationWindow if we have a visual xml file.
      QFileInfo visualFileInfo(fileInfo.absoluteDir().absolutePath() + "/" + fileInfo.completeBaseName() + "_visual.xml");
      if (visualFileInfo.exists()) {
        MainWindow::instance()->getPlotWindowContainer()->addAnimationWindow(MainWindow::instance()->getPlotWindowContainer()->subWindowList().isEmpty());
        AnimationWindow *pAnimationWindow = MainWindow::instance()->getPlotWindowContainer()->getCurrentAnimationWindow();
        if (pAnimationWindow) {
          pAnimationWindow->openAnimationFile(resultFileInfo.absoluteFilePath());
        }
      }
#endif
      MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(2);
      pVariablesWidget->insertVariablesItemsToTree(resultFileInfo.fileName(), fileInfo.absoluteDir().absolutePath(), list, SimulationOptions());
      MainWindow::instance()->getVariablesDockWidget()->show();
    }
  }
}

/*!
  Validates the simulation values entered by the user.
  */
bool TLMCoSimulationDialog::validate()
{
  if (mpManagerProcessTextBox->text().isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Enter manager process."), Helper::ok);
    mpManagerProcessTextBox->setFocus();
    return false;
  }
  if (mpMonitorProcessTextBox->text().isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Enter monitor process."), Helper::ok);
    mpMonitorProcessTextBox->setFocus();
    return false;
  }
  if (mpMonitorPortTextBox->text().isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Enter a monitor port."), Helper::ok);
    mpMonitorPortTextBox->setFocus();
    return false;
  }
  return true;
}

/*!
 * \brief TLMCoSimulationDialog::createTLMCoSimulationOptions
 * \return
 */
TLMCoSimulationOptions TLMCoSimulationDialog::createTLMCoSimulationOptions()
{
  TLMCoSimulationOptions tlmCoSimulationOptions;
  tlmCoSimulationOptions.setClassName(mpLibraryTreeItem->getName());
  tlmCoSimulationOptions.setFileName(mpLibraryTreeItem->getFileName());
  tlmCoSimulationOptions.setTLMPluginPath(mpTLMPluginPathTextBox->text());
  tlmCoSimulationOptions.setManagerProcess(mpManagerProcessTextBox->text());
  tlmCoSimulationOptions.setServerPort(mpServerPortTextBox->text());
  tlmCoSimulationOptions.setMonitorPort(mpMonitorPortTextBox->text());
  tlmCoSimulationOptions.setManagerDebugMode(mpManagerDebugModeCheckBox->isChecked());
  tlmCoSimulationOptions.setMonitorProcess(mpMonitorProcessTextBox->text());
  tlmCoSimulationOptions.setNumberOfSteps(mpNumberOfStepsTextBox->text().toInt());
  tlmCoSimulationOptions.setTimeStepSize(mpTimeStepSizeTextBox->text().toDouble());
  tlmCoSimulationOptions.setMonitorDebugMode(mpMonitorDebugModeCheckBox->isChecked());
  // manager args
  QStringList managerArgs;
  if (mpManagerDebugModeCheckBox->isChecked()) {
    managerArgs.append("-d");
  }
  if (!mpServerPortTextBox->text().isEmpty()) {
    managerArgs.append("-p");
    managerArgs.append(mpServerPortTextBox->text());
  }
  // monitor args
  QStringList monitorArgs;
  if (mpMonitorDebugModeCheckBox->isChecked()) {
    monitorArgs.append("-d");
  }
  if (!mpNumberOfStepsTextBox->text().isEmpty()) {
    monitorArgs.append("-n");
    monitorArgs.append(mpNumberOfStepsTextBox->text());
  }
  if (!mpTimeStepSizeTextBox->text().isEmpty()) {
    monitorArgs.append("-t");
    monitorArgs.append(mpTimeStepSizeTextBox->text());
  }
  if (!mpMonitorPortTextBox->text().isEmpty()) {
    // set monitor port for manager process
    managerArgs.append("-m");
    managerArgs.append(mpMonitorPortTextBox->text());
    // set monitor server:port for monitor process
#define MAXHOSTNAME 1024
    char myname[MAXHOSTNAME+1];
    struct hostent *hp;
#ifdef WIN32
    WSADATA ws;
    int d;
    d = WSAStartup(0x0101,&ws);
    Q_UNUSED(d);
#endif
    gethostname(myname, MAXHOSTNAME);
    hp = gethostbyname((const char*) myname);
    if (hp == NULL) {
      MessageItem messageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0,
                              tr("Failed to get my hostname, check that name resolves, e.g. /etc/hosts has %1")
                              .arg(QString(myname)), Helper::scriptingKind, Helper::errorLevel);
      MessagesWidget::instance()->addGUIMessage(messageItem);
      tlmCoSimulationOptions.setIsValid(false);
      return tlmCoSimulationOptions;
    }
    char* localIP = inet_ntoa (*(struct in_addr *)*hp->h_addr_list);
    QString monitorPort = QString(localIP) + ":" + mpMonitorPortTextBox->text();
    monitorArgs.append(monitorPort);
  }
  tlmCoSimulationOptions.setManagerArgs(managerArgs);
  tlmCoSimulationOptions.setMonitorArgs(monitorArgs);
  return tlmCoSimulationOptions;
}

/*!
 * \brief TLMCoSimulationDialog::browseTLMPath
 * Browse TLM path.
 */
void TLMCoSimulationDialog::browseTLMPluginPath()
{
  mpTLMPluginPathTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL));
  if (mpManagerProcessTextBox->text().isEmpty()) {
#ifdef WIN32
    mpManagerProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmanager.exe");
#else
    mpManagerProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmanager");
#endif
  }
  if (mpMonitorProcessTextBox->text().isEmpty()) {
#ifdef WIN32
    mpMonitorProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmonitor.exe");
#else
    mpMonitorProcessTextBox->setText(mpTLMPluginPathTextBox->text() + "/tlmmonitor");
#endif
  }
}

/*!
 * \brief TLMCoSimulationDialog::browseManagerProcess
 * Browse TLM Manager Process.
 */
void TLMCoSimulationDialog::browseManagerProcess()
{
  mpManagerProcessTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                  NULL, Helper::exeFileTypes, NULL));
}

/*!
 * \brief TLMCoSimulationDialog::browseMonitorProcess
 * Browse TLM Monitor Process.
 */
void TLMCoSimulationDialog::browseMonitorProcess()
{
  mpMonitorProcessTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                                  NULL, Helper::exeFileTypes, NULL));
}

/*!
 * \brief TLMCoSimulationDialog::showTLMCoSimulationOutputWindow
 * Shows the TLM co-simulation output window.
 */
void TLMCoSimulationDialog::showTLMCoSimulationOutputWindow()
{
  mpTLMCoSimulationOutputWidget->show();
  mpTLMCoSimulationOutputWidget->raise();
  mpTLMCoSimulationOutputWidget->activateWindow();
  mpTLMCoSimulationOutputWidget->setWindowState(mpTLMCoSimulationOutputWidget->windowState() & (~Qt::WindowMinimized | Qt::WindowActive));
}

/*!
 * \brief TLMCoSimulationDialog::simulate
 * Starts the TLM co-simulation
 */
void TLMCoSimulationDialog::runTLMCoSimulation()
{
  if (isTLMCoSimulationRunning()) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::TLMCOSIMULATION_ALREADY_RUNNING), Helper::ok);
    return;
  }
  if (validate()) {
    TLMCoSimulationOptions tlmCoSimulationOptions = createTLMCoSimulationOptions();
    if (tlmCoSimulationOptions.isValid()) {
      setIsTLMCoSimulationRunning(true);
      if (!mpLibraryTreeItem->getModelWidget()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
      }
      mpLibraryTreeItem->getModelWidget()->createModelWidgetComponents();
      // write the visual xml file
      QFileInfo fileInfo(mpLibraryTreeItem->getFileName());
      QString fileName = QString("%1/%2_visual.xml").arg(fileInfo.absolutePath()).arg(fileInfo.baseName());
      mpLibraryTreeItem->getModelWidget()->writeVisualXMLFile(fileName);
      mpTLMCoSimulationOutputWidget->showTLMCoSimulationOutputWidget(tlmCoSimulationOptions);
      showTLMCoSimulationOutputWindow();
      accept();
    }
  }
}

/*!
 * \brief CompositeModelSimulationParamsDialog::CompositeModelSimulationParamsDialog
 * \param pGraphicsView
 */
CompositeModelSimulationParamsDialog::CompositeModelSimulationParamsDialog(GraphicsView *pGraphicsView)
  : QDialog(pGraphicsView)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName).arg(Helper::simulationParams)
                 .arg(pGraphicsView->getModelWidget()->getLibraryTreeItem()->getName()));
  // set heading
  mpSimulationParamsHeading = Utilities::getHeadingLabel(QString("%1 - %2").arg(Helper::simulationParams)
                                                         .arg(pGraphicsView->getModelWidget()->getLibraryTreeItem()->getName()));
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  mpGraphicsView = pGraphicsView;
  mpLibraryTreeItem = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem();
  // Initialize simulation parameters
  mOldStartTime = "";
  mOldStopTime = "";
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
  if(pCompositeModelEditor->isSimulationParams()){
    mOldStartTime = pCompositeModelEditor->getSimulationStartTime();
    mOldStopTime = pCompositeModelEditor->getSimulationStopTime();
  }
  // CoSimulation Interval
  mpStartTimeLabel = new Label(QString("%1:").arg(Helper::startTime));
  mpStartTimeTextBox = new QLineEdit(mOldStartTime);
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit(mOldStopTime);
  // Add the validators
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStartTimeTextBox->setValidator(pDoubleValidator);
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  // buttons
  mpSaveButton = new QPushButton(Helper::save);
  mpSaveButton->setToolTip(tr("Saves the Co-Simulation experiment settings"));
  connect(mpSaveButton, SIGNAL(clicked()), this, SLOT(saveSimulationParams()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // adds Co-Simulation Experiment Setting buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpSaveButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpSimulationParamsHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpStartTimeLabel, 2, 0);
  pMainLayout->addWidget(mpStartTimeTextBox, 2, 1);
  pMainLayout->addWidget(mpStopTimeLabel, 3, 0);
  pMainLayout->addWidget(mpStopTimeTextBox, 3, 1);
  pMainLayout->addWidget(mpButtonBox, 4, 1, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CompositeModelSimulationParamsDialog::saveSimulationParams
 * Saves the Simulation Parameters.
 * Slot activated when mpSave button clicked signal is raised.
 */
void CompositeModelSimulationParamsDialog::saveSimulationParams()
{
  if (validateSimulationParams()) {
    // If user has changed the simulation parameters then push the change on the stack.
    if (!mOldStartTime.compare(mpStartTimeTextBox->text())== 0 || !mOldStopTime.compare(mpStopTimeTextBox->text())== 0) {
      UpdateSimulationParamsCommand *pUpdateSimulationParamsCommand;
      pUpdateSimulationParamsCommand = new UpdateSimulationParamsCommand(mpLibraryTreeItem, mOldStartTime, mpStartTimeTextBox->text(),
                                                                         mOldStopTime, mpStopTimeTextBox->text());
      mpLibraryTreeItem->getModelWidget()->getUndoStack()->push(pUpdateSimulationParamsCommand);
      mpLibraryTreeItem->getModelWidget()->updateModelText();
    }
    accept();
  }
}

/*!
  Validates the simulation params entered by the user.
  */
bool CompositeModelSimulationParamsDialog::validateSimulationParams()
{
  if (mpStartTimeTextBox->text().isEmpty()) {
    mpStartTimeTextBox->setText("0");
  }
  if (mpStopTimeTextBox->text().isEmpty()) {
    mpStopTimeTextBox->setText("1");
  }
  if (mpStartTimeTextBox->text().toDouble() > mpStopTimeTextBox->text().toDouble()) {
    QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::SIMULATION_STARTTIME_LESSTHAN_STOPTIME), Helper::ok);
    return false;
  }
  return true;
}
