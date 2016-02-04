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

#ifndef COMPONENTPROPERTIES_H
#define COMPONENTPROPERTIES_H

#include "Component.h"

class Parameter : public QObject
{
  Q_OBJECT
public:
  enum ValueType {
    Normal,  /* Integer, Real etc. */
    Boolean,
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
  void setValueWidget(QString value, bool defaultValue);
  ValueType getValueType() {return mValueType;}
  QWidget* getValueWidget();
  bool isValueModified();
  QString getValue();
  Label* getUnitLabel() {return mpUnitLabel;}
  Label* getCommentLabel() {return mpCommentLabel;}
  void setFixedState(QString fixed, bool defaultValue);
  QString getFixedState();
  QString getUnitFromDerivedClass(Component *pComponent);
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
  QComboBox *mpValueComboBox;
  QLineEdit *mpValueTextBox;
  Label *mpUnitLabel;
  Label *mpCommentLabel;

  void createValueWidget();
public slots:
  void valueComboBoxChanged(int index);
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
  ComponentParameters(Component *pComponent, MainWindow *pMainWindow);
  ~ComponentParameters();
private:
  Component *mpComponent;
  MainWindow *mpMainWindow;
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
  void updateComponentParameters();
};

class ComponentAttributes : public QDialog
{
  Q_OBJECT
public:
  ComponentAttributes(Component *pComponent, MainWindow *pMainWindow);
  void setUpDialog();
  void initializeDialog();
private:
  Component *mpComponent;
  MainWindow *mpMainWindow;
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

class SubModelAttributes : public QDialog
{
  Q_OBJECT
public:
  SubModelAttributes(Component *pComponent, MainWindow *pMainWindow);
  void setUpDialog();
  void initializeDialog();
private:
  Component *mpComponent;
  MainWindow *mpMainWindow;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpSimulationToolLabel;
  QComboBox *mpSimulationToolComboBox;
  Label *mpStartCommandLabel;
  QLineEdit *mpStartCommandTextBox;
  Label *mpModelFileLabel;
  QLineEdit *mpModelFileTextBox;
  Label *mpExactStepFlagLabel;
  QCheckBox *mpExactStepFlagCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void changeSimulationToolStartCommand(QString tool);
  void changeSimulationTool(QString simulationToolStartCommand);
  void updateSubModelParameters();
};

class Component;
class TLMInterfacePointInfo
{
public:
  TLMInterfacePointInfo(QString name, QString className, QString interfaceName);
  QString getName();
  QString getClassName();
  QString getInterfaceName();
  void setInterfaceName(QString interfaceName);
private:
  QString mName;
  QString mClassName;
  QString mInterfaceName;
};

class LineAnnotation;
class TLMConnectionAttributes : public QDialog
{
  Q_OBJECT
public:
  TLMConnectionAttributes(LineAnnotation *pConnectionLineAnnotation, MainWindow *pMainWindow);
  void setUpDialog();
  void initializeDialog();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  MainWindow *mpMainWindow;
  QList<TLMInterfacePointInfo*> mInterfacepointsList;
  Label *mpStartSubModelNameLabel;
  QLineEdit *mpStartSubModelNameTextBox;
  QComboBox *mpStartSubModelInterfacePointComboBox;
  QComboBox *mpEndSubModelInterfacePointComboBox;
  Label *mpEndSubModelNameLabel;
  QLineEdit *mpEndSubModelNameTextBox;
  Label *mpDelayLabel;
  QLineEdit *mpDelayTextBox;
  Label *mpZfLabel;
  QLineEdit *mpZfTextBox;
  Label *mpZfrLabel;
  QLineEdit *mpZfrTextBox;
  Label *mpAlphapLabel;
  QLineEdit *mpAlphaTextBox;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void createTLMConnection();
};

#endif // COMPONENTPROPERTIES_H
