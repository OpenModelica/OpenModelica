package TemplCG

import Print;
import Error;
import Util;
import System;

public type TemplateTreeSequence = list<TemplateTree>;

uniontype TemplateTree
  record TEMPLATE_COND
    list<KeyBody> cond_bodies;
    TemplateTreeSequence else_body;
  end TEMPLATE_COND;

  record TEMPLATE_FOR_EACH
    String key;
    String separator;
    TemplateTreeSequence body;
  end TEMPLATE_FOR_EACH;

  record TEMPLATE_RECURSION
    String key;
    String indent;
  end TEMPLATE_RECURSION;

  record TEMPLATE_ADD_INDENTATION
    String indent;
    TemplateTreeSequence body;
  end TEMPLATE_ADD_INDENTATION;

  record TEMPLATE_LOOKUP_KEY
    String key;
  end TEMPLATE_LOOKUP_KEY;

  record TEMPLATE_CURRENT_VALUE
  end TEMPLATE_CURRENT_VALUE;

  record TEMPLATE_TEXT
    String text;
  end TEMPLATE_TEXT;

  record TEMPLATE_INDENT
  end TEMPLATE_INDENT;

end TemplateTree;

uniontype Environment

  record ENV_STRING_LIST
    list<String> strings;
  end ENV_STRING_LIST;

  record ENV_DICT_LIST
    list<DictItemList> dicts;
  end ENV_DICT_LIST;

  record ENV_NULL
  end ENV_NULL;

end Environment;

uniontype Dict
  record ENABLED
  end ENABLED;

  record STRING_LIST
    list<String> strings;
  end STRING_LIST;

  record STRING
    String string;
  end STRING;

  record DICTIONARY
    DictItemList dict;
  end DICTIONARY;

  record DICTIONARY_LIST
    list<DictItemList> dict;
  end DICTIONARY_LIST;
end Dict;

record DictItem
  String key;
  Dict dict;
end DictItem;
type TemplDict = list<DictItemList>;
type DictItemList = list<DictItem>;

record TemplateInclude
  String key;
  TemplateTreeSequence body;
end TemplateInclude;

record KeyBody
  String key;
  Boolean negateValue;
  TemplateTreeSequence body;
end KeyBody;

public function Unescape
  input String str;
  input String indent;
  output String out;
algorithm
  out := Unescape2(stringListStringChar(str),indent);
end Unescape;

protected function Unescape2
  input list<String> str;
  input String indent;
  output String out;
algorithm
  out := matchcontinue(str,indent)
    local
      String char;
      list<String> rest;
    case ({},_) then "";
    case ("\\"::"n"::rest,indent) then "\n" +& Unescape2(rest,indent);
    case (char::rest,indent) then char+&Unescape2(rest,indent);
  end matchcontinue;
end Unescape2;

protected function GetTemplateInclude
  input list<TemplateInclude> includes;
  input String key;
  output TemplateTreeSequence body;
algorithm
  body := matchcontinue (includes,key)
  local
    list<TemplateInclude> rest;
    String thisKey;
    TemplateTreeSequence res;
    case ({},_) then fail();
    case (TemplateInclude(thisKey,res)::rest,key) equation
      true = thisKey ==& key;
    then res;
    case (_::rest,key) then GetTemplateInclude(rest,key);
  end matchcontinue;
end GetTemplateInclude;

public function PrintDict
  input DictItemList dict;
  input String indent;
algorithm
  _ := matchcontinue(dict,indent)
    local
      Dict item;
      DictItemList rest;
      String key;
    case ({},_) then ();
    case (DictItem(key,item)::rest,indent) equation
      print(indent);
      print(key +& ": ");
      PrintDictItem(item, indent);
      PrintDict(rest,indent);
    then ();
  end matchcontinue;
end PrintDict;

public function PrintDictList
  input list<DictItemList> dict;
  input String indent;
algorithm
  _ := matchcontinue(dict,indent)
    local
      DictItemList item;
      list<DictItemList> rest;
      String key;
    case ({},_) then ();
    case (item::rest,indent) equation
      PrintDict(item,indent);
      print("\n");
      PrintDictList(rest,indent);
    then ();
  end matchcontinue;
end PrintDictList;

protected function PrintDictItem
  input Dict dict;
  input String indent;
algorithm
  _ := matchcontinue(dict,indent)
    local
      DictItemList d;
      list<DictItemList> dl;
    case (ENABLED(),indent) equation
      print("ENABLED\n");
    then ();
    case (STRING(_),indent) equation
      print("STRING\n");
    then ();
    case (STRING_LIST(_),indent) equation
      print("STRING_LIST\n");
    then ();
    case (DICTIONARY(d),indent) equation
      print("DICTIONARY\n");
      PrintDict(d, indent+&"  ");
    then ();
    case (DICTIONARY_LIST(dl),indent) equation
      print("DICTIONARY_LIST\n");
      PrintDictList(dl,indent+&"  ");
    then ();
  end matchcontinue;
end PrintDictItem;

public function PrintTemplateTreeSequence
  input TemplateTreeSequence tree;
algorithm
  print("{\n");
  PrintTemplateTreeSequence_(tree, "  ");
  print("\n}");
end PrintTemplateTreeSequence;

protected function PrintTemplateTreeSequence_
  input TemplateTreeSequence tree;
  input String indentLevel;
algorithm
  _ := matchcontinue(tree,indentLevel)
    local
      TemplateTree element;
      TemplateTreeSequence rest;
    case ({},_) then ();
    case (element :: {},indentLevel) equation
      PrintTemplateTree(element,indentLevel);
    then ();
    case (element :: rest,indentLevel) equation
      PrintTemplateTree(element,indentLevel);
      print(",\n");
      PrintTemplateTreeSequence_(rest,indentLevel);
    then ();
  end matchcontinue;
end PrintTemplateTreeSequence_;

protected function PrintTemplateCond
  input list<KeyBody> bodies;
  input String indentLevel;
algorithm
  _ := matchcontinue(bodies,indentLevel)
    local
      String key;
      TemplateTreeSequence body;
      list<KeyBody> rest;
      Boolean negateValue;
    case ({},_) then ();
    case (KeyBody(key,negateValue,body)::rest,indentLevel) equation
      key = Util.stringReplaceChar(key,"\"","\\\"");
      print(indentLevel +& "TemplCG.KeyBody(\"" +& key +& "\",");
      print(Util.if_(negateValue,"true","false"));
      print(",{\n");
      PrintTemplateTreeSequence_(body,"  " +& indentLevel);
      print("\n" +& indentLevel +& "})");
      print(Util.if_(listLength(rest) == 1, ",\n", "\n"));
    then ();
  end matchcontinue;
end PrintTemplateCond;

protected function PrintTemplateTree
  input TemplateTree element;
  input String indentLevel;
algorithm
  _ := matchcontinue(element,indentLevel)
    local
      String key, sep, text;
      TemplateTreeSequence body,if_body,else_body;
      list<KeyBody> condBodies;
    case (TEMPLATE_COND(condBodies, else_body = else_body),indentLevel) equation
      print(indentLevel +& "TemplCG.TEMPLATE_COND({\n");
      PrintTemplateCond(condBodies, indentLevel);
      print(indentLevel +& "}, /* else */ {\n");
      PrintTemplateTreeSequence_(else_body, "  " +& indentLevel);
      print("\n" +& indentLevel +& "} \n" +& indentLevel +& ")");
    then ();
    case (TEMPLATE_FOR_EACH(key = key, separator = sep, body = body),indentLevel) equation
      key = Util.stringReplaceChar(key,"\"","\\\"");
      sep = Util.stringReplaceChar(sep,"\"","\\\"");
      print(indentLevel +& "TemplCG.TEMPLATE_FOR_EACH(\"" +& key +& "\",\"" +& sep +& "\",{\n");
      PrintTemplateTreeSequence_(body, "  " +& indentLevel);
      print("\n" +& indentLevel +& "})");
    then ();
    case (TEMPLATE_RECURSION(key = key, indent = sep),indentLevel) equation
      key = Util.stringReplaceChar(key,"\"","\\\"");
      sep = Util.stringReplaceChar(sep,"\"","\\\"");
      print(indentLevel +& "TemplCG.TEMPLATE_RECURSION(\"" +& key +& "\",\"" +& sep +& "\")");
    then ();
    case (TEMPLATE_ADD_INDENTATION(indent = sep, body=body),indentLevel) equation
      sep = Util.stringReplaceChar(sep,"\"","\\\"");
      print(indentLevel +& "TemplCG.TEMPLATE_ADD_INDENTATION(\"" +& sep +& "\",{\n");
      PrintTemplateTreeSequence_(body, "  " +& indentLevel);
      print("\n" +& indentLevel +& "})");
    then ();
    case (TEMPLATE_LOOKUP_KEY(key = key),indentLevel) equation
      key = Util.stringReplaceChar(key,"\"","\\\"");
      print(indentLevel +& "TemplCG.TEMPLATE_LOOKUP_KEY(\"" +& key +& "\")");
    then ();
    case (TEMPLATE_CURRENT_VALUE(),indentLevel) equation
      print(indentLevel +& "TemplCG.TEMPLATE_CURRENT_VALUE()");
    then ();
    case (TEMPLATE_INDENT(),indentLevel) equation
      print(indentLevel +& "TemplCG.TEMPLATE_INDENT()");
    then ();
    case (TEMPLATE_TEXT(text = text),indentLevel) equation
      text = Util.stringReplaceChar(text,"\\","\\\\");
      text = Util.stringReplaceChar(text,"\"","\\\"");
      text = Util.stringReplaceChar(text,"\n","\\n");
      print(indentLevel +& "TemplCG.TEMPLATE_TEXT(\"" +& text +& "\")");
    then ();
  end matchcontinue;
end PrintTemplateTree;

public function CompileTemplateFromFile
  input String templateFileName;
  input list<TemplateInclude> includes;
  output TemplateTreeSequence out;
algorithm
  out := matchcontinue (templateFileName,includes)
  local
    String template,error;
    list<String> templateNoComments;
    TemplateTreeSequence out;
  case (templateFileName,includes) equation
    template = System.readFile(templateFileName);
    (templateNoComments,error) = RemoveComments(stringListStringChar(template),0);
    error = Util.if_(error ==& "", "", "\nError: " +& error);
    print(error);
    true = error ==& "";

    (out,error) = CompileTemplate_Angles(templateNoComments, includes);
    error = Util.if_(error ==& "", "", "\nError: " +& error);
    print(error);
    true = error ==& "";
  then out;

  case (templateFileName,_) equation
    print("Parsing template " +& templateFileName +& " failed");
  then fail();
  end matchcontinue;
end CompileTemplateFromFile;

public function CompileTemplate
  input String template;
  input list<TemplateInclude> includes;
  output TemplateTreeSequence out;
algorithm
  out := CompileTemplate_Old(stringListStringChar(template), includes);
end CompileTemplate;

protected function RemoveComments
  input list<String> template;
  input Integer numNested;
  output list<String> out;
  output String error;
algorithm
  (out,error) := matchcontinue (template,numNested)
    local
      String char,error;
      list<String> out,rest;
    case ({},_) then ({},"");
    case (rest as "!"::">"::_,0) equation
      error = flattenStringList(rest);
      error = "Unbalanced comment tag: " +& error;
    then ({},error);
    case ("<"::"!"::rest,numNested) equation
      (out,error) = RemoveComments(rest,numNested+1);
    then (out,error);
    case ("!"::">"::rest,numNested) equation
      (out,error) = RemoveComments(rest,numNested-1);
    then (out,error);
    case (char::rest,numNested as 0) equation
       (out,error) = RemoveComments(rest,numNested);
    then (char::out, error);
    case (char::rest,numNested) equation
       (out,error) = RemoveComments(rest,numNested);
    then (out, error);

  end matchcontinue;
end RemoveComments;

protected function FindAngleBody
  input list<String> template;
  input Integer numNested;
  input String opener;
  input String closer;
  output list<String> body;
  output list<String> afterBody;
algorithm
  (body,afterBody) := matchcontinue(template,numNested,opener,closer)
    local
      String char;
      list<String> rest, afterBody, out;
    case ({},_,_,_) then fail();

    case ("\\"::char::rest, numNested, opener, closer) equation
      (out,afterBody) = FindAngleBody(rest, numNested, opener, closer);
    then ("\\"::char::out,afterBody);

    case (char::rest, 0, _, closer) equation
      true = char ==& closer;
      //print("\nFound closer: " +& char);
    then ({},rest);

    case (char::rest,numNested, opener, closer) equation
      false = char ==& "\\";
      //print("\n" +& intString(numNested));
      numNested = Util.if_(char ==& opener, numNested+1, numNested);
      numNested = Util.if_(char ==& closer, numNested-1, numNested);
      //print(" " +& intString(numNested) +& ": " +& char);
      (out,afterBody) = FindAngleBody(rest, numNested, opener, closer);
    then (char::out,afterBody);
  end matchcontinue;
end FindAngleBody;

protected function FindAngleBodyKey
  input list<String> template;
  output list<String> key;
  output list<String> afterKey;
algorithm
  (body,afterKey) := matchcontinue(template)
    local
      String char;
      list<String> rest, afterKey, out;
    case ({}) then ({},{});
    case (":"::rest) then ({},rest);
    case ("t"::"h"::"e"::"n"::rest) then ({},rest);

    case (" "::rest) equation
      ({},afterKey) = FindAngleBodyKey(rest);
    then ({},afterKey);
    case ("\n"::rest) equation
      ({},afterKey) = FindAngleBodyKey(rest);
    then ({},afterKey);

    case (char::rest) equation
      false = char ==& "<"; false = char ==& ">";
      false = char ==& "{"; false = char ==& "}";
      false = char ==& " "; false = char ==& "\n";
      (out,afterKey) = FindAngleBodyKey(rest);
    then (char::out,afterKey);
  end matchcontinue;
end FindAngleBodyKey;

protected function SkipCommentBody
  input list<String> template;
  output list<String> out;
algorithm
  (out) := matchcontinue(template)
    local
      String char;
      list<String> rest, afterKey, out;
    case ({}) equation
      Error.addMessage(Error.TEMPLCG_INVALID_TEMPLATE, {"Failed to end comment"});
    then fail();
    case ("!"::">"::rest) then rest;
    case (char::rest) then SkipCommentBody(rest);
  end matchcontinue;
end SkipCommentBody;

protected function SkipWhitespace
  input list<String> template;
  output list<String> out;
algorithm
  out := matchcontinue(template)
  local
    list<String> rest;
    case {} then {};
    case " "::rest then SkipWhitespace(rest);
    case "\n"::rest then SkipWhitespace(rest);
    case rest then rest;
  end matchcontinue;
end SkipWhitespace;

protected function FindAngleSep
  input list<String> afterBody;
  output String sep;
algorithm
  sep := matchcontinue (afterBody)
  local
    String error;
    case (afterBody) then FindAngleSep2(afterBody,0);
    case (afterBody) equation
      error = flattenStringList(afterBody);
      error = "FindAngleSep failed: " +& error;
      Error.addMessage(Error.TEMPLCG_INVALID_TEMPLATE, {error}); then fail();
  end matchcontinue;
end FindAngleSep;

protected function FindAngleSep2
  input list<String> afterBody;
  input Integer state;
  output String sep;
algorithm
  sep := matchcontinue (afterBody, state)
  local
    String char, sep;
    list<String> rest;
    case ({},0) then "";
    case ({},2) then "";
    case ("\n"::rest,state) then FindAngleSep2(rest,state); // Ignore \n in a separator, use \\n to enter newline
    case ("\""::rest,0) then FindAngleSep2(rest,1);
    case ("\""::rest,1) then FindAngleSep2(rest,2);
    case (char::rest,1) then char+&FindAngleSep2(rest,1);
    case (" "::rest,state) then FindAngleSep2(rest,state);
  end matchcontinue;
end FindAngleSep2;

protected function CompileTemplate_Angles_CondBody
  input list<String> template;
  input list<TemplateInclude> includes;
  output TemplateTree out;
  output String error;
algorithm
  out := matchcontinue(template,includes)
    local
      String key,error1,error2,error3,body,firstChar;
      list<String> keyList1,keyList2,rest, template, body, afterBody, caseBody, shouldBeWhitespace;
      list<TemplateInclude> includes;
      TemplateTreeSequence elseBody, bodySeq;
      list<KeyBody> condBodies;
      Boolean negateValue;
    case ({},includes) then (TEMPLATE_COND({},{}),"");
    case ("\n" :: rest,includes) equation
      (out,error) = CompileTemplate_Angles_CondBody(rest,includes);
    then (out,error);
    case (" " :: rest,includes) equation
      (out,error) = CompileTemplate_Angles_CondBody(rest,includes);
    then (out,error);

    case ("c"::"a"::"s"::"e"::rest,includes) equation
      (keyList1 as firstChar::keyList2,caseBody) = FindAngleBodyKey(SkipWhitespace(rest));
      negateValue = firstChar ==& "!";
      keyList1 = Util.if_(negateValue, keyList2, keyList1);
      key = flattenStringList(keyList1);
      false = key ==& "_";
      "{"::caseBody = SkipWhitespace(caseBody);
      (caseBody,afterBody) = FindAngleBody(caseBody, 0, "{", "}");
      (bodySeq,error1) = CompileTemplate_Angles(caseBody, includes);
      (TEMPLATE_COND(condBodies,elseBody),error2) = CompileTemplate_Angles_CondBody(afterBody,includes);
      error1 = Util.if_(error1 ==& "", error2, error1);
    then (TEMPLATE_COND(KeyBody(key,negateValue,bodySeq)::condBodies,elseBody),error1);

    case ("c"::"a"::"s"::"e"::rest,includes) equation
      ({"_"},caseBody) = FindAngleBodyKey(SkipWhitespace(rest));
      "{"::caseBody = SkipWhitespace(caseBody);
      (caseBody,afterBody) = FindAngleBody(caseBody, 0, "{", "}");
      (bodySeq,error1) = CompileTemplate_Angles(caseBody, includes);
      (TEMPLATE_COND({},{}),error2) = CompileTemplate_Angles_CondBody(afterBody,includes);
      error1 = Util.if_(error1 ==& "", error2, error1);
    then (TEMPLATE_COND({},bodySeq),error1);

    case ("e"::"l"::"s"::"e"::rest,includes) equation
      "{"::caseBody = SkipWhitespace(rest);
      (caseBody,afterBody) = FindAngleBody(caseBody, 0, "{", "}");
      (bodySeq,error1) = CompileTemplate_Angles(caseBody, includes);
      (TEMPLATE_COND({},{}),error2) = CompileTemplate_Angles_CondBody(afterBody,includes);
      error1 = Util.if_(error1 ==& "", error2, error1);
    then (TEMPLATE_COND({},bodySeq),error1);

    case (rest as "c"::"a"::"s"::"e"::_,_)
    then (TEMPLATE_COND({},{}),flattenStringList(rest));
    case (rest as "e"::"l"::"s"::"e"::_,_)
    then (TEMPLATE_COND({},{}),flattenStringList(rest));

    case (rest,_)
    then (TEMPLATE_COND({},{}),flattenStringList(rest));
  end matchcontinue;
end CompileTemplate_Angles_CondBody;

protected function CompileTemplate_Angles_Body
  input String key;
  input list<String> template;
  input list<TemplateInclude> includes;
  output TemplateTreeSequence out;
  output String error;
algorithm
  out := matchcontinue(key,template,includes)
    local
      String key,sep,error;
      list<String> rest, template, body, afterBody;
      list<TemplateInclude> includes;
      TemplateTreeSequence bodySeq;
      TemplateTreeSequence out;
    case (key, {}, includes) equation
      //print("\nFound simple FOR_EACH, no template to apply");
    then ({TEMPLATE_FOR_EACH(key, "", {TEMPLATE_LOOKUP_KEY("it")})},"");
    case (key, "{" :: rest, includes) equation
      (body,afterBody) = FindAngleBody(rest, 0, "{", "}");
      //print("\nbody=");
      //print(flattenStringList(body));
      sep = FindAngleSep(afterBody);
      (bodySeq,error) = CompileTemplate_Angles(body,includes);
    then ({TEMPLATE_FOR_EACH(key, sep, bodySeq)},error);
    case (key, (rest as "{" :: _), includes)
    then ({},flattenStringList(rest));
    case (key, " " :: rest, includes) equation
      (out,error) = CompileTemplate_Angles_Body(key, rest, includes);
    then (out,error);
    case (key, "\n" :: rest, includes) equation
      (out,error) = CompileTemplate_Angles_Body(key, rest, includes);
    then (out,error);
    case (_, rest, _) then ({},flattenStringList(rest));
  end matchcontinue;
end CompileTemplate_Angles_Body;

protected function CompileTemplate_Angles
  input list<String> template;
  input list<TemplateInclude> includes;
  output TemplateTreeSequence out;
  output String error;
algorithm
  (out,error) := matchcontinue(template,includes)
    local
      String error, error2, key, char, sep, keyAndSep, textBody, newTextBody;
      list<String> keyList, rest, body, afterBody;
      TemplateTreeSequence out,out2,nextBody;
      TemplateTree condBody,newBody;
      list<TemplateInclude> includes;
    case ({},_) then ({},"");

    case ("<"::"c"::"o"::"n"::"d"::rest,includes) equation
      (body,afterBody) = FindAngleBody(rest, 0, "<", ">");
      (condBody,error) = CompileTemplate_Angles_CondBody(body,includes);
      (out,error2) = CompileTemplate_Angles(afterBody,includes);
      error = Util.if_(error ==& "", error2, error);
    then (condBody::out,error);
    case (rest as "<"::"c"::"o"::"n"::"d"::_,includes) equation
    then ({},flattenStringList(rest));

    case ("<"::"i"::"n"::"c"::"l"::"u"::"d"::"e"::rest,includes) equation
      (body,afterBody) = FindAngleBody(rest, 0, "<", ">");
      key = FindAngleSep(body);
      out = CompileTemplateFromFile(key,includes);
      (out2,error) = CompileTemplate_Angles(afterBody,includes);
    then (listAppend(out,out2),error);
    case (rest as "<"::"i"::"n"::"c"::"l"::"u"::"d"::"e"::_,includes) equation
    then ({},flattenStringList(rest));

    case ("<"::rest,includes) equation
      (body,afterBody) = FindAngleBody(rest, 0, "<", ">");
      //print("\nForEach full body=");
      //print(flattenStringList(body));
      (keyList,rest) = FindAngleBodyKey(body);
      key = flattenStringList(keyList);
      //print("\nForEach body=");
      //print(flattenStringList(rest));
      //print("\nForEach afterBody=");
      //print(flattenStringList(afterBody));
      (nextBody,error) = CompileTemplate_Angles_Body(key,rest,includes);
      (out,error2) = CompileTemplate_Angles(afterBody,includes);
      error = Util.if_(error ==& "", error2, error);
      out = listAppend(nextBody,out);
    then (out,error);
    case ("<":: rest,includes) equation
    then ({},flattenStringList(rest));

    case ("\\" :: "n" :: rest, includes) equation
      (out,error) = CompileTemplate_Angles(rest,includes);
    then (TEMPLATE_TEXT("\n") :: TEMPLATE_INDENT() :: out,error);
    case ("\n" :: rest, includes) equation
    (out,error) = CompileTemplate_Angles(rest,includes);
    then (out,error);

    case ("\\" :: char :: rest, includes) equation
      (TEMPLATE_TEXT(text = textBody) :: nextBody,error) = CompileTemplate_Angles(rest, includes);
      newTextBody = char +& textBody;
    then
      (TEMPLATE_TEXT(newTextBody) :: nextBody,error);
    case ("\\" :: char :: rest, includes) equation
    (out,error) = CompileTemplate_Angles(rest,includes);
    then (TEMPLATE_TEXT(char)::out,error);

    case (char :: rest, includes) equation
      false = char ==& "<"; false = char ==& ">";
      false = char ==& "{"; false = char ==& "}";
      (TEMPLATE_TEXT(text = textBody) :: nextBody,error) = CompileTemplate_Angles(rest, includes);
      newTextBody = char +& textBody;
    then
      (TEMPLATE_TEXT(newTextBody) :: nextBody, error);
    case (char :: rest, includes) equation
      false = char ==& "<"; false = char ==& ">";
      false = char ==& "{"; false = char ==& "}";
      (nextBody,error) = CompileTemplate_Angles(rest, includes);
    then
      (TEMPLATE_TEXT(char) :: nextBody,error);

    case (rest, _) equation
      error = flattenStringList(rest);
    then ({},error);
  end matchcontinue;
end CompileTemplate_Angles;

protected function CompileTemplate_Old
  input list<String> template;
  input list<TemplateInclude> includes;
  output TemplateTreeSequence out;
algorithm
  out := matchcontinue(template,includes)
    local
      String char, key, sep, keyAndSep, textBody, newTextBody;
      list<String> rest, afterBody;
      TemplateTreeSequence body, newBody;
      list<TemplateInclude> includes;
    case ({},_) then {};
    case ("$" :: "=" :: rest,includes) equation
      (key,body,newBody) = FindKeyAndBody(rest, "=", includes);
    then
      TEMPLATE_COND({KeyBody(key,false,body)},{}) :: newBody;
    case ("$" :: "!" :: rest, includes) equation
      (key,body,newBody) = FindKeyAndBody(rest, "!", includes);
    then
      TEMPLATE_COND({KeyBody(key,true,body)},{}) :: newBody;
    case ("$" :: "#" :: rest, includes) equation
      (keyAndSep,body,newBody) = FindKeyAndBody(rest, "#", includes);
      (sep,key) = FindSepAndVar(stringListStringChar(keyAndSep),"","");
    then
      TEMPLATE_FOR_EACH(key,sep,body) :: newBody;
    case ("$" :: "t" :: "h" :: "i" :: "s" :: "$" :: rest, includes) equation
      newBody = CompileTemplate_Old(rest, includes);
    then
      TEMPLATE_CURRENT_VALUE() :: newBody;
    case ("$" :: "_" :: rest, includes) equation
      (sep,body,newBody) = FindKeyAndBody(rest, "_", includes);
    then
      TEMPLATE_ADD_INDENTATION(sep,body) :: newBody;
    case ("$" :: "^" :: rest, includes) equation
      (keyAndSep,afterBody) = FindKey(rest, "");
      (sep,key) = FindSepAndVar(stringListStringChar(keyAndSep),"","");
      newBody = CompileTemplate_Old(afterBody, includes);
    then
      TEMPLATE_RECURSION(key,sep) :: newBody;
    case ("$" :: ":" :: rest, includes) equation
      (key,afterBody) = FindKey(rest, "");
      body = GetTemplateInclude(includes, key);
      newBody = CompileTemplate_Old(afterBody, includes);
    then
      // Including a body opens a new scope; as does adding a 0-deep indentation level
      TEMPLATE_ADD_INDENTATION("", body) :: newBody;
    case ("$" :: char :: rest, includes) equation
      false = (char ==& "^");
      false = (char ==& "_");
      false = (char ==& "=");
      false = (char ==& "!");
      false = (char ==& "#");
      false = (char ==& ":");
      (key,afterBody) = FindKey(char :: rest, "");
      newBody = CompileTemplate_Old(afterBody, includes);
    then
      TEMPLATE_LOOKUP_KEY(key) :: newBody;

    case ((rest as "$" :: _), includes) equation
      textBody = flattenStringList(rest);
      textBody = "Couldn't match $: " +& textBody;
      Error.addMessage(Error.TEMPLCG_INVALID_TEMPLATE, {textBody});
    then fail();

    case ("\\" :: "n" :: rest, includes) equation
      newBody = CompileTemplate_Old(rest, includes);
    then
      TEMPLATE_TEXT("\n") :: TEMPLATE_INDENT() :: newBody;
    case ("\n" :: rest, includes) then
      CompileTemplate_Old(rest, includes);
    case (char :: rest, includes) equation
      false = char ==& "$";
      TEMPLATE_TEXT(text = textBody) :: body = CompileTemplate_Old(rest, includes);
      newTextBody = char +& textBody;
    then
      TEMPLATE_TEXT(newTextBody) :: body;
    case (char :: rest, includes) equation
      false = char ==& "$";
      newBody = CompileTemplate_Old(rest, includes);
    then
      TEMPLATE_TEXT(char) :: newBody;
  end matchcontinue;
end CompileTemplate_Old;

protected function FindKey
  input list<String> template;
  input String keyAcc;
  output String key;
  output list<String> afterKey;
algorithm
  (key,afterKey) := matchcontinue(template, keyAcc)
    local
      String char, out;
      list<String> rest, afterKey;
    case ({},keyAcc) then fail();
    case ("$" :: rest,keyAcc) then (keyAcc, rest);
    case ("\n" :: rest,keyAcc) equation
      (out,afterKey) = FindKey(rest, keyAcc);
    then
      (out,afterKey);
    case (char :: rest,keyAcc) equation
      (out,afterKey) = FindKey(rest, keyAcc+&char);
    then
      (out,afterKey);
  end matchcontinue;
end FindKey;

protected function FindKeyAndBody
  input list<String> template;
  input String scopeEndChar; // "!", "=", "#"
  input list<TemplateInclude> includes;
  output String key;
  output TemplateTreeSequence body;
  output TemplateTreeSequence afterBody;
algorithm
  (body,afterKey) := matchcontinue(template,scopeEndChar,includes)
    local
      String key;
      list<String> afterKey, afterBody, bodyAcc;
      list<TemplateInclude> includes;
    case(template,scopeEndChar,includes) equation
      (key,afterKey) = FindKey(template, "");
      (bodyAcc,afterBody) = FindBody(afterKey,scopeEndChar,0);
    then (key,CompileTemplate_Old(bodyAcc,includes),CompileTemplate_Old(afterBody,includes));
  end matchcontinue;
end FindKeyAndBody;

protected function FindBody
  input list<String> template;
  input String scopeEndChar; // "!", "=", "#"
  input Integer numNested;
  output list<String> body;
  output list<String> afterKey;
algorithm
  (body,afterKey) := matchcontinue(template,scopeEndChar,numNested)
    local
      String char;
      list<String> rest, afterKey, out;
    case ({},_,_) then fail();
    case ("$" :: char :: rest, scopeEndChar, numNested) equation
      true = scopeEndChar ==& char;
      (out,afterKey) = FindBodySkipToEnd(rest, scopeEndChar, numNested+1);
    then ("$"::char::out,afterKey);
    case ("$" :: "/" :: char :: rest, scopeEndChar, 0) equation
      true = scopeEndChar ==& char;
    then ({},rest);
    case ("$" :: "/" :: char :: rest, scopeEndChar, numNested) equation
      true = scopeEndChar ==& char;
      (out,afterKey) = FindBody(rest, scopeEndChar, numNested-1);
    then ("$"::"/"::char::out,afterKey);
    case (char :: rest, scopeEndChar, numNested) equation
      (out,afterKey) = FindBody(rest, scopeEndChar, numNested);
    then
      (char::out,afterKey);
  end matchcontinue;
end FindBody;

protected function FindBodySkipToEnd
  input list<String> template;
  input String scopeEndChar; // "!", "=", "#"
  input Integer numNested;
  output list<String> body;
  output list<String> afterKey;
algorithm
  (body,afterKey) := matchcontinue(template,scopeEndChar,numNested)
    local
      String char;
      list<String> rest, afterKey, out;
    case ("$" :: rest,scopeEndChar,numNested) equation
      (out,afterKey) = FindBody(rest, scopeEndChar, numNested);
    then ("$"::out,afterKey);
    case (char :: rest,scopeEndChar,numNested) equation
      (out,afterKey) = FindBodySkipToEnd(rest, scopeEndChar, numNested);
    then (char::out,afterKey);
  end matchcontinue;
end FindBodySkipToEnd;

protected function Lookup
  input TemplDict dict;
  input String key;
  input Environment curEnv;
  output Dict value;
protected
  list<String> split;
algorithm
  split := Util.stringSplitAtChar(key, ".");
  value := LookupCheckForIt(dict, split, curEnv);
end Lookup;

protected function LookupCheckForIt
  input TemplDict dict;
  input list<String> keys;
  input Environment curEnv;
  output Dict value;
algorithm
  value := matchcontinue (dict,keys,curEnv)
    local
      String key,string;
      list<String> rest;
      DictItemList newDict;
      list<DictItemList> dicts;
      TemplDict dict;
    case ({},_, _) then
      fail();
    case (_, "it" :: {}, curEnv) equation
      ENV_STRING_LIST(strings = string :: _) = curEnv;
    then STRING(string);
    case (_, "it" :: rest, curEnv) equation
      ENV_DICT_LIST(dicts = dicts) = curEnv;
      newDict = Util.listFirst(dicts);
      dict = {{DictItem("", DICTIONARY(newDict))}};
    then Lookup2(dict,rest);
    case (dict, rest, _) then Lookup2(dict, rest);
  end matchcontinue;
end LookupCheckForIt;

protected function Lookup2
  input TemplDict dict;
  input list<String> keys;
  output Dict value;
algorithm
  value := matchcontinue (dict,keys)
    local
      String key;
      list<String> rest;
      DictItemList newDict;
    case ({},_) then
      fail();
    case (dict, key :: {}) then
      GetDictItem_(dict,key);
    case (dict, key :: rest) equation
      DICTIONARY(dict = newDict) = GetDictItem_(dict,key);
    then
      Lookup2({newDict}, rest);
  end matchcontinue;
end Lookup2;

protected function GetDictItem_
  input TemplDict dict;
  input String key;
  output Dict value;
algorithm
  value := matchcontinue (dict,key)
    local
      DictItemList curDict;
      TemplDict rest;
    case ({}, _) // equation
      // Error.addMessage(Error.DICT_NO_SUCH_KEY, {key});
    then
      fail();
    case (curDict :: rest, key) then GetDictItem2(curDict,key);
    case (curDict :: rest, key) then GetDictItem_(rest,key);
  end matchcontinue;
end GetDictItem_;

protected function GetDictItem2
  input DictItemList dict;
  input String key;
  output Dict value;
algorithm
  value := matchcontinue (dict,key)
    local
      Dict res;
      DictItemList rest;
      String lkey;
    case ({}, _) then fail();
    case (DictItem(key = lkey, dict = res) :: rest, key) equation
      true = (key ==& lkey); then res;
    case (_ :: rest, key) equation then GetDictItem2(rest,key);
  end matchcontinue;
end GetDictItem2;

public function ApplyCompiledTemplate
  input DictItemList dict;
  input TemplateTreeSequence tree;
algorithm
  ApplyCompiledTemplate_({dict},tree,ENV_NULL(),tree,"","");
end ApplyCompiledTemplate;

protected function IsEmpty "(Successfully looked up) values that are empty:
  empty DICTIONARY_LIST {}
  empty STRING_LIST {}
  empty STRING \"\"
  "
  input Dict value;
  output Boolean out;
algorithm
  out := matchcontinue(value)
  case STRING("") then true;
  case STRING_LIST({}) then true;
  case DICTIONARY_LIST({}) then true;
  case _ then false;
  end matchcontinue;
end IsEmpty;

protected function ApplyCompiledTemplate_Cond
  input TemplDict dict;
  input list<KeyBody> restBodies;
  input TemplateTreeSequence elseBody;
  input Environment curEnv;
  input String sep;
  input String indent;
algorithm
  _ := matchcontinue (dict,restBodies,elseBody,curEnv,sep,indent)
    local
      Dict value;
      String key;
      TemplateTreeSequence elseBody,body;
    case (dict, {}, elseBody, curEnv, sep, indent) equation
      ApplyCompiledTemplate_(dict,elseBody,ENV_NULL(),elseBody,sep,indent);
    then ();

    /* IF_EXIST */
    case (dict, KeyBody(key,false,body)::restBodies, elseBody, curEnv, sep, indent) equation
      value = Lookup(dict,key,curEnv);
      false = IsEmpty(value);
      ApplyCompiledTemplate_(dict,body,ENV_NULL(),body,sep,indent);
    then ();

    /* IF_NOT_EXIST */
    case (dict, KeyBody(key,true,body)::restBodies, elseBody, curEnv, sep, indent) equation
      failure(_ = Lookup(dict,key,curEnv));
      ApplyCompiledTemplate_(dict,body,ENV_NULL(),body,sep,indent);
    then ();
    case (dict, KeyBody(key,true,body)::restBodies, elseBody, curEnv, sep, indent) equation
      value = Lookup(dict,key,curEnv);
      true = IsEmpty(value);
      ApplyCompiledTemplate_(dict,body,ENV_NULL(),body,sep,indent);
    then ();

    case (dict, _::restBodies, elseBody, curEnv, sep, indent) equation
      ApplyCompiledTemplate_Cond(dict,restBodies,elseBody,curEnv,sep,indent);
    then ();

  end matchcontinue;
end ApplyCompiledTemplate_Cond;

protected function ApplyCompiledTemplate_ForEach
  input Dict value;
  input TemplDict dict;
  input TemplateTreeSequence body;
  input Environment curEnv;
  input String sep;
  input String indent;
algorithm
  _ := matchcontinue (value,dict,body,curEnv,sep,indent)
    local
      list<String> strings;
      String string;
      DictItemList dictionary;
      Dict value;
      TemplDict dicts;
      Boolean isEmpty;
    case (STRING(string = string), dict, body, curEnv, sep, indent) equation
      ApplyCompiledTemplate_(dict,body,ENV_STRING_LIST({string}),body,sep,indent);
    then ();
    case (STRING_LIST(strings = strings), dict, body, curEnv, sep, indent) equation
      ApplyCompiledTemplate_(dict,body,ENV_STRING_LIST(strings),body,sep,indent);
    then ();
    case (DICTIONARY(dict = dictionary), dict, body, curEnv, sep, indent) equation
      ApplyCompiledTemplate_(dictionary :: dict,body,ENV_DICT_LIST({dictionary}),body,sep, indent);
    then ();
    case (DICTIONARY_LIST(dict = dicts), dict, body, curEnv, sep, indent) equation
      dictionary = Util.listFirst(dicts);
      ApplyCompiledTemplate_(dictionary :: dict,body,ENV_DICT_LIST(dicts),body,sep,indent);
    then ();
    case (DICTIONARY_LIST(dict = {}), dict, body, curEnv, sep, indent) then ();
  end matchcontinue;
end ApplyCompiledTemplate_ForEach;

protected function ApplyCompiledTemplate_
  input TemplDict dict;
  input TemplateTreeSequence tree;
  input Environment curEnv;
  input TemplateTreeSequence treeCopy;
  input String sep;
  input String indent;
algorithm
  _ := matchcontinue(dict,tree,curEnv,treeCopy,sep,indent)
    local
      TemplateTree first;
      TemplateTreeSequence rest, body, else_body;
      list<String> strings, envRest;
      String string, var, key, separator;
      DictItemList dictionary, dictEnv, dictEnvNext, topCurDict;
      Dict value;
      TemplDict dicts, dictEnvRest, restCurDict;
      list<KeyBody> restBodies;

      Boolean isEmpty;
      // Looping over ENV_STRING_LIST
    case (_, _, ENV_STRING_LIST( {} ), _, _, _) then ();
    case (_, {}, ENV_STRING_LIST( var :: {} ), _, _, _) then ();
    case (dict, {}, ENV_STRING_LIST(var :: envRest), treeCopy, sep, indent) equation
      Print.printBuf(sep);
      ApplyCompiledTemplate_(dict, treeCopy, ENV_STRING_LIST(envRest), treeCopy, sep, indent);
    then ();

      // Looping over ENV_DICT_LIST
    case (_, {}, ENV_DICT_LIST( {} ), _, _, _) then ();
    case (_, {}, ENV_DICT_LIST( dictEnv :: {} ), _, _, _) then ();
    case (topCurDict :: restCurDict, {}, ENV_DICT_LIST(dictEnv :: dictEnvNext :: dictEnvRest), treeCopy, sep, indent) equation
      Print.printBuf(sep);
      ApplyCompiledTemplate_(dictEnvNext :: restCurDict, treeCopy, ENV_DICT_LIST(dictEnvNext :: dictEnvRest), treeCopy, sep, indent);
    then ();

      // Looping over ENV_NULL
    case (_, {}, ENV_NULL(), _, _, _) then ();

      // Input for current iteration
    case (dict, TEMPLATE_TEXT(text = string) :: rest, curEnv, treeCopy, sep, indent) equation
      Print.printBuf(string);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();
    case (dict, TEMPLATE_ADD_INDENTATION(indent = string, body = body) :: rest, curEnv, treeCopy, sep, indent) equation
      ApplyCompiledTemplate_(dict,body,ENV_NULL(),body,sep, string+&indent);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();
    case (dict, TEMPLATE_LOOKUP_KEY(key = key) :: rest, curEnv, treeCopy, sep, indent) equation
      STRING(string = string) = Lookup(dict,key,curEnv);
      Print.printBuf(string);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();
    case (dict, TEMPLATE_CURRENT_VALUE() :: rest, curEnv, treeCopy, sep, indent) equation
      ENV_STRING_LIST(strings = strings) = curEnv;
      string = Util.listFirst(strings);
      Print.printBuf(string);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();

    case (dict, TEMPLATE_INDENT() :: rest, curEnv, treeCopy, sep, indent) equation
      Print.printBuf(indent);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();

    case (dict, TEMPLATE_COND(cond_bodies = restBodies, else_body = else_body) :: rest, curEnv, treeCopy, sep, indent) equation
      ApplyCompiledTemplate_Cond(dict,restBodies,else_body,curEnv,sep,indent);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep,indent);
    then ();

    case (dict, TEMPLATE_FOR_EACH(key = key, separator = separator, body = body) :: rest, curEnv, treeCopy, sep, indent) equation
      value = Lookup(dict,key,curEnv);
      separator = Unescape(separator, indent);
      ApplyCompiledTemplate_ForEach(value,dict,body,curEnv,separator,indent);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();

    case (topCurDict :: dict, TEMPLATE_RECURSION(key = key, indent = string) :: rest, curEnv, treeCopy, sep, indent) equation
      DICTIONARY(dict = dictionary) = Lookup(topCurDict::dict,key,curEnv);
      ApplyCompiledTemplate_(dictionary :: dict,treeCopy,ENV_NULL(),treeCopy,sep, indent+&string);
      ApplyCompiledTemplate_(topCurDict :: dict,rest,curEnv,treeCopy,sep, indent);
    then ();
    case (dict, TEMPLATE_RECURSION(key = key, indent = string) :: rest, curEnv, treeCopy, sep, indent) equation
      DICTIONARY_LIST(dict = {}) = Lookup(dict,key,curEnv);
      ApplyCompiledTemplate_(dict,rest,curEnv,treeCopy,sep, indent);
    then ();
    case (topCurDict :: dict, TEMPLATE_RECURSION(key = key, indent = string) :: rest, curEnv, treeCopy, sep, indent) equation
      DICTIONARY_LIST(dict = dicts) = Lookup(topCurDict::dict,key,curEnv);
      dictionary = Util.listFirst(dicts);
      ApplyCompiledTemplate_(dictionary :: dict,treeCopy,ENV_DICT_LIST(dicts),treeCopy,sep, indent+&string);
      ApplyCompiledTemplate_(topCurDict :: dict,rest,curEnv,treeCopy,sep, indent);
    then ();

    // Failures
    case (_, TEMPLATE_LOOKUP_KEY(key = key) :: rest, _, _, _, _) equation
      string = "LOOKUP_KEY(" +& key +& ")";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();
    case (_, TEMPLATE_CURRENT_VALUE() :: rest, _, _, _, _) equation
      string = "CURRENT_VALUE()";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();
    case (_, TEMPLATE_ADD_INDENTATION(indent = string) :: rest, _, _, _, _) equation
      string = "ADD_INDENTATION()";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();
    case (_, TEMPLATE_COND(_,_) :: rest, _, _, _, _) equation
      string = "COND()";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();
    case (_, TEMPLATE_FOR_EACH(key = key) :: rest, _, _, _, _) equation
      string = "FOR_EACH(" +& key +& ")";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();
    case (_, TEMPLATE_RECURSION(key = key) :: rest, _, _, _, _) equation
      string = "RECURSION(" +& key +& ")";
      Error.addMessage(Error.TEMPLCG_FAILED_TO_APPLY_TEMPLATE, {string});
    then fail();

    /*case (dict, tree, _, _, _, _) equation
      print("Failed to apply compiled template: \n");
      PrintTemplateTreeSequence(tree);
      print("Dictionaries used: \n");
      PrintDictList(dict, "");
    then fail();*/
  end matchcontinue;
end ApplyCompiledTemplate_;

// Generic Utility functions
protected function FindSepAndVar
  input list<String> inStr;
  input String sepAcc;
  input String varAcc;
  output String sep;
  output String var;
algorithm
  (sep,var) := matchcontinue (inStr, sepAcc, varAcc)
    local
      list<String> rest;
      String char;
    case ({},sepAcc,varAcc) then (sepAcc,varAcc);
    case ("#" :: char :: rest, "", varAcc) equation
      (sep,var) = FindSepAndVar(rest, char, varAcc);
    then
      (sep,var);
    case (char :: rest, "", varAcc) equation
      (sep,var) = FindSepAndVar(rest, "", varAcc +& char);
    then
      (sep,var);
    case (char :: rest, sepAcc, varAcc) equation
      (sep,var) = FindSepAndVar(rest, sepAcc +& char, varAcc);
    then
      (sep,var);
  end matchcontinue;
end FindSepAndVar;

protected function flattenStringList
  input list<String> lst;
  output String out;
algorithm
  out := matchcontinue lst
    local
      String char;
      list<String> rest;
    case {} then "";
    case char :: rest then char +& flattenStringList(rest);
  end matchcontinue;
end flattenStringList;


end TemplCG;
