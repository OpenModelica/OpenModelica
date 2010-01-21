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
#include <QColorDialog>

//IAEX headers
#include "legendLabel.h"
#include "curve.h"

LegendLabel::LegendLabel(QColor color_, QString s, QWidget* parent, bool showline, bool showpoints, int maxHeight): QLabel(s, parent), color(color_)
{
	curve = 0;
	state = true;
	setContextMenuPolicy(Qt::ActionsContextMenu);
	QAction* tmp;
	tmp =  new QAction(QString("Show line"), this);
	tmp->setCheckable(true);
	tmp->setChecked(showline);
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setLineVisible(bool)));
	connect(this, SIGNAL(showLine(bool)), tmp, SLOT(setChecked(bool)));
	addAction(tmp);

	tmp = new QAction("Show data points", this);
	tmp->setCheckable(true);
	tmp->setChecked(showpoints);
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setPointsVisible(bool)));
	connect(this, SIGNAL(showPoints(bool)), tmp, SLOT(setChecked(bool)));
	addAction(tmp);

	tmp = new QAction("Change color...", this);
	connect(tmp, SIGNAL(triggered()), this, SLOT(selectColor()));
	addAction(tmp);
	tmp = new QAction(this);
	tmp->setSeparator(true);
	addAction(tmp);
	tmp = new QAction("Delete", this);
	connect(tmp, SIGNAL(triggered()), this, SLOT(deleteCurve()));
	addAction(tmp);


	setMaximumHeight(maxHeight);

	setMinimumWidth((fontMetrics().width(text())+height()+4));




}

LegendLabel::~LegendLabel()
{

}

void LegendLabel::deleteCurve()
{

	int t = graphWidget->curves.indexOf(curve);
	if(t != -1)
		graphWidget->curves.removeAt(t);
	qDeleteAll(curve->dataPoints);

	delete curve;
//	delete menu;
	// deleteLater();
}


void LegendLabel::selectColor()
{
	QColor c = QColorDialog::getColor(color);
	if(c.isValid())
	{
		color = c;
		curve->setColor(color);
	}
}

void LegendLabel::setLineVisible(bool b)
{
	curve->showLine(b);


	curve->dataPoints[0]->scene()->update();
	emit showLine(b);
}

void LegendLabel::setPointsVisible(bool b)
{


	curve->showPoints(b);
	if(b)
		graphWidget->updatePointSizes();

	curve->dataPoints[0]->scene()->update();
	emit showPoints(b);
}
/*
void LegendLabel::showEvent(QShowEvent* event)
{

	QLabel::showEvent(event);

	graphWidget->originalZoom();
}
*/

void LegendLabel::paintEvent ( QPaintEvent * event )
{
	QPainter painter(this);

	render(&painter);

//	graphWidget->originalZoom();
}

void LegendLabel::render(QPainter* painter, QPointF pos)
{
	painter->save();
	painter->translate(pos.x(), pos.y());

	painter->setPen(Qt::black);
	QBrush b;
	if(state)
		b = QBrush(color);

	painter->setBrush(b);
	painter->setRenderHints(QPainter::Antialiasing);
	painter->drawEllipse(1, 1, max(0,height()-2), max(0,height()-2));

	painter->setFont(font());
//	setMinimumWidth(fontMetrics().width(text())+height()+4);
	//setMinimumWidth(50);
	QRectF r = rect();
	r.setLeft(r.left() + height()+2);
	painter->drawText(r, Qt::AlignVCenter, text());

	painter->restore();
}
