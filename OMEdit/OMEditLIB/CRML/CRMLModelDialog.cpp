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

#include "CRMLModelDialog.h"
#include <Modeling/LibraryTreeWidget.h>
#include <Modeling/ModelWidgetContainer.h>
#include <Modeling/Commands.h>
#include <CRML/CRMLProxy.h>
#include <Options/OptionsDialog.h>

#include <QGridLayout>
#include <QMessageBox>

/*!
 * \class CreateCRMLModelDialog
 * \brief Creates a dialog to allow users to create a new OMSimulator model.
 */
/*!
 * \brief CreateCRMLModelDialog::CreateCRMLModelDialog
 * \param pParent
 */
CreateCRMLModelDialog::CreateCRMLModelDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName).arg(Helper::newCRMLModel));
  setMinimumWidth(400);
  // set heading
  mpHeading = Utilities::getHeadingLabel(Helper::newCRMLModel);
  // set separator line
  mpHorizontalLine = Utilities::getHeadingLine();
  // model name
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(createNewModel()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpNameLabel, 2, 0);
  pMainLayout->addWidget(mpNameTextBox, 2, 1);
  pMainLayout->addWidget(mpButtonBox, 4, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CreateCRMLModelDialog::createNewModel
 * Creates a new OMSimulator model.
 */
void CreateCRMLModelDialog::createNewModel()
{
  if (mpNameTextBox->text().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("Model")), Helper::ok);
    return;
  }

    // create new model
  if (CRMLProxy::instance()->newModel(mpNameTextBox->text())) {
    QString fileName = QString("%1.%2").arg(mpNameTextBox->text(),"crml");
    LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
    LibraryTreeItem *pLibraryTreeItem =
      pLibraryTreeModel->createLibraryTreeItem(LibraryTreeItem::CRML, fileName, "",
                                                                 fileName, true,
                                                                 pLibraryTreeModel->getRootLibraryTreeItem());
    if (pLibraryTreeItem) {
      pLibraryTreeModel->showModelWidget(pLibraryTreeItem);
      accept();
    } else {
      // if creating the CRML model failed then delete the model created.
      CRMLProxy::instance()->crmlDelete(fileName);
    }
  }
}

/*!
 * \class CRMLInformationDialog
 * \brief Creates a dialog that shows the users the result of OMCProxy::instantiateModel and OMCProxy::checkModel.
 */
/*!
 * \brief CRMLInformationDialog::CRMLInformationDialog
 * \param windowTitle - title string for dialog
 * \param informationText - main text string for dialog
 * \param modelicaTextHighlighter - highlights the modelica code.
 * \param pParent
 */
CRMLInformationDialog::CRMLInformationDialog(QString windowTitle, QString informationText, QWidget *pParent)
  : QWidget(pParent, Qt::Window)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(windowTitle));
  // instantiate the model
  mpTextEditor = new TextEditor(pParent);
  mpTextEditor->setPlainText(informationText);
  // Create the button
  QPushButton *pOkButton = new QPushButton(Helper::ok);
  pOkButton->setAutoDefault(true);
  connect(pOkButton, SIGNAL(clicked()), SLOT(close()));
  // set layout
  QHBoxLayout *buttonLayout = new QHBoxLayout;
  buttonLayout->setAlignment(Qt::AlignRight);
  buttonLayout->addWidget(pOkButton);
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(mpTextEditor);
  mainLayout->addLayout(buttonLayout);
  setLayout(mainLayout);
  pOkButton->setFocus();
  /* restore the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    QSettings *pSettings = Utilities::getApplicationSettings();
    restoreGeometry(pSettings->value("CRMLInformationDialog/geometry").toByteArray());
  }
}

/*!
 * \brief CRMLInformationDialog::closeEvent
 * Saves the widgets geometry.
 * \param event
 */
void CRMLInformationDialog::closeEvent(QCloseEvent *event)
{
  /* save the window geometry. */
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations()) {
    QSettings *pSettings = Utilities::getApplicationSettings();
    pSettings->setValue("CRMLInformationDialog/geometry", saveGeometry());
  }
  event->accept();
}

/*!
 * \brief CRMLInformationDialog::keyPressEvent
 * Closes the widget when Esc key is pressed.
 * \param event
 */
void CRMLInformationDialog::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    close();
    return;
  }
  QWidget::keyPressEvent(event);
}
