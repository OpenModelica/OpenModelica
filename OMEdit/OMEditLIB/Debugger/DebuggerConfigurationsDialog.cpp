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

#include "DebuggerConfigurationsDialog.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Util/Helper.h"
#include "Util/StringHandler.h"
#include "Options/OptionsDialog.h"
#include "MainWindow.h"

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class DebuggerConfigurationPage
 * \brief Represents one debug configuration.
 */
/*!
 * \brief DebuggerConfigurationPage::DebuggerConfigurationPage
 * \param debuggerConfiguration - DebuggerConfiguration
 * \param pListWidgetItem - pointer to QListWidgetItem
 * \param pDebuggerConfigurationsDialog - pointer to DebuggerConfigurationsDialog
 */
DebuggerConfigurationPage::DebuggerConfigurationPage(DebuggerConfiguration debuggerConfiguration, QListWidgetItem *pListWidgetItem,
                                                     DebuggerConfigurationsDialog *pDebuggerConfigurationsDialog)
  : QWidget(pDebuggerConfigurationsDialog)
{
  mDebuggerConfiguration = debuggerConfiguration;
  mpConfigurationListWidgetItem = pListWidgetItem;
  mpDebuggerConfigurationsDialog = pDebuggerConfigurationsDialog;
  QFrame *pContainerFrame = new QFrame;
  pContainerFrame->setFrameShape(QFrame::StyledPanel);
  // Configuration Name
  mpNameLabel = new Label(tr("Name:"));
  mpNameTextBox = new QLineEdit(mDebuggerConfiguration.name);
  // Program File
  mpProgramLabel = new Label(tr("Program:"));
  mpProgramTextBox = new QLineEdit(mDebuggerConfiguration.program);
  mpProgramBrowseButton = new QPushButton(Helper::browse);
  connect(mpProgramBrowseButton, SIGNAL(clicked()), SLOT(browseProgramFile()));
  // Working Directory
  mpWorkingDirectoryLabel = new Label(Helper::workingDirectory);
  mpWorkingDirectoryTextBox = new QLineEdit(mDebuggerConfiguration.workingDirectory);
  mpWorkingDirectoryBrowseButton = new QPushButton(Helper::browse);
  connect(mpWorkingDirectoryBrowseButton, SIGNAL(clicked()), SLOT(browseWorkingDirectory()));
  // GDB Path
  mpGDBPathLabel = new Label(tr("GDB Path:"));
  mpGDBPathTextBox = new QLineEdit(mDebuggerConfiguration.GDBPath);
  mpGDBPathTextBox->setPlaceholderText(OptionsDialog::instance()->getDebuggerPage()->getGDBPath());
  mpGDBPathBrowseButton = new QPushButton(Helper::browse);
  connect(mpGDBPathBrowseButton, SIGNAL(clicked()), SLOT(browseGDBPath()));
  // Arguments
  mpArgumentsLabel = new Label(tr("Arguments:"));
  mpArgumentsTextBox = new QPlainTextEdit(mDebuggerConfiguration.arguments);
  // buttons
  mpApplyButton = new QPushButton(Helper::apply);
  mpApplyButton->setToolTip(tr("Saves the debug configuration"));
  connect(mpApplyButton, SIGNAL(clicked()), SLOT(saveDebugConfiguration()));
  mpResetButton = new QPushButton(Helper::reset);
  mpResetButton->setToolTip(tr("Resets the debug configuration"));
  connect(mpResetButton, SIGNAL(clicked()), SLOT(resetDebugConfiguration()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpApplyButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpResetButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pContainerFrameGridLayout = new QGridLayout;
  pContainerFrameGridLayout->setContentsMargins(3, 3, 3, 3);
  pContainerFrameGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pContainerFrameGridLayout->addWidget(mpNameLabel, 1, 0);
  pContainerFrameGridLayout->addWidget(mpNameTextBox, 1, 1, 1, 2);
  pContainerFrameGridLayout->addWidget(mpProgramLabel, 2, 0);
  pContainerFrameGridLayout->addWidget(mpProgramTextBox, 2, 1);
  pContainerFrameGridLayout->addWidget(mpProgramBrowseButton, 2, 2);
  pContainerFrameGridLayout->addWidget(mpWorkingDirectoryLabel, 3, 0);
  pContainerFrameGridLayout->addWidget(mpWorkingDirectoryTextBox, 3, 1);
  pContainerFrameGridLayout->addWidget(mpWorkingDirectoryBrowseButton, 3, 2);
  pContainerFrameGridLayout->addWidget(mpGDBPathLabel, 4, 0);
  pContainerFrameGridLayout->addWidget(mpGDBPathTextBox, 4, 1);
  pContainerFrameGridLayout->addWidget(mpGDBPathBrowseButton, 4, 2);
  pContainerFrameGridLayout->addItem(new QSpacerItem(1, 1), 5, 0);
  pContainerFrameGridLayout->addWidget(new Label(tr("GDB path defined in %1->Debugger is used if above field is empty.")
                                                 .arg(Helper::toolsOptionsPath)), 5, 1, 1, 2);
  pContainerFrameGridLayout->addWidget(mpArgumentsLabel, 6, 0, 1, 3);
  pContainerFrameGridLayout->addWidget(mpArgumentsTextBox, 7, 0, 1, 3);
  pContainerFrameGridLayout->addWidget(mpButtonBox, 8, 0, 1, 3, Qt::AlignRight);
  pContainerFrame->setLayout(pContainerFrameGridLayout);
  // main layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pContainerFrame, 0, 0);
  setLayout(pMainLayout);
}

/*!
 * \brief DebuggerConfigurationPage::configurationExists
 * Checks if the debugger configuration exists or not.
 * \param configurationKeyToCheck
 * \return
 */
bool DebuggerConfigurationPage::configurationExists(QString configurationKeyToCheck)
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    if (debugConfiguration.name.compare(configurationKeyToCheck) == 0) {
      return true;
    }
  }
  return false;
}

/*!
 * \brief DebuggerConfigurationPage::browseProgramFile
 * Slot activated when mProgramBrowseButton clicked signal is raised.\n
 * Allows user to select program File.
 */
void DebuggerConfigurationPage::browseProgramFile()
{
  QString programFile = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                       NULL, "", NULL);
  if (programFile.isEmpty()) {
    return;
  }
  mpProgramTextBox->setText(programFile);
}

/*!
 * \brief DebuggerConfigurationPage::browseWorkingDirectory
 * Slot activated when mpWorkingDirectoryBrowseButton clicked signal is raised.\n
 * Allows user to select the working directory.
 */
void DebuggerConfigurationPage::browseWorkingDirectory()
{
  mpWorkingDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName)
                                                                         .arg(Helper::chooseDirectory), NULL));
}

/*!
 * \brief DebuggerConfigurationPage::browseGDBPath
 * Slot activated when mpGDBPathBrowseButton clicked signal is raised.\n
 * Allows user to select the GDB path.
 */
void DebuggerConfigurationPage::browseGDBPath()
{
  QString GDBPath = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                   NULL, "", NULL);
  if (GDBPath.isEmpty()) {
    return;
  }
  mpGDBPathTextBox->setText(GDBPath);
}

/*!
 * \brief DebuggerConfigurationPage::saveDebugConfiguration
 * Slot activated when mpApplyButton clicked signal is raised.\n
 * Saves the debug configuration.
 * \return
 */
bool DebuggerConfigurationPage::saveDebugConfiguration()
{
  // First check if there is no configuration with the new name.
  if (mDebuggerConfiguration.name.compare(mpNameTextBox->text()) != 0) {
    if (configurationExists(mpNameTextBox->text())) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::DEBUG_CONFIGURATION_EXISTS_MSG).arg(mpNameTextBox->text())
                            .arg(mDebuggerConfiguration.name), Helper::ok);
      return false;
    }
  }
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  // Remove the debug configuration
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    if (debugConfiguration.name.compare(mDebuggerConfiguration.name) == 0) {
      debugConfigurations.removeOne(debugConfiguration);
      break;
    }
  }
  // create/update the configuration setting.
  mDebuggerConfiguration.name = mpNameTextBox->text();
  mDebuggerConfiguration.program = mpProgramTextBox->text();
  mDebuggerConfiguration.workingDirectory = mpWorkingDirectoryTextBox->text();
  mDebuggerConfiguration.GDBPath = mpGDBPathTextBox->text();
  mDebuggerConfiguration.arguments = mpArgumentsTextBox->toPlainText();
  debugConfigurations.append(QVariant::fromValue(mDebuggerConfiguration));
  pSettings->setValue("debuggerConfigurationList/configurations", debugConfigurations);
  mpConfigurationListWidgetItem->setText(mpNameTextBox->text());
  // update the debug configuration toolbar menu
  MainWindow::instance()->updateDebuggerToolBarMenu();
  return true;
}

/*!
 * \brief DebuggerConfigurationPage::resetDebugConfiguration
 * Slot activated when mpResetButton clicked signal is raised.\n
 * Resets the debug configuration state back to original.
 */
void DebuggerConfigurationPage::resetDebugConfiguration()
{
  mpNameTextBox->setText(mDebuggerConfiguration.name);
  mpProgramTextBox->setText(mDebuggerConfiguration.program);
  mpWorkingDirectoryTextBox->setText(mDebuggerConfiguration.workingDirectory);
  mpGDBPathTextBox->setText(mDebuggerConfiguration.GDBPath);
  mpArgumentsTextBox->clear();
  mpArgumentsTextBox->insertPlainText(mDebuggerConfiguration.arguments);
  mpArgumentsTextBox->document()->setModified(false);
}

/*!
 * \class DebuggerConfigurationsDialog
 * \brief Provides interface for creating and managing the debug configurations.
 */
/*!
 * \brief DebuggerConfigurationsDialog::DebuggerConfigurationsDialog
 * \param pParent
 */
DebuggerConfigurationsDialog::DebuggerConfigurationsDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::debugConfigurations));
  setAttribute(Qt::WA_DeleteOnClose);
  // create tool buttons
  mpNewToolButton = new QToolButton;
  mpNewToolButton->setIcon( QIcon(":/Resources/icons/new.svg"));
  mpNewToolButton->setToolTip(tr("New Configuration"));
  mpNewToolButton->setAutoRaise(true);
  connect(mpNewToolButton, SIGNAL(clicked()), SLOT(newConfiguration()));
  mpDeleteToolButton = new QToolButton;
  mpDeleteToolButton->setIcon( QIcon(":/Resources/icons/delete.svg"));
  mpDeleteToolButton->setToolTip(tr("Delete Configuration"));
  mpDeleteToolButton->setAutoRaise(true);
  connect(mpDeleteToolButton, SIGNAL(clicked()), SLOT(removeConfiguration()));
  // create status bar
  mpStatusBar = new QStatusBar;
  mpStatusBar->setObjectName("ModelStatusBar");
  mpStatusBar->setSizeGripEnabled(false);
  mpStatusBar->addPermanentWidget(mpNewToolButton, 0);
  mpStatusBar->addPermanentWidget(mpDeleteToolButton, 0);
  mpStatusBar->addPermanentWidget(new QLabel, 1);
  // configurations list
  mpConfigurationsListWidget = new QListWidget;
  mpConfigurationsListWidget->setItemDelegate(new ItemDelegate(mpConfigurationsListWidget));
  mpConfigurationsListWidget->setTextElideMode(Qt::ElideMiddle);
  connect(mpConfigurationsListWidget, SIGNAL(currentItemChanged(QListWidgetItem*,QListWidgetItem*)),
          SLOT(changeConfigurationPage(QListWidgetItem*,QListWidgetItem*)));
  // configuration pages
  mpConfigurationPagesWidget = new QStackedWidget;
  /* Configuration settings Page Splitter */
  mpConfigurationsSplitter = new QSplitter;
  mpConfigurationsSplitter->setVisible(false);
  mpConfigurationsSplitter->setChildrenCollapsible(false);
  mpConfigurationsSplitter->setHandleWidth(4);
  mpConfigurationsSplitter->setContentsMargins(0, 0, 0, 0);
  mpConfigurationsSplitter->setOrientation(Qt::Horizontal);
  mpConfigurationsSplitter->addWidget(mpConfigurationsListWidget);
  mpConfigurationsSplitter->addWidget(mpConfigurationPagesWidget);
  mpConfigurationsSplitter->setStretchFactor(0, 1);
  mpConfigurationsSplitter->setStretchFactor(1, 2);
  // buttons
  mpSaveButton = new QPushButton(Helper::save);
  mpSaveButton->setToolTip(tr("Saves all the debug configurations"));
  connect(mpSaveButton, SIGNAL(clicked()), this, SLOT(saveAllConfigurations()));
  mpSaveAndDebugButton = new QPushButton(tr("Save && Debug"));
  mpSaveAndDebugButton->setToolTip(tr("Saves all the debug configurations and starts debugging the active debug configuration"));
  connect(mpSaveAndDebugButton, SIGNAL(clicked()), this, SLOT(saveAllConfigurationsAndDebugConfiguration()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // adds debugger buttons to the button box
  mpConfigurationsButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpConfigurationsButtonBox->setVisible(false);
  mpConfigurationsButtonBox->addButton(mpSaveButton, QDialogButtonBox::ActionRole);
  mpConfigurationsButtonBox->addButton(mpSaveAndDebugButton, QDialogButtonBox::ActionRole);
  mpConfigurationsButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 2);
  pMainLayout->addWidget(mpStatusBar, 0, 0);
  pMainLayout->addWidget(mpConfigurationsSplitter, 1, 0);
  pMainLayout->addWidget(mpConfigurationsButtonBox, 2, 0, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
  // read the saved debug configurations
  readConfigurations();
}

/*!
 * \brief DebuggerConfigurationsDialog::getUniqueName
 * Returns a unique name for debugger configuration.
 * \param name
 * \param number
 * \return
 */
QString DebuggerConfigurationsDialog::getUniqueName(QString name, int number)
{
  QString newName;
  newName = name + QString::number(number);

  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    if (debugConfiguration.name.compare(newName) == 0) {
      newName = getUniqueName(name, ++number);
      break;
    }
  }
  return newName;
}

/*!
 * \brief DebuggerConfigurationsDialog::readConfigurations
 * Reads the list of debugger configurations setting from the settings file.
 */
void DebuggerConfigurationsDialog::readConfigurations()
{
  // read the settings and add configurations
  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    QListWidgetItem *pListWidgetItem = new QListWidgetItem(mpConfigurationsListWidget);
    pListWidgetItem->setIcon(QIcon(":/Resources/icons/debugger.svg"));
    pListWidgetItem->setText(debugConfiguration.name);
    // create DebuggerConfigurationPage
    mpConfigurationPagesWidget->addWidget(new DebuggerConfigurationPage(debugConfiguration, pListWidgetItem, this));
  }
  if (mpConfigurationsListWidget->count() > 0) {
    mpConfigurationsSplitter->setVisible(true);
    mpConfigurationsButtonBox->setVisible(true);
    mpConfigurationsListWidget->setCurrentRow(0, QItemSelectionModel::Select);
  }
}

/*!
 * \brief DebuggerConfigurationsDialog::getDebuggerConfigurationPage
 * Returns the DebuggerConfigurationPage
 * \param configurationName
 * \return
 */
DebuggerConfigurationPage* DebuggerConfigurationsDialog::getDebuggerConfigurationPage(QString configurationName)
{
  for (int i = 0 ; i < mpConfigurationPagesWidget->count() ; i++) {
    DebuggerConfigurationPage *pDebuggerConfigurationPage = qobject_cast<DebuggerConfigurationPage*>(mpConfigurationPagesWidget->widget(i));
    if (pDebuggerConfigurationPage && pDebuggerConfigurationPage->mDebuggerConfiguration.name.compare(configurationName) == 0) {
      return pDebuggerConfigurationPage;
    }
  }
  return 0;
}

/*!
 * \brief DebuggerConfigurationsDialog::runConfiguration
 * Runs the debug configuration.
 * \param pDebuggerConfigurationPage
 */
void DebuggerConfigurationsDialog::runConfiguration(DebuggerConfigurationPage *pDebuggerConfigurationPage)
{
  if (GDBAdapter::instance()->isGDBRunning()) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::DEBUGGER_ALREADY_RUNNING), Helper::ok);
  } else {
    // Remove the debug configuration we are going to run and then add it as first item of debug configurations list.
    QSettings *pSettings = Utilities::getApplicationSettings();
    QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
    foreach (QVariant configuration, debugConfigurations) {
      DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
      if (debugConfiguration.name.compare(pDebuggerConfigurationPage->mDebuggerConfiguration.name) == 0) {
        debugConfigurations.removeOne(debugConfiguration);
        break;
      }
    }
    debugConfigurations.prepend(pDebuggerConfigurationPage->mDebuggerConfiguration);
    pSettings->setValue("debuggerConfigurationList/configurations", debugConfigurations);
    // update the debug configuration toolbar menu
    MainWindow::instance()->updateDebuggerToolBarMenu();
    // Run the debug configuration now
    QString gdbPath = "";
    if (pDebuggerConfigurationPage->mDebuggerConfiguration.GDBPath.isEmpty()) {
      gdbPath = OptionsDialog::instance()->getDebuggerPage()->getGDBPath();
    } else {
      gdbPath = pDebuggerConfigurationPage->mDebuggerConfiguration.GDBPath;
    }
    GDBAdapter::instance()->launch(pDebuggerConfigurationPage->mDebuggerConfiguration.program,
                                   pDebuggerConfigurationPage->mDebuggerConfiguration.workingDirectory,
                                   pDebuggerConfigurationPage->mDebuggerConfiguration.arguments.split(" "), gdbPath);
    emit debuggerLaunched();

  }
}

/*!
 * \brief DebuggerConfigurationsDialog::saveAllConfigurationsHelper
 * Saves all the debug configurations to the settings file.
 * \return true if all debug configurations are saved successfully.
 */
bool DebuggerConfigurationsDialog::saveAllConfigurationsHelper()
{
  int count = mpConfigurationPagesWidget->count();
  for (int i = 0 ; i < count ; i++) {
    DebuggerConfigurationPage *pDebuggerConfigurationPage = qobject_cast<DebuggerConfigurationPage*>(mpConfigurationPagesWidget->widget(i));
    if (pDebuggerConfigurationPage) {
      if (!pDebuggerConfigurationPage->saveDebugConfiguration()) {
        return false;
      }
    }
  }
  return true;
}

/*!
 * \brief DebuggerConfigurationsDialog::newConfiguration
 * Creates a new debugger configuration.
 */
void DebuggerConfigurationsDialog::newConfiguration()
{
  QSettings *pSettings = Utilities::getApplicationSettings();
  // check if maximum limit for debug configurations is reached
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  if (debugConfigurations.size() >= MaxDebugConfigurations) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::DEBUG_CONFIGURATION_SIZE_EXCEED).arg(MaxDebugConfigurations), Helper::ok);
    return;
  }
  // create a new DebuggerConfigurationPage
  DebuggerConfiguration debuggerConfiguration;
  debuggerConfiguration.name = getUniqueName();
  debuggerConfiguration.GDBPath = OptionsDialog::instance()->getDebuggerPage()->getGDBPathForSettings();
  // create a new list item
  QListWidgetItem *pListWidgetItem = new QListWidgetItem(mpConfigurationsListWidget);
  pListWidgetItem->setIcon(QIcon(":/Resources/icons/debugger.svg"));
  pListWidgetItem->setText(debuggerConfiguration.name);
  mpConfigurationPagesWidget->addWidget(new DebuggerConfigurationPage(debuggerConfiguration, pListWidgetItem, this));
  mpConfigurationsListWidget->setCurrentItem(pListWidgetItem, QItemSelectionModel::ClearAndSelect);
  // add the debug configuration to settings
  debugConfigurations.append(debuggerConfiguration);
  pSettings->setValue("debuggerConfigurationList/configurations", debugConfigurations);
  // show the configurations and buttons.
  if (!mpConfigurationsSplitter->isVisible()) {
    mpConfigurationsSplitter->setVisible(true);
  }
  if (!mpConfigurationsButtonBox->isVisible()) {
    mpConfigurationsButtonBox->setVisible(true);
    adjustSize();
  }
  // update the debug configuration toolbar menu
  MainWindow::instance()->updateDebuggerToolBarMenu();
}

/*!
 * \brief DebuggerConfigurationsDialog::removeConfiguration
 * Removes the debugger configuration.
 */
void DebuggerConfigurationsDialog::removeConfiguration()
{
  QListWidgetItem *pListWidgetItem = mpConfigurationsListWidget->currentItem();
  if (!pListWidgetItem) {
    return;
  }

  QSettings *pSettings = Utilities::getApplicationSettings();
  QList<QVariant> debugConfigurations = pSettings->value("debuggerConfigurationList/configurations").toList();
  foreach (QVariant configuration, debugConfigurations) {
    DebuggerConfiguration debugConfiguration = qvariant_cast<DebuggerConfiguration>(configuration);
    if (debugConfiguration.name.compare(pListWidgetItem->text()) == 0) {
      // ask user if he is sure about removing the configuration
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::question));
      pMessageBox->setIcon(QMessageBox::Question);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::DELETE_DEBUG_CONFIGURATION_MSG).arg(debugConfiguration.name));
      pMessageBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
      pMessageBox->setDefaultButton(QMessageBox::Yes);
      int answer = pMessageBox->exec();
      switch (answer) {
        case QMessageBox::Yes: // Yes was clicked. Don't return.
          break;
        case QMessageBox::No: // No was clicked. Return
        default:
          return;
      }
      debugConfigurations.removeOne(debugConfiguration);
      pSettings->setValue("debuggerConfigurationList/configurations", debugConfigurations);
      // update the debug configuration toolbar menu
      MainWindow::instance()->updateDebuggerToolBarMenu();

      bool state = mpConfigurationsListWidget->blockSignals(true);
      QWidget *pWidget = mpConfigurationPagesWidget->widget(mpConfigurationsListWidget->currentRow());
      mpConfigurationPagesWidget->removeWidget(pWidget);
      delete pWidget;
      delete mpConfigurationsListWidget->item(mpConfigurationsListWidget->currentRow());
      mpConfigurationsListWidget->blockSignals(state);
      if (mpConfigurationsListWidget->count() <= 0) {
        mpConfigurationsSplitter->setVisible(false);
        mpConfigurationsButtonBox->setVisible(false);
      }
      break;
    }
  }
}

/*!
 * \brief DebuggerConfigurationsDialog::changeConfigurationPage
 * Change the page in DebuggerConfigurationsDialogt when the mpConfigurationsListWidget currentItemChanged Signal is raised.
 * \param current
 * \param previous
 */
void DebuggerConfigurationsDialog::changeConfigurationPage(QListWidgetItem *current, QListWidgetItem *previous)
{
  if (!current) {
    current = previous;
  }
  mpConfigurationPagesWidget->setCurrentIndex(mpConfigurationsListWidget->row(current));
}

/*!
 * \brief DebuggerConfigurationsDialog::saveAllConfigurations
 * Saves all the debug configurations to the settings file.
 */
void DebuggerConfigurationsDialog::saveAllConfigurations()
{
  if (saveAllConfigurationsHelper()) {
    accept();
  }
}

/*!
 * \brief DebuggerConfigurationsDialog::saveAllConfigurationsAndDebugConfiguration
 * Saves all the debug configurations to the settings file.
 * Starts the Algorithmic debugger for the active configuration.
 */
void DebuggerConfigurationsDialog::saveAllConfigurationsAndDebugConfiguration()
{
  if (saveAllConfigurationsHelper()) {
    accept();
    // start the debugger
    DebuggerConfigurationPage *pDebuggerConfigurationPage = qobject_cast<DebuggerConfigurationPage*>(mpConfigurationPagesWidget->currentWidget());
    if (pDebuggerConfigurationPage) {
      runConfiguration(pDebuggerConfigurationPage);
    }
  }
}
