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
#include "Component.h"
#include "ComponentProperties.h"
#include "OMS/ElementPropertiesDialog.h"
#include "Modeling/Commands.h"
#include "Modeling/DocumentationWidget.h"
#include "Plotting/VariablesWidget.h"
#include "OMS/BusDialog.h"

#include <QMessageBox>
#include <QMenu>
#include <QDockWidget>

/*!
 * \class ComponentInfo
 * \brief A class containing the information about the component like visibility, stream, casuality etc.
 */
/*!
 * \brief ComponentInfo::ComponentInfo
 * \param pParent
 */
ComponentInfo::ComponentInfo(QObject *pParent)
  : QObject(pParent)
{
  mClassName = "";
  mName = "";
  mComment = "";
  mIsProtected = false;
  mIsFinal = false;
  mIsFlow = false;
  mIsStream = false;
  mIsReplaceable = false;
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
 * \brief ComponentInfo::ComponentInfo
 * \param pComponentInfo
 * \param pParent
 */
ComponentInfo::ComponentInfo(ComponentInfo *pComponentInfo, QObject *pParent)
  : QObject(pParent)
{
  updateComponentInfo(pComponentInfo);
}

void ComponentInfo::updateComponentInfo(const ComponentInfo *pComponentInfo)
{
  mClassName = pComponentInfo->getClassName();
  mName = pComponentInfo->getName();
  mComment = pComponentInfo->getComment();
  mIsProtected = pComponentInfo->getProtected();
  mIsFinal = pComponentInfo->getFinal();
  mIsFlow = pComponentInfo->getFlow();
  mIsStream = pComponentInfo->getStream();
  mIsReplaceable = pComponentInfo->getReplaceable();
  mVariabilityMap.insert("constant", "constant");
  mVariabilityMap.insert("discrete", "discrete");
  mVariabilityMap.insert("parameter", "parameter");
  mVariabilityMap.insert("unspecified", "");
  mVariability = pComponentInfo->getVariablity();
  mIsInner = pComponentInfo->getInner();
  mIsOuter = pComponentInfo->getOuter();
  mCasualityMap.insert("input", "input");
  mCasualityMap.insert("output", "output");
  mCasualityMap.insert("unspecified", "");
  mCasuality = pComponentInfo->getCausality();
  mArrayIndex = pComponentInfo->getArrayIndex();
  mIsArray = pComponentInfo->isArray();
  mModifiersMap.clear();
  mModifiersLoaded = pComponentInfo->isModifiersLoaded();
  mModifiersMap = pComponentInfo->getModifiersMapWithoutFetching();
  mParameterValueLoaded = pComponentInfo->isParameterValueLoaded();
  mParameterValue = pComponentInfo->getParameterValueWithoutFetching();
  mStartCommand = pComponentInfo->getStartCommand();
  mExactStep = pComponentInfo->getExactStep();
  mModelFile = pComponentInfo->getModelFile();
  mGeometryFile = pComponentInfo->getGeometryFile();
  mPosition = pComponentInfo->getPosition();
  mAngle321 = pComponentInfo->getAngle321();
  mDimensions = pComponentInfo->getDimensions();
  mTLMCausality = pComponentInfo->getTLMCausality();
  mDomain = pComponentInfo->getDomain();
}

/*!
 * \brief ComponentInfo::parseComponentInfoString
 * Parses the component info string.
 * \param value
 */
void ComponentInfo::parseComponentInfoString(QString value)
{
  if (value.isEmpty()) {
    return;
  }
  QStringList list = StringHandler::unparseStrings(value);
  // read the class name
  if (list.size() > 0) {
    mClassName = list.at(0);
  } else {
    return;
  }
  // read the name
  if (list.size() > 1) {
    mName = list.at(1);
  } else {
    return;
  }
  // read the class comment
  if (list.size() > 2) {
    mComment = list.at(2);
  } else {
    return;
  }
  // read the class access
  if (list.size() > 3) {
    mIsProtected = StringHandler::removeFirstLastQuotes(list.at(3)).contains("protected");
  } else {
    return;
  }
  // read the final attribute
  if (list.size() > 4) {
    mIsFinal = list.at(4).contains("true");
  } else {
    return;
  }
  // read the flow attribute
  if (list.size() > 5) {
    mIsFlow = list.at(5).contains("true");
  } else {
    return;
  }
  // read the stream attribute
  if (list.size() > 6) {
    mIsStream = list.at(6).contains("true");
  } else {
    return;
  }
  // read the replaceable attribute
  if (list.size() > 7) {
    mIsReplaceable = list.at(7).contains("true");
  } else {
    return;
  }
  // read the variability attribute
  if (list.size() > 8) {
    QMap<QString, QString>::iterator variability_it;
    for (variability_it = mVariabilityMap.begin(); variability_it != mVariabilityMap.end(); ++variability_it) {
      if (variability_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(8))) == 0) {
        mVariability = variability_it.value();
        break;
      }
    }
  }
  // read the inner attribute
  if (list.size() > 9) {
    mIsInner = list.at(9).contains("inner");
    mIsOuter = list.at(9).contains("outer");
  } else {
    return;
  }
  // read the casuality attribute
  if (list.size() > 10) {
    QMap<QString, QString>::iterator casuality_it;
    for (casuality_it = mCasualityMap.begin(); casuality_it != mCasualityMap.end(); ++casuality_it) {
      if (casuality_it.key().compare(StringHandler::removeFirstLastQuotes(list.at(10))) == 0) {
        mCasuality = casuality_it.value();
        break;
      }
    }
  }
  // read the array index value
  if (list.size() > 11) {
    setArrayIndex(list.at(11));
  }
}

/*!
 * \brief ComponentInfo::fetchModifiers
 * Fetches the Component modifiers if any.
 * \param pOMCProxy
 * \param className
 * \param pComponent
 */
void ComponentInfo::fetchModifiers(OMCProxy *pOMCProxy, QString className, Component *pComponent)
{
  mModifiersMap.clear();
  QStringList componentModifiersList = pOMCProxy->getComponentModifierNames(className, mName);
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
     * If a modifier class is a record we read the modifer value with submodifiers using OMCProxy::getComponentModifierValues()
     * Otherwise read the binding value using OMCProxy::getComponentModifierValue()
     */
    if (isModiferClassRecord(modifierName, pComponent)) {
      QString originalModifierName = QString(mName).append(".").append(modifierName);
      QString componentModifierValue = pOMCProxy->getComponentModifierValues(className, originalModifierName);
      mModifiersMap.insert(modifierName, componentModifierValue);
    } else {
      QString originalModifierName = QString(mName).append(".").append(componentModifier);
      QString componentModifierValue = pOMCProxy->getComponentModifierValue(className, originalModifierName);
      mModifiersMap.insert(componentModifier, componentModifierValue);
    }
  }
}

/*!
 * \brief ComponentInfo::fetchParameterValue
 * Fetches the Component parameter value if any.
 * \param pOMCProxy
 * \param className
 */
void ComponentInfo::fetchParameterValue(OMCProxy *pOMCProxy, QString className)
{
  mParameterValue = pOMCProxy->getParameterValue(className, mName);
}

/*!
 * \brief ComponentInfo::applyDefaultPrefixes
 * Applies the default prefixes.
 * \param defaultPrefixes
 */
void ComponentInfo::applyDefaultPrefixes(QString defaultPrefixes)
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
 * \brief ComponentInfo::setArrayIndex
 * Sets the array index
 * \param arrayIndex
 */
void ComponentInfo::setArrayIndex(QString arrayIndex)
{
  mArrayIndex = arrayIndex;
  if (mArrayIndex.compare("{}") != 0) {
    mIsArray = true;
  } else {
    mIsArray = false;
  }
}

/*!
 * \brief ComponentInfo::getModifiersMap
 * Fetches the Component modifiers if needed and return them.
 * \param pOMCProxy
 * \param className
 * \param pComponent
 * \return
 */
QMap<QString, QString> ComponentInfo::getModifiersMap(OMCProxy *pOMCProxy, QString className, Component *pComponent)
{
  if (!mModifiersLoaded) {
    fetchModifiers(pOMCProxy, className, pComponent);
    mModifiersLoaded = true;
  }
  return mModifiersMap;
}

/*!
 * \brief ComponentInfo::getParameterValue
 * Fetches the parameters value if needed and return it.
 * \param pOMCProxy
 * \param className
 * \return
 */
QString ComponentInfo::getParameterValue(OMCProxy *pOMCProxy, QString className)
{
  if (!mParameterValueLoaded) {
    fetchParameterValue(pOMCProxy, className);
    mParameterValueLoaded = true;
  }
  return mParameterValue;
}

/*!
 * \brief ComponentInfo::operator ==
 * \param componentInfo
 * Compares the ComponentInfo and returns true if its equal.
 * \return
 */
bool ComponentInfo::operator==(const ComponentInfo &componentInfo) const
{
  return (componentInfo.getClassName() == this->getClassName()) && (componentInfo.getName() == this->getName()) &&
      (componentInfo.getComment() == this->getComment()) && (componentInfo.getProtected() == this->getProtected()) &&
      (componentInfo.getFinal() == this->getFinal()) && (componentInfo.getFlow() == this->getFlow()) &&
      (componentInfo.getStream() == this->getStream()) && (componentInfo.getReplaceable() == this->getReplaceable()) &&
      (componentInfo.getVariablity() == this->getVariablity()) && (componentInfo.getInner() == this->getInner()) &&
      (componentInfo.getOuter() == this->getOuter()) && (componentInfo.getCausality() == this->getCausality()) &&
      (componentInfo.getArrayIndex() == this->getArrayIndex()) &&
      (componentInfo.getModifiersMapWithoutFetching() == this->getModifiersMapWithoutFetching()) &&
      (componentInfo.getParameterValueWithoutFetching() == this->getParameterValueWithoutFetching()) &&
      (componentInfo.getStartCommand() == this->getStartCommand()) && (componentInfo.getExactStep() == this->getExactStep()) &&
      (componentInfo.getModelFile() == this->getModelFile()) && (componentInfo.getGeometryFile() == this->getGeometryFile()) &&
      (componentInfo.getPosition() == this->getPosition()) && (componentInfo.getAngle321() == this->getAngle321()) &&
      (componentInfo.getDimensions() == this->getDimensions()) && (componentInfo.getTLMCausality() == this->getTLMCausality()) &&
      (componentInfo.getDomain() == this->getDomain());
}

/*!
 * \brief ComponentInfo::operator !=
 * \param componentInfo
 * Compares the ComponentInfo and returns true if its not equal.
 * \return
 */
bool ComponentInfo::operator!=(const ComponentInfo &componentInfo) const
{
  return !operator==(componentInfo);
}

QString ComponentInfo::getHTMLDescription() const
{
  return QString("<b>%1</b><br/>&nbsp;&nbsp;&nbsp;&nbsp;%2 <i>\"%3\"<i>")
      .arg(mClassName, mName, Utilities::escapeForHtmlNonSecure(mComment));
}

/*!
 * \brief ComponentInfo::isModiferClassRecord
 * Returns true if a modifier class is a record.
 * \param modifierName
 * \param pComponent
 * \return
 */
bool ComponentInfo::isModiferClassRecord(QString modifierName, Component *pComponent)
{
  bool result = false;
  foreach (Component *pInheritedComponent, pComponent->getInheritedComponentsList()) {
    /* Since we use the parent ComponentInfo for inherited classes so we should not use
     * pInheritedComponent->getComponentInfo()->getClassName() to get the name instead we should use
     * pInheritedComponent->getLibraryTreeItem()->getNameStructure() to get the correct name of inherited class.
     */
    if (pInheritedComponent->getLibraryTreeItem() && pInheritedComponent->getLibraryTreeItem()->getName().compare(modifierName) == 0 &&
        pInheritedComponent->getLibraryTreeItem()->getRestriction() == StringHandler::Record) {
      return true;
    }
    result = isModiferClassRecord(modifierName, pInheritedComponent);
    if (result) {
      return result;
    }
  }
  foreach (Component *pNestedComponent, pComponent->getComponentsList()) {
    if (pNestedComponent->getName().compare(modifierName) == 0 && pNestedComponent->getLibraryTreeItem() &&
        pNestedComponent->getLibraryTreeItem()->getRestriction() == StringHandler::Record) {
      return true;
    }
    result = isModiferClassRecord(modifierName, pNestedComponent);
    if (result) {
      return result;
    }
  }
  return result;
}

Component::Component(QString name, LibraryTreeItem *pLibraryTreeItem, QString annotation, QPointF position, ComponentInfo *pComponentInfo,
                     GraphicsView *pGraphicsView)
  : QGraphicsItem(0), mpReferenceComponent(0), mpParentComponent(0)
{
  setZValue(2000);
  mpLibraryTreeItem = pLibraryTreeItem;
  mpComponentInfo = pComponentInfo;
  mpComponentInfo->setName(name);
  if (mpLibraryTreeItem) {
    mpComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  }
  mpGraphicsView = pGraphicsView;
  mIsInheritedComponent = false;
  mComponentType = Component::Root;
  mTransformationString = StringHandler::getPlacementAnnotation(annotation);
  // Construct the temporary polygon that is used when scaling
  mpResizerRectangle = new QGraphicsRectItem;
  mpResizerRectangle->setZValue(-5000);  // set to a very low value
  mpGraphicsView->addItem(mpResizerRectangle);
  QPen pen;
  pen.setStyle(Qt::DotLine);
  pen.setColor(Qt::transparent);
  mpResizerRectangle->setPen(pen);
  setOldScenePosition(QPointF(0, 0));
  setOldPosition(QPointF(0, 0));
  setComponentFlags(true);
  createNonExistingComponent();
  createDefaultComponent();
  createStateComponent();
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    mpDefaultComponentRectangle->setVisible(true);
    mpDefaultComponentText->setVisible(true);
    drawInterfacePoints();
  } else {
    drawComponent();
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
    mTransformation.setExtent1(QPointF(initialScale * boundingRect().left(), initialScale * boundingRect().top()));
    mTransformation.setExtent2(QPointF(initialScale * boundingRect().right(), initialScale * boundingRect().bottom()));
    mTransformation.setRotateAngle(0.0);
  }
  // dynamically adjust the interface points.
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    adjustInterfacePoints();
  }
  setTransform(mTransformation.getTransformationMatrix());
  setDialogAnnotation(StringHandler::getAnnotation(annotation, "Dialog"));
  setChoicesAnnotation(StringHandler::getAnnotation(annotation, "choices"));
  // create actions
  createActions();
  mpOriginItem = new OriginItem(this);
  createResizerItems();
  updateToolTip();
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleComponentAdded()));
    connect(mpLibraryTreeItem, SIGNAL(nameChanged()), SLOT(handleNameChanged()));
  }
  connect(this, SIGNAL(transformHasChanged()), SLOT(updatePlacementAnnotation()));
  connect(this, SIGNAL(transformHasChanged()), SLOT(updateOriginItem()));
  /* Ticket:4204
   * If the child class use text annotation from base class then we need to call this
   * since when the base class is created the child class doesn't exist.
   */
  displayTextChangedRecursive();
}

Component::Component(LibraryTreeItem *pLibraryTreeItem, Component *pParentComponent)
  : QGraphicsItem(pParentComponent), mpReferenceComponent(0), mpParentComponent(pParentComponent)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mpComponentInfo = mpParentComponent->getComponentInfo();
  /* Ticket #4013
   * We should have one ComponentInfo for each Component.
   * Creating a new ComponentInfo here for inherited classes gives wrong display of text names.
   */
//  mpComponentInfo = new ComponentInfo;
//  mpComponentInfo->setName(mpParentComponent->getComponentInfo()->getName());
//  mpComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  mpGraphicsView = mpParentComponent->getGraphicsView();
  mIsInheritedComponent = mpParentComponent->isInheritedComponent();
  mComponentType = Component::Extend;
  mTransformationString = "";
  mpResizerRectangle = 0;
  createNonExistingComponent();
  mpDefaultComponentRectangle = 0;
  mpDefaultComponentText = 0;
  mpStateComponentRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;
  drawInheritedComponentsAndShapes();
  setDialogAnnotation(QStringList());
  setChoicesAnnotation(QStringList());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleComponentAdded()));
  }
}

Component::Component(Component *pComponent, Component *pParentComponent, Component *pRootParentComponent)
  : QGraphicsItem(pRootParentComponent), mpReferenceComponent(pComponent), mpParentComponent(pParentComponent)
{
  mpLibraryTreeItem = mpReferenceComponent->getLibraryTreeItem();
  mpComponentInfo = mpReferenceComponent->getComponentInfo();
  mIsInheritedComponent = mpReferenceComponent->isInheritedComponent();
  mComponentType = Component::Port;
  mpGraphicsView = mpParentComponent->getGraphicsView();
  mTransformationString = mpReferenceComponent->getTransformationString();
  mDialogAnnotation = mpReferenceComponent->getDialogAnnotation();
  mChoicesAnnotation = mpReferenceComponent->getChoicesAnnotation();
  mpResizerRectangle = 0;
  createNonExistingComponent();
  mpDefaultComponentRectangle = 0;
  mpDefaultComponentText = 0;
  mpStateComponentRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = mpReferenceComponent->getBusComponent();
  drawInheritedComponentsAndShapes();
  mTransformation = Transformation(mpReferenceComponent->mTransformation);
  setTransform(mTransformation.getTransformationMatrix());
  mpOriginItem = 0;
  mpBottomLeftResizerItem = 0;
  mpTopLeftResizerItem = 0;
  mpTopRightResizerItem = 0;
  mpBottomRightResizerItem = 0;
  updateToolTip();
  setVisible(!mpReferenceComponent->isInBus());
  if (mpLibraryTreeItem) {
    connect(mpLibraryTreeItem, SIGNAL(loadedForComponent()), SLOT(handleLoaded()));
    connect(mpLibraryTreeItem, SIGNAL(unLoadedForComponent()), SLOT(handleUnloaded()));
    connect(mpLibraryTreeItem, SIGNAL(shapeAddedForComponent()), SLOT(handleShapeAdded()));
    connect(mpLibraryTreeItem, SIGNAL(componentAddedForComponent()), SLOT(handleComponentAdded()));
  }
  connect(mpReferenceComponent, SIGNAL(added()), SLOT(referenceComponentAdded()));
  connect(mpReferenceComponent, SIGNAL(transformHasChanged()), SLOT(referenceComponentTransformHasChanged()));
  connect(mpReferenceComponent, SIGNAL(displayTextChanged()), SLOT(componentNameHasChanged()));
  connect(mpReferenceComponent, SIGNAL(deleted()), SLOT(referenceComponentDeleted()));
}

Component::Component(Component *pComponent, GraphicsView *pGraphicsView)
  : QGraphicsItem(0), mpReferenceComponent(pComponent), mpParentComponent(0)
{
  setZValue(2000);
  mpLibraryTreeItem = mpReferenceComponent->getLibraryTreeItem();
  mpComponentInfo = mpReferenceComponent->getComponentInfo();
  mpGraphicsView = pGraphicsView;
  mIsInheritedComponent = true;
  mComponentType = Component::Root;
  mTransformationString = mpReferenceComponent->getTransformationString();
  mDialogAnnotation = mpReferenceComponent->getDialogAnnotation();
  mChoicesAnnotation = mpReferenceComponent->getChoicesAnnotation();
  //Construct the temporary polygon that is used when scaling
  mpResizerRectangle = new QGraphicsRectItem;
  mpResizerRectangle->setZValue(5000);  // set to a very high value
  mpGraphicsView->addItem(mpResizerRectangle);
  QPen pen;
  pen.setStyle(Qt::DotLine);
  pen.setColor(Qt::transparent);
  mpResizerRectangle->setPen(pen);
  setOldScenePosition(QPointF(0, 0));
  setOldPosition(QPointF(0, 0));
  setComponentFlags(true);
  createNonExistingComponent();
  createDefaultComponent();
  createStateComponent();
  mHasTransition = mpReferenceComponent->hasTransition();;
  mIsInitialState = mpReferenceComponent->isInitialState();
  mActiveState = false;
  mpBusComponent = 0;
  drawComponent();
  mTransformation = Transformation(mpReferenceComponent->mTransformation);
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
  connect(mpReferenceComponent, SIGNAL(added()), SLOT(referenceComponentAdded()));
  connect(mpReferenceComponent, SIGNAL(transformHasChanged()), SLOT(referenceComponentTransformHasChanged()));
  connect(mpReferenceComponent, SIGNAL(transformHasChanged()), SLOT(updateOriginItem()));
  connect(mpReferenceComponent, SIGNAL(transformHasChanged()), SIGNAL(transformChange()));
  connect(mpReferenceComponent, SIGNAL(displayTextChanged()), SIGNAL(displayTextChanged()));
  connect(mpReferenceComponent, SIGNAL(changed()), SLOT(referenceComponentChanged()));
  connect(mpReferenceComponent, SIGNAL(deleted()), SLOT(referenceComponentDeleted()));
  /* Ticket:4204
   * If the child class use text annotation from base class then we need to call this
   * since when the base class is created the child class doesn't exist.
   */
  displayTextChangedRecursive();
}

Component::Component(ComponentInfo *pComponentInfo, Component *pParentComponent)
  : QGraphicsItem(pParentComponent), mpReferenceComponent(0), mpParentComponent(pParentComponent)
{
  mpLibraryTreeItem = 0;
  mpComponentInfo = pComponentInfo;
  mIsInheritedComponent = false;
  mComponentType = Component::Port;
  mpGraphicsView = mpParentComponent->getGraphicsView();
  mTransformationString = "";
  mDialogAnnotation.clear();
  mChoicesAnnotation.clear();
  mpResizerRectangle = 0;
  createNonExistingComponent();
  createDefaultComponent();
  mpStateComponentRectangle = 0;
  mHasTransition = false;
  mIsInitialState = false;
  mActiveState = false;
  mpBusComponent = 0;

  if (mpComponentInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMBidirectional)) {
    if (mpComponentInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Mechanical)) {
      mpDefaultComponentRectangle->setFillColor(QColor(100, 100, 255));   //Mechanical = blue
    } else if (mpComponentInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Electric)) {
      mpDefaultComponentRectangle->setFillColor(QColor(255, 255, 100));   //Hydraulic = yellow
    } else if (mpComponentInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Hydraulic)) {
      mpDefaultComponentRectangle->setFillColor(QColor(100, 255, 100));   //Hydraulic = green
    } else if (mpComponentInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Pneumatic)) {
      mpDefaultComponentRectangle->setFillColor(QColor(100, 255, 255));   //Pneumatic = turquoise
    } else if (mpComponentInfo->getDomain() == StringHandler::getTLMDomain(StringHandler::Magnetic)) {
      mpDefaultComponentRectangle->setFillColor(QColor(255, 100, 255));   //Magnetic = purple
    }
    mpDefaultComponentText->setTextString(QString::number(mpComponentInfo->getDimensions())+ "D");
  } else if ((mpComponentInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMInput)) ||
             (mpComponentInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMOutput))) {
    mpDefaultComponentRectangle->setFillColor(QColor(255, 100, 100));       //Signal = red
    if (mpComponentInfo->getTLMCausality() == StringHandler::getTLMCausality(StringHandler::TLMInput)) {
      mpDefaultComponentText->setTextString("in");
    } else {
      mpDefaultComponentText->setTextString("out");
    }
  }
  mpDefaultComponentRectangle->setLineColor(QColor(0, 0, 0));
  mpDefaultComponentRectangle->setFillPattern(StringHandler::FillSolid);
  mpDefaultComponentRectangle->setVisible(true);
  mpDefaultComponentText->setFontSize(5);
  mpDefaultComponentText->setVisible(true);
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
 * \brief Component::hasShapeAnnotation
 * Checks if Component has any ShapeAnnotation
 * \param pComponent
 * \return
 */
bool Component::hasShapeAnnotation(Component *pComponent)
{
  if (!pComponent->getShapesList().isEmpty()) {
    return true;
  }
  bool iconAnnotationFound = false;
  foreach (Component *pInheritedComponent, pComponent->getInheritedComponentsList()) {
    iconAnnotationFound = hasShapeAnnotation(pInheritedComponent);
    if (iconAnnotationFound) {
      return iconAnnotationFound;
    }
  }
  /* Ticket #3654
   * Don't check components because if it has components and no shapes then it looks empty.
   */
//  foreach (Component *pChildComponent, pComponent->getComponentsList()) {
//    iconAnnotationFound = hasShapeAnnotation(pChildComponent);
//    if (iconAnnotationFound) {
//      return iconAnnotationFound;
//    }
//    foreach (Component *pInheritedComponent, pChildComponent->getInheritedComponentsList()) {
//      iconAnnotationFound = hasShapeAnnotation(pInheritedComponent);
//      if (iconAnnotationFound) {
//        return iconAnnotationFound;
//      }
//    }
//  }
  return iconAnnotationFound;
}

/*!
 * \brief Component::hasNonExistingClass
 * Returns true if any class in the hierarchy is non-existing.
 * \return
 */
bool Component::hasNonExistingClass()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->isNonExisting()) {
    return true;
  }
  bool nonExistingClassFound = false;
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    nonExistingClassFound = pInheritedComponent->hasNonExistingClass();
    if (nonExistingClassFound) {
      return nonExistingClassFound;
    }
  }
  /* Ticket #3706
   * Don't check components because we should not display class as missing one of components class is missing.
   */
//  foreach (Component *pChildComponent, mComponentsList) {
//    nonExistingClassFound = pChildComponent->hasNonExistingClass();
//    if (nonExistingClassFound) {
//      return nonExistingClassFound;
//    }
//    foreach (Component *pInheritedComponent, pChildComponent->getInheritedComponentsList()) {
//      nonExistingClassFound = pInheritedComponent->hasNonExistingClass();
//      if (nonExistingClassFound) {
//        return nonExistingClassFound;
//      }
//    }
//  }
  return nonExistingClassFound;
}

QRectF Component::boundingRect() const
{
  CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
  qreal left = coOrdinateSystem.getExtent().at(0).x();
  qreal bottom = coOrdinateSystem.getExtent().at(0).y();
  qreal right = coOrdinateSystem.getExtent().at(1).x();
  qreal top = coOrdinateSystem.getExtent().at(1).y();
  return QRectF(left, bottom, fabs(left - right), fabs(bottom - top));
}

/*!
 * \brief Component::itemsBoundingRect
 * Gets the bounding rectangle of all the items added to the component.
 * \return
 */
QRectF Component::itemsBoundingRect()
{
  QRectF rect;
  /* ticket:4431 use Component's sceneBoundingRect()
   * instead of calling sceneBoundingRect() on its items.
   */
  foreach (Component *pComponent, mInheritedComponentsList) {
    rect |= pComponent->sceneBoundingRect();
  }
  foreach (Component *pComponent, mComponentsList) {
    rect |= pComponent->sceneBoundingRect();
  }
  foreach (QGraphicsItem *item, mShapesList) {
    if (TextAnnotation *pTextAnnotation = dynamic_cast<TextAnnotation*>(item)) {
      rect |= pTextAnnotation->mExportBoundingRect;
    } else {
      rect |= item->sceneBoundingRect();
    }
  }
  if (mpNonExistingComponentLine->isVisible()) {
    rect |= mpNonExistingComponentLine->sceneBoundingRect();
  }
  if (mpDefaultComponentRectangle->isVisible()) {
    rect |= mpDefaultComponentRectangle->sceneBoundingRect();
  }
  if (mpDefaultComponentText->isVisible()) {
    rect |= mpDefaultComponentText->sceneBoundingRect();
  }
  return rect;
}

void Component::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(painter);
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mTransformation.isValid()) {
    setVisible(mTransformation.getVisible());
    if (mpStateComponentRectangle) {
      if (isVisible() && mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica &&
          mpLibraryTreeItem->isState()) {
        if (mHasTransition && mIsInitialState) {
          mpStateComponentRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateComponentRectangle->setLineThickness(0.5);
        } else if (mHasTransition && !mIsInitialState) {
          mpStateComponentRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateComponentRectangle->setLineThickness(0.25);
        } else if (!mHasTransition && mIsInitialState) {
          mpStateComponentRectangle->setLinePattern(StringHandler::LineSolid);
          mpStateComponentRectangle->setLineThickness(0.5);
        } else if (!mHasTransition && !mIsInitialState) {
          mpStateComponentRectangle->setLinePattern(StringHandler::LineDash);
          mpStateComponentRectangle->setLineThickness(0.25);
        }
        mpStateComponentRectangle->setVisible(true);
      } else {
        mpStateComponentRectangle->setVisible(false);
      }
    }
  }
}

Component* Component::getRootParentComponent()
{
  Component *pComponent = this;
  while (pComponent->getParentComponent()) {
    pComponent = pComponent->getParentComponent();
  }
  return pComponent;
}

/*!
 * \brief Component::getCoOrdinateSystem
 * \return
 */
CoOrdinateSystem Component::getCoOrdinateSystem() const
{
  CoOrdinateSystem coOrdinateSystem;
  if (mpLibraryTreeItem && !mpLibraryTreeItem->isNonExisting() && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::Modelica
      && mpLibraryTreeItem->getModelWidget()) {
    if (mpLibraryTreeItem->isConnector()) {
      if (mpGraphicsView->getViewType() == StringHandler::Icon) {
        coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->mCoOrdinateSystem;
      } else {
        coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->mCoOrdinateSystem;
      }
    } else {
      coOrdinateSystem = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->mCoOrdinateSystem;
    }
  }
  return coOrdinateSystem;
}

void Component::setComponentFlags(bool enable)
{
  /* Only set the ItemIsMovable & ItemSendsGeometryChanges flags on component if the class is not a system library class
   * AND component is not an inherited shape.
   */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedComponent()) {
    setFlag(QGraphicsItem::ItemIsMovable, enable);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
  }
  setFlag(QGraphicsItem::ItemIsSelectable, enable);
}

QString Component::getTransformationAnnotation()
{
  QString annotationString;
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    annotationString.append("iconTransformation=transformation(");
  } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
    annotationString.append("transformation=transformation(");
  }
  // add the origin
  if (mTransformation.hasOrigin()) {
    annotationString.append("origin={").append(QString::number(mTransformation.getOrigin().x())).append(",");
    annotationString.append(QString::number(mTransformation.getOrigin().y())).append("}, ");
  }
  // add extent points
  QPointF extent1 = mTransformation.getExtent1();
  QPointF extent2 = mTransformation.getExtent2();
  annotationString.append("extent={").append("{").append(QString::number(extent1.x()));
  annotationString.append(",").append(QString::number(extent1.y())).append("},");
  annotationString.append("{").append(QString::number(extent2.x())).append(",");
  annotationString.append(QString::number(extent2.y())).append("}}, ");
  // add icon rotation
  annotationString.append("rotation=").append(QString::number(mTransformation.getRotateAngle())).append(")");
  return annotationString;
}

QString Component::getPlacementAnnotation()
{
  // create the placement annotation string
  QString placementAnnotationString = "annotate=Placement(";
  if (mTransformation.isValid()) {
    placementAnnotationString.append("visible=").append(mTransformation.getVisible() ? "true" : "false");
  }
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector()) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      // first get the component from diagram view and get the transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getComponentObject(getName());
      if (pComponent) {
        placementAnnotationString.append(", ").append(pComponent->getTransformationAnnotation());
      }
      // then get the icon transformations
      placementAnnotationString.append(", ").append(getTransformationAnnotation());
    } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
      // first get the component from diagram view and get the transformations
      placementAnnotationString.append(", ").append(getTransformationAnnotation());
      // then get the icon transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getComponentObject(getName());
      if (pComponent) {
        placementAnnotationString.append(", ").append(pComponent->getTransformationAnnotation());
      }
    }
  } else {
    placementAnnotationString.append(", ").append(getTransformationAnnotation());
  }
  placementAnnotationString.append(")");
  return placementAnnotationString;
}

/*!
 * \brief Component::getOMCTransformationAnnotation
 * Returns the Component placement transformation annotation in OMC format.
 * \param position
 * \return
 */
QString Component::getOMCTransformationAnnotation(QPointF position)
{
  QString annotationString;
  // add the origin
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(position.x(), position.y());
  if (mTransformation.hasOrigin()) {
    annotationString.append(QString::number(mTransformation.getOrigin().x())).append(",");
    annotationString.append(QString::number(mTransformation.getOrigin().y())).append(",");
  } else {
    annotationString.append("-,");
    annotationString.append("-,");
  }
  // add extent points
  QPointF extent1 = mTransformation.getExtent1();
  QPointF extent2 = mTransformation.getExtent2();
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
 * \brief Component::getOMCPlacementAnnotation
 * Returns the Component placement annotation in OMC format.
 * \param position
 * \return
 */
QString Component::getOMCPlacementAnnotation(QPointF position)
{
  // create the placement annotation string
  QString placementAnnotationString = "Placement(";
  if (mTransformation.isValid()) {
    placementAnnotationString.append(mTransformation.getVisible() ? "true" : "false");
  }
  if (mpLibraryTreeItem && mpLibraryTreeItem->isConnector()) {
    if (mpGraphicsView->getViewType() == StringHandler::Icon) {
      // first get the component from diagram view and get the transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getComponentObject(getName());
      if (pComponent) {
        placementAnnotationString.append(",").append(pComponent->getOMCTransformationAnnotation(position));
      } else {
        placementAnnotationString.append(",-,-,-,-,-,-,-");
      }
      // then get the icon transformations
      placementAnnotationString.append(",").append(getOMCTransformationAnnotation(position));
    } else if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
      // first get the component from diagram view and get the transformations
      placementAnnotationString.append(",").append(getOMCTransformationAnnotation(position));
      // then get the icon transformations
      Component *pComponent;
      pComponent = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getComponentObject(getName());
      if (pComponent) {
        placementAnnotationString.append(",").append(pComponent->getOMCTransformationAnnotation(position));
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

QString Component::getTransformationOrigin()
{
  // add the icon origin
  QString transformationOrigin;
  transformationOrigin.append("{").append(QString::number(mTransformation.getOrigin().x())).append(",").append(QString::number(mTransformation.getOrigin().y())).append("}");
  return transformationOrigin;
}

QString Component::getTransformationExtent()
{
  QString transformationExtent;
  // add extent points
  QPointF extent1 = mTransformation.getExtent1();
  QPointF extent2 = mTransformation.getExtent2();
  transformationExtent.append("{").append(QString::number(extent1.x()));
  transformationExtent.append(",").append(QString::number(extent1.y())).append(",");
  transformationExtent.append(QString::number(extent2.x())).append(",");
  transformationExtent.append(QString::number(extent2.y())).append("}");
  return transformationExtent;
}

/*!
 * \brief Component::createClassComponents
 * Creates a class components.
 */
void Component::createClassComponents()
{
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    pInheritedComponent->createClassComponents();
  }
  if (!mpLibraryTreeItem->isNonExisting()) {
    if (!mpLibraryTreeItem->getModelWidget()) {
      MainWindow *pMainWindow = MainWindow::instance();
      pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
    }
    mpLibraryTreeItem->getModelWidget()->loadComponents();
    foreach (Component *pComponent, mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getComponentsList()) {
      mComponentsList.append(new Component(pComponent, this, getRootParentComponent()));
    }
    mpLibraryTreeItem->getModelWidget()->loadDiagramView();
    foreach (Component *pComponent, mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
      if (pComponent->getLibraryTreeItem() && pComponent->getLibraryTreeItem()->isConnector()) {
        continue;
      }
      Component *pNewComponent = new Component(pComponent, this, getRootParentComponent());
      // Set the Parent Item to 0 beacause we don't want to render Diagram components. We just want to store them for Parameters Dialog.
      pNewComponent->setParentItem(0);
      mpGraphicsView->removeItem(pNewComponent);
      mComponentsList.append(pNewComponent);
    }
  }
}

void Component::applyRotation(qreal angle)
{
  Transformation oldTransformation = mTransformation;
  setOriginAndExtents();
  if (angle == 360) {
    angle = 0;
  }
  mTransformation.setRotateAngle(angle);
  updateComponentTransformations(oldTransformation);
}

void Component::addConnectionDetails(LineAnnotation *pConnectorLineAnnotation)
{
  // handle component position, rotation and scale changes
  connect(this, SIGNAL(transformChange()), pConnectorLineAnnotation, SLOT(handleComponentMoved()), Qt::UniqueConnection);
  if (!pConnectorLineAnnotation->isInheritedShape()) {
    connect(this, SIGNAL(transformChanging()), pConnectorLineAnnotation, SLOT(updateConnectionTransformation()), Qt::UniqueConnection);
  }
}

void Component::removeConnectionDetails(LineAnnotation *pConnectorLineAnnotation)
{
  disconnect(this, SIGNAL(transformChange()), pConnectorLineAnnotation, SLOT(handleComponentMoved()));
  if (!pConnectorLineAnnotation->isInheritedShape()) {
    disconnect(this, SIGNAL(transformChanging()), pConnectorLineAnnotation, SLOT(updateConnectionTransformation()));
  }
}

/*!
 * \brief Component::setHasTransition
 * \param hasTransition
 */
void Component::setHasTransition(bool hasTransition)
{
  if (hasTransition) {
    mHasTransition = true;
    update();
  } else {
    foreach (LineAnnotation *pTransitionLineAnnotation, mpGraphicsView->getTransitionsList()) {
      Component *pStartComponent = pTransitionLineAnnotation->getStartComponent();
      Component *pEndComponent = pTransitionLineAnnotation->getEndComponent();
      if (pStartComponent->getRootParentComponent() == this || pEndComponent->getRootParentComponent() == this) {
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
 * \brief Component::setIsInitialState
 * \param isInitialState
 */
void Component::setIsInitialState(bool isInitialState)
{
  if (isInitialState) {
    mIsInitialState = true;
    update();
  } else {
    foreach (LineAnnotation *pInitialStateLineAnnotation, mpGraphicsView->getInitialStatesList()) {
      Component *pStartComponent = pInitialStateLineAnnotation->getStartComponent();
      if (pStartComponent->getRootParentComponent() == this) {
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
 * \brief Component::removeChildren
 * Removes the complete hirerchy of the Component.
 */
void Component::removeChildren()
{
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    pInheritedComponent->removeChildren();
    pInheritedComponent->setParentItem(0);
    mpGraphicsView->removeItem(pInheritedComponent);
    delete pInheritedComponent;
  }
  mInheritedComponentsList.clear();
  foreach (Component *pComponent, mComponentsList) {
    pComponent->removeChildren();
    pComponent->setParentItem(0);
    mpGraphicsView->removeItem(pComponent);
    delete pComponent;
  }
  mComponentsList.clear();
  foreach (ShapeAnnotation *pShapeAnnotation, mShapesList) {
    pShapeAnnotation->setParentItem(0);
    mpGraphicsView->removeItem(pShapeAnnotation);
    delete pShapeAnnotation;
  }
  mShapesList.clear();
}

void Component::emitAdded()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit added();
}

void Component::emitTransformHasChanged()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit transformHasChanged();
}

void Component::emitChanged()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit changed();
}

void Component::emitDeleted()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
  emit deleted();
}

void Component::componentParameterHasChanged()
{
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Component::getParameterDisplayString
 * Reads the parameters of the component.\n
 * Returns the parameter string which can be either R=%R or %R.
 * \param parameterString - the parameter string to look for.
 * \return the parameter string with value.
 */
QString Component::getParameterDisplayString(QString parameterName)
{
  /* How to get the display value,
   * 0. If the component is inherited component then check if the value is available in the class extends modifiers.
   * 1. Check if the value is available in component modifier.
   * 2. Check if the value is available in the component's class as a parameter or variable.
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
  if (isInheritedComponent() && mpReferenceComponent) {
    QString extendsClass = mpReferenceComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
    displayString = mpGraphicsView->getModelWidget()->getExtendsModifiersMap(extendsClass).value(QString("%1.%2").arg(getName()).arg(parameterName), "");
  }
  /* case 1 */
  if (displayString.isEmpty()) {
    displayString = mpComponentInfo->getModifiersMap(pOMCProxy, className, this).value(parameterName, "");
  }
  /* case 2 or check for enumeration type if case 1 */
  if (displayString.isEmpty() || typeName.isEmpty()) {
    if (mpLibraryTreeItem) {
      mpLibraryTreeItem->getModelWidget()->loadDiagramView();
      foreach (Component *pComponent, mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
        if (pComponent->getComponentInfo()->getName().compare(parameterName) == 0) {
          if (displayString.isEmpty()) {
            displayString = pComponent->getComponentInfo()->getParameterValue(pOMCProxy, mpLibraryTreeItem->getNameStructure());
          }
          typeName = pComponent->getComponentInfo()->getClassName();
          checkEnumerationDisplayString(displayString, typeName);
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
 * \brief Component::shapeAdded
 * Called when a reference shape is added in its actual class.
 */
void Component::shapeAdded()
{
  mpNonExistingComponentLine->setVisible(false);
  if (mComponentType == Component::Root) {
    mpDefaultComponentRectangle->setVisible(false);
    mpDefaultComponentText->setVisible(false);
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Component::shapeUpdated
 * Called when a reference shape is updated in its actual class.
 */
void Component::shapeUpdated()
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Component::shapeDeleted
 * Called when a reference shape is deleted in its actual class.
 */
void Component::shapeDeleted()
{
  mpNonExistingComponentLine->setVisible(false);
  if (mComponentType == Component::Root) {
    mpDefaultComponentRectangle->setVisible(false);
    mpDefaultComponentText->setVisible(false);
  }
  showNonExistingOrDefaultComponentIfNeeded();
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Component::renameComponentInConnections
 * Called when OMCProxy::renameComponentInClass() is used. Updates the components name in connections list.\n
 * So that next OMCProxy::updateConnection() uses the new name. Ticket #3683.
 * \param newName
 */
void Component::renameComponentInConnections(QString newName)
{
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    return;
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
    // update start component name
    Component *pStartComponent = pConnectionLineAnnotation->getStartComponent();
    if (pStartComponent->getRootParentComponent() == this) {
      QString startComponentName = pConnectionLineAnnotation->getStartComponentName();
      startComponentName.replace(getName(), newName);
      pConnectionLineAnnotation->setStartComponentName(startComponentName);
      pConnectionLineAnnotation->updateToolTip();
    }
    // update end component name
    Component *pEndComponent = pConnectionLineAnnotation->getEndComponent();
    if (pEndComponent->getRootParentComponent() == this) {
      QString endComponentName = pConnectionLineAnnotation->getEndComponentName();
      endComponentName.replace(getName(), newName);
      pConnectionLineAnnotation->setEndComponentName(endComponentName);
      pConnectionLineAnnotation->updateToolTip();
    }
  }
}

/*!
 * \brief Component::insertInterfacePoint
 * Inserts a new interface point.
 * \param interfaceName
 */
void Component::insertInterfacePoint(QString interfaceName, QString position, QString angle321, int dimensions, QString causality, QString domain)
{
  ComponentInfo *pComponentInfo = new ComponentInfo;
  pComponentInfo->setName(interfaceName);
  pComponentInfo->setPosition(position);
  pComponentInfo->setAngle321(angle321);
  pComponentInfo->setDimensions(dimensions);
  pComponentInfo->setTLMCausality(causality);
  pComponentInfo->setDomain(domain);
  mComponentsList.append(new Component(pComponentInfo, this));
  adjustInterfacePoints();
}

void Component::removeInterfacePoint(QString interfaceName)
{
  foreach (Component *pComponent, mComponentsList) {
    if (pComponent->getName().compare(interfaceName) == 0) {
      mComponentsList.removeOne(pComponent);
      pComponent->deleteLater();
      break;
    }
  }
  adjustInterfacePoints();
}

/*!
 * \brief Component::adjustInterfacePoints
 * Dynamically adjusts the size of interface points.
 */
void Component::adjustInterfacePoints()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    if (!mComponentsList.isEmpty()) {
      // we start with default size of 30
      int interfacePointSize = 30;
      // keep the separator size to 1/3.
      int interfacePointSeparatorSize = (interfacePointSize / 3);
      // 200 is the maximum height of submodel
      while (200 <= mComponentsList.size() * (interfacePointSize + interfacePointSeparatorSize)) {
        interfacePointSize -= 1;
        if (interfacePointSize <= 0) {
          interfacePointSize = 1;
          break;
        }
        interfacePointSeparatorSize = (interfacePointSize / 3);
      }
      // set the new transformation for each interface point.
      qreal yPosition = 100 - (interfacePointSize / 2);
      foreach (Component *pComponent, mComponentsList) {
        qreal xPosition = 100 + interfacePointSeparatorSize;
        QString transformation = QString("Placement(true,%1,%2,-%3,-%3,%3,%3,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0)").arg(xPosition).arg(yPosition)
            .arg(interfacePointSize / 2);
        yPosition -= (interfacePointSize + interfacePointSeparatorSize);
        pComponent->mTransformation.parseTransformationString(transformation, boundingRect().width(), boundingRect().height());
        pComponent->setTransform(pComponent->mTransformation.getTransformationMatrix());
      }
    }
  }
}

/*!
 * \brief Component::updateComponentTransformations
 * Creates a UpdateComponentTransformationsCommand and emits the Component::transformChanging() SIGNAL.
 * \param oldTransformation
 */
void Component::updateComponentTransformations(const Transformation &oldTransformation)
{
  mpGraphicsView->getModelWidget()->beginMacro("Update component transformations");
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateComponentTransformationsCommand(this, oldTransformation, mTransformation));
  emit transformChanging();
  mpGraphicsView->getModelWidget()->endMacro();
}

/*!
 * \brief Component::handleOMSComponentDoubleClick
 * Handles the mouse double click for OMS component.
 */
void Component::handleOMSComponentDoubleClick()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSBusConnector()) {
    AddBusDialog *pAddBusDialog = new AddBusDialog(QList<Component*>(), mpLibraryTreeItem, mpGraphicsView);
    pAddBusDialog->exec();
  } else if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSTLMBusConnector()) {
    AddTLMBusDialog *pAddTLMBusDialog = new AddTLMBusDialog(QList<Component*>(), mpLibraryTreeItem, mpGraphicsView);
    pAddTLMBusDialog->exec();
  } else if (mpLibraryTreeItem && (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement())) {
    showElementPropertiesDialog();
  }
}

/*!
 * \brief Component::setBusComponent
 * Sets the bus component.
 * \param pBusComponent
 */
void Component::setBusComponent(Component *pBusComponent)
{
  mpBusComponent = pBusComponent;
  setVisible(!isInBus());
}

/*!
 * \brief Component::createNonExistingComponent
 * Creates a non-existing component.
 */
void Component::createNonExistingComponent()
{
  mpNonExistingComponentLine = new LineAnnotation(this);
  mpNonExistingComponentLine->setVisible(false);
}

/*!
 * \brief Component::createDefaultComponent
 * Creates a default component.
 */
void Component::createDefaultComponent()
{
  mpDefaultComponentRectangle = new RectangleAnnotation(this);
  mpDefaultComponentRectangle->setVisible(false);
  mpDefaultComponentText = new TextAnnotation(this);
  mpDefaultComponentText->setVisible(false);
}

/*!
 * \brief Component::createStateComponent
 * Creates a state component.
 */
void Component::createStateComponent()
{
  mpStateComponentRectangle = new RectangleAnnotation(this);
  mpStateComponentRectangle->setVisible(false);
  // create a state rectangle
  mpStateComponentRectangle->setLineColor(QColor(95, 95, 95));
  mpStateComponentRectangle->setLinePattern(StringHandler::LineDash);
  mpStateComponentRectangle->setRadius(40);
  mpStateComponentRectangle->setFillColor(QColor(255, 255, 255));
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  mpStateComponentRectangle->setExtents(extents);
}

/*!
 * \brief Component::drawInterfacePoints
 * Draws the interface points of the submodel component.
 */
void Component::drawInterfacePoints()
{
  CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
  if (pCompositeModelEditor) {
    QDomNodeList subModels = pCompositeModelEditor->getSubModels();
    for (int i = 0; i < subModels.size(); i++) {
      QDomElement subModel = subModels.at(i).toElement();
      if (subModel.attribute("Name").compare(mpComponentInfo->getName()) == 0) {
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
 * \brief Component::drawComponent
 * Draws the Component.
 */
void Component::drawComponent()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    drawModelicaComponent();
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    drawOMSComponent();
  }
}

/*!
 * \brief Component::drawModelicaComponent
 * Draws the Modelica component.
 */
void Component::drawModelicaComponent()
{
  if (!mpLibraryTreeItem) { // if built in type e.g Real, Boolean etc.
    if (mComponentType == Component::Root) {
      mpDefaultComponentRectangle->setVisible(true);
      mpDefaultComponentText->setVisible(true);
    }
  } else if (mpLibraryTreeItem->isNonExisting()) { // if class is non existing
    mpNonExistingComponentLine->setVisible(true);
  } else {
    createClassInheritedComponents();
    createClassShapes();
    createClassComponents();
    showNonExistingOrDefaultComponentIfNeeded();
  }
}

/*!
 * \brief Component::drawOMSComponent
 * Draws the OMSimulator component.
 */
void Component::drawOMSComponent()
{
  if (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement()) {
    if (!mpLibraryTreeItem->getModelWidget()) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
    }
    // draw shapes first
    createClassShapes();
    // draw connectors now
    foreach (Component *pComponent, mpLibraryTreeItem->getModelWidget()->getIconGraphicsView()->getComponentsList()) {
      Component *pNewComponent = new Component(pComponent, this, getRootParentComponent());
      mComponentsList.append(pNewComponent);
    }
  } else if (mpLibraryTreeItem->getOMSConnector()) { // if component is a signal i.e., input/output
    if (mpLibraryTreeItem->getOMSConnector()->causality == oms_causality_input) {
      PolygonAnnotation *pInputPolygonAnnotation = new PolygonAnnotation(this);
      QList<QPointF> points;
      points << QPointF(-100.0, 100.0) << QPointF(100.0, 0.0) << QPointF(-100.0, -100.0) << QPointF(-100.0, 100.0);
      pInputPolygonAnnotation->setPoints(points);
      pInputPolygonAnnotation->setFillPattern(StringHandler::FillSolid);
      switch (mpLibraryTreeItem->getOMSConnector()->type) {
        case oms_signal_type_integer:
          pInputPolygonAnnotation->setLineColor(QColor(255,127,0));
          pInputPolygonAnnotation->setFillColor(QColor(255,127,0));
          break;
        case oms_signal_type_boolean:
          pInputPolygonAnnotation->setLineColor(QColor(255,0,255));
          pInputPolygonAnnotation->setFillColor(QColor(255,0,255));
          break;
        case oms_signal_type_string:
          qDebug() << "Component::drawOMSComponent oms_signal_type_string not implemented yet.";
          break;
        case oms_signal_type_enum:
          qDebug() << "Component::drawOMSComponent oms_signal_type_enum not implemented yet.";
          break;
        case oms_signal_type_bus:
          qDebug() << "Component::drawOMSComponent oms_signal_type_bus not implemented yet.";
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
      QList<QPointF> points;
      points << QPointF(-100.0, 100.0) << QPointF(100.0, 0.0) << QPointF(-100.0, -100.0) << QPointF(-100.0, 100.0);
      pOutputPolygonAnnotation->setPoints(points);
      pOutputPolygonAnnotation->setFillPattern(StringHandler::FillSolid);
      switch (mpLibraryTreeItem->getOMSConnector()->type) {
        case oms_signal_type_integer:
          pOutputPolygonAnnotation->setLineColor(QColor(255, 127, 0));
          pOutputPolygonAnnotation->setFillColor(QColor(255, 255, 255));
          break;
        case oms_signal_type_boolean:
          pOutputPolygonAnnotation->setLineColor(QColor(255, 0, 255));
          pOutputPolygonAnnotation->setFillColor(QColor(255, 255, 255));
          break;
        case oms_signal_type_string:
          qDebug() << "Component::drawOMSComponent oms_signal_type_string not implemented yet.";
          break;
        case oms_signal_type_enum:
          qDebug() << "Component::drawOMSComponent oms_signal_type_enum not implemented yet.";
          break;
        case oms_signal_type_bus:
          qDebug() << "Component::drawOMSComponent oms_signal_type_bus not implemented yet.";
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
    QList<QPointF> extents;
    extents << QPointF(-100, -100) << QPointF(100, 100);
    pBusRectangleAnnotation->setExtents(extents);
    pBusRectangleAnnotation->setLineColor(QColor(73, 151, 60));
    pBusRectangleAnnotation->setFillColor(QColor(73, 151, 60));
    pBusRectangleAnnotation->setFillPattern(StringHandler::FillSolid);
    mShapesList.append(pBusRectangleAnnotation);
  } else if (mpLibraryTreeItem->getOMSTLMBusConnector()) { // if component is a tlm bus
    RectangleAnnotation *pTLMBusRectangleAnnotation = new RectangleAnnotation(this);
    QList<QPointF> extents;
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
 * \brief Component::drawInheritedComponentsAndShapes
 * Draws the inherited components and their shapes.
 */
void Component::drawInheritedComponentsAndShapes()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    if (!mpLibraryTreeItem) { // if built in type e.g Real, Boolean etc.
      if (mComponentType == Component::Root) {
        assert(mpDefaultComponentRectangle);
        assert(mpDefaultComponentText);
        mpDefaultComponentRectangle->setVisible(true);
        mpDefaultComponentText->setVisible(true);
      }
    } else if (mpLibraryTreeItem->isNonExisting()) { // if class is non existing
      assert(mpNonExistingComponentLine);
      mpNonExistingComponentLine->setVisible(true);
    } else {
      createClassInheritedComponents();
      createClassShapes();
    }
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    if (mpReferenceComponent) {
      foreach (ShapeAnnotation *pShapeAnnotation, mpReferenceComponent->getShapesList()) {
        if (dynamic_cast<PolygonAnnotation*>(pShapeAnnotation)) {
          mShapesList.append(new PolygonAnnotation(pShapeAnnotation, this));
        } else if (dynamic_cast<RectangleAnnotation*>(pShapeAnnotation)) {
          mShapesList.append(new RectangleAnnotation(pShapeAnnotation, this));
        }
      }
    }
  }
}

/*!
 * \brief Component::showNonExistingOrDefaultComponentIfNeeded
 * Show non-existing or default Component if needed.
 */
void Component::showNonExistingOrDefaultComponentIfNeeded()
{
  mpNonExistingComponentLine->setVisible(false);
  if (mComponentType == Component::Root) {
    assert(mpDefaultComponentRectangle);
    assert(mpDefaultComponentText);
    mpDefaultComponentRectangle->setVisible(false);
    mpDefaultComponentText->setVisible(false);
  }
  if (!hasShapeAnnotation(this)) {
    if (hasNonExistingClass()) {
      assert(mpNonExistingComponentLine);
      mpNonExistingComponentLine->setVisible(true);
    } else if (mComponentType == Component::Root) {
      assert(mpDefaultComponentRectangle);
      assert(mpDefaultComponentText);
      mpDefaultComponentRectangle->setVisible(true);
      mpDefaultComponentText->setVisible(true);
    }
  }
}

/*!
 * \brief Component::createClassInheritedComponents
 * Creates a class inherited components.
 */
void Component::createClassInheritedComponents()
{
  if (!mpLibraryTreeItem->isNonExisting()) {
    if (!mpLibraryTreeItem->getModelWidget()) {
      MainWindow *pMainWindow = MainWindow::instance();
      pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
    }
    foreach (LibraryTreeItem *pLibraryTreeItem, mpLibraryTreeItem->getModelWidget()->getInheritedClassesList()) {
      mInheritedComponentsList.append(new Component(pLibraryTreeItem, this));
    }
  }
}

/*!
 * \brief Component::createClassShapes
 * Creates a class shapes.
 */
void Component::createClassShapes()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::Modelica) {
    if (!mpLibraryTreeItem->isNonExisting()) {
      if (!mpLibraryTreeItem->getModelWidget()) {
        MainWindow *pMainWindow = MainWindow::instance();
        pMainWindow->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(mpLibraryTreeItem, false);
      }
      GraphicsView *pGraphicsView = mpLibraryTreeItem->getModelWidget()->getIconGraphicsView();
      /* ticket:4505
         * Only use the diagram annotation when connector is inside the component instance.
         */
      if (mpLibraryTreeItem->isConnector() && mpGraphicsView->getViewType() == StringHandler::Diagram && canUseDiagramAnnotation()) {
        mpLibraryTreeItem->getModelWidget()->loadDiagramView();
        if (mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView()->hasAnnotation()) {
          pGraphicsView = mpLibraryTreeItem->getModelWidget()->getDiagramGraphicsView();
        }
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

void Component::createActions()
{
  // Parameters Action
  mpParametersAction = new QAction(Helper::parameters, mpGraphicsView);
  mpParametersAction->setStatusTip(tr("Shows the component parameters"));
  connect(mpParametersAction, SIGNAL(triggered()), SLOT(showParameters()));
  // Fetch interfaces action
  mpFetchInterfaceDataAction = new QAction(QIcon(":/Resources/icons/interface-data.svg"), Helper::fetchInterfaceData, mpGraphicsView);
  mpFetchInterfaceDataAction->setStatusTip(tr("Fetch interface data for this external model"));
  connect(mpFetchInterfaceDataAction, SIGNAL(triggered()), SLOT(fetchInterfaceData()));
  // Todo: Connect /robbr
  // Attributes Action
  mpAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpAttributesAction->setStatusTip(tr("Shows the component attributes"));
  connect(mpAttributesAction, SIGNAL(triggered()), SLOT(showAttributes()));
  // Open Class Action
  mpOpenClassAction = new QAction(QIcon(":/Resources/icons/model.svg"), Helper::openClass, mpGraphicsView);
  mpOpenClassAction->setStatusTip(Helper::openClassTip);
  connect(mpOpenClassAction, SIGNAL(triggered()), SLOT(openClass()));
  // View Documentation Action
  mpViewDocumentationAction = new QAction(QIcon(":/Resources/icons/info-icon.svg"), Helper::viewDocumentation, mpGraphicsView);
  mpViewDocumentationAction->setStatusTip(Helper::viewDocumentationTip);
  connect(mpViewDocumentationAction, SIGNAL(triggered()), SLOT(viewDocumentation()));
  // SubModel attributes Action
  mpSubModelAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpSubModelAttributesAction->setStatusTip(tr("Shows the submodel attributes"));
  connect(mpSubModelAttributesAction, SIGNAL(triggered()), SLOT(showSubModelAttributes()));
  // FMU Properties Action
  mpElementPropertiesAction = new QAction(Helper::properties, mpGraphicsView);
  mpElementPropertiesAction->setStatusTip(tr("Shows the Properties dialog"));
  connect(mpElementPropertiesAction, SIGNAL(triggered()), SLOT(showElementPropertiesDialog()));
}

void Component::createResizerItems()
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
  mpBottomLeftResizerItem->setPos(mapFromScene(x1, y1));
  mpBottomLeftResizerItem->setResizePosition(ResizerItem::BottomLeft);
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeComponent(QPointF)));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpBottomLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedComponent()));
  mpBottomLeftResizerItem->blockSignals(isSystemLibrary || isInheritedComponent() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Top left resizer
  mpTopLeftResizerItem = new ResizerItem(this);
  mpTopLeftResizerItem->setPos(mapFromScene(x1, y2));
  mpTopLeftResizerItem->setResizePosition(ResizerItem::TopLeft);
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeComponent(QPointF)));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpTopLeftResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedComponent()));
  mpTopLeftResizerItem->blockSignals(isSystemLibrary || isInheritedComponent() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Top Right resizer
  mpTopRightResizerItem = new ResizerItem(this);
  mpTopRightResizerItem->setPos(mapFromScene(x2, y2));
  mpTopRightResizerItem->setResizePosition(ResizerItem::TopRight);
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeComponent(QPointF)));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpTopRightResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedComponent()));
  mpTopRightResizerItem->blockSignals(isSystemLibrary || isInheritedComponent() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
  //Bottom Right resizer
  mpBottomRightResizerItem = new ResizerItem(this);
  mpBottomRightResizerItem->setPos(mapFromScene(x2, y1));
  mpBottomRightResizerItem->setResizePosition(ResizerItem::BottomRight);
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPressed(ResizerItem*)), SLOT(prepareResizeComponent(ResizerItem*)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemMoved(QPointF)), SLOT(resizeComponent(QPointF)));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemReleased()), SLOT(finishResizeComponent()));
  connect(mpBottomRightResizerItem, SIGNAL(resizerItemPositionChanged()), SLOT(resizedComponent()));
  mpBottomRightResizerItem->blockSignals(isSystemLibrary || isInheritedComponent() || isOMSConnector || isOMSBusConnecor || isOMSTLMBusConnecor);
}

void Component::getResizerItemsPositions(qreal *x1, qreal *y1, qreal *x2, qreal *y2)
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

void Component::showResizerItems()
{
  // show the origin item
  if (mTransformation.hasOrigin()) {
    mpOriginItem->setPos(mTransformation.getOrigin());
    mpOriginItem->setActive();
  }
  qreal x1, y1, x2, y2;
  getResizerItemsPositions(&x1, &y1, &x2, &y2);
  //Bottom left resizer
  mpBottomLeftResizerItem->setPos(mapFromScene(x1, y1));
  mpBottomLeftResizerItem->setActive();
  //Top left resizer
  mpTopLeftResizerItem->setPos(mapFromScene(x1, y2));
  mpTopLeftResizerItem->setActive();
  //Top Right resizer
  mpTopRightResizerItem->setPos(mapFromScene(x2, y2));
  mpTopRightResizerItem->setActive();
  //Bottom Right resizer
  mpBottomRightResizerItem->setPos(mapFromScene(x2, y1));
  mpBottomRightResizerItem->setActive();
}

void Component::hideResizerItems()
{
  mpOriginItem->setPassive();
  mpBottomLeftResizerItem->setPassive();
  mpTopLeftResizerItem->setPassive();
  mpTopRightResizerItem->setPassive();
  mpBottomRightResizerItem->setPassive();
}

void Component::getScale(qreal *sx, qreal *sy)
{
  qreal angle = mTransformation.getRotateAngle();
  if (transform().type() == QTransform::TxScale || transform().type() == QTransform::TxTranslate) {
    *sx = transform().m11() / (cos(angle * (M_PI / 180)));
    *sy = transform().m22() / (cos(angle * (M_PI / 180)));
  } else {
    *sx = transform().m12() / (sin(angle * (M_PI / 180)));
    *sy = -transform().m21() / (sin(angle * (M_PI / 180)));
  }
}

void Component::setOriginAndExtents()
{
  if (!mTransformation.hasOrigin()) {
    QPointF extent1, extent2;
    qreal sx, sy;
    getScale(&sx, &sy);
    extent1.setX(sx * boundingRect().left());
    extent1.setY(sy * boundingRect().top());
    extent2.setX(sx * boundingRect().right());
    extent2.setY(sy * boundingRect().bottom());
    mTransformation.setOrigin(scenePos());
    mTransformation.setExtent1(extent1);
    mTransformation.setExtent2(extent2);
  }
}

/*!
 * \brief Component::updateConnections
 * Updates the Component's connections.
 */
void Component::updateConnections()
{
  if ((!mpGraphicsView) || mpGraphicsView->getViewType() == StringHandler::Icon) {
    return;
  }
  foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
    // get start and end components
    QStringList startComponentList = pConnectionLineAnnotation->getStartComponentName().split(".");
    QStringList endComponentList = pConnectionLineAnnotation->getEndComponentName().split(".");
    // set the start component
    if ((startComponentList.size() > 1 && getName().compare(startComponentList.at(0)) == 0)) {
      QString startComponentName = startComponentList.at(1);
      if (startComponentName.contains("[")) {
        startComponentName = startComponentName.mid(0, startComponentName.indexOf("["));
      }
      pConnectionLineAnnotation->setStartComponent(mpGraphicsView->getModelWidget()->getConnectorComponent(this, startComponentName));
    }
    // set the end component
    if ((endComponentList.size() > 1 && getName().compare(endComponentList.at(0)) == 0)) {
      QString endComponentName = endComponentList.at(1);
      if (endComponentName.contains("[")) {
        endComponentName = endComponentName.mid(0, endComponentName.indexOf("["));
      }
      pConnectionLineAnnotation->setEndComponent(mpGraphicsView->getModelWidget()->getConnectorComponent(this, endComponentName));
    }
  }
}

/*!
 * \brief Component::getParameterDisplayStringFromExtendsModifiers
 * Gets the display string for Component from extends modifiers
 * \param parameterName
 * \return
 */
QString Component::getParameterDisplayStringFromExtendsModifiers(QString parameterName)
{
  QString displayString = "";
  /* Ticket:4204
   * Get the extends modifiers of the class not the inherited class.
   */
  if (mpLibraryTreeItem) {
    foreach (Component *pComponent, mInheritedComponentsList) {
      if (pComponent->getLibraryTreeItem()) {
        QMap<QString, QString> extendsModifiersMap = mpLibraryTreeItem->getModelWidget()->getExtendsModifiersMap(pComponent->getLibraryTreeItem()->getNameStructure());
        displayString = extendsModifiersMap.value(parameterName, "");
        if (!displayString.isEmpty()) {
          return displayString;
        }
      }
      displayString = pComponent->getParameterDisplayStringFromExtendsModifiers(parameterName);
      if (!displayString.isEmpty()) {
        return displayString;
      }
    }
  }
  return displayString;
}

/*!
 * \brief Component::getParameterDisplayStringFromExtendsParameters
 * Gets the display string for components from extends parameters.
 * \param parameterName
 * \param modifierString an existing extends modifier or an empty string
 * \return
 */
QString Component::getParameterDisplayStringFromExtendsParameters(QString parameterName, QString modifierString)
{
  QString displayString = modifierString;
  QString typeName = "";
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    if (pInheritedComponent->getLibraryTreeItem()) {
      if (!pInheritedComponent->getLibraryTreeItem()->getModelWidget()) {
        MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pInheritedComponent->getLibraryTreeItem(), false);
      }
      pInheritedComponent->getLibraryTreeItem()->getModelWidget()->loadDiagramView();
      foreach (Component *pComponent, pInheritedComponent->getLibraryTreeItem()->getModelWidget()->getDiagramGraphicsView()->getComponentsList()) {
        if (pComponent->getComponentInfo()->getName().compare(parameterName) == 0) {
          OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
          /* Ticket:4204
           * Look for the parameter value in the parameter containing class not in the parameter class.
           */
          if (pInheritedComponent->getLibraryTreeItem()) {
            if (displayString.isEmpty()) {
              displayString = pComponent->getComponentInfo()->getParameterValue(pOMCProxy, pInheritedComponent->getLibraryTreeItem()->getNameStructure());
            }
            typeName = pComponent->getComponentInfo()->getClassName();
            checkEnumerationDisplayString(displayString, typeName);
            if (!(displayString.isEmpty() || typeName.isEmpty())) {
              return displayString;
            }
          }
        }
      }
    }
    displayString = pInheritedComponent->getParameterDisplayStringFromExtendsParameters(parameterName, displayString);
    if (!(displayString.isEmpty() || typeName.isEmpty())) {
      return displayString;
    }
  }
  return displayString;
}

/*!
 * \brief Component::checkEnumerationDisplayString
 * Checks for enumeration type and shortens enumeration value.
 * Returns true if displayString was modified.
 * See ModelicaSpec 3.3, section 18.6.5.5, ticket:4084
 */
bool Component::checkEnumerationDisplayString(QString &displayString, const QString &typeName)
{
  if (displayString.startsWith(typeName + ".")) {
    displayString = displayString.right(displayString.length() - typeName.length() - 1);
    return true;
  }
  return false;
}

/*!
 * \brief Component::updateToolTip
 * Updates the Component's tooltip.
 */
void Component::updateToolTip()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS) {
    setToolTip(mpLibraryTreeItem->getTooltip());
  } else {
    QString comment = mpComponentInfo->getComment().replace("\\\"", "\"");
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    comment = pOMCProxy->makeDocumentationUriToFileName(comment);
    // since tooltips can't handle file:// scheme so we have to remove it in order to display images and make links work.
  #ifdef WIN32
    comment.replace("src=\"file:///", "src=\"");
  #else
    comment.replace("src=\"file://", "src=\"");
  #endif

    if ((mIsInheritedComponent || mComponentType == Component::Port) && mpReferenceComponent && !mpGraphicsView->isVisualizationView()) {
      setToolTip(tr("<b>%1</b> %2<br/>%3<br /><br />Component declared in %4").arg(mpComponentInfo->getClassName())
                 .arg(mpComponentInfo->getName()).arg(comment)
                 .arg(mpReferenceComponent->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure()));
    } else {
      setToolTip(tr("<b>%1</b> %2<br/>%3").arg(mpComponentInfo->getClassName()).arg(mpComponentInfo->getName()).arg(comment));
    }
  }
}

/*!
 * \brief Component::canUseDiagramAnnotation
 * If the component is a port component or has a port component as parent in the hirerchy
 * then we should not use the diagram annotation.
 * \return
 */
bool Component::canUseDiagramAnnotation()
{
  Component *pComponent = this;
  while (pComponent->getParentComponent()) {
    if (pComponent->getComponentType() == Component::Port) {
      return false;
    }
    pComponent = pComponent->getParentComponent();
  }
  return true;
}

void Component::updatePlacementAnnotation()
{
  // Add component annotation.
  LibraryTreeItem *pLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pLibraryTreeItem->getLibraryType()== LibraryTreeItem::CompositeModel) {
    CompositeModelEditor *pCompositeModelEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
    pCompositeModelEditor->updateSubModelPlacementAnnotation(mpComponentInfo->getName(), mTransformation.getVisible()? "true" : "false",
                                                        getTransformationOrigin(), getTransformationExtent(),
                                                        QString::number(mTransformation.getRotateAngle()));
  } else if (pLibraryTreeItem->getLibraryType()== LibraryTreeItem::OMS) {
    if (mpLibraryTreeItem && mpLibraryTreeItem->getOMSElement()) {
      ssd_element_geometry_t elementGeometry = mpLibraryTreeItem->getOMSElementGeometry();
      QPointF extent1 = mTransformation.getExtent1();
      QPointF extent2 = mTransformation.getExtent2();
      if (mTransformation.hasOrigin()) {
        extent1.setX(extent1.x() + mTransformation.getOrigin().x());
        extent1.setY(extent1.y() + mTransformation.getOrigin().y());
        extent2.setX(extent2.x() + mTransformation.getOrigin().x());
        extent2.setY(extent2.y() + mTransformation.getOrigin().y());
      }
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
      Component *pComponent = pGraphicsView->getComponentObject(getName());
      if (pComponent) {
        pComponent->mTransformation.setOrigin(mTransformation.getOrigin());
        pComponent->setTransform(pComponent->mTransformation.getTransformationMatrix());
        /* Disconnect the signal so we don't go into the recursion for updatePlacementAnnotation();
         * Connect again after emitting the signal.
         */
        disconnect(pComponent, SIGNAL(transformHasChanged()), pComponent, SLOT(updatePlacementAnnotation()));
        pComponent->emitTransformHasChanged();
        connect(pComponent, SIGNAL(transformHasChanged()), pComponent, SLOT(updatePlacementAnnotation()));
      }
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
    }
  } else {
    OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
    pOMCProxy->updateComponent(mpComponentInfo->getName(), mpComponentInfo->getClassName(),
                               mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), getPlacementAnnotation());
  }
  /* When something is changed in the icon layer then update the LibraryTreeItem in the Library Browser */
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Component::updateOriginItem
 * Slot that updates the position of the component OriginItem.
 */
void Component::updateOriginItem()
{
  if (mTransformation.hasOrigin()) {
    mpOriginItem->setPos(mTransformation.getOrigin());
  }
}

/*!
 * \brief Component::handleLoaded
 * Slot activated when LibraryTreeItem::loaded() SIGNAL is raised.
 * Redraws the Component and updates its connections accordingly.
 */
void Component::handleLoaded()
{
  Component *pComponent = getRootParentComponent();
  pComponent->removeChildren();
  pComponent->drawComponent();
  pComponent->emitChanged();
  pComponent->updateConnections();
}

/*!
 * \brief Component::handleUnloaded
 * Slot activated when LibraryTreeItem::unLoaded() SIGNAL is raised.
 * Removes the Component and updates its connections accordingly.
 */
void Component::handleUnloaded()
{
  removeChildren();
  showNonExistingOrDefaultComponentIfNeeded();
  emitDeleted();
  Component *pComponent = getRootParentComponent();
  pComponent->updateConnections();
}

/*!
 * \brief Component::handleShapeAdded
 * Slot activated when a new shape is added to Component's class and LibraryTreeItem::shapeAdded() SIGNAL is raised.
 */
void Component::handleShapeAdded()
{
  Component *pComponent = getRootParentComponent();
  pComponent->removeChildren();
  pComponent->drawComponent();
  pComponent->emitChanged();
  pComponent->updateConnections();
}

void Component::handleComponentAdded()
{
  Component *pComponent = getRootParentComponent();
  pComponent->removeChildren();
  pComponent->drawComponent();
  pComponent->emitChanged();
  pComponent->updateConnections();
}

/*!
 * \brief Component::handleNameChanged
 * Handles the name change of OMSimulator elements.
 */
void Component::handleNameChanged()
{
  if (mpComponentInfo) {
    // we should update connections associated with this component before updating the component name
    renameComponentInConnections(mpLibraryTreeItem->getName());
    mpComponentInfo->setName(mpLibraryTreeItem->getName());
    mpComponentInfo->setClassName(mpLibraryTreeItem->getNameStructure());
  }
  updateToolTip();
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Component::referenceComponentAdded
 * Adds the referenced components when reference component is added.
 */
void Component::referenceComponentAdded()
{
  if (mComponentType == Component::Port) {
    setVisible(true);
    if (mpReferenceComponent && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpBusComponent = mpReferenceComponent->getBusComponent();
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
      if (pConnectionLineAnnotation->getStartComponentName().compare(mpLibraryTreeItem->getNameStructure()) == 0) {
        pConnectionLineAnnotation->setStartComponent(this);
        pConnectionLineAnnotation->updateStartPoint(mapToScene(boundingRect().center()));
        pConnectionLineAnnotation->setVisible(true);
      }
      // if end connector moved out of bus
      if (pConnectionLineAnnotation->getEndComponentName().compare(mpLibraryTreeItem->getNameStructure()) == 0) {
        pConnectionLineAnnotation->setEndComponent(this);
        pConnectionLineAnnotation->updateEndPoint(mapToScene(boundingRect().center()));
        pConnectionLineAnnotation->setVisible(true);
      }
    }
  }
}

/*!
 * \brief Component::referenceComponentTransformHasChanged
 * Updates the referenced components when reference component transform has changed.
 */
void Component::referenceComponentTransformHasChanged()
{
  Component *pComponent = qobject_cast<Component*>(sender());
  if (pComponent) {
    mTransformation.updateTransformation(pComponent->mTransformation);
    setTransform(mTransformation.getTransformationMatrix());
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  }
}

/*!
 * \brief Component::referenceComponentChanged
 * Updates the referenced components when reference component is changed.
 */
void Component::referenceComponentChanged()
{
  removeChildren();
  drawComponent();
  emitChanged();
  updateConnections();
}

/*!
 * \brief Component::referenceComponentDeleted
 * Delets the referenced components when reference component is deleted.
 */
void Component::referenceComponentDeleted()
{
  if (mComponentType == Component::Port) {
    setVisible(false);
    if (mpReferenceComponent && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
      mpBusComponent = mpReferenceComponent->getBusComponent();
    }
  } else {
    mpGraphicsView->removeItem(this);
    mpGraphicsView->removeItem(mpOriginItem);
  }
  if (mpGraphicsView->getViewType() == StringHandler::Icon) {
    mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
  } else if (isInBus() && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
    foreach (LineAnnotation *pConnectionLineAnnotation, mpGraphicsView->getConnectionsList()) {
      // if start connector and end connector is bus
      if (((pConnectionLineAnnotation->getStartComponentName().compare(mpLibraryTreeItem->getNameStructure()) == 0)
           && pConnectionLineAnnotation->getEndComponent()->getLibraryTreeItem()->getOMSBusConnector())) {
        Component *pStartBusConnector = mpGraphicsView->getModelWidget()->getConnectorComponent(pConnectionLineAnnotation->getStartComponent()->getRootParentComponent(),
                                                                                                mpBusComponent->getName());
        pConnectionLineAnnotation->setStartComponent(pStartBusConnector);
        pConnectionLineAnnotation->setVisible(false);
      }
      // if end connector and start connector is bus
      if ((pConnectionLineAnnotation->getEndComponentName().compare(mpLibraryTreeItem->getNameStructure()) == 0)
          && pConnectionLineAnnotation->getStartComponent()->getLibraryTreeItem()->getOMSBusConnector()) {
        Component *pEndBusConnector = mpGraphicsView->getModelWidget()->getConnectorComponent(pConnectionLineAnnotation->getEndComponent()->getRootParentComponent(),
                                                                                              mpBusComponent->getName());
        pConnectionLineAnnotation->setEndComponent(pEndBusConnector);
        pConnectionLineAnnotation->setVisible(false);
      }
    }
  }
}

/*!
 * \brief Component::prepareResizeComponent
 * Slot is activated when ResizerItem::resizerItemPressed() SIGNAL is raised.
 * \param pResizerItem
 */
void Component::prepareResizeComponent(ResizerItem *pResizerItem)
{
  prepareGeometryChange();
  mOldTransformation = mTransformation;
  mpSelectedResizerItem = pResizerItem;
  mTransform = transform();
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
  mpResizerRectangle->setRect(boundingRect()); //Sets the current item to the temporary rect
  mpResizerRectangle->setTransform(transform()); //Set the same matrix of this item to the temporary item
  mpResizerRectangle->setPos(pos());
}

/*!
 * \brief Component::resizeComponent
 * Slot is activated when ResizerItem::resizerItemMoved() SIGNAL is raised.
 * \param newPosition
 */
void Component::resizeComponent(QPointF newPosition)
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
  mXFactor = 0;
  mYFactor = 0;
  mXFactor = xDistance / mSceneBoundingRect.width();
  mYFactor = yDistance / mSceneBoundingRect.height();
  mXFactor = 1 + mXFactor;
  mYFactor = 1 + mYFactor;
  // if preserveAspectRatio is true then resize equally
  CoOrdinateSystem coOrdinateSystem = getCoOrdinateSystem();
  if (coOrdinateSystem.getPreserveAspectRatio()) {
    qreal factor = qMax(fabs(mXFactor), fabs(mYFactor));
    mXFactor = mXFactor < 0 ? factor * -1 : factor;
    mYFactor = mYFactor < 0 ? factor * -1 : factor;
  }
  // Apply the transformation to the temporary polygon using the new scaling factors
  QPointF pivot = mPivotPoint - pos();
  // Creates a temporaty transformation
  QTransform tmpTransform = QTransform().translate(pivot.x(), pivot.y()).rotate(0)
      .scale(mXFactor, mYFactor)
      .translate(-pivot.x(), -pivot.y());
  mpResizerRectangle->setTransform(mTransform * tmpTransform); //Multiplies the previous transform * the temporary
  setTransform(mTransform * tmpTransform);
  // set the final resize on component.
  QPointF extent1, extent2;
  qreal sx, sy;
  getScale(&sx, &sy);
  extent1.setX(sx * boundingRect().left());
  extent1.setY(sy * boundingRect().top());
  extent2.setX(sx * boundingRect().right());
  extent2.setY(sy * boundingRect().bottom());
  mTransformation.setOrigin(scenePos());
  mTransformation.setExtent1(extent1);
  mTransformation.setExtent2(extent2);
  setTransform(mTransformation.getTransformationMatrix());
  // let connections know that component has changed.
  emit transformChange();
}

/*!
 * \brief Component::finishResizeComponent
 * Slot is activated when ResizerItem resizerItemReleased SIGNAL is raised.
 */
void Component::finishResizeComponent()
{
  if (isSelected()) {
    showResizerItems();
  } else {
    setSelected(true);
  }
}

/*!
 * \brief Component::resizedComponent
 * Slot is activated when ResizerItem resizerItemPositionChanged SIGNAL is raised.
 */
void Component::resizedComponent()
{
  updateComponentTransformations(mOldTransformation);
  mpGraphicsView->getModelWidget()->updateModelText();
}

/*!
 * \brief Component::componentCommentHasChanged
 * Updates the Component's tooltip when the component comment has changed.
 */
void Component::componentCommentHasChanged()
{
  updateToolTip();
  update();
}

/*!
 * \brief Component::componentNameHasChanged
 * Updates the Component's tooltip when the component name has changed. Emits displayTextChanged signal.
 */
void Component::componentNameHasChanged()
{
  updateToolTip();
  displayTextChangedRecursive();
  update();
}

/*!
 * \brief Component::displayTextChangedRecursive
 * Notifies all the TextAnnotation's about the name change.
 */
void Component::displayTextChangedRecursive()
{
  emit displayTextChanged();
  foreach (Component *pInheritedComponent, mInheritedComponentsList) {
    pInheritedComponent->displayTextChangedRecursive();
  }
}

/*!
 * \brief Component::deleteMe
 * Deletes the Component from the current view.
 */
void Component::deleteMe()
{
  // delete the component from model
  mpGraphicsView->deleteComponent(this);
}

/*!
 * \brief Component::duplicate
 * Duplicates the Component.
 */
void Component::duplicate()
{
  MainWindow *pMainWindow = MainWindow::instance();
  QString name;
  if (mpLibraryTreeItem) {
    // get the model defaultComponentName
    QString defaultName = pMainWindow->getOMCProxy()->getDefaultComponentName(mpLibraryTreeItem->getNameStructure());
    if (defaultName.isEmpty()) {
      name = mpGraphicsView->getUniqueComponentName(StringHandler::toCamelCase(mpLibraryTreeItem->getName()));
    } else {
      if (mpGraphicsView->checkComponentName(defaultName)) {
        name = defaultName;
      } else {
        name = mpGraphicsView->getUniqueComponentName(defaultName);
      }
    }
  } else {
    name = mpGraphicsView->getUniqueComponentName(StringHandler::toCamelCase(getName()));
  }
  QPointF gridStep(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5, mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  // add component
  ComponentInfo *pComponentInfo = new ComponentInfo(mpComponentInfo);
  pComponentInfo->setName(name);
  mpGraphicsView->addComponentToView(name, mpLibraryTreeItem, getOMCPlacementAnnotation(gridStep), QPointF(0, 0), pComponentInfo, true, true);
  // set component modifiers and attributes for Diagram Layer component.
  Component *pDiagramComponent = mpGraphicsView->getModelWidget()->getDiagramGraphicsView()->getComponentsList().last();
  // save the old ComponentInfo
  ComponentInfo oldDiagramComponentInfo(pDiagramComponent->getComponentInfo());
  // Create a new ComponentInfo
  ComponentInfo newDiagramComponentInfo(mpComponentInfo);
  newDiagramComponentInfo.setName(oldDiagramComponentInfo.getName());
  UpdateComponentAttributesCommand *pUpdateDiagramComponentAttributesCommand;
  pUpdateDiagramComponentAttributesCommand = new UpdateComponentAttributesCommand(pDiagramComponent, oldDiagramComponentInfo,
                                                                                  newDiagramComponentInfo, true);
  mpGraphicsView->getModelWidget()->getUndoStack()->push(pUpdateDiagramComponentAttributesCommand);
  setSelected(false);
  if (mpGraphicsView->getViewType() == StringHandler::Diagram) {
    pDiagramComponent->setSelected(true);
  } else {
    Component *pIconComponent = mpGraphicsView->getModelWidget()->getIconGraphicsView()->getComponentsList().last();
    pIconComponent->setSelected(true);
  }
}

/*!
 * \brief Component::rotateClockwise
 * Rotates the component clockwise.
 */
void Component::rotateClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = -90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  showResizerItems();
}

/*!
 * \brief Component::rotateAntiClockwise
 * Rotates the Component anti clockwise.
 */
void Component::rotateAntiClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = 90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
  showResizerItems();
}

/*!
 * \brief Component::flipHorizontal
 * Flips the component horizontally.
 */
void Component::flipHorizontal()
{
  Transformation oldTransformation = mTransformation;
  setOriginAndExtents();
  QPointF extent1 = mTransformation.getExtent1();
  QPointF extent2 = mTransformation.getExtent2();
  // do the flipping based on the component angle.
  qreal angle = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  if ((angle >= 0 && angle < 90) || (angle >= 180 && angle < 270)) {
    mTransformation.setExtent1(QPointF(extent2.x(), extent1.y()));
    mTransformation.setExtent2(QPointF(extent1.x(), extent2.y()));
  } else if ((angle >= 90 && angle < 180) || (angle >= 270 && angle < 360)) {
    mTransformation.setExtent1(QPointF(extent1.x(), extent2.y()));
    mTransformation.setExtent2(QPointF(extent2.x(), extent1.y()));
  }
  updateComponentTransformations(oldTransformation);
  showResizerItems();
}

/*!
 * \brief Component::flipVertical
 * Flips the component vertically.
 */
void Component::flipVertical()
{
  Transformation oldTransformation = mTransformation;
  setOriginAndExtents();
  QPointF extent1 = mTransformation.getExtent1();
  QPointF extent2 = mTransformation.getExtent2();
  // do the flipping based on the component angle.
  qreal angle = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  if ((angle >= 0 && angle < 90) || (angle >= 180 && angle < 270)) {
    mTransformation.setExtent1(QPointF(extent1.x(), extent2.y()));
    mTransformation.setExtent2(QPointF(extent2.x(), extent1.y()));
  } else if ((angle >= 90 && angle < 180) || (angle >= 270 && angle < 360)) {
    mTransformation.setExtent1(QPointF(extent2.x(), extent1.y()));
    mTransformation.setExtent2(QPointF(extent1.x(), extent2.y()));
  }
updateComponentTransformations(oldTransformation);
  showResizerItems();
}

/*!
 * \brief Component::moveUp
 * Slot that moves component upwards depending on the grid step size value
 * \sa moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft(), moveCtrlRight()
 */
void Component::moveUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep());
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveShiftUp
 * Slot that moves component upwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveShiftUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveCtrlUp
 * Slot that moves component one pixel upwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveCtrlUp()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, 1);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveDown
 * Slot that moves component downwards depending on the grid step size value
 * \sa moveUp(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep());
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveShiftDown
 * Slot that moves component downwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveShiftDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -(mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5));
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveCtrlDown
 * Slot that moves component one pixel downwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveCtrlDown()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(0, -1);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveLeft
 * Slot that moves component leftwards depending on the grid step size value
 * \sa moveUp(), moveDown(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep(), 0);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveShiftLeft
 * Slot that moves component leftwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveShiftLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5), 0);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveCtrlLeft
 * Slot that moves component one pixel leftwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlRight()
 */
void Component::moveCtrlLeft()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(-1, 0);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveRight
 * Slot that moves component rightwards depending on the grid step size value
 * \sa moveUp(), moveDown(), moveLeft(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep(), 0);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveShiftRight
 * Slot that moves component rightwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void Component::moveShiftRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5, 0);
  updateComponentTransformations(oldTransformation);
}

/*!
 * \brief Component::moveCtrlRight
 * Slot that moves component one pixel rightwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlLeft()
 */
void Component::moveCtrlRight()
{
  Transformation oldTransformation = mTransformation;
  mTransformation.adjustPosition(1, 0);
  updateComponentTransformations(oldTransformation);
}

//! Slot that opens up the component parameters dialog.
//! @see showAttributes()
void Component::showParameters()
{
  MainWindow *pMainWindow = MainWindow::instance();
  if (pMainWindow->getOMCProxy()->isBuiltinType(mpComponentInfo->getClassName())) {
    return;
  }
  if (!mpLibraryTreeItem || mpLibraryTreeItem->isNonExisting()) {
    QMessageBox::critical(pMainWindow, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::error),
                          tr("Cannot show parameters window for component <b>%1</b>. Did not find type <b>%2</b>.").arg(getName())
                          .arg(mpComponentInfo->getClassName()), Helper::ok);
    return;
  }
  pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 parameters window").arg(mpLibraryTreeItem->getNameStructure()).arg(getName()));
  pMainWindow->getProgressBar()->setRange(0, 0);
  pMainWindow->showProgressBar();
  ComponentParameters *pComponentParameters = new ComponentParameters(this, pMainWindow);
  pMainWindow->hideProgressBar();
  pMainWindow->getStatusBar()->clearMessage();
  pComponentParameters->exec();
}

//! Slot that opens up the component attributes dialog.
//! @see showParameters()
void Component::showAttributes()
{
  MainWindow *pMainWindow = MainWindow::instance();
  pMainWindow->getStatusBar()->showMessage(tr("Opening %1 %2 attributes window").arg(mpLibraryTreeItem->getNameStructure())
                                           .arg(mpComponentInfo->getName()));
  pMainWindow->getProgressBar()->setRange(0, 0);
  pMainWindow->showProgressBar();
  ComponentAttributes *pComponentAttributes = new ComponentAttributes(this, pMainWindow);
  pMainWindow->hideProgressBar();
  pMainWindow->getStatusBar()->clearMessage();
  pComponentAttributes->exec();
}

void Component::fetchInterfaceData()
{
    MainWindow::instance()->fetchInterfaceData(mpGraphicsView->getModelWidget()->getLibraryTreeItem(), this->getName());
}

/*!
 * \brief Component::openClass
 * Slot that opens up the component Modelica class in a new tab/window.
 */
void Component::openClass()
{
  MainWindow::instance()->getLibraryWidget()->openLibraryTreeItem(mpLibraryTreeItem->getNameStructure());
}

//! Slot that opens up the component Modelica class in a documentation view.
void Component::viewDocumentation()
{
  MainWindow::instance()->getDocumentationWidget()->showDocumentation(mpLibraryTreeItem);
  bool state = MainWindow::instance()->getDocumentationDockWidget()->blockSignals(true);
  MainWindow::instance()->getDocumentationDockWidget()->show();
  MainWindow::instance()->getDocumentationDockWidget()->blockSignals(state);
}

/*!
 * \brief Component::showSubModelAttributes
 * Slot that opens up the CompositeModelSubModelAttributes Dialog.
 */
void Component::showSubModelAttributes()
{
  CompositeModelSubModelAttributes *pCompositeModelSubModelAttributes = new CompositeModelSubModelAttributes(this, MainWindow::instance());
  pCompositeModelSubModelAttributes->exec();
}

/*!
 * \brief Component::showElementPropertiesDialog
 * Slot that opens up the ElementPropertiesDialog Dialog.
 */
void Component::showElementPropertiesDialog()
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
      && (mpLibraryTreeItem->isSystemElement() || mpLibraryTreeItem->isComponentElement())) {
    ElementPropertiesDialog *pElementPropertiesDialog = new ElementPropertiesDialog(this, MainWindow::instance());
    pElementPropertiesDialog->exec();
  }
}

/*!
 * \brief Component::updateDynamicSelect
 * Slot activated when updateDynamicSelect SIGNAL is raised by VariablesWidget during the visualization of result file.
 * \param time
 */
void Component::updateDynamicSelect(double time)
{
  if (mpLibraryTreeItem && mpLibraryTreeItem->isState()) {
    double value = MainWindow::instance()->getVariablesWidget()->readVariableValue(getName() + ".active", time);
    setActiveState(value);
    foreach (LineAnnotation *pTransitionLineAnnotation, mpGraphicsView->getTransitionsList()) {
      if (pTransitionLineAnnotation->getEndComponent()->getName().compare(getName()) == 0) {
        pTransitionLineAnnotation->setActiveState(value);
      }
    }
  }
}

/*!
 * \brief Component::contextMenuEvent
 * Reimplementation of contextMenuEvent.\n
 * Creates a context menu for the component.\n
 * \param event
 */
void Component::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
  Component *pComponent = getRootParentComponent();
  if (pComponent->isSelected()) {
    pComponent->showResizerItems();
  } else {
    // unselect all items
    foreach (QGraphicsItem *pItem, mpGraphicsView->items()) {
      pItem->setSelected(false);
    }
    pComponent->setSelected(true);
  }

  // No context menu for component of type OMS connector i.e., input/output signal or OMS bus connector.
  if (mpLibraryTreeItem && mpLibraryTreeItem->getLibraryType() == LibraryTreeItem::OMS
      && (mpLibraryTreeItem->getOMSConnector()
          || mpLibraryTreeItem->getOMSBusConnector()
          || mpLibraryTreeItem->getOMSTLMBusConnector())) {
    return;
  }

  LibraryTreeItem *pLibraryTreeItem = mpGraphicsView->getModelWidget()->getLibraryTreeItem();
  if (pLibraryTreeItem) {
    QMenu menu(mpGraphicsView);
    switch (pLibraryTreeItem->getLibraryType()) {
      case LibraryTreeItem::Modelica:
      default:
        menu.addAction(pComponent->getParametersAction());
        menu.addAction(pComponent->getAttributesAction());
        menu.addSeparator();
        menu.addAction(pComponent->getOpenClassAction());
        menu.addAction(pComponent->getViewDocumentationAction());
        menu.addSeparator();
        menu.addAction(mpGraphicsView->getDuplicateAction());
        if (pComponent->isInheritedComponent()) {
          mpGraphicsView->getDeleteAction()->setDisabled(true);
          mpGraphicsView->getDuplicateAction()->setDisabled(true);
          mpGraphicsView->getRotateClockwiseAction()->setDisabled(true);
          mpGraphicsView->getRotateAntiClockwiseAction()->setDisabled(true);
          mpGraphicsView->getFlipHorizontalAction()->setDisabled(true);
          mpGraphicsView->getFlipVerticalAction()->setDisabled(true);
        }
        break;
      case LibraryTreeItem::CompositeModel:
        menu.addAction(pComponent->getFetchInterfaceDataAction());
        menu.addSeparator();
        menu.addAction(pComponent->getSubModelAttributesAction());
        break;
      case LibraryTreeItem::OMS:
        if (pComponent->getLibraryTreeItem()->isSystemElement() || pComponent->getLibraryTreeItem()->isComponentElement()) {
          menu.addAction(pComponent->getElementPropertiesAction());
        }
        break;
    }
    menu.addSeparator();
    menu.addAction(mpGraphicsView->getDeleteAction());
    menu.addSeparator();
    menu.addAction(mpGraphicsView->getRotateClockwiseAction());
    menu.addAction(mpGraphicsView->getRotateAntiClockwiseAction());
    menu.addAction(mpGraphicsView->getFlipHorizontalAction());
    menu.addAction(mpGraphicsView->getFlipVerticalAction());
    menu.exec(event->screenPos());
  }
}

QVariant Component::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);
  if (change == QGraphicsItem::ItemSelectedHasChanged) {
    if (isSelected()) {
      showResizerItems();
      setCursor(Qt::SizeAllCursor);
      // Only allow manipulations on component if the class is not a system library class OR component is not an inherited component.
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedComponent()) {
        connect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseDuplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseFlipHorizontal()), this, SLOT(flipHorizontal()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(mouseFlipVertical()), this, SLOT(flipVertical()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
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
      if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || isInheritedComponent()) {
        hideResizerItems();
      }
      unsetCursor();
      /* Only allow manipulations on component if the class is not a system library class OR component is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedComponent()) {
        disconnect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView, SIGNAL(mouseDuplicate()), this, SLOT(duplicate()));
        disconnect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()));
        disconnect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
        disconnect(mpGraphicsView, SIGNAL(mouseFlipHorizontal()), this, SLOT(flipHorizontal()));
        disconnect(mpGraphicsView, SIGNAL(mouseFlipVertical()), this, SLOT(flipVertical()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()));
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
    emit transformChange();
  }
  else if (change == QGraphicsItem::ItemPositionChange) {
    // move by grid distance while dragging component
    QPointF positionDifference = mpGraphicsView->movePointByGrid(value.toPointF() - pos(), mTransformation.getOrigin() + pos(), true);
    return pos() + positionDifference;
  }
  return value;
}
