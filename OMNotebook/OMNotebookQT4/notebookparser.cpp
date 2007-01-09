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

#include <iostream>
#include <fstream>
#include <exception>
#include <stdexcept>
//#include <cstdlib>
//#include <algorithm>


//ANTLR Headers
#include "AntlrNotebookLexer.hpp"
#include "AntlrNotebookParser.hpp" 
#include "AntlrNotebookTreeParser.hpp"

//IAEX Headers
#include "notebookparser.h"

using namespace std;

namespace IAEX
{

   /*! \class NotebookParser 
    *
    * \brief Used to open a notebookfile. 
    *
    * Opens a notebookfile. Note that the parser used to parse
    * Mathematica notebooks is not completley correct. There are a lot
    * of notebooktags that are ignored. Some big things that is not
    * implemented is section counter and hyperlinks. Hyperlinks will
    * maybe be implemented later. For hyperlinks to work a new browser
    * must be implemented supporting opening of new documents. This is
    * not implemented at the time of writing.
    *
    * Those Cell styles that is not implemented could in most cases be
    * implemented using the stylesheet. \see \ref stylesheet.xml for
    * more information about changing a cells style.
    *
    * Here is a list of things that are implemented:
    *
    * \li Comments (**).
    * \li Cell[].
    * \li CellGroupData[].
    * \li List[].
    * \li StyleBox[] - does not care about newlines.
    * \li SuperscriptBox[].
    * \li rule[].
    * \li Some cellstyles, Text, Title, Section, Input, Author.
    * 
    * Rules implemented:
    * \li FontSlant
    * \li FontWeight
    * \li TextAlignment
    * \li FontSize
    * 
    * Below is some tags and rules that is not implemented. Note that
    * this is just a subset of all tags not implemented. It is far
    * from complete.
    *
    * \li Cellstyles, output.
    * \li Section counter.
    * \li Hard newlines.
    * \li swedish charachters (åäö).
    * \li subscript[] - will be implemented later.
    * \li FormBox - ignored.
    * \li RowBox - ignored.
    * \li TextData - displayed as ordinary text.
    * \li BoxData - ignored.
    * \li ButtonBox - ignored, should implement links.
    * \li FileName[] - ignored.
    * \li RuleDelayed - interpreted as Rule.
    *
    * Some rules not implemented
    * \li InitializationCell
    * \li RGBColor
    * \li CharacterEncoding
    * \li ButtonStyle
    * \li ButtonData
    * \li FontColor
    * \li TextJustification
    *
    *
    * \param filename is the name of the file to be opened. 
    *
    * \throws runtime_error if the notebook can not be opened.
    */
   NotebookParser::NotebookParser(const QString filename, Factory *f, int readmode)
      : filename_(filename), factory_(f), readmode_(readmode) {}

   NotebookParser::~NotebookParser(){}
   
   /*!
    * This method just calls the antlr generated parser. To change the
    * parser look at lexer.g, parser.g and walker.g instead.
    */
   Cell *NotebookParser::parse()
   {
	   std::ifstream anotebook( filename_.toStdString().c_str() );

      if(!anotebook)
      {
	 anotebook.close();
	 throw runtime_error("Could not open " + filename_.toStdString());
      }
      
      Cell *workspace = factory_->createCell("cellgroup", 0);
      
      antlr::ASTFactory myFactory;
      AntlrNotebookLexer lexer(anotebook);
      AntlrNotebookParser parser(lexer);
      
      parser.initializeASTFactory(myFactory);
      parser.setASTFactory(&myFactory);
      parser.document();
      antlr::RefAST t = parser.getAST();
      
      AntlrNotebookTreeParser *walker = new AntlrNotebookTreeParser();
            
      walker->document(t, workspace, factory_); //, readmode_);
      anotebook.close();
      
      return workspace;
   }
}
