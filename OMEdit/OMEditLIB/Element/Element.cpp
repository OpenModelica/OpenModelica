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

#include "MainWindow.h"
#include "Element.h"
#include "ElementProperties.h"
#include "OMS/ElementPropertiesDialog.h"
#include "Modeling/Commands.h"
#include "Modeling/DocumentationWidget.h"
#include "Plotting/VariablesWidget.h"
#include "OMS/BusDialog.h"
#include "Util/ResourceCache.h"
#include "Options/OptionsDialog.h"

#include <QMessageBox>
#include <QMenu>
#include <QDockWidget>

/*!
 * \class ElementInfo
 * \brief A class containing the information about the component like visibility, stream, casuality etc.
 */
/*!
 * \brief ElementInfo::ElementInfo
 * \param pParent
 */
ElementInfo::ElementInfo(QObject *pParent)
  : QObject(pParent)
{
  mParentClassName = "";
  mClassName = "";
  mName = "";
  mComment = "";
  mIsProtected = false;
  mIsFinal = false;
  mIsEach = false;
  mIsFlow = false;
  mIsStream = false;
  mIsReplaceable = false;
  mIsRedeclare = false;
  mIsElement = false;
  mRestriction = "";
  mVariabilityMap.insert("constant", "constant");
  mVariabilityMap.insert("discrete", "discrete");
  mVariabilityMap.insert("parameter", "parameter");
  mVariabilityMap.insert("unspecified", "");
  mVariability = "";
  mIsInner = false;
  mIsOuter = false;
  mCasualityMap.insert("input", "input");
  mCasualityMap.insert("output", "output");
  mCasualityMap.insert("unspecified", "");
  mCasuality = "";
  mConstrainedByClassName = "";
  mArrayIndex = "";
  mIsArray = false;
  mModifiersLoaded = false;
  mModifiersMap.clear();
  mParameterValueLoaded = false;
  mParameterValue = "";
  mStartCommand = "";
  mExactStep = false;
  mModelFile = "";
  mGeometryFile = "";
  mPosition = "0,0,0";
  mAngle321 = "0,0,0";
  mDimensions = 3;
  mTLMCausality = StringHandler::getTLMCausality(StringHandler::TLMBidirectional);
  mDomain = StringHandler::getTLMDomain(StringHandler::Mechanical);
}

/*!
 * \brief ElementInfo::ElementInfo
 * \param pElementInfo
 * \param pParent
 */
ElementInfo::ElementInfo(ElementInfo *pElementInfo, QObject *pParent)
  : QObject(pParent)
{
  updateElementInfo(pElementInfo);
}

void ElementInfo::updateElementInfo(const ElementInfo *pElementInfo)
{
  mParentClassName = pElementInfo->getParentClassName();
  mClassName = pElementInfo->getClassName();
  mName = pElementInfo->getName();
  mComment = pElementInfo->getComment();
  mIsProtected = pElementInfo->getProtected();
  mIsFinal = pElementInfo->getFinal();
  mIsEach = pElementInfo->getEach();
  mIsFlow = pElementInfo->getFlow();
  mIsStream = pElementInfo->getStream();
  mIsReplaceable = pElementInfo->getReplaceable();
  mIsRedeclare = pElementInfo->getRedeclare();
  mIsElement = pElementInfo->getIsElement();
  mRestriction = pElementInfo->getRestriction();
  mVariabilityMap.insert("constant", "constant");
  mVariabilityMap.insert("discrete", "discrete");
  mVariabilityMap.insert("parameter", "parameter");
  mVariabilityMap.insert("unspecified", "");
  mVariability = pElementInfo->getVariablity();
  mIsInner = pElementInfo->getInner();
  mIsOuter = pElementInfo->getOuter();
  mCasualityMap.insert("input", "input");
  mCasualityMap.insert("output", "output");
  mCasualityMap.insert("unspecified", "");
  mCasuality = pElementInfo->getCausality();
  mConstrainedByClassName = pElementInfo->getConstrainedByClassName();
  mArrayIndex = pElementInfo->getArrayIndex();
  mIsArray = pElementInfo->isArray();
  mModifiersMap.clear();
  mModifiersLoaded = pElementInfo->isModifiersLoaded();
  mModifiersMap = pElementInfo->getModifiersMapWithoutFetching();
  mParameterValueLoaded = pElementInfo->isParameterValueLoaded();
  mParameterValue = pElementInfo->getParameterValueWithoutFetching();
  mStartCommand = pElementInfo->getStartCommand();
  mExactStep = pElementInfo->getExactStep();
  mModelFile = pElementInfo->getModelFile();
  mGeometryFile = pElementInfo->getGeometryFile();
  mPosition = pElementInfo->getPosition();
  mAngle321 = pElementInfo->getAngle321();
  mDimensions = pElementInfo->getDimensions();
  mTLMCausality = pElementInfo->getTLMCausality();
  mDomain = pElementInfo->getDomain();
}

/*!
 * \brief ElementInfo::parseElementInfoString
 * Parses the component info string.
 * \param value
 */
void ElementInfo::parseElementInfoString(QString value)
{
  /*
  00 co/cl
  01 restriction // only matters for class
  02 type
  03 name (component or class name)
  04 comment
  05 public/protected
  06 final
  07 flow
  08 stream
  09 replaceable
  10 variability
  11 inner
  12 input/output
  13 constrainedby
  14 elementDims, TypeDims
  */

  if (value.isEmpty()) {
    return;
  }
  QStringList list = StringHandler::unparseStrings(value);

  // read the classifier component "co" vs class "cl"
  if (list.size() > 0) {
    mIsElement = StringHandler::removeFirstLastQuotes(list.at(0)).contains("cl");
  } else {
    return;
  }
  // read the restriction
  if (list.size() > 1) {
    mRestriction = list.at(1);
  } else {
    return;
  }
  // read the class name, i.e. type name
  if (list.size() > 2) {
    mClassName = list.at(2);
    if (mClassName.startsWith(".")) {
      mClassName.remove(0, 1);
    }
  } else {
    return;
  }
  // read the name
  if (list.size() > 3) {
    mName = list.at(3);
  } else {
    return;
  }
  // read the class comment
  if (list.size() > 4) {
    mComment = list.at(4);
  } else {
    return;
  }
  // read the class access
  if (list.size() > 5) {
    mIsProtected = StringHandler::removeFirstLastQuotes(list.at(5)).contains("protected");
  } else {
    return;
  }
  // read the final attribute
  if (list.size() > 6) {
    mIsFinal = list.at(6).contains("true");
  } else {
    return;
  }
  // read the flow attribute
  if (list.size() > 7) {
    mIsFlow = list.at(7).contains("true");
  } else {
    return;
  }
  // read the stream attribute
  if (list.size() > 8) {
    mIsStream = list.at(8).contains("true");
  } else {
    return;
  }
  // read the replaceable attribute
  if (list.size() > 9) {
    mIsReplaceable = list.at(9).contains("true");
  } else {
    return;
  }
  // read the variability attribute
  if (list.size() > 10) {
    QMap<QString, QString>::iterator variability_it;
    for (variability_it = mVariabilityMap.begin(); variability_it != mVariabilityMap.end(); ++variability_it) {
      if (variability_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(10))) == 0) {
        mVariability = variability_it.value();
        break;
      }
    }
  }
  // read the inner attribute
  if (list.size() > 11) {
    mIsInner = list.at(11).contains("inner");
    mIsOuter = list.at(11).contains("outer");
  } else {
    return;
  }
  // read the casuality attribute
  if (list.size() > 12) {
    QMap<QString, QString>::iterator casuality_it;
    for (casuality_it = mCasualityMap.begin(); casuality_it != mCasualityMap.end(); ++casuality_it) {
      if (casuality_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(12))) == 0) {
        mCasuality = casuality_it.value();
        break;
      }
    }
  }
  // read the constrainedby class name
  if (list.size() > 13) {
    mConstrainedByClassName = list.at(13);
  } else {
    return;
  }
  // read the array index value
  if (list.size() > 14) {
    setArrayIndex(list.at(14));
  }
}



/*!
 * \brief ElementInfo::fetchParameterValue
 * Fetches the Element parameter value if any.
 * \param pOMCProxy
 * \param className
 */
void ElementInfo::fetchParameterValue(OMCProxy *pOMCProxy, const QString &className)
{
  mParameterValue = pOMCProxy->getParameterValue(className, mName);
}

/*!
 * \brief ElementInfo::applyDefaultPrefixes
 * Applies the default prefixes.
 * \param defaultPrefixes
 */
void ElementInfo::applyDefaultPrefixes(QString defaultPrefixes)
{
  if (defaultPrefixes.contains("inner")) {
    mIsInner = true;
  }
  if (defaultPrefixes.contains("outer")) {
    mIsOuter = true;
  }
  if (defaultPrefixes.contains("replaceable")) {
    mIsReplaceable = true;
  }
  if (defaultPrefixes.contains("constant")) {
    mVariability = "constant";
  }
  if (defaultPrefixes.contains("parameter")) {
    mVariability = "parameter";
  }
  if (defaultPrefixes.contains("discrete")) {
    mVariability = "discrete";
  }
}

/*!
 * \brief ElementInfo::setArrayIndex
 * Sets the array index
 * \param arrayIndex
 */
void ElementInfo::setArrayIndex(const QString &arrayIndex)
{
  if (arrayIndex.compare("{}") != 0) {
    mIsArray = true;
  } else {
    mIsArray = false;
  }
  mArrayIndex = StringHandler::removeFirstLastCurlBrackets(arrayIndex);
}

/*!
 * \brief ElementInfo::getArrayIndexAsNumber
 * Returns the array index as number.
 * \param ok
 * \return
 */
int ElementInfo::getArrayIndexAsNumber(bool *ok) const
{
  if (isArray()) {
    return mArrayIndex.toInt(ok);
  } else {
    if (ok) *ok = false;
    return 0;
  }
}

/*!
 * \brief ElementInfo::getModifiersMap
 * Fetches the Element modifiers if needed and return them.
 * \param pOMCProxy
 * \param className
 * \param pElement
 * \return
 */
QMap<QString, QString> ElementInfo::getModifiersMap(OMCProxy *pOMCProxy, QString className, Element *pElement)
{
  if (!mModifiersLoaded) {
    fetchModifiers(pOMCProxy, className, pElement);
    mModifiersLoaded = true;
  }
  return mModifiersMap;
}

/*!
 * \brief ElementInfo::getParameterValue
 * Fetches the parameters value if needed and return it.
 * \param pOMCProxy
 * \param className
 * \return
 */
QString ElementInfo::getParameterValue(OMCProxy *pOMCProxy, const QString &className)
{
  if (!mParameterValueLoaded) {
    fetchParameterValue(pOMCProxy, className);
    mParameterValueLoaded = true;
  }
  return mParameterValue;
}

/*!
 * \brief ElementInfo::operator ==
 * \param componentInfo
 * Compares the ElementInfo and returns true if its equal.
 * \return
 */
bool ElementInfo::operator==(const ElementInfo &componentInfo) const
{
  return (componentInfo.getParentClassName() == this->getParentClassName()) && (componentInfo.getClassName() == this->getClassName()) && (componentInfo.getName() == this->getName()) &&
      (componentInfo.getComment() == this->getComment()) && (componentInfo.getProtected() == this->getProtected()) &&
      (componentInfo.getFinal() == this->getFinal()) && (componentInfo.getEach() == this->getEach()) && (componentInfo.getFlow() == this->getFlow()) &&
      (componentInfo.getStream() == this->getStream()) && (componentInfo.getReplaceable() == this->getReplaceable()) &&
      (componentInfo.getRedeclare() == this->getRedeclare()) && (componentInfo.getIsElement() == this->getIsElement()) &&
      (componentInfo.getRestriction() == this->getRestriction()) && (componentInfo.getVariablity() == this->getVariablity()) && (componentInfo.getInner() == this->getInner()) &&
      (componentInfo.getOuter() == this->getOuter()) && (componentInfo.getCausality() == this->getCausality()) &&
      (componentInfo.getConstrainedByClassName() == this->getConstrainedByClassName()) && (componentInfo.getArrayIndex() == this->getArrayIndex()) &&
      (componentInfo.getModifiersMapWithoutFetching() == this->getModifiersMapWithoutFetching()) &&
      (componentInfo.getParameterValueWithoutFetching() == this->getParameterValueWithoutFetching()) &&
      (componentInfo.getStartCommand() == this->getStartCommand()) && (componentInfo.getExactStep() == this->getExactStep()) &&
      (componentInfo.getModelFile() == this->getModelFile()) && (componentInfo.getGeometryFile() == this->getGeometryFile()) &&
      (componentInfo.getPosition() == this->getPosition()) && (componentInfo.getAngle321() == this->getAngle321()) &&
      (componentInfo.getDimensions() == this->getDimensions()) && (componentInfo.getTLMCausality() == this->getTLMCausality()) &&
      (componentInfo.getDomain() == this->getDomain());
}

/*!
 * \brief ElementInfo::operator !=
 * \param componentInfo
 * Compares the ElementInfo and returns true if its not equal.
 * \return
 */
bool ElementInfo::operator!=(const ElementInfo &componentInfo) const
{
  return !operator==(componentInfo);
}

QString ElementInfo::getHTMLDescription() const
{
  return QString("<b>%1</b><br/>&nbsp;&nbsp;&nbsp;&nbsp;%2 <i>\"%3\"<i>")
      .arg(mClassName, mName, Utilities::escapeForHtmlNonSecure(mComment));
}

/*!
 * \brief ElementInfo::fetchModifiers
 * Fetches the Element modifiers if any.
 * \param pOMCProxy
 * \param className
 * \param pElement
 */
void ElementInfo::fetchModifiers(OMCProxy *pOMCProxy, QString className, Element *pElement)
{
  mModifiersMap.clear();
  QStringList componentModifiersList = pOMCProxy->getElementModifierNames(className, mName);
  foreach (QString componentModifier, componentModifiersList) {
    QString modifierName = StringHandler::getFirstWordBeforeDot(componentModifier);
    // if we have already read the record modifier then continue
    if (mModifiersMap.contains(modifierName)) {
      /* Ticket:4081
       * If modifier is record then we can jump over otherwise read the modifier value.
       */
      if (pOMCProxy->isWhat(StringHandler::Record, modifierName)) {
        continue;
      }
    }
    /* Ticket:3626
     * If a modifier class is a record we read the modifer value with submodifiers using OMCProxy::getElementModifierValues()
     * Otherwise read the binding value using OMCProxy::getElementModifierValue()
     */
    if (isModiferClassRecord(modifierName, pElement)) {
      QString originalModifierName = QString(mName).append(".").append(modifierName);
      QString componentModifierValue = pOMCProxy->getElementModifierValues(className, originalModifierName);
      mModifiersMap.insert(modifierName, componentModifierValue);
    } else {
      QString originalModifierName = QString(mName).append(".").append(componentModifier);
      QString componentModifierValue = pOMCProxy->getElementModifierValue(className, originalModifierName);
      mModifiersMap.insert(componentModifier, componentModifierValue);
    }
  }
}

/*!
 * \brief ElementInfo::isModiferClassRecord
 * Returns true if a modifier class is a record.
 * \param modifierName
 * \param pElement
 * \return
 */
bool ElementInfo::isModiferClassRecord(QString modifierName, Element *pElement)
{
  bool result = false;
  foreach (Element *pInheritedElement, pElement->getInheritedElementsList()) {
    /* Since we use the parent ElementInfo for inherited classes so we should not use
     * pInheritedElement->getElementInfo()->getClassName() to get the name instead we should use
     * pInheritedElement->getLibraryTreeItem()->getNameStructure() to get the correct name of inherited class.
     */
    if (pInheritedElement->getLibraryTreeItem() && pInheritedElement->getLibraryTreeItem()->getName().compare(modifierName) == 0 &&
        pInheritedElement->getLibraryTreeItem()->getRestriction() == StringHandler::Record) {
      return true;
    }
    result = isModiferClassRecord(modifierName, pInheritedElement);
    if (result) {
      return result;
    }
  }
  foreach (Element *pNestedElement, pElement->getElementsList()) {
    if (pNestedElement->getName().compare(modifierName) == 0 && pNestedElement->getLibraryTreeItem() &&
        pNestedElement->getLibraryTreeItem()->getRestriction() == StringHandler::Record) {
      return true;
    }
    result = isModiferClassRecord(modifierName, pNestedElement);
    if (result) {
      return result;
    }
  }
  return result;
}

Element::Element(ModelInstance::Component *pModelComponent, bool inherited, GraphicsView *pGraphicsView, bool createTransformation, QPointF position,
                 const QString &placementAnnotation)
  : QGraphicsItem(0), mpReferenceElement(0), mpParentElement(0)
{
  setZValue(2000);
  mpModelComponent = pModelComponent;
  mpModel = pModelComponent->getModel();
  mName = mpModelComponent->getName();
  mClassName = mpModelComponent->getType();
  mpLibraryTreeItem = 0;
  mpElementInfo = 0;
  mpGraphicsView = pGraphicsView;
  mIsInheritedElement = inherited;
  mElementType = Element::Root;
  mTransformationString = "";
  setOldScenePosition(QPointF(0, 0));
  setOldPosition(QPointF(0, 0));
  setElementFlags(true);
  mpLibraryTreeItem = 0;
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  createStateElement();
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  drawElement();
  // transformation
  mTransformation = Transformation(mpGraphicsView->getViewType(), this);
  if (createTransformation) {
    if (boundingRect().width() > 0) {
      mTransformation.setWidth(boundingRect().width());
    }
    if (boundingRect().height() > 0) {
      mTransformation.setHeight(boundingRect().height());
    }
    // snap to grid while creating component
    position = mpGraphicsView->snapPointToGrid(position);
    mTransformation.setOrigin(position);
    ModelInstance::CoordinateSystem coordinateSystem = getCoOrdinateSystemNew();
    qreal initialScale = coordinateSystem.getInitialScale();
    QVector<QPointF> extent;
    qreal xExtent = initialScale * boundingRect().width() / 2;
    qreal yExtent = initialScale * boundingRect().height() / 2;
    extent.append(QPointF(-xExtent, -yExtent));
    extent.append(QPointF(xExtent, yExtent));
    mTransformation.setExtent(extent);
    mTransformation.setRotateAngle(0.0);
  } else if (!placementAnnotation.isEmpty()) {
    mTransformation.parseTransformationString(placementAnnotation, boundingRect().width(), boundingRect().height());
  } else {
    mTransformation.parseTransformation(mpModelComponent->getAnnotation()->getPlacementAnnotation(), getCoOrdinateSystemNew());
  }
  setTransform(mTransformation.getTransformationMatrix());
  setDialogAnnotation(QStringList());
  setChoicesAnnotation(QStringList());
  setChoicesAllMatchingAnnotation(QStringList());
  setChoices(QStringList());
  // create actions
  createActions();
  mpOriginItem = new OriginItem(this);
  createResizerItems();
  updateToolTip();
  connect(this, SIGNAL(transformHasChanged()), SLOT(updatePlacementAnnotation()));
  connect(this, SIGNAL(transformChange(bool)), SLOT(updateOriginItem()));
  connect(this, SIGNAL(transformHasChanged()), SLOT(updateOriginItem()));
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

Element::Element(ModelInstance::Model *pModel, Element *pParentElement)
  : QGraphicsItem(pParentElement), mpReferenceElement(0), mpParentElement(pParentElement)
{
  /* Ticket #4013
   * Use same ModelElement as parent
   * Creating a new ModelElement here for inherited classes gives wrong display of text names.
   */
  mpModelComponent = mpParentElement->getModelComponent();
  mpModel = pModel;
  mName = mpModelComponent->getName();
  mClassName = mpModelComponent->getType();
  mpLibraryTreeItem = 0;
  mpElementInfo = 0;
  mpGraphicsView = mpParentElement->getGraphicsView();
  mIsInheritedElement = mpParentElement->isInheritedElement();
  mElementType = Element::Extend;
  mTransformationString = "";
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  mpStateElementRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  drawInheritedElementsAndShapes();
  setDialogAnnotation(QStringList());
  setChoicesAnnotation(QStringList());
  setChoicesAllMatchingAnnotation(QStringList());
  setChoices(QStringList());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

Element::Element(ModelInstance::Component *pModelComponent, Element *pParentElement, Element *pRootParentElement)
  : QGraphicsItem(pRootParentElement), mpReferenceElement(0), mpParentElement(pParentElement)
{
  mpModelComponent = pModelComponent;
  mpModel = pModelComponent->getModel();
  mName = mpModelComponent->getName();
  mClassName = mpModelComponent->getType();
  mpLibraryTreeItem = 0;
  mpElementInfo = 0;
  mIsInheritedElement = mpParentElement->isInheritedElement();
  mElementType = Element::Port;
  mpGraphicsView = mpParentElement->getGraphicsView();
  mTransformationString = "";
  setDialogAnnotation(QStringList());
  setChoicesAnnotation(QStringList());
  setChoicesAllMatchingAnnotation(QStringList());
  setChoices(QStringList());
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  mpStateElementRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  drawInheritedElementsAndShapes();
  mTransformation = Transformation(StringHandler::Icon, this);
  mTransformation.parseTransformation(mpModelComponent->getAnnotation()->getPlacementAnnotation(), getCoOrdinateSystemNew());
  setTransform(mTransformation.getTransformationMatrix());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  updateToolTip();
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

Element::Element(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ElementInfo *pElementInfo, GraphicsView *pGraphicsView)
  : QGraphicsItem(0), mpReferenceElement(0), mpParentElement(0)
{
  setZValue(2000);
  mpLibraryTreeItem = pLibraryTreeItem;
  mpElementInfo = pElementInfo;
  mpElementInfo->setName(name);
  if (mpLibraryTreeItem) {
    mpElementInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  }
  mpGraphicsView = pGraphicsView;
  mIsInheritedElement = false;
  mElementType = Element::Root;
  mTransformationString = StringHandler::getPlacementAnnotation(annotation);
  setOldScenePosition(QPointF(0, 0));
  setOldPosition(QPointF(0, 0));
  setElementFlags(true);
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  createStateElement();
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    createDefaultElement();
    drawInterfacePoints();
  } else {
    drawElement();
  }
  // transformation
  mTransformation = Transformation(mpGraphicsView->getViewType(), this);
  mTransformation.parseTransformationString(mTransformationString, boundingRect().width(), boundingRect().height());
  if (mTransformationString.isEmpty()) {
    // snap to grid while creating component
    position = mpGraphicsView->snapPointToGrid(position);
    mTransformation.setOrigin(position);
    CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
    qreal initialScale = coOrdinateSystem.getInitialScale();
    QVector<QPointF> extent;
    qreal xExtent = initialScale * boundingRect().width() / 2;
    qreal yExtent = initialScale * boundingRect().height() / 2;
    extent.append(QPointF(-xExtent, -yExtent));
    extent.append(QPointF(xExtent, yExtent));
    mTransformation.setExtent(extent);
    mTransformation.setRotateAngle(0.0);
  }
  // dynamically adjust the interface points.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    adjustInterfacePoints();
  }
  setTransform(mTransformation.getTransformationMatrix());
  setDialogAnnotation(StringHandler::getAnnotation(annotation, "Dialog"));
  setChoicesAnnotation(StringHandler::getAnnotation(annotation, "choices"));
  setChoicesAllMatchingAnnotation(StringHandler::getAnnotation(annotation, "choicesAllMatching"));
  // add choices if there are any
  if (getChoicesAnnotation().size() > 2) {
    QString array = getChoicesAnnotation()[2];
    QStringList choices = StringHandler::unparseStrings(array);
    setChoices(choices);
  } else {
    setChoices(QStringList());
  }
  // create actions
  createActions();
  mpOriginItem = new OriginItem(this);
  createResizerItems();
  updateToolTip();
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(coOrdinateSystemUpdatedForComponent()), SLOT(handleCoOrdinateSystemUpdated()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleElementAdded()));
    connect(mpLibraryTreeItem, SIGNAL(nameChanged()), SLOT(handleNameChanged()));
  }
  connect(this, SIGNAL(transformHasChanged()), SLOT(updatePlacementAnnotation()));
  connect(this, SIGNAL(transformChange(bool)), SLOT(updateOriginItem()));
  connect(this, SIGNAL(transformHasChanged()), SLOT(updateOriginItem()));
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
  /* Ticket:4204
   * If the child class use text annotation from base class then we need to call this
   * since when the base class is created the child class doesn't exist.
   */
  displayTextChangedRecursive();
}

Element::Element(LibraryTreeItem *pLibraryTreeItem, Element *pParentElement)
  : QGraphicsItem(pParentElement), mpReferenceElement(0), mpParentElement(pParentElement)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mpElementInfo = mpParentElement->getElementInfo();
  /* Ticket #4013
   * We should have one ElementInfo for each Element.
   * Creating a new ElementInfo here for inherited classes gives wrong display of text names.
   */
//  mpElementInfo = new ElementInfo;
//  mpElementInfo->setName(mpParentComponent->getElementInfo()->getName());
//  mpElementInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  mpGraphicsView = mpParentElement->getGraphicsView();
  mIsInheritedElement = mpParentElement->isInheritedElement();
  mElementType = Element::Extend;
  mTransformationString = "";
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  mpStateElementRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  drawInheritedElementsAndShapes();
  setDialogAnnotation(QStringList());
  setChoicesAnnotation(QStringList());
  setChoicesAllMatchingAnnotation(QStringList());
  setChoices(QStringList());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleElementAdded()));
  }
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

Element::Element(Element *pElement, Element *pParentElement, Element *pRootParentElement)
  : QGraphicsItem(pRootParentElement), mpReferenceElement(pElement), mpParentElement(pParentElement)
{
  mpLibraryTreeItem = mpReferenceElement->getLibraryTreeItem();
  mpElementInfo = mpReferenceElement->getElementInfo();
  mIsInheritedElement = mpReferenceElement->isInheritedElement();
  mElementType = Element::Port;
  mpGraphicsView = mpParentElement->getGraphicsView();
  mTransformationString = mpReferenceElement->getTransformationString();
  mDialogAnnotation = mpReferenceElement->getDialogAnnotation();
  mChoicesAnnotation = mpReferenceElement->getChoicesAnnotation();
  mChoicesAllMatchingAnnotation = mpReferenceElement->getChoicesAllMatchingAnnotation();
  mChoices = mpReferenceElement->getChoices();
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  mpStateElementRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = mpReferenceElement->getBusComponent();
  drawInheritedElementsAndShapes();
  mTransformation = Transformation(mpReferenceElement->mTransformation);
  setTransform(mTransformation.getTransformationMatrix());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  updateToolTip();
  setVisible(!mpReferenceElement->isInBus());
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleElementAdded()));
  }
  connect(mpReferenceElement, SIGNAL(added()), SLOT(referenceElementAdded()));
  connect(mpReferenceElement, SIGNAL(transformHasChanged()), SLOT(referenceElementTransformHasChanged()));
  connect(mpReferenceElement, SIGNAL(displayTextChanged()), SLOT(componentNameHasChanged()));
  connect(mpReferenceElement, SIGNAL(deleted()), SLOT(referenceElementDeleted()));
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

Element::Element(Element *pElement, GraphicsView *pGraphicsView)
  : QGraphicsItem(0), mpReferenceElement(pElement), mpParentElement(0)
{
  setZValue(2000);
  mpLibraryTreeItem = mpReferenceElement->getLibraryTreeItem();
  mpElementInfo = mpReferenceElement->getElementInfo();
  mpGraphicsView = pGraphicsView;
  mIsInheritedElement = true;
  mElementType = Element::Root;
  mTransformationString = mpReferenceElement->getTransformationString();
  mDialogAnnotation = mpReferenceElement->getDialogAnnotation();
  mChoicesAnnotation = mpReferenceElement->getChoicesAnnotation();
  mChoicesAllMatchingAnnotation = mpReferenceElement->getChoicesAllMatchingAnnotation();
  mChoices = mpReferenceElement->getChoices();
  setOldScenePosition(QPointF(0, 0));
  setOldPosition(QPointF(0, 0));
  setElementFlags(true);
  mpNonExistingElementLine = 0;
  mpDefaultElementRectangle = 0;
  mpDefaultElementText = 0;
  createStateElement();
  mHasTransition = mpReferenceElement->hasTransition();;
  mIsInitialState = mpReferenceElement->isInitialState();
  mActiveState = false;
  mpBusComponent = 0;
  drawElement();
  mTransformation = Transformation(mpReferenceElement->mTransformation);
  setTransform(mTransformation.getTransformationMatrix());
  createActions();
  mpOriginItem = new OriginItem(this);
  mpGraphicsView->addItem(mpOriginItem);
  createResizerItems();
  mpGraphicsView->addItem(this);
  updateToolTip();
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
  }
  connect(mpReferenceElement, SIGNAL(added()), SLOT(referenceElementAdded()));
  connect(mpReferenceElement, SIGNAL(transformHasChanged()), SLOT(referenceElementTransformHasChanged()));
  connect(mpReferenceElement, SIGNAL(transformHasChanged()), SLOT(updateOriginItem()));
  connect(mpReferenceElement, SIGNAL(transformChange(bool)), SIGNAL(transformChange(bool)));
  connect(mpReferenceElement, SIGNAL(displayTextChanged()), SLOT(componentNameHasChanged()));
  connect(mpReferenceElement, SIGNAL(changed()), SLOT(referenceElementChanged()));
  connect(mpReferenceElement, SIGNAL(deleted()), SLOT(referenceElementDeleted()));
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
  /* Ticket:4204
   * If the child class use text annotation from base class then we need to call this
   * since when the base class is created the child class doesn't exist.
   */
  displayTextChangedRecursive();
}

Element::Element(ElementInfo *pElementInfo, Element *pParentElement)
  : QGraphicsItem(pParentElement), mpReferenceElement(0), mpParentElement(pParentElement)
{
  mpLibraryTreeItem = 0;
  mpElementInfo = pElementInfo;
  mIsInheritedElement = false;
  mElementType = Element::Port;
  mpGraphicsView = mpParentElement->getGraphicsView();
  mTransformationString = "";
  mDialogAnnotation.clear();
  mChoicesAnnotation.clear();
  mChoicesAllMatchingAnnotation.clear();
  mChoices.clear();
  mpNonExistingElementLine = 0;
  createDefaultElement();
  mpStateElementRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;

  if (mpElementInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMBidirectional)) {
    if (mpElementInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Mechanical)) {
      mpDefaultElementRectangle->setFillColor(QColor(100, 100, 255));   //Mechanical = blue
    } else if (mpElementInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Electric)) {
      mpDefaultElementRectangle->setFillColor(QColor(255, 255, 100));   //Hydraulic = yellow
    } else if (mpElementInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Hydraulic)) {
      mpDefaultElementRectangle->setFillColor(QColor(100, 255, 100));   //Hydraulic = green
    } else if (mpElementInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Pneumatic)) {
      mpDefaultElementRectangle->setFillColor(QColor(100, 255, 255));   //Pneumatic = turquoise
    } else if (mpElementInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Magnetic)) {
      mpDefaultElementRectangle->setFillColor(QColor(255, 100, 255));   //Magnetic = purple
    }
    mpDefaultElementText->setTextString(QString::number(mpElementInfo->getDimensions())+ "D");
  } else if ((mpElementInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMInput)) ||
             (mpElementInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMOutput))) {
    mpDefaultElementRectangle->setFillColor(QColor(255, 100, 100));       //Signal = red
    if (mpElementInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMInput)) {
      mpDefaultElementText->setTextString("in");
    } else {
      mpDefaultElementText->setTextString("out");
    }
  }
  mpDefaultElementRectangle->setLineColor(QColor(0, 0, 0));
  mpDefaultElementRectangle->setFillPattern(StringHandler::FillSolid);
  mpDefaultElementRectangle->setVisible(true);
  mpDefaultElementText->setFontSize(5);
  mpDefaultElementText->setVisible(true);
  // Transformation. Doesn't matter what we set here since it will be overwritten in adjustInterfacePoints();
  QString transformation = QString("Placement(true,100.0,100.0,-15.0,-15.0,15.0,15.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)");
  mTransformation = Transformation(mpGraphicsView->getViewType(), this);
  mTransformation.parseTransformationString(transformation, boundingRect().width(), boundingRect().height());
  setTransform(mTransformation.getTransformationMatrix());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  updateToolTip();
}

/*!
 * \brief Element::hasShapeAnnotation
 * Checks if Element has any ShapeAnnotation
 * \param pElement
 * \return
 */
bool Element::hasShapeAnnotation(Element *pElement)
{
  if (!pElement->getShapesList().isEmpty()) {
    return true;
  }
  bool iconAnnotationFound = false;
  foreach (Element *pInheritedElement, pElement->getInheritedElementsList()) {
    iconAnnotationFound = hasShapeAnnotation(pInheritedElement);
    if (iconAnnotationFound) {
      return iconAnnotationFound;
    }
  }
  /* Ticket #3654
   * Don't check components because if it has components and no shapes then it looks empty.
   */
//  foreach (Element *pChildElement, pElement->getElementsList()) {
//    iconAnnotationFound = hasShapeAnnotation(pChildElement);
//    if (iconAnnotationFound) {
//      return iconAnnotationFound;
//    }
//    foreach (Element *pInheritedElement, pChildElement->getInheritedElementsList()) {
//      iconAnnotationFound = hasShapeAnnotation(pInheritedElement);
//      if (iconAnnotationFound) {
//        return iconAnnotationFound;
//      }
//    }
//  }
  return iconAnnotationFound;
}

/*!
 * \brief Element::hasNonExistingClass
 * Returns true if any class in the hierarchy is non-existing.
 * \return
 */
bool Element::hasNonExistingClass()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModel->isMissing();
  } else {
    if (mpLibraryTreeItem && mpLibraryTreeItem->isNonExisting()) {
      return true;
    }
    bool nonExistingClassFound = false;
    foreach (Element *pInheritedElement, mInheritedElementsList) {
      nonExistingClassFound = pInheritedElement->hasNonExistingClass();
      if (nonExistingClassFound) {
        return nonExistingClassFound;
      }
    }
    /* Ticket #3706
     * Don't check components because we should not display class as missing one of components class is missing.
     */
  //  foreach (Element *pChildElement, mElementsList) {
  //    nonExistingClassFound = pChildElement->hasNonExistingClass();
  //    if (nonExistingClassFound) {
  //      return nonExistingClassFound;
  //    }
  //    foreach (Element *pInheritedElement, pChildElement->getInheritedElementsList()) {
  //      nonExistingClassFound = pInheritedElement->hasNonExistingClass();
  //      if (nonExistingClassFound) {
  //        return nonExistingClassFound;
  //      }
  //    }
  //  }
    return nonExistingClassFound;
  }
}

/*!
 * \brief Element::boundingRect
 * Reimplementation of QGraphicsItem::boundingRect()
 * We only set the bounding rectangle for root element.
 * So childrenBoundingRect() gets correct bounding rectangle for inherited items when called from Element::shape()
 * \return
 */
QRectF Element::boundingRect() const
{
  if (mElementType == Element::Root) {
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      ModelInstance::CoordinateSystem coordinateSystem = getCoOrdinateSystemNew();
      return coordinateSystem.getExtentRectangle();
    } else {
      CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
      ExtentAnnotation extent = coOrdinateSystem.getExtent();
      qreal left = extent.at(0).x();
      qreal bottom = extent.at(0).y();
      qreal right = extent.at(1).x();
      qreal top = extent.at(1).y();
      return QRectF(left, bottom, qFabs(left - right), qFabs(bottom - top));
    }
  } else {
    return QRectF();
  }
}

/*!
 * \brief Element::shape
 * Reimplementation of QGraphicsItem::shape()
 * Calls QGraphicsItem::childrenBoundingRect() to get the proper bounding rectangle for shape.
 * \return
 */
QPainterPath Element::shape() const
{
  QPainterPath path;
  path.addRect(childrenBoundingRect());
  return path;
}

/*!
 * \brief Element::itemsBoundingRect
 * Gets the bounding rectangle of the Element and its children.
 * \return
 */
QRectF Element::itemsBoundingRect()
{
  QRectF rect = boundingRect() | childrenBoundingRect();
  return mapToScene(rect).boundingRect();
}

void Element::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(painter);
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mTransformation.isValid()) {
    const bool condition = isCondition();
    if (mElementType == Element::Root) {
      setVisible(mTransformation.getVisible());
      if (!condition) {
        setOpacity(0.3);
      }
    } else if (mElementType == Element::Port) {
      setVisible(mTransformation.getVisible() && condition);
    } else {
      /* Element::Extend type ends up in this block
       * we don't set the opacity for it since it will take the opacity of parent.
       */
      setVisible(mTransformation.getVisible());
    }
    if (mpStateElementRectangle) {
      if (isVisible()) {
        if (mHasTransition && mIsInitialState) {
          mpStateElementRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateElementRectangle->setLineThickness(0.5);
        } else if (mHasTransition && !mIsInitialState) {
          mpStateElementRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateElementRectangle->setLineThickness(0.25);
        } else if (!mHasTransition && mIsInitialState) {
          mpStateElementRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateElementRectangle->setLineThickness(0.5);
        } else if (!mHasTransition && !mIsInitialState) {
          mpStateElementRectangle->setLinePattern(StringHandler::LineDash);
          mpStateElementRectangle->setLineThickness(0.25);
        }
        mpStateElementRectangle->setVisible(true);
      } else {
        mpStateElementRectangle->setVisible(false);
      }
    }
  }
}

/*!
 * \brief Element::getName
 * Returns the name of the element.
 * \return
 */
QString Element::getName() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mName;
  } else {
    return mpElementInfo->getName();
  }
}

/*!
 * \brief Element::getClassName
 * Returns the class name of the element.
 * \return
 */
QString Element::getClassName() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mClassName;
  } else {
    return mpElementInfo->getClassName();
  }
}

/*!
 * \brief Element::getComment
 * Returns the element comment
 * \return
 */
QString Element::getComment() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModelComponent->getComment();
  } else {
    return mpElementInfo->getComment();
  }
}

/*!
 * \brief Element::isCondition
 * Returns the element condition.
 * \return
 */
bool Element::isCondition() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModelComponent->getCondition();
  } else {
    return true;
  }
}

/*!
 * \brief Element::getRootParentElement
 * Returns the root parent Element.
 * \return
 */
Element* Element::getRootParentElement()
{
  Element *pElement = this;
  while (pElement->getParentElement()) {
    pElement = pElement->getParentElement();
  }
  return pElement;
}

/*!
 * \brief Element::getCoOrdinateSystem
 * \return
 */
CoOrdinateSystem Element::getCoOrdinateSystem() const
{
  CoOrdinateSystem coOrdinateSystem;
  if (mpLibraryTreeItem && !mpLibraryTreeItem->isNonExisting() && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica
      && mpLibraryTreeItem->getModelWidget()) {
    if (mpLibraryTreeItem->isConnector()) {
      if (mpGraphicsView->getViewType() == StringHandler::Icon) {
        coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->mMergedCoOrdinateSystem;
      } else {
        coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->mMergedCoOrdinateSystem;
      }
    } else {
      coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->mMergedCoOrdinateSystem;
    }
  }
  return coOrdinateSystem;
}

ModelInstance::CoordinateSystem Element::getCoOrdinateSystemNew() const
{
  ModelInstance::CoordinateSystem coordinateSystem;
  if (mpModel) {
    if (mpModelComponent->getModel()->isConnector() && (mpGraphicsView->getViewType() == StringHandler::Diagram) && canUseDiagramAnnotation()) {
      coordinateSystem = mpModel->getAnnotation()->getDiagramAnnotation()->mMergedCoOrdinateSystem;
    } else {
      coordinateSystem = mpModel->getAnnotation()->getIconAnnotation()->mMergedCoOrdinateSystem;
    }
  }
  return coordinateSystem;
}

void Element::setElementFlags(bool enable)
{
  /* Only set the ItemIsMovable & ItemSendsGeometryChanges flags on component if the class is not a system library class
   * AND not a visualization view.
   * AND component is not an inherited shape.
   */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedElement()) {
    setFlag(QGraphicsItem::ItemIsMovable, enable);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
  }
  setFlag(QGraphicsItem::ItemIsSelectable, enable);
}

/*!
 * \brief Element::getTransformationAnnotation
 * Returns the transformation annotation either in Modelica syntax or in the syntax that OMC API accepts.
 * \param ModelicaSyntax
 * \return
 */
QString Element::getTransformationAnnotation(bool ModelicaSyntax)
{
  QString annotationString;
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    annotationString.append(ModelicaSyntax ? "iconTransformation(" : "iconTransformation=transformation(");
  } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
    annotationString.append(ModelicaSyntax ? "transformation(" : "transformation=transformation(");
  }
  QStringList annotationStringList;
  // add the origin
  if (mTransformation.getOrigin().isDynamicSelectExpression() || mTransformation.getOrigin().toQString().compare(QStringLiteral("{0,0}")) != 0) {
    annotationStringList.append(QString("origin=%1").arg(mTransformation.getOrigin().toQString()));
  }
  // add extent points
  if (mTransformation.getExtent().isDynamicSelectExpression() || mTransformation.getExtent().size() > 1) {
    annotationStringList.append(QString("extent=%1").arg(mTransformation.getExtent().toQString()));
  }
  // add icon rotation
  if (mTransformation.getRotateAngle().isDynamicSelectExpression() || mTransformation.getRotateAngle().toQString().compare(QStringLiteral("0")) != 0) {
    annotationStringList.append(QString("rotation=%1").arg(mTransformation.getRotateAngle().toQString()));
  }
  return annotationString.append(annotationStringList.join(",")).append(")");
}

/*!
 * \brief Element::getPlacementAnnotation
 * Returns the placement annotation either in Modelica syntax or in the syntax that OMC API accepts.
 * \param ModelicaSyntax
 * \return
 */
QString Element::getPlacementAnnotation(bool ModelicaSyntax)
{
  // create the placement annotation string
  QString placementAnnotationString = ModelicaSyntax ? "Placement(" : "annotate=Placement(";
  if (mTransformation.isValid()) {
    if (mTransformation.getVisible().isDynamicSelectExpression() || mTransformation.getVisible().toQString().compare(QStringLiteral("true")) != 0) {
      placementAnnotationString.append(QString("visible=%1,").arg(mTransformation.getVisible().toQString()));
    }
  }
  if ((mpLibraryTreeItem && mpLibraryTreeItem->isConnector()) || (mpGraphicsView->getModelWidget()->isNewApi() && mpModel && mpModelComponent->getModel()->isConnector())) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      // first get the component from diagram view and get the transformations
      Element *pElement = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getElementObject(getName());
      if (pElement) {
        placementAnnotationString.append(pElement->getTransformationAnnotation(ModelicaSyntax)).append(", ");
      }
      // then get the icon transformations
      placementAnnotationString.append(getTransformationAnnotation(ModelicaSyntax));
    } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
      // first get the component from diagram view and get the transformations
      placementAnnotationString.append(getTransformationAnnotation(ModelicaSyntax)).append(", ");
      // then get the icon transformations
      Element *pElement = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getElementObject(getName());
      if (pElement) {
        placementAnnotationString.append(pElement->getTransformationAnnotation(ModelicaSyntax));
      }
    }
  } else {
    placementAnnotationString.append(getTransformationAnnotation(ModelicaSyntax));
  }
  placementAnnotationString.append(ModelicaSyntax ? ")" : ")");
  return placementAnnotationString;
}

/*!
 * \brief Element::getOMCTransformationAnnotation
 * Returns the Element placement transformation annotation in OMC format.
 * \param position
 * \return
 */
QString Element::getOMCTransformationAnnotation(QPointF position)
{
  QString annotationString;
  // add the origin
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(position.x(), position.y());
  annotationString.append(QString::number(mTransformation.getOrigin().x())).append(",");
  annotationString.append(QString::number(mTransformation.getOrigin().y())).append(",");
  // add extent points
  ExtentAnnotation extent = mTransformation.getExtent();
  QPointF extent1 = extent.at(0);
  QPointF extent2 = extent.at(1);
  annotationString.append(QString::number(extent1.x())).append(",");
  annotationString.append(QString::number(extent1.y())).append(",");
  annotationString.append(QString::number(extent2.x())).append(",");
  annotationString.append(QString::number(extent2.y())).append(",");
  // add rotation
  annotationString.append(QString::number(mTransformation.getRotateAngle()));
  mTransformation = oldTransformation;
  return annotationString;
}

/*!
 * \brief Element::getOMCPlacementAnnotation
 * Returns the Element placement annotation in OMC format.
 * \param position
 * \return
 */
QString Element::getOMCPlacementAnnotation(QPointF position)
{
  // create the placement annotation string
  QString placementAnnotationString = "Placement(";
  if (mTransformation.isValid()) {
    placementAnnotationString.append(mTransformation.getVisible() ? "true" : "false");
  }
  if ((mpLibraryTreeItem && mpLibraryTreeItem->isConnector()) || (mpGraphicsView->getModelWidget()->isNewApi() && mpModel && mpModelComponent->getModel()->isConnector())) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      // first get the component from diagram view and get the transformations
      Element *pElement;
      pElement = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getElementObject(getName());
      if (pElement) {
        placementAnnotationString.append(",").append(pElement->getOMCTransformationAnnotation(position));
      } else {
        placementAnnotationString.append(",-,-,-,-,-,-,-");
      }
      // then get the icon transformations
      placementAnnotationString.append(",").append(getOMCTransformationAnnotation(position));
    } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
      // first get the component from diagram view and get the transformations
      placementAnnotationString.append(",").append(getOMCTransformationAnnotation(position));
      // then get the icon transformations
      Element *pElement;
      pElement = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getElementObject(getName());
      if (pElement) {
        placementAnnotationString.append(",").append(pElement->getOMCTransformationAnnotation(position));
      } else {
        placementAnnotationString.append(",-,-,-,-,-,-,");
      }
    }
  } else {
    placementAnnotationString.append(",").append(getOMCTransformationAnnotation(position));
    placementAnnotationString.append(",-,-,-,-,-,-,");
  }
  placementAnnotationString.append(")");
  return placementAnnotationString;
}

QString Element::getTransformationOrigin()
{
  // add the icon origin
  QString transformationOrigin;
  transformationOrigin.append("{").append(QString::number(mTransformation.getOrigin().x())).append(",").append(QString::number(mTransformation.getOrigin().y())).append("}");
  return transformationOrigin;
}

QString Element::getTransformationExtent()
{
  QString transformationExtent;
  // add extent points
  ExtentAnnotation extent = mTransformation.getExtent();
  QPointF extent1 = extent.at(0);
  QPointF extent2 = extent.at(1);
  transformationExtent.append("{").append(QString::number(extent1.x()));
  transformationExtent.append(",").append(QString::number(extent1.y())).append(",");
  transformationExtent.append(QString::number(extent2.x())).append(",");
  transformationExtent.append(QString::number(extent2.y())).append("}");
  return transformationExtent;
}

/*!
 * \brief Element::isExpandableConnector
 * Returns true if the Element class is expandable connector.
 * \return
 */
bool Element::isExpandableConnector() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return (mpModel && mpModel->isExpandableConnector());
  } else {
    return (mpLibraryTreeItem && mpLibraryTreeItem->getRestriction() == StringHandler::ExpandableConnector);
  }
}

/*!
 * \brief Element::isArray
 * Returns true if the Element is an array.
 * \return
 */
bool Element::isArray() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModelComponent->getDimensions().isArray();
  } else {
    return (mpElementInfo && mpElementInfo->isArray());
  }
}

/*!
 * \brief Element::getAbsynArrayIndexes
 * Returns the absyn array indexes.
 * \return
 */
QStringList Element::getAbsynArrayIndexes() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModelComponent->getDimensions().getAbsynDimensions();
  } else if (mpElementInfo) {
    return QStringList() << mpElementInfo->getArrayIndex();
  } else {
    return QStringList();
  }
}

/*!
 * \brief Element::getTypedArrayIndexes
 * Returns the typed array indexes.
 * \return
 */
QStringList Element::getTypedArrayIndexes() const
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    return mpModelComponent->getDimensions().getTypedDimensions();
  } else if (mpElementInfo) {
    return QStringList() << mpElementInfo->getArrayIndex();
  } else {
    return QStringList();
  }
}

int Element::getArrayIndexAsNumber(bool *ok) const
{
  if (isArray()) {
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      QStringList arrayIndexes = getTypedArrayIndexes();
      if (!arrayIndexes.isEmpty()) {
        return arrayIndexes.at(0).toInt(ok);
      } else {
        return 0;
      }
    } else {
      return mpElementInfo->getArrayIndexAsNumber(ok);
    }
  } else {
    if (ok) *ok = false;
    return 0;
  }
}

/*!
 * \brief Element::isConnectorSizing
 * Returns true if connectorSizing.
 * \return
 */
bool Element::isConnectorSizing()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    if (isArray()) {
      // connectorSizing is only done on the single dimensional array.
      QString parameter = mpModelComponent->getDimensions().getAbsynDimensions().at(0);
      bool ok;
      parameter.toInt(&ok);
      // if the array index is not a number then look for parameter
      if (!ok) {
        return isParameterConnectorSizing(parameter);
      }
    }
  } else {
    if (mpElementInfo && mpElementInfo->isArray()) {
      QString parameter = mpElementInfo->getArrayIndex();
      bool ok;
      parameter.toInt(&ok);
      // if the array index is not a number then look for parameter
      if (!ok) {
        return Element::isParameterConnectorSizing(getRootParentElement(), parameter);
      }
    }
  }
  return false;
}

/*!
 * \brief Element::isParameterConnectorSizing
 * Checks if the parameter is connectorSizing.
 * \param parameter
 * \return
 */
bool Element::isParameterConnectorSizing(const QString &parameter)
{
  // First we look in the element's containing class elements i.e the neighbouring elements.
  if (mpGraphicsView->getModelWidget()->getModelInstance()->isParameterConnectorSizing(parameter)) {
    return true;
  }
  // Look in the elements of the element class
  return Element::isParameterConnectorSizing(getRootParentElement()->getModel(), parameter);
}

/*!
 * \brief Element::isParameterConnectorSizing
 * Checks if the parameter is connectorSizing.
 * \param pModel
 * \param parameter
 * \return
 */
bool Element::isParameterConnectorSizing(ModelInstance::Model *pModel, QString parameter)
{
  bool result = false;
  if (pModel) {
    if (pModel->isParameterConnectorSizing(parameter)) {
      return true;
    }
    // Look in class inheritance
    QList<ModelInstance::Element*> elements = pModel->getElements();
    foreach (auto pElement, elements) {
      if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
        result = Element::isParameterConnectorSizing(pExtend->getModel(), parameter);
        if (result) {
          return result;
        }
      }
    }
  }
  return result;
}

bool Element::isParameterConnectorSizing(Element *pElement, QString parameter)
{
  bool result = false;
  // Look in class elements
  foreach (Element *pClassElement, pElement->getElementsList()) {
    if (pClassElement->getElementInfo() && pClassElement->getName().compare(parameter) == 0) {
      return (pClassElement->getDialogAnnotation().size() > 10) && (pClassElement->getDialogAnnotation().at(10).compare("true") == 0);
    }
  }
  // Look in class inherited elements
  foreach (Element *pInheritedElement, pElement->getInheritedElementsList()) {
    /* Since we use the parent ElementInfo for inherited classes so we should not use
     * pInheritedElement->getElementInfo()->getClassName() to get the name instead we should use
     * pInheritedElement->getLibraryTreeItem()->getNameStructure() to get the correct name of inherited class.
     */
    if (pInheritedElement->getLibraryTreeItem() && pInheritedElement->getLibraryTreeItem()->getName().compare(parameter) == 0) {
      return (pInheritedElement->getDialogAnnotation().size() > 10) && (pInheritedElement->getDialogAnnotation().at(10).compare("true") == 0);
    }
    result = Element::isParameterConnectorSizing(pInheritedElement, parameter);
  }
  return result;
}

/*!
 * \brief Element::createClassElements
 * Creates a class components.
 */
void Element::createClassElements()
{
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    pInheritedElement->createClassElements();
  }

  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    QList<ModelInstance::Element*> elements = mpModel->getElements();
    foreach (auto pElement, elements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<ModelInstance::Component*>(pElement);
        if (pComponent->isPublic() && pComponent->getModel() && pComponent->getModel()->isConnector()) {
          mElementsList.append(new Element(pComponent, this, getRootParentElement()));
        }
      }
    }
  } else {
    if (!mpLibraryTreeItem->isNonExisting()) {
      if (!mpLibraryTreeItem->getModelWidget()) {
        MainWindow *pMainWindow = MainWindow::instance();
        pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
      }
      mpLibraryTreeItem->getModelWidget()->loadElements();
      foreach (Element *pElement, mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getElementsList()) {
        mElementsList.append(new Element(pElement, this, getRootParentElement()));
      }
      mpLibraryTreeItem->getModelWidget()->loadDiagramView();
      foreach (Element *pElement, mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getElementsList()) {
        if (pElement->getLibraryTreeItem() && pElement->getLibraryTreeItem()->isConnector()) {
          continue;
        }
        Element *pNewElement = new Element(pElement, this, getRootParentElement());
        // Set the Parent Item to 0 beacause we don't want to render Diagram components. We just want to store them for Parameters Dialog.
        pNewElement->setParentItem(0);
        mElementsList.append(pNewElement);
      }
    }
  }
}

void Element::applyRotation(qreal angle)
{
  Transformation oldTransformation = mTransformation;
  if (angle == 360) {
    angle = 0;
  }
  mTransformation.setRotateAngle(angle);
  updateElementTransformations(oldTransformation, false);
}

/*!
 * \brief Element::addConnectionDetails
 * Adds the link with connection.
 * \param pConnectorLineAnnotation
 */
void Element::addConnectionDetails(LineAnnotation *pConnectorLineAnnotation)
{
  // handle component position, rotation and scale changes
  connect(this, SIGNAL(transformChange(bool)), pConnectorLineAnnotation, SLOT(handleComponentMoved(bool)), Qt::UniqueConnection);
  if (!pConnectorLineAnnotation->isInheritedShape()) {
    connect(this, SIGNAL(transformChanging()), pConnectorLineAnnotation, SLOT(updateConnectionTransformation()), Qt::UniqueConnection);
  }
}

/*!
 * \brief Element::removeConnectionDetails
 * Removes the link with connection.
 * \param pConnectorLineAnnotation
 */
void Element::removeConnectionDetails(LineAnnotation *pConnectorLineAnnotation)
{
  disconnect(this, SIGNAL(transformChange(bool)), pConnectorLineAnnotation, SLOT(handleComponentMoved(bool)));
  if (!pConnectorLineAnnotation->isInheritedShape()) {
    disconnect(this, SIGNAL(transformChanging()), pConnectorLineAnnotation, SLOT(updateConnectionTransformation()));
  }
}

/*!
 * \brief Element::setHasTransition
 * \param hasTransition
 */
void Element::setHasTransition(bool hasTransition)
{
  if (hasTransition) {
    mHasTransition = true;
    update();
  } else {
    foreach (LineAnnotation *pTransitionLineAnnotation, mpGraphicsView->getTransitionsList()) {
      Element *pStartElement = pTransitionLineAnnotation->getStartElement();
      Element *pEndElement = pTransitionLineAnnotation->getEndElement();
      if (pStartElement->getRootParentElement() == this || pEndElement->getRootParentElement() == this) {
        mHasTransition = true;
        update();
        return;
      }
    }
    mHasTransition = false;
    update();
  }
}

/*!
 * \brief Element::setIsInitialState
 * \param isInitialState
 */
void Element::setIsInitialState(bool isInitialState)
{
  if (isInitialState) {
    mIsInitialState = true;
    update();
  } else {
    foreach (LineAnnotation *pInitialStateLineAnnotation, mpGraphicsView->getInitialStatesList()) {
      Element *pStartElement = pInitialStateLineAnnotation->getStartElement();
      if (pStartElement->getRootParentElement() == this) {
        mIsInitialState = true;
        update();
        return;
      }
    }
    mIsInitialState = false;
    update();
  }
}

/*!
 * \brief Element::removeChildren
 * Removes the complete hirerchy of the Element.
 */
void Element::removeChildren()
{
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    pInheritedElement->removeChildren();
    pInheritedElement->setParentItem(0);
    delete pInheritedElement;
  }
  mInheritedElementsList.clear();
  foreach (Element *pElement, mElementsList) {
    pElement->removeChildren();
    pElement->setParentItem(0);
    delete pElement;
  }
  mElementsList.clear();
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    pShapeAnnotation->setParentItem(0);
    delete pShapeAnnotation;
  }
  mShapesList.clear();
}

/*!
 * \brief Element::removeChildrenNew
 * Removes the complete hirerchy of the Element.
 */
void Element::removeChildrenNew()
{
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    pInheritedElement->removeChildrenNew();
    delete pInheritedElement;
  }
  mInheritedElementsList.clear();
  foreach (Element *pElement, mElementsList) {
    pElement->removeChildrenNew();
    delete pElement;
  }
  mElementsList.clear();
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    delete pShapeAnnotation;
  }
  mShapesList.clear();
}

void Element::reDrawElementNew()
{
  removeChildrenNew();
  mpModel = mpModelComponent->getModel();
  mName = mpModelComponent->getName();
  mClassName = mpModelComponent->getType();
  // delete if state element and then check if we need to create a state element
  if (mpStateElementRectangle) {
    delete mpStateElementRectangle;
  }
  createStateElement();
  drawElement();
  prepareGeometryChange();
  mTransformation.parseTransformation(mpModelComponent->getAnnotation()->getPlacementAnnotation(), getCoOrdinateSystemNew());
  setTransform(mTransformation.getTransformationMatrix());
  updateConnections();
  updateToolTip();
}

void Element::emitAdded()
{
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(coOrdinateSystemUpdatedForComponent()), SLOT(handleCoOrdinateSystemUpdated()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleElementAdded()));
    connect(mpLibraryTreeItem, SIGNAL(nameChanged()), SLOT(handleNameChanged()));
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit added();
}

void Element::emitTransformHasChanged()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit transformHasChanged();
}

void Element::emitChanged()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit changed();
}

void Element::emitDeleted()
{
  if (mpLibraryTreeItem) {
    disconnect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), this, SLOT(handleLoaded()));
    disconnect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), this, SLOT(handleUnloaded()));
    disconnect(mpLibraryTreeItem, SIGNAL(coOrdinateSystemUpdatedForComponent()), this, SLOT(handleCoOrdinateSystemUpdated()));
    disconnect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), this, SLOT(handleShapeAdded()));
    disconnect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), this, SLOT(handleElementAdded()));
    disconnect(mpLibraryTreeItem, SIGNAL(nameChanged()), this, SLOT(handleNameChanged()));
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit deleted();
}

void Element::componentParameterHasChanged()
{
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Element::getParameterDisplayString
 * Reads the parameters of the component.\n
 * Returns the parameter string which can be either R=%R or %R.
 * \param parameterString - the parameter string to look for.
 * \return the parameter string with value.
 */
QString Element::getParameterDisplayString(QString parameterName)
{
  /* How to get the display value,
   * 0. If the component is inherited component then check if the value is available in the class extends modifiers.
   * 1. Check if the value is available in component modifier.
   * 2 Check if the value is available in the component's class as a parameter or variable.
   * 3. Find the value in extends classes and check if the value is present in extends modifier.
   * 4. If there is no extends modifier then finally check if value is present in extends classes.
   */
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  QString displayString = "";
  QString typeName = "";
  /* Ticket #4095
   * Handle parameters display of inherited components.
   */
  /* case 0 */
  if (isInheritedElement()) {
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      displayString = mpModel->getParameterValueFromExtendsModifiers(parameterName);
    } else if (mpReferenceElement) {
      QString extendsClass = mpReferenceElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
      displayString = mpGraphicsView->getModelWidget()->getExtendsModifiersMap(extendsClass).value(QString("%1.%2").arg(getName()).arg(parameterName), "");
    }
  }
  /* case 1 */
  if (displayString.isEmpty()) {
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      if (mpModelComponent->getModifier()) {
        displayString = mpModelComponent->getModifier()->getModifierValue(QStringList() << parameterName);
      }
    } else {
      displayString = mpElementInfo->getModifiersMap(pOMCProxy, className, this).value(parameterName, "");
    }
  }
  /* case 2 or check for enumeration type if case 1 */
  if (displayString.isEmpty() || typeName.isEmpty()) {
    if (mpGraphicsView->getModelWidget()->isNewApi()) {
      QString value = mpModel->getParameterValue(parameterName, typeName);
      if (displayString.isEmpty()) {
        displayString = value;
      }
      Element::checkEnumerationDisplayString(displayString, typeName);
    } else if (mpLibraryTreeItem) {
      mpLibraryTreeItem->getModelWidget()->loadDiagramView();
      foreach (Element *pElement, mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getElementsList()) {
        if (pElement->getElementInfo()->getName().compare(StringHandler::getFirstWordBeforeDot(parameterName)) == 0) {
          if (displayString.isEmpty()) {
            displayString = pElement->getElementInfo()->getParameterValue(pOMCProxy, mpLibraryTreeItem->getNameStructure());
          }
          // Fixes issue #7493. Handles the case where value is from instance name e.g., %instanceName.parameterName
          if (displayString.isEmpty()) {
            displayString = pOMCProxy->getParameterValue(pElement->getElementInfo()->getClassName(), StringHandler::getLastWordAfterDot(parameterName));
          }

          typeName = pElement->getElementInfo()->getClassName();
          Element::checkEnumerationDisplayString(displayString, typeName);
          break;
        }
      }
    }
  }
  /* case 3 */
  if (displayString.isEmpty()) {
    displayString = getParameterDisplayStringFromExtendsModifiers(parameterName);
  }
  /* case 4 or check for enumeration type if case 3 */
  if (displayString.isEmpty() || typeName.isEmpty()) {
    displayString = getParameterDisplayStringFromExtendsParameters(parameterName, displayString);
  }
  return displayString;
}

/*!
 * \brief Element::getParameterModifierValue
 * Reads the component parameter modifier value.
 * \param parameterName
 * \param modifier
 * \return
 */
QString Element::getParameterModifierValue(const QString &parameterName, const QString &modifier)
{
  /* How to get the parameter modifier value,
   * 1. Check if the value is available in component modifier.
   */
  QString modifierValue = "";
  /* case 1 */
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    modifierValue = mpModelComponent->getModifierValueFromType(QStringList() << parameterName << modifier);
  } else {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    QString className = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    QString parameterAndModiferName = QString("%1.%2").arg(parameterName).arg(modifier);
    QMap<QString, QString> modifiers = mpElementInfo->getModifiersMap(pOMCProxy, className, this);
    QMap<QString, QString>::iterator modifiersIterator;
    for (modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
      if (parameterAndModiferName.compare(modifiersIterator.key()) == 0) {
        modifierValue = modifiersIterator.value();
        break;
      }
    }
  }
  return StringHandler::removeFirstLastQuotes(modifierValue);
}

/*!
 * \brief Element::getDerivedClassModifierValue
 * Used to fetch the values of unit and displayUnit.
 * \param modifierName
 * \return
 */
QString Element::getDerivedClassModifierValue(QString modifierName)
{
  /* Get unit value
   * First check if unit is defined with in the component modifier.
   * If no unit is found then check it in the derived class modifier value.
   * A derived class can be inherited, so look recursively.
   */
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className;
  if (mpReferenceElement) {
    className = mpReferenceElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  } else {
    className = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  }
  QString modifierValue = mpElementInfo->getModifiersMap(pOMCProxy, className, this).value(modifierName);
  if (modifierValue.isEmpty()) {
    if (!pOMCProxy->isBuiltinType(mpElementInfo->getClassName())) {
      if (mpLibraryTreeItem) {
        if (!mpLibraryTreeItem->getModelWidget()) {
          MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
        }
        modifierValue = mpLibraryTreeItem->getModelWidget()->getDerivedClassModifiersMap().value(modifierName);
      }
      if (modifierValue.isEmpty()) {
        modifierValue = getInheritedDerivedClassModifierValue(this, modifierName);
      }
    }
  }
  return StringHandler::removeFirstLastQuotes(modifierValue);
}

/*!
 * \brief Element::getInheritedDerivedClassModifierValue
 * Helper function for Element::getDerivedClassModifierValue()
 * \param pElement
 * \param modifierName
 * \return
 */
QString Element::getInheritedDerivedClassModifierValue(Element *pElement, QString modifierName)
{
  MainWindow *pMainWindow = MainWindow::instance();
  OMCProxy *pOMCProxy = pMainWindow->getOMCProxy();
  QString modifierValue = "";
  if (!pElement->getLibraryTreeItem()->getModelWidget()) {
    pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pElement->getLibraryTreeItem(), false);
  }
  foreach (Element *pInheritedElement, pElement->getInheritedElementsList()) {
    /* Ticket #4031
     * Since we use the parent ElementInfo for inherited classes so we should not use
     * pInheritedElement->getElementInfo()->getClassName() to get the name instead we should use
     * pInheritedElement->getLibraryTreeItem()->getNameStructure() to get the correct name of inherited class.
     * Also don't just return after reading from first inherited class. Check recursively.
     */
    if (!pOMCProxy->isBuiltinType(pInheritedElement->getLibraryTreeItem()->getNameStructure())) {
      if (pInheritedElement->getLibraryTreeItem()) {
        if (!pInheritedElement->getLibraryTreeItem()->getModelWidget()) {
          pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedElement->getLibraryTreeItem(), false);
        }
        modifierValue = pInheritedElement->getLibraryTreeItem()->getModelWidget()->getDerivedClassModifiersMap().value(modifierName);
      }
      if (modifierValue.isEmpty()) {
        modifierValue = getInheritedDerivedClassModifierValue(pInheritedElement, modifierName);
      }
      if (!modifierValue.isEmpty()) {
        return StringHandler::removeFirstLastQuotes(modifierValue);
      }
    }
  }
  return "";
}

/*!
 * \brief Element::shapeAdded
 * Called when a reference shape is added in its actual class.
 */
void Element::shapeAdded()
{
  deleteNonExistingElement();
  if (mElementType == Element::Root) {
    deleteDefaultElement();
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Element::shapeUpdated
 * Called when a reference shape is updated in its actual class.
 */
void Element::shapeUpdated()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Element::shapeDeleted
 * Called when a reference shape is deleted in its actual class.
 */
void Element::shapeDeleted()
{
  deleteNonExistingElement();
  if (mElementType == Element::Root) {
    deleteDefaultElement();
  }
  showNonExistingOrDefaultElementIfNeeded();
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Element::renameComponentInConnections
 * Called when OMCProxy::renameElementInClass() is used. Updates the components name in connections list.\n
 * So that next OMCProxy::updateConnection() uses the new name. Ticket #3683.
 * \param newName
 */
void Element::renameComponentInConnections(QString newName)
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    return;
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
    // update start component name
    Element *pStartElement = pConnectionLineAnnotation->getStartElement();
    if (pStartElement->getRootParentElement() == this) {
      QString startElementName = pConnectionLineAnnotation->getStartElementName();
      startElementName.replace(getName(), newName);
      pConnectionLineAnnotation->setStartElementName(startElementName);
      pConnectionLineAnnotation->updateToolTip();
    }
    // update end component name
    Element *pEndElement = pConnectionLineAnnotation->getEndElement();
    if (pEndElement->getRootParentElement() == this) {
      QString endElementName = pConnectionLineAnnotation->getEndElementName();
      endElementName.replace(getName(), newName);
      pConnectionLineAnnotation->setEndElementName(endElementName);
      pConnectionLineAnnotation->updateToolTip();
    }
  }
}

/*!
 * \brief Element::insertInterfacePoint
 * Inserts a new interface point.
 * \param interfaceName
 */
void Element::insertInterfacePoint(QString interfaceName, QString position, QString angle321, int dimensions, QString causality, QString domain)
{
  ElementInfo *pElementInfo = new ElementInfo;
  pElementInfo->setName(interfaceName);
  pElementInfo->setPosition(position);
  pElementInfo->setAngle321(angle321);
  pElementInfo->setDimensions(dimensions);
  pElementInfo->setTLMCausality(causality);
  pElementInfo->setDomain(domain);
  mElementsList.append(new Element(pElementInfo, this));
  adjustInterfacePoints();
}

void Element::removeInterfacePoint(QString interfaceName)
{
  foreach (Element *pElement, mElementsList) {
    if (pElement->getName().compare(interfaceName) == 0) {
      mElementsList.removeOne(pElement);
      pElement->deleteLater();
      break;
    }
  }
  adjustInterfacePoints();
}

/*!
 * \brief Element::adjustInterfacePoints
 * Dynamically adjusts the size of interface points.
 */
void Element::adjustInterfacePoints()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    if (!mElementsList.isEmpty()) {
      // we start with default size of 30
      int interfacePointSize = 30;
      // keep the separator size to 1/3.
      int interfacePointSeparatorSize = (interfacePointSize / 3);
      // 200 is the maximum height of submodel
      while (200 <= mElementsList.size() * (interfacePointSize + interfacePointSeparatorSize)) {
        interfacePointSize -= 1;
        if (interfacePointSize <= 0) {
          interfacePointSize = 1;
          break;
        }
        interfacePointSeparatorSize = (interfacePointSize / 3);
      }
      // set the new transformation for each interface point.
      qreal yPosition = 100 - (interfacePointSize / 2);
      foreach (Element *pElement, mElementsList) {
        qreal xPosition = 100 + interfacePointSeparatorSize;
        QString transformation = QString("Placement(true,%1,%2,-%3,-%3,%3,%3,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)").arg(xPosition).arg(yPosition)
            .arg(interfacePointSize / 2);
        yPosition -= (interfacePointSize + interfacePointSeparatorSize);
        pElement->mTransformation.parseTransformationString(transformation, boundingRect().width(), boundingRect().height());
        pElement->setTransform(pElement->mTransformation.getTransformationMatrix());
      }
    }
  }
}

/*!
 * \brief Element::updateElementTransformations
 * Creates a UpdateElementTransformationsCommand and emits the Element::transformChanging() SIGNAL.
 * \param oldTransformation
 * \param positionChanged
 */
void Element::updateElementTransformations(const Transformation &oldTransformation, const bool positionChanged)
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    resetTransform();
    bool state = flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
    setPos(0, 0);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);
    setTransform(mTransformation.getTransformationMatrix());
    emit transformChange(positionChanged);
    emit transformHasChanged();
    emit transformChanging();
  } else {
    mpGraphicsView->getModelWidget()->beginMacro(QStringLiteral("Update element transformations"));
    const bool moveConnectorsTogether = OptionsDialog::instance()->getGraphicalViewsPage()->getMoveConnectorsTogetherCheckBox()->isChecked();
    mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateComponentTransformationsCommand(this, oldTransformation, mTransformation, positionChanged, moveConnectorsTogether));
    emit transformChanging();
    mpGraphicsView->getModelWidget()->endMacro();
  }
}

/*!
 * \brief Element::handleOMSElementDoubleClick
 * Handles the mouse double click for OMS element.
 */
void Element::handleOMSElementDoubleClick()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSBusConnector()) {
    AddBusDialog *pAddBusDialog = new AddBusDialog(QList<Element*>(), mpLibraryTreeItem, mpGraphicsView);
    pAddBusDialog->exec();
  } else if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSTLMBusConnector()) {
    AddTLMBusDialog *pAddTLMBusDialog = new AddTLMBusDialog(QList<Element*>(), mpLibraryTreeItem, mpGraphicsView);
    pAddTLMBusDialog->exec();
  } else if (mpLibraryTreeItem && (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement())) {
    showElementPropertiesDialog();
  }
}

/*!
 * \brief Element::setBusComponent
 * Sets the bus component.
 * \param pBusElement
 */
void Element::setBusComponent(Element *pBusElement)
{
  mpBusComponent = pBusElement;
  setVisible(!isInBus());
}

/*!
 * \brief Element::getElementByName
 * Finds the element by name.
 * \param elementName
 * \return
 */
Element* Element::getElementByName(const QString &elementName)
{
  Element *pElementFound = 0;
  foreach (Element *pElement, getElementsList()) {
    if (pElement->getElementInfo() && pElement->getName().compare(elementName) == 0) {
      pElementFound = pElement;
      return pElementFound;
    }
  }
  /* if is not found in elements list then look into the inherited elements list. */
  foreach (Element *pInheritedElement, getInheritedElementsList()) {
    pElementFound = pInheritedElement->getElementByName(elementName);
    if (pElementFound) {
      return pElementFound;
    }
  }
  return pElementFound;
}

/*!
 * \brief Element::getModelComponentByName
 * Get the ModelInstance::Component by name.
 * \param name
 * \return
 */
ModelInstance::Component* Element::getModelComponentByName(ModelInstance::Model *pModel, const QString &name)
{
  ModelInstance::Component *pModelComponentFound = 0;
  if (pModel) {
    QList<ModelInstance::Element*> elements = pModel->getElements();
    foreach (auto pElement, elements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<ModelInstance::Component*>(pElement);
        if (pComponent->getName().compare(name) == 0) {
          pModelComponentFound = pComponent;
          return pModelComponentFound;
        }
      } else if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
        pModelComponentFound = Element::getModelComponentByName(pExtend->getModel(), name);
        if (pModelComponentFound) {
          return pModelComponentFound;
        }
      }
    }
  }
  return pModelComponentFound;
}

/*!
 * \brief Element::reDrawConnector
 * Redraws the connector that collides with the connection.
 * \param painter
 */
void Element::reDrawConnector(QPainter *painter)
{
  if (mpDefaultElementRectangle && mpDefaultElementRectangle->isVisible()) {
    painter->save();
    painter->setTransform(mpDefaultElementRectangle->sceneTransform(), true);
    mpDefaultElementRectangle->drawAnnotation(painter);
    painter->restore();
  }

  if (mpDefaultElementText && mpDefaultElementText->isVisible()) {
    painter->save();
    painter->setTransform(mpDefaultElementText->sceneTransform(), true);
    mpDefaultElementText->drawAnnotation(painter);
    painter->restore();
  }

  // Skip when condition is false
  if (!isCondition()) {
    return;
  }

  foreach (Element *pInheritedElement, mInheritedElementsList) {
    pInheritedElement->reDrawConnector(painter);
  }

  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    painter->save();
    painter->setTransform(pShapeAnnotation->sceneTransform(), true);
    pShapeAnnotation->drawAnnotation(painter);
    painter->restore();
  }

  foreach (Element *pElement, mElementsList) {
    pElement->reDrawConnector(painter);
  }
}

/*!
 * \brief Element::createNonExistingElement
 * Creates a non-existing element.
 */
void Element::createNonExistingElement()
{
  if (!mpNonExistingElementLine) {
    mpNonExistingElementLine = new LineAnnotation(this);
  }
}

/*!
 * \brief Element::deleteNonExistingElement
 * Delete the non-existing element.
 */
void Element::deleteNonExistingElement()
{
  if (mpNonExistingElementLine) {
    mpNonExistingElementLine->deleteLater();
    mpNonExistingElementLine = 0;
  }
}

/*!
 * \brief Element::createDefaultElement
 * Creates a default element.
 */
void Element::createDefaultElement()
{
  if (!mpDefaultElementRectangle) {
    mpDefaultElementRectangle = new RectangleAnnotation(this);
  }
  if (!mpDefaultElementText) {
    mpDefaultElementText = new TextAnnotation(this);
  }
}

/*!
 * \brief Element::deleteDefaultElement
 * Delete default element.
 */
void Element::deleteDefaultElement()
{
  if (mpDefaultElementRectangle) {
    mpDefaultElementRectangle->deleteLater();
    mpDefaultElementRectangle = 0;
  }

  if (mpDefaultElementText) {
    mpDefaultElementText->deleteLater();
    mpDefaultElementText = 0;
  }
}

/*!
 * \brief Element::createStateElement
 * Creates a state element.
 */
void Element::createStateElement()
{
  if ((mpGraphicsView->getModelWidget()->isNewApi() && mpModel && mpModel->getAnnotation()->isState())
      || (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica && !mpLibraryTreeItem->isNonExisting() && mpLibraryTreeItem->isState())) {
    mpStateElementRectangle = new RectangleAnnotation(this);
    mpStateElementRectangle->setVisible(false);
    // create a state rectangle
    mpStateElementRectangle->setLineColor(QColor(95, 95, 95));
    mpStateElementRectangle->setLinePattern(StringHandler::LineDash);
    mpStateElementRectangle->setRadius(40);
    mpStateElementRectangle->setFillColor(QColor(255, 255, 255));
    QVector<QPointF> extents;
    extents << QPointF(-100, -100) << QPointF(100, 100);
    mpStateElementRectangle->setExtents(extents);
  } else {
    mpStateElementRectangle = 0;
  }
}

/*!
 * \brief Element::drawInterfacePoints
 * Draws the interface points of the submodel component.
 */
void Element::drawInterfacePoints()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
  if (pCompositeModelEditor) {
    QDomNodeList subModels = pCompositeModelEditor->getSubModels();
    for (int i = 0; i < subModels.size(); i++) {
      QDomElement subModel = subModels.at(i).toElement();
      if (subModel.attribute("Name").compare(mpElementInfo->getName()) == 0) {
        QDomNodeList interfacePoints = subModel.elementsByTagName("InterfacePoint");
        for (int j = 0; j < interfacePoints.size(); j++) {
          QDomElement interfacePoint = interfacePoints.at(j).toElement();
          insertInterfacePoint(interfacePoint.attribute("Name"), interfacePoint.attribute("Position", "0,0,0"),
                               interfacePoint.attribute("Angle321", "0,0,0"), interfacePoint.attribute("Dimensions", "3").toInt(),
                               interfacePoint.attribute("Causality", StringHandler::getTLMCausality(StringHandler::TLMBidirectional)),
                               interfacePoint.attribute("Domain", StringHandler::getTLMDomain(StringHandler::Mechanical)));
        }
      }
    }
  }
}

/*!
 * \brief Element::drawElement
 * Draws the Element.
 */
void Element::drawElement()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    drawModelicaElement();
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    drawOMSElement();
  }
}

/*!
 * \brief Element::reDrawElement
 * Deletes the component childrens, removes it from the scene, redraws it and add its back to the scene.
 * If coOrdinateSystemUpdated then recalculate the transformation and apply it.
 * \param coOrdinateSystemUpdated
 */
void Element::reDrawElement(bool coOrdinateSystemUpdated)
{
  removeChildren();
  if (coOrdinateSystemUpdated) {
    mTransformation.parseTransformationString(mTransformationString, boundingRect().width(), boundingRect().height());
    if (mTransformationString.isEmpty()) {
      CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
      qreal initialScale = coOrdinateSystem.getInitialScale();
      QVector<QPointF> extent;
      extent.append(QPointF(initialScale * boundingRect().left(), initialScale * boundingRect().top()));
      extent.append(QPointF(initialScale * boundingRect().right(), initialScale * boundingRect().bottom()));
      mTransformation.setExtent(extent);
      mTransformation.setRotateAngle(0.0);
    }
    setTransform(mTransformation.getTransformationMatrix());
  }
  /* Ticket:5691
   * Seems like setParentItem(0) doesn't work well on items already added to the scene.
   * So here we remove the item, draw it and then add it back to the scene.
   */
  /*! @todo We should get rid of setParentItem(0).
   * Basically instead of creating an object of class Element we should store the non scene items in some other class.
   */
  mpGraphicsView->removeItem(this);
  drawElement();
  mpGraphicsView->addItem(this);
  emitChanged();
  updateConnections();
}

/*!
 * \brief Element::drawModelicaElement
 * Draws the Modelica component.
 */
void Element::drawModelicaElement()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    createClassInheritedElements();
    createClassShapes();
    createClassElements();
    showNonExistingOrDefaultElementIfNeeded();
  } else {
    if (!mpLibraryTreeItem) { // if built in type e.g Real, Boolean etc.
      if (mElementType == Element::Root) {
        createDefaultElement();
      }
    } else if (mpLibraryTreeItem->isNonExisting()) { // if class is non existing
      createNonExistingElement();
    } else {
      createClassInheritedElements();
      createClassShapes();
      createClassElements();
      showNonExistingOrDefaultElementIfNeeded();
    }
  }
}

/*!
 * \brief Element::drawOMSElement
 * Draws the OMSimulator component.
 */
void Element::drawOMSElement()
{
  if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
    if (!mpLibraryTreeItem->getModelWidget()) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
    }
    // draw shapes first
    createClassShapes();
    // draw connectors now
    foreach (Element *pElement, mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getElementsList()) {
      Element *pNewElement = new Element(pElement, this, getRootParentElement());
      mElementsList.append(pNewElement);
    }
  } else if (mpLibraryTreeItem->getOMSConnector()) { // if component is a signal i.e., input/output
    if (mpLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
      PolygonAnnotation *pInputPolygonAnnotation = new PolygonAnnotation(this);
      QVector<QPointF> points;
      points << QPointF(-100.0, 100.0) << QPointF(100.0, 0.0) << QPointF(-100.0, -100.0) << QPointF(-100.0, 100.0);
      pInputPolygonAnnotation->setPoints(points);
      pInputPolygonAnnotation->setFillPattern(StringHandler::FillSolid);
      switch (mpLibraryTreeItem->getOMSConnector()->type) {
        case oms_signal_type_integer:
        case oms_signal_type_enum:
          pInputPolygonAnnotation->setLineColor(QColor(255,127,0));
          pInputPolygonAnnotation->setFillColor(QColor(255,127,0));
          break;
        case oms_signal_type_boolean:
          pInputPolygonAnnotation->setLineColor(QColor(255,0,255));
          pInputPolygonAnnotation->setFillColor(QColor(255,0,255));
          break;
        case oms_signal_type_string:
          qDebug() << "Element::drawOMSElement oms_signal_type_string not implemented yet.";
          break;
        case oms_signal_type_bus:
          qDebug() << "Element::drawOMSElement oms_signal_type_bus not implemented yet.";
          break;
        case oms_signal_type_real:
        default:
          pInputPolygonAnnotation->setLineColor(QColor(0, 0, 127));
          pInputPolygonAnnotation->setFillColor(QColor(0, 0, 127));
          break;
      }
      mShapesList.append(pInputPolygonAnnotation);
    } else if (mpLibraryTreeItem->getOMSConnector()->causality == oms_causality_output) {
      PolygonAnnotation *pOutputPolygonAnnotation = new PolygonAnnotation(this);
      QVector<QPointF> points;
      points << QPointF(-100.0, 100.0) << QPointF(100.0, 0.0) << QPointF(-100.0, -100.0) << QPointF(-100.0, 100.0);
      pOutputPolygonAnnotation->setPoints(points);
      pOutputPolygonAnnotation->setFillPattern(StringHandler::FillSolid);
      switch (mpLibraryTreeItem->getOMSConnector()->type) {
        case oms_signal_type_integer:
        case oms_signal_type_enum:
          pOutputPolygonAnnotation->setLineColor(QColor(255, 127, 0));
          pOutputPolygonAnnotation->setFillColor(QColor(255, 255, 255));
          break;
        case oms_signal_type_boolean:
          pOutputPolygonAnnotation->setLineColor(QColor(255, 0, 255));
          pOutputPolygonAnnotation->setFillColor(QColor(255, 255, 255));
          break;
        case oms_signal_type_string:
          qDebug() << "Element::drawOMSElement oms_signal_type_string not implemented yet.";
          break;
        case oms_signal_type_bus:
          qDebug() << "Element::drawOMSElement oms_signal_type_bus not implemented yet.";
          break;
        case oms_signal_type_real:
        default:
          pOutputPolygonAnnotation->setLineColor(QColor(0, 0, 127));
          pOutputPolygonAnnotation->setFillColor(QColor(255, 255, 255));
          break;
      }
      mShapesList.append(pOutputPolygonAnnotation);
    }
  } else if (mpLibraryTreeItem->getOMSBusConnector()) { // if component is a bus
    RectangleAnnotation *pBusRectangleAnnotation = new RectangleAnnotation(this);
    QVector<QPointF> extents;
    extents << QPointF(-100, -100) << QPointF(100, 100);
    pBusRectangleAnnotation->setExtents(extents);
    pBusRectangleAnnotation->setLineColor(QColor(73, 151, 60));
    pBusRectangleAnnotation->setFillColor(QColor(73, 151, 60));
    pBusRectangleAnnotation->setFillPattern(StringHandler::FillSolid);
    mShapesList.append(pBusRectangleAnnotation);
  } else if (mpLibraryTreeItem->getOMSTLMBusConnector()) { // if component is a tlm bus
    RectangleAnnotation *pTLMBusRectangleAnnotation = new RectangleAnnotation(this);
    QVector<QPointF> extents;
    extents << QPointF(-100, -100) << QPointF(100, 100);
    pTLMBusRectangleAnnotation->setExtents(extents);
    switch (mpLibraryTreeItem->getOMSTLMBusConnector()->domain) {
      case oms_tlm_domain_input:
        pTLMBusRectangleAnnotation->setLineColor(QColor(0, 0, 127));
        pTLMBusRectangleAnnotation->setFillColor(QColor(0, 0, 127));
        break;
      case oms_tlm_domain_output:
        pTLMBusRectangleAnnotation->setLineColor(QColor(0, 0, 127));
        pTLMBusRectangleAnnotation->setFillColor(QColor(255, 255, 255));
        break;
      case oms_tlm_domain_rotational:
        pTLMBusRectangleAnnotation->setLineColor(QColor(100, 255, 255));
        pTLMBusRectangleAnnotation->setFillColor(QColor(100, 255, 255));
        break;
      case oms_tlm_domain_hydraulic:
        pTLMBusRectangleAnnotation->setLineColor(QColor(100, 255, 100));
        pTLMBusRectangleAnnotation->setFillColor(QColor(100, 255, 100));
        break;
      case oms_tlm_domain_electric:
        pTLMBusRectangleAnnotation->setLineColor(QColor(255, 255, 100));
        pTLMBusRectangleAnnotation->setFillColor(QColor(255, 255, 100));
        break;
      case oms_tlm_domain_mechanical:
      default:
        pTLMBusRectangleAnnotation->setLineColor(QColor(100, 100, 255));
        pTLMBusRectangleAnnotation->setFillColor(QColor(100, 100, 255));
        break;
    }
    pTLMBusRectangleAnnotation->setFillPattern(StringHandler::FillSolid);
    mShapesList.append(pTLMBusRectangleAnnotation);
  }
}

/*!
 * \brief Element::drawInheritedElementsAndShapes
 * Draws the inherited components and their shapes.
 */
void Element::drawInheritedElementsAndShapes()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    createClassInheritedElements();
    createClassShapes();
  } else {
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      if (!mpLibraryTreeItem) { // if built in type e.g Real, Boolean etc.
        if (mElementType == Element::Root) {
          createDefaultElement();
        }
      } else if (mpLibraryTreeItem->isNonExisting()) { // if class is non existing
        createNonExistingElement();
      } else {
        createClassInheritedElements();
        createClassShapes();
      }
    } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      if (mpReferenceElement) {
        foreach (ShapeAnnotation *pShapeAnnotation, mpReferenceElement->getShapesList()) {
          if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new PolygonAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new RectangleAnnotation(pShapeAnnotation, this));
          }
        }
      }
    }
  }
}

/*!
 * \brief Element::showNonExistingOrDefaultElementIfNeeded
 * Show non-existing or default Element if needed.
 */
void Element::showNonExistingOrDefaultElementIfNeeded()
{
  deleteNonExistingElement();
  deleteDefaultElement();

  if (!hasShapeAnnotation(this)) {
    if (hasNonExistingClass()) {
      createNonExistingElement();
    } else if (mElementType == Element::Root) {
      createDefaultElement();
    }
  }
}

/*!
 * \brief Element::createClassInheritedElements
 * Creates a class inherited components.
 */
void Element::createClassInheritedElements()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    QList<ModelInstance::Element*> elements = mpModel->getElements();
    foreach (auto pElement, elements) {
      if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
        mInheritedElementsList.append(new Element(pExtend->getModel(), this));
      }
    }
  } else {
    if (!mpLibraryTreeItem->isNonExisting()) {
      if (!mpLibraryTreeItem->getModelWidget()) {
        MainWindow *pMainWindow = MainWindow::instance();
        pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
      }
      foreach (LibraryTreeItem *pLibraryTreeItem, mpLibraryTreeItem->getModelWidget()->getInheritedClassesList()) {
        mInheritedElementsList.append(new Element(pLibraryTreeItem, this));
      }
    }
  }
}

/*!
 * \brief Element::createClassShapes
 * Creates a class shapes.
 */
void Element::createClassShapes()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    mpGraphicsView->getModelWidget()->addDependsOnModel(mpModel->getName());
    ModelInstance::Extend *pExtendModel = 0;
    if (mElementType == Element::Extend) {
      pExtendModel = mpModel->getParentExtend();
    }
    /* issue #9557
     * For connectors, the icon layer is used to represent a connector when it is shown in the icon layer of the enclosing model.
     * The diagram layer of the connector is used to represent it when shown in the diagram layer of the enclosing model.
     *
     * Always use the icon annotation when element type is port.
     */
    QList<ModelInstance::Shape*> shapes;
    // Always use the IconMap here. Only IconMap makes sense for drawing icons of Element.
    if (!(pExtendModel && !pExtendModel->getIconDiagramMapPrimitivesVisible(true))) {
      /* issue #12074
       * Use mpModelComponent->getModel()->isConnector() here instead of mpModel->isConnector()
       * So when called for extends we use the top level element restriction.
       * We use the same mpModelComponent for top level and extends elements. See Element constructor above for extends element type.
       */
      if (mpModelComponent->getModel()->isConnector() && mpGraphicsView->getViewType() == StringHandler::Diagram && canUseDiagramAnnotation()) {
        shapes = mpModel->getAnnotation()->getDiagramAnnotation()->getGraphics();
      } else {
        shapes = mpModel->getAnnotation()->getIconAnnotation()->getGraphics();
      }
    }

    foreach (auto shape, shapes) {
      if (ModelInstance::Line *pLine = dynamic_cast<ModelInstance::Line*>(shape)) {
        mShapesList.append(new LineAnnotation(pLine, this));
      } else if (ModelInstance::Polygon *pPolygon = dynamic_cast<ModelInstance::Polygon*>(shape)) {
        mShapesList.append(new PolygonAnnotation(pPolygon, this));
      } else if (ModelInstance::Rectangle *pRectangle = dynamic_cast<ModelInstance::Rectangle*>(shape)) {
        mShapesList.append(new RectangleAnnotation(pRectangle, this));
      } else if (ModelInstance::Ellipse *pEllipse = dynamic_cast<ModelInstance::Ellipse*>(shape)) {
        mShapesList.append(new EllipseAnnotation(pEllipse, this));
      } else if (ModelInstance::Text *pText = dynamic_cast<ModelInstance::Text*>(shape)) {
        mShapesList.append(new TextAnnotation(pText, this));
      } else if (ModelInstance::Bitmap *pBitmap = dynamic_cast<ModelInstance::Bitmap*>(shape)) {
        mShapesList.append(new BitmapAnnotation(pBitmap, mpModel->getSource().getFileName(), this));
      }
    }
  } else {
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
      if (!mpLibraryTreeItem->isNonExisting()) {
        if (!mpLibraryTreeItem->getModelWidget()) {
          MainWindow *pMainWindow = MainWindow::instance();
          pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
        }
        GraphicsView *pGraphicsView = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView();
        /* issue #9557
         * For connectors, the icon layer is used to represent a connector when it is shown in the icon layer of the enclosing model.
         * The diagram layer of the connector is used to represent it when shown in the diagram layer of the enclosing model.
         *
         * Always use the icon annotation when element type is port.
         */
        if (mpLibraryTreeItem->isConnector() && mpGraphicsView->getViewType() == StringHandler::Diagram && canUseDiagramAnnotation()) {
          mpLibraryTreeItem->getModelWidget()->loadDiagramView();
          pGraphicsView = mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
        }
        foreach (ShapeAnnotation *pShapeAnnotation, pGraphicsView->getShapesList()) {
          if (dynamic_cast<LineAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new LineAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new PolygonAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new RectangleAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<EllipseAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new EllipseAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new TextAnnotation(pShapeAnnotation, this));
          } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
            mShapesList.append(new BitmapAnnotation(pShapeAnnotation, this));
          }
        }
      }
    } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      foreach (ShapeAnnotation *pShapeAnnotation, mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getShapesList()) {
        if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
          mShapesList.append(new RectangleAnnotation(pShapeAnnotation, this));
        } else if (dynamic_cast<TextAnnotation*>(pShapeAnnotation)) {
          mShapesList.append(new TextAnnotation(pShapeAnnotation, this));
        } else if (dynamic_cast<BitmapAnnotation*>(pShapeAnnotation)) {
          mShapesList.append(new BitmapAnnotation(pShapeAnnotation, this));
        }
      }
    }
  }
}

void Element::createActions()
{
  // Parameters Action
  mpParametersAction = new QAction(Helper::parameters, mpGraphicsView);
  mpParametersAction->setStatusTip(tr("Shows the component parameters"));
  connect(mpParametersAction, SIGNAL(triggered()), SLOT(showParameters()));
  // Fetch interfaces action
  mpFetchInterfaceDataAction = new QAction(ResourceCache::getIcon(":/Resources/icons/interface-data.svg"), Helper::fetchInterfaceData, mpGraphicsView);
  mpFetchInterfaceDataAction->setStatusTip(tr("Fetch interface data for this external model"));
  connect(mpFetchInterfaceDataAction, SIGNAL(triggered()), SLOT(fetchInterfaceData()));
  // Todo: Connect /robbr
  // Attributes Action
  mpAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpAttributesAction->setStatusTip(tr("Shows the component attributes"));
  connect(mpAttributesAction, SIGNAL(triggered()), SLOT(showAttributes()));
  // Open Class Action
  mpOpenClassAction = new QAction(ResourceCache::getIcon(":/Resources/icons/model.svg"), Helper::openClass, mpGraphicsView);
  mpOpenClassAction->setStatusTip(Helper::openClassTip);
  connect(mpOpenClassAction, SIGNAL(triggered()), SLOT(openClass()));
  // SubModel attributes Action
  mpSubModelAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpSubModelAttributesAction->setStatusTip(tr("Shows the submodel attributes"));
  connect(mpSubModelAttributesAction, SIGNAL(triggered()), SLOT(showSubModelAttributes()));
  // FMU Properties Action
  mpElementPropertiesAction = new QAction(Helper::properties, mpGraphicsView);
  mpElementPropertiesAction->setStatusTip(tr("Shows the Properties dialog"));
  connect(mpElementPropertiesAction, SIGNAL(triggered()), SLOT(showElementPropertiesDialog()));
  // ReplaceSubModel Action
  mpReplaceSubModelAction = new QAction(ResourceCache::getIcon(":/Resources/icons/import-fmu.svg"), tr("Replace SubModel"), this);
  mpReplaceSubModelAction->setStatusTip(tr("Replaces the SubModel, but retains the connections and parameters if valid"));
  connect(mpReplaceSubModelAction, SIGNAL(triggered()), SLOT(showReplaceSubModelDialog()));
}

/*!
 * \brief Element::showReplaceSubModelDialog
 * Slot that opens up the ReplaceSubModelDialog Dialog from GraphicsView.
 */
void Element::showReplaceSubModelDialog()
{
  mpGraphicsView->showReplaceSubModelDialog(this->getName());
}

void Element::createResizerItems()
{
  bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary();
  bool isOMSConnector = (mpLibraryTreeItem
                         && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
                         && mpLibraryTreeItem->getOMSConnector());
  bool isOMSBusConnecor = (mpLibraryTreeItem
                           && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
                           && mpLibraryTreeItem->getOMSBusConnector());
  bool isOMSTLMBusConnecor = (mpLibraryTreeItem
                              && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
                              && mpLibraryTreeItem->getOMSTLMBusConnector());
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem = new ResizerItem(this);
  mpBottomLeftResizerItem->setPos(x1, y1);
  mpBottomLeftResizerItem->setResizePosition(ResizerItem::BottomLeft);
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeElement(ResizerItem*)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeElement(QPointF)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeElement()));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedElement()));
  mpBottomLeftResizerItem->blockSignals(isSystemLibrary || isInheritedElement() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Top left resizer
  mpTopLeftResizerItem = new ResizerItem(this);
  mpTopLeftResizerItem->setPos(x1, y2);
  mpTopLeftResizerItem->setResizePosition(ResizerItem::TopLeft);
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeElement(ResizerItem*)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeElement(QPointF)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeElement()));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedElement()));
  mpTopLeftResizerItem->blockSignals(isSystemLibrary || isInheritedElement() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Top Right resizer
  mpTopRightResizerItem = new ResizerItem(this);
  mpTopRightResizerItem->setPos(x2, y2);
  mpTopRightResizerItem->setResizePosition(ResizerItem::TopRight);
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeElement(ResizerItem*)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeElement(QPointF)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeElement()));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedElement()));
  mpTopRightResizerItem->blockSignals(isSystemLibrary || isInheritedElement() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Bottom Right resizer
  mpBottomRightResizerItem = new ResizerItem(this);
  mpBottomRightResizerItem->setPos(x2, y1);
  mpBottomRightResizerItem->setResizePosition(ResizerItem::BottomRight);
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeElement(ResizerItem*)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeElement(QPointF)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeElement()));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedElement()));
  mpBottomRightResizerItem->blockSignals(isSystemLibrary || isInheritedElement() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
}

void Element::getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2)
{
  qreal x11, y11, x22, y22;
  sceneBoundingRect().getCoords(&x11, &y11, &x22, &y22);
  if (x11 < x22)
  {
    *x1 = x11;
    *x2 = x22;
  }
  else
  {
    *x1 = x22;
    *x2 = x11;
  }
  if (y11 < y22)
  {
    *y1 = y11;
    *y2 = y22;
  }
  else
  {
    *y1 = y22;
    *y2 = y11;
  }
}

void Element::showResizerItems()
{
  // show the origin item
  mpOriginItem->setPos(mTransformation.getOrigin());
  mpOriginItem->setActive();
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem->setPos(x1, y1);
  mpBottomLeftResizerItem->setActive();
  //Top left resizer
  mpTopLeftResizerItem->setPos(x1, y2);
  mpTopLeftResizerItem->setActive();
  //Top Right resizer
  mpTopRightResizerItem->setPos(x2, y2);
  mpTopRightResizerItem->setActive();
  //Bottom Right resizer
  mpBottomRightResizerItem->setPos(x2, y1);
  mpBottomRightResizerItem->setActive();
}

void Element::hideResizerItems()
{
  mpOriginItem->setPassive();
  mpBottomLeftResizerItem->setPassive();
  mpTopLeftResizerItem->setPassive();
  mpTopRightResizerItem->setPassive();
  mpBottomRightResizerItem->setPassive();
}

void Element::getScale(qreal *sx, qreal *sy)
{
  qreal angle = mTransformation.getRotateAngle();
  if (transform().type() == QTransform::TxScale || transform().type() == QTransform::TxTranslate || transform().type() == QTransform::TxNone) {
    *sx = transform().m11() / (cos(angle * (M_PI / 180)));
    *sy = transform().m22() / (cos(angle * (M_PI / 180)));
  } else {
    *sx = transform().m12() / (sin(angle * (M_PI / 180)));
    *sy = -transform().m21() / (sin(angle * (M_PI / 180)));
  }
}

/*!
 * \brief Element::updateConnections
 * Updates the Element's connections.
 */
void Element::updateConnections()
{
  if ((!mpGraphicsView) || mpGraphicsView->getViewType() == StringHandler::Icon) {
    return;
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
    // get start and end components
    QStringList startElementList = pConnectionLineAnnotation->getStartElementName().split(".");
    QStringList endElementList = pConnectionLineAnnotation->getEndElementName().split(".");
    // set the start component
    if ((startElementList.size() > 1 && getName().compare(startElementList.at(0)) == 0)) {
      QString startElementName = startElementList.at(1);
      if (startElementName.contains("[")) {
        startElementName = startElementName.mid(0, startElementName.indexOf("["));
      }
      pConnectionLineAnnotation->setStartElement(mpGraphicsView->getModelWidget()->getConnectorElement(this, startElementName));
    }
    // set the end component
    if ((endElementList.size() > 1 && getName().compare(endElementList.at(0)) == 0)) {
      QString endElementName = endElementList.at(1);
      if (endElementName.contains("[")) {
        endElementName = endElementName.mid(0, endElementName.indexOf("["));
      }
      pConnectionLineAnnotation->setEndElement(mpGraphicsView->getModelWidget()->getConnectorElement(this, endElementName));
    }
  }
}

/*!
 * \brief Element::getParameterDisplayStringFromExtendsModifiers
 * Gets the display string for Element from extends modifiers
 * \param parameterName
 * \return
 */
QString Element::getParameterDisplayStringFromExtendsModifiers(QString parameterName)
{
  QString displayString = "";
  /* Ticket:4204
   * Get the extends modifiers of the class not the inherited class.
   */
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    displayString = mpModel->getParameterValueFromExtendsModifiers(parameterName);
  } else if (mpLibraryTreeItem) {
    foreach (Element *pElement, mInheritedElementsList) {
      if (pElement->getLibraryTreeItem()) {
        QMap<QString, QString> extendsModifiersMap = mpLibraryTreeItem->getModelWidget()->getExtendsModifiersMap(pElement->getLibraryTreeItem()->getNameStructure());
        displayString = extendsModifiersMap.value(parameterName, "");
        if (!displayString.isEmpty()) {
          return displayString;
        }
      }
      displayString = pElement->getParameterDisplayStringFromExtendsModifiers(parameterName);
      if (!displayString.isEmpty()) {
        return displayString;
      }
    }
  }
  return displayString;
}

/*!
 * \brief Element::getParameterDisplayStringFromExtendsParameters
 * Gets the display string for components from extends parameters.
 * \param parameterName
 * \param modifierString an existing extends modifier or an empty string
 * \return
 */
QString Element::getParameterDisplayStringFromExtendsParameters(QString parameterName, QString modifierString)
{
  QString displayString = modifierString;
  QString typeName = "";
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    displayString = Element::getParameterDisplayStringFromExtendsParameters(mpModel, parameterName, modifierString);
  } else {
    foreach (Element *pInheritedElement, mInheritedElementsList) {
      if (pInheritedElement->getLibraryTreeItem()) {
        if (!pInheritedElement->getLibraryTreeItem()->getModelWidget()) {
          MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedElement->getLibraryTreeItem(), false);
        }
        pInheritedElement->getLibraryTreeItem()->getModelWidget()->loadDiagramView();
        foreach (Element *pElement, pInheritedElement->getLibraryTreeItem()->getModelWidget()->getDiagramGraphicsView()->getElementsList()) {
          if (pElement->getElementInfo()->getName().compare(parameterName) == 0) {
            OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
            /* Ticket:4204
             * Look for the parameter value in the parameter containing class not in the parameter class.
             */
            if (pInheritedElement->getLibraryTreeItem()) {
              if (displayString.isEmpty()) {
                displayString = pElement->getElementInfo()->getParameterValue(pOMCProxy, pInheritedElement->getLibraryTreeItem()->getNameStructure());
              }
              typeName = pElement->getElementInfo()->getClassName();
              Element::checkEnumerationDisplayString(displayString, typeName);
              if (!(displayString.isEmpty() || typeName.isEmpty())) {
                return displayString;
              }
            }
          }
        }
      }
      displayString = pInheritedElement->getParameterDisplayStringFromExtendsParameters(parameterName, displayString);
      if (!(displayString.isEmpty() || typeName.isEmpty())) {
        return displayString;
      }
    }
  }
  return displayString;
}

/*!
 * \brief Element::getParameterDisplayStringFromExtendsParameters
 * Gets the display string for components from extends parameters.
 * \param pModel
 * \param parameterName
 * \param modifierString
 * \return
 */
QString Element::getParameterDisplayStringFromExtendsParameters(ModelInstance::Model *pModel, QString parameterName, QString modifierString)
{
  QString displayString = modifierString;
  QString typeName = "";

  QList<ModelInstance::Element*> elements = pModel->getElements();
  foreach (auto pElement, elements) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      QString value = pExtend->getModel()->getParameterValue(parameterName, typeName);
      if (displayString.isEmpty()) {
        displayString = value;
      }
      Element::checkEnumerationDisplayString(displayString, typeName);
      if (!(displayString.isEmpty() || typeName.isEmpty())) {
        return displayString;
      }
      displayString = Element::getParameterDisplayStringFromExtendsParameters(pExtend->getModel(), parameterName, displayString);
      if (!(displayString.isEmpty() || typeName.isEmpty())) {
        return displayString;
      }
    }
  }
  return displayString;
}

/*!
 * \brief Element::checkEnumerationDisplayString
 * Checks for enumeration type and shortens enumeration value.
 * Returns true if displayString was modified.
 * See ModelicaSpec 3.3, section 18.6.5.5, ticket:4084
 */
bool Element::checkEnumerationDisplayString(QString &displayString, const QString &typeName)
{
  if (displayString.startsWith(typeName + ".")) {
    displayString = displayString.right(displayString.length() - typeName.length() - 1);
    return true;
  }
  return false;
}

/*!
 * \brief Element::updateToolTip
 * Updates the Element's tooltip.
 */
void Element::updateToolTip()
{
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    QString comment = mpModelComponent->getComment();
    comment.replace("\\\"", "\"");
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    comment = pOMCProxy->makeDocumentationUriToFileName(comment);
    // since tooltips can't handle file:// scheme so we have to remove it in order to display images and make links work.
  #if defined(_WIN32)
    comment.replace("src=\"file:///", "src=\"");
  #else
    comment.replace("src=\"file://", "src=\"");
  #endif

    if ((mIsInheritedElement || mElementType == Element::Port) && mpParentElement && !mpGraphicsView->isVisualizationView()) {
      setToolTip(tr("<b>%1</b> %2<br/>%3<br /><br />Element declared in %4").arg(mpModel->getName())
                 .arg(mpModelComponent->getName()).arg(comment)
                 .arg(mpParentElement->getModel()->getName()));
    } else {
      setToolTip(tr("<b>%1</b> %2<br/>%3").arg(mpModel->getName()).arg(mpModelComponent->getName()).arg(comment));
    }
  } else {
    if (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
      setToolTip(mpLibraryTreeItem->getTooltip());
    } else {
      QString comment = mpElementInfo->getComment().replace("\\\"", "\"");
      OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
      comment = pOMCProxy->makeDocumentationUriToFileName(comment);
      // since tooltips can't handle file:// scheme so we have to remove it in order to display images and make links work.
    #if defined(_WIN32)
      comment.replace("src=\"file:///", "src=\"");
    #else
      comment.replace("src=\"file://", "src=\"");
    #endif

      if ((mIsInheritedElement || mElementType == Element::Port) && mpReferenceElement && !mpGraphicsView->isVisualizationView()) {
        setToolTip(tr("<b>%1</b> %2<br/>%3<br /><br />Element declared in %4").arg(mpElementInfo->getClassName())
                   .arg(mpElementInfo->getName()).arg(comment)
                   .arg(mpReferenceElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
      } else {
        setToolTip(tr("<b>%1</b> %2<br/>%3").arg(mpElementInfo->getClassName()).arg(mpElementInfo->getName()).arg(comment));
      }
    }
  }
}

/*!
 * \brief Element::canUseDiagramAnnotation
 * If the component is a port component or has a port component as parent in the hirerchy
 * then we should not use the diagram annotation.
 * \return
 */
bool Element::canUseDiagramAnnotation() const
{
  if (getElementType() == Element::Port)
    return false;

  Element *pElement = getParentElement();
  while (pElement) {
    if (pElement->getElementType() == Element::Port) {
      return false;
    }
    pElement = pElement->getParentElement();
  }

  return true;
}

void Element::updatePlacementAnnotation()
{
  // Add component annotation.
  LibraryTreeItem *pLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pLibraryTreeItem->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
    pCompositeModelEditor->updateSubModelPlacementAnnotation(mpElementInfo->getName(), mTransformation.getVisible()? "true" : "false",
                                                        getTransformationOrigin(), getTransformationExtent(),
                                                        QString::number(mTransformation.getRotateAngle()));
  } else if (pLibraryTreeItem->getLibraryType()== LibraryTreeItem::OMS) {
    if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSElement()) {
      ssd_element_geometry_t elementGeometry = mpLibraryTreeItem->getOMSElementGeometry();
      ExtentAnnotation extent = mTransformation.getExtent();
      QPointF extent1 = extent.at(0);
      QPointF extent2 = extent.at(1);
      extent1.setX(extent1.x() + mTransformation.getOrigin().x());
      extent1.setY(extent1.y() + mTransformation.getOrigin().y());
      extent2.setX(extent2.x() + mTransformation.getOrigin().x());
      extent2.setY(extent2.y() + mTransformation.getOrigin().y());
      elementGeometry.x1 = extent1.x();
      elementGeometry.y1 = extent1.y();
      elementGeometry.x2 = extent2.x();
      elementGeometry.y2 = extent2.y();
      elementGeometry.rotation = mTransformation.getRotateAngle();
      OMSProxy::instance()->setElementGeometry(mpLibraryTreeItem->getNameStructure(), &elementGeometry);
    } else if (mpLibraryTreeItem && (mpLibraryTreeItem->getOMSConnector()
                                     || mpLibraryTreeItem->getOMSBusConnector()
                                     || mpLibraryTreeItem->getOMSTLMBusConnector())) {
      ssd_connector_geometry_t connectorGeometry;
      connectorGeometry.x = Utilities::mapToCoOrdinateSystem(mTransformation.getOrigin().x(), -100, 100, 0, 1);
      connectorGeometry.y = Utilities::mapToCoOrdinateSystem(mTransformation.getOrigin().y(), -100, 100, 0, 1);
      if (mpLibraryTreeItem->getOMSConnector()) {
        OMSProxy::instance()->setConnectorGeometry(mpLibraryTreeItem->getNameStructure(), &connectorGeometry);
      } else if (mpLibraryTreeItem->getOMSBusConnector()) {
        OMSProxy::instance()->setBusGeometry(mpLibraryTreeItem->getNameStructure(), &connectorGeometry);
      } else if (mpLibraryTreeItem->getOMSTLMBusConnector()) {
        OMSProxy::instance()->setTLMBusGeometry(mpLibraryTreeItem->getNameStructure(), &connectorGeometry);
      }
      /* We have connector both on icon and diagram layer.
       * If one connector is updated then update the other connector automatically.
       */
      GraphicsView *pGraphicsView = 0;
      if (mpGraphicsView->getViewType() == StringHandler::Icon) {
        pGraphicsView = mpGraphicsView->getModelWidget()->getDiagramGraphicsView();
      } else {
        pGraphicsView = mpGraphicsView->getModelWidget()->getIconGraphicsView();
      }
      Element *pElement = pGraphicsView->getElementObject(getName());
      if (pElement) {
        pElement->mTransformation.setOrigin(mTransformation.getOrigin());
        pElement->setTransform(pElement->mTransformation.getTransformationMatrix());
        /* Disconnect the signal so we don't go into the recursion for updatePlacementAnnotation();
         * Connect again after emitting the signal.
         */
        disconnect(pElement, SIGNAL(transformHasChanged()), pElement, SLOT(updatePlacementAnnotation()));
        pElement->emitTransformHasChanged();
        connect(pElement, SIGNAL(transformHasChanged()), pElement, SLOT(updatePlacementAnnotation()));
      }
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
    }
  } else {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    pOMCProxy->setElementAnnotation(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure() % "." % getName(), "$Code((" % getPlacementAnnotation(true) % "))");
  }
  /* When something is changed in the icon layer then update the LibraryTreeItem in the Library Browser */
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Element::updateOriginItem
 * Slot that updates the position of the component OriginItem.
 */
void Element::updateOriginItem()
{
  mpOriginItem->setPos(mTransformation.getOrigin());
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem->setPos(x1, y1);
  //Top left resizer
  mpTopLeftResizerItem->setPos(x1, y2);
  //Top Right resizer
  mpTopRightResizerItem->setPos(x2, y2);
  //Bottom Right resizer
  mpBottomRightResizerItem->setPos(x2, y1);
}

/*!
 * \brief Element::handleLoaded
 * Slot activated when LibraryTreeItem::loaded() SIGNAL is raised.
 * Redraws the Element and updates its connections accordingly.
 */
void Element::handleLoaded()
{
  Element *pElement = getRootParentElement();
  pElement->reDrawElement();
}

/*!
 * \brief Element::handleUnloaded
 * Slot activated when LibraryTreeItem::unLoaded() SIGNAL is raised.
 * Removes the Element and updates its connections accordingly.
 */
void Element::handleUnloaded()
{
  removeChildren();
  showNonExistingOrDefaultElementIfNeeded();
  emitDeleted();
  Element *pElement = getRootParentElement();
  pElement->updateConnections();
}

/*!
 * \brief Element::handleCoOrdinateSystemUpdated
 * Slot activated when a coordinate system is updated in the Element's class and LibraryTreeItem::coOrdinateSystemUpdatedForElement() SIGNAL is raised.
 */
void Element::handleCoOrdinateSystemUpdated()
{
  Element *pElement = getRootParentElement();
  pElement->reDrawElement(true);
}

/*!
 * \brief Element::handleShapeAdded
 * Slot activated when a new shape is added to Element's class and LibraryTreeItem::shapeAddedForComponent() SIGNAL is raised.
 */
void Element::handleShapeAdded()
{
  Element *pElement = getRootParentElement();
  pElement->reDrawElement();
}

/*!
 * \brief Element::handleElementAdded
 * Slot activated when a new component is added to Element's class and LibraryTreeItem::componentAddedForComponent() SIGNAL is raised.
 */
void Element::handleElementAdded()
{
  Element *pElement = getRootParentElement();
  pElement->reDrawElement();
}

/*!
 * \brief Element::handleNameChanged
 * Handles the name change of OMSimulator elements.
 */
void Element::handleNameChanged()
{
  if (mpElementInfo) {
    // we should update connections associated with this component before updating the component name
    renameComponentInConnections(mpLibraryTreeItem->getName());
    mpElementInfo->setName(mpLibraryTreeItem->getName());
    mpElementInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  }
  updateToolTip();
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Element::referenceElementAdded
 * Adds the referenced components when reference component is added.
 */
void Element::referenceElementAdded()
{
  if (mElementType == Element::Port) {
    setVisible(true);
    if (mpReferenceElement && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpBusComponent = mpReferenceElement->getBusComponent();
    }
  } else {
    mpGraphicsView->addItem(this);
    mpGraphicsView->addItem(mpOriginItem);
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  } else if (!isInBus() && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
      // if start connector moved out of bus
      if (pConnectionLineAnnotation->getStartElementName().compare(mpLibraryTreeItem->getNameStructure()) == 0) {
        pConnectionLineAnnotation->setStartElement(this);
        pConnectionLineAnnotation->updateStartPoint(mapToScene(boundingRect().center()));
        pConnectionLineAnnotation->setVisible(true);
      }
      // if end connector moved out of bus
      if (pConnectionLineAnnotation->getEndElementName().compare(mpLibraryTreeItem->getNameStructure()) == 0) {
        pConnectionLineAnnotation->setEndElement(this);
        pConnectionLineAnnotation->updateEndPoint(mapToScene(boundingRect().center()));
        pConnectionLineAnnotation->setVisible(true);
      }
    }
  }
}

/*!
 * \brief Element::referenceElementTransformHasChanged
 * Updates the referenced components when reference component transform has changed.
 */
void Element::referenceElementTransformHasChanged()
{
  Element *pElement = qobject_cast<Element*>(sender());
  if (pElement) {
    mTransformation.updateTransformation(pElement->mTransformation);
    setTransform(mTransformation.getTransformationMatrix());
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Element::referenceElementChanged
 * Updates the referenced components when reference component is changed.
 */
void Element::referenceElementChanged()
{
  removeChildren();
  drawElement();
  emitChanged();
  updateConnections();
}

/*!
 * \brief Element::referenceElementDeleted
 * Deletes the referenced components when reference component is deleted.
 */
void Element::referenceElementDeleted()
{
  if (mElementType == Element::Port) {
    setVisible(false);
    if (mpReferenceElement && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpBusComponent = mpReferenceElement->getBusComponent();
    }
  } else {
    mpGraphicsView->removeElementItem(this);
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  } else if (isInBus() && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
      // if start connector and end connector is bus
      if (((pConnectionLineAnnotation->getStartElementName().compare(mpLibraryTreeItem->getNameStructure()) == 0)
           && pConnectionLineAnnotation->getEndElement()->getLibraryTreeItem()->getOMSBusConnector())) {
        Element *pStartBusConnector = mpGraphicsView->getModelWidget()->getConnectorElement(pConnectionLineAnnotation->getStartElement()->getRootParentElement(),
                                                                                                mpBusComponent->getName());
        pConnectionLineAnnotation->setStartElement(pStartBusConnector);
        pConnectionLineAnnotation->setVisible(false);
      }
      // if end connector and start connector is bus
      if ((pConnectionLineAnnotation->getEndElementName().compare(mpLibraryTreeItem->getNameStructure()) == 0)
          && pConnectionLineAnnotation->getStartElement()->getLibraryTreeItem()->getOMSBusConnector()) {
        Element *pEndBusConnector = mpGraphicsView->getModelWidget()->getConnectorElement(pConnectionLineAnnotation->getEndElement()->getRootParentElement(),
                                                                                              mpBusComponent->getName());
        pConnectionLineAnnotation->setEndElement(pEndBusConnector);
        pConnectionLineAnnotation->setVisible(false);
      }
    }
  }
}

/*!
 * \brief Element::prepareResizeElement
 * Slot is activated when ResizerItem::resizerItemPressed() SIGNAL is raised.
 * \param pResizerItem
 */
void Element::prepareResizeElement(ResizerItem *pResizerItem)
{
  prepareGeometryChange();
  mOldTransformation = mTransformation;
  mpSelectedResizerItem = pResizerItem;
  mSceneBoundingRect = sceneBoundingRect();
  QPointF topLeft = sceneBoundingRect().topLeft();
  QPointF topRight = sceneBoundingRect().topRight();
  QPointF bottomLeft = sceneBoundingRect().bottomLeft();
  QPointF bottomRight = sceneBoundingRect().bottomRight();
  mTransformationStartPosition = scenePos();
  mPivotPoint = sceneBoundingRect().center();

  if (mpSelectedResizerItem->getResizePosition() == ResizerItem::BottomLeft) {
    mTransformationStartPosition = topLeft;
    mPivotPoint = bottomRight;
  } else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::TopLeft) {
    mTransformationStartPosition = bottomLeft;
    mPivotPoint = topRight;
  } else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::TopRight) {
    mTransformationStartPosition = bottomRight;
    mPivotPoint = topLeft;
  } else if (mpSelectedResizerItem->getResizePosition() == ResizerItem::BottomRight) {
    mTransformationStartPosition = topRight;
    mPivotPoint = bottomLeft;
  }
}

/*!
 * \brief Element::resizeElement
 * Slot is activated when ResizerItem::resizerItemMoved() SIGNAL is raised.
 * \param newPosition
 */
void Element::resizeElement(QPointF newPosition)
{
  float xDistance; //X distance between the current position of the mouse and the starting position mouse
  float yDistance; //Y distance between the current position of the mouse and the starting position mouse
  //Calculates the X distance
  xDistance = newPosition.x() - mTransformationStartPosition.x();
  //If the starting point is on the negative side of the X plane we do an inverse of the value
  if (mTransformationStartPosition.x() < mPivotPoint.x()) {
    xDistance = xDistance * -1;
  }
  //Calculates the Y distance
  yDistance = newPosition.y() - mTransformationStartPosition.y();
  //If the starting point is on the negative side of the Y plane we do an inverse of the value
  if (mTransformationStartPosition.y() < mPivotPoint.y()) {
    yDistance = yDistance * -1;
  }
  //Calculate the factors by dividing the distances againts the original size of this container
  qreal xFactor = 0.0;
  qreal yFactor = 0.0;
  xFactor = xDistance / mSceneBoundingRect.width();
  yFactor = yDistance / mSceneBoundingRect.height();
  xFactor = 1 + xFactor;
  yFactor = 1 + yFactor;
  // if preserveAspectRatio is true then resize equally
  bool preserveAspectRatio;
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    ModelInstance::CoordinateSystem coOrdinateSystem = getCoOrdinateSystemNew();
    preserveAspectRatio = coOrdinateSystem.getPreserveAspectRatio();
  } else {
    CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
    preserveAspectRatio = coOrdinateSystem.getPreserveAspectRatio();
  }
  if (preserveAspectRatio) {
    qreal factor = qMax(qFabs(xFactor), qFabs(yFactor));
    xFactor = xFactor < 0 ? factor * -1 : factor;
    yFactor = yFactor < 0 ? factor * -1 : factor;
  }
  PointAnnotation startOrigin = mOldTransformation.getOrigin();
  ExtentAnnotation startExtent = mOldTransformation.getExtent();
  QPointF startExtent1 = startExtent.at(0);
  QPointF startExtent2 = startExtent.at(1);
  qreal x = mPivotPoint.x() + (startOrigin.x() - mPivotPoint.x()) * xFactor;
  qreal y = mPivotPoint.y() + (startOrigin.y() - mPivotPoint.y()) * yFactor;
  QPointF extent1, extent2;
  extent1.setX(xFactor * startExtent1.x());
  extent1.setY(yFactor * startExtent1.y());
  extent2.setX(xFactor * startExtent2.x());
  extent2.setY(yFactor * startExtent2.y());
  mTransformation.setOrigin(QPointF(x, y));
  QVector<QPointF> extent;
  extent.append(extent1);
  extent.append(extent2);
  mTransformation.setExtent(extent);
  if (!qFuzzyCompare(mOldTransformation.getRotateAngle(), 0.0)) {
    mTransformation.setRotateAngle((xFactor < 0 ? -1 : 1) * (yFactor < 0 ? -1 : 1) * mOldTransformation.getRotateAngle());
  }
  setTransform(mTransformation.getTransformationMatrix());
  // let connections know that component has changed.
  emit transformChange(false);
}

/*!
 * \brief Element::finishResizeElement
 * Slot is activated when ResizerItem resizerItemReleased SIGNAL is raised.
 */
void Element::finishResizeElement()
{
  if (isSelected()) {
    showResizerItems();
  } else {
    setSelected(true);
  }
}

/*!
 * \brief Element::resizedElement
 * Slot is activated when ResizerItem resizerItemPositionChanged SIGNAL is raised.
 */
void Element::resizedElement()
{
  updateElementTransformations(mOldTransformation, false);
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  // push the change on stack only for OMS models. For Modelica models the change is done in ModelWidget::updateModelText();
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    pModelWidget->createOMSimulatorUndoCommand(QStringLiteral("Update element transformations"));
  }
  pModelWidget->updateModelText();
}

/*!
 * \brief Element::componentCommentHasChanged
 * Updates the Element's tooltip when the component comment has changed.
 */
void Element::componentCommentHasChanged()
{
  updateToolTip();
  update();
}

/*!
 * \brief Element::componentNameHasChanged
 * Updates the Element's tooltip when the component name has changed. Emits displayTextChanged signal.
 */
void Element::componentNameHasChanged()
{
  updateToolTip();
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Element::displayTextChangedRecursive
 * Notifies all the TextAnnotation's about the name change.
 */
void Element::displayTextChangedRecursive()
{
  emit displayTextChanged();
  foreach (Element *pInheritedElement, mInheritedElementsList) {
    pInheritedElement->displayTextChangedRecursive();
  }
}

/*!
 * \brief Element::deleteMe
 * Deletes the Element from the current view.
 */
void Element::deleteMe()
{
  // delete the element from model
  mpGraphicsView->deleteElement(this);
}

/*!
 * \brief Element::duplicate
 * Duplicates the Element.
 */
void Element::duplicate()
{
  QString name = getName();
  QString defaultPrefix = "";
  if (mpLibraryTreeItem) {
    if (!mpGraphicsView->performElementCreationChecks(mpLibraryTreeItem, &name, &defaultPrefix)) {
      return;
    }
  } else {
    name = mpGraphicsView->getUniqueElementName(getClassName(), StringHandler::toCamelCase(getName()));
  }
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5, mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  // add component
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    ModelInstance::Component *pModelInstanceComponent = GraphicsView::createModelInstanceComponent(mpGraphicsView->getModelWidget()->getModelInstance(), name,
                                                                                                   getClassName(), mpModelComponent->getModel()->isConnector());
    mpGraphicsView->addElementToView(pModelInstanceComponent, false, true, false, QPointF(0, 0), getOMCPlacementAnnotation(gridStep), false);
    // set modifiers
    if (mpModelComponent->getModifier()) {
      MainWindow::instance()->getOMCProxy()->setElementModifierValue(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), name,
                                                                     mpModelComponent->getModifier()->toString());
    }
  } else {
    mpElementInfo->getModifiersMap(MainWindow::instance()->getOMCProxy(), mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), this);
    ElementInfo *pElementInfo = new ElementInfo(mpElementInfo);
    pElementInfo->setName(name);
    pElementInfo->applyDefaultPrefixes(defaultPrefix);
    mpGraphicsView->addComponentToView(name, mpLibraryTreeItem, getOMCPlacementAnnotation(gridStep), QPointF(0, 0), pElementInfo, true, true, true);
  }
  Element *pDiagramElement = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getElementsList().last();
  setSelected(false);
  if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
    pDiagramElement->setSelected(true);
  } else {
    Element *pIconElement = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getElementsList().last();
    pIconElement->setSelected(true);
  }
}

/*!
 * \brief Element::rotateClockwise
 * Rotates the element clockwise.
 */
void Element::rotateClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = -90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  showResizerItems();
}

/*!
 * \brief Element::rotateAntiClockwise
 * Rotates the element anti clockwise.
 */
void Element::rotateAntiClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = 90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  showResizerItems();
}

/*!
 * \brief Element::flipHorizontal
 * Flips the element horizontally.
 */
void Element::flipHorizontal()
{
  Transformation oldTransformation = mTransformation;
  ExtentAnnotation extent = mTransformation.getExtent();
  QPointF extent1 = extent.at(0);
  QPointF extent2 = extent.at(1);
  // invert x value of extents and the angle
  QVector<QPointF> newExtent;
  newExtent.append(QPointF(-extent1.x(), extent1.y()));
  newExtent.append(QPointF(-extent2.x(), extent2.y()));
  mTransformation.setExtent(newExtent);
  mTransformation.setRotateAngle(-mTransformation.getRotateAngle());
  updateElementTransformations(oldTransformation, false);
  showResizerItems();
}

/*!
 * \brief Element::flipVertical
 * Flips the element vertically.
 */
void Element::flipVertical()
{
  Transformation oldTransformation = mTransformation;
  ExtentAnnotation extent = mTransformation.getExtent();
  QPointF extent1 = extent.at(0);
  QPointF extent2 = extent.at(1);
  // invert y value of extents and the angle
  QVector<QPointF> newExtent;
  newExtent.append(QPointF(extent1.x(), -extent1.y()));
  newExtent.append(QPointF(extent2.x(), -extent2.y()));
  mTransformation.setExtent(newExtent);
  mTransformation.setRotateAngle(-mTransformation.getRotateAngle());
  updateElementTransformations(oldTransformation, false);
  showResizerItems();
}

/*!
 * \brief Element::moveUp
 * Slot that moves element upwards depending on the grid step size value
 * \sa moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft(), moveCtrlRight()
 */
void Element::moveUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep());
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveShiftUp
 * Slot that moves element upwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveShiftUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveCtrlUp
 * Slot that moves element one pixel upwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveCtrlUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, 1);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveDown
 * Slot that moves element downwards depending on the grid step size value
 * \sa moveUp(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep());
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveShiftDown
 * Slot that moves element downwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveShiftDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -(mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5));
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveCtrlDown
 * Slot that moves element one pixel downwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveCtrlDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -1);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveLeft
 * Slot that moves element leftwards depending on the grid step size value
 * \sa moveUp(), moveDown(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep(), 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveShiftLeft
 * Slot that moves element leftwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveShiftLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5), 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveCtrlLeft
 * Slot that moves element one pixel leftwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlRight()
 */
void Element::moveCtrlLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-1, 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveRight
 * Slot that moves element rightwards depending on the grid step size value
 * \sa moveUp(), moveDown(), moveLeft(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep(), 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveShiftRight
 * Slot that moves element rightwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Element::moveShiftRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5, 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::moveCtrlRight
 * Slot that moves element one pixel rightwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlLeft()
 */
void Element::moveCtrlRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(1, 0);
  updateElementTransformations(oldTransformation, true);
}

/*!
 * \brief Element::showParameters
 * Slot that opens up the element parameters dialog.
 * @see showAttributes()
 */
void Element::showParameters()
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 parameters window").arg(mpModel->getName()).arg(getName()));
  } else {
    if (pMainWindow->getOMCProxy()->isBuiltinType(mpElementInfo->getClassName())) {
      return;
    }
    if (!mpLibraryTreeItem || mpLibraryTreeItem->isNonExisting()) {
      QMessageBox::critical(pMainWindow, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                            tr("Cannot show parameters window for component <b>%1</b>. Did not find type <b>%2</b>.").arg(getName())
                            .arg(mpElementInfo->getClassName()), Helper::ok);
      return;
    }
    pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 parameters window").arg(mpLibraryTreeItem->getNameStructure()).arg(getName()));
  }

  if (MainWindow::instance()->isNewApi()) {
    pMainWindow->getProgressBar()->setRange(0, 0);
    pMainWindow->showProgressBar();
    ElementParameters *pElementParameters = new ElementParameters(mpModelComponent, mpGraphicsView, isInheritedElement(), false, 0, 0, 0, pMainWindow);
    pMainWindow->hideProgressBar();
    pMainWindow->getStatusBar()->clearMessage();
    pElementParameters->exec();
    pElementParameters->deleteLater();
  } else {
    pMainWindow->getProgressBar()->setRange(0, 0);
    pMainWindow->showProgressBar();
    ElementParametersOld *pElementParametersOld = new ElementParametersOld(this, pMainWindow);
    pMainWindow->hideProgressBar();
    pMainWindow->getStatusBar()->clearMessage();
    pElementParametersOld->exec();
  }
}

/*!
 * \brief Element::showAttributes
 * Slot that opens up the element attributes dialog.
 * @see showParameters()
 */
void Element::showAttributes()
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (mpGraphicsView->getModelWidget()->isNewApi()) {
    pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 attributes window").arg(mpModel->getName()).arg(getName()));
  } else {
    pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 attributes window").arg(mpLibraryTreeItem->getNameStructure()).arg(mpElementInfo->getName()));
  }
  pMainWindow->getProgressBar()->setRange(0, 0);
  pMainWindow->showProgressBar();
  ElementAttributes *pElementAttributes = new ElementAttributes(this, pMainWindow);
  pMainWindow->hideProgressBar();
  pMainWindow->getStatusBar()->clearMessage();
  pElementAttributes->exec();
}

void Element::fetchInterfaceData()
{
  MainWindow::instance()->fetchInterfaceData(mpGraphicsView->getModelWidget()->getLibraryTreeItem(), this->getName());
}

/*!
 * \brief Element::openClass
 * Slot that opens up the element Modelica class in a new tab/window.
 */
void Element::openClass()
{
  MainWindow::instance()->getLibraryWidget()->openLibraryTreeItem(getClassName());
}

/*!
 * \brief Element::showSubModelAttributes
 * Slot that opens up the CompositeModelSubModelAttributes Dialog.
 */
void Element::showSubModelAttributes()
{
  CompositeModelSubModelAttributes *pCompositeModelSubModelAttributes = new CompositeModelSubModelAttributes(this, MainWindow::instance());
  pCompositeModelSubModelAttributes->exec();
}

/*!
 * \brief Element::showElementPropertiesDialog
 * Slot that opens up the ElementPropertiesDialog Dialog.
 */
void Element::showElementPropertiesDialog()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
      && (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement())) {
    ElementPropertiesDialog *pElementPropertiesDialog = new ElementPropertiesDialog(this, MainWindow::instance());
    pElementPropertiesDialog->exec();
  }
}

/*!
 * \brief Element::updateDynamicSelect
 * Slot activated when updateDynamicSelect SIGNAL is raised by VariablesWidget during the visualization of result file.
 * \param time
 */
void Element::updateDynamicSelect(double time)
{
  // state machine debugging
  if ((mpGraphicsView->getModelWidget()->isNewApi() && mpModel && mpModel->getAnnotation()->isState()) || (mpLibraryTreeItem && mpLibraryTreeItem->isState())) {
    double value = MainWindow::instance()->getVariablesWidget()->readVariableValue(getName() + ".active", time);
    setActiveState(value);
    foreach (LineAnnotation *pTransitionLineAnnotation, mpGraphicsView->getTransitionsList()) {
      if (pTransitionLineAnnotation && pTransitionLineAnnotation->getEndElement() && pTransitionLineAnnotation->getEndElement()->getName().compare(getName()) == 0) {
        pTransitionLineAnnotation->setActiveState(value);
      }
    }
  } else { // DynamicSelect
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      pShapeAnnotation->updateDynamicSelect(time);
    }
  }
}

void Element::resetDynamicSelect()
{
  if ((mpGraphicsView->getModelWidget()->isNewApi() && mpModel && mpModel->getAnnotation()->isState()) || (mpLibraryTreeItem && mpLibraryTreeItem->isState())) {
    // no need to do anything for state machines case.
  } else { // DynamicSelect
    foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
      pShapeAnnotation->resetDynamicSelect();
    }
  }
}

QVariant Element::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);
  if (change == QGraphicsItem::ItemSelectedHasChanged) {
    if (isSelected()) {
      showResizerItems();
      setCursor(Qt::SizeAllCursor);
      // Only allow manipulations on component if the class is not a system library class OR not a visualization view OR component is not an inherited component.
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedElement()) {
        connect(mpGraphicsView, SIGNAL(deleteSignal()), this, SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(duplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseFlipHorizontal()), this, SLOT(flipHorizontal()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseFlipVertical()), this, SLOT(flipVertical()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressFlipHorizontal()), this, SLOT(flipHorizontal()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressFlipVertical()), this, SLOT(flipVertical()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftUp()), this, SLOT(moveShiftUp()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressCtrlUp()), this, SLOT(moveCtrlUp()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftDown()), this, SLOT(moveShiftDown()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressCtrlDown()), this, SLOT(moveCtrlDown()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), this, SLOT(moveShiftLeft()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressCtrlLeft()), this, SLOT(moveCtrlLeft()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressShiftRight()), this, SLOT(moveShiftRight()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressCtrlRight()), this, SLOT(moveCtrlRight()), Qt::UniqueConnection);
      }
    } else {
      if (!mpBottomLeftResizerItem->isPressed() && !mpTopLeftResizerItem->isPressed() &&
          !mpTopRightResizerItem->isPressed() && !mpBottomRightResizerItem->isPressed()) {
        hideResizerItems();
      }
      /* Always hide ResizerItem's for system library class and inherited components. */
      if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || isInheritedElement()) {
        hideResizerItems();
      }
      unsetCursor();
      /* Only allow manipulations on component if the class is not a system library class OR not a visualization view OR component is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedElement()) {
        disconnect(mpGraphicsView, SIGNAL(deleteSignal()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView, SIGNAL(duplicate()), this, SLOT(duplicate()));
        disconnect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()));
        disconnect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        disconnect(mpGraphicsView, SIGNAL(mouseFlipHorizontal()), this, SLOT(flipHorizontal()));
        disconnect(mpGraphicsView, SIGNAL(mouseFlipVertical()), this, SLOT(flipVertical()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        disconnect(mpGraphicsView, SIGNAL(keyPressFlipHorizontal()), this, SLOT(flipHorizontal()));
        disconnect(mpGraphicsView, SIGNAL(keyPressFlipVertical()), this, SLOT(flipVertical()));
        disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftUp()), this, SLOT(moveShiftUp()));
        disconnect(mpGraphicsView, SIGNAL(keyPressCtrlUp()), this, SLOT(moveCtrlUp()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftDown()), this, SLOT(moveShiftDown()));
        disconnect(mpGraphicsView, SIGNAL(keyPressCtrlDown()), this, SLOT(moveCtrlDown()));
        disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), this, SLOT(moveShiftLeft()));
        disconnect(mpGraphicsView, SIGNAL(keyPressCtrlLeft()), this, SLOT(moveCtrlLeft()));
        disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
        disconnect(mpGraphicsView, SIGNAL(keyPressShiftRight()), this, SLOT(moveShiftRight()));
        disconnect(mpGraphicsView, SIGNAL(keyPressCtrlRight()), this, SLOT(moveCtrlRight()));
      }
    }
#if !defined(WITHOUT_OSG)
    // if subModel selection is changed in CompositeModel
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
      MainWindow::instance()->getModelWidgetContainer()->updateThreeDViewer(mpGraphicsView->getModelWidget());
    }
#endif
  } else if (change == QGraphicsItem::ItemPositionHasChanged) {
    emit transformChange(true);
  }
  else if (change == QGraphicsItem::ItemPositionChange) {
    // move by grid distance while dragging component
    QPointF positionDifference = mpGraphicsView->movePointByGrid(value.toPointF() - pos(), mTransformation.getOrigin() + pos(), true);
    return pos() + positionDifference;
  }
  return value;
}
