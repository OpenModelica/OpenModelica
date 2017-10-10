/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

encapsulated uniontype JSON

import BaseAvlTree;
import LexerJSON;
import LexerJSON.{Token,TokenId,tokenContent,printToken,tokenSourceInfo};

protected

import Error;
import MetaModelica.Dangerous.listReverseInPlace;

public

encapsulated package AvlTree "AvlTree for String to String"
  import BaseAvlTree;
  import JSON;
  extends BaseAvlTree;
  redeclare type Key = String;
  redeclare type Value = JSON;
  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;
  redeclare function extends valueStr
  algorithm
    outString := JSON.toString(inValue);
  end valueStr;
  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;
annotation(__OpenModelica_Interface="util");
end AvlTree;

type Dict = JSON.AvlTree.Tree;

record OBJECT
  list<String> orderedKeys;
  list<JSON> orderedValues;
  Dict dict;
end OBJECT;
record ARRAY
  list<JSON> values;
end ARRAY;
record STRING
  String str;
end STRING;
record INTEGER
  Integer i;
end INTEGER;
record NUMBER
  Real r;
end NUMBER;
record TRUE
end TRUE;
record FALSE
end FALSE;
record NULL
end NULL;

function toString
  input JSON value;
  output String str;
algorithm
  str := match value
    case STRING() then "\""+System.escapedString(value.str,true)+"\"";
    case TRUE() then "true";
    case FALSE() then "false";
    case NULL() then "null";
    case INTEGER() then String(value.i);
    case NUMBER() then String(value.r);
    case ARRAY() then "["+stringDelimitList(list(toString(v) for v in value.values), ", ")+"]";
    case OBJECT() then "{"+stringDelimitList(list("\""+System.escapedString(k,true)+"\":"+toString(v) threaded for k in value.orderedKeys, v in value.orderedValues), ", ")+"}";
    else anyString(value);
  end match;
end toString;

partial function partialParser
  input list<Token> inTokens;
  output JSON value;
  output list<Token> tokens = inTokens;
protected
  Token tok;
end partialParser;

function parseFile
  input String fileName;
  output JSON value;
protected
  list<Token> tokens,errTokens;
algorithm
  (tokens,errTokens) := LexerJSON.scan(fileName);
  reportErrors(errTokens);
  value := parse_value_check_empty(tokens);
end parseFile;

function parse
  input String content;
  input String fileName="<String>";
  output JSON value;
protected
  list<Token> tokens,errTokens;
algorithm
  (tokens,errTokens) := LexerJSON.scanString(content,fileName=fileName);
  reportErrors(errTokens);
  value := parse_value_check_empty(tokens);
end parse;

function parse_value_check_empty
  input list<Token> inTokens;
  output JSON value;
protected
  list<Token> tokens;
algorithm
  (value,tokens) := parse_value(inTokens);
  check_empty(tokens);
end parse_value_check_empty;

function parse_value
  extends partialParser;
algorithm
  not_eof(tokens);
  tok::tokens := tokens;
  (value,tokens) := match tok.id
    case TokenId.STRING algorithm (value,tokens) := parse_string(inTokens); then (value,tokens);
    case TokenId.INTEGER algorithm (value,tokens) := parse_integer(inTokens); then (value,tokens);
    case TokenId.NUMBER algorithm (value,tokens) := parse_number(inTokens); then (value,tokens);
    case TokenId.OBJECTBEGIN algorithm (value,tokens) := parse_object(inTokens); then (value,tokens);
    case TokenId.ARRAYBEGIN algorithm (value,tokens) := parse_array(inTokens); then (value,tokens);
    case TokenId.TRUE then (TRUE(),tokens);
    case TokenId.FALSE then (FALSE(),tokens);
    case TokenId.NULL then (NULL(),tokens);
    else
      algorithm
        errorExpected("a value", tok);
      then fail();
  end match;
end parse_value;

function parse_string
  extends partialParser;
protected
  list<JSON> values = {};
  Boolean cont;
  String content;
algorithm
  not_eof(tokens);
  tok::tokens := tokens;
  if tok.id <> TokenId.STRING then
    errorExpected("a String", tok);
  end if;
  content := tokenContent(tok);
  if stringLength(content)==2 then
    content := "";
  else
    content := System.unescapedString(System.substring(content,2,stringLength(content)-1));
  end if;
  value := STRING(content);
end parse_string;

function parse_integer
  extends partialParser;
protected
  list<JSON> values = {};
  Boolean cont;
  String content;
algorithm
  not_eof(tokens);
  tok::tokens := tokens;
  if tok.id <> TokenId.INTEGER then
    errorExpected("an integer", tok);
  end if;
  content := tokenContent(tok);
  value := INTEGER(stringInt(content));
end parse_integer;

function parse_number
  extends partialParser;
protected
  list<JSON> values = {};
  Boolean cont;
  String content;
algorithm
  not_eof(tokens);
  tok::tokens := tokens;
  if tok.id <> TokenId.NUMBER then
    errorExpected("a (real) number", tok);
  end if;
  content := tokenContent(tok);
  value := NUMBER(stringReal(content));
end parse_number;


function parse_array
  extends partialParser;
protected
  list<JSON> values = {};
  Boolean cont;
algorithm
  tokens := parse_expected_token(tokens, TokenId.ARRAYBEGIN);
  cont := peek_id(tokens) <> TokenId.ARRAYEND;
  while cont loop
    (value,tokens) := parse_value(tokens);
    values := value::values;
    (tokens,cont) := eat_if_next_token_matches(tokens, TokenId.COMMA);
  end while;
  tokens := parse_expected_token(tokens, TokenId.ARRAYEND);
  value := ARRAY(listReverseInPlace(values));
end parse_array;

function parse_object
  extends partialParser;
protected
  Dict tree = Dict.EMPTY();
  list<JSON> orderedValues={};
  list<String> orderedKeys={};
  String key;
  Boolean cont;
algorithm
  tokens := parse_expected_token(tokens, TokenId.OBJECTBEGIN);
  cont := peek_id(tokens) <> TokenId.ARRAYEND;
  while cont loop
    (STRING(str=key), tokens) := parse_string(tokens);
    tokens := parse_expected_token(tokens,TokenId.COLON);
    (value,tokens) := parse_value(tokens);
    tree := AvlTree.add(tree, key, value);
    orderedKeys := key::orderedKeys;
    orderedValues := value::orderedValues;
    (tokens,cont) := eat_if_next_token_matches(tokens, TokenId.COMMA);
  end while;
  tokens := parse_expected_token(tokens, TokenId.OBJECTEND);
  value := OBJECT(listReverseInPlace(orderedKeys), listReverseInPlace(orderedValues), tree);
end parse_object;

protected

function reportErrors
  input list<Token> tokens;
protected
  Integer i=0;
algorithm
  for t in tokens loop
    i := i+1;
    if i>10 then
      Error.addMessage(Error.SCANNER_ERROR_LIMIT, {});
    end if;
    Error.addSourceMessage(Error.SCANNER_ERROR, {tokenContent(t)}, tokenSourceInfo(t));
  end for;
  if not listEmpty(tokens) then
    fail();
  end if;
end reportErrors;

function not_eof
  input output list<Token> tokens;
algorithm
  if listEmpty(tokens) then
    Error.addCompilerError("JSON expected value, got <EOF>...");
    fail();
  end if;
end not_eof;

function peek_id
  input list<Token> tokens;
  output TokenId nextToken;
protected
  Token tok;
algorithm
  if listEmpty(tokens) then
    nextToken := TokenId._NO_TOKEN;
  end if;
  tok := listHead(tokens);
  nextToken := tok.id;
end peek_id;

function eat_if_next_token_matches
  input output list<Token> tokens;
  input TokenId expectedToken;
  output Boolean matched=false;
protected
  Token tok;
algorithm
  if listEmpty(tokens) then
    return;
  end if;
  tok := listHead(tokens);
  if tok.id <> expectedToken then
    return;
  end if;
  matched := true;
  _::tokens := tokens;
end eat_if_next_token_matches;

function parse_expected_token
  input output list<Token> tokens;
  input TokenId expectedToken;
protected
  Token tok;
algorithm
  not_eof(tokens);
  tok::tokens := tokens;
  if tok.id <> expectedToken then
    Error.addSourceMessage(Error.COMPILER_ERROR, {"Expected a "+String(expectedToken)+", got token: " + tokenContent(tok)}, tokenSourceInfo(tok));
    fail();
  end if;
end parse_expected_token;

function check_empty
  input list<Token> tokens;
protected
  Token tok;
algorithm
  if listEmpty(tokens) then
    return;
  end if;
  tok := listHead(tokens);
  Error.addSourceMessage(Error.COMPILER_ERROR, {"Expected <EOF>, got more tokens, starting with: " + tokenContent(tok)}, tokenSourceInfo(tok));
  fail();
end check_empty;

function errorExpected
  input String expected;
  input Token tok;
algorithm
  Error.addSourceMessage(Error.COMPILER_ERROR, {"JSON expected "+expected+", got token "+String(tok.id)+": " + tokenContent(tok)}, tokenSourceInfo(tok));
  fail();
end errorExpected;

annotation(__OpenModelica_Interface="util");
end JSON;
