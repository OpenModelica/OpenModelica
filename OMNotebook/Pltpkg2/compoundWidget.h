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

#ifndef COMPOSITEWIDGET_H
#define COMPOSITEWIDGET_H

//Qt headers
#include <QWidget>
#include <QGraphicsView>
#include <QMessageBox>

//IAEX headers
#include "ui_compoundWidget.h"
#include "graphWidget.h"
#include "../3Dpkg/VisualizationWidget.h"

using namespace std;

class CompoundWidget: public QWidget, public Ui::CompoundWidget
{
	Q_OBJECT

public:
	CompoundWidget(QWidget* parent = 0);
	~CompoundWidget();
	void showVis();
	void hideVis();

public slots:
	void resizeY(quint32 w);
	void showPreferences();
  void graphicsResizeY(quint32 w);

public:
	QVBoxLayout* layout;
	IAEX::VisualizationWidget* visWidget;
	// QWidget* plotWidget;
};


#endif

