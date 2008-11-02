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

