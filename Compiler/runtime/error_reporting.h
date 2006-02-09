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
                                      "ERROR", \
                                      "error: %s, parsing continued at token '%s' on line %s", \
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
