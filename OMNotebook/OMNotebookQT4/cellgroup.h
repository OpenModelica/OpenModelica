/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
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
		CellStyle style();								// Changed 2005-10-28
		virtual QString text(){return QString::null;}

		void closeChildCells();							// Added 2005-11-30 AF

		//Flag
		bool isClosed() const;
		bool isEditable();								// Added 2005-10-28 AF


	public slots:	
		virtual void setStyle( CellStyle style );		// Changed 2005-10-28 AF
		void setClosed(const bool closed);
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
