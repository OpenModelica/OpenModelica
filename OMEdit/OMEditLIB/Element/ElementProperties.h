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

#ifndef COMPONENTPROPERTIES_H
#define COMPONENTPROPERTIES_H

#include "Element.h"

#include <QRadioButton>

class FinalEachToolButton : public QToolButton
{
  Q_OBJECT
public:
  FinalEachToolButton(bool canHaveEach, QWidget *parent = nullptr);

  void setFinal(bool final);
  bool isFinal() const {return mpFinalAction->isChecked();}
  void setEach(bool each);
  bool isEach() const {return mpEachAction->isChecked();}
  void setBreak(bool break_);
  bool isBreak() const {return mpBreakAction->isChecked();}
  bool isModified() const;
private:
  QMenu *mpFinalEachMenu;
  QAction *mpFinalAction;
  bool mFinalDefault = false;
  QAction *mpEachAction;
  bool mEachDefault = false;
  QAction *mpBreakAction;
  bool mBreakDefault = false;
signals:
  void breakToggled(bool breakValue);
public slots:
  void showParameterMenu();
};

class ElementParametersOld;
class ElementParameters;
class Parameter : public QObject
{
  Q_OBJECT
public:
  enum ValueType {
    Normal,  /* Integer, Real etc. */
    Boolean,
    CheckBox,
    Enumeration,
    ReplaceableComponent,
    ReplaceableClass,
    Record,
    Choices,
    ChoicesAllMatching
  };
  Parameter(ModelInstance::Element *pElement, bool defaultValue, ElementParameters *pElementParameters);
  ModelInstance::Element* getModelInstanceElement() {return mpModelInstanceElement;}
  bool isParameter() const;
  bool isInput() const;
  void setTab(QString tab) {mTab = tab;}
  const StringAnnotation &getTab() {return mTab;}
  void setGroup(QString group) {mGroup = group;}
  const StringAnnotation &getGroup() {return mGroup;}
  void setGroupDefined(bool groupDefined) {mGroupDefined = groupDefined;}
  bool isGroupDefined() const {return mGroupDefined;}
  void setShowStartAttribute(bool showStartAttribute) {mShowStartAttribute = showStartAttribute;}
  bool isShowStartAttribute() const {return mShowStartAttribute;}
  void setShowStartAndFixed(bool showStartAndFixed) {mShowStartAndFixed = showStartAndFixed;}
  bool isShowStartAndFixed() const {return mShowStartAndFixed;}
  const StringAnnotation &getGroupImage() const {return mGroupImage;}
  void updateNameLabel();
  QString getName() const {return mName;}
  QString getExtendName() const {return mExtendName;}
  bool isInherited() const {return mInherited;}
  Label* getNameLabel() {return mpNameLabel;}
  FixedCheckBox* getFixedCheckBox() {return mpFixedCheckBox;}
  QString getOriginalFixedValue() const {return mOriginalFixedValue;}
  FinalEachToolButton *getFixedFinalEachMenu() const {return mpFixedFinalEachMenuButton;}
  void setValueType(ValueType valueType) {mValueType = valueType;}
  void setValueWidget(QString value, bool defaultValue, QString fromUnit, bool valueModified = false, bool adjustSize = true, bool unitComboBoxChanged = false);
  bool isEnumeration() const {return mValueType == Enumeration;}
  bool isReplaceableComponent() const {return mValueType == ReplaceableComponent;}
  bool isReplaceableClass() const {return mValueType == ReplaceableClass;}
  bool isRecord() const {return mValueType == Record;}
  bool isChoices() const {return mValueType == Choices;}
  QWidget* getValueWidget();
  bool isValueModified();
  QString getValue();
  void hideValueWidget();
  QToolButton *getEditClassButton() const {return mpEditClassButton;}
  FinalEachToolButton *getFinalEachMenu() const {return mpFinalEachMenuButton;}
  QToolButton* getFileSelectorButton() {return mpFileSelectorButton;}
  void setLoadSelectorFilter(QString loadSelectorFilter) {mLoadSelectorFilter = loadSelectorFilter;}
  QString getLoadSelectorFilter() {return mLoadSelectorFilter;}
  void setLoadSelectorCaption(QString loadSelectorCaption) {mLoadSelectorCaption = loadSelectorCaption;}
  QString getLoadSelectorCaption() {return mLoadSelectorCaption;}
  void setSaveSelectorFilter(QString saveSelectorFilter) {mSaveSelectorFilter = saveSelectorFilter;}
  QString getSaveSelectorFilter() {return mSaveSelectorFilter;}
  void setSaveSelectorCaption(QString saveSelectorCaption) {mSaveSelectorCaption = saveSelectorCaption;}
  QString getSaveSelectorCaption() {return mSaveSelectorCaption;}
  void setHasDisplayUnit(bool hasDisplayUnit) {mHasDisplayUnit = hasDisplayUnit;}
  bool hasDisplayUnit() const {return mHasDisplayUnit;}
  QString getUnit() {return mUnit;}
  void setDisplayUnit(QString displayUnit) {mDisplayUnit = displayUnit;}
  QString getDisplayUnit() {return mDisplayUnit;}
  QComboBox* getUnitComboBox() {return mpUnitComboBox;}
  FinalEachToolButton *getDisplayUnitFinalEachMenu() const {return mpDisplayUnitFinalEachMenuButton;}
  Label* getCommentLabel() {return mpCommentLabel;}
  bool isStartFinalInHierarchy() const {return mStartFinalInHierarchy;}
  void setStartFinalInHierarchy(bool startFinalInHierarchy) {mStartFinalInHierarchy = startFinalInHierarchy;}
  bool isFixedFinalInHierarchy() const {return mFixedFinalInHierarchy;}
  void setFixedFinalInHierarchy(bool fixedFinalInHierarchy) {mFixedFinalInHierarchy = fixedFinalInHierarchy;}
  void setFixedState(QString fixed, bool defaultValue);
  QString getFixedState() const;
  void setEnabled(bool enable);
  void update();
private:
  ModelInstance::Element *mpModelInstanceElement;
  ElementParameters *mpElementParameters = 0;
  StringAnnotation mTab;
  StringAnnotation mGroup;
  bool mGroupDefined;
  BooleanAnnotation mEnable;
  BooleanAnnotation mShowStartAttribute;
  bool mShowStartAndFixed;
  BooleanAnnotation mColorSelector;
  StringAnnotation mLoadSelectorFilter;
  StringAnnotation mLoadSelectorCaption;
  StringAnnotation mSaveSelectorFilter;
  StringAnnotation mSaveSelectorCaption;
  StringAnnotation mGroupImage;
  BooleanAnnotation mConnectorSizing;

  QString mName;
  QString mExtendName;
  bool mInherited;
  Label *mpNameLabel;
  FixedCheckBox *mpFixedCheckBox;
  QString mOriginalFixedValue;
  FinalEachToolButton *mpFixedFinalEachMenuButton = 0;
  ValueType mValueType;
  bool mValueCheckBoxModified;
  QString mDefaultValue;
  QComboBox *mpValueComboBox;
  QLineEdit *mpValueTextBox;
  QCheckBox *mpValueCheckBox;
  QToolButton *mpEditClassButton = 0;
  FinalEachToolButton *mpFinalEachMenuButton = 0;
  QToolButton *mpFileSelectorButton;
  bool mHasDisplayUnit = false;
  QString mUnit;
  QString mDisplayUnit;
  QString mPreviousUnit;
  QComboBox *mpUnitComboBox;
  FinalEachToolButton *mpDisplayUnitFinalEachMenuButton = 0;
  Label *mpCommentLabel;
  bool mStartFinalInHierarchy = false;
  bool mFixedFinalInHierarchy = false;

  void createEditClassButton();
  void createValueWidget();
  void enableDisableUnitComboBox(const QString &value);
  void updateValueBinding(const FlatModelica::Expression expression);
  bool isValueModifiedHelper() const;
  void resetUnitCombobox();
private slots:
  void setBreakValue(bool breakValue);
public slots:
  void editClassButtonClicked();
  void fileSelectorButtonClicked();
  void unitComboBoxChanged(int index);
  void valueComboBoxChanged(int index);
  void valueCheckBoxChanged(bool toggle);
  void showFixedMenu();
  void trueFixedClicked();
  void falseFixedClicked();
  void inheritedFixedClicked();
  // QObject interface
public:
  virtual bool eventFilter(QObject *pWatched, QEvent *pEvent) override;
};

class GroupBox : public QGroupBox
{
  Q_OBJECT
public:
  GroupBox(const QString &title, QWidget* parent=0);
  void setGroupImage(QString groupImage);
  QGridLayout *getGridLayout() {return mpGridLayout;}
private:
  Label *mpGroupImageLabel;
  QGridLayout *mpGridLayout;
  QHBoxLayout *mpHorizontalLayout;
};

class ParametersScrollArea : public QScrollArea
{
  Q_OBJECT
public:
  ParametersScrollArea();
  virtual QSize minimumSizeHint() const override;
  int groupBoxesSize() {return mGroupBoxesList.size();}
  void addGroupBox(GroupBox *pGroupBox);
  GroupBox *getGroupBox(const QString &title);
  GroupBox *getGroupBox(int index) {return mGroupBoxesList.at(index);}
  QVBoxLayout* getLayout();
private:
  QWidget *mpWidget;
  QList<GroupBox*> mGroupBoxesList;
  QVBoxLayout *mpVerticalLayout;
};

class ElementParameters : public QDialog
{
  Q_OBJECT
public:
  ElementParameters(ModelInstance::Element *pElement, GraphicsView *pGraphicsView, bool inherited, bool nested, ModelInstance::Modifier *pDefaultElementModifier,
                    ModelInstance::Modifier *pReplaceableConstrainedByModifier, ModelInstance::Modifier *pElementModifier, QWidget *pParent = 0);
  ~ElementParameters();
  QString getElementParentClassName() const;
  QString getComponentClassName() const;
  QString getComponentClassComment() const;
  ModelInstance::Model *getModel() const;
  GraphicsView *getGraphicsView() const {return mpGraphicsView;}
  bool hasElement() const {return mpElement ? true : false;}
  bool isElementArray() const {return mpElement->getDimensions().isArray();}
  bool isInherited() const {return mInherited;}
  QString getModification() const {return mModification;}
  void applyFinalStartFixedAndDisplayUnitModifiers(Parameter *pParameter, ModelInstance::Modifier *pModifier, bool defaultValue, bool isElementModification);
  void updateParameters();
private:
  ModelInstance::Element *mpElement;
  GraphicsView *mpGraphicsView;
  bool mInherited;
  bool mNested;
  ModelInstance::Modifier *mpDefaultElementModifier;
  ModelInstance::Modifier *mpReplaceableConstrainedByModifier;
  ModelInstance::Modifier *mpElementModifier;
  QString mModification;
  Label *mpParametersHeading;
  QFrame *mHorizontalLine;
  QTabWidget *mpParametersTabWidget;
  QGroupBox *mpComponentGroupBox;
  Label *mpComponentNameLabel;
  Label *mpComponentNameTextBox;
  Label *mpComponentCommentLabel;
  Label *mpComponentCommentTextBox;
  QGroupBox *mpComponentClassGroupBox;
  Label *mpComponentClassNameLabel;
  Label *mpComponentClassNameTextBox;
  Label *mpComponentClassCommentLabel;
  Label *mpComponentClassCommentTextBox;
  Label *mpModifiersLabel;
  QLineEdit *mpModifiersTextBox;
  QMap<QString, int> mTabsMap;
  QList<Parameter*> mParametersList;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void setUpDialog();
  void createTabsGroupBoxesAndParameters(ModelInstance::Model *pModelInstance, bool defaultValue);
  void fetchElementExtendsModifiers(ModelInstance::Model *pModelInstance, bool defaultValue);
  void fetchModifiers(ModelInstance::Modifier *pModifier);
  void fetchRootElementModifiers(ModelInstance::Element *pModelElement);
  void fetchClassExtendsModifiers(ModelInstance::Element *pModelElement);
  void fetchRootClassExtendsModifiers(ModelInstance::Element *pModelElement);
  void applyModifier(ModelInstance::Modifier *pModifier, bool defaultValue);
  Parameter* findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
public slots:
  void commentLinkClicked(QString link);
  void updateElementParameters();
  virtual void reject() override;
};

class ElementAttributes : public QDialog
{
  Q_OBJECT
public:
  ElementAttributes(Element *pElement, QWidget *pParent = 0);
  void setUpDialog();
  void initializeDialog();
private:
  Element *mpElement;
  Label *mpAttributesHeading;
  QFrame *mHorizontalLine;
  QGroupBox *mpTypeGroupBox;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpDimensionsLabel;
  QLineEdit *mpDimensionsTextBox;
  Label *mpCommentLabel;
  QLineEdit *mpCommentTextBox;
  Label *mpPathLabel;
  Label *mpPathTextBox;
  QGroupBox *mpVariabilityGroupBox;
  QButtonGroup *mpVariabilityButtonGroup;
  QRadioButton *mpConstantRadio;
  QRadioButton *mpParameterRadio;
  QRadioButton *mpDiscreteRadio;
  QRadioButton *mpDefaultRadio;
  QGroupBox *mpPropertiesGroupBox;
  QCheckBox *mpFinalCheckBox;
  QCheckBox *mpProtectedCheckBox;
  QCheckBox *mpReplaceAbleCheckBox;
  QString mIsFlow;
  QGroupBox *mpCausalityGroupBox;
  QButtonGroup *mpCausalityButtonGroup;
  QRadioButton *mpInputRadio;
  QRadioButton *mpOutputRadio;
  QRadioButton *mpNoneRadio;
  QGroupBox *mpInnerOuterGroupBox;
  QCheckBox *mpInnerCheckBox;
  QCheckBox *mpOuterCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void updateElementAttributes();
};

#endif // COMPONENTPROPERTIES_H
