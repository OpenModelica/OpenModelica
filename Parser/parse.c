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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <MetaModelica_Lexer.h>
#include <Modelica_3_Lexer.h>
#include <Modelica_2_Lexer.h>
#include <BaseModelica_Lexer.h>
#include <ModelicaParser.h>
#include "runtime/errorext.h"

const char* modelicafilename; // The filename for the parsed file.
bool modelicafileReadOnly; // True if file is read only.

#include <errno.h>

long unsigned int szMemoryUsed = 0;

void Parser_5finit(void)
{
}

void lexNoRecover(pANTLR3_LEXER lex)
{
  lex->rec->state->error = ANTLR3_TRUE;
  pANTLR3_INT_STREAM istream = lex->input->istream;
  while (*(char*)lex->input->nextChar)
    istream->consume(istream);
}

void noRecover(pANTLR3_BASE_RECOGNIZER recognizer)
{
  recognizer->state->error = ANTLR3_TRUE;
  recognizer->state->failed  = ANTLR3_TRUE;
}

static void* noRecoverFromMismatchedSet(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_BITSET_LIST follow)
{
  recognizer->state->error  = ANTLR3_TRUE;
  recognizer->state->failed  = ANTLR3_TRUE;
  return NULL;
}

static void* noRecoverFromMismatchedToken(pANTLR3_BASE_RECOGNIZER recognizer, ANTLR3_UINT32 ttype, pANTLR3_BITSET_LIST follow)
{
  pANTLR3_PARSER        parser;
  pANTLR3_TREE_PARSER        tparser;
  pANTLR3_INT_STREAM        is;
  void          * matchedSymbol;

  // Invoke the debugger event if there is a debugger listening to us
  //
  if  (recognizer->debugger != NULL)
  {
    recognizer->debugger->recognitionException(recognizer->debugger, recognizer->state->exception);
  }

  switch  (recognizer->type)
  {
  case  ANTLR3_TYPE_PARSER:

    parser  = (pANTLR3_PARSER) (recognizer->super);
    tparser  = NULL;
    is  = parser->tstream->istream;

    break;

  case  ANTLR3_TYPE_TREE_PARSER:

    tparser = (pANTLR3_TREE_PARSER) (recognizer->super);
    parser  = NULL;
    is  = tparser->ctnstream->tnstream->istream;

    break;

  default:

    ANTLR3_FPRINTF(stderr, "Base recognizer function recoverFromMismatchedToken called by unknown parser type - provide override for this function\n");
    return NULL;

    break;
  }

  // Create an exception if we need one
  //
  if  (recognizer->state->exception == NULL)
  {
    antlr3RecognitionExceptionNew(recognizer);
  }

  if  ( recognizer->mismatchIsUnwantedToken(recognizer, is, ttype) == ANTLR3_TRUE)
  {
    recognizer->state->exception->type    = ANTLR3_UNWANTED_TOKEN_EXCEPTION;
    recognizer->state->exception->message  = ANTLR3_UNWANTED_TOKEN_EXCEPTION_NAME;
    return NULL;
  }

  if  (recognizer->mismatchIsMissingToken(recognizer, is, follow))
  {
    matchedSymbol = recognizer->getMissingSymbol(recognizer, is, recognizer->state->exception, ttype, follow);
    recognizer->state->exception->type    = ANTLR3_MISSING_TOKEN_EXCEPTION;
    recognizer->state->exception->message  = ANTLR3_MISSING_TOKEN_EXCEPTION_NAME;
    recognizer->state->exception->token    = matchedSymbol;
    recognizer->state->exception->expecting  = ttype;
    return NULL;
  }

  // Neither deleting nor inserting tokens allows recovery
  // must just report the exception.
  //
  recognizer->state->error      = ANTLR3_TRUE;
  return NULL;
}

static void handleLexerError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_LEXER lexer;
  pANTLR3_EXCEPTION ex;
  pANTLR3_STRING ftext;

  lexer   = (pANTLR3_LEXER)(recognizer->super);
  
  ex    = lexer->rec->state->exception;

  const char* chars = lexer->input->substr(lexer->input, lexer->getCharIndex(lexer), lexer->getCharIndex(lexer)+20)->chars;
  int line = lexer->getLine(lexer);
  int offset = lexer->getCharPositionInLine(lexer)+1;
  c_add_source_message(2, "SYNTAX", "Error", "Lexer failed to recognize: %s", &chars, 1, line, offset, line, offset, false, ModelicaParser_filename_C);
}

/* Error handling based on antlr3baserecognizer.c */
void handleParseError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_PARSER      parser;
  pANTLR3_TREE_PARSER  tparser;
  pANTLR3_INT_STREAM  is;
  pANTLR3_STRING      ttext;
  pANTLR3_EXCEPTION      ex;
  pANTLR3_COMMON_TOKEN   theToken;
  pANTLR3_BASE_TREE      theBaseTree;
  pANTLR3_COMMON_TREE    theCommonTree;
  int type;
  const char *error_type = "TRANSLATION";
  const char *token_text[2] = {0,0};
  int offset, error_id = 0, line;
  recognizer->state->error = ANTLR3_TRUE;

  // Retrieve some info for easy reading.
  ex      =    recognizer->state->exception;
  ttext   =    NULL;

  switch  (recognizer->type)
  {
  case  ANTLR3_TYPE_PARSER:
    theToken = (pANTLR3_COMMON_TOKEN)(ex->token);
    
    if (theToken != NULL)
      ttext = theToken->getText(theToken);

    offset = ex->charPositionInLine+1;    

    if  (theToken != NULL && theToken->type == ANTLR3_TOKEN_EOF) {
      token_text[0] = "<EOF>";
    } else if (ttext != NULL) {
      token_text[0] = ttext->chars;
    } else {
      fprintf(stderr, "has index %d\n", theToken->type);
      token_text[0] = (const char*) tokenNames[theToken->index]; // "<no text for the token>";
    }
    token_text[1] = (const char*) ex->message;
    type = ex->type;
    break;

  default:

    ANTLR3_FPRINTF(stderr, "Base recognizer function displayRecognitionError called by unknown parser type - provide override for this function\n");
    return;
    break;
  }

  switch (type) {
  case ANTLR3_UNWANTED_TOKEN_EXCEPTION:
    token_text[0] = ex->expecting == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*) tokenNames[ex->expecting];
    c_add_source_message(2, "SYNTAX", "Error", "Unwanted token '%s'.", token_text, 1, ex->line, offset, ex->line, offset, false, ModelicaParser_filename_C);
    break;
  case ANTLR3_MISSING_TOKEN_EXCEPTION:
    token_text[0] = ex->expecting == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*) tokenNames[ex->expecting];
    c_add_source_message(2, "SYNTAX", "Error", "Missing token '%s'.", token_text, 1, ex->line, offset, ex->line, offset, false, ModelicaParser_filename_C);
    break;
  case ModelicaParserException:
    c_add_source_message(2, "SYNTAX", "Error", "%s.", token_text+1, 1, ex->line, offset, ex->line, offset, false, ModelicaParser_filename_C);
    break;
  default:
    c_add_source_message(2, "SYNTAX", "Error", "Parser error near: '%s'. ", token_text, 1, ex->line, offset, ex->line, offset, false, ModelicaParser_filename_C);
    break;
  }

}


void* parseFile(void* fileNameRML, int flags)
{
  const char* fileNameC = RML_STRINGDATA(fileNameRML);
  bool debug         = check_debug_flag("parsedebug");
  bool parsedump     = check_debug_flag("parsedump");
  bool parseonly     = check_debug_flag("parseonly");
  void* lxr = 0;
  // TODO: Add flags to the actual Parser.parse() call instead of here?
  if (accept_meta_modelica_grammar()) flags |= PARSE_META_MODELICA;
  
  if (debug) { fprintf(stderr, "Starting parsing of file: %s\n", fileNameC); }

  pANTLR3_UINT8               fName;
  pANTLR3_INPUT_STREAM        input;
  pANTLR3_LEXER               pLexer;
  pANTLR3_COMMON_TOKEN_STREAM tstream;
  pModelicaParser             psr;
  
  ModelicaParser_filename_C = fileNameC;
  ModelicaParser_filename_RML = fileNameRML;
  ModelicaParser_flags = flags;

  fName  = (pANTLR3_UINT8)fileNameC;
  input  = antlr3AsciiFileStreamNew(fName);
  if ( input == NULL ) { fprintf(stderr, "Unable to open file %s\n", fileNameC); exit(ANTLR3_ERR_NOMEM); }

  if (flags & PARSE_META_MODELICA) {
    lxr = MetaModelica_LexerNew(input);
    if (lxr == NULL ) { fprintf(stderr, "Unable to create the lexer due to malloc() failure1\n"); exit(ANTLR3_ERR_NOMEM); }
    pLexer = ((pMetaModelica_Lexer)lxr)->pLexer;
    pLexer->rec->displayRecognitionError = handleLexerError;
    pLexer->recover = lexNoRecover;
    tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(((pMetaModelica_Lexer)lxr)));
  } else {
    lxr = Modelica_3_LexerNew(input);
    if (lxr == NULL ) { fprintf(stderr, "Unable to create the lexer due to malloc() failure1\n"); exit(ANTLR3_ERR_NOMEM); }
    pLexer = ((pModelica_3_Lexer)lxr)->pLexer;
    pLexer->rec->displayRecognitionError = handleLexerError;
    pLexer->recover = lexNoRecover;
    tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(((pModelica_3_Lexer)lxr)));
  }
  
  if (tstream == NULL) { fprintf(stderr, "Out of memory trying to allocate token stream\n"); exit(ANTLR3_ERR_NOMEM); }
  tstream->channel = ANTLR3_TOKEN_DEFAULT_CHANNEL;
  tstream->discardOffChannel = ANTLR3_TRUE;
  tstream->discardOffChannelToks(tstream, ANTLR3_TRUE);

  // Finally, now that we have our lexer constructed, create the parser
  psr      = ModelicaParserNew(tstream);  // ModelicaParserNew is generated by ANTLR3

  if (tstream == NULL) { fprintf(stderr, "Out of memory trying to allocate parser\n"); exit(ANTLR3_ERR_NOMEM); }

  psr->pParser->rec->displayRecognitionError = handleParseError;
  psr->pParser->rec->recover = noRecover;
  psr->pParser->rec->recoverFromMismatchedToken = noRecoverFromMismatchedToken;
  // psr->pParser->rec->recoverFromMismatchedSet = noRecoverFromMismatchedSet;

  void* res;
  if (flags & PARSE_EXPRESSION)
    res = psr->interactive_stmt(psr);
  else
    res = psr->stored_definition(psr);

  if (pLexer->rec->state->error || psr->pParser->rec->state->error) // Some parts of the AST are NULL if errors are used...
    res = 0;
  psr->free(psr);
  psr = NULL;
  tstream->free(tstream);
  tstream = NULL;
  if (flags & PARSE_META_MODELICA) {
    ((pMetaModelica_Lexer)lxr)->free((pMetaModelica_Lexer)lxr);
  } else {
    ((pModelica_3_Lexer)lxr)->free((pModelica_3_Lexer)lxr);
  }
  lxr = NULL;
  input->close(input);
  input = NULL;

  return res;
}

RML_BEGIN_LABEL(Parser__parse)
{
  rmlA0 = parseFile(rmlA0,PARSE_MODELICA);
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Parser__parseexp)
{
  rmlA0 = parseFile(rmlA0,PARSE_EXPRESSION);
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);
}
RML_END_LABEL

/*
char *get_string(std::ostringstream& s)
{
  char *buf=0;
  unsigned int size=0;
  string str = s.str();
  if (str.length() >= size)
  {
    size = (unsigned int)2*str.length();
    if (buf)
      delete [] buf;
    buf = new char[size];
  }
  strcpy(buf,str.c_str());
  return buf;
}
*/

RML_BEGIN_LABEL(Parser__parsestring)
{
#if 0
  std::ostringstream stringStream;

  char* str = RML_STRINGDATA(rmlA0);
  bool a0set=false;
  bool a1set=false;
  bool debug = check_debug_flag("parsedump");
  std::istringstream stream(str);
  modelicafileReadOnly = false;
  modelica_lexer lex(stream);
  modelica_parser parse(lex);

  /* 2004-10-05 adrpo moved this declaration here to
  * have the ast initialized before getting
  * into the code. This way, if this relation fails at least the
  * ast is initialized */
  void* ast = mk_nil();

  /* adrpo added 2004-10-27
  * I use this to delete [] the temp allocation of get_string(...)
  */
  char* getStringHolder = NULL;

  try
  {
    ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );

    parse.initializeASTFactory(my_factory);
    parse.setASTFactory(&my_factory);

    parse.stored_definition();

    RefMyAST t = RefMyAST(parse.getAST());


    if (t)
    {
      if (debug)
      {
        parse_tree_dumper dumper(std::cerr);
        //dumper.initializeASTFactory(factory);
        //dumper.setASTFactory(&factory);
        dumper.dump(t);
      }

      modelica_tree_parser build;
      build.initializeASTFactory(my_factory);
      build.setASTFactory(&my_factory);
      ast = build.stored_definition(t);

      if (debug) { std::cerr << "Build done\n"; }

      rmlA0 = ast ? ast : mk_nil(); a0set=true;
      rmlA1 = mk_scon("Ok"); a1set=true;

      RML_TAILCALLK(rmlSC);
    }
    else
    {
      rmlA0 = mk_nil(); a0set=true;
      rmlA1 = mk_scon("Internal error: parse tree null"); a1set=true;
      RML_TAILCALLK(rmlSC);
    }
  }
  catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e)
  {
    stringStream << "[" <<
    e.getLine() << ":" << e.getColumn() << "]: error: "
    << e.getMessage() << std::endl;
    //    std::cerr << stringStream.str().c_str();
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
  }
  catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e)
  {
    //    std::cerr << "Lexical error (CharStreamException). "  << std::endl;
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon("[-,-]: internal error: lexical error"); a1set=true;
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e)
  {
    stringStream << "[" << lex.getLine() << ":" << lex.getColumn()
      << "]: error: illegal token" << std::endl;
    //    std::cerr << stringStream.str().c_str();
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
  }
  catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e)
  {
    //    std::cerr << "ANTLRException: " << e.getMessage() << std::endl;
    stringStream << "[-,-]: internal error: " << e.getMessage() << std::endl;
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
  }
  catch (std::exception &e)
  {
    //    std::cerr << "Error while parsing: " << e.what() << "\n";
    stringStream << "[-,-]: internal error: " << e.what() << std::endl;
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream))); a1set=true;
  }
  catch (...)
  {
    //    std::cerr << "Error while parsing\n";
    rmlA0 = mk_nil(); a0set=true;
    rmlA1 = mk_scon("[-,-]: internal error"); a1set=true;
  }

  /* adrpo added 2004-10-27
  * no need for getStringHolder temp value allocated from get_string
  */
  if (getStringHolder) delete [] getStringHolder;

  if (! a0set)
  {
    rmlA0 = mk_nil(); a0set=true;
  }
  if (! a1set)
  {
    rmlA1 = mk_scon("internal error"); a1set=true;
  }
  RML_TAILCALLK(rmlSC);
#endif
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL


RML_BEGIN_LABEL(Parser__parsestringexp)
{
#if 0
  char* str = RML_STRINGDATA(rmlA0);
  std::ostringstream stringStream;
  bool debug = check_debug_flag("parsedump");
  /* 2004-10-05 adrpo moved this declaration here to
  * have the ast initialized before getting
  * into the code. This way, if this relation fails at least the
  * ast is initialized */
  void* ast = mk_nil();


  /* adrpo added 2004-10-27
  * I use this to delete [] the temp allocation of get_string(...)
  */
  char* getStringHolder = NULL;


  try
  {
    std::istringstream stream(str);
    modelicafileReadOnly = false;
    modelica_lexer lex(stream);
    modelica_expression_parser parse(lex);
    ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
    parse.initializeASTFactory(factory);
    parse.setASTFactory(&factory);
    parse.interactiveStmts();
    RefMyAST t = RefMyAST(parse.getAST());

    if (t)
    {
      if (debug)
      {
        std::cerr << "parsedump not implemented for interactiveStmt yet"<<endl;
        //parse_tree_dumper dumper(std::cerr);
        //dumper.dump(t);
      }

      modelica_tree_parser build;
      build.initializeASTFactory(factory);
      build.setASTFactory(&factory);
      ast = build.interactive_stmt(t);

      if (debug)
      {
        std::cerr << "Build done\n";
      }

      rmlA0 = ast ? ast : mk_nil();
      rmlA1 = mk_scon("Ok");

      RML_TAILCALLK(rmlSC);
    }
    else
    {
      rmlA0 = mk_nil();
      rmlA1 = mk_scon("parse tree null");
    }
  }
  catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e)
  {
    //std::cerr << "Error while parsing expression:\n" << e.getMessage() << "\n";
    stringStream << "[-,-]: internal error: " << e.getMessage() << std::endl;
    rmlA0 = mk_nil();
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
  }
  catch (std::exception &e)
  {
    //std::cerr << "Error while parsing expression:\n" << e.what() << "\n";
    stringStream << "[-,-]: internal error: " << e.what() << std::endl;
    rmlA0 = mk_nil();
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
  }
  catch (...)
    {
    //std::cerr << "Error while parsing expression\n";
    stringStream << "Error while parsing expression. Unknown exception in parse.cpp." << std::endl;
    rmlA0 = mk_nil();
    rmlA1 = mk_scon((getStringHolder = get_string(stringStream)));
  }

  /* adrpo added 2004-10-27
  * no need for getStringHolder temp value allocated from get_string
  */
  if (getStringHolder) delete [] getStringHolder;

  RML_TAILCALLK(rmlSC);
#endif
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL
