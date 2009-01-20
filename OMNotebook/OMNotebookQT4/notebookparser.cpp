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

      walker->document(t, workspace, factory_, readmode_);
      anotebook.close();

      return workspace;
   }
}
