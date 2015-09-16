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

#include "Commands.h"

AddComponentCommand::AddComponentCommand(QString name, QString className, QString transformationString, QPointF point,
                                         ComponentInfo *pComponentInfo, StringHandler::ModelicaClasses type, bool addObject, bool openingClass,
                                         bool inheritedClass, QString inheritedClassName, QString fileName, bool addOnlyToCurrentView,
                                         GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mType = type;
  mAddObject = addObject;
  mAddOnlyToCurrentView = addOnlyToCurrentView;
  mpIconComponent = 0;
  mpDiagramComponent = 0;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mpGraphicsView = pGraphicsView;
  setText(QString("Added Component %1").arg(name));

  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  QString annotation = "";
  // if component is of connector type && containing class is Modelica type.
  if (mType == StringHandler::Connector && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    if (mAddOnlyToCurrentView) {
      if (mpGraphicsView->getViewType() == StringHandler::Icon) {
        annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
        mpIconComponent = new Component(annotation, name, className, fileName, pComponentInfo, type, transformationString, point,
                                        inheritedClass, inheritedClassName, pMainWindow->getOMCProxy(), mpGraphicsView);
      } else {
        annotation = pMainWindow->getOMCProxy()->getDiagramAnnotation(className);
        // if diagram annotation is empty then use the icon annotation of the connector.
        if (StringHandler::removeFirstLastCurlBrackets(annotation).isEmpty()) {
          annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
        }
        mpDiagramComponent = new Component(annotation, name, className, fileName, pComponentInfo, type, transformationString, point,
                                           inheritedClass, inheritedClassName, pMainWindow->getOMCProxy(), mpGraphicsView);
      }
    } else {
      // first create the component for Icon View
      annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
      mpIconComponent = new Component(annotation, name, className, fileName, pComponentInfo, type, transformationString, point, inheritedClass,
                                      inheritedClassName, pMainWindow->getOMCProxy(), mpIconGraphicsView);
      // now create the component for Diagram View
      annotation = pMainWindow->getOMCProxy()->getDiagramAnnotation(className);
      // if diagram annotation is empty then use the icon annotation of the connector.
      if (StringHandler::removeFirstLastCurlBrackets(annotation).isEmpty()) {
        annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
      }
      mpDiagramComponent = new Component(annotation, name, className, fileName, new ComponentInfo(pComponentInfo), type, transformationString,
                                         point, inheritedClass, inheritedClassName, pMainWindow->getOMCProxy(), mpDiagramGraphicsView);
    }
  } else {
    if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      annotation = pMainWindow->getOMCProxy()->getIconAnnotation(className);
    }
    mpDiagramComponent = new Component(annotation, name, className, fileName, pComponentInfo, type, transformationString, point,
                                       inheritedClass, inheritedClassName, pMainWindow->getOMCProxy(), mpDiagramGraphicsView);
  }
  // only select the component of the active Icon/Diagram View
  if (!openingClass) {
    // unselect all items
    foreach (QGraphicsItem *pItem, mpGraphicsView->items()) {
      pItem->setSelected(false);
    }
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      mpIconComponent->setSelected(true);
    } else {
      mpDiagramComponent->setSelected(true);
    }
  }
}

/*!
 * \brief AddComponentCommand::redo
 * Redo the AddComponentCommand.
 */
void AddComponentCommand::redo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mType == StringHandler::Connector && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    if (mAddOnlyToCurrentView) {
      if (mpGraphicsView->getViewType() == StringHandler::Icon) {
        mpIconGraphicsView->scene()->addItem(mpIconComponent);
        mpIconGraphicsView->scene()->addItem(mpIconComponent->getOriginItem());
        mpIconGraphicsView->addComponentToList(mpIconComponent);
      } else {
        mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent);
        mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent->getOriginItem());
        mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
      }
    } else {
      // first add the component to Icon View
      mpIconGraphicsView->scene()->addItem(mpIconComponent);
      mpIconGraphicsView->scene()->addItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->addComponentToList(mpIconComponent);
      // now add the component to Diagram View
      mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent);
      mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent->getOriginItem());
      mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
    }
  } else {
    mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent);
    mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
  }
  if (mAddObject) {
    mpDiagramGraphicsView->addComponentObject(mpDiagramComponent);
  }
}

/*!
 * \brief AddComponentCommand::undo
 * Undo the AddComponentCommand.
 */
void AddComponentCommand::undo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mType == StringHandler::Connector && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first remove the component from Icon View
    mpIconGraphicsView->scene()->removeItem(mpIconComponent);
    mpIconGraphicsView->scene()->removeItem(mpIconComponent->getOriginItem());
    mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
    // now remove the component from Diagram View
    mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent);
    mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
  } else {
    mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent);
    mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
  }
  mpGraphicsView->deleteComponentObject(mpDiagramComponent);
}

DeleteComponentCommand::DeleteComponentCommand(Component *pComponent, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpComponent = pComponent;
  mpIconComponent = 0;
  mpDiagramComponent = 0;
  mpIconGraphicsView = pGraphicsView->getModelWidget()->getIconGraphicsView();
  mpDiagramGraphicsView = pGraphicsView->getModelWidget()->getDiagramGraphicsView();
  mpGraphicsView = pGraphicsView;
  setText(QString("Delete Component %1").arg(mpComponent->getName()));
}

/*!
 * \brief DeleteComponentCommand::redo
 * Redo the DeleteComponentCommand.
 */
void DeleteComponentCommand::redo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getType() == StringHandler::Connector && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first remove the component from Icon View
    mpIconComponent = mpIconGraphicsView->getComponentObject(mpComponent->getName());
    if (mpIconComponent) {
      mpIconGraphicsView->scene()->removeItem(mpIconComponent);
      mpIconGraphicsView->scene()->removeItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->deleteComponentFromList(mpIconComponent);
    }
    // now remove the component from Diagram View
    mpDiagramComponent = mpDiagramGraphicsView->getComponentObject(mpComponent->getName());
    if (mpDiagramComponent) {
      mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent);
      mpDiagramGraphicsView->scene()->removeItem(mpDiagramComponent->getOriginItem());
      mpDiagramGraphicsView->deleteComponentFromList(mpDiagramComponent);
    }
  } else {
    mpDiagramGraphicsView->scene()->removeItem(mpComponent);
    mpDiagramGraphicsView->scene()->removeItem(mpComponent->getOriginItem());
    mpDiagramGraphicsView->deleteComponentFromList(mpComponent);
  }
  mpGraphicsView->deleteComponentObject(mpComponent);
}

/*!
 * \brief DeleteComponentCommand::undo
 * Undo the DeleteComponentCommand.
 */
void DeleteComponentCommand::undo()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // if component is of connector type && containing class is Modelica type.
  if (mpComponent->getType() == StringHandler::Connector && pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    // first add the component to Icon View
    if (mpIconComponent) {
      mpIconGraphicsView->scene()->addItem(mpIconComponent);
      mpIconGraphicsView->scene()->addItem(mpIconComponent->getOriginItem());
      mpIconGraphicsView->addComponentToList(mpIconComponent);
    }
    // now add the component to Diagram View
    if (mpDiagramComponent) {
      mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent);
      mpDiagramGraphicsView->scene()->addItem(mpDiagramComponent->getOriginItem());
      mpDiagramGraphicsView->addComponentToList(mpDiagramComponent);
    }
  } else {
    mpDiagramGraphicsView->scene()->addItem(mpComponent);
    mpDiagramGraphicsView->scene()->addItem(mpComponent->getOriginItem());
    mpDiagramGraphicsView->addComponentToList(mpComponent);
  }
  mpGraphicsView->addComponentObject(mpComponent);
}


AddShapeCommand::AddShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mpGraphicsView = pGraphicsView;
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    setText("Add Line Shape");
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    setText("Add Polygon Shape");
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    setText("Add Rectangle Shape");
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    setText("Add Ellipse Shape");
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    setText("Add Text Shape");
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    setText("Add Bitmap Shape");
  }
}

/*!
 * \brief AddShapeCommand::redo
 * Redo the AddShapeCommand.
 */
void AddShapeCommand::redo()
{
  mpGraphicsView->addShapeObject(mpShapeAnnotation);
  mpGraphicsView->scene()->addItem(mpShapeAnnotation);
  mpGraphicsView->addClassAnnotation();
  mpShapeAnnotation->emitAdded();
  mpGraphicsView->setCanAddClassAnnotation(true);
}

/*!
 * \brief AddShapeCommand::undo
 * Undo the AddShapeCommand.
 */
void AddShapeCommand::undo()
{
  mpGraphicsView->deleteShapeObject(mpShapeAnnotation);
  mpGraphicsView->scene()->removeItem(mpShapeAnnotation);
  mpGraphicsView->addClassAnnotation();
  mpShapeAnnotation->emitDeleted();
  mpGraphicsView->setCanAddClassAnnotation(true);
}

DeleteShapeCommand::DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent)
  : QUndoCommand(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mpGraphicsView = pGraphicsView;
  if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
    setText("Delete Line Shape");
  } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
    setText("Delete Polygon Shape");
  } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
    setText("Delete Rectangle Shape");
  } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
    setText("Delete Ellipse Shape");
  } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
    setText("Delete Text Shape");
  } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
    setText("Delete Bitmap Shape");
  }
}

/*!
 * \brief DeleteShapeCommand::redo
 * Redo the DeleteShapeCommand.
 */
void DeleteShapeCommand::redo()
{
  mpGraphicsView->deleteShapeObject(mpShapeAnnotation);
  mpGraphicsView->scene()->removeItem(mpShapeAnnotation);
  mpGraphicsView->addClassAnnotation();
  mpShapeAnnotation->emitDeleted();
  mpGraphicsView->setCanAddClassAnnotation(true);
}

/*!
 * \brief DeleteShapeCommand::undo
 * Undo the DeleteShapeCommand.
 */
void DeleteShapeCommand::undo()
{
  mpGraphicsView->addShapeObject(mpShapeAnnotation);
  mpGraphicsView->scene()->addItem(mpShapeAnnotation);
  mpGraphicsView->addClassAnnotation();
  mpShapeAnnotation->emitAdded();
  mpGraphicsView->setCanAddClassAnnotation(true);
}
