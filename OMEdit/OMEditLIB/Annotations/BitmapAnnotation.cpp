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

#include "BitmapAnnotation.h"
#include "Modeling/Commands.h"
#include "Util/ResourceCache.h"
#include "Renderers.h"

#include <QMessageBox>

const char* bitmapResourceName = ":/Resources/icons/bitmap-shape.svg";

/*!
 * \brief A very simple heuristic to clasify the content type.
 *
 * Note that it's not super critical if this logic breaks for a weirdly contaminated SVG
 * file. In a worst-case scenario, we will return `false` and fall back to processing the file
 * with QImage, which will work and only make the rendering less perfect at larger zoom levels.
 * Therefore not overinvesting into this here.
 *
 * \return true if the given are of an SVG image, false otherwise.
 */
bool isSvgImage(const QByteArray &bytes)
{
  return bytes.left(1024).toLower().contains("<svg") && bytes.right(256).toLower().contains("</svg>");
}

/*!
 * \brief A factory function for a Renderers, based on input binary image data.
 * \param bytes The binry data bytes representing the image.
 * \return A pointer to a newly created rendered object.
 */
std::unique_ptr<Renderer> makeRenderer(const QByteArray &bytes)
{
  if (isSvgImage(bytes)) {
    return std::make_unique<SvgRenderer>(bytes);
  }
  return std::make_unique<BitmapRenderer>(bytes);
}

/*!
 * \brief A helper function to get a file content as byte array.
 */
QByteArray getFileAsBytes(const QString &fileName)
{
  QFile file(fileName);
  file.open(QIODevice::ReadOnly);
  return file.readAll();
}

BitmapAnnotation::BitmapAnnotation(QString classFileName, QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mClassFileName = classFileName;
  // set the default values
  setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

BitmapAnnotation::BitmapAnnotation(ModelInstance::Bitmap *pBitmap, const QString &classFileName, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mpBitmap = pBitmap;
  mClassFileName = classFileName;
  // set the default values
  setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  setShapeFlags(true);
}

BitmapAnnotation::BitmapAnnotation(BitmapAnnotation *pBitmapAnnotation, Element *pParent)
  : ShapeAnnotation(pBitmapAnnotation, pParent)
{
  mpOriginItem = 0;
  updateShape(pBitmapAnnotation);
  applyTransformation();
  setFileName(pBitmapAnnotation->getFileName());
  setImageSource(pBitmapAnnotation->getImageSource());
  updateRenderer();
}

BitmapAnnotation::BitmapAnnotation(ModelInstance::Bitmap *pBitmap, const QString &classFileName, Element *pParent)
  : ShapeAnnotation(pParent)
{
  mpOriginItem = 0;
  mpBitmap = pBitmap;
  mClassFileName = classFileName;
  // set the default values
  setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  applyTransformation();
}

BitmapAnnotation::BitmapAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

/*!
 * \brief BitmapAnnotation::BitmapAnnotation
 * Used by OMSimulator FMU ModelWidget\n
 * We always make this shape as inherited shape since its not allowed to be modified.
 * \param classFileName
 * \param pGraphicsView
 */
BitmapAnnotation::BitmapAnnotation(QString classFileName, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mClassFileName = classFileName;
  // set the default values
  setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  QVector<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtents(extents);
  setPos(mOrigin);
  setRotation(mRotation);
  setShapeFlags(true);

  setFileName(mClassFileName);
  setImageSource("");
  updateRenderer();
}

// No, we can not put this simply in the declaration and have unique_ptr accepting incomplete type.
BitmapAnnotation::~BitmapAnnotation() = default;

void BitmapAnnotation::updateRenderer()
{
  if (!mImageSource.isEmpty()) {
    QByteArray bytes = QByteArray::fromBase64(mImageSource.toLatin1());
    mpRenderer = makeRenderer(bytes);
  } else {
    if (!mFileName.isEmpty() && QFile::exists(mFileName)) {
      mpRenderer = makeRenderer(getFileAsBytes(getFileName()));
    } else {
      mpRenderer = std::make_unique<SvgRenderer>(getFileAsBytes(bitmapResourceName));
    }
  }
}

void BitmapAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Bitmap.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 5) {
    return;
  }
  // 4th item is the extent points
  mExtent.parse(list.at(3));
  // 5th item is the fileName
  setFileName(StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(4))));
  // 6th item is the imageSource
  if (list.size() >= 6) {
    setImageSource(StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(5))));
  }
  updateRenderer();
}

void BitmapAnnotation::parseShapeAnnotation()
{
  GraphicItem::parseShapeAnnotation(mpBitmap);

  mExtent = mpBitmap->getExtent();
  mExtent.evaluate(mpBitmap->getParentModel());
  setFileName(StringHandler::removeFirstLastQuotes(stripDynamicSelect(mpBitmap->getFileName())));
  setImageSource(StringHandler::removeFirstLastQuotes(stripDynamicSelect(mpBitmap->getImageSource())));
  updateRenderer();
}

QRectF BitmapAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath BitmapAnnotation::shape() const
{
  QPainterPath path;
  path.addRect(getBoundingRect());
  return path;
}

void BitmapAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible) {
    drawBitmapAnnotation(painter);
  }
}

/*!
 * \brief BitmapAnnotation::drawBitmapAnnotation
 * Draws the bitmap.
 * \param painter
 */
void BitmapAnnotation::drawBitmapAnnotation(QPainter *painter)
{
  QRectF rect = getBoundingRect().normalized();

  if (mpRenderer) {
    mpRenderer->render(painter, rect, true);
  }
}

/*!
 * \brief BitmapAnnotation::getOMCShapeAnnotation
 * Returns Bitmap annotation in format as returned by OMC.
 * \return
 */
QString BitmapAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  // get the extents
  annotationString.append(mExtent.toQString());
  // get the file name
  annotationString.append(QString("\"").append(mOriginalFileName).append("\""));
  // get the image source
  annotationString.append(QString("\"").append(mImageSource).append("\""));
  return annotationString.join(",");
}

/*!
 * \brief BitmapAnnotation::getOMCShapeAnnotationWithShapeName
 * Returns Bitmap annotation in format as returned by OMC wrapped in Bitmap keyword.
 * \return
 */
QString BitmapAnnotation::getOMCShapeAnnotationWithShapeName()
{
  return QString("Bitmap(%1)").arg(getOMCShapeAnnotation());
}

/*!
 * \brief BitmapAnnotation::getShapeAnnotation
 * Returns Bitmap annotation.
 * \return
 */
QString BitmapAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  // get the extents
  if (mExtent.isDynamicSelectExpression() || mExtent.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtent.toQString()));
  }
  // get the file name
  if (!mOriginalFileName.isEmpty()) {
    annotationString.append(QString("fileName=\"").append(mOriginalFileName).append("\""));
  }
  // get the image source
  if (!mImageSource.isEmpty()) {
    annotationString.append(QString("imageSource=\"").append(mImageSource).append("\""));
  }
  return QString("Bitmap(").append(annotationString.join(",")).append(")");
}

void BitmapAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

ModelInstance::Model *BitmapAnnotation::getParentModel() const
{
  if (mpBitmap) {
    return mpBitmap->getParentModel();
  }
  return 0;
}

/*!
 * \brief BitmapAnnotation::duplicate
 * Duplicates the shape.
 */
void BitmapAnnotation::duplicate()
{
  BitmapAnnotation *pBitmapAnnotation = new BitmapAnnotation(mClassFileName, "", mpGraphicsView);
  pBitmapAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  pBitmapAnnotation->setOrigin(mOrigin + gridStep);
  pBitmapAnnotation->drawCornerItems();
  pBitmapAnnotation->setCornerItemsActiveOrPassive();
  pBitmapAnnotation->applyTransformation();
  pBitmapAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pBitmapAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pBitmapAnnotation, mpGraphicsView);
  setSelected(false);
  pBitmapAnnotation->setSelected(true);
}

/*!
 * \brief ShapeAnnotation::setFileName
 * Sets the file name.
 * \param fileName
 */
void BitmapAnnotation::setFileName(QString fileName)
{
  if (fileName.isEmpty()) {
    mOriginalFileName = fileName;
    mFileName = fileName;
    return;
  }

  OMCProxy* pOMCProxy = MainWindow::instance()->getOMCProxy();
  mOriginalFileName = fileName;
  QUrl fileUrl(mOriginalFileName);
  QFileInfo fileInfo(mOriginalFileName);
  QFileInfo classFileInfo(mClassFileName);
  /* if its a modelica:// link then make it absolute path */
  if (fileUrl.scheme().toLower().compare("modelica") == 0) {
    mFileName = pOMCProxy->uriToFilename(mOriginalFileName);
  } else if (fileInfo.isRelative()) {
    mFileName = QString(classFileInfo.absoluteDir().absolutePath()).append("/").append(mOriginalFileName);
  } else if (fileInfo.isAbsolute()) {
    mFileName = mOriginalFileName;
  } else {
    mFileName = "";
  }
}

/*!
  Returns the file name.
  \return the file name.
  */
QString BitmapAnnotation::getFileName()
{
  return mOriginalFileName;
}

/*!
  \brief Sets the image source.
  */
void BitmapAnnotation::setImageSource(QString imageSource)
{
  mImageSource = imageSource;
}

/*!
  Returns the base 64 image source.
  \return the image source.
  */
QString BitmapAnnotation::getImageSource()
{
  return mImageSource;
}

/*!
  Returns the image.
  \return the image.
  */
QImage BitmapAnnotation::getImage()
{
  if (mpRenderer)
  {
    return mpRenderer->getImage();
  }
  return BitmapAnnotation::getPlaceholderImage();
}

QImage BitmapAnnotation::getPlaceholderImage()
{
  return ResourceCache::getImage(bitmapResourceName);
}

void BitmapAnnotation::setDefaults()
{
  ShapeAnnotation::setDefaults();

  mFileName = "";
  mImageSource = "";
  updateRenderer();
}
