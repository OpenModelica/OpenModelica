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

#ifndef SHAPEANNOTATION_H
#define SHAPEANNOTATION_H

#include "Util/StringHandler.h"
#include "Element/Transformation.h"
#include "Modeling/Model.h"

#include <QGraphicsItem>
#include <QSettings>
#include <QGroupBox>
#include <QDialog>
#include <QComboBox>
#include <QCheckBox>
#include <QDialogButtonBox>
#include <QVBoxLayout>

class MainWindow;
class GraphicsView;
class CornerItem;
class OriginItem;
class ShapeAnnotation;

QString stripDynamicSelect(const QString &str);

class GraphicItem
{
public:
  GraphicItem() {}
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void parseShapeAnnotation(QString annotation);
  void parseShapeAnnotation(ModelInstance::Shape *pShape);
  QStringList getOMCShapeAnnotation();
  QStringList getShapeAnnotation();
  void setOrigin(QPointF origin) {mOrigin = origin;}
  QPointF getOrigin() {return mOrigin;}
  void setRotationAngle(qreal rotation) {mRotation = rotation;}
  qreal getRotation() {return mRotation;}
protected:
  BooleanAnnotation mVisible;
  PointAnnotation mOrigin;
  RealAnnotation mRotation;
};

class FilledShape
{
public:
  FilledShape() {}
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void parseShapeAnnotation(QString annotation);
  void parseShapeAnnotation(ModelInstance::Shape *pShape);
  QStringList getOMCShapeAnnotation();
  QStringList getShapeAnnotation();
  QStringList getTextShapeAnnotation();
  void setLineColor(QColor color) {mLineColor = color;}
  QColor getLineColor() {return mLineColor;}
  void setFillColor(QColor color) {mFillColor = color;}
  QColor getFillColor() {return mFillColor;}
  void setLinePattern(StringHandler::LinePattern pattern) {mLinePattern = pattern;}
  StringHandler::LinePattern getLinePattern() {return mLinePattern;}
  void setFillPattern(StringHandler::FillPattern pattern) {mFillPattern = pattern;}
  const FillPatternAnnotation &getFillPattern() {return mFillPattern;}
  void setLineThickness(qreal thickness) {mLineThickness = thickness;}
  qreal getLineThickness() {return mLineThickness;}
protected:
  ColorAnnotation mLineColor;
  ColorAnnotation mFillColor;
  LinePatternAnnotation mLinePattern;
  FillPatternAnnotation mFillPattern;
  RealAnnotation mLineThickness;
};

class ShapeAnnotation : public QObject, public QGraphicsItem, public GraphicItem, public FilledShape
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
private:
  ShapeAnnotation *mpReferenceShapeAnnotation;
  bool mIsInheritedShape;
  QPointF mOldScenePosition;
  bool mIsCornerItemClicked;
  QTransform mTransform;
  QRectF mSceneBoundingRect;
  QPointF mTransformationStartPosition;
  QPointF mPivotPoint;
  QPointF mOldOrigin;
  QVector<QPointF> mOldExtents;
  QString mOldAnnotation;
  QAction *mpShapePropertiesAction;
  QAction *mpEditTransitionAction;
public:
  enum LineGeometryType {VerticalLine, HorizontalLine};
  Transformation mTransformation;
  ShapeAnnotation(QGraphicsItem *pParent);
  ShapeAnnotation(ShapeAnnotation *pShapeAnnotation, QGraphicsItem *pParent);
  ShapeAnnotation(bool inheritedShape, GraphicsView *pGraphicsView, ShapeAnnotation *pShapeAnnotation, QGraphicsItem *pParent = 0);
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void setUserDefaults();
  bool isInheritedShape();
  void createActions();
  QPainterPath addPathStroker(QPainterPath &path) const;
  QRectF getBoundingRect() const;
  void applyLinePattern(QPainter *painter);
  void applyFillPattern(QPainter *painter);
  virtual void parseShapeAnnotation(QString annotation) = 0;
  virtual QString getOMCShapeAnnotation() = 0;
  virtual QString getOMCShapeAnnotationWithShapeName() = 0;
  virtual QString getShapeAnnotation() = 0;
  virtual void drawAnnotation(QPainter *painter) = 0;
  QList<QPointF> getExtentsForInheritedShapeFromIconDiagramMap(GraphicsView *pGraphicsView);
  void applyTransformation();
  void drawCornerItems();
  void setCornerItemsActiveOrPassive();
  void updateCornerItems();
  void removeCornerItems();
  void setOldScenePosition(QPointF oldScenePosition) {mOldScenePosition = oldScenePosition;}
  QPointF getOldScenePosition() {return mOldScenePosition;}
  bool isCornerItemClicked() const {return mIsCornerItemClicked;}
  QAction* getShapePropertiesAction() const {return mpShapePropertiesAction;}
  QAction* getEditTransitionAction() const {return mpEditTransitionAction;}
  virtual void addPoint(QPointF point) {Q_UNUSED(point);}
  virtual void clearPoints() {}
  virtual void replaceExtent(const int index, const QPointF point);
  void updateExtent(const int index, const QPointF point);
  void setOriginItemPos(const QPointF point);
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  Element* getParentComponent() const {return mpParentComponent;}
  OriginItem* getOriginItem() {return mpOriginItem;}
  void setPoints(QVector<QPointF> points) {mPoints = points;}
  const PointArrayAnnotation &getPoints() {return mPoints;}
  const ArrowAnnotation &getArrow() {return mArrow;}
  void setStartArrow(StringHandler::Arrow startArrow) {mArrow.replace(0, startArrow);}
  StringHandler::Arrow getStartArrow() {return mArrow.at(0);}
  void setEndArrow(StringHandler::Arrow endArrow) {mArrow.replace(1, endArrow);}
  StringHandler::Arrow getEndArrow() {return mArrow.at(1);}
  void setArrowSize(qreal arrowSize) {mArrowSize = arrowSize;}
  qreal getArrowSize() {return mArrowSize;}
  void setSmooth(StringHandler::Smooth smooth) {mSmooth = smooth;}
  StringHandler::Smooth getSmooth() {return mSmooth;}
  void setExtents(QVector<QPointF> extents) {mExtent = extents;}
  const QVector<QPointF> &getExtents() {return mExtent;}
  void setBorderPattern(StringHandler::BorderPattern pattern) {mBorderPattern = pattern;}
  StringHandler::BorderPattern getBorderPattern() {return mBorderPattern;}
  void setRadius(qreal radius) {mRadius = radius;}
  qreal getRadius() {return mRadius;}
  void setStartAngle(qreal startAngle) {mStartAngle = startAngle;}
  qreal getStartAngle() {return mStartAngle;}
  void setEndAngle(qreal endAngle) {mEndAngle = endAngle;}
  qreal getEndAngle() {return mEndAngle;}
  void setClosure(StringHandler::EllipseClosure closure) {mClosure = closure;}
  StringHandler::EllipseClosure getClosure() {return mClosure;}
  void setTextString(QString textString);
  const QString &getTextString() {return mTextString;}
  void setFontName(QString fontName) {mFontName = fontName;}
  const QString &getFontName() {return mFontName;}
  void setFontSize(qreal fontSize) {mFontSize = fontSize;}
  qreal getFontSize() {return mFontSize;}
  void setTextStyles(QVector<StringHandler::TextStyle> textStyles) {mTextStyles = textStyles;}
  const QVector<StringHandler::TextStyle> &getTextStyles() {return mTextStyles;}
  void setTextHorizontalAlignment(StringHandler::TextAlignment textAlignment) {mHorizontalAlignment = textAlignment;}
  StringHandler::TextAlignment getTextHorizontalAlignment() {return mHorizontalAlignment;}
  void setFileName(QString fileName);
  QString getFileName();
  void setImageSource(QString imageSource);
  QString getImageSource();
  void setImage(QImage image);
  QImage getImage();
  void applyRotation(qreal angle);
  void adjustPointsWithOrigin();
  void adjustExtentsWithOrigin();
  CornerItem* getCornerItem(int index);
  void updateCornerItem(int index);
  void insertPointsGeometriesAndCornerItems(int index);
  void adjustCornerItemsConnectedIndexes();
  void removeRedundantPointsGeometriesAndCornerItems();
  void adjustGeometries();
  void moveShape(const qreal dx, const qreal dy);
  virtual void setShapeFlags(bool enable);
  virtual void updateShape(ShapeAnnotation *pShapeAnnotation) = 0;
  virtual ModelInstance::Extend* getExtend() const = 0;
  void emitAdded() {emit added();}
  void emitChanged() {emit changed();}
  void emitDeleted() {emit deleted();}
  void emitPrepareGeometryChange() {prepareGeometryChange();}
signals:
  void added();
  void changed();
  void deleted();
public slots:
  void deleteMe();
  virtual void duplicate() = 0;
  void bringToFront();
  void bringForward();
  void sendToBack();
  void sendBackward();
  void rotateClockwise();
  void rotateAntiClockwise();
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
  void cornerItemPressed(const int index);
  void cornerItemReleased(const bool changed);
  void updateCornerItemPoint(int index, QPointF point);
  LineGeometryType findLineGeometryType(QPointF point1, QPointF point2);
  bool isLineStraight(QPointF point1, QPointF point2);
  void showShapeProperties();
  void editTransition();
  void manhattanizeShape(bool addToStack = true);
  void referenceShapeAdded();
  void referenceShapeChanged();
  void referenceShapeDeleted();
  void updateDynamicSelect(double time);
  void resetDynamicSelect();
protected:
  GraphicsView *mpGraphicsView;
  Element *mpParentComponent;
  OriginItem *mpOriginItem;
  PointArrayAnnotation mPoints;
  QList<LineGeometryType> mGeometries;
  ArrowAnnotation mArrow;
  RealAnnotation mArrowSize;
  SmoothAnnotation mSmooth;
  ExtentAnnotation mExtent;
  BorderPatternAnnotation mBorderPattern;
  RealAnnotation mRadius;
  RealAnnotation mStartAngle;
  RealAnnotation mEndAngle;
  EllipseClosureAnnotation mClosure;
  StringAnnotation mOriginalTextString;
  StringAnnotation mTextString;
  RealAnnotation mFontSize;
  StringAnnotation mFontName;
  TextStyleAnnotation mTextStyles;
  TextAlignmentAnnotation mHorizontalAlignment;
  QString mOriginalFileName;
  QString mFileName;
  QString mClassFileName; /* Used to find the bitmap relative locations. */
  QString mImageSource;
  QImage mImage;
  QList<CornerItem*> mCornerItemsList;
  FlatModelica::Expression mTextExpression;
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value) override;
};

#endif // SHAPEANNOTATION_H
