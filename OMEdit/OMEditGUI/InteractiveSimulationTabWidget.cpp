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
 * Main Author 2011: Adeel Asghar
 *
 */

#include "InteractiveSimulationTabWidget.h"

using namespace OMPlot;

//! @class Parameter

//! Constructor
//! @param name is the parameter name string.
//! @param value is the parameter value string.
Parameter::Parameter(QString name, QString value, bool isProtected)
{
    mpParameterLabel = new QLabel(name);
    mpParameterTextBox = new QLineEdit(value);
    if (isProtected)
    {
        mpParameterLabel->setEnabled(false);
        mpParameterTextBox->setEnabled(false);
    }
}

//! Destructor
Parameter::~Parameter()
{
    delete mpParameterLabel;
    delete mpParameterTextBox;
}

QLabel* Parameter::getParameterLabel()
{
    return mpParameterLabel;
}

QLineEdit* Parameter::getParameterTextBox()
{
    return mpParameterTextBox;
}

//! @class ParameterWidget
ParametersWidget::ParametersWidget(InteractiveSimulationTab *pParent)
    : QWidget(pParent)
{
    mpInteractiveSimulationTab = pParent;

    mpHeadingLabel = new QLabel(tr("Parameters"));
    mpHeadingLabel->setFont(QFont("", Helper::headingFontSize - 5));
    mpTitleLabel = new QLabel(tr("* The parameters default value is used if no value is specified."));
    mpGridLayout = new QGridLayout;
    mpGridLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
    mpGridLayout->addWidget(mpHeadingLabel, 0, 0, 1, 2);
    mpGridLayout->addWidget(mpTitleLabel, 1, 0, 1, 2);

    setLayout(mpGridLayout);
}

ParametersWidget::~ParametersWidget()
{
    delete mpHeadingLabel;
    delete mpTitleLabel;
    delete mpGridLayout;
}

void ParametersWidget::addParameter(QString name, QString value, bool isProtected)
{
    static int count = 2;
    Parameter *pParameter = new Parameter(name, value, isProtected);
    mParametersList.append(pParameter);
    mpGridLayout->addWidget(pParameter->getParameterLabel(), count, 0);
    mpGridLayout->addWidget(pParameter->getParameterTextBox(), count, 1);
    count++;
}

//! @class VariablesWidget
VariablesWidget::VariablesWidget(InteractiveSimulationTab *pParent)
    : QWidget(pParent)
{
    mpInteractiveSimulationTab = pParent;

    mpHeadingLabel = new QLabel(tr("Variables"));
    mpHeadingLabel->setFont(QFont("", Helper::headingFontSize - 5));
    mpTitleLabel = new QLabel(tr("* Select the variable to plot it."));
    // set the layout
    mpVBLayout = new QVBoxLayout;
    mpVBLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
    mpVBLayout->addWidget(mpHeadingLabel);
    mpVBLayout->addWidget(mpTitleLabel);

    setLayout(mpVBLayout);
}

VariablesWidget::~VariablesWidget()
{
    delete mpHeadingLabel;
    delete mpTitleLabel;
    delete mpVBLayout;
}

QList<QCheckBox*> VariablesWidget::getVariablesList()
{
    return mVariablesList;
}

void VariablesWidget::addVariable(QString name)
{
    mpVariableCheckBox = new QCheckBox(name);
    mVariablesList.append(mpVariableCheckBox);
    mpVBLayout->addWidget(mpVariableCheckBox);
}

//! @class OMIProxy
//! @brief It contains TCP/IP client implementation used for communication with OpenModelica Interactive subsystem.

//! Constructor
OMIProxy::OMIProxy(InteractiveSimulationTab *pParent)
    : mMessageCounter(0)
{
    mpInteractiveSimulationTab = pParent;
    // create the OMI Logger dialog
    mpOMILogger = new QDialog();
    mpOMILogger->setWindowFlags(Qt::WindowTitleHint);
    mpOMILogger->setMinimumSize(640, 480);
    mpOMILogger->setWindowIcon(QIcon(":/Resources/icons/console.png"));
    mpOMILogger->setWindowTitle(QString(Helper::applicationName).append(" - OMI Messages Log"));
    // Set the omi runtime output label
    mpOMIRuntiumeOutputLabel = new QLabel(tr("OMI Runtime Output"));
    // Set the control server text box
    mpOMIRuntiumeOutputTextEdit = new QTextEdit();
    mpOMIRuntiumeOutputTextEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpOMIRuntiumeOutputTextEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpOMIRuntiumeOutputTextEdit->setReadOnly(true);
    mpOMIRuntiumeOutputTextEdit->setLineWrapMode(QTextEdit::WidgetWidth);
    mpOMIRuntiumeOutputTextEdit->setAutoFormatting(QTextEdit::AutoNone);
    // Set the control server label
    mpControlServerLabel = new QLabel(tr("OMI Control Server"));
    // Set the control server text box
    mpControlServerTextEdit = new QTextEdit();
    mpControlServerTextEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpControlServerTextEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpControlServerTextEdit->setReadOnly(true);
    mpControlServerTextEdit->setLineWrapMode(QTextEdit::WidgetWidth);
    mpControlServerTextEdit->setAutoFormatting(QTextEdit::AutoNone);
    // Set the transfer server label
    mpTransferServerLabel = new QLabel(tr("OMI Transfer Server"));
    // Set the transfer server text box
    mpTransferServerTextEdit = new QTextEdit();
    mpTransferServerTextEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpTransferServerTextEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpTransferServerTextEdit->setReadOnly(true);
    mpTransferServerTextEdit->setLineWrapMode(QTextEdit::WidgetWidth);
    mpTransferServerTextEdit->setAutoFormatting(QTextEdit::AutoNone);
    // Set the control client label
    mpControlClientLabel = new QLabel(tr("OMI Control Client"));
    // Set the control client text box
    mpControlClientTextEdit = new QTextEdit();
    mpControlClientTextEdit->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpControlClientTextEdit->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    mpControlClientTextEdit->setReadOnly(true);
    mpControlClientTextEdit->setLineWrapMode(QTextEdit::WidgetWidth);
    mpControlClientTextEdit->setAutoFormatting(QTextEdit::AutoNone);
    QVBoxLayout *verticalallayout = new QVBoxLayout;
    verticalallayout->addWidget(mpOMIRuntiumeOutputLabel);
    verticalallayout->addWidget(mpOMIRuntiumeOutputTextEdit);
    verticalallayout->addWidget(mpControlServerLabel);
    verticalallayout->addWidget(mpControlServerTextEdit);
    verticalallayout->addWidget(mpTransferServerLabel);
    verticalallayout->addWidget(mpTransferServerTextEdit);
    verticalallayout->addWidget(mpControlClientLabel);
    verticalallayout->addWidget(mpControlClientTextEdit);
    mpOMILogger->setLayout(verticalallayout);
    // set isConnected to false
    setConnected(false);
    setErrorOccurred(false);

    connect(this, SIGNAL(interactiveSimulationStarted(QString)),
            mpInteractiveSimulationTab->getParentTabWidget()->getParentMainWindow(),
            SLOT(switchToInteractiveSimulationView()));

    connect(this, SIGNAL(interactiveSimulationFinished()),
            mpInteractiveSimulationTab->getParentTabWidget()->getParentMainWindow(),
            SLOT(switchToModelingView()));
}

OMIProxy::~OMIProxy()
{
    delete mpOMILogger;
    // destroy the interactive simulaiton process
    if (mpSimulationProcess)
    {
        if (mpSimulationProcess->state() == QProcess::Running)
            mpSimulationProcess->kill();
    }
    // stop the control server and delete it
    if (mpControlServer)
    {
        mpControlServer->close();
        delete mpControlServer;
    }
    // stop the transfer server and delete it
    if (mpTransferServer)
    {
        mpTransferServer->close();
        delete mpTransferServer;
    }
}

void OMIProxy::incrementMessageCounter()
{
    mMessageCounter++;
}

int OMIProxy::getMessageCounter()
{
    return mMessageCounter;
}

void OMIProxy::setConnected(bool connected)
{
    mIsConnected = connected;
}

bool OMIProxy::isConnected()
{
    return mIsConnected;
}

void OMIProxy::setErrorOccurred(bool error)
{
    mErrorOccurred = error;
}

bool OMIProxy::isErrorOccurred()
{
    return mErrorOccurred;
}

void OMIProxy::startInteractiveSimulation(QString file)
{
    QStringList parameters;
    parameters << QString("-interactive");
    // if platform is win32 add .exe to the file
    QString init_file(file.split("/").last());
    #ifdef WIN32
        file = file.append(".exe");
    #endif
    QFileInfo fileInfo(file);
    // start the process
    mpSimulationProcess = new QProcess();
    #ifdef WIN32
        QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
        environment.insert("PATH", environment.value("Path") + ";" + QString(Helper::OpenModelicaHome).append("MinGW\\bin"));
        mpSimulationProcess->setProcessEnvironment(environment);
    #endif
    mpSimulationProcess->setWorkingDirectory(fileInfo.absolutePath());
    connect(mpSimulationProcess, SIGNAL(readyReadStandardOutput()), SLOT(readProcessStandardOutput()));
    connect(mpSimulationProcess, SIGNAL(readyReadStandardError()), SLOT(readProcessStandardError()));
    mpSimulationProcess->start(file, parameters);
    mpSimulationProcess->waitForStarted();
    // start the client control server
    mpControlServer = new OMIServer(OMIServer::CONTROLSERVER, this);
    mpControlServer->listen(QHostAddress(Helper::omi_network_address), Helper::omi_control_server_port);
    connect(mpControlServer, SIGNAL(recievedMessage(QString)), SLOT(readControlServerMessage(QString)));
    // start the transfer control server
    mpTransferServer = new OMIServer(OMIServer::TRANSFERSERVER, this);
    mpTransferServer->listen(QHostAddress(Helper::omi_network_address), Helper::omi_transfer_server_port);
    // create the control client socket and make signals slots connections
    mpControlClientSocket = new QTcpSocket(this);
    connect(mpControlClientSocket, SIGNAL(connected()), SLOT(controlClientConnected()));
    connect(mpControlClientSocket, SIGNAL(disconnected()), SLOT(controlClientDisConnected()));
    connect(mpControlClientSocket, SIGNAL(error(QAbstractSocket::SocketError)), SLOT(getSocketError(QAbstractSocket::SocketError)));
    connect(mpTransferServer, SIGNAL(recievedMessage(QString)), SLOT(readTransferServerMessage(QString)));
    // connect to omi control server
    mpControlClientSocket->connectToHost(QHostAddress(Helper::omi_network_address), Helper::omi_control_client_port);
    emit interactiveSimulationStarted(init_file.append("_init.xml"));
}

bool OMIProxy::sendMessage(QString message)
{
    if (!isConnected())
        return false;

    logOMIMessages(message);
    qint16 status = mpControlClientSocket->write(message.toLatin1(), message.size());
    if (status == -1)
        return false;
    else
        return true;
}

bool OMIProxy::sendSequenceMessage(QString message)
{
    incrementMessageCounter();
    return sendMessage(message.arg(QString::number(getMessageCounter())));
}

void OMIProxy::setResult(QString result)
{
    mResult = result;
}

QString OMIProxy::getResult()
{
    return mResult;
}

void OMIProxy::logOMIMessages(QString message)
{
    // move the cursor down before adding to the logger.
    QTextCursor textCursor = mpControlClientTextEdit->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpControlClientTextEdit->setTextCursor(textCursor);
    // log message
    mpControlClientTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Bold, false));
    mpControlClientTextEdit->insertPlainText(QString(">>---- Message Send : ").append(QTime::currentTime().toString()).append(" ----"));
    mpControlClientTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Normal, false));
    mpControlClientTextEdit->insertPlainText(QString("\n>>  ").append(message).append("\n"));
    // move the cursor
    textCursor.movePosition(QTextCursor::End);
    mpControlClientTextEdit->setTextCursor(textCursor);
}

//! Opens the OMI Logger dialog.
void OMIProxy::openOMILogger()
{
    mpOMILogger->raise();
    mpOMILogger->show();
}

void OMIProxy::controlClientConnected()
{
    setConnected(true);
}

void OMIProxy::controlClientDisConnected()
{
    setConnected(false);
    // close the interactive simulation tab
    mpInteractiveSimulationTab->getParentTabWidget()->closeInetractiveSimulationTab(mpInteractiveSimulationTab->getTabPosition(), false);
}

void OMIProxy::readControlServerMessage(QString message)
{
    // move the cursor down before adding to the logger.
    QTextCursor textCursor = mpControlServerTextEdit->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpControlServerTextEdit->setTextCursor(textCursor);
    // log message
    mpControlServerTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Bold, false));
    mpControlServerTextEdit->insertPlainText(QString(">>---- Message Received : ").append(QTime::currentTime().toString()).append(" ----"));
    mpControlServerTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Normal, false));
    mpControlServerTextEdit->insertPlainText(QString("\n>>  ").append(message).append("\n"));
    // move the cursor
    textCursor.movePosition(QTextCursor::End);
    mpControlServerTextEdit->setTextCursor(textCursor);
}

void OMIProxy::readTransferServerMessage(QString message)
{
    // send the message to interactive simulation widget
    /* QTimer and QSignalMapper are the best :) */
    QSignalMapper *pSingnalMapper = new QSignalMapper;
    QTimer *pTimer = new QTimer;
    pTimer->setSingleShot(true);
    pTimer->setInterval(1000);          // 1 sec
    connect(pTimer, SIGNAL(timeout()), pSingnalMapper, SLOT(map()));
    pSingnalMapper->setMapping(pTimer, message);
    connect(pSingnalMapper, SIGNAL(mapped(QString)), mpInteractiveSimulationTab, SLOT(recievedResult(QString)));
    pTimer->start();
    // move the cursor down before adding to the logger.
    QTextCursor textCursor = mpTransferServerTextEdit->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpTransferServerTextEdit->setTextCursor(textCursor);
    // log the message
    mpTransferServerTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Bold, false));
    mpTransferServerTextEdit->insertPlainText(QString(">>---- Message Received : ").append(QTime::currentTime().toString()).append(" ----"));
    mpTransferServerTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Normal, false));
    mpTransferServerTextEdit->insertPlainText(QString("\n>>  ").append(message).append("\n"));
    // move the cursor
    textCursor.movePosition(QTextCursor::End);
    mpTransferServerTextEdit->setTextCursor(textCursor);
}

void OMIProxy::readProcessStandardOutput()
{
    mpOMIRuntiumeOutputTextEdit->setCurrentFont(QFont("Times New Roman", 10, QFont::Normal, false));
    mpOMIRuntiumeOutputTextEdit->append(QString(mpSimulationProcess->readAllStandardOutput()));
    // scroll the text to end
    QTextCursor textCursor = mpOMIRuntiumeOutputTextEdit->textCursor();
    textCursor.movePosition(QTextCursor::End);
    mpOMIRuntiumeOutputTextEdit->setTextCursor(textCursor);
}

void OMIProxy::readProcessStandardError()
{
    MessageWidget *pMessageWidget;
    pMessageWidget = mpInteractiveSimulationTab->getParentTabWidget()->getParentMainWindow()->mpMessageWidget;
    pMessageWidget->printGUIErrorMessage(QString(mpSimulationProcess->readAllStandardError()));
    mpInteractiveSimulationTab->getParentTabWidget()->closeInetractiveSimulationTab(mpInteractiveSimulationTab->getTabPosition(), false);
}

void OMIProxy::getSocketError(QAbstractSocket::SocketError socketError)
{
    MessageWidget *pMessageWidget;
    pMessageWidget = mpInteractiveSimulationTab->getParentTabWidget()->getParentMainWindow()->mpMessageWidget;
    switch (socketError)
    {
        case QAbstractSocket::HostNotFoundError:
            pMessageWidget->printGUIErrorMessage(tr("The OMI control server was not found."));
            mpInteractiveSimulationTab->getParentTabWidget()->closeInetractiveSimulationTab(mpInteractiveSimulationTab->getTabPosition(), false);
            break;
        case QAbstractSocket::ConnectionRefusedError:
            pMessageWidget->printGUIErrorMessage(tr("The OMI control server refuse the connection."));
            mpInteractiveSimulationTab->getParentTabWidget()->closeInetractiveSimulationTab(mpInteractiveSimulationTab->getTabPosition(), false);
            break;
        default:
            pMessageWidget->printGUIErrorMessage(tr("The following error occurred while communicating with OMI control server: %1.")
                                                 .arg(mpControlClientSocket->errorString()));
            mpInteractiveSimulationTab->getParentTabWidget()->closeInetractiveSimulationTab(mpInteractiveSimulationTab->getTabPosition(), false);
    }
    setErrorOccurred(true);
}

//! @class OMIServer
OMIServer::OMIServer(int serverType, OMIProxy *pParent)
    : mServerType(serverType), QTcpServer(pParent)
{
    mpOMIProxy = pParent;
}

OMIServer::~OMIServer()
{

}

int OMIServer::getServerType()
{
    return mServerType;
}

void OMIServer::readMessages()
{
    if (getServerType() == OMIServer::CONTROLSERVER)
    {
        emit recievedMessage(QString(mTcpSocket.read(mTcpSocket.bytesAvailable())));
    }
    else if (getServerType() == OMIServer::TRANSFERSERVER)
    {
        QString message(mTcpSocket.read(mTcpSocket.bytesAvailable()));
        QStringList messages = message.split("end", QString::SkipEmptyParts);

        foreach (QString msg, messages)
        {
            emit recievedMessage(msg.append("end"));
        }
    }
}

void OMIServer::incomingConnection(int socketDescriptor)
{
    if (!mTcpSocket.setSocketDescriptor(socketDescriptor))
    {
        // do some error management
        return;
    }
    connect(&mTcpSocket, SIGNAL(readyRead()), SLOT(readMessages()));
}

//! @class InteractiveSimulation
InteractiveSimulationTab::InteractiveSimulationTab(QString filePath, InteractiveSimulationTabWidget *pParent)
    : QWidget(pParent)
{
    mpParentInteractiveSimulationTabWidget = pParent;
    // create the OMIProxy instance
    mpOMIProxy = new OMIProxy(this);
    connect(mpOMIProxy, SIGNAL(interactiveSimulationStarted(QString)), SLOT(readParametersandVariables(QString)));
    // create the plot window
    mpPlotWindow = new PlotWindow();
    mpPlotWindow->setTitle(tr(""));
    // create interactive simulation initialize, start, pause, shut down buttons
    mpInitializeButton = new QToolButton;
    mpInitializeButton->setText(tr("Initialize"));
    mpInitializeButton->setIcon(QIcon(":/Resources/icons/rename.png"));
    mpInitializeButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpInitializeButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpInitializeButton->setToolTip(Helper::omi_initialize_button_tooltip);
    mpInitializeButton->setStatusTip(Helper::omi_initialize_button_tooltip);
    connect(mpInitializeButton, SIGNAL(clicked()), SLOT(initializeInteractivePlotting()));
    // start button
    mpStartButton = new QToolButton;
    mpStartButton->setText(tr("Start"));
    mpStartButton->setIcon(QIcon(":/Resources/icons/start.png"));
    mpStartButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpStartButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpStartButton->setToolTip(Helper::omi_start_button_tooltip);
    mpStartButton->setStatusTip(Helper::omi_start_button_tooltip);
    mpStartButton->setEnabled(false);
    connect(mpStartButton, SIGNAL(clicked()), SLOT(startInteractivePlotting()));
    // pause button
    mpPauseButton = new QToolButton;
    mpPauseButton->setText(tr("Pause"));
    mpPauseButton->setIcon(QIcon(":/Resources/icons/pause.png"));
    mpPauseButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpPauseButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpPauseButton->setToolTip(Helper::omi_pause_button_tooltip);
    mpPauseButton->setStatusTip(Helper::omi_pause_button_tooltip);
    mpPauseButton->setEnabled(false);
    connect(mpPauseButton, SIGNAL(clicked()), SLOT(pauseInteractivePlotting()));
    // pause button
    mpStopButton = new QToolButton;
    mpStopButton->setText(tr("Stop"));
    mpStopButton->setIcon(QIcon(":/Resources/icons/stop.png"));
    mpStopButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpStopButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpStopButton->setToolTip(Helper::omi_stop_button_tooltip);
    mpStopButton->setStatusTip(Helper::omi_stop_button_tooltip);
    connect(mpStopButton, SIGNAL(clicked()), SLOT(stopInteractivePlotting()));
    // shutdown button
    mpShutdownButton = new QToolButton;
    mpShutdownButton->setText(tr("Shut Down"));
    mpShutdownButton->setIcon(QIcon(":/Resources/icons/shutdown.png"));
    mpShutdownButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpShutdownButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpShutdownButton->setToolTip(Helper::omi_shutdown_button_tooltip);
    mpShutdownButton->setStatusTip(Helper::omi_shutdown_button_tooltip);
    connect(mpShutdownButton, SIGNAL(clicked()), SLOT(shutdownInteractivePlotting()));
    // show OMI log button
    mpShowOMILogButton = new QToolButton;
    mpShowOMILogButton->setText(tr("Show OMI Log"));
    mpShowOMILogButton->setIcon(QIcon(":/Resources/icons/console.png"));
    mpShowOMILogButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    mpShowOMILogButton->setObjectName(tr("InteractiveSimulationButtons"));
    mpShowOMILogButton->setToolTip(Helper::omi_showlog_button_tooltip);
    mpShowOMILogButton->setStatusTip(Helper::omi_showlog_button_tooltip);
    connect(mpShowOMILogButton, SIGNAL(clicked()), mpOMIProxy, SLOT(openOMILogger()));
    // create layout for buttons
    QHBoxLayout *buttonsLayout = new QHBoxLayout;
    buttonsLayout->addWidget(mpInitializeButton);
    buttonsLayout->addWidget(mpStartButton);
    buttonsLayout->addWidget(mpPauseButton);
    buttonsLayout->addWidget(mpStopButton);
    buttonsLayout->addWidget(mpShutdownButton);
    buttonsLayout->addWidget(mpShowOMILogButton);
    // create layout for plot window and buttons
    QVBoxLayout *verticalLayout = new QVBoxLayout;
    verticalLayout->setContentsMargins(5, 5, 5, 5);
    verticalLayout->addWidget(mpPlotWindow);
    verticalLayout->addLayout(buttonsLayout);
    // create a widget for plotwindow and buttons so that we can add it to splitter
    mpPlotWindowContainer = new QWidget;
    mpPlotWindowContainer->setLayout(verticalLayout);
    mpPlotWindowContainer->installEventFilter(this);
    // create the parameters window
    mpParametersWidget = new ParametersWidget(this);
    QScrollArea *pParametersScrollArea = new QScrollArea;
    pParametersScrollArea->setBackgroundRole(QPalette::Base);
    pParametersScrollArea->setWidgetResizable(true);
    pParametersScrollArea->setWidget(mpParametersWidget);
    // create the variables window
    mpVariablesWidget = new VariablesWidget(this);
    QScrollArea *pVariablesScrollArea = new QScrollArea;
    pVariablesScrollArea->setBackgroundRole(QPalette::Base);
    pVariablesScrollArea->setWidgetResizable(true);
    pVariablesScrollArea->setWidget(mpVariablesWidget);
    // create splitter for parameters and variables window
    mpVerticalSplitter = new QSplitter;
    mpVerticalSplitter->setChildrenCollapsible(false);
    mpVerticalSplitter->setOrientation(Qt::Vertical);
    mpVerticalSplitter->addWidget(pParametersScrollArea);
    mpVerticalSplitter->addWidget(pVariablesScrollArea);
    // create the splitter for the whole widget
    mpHorizontalSplitter = new QSplitter;
    mpHorizontalSplitter->setChildrenCollapsible(false);
    mpHorizontalSplitter->addWidget(mpPlotWindowContainer);
    mpHorizontalSplitter->addWidget(mpVerticalSplitter);
    QList<int> sizes;
    sizes << 100 << 210;
    mpHorizontalSplitter->setSizes(sizes);
    // start the interactive simulation exe and servers
    mpOMIProxy->startInteractiveSimulation(filePath);
    // set the layout
    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(2, 2, 2, 2);
    layout->addWidget(mpHorizontalSplitter);
    setLayout(layout);
}

InteractiveSimulationTab::~InteractiveSimulationTab()
{
    delete mpOMIProxy;
    delete mpPlotWindow;
    delete mpParametersWidget;
    delete mpVariablesWidget;
}

InteractiveSimulationTabWidget* InteractiveSimulationTab::getParentTabWidget()
{
    return mpParentInteractiveSimulationTabWidget;
}

void InteractiveSimulationTab::setName(QString name)
{
    mName = name;
}

QString InteractiveSimulationTab::getName()
{
    return mName;
}

void InteractiveSimulationTab::setTabPosition(int position)
{
    mTabPosition = position;
}

int InteractiveSimulationTab::getTabPosition()
{
    return mTabPosition;
}

bool InteractiveSimulationTab::eventFilter(QObject *pObject, QEvent *event)
{
    if (pObject != mpPlotWindowContainer)
        return false;

    if (event->type() == QEvent::Paint)
    {
        QPainter painter (mpPlotWindowContainer);
        painter.setPen(Qt::gray);
        QRect rectangle = mpPlotWindowContainer->rect();
        rectangle.setWidth(mpPlotWindowContainer->rect().width() - 1);
        rectangle.setHeight(mpPlotWindowContainer->rect().height() - 1);
        painter.drawRect(rectangle);
        return true;
    }

    return false;
}

bool InteractiveSimulationTab::checkVariablesSelected()
{
    // if no variables are selected return false
    foreach(QCheckBox* variable, mpVariablesWidget->getVariablesList())
    {
        if (variable->checkState() == Qt::Checked)
            return true;
    }

    QMessageBox::information(mpParentInteractiveSimulationTabWidget->getParentMainWindow(),
                             Helper::applicationName + " - Information",
                             GUIMessages::getMessage(GUIMessages::SELECT_VARIABLE_FOR_OMI), "OK");

    return false;
}

void InteractiveSimulationTab::readParametersandVariables(QString filePath)
{
    MainWindow *pMainWindow = mpParentInteractiveSimulationTabWidget->getParentMainWindow();
    ProjectTab *pProjectTab = pMainWindow->mpProjectTabs->getCurrentTab();

    if (!pProjectTab)
        return;

    readComponentsRecursive(pProjectTab->mModelNameStructure, pProjectTab->mModelNameStructure);
    // read the variables to be plotted
    try {
      QList<QString> variablesList = pMainWindow->mpPlotWidget->readPlotVariables(filePath);
      //qSort(variablesList.begin(), variablesList.end());
      foreach(QString variable, variablesList)
          mpVariablesWidget->addVariable(variable);
    } catch (...) {
    }
}

void InteractiveSimulationTab::readComponentsRecursive(QString modelName, QString className, QString namePrefixStr)
{
    OMCProxy *pOMCProxy = mpParentInteractiveSimulationTabWidget->getParentMainWindow()->mpOMCProxy;
    QList<ComponentsProperties*> components = pOMCProxy->getComponents(className);

    if (!components.isEmpty())
    {
        foreach (ComponentsProperties *pComponent, components)
        {
            if (pOMCProxy->getComponents(pComponent->getClassName()).isEmpty())
            {
                if (pComponent->getVariablity().compare("parameter") == 0)
                {
                    QString parameterValue = pOMCProxy->getComponentModifierValue(modelName, QString(namePrefixStr)
                                                                                  .append(pComponent->getName()));
                    if (parameterValue.isEmpty())
                        parameterValue = pOMCProxy->getParameterValue(className, pComponent->getName());
                    mpParametersWidget->addParameter(namePrefixStr + pComponent->getName(), parameterValue, pComponent->getProtected());
                }
            }
            else
            {
                readComponentsRecursive(modelName, pComponent->getClassName(),
                                    QString(namePrefixStr).append(pComponent->getName()).append("."));
            }
        }
    }
}

void InteractiveSimulationTab::initializeInteractivePlotting()
{
    // check variables selected
    if (!checkVariablesSelected())
        return;

    bool detachFlag;
    foreach (PlotCurve *pPlotCurve, mpPlotWindow->getPlot()->getPlotCurvesList())
    {
        detachFlag = true;
        foreach(QCheckBox* variable, mpVariablesWidget->getVariablesList())
        {
            if (variable->text().compare(pPlotCurve->title().text()) == 0)
            {
                detachFlag = false;
                break;
            }
        }
        if (detachFlag)
        {
            pPlotCurve->detach();
            mpPlotWindow->getPlot()->removeCurve(pPlotCurve);
        }
    }

    bool attachFlag;
    PlotCurve *pPlotCurve;
    QStringList selectedVariablesList;
    QList<QCheckBox*> variablesList = mpVariablesWidget->getVariablesList();
    int i = 0;
    foreach(QCheckBox* variable, variablesList)
    {
        i++;
        attachFlag = true;
        if (variable->checkState() == Qt::Checked)
        {
            selectedVariablesList.append(variable->text());
            foreach (PlotCurve *pPlotCurve1, mpPlotWindow->getPlot()->getPlotCurvesList())
            {
                if (variable->text().compare(pPlotCurve1->title().text()) == 0)
                {
                    attachFlag = false;
                    break;
                }
            }
            if (attachFlag)
            {
                pPlotCurve = new PlotCurve(mpPlotWindow->getPlot());
                pPlotCurve->setTitle(variable->text());
                pPlotCurve->attach(mpPlotWindow->getPlot());
                mpPlotWindow->getPlot()->addPlotCurve(pPlotCurve);
            }
        }
    }
    if (!selectedVariablesList.isEmpty())
    {
        mpOMIProxy->sendSequenceMessage(tr("setfilter#%1#").append(selectedVariablesList.join(":")).append("#end"));
    }

    // make the start button enabled
    mpStartButton->setEnabled(true);
}

void InteractiveSimulationTab::startInteractivePlotting()
{
    // check variables selected
    if (!checkVariablesSelected())
        return;

    mpOMIProxy->sendSequenceMessage(tr("start#%1#end"));
    // make the pause button enabled and start and initialize disabled
    mpPauseButton->setEnabled(true);
    mpStartButton->setEnabled(false);
    mpInitializeButton->setEnabled(false);
}

void InteractiveSimulationTab::pauseInteractivePlotting()
{
    mpOMIProxy->sendSequenceMessage(tr("pause#%1#end"));
    // make the pause button disable and start and inititalize enabled
    mpPauseButton->setEnabled(false);
    mpStartButton->setEnabled(true);
    mpInitializeButton->setEnabled(true);
}

void InteractiveSimulationTab::stopInteractivePlotting()
{
    mpOMIProxy->sendSequenceMessage(tr("stop#%1#end"));
    // make the initialize button enable and start and pause diabled
    mpInitializeButton->setEnabled(true);
    mpStartButton->setEnabled(false);
    mpPauseButton->setEnabled(false);
}

void InteractiveSimulationTab::shutdownInteractivePlotting()
{
    mpOMIProxy->sendSequenceMessage(tr("shutdown#%1#end"));
    mpParentInteractiveSimulationTabWidget->closeInetractiveSimulationTab(getTabPosition(), false);
}

void InteractiveSimulationTab::recievedResult(QString message)
{
    int count = 0;
    QStringList list = message.split("#", QString::SkipEmptyParts);
    // remove first and last from list, since first is "result" and last is "end" and we don't need them
    if (list.size() < 4)
        return;
    list.removeFirst();
    list.removeLast();

    double time = static_cast<QString>(list.at(0)).toDouble();
    QStringList variables = static_cast<QString>(list.at(1)).split(":", QString::SkipEmptyParts);

    foreach (PlotCurve *pPlotCurve, mpPlotWindow->getPlot()->getPlotCurvesList())
    {
        QString variable = static_cast<QString>(variables.at(count));
        double element = variable.mid(variable.lastIndexOf("=") + 1, (variable.length() - 1)).trimmed().toDouble();
        pPlotCurve->addXAxisValue(time);
        pPlotCurve->addYAxisValue(element);
        pPlotCurve->setRawData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(), pPlotCurve->getSize());
        count++;
    }
}

void InteractiveSimulationTab::paintEvent(QPaintEvent *event)
{
    QPainter painter(this);
    painter.setPen(Qt::NoPen);
    painter.setBrush(QBrush(mpParentInteractiveSimulationTabWidget->palette().color(QPalette::Window)));
    painter.drawRect(rect());

    QWidget::paintEvent(event);
}

//! @class InteractiveSimulationTabWidget
InteractiveSimulationTabWidget::InteractiveSimulationTabWidget(MainWindow *pParent)
    : QTabWidget(pParent)
{
    mpParentMainWindow = pParent;
    // dont show this widget at startup
    setVisible(false);
    setTabsClosable(true);
    setContentsMargins(0, 0, 0, 0);

    connect(this, SIGNAL(tabCloseRequested(int)), SLOT(closeInetractiveSimulationTab(int)));
}

InteractiveSimulationTabWidget::~InteractiveSimulationTabWidget()
{

}

MainWindow* InteractiveSimulationTabWidget::getParentMainWindow()
{
    return mpParentMainWindow;
}

//! Adds a InteractiveSimulationTab object (a new tab) to itself.
//! @see closeInetractiveSimulationTab(int index)
void InteractiveSimulationTabWidget::addNewInteractiveSimulationTab(InteractiveSimulationTab *pInteractiveSimulationTab, QString tabName)
{
    pInteractiveSimulationTab->setName(tabName);
    pInteractiveSimulationTab->setTabPosition(addTab(pInteractiveSimulationTab, tabName));
    setCurrentWidget(pInteractiveSimulationTab);
}

//! Closes current interactive simulation tab.
//! @param index defines which project to close.
void InteractiveSimulationTabWidget::closeInetractiveSimulationTab(int index, bool askQuestion)
{
    InteractiveSimulationTab *pInteractiveSimualtion = dynamic_cast<InteractiveSimulationTab*>(widget(index));

    if (!askQuestion)
    {
        removeTab(index);
        delete pInteractiveSimualtion;
        return;
    }

    QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
    msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Information"));
    msgBox->setIcon(QMessageBox::Information);
    msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::CLOSE_INTERACTIVE_SIMULATION_TAB))
                    .arg(pInteractiveSimualtion->getName()));
    msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::INFO_CLOSE_INTERACTIVE_SIMULATION_TAB)));
    msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
    msgBox->setDefaultButton(QMessageBox::Yes);

    int answer = msgBox->exec();

    switch (answer)
    {
    case QMessageBox::Yes:
        // Yes was clicked
        removeTab(index);
        delete pInteractiveSimualtion;
        break;
    case QMessageBox::No:
        // No was clicked
        break;
    default:
        // should never be reached
        break;
    }
}
