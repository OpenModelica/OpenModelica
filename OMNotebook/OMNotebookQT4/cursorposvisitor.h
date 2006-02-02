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
 * \file cursorposvisitor.h
 * \author Anders Fernström
 */

#ifndef CURSORPOSVISITOR_H
#define CURSORPOSVISITOR_H

//IAEX Headers
#include "visitor.h"
#include "document.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"


using namespace std;

namespace IAEX
{
	class CursorPosVisitor : public Visitor 
	{

	public:
		CursorPosVisitor()
			: count_(true), closed_(false), position_(0)
		{}
		virtual ~CursorPosVisitor(){}
		virtual int position(){ return position_; }

		virtual void visitCellNodeBefore(Cell *node){}
		virtual void visitCellNodeAfter(Cell *node){}

		virtual void visitCellGroupNodeBefore(CellGroup *node)
		{
			if( count_ )
				if( node->isClosed() )
					closed_ = true;
		}
		virtual void visitCellGroupNodeAfter(CellGroup *node)
		{
			if( count_ )
			{
				if( closed_ )
				{
					position_ += node->height();
					closed_ = false;
				}
			}
		}

		virtual void visitTextCellNodeBefore(TextCell *node){}
		virtual void visitTextCellNodeAfter(TextCell *node)
		{
			if( count_ && !closed_ )
				position_ += node->height(); 
		}

		virtual void visitInputCellNodeBefore(InputCell *node){}
		virtual void visitInputCellNodeAfter(InputCell *node)
		{
			if( count_ && !closed_ )
				position_ += node->height(); 
		}

		virtual void visitCellCursorNodeBefore(CellCursor *cursor){}      
		virtual void visitCellCursorNodeAfter(CellCursor *cursor)
		{
			if( count_ && !closed_ )
				position_ += cursor->height(); 

			count_ = false;
		}

	private:
		bool count_;
		bool closed_;
		int position_;
	};
}
#endif
