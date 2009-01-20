/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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

#include <iostream>
#include "treeview.h"

#include <QtGui/QPolygon>
//Added by qt3to4:
#include <QtGui/QPaintEvent>
#include <QRectF>
#include <QMessageBox>
namespace IAEX
{

   /*! \brief Construct a TreeView object and initialize it.
    * \author Ingemar Axelsson
    *
    * For parameter information, see the Qt manual.
    */
   TreeView::TreeView(QWidget *parent)
      :QWidget(parent),
       selected_(false),
       closed_(false),
       //selectedColor_(QColor(0,0,255))
	   selectedColor_(QColor(160,160,160))
   {
      setFixedWidth(10);
      setSizePolicy(QSizePolicy(QSizePolicy::Fixed, QSizePolicy::Expanding));

	  // PORT >> setBackgroundMode(Qt::PaletteBase);
	  setBackgroundRole( QPalette::Base );
   }

   /*! \brief Set the background color of the treeview.
    * \author Ingemar Axelsson
    *
    * Sets the backgroundcolor of this view. This should never be set to
    * black due to the color of the treething.
    *
    * \todo Add functionality to change the treecolor. Also add
    * functionality to retrieve the current colors.(Ingemar Axelsson)
    *
    * \param col background color for the treeview.
    */
   void TreeView::setBackgroundColor(const QColor col)
   {
      backgroundColor_ = col;
   }

   void TreeView::setSelected(const bool sel)
   {
      selected_ = sel;
      repaint();
   }

   /*!
    * \deprecated
    */
   const bool TreeView::selected() const
   {
      return selected_;
   }

   void TreeView::setClosed(const bool closed)
   {
      closed_ = closed;
      repaint();
   }

   const bool TreeView::isClosed() const
   {
      return closed_;
   }

   QColor TreeView::selectedColor() const
   {
      return selectedColor_;
   }

   QColor TreeView::backgroundColor() const
   {
      return backgroundColor_;
   }

	/*! \brief Describes what a TreeView widget will look like.
	 *
	 * \bug Some cells are closed even if they cant be closed. This must
	 * be fixed in some way.
	 */
	void TreeView::paintEvent(QPaintEvent *event)
	{
		QPainter painter(this);

		if(selected_)
		{
			painter.setPen( QPen( QBrush( selectedColor() ), 10 ));
			painter.drawRect( this->rect() );

			painter.setPen(QPen( QBrush( QColor(160,0,0) ), 1, Qt::SolidLine));
		}
		else
		{
			painter.setPen( QPen( QBrush( backgroundColor() ), 10 ));

			painter.drawRect( this->rect() );

			painter.setPen(QPen(Qt::black,1, Qt::SolidLine));
		}

		QPolygon points(4);

		if(closed_)
		{
			points[0] = QPoint(1,2);
			points[1] = QPoint(5,2);
			points[2] = QPoint(5, height()-2);
			points[3] = QPoint(1, height()-8);
		}
		else
		{
			points[0] = QPoint(1,2);
			points[1] = QPoint(5,2);
			points[2] = QPoint(5,height()-2);
			points[3] = QPoint(1,height()-2);
		}

		painter.drawPolyline(points);

		QWidget::paintEvent(event);
	}

//////////////////////////////////////////////////////////////////////

   /*! \class InputTreeView
    *
    * \brief A treeview for inputcells. This view acts a little
    * different than other treeviews. Mostly different paintEvent.
    */
   InputTreeView::InputTreeView(QWidget *parent)
      : TreeView(parent)
   {}

	void InputTreeView::paintEvent(QPaintEvent *event)
	{
		QPainter painter(this);

		//Selected or not selected
		if(selected())
		{
			painter.setPen( QPen( QBrush( selectedColor() ), 10 ));
			painter.drawRect( this->rect() );

			painter.setPen(QPen( QBrush( QColor(160,0,0) ), 1, Qt::SolidLine));

			painter.drawRect(this->rect().x()-1, this->rect().y(), this->rect().width()-1, this->rect().height()-2);
			painter.setPen(QPen(Qt::black,1, Qt::SolidLine));

		}
		else
		{
			painter.setPen( QPen( QBrush( backgroundColor() ), 10 ));




			painter.drawRect( this->rect() );

//			painter.setPen(QPen(Qt::black,1, Qt::SolidLine));
//			painter.drawRect(this->rect().x()-1, this->rect().y(), this->rect().width()-1, this->rect().height()-2);
			painter.setPen(QPen(Qt::black,1, Qt::SolidLine));
		}

		if(isVisible())
		{
			QPolygon points(4);

			points[0] = QPoint(1,2);
			points[1] = QPoint(5,2);
			points[2] = QPoint(5,height()-2);
			points[3] = QPoint(1,height()-2);

			painter.drawPolyline(points);

			QWidget::paintEvent(event);
		}
	}
}
