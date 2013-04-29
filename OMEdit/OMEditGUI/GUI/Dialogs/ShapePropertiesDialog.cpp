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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "ShapePropertiesDialog.h"

ShapePropertiesDialog::ShapePropertiesDialog(ShapeAnnotation *pShapeAnnotation, MainWindow *pMainWindow)
  : QDialog(pMainWindow, Qt::WindowTitleHint)
{
  mpShapeAnnotation = pShapeAnnotation;
  mpLineAnnotation = dynamic_cast<LineAnnotation*>(mpShapeAnnotation);
  mpPolygonAnnotation = dynamic_cast<PolygonAnnotation*>(mpShapeAnnotation);
  mpRectangleAnnotation = dynamic_cast<RectangleAnnotation*>(mpShapeAnnotation);
  mpEllipseAnnotation = dynamic_cast<EllipseAnnotation*>(mpShapeAnnotation);
  mpTextAnnotation = dynamic_cast<TextAnnotation*>(mpShapeAnnotation);
  mpBitmapAnnotation = dynamic_cast<BitmapAnnotation*>(mpShapeAnnotation);
  mpMainWindow = pMainWindow;
  QString title = getTitle();
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(title).append(" ").append(Helper::properties));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  // heading label
  mpShapePropertiesHeading = new Label(QString(title).append(" ").append(Helper::properties));
  mpShapePropertiesHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpShapePropertiesHeading->setAlignment(Qt::AlignTop);
  // set seperator line
  mHorizontalLine = new QFrame();
  mHorizontalLine->setFrameShape(QFrame::HLine);
  mHorizontalLine->setFrameShadow(QFrame::Sunken);
  // Transformations Group Box
  mpTransformationGroupBox = new QGroupBox(tr("Transformation"));
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpOriginXLabel = new Label(Helper::originX);
  mpOriginXTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getOrigin().x()));
  mpOriginXTextBox->setValidator(pDoubleValidator);
  mpOriginYLabel = new Label(Helper::originY);
  mpOriginYTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getOrigin().y()));
  mpOriginYTextBox->setValidator(pDoubleValidator);
  mpRotationLabel = new Label(Helper::rotation);
  mpRotationTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getRotation()));
  mpRotationTextBox->setValidator(pDoubleValidator);
  // set the Transformations Group Box layout
  QHBoxLayout *pTransformationGroupBoxLayout = new QHBoxLayout;
  pTransformationGroupBoxLayout->addWidget(mpOriginXLabel);
  pTransformationGroupBoxLayout->addWidget(mpOriginXTextBox);
  pTransformationGroupBoxLayout->addWidget(mpOriginYLabel);
  pTransformationGroupBoxLayout->addWidget(mpOriginYTextBox);
  pTransformationGroupBoxLayout->addWidget(mpRotationLabel);
  pTransformationGroupBoxLayout->addWidget(mpRotationTextBox);
  mpTransformationGroupBox->setLayout(pTransformationGroupBoxLayout);
  // Extent Group Box
  mpExtentGroupBox = new QGroupBox(Helper::extent);
  // Extent1X
  QList<QPointF> extents = mpShapeAnnotation->getExtents();
  mpExtent1XLabel = new Label(Helper::extent1X);
  mpExtent1XTextBox = new QLineEdit(extents.size() > 0 ? QString::number(extents.at(0).x()) : "");
  mpExtent1XTextBox->setValidator(pDoubleValidator);
  mpExtent1YLabel = new Label(Helper::extent1Y);
  mpExtent1YTextBox = new QLineEdit(extents.size() > 0 ? QString::number(extents.at(0).y()) : "");
  mpExtent1YTextBox->setValidator(pDoubleValidator);
  mpExtent2XLabel = new Label(Helper::extent2X);
  mpExtent2XTextBox = new QLineEdit(extents.size() > 1 ? QString::number(extents.at(1).x()) : "");
  mpExtent2XTextBox->setValidator(pDoubleValidator);
  mpExtent2YLabel = new Label(Helper::extent2Y);
  mpExtent2YTextBox = new QLineEdit(extents.size() > 1 ? QString::number(extents.at(1).y()) : "");
  mpExtent2YTextBox->setValidator(pDoubleValidator);
  // set the extents Group Box layout
  QGridLayout *pExtentGroupBoxLayout = new QGridLayout;
  pExtentGroupBoxLayout->addWidget(mpExtent1XLabel, 0, 0);
  pExtentGroupBoxLayout->addWidget(mpExtent1XTextBox, 0, 1);
  pExtentGroupBoxLayout->addWidget(mpExtent1YLabel, 0, 2);
  pExtentGroupBoxLayout->addWidget(mpExtent1YTextBox, 0, 3);
  pExtentGroupBoxLayout->addWidget(mpExtent2XLabel, 1, 0);
  pExtentGroupBoxLayout->addWidget(mpExtent2XTextBox, 1, 1);
  pExtentGroupBoxLayout->addWidget(mpExtent2YLabel, 1, 2);
  pExtentGroupBoxLayout->addWidget(mpExtent2YTextBox, 1, 3);
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
  int currentIndex = mpBorderPatternComboBox->findText(StringHandler::getBorderPatternString(mpShapeAnnotation->getBorderPattern()), Qt::MatchExactly);
  if (currentIndex > -1)
    mpBorderPatternComboBox->setCurrentIndex(currentIndex);
  // radius
  mpRadiusLabel = new Label(Helper::radius);
  mpRadiusTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getRadius()));
  QDoubleValidator *pDoublePositiveValidator = new QDoubleValidator(this);
  pDoublePositiveValidator->setBottom(0);
  mpRadiusTextBox->setValidator(pDoublePositiveValidator);
  // set the border style Group Box layout
  QHBoxLayout *pBorderStyleGroupBoxLayout = new QHBoxLayout;
  pBorderStyleGroupBoxLayout->addWidget(mpBorderPatternLabel);
  pBorderStyleGroupBoxLayout->addWidget(mpBorderPatternComboBox);
  pBorderStyleGroupBoxLayout->addWidget(mpRadiusLabel);
  pBorderStyleGroupBoxLayout->addWidget(mpRadiusTextBox);
  mpBorderStyleGroupBox->setLayout(pBorderStyleGroupBoxLayout);
  // Angle Group Box
  mpAngleGroupBox = new QGroupBox(tr("Angle"));
  // start angle
  mpStartAngleLabel = new Label(Helper::startAngle);
  mpStartAngleTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getStartAngle()));
  mpStartAngleTextBox->setValidator(pDoubleValidator);
  // end angle
  mpEndAngleLabel = new Label(Helper::endAngle);
  mpEndAngleTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getEndAngle()));
  mpEndAngleTextBox->setValidator(pDoubleValidator);
  // set the border style Group Box layout
  QHBoxLayout *pAngleGroupBoxLayout = new QHBoxLayout;
  pAngleGroupBoxLayout->addWidget(mpStartAngleLabel);
  pAngleGroupBoxLayout->addWidget(mpStartAngleTextBox);
  pAngleGroupBoxLayout->addWidget(mpEndAngleLabel);
  pAngleGroupBoxLayout->addWidget(mpEndAngleTextBox);
  mpAngleGroupBox->setLayout(pAngleGroupBoxLayout);
  // Text Group Box
  mpTextGroupBox = new QGroupBox(tr("Text"));
  mpTextTextBox = new QLineEdit(mpShapeAnnotation->getTextString());
  // set the Text Group Box layout
  QHBoxLayout *pTextGroupBoxLayout = new QHBoxLayout;
  pTextGroupBoxLayout->addWidget(mpTextTextBox);
  mpTextGroupBox->setLayout(pTextGroupBoxLayout);
  // Font Style Group Box
  mpFontAndTextStyleGroupBox = new QGroupBox(tr("Font & Text Style"));
  mpFontNameLabel = new Label(Helper::name);
  mpFontNameComboBox = new QFontComboBox;
  mpFontNameComboBox->insertItem(0, "Default");
  currentIndex = mpFontNameComboBox->findText(mpShapeAnnotation->getFontName(), Qt::MatchExactly);
  if (currentIndex > -1)
    mpFontNameComboBox->setCurrentIndex(currentIndex);
  else
    mpFontNameComboBox->setCurrentIndex(0);
  mpFontSizeLabel = new Label(Helper::size);
  mpFontSizeTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getFontSize()));
  mpFontSizeTextBox->setValidator(pDoublePositiveValidator);
  mpFontStyleLabel = new Label(tr("Style:"));
  mpTextBoldCheckBox = new QCheckBox(tr("Bold"));
  mpTextBoldCheckBox->setChecked(StringHandler::getFontWeight(mpShapeAnnotation->getTextStyles()) == QFont::Bold ? true : false);
  mpTextItalicCheckBox = new QCheckBox(tr("Italic"));
  mpTextItalicCheckBox->setChecked(StringHandler::getFontItalic(mpShapeAnnotation->getTextStyles()));
  mpTextUnderlineCheckBox = new QCheckBox(tr("Underline"));
  mpTextUnderlineCheckBox->setChecked(StringHandler::getFontUnderline(mpShapeAnnotation->getTextStyles()));
  mpTextHorizontalAlignmentLabel = new Label(tr("Horizontal Alignment:"));
  mpTextHorizontalAlignmentComboBox = new QComboBox;
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentLeft));
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentCenter));
  mpTextHorizontalAlignmentComboBox->addItem(StringHandler::getTextAlignmentString(StringHandler::TextAlignmentRight));
  currentIndex = mpTextHorizontalAlignmentComboBox->findText(StringHandler::getTextAlignmentString(mpShapeAnnotation->getTextHorizontalAlignment()), Qt::MatchExactly);
  if (currentIndex > -1)
    mpTextHorizontalAlignmentComboBox->setCurrentIndex(currentIndex);
  // set the Font Style Group Box layout
  QGridLayout *pFontAndTextStyleGroupBox = new QGridLayout;
  pFontAndTextStyleGroupBox->addWidget(mpFontNameLabel, 0, 0);
  pFontAndTextStyleGroupBox->addWidget(mpFontNameComboBox, 0, 1, 1, 3);
  pFontAndTextStyleGroupBox->addWidget(mpFontSizeLabel, 0, 4);
  pFontAndTextStyleGroupBox->addWidget(mpFontSizeTextBox, 0, 5);
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
  if (currentIndex > -1)
    mpLinePatternComboBox->setCurrentIndex(currentIndex);
  // Line Thickness
  mpLineThicknessLabel = new Label(Helper::thickness);
  mpLineThicknessTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getLineThickness()));
  mpLineThicknessTextBox->setValidator(pDoublePositiveValidator);
  // Line smooth
  mpLineSmoothLabel = new Label(Helper::smooth);
  mpLineSmoothCheckBox = new QCheckBox(Helper::bezier);
  if (mpShapeAnnotation->getSmooth() == StringHandler::SmoothBezier)
    mpLineSmoothCheckBox->setChecked(true);
  // set the Line style Group Box layout
  QGridLayout *pLineStyleGroupBoxLayout = new QGridLayout;
  pLineStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pLineStyleGroupBoxLayout->addWidget(mpLineColorLabel, 0, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLinePickColorButton, 0, 1);
  pLineStyleGroupBoxLayout->addWidget(mpLinePatternLabel, 1, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLinePatternComboBox, 1, 1);
  pLineStyleGroupBoxLayout->addWidget(mpLineThicknessLabel, 2, 0);
  pLineStyleGroupBoxLayout->addWidget(mpLineThicknessTextBox, 2, 1);
  if (mpLineAnnotation || mpPolygonAnnotation)
  {
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
  if (currentIndex > -1)
    mpLineStartArrowComboBox->setCurrentIndex(currentIndex);
  mpLineEndArrowLabel = new Label(Helper::endArrow);
  mpLineEndArrowComboBox = StringHandler::getEndArrowComboBox();
  currentIndex = mpLineEndArrowComboBox->findText(StringHandler::getArrowString(mpShapeAnnotation->getEndArrow()), Qt::MatchExactly);
  if (currentIndex > -1)
    mpLineEndArrowComboBox->setCurrentIndex(currentIndex);
  mpLineArrowSizeLabel = new Label(Helper::arrowSize);
  mpLineArrowSizeTextBox = new QLineEdit(QString::number(mpShapeAnnotation->getArrowSize()));
  mpLineArrowSizeTextBox->setValidator(pDoublePositiveValidator);
  // set the Arrow style Group Box layout
  QGridLayout *pArrowStyleGroupBoxLayout = new QGridLayout;
  pArrowStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pArrowStyleGroupBoxLayout->addWidget(mpLineStartArrowLabel, 0, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineStartArrowComboBox, 0, 1);
  pArrowStyleGroupBoxLayout->addWidget(mpLineEndArrowLabel, 1, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineEndArrowComboBox, 1, 1);
  pArrowStyleGroupBoxLayout->addWidget(mpLineArrowSizeLabel, 2, 0);
  pArrowStyleGroupBoxLayout->addWidget(mpLineArrowSizeTextBox, 2, 1);
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
  if (currentIndex > -1)
    mpFillPatternComboBox->setCurrentIndex(currentIndex);
  // set the Fill style Group Box layout
  QGridLayout *pFillStyleGroupBoxLayout = new QGridLayout;
  pFillStyleGroupBoxLayout->setAlignment(Qt::AlignTop);
  pFillStyleGroupBoxLayout->addWidget(mpFillColorLabel, 0, 0);
  pFillStyleGroupBoxLayout->addWidget(mpFillPickColorButton, 0, 1);
  pFillStyleGroupBoxLayout->addWidget(mpFillPatternLabel, 1, 0);
  pFillStyleGroupBoxLayout->addWidget(mpFillPatternComboBox, 1, 1);
  mpFillStyleGroupBox->setLayout(pFillStyleGroupBoxLayout);
  // Image Group Box
  mpImageGroupBox = new QGroupBox(tr("Image"));
  mpFileLabel = new Label(Helper::file);
  mpFileTextBox = new QLineEdit(mpShapeAnnotation->getFileName());
  mpFileTextBox->setEnabled(false);
  mpBrowseFileButton = new QPushButton(Helper::browse);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(browseImageFile()));
  mpStoreImageInModelCheckBox = new QCheckBox(tr("Store image in model"));
  mpStoreImageInModelCheckBox->setChecked(true);
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
  mpPointsTableWidget->horizontalHeader()->setResizeMode(QHeaderView::Stretch);
  QStringList headerLabels;
  headerLabels << "X" << "Y";
  mpPointsTableWidget->setHorizontalHeaderLabels(headerLabels);
  // add points to points table widget
  QList<QPointF> points = mpShapeAnnotation->getPoints();
  mpPointsTableWidget->setRowCount(points.size());
  int rowIndex = 0;
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  foreach (QPointF point, points)
  {
    QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(QString::number(point.x()));
    if ((rowIndex == 0 || rowIndex == points.size() - 1) && (lineType == LineAnnotation::ConnectionType))
      pTableWidgetItemX->setFlags(Qt::NoItemFlags);
    else
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
    mpPointsTableWidget->setItem(rowIndex, 0, pTableWidgetItemX);
    QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(QString::number(point.y()));
    if ((rowIndex == 0 || rowIndex == points.size() - 1) && (lineType == LineAnnotation::ConnectionType))
      pTableWidgetItemY->setFlags(Qt::NoItemFlags);
    else
      pTableWidgetItemY->setFlags(pTableWidgetItemY->flags() | Qt::ItemIsEditable);
    mpPointsTableWidget->setItem(rowIndex, 1, pTableWidgetItemY);
    rowIndex++;
  }
  if (rowIndex > 0)
  {
    if (lineType == LineAnnotation::ConnectionType)
      mpPointsTableWidget->setCurrentCell(1, 1);
    else
      mpPointsTableWidget->setCurrentCell(0, 0);
  }
  // points navigation buttons
  mpMovePointUpButton = new QToolButton;
  mpMovePointUpButton->setObjectName("ShapePointsButton");
  mpMovePointUpButton->setIcon(QIcon(":/Resources/icons/up.png"));
  connect(mpMovePointUpButton, SIGNAL(clicked()), SLOT(movePointUp()));
  mpMovePointDownButton = new QToolButton;
  mpMovePointDownButton->setObjectName("ShapePointsButton");
  mpMovePointDownButton->setIcon(QIcon(":/Resources/icons/down.png"));
  connect(mpMovePointDownButton, SIGNAL(clicked()), SLOT(movePointDown()));
  // points manipulation buttons
  mpAddPointButton = new QToolButton;
  mpAddPointButton->setObjectName("ShapePointsButton");
  mpAddPointButton->setIcon(QIcon(":/Resources/icons/add-icon.png"));
  connect(mpAddPointButton, SIGNAL(clicked()), SLOT(addPoint()));
  mpRemovePointButton = new QToolButton;
  mpRemovePointButton->setObjectName("ShapePointsButton");
  mpRemovePointButton->setIcon(QIcon(":/Resources/icons/delete.png"));
  connect(mpRemovePointButton, SIGNAL(clicked()), SLOT(removePoint()));
  mpPointsButtonBox = new QDialogButtonBox(Qt::Vertical);
  mpPointsButtonBox->addButton(mpMovePointUpButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpMovePointDownButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpAddPointButton, QDialogButtonBox::ActionRole);
  mpPointsButtonBox->addButton(mpRemovePointButton, QDialogButtonBox::ActionRole);
  // set the Points Group Box layout
  QGridLayout *pPointsGroupBoxLayout = new QGridLayout;
  pPointsGroupBoxLayout->setAlignment(Qt::AlignTop);
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
  mpApplyButton = new QPushButton(tr("Apply"));
  mpApplyButton->setAutoDefault(false);
  connect(mpApplyButton, SIGNAL(clicked()), this, SLOT(applyShapeProperties()));
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
  if (!mpLineAnnotation && !mpPolygonAnnotation)
    pMainLayout->addWidget(mpExtentGroupBox, row++, 0, 1, colSpan);
  if (mpRectangleAnnotation)
    pMainLayout->addWidget(mpBorderStyleGroupBox, row++, 0, 1, colSpan);
  if (mpEllipseAnnotation)
    pMainLayout->addWidget(mpAngleGroupBox, row++, 0, 1, colSpan);
  if (mpTextAnnotation)
  {
    pMainLayout->addWidget(mpTextGroupBox, row++, 0, 1, colSpan);
    pMainLayout->addWidget(mpFontAndTextStyleGroupBox, row++, 0, 1, colSpan);
  }
  if (mpBitmapAnnotation)
  {
    pMainLayout->addWidget(mpLineStyleGroupBox, row++, 0, 1, colSpan);
    pMainLayout->addWidget(mpImageGroupBox, row++, 0, 1, colSpan);
  }
  else
  {
    pMainLayout->addWidget(mpLineStyleGroupBox, row, 0);
  }
  if (mpLineAnnotation)
  {
    pMainLayout->addWidget(mpArrowStyleGroupBox, row++, 1);
  }
  else if (!mpBitmapAnnotation)
  {
    pMainLayout->addWidget(mpFillStyleGroupBox, row++, 1);
  }
  if (mpLineAnnotation || mpPolygonAnnotation)
  {
    pMainLayout->addWidget(mpPointsGroupBox, row++, 0, 1, colSpan);
  }
  pMainLayout->addWidget(mpButtonBox, row, 0, 1, colSpan);
  setLayout(pMainLayout);
}

QString ShapePropertiesDialog::getTitle()
{
  if (mpLineAnnotation)
    if (mpLineAnnotation->getLineType() == LineAnnotation::ConnectionType)
      return "Connection";
    else
      return "Line";
  else if (mpPolygonAnnotation)
    return "Polygon";
  else if (mpRectangleAnnotation)
    return "Rectangle";
  else if (mpEllipseAnnotation)
    return "Ellipse";
  else if (mpTextAnnotation)
    return "Text";
  else if (mpBitmapAnnotation)
    return "Bitmap";
  else
    return "";
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
  if (!color.isValid())
    return;
  setLineColor(color);
  setLinePickColorButtonIcon();
}

void ShapePropertiesDialog::fillPickColor()
{
  QColor color = QColorDialog::getColor(getFillColor());
  // if user press ESC
  if (!color.isValid())
    return;
  setFillColor(color);
  setFillPickColorButtonIcon();
}

void ShapePropertiesDialog::movePointUp()
{
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  if (mpPointsTableWidget->selectedItems().size() > 0)
  {
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == 0)
      return;
    if (row == 1 && lineType == LineAnnotation::ConnectionType)
      return;
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
  if (mpPointsTableWidget->selectedItems().size() > 0)
  {
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == mpPointsTableWidget->rowCount() - 1)
      return;
    if (row == mpPointsTableWidget->rowCount() - 2 && lineType == LineAnnotation::ConnectionType)
      return;
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
  if (mpPointsTableWidget->selectedItems().size() > 0)
  {
    int row = mpPointsTableWidget->selectedItems().at(0)->row();
    if (row == mpPointsTableWidget->rowCount() - 1)
    {
      /* insert a new row which is similar to last row. */
      mpPointsTableWidget->insertRow(row + 1);
      QTableWidgetItem *pTableWidgetItemX = new QTableWidgetItem(mpPointsTableWidget->item(row, 0)->text());
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 0, pTableWidgetItemX);
      QTableWidgetItem *pTableWidgetItemY = new QTableWidgetItem(mpPointsTableWidget->item(row, 1)->text());
      pTableWidgetItemX->setFlags(pTableWidgetItemX->flags() | Qt::ItemIsEditable);
      mpPointsTableWidget->setItem(row + 1, 1, pTableWidgetItemY);
      mpPointsTableWidget->setCurrentCell(row + 1, 0);
    }
    else
    {
      /* get middle of two surronding points */
      QPointF point1(mpPointsTableWidget->item(row, 0)->text().toFloat(), mpPointsTableWidget->item(row, 1)->text().toFloat());
      QPointF point2(mpPointsTableWidget->item(row + 1, 0)->text().toFloat(), mpPointsTableWidget->item(row + 1, 0)->text().toFloat());
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
  }
}

void ShapePropertiesDialog::removePoint()
{
  if (mpPointsTableWidget->selectedItems().size() > 0)
  {
    mpPointsTableWidget->removeRow(mpPointsTableWidget->selectedItems().at(0)->row());
  }
}

void ShapePropertiesDialog::saveShapeProperties()
{
  if (applyShapeProperties())
    accept();
}

bool ShapePropertiesDialog::applyShapeProperties()
{
  /* perform validation first */
  if (mpOriginXTextBox->text().isEmpty())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::originX), Helper::ok);
    mpOriginXTextBox->setFocus();
    return false;
  }
  else if (mpOriginYTextBox->text().isEmpty())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::originY), Helper::ok);
    mpOriginYTextBox->setFocus();
    return false;
  }
  else if (mpRotationTextBox->text().isEmpty())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::rotation), Helper::ok);
    mpRotationTextBox->setFocus();
    return false;
  }
  else if (mpLineThicknessTextBox->text().isEmpty())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::thickness), Helper::ok);
    mpLineThicknessTextBox->setFocus();
    return false;
  }
  else if (mpLineArrowSizeTextBox->text().isEmpty())
  {
    QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::arrowSize), Helper::ok);
    mpLineArrowSizeTextBox->setFocus();
    return false;
  }
  /* validate points */
  for (int i = 0 ; i < mpPointsTableWidget->rowCount() ; i++)
  {
    QTableWidgetItem *pTableWidgetItem = mpPointsTableWidget->item(i, 0); /* point X value */
    bool Ok;
    pTableWidgetItem->text().toFloat(&Ok);
    if (!Ok || pTableWidgetItem->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER)
                            .arg("points item ("+  QString::number(i+1) +",0)"), Helper::ok);
      mpPointsTableWidget->editItem(pTableWidgetItem);
      return false;
    }
    pTableWidgetItem = mpPointsTableWidget->item(i, 1); /* point Y value */
    pTableWidgetItem->text().toFloat(&Ok);
    if (!Ok || pTableWidgetItem->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER)
                            .arg("points table ["+  QString::number(i+1) +",1]"), Helper::ok);
      mpPointsTableWidget->editItem(pTableWidgetItem);
      return false;
    }
  }
  /* validate extent points */
  if (!mpLineAnnotation && !mpPolygonAnnotation)
  {
    if (mpExtent1XTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::extent1X), Helper::ok);
      mpExtent1XTextBox->setFocus();
      return false;
    }
    else if (mpExtent1YTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::extent1Y), Helper::ok);
      mpExtent1YTextBox->setFocus();
      return false;
    }
    else if (mpExtent2XTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::extent2X), Helper::ok);
      mpExtent2XTextBox->setFocus();
      return false;
    }
    else if (mpExtent2YTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::extent2Y), Helper::ok);
      mpExtent2YTextBox->setFocus();
      return false;
    }
  }
  /* validate corner radius */
  if (mpRectangleAnnotation)
  {
    if (mpRadiusTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::radius), Helper::ok);
      mpRadiusTextBox->setFocus();
      return false;
    }
  }
  /* validate start and end angles */
  if (mpEllipseAnnotation)
  {
    if (mpStartAngleTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::startAngle), Helper::ok);
      mpStartAngleTextBox->setFocus();
      return false;
    }
    else if (mpEndAngleTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::endAngle), Helper::ok);
      mpEndAngleTextBox->setFocus();
      return false;
    }
  }
  /* validate font size */
  if (mpTextAnnotation)
  {
    if (mpFontSizeTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_VALID_NUMBER).arg(Helper::size), Helper::ok);
      mpFontSizeTextBox->setFocus();
      return false;
    }
  }
  /* validate the bitmap file name */
  if (mpBitmapAnnotation)
  {
    if (mpFileTextBox->text().isEmpty())
    {
      QMessageBox::critical(mpMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                            GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(Helper::file), Helper::ok);
      mpFileTextBox->setFocus();
      return false;
    }
  }
  /* apply properties */
  mpShapeAnnotation->setOrigin(QPointF(mpOriginXTextBox->text().toFloat(), mpOriginYTextBox->text().toFloat()));
  mpShapeAnnotation->setRotationAngle(mpRotationTextBox->text().toFloat());
  if (!mpLineAnnotation && !mpPolygonAnnotation)
  {
    QList<QPointF> extents;
    QPointF p1(mpExtent1XTextBox->text().toFloat(), mpExtent1YTextBox->text().toFloat());
    QPointF p2(mpExtent2XTextBox->text().toFloat(), mpExtent2YTextBox->text().toFloat());
    extents << p1 << p2;
    mpShapeAnnotation->setExtents(extents);
  }
  if (mpRectangleAnnotation)
  {
    mpShapeAnnotation->setBorderPattern(StringHandler::getBorderPatternType(mpBorderPatternComboBox->currentText()));
    mpShapeAnnotation->setRadius(mpRadiusTextBox->text().toFloat());
  }
  if (mpEllipseAnnotation)
  {
    mpShapeAnnotation->setStartAngle(mpStartAngleTextBox->text().toFloat());
    mpShapeAnnotation->setEndAngle(mpEndAngleTextBox->text().toFloat());
  }
  if (mpTextAnnotation)
  {
    mpShapeAnnotation->setTextString(mpTextTextBox->text().trimmed());
    if (mpFontNameComboBox->currentText().compare("Default") != 0)
      mpShapeAnnotation->setFontName(mpFontNameComboBox->currentText());
    mpShapeAnnotation->setFontSize(mpFontSizeTextBox->text().toFloat());
    QList<StringHandler::TextStyle> textStyles;
    if (mpTextBoldCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleBold);
    if (mpTextItalicCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleItalic);
    if (mpTextUnderlineCheckBox->isChecked()) textStyles.append(StringHandler::TextStyleUnderLine);
    mpShapeAnnotation->setTextStyles(textStyles);
    mpShapeAnnotation->setTextHorizontalAlignment(StringHandler::getTextAlignmentType(mpTextHorizontalAlignmentComboBox->currentText()));
  }
  mpShapeAnnotation->setLineColor(getLineColor());
  mpShapeAnnotation->setLinePattern(StringHandler::getLinePatternType(mpLinePatternComboBox->currentText()));
  mpShapeAnnotation->setLineThickness(mpLineThicknessTextBox->text().toFloat());
  mpShapeAnnotation->setSmooth(mpLineSmoothCheckBox->isChecked() ? StringHandler::SmoothBezier : StringHandler::SmoothNone);
  if (mpLineAnnotation)
  {
    mpShapeAnnotation->setStartArrow(StringHandler::getArrowType(mpLineStartArrowComboBox->currentText()));
    mpShapeAnnotation->setEndArrow(StringHandler::getArrowType(mpLineEndArrowComboBox->currentText()));
    mpShapeAnnotation->setArrowSize(mpLineArrowSizeTextBox->text().toFloat());
  }
  else
  {
    mpShapeAnnotation->setFillColor(getFillColor());
    mpShapeAnnotation->setFillPattern(StringHandler::getFillPatternType(mpFillPatternComboBox->currentText()));
  }
  /* save points */
  QList<QPointF> points;
  for (int i = 0 ; i < mpPointsTableWidget->rowCount() ; i++)
    points.append(QPointF(mpPointsTableWidget->item(i, 0)->text().toFloat(), mpPointsTableWidget->item(i, 1)->text().toFloat()));
  mpShapeAnnotation->setPoints(points);
  /* save bitmap file name and image source */
  if (mpBitmapAnnotation)
  {
    if (mpStoreImageInModelCheckBox->isChecked())
    {
      mpShapeAnnotation->setFileName("");
      QFile imageFile(mpFileTextBox->text());
      imageFile.open(QIODevice::ReadOnly);
      QByteArray imageByteArray = imageFile.readAll();
      mpShapeAnnotation->setImageSource(imageByteArray.toBase64());
      mpShapeAnnotation->setImage(mpPreviewImageLabel->pixmap()->toImage());
    }
    else
    {
      /* find the class to create a relative path */
      MainWindow *pMainWindow = mpShapeAnnotation->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow();
      LibraryTreeNode *pLibraryTreeNode;
      pLibraryTreeNode = mpShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeNode();
      pLibraryTreeNode = pMainWindow->getLibraryTreeWidget()->getLibraryTreeNode(StringHandler::getFirstWordBeforeDot(pLibraryTreeNode->getNameStructure()));
      /* get the class directory path and use it to get the relative path of the choosen bitmap file */
      QFileInfo classFileInfo(pLibraryTreeNode->getFileName());
      QDir classDirectory = classFileInfo.absoluteDir();
      QString relativeImagePath = classDirectory.relativeFilePath(mpFileTextBox->text());
      mpShapeAnnotation->setFileName(QString("modelica://").append(pLibraryTreeNode->getNameStructure()).append("/").append(relativeImagePath));
      mpShapeAnnotation->setImageSource("");
      mpShapeAnnotation->setImage(mpPreviewImageLabel->pixmap()->toImage());
    }
  }
  LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
  if (mpLineAnnotation) lineType = mpLineAnnotation->getLineType();
  if (mpLineAnnotation && lineType == LineAnnotation::ConnectionType)
  {
    mpLineAnnotation->updateConnectionAnnotation();
    mpLineAnnotation->update();
  }
  else
  {
    mpShapeAnnotation->initializeTransformation();
    mpShapeAnnotation->removeCornerItems();
    if (mpLineAnnotation)
      mpLineAnnotation->addPoint(QPointF(0, 0));
    else if (mpPolygonAnnotation)
      mpPolygonAnnotation->addPoint(QPointF(0, 0));
    mpShapeAnnotation->drawCornerItems();
    mpShapeAnnotation->update();
    mpShapeAnnotation->getGraphicsView()->addClassAnnotation();
    mpShapeAnnotation->getGraphicsView()->setCanAddClassAnnotation(true);
  }
  return true;
}

void ShapePropertiesDialog::browseImageFile()
{
  QString imageFileName = StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                         NULL, Helper::imageFileTypes, NULL);
  if (imageFileName.isEmpty())
    return;
  mpFileTextBox->setText(imageFileName);
  QPixmap pixmap;
  pixmap.load(imageFileName);
  mpPreviewImageLabel->setPixmap(pixmap);
}

void ShapePropertiesDialog::storeImageInModelToggled(bool checked)
{
  /*
    If store image in model check box is unchecked then see if model is saved or not.
    If the model is not saved then make the check box checked again.
    */
  if (!checked)
  {
    MainWindow *pMainWindow = mpBitmapAnnotation->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow();
    if (mpBitmapAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeNode()->getFileName().isEmpty())
    {
      if (pMainWindow->getOptionsDialog()->getNotificationsPage()->getSaveModelForBitmapInsertionCheckBox()->isChecked())
      {
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
