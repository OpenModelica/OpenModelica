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

#include "Renderers.h"

#include <qpainter.h>

BitmapRenderer::BitmapRenderer(QImage &&image) : mImage(std::move(image))
{
}

BitmapRenderer::BitmapRenderer(const QByteArray &bytes) : mImage(QImage::fromData(bytes))
{
}

void BitmapRenderer::render(QPainter *painter, const QRectF &rect, bool mirrored)
{
  // This has been copied from a previous version of the code.
  // TODO: The bitmap rescaling that takes place here is a rather bad idea. This method is
  // called frequently and MULTIPLE times by the repainting framework and it better be fast.
  // Rescaling arbitrary size images may not be that fast, so lots of CPU time may be part of a
  // blocking call here in case of large and graphics-rich models.
  // Ideally:
  // - the `image` should be constructed once, and recomputed only when the rect changes
  // (e.g. during model editing).
  // - this methos should only perfotm bound computation and painter->drawXYZ calls
  const QImage image = mImage.scaled(rect.width(), rect.height(), Qt::KeepAspectRatio, Qt::SmoothTransformation);
  const QPointF centerPoint = rect.center() - image.rect().center();
  const QRectF target(centerPoint.x(), centerPoint.y(), image.width(), image.height());
  if (mirrored) {
    painter->drawImage(target, mImage.mirrored());
  } else {
    painter->drawImage(target, mImage);
  }
}

QImage BitmapRenderer::getImage()
{
  return mImage;
}

SvgRenderer::SvgRenderer(const QByteArray &bytes) : mSvg(bytes), mPalette()
{
}

void SvgRenderer::render(QPainter *painter, const QRectF &rect, bool mirrored)
{
  const QSizeF src_size = mSvg.viewBoxF().size();
  // I guess anything that is sub-pixel would do here.
  const double epsilon = 0.1;

  if (std::abs(rect.height()) > epsilon && std::abs(rect.width()) > epsilon) {
    const QSizeF new_size = src_size.scaled(rect.width(), rect.height(), Qt::KeepAspectRatio);
    const QSizeF offset = 0.5 * (rect.size() - new_size);
    const QRectF target(rect.x() + offset.width(), rect.y() + offset.height(), new_size.width(), new_size.height());

    QRectF paintTarget = target;
    // Note: we flip top/bottom coordinates and translate to have the "mirrored" effect, and be
    // consistent with how the bitmap image types are rendered, given their coordinate conventions.
    if (mirrored) {
      paintTarget = QRectF(target.bottomLeft(), target.topRight());
      // It was not obvious initially, that this extra step was needed for the render to be at the
      // right location.
      paintTarget.moveCenter(QPointF(target.center().x(), target.center().y() - target.height()));
    }

    mSvg.render(painter, paintTarget);
  }
}

QImage SvgRenderer::getImage()
{
  const QSize size = mSvg.viewBox().size();
  QImage img(size, QImage::Format_RGB32);
  QPainter painter(&img);
  const QRectF rect(0, 0, size.width(), size.height());
  painter.fillRect(rect, mPalette.background());
  render(&painter, rect, false);
  return img;
}
