/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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
 * \file chaptercountervisitor.cpp
 * \author Anders Fernström
 */

//STD Headers
#include <exception>

//IAEX Headers
#include "chaptercountervisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "graphcell.h"


namespace IAEX
{
	/*! 
	 * \class ChapterCounterVisitor
	 * \date 2006-03-02
	 *
	 * \brief Update the chapter counters in the document
	 */

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class constructor
	 */
	ChapterCounterVisitor::ChapterCounterVisitor()
	{
		for( int i = 0; i < COUNTERS; ++i )
			counters_[i] = 0;
	}

	/*! 
	 * \author Anders Fernström
	 *
	 * \brief The class deconstructor
	 */
	ChapterCounterVisitor::~ChapterCounterVisitor()
	{}

	// CELL
	void ChapterCounterVisitor::visitCellNodeBefore(Cell *)
	{}

	void ChapterCounterVisitor::visitCellNodeAfter(Cell *)
	{}

	// GROUPCELL
	void ChapterCounterVisitor::visitCellGroupNodeBefore(CellGroup *node)
	{}

	void ChapterCounterVisitor::visitCellGroupNodeAfter(CellGroup *)
	{}

	// TEXTCELL
	void ChapterCounterVisitor::visitTextCellNodeBefore(TextCell *node)
	{
		int level = node->style()->chapterLevel();
		if( level > 0 && level <= COUNTERS )
		{
			// Add on chapter couner
			counters_[ level - 1 ]++;

			QString counter;
			QString number;
			for( int i = 0; i < level; ++i )
			{
				number.setNum( counters_[i] );

				if( !counter.isEmpty() )
					counter += ".";

				counter += number;
			}

			// reset all counters avter counter[level]
			for( int i = level; i < COUNTERS; ++i )
				counters_[i] = 0;

			node->setChapterCounter( counter );
		}
		else
		{
			// clear chapter counter
			node->setChapterCounter( "" );
		}
	}

	void ChapterCounterVisitor::visitTextCellNodeAfter(TextCell *)
	{}

	//INPUTCELL
	void ChapterCounterVisitor::visitInputCellNodeBefore(InputCell *node)
	{
		int level = node->style()->chapterLevel();
		if( level > 0 && level <= COUNTERS )
		{
			// Add on chapter couner
			counters_[ level - 1 ]++;

			QString counter;
			QString number;
			for( int i = 0; i < level; ++i )
			{
				number.setNum( counters_[i] );

				if( !counter.isEmpty() )
					counter += ".";

				counter += number;
			}

			// reset all counters avter counter[level]
			for( int i = level; i < COUNTERS; ++i )
				counters_[i] = 0;

			node->setChapterCounter( counter );
		}
		else
		{
			// clear chapter counter
			node->setChapterCounter( "" );
		}
	}

	void ChapterCounterVisitor::visitInputCellNodeAfter(InputCell *)
	{}


	//GRAPHCELL

	void ChapterCounterVisitor::visitGraphCellNodeBefore(GraphCell *node)
	{
		int level = node->style()->chapterLevel();
		if( level > 0 && level <= COUNTERS )
		{
			// Add on chapter couner
			counters_[ level - 1 ]++;

			QString counter;
			QString number;
			for( int i = 0; i < level; ++i )
			{
				number.setNum( counters_[i] );

				if( !counter.isEmpty() )
					counter += ".";

				counter += number;
			}

			// reset all counters avter counter[level]
			for( int i = level; i < COUNTERS; ++i )
				counters_[i] = 0;

			node->setChapterCounter( counter );
		}
		else
		{
			// clear chapter counter
			node->setChapterCounter( "" );
		}
	}

	void ChapterCounterVisitor::visitGraphCellNodeAfter(GraphCell *)
	{}
	//CELLCURSOR
	void ChapterCounterVisitor::visitCellCursorNodeBefore(CellCursor *)
	{}      

	void ChapterCounterVisitor::visitCellCursorNodeAfter(CellCursor *)
	{}
} 
