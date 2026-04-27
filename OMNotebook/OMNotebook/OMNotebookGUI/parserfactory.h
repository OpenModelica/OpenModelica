/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef _PARSER_FACTORY_H
#define _PARSER_FACTORY_H

#include <QtCore/QString>

#include "nbparser.h"
#include "factory.h"
#include "document.h"

namespace IAEX
{
   /*! \interface ParserFactory
    *
    * \brief Describes the interface for parser factories.
    *
    * A parser factory is responsible for creating the correct parser
    * for a given file.
    */
   class ParserFactory
   {
   public:
      virtual ~ParserFactory() = default;
      virtual NBParser *createParser(QString filename, Factory *f, Document *document, int readmode) = 0;
   };

   class CellParserFactory : public ParserFactory
   {
   public:
      CellParserFactory();
      virtual ~CellParserFactory();

      NBParser *createParser(QString filename, Factory *f, Document *document, int readmode);
   };
};

#endif
