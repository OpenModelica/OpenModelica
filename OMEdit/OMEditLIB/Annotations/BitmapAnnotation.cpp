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

#include <QMessageBox>

BitmapAnnotation::BitmapAnnotation(QString classFileName, QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mClassFileName = classFileName;
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

BitmapAnnotation::BitmapAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
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
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtents(extents);
  setPos(mOrigin);
  setRotation(mRotation);
  setShapeFlags(true);

  setFileName(mClassFileName);
  if (!mFileName.isEmpty() && QFile::exists(mFileName)) {
    mImage.load(mFileName);
  } else {
    mImage = ResourceCache::getImage(":/Resources/icons/bitmap-shape.svg");
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
  mExtents.parse(list.at(3));
  // 5th item is the fileName
  setFileName(StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(4))));
  // 6th item is the imageSource
  if (list.size() >= 6) {
    mImageSource = StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(5)));
  }
  if (!mImageSource.isEmpty()) {
    mImage.loadFromData(QByteArray::fromBase64(mImageSource.toLatin1()));
  } else if (!mFileName.isEmpty() && QFile::exists(mFileName)) {
    mImage.load(mFileName);
  } else {
    mImage = ResourceCache::getImage(":/Resources/icons/bitmap-shape.svg");
  }
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
  QImage image = mImage.scaled(rect.width(), rect.height(), Qt::KeepAspectRatio, Qt::SmoothTransformation);
  QPointF centerPoint = rect.center() - image.rect().center();
  QRectF target(centerPoint.x(), centerPoint.y(), image.width(), image.height());

  painter->drawImage(target, mImage.mirrored());
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
  annotationString.append(mExtents.toQString());
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
  if (mExtents.isDynamicSelectExpression() || mExtents.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtents.toQString()));
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
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  ShapeAnnotation::setDefaults(pShapeAnnotation);
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
