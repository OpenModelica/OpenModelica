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

/*
NewProject::NewProject(MainWindow *parent)
    : QDialog(parent)
{
    this->mpParentMainWindow = parent;
    //Set the name and size of the main window
    this->setWindowTitle("Create New Project");
    this->setMaximumSize(375, 140);
    this->setMinimumSize(375, 140);
    this->setModal(true);

    // Create the Text Box, File Dialog and Labels
    this->mpNameTextBox = new QLineEdit(tr(""));
    this->mpPathTextBox = new QLineEdit(tr(""));
    this->mpPathTextBox->setEnabled(false);
    this->mpProjectNameLabel = new QLabel(tr("Project Name:"));
    this->mpProjectPathLabel = new QLabel(tr("Project Path:"));

    // Create the buttons
    this->mpBrowseButton = new QPushButton(tr("Browse"));
    connect(this->mpBrowseButton, SIGNAL(clicked()), this, SLOT(openFileDialog()));
    this->mpOkButton = new QPushButton(tr("OK"));
    this->mpOkButton->setAutoDefault(true);
    connect(this->mpOkButton, SIGNAL(pressed()), this, SLOT(createProject()));
    this->mpCancelButton = new QPushButton(tr("&Cancel"));
    this->mpCancelButton->setAutoDefault(false);
    connect(this->mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

    this->mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    this->mpButtonBox->addButton(this->mpOkButton, QDialogButtonBox::ActionRole);
    this->mpButtonBox->addButton(this->mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    mainLayout->addWidget(this->mpProjectNameLabel, 0, 0);
    mainLayout->addWidget(this->mpNameTextBox, 1, 0);
    mainLayout->addWidget(this->mpProjectPathLabel, 2, 0);
    mainLayout->addWidget(this->mpButtonBox, 4, 0);

    horizontalLayout->addWidget(this->mpPathTextBox);
    horizontalLayout->addWidget(this->mpBrowseButton);
    mainLayout->addLayout(horizontalLayout, 3, 0);

    setLayout(mainLayout);
}

NewProject::~NewProject()
{
    delete this->mpParentMainWindow;
    delete this->mpNameTextBox;
    delete this->mpPathTextBox;
    delete this->mpProjectNameLabel;
    delete this->mpProjectPathLabel;
    delete this->mpBrowseButton;
    delete this->mpOkButton;
    delete this->mpCancelButton;
    delete this->mpButtonBox;
}

void NewProject::createProject()
{
    if (this->mpNameTextBox->text().isEmpty())
    {
        QMessageBox::warning(this, Helper::applicationName, tr("Please enter Project Name"), tr("OK"));
        return;
    }
    else if (this->mpPathTextBox->text().isEmpty())
    {
        QMessageBox::warning(this, Helper::applicationName, tr("Please enter Project Path"), tr("OK"));
        return;
    }
    else
    {
        QDir directory;
        QString path(QString(this->mpPathTextBox->text() + tr("/") + this->mpNameTextBox->text()));
        if (!directory.exists(path))
        {
            if (directory.mkdir(path))
            {
                // if directory is created successfully. Change the OMC current directory.
                this->mpParentMainWindow->mpOMCProxy->changeDirectory(path);
                // Add the new created project to Library Widget Tree.
                this->mpParentMainWindow->mpLibrary->addModelNode(this->mpNameTextBox->text(), tr(""), tr(""));
                // Close the dialog.
                this->close();
            }
            else
            {
                QMessageBox::warning(this, Helper::applicationName
                                     , "Some error occurred while creating directory " + path + ".\n Please try with a different name or try in some other location."
                                     , tr("OK"));
                return;
            }
        }
        else
        {
            QMessageBox::warning(this, Helper::applicationName
                                 , "There is already exists one directory with the same name.\n Please try with a different name or try in some other location."
                                 , tr("OK"));
            return;
        }
    }
}

void NewProject::openFileDialog()
{
    QDir directory;
    this->mpPathTextBox->setText(QFileDialog::getExistingDirectory(this, tr("Choose Location"),
                                                      directory.currentPath() + tr("/ModelicaProjects"),
                                                      QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks));
}
*/

NewPackage::NewPackage(MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint)
{
    this->mpParentMainWindow = parent;
    //Set the name and size of the main window
    this->setWindowTitle(QString(Helper::applicationName).append(" - Create New Package"));
    this->setMinimumSize(375, 140);
    this->setModal(true);

    // Create the Text Box, File Dialog and Labels
    this->mpPackageNameTextBox = new QLineEdit(tr(""));
    this->mpPackageNameLabel = new QLabel(tr("Package Name:"));
    this->mpParentPackageLabel = new QLabel(tr("Insert in Package (optional):"));

    this->mpParentPackageCombo = new QComboBox();

    // Create the buttons
    this->mpOkButton = new QPushButton(tr("OK"));
    this->mpOkButton->setAutoDefault(true);
    connect(this->mpOkButton, SIGNAL(pressed()), this, SLOT(createPackage()));
    this->mpCancelButton = new QPushButton(tr("&Cancel"));
    this->mpCancelButton->setAutoDefault(false);
    connect(this->mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

    this->mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    this->mpButtonBox->addButton(this->mpOkButton, QDialogButtonBox::ActionRole);
    this->mpButtonBox->addButton(this->mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(this->mpPackageNameLabel, 0, 0);
    mainLayout->addWidget(this->mpPackageNameTextBox, 1, 0);
    mainLayout->addWidget(this->mpParentPackageLabel, 2, 0);
    mainLayout->addWidget(this->mpParentPackageCombo, 3, 0);
    mainLayout->addWidget(this->mpButtonBox, 4, 0);

    setLayout(mainLayout);
}

NewPackage::~NewPackage()
{

}

void NewPackage::show()
{
    this->mpParentPackageCombo->clear();
    this->mpParentPackageCombo->addItem(tr(""));
    this->mpParentPackageCombo->addItems(this->mpParentMainWindow->mpOMCProxy->createPackagesList());
    this->mpPackageNameTextBox->setText(tr(""));
    this->mpPackageNameTextBox->setFocus();
    this->setVisible(true);
}

void NewPackage::createPackage()
{
    if (this->mpPackageNameTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                             GUIMessages::getMessage(GUIMessages::ENTER_PACKAGE_NAME), tr("OK"));
        return;
    }
    QString package, parentPackage, packageStructure;
    if (this->mpParentPackageCombo->currentText().isEmpty())
    {
        package = QString(this->mpPackageNameTextBox->text());
        parentPackage = QString(" in Global Scope");
    }
    else
    {
        package = QString(this->mpParentPackageCombo->currentText()).append(".").append(this->mpPackageNameTextBox->text());
        parentPackage = QString(" in '").append(this->mpParentPackageCombo->currentText()).append("'");
        packageStructure = QString(this->mpParentPackageCombo->currentText()).append(".");
    }

    // Check whether package exists or not.
    if (this->mpParentMainWindow->mpOMCProxy->existClass(package))
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                             QString("Package '").append(package).append("' already exists").append(parentPackage),
                             tr("OK"));
        return;
    }
    // create the package.
    if (this->mpParentPackageCombo->currentText().isEmpty())
    {
        if(!mpParentMainWindow->mpOMCProxy->createClass("package", this->mpPackageNameTextBox->text()))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED) +
                                 "\n\n" + mpParentMainWindow->mpOMCProxy->getResult() +
                                 "\n\n" + GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS),
                                 tr("OK"));
            return;
        }
    }
    else
    {
        if(!mpParentMainWindow->mpOMCProxy->createSubClass("package", this->mpPackageNameTextBox->text(), this->mpParentPackageCombo->currentText()))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED) +
                                 "\n\n" + mpParentMainWindow->mpOMCProxy->getResult() +
                                 "\n\n" + GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS),
                                 tr("OK"));
            return;
        }
    }

    //Add the package to tree
    mpParentMainWindow->mpLibrary->addModelicaNode(this->mpPackageNameTextBox->text(), StringHandler::PACKAGE,
                                                this->mpParentPackageCombo->currentText(), packageStructure);
    accept();
}

NewModel::NewModel(MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint)
{
    this->mpParentMainWindow = parent;
    //Set the name and size of the main window
    this->setWindowTitle(QString(Helper::applicationName).append(" - Create New Model"));
    this->setMinimumSize(375, 140);
    this->setModal(true);

    // Create the Text Box, File Dialog and Labels
    this->mpModelNameTextBox = new QLineEdit(tr(""));
    this->mpModelNameLabel = new QLabel(tr("Model Name:"));
    this->mpParentPackageLabel = new QLabel(tr("Insert in Package (optional):"));

    this->mpParentPackageCombo = new QComboBox();

    // Create the buttons
    this->mpOkButton = new QPushButton(tr("OK"));
    this->mpOkButton->setAutoDefault(true);
    connect(this->mpOkButton, SIGNAL(pressed()), this, SLOT(createModel()));
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
    mainLayout->addWidget(this->mpParentPackageLabel, 2, 0);
    mainLayout->addWidget(this->mpParentPackageCombo, 3, 0);
    mainLayout->addWidget(this->mpButtonBox, 4, 0);

    setLayout(mainLayout);
}

NewModel::~NewModel()
{

}

void NewModel::show()
{
    this->mpParentPackageCombo->clear();
    this->mpParentPackageCombo->addItem(tr(""));
    this->mpParentPackageCombo->addItems(this->mpParentMainWindow->mpOMCProxy->createPackagesList());
    this->mpModelNameTextBox->setText(tr(""));
    this->mpModelNameTextBox->setFocus();
    this->setVisible(true);
}

void NewModel::createModel()
{
    if (this->mpModelNameTextBox->text().isEmpty())
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                              GUIMessages::getMessage(GUIMessages::ENTER_MODEL_NAME), tr("OK"));
        return;
    }
    QString model, parentPackage, modelStructure;
    if (this->mpParentPackageCombo->currentText().isEmpty())
    {
        model = QString(this->mpModelNameTextBox->text());
        parentPackage = QString(" in Global Scope");
    }
    else
    {
        model = QString(this->mpParentPackageCombo->currentText()).append(".").append(this->mpModelNameTextBox->text());
        parentPackage = QString(" in '").append(this->mpParentPackageCombo->currentText()).append("'");
        modelStructure = QString(this->mpParentPackageCombo->currentText()).append(".");
    }

    // Check whether model exists or not.
    if (this->mpParentMainWindow->mpOMCProxy->existClass(model))
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                             QString("Model '").append(model).append("' already exists").append(parentPackage),
                             tr("OK"));
        return;
    }
    // create the model.
    if (this->mpParentPackageCombo->currentText().isEmpty())
    {
        if (!mpParentMainWindow->mpOMCProxy->createClass("model", this->mpModelNameTextBox->text()))
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED) +
                                 "\n\n" + mpParentMainWindow->mpOMCProxy->getResult() +
                                 "\n\n" + GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS),
                                 tr("OK"));
            return;
        }
    }

    else
    {
        if(!mpParentMainWindow->mpOMCProxy->createSubClass("model", this->mpModelNameTextBox->text(), this->mpParentPackageCombo->currentText()))
        {
            if (!mpParentMainWindow->mpOMCProxy->createClass("model", this->mpModelNameTextBox->text()))
            {
                QMessageBox::critical(this, Helper::applicationName + " - Error",
                                     GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED) +
                                     "\n\n" + mpParentMainWindow->mpOMCProxy->getResult() +
                                     "\n\n" + GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS),
                                     tr("OK"));
                return;
            }
        }
    }

    //open the new tab in central widget and add the model to tree.
    mpParentMainWindow->mpLibrary->addModelicaNode(this->mpModelNameTextBox->text(), StringHandler::MODEL,
                                                this->mpParentPackageCombo->currentText(), modelStructure);
    mpParentMainWindow->mpProjectTabs->addNewProjectTab(this->mpModelNameTextBox->text(), modelStructure);
    accept();
}

RenameClassWidget::RenameClassWidget(QString name, QString nameStructure, MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint), mName(name), mNameStructure(nameStructure)
{
    setAttribute(Qt::WA_DeleteOnClose);
    mpParentMainWindow = parent;

    this->setWindowTitle(QString(Helper::applicationName).append(" - Rename ").append(name));
    this->setMaximumSize(300, 100);
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
    if (mpParentMainWindow->mpOMCProxy->renameClass(mNameStructure, newName))
    {
        // Find the Tab and rename it to new Name
        newNameStructure = StringHandler::removeFirstLastCurlBrackets(mpParentMainWindow->mpOMCProxy->getResult());
        ProjectTab *pCurrentTab = mpParentMainWindow->mpProjectTabs->getTabByName(mNameStructure);
        if (pCurrentTab)
        {
            pCurrentTab->updateTabName(newName, newNameStructure);
        }
        // Change the name in tree as well
        mpParentMainWindow->mpLibrary->updateNodeText(newName, newNameStructure);
        mpParentMainWindow->mpMessageWidget->printGUIInfoMessage("Renamed '"+mName+"' to '"+mpModelNameTextBox->text().trimmed()+"'");
        accept();
    }
    else
    {
        QMessageBox::critical(this, Helper::applicationName + " - Error",
                             GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED) +
                             "\n\n" + mpParentMainWindow->mpOMCProxy->getResult() +
                             "\n\n" + GUIMessages::getMessage(GUIMessages::NO_OPEN_MODELICA_KEYWORDS),
                             tr("OK"));
        return;
    }
}
