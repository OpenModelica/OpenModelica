/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef COMPONENT_H
#define COMPONENT_H

#include "ShapeAnnotation.h"
#include "CornerItem.h"
#include "ModelWidgetContainer.h"
#include "OMCProxy.h"
#include "LineAnnotation.h"
#include "PolygonAnnotation.h"
#include "RectangleAnnotation.h"
#include "EllipseAnnotation.h"
#include "TextAnnotation.h"
#include "BitmapAnnotation.h"

class OMCProxy;
class CoOrdinateSystem;
class GraphicsScene;
class GraphicsView;
class ComponentInfo;
class Connector;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;
class TLMInterfacePointInfo;

class ComponentInfo : public QObject
{
  Q_OBJECT
public:
  ComponentInfo(QString value, QObject *pParent = 0);
  void parseComponentInfoString(QString value);
  void setClassName(QString className) {mClassName = className;}
  QString getClassName() {return mClassName;}
  void setName(QString name) {mName = name;}
  QString getName() {return mName;}
  void setComment(QString comment) {mComment = comment;}
  QString getComment() {return StringHandler::removeFirstLastQuotes(mComment);}
  void setProtected(bool protect) {mIsProtected = protect;}
  bool getProtected() {return mIsProtected;}
  void setFinal(bool final) {mIsFinal = final;}
  bool getFinal() {return mIsFinal;}
  bool getFlow() {return mIsFlow;}
  bool getStream() {return mIsStream;}
  void setReplaceable(bool replaceable) {mIsReplaceable = replaceable;}
  bool getReplaceable() {return mIsReplaceable;}
  void setVariablity(QString variability) {mVariability = variability;}
  QString getVariablity() {return mVariability;}
  void setInner(bool inner) {mIsInner = inner;}
  bool getInner() {return mIsInner;}
  void setOuter(bool outer) {mIsOuter = outer;}
  bool getOuter() {return mIsOuter;}
  void setCausality(QString causality) {mCasuality = causality;}
  QString getCausality() {return mCasuality;}
  void setArrayIndex(QString arrayIndex);
  QString getArrayIndex() {return mArrayIndex;}
  bool isArray() {return mIsArray;}
private:
  QString mClassName;
  QString mName;
  QString mComment;
  bool mIsProtected;
  bool mIsFinal;
  bool mIsFlow;
  bool mIsStream;
  bool mIsReplaceable;
  QMap<QString, QString> mVariabilityMap;
  QString mVariability;
  bool mIsInner;
  bool mIsOuter;
  QMap<QString, QString> mCasualityMap;
  QString mCasuality;
  QString mArrayIndex;
  bool mIsArray;
};

class Component : public QObject, public QGraphicsItem
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
public:
  enum ComponentType {
    Root,  /* Root Component. */
    Extend,  /* Inherited Component. */
    Port  /* Port Component. */
  };
  Component(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformation, QPointF position, ComponentInfo *pComponentInfo,
            GraphicsView *pGraphicsView);
  Component(Component *pComponent, GraphicsView *pGraphicsView, Component *pParent);
  Component(Component *pComponent, GraphicsView *pGraphicsView);
  bool isInheritedComponent() {return mIsInheritedComponent;}
  QString getInheritedClassName();
  void createNonExistingComponent();
  void createDefaultComponent();
  void createClassInheritedShapes();
  void createClassShapes(LibraryTreeItem *pLibraryTreeItem);
  void createClassInheritedComponents();
  void createClassComponents(LibraryTreeItem *pLibraryTreeItem);
  bool hasShapeAnnotation(Component *pComponent);
  void createActions();
  void createResizerItems();
  void getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2);
  void showResizerItems();
  void hideResizerItems();
  void getScale(qreal *sx, qreal *sy);
  void setOriginAndExtents();
  QRectF boundingRect() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QString getName() {return mpComponentInfo->getName();}
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  Component* getParentComponent() {return mpParentComponent;}
  Component* getRootParentComponent();
  ComponentType getComponentType() {return mComponentType;}
  QString getTransformationString() {return mTransformationString;}
  OriginItem* getOriginItem() {return mpOriginItem;}
  QAction* getParametersAction() {return mpParametersAction;}
  QAction* getAttributesAction() {return mpAttributesAction;}
  QAction* getViewClassAction() {return mpViewClassAction;}
  QAction* getViewDocumentationAction() {return mpViewDocumentationAction;}
  QAction* getTLMAttributesAction() {return mpTLMAttributesAction;}
  ComponentInfo* getComponentInfo() {return mpComponentInfo;}
  QList<Component*> getInheritanceList() {return mInheritanceList;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<Component*> getComponentsList() {return mComponentsList;}
  QList<TLMInterfacePointInfo*> getInterfacepointsList() {return mInterfacePointsList;}
  void setOldScenePosition(QPointF oldScenePosition) {mOldScenePosition = oldScenePosition;}
  QPointF getOldScenePosition() {return mOldScenePosition;}
  void setOldPosition(QPointF oldPosition) {mOldPosition = oldPosition;}
  QPointF getOldPosition() {return mOldPosition;}
  void setComponentFlags(bool enable);
  QString getTransformationAnnotation();
  QString getPlacementAnnotation();
  QString getTransformationOrigin();
  QString getTransformationExtent();
  void applyRotation(qreal angle);
  void addConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void removeConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void emitAdded();
  void emitTransformChange() {emit transformChange();}
  void emitTransformHasChanged();
  void emitDeleted();
  void componentNameHasChanged();
  void componentParameterHasChanged();
  QString getParameterDisplayString(QString parameterName);
  void shapeAdded();
  void shapeDeleted();
  void addInterfacePoint(TLMInterfacePointInfo *pTLMInterfacePointInfo);
  void removeInterfacePoint(TLMInterfacePointInfo *pTLMInterfacePointInfo);
  void renameInterfacePoint(TLMInterfacePointInfo *pTLMInterfacePointInfo, QString interfacePoint);

  Transformation mTransformation;
private:
  Component *mpReferenceComponent;
  Component *mpParentComponent;
  LibraryTreeItem *mpLibraryTreeItem;
  ComponentInfo *mpComponentInfo;
  GraphicsView *mpGraphicsView;
  bool mIsInheritedComponent;
  ComponentType mComponentType;
  QString mTransformationString;
  QGraphicsRectItem *mpResizerRectangle;
  LineAnnotation *mpNonExistingComponentLine;
  RectangleAnnotation *mpDefaultComponentRectangle;
  TextAnnotation *mpDefaultComponentText;
  CoOrdinateSystem *mpCoOrdinateSystem;
  QAction *mpParametersAction;
  QAction *mpAttributesAction;
  QAction *mpViewClassAction;
  QAction *mpViewDocumentationAction;
  QAction *mpTLMAttributesAction;
  ResizerItem *mpBottomLeftResizerItem;
  ResizerItem *mpTopLeftResizerItem;
  ResizerItem *mpTopRightResizerItem;
  ResizerItem *mpBottomRightResizerItem;
  ResizerItem *mpSelectedResizerItem;
  OriginItem *mpOriginItem;
  QTransform mTransform;
  QRectF mSceneBoundingRect;
  QPointF mTransformationStartPosition;
  QPointF mPivotPoint;
  qreal mXFactor;
  qreal mYFactor;
  QList<Component*> mInheritanceList;
  QList<ShapeAnnotation*> mShapesList;
  QList<Component*> mComponentsList;
  QPointF mOldScenePosition;
  QList<TLMInterfacePointInfo*> mInterfacePointsList;
  QPointF mOldPosition;
  void duplicateHelper(GraphicsView *pGraphicsView);
  void removeShapes();
  void removeComponents();
signals:
  void added();
  void transformChange();
  void transformHasChanged();
  void displayTextChanged();
  void deleted();
public slots:
  void updatePlacementAnnotation();
  void updateOriginItem();
  void handleLoaded();
  void handleUnloaded();
  void handleShapeAdded();
  void referenceComponentAdded();
  void referenceComponentChanged();
  void referenceComponentDeleted();
  void prepareResizeComponent(ResizerItem *pResizerItem);
  void resizeComponent(QPointF newPosition);
  void finishResizeComponent();
  void deleteMe();
  void duplicate();
  void rotateClockwise();
  void rotateAntiClockwise();
  void flipHorizontal();
  void flipVertical();
  void moveUp();
  void moveShiftUp();
  void moveCtrlUp();
  void moveDown();
  void moveShiftDown();
  void moveCtrlDown();
  void moveLeft();
  void moveShiftLeft();
  void moveCtrlLeft();
  void moveRight();
  void moveShiftRight();
  void moveCtrlRight();
  void showParameters();
  void showAttributes();
  void viewClass();
  void viewDocumentation();
  void showTLMAttributes();
protected:
  virtual void mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event);
  virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

#endif // COMPONENT_H
