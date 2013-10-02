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
  Component(QString annotation, QString name, QString className, StringHandler::ModelicaClasses type, QString transformation,
            QPointF position, bool inheritedComponent, QString inheritedClassName, OMCProxy *pOMCProxy, GraphicsView *pGraphicsView,
            Component *pParent = 0);
  Component(QString annotation, QString className, StringHandler::ModelicaClasses type, Component *pParent);
  Component(QString annotation, QString transformationString, ComponentInfo *pComponentInfo, StringHandler::ModelicaClasses type,
            Component *pParent);
  /* Used for Library Component */
  Component(QString annotation, QString className, OMCProxy *pOMCProxy, Component *pParent = 0);
  ~Component();
  void initialize();
  bool isLibraryComponent();
  bool isInheritedComponent();
  QString getInheritedClassName();
  void getClassInheritedComponents(bool isRootComponent = false, bool isPortComponent = false);
  void parseAnnotationString(QString annotation);
  void getClassComponents();
  bool canUseDefaultAnnotation(Component *pComponent);
  void createActions();
  void createResizerItems();
  void getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2);
  void showResizerItems();
  void hideResizerItems();
  QRectF boundingRect() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  QString getName();
  QString getClassName();
  StringHandler::ModelicaClasses getType();
  OMCProxy* getOMCProxy();
  GraphicsView* getGraphicsView();
  Component* getParentComponent();
  Component* getRootParentComponent();
  Transformation* getTransformation();
  QAction* getParametersAction();
  QAction* getAttributesAction();
  QAction* getViewClassAction();
  QAction* getViewDocumentationAction();
  ComponentInfo* getComponentInfo();
  QList<Component*> getInheritanceList();
  QList<ShapeAnnotation*> getShapesList();
  QList<Component*> getComponentsList();
  void setOldPosition(QPointF oldPosition);
  QPointF getOldPosition();
  void setComponentFlags();
  void unsetComponentFlags();
  void getExtents(QPointF *pExtent1, QPointF *pExtent2);
  QString getTransformationAnnotationString();
  QString getPlacementAnnotation();
  void applyRotation(qreal angle);
  void addConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void updateConnection();
  void componentNameHasChanged(QString newName);
  void componentParameterHasChanged();
  QString getParameterDisplayString(QString parameterName);
private:
  QString mName;
  QString mClassName;
  StringHandler::ModelicaClasses mType;
  OMCProxy *mpOMCProxy;
  GraphicsView *mpGraphicsView;
  Component *mpParentComponent;
  bool mIsLibraryComponent;
  bool mIsInheritedComponent;
  QString mInheritedClassName;
  ComponentType mComponentType;
  CoOrdinateSystem *mpCoOrdinateSystem;
  Transformation *mpTransformation;
  QGraphicsRectItem *mpResizerRectangle;
  QAction *mpParametersAction;
  QAction *mpAttributesAction;
  QAction *mpViewClassAction;
  QAction *mpViewDocumentationAction;
  ResizerItem *mpBottomLeftResizerItem;
  ResizerItem *mpTopLeftResizerItem;
  ResizerItem *mpTopRightResizerItem;
  ResizerItem *mpBottomRightResizerItem;
  ResizerItem *mpSelectedResizerItem;
  QTransform mTransform;
  QRectF mSceneBoundingRect;
  QPointF mTransformationStartPosition;
  QPointF mPivotPoint;
  qreal mXFactor;
  qreal mYFactor;
  ComponentInfo *mpComponentInfo;
  QList<Component*> mpInheritanceList;
  QList<ShapeAnnotation*> mpShapesList;
  QList<Component*> mpComponentsList;
  QPointF mOldPosition;
  void duplicateHelper(GraphicsView *pGraphicsView);
signals:
  void componentDisplayTextChanged();
  void componentClicked(Component*);
  void componentTransformChange();
  void componentTransformHasChanged();
  void componentRotationChange();
public slots:
  void updatePlacementAnnotation();
  void prepareResizeComponent(ResizerItem *pResizerItem);
  void resizeComponent(int index, QPointF newPosition);
  void finishResizeComponent();
  void deleteMe();
  void duplicate();
  void rotateClockwise();
  void rotateAntiClockwise();
  void flipHorizontal();
  void flipVertical();
  void moveUp();
  void moveShiftUp();
  void moveDown();
  void moveShiftDown();
  void moveLeft();
  void moveShiftLeft();
  void moveRight();
  void moveShiftRight();
  void showParameters();
  void showAttributes();
  void viewClass();
  void viewDocumentation();
protected:
  virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
  virtual void mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event);
  virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
  virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
  virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

class ComponentInfo
{
public:
  ComponentInfo(QString value);
  void parseComponentInfoString(QString value);
  QString getClassName();
  QString getName();
  QString getComment();
  bool getProtected();
  bool getFinal();
  bool getFlow();
  bool getStream();
  bool getReplaceable();
  QString getVariablity();
  bool getInner();
  bool getOuter();
  QString getCasuality();
  QString getArrayIndex();
  bool isArray();
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

#endif // COMPONENT_H
