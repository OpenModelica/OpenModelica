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

/*! \file visitor.h
 * \author Ingemar Axelsson (and Anders Fernström)
 */
#ifndef VISITOR_H
#define VISITOR_H

//using namespace std;

namespace IAEX{

   class Cell;
   class CellGroup;
   class TextCell;
   class CellText;
   class InputCell;
   class ImageCell;
   class CellCursor;
   class GraphCell;

   /*! \interface Visitor
    * \author Ingemar Axelsson (and Anders Ferström)
	* \date 2005-11-30 (update)
    *
    * When a new celltype is added to the cellhierarchy a new visitor
    * member function must be added also. This means that it is expensive
    * to add new celltypes.
    *
	* 2005-11-30 AF, Removed support for imagecells
    */
   class Visitor 
   {
   public:
      virtual void visitCellNodeBefore(Cell *node) = 0;
      virtual void visitCellNodeAfter(Cell *node) = 0;

      virtual void visitCellGroupNodeBefore(CellGroup *node) = 0;
      virtual void visitCellGroupNodeAfter(CellGroup *node) = 0;

      virtual void visitTextCellNodeBefore(TextCell *node) = 0;
      virtual void visitTextCellNodeAfter(TextCell *node) = 0;

      virtual void visitInputCellNodeBefore(InputCell *node) = 0;
      virtual void visitInputCellNodeAfter(InputCell *node) = 0;

	  virtual void visitGraphCellNodeBefore(GraphCell *node) = 0;
      virtual void visitGraphCellNodeAfter(GraphCell *node) = 0;

      virtual void visitCellCursorNodeBefore(CellCursor *cursor) = 0;
      virtual void visitCellCursorNodeAfter(CellCursor *cursor) = 0;
   };
}
#endif
