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
