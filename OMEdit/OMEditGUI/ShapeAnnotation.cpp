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

#include "ShapeAnnotation.h"
#include "ProjectTabWidget.h"

ShapeAnnotation::ShapeAnnotation(QGraphicsItem *parent)
    : QGraphicsItem(parent)
{
    mpGraphicsView = 0;
}

ShapeAnnotation::ShapeAnnotation(GraphicsView *graphicsView, QGraphicsItem *parent)
    : QGraphicsItem(parent)
{
    mpGraphicsView = graphicsView;
    createActions();
}

ShapeAnnotation::~ShapeAnnotation()
{
    // delete all the corner items associated with item
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        delete rectangleCornerItem;
    }
}

void ShapeAnnotation::initializeFields()
{
    // initialize the Line Patterns map.
    this->mLinePatternsMap.insert("None", Qt::NoPen);
    this->mLinePatternsMap.insert("Solid", Qt::SolidLine);
    this->mLinePatternsMap.insert("Dash", Qt::DashLine);
    this->mLinePatternsMap.insert("Dot", Qt::DotLine);
    this->mLinePatternsMap.insert("DashDot", Qt::DashDotLine);
    this->mLinePatternsMap.insert("DashDotDot", Qt::DashDotDotLine);

    // initialize the Fill Patterns map.
    this->mFillPatternsMap.insert("None", Qt::NoBrush);
    this->mFillPatternsMap.insert("Solid", Qt::SolidPattern);
    this->mFillPatternsMap.insert("Horizontal", Qt::HorPattern);
    this->mFillPatternsMap.insert("Vertical", Qt::VerPattern);
    this->mFillPatternsMap.insert("Cross", Qt::CrossPattern);
    // since we flipped the co-ordinates of view so to get patterns right switch between forward and backward.
    this->mFillPatternsMap.insert("Forward", Qt::BDiagPattern);
    this->mFillPatternsMap.insert("Backward", Qt::FDiagPattern);
    this->mFillPatternsMap.insert("CrossDiag", Qt::DiagCrossPattern);
    this->mFillPatternsMap.insert("HorizontalCylinder", Qt::LinearGradientPattern);
    this->mFillPatternsMap.insert("VerticalCylinder", Qt::Dense1Pattern);
    this->mFillPatternsMap.insert("Sphere", Qt::RadialGradientPattern);

    // initialize the Arrows map.
    this->mArrowsMap.insert("None", ShapeAnnotation::None);
    this->mArrowsMap.insert("Open", ShapeAnnotation::Open);
    this->mArrowsMap.insert("Filled", ShapeAnnotation::Filled);
    this->mArrowsMap.insert("Half", ShapeAnnotation::Half);

    this->mVisible = true;
    mOrigin.setX(0);
    mOrigin.setY(0);
    mRotation = 0;

    mLineColor = QColor (0, 0, 255);
    this->mFillColor = QColor (0, 0, 255);
    mLinePattern = Qt::SolidLine;
    this->mFillPattern = Qt::NoBrush;
    mThickness = 0.25;
    this->mBorderPattern = Qt::NoBrush;
    this->mCornerRadius = 0;
    mSmooth = false;
    mStartArrow = ShapeAnnotation::None;
    mEndArrow = ShapeAnnotation::None;
    mArrowSize = 3;

    mIsCustomShape = false;
    mIsFinishedCreatingShape = false;
    mIsRectangleCorneItemClicked = false;
}

void ShapeAnnotation::createActions()
{
    mpShapePropertiesAction = new QAction(QIcon(":/Resources/icons/tool.png"), tr("Properties"), this);
    connect(mpShapePropertiesAction, SIGNAL(triggered()), SLOT(openShapeProperties()));
}

void ShapeAnnotation::setSelectionBoxActive()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setActive();
    }
}

void ShapeAnnotation::setSelectionBoxPassive()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setPassive();
    }
}

void ShapeAnnotation::setSelectionBoxHover()
{
    foreach (RectangleCornerItem *rectangleCornerItem, mRectangleCornerItemsList)
    {
        rectangleCornerItem->setHovered();
    }
}

QString ShapeAnnotation::getShapeAnnotation()
{
    return QString();
}

QRectF ShapeAnnotation::getBoundingRect() const
{
    QPointF p1 = mExtent.at(0);
    QPointF p2 = mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    return QRectF (left, top, width, height);
}

QPainterPath ShapeAnnotation::addPathStroker(QPainterPath &path) const
{
    QPainterPathStroker stroker;
    stroker.setWidth(Helper::shapesStrokeWidth);
    return stroker.createStroke(path);
}

//! Tells the component to ask its parent to delete it.
void ShapeAnnotation::deleteMe()
{
    GraphicsView *pGraphicsView = qobject_cast<GraphicsView*>(const_cast<QObject*>(sender()));
    mpGraphicsView->deleteShapeObject(this);
    mpGraphicsView->scene()->removeItem(this);
    // if the signal is not send by graphicsview then emit updateshapeannotation
    if (!pGraphicsView)
    {
        emit updateShapeAnnotation();
    }
    delete this;
}

void ShapeAnnotation::doSelect()
{
    mIsRectangleCorneItemClicked = true;
    if (!this->isSelected())
        setSelectionBoxActive();
}

void ShapeAnnotation::doUnSelect()
{
    mIsRectangleCorneItemClicked = false;
    if (!this->isSelected())
        setSelectionBoxPassive();
}

//! Slot that moves component one pixel upwards
//! @see moveDown()
//! @see moveLeft()
//! @see moveRight()
void ShapeAnnotation::moveUp()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()+1);
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel downwards
//! @see moveUp()
//! @see moveLeft()
//! @see moveRight()
void ShapeAnnotation::moveDown()
{
    this->setPos(this->pos().x(), this->mapFromScene(this->mapToScene(this->pos())).y()-1);
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel leftwards
//! @see moveUp()
//! @see moveDown()
//! @see moveRight()
void ShapeAnnotation::moveLeft()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()-1, this->pos().y());
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

//! Slot that moves component one pixel rightwards
//! @see moveUp()
//! @see moveDown()
//! @see moveLeft()
void ShapeAnnotation::moveRight()
{
    this->setPos(this->mapFromScene(this->mapToScene(this->pos())).x()+1, this->pos().y());
    mpGraphicsView->scene()->update();
    emit updateShapeAnnotation();
}

void ShapeAnnotation::rotateClockwise()
{
    qreal rotation = this->rotation();
    qreal rotateIncrement = -90;

    if (rotation == -270)
        this->setRotation(0);
    else
        this->setRotation(rotation + rotateIncrement);
}

void ShapeAnnotation::rotateAntiClockwise()
{

    qreal rotation = this->rotation();
    qreal rotateIncrement = 90;

    if (rotation == 270)
        this->setRotation(0);
    else
        this->setRotation(rotation + rotateIncrement);
}

void ShapeAnnotation::resetRotation()
{
    this->setRotation(0);
}

void ShapeAnnotation::openShapeProperties()
{
    ShapeProperties *pShapeProperties = new ShapeProperties(this, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    pShapeProperties->show();
}

//! Event when mouse cursor enters component icon.
void ShapeAnnotation::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    // only use hover events for user defined lines
    if (!mIsCustomShape)
        return;

    if(!this->isSelected())
        setSelectionBoxHover();
}

//! Event when mouse cursor leaves component icon.
void ShapeAnnotation::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    Q_UNUSED(event);

    // only use hover events for user defined lines
    if (!mIsCustomShape)
        return;

    if(!this->isSelected())
        setSelectionBoxPassive();
}

void ShapeAnnotation::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (event->button() != Qt::LeftButton)
        return;
    // only use mouse events for user defined lines
    if (!mIsCustomShape or !mIsFinishedCreatingShape)
    {
        QGraphicsItem::mousePressEvent(event);
        return;
    }

    mClickPos = mapToScene(event->pos());
    mIsItemClicked = true;
    setCursor(Qt::SizeAllCursor);
    QGraphicsItem::mousePressEvent(event);
}

void ShapeAnnotation::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    // only use mouse events for user defined lines
    if (!mIsCustomShape or !mIsFinishedCreatingShape)
    {
        QGraphicsItem::mouseReleaseEvent(event);
        return;
    }

    if (mClickPos != mapToScene(event->pos()))
    {
        mIsItemClicked = false;
        emit updateShapeAnnotation();
    }
    unsetCursor();
    QGraphicsItem::mouseReleaseEvent(event);
}

QVariant ShapeAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
    QGraphicsItem::itemChange(change, value);
    if (change == QGraphicsItem::ItemSelectedHasChanged)
    {
        if (this->isSelected())
        {
            setSelectionBoxActive();
            // make the connections now
            connect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), SLOT(rotateClockwise()), Qt::UniqueConnection);
            connect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
            connect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), SLOT(resetRotation()), Qt::UniqueConnection);
            connect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), SLOT(deleteMe()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressDelete()), SLOT(deleteMe()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressUp()), SLOT(moveUp()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressDown()), SLOT(moveDown()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressLeft()), SLOT(moveLeft()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressRight()), SLOT(moveRight()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), SLOT(rotateClockwise()), Qt::UniqueConnection);
            connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
        }
        // if use has clicked on corner item then dont make it passive
        else if (!mIsRectangleCorneItemClicked)
        {
            setSelectionBoxPassive();
            disconnect(mpGraphicsView->mpRotateIconAction, SIGNAL(triggered()), this, SLOT(rotateClockwise()));
            disconnect(mpGraphicsView->mpRotateAntiIconAction, SIGNAL(triggered()), this, SLOT(rotateAntiClockwise()));
            disconnect(mpGraphicsView->mpResetRotation, SIGNAL(triggered()), this, SLOT(resetRotation()));
            disconnect(mpGraphicsView->mpDeleteIconAction, SIGNAL(triggered()), this, SLOT(deleteMe()));
            disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
            disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
            disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
            disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
            disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));

        }
    }
    return value;
}

void ShapeAnnotation::contextMenuEvent(QGraphicsSceneContextMenuEvent *event)
{
    if (!mpGraphicsView)
    {
        QGraphicsItem::contextMenuEvent(event);
        return;
    }

    setSelected(true);
    QMenu menu(mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
    menu.addAction(mpGraphicsView->mpRotateIconAction);
    menu.addAction(mpGraphicsView->mpRotateAntiIconAction);
    menu.addAction(mpGraphicsView->mpResetRotation);
    menu.addSeparator();
    menu.addAction(mpGraphicsView->mpDeleteIconAction);
    menu.addAction(mpShapePropertiesAction);
    menu.exec(event->screenPos());
}

ShapeProperties::ShapeProperties(ShapeAnnotation *pShape, MainWindow *pParent)
    : QDialog(pParent, Qt::WindowTitleHint)
{
    setAttribute(Qt::WA_DeleteOnClose);
    setMinimumSize(400, 300);
    setModal(true);

    mpParentMainWindow = pParent;
    mpShape = pShape;
    // set the shape type, whether it is Line, Rectangle, Ellipse etc...
    setShapeType();
    // set up the dialog based on shape type.
    setUpDialog();
}

void ShapeProperties::setShapeType()
{
    if (qobject_cast<LineAnnotation*>(mpShape))
        mShapeType = ShapeProperties::Line;
}

void ShapeProperties::setUpDialog()
{
    switch (mShapeType)
    {
        case ShapeProperties::Line:
            setUpLineDialog();
            break;
    }
}

void ShapeProperties::setUpLineDialog()
{
    setWindowTitle(QString(Helper::applicationName).append(" - Line Properties"));

    mpHeadingLabel = new QLabel(tr("Line Properties"));
    mpHeadingLabel->setFont(QFont("", Helper::headingFontSize));
    mpHeadingLabel->setAlignment(Qt::AlignTop);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->addWidget(mpHeadingLabel);
    layout->addLayout(createHorizontalLine());
    layout->addLayout(createPenControls());
    layout->addLayout(createBrushControls());

    setLayout(layout);
}

QVBoxLayout* ShapeProperties::createHorizontalLine()
{
    mpHorizontalLine = new QFrame();
    mpHorizontalLine->setFrameShape(QFrame::HLine);
    mpHorizontalLine->setFrameShadow(QFrame::Sunken);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpHorizontalLine);
    return layout;
}

QVBoxLayout* ShapeProperties::createPenControls()
{
    mpPenStyleGroup = new QGroupBox(tr("Pen Style"));

    mpPenColorLabel = new QLabel(tr("Color:"));
    mpPenColorViewerLabel = new QLabel(tr(""));
    mpPenColorPickButton = new QPushButton(tr("Pick Color"));
    connect(mpPenColorPickButton, SIGNAL(pressed()), SLOT(pickPenColor()));
    mpPenNoColorCheckBox = new QCheckBox(tr("No Color"));
    connect(mpPenNoColorCheckBox, SIGNAL(stateChanged(int)), SLOT(penNoColorChecked(int)));

    mpPenPatternLabel = new QLabel(tr("Pattern:"));
    mpPenPatternsComboBox = new QComboBox;
    mpPenPatternsComboBox->setIconSize(Helper::iconSize);
    mpPenPatternsComboBox->addItem(QIcon(":/Resources/icons/solidline.png"), tr("Solid"), Qt::SolidLine);
    mpPenPatternsComboBox->addItem(QIcon(":/Resources/icons/dashline.png"), tr("Dash"), Qt::DashLine);
    mpPenPatternsComboBox->addItem(QIcon(":/Resources/icons/dotline.png"), tr("Dot"), Qt::DotLine);
    mpPenPatternsComboBox->addItem(QIcon(":/Resources/icons/dashdotline.png"), tr("Dash Dot"), Qt::DashDotLine);
    mpPenPatternsComboBox->addItem(QIcon(":/Resources/icons/dashdotdotline.png"), tr("Dash Dot Dot"), Qt::DashDotDotLine);

    mpPenThicknessLabel = new QLabel(tr("Thickness:"));
    mpPenThicknessSpinBox = new QDoubleSpinBox;
    // change the locale to C so that decimal char is changed from ',' to '.'
    mpPenThicknessSpinBox->setLocale(QLocale("C"));
    mpPenThicknessSpinBox->setRange(0.25, 100.0);
    mpPenThicknessSpinBox->setSingleStep(0.5);

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpPenColorLabel, 0, 0);
    mainLayout->addWidget(mpPenColorViewerLabel, 0, 1);
    mainLayout->addWidget(mpPenColorPickButton, 1, 0);
    mainLayout->addWidget(mpPenNoColorCheckBox, 1, 1);
    mainLayout->addWidget(mpPenPatternLabel, 2, 0, 1, 2);
    mainLayout->addWidget(mpPenPatternsComboBox, 3, 0);
    mainLayout->addWidget(mpPenThicknessLabel, 4, 0, 1, 2);
    mainLayout->addWidget(mpPenThicknessSpinBox, 5, 0);
    mpPenStyleGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpPenStyleGroup);
    return layout;
}

QVBoxLayout* ShapeProperties::createBrushControls()
{
    mpBrushStyleGroup = new QGroupBox(tr("Brush Style"));

    mpBrushColorLabel = new QLabel(tr("Color:"));
    mpBrushColorViewerLabel = new QLabel(tr(""));
    mpBrushColorPickButton = new QPushButton(tr("Pick Color"));
    connect(mpBrushColorPickButton, SIGNAL(pressed()), SLOT(pickBrushColor()));
    mpBrushNoColorCheckBox = new QCheckBox(tr("No Color"));
    connect(mpBrushNoColorCheckBox, SIGNAL(stateChanged(int)), SLOT(brushNoColorChecked(int)));

    mpBrushPatternLabel = new QLabel(tr("Pattern:"));
    mpBrushPatternsComboBox = new QComboBox;
    mpBrushPatternsComboBox->setIconSize(Helper::iconSize);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/solid.png"), tr("Solid"), Qt::SolidPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/horizontal.png"), tr("Horizontal"), Qt::HorPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/vertical.png"), tr("Vertical"), Qt::VerPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/cross.png"), tr("Cross"), Qt::CrossPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/forward.png"), tr("Forward"), Qt::BDiagPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/backward.png"), tr("Backward"), Qt::FDiagPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/crossdiag.png"), tr("CrossDiag"), Qt::DiagCrossPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/horizontalcylinder.png"), tr("HorizontalCylinder"), Qt::LinearGradientPattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/verticalcylinder.png"), tr("VertitalCylinder"), Qt::Dense1Pattern);
    mpBrushPatternsComboBox->addItem(QIcon(":/Resources/icons/sphere.png"), tr("Sphere"), Qt::RadialGradientPattern);

    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    mainLayout->addWidget(mpBrushColorLabel, 0, 0);
    mainLayout->addWidget(mpBrushColorViewerLabel, 0, 1);
    mainLayout->addWidget(mpBrushColorPickButton, 1, 0);
    mainLayout->addWidget(mpBrushNoColorCheckBox, 1, 1);
    mainLayout->addWidget(mpBrushPatternLabel, 2, 0, 1, 2);
    mainLayout->addWidget(mpBrushPatternsComboBox, 3, 0);
    mpBrushStyleGroup->setLayout(mainLayout);

    QVBoxLayout *layout = new QVBoxLayout;
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(mpBrushStyleGroup);
    return layout;
}

void ShapeProperties::pickPenColor()
{
    QColor color = QColorDialog::getColor();

    if (color.spec() == QColor::Invalid)
        return;

    mPenColor = color;
    if (mpPenNoColorCheckBox->checkState() == Qt::Unchecked)
    {
        QPixmap pixmap(Helper::iconSize);
        pixmap.fill(mPenColor);
        mpPenColorViewerLabel->setPixmap(pixmap);
    }
}

void ShapeProperties::penNoColorChecked(int state)
{
    if (state == Qt::Checked)
    {
        if (mBrushColor.spec() != QColor::Invalid)
        {
            QPixmap pixmap(Helper::iconSize);
            pixmap.fill(Qt::black);
            mpPenColorViewerLabel->setPixmap(pixmap);
        }
        else
        {
            QPixmap pixmap(Helper::iconSize);
            pixmap.fill(Qt::transparent);
            mpPenColorViewerLabel->setPixmap(pixmap);
        }
    }
    else if (state == Qt::Unchecked)
    {
        if (mPenColor.spec() != QColor::Invalid)
        {
            QPixmap pixmap(Helper::iconSize);
            pixmap.fill(mPenColor);
            mpPenColorViewerLabel->setPixmap(pixmap);
        }
    }
}

void ShapeProperties::pickBrushColor()
{
    QColor color = QColorDialog::getColor();

    if (color.spec() == QColor::Invalid)
        return;

    mBrushColor = color;

    if (mpBrushNoColorCheckBox->checkState() == Qt::Unchecked)
    {
        QPixmap pixmap(Helper::iconSize);
        pixmap.fill(mBrushColor);
        mpBrushColorViewerLabel->setPixmap(pixmap);
    }
}

void ShapeProperties::brushNoColorChecked(int state)
{
    if (state == Qt::Checked)
    {
        QPixmap pixmap(Helper::iconSize);
        pixmap.fill(Qt::transparent);
        mpBrushColorViewerLabel->setPixmap(pixmap);
    }
    else if (state == Qt::Unchecked)
    {
        QPixmap pixmap(Helper::iconSize);
        pixmap.fill(mBrushColor);
        mpPenColorViewerLabel->setPixmap(pixmap);
    }
}
