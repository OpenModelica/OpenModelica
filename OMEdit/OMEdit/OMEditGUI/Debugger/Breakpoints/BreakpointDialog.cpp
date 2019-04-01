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

#include "BreakpointDialog.h"
#include "MainWindow.h"
#include "BreakpointsWidget.h"
#include "BreakpointMarker.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelicaClassDialog.h"
#include "Modeling/ModelWidgetContainer.h"

#include <limits>
#include <QMessageBox>
#include <QGridLayout>

/*!
 * \class BreakpointDialog
 * \brief Interface for adding and editing breakpoint.
 */
/*!
 * \brief BreakpointDialog::BreakpointDialog
 * \param pBreakpointTreeItem - pointer to BreakpointTreeItem
 * \param pBreakpointsTreeModel - pointer to BreakpointsTreeModel
 */
BreakpointDialog::BreakpointDialog(BreakpointTreeItem *pBreakpointTreeItem, BreakpointsTreeModel *pBreakpointsTreeModel)
  : QDialog(pBreakpointsTreeModel->getBreakpointsTreeView())
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("%1 Breakpoint").arg(pBreakpointTreeItem ? "Edit" : "Add")));

  mpBreakpointTreeItem = pBreakpointTreeItem;
  mpBreakpointsTreeModel = pBreakpointsTreeModel;
  // Create the file name label and text box
  mpFileNameLabel = new Label(tr("File Name:"));
  mpFileNameTextBox = new QLineEdit;
  if (mpBreakpointTreeItem && mpBreakpointTreeItem->getLibraryTreeItem()) {
    mpFileNameTextBox->setText(mpBreakpointTreeItem->getLibraryTreeItem()->getNameStructure());
  } else if (mpBreakpointTreeItem) {
    mpFileNameTextBox->setText(mpBreakpointTreeItem->getFilePath());
  }
  mpBrowseClassesButton = new QPushButton(tr("Browse Classes"));
  mpBrowseClassesButton->setAutoDefault(false);
  connect(mpBrowseClassesButton, SIGNAL(clicked()), SLOT(browseClasses()));
  mpBrowseFileSystemButton = new QPushButton(tr("File System"));
  mpBrowseFileSystemButton->setEnabled(false);
  mpBrowseFileSystemButton->setAutoDefault(false);
  connect(mpBrowseFileSystemButton, SIGNAL(clicked()), SLOT(browseFileSystem()));
  // Create the line number label and text box
  mpLineNumberLabel = new Label(tr("Line Number:"));
  mpLineNumberTextBox = new QLineEdit;
  // Create the enable label and check box
  mpEnableLabel = new Label(tr("Enabled:"));
  mpEnableCheckBox = new QCheckBox;
  // create ignore count label and spinbox
  mpIgnoreCountLabel = new Label(tr("Ignore Count:"));
  mpIgnoreCountSpinBox = new QSpinBox;
  mpIgnoreCountSpinBox->setRange(0, std::numeric_limits<int>::max());
  // create the condition label and text box
  mpConditionLabel = new Label(Helper::condition);
  mpConditionTextBox = new QLineEdit;
  mpConditionHintLabel = new Label(tr("* Use \"%1\" to set condition on simulation time.").arg("data->localData[0]->timeValue"));
  // if edit case then set the existing values
  if (mpBreakpointTreeItem) {
    mpLineNumberTextBox->setText(mpBreakpointTreeItem->getLineNumber());
    mpEnableCheckBox->setChecked(mpBreakpointTreeItem->isEnabled());
    mpIgnoreCountSpinBox->setValue(mpBreakpointTreeItem->getIgnoreCount());
    mpConditionTextBox->setText(mpBreakpointTreeItem->getCondition());
  } else {
    mpEnableCheckBox->setChecked(true);
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(addOrEditBreakpoint()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpFileNameLabel, 0, 0);
  pMainLayout->addWidget(mpFileNameTextBox, 0, 1);
  pMainLayout->addWidget(mpBrowseClassesButton, 0, 2);
  pMainLayout->addWidget(mpBrowseFileSystemButton, 0, 3);
  pMainLayout->addWidget(mpLineNumberLabel, 1, 0);
  pMainLayout->addWidget(mpLineNumberTextBox, 1, 1, 1, 3);
  pMainLayout->addWidget(mpEnableLabel, 2, 0);
  pMainLayout->addWidget(mpEnableCheckBox, 2, 1, 1, 3);
  pMainLayout->addWidget(mpIgnoreCountLabel, 3, 0);
  pMainLayout->addWidget(mpIgnoreCountSpinBox, 3, 1, 1, 3);
  pMainLayout->addWidget(mpConditionLabel, 4, 0);
  pMainLayout->addWidget(mpConditionTextBox, 4, 1, 1, 3);
  pMainLayout->addWidget(mpConditionHintLabel, 5, 0, 1, 4);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 4, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Slot activated when mpBrowseClassesButton clicked signal is raised.\n
  Shows the list of existing Modelica classes.
  */
void BreakpointDialog::browseClasses()
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Class"), mpFileNameTextBox, pMainWindow->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

/*!
  Slot activated when mpBrowseFileSystemButton clicked signal is raised.\n
  Opens the local file system.
  */
void BreakpointDialog::browseFileSystem()
{
  QString fileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                    NULL, Helper::omFileTypes, NULL);
  if (fileName.isEmpty())
    return;
  mpFileNameTextBox->setText(fileName);
}

/*!
  Slot activated when mpOkButton clicked signal is raised.\n
  Adds or edit the breakpoint.
  */
void BreakpointDialog::addOrEditBreakpoint()
{
  int lineNumber = mpLineNumberTextBox->text().toInt();
  BreakpointMarker *pBreakpointMarker;
  QFileInfo fileInfo(mpFileNameTextBox->text());
  if (fileInfo.exists()) {  /* if user has selected a file using Browse File System button. */
    if (!mpBreakpointTreeItem) {  /* Add Case */
      pBreakpointMarker = new BreakpointMarker(mpFileNameTextBox->text(), lineNumber, mpBreakpointsTreeModel);
      pBreakpointMarker->setEnabled(mpEnableCheckBox->isChecked());
      pBreakpointMarker->setIgnoreCount(mpIgnoreCountSpinBox->value());
      pBreakpointMarker->setCondition(mpConditionTextBox->text());
      mpBreakpointsTreeModel->insertBreakpoint(pBreakpointMarker, 0, mpBreakpointsTreeModel->getRootBreakpointTreeItem());
    } else {  /* Edit Case */
      /* find the BreakpointMarker and update its filepath and lineNumber. */
      pBreakpointMarker = mpBreakpointsTreeModel->findBreakpointMarker(mpBreakpointTreeItem->getFilePath(), mpBreakpointTreeItem->getLineNumber().toInt());
      pBreakpointMarker->setFilePath(mpFileNameTextBox->text());
      pBreakpointMarker->setLineNumber(lineNumber);
      pBreakpointMarker->setEnabled(mpEnableCheckBox->isChecked());
      pBreakpointMarker->setIgnoreCount(mpIgnoreCountSpinBox->value());
      pBreakpointMarker->setCondition(mpConditionTextBox->text());
      /* the breakpoint is file system breakpoint now so remove the mark from the previous editor and set LibraryTreeItem to 0. */
      if (mpBreakpointTreeItem->getLibraryTreeItem() && mpBreakpointTreeItem->getLibraryTreeItem()->getModelWidget()) {
        mpBreakpointTreeItem->getLibraryTreeItem()->getModelWidget()->getEditor()->getDocumentMarker()->removeMark(pBreakpointMarker);
      }
      mpBreakpointTreeItem->setLibraryTreeItem(0);
      /* update BreakpointTreeItem filePath and lineNumber. */
      mpBreakpointsTreeModel->updateBreakpoint(mpBreakpointTreeItem, mpFileNameTextBox->text(), lineNumber, mpEnableCheckBox->isChecked(),
                                               mpIgnoreCountSpinBox->value(), mpConditionTextBox->text());
    }
  } else {  /* if user has selected a class using Browse Classes button */
    LibraryWidget *pLibraryWidget = MainWindow::instance()->getLibraryWidget();
    LibraryTreeItem *pLibraryTreeItem = pLibraryWidget->getLibraryTreeModel()->findLibraryTreeItem(mpFileNameTextBox->text());
    if (pLibraryTreeItem) {
      if (!pLibraryTreeItem->isSaved()) {
        QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                              GUIMessages::getMessage(GUIMessages::BREAKPOINT_INSERT_NOT_SAVED).arg(pLibraryTreeItem->getNameStructure()),
                              Helper::ok);
        return;
      } else if (pLibraryTreeItem->getLibraryType() != LibraryTreeItem::Modelica) {
        QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                              GUIMessages::getMessage(GUIMessages::BREAKPOINT_INSERT_NOT_MODELICA_CLASS).arg(pLibraryTreeItem->getNameStructure()),
                              Helper::ok);
        return;
      } else if (!mpBreakpointTreeItem) { /* Add Case */
        pBreakpointMarker = new BreakpointMarker(pLibraryTreeItem->getFileName(), lineNumber, mpBreakpointsTreeModel);
        pBreakpointMarker->setEnabled(mpEnableCheckBox->isChecked());
        pBreakpointMarker->setIgnoreCount(mpIgnoreCountSpinBox->value());
        pBreakpointMarker->setCondition(mpConditionTextBox->text());
        mpBreakpointsTreeModel->insertBreakpoint(pBreakpointMarker, pLibraryTreeItem, mpBreakpointsTreeModel->getRootBreakpointTreeItem());
        if (pLibraryTreeItem->getModelWidget()) {
          pLibraryTreeItem->getModelWidget()->getEditor()->getDocumentMarker()->addMark(pBreakpointMarker, lineNumber);
        }
      } else {  /* Edit Case */
        /* find the BreakpointMarker and update its filepath and lineNumber. */
        pBreakpointMarker = mpBreakpointsTreeModel->findBreakpointMarker(mpBreakpointTreeItem->getFilePath(),
                                                                         mpBreakpointTreeItem->getLineNumber().toInt());
        // first remove the marker
        if (mpBreakpointTreeItem->getLibraryTreeItem()->getModelWidget() &&
            mpBreakpointTreeItem->getLibraryTreeItem()->getModelWidget()->getEditor()) {
          mpBreakpointTreeItem->getLibraryTreeItem()->getModelWidget()->getEditor()->getDocumentMarker()->removeMark(pBreakpointMarker);
        }
        // set new attributes for the breakpoint marker
        pBreakpointMarker->setFilePath(pLibraryTreeItem->getFileName());
        pBreakpointMarker->setLineNumber(lineNumber);
        pBreakpointMarker->setEnabled(mpEnableCheckBox->isChecked());
        pBreakpointMarker->setIgnoreCount(mpIgnoreCountSpinBox->value());
        pBreakpointMarker->setCondition(mpConditionTextBox->text());
        /* the breakpoint is not a file system breakpoint now so set LibraryTreeItem. */
        mpBreakpointTreeItem->setLibraryTreeItem(pLibraryTreeItem);
        /* update BreakpointTreeItem filePath and lineNumber. */
        mpBreakpointsTreeModel->updateBreakpoint(mpBreakpointTreeItem, pLibraryTreeItem->getFileName(), lineNumber,
                                                 mpEnableCheckBox->isChecked(), mpIgnoreCountSpinBox->value(), mpConditionTextBox->text());
        if (pLibraryTreeItem->getModelWidget()) {
          if (!pLibraryTreeItem->getModelWidget()->getEditor()) {
            pLibraryTreeItem->getModelWidget()->createModelWidgetComponents();
          }
          pLibraryTreeItem->getModelWidget()->getEditor()->getDocumentMarker()->addMark(pBreakpointMarker, lineNumber);
        }
      }
    } else {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::CLASS_NOT_FOUND).arg(mpFileNameTextBox->text()), Helper::ok);
      return;
    }
  }
  accept();
}
