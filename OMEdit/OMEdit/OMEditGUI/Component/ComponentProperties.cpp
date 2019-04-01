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

#include "ComponentProperties.h"
#include "MainWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/Commands.h"

#include <QApplication>
#include <QMenu>
#include <QWidgetAction>
#include <QButtonGroup>
#include <QMessageBox>
#include <QDesktopServices>
#include <QDesktopWidget>
#include <QList>
#include <QStringList>

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
  setFixedState("false", true);
  // set the value type based on component type.
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  if (mpComponent->getComponentInfo()->getClassName().compare("Boolean") == 0) {
    if (mpComponent->getChoicesAnnotation().size() > 1 && /* Size should be 2. We always get choices(checkBox, __Dymola_checkBox) */
        (mpComponent->getChoicesAnnotation().at(0).compare("true") == 0 || mpComponent->getChoicesAnnotation().at(1).compare("true") == 0)) {
      mValueType = Parameter::CheckBox;
    } else {
      mValueType = Parameter::Boolean;
    }
  } else if (pOMCProxy->isBuiltinType(mpComponent->getComponentInfo()->getClassName())) {
    mValueType = Parameter::Normal;
  } else if (pOMCProxy->isWhat(StringHandler::Enumeration, mpComponent->getComponentInfo()->getClassName())) {
    mValueType = Parameter::Enumeration;
  } else {
    mValueType = Parameter::Normal;
  }
  mValueCheckBoxModified = false;
  mDefaultValue = "";
  mpFileSelectorButton = new QToolButton;
  mpFileSelectorButton->setText("...");
  mpFileSelectorButton->setToolButtonStyle(Qt::ToolButtonTextOnly);
  connect(mpFileSelectorButton, SIGNAL(clicked()), SLOT(fileSelectorButtonClicked()));
  setLoadSelectorFilter("-");
  setLoadSelectorCaption("-");
  setSaveSelectorFilter("-");
  setSaveSelectorCaption("-");
  createValueWidget();
  /* Get unit value
   * First check if unit is defined with in the component modifier.
   * If no unit is found then check it in the derived class modifier value.
   * A derived class can be inherited, so look recursively.
   */
  QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QString unit = mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent).value("unit");
  if (unit.isEmpty()) {
    if (!pOMCProxy->isBuiltinType(mpComponent->getComponentInfo()->getClassName())) {
      unit = pOMCProxy->getDerivedClassModifierValue(mpComponent->getComponentInfo()->getClassName(), "unit");
      if (unit.isEmpty()) {
        unit = getModifierValueFromDerivedClass(mpComponent, "unit");
      }
    }
  }
  mUnit = StringHandler::removeFirstLastQuotes(unit);
  /* Get displayUnit value
   * First check if displayUnit is defined with in the component modifier.
   * If no displayUnit is found then check it in the derived class modifier value.
   * A derived class can be inherited, so look recursively.
   */
  QString displayUnit = mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent).value("displayUnit");
  if (displayUnit.isEmpty()) {
    if (!pOMCProxy->isBuiltinType(mpComponent->getComponentInfo()->getClassName())) {
      displayUnit = pOMCProxy->getDerivedClassModifierValue(mpComponent->getComponentInfo()->getClassName(), "displayUnit");
      if (displayUnit.isEmpty()) {
        displayUnit = getModifierValueFromDerivedClass(mpComponent, "displayUnit");
      }
    }
  }
  if (displayUnit.isEmpty()) {
    displayUnit = unit;
  }
  mDisplayUnit = StringHandler::removeFirstLastQuotes(displayUnit);
  mPreviousUnit = mDisplayUnit;
  mpUnitComboBox = new QComboBox;
  if (!mUnit.isEmpty()) {
    mpUnitComboBox->addItem(mUnit);
    if (mDisplayUnit.compare(mUnit) != 0) {
      mpUnitComboBox->addItem(mDisplayUnit);
      mpUnitComboBox->setCurrentIndex(1);
    }
  }
  connect(mpUnitComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(unitComboBoxChanged(QString)));
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

/*!
 * \brief Parameter::setValueWidget
 * Sets the value and defaultValue for the parameter.
 * \param value
 * \param defaultValue
 * \param fromUnit
 * \param valueChanged
 * \param adjustSize
 */
void Parameter::setValueWidget(QString value, bool defaultValue, QString fromUnit, bool valueModified, bool adjustSize)
{
  // convert the value to display unit
  if (!fromUnit.isEmpty() && mpUnitComboBox->currentText().compare(fromUnit) != 0) {
    bool ok = true;
    qreal realValue = value.toDouble(&ok);
    // if the modifier is a literal constant
    if (ok) {
      OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
      OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(fromUnit, mpUnitComboBox->currentText());
      if (convertUnit.unitsCompatible) {
        realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
        value = QString::number(realValue);
      }
    } else { // if expression
      value = Utilities::arrayExpressionUnitConversion(MainWindow::instance()->getOMCProxy(), value, fromUnit, mpUnitComboBox->currentText());
    }
  }
  mDefaultValue = defaultValue;
  QFontMetrics fm = QFontMetrics(QFont());
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      if (defaultValue) {
        mpValueComboBox->lineEdit()->setPlaceholderText(value);
      } else {
        mpValueComboBox->lineEdit()->setText(value);
        mpValueComboBox->lineEdit()->setModified(valueModified);
      }
      if (adjustSize) {
        /* Set the minimum width so that the value text will be readable */
        fm = QFontMetrics(mpValueComboBox->lineEdit()->font());
        mpValueComboBox->setMinimumWidth(fm.width(value) + 50);
      }
      break;
    case Parameter::CheckBox:
      mpValueCheckBox->setChecked(value.compare("true") == 0);
      break;
    case Parameter::Normal:
    default:
      if (defaultValue) {
        mpValueTextBox->setPlaceholderText(value);
      } else {
        mpValueTextBox->setText(value);
        mpValueTextBox->setModified(valueModified);
      }
      if (adjustSize) {
        /* Set the minimum width so that the value text will be readable */
        fm = QFontMetrics(mpValueTextBox->font());
        mpValueTextBox->setMinimumWidth(fm.width(value) + 50);
      }
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
    case Parameter::CheckBox:
      return mpValueCheckBox;
    case Parameter::Normal:
    default:
      return mpValueTextBox;
  }
}

/*!
 * \brief Parameter::isValueModified
 * Returns true if value widget is changed.
 * \return
 */
bool Parameter::isValueModified()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      return mpValueComboBox->lineEdit()->isModified();
    case Parameter::CheckBox:
      return mValueCheckBoxModified;
    case Parameter::Normal:
    default:
      return mpValueTextBox->isModified();
  }
}

/*!
 * \brief Parameter::getValue
 * Returns the value.
 * \return
 */
QString Parameter::getValue()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
      return mpValueComboBox->lineEdit()->text().trimmed();
    case Parameter::CheckBox:
      return mpValueCheckBox->isChecked() ? "true" : "false";
    case Parameter::Normal:
    default:
      return mpValueTextBox->text().trimmed();
  }
}

/*!
 * \brief Parameter::getDefaultValue
 * Returns the default value.
 * \return
 */
QString Parameter::getDefaultValue()
{
  return mDefaultValue;
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
 * \brief Parameter::getModifierValueFromDerivedClass
 * Returns the modifier value by reading the derived classes.
 * \param pComponent
 * \param modifierName
 * \return the modifier value.
 */
QString Parameter::getModifierValueFromDerivedClass(Component *pComponent, QString modifierName)
{
  MainWindow *pMainWindow = MainWindow::instance();
  OMCProxy *pOMCProxy = pMainWindow->getOMCProxy();
  QString modifierValue = "";
  if (!pComponent->getLibraryTreeItem()->getModelWidget()) {
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pComponent->getLibraryTreeItem(), false);
  }
  foreach (Component *pInheritedComponent, pComponent->getInheritedComponentsList()) {
    /* Ticket #4031
     * Since we use the parent ComponentInfo for inherited classes so we should not use
     * pInheritedComponent->getComponentInfo()->getClassName() to get the name instead we should use
     * pInheritedComponent->getLibraryTreeItem()->getNameStructure() to get the correct name of inherited class.
     * Also don't just return after reading from first inherited class. Check recursively.
     */
    if (pInheritedComponent->getLibraryTreeItem() &&
        !pOMCProxy->isBuiltinType(pInheritedComponent->getLibraryTreeItem()->getNameStructure())) {
      modifierValue = pOMCProxy->getDerivedClassModifierValue(pInheritedComponent->getLibraryTreeItem()->getNameStructure(),
                                                              modifierName);
      if (modifierValue.isEmpty()) {
        modifierValue = getModifierValueFromDerivedClass(pInheritedComponent, modifierName);
      }
      if (!modifierValue.isEmpty()) {
        return modifierValue;
      }
    }
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
    case Parameter::CheckBox:
      mpValueCheckBox->setEnabled(enable);
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
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
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
    case Parameter::CheckBox:
      mpValueCheckBox = new QCheckBox;
      connect(mpValueCheckBox, SIGNAL(toggled(bool)), SLOT(valueCheckBoxChanged(bool)));
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox = new QLineEdit;
      break;
  }
}

/*!
 * \brief Parameter::fileSelectorButtonClicked
 * Slot activated when mpFileSelectorButton clicked SIGNAL is raised.
 * Opens a QFileDialog::getOpenFileName or QFileDialog::getSaveFileName so user can select a file.
 */
void Parameter::fileSelectorButtonClicked()
{
  QString filter, caption = "";
  QString fileName;
  /* saveSelector is given precedence if present.
   * There is nothing about it in the specification but we do so to keep consistant with Dymola.
   */
  if (mSaveSelectorFilter.compare("-") != 0 && mSaveSelectorCaption.compare("-") != 0) {
    if (mSaveSelectorFilter.compare("-") != 0) {
      filter = mSaveSelectorFilter;
    }
    caption = tr("Save");
    if (mSaveSelectorCaption.compare("-") != 0) {
      caption = mSaveSelectorCaption;
    }
    fileName = StringHandler::getSaveFileName(MainWindow::instance(), caption, NULL, filter, NULL);
  } else {
    filter = "";
    if (mLoadSelectorFilter.compare("-") != 0) {
      filter = mLoadSelectorFilter;
    }
    caption = tr("Load");
    if (mLoadSelectorCaption.compare("-") != 0) {
      caption = mLoadSelectorCaption;
    }
    fileName = StringHandler::getOpenFileName(MainWindow::instance(), caption, NULL, filter, NULL);
  }
  // if user press ESC
  if (fileName.isEmpty()) {
    return;
  }
  setValueWidget(QString("\"%1\"").arg(fileName), false, mUnit, true, false);
}

/*!
 * \brief Parameter::unitComboBoxChanged
 * SLOT activated when mpUnitComboBox currentIndexChanged(QString) SIGNAL is raised.\n
 * Updates the value according to the unit selected.
 * \param text
 */
void Parameter::unitComboBoxChanged(QString text)
{
  QString defaultValue = getDefaultValue();
  if (!defaultValue.isEmpty()) {
    setValueWidget(getDefaultValue(), true, mPreviousUnit, false);
  }
  QString value = getValue();
  if (!value.isEmpty()) {
    setValueWidget(getValue(), false, mPreviousUnit, true);
  }
  mPreviousUnit = text;
}

/*!
 * \brief Parameter::valueComboBoxChanged
 * SLOT activated when mpValueComboBox currentIndexChanged(int) SIGNAL is raised.\n
 * Updates the value according to the value selected.
 * \param index
 */
void Parameter::valueComboBoxChanged(int index)
{
  mpValueComboBox->lineEdit()->setText(mpValueComboBox->itemData(index).toString());
  mpValueComboBox->lineEdit()->setModified(true);
}

/*!
 * \brief Parameter::valueCheckBoxChanged
 * SLOT activated when mpValueCheckBox toggled(bool) SIGNAL is raised.\n
 * Marks the item modified.
 * \param toggle
 */
void Parameter::valueCheckBoxChanged(bool toggle)
{
  mValueCheckBoxModified = true;
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
  if (QFile::exists(groupImage)) {
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
 * \param pParent
 */
ComponentParameters::ComponentParameters(Component *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Component Parameters")).arg(pComponent->getName())
                 .arg(className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
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
  mpParametersHeading = Utilities::getHeadingLabel(Helper::parameters);
  // set separator line
  mHorizontalLine = Utilities::getHeadingLine();
  // parameters tab widget
  mpParametersTabWidget = new QTabWidget;
  // Component Group Box
  mpComponentGroupBox = new QGroupBox(tr("Component"));
  // Component name
  mpComponentNameLabel = new Label(Helper::name);
  mpComponentNameTextBox = new Label(mpComponent->getName());
  QGridLayout *pComponentGroupBoxLayout = new QGridLayout;
  pComponentGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentGroupBoxLayout->addWidget(mpComponentNameLabel, 0, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentNameTextBox, 0, 1);
  mpComponentGroupBox->setLayout(pComponentGroupBoxLayout);
  // Component Class Group Box
  mpComponentClassGroupBox = new QGroupBox(tr("Class"));
  // Component class name
  mpComponentClassNameLabel = new Label(Helper::path);
  mpComponentClassNameTextBox = new Label(mpComponent->getComponentInfo()->getClassName());
  // Component comment
  mpComponentClassCommentLabel = new Label(Helper::comment);
  mpComponentClassCommentTextBox = new Label;
  mpComponentClassCommentTextBox->setTextFormat(Qt::RichText);
  mpComponentClassCommentTextBox->setTextInteractionFlags(mpComponentClassCommentTextBox->textInteractionFlags()
                                                          | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  if (mpComponent->getLibraryTreeItem()) {
    mpComponentClassCommentTextBox->setText(mpComponent->getLibraryTreeItem()->mClassInformation.comment);
  }
  connect(mpComponentClassCommentTextBox, SIGNAL(linkActivated(QString)), SLOT(commentLinkClicked(QString)));
  QGridLayout *pComponentClassGroupBoxLayout = new QGridLayout;
  pComponentClassGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassNameLabel, 0, 0);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassNameTextBox, 0, 1);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassCommentLabel, 1, 0);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassCommentTextBox, 1, 1);
  mpComponentClassGroupBox->setLayout(pComponentClassGroupBoxLayout);
  // Create General tab and Parameters GroupBox
  ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
  // first add the Component Group Box and component class group box
  pParametersScrollArea->getLayout()->addWidget(mpComponentGroupBox);
  pParametersScrollArea->getLayout()->addWidget(mpComponentClassGroupBox);
  GroupBox *pParametersGroupBox = new GroupBox("Parameters");
  pParametersScrollArea->addGroupBox(pParametersGroupBox);
  GroupBox *pInitializationGroupBox = new GroupBox("Initialization");
  pParametersScrollArea->addGroupBox(pInitializationGroupBox);
  mTabsMap.insert("General", mpParametersTabWidget->addTab(pParametersScrollArea, "General"));
  // create parameters tabs and groupboxes
  createTabsGroupBoxesAndParameters(mpComponent->getLibraryTreeItem());
  /* We append the actual Components parameters first so that they appear first on the list.
   * For that we use QList insert instead of append in ComponentParameters::createTabsGroupBoxesAndParametersHelper() function.
   * Modelica.Electrical.Analog.Basic.Resistor order is wrong if we don't use insert.
   */
  createTabsGroupBoxesAndParametersHelper(mpComponent->getLibraryTreeItem(), true);
  fetchComponentModifiers();
  fetchExtendsModifiers();
  foreach (Parameter *pParameter, mParametersList) {
    ParametersScrollArea *pParametersScrollArea;
    pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
    if (pParametersScrollArea) {
      if (!pParameter->getGroupBox().isEmpty()) {
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
          if (pParameter->getLoadSelectorFilter().compare("-") != 0 || pParameter->getLoadSelectorCaption().compare("-") != 0 ||
              pParameter->getSaveSelectorFilter().compare("-") != 0 || pParameter->getSaveSelectorCaption().compare("-") != 0) {
            pGroupBoxGridLayout->addWidget(pParameter->getFileSelectorButton(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }
          if (pParameter->getUnitComboBox()->count() > 0) { // only add the unit combobox if we really have a unit
            /* ticket:4421
             * Show a fixed value when there is only one unit.
             */
            if (pParameter->getUnitComboBox()->count() == 1) {
              pGroupBoxGridLayout->addWidget(new Label(pParameter->getUnitComboBox()->currentText()), layoutIndex, columnIndex++);
            } else {
              pGroupBoxGridLayout->addWidget(pParameter->getUnitComboBox(), layoutIndex, columnIndex++);
            }
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getCommentLabel(), layoutIndex, columnIndex++);
        }
      }
    }
  }
  // create Modifiers tab
  QWidget *pModifiersTab = new QWidget;
  // add items to modifiers tab
  mpModifiersLabel = new Label(tr("Add new modifiers, e.g., phi(start=1), w(start=2)"));
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
  if (mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpComponent->getGraphicsView()->isVisualizationView()) {
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
  foreach (LibraryTreeItem *pInheritedLibraryTreeItem, pLibraryTreeItem->getModelWidget()->getInheritedClassesList()) {
    createTabsGroupBoxesAndParameters(pInheritedLibraryTreeItem);
    createTabsGroupBoxesAndParametersHelper(pInheritedLibraryTreeItem);
  }
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
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  foreach (LibraryTreeItem *pInheritedLibraryTreeItem, pLibraryTreeItem->getInheritedClasses()) {
    QMap<QString, QString> extendsModifiers = pLibraryTreeItem->getModelWidget()->getExtendsModifiersMap(pInheritedLibraryTreeItem->getNameStructure());
    QMap<QString, QString>::iterator extendsModifiersIterator;
    for (extendsModifiersIterator = extendsModifiers.begin(); extendsModifiersIterator != extendsModifiers.end(); ++extendsModifiersIterator) {
      QString parameterName = StringHandler::getFirstWordBeforeDot(extendsModifiersIterator.key());
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
          if (extendsModifiersIterator.key().compare(parameterName + ".start") == 0) {
            QString start = extendsModifiersIterator.value();
            if (!start.isEmpty()) {
              if (pParameter->getGroupBox().isEmpty()) {
                pParameter->setGroupBox("Initialization");
              }
              pParameter->setShowStartAttribute(true);
              pParameter->setValueWidget(start, true, pParameter->getUnit());
            }
          } else if (extendsModifiersIterator.key().compare(parameterName + ".fixed") == 0) {
            QString fixed = extendsModifiersIterator.value();
            if (!fixed.isEmpty()) {
              if (pParameter->getGroupBox().isEmpty()) {
                pParameter->setGroupBox("Initialization");
              }
              pParameter->setShowStartAttribute(true);
              pParameter->setFixedState(fixed, true);
            }
          } else {
            pParameter->setValueWidget(extendsModifiersIterator.value(), true, pParameter->getUnit());
          }
        }
      }
    }
  }
  int insertIndex = 0;
  pLibraryTreeItem->getModelWidget()->loadDiagramView();
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
    QString loadSelectorFilter = "-", loadSelectorCaption = "-", saveSelectorFilter = "-", saveSelectorCaption = "-";
    QString start = "", fixed = "";
    bool isParameter = (pComponent->getComponentInfo()->getVariablity().compare("parameter") == 0);
    // If not a parameter then check for start and fixed bindings. See Modelica.Electrical.Analog.Basic.Resistor parameter R.
    if (!isParameter) {
      OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
      QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      QMap<QString, QString> modifiers = pComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, pComponent);
      QMap<QString, QString>::iterator modifiersIterator;
      for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
        if (modifiersIterator.key().compare("start") == 0) {
          start = modifiersIterator.value();
        }
        else if (modifiersIterator.key().compare("fixed") == 0) {
          fixed = modifiersIterator.value();
        }
      }
      showStartAttribute = (!start.isEmpty() || !fixed.isEmpty()) ? true : false;
    }
    /* get the dialog annotation */
    QStringList dialogAnnotation = pComponent->getDialogAnnotation();
    QString groupImage = "";
    if (dialogAnnotation.size() > 0) {
      // get the tab value
      tab = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(0));
      // get the group value
      groupBox = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(1));
      // get the enable value
      /* Ticket #4008
       * For now just display all parameters as enabled.
       */
      //enable = (dialogAnnotation.at(2).compare("true") == 0);
      // get the showStartAttribute value
      if (dialogAnnotation.at(3).compare("-") != 0) {
        showStartAttribute = (dialogAnnotation.at(3).compare("true") == 0);
      }
      // get the loadSelector
      loadSelectorFilter = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(5));
      loadSelectorCaption = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(6));
      // get the saveSelector
      saveSelectorFilter = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(7));
      saveSelectorCaption = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(8));
      // get the group image
      groupImage = StringHandler::removeFirstLastQuotes(dialogAnnotation.at(9));
      if (!groupImage.isEmpty()) {
        groupImage = MainWindow::instance()->getOMCProxy()->uriToFilename(groupImage);
      }
    }
    // if showStartAttribute true and group name is empty or Parameters then we should make group name Initialization
    if (showStartAttribute && groupBox.isEmpty()) {
      groupBox = "Initialization";
    } else if (groupBox.isEmpty() && (isParameter || (dialogAnnotation.size() > 0))) {
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
      GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(groupBox);
      if (pParametersScrollArea && !pGroupBox) {
        pGroupBox = new GroupBox(groupBox);
        pParametersScrollArea->addGroupBox(pGroupBox);
      }
      // set the group image
      pGroupBox->setGroupImage(groupImage);
    }
    // create the Parameter
    Parameter *pParameter = new Parameter(pComponent, showStartAttribute, tab, groupBox);
    pParameter->setEnabled(enable);
    pParameter->setLoadSelectorFilter(loadSelectorFilter);
    pParameter->setLoadSelectorCaption(loadSelectorCaption);
    pParameter->setSaveSelectorFilter(saveSelectorFilter);
    pParameter->setSaveSelectorCaption(saveSelectorCaption);
    QString componentDefinedInClass = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    QString value = pComponent->getComponentInfo()->getParameterValue(pOMCProxy, componentDefinedInClass);
    pParameter->setValueWidget(value, true, pParameter->getUnit());
    if (showStartAttribute) {
      pParameter->setValueWidget(start, true, pParameter->getUnit());
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

/*!
 * \brief ComponentParameters::fetchComponentModifiers
 * Fetches the Component's modifiers and apply modifier values on the appropriate Parameters.
 */
void ComponentParameters::fetchComponentModifiers()
{
  Component *pComponent = mpComponent;
  if (mpComponent->getReferenceComponent()) {
    pComponent = mpComponent->getReferenceComponent();
  }
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QMap<QString, QString> modifiers = pComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent);
  QMap<QString, QString>::iterator modifiersIterator;
  for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
    QString parameterName = StringHandler::getFirstWordBeforeDot(modifiersIterator.key());
    Parameter *pParameter = findParameter(parameterName);
    if (pParameter) {
      if (pParameter->isShowStartAttribute()) {
        if (modifiersIterator.key().compare(parameterName + ".start") == 0) {
          QString start = modifiersIterator.value();
          if (!start.isEmpty()) {
            if (pParameter->getGroupBox().isEmpty()) {
              pParameter->setGroupBox("Initialization");
            }
            pParameter->setShowStartAttribute(true);
            pParameter->setValueWidget(start, mpComponent->getReferenceComponent() ? true : false, pParameter->getUnit());
          }
        } else if (modifiersIterator.key().compare(parameterName + ".fixed") == 0) {
          QString fixed = modifiersIterator.value();
          if (!fixed.isEmpty()) {
            if (pParameter->getGroupBox().isEmpty()) {
              pParameter->setGroupBox("Initialization");
            }
            pParameter->setShowStartAttribute(true);
            pParameter->setFixedState(fixed, mpComponent->getReferenceComponent() ? true : false);
          }
        }
      } else if (modifiersIterator.key().compare(parameterName) == 0) {
        pParameter->setValueWidget(modifiersIterator.value(), mpComponent->getReferenceComponent() ? true : false, pParameter->getUnit());
      }
      if (modifiersIterator.key().compare(parameterName + ".displayUnit") == 0) {
        QString displayUnit = StringHandler::removeFirstLastQuotes(modifiersIterator.value());
        int index = pParameter->getUnitComboBox()->findText(displayUnit, Qt::MatchExactly);
        if (index < 0) {
          // add modifier as additional display unit if compatible
          index = pParameter->getUnitComboBox()->count() - 1;
          if (index > -1 &&
              (pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemText(0), displayUnit)).unitsCompatible) {
            pParameter->getUnitComboBox()->addItem(displayUnit);
            index ++;
          }
        }
        if (index > -1) {
          pParameter->getUnitComboBox()->setCurrentIndex(index);
          pParameter->setDisplayUnit(displayUnit);
        }
      }
    }
  }
}

void ComponentParameters::fetchExtendsModifiers()
{
  if (mpComponent->getReferenceComponent()) {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QString inheritedClassName;
    inheritedClassName = mpComponent->getReferenceComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    QMap<QString, QString> extendsModifiersMap = mpComponent->getGraphicsView()->getModelWidget()->getExtendsModifiersMap(inheritedClassName);
    QMap<QString, QString>::iterator extendsModifiersIterator;
    for (extendsModifiersIterator = extendsModifiersMap.begin(); extendsModifiersIterator != extendsModifiersMap.end(); ++extendsModifiersIterator) {
      QString componentName = StringHandler::getFirstWordBeforeDot(extendsModifiersIterator.key());
      if (mpComponent->getName().compare(componentName) == 0) {
        /* Ticket #4095
         * Handle parameters display of inherited components.
         */
        QString parameterName = extendsModifiersIterator.key();
        Parameter *pParameter = findParameter(StringHandler::removeFirstWordAfterDot(parameterName));
        if (pParameter) {
          if (pParameter->isShowStartAttribute()) {
            if (extendsModifiersIterator.key().compare(parameterName + ".start") == 0) {
              QString start = extendsModifiersIterator.value();
              if (!start.isEmpty()) {
                if (pParameter->getGroupBox().isEmpty()) {
                  pParameter->setGroupBox("Initialization");
                }
                pParameter->setShowStartAttribute(true);
                pParameter->setValueWidget(start, false, pParameter->getUnit());
              }
            } else if (extendsModifiersIterator.key().compare(parameterName + ".fixed") == 0) {
              QString fixed = extendsModifiersIterator.value();
              if (!fixed.isEmpty()) {
                if (pParameter->getGroupBox().isEmpty()) {
                  pParameter->setGroupBox("Initialization");
                }
                pParameter->setShowStartAttribute(true);
                pParameter->setFixedState(fixed, false);
              }
            }
          } else if (extendsModifiersIterator.key().compare(parameterName) == 0) {
            pParameter->setValueWidget(extendsModifiersIterator.value(), false, pParameter->getUnit());
          }
          if (extendsModifiersIterator.key().compare(parameterName + ".displayUnit") == 0) {
            QString displayUnit = StringHandler::removeFirstLastQuotes(extendsModifiersIterator.value());
            int index = pParameter->getUnitComboBox()->findText(displayUnit, Qt::MatchExactly);
            if (index < 0) {
              // add extends modifier as additional display unit if compatible
              index = pParameter->getUnitComboBox()->count() - 1;
              if (index > -1 &&
                  (pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemText(0), displayUnit)).unitsCompatible) {
                pParameter->getUnitComboBox()->addItem(displayUnit);
                index ++;
              }
            }
            if (index > -1) {
              pParameter->getUnitComboBox()->setCurrentIndex(index);
              pParameter->setDisplayUnit(displayUnit);
            }
          }
        }
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

void ComponentParameters::commentLinkClicked(QString link)
{
  QUrl linkUrl(link);
  if (linkUrl.scheme().compare("modelica") == 0) {
    link = link.remove("modelica://");
    LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(link);
    if (pLibraryTreeItem) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    }
  } else {
    QDesktopServices::openUrl(link);
  }
}

/*!
 * \brief ComponentParameters::updateComponentParameters
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Checks the list of parameters i.e mParametersList and if the value is changed then sets the new value.
 */
void ComponentParameters::updateComponentParameters()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  bool valueChanged = false;
  // save the Component modifiers
  QMap<QString, QString> oldComponentModifiersMap = mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent);
  // new Component modifiers
  QMap<QString, QString> newComponentModifiersMap = mpComponent->getComponentInfo()->getModifiersMap(pOMCProxy, className, mpComponent);
  QMap<QString, QString> newComponentExtendsModifiersMap;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    QString componentModifierKey = pParameter->getNameLabel()->text();
    QString componentModifierValue = pParameter->getValue();
    // convert the value to display unit
    if (!pParameter->getUnit().isEmpty() && pParameter->getUnit().compare(pParameter->getUnitComboBox()->currentText()) != 0) {
      bool ok = true;
      qreal componentModifierRealValue = componentModifierValue.toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(pParameter->getUnitComboBox()->currentText(), pParameter->getUnit());
        if (convertUnit.unitsCompatible) {
          componentModifierRealValue = Utilities::convertUnit(componentModifierRealValue, convertUnit.offset, convertUnit.scaleFactor);
          componentModifierValue = QString::number(componentModifierRealValue);
        }
      } else { // if expression
        componentModifierValue = Utilities::arrayExpressionUnitConversion(pOMCProxy, componentModifierValue,
                                                                          pParameter->getUnitComboBox()->currentText(),
                                                                          pParameter->getUnit());
      }
    }
    if (pParameter->isValueModified()) {
      valueChanged = true;
      /* If the component is inherited then add the modifier value into the extends. */
      if (mpComponent->isInheritedComponent()) {
        newComponentExtendsModifiersMap.insert(mpComponent->getName() + "." + componentModifierKey, componentModifierValue);
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
        newComponentExtendsModifiersMap.insert(mpComponent->getName() + "." + componentModifierKey, componentModifierValue);
      } else {
        newComponentModifiersMap.insert(componentModifierKey, componentModifierValue);
      }
    }
    // remove the .start or .fixed from modifier key
    if (pParameter->isShowStartAttribute()) {
      if (componentModifierKey.endsWith(".start")) {
        componentModifierKey.chop(QString(".start").length());
      }
      if (componentModifierKey.endsWith(".fixed")) {
        componentModifierKey.chop(QString(".fixed").length());
      }
    }
    // if displayUnit is changed
    if (pParameter->getDisplayUnit().compare(pParameter->getUnitComboBox()->currentText()) != 0) {
      valueChanged = true;
      /* If the component is inherited then add the modifier value into the extends. */
      if (mpComponent->isInheritedComponent()) {
        newComponentExtendsModifiersMap.insert(mpComponent->getName() + "." + componentModifierKey + ".displayUnit",
                                               "\"" + pParameter->getUnitComboBox()->currentText() + "\"");
      } else {
        newComponentModifiersMap.insert(componentModifierKey + ".displayUnit", "\"" + pParameter->getUnitComboBox()->currentText() + "\"");
      }
    }
  }
  // any new modifier is added
  if (!mpModifiersTextBox->text().isEmpty()) {
    QString regexp ("\\s*([A-Za-z0-9._]+\\s*)\\(\\s*([A-Za-z0-9._]+)\\s*=\\s*([A-Za-z0-9._]+)\\s*\\)$");
    QRegExp modifierRegExp (regexp);
    QStringList modifiers = mpModifiersTextBox->text().split(",", QString::SkipEmptyParts);
    foreach (QString modifier, modifiers) {
      modifier = modifier.trimmed();
      if (modifierRegExp.exactMatch(modifier)) {
        valueChanged = true;
        QString componentModifierKey = modifier.mid(0, modifier.indexOf("("));
        QString componentModifierValue = modifier.mid(modifier.indexOf("("));
        newComponentModifiersMap.insert(componentModifierKey, componentModifierValue);
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0,
                                                              GUIMessages::getMessage(GUIMessages::WRONG_MODIFIER).arg(modifier),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    }
  }
  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged) {
    // save the Component extends modifiers
    QMap<QString, QString> oldComponentExtendsModifiersMap;
    if (mpComponent->getReferenceComponent()) {
      QString inheritedClassName;
      inheritedClassName = mpComponent->getReferenceComponent()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      oldComponentExtendsModifiersMap = mpComponent->getGraphicsView()->getModelWidget()->getExtendsModifiersMap(inheritedClassName);
    }
    // create UpdateComponentParametersCommand
    UpdateComponentParametersCommand *pUpdateComponentParametersCommand;
    pUpdateComponentParametersCommand = new UpdateComponentParametersCommand(mpComponent, oldComponentModifiersMap,
                                                                             oldComponentExtendsModifiersMap, newComponentModifiersMap,
                                                                             newComponentExtendsModifiersMap);
    mpComponent->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateComponentParametersCommand);
    mpComponent->getGraphicsView()->getModelWidget()->updateModelText();
    // remove possible dynamic results to see the new static values
    mpComponent->getGraphicsView()->getModelWidget()->removeDynamicResults();
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
 * \param pParent
 */
ComponentAttributes::ComponentAttributes(Component *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  QString className = pComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Component Attributes")).arg(pComponent->getName())
                 .arg(className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
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
  mpAttributesHeading = Utilities::getHeadingLabel(Helper::attributes);
  // set separator line
  mHorizontalLine = Utilities::getHeadingLine();
  // create Type Group Box
  mpTypeGroupBox = new QGroupBox(Helper::type);
  QGridLayout *pTypeGroupBoxLayout = new QGridLayout;
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // dimensions
  mpDimensionsLabel = new Label(tr("Dimensions:"));
  mpDimensionsTextBox = new QLineEdit;
  mpDimensionsTextBox->setToolTip(tr("Array of dimensions e.g [1, 5, 2]"));
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
  QString dimensions = StringHandler::removeFirstLastCurlBrackets(mpComponent->getComponentInfo()->getArrayIndex());
  mpDimensionsTextBox->setText(QString("[%1]").arg(dimensions));
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
      QMessageBox::information(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME).arg(mpNameTextBox->text()), Helper::ok);
      return;
    }
  }
  // check for spaces
  if (StringHandler::containsSpace(mpNameTextBox->text())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("A component name should not have spaces. Please choose another name."), Helper::ok);
    return;
  }
  // check for comma
  if (mpNameTextBox->text().contains(',')) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
  }
  // check for invalid names
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
  QList<QString> result = MainWindow::instance()->getOMCProxy()->parseString(QString("model M N %1; end M;").arg(mpNameTextBox->text()),
                                                                             "M", false);
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
  if (result.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
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
  QString dimensions = StringHandler::removeFirstLastSquareBrackets(mpDimensionsTextBox->text());
  newComponentInfo.setArrayIndex(QString("{%1}").arg(dimensions));
  /* If user has really changed the Component's attributes then push that change on the stack.
   */
  if (oldComponentInfo != newComponentInfo) {
    UpdateComponentAttributesCommand *pUpdateComponentAttributesCommand = new UpdateComponentAttributesCommand(mpComponent, oldComponentInfo,
                                                                                                               newComponentInfo);
    pModelWidget->getUndoStack()->push(pUpdateComponentAttributesCommand);
    pModelWidget->updateModelText();
  }
  accept();
}

/*!
 * \class CompositeModelSubModelAttributes
 * \brief A dialog for displaying SubModel attributes.
 */
/*!
 * \brief CompositeModelSubModelAttributes::CompositeModelSubModelAttributes
 * \param pComponent - pointer to Component
 * \param pParent
 */
CompositeModelSubModelAttributes::CompositeModelSubModelAttributes(Component *pComponent, QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("SubModel Attributes")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpComponent = pComponent;
  setUpDialog();
  initializeDialog();
}

/*!
 * \brief CompositeModelSubModelAttributes::setUpDialog
 * Creates the dialog and set up submodel attributes of the CompositeModel.
 */
void CompositeModelSubModelAttributes::setUpDialog()
{
  // Create the name label and text box
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  mpNameTextBox->setDisabled(true);
  // Create the simulation tool label and combo box
  mpSimulationToolLabel = new Label(tr("Simulation Tool"));
  mpSimulationToolComboBox = new QComboBox;
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::Adams));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::Beast));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::Dymola));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::OpenModelica));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::Simulink));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::WolframSystemModeler));
  mpSimulationToolComboBox->addItem(StringHandler::getSimulationTool(StringHandler::Other));
  connect(mpSimulationToolComboBox, SIGNAL(currentIndexChanged(QString)), SLOT(changeSimulationToolStartCommand(QString)));
  // Create the start command label and text box
  mpStartCommandLabel = new Label(tr("Start Command:"));
  mpStartCommandTextBox = new QLineEdit;
  connect(mpStartCommandTextBox, SIGNAL(textChanged(QString)), SLOT(changeSimulationTool(QString)));
  // Create the model file label and text box
  mpModelFileLabel = new Label(tr("Model File:"));
  mpModelFileTextBox = new QLineEdit;
  mpModelFileTextBox->setDisabled(true);
  // Create the exact step check box
  mpExactStepCheckBox = new QCheckBox(tr("Exact Step"));
  // geometry file label, text box and browse button
  mpGeometryFileLabel = new Label(tr("Geometry File:"));
  mpGeometryFileTextBox = new QLineEdit;
  mpGeometryFileBrowseButton = new QPushButton(Helper::browse);
  mpGeometryFileBrowseButton->setAutoDefault(false);
  connect(mpGeometryFileBrowseButton, SIGNAL(clicked()), this, SLOT(browseGeometryFile()));
  // Model parameters
  mpParametersLayout = new QGridLayout;
  mpParametersLabel = new QLabel("Parameters:");
  mpParametersLayout->addWidget(mpParametersLabel,0,0,1,2);
  mpParametersScrollArea = new QScrollArea;
  mpParametersScrollArea->setWidgetResizable(true);
  mpParametersScrollWidget = new QWidget;
  mpParametersScrollWidget->setLayout(mpParametersLayout);
  mpParametersScrollArea->setWidget(mpParametersScrollWidget);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateSubModelParameters()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  // Create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpNameLabel, 0, 0);
  pMainLayout->addWidget(mpNameTextBox, 0, 1, 1, 2);
  pMainLayout->addWidget(mpModelFileLabel, 1, 0);
  pMainLayout->addWidget(mpModelFileTextBox, 1, 1, 1, 2);
  pMainLayout->addWidget(mpSimulationToolLabel, 2, 0);
  pMainLayout->addWidget(mpSimulationToolComboBox, 2, 1, 1, 2);
  pMainLayout->addWidget(mpStartCommandLabel, 3, 0);
  pMainLayout->addWidget(mpStartCommandTextBox, 3, 1, 1, 2);
  pMainLayout->addWidget(mpExactStepCheckBox, 4, 0 );
  pMainLayout->addWidget(mpGeometryFileLabel, 5, 0);
  pMainLayout->addWidget(mpGeometryFileTextBox, 5, 1);
  pMainLayout->addWidget(mpGeometryFileBrowseButton, 5, 2);
  pMainLayout->addWidget(mpParametersScrollArea,6,0,1,3);
  pMainLayout->addWidget(mpButtonBox, 7, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Initialize the fields with values.
  */
void CompositeModelSubModelAttributes::initializeDialog()
{
  // set Name
  mpNameTextBox->setText(mpComponent->getName());
  // set the start command
  mpStartCommandTextBox->setText(mpComponent->getComponentInfo()->getStartCommand());
  // set the exact step
  mpExactStepCheckBox->setChecked(mpComponent->getComponentInfo()->getExactStep());
  // set the simulation tool of the submodel
  mpSimulationToolComboBox->setCurrentIndex(StringHandler::getSimulationTool(mpStartCommandTextBox->text()));
  // set the model file name
  mpModelFileTextBox->setText(mpComponent->getComponentInfo()->getModelFile());
  // set the geometry file name
  mpGeometryFileTextBox->setText(mpComponent->getComponentInfo()->getGeometryFile());
  // update parameter widgets
  CompositeModelEditor *pEditor = dynamic_cast<CompositeModelEditor*>(mpComponent->getGraphicsView()->getModelWidget()->getEditor());
  QStringList parameters = pEditor->getParameterNames(mpComponent->getName());
  mParameterLabels.clear();
  mParameterLineEdits.clear();
  for(int i=0; i<parameters.size(); ++i) {
      mParameterLabels.append(new QLabel(parameters[i]));
      mParameterLineEdits.append(new QLineEdit(pEditor->getParameterValue(mpComponent->getName(), parameters[i])));
      mpParametersLayout->addWidget(mParameterLabels.last(),i+1,0);
      mpParametersLayout->addWidget(mParameterLineEdits.last(),i+1,1);
  }
  mpParametersScrollWidget->setVisible(!parameters.isEmpty());
  mpParametersLabel->setVisible(!parameters.isEmpty());
}

/*!
 * \brief CompositeModelSubModelAttributes::changeSimulationToolStartCommand
 * Updates the simulation tool start command.\n
 * Slot activated when mpSimulationToolComboBox currentIndexChanged signal is raised.
 * \param tool
 */
void CompositeModelSubModelAttributes::changeSimulationToolStartCommand(QString tool)
{
  mpStartCommandTextBox->setText(StringHandler::getSimulationToolStartCommand(tool, mpStartCommandTextBox->text()));
}

/*!
 * \brief CompositeModelSubModelAttributes::changeSimulationTool
 * Updates the simulation tool.\n
 * Slot activated when mpStartCommandTextBox textChanged signal is raised.
 * \param simulationToolStartCommand
 */
void CompositeModelSubModelAttributes::changeSimulationTool(QString simulationToolStartCommand)
{
  mpSimulationToolComboBox->setCurrentIndex(StringHandler::getSimulationTool(simulationToolStartCommand));
}

/*!
 * \brief CompositeModelSubModelAttributes::browseGeometryFile
 * Updates subModel parameters.\n
 * Slot activated when mpGeometryFileBrowseButton clicked signal is raised.
 */
void CompositeModelSubModelAttributes::browseGeometryFile()
{
  QString geometryFile = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseFile),
                                                       NULL, "", NULL);
  if (geometryFile.isEmpty()) {
    return;
  }
  mpGeometryFileTextBox->setText(geometryFile);
}

/*!
 * \brief CompositeModelSubModelAttributes::updateSubModelParameters
 * Updates subModel parameters.\n
 * Slot activated when mpOkButton clicked signal is raised.
 */
void CompositeModelSubModelAttributes::updateSubModelParameters()
{
  // save the old ComponentInfo
  ComponentInfo oldComponentInfo(mpComponent->getComponentInfo());
  // Create a new ComponentInfo
  ComponentInfo newComponentInfo(mpComponent->getComponentInfo());
  newComponentInfo.setStartCommand(mpStartCommandTextBox->text());
  newComponentInfo.setExactStep(mpExactStepCheckBox->isChecked());
  newComponentInfo.setGeometryFile(mpGeometryFileTextBox->text());


  QStringList parameterNames, oldParameterValues, newParameterValues;
  if(mpComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    BaseEditor *pBaseEditor = mpComponent->getGraphicsView()->getModelWidget()->getEditor();
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pBaseEditor);

    parameterNames = pEditor->getParameterNames(mpComponent->getName());  //Assume submodel; otherwise returned list is empty
    foreach(QString parName, parameterNames) {
      oldParameterValues.append(pEditor->getParameterValue(mpComponent->getName(), parName));
    }

    for(int i=0; i<mParameterLineEdits.size(); ++i) {
      newParameterValues.append(mParameterLineEdits[i]->text());
    }
  }

  // If user has really changed the Component's attributes then push that change on the stack.
  if (oldComponentInfo != newComponentInfo || oldParameterValues != newParameterValues) {
    UpdateSubModelAttributesCommand *pUpdateSubModelAttributesCommand = new UpdateSubModelAttributesCommand(mpComponent, oldComponentInfo,
                                                                                                            newComponentInfo,
                                                                                                            parameterNames,
                                                                                                            oldParameterValues,
                                                                                                            newParameterValues);
    ModelWidget *pModelWidget = mpComponent->getGraphicsView()->getModelWidget();
    pModelWidget->getUndoStack()->push(pUpdateSubModelAttributesCommand);
    pModelWidget->updateModelText();
  }

  accept();
}

/*!
  \class CompositeModelConnectionAttributes
  \brief A dialog for displaying CompositeModel Connection Attributes
  */
/*!
  \param pConnectionLineAnnotation - pointer to LineAnnotation
  \param pMainWindow - pointer to MainWindow
  */
CompositeModelConnectionAttributes::CompositeModelConnectionAttributes(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation,
                                                             bool edit, QWidget *pParent)
  : QDialog(pParent), mpGraphicsView(pGraphicsView), mpConnectionLineAnnotation(pConnectionLineAnnotation), mEdit(edit)
{
  ComponentInfo *pInfo = mpConnectionLineAnnotation->getStartComponent()->getComponentInfo();
  bool tlm = (pInfo->getTLMCausality() == "Bidirectional");
  int dimensions = pInfo->getDimensions();

  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::connectionAttributes));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  mpHeading = Utilities::getHeadingLabel(Helper::connectionAttributes);
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Create the start component class name label and text box
  mpFromLabel = new Label(tr("From:"));
  mpConnectionStartLabel = new Label(mpConnectionLineAnnotation->getStartComponentName());
  // Create the end component class name label and text box
  mpToLabel = new Label(tr("To:"));
  mpConnectionEndLabel = new Label(mpConnectionLineAnnotation->getEndComponentName());
  // Create the delay label and text box
  mpDelayLabel = new Label(tr("Delay:"));
  mpDelayTextBox = new QLineEdit(mpConnectionLineAnnotation->getDelay());
  mpZfLabel = new Label(tr("Zf:"));
  mpZfTextBox = new QLineEdit(mpConnectionLineAnnotation->getZf());
  mpZfrLabel = new Label(tr("Zfr:"));
  mpZfrTextBox = new QLineEdit(mpConnectionLineAnnotation->getZfr());
  // Create the alpha label and text box
  mpAlphapLabel = new Label(tr("Alpha:"));
  mpAlphaTextBox = new QLineEdit(mpConnectionLineAnnotation->getAlpha());
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(createCompositeModelConnection()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpFromLabel, 2, 0);
  pMainLayout->addWidget(mpConnectionStartLabel, 2, 1);
  pMainLayout->addWidget(mpToLabel, 3, 0);
  pMainLayout->addWidget(mpConnectionEndLabel, 3, 1);
  pMainLayout->addWidget(mpDelayLabel, 4, 0);
  pMainLayout->addWidget(mpDelayTextBox, 4, 1);
  if(tlm) {     //Only show TLM parameter widgets if it is a TLM connection
    pMainLayout->addWidget(mpZfLabel,5, 0);
    pMainLayout->addWidget(mpZfTextBox, 5, 1);
    if(dimensions > 1) {        //Only show rotational impedance box for 3D connections
      pMainLayout->addWidget(mpZfrLabel, 6, 0);
      pMainLayout->addWidget(mpZfrTextBox, 6, 1);
    }
    pMainLayout->addWidget(mpAlphapLabel, 7, 0);
    pMainLayout->addWidget(mpAlphaTextBox, 7, 1);
  }
  pMainLayout->addWidget(mpButtonBox, 8, 0, 1, 2, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief CompositeModelConnectionAttributes::createCompositeModelConnection
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Creates a connection
 */
void CompositeModelConnectionAttributes::createCompositeModelConnection()
{
  ComponentInfo *pInfo = mpConnectionLineAnnotation->getStartComponent()->getComponentInfo();
  bool tlm = (pInfo->getTLMCausality() == "Bidirectional");
  int dimensions = pInfo->getDimensions();
  if (mEdit) {
    CompositeModelConnection oldCompositeModelConnection;
    oldCompositeModelConnection.mDelay = mpConnectionLineAnnotation->getDelay();
    oldCompositeModelConnection.mZf = mpConnectionLineAnnotation->getZf();
    oldCompositeModelConnection.mZfr = mpConnectionLineAnnotation->getZfr();
    oldCompositeModelConnection.mAlpha = mpConnectionLineAnnotation->getAlpha();
    CompositeModelConnection newCompositeModelConnection;
    newCompositeModelConnection.mDelay = mpDelayTextBox->text();
    if(tlm) { //Only update TLM parameters if this is a TLM connection
      newCompositeModelConnection.mZf = mpZfTextBox->text();
      if(dimensions>1) { //Only update rotational impedance if this is a 3D connection
        newCompositeModelConnection.mZfr = mpZfrTextBox->text();
      }
      newCompositeModelConnection.mAlpha = mpAlphaTextBox->text();
    }

    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateCompositeModelConnection(mpConnectionLineAnnotation,
                                                                                              oldCompositeModelConnection,
                                                                                              newCompositeModelConnection));
  } else {
    mpConnectionLineAnnotation->setDelay(mpDelayTextBox->text());
    if(tlm) { //Only update TLM parameters if this is a TLM connection
      mpConnectionLineAnnotation->setZf(mpZfTextBox->text());
      if(dimensions > 1) { //Only update rotational impedance if this is a 3D connection
        mpConnectionLineAnnotation->setZfr(mpZfrTextBox->text());
      }
      mpConnectionLineAnnotation->setAlpha(mpAlphaTextBox->text());
    }
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddConnectionCommand(mpConnectionLineAnnotation, true));
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitConnectionAdded(mpConnectionLineAnnotation);
  }
  mpGraphicsView->getModelWidget()->updateModelText();
  accept();
}
