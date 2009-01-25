/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

#ifndef POINT_H
#define POINT_H

//Qt headers
#include <QGraphicsPathItem>
#include <QGraphicsEllipseItem>

//IAEX headers
#include "graphWidget.h"

using namespace std;

class Point: public QGraphicsEllipseItem
{
 public:
  Point(qreal x1, qreal y1, qreal h, qreal w, QColor color_, const GraphWidget* graphwidget_=0,
	QGraphicsItem* parent=0, QGraphicsScene* scene=0, const QString& label = "");
  ~Point();
  double xFactor, yFactor;
  double xPos, yPos, hgt, wdt;
  void move(double, double);
  void updateSize();
  //QString toolTip () const;

 protected:
  virtual void hoverEnterEvent ( QGraphicsSceneHoverEvent * event );
  virtual void hoverLeaveEvent ( QGraphicsSceneHoverEvent * event );
  virtual void mousePressEvent ( QGraphicsSceneMouseEvent * event );

 public:
  QColor color;
 private:
  const GraphWidget* graphwidget;
  double dx, dy;
  //const QString& label_;
};

#endif

