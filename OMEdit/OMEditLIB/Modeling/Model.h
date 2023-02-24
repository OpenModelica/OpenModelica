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
#ifndef MODEL_H
#define MODEL_H

#include <QJsonArray>
#include <QJsonObject>
#include <QColor>
#include <QRectF>

#include "Annotations/BooleanAnnotation.h"
#include "Annotations/PointAnnotation.h"
#include "Annotations/RealAnnotation.h"
#include "Annotations/ColorAnnotation.h"
#include "Annotations/LinePatternAnnotation.h"
#include "Annotations/FillPatternAnnotation.h"
#include "Annotations/PointArrayAnnotation.h"
#include "Annotations/ArrowAnnotation.h"
#include "Annotations/SmoothAnnotation.h"
#include "Annotations/ExtentAnnotation.h"
#include "Annotations/BorderPatternAnnotation.h"
#include "Annotations/EllipseClosureAnnotation.h"
#include "Annotations/StringAnnotation.h"
#include "Annotations/TextStyleAnnotation.h"
#include "Annotations/TextAlignmentAnnotation.h"

namespace ModelInstance
{
  class CoordinateSystem
  {
  public:
    CoordinateSystem();
    CoordinateSystem(const CoordinateSystem &coOrdinateSystem);
    void setExtent(const QVector<QPointF> extent);
    ExtentAnnotation getExtent() const {return mExtent;}
    void setHasExtent(const bool hasExtent) {mHasExtent = hasExtent;}
    bool hasExtent() const {return mHasExtent;}
    void setPreserveAspectRatio(const bool preserveAspectRatio);
    BooleanAnnotation getPreserveAspectRatio() const {return mPreserveAspectRatio;}
    bool hasPreserveAspectRatio() const {return mHasPreserveAspectRatio;}
    void setHasPreserveAspectRatio(const bool hasPreserveAspectRatio) {mHasPreserveAspectRatio = hasPreserveAspectRatio;}
    void setInitialScale(const qreal initialScale);
    RealAnnotation getInitialScale() const {return mInitialScale;}
    bool hasInitialScale() const {return mHasInitialScale;}
    void setHasInitialScale(const bool hasInitialScale) {mHasInitialScale = hasInitialScale;}
    void setGrid(const QPointF grid);
    PointAnnotation getGrid() const {return mGrid;}
    void setHasGrid(const bool hasGrid) {mHasGrid = hasGrid;}
    bool hasGrid() const {return mHasGrid;}

    double getHorizontalGridStep();
    double getVerticalGridStep();
    QRectF getExtentRectangle() const;
    void reset();
    bool isComplete() const;
    void deserialize(const QJsonObject &jsonObject);

    CoordinateSystem& operator=(const CoordinateSystem &coOrdinateSystem) = default;
  private:
    ExtentAnnotation mExtent;
    bool mHasExtent;
    BooleanAnnotation mPreserveAspectRatio;
    bool mHasPreserveAspectRatio;
    RealAnnotation mInitialScale;
    bool mHasInitialScale;
    PointAnnotation mGrid;
    bool mHasGrid;
  };

  class GraphicItem
  {
  public:
    GraphicItem();
    BooleanAnnotation getVisible() const {return mVisible;}
    PointAnnotation getOrigin() const {return mOrigin;}
    RealAnnotation getRotation() const {return mRotation;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);
private:
    BooleanAnnotation mVisible;
    PointAnnotation mOrigin;
    RealAnnotation mRotation;
  };

  class FilledShape
  {
  public:
    FilledShape();
    ColorAnnotation getLineColor() const {return mLineColor;}
    ColorAnnotation getFillColor() const {return mFillColor;}
    LinePatternAnnotation getPattern() const {return mPattern;}
    FillPatternAnnotation getFillPattern() const {return mFillPattern;}
    RealAnnotation getLineThickness() const {return mLineThickness;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);
  private:
    ColorAnnotation mLineColor;
    ColorAnnotation mFillColor;
    LinePatternAnnotation mPattern;
    FillPatternAnnotation mFillPattern;
    RealAnnotation mLineThickness;
  };

  class Model;
  class Extend;
  class Shape : public GraphicItem, public FilledShape
  {
  public:
    Shape(Model *pParentModel);
    virtual ~Shape();

    Model *getParentModel() const {return mpParentModel;}
    Extend *getParentExtend() const;
  private:
    Model *mpParentModel;
  };

  class Line : public Shape
  {
  public:
    Line(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);

    void setPoints(const PointArrayAnnotation &points) {mPoints = points;}
    PointArrayAnnotation getPoints() const {return mPoints;}
    void clearPoints() {mPoints.clear();}
    void setColor(const QColor &color);
    ColorAnnotation getColor() const {return mColor;}
    void setPattern(StringHandler::LinePattern pattern) {mPattern = pattern;}
    LinePatternAnnotation getPattern() const {return mPattern;}
    void setThickness(double thickness) {mThickness = thickness;}
    RealAnnotation getThickness() const {return mThickness;}
    void setArrow(const ArrowAnnotation &arrow) {mArrow = arrow;}
    ArrowAnnotation getArrow() {return mArrow;}
    void setArrowSize(double arrowSize) {mArrowSize = arrowSize;}
    RealAnnotation getArrowSize() const {return mArrowSize;}
    void setSmooth(StringHandler::Smooth smooth) {mSmooth = smooth;}
    SmoothAnnotation getSmooth() const {return mSmooth;}
  private:
    PointArrayAnnotation mPoints;
    ColorAnnotation mColor;
    LinePatternAnnotation mPattern;
    RealAnnotation mThickness;
    ArrowAnnotation mArrow;
    RealAnnotation mArrowSize;
    SmoothAnnotation mSmooth;
  };

  class Polygon : public Shape
  {
  public:
    Polygon(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);

    PointArrayAnnotation getPoints() const {return mPoints;}
    SmoothAnnotation getSmooth() const {return mSmooth;}
  private:
    PointArrayAnnotation mPoints;
    SmoothAnnotation mSmooth;
  };

  class Rectangle : public Shape
  {
  public:
    Rectangle(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);

    BorderPatternAnnotation getBorderPattern() const {return mBorderPattern;}
    ExtentAnnotation getExtent() const {return mExtent;}
    RealAnnotation getRadius() const {return mRadius;}
  private:
    BorderPatternAnnotation mBorderPattern;
    ExtentAnnotation mExtent;
    RealAnnotation mRadius;
  };

  class Ellipse : public Shape
  {
  public:
    Ellipse(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);

    ExtentAnnotation getExtent() const {return mExtent;}
    RealAnnotation getStartAngle() const {return mStartAngle;}
    RealAnnotation getEndAngle() const {return mEndAngle;}
    EllipseClosureAnnotation getClosure() const {return mClosure;}
  private:
    ExtentAnnotation mExtent;
    RealAnnotation mStartAngle;
    RealAnnotation mEndAngle;
    EllipseClosureAnnotation mClosure;
  };

  class Text : public Shape
  {
  public:
    Text(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);

    ExtentAnnotation getExtent() const {return mExtent;}
    StringAnnotation getTextString() const {return mTextString;}
    RealAnnotation getFontSize() const {return mFontSize;}
    StringAnnotation getFontName() const {return mFontName;}
    TextStyleAnnotation getTextStyle() const {return mTextStyle;}
    ColorAnnotation getTextColor() const {return mTextColor;}
    TextAlignmentAnnotation getHorizontalAlignment() const {return mHorizontalAlignment;}
  private:
    ExtentAnnotation mExtent;
    StringAnnotation mTextString;
    RealAnnotation mFontSize;
    StringAnnotation mFontName;
    TextStyleAnnotation mTextStyle;
    ColorAnnotation mTextColor;
    TextAlignmentAnnotation mHorizontalAlignment;
  };

  class Bitmap : public Shape
  {
  public:
    Bitmap(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);

    ExtentAnnotation getExtent() const {return mExtent;}
    QString getFileName() const {return mFileName;}
    QString getImageSource() const {return mImageSource;}
  private:
    ExtentAnnotation mExtent;
    QString mFileName;
    QString mImageSource;
  };

  class IconDiagramAnnotation
  {
  public:
    IconDiagramAnnotation(Model *pParentModel);
    ~IconDiagramAnnotation();
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    QList<Shape*> getGraphics() const {return mGraphics;}
    bool isGraphicsEmpty() const {return mGraphics.isEmpty();}

    CoordinateSystem mCoordinateSystem;
    CoordinateSystem mMergedCoOrdinateSystem;
  private:
    Model *mpParentModel;
    QList<Shape*> mGraphics;
  };

  class Transformation
  {
  public:
    Transformation();
    void deserialize(const QJsonObject &jsonObject);
    PointAnnotation getOrigin() const {return mOrigin;}
    ExtentAnnotation getExtent() const {return mExtent;}
    double getRotation() const {return mRotation;}
  private:
    PointAnnotation mOrigin;
    ExtentAnnotation mExtent;
    RealAnnotation mRotation;
  };

  class PlacementAnnotation
  {
  public:
    PlacementAnnotation(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);
    Model *getParentModel() const {return mpParentModel;}
    BooleanAnnotation getVisible() const {return mVisible;}
    Transformation getTransformation() const {return mTransformation;}
    BooleanAnnotation getIconVisible() const {return mIconVisible;}
    Transformation getIconTransformation() const {return mIconTransformation;}
  private:
    Model *mpParentModel;
    BooleanAnnotation mVisible;
    Transformation mTransformation;
    BooleanAnnotation mIconVisible;
    Transformation mIconTransformation;
  };

  class Selector
  {
  public:
    Selector();
    void deserialize(const QJsonObject &jsonObject);
    StringAnnotation getFilter() const {return mFilter;}
    StringAnnotation getCaption() const {return mCaption;}
  private:
    StringAnnotation mFilter;
    StringAnnotation mCaption;
  };

  class DialogAnnotation
  {
  public:
    DialogAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    StringAnnotation getTab() const {return mTab;}
    StringAnnotation getGroup() const {return mGroup;}
    BooleanAnnotation isEnabled() const {return mEnable;}
    BooleanAnnotation getShowStartAttribute() const {return mShowStartAttribute;}
    BooleanAnnotation isColorSelector() const {return mColorSelector;}
    Selector getLoadSelector() const {return mLoadSelector;}
    Selector getSaveSelector() const {return mSaveSelector;}
    Selector getDirectorySelector() const {return mDirectorySelector;}
    QString getGroupImage() const {return mGroupImage;}
    BooleanAnnotation isConnectorSizing() const {return mConnectorSizing;}
  private:
    StringAnnotation mTab;
    StringAnnotation mGroup;
    BooleanAnnotation mEnable;
    BooleanAnnotation mShowStartAttribute;
    BooleanAnnotation mColorSelector;
    Selector mLoadSelector;
    Selector mSaveSelector;
    Selector mDirectorySelector;
    StringAnnotation mGroupImage;
    BooleanAnnotation mConnectorSizing;
  };

  class Choices
  {
  public:
    Choices();
    void deserialize(const QJsonObject &jsonObject);

    bool isCheckBox() const {return mCheckBox;}
    bool isDymolaCheckBox() const {return mDymolaCheckBox;}
    QStringList getChoices() const {return mChoice;}
  private:
    BooleanAnnotation mCheckBox;
    BooleanAnnotation mDymolaCheckBox;
    QStringList mChoice;
  };

  class IconDiagramMap
  {
  public:
    IconDiagramMap();
    void deserialize(const QJsonObject &jsonObject);

    ExtentAnnotation getExtent() const {return mExtent;}
    BooleanAnnotation getprimitivesVisible() const {return mPrimitivesVisible;}
  private:
    ExtentAnnotation mExtent;
    BooleanAnnotation mPrimitivesVisible;
  };

  class Annotation
  {
  public:
    Annotation(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    IconDiagramAnnotation *getIconAnnotation() const {return mpIconAnnotation.get();}
    IconDiagramAnnotation *getDiagramAnnotation() const {return mpDiagramAnnotation.get();}
    bool isDocumentationClass() const {return mDocumentationClass;}
    QString getVersion() const {return mVersion;}
    QString getVersionDate() const {return mVersionDate;}
    QString getDateModified() const {return mDateModified;}
    QString getPreferredView() const {return mPreferredView;}
    bool isState() const {return mState;}
    QString getAccess() const {return mAccess;}
    // Element annotation
    PlacementAnnotation getPlacementAnnotation() const {return mPlacementAnnotation;}
    bool hasDialogAnnotation() const {return mHasDialogAnnotation;}
    DialogAnnotation getDialogAnnotation() const {return mDialogAnnotation;}
    bool isEvaluate() const {return mEvaluate;}
    Choices getChoices() const {return mChoices;}
    // Connection annotation
    Line *getLine() const {return mpLine.get();}
    Text *getText() const {return mpText.get();}
    // Extend annotation
    IconDiagramMap getIconMap() const {return mIconMap;}
    IconDiagramMap getDiagramMap() const {return mDiagramMap;}
  private:
    Model *mpParentModel;
    std::unique_ptr<IconDiagramAnnotation> mpIconAnnotation;
    std::unique_ptr<IconDiagramAnnotation> mpDiagramAnnotation;
    BooleanAnnotation mDocumentationClass;
    StringAnnotation mVersion;
    StringAnnotation mVersionDate;
    RealAnnotation mVersionBuild;
    StringAnnotation mDateModified;
    StringAnnotation mPreferredView;
    BooleanAnnotation mState;
    StringAnnotation mAccess;
    // Element annotation
    BooleanAnnotation mChoicesAllMatching;
    PlacementAnnotation mPlacementAnnotation;
    bool mHasDialogAnnotation;
    DialogAnnotation mDialogAnnotation;
    BooleanAnnotation mEvaluate;
    Choices mChoices;
    // Connection annotation
    std::unique_ptr<Line> mpLine;
    std::unique_ptr<Text> mpText;
    // Extend annotation
    IconDiagramMap mIconMap;
    IconDiagramMap mDiagramMap;
  };

  class Modifier
  {
  public:
    Modifier();
    void deserialize(const QJsonValue &jsonValue);

    QString getName() const {return mName;}
    void setName(const QString &name) {mName = name;}
    QString getValue() const {return mValue;}
    QString getValueWithoutQuotes() const {return StringHandler::removeFirstLastQuotes(getValue());}
    QList<Modifier> getModifiers() const {return mModifiers;}
    bool isFinal() const {return mFinal;}
    bool isEach() const {return mEach;}
    QString getModifierValue(QStringList qualifiedModifierName);
  private:
    QString mName;
    QString mValue;
    bool mFinal;
    bool mEach;
    QList<Modifier> mModifiers;

    static QString getModifierValue(const Modifier &modifier, const QString &modifierName, QStringList qualifiedModifierName);
  };

  class Replaceable
  {
  public:
    Replaceable(Model *pParentModel);
    void deserialize(const QJsonValue &jsonValue);

    bool isReplaceable() const {return mIsReplaceable;}
    QString getConstrainedby() const {return mConstrainedby;}
    QString getComment() const {return mComment;}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
  private:
    Model *mpParentModel;
    bool mIsReplaceable;
    QString mConstrainedby;
    Modifier mModifier;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;
  };

  class Element;
  class Component;
  class Connection;
  class Transition;
  class InitialState;
  class Model
  {
  public:
    Model(const QJsonObject &jsonObject, Element *pParentElement = 0);
    virtual ~Model();
    void deserialize();

    Element *getParentElement() const {return mpParentElement;}
    Extend *getParentExtend() const;
    Component *getParentComponent() const;
    QJsonObject getModelJson() const {return mModelJson;}
    void setModelJson(const QJsonObject &modelJson) {mModelJson = modelJson;}
    QString getName() const {return mName;}
    QStringList getDims() const {return mDims;}
    QString getRestriction() const {return mRestriction;}
    Modifier getModifier() const {return mModifier;}
    bool isConnector() const;
    bool isExpandableConnector() const;
    bool isEnumeration() const;
    bool isType() const;
    bool isPublic() const {return mPublic;}
    bool isFinal() const {return mFinal;}
    bool isInner() const {return mInner;}
    bool isOuter() const {return mOuter;}
    bool isReplaceable() const {return mReplaceable;}
    bool isRedeclare() const {return mRedeclare;}
    bool isPartial() const {return mPartial;}
    bool isEncapsulated() const {return mEncapsulated;}
    QString getComment() const {return mComment;}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
    void readCoordinateSystemFromExtendsClass(CoordinateSystem *pCoordinateSystem, bool isIcon);
    void addElement(Element *pElement) {mElements.append(pElement);}
    QList<Element *> getElements() const {return mElements;}
    QString getFileName() const {return mFileName;}
    int getLineStart() const {return mLineStart;}
    int getColumnStart() const {return mColumnStart;}
    int getLineEnd() const {return mLineEnd;}
    int getColumnEnd() const {return mColumnEnd;}
    bool isReadonly() const {return mReadonly;}
    QList<Connection *> getConnections() const {return mConnections;}
    QList<Transition *> getTransitions() const {return mTransitions;}
    QList<InitialState *> getInitialStates() const {return mInitialStates;}

    bool isParameterConnectorSizing(const QString &parameter);
    QString getParameterValue(const QString &parameter, QString &typeName);
    QString getParameterValueFromExtendsModifiers(const QString &parameter);

    FlatModelica::Expression getVariableBinding(const QString &variableName);
  private:
    void initialize();

    Element *mpParentElement;
    QJsonObject mModelJson;
    QString mName;
    QStringList mDims;
    QString mRestriction;
    Modifier mModifier;
    bool mPublic;
    bool mFinal;
    bool mInner;
    bool mOuter;
    bool mReplaceable;
    bool mRedeclare;
    bool mPartial;
    bool mEncapsulated;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;
    QList<Element*> mElements;
    QString mFileName;
    int mLineStart;
    int mColumnStart;
    int mLineEnd;
    int mColumnEnd;
    bool mReadonly;
    QList<Connection*> mConnections;
    QList<Transition*> mTransitions;
    QList<InitialState*> mInitialStates;
  };

  class Element
  {
  public:
    Element(Model *pParentModel);
    virtual ~Element();

    Model *getParentModel() const {return mpParentModel;}
    void setModel(Model *pModel) {mpModel = pModel;}
    Model *getModel() const {return mpModel;}

    virtual QString getQualifiedName() const = 0;
    virtual bool isComponent() const = 0;
    virtual bool isExtend() const = 0;
  protected:
    Model *mpParentModel;
    Model *mpModel = 0;
  };

  class Component : public Element
  {
  public:
    Component(Model *pParentModel);
    Component(Model *pParentModel, const QJsonObject &jsonObject);
    void initialize();
    void deserialize(const QJsonObject &jsonObject);

    void setName(const QString &name) {mName = name;}
    QString getName() const {return mName;}
    bool getCondition() const {return mCondition;}
    void setType(const QString &type) {mType = type;}
    QString getType() const {return mType;}
    Modifier getModifier() const {return mModifier;}
    FlatModelica::Expression getBinding() const {return mBinding;}
    void setBinding(const FlatModelica::Expression expression) {mBinding = expression;}
    void resetBinding() {mBinding = mBindingForReset;}
    QString getModifierValueFromType(QStringList modifierName);
    QStringList getAbsynDimensions() const {return mAbsynDims;}
    QString getAbsynDimensionsString() const {return mAbsynDims.join(", ");}
    QStringList getTypedDimensions() const {return mTypedDims;}
    bool isArray() const {return !mTypedDims.isEmpty();}
    bool isPublic() const {return mPublic;}
    bool isFinal() const {return mFinal;}
    bool isInner() const {return mInner;}
    bool isOuter() const {return mOuter;}
    Replaceable *getReplaceable() const {return mpReplaceable.get();}
    bool isRedeclare() const {return mRedeclare;}
    QString getConnector() const {return mConnector;}
    QString getVariability() const {return mVariability;}
    QString getDirection() const {return mDirection;}
    QString getComment() const {return mComment;}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
  private:
    QString mName;
    bool mCondition;
    QString mType;

    Modifier mModifier;
    FlatModelica::Expression mBinding;
    FlatModelica::Expression mBindingForReset;
    QStringList mAbsynDims;
    QStringList mTypedDims;
    bool mPublic;
    bool mFinal;
    bool mInner;
    bool mOuter;
    std::unique_ptr<Replaceable> mpReplaceable;
    bool mRedeclare;
    QString mConnector;
    QString mVariability;
    QString mDirection;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;

    static QString getModifierValueFromInheritedType(Model *pModel, QStringList modifierName);
    // Element interface
  public:
    virtual QString getQualifiedName() const override;
    virtual bool isComponent() const override {return true;}
    virtual bool isExtend() const override {return false;}
  };

  class Extend : public Element
  {
  public:
    Extend(Model *pParentModel, const QJsonObject &jsonObject);
    void deserialize(const QJsonObject &jsonObject);

    Annotation *getExtendsAnnotation() const {return mpExtendsAnnotation.get();}
    Modifier getExtendsModifier() const {return mExtendsModifier;}
  private:
    std::unique_ptr<Annotation> mpExtendsAnnotation;
    Modifier mExtendsModifier;
    // Element interface
  public:
    virtual QString getQualifiedName() const override;
    virtual bool isComponent() const override {return false;}
    virtual bool isExtend() const override {return true;}
  };

  class Part
  {
  public:
    Part();
    void deserialize(const QJsonObject &jsonObject);

    QString getName() const;
  private:
    QString mName;
    QStringList mSubScripts;
  };

  class Connector
  {
  public:
    Connector();
    void deserialize(const QJsonObject &jsonObject);

    QString getName() const;
    QStringList getNameParts() const;
  private:
    QString mKind;
    QList<Part> mParts;
  };

  class Connection
  {
  public:
    Connection(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    Connector *getStartConnector() const {return mpStartConnector.get();}
    Connector *getEndConnector() const {return mpEndConnector.get();}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
    QString toString() const;
  private:
    Model *mpParentModel;
    std::unique_ptr<Connector> mpStartConnector;
    std::unique_ptr<Connector> mpEndConnector;
    std::unique_ptr<Annotation> mpAnnotation;
  };

  class Transition
  {
  public:
    Transition(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    Connector *getStartConnector() const {return mpStartConnector.get();}
    Connector *getEndConnector() const {return mpEndConnector.get();}
    bool getCondition() const {return mCondition;}
    bool getImmediate() const {return mImmediate;}
    bool getReset() const {return mReset;}
    bool getSynchronize() const {return mSynchronize;}
    int getPriority() const {return mPriority;}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
    QString toString() const;
  private:
    Model *mpParentModel;
    std::unique_ptr<Connector> mpStartConnector;
    std::unique_ptr<Connector> mpEndConnector;
    bool mCondition;
    bool mImmediate;
    bool mReset;
    bool mSynchronize;
    int mPriority;
    std::unique_ptr<Annotation> mpAnnotation;
  };

  class InitialState
  {
  public:
    InitialState(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    Connector *getStartConnector() const {return mpStartConnector.get();}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
    QString toString() const;
  private:
    Model *mpParentModel;
    std::unique_ptr<Connector> mpStartConnector;
    std::unique_ptr<Annotation> mpAnnotation;
  };

}

#endif // MODEL_H
