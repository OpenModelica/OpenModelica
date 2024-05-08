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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

#include <limits>

#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/MessagesWidget.h"
#include "Util/StringHandler.h"
#include "Modeling/ModelWidgetContainer.h"
// #include "Commands.h"
#include "Modeling/ItemDelegate.h"
#include "CRML/CRMLTranslateAsDialog.h"

#include <QApplication>
#include <QMessageBox>
#include <QCompleter>
#include <QHeaderView>

/*!
 * \class CRMLTranslateAsDialog
 * \brief Creates a dialog to allow users to create new Modelica class restriction.
 */
/*!
 * \brief CRMLTranslateAsDialog::CRMLTranslateAsDialog
 * \param pParent
 */
CRMLTranslateAsDialog::CRMLTranslateAsDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::translateAsCRML));
  setMinimumWidth(1000);
  // Create the output directory label
  mpOutputDirectoryLabel = new Label(tr("Select the output directory:"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpOutputDirectoryTextBox->setText(StringHandler::getLastOpenDirectory());
  mpOutputDirectoryBrowseButton = new QPushButton(Helper::browse);
  mpOutputDirectoryBrowseButton->setAutoDefault(false);
  connect(mpOutputDirectoryBrowseButton, SIGNAL(clicked()), SLOT(browseOutputDirectory()));

  // Create the parent package label, text box, browse button
  mpParentClassLabel = new Label(tr("Insert in class - within (optional):"));
  mpParentClassTextBox = new QLineEdit;
  mpParentClassBrowseButton = new QPushButton(Helper::browse);
  mpParentClassBrowseButton->setAutoDefault(false);
  connect(mpParentClassBrowseButton, SIGNAL(clicked()), SLOT(browseParentClass()));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(accept()));
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
  pMainLayout->addWidget(mpOutputDirectoryLabel, 1, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 1, 1);
  pMainLayout->addWidget(mpOutputDirectoryBrowseButton, 1, 2);
  pMainLayout->addWidget(mpParentClassLabel, 2, 0);
  pMainLayout->addWidget(mpParentClassTextBox, 2, 1);
  pMainLayout->addWidget(mpParentClassBrowseButton, 2, 2);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

void CRMLTranslateAsDialog::browseOutputDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append("Choose output directory"), NULL));
}


void CRMLTranslateAsDialog::browseParentClass()
{
  LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Parent Class"), mpParentClassTextBox,
                                                                      MainWindow::instance()->getLibraryWidget());
  pLibraryBrowseDialog->exec();
}

/*!
  Creates a new Modelica class restriction.\n
  Slot activated when mpOkButton clicked signal is raised.
  */
 /*
void CRMLTranslateAsDialog::createModelicaClass()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::ENTER_NAME).arg(mpSpecializationComboBox->currentText()), Helper::ok);
    return;
  }
  // if extends class doesn't exist.
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pExtendsLibraryTreeItem = 0;
  if (!mpExtendsClassTextBox->text().isEmpty()) {
    pExtendsLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpExtendsClassTextBox->text());
    if (!pExtendsLibraryTreeItem) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::EXTENDS_CLASS_NOT_FOUND).arg(mpExtendsClassTextBox->text()), Helper::ok);
      return;
    }
  }
  // if insert in class doesn't exist.
  LibraryTreeItem *pParentLibraryTreeItem = pLibraryTreeModel->getRootLibraryTreeItem();
  if (!mpParentClassTextBox->text().isEmpty()) {
    pParentLibraryTreeItem = pLibraryTreeModel->findLibraryTreeItem(mpParentClassTextBox->text());
    if (!pParentLibraryTreeItem) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::INSERT_IN_CLASS_NOT_FOUND).arg(mpParentClassTextBox->text()), Helper::ok);
      return;
    }
  }
  // if insert in class is system library.
  if (pParentLibraryTreeItem && pParentLibraryTreeItem->isSystemLibrary()) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INSERT_IN_SYSTEM_LIBRARY_NOT_ALLOWED)
                          .arg(mpParentClassTextBox->text()), Helper::ok);
    return;
  }
  QString model, parentPackage;
  if (mpParentClassTextBox->text().isEmpty()) {
    model = mpNameTextBox->text().trimmed();
    parentPackage = "Global Scope";
  } else {
    model = QString(mpParentClassTextBox->text().trimmed()).append(".").append(mpNameTextBox->text().trimmed());
    parentPackage = QString("Package '").append(mpParentClassTextBox->text().trimmed()).append("'");
  }
  // Check whether model exists or not.
  if (MainWindow::instance()->getOMCProxy()->existClass(model) || pLibraryTreeModel->findLibraryTreeItemOneLevel(model)) {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                            GUIMessages::MODEL_ALREADY_EXISTS).arg(mpSpecializationComboBox->currentText()).arg(model)
                          .arg(parentPackage), Helper::ok);
    return;
  }
  // create the model.
  QString modelicaClass = mpEncapsulatedCheckBox->isChecked() ? "encapsulated " : "";
  modelicaClass.append(mpPartialCheckBox->isChecked() ? "partial " : "");
  modelicaClass.append(mpSpecializationComboBox->currentText().toLower());
  if (mpParentClassTextBox->text().isEmpty()) {
    if (!MainWindow::instance()->getOMCProxy()->createClass(modelicaClass, mpNameTextBox->text().trimmed(), pExtendsLibraryTreeItem)) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getErrorString()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  } else {
    if (!MainWindow::instance()->getOMCProxy()->createSubClass(modelicaClass, mpNameTextBox->text().trimmed(), pParentLibraryTreeItem, pExtendsLibraryTreeItem)) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), GUIMessages::getMessage(
                              GUIMessages::ERROR_OCCURRED).arg(MainWindow::instance()->getOMCProxy()->getErrorString()).append("\n\n").
                            append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  // if state
  if (mpStateCheckBox->isChecked()) {
    QString nameStructure;
    if (pParentLibraryTreeItem->getNameStructure().isEmpty()) {
      nameStructure = mpNameTextBox->text().trimmed();
    } else {
      nameStructure = pParentLibraryTreeItem->getNameStructure() + "." + mpNameTextBox->text().trimmed();
    }
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=Icon(graphics={Text(extent={{-100,100},{100,-100}},textString=\"%name\")})");
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=__Dymola_state(true)");
    MainWindow::instance()->getOMCProxy()->addClassAnnotation(nameStructure, "annotate=singleInstance(true)");
  }
  // open the new tab in central widget and add the model to library tree.
  LibraryTreeItem *pLibraryTreeItem;
  pLibraryTreeItem = pLibraryTreeModel->createLibraryTreeItem(mpNameTextBox->text().trimmed(), pParentLibraryTreeItem, false, false, true);
  if (pParentLibraryTreeItem != pLibraryTreeModel->getRootLibraryTreeItem() && pParentLibraryTreeItem->getSaveContentsType() == LibraryTreeItem::SaveInOneFile) {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  } else if (mpSaveContentsInOneFileCheckBox->isChecked()) {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveInOneFile);
  } else {
    pLibraryTreeItem->setSaveContentsType(LibraryTreeItem::SaveFolderStructure);
  }
  pLibraryTreeModel->checkIfAnyNonExistingClassLoaded();
  pLibraryTreeItem->setExpanded(true);
  // show the ModelWidget
  pLibraryTreeModel->showModelWidget(pLibraryTreeItem, true);
  if (pLibraryTreeItem->getModelWidget()) {
    pLibraryTreeItem->getModelWidget()->updateModelText();
  }
  accept();
}
*/
