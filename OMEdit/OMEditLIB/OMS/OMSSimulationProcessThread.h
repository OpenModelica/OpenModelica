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
#ifndef OMSSIMULATIONPROCESSTHREAD_H
#define OMSSIMULATIONPROCESSTHREAD_H

#include "OMS/OMSSimulationOutputWidget.h"
#include "Util/StringHandler.h"

#include <QThread>

/*!
 * \brief The OMSSimulationSubscriberThread class
 * Thread for zmq subscriber socket
 */
class OMSSimulationSubscriberThread : public QThread
{
  Q_OBJECT
public:
  /*!
   * \brief OMSSimulationSubscriberThread
   * \param parent
   */
  OMSSimulationSubscriberThread(QObject *parent = 0);
  ~OMSSimulationSubscriberThread();
  void setIsFinished(bool isFinished) {mIsFinished = isFinished;}
  QString getEndPoint() const {return mEndPoint;}
  QString getBindError() const {return mBindError;}
private:
  void *mpContext;
  void *mpSubscriberSocket;
  bool mIsFinished;
  QString mEndPoint;
  QString mBindError;
protected:
  /*!
   * \brief run
   * Reimplementation of QThread::run();
   * Runs a loop to read the simulation progress data.
   */
  virtual void run() override;
signals:
  /*!
   * \brief sendProgressJson
   * Sends the simulation progress json to output window.
   * \param progressJson
   */
  void sendProgressJson(QString progressJson);
};

/*!
 * \brief The OMSSimulationProcessThread class
 * Thread for running the OMSimulatorPython process.
 */
class OMSSimulationProcessThread : public QThread
{
  Q_OBJECT
public:
  /*!
   * \brief OMSSimulationProcessThread
   * \param fileName
   * \param parent
   */
  OMSSimulationProcessThread(const QString &fileName, QObject *parent = 0);
  ~OMSSimulationProcessThread();
  QProcess* getSimulationProcess() {return mpSimulationProcess;}
  void setSimulationProcessKilled(bool killed) {mIsSimulationProcessKilled = killed;}
  bool isSimulationProcessKilled() {return mIsSimulationProcessKilled;}
  bool isSimulationProcessRunning() {return mIsSimulationProcessRunning;}
protected:
  /*!
   * \brief run
   * Reimplementation of QThread::run();
   * Starts the OMSimulatorPython process.
   */
  virtual void run() override;
private:
  QString mFileName;
  QProcess *mpSimulationProcess;
  bool mIsSimulationProcessKilled;
  bool mIsSimulationProcessRunning;
  OMSSimulationSubscriberThread *mpOMSSimulationSubscriberThread;
private slots:
  /*!
   * \brief simulationProcessStarted
   * Called when process has started and sends that information to output window.
   */
  void simulationProcessStarted();
  /*!
   * \brief readSimulationStandardOutput
   * Reads the simulation process standard output and sends it to output window.
   */
  void readSimulationStandardOutput();
  /*!
   * \brief readSimulationStandardError
   * Reads the simulation process standard error and sends it to output window.
   */
  void readSimulationStandardError();
  /*!
   * \brief simulationProcessError
   * Called when any error has occurred in running the simulation process.
   * \param error
   */
  void simulationProcessError(QProcess::ProcessError error);
  /*!
   * \brief simulationProcessFinished
   * Called when process has finished and sends that information to output window.
   * \param exitCode
   * \param exitStatus
   */
  void simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
signals:
  /*!
   * \brief sendSimulationStarted
   * Sends the information that simulation process started.
   */
  void sendSimulationStarted();
  /*!
   * \brief sendSimulationOutput
   * Sends the simulation output to output window.
   * \param type
   */
  void sendSimulationOutput(QString, StringHandler::SimulationMessageType type, bool);
  /*!
   * \brief sendProgressJson
   * Sends the simulation process progress to output window for progress bar.
   */
  void sendProgressJson(QString);
  /*!
   * \brief sendSimulationFinished
   * Sends the information that simulation process finished.
   */
  void sendSimulationFinished(int, QProcess::ExitStatus);
};

#endif // OMSSIMULATIONPROCESSTHREAD_H
