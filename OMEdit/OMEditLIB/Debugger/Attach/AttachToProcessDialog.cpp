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

#include "AttachToProcessDialog.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "Debugger/GDB/GDBAdapter.h"

#include <QHeaderView>
#include <QMessageBox>
#include <QGridLayout>

/*!
 * \class AttachToProcessDialog
 * \brief Provides interface for attaching a debugger to a running process.
 */
/*!
 * \param pParent
 */
AttachToProcessDialog::AttachToProcessDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::attachToRunningProcess));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(500, 400);
  // attach to process id
  mpAttachToProcessIDLabel = new Label(tr("Attach to Process ID:"));
  mpAttachToProcessIDTextBox = new QLineEdit;
  // filter
  mpFilterProcessesTextBox = new QLineEdit;
  mpFilterProcessesTextBox->setPlaceholderText(tr("Filter Processes"));
  // processes tree view model & proxy
  mpProcessListModel = new ProcessListModel;
  mProcessListFilterModel.setSourceModel(mpProcessListModel);
  mProcessListFilterModel.setFilterRegExp(mpFilterProcessesTextBox->text());
  // processes tree view
  mpProcessesTreeView = new QTreeView;
  mpProcessesTreeView->setItemDelegate(new ItemDelegate(mpProcessesTreeView));
  mpProcessesTreeView->setModel(&mProcessListFilterModel);
  mpProcessesTreeView->setTextElideMode(Qt::ElideMiddle);
  mpProcessesTreeView->setIndentation(0);
  mpProcessesTreeView->setSelectionBehavior(QAbstractItemView::SelectRows);
  mpProcessesTreeView->setSelectionMode(QAbstractItemView::SingleSelection);
  mpProcessesTreeView->setUniformRowHeights(true);
  //mpProcessesTreeView->setRootIsDecorated(false);
  mpProcessesTreeView->setSortingEnabled(true);
  mpProcessesTreeView->header()->setDefaultSectionSize(100);
  mpProcessesTreeView->header()->setStretchLastSection(true);
  mpProcessesTreeView->sortByColumn(1, Qt::AscendingOrder);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setEnabled(false);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(attachProcess()));
  mpRefreshButton = new QPushButton(Helper::refresh);
  connect(mpRefreshButton, SIGNAL(clicked()), SLOT(updateProcessList()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpRefreshButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

  connect(mpAttachToProcessIDTextBox, SIGNAL(textChanged(QString)), this, SLOT(processIDChanged(QString)));
  connect(mpFilterProcessesTextBox, SIGNAL(textChanged(QString)), this, SLOT(setFilterString(QString)));
  connect(mpProcessesTreeView, SIGNAL(doubleClicked(QModelIndex)), this, SLOT(processSelected(QModelIndex)));
  connect(mpProcessesTreeView, SIGNAL(clicked(QModelIndex)), this, SLOT(processClicked(QModelIndex)));
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpAttachToProcessIDLabel, 0, 0);
  pMainLayout->addWidget(mpAttachToProcessIDTextBox, 0, 1);
  pMainLayout->addWidget(mpFilterProcessesTextBox, 1, 0, 1 ,2);
  pMainLayout->addWidget(mpProcessesTreeView, 2, 0, 1 ,2);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
  // get the list of processes
  updateProcessList();
}

/*!
  Slot activated when mpOkButton clicked signal is raised.\n
  Starts GDB and try to attach it to the selected process.
  */
void AttachToProcessDialog::attachProcess()
{
  if (GDBAdapter::instance()->isGDBRunning()) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             GUIMessages::getMessage(GUIMessages::DEBUGGER_ALREADY_RUNNING), Helper::ok);
  } else {
    QString GDBPath = OptionsDialog::instance()->getDebuggerPage()->getGDBPath();
    GDBAdapter::instance()->launch(mpAttachToProcessIDTextBox->text(), GDBPath);
  }
  accept();
}

/*!
  Slot activated when mpRefreshButton clicked signal is raised.\n
  Updates/Refresh the list of processes.
  */
void AttachToProcessDialog::updateProcessList()
{
  mpProcessListModel->updateProcessList();
}

/*!
  Slot activated when mpAttachToProcessIDTextBox textChanged signal is raised.\n
  Notifies that user as changed the process id.
  */
void AttachToProcessDialog::processIDChanged(const QString &pid)
{
  const bool enabled = !pid.isEmpty() && pid != QLatin1String("0") && pid != QString::number(mpProcessListModel->getSelfProcessID());
  mpOkButton->setEnabled(enabled);
}

/*!
  Slot activated when mpFilterProcessesTextBox textChanged signal is raised.\n
  Sets the filter on processes.
  */
void AttachToProcessDialog::setFilterString(const QString &filter)
{
  mProcessListFilterModel.setFilterRegExp(filter);
  // Activate the line edit if there's a unique filtered process.
  QString processId;
  if (mProcessListFilterModel.rowCount(QModelIndex()) == 1)
  {
    QModelIndex index = mProcessListFilterModel.index(0, 0, QModelIndex());
    processId = mpProcessListModel->processIdAt(mProcessListFilterModel.mapToSource(index));
  }
  mpAttachToProcessIDTextBox->setText(processId);
  processIDChanged(processId);
}

/*!
  Slot activated when mpProcessesTreeView doubleClicked signal is raised.\n
  Selects the clicked process.
  */
void AttachToProcessDialog::processSelected(const QModelIndex &index)
{
  const QString processId = mpProcessListModel->processIdAt(mProcessListFilterModel.mapToSource(index));
  if (!processId.isEmpty()) {
    mpAttachToProcessIDTextBox->setText(processId);
    if (mpOkButton->isEnabled())
      mpOkButton->animateClick();
  }
}

/*!
  Slot activated when mpProcessesTreeView clicked signal is raised.\n
  Mark the clicked process selected.
  */
void AttachToProcessDialog::processClicked(const QModelIndex &index)
{
  const QString processId = mpProcessListModel->processIdAt(mProcessListFilterModel.mapToSource(index));
  if (!processId.isEmpty())
    mpAttachToProcessIDTextBox->setText(processId);
}

