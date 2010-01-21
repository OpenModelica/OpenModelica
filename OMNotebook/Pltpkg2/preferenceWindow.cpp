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

//IAEX headers
#include "preferenceWindow.h"
#include "compoundWidget.h"

PreferenceWindow::PreferenceWindow(CompoundWidget* cw, QWidget *parent): QDialog(parent)
{
	compoundWidget =cw;

	setupUi(this);

	vMin->setText(QVariant(compoundWidget->gwMain->currentArea().top()).toString());
	vMax->setText(QVariant(compoundWidget->gwMain->currentArea().bottom()).toString());
	hMin->setText(QVariant(compoundWidget->gwMain->currentArea().left()).toString());
	hMax->setText(QVariant(compoundWidget->gwMain->currentArea().right()).toString());

	hMajorSize->setText(QVariant(compoundWidget->gwMain->xMajorDist).toString());
	hMinorSize->setText(QVariant(compoundWidget->gwMain->xMinorDist).toString());

	vMajorSize->setText(QVariant(compoundWidget->gwMain->yMajorDist).toString());
	vMinorSize->setText(QVariant(compoundWidget->gwMain->yMinorDist).toString());

	hAutoGrid->setChecked(!compoundWidget->gwMain->fixedXSize);
	vAutoGrid->setChecked(!compoundWidget->gwMain->fixedYSize);

	showGrid->setChecked(compoundWidget->gwMain->gridVisible);
	showLegend->setChecked(compoundWidget->legendFrame->isVisible());
	plotTitle->setText(compoundWidget->plotTitle->text());
	vLabel->setText(compoundWidget->yLabel->text());
	hLabel->setText(compoundWidget->xLabel->text());

	hLog->setChecked(compoundWidget->gwMain->xLog);
	vLog->setChecked(compoundWidget->gwMain->yLog);

	connect(pbOk, SIGNAL(clicked()), this, SLOT(apply()));
	connect(pbApply, SIGNAL(clicked()), this, SLOT(apply()));
	connect(this, SIGNAL(setGrid(bool)), compoundWidget->gwMain, SLOT(showGrid(bool)));
	connect(this, SIGNAL(setLogarithmic(bool)), compoundWidget->gwMain, SLOT(setLogarithmic(bool)));
}

PreferenceWindow::~PreferenceWindow()
{

}

void PreferenceWindow::apply()
{
	QRectF area = compoundWidget->gwMain->currentArea();

	double left, right, top, bottom;
	left = area.left();
	right = area.right();
	top = area.top();
	bottom = area.bottom();

	if(vMin->isEnabled())
	{

		top = QVariant(vMin->text()).toDouble();
		bottom = QVariant(vMax->text()).toDouble();
	}

	if(hMin->isEnabled())
	{
		left = QVariant(hMin->text()).toDouble();
		right = QVariant(hMax->text()).toDouble();
	}

	QRectF newArea(left, top, right-left, bottom-top);

	if(newArea != compoundWidget->gwMain->currentArea())
		compoundWidget->gwMain->setArea(newArea);

	compoundWidget->gwMain->fixedXSize = !hAutoGrid->isChecked();
	compoundWidget->gwMain->fixedYSize = !vAutoGrid->isChecked();

	if(!hAutoGrid->isChecked())
	{
		compoundWidget->gwMain->xMajorDist = QVariant(hMajorSize->text()).toDouble();
		compoundWidget->gwMain->xMinorDist = QVariant(hMinorSize->text()).toDouble();
	}

	if(!vAutoGrid->isChecked())
	{
		compoundWidget->gwMain->yMajorDist = QVariant(vMajorSize->text()).toDouble();
		compoundWidget->gwMain->yMinorDist = QVariant(vMinorSize->text()).toDouble();
	}

	compoundWidget->plotTitle->setText(plotTitle->text());
	compoundWidget->yLabel->setText(vLabel->text());
	compoundWidget->xLabel->setText(hLabel->text());

	if(vLog->isChecked() != compoundWidget->gwMain->yLog || hLog->isChecked() != compoundWidget->gwMain->xLog)
	{
		compoundWidget->gwMain->yLog = vLog->isChecked();
		compoundWidget->gwMain->xLog = hLog->isChecked();
		emit setLogarithmic(true);
	}

	emit setGrid(showGrid->isChecked());

	compoundWidget->legendFrame->setVisible(showLegend->isChecked());
	compoundWidget->gwMain->graphicsScene->update(compoundWidget->gwMain->currentArea());
	compoundWidget->gwMain->update();
}

