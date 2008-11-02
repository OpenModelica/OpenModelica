/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
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
  QGraphicsEllipseItem(x1, y1, h, w, parent, scene), graphwidget(graphwidget_)
{

  color = color_;
  graphwidget = graphwidget_;
  xPos = x1;
  yPos = y1;
  hgt = h;
  wdt = w;
  dx = dy = 0;

  setAcceptsHoverEvents(true);
  QPen qp;
  qp.setColor(color);
  setPen(qp);

  if(label.size())
    setToolTip(label);
  else
    setToolTip(graphwidget->currentXVar + QString(": ") + QVariant(x1).toString() + QString("\n") +
	       graphwidget->currentYVar +QString(": ") + QVariant(y1).toString());



  //	setFlag(QGraphicsItem::ItemIgnoresTransformations);

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

