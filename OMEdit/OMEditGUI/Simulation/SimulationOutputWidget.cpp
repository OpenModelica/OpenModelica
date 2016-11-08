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
#include "VariablesWidget.h"
#include "CEditor.h"

/*!
  \class SimulationOutputTree
  \brief A tree based structure for simulation output messages.
  */
/*!
  \param pSimulationOutputWidget - a pointer to SimulationOutputWidget.
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
  Asks the model about the depth/level of QModelIndex.
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
  Shows a context menu when user right click on the Messages tree.
  Slot activated when SimulationOutputTree::customContextMenuRequested() signal is raised.
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
  Slot activated when QHeaderView sectionResized signal is raised.\n
  Tells the model to emit layoutChanged signal.\n
  \sa SimulationMessageModel::callLayoutChanged()
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
  Selects all the Messages.
  Slot activated when mpSelectAllAction triggered signal is raised.
  */
void SimulationOutputTree::selectAllMessages()
{
  selectAll();
}

/*!
  Copy the selected Messages to the clipboard.
  Slot activated when mpCopyAction triggered signal is raised.
  */
void SimulationOutputTree::copyMessages()
{
  SimulationMessageModel *pSimulationMessageModel = qobject_cast<SimulationMessageModel*>(model());
  if (pSimulationMessageModel) {
    QStringList textToCopy;
    const QModelIndexList modelIndexes = pSimulationMessageModel->selectedRows();
    foreach (QModelIndex modelIndex, modelIndexes) {
      SimulationMessage *pSimulationMessage = static_cast<SimulationMessage*>(modelIndex.internalPointer());
      if (pSimulationMessage) {
        textToCopy.append(QString("%1 | %2 | %3")
                          .arg(pSimulationMessage->mStream)
                          .arg(StringHandler::getSimulationMessageTypeString(pSimulationMessage->mType))
                          .arg(pSimulationMessage->mText));
      }
    }
    QApplication::clipboard()->setText(textToCopy.join("\n"));
  }
}

/*!
  Reimplementation of keypressevent.
  Defines what to do for Ctrl+A, Ctrl+C and Del buttons.
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
  \class SimulationOutputDialog
  \brief Creates a dialog that shows the current simulation output.
  */

/*!
  \param modelName - the name of the simulating model.
  \param pSimulationProcess - the simulation process.
  \param pParent - pointer to MainWindow.
  */
SimulationOutputWidget::SimulationOutputWidget(SimulationOptions simulationOptions, MainWindow *pMainWindow)
  : mSimulationOptions(simulationOptions), mpMainWindow(pMainWindow)
{
  setWindowTitle(QString("%1 - %2 %3").arg(Helper::applicationName).arg(mSimulationOptions.getClassName()).arg(Helper::simulationOutput));
  // progress label
  mpProgressLabel = new Label;
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpCancelButton = new QPushButton(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelCompilationOrSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // Generated Files tab widget
  mpGeneratedFilesTabWidget = new QTabWidget;
  mpGeneratedFilesTabWidget->setMovable(true);
  mpSimulationOutputHandler = 0;
  // Simulation Output TextBox
  if (mpMainWindow->getOptionsDialog()->getSimulationPage()->getOutputMode().compare(Helper::structuredOutput) == 0) {
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
  mpGeneratedFilesTabWidget->setTabEnabled(0, false);
  // Compilation Output TextBox
  mpCompilationOutputTextBox = new QPlainTextEdit;
  mpCompilationOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  mpGeneratedFilesTabWidget->addTab(mpCompilationOutputTextBox, tr("Compilation"));
  mpGeneratedFilesTabWidget->setTabEnabled(1, false);
  if (mSimulationOptions.getShowGeneratedFiles()) {
    QString workingDirectory = mSimulationOptions.getWorkingDirectory();
    QString outputFile = mSimulationOptions.getOutputFileName();
    /* className.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append(".c"));
    /* className_01exo.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_01exo.c"));
    /* className_02nls.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_02nls.c"));
    /* className_03lsy.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_03lsy.c"));
    /* className_04set.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_04set.c"));
    /* className_05evt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_05evt.c"));
    /* className_06inz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_06inz.c"));
    /* className_07dly.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_07dly.c"));
    /* className_08bnd.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_08bnd.c"));
    /* className_09alg.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_09alg.c"));
    /* className_10asr.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_10asr.c"));
    /* className_11mix.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.c"));
    /* className_11mix.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.h"));
    /* className_12jac.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.c"));
    /* className_12jac.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.h"));
    /* className_13opt.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_13opt.c"));
    /* className_14lnz.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_14lnz.c"));
    /* className_functions.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.c"));
    /* className_records.c tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_records.c"));
    /* className_11mix.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_11mix.h"));
    /* className_12jac.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_12jac.h"));
    /* className_13opt.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_13opt.h"));
    /* className_functions.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_functions.h"));
    /* className_includes.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_includes.h"));
    /* className_literals.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_literals.h"));
    /* className_model.h tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_model.h"));
    /* className_info.json tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_info.json"));
    /* className_init.xml tab */
    addGeneratedFileTab(QString(workingDirectory).append("/").append(outputFile).append("_init.xml"));
  }
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->addWidget(mpProgressLabel, 0, 0, 1, 2);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelButton, 1, 1);
  pMainLayout->addWidget(mpGeneratedFilesTabWidget, 2, 0, 1, 2);
  setLayout(pMainLayout);
  // create the ArchivedSimulationItem
  mpArchivedSimulationItem = new ArchivedSimulationItem(mSimulationOptions, this);
  mpMainWindow->getSimulationDialog()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedSimulationItem);
  // create the thread
  mpSimulationProcessThread = new SimulationProcessThread(this);
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationStarted()), SLOT(compilationProcessStarted()));
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationOutput(QString,QColor)), SLOT(writeCompilationOutput(QString,QColor)));
  connect(mpSimulationProcessThread, SIGNAL(sendCompilationFinished(int,QProcess::ExitStatus)),
          SLOT(compilationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationStarted()), SLOT(simulationProcessStarted()));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationOutput(QString,StringHandler::SimulationMessageType,bool)),
          SLOT(writeSimulationOutput(QString,StringHandler::SimulationMessageType,bool)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)),
          SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  connect(mpSimulationProcessThread, SIGNAL(sendSimulationProgress(int)), mpProgressBar, SLOT(setValue(int)));
  mpSimulationProcessThread->start();
}

SimulationOutputWidget::~SimulationOutputWidget()
{
  if (mpSimulationOutputHandler) {
    delete mpSimulationOutputHandler;
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
      pEditor = new CEditor(mpMainWindow);
      CHighlighter *pCHighlighter = new CHighlighter(mpMainWindow->getOptionsDialog()->getCEditorPage(), pEditor->getPlainTextEdit());
      Q_UNUSED(pCHighlighter);
    } else {
      pEditor = new TextEditor(mpMainWindow);
    }
    pEditor->getPlainTextEdit()->setPlainText(QString(file.readAll()));
    mpGeneratedFilesTabWidget->addTab(pEditor, fileInfo.fileName());
    file.close();
  }
}

/*!
  Writes the simulation output in a formatted text form.\n
  \param - pSimulationMessage - the simulation output message.
  */
void SimulationOutputWidget::writeSimulationMessage(SimulationMessage *pSimulationMessage)
{
  static QString lastSream;
  static QString lastType;
  /* format the error message */
  QString type = StringHandler::getSimulationMessageTypeString(pSimulationMessage->mType);
  QString error = ((lastSream == pSimulationMessage->mStream && pSimulationMessage->mLevel > 0) ? "|" : pSimulationMessage->mStream) + "\t\t| ";
  error += ((lastSream == pSimulationMessage->mStream && lastType == type && pSimulationMessage->mLevel > 0) ? "|" : type) + "\t | ";
  for (int i = 0 ; i < pSimulationMessage->mLevel ; ++i)
    error += "| ";
  error += pSimulationMessage->mText;
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpSimulationOutputTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  /* set the text color */
  QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
  charFormat.setForeground(StringHandler::getSimulationMessageTypeColor(pSimulationMessage->mType));
  mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
  /* append the output */
  /* write the error message */
  mpSimulationOutputTextBrowser->insertPlainText(error);
  /* write the error link */
  if (!pSimulationMessage->mIndex.isEmpty()) {
    mpSimulationOutputTextBrowser->insertHtml("&nbsp;<a href=\"omedittransformationsbrowser://" + QUrl::fromLocalFile(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getFileNamePrefix() + "_info.json").path() + "?index=" + pSimulationMessage->mIndex + "\">Debug more</a><br />");
  } else {
    mpSimulationOutputTextBrowser->insertPlainText("\n");
  }
  /* save the current stream & type as last */
  lastSream = pSimulationMessage->mStream;
  lastType = type;
  /* write the child messages */
  foreach (SimulationMessage* pSimulationMessage, pSimulationMessage->mChildren) {
    writeSimulationMessage(pSimulationMessage);
  }
}

/*!
  Slot activated when SimulationProcessThread sendCompilationStarted signal is raised.\n
  Updates the progress label, bar and button controls.
  */
void SimulationOutputWidget::compilationProcessStarted()
{
  mpProgressLabel->setText(tr("Compiling <b>%1</b>. Please wait for a while.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(false);
  mpCancelButton->setText(tr("Cancel Compilation"));
  mpCancelButton->setEnabled(true);
}

/*!
  Slot activated when SimulationProcessThread sendCompilationStandardOutput signal is raised.\n
  Writes the compilation standard output to the compilation output text box.
  */
void SimulationOutputWidget::writeCompilationOutput(QString output, QColor color)
{
  mpGeneratedFilesTabWidget->setTabEnabled(1, true);
  QTextCharFormat format;
  format.setForeground(color);
  Utilities::insertText(mpCompilationOutputTextBox, output, format);
  /* make the compilation tab the current one */
  mpGeneratedFilesTabWidget->setCurrentIndex(1);
}

/*!
  Slot activated when SimulationProcessThread sendCompilationFinished signal is raised.\n
  Calls the Transformational Debugger or Algorithmic Debugger depending on the user selections.
  */
void SimulationOutputWidget::compilationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  mpProgressLabel->setText(tr("Compilation of <b>%1</b> is finished.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 1);
  mpProgressBar->setValue(1);
  mpCancelButton->setEnabled(false);
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    if (mpMainWindow->getOptionsDialog()->getDebuggerPage()->getAlwaysShowTransformationsCheckBox()->isChecked() ||
        mSimulationOptions.getLaunchTransformationalDebugger() || mSimulationOptions.getProfiling() != "none") {
      mpMainWindow->showTransformationsWidget(mSimulationOptions.getWorkingDirectory() + "/" + mSimulationOptions.getOutputFileName() + "_info.json");
    }
    mpMainWindow->getSimulationDialog()->showAlgorithmicDebugger(mSimulationOptions);
  }
  mpArchivedSimulationItem->setStatus(Helper::finished);
}

/*!
  Slot activated when SimulationProcessThread sendSimulationStarted signal is raised.\n
  Updates the progress label, bar and button controls.
  */
void SimulationOutputWidget::simulationProcessStarted()
{
  mpProgressLabel->setText(tr("Running simulation of <b>%1</b>. Please wait for a while.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  mpCancelButton->setText(Helper::cancelSimulation);
  mpCancelButton->setEnabled(true);
  // save the last modified datetime of result file.
  QFileInfo resultFileInfo(QString(mSimulationOptions.getWorkingDirectory()).append("/").append(mSimulationOptions.getResultFileName()));
  if (resultFileInfo.exists()) {
    mResultFileLastModifiedDateTime = resultFileInfo.lastModified();
  }
  mpArchivedSimulationItem->setStatus(Helper::running);
}

/*!
  Slot activated when SimulationProcessThread sendSimulationOutput signal is raised.\n
  Writes the simulation standard output to the simulation output text box.
  */
void SimulationOutputWidget::writeSimulationOutput(QString output, StringHandler::SimulationMessageType type, bool textFormat)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  QString escaped = QString(output).toHtmlEscaped();
#else /* Qt4 */
  QString escaped = Qt::escape(output);
#endif

  mpGeneratedFilesTabWidget->setTabEnabled(0, true);
  if (isOutputStructured()) {
    if (textFormat) {
      output = QString("<message stream=\"stdout\" type=\"%1\" text=\"%2\" />")
          .arg(StringHandler::getSimulationMessageTypeString(type))
          .arg(escaped);
    }
    if (!mpSimulationOutputHandler) {
      mpSimulationOutputHandler = new SimulationOutputHandler(this, output);
      mpSimulationOutputTree->setModel(mpSimulationOutputHandler->getSimulationMessageModel());
    } else {
      mpSimulationOutputHandler->parseSimulationOutput(output);
    }
  } else {
    /* move the cursor down before adding to the logger. */
    QTextCursor textCursor = mpSimulationOutputTextBrowser->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpSimulationOutputTextBrowser->setTextCursor(textCursor);
    /* set the text color */
    QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
    charFormat.setForeground(StringHandler::getSimulationMessageTypeColor(type));
    mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
    /* append the output */
    if (textFormat) {
      mpSimulationOutputTextBrowser->insertPlainText(output + "\n");
    } else if (!mpSimulationOutputHandler) {
      mpSimulationOutputHandler = new SimulationOutputHandler(this, output);
    } else {
      mpSimulationOutputHandler->parseSimulationOutput(output);
    }
    /* move the cursor */
    textCursor.movePosition(QTextCursor::End);
    mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  }
  /* make the compilation tab the current one */
  mpGeneratedFilesTabWidget->setCurrentIndex(0);
}

/*!
  Slot activated when SimulationProcessThread sendSimulationFinished signal is raised.\n
  Reads the result variables, populates the variables browser and shows the plotting view.
  */
void SimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  Q_UNUSED(exitStatus);
  mpProgressLabel->setText(tr("Simulation of <b>%1</b> is finished.").arg(mSimulationOptions.getClassName()));
  mpProgressBar->setValue(mpProgressBar->maximum());
  mpCancelButton->setEnabled(false);
  mpMainWindow->getSimulationDialog()->simulationProcessFinished(mSimulationOptions, mResultFileLastModifiedDateTime);
  mpArchivedSimulationItem->setStatus(Helper::finished);
}

/*!
  Slot activated when mpCancelButton clicked signal is raised.\n
  Cancels a running compilaiton/simulation by killing the compilation/simulation process.
  */
void SimulationOutputWidget::cancelCompilationOrSimulation()
{
  if (mpSimulationProcessThread->isCompilationProcessRunning()) {
    mpSimulationProcessThread->getCompilationProcess()->kill();
    mpProgressLabel->setText(tr("Compilation of <b>%1</b> is cancelled.").arg(mSimulationOptions.getClassName()));
    mpProgressBar->setRange(0, 1);
    mpProgressBar->setValue(1);
    mpCancelButton->setEnabled(false);
    mpArchivedSimulationItem->setStatus(Helper::finished);
  } else if (mpSimulationProcessThread->isSimulationProcessRunning()) {
    mpSimulationProcessThread->getSimulationProcess()->kill();
    mpProgressLabel->setText(tr("Simulation of <b>%1</b> is cancelled.").arg(mSimulationOptions.getClassName()));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mpCancelButton->setEnabled(false);
    mpArchivedSimulationItem->setStatus(Helper::finished);
  }
}

/*!
  Slot activated when a link is clicked from simulation output.\n
  Parses the url and loads the TransformationsWidget with the used equation.
  \param url - the url that is clicked
  */
/*
  <a href="omedittransformationsbrowser://model_info.json?index=4></a>"
  */
void SimulationOutputWidget::openTransformationBrowser(QUrl url)
{
  /* read the file name */
  if (url.scheme() != "omedittransformationsbrowser") {
    /* TODO: Write error-message?! */
    return;
  }
  QString fileName = url.path();
#ifdef WIN32
  if (fileName.startsWith("/")) fileName.remove(0, 1);
#endif
  /* open the model_info.json file */
  if (QFileInfo(fileName).exists()) {
    TransformationsWidget *pTransformationsWidget = mpMainWindow->showTransformationsWidget(fileName);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
    QUrlQuery query(url);
    int equationIndex = query.queryItemValue("index").toInt();
#else /* Qt4 */
    int equationIndex = url.queryItemValue("index").toInt();
#endif
    QTreeWidgetItem *pTreeWidgetItem = pTransformationsWidget->findEquationTreeItem(equationIndex);
    if (pTreeWidgetItem) {
      pTransformationsWidget->getEquationsTreeWidget()->clearSelection();
      pTransformationsWidget->getEquationsTreeWidget()->setCurrentItem(pTreeWidgetItem);
    }
    pTransformationsWidget->fetchEquationData(equationIndex);
  } else {
    /* TODO: Display error-message */
  }
}
