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
#include "ui_IconProperties.h"

IconProperties::IconProperties(IconAnnotation *icon, QWidget *parent)
    : QDialog(parent, Qt::WindowTitleHint), ui(new Ui::IconProperties)
{
    ui->setupUi(this);
    setWindowTitle(QString(Helper::applicationName).append(" - Component Properties"));
    setAttribute(Qt::WA_DeleteOnClose);
    mpIconAnnotation = icon;
    initializeFields();
}

IconProperties::~IconProperties()
{
    delete ui;
}

void IconProperties::initializeFields()
{
    ui->mpPropertiesTabWidget->setCurrentIndex(0);
    ui->mpIconNameTextBox->setText(mpIconAnnotation->getName());
    //ui->mpIconCommentTextBox->setText(mpIconAnnotation->getComment());

    ui->mpIconModelNameTextBox->setText(mpIconAnnotation->getClassName());
    //ui->mpIconModelNameTextBox->setText(mpIconAnnotation->getClassName());

    ui->mpParametersVerticalLayout->setAlignment(Qt::AlignTop);

    for (int i = 0 ; i < mpIconAnnotation->mpIconParametersList.size() ; i++)
    {
        IconParameters *iconParameter = mpIconAnnotation->mpIconParametersList.at(i);

        QLabel *parameterLabel = new QLabel;
        parameterLabel->setText(iconParameter->getName());

        QLineEdit *parameterTextBox = new QLineEdit;
        parameterTextBox->setText(iconParameter->getValue().isEmpty() ?
                                  iconParameter->getDefaultValue() : iconParameter->getValue());
        parameterTextBox->setMaximumWidth(100);
        mParameterTextBoxesList.append(parameterTextBox);

        QLabel *parameterComment = new QLabel;
        parameterComment->setText(mpIconAnnotation->mpComponentProperties->getComment());

        QHBoxLayout *horizontalLayout = new QHBoxLayout;
        horizontalLayout->addWidget(parameterLabel);
        horizontalLayout->addWidget(parameterTextBox);
        horizontalLayout->addWidget(parameterComment);

        ui->mpParametersVerticalLayout->addLayout(horizontalLayout);
    }
}

void IconProperties::updateIconProperties()
{
    QString iconName = ui->mpIconNameTextBox->text().trimmed();
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
                                                              ui->mpIconNameTextBox->text().trimmed()))
            {
                // if renameComponent command is successful update the component with new name
                mpIconAnnotation->updateName(ui->mpIconNameTextBox->text().trimmed());
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
