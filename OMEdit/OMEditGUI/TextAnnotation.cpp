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

TextAnnotation::TextAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpComponent(pParent)
{
    initializeFields();
    this->mFontWeight = -1;
    this->mFontItalic = false;
    this->mFontName = qApp->font().family();
    this->mHorizontalAlignment = Qt::AlignCenter;
    this->mFontUnderLine = false;
    this->mFontSize = 0;
    parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

TextAnnotation::TextAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    this->mFontWeight = -1;
    this->mFontItalic = false;
    this->mFontName = qApp->font().family();
    this->mHorizontalAlignment = Qt::AlignCenter;
    this->mFontUnderLine = false;
    this->mFontSize = 0;
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
    this->mFontWeight = -1;
    this->mFontItalic = false;
    this->mFontName = qApp->font().family();
    this->mHorizontalAlignment = Qt::AlignCenter;
    this->mFontUnderLine = false;
    mIsCustomShape = true;
    this->mFontSize = 0;    

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

    double localFontSize;

    //If fontsize is 0, scale to fit the rectangle
    if(this->mFontSize == 0)
    {
        localFontSize = width;

        while(localFontSize > -height - 3.5)
        {
            localFontSize = localFontSize - 0.05;
        }
        while(localFontSize > width/7)
            localFontSize = localFontSize - 0.05;
        if(-height - 3.5 <= 1)
            localFontSize = 3;

        if(!mIsCustomShape)
        {
            localFontSize = width;

            while(localFontSize > -height)
                localFontSize = localFontSize - 0.05;
            while(localFontSize > width/15)
                localFontSize = localFontSize - 0.05;
        }
    }
    else
        localFontSize = this->mFontSize;

    painter->scale(1.0, -1.0);
    QPen pen(this->mLineColor, this->mThickness, this->mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);
    painter->setBrush(QBrush(this->mFillColor, Qt::SolidPattern));

    QFont font(this->mFontName, localFontSize, this->mFontWeight, this->mFontItalic);
    if(this->mFontUnderLine)
        font.setUnderline(true);
    painter->setFont(font);
    //painter->setFont(QFont(this->mFontName, this->mDefaultFontSize + this->mFontSize, this->mFontWeight, this->mFontItalic));
    painter->drawText(rect, mHorizontalAlignment, this->mTextString);
}

void TextAnnotation::checkNameString()
{
    /* the name of the component can be present in any inherited class . So we start with the main class and then
       move up the hierarchy looking for the name.
    */
    if (this->mTextString.contains("%name"))
    {
        if (!mpComponent->getName().isEmpty())
            mTextString = mpComponent->getName();
        else
        {
            Component *pComponent = mpComponent;
            while (pComponent->mpParentComponent)
            {
                pComponent = pComponent->mpParentComponent;
                if (!pComponent->getName().isEmpty())
                {
                    mTextString = pComponent->getName();
                    break;
                }
            }
        }
    }
}

void TextAnnotation::checkParameterString()
{
    // look for the string in parameters list
    foreach (IconParameters *parameter, mpComponent->mIconParametersList)
    {
        if (updateParameterString(parameter))
            break;
    }
}

bool TextAnnotation::updateParameterString(IconParameters *pParamter)
{
    QString parameterString;
    // paramter can be in form R=%R
    parameterString = QString(pParamter->getName()).append("=%").append(pParamter->getName());
    if (parameterString == mTextString)
    {
        mTextString = QString(pParamter->getName()).append("=").append(pParamter->getDefaultValue());
        return true;
    }
    // paramter can be in form %R
    parameterString = QString("%").append(pParamter->getName());
    if (parameterString == mTextString)
    {
        mTextString = QString(pParamter->getDefaultValue());
        return true;
    }
    return false;
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

void TextAnnotation::setFontName(QString fontName)
{
    mFontName = fontName;
}

void TextAnnotation::setFontSize(double fontSize)
{
    mFontSize = fontSize;
}

void TextAnnotation::setItalic(bool italic)
{
    mFontItalic = italic;
}

void TextAnnotation::setWeight(int bold)
{
    mFontWeight = bold;
}

void TextAnnotation::setUnderLine(bool underLine)
{
    mFontUnderLine = underLine;
}

void TextAnnotation::setAlignment(Qt::Alignment alignment)
{
    mHorizontalAlignment = alignment;
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

    if(this->mFontSize != 0)
    {
        annotationString.append(",fontSize=");
        annotationString.append(QString::number(this->mFontSize));

    }

    if(!(this->mFontName == qApp->font().family()))
    {
        annotationString.append(",fontName=");
        annotationString.append('"');
        annotationString.append(this->mFontName);
        annotationString.append('"');
    }

    //Annotation for text style bold italic underline
    if(mFontItalic || (mFontWeight == QFont::Bold) || mFontUnderLine)
    {
        annotationString.append(",textStyle={");
        {
            if(mFontItalic)
                annotationString.append("TextStyle.Italic");

            if(mFontWeight == QFont::Bold)
            {
                if(mFontItalic)
                    annotationString.append(",TextStyle.Bold");
                else
                    annotationString.append("TextStyle.Bold");
            }
            if(mFontUnderLine)
            {
                if(mFontItalic || mFontWeight == QFont::Bold)
                    annotationString.append(",TextStyle.UnderLine");
                else
                    annotationString.append("TextStyle.UnderLine");
            }
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

    // 11, 12, 13, 14 items of the list contains the extent points of Text.
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

    index++;
    //Now comes the optional parameters.
    while(index < list.size())
    {
        QString line = StringHandler::removeFirstLastQuotes(list.at(index));
        if(line == "TextStyle.Italic")
        {
            this->mFontItalic = true;
            index++;
        }
        else if(line == "TextStyle.Bold")
        {
            this->mFontWeight = QFont::Bold;
            index++;
        }
        else if(line == "TextStyle.UnderLine")
        {
            this->mFontUnderLine = true;
            index++;
        }
        else if(line.length() < 3)
        {
            this->mFontSize = line.toInt();
            index++;
        }
        else if(line == "TextAlignment.Center" )
        {
            this-> mHorizontalAlignment = Qt::AlignCenter;
            index++;
        }
        else if(line == "TextAlignment.Left" )
        {
            this-> mHorizontalAlignment = Qt::AlignLeft;
            index++;
        }
        else if(line == "TextAlignment.Right" )
        {
            this-> mHorizontalAlignment = Qt::AlignRight;
            index++;
        }
        else if(line.length() > 3)
        {
            this->mFontName = line;
            index++;
        }
    }

    // 16 item of the list contains the font size.
//    index = index + 1;
//    this->mFontSize = static_cast<QString>(list.at(index)).toInt();
////    if(this->mFontSize != 0)
////        this->mDefaultFontSize = this->mFontSize;

//    if(!mIsCustomShape)
//        return;

//    // 17 item of the list contains the font name.
//    index = index + 1;
//    //if (list.size() < index)
//        this->mFontName = StringHandler::removeFirstLastQuotes(list.at(index));
////    else
////    {
////        //this->mFontName = "Tahoma";
////        this->mFontName = qApp->font().family();
////    }

//    //Get text style
//    index = index + 1;
//    QString style = StringHandler::removeFirstLastQuotes(list.at(index));
//    if(style == "TextStyle.Italic")
//    {
//        this->mFontItalic = true;
//        index++;
//    }
//    style = StringHandler::removeFirstLastQuotes(list.at(index));
//    if(style == "TextStyle.Bold")
//    {
//        this->mFontWeight = QFont::Bold;
//        index++;
//    }
//    style = StringHandler::removeFirstLastQuotes(list.at(index));
//    if(style == "TextStyle.UnderLine")
//    {
//        this->mFontUnderLine = true;
//        index++;
//    }

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
    //setMaximumSize(300, 300);
    mpParentMainWindow = parent;
    mpTextAnnotation = pTextShape;
    setUpForm();
}

void TextWidget::setUpForm()
{
    //Text Label
    QGridLayout *textLayout = new QGridLayout;
    mpTextGroup = new QGroupBox();
    mpTextLabel = new QLabel(tr("Text of Label:"));
    mpTextBox = new QLineEdit(mpTextAnnotation->getTextString());
    textLayout->addWidget(mpTextLabel, 0, 0);
    textLayout->addWidget(mpTextBox, 0, 1);
    mpTextGroup->setLayout(textLayout);

    //Font Name    
    QGridLayout *fontLayout = new QGridLayout;
    mpFontGroup = new QGroupBox();
    mpFontLabel = new QLabel(tr("Fontname:"));
    mpFontFamilyComboBox = new QFontComboBox;
    fontLayout->addWidget(mpFontLabel, 0, 0);
    fontLayout->addWidget(mpFontFamilyComboBox, 0, 1);
    mpFontGroup->setLayout(fontLayout);

    //Font Size
    mpFontSizeComboBox = new QComboBox;
    QStringList sizesList;
    sizesList << "0" << "2" << "4" << "6" << "7" << "8" << "9" << "10" << "11" << "12"
              << "14" << "16" << "18" << "20" << "22" << "24" << "26" << "28"
              << "36" << "48" << "72";
    mpFontSizeComboBox->addItems(sizesList);
    QGridLayout *fontSizeLayout = new QGridLayout;
    mpFontSizeGroup = new QGroupBox();
    mpFontSizeLabel = new QLabel(tr("Fontsize:"));
    fontSizeLayout->addWidget(mpFontSizeLabel, 0, 0);
    fontSizeLayout->addWidget(mpFontSizeComboBox, 0, 1, Qt::AlignLeft);
    mpFontSizeGroup->setLayout(fontSizeLayout);

    //Cursive Bold Underline Checkboxes
    QGridLayout *styleLayout = new QGridLayout;
    mpStyleGroup = new QGroupBox();
    mpCursive = new QCheckBox("Italic", this);
    mpBold = new QCheckBox("Bold", this);
    mpUnderline = new QCheckBox("Underline", this);
    styleLayout->addWidget(mpCursive, 0, 1);
    styleLayout->addWidget(mpBold, 0, 2);
    styleLayout->addWidget(mpUnderline, 0, 3);
    mpStyleGroup->setLayout(styleLayout);

    //Alignment
    mpAlignmentComboBox = new QComboBox;
    QStringList alignmentList;
    alignmentList << "Center" << "Left" << "Right";
    mpAlignmentComboBox->addItems(alignmentList);
    QGridLayout *alignmentLayout = new QGridLayout;
    mpAlignmentGroup = new QGroupBox();
    mpAlignmentLabel = new QLabel(tr("Alignment:"));
    alignmentLayout->addWidget(mpAlignmentLabel, 0, 0);
    alignmentLayout->addWidget(mpAlignmentComboBox, 0, 1, Qt::AlignLeft);
    mpAlignmentGroup->setLayout(alignmentLayout);

    //Buttons
    mpEditButton = new QPushButton(tr("Ok"));
    mpEditButton->setAutoDefault(true);
    connect(mpEditButton, SIGNAL(pressed()), this, SLOT(edit()));
    mpCancelButton = new QPushButton(tr("Cancel"));
    mpCancelButton->setAutoDefault(false);
    connect(mpCancelButton, SIGNAL(pressed()), this, SLOT(reject()));
    mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
    mpButtonBox->addButton(mpEditButton, QDialogButtonBox::ActionRole);
    mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);   

    //Main Layout
    QGridLayout *mainLayout = new QGridLayout;
    mainLayout->addWidget(mpTextGroup, 1, 0);
    mainLayout->addWidget(mpFontGroup, 2, 0);
    mainLayout->addWidget(mpFontSizeGroup, 3, 0);
    mainLayout->addWidget(mpStyleGroup, 4, 0);
    mainLayout->addWidget(mpAlignmentGroup, 5, 0);
    mainLayout->addWidget(mpButtonBox, 6, 0);

    setLayout(mainLayout);
}

void TextWidget::edit()
{
    if(mpTextBox->text().isEmpty())    
        return;

    mpTextAnnotation->setTextString(mpTextBox->text());
    mpTextAnnotation->setFontName(mpFontFamilyComboBox->currentText());
    mpTextAnnotation->setFontSize(mpFontSizeComboBox->currentText().toDouble());

    if(mpCursive->isChecked())
        mpTextAnnotation->setItalic(true);
    if(mpBold->isChecked())
        mpTextAnnotation->setWeight(QFont::Bold);    
    if(mpUnderline->isChecked())
        mpTextAnnotation->setUnderLine(true);

    if(mpFontSizeComboBox->currentText().toDouble() != 0)
    {
        if(mpAlignmentComboBox->currentText() == "Left")
            mpTextAnnotation->setAlignment(Qt::AlignLeft);
        else if(mpAlignmentComboBox->currentText() == "Right")
            mpTextAnnotation->setAlignment(Qt::AlignRight);
    }

    mpTextAnnotation->updateAnnotation();
    accept();
}

void TextWidget::show()
{
    setVisible(true);
}
