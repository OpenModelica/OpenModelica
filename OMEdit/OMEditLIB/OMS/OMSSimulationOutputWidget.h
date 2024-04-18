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

#ifndef OMSSIMULATIONOUTPUTWIDGET_H
#define OMSSIMULATIONOUTPUTWIDGET_H

#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "OMSimulator/OMSimulator.h"

#include <QWidget>
#include <QProgressBar>
#include <QDateTime>
#include <QTextBrowser>

class SimulationSubscriberSocket : public QObject
{
  Q_OBJECT
public:
  SimulationSubscriberSocket();
  ~SimulationSubscriberSocket();
  QString getEndPoint() const {return mEndPoint;}
  QString getErrorString() const {return mErrorString;}
  void setSocketConnected(bool socketConnected) {mSocketConnected = socketConnected;}
  bool isSocketConnected() const {return mSocketConnected;}
private:
  void *mpContext;
  void *mpSocket;
  QString mEndPoint;
  QString mErrorString;
  bool mSocketConnected;
signals:
  void simulationDataPublished(const QByteArray &data);
public slots:
  void readSimulationData();
};

class SimulationRequestSocket : public QObject
{
  Q_OBJECT
public:
  SimulationRequestSocket();
  ~SimulationRequestSocket();
  QString getEndPoint() const {return mEndPoint;}
  QString getErrorString() const {return mErrorString;}
  void setSocketConnected(bool socketConnected) {mSocketConnected = socketConnected;}
  bool isSocketConnected() const {return mSocketConnected;}
private:
  void *mpContext;
  void *mpSocket;
  QString mEndPoint;
  QString mErrorString;
  bool mSocketConnected;
signals:
  void simulationReply(const QByteArray &reply, const QString &function, const QString &argument);
public slots:
  void sendRequest(const QString &function, const QString &argument);
};

class ArchivedSimulationItem;
class OutputPlainTextEdit;
class OMSSimulationOutputWidget : public QWidget
{
  Q_OBJECT
public:
  OMSSimulationOutputWidget(const QString &cref, const QString &fileName, bool interactive, QWidget *pParent = 0);
  ~OMSSimulationOutputWidget();
  QProcess* getSimulationProcess() {return mpSimulationProcess;}
  bool isSimulationProcessKilled() {return mIsSimulationProcessKilled;}
  bool isSimulationProcessRunning() {return mIsSimulationProcessRunning;}
private:
  QString mCref;
  double mStartTime;
  double mStopTime;
  QString mResultFilePath;
  Label *mpProgressLabel;
  QProgressBar *mpProgressBar;
  QPushButton *mpCancelSimulationButton;
  OutputPlainTextEdit *mpSimulationOutputPlainTextEdit;
  ArchivedSimulationItem *mpArchivedSimulationItem;
  QDateTime mResultFileLastModifiedDateTime;
  QProcess *mpSimulationProcess;
  bool mIsSimulationProcessKilled;
  bool mIsSimulationProcessRunning;
  SimulationSubscriberSocket *mpSimulationSubscriberSocket;
  SimulationRequestSocket *mpSimulationRequestSocket;
  QThread mSimulationSubscribeThread;
  QThread mSimulationRequestThread;

  void parseSimulationProgress(const QVariant progress);
  void parseSimulationVariables(const QVariant variables);
  void updateMessageTab(const QString &text);
  void updateMessageTabProgress();
signals:
  void sendRequest(const QString &function, const QString &argument);
  void updateText(const QString &text);
  void updateProgressBar(QProgressBar *pProgressBar);
public slots:
  void simulationProcessStarted();
  void readSimulationStandardOutput();
  void readSimulationStandardError();
  void simulationProcessError(QProcess::ProcessError error);
  void writeSimulationOutput(const QString &output, StringHandler::SimulationMessageType type);
  void simulationDataPublished(const QByteArray &data);
  void simulationReply(const QByteArray &reply, const QString &function, const QString &argument);
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void cancelSimulation();
  void pauseSimulation();
  void continueSimulation();
  void endSimulation();
};

#endif // OMSSIMULATIONOUTPUTWIDGET_H
