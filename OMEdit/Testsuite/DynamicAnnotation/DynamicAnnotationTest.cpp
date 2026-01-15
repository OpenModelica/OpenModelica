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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "DynamicAnnotationTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"

#ifndef GC_THREADS
#define GC_THREADS
#endif
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(DynamicAnnotationTest)

void DynamicAnnotationTest::initTestCase()
{
  MainWindow::instance()->getLibraryWidget()->openFile(QFINDTESTDATA(mFileName));
  if (!MainWindow::instance()->getOMCProxy()->existClass(mPackageName)) {
    QFAIL(QString("Failed to load file %1").arg(mFileName).toStdString().c_str());
  }

  mpModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(mModelName));
}

void DynamicAnnotationTest::evaluate()
{
  // check model instance
  if (!mpModelInstance) {
    QFAIL(QString("Model instance of %1 is NULL.").arg(mModelName).toStdString().c_str());
  }
  // get the element test from the model instance
  QList<ModelInstance::Element*> elements = mpModelInstance->getElements();
  if (elements.size() < 2) {
    QFAIL(QString("Failed to read the class elements of %1.").arg(mpModelInstance->getName()).toStdString().c_str());
  } else {
    // get the first element
    ModelInstance::Element *pTestElement = elements.at(1);
    if (pTestElement->getModel()->getElements().isEmpty()) {
      QFAIL(QString("Failed to read the class elements of %1.").arg(pTestElement->getModel()->getName()).toStdString().c_str());
    } else {
      // read the dialog annotation of element and then evaluate it
      ModelInstance::Element *pElement = pTestElement->getModel()->getElements().at(0);
      auto &dialogAnnotation = pElement->getAnnotation()->getDialogAnnotation();
      mEnable = dialogAnnotation.isEnabled();
      mEnable.evaluate(mpModelInstance);
      // mEnable should be false after evaluation
      if (mEnable) {
        QFAIL(QString("Failed to evaluate the expression %1 in %2.").arg(mEnable.toQString(), pElement->getQualifiedName()).toStdString().c_str());
      }
    }
  }
}

void DynamicAnnotationTest::cleanupTestCase()
{
  if (mpModelInstance) {
    delete mpModelInstance;
  }
  MainWindow::instance()->close();
}
