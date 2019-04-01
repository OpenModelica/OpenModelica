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
#include "Component/Transformation.h"

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
class ResizerItem;
class ShapeAnnotation;

class GraphicItem
{
public:
  GraphicItem() {}
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void parseShapeAnnotation(QString annotation);
  QStringList getOMCShapeAnnotation();
  QStringList getShapeAnnotation();
  void setOrigin(QPointF origin) {mOrigin = origin;}
  QPointF getOrigin() {return mOrigin;}
  void setRotationAngle(qreal rotation) {mRotation = rotation;}
  qreal getRotation() {return mRotation;}
protected:
  bool mVisible;
  QPointF mOrigin;
  qreal mRotation;
  QString mDynamicVisible; /* variable for visible attribute */
};

class FilledShape
{
public:
  FilledShape() {}
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void parseShapeAnnotation(QString annotation);
  QStringList getOMCShapeAnnotation();
  QStringList getShapeAnnotation();
  void setLineColor(QColor color) {mLineColor = color;}
  QColor getLineColor() {return mLineColor;}
  void setFillColor(QColor color) {mFillColor = color;}
  QColor getFillColor() {return mFillColor;}
  void setLinePattern(StringHandler::LinePattern pattern) {mLinePattern = pattern;}
  StringHandler::LinePattern getLinePattern() {return mLinePattern;}
  void setFillPattern(StringHandler::FillPattern pattern) {mFillPattern = pattern;}
  StringHandler::FillPattern getFillPattern() {return mFillPattern;}
  void setLineThickness(qreal thickness) {mLineThickness = thickness;}
  qreal getLineThickness() {return mLineThickness;}
protected:
  QColor mLineColor;
  QColor mFillColor;
  StringHandler::LinePattern mLinePattern;
  StringHandler::FillPattern mFillPattern;
  qreal mLineThickness;
};

class ShapeAnnotation : public QObject, public QGraphicsItem, public GraphicItem, public FilledShape
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
private:
  bool mIsCustomShape;
  bool mIsInheritedShape;
  QPointF mOldScenePosition;
  bool mIsCornerItemClicked;
  QAction *mpShapePropertiesAction;
  QAction *mpAlignInterfacesAction;
  QAction *mpShapeAttributesAction;
  QAction *mpEditTransitionAction;
public:
  enum LineGeometryType {VerticalLine, HorizontalLine};
  Transformation mTransformation;
  ShapeAnnotation(QGraphicsItem *pParent);
  ShapeAnnotation(bool inheritedShape, GraphicsView *pGraphicsView, QGraphicsItem *pParent = 0);
  void setDefaults();
  void setDefaults(ShapeAnnotation *pShapeAnnotation);
  void setUserDefaults();
  bool isInheritedShape();
  void createActions();
  QPainterPath addPathStroker(QPainterPath &path) const;
  QRectF getBoundingRect() const;
  void applyLinePattern(QPainter *painter);
  void applyFillPattern(QPainter *painter);
  virtual void parseShapeAnnotation(QString annotation);
  virtual QString getOMCShapeAnnotation();
  virtual QString getShapeAnnotation();
  void initializeTransformation();
  void drawCornerItems();
  void setCornerItemsActiveOrPassive();
  void removeCornerItems();
  void setOldScenePosition(QPointF oldScenePosition) {mOldScenePosition = oldScenePosition;}
  QPointF getOldScenePosition() {return mOldScenePosition;}
  virtual void addPoint(QPointF point) {Q_UNUSED(point);}
  virtual void clearPoints() {}
  virtual void replaceExtent(int index, QPointF point);
  virtual void updateEndExtent(QPointF point);
  GraphicsView* getGraphicsView() {return mpGraphicsView;}
  void setPoints(QList<QPointF> points) {mPoints = points;}
  QList<QPointF> getPoints() {return mPoints;}
  void setStartArrow(StringHandler::Arrow startArrow) {mArrow.replace(0, startArrow);}
  StringHandler::Arrow getStartArrow() {return mArrow.at(0);}
  void setEndArrow(StringHandler::Arrow endArrow) {mArrow.replace(1, endArrow);}
  StringHandler::Arrow getEndArrow() {return mArrow.at(1);}
  void setArrowSize(qreal arrowSize) {mArrowSize = arrowSize;}
  qreal getArrowSize() {return mArrowSize;}
  void setSmooth(StringHandler::Smooth smooth) {mSmooth = smooth;}
  StringHandler::Smooth getSmooth() {return mSmooth;}
  void setExtents(QList<QPointF> extents) {mExtents = extents;}
  QList<QPointF> getExtents() {return mExtents;}
  void setBorderPattern(StringHandler::BorderPattern pattern) {mBorderPattern = pattern;}
  StringHandler::BorderPattern getBorderPattern() {return mBorderPattern;}
  void setRadius(qreal radius) {mRadius = radius;}
  qreal getRadius() {return mRadius;}
  void setStartAngle(qreal startAngle) {mStartAngle = startAngle;}
  qreal getStartAngle() {return mStartAngle;}
  void setEndAngle(qreal endAngle) {mEndAngle = endAngle;}
  qreal getEndAngle() {return mEndAngle;}
  void setTextString(QString textString);
  QString getTextString() {return mOriginalTextString;}
  void setFontName(QString fontName) {mFontName = fontName;}
  QString getFontName() {return mFontName;}
  void setFontSize(qreal fontSize) {mFontSize = fontSize;}
  qreal getFontSize() {return mFontSize;}
  void setTextStyles(QList<StringHandler::TextStyle> textStyles) {mTextStyles = textStyles;}
  QList<StringHandler::TextStyle> getTextStyles() {return mTextStyles;}
  void setTextHorizontalAlignment(StringHandler::TextAlignment textAlignment) {mHorizontalAlignment = textAlignment;}
  StringHandler::TextAlignment getTextHorizontalAlignment() {return mHorizontalAlignment;}
  void setFileName(QString fileName);
  QString getFileName();
  void setImageSource(QString imageSource);
  QString getImageSource();
  void setImage(QImage image);
  QImage getImage();
  QVariant getDynamicValue(QString name);
  void applyRotation(qreal angle);
  void adjustPointsWithOrigin();
  void adjustExtentsWithOrigin();
  CornerItem* getCornerItem(int index);
  void updateCornerItem(int index);
  void insertPointsGeometriesAndCornerItems(int index);
  void adjustCornerItemsConnectedIndexes();
  void removeRedundantPointsGeometriesAndCornerItems();
  void adjustGeometries();
  virtual void setShapeFlags(bool enable);
  virtual void updateShape(ShapeAnnotation *pShapeAnnotation);
  void emitAdded() {emit added();}
  void emitChanged() {emit changed();}
  void emitDeleted() {emit deleted();}
  void emitPrepareGeometryChange() {prepareGeometryChange();}
signals:
  void updateReferenceShapes();
  void added();
  void changed();
  void deleted();
public slots:
  void deleteMe();
  virtual void duplicate();
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
  void cornerItemPressed();
  void cornerItemReleased();
  void updateCornerItemPoint(int index, QPointF point);
  LineGeometryType findLineGeometryType(QPointF point1, QPointF point2);
  bool isLineStraight(QPointF point1, QPointF point2);
  void showShapeProperties();
  void alignInterfaces();
  void showShapeAttributes();
  void editTransition();
  void manhattanizeShape(bool addToStack = true);
  void referenceShapeAdded();
  void referenceShapeChanged();
  void referenceShapeDeleted();
  void updateVisible();
protected:
  GraphicsView *mpGraphicsView;
  Component *mpParentComponent;
  QList<QPointF> mPoints;
  QList<LineGeometryType> mGeometries;
  QList<StringHandler::Arrow> mArrow;
  qreal mArrowSize;
  StringHandler::Smooth mSmooth;
  QList<QPointF> mExtents;
  StringHandler::BorderPattern mBorderPattern;
  qreal mRadius;
  qreal mStartAngle;
  qreal mEndAngle;
  QString mOriginalTextString;
  QString mTextString;
  qreal mFontSize;
  QString mFontName;
  QList<StringHandler::TextStyle> mTextStyles;
  StringHandler::TextAlignment mHorizontalAlignment;
  QString mOriginalFileName;
  QString mFileName;
  QString mClassFileName; /* Used to find the bitmap relative locations. */
  QString mImageSource;
  QImage mImage;
  QList<CornerItem*> mCornerItemsList;
  QList<QVariant> mDynamicTextString; /* list of String() arguments */
  void initUpdateVisible();
  virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *pEvent);
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
};

#endif // SHAPEANNOTATION_H
