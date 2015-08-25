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

#include "FetchInterfaceDataDialog.h"

FetchInterfaceDataDialog::FetchInterfaceDataDialog(LibraryTreeItem *pLibraryTreeItem, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint), mpMainWindow(pMainWindow), mpLibraryTreeItem(pLibraryTreeItem)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Fetch Interface Data")).append(" - ")
                 .append(mpLibraryTreeItem->getNameStructure()));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  mpLibraryTreeItem = pLibraryTreeItem;
  // progress
  mpProgressLabel = new Label;
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  // cancel button
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelFetchingInterfaceData()));
  // try again button
  mpFetchAgainButton = new QPushButton(tr("Fetch Again"));
  mpFetchAgainButton->setEnabled(false);
  connect(mpFetchAgainButton, SIGNAL(clicked()), SLOT(fetchAgainInterfaceData()));
  // output
  mpOutputLabel = new Label(Helper::output);
  mpOutputTextBox = new QPlainTextEdit;
  mpOutputTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  // main Layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  pMainGridLayout->setContentsMargins(5, 5, 5, 5);
  pMainGridLayout->addWidget(mpProgressLabel, 0, 0, 1, 3);
  pMainGridLayout->addWidget(mpProgressBar, 1, 0);
  pMainGridLayout->addWidget(mpCancelButton, 1, 1);
  pMainGridLayout->addWidget(mpFetchAgainButton, 1, 2);
  pMainGridLayout->addWidget(mpOutputLabel, 2, 0, 1, 3);
  pMainGridLayout->addWidget(mpOutputTextBox, 3, 0, 1, 3);
  setLayout(pMainGridLayout);
  // create the thread
  mpFetchInterfaceDataThread = new FetchInterfaceDataThread(this);
  connect(mpFetchInterfaceDataThread, SIGNAL(sendManagerStarted()), SLOT(managerProcessStarted()));
  connect(mpFetchInterfaceDataThread, SIGNAL(sendManagerOutput(QString,StringHandler::SimulationMessageType)),
          SLOT(writeManagerOutput(QString,StringHandler::SimulationMessageType)));
  connect(mpFetchInterfaceDataThread, SIGNAL(sendManagerFinished(int,QProcess::ExitStatus)),
          SLOT(managerProcessFinished(int,QProcess::ExitStatus)));
  mpFetchInterfaceDataThread->start();
}

/*!
 * \brief FetchInterfaceDataDialog::closeEvent
 * \param event
 * Reimplentation of QDialog::closeEvent(). Doesn't allow closing the dialog if we are fetching interface data.
 */
void FetchInterfaceDataDialog::closeEvent(QCloseEvent *event)
{
  if (mpFetchInterfaceDataThread->isManagerProcessRunning()) {
    event->ignore();
  } else {
    mpFetchInterfaceDataThread->exit();
    mpFetchInterfaceDataThread->wait();
    event->accept();
  }
}

/*!
 * \brief FetchInterfaceDataDialog::cancelFetchingInterfaceData
 * Slot activated when mpCancelButton clicked signal is raised.\n
 * Kills the manager process.
 */
void FetchInterfaceDataDialog::cancelFetchingInterfaceData()
{
  if (mpFetchInterfaceDataThread->isManagerProcessRunning()) {
    mpFetchInterfaceDataThread->getManagerProcess()->kill();
    mpProgressLabel->setText(tr("Fetching interface data for <b>%1</b> is cancelled.").arg(mpLibraryTreeItem->getNameStructure()));
    mpCancelButton->setEnabled(false);
    mpFetchAgainButton->setEnabled(true);
  }
}

void FetchInterfaceDataDialog::fetchAgainInterfaceData()
{
  if (mpFetchInterfaceDataThread->isRunning()) {
    mpFetchInterfaceDataThread->exit();
    mpFetchInterfaceDataThread->wait();
  }
  mpFetchInterfaceDataThread->start();
}

/*!
 * \brief FetchInterfaceDataDialog::managerProcessStarted
 * Slot activated when FetchInterfaceDataThread sendManagerStarted signal is raised.\n
 * Updates the progress label, bar and stop manager button controls.
 */
void FetchInterfaceDataDialog::managerProcessStarted()
{
  mpProgressLabel->setText(tr("Fetching interface data for <b>%1</b>...").arg(mpLibraryTreeItem->getNameStructure()));
  mpProgressBar->setRange(0, 0);
  mpProgressBar->setTextVisible(true);
  mpCancelButton->setEnabled(true);
  mpFetchAgainButton->setEnabled(false);
}

/*!
 * \brief FetchInterfaceDataDialog::writeManagerOutput
 * \param output
 * \param type
 * Slot activated when FetchInterfaceDataThread sendManagerOutput signal is raised.\n
 * Writes the manager standard output/error to the manager output text box.
 */
void FetchInterfaceDataDialog::writeManagerOutput(QString output, StringHandler::SimulationMessageType type)
{
  /* move the cursor down before adding to the logger. */
  QTextCursor textCursor = mpOutputTextBox->textCursor();
  textCursor.movePosition(QTextCursor::End);
  mpOutputTextBox->setTextCursor(textCursor);
  /* set the text color */
  QTextCharFormat charFormat = mpOutputTextBox->currentCharFormat();
  charFormat.setForeground(StringHandler::getSimulationMessageTypeColor(type));
  mpOutputTextBox->setCurrentCharFormat(charFormat);
  /* append the output */
  mpOutputTextBox->insertPlainText(output + "\n");
  /* move the cursor */
  textCursor.movePosition(QTextCursor::End);
  mpOutputTextBox->setTextCursor(textCursor);
}

/*!
 * \brief FetchInterfaceDataDialog::managerProcessFinished
 * \param exitCode
 * \param exitStatus
 * Slot activated when FetchInterfaceDataThread sendManagerFinished signal is raised.
 */
void FetchInterfaceDataDialog::managerProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
  Q_UNUSED(exitCode);
  Q_UNUSED(exitStatus);
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setValue(mpProgressBar->maximum());
  mpCancelButton->setEnabled(false);
  mpFetchAgainButton->setEnabled(true);
  // if manager process has finished successfully then try reading the interface data.
  if (exitStatus == QProcess::NormalExit && exitCode == 0) {
    mpProgressLabel->setText(tr("Fetched interface data for <b>%1</b>...").arg(mpLibraryTreeItem->getNameStructure()));
    emit readInterfaceData(mpLibraryTreeItem);
  }
}

