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

#include <QtSvg/QSvgGenerator>

#include "MainWindow.h"
#include "Helper.h"

MainWindow::MainWindow(QSplashScreen *pSplashScreen, QWidget *parent)
  : QMainWindow(parent), mExitApplicationStatus(false), mDebugApplication(false)
{
  // This is a very convoluted way of asking for the default system font in Qt
  QFont systmFont("Monospace");
  systmFont.setStyleHint(QFont::System);
  Helper::systemFontInfo = QFontInfo(systmFont);
  // This is a very convoluted way of asking for the default monospace font in Qt
  QFont monospaceFont("Monospace");
  monospaceFont.setStyleHint(QFont::TypeWriter);
  Helper::monospacedFontInfo = QFontInfo(monospaceFont);
  // Create the OMCProxy object.
  pSplashScreen->showMessage(tr("Connecting to OpenModelica Compiler"), Qt::AlignRight, Qt::white);
  mpOMCProxy = new OMCProxy(this);
  if (getExitApplicationStatus())
    return;
  pSplashScreen->showMessage(tr("Reading Settings"), Qt::AlignRight, Qt::white);
  mpOptionsDialog = new OptionsDialog(this);
  //Set the name and size of the main window
  pSplashScreen->showMessage(tr("Loading Widgets"), Qt::AlignRight, Qt::white);
  setObjectName("MainWindow");
  setWindowTitle(Helper::applicationName + " - "  + Helper::applicationIntroText);
  setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  setMinimumSize(400, 300);
  resize(800, 600);
  setContentsMargins(1, 1, 1, 1);
  // Create an object of MessagesWidget.
  mpMessagesWidget = new MessagesWidget(this);
  // Create MessagesDockWidget dock
  mpMessagesDockWidget = new QDockWidget(tr("Messages Browser"), this);
  mpMessagesDockWidget->setObjectName("Messages");
  mpMessagesDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea | Qt::BottomDockWidgetArea);
  mpMessagesDockWidget->setWidget(mpMessagesWidget);
  addDockWidget(Qt::BottomDockWidgetArea, mpMessagesDockWidget);
  mpMessagesDockWidget->hide();
  connect(mpMessagesWidget, SIGNAL(MessageAdded()), mpMessagesDockWidget, SLOT(show()));
  // Create an object of SearchClassWidget
  mpSearchClassWidget = new SearchClassWidget(this);
  // Create LibraryTreeWidget dock
  mpSearchClassDockWidget = new QDockWidget(tr("Search Browser"), this);
  mpSearchClassDockWidget->setObjectName("SearchClassWidget");
  mpSearchClassDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpSearchClassDockWidget->setWidget(mpSearchClassWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpSearchClassDockWidget);
  setCorner(Qt::TopLeftCorner, Qt::LeftDockWidgetArea);
  connect(mpSearchClassDockWidget, SIGNAL(visibilityChanged(bool)), SLOT(focusSearchClassWidget(bool)));
  mpSearchClassDockWidget->hide();
  // Create an object of LibraryTreeWidget
  mpLibraryTreeWidget = new LibraryTreeWidget(false, this);
  // Loads and adds the OM Standard Library into the Library Widget.
  mpLibraryTreeWidget->addModelicaLibraries(pSplashScreen);
  // Create LibraryTreeWidget dock
  mpLibraryTreeDockWidget = new QDockWidget(tr("Libraries Browser"), this);
  mpLibraryTreeDockWidget->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
  mpLibraryTreeDockWidget->setObjectName("Libraries");
  mpLibraryTreeDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpLibraryTreeDockWidget->setWidget(mpLibraryTreeWidget);
  addDockWidget(Qt::LeftDockWidgetArea, mpLibraryTreeDockWidget);
  setCorner(Qt::BottomLeftCorner, Qt::LeftDockWidgetArea);
  // create an object of DocumentationWidget
  mpDocumentationWidget = new DocumentationWidget(this);
  // Create DocumentationWidget dock
  mpDocumentationDockWidget = new QDockWidget(tr("Documentation Browser"), this);
  mpDocumentationDockWidget->setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
  mpDocumentationDockWidget->setObjectName("Documentation");
  mpDocumentationDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  mpDocumentationDockWidget->setWidget(mpDocumentationWidget);
  addDockWidget(Qt::RightDockWidgetArea, mpDocumentationDockWidget);
  setCorner(Qt::TopRightCorner, Qt::RightDockWidgetArea);
  mpDocumentationDockWidget->hide();
  // Create VariablesWidget dock
  mpVariablesDockWidget = new QDockWidget(tr("Variables Browser"), this);
  mpVariablesDockWidget->setObjectName("Variables");
  mpVariablesDockWidget->setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);
  addDockWidget(Qt::RightDockWidgetArea, mpVariablesDockWidget);
  setCorner(Qt::TopRightCorner, Qt::RightDockWidgetArea);
  mpVariablesDockWidget->hide();
  //Create Actions, Toolbar and Menus
  pSplashScreen->showMessage(tr("Creating Widgets"), Qt::AlignRight, Qt::white);
  setAcceptDrops(true);
  createActions();
  createToolbars();
  createMenus();
  // Create find/replace dialog
  mpFindReplaceDialog = new FindReplaceDialog(this);
  // Create simulation dialog
  mpSimulationDialog = new SimulationDialog(this);
  // Create an object of PlotWindowContainer
  mpPlotWindowContainer = new PlotWindowContainer(this);
  // create an object of VariablesWidget
  mpVariablesWidget = new VariablesWidget(this);
  mpVariablesDockWidget->setWidget(mpVariablesWidget);
  // Create an object of InteractiveSimulationTabWidget
  //mpInteractiveSimualtionTabWidget = new InteractiveSimulationTabWidget(this);
  // Create an object of ModelWidgetContainer
  mpModelWidgetContainer = new ModelWidgetContainer(this);
  /*! @note register the RecentFile and FindText struct in the Qt's meta system
   * Don't remove/move the following line.
   * Because RecentFile struct should be registered before reading the recentFilesList section from the settings file.
   */
  qRegisterMetaTypeStreamOperators<RecentFile>("RecentFile");
  qRegisterMetaTypeStreamOperators<FindText>("FindText");
    // Create an object of WelcomePageWidget
  mpWelcomePageWidget = new WelcomePageWidget(this);
  updateRecentFileActions();
  // create the OMEdit About widget
  mpAboutOMEditDialog = new AboutOMEditWidget(this);
  mpAboutOMEditDialog->hide();
  // craete an instance of InfoBar
  mpInfoBar = new InfoBar(this);
  mpInfoBar->hide();
  //Create a centralwidget for the main window
  QWidget *pCentralwidget = new QWidget;
  // set the layout
  QGridLayout *pCentralgrid = new QGridLayout;
  pCentralgrid->setVerticalSpacing(4);
  pCentralgrid->setContentsMargins(0, 1, 0, 0);
  pCentralgrid->addWidget(mpInfoBar, 0, 0);
  pCentralgrid->addWidget(mpWelcomePageWidget, 1, 0);
  pCentralgrid->addWidget(mpModelWidgetContainer, 1, 0);
  pCentralgrid->addWidget(mpPlotWindowContainer, 1, 0);
  //pCentralgrid->addWidget(mpInteractiveSimualtionTabWidget, 1, 0);
  pCentralwidget->setLayout(pCentralgrid);
  //Set the centralwidget
  setCentralWidget(pCentralwidget);
  // Create an object of QStatusBar
  mpStatusBar = new QStatusBar();
  mpStatusBar->setObjectName("statusBar");
  mpStatusBar->setContentsMargins(0, 0, 0, 0);
  // Create an object of QProgressBar
  mpProgressBar = new QProgressBar;
  mpProgressBar->setMaximumWidth(300);
  mpProgressBar->setTextVisible(false);
  mpProgressBar->setVisible(false);
  // pointer position Label
  mpPointerXPositionLabel = new Label;
  mpPointerXPositionLabel->setMinimumWidth(60);
  mpPointerYPositionLabel = new Label;
  mpPointerYPositionLabel->setMinimumWidth(60);
  // add progressbar to statusbar
  mpStatusBar->addPermanentWidget(mpProgressBar);
  mpStatusBar->addPermanentWidget(mpPointerXPositionLabel);
  mpStatusBar->addPermanentWidget(mpPointerYPositionLabel);
  mpPerspectiveTabbar = new QTabBar;
  mpPerspectiveTabbar->setDocumentMode(true);
  mpPerspectiveTabbar->setShape(QTabBar::RoundedSouth);
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/omedit.png"), tr("Welcome"));
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/modeling.png"), tr("Modeling"));
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/omplot.png"), tr("Plotting"));
  mpPerspectiveTabbar->addTab(QIcon(":/Resources/icons/interactive-simulation.png"), tr("Interactive Simulation"));
  mpPerspectiveTabbar->setTabEnabled(3, false);
  connect(mpPerspectiveTabbar, SIGNAL(currentChanged(int)), SLOT(perspectiveTabChanged(int)));
  mpStatusBar->addPermanentWidget(mpPerspectiveTabbar);
  // set status bar for MainWindow
  setStatusBar(mpStatusBar);
  QMetaObject::connectSlotsByName(this);
  // set the matching algorithm and index reduction methods.
  mpOMCProxy->setMatchingAlgorithm(mpOptionsDialog->getSimulationPage()->getMatchingAlgorithmComboBox()->currentText());
  mpOMCProxy->setIndexReductionMethod(mpOptionsDialog->getSimulationPage()->getIndexReductionMethodComboBox()->currentText());
  // restore OMEdit widgets state
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  if (mpOptionsDialog->getGeneralSettingsPage()->getPreserveUserCustomizations())
  {
    restoreGeometry(settings.value("application/geometry").toByteArray());
    bool restoreMessagesWidget = false;
    if (mpMessagesWidget->getMessagesTreeWidget()->topLevelItemCount() > 0) restoreMessagesWidget = true;
    restoreState(settings.value("application/windowState").toByteArray());
    if (restoreMessagesWidget) mpMessagesDockWidget->show();
    mpPerspectiveTabbar->setCurrentIndex(0);
  }
  // read last Open Directory location
  if (settings.contains("lastOpenDirectory"))
    StringHandler::setLastOpenDirectory(settings.value("lastOpenDirectory").toString());
}

//! Returns the instance of OMCProxy.
//! @return Instance of OMCProxy.
OMCProxy* MainWindow::getOMCProxy()
{
  return mpOMCProxy;
}

//! sets the value of ExitApplicationStatus variable.
void MainWindow::setExitApplicationStatus(bool status)
{
  mExitApplicationStatus = status;
}

//! Returns the value of ExitApplicationStatus variable.
bool MainWindow::getExitApplicationStatus()
{
  return mExitApplicationStatus;
}

void MainWindow::setDebugApplication(bool debug)
{
  mDebugApplication = debug;
}

bool MainWindow::getDebugApplication()
{
  return mDebugApplication;
}

OptionsDialog* MainWindow::getOptionsDialog()
{
  return mpOptionsDialog;
}

MessagesWidget* MainWindow::getMessagesWidget()
{
  return mpMessagesWidget;
}

LibraryTreeWidget* MainWindow::getLibraryTreeWidget()
{
  return mpLibraryTreeWidget;
}

DocumentationWidget* MainWindow::getDocumentationWidget()
{
  return mpDocumentationWidget;
}

QDockWidget* MainWindow::getDocumentationDockWidget()
{
  return mpDocumentationDockWidget;
}

VariablesWidget* MainWindow::getVariablesWidget()
{
  return mpVariablesWidget;
}

QDockWidget* MainWindow::getVariablesDockWidget()
{
  return mpVariablesDockWidget;
}

PlotWindowContainer* MainWindow::getPlotWindowContainer()
{
  return mpPlotWindowContainer;
}

//InteractiveSimulationTabWidget* MainWindow::getInteractiveSimulationTabWidget()
//{
//  return mpInteractiveSimualtionTabWidget;
//}

ModelWidgetContainer* MainWindow::getModelWidgetContainer()
{
  return mpModelWidgetContainer;
}

InfoBar* MainWindow::getInfoBar()
{
  return mpInfoBar;
}

QStatusBar* MainWindow::getStatusBar()
{
  return mpStatusBar;
}

QProgressBar* MainWindow::getProgressBar()
{
  return mpProgressBar;
}

Label* MainWindow::getPointerXPositionLabel()
{
  return mpPointerXPositionLabel;
}

Label* MainWindow::getPointerYPositionLabel()
{
  return mpPointerYPositionLabel;
}

QTabBar* MainWindow::getPerspectiveTabBar()
{
  return mpPerspectiveTabbar;
}

QAction* MainWindow::getSaveAction()
{
  return mpSaveAction;
}

QAction* MainWindow::getSaveAsAction()
{
  return mpSaveAsAction;
}

QAction* MainWindow::getPrintModelAction()
{
  return mpPrintModelAction;
}

QAction* MainWindow::getSaveAllAction()
{
  return mpSaveAllAction;
}

QAction* MainWindow::getShowGridLinesAction()
{
  return mpShowGridLinesAction;
}

QAction* MainWindow::getResetZoomAction()
{
  return mpResetZoomAction;
}

QAction* MainWindow::getZoomInAction()
{
  return mpZoomInAction;
}

QAction* MainWindow::getZoomOutAction()
{
  return mpZoomOutAction;
}

QAction* MainWindow::getSimulationAction()
{
  return mpSimulationAction;
}

QAction* MainWindow::getInstantiateModelAction()
{
  return mpInstantiateModelAction;
}

QAction* MainWindow::getCheckModelAction()
{
  return mpCheckModelAction;
}

QAction* MainWindow::getExportFMUAction()
{
  return mpExportFMUAction;
}

QAction* MainWindow::getExportXMLAction()
{
  return mpExportXMLAction;
}

QAction* MainWindow::getLineShapeAction()
{
  return mpLineShapeAction;
}

QAction* MainWindow::getPolygonShapeAction()
{
  return mpPolygonShapeAction;
}

QAction* MainWindow::getRectangleShapeAction()
{
  return mpRectangleShapeAction;
}

QAction* MainWindow::getEllipseShapeAction()
{
  return mpEllipseShapeAction;
}

QAction* MainWindow::getTextShapeAction()
{
  return mpTextShapeAction;
}

QAction* MainWindow::getBitmapShapeAction()
{
  return mpBitmapShapeAction;
}

QAction* MainWindow::getExportAsImageAction()
{
  return mpExportAsImageAction;
}

QAction* MainWindow::getExportToOMNotebookAction()
{
  return mpExportToOMNotebookAction;
}

QAction* MainWindow::getImportFromOMNotebookAction()
{
  return mpImportFromOMNotebookAction;
}

QAction* MainWindow::getConnectModeAction()
{
  return mpConnectModeAction;
}

QAction* MainWindow::getFindReplaceAction()
{
  return mpFindReplaceAction;
}

QAction* MainWindow::getClearFindReplaceTextsAction()
{
  return mpClearFindReplaceTextsAction;
}

QAction* MainWindow::getGotoLineNumberAction()
{
  return mpGotoLineNumberAction;
}

//! Adds the currently opened file to the recentFilesList settings.
void MainWindow::addRecentFile(const QString &fileName, const QString &encoding)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  QList<QVariant> files = settings.value("recentFilesList/files").toList();
  // remove the already present RecentFile instance from the list.
  foreach (QVariant file, files)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(file);
    QFileInfo file1(recentFile.fileName);
    QFileInfo file2(fileName);
    if (file1.absoluteFilePath().compare(file2.absoluteFilePath()) == 0)
      files.removeOne(file);
  }
  RecentFile recentFile;
  recentFile.fileName = fileName;
  recentFile.encoding = encoding;
  files.prepend(QVariant::fromValue(recentFile));
  while (files.size() > MaxRecentFiles)
    files.removeLast();
  settings.setValue("recentFilesList/files", files);
  updateRecentFileActions();
}

//! Updates the actions of the recent files menu items.
void MainWindow::updateRecentFileActions()
{
  /* first set all recent files actions visibility to false. */
  for (int i = 0; i < MaxRecentFiles; ++i)
    mpRecentFileActions[i]->setVisible(false);
  /* read the new recent files list */
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  QList<QVariant> files = settings.value("recentFilesList/files").toList();
  int numRecentFiles = qMin(files.size(), (int)MaxRecentFiles);
  for (int i = 0; i < numRecentFiles; ++i)
  {
    RecentFile recentFile = qvariant_cast<RecentFile>(files[i]);
    mpRecentFileActions[i]->setText(recentFile.fileName);
    QStringList dataList;
    dataList << recentFile.fileName << recentFile.encoding;
    mpRecentFileActions[i]->setData(dataList);
    mpRecentFileActions[i]->setVisible(true);
  }
  mpWelcomePageWidget->addRecentFilesListItems();
}

//! Event triggered re-implemented method that closes the main window.
//! First all tabs (models) are closed, if the user do not push Cancel
//! (closeAllProjectTabs then returns 'false') the event is accepted and
//! the main window is closed.
//! @param event contains information of the closing operation.
void MainWindow::closeEvent(QCloseEvent *event)
{
  SaveChangesDialog *pSaveChangesDialog = new SaveChangesDialog(this);
  if (pSaveChangesDialog->exec())
  {
    if (askForExit())
    {
      beforeClosingMainWindow();
      event->accept();
    }
    else
    {
      event->ignore();
    }
  }
  else
  {
    event->ignore();
  }
}

int MainWindow::askForExit()
{
  if (!mpOptionsDialog->getNotificationsPage()->getQuitApplicationCheckBox()->isChecked())
  {
    NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::QuitApplication,
                                                                        NotificationsDialog::QuestionIcon, this);
    return pNotificationsDialog->exec();
  }
  return true;
}

void MainWindow::beforeClosingMainWindow()
{
  mpOMCProxy->stopServer();
  // save OMEdit widgets state
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.setValue("application/geometry", saveGeometry());
  settings.setValue("application/windowState", saveState());
  // save last Open Directory location
  settings.setValue("lastOpenDirectory", StringHandler::getLastOpenDirectory());
}

void MainWindow::openDroppedFile(QDropEvent *event)
{
  int progressValue = 0;
  mpProgressBar->setRange(0, event->mimeData()->urls().size());
  showProgressBar();
  //retrieves the filenames of all the dragged files in list and opens the valid files.
  foreach (QUrl fileUrl, event->mimeData()->urls())
  {
    QFileInfo fileInfo(fileUrl.toLocalFile());
    // show file loading message
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(fileInfo.absoluteFilePath()));
    mpProgressBar->setValue(++progressValue);
    // check the file extension
    QRegExp resultFilesRegExp("\\b(mat|plt|csv)\\b");
    if (fileInfo.suffix().compare("mo", Qt::CaseInsensitive) == 0)
    {
      mpLibraryTreeWidget->openFile(fileInfo.absoluteFilePath(), Helper::utf8, false);
    }
    else if (resultFilesRegExp.indexIn(fileInfo.suffix()) != -1)
    {
      openResultFiles(QStringList(fileInfo.absoluteFilePath()));
    }
    else
    {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::FILE_FORMAT_NOT_SUPPORTED).arg(fileInfo.fileName())
                           .arg(Helper::omFileTypes));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

void MainWindow::openResultFiles(QStringList fileNames)
{
  QString currentDirectory = mpOMCProxy->changeDirectory();
  foreach (QString fileName, fileNames)
  {
    QFileInfo fileInfo(fileName);
    mpOMCProxy->changeDirectory(fileInfo.absoluteDir().absolutePath());
    QList<QString> list = mpOMCProxy->readSimulationResultVars(fileInfo.fileName());
    // close the simulation result file.
    mpOMCProxy->closeSimulationResultFile();
    mpPerspectiveTabbar->setCurrentIndex(2);
    mpVariablesWidget->addPlotVariablestoTree(fileInfo.fileName(), fileInfo.absoluteDir().absolutePath(), list);
    mpVariablesDockWidget->show();
  }
  mpOMCProxy->changeDirectory(currentDirectory);
}

void MainWindow::simulate(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  mpSimulationDialog->show(pLibraryTreeNode, false);
}

void MainWindow::instantiatesModel(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  // set the status message.
  mpStatusBar->showMessage(QString(Helper::instantiateModel).append(" ").append(pLibraryTreeNode->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString instantiateModelResult = mpOMCProxy->instantiateModel(pLibraryTreeNode->getNameStructure());
  if (instantiateModelResult.length())
  {
    QString windowTitle = QString(Helper::instantiateModel).append(" - ").append(pLibraryTreeNode->getName());
    InformationDialog *pInformationDialog = new InformationDialog(windowTitle, instantiateModelResult, true, this);
    pInformationDialog->show();
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                         "Instantiation of " + pLibraryTreeNode->getName() + " failed.",
                                                         Helper::scriptingKind, Helper::notificationLevel, 0,
                                                         mpMessagesWidget->getMessagesTreeWidget()));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::checkModel(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  // set the status message.
  mpStatusBar->showMessage(QString(Helper::checkModel).append(" ").append(pLibraryTreeNode->getNameStructure()));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  QString checkModelResult = mpOMCProxy->checkModel(pLibraryTreeNode->getNameStructure());
  if (checkModelResult.length())
  {
    QString windowTitle = QString(Helper::checkModel).append(" - ").append(pLibraryTreeNode->getName());
    InformationDialog *pInformationDialog = new InformationDialog(windowTitle, checkModelResult, false, this);
    pInformationDialog->show();
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0,
                                                         "Check of " + pLibraryTreeNode->getName() + " failed.",
                                                         Helper::scriptingKind, Helper::notificationLevel, 0,
                                                         mpMessagesWidget->getMessagesTreeWidget()));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelFMU(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model as FMU"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  if (mpOMCProxy->translateModelFMU(pLibraryTreeNode->getNameStructure()))
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::FMU_GENERATED)
                                                         .arg(mpOMCProxy->changeDirectory()).arg(pLibraryTreeNode->getNameStructure()),
                                                         Helper::scriptingKind, Helper::notificationLevel, 0,
                                                         mpMessagesWidget->getMessagesTreeWidget()));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelXML(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model as XML"));
  // show the progress bar
  mpProgressBar->setRange(0, 0);
  showProgressBar();
  if (mpOMCProxy->translateModelXML(pLibraryTreeNode->getNameStructure()))
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::XML_GENERATED)
                                                         .arg(mpOMCProxy->changeDirectory()).arg(pLibraryTreeNode->getNameStructure()),
                                                         Helper::scriptingKind, Helper::notificationLevel, 0,
                                                         mpMessagesWidget->getMessagesTreeWidget()));
  }
  // hide progress bar
  hideProgressBar();
  // clear the status bar message
  mpStatusBar->clearMessage();
}

void MainWindow::exportModelToOMNotebook(LibraryTreeNode *pLibraryTreeNode)
{
  /* if Modelica text is changed manually by user then validate it before saving. */
  if (pLibraryTreeNode->getModelWidget())
  {
    if (!pLibraryTreeNode->getModelWidget()->getModelicaTextWidget()->getModelicaTextEdit()->validateModelicaText())
      return;
  }
  QString omnotebookFileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::exportToOMNotebook),
                                                              NULL, Helper::omnotebookFileTypes, NULL, "onb", &pLibraryTreeNode->getName());
  // if user cancels the operation. or closes the export dialog box.
  if (omnotebookFileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 6;    // since in total we do six things while exporting to OMNotebook
  int value = 1;
  // set the status message.
  mpStatusBar->showMessage(tr("Exporting model to OMNotebook"));
  // show the progress bar
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  // create the xml for the omnotebook file.
  QDomDocument xmlDocument;
  // create Notebook element
  QDomElement notebookElement = xmlDocument.createElement("Notebook");
  xmlDocument.appendChild(notebookElement);
  mpProgressBar->setValue(value++);
  // create title cell
  createOMNotebookTitleCell(pLibraryTreeNode, xmlDocument, notebookElement);
  mpProgressBar->setValue(value++);
  // create image cell
  QStringList pathList = omnotebookFileName.split('/');
  pathList.removeLast();
  QString modelImagePath(pathList.join("/"));
  createOMNotebookImageCell(pLibraryTreeNode, xmlDocument, notebookElement, modelImagePath);
  mpProgressBar->setValue(value++);
  // create a code cell
  createOMNotebookCodeCell(pLibraryTreeNode, xmlDocument, notebookElement);
  mpProgressBar->setValue(value++);
  // create a file object and write the xml in it.
  QFile omnotebookFile(omnotebookFileName);
  omnotebookFile.open(QIODevice::WriteOnly);
  QTextStream textStream(&omnotebookFile);
  textStream << xmlDocument.toString();
  omnotebookFile.close();
  mpProgressBar->setValue(value++);
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

//! creates a title cell in omnotebook xml file
void MainWindow::createOMNotebookTitleCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement)
{
  QDomElement textCellElement = xmlDocument.createElement("TextCell");
  textCellElement.setAttribute("style", "Text");
  domElement.appendChild(textCellElement);
  // create text Element
  QDomElement textElement = xmlDocument.createElement("Text");
  textElement.appendChild(xmlDocument.createTextNode("<html><head><meta name=\"qrichtext\" content=\"1\" /><head><body style=\"white-space: pre-wrap; font-family:MS Shell Dlg; font-size:8.25pt; font-weight:400; font-style:normal; text-decoration:none;\"><p style=\"margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px; font-family:Arial; font-size:38pt; font-weight:600; color:#000000;\">" + pLibraryTreeNode->getName() + "</p></body></html>"));
  textCellElement.appendChild(textElement);
}

//! creates a image cell in omnotebook xml file
void MainWindow::createOMNotebookImageCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement,
                                           QString filePath)
{
  GraphicsView *pGraphicsView = pLibraryTreeNode->getModelWidget()->getDiagramGraphicsView();
  QPixmap modelImage(pGraphicsView->viewport()->size());
  modelImage.fill(QColor(Qt::transparent));
  QPainter painter(&modelImage);
  painter.setWindow(pGraphicsView->viewport()->rect());
  // paint the background color first
  painter.fillRect(modelImage.rect(), pGraphicsView->palette().background());
  // paint all the items
  pGraphicsView->render(&painter, QRectF(painter.viewport()), pGraphicsView->viewport()->rect());
  painter.end();
  // create textcell element
  QDomElement textCellElement = xmlDocument.createElement("TextCell");
  domElement.appendChild(textCellElement);
  // create text Element
  QDomElement textElement = xmlDocument.createElement("Text");
  textElement.appendChild(xmlDocument.createTextNode("<img src=\""+QString(filePath).append("/OMNotebook_tempfiles/1.png")+"\" />"));
  textCellElement.appendChild(textElement);
  // create rule Element
  QDomElement ruleElement = xmlDocument.createElement("Rule");
  ruleElement.setAttribute("name", "TextAlignment");
  ruleElement.appendChild(xmlDocument.createTextNode("Center"));
  textCellElement.appendChild(ruleElement);
  // create image Element
  QDomElement imageElement = xmlDocument.createElement("Image");
  imageElement.setAttribute("name", QString(filePath).append("/OMNotebook_tempfiles/1.png"));
  // get the base64 encoding of image
  QBuffer imageBuffer;
  imageBuffer.open(QBuffer::WriteOnly);
  QDataStream out(&imageBuffer);
  out << modelImage;
  imageBuffer.close();
  imageElement.appendChild(xmlDocument.createTextNode(imageBuffer.buffer().toBase64()));
  textCellElement.appendChild(imageElement);
}

//! creates a code cell in omnotebook xml file
void MainWindow::createOMNotebookCodeCell(LibraryTreeNode *pLibraryTreeNode, QDomDocument xmlDocument, QDomElement domElement)
{
  QDomElement textCellElement = xmlDocument.createElement("InputCell");
  domElement.appendChild(textCellElement);
  // create input Element
  QDomElement inputElement = xmlDocument.createElement("Input");
  inputElement.appendChild(xmlDocument.createTextNode(mpOMCProxy->list(pLibraryTreeNode->getNameStructure())));
  textCellElement.appendChild(inputElement);
  // create output Element
  QDomElement outputElement = xmlDocument.createElement("Output");
  outputElement.appendChild(xmlDocument.createTextNode(""));
  textCellElement.appendChild(outputElement);
}

//! Opens the new model widget.
void MainWindow::createNewModelicaClass()
{
  ModelicaClassDialog *pModelicaClassDialog = new ModelicaClassDialog(this);
  pModelicaClassDialog->show();
}

void MainWindow::openModelicaFile()
{
  QStringList fileNames;
  fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                              NULL, Helper::omFileTypes, NULL);
  if (fileNames.isEmpty())
    return;
  int progressValue = 0;
  mpProgressBar->setRange(0, fileNames.size());
  showProgressBar();
  foreach (QString file, fileNames)
  {
    file = file.replace("\\", "/");
    mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(file));
    mpProgressBar->setValue(++progressValue);
    // if file doesn't exists
    if (!QFile::exists(file))
    {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(file)));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(file)));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    }
    else
    {
      mpLibraryTreeWidget->openFile(file, Helper::utf8, false);
    }
  }
  mpStatusBar->clearMessage();
  hideProgressBar();
}

void MainWindow::showOpenModelicaFileDialog()
{
  OpenModelicaFile *pOpenModelicaFile = new OpenModelicaFile(this);
  pOpenModelicaFile->show();
}

void MainWindow::showOpenResultFileDialog()
{
  QStringList fileNames = StringHandler::getOpenFileNames(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFiles),
                                                          NULL, Helper::omResultFileTypes, NULL);
  if (fileNames.isEmpty())
    return;
  openResultFiles(fileNames);
}

void MainWindow::loadSystemLibrary()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction)
  {
    /* check if library is already loaded. */
    if (mpOMCProxy->existClass(pAction->text()))
    {
      QMessageBox *pMessageBox = new QMessageBox(this);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
      pMessageBox->setIcon(QMessageBox::Information);
      pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(pAction->text())));
      pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                      .arg(pAction->text()).append("\n")
                                      .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(pAction->text())));
      pMessageBox->setStandardButtons(QMessageBox::Ok);
      pMessageBox->exec();
    }
    /* if library is not loaded then load it. */
    else
    {
      if (mpOMCProxy->loadModel(pAction->text()))
      {
        // create library tree nodes
        mpProgressBar->setRange(0, 0);
        showProgressBar();
        LibraryTreeNode *pLibraryTreeNode = mpLibraryTreeWidget->addLibraryTreeNode(pAction->text(),
                                                                                    mpOMCProxy->getClassRestriction(pAction->text()), "");
        pLibraryTreeNode->setSystemLibrary(true);
        mpStatusBar->showMessage(QString(Helper::loading).append(": ").append(pAction->text()));
        mpLibraryTreeWidget->createLibraryTreeNodes(pLibraryTreeNode);
        mpStatusBar->clearMessage();
        hideProgressBar();
      }
    }
  }
}

void MainWindow::focusSearchClassWidget(bool visible)
{
  if (visible)
    mpSearchClassWidget->getSearchClassTextBox()->setFocus();
}

void MainWindow::showFindReplaceDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    mpFindReplaceDialog->readFindTextFromSettings();
    mpFindReplaceDialog->setTextEdit(pModelWidget->getModelicaTextWidget()->getModelicaTextEdit());
    mpFindReplaceDialog->show();
    mpFindReplaceDialog->raise();
    mpFindReplaceDialog->activateWindow();
  }
}

void MainWindow::showGotoLineNumberDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    GotoLineDialog *pGotoLineWidget = new GotoLineDialog(pModelWidget->getModelicaTextWidget()->getModelicaTextEdit(), this);
    pGotoLineWidget->show();
  }
}

//! Opens the recent file.
void MainWindow::openRecentFile()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  if (pAction)
  {
    QStringList dataList = pAction->data().toStringList();
    mpLibraryTreeWidget->openFile(dataList.at(0), dataList.at(1), true, true);
  }
}

void MainWindow::clearRecentFilesList()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.remove("recentFilesList/files");
  updateRecentFileActions();
  mpWelcomePageWidget->addRecentFilesListItems();
}

void MainWindow::clearFindReplaceTexts()
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.remove("findReplaceDialog/textsToFind");
  mpFindReplaceDialog->readFindTextFromSettings();
}

void MainWindow::setShowGridLines(bool showLines)
{
  mpModelWidgetContainer->setShowGridLines(showLines);
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    if (pModelWidget->getDiagramGraphicsView()->isVisible())
      pModelWidget->getDiagramGraphicsView()->scene()->update();
    else if (pModelWidget->getIconGraphicsView()->isVisible())
      pModelWidget->getIconGraphicsView()->scene()->update();
  }
}

//! Tells the current model to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void MainWindow::resetZoom()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    if (pModelWidget->getDiagramGraphicsView()->isVisible())
      pModelWidget->getDiagramGraphicsView()->resetZoom();
    else if (pModelWidget->getIconGraphicsView()->isVisible())
      pModelWidget->getIconGraphicsView()->resetZoom();
  }
}

//! Tells the current model to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void MainWindow::zoomIn()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    if (pModelWidget->getDiagramGraphicsView()->isVisible())
      pModelWidget->getDiagramGraphicsView()->zoomIn();
    else if (pModelWidget->getIconGraphicsView()->isVisible())
      pModelWidget->getIconGraphicsView()->zoomIn();
  }
}

//! Tells the current model to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void MainWindow::zoomOut()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    if (pModelWidget->getDiagramGraphicsView()->isVisible())
      pModelWidget->getDiagramGraphicsView()->zoomOut();
    else if (pModelWidget->getIconGraphicsView()->isVisible())
      pModelWidget->getIconGraphicsView()->zoomOut();
  }
}

void MainWindow::instantiatesModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      instantiatesModel(pLibraryTreeNode);
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("instantiating")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

void MainWindow::checkModel()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      checkModel(pLibraryTreeNode);
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("checking")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

//! Open Simulation Window
void MainWindow::openSimulationDialog()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      simulate(pLibraryTreeNode);
  }
}

//! Open Interactive Simulation Window
void MainWindow::openInteractiveSimulation()
{
  //mpSimulationDialog->show(true);
}

//! Exports the current model to FMU
void MainWindow::exportModelFMU()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      exportModelFMU(pLibraryTreeNode);
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("making FMU")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

//! Exports the current model to XML
void MainWindow::exportModelXML()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      exportModelXML(pLibraryTreeNode);
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("making XML")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

//! Imports the model from FMU
void MainWindow::importModelFMU()
{
  ImportFMUDialog *pImportFMUDialog = new ImportFMUDialog(this);
  pImportFMUDialog->show();
}

//! Exports the current model to OMNotebook.
//! Creates a new onb file and add the model text and model image in it.
//! @see importModelfromOMNotebook();
void MainWindow::exportModelToOMNotebook()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
      exportModelToOMNotebook(pLibraryTreeNode);
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("exporting to OMNotebook")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

//! Imports the models from OMNotebook.
//! @see exportModelToOMNotebook();
void MainWindow::importModelfromOMNotebook()
{
  QString fileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::importFromOMNotebook),
                                                    NULL, Helper::omnotebookFileTypes);
  if (fileName.isEmpty())
    return;
  // create a progress bar
  int endtime = 3;    // since in total we do three things while importing from OMNotebook
  int value = 1;
  // show the progressbar and set the message in status bar
  mpStatusBar->showMessage(tr("Importing model(s) from OMNotebook"));
  mpProgressBar->setRange(0, endtime);
  showProgressBar();
  // open the xml file
  QFile file(fileName);
  if (!file.open(QIODevice::ReadOnly))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          tr("Error opening the file"), Helper::ok);
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);
  // create the xml from the omnotebook file.
  QDomDocument xmlDocument;
  if (!xmlDocument.setContent(&file))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          tr("Error reading the xml file"), Helper::ok);
    hideProgressBar();
    return;
  }
  mpProgressBar->setValue(value++);
  // read the file
  QDomNodeList nodes = xmlDocument.elementsByTagName("Input");
  endtime = endtime + nodes.size();
  mpProgressBar->setMaximum(endtime);
  for (int i = 0; i < nodes.size(); i++)
  {
    if (nodes.at(i).toElement().text().toLower().startsWith("model"))
    {
      mpLibraryTreeWidget->parseAndLoadModelicaText(nodes.at(i).toElement().text());
    }
    mpProgressBar->setValue(value++);
  }
  file.close();
  // hide the progressbar and clear the message in status bar
  mpStatusBar->clearMessage();
  hideProgressBar();
}

//! Exports the current model as image
void MainWindow::exportModelAsImage()
{
  ModelWidget *pModelWidget = mpModelWidgetContainer->getCurrentModelWidget();
  if (pModelWidget)
  {
    LibraryTreeNode *pLibraryTreeNode = pModelWidget->getLibraryTreeNode();
    if (pLibraryTreeNode)
    {
      QString fileName = StringHandler::getSaveFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::exportAsImage),
                                                        NULL, Helper::imageFileTypes, NULL, "svg", &pLibraryTreeNode->getName());
      // if user cancels the operation. or closes the export dialog box.
      if (fileName.isEmpty())
        return;
      bool oldSkipDrawBackground;
      // show the progressbar and set the message in status bar
      mpProgressBar->setRange(0, 0);
      showProgressBar();
      mpStatusBar->showMessage(tr("Exporting model as an Image"));
      QPainter painter;
      QSvgGenerator svgGenerator;
      GraphicsView *pGraphicsView;
      if (pLibraryTreeNode->getModelWidget()->getIconGraphicsView()->isVisible())
        pGraphicsView = pLibraryTreeNode->getModelWidget()->getIconGraphicsView();
      else
        pGraphicsView = pLibraryTreeNode->getModelWidget()->getDiagramGraphicsView();
      QPixmap modelImage(pGraphicsView->viewport()->size());
      // export svg
      if (fileName.endsWith(".svg"))
      {
        QRect bbox = pGraphicsView->itemsBoundingRect().toAlignedRect();
        QSize bigSize = pGraphicsView->viewport()->size();
        svgGenerator.setTitle(QString(Helper::applicationName).append(" - ").append(Helper::applicationIntroText));
        svgGenerator.setDescription("Generated by OMEdit - OpenModelica Connection Editor");
        svgGenerator.setSize(bigSize);
        svgGenerator.setViewBox(bbox);
        svgGenerator.setFileName(fileName);
        painter.begin(&svgGenerator);
      }
      else
      {
        modelImage.fill(QColor(Qt::transparent));
        painter.begin(&modelImage);
      }
      painter.setWindow(pGraphicsView->viewport()->rect());
      // paint the background color first
      if (!fileName.endsWith(".svg")) {
        if (pGraphicsView->getViewType() == StringHandler::Diagram)
          painter.fillRect(painter.viewport(), pGraphicsView->palette().background());
        else
          painter.fillRect(painter.viewport(), Qt::white);
      }
      // paint all the items
      oldSkipDrawBackground = pGraphicsView->mSkipBackground;
      if (fileName.endsWith(".svg")) {
        pGraphicsView->mSkipBackground = true;
      }
      pGraphicsView->render(&painter);
      painter.end();
      pGraphicsView->mSkipBackground = oldSkipDrawBackground;
      if (!fileName.endsWith(".svg"))
      {
        if (!modelImage.save(fileName))
          QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                                tr("Error saving the image file"), Helper::ok);
      }
      // hide the progressbar and clear the message in status bar
      mpStatusBar->clearMessage();
      hideProgressBar();
    }
  }
  else
  {
    mpMessagesWidget->addGUIMessage(new MessagesTreeItem("", false, 0, 0, 0, 0, GUIMessages::getMessage(GUIMessages::NO_MODELICA_CLASS_OPEN)
                                                    .arg(tr("exporting to Image")), Helper::scriptingKind, Helper::notificationLevel,
                                                    0, mpMessagesWidget->getMessagesTreeWidget()));
  }
}

void MainWindow::openConfigurationOptions()
{
  mpOptionsDialog->show();
}

void MainWindow::openUsersGuide()
{
  QUrl usersGuidePath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                       .append("/share/doc/omc/OpenModelicaUsersGuide.pdf"));
  QDesktopServices::openUrl(usersGuidePath);
}

void MainWindow::openSystemDocumentation()
{
  QUrl systemDocumentationPath (QString("file:///").append(QString(Helper::OpenModelicaHome).replace("\\", "/"))
                                .append("/share/doc/omc/OpenModelicaSystem.pdf"));
  QDesktopServices::openUrl(systemDocumentationPath);
}

void MainWindow::openAboutOMEdit()
{
  mpAboutOMEditDialog->setGeometry(QRect(rect().center() - QPoint(262.2, 235), rect().center() + QPoint(262.2, 235)));
  mpAboutOMEditDialog->setFocus(Qt::ActiveWindowFocusReason);
  mpAboutOMEditDialog->raise();
  mpAboutOMEditDialog->show();
}

void MainWindow::toggleShapesButton()
{
  QAction *clickedAction = qobject_cast<QAction*>(const_cast<QObject*>(sender()));
  QList<QAction*> shapeActions = mpShapesActionGroup->actions();
  foreach (QAction *shapeAction, shapeActions)
    if (shapeAction != clickedAction)
      shapeAction->setChecked(false);
}

void MainWindow::openRecentModelWidget()
{
  QAction *action = qobject_cast<QAction*>(sender());
  if (action)
  {
    LibraryTreeNode *pLibraryTreeNode = mpLibraryTreeWidget->getLibraryTreeNode(action->data().toString());
    mpModelWidgetContainer->addModelWidget(pLibraryTreeNode->getModelWidget(), false);
  }
}

void MainWindow::addNewPlotWindow()
{
  mpPlotWindowContainer->addPlotWindow();
}

void MainWindow::addNewPlotParametricWindow()
{
  mpPlotWindowContainer->addPlotParametricWindow();
}

void MainWindow::clearPlotWindow()
{
  mpPlotWindowContainer->clearPlotWindow();
}

//! shows the progress bar contained inside the status bar
//! @see hideProgressBar()
void MainWindow::showProgressBar()
{
  mpProgressBar->setVisible(true);
}

//! hides the progress bar contained inside the status bar
//! @see hideProgressBar()
void MainWindow::hideProgressBar()
{
  mpProgressBar->setVisible(false);
}

void MainWindow::updateModelSwitcherMenu(QMdiSubWindow *pActivatedWindow)
{
  Q_UNUSED(pActivatedWindow);
  ModelWidgetContainer *pModelWidgetContainer = qobject_cast<ModelWidgetContainer*>(sender());
  // get list of opened Model Widgets
  QList<QMdiSubWindow*> subWindowsList = mpModelWidgetContainer->subWindowList(QMdiArea::ActivationHistoryOrder);
  if (subWindowsList.isEmpty() && pModelWidgetContainer)
  {
    mpModelSwitcherToolButton->setEnabled(false);
    return;
  }
  int j = 0;
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--)
  {
    if (j >= MaxRecentFiles)
      break;
    ModelWidget *pModelWidget = qobject_cast<ModelWidget*>(subWindowsList.at(i)->widget());
    if (pModelWidget)
    {
      mpModelSwitcherActions[j]->setText(pModelWidget->getLibraryTreeNode()->getNameStructure());
      mpModelSwitcherActions[j]->setData(pModelWidget->getLibraryTreeNode()->getNameStructure());
      mpModelSwitcherActions[j]->setVisible(true);
    }
    j++;
  }
  // if subwindowlist size is less than MaxRecentFiles then hide the remaining actions
  int numRecentModels = qMin(subWindowsList.size(), (int)MaxRecentFiles);
  for (j = numRecentModels ; j < MaxRecentFiles ; j++)
    mpModelSwitcherActions[j]->setVisible(false);
}

void MainWindow::perspectiveTabChanged(int tabIndex)
{
  switch (tabIndex)
  {
    case 0:
      switchToWelcomePerspective();
      break;
    case 1:
      switchToModelingPerspective();
      break;
    case 2:
      switchToPlottingPerspective();
      break;
    case 3:
      switchToInteractiveSimulationPerspective();
      break;
    default:
      switchToWelcomePerspective();
      break;
  }
}

//! Defines the actions used by the toolbars
void MainWindow::createActions()
{
  /* Menu Actions */
  // File Menu
  // create new Modelica class action
  mpNewModelicaClassAction = new QAction(QIcon(":/Resources/icons/new.png"), Helper::newModelicaClass, this);
  mpNewModelicaClassAction->setStatusTip(Helper::createNewModelicaClass);
  mpNewModelicaClassAction->setShortcut(QKeySequence("Ctrl+n"));
  connect(mpNewModelicaClassAction, SIGNAL(triggered()), SLOT(createNewModelicaClass()));
  // open Modelica file action
  mpOpenModelicaFileAction = new QAction(QIcon(":/Resources/icons/open.png"), Helper::openModelicaFile, this);
  mpOpenModelicaFileAction->setShortcut(QKeySequence("Ctrl+o"));
  mpOpenModelicaFileAction->setStatusTip(tr("Opens the Modelica file(s)"));
  connect(mpOpenModelicaFileAction, SIGNAL(triggered()), SLOT(openModelicaFile()));
  // open Modelica file action
  mpOpenModelicaFileWithEncodingAction = new QAction(tr("Open Modelica File(s) with Encoding"), this);
  mpOpenModelicaFileWithEncodingAction->setStatusTip(tr("Opens the Modelica file(s) with encoding"));
  connect(mpOpenModelicaFileWithEncodingAction, SIGNAL(triggered()), SLOT(showOpenModelicaFileDialog()));
  // open result file action
  mpOpenResultFileAction = new QAction(tr("Open Result File(s)"), this);
  mpOpenResultFileAction->setShortcut(QKeySequence("Ctrl+shift+o"));
  mpOpenResultFileAction->setStatusTip(tr("Opens the OpenModelica Result file"));
  connect(mpOpenResultFileAction, SIGNAL(triggered()), SLOT(showOpenResultFileDialog()));
  // save file action
  mpSaveAction = new QAction(QIcon(":/Resources/icons/save.png"), tr("Save"), this);
  mpSaveAction->setShortcut(QKeySequence("Ctrl+s"));
  mpSaveAction->setStatusTip(tr("Save a file"));
  mpSaveAction->setEnabled(false);
  // save as file action
  mpSaveAsAction = new QAction(QIcon(":/Resources/icons/saveas.png"), tr("Save As"), this);
  mpSaveAsAction->setStatusTip(tr("Save As a File"));
  mpSaveAsAction->setEnabled(false);
  // save all file action
  mpSaveAllAction = new QAction(QIcon(":/Resources/icons/saveall.png"), tr("Save All"), this);
  mpSaveAllAction->setStatusTip(tr("Save All Files"));
  mpSaveAllAction->setEnabled(false);
  // recent files action
  for (int i = 0; i < MaxRecentFiles; ++i)
  {
    mpRecentFileActions[i] = new QAction(this);
    mpRecentFileActions[i]->setVisible(false);
    connect(mpRecentFileActions[i], SIGNAL(triggered()), this, SLOT(openRecentFile()));
  }
  // clear recent files action
  mpClearRecentFilesAction = new QAction(Helper::clearRecentFiles, this);
  mpClearRecentFilesAction->setStatusTip(tr("Clears the recent files list"));
  connect(mpClearRecentFilesAction, SIGNAL(triggered()), SLOT(clearRecentFilesList()));
  // print  action
  mpPrintModelAction = new QAction(QIcon(":/Resources/icons/print.png"), tr("Print..."), this);
  mpPrintModelAction->setShortcut(QKeySequence("Ctrl+p"));
  mpPrintModelAction->setEnabled(false);
  // close OMEdit action
  mpQuitAction = new QAction(QIcon(":/Resources/icons/quit.png"), tr("Quit"), this);
  mpQuitAction->setStatusTip(tr("Quit the ").append(Helper::applicationIntroText));
  mpQuitAction->setShortcut(QKeySequence("Ctrl+q"));
  connect(mpQuitAction, SIGNAL(triggered()), SLOT(close()));
  // Edit Menu
  // cut action
  mpCutAction = new QAction(QIcon(":/Resources/icons/cut.png"), tr("Cut"), this);
  mpCutAction->setShortcut(QKeySequence("Ctrl+x"));
  // copy action
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.png"), tr("Copy"), this);
  //! @todo opening this will stop copying data from messages window.
  //copyAction->setShortcut(QKeySequence("Ctrl+c"));
  // paste action
  mpPasteAction = new QAction(QIcon(":/Resources/icons/paste.png"), tr("Paste"), this);
  mpPasteAction->setShortcut(QKeySequence("Ctrl+v"));
  // find replace class action
  mpFindReplaceAction = new QAction(QIcon(":/Resources/icons/search.png"), QString(Helper::findReplaceModelicaText), this);
  mpFindReplaceAction->setStatusTip(tr("Shows the Find/Replace window"));
  mpFindReplaceAction->setShortcut(QKeySequence("Ctrl+f"));
  mpFindReplaceAction->setEnabled(false);
  connect(mpFindReplaceAction, SIGNAL(triggered()), SLOT(showFindReplaceDialog()));
  // clear find/replace texts action
  mpClearFindReplaceTextsAction = new QAction(tr("Clear Find/Replace Texts"), this);
  mpClearFindReplaceTextsAction->setStatusTip(tr("Clears the Find/Replace text items"));
  connect(mpClearFindReplaceTextsAction, SIGNAL(triggered()), SLOT(clearFindReplaceTexts()));
  // goto line action
  mpGotoLineNumberAction = new QAction(tr("Go to Line"), this);
  mpGotoLineNumberAction->setStatusTip(tr("Shows the Go to Line Number window"));
  mpGotoLineNumberAction->setShortcut(QKeySequence("Ctrl+l"));
  mpGotoLineNumberAction->setEnabled(false);
  connect(mpGotoLineNumberAction, SIGNAL(triggered()), SLOT(showGotoLineNumberDialog()));
  // View Menu
  // show/hide gridlines action
  mpShowGridLinesAction = new QAction(QIcon(":/Resources/icons/grid.png"), tr("Grid Lines"), this);
  mpShowGridLinesAction->setStatusTip(tr("Show/Hide the grid lines"));
  mpShowGridLinesAction->setCheckable(true);
  mpShowGridLinesAction->setEnabled(false);
  connect(mpShowGridLinesAction, SIGNAL(toggled(bool)), SLOT(setShowGridLines(bool)));
  // reset zoom action
  mpResetZoomAction = new QAction(QIcon(":/Resources/icons/zoomReset.png"), tr("Reset Zoom"), this);
  mpResetZoomAction->setStatusTip(tr("Resets the zoom"));
  mpResetZoomAction->setShortcut(QKeySequence("Ctrl+0"));
  mpResetZoomAction->setEnabled(false);
  connect(mpResetZoomAction, SIGNAL(triggered()), SLOT(resetZoom()));
  // zoom in action
  mpZoomInAction = new QAction(QIcon(":/Resources/icons/zoomIn.png"), tr("Zoom In"), this);
  mpZoomInAction->setStatusTip(tr("Zoom in"));
  mpZoomInAction->setShortcut(QKeySequence("Ctrl++"));
  mpZoomInAction->setEnabled(false);
  connect(mpZoomInAction, SIGNAL(triggered()), SLOT(zoomIn()));
  // zoom out action
  mpZoomOutAction = new QAction(QIcon(":/Resources/icons/zoomOut.png"), tr("Zoom Out"), this);
  mpZoomOutAction->setStatusTip(tr("Zoom out"));
  mpZoomOutAction->setShortcut(QKeySequence("Ctrl+-"));
  mpZoomOutAction->setEnabled(false);
  connect(mpZoomOutAction, SIGNAL(triggered()), SLOT(zoomOut()));
  // Simulation Menu
  // simulate action
  mpSimulationAction = new QAction(QIcon(":/Resources/icons/simulate.png"), Helper::simulate, this);
  mpSimulationAction->setStatusTip(Helper::simulateTip);
  mpSimulationAction->setShortcut(QKeySequence("Ctrl+b"));
  mpSimulationAction->setEnabled(false);
  connect(mpSimulationAction, SIGNAL(triggered()), SLOT(openSimulationDialog()));
  // instantiate model action
  mpInstantiateModelAction = new QAction(QIcon(":/Resources/icons/flatmodel.png"), tr("Instantiate Model"), this);
  mpInstantiateModelAction->setStatusTip(tr("Instantiates the modelica model"));
  mpInstantiateModelAction->setEnabled(false);
  connect(mpInstantiateModelAction, SIGNAL(triggered()), SLOT(instantiatesModel()));
  // check model action
  mpCheckModelAction = new QAction(QIcon(":/Resources/icons/check.png"), tr("Check Model"), this);
  mpCheckModelAction->setStatusTip(tr("Check the modelica model"));
  mpCheckModelAction->setEnabled(false);
  connect(mpCheckModelAction, SIGNAL(triggered()), SLOT(checkModel()));
  // FMI Menu
  // export FMU action
  mpExportFMUAction = new QAction(QIcon(":/Resources/icons/export-fmu.png"), Helper::exportFMU, this);
  mpExportFMUAction->setStatusTip(Helper::exportFMUTip);
  mpExportFMUAction->setEnabled(false);
  connect(mpExportFMUAction, SIGNAL(triggered()), SLOT(exportModelFMU()));
  // import FMU action
  mpImportFMUAction = new QAction(QIcon(":/Resources/icons/import-fmu.png"), Helper::importFMU, this);
  mpImportFMUAction->setStatusTip(Helper::importFMUTip);
  connect(mpImportFMUAction, SIGNAL(triggered()), SLOT(importModelFMU()));
  // XML Menu
  // export XML action
  mpExportXMLAction = new QAction(QIcon(":/Resources/icons/export-xml.png"), Helper::exportXML, this);
  mpExportXMLAction->setStatusTip(Helper::exportXMLTip);
  mpExportXMLAction->setEnabled(false);
  connect(mpExportXMLAction, SIGNAL(triggered()), SLOT(exportModelXML()));
  // Tools Menu
  // show omc logger action
  mpOmcLoggerAction = new QAction(QIcon(":/Resources/icons/console.png"), tr("OMC Logger"), this);
  mpOmcLoggerAction->setStatusTip(tr("Shows OMC Logger Window"));
  connect(mpOmcLoggerAction, SIGNAL(triggered()), mpOMCProxy, SLOT(openOMCLogger()));
  // export to OMNotebook action
  mpExportToOMNotebookAction = new QAction(QIcon(":/Resources/icons/export-omnotebook.png"), Helper::exportToOMNotebook, this);
  mpExportToOMNotebookAction->setStatusTip(Helper::exportToOMNotebookTip);
  mpExportToOMNotebookAction->setEnabled(false);
  connect(mpExportToOMNotebookAction, SIGNAL(triggered()), SLOT(exportModelToOMNotebook()));
  // import from OMNotebook action
  mpImportFromOMNotebookAction = new QAction(QIcon(":/Resources/icons/import-omnotebook.png"), Helper::importFromOMNotebook, this);
  mpImportFromOMNotebookAction->setStatusTip(Helper::importFromOMNotebookTip);
  connect(mpImportFromOMNotebookAction, SIGNAL(triggered()), SLOT(importModelfromOMNotebook()));
  // open options action
  mpOptionsAction = new QAction(QIcon(":/Resources/icons/options.png"), tr("Options"), this);
  mpOptionsAction->setStatusTip(tr("Shows the options window"));
  connect(mpOptionsAction, SIGNAL(triggered()), SLOT(openConfigurationOptions()));
  // Help Menu
  // users guide action
  mpUsersGuideAction = new QAction(tr("OpenModelica Users Guide"), this);
  mpUsersGuideAction->setStatusTip(tr("Opens the OpenModelica Users Guide"));
  mpUsersGuideAction->setShortcut(QKeySequence(Qt::Key_F1));
  connect(mpUsersGuideAction, SIGNAL(triggered()), SLOT(openUsersGuide()));
  // system documentation action
  mpSystemDocumentationAction = new QAction(tr("OpenModelica System Documentation"), this);
  mpSystemDocumentationAction->setStatusTip(tr("Opens the OpenModelica System Documentation"));
  connect(mpSystemDocumentationAction, SIGNAL(triggered()), SLOT(openSystemDocumentation()));
  // about OMEdit action
  mpAboutOMEditAction = new QAction(tr("About OMEdit"), this);
  mpAboutOMEditAction->setStatusTip(tr("Information about OMEdit"));
  connect(mpAboutOMEditAction, SIGNAL(triggered()), SLOT(openAboutOMEdit()));
  /* Toolbar Actions */
  // custom shapes group
  mpShapesActionGroup = new QActionGroup(this);
  mpShapesActionGroup->setExclusive(false);
  // line creation action
  mpLineShapeAction = new QAction(QIcon(":/Resources/icons/line-shape.png"), tr("Line"), mpShapesActionGroup);
  mpLineShapeAction->setStatusTip(tr("Draws a line shape"));
  mpLineShapeAction->setCheckable(true);
  connect(mpLineShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // polygon creation action
  mpPolygonShapeAction = new QAction(QIcon(":/Resources/icons/polygon-shape.png"), tr("Polygon"), mpShapesActionGroup);
  mpPolygonShapeAction->setStatusTip(tr("Draws a polygon shape"));
  mpPolygonShapeAction->setCheckable(true);
  connect(mpPolygonShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // rectangle creation action
  mpRectangleShapeAction = new QAction(QIcon(":/Resources/icons/rectangle-shape.png"), tr("Rectangle"), mpShapesActionGroup);
  mpRectangleShapeAction->setStatusTip(tr("Draws a rectangle shape"));
  mpRectangleShapeAction->setCheckable(true);
  connect(mpRectangleShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // ellipse creation action
  mpEllipseShapeAction = new QAction(QIcon(":/Resources/icons/ellipse-shape.png"), tr("Ellipse"), mpShapesActionGroup);
  mpEllipseShapeAction->setStatusTip(tr("Draws an ellipse shape"));
  mpEllipseShapeAction->setCheckable(true);
  connect(mpEllipseShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // text creation action
  mpTextShapeAction = new QAction(QIcon(":/Resources/icons/text-shape.png"), tr("Text"), mpShapesActionGroup);
  mpTextShapeAction->setStatusTip(tr("Draws a text shape"));
  mpTextShapeAction->setCheckable(true);
  connect(mpTextShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // bitmap creation action
  mpBitmapShapeAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), tr("Bitmap"), mpShapesActionGroup);
  mpBitmapShapeAction->setStatusTip(tr("Inserts a bitmap"));
  mpBitmapShapeAction->setCheckable(true);
  connect(mpBitmapShapeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // connect/unconnect action
  mpConnectModeAction = new QAction(QIcon(":/Resources/icons/connect-mode.png"), tr("Connect/Unconnect Mode"), mpShapesActionGroup);
  mpConnectModeAction->setStatusTip(tr("Changes to/from connect mode"));
  mpConnectModeAction->setCheckable(true);
  mpConnectModeAction->setChecked(true);
  connect(mpConnectModeAction, SIGNAL(triggered()), SLOT(toggleShapesButton()));
  // model switcher actions
  for (int i = 0; i < MaxRecentFiles; ++i)
  {
    mpModelSwitcherActions[i] = new QAction(this);
    mpModelSwitcherActions[i]->setVisible(false);
    connect(mpModelSwitcherActions[i], SIGNAL(triggered()), this, SLOT(openRecentModelWidget()));
  }
  // new plot window action
  mpNewPlotWindowAction = new QAction(QIcon(":/Resources/icons/plotwindow.png"), tr("New Plot Window"), this);
  mpNewPlotWindowAction->setStatusTip(tr("Inserts new plot window"));
  connect(mpNewPlotWindowAction, SIGNAL(triggered()), SLOT(addNewPlotWindow()));
  // new plot parametric action
  mpNewPlotParametricWindowAction = new QAction(QIcon(":/Resources/icons/plotparametricwindow.png"), tr("New Plot Parametric Window"), this);
  mpNewPlotParametricWindowAction->setStatusTip(tr("Inserts new plot parametric window"));
  connect(mpNewPlotParametricWindowAction, SIGNAL(triggered()), SLOT(addNewPlotParametricWindow()));
  // clear plot window action
  mpClearPlotWindowAction = new QAction(QIcon(":/Resources/icons/clearmessages.png"), tr("Clear Plot Window"), this);
  mpClearPlotWindowAction->setStatusTip(tr("Clears all the curves from the plot window"));
  connect(mpClearPlotWindowAction, SIGNAL(triggered()), SLOT(clearPlotWindow()));
  // Other Actions
  // export as image action
  mpExportAsImageAction = new QAction(QIcon(":/Resources/icons/bitmap-shape.png"), Helper::exportAsImage, this);
  mpExportAsImageAction->setStatusTip(Helper::exportAsImageTip);
  mpExportAsImageAction->setEnabled(false);
  connect(mpExportAsImageAction, SIGNAL(triggered()), SLOT(exportModelAsImage()));
}

//! Creates the menus
void MainWindow::createMenus()
{
  //Create the menubar
  QMenuBar *pMenuBar = new QMenuBar();
  //Create the menus
  // File menu
  QMenu *pFileMenu = new QMenu(pMenuBar);
  pFileMenu->setObjectName("menuFile");
  pFileMenu->setTitle(tr("&File"));
  // add actions to File menu
  pFileMenu->addAction(mpNewModelicaClassAction);
  pFileMenu->addAction(mpOpenModelicaFileAction);
  pFileMenu->addAction(mpOpenModelicaFileWithEncodingAction);
  pFileMenu->addAction(mpOpenResultFileAction);
  pFileMenu->addAction(mpSaveAction);
  pFileMenu->addAction(mpSaveAsAction);
  //menuFile->addAction(saveAllAction);
  pFileMenu->addSeparator();
  mpLibrariesMenu = new QMenu(pMenuBar);
  mpLibrariesMenu->setObjectName("LibrariesMenu");
  mpLibrariesMenu->setTitle(tr("&System Libraries"));
  // get the available libraries.
  QStringList libraries = mpOMCProxy->getAvailableLibraries();
  for (int i = 0; i < libraries.size(); ++i)
  {
    QAction *pAction = new QAction(libraries[i], this);
    connect(pAction, SIGNAL(triggered()), SLOT(loadSystemLibrary()));
    mpLibrariesMenu->addAction(pAction);
  }
  pFileMenu->addMenu(mpLibrariesMenu);
  pFileMenu->addSeparator();
  mpRecentFilesMenu = new QMenu(pMenuBar);
  mpRecentFilesMenu->setObjectName("RecentFilesMenu");
  mpRecentFilesMenu->setTitle(tr("Recent &Files"));
  for (int i = 0; i < MaxRecentFiles; ++i)
    mpRecentFilesMenu->addAction(mpRecentFileActions[i]);
  pFileMenu->addMenu(mpRecentFilesMenu);
  pFileMenu->addAction(mpClearRecentFilesAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpPrintModelAction);
  pFileMenu->addSeparator();
  pFileMenu->addAction(mpQuitAction);
  // add File menu to menu bar
  pMenuBar->addAction(pFileMenu->menuAction());
  // Edit menu
  QMenu *pEditMenu = new QMenu(pMenuBar);
  pEditMenu->setTitle(tr("&Edit"));
  // add actions to Edit menu
  pEditMenu->addAction(mpCutAction);
  pEditMenu->addAction(mpCopyAction);
  pEditMenu->addAction(mpPasteAction);
  pEditMenu->addSeparator();
  pEditMenu->addAction(mpFindReplaceAction);
  pEditMenu->addAction(mpClearFindReplaceTextsAction);
  pEditMenu->addAction(mpGotoLineNumberAction);
  // add Edit menu to menu bar
  pMenuBar->addAction(pEditMenu->menuAction());
  // View menu
  QMenu *pViewMenu = new QMenu(pMenuBar);
  pViewMenu->setTitle(tr("&View"));
  // Toolbars View Menu
  QMenu *pViewToolbarsMenu = new QMenu(pMenuBar);
  pViewToolbarsMenu->setObjectName("ToolbarsViewMenu");
  pViewToolbarsMenu->setTitle(tr("Toolbars"));
  // Windows View Menu
  QMenu *pViewWindowsMenu = new QMenu(pMenuBar);
  pViewWindowsMenu->setObjectName("WindowsViewMenu");
  pViewWindowsMenu->setTitle(tr("Windows"));
  // Perspectives View Menu
  QMenu *pViewPerspectivesMenu = new QMenu(pMenuBar);
  pViewPerspectivesMenu->setObjectName("PerspectivesViewMenu");
  pViewPerspectivesMenu->setTitle(tr("Perspectives"));
  // add actions to View menu
  // Add Actions to Toolbars View Sub Menu
  pViewToolbarsMenu->addAction(mpFileToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpEditToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpViewToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpShapesToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpSimulationToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpPlotToolBar->toggleViewAction());
  pViewToolbarsMenu->addAction(mpModelSwitcherToolBar->toggleViewAction());
  pViewMenu->addAction(pViewToolbarsMenu->menuAction());
  // Add Actions to Windows View Sub Menu
  QAction *pSearchClassAction = mpSearchClassDockWidget->toggleViewAction();
  pSearchClassAction->setShortcut(QKeySequence("Ctrl+Shift+f"));
  pViewWindowsMenu->addAction(pSearchClassAction);
  pViewWindowsMenu->addAction(mpLibraryTreeDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpDocumentationDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpVariablesDockWidget->toggleViewAction());
  pViewWindowsMenu->addAction(mpMessagesDockWidget->toggleViewAction());
  pViewMenu->addAction(pViewWindowsMenu->menuAction());
  pViewMenu->addSeparator();
  pViewMenu->addAction(mpShowGridLinesAction);
  pViewMenu->addAction(mpResetZoomAction);
  pViewMenu->addAction(mpZoomInAction);
  pViewMenu->addAction(mpZoomOutAction);
  // add View menu to menu bar
  pMenuBar->addAction(pViewMenu->menuAction());
  // Simulation Menu
  QMenu *pSimulationMenu = new QMenu(pMenuBar);
  pSimulationMenu->setTitle(tr("&Simulation"));
  // add actions to Simulation menu
  pSimulationMenu->addAction(mpSimulationAction);
  pSimulationMenu->addAction(mpInstantiateModelAction);
  pSimulationMenu->addAction(mpCheckModelAction);
  // add Simulation menu to menu bar
  pMenuBar->addAction(pSimulationMenu->menuAction());
  // FMI menu
  QMenu *pFMIMenu = new QMenu(pMenuBar);
  pFMIMenu->setTitle(tr("F&MI"));
  // add actions to FMI menu
  pFMIMenu->addAction(mpExportFMUAction);
  pFMIMenu->addAction(mpImportFMUAction);
  // add FMI menu to menu bar
  pMenuBar->addAction(pFMIMenu->menuAction());
  // XML menu
  QMenu *pXMLMenu = new QMenu(pMenuBar);
  pXMLMenu->setTitle(tr("&XML"));
  // add actions to XML menu
  pXMLMenu->addAction(mpExportXMLAction);
  // add XML menu to menu bar
  pMenuBar->addAction(pXMLMenu->menuAction());
  // Tools menu
  QMenu *pToolsMenu = new QMenu(pMenuBar);
  pToolsMenu->setTitle(tr("&Tools"));
  // add actions to Tools menu
  pToolsMenu->addAction(mpOmcLoggerAction);
  pToolsMenu->addSeparator();
  pToolsMenu->addAction(mpExportToOMNotebookAction);
  pToolsMenu->addAction(mpImportFromOMNotebookAction);
  pToolsMenu->addSeparator();
  pToolsMenu->addAction(mpOptionsAction);
  // add Tools menu to menu bar
  pMenuBar->addAction(pToolsMenu->menuAction());
  // Help menu
  QMenu *pHelpMenu = new QMenu(pMenuBar);
  pHelpMenu->setTitle(tr("&Help"));
  // add actions to Help menu
  pHelpMenu->addAction(mpUsersGuideAction);
  pHelpMenu->addAction(mpSystemDocumentationAction);
  pHelpMenu->addAction(mpAboutOMEditAction);
  // add Help menu to menu bar
  pMenuBar->addAction(pHelpMenu->menuAction());
  // set menubar
  setMenuBar(pMenuBar);
}

void MainWindow::switchToWelcomePerspective()
{
  mpWelcomePageWidget->setVisible(true);
  mpModelWidgetContainer->setVisible(false);
  mpModelWidgetContainer->currentModelWidgetChanged(0);
  mpModelSwitcherToolButton->setEnabled(false);
  mpPlotWindowContainer->setVisible(false);
  mpVariablesDockWidget->hide();
  mpPlotToolBar->setEnabled(false);
  //mpInteractiveSimualtionTabWidget->setVisible(false);
}

void MainWindow::switchToModelingPerspective()
{
  mpWelcomePageWidget->setVisible(false);
  mpModelWidgetContainer->setVisible(true);
  mpModelWidgetContainer->currentModelWidgetChanged(mpModelWidgetContainer->getCurrentMdiSubWindow());
  mpModelSwitcherToolButton->setEnabled(true);
  mpPlotWindowContainer->setVisible(false);
  mpVariablesDockWidget->hide();
  mpPlotToolBar->setEnabled(false);
  //mpInteractiveSimualtionTabWidget->setVisible(false);
}

void MainWindow::switchToPlottingPerspective()
{
  mpWelcomePageWidget->setVisible(false);
  mpModelWidgetContainer->setVisible(false);
  mpModelWidgetContainer->currentModelWidgetChanged(0);
  mpModelSwitcherToolButton->setEnabled(false);
  // if not plotwindow is opened then open one for user
  if (mpPlotWindowContainer->subWindowList().size() == 0)
    mpPlotWindowContainer->addPlotWindow();
  mpPlotWindowContainer->setVisible(true);
  mpVariablesDockWidget->show();
  mpPlotToolBar->setEnabled(true);
  //mpInteractiveSimualtionTabWidget->setVisible(false);
}

void MainWindow::switchToInteractiveSimulationPerspective()
{
  mpWelcomePageWidget->setVisible(false);
  mpModelWidgetContainer->setVisible(false);
  mpModelWidgetContainer->currentModelWidgetChanged(0);
  mpModelSwitcherToolButton->setEnabled(false);
  mpPlotWindowContainer->setVisible(false);
  mpVariablesDockWidget->hide();
  mpPlotToolBar->setEnabled(false);
  //mpInteractiveSimualtionTabWidget->setVisible(true);
}

//! Creates the toolbars
void MainWindow::createToolbars()
{
  setIconSize(QSize(16, 16));
  // File Toolbar
  mpFileToolBar = addToolBar(tr("File Toolbar"));
  mpFileToolBar->setObjectName("File Toolbar");
  mpFileToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to File Toolbar
  mpFileToolBar->addAction(mpNewModelicaClassAction);
  mpFileToolBar->addAction(mpOpenModelicaFileAction);
  mpFileToolBar->addAction(mpSaveAction);
  mpFileToolBar->addAction(mpSaveAsAction);
  mpFileToolBar->addAction(mpSaveAllAction);
  // Edit Toolbar
  mpEditToolBar = addToolBar(tr("Edit Toolbar"));
  mpEditToolBar->setObjectName("Edit Toolbar");
  mpEditToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to edit toolbar
  mpEditToolBar->addAction(mpCutAction);
  mpEditToolBar->addAction(mpCopyAction);
  mpEditToolBar->addAction(mpPasteAction);
  // View Toolbar
  mpViewToolBar = addToolBar(tr("View Toolbar"));
  mpViewToolBar->setObjectName("View Toolbar");
  mpViewToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to View Toolbar
  mpViewToolBar->addAction(mpShowGridLinesAction);
  mpViewToolBar->addSeparator();
  mpViewToolBar->addAction(mpResetZoomAction);
  mpViewToolBar->addAction(mpZoomInAction);
  mpViewToolBar->addAction(mpZoomOutAction);
  // Shapes Toolbar
  mpShapesToolBar = addToolBar(tr("Shapes Toolbar"));
  mpShapesToolBar->setObjectName("Shapes Toolbar");
  mpShapesToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Shapes Toolbar
  mpShapesToolBar->addAction(mpLineShapeAction);
  mpShapesToolBar->addAction(mpPolygonShapeAction);
  mpShapesToolBar->addAction(mpRectangleShapeAction);
  mpShapesToolBar->addAction(mpEllipseShapeAction);
  mpShapesToolBar->addAction(mpTextShapeAction);
  mpShapesToolBar->addAction(mpBitmapShapeAction);
  mpShapesToolBar->addSeparator();
  mpShapesToolBar->addAction(mpConnectModeAction);
  // Simulation Toolbar
  mpSimulationToolBar = addToolBar(tr("Simulation Toolbar"));
  mpSimulationToolBar->setObjectName("Simulation Toolbar");
  mpSimulationToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // add actions to Simulation Toolbar
  mpSimulationToolBar->addAction(mpSimulationAction);
  mpSimulationToolBar->addAction(mpInstantiateModelAction);
  mpSimulationToolBar->addAction(mpCheckModelAction);
  // Model Swithcer Toolbar
  mpModelSwitcherToolBar = addToolBar(tr("ModelSwitcher Toolbar"));
  mpModelSwitcherToolBar->setObjectName("ModelSwitcher Toolbar");
  mpModelSwitcherToolBar->setAllowedAreas(Qt::TopToolBarArea);
  // Model Switcher Menu
  mpModelSwitcherMenu = new QMenu;
  for (int i = 0; i < MaxRecentFiles; ++i)
  {
    mpModelSwitcherMenu->addAction(mpModelSwitcherActions[i]);
  }
  // Model Switcher ToolButton
  mpModelSwitcherToolButton = new QToolButton;
  mpModelSwitcherToolButton->setEnabled(false);
  mpModelSwitcherToolButton->setMenu(mpModelSwitcherMenu);
  mpModelSwitcherToolButton->setPopupMode(QToolButton::MenuButtonPopup);
  mpModelSwitcherToolButton->setIcon(QIcon(":/Resources/icons/switch.png"));
  mpModelSwitcherToolBar->addWidget(mpModelSwitcherToolButton);
  // Plot Toolbar
  mpPlotToolBar = addToolBar(tr("Plot Toolbar"));
  mpPlotToolBar->setObjectName("Plot Toolbar");
  mpPlotToolBar->setAllowedAreas(Qt::TopToolBarArea);
  mpPlotToolBar->setEnabled(false);
  // add actions to Plot Toolbar
  mpPlotToolBar->addAction(mpNewPlotWindowAction);
  mpPlotToolBar->addAction(mpNewPlotParametricWindowAction);
  mpPlotToolBar->addAction(mpClearPlotWindowAction);
}

//! when the dragged object enters the main window
//! @param event contains information of the drag operation.
void MainWindow::dragEnterEvent(QDragEnterEvent *event)
{
  event->setDropAction(Qt::CopyAction);
  event->accept();
}

//! Defines what happens when moving an object in the MainWindow.
//! @param event contains information of the drag operation.
void MainWindow::dragMoveEvent(QDragMoveEvent *event)
{
  if(event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    event->setDropAction(Qt::CopyAction);
    event->accept();
  }
  else
  {
    event->ignore();
  }
}

//! Defines what happens when drop a file in a Main Window.
//! @param event contains information of the drop operation.
void MainWindow::dropEvent(QDropEvent *event)
{
  if (!event->mimeData()->hasFormat(Helper::modelicaFileFormat))
  {
    event->ignore();
    return;
  }
  openDroppedFile(event);
  event->accept();
}

/*!
  Reimplementation of resizeEvent.\n
  Resizes the AboutOMEditWidget whenever the MainWindow is resized.
  */
void MainWindow::resizeEvent(QResizeEvent *event)
{
  if (mpAboutOMEditDialog)
    if (mpAboutOMEditDialog->isVisible())
      mpAboutOMEditDialog->setGeometry(QRect(rect().center() - QPoint(262.2, 235), rect().center() + QPoint(262.2, 235)));
  QMainWindow::resizeEvent(event);
}

InfoBar::InfoBar(MainWindow *pParent)
  : QFrame(pParent)
{
  QPalette pal = palette();
  pal.setColor(QPalette::Window, QColor(255, 255, 225));
  pal.setColor(QPalette::WindowText, Qt::black);
  setPalette(pal);
  setFrameStyle(QFrame::StyledPanel);
  setAutoFillBackground(true);
  mpInfoLabel = new Label;
  mpInfoLabel->setWordWrap(true);
  mpCloseButton = new QToolButton;
  mpCloseButton->setAutoRaise(true);
  mpCloseButton->setIcon(QIcon(":/Resources/icons/clear.png"));
  mpCloseButton->setToolTip(Helper::close);
  connect(mpCloseButton, SIGNAL(clicked()), SLOT(hide()));
  // set the layout
  QHBoxLayout *pMainLayout = new QHBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setMargin(2);
  pMainLayout->addWidget(mpInfoLabel);
  pMainLayout->addWidget(mpCloseButton, 0, Qt::AlignTop);
  setLayout(pMainLayout);
}

void InfoBar::showMessage(QString message)
{
  mpInfoLabel->setText(message);
  show();
}

/*!
  \class AboutOMEditWidget
  \brief Creates a widget that shows the about text of OMEdit.

  Information about OpenModelica Connection Editor. Shows the list of OMEdit contributors.
  */

/*!
  \param pParent - pointer to MainWindow
  */
AboutOMEditWidget::AboutOMEditWidget(MainWindow *pMainWindow)
  : QWidget(pMainWindow)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
  setMinimumSize(525, 470);
  setMaximumSize(525, 470);
  mBackgroundPixmap.load(":/Resources/icons/about-us.png");
#ifdef Q_OS_MAC
  int MAC_FONT_FACTOR = 5;  /* the system font size in MAC is too small. */
#else
  int MAC_FONT_FACTOR = 0;
#endif
  // OMEdit intro text
  Label *pIntroLabel = new Label(Helper::applicationIntroText);
  pIntroLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::systemFontInfo.pointSize() + 3 + MAC_FONT_FACTOR));
  // OpenModelica compiler info
  Label *pConnectedLabel = new Label(QString("Connected to OpenModelica ").append(pMainWindow->getOMCProxy()->getVersion()));
  pConnectedLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::systemFontInfo.pointSize() - 2 + MAC_FONT_FACTOR));
  // about text
  QString aboutText = QString("Copyright <b>Open Source Modelica Consortium (OSMC)</b>.<br />")
      .append("Distributed under OSMC-PL and GPL, see <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>.<br /><br />")
      .append("Initially developed by <b>Adeel Asghar</b> and <b>Sonia Tariq</b> as part of their final master thesis.");
  Label *pAboutTextLabel = new Label;
  pAboutTextLabel->setTextFormat(Qt::RichText);
  pAboutTextLabel->setTextInteractionFlags(pAboutTextLabel->textInteractionFlags() |Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  pAboutTextLabel->setOpenExternalLinks(true);
  pAboutTextLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::systemFontInfo.pointSize() - 4 + MAC_FONT_FACTOR));
  pAboutTextLabel->setWordWrap(true);
  pAboutTextLabel->setText(aboutText);
  QVBoxLayout *pAboutLayout = new QVBoxLayout;
  pAboutLayout->setContentsMargins(0, 0, 0, 0);
  pAboutLayout->addWidget(pAboutTextLabel);
  // contributors heading
  QString contributorsHeading = QString("<b>Contributors:</b>");
  Label *pContributorsHeading = new Label;
  pContributorsHeading->setTextFormat(Qt::RichText);
  pContributorsHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::systemFontInfo.pointSize() - 4 + MAC_FONT_FACTOR));
  pContributorsHeading->setText(contributorsHeading);
  // contributors text
  QString contributorsText = QString("<ul style=\"margin: 0px 0px 0px -32px; padding: 2px;\">")
      .append("<li>Adeel Asghar - <u><a href=\"mailto:adeel.asghar@liu.se\">adeel.asghar@liu.se</a></u></li>")
      .append("<li>Sonia Tariq</li>")
      .append("<li>Martin Sjölund - <u><a href=\"mailto:martin.sjolund@liu.se\">martin.sjolund@liu.se</a></u></li>")
      .append("<li>Haris Kapidzic</li>")
      .append("<li>Abhinn Kothari</li>")
      .append("<li>Dr. Henning Kiel</li>")
      .append("<li>Alachew Shitahun</li>")
      .append("</ul>");
  Label *pContributorsLabel = new Label;
  pContributorsLabel->setTextFormat(Qt::RichText);
  pContributorsLabel->setTextInteractionFlags(pContributorsLabel->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  pContributorsLabel->setOpenExternalLinks(true);
  pContributorsLabel->setFont(QFont(Helper::systemFontInfo.family(), Helper::systemFontInfo.pointSize() - 4 + MAC_FONT_FACTOR));
  pContributorsLabel->setText(contributorsText);
  // QScrollArea
  QScrollArea *pScrollArea = new QScrollArea;
  pScrollArea->setFrameShape(QFrame::NoFrame);
  pScrollArea->setBackgroundRole(QPalette::Base);
  pScrollArea->setWidgetResizable(true);
  pScrollArea->setWidget(pContributorsLabel);
  // close button
  QPushButton *pCloseButton = new QPushButton(Helper::close);
  connect(pCloseButton, SIGNAL(clicked()), SLOT(hide()));
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(45, 200, 45, 20);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pIntroLabel, 1, 0, 1, 1, Qt::AlignHCenter);
  pMainLayout->addWidget(pConnectedLabel, 2, 0, 1, 1, Qt::AlignHCenter);
  pMainLayout->addLayout(pAboutLayout, 3, 0, 1, 1);
  pMainLayout->addWidget(pContributorsHeading, 4, 0, 1, 1);
  pMainLayout->addWidget(pScrollArea, 5, 0, 1, 1);
  pMainLayout->addWidget(pCloseButton, 6, 0, 1, 1, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Reimplementation of paintEvent.\n
  Draws the background image.
  \param event - pointer to QPaintEvent
  */
void AboutOMEditWidget::paintEvent(QPaintEvent *pEvent)
{
  QWidget::paintEvent(pEvent);
  QPainter painter(this);
  painter.drawPixmap((size().width() - mBackgroundPixmap.size().width())/2,
                     (size().height() - mBackgroundPixmap.size().height())/2, mBackgroundPixmap);
}

/*!
  Reimplementation of keyPressEvent.\n
  Hides the widget.
  */
void AboutOMEditWidget::keyPressEvent(QKeyEvent *pEvent)
{
  if (pEvent->key() == Qt::Key_Escape)
    hide();
  QWidget::keyPressEvent(pEvent);
}
