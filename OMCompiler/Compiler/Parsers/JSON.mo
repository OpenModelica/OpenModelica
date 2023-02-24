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

import LexerJSON;
import LexerJSON.{Token,TokenId,tokenContent,printToken,tokenSourceInfo};
import Vector;
import UnorderedMap;

protected

import Error;
import MetaModelica.Dangerous.listReverseInPlace;

public

record OBJECT
  UnorderedMap<String, JSON> values;
end OBJECT;
record ARRAY
  Vector<JSON> values;
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
// Used by the toString methods.
record TOKEN
  String str;
end TOKEN;
record INDENT
end INDENT;
record PUSH_INDENT
end PUSH_INDENT;
record POP_INDENT
end POP_INDENT;

function emptyObject
  output JSON obj;
algorithm
  obj := OBJECT(UnorderedMap.new<JSON>(stringHashDjb2, stringEq));
end emptyObject;

function fromPair
  input String key;
  input JSON value;
  output JSON obj;
algorithm
  obj := emptyObject();
  obj := addPair(key, value, obj);
end fromPair;

function emptyArray
  input Integer capacity = 0;
  output JSON obj = ARRAY(Vector.new<JSON>(capacity));
end emptyArray;

function makeArray
  input list<JSON> elements;
  output JSON obj = ARRAY(Vector.fromList(elements));
end makeArray;

function makeString
  input String str;
  output JSON obj = STRING(str);
end makeString;

function makeInteger
  input Integer i;
  output JSON obj = INTEGER(i);
end makeInteger;

function makeNumber
  input Real r;
  output JSON obj = NUMBER(r);
end makeNumber;

function makeBoolean
  input Boolean b;
  output JSON obj = if b then TRUE() else FALSE();
end makeBoolean;

function makeNull
  output JSON obj = NULL();
end makeNull;

function isNull
  input JSON obj;
  output Boolean res;
algorithm
  res := match obj
    case NULL() then true;
    else false;
  end match;
end isNull;

function addElement
  "Adds a value at the end of a JSON array, or returns a new array with the
   given value if the JSON is null."
  input JSON value;
  input JSON obj;
  output JSON outObj;
algorithm
  outObj := match obj
    case ARRAY()
      algorithm
        Vector.push(obj.values, value);
      then
        obj;

    case NULL()
      then addElement(value, emptyArray());
  end match;
end addElement;

function addElementNotNull
  input JSON value;
  input JSON obj;
  output JSON outObj;
algorithm
  outObj := if isNull(value) then obj else addElement(value, obj);
end addElementNotNull;

function addPair
  "Adds a key-value pair to a JSON object, or returns a new object with the
   key-value pair if the JSON is null."
  input String key;
  input JSON value;
  input JSON obj;
  output JSON outObj;
algorithm
  outObj := match obj
    case OBJECT()
      algorithm
        UnorderedMap.add(key, value, obj.values);
      then
        obj;

    case NULL()
      then addPair(key, value, emptyObject());
  end match;
end addPair;

function addPairNotNull
  "Adds a key-value pair to a JSON object if the value is not null."
  input String key;
  input JSON value;
  input JSON obj;
  output JSON outObj;
algorithm
  outObj := if isNull(value) then obj else addPair(key, value, obj);
end addPairNotNull;

function toString
  input JSON value;
  input Boolean prettyPrint = false;
  output String str;
algorithm
  if prettyPrint then
    str := toStringPP_work(value);
  else
    str := toString_work(value);
  end if;
end toString;

function toString_work
  input JSON value;
  output String str;
protected
  list<JSON> stack = {value};
  JSON v;
  list<String> strl = {};
  Integer len = 0;
algorithm
  while not listEmpty(stack) loop
    v :: stack := stack;

    strl := match v
      case STRING() then appendStackString(v.str, strl);
      case TRUE() then "true" :: strl;
      case FALSE() then "false" :: strl;
      case NULL() then "null" :: strl;
      case INTEGER() then String(v.i) :: strl;
      case NUMBER() then String(v.r) :: strl;

      case ARRAY()
        algorithm
          stack := appendStackArray(v.values, stack);
        then
          strl;

      case OBJECT()
        algorithm
          stack := appendStackObject(v.values, stack);
        then
          strl;

      case TOKEN() then v.str :: strl;
    end match;
  end while;

  str := stringAppendList(strl);
end toString_work;

function appendStackString
  input String str;
  input output list<String> strl;
algorithm
  strl := "\"" :: strl;
  strl := System.escapedString(str, true) :: strl;
  strl := "\"" :: strl;
end appendStackString;

function appendStackArray
  input Vector<JSON> values;
  input output list<JSON> stack;
algorithm
  stack := TOKEN("[") :: stack;

  for i in 1:Vector.size(values) loop
    if i <> 1 then
      stack := TOKEN(", ") :: stack;
    end if;

    stack := Vector.getNoBounds(values, i) :: stack;
  end for;

  stack := TOKEN("]") :: stack;
end appendStackArray;

function appendStackObject
  input UnorderedMap<String, JSON> map;
  input output list<JSON> stack;
algorithm
  stack := TOKEN("{") :: stack;

  for i in 1:UnorderedMap.size(map) loop
    if i <> 1 then
      stack := TOKEN(", ") :: stack;
    end if;

    stack := TOKEN("\"") :: stack;
    stack := TOKEN(UnorderedMap.keyAt(map, i)) :: stack;
    stack := TOKEN("\":") :: stack;
    stack := UnorderedMap.valueAt(map, i) :: stack;
  end for;

  stack := TOKEN("}") :: stack;
end appendStackObject;

function toStringPP_work
  input JSON value;
  output String str;
protected
  list<JSON> stack = {value};
  JSON v;
  list<String> strl = {};
  String indent = "";
  Integer indent_len;
algorithm
  while not listEmpty(stack) loop
    v :: stack := stack;

    strl := match v
      case STRING() then appendStackString(v.str, strl);
      case TRUE() then "true" :: strl;
      case FALSE() then "false" :: strl;
      case NULL() then "null" :: strl;
      case INTEGER() then String(v.i) :: strl;
      case NUMBER() then String(v.r) :: strl;

      case ARRAY()
        algorithm
          stack := appendStackArrayPP(v.values, stack);
        then
          strl;

      case OBJECT()
        algorithm
          stack := appendStackObjectPP(v.values, stack);
        then
          strl;

      case TOKEN() then v.str :: strl;
      case INDENT() then indent :: strl;

      case PUSH_INDENT()
        algorithm
          indent := indent + "  ";
        then
          strl;

      case POP_INDENT()
        algorithm
          indent_len := stringLength(indent) - 2;

          if indent_len == 0 then
            indent := "";
          else
            indent := substring(indent, 1,  indent_len);
          end if;
        then
          strl;
    end match;
  end while;

  str := stringAppendList(strl);
end toStringPP_work;

function appendStackArrayPP
  input Vector<JSON> values;
  input output list<JSON> stack;
algorithm
  stack := POP_INDENT() :: stack;
  stack := TOKEN("[\n") :: stack;

  for i in 1:Vector.size(values) loop
    if i <> 1 then
      stack := TOKEN(",\n") :: stack;
    end if;

    stack := INDENT() :: stack;
    stack := Vector.getNoBounds(values, i) :: stack;
  end for;

  stack := TOKEN("\n") :: stack;
  stack := PUSH_INDENT() :: stack;
  stack := INDENT() :: stack;
  stack := TOKEN("]") :: stack;
end appendStackArrayPP;

function appendStackObjectPP
  input UnorderedMap<String, JSON> map;
  input output list<JSON> stack;
algorithm
  stack := POP_INDENT() :: stack;
  stack := TOKEN("{\n") :: stack;

  for i in 1:UnorderedMap.size(map) loop
    if i <> 1 then
      stack := TOKEN(",\n") :: stack;
    end if;

    stack := INDENT() :: stack;
    stack := TOKEN("\"") :: stack;
    stack := TOKEN(UnorderedMap.keyAt(map, i)) :: stack;
    stack := TOKEN("\": ") :: stack;
    stack := UnorderedMap.valueAt(map, i) :: stack;
  end for;

  stack := TOKEN("\n") :: stack;
  stack := PUSH_INDENT() :: stack;
  stack := INDENT() :: stack;
  stack := TOKEN("}") :: stack;
end appendStackObjectPP;

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

function hasKey
  input JSON obj;
  input String str;
  output Boolean b;
algorithm
  b := match obj
    case OBJECT() then UnorderedMap.contains(str, obj.values);
  end match;
end hasKey;

function get
  input JSON obj;
  input String str;
  output JSON out;
algorithm
  out := match obj
    case OBJECT() then UnorderedMap.getOrFail(str, obj.values);
  end match;
end get;

function getOrDefault
  input JSON obj;
  input String str;
  input JSON default;
  output JSON out;
algorithm
  out := match obj
    case OBJECT() then UnorderedMap.getOrDefault(str, obj.values, default);
    else default;
  end match;
end getOrDefault;

function at
  input JSON obj;
  input Integer index;
  output JSON out;
algorithm
  out := match obj
    case ARRAY() then Vector.get(obj.values, index);
  end match;
end at;

function getString
  input JSON obj;
  output String str;
algorithm
  JSON.STRING(str) := obj;
end getString;

function getStringList
  input JSON obj;
  output list<String> strl;
algorithm
  strl := match obj
    case OBJECT() then list(getString(v) for v in UnorderedMap.valueList(obj.values));
    case ARRAY() then Vector.mapToList(obj.values, getString);
  end match;
end getStringList;

function getKeys
  input JSON obj;
  output list<String> keys;
algorithm
  keys := match obj
    case OBJECT() then UnorderedMap.keyList(obj.values);
  end match;
end getKeys;

function getBoolean
  input JSON obj;
  output Boolean b;
algorithm
  b := match obj
    case JSON.TRUE() then true;
    case JSON.FALSE() then false;
  end match;
end getBoolean;

function size
  input JSON obj;
  output Integer sz;
algorithm
  sz := match obj
    case OBJECT() then UnorderedMap.size(obj.values);
    case ARRAY() then Vector.size(obj.values);
    else 1;
  end match;
end size;

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
  Vector<JSON> values = Vector.new<JSON>();
  Boolean cont;
algorithm
  value := emptyObject();
  tokens := parse_expected_token(tokens, TokenId.ARRAYBEGIN);
  cont := peek_id(tokens) <> TokenId.ARRAYEND;
  while cont loop
    (value,tokens) := parse_value(tokens);
    Vector.push(values, value);
    (tokens,cont) := eat_if_next_token_matches(tokens, TokenId.COMMA);
  end while;
  tokens := parse_expected_token(tokens, TokenId.ARRAYEND);
  value := ARRAY(values);
end parse_array;

function parse_object
  extends partialParser;
protected
  UnorderedMap<String, JSON> values;
  String key;
  Boolean cont;
algorithm
  values := UnorderedMap.new<JSON>(stringHashDjb2, stringEq);
  tokens := parse_expected_token(tokens, TokenId.OBJECTBEGIN);
  cont := peek_id(tokens) <> TokenId.ARRAYEND;
  while cont loop
    (STRING(str=key), tokens) := parse_string(tokens);
    tokens := parse_expected_token(tokens,TokenId.COLON);
    (value,tokens) := parse_value(tokens);
    UnorderedMap.add(key, value, values);
    (tokens,cont) := eat_if_next_token_matches(tokens, TokenId.COMMA);
  end while;
  tokens := parse_expected_token(tokens, TokenId.OBJECTEND);
  value := OBJECT(values);
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
