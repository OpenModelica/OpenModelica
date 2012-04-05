/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * RCS: $Id$
 */

#include <QMessageBox>

#include "ModelWidget.h"
#include "StringHandler.h"
#include "ProjectTabWidget.h"

ModelCreator::ModelCreator(MainWindow *parent)
  : QDialog(parent, Qt::WindowTitleHint)
{
  mpParentMainWindow = parent;
  setMinimumSize(375, 140);
  setModal(true);
  // Create the Text Box, File Dialog and Labels
  mpNameLabel = new QLabel;
  mpNameTextBox = new QLineEdit;
  mpParentPackageLabel = new QLabel(tr("Insert in Package (optional):"));
  mpParentPackageCombo = new QComboBox();
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(create()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create save contents of package in one file
  mpSaveOneFileCheckBox = new QCheckBox(tr("Save contents of package in one file"));
  // create buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpNameLabel, 0, 0);
  mainLayout->addWidget(mpNameTextBox, 1, 0);
  mainLayout->addWidget(mpParentPackageLabel, 2, 0);
  mainLayout->addWidget(mpParentPackageCombo, 3, 0);
  mainLayout->addWidget(mpSaveOneFileCheckBox, 4, 0);
  mainLayout->addWidget(mpButtonBox, 5, 0);
  setLayout(mainLayout);
}

void ModelCreator::show(int type)
{
  mType = type;
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Create New ")).append(StringHandler::getModelicaClassType(mType)));
  mpNameLabel->setText(StringHandler::getModelicaClassType(mType).append(" ").append(Helper::name));
  mpNameTextBox->setText("");
  mpNameTextBox->setFocus();
  mpParentPackageCombo->clear();
  mpParentPackageCombo->addItem("");
  mpParentPackageCombo->addItems(mpParentMainWindow->mpOMCProxy->createPackagesList());
  if (StringHandler::PACKAGE == mType)
    mpSaveOneFileCheckBox->setVisible(true);
  else
    mpSaveOneFileCheckBox->setVisible(false);
  setVisible(true);
}

void ModelCreator::create()
{
  if (mpNameTextBox->text().isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(StringHandler::getModelicaClassType(mType)), Helper::ok);
    return;
  }
  QString model, parentPackage, modelStructure;
  if (mpParentPackageCombo->currentText().isEmpty())
  {
    model = QString(mpNameTextBox->text());
    parentPackage = tr("in Global Scope");
  }
  else
  {
    model = QString(mpParentPackageCombo->currentText()).append(".").append(mpNameTextBox->text());
    parentPackage = tr("in Package '").append(mpParentPackageCombo->currentText()).append("'");
    modelStructure = QString(mpParentPackageCombo->currentText()).append(".");
  }

  // Check whether model exists or not.
  if (mpParentMainWindow->mpOMCProxy->existClass(model))
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).arg(StringHandler::getModelicaClassType(mType))
                          .arg(model).arg(parentPackage), Helper::ok);
    return;
  }
  // create the model.
  if (mpParentPackageCombo->currentText().isEmpty())
  {
    if (!mpParentMainWindow->mpOMCProxy->createClass(StringHandler::getModelicaClassType(mType).toLower(), mpNameTextBox->text()))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(mpParentMainWindow->mpOMCProxy->getResult())
                            .append("\n\n").append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  else
  {
    if(!mpParentMainWindow->mpOMCProxy->createSubClass(StringHandler::getModelicaClassType(mType).toLower(), mpNameTextBox->text(),
                                                       mpParentPackageCombo->currentText()))
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(mpParentMainWindow->mpOMCProxy->getResult())
                            .append("\n\n").append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  //open the new tab in central widget and add the model to tree.
  mpParentMainWindow->mpLibrary->addModelicaNode(mpNameTextBox->text(), mType, mpParentPackageCombo->currentText(), modelStructure);
  mpParentMainWindow->mpProjectTabs->addNewProjectTab(mpNameTextBox->text(), modelStructure, mType);
  mpParentMainWindow->switchToModelingView();
  accept();
}

//creates the copy of the model and adds a node in the modelica tree
//! param modelname is the name of the model being copied
void ModelCreator::createCopy(QString modelname)
{
  QString newname = StringHandler::removeLastWordAfterDot(modelname);
  if (modelname.isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(StringHandler::getModelicaClassType(mType)), Helper::ok);
    return;
  }
  QString model;
  int i=1;
  model = newname + QString::number(i);
  //naming the new model
  while(mpParentMainWindow->mpOMCProxy->existClass(model))
  {
    i=i+1;
    model = newname + QString::number(i) ;
  }
  QString listmodel = mpParentMainWindow->mpOMCProxy->list(modelname);
  //replacing the name of old model with model in the modelica text of new model
  listmodel = listmodel.replace("model " + modelname , "model " + model);
  listmodel = listmodel.replace("end " + modelname , "end " + model);
  mpParentMainWindow->mpLibrary->addModelicaNode(model, mpParentMainWindow->mpOMCProxy->getClassRestriction(modelname), "", "");
}

RenameClassWidget::RenameClassWidget(QString name, QString nameStructure, MainWindow *parent)
  : QDialog(parent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
  setAttribute(Qt::WA_DeleteOnClose);
  mpParentMainWindow = parent;

  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::rename).append(" ").append(name));
  setMinimumSize(300, 100);
  setModal(true);

  mpModelNameTextBox = new QLineEdit(name);
  mpModelNameLabel = new QLabel(tr("New Name:"));
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(renameClass()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpModelNameLabel, 0, 0);
  mainLayout->addWidget(mpModelNameTextBox, 1, 0);
  mainLayout->addWidget(mpButtonBox, 2, 0);
  setLayout(mainLayout);
}

RenameClassWidget::~RenameClassWidget()
{

}

void RenameClassWidget::renameClass()
{
  QString newName = mpModelNameTextBox->text().trimmed();
  QString newNameStructure;
  // if no change in the name then return
  if (newName == mName)
  {
    accept();
    return;
  }

  if (!mpParentMainWindow->mpOMCProxy->existClass(QString(StringHandler::removeLastWordAfterDot(mNameStructure)).append(".").append(newName)))
  {
    if (mpParentMainWindow->mpOMCProxy->renameClass(mNameStructure, newName))
    {
      newNameStructure = StringHandler::removeFirstLastCurlBrackets(mpParentMainWindow->mpOMCProxy->getResult());
      // Change the name in tree
      mpParentMainWindow->mpLibrary->updateNodeText(newName, newNameStructure);
      accept();
    }
    else
    {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).arg(mpParentMainWindow->mpOMCProxy->getResult())
                            .append("\n\n").append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
      return;
    }
  }
  else
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS)
                          .append("\n\n").append(GUIMessages::getMessage(GUIMessages::NO_OPENMODELICA_KEYWORDS)), Helper::ok);
    return;
  }
}

CheckModelWidget::CheckModelWidget(QString name, QString nameStructure, MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
  setAttribute(Qt::WA_DeleteOnClose);
  mpParentMainWindow = pParent;

  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::checkModel).append(" ").append(name));
  setMinimumSize(300, 100);
  setModal(true);

  mpCheckResultLabel = new QTextEdit;
  mpCheckResultLabel->setReadOnly(true);
  mpCheckResultLabel->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpCheckResultLabel->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpCheckResultLabel->setText(StringHandler::removeFirstLastQuotes(mpParentMainWindow->mpOMCProxy->checkModel(mNameStructure)));
  // Create the button
  mpOkButton = new QPushButton(Helper::ok);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(close()));
  // Create a layout
  QHBoxLayout *buttonLayout = new QHBoxLayout;
  buttonLayout->setAlignment(Qt::AlignCenter);
  buttonLayout->addWidget(mpOkButton);
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(mpCheckResultLabel);
  mainLayout->addLayout(buttonLayout);
  setLayout(mainLayout);
}

FlatModelWidget::FlatModelWidget(QString name, QString nameStructure, MainWindow *pParent)
  : QDialog(pParent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
  setAttribute(Qt::WA_DeleteOnClose);
  mpParentMainWindow = pParent;

  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::instantiateModel).append(" ").append(name));
  setMinimumSize(300, 100);
  setModal(true);

  mpText = new QTextEdit;
  mpText->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  mpText->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
  QString str = mpParentMainWindow->mpOMCProxy->instantiateModel(mNameStructure);
  ModelicaTextHighlighter *highlighter = new ModelicaTextHighlighter(pParent->mpOptionsWidget->mpModelicaTextSettings,mpText->document());
  mpText->setPlainText(str.length() ? str : tr("Instantiation of ") + name + tr(" failed"));
  // Create the button
  mpOkButton = new QPushButton(Helper::ok);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(close()));
  // Create a layout
  QHBoxLayout *buttonLayout = new QHBoxLayout;
  buttonLayout->setAlignment(Qt::AlignCenter);
  buttonLayout->addWidget(mpOkButton);
  QVBoxLayout *mainLayout = new QVBoxLayout;
  mainLayout->addWidget(mpText);
  mainLayout->addLayout(buttonLayout);
  setLayout(mainLayout);
}
