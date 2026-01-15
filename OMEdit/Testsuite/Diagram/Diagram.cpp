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

#include "Diagram.h"
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

OMEDITTEST_MAIN(Diagram)

void Diagram::initTestCase()
{
  QVector<QPair<QString, QString> > libraries;
  libraries.append(qMakePair(QString("Modelica"), QString("default")));
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->addModelicaLibraries(libraries);
}

void Diagram::chuaCircuit()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("Modelica.Electrical.Analog.Examples.ChuaCircuit");
  if (!pLibraryTreeItem) {
    QFAIL("Failed to find Modelica.Electrical.Analog.Examples.ChuaCircuit. Makesure MSL is loaded.");
  }
  if (!Util::expandLibraryTreeItemParentHierarchy(pLibraryTreeItem)) {
    QFAIL("Expanding to Modelica.Electrical.Analog.Examples failed.");
  }

  // Open the Modelica.Electrical.Analog.Examples.ChuaCircuit diagram.
  QModelIndex modelIndex = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->libraryTreeItemIndex(pLibraryTreeItem);
  QModelIndex proxyIndex = MainWindow::instance()->getLibraryWidget()->getLibraryTreeProxyModel()->mapFromSource(modelIndex);
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeView()->libraryTreeItemDoubleClicked(proxyIndex);
}

void Diagram::cleanupTestCase()
{
  MainWindow::instance()->close();
}
