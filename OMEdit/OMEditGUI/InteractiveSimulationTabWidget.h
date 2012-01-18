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

#ifndef INTERACTIVESIMULATIONTABWIDGET_H
#define INTERACTIVESIMULATIONTABWIDGET_H

#include "mainwindow.h"
#include "PlotWindow.h"
#include <QTcpServer>
#include <QTcpSocket>

class MainWindow;
class InteractiveSimulationTab;
class ParametersWidget;

class Parameter
{
private:
    QLabel *mpParameterLabel;
    QLineEdit *mpParameterTextBox;
public:
    Parameter(QString name, QString value, bool isProtected);
    ~Parameter();
    QLabel* getParameterLabel();
    QLineEdit* getParameterTextBox();
};

class ParametersWidget : public QWidget
{
    Q_OBJECT
public:
    ParametersWidget(InteractiveSimulationTab *pParent);
    ~ParametersWidget();
    void addParameter(QString name, QString value, bool isProtected);

    InteractiveSimulationTab *mpInteractiveSimulationTab;
    QLabel *mpHeadingLabel;
    QLabel *mpTitleLabel;
    QList<Parameter*> mParametersList;
    QGridLayout *mpGridLayout;
};

class VariablesWidget : public QWidget
{
    Q_OBJECT
private:
    InteractiveSimulationTab *mpInteractiveSimulationTab;
    QLabel *mpHeadingLabel;
    QLabel *mpTitleLabel;
    QCheckBox *mpVariableCheckBox;
    QList<QCheckBox*> mVariablesList;
    QVBoxLayout *mpVBLayout;
public:
    VariablesWidget(InteractiveSimulationTab *pParent);
    ~VariablesWidget();
    QList<QCheckBox*> getVariablesList();
public slots:
    void addVariable(QString name);
};

class OMIServer;

class OMIProxy : public QObject
{
    Q_OBJECT
private:
    InteractiveSimulationTab *mpInteractiveSimulationTab;
    OMIServer *mpControlServer;
    OMIServer *mpTransferServer;
    QTcpSocket *mpControlClientSocket;
    QProcess *mpSimulationProcess;
    int mMessageCounter;
    bool mIsConnected;
    bool mErrorOccurred;
    QString mResult;
    QDialog *mpOMILogger;
    QPushButton *mpSendButton;
    QLabel *mpOMIRuntiumeOutputLabel;
    QTextEdit *mpOMIRuntiumeOutputTextEdit;
    QLabel *mpControlServerLabel;
    QTextEdit *mpControlServerTextEdit;
    QLabel *mpTransferServerLabel;
    QTextEdit *mpTransferServerTextEdit;
    QLabel *mpControlClientLabel;
    QTextEdit *mpControlClientTextEdit;
public:
    OMIProxy(InteractiveSimulationTab *pParent);
    ~OMIProxy();
    void incrementMessageCounter();
    int getMessageCounter();
    void setConnected(bool connected);
    bool isConnected();
    void setErrorOccurred(bool error);
    bool isErrorOccurred();
    void startInteractiveSimulation(QString file);
    bool sendMessage(QString message);
    bool sendSequenceMessage(QString message);
    void setResult(QString result);
    QString getResult();
    void logOMIMessages(QString message);
signals:
    void interactiveSimulationStarted(QString filePath);
    void interactiveSimulationFinished();
public slots:
    void openOMILogger();
    void controlClientConnected();
    void controlClientDisConnected();
    void readControlServerMessage(QString message);
    void readTransferServerMessage(QString message);
    void readProcessStandardOutput();
    void readProcessStandardError();
    void getSocketError(QAbstractSocket::SocketError socketError);
};

class OMIServer : public QTcpServer
{
    Q_OBJECT
private:
    QTcpSocket mTcpSocket;
    OMIProxy *mpOMIProxy;
    int mServerType;
public:
    OMIServer(int serverType, OMIProxy *pParent);
    ~OMIServer();
    enum serverType {CONTROLSERVER, TRANSFERSERVER};
    int getServerType();
signals:
    void recievedMessage(QString message);
public slots:
    void readMessages();
protected:
    virtual void incomingConnection(int socketDescriptor);
};

class InteractiveSimulationTabWidget;

class InteractiveSimulationTab : public QWidget
{
    Q_OBJECT
private:
    InteractiveSimulationTabWidget *mpParentInteractiveSimulationTabWidget;
    OMIProxy *mpOMIProxy;

    OMPlot::PlotWindow *mpPlotWindow;
    ParametersWidget *mpParametersWidget;
    VariablesWidget *mpVariablesWidget;
    QSplitter *mpHorizontalSplitter;
    QSplitter *mpVerticalSplitter;
    QToolButton *mpInitializeButton;
    QToolButton *mpStartButton;
    QToolButton *mpPauseButton;
    QToolButton *mpStopButton;
    QToolButton *mpShutdownButton;
    QToolButton *mpShowOMILogButton;
    QWidget *mpPlotWindowContainer;
    QList<QwtPlotCurve*> mPlotCurvesList;

    QString mName;
    int mTabPosition;
public:
    InteractiveSimulationTab(QString filePath, InteractiveSimulationTabWidget *pParent);
    ~InteractiveSimulationTab();
    InteractiveSimulationTabWidget* getParentTabWidget();
    void setName(QString name);
    QString getName();
    void setTabPosition(int position);
    int getTabPosition();
    bool eventFilter(QObject *pObject, QEvent *event);
    bool checkVariablesSelected();
public slots:
    void readParametersandVariables(QString filePath);
    void readComponentsRecursive(QString modelName, QString className, QString namePrefixStr = QString());
    void initializeInteractivePlotting();
    void startInteractivePlotting();
    void pauseInteractivePlotting();
    void stopInteractivePlotting();
    void shutdownInteractivePlotting();
    void recievedResult(QString message);
protected:
    virtual void paintEvent(QPaintEvent *event);
};

class InteractiveSimulationTabWidget : public QTabWidget
{
    Q_OBJECT
private:
    MainWindow *mpParentMainWindow;
public:
    InteractiveSimulationTabWidget(MainWindow *pParent);
    ~InteractiveSimulationTabWidget();
    MainWindow* getParentMainWindow();
public slots:
    void addNewInteractiveSimulationTab(InteractiveSimulationTab *pInteractiveSimulationTab, QString tabName);
    void closeInetractiveSimulationTab(int index, bool askQuestion = true);
};

#endif // INTERACTIVESIMULATIONTABWIDGET_H
