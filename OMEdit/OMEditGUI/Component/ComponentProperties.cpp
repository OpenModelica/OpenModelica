/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "ComponentProperties.h"
#include "Commands.h"

/*!
 * \class Parameter
 * \brief Defines one parameter. Creates name, value, unit and comment GUI controls.
 */
/*!
 * \brief Parameter::Parameter
 * \param pComponent
 * \param showStartAttribute
 * \param tab
 * \param groupBox
 */
Parameter::Parameter(Component *pComponent, bool showStartAttribute, QString tab, QString groupBox)
{
  mpComponent = pComponent;
  mTab = tab;
  mGroupBox = groupBox;
  mShowStartAttribute = showStartAttribute;
  mpNameLabel = new Label;
  mpFixedCheckBox = new FixedCheckBox;
  connect(mpFixedCheckBox, SIGNAL(clicked()), SLOT(showFixedMenu()));
  mOriginalFixedValue = "";
  // set the value type based on component type.
  OMCProxy *pOMCProxy = mpComponent->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  if (mpComponent->getComponentInfo()->getClassName().compare("Boolean") == 0) {
    mValueType = Parameter::Boolean;
  } else if (pOMCProxy->isBuiltinType(mpComponent->getComponentInfo()->getClassName())) {
    mValueType = Parameter::Normal;
  } else if (pOMCProxy->isWhat(StringHandler::Enumeration, mpComponent->getComponentInfo()->getClassName())) {
    mValueType = Parameter::Enumeration;
  } else {
    mValueType = Parameter::Normal;
  }
  createValueWidget();
  mpUnitLabel = new Label;
  mpCommentLabel = new Label;
  /* Get unit value
   * First check if unit is defined with in the component modifier.
   * If no unit is found then check it in the derived class modifier value.
   * A derived class can be inherited, so look recursively.
   */
  QString unit = pOMCProxy->getComponentModifierValue(mpComponent->getComponentInfo()->getClassName(),
                                                      QString(mpComponent->getName()).append(".unit"));
  if (unit.isEmpty()) {
    if (!pOMCProxy->isBuiltinType(mpComponent->getComponentInfo()->getClassName())) {
      unit = getUnitFromDerivedClass(mpComponent);
    }
  }
  mpUnitLabel = new Label(StringHandler::removeFirstLastQuotes(unit));
  mpCommentLabel = new Label(mpComponent->getComponentInfo()->getComment());
}

/*!
 * \brief Parameter::updateNameLabel
 * Updates the name label.
 */
void Parameter::updateNameLabel()
{
  mpNameLabel->setText(mpComponent->getName() + (mShowStartAttribute ? ".start" : ""));
}

void Parameter::setValueWidget(QString value, bool defaultValue)
{
  QFontMetrics fm = QFontMetrics(QFont());
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      if (defaultValue) {
        mpValueComboBox->lineEdit()->setPlaceholderText(value);
      } else {
        mpValueComboBox->lineEdit()->setText(value);
      }
      /* Set the minimum width so that the value text will be readable */
      fm = QFontMetrics(mpValueComboBox->lineEdit()->font());
      mpValueComboBox->setMinimumWidth(fm.width(value) + 50);
      break;
    case Parameter::Normal:
    default:
      if (defaultValue) {
        mpValueTextBox->setPlaceholderText(value);
      } else {
        mpValueTextBox->setText(value);
      }
      /* Set the minimum width so that the value text will be readable */
      fm = QFontMetrics(mpValueTextBox->font());
      mpValueTextBox->setMinimumWidth(fm.width(value) + 50);
      mpValueTextBox->setCursorPosition(0); /* move the cursor to start so that parameter value will show up from start instead of end. */
      break;
  }
}

QWidget* Parameter::getValueWidget()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      return mpValueComboBox;
    case Parameter::Normal:
    default:
      return mpValueTextBox;
  }
}

bool Parameter::isValueModified()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      return mpValueComboBox->lineEdit()->isModified();
    case Parameter::Normal:
    default:
      return mpValueTextBox->isModified();
  }
}

QString Parameter::getValue()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      return mpValueComboBox->lineEdit()->text().trimmed();
    case Parameter::Normal:
    default:
      return mpValueTextBox->text().trimmed();
  }
}

void Parameter::setFixedState(QString fixed, bool defaultValue)
{
  mOriginalFixedValue = fixed;
  if (fixed.compare("true") == 0) {
    mpFixedCheckBox->setTickState(defaultValue, true);
  } else {
    mpFixedCheckBox->setTickState(defaultValue, false);
  }
}

QString Parameter::getFixedState()
{
  return mpFixedCheckBox->tickStateString();
}

/*!
 * \brief Parameter::getUnitFromDerivedClass
 * Returns the unit value by reading the derived classes.
 * \param pComponent
 * \return the unit value.
 */
QString Parameter::getUnitFromDerivedClass(Component *pComponent)
{
  OMCProxy *pOMCProxy = pComponent->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  if (pComponent->getLibraryTreeItem()->getModelWidget()->getInheritedClassesList().size() == 0) {
    return pOMCProxy->getDerivedClassModifierValue(pComponent->getComponentInfo()->getClassName(), "unit");
  }
  foreach (Component *pInheritedComponent, pComponent->getInheritedComponentsList()) {
    if (pOMCProxy->isBuiltinType(pInheritedComponent->getComponentInfo()->getClassName())) {
      return pOMCProxy->getDerivedClassModifierValue(pInheritedComponent->getComponentInfo()->getClassName(), "unit");
    }
    return getUnitFromDerivedClass(pInheritedComponent);
  }
  return "";
}

/*!
  Sets the input field of the parameter enable/disable.
  \param enable
  */
void Parameter::setEnabled(bool enable)
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      mpValueComboBox->setEnabled(enable);
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox->setEnabled(enable);
      break;
  }
}

void Parameter::createValueWidget()
{
  int i;
  OMCProxy *pOMCProxy = mpComponent->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  QString className = mpComponent->getComponentInfo()->getClassName();
  QStringList enumerationLiterals;
  switch (mValueType) {
    case Parameter::Boolean:
      mpValueComboBox = new QComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->addItem("", "");
      mpValueComboBox->addItem("true", "true");
      mpValueComboBox->addItem("false", "false");
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;
    case Parameter::Enumeration:
      mpValueComboBox = new QComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->addItem("", "");
      enumerationLiterals = pOMCProxy->getEnumerationLiterals(className);
      for (i = 0 ; i < enumerationLiterals.size(); i++) {
        mpValueComboBox->addItem(enumerationLiterals[i], className + "." + enumerationLiterals[i]);
      }
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox = new QLineEdit;
      break;
  }
}

void Parameter::valueComboBoxChanged(int index)
{
  mpValueComboBox->lineEdit()->setText(mpValueComboBox->itemData(index).toString());
  mpValueComboBox->lineEdit()->setModified(true);
}

void Parameter::showFixedMenu()
{
  // create a menu
  QMenu menu;
  Label *pTitleLabel = new Label("Fixed");
  QWidgetAction *pTitleAction = new QWidgetAction(&menu);
  pTitleAction->setDefaultWidget(pTitleLabel);
  menu.addAction(pTitleAction);
  // fixed action group
  QActionGroup *pFixedActionGroup = new QActionGroup(this);
  pFixedActionGroup->setExclusive(false);
  // true case action
  QString trueText = tr("true: start-value is used to initialize");
  QAction *pTrueAction = new QAction(trueText, pFixedActionGroup);
  pTrueAction->setCheckable(true);
  connect(pTrueAction, SIGNAL(triggered()), SLOT(trueFixedClicked()));
  menu.addAction(pTrueAction);
  // false case action
  QString falseText = tr("false: start-value is only a guess-value");
  QAction *pFalseAction = new QAction(falseText, pFixedActionGroup);
  pFalseAction->setCheckable(true);
  connect(pFalseAction, SIGNAL(triggered()), SLOT(falseFixedClicked()));
  menu.addAction(pFalseAction);
  // inherited case action
  QString inheritedText = tr("inherited: (%1)").arg(mpFixedCheckBox->tickState() ? trueText : falseText);
  QAction *pInheritedAction = new QAction(inheritedText, pFixedActionGroup);
  pInheritedAction->setCheckable(true);
  connect(pInheritedAction, SIGNAL(triggered()), SLOT(inheritedFixedClicked()));
  menu.addAction(pInheritedAction);
  // set the menu actions states
  if (mpFixedCheckBox->tickStateString().compare("true") == 0) {
    pTrueAction->setChecked(true);
  } else if (mpFixedCheckBox->tickStateString().compare("false") == 0) {
    pFalseAction->setChecked(true);
  } else {
    pInheritedAction->setChecked(true);
  }
  // show the menu
  menu.exec(mpFixedCheckBox->mapToGlobal(QPoint(0, 0)));
}

void Parameter::trueFixedClicked()
{
  mpFixedCheckBox->setTickState(false, true);
}

void Parameter::falseFixedClicked()
{
  mpFixedCheckBox->setTickState(false, false);
}

void Parameter::inheritedFixedClicked()
{
  mpFixedCheckBox->setTickState(true, true);
}

/*!
  \class GroupBox
  \brief Creates a group for parameters.
  */
GroupBox::GroupBox(const QString &title, QWidget *parent)
  : QGroupBox(title, parent)
{
  mpGroupImageLabel = new Label;
  mpGridLayout = new QGridLayout;
  mpGridLayout->setObjectName(title);
  mpGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mpHorizontalLayout = new QHBoxLayout;
  mpHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mpHorizontalLayout->addLayout(mpGridLayout, 1);
  mpHorizontalLayout->addWidget(mpGroupImageLabel, 0, Qt::AlignRight);
  setLayout(mpHorizontalLayout);
}

/*!
  Sets the group image.
  \param groupImage - the absolute path of the image.
  */
void GroupBox::setGroupImage(QString groupImage)
{
  if (!mpGroupImageLabel->pixmap() || (mpGroupImageLabel->pixmap() && mpGroupImageLabel->pixmap()->isNull())) {
    QPixmap pixmap(groupImage);
    mpGroupImageLabel->setPixmap(pixmap);
  }
}

/*!
  \class ParametersScrollArea
  \brief Creates a scroll area for each tab of the component parameters dialog.
  */
ParametersScrollArea::ParametersScrollArea()
{
  mpWidget = new QWidget;
  setFrameShape(QFrame::NoFrame);
  setBackgroundRole(QPalette::Base);
  setWidgetResizable(true);
  mpVerticalLayout = new QVBoxLayout;
  mpVerticalLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  mpWidget->setLayout(mpVerticalLayout);
  setWidget(mpWidget);
}

/*!
 * Reimplementation of minimumSizeHint.
 * Finds maximum optimal size for ComponentParameters dialog. If the dialog is larger than screen then shows the scrollbars.
 */
QSize ParametersScrollArea::minimumSizeHint() const
{
  QSize size = QWidget::sizeHint();
  // find optimal width
  int screenWidth = QApplication::desktop()->availableGeometry().width() - 100;
  int widgetWidth = mpWidget->minimumSizeHint().width() + (verticalScrollBar()->isVisible() ? verticalScrollBar()->width() : 0);
  size.rwidth() = qMin(screenWidth, widgetWidth);
  // find optimal height
  int screenHeight = QApplication::desktop()->availableGeometry().height() - 300;
  int widgetHeight = mpWidget->minimumSizeHint().height() + (horizontalScrollBar()->isVisible() ? horizontalScrollBar()->height() : 0);
  size.rheight() = qMin(screenHeight, widgetHeight);
  return size;
}

/*!
  Adds a QGroupBox to the layout.
  \param pGroupBox - pointer to QGroupBox.
  \param pGroupBoxLayout - pointer to QGridLayout.
  */
void ParametersScrollArea::addGroupBox(GroupBox *pGroupBox)
{
  if (!getGroupBox(pGroupBox->title()))
  {
    pGroupBox->hide();  /* create a hidden groupbox, we show it when it contains the parameters. */
    mGroupBoxesList.append(pGroupBox);
    mpVerticalLayout->addWidget(pGroupBox);
  }
}

/*!
  Returns the GroupBox by reading the list of GroupBoxes.
  \return the GroupBox
  */
GroupBox* ParametersScrollArea::getGroupBox(QString title)
{
  foreach (GroupBox *pGroupBox, mGroupBoxesList)
  {
    if (pGroupBox->title().compare(title) == 0)
      return pGroupBox;
  }
  return 0;
}

/*!
  Returns the main layout of the widget.
  \return the QVBoxLayout
  */
QVBoxLayout *ParametersScrollArea::getLayout()
{
  return mpVerticalLayout;
}

/*!
 * \class ComponentParameters
 * \brief A dialog for displaying Component's parameters.
 */
/*!
 * \brief ComponentParameters::ComponentParameters
 * \param pComponent - pointer to Component
 * \param pMainWindow - pointer to MainWindow
 */
ComponentParameters::ComponentParameters(Component *pComponent, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Component Parameters")).arg(pComponent->getName())
                 .arg(className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
  mpMainWindow = pMainWindow;
  setUpDialog();
}

/*!
 * \brief ComponentParameters::~ComponentParameters
 * Deletes the list of Parameter objects.
 */
ComponentParameters::~ComponentParameters()
{
  qDeleteAll(mParametersList.begin(), mParametersList.end());
  mParametersList.clear();
}

/*!
  Creates the Dialog and set up all the controls with default values.
  */
void ComponentParameters::setUpDialog()
{
  // heading label
  mpParametersHeading = new Label(Helper::parameters);
  mpParametersHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpParametersHeading->setAlignment(Qt::AlignTop);
  // set seperator line
  mHorizontalLine = new QFrame();
  mHorizontalLine->setFrameShape(QFrame::HLine);
  mHorizontalLine->setFrameShadow(QFrame::Sunken);
  // parameters tab widget
  mpParametersTabWidget = new QTabWidget;
  // Component Group Box
  mpComponentGroupBox = new QGroupBox(tr("Component"));
  // Component name
  mpComponentNameLabel = new Label(Helper::name);
  mpComponentNameTextBox = new Label(mpComponent->getName());
  // Component class name
  mpComponentClassNameLabel = new Label(Helper::path);
  mpComponentClassNameTextBox = new Label(mpComponent->getComponentInfo()->getClassName());
  QGridLayout *pComponentGroupBoxLayout = new QGridLayout;
  pComponentGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentGroupBoxLayout->addWidget(mpComponentNameLabel, 0, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentNameTextBox, 0, 1);
  pComponentGroupBoxLayout->addWidget(mpComponentClassNameLabel, 1, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentClassNameTextBox, 1, 1);
  mpComponentGroupBox->setLayout(pComponentGroupBoxLayout);
  // Create General tab and Parameters GroupBox
  ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
  // first add the Component Group Box
  pParametersScrollArea->getLayout()->addWidget(mpComponentGroupBox);
  GroupBox *pGroupBox = new GroupBox("Parameters");
  pParametersScrollArea->addGroupBox(pGroupBox);
  mTabsMap.insert("General", mpParametersTabWidget->addTab(pParametersScrollArea, "General"));
  // create parameters tabs and groupboxes
  createTabsGroupBoxesAndParameters(mpComponent->getLibraryTreeItem());
  fetchComponentModifiers();
  foreach (Parameter *pParameter, mParametersList) {
    ParametersScrollArea *pParametersScrollArea;
    pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
    if (pParametersScrollArea) {
      GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(pParameter->getGroupBox());
      if (pGroupBox) {
        /* We hide the groupbox when we create it. Show the groupbox now since it has a parameter. */
        pGroupBox->show();
        QGridLayout *pGroupBoxGridLayout = pGroupBox->getGridLayout();
        int layoutIndex = pGroupBoxGridLayout->rowCount();
        int columnIndex = 0;
        pParameter->updateNameLabel();
        pGroupBoxGridLayout->addWidget(pParameter->getNameLabel(), layoutIndex, columnIndex++);
        if (pParameter->isShowStartAttribute()) {
          pGroupBoxGridLayout->addWidget(pParameter->getFixedCheckBox(), layoutIndex, columnIndex++);
        } else {
          pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
        }
        pGroupBoxGridLayout->addWidget(pParameter->getValueWidget(), layoutIndex, columnIndex++);
        pGroupBoxGridLayout->addWidget(pParameter->getUnitLabel(), layoutIndex, columnIndex++);
        pGroupBoxGridLayout->addWidget(pParameter->getCommentLabel(), layoutIndex, columnIndex++);
      }
    }
  }
  // create Modifiers tab
  QWidget *pModifiersTab = new QWidget;
  // add items to modifiers tab
  mpModifiersLabel = new Label(tr("Add new modifiers, e.g phi(start=1),w(start=2)"));
  mpModifiersTextBox = new QLineEdit;
  QVBoxLayout *pModifiersTabLayout = new QVBoxLayout;
  pModifiersTabLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pModifiersTabLayout->addWidget(mpModifiersLabel);
  pModifiersTabLayout->addWidget(mpModifiersTextBox);
  pModifiersTab->setLayout(pModifiersTabLayout);
  mpParametersTabWidget->addTab(pModifiersTab, "Modifiers");
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateComponentParameters()));
  if (mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary()) {
    mpOkButton->setDisabled(true);
  }
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpParametersHeading);
  pMainLayout->addWidget(mHorizontalLine);
  pMainLayout->addWidget(mpParametersTabWidget);
  pMainLayout->addWidget(mpButtonBox);
  setLayout(pMainLayout);
}

/*!
 * \brief ComponentParameters::createTabsGroupBoxesAndParameters
 * Loops over the inherited classes of the Component.
 * \param pLibraryTreeItem
 * \see ComponentParameters::createTabsGroupBoxesAndParametersHelper()
 */
void ComponentParameters::createTabsGroupBoxesAndParameters(LibraryTreeItem *pLibraryTreeItem)
{
  foreach (ModelWidget::InheritedClass *pInheritedClass, pLibraryTreeItem->getModelWidget()->getInheritedClassesList()) {
    createTabsGroupBoxesAndParametersHelper(pInheritedClass->mpLibraryTreeItem);
  }
  /* We append the actual Components parameters first so that they appear first on the list.
   * For that we use QList insert instead of append in ComponentParameters::createTabsGroupBoxesAndParametersHelper() function.
   * Modelica.Electrical.Analog.Basic.Resistor order is wrong if we don't use insert.
   */
  createTabsGroupBoxesAndParametersHelper(pLibraryTreeItem, true);
}

/*!
 * \brief ComponentParameters::createTabsGroupBoxesAndParametersHelper
 * Creates the dynamic tabs for QTabWidget and QGroupBoxes within them.
 * Creats the parameters and adds them to the appropriate tab and groupbox.
 * \param pLibraryTreeItem
 * \param useInsert - if true we use QList insert instead of append.
 * \see ComponentParameters::createTabsGroupBoxesAndParameters()
 */
void ComponentParameters::createTabsGroupBoxesAndParametersHelper(LibraryTreeItem *pLibraryTreeItem, bool useInsert)
{
  OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
  foreach (LibraryTreeItem *pInheritedLibraryTreeItem, pLibraryTreeItem->getInheritedClasses()) {
    QStringList extendsModifiers = pOMCProxy->getExtendsModifierNames(pLibraryTreeItem->getNameStructure(),
                                                                      pInheritedLibraryTreeItem->getNameStructure());
    foreach (QString extendsModifier, extendsModifiers) {
      QString parameterName = StringHandler::getFirstWordBeforeDot(extendsModifier);
      /* Ticket #2531
       * Check if parameter is marked final in the extends modifier.
       */
      if (pOMCProxy->isExtendsModifierFinal(pLibraryTreeItem->getNameStructure(), pInheritedLibraryTreeItem->getNameStructure(), parameterName)) {
        Parameter *pParameter = findParameter(parameterName);
        if (pParameter) {
          mParametersList.removeOne(pParameter);
          delete pParameter;
        }
      } else {
        Parameter *pParameter = findParameter(parameterName);
        if (pParameter) {
          QString start = pOMCProxy->getExtendsModifierValue(pLibraryTreeItem->getNameStructure(),
                                                             pInheritedLibraryTreeItem->getNameStructure(), parameterName + ".start");
          QString fixed = pOMCProxy->getExtendsModifierValue(pLibraryTreeItem->getNameStructure(),
                                                             pInheritedLibraryTreeItem->getNameStructure(), parameterName + ".fixed");
          if (!start.isEmpty() || !fixed.isEmpty()) {
            pParameter->setGroupBox("Initialization");
            pParameter->setShowStartAttribute(true);
            pParameter->setValueWidget(start, true);
            pParameter->setFixedState(fixed, true);
          } else {
            QString value = pOMCProxy->getExtendsModifierValue(pLibraryTreeItem->getNameStructure(),
                                                               pInheritedLibraryTreeItem->getNameStructure(), extendsModifier);
            pParameter->setValueWidget(value, true);
          }
        }
      }
    }
  }
  int insertIndex = 0;
  foreach (Component *pComponent, pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
    /* Ticket #2531
     * Do not show the protected & final parameters.
     */
    if (pComponent->getComponentInfo()->getProtected() || pComponent->getComponentInfo()->getFinal()) {
      continue;
    }
    /* I didn't find anything useful in the specification regarding this issue.
     * The parameters dialog is only suppose to show the parameters. However, Dymola also shows the variables in the parameters window
     * which have the dialog annotation with them. So, if the variable has dialog annotation or it is a parameter then show it.
     * If the variable have start/fixed attribute set then show it also.
     */
    QString tab = QString("General");
    QString groupBox = "";
    bool enable = true;
    bool showStartAttribute = false;
    QString start, fixed = "";
    bool isParameter = (pComponent->getComponentInfo()->getVariablity().compare("parameter") == 0);
    // If not a parameter then check for start and fixed bindings. See Modelica.Electrical.Analog.Basic.Resistor parameter R.
    if (!isParameter) {
      start = pOMCProxy->getComponentModifierValue(pLibraryTreeItem->getNameStructure(), pComponent->getName() + ".start");
      fixed = pOMCProxy->getComponentModifierValue(pLibraryTreeItem->getNameStructure(), pComponent->getName() + ".fixed");
      showStartAttribute = (!start.isEmpty() || !fixed.isEmpty()) ? true : false;
    }
    /* get the dialog annotation */
    QStringList dialogAnnotation = pComponent->getDialogAnnotation();
    QString groupImage = "";
    if (isParameter || (dialogAnnotation.size() > 0) || showStartAttribute) {
      if (dialogAnnotation.size() > 0) {
        // get the tab value
        tab = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(0));
        // get the group value
        groupBox = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(1));
        // get the enable value
        enable = (dialogAnnotation.at(2).compare("true") == 0);
        // get the showStartAttribute value
        if (dialogAnnotation.at(3).compare("-") != 0) {
          showStartAttribute = (dialogAnnotation.at(3).compare("true") == 0);
        }
        // get the group image
        groupImage = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(9));
        groupImage = mpMainWindow->getOMCProxy()->uriToFilename(groupImage);
      }
      // if showStartAttribute true and group name is empty or Parameters then we should make group name Initialization
      if (showStartAttribute && groupBox.isEmpty()) {
        groupBox = "Initialization";
      } else if (groupBox.isEmpty()) {
        groupBox = "Parameters";
      }
      if (!mTabsMap.contains(tab)) {
        ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
        GroupBox *pGroupBox = new GroupBox(groupBox);
        // set the group image
        pGroupBox->setGroupImage(groupImage);
        pParametersScrollArea->addGroupBox(pGroupBox);
        mTabsMap.insert(tab, mpParametersTabWidget->addTab(pParametersScrollArea, tab));
      } else {
        ParametersScrollArea *pParametersScrollArea;
        pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(tab)));
        if (pParametersScrollArea && !pParametersScrollArea->getGroupBox(groupBox)) {
          GroupBox *pGroupBox = new GroupBox(groupBox);
          // set the group image
          pGroupBox->setGroupImage(groupImage);
          pParametersScrollArea->addGroupBox(pGroupBox);
        }
      }
      // create the Parameter
      Parameter *pParameter = new Parameter(pComponent, showStartAttribute, tab, groupBox);
      pParameter->setEnabled(enable);
      QString componentDefinedInClass = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      QString value = pOMCProxy->getParameterValue(componentDefinedInClass, pComponent->getName());
      pParameter->setValueWidget(value, true);
      if (showStartAttribute) {
        pParameter->setValueWidget(start, true);
        pParameter->setFixedState(fixed, true);
      }
      if (useInsert) {
        mParametersList.insert(insertIndex, pParameter);
      } else {
        mParametersList.append(pParameter);
      }
      insertIndex++;
    }
  }
}

/*!
 * \brief ComponentParameters::fetchComponentModifiers
 * Fetches the Component's modifiers and apply modifier values on the approriate Parameters.
 */
void ComponentParameters::fetchComponentModifiers()
{
  OMCProxy *pOMCProxy = mpMainWindow->getOMCProxy();
  QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QStringList modifiers = pOMCProxy->getComponentModifierNames(className, mpComponent->getName());
  foreach (QString modifier, modifiers) {
    QString parameterName = StringHandler::getFirstWordBeforeDot(modifier);
    Parameter *pParameter = findParameter(parameterName);
    if (pParameter) {
      QString start = pOMCProxy->getComponentModifierValue(className, mpComponent->getName() + "." + parameterName + ".start");
      QString fixed = pOMCProxy->getComponentModifierValue(className, mpComponent->getName() + "." + parameterName + ".fixed");
      if (!start.isEmpty() || !fixed.isEmpty()) {
        pParameter->setGroupBox("Initialization");
        pParameter->setShowStartAttribute(true);
        pParameter->setValueWidget(start, false);
        pParameter->setFixedState(fixed, false);
      } else {
        QString value = pOMCProxy->getComponentModifierValue(className, mpComponent->getName() + "." + modifier);
        pParameter->setValueWidget(value, false);
      }
    }
  }
}

/*!
 * \brief ComponentParameters::findParameter
 * Finds the Parameter.
 * \param pLibraryTreeItem
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ComponentParameters::findParameter(LibraryTreeItem *pLibraryTreeItem, const QString &parameter,
                                              Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if ((pParameter->getComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem() == pLibraryTreeItem) &&
        (pParameter->getComponent()->getName().compare(parameter, caseSensitivity) == 0)) {
      return pParameter;
    }
  }
  return 0;
}

/*!
 * \brief ComponentParameters::findParameter
 * Finds the Parameter.
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ComponentParameters::findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if (pParameter->getComponent()->getName().compare(parameter, caseSensitivity) == 0) {
      return pParameter;
    }
  }
  return 0;
}

/*!
 * \brief ComponentParameters::updateComponentParameters
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Checks the list of parameters i.e mParametersList and if the value is changed then sets the new value.
 */
void ComponentParameters::updateComponentParameters()
{
  bool valueChanged = false;
  QMap<QString, QString> newComponentModifiersMap;
  QMap<QString, QString> newComponentExtendsModifiersMap;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    QString componentModifierKey = QString(mpComponent->getName()).append(".").append(pParameter->getNameLabel()->text());
    QString componentModifierValue = pParameter->getValue();
    if (pParameter->isValueModified()) {
      valueChanged = true;
      /* If the component is inherited then add the modifier value into the extends. */
      if (mpComponent->isInheritedComponent()) {
        newComponentExtendsModifiersMap.insert(componentModifierKey, componentModifierValue);
      } else {
        newComponentModifiersMap.insert(componentModifierKey, componentModifierValue);
      }
    }
    if (pParameter->isShowStartAttribute() && (pParameter->getFixedState().compare(pParameter->getOriginalFixedValue()) != 0)) {
      valueChanged = true;
      componentModifierKey = componentModifierKey.replace(".start", ".fixed");
      componentModifierValue = pParameter->getFixedState();
      /* If the component is inherited then add the modifier value into the extends. */
      if (mpComponent->isInheritedComponent()) {
        newComponentExtendsModifiersMap.insert(componentModifierKey, componentModifierValue);
      } else {
        newComponentModifiersMap.insert(componentModifierKey, componentModifierValue);
      }
    }
  }
  // any new modifier is added
  if (!mpModifiersTextBox->text().isEmpty()) {
    QString regexp ("\\s*([A-Za-z0-9]+\\s*)\\(\\s*([A-Za-z0-9]+)\\s*=\\s*([A-Za-z0-9]+)\\s*\\)$");
    QRegExp modifierRegExp (regexp);
    QStringList modifiers = mpModifiersTextBox->text().split(",", QString::SkipEmptyParts);
    foreach (QString modifier, modifiers) {
      modifier = modifier.trimmed();
      if (modifierRegExp.exactMatch(modifier)) {
        valueChanged = true;
        QString componentModifierKey = QString(mpComponent->getName()).append(".").append(modifier.mid(0, modifier.indexOf("(")));
        QString componentModifierValue = modifier.mid(modifier.indexOf("("));
        newComponentModifiersMap.insert(componentModifierKey, componentModifierValue);
      } else {
        mpMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                                     GUIMessages::getMessage(GUIMessages::WRONG_MODIFIER).arg(modifier),
                                                                     Helper::scriptingKind, Helper::errorLevel));
      }
    }
  }
  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged) {
    // save the Component modifiers
    QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    QMap<QString, QString> oldComponentModifiersMap;
    QStringList componentModifiersList = mpMainWindow->getOMCProxy()->getComponentModifierNames(className, mpComponent->getName());
    foreach (QString componentModifier, componentModifiersList) {
      QString originalModifierName = QString(mpComponent->getName()).append(".").append(componentModifier);
      QString componentModifierValue = mpMainWindow->getOMCProxy()->getComponentModifierValue(className, originalModifierName);
      oldComponentModifiersMap.insert(componentModifier, componentModifierValue);
    }
    // save the Component extends modifiers
    QMap<QString, QString> oldComponentExtendsModifiersMap;
    if (mpComponent->getReferenceComponent()) {
      QString inheritedClassName = mpComponent->getReferenceComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      QStringList extendsModifiersList = mpMainWindow->getOMCProxy()->getExtendsModifierNames(className, inheritedClassName);
      foreach (QString extendsModifier, extendsModifiersList) {
        QString componentModifierValue = mpMainWindow->getOMCProxy()->getExtendsModifierValue(className, inheritedClassName, extendsModifier);
        oldComponentExtendsModifiersMap.insert(extendsModifier, componentModifierValue);
      }
    }
    // create UpdateComponentParametersCommand
    UpdateComponentParametersCommand *pUpdateComponentParametersCommand;
    pUpdateComponentParametersCommand = new UpdateComponentParametersCommand(mpComponent, oldComponentModifiersMap,
                                                                             oldComponentExtendsModifiersMap, newComponentModifiersMap,
                                                                             newComponentExtendsModifiersMap);
    mpComponent->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateComponentParametersCommand);
    mpComponent->getGraphicsView()->getModelWidget()->updateModelicaText();
  }
  accept();
}

/*!
 * \class ComponentAttributes
 * \brief A dialog for displaying components attributes like visibility, stream, casuality etc.
 */
/*!
 * \brief ComponentAttributes::ComponentAttributes
 * \param pComponent
 * \param pMainWindow
 */
ComponentAttributes::ComponentAttributes(Component *pComponent, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Component Attributes")).arg(pComponent->getName())
                 .arg(className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
  mpMainWindow = pMainWindow;
  setUpDialog();
  initializeDialog();
}

/*!
 * \brief ComponentAttributes::setUpDialog
 * Creates the Dialog and set up all the controls with default values.
 */
void ComponentAttributes::setUpDialog()
{
  // heading label
  mpAttributesHeading = new Label(Helper::attributes);
  mpAttributesHeading->setFont(QFont("", Helper::headingFontSize));
  mpAttributesHeading->setAlignment(Qt::AlignTop);
  // set seperator line
  mHorizontalLine = new QFrame();
  mHorizontalLine->setFrameShape(QFrame::HLine);
  mHorizontalLine->setFrameShadow(QFrame::Sunken);
  // create Type Group Box
  mpTypeGroupBox = new QGroupBox(Helper::type);
  QGridLayout *pTypeGroupBoxLayout = new QGridLayout;
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // dimensions
  mpDimensionsLabel = new Label(tr("Dimensions:"));
  mpDimensionsTextBox = new QLineEdit;
  mpDimensionsTextBox->setToolTip(tr("Array of dimensions e.g {1, 5, 2}"));
  mpCommentLabel = new Label(Helper::comment);
  mpCommentTextBox = new QLineEdit;
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new Label;
  pTypeGroupBoxLayout->addWidget(mpNameLabel, 0, 0);
  pTypeGroupBoxLayout->addWidget(mpNameTextBox, 0, 1);
  pTypeGroupBoxLayout->addWidget(mpDimensionsLabel, 1, 0);
  pTypeGroupBoxLayout->addWidget(mpDimensionsTextBox, 1, 1);
  pTypeGroupBoxLayout->addWidget(mpCommentLabel, 2, 0);
  pTypeGroupBoxLayout->addWidget(mpCommentTextBox, 2, 1);
  pTypeGroupBoxLayout->addWidget(mpPathLabel, 3, 0);
  pTypeGroupBoxLayout->addWidget(mpPathTextBox, 3, 1);
  mpTypeGroupBox->setLayout(pTypeGroupBoxLayout);
  // create Variablity Group Box
  mpVariabilityGroupBox = new QGroupBox("Variability");
  mpConstantRadio = new QRadioButton("Constant");
  mpParameterRadio = new QRadioButton("Parameter");
  mpDiscreteRadio = new QRadioButton("Discrete");
  mpDefaultRadio = new QRadioButton("Unspecified (Default)");
  QVBoxLayout *pVariabilityGroupBoxLayout = new QVBoxLayout;
  pVariabilityGroupBoxLayout->addWidget(mpConstantRadio);
  pVariabilityGroupBoxLayout->addWidget(mpParameterRadio);
  pVariabilityGroupBoxLayout->addWidget(mpDiscreteRadio);
  pVariabilityGroupBoxLayout->addWidget(mpDefaultRadio);
  mpVariabilityButtonGroup = new QButtonGroup;
  mpVariabilityButtonGroup->addButton(mpConstantRadio);
  mpVariabilityButtonGroup->addButton(mpParameterRadio);
  mpVariabilityButtonGroup->addButton(mpDiscreteRadio);
  mpVariabilityButtonGroup->addButton(mpDefaultRadio);
  mpVariabilityGroupBox->setLayout(pVariabilityGroupBoxLayout);
  // create Variablity Group Box
  mpPropertiesGroupBox = new QGroupBox("Properties");
  mpFinalCheckBox = new QCheckBox("Final");
  mpProtectedCheckBox = new QCheckBox("Protected");
  mpReplaceAbleCheckBox = new QCheckBox("Replaceable");
  QVBoxLayout *pPropertiesGroupBoxLayout = new QVBoxLayout;
  pPropertiesGroupBoxLayout->addWidget(mpFinalCheckBox);
  pPropertiesGroupBoxLayout->addWidget(mpProtectedCheckBox);
  pPropertiesGroupBoxLayout->addWidget(mpReplaceAbleCheckBox);
  mpPropertiesGroupBox->setLayout(pPropertiesGroupBoxLayout);
  // create Variablity Group Box
  mpCausalityGroupBox = new QGroupBox("Causality");
  mpInputRadio = new QRadioButton("Input");
  mpOutputRadio = new QRadioButton("Output");
  mpNoneRadio = new QRadioButton("None");
  QVBoxLayout *pCausalityGroupBoxLayout = new QVBoxLayout;
  pCausalityGroupBoxLayout->addWidget(mpInputRadio);
  pCausalityGroupBoxLayout->addWidget(mpOutputRadio);
  pCausalityGroupBoxLayout->addWidget(mpNoneRadio);
  mpCausalityButtonGroup = new QButtonGroup;
  mpCausalityButtonGroup->addButton(mpInputRadio);
  mpCausalityButtonGroup->addButton(mpOutputRadio);
  mpCausalityButtonGroup->addButton(mpNoneRadio);
  mpCausalityGroupBox->setLayout(pCausalityGroupBoxLayout);
  // create Variablity Group Box
  mpInnerOuterGroupBox = new QGroupBox("Inner/Outer");
  mpInnerCheckBox = new QCheckBox("Inner");
  mpOuterCheckBox = new QCheckBox("Outer");
  QVBoxLayout *pInnerOuterGroupBoxLayout = new QVBoxLayout;
  pInnerOuterGroupBoxLayout->addWidget(mpInnerCheckBox);
  pInnerOuterGroupBoxLayout->addWidget(mpOuterCheckBox);
  mpInnerOuterGroupBox->setLayout(pInnerOuterGroupBoxLayout);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateComponentAttributes()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  if (mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpComponent->isInheritedComponent()) {
    mpOkButton->setDisabled(true);
  }
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpAttributesHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpTypeGroupBox, 2, 0, 1, 2);
  pMainLayout->addWidget(mpVariabilityGroupBox, 3, 0);
  pMainLayout->addWidget(mpPropertiesGroupBox, 3, 1);
  pMainLayout->addWidget(mpCausalityGroupBox, 4, 0);
  pMainLayout->addWidget(mpInnerOuterGroupBox, 4, 1);
  pMainLayout->addWidget(mpButtonBox, 5, 0, 1, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief ComponentAttributes::initializeDialog
 * Initialize the fields with default values.
 */
void ComponentAttributes::initializeDialog()
{
  // get Class Name
  mpNameTextBox->setText(mpComponent->getComponentInfo()->getName());
  mpNameTextBox->setCursorPosition(0);
  // get dimensions
  mpDimensionsTextBox->setText(mpComponent->getComponentInfo()->getArrayIndex());
  // get Comment
  mpCommentTextBox->setText(mpComponent->getComponentInfo()->getComment());
  mpCommentTextBox->setCursorPosition(0);
  // get classname
  mpPathTextBox->setText(mpComponent->getComponentInfo()->getClassName());
  // get Variability
  if (mpComponent->getComponentInfo()->getVariablity() == "constant") {
    mpConstantRadio->setChecked(true);
  } else if (mpComponent->getComponentInfo()->getVariablity() == "parameter") {
    mpParameterRadio->setChecked(true);
  } else if (mpComponent->getComponentInfo()->getVariablity() == "discrete") {
    mpDiscreteRadio->setChecked(true);
  } else {
    mpDefaultRadio->setChecked(true);
  }
  // get Properties
  mpFinalCheckBox->setChecked(mpComponent->getComponentInfo()->getFinal());
  mpProtectedCheckBox->setChecked(mpComponent->getComponentInfo()->getProtected());
  mpReplaceAbleCheckBox->setChecked(mpComponent->getComponentInfo()->getReplaceable());
  mIsFlow = mpComponent->getComponentInfo()->getFlow() ? "true" : "false";
  // get Casuality
  if (mpComponent->getComponentInfo()->getCausality() == "input") {
    mpInputRadio->setChecked(true);
  } else if (mpComponent->getComponentInfo()->getCausality() == "output") {
    mpOutputRadio->setChecked(true);
  } else {
    mpNoneRadio->setChecked(true);
  }
  // get InnerOuter
  mpInnerCheckBox->setChecked(mpComponent->getComponentInfo()->getInner());
  mpOuterCheckBox->setChecked(mpComponent->getComponentInfo()->getOuter());
}

/*!
 * \brief ComponentAttributes::updateComponentAttributes
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Updates the component attributes.
 */
void ComponentAttributes::updateComponentAttributes()
{
  ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
  /* Check the same component name problem before setting any attributes. */
  if (mpComponent->getComponentInfo()->getName().compare(mpNameTextBox->text()) != 0) {
    if (!mpComponent->getGraphicsView()->checkComponentName(mpNameTextBox->text())) {
      QMessageBox::information(pModelWidget->getModelWidgetContainer()->getMainWindow(),
                               QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME), Helper::ok);
      return;
    }
  }
  QString variability;
  if (mpConstantRadio->isChecked()) {
    variability = "constant";
  } else if (mpParameterRadio->isChecked()) {
    variability = "parameter";
  } else if (mpDiscreteRadio->isChecked()) {
    variability = "discrete";
  } else {
    variability = "";
  }
  QString causality;
  if (mpInputRadio->isChecked()) {
    causality = "input";
  } else if (mpOutputRadio->isChecked()) {
    causality = "output";
  } else {
    causality = "";
  }
  // save the old ComponentInfo
  ComponentInfo oldComponentInfo(mpComponent->getComponentInfo());
  // Create a new ComponentInfo
  ComponentInfo newComponentInfo;
  newComponentInfo.setClassName(mpComponent->getComponentInfo()->getClassName());
  newComponentInfo.setName(mpNameTextBox->text());
  newComponentInfo.setComment(mpCommentTextBox->text());
  newComponentInfo.setProtected(mpProtectedCheckBox->isChecked());
  newComponentInfo.setFinal(mpFinalCheckBox->isChecked());
  newComponentInfo.setFlow(mpComponent->getComponentInfo()->getFlow());
  newComponentInfo.setStream(mpComponent->getComponentInfo()->getStream());
  newComponentInfo.setReplaceable(mpReplaceAbleCheckBox->isChecked());
  newComponentInfo.setVariablity(variability);
  newComponentInfo.setInner(mpInnerCheckBox->isChecked());
  newComponentInfo.setOuter(mpOuterCheckBox->isChecked());
  newComponentInfo.setCausality(causality);
  newComponentInfo.setArrayIndex(mpDimensionsTextBox->text());
  /* If user has really changed the Component's attributes then push that change on the stack.
   */
  if (oldComponentInfo != newComponentInfo) {
    UpdateComponentAttributesCommand *pUpdateComponentAttributesCommand = new UpdateComponentAttributesCommand(mpComponent, oldComponentInfo,
                                                                                                               newComponentInfo);
    pModelWidget->getUndoStack()->push(pUpdateComponentAttributesCommand);
    pModelWidget->updateModelicaText();
  }
  accept();
}

/*!
 * \class SubModelAttributes
 * \brief A dialog for displaying SubModel attributes.
 */
/*!
 * \brief SubModelAttributes::SubModelAttributes
 * \param pComponent - pointer to Component
 * \param pMainWindow - pointer to MainWindow
 */
SubModelAttributes::SubModelAttributes(Component *pComponent, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("SubModel Attributes")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(250);
  mpComponent = pComponent;
  mpMainWindow = pMainWindow;
  setUpDialog();
  initializeDialog();
}

/*!
 * \brief SubModelAttributes::setUpDialog
 * Creates the Dialog and set up attributes.
 */
void SubModelAttributes::setUpDialog()
{
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  mpNameTextBox->setReadOnly(true);
  // Create the start command label and text box
  mpStartCommandLabel = new Label(tr("Start Command:"));
  mpStartCommandTextBox = new QLineEdit;
  mpStartCommandTextBox->setReadOnly(true);
  // Create the model file label and text box
  mpModelFileLabel = new Label(tr("Model File:"));
  mpModelFileTextBox = new QLineEdit;
  mpModelFileTextBox->setReadOnly(true);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(accept()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1);
  pMainLayout->addWidget(mpStartCommandLabel, 1, 0);
  pMainLayout->addWidget(mpStartCommandTextBox, 1, 1);
  pMainLayout->addWidget(mpModelFileLabel, 2, 0);
  pMainLayout->addWidget(mpModelFileTextBox, 2, 1);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Initialize the fields with default values.
  */
void SubModelAttributes::initializeDialog()
{
  // get component Name
  mpNameTextBox->setText(mpComponent->getName());
  mpStartCommandTextBox->setText("StartTLMOpenModelica");
  QFileInfo fileInfo(mpComponent->getLibraryTreeItem()->getFileName());
  mpModelFileTextBox->setText(fileInfo.fileName());
}

TLMInterfacePointInfo::TLMInterfacePointInfo(QString name, QString className, QString interfaceName)
{
  mName = name;
  mClassName = className;
  mInterfaceName = interfaceName;
}

QString TLMInterfacePointInfo::getName()
{
  return mName;
}

QString TLMInterfacePointInfo::getClassName()
{
  return mClassName;
}

QString TLMInterfacePointInfo::getInterfaceName()
{
  return mInterfaceName;
}

void TLMInterfacePointInfo::setInterfaceName(QString interfacePoint)
{
   mInterfaceName = interfacePoint;
}

/*!
  \class TLMConnectiontAttributes
  \brief A dialog for displaying TLM connection attributes
  */
/*!
  \param pConnectionLineAnnotation - pointer to LineAnnotation
  \param pMainWindow - pointer to MainWindow
  */
TLMConnectionAttributes::TLMConnectionAttributes(LineAnnotation *pConnectionLineAnnotation, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("TLM Connection Attributes")));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  mpConnectionLineAnnotation = pConnectionLineAnnotation;
  mpMainWindow = pMainWindow;
  setUpDialog();
  initializeDialog();
}

/*!
  Creates the Dialog and set up attributes .
  */
void TLMConnectionAttributes::setUpDialog()
{
  // Create the start component class name label and text box
  mpStartSubModelNameLabel = new Label(tr("From:"));
  mpStartSubModelNameTextBox = new QLineEdit;
  mpStartSubModelNameTextBox->setReadOnly(true);
  // Create the start component interface points  combo box
  mpStartSubModelInterfacePointComboBox = new QComboBox;
  // Create the end component class name label and text box
  mpEndSubModelNameLabel = new Label(tr("To:"));
  mpEndSubModelNameTextBox = new QLineEdit;
  mpEndSubModelNameTextBox->setReadOnly(true);
  // Create the end component interface points  combo box
  mpEndSubModelInterfacePointComboBox = new QComboBox;
  // Create the delay label and text box
  mpDelayLabel = new Label(tr("Delay:"));
  mpDelayTextBox = new QLineEdit;

  mpZfLabel = new Label(tr("Zf:"));
  mpZfTextBox = new QLineEdit;
  mpZfrLabel = new Label(tr("Zfr:"));
  mpZfrTextBox = new QLineEdit;

  // Create the alpha label and text box
  mpAlphapLabel = new Label(tr("Alpha:"));
  mpAlphaTextBox = new QLineEdit;
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(createTLMConnection()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpStartSubModelNameLabel, 0, 0);
  pMainLayout->addWidget(mpStartSubModelNameTextBox, 0, 1);
  pMainLayout->addWidget(mpStartSubModelInterfacePointComboBox, 0, 2);
  pMainLayout->addWidget(mpEndSubModelNameLabel, 1, 0);
  pMainLayout->addWidget(mpEndSubModelNameTextBox, 1, 1);
  pMainLayout->addWidget(mpEndSubModelInterfacePointComboBox, 1, 2);
  pMainLayout->addWidget(mpDelayLabel, 2, 0);
  pMainLayout->addWidget(mpDelayTextBox, 2, 1, 1, 3);
  pMainLayout->addWidget(mpZfLabel,3, 0);
  pMainLayout->addWidget(mpZfTextBox,3, 1, 1, 3);
  pMainLayout->addWidget(mpZfrLabel, 4, 0);
  pMainLayout->addWidget(mpZfrTextBox,4, 1, 1, 3);
  pMainLayout->addWidget(mpAlphapLabel, 5, 0);
  pMainLayout->addWidget(mpAlphaTextBox, 5, 1, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 4, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Initialize the fields with default values.
  */
void TLMConnectionAttributes::initializeDialog()
{
  mpStartSubModelNameTextBox->setText(mpConnectionLineAnnotation->getStartComponent()->getName());
  mpEndSubModelNameTextBox->setText(mpConnectionLineAnnotation->getEndComponent()->getName());
  mInterfacepointsList = mpConnectionLineAnnotation->getStartComponent()->getInterfacepointsList();
  for( int i=0; i<mInterfacepointsList.count(); ++i )
  {
   mpStartSubModelInterfacePointComboBox->addItem(mInterfacepointsList.at(i)->getInterfaceName());
  }

  mInterfacepointsList = mpConnectionLineAnnotation->getEndComponent()->getInterfacepointsList();
  for( int i=0; i<mInterfacepointsList.count(); ++i )
  {
   mpEndSubModelInterfacePointComboBox->addItem(mInterfacepointsList.at(i)->getInterfaceName());
  }
}

/*!
  Slot activated when mpOkButton clicked signal is raised.\n
  Updates the TLM component attributes.
  */
void TLMConnectionAttributes::createTLMConnection()
{
  TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpMainWindow->getModelWidgetContainer()->getCurrentModelWidget()->getEditor());
  QString startFrom = mpStartSubModelNameTextBox->text().append(".").append(mpStartSubModelInterfacePointComboBox->currentText());
  QString endTo = mpEndSubModelNameTextBox->text().append(".").append(mpEndSubModelInterfacePointComboBox->currentText());
  pTLMEditor->createConnection(startFrom, endTo, mpDelayTextBox->text(), mpAlphaTextBox->text(),mpZfTextBox->text(), mpZfrTextBox->text(),
                               mpConnectionLineAnnotation->getTLMShapeAnnotation());
  accept();
}
