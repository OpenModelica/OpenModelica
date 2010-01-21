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


#ifndef FOCUSRECT_H
#define FOCUSRECT_H

#include <QGraphicsRectItem>
#include <QBrush>
#include "graphWidget.h"
#include <QMessageBox>

class FocusRect: public QGraphicsRectItem
{

public:
	FocusRect(const QRectF& rect,  GraphWidget* w): QGraphicsRectItem(rect), widget(w)
	{
		setAcceptsHoverEvents(true);
		setZValue(-2);
	}

	~FocusRect()
	{
	}

	void hoverEnterEvent ( QGraphicsSceneHoverEvent * event )
	{
		QColor c(0, 255, 0, 50);
		QBrush b(c);
		setBrush(b);
	}

	void hoverLeaveEvent ( QGraphicsSceneHoverEvent * event )
	{
		QColor c(255, 0, 0, 50);
		QBrush b(c);
		setBrush(b);
	}

	void mousePressEvent ( QGraphicsSceneMouseEvent * event )
	{


		widget->zoomIn(rect());
		widget->updatePointSizes(QRect(-1,0,0,0));
	}

	 GraphWidget* widget;



};

#endif
