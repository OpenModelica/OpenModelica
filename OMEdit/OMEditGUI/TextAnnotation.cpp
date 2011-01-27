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

#include "TextAnnotation.h"
#include "SimulationWidget.h"

TextAnnotation::TextAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpComponent(pParent)
{
    initializeFields();
    this->mFontWeight = -1;
    this->mFontItalic = false;
    this->mFontBold = false;
    this->mFontUnderLine = false;
    parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

TextAnnotation::TextAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    this->mFontItalic = false;
    this->mFontBold = false;
    this->mFontUnderLine = false;
    mTextString = QString("Text Here");
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

TextAnnotation::TextAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{    
    // initialize all fields with default values
    initializeFields();
    this->mFontItalic = false;
    this->mFontBold = false;
    this->mFontUnderLine = false;
    mIsCustomShape = true;
    parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);    
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF TextAnnotation::boundingRect() const
{    
    return shape().boundingRect();
}

QPainterPath TextAnnotation::shape() const
{
    QPainterPath path;
    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    QRectF rect (left, top, width, height);
    path.addRoundedRect(rect, mCornerRadius, mCornerRadius);

    return path;
}

void TextAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    top = -top;
    height = -height;

    QRectF rect (left, top, width, height);          

    this -> mFontSize = width;

    while(mFontSize > -height)
        mFontSize = mFontSize - 0.05;
    while(mFontSize > width/5.6)
        mFontSize = mFontSize - 0.05;

    if(!mIsCustomShape)
    {
        this -> mFontSize = width;

        while(mFontSize > -height)
            mFontSize = mFontSize - 0.05;
        while(mFontSize > width/15)
            mFontSize = mFontSize - 0.05;
    }    

    painter->scale(1.0, -1.0);
    QPen pen(this->mLineColor, this->mThickness, this->mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);
    painter->setBrush(QBrush(this->mFillColor, Qt::SolidPattern));
    painter->setFont(QFont(this->mFontName, this->mDefaultFontSize + this->mFontSize, this->mFontWeight, this->mFontItalic));
    painter->drawText(rect, Qt::AlignCenter, this->mTextString, &rect);
}

void TextAnnotation::checkNameString()
{
    if (this->mTextString.contains("%name"))
    {
        // if it is a root item the get name
        if (!mpComponent->mpParentComponent)
            mTextString = mpComponent->getName();
        else if (!mpComponent->mpComponentProperties)
            mTextString = mpComponent->getRootParentComponent()->getName();
        else if (mpComponent->mpComponentProperties)
            mTextString = mpComponent->mpComponentProperties->getName();
    }
}

void TextAnnotation::checkParameterString()
{
    QString parameterString;

    foreach (IconParameters *parameter, mpComponent->mpIconParametersList)
    {
        // paramter can be in form R=%R
        parameterString = QString(parameter->getName()).append("=%").append(parameter->getName());
        if (parameterString == mTextString)
        {
            mTextString = QString(parameter->getName()).append("=").append(parameter->getDefaultValue());
            break;
        }
        // paramter can be in form %R
        parameterString = QString("%").append(parameter->getName());
        if (parameterString == mTextString)
        {
            mTextString = QString(parameter->getDefaultValue());
            break;
        }
    }
}

QString TextAnnotation::getTextString()
{
    return mTextString.trimmed();
}

void TextAnnotation::setTextString(QString text)
{
    mTextString = text;
    update(boundingRect());
}

void TextAnnotation::drawRectangleCornerItems()
{
    mIsFinishedCreatingShape = true;
    for (int i = 0 ; i < this->mExtent.size() ; i++)
    {
        QPointF point = this->mExtent.at(i);
        RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
        mRectangleCornerItemsList.append(rectangleCornerItem);
    }
    emit updateShapeAnnotation();
}

void TextAnnotation::addPoint(QPointF point)
{
    mExtent.append(point);
}

void TextAnnotation::updatePoint(int index, QPointF point)
{
    mExtent.replace(index, point);
}

void TextAnnotation::updateEndPoint(QPointF point)
{
    mExtent.back() = point;    
}

void TextAnnotation::updateAnnotation()
{
    emit updateShapeAnnotation();
}

QString TextAnnotation::getShapeAnnotation()
{
    QString annotationString;
    annotationString.append("Text(");

    if (!mVisible)
    {
        annotationString.append("visible=false,");
    }    

    annotationString.append("rotation=").append(QString::number(this->rotation())).append(",");

    annotationString.append("lineColor={");
    annotationString.append(QString::number(mLineColor.red())).append(",");
    annotationString.append(QString::number(mLineColor.green())).append(",");
    annotationString.append(QString::number(mLineColor.blue()));
    annotationString.append("},");    

    annotationString.append("fillColor={");
    annotationString.append(QString::number(mFillColor.red())).append(",");
    annotationString.append(QString::number(mFillColor.green())).append(",");
    annotationString.append(QString::number(mFillColor.blue()));
    annotationString.append("},");

    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.value() == mLinePattern)
        {
            annotationString.append("pattern=LinePattern.").append(it.key()).append(",");
            break;
        }
    }

    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.value() == mFillPattern)
        {
            annotationString.append("fillPattern=FillPattern.").append(fill_it.key()).append(",");
            break;
        }
    }

    annotationString.append("lineThickness=").append(QString::number(mThickness)).append(",");
    annotationString.append("extent={{");
    annotationString.append(QString::number(mapToScene(mExtent.at(0)).x())).append(",");
    annotationString.append(QString::number(mapToScene(mExtent.at(0)).y())).append("},{");
    annotationString.append(QString::number(mapToScene(mExtent.at(1)).x())).append(",");
    annotationString.append(QString::number(mapToScene(mExtent.at(1)).y()));
    annotationString.append("}}");

    annotationString.append(",textString=");
    annotationString.append('"');
    annotationString.append(this->getTextString());
    annotationString.append('"');

    if(mFontItalic || mFontBold || mFontUnderLine)
    {
        annotationString.append("textStyle={");
        {
            if(mFontItalic)
                annotationString.append("TextStyle.Italic,");
            if(mFontBold)
                annotationString.append("TextStyle.Bold,");
            if(mFontUnderLine)
                annotationString.append("TextStyle.UnderLine");
        }
        annotationString.append("}");
    }

    annotationString.append(")");
    return annotationString;
}

void TextAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{

    shape = shape.replace("{", "");
    shape = shape.replace("}", "");

    // parse the shape to get the list of attributes of Text Annotation.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 17)
    {
        return;
    }

    // if first item of list is true then the Text Annotation should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    int index = 0;
    if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
      mOrigin.setX(static_cast<QString>(list.at(1)).toFloat());
      mOrigin.setY(static_cast<QString>(list.at(2)).toFloat());

      mRotation = static_cast<QString>(list.at(3)).toFloat();
      index = 3;
    }

    // 2,3,4 items of list contains the line color.
    index = index + 1;
    int red, green, blue;

    red = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    green = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    blue = static_cast<QString>(list.at(index)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // 5,6,7 items of list contains the fill color.
    index = index + 1;
    red = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    green = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    blue = static_cast<QString>(list.at(index)).toInt();
    this->mFillColor = QColor (red, green, blue);

    // 8 item of the list contains the line pattern.
    index = index + 1;
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(index));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key().compare(linePattern) == 0)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // 9 item of the list contains the fill pattern.
    index = index + 1;
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(index));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key().compare(fillPattern) == 0)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // 10 item of the list contains the thickness.
    index = index + 1;
    this->mThickness = static_cast<QString>(list.at(index)).toFloat();

    // 11, 12, 13, 14 items of the list contains the extent points of Ellipse.
    index = index + 1;
    qreal x = static_cast<QString>(list.at(index)).toFloat();
    index = index + 1;
    qreal y = static_cast<QString>(list.at(index)).toFloat();
    QPointF p1 (x, y);
    index = index + 1;
    x = static_cast<QString>(list.at(index)).toFloat();
    index = index + 1;
    y = static_cast<QString>(list.at(index)).toFloat();
    QPointF p2 (x, y);

    this->mExtent.append(p1);
    this->mExtent.append(p2);

    // 15 item of the list contains the text string.
    index = index + 1;

    if(mIsCustomShape)
        this->mTextString = StringHandler::removeFirstLastQuotes(list.at(index));
    else
    {
        this->mTextString = StringHandler::removeFirstLastQuotes(list.at(index));
        checkNameString();
        checkParameterString();
    }

    // 16 item of the list contains the font size.
    index = index + 1;
    this->mFontSize = static_cast<QString>(list.at(index)).toInt();

    // 17 item of the list contains the font name.
    index = index + 1;
    if (list.size() < index)
    {
        this->mFontName = StringHandler::removeFirstLastQuotes(list.at(index));
    }
    else
    {
        //this->mFontName = "Tahoma";
        this->mFontName = qApp->font().family();
    }

    //if item is Diagram view then dont change the font value
    //    if (mpComponent->mType == StringHandler::DIAGRAM)
    //        this->mDefaultFontSize = 15;
    //    else
    //        this->mDefaultFontSize = 25;
}

//TextWidget declarations

TextWidget::TextWidget(TextAnnotation *pTextShape, MainWindow *parent)
    : QDialog(parent, Qt::WindowTitleHint)
{
    setWindowTitle(QString(Helper::applicationName).append(" - Text"));
    setAttribute(Qt::WA_DeleteOnClose);
    setMaximumSize(175, 150);
    mpParentMainWindow = parent;
    mpTextAnnotation = pTextShape;
    setUpForm();
}

void TextWidget::setUpForm()
{
    mpTextLabel = new QLabel(tr("Text of Label:"));
    mpTextBox = new QLineEdit(mpTextAnnotation->getTextString());

    mpEditButton = new QPushButton(tr("Ok"));
    mpEditButton->setAutoDefault(true);
    connect(mpEditButton, SIGNAL(pressed()), this, SLOT(edit()));

    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));

    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpEditButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

    QGridLayout *mainLayout = new QGridLayout;

    mainLayout->addWidget(mpTextLabel, 0, 0);
    mainLayout->addWidget(mpTextBox, 1, 0);
    mainLayout->addWidget(mpButtonBox, 2, 0);

    setLayout(mainLayout);
}

void TextWidget::edit()
{
    if(mpTextBox->text().isEmpty())
    {
        return;
    }
    mpTextAnnotation->setTextString(mpTextBox -> text());
    mpTextAnnotation->updateAnnotation();
    accept();
}

void TextWidget::show()
{
    setVisible(true);
}



