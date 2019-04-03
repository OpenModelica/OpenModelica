encapsulated package OMCCTypes
import Absyn;
import INFO = Absyn.INFO;
import List;
import System;

uniontype Token
  record TOKEN
    String name;
    Integer id;
    String fileContents;
    Integer byteOffset,length;
    Integer lineNumberStart;
    Integer columnNumberStart;
    Integer lineNumberEnd;
    Integer columnNumberEnd;
  end TOKEN;

end Token;

constant Token noToken = TOKEN("",-1,"",0,0,0,0,0,0);

type Info = Absyn.Info;

function getTimeStamp
  output Absyn.TimeStamp timeStamp;
algorithm
  timeStamp := Absyn.dummyTimeStamp;
end getTimeStamp;

function printToken
  input Token token;
  output String strTk;
protected
  String tokName,contents;
  Integer idtk,lns,cns,lne,cne,byteOffset,length;
  Info info;
algorithm
  TOKEN(name=tokName,id=idtk,lineNumberStart=lns,columnNumberStart=cns,lineNumberEnd=lne,columnNumberEnd=cne) := token;
  contents := getStringValue(token);

  strTk := "[TOKEN:" + tokName + " '" +  contents + "' (" + intString(lns) + ":" + intString(cns) + "-"+ intString(lne) + ":" + intString(cne) +")]";
end printToken;

function makeInfo
  input Token tok;
  input String fileName;
  output Info info;
protected
  Integer lns,cns,lne,cne;
algorithm
  TOKEN(lineNumberStart=lns,columnNumberStart=cns,lineNumberEnd=lne,columnNumberEnd=cne) := tok;
  info := Absyn.INFO(fileName,false,lns,cns,lne,cne,Absyn.dummyTimeStamp);
end makeInfo;

function getStringValue
  input Token tok;
  output String str;
protected
  String contents;
  Integer byteOffset,length;
algorithm
  TOKEN(fileContents=contents,byteOffset=byteOffset,length=length) := tok;
  str := if length>0 then substring(contents,byteOffset,byteOffset+length-1) else "";
end getStringValue;

function getMergeTokenValue
  input Token token1;
  input Token token2;
  output String value;
algorithm
  value := getStringValue(token1) + getStringValue(token2);
end getMergeTokenValue;

function printErrorToken
  input Token token;
  output String strTk;
algorithm
  strTk := "'" +  getStringValue(token) + "'";
end printErrorToken;

function readLine "Reads a line of text from a file and returns it in a string"
  input String fileName;
  input Integer lineNumber(min=1);
  output String string "Line of text";
  output Boolean endOfFile "If true, end-of-file was reached when trying to read line";
external "C" string=  ModelicaInternal_readLine(fileName,lineNumber,endOfFile) annotation(Library="ModelicaExternalC");
end readLine;

function printErrorLine // TODO: Make this print the context of the error... Getting line before and after can be done efficiently
  input Token token;
  output String strTk;
  protected
  Token token1:=token;
  String tokName,fileNm;
  String str,str1,str2;
  Integer idtk,lns,cns,lne,cne,errline;
  Boolean b;
  Info info;
algorithm
  strTk := "'" + getStringValue(token)  + "'";
end printErrorLine;

function printErrorLine2 = printErrorLine; // TODO: Make this print the context of the error...

function printInfoError
  input Info info;
  output String strTk;
  protected
  Info info1:=info;
  String tokName,fileNm;
  Integer idtk,lns,cns,lne,cne;
 algorithm
  INFO(fileName=fileNm,lineNumberStart=lns,columnNumberStart=cns,lineNumberEnd=lne,columnNumberEnd=cne) := info;
  strTk := fileNm + ":" + intString(lns) + ":" + intString(cns) ;
end printInfoError;

function printShortToken
  input Token token;
  output String strTk;
algorithm
  strTk := "'" +  getStringValue(token) +"'";
end printShortToken;

function printShortToken2
  input Token token;
  output String strTk;
protected
  Token token1:=token;
  String tokName;
  Integer idtk,lns,cns,lne,cne;
  Info info;
algorithm
  TOKEN(name=tokName,id=idtk,loc=info) := token1;
  INFO(lineNumberStart=lns,columnNumberStart=cns,lineNumberEnd=lne,columnNumberEnd=cne) := info;

  strTk := "[" + tokName + " '" +  getStringValue(token) +"']";
end printShortToken2;

function printTokens
    input list<Token> inList;
    input String cBuff;
    output String outList;
    protected
    list<Token> inList1:=inList;
    Token c;
   algorithm
     outList := "";
     while (List.isEmpty(inList1)==false) loop
       c::inList1 := inList1;
       outList := outList + printToken(c);
     end while;
  end printTokens;

 function countTokens
    input list<Token> inList;
    input Integer sValue;
    output Integer outTotal;
    protected
    list<Token> inList1:=inList;
   algorithm
     //printAny("\nhere1");
    (outTotal) := match(inList,sValue)
      local
        Token c;
        Integer new,tout;
        list<Token> rest;
      case ({},_)
        then (sValue+1);
      else
        equation
           //printAny("\nhere2");
           c::rest = inList1;
           //printAny("\nhere3");
           new = sValue + 1;
           (tout) = countTokens(rest,new);
        then (tout);
     end match;
     //printAny("\nhere4");
  end countTokens;

function printBuffer
  input list<Integer> inList;
  input String cBuff;
  output String outList;
  protected
  list<Integer> inList1:=inList;
algorithm
  (outList) := match(inList,cBuff)
    local
      Integer c;
      String new,tout;
      list<Integer> rest;
    case ({},_)
    then (cBuff);
      else
      equation
        c::rest = inList1;
        new = cBuff + intStringChar(c);
        (tout) = printBuffer(rest,new);
      then (tout);
  end match;
end printBuffer;

end OMCCTypes;
