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

#ifndef VARIABLEWINDOW_H
#define VARIABLEWINDOW_H

//Qt headers
#include <QtGui/QDialog>
#include "ui_newgraph.h"

//IAEX headers
#include "graphWidget.h"

class VariableWindow: public QDialog, public Ui::NewGraph
{
	Q_OBJECT
public:
	VariableWindow(GraphWidget* gw, QWidget* parent = 0);

	~VariableWindow();

public slots:
	void createCurve();
	void selectColor();
	void updateViews();
	void removeCurve();

signals:
	void showGraphics();
	//	void setLegend(bool visible);
//	void setGrid(bool visible);
//	void setLogarithmic(bool);

private:
	GraphWidget* graphWidget;

};

#endif

