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

#include "BrowseMSL.h"
#include "Util.h"
#include "OMEditApplication.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"

#define GC_THREADS
extern "C" {
#include "meta/meta_modelica.h"
}

OMEDITTEST_MAIN(BrowseMSL)

void BrowseMSL::electricalAnalogBasic()
{
  if (!Util::expandLibraryTreeItemParentHierarchy(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("Modelica.Electrical.Analog.Basic"))) {
    QFAIL("Expanding to Modelica.Electrical.Analog.Basic failed.");
  }
}

void BrowseMSL::mediaAir()
{
  OMEDITTEST_SKIP("Enable this testcase by removing this line once the ticket#5669 (https://trac.openmodelica.org/OpenModelica/ticket/5669) is fixed.");
  if (!Util::expandLibraryTreeItemParentHierarchy(MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("Modelica.Media.Air"))) {
    QFAIL("Expanding to Modelica.Media.Air failed.");
  }
}

void BrowseMSL::cleanupTestCase()
{
  MainWindow::instance()->close();
}
