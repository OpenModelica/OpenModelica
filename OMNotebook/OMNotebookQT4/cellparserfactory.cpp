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

#include <exception>
#include <stdexcept>

#include "parserfactory.h"
#include "xmlparser.h"
#include "notebookparser.h"


namespace IAEX
{

   /*! \class CellParserFactory
    * \brief Nows how to open xml and nb files.
    *
    * This factory class knows how to open different fileformats. If a
    * new fileformat should be added the code for parsing the new format.
    *
	* Do not forget to delete a parser when it is not used anymore.
	*
	*
    * \todo Check for whitespaces in filename. Whitespaces at the end
    * of a file should be taken care of in some way.(Ingemar Axelsson)
    *
    */
   CellParserFactory::CellParserFactory(){}
   CellParserFactory::~CellParserFactory(){}

   NBParser *CellParserFactory::createParser(QString filename, Factory *f, Document *document, int readmode)
   {
      // PORT >>filename = filename.stripWhiteSpace();
	  QString fileName = filename.trimmed();


	  if( fileName.endsWith(".onb", Qt::CaseInsensitive) ||
		  fileName.endsWith(".xml", Qt::CaseInsensitive) ||
		  fileName.endsWith(".onbz", Qt::CaseInsensitive))
      {
		 return new XMLParser(fileName, f, document, readmode);//openXMLFile(filename);
      }
      else if(fileName.endsWith(".nb", Qt::CaseInsensitive))
      {
		 return new NotebookParser(fileName, f, readmode); //openNotebookFile(filename);
      }
      else
      {
		 throw runtime_error("Can only open files ending with .onb or .nb,\n(can open old OMNotebooks file that ends with .xml)");
      }
   }
};
