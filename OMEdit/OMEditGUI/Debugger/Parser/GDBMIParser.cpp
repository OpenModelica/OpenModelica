/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "GDBMIParser.h"
#include "GDBMIOutputLexer.h"
#include "GDBMIOutputParser.h"

namespace GDBMIParser {
GDBMIValue::GDBMIValue()
{
  type = GDBMIValue::NoneValue;
  value = "";
  miTuple = 0;
  miList = 0;
}

GDBMIValue::~GDBMIValue()
{
  if (miTuple) delete miTuple;
  if (miList) delete miList;
}

GDBMITuple::~GDBMITuple()
{
  /* Delete the GDBMIResultList */
  GDBMIResultList::iterator resultsListiterator;
  for (resultsListiterator = miResultsList.begin(); resultsListiterator != miResultsList.end(); ++resultsListiterator)
  {
    delete *resultsListiterator;
  }
  miResultsList.clear();
}

GDBMIList::GDBMIList()
{
  type = GDBMIList::NoneList;
}

GDBMIList::~GDBMIList()
{
  /* Delete the GDBMIValueList */
  GDBMIValueList::iterator valuesListiterator;
  for (valuesListiterator = miValuesList.begin(); valuesListiterator != miValuesList.end(); ++valuesListiterator)
  {
    delete *valuesListiterator;
  }
  miValuesList.clear();
  /* Delete the GDBMIResultList */
  GDBMIResultList::iterator resultsListiterator;
  for (resultsListiterator = miResultsList.begin(); resultsListiterator != miResultsList.end(); ++resultsListiterator)
  {
    delete *resultsListiterator;
  }
  miResultsList.clear();
}

GDBMIResult::GDBMIResult()
{
  variable = "";
  miValue = 0;
}

GDBMIResult::~GDBMIResult()
{
  if (miValue) delete miValue;
}

GDBMIResultRecord::GDBMIResultRecord()
{
  token = -1;
  cls = "";
  consoleStreamOutput = "";
  logStreamOutput = "";
}

GDBMIResultRecord::~GDBMIResultRecord()
{
  GDBMIResultList::iterator it;
  for (it = miResultsList.begin(); it != miResultsList.end(); ++it)
  {
    delete *it;
  }
}

GDBMIOutOfBandRecord::GDBMIOutOfBandRecord()
{
  type = GDBMIOutOfBandRecord::NoneRecord;
  miResultRecord = 0;
  miStreamRecord = 0;
}

GDBMIOutOfBandRecord::~GDBMIOutOfBandRecord()
{
  if (miResultRecord) delete miResultRecord;
  if (miStreamRecord) delete miStreamRecord;
}

GDBMIResponse::GDBMIResponse()
{
  type = GDBMIResponse::NoneResponse;
  miResultRecord = 0;
}

GDBMIResponse::~GDBMIResponse()
{
  /* Delete the GDBMIOutOfBandRecordList */
  GDBMIOutOfBandRecordList::iterator outOfBandRecordIterator;
  for (outOfBandRecordIterator = miOutOfBandRecordList.begin(); outOfBandRecordIterator != miOutOfBandRecordList.end(); ++outOfBandRecordIterator)
  {
    delete *outOfBandRecordIterator;
  }
  miOutOfBandRecordList.clear();
  /* Delete the GDBMIResultRecord */
  if (miResultRecord) delete miResultRecord;
}

static list<string> lexerErrorsList;
static void handleLexerError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_LEXER lexer;
  pANTLR3_EXCEPTION ex;
  int type;
  const char *text = 0;
  int offset, line;
//  recognizer->state->error = ANTLR3_TRUE;
//  recognizer->state->failed = ANTLR3_TRUE;

  // Retrieve some info for easy reading.
  ex = recognizer->state->exception;

  switch  (recognizer->type)
  {
    case  ANTLR3_TYPE_LEXER:
      lexer = (pANTLR3_LEXER) (recognizer->super);
      text = (const char*)lexer->input->data;
      type = ex->type;
      line = lexer->getLine(lexer);
      offset = lexer->getCharPositionInLine(lexer)+1;
      break;
    default:
      ANTLR3_FPRINTF(stderr, "Base recognizer function displayRecognitionError called by unknown lexer type - provide override for this function\n");
      return;
      break;
  }

  std::stringstream errorStr;
  switch (type) {
    case ANTLR3_NO_VIABLE_ALT_EXCEPTION:
    default:
      errorStr << "No viable alternative near token: " << text << " at line " << line << ": at offset " << offset;
      lexerErrorsList.push_back(errorStr.str());
      break;
  }
}

static list<string> parserErrorsList;
/* Error handling based on antlr3baserecognizer.c */
static void handleParseError(pANTLR3_BASE_RECOGNIZER recognizer, pANTLR3_UINT8 * tokenNames)
{
  pANTLR3_PARSER parser;
  pANTLR3_EXCEPTION ex;
  pANTLR3_COMMON_TOKEN preToken,nextToken;
  pANTLR3_TOKEN_STREAM tokenStream;
  int type;
  const char *token_text[3] = {0,0,0};
  int p_offset, n_offset, p_line, n_line;
  recognizer->state->error = ANTLR3_TRUE;
  recognizer->state->failed = ANTLR3_TRUE;

  // Retrieve some info for easy reading.
  ex = recognizer->state->exception;

  switch  (recognizer->type)
  {
    case  ANTLR3_TYPE_PARSER:
      parser = (pANTLR3_PARSER) (recognizer->super);
      token_text[1] = (const char*) ex->message;
      type = ex->type;
      tokenStream = parser->getTokenStream(parser);
      preToken = tokenStream->_LT(tokenStream,1);
      nextToken = tokenStream->_LT(tokenStream,2);
      if (preToken == NULL) preToken = nextToken;
      p_line = preToken->line;
      n_line = nextToken->line;
      p_offset = preToken->charPosition+1;
      n_offset = nextToken->charPosition;
      break;
    default:
      ANTLR3_FPRINTF(stderr, "Base recognizer function displayRecognitionError called by unknown parser type - provide override for this function\n");
      return;
      break;
  }

  std::stringstream errorStr;
  switch (type) {

    case ANTLR3_UNWANTED_TOKEN_EXCEPTION:
    {
      ANTLR3_COMMON_TOKEN *token = (ANTLR3_COMMON_TOKEN*) ex->token;
      ANTLR3_STRING *str = token->getText(token);
      token_text[0] = (const char*) tokenNames[token->type];
      token_text[1] = token->type == ANTLR3_TOKEN_EOF ? "" : (const char*) str->chars;
      token_text[2] = (const char*) tokenNames[ex->expecting];
      errorStr << "Expected token of type " << token_text[0] << ", got '" << token_text[1] << "' of type " << token_text[2] << " at " << p_line << ":" << p_offset << "-" << n_line << ":" << n_offset;
      parserErrorsList.push_back(errorStr.str());
      //fprintf(stderr, "ANTLR3_UNWANTED_TOKEN_EXCEPTION Expected token of type %s, got '%s' of type %s at %d:%d-%d:%d\n", token_text[0], token_text[1], token_text[2], p_line, p_offset, n_line, n_offset);fflush(NULL);
      break;
    }
    case ANTLR3_MISSING_TOKEN_EXCEPTION:
      token_text[0] = (const char*) tokenNames[ex->expecting];
      errorStr << "Missing token: " << token_text[0] << " at " << p_line << ":" << p_offset << "-" << p_line << ":" << p_offset;
      parserErrorsList.push_back(errorStr.str());
      //fprintf(stderr, "ANTLR3_MISSING_TOKEN_EXCEPTION Missing token: %s at %d:%d-%d:%d\n", token_text[0], p_line, p_offset, p_line, p_offset);fflush(NULL);
      break;
    case ANTLR3_NO_VIABLE_ALT_EXCEPTION:
      token_text[0] = preToken->type == ANTLR3_TOKEN_EOF ? "<EOF>" : (const char*)preToken->getText(preToken)->chars;
      if (preToken->type == ANTLR3_TOKEN_EOF) n_offset = p_offset;
      errorStr << "No viable alternative near token: " << token_text[0] << " at " << p_line << ":" << p_offset << "-" << n_line << ":" << n_offset;
      parserErrorsList.push_back(errorStr.str());
      break;
    case ANTLR3_MISMATCHED_SET_EXCEPTION:
    case ANTLR3_EARLY_EXIT_EXCEPTION:
    case ANTLR3_RECOGNITION_EXCEPTION:
    default:
      token_text[2] = (const char*)ex->message;
      token_text[1] = preToken->type == ANTLR3_TOKEN_EOF ? "" : (const char*)preToken->getText(preToken)->chars;
      token_text[0] = (const char*) tokenNames[preToken->type];
      if (preToken->type == ANTLR3_TOKEN_EOF) n_offset = p_offset;
      errorStr << "Parser error: " << token_text[0] << " near: " << token_text[1] << " (" << token_text[2] << ") " << " at " << p_line << ":" << p_offset << "-" << n_line << ":" << n_offset;
      parserErrorsList.push_back(errorStr.str());
      break;
  }
}

bool printGDBMIResponse(GDBMIResponse *miResponse)
{
  if (miResponse->type == GDBMIResponse::OutOfBandRecordResponse)
  {
    printGDBMIOutOfBandRecordList(miResponse->miOutOfBandRecordList);
    return true;
  }
  else if (miResponse->type == GDBMIResponse::ResultRecordResponse)
  {
    printGDBMIResultRecord(miResponse->miResultRecord);
    return true;
  }
  else
  {
    return false;
  }
}

void printGDBMIOutOfBandRecordList(GDBMIOutOfBandRecordList miOutOfBandRecordList)
{
  GDBMIOutOfBandRecordList::iterator it;
  for (it = miOutOfBandRecordList.begin(); it != miOutOfBandRecordList.end(); ++it)
  {
    printGDBMIOutOfBandRecord(*it);
    if (it != --miOutOfBandRecordList.end())
      fprintf(stdout, ",");fflush(NULL);
  }
}

void printGDBMIOutOfBandRecord(GDBMIOutOfBandRecord *miOutOfBandRecord)
{
  if (miOutOfBandRecord->type == GDBMIOutOfBandRecord::AsyncRecord)
  {
    printGDBMIResultRecord(miOutOfBandRecord->miResultRecord);
  }
  else if (miOutOfBandRecord->type == GDBMIOutOfBandRecord::StreamRecord)
  {
    printStreamRecord(miOutOfBandRecord->miStreamRecord);
  }
}

void printStreamRecord(GDBMIStreamRecord *miStreamRecord)
{
  fprintf(stdout, "%s", miStreamRecord->value.c_str());fflush(NULL);
}

void printGDBMIResultRecord(GDBMIResultRecord *miResultRecord)
{
  fprintf(stdout, "%d,%s,", miResultRecord->token, miResultRecord->cls.c_str());fflush(NULL);
  printGDBMIResultList(miResultRecord->miResultsList);
}

void printGDBMIResultList(GDBMIResultList miResultsList)
{
  GDBMIResultList::iterator it;
  for (it = miResultsList.begin(); it != miResultsList.end(); ++it)
  {
    printGDBMIResult(*it);
    if (it != --miResultsList.end())
      fprintf(stdout, ",");fflush(NULL);
  }
}

void printGDBMIResult(GDBMIResult *miResult)
{
  fprintf(stdout, "%s=", miResult->variable.c_str());fflush(NULL);
  printGDBMIValue(miResult->miValue);
}

void printGDBMIValue(GDBMIValue *miValue)
{
  if (miValue->type == GDBMIValue::ConstantValue)
  {
    fprintf(stdout, "%s", miValue->value.c_str());fflush(NULL);
  }
  else if (miValue->type == GDBMIValue::TupleValue)
  {
    printGDBMITuple(miValue->miTuple);
  }
  else if (miValue->type == GDBMIValue::ListValue)
  {
    printGDBMIList(miValue->miList);
  }
}

void printGDBMITuple(GDBMITuple *miTuple)
{
  GDBMIResultList::iterator resultsListiterator;
  fprintf(stdout, "{");fflush(NULL);
  for (resultsListiterator = miTuple->miResultsList.begin(); resultsListiterator != miTuple->miResultsList.end(); ++resultsListiterator)
  {
    GDBMIResult *pGDBMIResult = (*resultsListiterator);
    GDBMIValue *pGDBMIValue = pGDBMIResult->miValue;
    if (pGDBMIValue->type == GDBMIValue::ConstantValue)
    {
      fprintf(stdout, "%s=%s", pGDBMIResult->variable.c_str(), pGDBMIValue->value.c_str());fflush(NULL);
    }
    else
    {
      fprintf(stdout, "%s=", pGDBMIResult->variable.c_str());fflush(NULL);
      printGDBMIValue(pGDBMIValue);
    }
    if (resultsListiterator != --miTuple->miResultsList.end())
      fprintf(stdout, ",");fflush(NULL);
  }
  fprintf(stdout, "}");fflush(NULL);
}

void printGDBMIList(GDBMIList *miList)
{
  if (miList->type == GDBMIList::ValuesList)
  {
    GDBMIValueList::iterator it;
    fprintf(stdout, "[");fflush(NULL);
    for (it = miList->miValuesList.begin(); it != miList->miValuesList.end(); ++it)
    {
      printGDBMIValue(*it);
      if (it != --miList->miValuesList.end())
        fprintf(stdout, ",");fflush(NULL);
    }
    fprintf(stdout, "]");fflush(NULL);
  }
  else if (miList->type == GDBMIList::ResultsList)
  {
    GDBMIResultList::iterator it;
    fprintf(stdout, "[");fflush(NULL);
    for (it = miList->miResultsList.begin(); it != miList->miResultsList.end(); ++it)
    {
      printGDBMIResult(*it);
      if (it != --miList->miResultsList.end())
        fprintf(stdout, ",");fflush(NULL);
    }
    fprintf(stdout, "]");fflush(NULL);
  }
}

list<string> getLexerErrorsList()
{
  return lexerErrorsList;
}

void clearLexerErrorsList()
{
  lexerErrorsList.clear();
}

list<string> getParserErrorsList()
{
  return parserErrorsList;
}

void clearParserErrorsList()
{
  parserErrorsList.clear();
}

GDBMIResponse* parseGDBOutput(const char* output) {
  pANTLR3_INPUT_STREAM           input;
  pGDBMIOutputLexer                lex;
  pANTLR3_COMMON_TOKEN_STREAM    tokens;
  pGDBMIOutputParser               parser;

  input  = antlr3NewAsciiStringInPlaceStream((pANTLR3_UINT8)output, strlen(output), (pANTLR3_UINT8)"");
  lex    = GDBMIOutputLexerNew(input);
  lex->pLexer->rec->displayRecognitionError = handleLexerError;
  tokens = antlr3CommonTokenStreamSourceNew(ANTLR3_SIZE_HINT, TOKENSOURCE(lex));
  parser = GDBMIOutputParserNew(tokens);
  parser->pParser->rec->displayRecognitionError = handleParseError;

  parserErrorsList.clear();
  GDBMIResponse *retval = parser->output(parser);
  /* if the parser fails */
  if (parser->pParser->rec->state->failed)
  {
    parserErrorsList.push_back(string(output));
    delete retval;
    retval = NULL;
  }
  // Must manually clean up
  //
  parser ->free(parser);
  tokens ->free(tokens);
  lex    ->free(lex);
  input  ->close(input);
  return retval;
}
} // namespace GDBMIParser
