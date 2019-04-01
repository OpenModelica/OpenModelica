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

#include "Debugger/GDB/GDBAdapter.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "Debugger/StackFrames/StackFramesWidget.h"
#include "Debugger/Locals/LocalsWidget.h"
#include "Debugger/GDB/CommandFactory.h"
#include "Debugger/Locals/ModelicaValue.h"
#include "Simulation/SimulationOutputWidget.h"
#include "Simulation/SimulationDialog.h"

#include <QDockWidget>
#include <QMessageBox>

/*!
 * \class GDBLoggerWidget
 * \brief Console for viewing GDB response & sending user commands to GDB.
 */
/*!
 * \brief GDBLoggerWidget::GDBLoggerWidget
 * \param pParent
 */
GDBLoggerWidget::GDBLoggerWidget(QWidget *pParent)
  : QWidget(pParent)
{
  /* GDB commands area */
  mpCommandsTextBox = new QPlainTextEdit;
  mpCommandsTextBox->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  mpCommandsTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  /* GDB commands area */
  mpResponseTextBox = new QPlainTextEdit;
  mpResponseTextBox->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  mpResponseTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  /* user command text box */
  mpCommandTextBox = new QLineEdit;
  mpCommandTextBox->setEnabled(false);
  mpCommandTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  connect(mpCommandTextBox, SIGNAL(returnPressed()), SLOT(postCommand()));
  /* send command button */
  mpSendCommandButton = new QPushButton(tr("Send"));
  mpSendCommandButton->setEnabled(false);
  connect(mpSendCommandButton, SIGNAL(clicked()), SLOT(postCommand()));
  /* Log Windows Splitter */
  QSplitter *pLogWindowsSplitter = new QSplitter;
  pLogWindowsSplitter->setChildrenCollapsible(false);
  pLogWindowsSplitter->setHandleWidth(4);
  pLogWindowsSplitter->setContentsMargins(0, 0, 0, 0);
  pLogWindowsSplitter->addWidget(mpCommandsTextBox);
  pLogWindowsSplitter->addWidget(mpResponseTextBox);
  pLogWindowsSplitter->setStretchFactor(0, 0);
  pLogWindowsSplitter->setStretchFactor(1, 1);
  /* layout */
  QGridLayout *pGridLayout = new QGridLayout;
  pGridLayout->setAlignment(Qt::AlignLeft);
  pGridLayout->setContentsMargins(1, 1, 1, 1);
  pGridLayout->addWidget(pLogWindowsSplitter, 0, 0, 1, 2);
  pGridLayout->addWidget(mpCommandTextBox, 1, 0);
  pGridLayout->addWidget(mpSendCommandButton, 1, 1);
  setLayout(pGridLayout);
  connect(GDBAdapter::instance(), SIGNAL(GDBProcessStarted()), SLOT(handleGDBProcessStarted()));
  connect(GDBAdapter::instance(), SIGNAL(GDBProcessFinished()), SLOT(handleGDBProcessFinished()));
}

/*!
 * \brief GDBLoggerWidget::logDebuggerCommand
 * Writes Debugger command in Debugger Logger window.
 * \param command
 */
void GDBLoggerWidget::logDebuggerCommand(QString command)
{
  Utilities::insertText(mpCommandsTextBox, command + "\n\n");
}

/*!
 * \brief GDBLoggerWidget::logDebuggerStandardResponse
 * Writes Debugger standard response in Debugger Logger window.
 * \param response
 */
void GDBLoggerWidget::logDebuggerStandardResponse(QString response)
{
  logDebuggerResponse(response, Qt::black);
}

/*!
 * \brief GDBLoggerWidget::logDebuggerErrorResponse
 * Writes Debugger error response in Debugger Logger window.
 * \param response
 */
void GDBLoggerWidget::logDebuggerErrorResponse(QString response)
{
  logDebuggerResponse(response, Qt::red);
}

/*!
 * \brief GDBLoggerWidget::logDebuggerResponse
 * Writes Debugger response in Debugger Logger window.
 * \param response
 * \param color
 */
void GDBLoggerWidget::logDebuggerResponse(QString response, QColor color)
{
  QString newLine = response.endsWith("\n") ? "\n" : "\n\n";
  QTextCharFormat format;
  format.setForeground(color);
  Utilities::insertText(mpResponseTextBox, response + newLine, format);
}

/*!
 * \brief GDBLoggerWidget::postCommand
 * Posts the user typed GDB command.
 */
void GDBLoggerWidget::postCommand()
{
  if (mpCommandTextBox->text().isEmpty()) {
    return;
  }
  GDBAdapter::instance()->postCommand(QByteArray(mpCommandTextBox->text().toStdString().c_str()));
}

/*!
 * \brief GDBLoggerWidget::handleGDBProcessStarted
 * Slot activated when GDBProcessStarted signal of GDBAdapter is raised.
 * Clears the GDB response text box area. Allows to send commands.
 */
void GDBLoggerWidget::handleGDBProcessStarted()
{
  /* if clear log on new run option is set then clear the log windows. */
  DebuggerPage *pDebuggerPage = OptionsDialog::instance()->getDebuggerPage();
  if (pDebuggerPage->getClearLogOnNewRunCheckBox()->isChecked()) {
    mpCommandsTextBox->clear();
    mpResponseTextBox->clear();
  }
  mpCommandTextBox->setEnabled(true);
  mpSendCommandButton->setEnabled(true);
}

/*!
 * \brief GDBLoggerWidget::handleGDBProcessFinished
 * Slot activated when GDBProcessFinished signal of GDBAdapter is raised.
 * Disables the user commands.
 */
void GDBLoggerWidget::handleGDBProcessFinished()
{
  mpCommandTextBox->setEnabled(false);
  mpSendCommandButton->setEnabled(false);
}

/*!
 * \class TargetOutputWidget
 * \brief Console for viewing GDB inferior output.
 */
/*!
 * \brief TargetOutputWidget::TargetOutputWidget
 * \param pParent
 */
TargetOutputWidget::TargetOutputWidget(QWidget *pParent)
  : QPlainTextEdit(pParent)
{
  setFont(QFont(Helper::monospacedFontInfo.family()));
  connect(GDBAdapter::instance(), SIGNAL(GDBProcessStarted()), SLOT(handleGDBProcessStarted()));
}

/*!
 * \brief TargetOutputWidget::logDebuggerStandardOutput
 * Writes Debugger standard response in Output Browser window.
 * \param output
 */
void TargetOutputWidget::logDebuggerStandardOutput(QString output)
{
  logDebuggerOutput(output, Qt::black);
}

/*!
 * \brief TargetOutputWidget::logDebuggerErrorOutput
 * Writes Debugger error response in Output Browser window.
 * \param output
 */
void TargetOutputWidget::logDebuggerErrorOutput(QString output)
{
  logDebuggerOutput(output, Qt::red);
}

/*!
 * \brief TargetOutputWidget::logDebuggerOutput
 * Writes Debugger response in Output Browser window.
 * \param output
 * \param color
 */
void TargetOutputWidget::logDebuggerOutput(QString output, QColor color)
{
  MainWindow::instance()->getTargetOutputDockWidget()->show();
  QList<QDockWidget*> tabifiedDockWidgetsList = MainWindow::instance()->tabifiedDockWidgets(MainWindow::instance()->getTargetOutputDockWidget());
  if (tabifiedDockWidgetsList.size() > 0) {
    MainWindow::instance()->tabifyDockWidget(tabifiedDockWidgetsList.at(0), MainWindow::instance()->getTargetOutputDockWidget());
  }
  // log the output
  QString newLine = output.endsWith("\n") ? "" : "\n";
  QTextCharFormat format;
  format.setForeground(color);
  Utilities::insertText(this, output + newLine, format);
}

/*!
 * \brief TargetOutputWidget::handleGDBProcessStarted
 * Slot activated when GDBProcessStarted signal of GDBAdapter is raised.
 * Clears the GDB output text box area. Allows to send commands.
 */
void TargetOutputWidget::handleGDBProcessStarted()
{
  /* if clear output on new run option is set then clear the log windows. */
  DebuggerPage *pDebuggerPage = OptionsDialog::instance()->getDebuggerPage();
  if (pDebuggerPage->getClearOutputOnNewRunCheckBox()->isChecked()) {
    clear();
  }
}

/*!
 * \class GDBAdapter
 * \brief Interface for communication with GDB.
 */

GDBAdapter *GDBAdapter::mpInstance = 0;

/*!
 * \brief MessagesWidget::create
 */
void GDBAdapter::create()
{
  if (!mpInstance) {
    mpInstance = new GDBAdapter;
  }
}

/*!
 * \brief GDBAdapter::destroy
 */
void GDBAdapter::destroy()
{
  mpInstance->deleteLater();
}

/*!
 * \brief GDBAdapter::GDBAdapter
 * \param pParent
 */
GDBAdapter::GDBAdapter(QWidget *pParent)
  : QObject(pParent)
{
  setExecuteCommand(GDBAdapter::ExecNext);
  mAttachToProcessId = "0";
  mIsRunning = false;
  mIsParsingStandardOutput = false;
  mIsInferiorSuspended = false;
  mIsInferiorTerminated = false;
  mIsInferiorRunning = false;
  mToken = 0;
  mCatchOMCBreakpointId = "1";
  mGDBCommandTimer.setSingleShot(true);
  connect(&mGDBCommandTimer, SIGNAL(timeout()), SLOT(GDBcommandTimeout()));
}

/*!
 * \brief GDBAdapter::launch
 * Launches the GDB with the default arguments.
 * \param program - the program to debug with GDB.
 * \param workingDirectory - working directory for GDB.
 * \param arguments - program arguments
 * \param GDBPath - GDB location.
 * \param simulationOptions
 */
void GDBAdapter::launch(QString program, QString workingDirectory, QStringList arguments, QString GDBPath, SimulationOptions simulationOptions)
{
  // check if the inferior exists
  if (!QFile::exists(program)) {
    MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(tr("The executable to debug does not exist: %1").arg(program));
    return;
  }
  mpGDBProcess = new QProcess;
  setGDBKilled(false);
#ifdef WIN32
  /* Set the environment for GDB process */
  QProcessEnvironment processEnvironment = StringHandler::simulationProcessEnvironment();
  if (!simulationOptions.getFileName().isEmpty()) {
    QFileInfo fileInfo(simulationOptions.getFileName());
    processEnvironment.insert("PATH", fileInfo.absoluteDir().absolutePath() + ";" + processEnvironment.value("PATH"));
  }
  mpGDBProcess->setProcessEnvironment(processEnvironment);
#endif
  mpGDBProcess->setWorkingDirectory(workingDirectory);
  connect(mpGDBProcess, SIGNAL(started()), SLOT(handleGDBProcessStarted()));
  connect(mpGDBProcess, SIGNAL(readyReadStandardOutput()), SLOT(readGDBStandardOutput()));
  connect(mpGDBProcess, SIGNAL(readyReadStandardError()), SLOT(readGDBErrorOutput()));
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0))
  connect(mpGDBProcess, SIGNAL(errorOccurred(QProcess::ProcessError)), SLOT(handleGDBProcessError(QProcess::ProcessError)));
#else
  connect(mpGDBProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(handleGDBProcessError(QProcess::ProcessError)));
#endif
  connect(mpGDBProcess, SIGNAL(finished(int)), SLOT(handleGDBProcessFinished(int)));
  connect(mpGDBProcess, SIGNAL(finished(int)), mpGDBProcess, SLOT(deleteLater()));
  mSimulationOptions = simulationOptions;
  if (mSimulationOptions.isValid()) {
    connect(mpGDBProcess, SIGNAL(started()), SLOT(handleGDBProcessStartedForSimulation()));
    connect(mpGDBProcess, SIGNAL(finished(int)), SLOT(handleGDBProcessFinishedForSimulation(int)));
  }
  /* launch gdb with the default arguments
   * -q  quiet mode. Don't print welcome messages
   * -nw don't use window interface
   * -i  select interface
   * mi  machine interface
   */
  mGDBProgram = GDBPath;
  mGDBArguments.clear();
  mInferiorArguments.clear();
  mGDBArguments << "-q" << "-nw" << "-i" << "mi" << "--args" << program;
  mInferiorArguments = arguments;
  mpGDBProcess->start(mGDBProgram, mGDBArguments);
}

/*!
 * \brief GDBAdapter::launch
 * Launches the GDB and attachs it to the processID.
 * \param processID - process ID to attach.
 * \param GDBPath - GDB location.
 */
void GDBAdapter::launch(QString processId, QString GDBPath)
{
  mAttachToProcessId = processId;
  mpGDBProcess = new QProcess;
  setGDBKilled(false);
#ifdef WIN32
  /* Set the environment for GDB process */
  mpGDBProcess->setProcessEnvironment(StringHandler::simulationProcessEnvironment());
#endif
  connect(mpGDBProcess, SIGNAL(started()), SLOT(handleGDBProcessStartedForAttach()));
  connect(mpGDBProcess, SIGNAL(readyReadStandardOutput()), SLOT(readGDBStandardOutput()));
  connect(mpGDBProcess, SIGNAL(readyReadStandardError()), SLOT(readGDBErrorOutput()));
  connect(mpGDBProcess, SIGNAL(error(QProcess::ProcessError)), SLOT(handleGDBProcessError(QProcess::ProcessError)));
  connect(mpGDBProcess, SIGNAL(finished(int)), SLOT(handleGDBProcessFinished(int)));
  connect(mpGDBProcess, SIGNAL(finished(int)), mpGDBProcess, SLOT(deleteLater()));
  /*
    launch gdb with the default arguments
    -q  quiet mode. Don't print welcome messages
    -nw don't use window interface
    -i  select interface
    mi  machine interface
    */
  mGDBProgram = GDBPath;
  mGDBArguments.clear();
  mInferiorArguments.clear();
  mGDBArguments << "-q" << "-nw" << "-i" << "mi";
  mpGDBProcess->start(mGDBProgram, mGDBArguments);
}

/*!
 * \brief GDBAdapter::postCommand
 * Sends a command to GDB.
 * \param command - the command to send.
 * \param callback - the command to callback function.
 */
void GDBAdapter::postCommand(QByteArray command, GDBCommandCallback callback)
{
  postCommand(command, GDBAdapter::NoFlags, 0, callback);
}

/*!
 * \brief GDBAdapter::postCommand
 * Sends a command to GDB.
 * \param command - the command to send.
 * \param pCallbackObject - the QObject pointer which is used to call the callback function.
 * \param callback - the command to callback function.
 */
void GDBAdapter::postCommand(QByteArray command, QObject *pCallbackObject, GDBCommandCallback callback)
{
  postCommand(command, GDBAdapter::NoFlags, pCallbackObject, callback);
}

/*!
 * \brief GDBAdapter::postCommand
 * Sends a command to GDB.
 * \param command - the command to send.
 * \param flags - the command flags.
 * \param callback - the command to callback function.
 */
void GDBAdapter::postCommand(QByteArray command, GDBCommandFlags flags, GDBCommandCallback callback)
{
  postCommand(command, flags, 0, callback);
}

/*!
 * \brief GDBAdapter::postCommand
 * Sends a command to GDB.
 * \param command - the command to send.
 * \param flags - the command flags.
 * \param pCallbackObject - the QObject pointer which is used to call the callback function.
 * \param callback - the command to callback function.
 */
void GDBAdapter::postCommand(QByteArray command, GDBCommandFlags flags, QObject *pCallbackObject, GDBCommandCallback callback)
{
  if (isGDBRunning()) {
    int token = currentToken() + 1;
    setCurrentToken(token);
    GDBMICommand cmd;
    cmd.mFlags = flags;
    cmd.mCommand = command;
    cmd.mpCallbackObject = pCallbackObject;
    cmd.mGDBCommandCallback = callback;
    if (cmd.mFlags & GDBAdapter::ConsoleCommand) {
      cmd.mCommand = "-interpreter-exec console \"" + cmd.mCommand + '"';
    }
    cmd.mCommand = QByteArray::number(token) + cmd.mCommand;
    mGDBMICommandsHash[token] = cmd;
    // log command
    writeDebuggerCommandLog(cmd.mCommand);
    MainWindow::instance()->getGDBLoggerWidget()->logDebuggerCommand(QString(cmd.mCommand));
    /* if command needs a response
     * block until response is arrived
     */
    if (cmd.mFlags & GDBAdapter::BlockUntilResponse) {
      QEventLoop eventLoop;
      QTimer timer;
      connect(&timer, SIGNAL(timeout()), &eventLoop, SLOT(quit()));
      connect(this, SIGNAL(commandCompleted()), &eventLoop, SLOT(quit()));
      /* Just in case command response doesn't arrive for some reason we don't want to stay in blocked state.
       * So we start a timer which will quit the event loop after 5 secs.
       */
      timer.start(5000);
      mpGDBProcess->write(cmd.mCommand + "\r\n");
      eventLoop.exec();
    } else {
      mpGDBProcess->write(cmd.mCommand + "\r\n");
      mGDBCommandTimer.setInterval(commandTimeoutTime());
      if (!cmd.mCommand.endsWith("-gdb-exit")) {
        mGDBCommandTimer.start();
      }
    }
  }
}

/*!
 * \brief GDBAdapter::commandTimeoutTime
 * Returns the GDB Command timeout.
 * \return
 */
int GDBAdapter::commandTimeoutTime() const
{
  int timeout = OptionsDialog::instance()->getDebuggerPage()->getGDBCommandTimeoutSpinBox()->value();
  return 1000 * qMax(40, timeout);
}

/*!
 * \brief GDBAdapter::insertCatchOMCBreakpoint
 * Inserts a breakpoint at Catch.omc:1 to handle MMC_THROW()
 */
void GDBAdapter::insertCatchOMCBreakpoint()
{
  postCommand(CommandFactory::breakInsert("Catch.omc", 1, true), GDBAdapter::SilentCommand);
}

/*!
 * \brief GDBAdapter::enableCatchOMCBreakpoint
 * Enables the breakpoint at Catch.omc:1 to handle MMC_THROW()
 */
void GDBAdapter::enableCatchOMCBreakpoint()
{
  postCommand(CommandFactory::breakEnable(QStringList() << mCatchOMCBreakpointId), GDBAdapter::SilentCommand);
}

/*!
 * \brief GDBAdapter::disableCatchOMCBreakpoint
 * Disables the breakpoint at Catch.omc:1 to handle MMC_THROW()
 */
void GDBAdapter::disableCatchOMCBreakpoint()
{
  postCommand(CommandFactory::breakDisable(QStringList() << mCatchOMCBreakpointId), GDBAdapter::SilentCommand);
}

/*!
 * \brief GDBAdapter::deleteCatchOMCBreakpoint
 * Deletes the breakpoint at Catch.omc:1
 */
void GDBAdapter::deleteCatchOMCBreakpoint()
{
  postCommand(CommandFactory::breakDelete(QStringList() << mCatchOMCBreakpointId), GDBAdapter::SilentCommand);
}

/*!
 * \brief GDBAdapter::stackListFramesCB
 * Callback function for handling the -stack-list-frames command.
 * \param pGDBMIResultRecord - the stack list frames result record.
 */
void GDBAdapter::stackListFramesCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pStackGDBMIResult = getGDBMIResult("stack", pGDBMIResultRecord->miResultsList);
  if (pStackGDBMIResult) {
    emit stackListFrames(pStackGDBMIResult->miValue);
  }
}

/*!
 * \brief GDBAdapter::stackListVariablesCB
 * Callback function for handling the -stack-list-variables command.
 * \param pGDBMIResultRecord - the stack list variables record.
 */
/*
  -stack-list-variables --thread 1 --frame 0 --all-values
  ^done,variables=[{name="x",value="11"},{name="s",value="{a = 1, b = 2}"}]
  */
void GDBAdapter::stackListVariablesCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pVaribalesGDBMIResult = getGDBMIResult("variables", pGDBMIResultRecord->miResultsList);
    if (pVaribalesGDBMIResult) {
      GDBMIValue* pVariablesGDBMIValue = pVaribalesGDBMIResult->miValue;
      if(pVariablesGDBMIValue->type == GDBMIValue::ListValue) {
        GDBMIValueList::iterator valuesListiterator;
        QList<QVector<QVariant> > locals;
        for (valuesListiterator = pVariablesGDBMIValue->miList->miValuesList.begin(); valuesListiterator != pVariablesGDBMIValue->miList->miValuesList.end(); ++valuesListiterator) {
          GDBMIValue *pGDBMIValue = *valuesListiterator;
          QString name, type, value;
          if (pGDBMIValue->type == GDBMIValue::TupleValue) {
            GDBMIResultList resultsList = pGDBMIValue->miTuple->miResultsList;
            name = getGDBMIConstantValue(getGDBMIResult("name", resultsList));
            type = getGDBMIConstantValue(getGDBMIResult("type", resultsList));
            value = getGDBMIConstantValue(getGDBMIResult("value", resultsList));
            /* We are only interested in the variables starting with underscore. */
            if (name.startsWith("_")) {
              QVector<QVariant> localItemData;
              localItemData << name << name.mid(1) << type << value; /* always return 4 items from here. */
              locals.append(localItemData);
            }
          }
        }
        MainWindow::instance()->getLocalsWidget()->getLocalsTreeModel()->insertLocalsList(locals);
      }
    }
  }
  /* The debugger almost completes one cycle here. For example if user clicks stepOver then debugger requests threads, stacks, locals etc.
   * And all fetching of all these things after the stopped event are finished here. So we suspend the debugger here.
   */
  suspendDebugger();
}

/*!
 * Callback function for handling the "-data-evaluate-expression (char*)getTypeOfAny(expr)" command.
 * \param pGDBMIResultRecord - the variable type result record.
 * \param pGDBMIResultRecord
 */
/*
  935^done,value="0x72e1938 \"String\""
  59^done,value="0x5c012e0 \"record<GlobalScript.SymbolTable.SYMBOLTABLE>\""
  Sometimes the values are optimized out if -O2 is used then we get this,
  14^error,msg="value has been optimized out"
  */
void GDBAdapter::getTypeOfAnyCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pGDBMIResult = 0;
  QString metaTypeValue = "";
  if (pGDBMIResultRecord->cls.compare("done") == 0) { // if the value is not optimized out then read the value.
    pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult && pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = getGDBMIConstantValue(pGDBMIResult);
      int beginIndex = value.indexOf("\"") + 1;
      int endIndex = value.lastIndexOf("\"");
      metaTypeValue = value.mid(beginIndex, endIndex - beginIndex);
    }
  } else if (pGDBMIResultRecord->cls.compare("error") == 0) { // if the value is optimized out then read the error message.
    pGDBMIResult = getGDBMIResult("msg", pGDBMIResultRecord->miResultsList);
    metaTypeValue = getGDBMIConstantValue(pGDBMIResult);
  }
  GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
  if (LocalsTreeItem *pLocalsTreeItem = qobject_cast<LocalsTreeItem*>(cmd.mpCallbackObject)) {
    pLocalsTreeItem->setModelicaMetaType(metaTypeValue);
  }
}

/*!
 * \brief GDBAdapter::dataEvaluateExpressionCB
 * Callback function for handling the "-data-evaluate-expression expr" command.
 * \param pGDBMIResultRecord - the variable value result record.
 */
/*
  392^done,value="0 '\\000'"
  929^done,value="6"
  */
void GDBAdapter::dataEvaluateExpressionCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = QString(pGDBMIResult->miValue->value.c_str());
      value = StringHandler::removeFirstLastQuotes(value);
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      if (LocalsTreeItem *pLocalsTreeItem = qobject_cast<LocalsTreeItem*>(cmd.mpCallbackObject)) {
        pLocalsTreeItem->setValue(value);
      }
    }
  }
}

/*!
 * \brief GDBAdapter::anyStringCB
 * Callback function for handling the "-data-evaluate-expression (char*)anyString(expr)" command.
 * \param pGDBMIResultRecord - the variable value result record.
 */
/*
  1302^done,value="0x456c158 \"C:/OpenModelica/trunk/build/\""
  */
void GDBAdapter::anyStringCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = QString(pGDBMIResult->miValue->value.c_str());
      value = StringHandler::removeFirstLastQuotes(value);
      int beginIndex = value.indexOf("\"") + 1;
      int endIndex = value.lastIndexOf("\"") - 1;
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      if (LocalsTreeItem *pLocalsTreeItem = qobject_cast<LocalsTreeItem*>(cmd.mpCallbackObject)) {
        pLocalsTreeItem->setValue(value.mid(beginIndex, endIndex - beginIndex));
      }
    }
  }
}

/*!
 * \brief GDBAdapter::arrayLengthCB
 * Callback function for handling the "-data-evaluate-expression (int)arrayLength(expr)" command.
 * \param pGDBMIResultRecord - the variable value result record.
 */
/*
  252^done,value="3"
  */
void GDBAdapter::arrayLengthCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = QString(pGDBMIResult->miValue->value.c_str());
      value = StringHandler::removeFirstLastQuotes(value);
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      if (ModelicaValue *pModelicaValue = qobject_cast<ModelicaValue*>(cmd.mpCallbackObject)) {
        pModelicaValue->setChildrenSize(value);
        pModelicaValue->getLocalsTreeItem()->getLocalsTreeModel()->updateLocalsTreeItem(pModelicaValue->getLocalsTreeItem());
      }
    }
  }
}

/*!
 * \brief GDBAdapter::getMetaTypeElementCB
 * Callback function for handling the "-data-evaluate-expression "(char*)getMetaTypeElementCB(expr, index)"" command.
 * \param pGDBMIResultRecord - the meta type element array as result record.
 */
/*
  20^done,value="0x59f7008 \"^omc_element{3411547,name,String,BouncingBall}\""
  21^done,value="0x59f7008 \"^omc_element{21175143,subscripts,list<Any>,{NIL}}\""
  */
void GDBAdapter::getMetaTypeElementCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = QString(pGDBMIResult->miValue->value.c_str());
      value = StringHandler::removeFirstLastQuotes(value);
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      int beginIndex = value.indexOf("\"") + 1;
      int endIndex = value.lastIndexOf("\"") - 1;
      QString trimmedValue = value.mid(beginIndex, endIndex - beginIndex);
      trimmedValue = trimmedValue.remove("\\");
      QString name, displayName, type;
      GDBMIResponse *pGDBMIResponse = parseGDBOutput(trimmedValue.toStdString().c_str());
      if (pGDBMIResponse) {
        if (pGDBMIResponse->type == GDBMIResponse::ResultRecordResponse) {
          GDBMIResult* pGDBMIResult = getGDBMIResult("omc_element", pGDBMIResponse->miResultRecord->miResultsList);
          if (pGDBMIResult->miValue->type == GDBMIValue::TupleValue) {
            GDBMIResultList resultsList = pGDBMIResult->miValue->miTuple->miResultsList;
            name = getGDBMIConstantValue(getGDBMIResult("name", resultsList));
            displayName = getGDBMIConstantValue(getGDBMIResult("displayName", resultsList));
            type = getGDBMIConstantValue(getGDBMIResult("type", resultsList));
          }
        }
        delete pGDBMIResponse;
      }
      if (LocalsTreeItem *pLocalsTreeItem = qobject_cast<LocalsTreeItem*>(cmd.mpCallbackObject)) {
        QVector<QVariant> localItemData;
        localItemData << name << displayName << type << ""; /* always return 4 items */
        MainWindow::instance()->getLocalsWidget()->getLocalsTreeModel()->insertLocalItemData(localItemData, pLocalsTreeItem);
      }
    }
  }
}

/*!
 * \brief GDBAdapter::isOptionNoneCB
 * Callback function for handling the "-data-evaluate-expression (int)isOptionNone(expr)" command.
 * \param pGDBMIResultRecord - the option none value result record.
 */
/*
  252^done,value="1"
  */
void GDBAdapter::isOptionNoneCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("done") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("value", pGDBMIResultRecord->miResultsList);
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      QString value = QString(pGDBMIResult->miValue->value.c_str());
      value = StringHandler::removeFirstLastQuotes(value);
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      if (ModelicaValue *pModelicaValue = qobject_cast<ModelicaValue*>(cmd.mpCallbackObject)) {
        pModelicaValue->setChildrenSize(value);
      }
    }
  }
}

/*!
 * \brief GDBAdapter::createFullBacktraceCB
 * Callback function for handling the "-interpreter-exec console "thread apply all bt full"" command.
 * \param pGDBMIResultRecord - the backtrace result record.
 */
void GDBAdapter::createFullBacktraceCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  QString backtrace = QString(pGDBMIResultRecord->consoleStreamOutput.c_str()) + QString(pGDBMIResultRecord->logStreamOutput.c_str());
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  QFileInfo fileInfo(QString("%1/backtrace%2.txt").arg(Utilities::tempDirectory())
                     .arg(QDateTime::currentDateTime().toString("yyyyMMddhhmmsszzz")));
  if (MainWindow::instance()->getLibraryWidget()->saveFile(fileInfo.absoluteFilePath(), backtrace)) {
    LibraryTreeItem *pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::Text, fileInfo.fileName(),
                                                                                 fileInfo.absoluteFilePath(), fileInfo.absoluteFilePath(),
                                                                                 true, pLibraryTreeModel->getRootLibraryTreeItem());
    if (pLibraryTreeItem) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
    }
  }
}

/*!
 * \brief GDBAdapter::insertBreakpointCB
 * Callback function for handling the "-insert-break" command.
 * \param pGDBMIResultRecord - the breakpoint ID result record.
 */
/*
  6^done,bkpt={number="1",type="breakpoint",disp="keep",enabled="y",addr="0x00c397f1",func="omc_Interactive_getComponents2",
  file="c:/OpenModelica/trunk/Compiler/Script/Interactive.mo",fullname="c:\\openmodelica\\trunk\\compiler\\script\\interactive.mo",
  line="10806",times="0",original-location="C:/OpenModelica/trunk/Compiler/Script/Interactive.mo:10806"}
  */
void GDBAdapter::insertBreakpointCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pBreakpointGDBMIResult = getGDBMIResult("bkpt", pGDBMIResultRecord->miResultsList);
  if (pBreakpointGDBMIResult) {
    if (pBreakpointGDBMIResult->miValue->type == GDBMIValue::TupleValue) {
      GDBMIResultList resultsList = pBreakpointGDBMIResult->miValue->miTuple->miResultsList;
      QString breakpointID = getGDBMIConstantValue(getGDBMIResult("number", resultsList));
      GDBMICommand cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      if (BreakpointTreeItem *pBreakpointTreeItem = qobject_cast<BreakpointTreeItem*>(cmd.mpCallbackObject)) {
        pBreakpointTreeItem->setBreakpointID(breakpointID);
      }
    }
  }
}

/*!
 * \brief GDBAdapter::getGDBMIResult
 * Finds the GDBMIResult from GDBMIResultList.
 * \param variable -  the name of GDBMIResult to find.
 * \param resultsList - GDBMIResultList
 * \return GDBMIResult
 */
GDBMIResult* GDBAdapter::getGDBMIResult(const char *variable, GDBMIResultList resultsList)
{
  GDBMIResultList::iterator it;
  for (it = resultsList.begin(); it != resultsList.end(); ++it) {
    GDBMIResult *pGDBMIResult = *it;
    if (pGDBMIResult->variable.compare(variable) == 0) {
      return pGDBMIResult;
    }
  }
  return 0;
}

/*!
 * \brief GDBAdapter::getGDBMIConstantValue
 * Finds the constant value from GDBMIResult
 * \param pGDBMIResult - pointer to GDBMIResult
 * \return the constant value.
 */
QString GDBAdapter::getGDBMIConstantValue(GDBMIResult *pGDBMIResult)
{
  if (pGDBMIResult) {
    if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
      return StringHandler::unparse(QString(pGDBMIResult->miValue->value.c_str()));
    }
  }
  return "";
}

/*!
 * \brief GDBAdapter::insertBreakpoint
 * Sends the -break-insert command to GDB.
 * \param pBreakpointTreeItem - pointer to BreakpointTreeItem
 */
void GDBAdapter::insertBreakpoint(BreakpointTreeItem *pBreakpointTreeItem)
{
  QFileInfo fileInfo(pBreakpointTreeItem->getFilePath());
  QByteArray command;
  command = CommandFactory::breakInsert(fileInfo.fileName(), pBreakpointTreeItem->getLineNumber().toInt(), !pBreakpointTreeItem->isEnabled(),
                                        pBreakpointTreeItem->getCondition(), pBreakpointTreeItem->getIgnoreCount());
  postCommand(command, pBreakpointTreeItem, &GDBAdapter::insertBreakpointCB);
}

/*!
 * \brief GDBAdapter::suspendDebugger
 * Sets the debugger suspended.\n
 * Sends the notification to StackFramesWidget and LocalsWidget by emitting the signal inferiorSuspended
 */
void GDBAdapter::suspendDebugger()
{
  setInferiorSuspended(true);
  setInferiorTerminated(false);
  setInferiorRunning(false);
  emit inferiorSuspended();
}

/*!
 * \brief GDBAdapter::resumeDebugger
 * Sets the debugger resumed.\n
 * Sends the notification to StackFramesWidget and LocalsWidget by emitting the signal inferiorResumed
 */
void GDBAdapter::resumeDebugger()
{
  setInferiorSuspended(false);
  setInferiorTerminated(false);
  setInferiorRunning(true);
  emit inferiorResumed();
}

/*!
 * \brief GDBAdapter::handleGDBProcessStartedHelper
 * Helper function for handling the GDB process start up.
 * \see GDBAdapter::handleGDBProcessStarted
 * \see GDBAdapter::handleGDBProcessStartedForAttach
 */
void GDBAdapter::handleGDBProcessStartedHelper()
{
  setGDBRunning(true);
  /* create the tmp path */
  QString& tmpPath = Utilities::tempDirectory();
  /* create a file to write debugger response log */
  mDebuggerLogFile.setFileName(QString("%1omeditdebugger.log").arg(tmpPath));
  if (mDebuggerLogFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
    mDebuggerLogFileTextStream.setDevice(&mDebuggerLogFile);
    mDebuggerLogFileTextStream.setCodec(Helper::utf8.toStdString().data());
    mDebuggerLogFileTextStream.setGenerateByteOrderMark(false);
  }
  emit GDBProcessStarted();
  // set the GDB environment before starting the actual debugging
  // sets the confirm on/off. Off disables confirmation requests. On Enables confirmation requests.
  postCommand(CommandFactory::GDBSet("confirm off"), GDBAdapter::NonCriticalResponse);
  /* When displaying a pointer to an object, identify the actual (derived) type of the object rather than the declared type,
   * using the virtual function table.
   */
  postCommand(CommandFactory::GDBSet("print object on"), GDBAdapter::NonCriticalResponse);
  // This indicates that an unrecognized breakpoint location should automatically result in a pending breakpoint being created.
  postCommand(CommandFactory::GDBSet("breakpoint pending on"), GDBAdapter::NonCriticalResponse);
  // This command sets the width of the screen to num characters wide.
  postCommand(CommandFactory::GDBSet("width 0"), GDBAdapter::NonCriticalResponse);
  // This command sets the height of the screen to num lines high.
  postCommand(CommandFactory::GDBSet("height 0"), GDBAdapter::NonCriticalResponse);
  /* Set a limit on how many elements of an array GDB will print.\n
   * If GDB is printing a large array, it stops printing after it has printed the number of elements set by the set print elements command.\n
   * This limit also applies to the display of strings. When GDB starts, this limit is set to 200.\n
   * Setting number-of-elements to zero means that the printing is unlimited.
   */
  int numberOfElements = OptionsDialog::instance()->getDebuggerPage()->getGDBOutputLimitSpinBox()->value();
  postCommand(CommandFactory::GDBSet(QString("print elements %1").arg(QString::number(numberOfElements))), GDBAdapter::NonCriticalResponse);
  /* set the inferior arguments
   * GDB change the program arguments if we pass them through --args e.g -override=variableFilter=.*
   */
  postCommand(CommandFactory::GDBSet(QString("args %1").arg(mInferiorArguments.join(" "))), GDBAdapter::NonCriticalResponse);
  /* Insert breakpoints */
  insertCatchOMCBreakpoint();
  insertBreakpoints();
}

/*!
 * \brief GDBAdapter::writeDebuggerCommandLog
 * Writes the debugger command to the omeditdebugger.log file.
 * \param command - the command to write
 * \param command
 */
void GDBAdapter::writeDebuggerCommandLog(QByteArray command)
{
  if (mDebuggerLogFileTextStream.device()) {
    mDebuggerLogFileTextStream << "MI TxThread :: " << command << "\n\n";
    mDebuggerLogFileTextStream.flush();
  }
}

/*!
 * \brief GDBAdapter::writeDebuggerResponseLog
 * Writes the debugger response to the omeditdebugger.log file.
 * \param response - the response to write
 * \param response
 */
void GDBAdapter::writeDebuggerResponseLog(QString response)
{
  if (mDebuggerLogFileTextStream.device()) {
    QString newLine = response.endsWith("\n") ? "\n" : "\n\n";
    mDebuggerLogFileTextStream << "MI RxThread :: " << response << newLine;
    mDebuggerLogFileTextStream.flush();
  }
}

/*!
 * \brief GDBAdapter::insertBreakpoints
 * Reads the list of breakpoints from BreakpointsTreeModel and inserts them in GDB.\n
 */
void GDBAdapter::insertBreakpoints()
{
  QList<BreakpointTreeItem*> breakpoints;
  breakpoints = MainWindow::instance()->getBreakpointsWidget()->getBreakpointsTreeModel()->getRootBreakpointTreeItem()->getChildren();
  foreach (BreakpointTreeItem *pBreakpoint, breakpoints) {
    insertBreakpoint(pBreakpoint);
  }
}

/*!
 * \brief GDBAdapter::startDebugger
 * Starts the debugger.\n
 * Sends the -exec-run command.\n
 * Sends the -data-evaluate-expression changeStdStreamBuffer() command.\n
 * Sends the notification to StackFramesWidget and LocalsWidget by emitting the signal inferiorResumed
 */
void GDBAdapter::startDebugger()
{
  setInferiorSuspended(false);
  setInferiorTerminated(false);
  setInferiorRunning(true);
  setChangeStdStreamBuffer(false);
  MainWindow::instance()->getStackFramesWidget()->setSelectedThread(1);
  MainWindow::instance()->getStackFramesWidget()->setSelectedFrame(0);
  postCommand(CommandFactory::execRun());
  emit inferiorResumed();
}

/*!
 * \brief GDBAdapter::processGDBMIResponse
 * Process the GDB output.
 * \param response
 */
void GDBAdapter::processGDBMIResponse(QString response)
{
  if (response.isEmpty() || response == "(gdb) ") {
    return;
  }

  mCurrentResponse = response;
  GDBMIResponse *pGDBMIResponse = parseGDBOutput(response.toStdString().c_str());
//  fprintf(stdout, "Read Line :: %s\n\n", response.toStdString().c_str());fflush(NULL);
//  fprintf(stdout, "Parsed Line :: ");fflush(NULL);
//  printGDBMIResponse(pGDBMIResponse);
//  fprintf(stdout, "\n\n");fflush(NULL);
  if (pGDBMIResponse) {
    if (pGDBMIResponse->type == GDBMIResponse::OutOfBandRecordResponse) {
      //qDebug() << "OutOfBandRecordResponse" << response;
      GDBMIOutOfBandRecordList::iterator it;
      for (it = pGDBMIResponse->miOutOfBandRecordList.begin(); it != pGDBMIResponse->miOutOfBandRecordList.end(); ++it) {
        processGDBMIOutOfBandRecord(*it);
      }
    } else if (pGDBMIResponse->type == GDBMIResponse::ResultRecordResponse) {
      //qDebug() << "ResultRecordResponse" << response;
      processGDBMIResultRecord(pGDBMIResponse->miResultRecord);
    } else {
      MainWindow::instance()->getTargetOutputWidget()->logDebuggerStandardOutput(response);
    }
    delete pGDBMIResponse;
  } else {
    list<string> parserErrorsList = getParserErrorsList();
    list<string>::iterator parserErrorsListIterator;
    for (parserErrorsListIterator = parserErrorsList.begin(); parserErrorsListIterator != parserErrorsList.end(); ++parserErrorsListIterator) {
      qCritical() << (*parserErrorsListIterator).c_str();
    }
    clearParserErrorsList();
  }
  list<string> lexerErrorsList = getLexerErrorsList();
  list<string>::iterator lexerErrorsListIterator;
  for (lexerErrorsListIterator = lexerErrorsList.begin(); lexerErrorsListIterator != lexerErrorsList.end(); ++lexerErrorsListIterator) {
    qCritical() << (*lexerErrorsListIterator).c_str();
  }
  clearLexerErrorsList();
}

/*!
 * \brief GDBAdapter::processGDBMIOutOfBandRecord
 * Process the GDBMIOutOfBandRecord.
 * \param pGDBMIOutOfBandRecord
 */
void GDBAdapter::processGDBMIOutOfBandRecord(GDBMIOutOfBandRecord *pGDBMIOutOfBandRecord)
{
  if (pGDBMIOutOfBandRecord->type == GDBMIOutOfBandRecord::AsyncRecord) {
    processGDBMIResultRecord(pGDBMIOutOfBandRecord->miResultRecord);
  } else if (pGDBMIOutOfBandRecord->type == GDBMIOutOfBandRecord::StreamRecord) {
    handleGDBMIStreamRecord(pGDBMIOutOfBandRecord->miStreamRecord);
  }
}

/*!
 * \brief GDBAdapter::processGDBMIResultRecord
 * Process the GDBMIResultRecord.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::processGDBMIResultRecord(GDBMIResultRecord *pGDBMIResultRecord)
{
  /* output not as a response of command */
  if (pGDBMIResultRecord->token == -1) {
    /* handle stopped response */
    if (pGDBMIResultRecord->cls.compare("stopped") == 0) {
      string reason = "";
      GDBMIResultList::iterator it;
      for (it = pGDBMIResultRecord->miResultsList.begin(); it != pGDBMIResultRecord->miResultsList.end(); ++it) {
        GDBMIResult *pGDBMIResult = *it;
        if (pGDBMIResult->variable.compare("reason") == 0) {
          if (pGDBMIResult->miValue->type == GDBMIValue::ConstantValue) {
            reason = pGDBMIResult->miValue->value;
            break;
          }
        }
      }
      handleStoppedEvent(reason, pGDBMIResultRecord);
      mPendingConsoleStreamOutput.clear();
      mPendingLogStreamOutput.clear();
    } else if (pGDBMIResultRecord->cls.compare("running") == 0) {
      /* handle running response */
      MainWindow::instance()->getStackFramesWidget()->setStatusMessage("Running");
      resumeDebugger();
    } else if (pGDBMIResultRecord->cls.compare("thread-group-added") == 0 ||
               pGDBMIResultRecord->cls.compare("thread-group-started") == 0 ||
               pGDBMIResultRecord->cls.compare("thread-created") == 0 ||
               pGDBMIResultRecord->cls.compare("library-loaded") == 0 ||
               pGDBMIResultRecord->cls.compare("thread-exited") == 0 ||
               pGDBMIResultRecord->cls.compare("thread-group-exited") == 0) {
      /* Display few of the notify-async-output on the StackFramesWidget message label.
       * Not sure what to do of these notification at the moment.
       */
      MainWindow::instance()->getStackFramesWidget()->setStatusMessage(mCurrentResponse);
    } else if (pGDBMIResultRecord->cls.compare("error") == 0) {
      /* handle the error response */
      GDBMIResult* pGDBMIResult = getGDBMIResult("msg", pGDBMIResultRecord->miResultsList);
      MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(getGDBMIConstantValue(pGDBMIResult));
    }
  } else {  /* output as a response to a command */
    GDBMICommand cmd;
    pGDBMIResultRecord->consoleStreamOutput = QString(mPendingConsoleStreamOutput).toStdString();
    pGDBMIResultRecord->logStreamOutput = QString(mPendingLogStreamOutput).toStdString();
    mPendingConsoleStreamOutput.clear();
    mPendingLogStreamOutput.clear();
    if (mGDBMICommandsHash.contains(pGDBMIResultRecord->token)) {
      cmd = mGDBMICommandsHash.value(pGDBMIResultRecord->token);
      /* if cmd has callback function then call it. */
      if (cmd.mGDBCommandCallback) {
        (this->*cmd.mGDBCommandCallback)(pGDBMIResultRecord);
      }
      if (cmd.mFlags & GDBAdapter::BlockUntilResponse) {
        emit commandCompleted();
      }
      cmd.mCompleted = true;
      mGDBMICommandsHash[pGDBMIResultRecord->token] = cmd;
    }
    /* handle the error response */
    if (pGDBMIResultRecord->cls.compare("error") == 0) {
      if (!(cmd.mFlags & GDBAdapter::SilentCommand)) {
        GDBMIResult* pGDBMIResult = getGDBMIResult("msg", pGDBMIResultRecord->miResultsList);
        QString msg = getGDBMIConstantValue(pGDBMIResult);
        if (msg.compare(Helper::VALUE_OPTIMIZED_OUT) != 0) {
          MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(msg);
        }
      }
    }
  }
}

/*!
 * \brief GDBAdapter::handleGDBMIStreamRecord
 * Handles the GDBMIStreamRecord.
 * \param pGDBMIStreamRecord
 */
void GDBAdapter::handleGDBMIStreamRecord(GDBMIStreamRecord *pGDBMIStreamRecord)
{
  switch (pGDBMIStreamRecord->type) {
    case GDBMIStreamRecord::ConsoleStream:
      handleGDBMIConsoleStream(pGDBMIStreamRecord);
      break;
    case GDBMIStreamRecord::TargetStream:
      MainWindow::instance()->getTargetOutputWidget()->logDebuggerStandardOutput(pGDBMIStreamRecord->value.c_str());
      break;
    case GDBMIStreamRecord::LogStream:
      handleGDBMILogStream(pGDBMIStreamRecord);
      break;
    default:
      break;
  }
}

/*!
 * \brief GDBAdapter::handleGDBMIConsoleStream
 * Handles the GDBMIStreamRecord.
 * \param pGDBMIStreamRecord
 */
void GDBAdapter::handleGDBMIConsoleStream(GDBMIStreamRecord *pGDBMIStreamRecord)
{
  QString consoleData = StringHandler::unparse(pGDBMIStreamRecord->value.c_str());
  mPendingConsoleStreamOutput += consoleData;
  /* Only display some selected console messages */
  if (consoleData.startsWith("Reading symbols from ") || consoleData.startsWith("[New ") || consoleData.startsWith("[Thread ")) {
    MainWindow::instance()->getStackFramesWidget()->setStatusMessage(consoleData.simplified());
  }
}

/*!
 * \brief GDBAdapter::handleGDBMILogStream
 * Handles the GDBMIStreamRecord.\n
 * log-stream-output is output text coming from gdb's internals, for instance messages that should be displayed as part of an error log.\n
 * All the log output is prefixed by ‘&’.
 * \param pGDBMIStreamRecord
 */
void GDBAdapter::handleGDBMILogStream(GDBMIStreamRecord *pGDBMIStreamRecord)
{
  QString logData = StringHandler::unparse(pGDBMIStreamRecord->value.c_str());
  mPendingLogStreamOutput += logData;
  /*! \note Skip the log messages we get as a result of pending breakpoint.
   * e.g., No source file named Catch.omc.
   */
  if (logData.startsWith("No source file named")) {
    return;
  }
  MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(logData);
}

/*!
 * \brief GDBAdapter::skipSteppedInFrames
 * Checks if debugger is stopped on a non-modelica file.
 * Performs silent -exec-next or -exec-step until we reach a valid modelica file.
 * \param pGDBMIResultRecord
 * \return
 */
bool GDBAdapter::skipSteppedInFrames(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pGDBMIResult = getGDBMIResult("frame", pGDBMIResultRecord->miResultsList);
  if (pGDBMIResult && pGDBMIResult->miValue->type == GDBMIValue::TupleValue) {
    GDBMIResultList resultsList = pGDBMIResult->miValue->miTuple->miResultsList;
    QString file = getGDBMIConstantValue(getGDBMIResult("file", resultsList));
    QFileInfo fileInfo(file);
    if (!Utilities::isModelicaFile(fileInfo.suffix())) {
      enableCatchOMCBreakpoint();
      if (getExecuteCommand() == GDBAdapter::ExecNext) {
        postCommand(CommandFactory::execNext(), GDBAdapter::SilentCommand);
      } else if (getExecuteCommand() == GDBAdapter::ExecStep) {
        postCommand(CommandFactory::execStep(), GDBAdapter::SilentCommand);
      }
      return false;
    }
  }
  return true;
}

/*!
 * \brief GDBAdapter::handleStoppedEvent
 * Handles the GDB stopped event.
 * \param reason
 * \param pGDBMIResultRecord
 */
void GDBAdapter::handleStoppedEvent(string reason, GDBMIResultRecord *pGDBMIResultRecord)
{
  // call changeStdStreamBuffer no matter for what reason we have stopped
  if (!isChangeStdStreamBuffer() && !(reason.compare("\"exited-normally\"") == 0 || reason.compare("\"exited\""))) {
    setChangeStdStreamBuffer(true);
    postCommand(CommandFactory::changeStdStreamBuffer(), GDBAdapter::NonCriticalResponse | GDBAdapter::BlockUntilResponse);
  }
  if (reason.compare("\"breakpoint-hit\"") == 0) {
    handleBreakpointHit(pGDBMIResultRecord);
  } else if (reason.compare("\"end-stepping-range\"") == 0) {
    handleSteppingRange(pGDBMIResultRecord);
  } else if (reason.compare("\"function-finished\"") == 0) {
    handleFunctionFinished(pGDBMIResultRecord);
  } else if (reason.compare("\"exited-normally\"") == 0 || reason.compare("\"exited\"") == 0) {
    /* Inferior stopped and exited normally OR Inferior exited. Stop the GDB and exit debugger. */
    postCommand(CommandFactory::GDBExit());
  } else if (reason.compare("\"signal-received\"") == 0) {
    handleSignalReceived(pGDBMIResultRecord);
  } else {
    /* If we are stopped for unknown reason. When GDB is attached to a running process it just returns *stopped. */
    /* Get the list of threads. */
    postCommand(CommandFactory::threadInfo(), &GDBAdapter::threadInfoCB);
    /* Get the list of stack frames. */
    StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
    postCommand(CommandFactory::stackListFrames(pStackFramesWidget->getSelectedThread()), &GDBAdapter::stackListFramesCB);
  }
}

/*!
 * \brief GDBAdapter::handleBreakpointHit
 * Handles the GDB breakpoint hit event.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::handleBreakpointHit(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pGDBMIResult = getGDBMIResult("frame", pGDBMIResultRecord->miResultsList);
  if (pGDBMIResult && pGDBMIResult->miValue->type == GDBMIValue::TupleValue) {
    GDBMIResultList resultsList = pGDBMIResult->miValue->miTuple->miResultsList;
    QString file = getGDBMIConstantValue(getGDBMIResult("file", resultsList));
    if (file.compare("Catch.omc") == 0) {
      disableCatchOMCBreakpoint();
      /* since we reached inside the Catch.omc::mmc_catch_dummy_fn() function we should move out from there
       * send -exec-finish command to return back to actual function.
       */
      postCommand(CommandFactory::execFinish());
      return;
    }
  }
  /* Display stopped message */
  QString breakPoint = getGDBMIConstantValue(getGDBMIResult("bkptno", pGDBMIResultRecord->miResultsList));
  int breakPointNumber = breakPoint.toInt() - 1; /* since we add an internal breakpoint at Catch.omc:1 */
  QString threadId = getGDBMIConstantValue(getGDBMIResult("thread-id", pGDBMIResultRecord->miResultsList));
  MainWindow::instance()->getStackFramesWidget()->setStatusMessage(QString("Stopped at breakpoint %1 in thread %2").arg(breakPointNumber).arg(threadId));
  /* Get the list of threads. */
  postCommand(CommandFactory::threadInfo(), &GDBAdapter::threadInfoCB);
  /* Get the list of stack frames. */
  StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
  postCommand(CommandFactory::stackListFrames(pStackFramesWidget->getSelectedThread()), &GDBAdapter::stackListFramesCB);
}

/*!
 * \brief GDBAdapter::handleSteppingRange
 * Handles the GDB end stepping range event.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::handleSteppingRange(GDBMIResultRecord *pGDBMIResultRecord)
{
  disableCatchOMCBreakpoint();
  if (skipSteppedInFrames(pGDBMIResultRecord)) {
    /* Display end stepping range message */
    QString threadId = getGDBMIConstantValue(getGDBMIResult("thread-id", pGDBMIResultRecord->miResultsList));
    MainWindow::instance()->getStackFramesWidget()->setStatusMessage(QString("End stepping range in thread %1").arg(threadId));
    /* Get the list of threads. */
    postCommand(CommandFactory::threadInfo(), &GDBAdapter::threadInfoCB);
    /* Get the list of stack frames. */
    StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
    postCommand(CommandFactory::stackListFrames(pStackFramesWidget->getSelectedThread()), &GDBAdapter::stackListFramesCB);
  }
}

/*!
 * \brief GDBAdapter::handleFunctionFinished
 * Handles the GDB function finished event.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::handleFunctionFinished(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (skipSteppedInFrames(pGDBMIResultRecord)) {
    /* Get the list of threads. */
    postCommand(CommandFactory::threadInfo(), &GDBAdapter::threadInfoCB);
    /* Get the list of stack frames. */
    StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
    postCommand(CommandFactory::stackListFrames(pStackFramesWidget->getSelectedThread()), &GDBAdapter::stackListFramesCB);
  }
}

/*!
 * \brief GDBAdapter::handleSignalReceived
 * Handles the GDB signal received event.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::handleSignalReceived(GDBMIResultRecord *pGDBMIResultRecord)
{
  /* Display signal received message */
  QString signalName = getGDBMIConstantValue(getGDBMIResult("signal-name", pGDBMIResultRecord->miResultsList));
  QString threadId = getGDBMIConstantValue(getGDBMIResult("thread-id", pGDBMIResultRecord->miResultsList));
  MainWindow::instance()->getStackFramesWidget()->setStatusMessage(QString("%1 signal received in thread %2").arg(signalName, threadId));
  /* check the signals received */
  if ((signalName.compare("SIGTRAP") == 0) || (signalName.compare("SIGINT") == 0)) {
    qDebug() << "Handle the SIGTRAP & SIGTINT";
  } else {
    QString signalMeaning = getGDBMIConstantValue(getGDBMIResult("signal-meaning", pGDBMIResultRecord->miResultsList));
    QString signalMsg = QString("Program received signal\n"
        "signal-name=\"%1\"\n"
        "signal-meaning=\"%2\"\n"
        "thread-id=\"%3\"\n").arg(signalName, signalMeaning, threadId);
    GDBMIResult *pFrameGDBMIResult = getGDBMIResult("frame", pGDBMIResultRecord->miResultsList);
    if (pFrameGDBMIResult && pFrameGDBMIResult->miValue->type == GDBMIValue::TupleValue) {
      GDBMIResultList resultsList = pFrameGDBMIResult->miValue->miTuple->miResultsList;
      QString level = getGDBMIConstantValue(getGDBMIResult("level", resultsList));
      QString address = getGDBMIConstantValue(getGDBMIResult("addr", resultsList));
      QString function = getGDBMIConstantValue(getGDBMIResult("func", resultsList));
      QString line = getGDBMIConstantValue(getGDBMIResult("line", resultsList));
      QString file = getGDBMIConstantValue(getGDBMIResult("file", resultsList));
      QString fullName = getGDBMIConstantValue(getGDBMIResult("fullname", resultsList));
      QString frameMsg = QString("level=\"%4\", address=\"%5\", function=\"%6\", line=\"%7\", file=\"%8\", fullName=\"%9\"").arg(level, address, function, line, file, fullName);
      signalMsg.append(frameMsg);
    }
    MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(signalMsg);
    /* Get the list of threads. */
    postCommand(CommandFactory::threadInfo(), &GDBAdapter::threadInfoCB);
    /* Get the list of stack frames. */
    StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
    postCommand(CommandFactory::stackListFrames(pStackFramesWidget->getSelectedThread()), &GDBAdapter::stackListFramesCB);
  }
}

/*!
 * \brief GDBAdapter::threadInfoCB
 * Callback function for handling the -thread-info command.
 * \param pGDBMIResultRecord - the threads list result record.
 */
void GDBAdapter::threadInfoCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  GDBMIResult *pThreadsGDBMIResult = getGDBMIResult("threads", pGDBMIResultRecord->miResultsList);
  QString currentThreadId = getGDBMIConstantValue(getGDBMIResult("current-thread-id", pGDBMIResultRecord->miResultsList));
  if (pThreadsGDBMIResult) {
    emit threadInfo(pThreadsGDBMIResult->miValue, currentThreadId);
  }
}

/*!
 * \brief GDBAdapter::attachCB
 * Callback function for handling the "attach pid" command.
 * \param pGDBMIResultRecord - the attach command result record.
 * \param pGDBMIResultRecord
 */
void GDBAdapter::attachCB(GDBMIResultRecord *pGDBMIResultRecord)
{
  if (pGDBMIResultRecord->cls.compare("running") == 0 || pGDBMIResultRecord->cls.compare("done") == 0) {
    // attach is successful. Do nothing.
  } else if (pGDBMIResultRecord->cls.compare("error") == 0) {
    GDBMIResult *pGDBMIResult = getGDBMIResult("msg", pGDBMIResultRecord->miResultsList);
    QString msg = getGDBMIConstantValue(pGDBMIResult);
    if (msg.compare("ptrace: Operation not permitted.") == 0) {
      QString ptraceMsg = "ptrace: Operation not permitted.\n\n"
          "Could not attach to the process. "
          "Make sure no other debugger traces this process.\n"
          "Check the settings of\n"
          "/proc/sys/kernel/yama/ptrace_scope\n"
          "For more details, see /etc/sysctl.d/10-ptrace.conf\n";
      MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(ptraceMsg);
    } else {
      MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(msg);
    }
    // Attach is failed. Stop the debugger
    postCommand(CommandFactory::GDBExit());
  }
}

/*!
 * \brief GDBAdapter::handleGDBProcessStarted
 * Slot activated when started signal of GDB process is raised.
 * Sets the GDB running state flag to true.
 */
void GDBAdapter::handleGDBProcessStarted()
{
  handleGDBProcessStartedHelper();
  /* start the inferior */
  startDebugger();
}

/*!
 * \brief GDBAdapter::handleGDBProcessStartedForSimulation
 * Slot activated when started signal of GDB process is raised for the simulation.\n
 * Saves the result file last modified time.
 */
void GDBAdapter::handleGDBProcessStartedForSimulation()
{
  QFileInfo resultFileInfo(QString(mSimulationOptions.getWorkingDirectory()).append("/").append(mSimulationOptions.getFullResultFileName()));
  if (resultFileInfo.exists()) {
    mResultFileLastModifiedDateTime = resultFileInfo.lastModified();
  }
}

/*!
 * \brief GDBAdapter::handleGDBProcessStartedForAttach
 * Slot activated when started signal of GDB process is raised.\n
 * Sets the GDB running state flag to true. Posts the attach to process command.
 */
void GDBAdapter::handleGDBProcessStartedForAttach()
{
  handleGDBProcessStartedHelper();
  /* attach the process */
  postCommand(CommandFactory::attach(mAttachToProcessId), GDBAdapter::ConsoleCommand, &GDBAdapter::attachCB);
}

/*!
 * \brief GDBAdapter::readGDBStandardOutput
 * Slot activated when readyReadStandardOutput signal of GDB process is raised.
 * Reads the output stream of GDB, parses the result and generates the events.
 */
void GDBAdapter::readGDBStandardOutput()
{
  mGDBCommandTimer.start(); // Restart timer.
  int newstart = 0;
  int scan = mStandardOutputBuffer.size();
  QString standardOutput = mpGDBProcess->readAllStandardOutput();
  mStandardOutputBuffer.append(standardOutput);
  // This can trigger when a blocking command starts an event loop.
  if (isParsingStandardOutput()) {
    GDBMICommand cmd = mGDBMICommandsHash.value(currentToken());
    if (cmd.mFlags & GDBAdapter::BlockUntilResponse && standardOutput.startsWith(QString::number(currentToken()))) {
      emit commandCompleted();
    }
    return;
  }
  while (newstart < mStandardOutputBuffer.size()) {
    int start = newstart;
    int end = mStandardOutputBuffer.indexOf('\n', scan);
    if (end < 0) {
      mStandardOutputBuffer.remove(0, start);
      return;
    }
    newstart = end + 1;
    scan = newstart;
    if (end == start) {
      continue;
    }
#ifdef Q_OS_WIN
    if (mStandardOutputBuffer.at(end - 1) == '\r') {
      --end;
      if (end == start) {
        continue;
      }
    }
#endif
    setParsingStandardOutput(true);
    QString response(QByteArray::fromRawData(mStandardOutputBuffer.constData() + start, end - start));
    writeDebuggerResponseLog(response);
    MainWindow::instance()->getGDBLoggerWidget()->logDebuggerStandardResponse(response);
    processGDBMIResponse(response);
    setParsingStandardOutput(false);
  }
  mStandardOutputBuffer.clear();
}

/*!
 * \brief GDBAdapter::readGDBErrorOutput
 * Slot activated when readyReadStandardError signal of GDB process is raised.
 * Reads the error stream of GDB.
 */
void GDBAdapter::readGDBErrorOutput()
{
  QString response = QString(mpGDBProcess->readAllStandardError());
  writeDebuggerResponseLog(response);
  MainWindow::instance()->getGDBLoggerWidget()->logDebuggerErrorResponse(response);
  MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(response);
}

/*!
 * \brief GDBAdapter::handleGDBProcessError
 * Slot activated when error signal of GDB Process is raised.
 * Sets the GDB running state flag to false.
 * \param error
 */
void GDBAdapter::handleGDBProcessError(QProcess::ProcessError error)
{
  Q_UNUSED(error);
  /* this signal is raised when we kill the timed out GDB forcefully. */
  if (isGDBKilled()) {
    return;
  }
  QString errorString = GUIMessages::getMessage(GUIMessages::GDB_ERROR).arg(mpGDBProcess->errorString()).arg(mGDBArguments.join(" "));
  MainWindow::instance()->getTargetOutputWidget()->logDebuggerErrorOutput(errorString);
  setGDBRunning(false);
}

/*!
 * \brief GDBAdapter::handleGDBProcessFinished
 * Slot activated when finished signal of GDB Process is raised.
 * Sets the GDB running state flag to false.
 * \param exitCode
 */
void GDBAdapter::handleGDBProcessFinished(int exitCode)
{
  Q_UNUSED(exitCode);
  if (mGDBCommandTimer.isActive()) {
    mGDBCommandTimer.stop();
  }
  setGDBRunning(false);
  /* close the debugger log file */
  mDebuggerLogFile.close();
  emit GDBProcessFinished();
}

/*!
 * \brief GDBAdapter::handleGDBProcessFinishedForSimulation
 * Slot activated when finished signal of GDB Process is raised.
 * \param exitCode
 */
void GDBAdapter::handleGDBProcessFinishedForSimulation(int exitCode)
{
  Q_UNUSED(exitCode);
  if (!isGDBKilled()) {
    MainWindow::instance()->getSimulationDialog()->simulationProcessFinished(mSimulationOptions, mResultFileLastModifiedDateTime);
  }
}

/*!
 * \brief GDBAdapter::GDBcommandTimeout
 * Slot activated when timeout signal of mGDBCommandTimer is raised.
 */
void GDBAdapter::GDBcommandTimeout()
{
  QList<int> keys = mGDBMICommandsHash.keys();
  qSort(keys);
  bool killIt = false;
  foreach (int key, keys) {
    const GDBMICommand &cmd = mGDBMICommandsHash.value(key);
    if (!cmd.mCompleted && !(cmd.mFlags & GDBAdapter::NonCriticalResponse)) {
      killIt = true;
    }
  }
  if (killIt) {
    int timeOut = mGDBCommandTimer.interval();
    const QString msg = tr("The gdb process has not responded "
                           "to a command within %n second(s). This could mean it is stuck "
                           "in an endless loop or taking longer than expected to perform "
                           "the operation.\nYou can choose between waiting "
                           "longer or abort debugging.", 0, timeOut / 1000);
    QMessageBox *pMessageBox = new QMessageBox(QMessageBox::Critical,
                                               QString(Helper::applicationName).append(" - ").append(tr("Debugger not responding")), msg,
                                               QMessageBox::Ok | QMessageBox::Cancel);
    pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
    pMessageBox->button(QMessageBox::Cancel)->setText(tr("Give GDB more time"));
    pMessageBox->button(QMessageBox::Ok)->setText(tr("Stop debugging"));
    if (pMessageBox->exec() == QMessageBox::Ok) {
      /* make sure you don't kill the GDB twice. */
      if (!isGDBKilled()) {
        setGDBKilled(true);
        mpGDBProcess->kill();
      }
    }
  }
}
