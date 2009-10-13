/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
