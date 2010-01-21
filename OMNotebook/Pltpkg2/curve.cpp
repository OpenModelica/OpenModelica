/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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
#include <QColor>

//IAEX headers
#include "curve.h"
#include "point.h"
#include "legendLabel.h"
#include "line2D.h"


Curve::Curve(VariableData* x_, VariableData* y_, QColor& color, LegendLabel* ll):
x(x_), y(y_), label(ll)
{
	line = new QGraphicsItemGroup;
  setColor(color);
}

Curve::~Curve()
{
	delete line;
	delete label;

//	foreach(Point* p, dataPoints)
//			delete p;
	dataPoints.clear();
}


void Curve::showPoints(bool b)
{
	foreach(Point* p, dataPoints)
		p->setVisible(b);

	drawPoints = b;
}

void Curve::showLine(bool b)
{
	line->setVisible(b);
	line->update();
	visible = b;
}

void Curve::setColor(QColor c)
{
	color_ = c;
	QPen p(c);
  p.setWidthF(PLOT_LINE_WIDTH);
  p.setCosmetic(true);
	QList<QGraphicsItem*> l = line->children();

	for(int i = 0; i < l.size(); ++i)
		static_cast<Line2D*>(l[i])->setPen(p);

	for(int i = 0; i < dataPoints.size(); ++i)
	{
		dataPoints[i]->color = c;
		dataPoints[i]->setPen(QPen(c));
	}
}
