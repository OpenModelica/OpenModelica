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

#include <limits>

#include "ShapePropertiesDialog.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Options/NotificationsDialog.h"
#include "Modeling/Commands.h"

#include <QHeaderView>
#include <QColorDialog>
#include <QMessageBox>

ShapePropertiesDialog::ShapePropertiesDialog(ShapeAnnotation *pShapeAnnotation, QWidget *pParent)
  : QDialog(pParent)
{
  mpShapeAnnotation = pShapeAnnotation;
  mOldAnnotation = "";
  mpLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
  mpPolygonAnnotation = dynamic_cast<PolygonAnnotation*>(mpShapeAnnotation);
  mpRectangleAnnotation = dynamic_cast<RectangleAnnotation*>(mpShapeAnnotation);
  mpEllipseAnnotation = dynamic_cast<EllipseAnnotation*>(mpShapeAnnotation);
  mpTextAnnotation = dynamic_cast<TextAnnotation*>(mpShapeAnnotation);
  mpBitmapAnnotation = dynamic_cast<BitmapAnnotation*>(mpShapeAnnotation);
  QString title = getTitle();
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(title).append(" ").append(Helper::properties));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading label
  mpShapePropertiesHeading = Utilities::getHeadingLabel(QString(title).append(" ").append(Helper::properties));
  // set separator line
  mHorizontalLine = Utilities::getHeadingLine();
  // Transformations Group Box
  mpTransformationGroupBox = new QGroupBox(tr("Transformation"));
  mpOriginXLabel = new Label(Helper::originX);
  mpOriginXSpinBox = new DoubleSpinBox;
  mpOriginXSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpOriginXSpinBox->setValue(mpShapeAnnotation->getOrigin().x());
  mpOriginXSpinBox->setSingleStep(1);
  mpOriginYLabel = new Label(Helper::originY);
  mpOriginYSpinBox = new DoubleSpinBox;
  mpOriginYSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpOriginYSpinBox->setValue(mpShapeAnnotation->getOrigin().y());
  mpOriginYSpinBox->setSingleStep(1);
  mpRotationLabel = new Label(Helper::rotation);
  mpRotationSpinBox = new DoubleSpinBox;
  mpRotationSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpRotationSpinBox->setValue(mpShapeAnnotation->getRotation());
  mpRotationSpinBox->setSingleStep(90);
  // set the Transformations Group Box layout
  QGridLayout *pTransformationGridLayout = new QGridLayout;
  pTransformationGridLayout->setColumnStretch(1, 1);
  pTransformationGridLayout->setColumnStretch(3, 1);
  pTransformationGridLayout->setColumnStretch(5, 1);
  pTransformationGridLayout->addWidget(mpOriginXLabel, 0, 0);
  pTransformationGridLayout->addWidget(mpOriginXSpinBox, 0, 1);
  pTransformationGridLayout->addWidget(mpOriginYLabel, 0, 2);
  pTransformationGridLayout->addWidget(mpOriginYSpinBox, 0, 3);
  pTransformationGridLayout->addWidget(mpRotationLabel, 0, 4);
  pTransformationGridLayout->addWidget(mpRotationSpinBox, 0, 5);
  mpTransformationGroupBox->setLayout(pTransformationGridLayout);
  // Extent Group Box
  mpExtentGroupBox = new QGroupBox(Helper::extent);
  // Extent1X
  QList<QPointF> extents = mpShapeAnnotation->getExtents();
  mpExtent1XLabel = new Label(Helper::extent1X);
  mpExtent1XSpinBox = new DoubleSpinBox;
  mpExtent1XSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpExtent1XSpinBox->setValue(extents.size() > 0 ? extents.at(0).x() : 0);
  mpExtent1XSpinBox->setSingleStep(10);
  mpExtent1YLabel = new Label(Helper::extent1Y);
  mpExtent1YSpinBox = new DoubleSpinBox;
  mpExtent1YSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpExtent1YSpinBox->setValue(extents.size() > 0 ? extents.at(0).y() : 0);
  mpExtent1YSpinBox->setSingleStep(10);
  mpExtent2XLabel = new Label(Helper::extent2X);
  mpExtent2XSpinBox = new DoubleSpinBox;
  mpExtent2XSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpExtent2XSpinBox->setValue(extents.size() > 0 ? extents.at(1).x() : 0);
  mpExtent2XSpinBox->setSingleStep(10);
  mpExtent2YLabel = new Label(Helper::extent2Y);
  mpExtent2YSpinBox = new DoubleSpinBox;
  mpExtent2YSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpExtent2YSpinBox->setValue(extents.size() > 0 ? extents.at(1).y() : 0);
  mpExtent2YSpinBox->setSingleStep(10);
  // set the extents Group Box layout
  QGridLayout *pExtentGroupBoxLayout = new QGridLayout;
  pExtentGroupBoxLayout->setColumnStretch(1, 1);
  pExtentGroupBoxLayout->setColumnStretch(3, 1);
  pExtentGroupBoxLayout->addWidget(mpExtent1XLabel, 0, 0);
  pExtentGroupBoxLayout->addWidget(mpExtent1XSpinBox, 0, 1);
  pExtentGroupBoxLayout->addWidget(mpExtent1YLabel, 0, 2);
  pExtentGroupBoxLayout->addWidget(mpExtent1YSpinBox, 0, 3);
  pExtentGroupBoxLayout->addWidget(mpExtent2XLabel, 1, 0);
  pExtentGroupBoxLayout->addWidget(mpExtent2XSpinBox, 1, 1);
  pExtentGroupBoxLayout->addWidget(mpExtent2YLabel, 1, 2);
  pExtentGroupBoxLayout->addWidget(mpExtent2YSpinBox, 1, 3);
  mpExtentGroupBox->setLayout(pExtentGroupBoxLayout);
  // Border style Group Box
  mpBorderStyleGroupBox = new QGroupBox(tr("Border Style"));
  // border pattern
  mpBorderPatternLabel = new Label(Helper::pattern);
  mpBorderPatternComboBox = new QComboBox;
  mpBorderPatternComboBox->addItem(StringHandler::getBorderPatternString(StringHandler::BorderNone));
  mpBorderPatternComboBox->addItem(StringHandler::getBorderPatternString(StringHandler::BorderRaised));
  mpBorderPatternComboBox->addItem(StringHandler::getBorderPatternString(StringHandler::BorderSunken));
  mpBorderPatternComboBox->addItem(StringHandler::getBorderPatternString(StringHandler::BorderEngraved));
  int currentIndex = mpBorderPatternComboBox->findText(StringHandler::getBorderPatternString(
                                                         mpShapeAnnotation->getBorderPattern()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpBorderPatternComboBox->setCurrentIndex(currentIndex);
  }
  // radius
  mpRadiusLabel = new Label(Helper::radius);
  mpRadiusSpinBox = new DoubleSpinBox;
  mpRadiusSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpRadiusSpinBox->setValue(mpShapeAnnotation->getRadius());
  mpRadiusSpinBox->setSingleStep(1);
  // set the border style Group Box layout
  QGridLayout *pBorderStyleGridLayout = new QGridLayout;
  pBorderStyleGridLayout->setColumnStretch(1, 1);
  pBorderStyleGridLayout->setColumnStretch(3, 1);
  pBorderStyleGridLayout->addWidget(mpBorderPatternLabel, 0, 0);
  pBorderStyleGridLayout->addWidget(mpBorderPatternComboBox, 0, 1);
  pBorderStyleGridLayout->addWidget(mpRadiusLabel, 0, 2);
  pBorderStyleGridLayout->addWidget(mpRadiusSpinBox, 0, 3);
  mpBorderStyleGroupBox->setLayout(pBorderStyleGridLayout);
  // Angle Group Box
  mpAngleGroupBox = new QGroupBox(tr("Angle"));
  // start angle
  mpStartAngleLabel = new Label(Helper::startAngle);
  mpStartAngleSpinBox = new DoubleSpinBox;
  mpStartAngleSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpStartAngleSpinBox->setValue(mpShapeAnnotation->getStartAngle());
  mpStartAngleSpinBox->setSingleStep(90);
  // end angle
  mpEndAngleLabel = new Label(Helper::endAngle);
  mpEndAngleSpinBox = new DoubleSpinBox;
  mpEndAngleSpinBox->setRange(-std::numeric_limits<double>::max(), std::numeric_limits<double>::max());
  mpEndAngleSpinBox->setValue(mpShapeAnnotation->getEndAngle());
  mpEndAngleSpinBox->setSingleStep(90);
  // set the border style Group Box layout
  QGridLayout *pAngleGridLayout = new QGridLayout;
  pAngleGridLayout->setColumnStretch(1, 1);
  pAngleGridLayout->setColumnStretch(3, 1);
  pAngleGridLayout->addWidget(mpStartAngleLabel, 0, 0);
  pAngleGridLayout->addWidget(mpStartAngleSpinBox, 0, 1);
  pAngleGridLayout->addWidget(mpEndAngleLabel, 0, 2);
  pAngleGridLayout->addWidget(mpEndAngleSpinBox, 0, 3);
  mpAngleGroupBox->setLayout(pAngleGridLayout);
  // Text Group Box
  mpTextGroupBox = new QGroupBox(tr("Text"));
  mpTextTextBox = new QLineEdit(mpShapeAnnotation->getTextString());
  mpTextTextBox->setToolTip(tr("Use \\n for multi-line text"));
  // set the Text Group Box layout
  QHBoxLayout *pTextGroupBoxLayout = new QHBoxLayout;
  pTextGroupBoxLayout->addWidget(mpTextTextBox);
  mpTextGroupBox->setLayout(pTextGroupBoxLayout);
  // Font Style Group Box
  mpFontAndTextStyleGroupBox = new QGroupBox(tr("Font && Text Style"));
  mpFontNameLabel = new Label(Helper::name);
  mpFontNameComboBox = new QFontComboBox;
  mpFontNameComboBox->insertItem(0, "Default");
  currentIndex = mpFontNameComboBox->findText(mpShapeAnnotation->getFontName(), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpFontNameComboBox->setCurrentIndex(currentIndex);
  } else {
    mpFontNameComboBox->setCurrentIndex(0);
  }
  mpFontSizeLabel = new Label(Helper::size);
  mpFontSizeSpinBox = new DoubleSpinBox;
  mpFontSizeSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpFontSizeSpinBox->setValue(mpShapeAnnotation->getFontSize());
  mpFontSizeSpinBox->setSingleStep(1);
  mpFontStyleLabel = new Label(tr("Style:"));
  mpTextBoldCheckBox = new QCheckBox(Helper::bold);
  mpTextBoldCheckBox->setChecked(StringHandler::getFontWeight(mpShapeAnnotation->getTextStyles()) == QFont::Bold ? true : false);
  mpTextItalicCheckBox = new QCheckBox(Helper::italic);
  mpTextItalicCheckBox->setChecked(StringHandler::getFontItalic(mpShapeAnnotation->getTextStyles()));
  mpTextUnderlineCheckBox = new QCheckBox(Helper::underline);
  mpTextUnderlineCheckBox->setChecked(StringHandler::getFontUnderline(mpShapeAnnotation->getTextStyles()));
  mpTextHorizontalAlignmentLabel = new Label(tr("Horizontal Alignment:"));
  mpTextHorizontalAlignmentComboBox = new QComboBox;
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentLeft));
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentCenter));
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentRight));
  currentIndex = mpTextHorizontalAlignmentComboBox->findText(StringHandler::getTextAlignmentString(
                                                               mpShapeAnnotation->getTextHorizontalAlignment()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpTextHorizontalAlignmentComboBox->setCurrentIndex(currentIndex);
  }
  // set the Font Style Group Box layout
  QGridLayout *pFontAndTextStyleGroupBox = new QGridLayout;
  pFontAndTextStyleGroupBox->setColumnStretch(5, 1);
  pFontAndTextStyleGroupBox->addWidget(mpFontNameLabel, 0, 0);
  pFontAndTextStyleGroupBox->addWidget(mpFontNameComboBox, 0, 1, 1, 3);
  pFontAndTextStyleGroupBox->addWidget(mpFontSizeLabel, 0, 4);
  pFontAndTextStyleGroupBox->addWidget(mpFontSizeSpinBox, 0, 5);
  pFontAndTextStyleGroupBox->addWidget(mpFontStyleLabel, 1, 0);
  pFontAndTextStyleGroupBox->addWidget(mpTextBoldCheckBox, 1, 1);
  pFontAndTextStyleGroupBox->addWidget(mpTextItalicCheckBox, 1, 2);
  pFontAndTextStyleGroupBox->addWidget(mpTextUnderlineCheckBox, 1, 3);
  pFontAndTextStyleGroupBox->addWidget(mpTextHorizontalAlignmentLabel, 1, 4);
  pFontAndTextStyleGroupBox->addWidget(mpTextHorizontalAlignmentComboBox, 1, 5);
  mpFontAndTextStyleGroupBox->setLayout(pFontAndTextStyleGroupBox);
  // Line style Group Box
  mpLineStyleGroupBox = new QGroupBox(Helper::lineStyle);
  // Line Color
  mpLineColorLabel = new Label(Helper::color);
  mpLinePickColorButton = new QPushButton(Helper::pickColor);
  mpLinePickColorButton->setAutoDefault(false);
  connect(mpLinePickColorButton, SIGNAL(clicked()), SLOT(linePickColor()));
  setLineColor(mpShapeAnnotation->getLineColor());
  setLinePickColorButtonIcon();
  // Line Pattern
  mpLinePatternLabel = new Label(Helper::pattern);
  mpLinePatternComboBox = StringHandler::getLinePatternComboBox();
  currentIndex = mpLinePatternComboBox->findText(StringHandler::getLinePatternString(mpShapeAnnotation->getLinePattern()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpLinePatternComboBox->setCurrentIndex(currentIndex);
  }
  // Line Thickness
  mpLineThicknessLabel = new Label(Helper::thickness);
  mpLineThicknessSpinBox = new DoubleSpinBox;
  mpLineThicknessSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineThicknessSpinBox->setValue(mpShapeAnnotation->getLineThickness());
  mpLineThicknessSpinBox->setSingleStep(0.25);
  // Line smooth
  mpLineSmoothLabel = new Label(Helper::smooth);
  mpLineSmoothCheckBox = new QCheckBox(Helper::bezier);
  if (mpShapeAnnotation->getSmooth() == StringHandler::SmoothBezier) {
    mpLineSmoothCheckBox->setChecked(true);
  }
  // set the Line style Group Box layout
  QGridLayout *pLineStyleGroupBoxLayout = new QGridLayout;
  pLineStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pLineStyleGroupBoxLayout->setColumnStretch(1, 1);
  pLineStyleGroupBoxLayout->addWidget(mpLineColorLabel, 0, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLinePickColorButton, 0, 1);
  pLineStyleGroupBoxLayout->addWidget(mpLinePatternLabel, 1, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLinePatternComboBox, 1, 1);
  pLineStyleGroupBoxLayout->addWidget(mpLineThicknessLabel, 2, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLineThicknessSpinBox, 2, 1);
  if (mpLineAnnotation || mpPolygonAnnotation) {
    pLineStyleGroupBoxLayout->addWidget(mpLineSmoothLabel, 3, 0);
    pLineStyleGroupBoxLayout->addWidget(mpLineSmoothCheckBox, 3, 1);
  }
  mpLineStyleGroupBox->setLayout(pLineStyleGroupBoxLayout);
  // Arrow style Group Box
  mpArrowStyleGroupBox = new QGroupBox(tr("Arrow Style"));
  // Start Arrow
  mpLineStartArrowLabel = new Label(Helper::startArrow);
  mpLineStartArrowComboBox = StringHandler::getStartArrowComboBox();
  currentIndex = mpLineStartArrowComboBox->findText(StringHandler::getArrowString(mpShapeAnnotation->getStartArrow()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpLineStartArrowComboBox->setCurrentIndex(currentIndex);
  }
  mpLineEndArrowLabel = new Label(Helper::endArrow);
  mpLineEndArrowComboBox = StringHandler::getEndArrowComboBox();
  currentIndex = mpLineEndArrowComboBox->findText(StringHandler::getArrowString(mpShapeAnnotation->getEndArrow()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpLineEndArrowComboBox->setCurrentIndex(currentIndex);
  }
  mpLineArrowSizeLabel = new Label(Helper::arrowSize);
  mpLineArrowSizeSpinBox = new DoubleSpinBox;
  mpLineArrowSizeSpinBox->setRange(0, std::numeric_limits<double>::max());
  mpLineArrowSizeSpinBox->setValue(mpShapeAnnotation->getArrowSize());
  mpLineArrowSizeSpinBox->setSingleStep(1);
  // set the Arrow style Group Box layout
  QGridLayout *pArrowStyleGroupBoxLayout = new QGridLayout;
  pArrowStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pArrowStyleGroupBoxLayout->setColumnStretch(1, 1);
  pArrowStyleGroupBoxLayout->addWidget(mpLineStartArrowLabel, 0, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineStartArrowComboBox, 0, 1);
  pArrowStyleGroupBoxLayout->addWidget(mpLineEndArrowLabel, 1, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineEndArrowComboBox, 1, 1);
  pArrowStyleGroupBoxLayout->addWidget(mpLineArrowSizeLabel, 2, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineArrowSizeSpinBox, 2, 1);
  mpArrowStyleGroupBox->setLayout(pArrowStyleGroupBoxLayout);
  // Fill style Group Box
  mpFillStyleGroupBox = new QGroupBox(Helper::fillStyle);
  // Fill Color
  mpFillColorLabel = new Label(Helper::color);
  mpFillPickColorButton = new QPushButton(Helper::pickColor);
  mpFillPickColorButton->setAutoDefault(false);
  connect(mpFillPickColorButton, SIGNAL(clicked()), SLOT(fillPickColor()));
  setFillColor(mpShapeAnnotation->getFillColor());
  setFillPickColorButtonIcon();
  // Fill Pattern
  mpFillPatternLabel = new Label(Helper::pattern);
  mpFillPatternComboBox = StringHandler::getFillPatternComboBox();
  currentIndex = mpFillPatternComboBox->findText(StringHandler::getFillPatternString(mpShapeAnnotation->getFillPattern()), Qt::MatchExactly);
  if (currentIndex > -1) {
    mpFillPatternComboBox->setCurrentIndex(currentIndex);
  }
  // set the Fill style Group Box layout
  QGridLayout *pFillStyleGroupBoxLayout = new QGridLayout;
  pFillStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pFillStyleGroupBoxLayout->setColumnStretch(1, 1);
  pFillStyleGroupBoxLayout->addWidget(mpFillColorLabel, 0, 0);
  pFillStyleGroupBoxLayout->addWidget(mpFillPickColorButton, 0, 1);
  pFillStyleGroupBoxLayout->addWidget(mpFillPatternLabel, 1, 0);
  pFillStyleGroupBoxLayout->addWidget(mpFillPatternComboBox, 1, 1);
  mpFillStyleGroupBox->setLayout(pFillStyleGroupBoxLayout);
  // Image Group Box
  mpImageGroupBox = new QGroupBox(tr("Image"));
  mpFileLabel = new Label(Helper::fileLabel);
  mpFileTextBox = new QLineEdit(mpShapeAnnotation->getFileName());
  mpFileTextBox->setEnabled(false);
  mpBrowseFileButton = new QPushButton(Helper::browse);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(browseImageFile()));
  mpStoreImageInModelCheckBox = new QCheckBox(tr("Store image in model"));
  mpStoreImageInModelCheckBox->setChecked(mpShapeAnnotation->getFileName().isEmpty());
  connect(mpStoreImageInModelCheckBox, SIGNAL(toggled(bool)), SLOT(storeImageInModelToggled(bool)));
  mpPreviewImageLabel = new Label;
  mpPreviewImageLabel->setAlignment(Qt::AlignCenter);
  mpPreviewImageLabel->setPixmap(QPixmap::fromImage(mpShapeAnnotation->getImage()));
  mpPreviewImageScrollArea = new QScrollArea;
  mpPreviewImageScrollArea->setMinimumSize(400, 150);
  mpPreviewImageScrollArea->setWidgetResizable(true);
  mpPreviewImageScrollArea->setWidget(mpPreviewImageLabel);
  // set the Image Group Box
  QGridLayout *pImageGroupBoxLayout = new QGridLayout;
  pImageGroupBoxLayout->addWidget(mpFileLabel, 0, 0);
  pImageGroupBoxLayout->addWidget(mpFileTextBox, 0, 1);
  pImageGroupBoxLayout->addWidget(mpBrowseFileButton, 0, 2);
  pImageGroupBoxLayout->addWidget(mpStoreImageInModelCheckBox, 1, 0, 1, 3);
  pImageGroupBoxLayout->addWidget(mpPreviewImageScrollArea, 2, 0, 1, 3);
  mpImageGroupBox->setLayout(pImageGroupBoxLayout);
  // Points Group Box
  mpPointsGroupBox = new QGroupBox(tr("Points"));
  mpPointsTableWidget = new QTableWidget;
  mpPointsTableWidget->setTextElideMode(Qt::ElideMiddle);
  mpPointsTableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
  mpPointsTableWidget->setSelectionMode(QAbstractItemView::SingleSelection);
  mpPointsTableWidget->setColumnCount(2);
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  mpPointsTableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
#else /* Qt4 */
  mpPointsTableWidget->horizontalHeader()->setResizeMode(QHeaderView::Stretch);
#endif
  mpPointsTableWidget->horizontalHeader()->setDefaultAlignment(Qt::AlignLeft);
  QStringList headerLabels;
  headerLabels << "X" << "Y";
  mpPointsTableWidget->setHorizontalHeaderLabels(headerLabels);
  // add points to points table widget
  QList<QPointF> points = mpShapeAnnotation->getPoints();
  mpPointsTableWidget->setRowCount(points.size());
  int rowIndex = 0;
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  foreach (QPointF point, points) {
    QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(QString::number(point.x()));
    if ((rowIndex == 0 || rowIndex == points.size() - 1) && (lineType == LineAnnotation::ConnectionType)) {
      pTableWidgetItemX->setFlags(Qt::NoItemFlags);
    } else {
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
    }
    mpPointsTableWidget->setItem(rowIndex, 0, pTableWidgetItemX);
    QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(QString::number(point.y()));
    if ((rowIndex == 0 || rowIndex == points.size() - 1) && (lineType == LineAnnotation::ConnectionType)) {
      pTableWidgetItemY->setFlags(Qt::NoItemFlags);
    } else {
      pTableWidgetItemY->setFlags(pTableWidgetItemY->flags() | Qt::ItemIsEditable);
    }
    mpPointsTableWidget->setItem(rowIndex, 1, pTableWidgetItemY);
    rowIndex++;
  }
  if (rowIndex > 0) {
    if (lineType == LineAnnotation::ConnectionType) {
      mpPointsTableWidget->setCurrentCell(1, 1);
    } else {
      mpPointsTableWidget->setCurrentCell(0, 0);
    }
  }
  // points navigation buttons
  mpMovePointUpButton = new QToolButton;
  mpMovePointUpButton->setObjectName("ShapePointsButton");
  mpMovePointUpButton->setIcon(QIcon(":/Resources/icons/up.svg"));
  mpMovePointUpButton->setToolTip(tr("Move point up"));
  connect(mpMovePointUpButton, SIGNAL(clicked()), SLOT(movePointUp()));
  mpMovePointDownButton = new QToolButton;
  mpMovePointDownButton->setObjectName("ShapePointsButton");
  mpMovePointDownButton->setIcon(QIcon(":/Resources/icons/down.svg"));
  mpMovePointDownButton->setToolTip(tr("Move point down"));
  connect(mpMovePointDownButton, SIGNAL(clicked()), SLOT(movePointDown()));
  // points manipulation buttons
  mpAddPointButton = new QToolButton;
  mpAddPointButton->setObjectName("ShapePointsButton");
  mpAddPointButton->setIcon(QIcon(":/Resources/icons/add-icon.svg"));
  mpAddPointButton->setToolTip(tr("Add new point"));
  connect(mpAddPointButton, SIGNAL(clicked()), SLOT(addPoint()));
  mpRemovePointButton = new QToolButton;
  mpRemovePointButton->setObjectName("ShapePointsButton");
  mpRemovePointButton->setIcon(QIcon(":/Resources/icons/delete.svg"));
  mpRemovePointButton->setToolTip(tr("Remove point"));
  connect(mpRemovePointButton, SIGNAL(clicked()), SLOT(removePoint()));
  mpPointsButtonBox = new QDialogButtonBox(Qt::Vertical);
  mpPointsButtonBox->addButton(mpMovePointUpButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpMovePointDownButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpAddPointButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpRemovePointButton, QDialogButtonBox::ActionRole);
  // set the Points Group Box layout
  QGridLayout *pPointsGroupBoxLayout = new QGridLayout;
  pPointsGroupBoxLayout->setAlignment(Qt::AlignTop);
  pPointsGroupBoxLayout->setColumnStretch(0, 1);
  pPointsGroupBoxLayout->addWidget(mpPointsTableWidget, 0, 0);
  pPointsGroupBoxLayout->addWidget(mpPointsButtonBox, 0, 1);
  mpPointsGroupBox->setLayout(pPointsGroupBoxLayout);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(saveShapeProperties()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpApplyButton = new QPushButton(Helper::apply);
  mpApplyButton->setAutoDefault(false);
  connect(mpApplyButton, SIGNAL(clicked()), this, SLOT(applyShapeProperties()));
  if (mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() ||
      mpShapeAnnotation->isInheritedShape()) {
    mpOkButton->setDisabled(true);
    mpApplyButton->setDisabled(true);
  }
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpApplyButton, QDialogButtonBox::ActionRole);
  // main layout
  int row = 0;
  int colSpan = 2;
  if (mpBitmapAnnotation) colSpan = 1;
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpShapePropertiesHeading, row++, 0, 1, colSpan);
  pMainLayout->addWidget(mHorizontalLine, row++, 0, 1, colSpan);
  pMainLayout->addWidget(mpTransformationGroupBox, row++, 0, 1, colSpan);
  if (!mpLineAnnotation && !mpPolygonAnnotation) {
    pMainLayout->addWidget(mpExtentGroupBox, row++, 0, 1, colSpan);
  }
  if (mpRectangleAnnotation) {
    pMainLayout->addWidget(mpBorderStyleGroupBox, row++, 0, 1, colSpan);
  }
  if (mpEllipseAnnotation) {
    pMainLayout->addWidget(mpAngleGroupBox, row++, 0, 1, colSpan);
  }
  if (mpTextAnnotation) {
    pMainLayout->addWidget(mpTextGroupBox, row++, 0, 1, colSpan);
    pMainLayout->addWidget(mpFontAndTextStyleGroupBox, row++, 0, 1, colSpan);
  }
  if (mpBitmapAnnotation) {
    pMainLayout->addWidget(mpImageGroupBox, row++, 0, 1, colSpan);
  } else {
    pMainLayout->addWidget(mpLineStyleGroupBox, row, 0);
  }
  if (mpLineAnnotation) {
    pMainLayout->addWidget(mpArrowStyleGroupBox, row++, 1);
  } else if (!mpBitmapAnnotation) {
    pMainLayout->addWidget(mpFillStyleGroupBox, row++, 1);
  }
  if (mpLineAnnotation || mpPolygonAnnotation) {
    pMainLayout->addWidget(mpPointsGroupBox, row++, 0, 1, colSpan);
  }
  pMainLayout->addWidget(mpButtonBox, row, 0, 1, colSpan);
  setLayout(pMainLayout);
}

QString ShapePropertiesDialog::getTitle()
{
  if (mpLineAnnotation) {
    if (mpLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
      return "Connection";
    } else if (mpLineAnnotation->getLineType() == LineAnnotation::TransitionType) {
      return "Transition";
    } else if (mpLineAnnotation->getLineType() == LineAnnotation::InitialStateType) {
      return "Initial State";
    } else {
      return "Line";
    }
  } else if (mpPolygonAnnotation) {
    return "Polygon";
  } else if (mpRectangleAnnotation) {
    return "Rectangle";
  } else if (mpEllipseAnnotation) {
    return "Ellipse";
  } else if (mpTextAnnotation) {
    return "Text";
  } else if (mpBitmapAnnotation) {
    return "Bitmap";
  } else {
    return "";
  }
}

void ShapePropertiesDialog::setLineColor(QColor color)
{
  mLineColor = color;
}

QColor ShapePropertiesDialog::getLineColor()
{
  return mLineColor;
}

void ShapePropertiesDialog::setLinePickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getLineColor());
  mpLinePickColorButton->setIcon(pixmap);
}

void ShapePropertiesDialog::setFillColor(QColor color)
{
  mFillColor = color;
}

QColor ShapePropertiesDialog::getFillColor()
{
  return mFillColor;
}

void ShapePropertiesDialog::setFillPickColorButtonIcon()
{
  QPixmap pixmap(Helper::iconSize);
  pixmap.fill(getFillColor());
  mpFillPickColorButton->setIcon(pixmap);
}

void ShapePropertiesDialog::linePickColor()
{
  QColor color = QColorDialog::getColor(getLineColor());
  // if user press ESC
  if (!color.isValid()) {
    return;
  }
  setLineColor(color);
  setLinePickColorButtonIcon();
}

void ShapePropertiesDialog::fillPickColor()
{
  QColor color = QColorDialog::getColor(getFillColor());
  // if user press ESC
  if (!color.isValid()) {
    return;
  }
  setFillColor(color);
  setFillPickColorButtonIcon();
}

void ShapePropertiesDialog::movePointUp()
{
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  if (lineType == LineAnnotation::InitialStateType) {
    return;
  }
  if (mpPointsTableWidget->selectedItems().size() > 0) {
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == 0) {
      return;
    }
    if (row == 1 && (lineType == LineAnnotation::ConnectionType || lineType == LineAnnotation::TransitionType)) {
      return;
    }
    QTableWidgetItem *pSourceItemX = mpPointsTableWidget->takeItem(row, 0);
    QTableWidgetItem *pSourceItemY = mpPointsTableWidget->takeItem(row, 1);
    QTableWidgetItem *pDestinationItemX = mpPointsTableWidget->takeItem(row - 1, 0);
    QTableWidgetItem *pDestinationItemY = mpPointsTableWidget->takeItem(row - 1, 1);
    mpPointsTableWidget->setItem(row - 1, 0, pSourceItemX);
    mpPointsTableWidget->setItem(row - 1, 1, pSourceItemY);
    mpPointsTableWidget->setItem(row, 0, pDestinationItemX);
    mpPointsTableWidget->setItem(row, 1, pDestinationItemY);
    mpPointsTableWidget->setCurrentCell(row - 1, 0);
  }
}

void ShapePropertiesDialog::movePointDown()
{
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  if (lineType == LineAnnotation::InitialStateType) {
    return;
  }
  if (mpPointsTableWidget->selectedItems().size() > 0) {
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == mpPointsTableWidget->rowCount() - 1) {
      return;
    }
    if (row == mpPointsTableWidget->rowCount() - 2 && (lineType == LineAnnotation::ConnectionType || lineType == LineAnnotation::TransitionType)) {
      return;
    }
    QTableWidgetItem *pSourceItemX = mpPointsTableWidget->takeItem(row, 0);
    QTableWidgetItem *pSourceItemY = mpPointsTableWidget->takeItem(row, 1);
    QTableWidgetItem *pDestinationItemX = mpPointsTableWidget->takeItem(row + 1, 0);
    QTableWidgetItem *pDestinationItemY = mpPointsTableWidget->takeItem(row + 1, 1);
    mpPointsTableWidget->setItem(row + 1, 0, pSourceItemX);
    mpPointsTableWidget->setItem(row + 1, 1, pSourceItemY);
    mpPointsTableWidget->setItem(row, 0, pDestinationItemX);
    mpPointsTableWidget->setItem(row, 1, pDestinationItemY);
    mpPointsTableWidget->setCurrentCell(row + 1, 0);
  }
}

void ShapePropertiesDialog::addPoint()
{
  if (mpPointsTableWidget->selectedItems().size() > 0) {
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
    if (lineType == LineAnnotation::InitialStateType) {
      return;
    }
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == mpPointsTableWidget->rowCount() - 1) {
      /* insert a new row which is similar to last row. */
      mpPointsTableWidget->insertRow(row + 1);
      QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(mpPointsTableWidget->item(row, 0)->text());
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 0, pTableWidgetItemX);
      QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(mpPointsTableWidget->item(row, 1)->text());
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 1, pTableWidgetItemY);
      mpPointsTableWidget->setCurrentCell(row + 1, 0);
    } else {
      /* get middle of two surronding points */
      QPointF point1(mpPointsTableWidget->item(row, 0)->text().toFloat(), mpPointsTableWidget->item(row, 1)->text().toFloat());
      QPointF point2(mpPointsTableWidget->item(row + 1, 0)->text().toFloat(), mpPointsTableWidget->item(row + 1, 1)->text().toFloat());
      QPointF point3 = (point1 + point2) / 2;
      /* insert new row */
      mpPointsTableWidget->insertRow(row + 1);
      QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(QString::number(point3.x()));
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 0, pTableWidgetItemX);
      QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(QString::number(point3.y()));
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 1, pTableWidgetItemY);
      mpPointsTableWidget->setCurrentCell(row + 1, 0);
    }
  } else if (mpLineAnnotation && mpPointsTableWidget->rowCount() == 2 &&
             (mpLineAnnotation->getLineType() == LineAnnotation::ConnectionType ||
              mpLineAnnotation->getLineType() == LineAnnotation::TransitionType)) {
    /* get middle of two surronding points */
    QPointF point1(mpPointsTableWidget->item(0, 0)->text().toFloat(), mpPointsTableWidget->item(0, 1)->text().toFloat());
    QPointF point2(mpPointsTableWidget->item(1, 0)->text().toFloat(), mpPointsTableWidget->item(1, 1)->text().toFloat());
    QPointF point3 = (point1 + point2) / 2;
    /* insert new row */
    mpPointsTableWidget->insertRow(1);
    QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(QString::number(point3.x()));
    pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
    mpPointsTableWidget->setItem(1, 0, pTableWidgetItemX);
    QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(QString::number(point3.y()));
    pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
    mpPointsTableWidget->setItem(1, 1, pTableWidgetItemY);
    mpPointsTableWidget->setCurrentCell(1, 0);
  }
}

void ShapePropertiesDialog::removePoint()
{
  if (mpPointsTableWidget->selectedItems().size() > 0) {
    if ((mpLineAnnotation && mpPointsTableWidget->rowCount() > 2) || (mpPolygonAnnotation && mpPointsTableWidget->rowCount() > 4)) {
      LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
      if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
      int row = mpPointsTableWidget->selectedItems().at(0)->row();
      if (lineType == LineAnnotation::InitialStateType && row == 0) {
        return;
      }
      mpPointsTableWidget->removeRow(row);
    }
  }
}

void ShapePropertiesDialog::saveShapeProperties()
{
  if (applyShapeProperties()) {
    mpShapeAnnotation->emitChanged();
    accept();
  }
}

bool ShapePropertiesDialog::applyShapeProperties()
{
  // we need to set focus on the OK button otherwise QTableWidget doesn't read any active cell editing value.
  mpOkButton->setFocus(Qt::ActiveWindowFocusReason);
  // save the old annotation before applying anything.
  mOldAnnotation = mpShapeAnnotation->getOMCShapeAnnotation();
  /* validate points */
  for (int i = 0 ; i < mpPointsTableWidget->rowCount() ; i++) {
    QTableWidgetItem *pTableWidgetItem = mpPointsTableWidget->item(i, 0); /* point X value */
    bool Ok;
    pTableWidgetItem->text().toFloat(&Ok);
    if (!Ok || pTableWidgetItem->text().isEmpty()) {
      QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER)
                            .arg("points item ("+  QString::number(i+1) +",0)"), Helper::ok);
      mpPointsTableWidget->editItem(pTableWidgetItem);
      return false;
    }
    pTableWidgetItem = mpPointsTableWidget->item(i, 1); /* point Y value */
    pTableWidgetItem->text().toFloat(&Ok);
    if (!Ok || pTableWidgetItem->text().isEmpty()) {
      QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER)
                            .arg("points table ["+  QString::number(i+1) +",1]"), Helper::ok);
      mpPointsTableWidget->editItem(pTableWidgetItem);
      return false;
    }
  }
  /* validate the bitmap file name */
  if (mpBitmapAnnotation) {
    if (mpStoreImageInModelCheckBox->isChecked() && mpShapeAnnotation->getImageSource().isEmpty()) {
      if (mpFileTextBox->text().isEmpty()) {
        QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                              GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::fileLabel), Helper::ok);
        mpFileTextBox->setFocus();
        return false;
      }
    } else if (!mpStoreImageInModelCheckBox->isChecked()) {
      if (mpFileTextBox->text().isEmpty()) {
        QMessageBox::critical(MainWindow::instance(), QString(Helper::applicationName).append(" - ").append(Helper::error),
                              GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::fileLabel), Helper::ok);
        mpFileTextBox->setFocus();
        return false;
      }
    }
  }
  /* apply properties */
  mpShapeAnnotation->setOrigin(QPointF(mpOriginXSpinBox->value(), mpOriginYSpinBox->value()));
  mpShapeAnnotation->setRotationAngle(mpRotationSpinBox->value());
  if (!mpLineAnnotation && !mpPolygonAnnotation) {
    QList<QPointF> extents;
    QPointF p1(mpExtent1XSpinBox->value(), mpExtent1YSpinBox->value());
    QPointF p2(mpExtent2XSpinBox->value(), mpExtent2YSpinBox->value());
    extents << p1 << p2;
    mpShapeAnnotation->setExtents(extents);
  }
  if (mpRectangleAnnotation) {
    mpShapeAnnotation->setBorderPattern(StringHandler::getBorderPatternType(mpBorderPatternComboBox->currentText()));
    mpShapeAnnotation->setRadius(mpRadiusSpinBox->value());
  }
  if (mpEllipseAnnotation) {
    mpShapeAnnotation->setStartAngle(mpStartAngleSpinBox->value());
    mpShapeAnnotation->setEndAngle(mpEndAngleSpinBox->value());
  }
  if (mpTextAnnotation) {
    mpShapeAnnotation->setTextString(mpTextTextBox->text().trimmed());
    if (mpFontNameComboBox->currentText().compare("Default") != 0) {
      mpShapeAnnotation->setFontName(mpFontNameComboBox->currentText());
    }
    mpShapeAnnotation->setFontSize(mpFontSizeSpinBox->value());
    QList<StringHandler::TextStyle> textStyles;
    if (mpTextBoldCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleBold);
    if (mpTextItalicCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleItalic);
    if (mpTextUnderlineCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleUnderLine);
    mpShapeAnnotation->setTextStyles(textStyles);
    mpShapeAnnotation->setTextHorizontalAlignment(StringHandler::getTextAlignmentType(mpTextHorizontalAlignmentComboBox->currentText()));
  }
  mpShapeAnnotation->setLineColor(getLineColor());
  mpShapeAnnotation->setLinePattern(StringHandler::getLinePatternType(mpLinePatternComboBox->currentText()));
  mpShapeAnnotation->setLineThickness(mpLineThicknessSpinBox->value());
  mpShapeAnnotation->setSmooth(mpLineSmoothCheckBox->isChecked() ? StringHandler::SmoothBezier : StringHandler::SmoothNone);
  if (mpLineAnnotation) {
    mpShapeAnnotation->setStartArrow(StringHandler::getArrowType(mpLineStartArrowComboBox->currentText()));
    mpShapeAnnotation->setEndArrow(StringHandler::getArrowType(mpLineEndArrowComboBox->currentText()));
    mpShapeAnnotation->setArrowSize(mpLineArrowSizeSpinBox->value());
  } else {
    mpShapeAnnotation->setFillColor(getFillColor());
    mpShapeAnnotation->setFillPattern(StringHandler::getFillPatternType(mpFillPatternComboBox->currentText()));
  }
  /* save points */
  mpShapeAnnotation->clearPoints();
  QList<QPointF> points;
  for (int i = 0 ; i < mpPointsTableWidget->rowCount() ; i++) {
    points.append(QPointF(mpPointsTableWidget->item(i, 0)->text().toFloat(), mpPointsTableWidget->item(i, 1)->text().toFloat()));
  }
  mpShapeAnnotation->setPoints(points);
  /* save bitmap file name and image source */
  if (mpBitmapAnnotation) {
    if (mpStoreImageInModelCheckBox->isChecked()) {
      mpShapeAnnotation->setFileName("");
      if (!mpFileTextBox->text().isEmpty()) {
        QUrl fileUrl(mpFileTextBox->text());
        QFileInfo fileInfo(mpFileTextBox->text());
        QFileInfo classFileInfo(mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getFileName());
        MainWindow *pMainWindow = MainWindow::instance();
        /* if its a modelica:// link then make it absolute path */
        QString fileName;
        if (fileUrl.scheme().toLower().compare("modelica") == 0) {
          fileName = pMainWindow->getOMCProxy()->uriToFilename(mpFileTextBox->text());
        } else if (fileInfo.isRelative()) {
          fileName = QString(classFileInfo.absoluteDir().absolutePath()).append("/").append(mpFileTextBox->text());
        } else if (fileInfo.isAbsolute()) {
          fileName = mpFileTextBox->text();
        } else {
          fileName = "";
        }
        QFile imageFile(fileName);
        imageFile.open(QIODevice::ReadOnly);
        QByteArray imageByteArray = imageFile.readAll();
        mpShapeAnnotation->setImageSource(imageByteArray.toBase64());
      }
      mpShapeAnnotation->setImage(mpPreviewImageLabel->pixmap()->toImage());
    } else {
      /* find the class to create a relative path */
      MainWindow *pMainWindow = MainWindow::instance();
      LibraryTreeItem *pLibraryTreeItem = mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem();
      QString nameStructure = StringHandler::getFirstWordBeforeDot(pLibraryTreeItem->getNameStructure());
      pLibraryTreeItem = pMainWindow->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(nameStructure);
      /* get the class directory path and use it to get the relative path of the chosen bitmap file */
      QFileInfo classFileInfo(pLibraryTreeItem->getFileName());
      QDir classDirectory = classFileInfo.absoluteDir();
      QString relativeImagePath = classDirectory.relativeFilePath(mpFileTextBox->text());
      mpShapeAnnotation->setFileName(QString("modelica://").append(pLibraryTreeItem->getNameStructure()).append("/").append(relativeImagePath));
      mpShapeAnnotation->setImageSource("");
      mpShapeAnnotation->setImage(mpPreviewImageLabel->pixmap()->toImage());
    }
  }
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) {
    lineType = mpLineAnnotation->getLineType();
    if (lineType == LineAnnotation::ConnectionType || lineType == LineAnnotation::TransitionType) {
      mpLineAnnotation->adjustGeometries();
    }
  }
  // if nothing has changed then just simply return true.
  if (mOldAnnotation.compare(mpShapeAnnotation->getOMCShapeAnnotation()) == 0) {
    return true;
  } else if (mpLineAnnotation && lineType == LineAnnotation::ConnectionType) {
    // create a UpdateConnectionCommand object and push it to the undo stack.
    UpdateConnectionCommand *pUpdateConnectionCommand;
    pUpdateConnectionCommand = new UpdateConnectionCommand(mpLineAnnotation, mOldAnnotation, mpShapeAnnotation->getOMCShapeAnnotation());
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateConnectionCommand);
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->updateModelText();
  } else if (mpLineAnnotation && lineType == LineAnnotation::TransitionType) {
    // create a UpdateTransitionCommand object and push it to the undo stack.
    UpdateTransitionCommand *pUpdateTransitionCommand;
    pUpdateTransitionCommand = new UpdateTransitionCommand(mpLineAnnotation, mpLineAnnotation->getCondition(), mpLineAnnotation->getImmediate(),
                                                           mpLineAnnotation->getReset(), mpLineAnnotation->getSynchronize(),
                                                           mpLineAnnotation->getPriority(), mOldAnnotation, mpLineAnnotation->getCondition(),
                                                           mpLineAnnotation->getImmediate(), mpLineAnnotation->getReset(),
                                                           mpLineAnnotation->getSynchronize(), mpLineAnnotation->getPriority(),
                                                           mpShapeAnnotation->getOMCShapeAnnotation());
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateTransitionCommand);
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->updateModelText();
  } else if (mpLineAnnotation && lineType == LineAnnotation::InitialStateType) {
    // create a UpdateInitialStateCommand object and push it to the undo stack.
    UpdateInitialStateCommand *pUpdateInitialStateCommand;
    pUpdateInitialStateCommand = new UpdateInitialStateCommand(mpLineAnnotation, mOldAnnotation, mpShapeAnnotation->getOMCShapeAnnotation());
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateInitialStateCommand);
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->updateModelText();
  } else {
    // create a UpdateShapeCommand object and push it to the undo stack.
    UpdateShapeCommand *pUpdateShapeCommand;
    pUpdateShapeCommand = new UpdateShapeCommand(mpShapeAnnotation, mOldAnnotation, mpShapeAnnotation->getOMCShapeAnnotation());
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->getUndoStack()->push(pUpdateShapeCommand);
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->updateClassAnnotationIfNeeded();
    mpShapeAnnotation->getGraphicsView()->getModelWidget()->updateModelText();
  }
  return true;
}

void ShapePropertiesDialog::browseImageFile()
{
  QString imageFileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                         NULL, Helper::bitmapFileTypes, NULL);
  if (imageFileName.isEmpty()) {
    return;
  }
  mpFileTextBox->setText(imageFileName);
  QPixmap pixmap;
  pixmap.load(imageFileName);
  mpPreviewImageLabel->setPixmap(pixmap);
}

void ShapePropertiesDialog::storeImageInModelToggled(bool checked)
{
  /* If store image in model check box is unchecked then see if model is saved or not.
   * If the model is not saved then make the check box checked again.
   */
  if (!checked) {
    MainWindow *pMainWindow = MainWindow::instance();
    if (!mpBitmapAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isFilePathValid()) {
      if (OptionsDialog::instance()->getNotificationsPage()->getSaveModelForBitmapInsertionCheckBox()->isChecked()) {
        NotificationsDialog *pNotificationsDialog = new NotificationsDialog(NotificationsDialog::SaveModelForBitmapInsertion,
                                                                            NotificationsDialog::InformationIcon,
                                                                            pMainWindow);
        pNotificationsDialog->exec();
      }
      mpStoreImageInModelCheckBox->blockSignals(true);
      mpStoreImageInModelCheckBox->setChecked(true);
      mpStoreImageInModelCheckBox->blockSignals(false);
    }
  }
}
