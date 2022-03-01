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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include "DiagramWindow.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Plotting/PlotWindowContainer.h"
#include "Plotting/VariablesWidget.h"

/*!
 * \class DiagramWindow
 * \brief Diagram window for the DiagramGraphicsView.
 */
/*!
 * \brief DiagramWindow::DiagramWindow
 * \param parent
 */
DiagramWindow::DiagramWindow(QWidget *parent) : QWidget(parent)
{
  setObjectName("diagramWindow");
  setWindowTitle("Diagram");

  mpModelWidget = 0;
  mpMainLayout = new QVBoxLayout;
  mpMainLayout->setContentsMargins(0, 0, 0, 0);
  setLayout(mpMainLayout);
}

/*!
 * \brief DiagramWindow::showVisualizationDiagram
 * Shows the diagram graphics view of the passed ModelWidget for visualization.
 * \param pModelWidget
 */
void DiagramWindow::showVisualizationDiagram(ModelWidget *pModelWidget)
{
  if (pModelWidget && pModelWidget->getDiagramGraphicsView() && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    setWindowTitle(pModelWidget->getLibraryTreeItem()->getName());
    mpModelWidget = pModelWidget;
    mpModelWidget->getDiagramGraphicsView()->setIsVisualizationView(true);
    connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), mpModelWidget->getDiagramGraphicsView(), SIGNAL(updateDynamicSelect(double)));
    mpModelWidget->getDiagramGraphicsView()->show();
    mpMainLayout->addWidget(mpModelWidget->getDiagramGraphicsView());
  } else {
    removeVisualizationDiagram();
  }
}

/*!
 * \brief DiagramWindow::removeVisualizationDiagram
 * When the corresponding ModelWidget is about to delete then clear the DiagramWindow.
 */
void DiagramWindow::removeVisualizationDiagram()
{
  if (mpModelWidget) {
    // set the window title to default
    setWindowTitle("Diagram");
    disconnect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), mpModelWidget->getDiagramGraphicsView(), SIGNAL(updateDynamicSelect(double)));
    mpMainLayout->removeWidget(mpModelWidget->getDiagramGraphicsView());
  }
}

/*!
 * \brief DiagramWindow::closeEvent
 * Removes DiagramWindow from PlotWindowContainer.
 * \param event
 */
void DiagramWindow::closeEvent(QCloseEvent *event)
{
  Q_UNUSED(event);
  MainWindow::instance()->getPlotWindowContainer()->removeSubWindow(this);
}
