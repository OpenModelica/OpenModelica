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

#include <QGridLayout>
#include <QtCore/qmath.h>

OMSSimulationOutputWidget::OMSSimulationOutputWidget(OMSSimulationOptions omsSimulationOptions, QWidget *pParent)
  : mOMSSimulationOptions(omsSimulationOptions)
{
  Q_UNUSED(pParent);
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName)
                 .arg(mOMSSimulationOptions.getModelName()).arg(Helper::simulationOutput));
  resize(640, 120);
  // simulation widget heading
  mpSimulationHeading = Utilities::getHeadingLabel(QString("%1 - %2")
                                                   .arg(tr("OMSimulator Simulation"), mOMSSimulationOptions.getModelName()));
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // progress label
  mpProgressLabel = new Label(tr("Running simulation of <b>%1</b>. Please wait for a while.").arg(mOMSSimulationOptions.getModelName()));
  mpProgressLabel->setTextFormat(Qt::RichText);
  mpCancelSimulationButton = new QPushButton(Helper::cancelSimulation);
  mpCancelSimulationButton->setEnabled(false);
  connect(mpCancelSimulationButton, SIGNAL(clicked()), SLOT(cancelSimulation()));
  mpProgressBar = new QProgressBar;
  mpProgressBar->setAlignment(Qt::AlignHCenter);
  mpProgressBar->setRange(0, 100);
  mpProgressBar->setTextVisible(true);
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(5, 5, 5, 5);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpSimulationHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpProgressLabel, 2, 0, 1, 2);
  pMainLayout->addWidget(mpProgressBar, 3, 0);
  pMainLayout->addWidget(mpCancelSimulationButton, 3, 1);
  setLayout(pMainLayout);
  // create the ArchivedSimulationItem
  mpArchivedOMSSimulationItem = new ArchivedOMSSimulationItem(mOMSSimulationOptions, this);
  MainWindow::instance()->getOMSSimulationDialog()->getArchivedSimulationsTreeWidget()->addTopLevelItem(mpArchivedOMSSimulationItem);
  // save the last modified datetime of result file.
  QFileInfo resultFileInfo(mOMSSimulationOptions.getWorkingDirectory() + "/" + mOMSSimulationOptions.getResultFileName());
  if (resultFileInfo.exists()) {
    mResultFileLastModifiedDateTime = resultFileInfo.lastModified();
  } else {
    mResultFileLastModifiedDateTime = QDateTime::currentDateTime();
  }
  mIsSimulationRunning = false;
  // initialize the model
  if (OMSProxy::instance()->initialize(mOMSSimulationOptions.getModelName())) {
    // start the asynchronous simulation
    qRegisterMetaType<oms_status_enu_t>("oms_status_enu_t");
    connect(this, SIGNAL(sendSimulationProgress(QString,double,oms_status_enu_t)), SLOT(simulationProgress(QString,double,oms_status_enu_t)));
    if (OMSProxy::instance()->simulate_asynchronous(mOMSSimulationOptions.getModelName())) {
      mIsSimulationRunning = true;
      mpCancelSimulationButton->setEnabled(true);
    } else {
      mpProgressLabel->setText(tr("Simulation using the <b>%1</b> model is failed. %2")
                               .arg(mOMSSimulationOptions.getModelName())
                               .arg(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER)));
      mpProgressBar->setValue(mpProgressBar->maximum());
      mpArchivedOMSSimulationItem->setStatus(tr("Simulation failed!"));
    }
  } else {
    LibraryTreeItem *pLibraryTreeItem;
    pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(mOMSSimulationOptions.getModelName());
    if (pLibraryTreeItem) {
      MainWindow::instance()->instantiateOMSModel(pLibraryTreeItem, false);
    }
    mpProgressLabel->setText(tr("Initialization using the <b>%1</b> model is failed. %2")
                             .arg(mOMSSimulationOptions.getModelName())
                             .arg(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER)));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mpArchivedOMSSimulationItem->setStatus(tr("Initialization failed!"));
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
 * \brief OMSSimulationOutputWidget::cancelSimulation
 * Slot activated when mpCancelSimulationButton clicked SIGNAL is raised.\n
 * Cancels the running simulation.
 */
void OMSSimulationOutputWidget::cancelSimulation()
{
  // cancel the simulation
  if (OMSProxy::instance()->cancelSimulation_asynchronous(mOMSSimulationOptions.getModelName())) {
    LibraryTreeItem *pLibraryTreeItem;
    pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(mOMSSimulationOptions.getModelName());
    if (pLibraryTreeItem) {
      MainWindow::instance()->instantiateOMSModel(pLibraryTreeItem, false);
    }
    mpProgressLabel->setText(tr("Simulation using the <b>%1</b> model is cancelled.").arg(mOMSSimulationOptions.getModelName()));
    mpProgressBar->setValue(mpProgressBar->maximum());
    mIsSimulationRunning = false;
    mpCancelSimulationButton->setEnabled(false);
  }
}

/*!
 * \brief OMSSimulationOutputWidget::simulationProgress
 * Slot activated when sendSimulationProgress SIGNAL is raised.\n
 * Updates the simulation progress.
 * \param ident
 * \param time
 * \param status
 */
void OMSSimulationOutputWidget::simulationProgress(QString ident, double time, oms_status_enu_t status)
{
  if (status < oms_status_warning) {
    int progress = (time * 100) / mOMSSimulationOptions.getStopTime();
    mpProgressBar->setValue(progress);
    if (time >= mOMSSimulationOptions.getStopTime()) {
      mpProgressLabel->setText(tr("Simulation using the <b>%1</b> model is finished.").arg(mOMSSimulationOptions.getModelName()));
      mpProgressBar->setValue(mpProgressBar->maximum());
      mIsSimulationRunning = false;
      mpCancelSimulationButton->setEnabled(false);
      mpArchivedOMSSimulationItem->setStatus(Helper::finished);
      // terminate the model after the simulation is finished successfully.
      LibraryTreeItem *pLibraryTreeItem;
      pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(ident);
      if (pLibraryTreeItem) {
        MainWindow::instance()->instantiateOMSModel(pLibraryTreeItem, false);
      }
      // simulation finished show the results
      MainWindow::instance()->getOMSSimulationDialog()->simulationFinished(mOMSSimulationOptions, mResultFileLastModifiedDateTime);
    }
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
