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

#include "OMSSimulationDialog.h"
#include "MainWindow.h"
#include "Util/Helper.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "OMSSimulationOutputWidget.h"
#include "Options/OptionsDialog.h"
#include "Plotting/VariablesWidget.h"

#include <QGridLayout>
#include <QMessageBox>
#include <QDesktopWidget>

/*!
 * \class OMSSimulationDialog
 * \brief Displays a dialog with simulation options for OMSimulator.
 */
/*!
 * \brief OMSSimulationDialog::OMSSimulationDialog
 * \param pParent
 */
OMSSimulationDialog::OMSSimulationDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::archivedSimulations));
  // heading
  mpSimulationHeading = Utilities::getHeadingLabel(Helper::archivedSimulations);
  mpSimulationHeading->setElideMode(Qt::ElideMiddle);
  // Horizontal separator
  mpHorizontalLine = Utilities::getHeadingLine();
  // archived simulation tree widget
  mpArchivedSimulationsTreeWidget = new QTreeWidget;
  mpArchivedSimulationsTreeWidget->setItemDelegate(new ItemDelegate(mpArchivedSimulationsTreeWidget));
  mpArchivedSimulationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpArchivedSimulationsTreeWidget->setColumnCount(4);
  QStringList headers;
  headers << tr("Model") << Helper::dateTime << Helper::startTime << Helper::stopTime << Helper::status;
  mpArchivedSimulationsTreeWidget->setHeaderLabels(headers);
  mpArchivedSimulationsTreeWidget->setIndentation(0);
  connect(mpArchivedSimulationsTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showArchivedSimulation(QTreeWidgetItem*)));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(accept()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // adds buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpSimulationHeading, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(mpArchivedSimulationsTreeWidget, 2, 0);
  pMainLayout->addWidget(mpButtonBox, 3, 0);
  setLayout(pMainLayout);
}

/*!
 * \brief OMSSimulationDialog::~OMSSimulationDialog
 * OMSSimulationDialog destructor.
 */
OMSSimulationDialog::~OMSSimulationDialog()
{
  foreach (OMSSimulationOutputWidget *pOMSSimulationOutputWidget, mOMSSimulationOutputWidgetsList) {
    delete pOMSSimulationOutputWidget;
  }
  mOMSSimulationOutputWidgetsList.clear();
}

/*!
 * \brief OMSSimulationDialog::simulationFinished
 * Called by OMSSimulationOutputWidget when the simulation is finished.\n
 * Reads the result file and plots the result.
 * \param omsSimulationOptions
 * \param resultFileLastModifiedDateTime
 */
void OMSSimulationDialog::simulationFinished(OMSSimulationOptions omsSimulationOptions, QDateTime resultFileLastModifiedDateTime)
{
  // read the result file
  QFileInfo resultFileInfo(omsSimulationOptions.getWorkingDirectory() + "/" + omsSimulationOptions.getResultFileName());
  if (resultFileInfo.exists() && resultFileLastModifiedDateTime <= resultFileInfo.lastModified()) {
    VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QStringList list = pOMCProxy->readSimulationResultVars(resultFileInfo.absoluteFilePath());
    if (list.size() > 0) {
      MainWindow::instance()->getPerspectiveTabBar()->setCurrentIndex(2);
      pVariablesWidget->insertVariablesItemsToTree(resultFileInfo.fileName(), omsSimulationOptions.getWorkingDirectory(),
                                                   list, SimulationOptions());
      MainWindow::instance()->getVariablesDockWidget()->show();
    }
  }
}

/*!
 * \brief OMSSimulationDialog::showArchivedSimulation
 * Slot activated when mpArchivedSimulationsListWidget itemDoubleClicked signal is raised.\n
 * Shows the archived OMSSimulationOutputWidget.
 * \param pTreeWidgetItem
 */
void OMSSimulationDialog::showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem)
{
  ArchivedOMSSimulationItem *pArchivedOMSSimulationItem = dynamic_cast<ArchivedOMSSimulationItem*>(pTreeWidgetItem);
  if (pArchivedOMSSimulationItem) {
    OMSSimulationOutputWidget *pSimulationOutputWidget = pArchivedOMSSimulationItem->getOMSSimulationOutputWidget();
    pSimulationOutputWidget->show();
    pSimulationOutputWidget->raise();
    pSimulationOutputWidget->setWindowState(pSimulationOutputWidget->windowState() & (~Qt::WindowMinimized));
  }
}

/*!
 * \brief OMSSimulationDialog::simulate
 * Simulates the OMSimulator model.
 * \param pLibraryTreeItem
 */
void OMSSimulationDialog::simulate(LibraryTreeItem *pLibraryTreeItem)
{
  OMSSimulationOutputWidget *pOMSSimulationOutputWidget = new OMSSimulationOutputWidget(pLibraryTreeItem->mOMSSimulationOptions);
  mOMSSimulationOutputWidgetsList.append(pOMSSimulationOutputWidget);
  int xPos = QApplication::desktop()->availableGeometry().width() - pOMSSimulationOutputWidget->frameSize().width() - 20;
  int yPos = QApplication::desktop()->availableGeometry().height() - pOMSSimulationOutputWidget->frameSize().height() - 20;
  pOMSSimulationOutputWidget->setGeometry(xPos, yPos, pOMSSimulationOutputWidget->width(), pOMSSimulationOutputWidget->height());
  pOMSSimulationOutputWidget->show();
}
