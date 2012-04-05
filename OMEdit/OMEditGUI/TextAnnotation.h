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
 *
 */

/*
 * RCS: $Id$
 */

#ifndef TEXTANNOTATION_H
#define TEXTANNOTATION_H

#include "ShapeAnnotation.h"
#include "Component.h"
#include "mainwindow.h"

class OMCProxy;
class IconParameters;

class TextAnnotation : public ShapeAnnotation
{
  Q_OBJECT
private:
  QString mTextString;
  qreal mFontSize;
  qreal mCalculatedFontSize;
  QString mFontName;
  int mFontWeight;
  bool mFontItalic;
  bool mFontUnderLine;
  //double mDefaultFontSize;
  Qt::Alignment mHorizontalAlignment;
  QRectF mDrawingRect;
  qreal mLetterSpacing;
public:
  TextAnnotation(QString shape, Component *pParent);
  TextAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent = 0);
  TextAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent = 0);

  QRectF boundingRect() const;
  QString getTextString();
  QPainterPath shape() const;
  QString getShapeAnnotation();
  QRectF getDrawingRect();
  void setLetterSpacing(qreal letterSpacing);
  void setLetterSpacingOnFont(QFont *font, qreal letterSpacing);
  qreal getLetterSpacing();

  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  void checkNameString();
  void checkParameterString();
  bool updateParameterString(IconParameters *pParamter);
  void setTextString(QString text);
  void setFontName(QString fontName);
  QString getFontName();
  void setFontSize(double fontSize);
  double getFontSize();
  void setItalic(bool italic);
  bool getItalic();
  void setWeight(int bold);
  bool getWeight();
  void setUnderLine(bool underLine);
  bool getUnderLine();
  void setAlignment(Qt::Alignment alignment);
  QString getAlignment();
  void drawRectangleCornerItems();
  void updateEndPoint(QPointF point);
  void addPoint(QPointF point);
  void updateAnnotation();
  void parseShapeAnnotation(QString shape, OMCProxy *omc);

  Component *mpComponent;
signals:
  void extentChanged();
public slots:
  void updatePoint(int index, QPointF point);
  void calculateFontSize();
};

class TextWidget : public QDialog
{
  Q_OBJECT
public:
  TextWidget(TextAnnotation *pTextShape, MainWindow *parent);
  MainWindow *mpParentMainWindow;
  void setUpForm();
  void show();

private:
  QLabel *mpHeading;
  QFrame *mHorizontalLine;
  QLabel *mpTextLabel;
  QLineEdit *mpTextBox;
  QLabel *mpFontLabel;
  QFontComboBox *mpFontFamilyComboBox;
  QLabel *mpFontSizeLabel;
  QComboBox *mpFontSizeComboBox;
  QLabel *mpAlignmentLabel;
  QComboBox *mpAlignmentComboBox;
  QGroupBox *mpStylesGroup;
  QCheckBox *mpCursive;
  QCheckBox *mpBold;
  QCheckBox *mpUnderline;
  QPushButton *mpEditButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;

  TextAnnotation *mpTextAnnotation;
public slots:
  void edit();
};

#endif // TEXTANNOTATION_H
