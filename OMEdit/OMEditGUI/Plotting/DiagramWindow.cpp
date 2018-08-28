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

  mpGraphicsScene = 0;
  mpGraphicsView = 0;

  mpMainLayout = new QVBoxLayout;
  mpMainLayout->setContentsMargins(0, 0, 0, 0);
  setLayout(mpMainLayout);
}

/*!
 * \brief DiagramWindow::drawDiagram
 * Draw the diagram based on the current ModelWidget.
 */
void DiagramWindow::drawDiagram()
{
  // Stop any running visualization when we are going to draw a diagram.
  MainWindow::instance()->getVariablesWidget()->rewindVisualization();

  ModelWidget *pModelWidget = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget();
  if (pModelWidget && pModelWidget->getDiagramGraphicsView()) {
    if (mpGraphicsView) {
      delete mpGraphicsScene;
      mpGraphicsScene = 0;
      mpMainLayout->removeWidget(mpGraphicsView);
      delete mpGraphicsView;
      mpGraphicsView = 0;
    }
    mpGraphicsScene = new GraphicsScene(StringHandler::Diagram, pModelWidget);
    mpGraphicsView = new GraphicsView(StringHandler::Diagram, pModelWidget, true);
    mpGraphicsView->setScene(mpGraphicsScene);
    mpMainLayout->addWidget(mpGraphicsView);
    foreach (Component *pReferenceComponent, pModelWidget->getDiagramGraphicsView()->getComponentsList()) {
      Component *pComponent = new Component(pReferenceComponent, mpGraphicsView);
      mpGraphicsView->addComponentToList(pComponent);
      connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), pComponent, SLOT(updateDynamicSelect(double)));
    }
    foreach (LineAnnotation *pConnectionLineAnnotation, pModelWidget->getDiagramGraphicsView()->getConnectionsList()) {
      LineAnnotation *pNewConntionLineAnnotation = new LineAnnotation(pConnectionLineAnnotation, mpGraphicsView);
      pNewConntionLineAnnotation->initializeTransformation();
      pNewConntionLineAnnotation->drawCornerItems();
      pNewConntionLineAnnotation->setCornerItemsActiveOrPassive();
      mpGraphicsView->addConnectionToList(pNewConntionLineAnnotation);
    }
    foreach (LineAnnotation *pTransitionLineAnnotation, pModelWidget->getDiagramGraphicsView()->getTransitionsList()) {
      LineAnnotation *pNewTransitionLineAnnotation = new LineAnnotation(pTransitionLineAnnotation, mpGraphicsView);
      pNewTransitionLineAnnotation->initializeTransformation();
      pNewTransitionLineAnnotation->updateToolTip();
      pNewTransitionLineAnnotation->drawCornerItems();
      pNewTransitionLineAnnotation->setCornerItemsActiveOrPassive();
      mpGraphicsView->addTransitionToList(pNewTransitionLineAnnotation);
    }
  }
}
