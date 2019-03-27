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

#ifndef TRANSLATIONFLAGSWIDGET_H
#define TRANSLATIONFLAGSWIDGET_H

#include <QWidget>
#include <QComboBox>
#include <QCheckBox>
#include <QLineEdit>
#include <QToolButton>

class SimulationOptions;
class Label;
class TranslationFlagsWidget : public QWidget
{
  Q_OBJECT
public:
  TranslationFlagsWidget(QWidget *pParent = 0);
  QComboBox *getMatchingAlgorithmComboBox() const {return mpMatchingAlgorithmComboBox;}
  QComboBox *getIndexReductionMethodComboBox() const {return mpIndexReductionMethodComboBox;}
  QCheckBox *getInitializationCheckBox() const {return mpInitializationCheckBox;}
  QCheckBox *getEvaluateAllParametersCheckBox() const {return mpEvaluateAllParametersCheckBox;}
  QCheckBox *getNLSanalyticJacobianCheckBox() const {return mpNLSanalyticJacobianCheckBox;}
  QCheckBox *getPedanticCheckBox() const {return mpPedanticCheckBox;}
  QCheckBox *getParmodautoCheckBox() const {return mpParmodautoCheckBox;}
  QCheckBox *getNewInstantiationCheckBox() const {return mpNewInstantiationCheckBox;}
  QCheckBox *getDataReconciliationCheckBox() const {return mpDataReconciliationCheckBox;}
  QLineEdit *getAdditionalTranslationFlagsTextBox() const {return mpAdditionalTranslationFlagsTextBox;}

  void applySimulationOptions(const SimulationOptions &simulationOptions);
  void createSimulationOptions(SimulationOptions *pSimulationOptions);
  bool applyFlags();
  QString commandLineOptions();
private:
  Label *mpMatchingAlgorithmLabel;
  QComboBox *mpMatchingAlgorithmComboBox;
  Label *mpIndexReductionMethodLabel;
  QComboBox *mpIndexReductionMethodComboBox;
  QCheckBox *mpInitializationCheckBox;
  QCheckBox *mpEvaluateAllParametersCheckBox;
  QCheckBox *mpNLSanalyticJacobianCheckBox;
  QCheckBox *mpPedanticCheckBox;
  QCheckBox *mpParmodautoCheckBox;
  QCheckBox *mpNewInstantiationCheckBox;
  QCheckBox *mpDataReconciliationCheckBox;
  Label *mpAdditionalTranslationFlagsLabel;
  QLineEdit *mpAdditionalTranslationFlagsTextBox;
  QToolButton *mpTranslationFlagsHelpButton;
private slots:
  void updateMatchingAlgorithmToolTip(int index);
  void updateIndexReductionToolTip(int index);
  void showTranslationFlagsHelp();
};

#endif // TRANSLATIONFLAGSWIDGET_H
