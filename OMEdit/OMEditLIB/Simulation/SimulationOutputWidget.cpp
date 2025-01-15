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

#include "SimulationOutputWidget.h"
#include "ArchivedSimulationsWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Util/OutputPlainTextEdit.h"
#include "SimulationOutputHandler.h"
#include "Editors/CEditor.h"
#include "Editors/TextEditor.h"
#include "SimulationDialog.h"
#include "TransformationalDebugger/TransformationsWidget.h"

#include <QApplication>
#include <QObject>
#include <QHeaderView>
#include <QAction>
#include <QMenu>
#include <QTcpSocket>
#include <QMessageBox>
#include <QTextDocumentFragment>
#include <QClipboard>
#include <QDesktopServices>

extern "C" {
extern const char* System_openModelicaPlatform();
}

/*!
 * \class SimulationOutputTree
 * \brief A tree based structure for simulation output messages.
 */
/*!
 * \brief SimulationOutputTree::SimulationOutputTree
 * \param pSimulationOutputWidget
 */
SimulationOutputTree::SimulationOutputTree(SimulationOutputWidget *pSimulationOutputWidget)
  : QTreeView(pSimulationOutputWidget), mpSimulationOutputWidget(pSimulationOutputWidget)
{
  setItemDelegate(new ItemDelegate(this, true));
  setTextElideMode(Qt::ElideNone);
  setIndentation(Helper::treeIndentation);
  setExpandsOnDoubleClick(false);
  setHeaderHidden(true);
  setMouseTracking(true); /* important for Debug more links. */
  setSelectionMode(QAbstractItemView::ExtendedSelection);
  setContextMenuPolicy(Qt::CustomContextMenu);
  setFont(QFont(Helper::monospacedFontInfo.family()));
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(header(), SIGNAL(sectionResized(int,int,int)), SLOT(callLayoutChanged(int,int,int)));
  // create actions
  mpSelectAllAction = new QAction(tr("Select All"), this);
  mpSelectAllAction->setShortcut(QKeySequence("Ctrl+a"));
  mpSelectAllAction->setStatusTip(tr("Selects all the Messages"));
  connect(mpSelectAllAction, SIGNAL(triggered()), SLOT(selectAllMessages()));
  mpCopyAction = new QAction(QIcon(":/Resources/icons/copy.svg"), Helper::copy, this);
  mpCopyAction->setShortcut(QKeySequence("Ctrl+c"));
  mpCopyAction->setStatusTip(tr("Copy the Message"));
  connect(mpCopyAction, SIGNAL(triggered()), SLOT(copyMessages()));
  mpExpandAllAction = new QAction(Helper::expandAll, this);
  mpExpandAllAction->setStatusTip(tr("Copy the Message"));
  connect(mpExpandAllAction, SIGNAL(triggered()), SLOT(expandAll()));
  mpCollapseAllAction = new QAction(Helper::collapseAll, this);
  mpCollapseAllAction->setStatusTip(tr("Copy the Message"));
  connect(mpCollapseAllAction, SIGNAL(triggered()), SLOT(collapseAll()));
}

/*!
 * \brief SimulationOutputTree::getDepth
 * Asks the model about the depth/level of QModelIndex.
 * \param index
 * \return
 */
int SimulationOutputTree::getDepth(const QModelIndex &index) const
{
  SimulationMessageModel *pSimulationMessageModel = qobject_cast<SimulationMessageModel*>(model());
  if (pSimulationMessageModel) {
    return pSimulationMessageModel->getDepth(index);
  } else {
    return 1;
  }
}

/*!
 * \brief SimulationOutputTree::showContextMenu
 * Shows a context menu when user right click on the Messages tree.
 * Slot activated when SimulationOutputTree::customContextMenuRequested() signal is raised.
 * \param point
 */
void SimulationOutputTree::showContextMenu(QPoint point)
{
  QMenu menu(this);
  menu.addAction(mpSelectAllAction);
  menu.addAction(mpCopyAction);
  menu.addSeparator();
  menu.addAction(mpExpandAllAction);
  menu.addAction(mpCollapseAllAction);
  menu.exec(viewport()->mapToGlobal(point));
}

/*!
 * \brief SimulationOutputTree::callLayoutChanged
 * Slot activated when QHeaderView sectionResized signal is raised.\n
 * Tells the model to emit layoutChanged signal.\n
 * \sa SimulationMessageModel::callLayoutChanged()
 * \param logicalIndex
 * \param oldSize
 * \param newSize
 */
void SimulationOutputTree::callLayoutChanged(int logicalIndex, int oldSize, int newSize)
{
  Q_UNUSED(logicalIndex);
  Q_UNUSED(oldSize);
  Q_UNUSED(newSize);
  SimulationMessageModel *pSimulationMessageModel = qobject_cast<SimulationMessageModel*>(model());
  if (pSimulationMessageModel) {
    pSimulationMessageModel->callLayoutChanged();
  }
}

/*!
 * \brief SimulationOutputTree::selectAllMessages
 * Selects all the Messages.
 * Slot activated when mpSelectAllAction triggered signal is raised.
 */
void SimulationOutputTree::selectAllMessages()
{
  selectAll();
}

/*!
 * \brief compareSimulationMessageDeweyId
 * Compares the QModelIndexes based on their deweyid
 * \param index1
 * \param index2
 * \return
 */
bool compareSimulationMessageDeweyId(const QModelIndex &index1, const QModelIndex &index2)
{
  SimulationMessage *pSimulationMessage1 = static_cast<SimulationMessage*>(index1.internalPointer());
  SimulationMessage *pSimulationMessage2 = static_cast<SimulationMessage*>(index2.internalPointer());

  return pSimulationMessage1 && pSimulationMessage2 && pSimulationMessage1->mDeweyId < pSimulationMessage2->mDeweyId;
}

/*!
 * \brief SimulationOutputTree::copyMessages
 * Copy the selected Messages to the clipboard.
 * Slot activated when mpCopyAction triggered signal is raised.
 */
void SimulationOutputTree::copyMessages()
{
  SimulationMessageModel *pSimulationMessageModel = qobject_cast<SimulationMessageModel*>(model());
  if (pSimulationMessageModel) {
    QStringList textToCopy;
    QModelIndexList modelIndexes = selectionModel()->selectedRows();
    // sort the selected indexes based on deweyid so that we get the correct order since selectionModel()->selectedRows() changes the order.
    std::sort(modelIndexes.begin(), modelIndexes.end(), compareSimulationMessageDeweyId);
    foreach (QModelIndex modelIndex, modelIndexes) {
      SimulationMessage *pSimulationMessage = static_cast<SimulationMessage*>(modelIndex.internalPointer());
      if (pSimulationMessage) {
        /* Ticket:4778 Remove HTML formatting. */
//        textToCopy.append(QString("%1 | %2 | %3")
//                          .arg(pSimulationMessage->mStream)
//                          .arg(StringHandler::getSimulationMessageTypeString(pSimulationMessage->mType))
//                          .arg(pSimulationMessage->mText));
        textToCopy.append(QTextDocumentFragment::fromHtml(QString(pSimulationMessage->mText).remove("<p>").remove("</p>")).toPlainText());
      }
    }
    QApplication::clipboard()->setText(textToCopy.join("\n"));
  }
}

/*!
 * \brief SimulationOutputTree::keyPressEvent
 * Reimplementation of keypressevent.
 * Defines what to do for Ctrl+A, Ctrl+C and Del buttons.
 * \param event
 */
void SimulationOutputTree::keyPressEvent(QKeyEvent *event)
{
  bool controlModifier = event->modifiers().testFlag(Qt::ControlModifier);
  if (controlModifier && event->key() == Qt::Key_A) {
    selectAllMessages();
  } else if (controlModifier && event->key() == Qt::Key_C) {
    copyMessages();
  } else {
    QTreeView::keyPressEvent(event);
  }
}

/*!
 * \class SimulationOutputDialog
 * \brief Creates a dialog that shows the current simulation output.
 */
/*!
 * \brief SimulationOutputWidget::SimulationOutputWidget
 * \param simulationOptions
 * \param pParent
 */
SimulationOutputWidget::SimulationOutputWidget(SimulationOptions simulationOptions, QWidget *pParent)
  : QWidget(pParent), mSimulationOptions(simulationOptions)
{
  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setElideMode(Qt::ElideMiddle);
  mpCancelButton = new QPushButton(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelCompilationOrSimulation()));
  mpOpenTransformationalDebuggerButton = new QToolButton;
  mpOpenTransformationalDebuggerButton->setIcon(QIcon(":/Resources/icons/equational-debugger.svg"));
  mpOpenTransformationalDebuggerButton->setToolTip(tr("Open Transformational Debugger"));
  connect(mpOpenTransformationalDebuggerButton, SIGNAL(clicked()), SLOT(openTransformationalDebugger()));
  mpOpenOutputFileButton = new QPushButton(tr("Open Output File"));
  mpOpenOutputFileButton->setEnabled(false);
  connect(mpOpenOutputFileButton, SIGNAL(clicked()), SLOT(openSimulationLogFile()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setDocumentMode(true);
  mpGeneratedFilesTabWidget->setMovable(true);
  // Compilation Output TextBox
  mpCompilationOutputTextBox = new OutputPlainTextEdit;
  mpCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, tr("Compilation"));
  mSimulationStandardOutput.clear();
  mSimulationStandardError.clear();
  // Simulation output handler
  mpSimulationOutputHandler = 0;
  // Simulation Output TextBox
  if (OptionsDialog::instance()->getSimulationPage()->getOutputMode().compare(Helper::structuredOutput) == 0) {
    mIsOutputStructured = true;
    // simulation output browser
    mpSimulationOutputTextBrowser = 0;
    // simulation output tree
    mpSimulationOutputTree = new SimulationOutputTree(this);
    mpGeneratedFilesTabWidget->addTab(mpSimulationOutputTree, Helper::output);
  } else {
    mIsOutputStructured = false;
    // simulation output browser
    mpSimulationOutputTextBrowser = new QTextBrowser;
    mpSimulationOutputTextBrowser->setFont(QFont(Helper::monospacedFontInfo.family()));
    mpSimulationOutputTextBrowser->setOpenLinks(false);
    mpSimulationOutputTextBrowser->setOpenExternalLinks(false);
    connect(mpSimulationOutputTextBrowser, SIGNAL(anchorClicked(QUrl)), SLOT(openTransformationBrowser(QUrl)));
    // simulation output tree
    mpSimulationOutputTree = 0;
    mpGeneratedFilesTabWidget->addTab(mpSimulationOutputTextBrowser, Helper::output);
  }
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);
  mGeneratedFilesList << "%1.makefile";
  // cpp-runtime generated files
  if (simulationOptions.getTargetLanguage().compare("Cpp") == 0) {
    mGeneratedFilesList << "OMCpp%1.cpp"
                        << "OMCpp%1.h"
                        << "OMCpp%1.exp"
                        << "OMCpp%1.lib"
                        << "OMCpp%1AlgLoopMain.cpp"
                        << "OMCpp%1CalcHelperMain.cpp"
                        << "OMCpp%1CalcHelperMain.obj"
                        << "OMCpp%1CalcHelperMain.o"
                        << "OMCpp%1FactoryExport.cpp"
                        << "OMCpp%1Functions.cpp"
                        << "OMCpp%1Functions.h"
                        << "OMCpp%1Initialize.cpp"
                        << "OMCpp%1Initialize.h"
                        << "OMCpp%1Jacobian.cpp"
                        << "OMCpp%1Jacobian.h"
                        << "OMCpp%1Main.cpp"
                        << "OMCpp%1Main.obj"
                        << "OMCpp%1Mixed.cpp"
                        << "OMCpp%1Mixed.h"
                        << "OMCpp%1StateSelection.cpp"
                        << "OMCpp%1StateSelection.h"
                        << "OMCpp%1Types.h"
                        << "OMCpp%1WriteOutput.cpp"
                        << "OMCpp%1WriteOutput.h";

    mGeneratedAlgLoopFilesList << QString("OMCpp%1Algloop*.h").arg(simulationOptions.getOutputFileName())
                               << QString("OMCpp%1Algloop*.cpp").arg(simulationOptions.getOutputFileName());
  } else {
    // c-runtime generated files
    mGeneratedFilesList << "%1.c"
                        << "%1.o"
                        << "%1_01exo.c"
                        << "%1_01exo.o"
                        << "%1_02nls.c"
                        << "%1_02nls.o"
                        << "%1_03lsy.c"
                        << "%1_03lsy.o"
                        << "%1_04set.c"
                        << "%1_04set.o"
                        << "%1_05evt.c"
                        << "%1_05evt.o"
                        << "%1_06inz.c"
                        << "%1_06inz.o"
                        << "%1_07dly.c"
                        << "%1_07dly.o"
                        << "%1_08bnd.c"
                        << "%1_08bnd.o"
                        << "%1_09alg.c"
                        << "%1_09alg.o"
                        << "%1_10asr.c"
                        << "%1_10asr.o"
                        << "%1_11mix.c"
                        << "%1_11mix.o"
                        << "%1_11mix.h"
                        << "%1_12jac.c"
                        << "%1_12jac.o"
                        << "%1_12jac.h"
                        << "%1_13opt.c"
                        << "%1_13opt.o"
                        << "%1_13opt.h"
                        << "%1_14lnz.c"
                        << "%1_14lnz.o"
                        << "%1_15syn.c"
                        << "%1_15syn.o"
                        << "%1_16dae.c"
                        << "%1_16dae.o"
                        << "%1_16dae.h"
                        << "%1_17inl.c"
                        << "%1_17inl.o"
                        << "%1_18spd.c"
                        << "%1_18spd.o"
                        << "%1_functions.c"
                        << "%1_functions.o"
                        << "%1_functions.h"
                        << "%1_records.c"
                        << "%1_records.o"
                        << "%1_includes.h"
                        << "%1_literals.h"
                        << "%1_model.h";

    mGeneratedAlgLoopFilesList.clear();
  }
  if (mSimulationOptions.getShowGeneratedFiles()) {
    QString workingDirectory = mSimulationOptions.getWorkingDirectory();
    QString outputFile = mSimulationOptions.getOutputFileName();
    foreach (QString fileName, mGeneratedFilesList) {
      // filter *.o files and .makefile
      if (!fileName.endsWith(".o") && fileName.compare(".makefile") != 0) {
        addGeneratedFileTab(QString("%1/%2").arg(workingDirectory, QString(fileName).arg(outputFile)));
      }
    }
    // Delete the Algloop*.cpp/h files generated by cpp runtime
    if (mSimulationOptions.getTargetLanguage().compare("Cpp") == 0) {
      QStringList filesList = QDir(workingDirectory).entryList(mGeneratedAlgLoopFilesList, QDir::Files | QDir::NoSymLinks |
                                                               QDir::NoDotAndDotDot | QDir::Writable | QDir::CaseSensitive);
      foreach (QString fileName, filesList) {
        addGeneratedFileTab(QString("%1/%2").arg(workingDirectory, fileName));
      }
    }
    if (simulationOptions.getTargetLanguage().compare("C") == 0) {
      /* className_info.json tab */
      addGeneratedFileTab(QString("%1/%2%3").arg(workingDirectory, outputFile).arg("_info.json"));
    }
    /* className_init.xml tab */
    addGeneratedFileTab(QString("%1/%2%3").arg(workingDirectory, outputFile).arg("_init.xml"));
  }
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0);
  pMainLayout->addWidget(mpProgressBar, 0, 1);
  pMainLayout->addWidget(mpCancelButton, 0, 2);
  pMainLayout->addWidget(mpOpenTransformationalDebuggerButton, 0, 3);
  pMainLayout->addWidget(mpOpenOutputFileButton, 0, 4);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 1, 0, 1, 5);
  setLayout(pMainLayout);
  // create the ArchivedSimulationItem
  mpArchivedSimulationItem = new ArchivedSimulationItem(mSimulationOptions.getOutputFileName(), mSimulationOptions.getStartTime().toDouble(), mSimulationOptions.getStopTime().toDouble(), this);
  ArchivedSimulationsWidget::instance()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedSimulationItem);
  // start the tcp server
  mpTcpServer = new QTcpServer;
  mSocketState = SocketState::NotConnected;
  mpTcpServer->listen(QHostAddress(QHostAddress::LocalHost));
  connect(mpTcpServer, SIGNAL(newConnection()), SLOT(createSimulationProgressSocket()));
  mpCompilationProcess = 0;
  setCompilationProcessKilled(false);
  mIsCompilationProcessRunning = false;
  mpPostCompilationProcess = 0;
  setPostCompilationProcessKilled(false);
  mIsPostCompilationProcessRunning = false;
  mpSimulationProcess = 0;
  setSimulationProcessKilled(false);
  mIsSimulationProcessRunning = false;
}

/*!
 * \brief SimulationOutputWidget::~SimulationOutputWidget
 */
SimulationOutputWidget::~SimulationOutputWidget()
{
  // compilation process
  if (mpCompilationProcess && isCompilationProcessRunning()) {
    mpCompilationProcess->kill();
    mpCompilationProcess->deleteLater();
  }
  // post compilation process
  if (mpPostCompilationProcess && isPostCompilationProcessRunning()) {
    mpPostCompilationProcess->kill();
    mpPostCompilationProcess->deleteLater();
  }
  // simulation process
  if (mpSimulationProcess && isSimulationProcessRunning()) {
    mpSimulationProcess->kill();
    mpSimulationProcess->deleteLater();
  }
  /* Ticket:3788 comment:12 Delete the entire simulation folder. */
  if (OptionsDialog::instance()->getSimulationPage()->getDeleteEntireSimulationDirectoryCheckBox()->isChecked()) {
    Utilities::removeDirectoryRecursively(mSimulationOptions.getWorkingDirectory());
  }
  if (mpSimulationOutputHandler) {
    delete mpSimulationOutputHandler;
  }
  if (mpTcpServer) {
    mpTcpServer->deleteLater();
  }
}

/*!
 * \brief SimulationOutputWidget::start
 * Starts the compilation/simulation.
 */
void SimulationOutputWidget::start()
{
  if (!mSimulationOptions.isReSimulate()) {
    compileModel();
  } else {
    runSimulationExecutable();
  }
}

void SimulationOutputWidget::addGeneratedFileTab(QString fileName)
{
  QFile file(fileName);
  QFileInfo fileInfo(fileName);
  if (file.exists()) {
    file.open(QIODevice::ReadOnly);
    BaseEditor *pEditor;
    if (Utilities::isCFile(fileInfo.suffix())) {
      pEditor = new CEditor(MainWindow::instance());
      CHighlighter *pCHighlighter = new CHighlighter(OptionsDialog::instance()->getCEditorPage(), pEditor->getPlainTextEdit());
      Q_UNUSED(pCHighlighter);
    } else {
      pEditor = new TextEditor(MainWindow::instance());
    }
    pEditor->getPlainTextEdit()->setPlainText(QString(file.readAll()));
    mpGeneratedFilesTabWidget->addTab(pEditor, fileInfo.fileName());
    file.close();
  }
}

/*!
 * \brief SimulationOutputWidget::writeSimulationMessage
 * Writes the simulation output in a formatted text form.\n
 * \param type
 * \param text
 * \param index
 */
void SimulationOutputWidget::writeSimulationMessage(StringHandler::SimulationMessageType type, QString text, QString index)
{
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpSimulationOutputTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  /* set the text color */
  QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
  charFormat.setForeground(OptionsDialog::instance()->getMessagesPage()->getColor(type));
  mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
  /* append the output */
  /* write the error message */
  if (text.compare(Helper::displayLimit) == 0) {
    QString simulationLogFilePath = QString("%1/%2.log").arg(mSimulationOptions.getWorkingDirectory()).arg(mSimulationOptions.getOutputFileName());
    mpSimulationOutputTextBrowser->insertHtml(Helper::displayLimitMsg.arg(simulationLogFilePath));
  } else {
    mpSimulationOutputTextBrowser->insertPlainText(text);
  }
  /* write the error link */
  if (!index.isEmpty()) {
    mpSimulationOutputTextBrowser->insertHtml("&nbsp;<a href=\"omedittransformationsbrowser://" + QUrl::fromLocalFile(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getOutputFileName() + "_info.json").path() + "?index=" + index + "\">Debug more</a><br />");
  } else {
    mpSimulationOutputTextBrowser->insertPlainText("\n");
  }
}

/*!
 * \brief SimulationOutputWidget::embeddedServerInitialized
 * Calls a function for creating an OpcUaClient object.
 */
void SimulationOutputWidget::embeddedServerInitialized()
{
  QString errorString;
  if (!MainWindow::instance()->getSimulationDialog()->createOpcUaClient(mSimulationOptions, &errorString)) {
    writeSimulationOutput(errorString, StringHandler::Error, true);
  }
}

/*!
 * \brief SimulationOutputWidget::compileModel
 * Compiles the simulation model.
 */
void SimulationOutputWidget::compileModel()
{
  mpCompilationProcess = new QProcess;
  mpCompilationProcess->setWorkingDirectory(mSimulationOptions.getWorkingDirectory());
  connect(mpCompilationProcess, SIGNAL(started()), SLOT(compilationProcessStarted()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readCompilationStandardOutput()));
  connect(mpCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readCompilationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#else
  connect(mpCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(compilationProcessError(QProcess::ProcessError)));
#endif
  connect(mpCompilationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  QString numProcs, linkType("dynamic");
  if (mSimulationOptions.getNumberOfProcessors() == 0) {
    numProcs = QString::number(mSimulationOptions.getNumberOfProcessors());
  } else {
    numProcs = QString::number(mSimulationOptions.getNumberOfProcessors());
  }
  QStringList args;
#if defined(_WIN32)
  if (OptionsDialog::instance()->getSimulationPage()->getUseStaticLinkingCheckBox()->isChecked()) {
    linkType = "static";
  }
  SimulationPage *pSimulationPage = OptionsDialog::instance()->getSimulationPage();
  args << mSimulationOptions.getOutputFileName()
       << pSimulationPage->getTargetBuildComboBox()->itemData(pSimulationPage->getTargetBuildComboBox()->currentIndex()).toString()
       << System_openModelicaPlatform() << "parallel" << linkType << numProcs << "0";
  QString compilationProcessPath = QString(Helper::OpenModelicaHome) + "/share/omc/scripts/Compile.bat";
  writeCompilationOutput(QString("%1 %2\n").arg(compilationProcessPath).arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start(compilationProcessPath, args);
#else
  int numProcsInt = numProcs.toInt();
  if (numProcsInt > 1) {
    args << "-j" + numProcs;
  }
  args << "-f" << mSimulationOptions.getOutputFileName() + ".makefile";
#  if !defined(__FreeBSD__)
  writeCompilationOutput(QString("%1 %2\n").arg("make").arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start("make", args);
#  else
  writeCompilationOutput(QString("%1 %2\n").arg("gmake").arg(args.join(" ")), Qt::blue);
  mpCompilationProcess->start("gmake", args);
#  endif
#endif
}


/*!
 * \brief SimulationOutputWidget::runPostCompilation
 * Runs the post compilation command after the compilation of the model.
 */
void SimulationOutputWidget::runPostCompilation()
{
  const QString postCompilationCommand = OptionsDialog::instance()->getSimulationPage()->getPostCompilationCommand();
  if (postCompilationCommand.size()) {
    mpPostCompilationProcess = new QProcess;
    mpPostCompilationProcess->setWorkingDirectory(mSimulationOptions.getWorkingDirectory());
    connect(mpPostCompilationProcess, SIGNAL(started()), SLOT(postCompilationProcessStarted()));
    connect(mpPostCompilationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readPostCompilationStandardOutput()));
    connect(mpPostCompilationProcess, SIGNAL(readyReadStandardError()), SLOT(readPostCompilationStandardError()));
  #if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    connect(mpPostCompilationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
  #else
    connect(mpPostCompilationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(postCompilationProcessError(QProcess::ProcessError)));
  #endif
    connect(mpPostCompilationProcess, SIGNAL(finished(int, QProcess::ExitStatus)), SLOT(postCompilationProcessFinished(int, QProcess::ExitStatus)));
    writeCompilationOutput(QString("%1\n").arg(postCompilationCommand), Qt::blue);
  #if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
    QStringList args(QProcess::splitCommand(postCompilationCommand));
    const QString program(args.takeFirst());
    mpPostCompilationProcess->start(program, args);
  #else
    mpPostCompilationProcess->start(postCompilationCommand);
  #endif
  } else {
    // no post-compilation step, run directly the simulation
    if (!mSimulationOptions.getBuildOnly() && !mSimulationOptions.getLaunchAlgorithmicDebugger()) {
      runSimulationExecutable();
    }
  }
}

/*!
 * \brief SimulationOutputWidget::postCompilationProcessStarted
* Slot activated when mpPostCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void SimulationOutputWidget::postCompilationProcessStarted()
{
  mIsPostCompilationProcessRunning = true;
  const QString progressStr = tr("Post compiling %1.").arg(mSimulationOptions.getClassName());
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief SimulationOutputWidget::readPostCompilationStandardOutput
 * Slot activated when mpPostCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void SimulationOutputWidget::readPostCompilationStandardOutput()
{
  writeCompilationOutput(QString(mpPostCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief SimulationOutputWidget::readPostCompilationStandardError
 * Slot activated when mpPostCompilationProcess readyReadStandardError signal is raised.\n
 */
void SimulationOutputWidget::readPostCompilationStandardError()
{
  writeCompilationOutput(QString(mpPostCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief SimulationOutputWidget::postCompilationProcessError
 * Slot activated when mpPostCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void SimulationOutputWidget::postCompilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsPostCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isPostCompilationProcessKilled()) {
    return;
  }
  writeCompilationOutput(mpPostCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief SimulationOutputWidget::postCompilationProcessFinished
 * Slot activated when mpPostCompilationProcess finished signal is raised.\n
 * If the mpPostCompilationProcess finished normally then run the simulation executable.\n
 * \param exitCode
 * \param exitStatus
 */
void SimulationOutputWidget::postCompilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsPostCompilationProcessRunning = false;
  QString exitCodeStr = tr("Post compilation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeCompilationOutput(tr("Post compilation process finished successfully.\n"), Qt::blue);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
    // if not build only and launch the algorithmic debugger is false then run the simulation process.
    if (!mSimulationOptions.getBuildOnly() && !mSimulationOptions.getLaunchAlgorithmicDebugger()) {
      runSimulationExecutable();
    }
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writeCompilationOutput(exitCodeStr, Qt::red);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
  } else {
    writeCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    postCompilationProcessFinishedHelper(exitCode, exitStatus);
  }
}

void SimulationOutputWidget::postCompilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpProgressBar->setRange(0, 1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressBar->setValue(1);
    progressStr = tr("Post compilation of %1 finished.").arg(mSimulationOptions.getClassName());
  } else {
    mpProgressBar->setValue(0);
    progressStr = tr("Post compilation of %1 failed.").arg(mSimulationOptions.getClassName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief SimulationOutputWidget::updateMessageTab
 * Updates the corresponsing MessageTab.
 */
void SimulationOutputWidget::updateMessageTab(const QString &text)
{
  emit updateText(text);
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief SimulationOutputWidget::updateMessageTabProgress
 * Updates the progress bar of MessageTab
 */
void SimulationOutputWidget::updateMessageTabProgress()
{
  emit updateProgressBar(mpProgressBar);
}

/*!
 * \brief SimulationOutputWidget::runSimulationExecutable
 * Runs the simulation executable.
 */
void SimulationOutputWidget::runSimulationExecutable()
{
  mpSimulationProcess = new QProcess;
  /* Ticket:4583
   * Use the OMEdit working directory so users can put their input files there.
   */
//  mpSimulationProcess->setWorkingDirectory(simulationOptions.getWorkingDirectory());
  mpSimulationProcess->setWorkingDirectory(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory());
  connect(mpSimulationProcess, SIGNAL(started()), SLOT(simulationProcessStarted()));
  connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readSimulationStandardOutput()));
  connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readSimulationStandardError()));
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
  connect(mpSimulationProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)));
#else
  connect(mpSimulationProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(simulationProcessError(QProcess::ProcessError)));
#endif
  connect(mpSimulationProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  QStringList args(QString("-port=").append(QString::number(mpTcpServer->serverPort())));
  args << "-logFormat=xmltcp" << mSimulationOptions.getSimulationFlags();
  // start the executable
  QString fileName = QString(mSimulationOptions.getWorkingDirectory()).append("/").append(mSimulationOptions.getOutputFileName());
  fileName = fileName.replace("//", "/");
  // run the simulation executable to create the result file
#if defined(_WIN32)
  QString errorMsg;
  QProcessEnvironment processEnvironment = StringHandler::modelicaSimulationProcessEnvironment(fileName + ".bat", &errorMsg);
  if (!errorMsg.isEmpty()) {
    writeSimulationOutput(errorMsg, StringHandler::Error, true);
  }
  fileName = fileName.append(".exe");
  QFileInfo fileInfo(mSimulationOptions.getFileName());
  processEnvironment.insert("PATH", fileInfo.absoluteDir().absolutePath() + ";" + processEnvironment.value("PATH"));
  mpSimulationProcess->setProcessEnvironment(processEnvironment);
#endif
  // make the output tab enabled and current
  mpGeneratedFilesTabWidget->setTabEnabled(1, true);
  mpGeneratedFilesTabWidget->setCurrentIndex(1);
  writeSimulationOutput(QString("%1 %2").arg(fileName).arg(args.join(" ")), StringHandler::OMEditInfo, true);
  mpSimulationProcess->start(fileName, args);
}

/*!
 * \brief SimulationOutputWidget::writeCompilationOutput
 * Writes the compilation standard output to the compilation output text box.
 * \param output
 * \param color
 */
void SimulationOutputWidget::writeCompilationOutput(QString output, QColor color)
{
  QTextCharFormat format;
  format.setForeground(color);
  mpCompilationOutputTextBox->appendOutput(output, format);
}

void SimulationOutputWidget::compilationProcessFinishedHelper(int exitCode, QProcess::ExitStatus exitStatus)
{
  QString progressStr;
  mpProgressBar->setRange(0, 1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressBar->setValue(1);
    bool profiling = mSimulationOptions.getProfiling().compare(QStringLiteral("none")) != 0;
    if (mSimulationOptions.getBuildOnly() &&
        (OptionsDialog::instance()->getDebuggerPage()->getAlwaysShowTransformationsCheckBox()->isChecked() ||
         mSimulationOptions.getLaunchTransformationalDebugger() || profiling)) {
      MainWindow::instance()->showTransformationsWidget(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getOutputFileName() + "_info.json", profiling);
    }
    MainWindow::instance()->getSimulationDialog()->showAlgorithmicDebugger(mSimulationOptions);
    progressStr = tr("Compilation of %1 finished.").arg(mSimulationOptions.getClassName());
  } else {
    mpProgressBar->setValue(0);
    progressStr = tr("Compilation of %1 failed.").arg(mSimulationOptions.getClassName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
  mpArchivedSimulationItem->setStatus(Helper::finished);
  // remove the generated files
  if (mSimulationOptions.getBuildOnly()) {
    deleteIntermediateCompilationFiles();
  }
}

/*!
 * \brief SimulationOutputWidget::deleteIntermediateCompilationFiles
 * Deletes the intermediate compilation files
 */
void SimulationOutputWidget::deleteIntermediateCompilationFiles()
{
  if (OptionsDialog::instance()->getSimulationPage()->getDeleteIntermediateCompilationFilesCheckBox()->isChecked()) {
    QString workingDirectory = mSimulationOptions.getWorkingDirectory();
    QString outputFile = mSimulationOptions.getOutputFileName();
    foreach (QString fileName, mGeneratedFilesList) {
      if (QFile::exists(QString("%1/%2").arg(workingDirectory, QString(fileName).arg(outputFile)))) {
        QFile::remove(QString("%1/%2").arg(workingDirectory, QString(fileName).arg(outputFile)));
      }
    }
    // Delete the Algloop*.cpp/h files generated by cpp runtime
    if (mSimulationOptions.getTargetLanguage().compare("Cpp") == 0) {
      QStringList filesList = QDir(workingDirectory).entryList(mGeneratedAlgLoopFilesList, QDir::Files | QDir::NoSymLinks |
                                                               QDir::NoDotAndDotDot | QDir::Writable | QDir::CaseSensitive);
      foreach (QString fileName, filesList) {
        if (QFile::exists(QString("%1/%2").arg(workingDirectory, fileName))) {
          QFile::remove(QString("%1/%2").arg(workingDirectory, fileName));
        }
      }
    }
  }
}

/*!
 * \brief SimulationOutputWidget::writeSimulationOutput
 * Writes the simulation standard output to the simulation output text box.
 * \param output
 * \param type
 * \param textFormat
 */
void SimulationOutputWidget::writeSimulationOutput(QString output, StringHandler::SimulationMessageType type, bool textFormat)
{
  if (textFormat) {
    QString escaped = QString(output).toHtmlEscaped();
    output = QString("<message stream=\"stdout\" type=\"%1\" text=\"%2\" />")
        .arg(StringHandler::getSimulationMessageTypeString(type))
        .arg(escaped);
  }

  if (!mpSimulationOutputHandler) {
    mpSimulationOutputHandler = new SimulationOutputHandler(this, output);
    if (isOutputStructured()) {
      mpSimulationOutputTree->setModel(mpSimulationOutputHandler->getSimulationMessageModel());
    }
  } else {
    mpSimulationOutputHandler->parseSimulationOutput(output);
  }
}

/*!
 * \brief SimulationOutputWidget::simulationProcessFinishedHelper
 * Helper function for socketDisconnected and simulationProcessFinished
 */
void SimulationOutputWidget::simulationProcessFinishedHelper()
{
  /* We first read all the data from the socket and then read the stdout and stderr
   * Otherwise the mixed data is sent to the parser which leads to issues like issue #7245
   */
  if (!mSimulationStandardOutput.isEmpty()) {
    writeSimulationOutput(mSimulationStandardOutput, StringHandler::Unknown, true);
    mSimulationStandardOutput.clear();
  }
  if (!mSimulationStandardError.isEmpty()) {
    writeSimulationOutput(mSimulationStandardError, StringHandler::Error, true);
    mSimulationStandardError.clear();
  }

  int exitCode = mpSimulationProcess->exitCode();
  QProcess::ExitStatus exitStatus = mpSimulationProcess->exitStatus();
  QString exitCodeStr = tr("Simulation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  QString progressStr;
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    /* Ticket:4486
     * Don't print the success message since omc now outputs the success information.
     */
    //writeSimulationOutput(tr("Simulation process finished successfully."), StringHandler::OMEditInfo, true);
    progressStr = tr("Simulation of %1 finished.").arg(mSimulationOptions.getClassName());
  } else {
    if (mpSimulationOutputHandler) {
      SimulationMessage *pSimulationMessage;
      if (isOutputStructured()) {
        pSimulationMessage = new SimulationMessage(mpSimulationOutputHandler->getSimulationMessageModel()->getRootSimulationMessage());
      } else {
        pSimulationMessage = new SimulationMessage;
      }
      pSimulationMessage->mStream = "LOG_STDOUT";
      pSimulationMessage->mType = StringHandler::Error;
      pSimulationMessage->mLevel = 0;

      if (mpSimulationProcess->error() == QProcess::UnknownError) {
        pSimulationMessage->mText = exitCodeStr;
      } else {
        pSimulationMessage->mText = mpSimulationProcess->errorString() + "\n" + exitCodeStr;
      }

      mpSimulationOutputHandler->addSimulationMessage(pSimulationMessage);
    }
    progressStr = tr("Simulation of %1 failed.").arg(mSimulationOptions.getClassName());
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
  mpCancelButton->setEnabled(false);
  MainWindow::instance()->getSimulationDialog()->simulationProcessFinished(mSimulationOptions, mResultFileLastModifiedDateTime);
  mpArchivedSimulationItem->setStatus(Helper::finished);
  if (mpSimulationOutputHandler) {
    mpSimulationOutputHandler->simulationProcessFinished();
  }
  // remove the generated files
  if (!mSimulationOptions.getBuildOnly()) {
    deleteIntermediateCompilationFiles();
  }
  // this signal is used by testsuite to know that the simulation is finished.
  emit simulationFinished();
}

/*!
 * \brief SimulationOutputWidget::cancelCompilationOrSimulation
 * Slot activated when mpCancelButton clicked signal is raised.\n
 * Cancels a running compilaiton/simulation by killing the compilation/simulation process.
 */
void SimulationOutputWidget::cancelCompilationOrSimulation()
{
  QString progressStr;
  if (isCompilationProcessRunning()) {
    setCompilationProcessKilled(true);
    mpCompilationProcess->kill();
    mIsCompilationProcessRunning = false;
    progressStr = tr("Compilation of %1 is cancelled.").arg(mSimulationOptions.getClassName());
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
    mpArchivedSimulationItem->setStatus(Helper::finished);
  } else if (isPostCompilationProcessRunning()) {
    setPostCompilationProcessKilled(true);
    mpPostCompilationProcess->kill();
    mIsPostCompilationProcessRunning = false;
    progressStr = tr("Post compilation of %1 is cancelled.").arg(mSimulationOptions.getClassName());
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(0);
    mpCancelButton->setEnabled(false);
    mpArchivedSimulationItem->setStatus(Helper::finished);
  } else if (isSimulationProcessRunning()) {
    setSimulationProcessKilled(true);
    mpSimulationProcess->kill();
    mIsSimulationProcessRunning = false;
    progressStr = tr("Simulation of %1 is cancelled.").arg(mSimulationOptions.getClassName());
    mpCancelButton->setEnabled(false);
    mpArchivedSimulationItem->setStatus(Helper::finished);
  }
  mpProgressLabel->setText(progressStr);
  updateMessageTab(progressStr);
}

/*!
 * \brief SimulationOutputWidget::openTransformationalDebugger
 * Slot activated when mpOpenTransformationalDebuggerButton clicked SIGNAL is raised.\n
 * Opens the transformational debugger.
 */
void SimulationOutputWidget::openTransformationalDebugger()
{
  QString fileName = QString("%1/%2_info.json").arg(mSimulationOptions.getWorkingDirectory(), mSimulationOptions.getOutputFileName());
  /* open the model_info.json file */
  if (QFileInfo(fileName).exists()) {
    MainWindow::instance()->showTransformationsWidget(fileName, mSimulationOptions.getProfiling().compare(QStringLiteral("none")) != 0);
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName), QMessageBox::Ok);
  }
}

/*!
 * \brief SimulationOutputWidget::openSimulationLogFile
 * Slot activated when mpOpenOutputFileButton clicked SIGNAL is raised.\n
 * Opens the simulation log file.
 */
void SimulationOutputWidget::openSimulationLogFile()
{
  QUrl logFile (QString("file:///%1/%2.log").arg(mSimulationOptions.getWorkingDirectory(), mSimulationOptions.getOutputFileName()));
  if (!QDesktopServices::openUrl(logFile)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_OPEN_FILE).arg(logFile.toString()), QMessageBox::Ok);
  }
}

/*!
 * \brief SimulationOutputWidget::createSimulationProgressSocket
 * Slot activated when QTcpServer newConnection SIGNAL is raised.\n
 * Accepts the incoming connection and connects to readyRead SIGNAL of QTcpSocket.
 */
void SimulationOutputWidget::createSimulationProgressSocket()
{
  if (sender()) {
    QTcpServer *pTcpServer = qobject_cast<QTcpServer*>(const_cast<QObject*>(sender()));
    if (pTcpServer && pTcpServer->hasPendingConnections()) {
      QTcpSocket *pTcpSocket = pTcpServer->nextPendingConnection();
      mSocketState = SocketState::Connected;
      connect(pTcpSocket, SIGNAL(readyRead()), SLOT(readSimulationProgress()));
      connect(pTcpSocket, SIGNAL(disconnected()), SLOT(socketDisconnected()));
      connect(pTcpSocket, SIGNAL(disconnected()), pTcpSocket, SLOT(deleteLater()));
      disconnect(pTcpServer, SIGNAL(newConnection()), this, SLOT(createSimulationProgressSocket()));
    }
  }
}

/*!
 * \brief SimulationOutputWidget::readSimulationProgress
 * Slot activated when QTcpSocket readyRead SIGNAL is raised.\n
 * Sends the recieved data to xml parser.
 */
void SimulationOutputWidget::readSimulationProgress()
{
  if (sender()) {
    QTcpSocket *pTcpSocket = qobject_cast<QTcpSocket*>(const_cast<QObject*>(sender()));
    if (pTcpSocket) {
      QString output = QString(pTcpSocket->readAll());
      if (!output.isEmpty()) {
        writeSimulationOutput(output, StringHandler::Unknown, false);
      }
    }
  }
}

/*!
 * \brief SimulationOutputWidget::socketDisconnected
 * Slot activated when QTcpSocket disconnected SIGNAL is raised.\n
 */
void SimulationOutputWidget::socketDisconnected()
{
  mSocketState = SocketState::Disconnected;
  if (!mIsSimulationProcessRunning) {
    simulationProcessFinishedHelper();
  }
}

/*!
 * \brief SimulationOutputWidget::compilationProcessStarted
* Slot activated when mpCompilationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void SimulationOutputWidget::compilationProcessStarted()
{
  mIsCompilationProcessRunning = true;
  const QString progressStr = tr("Compiling %1. Please wait for a while.").arg(mSimulationOptions.getClassName());
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  updateMessageTab(progressStr);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
 * \brief SimulationOutputWidget::readCompilationStandardOutput
 * Slot activated when mpCompilationProcess readyReadStandardOutput signal is raised.\n
 */
void SimulationOutputWidget::readCompilationStandardOutput()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardOutput()), Qt::black);
}

/*!
 * \brief SimulationOutputWidget::readCompilationStandardError
 * Slot activated when mpCompilationProcess readyReadStandardError signal is raised.\n
 */
void SimulationOutputWidget::readCompilationStandardError()
{
  writeCompilationOutput(QString(mpCompilationProcess->readAllStandardError()), Qt::red);
}

/*!
 * \brief SimulationOutputWidget::compilationProcessError
 * Slot activated when mpCompilationProcess errorOccurred signal is raised.\n
 * \param error
 */
void SimulationOutputWidget::compilationProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  mIsCompilationProcessRunning = false;
  /* this signal is raised when we kill the compilation process forcefully. */
  if (isCompilationProcessKilled()) {
    return;
  }
  writeCompilationOutput(mpCompilationProcess->errorString(), Qt::red);
}

/*!
 * \brief SimulationOutputWidget::compilationProcessFinished
 * Slot activated when mpCompilationProcess finished signal is raised.\n
 * If the mpCompilationProcess finished normally then run the simulation executable.\n
 * Calls the Transformational Debugger or Algorithmic Debugger depending on the user selections.
 * \param exitCode
 * \param exitStatus
 */
void SimulationOutputWidget::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mIsCompilationProcessRunning = false;
  QString exitCodeStr = tr("Compilation process failed. Exited with code %1.").arg(Utilities::formatExitCode(exitCode));
  /* Issue #7862
   * Show instructions to select default MinGW compiler if compilation with MSVC compiler fails.
   */
  SimulationPage *pSimulationPage = OptionsDialog::instance()->getSimulationPage();
  QString targetBuild = pSimulationPage->getTargetBuildComboBox()->itemData(pSimulationPage->getTargetBuildComboBox()->currentIndex()).toString();
  if (targetBuild.startsWith("msvc")) {
    exitCodeStr.append("\nTry compiling with the default MinGW compiler. Select \"MinGW\" in \"Tools->Options->Simulation->Target Build\".");
  }
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    writeCompilationOutput(tr("Compilation process finished successfully.\n"), Qt::blue);
    compilationProcessFinishedHelper(exitCode, exitStatus);
    runPostCompilation();
  } else if (mpCompilationProcess->error() == QProcess::UnknownError) {
    writeCompilationOutput(exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  } else {
    writeCompilationOutput(mpCompilationProcess->errorString() + "\n" + exitCodeStr, Qt::red);
    compilationProcessFinishedHelper(exitCode, exitStatus);
  }
}

/*!
 * \brief SimulationOutputWidget::simulationProcessStarted
 * Slot activated when mpSimulationProcess started signal is raised.\n
 * Updates the progress label, bar and button controls.
 */
void SimulationOutputWidget::simulationProcessStarted()
{
  mIsSimulationProcessRunning = true;
  QString progressStr;
  if (mSimulationOptions.isInteractiveSimulation()) {
    progressStr = tr("Running interactive simulation of %1.").arg(mSimulationOptions.getClassName());
  } else {
    progressStr = tr("Running simulation of %1. Please wait for a while.").arg(mSimulationOptions.getClassName());
  }
  mpProgressLabel->setText(progressStr);
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setValue(0);
  mpProgressBar->setTextVisible(true);
  updateMessageTab(progressStr);
  mpCancelButton->setText(Helper::cancelSimulation);
  mpCancelButton->setEnabled(true);
  mpOpenOutputFileButton->setEnabled(true);
  // save the current datetime as last modified datetime for result file.
  mResultFileLastModifiedDateTime = QDateTime::currentDateTime();
  mpArchivedSimulationItem->setStatus(Helper::running);
}

/*!
 * \brief SimulationOutputWidget::readSimulationStandardOutput
 * Slot activated when mpSimulationProcess readyReadStandardOutput signal is raised.
 */
void SimulationOutputWidget::readSimulationStandardOutput()
{
  /* The remote embedded server does not currently disconnect connected clients when a simulation finishes.
   * This check hides the mazy network message of an open connection at shutdown.
   */
  QRegularExpression rx("info/network");
  QString stdOutput = mpSimulationProcess->readAllStandardOutput();
  if (!stdOutput.contains(rx)) {
    mSimulationStandardOutput.append(stdOutput);
  }
}

/*!
 * \brief SimulationOutputWidget::readSimulationStandardError
 * Slot activated when mpSimulationProcess readyReadStandardError signal is raised.
 */
void SimulationOutputWidget::readSimulationStandardError()
{
  mSimulationStandardError.append(mpSimulationProcess->readAllStandardError());
}

/*!
 * \brief SimulationOutputWidget::simulationProcessError
 * Slot activated when mpSimulationProcess errorOccurred signal is raised.
 * \param error
 */
void SimulationOutputWidget::simulationProcessError(QProcess::ProcessError error)
{
  mIsSimulationProcessRunning = false;
  /* this signal is raised when we kill the simulation process forcefully. */
  if (!isSimulationProcessKilled()) {
    writeSimulationOutput(mpSimulationProcess->errorString(), StringHandler::Error, true);
  }
  if (error == QProcess::FailedToStart) {
    simulationProcessFinished(0, QProcess::NormalExit);
  }
}

/*!
 * \brief SimulationOutputWidget::simulationProcessFinished
 * Slot activated when mpSimulationProcess finished signal is raised.\n
 * Reads the result variables, populates the variables browser and shows the plotting view.
 * \param exitCode
 * \param exitStatus
 */
void SimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  Q_UNUSED(exitStatus);
  mIsSimulationProcessRunning = false;
  // We are relying on QTcpSocket that it will always send disconnected() SIGNAL.
  if (mSocketState != SocketState::Connected) {
    simulationProcessFinishedHelper();
  }
  MainWindow::instance()->getSimulationDialog()->stopInteractiveSimulationSampling(mSimulationOptions);
}

/*!
 * \brief SimulationOutputWidget::openTransformationBrowser
 * Slot activated when a link is clicked from simulation output.\n
 * Parses the url and loads the TransformationsWidget with the used equation.
 * \param url - the url that is clicked
 */
/*
 * <a href="omedittransformationsbrowser://model_info.json?index=4></a>"
 */
void SimulationOutputWidget::openTransformationBrowser(QUrl url)
{
  if (url.scheme().compare("omedittransformationsbrowser") == 0) {
    /* read the file name */
    QString fileName = url.path();
#if defined(_WIN32)
    if (fileName.startsWith("/")) fileName.remove(0, 1);
#endif
    /* open the model_info.json file */
    if (QFileInfo(fileName).exists()) {
      TransformationsWidget *pTransformationsWidget = MainWindow::instance()->showTransformationsWidget(fileName, mSimulationOptions.getProfiling().compare(QStringLiteral("none")) != 0);
      QUrlQuery query(url);
      int equationIndex = query.queryItemValue("index").toInt();
      QTreeWidgetItem *pTreeWidgetItem = pTransformationsWidget->findEquationTreeItem(equationIndex);
      if (pTreeWidgetItem) {
        pTransformationsWidget->getEquationsTreeWidget()->clearSelection();
        pTransformationsWidget->getEquationsTreeWidget()->setCurrentItem(pTreeWidgetItem);
      }
      pTransformationsWidget->fetchEquationData(equationIndex);
    } else {
      QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), QString("%1<br />%2")
                            .arg(GUIMessages::getMessage(GUIMessages::FILE_NOT_FOUND).arg(fileName))
                            .arg(tr("Url is <b>%1</b>").arg(url.toString())), QMessageBox::Ok);
    }
  } else if (url.scheme().compare("file") == 0) {
    // we know that file link is always simulation log file.
    openSimulationLogFile();
  } else {
    /* TODO: Write error-message?! */
  }
}
