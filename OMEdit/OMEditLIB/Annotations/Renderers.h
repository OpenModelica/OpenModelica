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

#ifndef RENDERERS_H
#define RENDERERS_H

#include <qimage.h>
#include <qsvgrenderer.h>
#include <qpalette.h>

/*!
 * \brief Defines the interface for an image rendering utility.
 */
class Renderer
{
public:
  /*!
   * \brief Renders an image on a given painter object.
   *
   * The implementation should render the image it has access to on a QPainter object,
   * within given rectangular bounds. An optional mirroring feature (vertical flip)
   * is controlled by the mirrored flag.
   */
  virtual void render(QPainter *painter, const QRectF& rect, bool mirrored) = 0;
  /**
   * \brief Provides a bitmap version of the image.
   *
   * The implementation should create a bitmap version of the image it has access to
   * and return it.
   */
  virtual QImage getImage() = 0;
};

/*!
 * \brief Renderer for bitmap (PNG, JPG, BMP etc) images.
 */
class BitmapRenderer: public Renderer
{
public:
  BitmapRenderer(QImage&& image);
  BitmapRenderer(const QByteArray& bytes);
  void render(QPainter *painter, const QRectF& rect, bool mirrored) override;
  QImage getImage() override;
private:
  QImage mImage;
};

/*!
 * \brief Renderer for SVG images.
 */
class SvgRenderer: public Renderer
{
public:
  SvgRenderer(const QByteArray& bytes);
  void render(QPainter *painter, const QRectF& rect, bool mirrored) override;
  QImage getImage() override;
private:
  QSvgRenderer mSvg;
  QPalette mPalette;
};
#endif // RENDERERS_H
