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

//IAEX headers
#include "compoundWidget.h"
#include "preferenceWindow.h"

CompoundWidget::CompoundWidget(QWidget* parent):  QWidget(parent)
{
//	this->resize(672, 784);
//	this->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));
//  plotWidget = new QWidget(this);
//  plotWidget->setSizePolicy(QSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed));
//  plotWidget->resize(400, 300);
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
  gwMain->hide();  
  gvLeft->hide();
  gvBottom->hide();
  plotTitle->hide();
	// plotWidget->hide();
	xLabel->hide();
	yLabel->hide();
  legendFrame->hide();
}

void CompoundWidget::hideVis() {
	visWidget->hide();
	// plotWidget->show();
  gwMain->showGrid(true);
  gwMain->show();
  gvLeft->show();
  gvBottom->show();
  plotTitle->show();
	xLabel->show();
	yLabel->show();
  legendFrame->show();
}
