/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

//! @file   OMCProxy.cpp
//! @author Sonia Tariq <sonta273@student.liu.se>
//! @date   2010-06-25

//! @brief Contains functions used for communication with OpenModelica Compiler.

#include <stdexcept>
#include <stdlib.h>
#include <iostream>

#include "OMCProxy.h"
#include "OMCThread.h"
#include "StringHandler.h"
#include "../../Compiler/runtime/config.h"

using namespace OMPlot;

//! @class OMCProxy
//! @brief It contains the reference of the CORBA object used to communicate with the OpenModelica Compiler.

//! Constructor
//! @param pParent is the pointer to MainWindow.
//! @param displayErrors is the boolean variable used for displaying errors.
OMCProxy::OMCProxy(MainWindow *pParent, bool displayErrors)
    : mOMC(0), mHasInitialized(false), mName(Helper::omcServerName) ,mResult(""), mDisplayErrors(displayErrors)
{
    this->mpParentMainWindow = pParent;
    this->mAnnotationVersion = OMCProxy::ANNOTATION_VERSION3X;
    this->mCurrentCommandIndex = -1;
    this->mpOMCLogger = new QDialog();
    this->mpOMCLogger->setWindowFlags(Qt::WindowTitleHint);
    this->mpOMCLogger->setMinimumSize(640, 480);
    this->mpOMCLogger->setWindowIcon(QIcon(":/Resources/icons/console.png"));
    this->mpOMCLogger->setWindowTitle(QString(Helper::applicationName).append(" - OMC Messages Log"));
    // Set the QTextEdit Box
    this->mpPlainTextEdit = new QPlainTextEdit();
    this->mpPlainTextEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    this->mpPlainTextEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    this->mpPlainTextEdit->setReadOnly(true);
    this->mpPlainTextEdit->setLineWrapMode(QPlainTextEdit::WidgetWidth);
    //this->mpPlainTextEdit->setAutoFormatting(QTextEdit::AutoNone);
    // Set the Layout
    QHBoxLayout *horizontallayout = new QHBoxLayout;
    horizontallayout->setContentsMargins(0, 0, 0, 0);
    mpExpressionTextBox = new CustomExpressionBox(this);
    mpSendButton = new QPushButton("Send");
    connect(mpSendButton, SIGNAL(clicked()), SLOT(sendCustomExpression()));
    horizontallayout->addWidget(mpExpressionTextBox);
    horizontallayout->addWidget(mpSendButton);
    QVBoxLayout *verticalallayout = new QVBoxLayout;
    verticalallayout->addWidget(this->mpPlainTextEdit);
    verticalallayout->addLayout(horizontallayout);
    mpOMCLogger->setLayout(verticalallayout);
    //start the server
    if(!startServer())      // if we are unable to start OMC. Exit the application.
    {
        mpParentMainWindow->mExitApplication = true;
        return;
    }
}

//! Destructor
OMCProxy::~OMCProxy()
{
    delete mpOMCLogger;
}

//! Puts the previous send OMC command in the send command text box.
//! Invoked by the up arrow key.
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

//! Puts the most recently send OMC command in the send command text box.
//! Invoked by the down arrow key.
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

//! Adds the OMC command to mCommandsMap, command as key and result as value.
void OMCProxy::addExpressionInCommandMap(QString expression, QString result)
{
    if (expression.contains("Modelica."))
        mCommandsMap.insert(expression, result);
}

//! Returns the command result by looking it into the mCommandsMap.
//! @return QString the command result
QString OMCProxy::getCommandFromMap(QString expression)
{
    return mCommandsMap.value(expression, QString());
}

//! Returns the command result by looking it into the mCommandsMap.
//! @return QString the command result
void OMCProxy::setExpression(QString expression)
{
    mExpression = expression;
}

//! Returns the most recent OMC command.
//! @return QString the command.
QString OMCProxy::getExpression()
{
    return mExpression;
}

//! Writes the commands to the omeditcommands.log file.
//! @param expression the command to write
//! @param commandTime the command start time
void OMCProxy::writeCommandLog(QString expression, QTime* commandTime)
{
    if (mCommandsLogFileTextStream.device())
    {
        mCommandsLogFileTextStream << expression << " " << commandTime->currentTime().toString(tr("hh:mm:ss:zzz"));
        mCommandsLogFileTextStream << "\n";
        mCommandsLogFileTextStream.flush();
    }
}

//! Writes the command response to the omeditcommands.log file.
//! @param commandTime the command end time
void OMCProxy::writeCommandResponseLog(QTime* commandTime)
{
    if (mCommandsLogFileTextStream.device())
    {
        mCommandsLogFileTextStream << getResult() << " " << commandTime->currentTime().toString(tr("hh:mm:ss:zzz"));
        mCommandsLogFileTextStream << "\n";
        mCommandsLogFileTextStream << "Elapsed Time :: " << QString::number((double)commandTime->elapsed() / 1000).append(" secs");
        mCommandsLogFileTextStream << "\n\n";
        mCommandsLogFileTextStream.flush();
    }
}

//! Starts the OpenModelica Compiler.
//! On Windows look for OPENMODELICAHOME environment variable. On Linux read the installation directory from config.h file.
//! Runs the omc with +c and +d=interactiveCorba flags.
//! +c flag creates a CORBA IOR file with name e.g openmodelica.objid.OMEdit{1ABB3DAA-C925-47E8-85F9-3DE6F3F7E79C}154302842
//! For each instance of OMEdit a new omc is run.
bool OMCProxy::startServer()
{
    try
    {
        QString msg;
        const char *omhome = getenv("OPENMODELICAHOME");
        QString omcPath;
#ifdef WIN32
        if (!omhome)
            throw std::runtime_error(GUIMessages::getMessage(GUIMessages::OPEN_MODELICA_HOME_NOT_FOUND).toStdString());
        omcPath = QString( omhome ) + "/bin/omc.exe";
#else /* unix */
        omcPath = (omhome ? QString(omhome)+"/bin/omc" : QString(CONFIG_DEFAULT_OPENMODELICAHOME) + "/bin/omc");
#endif

        // Check the IOR file created by omc.exe
        QFile objectRefFile;
        QString fileIdentifier;
        if (mDisplayErrors)
            fileIdentifier = qApp->sessionId().append(QTime::currentTime().toString(tr("hh:mm:ss:zzz")).remove(":"));
        else
            fileIdentifier = QString("temp-").append(qApp->sessionId().append(QTime::currentTime().toString(tr("hh:mm:ss:zzz")).remove(":")));

#ifdef WIN32 // Win32
        objectRefFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.objid.").append(this->mName).append(fileIdentifier));
#else // UNIX environment
        char *user = getenv("USER");
        if (!user) { user = "nobody"; }
        objectRefFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.").append(*(new QString(user))).append(".objid.").append(this->mName).append(fileIdentifier));
#endif

        if (objectRefFile.exists())
            objectRefFile.remove();

        mObjectRefFile = objectRefFile.fileName();
        // Start the omc.exe
        QStringList parameters;
        parameters << QString("+c=").append(this->mName).append(fileIdentifier) << QString("+d=interactiveCorba");
        QProcess *omcProcess = new QProcess();
        QFile omcOutputFile;
#ifdef WIN32 // Win32
        omcOutputFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.omc.output.").append(this->mName));
#else // UNIX environment
        char *user = getenv("USER");
        if (!user) { user = "nobody"; }
        omcOutputFile.setFileName(QString(QDir::tempPath()).append(QDir::separator()).append("openmodelica.").append(*(new QString(user))).append(".omc.output.").append(this->mName));
#endif
        omcProcess->setProcessChannelMode(QProcess::MergedChannels);
        omcProcess->setStandardOutputFile(omcOutputFile.fileName());
        omcProcess->start(omcPath, parameters);
        // wait for the server to start.
        int ticks = 0;
        while (!objectRefFile.exists())
        {
            OMCThread::sleep(1);
            ticks++;
            if (ticks > 20)
            {
                msg = "Unable to find " + Helper::applicationName + " server, Object reference file " + mObjectRefFile + " not created.";
                throw std::runtime_error(msg.toStdString());
            }
        }
        // ORB initialization.
        int argc = 2;
        static const char *argv[] = { "-ORBgiopMaxMsgSize", "10485760" };
        CORBA::ORB_var orb = CORBA::ORB_init(argc, (char **)argv);

        objectRefFile.open(QIODevice::ReadOnly);

        char buf[1024];
        objectRefFile.readLine( buf, sizeof(buf) );
        QString uri( (const char*)buf );

        CORBA::Object_var obj = orb->string_to_object(uri.trimmed().toLocal8Bit());

        mOMC = OmcCommunication::_narrow(obj);
        mHasInitialized = true;
    }
    catch(std::exception &e)
    {
        if (mDisplayErrors)
        {
            QString msg = e.what();
            QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                                  msg.append("\n\n").append(Helper::applicationName).append(" will close."), "OK");
        }
        mHasInitialized = false;
        return false;
    }
    catch (CORBA::Exception&)
    {
        if (mDisplayErrors)
        {
            QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                                  QString("Unable to communicate with ").append(Helper::applicationName).append(" server.")
                                  .append("\n\n").append(Helper::applicationName).append(" will close."), "OK");
        }
        mHasInitialized = false;
        return false;
    }
    // set OpenModelicaHome variable
    sendCommand("getInstallationDirectoryPath()");
    Helper::OpenModelicaHome = StringHandler::removeFirstLastQuotes(getResult());
    // set temp path variable
    sendCommand("getTempDirectoryPath()");
    QString tmpPath = getResult()+"/OpenModelica/OMEdit/";
    tmpPath.remove("\"");
    if (!QDir().exists(tmpPath))
    {
        if (QDir().mkpath(tmpPath))
            changeDirectory(tmpPath);
    }
    else
        changeDirectory(tmpPath);
    // set the OpenModelicaLibrary variable.
    sendCommand("getModelicaPath()");
    Helper::OpenModelicaLibrary = StringHandler::removeFirstLastQuotes(getResult());
    // create a file to write OMEdit commands log
    mCommandsLogFile.setFileName(tmpPath + QDir::separator() + "omeditcommands.log");
    if (mCommandsLogFile.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        mCommandsLogFileTextStream.setDevice(&mCommandsLogFile);
    }
    return true;
}

//! Stops the OpenModelica Compiler. Kill the process omc and also deletes the CORBA reference file.
//! @see startServer
void OMCProxy::stopServer()
{
    sendCommand("quit()");
    mCommandsLogFile.close();
}

//! Sends the user commands to OMC.
//! @param expression is used to send command as a string.
//! @see sendCommand()
void OMCProxy::sendCommand(const QString expression)
{
    if (!mHasInitialized)
        if(!startServer())      // if we are unable to start OMC. Exit the application.
        {
            mpParentMainWindow->mExitApplication = true;
            return;
        }
    // write command to the commands log.
    QTime commandTime;
    commandTime.start();
    writeCommandLog(expression, &commandTime);
    // Send command to server
    try
    {
        setExpression(expression);
        if (expression.startsWith("OMEdit_simulate_result:=simulate") or expression.startsWith("buildModel")
            or expression.startsWith("translateModelFMU") or expression.startsWith("importFMU"))
        {
            QFuture<void> future = QtConcurrent::run(this, &OMCProxy::sendCommand);
            while (future.isRunning())
                qApp->processEvents(QEventLoop::ExcludeUserInputEvents);
            future.waitForFinished();
            writeCommandResponseLog(&commandTime);
            logOMCMessages(expression);
        }
        else
        {
            mResult = QString::fromLocal8Bit(mOMC->sendExpression(getExpression().toLocal8Bit()));
            writeCommandResponseLog(&commandTime);
            logOMCMessages(expression);
        }
    }
    catch(CORBA::Exception&)
    {
        // if the command is quit() and we get exception just simply quit
        if (expression == "quit()")
            return;

        removeObjectRefFile();
        if (mDisplayErrors)
        {
            QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                                  QString("Communication with the ").append(Helper::applicationName).append(" server has been lost.")
                                  .append("\n\n").append(Helper::applicationName).append(" will close."), "OK");
            restartApplication();
        }
    }
}

//! Sends the user commands to OMC by using the Qt::concurrent feature.
//! @see sendCommand(const QString expression)
void OMCProxy::sendCommand()
{
    mResult = QString::fromLocal8Bit(mOMC->sendExpression(getExpression().toLocal8Bit()));
}

//! Sets the command result.
//! @param value the command result.
void OMCProxy::setResult(QString value)
{
    mResult = value;
}

//! Returns the result obtained from OMC.
//! @return QString the command result.
QString OMCProxy::getResult()
{
    return mResult.trimmed();
}

//! writes OMC messages in OMC Logger window.
void OMCProxy::logOMCMessages(QString expression)
{
    // move the cursor down before adding to the logger.
    QTextCursor textCursor = mpPlainTextEdit->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpPlainTextEdit->setTextCursor(textCursor);
    // add the expression to commands list
    mCommandsList.append(expression);
    // log expression
    QFont font("Times New Roman", 10, QFont::Bold, false);
    QTextCharFormat *pCharFormat = new QTextCharFormat;
    pCharFormat->setFont(font);
    mpPlainTextEdit->setCurrentCharFormat(*pCharFormat);
    mpPlainTextEdit->insertPlainText(expression + "\n");
    // log result
    font = QFont("Times New Roman", 10, QFont::Normal, false);
    pCharFormat->setFont(font);
    mpPlainTextEdit->setCurrentCharFormat(*pCharFormat);
    mpPlainTextEdit->insertPlainText(getResult() + "\n\n");
    // move the cursor
    textCursor.movePosition(QTextCursor::End);
    mpPlainTextEdit->setTextCursor(textCursor);
    // set the current command index.
    mCurrentCommandIndex = mCommandsList.count();
    mpExpressionTextBox->setText(tr(""));
}

//! Uses the OMC getPackages API to built a list of packages.
//! @return QStringList the list of packages.
QStringList OMCProxy::createPackagesList()
{
    QStringList packagesList;
    QStringList classesList = getPackages(tr(""));

    foreach (QString package, classesList)
    {
        // if package is Modelica skip it.
        if (package != tr("Modelica") and package != tr("ModelicaServices") and package != tr("ModelicaReference"))
            addPackage(&packagesList, package, tr(""));
    }
    return packagesList;
}

//! A helper function for OMCProxy::createPackagesList
//! @param list the list top append package.
//! @param package the package name
//! @param parentPackage the package parent name
void OMCProxy::addPackage(QStringList *list, QString package, QString parentPackage)
{
    if (!parentPackage.isEmpty())
        package = parentPackage + tr(".") + package;

    list->append(package);
    QStringList classesList = getPackages(package);

    foreach (QString packageStr, classesList)
        addPackage(list, packageStr, package);
}

//! Opens the OMC Logger dialog.
void OMCProxy::openOMCLogger()
{
    mpExpressionTextBox->setFocus(Qt::ActiveWindowFocusReason);
    this->mpOMCLogger->raise();
    this->mpOMCLogger->show();
}

//! Sends the command written in the OMC Logger textbox.
void OMCProxy::sendCustomExpression()
{
    if (mpExpressionTextBox->text().isEmpty())
        return;

    sendCommand(mpExpressionTextBox->text());
    mpExpressionTextBox->setText(QString());
}

//! Removes the CORBA IOR file. We only call this method when we are unable to connect to OMC.
//! In normal case OMCProxy::stopServer will delete that file.
void OMCProxy::removeObjectRefFile()
{
    QFile::remove(mObjectRefFile);
}

void OMCProxy::restartApplication()
{
    qApp->exit();
}

//! Returns the OMC error string.
//! @return QString the error string.
//! @deprecated Use printMessagesStringInternal()
QString OMCProxy::getErrorString()
{
    sendCommand("getErrorString()");
    return StringHandler::unparse(getResult());
}

//! Gets the errors by using the getMessagesStringInternal API.
//! Reads all the errors and add them to the Problems Tab.
//! @see MessageWidget::addGUIProblem
//! @see Problem
//! @return bool true if there are any errors otherwise false.
bool OMCProxy::printMessagesStringInternal()
{
    int errorsSize = getMessagesStringInternal();
    bool returnValue = errorsSize > 0 ? true : false;

    for (int i = 1; i <= errorsSize ; i++)
    {
        setCurrentError(i);
        ProblemItem *pProblemItem = new ProblemItem(mpParentMainWindow->mpMessageWidget->mpProblem);
        pProblemItem->setFileName(getErrorFileName());
        pProblemItem->setReadOnly(getErrorReadOnly());
        pProblemItem->setLineStart(getErrorLineStart());
        pProblemItem->setColumnStart(getErrorColumnStart());
        pProblemItem->setLineEnd(getErrorLineEnd());
        pProblemItem->setColumnEnd(getErrorColumnEnd());
        pProblemItem->setMessage(getErrorMessage());
        pProblemItem->setKind(getErrorKind());
        pProblemItem->setLevel(getErrorLevel());
        pProblemItem->setId(getErrorId());
        pProblemItem->setColumnsText();
        mpParentMainWindow->mpMessageWidget->addGUIProblem(pProblemItem);
    }
    return returnValue;
}

//! Retrieves the list of errors from OMC
//! @return int size of errors
int OMCProxy::getMessagesStringInternal()
{
    sendCommand("errors:=getMessagesStringInternal()");
    sendCommand("size(errors,1)");
    return getResult().toInt();
}

//! Sets the current error.
//! @param int the error index
void OMCProxy::setCurrentError(int errorIndex)
{
    sendCommand("currentError:=errors[" + QString::number(errorIndex) + "]");
}

//! Gets the error file name from current error.
//! @return QString the error file name
QString OMCProxy::getErrorFileName()
{
    sendCommand("currentError.info.filename");
    QString file = StringHandler::unparse(getResult());
    if (file.compare("<interactive>") == 0)
      return "";
    else
      return file;
}

//! Gets the error read only state from current error.
//! @return bool the error read only state
bool OMCProxy::getErrorReadOnly()
{
    sendCommand("currentError.info.readonly");
    return StringHandler::unparseBool(StringHandler::unparse(getResult()));
}

//! Gets the error line start index from current error.
//! @return int the error line start index
int OMCProxy::getErrorLineStart()
{
    sendCommand("currentError.info.lineStart");
    return getResult().toInt();
}

//! Gets the error column start index from current error.
//! @return int the error column start index
int OMCProxy::getErrorColumnStart()
{
    sendCommand("currentError.info.columnStart");
    return getResult().toInt();
}

//! Gets the error line end index from current error.
//! @return int the error line end index
int OMCProxy::getErrorLineEnd()
{
    sendCommand("currentError.info.lineEnd");
    return getResult().toInt();
}

//! Gets the error column end index from current error.
//! @return int the error column end index
int OMCProxy::getErrorColumnEnd()
{
    sendCommand("currentError.info.columnEnd");
    return getResult().toInt();
}

//! Gets the error message from current error.
//! @return QString the error message
QString OMCProxy::getErrorMessage()
{
    sendCommand("currentError.message");
    return StringHandler::unparse(getResult());
}

//! Gets the error kind from current error.
//! @return QString the error kind
QString OMCProxy::getErrorKind()
{
    sendCommand("currentError.kind");
    return getResult();
}

//! Gets the error level from current error.
//! @return QString the error level
QString OMCProxy::getErrorLevel()
{
    sendCommand("currentError.level");
    return getResult();
}

//! Gets the error id from current error.
//! @return QString the error id
int OMCProxy::getErrorId()
{
    sendCommand("currentError.id");
    return getResult().toInt();
}

//! Gets the OMC version. On Linux it also return the revision number as well.
//! @return QString the version
QString OMCProxy::getVersion()
{
    sendCommand("getVersion()");
    return StringHandler::unparse(getResult());
}

//! Sets the OMC annotation version
//! @return bool true if successful.
bool OMCProxy::setAnnotationVersion(int version)
{
    if (version == OMCProxy::ANNOTATION_VERSION2X)
    {
        mAnnotationVersion = OMCProxy::ANNOTATION_VERSION2X;
        setEnvironmentVar("OPENMODELICALIBRARY", QString(Helper::OpenModelicaHome).append("/lib/omc/omlibrary/msl221"));
        sendCommand("setAnnotationVersion(\"2.x\")");
    }
    else if (version == OMCProxy::ANNOTATION_VERSION3X)
    {
        mAnnotationVersion = OMCProxy::ANNOTATION_VERSION3X;
        setEnvironmentVar("OPENMODELICALIBRARY", QString(Helper::OpenModelicaHome).append("/lib/omc/omlibrary/msl31"));
        sendCommand("setAnnotationVersion(\"3.x\")");
    }

    if (getResult().toLower().contains("true"))
        return true;
    else
    {
        setEnvironmentVar("OPENMODELICALIBRARY", QString(Helper::OpenModelicaHome).append("/lib/omc/omlibrary/msl221"));
        mAnnotationVersion = OMCProxy::ANNOTATION_VERSION2X;
        return false;
    }
}

//! Gets the OMC annotation version
//! @return QString the annotation version
QString OMCProxy::getAnnotationVersion()
{
    sendCommand("getAnnotationVersion()");
    return getResult();
}

//! Sends OMC setEnvironmentVar command.
//! @param name the variable name
//! @param value the variable value
//! @return true on success
bool OMCProxy::setEnvironmentVar(QString name, QString value)
{
    sendCommand("setEnvironmentVar(\"" + name + "\", \"" + value + "\")");
    if (getResult().toLower().contains("ok"))
        return true;
    else
        return false;
}

//! Gets OMC getEnvironmentVar command.
//! @param name the variable name
//! @return QString the variable value.
QString OMCProxy::getEnvironmentVar(QString name)
{
    sendCommand("getEnvironmentVar(\"" + name + "\")");
    return getResult();
}

//! Loads the OpenModelica Standard Library.
//! Reads the omedit.ini file to get the libraries to load.
//! Deletes the Fluid library as is not supported fully by OpenModelica.
void OMCProxy::loadStandardLibrary()
{
    QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");

    settings.beginGroup("libraries");
    QStringList libraries = settings.childKeys();

    if (!settings.contains("Modelica")) {
        settings.setValue("Modelica","default");
        libraries.prepend("Modelica");
    }
    if (!settings.contains("ModelicaReference")) {
        settings.setValue("ModelicaReference","default");
        libraries.prepend("ModelicaReference");
    }

    foreach (QString lib, libraries) {
        QString version = settings.value(lib).toString();
        QString command = "loadModel(" + lib + ",{\"" + version + "\"})";
        sendCommand(command);
        printMessagesStringInternal();
    }

    sendCommand("getNamedAnnotation(Modelica,version)");
    QStringList versionLst = StringHandler::unparseStrings(getResult());
    QString versionStr = versionLst.empty() ? "" : versionLst.at(0);
    double version = versionStr.toDouble();

    if (version >= 3.0 && version < 4.0) {
        deleteClass("Modelica.Fluid");
    } else if (!versionLst.empty()) {
        if (version < 2) sendCommand("setAnnotationVersion(\"1.x\")");
        else if (version < 3) sendCommand("setAnnotationVersion(\"2.x\")");
            QMessageBox::warning(mpParentMainWindow, Helper::applicationName + " requires Modelica 3 annotations",
                             "Modelica Standard Library version " + versionStr + " is unsupported.", "OK");
    }
}

//! Gets the list of classes from OMC.
//! @param className is the name of the class whose sub classes are retrieved.
//! @return QStringList the list of classes
QStringList OMCProxy::getClassNames(QString className)
{
    sendCommand("getClassNames(" + className + ")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
}

//! Gets the information about the class.
//! @param modelName is the name of the class whose information is retrieved.
//! @return QStringList the information
QStringList OMCProxy::getClassInformation(QString modelName)
{
    sendCommand("getClassInformation(" + modelName + ")");
    QString result = getResult();
    QStringList list = StringHandler::unparseStrings(result);
    return list;
}

//! Gets the list of classes from OMC recursively.
//! @param className is the name of the class whose sub classes are retrieved.
//! @return QStringList the list of classes
QStringList OMCProxy::getClassNamesRecursive(QString className)
{
    sendCommand("getClassNamesRecursive(" + className + ")");
    QStringList list = getResult().split(" ", QString::SkipEmptyParts);
    return list;
}

//! Gets the list of packages from OMC.
//! @param packageName is the name of the package whose sub packages are retrieved.
//! @return QStringList the list of packages
QStringList OMCProxy::getPackages(QString packageName)
{
    sendCommand("getPackages(" + packageName + ")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
}

//! Checks whether the class is a package or not.
//! @param className is the name of the class which is checked.
//! @return bool true if the class is a pacakge otherwise false
bool OMCProxy::isPackage(QString className)
{
    sendCommand("isPackage(" + className + ")");
    if (getResult().contains("true"))
    {
        return true;
    }
    else
    {
        return false;
    }
}

//! Returns true if the given type is one of the predefined types in Modelica.
bool OMCProxy::isBuiltinType(QString typeName)
{
    return (typeName == "Real" ||
            typeName == "Integer" ||
            typeName == "String" ||
            typeName == "Boolean");
}

//! Checks the class type.
//! @param type the type to check.
//! @param className the class to check.
//! @return bool true if the class is a specified type
bool OMCProxy::isWhat(int type, QString className)
{
    switch (type)
    {
        case StringHandler::MODEL:
            sendCommand("isModel(" + className + ")");
            break;
        case StringHandler::CLASS:
            sendCommand("isClass(" + className + ")");
            break;
        case StringHandler::CONNECTOR:
            sendCommand("isConnector(" + className + ")");
            break;
        case StringHandler::RECORD:
            sendCommand("isRecord(" + className + ")");
            break;
        case StringHandler::BLOCK:
            sendCommand("isBlock(" + className + ")");
            break;
        case StringHandler::FUNCTION:
            sendCommand("isFunction(" + className + ")");
            break;
        case StringHandler::PACKAGE:
            sendCommand("isPackage(" + className + ")");
            break;
        default:
            return false;
    }
    return StringHandler::unparseBool(getResult());
}

//! Checks whether the class parameter is protected or not.
//! @param className is the name of the class.
//! @param paramter is the paramter to check.
//! @return bool true if the paramter is protected otherwise false
bool OMCProxy::isProtected(QString parameter, QString className)
{
    sendCommand("isProtected(" + parameter + "," + className + ")");
    return StringHandler::unparseBool(getResult());
}

//! Gets the class type.
//! @param modelName is the name of the class to check.
//! @return int the class type.
int OMCProxy::getClassRestriction(QString modelName)
{
    sendCommand("getClassRestriction(" + modelName + ")");

    if (getResult().toLower().contains("model"))
        return StringHandler::MODEL;
    else if (getResult().toLower().contains("class"))
        return StringHandler::CLASS;
    else if (getResult().toLower().contains("connector"))
        return StringHandler::CONNECTOR;
    else if (getResult().toLower().contains("record"))
        return StringHandler::RECORD;
    else if (getResult().toLower().contains("block"))
        return StringHandler::BLOCK;
    else if (getResult().toLower().contains("function"))
        return StringHandler::FUNCTION;
    else if (getResult().toLower().contains("package"))
        return StringHandler::PACKAGE;
    else if (getResult().toLower().contains("type"))
        return StringHandler::TYPE;
    else
        return StringHandler::MODEL;
}

//! Gets the list of paramters.
//! Create an object of IconParameters for each parameter and puts it into the list.
//! @param modelName is the name of the model. Fully qualified name.
//! @param className is the name of the class.
//! @param name is the name component.
//! @return QList<IconParameters*> the list of parameters
QList<IconParameters*> OMCProxy::getParameters(QString modelName, QString className, QString name)
{
    QList<IconParameters*> iconParametersList;
    // get the list of component modifires
    QStringList modifiersList = getComponentModifierNames(modelName, name);
    for (int i = 0 ; i < modifiersList.size() ; i++)
    {
        QString value = getComponentModifierValue(modelName, QString(name).append(".").append(modifiersList.at(i)).trimmed());
        IconParameters *iconParameter = new IconParameters(QString(modifiersList.at(i)).trimmed(), value);
        iconParametersList.append(iconParameter);
    }
    // get the list of parameters
    QStringList list = getParameterNames(className);
    for (int i = 0 ; i < list.size() ; i++)
    {
        if (!getIconParameter(iconParametersList, QString(list.at(i)).trimmed()))
        {
            QString value = getParameterValue(className, QString(list.at(i)).trimmed());
            IconParameters *iconParameter = new IconParameters(QString(list.at(i)).trimmed(), value);
            iconParametersList.append(iconParameter);
        }
    }
    return iconParametersList;
}

//! Gets the parameters from a list of paramters.
//! @param list is the parameters list to search in.
//! @param value is the value to search for.
//! @return IconParameters* the searched parameter
IconParameters* OMCProxy::getIconParameter(QList<IconParameters *> list, QString value)
{
    IconParameters *pIconParameter = 0;
    foreach (IconParameters *iconParammeter, list)
    {
        if (iconParammeter->getName().compare(value) == 0)
        {
            pIconParameter = iconParammeter;
            break;
        }
    }
    return pIconParameter;
}

//! Gets the parameter names.
//! @param className is the name of the class whose parameter names are retrieved.
//! @return QStringList the list of paramter names.
QStringList OMCProxy::getParameterNames(QString className)
{
    QString result;
    QString expression = "getParameterNames(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        result = StringHandler::removeFirstLastCurlBrackets(getResult());
        addExpressionInCommandMap(expression, result);
    }
    else
    {
        result = expressionResult;
    }

    if (result.isEmpty())
        return QStringList();
    else
    {
        QStringList list = result.split(",", QString::SkipEmptyParts);
        return list;
    }
}

//! Gets the parameter value.
//! @param className is the name of the class whose parameter value is retrieved.
//! @return QString the paramter value.
QString OMCProxy::getParameterValue(QString className, QString parameter)
{
    sendCommand("getParameterValue(" + className + "," + parameter + ")");
    return getResult();
}

//! Sets the parameter value.
//! @param className is the name of the class whose parameter value is set.
//! @param parameter is the name of the parameter whose value is set.
//! @param value is the value to set.
//! @return bool true on success
bool OMCProxy::setParameterValue(QString className, QString parameter, QString value)
{
    sendCommand("setParameterValue(" + className + "," + parameter + "," + value + ")");
    if (getResult().contains("Ok"))
        return true;
    else
        return false;
}

//! Gets the list of component modifier names.
//! @param modelName is the name of the class whose modifier names are retrieved.
//! @param name is the name of the component.
//! @return QStringList the list of modifier names
QStringList OMCProxy::getComponentModifierNames(QString modelName, QString name)
{
    sendCommand("getComponentModifierNames(" + modelName + "," + name + ")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
}

//! Gets the list of component modifier value.
//! @param modelName is the name of the class whose modifier value is retrieved.
//! @param name is the name of the component.
//! @return QString the value of modifier.
QString OMCProxy::getComponentModifierValue(QString modelName, QString name)
{
    sendCommand("getComponentModifierValue(" + modelName + "," + name + ")");
    return StringHandler::getModifierValue(getResult());
}

//! Gets the list of component modifier value.
//! @param modelName is the name of the class whose modifier value is set.
//! @param name is the name of the modifier whose value is set.
//! @param value is the value to set.
//! @return bool true on success.
bool OMCProxy::setComponentModifierValue(QString modelName, QString name, QString value)
{
    sendCommand("setComponentModifierValue(" + modelName + "," + name + ", Code(" + value + "))");
    if (getResult().toLower().contains("ok"))
        return true;
    else
    {
        printMessagesStringInternal();
        return false;
    }
}

//! Gets the Icon Annotation of a specified class from OMC.
//! @param className is the name of the class.
//! @return QString the icon annotation.
QString OMCProxy::getIconAnnotation(QString className)
{
    QString expression = "getIconAnnotation(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return getResult();
    }
    else
    {
        return expressionResult;
    }
}

//! Gets the Diagram Annotation of a specified class from OMC.
//! @param className is the name of the class.
//! @return QString the diagram annotation.
QString OMCProxy::getDiagramAnnotation(QString className)
{
    QString expression = "getDiagramAnnotation(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return getResult();
    }
    else
    {
        return expressionResult;
    }
}

//! Gets the number of connection from a model.
//! @param className is the name of the model.
//! @return int the number of connections.
int OMCProxy::getConnectionCount(QString className)
{
    QString result;
    QString expression = "getConnectionCount(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        result = getResult();
    }
    else
    {
        result = expressionResult;
    }

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

//! Returns the connection at a specific index from a model.
//! @param className is the name of the model.
//! @param num is the index of connection.
//! @return QString the connection
QString OMCProxy::getNthConnection(QString className, int num)
{
    QString expression = "getNthConnection(" + className + ", " + QString::number(num) + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return getResult();
    }
    else
    {
        return expressionResult;
    }
}

//! Returns the connection annotation at a specific index from a model.
//! @param className is the name of the model.
//! @param num is the index of connection annotation.
//! @return QString the connection annotation
QString OMCProxy::getNthConnectionAnnotation(QString className, int num)
{
    QString expression = "getNthConnectionAnnotation(" + className + ", " + QString::number(num) + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return getResult();
    }
    else
    {
        return expressionResult;
    }
}

//! Returns the inheritance count of a model.
//! @param className is the name of the model.
//! @return int the inheritance count
int OMCProxy::getInheritanceCount(QString className)
{
    QString result;
    QString expression = "getInheritanceCount(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        result = getResult();
    }
    else
    {
        result = expressionResult;
    }

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

//! Returns the inherited class at a specific index from a model.
//! @param className is the name of the model.
//! @param num is the index of inherited class.
//! @return QString the inherited class.
QString OMCProxy::getNthInheritedClass(QString className, int num)
{
    QString expression = "getNthInheritedClass(" + className + ", " + QString::number(num) + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return getResult();
    }
    else
    {
        return expressionResult;
    }
}

//! Returns the components of a model with their attributes.
//! Creates an object of ComponentsProperties for each component.
//! @param className is the name of the model.
//! @return QList<ComponentsProperties*> the list of components
QList<ComponentsProperties*> OMCProxy::getComponents(QString className)
{
    QString result;
    QString expression = "getComponents(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        result = getResult();
    }
    else
    {
        result = expressionResult;
    }

    QList<ComponentsProperties*> components;
    QStringList list = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(result));

    for (int i = 0 ; i < list.size() ; i++)
    {
        if (list.at(i) == "Error")
            continue;
        components.append(new ComponentsProperties(StringHandler::removeFirstLastCurlBrackets(list.at(i))));
    }

    return components;
}

//! Returns the component annotations of a model.
//! @param className is the name of the model.
//! @return QStringList the list of component annotations.
QStringList OMCProxy::getComponentAnnotations(QString className)
{
    QString expression = "getComponentAnnotations(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        addExpressionInCommandMap(expression, getResult());
        return StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(getResult()));
    }
    else
    {
        return StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(expressionResult));
    }
}

//! Returns the documentation annotation of a model.
//! The documenation is not standardized, so for any not standard html documentation add <pre></pre> tags.
//! @param className is the name of the model.
//! @return QString the documentation annotation.
QString OMCProxy::getDocumentationAnnotation(QString className)
{
    QString expression = "getDocumentationAnnotation(" + className + ")";
    // check the expression in CommandsMap
    QString expressionResult = getCommandFromMap(expression);
    if (expressionResult.isEmpty())
    {
        sendCommand(expression);
        expressionResult = getResult();
        QStringList lst = StringHandler::unparseStrings(expressionResult);
        QString doc;
        foreach (QString expressionResult, lst) {
            expressionResult = expressionResult.replace("Modelica://", "Modelica:/");
            int i,j;
            /*
           * Documentation may have the form
           * text <HTML>...</html> text <html>...</HTML> [...]
           * Nothing is standardized, but we will treat non-html tags as <pre>-formatted text
           */
            while (1) {
                expressionResult = expressionResult.trimmed();
                i = expressionResult.indexOf("<html>", 0, Qt::CaseInsensitive);
                if (i == -1) break;
                if (i != 0) {
                    doc += "<pre>" + expressionResult.left(i).replace("<","&lt;").replace(">","&gt;") + "</pre>";
                    expressionResult = expressionResult.remove(i);
                }
                j = expressionResult.indexOf("</html>", 0, Qt::CaseInsensitive);
                if (j == -1) break;
                doc += expressionResult.leftRef(j+7);
                expressionResult = expressionResult.mid(j+7,-1);
            }
            if (expressionResult.length()) {
                doc += "<pre>" + expressionResult.replace("<","&lt;").replace(">","&gt;") + "</pre>";
            }
        }
        addExpressionInCommandMap(expression, doc);
        return doc;
    }
    return expressionResult;
}

//! Change the current working directory of OMC. Also retunrs the current working directory.
//! @param directory the new working directory location.
//! @return QString the current working directory
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

//! Loads a file in OMC
//! @param fileName the file to load.
//! @return bool true on success
bool OMCProxy::loadFile(QString fileName)
{
    fileName = fileName.replace('\\', '/');
    sendCommand("loadFile(\"" + fileName + "\")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
    {
        printMessagesStringInternal();
        return false;
    }
}

//! Loads a string in OMC
//! @param value the string to load.
//! @return bool true on success
bool OMCProxy::loadString(QString value)
{
    sendCommand("loadString(\"" + value.replace("\"", "\\\"") + "\")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Parse the file. Doesn't load it into OMC.
//! @param fileName the file to parse.
//! @return bool true on success
bool OMCProxy::parseFile(QString fileName)
{
    fileName = fileName.replace('\\', '/');
    sendCommand("parseFile(\"" + fileName + "\")");
    if (getResult() == "{}")
    {
        printMessagesStringInternal();
        return false;
    }
    else
        return true;
}

//! Parse the string. Doesn't load it into OMC.
//! @param value the string to parse.
//! @return QStringList the list of models inside the string.
QStringList OMCProxy::parseString(QString value)
{
    sendCommand("parseString(\"" + value.replace("\"", "\\\"") + "\")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    printMessagesStringInternal();
    return list;
}

//! Creates a new class in OMC.
//! @param type the class type.
//! @param className the class name.
//! @return bool true on successs.
bool OMCProxy::createClass(QString type, QString className)
{
    sendCommand(type + " " + className + " end " + className + ";");
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Creates a new sub class in OMC.
//! @param type the class type.
//! @param className the class name.
//! @param parentClassName the parent class name.
//! @return bool true on successs.
bool OMCProxy::createSubClass(QString type, QString className, QString parentClassName)
{
    sendCommand("within " + parentClassName + "; " + type + " " + className + " end " + className + ";");
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Updates the sub class in OMC.
//! @param parentClassName the parent class name.
//! @param modelText
//! @return bool true on successs.
bool OMCProxy::updateSubClass(QString parentClassName, QString modelText)
{
    sendCommand("within " + parentClassName + "; " + modelText);
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Creates a new class in OMC.
//! @param modelName the name for a new class.
//! @return bool true on successs.
bool OMCProxy::createModel(QString modelName)
{
    sendCommand("createModel(" + modelName + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Creates a new class in OMC.
//! @param modelName the name for a new class.
//! @param parentModelName the parent model name.
//! @return bool true on successs.
bool OMCProxy::newModel(QString modelName, QString parentModelName)
{
    sendCommand("newModel(" + modelName + ", " + parentModelName + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Checks whether the class already exists in OMC or not.
//! @param className the name for the class to check.
//! @return bool true on successs.
bool OMCProxy::existClass(QString className)
{
    sendCommand("existClass(" + className + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Renames a class.
//! @param oldName.
//! @param newName.
//! @return bool true on successs.
bool OMCProxy::renameClass(QString oldName, QString newName)
{
    sendCommand("renameClass(" + oldName + ", " + newName + ")");
    if (StringHandler::unparseBool(getResult()))
        return false;
    else
        return true;
}

//! Deletes a class.
//! @param className.
//! @return bool true on successs.
bool OMCProxy::deleteClass(QString className)
{
    sendCommand("deleteClass(" + className + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Returns the file name of a model.
//! @param modelName
//! @return QString the file name.
QString OMCProxy::getSourceFile(QString modelName)
{
    sendCommand("getSourceFile(" + modelName + ")");
    QString file = StringHandler::unparse(getResult());
    if (file.compare("<interactive>") == 0)
      return "";
    else
      return file;
}

//! Sets a file name of a model.
//! @param modelName
//! @param path the full location
//! @return bool true on successs.
bool OMCProxy::setSourceFile(QString modelName, QString path)
{
    sendCommand("setSourceFile(" + modelName + ", \"" + path + "\")");
    return StringHandler::unparseBool(getResult());
}

//! Saves a model.
//! @param modelName
//! @return bool true on successs.
bool OMCProxy::save(QString modelName)
{
    sendCommand("save(" + modelName + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

bool OMCProxy::saveModifiedModel(QString modelText)
{
    sendCommand(modelText);
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Retruns the modelica text of a class.
//! @param className
//! @return QString the modelica text.
QString OMCProxy::list(QString className)
{
    sendCommand("list(" + className + ")");
    return StringHandler::unparse(getResult());
}

//! Adds annotation to the class.
//! @param className
//! @param annotation
//! @return bool true in success the modelica text.
bool OMCProxy::addClassAnnotation(QString className, QString annotation)
{
    sendCommand("addClassAnnotation(" + className + ", " + annotation + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Retunrs the default componet name of a class.
//! @param className.
//! @return QString the default component name.
QString OMCProxy::getDefaultComponentName(QString className)
{
    sendCommand("getDefaultComponentName(" + className + ")");
    if (getResult().compare("{}") == 0)
        return QString();

    return StringHandler::unparse(getResult());
}

//! Retunrs the default component prefixes of a class.
//! @param className.
//! @return QString the default component prefixes.
QString OMCProxy::getDefaultComponentPrefixes(QString className)
{
    sendCommand("getDefaultComponentPrefixes(" + className + ")");
    if (getResult().compare("{}") == 0)
        return QString();

    return StringHandler::unparse(getResult());
}

//! Adds a component to the model.
//! @param name the component name
//! @param className the component fully qualified name.
//! @param modelName
//! @return bool true on success.
bool OMCProxy::addComponent(QString name, QString className, QString modelName)
{
    sendCommand("addComponent(" + name + ", " + className + "," + modelName + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Deletes a component from the model.
//! @param name the component name
//! @param modelName
//! @return bool true on success.
bool OMCProxy::deleteComponent(QString name, QString modelName)
{
    sendCommand("deleteComponent(" + name + "," + modelName + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Renames a component
//! @param modelName
//! @param oldName
//! @param newName
//! @return bool true on success.
//! @see OMCProxy::renameComponentInClass(QString modelName, QString oldName, QString newName)
bool OMCProxy::renameComponent(QString modelName, QString oldName, QString newName)
{
    sendCommand("renameComponent(" + modelName + "," + oldName + "," + newName + ")");
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Updates the component annotations.
//! @param name the component name
//! @param className the component fully qualified name.
//! @param modelName
//! @param annotation
//! @return bool true on success.
bool OMCProxy::updateComponent(QString name, QString className, QString modelName, QString annotation)
{
    sendCommand("updateComponent(" + name + "," + className + "," + modelName + "," + annotation + ")");
    if (StringHandler::unparseBool(getResult()))
        return true;
    else
        return false;
}

//! Renames a component in a class.
//! @param modelName
//! @param oldName
//! @param newName
//! @return bool true on success.
//! @see OMCProxy::renameComponent(QString modelName, QString oldName, QString newName)
bool OMCProxy::renameComponentInClass(QString modelName, QString oldName, QString newName)
{
    sendCommand("renameComponentInClass(" + modelName + "," + oldName + "," + newName + ")");
    if (getResult().toLower().contains("error"))
        return false;
    else
        return true;
}

//! Updates the connection annotation
//! @param from the connection start component name
//! @param to the connection end component name
//! @param modelName
//! @param annotation
//! @return bool true on success.
bool OMCProxy::updateConnection(QString from, QString to, QString modelName, QString annotation)
{
    sendCommand("updateConnection(" + from + "," + to + "," + modelName + "," + annotation + ")");
    if (getResult().contains("Ok"))
        return true;
    else
        return false;
}

//! Sets the component properties
//! @param modelName
//! @param componentName
//! @param isFinal
//! @param isFlow
//! @param isProtected
//! @param isReplaceAble
//! @param variability
//! @param isInner
//! @param isOuter
//! @param causality
//! @return bool true on success.
bool OMCProxy::setComponentProperties(QString modelName, QString componentName, QString isFinal, QString isFlow, QString isProtected,
                                      QString isReplaceAble, QString variability, QString isInner, QString isOuter, QString causality)
{
    sendCommand("setComponentProperties(" + modelName + "," + componentName + ",{" + isFinal + "," + isFlow + "," + isProtected + "," + isReplaceAble + "}, {\"" + variability + "\"}, {" + isInner +
                "," + isOuter + "}, {\"" + causality + "\"})");

    if (getResult().toLower().contains("error"))
    {
        printMessagesStringInternal();
        return false;
    }
    else
        return true;
}

//! Sets the component comment
//! @param modelName
//! @param componentName
//! @param comment
//! @return bool true on success.
bool OMCProxy::setComponentComment(QString modelName, QString componentName, QString comment)
{
    sendCommand("setComponentComment(" + modelName + "," + componentName + ",\"" + comment + "\")");
    if (getResult().toLower().contains("error"))
    {
        printMessagesStringInternal();
        return false;
    }
    else
        return true;
}

//! Adds a connection
//! @param from the connection start component name.
//! @param to the connection end component name.
//! @param className
//! @return bool true on success.
bool OMCProxy::addConnection(QString from, QString to, QString className)
{
    sendCommand("addConnection(" + from + "," + to + "," + className + ")");
    if (getResult().contains("Ok"))
        return true;
    else
        return false;
}

//! Deletes a connection
//! @param from the connection start component name.
//! @param to the connection end component name.
//! @param className
//! @return bool true on success.
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

//! Check if Instantiating the model is successful or not.
//! @param modelName
//! @return bool true on success.
bool OMCProxy::instantiateModelSucceeds(QString modelName)
{
    sendCommand("instantiateModel(" + modelName + ")");
    if (getResult().size() < 3)
    {
        printMessagesStringInternal();
        return false;
    }
    else
        return true;
}

//! Simulate the model. Creates an execuatble and runs it.
//! @param modelName
//! @param simualtionParameters
//! @return bool true on success.
//! @deprecated OMEdit only use OMCProxy::buildModel(QString modelName, QString simualtionParameters)
bool OMCProxy::simulate(QString modelName, QString simualtionParameters)
{
    sendCommand("OMEdit_simulate_result:=simulate(" + modelName + "," + simualtionParameters + ")");
    sendCommand("OMEdit_simulate_result.resultFile");
    if (StringHandler::unparse(getResult()).isEmpty())
        return false;
    else
        return true;
}

//! Builds the model. Creates an executable only doesn't run it.
//! @param modelName
//! @param simualtionParameters
//! @return bool true on success.
bool OMCProxy::buildModel(QString modelName, QString simualtionParameters)
{
    sendCommand("buildModel(" + modelName + "," + simualtionParameters + ")");
    bool res = getResult() != "{\"\",\"\"}";
    printMessagesStringInternal();
    return res;
}

//! Reads the simulation result variables from the result file.
//! @param fileName the result file name
//! @return QList<QString> the list of variables.
QList<QString> OMCProxy::readSimulationResultVars(QString fileName)
{
    sendCommand("readSimulationResultVars(\"" + fileName + "\")");

    QList<QString> variablesList = StringHandler::getSimulationResultVars(getResult());
    qSort(variablesList.begin(), variablesList.end());
    return variablesList;
}

//! Plot the variables
//! @param plotVariables
//! @param fileName the result file name
//! @return bool true on success.
//! @deprecated OMEdit uses the OMPlot for plotting.
bool OMCProxy::plot(QString plotVariables, QString fileName)
{
    sendCommand("plot({" + plotVariables + "}, \"" + fileName + "\")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

//! PlotParametric the variables
//! @param plotVariables
//! @param modelName
//! @return bool true on success.
//! @deprecated OMEdit uses the OMPlot for plotting.
bool OMCProxy::plotParametric(QString modelName, QString plotVariables)
{
    sendCommand("plotParametric(" + modelName + "," + plotVariables + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

bool OMCProxy::visualize(QString modelName)
{
    sendCommand("visualize(" + modelName + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

//! Checks the model. Checks model balance in terms of number of variables and equations.
//! @param modelName
//! @return QString the model check result
QString OMCProxy::checkModel(QString modelName)
{
    sendCommand("checkModel(" + modelName + ")");
    return getResult();
}

//! Instantiates the model.
//! @param modelName
//! @return QString the instantiated model
QString OMCProxy::instantiateModel(QString modelName)
{
    sendCommand("instantiateModel(" + modelName + ")");
    QString result = StringHandler::unparse(getResult());
    printMessagesStringInternal();
    return result;
}

//! Returns the simulation options stored in the model.
//! @param modelName
//! @return QString the simulation options
QString OMCProxy::getSimulationOptions(QString modelName)
{
    sendCommand("getSimulationOptions(" + modelName + ")");
    return getResult();
}

//! Creates the FMU of the model.
//! @param modelName
//! @return QString the created FMU location
bool OMCProxy::translateModelFMU(QString modelName)
{
    sendCommand("translateModelFMU(" + modelName + ")");
    if (StringHandler::unparse(getResult()).compare("SimCode: The model " + modelName + " has been translated to FMU") == 0)
        return true;
    else
    {
        printMessagesStringInternal();
        return false;
    }
}

//! Imports the FMU
//! @param fmuName the FMU location
//! @param outputDirectory the output location
//! @return bool true on success
bool OMCProxy::importFMU(QString fmuName, QString outputDirectory)
{
    if (outputDirectory.isEmpty())
        sendCommand("importFMU(\"" + fmuName + "\")");
    else
    {
        sendCommand("importFMU(\"" + fmuName + "\", \"" + outputDirectory.replace("\\", "/") + "\")");
    }
    return StringHandler::unparseBool(getResult());
}

//! @class CustomExpressionBox
//! @brief A text box for executing OMC commands.

//! Constructor
//! @param pParent is the pointer to OMCProxy.
CustomExpressionBox::CustomExpressionBox(OMCProxy *pParent)
{
    mpParentOMCProxy = pParent;
}

//! Reimplementation of keyPressEvent.
void CustomExpressionBox::keyPressEvent(QKeyEvent *event)
{
    switch (event->key())
    {
        case Qt::Key_Up:
            mpParentOMCProxy->getPreviousCommand();
            break;
        case Qt::Key_Down:
            mpParentOMCProxy->getNextCommand();
            break;
        default:
            QLineEdit::keyPressEvent(event);
    }
}
