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

#include "BitmapAnnotation.h"

BitmapAnnotation::BitmapAnnotation(QString shape, Component *pParent)
  : ShapeAnnotation(pParent), mpComponent(pParent)
{
  initializeFields();
  parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

BitmapAnnotation::BitmapAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
  : ShapeAnnotation(graphicsView, pParent)
{
  initializeFields();
  mIsCustomShape = true;
  setAcceptHoverEvents(true);
  mFileName = ":/Resources/icons/bitmap-shape.png";

  QFile* file = new QFile(":/Resources/icons/bitmap-shape.png");
  file->open(QIODevice::ReadOnly);
  QByteArray image = file->readAll();
  mImageSource = QString(image.toBase64());

  connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

BitmapAnnotation::BitmapAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
  : ShapeAnnotation(graphicsView, pParent)
{
  // initialize all fields with default values
  initializeFields();
  mIsCustomShape = true;
  parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
  setAcceptHoverEvents(true);
  connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF BitmapAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath BitmapAnnotation::shape() const
{
  QPainterPath path;
  path.addRoundedRect(getBoundingRect(), mCornerRadius, mCornerRadius);
  return path;
}

void BitmapAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);

  if(!mImageSource.isEmpty())
  {
    //open file from image source
    QByteArray data = QByteArray::fromBase64(mImageSource.toLatin1());
    QImage image;
    if(image.loadFromData(data))
      painter->drawImage(getBoundingRect(), image.mirrored());
  }
  else
  {
    QImage image(mFileName);
    painter->drawImage(getBoundingRect(), image.mirrored());
  }
}

void BitmapAnnotation::addPoint(QPointF point)
{
  mExtent.append(point);
}

void BitmapAnnotation::updatePoint(int index, QPointF point)
{
  mExtent.replace(index, point);
}

void BitmapAnnotation::updateEndPoint(QPointF point)
{
  mExtent.back() = point;
}

void BitmapAnnotation::drawRectangleCornerItems()
{
  mIsFinishedCreatingShape = true;
  for (int i = 0 ; i < mExtent.size() ; i++)
  {
    QPointF point = mExtent.at(i);
    RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
    mRectangleCornerItemsList.append(rectangleCornerItem);
  }
  emit updateShapeAnnotation();
}

QString BitmapAnnotation::getShapeAnnotation()
{
  QString annotationString;
  annotationString.append("Bitmap(");

  if (!mVisible)
  {
    annotationString.append("visible=false,");
  }

  annotationString.append("rotation=").append(QString::number(rotation())).append(",");

  annotationString.append("extent={{");
  annotationString.append(QString::number(mapToScene(mExtent.at(0)).x())).append(",");
  annotationString.append(QString::number(mapToScene(mExtent.at(0)).y())).append("},{");
  annotationString.append(QString::number(mapToScene(mExtent.at(1)).x())).append(",");
  annotationString.append(QString::number(mapToScene(mExtent.at(1)).y()));
  annotationString.append("}}");

  if(mImageSource.isEmpty())
  {
    annotationString.append(", fileName=");
    annotationString.append('"');
    annotationString.append(mFileName);
    annotationString.append('"');

    annotationString.append(", imageSource=");
    annotationString.append('""');
  }
  else
  {
    annotationString.append(", fileName=");
    annotationString.append('""');

    annotationString.append(", imageSource=");
    annotationString.append('"');
    annotationString.append(mImageSource);
    annotationString.append('"');
  }

  annotationString.append(")");
  return annotationString;
}

void BitmapAnnotation::setFileName(QString fileName)
{
  mFileName = fileName;
}

void BitmapAnnotation::updateAnnotation()
{
  emit updateShapeAnnotation();
}

void BitmapAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
  shape = shape.replace("{", "");
  shape = shape.replace("}", "");

  // parse the shape to get the list of attributes of bitmap.
  QStringList list = StringHandler::getStrings(shape);
  //    if (list.size() < 16)
  //    {
  //        return;
  //    }

  // if first item of list is true then the Rectangle should be visible.
  mVisible = static_cast<QString>(list.at(0)).contains("true");

  int index = 0;
  if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    mOrigin.setX(static_cast<QString>(list.at(1)).toFloat());
    mOrigin.setY(static_cast<QString>(list.at(2)).toFloat());

    mRotation = static_cast<QString>(list.at(3)).toFloat();
    index = 3;
  }

  // 4,5,6,7 items of the list contains the extent points of rectangle.
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

  mExtent.append(p1);
  mExtent.append(p2);

  //8 Item contains filename
  index = index + 1;
  QString tempFileName = StringHandler::removeFirstLastQuotes(list.at(index));
  QDir dir(tempFileName);

  if(dir.isAbsolute())
    mFileName = tempFileName;
  else
  {
    if(tempFileName.startsWith("/"))
      mFileName = tempFileName;
    else
    {
      tempFileName.insert(0, QString("/"));
      mFileName = tempFileName;
    }
  }

  //If not customshape create absolute path.
  if(!mIsCustomShape)
  {
    QString modelPath = mpComponent->mpOMCProxy->getSourceFile(mpComponent->getClassName());
    QFileInfo qFile(modelPath);
    mFileName = qFile.absolutePath() + "/" + tempFileName;
  }

  //9 Item contains imagesource
  if(tempFileName.isEmpty())
  {
    index = index + 1;
    mImageSource = StringHandler::removeFirstLastQuotes(list.at(index));
  }
}

void BitmapAnnotation::setImageSource(QString imageSource)
{
  mImageSource = imageSource;
}

QString BitmapAnnotation::getFileName()
{
  return mFileName;
}

//Bitmapwidget declarations...

BitmapWidget::BitmapWidget(BitmapAnnotation *pBitmapShape, MainWindow *parent)
  : QDialog(parent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Open Bitmap")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMaximumSize(175, 150);
  mpParentMainWindow = parent;

  mpBitmapAnnotation = pBitmapShape;

  setUpForm();
}

void BitmapWidget::setUpForm()
{
  mpBrowseBox = new QLineEdit;

  mpBrowseButton = new QPushButton(Helper::browse);
  mpBrowseButton->setAutoDefault(true);
  connect(mpBrowseButton, SIGNAL(clicked()), this, SLOT(browse()));

  mpCheckBox = new QCheckBox(tr("Store picture in model"), this);

  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(false);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(edit()));

  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));

  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

  QGridLayout *mainLayout = new QGridLayout;

  mainLayout->addWidget(mpBrowseBox, 0, 0);
  mainLayout->addWidget(mpBrowseButton, 0, 1);
  mainLayout->addWidget(mpCheckBox, 2, 0);
  mainLayout->addWidget(mpButtonBox, 3, 0);

  setLayout(mainLayout);
}

void BitmapWidget::edit()
{
  if(!(mpBrowseBox->text().endsWith("png") || mpBrowseBox->text().endsWith("bmp") || mpBrowseBox->text().endsWith("jpg")))
  {
    QMessageBox::critical(mpParentMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::UNKNOWN_FILE_FORMAT).arg(".png,.bmp,.jpg"), Helper::ok);
    return;
  }

  //Set file name as picture path relative to model directory...
  QString modelPath = mpParentMainWindow->mpProjectTabs->getCurrentTab()->mModelFileName;
  QFileInfo qfile(modelPath);
  QDir dir(qfile.absolutePath());
  QString relativePath;
  relativePath = dir.relativeFilePath(mpBrowseBox->text());
  mpBitmapAnnotation->setFileName("/" + relativePath);

  if(!dir.exists(relativePath))
  {
    QMessageBox::critical(mpParentMainWindow, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg(relativePath), Helper::ok);
    return;
  }

  //Store imageSource base64 of the image if checked
  if(mpCheckBox->isChecked())
  {
    QFile* file = new QFile(mpBrowseBox->text());
    file->open(QIODevice::ReadOnly);
    QByteArray image = file->readAll();
    QString imageSource = QString(image.toBase64());

    mpBitmapAnnotation->setImageSource(imageSource);
  }
  else
    mpBitmapAnnotation->setImageSource("");

  accept();
  mpBitmapAnnotation->updateAnnotation();
}

void BitmapWidget::show()
{
  setVisible(true);
}

void BitmapWidget::browse()
{
  QString name = StringHandler::getOpenFileName(this, Helper::chooseFile, NULL, "Image Files (*.png *.bmp *.jpg)", NULL);
  mpBrowseBox->setText(name);
}
