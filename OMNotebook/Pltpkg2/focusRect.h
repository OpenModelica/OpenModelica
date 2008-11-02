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
