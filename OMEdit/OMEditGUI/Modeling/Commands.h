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

#ifndef COMMANDS_H
#define COMMANDS_H

#include "ModelWidgetContainer.h"

class AddShapeCommand : public QUndoCommand
{
public:
  AddShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  GraphicsView *mpGraphicsView;
};

class MoveShapeMouseCommand : public QUndoCommand
{
public:
  MoveShapeMouseCommand(ShapeAnnotation *pShapeAnnotation, QPointF oldScenePos, QPointF newScenePos, GraphicsView *pGraphicsView,
                        QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  QPointF mOldScenePosition;
  QPointF mNewScenePosition;
  GraphicsView *mpGraphicsView;
};

class MoveShapeKeyCommand : public QUndoCommand
{
public:
  MoveShapeKeyCommand(ShapeAnnotation *pShapeAnnotation, qreal x, qreal y, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  qreal mX;
  qreal mY;
  GraphicsView *mpGraphicsView;
};

class RotateShapeCommand : public QUndoCommand
{
public:
  RotateShapeCommand(ShapeAnnotation *pShapeAnnotation, bool clockwise, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  bool mClockwise;
};

class DeleteShapeCommand : public QUndoCommand
{
public:
  DeleteShapeCommand(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  GraphicsView *mpGraphicsView;
};

class AddComponentCommand : public QUndoCommand
{
public:
  AddComponentCommand(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformationString, QPointF position,
                      ComponentInfo *pComponentInfo, bool addObject, bool openingClass, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  LibraryTreeItem *mpLibraryTreeItem;
  StringHandler::ModelicaClasses mType;
  bool mAddObject;
  ComponentInfo *mpComponentInfo;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsView *mpGraphicsView;
};

class MoveComponentMouseCommand : public QUndoCommand
{
public:
  MoveComponentMouseCommand(Component *pComponent, QPointF oldScenePos, QPointF newScenePos, GraphicsView *pGraphicsView,
                            QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  QPointF mOldScenePosition;
  QPointF mNewScenePosition;
  GraphicsView *mpGraphicsView;
};

class MoveComponentKeyCommand : public QUndoCommand
{
public:
  MoveComponentKeyCommand(Component *pComponent, qreal x, qreal y, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  qreal mX;
  qreal mY;
  GraphicsView *mpGraphicsView;
};

class RotateComponentCommand : public QUndoCommand
{
public:
  RotateComponentCommand(Component *pComponent, bool clockwise, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  bool mClockwise;
};

class DeleteComponentCommand : public QUndoCommand
{
public:
  DeleteComponentCommand(Component *pComponent, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  Component *mpIconComponent;
  Component *mpDiagramComponent;
  GraphicsView *mpIconGraphicsView;
  GraphicsView *mpDiagramGraphicsView;
  GraphicsView *mpGraphicsView;
};

class AddConnectionCommand : public QUndoCommand
{
public:
  AddConnectionCommand(LineAnnotation *pConnectionLineAnnotation, bool addConnection, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  bool mAddConnection;
  GraphicsView *mpGraphicsView;
};

class DeleteConnectionCommand : public QUndoCommand
{
public:
  DeleteConnectionCommand(LineAnnotation *pConnectionLineAnnotation, GraphicsView *pGraphicsView, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  LineAnnotation *mpConnectionLineAnnotation;
  GraphicsView *mpGraphicsView;
};

#endif // COMMANDS_H
