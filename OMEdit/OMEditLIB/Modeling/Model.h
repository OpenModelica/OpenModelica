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

namespace ModelInstance
{
  class Point
  {
  public:
    Point();
    Point(double x, double y);
    Point(const Point &point);
    void deserialize(const QJsonArray &jsonArray);
    double x() const {return mValue[0];}
    double y() const {return mValue[1];}

    Point& operator=(const Point &point) noexcept = default;
private:
    double mValue[2];
  };

  class Extent
  {
  public:
    Extent();
    Extent(const Point &extent1, const Point extent2);
    Extent(const Extent &extent);
    void deserialize(const QJsonArray &jsonArray);
    Point getExtent1() const {return mPoint[0];}
    Point getExtent2() const {return mPoint[1];}

    Extent& operator=(const Extent &extent) noexcept = default;
private:
    Point mPoint[2];
  };

  class CoordinateSystem
  {
  public:
    CoordinateSystem();
    CoordinateSystem(const CoordinateSystem &coOrdinateSystem);
    void setExtent(const Extent &extent);
    Extent getExtent() const {return mExtent;}
    void setHasExtent(const bool hasExtent) {mHasExtent = hasExtent;}
    bool hasExtent() const {return mHasExtent;}
    void setPreserveAspectRatio(const bool preserveAspectRatio);
    bool getPreserveAspectRatio() const {return mPreserveAspectRatio;}
    bool hasPreserveAspectRatio() const {return mHasPreserveAspectRatio;}
    void setHasPreserveAspectRatio(const bool hasPreserveAspectRatio) {mHasPreserveAspectRatio = hasPreserveAspectRatio;}
    void setInitialScale(const qreal initialScale);
    double getInitialScale() const {return mInitialScale;}
    bool hasInitialScale() const {return mHasInitialScale;}
    void setHasInitialScale(const bool hasInitialScale) {mHasInitialScale = hasInitialScale;}
    void setGrid(const Point &grid);
    Point getGrid() const {return mGrid;}
    void setHasGrid(const bool hasGrid) {mHasGrid = hasGrid;}
    bool hasGrid() const {return mHasGrid;}

    double getHorizontalGridStep();
    double getVerticalGridStep();
    QRectF getExtentRectangle() const;
    void reset();
    bool isComplete() const;
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;

    CoordinateSystem& operator=(const CoordinateSystem &coOrdinateSystem) noexcept = default;
  private:
    Extent mExtent;
    bool mHasExtent;
    bool mPreserveAspectRatio;
    bool mHasPreserveAspectRatio;
    qreal mInitialScale;
    bool mHasInitialScale;
    Point mGrid;
    bool mHasGrid;
  };

  class GraphicItem
  {
  public:
    GraphicItem();
    bool getVisible() const {return mVisible;}
    Point getOrigin() const {return mOrigin;}
    double getRotation() const {return mRotation;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);
private:
    bool mVisible;
    Point mOrigin;
    double mRotation;
  };

  class Color
  {
  public:
    Color();
    void deserialize(const QJsonArray &jsonArray);
    QColor getColor() const {return mColor;}
private:
    QColor mColor;
  };

  enum class LinePattern {None, Solid, Dash, Dot, DashDot, DashDotDot};
  enum class FillPattern {None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere};
  enum class BorderPattern {None, Raised, Sunken, Engraved};
  enum class Smooth {None, Bezier};
  enum class EllipseClosure {None, Chord, Radial};
  enum class Arrow {None, Open, Filled, Half};
  enum class TextStyle {Bold, Italic, UnderLine};
  enum class TextAlignment {Left, Center, Right};

  class FilledShape
  {
  public:
    FilledShape();
    Color getLineColor() const {return mLineColor;}
    Color getFillColor() const {return mFillColor;}
    QString getPattern() const {return mPattern;}
    QString getFillPattern() const {return mFillPattern;}
    double getLineThickness() const {return mLineThickness;}
  protected:
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);
  private:
    Color mLineColor;
    Color mFillColor;
    QString mPattern;
    QString mFillPattern;
    double mLineThickness;
  };

  class Shape : public GraphicItem, public FilledShape
  {
  public:
    Shape();
    virtual ~Shape();
  };

  class Line : public Shape
  {
  public:
    Line();
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);

    QList<Point> getPoints() const {return mPoints;}
    Color getColor() const {return mColor;}
    QString getPattern() const {return mPattern;}
    double getThickness() const {return mThickness;}
    QString getStartArrow() const {return mArrow[0];}
    QString getEndArrow() const {return mArrow[1];}
    double getArrowSize() const {return mArrowSize;}
    QString getSmooth() const {return mSmooth;}
  private:
    QList<Point> mPoints;
    Color mColor;
    QString mPattern;
    double mThickness;
    QString mArrow[2];
    double mArrowSize = 3;
    QString mSmooth;
  };

  class Polygon : public Shape
  {
  public:
    Polygon();
    void deserialize(const QJsonArray &jsonArray);

    QList<Point> getPoints() const {return mPoints;}
    QString getSmooth() const {return mSmooth;}
  private:
    QList<Point> mPoints;
    QString mSmooth;
  };

  class Rectangle : public Shape
  {
  public:
    Rectangle();
    void deserialize(const QJsonArray &jsonArray);

    QString getBorderPattern() const {return mBorderPattern;}
    Extent getExtent() const {return mExtent;}
    double getRadius() const {return mRadius;}
  private:
    QString mBorderPattern;
    Extent mExtent;
    double mRadius;
  };

  class Ellipse : public Shape
  {
  public:
    Ellipse();
    void deserialize(const QJsonArray &jsonArray);

    Extent getExtent() const {return mExtent;}
    double getStartAngle() const {return mStartAngle;}
    double getEndAngle() const {return mEndAngle;}
    QString getClosure() const {return mClosure;}
  private:
    Extent mExtent;
    double mStartAngle;
    double mEndAngle;
    QString mClosure;
  };

  class Text : public Shape
  {
  public:
    Text();
    void deserialize(const QJsonArray &jsonArray);
    void deserialize(const QJsonObject &jsonObject);

    Extent getExtent() const {return mExtent;}
    QString getTextString() const {return mTextString;}
    double getFontSize() const {return mFontSize;}
    QString getFontName() const {return mFontName;}
    QStringList getTextStyle() const {return mTextStyle;}
    Color getTextColor() const {return mTextColor;}
    QString getHorizontalAlignment() const {return mHorizontalAlignment;}
  private:
    Extent mExtent;
    QString mTextString;
    double mFontSize;
    QString mFontName;
    QStringList mTextStyle;
    Color mTextColor;
    QString mHorizontalAlignment;
  };

  class Bitmap : public Shape
  {
  public:
    Bitmap();
    void deserialize(const QJsonArray &jsonArray);

    Extent getExtent() const {return mExtent;}
    QString getFileName() const {return mFileName;}
    QString getImageSource() const {return mImageSource;}
  private:
    Extent mExtent;
    QString mFileName;
    QString mImageSource;
  };

  class IconDiagramAnnotation
  {
  public:
    IconDiagramAnnotation();
    ~IconDiagramAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    CoordinateSystem getCoordinateSystem() {return mCoordinateSystem;}
    QList<Shape*> getGraphics() const {return mGraphics;}
    bool isGraphicsEmpty() const {return mGraphics.isEmpty();}

    CoordinateSystem mCoordinateSystem;
    QList<Shape*> mGraphics;

  };

  class Extend;
  class Element;
  class Connection;
  class Model
  {
  public:
    Model();
    Model(const QJsonObject &jsonObject);
    virtual ~Model();
    void deserialize();
    void serialize(QJsonObject &jsonObject) const;
    QJsonObject getModelJson() const {return mModelJson;}
    void setModelJson(const QJsonObject &modelJson) {mModelJson = modelJson;}
    QString getName() const {return mName;}
    bool isConnector() const;
    QList<Extend *> getExtends() const {return mExtends;}
    QString getComment() const {return mComment;}
    IconDiagramAnnotation *getIconAnnotation() const {return mpIconAnnotation;}
    IconDiagramAnnotation *getDiagramAnnotation() const {return mpDiagramAnnotation;}
    QList<Element *> getElements() const {return mElements;}
    QList<Connection *> getConnections() const {return mConnections;}
  private:
    void initialize();

    QJsonObject mModelJson;
    QString mName;
    QString mRestriction;
    QList<Extend*> mExtends;
    QString mComment;
    IconDiagramAnnotation *mpIconAnnotation;
    IconDiagramAnnotation *mpDiagramAnnotation;
    QList<Element*> mElements;
    QList<Connection*> mConnections;
  };

  class Transformation
  {
  public:
    Transformation();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    Point getOrigin() const {return mOrigin;}
    Extent getExtent() const {return mExtent;}
    double getRotation() const {return mRotation;}
  private:
    Point mOrigin;
    Extent mExtent;
    double mRotation;
  };

  class PlacementAnnotation
  {
  public:
    PlacementAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    bool getVisible() const {return mVisible;}
    Transformation getTransformation() const {return mTransformation;}
    bool getIconVisible() const {return mIconVisible;}
    Transformation getIconTransformation() const {return mIconTransformation;}
  private:
    bool mVisible;
    Transformation mTransformation;
    bool mIconVisible;
    Transformation mIconTransformation;
  };

  class Selector
  {
  public:
    Selector();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    QString getFilter() const {return mFilter;}
    QString getCaption() const {return mCaption;}
  private:
    QString mFilter;
    QString mCaption;
  };

  class DialogAnnotation
  {
  public:
    DialogAnnotation();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    QString getTab() const {return mTab;}
    QString getGroup() const {return mGroup;}
    bool isEnabled() const {return mEnable;}
    bool getShowStartAttribute() const {return mShowStartAttribute;}
    bool isColorSelector() const {return mColorSelector;}
    Selector getLoadSelector() const {return mLoadSelector;}
    Selector getSaveSelector() const {return mSaveSelector;}
    Selector getDirectorySelector() const {return mDirectorySelector;}
    QString getGroupImage() const {return mGroupImage;}
    bool isConnectorSizing() const {return mConnectorSizing;}
  private:
    QString mTab;
    QString mGroup;
    bool mEnable;
    bool mShowStartAttribute;
    bool mColorSelector;
    Selector mLoadSelector;
    Selector mSaveSelector;
    Selector mDirectorySelector;
    QString mGroupImage;
    bool mConnectorSizing;
  };

  class Modifier
  {
  public:
    Modifier();
    void deserialize(const QJsonValue &jsonValue);
    void serialize(QJsonObject &jsonObject) const;

    QString getName() const {return mName;}
    void setName(const QString &name) {mName = name;}
    QString getValue() const {return mValue;}
    QList<Modifier> getModifiers() const {return mModifiers;}
  private:
    QString mName;
    QString mValue;
    QList<Modifier> mModifiers;
  };

  class Choices
  {
  public:
    Choices();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;
    bool isCheckBox() const {return mCheckBox;}
    bool isDymolaCheckBox() const {return mDymolaCheckBox;}
  private:
    bool mCheckBox;
    bool mDymolaCheckBox;
  };

  class Element
  {
  public:
    Element(Model *pParentModel);
    ~Element();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;

    Model *getParentModel() const {return mpParentModel;}
    QString getName() const {return mName;}
    QString getType() const {return mType;}
    Model *getModel() const {return mpModel;}
    Modifier getModifier() const {return mModifier;}
    QString getDimensions() const {return mDims.join(", ");}
    bool isPublic() const {return mPublic;}
    bool isFinal() const {return mFinal;}
    bool isInner() const {return mInner;}
    bool isOuter() const {return mOuter;}
    bool isReplaceable() const {return mReplaceable;}
    bool isRedeclare() const {return mRedeclare;}
    QString getConnector() const {return mConnector;}
    QString getVariability() const {return mVariability;}
    QString getDirection() const {return mDirection;}
    QString getComment() const {return mComment;}
    PlacementAnnotation getPlacementAnnotation() const {return mPlacementAnnotation;}
    bool hasDialogAnnotation() const {return mHasDialogAnnotation;}
    DialogAnnotation getDialogAnnotation() const {return mDialogAnnotation;}
    bool isEvaluate() const {return mEvaluate;}
    Choices getChoices() const {return mChoices;}
  private:
    Model *mpParentModel;
    QString mName;
    QString mType;
    Model *mpModel;
    Modifier mModifier;
    QStringList mDims;
    bool mPublic;
    bool mFinal;
    bool mInner;
    bool mOuter;
    bool mReplaceable;
    bool mRedeclare;
    QString mConnector;
    QString mVariability;
    QString mDirection;
    QString mComment;
    PlacementAnnotation mPlacementAnnotation;
    bool mHasDialogAnnotation;
    DialogAnnotation mDialogAnnotation;
    bool mEvaluate;
    Choices mChoices;
  };

  class Connector
  {
  public:
    Connector();
    void deserialize(const QJsonObject &jsonObject);

    QString getName() const;
    QStringList getNameParts() const {return mParts;}
  private:
    QString mKind;
    QStringList mParts;
  };

  class Connection
  {
  public:
    Connection();
    ~Connection();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;

    Connector *getStartConnector() const {return mpStartConnector;}
    Connector *getEndConnector() const {return mpEndConnector;}
    Line *getLine() const {return mpLine;}
    Text *getText() const {return mpText;}
  private:
    Connector *mpStartConnector;
    Connector *mpEndConnector;
    Line *mpLine;
    Text *mpText;
  };

  class Extend : public Model
  {
  public:
    Extend();
    ~Extend();
    void deserialize(const QJsonObject &jsonObject);
    void serialize(QJsonObject &jsonObject) const;

    Modifier getModifier() const {return mModifier;}
  private:
    Modifier mModifier;
  };

}

#endif // MODEL_H
