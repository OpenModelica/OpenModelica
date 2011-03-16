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
 *
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
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(pressed()), SLOT(create()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpNameLabel, 0, 0);
    mainLayout->addWidget(mpNameTextBox, 1, 0);
    mainLayout->addWidget(mpParentPackageLabel, 2, 0);
    mainLayout->addWidget(mpParentPackageCombo, 3, 0);
    mainLayout->addWidget(mpButtonBox, 4, 0);

    setLayout(mainLayout);
}

ModelCreator::~ModelCreator()
{

}

void ModelCreator::show(int type)
{
    mType = type;
    setWindowTitle(QString(Helper::applicationName).append(" - Create New ")
                   .append(StringHandler::getModelicaClassType(mType)));
    mpNameLabel->setText(StringHandler::getModelicaClassType(mType).append(" Name:"));
    mpNameTextBox->setText(tr(""));
    mpNameTextBox->setFocus();
    mpParentPackageCombo->clear();
    mpParentPackageCombo->addItem(tr(""));
    mpParentPackageCombo->addItems(mpParentMainWindow->mpOMCProxy->createPackagesList());
    setVisible(true);
}

void ModelCreator::create()
{
    if (mpNameTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                              GUIMessages::getMessage(GUIMessages::ENTER_NAME).
                              arg(StringHandler::getModelicaClassType(mType)), tr("OK"));
        return;
    }
    QString model, parentPackage, modelStructure;
    if (mpParentPackageCombo->currentText().isEmpty())
    {
        model = QString(mpNameTextBox->text());
        parentPackage = QString("in Global Scope");
    }
    else
    {
        model = QString(mpParentPackageCombo->currentText()).append(".").append(mpNameTextBox->text());
        parentPackage = QString("in Package '").append(mpParentPackageCombo->currentText()).append("'");
        modelStructure = QString(mpParentPackageCombo->currentText()).append(".");
    }

    // Check whether model exists or not.
    if (mpParentMainWindow->mpOMCProxy->existClass(model))
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                              GUIMessages::getMessage(GUIMessages::MODEL_ALREADY_EXISTS).
                              arg(StringHandler::getModelicaClassType(mType)).arg(model).arg(parentPackage),
                              tr("OK"));
        return;
    }
    // create the model.
    if (mpParentPackageCombo->currentText().isEmpty())
    {
        if (!mpParentMainWindow->mpOMCProxy->createClass(StringHandler::getModelicaClassType(mType).toLower(),
                                                         mpNameTextBox->text()))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                 arg(mpParentMainWindow->mpOMCProxy->getResult()).append("\n\n").
                                 append(GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS)), tr("OK"));
            return;
        }
    }
    else
    {
        if(!mpParentMainWindow->mpOMCProxy->createSubClass(StringHandler::getModelicaClassType(mType).toLower(),
                                                           mpNameTextBox->text(),
                                                           mpParentPackageCombo->currentText()))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                  GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                  arg(mpParentMainWindow->mpOMCProxy->getResult()).append("\n\n").
                                  append(GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS)), tr("OK"));
            return;
        }
    }

    //open the new tab in central widget and add the model to tree.
    mpParentMainWindow->mpLibrary->addModelicaNode(mpNameTextBox->text(), mType,
                                                   mpParentPackageCombo->currentText(), modelStructure);
    mpParentMainWindow->mpProjectTabs->addNewProjectTab(mpNameTextBox->text(), modelStructure, mType);
    accept();
}

RenameClassWidget::RenameClassWidget(QString name, QString nameStructure, MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
    setAttribute(Qt::WA_DeleteOnClose);
    mpParentMainWindow = parent;

    this->setWindowTitle(QString(Helper::applicationName).append(" - Rename ").append(name));
    this->setMinimumSize(300, 100);
    this->setModal(true);

    this->mpModelNameTextBox = new QLineEdit(name);
    this->mpModelNameLabel = new QLabel(tr("New Name:"));
    // Create the buttons
    this->mpOkButton = new QPushButton(tr("Rename"));
    this->mpOkButton->setAutoDefault(true);
    connect(this->mpOkButton, SIGNAL(pressed()), this, SLOT(renameClass()));
    this->mpCancelButton = new QPushButton(tr("&Cancel"));
    this->mpCancelButton->setAutoDefault(false);
    connect(this->mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

    this->mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    this->mpButtonBox->addButton(this->mpOkButton, QDialogButtonBox::ActionRole);
    this->mpButtonBox->addButton(this->mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(this->mpModelNameLabel, 0, 0);
    mainLayout->addWidget(this->mpModelNameTextBox, 1, 0);
    mainLayout->addWidget(this->mpButtonBox, 2, 0);

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

    if (!mpParentMainWindow->mpOMCProxy->existClass(QString(StringHandler::removeLastWordAfterDot(mNameStructure))
                                                    .append(".").append(newName)))
    {
        if (mpParentMainWindow->mpOMCProxy->renameClass(mNameStructure, newName))
        {
            newNameStructure = StringHandler::removeFirstLastCurlBrackets(mpParentMainWindow->mpOMCProxy->getResult());
            // Change the name in tree
            mpParentMainWindow->mpLibrary->updateNodeText(newName, newNameStructure);
            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage("Renamed '"+mName+"' to '"+mpModelNameTextBox->text().trimmed()+"'");
            accept();
        }
        else
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                 arg(mpParentMainWindow->mpOMCProxy->getResult()).append("\n\n").
                                 append(GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS)),
                                 tr("OK"));
            return;
        }
    }
    else
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                             GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS).append("\n\n").
                             append(GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS)),
                             tr("OK"));
        return;
    }
}

CheckModelWidget::CheckModelWidget(QString name, QString nameStructure, MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
    setAttribute(Qt::WA_DeleteOnClose);
    mpParentMainWindow = pParent;

    setWindowTitle(QString(Helper::applicationName).append(" - Check Model - ").append(name));
    setMinimumSize(300, 100);
    setModal(true);

    mpCheckResultLabel = new QTextEdit(tr(""));
    mpCheckResultLabel->setReadOnly(true);
    mpCheckResultLabel->setText(StringHandler::removeFirstLastQuotes(
                                mpParentMainWindow->mpOMCProxy->checkModel(mNameStructure)));
    // Create the button
    mpOkButton = new QPushButton(tr("OK"));
    connect(mpOkButton, SIGNAL(pressed()), SLOT(close()));

    // Create a layout
    QHBoxLayout *buttonLayout = new QHBoxLayout;
    buttonLayout->setAlignment(Qt::AlignCenter);
    buttonLayout->addWidget(mpOkButton);

    QVBoxLayout *mainLayout = new QVBoxLayout;
    mainLayout->addWidget(mpCheckResultLabel);
    mainLayout->addLayout(buttonLayout);

    setLayout(mainLayout);
}
