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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "ReplaceableConstrainedByTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Model.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

#include <QApplication>
#include <QTimer>
#include <QToolButton>

OMEDITTEST_MAIN(ReplaceableConstrainedByTest)

void ReplaceableConstrainedByTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("DefaultParamToParamWithoutDefault.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("DefaultParamToParamWithoutDefault")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void ReplaceableConstrainedByTest::subDialogUsesParameterDefaultValue()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("DefaultParamToParamWithoutDefault.ClassWithInstance");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find the library tree item for DefaultParamToParamWithoutDefault.ClassWithInstance.");
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL("Failed to create the model widget for DefaultParamToParamWithoutDefault.ClassWithInstance.");
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL("The model widget of DefaultParamToParamWithoutDefault.ClassWithInstance has no diagram graphics view.");
  }
  Element *pClassWithReplaceables = pDiagramGraphicsView->getElementObject("classWithReplaceables");
  if (!pClassWithReplaceables) {
    QFAIL("Failed to find the classWithReplaceables diagram element.");
  }
  ModelInstance::Component *pClassWithReplaceablesComponent = pClassWithReplaceables->getModelComponent();
  if (!pClassWithReplaceablesComponent) {
    QFAIL("The classWithReplaceables diagram element has no model component.");
  }
  ElementParameters *pElementParameters = new ElementParameters(pClassWithReplaceablesComponent, pDiagramGraphicsView, false, false, false, 0, 0, 0, MainWindow::instance());

  /* The enclosing parameter only has a default value, it is not set. */
  Parameter *pTypeParamParameter = pElementParameters->findParameter("typeParam");
  if (!pTypeParamParameter) {
    QFAIL("The element parameters dialog of classWithReplaceables has no typeParam parameter.");
  }
  QVERIFY(pTypeParamParameter->getValue().isEmpty());
  QCOMPARE(pTypeParamParameter->getDefaultValue(), QString("DefaultParamToParamWithoutDefault.SomeType.Type1"));

  Parameter *pReplRecord1Parameter = pElementParameters->findParameter("replRecord1");
  if (!pReplRecord1Parameter) {
    QFAIL("The element parameters dialog of classWithReplaceables has no replRecord1 parameter.");
  }
  QToolButton *pEditClassButton = pReplRecord1Parameter->getEditClassButton();
  if (!pEditClassButton) {
    QFAIL("The replRecord1 parameter has no edit class button.");
  }

  bool subDialogFound = false;
  bool realParam1Found = false;
  bool realParam1Enabled = false;
  bool realParam2Found = false;
  bool realParam2Enabled = false;
  QString typeParamBinding;
  QString unexpectedModalWidget;

  /* The sub dialog is shown with QDialog::exec(), i.e. it blocks in a nested event loop,
   * so it has to be inspected and closed from the event loop.
   */
  QTimer timer;
  timer.setInterval(50);
  int attempts = 0;
  connect(&timer, &QTimer::timeout, this, [&]() {
    ElementParameters *pSubDialog = nullptr;
    for (QWidget *pWidget : QApplication::allWidgets()) {
      auto pDialog = qobject_cast<ElementParameters*>(pWidget);
      if (pDialog && pDialog != pElementParameters && pDialog->isVisible()) {
        pSubDialog = pDialog;
        break;
      }
    }
    if (!pSubDialog) {
      /* Give the sub dialog up to ten seconds to show up, then close an unexpected modal
       * widget so that exec() returns instead of blocking the test.
       */
      if (++attempts > 200) {
        timer.stop();
        if (QWidget *pModalWidget = QApplication::activeModalWidget()) {
          unexpectedModalWidget = pModalWidget->metaObject()->className();
          pModalWidget->close();
        }
      }
      return;
    }

    timer.stop();
    subDialogFound = true;
    if (Parameter *pRealParam1 = pSubDialog->findParameter("realParam1")) {
      realParam1Found = true;
      realParam1Enabled = pRealParam1->getValueWidget()->isEnabled();
      /* The typeParam of the record must be bound to the default value of the classWithReplaceables typeParam. */
      ModelInstance::Model *pRecordModel = pRealParam1->getModelInstanceElement()->getParentModel();
      if (pRecordModel) {
        if (ModelInstance::Element *pRecordTypeParam = pRecordModel->lookupElement("typeParam")) {
          typeParamBinding = pRecordTypeParam->getBinding().toQString();
        }
      }
    }
    if (Parameter *pRealParam2 = pSubDialog->findParameter("realParam2")) {
      realParam2Found = true;
      realParam2Enabled = pRealParam2->getValueWidget()->isEnabled();
    }
    pSubDialog->reject();
  });
  timer.start();
  pEditClassButton->click();
  timer.stop();

  if (!unexpectedModalWidget.isEmpty()) {
    QFAIL(qPrintable(QString("The sub dialog of the replRecord1 parameter showed the unexpected modal widget %1.").arg(unexpectedModalWidget)));
  }
  QVERIFY2(subDialogFound, "The sub dialog of the replRecord1 parameter was not shown.");
  QVERIFY2(realParam1Found, "The sub dialog of the replRecord1 parameter has no realParam1 parameter.");
  QVERIFY2(realParam2Found, "The sub dialog of the replRecord1 parameter has no realParam2 parameter.");
  /* Issue #16642: an empty parameter value must not replace the constrainedby modifier, it has to be
   * replaced with the default value of the parameter so that the enable annotations of the record
   * are evaluated with it.
   */
  QCOMPARE(typeParamBinding, pTypeParamParameter->getDefaultValue());
  QVERIFY2(realParam1Enabled, "realParam1 is disabled although typeParam defaults to DefaultParamToParamWithoutDefault.SomeType.Type1.");
  QVERIFY2(!realParam2Enabled, "realParam2 is enabled although typeParam defaults to DefaultParamToParamWithoutDefault.SomeType.Type1.");

  delete pElementParameters;
}

void ReplaceableConstrainedByTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
