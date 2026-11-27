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

#include "CRMLBindingsTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "OMC/OMCProxy.h"
#include "CRML/Bindings/BindingEngine.h"
#include "CRML/Bindings/ModelIndexBuilder.h"
#include "CRML/Bindings/VerificationGenerator.h"
#include "CRML/Bindings/VerificationConfigurationEditor.h"
#include "Options/OptionsDialog.h"
#include "Util/DirectoryOrFileSelector.h"

#include <QLineEdit>
#include <QListWidget>
#include <QPushButton>
#include <QTableWidget>
#include <QMessageBox>
#include <QTemporaryDir>
#include <QTimer>

OMEDITTEST_MAIN(CRMLBindingsTest)

using namespace CRMLBindings;

static const QString behaviourModel = "PowerPlantLib.Behaviour.CoolingSystem_B1";
static const QString observers = "PowerPlantLib.Observers";
static const QString obsStarted1 = "PowerPlantLib.Observers.Obs_PumpStarted_1";
static const QString obsStarted2 = "PowerPlantLib.Observers.Obs_PumpStarted_2";
static const QString obsStarted3 = "PowerPlantLib.Observers.Obs_PumpStarted_3";
static const QString obsCavitating = "PowerPlantLib.Observers.Obs_PumpCavitating";

static QStringList toStrings(const QList<Diagnostic> &diagnostics)
{
  QStringList list;
  for (const Diagnostic &d : diagnostics) {
    list.append(d.toString());
  }
  return list;
}

static QStringList errorCodes(const Resolution &resolution)
{
  QStringList codes;
  for (const Diagnostic &d : resolution.mDiagnostics) {
    if (d.mSeverity == Diagnostic::Error) {
      codes.append(d.mCode);
    }
  }
  return codes;
}

void CRMLBindingsTest::initTestCase()
{
  for (const QString &file : {QString("CRMLtoModelicaStub.mo"), QString("PowerPlantLib.mo")}) {
    MainWindow::instance()->getLibraryWidget()->openFile(QFINDTESTDATA(file));
  }
  if (!MainWindow::instance()->getOMCProxy()->existClass(behaviourModel)) {
    QFAIL("Failed to load PowerPlantLib.mo");
  }
  QString error;
  QJsonObject json;
  QVERIFY2(readJsonFile(QFINDTESTDATA("CoolingSystem_R_externals.json"), json, &error) && mExternals.fromJson(json, &error), qPrintable(error));
  QVERIFY2(readJsonFile(QFINDTESTDATA("CoolingSystem_A1.architecture.json"), json, &error) && mArchitecture.fromJson(json, &error), qPrintable(error));
  QVERIFY2(readJsonFile(QFINDTESTDATA("CoolingSystem_A1_allocated.architecture.json"), json, &error) && mAllocatedArchitecture.fromJson(json, &error), qPrintable(error));
  QVERIFY2(buildModelIndex(MainWindow::instance()->getOMCProxy(), behaviourModel, {observers}, mIndex, &error), qPrintable(error));
  QCOMPARE(mIndex.mInstances.size(), 5);
  QCOMPARE(mIndex.mObservers.size(), 5);
}

VerificationConfiguration CRMLBindingsTest::discoveredConfiguration(const ArchitectureModel &architecture) const
{
  VerificationConfiguration configuration;
  configuration.mName = "CoolingSystem_Verification";
  configuration.mRequirementFile = "CoolingSystem_R.crml";
  configuration.mBehaviourModel = behaviourModel;
  configuration.mObserverLibraries = {observers};
  BindingDiscovery(mExternals, architecture, mIndex).discover(configuration);
  return configuration;
}

void CRMLBindingsTest::discovery()
{
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);

  QCOMPARE(configuration.mSetBindings.size(), 1);
  QCOMPARE(configuration.mSetBindings.first().mSet, QString("pumps"));
  QCOMPARE(configuration.mSetBindings.first().mTargets.first().mName, QString("Pump_A"));

  const VariableBinding *pInOperation = configuration.findVariableBinding("Pump_R", "inOperation");
  QVERIFY(pInOperation);
  QCOMPARE(pInOperation->mObservers.size(), 3);
  QCOMPARE(pInOperation->mObservers.at(0).mObserver, obsStarted1);
  QCOMPARE(pInOperation->mObservers.at(1).mObserver, obsStarted2);
  QCOMPARE(pInOperation->mObservers.at(2).mObserver, obsStarted3);
  const VariableBinding *pCavitate = configuration.findVariableBinding("Pump_R", "cavitate");
  QVERIFY(pCavitate);
  QCOMPARE(pCavitate->mObservers.size(), 1);
  QCOMPARE(pCavitate->mObservers.first().mObserver, obsCavitating);

  // D2.1.1 3.4.3, bind_input i1 to i4
  const InputBinding *pCavitating = configuration.findInputBinding(obsCavitating);
  QVERIFY(pCavitating);
  QCOMPARE(pCavitating->mStatus, Status::Valid);
  QCOMPARE(pCavitating->mInputs.size(), 3);
  QCOMPARE(pCavitating->findInput("P")->mVariable, QString("Pin"));
  QCOMPARE(pCavitating->findInput("P")->mClass, QString("PowerPlantLib.Behaviour.CentrifugalPump"));
  QCOMPARE(pCavitating->findInput("q")->mVariable, QString("q"));
  QCOMPARE(pCavitating->findInput("NPSH_req")->mSource, InputMapping::Architecture);
  QCOMPARE(pCavitating->findInput("NPSH_req")->mClass, QString("Pump_A"));
  QCOMPARE(configuration.findInputBinding(obsStarted1)->findInput("V")->mClass, QString("PowerPlantLib.Behaviour.ElectricMotor"));
  QVERIFY(!configuration.findInputBinding(obsStarted1)->findInput("Vt")); // threshold keeps its default
  QCOMPARE(configuration.findInputBinding(obsStarted2)->findInput("Cm")->mClass, QString("PowerPlantLib.Behaviour.CentrifugalPump"));

  // D2.1.1 3.4.4, bind_instance i1 to i3, found from the pump ids in the component descriptions
  QStringList pump1, pump3;
  for (const InstanceTarget &target : configuration.findInstanceBinding("pump1")->mTargets) pump1.append(target.mInstance);
  for (const InstanceTarget &target : configuration.findInstanceBinding("pump3")->mTargets) pump3.append(target.mInstance);
  QCOMPARE(pump1, QStringList({"p1", "m1"}));
  QCOMPARE(pump3, QStringList({"p3"}));
}

void CRMLBindingsTest::discoveryFromAllocations()
{
  VerificationConfiguration configuration = discoveredConfiguration(mAllocatedArchitecture);
  const InstanceBinding *pPump1 = configuration.findInstanceBinding("pump1");
  QVERIFY(pPump1);
  QCOMPARE(pPump1->mConfidence, 0.95);
  QCOMPARE(pPump1->mTargets.size(), 2);
  QCOMPARE(pPump1->mTargets.at(1).mInstance, QString("m1"));
  QCOMPARE(pPump1->mTargets.at(1).mRole, QString("inOperation"));
}

void CRMLBindingsTest::resolution()
{
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);
  Resolution resolution = BindingEngine(configuration, mExternals, mArchitecture, mIndex).resolve();
  QVERIFY2(!resolution.hasErrors(), qPrintable(toStrings(resolution.mDiagnostics).join("\n")));

  // D2.1.1 3.5 step 3
  QStringList expressions;
  for (const ResolvedExpression &expression : resolution.mExpressions) {
    expressions.append(expression.mLeft + " = " + expression.call());
  }
  QStringList expected = {
    "req.pumps[1].inOperation = " + obsStarted1 + "(V = behav.m1.V)",
    "req.pumps[1].cavitate = " + obsCavitating + "(P = behav.p1.Pin, q = behav.p1.q, NPSH_req = pump1_NPSH_req)",
    "req.pumps[2].inOperation = " + obsStarted1 + "(V = behav.m2.V)",
    "req.pumps[2].cavitate = " + obsCavitating + "(P = behav.p2.Pin, q = behav.p2.q, NPSH_req = pump2_NPSH_req)",
    "req.pumps[3].inOperation = " + obsStarted2 + "(Cm = behav.p3.Cm)",
    "req.pumps[3].cavitate = " + obsCavitating + "(P = behav.p3.Pin, q = behav.p3.q, NPSH_req = pump3_NPSH_req)"
  };
  QCOMPARE(expressions, expected);
  QCOMPARE(resolution.mSets.first().mElements, QStringList({"pump1", "pump2", "pump3"}));
  QCOMPARE(resolution.mParameters.size(), 3);

  // pump3 has no motor: Obs_PumpStarted_1 is skipped and the fallback is reported
  QStringList warnings;
  for (const Diagnostic &d : resolution.mDiagnostics) {
    if (d.mSeverity == Diagnostic::Warning) warnings.append(d.mCode + " " + d.mMessage);
  }
  QCOMPARE(warnings, QStringList({"VW006 pump3.inOperation uses " + obsStarted2 + ", candidate 2 of Pump_R.inOperation."}));
}

void CRMLBindingsTest::missingObserver()
{
  // without Obs_PumpStarted_2 and _3, no observer of inOperation can be computed for pump3
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);
  for (VariableBinding &binding : configuration.mVariableBindings) {
    if (binding.mVariable == "inOperation") {
      binding.mObservers[1].mEnabled = false;
      binding.mObservers[2].mEnabled = false;
    }
  }
  Resolution resolution = BindingEngine(configuration, mExternals, mArchitecture, mIndex).resolve();
  QCOMPARE(errorCodes(resolution), QStringList({"VW001"}));
  BindingEngine::updateStatus(configuration, resolution);
  QCOMPARE(configuration.findInstanceBinding("pump3")->mStatus, Status::Missing);
  QCOMPARE(configuration.findInstanceBinding("pump1")->mStatus, Status::Valid);
}

void CRMLBindingsTest::ambiguousInstances()
{
  // two pumps bound to pump1: only a role can select the one that gives q and Pin
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);
  for (InstanceBinding &binding : configuration.mInstanceBindings) {
    if (binding.mInstance == "pump1") {
      InstanceTarget target;
      target.mInstance = "p2";
      binding.mTargets.append(target);
    }
  }
  Resolution resolution = BindingEngine(configuration, mExternals, mArchitecture, mIndex).resolve();
  QVERIFY(errorCodes(resolution).contains("VW002"));
  BindingEngine::updateStatus(configuration, resolution);
  QCOMPARE(configuration.findInstanceBinding("pump1")->mStatus, Status::Ambiguous);

  for (InstanceBinding &binding : configuration.mInstanceBindings) {
    if (binding.mInstance == "pump1") binding.mTargets[0].mRole = "cavitate";
  }
  for (VariableBinding &binding : configuration.mVariableBindings) {
    if (binding.mVariable == "cavitate") binding.mRole = "cavitate";
  }
  resolution = BindingEngine(configuration, mExternals, mArchitecture, mIndex).resolve();
  QVERIFY2(!resolution.hasErrors(), qPrintable(toStrings(resolution.mDiagnostics).join("\n")));
  QCOMPARE(resolution.mExpressions.at(1).mArguments.first().mExpression, QString("behav.p1.Pin"));
}

void CRMLBindingsTest::typeMismatch()
{
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);
  for (InputBinding &binding : configuration.mInputBindings) {
    if (binding.mObserver == obsCavitating) {
      for (InputMapping &mapping : binding.mInputs) {
        if (mapping.mInput == "NPSH_req") mapping.mVariable = "id";
      }
    }
  }
  QStringList codes;
  for (const Diagnostic &d : BindingEngine(configuration, mExternals, mArchitecture, mIndex).validate()) codes.append(d.mCode);
  QCOMPARE(codes, QStringList({"VW003"}));
}

void CRMLBindingsTest::configurationRoundTrip()
{
  VerificationConfiguration configuration = discoveredConfiguration(mAllocatedArchitecture);
  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  const QString fileName = directory.filePath("CoolingSystem_Verification.crmlbind.json");
  QString error;
  QVERIFY2(configuration.save(fileName, &error), qPrintable(error));
  VerificationConfiguration loaded;
  QVERIFY2(loaded.load(fileName, &error), qPrintable(error));
  QCOMPARE(loaded.toJson(), configuration.toJson());
}

void CRMLBindingsTest::generateAndSimulate()
{
  VerificationConfiguration configuration = discoveredConfiguration(mArchitecture);
  Resolution resolution = BindingEngine(configuration, mExternals, mArchitecture, mIndex).resolve();
  QVERIFY(!resolution.hasErrors());
  QFile translated(QFINDTESTDATA("CoolingSystem_R_translated.mo"));
  QVERIFY(translated.open(QIODevice::ReadOnly));
  VerificationGenerator generator(configuration, mExternals, mIndex, resolution);
  const QString text = generator.generate(QString::fromUtf8(translated.readAll()));
  QVERIFY(text.contains("CoolingSystem_R req(pumps_n = 3)"));
  QVERIFY(text.contains("parameter Real pump2_NPSH_req[:, 2] = {{0, 50000}, {5, 120000}}"));

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QVERIFY2(pOMCProxy->loadString(text, "CoolingSystem_Verification.mo"), qPrintable(text));
  QString check = pOMCProxy->checkModel(generator.verificationModel());
  QVERIFY2(check.contains("Check of " + generator.verificationModel() + " completed successfully."), qPrintable(check + "\n" + text));

  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  const QString previousDirectory = pOMCProxy->changeDirectory();
  pOMCProxy->changeDirectory(directory.path());
  pOMCProxy->sendCommand(QString("simulate(%1, stopTime = 10)").arg(generator.verificationModel()));
  pOMCProxy->sendCommand(QString("readSimulationResultSize(\"%1_res.mat\")").arg(generator.verificationModel()));
  QVERIFY2(pOMCProxy->getResult().toInt() > 0, qPrintable(pOMCProxy->getErrorString()));

  // R2 is violated because pump PO2 cavitates after about 7 s; PO1 and PO3 satisfy it
  QMap<QString, QString> results;
  for (const RequirementStatusVariable &status : generator.statusVariables()) {
    pOMCProxy->sendCommand(QString("val(%1.y, 10, \"%2_res.mat\")").arg(status.mComponent, generator.verificationModel()));
    results.insert(status.mComponent, requirementResultToString(requirementResultFromBoolean4(qRound(pOMCProxy->getResult().toDouble()))));
  }
  QMap<QString, QString> expected = {
    {"R2_status", "Violated"},
    {"R2_pump1_status", "Satisfied"},
    {"R2_pump2_status", "Violated"},
    {"R2_pump3_status", "Satisfied"}
  };
  pOMCProxy->changeDirectory(previousDirectory);
  QCOMPARE(results, expected);
}

void CRMLBindingsTest::editorEndToEnd()
{
  // drives the editor with a CRML compiler that has --externals-json
  const QString compilerJar = qEnvironmentVariable("CRML_COMPILER_JAR");
  if (compilerJar.isEmpty()) {
    QSKIP("Set CRML_COMPILER_JAR to a CRML compiler jar with --externals-json to run this test.");
  }
  CRMLPage *pCRMLPage = OptionsDialog::instance()->getCRMLPage();
  pCRMLPage->getCompilerJarTextBox()->setText(compilerJar);
  pCRMLPage->getCompilerCommandLineOptionsTextBox()->clear();
  pCRMLPage->getModelicaLibraries()->setItems({});

  // the generated package of generateAndSimulate has the same name
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  pOMCProxy->sendCommand("deleteClass(CoolingSystem_Verification)");

  // an error box would block the test: record its text and close it
  QStringList messageBoxes;
  QTimer messageBoxWatcher;
  connect(&messageBoxWatcher, &QTimer::timeout, [&messageBoxes]() {
    if (QMessageBox *pMessageBox = qobject_cast<QMessageBox*>(QApplication::activeModalWidget())) {
      messageBoxes.append(pMessageBox->text());
      pMessageBox->reject();
    }
  });
  messageBoxWatcher.start(200);

  VerificationConfigurationEditor *pEditor = new VerificationConfigurationEditor(QFINDTESTDATA("CoolingSystem_R.crml"));
  pEditor->findChild<QLineEdit*>("ArchitectureTextBox")->setText(QFINDTESTDATA("CoolingSystem_A1.architecture.json"));
  pEditor->findChild<QLineEdit*>("BehaviourTextBox")->setText(behaviourModel);
  pEditor->findChild<QLineEdit*>("ObserversTextBox")->setText(observers);
  QCOMPARE(pEditor->findChild<QLineEdit*>("NameTextBox")->text(), QString("CoolingSystem_R_Verification"));

  pEditor->findChild<QPushButton*>("AutoDiscoverButton")->click();
  QVERIFY2(messageBoxes.isEmpty(), qPrintable(messageBoxes.join("\n")));
  QListWidget *pDiagnostics = pEditor->findChild<QListWidget*>("DiagnosticsListWidget");
  QStringList diagnostics;
  for (int i = 0; i < pDiagnostics->count(); ++i) diagnostics.append(pDiagnostics->item(i)->text());
  QCOMPARE(diagnostics, QStringList({"Warning VW006: pump3.inOperation uses " + obsStarted2 + ", candidate 2 of Pump_R.inOperation. [v1]"}));
  QTableWidget *pInstances = pEditor->findChild<QTableWidget*>("InstanceBindingsTable");
  QCOMPARE(pInstances->rowCount(), 3);
  QCOMPARE(pInstances->item(0, 1)->text(), QString("p1, m1"));

  pEditor->findChild<QPushButton*>("GenerateButton")->click();
  QVERIFY(pOMCProxy->existClass("CoolingSystem_R_Verification.Verification"));
  QVERIFY(pEditor->findChild<QPushButton*>("SimulateButton")->isEnabled());
  pEditor->findChild<QPushButton*>("SimulateButton")->click();
  QVERIFY2(messageBoxes.isEmpty(), qPrintable(messageBoxes.join("\n")));
  QTableWidget *pResults = pEditor->findChild<QTableWidget*>("ResultsTable");
  QStringList results;
  for (int row = 0; row < pResults->rowCount(); ++row) {
    results.append(QString("%1 %2 %3").arg(pResults->item(row, 0)->text(), pResults->item(row, 1)->text(), pResults->item(row, 2)->text()).simplified());
  }
  QCOMPARE(results, QStringList({"R2 Violated", "R2 pump1 Satisfied", "R2 pump2 Violated", "R2 pump3 Satisfied"}));
  pEditor->close();
}
