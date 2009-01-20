/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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
#include <QString>
#include <QFileDialog>
#include <QFile>
#include <QTextStream>
#include <QMessageBox>

//Std headers
#include <iostream>

//IAEX headers
#include "graphWindow.h"
#include "dataSelect.h"
#include "preferenceWindow.h"
#include "legendLabel.h"
#include "variablewindow.h"
using namespace std;

GraphWindow::GraphWindow(QWidget* parent): QMainWindow(parent)
{
  setupUi(this);

  compoundWidget = graphicsView;
  // starting listening servers
  connect(graphicsView->gwMain, SIGNAL(serverState(bool)), actionActive, SLOT(setChecked(bool)));
  connect(actionActive, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(enableServers(bool)));

  // QObject::connect(actionOpen, SIGNAL(activated()), this, SLOT(openFile()));

  connect(graphicsView->gwMain, SIGNAL(newMessage(QString)), this, SLOT(showMessage(QString)));
  QObject::connect(actionGrid, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(showGrid(bool)));
  QObject::connect(actionHold, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setHold(bool)));

  QObject::connect(actionPan, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setPan(bool)));
  QObject::connect(actionSelect, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setSelect(bool)));
  QObject::connect(actionZoom, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setZoom(bool)));

  connect(actionPreferences, SIGNAL(triggered()), compoundWidget, SLOT(showPreferences()));
  connect(actionSimulationData, SIGNAL(triggered()), this, SLOT(showSimulationData()));

  connect(actionImage, SIGNAL(activated()), this, SLOT(saveImage()));

  QActionGroup* ag = new QActionGroup(this);
  ag->addAction(actionPan);
  ag->addAction(actionSelect);
  ag->addAction(actionZoom);
  ag->addAction(actionHold);
  ag->setExclusive(true);

  connect(actionAboutQt, SIGNAL(triggered()), qApp, SLOT(aboutQt()));
}

GraphWindow::~GraphWindow()
{

}

void GraphWindow::showPreferences()
{
	PreferenceWindow* pw = new PreferenceWindow(compoundWidget, 0);
	pw->setAttribute(Qt::WA_DeleteOnClose);
	pw->show();
}

void GraphWindow::showSimulationData()
{
	VariableWindow* vw = new VariableWindow(compoundWidget->gwMain, 0);
	vw->setAttribute(Qt::WA_DeleteOnClose);
	vw->show();
}


void GraphWindow::showMessage(QString message)
{
	statusbar->showMessage(message);
}

void GraphWindow::sceneDestroyed()
{

}

void GraphWindow::saveImage()
{

	QString filename = QFileDialog::getSaveFileName(this, "Export image", "untitled", "Portable Network Graphics (*.png);;Windows Bitmap (*.bmp);;Joint Photographic Experts Group (*.jpg)");

	if(!filename.size())
		return;

	QImage i3(compoundWidget->rect().size(),  QImage::Format_RGB32);
	i3.fill(QColor(Qt::white).rgb());
	QPainter p(&i3);
	QRectF target = QRectF(compoundWidget->gwMain->rect());
	target.moveTo(compoundWidget->gwMain->pos());
	compoundWidget->gwMain->render(&p, target);

	p.drawRect(target);

	target = QRectF(compoundWidget->gvLeft->rect());
	target.moveTo(compoundWidget->gvLeft->pos());
	compoundWidget->gvLeft->render(&p, target);

	target = QRectF(compoundWidget->gvBottom->rect());
	target.moveTo(compoundWidget->gvBottom->pos());
	compoundWidget->gvBottom->render(&p, target);

	compoundWidget->yLabel->render(&p, compoundWidget->yLabel->pos());
	compoundWidget->xLabel->render(&p, compoundWidget->xLabel->pos());
	compoundWidget->plotTitle->render(&p, compoundWidget->plotTitle->pos());


	QList<LegendLabel*> l = compoundWidget->legendFrame->findChildren<LegendLabel*>();
	for(int i = 0; i < l.size(); ++i)
		l[i]->render(&p, l[i]->pos()+compoundWidget->legendFrame->pos());


	if(filename.endsWith("png"))
		i3.save(filename, "PNG");
	else if(filename.endsWith("bmp"))
		i3.save(filename, "BMP");
	else if(filename.endsWith("jpg") || filename.endsWith("jpeg"))
		i3.save(filename, "JPG");
	else
		i3.save(filename+".bmp", "BMP");
}
