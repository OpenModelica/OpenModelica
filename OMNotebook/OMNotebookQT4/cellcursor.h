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

/*!
 * \file cellcursor.h
 * \author Ingemar Axelsson (and Anders Fenström)
 *
 * \brief Implementation of a marker made as an Cell.
 */

#ifndef _CELLCURSOR_H
#define _CELLCURSOR_H


//IAEX Headers
#include "cell.h"

// forward declaration
class QPaintEvent;

namespace IAEX
{
	class CellCursor : public Cell
	{
		Q_OBJECT

	public:
		CellCursor(QWidget *parent=0);
		virtual ~CellCursor();

		//Insertion
		void addBefore(Cell *newCell);
		void deleteCurrentCell();
		void removeCurrentCell();
		void replaceCurrentWith(Cell *newCell);

		Cell *currentCell();

		//Movment
		bool moveUp();									// Changed 2006-08-24 AF
		bool moveDown();								// Changed 2006-08-24 AF

		void moveToFirstChild(Cell *parent);
		void moveToLastChild(Cell *parent);
		void moveBefore(Cell *current);
		void moveAfter(Cell *current);

		virtual void accept(Visitor &v);
		virtual QString text(){return QString::null;}

		//Flag
		bool isEditable();								// Added 2005-10-28 AF
		bool isClickedOn();								// Added 2006-04-27 AF

	public slots:
		virtual void setFocus(const bool){}

	signals:
		void changedPosition();
		void positionChanged(int x, int y, int xm, int ym);

	protected:
		void mousePressEvent(QMouseEvent *event);		// Added 2006-04-27 AF

	private:
		void cursorIsMoved();							// Added 2006-04-27 AF
		void removeFromCurrentPosition();

	private:
		bool clickedOn_;

	};


	class CursorWidget : public QWidget
	{
	public:
		CursorWidget(QWidget *parent=0)
			:QWidget(parent){}
			virtual ~CursorWidget(){}

	protected:
		void paintEvent(QPaintEvent *event);
	};
}
#endif
