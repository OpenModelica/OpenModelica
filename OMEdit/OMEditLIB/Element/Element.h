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
class Element;

class ElementInfo : public QObject
{
  Q_OBJECT
public:
  ElementInfo(QObject *pParent = 0);
  ElementInfo(ElementInfo *pElementInfo, QObject *pParent = 0);
  void updateElementInfo(const ElementInfo *pElementInfo);
  void parseComponentInfoString(QString value);
  void parseElementInfoString(QString value);
  void fetchParameterValue(OMCProxy *pOMCProxy, const QString &className);
  void applyDefaultPrefixes(QString defaultPrefixes);
  void setClassName(const QString &className) {mClassName = className;}
  QString getClassName() const {return mClassName;}
  void setName(const QString &name) {mName = name;}
  QString getName() const {return mName;}
  void setComment(const QString &comment) {mComment = comment;}
  QString getComment() const {return StringHandler::removeFirstLastQuotes(mComment);}
  void setProtected(bool protect) {mIsProtected = protect;}
  bool getProtected() const {return mIsProtected;}
  void setFinal(bool final) {mIsFinal = final;}
  bool getFinal() const {return mIsFinal;}
  void setEach(bool each) {mIsEach = each;}
  bool getEach() const {return mIsEach;}
  void setFlow(bool flow) {mIsFlow = flow;}
  bool getFlow() const {return mIsFlow;}
  void setStream(bool stream) {mIsStream = stream;}
  bool getStream() const {return mIsStream;}
  void setReplaceable(bool replaceable) {mIsReplaceable = replaceable;}
  bool getReplaceable() const {return mIsReplaceable;}
  void setRedeclare(bool redeclare) {mIsRedeclare = redeclare;}
  bool getRedeclare() const {return mIsRedeclare;}
  void setVariablity(const QString &variability) {mVariability = variability;}
  QString getVariablity() const {return mVariability;}
  void setInner(bool inner) {mIsInner = inner;}
  bool getInner() const {return mIsInner;}
  void setOuter(bool outer) {mIsOuter = outer;}
  bool getOuter() const {return mIsOuter;}
  void setCausality(const QString &causality) {mCasuality = causality;}
  QString getCausality() const {return mCasuality;}
  void setIsElement(bool isElement) {mIsElement = isElement;}
  bool getIsElement() const {return mIsElement;}
  void setRestriction(const QString &restriction) {mRestriction = restriction;}
  QString getRestriction() const {return mRestriction;}
  void setParentClassName(const QString &parentClassName) {mParentClassName = parentClassName;}
  QString getParentClassName() const {return mParentClassName;}
  void setConstrainedByClassName(const QString &constrainedByClassName) {mConstrainedByClassName = constrainedByClassName;}
  QString getConstrainedByClassName() const {return mConstrainedByClassName;}
  void setArrayIndex(const QString &arrayIndex);
  QString getArrayIndex() const {return mArrayIndex;}
  int getArrayIndexAsNumber(bool *ok) const;
  bool isArray() const {return mIsArray;}
  bool isModifiersLoaded() const {return mModifiersLoaded;}
  void setModifiersLoaded(bool modifiersLoaded) {mModifiersLoaded = modifiersLoaded;}
  void setModifiersMap(QMap<QString, QString> modifiersMap) {mModifiersMap = modifiersMap;}
  QMap<QString, QString> getModifiersMapWithoutFetching() const {return mModifiersMap;}
  QMap<QString, QString> getModifiersMap(OMCProxy *pOMCProxy, QString className, Element *pElement);
  bool isParameterValueLoaded() const {return mParameterValueLoaded;}
  void setParameterValue(const QString &parameterValue) {mParameterValue = parameterValue;}
  QString getParameterValueWithoutFetching() const {return mParameterValue;}
  QString getParameterValue(OMCProxy *pOMCProxy, const QString &className);
  // CompositeModel attributes
  void setStartCommand(const QString &startCommand) {mStartCommand = startCommand;}
  QString getStartCommand() const {return mStartCommand;}
  void setExactStep(bool exactStep) {mExactStep = exactStep;}
  bool getExactStep() const {return mExactStep;}
  void setModelFile(const QString &modelFile) {mModelFile = modelFile;}
  QString getModelFile() const {return mModelFile;}
  void setGeometryFile(const QString &geometryFile) {mGeometryFile = geometryFile;}
  QString getGeometryFile() const {return mGeometryFile;}
  void setPosition(const QString &position) {mPosition = position;}
  QString getPosition() const {return mPosition;}
  void setAngle321(const QString &angle321) {mAngle321 = angle321;}
  QString getAngle321() const {return mAngle321;}
  void setDimensions(int dimensions) {mDimensions = dimensions;}
  int getDimensions() const {return mDimensions;}
  void setTLMCausality(const QString &causality) {mTLMCausality = causality;}
  QString getTLMCausality() const {return mTLMCausality;}
  void setDomain(const QString &domain) {mDomain = domain;}
  QString getDomain() const {return mDomain;}
  // operator overloading
  bool operator==(const ElementInfo &componentInfo) const;
  bool operator!=(const ElementInfo &componentInfo) const;
  QString getHTMLDescription() const;
private:
  QString mParentClassName;
  QString mClassName;
  QString mName;
  QString mComment;
  bool mIsProtected;
  bool mIsFinal;
  bool mIsEach;
  bool mIsFlow;
  bool mIsStream;
  bool mIsReplaceable;
  bool mIsRedeclare;
  bool mIsElement;
  QString mRestriction; // only matters when mIsElement is true.
  QMap<QString, QString> mVariabilityMap;
  QString mVariability;
  bool mIsInner;
  bool mIsOuter;
  QMap<QString, QString> mCasualityMap;
  QString mCasuality;
  QString mConstrainedByClassName;
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

  void fetchModifiers(OMCProxy *pOMCProxy, QString className, Element *pElement);
  bool isModiferClassRecord(QString modifierName, Element *pElement);
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
  Element(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ElementInfo *pElementInfo, GraphicsView *pGraphicsView);
  Element(LibraryTreeItem *pLibraryTreeItem, Element *pParentElement);
  Element(Element *pElement, Element *pParentElement, Element *pRootParentElement);
  Element(Element *pElement, GraphicsView *pGraphicsView);
  // used for interface point
  Element(ElementInfo *pElementInfo, Element *pParentElement);
  bool isInheritedElement() {return mIsInheritedElement;}
  bool isInheritedComponent() {return isInheritedElement();}
  bool hasShapeAnnotation(Element *pElement);
  bool hasNonExistingClass();
  QRectF boundingRect() const override;
  QRectF itemsBoundingRect();
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0) override;
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  QString getName() {return mpElementInfo->getName();}
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  Element *getReferenceComponent() {return mpReferenceComponent;}
  Element* getParentComponent() {return mpParentComponent;}
  Element* getRootParentComponent();
  ElementType getElementType() {return mElementType;}
  QString getTransformationString() {return mTransformationString;}
  void setDialogAnnotation(QStringList dialogAnnotation) {mDialogAnnotation = dialogAnnotation;}
  QStringList getDialogAnnotation() {return mDialogAnnotation;}
  void setChoicesAnnotation(QStringList choicesAnnotation) {mChoicesAnnotation = choicesAnnotation;}
  QStringList getChoicesAnnotation() {return mChoicesAnnotation;}
  void setChoicesAllMatchingAnnotation(QStringList choicesAllMatching) {mChoicesAllMatchingAnnotation = choicesAllMatching;}
  QStringList getChoicesAllMatchingAnnotation() {return mChoicesAllMatchingAnnotation;}
  void setChoices(QStringList choices) {mChoices = choices;}
  QStringList getChoices() {return mChoices;}
  bool hasChoices() {return (mChoices.size() > 0);}
  CoOrdinateSystem getCoOrdinateSystem() const;
  OriginItem* getOriginItem() {return mpOriginItem;}
  QAction* getParametersAction() {return mpParametersAction;}
  QAction* getFetchInterfaceDataAction() {return mpFetchInterfaceDataAction;}
  QAction* getAttributesAction() {return mpAttributesAction;}
  QAction* getOpenClassAction() {return mpOpenClassAction;}
  QAction* getSubModelAttributesAction() {return mpSubModelAttributesAction;}
  QAction* getElementPropertiesAction() {return mpElementPropertiesAction;}
  ElementInfo* getElementInfo() {return mpElementInfo;}
  ElementInfo* getComponentInfo() {return mpElementInfo;}
  QList<ShapeAnnotation*> getShapesList() {return mShapesList;}
  QList<Element*> getInheritedElementsList() {return mInheritedElementsList;}
  QList<Element*> getElementsList() {return mElementsList;}
  QList<Element*> getComponentsList() {return mElementsList;}
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
  int getArrayIndexAsNumber(bool *ok = 0) const;
  bool isConnectorSizing();
  static bool isParameterConnectorSizing(Element *pElement, QString parameter);
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
  void removeChildren();
  void emitAdded();
  void emitTransformChange(bool positionChanged) {emit transformChange(positionChanged);}
  void emitTransformHasChanged();
  void emitChanged();
  void emitDeleted();
  void componentParameterHasChanged();
  QString getParameterDisplayString(QString parameterName);
  QString getParameterModifierValue(const QString &parameterName, const QString &modifier);
  QString getDerivedClassModifierValue(QString modifierName);
  QString getInheritedDerivedClassModifierValue(Element *pElement, QString modifierName);
  void shapeAdded();
  void shapeUpdated();
  void shapeDeleted();
  void renameComponentInConnections(QString newName);
  void insertInterfacePoint(QString interfaceName, QString position, QString angle321, int dimensions, QString causality, QString domain);
  void removeInterfacePoint(QString interfaceName);
  void adjustInterfacePoints();
  void updateElementTransformations(const Transformation &oldTransformation, const bool positionChanged);
  void handleOMSElementDoubleClick();
  bool isInBus() {return mpBusComponent != 0;}
  void setBusComponent(Element *pBusComponent);
  Element* getBusComponent() {return mpBusComponent;}
  Element* getElementByName(const QString &componentName);

  Transformation mTransformation;
  Transformation mOldTransformation;
private:
  Element *mpReferenceComponent;
  Element *mpParentComponent;
  LibraryTreeItem *mpLibraryTreeItem;
  ElementInfo *mpElementInfo;
  GraphicsView *mpGraphicsView;
  bool mIsInheritedElement;
  ElementType mElementType;
  QString mTransformationString;
  QStringList mDialogAnnotation;
  QStringList mChoicesAnnotation;
  QStringList mChoicesAllMatchingAnnotation;
  QStringList mChoices;
  QString mParameterValue;
  LineAnnotation *mpNonExistingElementLine;
  RectangleAnnotation *mpDefaultElementRectangle;
  TextAnnotation *mpDefaultElementText;
  RectangleAnnotation *mpStateElementRectangle;
  QAction *mpParametersAction;
  QAction *mpFetchInterfaceDataAction;
  QAction *mpAttributesAction;
  QAction *mpOpenClassAction;
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
  QList<Element*> mInheritedElementsList;
  QList<ShapeAnnotation*> mShapesList;
  QList<Element*> mElementsList;
  QPointF mOldScenePosition;
  QPointF mOldPosition;
  bool mHasTransition;
  bool mIsInitialState;
  bool mActiveState;
  Element *mpBusComponent;
  void createNonExistingElement();
  void createDefaultElement();
  void createStateElement();
  void drawInterfacePoints();
  void drawElement();
  void reDrawElement(bool coOrdinateSystemUpdated = false);
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
  void setOriginAndExtents();
  void updateConnections();
  QString getParameterDisplayStringFromExtendsModifiers(QString parameterName);
  QString getParameterDisplayStringFromExtendsParameters(QString parameterName, QString modifierString);
  bool checkEnumerationDisplayString(QString &displayString, const QString &typeName);
  void updateToolTip();
  bool canUseDiagramAnnotation();
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
  void handleLoaded();
  void handleUnloaded();
  void handleCoOrdinateSystemUpdated();
  void handleShapeAdded();
  void handleElementAdded();
  void handleNameChanged();
  void referenceElementAdded();
  void referenceElementTransformHasChanged();
  void referenceElementChanged();
  void referenceElementDeleted();
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
  void showParameters();
  void showAttributes();
  void fetchInterfaceData();
  void openClass();
  void showSubModelAttributes();
  void showElementPropertiesDialog();
  void updateDynamicSelect(double time);
protected:
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value) override;
};

#endif // ELEMENT_H
