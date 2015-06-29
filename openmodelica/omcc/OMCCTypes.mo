encapsulated package OMCCTypes

replaceable type TokenType = Integer;
replaceable constant TokenType noTokenConst = -1;

uniontype Token
  record TOKEN
    String name;
    TokenType id; // Is Integer for Bison, enumeration for pure flex
    String fileContents;
    Integer byteOffset,length;
    Integer lineNumberStart;
    Integer columnNumberStart;
    Integer lineNumberEnd;
    Integer columnNumberEnd;
  end TOKEN;
end Token;

constant Token noToken = TOKEN("",noTokenConst,"",0,0,0,0,0,0);

function printToken
  input Token token;
  output String strTk;
protected
  String tokName,contents;
  Integer idtk,lns,cns,lne,cne,byteOffset,length;
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
  info := SOURCEINFO(fileName,false,lns,cns,lne,cne,Absyn.dummyTimeStamp);
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

function printShortToken
  input Token token;
  output String strTk;
algorithm
  strTk := "'" +  getStringValue(token) +"'";
end printShortToken;

end OMCCTypes;
