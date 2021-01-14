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

  mpGraphicsScene = 0;
  mpGraphicsView = 0;

  mpMainLayout = new QVBoxLayout;
  mpMainLayout->setContentsMargins(0, 0, 0, 0);
  setLayout(mpMainLayout);
}

/*!
 * \brief DiagramWindow::drawDiagram
 * Draws the diagram based on the passed ModelWidget.
 * \param pModelWidget
 */
void DiagramWindow::drawDiagram(ModelWidget *pModelWidget)
{
  if (pModelWidget && pModelWidget->getDiagramGraphicsView()) {
    setWindowTitle(pModelWidget->getLibraryTreeItem()->getName());
    deleteGraphicsViewAndScene();
    mpGraphicsScene = new GraphicsScene(StringHandler::Diagram, pModelWidget);
    mpGraphicsView = new GraphicsView(StringHandler::Diagram, pModelWidget, true);
    mpGraphicsView->setScene(mpGraphicsScene);
    mpGraphicsView->setCoOrdinateSystem(pModelWidget->getDiagramGraphicsView()->getCoOrdinateSystem());
    mpGraphicsView->mMergedCoOrdinateSystem = pModelWidget->getDiagramGraphicsView()->mMergedCoOrdinateSystem;
    mpGraphicsView->setExtentRectangle(pModelWidget->getDiagramGraphicsView()->mMergedCoOrdinateSystem.getExtentRectangle());
    mpMainLayout->addWidget(mpGraphicsView);
    // draw inherited shapes
    foreach (ShapeAnnotation *pReferenceShapeAnnotation, pModelWidget->getDiagramGraphicsView()->getInheritedShapesList()) {
      ShapeAnnotation *pShapeAnnotation = ModelWidget::createInheritedShape(pReferenceShapeAnnotation, mpGraphicsView);
      mpGraphicsView->addShapeToList(pShapeAnnotation);
      connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), pShapeAnnotation, SLOT(updateDynamicSelect(double)));
    }
    // draw shapes
    foreach (ShapeAnnotation *pReferenceShapeAnnotation, pModelWidget->getDiagramGraphicsView()->getShapesList()) {
      ShapeAnnotation *pShapeAnnotation = ModelWidget::createInheritedShape(pReferenceShapeAnnotation, mpGraphicsView);
      mpGraphicsView->addShapeToList(pShapeAnnotation);
      connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), pShapeAnnotation, SLOT(updateDynamicSelect(double)));
    }
    // draw inherited elements
    foreach (Element *pReferenceComponent, pModelWidget->getDiagramGraphicsView()->getInheritedElementsList()) {
      Element *pElement = new Element(pReferenceComponent, mpGraphicsView);
      mpGraphicsView->addElementToList(pElement);
      connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), pElement, SLOT(updateDynamicSelect(double)));
    }
    // draw elements
    foreach (Element *pReferenceComponent, pModelWidget->getDiagramGraphicsView()->getElementsList()) {
      Element *pElement = new Element(pReferenceComponent, mpGraphicsView);
      mpGraphicsView->addElementToList(pElement);
      connect(MainWindow::instance()->getVariablesWidget(), SIGNAL(updateDynamicSelect(double)), pElement, SLOT(updateDynamicSelect(double)));
    }
    // draw inherited connections
    foreach (LineAnnotation *pConnectionLineAnnotation, pModelWidget->getDiagramGraphicsView()->getInheritedConnectionsList()) {
      LineAnnotation *pNewConnectionLineAnnotation = new LineAnnotation(pConnectionLineAnnotation, mpGraphicsView);
      pNewConnectionLineAnnotation->drawCornerItems();
      pNewConnectionLineAnnotation->setCornerItemsActiveOrPassive();
      pNewConnectionLineAnnotation->applyTransformation();
      mpGraphicsView->addConnectionToList(pNewConnectionLineAnnotation);
    }
    // draw connections
    foreach (LineAnnotation *pConnectionLineAnnotation, pModelWidget->getDiagramGraphicsView()->getConnectionsList()) {
      LineAnnotation *pNewConnectionLineAnnotation = new LineAnnotation(pConnectionLineAnnotation, mpGraphicsView);
      pNewConnectionLineAnnotation->drawCornerItems();
      pNewConnectionLineAnnotation->setCornerItemsActiveOrPassive();
      pNewConnectionLineAnnotation->applyTransformation();
      mpGraphicsView->addConnectionToList(pNewConnectionLineAnnotation);
    }
    // draw transitions
    foreach (LineAnnotation *pTransitionLineAnnotation, pModelWidget->getDiagramGraphicsView()->getTransitionsList()) {
      LineAnnotation *pNewTransitionLineAnnotation = new LineAnnotation(pTransitionLineAnnotation, mpGraphicsView);
      pNewTransitionLineAnnotation->updateToolTip();
      pNewTransitionLineAnnotation->drawCornerItems();
      pNewTransitionLineAnnotation->setCornerItemsActiveOrPassive();
      pNewTransitionLineAnnotation->applyTransformation();
      mpGraphicsView->addTransitionToList(pNewTransitionLineAnnotation);
    }
  }
}

/*!
 * \brief DiagramWindow::removeDiagram
 * When the corresponding ModelWidget is about to delete then clear the DiagramWindow.
 * \param pModelWidget
 */
void DiagramWindow::removeDiagram(ModelWidget *pModelWidget)
{
  if (mpGraphicsView && mpGraphicsView->getModelWidget() == pModelWidget) {
    // set the window title to default
    setWindowTitle("Diagram");
    deleteGraphicsViewAndScene();
  }
}

/*!
 * \brief DiagramWindow::deleteGraphicsViewAndScene
 * Clears the GraphicsView and deletes it and GraphicsScene.
 */
void DiagramWindow::deleteGraphicsViewAndScene()
{
  // Stop any running visualization
  MainWindow::instance()->getVariablesWidget()->rewindVisualization();
  if (mpGraphicsView) {
    mpGraphicsView->clearGraphicsView();
    mpMainLayout->removeWidget(mpGraphicsView);
    mpGraphicsView->deleteLater();
    mpGraphicsView = 0;
  }
  if (mpGraphicsScene) {
    mpGraphicsScene->deleteLater();
    mpGraphicsScene = 0;
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
