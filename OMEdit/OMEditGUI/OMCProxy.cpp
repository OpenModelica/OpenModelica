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
 *
 */

//! @file   OMCProxy.cpp
//! @author Sonia Tariq <sonta273@student.liu.se>
//! @date   2010-06-25

//! @brief Contains functions used for communication with Open Modelica Compiler.

#include <stdexcept>

#include "OMCProxy.h"
#include "OMCThread.h"
#include "StringHandler.h"
#include "Helper.h"
#include <omniORB4/CORBA.h>

//! @class OMCProxy
//! @brief The OMCProxy is a singleton class. It contains the reference of the CORBA object used to communicate with the Open Modelica Compiler.

//! Constructor
//! @param mOMC is the CORBA object.
//! @param mHasInitialized is the boolean variable used for checking server intialization.
//! @param mIsStandardLibraryLoaded is the boolean variable used for checking OM Standard Library intialization.
//! @param mResult contains the result obtained from OMC.
OMCProxy::OMCProxy(MainWindow *pParent)
    : mOMC(0), mHasInitialized(false), mIsStandardLibraryLoaded(false),
      mName(Helper::omcServerName) ,mResult("")
{
    this->mpParentMainWindow = pParent;
    this->mpOMCLogger = new QDialog();
    this->mpOMCLogger->setWindowFlags(Qt::WindowTitleHint);
    this->mpOMCLogger->setMaximumSize(640, 480);
    this->mpOMCLogger->setMinimumSize(640, 480);
    this->mpOMCLogger->setWindowIcon(QIcon("../OMEditGUI/Resources/icons/console.png"));
    this->mpOMCLogger->setWindowTitle(QString(Helper::applicationName).append(" - OMC Messages Log"));
    // Set the QTextEdit Box
    this->mpTextEdit = new QTextEdit();
    this->mpTextEdit->setReadOnly(true);
    // Set the Layout
    QHBoxLayout *layout = new QHBoxLayout(this->mpOMCLogger);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(this->mpTextEdit);
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

//! Starts the Open Modelica Compiler.
bool OMCProxy::startServer()
{
    try
    {
        QString msg;
        QString omHome (getenv("OPENMODELICAHOME"));
        if (omHome.isEmpty())
            throw std::runtime_error("Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.");

        QDir dir;

        #ifdef WIN32
            if( dir.exists( omHome + "\\bin\\omc.exe" ) )
                    omHome += "\\bin\\";
            else if( dir.exists( omHome + "\\omc.exe" ) )
                    omHome += "";
            else
            {
                msg = "Unable to find " + Helper::applicationName + " server, searched in:\n" +
                        omHome + "\\bin\\\n" +
                        omHome + "\n" +
                        dir.absolutePath();

                throw std::runtime_error(msg.toStdString().c_str());
            }
        #else /* unix */
            if( dir.exists( omHome + "/bin/omc" ) )
                    omHome += "/bin/";
            else if( dir.exists( omHome + "/omc" ) )
                    omHome += "";
            else
            {
                msg = "Unable to find " + Helper::applicationName + " server, searched in:\n" +
                  omHome + "/bin/\n" +
                  omHome + "\n" +
                  dir.absolutePath();

                throw std::runtime_error(msg.toStdString().c_str());
            }
        #endif

        QString omcPath;

        #ifdef WIN32
                omcPath = omHome + "omc.exe";
        #else
                omcPath = omHome + "omc";
        #endif

        // Check the IOR file created by omc.exe
        QFile objectRefFile;
        QString fileIdentifier = qApp->sessionId().append(QTime::currentTime().toString().remove(":"));

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
        omcProcess->start( omcPath, parameters );

        // wait for the server to start.
        int ticks = 0;
        while (!objectRefFile.exists())
        {
            OMCThread::sleep(1);
            ticks++;
            if (ticks > 4)
            {
                msg = "Unable to find " + Helper::applicationName + " server, No OMC object reference file created.";
                throw std::runtime_error(msg.toStdString().c_str());
            }
        }
        // ORB initialization.
        int argc = 4;
        static const char *argv[] = { "OMCProxy", "-NoResolve", "-IIOPAddr", "inet:127.0.0.1:0", "-ORBIIOPBlocking"};
        CORBA::ORB_var orb = CORBA::ORB_init(argc, (char **)argv);

        objectRefFile.open(QIODevice::ReadOnly);

        char buf[1024];
        objectRefFile.readLine( buf, sizeof(buf) );
        QString uri( (const char*)buf );

        CORBA::Object_var obj = orb->string_to_object(uri.trimmed().toLatin1());

        mOMC = OmcCommunication::_narrow(obj);
        mHasInitialized = true;
    }
    catch(std::exception &e)
    {
        QString msg = e.what();
        QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                              msg.append("\n\n").append(Helper::applicationName).append(" will close."), "OK");
        mHasInitialized = false;
        return false;
    }
    catch (CORBA::Exception&)
    {
        QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                              QString("Unable to communicate with ").append(Helper::applicationName).append(" server.")
                              .append("\n\n").append(Helper::applicationName).append(" will close."), "OK");
        mHasInitialized = false;
        return false;
    }
   return true;
}

//! Stops the Open Modelica Compiler. Kill the process omc and also deletes the CORBA reference file.
//! @see startServer
void OMCProxy::stopServer()
{
    sendCommand("quit()");
}

//! Sends the user commands to OMC in a thread.
//! @param expression is used to send command as a string.
//! @see evalCommand(QString expression)
//! @see OMCThread
void OMCProxy::sendCommand(QString expression)
{
    if (!mHasInitialized)
        if(!startServer())      // if we are unable to start OMC. Exit the application.
        {
            mpParentMainWindow->mExitApplication = true;
            return;
        }

    // Send command to server
    try
    {
        mResult = mOMC->sendExpression(expression.toLatin1());
        logOMCMessages(expression);
    }
    catch(CORBA::Exception& ex)
    {
        // if the command is quit() and we get exception just simply quit
        if (expression == "quit()")
            return;
        QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                              QString("Communication with ").append(Helper::applicationName).append(" server has lost.")
                              .append("\n\n").append(Helper::applicationName).append(" will restart."), "OK");
        removeObjectRefFile();
        restartApplication();
    }
}

void OMCProxy::setResult(QString value)
{
    mResult = value;
}

//! Returns the result obtained from OMC.
QString OMCProxy::getResult()
{
    return mResult.trimmed();
}

void OMCProxy::logOMCMessages(QString expression)
{
    mpTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Bold, false));
    mpTextEdit->append(">>  " + expression);

    mpTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Normal, false));
    mpTextEdit->append(">>  " + getResult());
    mpTextEdit->append("");
}

QStringList OMCProxy::createPackagesList()
{
    QStringList packagesList;
    QStringList classesList = getPackages(tr(""));

    foreach (QString package, classesList)
    {
        // if package is Modelica skip it.
        if (package != tr("Modelica"))
            addPackage(&packagesList, package, tr(""));
    }
    return packagesList;
}

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
    this->mpOMCLogger->show();
}

void OMCProxy::catchException()
{
    QMessageBox::critical(mpParentMainWindow, Helper::applicationName + " - Error",
                          QString("Communication with ").append(Helper::applicationName).append(" server has lost.")
                          .append("\n\n").append(Helper::applicationName).append(" will restart."), "OK");
    removeObjectRefFile();
    restartApplication();
}

void OMCProxy::removeObjectRefFile()
{
    QFile::remove(mObjectRefFile);
}

void OMCProxy::restartApplication()
{
    //QProcess *applicationProcess = new QProcess();
    //applicationProcess->start(qApp->applicationFilePath());
    qApp->exit();
}

QString OMCProxy::getErrorString()
{
    sendCommand("getErrorString()");
    if (getResult().size() > 3)
        return getResult();
    else
    {
        setResult(tr(""));
        return getResult();
    }
}

QString OMCProxy::getVersion()
{
    sendCommand("getVersion()");
    return getResult();
}

//! Loads the Open Modelica Standard Library.
void OMCProxy::loadStandardLibrary()
{
    sendCommand("loadModel(Modelica)");
    if (getResult().contains("true"))
    {
        mIsStandardLibraryLoaded = true;
    }
}

//! Checks whether the Open Modelica Standard Library is loaded or not.
bool OMCProxy::isStandardLibraryLoaded()
{
    return mIsStandardLibraryLoaded;
}

//! Gets the list of classes from OMC.
//! @param className is the name of the class whose sub classes are retrieved.
QStringList OMCProxy::getClassNames(QString className)
{
    sendCommand("getClassNames(" + className + ")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
}

//! Gets the list of packages from OMC.
//! @param packageName is the name of the package whose sub packages are retrieved.
QStringList OMCProxy::getPackages(QString packageName)
{
    sendCommand("getPackages(" + packageName + ")");
    QString result = StringHandler::removeFirstLastCurlBrackets(getResult());
    QStringList list = result.split(",", QString::SkipEmptyParts);
    return list;
}

//! Checks whether the class is a package or not.
//! @param className is the name of the class which is checked.
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

bool OMCProxy::isWhat(int type, QString className)
{
    if (type == StringHandler::MODEL)
        sendCommand("isModel(" + className + ")");
    else if (type == StringHandler::PACKAGE)
        sendCommand("isPackage(" + className + ")");
    else if (type == StringHandler::CONNECTOR)
        sendCommand("isConnector(" + className + ")");

    if (getResult().contains("true"))
        return true;
    else
        return false;
}

//! Gets the Icon Annotation of a specified class from OMC.
//! @param className is the name of the class.
QString OMCProxy::getIconAnnotation(QString className)
{
    sendCommand("getIconAnnotation(" + className + ")");
    return getResult();
}

QString OMCProxy::getDiagramAnnotation(QString className)
{
    sendCommand("getDiagramAnnotation(" + className + ")");
    return getResult();
}

int OMCProxy::getInheritanceCount(QString className)
{
    sendCommand("getInheritanceCount(" + className + ")");
    if (!getResult().isEmpty())
    {
        bool ok;
        int result = getResult().toInt(&ok);
        if (ok)
            return result;
        else
            return 0;
    }
    else
        return 0;
}

QString OMCProxy::getNthInheritedClass(QString className, int num)
{
    QString number;
    sendCommand("getNthInheritedClass(" + className + ", " + number.setNum(num) + ")");
    return getResult();
}

QList<ComponentsProperties*> OMCProxy::getComponents(QString className)
{
    sendCommand("getComponents(" + className + ")");

    QList<ComponentsProperties*> components;
    QStringList list = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(getResult()));

    for (int i = 0 ; i < list.size() ; i++)
    {
        components.append(new ComponentsProperties(StringHandler::removeFirstLastCurlBrackets(list.at(i))));
    }

    return components;
}

QStringList OMCProxy::getComponentAnnotations(QString className)
{
    sendCommand("getComponentAnnotations(" + className + ")");
    return StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(getResult()));
}

QString OMCProxy::changeDirectory(QString directory)
{
    sendCommand("cd(\"" + directory + "\")");
    return getResult();
}

QString OMCProxy::loadFile(QString fileName)
{
    sendCommand("loadFile(\"" + fileName + "\")");
    return getResult();
}

bool OMCProxy::createClass(QString type, QString className)
{
    sendCommand(type + " " + className + " end " + className + ";");
    // check if there is any error.
    if (!getErrorString().isEmpty())
        return true;
        return false;
}

bool OMCProxy::createSubClass(QString type, QString className, QString parentClassName)
{
    sendCommand("within " + parentClassName + "; " + type + " " + className + " end " + className + ";");
    // check if there is any error.
    if (!getErrorString().isEmpty())
        return true;
    return false;
}

bool OMCProxy::createModel(QString modelName)
{
    sendCommand("createModel(" + modelName + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

bool OMCProxy::newModel(QString modelName, QString parentModelName)
{
    sendCommand("newModel(" + modelName + ", " + parentModelName + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

bool OMCProxy::existClass(QString className)
{
    sendCommand("existClass(" + className + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

QString OMCProxy::getSourceFile(QString modelName)
{
    sendCommand("getSourceFile(" + modelName + ")");
    return getResult();
}

QString OMCProxy::list(QString className)
{
    sendCommand("list(" + className + ")");
    return StringHandler::removeFirstLastQuotes(getResult()).trimmed();
}

bool OMCProxy::addComponent(QString name, QString className, QString modelName)
{
    sendCommand("addComponent(" + name + ", " + className + "," + modelName + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

bool OMCProxy::deleteComponent(QString name, QString modelName)
{
    sendCommand("deleteComponent(" + name + "," + modelName + ")");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

void OMCProxy::renameComponent(QString oldName, QString className, QString newName)
{
    sendCommand("renameComponent(" + oldName + "," + className + "," + newName + ")");
}

bool OMCProxy::addConnection(QString from, QString to, QString className)
{
    sendCommand("addConnection(" + from + "," + to + "," + className + ")");
    if (getResult().contains("Ok"))
        return true;
    else
        return false;
}

bool OMCProxy::deleteConnection(QString from, QString to, QString className)
{
    sendCommand("deleteConnection(" + from + "," + to + "," + className + ")");
    if (getResult().contains("Ok"))
        return true;
    else
        return false;
}

bool OMCProxy::simulate(QString modelName, QString simualtionParameters)
{
    sendCommand("simulate(" + modelName + "," + simualtionParameters + ")");
    if (getResult().contains("res.plt"))
        return true;
    else
        return false;
}

bool OMCProxy::plot(QString modelName, QString plotVariables)
{
    sendCommand("plot(" + modelName + ",{" + plotVariables + "})");
    if (getResult().contains("true"))
        return true;
    else
        return false;
}

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
