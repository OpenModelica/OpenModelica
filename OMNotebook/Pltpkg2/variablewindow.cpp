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

