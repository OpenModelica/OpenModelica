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

/*
 * RCS: $Id$
 */

#ifndef ICONPROPERTIES_H
#define ICONPROPERTIES_H

#include "Component.h"

class Component;

class IconProperties : public QDialog
{
  Q_OBJECT
public:
  IconProperties(Component *pComponent, QWidget *pParent = 0);
  ~IconProperties();
  void setUpDialog();

  Component *mpComponent;
private:
  QList<QLineEdit*> mParameterTextBoxesList;
  QLabel *mpPropertiesHeading;
  QLabel *mpPixmapLabel;
  QFrame *mHorizontalLine;
  QTabWidget *mpPropertiesTabWidget;
  QWidget *mpGeneralTab;
  QGroupBox *mpComponentGroup;
  QLabel *mpIconNameLabel;
  QLineEdit *mpIconNameTextBox;
  QLabel *mpIconClassLabel;
  QLabel *mpIconClassTextBox;
  QGroupBox *mpModelGroup;
  QLabel *mpIconModelNameLabel;
  QLabel *mpIconModelNameTextBox;
  QLabel *mpIconModelCommentLabel;
  QLabel *mpIconModelCommentTextBox;
  QWidget *mpParametersTab;
  QScrollArea *mpParametersTabScrollArea;
  QWidget *mpModifiersTab;
  QLabel *mpModifiersLabel;
  QLineEdit *mpModifiersTextBox;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void updateIconProperties();
};

class IconAttributes : public QDialog
{
  Q_OBJECT
public:
  IconAttributes(Component *pComponent, QWidget *pParent = 0);
  void setUpDialog();
  void initializeDialog();

  Component *mpComponent;
private:
  QLabel *mpPropertiesHeading;
  QLabel *mpPixmapLabel;
  QFrame *mHorizontalLine;
  QGroupBox *mpTypeGroup;
  QLabel *mpNameLabel;
  QLabel *mpNameTextBox;
  QLabel *mpCommentLabel;
  QLineEdit *mpCommentTextBox;
  QGroupBox *mpVariabilityGroup;
  QButtonGroup *mpVariabilityButtonGroup;
  QRadioButton *mpConstantRadio;
  QRadioButton *mpParameterRadio;
  QRadioButton *mpDiscreteRadio;
  QRadioButton *mpDefaultRadio;
  QGroupBox *mpPropertiesGroup;
  QCheckBox *mpFinalCheckBox;
  QCheckBox *mpProtectedCheckBox;
  QCheckBox *mpReplaceAbleCheckBox;
  QString mIsFlow;
  QGroupBox *mpCausalityGroup;
  QButtonGroup *mpCausalityButtonGroup;
  QRadioButton *mpInputRadio;
  QRadioButton *mpOutputRadio;
  QRadioButton *mpNoneRadio;
  QGroupBox *mpInnerOuterGroup;
  QCheckBox *mpInnerCheckBox;
  QCheckBox *mpOuterCheckBox;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void updateIconAttributes();
};

#endif // ICONPROPERTIES_H
