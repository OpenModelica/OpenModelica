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

#include <stdexcept>
#include <stdlib.h>
#include <iostream>

#include "OMCProxy.h"
#include "../../../Compiler/runtime/config.h"

/*!
  \class OMCProxy
  \brief It contains the reference of the CORBA object used to communicate with the OpenModelica Compiler.
  */
/*!
  \param pMainWindow - pointer to MainWindow
  */
OMCProxy::OMCProxy(MainWindow *pMainWindow)
  : QObject(pMainWindow), mOMC(0), mHasInitialized(false) ,mResult("")
{
  mpMainWindow = pMainWindow;
  mCurrentCommandIndex = -1;
  // OMC Commands Logger Widget
  mpOMCLoggerWidget = new QWidget;
  mpOMCLoggerWidget->resize(640, 480);
  mpOMCLoggerWidget->setWindowIcon(QIcon(":/Resources/icons/console.png"));
  mpOMCLoggerWidget->setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("OMC Messages Log")));
  // OMC Logger textbox
  mpOMCLoggerTextBox = new QPlainTextEdit();
  mpOMCLoggerTextBox->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpOMCLoggerTextBox->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpOMCLoggerTextBox->setReadOnly(true);
  mpOMCLoggerTextBox->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  mpExpressionTextBox = new CustomExpressionBox(this);
  connect(mpExpressionTextBox, SIGNAL(returnPressed()), SLOT(sendCustomExpression()));
  mpOMCLoggerSendButton = new QPushButton(tr("Send"));
  connect(mpOMCLoggerSendButton, SIGNAL(clicked()), SLOT(sendCustomExpression()));
  // Set the OMC Logger widget Layout
  QHBoxLayout *pHorizontalLayout = new QHBoxLayout;
  pHorizontalLayout->setContentsMargins(0, 0, 0, 0);
  pHorizontalLayout->addWidget(mpExpressionTextBox);
  pHorizontalLayout->addWidget(mpOMCLoggerSendButton);
  QVBoxLayout *pVerticalalLayout = new QVBoxLayout;
  pVerticalalLayout->addWidget(mpOMCLoggerTextBox);
  pVerticalalLayout->addLayout(pHorizontalLayout);
  mpOMCLoggerWidget->setLayout(pVerticalalLayout);
  //start the server
  if(!startServer())      // if we are unable to start OMC. Exit the application.
  {
    mpMainWindow->setExitApplicationStatus(true);
    return;
  }
}

OMCProxy::~OMCProxy()
{
  delete mpOMCLoggerWidget;
}

/*!
  Show/Hide the custom command expression box.
  \param enable - enables/disables the expression text box.
  */
void OMCProxy::enableCustomExpression(bool enable)
{
  if (!enable)
  {
    mpExpressionTextBox->hide();
    mpOMCLoggerSendButton->hide();
  }
}

/*!
  Puts the previous send OMC command in the send command text box.\n
  Invoked by the up arrow key.
  */
void OMCProxy::getPreviousCommand()
{
  if (mCommandsList.isEmpty())
    return;

  mCurrentCommandIndex -= 1;
  if (mCurrentCommandIndex > -1)
  {
    mpExpressionTextBox->setText(mCommandsList.at(mCurrentCommandIndex));
  }
  else
  {
    mCurrentCommandIndex += 1;
  }
}

/*!
  Puts the most recently send OMC command in the send command text box.
  Invoked by the down arrow key.
  */
void OMCProxy::getNextCommand()
{
  if (mCommandsList.isEmpty())
    return;

  mCurrentCommandIndex += 1;
  if (mCurrentCommandIndex < mCommandsList.count())
  {
    mpExpressionTextBox->setText(mCommandsList.at(mCurrentCommandIndex));
  }
  else
  {
    mCurrentCommandIndex -= 1;
  }
}

/*!
  Sets the OMC command expression.
  \param expression
  */
void OMCProxy::setExpression(QString expression)
{
  mExpression = expression;
}

/*!
  Returns the OMC command expression.
  \return expression
  */
QString OMCProxy::getExpression()
{
  return mExpression;
}


/*!
  Writes the commands to the omeditcommands.log file.
  \param expression - the command to write
  \param commandTime - the command start time
  */
void OMCProxy::writeCommandLog(QString expression, QTime* commandTime)
{
  if (mCommandsLogFileTextStream.device())
  {
    mCommandsLogFileTextStream << expression << " " << commandTime->currentTime().toString("hh:mm:ss:zzz");
    mCommandsLogFileTextStream << "\n";
    mCommandsLogFileTextStream.flush();
  }
}

/*!
  Writes the command response to the omeditcommands.log file.
  \param commandTime - the command end time
  */
void OMCProxy::writeCommandResponseLog(QTime* commandTime)
{
  if (mCommandsLogFileTextStream.device())
  {
    mCommandsLogFileTextStream << getResult() << " " << commandTime->currentTime().toString("hh:mm:ss:zzz");
    mCommandsLogFileTextStream << "\n";
    mCommandsLogFileTextStream << "Elapsed Time :: " << QString::number((double)commandTime->elapsed() / 1000).append(" secs");
    mCommandsLogFileTextStream << "\n\n";
    mCommandsLogFileTextStream.flush();
  }
}

/*!
  Returns the cached OMC command from the hash.
  \param className - the name of the class to search for.
  \param command - the command to search for.
  \return the OMC command
  */
cachedOMCCommand OMCProxy::getcachedOMCCommand(QString className, QString command)
{
  if (mCachedOMCCommandsMap.contains(className))
  {
    QList<cachedOMCCommand> commandsList = mCachedOMCCommandsMap.value(className);
    foreach (cachedOMCCommand omcCommand, commandsList)
    {
      if (omcCommand.mOMCCommand.compare(command) == 0)
        return omcCommand;
    }
  }
  return cachedOMCCommand();
}

/*!
  Adds the OMC command to the cached hash.
  \param className - the name of the class.
  \param command - the command.
  \param commandResult - the command result
  */
void OMCProxy::cacheOMCCommand(QString className, QString command, QString commandResult)
{
  /* if the className is already in commands hash */
  if (mCachedOMCCommandsMap.contains(className))
  {
    QList<cachedOMCCommand> commandsList = mCachedOMCCommandsMap.value(className);
    /* if the commands list doesn't contain the command then add it */
    bool found = false;
    foreach (cachedOMCCommand omcCommand, commandsList)
    {
      if (omcCommand.mOMCCommand.compare(command) == 0)
      {
        found = true;
        break;
      }
    }
    if (!found)
    {
      cachedOMCCommand omcCommand;
      omcCommand.mOMCCommand = command;
      omcCommand.mOMCCommandResult = commandResult;
      commandsList.append(omcCommand);
      mCachedOMCCommandsMap.insert(className, commandsList);
    }
  }
  else
  {
    QList<cachedOMCCommand> commandsList;
    cachedOMCCommand omcCommand;
    omcCommand.mOMCCommand = command;
    omcCommand.mOMCCommandResult = commandResult;
    commandsList.append(omcCommand);
    mCachedOMCCommandsMap.insert(className, commandsList);
  }
}

/*!
  Removes the OMC command from the cached hash.
  \param className - the name of the class.
  */
void OMCProxy::removeCachedOMCCommand(QString className)
{
  mCachedOMCCommandsMap.remove(className);
}

/*!
  Starts the OpenModelica Compiler.\n
  On Windows look for OPENMODELICAHOME environment variable. On Linux read the installation directory from config.h file.\n
  Runs the omc with +c and +d=interactiveCorba flags.\n
  +c flag creates a CORBA IOR file with name e.g openmodelica.objid.OMEdit{1ABB3DAA-C925-47E8-85F9-3DE6F3F7E79C}154302842\n
  +corbaObjectReferenceFilePath sets the path for CORBA object reference file.\n
  For each instance of OMEdit a new omc is run.
  */
bool OMCProxy::startServer()
{
  /* create the tmp path */
  QString tmpPath = QDir::tempPath() + "/OpenModelica/OMEdit/";
  tmpPath.remove("\"");
  if (!QDir().exists(tmpPath))
    QDir().mkpath(tmpPath);
  /* create a file to write OMEdit commands log */
  mCommandsLogFile.setFileName(tmpPath + QDir::separator() + "omeditcommands.log");
  if (mCommandsLogFile.open(QIODevice::WriteOnly | QIODevice::Text))
  {
    mCommandsLogFileTextStream.setDevice(&mCommandsLogFile);
  }
  try
  {
    QString msg;
    const char *omhome = getenv("OPENMODELICAHOME");
    QString omcPath;
#ifdef WIN32
    if (!omhome)
      throw std::runtime_error(GUIMessages::getMessage(GUIMessages::OPENMODELICAHOME_NOT_FOUND).toStdString());
    omcPath = QString( omhome ) + "/bin/omc.exe";
#else /* unix */
    omcPath = (omhome ? QString(omhome)+"/bin/omc" : QString(CONFIG_DEFAULT_OPENMODELICAHOME) + "/bin/omc");
#endif
    // Check the IOR file created by omc.exe
    QFile objectRefFile;
    QString fileIdentifier;
    fileIdentifier = qApp->sessionId().append(QTime::currentTime().toString("hh:mm:ss:zzz").remove(":"));
#ifdef WIN32 // Win32
    objectRefFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.objid.").append(Helper::OMCServerName).append(fileIdentifier));
#else // UNIX environment
    char *user = getenv("USER");
    if (!user) { user = "nobody"; }
    objectRefFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.").append(*(new QString(user))).append(".objid.").append(Helper::OMCServerName).append(fileIdentifier));
#endif
    if (objectRefFile.exists())
      objectRefFile.remove();
    mObjectRefFile = objectRefFile.fileName();
    // read the locale
    QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
    QLocale settingsLocale = QLocale(settings.value("language").toString());
    settingsLocale = settingsLocale.name() == "C" ? settings.value("language").toLocale() : settingsLocale;
    // Start the omc.exe
    QStringList parameters;
    parameters << QString("+c=").append(Helper::OMCServerName).append(fileIdentifier)
               << QString("+d=interactiveCorba")
               << QString("+corbaObjectReferenceFilePath=").append(QDir::tempPath())
               << QString("+locale=").append(settingsLocale.name());
    QProcess *omcProcess = new QProcess;
    connect(omcProcess, SIGNAL(finished(int)), omcProcess, SLOT(deleteLater()));
    QFile omcOutputFile;
#ifdef WIN32 // Win32
    omcOutputFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("OpenModelica/OMEdit/openmodelica.omc.output.").append(Helper::OMCServerName));
#else // UNIX environment
    omcOutputFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("OpenModelica/OMEdit/openmodelica.").append(*(new QString(user))).append(".omc.output.").append(Helper::OMCServerName));
#endif
    omcProcess->setProcessChannelMode(QProcess::MergedChannels);
    omcProcess->setStandardOutputFile(omcOutputFile.fileName());
    omcProcess->start(omcPath, parameters);
    // wait for the server to start.
    int ticks = 0;
    while (!objectRefFile.exists())
    {
      Sleep::sleep(1);
      ticks++;
      if (ticks > 20)
      {
        msg = "Unable to find " + Helper::applicationName + " server, Object reference file " + mObjectRefFile + " not created.";
        throw std::runtime_error(msg.toStdString());
      }
    }
    // ORB initialization.
    int argc = 2;
    static const char *argv[] = {"-ORBgiopMaxMsgSize", "2147483647"};
    CORBA::ORB_var orb = CORBA::ORB_init(argc, (char **)argv);
    objectRefFile.open(QIODevice::ReadOnly);
    char buf[1024];
    objectRefFile.readLine( buf, sizeof(buf) );
    QString uri( (const char*)buf );
    CORBA::Object_var obj = orb->string_to_object(uri.trimmed().toLocal8Bit());
    mOMC = OmcCommunication::_narrow(obj);
    mHasInitialized = true;
  }
  catch (std::exception &e)
  {
    QString msg = e.what();
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),msg.append("\n\n")
                          .append(Helper::applicationName).append(tr(" will close.")), Helper::ok);
    mHasInitialized = false;
    return false;
  }
  catch (CORBA::Exception&)
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          QString(tr("Unable to communicate with OpenModelica Compiler.")).append("\n\n").append(Helper::applicationName)
                          .append(" will close."), Helper::ok);
    mHasInitialized = false;
    return false;
  }
  // set OpenModelicaHome variable
  sendCommand("getInstallationDirectoryPath()");
  Helper::OpenModelicaHome = StringHandler::removeFirstLastQuotes(getResult());
  /* set the tmp directory as the working directory */
  changeDirectory(tmpPath);
  // set the OpenModelicaLibrary variable.
  Helper::OpenModelicaLibrary = getModelicaPath();
  return true;
}

/*!
  Stops the OpenModelica Compiler. Kill the process omc and also deletes the CORBA reference file.
  \see startServer
  */
void OMCProxy::stopServer()
{
  sendCommand("quit()");
  mCommandsLogFile.close();
}

/*!
  Sends the user commands to OMC.
  \param expression - is used to send command as a string.
  \param cacheCommand - is used to cache the OMC command.
  \param className - the class name to store the cache command with.
  \param dontUseCachedCommand - flag used to check whether we want to use cached command or not.
  \see sendCommand()
  */
void OMCProxy::sendCommand(const QString expression, bool cacheCommand, QString className, bool dontUseCachedCommand)
{
  if (!mHasInitialized)
    if(!startServer())      // if we are unable to start OMC. Exit the application.
    {
      mpMainWindow->setExitApplicationStatus(true);
      return;
    }
  /* if OMC command is find in the cached OMC commands then use it and return. */
  if (!dontUseCachedCommand)
  {
    cachedOMCCommand pOMCCommand = getcachedOMCCommand(className, expression);
    if (!pOMCCommand.mOMCCommandResult.isEmpty())
    {
      setResult(pOMCCommand.mOMCCommandResult);
      // write command to the commands log.
      QTime commandTime;
      commandTime.start();
      QString cacheString = QString("Using the cached OMC Command :: ");
      writeCommandLog(QString(cacheString).append(expression), &commandTime);
      logOMCMessages(QString(cacheString).append(expression));
      return;
    }
  }
  // write command to the commands log.
  QTime commandTime;
  commandTime.start();
  writeCommandLog(expression, &commandTime);
  // Send command to server
  try
  {
    setExpression(expression);
    QFuture<void> future = QtConcurrent::run(this, &OMCProxy::sendCommand);
    QEventLoop eventLoop;
    QTimer timer;
    connect(&timer, SIGNAL(timeout()), &eventLoop, SLOT(quit()));
    connect(this, SIGNAL(commandFinished()), &eventLoop, SLOT(quit()));
    timer.start(10);
    while (future.isRunning())
    {
      eventLoop.exec(QEventLoop::ExcludeUserInputEvents);
      qApp->processEvents(QEventLoop::ExcludeUserInputEvents);
    }
    timer.stop();
    future.waitForFinished();
    writeCommandResponseLog(&commandTime);
    logOMCMessages(expression);
    // cahce the OMC command
    if (cacheCommand)
      cacheOMCCommand(className, expression, getResult());
  }
  catch (QtConcurrent::Exception&)
  {
    // if the command is quit() and we get exception just simply quit
    if (expression == "quit()")
      return;
    exitApplication();
  }
  catch (CORBA::Exception&)
  {
    // if the command is quit() and we get exception just simply quit
    if (expression == "quit()")
      return;
    exitApplication();
  }
}

/*!
  Sends the user commands to OMC by using the Qt::concurrent feature.
  \see sendCommand(const QString expression)
  */
void OMCProxy::sendCommand()
{
  mResult = QString::fromLocal8Bit(mOMC->sendExpression(getExpression().toLocal8Bit()));
  emit commandFinished();
}

/*!
  Sets the command result.
  \param value the command result.
  */
void OMCProxy::setResult(QString value)
{
  mResult = value;
}

/*!
  Returns the result obtained from OMC.
  \return the command result.
  */
QString OMCProxy::getResult()
{
  return mResult.trimmed();
}

/*!
  Writes OMC messages in OMC Logger window.
  */
void OMCProxy::logOMCMessages(QString expression)
{
  // move the cursor down before adding to the logger.
  QTextCursor textCursor = mpOMCLoggerTextBox->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // add the expression to commands list
  mCommandsList.append(expression);
  // log expression
  QFont font(Helper::monospacedFontInfo.family(), Helper::monospacedFontInfo.pointSize() - 2, QFont::Bold, false);
  QTextCharFormat charFormat = mpOMCLoggerTextBox->currentCharFormat();
  charFormat.setFont(font);
  mpOMCLoggerTextBox->setCurrentCharFormat(charFormat);
  mpOMCLoggerTextBox->insertPlainText(expression + "\n");
  // log result
  font = QFont(Helper::monospacedFontInfo.family(), Helper::monospacedFontInfo.pointSize() - 2, QFont::Normal, false);
  charFormat.setFont(font);
  mpOMCLoggerTextBox->setCurrentCharFormat(charFormat);
  mpOMCLoggerTextBox->insertPlainText(getResult() + "\n\n");
  // move the cursor
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // set the current command index.
  mCurrentCommandIndex = mCommandsList.count();
  mpExpressionTextBox->setText("");
}

/*!
  Opens the OMC Logger widget.
  */
void OMCProxy::openOMCLoggerWidget()
{
  mpExpressionTextBox->setFocus(Qt::ActiveWindowFocusReason);
  mpOMCLoggerWidget->show();
  mpOMCLoggerWidget->raise();
  mpOMCLoggerWidget->activateWindow();
  mpOMCLoggerWidget->setWindowState(mpOMCLoggerWidget->windowState() & ~Qt::WindowMinimized | Qt::WindowActive);
}

/*!
  Sends the command written in the OMC Logger textbox.
  */
void OMCProxy::sendCustomExpression()
{
  if (mpExpressionTextBox->text().isEmpty())
    return;

  sendCommand(mpExpressionTextBox->text());
  mpExpressionTextBox->setText(QString());
}

/*!
  Removes the CORBA IOR file. We only call this method when we are unable to connect to OMC.\n
  In normal case OMCProxy::stopServer will delete that file.
  */
void OMCProxy::removeObjectRefFile()
{
  QFile::remove(mObjectRefFile);
}

/*!
  Removes the CORBA IOR file.\n
  Shows an error message that OMEdit connection with OMC is lost and exit the application.
  \see OMCProxy::removeObjectRefFile()
  */
void OMCProxy::exitApplication()
{
  removeObjectRefFile();
  QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                        QString(tr("Connection with the OpenModelica Compiler has been lost."))
                        .append("\n\n").append(Helper::applicationName).append(" will close."), Helper::ok);
  exit(EXIT_FAILURE);
}

/*!
  Returns the OMC error string.
  \return the error string.
  \deprecated Use printMessagesStringInternal()
  */
QString OMCProxy::getErrorString()
{
  sendCommand("getErrorString()");
  return StringHandler::unparse(getResult());
}

/*!
  Gets the errors by using the getMessagesStringInternal API.
  Reads all the errors and add them to the Messages Window.
  \see MessageWidget::addGUIMessage
  \see MessageTreeItem
  \return true if there are any errors otherwise false.'
  */
bool OMCProxy::printMessagesStringInternal()
{
  int errorsSize = getMessagesStringInternal();
  bool returnValue = errorsSize > 0 ? true : false;

  for (int i = 1; i <= errorsSize ; i++)
  {
    setCurrentError(i);
    MessagesTreeItem *pMessageItem = new MessagesTreeItem(mpMainWindow->getMessagesWidget()->getMessagesTreeWidget());
    pMessageItem->setFileName(getErrorFileName());
    pMessageItem->setReadOnly(getErrorReadOnly());
    pMessageItem->setLineStart(getErrorLineStart());
    pMessageItem->setColumnStart(getErrorColumnStart());
    pMessageItem->setLineEnd(getErrorLineEnd());
    pMessageItem->setColumnEnd(getErrorColumnEnd());
    pMessageItem->setMessage(getErrorMessage());
    pMessageItem->setKind(getErrorKind());
    pMessageItem->setLevel(getErrorLevel());
    pMessageItem->setId(getErrorId());
    pMessageItem->setColumnsText();
    mpMainWindow->getMessagesWidget()->addGUIMessage(pMessageItem);
  }
  return returnValue;
}

/*!
  Retrieves the list of errors from OMC
  \return size of errors
  */
int OMCProxy::getMessagesStringInternal()
{
  sendCommand("errors:=getMessagesStringInternal()");
  sendCommand("size(errors,1)");
  return getResult().toInt();
}

/*!
  Sets the current error.
  \param int the error index
  */
void OMCProxy::setCurrentError(int errorIndex)
{
  sendCommand("currentError:=errors[" + QString::number(errorIndex) + "]");
}

/*!
  Gets the error file name from current error.
  \return the error file name
  */
QString OMCProxy::getErrorFileName()
{
  sendCommand("currentError.info.filename");
  QString file = StringHandler::unparse(getResult());
  if (file.compare("<interactive>") == 0)
    return "";
  else
    return file;
}

/*!
  Gets the error read only state from current error.
  \return the error read only state
  */
bool OMCProxy::getErrorReadOnly()
{
  sendCommand("currentError.info.readonly");
  return StringHandler::unparseBool(StringHandler::unparse(getResult()));
}

/*!
  Gets the error line start index from current error.
  \return the error line start index
  */
int OMCProxy::getErrorLineStart()
{
  sendCommand("currentError.info.lineStart");
  return getResult().toInt();
}

/*!
  Gets the error column start index from current error.
  \return the error column start index
  */
int OMCProxy::getErrorColumnStart()
{
  sendCommand("currentError.info.columnStart");
  return getResult().toInt();
}

/*!
  Gets the error line end index from current error.
  \return the error line end index
  */
int OMCProxy::getErrorLineEnd()
{
  sendCommand("currentError.info.lineEnd");
  return getResult().toInt();
}

/*!
  Gets the error column end index from current error.
  \return the error column end index
  */
int OMCProxy::getErrorColumnEnd()
{
  sendCommand("currentError.info.columnEnd");
  return getResult().toInt();
}

/*!
  Gets the error message from current error.
  \return the error message
  */
QString OMCProxy::getErrorMessage()
{
  sendCommand("currentError.message");
  return StringHandler::unparse(getResult());
}

/*!
  Gets the error kind from current error.
  \return the error kind
  */
QString OMCProxy::getErrorKind()
{
  sendCommand("currentError.kind");
  return getResult();
}

/*!
  Gets the error level from current error.
  \return the error level
  */
QString OMCProxy::getErrorLevel()
{
  sendCommand("currentError.level");
  return getResult();
}

/*!
  Gets the error id from current error.
  \return the error id
  */
int OMCProxy::getErrorId()
{
  sendCommand("currentError.id");
  return getResult().toInt();
}

/*!
  Gets the OMC version. On Linux it also return the revision number as well.
  \return the version
  */
QString OMCProxy::getVersion()
{
  sendCommand("getVersion()");
  return StringHandler::unparse(getResult());
}

/*!
  Gets the OMC annotation version
  \return the annotation version
  */
QString OMCProxy::getAnnotationVersion()
{
  sendCommand("getAnnotationVersion()");
  return getResult();
}

/*!
  Sends OMC setEnvironmentVar command.
  \param name - the variable name
  \param value - the variable value
  \return true on success
  */
bool OMCProxy::setEnvironmentVar(QString name, QString value)
{
  sendCommand("setEnvironmentVar(\"" + name + "\", \"" + value + "\")");
  if (getResult().toLower().contains("ok"))
    return true;
  else
    return false;
}

/*!
  Gets OMC getEnvironmentVar command.
  \param name - the variable name
  \return the environment variable value.
  */
QString OMCProxy::getEnvironmentVar(QString name)
{
  sendCommand("getEnvironmentVar(\"" + name + "\")");
  return getResult();
}

/*!
  Loads the Modelica System Libraries.\n
  Reads the omedit.ini file to get the libraries to load.
  */
void OMCProxy::loadSystemLibraries(QSplashScreen *pSplashScreen)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  bool forceModelicaLoad = true;
  if (settings.contains("forceModelicaLoad"))
    forceModelicaLoad = settings.value("forceModelicaLoad").toBool();
  settings.beginGroup("libraries");
  QStringList libraries = settings.childKeys();
  /*
    Only force loading of Modelica & ModelicaReference if user is using OMEdit for the first time.
    Later user must use the libraries options dialog.
    */
  if (forceModelicaLoad)
  {
    if (!settings.contains("Modelica"))
    {
      settings.setValue("Modelica","default");
      libraries.prepend("Modelica");
    }
    if (!settings.contains("ModelicaReference"))
    {
      settings.setValue("ModelicaReference","default");
      libraries.prepend("ModelicaReference");
    }
  }
  foreach (QString lib, libraries)
  {
    pSplashScreen->showMessage(QString(Helper::loading).append(" ").append(lib), Qt::AlignRight, Qt::white);
    QString version = settings.value(lib).toString();
    loadModel(lib, version);
  }
  settings.endGroup();
  mpMainWindow->getOptionsDialog()->readLibrariesSettings();
}

/*!
  Loads the Modelica User Libraries.
  Reads the omedit.ini file to get the libraries to load.
  */
void OMCProxy::loadUserLibraries(QSplashScreen *pSplashScreen)
{
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  settings.beginGroup("userlibraries");
  QStringList libraries = settings.childKeys();
  foreach (QString lib, libraries)
  {
    QString encoding = settings.value(lib).toString();
    QString fileName = QUrl::fromPercentEncoding(QByteArray(lib.toStdString().c_str()));
    pSplashScreen->showMessage(QString(Helper::loading).append(" ").append(fileName), Qt::AlignRight, Qt::white);
    if (parseFile(fileName, encoding))
    {
      QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
      QStringList modelsList = result.split(",", QString::SkipEmptyParts);
      /*
        Only allow loading of files that has just one nonstructured entity.
        From Modelica specs section 13.2.2.2,
        "A nonstructured entity [e.g. the file A.mo] shall contain only a stored-definition that defines a class [A] with a name
         matching the name of the nonstructured entity."
        */
      if (modelsList.size() > 1)
      {
        QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
        pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
        pMessageBox->setIcon(QMessageBox::Critical);
        pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
        pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(fileName)
                                        .arg(modelsList.join(",")));
        pMessageBox->setStandardButtons(QMessageBox::Ok);
        pMessageBox->exec();
        return;
      }
      QStringList existingmodelsList;
      bool existModel = false;
      // check if the model already exists
      foreach(QString model, modelsList)
      {
        if (existClass(model))
        {
          existingmodelsList.append(model);
          existModel = true;
        }
      }
      // if existModel is true, show user an error message
      if (existModel)
      {
        QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
        pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
        pMessageBox->setIcon(QMessageBox::Information);
        pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(encoding)));
        pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                        .arg(existingmodelsList.join(",")).append("\n")
                                        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(encoding)));
        pMessageBox->setStandardButtons(QMessageBox::Ok);
        pMessageBox->exec();
      }
      // if no conflicting model found then just load the file simply
      else
      {
        loadFile(fileName, encoding);
      }
    }
  }
  settings.endGroup();
}

/*!
  Gets the list of classes from OMC.
  \param className - is the name of the class whose sub classes are retrieved.
  \param recursive - recursively retrieve all the sub classes.
  \param qualified - returns the class names as qualified path.
  \param showProtected - returns the protected classes as well.
  \return the list of classes
  */
QStringList OMCProxy::getClassNames(QString className, QString recursive, QString qualified, QString showProtected)
{
  if (className.isEmpty())
    sendCommand("getClassNames(recursive=" + recursive + ",qualified=" + qualified + ",showProtected=" + showProtected + ")");
  else
    sendCommand("getClassNames(" + className + ",recursive=" + recursive + ",qualified=" + qualified + ",showProtected=" + showProtected + ")");
  QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
  QStringList list = result.split(",", QString::SkipEmptyParts);
  return list;
}

/*!
  Searches the list of classes from OMC.
  \param searchText - is the text to search for.
  \param findInText - tells to look for the searchText inside Modelica Text also.
  \return the list of searched classes.
  */
QStringList OMCProxy::searchClassNames(QString searchText, QString findInText)
{
  sendCommand("searchClassNames(\"" + searchText + "\", findInText=" + findInText + ")");
  QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
  QStringList list = result.split(",", QString::SkipEmptyParts);
  return list;
}

/*!
  Gets the information about the class.
  \param className - is the name of the class whose information is retrieved.
  \return the class information list.
  */
QStringList OMCProxy::getClassInformation(QString className)
{
  sendCommand("getClassInformation(" + className + ")", true, className);
  QString result = getResult();
  QStringList list = StringHandler::unparseStrings(result);
  return list;
}

/*!
  Checks whether the class is a package or not.
  \param className - is the name of the class which is checked.
  \return true if the class is a pacakge otherwise false
  */
bool OMCProxy::isPackage(QString className)
{
  sendCommand("isPackage(" + className + ")", true, className);
  if (getResult().contains("true"))
  {
    return true;
  }
  else
  {
    return false;
  }
}

/*!
  Returns true if the given type is one of the predefined types in Modelica.
  */
bool OMCProxy::isBuiltinType(QString typeName)
{
  return (typeName == "Real" ||
          typeName == "Integer" ||
          typeName == "String" ||
          typeName == "Boolean");
}

/*!
  Checks the class type.
  \param type - the type to check.
  \param className - the class to check.
  \return true if the class is a specified type
  */
bool OMCProxy::isWhat(int type, QString className)
{
  switch (type)
  {
    case StringHandler::Model:
      sendCommand("isModel(" + className + ")", true, className);
      break;
    case StringHandler::Class:
      sendCommand("isClass(" + className + ")", true, className);
      break;
    case StringHandler::Connector:
      sendCommand("isConnector(" + className + ")", true, className);
      break;
    case StringHandler::Record:
      sendCommand("isRecord(" + className + ")", true, className);
      break;
    case StringHandler::Block:
      sendCommand("isBlock(" + className + ")", true, className);
      break;
    case StringHandler::Function:
      sendCommand("isFunction(" + className + ")", true, className);
      break;
    case StringHandler::Package:
      sendCommand("isPackage(" + className + ")", true, className);
      break;
    case StringHandler::Type:
      sendCommand("isType(" + className + ")", true, className);
      break;
    case StringHandler::Operator:
      sendCommand("isOperator(" + className + ")", true, className);
      break;
    case StringHandler::OperatorRecord:
      sendCommand("isOperatorRecord(" + className + ")", true, className);
      break;
    case StringHandler::OperatorFunction:
      sendCommand("isOperatorFunction(" + className + ")", true, className);
      break;
    case StringHandler::Optimization:
      sendCommand("isOptimization(" + className + ")", true, className);
      break;
    default:
      return false;
  }
  return StringHandler::unparseBool(getResult());
}

/*!
  Checks whether the class parameter is protected or not.
  \param className - is the name of the class.
  \param parameter - is the parameter to check.
  \return true if the parameter is protected otherwise false
  */
bool OMCProxy::isProtected(QString parameter, QString className)
{
  sendCommand("isProtected(" + parameter + "," + className + ")", true, className);
  return StringHandler::unparseBool(getResult());
}

/*!
  Checks whether the nested class is protected or not.
  \param className - is the name of the class.
  \param nestedClassName - is the nested class to check.
  \return true if the nested class is protected otherwise false
  */
bool OMCProxy::isProtectedClass(QString className, QString nestedClassName)
{
  sendCommand("isProtectedClass(" + className + ",\"" + nestedClassName + "\")", true, className);
  return StringHandler::unparseBool(getResult());
}

/*!
  Checks whether the class is partial or not.
  \param className - is the name of the class.
  \return true if the class is partial otherwise false
  */
bool OMCProxy::isPartial(QString className)
{
  sendCommand("isPartial(" + className + ")", true, className);
  return StringHandler::unparseBool(getResult());
}

/*!
  Gets the class type.
  \param className - is the name of the class to check.
  \return the class type.
  */
StringHandler::ModelicaClasses OMCProxy::getClassRestriction(QString className)
{
  sendCommand("getClassRestriction(" + className + ")", true, className);

  if (getResult().toLower().contains("model"))
    return StringHandler::Model;
  else if (getResult().toLower().contains("class"))
    return StringHandler::Class;
  //! @note Also handles the expandable connectors i.e we return StringHandler::CONNECTOR for expandable connectors.
  else if (getResult().toLower().contains("connector"))
    return StringHandler::Connector;
  else if (getResult().toLower().contains("record"))
    return StringHandler::Record;
  else if (getResult().toLower().contains("block"))
    return StringHandler::Block;
  else if (getResult().toLower().contains("function"))
    return StringHandler::Function;
  else if (getResult().toLower().contains("package"))
    return StringHandler::Package;
  else if (getResult().toLower().contains("type"))
    return StringHandler::Type;
  else if (getResult().toLower().contains("operator"))
    return StringHandler::Operator;
  else if (getResult().toLower().contains("operator record"))
    return StringHandler::OperatorRecord;
  else if (getResult().toLower().contains("operator function"))
    return StringHandler::OperatorFunction;
  else if (getResult().toLower().contains("optimization"))
    return StringHandler::Optimization;
  else
    return StringHandler::Model;
}

/*!
  Gets the parameter names.
  \param className - is the name of the class whose parameter names are retrieved.
  \return the list of parameter names.
  */
QStringList OMCProxy::getParameterNames(QString className)
{
  QString result;
  QString expression = "getParameterNames(" + className + ")";
  sendCommand(expression, true, className);
  result = StringHandler::removeFirstLastCurlBrackets(getResult());
  if (result.isEmpty())
    return QStringList();
  else
  {
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
  }
}

/*!
  Gets the parameter value.
  \param className - is the name of the class whose parameter value is retrieved.
  \return the parameter value.
  */
QString OMCProxy::getParameterValue(QString className, QString parameter)
{
  sendCommand("getParameterValue(" + className + "," + parameter + ")", true, className);
  return getResult();
}

/*!
  Sets the parameter value.
  \param className - is the name of the class whose parameter value is set.
  \param parameter - is the name of the parameter whose value is set.
  \param value - is the value to set.
  \return true on success
  */
bool OMCProxy::setParameterValue(QString className, QString parameter, QString value)
{
  sendCommand("setParameterValue(" + className + "," + parameter + "," + value + ")");
  if (getResult().contains("Ok"))
    return true;
  else
    return false;
}

/*!
  Gets the list of component modifier names.
  \param className - is the name of the class whose modifier names are retrieved.
  \param name - is the name of the component.
  \return the list of modifier names
  */
QStringList OMCProxy::getComponentModifierNames(QString className, QString name)
{
  sendCommand("getComponentModifierNames(" + className + "," + name + ")", true, className);
  QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
  QStringList list = result.split(",", QString::SkipEmptyParts);
  return list;
}

/*!
  Gets the component modifier value.
  \param className - is the name of the class whose modifier value is retrieved.
  \param name - is the name of the component.
  \return the value of modifier.
  */
QString OMCProxy::getComponentModifierValue(QString className, QString name)
{
  sendCommand("getComponentModifierValue(" + className + "," + name + ")", true, className);
  return StringHandler::getModifierValue(getResult()).trimmed();
}

/*!
  Sets the component modifier value.
  \param className - is the name of the class whose modifier value is set.
  \param name - is the name of the modifier whose value is set.
  \param value - is the value to set.
  \return true on success.
  */
bool OMCProxy::setComponentModifierValue(QString className, QString modifierName, QString modifierValue)
{
  if (modifierValue.compare("=") == 0)
    sendCommand("setComponentModifierValue(" + className + "," + modifierName + ", $Code(()))");
  else
    sendCommand("setComponentModifierValue(" + className + "," + modifierName + ", $Code(" + modifierValue + "))");
  if (getResult().toLower().contains("ok"))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

QStringList OMCProxy::getExtendsModifierNames(QString className, QString extendsClassName)
{
  sendCommand("getExtendsModifierNames(" + className + "," + extendsClassName + ", useQuotes = true)", true, className);
  return StringHandler::unparseStrings(getResult());
}

/*!
  Gets the extends class modifier value.
  \param className - is the name of the class.
  \param extendsClassName - is the name of the extends class whose modifier value is retrieved.
  \param modifierName - is the name of the modifier.
  \return the value of modifier.
  */
QString OMCProxy::getExtendsModifierValue(QString className, QString extendsClassName, QString modifierName)
{
  sendCommand("getExtendsModifierValue(" + className + "," + extendsClassName + "," + modifierName + ")", true, className);
  return StringHandler::getModifierValue(getResult()).trimmed();
}

bool OMCProxy::setExtendsModifierValue(QString className, QString extendsClassName, QString modifierName, QString modifierValue)
{
  if (modifierValue.compare("=") == 0)
    sendCommand("setExtendsModifierValue(" + className + "," + extendsClassName + "," + modifierName + ", $Code(()))");
  else
    sendCommand("setExtendsModifierValue(" + className + "," + extendsClassName + "," + modifierName + ", $Code(" + modifierValue + "))");
  if (getResult().toLower().contains("ok"))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Gets the Icon Annotation of a specified class from OMC.
  \param className - is the name of the class.
  \return the icon annotation.
  */
QString OMCProxy::getIconAnnotation(QString className)
{
  QString expression = "getIconAnnotation(" + className + ")";
  sendCommand(expression, true, className);
  return getResult();
}

/*!
  Gets the Diagram Annotation of a specified class from OMC.
  \param className - is the name of the class.
  \return the diagram annotation.
  */
QString OMCProxy::getDiagramAnnotation(QString className)
{
  QString expression = "getDiagramAnnotation(" + className + ")";
  sendCommand(expression, true, className);
  return getResult();
}

/*!
  Gets the number of connection from a model.
  \param className - is the name of the model.
  \return the number of connections.
  */
int OMCProxy::getConnectionCount(QString className)
{
  QString expression = "getConnectionCount(" + className + ")";
  sendCommand(expression, true, className);
  QString result = getResult();
  if (!result.isEmpty())
  {
    bool ok;
    int result_number = result.toInt(&ok);
    if (ok)
      return result_number;
    else
      return 0;
  }
  else
    return 0;
}

/*!
  Returns the connection at a specific index from a model.
  \param className - is the name of the model.
  \param num - is the index of connection.
  \return the connection
  */
QString OMCProxy::getNthConnection(QString className, int num)
{
  QString expression = "getNthConnection(" + className + ", " + QString::number(num) + ")";
  sendCommand(expression, true, className);
  return getResult();
}

/*!
  Returns the connection annotation at a specific index from a model.
  \param className - is the name of the model.
  \param num - is the index of connection annotation.
  \return the connection annotation
  */
QString OMCProxy::getNthConnectionAnnotation(QString className, int num)
{
  QString expression = "getNthConnectionAnnotation(" + className + ", " + QString::number(num) + ")";
  sendCommand(expression, true, className);
  return getResult();
}

/*!
  Returns the inheritance count of a model.
  \param className - is the name of the model.
  \return the inheritance count
  */
int OMCProxy::getInheritanceCount(QString className)
{
  QString expression = "getInheritanceCount(" + className + ")";
  sendCommand(expression, true, className);
  QString result = getResult();
  if (!result.isEmpty())
  {
    bool ok;
    int result_number = result.toInt(&ok);
    if (ok)
      return result_number;
    else
      return 0;
  }
  else
    return 0;
}

/*!
  Returns the inherited class at a specific index from a model.
  \param className - is the name of the model.
  \param num - is the index of inherited class.
  \return the inherited class.
  */
QString OMCProxy::getNthInheritedClass(QString className, int num)
{
  QString expression = "getNthInheritedClass(" + className + ", " + QString::number(num) + ")";
  sendCommand(expression, true, className);
  return getResult();
}

/*!
  Returns the components of a model with their attributes.\n
  Creates an object of ComponentInfo for each component.
  \param className - is the name of the model.
  \return the list of components
  */
QList<ComponentInfo*> OMCProxy::getComponents(QString className)
{
  QString expression = "getComponents(" + className + ", useQuotes = true)";
  sendCommand(expression, true, className);
  QString result = getResult();
  QList<ComponentInfo*> componentInfoList;
  QStringList list = StringHandler::unparseArrays(result);

  for (int i = 0 ; i < list.size() ; i++)
  {
    if (list.at(i) == "Error")
      continue;
    componentInfoList.append(new ComponentInfo(list.at(i)));
  }

  return componentInfoList;
}

/*!
  Returns the component annotations of a model.
  \param className - is the name of the model.
  \return the list of component annotations.
  */
QStringList OMCProxy::getComponentAnnotations(QString className)
{
  QString expression = "getComponentAnnotations(" + className + ")";
  sendCommand(expression, true, className);
  return StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(getResult()));
}

/*!
  Returns the documentation annotation of a model.\n
  The documenation is not standardized, so for any non-standard html documentation add <pre></pre> tags.
  \param className - is the name of the model.
  \return the documentation.
  */
QString OMCProxy::getDocumentationAnnotation(QString className)
{
  QString expression = "getDocumentationAnnotation(" + className + ")";
  sendCommand(expression, true, className);
  QStringList docsList = StringHandler::unparseStrings(getResult());
  // get the class comment and show it as the first line on the documentation page.
  QString doc = getClassComment(className);
  if (!doc.isEmpty()) doc.prepend("<h4>").append("</h4>");
  doc.prepend(QString("<h2>").append(className).append("</h2>"));
  for (int ele = 0 ; ele < docsList.size() ; ele++)
  {
    QString docElement = docsList[ele];
    if (docElement.isEmpty())
      continue;
    if (ele == 0)         // info section
      doc += "<p style=\"font-size:12px;\"><strong><u>Information</u></strong></p>";
    else if (ele == 1)    // revisions section
      doc += "<p style=\"font-size:12px;\"><strong><u>Revisions</u></strong></p>";
    int i,j;
    /*
       * Documentation may have the form
       * text <HTML>...</html> text <html>...</HTML> [...]
       * Nothing is standardized, but we will treat non-html tags as <pre>-formatted text
       */
    while (1) {
      docElement = docElement.trimmed();
      i = docElement.indexOf("<html>", 0, Qt::CaseInsensitive);
      if (i == -1) break;
      if (i != 0) {
        doc += "<pre>" + docElement.left(i).replace("<","&lt;").replace(">","&gt;") + "</pre>";
        docElement = docElement.remove(i);
      }
      j = docElement.indexOf("</html>", 0, Qt::CaseInsensitive);
      if (j == -1) break;
      doc += docElement.leftRef(j+7);
      docElement = docElement.mid(j+7,-1);
    }
    if (docElement.length()) {
      doc += "<pre>" + docElement.replace("<","&lt;").replace(">","&gt;") + "</pre>";
    }
  }
  return makeDocumentationImagesUriToFileName(doc);
}

/*!
  Gets the class comment.
  \param className - is the name of the class.
  \return class comment.
  */
QString OMCProxy::getClassComment(QString className)
{
  sendCommand("getClassComment(" + className + ")", true, className);
  return StringHandler::unparse(getResult());
}

/*!
  Change the current working directory of OMC. Also retunrs the current working directory.
  \param directory - the new working directory location.
  \return the current working directory
  */
QString OMCProxy::changeDirectory(QString directory)
{
  if (directory.isEmpty())
  {
    sendCommand("cd()");
  }
  else
  {
    directory = directory.replace("\\", "/");
    sendCommand("cd(\"" + directory + "\")");
  }
  return StringHandler::unparse(getResult());
}

/*!
  Loads the library.
  \param library - the library name.
  \param version -  the version of the library.
  \return true on success
  */
bool OMCProxy::loadModel(QString library, QString version)
{
  sendCommand("loadModel(" + library + ",{\"" + version + "\"})");
  bool result = StringHandler::unparseBool(getResult());
  printMessagesStringInternal();
  return result;
}

/*!
  Loads a file in OMC
  \param fileName - the file to load.
  \return true on success
  */
bool OMCProxy::loadFile(QString fileName, QString encoding)
{
  fileName = fileName.replace('\\', '/');
  sendCommand("loadFile(\"" + fileName + "\",\"" + encoding + "\")");
  bool result = StringHandler::unparseBool(getResult());
  printMessagesStringInternal();
  return result;
}

/*!
  Loads a string in OMC
  \param value - the string to load.
  \return true on success
  */
bool OMCProxy::loadString(QString value)
{
  sendCommand("loadString(\"" + value.replace("\"", "\\\"") + "\")");
  bool result = StringHandler::unparseBool(getResult());
  printMessagesStringInternal();
  return result;
}

/*!
  Parse the file. Doesn't load it into OMC.
  \param fileName - the file to parse.
  \return true on success
  */
bool OMCProxy::parseFile(QString fileName, QString encoding)
{
  fileName = fileName.replace('\\', '/');
  sendCommand("parseFile(\"" + fileName + "\",\"" + encoding + "\")");
  if (getResult() == "{}")
  {
    printMessagesStringInternal();
    return false;
  }
  else
    return true;
}

/*!
  Parse the string. Doesn't load it into OMC.
  \param value - the string to parse.
  \return the list of models inside the string.
  */
QStringList OMCProxy::parseString(QString value)
{
  sendCommand("parseString(\"" + value.replace("\"", "\\\"") + "\")");
  QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
  QStringList list = result.split(",", QString::SkipEmptyParts);
  printMessagesStringInternal();
  return list;
}

/*!
  Creates a new class in OMC.
  \param type - the class type.
  \param className - the class name.
  \return true on successs.
  */
bool OMCProxy::createClass(QString type, QString className, QString extendsClass)
{
  if (extendsClass.isEmpty())
    sendCommand(type + " " + className + " end " + className + ";");
  else
    sendCommand(type + " " + className + " extends " + extendsClass + "; end " + className + ";");
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Creates a new sub class in OMC.
  \param type - the class type.
  \param className - the class name.
  \param parentClassName - the parent class name.
  \return true on successs.
  */
bool OMCProxy::createSubClass(QString type, QString className, QString parentClassName, QString extendsClass)
{
  if (extendsClass.isEmpty())
    sendCommand("within " + parentClassName + "; " + type + " " + className + " end " + className + ";");
  else
    sendCommand("within " + parentClassName + "; " + type + " " + className + " extends " + extendsClass + "; end " + className + ";");
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Checks whether the class already exists in OMC or not.
  \param className - the name for the class to check.
  \return true on successs.
  */
bool OMCProxy::existClass(QString className)
{
  sendCommand("existClass(" + className + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Renames a class.
  \param oldName - the class old name.
  \param newName - the class new name.
  \return true on successs.
  */
bool OMCProxy::renameClass(QString oldName, QString newName)
{
  sendCommand("renameClass(" + oldName + ", " + newName + ")");
  if (StringHandler::unparseBool(getResult()))
    return false;
  else
    return true;
}

/*!
  Deletes a class.
  \param className - the name of the class.
  \return true on successs.
  */
bool OMCProxy::deleteClass(QString className)
{
  sendCommand("deleteClass(" + className + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Returns the file name of a model.
  \param className - the name of the class.
  \return the file name.
  */
QString OMCProxy::getSourceFile(QString className)
{
  sendCommand("getSourceFile(" + className + ")");
  QString file = StringHandler::unparse(getResult());
  if (file.compare("<interactive>") == 0)
    return "";
  else
    return file;
}

/*!
  Sets a file name of a model.
  \param className - the name of the class.
  \param path - the full location
  \return true on successs.
  */
bool OMCProxy::setSourceFile(QString className, QString path)
{
  sendCommand("setSourceFile(" + className + ", \"" + path + "\")");
  return StringHandler::unparseBool(getResult());
}

/*!
  Saves a model.
  \param className - the name of the class.
  \return true on successs.
  */
bool OMCProxy::save(QString className)
{
  sendCommand("save(" + className + ")");
  bool result = StringHandler::unparseBool(getResult());
  if (result)
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

bool OMCProxy::saveModifiedModel(QString modelText)
{
  sendCommand(modelText);
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Retruns the text of the class.
  \param className - the name of the class.
  \return the class text.
  */
QString OMCProxy::list(QString className)
{
  sendCommand("list(" + className + ")", true, className);
  return StringHandler::unparse(getResult());
}

/*!
  Adds annotation to the class.
  \param className - the name of the class.
  \param annotation - the annotaiton to set for the class.
  \return true on success.
  */
bool OMCProxy::addClassAnnotation(QString className, QString annotation)
{
  sendCommand("addClassAnnotation(" + className + ", " + annotation + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Retunrs the default componet name of a class.
  \param className - the name of the class.
  \return the default component name.
  */
QString OMCProxy::getDefaultComponentName(QString className)
{
  sendCommand("getDefaultComponentName(" + className + ")", true, className);
  if (getResult().compare("{}") == 0)
    return QString();

  return StringHandler::unparse(getResult());
}

/*!
  Retunrs the default component prefixes of a class.
  \param className - the name of the class.
  \return the default component prefixes.
  */
QString OMCProxy::getDefaultComponentPrefixes(QString className)
{
  sendCommand("getDefaultComponentPrefixes(" + className + ")", true, className);
  if (getResult().compare("{}") == 0)
    return QString();

  return StringHandler::unparse(getResult());
}

/*!
  Adds a component to the model.
  \param name - the component name
  \param className - the component fully qualified name.
  \param componentName - the name of the component to add.
  \return true on success.
  */
bool OMCProxy::addComponent(QString name, QString className, QString componentName, QString placementAnnotation)
{
  sendCommand("addComponent(" + name + ", " + className + "," + componentName + "," + placementAnnotation + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Deletes a component from the model.
  \param name - the component name
  \param componentName - the name of the component to delete.
  \return true on success.
  */
bool OMCProxy::deleteComponent(QString name, QString componentName)
{
  sendCommand("deleteComponent(" + name + "," + componentName + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Renames a component
  \param className - the name of the class.
  \param oldName - the old name of the component.
  \param newName - the new name of the component.
  \return true on success.
  \deprecated
  \see OMCProxy::renameComponentInClass(QString className, QString oldName, QString newName)
  */
bool OMCProxy::renameComponent(QString className, QString oldName, QString newName)
{
  sendCommand("renameComponent(" + className + "," + oldName + "," + newName + ")");
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Updates the component annotations.
  \param name - the component name
  \param className - the component fully qualified name.
  \param componentName - the name of the component to update.
  \param annotation - the updated annotation.
  \return true on success.
  */
bool OMCProxy::updateComponent(QString name, QString className, QString componentName, QString placementAnnotation)
{
  sendCommand("updateComponent(" + name + "," + className + "," + componentName + "," + placementAnnotation + ")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
    return false;
}

/*!
  Renames a component in a class.
  \param className - the name of the class.
  \param oldName - the old name of the component.
  \param newName - the new name of the component.
  \return true on success.
  \see OMCProxy::renameComponent(QString className, QString oldName, QString newName)
  */
bool OMCProxy::renameComponentInClass(QString className, QString oldName, QString newName)
{
  sendCommand("renameComponentInClass(" + className + "," + oldName + "," + newName + ")");
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Updates the connection annotation
  \param from - the connection start component name
  \param to - the connection end component name
  \param className - the name of the class.
  \param annotation - the updated conneciton annotation.
  \return true on success.
  */
bool OMCProxy::updateConnection(QString from, QString to, QString className, QString annotation)
{
  sendCommand("updateConnection(" + from + "," + to + "," + className + "," + annotation + ")");
  if (getResult().contains("Ok"))
    return true;
  else
    return false;
}

/*!
  Sets the component properties
  \param className - the name of the class.
  \param componentName - the name of the component.
  \param isFinal - the final property.
  \param isFlow - the flow property.
  \param isProtected - the protected property.
  \param isReplaceAble - the replaceable property.
  \param variability - the variability property.
  \param isInner - the inner property.
  \param isOuter - the outer property.
  \param causality - the causality property.
  \return true on success.
  */
bool OMCProxy::setComponentProperties(QString className, QString componentName, QString isFinal, QString isFlow, QString isProtected,
                                      QString isReplaceAble, QString variability, QString isInner, QString isOuter, QString causality)
{
  sendCommand("setComponentProperties(" + className + "," + componentName + ",{" + isFinal + "," + isFlow + "," + isProtected + "," + isReplaceAble + "}, {\"" + variability + "\"}, {" + isInner +
              "," + isOuter + "}, {\"" + causality + "\"})");

  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Sets the component comment
  \param className - the name of the class.
  \param componentName - the name of the component.
  \param comment - the component comment.
  \return true on success.
  */
bool OMCProxy::setComponentComment(QString className, QString componentName, QString comment)
{
  sendCommand("setComponentComment(" + className + "," + componentName + ",\"" + comment + "\")");
  if (getResult().toLower().contains("error"))
    return false;
  else
    return true;
}

/*!
  Adds a connection
  \param from - the connection start component name.
  \param to - the connection end component name.
  \param className - the name of the class.
  \return true on success.
  */
bool OMCProxy::addConnection(QString from, QString to, QString className, QString annotation)
{
  sendCommand("addConnection(" + from + "," + to + "," + className + "," + annotation + ")");
  if (getResult().contains("Ok"))
    return true;
  else
    return false;
}

/*!
  Deletes a connection
  \param from - the connection start component name.
  \param to - the connection end component name.
  \param className - the name od the class.
  \return true on success.
  */
bool OMCProxy::deleteConnection(QString from, QString to, QString className)
{
  sendCommand("deleteConnection(" + from + "," + to + "," + className + ")");
  if (getResult().contains("Ok"))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Check if Instantiating the model is successful or not.
  \param className - the name of the class.
  \return true on success.
  */
bool OMCProxy::instantiateModelSucceeds(QString className)
{
  sendCommand("instantiateModel(" + className + ")", false, className, true);
  if (getResult().size() < 3)
  {
    printMessagesStringInternal();
    return false;
  }
  else
    return true;
}

/*!
  Simulate the model. Creates an execuatble and runs it.
  \param className - the name of the class.
  \param simualtionParameters - the simulation parameters.
  \return true on success.
  \deprecated OMEdit only use OMCProxy::buildModel(QString className, QString simualtionParameters)
  */
bool OMCProxy::simulate(QString className, QString simualtionParameters)
{
  sendCommand("OMEdit_simulate_result:=simulate(" + className + "," + simualtionParameters + ")");
  sendCommand("OMEdit_simulate_result.resultFile");
  if (StringHandler::unparse(getResult()).isEmpty())
    return false;
  else
    return true;
}

/*!
  Builds the model. Only creates the simualtion executable, doesn't run it.
  \param className - the name of the class.
  \param simualtionParameters - the simulation parameters.
  \return true on success.
  \deprecated OMEdit now use OMCProxy::translateModel(QString className, QString simualtionParameters)
  */
bool OMCProxy::buildModel(QString className, QString simualtionParameters)
{
  sendCommand("buildModel(" + className + "," + simualtionParameters + ")");
  bool res = getResult() != "{\"\",\"\"}";
  printMessagesStringInternal();
  return res;
}

/*!
  Builds the model. Only creates the simulation files.
  \param className - the name of the class.
  \param simualtionParameters - the simulation parameters.
  \return true on success.
  */
bool OMCProxy::translateModel(QString className, QString simualtionParameters)
{
  sendCommand("translateModel(" + className + "," + simualtionParameters + ")");
  bool res = StringHandler::unparseBool(getResult());
  printMessagesStringInternal();
  return res;
}

/*!
  Reads the simulation result variables from the result file.
  \param fileName - the result file name
  \return the list of variables.
  */
QStringList OMCProxy::readSimulationResultVars(QString fileName)
{
  sendCommand("readSimulationResultVars(\"" + fileName + "\")");
  QStringList variablesList = StringHandler::unparseStrings(getResult());
  qSort(variablesList.begin(), variablesList.end());
  printMessagesStringInternal();
  return variablesList;
}

/*!
  Closes the current simulation result file.\n
  Only valid for Windows.\n
  On Linux it simply returns true without doing anything.
  \return true on success.
  */
bool OMCProxy::closeSimulationResultFile()
{
#ifdef Q_OS_WIN
  sendCommand("closeSimulationResultFile()");
  return StringHandler::unparseBool(getResult());
#else
  return true;
#endif
}

/*!
  Checks the model. Checks model balance in terms of number of variables and equations.
  \param className - the name of the class.
  \return the model check result
  */
QString OMCProxy::checkModel(QString className)
{
  sendCommand("checkModel(" + className + ")", true, className);
  return getResult();
}

/*!
  Instantiates the model.
  \param className - the name of the class.
  \return the instantiated model
  */
QString OMCProxy::instantiateModel(QString className)
{
  sendCommand("instantiateModel(" + className + ")", true, className);
  QString result = StringHandler::unparse(getResult());
  printMessagesStringInternal();
  return result;
}

/*!
  Returns the simulation options stored in the model.
  \param className - the name of the class.
  \return the simulation options
  */
bool OMCProxy::isExperiment(QString className)
{
  sendCommand("isExperiment(" + className + ")", true, className);
  return StringHandler::unparseBool(getResult());
}

/*!
  Returns the simulation options stored in the model.
  \param className - the name of the class.
  \return the simulation options
  */
QString OMCProxy::getSimulationOptions(QString className)
{
  sendCommand("getSimulationOptions(" + className + ")", true, className);
  return getResult();
}

/*!
  Creates the FMU of the model.
  \param className - the name of the class.
  \return the created FMU location
  */
bool OMCProxy::translateModelFMU(QString className)
{
  sendCommand("translateModelFMU(" + className + ")");
  if (StringHandler::unparse(getResult()).compare("SimCode: The model " + className + " has been translated to FMU") == 0)
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Creates the XML of the model.
  \param className - the name of the class.
  \return the created XML location
  */
bool OMCProxy::translateModelXML(QString className)
{
  sendCommand("translateModelXML(" + className + ")");
  if (StringHandler::unparse(getResult()).compare("SimCode: The model " + className + " has been translated to XML") == 0)
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Imports the FMU
  \param fmuName - the FMU location
  \param outputDirectory - the output location
  \param logLevel - the logging level
  \param debugLogging - enables the debug logging for the imported FMU.
  \param generateInputConnectors - generates the input variables as connectors
  \param generateOutputConnectors - generates the output variables as connectors.
  \return generated Modelica Code file path
  */
QString OMCProxy::importFMU(QString fmuName, QString outputDirectory, int logLevel, bool debugLogging, bool generateInputConnectors,
                            bool generateOutputConnectors)
{
  QString debugLoggingString = debugLogging ? "true" : "false";
  QString generateInputConnectorsString = generateInputConnectors ? "true" : "false";
  QString generateOutputConnectorsString = generateOutputConnectors ? "true" : "false";
  if (outputDirectory.isEmpty())
    sendCommand("importFMU(\"" + fmuName + "\", loglevel=" + QString::number(logLevel) + ", fullPath=true, debugLogging=" + debugLoggingString + ", generateInputConnectors=" + generateInputConnectorsString + ", generateOutputConnectors=" + generateOutputConnectorsString + ")");
  else
    sendCommand("importFMU(\"" + fmuName + "\", \"" + outputDirectory.replace("\\", "/") + "\", loglevel=" + QString::number(logLevel) + ", fullPath=true, debugLogging=" + debugLoggingString + ", generateInputConnectors=" + generateInputConnectorsString + ", generateOutputConnectors=" + generateOutputConnectorsString + ")");
  QString fmuFileName = StringHandler::unparse(getResult());
  printMessagesStringInternal();
  return fmuFileName;
}

/*!
  Reads the matching algorithm used during the simulation.
  \return the name of the matching algorithm
  */
QString OMCProxy::getMatchingAlgorithm()
{
  sendCommand("getMatchingAlgorithm()");
  return StringHandler::unparse(getResult());
}

/*!
  Reads the list of available matching algorithms.
  \param choices (Output) - the list of matching algorithm choices
  \param comments (Output) - the list of matching algorithm choices comments
  */
void OMCProxy::getAvailableMatchingAlgorithms(QStringList *choices, QStringList *comments)
{
  sendCommand("getAvailableMatchingAlgorithms()");
  QStringList resultList = StringHandler::unparseArrays(getResult());
  if (resultList.size() == 2)
  {
    *choices = StringHandler::unparseStrings(resultList.at(0));
    *comments = StringHandler::unparseStrings(resultList.at(1));
  }
  else
    printMessagesStringInternal();
}

/*!
  Reads the index reduction method used during the simulation.
  \return the name of the index reduction method.
  */
QString OMCProxy::getIndexReductionMethod()
{
  sendCommand("getIndexReductionMethod()");
  return StringHandler::unparse(getResult());
}

/*!
  Sets the matching algorithm.
  \param matchingAlgorithm - the macthing algorithm to set
  \return true on success
  */
bool OMCProxy::setMatchingAlgorithm(QString matchingAlgorithm)
{
  sendCommand("setMatchingAlgorithm(\"" + matchingAlgorithm + "\")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Reads the list of available index reduction methods.
  \param choices (Output) - the list of index reduction methods choices
  \param comments (Output) - the list of index reduction methods comments
  */
void OMCProxy::getAvailableIndexReductionMethods(QStringList *choices, QStringList *comments)
{
  sendCommand("getAvailableIndexReductionMethods()");
  QStringList resultList = StringHandler::unparseArrays(getResult());
  if (resultList.size() == 2)
  {
    *choices = StringHandler::unparseStrings(resultList.at(0));
    *comments = StringHandler::unparseStrings(resultList.at(1));
  }
  else
    printMessagesStringInternal();
}

/*!
  Sets the index reduction method.
  \param method the index reduction method to set
  \return true on success
  */
bool OMCProxy::setIndexReductionMethod(QString method)
{
  sendCommand("setIndexReductionMethod(\"" + method + "\")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Sets the OMC flags.
  \param options - a space separated list fo OMC command line options e.g. +d=initialization +cheapmatchingAlgorithm=3
  \return true on success
  */
bool OMCProxy::setCommandLineOptions(QString options)
{
  sendCommand("setCommandLineOptions(\"" + options + "\")");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Clears the OMC flags.
  \return true on success
  */
bool OMCProxy::clearCommandLineOptions()
{
  sendCommand("clearCommandLineOptions()");
  if (StringHandler::unparseBool(getResult()))
    return true;
  else
  {
    printMessagesStringInternal();
    return false;
  }
}

/*!
  Helper function for getDocumentationAnnotation. Takes the documentation html and replaces the modelica links with absolute pahts.\n
  This function also makes the html valid. e.g html like,\n
    <p>Test</p><html><body>This is body</body></html>\n
   will become,\n
    <html><head></head><body><p>Test</p>This is body</body></html>
  \param documentation - in html form.
  \return New documentation in html form.
  */
QString OMCProxy::makeDocumentationImagesUriToFileName(QString documentation)
{
  QWebPage webPage;
  QWebFrame *pWebFrame = webPage.mainFrame();
  pWebFrame->setHtml(documentation);
  QWebElement webElement = pWebFrame->documentElement();
  QWebElementCollection imgTags = webElement.findAll("img");
  foreach (QWebElement imgTag, imgTags)
  {
    QString src = imgTag.attribute("src");
    if (src.startsWith("modelica://"))
    {
      QString imgFileName = uriToFilename(src);
      imgTag.setAttribute("src", imgFileName);
    }
    else if (src.startsWith("file://"))
    {
      QString imgFileName = uriToFilename(src);
      /*
        Windows absolute paths doesn't start with "/".
        */
#ifdef WIN32
      if (imgFileName.startsWith("/"))
        imgFileName = imgFileName.mid(1);
#endif
      imgTag.setAttribute("src", imgFileName);
    }
    else
    {
      //! @todo The img src value starts with modelica:// for MSL 3.2.1. Handle the other cases in this else block.
    }
  }
  return webElement.toOuterXml();
}

/*!
  Takes the Modelica file link as modelica://Modelica/Resources/Images/ABC.png and returns the absolute path for it.
  \param uri - the modelica link of the file
  \return absolute path
  */
QString OMCProxy::uriToFilename(QString uri)
{
  sendCommand("uriToFilename(\"" + uri + "\")");
  QString result = StringHandler::removeFirstLastBrackets(getResult());
  result = result.prepend("{").append("}");
  QStringList results = StringHandler::unparseStrings(result);
  /* uriToFilename does not set errors.
  printMessagesStringInternal();
  */
  if (results.size() > 0)
    return results.first();
  else
    return "";
}

/*!
  Gets the modelica library path
  \return the library path
  */
QString OMCProxy::getModelicaPath()
{
  sendCommand("getModelicaPath()");
  QString result = StringHandler::unparse(getResult());
  printMessagesStringInternal();
  return result;
}

/*!
  Gets the available OpenModelica libraries.
  \return the list of libaries.
  */
QStringList OMCProxy::getAvailableLibraries()
{
  sendCommand("getAvailableLibraries()");
  QString result = getResult();
  return StringHandler::unparseStrings(result);
}

/*!
  Gets the derived class modifier value.
  \param className - the name of the derived class.
  \param modifierName - the modifier name.
  \return the value of the modifier.
  */
QString OMCProxy::getDerivedClassModifierValue(QString className, QString modifierName)
{
  sendCommand("getDerivedClassModifierValue(" + className + "," + modifierName + ")", true, className);
  return StringHandler::getModifierValue(StringHandler::unparse(getResult()));
}

/*!
  Gets the DocumentationClass annotation.
  \param className - the name of the class.
  \return true/false.
  */
bool OMCProxy::getDocumentationClassAnnotation(QString className)
{
  sendCommand("getNamedAnnotation(" + className + ", DocumentationClass)");
  return StringHandler::unparseBool(StringHandler::removeFirstLastCurlBrackets(getResult()));
}

/*!
  Gets the number of processors.
  \return the number of processors.
  */
QString OMCProxy::numProcessors()
{
  sendCommand("numProcessors()");
  return getResult();
}

/*!
  \class CustomExpressionBox
  \brief A text box for executing OMC commands.
  */
/*!
  \param pOMCProxy - pointer to OMCProxy
  */
CustomExpressionBox::CustomExpressionBox(OMCProxy *pOMCProxy)
{
  mpOMCProxy = pOMCProxy;
}

/*!
  Reimplementation of keyPressEvent.
  */
void CustomExpressionBox::keyPressEvent(QKeyEvent *event)
{
  switch (event->key())
  {
    case Qt::Key_Up:
      mpOMCProxy->getPreviousCommand();
      break;
    case Qt::Key_Down:
      mpOMCProxy->getNextCommand();
      break;
    default:
      QLineEdit::keyPressEvent(event);
  }
}
