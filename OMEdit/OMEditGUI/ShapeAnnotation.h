/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * RCS: $Id$
 */

#ifndef SHAPEANNOTATION_H
#define SHAPEANNOTATION_H

#include <QtCore>
#include <QtGui>

#include "StringHandler.h"

class MainWindow;
class GraphicsView;
class RectangleCornerItem;
class ShapeProperties;
// Base class for all shapes annotations
class ShapeAnnotation : public QObject, public QGraphicsItem
{
  Q_OBJECT
  Q_INTERFACES(QGraphicsItem)
private:
  QAction *mpShapePropertiesAction;
  QAction *mpTextPropertiesAction;
  QAction *mpShapePenStyleAction;
  QAction *mpShapeBrushStyleAction;

  QAction *mpNoArrowAction;
  QAction *mpHalfArrowAction;
  QAction *mpOpenArrowAction;
  QAction *mpFilledArrowAction;
  QAction *mpNoEndArrowAction;
  QAction *mpHalfEndArrowAction;
  QAction *mpOpenEndArrowAction;
  QAction *mpFilledEndArrowAction;

  QSettings mSettings;
public:
  ShapeAnnotation(QGraphicsItem *parent = 0);
  ShapeAnnotation(GraphicsView *graphicsView, QGraphicsItem *parent = 0);
  ~ShapeAnnotation();
  void initializeFields();
  void readSettings();
  void readPenStyleSettings();
  void readBrushStyleSettings();
  void createActions();
  void setSelectionBoxActive();
  void setSelectionBoxPassive();
  void setSelectionBoxHover();
  void changePenProperty();
  void changeBrushProperty();

  //void changeColour();
  virtual QString getShapeAnnotation();
  QRectF getBoundingRect() const;
  QPainterPath addPathStroker(QPainterPath &path) const;
  ShapeProperties *mpShapeProperties;
  GraphicsView *mpGraphicsView;
signals:
  void updateShapeAnnotation();

public slots:
  void deleteMe();
  void doSelect();
  void doUnSelect();
  void moveUp();
  void moveDown();
  void moveLeft();
  void moveRight();
  void rotateClockwise();
  void flipHorizontal();
  void flipVertical();
  void rotateAntiClockwise();
  void resetRotation();
  QColor getLineColor();
  Qt::PenStyle getLinePattern();
  double getLineThickness();
  double getRectCornerRadius();
  bool getLineSmooth();
  QColor getFillColor();
  Qt::BrushStyle getFillPattern();
  void noArrowLine();
  void halfArrowLine();
  void openArrowLine();
  void filledArrowLine();
  void noEndArrowLine();
  void halfEndArrowLine();
  void openEndArrowLine();
  void filledEndArrowLine();

  void openShapeProperties();
  void openTextProperties();
  //void openPenStyleProperties();
  //void openBrushStyleProperties();
protected:
  bool mVisible;
  QPointF mOrigin;
  qreal mRotation;
  QColor mLineColor;
  QColor mFillColor;
  QMap<QString, Qt::PenStyle> mLinePatternsMap;
  Qt::PenStyle mLinePattern;
  QMap<QString, Qt::BrushStyle> mFillPatternsMap;
  Qt::BrushStyle mFillPattern;
  qreal mThickness;
  QMap<QString, Qt::BrushStyle> mBorderPatternsMap;
  Qt::BrushStyle mBorderPattern;
  QVector<QPointF> mPoints;
  QList<QPointF> mExtent;
  qreal mCornerRadius;
  bool mSmooth;
  enum ArrowType {None, Open, Filled, Half};
  QMap<QString, ArrowType> mArrowsMap;
  int mStartArrow;
  int mEndArrow;
  qreal mArrowSize;

  QList<RectangleCornerItem*> mRectangleCornerItemsList;
  bool mIsCustomShape;
  bool mIsFinishedCreatingShape;
  bool mIsRectangleCorneItemClicked;
  bool mIsItemClicked;
  QPointF mClickPos;

  virtual void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
  virtual void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
  virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
  virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);
  virtual QVariant itemChange(GraphicsItemChange change, const QVariant &value);
  virtual void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
};

class ShapeProperties : public QDialog
{
  Q_OBJECT
private:
  // Heading controls
  QLabel *mpHeadingLabel;
  QFrame *mpHorizontalLine;
  // Pen style controls
  QGroupBox *mpPenStyleGroup;
  QLabel *mpPenColorLabel;
  QLabel *mpPenColorViewerLabel;
  QPushButton *mpPenColorPickButton;
  QColor mPenColor;
  Qt::PenStyle mPenPattern;
  double mPenThickness;
  double mRectCornerRadius;
  bool mPenSmooth;
  QLabel *mpSmoothLabel;
  QCheckBox *mpPenNoColorCheckBox;
  QLabel *mpPenPatternLabel;
  QComboBox *mpPenPatternsComboBox;
  QLabel *mpPenThicknessLabel;
  QDoubleSpinBox *mpPenThicknessSpinBox;
  QLabel *mpCornerRadiusLabel;
  QDoubleSpinBox *mpCornerRadiusSpinBox;
  QCheckBox *mpSmoothCheckBox;
  // Brush style controls
  QGroupBox *mpBrushStyleGroup;
  QLabel *mpBrushColorLabel;
  QLabel *mpBrushColorViewerLabel;
  QPushButton *mpBrushColorPickButton;
  QColor mBrushColor;
  Qt::BrushStyle mBrushPattern;
  QCheckBox *mpBrushNoColorCheckBox;
  QLabel *mpBrushPatternLabel;
  QComboBox *mpBrushPatternsComboBox;
  QPushButton *mpCancelButton;
  QPushButton *mpOkButton;
  QDialogButtonBox *mpButtonBox;

signals:
  void colourChanged();
public:
  ShapeProperties(ShapeAnnotation *pShape, MainWindow *pParent);
  void setShapeType();
  void setUpDialog();
  void setUpLineDialog();
  void setInitPenColor(QColor color);
  void setInitPenPattern(Qt::PenStyle pattern);
  void setInitPenThickness(double thickness);
  void setInitCornerRadius(double radius);
  void setInitPenSmooth(bool smooth);
  QColor getPenColor();
  void setPenPattern();
  QString getPenPatternString();
  Qt::PenStyle getPenPattern();
  void setPenThickness();
  double getPenThickness();
  void setCornerRadius();
  double getCornerRadius();
  void setPenSmooth();
  bool getPenSmooth();
  void setInitBrushColor(QColor color);
  void setInitBrushPattern(Qt::BrushStyle pattern);
  QColor getBrushColor();
  void setBrushPattern();
  QString getBrushPatternString();
  Qt::BrushStyle getBrushPattern();
  QVBoxLayout* createHorizontalLine();
  QVBoxLayout* createPenControls();
  QVBoxLayout* createBrushControls();

  MainWindow *mpParentMainWindow;
  ShapeAnnotation *mpShape;
  enum ShapeType {Line, Polygon, Rectangle, Ellipse, Text, Bitmap};
  int mShapeType;
public slots:
  void pickPenColor();
  void penNoColorChecked(int state);
  void pickBrushColor();

  void brushNoColorChecked(int state);
  void applyChanges();

};

#endif // SHAPEANNOTATION_H
