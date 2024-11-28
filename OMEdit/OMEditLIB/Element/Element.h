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

#ifndef ELEMENT_H
#define ELEMENT_H

#include "Annotations/ShapeAnnotation.h"
#include "Element/CornerItem.h"
#include "Modeling/ModelWidgetContainer.h"
#include "OMC/OMCProxy.h"
#include "Annotations/LineAnnotation.h"
#include "Annotations/PolygonAnnotation.h"
#include "Annotations/RectangleAnnotation.h"
#include "Annotations/EllipseAnnotation.h"
#include "Annotations/TextAnnotation.h"
#include "Annotations/BitmapAnnotation.h"
#include "OMS/OMSProxy.h"

class OMCProxy;
class GraphicsScene;
class GraphicsView;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;
class LibraryTreeItem;
class Element;

class ElementInfo
{
public:
  ElementInfo() = default;
  ElementInfo(const ElementInfo &elementInfo);
  void parseElementInfoString(QString value);
  void fetchParameterValue(OMCProxy *pOMCProxy, const QString &className);
  void setClassName(const QString &className) {mClassName = className;}
  QString getClassName() const {return mClassName;}
  void setName(const QString &name) {mName = name;}
  QString getName() const {return mName;}
  void setComment(const QString &comment) {mComment = comment;}
  QString getComment() const {return StringHandler::removeFirstLastQuotes(mComment);}
  void setCausality(const QString &causality) {mCausality = causality;}
  QString getCausality() const {return mCausality;}
  bool isParameterValueLoaded() const {return mParameterValueLoaded;}
  void setParameterValue(const QString &parameterValue) {mParameterValue = parameterValue;}
  QString getParameterValueWithoutFetching() const {return mParameterValue;}
  QString getParameterValue(OMCProxy *pOMCProxy, const QString &className);
  // operator overloading
  bool operator==(const ElementInfo &componentInfo) const;
  bool operator!=(const ElementInfo &componentInfo) const;
  QString getHTMLDescription() const;
private:
  QString mClassName;
  QString mName;
  QString mComment;
  QString mCausality;
  bool mParameterValueLoaded = false;
  QString mParameterValue;
};

class Element : public QObject, public QGraphicsItem
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
public:
  enum ElementType {
    Root,  /* Root Element. */
    Extend,  /* Inherited Element. */
    Port  /* Port Element. */
  };

  Element(ModelInstance::Component *pModelComponent, bool inherited, GraphicsView *pGraphicsView, bool createTransformation, QPointF position, const QString &placementAnnotation);
  Element(ModelInstance::Model *pModel, Element *pParentElement);
  Element(ModelInstance::Component *pModelComponent, Element *pParentElement, Element *pRootParentElement);
  // Used for OMS Element
  Element(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, GraphicsView *pGraphicsView);
  // Used for OMS Connector Element
  Element(Element *pElement, Element *pParentElement, Element *pRootParentElement);
  bool isRoot() const {return mElementType == Element::Root;}
  bool isExtend() const {return mElementType == Element::Extend;}
  bool isPort() const {return mElementType == Element::Port;}
  bool isInheritedElement() {return mIsInheritedElement;}
  bool hasShapeAnnotation() const;
  bool hasNonExistingClass();
  QRectF boundingRect() const override;
  QPainterPath shape() const override;
  QRectF itemsBoundingRect();
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0) override;
  ModelInstance::Model *getModel() const {return mpModel;}
  void setModel(ModelInstance::Model *pModel) {mpModel = pModel;}
  ModelInstance::Component *getModelComponent() const {return mpModelComponent;}
  void setModelComponent(ModelInstance::Component *pModelComponent) {mpModelComponent = pModelComponent;}
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QString getName() const;
  QString getClassName() const;
  QString getComment() const;
  bool isCondition() const;
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  Element *getReferenceElement() {return mpReferenceElement;}
  Element* getParentElement() const {return mpParentElement;}
  Element* getRootParentElement();
  QString getTransformationString() {return mTransformationString;}
  ModelInstance::CoordinateSystem getCoordinateSystem() const;
  ResizerItem* getBottomLeftResizerItem() {return mpBottomLeftResizerItem;}
  ResizerItem* getTopLeftResizerItem() {return mpTopLeftResizerItem;}
  ResizerItem* getTopRightResizerItem() {return mpTopRightResizerItem;}
  ResizerItem* getBottomRightResizerItem() {return mpBottomRightResizerItem;}
  OriginItem* getOriginItem() {return mpOriginItem;}
  QAction* getShowElementAction() {return mpShowElementAction;}
  QAction* getParametersAction() {return mpParametersAction;}
  QAction* getAttributesAction() {return mpAttributesAction;}
  QAction* getOpenClassAction() {return mpOpenClassAction;}
  QAction* getElementPropertiesAction() {return mpElementPropertiesAction;}
  QAction* getReplaceSubModelAction() {return mpReplaceSubModelAction;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<Element*> getInheritedElementsList() {return mInheritedElementsList;}
  QList<Element*> getElementsList() {return mElementsList;}
  void setOldScenePosition(QPointF oldScenePosition) {mOldScenePosition = oldScenePosition;}
  QPointF getOldScenePosition() {return mOldScenePosition;}
  void setOldPosition(QPointF oldPosition) {mOldPosition = oldPosition;}
  QPointF getOldPosition() {return mOldPosition;}
  void setElementFlags(bool enable);
  QString getTransformationAnnotation(bool ModelicaSyntax);
  QString getPlacementAnnotation(bool ModelicaSyntax = false);
  QString getOMCTransformationAnnotation(QPointF position);
  QString getOMCPlacementAnnotation(QPointF position);
  QString getTransformationOrigin();
  QString getTransformationExtent();
  bool isExpandableConnector() const;
  bool isArray() const;
  QStringList getAbsynArrayIndexes() const;
  QStringList getTypedArrayIndexes() const;
  int getArrayIndexAsNumber(bool *ok = 0) const;
  bool isConnectorSizing();
  bool isParameterConnectorSizing(const QString &parameter);
  static bool isParameterConnectorSizing(ModelInstance::Model *pModel, QString parameter);
  void createClassElements();
  void applyRotation(qreal angle);
  void addConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void removeConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void setHasTransition(bool hasTransition);
  bool hasTransition() {return mHasTransition;}
  void setIsInitialState(bool isInitialState);
  bool isInitialState() {return mIsInitialState;}
  void setActiveState(bool activeState) {mActiveState = activeState;}
  bool isActiveState() {return mActiveState;}
  void setIgnoreSelection(bool ignoreSelection) {mIgnoreSelection = ignoreSelection;}
  bool ignoreSelection() const {return mIgnoreSelection;}
  void removeChildren();
  void removeChildrenNew();
  void reDrawElement();
  void emitTransformChange(bool positionChanged) {emit transformChange(positionChanged);}
  void emitTransformHasChanged();
  void emitChanged();
  void emitDeleted();
  void componentParameterHasChanged();
  QPair<QString, bool> getParameterDisplayString(QString parameterName);
  QPair<QString, bool> getParameterModifierValue(const QString &parameterName, const QString &modifier);
  void shapeAdded();
  void shapeUpdated();
  void shapeDeleted();
  void renameComponentInConnections(QString newName);
  void updateElementTransformations(const Transformation &oldTransformation, const bool positionChanged);
  void handleOMSElementDoubleClick();
  bool isInBus() {return mpBusComponent != 0;}
  void setBusComponent(Element *pBusComponent);
  Element* getBusComponent() {return mpBusComponent;}
  static ModelInstance::Component *getModelComponentByName(ModelInstance::Model *pModel, const QString &name);
  void reDrawConnector(QPainter *painter);

  Transformation mTransformation;
  Transformation mOldTransformation;
private:
  ModelInstance::Component *mpModelComponent = nullptr;
  ModelInstance::Model *mpModel = nullptr;
  QString mName;
  QString mClassName;
  Element *mpReferenceElement = nullptr;
  Element *mpParentElement = nullptr;
  LibraryTreeItem *mpLibraryTreeItem = nullptr;
  GraphicsView *mpGraphicsView = nullptr;
  bool mIsInheritedElement = false;
  ElementType mElementType;
  QString mTransformationString;
  QString mParameterValue;
  LineAnnotation *mpNonExistingElementLine = nullptr;
  RectangleAnnotation *mpDefaultElementRectangle = nullptr;
  TextAnnotation *mpDefaultElementText = nullptr;
  RectangleAnnotation *mpStateElementRectangle = nullptr;
  QAction *mpShowElementAction = nullptr;
  QAction *mpParametersAction = nullptr;
  QAction *mpAttributesAction = nullptr;
  QAction *mpOpenClassAction = nullptr;
  QAction *mpElementPropertiesAction = nullptr;
  QAction *mpReplaceSubModelAction = nullptr;
  ResizerItem *mpBottomLeftResizerItem = nullptr;
  ResizerItem *mpTopLeftResizerItem = nullptr;
  ResizerItem *mpTopRightResizerItem = nullptr;
  ResizerItem *mpBottomRightResizerItem = nullptr;
  ResizerItem *mpSelectedResizerItem = nullptr;
  OriginItem *mpOriginItem = nullptr;
  QRectF mSceneBoundingRect;
  QPointF mTransformationStartPosition;
  QPointF mPivotPoint;
  QList<Element*> mInheritedElementsList;
  QList<ShapeAnnotation*> mShapesList;
  QList<Element*> mElementsList;
  QPointF mOldScenePosition;
  QPointF mOldPosition;
  bool mHasTransition = false;
  bool mIsInitialState = false;
  bool mActiveState = false;
  Element *mpBusComponent = nullptr;
  bool mIgnoreSelection = false;
  void createNonExistingElement();
  void deleteNonExistingElement();
  void createDefaultElement();
  void deleteDefaultElement();
  void createStateElement();
  void drawElement();
  void drawModelicaElement();
  void drawOMSElement();
  void drawInheritedElementsAndShapes();
  void showNonExistingOrDefaultElementIfNeeded();
  void createClassInheritedElements();
  void createClassShapes();
  void createActions();
  void createResizerItems();
  void getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2);
  void showResizerItems();
  void hideResizerItems();
  void getScale(qreal *sx, qreal *sy);
  void updateConnections();
  QPair<QString, bool> getParameterDisplayStringFromExtendsModifiers(QString parameterName);
  QPair<QString, bool> getParameterDisplayStringFromExtendsParameters(QString parameterName, QPair<QString, bool> modifierString);
  static QPair<QString, bool> getParameterDisplayStringFromExtendsParameters(ModelInstance::Model *pModel, QString parameterName, QPair<QString, bool> modifierString);
  static bool checkEnumerationDisplayString(QString &displayString, const QString &typeName);
  void updateToolTip();
  bool canUseDiagramAnnotation() const;
signals:
  void added();
  void transformChange(bool positionChanged);
  void transformHasChanged();
  void transformChanging();
  void displayTextChanged();
  void changed();
  void deleted();
public slots:
  void updatePlacementAnnotation();
  void updateOriginItem();
  void prepareResizeElement(ResizerItem *pResizerItem);
  void resizeElement(QPointF newPosition);
  void finishResizeElement();
  void resizedElement();
  void componentCommentHasChanged();
  void componentNameHasChanged();
  void displayTextChangedRecursive();
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
  void showElement();
  void showParameters();
  void showAttributes();
  void openClass();
  void showElementPropertiesDialog();
  void showReplaceSubModelDialog();
  void updateDynamicSelect(double time);
  void resetDynamicSelect();
  // QGraphicsItem interface
protected:
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value) override;
};

#endif // ELEMENT_H
