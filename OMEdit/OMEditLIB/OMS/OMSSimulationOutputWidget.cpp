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

#include "OMSSimulationOutputWidget.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "OMSSimulationDialog.h"
#include "OMSProxy.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Options/OptionsDialog.h"
#include "OMSSimulationProcessThread.h"

#include <QGridLayout>

/*!
 * \class OMSSimulationOutputWidget
 * \brief Simulation output window.
 */
/*!
 * \brief OMSSimulationOutputWidget::OMSSimulationOutputWidget
 * Creates a simulation output window.
 * \param cref
 * \param fileName
 * \param pParent
 */
OMSSimulationOutputWidget::OMSSimulationOutputWidget(const QString &cref, const QString &fileName, QWidget *pParent)
  : QWidget(pParent), mCref(cref)
{
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, mCref, Helper::simulationOutput));
  // progress label
  mpProgressLabel = new Label(tr("Running simulation of <b>%1</b>. Please wait for a while.").arg(mCref));
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpCancelSimulationButton = new QPushButton(Helper::cancelSimulation);
  mpCancelSimulationButton->setEnabled(false);
  connect(mpCancelSimulationButton, SIGNAL(clicked()), SLOT(cancelSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  // simulation output browser
  mpSimulationOutputTextBrowser = new QTextBrowser;
  mpSimulationOutputTextBrowser->setFont(QFont(Helper::monospacedFontInfo.family()));
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpProgressLabel, 0, 0, 1, 2);
  pMainLayout->addWidget(mpProgressBar, 1, 0);
  pMainLayout->addWidget(mpCancelSimulationButton, 1, 1);
  pMainLayout->addWidget(mpSimulationOutputTextBrowser, 2, 0, 1, 2);
  setLayout(pMainLayout);
  // save the model start time
  OMSProxy::instance()->getStartTime(mCref, &mStartTime);
  // save the model stop time
  OMSProxy::instance()->getStopTime(mCref, &mStopTime);
  // create the ArchivedSimulationItem
  mpArchivedOMSSimulationItem = new ArchivedOMSSimulationItem(mCref, mStartTime, mStopTime, this);
  MainWindow::instance()->getOMSSimulationDialog()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedOMSSimulationItem);
  // save the last modified datetime of result file.
  char *resultFileName = (char*)"";
  int bufferSize;
  OMSProxy::instance()->getResultFile(mCref, &resultFileName, &bufferSize);
  mResultFilePath = QString("%1/%2").arg(OptionsDialog::instance()->getGeneralSettingsPage()->getWorkingDirectory(), QString(resultFileName));
  // save the current datetime as last modified datetime for result file.
  mResultFileLastModifiedDateTime = QDateTime::currentDateTime();
  mIsSimulationRunning = false;

  mpOMSSimulationProcessThread = new OMSSimulationProcessThread(fileName, this);
  connect(mpOMSSimulationProcessThread, SIGNAL(sendSimulationStarted()), SLOT(simulationProcessStarted()));
  connect(mpOMSSimulationProcessThread, SIGNAL(sendSimulationOutput(QString,StringHandler::SimulationMessageType,bool)),
          SLOT(writeSimulationOutput(QString,StringHandler::SimulationMessageType,bool)));
  connect(mpOMSSimulationProcessThread, SIGNAL(sendProgressJson(QString)), SLOT(simulationProgressJson(QString)));
  connect(mpOMSSimulationProcessThread, SIGNAL(sendSimulationFinished(int,QProcess::ExitStatus)), SLOT(simulationProcessFinished(int,QProcess::ExitStatus)));
  mpOMSSimulationProcessThread->start();
}

/*!
 * \brief OMSSimulationOutputWidget::~OMSSimulationOutputWidget
 * Saves the simulation output window geometry.
 */
OMSSimulationOutputWidget::~OMSSimulationOutputWidget()
{
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    Utilities::getApplicationSettings()->setValue("OMSSimulationOutputWidget/geometry", saveGeometry());
  }
}

/*!
 * \brief OMSSimulationOutputWidget::simulateCallback
 * This function is called by simulateCallback function from OMSProxy.\n
 * Emits the SIGNAL sendSimulationProgress so that we can update the GUI elements in the GUI thread.
 * \param ident
 * \param time
 * \param status
 */
void OMSSimulationOutputWidget::simulateCallback(const char* ident, double time, oms_status_enu_t status)
{
  emit sendSimulationProgress(QString(ident), time, status);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessStarted
 * Updates the simulation output window when the simulation has started.
 */
void OMSSimulationOutputWidget::simulationProcessStarted()
{
  mpProgressLabel->setText(tr("Running simulation of %1. Please wait for a while.").arg(mCref));
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  mpCancelSimulationButton->setEnabled(true);
  mpArchivedOMSSimulationItem->setStatus(Helper::running);
}

/*!
 * \brief OMSSimulationOutputWidget::writeSimulationOutput
 * Writes the simulation output.
 * \param output
 * \param type
 * \param textFormat
 */
void OMSSimulationOutputWidget::writeSimulationOutput(QString output, StringHandler::SimulationMessageType type, bool textFormat)
{
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpSimulationOutputTextBrowser->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpSimulationOutputTextBrowser->setTextCursor(textCursor);
  /* set the text color */
  QTextCharFormat charFormat = mpSimulationOutputTextBrowser->currentCharFormat();
  charFormat.setForeground(StringHandler::getSimulationMessageTypeColor(type));
  mpSimulationOutputTextBrowser->setCurrentCharFormat(charFormat);
  /* append the output */
  /* write the error message */
  mpSimulationOutputTextBrowser->insertPlainText(output);
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProgressJson
 * Reads the simulation progress json and updates the progress bar.
 * \param progressJson
 */
void OMSSimulationOutputWidget::simulationProgressJson(QString progressJson)
{
  int colonIndex = progressJson.indexOf(":");
  if (colonIndex != -1) {
    QString progressStr = progressJson.mid(colonIndex + 1);
    progressStr.chop(1);
    bool ok;
    int progress = progressStr.toInt(&ok);
    if (ok) {
      mpProgressBar->setValue(progress);
    }
  }
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProcessFinished
 * Updates the simulation output window when the simulation is finished.
 * \param exitCode
 * \param exitStatus
 */
void OMSSimulationOutputWidget::simulationProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  Q_UNUSED(exitStatus);
  mpProgressLabel->setText(tr("Simulation of %1 is finished.").arg(mCref));
  mpProgressBar->setValue(mpProgressBar->maximum());
  mpCancelSimulationButton->setEnabled(false);
  // simulation finished show the results
  MainWindow::instance()->getOMSSimulationDialog()->simulationFinished(mResultFilePath, mResultFileLastModifiedDateTime);
  mpArchivedOMSSimulationItem->setStatus(Helper::finished);
}

/*!
 * \brief OMSSimulationOutputWidget::cancelSimulation
 * Slot activated when mpCancelSimulationButton clicked SIGNAL is raised.\n
 * Cancels the running simulation.
 */
void OMSSimulationOutputWidget::cancelSimulation()
{
  if (mpOMSSimulationProcessThread->isSimulationProcessRunning()) {
    mpOMSSimulationProcessThread->setSimulationProcessKilled(true);
    mpOMSSimulationProcessThread->getSimulationProcess()->kill();
    mpProgressLabel->setText(tr("Simulation of %1 is cancelled.").arg(mCref));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mpCancelSimulationButton->setEnabled(false);
    mpArchivedOMSSimulationItem->setStatus(Helper::finished);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::keyPressEvent
 * Closes the widget when Esc key is pressed.
 * \param event
 */
void OMSSimulationOutputWidget::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    close();
    return;
  }
  QWidget::keyPressEvent(event);
}

/*!
 * \brief OMSSimulationOutputWidget::closeEvent
 * Reimplementation of QWidget::closeEvent(). Ignores the event if simulation process is running.
 * \param event
 */
void OMSSimulationOutputWidget::closeEvent(QCloseEvent *event)
{
  if (mpOMSSimulationProcessThread->isSimulationProcessRunning()) {
    event->ignore();
  } else {
    event->accept();
  }
}
