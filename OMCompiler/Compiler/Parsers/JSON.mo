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
import Util;
import Print;

public

record OBJECT
  UnorderedMap<String, JSON> values;
end OBJECT;
record LIST_OBJECT
  list<tuple<String, JSON>> values;
end LIST_OBJECT;
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

function emptyObject
  output JSON obj;
algorithm
  obj := OBJECT(UnorderedMap.new<JSON>(stringHashDjb2, stringEq));
end emptyObject;

function emptyListObject
  output JSON obj = LIST_OBJECT({});
end emptyListObject;

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

    case LIST_OBJECT()
      then LIST_OBJECT((key, value) :: obj.values);

    case NULL()
      then addPair(key, value, emptyListObject());
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
protected
  Integer handle;
algorithm
  handle := Print.saveAndClearBuf();

  if prettyPrint then
    toStringPP_work(value);
  else
    toString_work(value);
  end if;

  str := Print.getString();
  Print.restoreBuf(handle);
end toString;

function toString_work
  input JSON value;
algorithm
  () := match value
    case STRING()
      algorithm
        Print.printBuf("\"");
        Print.printBuf(System.escapedString(value.str, true));
        Print.printBuf("\"");
      then
        ();

    case TRUE()
      algorithm
        Print.printBuf("true");
      then
        ();

    case FALSE()
      algorithm
        Print.printBuf("false");
      then
        ();

    case NULL()
      algorithm
        Print.printBuf("null");
      then
        ();

    case INTEGER()
      algorithm
        Print.printBuf(String(value.i));
      then
        ();

    case NUMBER()
      algorithm
        Print.printBuf(String(value.r));
      then
        ();

    case ARRAY()
      algorithm
        toString_array(value.values);
      then
        ();

    case OBJECT()
      algorithm
        toString_object(value.values);
      then
        ();

    case LIST_OBJECT()
      algorithm
        toString_listObject(value.values);
      then
        ();

    else ();
  end match;
end toString_work;

function toString_array
  input Vector<JSON> values;
algorithm
  Print.printBuf("[");

  for i in 1:Vector.size(values) loop
    if i <> 1 then
      Print.printBuf(", ");
    end if;

    toString_work(Vector.getNoBounds(values, i));
  end for;

  Print.printBuf("]");
end toString_array;

function toString_object
  input UnorderedMap<String, JSON> map;
algorithm
  Print.printBuf("{");

  for i in 1:UnorderedMap.size(map) loop
    if i <> 1 then
      Print.printBuf(", ");
    end if;

    Print.printBuf("\"");
    Print.printBuf(UnorderedMap.keyAt(map, i));
    Print.printBuf("\":");
    toString_work(UnorderedMap.valueAt(map, i));
  end for;

  Print.printBuf("}");
end toString_object;

function toString_listObject
  input list<tuple<String, JSON>> object;
protected
  Boolean first = true;
  String key;
  JSON value;
algorithm
  Print.printBuf("{");

  for entry in listReverse(object) loop
    (key, value) := entry;

    if first then
      first := false;
    else
      Print.printBuf(", ");
    end if;

    Print.printBuf("\"");
    Print.printBuf(key);
    Print.printBuf("\":");
    toString_work(value);
  end for;

  Print.printBuf("}");
end toString_listObject;

function toStringPP_work
  input JSON value;
  input String indent = "";
algorithm
  () := match value
    case STRING()
      algorithm
        Print.printBuf("\"");
        Print.printBuf(System.escapedString(value.str, true));
        Print.printBuf("\"");
      then
        ();

    case TRUE()
      algorithm
        Print.printBuf("true");
      then
        ();

    case FALSE()
      algorithm
        Print.printBuf("false");
      then
        ();

    case NULL()
      algorithm
        Print.printBuf("null");
      then
        ();

    case INTEGER()
      algorithm
        Print.printBuf(String(value.i));
      then
        ();

    case NUMBER()
      algorithm
        Print.printBuf(String(value.r));
      then
        ();

    case ARRAY()
      algorithm
        toStringPP_array(value.values, indent);
      then
        ();

    case OBJECT()
      algorithm
        toStringPP_object(value.values, indent);
      then
        ();

    case LIST_OBJECT()
      algorithm
        toStringPP_listObject(value.values, indent);
      then
        ();

    else ();
  end match;
end toStringPP_work;

function toStringPP_array
  input Vector<JSON> values;
  input String indent;
protected
  String next_indent = indent + "  ";
algorithm
  Print.printBuf("[\n");

  for i in 1:Vector.size(values) loop
    if i <> 1 then
      Print.printBuf(",\n");
    end if;

    Print.printBuf(next_indent);
    toStringPP_work(Vector.getNoBounds(values, i), next_indent);
  end for;

  Print.printBuf("\n");
  Print.printBuf(indent);
  Print.printBuf("]");
end toStringPP_array;

function toStringPP_object
  input UnorderedMap<String, JSON> map;
  input String indent;
protected
  String next_indent = indent + "  ";
algorithm
  Print.printBuf("{");

  for i in 1:UnorderedMap.size(map) loop
    Print.printBuf(if i == 1 then "\n" else ",\n");
    Print.printBuf(next_indent);
    Print.printBuf("\"");
    Print.printBuf(UnorderedMap.keyAt(map, i));
    Print.printBuf("\": ");
    toStringPP_work(UnorderedMap.valueAt(map, i), next_indent);
  end for;

  Print.printBuf("\n");
  Print.printBuf(indent);
  Print.printBuf("}");
end toStringPP_object;

function toStringPP_listObject
  input list<tuple<String, JSON>> object;
  input String indent;
protected
  Boolean first = true;
  String key;
  JSON value;
  String next_indent = indent + "  ";
algorithm
  Print.printBuf("{\n");

  for entry in listReverse(object) loop
    (key, value) := entry;

    if first then
      first := false;
    else
      Print.printBuf(",\n");
    end if;

    Print.printBuf(next_indent);
    Print.printBuf("\"");
    Print.printBuf(key);
    Print.printBuf("\": ");
    toStringPP_work(value, next_indent);
  end for;

  Print.printBuf("\n");
  Print.printBuf(indent);
  Print.printBuf("}");
end toStringPP_listObject;

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
    case LIST_OBJECT()
      algorithm
        b := false;
        for entry in obj.values loop
          if Util.tuple21(entry) == str then
            b := true;
          end if;
        end for;
      then
        b;
  end match;
end hasKey;

function get
  input JSON obj;
  input String str;
  output JSON out;
algorithm
  out := match obj
    case OBJECT() then UnorderedMap.getOrFail(str, obj.values);
    case LIST_OBJECT()
      algorithm
        for entry in obj.values loop
          if Util.tuple21(entry) == str then
            out := Util.tuple22(entry);
            return;
          end if;
        end for;
      then
        fail();
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
    case LIST_OBJECT()
      algorithm
        for entry in obj.values loop
          if Util.tuple21(entry) == str then
            out := Util.tuple22(entry);
            return;
          end if;
        end for;
      then
        default;
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
    case LIST_OBJECT() then listReverse(getString(Util.tuple22(v)) for v in obj.values);
    case ARRAY() then Vector.mapToList(obj.values, getString);
  end match;
end getStringList;

function getKeys
  input JSON obj;
  output list<String> keys;
algorithm
  keys := match obj
    case OBJECT() then UnorderedMap.keyList(obj.values);
    case LIST_OBJECT() then listReverse(Util.tuple21(e) for e in obj.values);
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
    case LIST_OBJECT() then listLength(obj.values);
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
