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
 * \file cellgroup.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 */

#ifndef CELLGROUP_H
#define CELLGROUP_H

//STD Headers
#include <vector>
#include <list>

//QT Headers
#include <QtGui/QWidget>
#include <QtGui/QLayout>
//Added by qt3to4:
#include <QtGui/QMouseEvent>
#include <QtGui/QGridLayout>

//IAEX Headers
#include "cell.h"
#include "visitor.h"

using namespace std;
using namespace IAEX;

namespace IAEX{

	class CellGroup : public Cell
	{
		Q_OBJECT

	public:
		CellGroup(QWidget *parent=0);
		virtual ~CellGroup();

		virtual void viewExpression(const bool){};

		//Traversals implementation
		virtual void accept(Visitor &v);

		//Datastructure implementation.
		virtual void addChild(Cell *newCell);
		virtual void removeChild(Cell *aCell);

		virtual void addCellWidget(Cell *newCell);
		virtual void addCellWidgets();
		virtual void removeCellWidgets();

		int height();
		CellStyle *style();								// Changed 2005-10-28
		virtual QString text(){return QString::null;}

		void closeChildCells();							// Added 2005-11-30 AF

		//Flag
		bool isClosed() const;
		bool isEditable();								// Added 2005-10-28 AF

		QTextEdit* textEdit();							// Added 2006-08-24 AF


	public slots:
		virtual void setStyle( CellStyle style );		// Changed 2005-10-28 AF
		void setClosed(const bool closed, bool update = true);
		virtual void setFocus(const bool focus);

	protected:
		void mouseDoubleClickEvent(QMouseEvent *event);

	protected slots:
		void adjustHeight();

	private:
		bool closed_;

		QWidget *main_;
		QGridLayout *layout_;
		unsigned long newIndex_;
	};
}
#endif
