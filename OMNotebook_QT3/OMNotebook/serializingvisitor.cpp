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

#include <iostream>
#include "serializingvisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "imagecell.h"

namespace IAEX
{
   /*! \class SerializingVisitor
    *
    * \brief Saves a celltree to an xml file.
    *
    * Converts a cell structure to XML.
    */
   SerializingVisitor::SerializingVisitor(QDomElement &element, QDomDocument &doc)
      : currentElement_(element), doc_(doc)
   {
   }

   SerializingVisitor::~SerializingVisitor()
   {
      
   }
   
   /*! \brief writes cell contents to a file.
    */
   void SerializingVisitor::visitCellNodeBefore(Cell *node)
   {
      cerr << "visitCellNode is not implemented" << endl;
   }

   void SerializingVisitor::visitCellNodeAfter(Cell *node)
   {
   }
   
   /*! 
    */
   void SerializingVisitor::visitCellGroupNodeBefore(CellGroup *node)
   {
      //qDebug("Visitin a cellgroup");
      parents_.push(currentElement_);
      QDomElement ce = doc_.createElement("CellGroupData");
      currentElement_.appendChild(ce);

      ce.setAttribute("closed", node->isClosed());

      currentElement_ = ce;
   }
   
   /*! \bug Does not set the parent correctly.
    */
   void SerializingVisitor::visitCellGroupNodeAfter(CellGroup *node)
   {
      currentElement_ = parents_.top();
      parents_.pop();
   }
   
   void SerializingVisitor::visitTextCellNodeBefore(TextCell *node)
   {
      //qDebug("Visitin a textcell");
      QDomElement textcell = doc_.createElement("Cell");
      QDomText t = doc_.createTextNode(node->text());
      
      textcell.setAttribute("style", node->style());
      textcell.appendChild(t);
      
      Cell::rules_t r = node->rules();
      Cell::rules_t::const_iterator i = r.begin();
      for(;i!=r.end();++i)
      {
	 textcell.setAttribute((*i)->attribute(), (*i)->value());
      }
      
      currentElement_.appendChild(textcell);
   }

   void SerializingVisitor::visitTextCellNodeAfter(TextCell *node)
   {
   }
   
   void SerializingVisitor::visitInputCellNodeBefore(InputCell *node)
   {
      //qDebug("Visitin a inputcell");
      QDomElement textcell = doc_.createElement("Cell");
      
      QDomText t = doc_.createTextNode(node->text());
      textcell.setAttribute("style", "Input");
      textcell.appendChild(t);

      currentElement_.appendChild(textcell);
   }

   void SerializingVisitor::visitInputCellNodeAfter(InputCell *node)
   {

   }

   void SerializingVisitor::visitImageCellNodeBefore(ImageCell *node)
   {
      QDomElement imgCell = doc_.createElement("Cell");
      imgCell.setAttribute("style", "Image");
      imgCell.setAttribute("filename", node->filename());
   
      currentElement_.appendChild(imgCell);
   }

   void SerializingVisitor::visitImageCellNodeAfter(ImageCell *node)
   {

   }


   void SerializingVisitor::visitCellCursorNodeBefore(CellCursor *cursor)
   {
      //qDebug("Visitin a cellcursor");      
   }      

   void SerializingVisitor::visitCellCursorNodeAfter(CellCursor *cursor)
   {

   }
} 
