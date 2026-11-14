/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef CRMLVERIFICATIONCONFIGURATIONEDITOR_H
#define CRMLVERIFICATIONCONFIGURATIONEDITOR_H

#include "BindingEngine.h"
#include "VerificationGenerator.h"

#include <QDialog>

class QLineEdit;
class QListWidget;
class QPushButton;
class QTableWidget;
class QTabWidget;

/*!
 * \brief The VerificationConfigurationEditor class
 * Edits a CRML verification configuration: the models, the set, variable, input and instance
 * bindings, and generates and simulates the verification model (MODRIO D2.1.1 3.4 and 3.5).
 */
class VerificationConfigurationEditor : public QDialog
{
  Q_OBJECT
public:
  VerificationConfigurationEditor(const QString &crmlFile, QWidget *pParent = nullptr);
private:
  CRMLBindings::VerificationConfiguration mConfiguration;
  CRMLBindings::CrmlExternals mExternals;
  CRMLBindings::ArchitectureModel mArchitecture;
  CRMLBindings::ModelIndex mIndex;
  CRMLBindings::Resolution mResolution;
  QList<CRMLBindings::RequirementStatusVariable> mStatusVariables;
  QString mTranslatedRequirement;
  QString mConfigurationFile;
  QString mVerificationModel;
  QString mResultFile;
  bool mModelsLoaded = false;

  QTabWidget *mpTabWidget;
  QLineEdit *mpNameTextBox;
  QLineEdit *mpRequirementTextBox;
  QLineEdit *mpArchitectureTextBox;
  QLineEdit *mpBehaviourTextBox;
  QLineEdit *mpObserversTextBox;
  QTableWidget *mpSetBindingsTable;
  QTableWidget *mpVariableBindingsTable;
  QTableWidget *mpInputBindingsTable;
  QTableWidget *mpInstanceBindingsTable;
  QListWidget *mpDiagnosticsListWidget;
  QTableWidget *mpResultsTable;
  QPushButton *mpGenerateButton;
  QPushButton *mpSimulateButton;
  QPushButton *mpPlotButton;

  QWidget *createModelsTab();
  QTableWidget *createTable(const QStringList &headers);
  void readModelsTab();
  void fillModelsTab();
  void fillTables();
  bool readTables();
  void setStatusItem(QTableWidget *pTable, int row, int column, CRMLBindings::Status status, double confidence);
  void showDiagnostics(const QList<CRMLBindings::Diagnostic> &diagnostics);
  bool translateRequirement(QString *pError);
  bool ensureModelsLoaded();
  QString outputDirectory() const;
private slots:
  void browseRequirement();
  void browseArchitecture();
  void loadModels();
  void autoDiscover();
  void validate();
  void generate();
  void simulate();
  void plotResults();
  void openConfiguration();
  void saveConfiguration();
};

#endif // CRMLVERIFICATIONCONFIGURATIONEDITOR_H
