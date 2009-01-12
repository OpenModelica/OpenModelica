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

//IAEX headers
#include "compoundWidget.h"
#include "preferenceWindow.h"

CompoundWidget::CompoundWidget(QWidget* parent):  QWidget(parent)
{
//	this->resize(672, 784);
//	this->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));
	plotWidget = new QWidget(this);
	plotWidget->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));
//	plotWidget->setMinimumHeight(784);
//	plotWidget->setMinimumWidth(672);

	setupUi(this);

	QFont f("Arial",10);
	f.setBold(true);
	plotTitle->setFont(f); 
	gwMain->gvBottom = gvBottom;
	gwMain->gvLeft = gvLeft;



	gvBottom->setScene(gwMain->graphicsScene->xRulerScene);
	gvLeft->setScene(gwMain->graphicsScene->yRulerScene);
	gvBottom->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvBottom->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvLeft->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvLeft->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);	

	connect(gwMain, SIGNAL(resizeY(quint32)), this, SLOT(resizeY(quint32)));
	connect(gwMain, SIGNAL(showPreferences2()), this, SLOT(showPreferences()));

	layout = new QVBoxLayout;
	legendFrame->setLayout(layout);

//	legendFrame->setMinimumWidth(50);

	gwMain->legendLayout = layout;
	gwMain->legendFrame = legendFrame;

	gwMain->compoundwidget = this;

  //Initialize SoQT
  //#ifndef __APPLE_CC__  
	// SoQt::init(this);
  //#endif
	visWidget = new IAEX::VisualizationWidget(this);
	// connect(visWidget, SIGNAL(resizeY(quint32)), this, SLOT(graphicsResizeY(quint32)));
	visWidget->hide();
	
}

CompoundWidget::~CompoundWidget()
{

	delete gwMain;
	delete gvLeft;
	delete gvBottom;
	delete xLabel;
	delete yLabel;
	delete plotTitle;
	delete layout;
  delete visWidget;
}

void CompoundWidget::showPreferences()
{
	PreferenceWindow* pw = new PreferenceWindow(this, 0);
	pw->setAttribute(Qt::WA_DeleteOnClose);
	pw->show();
}

void CompoundWidget::resizeY(quint32 w)
{
	gvLeft->setMinimumWidth(w+5);
	gvLeft->update();
}

void CompoundWidget::graphicsResizeY(quint32 w)
{
	visWidget->setMinimumWidth(w+5);
	visWidget->update();
}


void CompoundWidget::showVis() {
	visWidget->show();
  gwMain->showGrid(false);
  gvLeft->hide();
  gvBottom->hide();
  plotTitle->hide();
	plotWidget->hide();
	xLabel->hide();
	yLabel->hide();
  legendFrame->hide();
}

void CompoundWidget::hideVis() {
	visWidget->hide();
	plotWidget->show();
  gwMain->showGrid(true);
  gvLeft->show();
  gvBottom->show();
  plotTitle->show();
	xLabel->show();
	yLabel->show();
  legendFrame->show();
}
