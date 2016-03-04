/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 *
 */

#include <OMC/Parser/OMCOutputLexer.h>
#include <OMC/Parser/OMCOutputParser.h>
#include "meta/meta_modelica.h"
#ifdef WIN32
#include "version.h"
#endif

extern "C" {
void (*omc_assert)(threadData_t*,FILE_INFO info,const char *msg,...) __attribute__((noreturn)) = omc_assert_function;
void (*omc_assert_warning)(FILE_INFO info,const char *msg,...) = omc_assert_warning_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_function;
int omc_Main_handleCommand(void *threadData, void *imsg, void *ist, void **omsg, void **ost);
void* omc_Main_init(void *threadData, void *args);
void* omc_Main_readSettings(void *threadData, void *args);
#ifdef WIN32
void omc_Main_setWindowsPaths(threadData_t *threadData, void* _inOMHome);
#endif
}

#include <stdlib.h>
#include <iostream>

#include "OMCProxy.h"
#include "simulation_options.h"

static QVariant parseExpression(QString result)
{
  QVariant res;
  pANTLR3_INPUT_STREAM input;
  pOMCOutputLexer lex;
  pANTLR3_COMMON_TOKEN_STREAM tokens;
  pOMCOutputParser parser;
  QByteArray ba = result.toUtf8();

  input  = antlr3NewAsciiStringInPlaceStream((pANTLR3_UINT8)ba.data(), ba.size(), (pANTLR3_UINT8)"");
  lex    = OMCOutputLexerNew(input);
  tokens = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lex));
  parser = OMCOutputParserNew(tokens);

  parser->exp(parser, res);
  // Clean up? Check error? For chickens
  parser->free(parser);
  tokens->free(tokens);
  lex->free(lex);
  input->close(input);
  return res;
}

/*!
  \class OMCProxy
  \brief It contains the reference of the CORBA object used to communicate with the OpenModelica Compiler.
  */
/*!
  \param pMainWindow - pointer to MainWindow
  */
OMCProxy::OMCProxy(MainWindow *pMainWindow)
  : QObject(pMainWindow), mHasInitialized(false), mResult("")
{
  mpMainWindow = pMainWindow;
  mCurrentCommandIndex = -1;
  // OMC Commands Logger Widget
  mpOMCLoggerWidget = new QWidget;
  mpOMCLoggerWidget->resize(640, 480);
  mpOMCLoggerWidget->setWindowIcon(QIcon(":/Resources/icons/console.svg"));
  mpOMCLoggerWidget->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::OpenModelicaCompilerCLI));
  // OMC Logger textbox
  mpOMCLoggerTextBox = new QPlainTextEdit;
  mpOMCLoggerTextBox->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpOMCLoggerTextBox->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpOMCLoggerTextBox->setReadOnly(true);
  mpOMCLoggerTextBox->setLineWrapMode(QPlainTextEdit::WidgetWidth);
  mpOMCLoggerEnableHintLabel = new Label(tr("* To enable OpenModelica Compiler CLI start OMEdit with argument --OMCLogger=true"));
  mpOMCLoggerEnableHintLabel->setFont(QFont(Helper::monospacedFontInfo.family()));
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
  pVerticalalLayout->setContentsMargins(1, 1, 1, 1);
  pVerticalalLayout->addWidget(mpOMCLoggerTextBox);
  pVerticalalLayout->addLayout(pHorizontalLayout);
  pVerticalalLayout->addWidget(mpOMCLoggerEnableHintLabel);
  mpOMCLoggerWidget->setLayout(pVerticalalLayout);
  if (mpMainWindow->isDebug()) {
    // OMC Diff widget
    mpOMCDiffWidget = new QWidget;
    mpOMCDiffWidget->resize(640, 480);
    mpOMCDiffWidget->setWindowIcon(QIcon(":/Resources/icons/console.svg"));
    mpOMCDiffWidget->setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("OMC Diff")));
    mpOMCDiffBeforeLabel = new Label(tr("Before"));
    mpOMCDiffBeforeTextBox = new QPlainTextEdit;
    mpOMCDiffAfterLabel = new Label(tr("After"));
    mpOMCDiffAfterTextBox = new QPlainTextEdit;
    mpOMCDiffMergedLabel = new Label(tr("Merged"));
    mpOMCDiffMergedTextBox = new QPlainTextEdit;
    // Set the OMC Diff widget Layout
    QGridLayout *pOMCDiffWidgetLayout = new QGridLayout;
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffBeforeLabel, 0, 0);
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffAfterLabel, 0, 1);
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffBeforeTextBox, 1, 0);
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffAfterTextBox, 1, 1);
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffMergedLabel, 2, 0, 1, 2);
    pOMCDiffWidgetLayout->addWidget(mpOMCDiffMergedTextBox, 3, 0, 1, 2);
    mpOMCDiffWidget->setLayout(pOMCDiffWidgetLayout);
  }
  //start the server
  if(!initializeOMC())      // if we are unable to start OMC. Exit the application.
  {
    mpMainWindow->setExitApplicationStatus(true);
    return;
  }
}

OMCProxy::~OMCProxy()
{
  delete mpOMCLoggerWidget;
  if (mpMainWindow->isDebug()) {
    delete mpOMCDiffWidget;
  }
}

/*!
  Show/Hide the custom command expression box.
  \param enable - enables/disables the expression text box.
  */
void OMCProxy::enableCustomExpression(bool enable)
{
  if (!enable) {
    mpExpressionTextBox->hide();
    mpOMCLoggerSendButton->hide();
    mpOMCLoggerEnableHintLabel->show();
  } else {
    mpExpressionTextBox->show();
    mpOMCLoggerSendButton->show();
    mpOMCLoggerEnableHintLabel->hide();
  }
}

/*!
  Puts the previous send OMC command in the send command text box.\n
  Invoked by the up arrow key.
  */
void OMCProxy::getPreviousCommand()
{
  if (mCommandsList.isEmpty()) {
    return;
  }

  mCurrentCommandIndex -= 1;
  if (mCurrentCommandIndex > -1) {
    mpExpressionTextBox->setText(mCommandsList.at(mCurrentCommandIndex));
  } else {
    mCurrentCommandIndex += 1;
  }
}

/*!
  Puts the most recently send OMC command in the send command text box.
  Invoked by the down arrow key.
  */
void OMCProxy::getNextCommand()
{
  if (mCommandsList.isEmpty()) {
    return;
  }

  mCurrentCommandIndex += 1;
  if (mCurrentCommandIndex < mCommandsList.count()) {
    mpExpressionTextBox->setText(mCommandsList.at(mCurrentCommandIndex));
  } else {
    mCurrentCommandIndex -= 1;
  }
}

/*!
  Initializes the OpenModelica Compiler binary.\n
  Creates the omeditcommunication.log & omeditcommands.mos files.
  \return status - returns true if initialization is successful otherwise false.
  */
bool OMCProxy::initializeOMC()
{
  /* create the tmp path */
  QString& tmpPath = OpenModelica::tempDirectory();
  /* create a file to write OMEdit communication log */
  mCommunicationLogFile.setFileName(QString("%1omeditcommunication.log").arg(tmpPath));
  if (mCommunicationLogFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
    mCommunicationLogFileTextStream.setDevice(&mCommunicationLogFile);
    mCommunicationLogFileTextStream.setCodec(Helper::utf8.toStdString().data());
    mCommunicationLogFileTextStream.setGenerateByteOrderMark(false);
  }
  /* create a file to write OMEdit commands */
  mCommandsMosFile.setFileName(QString("%1omeditcommands.mos").arg(tmpPath));
  if (mCommandsMosFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
    mCommandsLogFileTextStream.setDevice(&mCommandsMosFile);
    mCommandsLogFileTextStream.setCodec(Helper::utf8.toStdString().data());
    mCommandsLogFileTextStream.setGenerateByteOrderMark(false);
  }
  threadData_t *threadData = (threadData_t *) calloc(1, sizeof(threadData_t));
  void *st = 0;
  MMC_TRY_TOP_INTERNAL()
  omc_Main_init(threadData, mmc_mk_nil());
  st = omc_Main_readSettings(threadData, mmc_mk_nil());
  threadData->plotClassPointer = mpMainWindow;
  threadData->plotCB = MainWindow::PlotCallbackFunction;
  MMC_CATCH_TOP(return false;)
  mpOMCInterface = new OMCInterface(threadData, st);
  connect(mpOMCInterface, SIGNAL(logCommand(QString,QTime*)), this, SLOT(logCommand(QString,QTime*)));
  connect(mpOMCInterface, SIGNAL(logResponse(QString,QTime*)), this, SLOT(logResponse(QString,QTime*)));
  connect(mpOMCInterface, SIGNAL(throwException(QString)), SLOT(showException(QString)));
  mHasInitialized = true;
  // set the locale
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  QLocale settingsLocale = QLocale(pSettings->value("language").toString());
  settingsLocale = settingsLocale.name() == "C" ? pSettings->value("language").toLocale() : settingsLocale;
  setCommandLineOptions("+locale=" + settingsLocale.name());
  // get OpenModelica version
  Helper::OpenModelicaVersion = getVersion();
#ifdef WIN32
  sendCommand("\"" +  QString(GIT_SHA) + "\"");
#endif
  // set OpenModelicaHome variable
  Helper::OpenModelicaHome = mpOMCInterface->getInstallationDirectoryPath();
#ifdef WIN32
  MMC_TRY_TOP_INTERNAL()
  omc_Main_setWindowsPaths(threadData, mmc_mk_scon(Helper::OpenModelicaHome.toStdString().c_str()));
  MMC_CATCH_TOP()
#endif
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
void OMCProxy::quitOMC()
{
  sendCommand("quit()");
  mCommunicationLogFile.close();
  mCommandsMosFile.close();
}

/*!
 * \brief OMCProxy::sendCommand
 * Sends the user commands to OMC.
 * \param expression - is used to send command as a string.
 */
void OMCProxy::sendCommand(const QString expression)
{
  if (!mHasInitialized) {
    // if we are unable to start OMC. Exit the application.
    if(!initializeOMC()) {
      mpMainWindow->setExitApplicationStatus(true);
      return;
    }
  }
  // write command to the commands log.
  QTime commandTime;
  commandTime.start();
  logCommand(expression, &commandTime);
  // TODO: Call this in a thread that loops over received messages? Avoid MMC_TRY_TOP all the time, etc
  void *reply_str = NULL;
  threadData_t *threadData = mpOMCInterface->threadData;

  MMC_TRY_TOP_INTERNAL()

  MMC_TRY_STACK()

  if (!omc_Main_handleCommand(threadData, mmc_mk_scon(expression.toStdString().c_str()), mpOMCInterface->st, &reply_str, &mpOMCInterface->st)) {
    if (expression == "quit()") {
      return;
    }
    exitApplication();
  }
  mResult = MMC_STRINGDATA(reply_str);
  logResponse(mResult.trimmed(), &commandTime);

  MMC_ELSE()
    mResult = "";
    fprintf(stderr, "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
    printStacktraceMessages();
    fflush(NULL);
  MMC_CATCH_STACK()

  MMC_CATCH_TOP(mResult = "");
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
  Writes OMC command in OMC Logger window.
  Writes the command to the omeditcommunication.log file.
  Writes the command to the omeditcommands.mos file.
  \param command - the command to write
  \param commandTime - the command start time
  */
void OMCProxy::logCommand(QString command, QTime *commandTime)
{
  // move the cursor down before adding to the logger.
  QTextCursor textCursor = mpOMCLoggerTextBox->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // add the expression to commands list
  mCommandsList.append(command);
  // log expression
  QFont font(Helper::monospacedFontInfo.family(), Helper::monospacedFontInfo.pointSize() - 2, QFont::Bold, false);
  QTextCharFormat charFormat = mpOMCLoggerTextBox->currentCharFormat();
  charFormat.setFont(font);
  mpOMCLoggerTextBox->setCurrentCharFormat(charFormat);
  mpOMCLoggerTextBox->insertPlainText(command + "\n");
  // move the cursor
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // set the current command index.
  mCurrentCommandIndex = mCommandsList.count();
  mpExpressionTextBox->setText("");
  // write the log to communication log file
  if (mCommunicationLogFileTextStream.device()) {
    mCommunicationLogFileTextStream << command << " " << commandTime->currentTime().toString("hh:mm:ss:zzz");
    mCommunicationLogFileTextStream << "\n";
    mCommunicationLogFileTextStream.flush();
  }
  // write commands mos file
  if (mCommandsLogFileTextStream.device()) {
    if (command.compare("quit()") == 0) {
      mCommandsLogFileTextStream << command << ";\n";
    } else {
      mCommandsLogFileTextStream << command << "; getErrorString();\n";
    }
    mCommandsLogFileTextStream.flush();
  }
}

/*!
  Writes OMC response in OMC Logger window.
  Writes the response to the omeditcommunication.log file.
  Writes the response to the omeditcommands.mos file.
  \param response - the response to write
  \param commandTime - the command start time
  */
void OMCProxy::logResponse(QString response, QTime *responseTime)
{
  // move the cursor down before adding to the logger.
  QTextCursor textCursor = mpOMCLoggerTextBox->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // log expression
  QFont font(Helper::monospacedFontInfo.family(), Helper::monospacedFontInfo.pointSize() - 2, QFont::Normal, false);
  QTextCharFormat charFormat = mpOMCLoggerTextBox->currentCharFormat();
  charFormat.setFont(font);
  mpOMCLoggerTextBox->setCurrentCharFormat(charFormat);
  mpOMCLoggerTextBox->insertPlainText(response + "\n\n");
  // move the cursor
  textCursor.movePosition(QTextCursor::End);
  mpOMCLoggerTextBox->setTextCursor(textCursor);
  // write the log to communication log file
  if (mCommunicationLogFileTextStream.device()) {
    mCommunicationLogFileTextStream << response << " " << responseTime->currentTime().toString("hh:mm:ss:zzz");
    mCommunicationLogFileTextStream << "\n";
    mCommunicationLogFileTextStream << "Elapsed Time :: " << QString::number((double)responseTime->elapsed() / 1000).append(" secs");
    mCommunicationLogFileTextStream << "\n\n";
    mCommunicationLogFileTextStream.flush();
  }
}

/*!
 * \brief Writes the exception to MessagesWidget.
 * \param exception
 */
void OMCProxy::showException(QString exception)
{
  MessageItem messageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, exception, Helper::scriptingKind, Helper::errorLevel);
  mpMainWindow->getMessagesWidget()->addGUIMessage(messageItem);
  printMessagesStringInternal();
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
  mpOMCLoggerWidget->setWindowState(mpOMCLoggerWidget->windowState() & (~Qt::WindowMinimized | Qt::WindowActive));
}

/*!
  Sends the command written in the OMC Logger textbox.
  */
void OMCProxy::sendCustomExpression()
{
  if (mpExpressionTextBox->text().isEmpty())
    return;

  sendCommand(mpExpressionTextBox->text());
  mpExpressionTextBox->setText("");
}

/*!
 * \brief OMCProxy::openOMCDiffWidget
 * Opens the OMC Diff widget.
 */
void OMCProxy::openOMCDiffWidget()
{
  if (mpMainWindow->isDebug()) {
    mpOMCDiffBeforeTextBox->setFocus(Qt::ActiveWindowFocusReason);
    mpOMCDiffWidget->show();
    mpOMCDiffWidget->raise();
    mpOMCDiffWidget->activateWindow();
    mpOMCDiffWidget->setWindowState(mpOMCDiffWidget->windowState() & (~Qt::WindowMinimized | Qt::WindowActive));
  }
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
  Returns the OMC error string.\n
  \return the error string.
  \deprecated Use printMessagesStringInternal(). Now used where we want to consume the error message without showing it to user.
  */
QString OMCProxy::getErrorString(bool warningsAsErrors)
{
  return mpOMCInterface->getErrorString(warningsAsErrors);
}

/*!
  Gets the errors by using the getMessagesStringInternal API.
  Reads all the errors and add them to the Messages Window.
  \see MessagesWidget::addGUIMessage
  \return true if there are any errors otherwise false.'
  */
bool OMCProxy::printMessagesStringInternal()
{
  int errorsSize = getMessagesStringInternal();
  bool returnValue = errorsSize > 0 ? true : false;

  /* Loop in reverse order since getMessagesStringInternal returns error messages in reverse order. */
  for (int i = errorsSize; i > 0 ; i--) {
    setCurrentError(i);
    MessageItem messageItem(MessageItem::Modelica, getErrorFileName(), getErrorReadOnly(), getErrorLineStart(), getErrorColumnStart(), getErrorLineEnd(),
                            getErrorColumnEnd(), getErrorMessage(), getErrorKind(), getErrorLevel());
    mpMainWindow->getMessagesWidget()->addGUIMessage(messageItem);
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
  Gets the OMC version. On Linux it also return the revision number as well.
  \return the version
  */
QString OMCProxy::getVersion(QString className)
{
  return mpOMCInterface->getVersion(className);
}

/*!
 * \brief OMCProxy::loadSystemLibraries
 * Loads the Modelica System Libraries.\n
 * Reads the omedit.ini file to get the libraries to load.
 */
void OMCProxy::loadSystemLibraries()
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  bool forceModelicaLoad = true;
  if (pSettings->contains("forceModelicaLoad")) {
    forceModelicaLoad = pSettings->value("forceModelicaLoad").toBool();
  }
  pSettings->beginGroup("libraries");
  QStringList libraries = pSettings->childKeys();
  pSettings->endGroup();
  /*
    Only force loading of Modelica & ModelicaReference if user is using OMEdit for the first time.
    Later user must use the libraries options dialog.
    */
  if (forceModelicaLoad) {
    if (!pSettings->contains("libraries/Modelica")) {
      pSettings->setValue("libraries/Modelica","default");
      libraries.prepend("Modelica");
    }
    if (!pSettings->contains("libraries/ModelicaReference")) {
      pSettings->setValue("libraries/ModelicaReference","default");
      libraries.prepend("ModelicaReference");
    }
  }
  foreach (QString lib, libraries) {
    QString version = pSettings->value("libraries/" + lib).toString();
    loadModel(lib, version);
  }
  mpMainWindow->getOptionsDialog()->readLibrariesSettings();
}

/*!
 * \brief OMCProxy::loadUserLibraries
 * Loads the Modelica User Libraries.
 * Reads the omedit.ini file to get the libraries to load.
 */
void OMCProxy::loadUserLibraries()
{
  QSettings *pSettings = OpenModelica::getApplicationSettings();
  pSettings->beginGroup("userlibraries");
  QStringList libraries = pSettings->childKeys();
  pSettings->endGroup();
  foreach (QString lib, libraries) {
    QString encoding = pSettings->value("userlibraries/" + lib).toString();
    QString fileName = QUrl::fromPercentEncoding(QByteArray(lib.toStdString().c_str()));
    QStringList classesList = parseFile(fileName, encoding);
    if (!classesList.isEmpty()) {
      /*
        Only allow loading of files that has just one nonstructured entity.
        From Modelica specs section 13.2.2.2,
        "A nonstructured entity [e.g. the file A.mo] shall contain only a stored-definition that defines a class [A] with a name
         matching the name of the nonstructured entity."
        */
      if (classesList.size() > 1) {
        QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
        pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
        pMessageBox->setIcon(QMessageBox::Critical);
        pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
        pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(fileName)));
        pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::MULTIPLE_TOP_LEVEL_CLASSES)).arg(fileName)
                                        .arg(classesList.join(",")));
        pMessageBox->setStandardButtons(QMessageBox::Ok);
        pMessageBox->exec();
        return;
      }
      QStringList existingmodelsList;
      bool existModel = false;
      // check if the model already exists
      foreach(QString model, classesList) {
        if (existClass(model)) {
          existingmodelsList.append(model);
          existModel = true;
        }
      }
      // if existModel is true, show user an error message
      if (existModel) {
        QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
        pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::information));
        pMessageBox->setIcon(QMessageBox::Information);
        pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
        pMessageBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(encoding)));
        pMessageBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFINING_EXISTING_CLASSES))
                                        .arg(existingmodelsList.join(",")).append("\n")
                                        .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD).arg(encoding)));
        pMessageBox->setStandardButtons(QMessageBox::Ok);
        pMessageBox->exec();
      } else { // if no conflicting model found then just load the file simply
        loadFile(fileName, encoding);
      }
    }
  }
}

/*!
 * \brief OMCProxy::getClassNames
 * Gets the list of classes from OMC.
 * \param className - is the name of the class whose sub classes are retrieved.
 * \param recursive - recursively retrieve all the sub classes.
 * \param qualified - returns the class names as qualified path.
 * \param sort
 * \param builtin
 * \param showProtected - returns the protected classes as well.
 * \return
 */
QStringList OMCProxy::getClassNames(QString className, bool recursive, bool qualified, bool sort, bool builtin, bool showProtected)
{
  return mpOMCInterface->getClassNames(className, recursive, qualified, sort, builtin, showProtected);
}

/*!
  Searches the list of classes from OMC.
  \param searchText - is the text to search for.
  \param findInText - tells to look for the searchText inside Modelica Text also.
  \return the list of searched classes.
  */
QStringList OMCProxy::searchClassNames(QString searchText, bool findInText)
{
  return mpOMCInterface->searchClassNames(searchText, findInText);
}

/*!
  Gets the information about the class.
  \param className - is the name of the class whose information is retrieved.
  \return the class information list.
  */
OMCInterface::getClassInformation_res OMCProxy::getClassInformation(QString className)
{
  OMCInterface::getClassInformation_res classInformation = mpOMCInterface->getClassInformation(className);
  QString comment = classInformation.comment.replace("\\\"", "\"");
  comment = makeDocumentationUriToFileName(comment);
  // since tooltips can't handle file:// scheme so we have to remove it in order to display images and make links work.
#ifdef WIN32
  comment.replace("src=\"file:///", "src=\"");
#else
  comment.replace("src=\"file://", "src=\"");
#endif
  classInformation.comment = comment;
  return classInformation;
}

/*!
  Checks whether the class is a package or not.
  \param className - is the name of the class which is checked.
  \return true if the class is a pacakge otherwise false
  */
bool OMCProxy::isPackage(QString className)
{
  return mpOMCInterface->isPackage(className);
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
  Returns true if the given type is one of the predefined types in Modelica.
  Returns also the name of the predefined type.
  */
QString OMCProxy::getBuiltinType(QString typeName)
{
  QString result = "";
  result = mpOMCInterface->getBuiltinType(typeName);
  getErrorString();
  return result;
}

/*!
  Checks the class type.
  \param type - the type to check.
  \param className - the class to check.
  \return true if the class is a specified type
  */
bool OMCProxy::isWhat(StringHandler::ModelicaClasses type, QString className)
{
  bool result = false;
  switch (type) {
    case StringHandler::Model:
      result = mpOMCInterface->isModel(className);
      break;
    case StringHandler::Class:
      result = mpOMCInterface->isClass(className);
      break;
    case StringHandler::Connector:
      result = mpOMCInterface->isConnector(className);
      break;
    case StringHandler::Record:
      result = mpOMCInterface->isRecord(className);
      break;
    case StringHandler::Block:
      result = mpOMCInterface->isBlock(className);
      break;
    case StringHandler::Function:
      result = mpOMCInterface->isFunction(className);
      break;
    case StringHandler::Package:
      result = mpOMCInterface->isPackage(className);
      break;
    case StringHandler::Type:
      result = mpOMCInterface->isType(className);
      break;
    case StringHandler::Operator:
      result = mpOMCInterface->isOperator(className);
      break;
    case StringHandler::OperatorRecord:
      result = mpOMCInterface->isOperatorRecord(className);
      break;
    case StringHandler::OperatorFunction:
      result = mpOMCInterface->isOperatorFunction(className);
      break;
    case StringHandler::Optimization:
      result = mpOMCInterface->isOptimization(className);
      break;
    case StringHandler::Enumeration:
      result = mpOMCInterface->isEnumeration(className);
      break;
    default:
      result = false;
  }
  return result;
}

/*!
  Checks whether the nested class is protected or not.
  \param className - is the name of the class.
  \param nestedClassName - is the nested class to check.
  \return true if the nested class is protected otherwise false
  */
bool OMCProxy::isProtectedClass(QString className, QString nestedClassName)
{
  if (className.isEmpty()) {
    return false;
  } else {
    return mpOMCInterface->isProtectedClass(className, nestedClassName);
  }
}

/*!
  Checks whether the class is partial or not.
  \param className - is the name of the class.
  \return true if the class is partial otherwise false
  */
bool OMCProxy::isPartial(QString className)
{
  return mpOMCInterface->isPartial(className);
}

/*!
 * \brief OMCProxy::isReplaceable
 * Returns true if the className is replaceable in parentClassName.
 * \param parentClassName
 * \param className
 * \return
 */
bool OMCProxy::isReplaceable(QString parentClassName, QString className)
{
  sendCommand("isReplaceable(" + parentClassName + ", \"" + className + "\")");
  return StringHandler::unparseBool(getResult());
}

/*!
  Gets the class type.
  \param className - is the name of the class to check.
  \return the class type.
  */
StringHandler::ModelicaClasses OMCProxy::getClassRestriction(QString className)
{
  QString result = mpOMCInterface->getClassRestriction(className);

  if (result.toLower().contains("model"))
    return StringHandler::Model;
  else if (result.toLower().contains("class"))
    return StringHandler::Class;
  //! @note Also handles the expandable connectors i.e we return StringHandler::CONNECTOR for expandable connectors.
  else if (result.toLower().contains("connector"))
    return StringHandler::Connector;
  else if (result.toLower().contains("record"))
    return StringHandler::Record;
  else if (result.toLower().contains("block"))
    return StringHandler::Block;
  else if (result.toLower().contains("function"))
    return StringHandler::Function;
  else if (result.toLower().contains("package"))
    return StringHandler::Package;
  else if (result.toLower().contains("type"))
    return StringHandler::Type;
  else if (result.toLower().contains("operator"))
    return StringHandler::Operator;
  else if (result.toLower().contains("operator record"))
    return StringHandler::OperatorRecord;
  else if (result.toLower().contains("operator function"))
    return StringHandler::OperatorFunction;
  else if (result.toLower().contains("optimization"))
    return StringHandler::Optimization;
  else
    return StringHandler::Model;
}

/*!
  Gets the parameter value.
  \param className - is the name of the class whose parameter value is retrieved.
  \return the parameter value.
  */
QString OMCProxy::getParameterValue(QString className, QString parameter)
{
  return mpOMCInterface->getParameterValue(className, parameter);
}

/*!
  Gets the list of component modifier names.
  \param className - is the name of the class whose modifier names are retrieved.
  \param name - is the name of the component.
  \return the list of modifier names
  */
QStringList OMCProxy::getComponentModifierNames(QString className, QString name)
{
  return mpOMCInterface->getComponentModifierNames(className, name);
}

/*!
  Gets the component modifier value.
  \param className - is the name of the class whose modifier value is retrieved.
  \param name - is the name of the component.
  \return the value of modifier.
  */
QString OMCProxy::getComponentModifierValue(QString className, QString name)
{
  sendCommand("getComponentModifierValue(" + className + "," + name + ")");
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
  QString expression;
  if (modifierValue.isEmpty()) {
    expression = QString("setComponentModifierValue(%1, %2, $Code(()))").arg(className).arg(modifierName);
  } else if (modifierValue.startsWith("(")) {
    expression = QString("setComponentModifierValue(%1, %2, $Code(%3))").arg(className).arg(modifierName).arg(modifierValue);
  } else {
    expression = QString("setComponentModifierValue(%1, %2, $Code(=%3))").arg(className).arg(modifierName).arg(modifierValue);
  }
  sendCommand(expression);
  if (getResult().toLower().contains("ok")) {
    return true;
  } else {
    QString msg = tr("Unable to set the component modifier value using command <b>%1</b>").arg(expression);
    MessageItem messageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind, Helper::errorLevel);
    mpMainWindow->getMessagesWidget()->addGUIMessage(messageItem);
    return false;
  }
}

/*!
 * \brief OMCProxy::removeComponentModifiers
 * Removes all the modifiers of a component.
 * \param className
 * \param name
 * \return
 */
bool OMCProxy::removeComponentModifiers(QString className, QString name)
{
  return mpOMCInterface->removeComponentModifiers(className, name);
}

QStringList OMCProxy::getExtendsModifierNames(QString className, QString extendsClassName)
{
  sendCommand("getExtendsModifierNames(" + className + "," + extendsClassName + ", useQuotes = true)");
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
  sendCommand("getExtendsModifierValue(" + className + "," + extendsClassName + "," + modifierName + ")");
  return StringHandler::getModifierValue(getResult()).trimmed();
}

bool OMCProxy::setExtendsModifierValue(QString className, QString extendsClassName, QString modifierName, QString modifierValue)
{
  QString expression;
  if (modifierValue.isEmpty()) {
    expression = QString("setExtendsModifierValue(%1, %2, %3, $Code(()))").arg(className).arg(extendsClassName).arg(modifierName);
  } else if (modifierValue.startsWith("(")) {
    expression = QString("setExtendsModifierValue(%1, %2, %3, $Code(%4))").arg(className).arg(extendsClassName).arg(modifierName).arg(modifierValue);
  } else {
    expression = QString("setExtendsModifierValue(%1, %2, %3, $Code(=%4))").arg(className).arg(extendsClassName).arg(modifierName).arg(modifierValue);
  }
  sendCommand(expression);
  if (getResult().toLower().contains("ok")) {
    return true;
  } else {
    QString msg = tr("Unable to set the extends modifier value using command <b>%1</b>").arg(expression);
    MessageItem messageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, msg, Helper::scriptingKind, Helper::errorLevel);
    mpMainWindow->getMessagesWidget()->addGUIMessage(messageItem);
    return false;
  }
}

/*!
  Gets the extends class modifier final prefix.
  \param className - is the name of the class.
  \param extendsClassName - is the name of the extends class whose modifier value is retrieved.
  \param modifierName - is the name of the modifier.
  \return the final prefix.
  */
bool OMCProxy::isExtendsModifierFinal(QString className, QString extendsClassName, QString modifierName)
{
  sendCommand("isExtendsModifierFinal(" + className + "," + extendsClassName + "," + modifierName + ")");
  return StringHandler::unparseBool(getResult());
}

/*!
 * \brief OMCProxy::removeExtendsModifiers
 * Removes the extends modifier of a class.
 * \param className
 * \param extendsClassName
 * \return
 */
bool OMCProxy::removeExtendsModifiers(QString className, QString extendsClassName)
{
  return mpOMCInterface->removeExtendsModifiers(className, extendsClassName);
}

/*!
  Gets the Icon Annotation of a specified class from OMC.
  \param className - is the name of the class.
  \return the icon annotation.
  */
QString OMCProxy::getIconAnnotation(QString className)
{
  QString expression = "getIconAnnotation(" + className + ")";
  sendCommand(expression);
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
  sendCommand(expression);
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
  sendCommand(expression);
  QString result = getResult();
  if (!result.isEmpty()) {
    bool ok;
    int result_number = result.toInt(&ok);
    if (ok) {
      return result_number;
    } else {
      return 0;
    }
  }
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
  sendCommand(expression);
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
  sendCommand(expression);
  return getResult();
}

/*!
 * \brief OMCProxy::getInheritanceCount
 * Returns the inheritance count of a model.
 * \param className - is the name of the model.
 * \return
 * \deprecated Use OMCProxy::getInheritedClasses()
 */
int OMCProxy::getInheritanceCount(QString className)
{
  QString expression = "getInheritanceCount(" + className + ")";
  sendCommand(expression);
  QString result = getResult();
  if (!result.isEmpty()) {
    bool ok;
    int result_number = result.toInt(&ok);
    if (ok) {
      return result_number;
    } else {
      return 0;
    }
  }
  return 0;
}

/*!
 * \brief OMCProxy::getNthInheritedClass
 * Returns the inherited class at a specific index from a model.
 * \param className - is the name of the model.
 * \param num - is the index of inherited class.
 * \return
 * \deprecated Use OMCProxy::getInheritedClasses()
 */
QString OMCProxy::getNthInheritedClass(QString className, int num)
{
  QString expression = "getNthInheritedClass(" + className + ", " + QString::number(num) + ")";
  sendCommand(expression);
  return getResult();
}

/*!
 * \brief OMCProxy::getInheritedClasses
 * Returns the list of Inherited Classes.
 * \param className
 * \return
 * \sa OMCProxy::getInheritanceCount()
 * \sa OMCProxy::getNthInheritedClass()
 */
QList<QString> OMCProxy::getInheritedClasses(QString className)
{
  QList<QString> result = mpOMCInterface->getInheritedClasses(className);
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::getComponents
 * Returns the components of a model with their attributes.\n
 * Creates an object of ComponentInfo for each component.
 * \param className - is the name of the model.
 * \return the list of components
 */
QList<ComponentInfo*> OMCProxy::getComponents(QString className)
{
  QString expression = "getComponents(" + className + ", useQuotes = true)";
  sendCommand(expression);
  QString result = getResult();
  QList<ComponentInfo*> componentInfoList;
  QStringList list = StringHandler::unparseArrays(result);

  for (int i = 0 ; i < list.size() ; i++) {
    if (list.at(i) == "Error") {
      continue;
    }
    ComponentInfo *pComponentInfo = new ComponentInfo();
    pComponentInfo->parseComponentInfoString(list.at(i));
    componentInfoList.append(pComponentInfo);
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
  sendCommand(expression);
  return StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(getResult()));
}

QString OMCProxy::getDocumentationAnnotationInfoHeader(LibraryTreeItem *pLibraryTreeItem, QString infoHeader)
{
  if (pLibraryTreeItem && !pLibraryTreeItem->isRootItem()) {
    QList<QString> docsList = mpOMCInterface->getDocumentationAnnotation(pLibraryTreeItem->getNameStructure());
    infoHeader.prepend(docsList.at(2)); // __OpenModelica_infoHeader section is the 3rd item in the list
    return getDocumentationAnnotationInfoHeader(pLibraryTreeItem->parent(), infoHeader);
  } else {
    return infoHeader;
  }
}

/*!
 * \brief OMCProxy::getDocumentationAnnotation
 * Returns the documentation annotation of a model.\n
 * The documenation is not standardized, so for any non-standard html documentation add <pre></pre> tags.
 * \param pLibraryTreeItem
 * \return the documentation
 */
QString OMCProxy::getDocumentationAnnotation(LibraryTreeItem *pLibraryTreeItem)
{
  QList<QString> docsList = mpOMCInterface->getDocumentationAnnotation(pLibraryTreeItem->getNameStructure());
  QString infoHeader = "";
  infoHeader = getDocumentationAnnotationInfoHeader(pLibraryTreeItem->parent(), infoHeader);
  // get the class comment and show it as the first line on the documentation page.
  QString doc = getClassComment(pLibraryTreeItem->getNameStructure());
  if (!doc.isEmpty()) doc.prepend("<h4>").append("</h4>");
  doc.prepend(QString("<h2>").append(pLibraryTreeItem->getNameStructure()).append("</h2>"));
  for (int ele = 0 ; ele < docsList.size() ; ele++) {
    QString docElement = docsList[ele];
    if (docElement.isEmpty()) {
      continue;
    }
    if (ele == 0) {         // info section
      doc += "<p style=\"font-size:12px;\"><strong><u>Information</u></strong></p>";
    } else if (ele == 1) {    // revisions section
      doc += "<p style=\"font-size:12px;\"><strong><u>Revisions</u></strong></p>";
    } else if (ele == 2) {    // __OpenModelica_infoHeader section
      infoHeader.append(docElement);
      continue;
    }
    docElement = docElement.trimmed();
    docElement.remove(QRegExp("<html>|</html>|<HTML>|</HTML>|<head>|</head>|<HEAD>|</HEAD>|<body>|</body>|<BODY>|</BODY>"));
    doc += docElement;
  }
  QString documentation = QString("<html>\n"
                                  "  <head>\n"
                                  "    %1\n"
                                  "  </head>\n"
                                  "  <body>\n"
                                  "    %2\n"
                                  "  </body>\n"
                                  "</html>").arg(infoHeader).arg(doc);
  documentation = makeDocumentationUriToFileName(documentation);
  /*! @note We convert modelica:// to modelica:///.
    * This tells QWebview that these links doesn't have any host.
    * Why we are doing this. Because,
    * QUrl converts the url host to lowercase. So if we use modelica:// then links like modelica://Modelica.Icons will be converted to
    * modelica://modelica.Icons. We use the LibraryTreeModel->findLibraryTreeItem() method to find the classname
    * by doing the search using the Qt::CaseInsensitive. This will be wrong if we have Modelica classes like Modelica.Icons and modelica.Icons
    * \see DocumentationViewer::processLinkClick
    */
  return documentation.replace("modelica://", "modelica:///");
}

/*!
 * \brief OMCProxy::getClassComment
 * Gets the class comment.
 * \param className - is the name of the class.
 * \return class comment.
 * \param className
 * \return
 */
QString OMCProxy::getClassComment(QString className)
{
  return mpOMCInterface->getClassComment(className);
}

/*!
  Change the current working directory of OMC. Also retunrs the current working directory.
  \param directory - the new working directory location.
  \return the current working directory
  */
QString OMCProxy::changeDirectory(QString directory)
{
  return mpOMCInterface->cd(directory);
}

/*!
  Loads the library.
  \param library - the library name.
  \param version -  the version of the library.
  \return true on success
  */
bool OMCProxy::loadModel(QString className, QString priorityVersion, bool notify, QString languageStandard, bool requireExactVersion)
{
  bool result = false;
  QList<QString> priorityVersionList;
  priorityVersionList << priorityVersion;
  result = mpOMCInterface->loadModel(className, priorityVersionList, notify, languageStandard, requireExactVersion);
  printMessagesStringInternal();
  return result;
}

/*!
  Loads a file in OMC
  \param fileName - the file to load.
  \return true on success
  */
bool OMCProxy::loadFile(QString fileName, QString encoding, bool uses)
{
  bool result = false;
  fileName = fileName.replace('\\', '/');
  result = mpOMCInterface->loadFile(fileName, encoding, uses);
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::loadString
 * Loads a string in OMC
 * \param value - the string to load.
 * \param fileName
 * \param encoding
 * \param merge
 * \param checkError
 * \return true on success
 */
bool OMCProxy::loadString(QString value, QString fileName, QString encoding, bool merge, bool checkError)
{
  bool result = mpOMCInterface->loadString(value, fileName, encoding, merge);
  if (checkError) {
    printMessagesStringInternal();
  }
  return result;
}

/*!
  Parse the file. Doesn't load it into OMC.
  \param fileName - the file to parse.
  \return true on success
  */
QList<QString> OMCProxy::parseFile(QString fileName, QString encoding)
{
  QList<QString> result;
  fileName = fileName.replace('\\', '/');
  result = mpOMCInterface->parseFile(fileName, encoding);
  if (result.isEmpty()) {
    printMessagesStringInternal();
  }
  return result;
}

/*!
  Parse the string. Doesn't load it into OMC.
  \param value - the string to parse.
  \return the list of models inside the string.
  */
QList<QString> OMCProxy::parseString(QString value, QString fileName)
{
  QList<QString> result;
  result = mpOMCInterface->parseString(value, fileName);
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::createClass
 * Creates a new class in OMC.
 * \param type - the class type.
 * \param className - the class name.
 * \param pExtendsLibraryTreeItem - the extends class.
 * \return
 */
bool OMCProxy::createClass(QString type, QString className, LibraryTreeItem *pExtendsLibraryTreeItem)
{
  QString expression;
  if (!pExtendsLibraryTreeItem) {
    expression = QString("%1 %2 end %3;").arg(type).arg(className).arg(className);
  } else {
    expression = QString("%1 %2 extends %3; end %4;").arg(type).arg(className).arg(pExtendsLibraryTreeItem->getNameStructure()).arg(className);
  }
  return loadString(expression, className, Helper::utf8, false, false);
}

/*!
 * \brief OMCProxy::createSubClass
 * Creates a new sub class in OMC.
 * \param type - the class type.
 * \param className - the class name.
 * \param pParentLibraryTreeItem - the parent class.
 * \param pExtendsLibraryTreeItem - the extends class.
 * \return
 */
bool OMCProxy::createSubClass(QString type, QString className, LibraryTreeItem *pParentLibraryTreeItem,
                              LibraryTreeItem *pExtendsLibraryTreeItem)
{
  QString expression;
  if (!pExtendsLibraryTreeItem) {
    expression = QString("within %1; %2 %3 end %4;").arg(pParentLibraryTreeItem->getNameStructure()).arg(type).arg(className).arg(className);
  } else {
    expression = QString("within %1; %2 %3 extends %4; end %5;").arg(pParentLibraryTreeItem->getNameStructure()).arg(type).arg(className)
        .arg(pExtendsLibraryTreeItem->getNameStructure()).arg(className);
  }
  QString fileName;
  if (pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    fileName = pParentLibraryTreeItem->mClassInformation.fileName;
  } else {
    fileName = pParentLibraryTreeItem->getNameStructure() + "." + className;
  }
  return loadString(expression, fileName, Helper::utf8, false, false);
}

/*!
  Checks whether the class already exists in OMC or not.
  \param className - the name for the class to check.
  \return true on success.
  */
bool OMCProxy::existClass(QString className)
{
  sendCommand("existClass(" + className + ")");
  bool result = StringHandler::unparseBool(getResult());
  getErrorString();
  return result;
}

/*!
  Renames a class.
  \param oldName - the class old name.
  \param newName - the class new name.
  \return true on success.
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
  \return true on success.
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
 * \brief OMCProxy::getSourceFile
 * Returns the file name of a model.
 * \param className - the name of the class.
 * \return the file name.
 */
QString OMCProxy::getSourceFile(QString className)
{
  QString file = mpOMCInterface->getSourceFile(className);
  if (file.compare("<interactive>") == 0) {
    return "";
  } else {
    return file;
  }
}

/*!
 * \brief OMCProxy::setSourceFile
 * Sets a file name of a model.
 * \param className - the name of the class.
 * \param path - the full location
 * \return true on success.
 */
bool OMCProxy::setSourceFile(QString className, QString path)
{
  return mpOMCInterface->setSourceFile(className, path);
}

/*!
 * \brief OMCProxy::save
 * Saves a model.
 * \param className - the name of the class.
 * \deprecated OMEdit saves the files by itself and doesn't use OMC save API anymore.
 * \return true on success.
 */
bool OMCProxy::save(QString className)
{
  sendCommand("save(" + className + ")");
  bool result = StringHandler::unparseBool(getResult());
  if (!result) {
    printMessagesStringInternal();
  }
  return result;
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
 * \brief OMCProxy::saveTotalModel
 * Save class with all used classes to a file.
 * \param fileName - the file to save in.
 * \param className - the name of the class.
 * \return true on success.
 */
bool OMCProxy::saveTotalModel(QString fileName, QString className)
{
  bool result = mpOMCInterface->saveTotalModel(fileName, className);
  if (!result) {
    printMessagesStringInternal();
  }
  return result;
}

/*!
 * \brief OMCProxy::list
 * Retruns the text of the class.
 * \param className - the name of the class.
 * \return the class text.
 * \deprecated
 * \sa OMCProxy::listFile()
 * \sa OMCProxy::diffModelicaFileListings()
 */
QString OMCProxy::list(QString className)
{
  sendCommand("list(" + className + ")");
  return StringHandler::unparse(getResult());
}

/*!
 * \brief OMCProxy::listFile
 * Lists the contents of the file given by the class.
 * \param className
 * \return
 */
QString OMCProxy::listFile(QString className)
{
  QString result = mpOMCInterface->listFile(className);
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::diffModelicaFileListings
 * Creates diffs of two strings corresponding to Modelica files.
 * \param before
 * \param after
 * \return
 */
QString OMCProxy::diffModelicaFileListings(QString before, QString after)
{
  QString escapedBefore = StringHandler::escapeString(before);
  QString escapedAfter = StringHandler::escapeString(after);
  QString result;
  // only use the diffModelicaFileListings when preserve text indentation settings is true
  if (mpMainWindow->getOptionsDialog()->getModelicaTextEditorPage()->getPreserveTextIndentationCheckBox()->isChecked()) {
    sendCommand("diffModelicaFileListings(\"" + escapedBefore + "\", \"" + escapedAfter + "\", OpenModelica.Scripting.DiffFormat.plain)");
    result = StringHandler::unparse(getResult());
    printMessagesStringInternal();
    if (result.isEmpty()) {
      result = after; // use omc pretty-printing since diffModelicaFileListings() failed.
    }
  } else {
    result = after;
  }
  if (mpMainWindow->isDebug()) {
    mpOMCDiffBeforeTextBox->setPlainText(before);
    mpOMCDiffAfterTextBox->setPlainText(after);
    mpOMCDiffMergedTextBox->setPlainText(result);
  }
  return result;
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
  sendCommand("getDefaultComponentName(" + className + ")");
  if (getResult().compare("{}") == 0)
    return "";

  return StringHandler::unparse(getResult());
}

/*!
  Retunrs the default component prefixes of a class.
  \param className - the name of the class.
  \return the default component prefixes.
  */
QString OMCProxy::getDefaultComponentPrefixes(QString className)
{
  sendCommand("getDefaultComponentPrefixes(" + className + ")");
  if (getResult().compare("{}") == 0)
    return "";

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
  sendCommand("setComponentProperties(" + className + "," + componentName + ",{" + isFinal + "," + isFlow + "," + isProtected +
              "," + isReplaceAble + "}, {\"" + variability + "\"}, {" + isInner + "," + isOuter + "}, {\"" + causality + "\"})");

  if (getResult().toLower().contains("error")) {
    return false;
  }
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
 * \brief OMCProxy::setComponentDimensions
 * Sets the component dimensions
 * \param className - the name of the class.
 * \param componentName - the name of the component.
 * \param dimensions - the component dimensions.
 * \return true on success
 */
bool OMCProxy::setComponentDimensions(QString className, QString componentName, QString dimensions)
{
  sendCommand("setComponentDimensions(" + className + "," + componentName + "," + dimensions + ")");
  if (getResult().contains("Ok")) {
    return true;
  } else {
    return false;
  }
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
 * \brief OMCProxy::simulate
 * Simulate the model. Creates an execuatble and runs it.
 * \param className - the name of the class.
 * \param simualtionParameters - the simulation parameters.
 * \return true on success.
 * \deprecated OMEdit only use OMCProxy::buildModel(QString className, QString simualtionParameters)
 */
bool OMCProxy::simulate(QString className, QString simualtionParameters)
{
  sendCommand("OMEdit_simulate_result:=simulate(" + className + "," + simualtionParameters + ")");
  sendCommand("OMEdit_simulate_result.resultFile");
  if (StringHandler::unparse(getResult()).isEmpty()) {
    return false;
  } else {
    return true;
  }
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
  mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  return res;
}

/*!
 * \brief OMCProxy::readSimulationResultVars
 * Reads the simulation result variables from the result file.
 * \param fileName - the result file name
 * \return the list of variables.
 */
QStringList OMCProxy::readSimulationResultVars(QString fileName)
{
  QStringList variablesList = mpOMCInterface->readSimulationResultVars(fileName, true, false);
  qSort(variablesList.begin(), variablesList.end());
  printMessagesStringInternal();
  return variablesList;
}

/*!
 * \brief OMCProxy::closeSimulationResultFile
 * Closes the current simulation result file.\n
 * Only valid for Windows.\n
 * On Linux it simply returns true without doing anything.
 * \return true on success.
 */
bool OMCProxy::closeSimulationResultFile()
{
#ifdef Q_OS_WIN
  return mpOMCInterface->closeSimulationResultFile();
#else
  return true;
#endif
}

/*!
 * \brief OMCProxy::checkModel
 * Checks the model. Checks model balance in terms of number of variables and equations.
 * \param className - the name of the class.
 * \return the model check result
 */
QString OMCProxy::checkModel(QString className)
{
  QString result = mpOMCInterface->checkModel(className);
  printMessagesStringInternal();
  mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  return result;
}

/*!
  Converts a given ngspice netlist to equivalent Modelica code.
  Filename is the name of the ngspice netlist. Subcircuit and device model (.lib) files
  are to be present in the same directory. The Modelica model is created in the same directory
  as that of netlist file. - added by Rakhi
  */
bool OMCProxy::ngspicetoModelica(QString fileName)
{
  fileName = fileName.replace('\\', '/');
  sendCommand("ngspicetoModelica(\"" + fileName + "\")");
  return StringHandler::unparseBool(getResult());
}

/*!
 * \brief OMCProxy::checkAllModelsRecursive
 * Checks all nested modelica classes. Checks model balance in terms of number of variables and equations.
 * \param className - the name of the class.
 * \return the model check result
 */
QString OMCProxy::checkAllModelsRecursive(QString className)
{
  QString result = mpOMCInterface->checkAllModelsRecursive(className, false);
  printMessagesStringInternal();
  mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  return result;
}

/*!
 * \brief OMCProxy::instantiateModel
 * Instantiates the model.
 * \param className - the name of the class.
 * \return the instantiated model
 */
QString OMCProxy::instantiateModel(QString className)
{
  QString result = mpOMCInterface->instantiateModel(className);
  printMessagesStringInternal();
  mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  return result;
}

/*!
 * \brief OMCProxy::isExperiment
 * Returns the simulation options stored in the model.
 * \param className - the name of the class.
 * \return the simulation options
 */
bool OMCProxy::isExperiment(QString className)
{
  return mpOMCInterface->isExperiment(className);
}

/*!
 * \brief OMCProxy::getSimulationOptions
 * Returns the simulation options stored in the model.
 * \param className - the name of the class.
 * \param defaultTolerance
 * \return the simulation options
 */
OMCInterface::getSimulationOptions_res OMCProxy::getSimulationOptions(QString className, double defaultTolerance)
{
  return mpOMCInterface->getSimulationOptions(className, 0.0, 1.0, defaultTolerance, 500, 0.0);
}

/*!
 * \brief OMCProxy::translateModelFMU
 * Creates the FMU of the model.
 * \param className - the name of the class.
 * \param version - the fmu version
 * \param type - the fmu type
 * \param fileNamePrefix
 * \return
 */
bool OMCProxy::translateModelFMU(QString className, double version, QString type, QString fileNamePrefix)
{
  bool result = false;
  fileNamePrefix = fileNamePrefix.isEmpty() ? "<default>" : fileNamePrefix;
  QString res = mpOMCInterface->translateModelFMU(className, QString::number(version), type, fileNamePrefix);
  if (res.compare("SimCode: The model " + className + " has been translated to FMU") == 0) {
    result = true;
    mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  }
  printMessagesStringInternal();
  return result;
}

/*!
  Creates the XML of the model.
  \param className - the name of the class.
  \return the created XML location
  */
bool OMCProxy::translateModelXML(QString className)
{
  bool result = false;
  sendCommand("translateModelXML(" + className + ")");
  if (StringHandler::unparse(getResult()).compare("SimCode: The model " + className + " has been translated to XML") == 0) {
    result = true;
    mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->loadDependentLibraries(getClassNames());
  }
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::importFMU
 * Imports the FMU
 * \param fmuName - the FMU location
 * \param outputDirectory - the output location
 * \param logLevel - the logging level
 * \param debugLogging - enables the debug logging for the imported FMU.
 * \param generateInputConnectors - generates the input variables as connectors
 * \param generateOutputConnectors - generates the output variables as connectors.
 * \return generated Modelica Code file path
 */
QString OMCProxy::importFMU(QString fmuName, QString outputDirectory, int logLevel, bool debugLogging, bool generateInputConnectors,
                            bool generateOutputConnectors)
{
  outputDirectory = outputDirectory.isEmpty() ? "<default>" : outputDirectory;
  QString fmuFileName = mpOMCInterface->importFMU(fmuName, outputDirectory, logLevel, true, debugLogging, generateInputConnectors, generateOutputConnectors);
  printMessagesStringInternal();
  return fmuFileName;
}

/*!
  Reads the matching algorithm used during the simulation.
  \return the name of the matching algorithm
  */
QString OMCProxy::getMatchingAlgorithm()
{
  return mpOMCInterface->getMatchingAlgorithm();
}

/*!
 * \brief OMCProxy::getAvailableMatchingAlgorithms
 * Reads the list of available matching algorithms.
 * \return
 */
OMCInterface::getAvailableMatchingAlgorithms_res OMCProxy::getAvailableMatchingAlgorithms()
{
  return mpOMCInterface->getAvailableMatchingAlgorithms();
}

/*!
 * \brief OMCProxy::getIndexReductionMethod
 * Reads the index reduction method used during the simulation.
 * \return the name of the index reduction method.
 */
QString OMCProxy::getIndexReductionMethod()
{
  return mpOMCInterface->getIndexReductionMethod();
}

/*!
  Sets the matching algorithm.
  \param matchingAlgorithm - the macthing algorithm to set
  \return true on success
  */
bool OMCProxy::setMatchingAlgorithm(QString matchingAlgorithm)
{
  sendCommand("setMatchingAlgorithm(\"" + matchingAlgorithm + "\")");
  if (StringHandler::unparseBool(getResult())) {
    return true;
  } else {
    printMessagesStringInternal();
    return false;
  }
}

/*!
 * \brief OMCProxy::getAvailableIndexReductionMethods
 * Reads the list of available index reduction methods.
 * \return
 */
OMCInterface::getAvailableIndexReductionMethods_res OMCProxy::getAvailableIndexReductionMethods()
{
  return mpOMCInterface->getAvailableIndexReductionMethods();
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
 * \brief OMCProxy::setCommandLineOptions
 * Sets the OMC flags.
 * \param options - a space separated list fo OMC command line options e.g. +d=initialization +cheapmatchingAlgorithm=3
 * \return true on success
 */
bool OMCProxy::setCommandLineOptions(QString options)
{
  bool result = mpOMCInterface->setCommandLineOptions(options);
  if (!result) {
    printMessagesStringInternal();
  }
  return result;
}

/*!
 * \brief OMCProxy::clearCommandLineOptions
 * Clears the OMC flags.
 * \return true on success
 */
bool OMCProxy::clearCommandLineOptions()
{
  bool result = mpOMCInterface->clearCommandLineOptions();
  if (result) {
    return true;
  } else {
    printMessagesStringInternal();
    return false;
  }
}

/*!
 * \brief OMCProxy::makeDocumentationUriToFileName
 * Helper function for getDocumentationAnnotation. Takes the documentation html and replaces the modelica links with absolute pahts.\n
 * This function also makes the html valid. e.g html like,\n
 *   <p>Test</p><html><body>This is body</body></html>\n
 *  will become,\n
 *   <html><head></head><body><p>Test</p>This is body</body></html>
 * \param documentation - in html form.
 * \return New documentation in html form.
 */
QString OMCProxy::makeDocumentationUriToFileName(QString documentation)
{
  QWebPage *pWebPage = new QWebPage;
  pWebPage->settings()->setAttribute(QWebSettings::JavascriptEnabled, false);
  connect(pWebPage, SIGNAL(loadFinished(bool)), pWebPage, SLOT(deleteLater()));
  QWebFrame *pWebFrame = pWebPage->mainFrame();
  pWebFrame->setContent(QByteArray(documentation.toStdString().c_str()), "text/html");
  QWebElement webElement = pWebFrame->documentElement();
  QWebElementCollection tags = webElement.findAll("img,script,link");
  foreach (QWebElement tag, tags) {
    QString attributeName = "src";
    if (tag.tagName().toLower().compare("link") == 0) {
      attributeName = "href";
    }
    QString attributeValue = tag.attribute(attributeName);
    if (attributeValue.startsWith("modelica://")) {
      QString imgFileName = uriToFilename(attributeValue);
#ifdef WIN32
      tag.setAttribute(attributeName, "file:///" + imgFileName);
#else
      tag.setAttribute(attributeName, "file://" + imgFileName);
#endif
    } else {
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
  /* the second argument of uriToFilename result is error string. */
  if (results.size() > 1 && !results.at(1).isEmpty()) {
    QString errorString = results.at(1);
    mpMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, errorString,
                                                                 Helper::scriptingKind, Helper::errorLevel));
  }
  if (results.size() > 0) {
    return results.first();
  } else {
    return "";
  }
}

/*!
 * \brief OMCProxy::getModelicaPath
 * Gets the modelica library path
 * \return the library path
 */
QString OMCProxy::getModelicaPath()
{
  QString result = mpOMCInterface->getModelicaPath();
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::getAvailableLibraries
 * Gets the available OpenModelica libraries.
 * \return the list of libaries.
 */
QStringList OMCProxy::getAvailableLibraries()
{
  return mpOMCInterface->getAvailableLibraries();
}

/*!
 * \brief OMCProxy::getDerivedClassModifierValue
 * Gets the derived class modifier value.
 * \param className - the name of the derived class.
 * \param modifierName - the modifier name.
 * \return the value of the modifier.
 */
QString OMCProxy::getDerivedClassModifierValue(QString className, QString modifierName)
{
  sendCommand("getDerivedClassModifierValue(" + className + "," + modifierName + ")");
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
 * \brief OMCProxy::numProcessors
 * Gets the number of processors.
 * \return the number of processors.
 */
int OMCProxy::numProcessors()
{
  return mpOMCInterface->numProcessors();
}

/*!
 * \brief OMCProxy::help
 * \param topic
 * \return
 */
QString OMCProxy::help(QString topic)
{
  return mpOMCInterface->help(topic);
}

/*!
 * \brief OMCProxy::getConfigFlagValidOptions
 * \param topic
 * \return
 */
OMCInterface::getConfigFlagValidOptions_res OMCProxy::getConfigFlagValidOptions(QString topic)
{
  return mpOMCInterface->getConfigFlagValidOptions(topic);
}

/*!
 * \brief OMCProxy::setDebugFlags
 * \param debugFlags
 * \return
 */
bool OMCProxy::setDebugFlags(QString debugFlags)
{
  sendCommand("setDebugFlags(\"" + debugFlags + "\")");
  return StringHandler::unparseBool(getResult());
}

/*!
 * \brief OMCProxy::exportToFigaro
 * Exports the model to figaro
 * \param className
 * \param directory
 * \param database
 * \param mode
 * \param options
 * \param processor
 * \return
 */
bool OMCProxy::exportToFigaro(QString className, QString directory, QString database, QString mode, QString options, QString processor)
{
  bool result = false;
  result = mpOMCInterface->exportToFigaro(className, directory, database, mode, options, processor);
  if (!result) {
    printMessagesStringInternal();
  }
  return result;
}

/*!
 * \brief OMCProxy::copyClass
 * Copies the class with new name to within path.
 * \param className - the class that should be copied
 * \param newClassName - the name for new class
 * \param withIn - the with in path for new class
 * \return
 */
bool OMCProxy::copyClass(QString className, QString newClassName, QString withIn)
{
  bool result = mpOMCInterface->copyClass(className, newClassName, withIn.isEmpty() ? "TopLevel" : withIn);
  if (!result) printMessagesStringInternal();
  return result;
}

/*!
  Gets the list of enumeration literals of the class.
  \param className - the enumeration class
  \return the list of enumeration literals
  */
QStringList OMCProxy::getEnumerationLiterals(QString className)
{
  sendCommand("getEnumerationLiterals(" + className + ")");
  QStringList enumerationLiterals = StringHandler::unparseStrings(getResult());
  printMessagesStringInternal();
  return enumerationLiterals;
}

/*!
 * \brief OMCProxy::getSolverMethods
 * Returns the list of solvers name and their description.
 * \param methods
 * \param descriptions
 */
void OMCProxy::getSolverMethods(QStringList *methods, QStringList *descriptions)
{
  for (int i = S_UNKNOWN + 1 ; i < S_MAX ; i++) {
    *methods << SOLVER_METHOD_NAME[i];
    *descriptions << SOLVER_METHOD_DESC[i];
  }
}

/*!
 * \brief OMCProxy::getInitializationMethods
 * Returns the list of initialization methods name and their description.
 * \param methods
 * \param descriptions
 */
void OMCProxy::getInitializationMethods(QStringList *methods, QStringList *descriptions)
{
  for (int i = IIM_UNKNOWN + 1 ; i < IIM_MAX ; i++) {
    *methods << INIT_METHOD_NAME[i];
    *descriptions << INIT_METHOD_DESC[i];
  }
}

/*!
 * \brief OMCProxy::getLinearSolvers
 * Returns the list of linear solvers name and their description.
 * \param methods
 * \param descriptions
 */
void OMCProxy::getLinearSolvers(QStringList *methods, QStringList *descriptions)
{
  for (int i = LS_NONE + 1 ; i < LS_MAX ; i++) {
    *methods << LS_NAME[i];
    *descriptions << LS_DESC[i];
  }
}

/*!
 * \brief OMCProxy::getNonLinearSolvers
 * Returns the list of non-linear solvers name and their description.
 * \param methods
 * \param descriptions
 */
void OMCProxy::getNonLinearSolvers(QStringList *methods, QStringList *descriptions)
{
  for (int i = NLS_NONE + 1 ; i < NLS_MAX ; i++) {
    *methods << NLS_NAME[i];
    *descriptions << NLS_DESC[i];
  }
}

/*!
 * \brief OMCProxy::moveClass
 * Moves the class by offset in its enclosing class.
 * \param className
 * \param offset
 * \return
 */
bool OMCProxy::moveClass(QString className, int offset)
{
  return mpOMCInterface->moveClass(className, offset);
}

/*!
 * \brief OMCProxy::moveClassToTop
 * Moves the class to top of its enclosing class.
 * \param className
 * \return
 */
bool OMCProxy::moveClassToTop(QString className)
{
  return mpOMCInterface->moveClassToTop(className);
}

/*!
 * \brief OMCProxy::moveClassToBottom
 * Moves the class to bottom of its enclosing class.
 * \param className
 * \return
 */
bool OMCProxy::moveClassToBottom(QString className)
{
  return mpOMCInterface->moveClassToBottom(className);
}

/*!
 * \brief OMCProxy::inferBindings
 * Updates the bindings.
 * \param className
 * \return
 */
bool OMCProxy::inferBindings(QString className)
{
  bool result = mpOMCInterface->inferBindings(className);
  printMessagesStringInternal();
  return result;
}

/*!
 * \brief OMCProxy::getUses
 * Returns the uses annotation.
 * \param className
 * \return
 */
QList<QList<QString > > OMCProxy::getUses(QString className)
{
  QList<QList<QString > > result = mpOMCInterface->getUses(className);
  printMessagesStringInternal();
  return result;
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
