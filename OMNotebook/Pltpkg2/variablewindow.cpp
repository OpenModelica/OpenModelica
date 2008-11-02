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
#include <QMessageBox>
#include <QRectF>
#include <QVariant>
#include <QList>
#include <QColorDialog>

//IAEX headers
#include "variablewindow.h"
#include "graphWidget.h"
#include "variableData.h"
#include "curve.h"
#include "legendLabel.h"
using namespace std;

VariableWindow::VariableWindow(GraphWidget* gw, QWidget *parent): QDialog(parent)
{
	graphWidget =gw;

	setupUi(this) ;
	connect(pbCreate, SIGNAL(clicked()), this, SLOT(createCurve()));
	connect(pbColor, SIGNAL(clicked()), this, SLOT(selectColor()));
	connect(pbRemove, SIGNAL(clicked()), this, SLOT(removeCurve()));

	updateViews();
}



VariableWindow::~VariableWindow()
{

}

void VariableWindow::updateViews()
{
	QTreeWidgetItem* item;
	twVariables->clear();
	cbx->clear();
	cby->clear();
	for(map<QString, VariableData*>::iterator i = graphWidget->variables.begin(); i != graphWidget->variables.end(); ++i)
	{
		item = new QTreeWidgetItem();
		item->setText(0, i->first);
		item->setText(1, QVariant(i->second->count()).toString());

		cbx->addItem(i->first);
		cby->addItem(i->first);
		twVariables->insertTopLevelItem(0,item);
	}

	twPlotted->clear();
	for(QList<Curve*>::iterator i = graphWidget->curves.begin(); i != graphWidget->curves.end(); ++i)
	{

		if(!(*i))
			continue;
		item = new QTreeWidgetItem();

		item->setText(0, (*i)->x->variableName());
		item->setText(1, (*i)->y->variableName());
		twPlotted->insertTopLevelItem(0, item);

	}


}

void VariableWindow::selectColor()
{
//	QColorDialog d(this);


	QColor c = QColorDialog::getColor(lColor->palette().button().color());

	lColor->setPalette(QPalette(c));
}

void VariableWindow::createCurve()
{

	QColor color = lColor->palette().button().color();
	LegendLabel *l = new LegendLabel(color,cby->currentText(),graphWidget->legendFrame, true, true, 12);
	graphWidget->legendFrame->setMinimumWidth(max(l->fontMetrics().width(l->text())+41+4, graphWidget->legendFrame->minimumWidth()));
	l->graphWidget = graphWidget;


	Curve* c = new Curve(graphWidget->variables[cbx->currentText()],graphWidget->variables[cby->currentText()],color, l);
	l->setCurve(c);

	if(rbLinear->isChecked())
		c->interpolation = INTERPOLATION_LINEAR;
	else if(rbConstant->isChecked())
		c->interpolation = INTERPOLATION_CONSTANT;
	else
		c->interpolation= INTERPOLATION_NONE;
	c->drawPoints = cbPoints->isChecked();

	graphWidget->legendLayout->addWidget(l);
	graphWidget->curves.push_back(c);
//	graphWidget->showGraphics();
	graphWidget->setLogarithmic(true);
	emit showGraphics();
	graphWidget->resetZoom();
	//	graphWidget->
	updateViews();
}

void VariableWindow::removeCurve()
{

	if(!twPlotted->currentItem())
		return;
	QString x = twPlotted->currentItem()->text(0);
	QString y = twPlotted->currentItem()->text(1);

	for(int i = 0; i < graphWidget->curves.size(); ++i)
	{
		if(graphWidget->curves[i]->x->variableName() == x && graphWidget->curves[i]->y->variableName() == y)
		{
			Curve* c = graphWidget->curves.takeAt(i);
			delete c;
			break;

		}
	}
			updateViews();


}

