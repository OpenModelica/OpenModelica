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

#include "OuterParameterDialogTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

OMEDITTEST_MAIN(OuterParameterDialogTest)

void OuterParameterDialogTest::initTestCase()
{
  const QString fileName = QFINDTESTDATA("OuterParameterDialogMWE.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("OuterParameterDialogMWE")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void OuterParameterDialogTest::parametersOfSystemComponent1()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("OuterParameterDialogMWE.System");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find the library tree item for OuterParameterDialogMWE.System.");
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL("Failed to create the model widget for OuterParameterDialogMWE.System.");
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL("The model widget of OuterParameterDialogMWE.System has no diagram graphics view.");
  }
  Element *pComponent1 = pDiagramGraphicsView->getElementObject("Component1");
  if (!pComponent1) {
    QFAIL("Failed to find the Component1 diagram element.");
  }
  ModelInstance::Component *pComponent1Model = pComponent1->getModelComponent();
  if (!pComponent1Model) {
    QFAIL("The Component1 diagram element has no model component.");
  }
  /* Create the ElementParameters dialog without exec() so that no dialog is shown.
   * The constructor builds the parameters list of the component type and delegates it.
   */
  ElementParameters *pElementParameters = new ElementParameters(pComponent1Model, pDiagramGraphicsView, false, false, false, 0, 0, 0, MainWindow::instance());
  /* Issue #14750: outer parameters must not be listed in the parameters dialog. */
  QVERIFY(!pElementParameters->findParameter("globalTime"));
  /* The local parameter must still be listed. */
  Parameter *pLocalTimeParameter = pElementParameters->findParameter("localTime");
  QVERIFY(pLocalTimeParameter);
  if (pLocalTimeParameter) {
    QCOMPARE(pLocalTimeParameter->getModelInstanceElement()->isOuter(), false);
  }
  delete pElementParameters;
}

void OuterParameterDialogTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}