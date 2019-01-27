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

#ifndef COMPONENT_H
#define COMPONENT_H

#include "Annotations/ShapeAnnotation.h"
#include "Component/CornerItem.h"
#include "Modeling/CoOrdinateSystem.h"
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

class ComponentInfo : public QObject
{
  Q_OBJECT
public:
  ComponentInfo(QObject *pParent = 0);
  ComponentInfo(ComponentInfo *pComponentInfo, QObject *pParent = 0);
  void updateComponentInfo(const ComponentInfo *pComponentInfo);
  void parseComponentInfoString(QString value);
  void fetchModifiers(OMCProxy *pOMCProxy, QString className, Component *pComponent);
  void fetchParameterValue(OMCProxy *pOMCProxy, QString className);
  void applyDefaultPrefixes(QString defaultPrefixes);
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
  bool isModifiersLoaded() const {return mModifiersLoaded;}
  void setModifiersMap(QMap<QString, QString> modifiersMap) {mModifiersMap = modifiersMap;}
  QMap<QString, QString> getModifiersMapWithoutFetching() const {return mModifiersMap;}
  QMap<QString, QString> getModifiersMap(OMCProxy *pOMCProxy, QString className, Component *pComponent);
  bool isParameterValueLoaded() const {return mParameterValueLoaded;}
  void setParameterValue(QString parameterValue) {mParameterValue = parameterValue;}
  QString getParameterValueWithoutFetching() const {return mParameterValue;}
  QString getParameterValue(OMCProxy *pOMCProxy, QString className);
  // CompositeModel attributes
  void setStartCommand(QString startCommand) {mStartCommand = startCommand;}
  QString getStartCommand() const {return mStartCommand;}
  void setExactStep(bool exactStep) {mExactStep = exactStep;}
  bool getExactStep() const {return mExactStep;}
  void setModelFile(QString modelFile) {mModelFile = modelFile;}
  QString getModelFile() const {return mModelFile;}
  void setGeometryFile(QString geometryFile) {mGeometryFile = geometryFile;}
  QString getGeometryFile() const {return mGeometryFile;}
  void setPosition(QString position) {mPosition = position;}
  QString getPosition() const {return mPosition;}
  void setAngle321(QString angle321) {mAngle321 = angle321;}
  QString getAngle321() const {return mAngle321;}
  void setDimensions(int dimensions) {mDimensions = dimensions;}
  int getDimensions() const {return mDimensions;}
  void setTLMCausality(QString causality) {mTLMCausality = causality;}
  QString getTLMCausality() const {return mTLMCausality;}
  void setDomain(QString domain) {mDomain = domain;}
  QString getDomain() const {return mDomain;}
  // operator overloading
  bool operator==(const ComponentInfo &componentInfo) const;
  bool operator!=(const ComponentInfo &componentInfo) const;
  QString getHTMLDescription() const;
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
  bool mModifiersLoaded;
  QMap<QString, QString> mModifiersMap;
  bool mParameterValueLoaded;
  QString mParameterValue;
  // CompositeModel attributes
  QString mStartCommand;
  bool mExactStep;
  QString mModelFile;
  QString mGeometryFile;
  QString mPosition;
  QString mAngle321;
  int mDimensions;
  QString mTLMCausality;
  QString mDomain;

  bool isModiferClassRecord(QString modifierName, Component *pComponent);
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
  Component(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ComponentInfo *pComponentInfo,
            GraphicsView *pGraphicsView);
  Component(LibraryTreeItem *pLibraryTreeItem, Component *pParentComponent);
  Component(Component *pComponent, Component *pParentComponent, Component *pRootParentComponent);
  Component(Component *pComponent, GraphicsView *pGraphicsView);
  // used for interface point
  Component(ComponentInfo *pComponentInfo, Component *pParentComponent);
  bool isInheritedComponent() {return mIsInheritedComponent;}
  bool hasShapeAnnotation(Component *pComponent);
  bool hasNonExistingClass();
  QRectF boundingRect() const;
  QRectF itemsBoundingRect();
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
  void setChoicesAnnotation(QStringList choicesAnnotation) {mChoicesAnnotation = choicesAnnotation;}
  QStringList getChoicesAnnotation() {return mChoicesAnnotation;}
  CoOrdinateSystem getCoOrdinateSystem() const;
  OriginItem* getOriginItem() {return mpOriginItem;}
  QAction* getParametersAction() {return mpParametersAction;}
  QAction* getFetchInterfaceDataAction() {return mpFetchInterfaceDataAction;}
  QAction* getAttributesAction() {return mpAttributesAction;}
  QAction* getOpenClassAction() {return mpOpenClassAction;}
  QAction* getViewDocumentationAction() {return mpViewDocumentationAction;}
  QAction* getSubModelAttributesAction() {return mpSubModelAttributesAction;}
  QAction* getElementPropertiesAction() {return mpElementPropertiesAction;}
  ComponentInfo* getComponentInfo() {return mpComponentInfo;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<Component*> getInheritedComponentsList() {return mInheritedComponentsList;}
  QList<Component*> getComponentsList() {return mComponentsList;}
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
  void createClassComponents();
  void applyRotation(qreal angle);
  void addConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void removeConnectionDetails(LineAnnotation *pConnectorLineAnnotation);
  void setHasTransition(bool hasTransition);
  bool hasTransition() {return mHasTransition;}
  void setIsInitialState(bool isInitialState);
  bool isInitialState() {return mIsInitialState;}
  void setActiveState(bool activeState) {mActiveState = activeState;}
  bool isActiveState() {return mActiveState;}
  void removeChildren();
  void emitAdded();
  void emitTransformChange() {emit transformChange();}
  void emitTransformHasChanged();
  void emitChanged();
  void emitDeleted();
  void componentParameterHasChanged();
  QString getParameterDisplayString(QString parameterName);
  void shapeAdded();
  void shapeUpdated();
  void shapeDeleted();
  void renameComponentInConnections(QString newName);
  void insertInterfacePoint(QString interfaceName, QString position, QString angle321, int dimensions, QString causality, QString domain);
  void removeInterfacePoint(QString interfaceName);
  void adjustInterfacePoints();
  void updateComponentTransformations(const Transformation &oldTransformation);
  void handleOMSComponentDoubleClick();
  bool isInBus() {return mpBusComponent != 0;}
  void setBusComponent(Component *pBusComponent);
  Component* getBusComponent() {return mpBusComponent;}

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
  QStringList mChoicesAnnotation;
  QString mParameterValue;
  QGraphicsRectItem *mpResizerRectangle;
  LineAnnotation *mpNonExistingComponentLine;
  RectangleAnnotation *mpDefaultComponentRectangle;
  TextAnnotation *mpDefaultComponentText;
  RectangleAnnotation *mpStateComponentRectangle;
  QAction *mpParametersAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpAttributesAction;
  QAction *mpOpenClassAction;
  QAction *mpViewDocumentationAction;
  QAction *mpSubModelAttributesAction;
  QAction *mpElementPropertiesAction;
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
  QPointF mOldPosition;
  bool mHasTransition;
  bool mIsInitialState;
  bool mActiveState;
  Component *mpBusComponent;
  void createNonExistingComponent();
  void createDefaultComponent();
  void createStateComponent();
  void drawInterfacePoints();
  void drawComponent();
  void drawModelicaComponent();
  void drawOMSComponent();
  void drawInheritedComponentsAndShapes();
  void showNonExistingOrDefaultComponentIfNeeded();
  void createClassInheritedComponents();
  void createClassShapes();
  void createActions();
  void createResizerItems();
  void getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2);
  void showResizerItems();
  void hideResizerItems();
  void getScale(qreal *sx, qreal *sy);
  void setOriginAndExtents();
  void updateConnections();
  QString getParameterDisplayStringFromExtendsModifiers(QString parameterName);
  QString getParameterDisplayStringFromExtendsParameters(QString parameterName, QString modifierString);
  bool checkEnumerationDisplayString(QString &displayString, const QString &typeName);
  void updateToolTip();
  bool canUseDiagramAnnotation();
signals:
  void added();
  void transformChange();
  void transformHasChanged();
  void transformChanging();
  void displayTextChanged();
  void changed();
  void deleted();
public slots:
  void updatePlacementAnnotation();
  void updateOriginItem();
  void handleLoaded();
  void handleUnloaded();
  void handleShapeAdded();
  void handleComponentAdded();
  void handleNameChanged();
  void referenceComponentAdded();
  void referenceComponentTransformHasChanged();
  void referenceComponentChanged();
  void referenceComponentDeleted();
  void prepareResizeComponent(ResizerItem *pResizerItem);
  void resizeComponent(QPointF newPosition);
  void finishResizeComponent();
  void resizedComponent();
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
  void showParameters();
  void showAttributes();
  void fetchInterfaceData();
  void openClass();
  void viewDocumentation();
  void showSubModelAttributes();
  void showElementPropertiesDialog();
  void updateDynamicSelect(double time);
protected:
  virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

#endif // COMPONENT_H
