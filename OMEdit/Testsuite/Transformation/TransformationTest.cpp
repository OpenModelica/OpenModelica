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

#include "TransformationTest.h"
#include "Util.h"
#include "MainWindow.h"
#include "Element/Transformation.h"

OMEDITTEST_MAIN(TransformationTest)

void TransformationTest::wrongPlacementAnnotation()
{
  QString placementAnnotationString = "{Placement(true,-,{{-140.0, 40.0}, {-100.0, 80.0}},-,-,-,)}";

  Transformation transformation;
  transformation.parseTransformationString(placementAnnotationString, 200, 200);
}

void TransformationTest::correctPlacementAnnotation()
{
  QString placementAnnotationString = "{Placement(true,-75.0,38.0,-25.0,-25.0,25.0,25.0,270.0,-,-,-,-,-,-,)}";

  Transformation transformation;
  transformation.parseTransformationString(placementAnnotationString, 200, 200);
}

void TransformationTest::cleanupTestCase()
{
  MainWindow::instance()->close();
}
