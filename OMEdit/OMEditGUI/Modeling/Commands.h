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

class UpdateShapeCommand : public QUndoCommand
{
public:
  UpdateShapeCommand(ShapeAnnotation *pShapeAnnotation, QString oldAnnotaton, QString newAnnotation, GraphicsView *pGraphicsView,
                      QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  ShapeAnnotation *mpShapeAnnotation;
  QString mOldAnnotation;
  QString mNewAnnotation;
  GraphicsView *mpGraphicsView;
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
                      ComponentInfo *pComponentInfo, bool addObject, bool openingClass, GraphicsView *pGraphicsView,
                      QUndoCommand *pParent = 0);
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

class UpdateComponentTransformationsCommand : public QUndoCommand
{
public:
  UpdateComponentTransformationsCommand(Component *pComponent, const Transformation &oldTransformation,
                                        const Transformation &newTransformation, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  Transformation mOldTransformation;
  Transformation mNewTransformation;
};

class UpdateComponentAttributesCommand : public QUndoCommand
{
public:
  UpdateComponentAttributesCommand(Component *pComponent, const ComponentInfo &oldComponentInfo, const ComponentInfo &newComponentInfo,
                                   bool duplicate, QUndoCommand *pParent = 0);
  void redo();
  void undo();
private:
  Component *mpComponent;
  ComponentInfo mOldComponentInfo;
  ComponentInfo mNewComponentInfo;
  bool mDuplicate;
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
