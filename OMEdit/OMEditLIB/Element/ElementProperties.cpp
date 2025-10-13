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
#include <QList>
#include <QScreen>
#include <QStringList>
#include <QStringBuilder>

/*!
 * \class FinalEachToolButton
 * \brief Creates a toolbutton with drop menu for final and each modifiers.
 */
/*!
 * \brief FinalEachToolButton::FinalEachToolButton
 * \param canHaveEach
 * \param parent
 */
FinalEachToolButton::FinalEachToolButton(bool canHaveEach, QWidget *parent)
  : QToolButton(parent)
{
  setIcon(QIcon(":/Resources/icons/drop-menu.svg"));
  setAutoRaise(true);
  // final action
  mpFinalAction = new QAction("final");
  mpFinalAction->setCheckable(true);
  // each action
  mpEachAction = new QAction("each");
  mpEachAction->setCheckable(true);
  // break action
  mpBreakAction = new QAction(Helper::BREAK);
  mpBreakAction->setCheckable(true);
  connect(mpBreakAction, SIGNAL(toggled(bool)), SIGNAL(breakToggled(bool)));
  // create a menu
  mpFinalEachMenu = new QMenu;
  mpFinalEachMenu->addAction(mpFinalAction);
  if (canHaveEach) {
    mHasEach = canHaveEach;
    mpFinalEachMenu->addAction(mpEachAction);
  }
  mpFinalEachMenu->addSeparator();
  mpFinalEachMenu->addAction(mpBreakAction);

  connect(this, SIGNAL(clicked()), SLOT(showParameterMenu()));
}

void FinalEachToolButton::setFinal(bool final)
{
  mpFinalAction->setChecked(final);
  mFinalDefault = final;
}

void FinalEachToolButton::setEach(bool each)
{
  mpEachAction->setChecked(each);
  mEachDefault = each;
}

void FinalEachToolButton::setBreak(bool break_)
{
  bool state = mpBreakAction->blockSignals(true);
  mpBreakAction->setChecked(break_);
  mpBreakAction->blockSignals(state);
  mBreakDefault = break_;
}

/*!
 * \brief FinalEachToolButton::isModified
 * \return true if final or each or break are modified.
 */
bool FinalEachToolButton::isModified() const
{
  if (mFinalDefault != isFinal() || mEachDefault != isEach() || mBreakDefault != isBreak()) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief FinalEachToolButton::showParameterMenu
 * Slot activated when clicked SIGNAL is raised.
 * Shows the menu.
 */
void FinalEachToolButton::showParameterMenu()
{
  mpFinalEachMenu->exec(mapToGlobal(QPoint(0, 0)));
}

Parameter::Parameter(ModelInstance::Element *pElement, bool defaultValue, ElementParameters *pElementParameters)
{
  mpModelInstanceElement = pElement;
  mExtendName = mpModelInstanceElement->getTopLevelExtendName();
  mInherited = defaultValue;
  mpElementParameters = pElementParameters;
  auto &dialogAnnotation = mpModelInstanceElement->getAnnotation()->getDialogAnnotation();
  mTab = dialogAnnotation.getTab();
  mGroup = dialogAnnotation.getGroup();
  mGroupDefined = !mGroup.isEmpty();
  mEnable = dialogAnnotation.isEnabled();
  mShowStartAttribute = dialogAnnotation.getShowStartAttribute();
  mShowStartAndFixed = mShowStartAttribute;
  mColorSelector = dialogAnnotation.isColorSelector();
  auto &loadSelector = dialogAnnotation.getLoadSelector();
  mLoadSelectorFilter = loadSelector.getFilter();
  mLoadSelectorCaption = loadSelector.getCaption();
  auto &saveSelector = dialogAnnotation.getSaveSelector();
  mSaveSelectorFilter = saveSelector.getFilter();
  mSaveSelectorCaption = saveSelector.getCaption();
  mGroupImage = dialogAnnotation.getGroupImage();
  if (!mGroupImage.isEmpty()) {
    mGroupImage = MainWindow::instance()->getOMCProxy()->uriToFilename(mGroupImage);
  }
  mConnectorSizing = dialogAnnotation.isConnectorSizing();

  // If mShowStartAttribute is not set then check for start modifier
  if (!mShowStartAndFixed && !dialogAnnotation.hasShowStartAttribute()
      && !mpModelInstanceElement->isParameter() && !mpModelInstanceElement->isInput() && mpModelInstanceElement->getModifier()) {
    mShowStartAndFixed = mpModelInstanceElement->getModifier()->hasModifier("start");
  }
  /* if mShowStartAndFixed and group name is empty then set group name to Initialization.
   * else set group name to Parameters for actual parameters or elements that have dialog annotation or replaceable elements.
   */
  if (mShowStartAndFixed && mGroup.isEmpty()) {
    mGroup = "Initialization";
  } else if (mGroup.isEmpty() && (mpModelInstanceElement->isParameter() || mpModelInstanceElement->getAnnotation()->hasDialogAnnotation()
                                  || mpModelInstanceElement->getReplaceable())) {
    mGroup = "Parameters";
  }

  mpNameLabel = new Label;
  mpFixedCheckBox = new FixedCheckBox;
  connect(mpFixedCheckBox, SIGNAL(clicked()), SLOT(showFixedMenu()));
  setFixedState("", true);
  mpFixedFinalEachMenuButton = new FinalEachToolButton((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                       || mpModelInstanceElement->getDimensions().isArray());
  // set the value type based on element type.
  if (mpModelInstanceElement->getRootType().compare(QStringLiteral("Boolean")) == 0) {
    if (mpModelInstanceElement->getAnnotation()->getChoices()
        && (mpModelInstanceElement->getAnnotation()->getChoices()->isCheckBox() || mpModelInstanceElement->getAnnotation()-> getChoices()->isDymolaCheckBox())) {
      mValueType = Parameter::CheckBox;
    } else {
      mValueType = Parameter::Boolean;
    }
  } else if (mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isEnumeration()) {
    mValueType = Parameter::Enumeration;
  } else if (mpModelInstanceElement->getReplaceable()) {
    // replaceable component or short element definition
    if (mpModelInstanceElement->isShortClassDefinition()) {
      mValueType = Parameter::ReplaceableClass;
    } else {
      mValueType = Parameter::ReplaceableComponent;
    }
    if (mpModelInstanceElement->getModel() || mpModelInstanceElement->isShortClassDefinition()) {
      createEditClassButton();
    }
  } else if (mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isRecord()) {
    mValueType = Parameter::Record;
    createEditClassButton();
  } else if (mpModelInstanceElement->getAnnotation()->getChoices() && !mpModelInstanceElement->getAnnotation()->getChoices()->getChoices().isEmpty()) {
    mValueType = Parameter::Choices;
  } else if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
    mValueType = Parameter::ChoicesAllMatching;
  } else {
    mValueType = Parameter::Normal;
  }
  // final and each menu
  mpFinalEachMenuButton = new FinalEachToolButton((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                  || mpModelInstanceElement->getDimensions().isArray());
  connect(mpFinalEachMenuButton, SIGNAL(breakToggled(bool)), SLOT(setBreakValue(bool)));
  mValueCheckBoxModified = false;
  mDefaultValue = "";
  mpFileSelectorButton = new QToolButton;
  mpFileSelectorButton->setText("...");
  mpFileSelectorButton->setToolButtonStyle(Qt::ToolButtonTextOnly);
  connect(mpFileSelectorButton, SIGNAL(clicked()), SLOT(fileSelectorButtonClicked()));
  createValueWidget();
  // Get unit value
  QPair<QString, bool> unit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "unit");
  mUnit = unit.first;
  // Get displayUnit value
  QPair<QString, bool> displayUnit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "displayUnit");
  if (displayUnit.first.isEmpty()) {
    displayUnit.first = mUnit;
  }
  mDisplayUnit = displayUnit.first;
  mPreviousUnit = mDisplayUnit;
  QStringList units;
  if (!mUnit.isEmpty()) {
    units << mUnit;
    if (mDisplayUnit.compare(mUnit) != 0) {
      units << mDisplayUnit;
    }
    Utilities::addDefaultDisplayUnit(mUnit, units);
  }
  mpUnitComboBox = new ComboBox;
  foreach (QString unit, units) {
    mpUnitComboBox->addItem(OMPlot::Plot::convertUnitToSymbol(unit), unit);
  }
  if (mDisplayUnit.compare(mUnit) != 0) {
    mpUnitComboBox->setCurrentIndex(1);
  }
  connect(mpUnitComboBox, SIGNAL(currentIndexChanged(int)), SLOT(unitComboBoxChanged(int)));
  /* Issue #11715.
   * Do not add each menu item to displayUnit modifiers.
   * We will automatically add the each prefix for arrays.
   */
  mpDisplayUnitFinalEachMenuButton = new FinalEachToolButton(false);
  // comment
  const QString comment = mpModelInstanceElement->getComment();
  mpCommentLabel = new Label(comment);

  if (isReplaceableClass()) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
    setValueWidget(pReplaceableClass->getBaseClass(), true, mUnit);
  } else if (isReplaceableComponent()) {
    QString value;
    if (mpModelInstanceElement->getModifier()) {
      if (mpModelInstanceElement->getModifier()->isValueDefined()) {
        value = mpModelInstanceElement->getModifier()->getValue();
      } else {
        value = "redeclare " % mpModelInstanceElement->getType() % " " % mpModelInstanceElement->getName();
        QString modifier = mpModelInstanceElement->getModifier()->toString(true);
        if (!modifier.isEmpty()) {
          if (modifier.startsWith("(")) {
            value = value % modifier;
          } else {
            value = value % "(" % modifier % ")";
          }
        }
      }
    }
    setValueWidget(value, defaultValue, mUnit);
  } else {
    mpElementParameters->applyFinalStartFixedAndDisplayUnitModifiers(this, mpModelInstanceElement->getModifier(), defaultValue, false);
  }
  update();
}

/*!
 * \brief Parameter::updateNameLabel
 * Updates the name label.
 */
void Parameter::updateNameLabel()
{
  mName = mpModelInstanceElement->getName();
  QString name = mName;
  if (mpModelInstanceElement->getDimensions().isArray()) {
    name.append("[" % mpModelInstanceElement->getDimensions().getTypedDimensionsString() % "]");
  }
  if (mShowStartAndFixed) {
    name.append(".start");
  }
  mpNameLabel->setText(name);
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
  if (!unitComboBoxChanged && !defaultValue) {
    enableDisableUnitComboBox(value);
  }

  QStringList valueParts = Utilities::extractArrayParts(value);
  // convert the value to display unit
  if (!fromUnit.isEmpty() && mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString().compare(fromUnit) != 0) {
    if (valueParts.size() == 1) {
      bool ok = true;
      qreal realValue = valueParts.at(0).toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
        if (convertUnit.unitsCompatible) {
          realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
          value = StringHandler::number(realValue);
        }
      }
    } else { // if array expression
      value = Utilities::arrayExpressionUnitConversion(MainWindow::instance()->getOMCProxy(), value, fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
    }
  }

  if (defaultValue) {
    mDefaultValue = value;
    /* Issue #11847
     * Show the default values as arrays, either as {0, 0, 0} or fill(0, 3).
     * Use first version if the number of dimensions is small (say, <= 4, which works for 3-phase, 3D mechanics and quaternions).
     * Use the second version for larger arrays, to avoid overbloating it.
     */
    if (Utilities::isValueScalarLiteralConstant(value) && ((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                           || mpModelInstanceElement->getDimensions().isArray())) {
      bool ok;
      int dims = mpElementParameters->getElementDimensions().toInt(&ok);
      if (ok) {
        if (dims <= 4) {
          QStringList valueList;
          for (int i = 0; i < dims; ++i) {
            valueList.append(value);
          }
          value = "{" % valueList.join(",") % "}";
        } else {
          value = "fill(" % value % ", " % mpElementParameters->getElementDimensions() % ")";
        }
      }
    }
  }
  QFontMetrics fm = QFontMetrics(QFont());
  // Allow to take 70% of screen width
  int screenWidth = QApplication::primaryScreen()->availableGeometry().width() * 0.7;
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
        /* Issue #12756
         * Reset the value combobox selection for choices.
         * Since we always want to update the unit combobox when value selection changes for choices.
         * Also don't add the new value to the combobox.
         */
        if (isChoices()) {
          mpValueComboBox->setCurrentIndex(-1);
        } else {
          int index = mpValueComboBox->findData(value);
          if (index > -1) {
            mpValueComboBox->setCurrentIndex(index);
          } else { // if we fail to find the value in the combobox then add it to the combobox
            mpValueComboBox->insertItem(1, value, value);
          }
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 11, 0)
        mpValueComboBox->setMinimumWidth(qMin(qMax(fm.horizontalAdvance(value), mpValueComboBox->minimumSizeHint().width()), screenWidth) + 50);
#else // QT_VERSION_CHECK
        mpValueComboBox->setMinimumWidth(qMin(qMax(fm.width(value), mpValueComboBox->minimumSizeHint().width()), screenWidth) + 50);
#endif // QT_VERSION_CHECK
      }
      break;
    case Parameter::CheckBox:
      signalsState = mpValueCheckBox->blockSignals(true);
      mpValueCheckBox->setChecked(value.compare("true") == 0);
      mpValueCheckBox->blockSignals(signalsState);
      mValueCheckBoxModified = valueModified && !defaultValue;
      break;
    case Parameter::Record:
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
#if QT_VERSION >= QT_VERSION_CHECK(5, 11, 0)
        mpValueTextBox->setMinimumWidth(qMin(fm.horizontalAdvance(value), screenWidth) + 50);
#else // QT_VERSION_CHECK
        mpValueTextBox->setMinimumWidth(qMin(fm.width(value), screenWidth) + 50);
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
    case Parameter::Record:
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
      return mpValueComboBox->lineEdit()->isModified() || isValueModifiedHelper();
    case Parameter::CheckBox:
      return mValueCheckBoxModified || isValueModifiedHelper();
    case Parameter::Record:
    case Parameter::Normal:
    default:
      return mpValueTextBox->isModified() || isValueModifiedHelper();
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
    case Parameter::Record:
    case Parameter::Normal:
    default:
      return mpValueTextBox->text().trimmed();
  }
}

/*!
 * \brief Parameter::hideValueWidget
 * Hides the value widget.
 */
void Parameter::hideValueWidget()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      mpValueComboBox->setVisible(false);
      break;
    case Parameter::CheckBox:
      mpValueCheckBox->setVisible(false);
      break;
    case Parameter::Record:
    case Parameter::Normal:
    default:
      mpValueTextBox->setVisible(false);
      break;
  }
}

void Parameter::setFixedState(QString fixed, bool defaultValue)
{
  mOriginalFixedValue = defaultValue ? "" : fixed;
  if (fixed.compare(QStringLiteral("true")) == 0) {
    mpFixedCheckBox->setTickState(defaultValue, true);
  } else {
    mpFixedCheckBox->setTickState(defaultValue, false);
  }
}

QString Parameter::getFixedState() const
{
  return mpFixedCheckBox->getTickStateString();
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
    case Parameter::Record:
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
  if (mpEditClassButton) {
    mpEditClassButton->setEnabled(enable);
  }
}

/*!
 * \brief Parameter::update
 * Enable/disable the parameter.
 */
void Parameter::update()
{
  mEnable.evaluate(mpElementParameters->getGraphicsView()->getModelWidget()->getModelInstance());
  setEnabled(mEnable);
}

/*!
 * \brief Parameter::createEditClassButton
 * Creates the edit class button.
 */
void Parameter::createEditClassButton()
{
  mpEditClassButton = new QToolButton;
  mpEditClassButton->setIcon(QIcon(":/Resources/icons/edit-icon.svg"));
  mpEditClassButton->setToolTip(tr("Edit"));
  mpEditClassButton->setAutoRaise(true);
  connect(mpEditClassButton, SIGNAL(clicked()), SLOT(editClassButtonClicked()));
}

void Parameter::createValueWidget()
{
  int i;
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpModelInstanceElement->getType();
  QString constrainedByClassName = QStringLiteral("$Any");
  QString replaceable = "", replaceableText = "", parentClassName = "", restriction = "", elementName = "";
  QStringList enumerationLiterals, enumerationLiteralsDisplay, choices, choicesComment, replaceableChoice;
  QList<QList<QString>> replaceableChoices;

  switch (mValueType) {
    case Parameter::Boolean:
      mpValueComboBox = new ComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->setInsertPolicy(QComboBox::NoInsert);
      mpValueComboBox->addItem("", "");
      mpValueComboBox->addItem("true", "true");
      mpValueComboBox->addItem("false", "false");
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;

    case Parameter::Enumeration:
      mpValueComboBox = new ComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->setInsertPolicy(QComboBox::NoInsert);
      mpValueComboBox->addItem("", "");
      foreach (auto pModelInstanceElement, mpModelInstanceElement->getModel()->getElements()) {
        if (pModelInstanceElement->isComponent()) {
          auto pModelInstanceComponent = dynamic_cast<ModelInstance::Component*>(pModelInstanceElement);
          enumerationLiterals.append(pModelInstanceComponent->getName());
          enumerationLiteralsDisplay.append(pModelInstanceComponent->getName() % " " % pModelInstanceComponent->getComment());
        }
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
      if (isReplaceableComponent() || isReplaceableClass()) {
        constrainedByClassName = mpModelInstanceElement->getReplaceable()->getConstrainedby();
        if (constrainedByClassName.isEmpty()) {
          auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
          if (pReplaceableClass) {
            constrainedByClassName = pReplaceableClass->getBaseClass();
          }
        }
      }
      if (mpModelInstanceElement->getAnnotation()->getChoices()) {
        choices = mpModelInstanceElement->getAnnotation()->getChoices()->getChoicesValueStringList();
        choicesComment = mpModelInstanceElement->getAnnotation()->getChoices()->getChoicesCommentStringList();
      }
      parentClassName = mpElementParameters->getElementParentClassName();
      if (mpModelInstanceElement->getModel()) {
        restriction = mpModelInstanceElement->getModel()->getRestriction();
      } else {
        restriction = mpModelInstanceElement->getType();
      }
      elementName = mpModelInstanceElement->getName();

      if (constrainedByClassName.contains(QStringLiteral("$Any"))) {
        constrainedByClassName = className;
      }

      mpValueComboBox = new ComboBox;
      mpValueComboBox->setEditable(true);
      mpValueComboBox->setInsertPolicy(QComboBox::NoInsert);
      mpValueComboBox->addItem("", "");
      // add choices if there are any
      for (i = 0; i < choices.size(); i++) {
        QString choice = choices[i];
        QString comment = i < choicesComment.size() ? choicesComment[i] : choice;
        mpValueComboBox->addItem(comment, choice);
      }

      // choicesAllMatching
      if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
        replaceableChoices = pOMCProxy->getReplaceableChoices(constrainedByClassName, parentClassName);
      }
      for (i = 0; i < replaceableChoices.size(); i++) {
        replaceableChoice = replaceableChoices[i];
        if (isReplaceableComponent() || isReplaceableClass()) {
          replaceableText = "redeclare " + replaceableChoice[0];
          // add comment if available
          if (!replaceableChoice[1].isEmpty()) {
            replaceableText += " \"" + replaceableChoice[1] + "\"";
          }
          // if replaceableChoices points to a class in this scope, remove scope
          if (replaceableChoice[0].startsWith(parentClassName + ".")) {
            replaceableChoice[0].remove(0, parentClassName.size() + 1);
          }
          if (isReplaceableClass()) {
            replaceable = QString("redeclare %1 %2 = %3").arg(restriction, elementName, replaceableChoice[0]);
          } else {
            replaceable = QString("redeclare %1 %2").arg(replaceableChoice[0], elementName);
          }
          mpValueComboBox->addItem(replaceableText, replaceable);
        } else {
          mpValueComboBox->addItem(replaceableChoice[0], replaceableChoice[0]);
        }
      }

      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;
    case Parameter::Record:
    case Parameter::Normal:
    default:
      mpValueTextBox = new QLineEdit;
      mpValueTextBox->installEventFilter(this);
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
  mpFinalEachMenuButton->setBreak(value.compare(Helper::BREAK) == 0);
  // Do not do anything when the value is empty
  if (value.isEmpty()) {
    return;
  }
  /* Enable/disable the unit combobox based on the literalConstant
   * Set the display unit as current when value is literalConstant otherwise use unit
   * ticket:5618 Disable the unit drop down when we have a symbolic parameter
   */
  bool literalConstant = Utilities::isValueLiteralConstant(value);
  mpUnitComboBox->setEnabled(mEnable && literalConstant);
  /* ticket:5976 don't change the unit combobox when the literalConstant is true
   * We only want to disbale and switch to unit when literalConstant is false and we got a symbolic or expression parameter.
   */
  if (!literalConstant) {
    resetUnitCombobox();
  }
  /* Issue #13636
   * Set each if value is scalar or remove it if value is not scalar.
   */
  if (mpFinalEachMenuButton->hasEach()) {
    mpFinalEachMenuButton->setEach(Utilities::isValueScalarLiteralConstant(value));
  }
}

/*!
 * \brief Parameter::updateValueBinding
 * Updates the value binding of the parameter and call updateParameters so depending parameters gets updated.
 * \param value
 */
void Parameter::updateValueBinding(const FlatModelica::Expression expression)
{
  // update the binding with the new value
  mpModelInstanceElement->setBinding(expression);
  mpElementParameters->updateParameters();
}

/*!
 * \brief Parameter::isValueModifiedHelper
 * \return
 */
bool Parameter::isValueModifiedHelper() const
{
  const QString unit = mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString();
  /* if final each are modified
   * OR if fixed is modified
   * OR if fixed final each are modified
   * OR if displayUnit is modified
   * OR if displayUnit final each are modified
   */
  if ((mpFinalEachMenuButton && mpFinalEachMenuButton->isModified())
      || (isShowStartAndFixed() && getFixedState().compare(getOriginalFixedValue()) != 0)
      || (isShowStartAndFixed() && mpFixedFinalEachMenuButton && mpFixedFinalEachMenuButton->isModified())
      || (mpUnitComboBox->isEnabled() && !unit.isEmpty() && mDisplayUnit.compare(unit) != 0)
      || (mpDisplayUnitFinalEachMenuButton && mpDisplayUnitFinalEachMenuButton->isModified())) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief Parameter::resetUnitCombobox
 * Resets the unit combobox to the default unit.
 */
void Parameter::resetUnitCombobox()
{
  int index = mpUnitComboBox->findData(mUnit);
  if (index > -1 && index != mpUnitComboBox->currentIndex()) {
    mpUnitComboBox->setCurrentIndex(index);
    mPreviousUnit = mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString();
  }
}

/*!
 * \brief Parameter::setBreakValue
 * Slot activated when break is toggled in the menu.
 * \param breakValue
 */
void Parameter::setBreakValue(bool breakValue)
{
  const QString breakStr = breakValue ? Helper::BREAK : "";
  setValueWidget(breakStr, false, mUnit, true);
}

/*!
 * \brief Parameter::editClassButtonClicked
 * Slot activate when mpEditClassButton clicked signal is raised.
 * Opens ElementParameters dialog for the redeclare class.
 */
void Parameter::editClassButtonClicked()
{
  QString type;
  QString value;
  QString defaultValue;
  if (isRecord()) {
    value = mpValueTextBox->text();
    defaultValue = mpValueTextBox->placeholderText();
  } else {
    value = mpValueComboBox->lineEdit()->text();
    defaultValue = mpValueComboBox->lineEdit()->placeholderText();
  }
  QString modifier = value;
  QString defaultModifier = defaultValue;
  ModelInstance::Modifier *pReplaceableConstrainedByModifier = 0;
  QString comment;
  if (isReplaceableComponent()) {
    type = mpModelInstanceElement->getType();
    pReplaceableConstrainedByModifier = mpModelInstanceElement->getReplaceable()->getModifier();
  } else if (isReplaceableClass()) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
    type = pReplaceableClass->getBaseClass();
    pReplaceableConstrainedByModifier = pReplaceableClass->getReplaceable()->getModifier();
  } else if (isRecord()) {
    type = mpModelInstanceElement->getType();
  }
  // parse the Modelica code of element redeclaration to get the type and modifiers
  if (value.startsWith("redeclare")) {
    if (isReplaceableComponent()) {
      FlatModelica::Parser::getTypeFromElementRedeclaration(value, type, modifier, comment);
    } else if (isReplaceableClass()) {
      FlatModelica::Parser::getShortClassTypeFromElementRedeclaration(value, type, modifier, comment);
    }
  }

  QString classPath;
  if (mpElementParameters && mpElementParameters->hasElement()) {
    // if we fail to find the type
    if ((mpModelInstanceElement == NULL) ||
        (mpModelInstanceElement->getTopLevelExtendElement() == NULL) ||
        (mpModelInstanceElement->getTopLevelExtendElement()->getParentModel() == NULL) ||
        (mpModelInstanceElement->getTopLevelExtendElement()->getParentModel()->getName() == QString())) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Unable to find the redeclare class."), QMessageBox::Ok);
      return;
    }
    classPath = mpModelInstanceElement->getTopLevelExtendElement()->getParentModel()->getName();
  } else {
    classPath = mpElementParameters->getElementParentClassName();
  }
  // get type as qualified path
  const QString qualifiedType = MainWindow::instance()->getOMCProxy()->qualifyPath(classPath, type);
  ModelInstance::Model *pCurrentModel = mpModelInstanceElement->getModel();
  const QJsonObject newModelJSON = MainWindow::instance()->getOMCProxy()->getModelInstance(qualifiedType, modifier);
  if (!newModelJSON.isEmpty()) {
    const QJsonObject modifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(modifier);
    ModelInstance::Modifier *pElementModifier = new ModelInstance::Modifier("", QJsonValue(), mpModelInstanceElement->getParentModel());
    pElementModifier->deserialize(QJsonValue(modifierJSON));
    const QJsonObject defaultModifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(defaultModifier);
    ModelInstance::Modifier *pDefaultElementModifier = new ModelInstance::Modifier("", QJsonValue(), mpModelInstanceElement->getParentModel());
    pDefaultElementModifier->deserialize(QJsonValue(defaultModifierJSON));
    ModelInstance::Model *pNewModel = new ModelInstance::Model(newModelJSON, mpModelInstanceElement);
    mpModelInstanceElement->setModel(pNewModel);
    MainWindow::instance()->getProgressBar()->setRange(0, 0);
    MainWindow::instance()->showProgressBar();
    ElementParameters *pElementParameters = new ElementParameters(mpModelInstanceElement, mpElementParameters->getGraphicsView(), mpElementParameters->isInherited(),
                                                                  true, pDefaultElementModifier, pReplaceableConstrainedByModifier, pElementModifier, mpElementParameters);
    MainWindow::instance()->hideProgressBar();
    MainWindow::instance()->getStatusBar()->clearMessage();
    if (pElementParameters->exec() == QDialog::Accepted) {
      const QString modification = pElementParameters->getModification();
      if (isReplaceableComponent() || isRecord()) {
        if (value.startsWith("redeclare")) {
          QString elementRedeclaration = "redeclare " % type % " " % mpModelInstanceElement->getName() % modification;
          if (!comment.isEmpty()) {
            elementRedeclaration = elementRedeclaration % " " % comment;
          }
          setValueWidget(elementRedeclaration, false, mUnit, true);
        } else {
          if (modification.isEmpty()) {
            setValueWidget("", false, mUnit, true);
          } else {
            setValueWidget(mpModelInstanceElement->getName() % modification, false, mUnit, true);
          }
        }
      } else if (isReplaceableClass()) {
        QString restriction;
        if (mpModelInstanceElement->getModel()) {
          restriction = mpModelInstanceElement->getModel()->getRestriction();
        } else {
          restriction = mpModelInstanceElement->getType();
        }
        QString elementRedeclaration = "redeclare " % restriction % " " % mpModelInstanceElement->getName() % " = " % type % " " % modification;
        if (!comment.isEmpty()) {
          elementRedeclaration = elementRedeclaration % " " % comment;
        }
        setValueWidget(elementRedeclaration, false, mUnit, true);
      }
    }
    pElementParameters->deleteLater();
    delete pElementModifier;
    delete pDefaultElementModifier;
    // reset the actual model of the element
    mpModelInstanceElement->setModel(pCurrentModel);
    delete pNewModel;
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
    if (isEnumeration()) {
      updateValueBinding(FlatModelica::Expression(value.toStdString(), index));
    } else {
      if (isChoices()) {
        resetUnitCombobox();
      }
      updateValueBinding(FlatModelica::Expression::parse(value));
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
  QString inheritedText = tr("inherited: (%1)").arg(mpFixedCheckBox->getInheritedValue() ? trueText : falseText);
  QAction *pInheritedAction = new QAction(inheritedText, pFixedActionGroup);
  pInheritedAction->setCheckable(true);
  connect(pInheritedAction, SIGNAL(triggered()), SLOT(inheritedFixedClicked()));
  menu.addAction(pInheritedAction);
  // set the menu actions states
  if (mpFixedCheckBox->getTickStateString().compare("true") == 0) {
    pTrueAction->setChecked(true);
  } else if (mpFixedCheckBox->getTickStateString().compare("false") == 0) {
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
  mpFixedCheckBox->setTickState(true, mpFixedCheckBox->getInheritedValue());
}

/*!
 * \brief Parameter::eventFilter
 * Handles the FocusOut event of value textbox.
 * \param pWatched
 * \param pEvent
 * \return
 */
bool Parameter::eventFilter(QObject *pWatched, QEvent *pEvent)
{
  if (mpValueTextBox == pWatched && pEvent->type() == QEvent::FocusOut) {
    enableDisableUnitComboBox(mpValueTextBox->text());
  }

  return QObject::eventFilter(pWatched, pEvent);
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
  int screenWidth = QApplication::primaryScreen()->availableGeometry().width() - 100;
  int screenHeight = QApplication::primaryScreen()->availableGeometry().height() - 300;
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
 * \param inherited
 * \param nested
 * \param pDefaultElementModifier
 * \param pReplaceableConstrainedByModifier
 * \param pElementModifier
 * \param pParent
 */
ElementParameters::ElementParameters(ModelInstance::Element *pElement, GraphicsView *pGraphicsView, bool inherited, bool nested,
                                     ModelInstance::Modifier *pDefaultElementModifier,
                                     ModelInstance::Modifier *pReplaceableConstrainedByModifier, ModelInstance::Modifier *pElementModifier, QWidget *pParent)
  : QDialog(pParent)
{
  const QString className = pGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  if (pElement) {
    setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName, tr("Element Parameters"), pElement->getQualifiedName(), className));
  } else {
    setWindowTitle(tr("%1 - %2 - %3").arg(Helper::applicationName, Helper::parameters, className));
  }
  mpElement = pElement;
  mpGraphicsView = pGraphicsView;
  mInherited = inherited;
  mNested = nested;
  mpDefaultElementModifier = pDefaultElementModifier;
  mpReplaceableConstrainedByModifier = pReplaceableConstrainedByModifier;
  mpElementModifier = pElementModifier;
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
 * \brief ElementParameters::getElementParentClassName
 * Returns the class name where the component is defined.
 * \return
 */
QString ElementParameters::getElementParentClassName() const
{
  return hasElement() ? mpElement->getParentModel()->getName() : mpGraphicsView->getModelWidget()->getModelInstance()->getName();
}

/*!
 * \brief ElementParameters::getComponentClassName
 * Returns the component's class name in case of component or class name in case of top level.
 * \return
 */
QString ElementParameters::getComponentClassName() const
{
  return hasElement() ? mpElement->getModel()->getName() : mpGraphicsView->getModelWidget()->getModelInstance()->getName();
}

/*!
 * \brief ElementParameters::getComponentClassComment
 * Returns the component's class comment in case of component or class comment in case of top level.
 * \return
 */
QString ElementParameters::getComponentClassComment() const
{
  return hasElement() ? mpElement->getModel()->getComment() : mpGraphicsView->getModelWidget()->getModelInstance()->getComment();
}

/*!
 * \brief ElementParameters::getModel
 * Return the model instance.
 * \return
 */
ModelInstance::Model *ElementParameters::getModel() const
{
  return hasElement() ? mpElement->getModel() : mpGraphicsView->getModelWidget()->getModelInstance();
}

/*!
 * \brief ElementParameters::applyFinalStartFixedAndDisplayUnitModifiers
 * \param pParameter
 * \param pModifier
 * \param defaultValue
 * \param isElementModification
 */
void ElementParameters::applyFinalStartFixedAndDisplayUnitModifiers(Parameter *pParameter, ModelInstance::Modifier *pModifier, bool defaultValue, bool isElementModification)
{
  if (pParameter && pModifier) {
    /* Ticket #2531
     * Check if parameter is marked final.
     * Redeclared but not replaceable classes should not show up in the parameter window. See issue #11311.
     * Only check for redeclare and replaceable modification for top level and when its not element modification. See issue #13334.
     */
    if (defaultValue && (pModifier->isFinal() || (!isElementModification && pModifier->isRedeclare() && !pModifier->isReplaceable()))) {
      if (mParametersList.removeOne(pParameter)) {
        delete pParameter;
      }
    } else {
      // if builtin type
      if (MainWindow::instance()->getOMCProxy()->isBuiltinType(pParameter->getModelInstanceElement()->getRootType())) {
        const QString value = pModifier->getValue();
        // if value is not empty then use it otherwise try to read start and fixed modifiers
        if (pParameter->isShowStartAttribute() || (value.isEmpty() && !pParameter->getModelInstanceElement()->isParameter() && !pParameter->getModelInstanceElement()->isInput())) {
          bool hasStart = pModifier->hasModifier("start");
          bool isStartFinal = false;
          bool hasFixed = pModifier->hasModifier("fixed");
          bool isFixedFinal = false;
          if (hasStart) {
            if (!pParameter->isGroupDefined() && !pParameter->getModelInstanceElement()->isParameter() && !pParameter->getModelInstanceElement()->isInput()) {
              pParameter->setGroup("Initialization");
            }
            pParameter->setShowStartAndFixed(true);
          }
          if (hasStart) {
            ModelInstance::Modifier *pStartModifier = pModifier->getModifier("start");
            if (pStartModifier) {
              isStartFinal = pStartModifier->isFinal();
              pParameter->setValueWidget(StringHandler::removeFirstLastQuotes(pStartModifier->getValue()), defaultValue, pParameter->getUnit(), mNested);
              pParameter->getFinalEachMenu()->setFinal(pStartModifier->isFinal());
              pParameter->getFinalEachMenu()->setEach(pStartModifier->isEach());
              pParameter->getFinalEachMenu()->setBreak(pStartModifier->isBreak());
            }
          }
          if (hasFixed) {
            ModelInstance::Modifier *pFixedModifier = pModifier->getModifier("fixed");
            if (pFixedModifier) {
              isFixedFinal = pFixedModifier->isFinal();
              if (pFixedModifier->isBreak()) {
                pParameter->getFixedFinalEachMenu()->setBreak(pFixedModifier->isBreak());
              } else {
                pParameter->setFixedState(StringHandler::removeFirstLastQuotes(pFixedModifier->getValue()), defaultValue);
              }
              pParameter->getFixedFinalEachMenu()->setFinal(pFixedModifier->isFinal());
              pParameter->getFixedFinalEachMenu()->setEach(pFixedModifier->isEach());
            }
          }
          /* Issue #12898
           * If start is final then hide the value box.
           * If fixed is final then hide the fixed checkbox.
           * If both are final then delete the parameter.
           * They can be set final at different levels e.g., start can be set final at declaration and fixed set final via extends modifier in parent.
           * so we set start and fixed final in the hierarchy flags and then check them when removing the parameter.
           * We do these checks only for the defaultValue i.e., when it comes from declaration and not from component or extends modification. See issue #13333.
           */
          if (defaultValue) {
            if (isStartFinal) {
              pParameter->hideValueWidget();
              pParameter->getFinalEachMenu()->setVisible(false);
              pParameter->setStartFinalInHierarchy(true);
            }
            if (isFixedFinal) {
              pParameter->getFixedCheckBox()->setVisible(false);
              pParameter->getFixedFinalEachMenu()->setVisible(false);
              pParameter->setFixedFinalInHierarchy(true);
            }
            if (pParameter->isStartFinalInHierarchy() && pParameter->isFixedFinalInHierarchy()) {
              if (mParametersList.removeOne(pParameter)) {
                delete pParameter;
              }
              return;
            }
          }
        } else {
          pParameter->setValueWidget(value, defaultValue, pParameter->getUnit(), mNested);
          // set final and each checkboxes in the menu
          pParameter->getFinalEachMenu()->setFinal(pModifier->isFinal());
          pParameter->getFinalEachMenu()->setEach(pModifier->isEach());
          pParameter->getFinalEachMenu()->setBreak(pModifier->isBreak());
        }
      } else { // if not builtin type then use all sub modifiers
        QString modifierValue;
        if (pModifier->isValueDefined()) {
          modifierValue = pModifier->getValue();
        } else {
          modifierValue = pModifier->toString(true);
          if (modifierValue.startsWith("(")) {
            modifierValue = pParameter->getModelInstanceElement()->getName() % modifierValue;
          }
        }
        pParameter->setValueWidget(modifierValue, defaultValue, pParameter->getUnit(), mNested);
      }
      // displayUnit
      ModelInstance::Modifier *pDisplayUnitModifier = pModifier->getModifier("displayUnit");
      QString displayUnit;
      if (pDisplayUnitModifier) {
        displayUnit = StringHandler::removeFirstLastQuotes(pDisplayUnitModifier->getValue());
      }
      if (!displayUnit.isEmpty()) {
        int index = pParameter->getUnitComboBox()->findData(displayUnit);
        if (index < 0) {
          if (pDisplayUnitModifier && displayUnit.compare(Helper::BREAK) == 0) {
            pParameter->getDisplayUnitFinalEachMenu()->setBreak(pDisplayUnitModifier->isBreak());
          } else {
            // add modifier as additional display unit if compatible
            OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
            if (pParameter->getUnitComboBox()->count() > 0 && pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(0).toString(), displayUnit).unitsCompatible) {
              pParameter->getUnitComboBox()->addItem(OMPlot::Plot::convertUnitToSymbol(displayUnit), displayUnit);
              index = pParameter->getUnitComboBox()->count() - 1;
            }
          }
        } else {
          /* Issue #11782.
           * Setting the display unit trigger SIGNAL currentIndexChanged and calls SLOT unitComboBoxChanged which will set the correct value.
           */
          pParameter->getUnitComboBox()->setCurrentIndex(index);
          pParameter->setDisplayUnit(displayUnit);
          if (!defaultValue) {
            pParameter->setHasDisplayUnit(true);
          }
          if (pDisplayUnitModifier) {
            pParameter->getDisplayUnitFinalEachMenu()->setFinal(pDisplayUnitModifier->isFinal());
            pParameter->getDisplayUnitFinalEachMenu()->setEach(pDisplayUnitModifier->isEach());
          }
        }
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
  QString name;
  if (hasElement()) {
    name = mpElement->getQualifiedName();
    if (isElementArray()) {
      name.append("[" % getElementDimensions() % "]");
    }
  }
  mpComponentNameTextBox = new Label(name);
  mpComponentCommentLabel = new Label(Helper::comment);
  mpComponentCommentTextBox = new Label(hasElement() ? mpElement->getComment() : "");
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
  mpComponentClassNameTextBox = new Label(getComponentClassName());
  // Component comment
  mpComponentClassCommentLabel = new Label(Helper::comment);
  mpComponentClassCommentTextBox = new Label;
  mpComponentClassCommentTextBox->setTextFormat(Qt::RichText);
  mpComponentClassCommentTextBox->setTextInteractionFlags(mpComponentClassCommentTextBox->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  mpComponentClassCommentTextBox->setText(getComponentClassComment());
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
  if (hasElement()) {
    pParametersScrollArea->getLayout()->addWidget(mpComponentGroupBox);
  }
  pParametersScrollArea->getLayout()->addWidget(mpComponentClassGroupBox);
  GroupBox *pParametersGroupBox = new GroupBox("Parameters");
  pParametersScrollArea->addGroupBox(pParametersGroupBox);
  GroupBox *pInitializationGroupBox = new GroupBox("Initialization");
  pParametersScrollArea->addGroupBox(pInitializationGroupBox);
  mTabsMap.insert("General", mpParametersTabWidget->addTab(pParametersScrollArea, "General"));
  // create parameters tabs and groupboxes
  createTabsGroupBoxesAndParameters(getModel(), hasElement());
  fetchElementExtendsModifiers(getModel(), hasElement());
  if (hasElement()) {
    fetchModifiers(mpElement->getModifier());
    // In case of element mode use the root parent ModelInstance::Element to read the element modifiers.
    if (mpGraphicsView->getModelWidget()->isElementMode()) {
      fetchRootElementModifiers(mpGraphicsView->getModelWidget()->getModelInstance()->getRootParentElement());
    }
    fetchClassExtendsModifiers(mpElement);
    // In case of element mode use the root parent ModelInstance::Element to read the extends modifiers.
    if (mpGraphicsView->getModelWidget()->isElementMode()) {
      fetchRootClassExtendsModifiers(mpGraphicsView->getModelWidget()->getModelInstance()->getRootParentElement());
    }
  }
  // Apply the default modifiers that are given in the redeclaration of the replaceable class or component.
  applyModifier(mpDefaultElementModifier, true);
  // Apply the modifiers that are given in the constainedBy of the replaceable class or component.
  applyModifier(mpReplaceableConstrainedByModifier, true);
  // Apply the modifiers that are given in the redeclaration of the replaceable class or component.
  applyModifier(mpElementModifier, false);

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
            pGroupBoxGridLayout->addWidget(pParameter->getFixedFinalEachMenu(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getValueWidget(), layoutIndex, columnIndex++);

          if (pParameter->getEditClassButton()) {
            pGroupBoxGridLayout->addWidget(pParameter->getEditClassButton(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getFinalEachMenu(), layoutIndex, columnIndex++);
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
            pGroupBoxGridLayout->addWidget(pParameter->getDisplayUnitFinalEachMenu(), layoutIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(1, 1), layoutIndex, columnIndex++);
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
  /* Do not add Modifiers tab when we are modifying top level parameters.
   * We don't know yet how to set the modifiers in the top level parameter editing.
   * For now simply hide the Modifiers tab in that case.
   */
  if (hasElement()) {
    mpParametersTabWidget->addTab(pModifiersTab, "Modifiers");
  }
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
void ElementParameters::createTabsGroupBoxesAndParameters(ModelInstance::Model *pModelInstance, bool defaultValue)
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
      if (!pElement->isPublic() || pElement->isFinal()) {
        continue;
      }
      /* Ticket #12898
       * Do not show parameter if start and fixed are final.
       */
      ModelInstance::Modifier *pModifier = pElement->getModifier();
      if (pModifier) {
        ModelInstance::Modifier *pStartModifier = pModifier->getModifier("start");
        ModelInstance::Modifier *pFixedModifier = pModifier->getModifier("fixed");
        if (pStartModifier && pStartModifier->isFinal() && pFixedModifier && pFixedModifier->isFinal()) {
          continue;
        }
      }
      auto &dialogAnnotation = pElement->getAnnotation()->getDialogAnnotation();
      // if connectorSizing is present then don't show the parameter
      if (dialogAnnotation.isConnectorSizing()) {
        continue;
      }
      /* Issue #13973
       * if showStart is present and false then don't show the variable.
       * annotation(Dialog(showStartAttribute = false))
       */
      if (!pElement->isParameter() && dialogAnnotation.hasShowStartAttribute() && !dialogAnnotation.getShowStartAttribute()) {
        continue;
      }
      // create the Parameter
      Parameter *pParameter = new Parameter(pElement, defaultValue, this);
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
      createTabsGroupBoxesAndParameters(pElement->getModel(), true);
    }
  }
}

/*!
 * \brief ElementParameters::fetchElementExtendsModifiers
 * Fetches the Element's extends modifiers and apply modifier values on the appropriate Parameters.
 * \param pModelInstance
 * \param defaultValue
 */
void ElementParameters::fetchElementExtendsModifiers(ModelInstance::Model *pModelInstance, bool defaultValue)
{
  foreach (auto pElement, pModelInstance->getElements()) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      /* Issue #10811
       * Go deep in the extends hierarchy and then apply the values in bottom to top order.
       */
      fetchElementExtendsModifiers(pExtend->getModel(), true);
      if (pExtend->getModifier()) {
        foreach (auto *pModifier, pExtend->getModifier()->getModifiers()) {
          Parameter *pParameter = findParameter(pModifier->getName());
          applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pModifier, defaultValue, false);
        }
      }
    }
  }
}

/*!
 * \brief ElementParameters::fetchModifiers
 * Fetches the modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParameters::fetchModifiers(ModelInstance::Modifier *pModifier)
{
  if (pModifier) {
    foreach (auto *pModifier, pModifier->getModifiers()) {
      Parameter *pParameter = findParameter(pModifier->getName());
      // Pass false for isElementModification. See issue #14196.
      applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pModifier, mInherited || mNested, false);
    }
  }
}

/*!
 * \brief ElementParameters::fetchRootElementModifiers
 * \param pModelElement
 */
void ElementParameters::fetchRootElementModifiers(ModelInstance::Element *pModelElement)
{
  if (pModelElement && pModelElement->isComponent() && pModelElement->getModifier()) {
    QStringList nameList = StringHandler::makeVariableParts(mpElement->getQualifiedName());
    // the first item is element name
    if (!nameList.isEmpty()) {
      nameList.removeFirst();
    }
    ModelInstance::Modifier *pModifier = pModelElement->getModifier();
    foreach (QString name, nameList) {
      pModifier = pModifier->getModifier(name);
      if (!pModifier) {
        return;
      }
    }
    fetchModifiers(pModifier);
  }
}

/*!
 * \brief ElementParameters::fetchClassExtendsModifiers
 * If the Element is inherited then fetch the class extends modifiers and apply modifier values on the appropriate Parameters.
 * \param pModelElement
 */
void ElementParameters::fetchClassExtendsModifiers(ModelInstance::Element *pModelElement)
{
  /* Issue #10864
   * Fetch the class extends modifiers recursively.
   */
  if (pModelElement && pModelElement->getParentModel()) {
    auto pExtend = pModelElement->getParentModel()->getParentElement();
    if (pExtend && pExtend->isExtend()) {
      bool hasParentElement = pExtend->getParentModel() && pExtend->getParentModel()->getParentElement();
      if (pExtend->getModifier()) {
        foreach (auto pModifier, pExtend->getModifier()->getModifiers()) {
          if (pModifier->getName().compare(mpElement->getName()) == 0) {
            foreach (auto *pSubModifier, pModifier->getModifiers()) {
              Parameter *pParameter = findParameter(pSubModifier->getName());
              applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, hasParentElement, true);
            }
            break;
          }
        }
      }
      if (hasParentElement) {
        fetchClassExtendsModifiers(pExtend);
      }
    }
  }
}

/*!
 * \brief ElementParameters::fetchRootClassExtendsModifiers
 * In case of element mode if the root parent ModelInstance::Element is extend and has modifier.
 * Apply modifier values on the appropriate Parameters.
 * \param pModelElement
 */
void ElementParameters::fetchRootClassExtendsModifiers(ModelInstance::Element *pModelElement)
{
  if (pModelElement && pModelElement->isExtend() && pModelElement->getModifier()) {
    QStringList nameList = StringHandler::makeVariableParts(mpElement->getQualifiedName());
    ModelInstance::Modifier *pModifier = pModelElement->getModifier();
    foreach (QString name, nameList) {
      pModifier = pModifier->getModifier(name);
      if (!pModifier) {
        return;
      }
    }

    if (pModifier && pModifier->getName().compare(mpElement->getName()) == 0) {
      foreach (auto *pSubModifier, pModifier->getModifiers()) {
        Parameter *pParameter = findParameter(pSubModifier->getName());
        applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, false, true);
      }
    }
  }
}

/*!
 * \brief ElementParameters::applyModifier
 * Apply the modifier of the component.
 * \param pModifier
 * \param defaultValue
 */
void ElementParameters::applyModifier(ModelInstance::Modifier *pModifier, bool defaultValue)
{
  if (mNested && pModifier) {
    foreach (auto pSubModifier, pModifier->getModifiers()) {
      Parameter *pParameter = findParameter(pSubModifier->getName());
      applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, defaultValue, false);
      // set final and each checkboxes in the menu
      if (pParameter && !pParameter->isShowStartAndFixed()) {
        pParameter->getFinalEachMenu()->setFinal(pSubModifier->isFinal());
        pParameter->getFinalEachMenu()->setEach(pSubModifier->isEach());
        pParameter->getFinalEachMenu()->setBreak(pSubModifier->isBreak());
      }
    }
  }
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

typedef struct {
  QString mName;
  QString mExtendName;
  bool mInherited;
  QString mKey;
  QString mValue;
  bool mIsReplaceable;
  bool mFinal;
  bool mEach;
  bool mBreak;
  bool mStartAndFixed;
} ElementModifier;

typedef struct {
  QString mName;
  QString mExtendName;
  bool mInherited;
  QString mValue;
} Modifier;

static int accumulatedSize(const QList<Modifier> &list, int seplen)
{
  int result = 0;
  if (!list.isEmpty()) {
    for (const auto &e : list) {
      result += e.mValue.size() + seplen;
    }
    result -= seplen;
  }
  return result;
}

QString modifiersJoin(const QList<Modifier> &list, const QString &sep)
{
  QString result;
  if (!list.isEmpty()) {
    result.reserve(accumulatedSize(list, sep.size()));
    int len = 0;
    for (const auto &e : list) {
      len++;
      result += e.mValue;
      if (len < list.size()) {
        result += sep;
      }
    }
  }
  return result;
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
  QList<ElementModifier> elementModifiersList;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    // if parameter is not visible then continue
    if (pParameter->getGroup().isEmpty()) {
      continue;
    }
    ElementModifier elementModifier;
    elementModifier.mName = pParameter->getName();
    elementModifier.mExtendName = pParameter->getExtendName();
    elementModifier.mInherited = pParameter->isInherited();
    elementModifier.mKey = pParameter->getName();
    QString elementModifierValue = pParameter->getValue();
    elementModifier.mIsReplaceable = (pParameter->isReplaceableComponent() || pParameter->isReplaceableClass());
    elementModifier.mFinal = pParameter->getFinalEachMenu()->isFinal();
    elementModifier.mEach = pParameter->getFinalEachMenu()->isEach();
    elementModifier.mBreak = pParameter->getFinalEachMenu()->isBreak();
    elementModifier.mStartAndFixed = pParameter->isShowStartAndFixed();
    // if break
    if (elementModifier.mBreak) {
      elementModifierValue = Helper::BREAK;
    } else {
      // convert the value to display unit
      if (!pParameter->getUnit().isEmpty()
          && pParameter->getUnit().compare(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString()) != 0) {
        bool ok = true;
        qreal elementModifierRealValue = elementModifierValue.toDouble(&ok);
        // if the modifier is a literal constant
        if (ok) {
          OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(),
                                                                               pParameter->getUnit());
          if (convertUnit.unitsCompatible) {
            elementModifierRealValue = Utilities::convertUnit(elementModifierRealValue, convertUnit.offset, convertUnit.scaleFactor);
            elementModifierValue = StringHandler::number(elementModifierRealValue);
          }
        } else { // if expression
          elementModifierValue = Utilities::arrayExpressionUnitConversion(pOMCProxy, elementModifierValue,
                                                                          pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(),
                                                                          pParameter->getUnit());
        }
      }
    }

    QStringList subModifiers;
    // if value is changed
    if (pParameter->isValueModified()) {
      valueChanged = true;
      // set start value
      if (pParameter->isShowStartAndFixed()) {
        QString startModifier;
        if (pParameter->getFinalEachMenu()->isVisible()) {
          if (pParameter->getFinalEachMenu()->isEach()) {
            startModifier.append("each ");
          }
          if (pParameter->getFinalEachMenu()->isFinal()) {
            startModifier.append("final ");
          }
          if (elementModifierValue.isEmpty()) {
            subModifiers.append(startModifier.append("start"));
          } else {
            subModifiers.append(startModifier.append("start=" % elementModifierValue));
          }
        }
        // set fixed
        if (pParameter->getFixedFinalEachMenu()->isVisible()) {
          QString fixedModifier;
          if (pParameter->getFixedFinalEachMenu()->isEach()) {
            fixedModifier.append("each ");
          }
          if (pParameter->getFixedFinalEachMenu()->isFinal()) {
            fixedModifier.append("final ");
          }
          if (pParameter->getFixedFinalEachMenu()->isBreak()) {
            subModifiers.append(fixedModifier.append("fixed=" % Helper::BREAK));
          } else if (pParameter->getFixedState().isEmpty()) {
            subModifiers.append(fixedModifier.append("fixed"));
          } else {
            subModifiers.append(fixedModifier.append("fixed=" % pParameter->getFixedState()));
          }
        }
      }
      // set displayUnit
      const QString unit = pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString();
      QString displayUnitModifier;
      /* Issue #11715 and #11839
       * Add each prefix if element is an array OR parameter is an array.
       */
      if ((hasElement() && isElementArray()) || pParameter->getModelInstanceElement()->getDimensions().isArray()) {
        displayUnitModifier.append("each ");
      }
      if (pParameter->getDisplayUnitFinalEachMenu()->isFinal()) {
        displayUnitModifier.append("final ");
      }
      // if break displayUnit
      if (pParameter->getDisplayUnitFinalEachMenu()->isBreak()) {
        subModifiers.append(displayUnitModifier.append("displayUnit=" % Helper::BREAK));
      } else if (pParameter->getUnitComboBox()->isEnabled() && !unit.isEmpty() && (pParameter->hasDisplayUnit() || pParameter->getDisplayUnit().compare(unit) != 0)) {
        // if displayUnit is changed OR if we already have the displayUnit modifier then set it
        subModifiers.append(displayUnitModifier.append("displayUnit=\"" % unit % "\""));
      }
      // join the submodifiers
      if (!subModifiers.isEmpty()) {
        elementModifier.mKey.append("(" % subModifiers.join(",") % ")");
      }
      if (pParameter->isShowStartAndFixed()) {
        elementModifier.mValue = "";
      } else {
        elementModifier.mValue = elementModifierValue;
      }
      elementModifiersList.append(elementModifier);
    }
  }
  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged || !mpModifiersTextBox->text().isEmpty()) {
    // apply the new Component modifiers if any
    QList<Modifier> modifiersList;
    foreach (ElementModifier elementModifier, elementModifiersList) {
      int index = elementModifier.mValue.indexOf('(');
      QString modifierStartStr;
      if (index > -1) {
        modifierStartStr = elementModifier.mValue.left(index);
        modifierStartStr = modifierStartStr.remove('(').trimmed();
      }
      QString modifierValue;
      if (elementModifier.mValue.isEmpty()) {
        modifierValue = QString(elementModifier.mKey);
      } else if (elementModifier.mValue.startsWith(QStringLiteral("redeclare")) || ((index > -1) && (modifierStartStr.compare(elementModifier.mKey) == 0))) {
        modifierValue = QString(elementModifier.mValue);
      } else {
        modifierValue = QString(elementModifier.mKey % " = " % elementModifier.mValue);
      }
      // if startandfixed then the final and each are handled with the start value.
      if (!elementModifier.mStartAndFixed) {
        QString modifier;
        // if each
        if (elementModifier.mEach) {
          modifier.append("each ");
        }
        // if final
        if (elementModifier.mFinal) {
          modifier.append("final ");
        }
        // handle redeclare
        if (modifierValue.startsWith(QStringLiteral("redeclare"))) {
          modifierValue.replace("redeclare ", "redeclare " % modifier);
        } else {
          modifierValue.prepend(modifier);
        }
      }
      Modifier modifier;
      modifier.mName = elementModifier.mName;
      modifier.mExtendName = elementModifier.mExtendName;
      modifier.mInherited = elementModifier.mInherited;
      modifier.mValue = modifierValue;
      modifiersList.append(modifier);
    }
    if (mNested) {
      if (modifiersList.isEmpty()) {
        mModification.clear();
      } else {
        mModification = "(" % modifiersJoin(modifiersList, ", ") % ")";
      }
    } else {
      if (hasElement()) {
        // add custom modifiers added by user. See issue #5105
        if (!mpModifiersTextBox->text().isEmpty()) {
          Modifier modifier;
          modifier.mValue = mpModifiersTextBox->text();
          modifiersList.append(modifier);
        }
        QString modifiers = modifiersJoin(modifiersList, ", ");
        if (!modifiers.isEmpty()) {
          // if the element is inherited then add the modifier value into the extends.
          if (mInherited) {
            if (pModelWidget->isElementMode()) {
              ModelInstance::Element *pParentElement = mpElement;
              while (pParentElement) {
                if (pParentElement->isComponent()) {
                  /* Skip adding `each` to this element since it will be added from the dialog if user selects it.
                   * We only automatically add `each` to upper hierarchy elements.
                   * See issue #13126
                   */
                  if (pParentElement != mpElement && pParentElement->getDimensions().isArray()) {
                    modifiers = pParentElement->getName() % "(each " % modifiers % ")";
                  } else {
                    modifiers = pParentElement->getName() % "(" % modifiers % ")";
                  }
                }
                pParentElement = pParentElement->getParentModel() ? pParentElement->getParentModel()->getParentElement() : nullptr;
              }
              pOMCProxy->setExtendsModifierValue(className, mpElement->getTopLevelExtendName(), "_", modifiers);
            } else {
              pOMCProxy->setExtendsModifierValue(className, mpElement->getTopLevelExtendName(), mpElement->getQualifiedName(), modifiers);
            }
          } else {
            pOMCProxy->setElementModifierValue(className, mpElement->getQualifiedName(), modifiers);
          }
          if (pModelWidget->isElementMode()) {
            pModelWidget->setComponentModified(true);
          } else {
            ModelInfo newModelInfo = pModelWidget->createModelInfo();
            pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo,
                                                                  QString("Update Element %1 Parameters").arg(mpElement->getQualifiedName())));
            pModelWidget->updateModelText();
          }
        }
      } else {
        for (const auto &modifier : modifiersList) {
          const QString name = modifier.mName;
          QString value = modifier.mValue;
          if (modifier.mInherited) {
            pOMCProxy->setExtendsModifierValue(className, modifier.mExtendName, "_", value);
          } else {
            if (value.startsWith(name)) {
              value.remove(0, name.size());
            }
            pOMCProxy->setElementModifierValue(className, name, value);
          }
        }

        if (!modifiersList.isEmpty()) {
          ModelInfo newModelInfo = pModelWidget->createModelInfo();
          pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo,
                                                                QString("Update %1 Parameters").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure())));
          pModelWidget->updateModelText();
        }
      }
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
  const QString variability = mpElement->getModelComponent()->getVariability();
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
  mpFinalCheckBox->setChecked(mpElement->getModelComponent()->isFinal());
  mpProtectedCheckBox->setChecked(!mpElement->getModelComponent()->isPublic());
  mpReplaceAbleCheckBox->setChecked(mpElement->getModelComponent()->getReplaceable());
  // get Casuality
  const QString direction = mpElement->getModelComponent()->getDirectionPrefix();
  if (direction.compare(QStringLiteral("input")) == 0) {
    mpInputRadio->setChecked(true);
  } else if (direction.compare(QStringLiteral("output")) == 0) {
    mpOutputRadio->setChecked(true);
  } else {
    mpNoneRadio->setChecked(true);
  }
  // get InnerOuter
  mpInnerCheckBox->setChecked(mpElement->getModelComponent()->isInner());
  mpOuterCheckBox->setChecked(mpElement->getModelComponent()->isOuter());
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
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
      return;
    }
  }
  // check for comma
  if (StringHandler::nameContainsComma(mpNameTextBox->text())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
    return;
  }
  // check for invalid names
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
  QList<QString> result = MainWindow::instance()->getOMCProxy()->parseString(QString("model M N %1; end M;").arg(mpNameTextBox->text()), "M", false);
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
  if (result.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
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
  ModelInfo oldModelInfo = pModelWidget->createModelInfo();
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
  bool attributesChanged = false;
  attributesChanged |= mpElement->getModelComponent()->isFinal() != mpFinalCheckBox->isChecked();
  attributesChanged |= !mpElement->getModelComponent()->isPublic() != mpProtectedCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getReplaceable() ? true : false != mpReplaceAbleCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getVariability().compare(variability) != 0;
  attributesChanged |= mpElement->getModelComponent()->isInner() != mpInnerCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->isOuter() != mpOuterCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getDirectionPrefix().compare(causality) != 0;

  QString isFinal = mpFinalCheckBox->isChecked() ? "true" : "false";
  QString flow = (mpElement->getModelComponent()->getConnector().compare(QStringLiteral("flow")) == 0) ? "true" : "false";
  QString isProtected = mpProtectedCheckBox->isChecked() ? "true" : "false";
  QString isReplaceAble = mpReplaceAbleCheckBox->isChecked() ? "true" : "false";
  QString isInner = mpInnerCheckBox->isChecked() ? "true" : "false";
  QString isOuter = mpOuterCheckBox->isChecked() ? "true" : "false";

  // update element attributes if needed
  if (attributesChanged) {
    if (!pOMCProxy->setComponentProperties(modelName, mpElement->getName(), isFinal, flow, isProtected, isReplaceAble, variability, isInner, isOuter, causality)) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }

  // update the element comment only if its changed.
  if (mpElement->getModelComponent()->getComment().compare(mpCommentTextBox->text()) != 0) {
    QString comment = StringHandler::escapeString(mpCommentTextBox->text());
    if (pOMCProxy->setComponentComment(modelName, mpElement->getName(), comment)) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
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
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the element name only if its changed.
  if (mpElement->getName().compare(mpNameTextBox->text()) != 0) {
    // if renameComponentInClass command is successful update the element with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpElement->getName(), mpNameTextBox->text())) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // push the attributes updated change to the stack
  if (attributesChanged) {
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, QString("Update Element %1 Attributes").arg(mpElement->getName())));
    pModelWidget->updateModelText();
  }
  accept();
}
