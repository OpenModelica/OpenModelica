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

#include "ElementProperties.h"
#include "MainWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/Commands.h"
#include "Options/OptionsDialog.h"
#include "OMPlot.h"
#include "FlatModelica/Parser.h"

#include <QApplication>
#include <QMenu>
#include <QWidgetAction>
#include <QButtonGroup>
#include <QMessageBox>
#include <QDesktopServices>
#include <QDesktopWidget>
#include <QList>
#include <QStringList>
#include <QStringBuilder>

/*!
 * \class Parameter
 * \brief Defines one parameter. Creates name, value, unit and comment GUI controls.
 */
/*!
 * \brief Parameter::Parameter
 * \param pElement
 * \param showStartAttribute
 * \param tab
 * \param groupBox
 */
Parameter::Parameter(Element *pElement, bool showStartAttribute, QString tab, QString groupBox, ElementParametersOld *pElementParametersOld)
{
  mpElement = pElement;
  mpModelInstanceElement = 0;
  mpElementParametersOld = pElementParametersOld;
  mTab = tab;
  mGroup = groupBox;
  mShowStartAttribute = showStartAttribute;
  mpNameLabel = new Label;
  mpFixedCheckBox = new FixedCheckBox;
  connect(mpFixedCheckBox, SIGNAL(clicked()), SLOT(showFixedMenu()));
  setFixedState("false", true);
  // set the value type based on element type.
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  if (mpElement->getElementInfo()->getClassName().compare("Boolean") == 0) {
    if (mpElement->getChoicesAnnotation().size() > 1 && /* Size should be 2. We always get choices(checkBox, __Dymola_checkBox) */
        (mpElement->getChoicesAnnotation().at(0).compare("true") == 0 || mpElement->getChoicesAnnotation().at(1).compare("true") == 0)) {
      mValueType = Parameter::CheckBox;
    } else {
      mValueType = Parameter::Boolean;
    }
  } else if (pOMCProxy->isBuiltinType(mpElement->getElementInfo()->getClassName())) {
    mValueType = Parameter::Normal;
  } else if (pOMCProxy->isWhat(StringHandler::Enumeration, mpElement->getElementInfo()->getClassName())) {
    mValueType = Parameter::Enumeration;
  } else if (mpElement->getElementInfo()->getReplaceable()) { // replaceable component or short element definition
    mValueType = mpElement->getElementInfo()->getIsElement() ? Parameter::ReplaceableClass : Parameter::ReplaceableComponent;
  } else if (mpElement->getElementInfo()->getIsElement()) { // non replaceable short element definition
    mValueType = Parameter::ReplaceableClass;
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
  // Get unit value
  mUnit = mpElement->getDerivedClassModifierValue("unit");;
  // Get displayUnit value
  QString displayUnit = mpElement->getDerivedClassModifierValue("displayUnit");
  if (displayUnit.isEmpty()) {
    displayUnit = mUnit;
  }
  mDisplayUnit = StringHandler::removeFirstLastQuotes(displayUnit);
  mPreviousUnit = mDisplayUnit;
  QStringList units;
  if (!mUnit.isEmpty()) {
    units << mUnit;
    if (mDisplayUnit.compare(mUnit) != 0) {
      units << mDisplayUnit;
    }
    Utilities::addDefaultDisplayUnit(mUnit, units);
    // add unit prefixes
    if (OMPlot::Plot::prefixableUnit(mUnit)) {
      units << QString("k%1").arg(mUnit)
            << QString("M%1").arg(mUnit)
            << QString("G%1").arg(mUnit)
            << QString("T%1").arg(mUnit)
            << QString("m%1").arg(mUnit)
            << QString("u%1").arg(mUnit)
            << QString("n%1").arg(mUnit)
            << QString("p%1").arg(mUnit);
    }
  }
  mpUnitComboBox = new QComboBox;
  units.removeDuplicates();
  foreach (QString unit, units) {
    mpUnitComboBox->addItem(Utilities::convertUnitToSymbol(unit), unit);
  }
  if (mDisplayUnit.compare(mUnit) != 0) {
    mpUnitComboBox->setCurrentIndex(1);
  }
  connect(mpUnitComboBox, SIGNAL(currentIndexChanged(int)), SLOT(unitComboBoxChanged(int)));
  mpCommentLabel = new Label(mpElement->getElementInfo()->getComment());
}

Parameter::Parameter(ModelInstance::Element *pElement, ElementParameters *pElementParameters)
{
  mpElement = 0;
  mpModelInstanceElement = pElement;
  mpElementParameters = pElementParameters;
  const ModelInstance::DialogAnnotation dialogAnnotation = mpModelInstanceElement->getAnnotation()->getDialogAnnotation();
  mTab = dialogAnnotation.getTab();
  mGroup = dialogAnnotation.getGroup();
  mGroupDefined = !mGroup.isEmpty();
  mEnable = dialogAnnotation.isEnabled();
  mShowStartAttribute = dialogAnnotation.getShowStartAttribute();
  mShowStartAndFixed = mShowStartAttribute;
  mColorSelector = dialogAnnotation.isColorSelector();
  const ModelInstance::Selector loadSelector = dialogAnnotation.getLoadSelector();
  mLoadSelectorFilter = loadSelector.getFilter();
  mLoadSelectorCaption = loadSelector.getCaption();
  const ModelInstance::Selector saveSelector = dialogAnnotation.getSaveSelector();
  mSaveSelectorFilter = saveSelector.getFilter();
  mSaveSelectorCaption = saveSelector.getCaption();
  mGroupImage = dialogAnnotation.getGroupImage();
  if (!mGroupImage.isEmpty()) {
    mGroupImage = MainWindow::instance()->getOMCProxy()->uriToFilename(mGroupImage);
  }
  mConnectorSizing = dialogAnnotation.isConnectorSizing();

  // If mShowStartAttribute is not set then check for start modifier
  if (!mShowStartAndFixed && !isParameter()) {
    mShowStartAndFixed = mpModelInstanceElement->getModifier().hasModifier("start");
  }
  /* if mShowStartAndFixed and group name is empty then set group name to Initialization.
   * else set group name to Parameters for actual parameters or elements that have dialog annotation or replaceable elements.
   */
  if (mShowStartAndFixed && mGroup.isEmpty()) {
    mGroup = "Initialization";
  } else if (mGroup.isEmpty() && (isParameter() || mpModelInstanceElement->getAnnotation()->hasDialogAnnotation() || mpModelInstanceElement->getPrefixes()->getReplaceable())) {
    mGroup = "Parameters";
  }

  mpNameLabel = new Label;
  mpFixedCheckBox = new FixedCheckBox;
  connect(mpFixedCheckBox, SIGNAL(clicked()), SLOT(showFixedMenu()));
  setFixedState("", true);
  // set the value type based on element type.
  if (mpModelInstanceElement->getRootType().compare(QStringLiteral("Boolean")) == 0) {
    if (mpModelInstanceElement->getAnnotation()->getChoices().isCheckBox() || mpModelInstanceElement->getAnnotation()-> getChoices().isDymolaCheckBox()) {
      mValueType = Parameter::CheckBox;
    } else {
      mValueType = Parameter::Boolean;
    }
  } else if (mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isEnumeration()) {
    mValueType = Parameter::Enumeration;
  } else if (mpModelInstanceElement->getPrefixes()->getReplaceable()) {
    // replaceable component or short element definition
    if (mpModelInstanceElement->isShortClassDefinition()) {
      mValueType = Parameter::ReplaceableClass;
    } else {
      mValueType = Parameter::ReplaceableComponent;
    }
    if (mpModelInstanceElement->getModel() || mpModelInstanceElement->isShortClassDefinition()) {
      mpEditRedeclareClassButton = new QToolButton;
      mpEditRedeclareClassButton->setIcon( QIcon(":/Resources/icons/edit-icon.svg"));
      mpEditRedeclareClassButton->setToolTip(tr("Edit"));
      mpEditRedeclareClassButton->setAutoRaise(true);
      connect(mpEditRedeclareClassButton, SIGNAL(clicked()), SLOT(editRedeclareClassButtonClicked()));
    }
  } else if (!mpModelInstanceElement->getAnnotation()->getChoices().getChoices().isEmpty()) {
    mValueType = Parameter::Choices;
  } else if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
    mValueType = Parameter::ChoicesAllMatching;
  } else {
    mValueType = Parameter::Normal;
  }
  mValueCheckBoxModified = false;
  mDefaultValue = "";
  mpFileSelectorButton = new QToolButton;
  mpFileSelectorButton->setText("...");
  mpFileSelectorButton->setToolButtonStyle(Qt::ToolButtonTextOnly);
  connect(mpFileSelectorButton, SIGNAL(clicked()), SLOT(fileSelectorButtonClicked()));
  createValueWidget();
  // Get unit value
  mUnit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "unit");
  // Get displayUnit value
  QString displayUnit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "displayUnit");
  if (displayUnit.isEmpty()) {
    displayUnit = mUnit;
  }
  mDisplayUnit = displayUnit;
  mPreviousUnit = mDisplayUnit;
  QStringList units;
  if (!mUnit.isEmpty()) {
    units << mUnit;
    if (mDisplayUnit.compare(mUnit) != 0) {
      units << mDisplayUnit;
    }
    Utilities::addDefaultDisplayUnit(mUnit, units);
    // add unit prefixes
    if (OMPlot::Plot::prefixableUnit(mUnit)) {
      units << QString("k%1").arg(mUnit)
            << QString("M%1").arg(mUnit)
            << QString("G%1").arg(mUnit)
            << QString("T%1").arg(mUnit)
            << QString("m%1").arg(mUnit)
            << QString("u%1").arg(mUnit)
            << QString("n%1").arg(mUnit)
            << QString("p%1").arg(mUnit);
    }
  }
  mpUnitComboBox = new QComboBox;
  units.removeDuplicates();
  foreach (QString unit, units) {
    mpUnitComboBox->addItem(Utilities::convertUnitToSymbol(unit), unit);
  }
  if (mDisplayUnit.compare(mUnit) != 0) {
    mpUnitComboBox->setCurrentIndex(1);
  }
  connect(mpUnitComboBox, SIGNAL(currentIndexChanged(int)), SLOT(unitComboBoxChanged(int)));
  const QString comment = mpModelInstanceElement->getComment();
  mpCommentLabel = new Label(comment);

  if (mValueType == Parameter::ReplaceableClass) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
    setValueWidget(pReplaceableClass->getBaseClass(), true, mUnit);
  } else if (mValueType == Parameter::ReplaceableComponent) {
    QString value = "redeclare " % mpModelInstanceElement->getType()
                    % " " % mpModelInstanceElement->getName();
    QString modifiers = mpModelInstanceElement->getModifier().getValueWithSubModifiers();
    if (!modifiers.isEmpty()) {
      value = value % "(" % modifiers % ")";
    }
    setValueWidget(value, true, mUnit);
  } else {
    ElementParameters::applyStartFixedAndDisplayUnitModifiers(this, mpModelInstanceElement->getModifier(), true);
  }
  update();
}

/*!
 * \brief Parameter::isParameter
 * Returns true if parameter
 * \return
 */
bool Parameter::isParameter() const
{
  if (mpModelInstanceElement) {
    return mpModelInstanceElement->getPrefixes()->getVariability().compare(QStringLiteral("parameter")) == 0;
  } else {
    return mpElement->getElementInfo()->getVariablity().compare("parameter") == 0;
  }
}

/*!
 * \brief Parameter::updateNameLabel
 * Updates the name label.
 */
void Parameter::updateNameLabel()
{
  if (MainWindow::instance()->isNewApi()) {
    mpNameLabel->setText(mpModelInstanceElement->getName() + (mShowStartAndFixed ? ".start" : ""));
  } else {
    mpNameLabel->setText(mpElement->getName() + (mShowStartAttribute ? ".start" : ""));
  }
}

/*!
 * \brief Parameter::setValueWidget
 * Sets the value and defaultValue for the parameter.
 * \param value
 * \param defaultValue
 * \param fromUnit
 * \param valueModified
 * \param adjustSize
 * \param unitComboBoxChanged
 */
void Parameter::setValueWidget(QString value, bool defaultValue, QString fromUnit, bool valueModified, bool adjustSize, bool unitComboBoxChanged)
{
  /* ticket:5618 if we don't have a literal constant and array of constants
   * then we assume its an expression and don't do any conversions.
   * So just show the unit in the unit drop down list
   */
  if (!unitComboBoxChanged) {
    enableDisableUnitComboBox(value);
  }
  if (Utilities::isValueLiteralConstant(value)) {
    // convert the value to display unit
    if (!fromUnit.isEmpty() && mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString().compare(fromUnit) != 0) {
      bool ok = true;
      qreal realValue = value.toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
        if (convertUnit.unitsCompatible) {
          realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
          value = StringHandler::number(realValue);
        }
      } else { // if expression
        value = Utilities::arrayExpressionUnitConversion(MainWindow::instance()->getOMCProxy(), value, fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
      }
    }
  }
  if (defaultValue) {
    mDefaultValue = value;
  }
  QFontMetrics fm = QFontMetrics(QFont());
  bool signalsState;
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      if (defaultValue) {
        mpValueComboBox->lineEdit()->setPlaceholderText(value);
      } else {
        // update the value combobox index when setting the value on the line edit
        bool state = mpValueComboBox->blockSignals(true);
        int index = mpValueComboBox->findData(value);
        if (index > -1) {
          mpValueComboBox->setCurrentIndex(index);
        } else { // if we fail to find the value in the combobox then add it to the combobox
          mpValueComboBox->insertItem(1, value, value);
        }
        mpValueComboBox->lineEdit()->setText(value);
        mpValueComboBox->lineEdit()->setModified(valueModified);
        mpValueComboBox->blockSignals(state);
      }
      if (adjustSize) {
        /* Set the minimum width so that the value text will be readable.
         * If the items width is greater than the value text than use it.
         */
        fm = QFontMetrics(mpValueComboBox->lineEdit()->font());
#if (QT_VERSION >= QT_VERSION_CHECK(5, 11, 0))
        mpValueComboBox->setMinimumWidth(qMax(fm.horizontalAdvance(value), mpValueComboBox->minimumSizeHint().width()) + 50);
#else // QT_VERSION_CHECK
        mpValueComboBox->setMinimumWidth(qMax(fm.width(value), mpValueComboBox->minimumSizeHint().width()) + 50);
#endif // QT_VERSION_CHECK
      }
      break;
    case Parameter::CheckBox:
      signalsState = mpValueCheckBox->blockSignals(true);
      mpValueCheckBox->setChecked(value.compare("true") == 0);
      mpValueCheckBox->blockSignals(signalsState);
      mValueCheckBoxModified = valueModified;
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
#if (QT_VERSION >= QT_VERSION_CHECK(5, 11, 0))
        mpValueTextBox->setMinimumWidth(fm.horizontalAdvance(value) + 50);
#else // QT_VERSION_CHECK
        mpValueTextBox->setMinimumWidth(fm.width(value) + 50);
#endif // QT_VERSION_CHECK
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
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
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
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
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
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      return mpValueComboBox->lineEdit()->text().trimmed();
    case Parameter::CheckBox:
      return mpValueCheckBox->isChecked() ? "true" : "false";
    case Parameter::Normal:
    default:
      return mpValueTextBox->text().trimmed();
  }
}

void Parameter::setFixedState(QString fixed, bool defaultValue)
{
  mOriginalFixedValue = fixed;
  if (fixed.compare(QStringLiteral("true")) == 0) {
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
  Sets the input field of the parameter enable/disable.
  \param enable
  */
void Parameter::setEnabled(bool enable)
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableComponent:
    case Parameter::ReplaceableClass:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
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
  mpUnitComboBox->setEnabled(enable);
  // if enable is true then enable/disable the unit combobox based on value
  if (enable) {
    enableDisableUnitComboBox(getValue());
  }
  if (mpEditRedeclareClassButton) {
    mpEditRedeclareClassButton->setEnabled(enable);
  }
}

/*!
 * \brief Parameter::update
 * Enable/disable the parameter.
 */
void Parameter::update()
{
  mEnable.evaluate(mpModelInstanceElement->getParentModel());
  setEnabled(mEnable);
}

void Parameter::createValueWidget()
{
  int i;
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className;
  if (MainWindow::instance()->isNewApi()) {
    className = mpModelInstanceElement->getType();
  } else {
    className = mpElement->getElementInfo()->getClassName();
  }
  QString constrainedByClassName = QStringLiteral("$Any");
  QString replaceable = "", replaceableText = "", replaceableChoice = "", parentClassName = "", restriction = "", elementName = "";
  QStringList enumerationLiterals, enumerationLiteralsDisplay, replaceableChoices, choices;

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
      if (MainWindow::instance()->isNewApi()) {
        foreach (auto pModelInstanceElement, mpModelInstanceElement->getModel()->getElements()) {
          if (pModelInstanceElement->isComponent()) {
            auto pModelInstanceComponent = dynamic_cast<ModelInstance::Component*>(pModelInstanceElement);
            enumerationLiterals.append(pModelInstanceComponent->getName());
            enumerationLiteralsDisplay.append(pModelInstanceComponent->getName() % " " % pModelInstanceComponent->getComment());
          }
        }
      } else {
        enumerationLiterals = pOMCProxy->getEnumerationLiterals(className);
        enumerationLiteralsDisplay = enumerationLiterals;
      }
      for (i = 0 ; i < enumerationLiterals.size(); i++) {
        mpValueComboBox->addItem(enumerationLiteralsDisplay[i], className + "." + enumerationLiterals[i]);
      }
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;

    case Parameter::CheckBox:
      mpValueCheckBox = new QCheckBox;
      connect(mpValueCheckBox, SIGNAL(toggled(bool)), SLOT(valueCheckBoxChanged(bool)));
      break;

    case Parameter::ReplaceableComponent:
    case Parameter::ReplaceableClass:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      if (MainWindow::instance()->isNewApi()) {
        if (mValueType == Parameter::ReplaceableComponent || mValueType == Parameter::ReplaceableClass) {
          constrainedByClassName = mpModelInstanceElement->getPrefixes()->getReplaceable()->getConstrainedby();
          if (constrainedByClassName.isEmpty()) {
            constrainedByClassName = mpModelInstanceElement->getType();
          }
        }
        choices = mpModelInstanceElement->getAnnotation()->getChoices().getChoices();
        parentClassName = mpModelInstanceElement->getParentModel()->getName();
        if (mpModelInstanceElement->getModel()) {
          restriction = mpModelInstanceElement->getModel()->getRestriction();
        } else {
          restriction = mpModelInstanceElement->getType();
        }
        elementName = mpModelInstanceElement->getName();
      } else {
        constrainedByClassName = mpElement->getElementInfo()->getConstrainedByClassName();
        if (mpElement->hasChoices()) {
          choices = mpElement->getChoices();
        }
        parentClassName = mpElementParametersOld->getElementParentClassName();
        restriction = mpElement->getElementInfo()->getRestriction();
        elementName = mpElement->getName();
      }

      if (constrainedByClassName.contains(QStringLiteral("$Any"))) {
        constrainedByClassName = className;
      }

      mpValueComboBox = new QComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->addItem("", "");
      // add choices if there are any
      for (i = 0; i < choices.size(); i++) {
        QString choice = choices[i];
        QString comment;
        if (MainWindow::instance()->isNewApi()) {
          comment = choice;
        } else {
          comment = StringHandler::removeFirstLastQuotes(FlatModelica::Parser::getModelicaComment(choice));
        }
        mpValueComboBox->addItem(comment, choice);
      }

      // choicesAllMatching
      if (MainWindow::instance()->isNewApi()) {
        if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
          replaceableChoices = pOMCProxy->getAllSubtypeOf(constrainedByClassName, parentClassName);
        }
      } else {
        // do replaceable only if not choicesAllMatching=false
        // if choicesAllMatching is not defined, consider choicesAllMatching=true
        replaceableChoices = pOMCProxy->getAllSubtypeOf(constrainedByClassName, parentClassName);
      }
      for (i = 0; i < replaceableChoices.size(); i++) {
        replaceableChoice = replaceableChoices[i];
        // if replaceableChoices points to a class in this scope, remove scope
        if (replaceableChoice.startsWith(parentClassName + ".")) {
          replaceableChoice.remove(0, parentClassName.size() + 1);
        }
        if (mValueType == Parameter::ReplaceableClass) {
          replaceable = QString("redeclare %1 %2 = %3").arg(restriction, elementName, replaceableChoice);
          QString str = (pOMCProxy->getClassInformation(replaceableChoices[i])).comment;
          if (!str.isEmpty()) {
            str = " - " + str;
          }
          replaceableText = replaceableChoices[i] + str;
          mpValueComboBox->addItem(replaceableText, replaceable);
        } else if (mValueType == Parameter::ReplaceableComponent) {
          replaceable = QString("redeclare %1 %2").arg(replaceableChoice, elementName);
          mpValueComboBox->addItem(replaceable, replaceable);
        } else {
          mpValueComboBox->addItem(replaceableChoice, replaceableChoice);
        }
      }

      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;

    case Parameter::Normal:
    default:
      mpValueTextBox = new QLineEdit;
      connect(mpValueTextBox, SIGNAL(textEdited(QString)), SLOT(valueTextBoxEdited(QString)));
      break;
  }
}

/*!
 * \brief Parameter::enableDisableUnitComboBox
 * Enables/disables the unit combobox.
 * \param value
 */
void Parameter::enableDisableUnitComboBox(const QString &value)
{
  // Do not do anything when the value is empty OR parameter is not enabled
  if (value.isEmpty() || !mEnable) {
    return;
  }
  /* Enable/disable the unit combobox based on the literalConstant
   * Set the display unit as current when value is literalConstant otherwise use unit
   * ticket:5618 Disable the unit drop down when we have a symbolic parameter
   */
  bool literalConstant = Utilities::isValueLiteralConstant(value);
  mpUnitComboBox->setEnabled(literalConstant);
  /* ticket:5976 don't change the unit combobox when the literalConstant is true
   * We only want to disbale and switch to display unit when literalConstant is false and we got a symbolic or expression parameter.
   */
  if (!literalConstant) {
    bool state = mpUnitComboBox->blockSignals(true);
    int index = mpUnitComboBox->findData(mUnit);
    if (index > -1 && index != mpUnitComboBox->currentIndex()) {
      mpUnitComboBox->setCurrentIndex(index);
      mPreviousUnit = mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString();
    }
    mpUnitComboBox->blockSignals(state);
  }
}

/*!
 * \brief Parameter::updateValueBinding
 * Updates the value binding of the parameter and call updateParameters so depending parameters gets updated.
 * \param value
 */
void Parameter::updateValueBinding(const FlatModelica::Expression expression)
{
  if (MainWindow::instance()->isNewApi()) {
    // update the binding with the new value
    mpModelInstanceElement->setBinding(expression);
    mpElementParameters->updateParameters();
  }
}

/*!
 * \brief Parameter::editRedeclareClassButtonClicked
 * Slot activate when mpEditRedeclareClassButton clicked signal is raised.
 * Opens ElementParameters dialog for the redeclare class.
 */
void Parameter::editRedeclareClassButtonClicked()
{
  QString type;
  if (mpValueComboBox->currentIndex() == 0) {
    if (mValueType == Parameter::ReplaceableComponent) {
      type = mpModelInstanceElement->getType();
    } else if (mValueType == Parameter::ReplaceableClass) {
      auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
      type = pReplaceableClass->getBaseClass();
    }
  } else {
    type = mpModelInstanceElement->getAnnotation()->getChoices().getType(mpValueComboBox->currentIndex() - 1);
  }

  // if type is empty then try to parse the Modelica code of element redeclaration to get the type
  if (type.isEmpty()) {
    if (mValueType == Parameter::ReplaceableComponent) {
      type = FlatModelica::Parser::getTypeFromElementRedeclaration(mpValueComboBox->lineEdit()->text());
    } else if (mValueType == Parameter::ReplaceableClass) {
      type = FlatModelica::Parser::getShortClassTypeFromElementRedeclaration(mpValueComboBox->lineEdit()->text());
    }
  }

  if (type.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Unable to find the redeclare class %1.").arg(type), Helper::ok);
  } else {
    ModelInstance::Model *pCurrentModel = mpModelInstanceElement->getModel();
    const QJsonObject newModelJSON = MainWindow::instance()->getOMCProxy()->getModelInstance(type, mpValueComboBox->lineEdit()->text());
    if (!newModelJSON.isEmpty()) {
      const QJsonObject modifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(mpValueComboBox->lineEdit()->text());
      if (!modifierJSON.isEmpty()) {
        ModelInstance::Modifier elementModifier;
        elementModifier.deserialize(QJsonValue(modifierJSON));
        mpModelInstanceElement->setModifier(elementModifier);
      }
      ModelInstance::Model *pNewModel = new ModelInstance::Model(newModelJSON);
      mpModelInstanceElement->setModel(pNewModel);
      MainWindow::instance()->getProgressBar()->setRange(0, 0);
      MainWindow::instance()->showProgressBar();
      ElementParameters *pElementParameters = new ElementParameters(mpModelInstanceElement, mpElementParameters->getGraphicsView(), mpElementParameters->isInherited(), true, mpElementParameters);
      MainWindow::instance()->hideProgressBar();
      MainWindow::instance()->getStatusBar()->clearMessage();
      if (pElementParameters->exec() == QDialog::Accepted) {
        if (!pElementParameters->getModification().isEmpty()) {
          setValueWidget(pElementParameters->getModification(), false, mUnit, true);
        }
      }
      pElementParameters->deleteLater();
      // reset the modifier
      mpModelInstanceElement->resetModifier();
      // reset the actual model of the element
      mpModelInstanceElement->setModel(pCurrentModel);
      delete pNewModel;
    }
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
 * SLOT activated when mpUnitComboBox currentIndexChanged(int) SIGNAL is raised.\n
 * Updates the value according to the unit selected.
 * \param text
 */
void Parameter::unitComboBoxChanged(int index)
{
  if (!mDefaultValue.isEmpty()) {
    setValueWidget(mDefaultValue, true, mPreviousUnit, false, true, true);
  }
  QString value = getValue();
  if (!value.isEmpty()) {
    setValueWidget(value, false, mPreviousUnit, true, true, true);
  }
  mPreviousUnit = mpUnitComboBox->itemData(index).toString();
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

  QString value = mpValueComboBox->lineEdit()->text();
  if (value.isEmpty()) {
    value = mpValueComboBox->lineEdit()->placeholderText();
  }

  try {
    switch (mValueType) {
      case Parameter::Enumeration:
        updateValueBinding(FlatModelica::Expression(value.toStdString(), index));
        break;
      default:
        updateValueBinding(FlatModelica::Expression::parse(value));
        break;
    }
  } catch (const std::exception &e) {
    qDebug() << "Failed to parse value: " << value;
    qDebug() << e.what();
  }
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
  updateValueBinding(FlatModelica::Expression(toggle));
}

/*!
 * \brief Parameter::valueTextBoxEdited
 * This slot is only called when user manually edits the text.\n
 * \param text
 */
void Parameter::valueTextBoxEdited(const QString &text)
{
  // if we don't have the text we use the default value otherwise the text
  QString value;
  if (text.isEmpty()) {
    value = mDefaultValue;
  } else {
    value = text;
  }

  enableDisableUnitComboBox(value);
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
  mpGroupImageLabel->setScaledContents(true);
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
    mpGroupImageLabel->setMaximumWidth(pixmap.width() / qApp->devicePixelRatio());
    mpGroupImageLabel->setMaximumHeight(pixmap.height() / qApp->devicePixelRatio());
    mpGroupImageLabel->setPixmap(pixmap);
  }
}

/*!
  \class ParametersScrollArea
  \brief Creates a scroll area for each tab of the element parameters dialog.
  */
ParametersScrollArea::ParametersScrollArea()
{
  mpWidget = new QWidget;
  setFrameShape(QFrame::NoFrame);
  setBackgroundRole(QPalette::Base);
  setWidgetResizable(true);
  mGroupBoxesList.clear();
  mpVerticalLayout = new QVBoxLayout;
  mpVerticalLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  mpWidget->setLayout(mpVerticalLayout);
  setWidget(mpWidget);
}

/*!
 * Reimplementation of minimumSizeHint.
 * Finds maximum optimal size for ElementParameters dialog. If the dialog is larger than screen then shows the scrollbars.
 */
QSize ParametersScrollArea::minimumSizeHint() const
{
  QSize size = QWidget::sizeHint();
  // find optimal width and height
#if (QT_VERSION >= QT_VERSION_CHECK(5, 11, 0))
  int screenWidth = QApplication::primaryScreen()->availableGeometry().width() - 100;
  int screenHeight = QApplication::primaryScreen()->availableGeometry().height() - 300;
#else // QT_VERSION_CHECK
  int screenWidth = QApplication::desktop()->availableGeometry().width() - 100;
  int screenHeight = QApplication::desktop()->availableGeometry().height() - 300;
#endif // QT_VERSION_CHECK
  int widgetWidth = mpWidget->minimumSizeHint().width() + (verticalScrollBar()->isVisible() ? verticalScrollBar()->width() : 0);
  size.rwidth() = qMin(screenWidth, widgetWidth);
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
  if (!getGroupBox(pGroupBox->title())) {
    pGroupBox->hide();  /* create a hidden groupbox, we show it when it contains the parameters. */
    mGroupBoxesList.append(pGroupBox);
    mpVerticalLayout->addWidget(pGroupBox);
  }
}

/*!
  Returns the GroupBox by reading the list of GroupBoxes.
  \return the GroupBox
  */
GroupBox* ParametersScrollArea::getGroupBox(const QString &title)
{
  foreach (GroupBox *pGroupBox, mGroupBoxesList) {
    if (pGroupBox->title().compare(title) == 0) {
      return pGroupBox;
    }
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
 * \class ElementParameters
 * \brief A dialog for displaying Element's parameters.
 */
/*!
 * \brief ElementParameters::ElementParameters
 * \param pElement - pointer to ModelInstance::Element
 * \param pGraphicsView
 * \param className
 * \param inherited
 * \param pParent
 */
ElementParameters::ElementParameters(ModelInstance::Element *pElement, GraphicsView *pGraphicsView, bool inherited, bool nested, QWidget *pParent)
  : QDialog(pParent)
{
  const QString className = pGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Element Parameters")).arg(pElement->getQualifiedName()).arg(className));
  mpElement = pElement;
  mpGraphicsView = pGraphicsView;
  mInherited = inherited;
  mNested = nested;
  mModification.clear();
  setUpDialog();
}

/*!
 * \brief ElementParameters::~ElementParameters
 * Deletes the list of Parameter objects.
 */
ElementParameters::~ElementParameters()
{
  qDeleteAll(mParametersList.begin(), mParametersList.end());
  mParametersList.clear();
}

/*!
 * \brief ElementParameters::applyStartFixedAndDisplayUnitModifiers
 * \param pParameter
 * \param modifier
 * \param defaultValue
 */
void ElementParameters::applyStartFixedAndDisplayUnitModifiers(Parameter *pParameter, const ModelInstance::Modifier &modifier, bool defaultValue)
{
  if (pParameter) {
    // if builtin type
    if (MainWindow::instance()->getOMCProxy()->isBuiltinType(pParameter->getModelInstanceElement()->getRootType())) {
      const QString value = modifier.getValue();
      // if value is not empty then use it otherwise try to read start and fixed modifiers
      if (pParameter->isShowStartAttribute() || (value.isEmpty() && !pParameter->isParameter())) {
        bool hasStart = modifier.hasModifier("start");
        bool hasFixed = modifier.hasModifier("fixed");
        if (hasStart || hasFixed) {
          if (!pParameter->isGroupDefined() && !pParameter->isParameter()) {
            pParameter->setGroup("Initialization");
          }
          pParameter->setShowStartAndFixed(true);
        }
        if (hasStart) {
          pParameter->setValueWidget(StringHandler::removeFirstLastQuotes(modifier.getModifier("start")), defaultValue, pParameter->getUnit());
        }
        if (hasFixed) {
          pParameter->setFixedState(StringHandler::removeFirstLastQuotes(modifier.getModifier("fixed")), defaultValue);
        }
      } else {
        pParameter->setValueWidget(value, defaultValue, pParameter->getUnit());
      }
    } else { // if not builtin type then use all sub modifiers
      pParameter->setValueWidget(modifier.getValueWithSubModifiers(), defaultValue, pParameter->getUnit());
    }
    // displayUnit
    QString displayUnit = StringHandler::removeFirstLastQuotes(modifier.getModifier("displayUnit"));
    if (!displayUnit.isEmpty()) {
      int index = pParameter->getUnitComboBox()->findData(displayUnit);
      if (index < 0) {
        // add modifier as additional display unit if compatible
        index = pParameter->getUnitComboBox()->count() - 1;
        OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
        if (index > -1 &&
            (pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(0).toString(), displayUnit)).unitsCompatible) {
          pParameter->getUnitComboBox()->addItem(Utilities::convertUnitToSymbol(displayUnit), displayUnit);
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

/*!
 * \brief ElementParameters::updateParameters
 * Updates the parameters.
 */
void ElementParameters::updateParameters()
{
  foreach (Parameter *pParameter, mParametersList) {
    pParameter->update();
  }
}

/*!
 * \brief ElementParameters::setUpDialog
 * Creates the Dialog and set up all the controls with default values.
 */
void ElementParameters::setUpDialog()
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
  mpComponentNameTextBox = new Label(mpElement->getQualifiedName());
  mpComponentCommentLabel = new Label(Helper::comment);
  mpComponentCommentTextBox = new Label(mpElement->getComment());
  QGridLayout *pComponentGroupBoxLayout = new QGridLayout;
  pComponentGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentGroupBoxLayout->addWidget(mpComponentNameLabel, 0, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentNameTextBox, 0, 1);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentLabel, 1, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentTextBox, 1, 1);
  mpComponentGroupBox->setLayout(pComponentGroupBoxLayout);
  // Component Class Group Box
  mpComponentClassGroupBox = new QGroupBox(tr("Class"));
  // Component class name
  mpComponentClassNameLabel = new Label(Helper::path);
  mpComponentClassNameTextBox = new Label(mpElement->getModel()->getName());
  // Component comment
  mpComponentClassCommentLabel = new Label(Helper::comment);
  mpComponentClassCommentTextBox = new Label;
  mpComponentClassCommentTextBox->setTextFormat(Qt::RichText);
  mpComponentClassCommentTextBox->setTextInteractionFlags(mpComponentClassCommentTextBox->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  mpComponentClassCommentTextBox->setText(mpElement->getModel()->getComment());
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
  createTabsGroupBoxesAndParameters(mpElement->getModel());
  fetchElementExtendsModifiers(mpElement->getModel());
  fetchElementModifiers();
  fetchClassExtendsModifiers();

  foreach (Parameter *pParameter, mParametersList) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
    if (pParametersScrollArea) {
      if (!pParameter->getGroup().isEmpty()) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(pParameter->getGroup());
        if (pGroupBox) {
          /* We hide the groupbox when we create it. Show the groupbox now since it has a parameter. */
          pGroupBox->show();
          QGridLayout *pGroupBoxGridLayout = pGroupBox->getGridLayout();
          int layoutIndex = pGroupBoxGridLayout->rowCount();
          int columnIndex = 0;
          pParameter->updateNameLabel();
          pGroupBoxGridLayout->addWidget(pParameter->getNameLabel(), layoutIndex, columnIndex++);
          if (pParameter->isShowStartAndFixed()) {
            pGroupBoxGridLayout->addWidget(pParameter->getFixedCheckBox(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getValueWidget(), layoutIndex, columnIndex++);

          if (pParameter->getEditRedeclareClassButton()) {
            pGroupBoxGridLayout->addWidget(pParameter->getEditRedeclareClassButton(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }

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
  // Issue #7494. Hide any empty tab. We start the loop from 1 since we don't want to remove General tab which is always the first tab.
  for (int i = 1; i < mpParametersTabWidget->count(); ++i) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(i));
    if (pParametersScrollArea) {
      bool tabIsEmpty = true;
      // The tab is empty if its groupbox layout is empty.
      for (int j = 0; j < pParametersScrollArea->groupBoxesSize(); ++j) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(j);
        if (pGroupBox && !pGroupBox->getGridLayout()->isEmpty()) {
          tabIsEmpty = false;
          break;
        }
      }
      // If the tab is empty then remove it and move one step back.
      if (tabIsEmpty) {
        mpParametersTabWidget->removeTab(i);
        --i;
      }
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateElementParameters()));
  mpOkButton->setDisabled(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpGraphicsView->isVisualizationView());
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
 * \brief ElementParameters::createTabsGroupBoxesAndParameters
 * \param pModelInstance
 */
void ElementParameters::createTabsGroupBoxesAndParameters(ModelInstance::Model *pModelInstance)
{
  foreach (auto pElement, pModelInstance->getElements()) {
    if (pElement->isComponent() || pElement->isShortClassDefinition()) {
      // if we already have the parameter with same name then just skip this one.
      if (findParameter(pElement->getName())) {
        continue;
      }
      /* Ticket #2531
       * Do not show the protected & final parameters.
       */
      if (!pElement->getPrefixes()->isPublic() || pElement->getPrefixes()->isFinal()) {
        continue;
      }
      // if connectorSizing is present then don't show the parameter
      if (pElement->getAnnotation()->getDialogAnnotation().isConnectorSizing()) {
        continue;
      }
      // create the Parameter
      Parameter *pParameter = new Parameter(pElement, this);
      if (!mTabsMap.contains(pParameter->getTab())) {
        ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
        GroupBox *pGroupBox = new GroupBox(pParameter->getGroup());
        // set the group image
        pGroupBox->setGroupImage(pParameter->getGroupImage());
        pParametersScrollArea->addGroupBox(pGroupBox);
        mTabsMap.insert(pParameter->getTab(), mpParametersTabWidget->addTab(pParametersScrollArea, pParameter->getTab()));
      } else {
        ParametersScrollArea *pParametersScrollArea;
        pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(pParameter->getGroup());
        if (pParametersScrollArea && !pGroupBox) {
          pGroupBox = new GroupBox(pParameter->getGroup());
          pParametersScrollArea->addGroupBox(pGroupBox);
        }
        // set the group image
        pGroupBox->setGroupImage(pParameter->getGroupImage());
      }
      mParametersList.append(pParameter);
    } else if (pElement->isExtend() && pElement->getModel()) {
      createTabsGroupBoxesAndParameters(pElement->getModel());
    }
  }
}

/*!
 * \brief ElementParameters::fetchElementExtendsModifiers
 * Fetches the Element's extends modifiers and apply modifier values on the appropriate Parameters.
 * \param pModelInstance
 */
void ElementParameters::fetchElementExtendsModifiers(ModelInstance::Model *pModelInstance)
{
  foreach (auto pElement, pModelInstance->getElements()) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      foreach (auto modifier, pExtend->getModifier().getModifiers()) {
        Parameter *pParameter = findParameter(modifier.getName());
        if (pParameter) {
          /* Ticket #2531
         * Check if parameter is marked final in the extends modifier.
         */
          if (modifier.isFinal()) {
            mParametersList.removeOne(pParameter);
            delete pParameter;
            continue;
          }
          ElementParameters::applyStartFixedAndDisplayUnitModifiers(pParameter, modifier, true);
        }
      }
      fetchElementExtendsModifiers(pExtend->getModel());
    }
  }
}

/*!
 * \brief ElementParameters::fetchElementModifiers
 * Fetches the Element's modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParameters::fetchElementModifiers()
{
  foreach (auto modifier, mpElement->getModifier().getModifiers()) {
    Parameter *pParameter = findParameter(modifier.getName());
    ElementParameters::applyStartFixedAndDisplayUnitModifiers(pParameter, modifier, mInherited);
  }
}

/*!
 * \brief ElementParameters::fetchClassExtendsModifiers
 * If the Element is inherited then fetch the class extends modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParameters::fetchClassExtendsModifiers()
{
  ModelInstance::Model *pClassModelInstance = mpGraphicsView->getModelWidget()->getModelInstance();
  QList<ModelInstance::Element*> elements = pClassModelInstance->getElements();
  foreach (auto pElement, elements) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      if (pExtend->getModel()->getName().compare(mpElement->getParentModel()->getName()) == 0) {
        foreach (auto modifier, pExtend->getModifier().getModifiers()) {
          if (modifier.getName().compare(mpElement->getName()) == 0) {
            foreach (auto subModifier, modifier.getModifiers()) {
              Parameter *pParameter = findParameter(subModifier.getName());
              ElementParameters::applyStartFixedAndDisplayUnitModifiers(pParameter, modifier, false);
            }
          }
          break;
        }
      }
    }
  }
}

/*!
 * \brief ElementParameters::findParameter
 * Finds the Parameter.
 * \param pLibraryTreeItem
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ElementParameters::findParameter(LibraryTreeItem *pLibraryTreeItem, const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if ((pParameter->getElement()->getGraphicsView()->getModelWidget()->getLibraryTreeItem() == pLibraryTreeItem) &&
        (pParameter->getElement()->getName().compare(parameter, caseSensitivity) == 0)) {
      return pParameter;
    }
  }
  return 0;
}

/*!
 * \brief ElementParameters::findParameter
 * Finds the Parameter.
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ElementParameters::findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if (pParameter->getModelInstanceElement()->getName().compare(parameter, caseSensitivity) == 0) {
      return pParameter;
    }
  }
  return 0;
}

/*!
 * \brief ElementParameters::commentLinkClicked
 * \param link
 */
void ElementParameters::commentLinkClicked(QString link)
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
 * \brief ElementParameters::updateElementParameters
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Checks the list of parameters i.e mParametersList and if the value is changed then sets the new value.
 */
void ElementParameters::updateElementParameters()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  ModelInfo oldModelInfo = pModelWidget->createModelInfo();
  QString className = pModelWidget->getLibraryTreeItem()->getNameStructure();
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  bool valueChanged = false;
  QMap<QString, QString> elementModifiersMap;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    // if parameter is not visible then continue
    if (pParameter->getGroup().isEmpty()) {
      continue;
    }
    QString elementModifierKey = pParameter->getNameLabel()->text();
    QString elementModifierValue = pParameter->getValue();
    // convert the value to display unit
    if (!pParameter->getUnit().isEmpty() && pParameter->getUnit().compare(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString()) != 0) {
      bool ok = true;
      qreal elementModifierRealValue = elementModifierValue.toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(), pParameter->getUnit());
        if (convertUnit.unitsCompatible) {
          elementModifierRealValue = Utilities::convertUnit(elementModifierRealValue, convertUnit.offset, convertUnit.scaleFactor);
          elementModifierValue = StringHandler::number(elementModifierRealValue);
        }
      } else { // if expression
        elementModifierValue = Utilities::arrayExpressionUnitConversion(pOMCProxy, elementModifierValue, pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(), pParameter->getUnit());
      }
    }
    if (pParameter->isValueModified()) {
      valueChanged = true;
      elementModifiersMap.insert(elementModifierKey, elementModifierValue);
    }
    if (pParameter->isShowStartAndFixed() && (pParameter->getFixedState().compare(pParameter->getOriginalFixedValue()) != 0)) {
      valueChanged = true;
      elementModifierKey = elementModifierKey.replace(".start", ".fixed");
      elementModifierValue = pParameter->getFixedState();
      elementModifiersMap.insert(elementModifierKey, elementModifierValue);
    }
    // remove the .start or .fixed from modifier key
    if (pParameter->isShowStartAndFixed()) {
      if (elementModifierKey.endsWith(".start")) {
        elementModifierKey.chop(QString(".start").length());
      }
      if (elementModifierKey.endsWith(".fixed")) {
        elementModifierKey.chop(QString(".fixed").length());
      }
    }
    // if displayUnit is changed
    const QString unit = pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString();
    if (pParameter->getUnitComboBox()->isEnabled() && !unit.isEmpty() && pParameter->getDisplayUnit().compare(unit) != 0) {
      valueChanged = true;
      elementModifiersMap.insert(elementModifierKey % ".displayUnit", "\"" + unit + "\"");
    }
  }
  // any new modifier is added
  if (!mpModifiersTextBox->text().isEmpty()) {
    QString regexp ("\\s*([A-Za-z0-9._]+\\s*)\\(\\s*([A-Za-z0-9._]+)\\s*=\\s*([A-Za-z0-9._]+)\\s*\\)$");
    QRegExp modifierRegExp (regexp);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
    QStringList modifiers = mpModifiersTextBox->text().split(",", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
    QStringList modifiers = mpModifiersTextBox->text().split(",", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
    foreach (QString modifier, modifiers) {
      modifier = modifier.trimmed();
      if (modifierRegExp.exactMatch(modifier)) {
        valueChanged = true;
        QString elementModifierKey = modifier.mid(0, modifier.indexOf("("));
        QString elementModifierValue = modifier.mid(modifier.indexOf("("));
        elementModifiersMap.insert(elementModifierKey, elementModifierValue);
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, GUIMessages::getMessage(GUIMessages::WRONG_MODIFIER).arg(modifier),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    }
  }
  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged) {
    if (mNested) {
      QStringList modifications;
      QMap<QString, QString>::iterator newElementModifier;
      for (newElementModifier = elementModifiersMap.begin(); newElementModifier != elementModifiersMap.end(); ++newElementModifier) {
        QString modifierValue = newElementModifier.value().trimmed();
        if (modifierValue.startsWith("(") && modifierValue.contains("=")) {
          modifications.append(newElementModifier.key() % modifierValue);
        } else {
          modifications.append(newElementModifier.key() % "=" % modifierValue);
        }
      }
      mModification = "(" % modifications.join(",") % ")";
    } else {
      // apply the new Component modifiers if any
      QMap<QString, QString>::iterator newElementModifier;
      for (newElementModifier = elementModifiersMap.begin(); newElementModifier != elementModifiersMap.end(); ++newElementModifier) {
        QString modifierValue = newElementModifier.value();
        QString modifierKey = QString(mpElement->getName() % "." % newElementModifier.key());
        // if the element is inherited then add the modifier value into the extends.
        if (mInherited) {
          pOMCProxy->setExtendsModifierValue(className, mpElement->getParentModel()->getName(), modifierKey, modifierValue);
        } else {
          pOMCProxy->setElementModifierValue(className, modifierKey, modifierValue);
        }
      }
      ModelInfo newModelInfo = pModelWidget->createModelInfo();
      pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo,
                                                            QString("Update Element %1 Parameters").arg(mpElement->getName())));
      pModelWidget->updateModelText();
    }
  }
  accept();
}

/*!
 * \brief ElementParameters::reject
 * Reimplementation of QDialog::reject()
 */
void ElementParameters::reject()
{
  foreach (Parameter *pParameter, mParametersList) {
    // reset any changed parameter binding
    if (pParameter->isValueModified()) {
      pParameter->getModelInstanceElement()->resetBinding();
    }
  }
  QDialog::reject();
}

/*!
 * \class ElementParameters
 * \brief A dialog for displaying Element's parameters.
 */
/*!
 * \brief ElementParameters::ElementParameters
 * \param pElement - pointer to Element
 * \param pParent
 */
ElementParametersOld::ElementParametersOld(Element *pElement, QWidget *pParent)
  : QDialog(pParent)
{
  QString className = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName).arg(tr("Element Parameters")).arg(pElement->getName()).arg(className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpElement = pElement;
  setUpDialog();
}

/*!
 * \brief ElementParameters::~ElementParameters
 * Deletes the list of Parameter objects.
 */
ElementParametersOld::~ElementParametersOld()
{
  qDeleteAll(mParametersList.begin(), mParametersList.end());
  mParametersList.clear();
}

/*!
 * \brief ElementParametersOld::getElementParentClassName
 * Returns the class name where the component is defined.
 * \return
 */
QString ElementParametersOld::getElementParentClassName() const
{
  QString parentClassName = mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  if (mpElement->isInheritedElement() && mpElement->getReferenceElement() && mpElement->getReferenceElement()->getGraphicsView()) {
    parentClassName = mpElement->getReferenceElement()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  }
  return parentClassName;
}

/*!
  Creates the Dialog and set up all the controls with default values.
  */
void ElementParametersOld::setUpDialog()
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
  mpComponentNameTextBox = new Label(mpElement->getName());
  mpComponentCommentLabel = new Label(Helper::comment);
  mpComponentCommentTextBox = new Label(mpElement->getComment());
  QGridLayout *pComponentGroupBoxLayout = new QGridLayout;
  pComponentGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentGroupBoxLayout->addWidget(mpComponentNameLabel, 0, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentNameTextBox, 0, 1);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentLabel, 1, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentTextBox, 1, 1);
  mpComponentGroupBox->setLayout(pComponentGroupBoxLayout);
  // Component Class Group Box
  mpComponentClassGroupBox = new QGroupBox(tr("Class"));
  // Component class name
  mpComponentClassNameLabel = new Label(Helper::path);
  mpComponentClassNameTextBox = new Label(mpElement->getElementInfo()->getClassName());
  // Component comment
  mpComponentClassCommentLabel = new Label(Helper::comment);
  mpComponentClassCommentTextBox = new Label;
  mpComponentClassCommentTextBox->setTextFormat(Qt::RichText);
  mpComponentClassCommentTextBox->setTextInteractionFlags(mpComponentClassCommentTextBox->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  if (mpElement->getLibraryTreeItem()) {
    mpComponentClassCommentTextBox->setText(mpElement->getLibraryTreeItem()->mClassInformation.comment);
  } else {
    mpComponentClassCommentTextBox->setText(mpElement->getModel()->getComment());
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
  createTabsGroupBoxesAndParameters(mpElement->getLibraryTreeItem());
  /* We append the actual Element's parameters first so that they appear first on the list.
   * For that we use QList insert instead of append in ElementParameters::createTabsGroupBoxesAndParametersHelper() function.
   * Modelica.Electrical.Analog.Basic.Resistor order is wrong if we don't use insert.
   */
  createTabsGroupBoxesAndParametersHelper(mpElement->getLibraryTreeItem(), true);
  fetchElementModifiers();
  fetchElementExtendsModifiers();

  foreach (Parameter *pParameter, mParametersList) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
    if (pParametersScrollArea) {
      if (!pParameter->getGroup().isEmpty()) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(pParameter->getGroup());
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
  // Issue #7494. Hide any empty tab.
  for (int i = 0; i < mpParametersTabWidget->count(); ++i) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(i));
    if (pParametersScrollArea) {
      bool tabIsEmpty = true;
      // The tab is empty if its groupbox layout is empty.
      for (int j = 0; j < pParametersScrollArea->groupBoxesSize(); ++j) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(j);
        if (pGroupBox && !pGroupBox->getGridLayout()->isEmpty()) {
          tabIsEmpty = false;
          break;
        }
      }
      // If the tab is empty then remove it and move one step back.
      if (tabIsEmpty) {
        mpParametersTabWidget->removeTab(i);
        --i;
      }
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateElementParameters()));
  if (mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpElement->getGraphicsView()->isVisualizationView()) {
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
 * \brief ElementParameters::createTabsGroupBoxesAndParameters
 * Loops over the inherited classes of the Element.
 * \param pLibraryTreeItem
 * \see ElementParameters::createTabsGroupBoxesAndParametersHelper()
 */
void ElementParametersOld::createTabsGroupBoxesAndParameters(LibraryTreeItem *pLibraryTreeItem)
{
  foreach (LibraryTreeItem *pInheritedLibraryTreeItem, pLibraryTreeItem->getModelWidget()->getInheritedClassesList()) {
    createTabsGroupBoxesAndParameters(pInheritedLibraryTreeItem);
    createTabsGroupBoxesAndParametersHelper(pInheritedLibraryTreeItem);
  }
}

/*!
 * \brief ElementParameters::createTabsGroupBoxesAndParametersHelper
 * Creates the dynamic tabs for QTabWidget and QGroupBoxes within them.
 * Creats the parameters and adds them to the appropriate tab and groupbox.
 * \param pLibraryTreeItem
 * \param useInsert - if true we use QList insert instead of append.
 * \see ElementParameters::createTabsGroupBoxesAndParameters()
 */
void ElementParametersOld::createTabsGroupBoxesAndParametersHelper(LibraryTreeItem *pLibraryTreeItem, bool useInsert)
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
              if (pParameter->getGroup().isEmpty()) {
                pParameter->setGroup("Initialization");
              }
              pParameter->setShowStartAttribute(true);
              pParameter->setValueWidget(start, true, pParameter->getUnit());
            }
          } else if (extendsModifiersIterator.key().compare(parameterName + ".fixed") == 0) {
            QString fixed = extendsModifiersIterator.value();
            if (!fixed.isEmpty()) {
              if (pParameter->getGroup().isEmpty()) {
                pParameter->setGroup("Initialization");
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
  foreach (Element *pElement, pLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getElementsList()) {
    // if we already have the parameter from one of the inherited class then just skip this one.
    if (findParameter(pElement->getName())) {
      continue;
    }
    /* Ticket #2531
     * Do not show the protected & final parameters.
     */
    if (pElement->getElementInfo()->getProtected() || pElement->getElementInfo()->getFinal()) {
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
    bool isParameter = (pElement->getElementInfo()->getVariablity().compare("parameter") == 0);
    // If not a parameter then check for start and fixed bindings. See Modelica.Electrical.Analog.Basic.Resistor parameter R.
    if (!isParameter) {
      OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
      QString className = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      QMap<QString, QString> modifiers = pElement->getElementInfo()->getModifiersMap(pOMCProxy, className, pElement);
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
    QStringList dialogAnnotation = pElement->getDialogAnnotation();
    QString groupImage = "";
    bool connectorSizing = false;
    if (dialogAnnotation.size() > 10) {
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
      // get the connectorSizing
      connectorSizing = (dialogAnnotation.at(10).compare("true") == 0);
    }
    // if connectorSizing is present then don't show the parameter
    if (connectorSizing) {
      continue;
    }
    // if showStartAttribute true and group name is empty or Parameters then we should make group name Initialization
    if (showStartAttribute && groupBox.isEmpty()) {
      groupBox = "Initialization";
    } else if (groupBox.isEmpty() && (isParameter || (dialogAnnotation.size() > 0) || (pElement->getElementInfo()->getReplaceable()))) {
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
    Parameter *pParameter = new Parameter(pElement, showStartAttribute, tab, groupBox, this);
    pParameter->setEnabled(enable);
    pParameter->setLoadSelectorFilter(loadSelectorFilter);
    pParameter->setLoadSelectorCaption(loadSelectorCaption);
    pParameter->setSaveSelectorFilter(saveSelectorFilter);
    pParameter->setSaveSelectorCaption(saveSelectorCaption);
    if (pParameter->getValueType() == Parameter::ReplaceableClass) {
      QString className = pElement->getElementInfo()->getClassName();
      QString comment = "";
      if (pElement->getLibraryTreeItem()) {
        comment = pElement->getLibraryTreeItem()->mClassInformation.comment;
      } else {
        comment = (pOMCProxy->getClassInformation(className)).comment;
      }
      pParameter->setValueWidget(comment.isEmpty() ? className : QString("%1 - %2").arg(className, comment), true, pParameter->getUnit());
    } else if (pParameter->getValueType() == Parameter::ReplaceableComponent) {
      pParameter->setValueWidget(QString("replaceable %1 %2").arg(pElement->getElementInfo()->getClassName(), pElement->getName()), true, pParameter->getUnit());
    } else {
      QString elementDefinedInClass = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      QString value = pElement->getElementInfo()->getParameterValue(pOMCProxy, elementDefinedInClass);
      pParameter->setValueWidget(value, true, pParameter->getUnit());
    }
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
 * \brief ElementParameters::fetchElementExtendsModifiers
 * Fetches the Element's extends modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParametersOld::fetchElementExtendsModifiers()
{
  if (mpElement->getReferenceElement()) {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QString inheritedClassName;
    inheritedClassName = mpElement->getReferenceElement()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    QMap<QString, QString> extendsModifiersMap = mpElement->getGraphicsView()->getModelWidget()->getExtendsModifiersMap(inheritedClassName);
    QMap<QString, QString>::iterator extendsModifiersIterator;
    for (extendsModifiersIterator = extendsModifiersMap.begin(); extendsModifiersIterator != extendsModifiersMap.end(); ++extendsModifiersIterator) {
      QString elementName = StringHandler::getFirstWordBeforeDot(extendsModifiersIterator.key());
      if (mpElement->getName().compare(elementName) == 0) {
        /* Ticket #4095
         * Handle parameters display of inherited elements.
         */
        QString parameterName = extendsModifiersIterator.key();
        Parameter *pParameter = findParameter(StringHandler::removeFirstWordAfterDot(parameterName));
        if (pParameter) {
          if (pParameter->isShowStartAttribute()) {
            if (extendsModifiersIterator.key().compare(parameterName + ".start") == 0) {
              QString start = extendsModifiersIterator.value();
              if (!start.isEmpty()) {
                if (pParameter->getGroup().isEmpty()) {
                  pParameter->setGroup("Initialization");
                }
                pParameter->setShowStartAttribute(true);
                pParameter->setValueWidget(start, false, pParameter->getUnit());
              }
            } else if (extendsModifiersIterator.key().compare(parameterName + ".fixed") == 0) {
              QString fixed = extendsModifiersIterator.value();
              if (!fixed.isEmpty()) {
                if (pParameter->getGroup().isEmpty()) {
                  pParameter->setGroup("Initialization");
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
            int index = pParameter->getUnitComboBox()->findData(displayUnit);
            if (index < 0) {
              // add extends modifier as additional display unit if compatible
              index = pParameter->getUnitComboBox()->count() - 1;
              if (index > -1 &&
                  (pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(0).toString(), displayUnit)).unitsCompatible) {
                pParameter->getUnitComboBox()->addItem(Utilities::convertUnitToSymbol(displayUnit), displayUnit);
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
 * \brief ElementParameters::fetchElementModifiers
 * Fetches the Element's modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParametersOld::fetchElementModifiers()
{
  Element *pElement = mpElement;
  if (mpElement->getReferenceElement()) {
    pElement = mpElement->getReferenceElement();
  }
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QMap<QString, QString> modifiers = pElement->getElementInfo()->getModifiersMap(pOMCProxy, className, mpElement);
  QMap<QString, QString>::iterator modifiersIterator;
  for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
    QString parameterName = StringHandler::getFirstWordBeforeDot(modifiersIterator.key());
    Parameter *pParameter = findParameter(parameterName);
    if (pParameter) {
      if (pParameter->isShowStartAttribute()) {
        if (modifiersIterator.key().compare(parameterName + ".start") == 0) {
          QString start = modifiersIterator.value();
          if (!start.isEmpty()) {
            if (pParameter->getGroup().isEmpty()) {
              pParameter->setGroup("Initialization");
            }
            pParameter->setShowStartAttribute(true);
            pParameter->setValueWidget(start, mpElement->getReferenceElement() ? true : false, pParameter->getUnit());
          }
        } else if (modifiersIterator.key().compare(parameterName + ".fixed") == 0) {
          QString fixed = modifiersIterator.value();
          if (!fixed.isEmpty()) {
            if (pParameter->getGroup().isEmpty()) {
              pParameter->setGroup("Initialization");
            }
            pParameter->setShowStartAttribute(true);
            pParameter->setFixedState(fixed, mpElement->getReferenceElement() ? true : false);
          }
        }
      } else if (modifiersIterator.key().compare(parameterName) == 0) {
        pParameter->setValueWidget(modifiersIterator.value(), mpElement->getReferenceElement() ? true : false, pParameter->getUnit());
      }
      if (modifiersIterator.key().compare(parameterName + ".displayUnit") == 0) {
        QString displayUnit = StringHandler::removeFirstLastQuotes(modifiersIterator.value());
        int index = pParameter->getUnitComboBox()->findData(displayUnit);
        if (index < 0) {
          // add modifier as additional display unit if compatible
          index = pParameter->getUnitComboBox()->count() - 1;
          if (index > -1 &&
              (pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(0).toString(), displayUnit)).unitsCompatible) {
            pParameter->getUnitComboBox()->addItem(Utilities::convertUnitToSymbol(displayUnit), displayUnit);
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

/*!
 * \brief ElementParameters::findParameter
 * Finds the Parameter.
 * \param pLibraryTreeItem
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ElementParametersOld::findParameter(LibraryTreeItem *pLibraryTreeItem, const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if ((pParameter->getElement()->getGraphicsView()->getModelWidget()->getLibraryTreeItem() == pLibraryTreeItem) &&
        (pParameter->getElement()->getName().compare(parameter, caseSensitivity) == 0)) {
      return pParameter;
    }
  }
  return 0;
}

/*!
 * \brief ElementParameters::findParameter
 * Finds the Parameter.
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ElementParametersOld::findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if (pParameter->getElement()->getName().compare(parameter, caseSensitivity) == 0) {
      return pParameter;
    }
  }
  return 0;
}

void ElementParametersOld::commentLinkClicked(QString link)
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
 * \brief ElementParameters::updateElementParameters
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Checks the list of parameters i.e mParametersList and if the value is changed then sets the new value.
 */
void ElementParametersOld::updateElementParameters()
{
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  bool valueChanged = false;
  // save the Element modifiers
  QMap<QString, QString> oldElementModifiersMap = mpElement->getElementInfo()->getModifiersMap(pOMCProxy, className, mpElement);
  // new Element modifiers
  QMap<QString, QString> newElementModifiersMap = mpElement->getElementInfo()->getModifiersMap(pOMCProxy, className, mpElement);
  QMap<QString, QString> newElementExtendsModifiersMap;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    QString elementModifierKey = pParameter->getNameLabel()->text();
    QString elementModifierValue = pParameter->getValue();
    // convert the value to display unit
    if (!pParameter->getUnit().isEmpty() && pParameter->getUnit().compare(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString()) != 0) {
      bool ok = true;
      qreal elementModifierRealValue = elementModifierValue.toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(), pParameter->getUnit());
        if (convertUnit.unitsCompatible) {
          elementModifierRealValue = Utilities::convertUnit(elementModifierRealValue, convertUnit.offset, convertUnit.scaleFactor);
          elementModifierValue = StringHandler::number(elementModifierRealValue);
        }
      } else { // if expression
        elementModifierValue = Utilities::arrayExpressionUnitConversion(pOMCProxy, elementModifierValue, pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(), pParameter->getUnit());
      }
    }
    if (pParameter->isValueModified()) {
      valueChanged = true;
      /* If the element is inherited then add the modifier value into the extends. */
      if (mpElement->isInheritedElement()) {
        newElementExtendsModifiersMap.insert(mpElement->getName() + "." + elementModifierKey, elementModifierValue);
      } else {
        newElementModifiersMap.insert(elementModifierKey, elementModifierValue);
      }
    }
    if (pParameter->isShowStartAttribute() && (pParameter->getFixedState().compare(pParameter->getOriginalFixedValue()) != 0)) {
      valueChanged = true;
      elementModifierKey = elementModifierKey.replace(".start", ".fixed");
      elementModifierValue = pParameter->getFixedState();
      /* If the element is inherited then add the modifier value into the extends. */
      if (mpElement->isInheritedElement()) {
        newElementExtendsModifiersMap.insert(mpElement->getName() + "." + elementModifierKey, elementModifierValue);
      } else {
        newElementModifiersMap.insert(elementModifierKey, elementModifierValue);
      }
    }
    // remove the .start or .fixed from modifier key
    if (pParameter->isShowStartAttribute()) {
      if (elementModifierKey.endsWith(".start")) {
        elementModifierKey.chop(QString(".start").length());
      }
      if (elementModifierKey.endsWith(".fixed")) {
        elementModifierKey.chop(QString(".fixed").length());
      }
    }
    // if displayUnit is changed
    if (pParameter->getUnitComboBox()->isEnabled() && pParameter->getDisplayUnit().compare(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString()) != 0) {
      valueChanged = true;
      /* If the element is inherited then add the modifier value into the extends. */
      if (mpElement->isInheritedElement()) {
        newElementExtendsModifiersMap.insert(mpElement->getName() + "." + elementModifierKey + ".displayUnit",
                                             "\"" + pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString() + "\"");
      } else {
        newElementModifiersMap.insert(elementModifierKey + ".displayUnit", "\"" + pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString() + "\"");
      }
    }
  }
  // any new modifier is added
  if (!mpModifiersTextBox->text().isEmpty()) {
    QString regexp ("\\s*([A-Za-z0-9._]+\\s*)\\(\\s*([A-Za-z0-9._]+)\\s*=\\s*([A-Za-z0-9._]+)\\s*\\)$");
    QRegExp modifierRegExp (regexp);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 14, 0))
    QStringList modifiers = mpModifiersTextBox->text().split(",", Qt::SkipEmptyParts);
#else // QT_VERSION_CHECK
    QStringList modifiers = mpModifiersTextBox->text().split(",", QString::SkipEmptyParts);
#endif // QT_VERSION_CHECK
    foreach (QString modifier, modifiers) {
      modifier = modifier.trimmed();
      if (modifierRegExp.exactMatch(modifier)) {
        valueChanged = true;
        QString elementModifierKey = modifier.mid(0, modifier.indexOf("("));
        QString elementModifierValue = modifier.mid(modifier.indexOf("("));
        newElementModifiersMap.insert(elementModifierKey, elementModifierValue);
      } else {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              GUIMessages::getMessage(GUIMessages::WRONG_MODIFIER).arg(modifier),
                                                              Helper::scriptingKind, Helper::errorLevel));
      }
    }
  }
  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged) {
    // save the Element extends modifiers
    QMap<QString, QString> oldElementExtendsModifiersMap;
    if (mpElement->getReferenceElement()) {
      QString inheritedClassName;
      inheritedClassName = mpElement->getReferenceElement()->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      oldElementExtendsModifiersMap = mpElement->getGraphicsView()->getModelWidget()->getExtendsModifiersMap(inheritedClassName);
    }
    // create UpdateElementParametersCommand
    UpdateElementParametersCommand *pUpdateElementParametersCommand;
    pUpdateElementParametersCommand = new UpdateElementParametersCommand(mpElement, oldElementModifiersMap, oldElementExtendsModifiersMap,
                                                                         newElementModifiersMap, newElementExtendsModifiersMap);
    mpElement->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateElementParametersCommand);
    mpElement->getGraphicsView()->getModelWidget()->updateModelText();
  }
  accept();
}

/*!
 * \class ElementAttributes
 * \brief A dialog for displaying elements attributes like visibility, stream, casuality etc.
 */
/*!
 * \brief ElementAttributes::ElementAttributes
 * \param pElement
 * \param pParent
 */
ElementAttributes::ElementAttributes(Element *pElement, QWidget *pParent)
  : QDialog(pParent)
{
  QString className = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName, tr("Element Attributes"), pElement->getName(), className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpElement = pElement;
  setUpDialog();
  initializeDialog();
}

/*!
 * \brief ElementAttributes::setUpDialog
 * Creates the Dialog and set up all the controls with default values.
 */
void ElementAttributes::setUpDialog()
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
  mpVariabilityButtonGroup = new QButtonGroup(this);
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
  mpCausalityButtonGroup = new QButtonGroup(this);
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
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateElementAttributes()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  if (mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpElement->isInheritedElement()) {
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
 * \brief ElementAttributes::initializeDialog
 * Initialize the fields with default values.
 */
void ElementAttributes::initializeDialog()
{
  if (MainWindow::instance()->isNewApi()) {
    // get Class Name
    mpNameTextBox->setText(mpElement->getModelComponent()->getName());
    mpNameTextBox->setCursorPosition(0);
    // get dimensions
    QString dimensions = mpElement->getModelComponent()->getDimensions().getAbsynDimensionsString();
    mpDimensionsTextBox->setText(QString("[%1]").arg(dimensions));
    // get Comment
    mpCommentTextBox->setText(mpElement->getModelComponent()->getComment());
    mpCommentTextBox->setCursorPosition(0);
    // get classname
    mpPathTextBox->setText(mpElement->getModelComponent()->getType());
    // get Variability
    const QString variability = mpElement->getModelComponent()->getPrefixes()->getVariability();
    if (variability.compare(QStringLiteral("constant")) == 0) {
      mpConstantRadio->setChecked(true);
    } else if (variability.compare(QStringLiteral("parameter")) == 0) {
      mpParameterRadio->setChecked(true);
    } else if (variability.compare(QStringLiteral("discrete")) == 0) {
      mpDiscreteRadio->setChecked(true);
    } else {
      mpDefaultRadio->setChecked(true);
    }
    // get Properties
    mpFinalCheckBox->setChecked(mpElement->getModelComponent()->getPrefixes()->isFinal());
    mpProtectedCheckBox->setChecked(!mpElement->getModelComponent()->getPrefixes()->isPublic());
    mpReplaceAbleCheckBox->setChecked(mpElement->getModelComponent()->getPrefixes()->getReplaceable());
    // get Casuality
    const QString direction = mpElement->getModelComponent()->getPrefixes()->getDirection();
    if (direction.compare(QStringLiteral("input")) == 0) {
      mpInputRadio->setChecked(true);
    } else if (direction.compare(QStringLiteral("output")) == 0) {
      mpOutputRadio->setChecked(true);
    } else {
      mpNoneRadio->setChecked(true);
    }
    // get InnerOuter
    mpInnerCheckBox->setChecked(mpElement->getModelComponent()->getPrefixes()->isInner());
    mpOuterCheckBox->setChecked(mpElement->getModelComponent()->getPrefixes()->isOuter());
  } else {
    // get Class Name
    mpNameTextBox->setText(mpElement->getElementInfo()->getName());
    mpNameTextBox->setCursorPosition(0);
    // get dimensions
    QString dimensions = mpElement->getElementInfo()->getArrayIndex();
    mpDimensionsTextBox->setText(QString("[%1]").arg(dimensions));
    // get Comment
    mpCommentTextBox->setText(mpElement->getElementInfo()->getComment());
    mpCommentTextBox->setCursorPosition(0);
    // get classname
    mpPathTextBox->setText(mpElement->getElementInfo()->getClassName());
    // get Variability
    if (mpElement->getElementInfo()->getVariablity() == "constant") {
      mpConstantRadio->setChecked(true);
    } else if (mpElement->getElementInfo()->getVariablity() == "parameter") {
      mpParameterRadio->setChecked(true);
    } else if (mpElement->getElementInfo()->getVariablity() == "discrete") {
      mpDiscreteRadio->setChecked(true);
    } else {
      mpDefaultRadio->setChecked(true);
    }
    // get Properties
    mpFinalCheckBox->setChecked(mpElement->getElementInfo()->getFinal());
    mpProtectedCheckBox->setChecked(mpElement->getElementInfo()->getProtected());
    mpReplaceAbleCheckBox->setChecked(mpElement->getElementInfo()->getReplaceable());
    mIsFlow = mpElement->getElementInfo()->getFlow() ? "true" : "false";
    // get Casuality
    if (mpElement->getElementInfo()->getCausality() == "input") {
      mpInputRadio->setChecked(true);
    } else if (mpElement->getElementInfo()->getCausality() == "output") {
      mpOutputRadio->setChecked(true);
    } else {
      mpNoneRadio->setChecked(true);
    }
    // get InnerOuter
    mpInnerCheckBox->setChecked(mpElement->getElementInfo()->getInner());
    mpOuterCheckBox->setChecked(mpElement->getElementInfo()->getOuter());
  }
}

/*!
 * \brief ElementAttributes::updateElementAttributes
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Updates the element attributes.
 */
void ElementAttributes::updateElementAttributes()
{
  ModelWidget *pModelWidget = mpElement->getGraphicsView()->getModelWidget();
  /* Check the same element name problem before setting any attributes. */
  if (mpElement->getName().compare(mpNameTextBox->text()) != 0) {
    if (!mpElement->getGraphicsView()->checkElementName(mpElement->getClassName(), mpNameTextBox->text())) {
      QMessageBox::information(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME).arg(mpNameTextBox->text()), Helper::ok);
      return;
    }
  }
  // check for spaces
  if (StringHandler::containsSpace(mpNameTextBox->text())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("A component name should not have spaces. Please choose another name."), Helper::ok);
    return;
  }
  // check for comma
  if (mpNameTextBox->text().contains(',')) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), Helper::ok);
    return;
  }
  // check for invalid names
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
  QList<QString> result = MainWindow::instance()->getOMCProxy()->parseString(QString("model M N %1; end M;").arg(mpNameTextBox->text()), "M", false);
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
  if (result.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
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
  if (MainWindow::instance()->isNewApi()) {
    ModelInfo oldModelInfo = pModelWidget->createModelInfo();
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
    bool attributesChanged = false;
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->isFinal() != mpFinalCheckBox->isChecked();
    attributesChanged |= !mpElement->getModelComponent()->getPrefixes()->isPublic() != mpProtectedCheckBox->isChecked();
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->getReplaceable() ? true : false != mpReplaceAbleCheckBox->isChecked();
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->getVariability().compare(variability) != 0;
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->isInner() != mpInnerCheckBox->isChecked();
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->isOuter() != mpOuterCheckBox->isChecked();
    attributesChanged |= mpElement->getModelComponent()->getPrefixes()->getDirection().compare(causality) != 0;

    QString isFinal = mpFinalCheckBox->isChecked() ? "true" : "false";
    QString flow = (mpElement->getModelComponent()->getPrefixes()->getConnector().compare(QStringLiteral("flow")) == 0) ? "true" : "false";
    QString isProtected = mpProtectedCheckBox->isChecked() ? "true" : "false";
    QString isReplaceAble = mpReplaceAbleCheckBox->isChecked() ? "true" : "false";
    QString isInner = mpInnerCheckBox->isChecked() ? "true" : "false";
    QString isOuter = mpOuterCheckBox->isChecked() ? "true" : "false";

    // update element attributes if needed
    if (attributesChanged) {
      if (!pOMCProxy->setComponentProperties(modelName, mpElement->getName(), isFinal, flow, isProtected, isReplaceAble, variability, isInner, isOuter, causality)) {
        QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
        pOMCProxy->printMessagesStringInternal();
      }
    }

    // update the element comment only if its changed.
    if (mpElement->getModelComponent()->getComment().compare(mpCommentTextBox->text()) != 0) {
      QString comment = StringHandler::escapeString(mpCommentTextBox->text());
      if (pOMCProxy->setComponentComment(modelName, mpElement->getName(), comment)) {
        attributesChanged = true;
      } else {
        QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
        pOMCProxy->printMessagesStringInternal();
      }
    }
    // update the element dimensions
    const QString dimensions = StringHandler::removeFirstLastSquareBrackets(mpDimensionsTextBox->text());
    if (mpElement->getModelComponent()->getDimensions().getAbsynDimensionsString().compare(dimensions) != 0) {
      const QString arrayIndex = QString("{%1}").arg(dimensions);
      if (pOMCProxy->setComponentDimensions(modelName, mpElement->getName(), arrayIndex)) {
        attributesChanged = true;
      } else {
        QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
        pOMCProxy->printMessagesStringInternal();
      }
    }
    // update the element name only if its changed.
    if (mpElement->getName().compare(mpNameTextBox->text()) != 0) {
      // if renameComponentInClass command is successful update the element with new name
      if (pOMCProxy->renameComponentInClass(modelName, mpElement->getName(), mpNameTextBox->text())) {
        attributesChanged = true;
      } else {
        QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), Helper::ok);
        pOMCProxy->printMessagesStringInternal();
      }
    }
    // push the attributes updated change to the stack
    if (attributesChanged) {
      ModelInfo newModelInfo = pModelWidget->createModelInfo();
      pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, QString("Update Element %1 Attributes").arg(mpElement->getName())));
      pModelWidget->updateModelText();
    }
  } else {
    // save the old ElementInfo
    ElementInfo oldElementInfo(mpElement->getElementInfo());
    // Create a new ElementInfo
    ElementInfo newElementInfo;
    newElementInfo.setClassName(mpElement->getElementInfo()->getClassName());
    newElementInfo.setName(mpNameTextBox->text());
    newElementInfo.setComment(mpCommentTextBox->text());
    newElementInfo.setProtected(mpProtectedCheckBox->isChecked());
    newElementInfo.setFinal(mpFinalCheckBox->isChecked());
    newElementInfo.setFlow(mpElement->getElementInfo()->getFlow());
    newElementInfo.setStream(mpElement->getElementInfo()->getStream());
    newElementInfo.setReplaceable(mpReplaceAbleCheckBox->isChecked());
    newElementInfo.setVariablity(variability);
    newElementInfo.setInner(mpInnerCheckBox->isChecked());
    newElementInfo.setOuter(mpOuterCheckBox->isChecked());
    newElementInfo.setCausality(causality);
    QString dimensions = StringHandler::removeFirstLastSquareBrackets(mpDimensionsTextBox->text());
    newElementInfo.setArrayIndex(QString("{%1}").arg(dimensions));
    /* If user has really changed the Element's attributes then push that change on the stack.
     */
    if (oldElementInfo != newElementInfo) {
      UpdateElementAttributesCommand *pUpdateElementAttributesCommand = new UpdateElementAttributesCommand(mpElement, oldElementInfo, newElementInfo);
      pModelWidget->getUndoStack()->push(pUpdateElementAttributesCommand);
      pModelWidget->updateModelText();
    }
  }
  accept();
}

/*!
 * \class CompositeModelSubModelAttributes
 * \brief A dialog for displaying SubModel attributes.
 */
/*!
 * \brief CompositeModelSubModelAttributes::CompositeModelSubModelAttributes
 * \param pElement - pointer to Element
 * \param pParent
 */
CompositeModelSubModelAttributes::CompositeModelSubModelAttributes(Element *pElement, QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("SubModel Attributes")));
  setAttribute(Qt::WA_DeleteOnClose);
  mpElement = pElement;
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
  mpNameTextBox->setText(mpElement->getName());
  // set the start command
  mpStartCommandTextBox->setText(mpElement->getElementInfo()->getStartCommand());
  // set the exact step
  mpExactStepCheckBox->setChecked(mpElement->getElementInfo()->getExactStep());
  // set the simulation tool of the submodel
  mpSimulationToolComboBox->setCurrentIndex(StringHandler::getSimulationTool(mpStartCommandTextBox->text()));
  // set the model file name
  mpModelFileTextBox->setText(mpElement->getElementInfo()->getModelFile());
  // set the geometry file name
  mpGeometryFileTextBox->setText(mpElement->getElementInfo()->getGeometryFile());
  // update parameter widgets
  CompositeModelEditor *pEditor = dynamic_cast<CompositeModelEditor*>(mpElement->getGraphicsView()->getModelWidget()->getEditor());
  QStringList parameters = pEditor->getParameterNames(mpElement->getName());
  mParameterLabels.clear();
  mParameterLineEdits.clear();
  for(int i=0; i<parameters.size(); ++i) {
      mParameterLabels.append(new QLabel(parameters[i]));
      mParameterLineEdits.append(new QLineEdit(pEditor->getParameterValue(mpElement->getName(), parameters[i])));
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
  // save the old ElementInfo
  ElementInfo oldElementInfo(mpElement->getElementInfo());
  // Create a new ElementInfo
  ElementInfo newElementInfo(mpElement->getElementInfo());
  newElementInfo.setStartCommand(mpStartCommandTextBox->text());
  newElementInfo.setExactStep(mpExactStepCheckBox->isChecked());
  newElementInfo.setGeometryFile(mpGeometryFileTextBox->text());


  QStringList parameterNames, oldParameterValues, newParameterValues;
  if(mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    BaseEditor *pBaseEditor = mpElement->getGraphicsView()->getModelWidget()->getEditor();
    CompositeModelEditor *pEditor = qobject_cast<CompositeModelEditor*>(pBaseEditor);

    parameterNames = pEditor->getParameterNames(mpElement->getName());  //Assume submodel; otherwise returned list is empty
    foreach(QString parName, parameterNames) {
      oldParameterValues.append(pEditor->getParameterValue(mpElement->getName(), parName));
    }

    for(int i=0; i<mParameterLineEdits.size(); ++i) {
      newParameterValues.append(mParameterLineEdits[i]->text());
    }
  }

  // If user has really changed the Element's attributes then push that change on the stack.
  if (oldElementInfo != newElementInfo || oldParameterValues != newParameterValues) {
    UpdateSubModelAttributesCommand *pUpdateSubModelAttributesCommand = new UpdateSubModelAttributesCommand(mpElement, oldElementInfo, newElementInfo,
                                                                                                            parameterNames, oldParameterValues, newParameterValues);
    ModelWidget *pModelWidget = mpElement->getGraphicsView()->getModelWidget();
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
  ElementInfo *pInfo = mpConnectionLineAnnotation->getStartElement()->getElementInfo();
  bool tlm = (pInfo->getTLMCausality() == "Bidirectional");
  int dimensions = pInfo->getDimensions();

  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::connectionAttributes));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  mpHeading = Utilities::getHeadingLabel(Helper::connectionAttributes);
  // horizontal line
  mpHorizontalLine = Utilities::getHeadingLine();
  // Create the start element class name label and text box
  mpFromLabel = new Label(tr("From:"));
  mpConnectionStartLabel = new Label(mpConnectionLineAnnotation->getStartElementName());
  // Create the end element class name label and text box
  mpToLabel = new Label(tr("To:"));
  mpConnectionEndLabel = new Label(mpConnectionLineAnnotation->getEndElementName());
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
  ElementInfo *pInfo = mpConnectionLineAnnotation->getStartElement()->getElementInfo();
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

    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateCompositeModelConnection(mpConnectionLineAnnotation, oldCompositeModelConnection, newCompositeModelConnection));
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
