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
#include <ModelicaLexer.h>
#include <ModelicaParser.h>
#include "runtime/errorext.h"

const char* modelicafilename; // The filename for the parsed file.
bool modelicafileReadOnly; // True if file is read only.

int check_debug_flag(char const* strdata);

#include <errno.h>

long unsigned int szMemoryUsed = 0;


void Parser_5finit(void)
{
}

void lexNoRecover(pANTLR3_LEXER lex)
{
  lex->rec->state->error = ANTLR3_TRUE;
  pANTLR3_INT_STREAM istream = lex->input->istream;
  istream->seek(istream, istream->size(istream)-1);
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
	pANTLR3_PARSER			  parser;
	pANTLR3_TREE_PARSER	      tparser;
	pANTLR3_INT_STREAM	      is;
	void					* matchedSymbol;

	// Invoke the debugger event if there is a debugger listening to us
	//
	if	(recognizer->debugger != NULL)
	{
		recognizer->debugger->recognitionException(recognizer->debugger, recognizer->state->exception);
	}

	switch	(recognizer->type)
	{
	case	ANTLR3_TYPE_PARSER:

		parser  = (pANTLR3_PARSER) (recognizer->super);
		tparser	= NULL;
		is	= parser->tstream->istream;

		break;

	case	ANTLR3_TYPE_TREE_PARSER:

		tparser = (pANTLR3_TREE_PARSER) (recognizer->super);
		parser	= NULL;
		is	= tparser->ctnstream->tnstream->istream;

		break;

	default:

		ANTLR3_FPRINTF(stderr, "Base recognizer function recoverFromMismatchedToken called by unknown parser type - provide override for this function\n");
		return NULL;

		break;
	}

	// Create an exception if we need one
	//
	if	(recognizer->state->exception == NULL)
	{
		antlr3RecognitionExceptionNew(recognizer);
	}

	// If the next token after the one we are looking at in the input stream
	// is what we are looking for then we remove the one we have discovered
	// from the stream by consuming it, then consume this next one along too as
	// if nothing had happened.
	//
	if	( recognizer->mismatchIsUnwantedToken(recognizer, is, ttype) == ANTLR3_TRUE)
	{
		recognizer->state->exception->type		= ANTLR3_UNWANTED_TOKEN_EXCEPTION;
		recognizer->state->exception->message	= ANTLR3_UNWANTED_TOKEN_EXCEPTION_NAME;
	}

	// Single token deletion (Unwanted above) did not work
	// so we see if we can insert a token instead by calculating which
	// token would be missing
	//
	if	(recognizer->mismatchIsMissingToken(recognizer, is, follow))
	{
		matchedSymbol = recognizer->getMissingSymbol(recognizer, is, recognizer->state->exception, ttype, follow);
		recognizer->state->exception->type		= ANTLR3_MISSING_TOKEN_EXCEPTION;
		recognizer->state->exception->message	= ANTLR3_MISSING_TOKEN_EXCEPTION_NAME;
		recognizer->state->exception->token		= matchedSymbol;
		recognizer->state->exception->expecting	= ttype;
	}


	// Neither deleting nor inserting tokens allows recovery
	// must just report the exception.
	//
	recognizer->state->error	    = ANTLR3_TRUE;
	return NULL;
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
  const char *filename = 0;
  const char *error_type = "TRANSLATION";
  const char *token_text[2] = {0,0};
  int offset, error_id = 0, line;
  recognizer->state->error = ANTLR3_TRUE;

  // Retrieve some info for easy reading.
  //
  ex      =    recognizer->state->exception;
  ttext   =    NULL;

  // See if there is a 'filename' we can use
  //
  if  (ex->streamName == NULL)
  {
    if  (((pANTLR3_COMMON_TOKEN)(ex->token))->type == ANTLR3_TOKEN_EOF)
    {
      filename = "-end of input-(";
    }
    else
    {
      filename = "-unknown source-(";
    }
  }
  else
  {
    filename = ex->streamName->to8(ex->streamName)->chars;
  }

  // How we determine the next piece is dependent on which thing raised the
  // error.
  //
  switch  (recognizer->type)
  {
  case  ANTLR3_TYPE_PARSER:

    // Prepare the knowledge we know we have
    //
    parser      = (pANTLR3_PARSER) (recognizer->super);
    tparser      = NULL;
    is      = parser->tstream->istream;
    theToken    = (pANTLR3_COMMON_TOKEN)(ex->token);
    ttext      = theToken->getText(theToken);

    offset = ex->charPositionInLine;
    error_id = 2;
    

    if  (theToken != NULL && theToken->type == ANTLR3_TOKEN_EOF) {
      token_text[0] = "<EOF>";
    } else if (ttext != NULL) {
      token_text[0] = ttext->chars;
    } else {
      token_text[0] = "<no text for the token>";
    }
    token_text[1] = (const char*) ex->message;
    break;

  default:

    ANTLR3_FPRINTF(stderr, "Base recognizer function displayRecognitionError called by unknown parser type - provide override for this function\n");
    return;
    break;
  }

  c_add_source_message(2, "SYNTAX", "Error", "%s near: '%s'. ", token_text, 2, ex->line, offset, ex->line, offset, false, filename);
}


void* parseFile(char* fileName)
{
  pANTLR3_UINT8               fName;
  pANTLR3_INPUT_STREAM        input;
  pModelicaLexer              lxr;
  pANTLR3_COMMON_TOKEN_STREAM tstream;
  pModelicaParser             psr;
  
  // fprintf(stderr, "Parsing %s\n", fileName); fflush(stderr);

  fName  = (pANTLR3_UINT8)fileName;
  ModelicaParser_filename = mk_scon(fName);
  input  = antlr3AsciiFileStreamNew(fName);
  if ( input == NULL ) { fprintf(stderr, "Unable to open file %s\n", (char *)fName); exit(ANTLR3_ERR_NOMEM); }

  lxr      = ModelicaLexerNew(input);
  if (lxr == NULL ) { fprintf(stderr, "Unable to create the lexer due to malloc() failure1\n"); exit(ANTLR3_ERR_NOMEM); }
  // lxr->pLexer->rec->displayRecognitionError = handleParseError;
  lxr->pLexer->recover = lexNoRecover;

  tstream = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lxr));
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

  void* res = psr->stored_definition(psr);
  if (lxr->pLexer->rec->state->error || psr->pParser->rec->state->error) // Some parts of the AST are NULL if errors are used...
    res = 0;
  psr->free(psr);         psr = NULL;
  tstream->free(tstream); tstream = NULL;
  lxr->free(lxr);         lxr = NULL;
  input->close(input);    input = NULL;

  return res;
}


RML_BEGIN_LABEL(Parser__parse)
{
  char* filename = RML_STRINGDATA(rmlA0);
  bool debug = false, parsedump = false, parseonly = false;
  debug      = check_debug_flag("parsedebug");
  parsedump  = check_debug_flag("parsedump");
  parseonly  = check_debug_flag("parseonly");
  /* 2004-10-05 adrpo moved this declaration here to
  * have the ast initialized before getting
  * into the code. This way, if this relation fails at least the
  * ast is initialized */
  void* ast = mk_nil();

  if (debug) { fprintf(stderr, "Starting parsing of file: %s\n", filename); }

  // Set global filename, used to populate elements with
  // corresponding file name.
  modelicafilename=filename;

  //For parsing flat modelica (mof) files, if such is given
  /*bool parseFlatModelica=false;
  if (filestring.size()-4 == filestring.rfind(".mof"))
  {
    parseFlatModelica=true;
    if (debug) { std::cerr << "File:" << filename << " is a flat Modelica file." << std::endl; }
  }*/
  /*std::ifstream checkROfile(filename,ios::out); // open file in write mode to check if readonly
  modelicafileReadOnly = !checkROfile;
  if (debug && modelicafileReadOnly) { std::cerr << "File:" << filename << " is read-only." << std::endl; }

  std::ifstream stream(filename);
  if (!stream)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(filename));
    add_message(85, // Error opening file,see Error.rml
          "TRANSLATION",
          "Error",
          "Error opening file %s",
          tokens);
    modelicafilename=string("");
    RML_TAILCALLK(rmlFC);
    modelicafilename=string("");
  }
  //bool debug = true;
  modelica_lexer *lex=0;
  modelica_parser *parse=0;
  flat_modelica_parser *flat_parse=0;
  flat_modelica_lexer *flat_lex=0;
  ANTLR_USE_NAMESPACE(antlr)ASTFactory my_factory( "MyAST", MyAST::factory );

  RefMyAST t = 0;
  try
  {
    if (parseFlatModelica){
      //We are parsing flat modelica and not modelica
      flat_lex = new flat_modelica_lexer(stream);
      flat_lex->setFilename(filename);

      flat_parse = new flat_modelica_parser(*flat_lex);
      //flat_parse->setFilename(filename);

      // make factory with customized type of MyAST
      flat_parse->initializeASTFactory(my_factory);
      flat_parse->setASTFactory( &my_factory );

      flat_parse->stored_definition();
      t = RefMyAST(flat_parse->getAST());
    }
    else{
      //We are parsing regular modelica
      lex = new modelica_lexer(stream);
      lex->setFilename(filename);

      parse = new modelica_parser(*lex);
      //parse->setFilename(filename);

      // make factory with customized type of MyAST
      parse->initializeASTFactory(my_factory);
      parse->setASTFactory( &my_factory );

      parse->stored_definition();

      t = RefMyAST(parse->getAST());
    }
  }
  catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e)
  {
    std::cerr << "Lexical error. CharStreamException. "  << std::endl;
    ast = mk_nil();
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException &e)
  {
    modelica_lexer *currentLex=0;

    if (parseFlatModelica) {
      currentLex = (modelica_lexer*)flat_lex;
    }
    else {
      currentLex = lex;
    }
    std::list<std::string> tokens;
    tokens.push_back(std::string(currentLex->getText()));
    add_source_message(1, // syntax error, see Error.rml
           "SYNTAX",
           "Error",
           "Syntax error near: %s",
           tokens,
           currentLex->getLine(),
           currentLex->getColumn(),
           currentLex->getLine(),
           currentLex->getColumn(),
           false,
           filename);
    ast = mk_nil();
    modelicafilename=string("");
  }
  catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(e.getMessage()));
    add_source_message(2, // Grammar error, see Error.rml
           "GRAMMAR",
           "Error",
           "Parse error: %s",
           tokens,
           e.getLine(),
           e.getColumn(),
           e.getLine(),
           e.getColumn(),
           false,
           filename);
    ast = mk_nil();
    modelicafilename=string("");
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(e.getMessage()));
    add_source_message(2, // Grammar error, see Error.rml 
           "GRAMMAR",
           "Error",
           "Parse error: %s",
           tokens,
           0,
           0,
           0,
           0,
           false,
           filename);
    ast = mk_nil();
    modelicafilename=string("");
  }
  catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string("while parsing:")+
         std::string(e.getMessage()));
    add_source_message(63, // Internal error, see Error.rml 
           "TRANSLATION",
           "Error",
           "Internal error %s",
           tokens,
           0,
           0,
           0,
           0,
           false,
           filename);
    ast = mk_nil();
    modelicafilename=string("");
  }
  catch (std::exception &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string("while parsing:"));
    add_source_message(63, // Internal error, see Error.rml 
           "TRANSLATION",
           "Error",
           "Internal error %s",
           tokens,
           0,
           0,
           0,
           0,
           false,
           filename);
    ast = mk_nil();
    modelicafilename=string("");
  }
  catch (...)
    {
      std::list<std::string> tokens;
      tokens.push_back(std::string("while parsing:"));
      add_source_message(63, // Internal error, see Error.rml 
             "TRANSLATION",
             "Error",
             "Internal error %s",
             tokens,
             0,
             0,
             0,
             0,
             false,
             filename);
      ast = mk_nil();
      modelicafilename=string("");
  }
  */
  rmlA0 = parseFile(filename);
  // fprintf(stderr, "Parsed %s using the ANTLR3 parser :) %ld\n", filename, (long) rmlA0);
  if (rmlA0)
    RML_TAILCALLK(rmlSC);
  else
    RML_TAILCALLK(rmlFC);

  //Parsing complete
  /*if (debug)
  {
    std::cerr << "Parsing of: [" << filename << "] complete. Starting to traverse ast." << std::endl;
  }

  if (t) //Did we get at AST?
  {
    if (parsedump)
    {
      parse_tree_dumper dumper(std::cout);
      //dumper.initializeASTFactory(factory);
      //dumper.setASTFactory(&factory);
      dumper.dump(t);
    }

    if (parseonly) // only do the parsing, do not build the AST and return a null ast! 
    {
      rmlA0 = Absyn__PROGRAM(mk_nil(), Absyn__TOP, Absyn__TIMESTAMP(mk_rcon(0.0),mk_rcon(0.0)));
      RML_TAILCALLK(rmlSC);
    }


    modelica_tree_parser build;
    try
    {
      build.initializeASTFactory(my_factory);
      build.setASTFactory(&my_factory);
      ast = build.stored_definition(t);
    }
    catch (ANTLR_USE_NAMESPACE(antlr)NoViableAltException &e)
    {
      std::cerr << "1 Error walking AST while building RML data: "
        << e.getMessage() << " AST:" << std::endl;
      parse_tree_dumper dumper(std::cerr);
      dumper.dump(RefMyAST(e.node));
      ast = mk_nil();
      modelicafilename=string("");
      RML_TAILCALLK(rmlFC);
    }
    catch (ANTLR_USE_NAMESPACE(antlr)MismatchedTokenException &e)
    {
      if (e.node)
      {
        std::cerr << "2 Error walking AST while  building RML data: "
          << e.getMessage() << " AST:" << std::endl;
        parse_tree_dumper dumper(std::cerr);
        dumper.dump(RefMyAST(e.node));
      }
      else
      {
        std::cerr << "3 Error walking AST while  building RML data: "
          << e.getMessage() << " AST: == NULL" << std::endl;
      }

      // adrpo added 2004-10-27
      if (parse) delete parse;
      if (flat_parse) delete parse;
      if (lex) delete lex;
      modelicafilename=string("");
      RML_TAILCALLK(rmlFC); // rmlFC
    }
    modelicafilename=string("");
    if (debug)
    {
      std::cout << "Build done\n";
    }


    rmlA0 = ast;

    // adrpo added 2004-10-27
    if (flat_parse) delete parse;
    if (parse) delete parse;
    if (lex) delete lex;
    if (flat_lex) delete flat_lex;

    if (!ast) { RML_TAILCALLK(rmlFC);  }
    RML_TAILCALLK(rmlSC);
  }
  else
  {
    // adrpo added 2004-10-27
    if (flat_parse) delete flat_parse;
    if (parse) delete parse;
    if (lex) delete lex;
    if (flat_lex) delete flat_lex;
    ast = mk_nil();
    //std::cerr << "Error building AST" << std::endl;
  }
  */

  RML_TAILCALLK(rmlFC); // rmlFC
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


RML_BEGIN_LABEL(Parser__parseexp)
{
#if 0
  char * filename = RML_STRINGDATA(rmlA0);
  bool debug = check_debug_flag("parsedump");
  string filestring(filename);
  /* 2004-10-05 adrpo moved this declaration here to
  * have the ast initialized before getting
  * into the code. This way, if this relation fails at least the
  * ast is initialized */
  void* ast = mk_nil();
  modelicafileReadOnly = false;
  std::ifstream stream(filename);
  if (!stream)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(filename));
    add_message(85, /* Error opening file,see Error.rml*/
          "TRANSLATION",
          "Error",
          "Error opening file %s",
          tokens);
    RML_TAILCALLK(rmlFC);
  }
  // Set global filename, used to populate elements with
  // corresponding file name.
  modelicafilename = filestring;
  // lexer & parser
  modelica_lexer lex(stream);
  lex.setFilename(filename);
  modelica_expression_parser parse(lex);

  try
  {
    ANTLR_USE_NAMESPACE(antlr)ASTFactory factory;
    parse.initializeASTFactory(factory);
    parse.setASTFactory(&factory);
    parse.interactiveStmts();
    RefMyAST t = RefMyAST(parse.getAST());

    if (t)
    {
      if (debug)
      {
        parse_tree_dumper dumper(std::cerr);
        dumper.dump(t);
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

      RML_TAILCALLK(rmlSC);
    }
  }
  catch (ANTLR_USE_NAMESPACE(antlr)CharStreamException &e)
  {
    std::cerr << "Lexical error. CharStreamException. "  << std::endl;
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(lex.getText()));
    add_source_message(1, /* syntax error, see Error.rml */
           "SYNTAX", "Error", "Syntax error near: %s",
           tokens,
           lex.getLine(), lex.getColumn(),
           lex.getLine(),lex.getColumn(),
           false, filename);
  }
  catch (ANTLR_USE_NAMESPACE(antlr)RecognitionException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(e.getMessage()));
    add_source_message(2, /* Grammar error, see Error.rml */
           "GRAMMAR", "Error", "Parse error: %s",
           tokens,
           e.getLine(), e.getColumn(),
           e.getLine(), e.getColumn(),
           false, filename);
  }
  catch (ANTLR_USE_NAMESPACE(antlr)TokenStreamException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string(e.getMessage()));
    add_source_message(2, /* Grammar error, see Error.rml */
           "GRAMMAR", "Error", "Parse error: %s",
           tokens,
           0, 0,
           0, 0,
           false, filename);
  }
  catch (ANTLR_USE_NAMESPACE(antlr)ANTLRException &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string("while parsing:")+
         std::string(e.getMessage()));
    add_source_message(63, /* Internal error, see Error.rml */
           "TRANSLATION", "Error", "Internal error %s",
           tokens,
           0, 0,
           0, 0,
           false, filename);
  }
  catch (std::exception &e)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string("while parsing:"));
    add_source_message(63, /* Internal error, see Error.rml */
           "TRANSLATION", "Error", "Internal error %s",
           tokens,
           0, 0,
           0, 0,
           false, filename);
  }
  catch (...)
  {
    std::list<std::string> tokens;
    tokens.push_back(std::string("while parsing expression in file:"));
    add_source_message(63, /* Internal error, see Error.rml */
           "TRANSLATION", "Error", "Internal error %s",
           tokens,
           0, 0,
           0, 0,
           false, filename);
  }
  rmlA0 = mk_nil();
#endif
  RML_TAILCALLK(rmlFC);
}
RML_END_LABEL
