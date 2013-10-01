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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
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

class Parameter
{
public:
  Parameter(ComponentInfo *pComponentInfo, OMCProxy *pOMCProxy, QString className, QString componentBaseClassName,
            QString componentClassName, QString componentName, bool parametersOnly, bool inheritedComponent, QString inheritedClassName);
  Label* getNameLabel();
  QLineEdit* getValueTextBox();
  Label* getUnitLabel();
  Label* getCommentLabel();
  QString getUnitFromDerivedClass(OMCProxy *pOMCProxy, QString className);
private:
  Label *mpNameLabel;
  QLineEdit *mpValueTextBox;
  Label *mpUnitLabel;
  Label *mpCommentLabel;
};

class ParametersScrollArea : public QScrollArea
{
  Q_OBJECT
public:
  ParametersScrollArea();
  void addGroupBox(QGroupBox *pGroupBox, QGridLayout *pGroupBoxLayout);
  QGroupBox* getGroupBox(QString title);
  QGridLayout* getGroupBoxLayout(QString title);
  QVBoxLayout* getLayout();
private:
  QWidget *mpWidget;
  QList<QGroupBox*> mGroupBoxesList;
  QList<QGridLayout*> mGroupBoxesLayoutList;
  QVBoxLayout *mpVerticalLayout;
};

class ComponentParameters : public QDialog
{
  Q_OBJECT
public:
  ComponentParameters(bool parametersOnly, Component *pComponent, MainWindow *pMainWindow);
  ~ComponentParameters();
  void setUpDialog();
  void createTabsAndGroupBoxes(OMCProxy *pOMCProxy, QString componentClassName);
  void createParameters(OMCProxy *pOMCProxy, QString className, QString componentBaseClassName, QString componentClassName,
                        QString componentName, bool inheritedComponent, QString inheritedClassName, bool isInheritedCycle = false);
  QList<Parameter*> getParametersList();
private:
  bool mParametersOnly;
  Component *mpComponent;
  MainWindow *mpMainWindow;
  Label *mpParametersHeading;
  QFrame *mHorizontalLine;
  QTabWidget *mpParametersTabWidget;
  QGroupBox *mpComponentGroupBox;
  Label *mpComponentNameLabel;
  Label *mpComponentNameTextBox;
  Label *mpComponentClassNameLabel;
  Label *mpComponentClassNameTextBox;
  Label *mpModifiersLabel;
  QLineEdit *mpModifiersTextBox;
  QMap<QString, int> mTabsMap;
  QList<Parameter*> mParametersList;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
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
  ComponentInfo *mpComponentInfo;
  Label *mpAttributesHeading;
  QFrame *mHorizontalLine;
  QGroupBox *mpTypeGroupBox;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
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

#endif // COMPONENTPROPERTIES_H
