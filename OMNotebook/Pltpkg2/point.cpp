/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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

//Qt headers
#include <QPen>
#include <QGraphicsItem>
#include <QVariant>

//Std headers
#include <iostream>

//IAEX headers
#include "point.h"
#include "graphWidget.h"

using namespace std;

Point::Point(qreal x1, qreal y1,qreal h, qreal w, QColor color_, const GraphWidget* graphwidget_,
	     QGraphicsItem* parent, QGraphicsScene* scene, const QString& label):
  /*label_(label),*/QGraphicsEllipseItem(x1, y1, h, w, parent, scene), graphwidget(graphwidget_)
{
  color = color_;
  graphwidget = graphwidget_;
  xPos = x1;
  yPos = y1;
  hgt = h;
  wdt = w;
  dx = dy = 0;

  /* adrpo: TODO! FIXME! WRONG! 
   *        to have such a huge string for EACH point is an OVERKILL!
   *        for example plotting all pendulum variables gets and Out of Memory error
   * This class is not even needed as its only purpose is to display tooltips with time/value
   * we can do that by intercepting hover events in Curve and displaying text directly!!!
   */
  if(label.size())
    setToolTip(label);
  else
    setToolTip(graphwidget->currentXVar + QString(": ") + QVariant(xPos).toString() + QString("\n") +
	       graphwidget->currentYVar +QString(": ") + QVariant(yPos).toString());

  setAcceptsHoverEvents(true);
  QPen qp;
  qp.setColor(color);
  setPen(qp);
}

Point::~Point()
{

}

void Point::updateSize()
{
	double xScale = graphwidget->matrix().m11()/125;
	double yScale = graphwidget->matrix().m22()/195;

	double width=150 / xScale;
	double height = -200 / yScale;

	scale(1/xScale, 1/yScale);
}

void Point::move(double x, double y)
{
	moveBy(-dx +x, -dy +y);
	dx = x;
	dy = y;
}

void Point::hoverEnterEvent ( QGraphicsSceneHoverEvent * event )
{
	QPen qp;

#if QT_VERSION >= 0x400300
	QBrush b(color.darker());
#else
	QBrush b(color);
#endif
	setBrush(b);
}
void Point::hoverLeaveEvent ( QGraphicsSceneHoverEvent * event )
{
	QBrush b(Qt::NoBrush);
	setBrush(b);

	QPen qp;
	qp.setColor(color);
	setPen(qp);
}

void Point::mousePressEvent ( QGraphicsSceneMouseEvent * event )
{
}

