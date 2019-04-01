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

#ifndef SHAPEPROPERTIESDIALOG_H
#define SHAPEPROPERTIESDIALOG_H

#include <QDialog>
#include <QFrame>
#include <QGroupBox>
#include <QComboBox>
#include <QLineEdit>
#include <QFontComboBox>
#include <QCheckBox>
#include <QScrollArea>
#include <QTableWidget>
#include <QDialogButtonBox>
#include <QToolButton>

class ShapeAnnotation;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;
class BitmapAnnotation;
class Label;
class DoubleSpinBox;

class ShapePropertiesDialog : public QDialog
{
  Q_OBJECT
public:
  ShapePropertiesDialog(ShapeAnnotation *pShapeAnnotation, QWidget *pParent = 0);
  QString getTitle();
  void setLineColor(QColor color);
  QColor getLineColor();
  void setLinePickColorButtonIcon();
  void setFillColor(QColor color);
  QColor getFillColor();
  void setFillPickColorButtonIcon();
private:
  ShapeAnnotation *mpShapeAnnotation;
  QString mOldAnnotation;
  LineAnnotation *mpLineAnnotation;
  PolygonAnnotation *mpPolygonAnnotation;
  RectangleAnnotation *mpRectangleAnnotation;
  EllipseAnnotation *mpEllipseAnnotation;
  TextAnnotation *mpTextAnnotation;
  BitmapAnnotation *mpBitmapAnnotation;
  Label *mpShapePropertiesHeading;
  QFrame *mHorizontalLine;
  QGroupBox *mpTransformationGroupBox;
  Label *mpOriginXLabel;
  DoubleSpinBox *mpOriginXSpinBox;
  Label *mpOriginYLabel;
  DoubleSpinBox *mpOriginYSpinBox;
  Label *mpRotationLabel;
  DoubleSpinBox *mpRotationSpinBox;
  QGroupBox *mpExtentGroupBox;
  Label *mpExtent1XLabel;
  DoubleSpinBox *mpExtent1XSpinBox;
  Label *mpExtent1YLabel;
  DoubleSpinBox *mpExtent1YSpinBox;
  Label *mpExtent2XLabel;
  DoubleSpinBox *mpExtent2XSpinBox;
  Label *mpExtent2YLabel;
  DoubleSpinBox *mpExtent2YSpinBox;
  QGroupBox *mpBorderStyleGroupBox;
  Label *mpBorderPatternLabel;
  QComboBox *mpBorderPatternComboBox;
  Label *mpRadiusLabel;
  DoubleSpinBox *mpRadiusSpinBox;
  QGroupBox *mpAngleGroupBox;
  Label *mpStartAngleLabel;
  DoubleSpinBox *mpStartAngleSpinBox;
  Label *mpEndAngleLabel;
  DoubleSpinBox *mpEndAngleSpinBox;
  QGroupBox *mpTextGroupBox;
  QLineEdit *mpTextTextBox;
  QGroupBox *mpFontAndTextStyleGroupBox;
  Label *mpFontNameLabel;
  QFontComboBox *mpFontNameComboBox;
  Label *mpFontSizeLabel;
  DoubleSpinBox *mpFontSizeSpinBox;
  Label *mpFontStyleLabel;
  QCheckBox *mpTextBoldCheckBox;
  QCheckBox *mpTextItalicCheckBox;
  QCheckBox *mpTextUnderlineCheckBox;
  Label *mpTextHorizontalAlignmentLabel;
  QComboBox *mpTextHorizontalAlignmentComboBox;
  QGroupBox *mpLineStyleGroupBox;
  Label *mpLineColorLabel;
  QPushButton *mpLinePickColorButton;
  QColor mLineColor;
  Label *mpLinePatternLabel;
  QComboBox *mpLinePatternComboBox;
  Label *mpLineThicknessLabel;
  DoubleSpinBox *mpLineThicknessSpinBox;
  Label *mpLineSmoothLabel;
  QCheckBox *mpLineSmoothCheckBox;
  QGroupBox *mpArrowStyleGroupBox;
  Label *mpLineStartArrowLabel;
  QComboBox *mpLineStartArrowComboBox;
  Label *mpLineEndArrowLabel;
  QComboBox *mpLineEndArrowComboBox;
  Label *mpLineArrowSizeLabel;
  DoubleSpinBox *mpLineArrowSizeSpinBox;
  QGroupBox *mpFillStyleGroupBox;
  Label *mpFillColorLabel;
  QPushButton *mpFillPickColorButton;
  QColor mFillColor;
  Label *mpFillPatternLabel;
  QComboBox *mpFillPatternComboBox;
  QGroupBox *mpImageGroupBox;
  Label *mpFileLabel;
  QLineEdit *mpFileTextBox;
  QPushButton *mpBrowseFileButton;
  QCheckBox *mpStoreImageInModelCheckBox;
  QScrollArea *mpPreviewImageScrollArea;
  Label *mpPreviewImageLabel;
  QGroupBox *mpPointsGroupBox;
  QTableWidget *mpPointsTableWidget;
  QToolButton *mpMovePointUpButton;
  QToolButton *mpMovePointDownButton;
  QDialogButtonBox *mpPointsButtonBox;
  QToolButton *mpAddPointButton;
  QToolButton *mpRemovePointButton;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QPushButton *mpApplyButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void linePickColor();
  void fillPickColor();
  void movePointUp();
  void movePointDown();
  void addPoint();
  void removePoint();
  void saveShapeProperties();
  bool applyShapeProperties();
  void browseImageFile();
  void storeImageInModelToggled(bool checked);
};

#endif // SHAPEPROPERTIESDIALOG_H
