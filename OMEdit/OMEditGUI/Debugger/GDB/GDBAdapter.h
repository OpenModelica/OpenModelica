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

#ifndef GDBADAPTER_H
#define GDBADAPTER_H

#include <QPlainTextEdit>
#include <QLineEdit>
#include <QPushButton>
#include <QTextStream>
#include <QProcess>
#include <QDateTime>
#include <QTimer>

#include "Debugger/Parser/GDBMIParser.h"
#include "Debugger/Breakpoints/BreakpointsWidget.h"
#include "Simulation/SimulationOptions.h"

using namespace GDBMIParser;
class BreakpointTreeItem;

class GDBLoggerWidget : public QWidget
{
  Q_OBJECT
public:
  GDBLoggerWidget(QWidget *pParent = 0);
  QPlainTextEdit* getCommandsTextBox() {return mpCommandsTextBox;}
  QPlainTextEdit* getResponseTextBox() {return mpResponseTextBox;}
  QLineEdit* getCommandTextBox() {return mpCommandTextBox;}
  QPushButton* getSendCommandButton() {return mpSendCommandButton;}
  void logDebuggerCommand(QString command);
  void logDebuggerStandardResponse(QString response);
  void logDebuggerErrorResponse(QString response);
private:
  QPlainTextEdit *mpCommandsTextBox;
  QPlainTextEdit *mpResponseTextBox;
  QLineEdit *mpCommandTextBox;
  QPushButton *mpSendCommandButton;

  void logDebuggerResponse(QString response, QColor color);
public slots:
  void postCommand();
  void handleGDBProcessStarted();
  void handleGDBProcessFinished();
};

class TargetOutputWidget : public QPlainTextEdit
{
  Q_OBJECT
public:
  TargetOutputWidget(QWidget *pParent = 0);
  void logDebuggerStandardOutput(QString output);
  void logDebuggerErrorOutput(QString output);
private:
  void logDebuggerOutput(QString output, QColor color);
public slots:
  void handleGDBProcessStarted();
};

class GDBAdapter : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  GDBAdapter(QWidget *pParent = 0);

  static GDBAdapter *mpInstance;
public:
  typedef void (GDBAdapter::*GDBCommandCallback)(GDBMIResultRecord*);
  enum GDBCommandFlag {
    NoFlags = 0,
    ConsoleCommand = 1, // This is a command that needs to be wrapped into -interpreter-exec console
    NonCriticalResponse = 2,
    SilentCommand = 4, // Ignore the error of this command
    BlockUntilResponse = 8 // Blocks until the command has recieved the answer
  };
  Q_DECLARE_FLAGS(GDBCommandFlags, GDBCommandFlag)
  enum ExecuteCommand {
    ExecNext,
    ExecStep
  };

  static GDBAdapter* instance() {return mpInstance;}
  void setExecuteCommand(ExecuteCommand command) {mExecuteCommand = command;}
  ExecuteCommand getExecuteCommand() {return mExecuteCommand;}
  QProcess* getGDBProcess() {return mpGDBProcess;}
  void launch(QString program, QString workingDirectory, QStringList arguments, QString GDBPath,
              SimulationOptions simulationOptions = SimulationOptions());
  void launch(QString processId, QString GDBPath);
  void postCommand(QByteArray command, GDBCommandCallback callback = 0);
  void postCommand(QByteArray command, QObject *pCallbackObject, GDBCommandCallback callback);
  void postCommand(QByteArray command, GDBCommandFlags flags, GDBCommandCallback callback);
  void postCommand(QByteArray command, GDBCommandFlags flags, QObject *pCallbackObject = 0, GDBCommandCallback callback = 0);
  void setGDBRunning(bool running) {mIsRunning = running;}
  bool isGDBRunning() {return mIsRunning;}
  void setGDBKilled(bool killed) {mIsKilled = killed;}
  bool isGDBKilled() {return mIsKilled;}
  void setParsingStandardOutput(bool parsing) {mIsParsingStandardOutput = parsing;}
  bool isParsingStandardOutput() {return mIsParsingStandardOutput;}
  void setInferiorSuspended(bool suspended) {mIsInferiorSuspended = suspended;}
  bool isInferiorSuspended() {return mIsInferiorSuspended;}
  void setInferiorTerminated(bool terminated) {mIsInferiorTerminated = terminated;}
  bool isInferiorTerminated() {return mIsInferiorTerminated;}
  void setInferiorRunning(bool running) {mIsInferiorRunning = running;}
  bool isInferiorRunning() {return mIsInferiorRunning;}
  void setCurrentToken(int token) {mToken = token;}
  int currentToken() {return mToken;}
  void setChangeStdStreamBuffer(bool changeStdStreamBuffer) {mChangeStdStreamBuffer = changeStdStreamBuffer;}
  bool isChangeStdStreamBuffer() {return mChangeStdStreamBuffer;}
  int commandTimeoutTime() const;
  void insertCatchOMCBreakpoint();
  void enableCatchOMCBreakpoint();
  void disableCatchOMCBreakpoint();
  void deleteCatchOMCBreakpoint();
  void stackListFramesCB(GDBMIResultRecord *pGDBMIResultRecord);
  void stackListVariablesCB(GDBMIResultRecord *pGDBMIResultRecord);
  void getTypeOfAnyCB(GDBMIResultRecord *pGDBMIResultRecord);
  void dataEvaluateExpressionCB(GDBMIResultRecord *pGDBMIResultRecord);
  void anyStringCB(GDBMIResultRecord *pGDBMIResultRecord);
  void arrayLengthCB(GDBMIResultRecord *pGDBMIResultRecord);
  void getMetaTypeElementCB(GDBMIResultRecord *pGDBMIResultRecord);
  void isOptionNoneCB(GDBMIResultRecord *pGDBMIResultRecord);
  void createFullBacktraceCB(GDBMIResultRecord *pGDBMIResultRecord);
  void insertBreakpointCB(GDBMIResultRecord *pGDBMIResultRecord);
  GDBMIResult* getGDBMIResult(const char *variable, GDBMIResultList resultsList);
  QString getGDBMIConstantValue(GDBMIResult *pGDBMIResult);
  void insertBreakpoint(BreakpointTreeItem *pBreakpointTreeItem);
  void suspendDebugger();
  void resumeDebugger();
private:
  ExecuteCommand mExecuteCommand;
  QString mAttachToProcessId;
  QProcess *mpGDBProcess;
  QString mGDBProgram;
  QStringList mGDBArguments;
  QStringList mInferiorArguments;
  bool mIsRunning;
  bool mIsKilled;
  QByteArray mStandardOutputBuffer;
  QByteArray mPendingConsoleStreamOutput;
  QByteArray mPendingLogStreamOutput;
  QString mCurrentResponse;
  bool mIsParsingStandardOutput;
  bool mIsInferiorSuspended;
  bool mIsInferiorTerminated;
  bool mIsInferiorRunning;
  int mToken;
  bool mChangeStdStreamBuffer;
  QString mCatchOMCBreakpointId;
  QFile mDebuggerLogFile;
  QTextStream mDebuggerLogFileTextStream;
  SimulationOptions mSimulationOptions;
  QDateTime mResultFileLastModifiedDateTime;

  struct GDBMICommand
  {
    GDBMICommand() {mFlags = 0; mpCallbackObject = 0; mGDBCommandCallback = 0; mCompleted = false;}
    int mFlags;
    QObject *mpCallbackObject;
    GDBCommandCallback mGDBCommandCallback;
    QByteArray mCommand;
    bool mCompleted;
  };
  QHash<int, GDBMICommand> mGDBMICommandsHash;
  QTimer mGDBCommandTimer;

  void handleGDBProcessStartedHelper();
  void writeDebuggerCommandLog(QByteArray command);
  void writeDebuggerResponseLog(QString response);
  void insertBreakpoints();
  void startDebugger();
  void processGDBMIResponse(QString response);
  void processGDBMIOutOfBandRecord(GDBMIOutOfBandRecord *pGDBMIOutOfBandRecord);
  void processGDBMIResultRecord(GDBMIResultRecord *pGDBMIResultRecord);
  void handleGDBMIStreamRecord(GDBMIStreamRecord *pGDBMIStreamRecord);
  void handleGDBMIConsoleStream(GDBMIStreamRecord *pGDBMIStreamRecord);
  void handleGDBMILogStream(GDBMIStreamRecord *pGDBMIStreamRecord);
  bool skipSteppedInFrames(GDBMIResultRecord *pGDBMIResultRecord);
  void handleStoppedEvent(string reason, GDBMIResultRecord *pGDBMIResultRecord);
  void handleBreakpointHit(GDBMIResultRecord *pGDBMIResultRecord);
  void handleSteppingRange(GDBMIResultRecord *pGDBMIResultRecord);
  void handleFunctionFinished(GDBMIResultRecord *pGDBMIResultRecord);
  void handleSignalReceived(GDBMIResultRecord *pGDBMIResultRecord);
  void threadInfoCB(GDBMIResultRecord *pGDBMIResultRecord);
  void attachCB(GDBMIResultRecord *pGDBMIResultRecord);
signals:
  void GDBProcessStarted();
  void GDBProcessFinished();
  void commandCompleted();
  void inferiorSuspended();
  void inferiorResumed();
  void stackListFrames(GDBMIValue *pStackGDBMIValue);
  void threadInfo(GDBMIValue *pThreadsGDBMIValue, QString currentThreadId);
public slots:
  void readGDBStandardOutput();
private slots:
  void handleGDBProcessStarted();
  void handleGDBProcessStartedForSimulation();
  void handleGDBProcessStartedForAttach();
  void readGDBErrorOutput();
  void handleGDBProcessError(QProcess::ProcessError error);
  void handleGDBProcessFinished(int exitCode);
  void handleGDBProcessFinishedForSimulation(int exitCode);
  void GDBcommandTimeout();
};

Q_DECLARE_OPERATORS_FOR_FLAGS(GDBAdapter::GDBCommandFlags)

#endif // GDBADAPTER_H
