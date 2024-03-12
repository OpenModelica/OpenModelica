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

#include "ModelInstanceTest.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"

#define GC_THREADS
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(ModelInstanceTest)

void ModelInstanceTest::initTestCase()
{
  MainWindow::instance()->getLibraryWidget()->openFile(QFINDTESTDATA(mFileName));
  if (!MainWindow::instance()->getOMCProxy()->existClass(mPackageName)) {
    QFAIL(QString("Failed to load file %1").arg(mFileName).toStdString().c_str());
  }

  mpModelInstance = new ModelInstance::Model(MainWindow::instance()->getOMCProxy()->getModelInstance(mModelName));
}

void ModelInstanceTest::classAnnotations()
{
  if (mpModelInstance->getAnnotation()->getIconAnnotation()->getGraphics().isEmpty()) {
    QFAIL("Failed to read the class icon annotation.");
  }

  if (mpModelInstance->getAnnotation()->getDiagramAnnotation()->getGraphics().isEmpty()) {
    QFAIL("Failed to read the class diagram annotation.");
  }
}

void ModelInstanceTest::classElements()
{
  if (mpModelInstance->getElements().isEmpty()) {
    QFAIL("Failed to read the class elements.");
  }
}

void ModelInstanceTest::classConnections()
{
  if (mpModelInstance->getConnections().isEmpty()) {
    QFAIL("Failed to read the class connections.");
  }
}

void ModelInstanceTest::cleanupTestCase()
{
  if (mpModelInstance) {
    delete mpModelInstance;
  }
  MainWindow::instance()->close();
}
