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
#include "CoOrdinateSystem.h"
#include "ModelWidgetContainer.h"
#include "OMCProxy.h"
#include "LineAnnotation.h"
#include "PolygonAnnotation.h"
#include "RectangleAnnotation.h"
#include "EllipseAnnotation.h"
#include "TextAnnotation.h"
#include "BitmapAnnotation.h"

class OMCProxy;
class GraphicsScene;
class GraphicsView;
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
  ComponentInfo(QObject *pParent = 0);
  ComponentInfo(ComponentInfo *pComponentInfo, QObject *pParent = 0);
  void updateComponentInfo(const ComponentInfo *pComponentInfo);
  void parseComponentInfoString(QString value);
  void setClassName(QString className) {mClassName = className;}
  QString getClassName() const {return mClassName;}
  void setName(QString name) {mName = name;}
  QString getName() const {return mName;}
  void setComment(QString comment) {mComment = comment;}
  QString getComment() const {return StringHandler::removeFirstLastQuotes(mComment);}
  void setProtected(bool protect) {mIsProtected = protect;}
  bool getProtected() const {return mIsProtected;}
  void setFinal(bool final) {mIsFinal = final;}
  bool getFinal() const {return mIsFinal;}
  void setFlow(bool flow) {mIsFlow = flow;}
  bool getFlow() const {return mIsFlow;}
  void setStream(bool stream) {mIsStream = stream;}
  bool getStream() const {return mIsStream;}
  void setReplaceable(bool replaceable) {mIsReplaceable = replaceable;}
  bool getReplaceable() const {return mIsReplaceable;}
  void setVariablity(QString variability) {mVariability = variability;}
  QString getVariablity() const {return mVariability;}
  void setInner(bool inner) {mIsInner = inner;}
  bool getInner() const {return mIsInner;}
  void setOuter(bool outer) {mIsOuter = outer;}
  bool getOuter() const {return mIsOuter;}
  void setCausality(QString causality) {mCasuality = causality;}
  QString getCausality() const {return mCasuality;}
  void setArrayIndex(QString arrayIndex);
  QString getArrayIndex() const {return mArrayIndex;}
  bool isArray() const {return mIsArray;}
  bool operator==(const ComponentInfo &componentInfo) const;
  bool operator!=(const ComponentInfo &componentInfo) const;
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
  Component(QString name, LibraryTreeItem *pLibraryTreeItem, QString transformation, QPointF position, QStringList dialogAnnotation,
            ComponentInfo *pComponentInfo, GraphicsView *pGraphicsView);
  Component(LibraryTreeItem *pLibraryTreeItem, Component *pParentComponent);
  Component(Component *pComponent, Component *pParentComponent);
  Component(Component *pComponent, GraphicsView *pGraphicsView);
  bool isInheritedComponent() {return mIsInheritedComponent;}
  bool hasShapeAnnotation(Component *pComponent);
  bool hasNonExistingClass();
  QRectF boundingRect() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QString getName() {return mpComponentInfo->getName();}
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  Component *getReferenceComponent() {return mpReferenceComponent;}
  Component* getParentComponent() {return mpParentComponent;}
  Component* getRootParentComponent();
  ComponentType getComponentType() {return mComponentType;}
  QString getTransformationString() {return mTransformationString;}
  void setDialogAnnotation(QStringList dialogAnnotation) {mDialogAnnotation = dialogAnnotation;}
  QStringList getDialogAnnotation() {return mDialogAnnotation;}
  CoOrdinateSystem getCoOrdinateSystem() const;
  OriginItem* getOriginItem() {return mpOriginItem;}
  QAction* getParametersAction() {return mpParametersAction;}
  QAction* getAttributesAction() {return mpAttributesAction;}
  QAction* getViewClassAction() {return mpViewClassAction;}
  QAction* getViewDocumentationAction() {return mpViewDocumentationAction;}
  QAction* getTLMAttributesAction() {return mpTLMAttributesAction;}
  ComponentInfo* getComponentInfo() {return mpComponentInfo;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<Component*> getInheritedComponentsList() {return mInheritedComponentsList;}
  QList<Component*> getComponentsList() {return mComponentsList;}
  QList<TLMInterfacePointInfo*> getInterfacepointsList() {return mInterfacePointsList;}
  void setOldScenePosition(QPointF oldScenePosition) {mOldScenePosition = oldScenePosition;}
  QPointF getOldScenePosition() {return mOldScenePosition;}
  void setOldPosition(QPointF oldPosition) {mOldPosition = oldPosition;}
  QPointF getOldPosition() {return mOldPosition;}
  void setComponentFlags(bool enable);
  QString getTransformationAnnotation();
  QString getPlacementAnnotation();
  QString getOMCTransformationAnnotation(QPointF position);
  QString getOMCPlacementAnnotation(QPointF position);
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
  Transformation mOldTransformation;
private:
  Component *mpReferenceComponent;
  Component *mpParentComponent;
  LibraryTreeItem *mpLibraryTreeItem;
  ComponentInfo *mpComponentInfo;
  GraphicsView *mpGraphicsView;
  bool mIsInheritedComponent;
  ComponentType mComponentType;
  QString mTransformationString;
  QStringList mDialogAnnotation;
  QGraphicsRectItem *mpResizerRectangle;
  LineAnnotation *mpNonExistingComponentLine;
  RectangleAnnotation *mpDefaultComponentRectangle;
  TextAnnotation *mpDefaultComponentText;
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
  QList<Component*> mInheritedComponentsList;
  QList<ShapeAnnotation*> mShapesList;
  QList<Component*> mComponentsList;
  QPointF mOldScenePosition;
  QList<TLMInterfacePointInfo*> mInterfacePointsList;
  QPointF mOldPosition;
  void createNonExistingComponent();
  void createDefaultComponent();
  void showHideNonExistingOrDefaultComponent();
  void createClassInheritedComponents();
  void createClassShapes();
  void createClassComponents();
  void removeClassShapes();
  void removeInheritedComponents();
  void removeComponents();
  void createActions();
  void createResizerItems();
  void getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2);
  void showResizerItems();
  void hideResizerItems();
  void getScale(qreal *sx, qreal *sy);
  void setOriginAndExtents();
  void reloadComponent(bool loaded);
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
  void resizedComponent();
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
