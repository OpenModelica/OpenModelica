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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef ELEMENTPROPERTIESDIALOG_H
#define ELEMENTPROPERTIESDIALOG_H

#include "Element/Element.h"

class ElementProperties
{
public:
  ElementProperties();

  QList<QString> mParameterValues;
  QList<QString> mInputValues;
};

class ElementPropertiesDialog : public QDialog
{
  Q_OBJECT
public:
  ElementPropertiesDialog(Element *pComponent, QWidget *pParent = 0);
private:
  Element *mpComponent;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpNameLabel;
  QLineEdit *mpNameTextBox;
  Label *mpStartScriptLabel;
  QLineEdit *mpStartScriptTextBox;
  QTabWidget *mpTabWidget;
  QGroupBox *mpGeneralGroupBox;
  Label *mpDescriptionLabel;
  Label *mpDescriptionValueLabel;
  Label *mpFMUKindLabel;
  Label *mpFMUKindValueLabel;
  Label *mpFMIVersionLabel;
  Label *mpFMIVersionValueLabel;
  Label *mpGenerationToolLabel;
  Label *mpGenerationToolValueLabel;
  Label *mpGuidLabel;
  Label *mpGuidValueLabel;
  Label *mpGenerationTimeLabel;
  Label *mpGenerationTimeValueLabel;
  Label *mpModelNameLabel;
  Label *mpModelNameValueLabel;
  QGroupBox *mpCapabilitiesGroupBox;
  Label *mpCanBeInstantiatedOnlyOncePerProcessLabel;
  Label *mpCanBeInstantiatedOnlyOncePerProcessValueLabel;
  Label *mpCanGetAndSetFMUStateLabel;
  Label *mpCanGetAndSetFMUStateValueLabel;
  Label *mpCanNotUseMemoryManagementFunctionsLabel;
  Label *mpCanNotUseMemoryManagementFunctionsValueLabel;
  Label *mpCanSerializeFMUStateLabel;
  Label *mpCanSerializeFMUStateValueLabel;
  Label *mpCompletedIntegratorStepNotNeededLabel;
  Label *mpCompletedIntegratorStepNotNeededValueLabel;
  Label *mpNeedsExecutionToolLabel;
  Label *mpNeedsExecutionToolValueLabel;
  Label *mpProvidesDirectionalDerivativeLabel;
  Label *mpProvidesDirectionalDerivativeValueLabel;
  Label *mpCanInterpolateInputsLabel;
  Label *mpCanInterpolateInputsValueLabel;
  Label *mpMaxOutputDerivativeOrderLabel;
  Label *mpMaxOutputDerivativeOrderValueLabel;
  QList<Label*> mParameterLabels;
  QList<QLineEdit*> mParameterLineEdits;
  QList<Label*> mInputLabels;
  QList<QLineEdit*> mInputLineEdits;
  ElementProperties mOldElementProperties;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void updateProperties();
};

#endif // ELEMENTPROPERTIESDIALOG_H
