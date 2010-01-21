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
 */

#ifndef __ERROR_REPORTING_H__
#define __ERROR_REPORTING_H__

#include <sstream>

// x05andre, Andreas Remar, 2006-02-02
// The following are helper macros for panic mode error recovery

// This macro is inserted before synchronizing with the FOLLOW set
#define BEFORE_SYNC if(std::string(e.getMessage()) == std::string("unexpected end of file")) \
                      throw ANTLR_USE_NAMESPACE(antlr)RecognitionException("unexpected end of file", \
                                                                           modelicafilename, \
                                                                           LT(1)->getLine(), \
                                                                           LT(1)->getColumn());	\
                    std::list<std::string> tokens; \
                    int errorLine = LT(1)->getLine(); \
                    int errorColumn = LT(1)->getColumn(); \
                    tokens.push_back(std::string(e.getMessage()))

// This macro is inserted after synchronizing with the FOLLOW set
#define AFTER_SYNC tokens.push_back(std::string(LT(1)->getText())); \
                   std::stringstream ss; \
                   ss << LT(1)->getLine() << ", column " << LT(1)->getColumn(); \
                   tokens.push_back(std::string(ss.str())); \
                   add_source_message(2, \
                                      "SYNTAX", \
                                      "Error", \
                                      "%s, parsing resumed at token '%s' on line %s", \
                                      tokens, \
                                      errorLine, \
                                      errorColumn, \
                                      LT(1)->getLine(), \
                                      LT(1)->getColumn(), \
                                      false, \
                                      (char *)modelicafilename.c_str());

// Access the global string modelicafilename found in Compiler/absyn_builder/parse.cpp
extern std::string modelicafilename;

#endif
