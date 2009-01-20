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
 * \file removehighlightervisitor.h
 * \author Anders Fernström
 */

#ifndef REMOVEHIGHLIGHTERVISITOR_H
#define REMOVEHIGHLIGHTERVISITOR_H

//IAEX Headers
#include "visitor.h"
#include "document.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "highlighterthread.h"
#include "graphcell.h"

using namespace std;
namespace IAEX
{
	class RemoveHighlighterVisitor : public Visitor
	{

	public:
		RemoveHighlighterVisitor(){}
		virtual ~RemoveHighlighterVisitor(){}

		virtual void visitCellNodeBefore(Cell *node){}
		virtual void visitCellNodeAfter(Cell *node){}

		virtual void visitCellGroupNodeBefore(CellGroup *node){}
		virtual void visitCellGroupNodeAfter(CellGroup *node){}

		virtual void visitTextCellNodeBefore(TextCell *node){}
		virtual void visitTextCellNodeAfter(TextCell *node){}

		virtual void visitInputCellNodeBefore(InputCell *node)
		{
			HighlighterThread *thread = HighlighterThread::instance();
			thread->removeEditor( node->textEdit() );
		}
		virtual void visitInputCellNodeAfter(InputCell *node){}

		virtual void visitGraphCellNodeBefore(GraphCell *node)
		{
			HighlighterThread *thread = HighlighterThread::instance();
			thread->removeEditor( node->textEdit() );
		}
		virtual void visitGraphCellNodeAfter(GraphCell *node){}


		virtual void visitCellCursorNodeBefore(CellCursor *cursor){}
		virtual void visitCellCursorNodeAfter(CellCursor *cursor){}
	};
}
#endif
