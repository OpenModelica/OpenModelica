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

IconProperties::IconProperties(Component *pComponent, QWidget *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Component Properties"));
    setAttribute(Qt::WA_DeleteOnClose);
    setMinimumSize(400, 300);
    setModal(true);
    mpComponent = pComponent;

    setUpDialog();
}

IconProperties::~IconProperties()
{

}

void IconProperties::setUpDialog()
{
    mpPropertiesHeading = new QLabel(tr("Properties"));
    mpPropertiesHeading->setFont(QFont("", Helper::headingFontSize));
    mpPropertiesHeading->setAlignment(Qt::AlignTop);

    mpPixmapLabel = new QLabel;
    mpPixmapLabel->setObjectName(tr("componentPixmap"));
    mpPixmapLabel->setMaximumSize(QSize(86, 86));
    mpPixmapLabel->setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);
    mpPixmapLabel->setAlignment(Qt::AlignCenter);

    ProjectTabWidget *pProjectTabs = mpComponent->mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget;
    LibraryComponent *libraryComponent;
    libraryComponent = pProjectTabs->mpParentMainWindow->mpLibrary->getLibraryComponentObject(mpComponent->getClassName());

    if (libraryComponent)
    {
        mpPixmapLabel->setPixmap(libraryComponent->getComponentPixmap(QSize(75, 75)));
    }

    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpPropertiesHeading);
    horizontalLayout->addWidget(mpPixmapLabel);

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
    gridComponentLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
    mpIconNameLabel = new QLabel(tr("Name:"));
    mpIconNameTextBox = new QLineEdit(mpComponent->getName());
    mpIconClassLabel = new QLabel(tr("Comment:"));
    mpIconClassTextBox = new QLabel(mpComponent->getClassName());
    //mpIconCommentTextBox->setText(mpIconAnnotation->getComment());
    gridComponentLayout->addWidget(mpIconNameLabel, 0, 0);
    gridComponentLayout->addWidget(mpIconNameTextBox, 0, 1);
    gridComponentLayout->addWidget(mpIconClassLabel, 1, 0);
    gridComponentLayout->addWidget(mpIconClassTextBox, 1, 1);
    mpComponentGroup->setLayout(gridComponentLayout);
    // set General Tab layout
    vGeneralTabLayout->addWidget(mpComponentGroup);
    mpGeneralTab->setLayout(vGeneralTabLayout);

    // add items to parameters tab
    QVBoxLayout *vParametersLayout = new QVBoxLayout;
    vParametersLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    QGridLayout *gridParametersLayout = new QGridLayout;
    gridParametersLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);

    for (int i = 0 ; i < mpComponent->mIconParametersList.size() ; i++)
    {
        IconParameters *iconParameter = mpComponent->mIconParametersList.at(i);

        QLabel *parameterLabel = new QLabel;
        parameterLabel->setText(iconParameter->getName());

        QLineEdit *parameterTextBox = new QLineEdit;
        parameterTextBox->setText(iconParameter->getValue().isEmpty() ?
                                  iconParameter->getDefaultValue() : iconParameter->getValue());
        mParameterTextBoxesList.append(parameterTextBox);

        if (mpComponent->mpOMCProxy->isProtected(iconParameter->getName(), mpComponent->getClassName()))
        {
            parameterLabel->setEnabled(false);
            parameterTextBox->setEnabled(false);
        }

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
    connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateIconProperties()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addLayout(horizontalLayout, 0, 0);
    mainLayout->addWidget(mHorizontalLine, 1, 0);
    mainLayout->addWidget(mpPropertiesTabWidget, 2, 0);
    mainLayout->addWidget(mpButtonBox, 3, 0);

    setLayout(mainLayout);
}

void IconProperties::updateIconProperties()
{
    QString iconName = mpIconNameTextBox->text().trimmed();
    ProjectTab *pProjectTab = mpComponent->mpGraphicsView->mpParentProjectTab;
    MainWindow *pMainWindow = pProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    bool valueChanged = false;

    // update the component name if it is changed
    if (mpComponent->getName() != iconName)
    {
        if (!mpComponent->mpGraphicsView->checkComponentName(iconName))
        {
            pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME));
        }
        else
        {
            if (mpComponent->mpOMCProxy->renameComponentInClass(pProjectTab->mModelNameStructure, mpComponent->getName(),
                                                                mpIconNameTextBox->text().trimmed()))
            {
                // if renameComponent command is successful update the component with new name
                mpComponent->updateName(mpIconNameTextBox->text().trimmed());
                valueChanged = true;
            }
            else
            {
                // if renameComponent command is unsuccessful print the error message
                pMainWindow->mpMessageWidget->printGUIErrorMessage(mpComponent->mpOMCProxy->getResult());
            }
        }
    }

    QString parameterOldValueString;
    QString parameterNewValueString;

    // update the parameter if it is changed
    for (int i = 0 ; i < mpComponent->mIconParametersList.size() ; i++)
    {
        // if the paramter value has changed only then update it
        if (mParameterTextBoxesList.at(i)->isModified())
        {
            IconParameters *iconParameter = mpComponent->mIconParametersList.at(i);
            mpComponent->mpOMCProxy->setComponentModifierValue(pProjectTab->mModelNameStructure, QString(mpComponent->getName()).append(".")
                                                               .append(iconParameter->getName()),
                                                               mParameterTextBoxesList.at(i)->text().trimmed());

            valueChanged = true;
            // update the gui text now
            parameterOldValueString = QString(iconParameter->getName()).append("=").append(iconParameter->getValue());
            parameterNewValueString = QString(iconParameter->getName()).append("=").append(mParameterTextBoxesList.at(i)->text().trimmed());
            mpComponent->updateParameterValue(parameterOldValueString, parameterNewValueString);
            iconParameter->setValue(mParameterTextBoxesList.at(i)->text().trimmed());
        }
    }
    if (valueChanged)
    {
        ProjectTab *pProjectTab = mpComponent->mpGraphicsView->mpParentProjectTab;
        ProjectTabWidget *pProjectTabs = mpComponent->mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget;
        pProjectTab->mpModelicaEditor->setPlainText(pProjectTabs->mpParentMainWindow->mpOMCProxy->list(pProjectTab->mModelNameStructure));
    }
    accept();
}

IconAttributes::IconAttributes(Component *pComponent, QWidget *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Component Attributes"));
    setAttribute(Qt::WA_DeleteOnClose);
    setMinimumSize(400, 350);
    setModal(true);
    mpComponent = pComponent;

    setUpDialog();
    initializeDialog();
}

void IconAttributes::setUpDialog()
{
    mpPropertiesHeading = new QLabel(tr("Attributes"));
    mpPropertiesHeading->setFont(QFont("", Helper::headingFontSize));
    mpPropertiesHeading->setAlignment(Qt::AlignTop);

    mpPixmapLabel = new QLabel;
    mpPixmapLabel->setObjectName(tr("componentPixmap"));
    mpPixmapLabel->setMaximumSize(QSize(86, 86));
    mpPixmapLabel->setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);
    mpPixmapLabel->setAlignment(Qt::AlignCenter);

    ProjectTabWidget *pProjectTabs = mpComponent->mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget;
    LibraryComponent *libraryComponent;
    libraryComponent = pProjectTabs->mpParentMainWindow->mpLibrary->getLibraryComponentObject(mpComponent->getClassName());

    if (libraryComponent)
    {
        mpPixmapLabel->setPixmap(libraryComponent->getComponentPixmap(QSize(75, 75)));
    }

    QHBoxLayout *horizontalLayout = new QHBoxLayout;
    horizontalLayout->addWidget(mpPropertiesHeading);
    horizontalLayout->addWidget(mpPixmapLabel);

    mHorizontalLine = new QFrame();
    mHorizontalLine->setFrameShape(QFrame::HLine);
    mHorizontalLine->setFrameShadow(QFrame::Sunken);

    // create Type Group Box
    mpTypeGroup = new QGroupBox(tr("Type"));
    QGridLayout *gridTypeLayout = new QGridLayout;
    mpNameLabel = new QLabel(tr("Name:"));
    mpNameTextBox = new QLabel(tr(""));
    mpCommentLabel = new QLabel(tr("Comment:"));
    mpCommentTextBox = new QLineEdit(tr(""));
    gridTypeLayout->addWidget(mpNameLabel, 0, 0);
    gridTypeLayout->addWidget(mpNameTextBox, 0, 1);
    gridTypeLayout->addWidget(mpCommentLabel, 1, 0);
    gridTypeLayout->addWidget(mpCommentTextBox, 1, 1);
    mpTypeGroup->setLayout(gridTypeLayout);

    // create Variablity Group Box
    mpVariabilityGroup = new QGroupBox(tr("Variability"));
    mpConstantRadio = new QRadioButton(tr("Constant"));
    mpParameterRadio = new QRadioButton(tr("Paramter"));
    mpDiscreteRadio = new QRadioButton(tr("Discrete"));
    mpDefaultRadio = new QRadioButton(tr("Unspecified (Default)"));
    QVBoxLayout *verticalVariabilityLayout = new QVBoxLayout;
    verticalVariabilityLayout->addWidget(mpConstantRadio);
    verticalVariabilityLayout->addWidget(mpParameterRadio);
    verticalVariabilityLayout->addWidget(mpDiscreteRadio);
    verticalVariabilityLayout->addWidget(mpDefaultRadio);
    mpVariabilityButtonGroup = new QButtonGroup;
    mpVariabilityButtonGroup->addButton(mpConstantRadio);
    mpVariabilityButtonGroup->addButton(mpParameterRadio);
    mpVariabilityButtonGroup->addButton(mpDiscreteRadio);
    mpVariabilityButtonGroup->addButton(mpDefaultRadio);
    mpVariabilityGroup->setLayout(verticalVariabilityLayout);

    // create Variablity Group Box
    mpPropertiesGroup = new QGroupBox(tr("Properties"));
    mpFinalCheckBox = new QCheckBox(tr("Final"));
    mpProtectedCheckBox = new QCheckBox(tr("Protected"));
    mpReplaceAbleCheckBox = new QCheckBox(tr("Replaceable"));
    QVBoxLayout *verticalPropertiesLayout = new QVBoxLayout;
    verticalPropertiesLayout->addWidget(mpFinalCheckBox);
    verticalPropertiesLayout->addWidget(mpProtectedCheckBox);
    verticalPropertiesLayout->addWidget(mpReplaceAbleCheckBox);
    mpPropertiesGroup->setLayout(verticalPropertiesLayout);

    // create Variablity Group Box
    mpCausalityGroup = new QGroupBox(tr("Causality"));
    mpInputRadio = new QRadioButton(tr("Input"));
    mpOutputRadio = new QRadioButton(tr("Output"));
    mpNoneRadio = new QRadioButton(tr("None"));
    QVBoxLayout *verticalCausalityLayout = new QVBoxLayout;
    verticalCausalityLayout->addWidget(mpInputRadio);
    verticalCausalityLayout->addWidget(mpOutputRadio);
    verticalCausalityLayout->addWidget(mpNoneRadio);
    mpCausalityButtonGroup = new QButtonGroup;
    mpCausalityButtonGroup->addButton(mpInputRadio);
    mpCausalityButtonGroup->addButton(mpOutputRadio);
    mpCausalityButtonGroup->addButton(mpNoneRadio);
    mpCausalityGroup->setLayout(verticalCausalityLayout);

    // create Variablity Group Box
    mpInnerOuterGroup = new QGroupBox(tr("Inner/Output"));
    mpInnerCheckBox = new QCheckBox(tr("Inner"));
    mpOuterCheckBox = new QCheckBox(tr("Outer"));
    QVBoxLayout *verticalInnerOuterLayout = new QVBoxLayout;
    verticalInnerOuterLayout->addWidget(mpInnerCheckBox);
    verticalInnerOuterLayout->addWidget(mpOuterCheckBox);
    mpInnerOuterGroup->setLayout(verticalInnerOuterLayout);

    // Create the buttons
    mpOkButton = new QPushButton(tr("OK"));
    mpOkButton->setAutoDefault(true);
    connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateIconAttributes()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    // Create a layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addLayout(horizontalLayout, 0, 0, 1, 2);
    mainLayout->addWidget(mHorizontalLine, 1, 0, 1, 2);
    mainLayout->addWidget(mpTypeGroup, 2, 0, 1, 2);
    mainLayout->addWidget(mpVariabilityGroup, 3, 0);
    mainLayout->addWidget(mpPropertiesGroup, 3, 1);
    mainLayout->addWidget(mpCausalityGroup, 4, 0);
    mainLayout->addWidget(mpInnerOuterGroup, 4, 1);
    mainLayout->addWidget(mpButtonBox, 5, 0, 1, 2);

    setLayout(mainLayout);
}

void IconAttributes::initializeDialog()
{
    QList<ComponentsProperties*> components = mpComponent->mpOMCProxy->getComponents(mpComponent->mpGraphicsView->mpParentProjectTab->mModelNameStructure);
    foreach (ComponentsProperties *componentProperties, components)
    {
        if (componentProperties->getName() == mpComponent->getName())
        {
            // get Class Name
            mpNameTextBox->setText(componentProperties->getClassName());
            // get Comment
            mpCommentTextBox->setText(componentProperties->getComment());

            // get Variability
            if (componentProperties->getVariablity() == "constant")
                mpConstantRadio->setChecked(true);
            else if (componentProperties->getVariablity() == "parameter")
                mpParameterRadio->setChecked(true);
            else if (componentProperties->getVariablity() == "discrete")
                mpDiscreteRadio->setChecked(true);
            else
                mpDefaultRadio->setChecked(true);

            // get Properties
            mpFinalCheckBox->setChecked(componentProperties->getFinal());
            mpProtectedCheckBox->setChecked(componentProperties->getProtected());
            mpReplaceAbleCheckBox->setChecked(componentProperties->getReplaceable());
            mIsFlow = componentProperties->getFlow() ? tr("true") : tr("false");

            // get Casuality
            if (componentProperties->getCasuality() == "input")
                mpInputRadio->setChecked(true);
            else if (componentProperties->getCasuality() == "output")
                mpOutputRadio->setChecked(true);
            else
                mpNoneRadio->setChecked(true);

            // get InnerOuter
            mpInnerCheckBox->setChecked(componentProperties->getInner());
            mpOuterCheckBox->setChecked(componentProperties->getOuter());

            break;
        }
    }
}

void IconAttributes::updateIconAttributes()
{
    ProjectTab *pCurrentTab = mpComponent->mpGraphicsView->mpParentProjectTab;
    QString modelName = pCurrentTab->mModelNameStructure;
    QString componentName = mpComponent->getName();
    QString isFinal = mpFinalCheckBox->isChecked() ? tr("true") : tr("false");
    QString isProtected = mpProtectedCheckBox->isChecked() ? tr("true") : tr("false");
    QString isReplaceAble = mpReplaceAbleCheckBox->isChecked() ? tr("true") : tr("false");
    QString variability;
    if (mpConstantRadio->isChecked())
        variability = tr("constant");
    else if (mpParameterRadio->isChecked())
        variability = tr("parameter");
    else if (mpDiscreteRadio->isChecked())
        variability = tr("discrete");
    else
        variability = tr("");
    QString isInner = mpInnerCheckBox->isChecked() ? tr("true") : tr("false");
    QString isOuter = mpOuterCheckBox->isChecked() ? tr("true") : tr("false");
    QString causality;
    if (mpInputRadio->isChecked())
        causality = tr("input");
    else if (mpOutputRadio->isChecked())
        causality = tr("output");
    else
        causality = tr("");

    OMCProxy *pOMCProxy = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
    MessageWidget *pMessageWidget = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpMessageWidget;
    // update component attributes
    if (!pOMCProxy->setComponentProperties(modelName, componentName, isFinal, mIsFlow, isProtected, isReplaceAble,
                                           variability, isInner, isOuter, causality))
    {
        pMessageWidget->printGUIErrorMessage(QString(GUIMessages::getMessage(GUIMessages::ATTRIBUTES_SAVE_ERROR))
                                             .arg(pOMCProxy->getErrorString()));
    }
    // update the component comment
    if (!pOMCProxy->setComponentComment(modelName, componentName, mpCommentTextBox->text().trimmed()))
    {
        pMessageWidget->printGUIErrorMessage(QString(GUIMessages::getMessage(GUIMessages::COMMENT_SAVE_ERROR))
                                             .arg(pOMCProxy->getErrorString()));
    }
    accept();
}
