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

#include "IconProperties.h"

IconProperties::IconProperties(IconAnnotation *icon, QWidget *parent)
    : QDialog(parent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Component Properties"));
    setAttribute(Qt::WA_DeleteOnClose);
    setMinimumSize(400, 300);
    setModal(true);
    mpIconAnnotation = icon;

    setUpForm();
}

IconProperties::~IconProperties()
{

}

void IconProperties::setUpForm()
{
    mpPropertiesHeading = new QLabel(tr("Properties"));
    mpPropertiesHeading->setFont(QFont("", Helper::headingFontSize));

    mHorizontalLine = new QFrame();
    mHorizontalLine->setFrameShape(QFrame::HLine);
    mHorizontalLine->setFrameShadow(QFrame::Sunken);

    // Create the Tab Widget and add tabs to it
    mpPropertiesTabWidget = new QTabWidget;
    //mpPropertiesTabWidget->setCurrentIndex(0);
    mpGeneralTab = new QWidget(mpPropertiesTabWidget);
    mpPropertiesTabWidget->addTab(mpGeneralTab, tr("General"));
    mpParametersTab = new QWidget(mpPropertiesTabWidget);
    mpPropertiesTabWidget->addTab(mpParametersTab, tr("Parameters"));
    mpModeifiersTab = new QWidget(mpPropertiesTabWidget);
    mpPropertiesTabWidget->addTab(mpModeifiersTab, tr("Modifiers"));

    // add group boxes to General Tab
    QVBoxLayout *vGeneralTabLayout = new QVBoxLayout;
    // Create the Component Box
    mpComponentGroup = new QGroupBox(tr("Component"));
    QGridLayout *gridComponentLayout = new QGridLayout;
    mpIconNameLabel = new QLabel(tr("Name:"));
    mpIconNameTextBox = new QLineEdit(mpIconAnnotation->getName());
    mpIconCommentLabel = new QLabel(tr("Comment:"));
    mpIconCommentTextBox = new QLineEdit(mpIconAnnotation->getClassName());
    //mpIconCommentTextBox->setText(mpIconAnnotation->getComment());
    gridComponentLayout->addWidget(mpIconNameLabel, 0, 0);
    gridComponentLayout->addWidget(mpIconNameTextBox, 0, 1);
    gridComponentLayout->addWidget(mpIconCommentLabel, 1, 0);
    gridComponentLayout->addWidget(mpIconCommentTextBox, 1, 1);
    mpComponentGroup->setLayout(gridComponentLayout);
    // Create the Model Box
    mpModelGroup = new QGroupBox(tr("Model"));
    QGridLayout *gridModelLayout = new QGridLayout;
    mpIconModelNameLabel = new QLabel(tr("Name:"));
    mpIconModelNameTextBox = new QLabel;
    mpIconModelCommentLabel = new QLabel(tr("Comment:"));
    mpIconModelCommentTextBox = new QLabel;
    gridModelLayout->addWidget(mpIconModelNameLabel, 0, 0);
    gridModelLayout->addWidget(mpIconModelNameTextBox, 0, 1);
    gridModelLayout->addWidget(mpIconModelCommentLabel, 1, 0);
    gridModelLayout->addWidget(mpIconModelCommentTextBox, 1, 1);
    mpModelGroup->setLayout(gridModelLayout);
    // set General Tab layout
    vGeneralTabLayout->addWidget(mpComponentGroup);
    vGeneralTabLayout->addWidget(mpModelGroup);
    mpGeneralTab->setLayout(vGeneralTabLayout);

    // add items to parameters tab
    QVBoxLayout *vParametersLayout = new QVBoxLayout;
    vParametersLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    QGridLayout *gridParametersLayout = new QGridLayout;
    gridParametersLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    for (int i = 0 ; i < mpIconAnnotation->mpIconParametersList.size() ; i++)
    {
        IconParameters *iconParameter = mpIconAnnotation->mpIconParametersList.at(i);

        QLabel *parameterLabel = new QLabel;
        parameterLabel->setText(iconParameter->getName());

        QLineEdit *parameterTextBox = new QLineEdit;
        parameterTextBox->setText(iconParameter->getValue().isEmpty() ?
                                  iconParameter->getDefaultValue() : iconParameter->getValue());
        mParameterTextBoxesList.append(parameterTextBox);

        QLabel *parameterComment = new QLabel;
        parameterComment->setText(iconParameter->getComment());

        gridParametersLayout->addWidget(parameterLabel, i, 0);
        gridParametersLayout->addWidget(parameterTextBox, i, 1);
        gridParametersLayout->addWidget(parameterComment, i, 2);
    }
    vParametersLayout->addLayout(gridParametersLayout);
    mpParametersTab->setLayout(vParametersLayout);
    // add items to modifiers tab

    // Create the buttons
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(pressed()), this, SLOT(updateIconProperties()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpPropertiesHeading, 0, 0);
    mainLayout->addWidget(mHorizontalLine, 1, 0);
    mainLayout->addWidget(mpPropertiesTabWidget, 2, 0);
    mainLayout->addWidget(mpButtonBox, 3, 0);

    setLayout(mainLayout);
}

void IconProperties::updateIconProperties()
{
    QString iconName = mpIconNameTextBox->text().trimmed();
    ProjectTab *pProjectTab = mpIconAnnotation->mpGraphicsView->mpParentProjectTab;
    MainWindow *pMainWindow = pProjectTab->mpParentProjectTabWidget->mpParentMainWindow;

    // update the component name if it is changed
    if (mpIconAnnotation->getName() != iconName)
    {
        if (!mpIconAnnotation->mpGraphicsView->checkIconName(iconName))
        {
            pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(
                                                               GUIMessages::SAME_COMPONENT_NAME));
        }
        else
        {
            if (mpIconAnnotation->mpOMCProxy->renameComponent(pProjectTab->mModelNameStructure,
                                                              mpIconAnnotation->getName(),
                                                              mpIconNameTextBox->text().trimmed()))
            {
                // if renameComponent command is successful update the component with new name
                mpIconAnnotation->updateName(mpIconNameTextBox->text().trimmed());
            }
            else
            {
                // if renameComponent command is unsuccessful print the error message
                pMainWindow->mpMessageWidget->printGUIErrorMessage(mpIconAnnotation->mpOMCProxy->getResult());
            }
        }
    }

    QString parameterOldValueString;
    QString parameterNewValueString;

    // update the parameter if it is changed
    for (int i = 0 ; i < mpIconAnnotation->mpIconParametersList.size() ; i++)
    {
        IconParameters *iconParameter = mpIconAnnotation->mpIconParametersList.at(i);

        if (mParameterTextBoxesList.at(i)->text().isEmpty())
        {
            mpIconAnnotation->mpOMCProxy->setParameterValue(mpIconAnnotation->getClassName(),
                                                            iconParameter->getName(),
                                                            iconParameter->getDefaultValue());

            parameterOldValueString = QString(iconParameter->getName()).append("=").append(iconParameter->getValue());
            parameterNewValueString = QString(iconParameter->getName()).append("=").append(iconParameter->getDefaultValue());
            mpIconAnnotation->updateParameterValue(parameterOldValueString, parameterNewValueString);
            iconParameter->setValue(iconParameter->getDefaultValue());

        }
        else
        {
            mpIconAnnotation->mpOMCProxy->setParameterValue(mpIconAnnotation->getClassName(),
                                                            iconParameter->getName(),
                                                            mParameterTextBoxesList.at(i)->text().trimmed());

            parameterOldValueString = QString(iconParameter->getName()).append("=").append(iconParameter->getValue());
            parameterNewValueString = QString(iconParameter->getName()).append("=").append(mParameterTextBoxesList.at(i)->text().trimmed());
            mpIconAnnotation->updateParameterValue(parameterOldValueString, parameterNewValueString);
            iconParameter->setValue(mParameterTextBoxesList.at(i)->text().trimmed());
        }
    }
    accept();
}
