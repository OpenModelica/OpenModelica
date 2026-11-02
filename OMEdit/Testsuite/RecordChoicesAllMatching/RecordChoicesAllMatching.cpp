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

#include "RecordChoicesAllMatching.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

#include <QComboBox>

OMEDITTEST_MAIN(RecordChoicesAllMatching)

void RecordChoicesAllMatching::initTestCase()
{
  const QString fileName = QFINDTESTDATA("RecordChoicesAllMatching.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("RecordChoicesAllMatching")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void RecordChoicesAllMatching::recordParameterChoicesHaveInstantiationSuffix()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("RecordChoicesAllMatching.ClassWithInstance");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find the library tree item for RecordChoicesAllMatching.ClassWithInstance.");
  }
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (!pModelWidget) {
    QFAIL("Failed to create the model widget for RecordChoicesAllMatching.ClassWithInstance.");
  }
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  if (!pDiagramGraphicsView) {
    QFAIL("The model widget of RecordChoicesAllMatching.ClassWithInstance has no diagram graphics view.");
  }
  Element *pClassWithRecordParam = pDiagramGraphicsView->getElementObject("classWithRecordParam");
  if (!pClassWithRecordParam) {
    QFAIL("Failed to find the classWithRecordParam diagram element.");
  }
  ModelInstance::Component *pClassWithRecordParamModel = pClassWithRecordParam->getModelComponent();
  if (!pClassWithRecordParamModel) {
    QFAIL("The classWithRecordParam diagram element has no model component.");
  }
  /* Create the ElementParameters dialog without exec() so that no dialog is shown.
   * The constructor builds the parameters list of the component type and delegates it.
   */
  ElementParameters *pElementParameters = new ElementParameters(pClassWithRecordParamModel, pDiagramGraphicsView, false, false, false, 0, 0, 0, MainWindow::instance());
  /* The record parameter must use choicesAllMatching=true to offer all record subtypes. */
  Parameter *pRecordParam = pElementParameters->findParameter("recordParam");
  QVERIFY(pRecordParam);
  if (pRecordParam) {
    QVERIFY(pRecordParam->isChoicesAllMatching());
    QComboBox *pChoicesComboBox = qobject_cast<QComboBox*>(pRecordParam->getValueWidget());
    QVERIFY(pChoicesComboBox);
    if (pChoicesComboBox) {
      /* Every record subtype offered by choicesAllMatching=true must have ()
       * appended so it can be instantiated, e.g. RecordA() instead of RecordA.
       */
      bool foundRecordA = false;
      bool foundRecordB = false;
      for (int i = 0; i < pChoicesComboBox->count(); ++i) {
        const QString value = pChoicesComboBox->itemData(i).toString();
        if (value.endsWith("RecordChoicesAllMatching.RecordA()")) {
          foundRecordA = true;
        } else if (value.endsWith("RecordChoicesAllMatching.RecordB()")) {
          foundRecordB = true;
        }
      }
      QVERIFY2(foundRecordA, "RecordA() is missing from the record parameter choices.");
      QVERIFY2(foundRecordB, "RecordB() is missing from the record parameter choices.");
    }
  }
  delete pElementParameters;
}

void RecordChoicesAllMatching::cleanupTestCase()
{
  MainWindow::instance()->close();
}
