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

#ifndef LEGENDLABEL_H
#define LEGENDLABEL_H

//Qt headers
#include <QLabel>
#include <QString>
#include <QColor>
#include <QMenu>
#include <QPainter>
#include <QAction>
#include <QMessageBox>

//IAEX headers
#include "curve.h"
#include "point.h"

using namespace std;

class LegendLabel: public QLabel
{
	Q_OBJECT

public:
	LegendLabel(QColor color_, QString s, QWidget* parent, bool showline, bool showpoints, int maxHeight);
	~LegendLabel();

	void setCurve(Curve* c)
	{
		curve = c;
	}

signals:
	void showLine(bool);
	void showPoints(bool);

public slots:
	void setLineVisible(bool b);
	void setPointsVisible(bool b);
	void selectColor();
	void deleteCurve();

protected:
	void paintEvent ( QPaintEvent * event );

	void resizeEvent ( QResizeEvent * event )
	{
		setIndent(height() +2);
	}

//	void showEvent(QShowEvent*);
public:
	void render(QPainter* painter, QPointF pos = QPointF());
	GraphWidget* graphWidget;

private:
	QColor color;
	QMenu *menu;
	Curve* curve;
	bool state;

};

#endif

