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
    const ExtentAnnotation& getExtent() const {return mExtent;}
    void setHasExtent(const bool hasExtent) {mHasExtent = hasExtent;}
    bool hasExtent() const {return mHasExtent;}
    void setPreserveAspectRatio(const bool preserveAspectRatio);
    const BooleanAnnotation& getPreserveAspectRatio() const {return mPreserveAspectRatio;}
    bool hasPreserveAspectRatio() const {return mHasPreserveAspectRatio;}
    void setHasPreserveAspectRatio(const bool hasPreserveAspectRatio) {mHasPreserveAspectRatio = hasPreserveAspectRatio;}
    void setInitialScale(const qreal initialScale);
    const RealAnnotation& getInitialScale() const {return mInitialScale;}
    bool hasInitialScale() const {return mHasInitialScale;}
    void setHasInitialScale(const bool hasInitialScale) {mHasInitialScale = hasInitialScale;}
    void setGrid(const QPointF grid);
    const PointAnnotation& getGrid() const {return mGrid;}
    void setHasGrid(const bool hasGrid) {mHasGrid = hasGrid;}
    bool hasGrid() const {return mHasGrid;}

    double getHorizontalGridStep();
    double getVerticalGridStep();
    QRectF getExtentRectangle() const;
    void reset();
    bool isComplete() const;
    void deserialize(const QJsonObject &jsonObject);

    CoordinateSystem& operator=(const CoordinateSystem &coOrdinateSystem) = default;
    CoordinateSystem& operator=(CoordinateSystem &&coOrdinateSystem) = default;
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
    const BooleanAnnotation &getVisible() const {return mVisible;}
    const PointAnnotation &getOrigin() const {return mOrigin;}
    const RealAnnotation &getRotation() const {return mRotation;}
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
    const ColorAnnotation &getLineColor() const {return mLineColor;}
    const ColorAnnotation &getFillColor() const {return mFillColor;}
    const LinePatternAnnotation &getPattern() const {return mPattern;}
    const FillPatternAnnotation &getFillPattern() const {return mFillPattern;}
    const RealAnnotation &getLineThickness() const {return mLineThickness;}
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
    virtual ~Shape() = default;

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

    void setPoints(PointArrayAnnotation points) {mPoints = std::move(points);}
    const PointArrayAnnotation &getPoints() const {return mPoints;}
    void clearPoints() {mPoints.clear();}
    void setColor(const QColor &color);
    const ColorAnnotation &getColor() const {return mColor;}
    void setPattern(StringHandler::LinePattern pattern) {mPattern = pattern;}
    const LinePatternAnnotation &getPattern() const {return mPattern;}
    void setThickness(double thickness) {mThickness = thickness;}
    const RealAnnotation &getThickness() const {return mThickness;}
    void setArrow(ArrowAnnotation arrow) {mArrow = std::move(arrow);}
    const ArrowAnnotation &getArrow() {return mArrow;}
    void setArrowSize(double arrowSize) {mArrowSize = arrowSize;}
    const RealAnnotation &getArrowSize() const {return mArrowSize;}
    void setSmooth(StringHandler::Smooth smooth) {mSmooth = smooth;}
    const SmoothAnnotation &getSmooth() const {return mSmooth;}
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

    const PointArrayAnnotation &getPoints() const {return mPoints;}
    const SmoothAnnotation &getSmooth() const {return mSmooth;}
  private:
    PointArrayAnnotation mPoints;
    SmoothAnnotation mSmooth;
  };

  class Rectangle : public Shape
  {
  public:
    Rectangle(Model *pParentModel);
    void deserialize(const QJsonArray &jsonArray);

    const BorderPatternAnnotation &getBorderPattern() const {return mBorderPattern;}
    const ExtentAnnotation &getExtent() const {return mExtent;}
    const RealAnnotation &getRadius() const {return mRadius;}
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

    const ExtentAnnotation &getExtent() const {return mExtent;}
    const RealAnnotation &getStartAngle() const {return mStartAngle;}
    const RealAnnotation &getEndAngle() const {return mEndAngle;}
    const EllipseClosureAnnotation &getClosure() const {return mClosure;}
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

    const ExtentAnnotation &getExtent() const {return mExtent;}
    const StringAnnotation &getTextString() const {return mTextString;}
    const RealAnnotation &getFontSize() const {return mFontSize;}
    const StringAnnotation &getFontName() const {return mFontName;}
    const TextStyleAnnotation &getTextStyle() const {return mTextStyle;}
    const ColorAnnotation &getTextColor() const {return mTextColor;}
    const TextAlignmentAnnotation &getHorizontalAlignment() const {return mHorizontalAlignment;}
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

    const ExtentAnnotation &getExtent() const {return mExtent;}
    const QString &getFileName() const {return mFileName;}
    const QString &getImageSource() const {return mImageSource;}
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
    CoordinateSystem mMergedCoordinateSystem;
  private:
    Model *mpParentModel;
    QList<Shape*> mGraphics;
  };

  class Transformation
  {
  public:
    Transformation();
    void deserialize(const QJsonObject &jsonObject);
    const PointAnnotation &getOrigin() const {return mOrigin;}
    const ExtentAnnotation &getExtent() const {return mExtent;}
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
    const BooleanAnnotation &getVisible() const {return mVisible;}
    const Transformation &getTransformation() const {return mTransformation;}
    const BooleanAnnotation &getIconVisible() const {return mIconVisible;}
    const Transformation &getIconTransformation() const {return mIconTransformation;}
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
    const StringAnnotation &getFilter() const {return mFilter;}
    const StringAnnotation &getCaption() const {return mCaption;}
  private:
    StringAnnotation mFilter;
    StringAnnotation mCaption;
  };

  class DialogAnnotation
  {
  public:
    DialogAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    const StringAnnotation &getTab() const {return mTab;}
    const StringAnnotation &getGroup() const {return mGroup;}
    const BooleanAnnotation &isEnabled() const {return mEnable;}
    const BooleanAnnotation &getShowStartAttribute() const {return mShowStartAttribute;}
    const BooleanAnnotation &isColorSelector() const {return mColorSelector;}
    const Selector &getLoadSelector() const {return mLoadSelector;}
    const Selector &getSaveSelector() const {return mSaveSelector;}
    const Selector &getDirectorySelector() const {return mDirectorySelector;}
    const QString &getGroupImage() const {return mGroupImage;}
    const BooleanAnnotation &isConnectorSizing() const {return mConnectorSizing;}
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

  class Modifier;
  class Choices
  {
  public:
    Choices(const QJsonObject &jsonObject, Model *pParentModel);
    ~Choices();
    void deserialize(const QJsonObject &jsonObject);

    bool isCheckBox() const {return mCheckBox;}
    bool isDymolaCheckBox() const {return mDymolaCheckBox;}
    const QList<Modifier*> &getChoices() const {return mChoices;}
    QStringList getChoicesValueStringList() const;
    QStringList getChoicesCommentStringList() const;
  private:
    Model *mpParentModel;
    BooleanAnnotation mCheckBox;
    BooleanAnnotation mDymolaCheckBox;
    QList<Modifier*> mChoices;
  };

  class IconDiagramMap
  {
  public:
    IconDiagramMap() = default;
    void deserialize(const QJsonObject &jsonObject);

    const ExtentAnnotation &getExtent() const {return mExtent;}
    bool hasExtent() const {return mHasExtent;}
    const BooleanAnnotation &getprimitivesVisible() const {return mPrimitivesVisible;}
  private:
    ExtentAnnotation mExtent = QVector<QPointF>(2, QPointF(0, 0));
    bool mHasExtent = false;
    BooleanAnnotation mPrimitivesVisible = true;
  };

  class ExperimentAnnotation
  {
  public:
    ExperimentAnnotation() = default;
    void deserialize(const QJsonObject &jsonObject);

    bool hasInterval() const {return mHasInterval;}
  private:
    //RealAnnotation mInterval = 0.2;
    bool mHasInterval = false;
  };

  class Annotation
  {
  public:
    Annotation(Model *pParentModel);
    ~Annotation();
    void deserialize(const QJsonObject &jsonObject);

    IconDiagramAnnotation *getIconAnnotation() const {return mpIconAnnotation.get();}
    IconDiagramAnnotation *getDiagramAnnotation() const {return mpDiagramAnnotation.get();}
    const BooleanAnnotation &isState() const {return mState;}
    // Element annotation
    const BooleanAnnotation &isChoicesAllMatching() const {return mChoicesAllMatching;}
    const PlacementAnnotation &getPlacementAnnotation() const {return mPlacementAnnotation;}
    bool hasDialogAnnotation() const {return mHasDialogAnnotation;}
    const DialogAnnotation &getDialogAnnotation() const {return mDialogAnnotation;}
    bool isEvaluate() const {return mEvaluate;}
    Choices *getChoices() const {return mpChoices;}
    // Connection annotation
    Line *getLine() const {return mpLine.get();}
    Text *getText() const {return mpText.get();}
    // Extend annotation
    const IconDiagramMap &getMap(bool icon) const;
    const ExperimentAnnotation &getExperimentAnnotation() const {return mExperimentAnnotation;}

    static Annotation defaultAnnotation;

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
    Choices *mpChoices = 0;
    // Connection annotation
    std::unique_ptr<Line> mpLine;
    std::unique_ptr<Text> mpText;
    // Extend annotation
    IconDiagramMap mIconMap;
    IconDiagramMap mDiagramMap;
    // experiment annotation
    ExperimentAnnotation mExperimentAnnotation;
  };

  class Dimensions
  {
  public:
    Dimensions();
    void deserialize(const QJsonObject &jsonObject);

    const QStringList &getAbsynDimensions() const {return mAbsynDims;}
    QString getAbsynDimensionsString(const QString &separator = ", ") const {return mAbsynDims.join(separator);}
    const QStringList &getTypedDimensions() const {return mTypedDims;}
    QString getTypedDimensionsString(const QString &separator = ", ") const {return mTypedDims.join(separator);}
    bool isArray() const {return !mTypedDims.isEmpty();}
  private:
    QStringList mAbsynDims;
    QStringList mTypedDims;
  };

  class Element;
  class Modifier
  {
  public:
    Modifier(const QString &name, const QJsonValue &jsonValue, Model *pParentModel);
    ~Modifier();
    void deserialize(const QJsonValue &jsonValue);

    Model* getParentModel() const {return mpParentModel;}
    const QString &getName() const {return mName;}
    void setName(const QString &newName) {mName = newName;}
    const QString &getType() const {return mType;}
    QString getValueWithoutQuotes() const {return StringHandler::removeFirstLastQuotes(getValue());}
    bool isValueDefined() const {return mValueDefined;}
    QString toString(bool skipTopLevel = false, bool includeComment = false) const;
    Modifier *getModifier(const QString &modifier) const;
    QPair<QString, bool> getModifierValue(const QString &modifier) const;
    bool hasModifier(const QString &modifier) const;
    const QList<Modifier*> &getModifiers() const {return mModifiers;}
    void addModifier(const Modifier *pModifier);
    bool isFinal() const {return mFinal;}
    bool isEach() const {return mEach;}
    bool isBreak() const;
    bool isRedeclare() const;
    bool isReplaceable() const;
    const QString &getValue() const {return mValue;}
    const QString &getComment() const {return mComment;}
    QPair<QString, bool> getModifierValue(QStringList qualifiedModifierName) const;
  private:
    Model *mpParentModel;
    QString mName;
    QString mType;
    bool mFinal = false;
    bool mEach = false;
    QString mValue;
    bool mValueDefined = false;
    QString mComment;
    Element *mpElement = 0;
    QList<Modifier*> mModifiers;

    QString toStringEach() const;
    QString toStringFinal() const;
    static QPair<QString, bool> getModifierValue(const Modifier *pModifier, const QString &modifierName, QStringList qualifiedModifierName);
  };

  class Replaceable
  {
  public:
    Replaceable(Model *pParentModel);
    ~Replaceable();
    void deserialize(const QJsonValue &jsonValue);

    Modifier *getModifier() const {return mpModifier;}
    const QString &getConstrainedby() const {return mConstrainedby;}
    const QString &getComment() const {return mComment;}
    Annotation *getAnnotation() const {return mpAnnotation.get();}
  private:
    Model *mpParentModel;
    QString mConstrainedby;
    Modifier *mpModifier = 0;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;
  };

  class Prefixes
  {
  public:
    Prefixes(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    bool isPublic() const {return mPublic;}
    bool isFinal() const {return mFinal;}
    bool isInner() const {return mInner;}
    bool isOuter() const {return mOuter;}
    Replaceable *getReplaceable() const {return mpReplaceable.get();}
    bool isRedeclare() const {return mRedeclare;}
    bool isPartial() const {return mPartial;}
    const QString &getConnector() const {return mConnector;}
    const QString &getVariability() const {return mVariability;}
    const QString &getDirection() const {return mDirection;}
    QString toString(bool skipTopLevel = false) const;
    QString typePrefixes() const;

  private:
    Model *mpParentModel;
    bool mPublic;
    bool mFinal;
    bool mInner;
    bool mOuter;
    std::unique_ptr<Replaceable> mpReplaceable;
    bool mRedeclare;
    bool mPartial;
    bool mEncapsulated;
    QString mConnector;
    QString mVariability;
    QString mDirection;
  };

  class Source
  {
  public:
    Source();
    void deserialize(const QJsonObject &jsonObject);

    const QString &getFileName() const {return mFileName;}
  private:
    QString mFileName;
    int mLineStart;
    int mColumnStart;
    int mLineEnd;
    int mColumnEnd;
    bool mReadonly;
  };

  class Component;
  class Import;
  class Connection;
  class Transition;
  class InitialState;
  class Name;
  class Model
  {
  public:
    Model(const QJsonObject &jsonObject, Element *pParentElement = 0);
    virtual ~Model();
    void deserialize();
    void deserializeElements(const QJsonArray elements);
    void updateMergedCoordinateSystem();

    Element *getParentElement() const {return mpParentElement;}
    Element *getRootParentElement() const;
    Extend *getParentExtend() const;
    Component *getParentComponent() const;
    bool isModelJsonEmpty() const {return mModelJson.isEmpty();}
    void setModelJson(const QJsonObject &modelJson) {mModelJson = modelJson;}
    const QString &getName() const {return mName;}
    const QString &getRootType() const;
    bool isMissing() const {return mMissing;}
    void setRestriction(const QString &restriction) {mRestriction = restriction;}
    const QString &getRestriction() const {return mRestriction;}
    bool isConnector() const;
    bool isExpandableConnector() const;
    bool isEnumeration() const;
    bool isRecord() const;
    bool isType() const;
    bool isDerivedType() const;
    bool isPartial() const;
    QString getDirection() const;
    QString getComment() const {return mComment;}
    Annotation *getAnnotation() const;
    void readCoordinateSystemFromExtendsClass(CoordinateSystem *pCoordinateSystem, bool isIcon);
    void addElement(Element *pElement) {mElements.append(pElement);}
    void removeElement(const QString &name);
    const QList<Element *> &getElements() const {return mElements;}
    QList<Element *> getComponents() const;
    size_t componentCount() const;
    const QList<Import> &getImports() const {return mImports;}
    const QList<Connection *> &getConnections() const {return mConnections;}
    const QList<Transition *> &getTransitions() const {return mTransitions;}
    const QList<InitialState *> &getInitialStates() const {return mInitialStates;}
    const Source &getSource() const {return mSource;}

    bool isParameterConnectorSizing(const QString &parameter);
    bool isValidConnection(const Name &lhsConnector, const Name &rhsConnector) const;
    bool isTypeCompatibleWith(const Model &other, bool lhsOutside, bool rhsOutside) const;
    QPair<QString, bool> getParameterValue(const QString &parameter, QString &typeName);
    QPair<QString, bool> getParameterValueFromExtendsModifiers(const QStringList &parameter);

    FlatModelica::Expression* getVariableBinding(const QString &variableName);
    const Element *lookupElement(const QString &name) const;
    Element *lookupElement(const QString &name);
    const Element *lookupElement(const Name &name) const;
    Element *lookupElement(const Name &name);

  private:
    void initialize();

    Element *mpParentElement;
    QJsonObject mModelJson;
    QString mName;
    bool mMissing;
    Dimensions mDims;
    QString mRestriction;
    std::unique_ptr<Prefixes> mpPrefixes;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;
    QList<Element*> mElements;
    QList<Import> mImports;
    QList<Connection*> mConnections;
    QList<Transition*> mTransitions;
    QList<InitialState*> mInitialStates;
    Source mSource;
  };

  class Element
  {
  public:
    Element(Model *pParentModel);
    virtual ~Element();
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    QString getTopLevelExtendName() const;
    Element *getTopLevelExtendElement() const;
    void setModel(Model *pModel) {mpModel = pModel;}
    Model *getModel() const {return mpModel;}
    Modifier *getModifier() const {return mpModifier;}
    QPair<QString, bool> getModifierValueFromType(QStringList modifierNames);
    const Dimensions &getDimensions() const {return mDims;}
    bool isPublic() const;
    bool isFinal() const;
    bool isInner() const;
    bool isOuter() const;
    Replaceable *getReplaceable() const;
    bool isRedeclare() const;
    QString getConnector() const;
    QString getVariability() const;
    QString getDirectionPrefix() const;
    const QString &getComment() const;
    Annotation *getAnnotation() const;
    const FlatModelica::Expression &getBinding() const {return mBinding;}
    FlatModelica::Expression &getBinding() {return mBinding;}
    void setBinding(const FlatModelica::Expression expression) {mBinding = expression;}
    void resetBinding() {mBinding = mBindingForReset;}
    bool getIconDiagramMapPrimitivesVisible(bool icon) const;
    bool getIconDiagramMapHasExtent(bool icon) const;
    const ExtentAnnotation &getIconDiagramMapExtent(bool icon) const;

    virtual QString getName() const = 0;
    virtual QString getQualifiedName(bool includeBaseName) const = 0;
    virtual QString getQualifiedName() const = 0;
    virtual const QString &getRootType() const = 0;
    virtual QString getType() const = 0;
    virtual bool isShortClassDefinition() const = 0;
    virtual bool isComponent() const = 0;
    virtual bool isExtend() const = 0;
    virtual bool isClass() const = 0;
    virtual QString toString(bool skipTopLevel = false, bool mergeExtendsModifiers = false) const;

    QString getDirection() const;
  private:
    virtual void deserialize_impl(const QJsonObject &jsonObject) = 0;
    static QPair<QString, bool> getModifierValueFromInheritedType(Model *pModel, QStringList modifierNames);
  protected:
    Model *mpParentModel;
    Model *mpModel = 0;

    Modifier *mpModifier = 0;
    Dimensions mDims;
    std::unique_ptr<Prefixes> mpPrefixes;
    QString mComment;
    std::unique_ptr<Annotation> mpAnnotation;
    FlatModelica::Expression mBinding;
    FlatModelica::Expression mBindingForReset;
  };

  class Extend : public Element
  {
  public:
    Extend(Model *pParentModel, const QJsonObject &jsonObject);
  private:
    void deserialize_impl(const QJsonObject &jsonObject) override;
  private:
    QString mBaseClass;
    // Element interface
  public:
    virtual QString getName() const override {return "";}
    virtual QString getQualifiedName(bool includeBaseName) const override;
    virtual QString getQualifiedName() const override {return getQualifiedName(false);}
    virtual const QString& getRootType() const override;
    virtual QString getType() const override {return mBaseClass;}
    virtual bool isShortClassDefinition() const override {return false;}
    virtual bool isComponent() const override {return false;}
    virtual bool isExtend() const override {return true;}
    virtual bool isClass() const override {return false;}
    virtual QString toString(bool skipTopLevel = false, bool mergeExtendsModifiers = false) const override;
  };

  class Component : public Element
  {
  public:
    Component(Model *pParentModel);
    Component(Model *pParentModel, const QJsonObject &jsonObject);

    void setName(const QString &name) {mName = name;}
    bool getCondition() const {return mCondition;}
    void setType(const QString &type) {mType = type;}
  private:
    void deserialize_impl(const QJsonObject &jsonObject) override;
    QList<Modifier*> getExtendsModifiers(const Model *pParentModel) const;
    Modifier *mergeModifiersIntoOne(QList<Modifier*> extendsModifiers) const;
    static void mergeModifiers(Modifier *pModifier1, Modifier *pModifier2);
  private:
    QString mName;
    bool mCondition = true;
    QString mType;
    // Element interface
  public:
    virtual QString getName() const override {return mName;}
    virtual QString getQualifiedName(bool includeBaseName) const override;
    virtual QString getQualifiedName() const override {return getQualifiedName(false);}
    virtual const QString &getRootType() const override;
    virtual QString getType() const override {return mType;}
    virtual bool isShortClassDefinition() const override {return false;}
    virtual bool isComponent() const override {return true;}
    virtual bool isExtend() const override {return false;}
    virtual bool isClass() const override {return false;}
    virtual QString toString(bool skipTopLevel = false, bool mergeExtendsModifiers = false) const override;
  };

  class ReplaceableClass : public Element
  {
  public:
    ReplaceableClass(Model *pParentModel, const QJsonObject &jsonObject);

    QString getBaseClass() const {return mBaseClass;}
  private:
    void deserialize_impl(const QJsonObject &jsonObject) override;
  private:
    QString mName;
    QString mType;
    bool mIsShortClassDefinition;
    QString mBaseClass;
    Source mSource;
    // Element interface
  public:
    virtual QString getName() const override {return mName;}
    virtual QString getQualifiedName(bool includeBaseName) const override;
    virtual QString getQualifiedName() const override {return getQualifiedName(false);}
    virtual const QString &getRootType() const override {return mName;}
    virtual QString getType() const override {return mType;}
    virtual bool isShortClassDefinition() const override {return mIsShortClassDefinition;}
    virtual bool isComponent() const override {return false;}
    virtual bool isExtend() const override {return false;}
    virtual bool isClass() const override {return true;}
    virtual QString toString(bool skipTopLevel = false, bool mergeExtendsModifiers = false) const override;
  };

  class Part
  {
  public:
    Part();
    Part(const QString &str);
    void deserialize(const QJsonObject &jsonObject);

    QString getName(bool includeSubscripts = true) const;
  private:
    QString mName;
    QStringList mSubScripts;
  };

  class Name
  {
  public:
    Name() = default;
    Name(QString str);
    void deserialize(const QJsonArray &jsonArray);

    QString getName() const;
    QStringList getNameParts() const;
    const QList<Part> getParts() const { return mParts; }

    size_t size() const { return mParts.size(); }
    Part first() const { return mParts.empty() ? Part() : mParts[0]; }

  private:
    QList<Part> mParts;
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
    Name mName;
  };

  class Import
  {
  public:
    Import(const QJsonObject &jsonObject);

    QString getPath() const {return mPath;}
    QString getShortName() const {return mShortName;}
  private:
    QString mPath;
    QString mShortName;
  };

  class Connection
  {
  public:
    Connection(Model *pParentModel);
    void deserialize(const QJsonObject &jsonObject);

    Model *getParentModel() const {return mpParentModel;}
    Connector *getStartConnector() const {return mpStartConnector.get();}
    Connector *getEndConnector() const {return mpEndConnector.get();}
    Annotation *getAnnotation() const;
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
    Annotation *getAnnotation() const;
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
    Annotation *getAnnotation() const;
    QString toString() const;
  private:
    Model *mpParentModel;
    std::unique_ptr<Connector> mpStartConnector;
    std::unique_ptr<Annotation> mpAnnotation;
  };
} // namespace ModelInstance

#endif // MODEL_H
