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

#include "Component.h"

#include <QRadioButton>

class Parameter : public QObject
{
  Q_OBJECT
public:
  enum ValueType {
    Normal,  /* Integer, Real etc. */
    Boolean,
    CheckBox,
    Enumeration
  };
  Parameter(Component *pComponent, bool showStartAttribute, QString tab, QString groupBox);
  Component* getComponent() {return mpComponent;}
  void setTab(QString tab) {mTab = tab;}
  QString getTab() {return mTab;}
  void setGroupBox(QString groupBox) {mGroupBox = groupBox;}
  QString getGroupBox() {return mGroupBox;}
  void setShowStartAttribute(bool showStartAttribute) {mShowStartAttribute = showStartAttribute;}
  bool isShowStartAttribute() {return mShowStartAttribute;}
  void updateNameLabel();
  Label* getNameLabel() {return mpNameLabel;}
  FixedCheckBox* getFixedCheckBox() {return mpFixedCheckBox;}
  QString getOriginalFixedValue() {return mOriginalFixedValue;}
  void setValueType(ValueType valueType) {mValueType = valueType;}
  void setValueWidget(QString value, bool defaultValue, QString fromUnit, bool valueModified = false, bool adjustSize = true);
  ValueType getValueType() {return mValueType;}
  QWidget* getValueWidget();
  bool isValueModified();
  QString getValue();
  QString getDefaultValue();
  QToolButton* getFileSelectorButton() {return mpFileSelectorButton;}
  void setLoadSelectorFilter(QString loadSelectorFilter) {mLoadSelectorFilter = loadSelectorFilter;}
  QString getLoadSelectorFilter() {return mLoadSelectorFilter;}
  void setLoadSelectorCaption(QString loadSelectorCaption) {mLoadSelectorCaption = loadSelectorCaption;}
  QString getLoadSelectorCaption() {return mLoadSelectorCaption;}
  void setSaveSelectorFilter(QString saveSelectorFilter) {mSaveSelectorFilter = saveSelectorFilter;}
  QString getSaveSelectorFilter() {return mSaveSelectorFilter;}
  void setSaveSelectorCaption(QString saveSelectorCaption) {mSaveSelectorCaption = saveSelectorCaption;}
  QString getSaveSelectorCaption() {return mSaveSelectorCaption;}
  QString getUnit() {return mUnit;}
  void setDisplayUnit(QString displayUnit) {mDisplayUnit = displayUnit;}
  QString getDisplayUnit() {return mDisplayUnit;}
  QComboBox* getUnitComboBox() {return mpUnitComboBox;}
  Label* getCommentLabel() {return mpCommentLabel;}
  void setFixedState(QString fixed, bool defaultValue);
  QString getFixedState();
  QString getModifierValueFromDerivedClass(Component *pComponent, QString modifierName);
  void setEnabled(bool enable);
private:
  Component *mpComponent;
  QString mTab;
  QString mGroupBox;
  bool mShowStartAttribute;
  Label *mpNameLabel;
  FixedCheckBox *mpFixedCheckBox;
  QString mOriginalFixedValue;
  ValueType mValueType;
  bool mValueCheckBoxModified;
  QString mDefaultValue;
  QComboBox *mpValueComboBox;
  QLineEdit *mpValueTextBox;
  QCheckBox *mpValueCheckBox;
  QToolButton *mpFileSelectorButton;
  QString mLoadSelectorFilter;
  QString mLoadSelectorCaption;
  QString mSaveSelectorFilter;
  QString mSaveSelectorCaption;
  QString mUnit;
  QString mDisplayUnit;
  QString mPreviousUnit;
  QComboBox *mpUnitComboBox;
  Label *mpCommentLabel;

  void createValueWidget();
public slots:
  void fileSelectorButtonClicked();
  void unitComboBoxChanged(QString text);
  void valueComboBoxChanged(int index);
  void valueCheckBoxChanged(bool toggle);
  void showFixedMenu();
  void trueFixedClicked();
  void falseFixedClicked();
  void inheritedFixedClicked();
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
  virtual QSize minimumSizeHint() const;
  void addGroupBox(GroupBox *pGroupBox);
  GroupBox *getGroupBox(QString title);
  QVBoxLayout* getLayout();
private:
  QWidget *mpWidget;
  QList<GroupBox*> mGroupBoxesList;
  QVBoxLayout *mpVerticalLayout;
};

class ComponentParameters : public QDialog
{
  Q_OBJECT
public:
  ComponentParameters(Component *pComponent, QWidget *pParent = 0);
  ~ComponentParameters();
private:
  Component *mpComponent;
  Label *mpParametersHeading;
  QFrame *mHorizontalLine;
  QTabWidget *mpParametersTabWidget;
  QGroupBox *mpComponentGroupBox;
  Label *mpComponentNameLabel;
  Label *mpComponentNameTextBox;
  QGroupBox *mpComponentClassGroupBox;
  Label *mpComponentClassNameLabel;
  Label *mpComponentClassNameTextBox;
  Label *mpComponentClassCommentLabel;
  Label *mpComponentClassCommentTextBox;
  Label *mpModifiersLabel;
  QLineEdit *mpModifiersTextBox;
  QMap<QString, int> mTabsMap;
  QList<Parameter*> mParametersList;
  QList<Parameter*> mOrderedParametersList;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  void setUpDialog();
  void createTabsGroupBoxesAndParameters(LibraryTreeItem *pLibraryTreeItem);
  void createTabsGroupBoxesAndParametersHelper(LibraryTreeItem *pLibraryTreeItem, bool useInsert = false);
  void fetchComponentModifiers();
  void fetchExtendsModifiers();
  Parameter* findParameter(LibraryTreeItem *pLibraryTreeItem, const QString &parameter,
                           Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
  Parameter* findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity = Qt::CaseSensitive) const;
public slots:
  void commentLinkClicked(QString link);
  void updateComponentParameters();
};

class ComponentAttributes : public QDialog
{
  Q_OBJECT
public:
  ComponentAttributes(Component *pComponent, QWidget *pParent = 0);
  void setUpDialog();
  void initializeDialog();
private:
  Component *mpComponent;
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
  void updateComponentAttributes();
};

class CompositeModelSubModelAttributes : public QDialog
{
  Q_OBJECT
public:
  CompositeModelSubModelAttributes(Component *pComponent, QWidget *pParent = 0);
  void setUpDialog();
  void initializeDialog();
private:
  Component *mpComponent;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpSimulationToolLabel;
  QComboBox *mpSimulationToolComboBox;
  Label *mpStartCommandLabel;
  QLineEdit *mpStartCommandTextBox;
  Label *mpModelFileLabel;
  QLineEdit *mpModelFileTextBox;
  Label *mpExactStepFlagLabel;
  QCheckBox *mpExactStepCheckBox;
  Label *mpGeometryFileLabel;
  QLineEdit *mpGeometryFileTextBox;
  QPushButton *mpGeometryFileBrowseButton;
  QScrollArea *mpParametersScrollArea;
  QWidget *mpParametersScrollWidget;
  QGridLayout *mpParametersLayout;
  QLabel *mpParametersLabel;
  QList<QLabel*> mParameterLabels;
  QList<QLineEdit*> mParameterLineEdits;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void changeSimulationToolStartCommand(QString tool);
  void changeSimulationTool(QString simulationToolStartCommand);
  void browseGeometryFile();
  void updateSubModelParameters();
};

class LineAnnotation;
class CompositeModelConnectionAttributes : public QDialog
{
  Q_OBJECT
public:
  CompositeModelConnectionAttributes(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, bool edit, QWidget *pParent = 0);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpConnectionLineAnnotation;
  bool mEdit;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpFromLabel;
  Label *mpConnectionStartLabel;
  Label *mpToLabel;
  Label *mpConnectionEndLabel;
  Label *mpDelayLabel;
  QLineEdit *mpDelayTextBox;
  Label *mpZfLabel;
  QLineEdit *mpZfTextBox;
  Label *mpZfrLabel;
  QLineEdit *mpZfrTextBox;
  Label *mpAlphapLabel;
  QLineEdit *mpAlphaTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void createCompositeModelConnection();
};

#endif // COMPONENTPROPERTIES_H
