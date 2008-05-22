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
	deleteLater();
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
