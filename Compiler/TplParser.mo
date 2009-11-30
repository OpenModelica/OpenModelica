package TplParser

public import System;
public import Debug;
public import Tpl;
public import Util;
public import TplAbsyn;

public constant Integer TabSpaces = 4;

public 
uniontype ParseInfo 
  record PARSE_INFO
    String fileName;
    list<String> errors;      
  end PARSE_INFO;
end ParseInfo;

public 
uniontype LineInfo 
  record LINE_INFO
    ParseInfo parseInfo;
    Integer lineNumber;
    Integer lineLength;
    list<String> startOfLineChars;    
  end LINE_INFO;
end LineInfo;


public function getPosition
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output Integer outLineNumber;
  output Integer outColumnNumber;
algorithm
  (outLineNumber,outColumnNumber)  := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      Integer lnum, llen, tillEnd;

    case (chars, LINE_INFO(lineNumber = lnum, lineLength = llen))
      equation
        tillEnd = charsTillEndOfLine(chars, 0);
      then (lnum, llen - tillEnd);    
  end matchcontinue;
end getPosition;


public function charsTillEndOfLine
  input list<String> inChars;
  input Integer inAccCount;
  output Integer outCharsTillEnd;
algorithm
  (outCharsTillEnd) := 
  matchcontinue (inChars, inAccCount)
    local
      list<String> chars;
      Integer accCount, i;
      String c;
    case (c :: chars, accCount)
      equation
        i = stringCharInt(c);
        true = (i == 10) or (i == 13); // \n or \r
      then accCount;
    
    case (c :: chars, accCount)
      then charsTillEndOfLine(chars, accCount + 1);
    
    case ({}, accCount)
      then accCount;
        
  end matchcontinue;
end charsTillEndOfLine;


public function makeStartLineInfo
  input list<String> inChars;
  input String inFileName;
  output LineInfo outLineInfo;
protected
  Integer llen;
algorithm
  llen := charsTillEndOfLine(inChars, 1);
  outLineInfo := LINE_INFO(PARSE_INFO(inFileName,{}), 1, llen, inChars);  
end makeStartLineInfo;



public function templPackageFromFile
  input  String inFile;
  output TplAbsyn.TemplPackage outTemplPackage;
algorithm
  (outTemplPackage) := matchcontinue (inFile)
    local
      String src, file;
      list<String> chars;
      TplAbsyn.TemplPackage templPackage;
    case (file)
        equation
          src = System.readFile(file);
          chars = stringListStringChar( src );
          (chars,_, templPackage) = templPackage(chars, makeStartLineInfo(chars, file));
        then templPackage;
    
    case (file) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.templPackageFromFile failed for file '" +& file +& "'.\n");
      then fail();

  end matchcontinue;
end templPackageFromFile;


public function typeviewDefsFromFile
  input  String inFile;
  input list<TplAbsyn.ASTDef> inAccASTDefs;
  
  output list<TplAbsyn.ASTDef> outASTDefs;
algorithm
  (outASTDefs) := matchcontinue (inFile, inAccASTDefs)
    local
      String file, src;
      list<String> chars;
      LineInfo linfo;
      list<TplAbsyn.ASTDef> astDefs;
      
    case (file, astDefs)
      equation
        src = System.readFile(file);
        chars = stringListStringChar( src );
        linfo = makeStartLineInfo(chars, file);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs) = typeviewDefs(chars, linfo, astDefs);
        ({}, _) = interleave(chars, linfo); //TODO: to the end of the file check
      then (astDefs);            
    
    case (file,_) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.typeviewDefsFromFile failed for file '" +& file +& "'.\n");
      then fail();
                
  end matchcontinue;
end typeviewDefsFromFile;





/*
newLine:
	\r \n  //CR + LF ... Windows
	|
	\n     //CR only ... Linux
	|
	\r     //LF only ... Mac OS up to 9
*/
public function newLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      ParseInfo pinfo;
      String c;
      Integer lnum, llen, i;
    //CR + LF .. Windows
    case(c :: chars, LINE_INFO(parseInfo = pinfo, lineNumber = lnum))
      equation
        13 = stringCharInt(c);   // \r
        ("\n" :: chars) = chars; // \n
        llen = charsTillEndOfLine(chars, 1); //1 is colum number of the first character, so count it
        lnum = lnum + 1;
      then (chars, LINE_INFO(pinfo, lnum, llen, chars));
    
    //LF only ... Linux
    //or CR only - Mac OS up to 9
    case (c :: chars, LINE_INFO(parseInfo = pinfo, lineNumber = lnum))
      equation
        i = stringCharInt(c);
        true = (i == 10) or (i == 13); // \n or \r
        llen = charsTillEndOfLine(chars, 1); //1 is colum number of the first character, so count it
        lnum = lnum + 1;
      then (chars, LINE_INFO(pinfo, lnum, llen, chars)); 
    
  end matchcontinue;
end newLine;

/*
// interleave will be applied before every token
interleave:  //i.e. space / comment
	[' '\n\r\t] interleave
	|
	'//' toEndOfLine  interleave
	|
	'/''*' comment  interleave
	|
	_ //just nothing
*/
public function interleave
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c;
    case (" "  :: chars, linfo) 
      equation
        (chars, linfo) =  interleave(chars, linfo);
      then (chars, linfo);
    case ("\t" :: chars, linfo) 
      equation
        (chars, linfo) =  interleave(chars, linfo);
      then (chars, linfo);
    case ("/" :: "/" :: chars, linfo) 
      equation
        (chars, linfo) = toEndOfLine(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo);
    case ("/" :: "*" :: chars, linfo) 
      equation
        (chars, linfo) = comment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo);
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
      then (chars, linfo); 
    
    case (chars, linfo) then (chars, linfo);
    
  end matchcontinue;
end interleave;



/*
toEndOfLine:
    \n
    |
    eof  //end of stream ~ {}
    |
    any  toEndOfLine //any is any character
*/
public function toEndOfLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue(inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
      then (chars, linfo);
    case (_ :: chars, linfo)
      equation
        (chars, linfo) = toEndOfLine(chars, linfo);
      then (chars, linfo);
    case ({}, linfo) then ({},linfo);
  end matchcontinue;
end toEndOfLine;


//comment:
//	'*''/' 
//	|
//	'/''*' comment comment  //nesting is possible
//	|
//	any  comment

public function comment
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    case ("*" :: "/" :: chars, linfo) then (chars, linfo);
    case ("/" :: "*" :: chars, linfo) 
      equation
        (chars, linfo) = comment(chars,linfo);
        (chars, linfo) = comment(chars,linfo);
      then (chars, linfo);
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (chars, linfo) = comment(chars,linfo);
      then (chars, linfo);
    case (_ :: chars, linfo) 
      equation
        (chars, linfo) = comment(chars,linfo);
      then (chars, linfo);
    case ({}, linfo) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.comment - unmatched /* */ comment - reached end of file.\n");
      then ({}, linfo);
  end matchcontinue;
end comment;

/*
//afterKeyword must not fail after every keyword to be considered as keyword 
afterKeyword:
    [_0-9A-Za-z]  =>  fail  // if it can be an identifier/other keyword
    |
    _  => ()
*/

public function afterKeyword
  input list<String> inChars;
algorithm
  _ := matchcontinue inChars
    local
      list<String> chars;
      String c;
      Integer i;

    case (c :: _) 
      equation
        i = stringCharInt(c);
        //[_0-9A-Za-z]
        false = (i == 95/*_*/) 
            or ( 48/*0*/ <= i and i <= 57/*9*/) 
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/);             
      then ();
    
    case ({}) then ();
            
  end matchcontinue;
end afterKeyword;

/*
identifier:
	[_A-Za-z]:c  identifier_rest:rest     =>  string_char_list_string(c::rest)
*/
public function identifier
  input list<String> inChars;

  output list<String> outChars;
  output TplAbsyn.Ident outIdent;
algorithm
  (outChars, outIdent) := matchcontinue inChars
    local
      list<String> chars, restIdChars;
      String c, ident;
      Integer i;

    case (c :: chars) 
      equation
        i = stringCharInt(c);
        //[_A-Za-z]
        true = (i == 95/*_*/) 
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/);
        (chars, restIdChars) = identifier_rest(chars);
        ident = string_char_list_string(c :: restIdChars);
      then (chars, ident);
          
  end matchcontinue;
end identifier;

/*
identifier_rest:
    [_0-9A-Za-z]:c  identifier_rest:rest  =>  c::rest
    |
	_  =>  {}
*/
public function identifier_rest
  input list<String> inChars;

  output list<String> outChars;
  output list<String> outRestIdentChars;
algorithm
  (outChars, outRestIdentChars) := matchcontinue inChars
    local
      list<String> chars, restIdChars;
      String c;
      Integer i;

    case (c :: chars) 
      equation
        i = stringCharInt(c);
        //[_0-9A-Za-z]
        true = (i == 95/*_*/) 
            or ( 48/*0*/ <= i and i <= 57/*9*/) 
            or ( 65/*A*/ <= i and i <= 90/*Z*/)
            or ( 97/*a*/ <= i and i <= 122/*z*/);
        (chars, restIdChars) = identifier_rest(chars);        
      then (chars, c :: restIdChars);
    
    case chars then (chars, {});
       
  end matchcontinue;
end identifier_rest;


/*
pathIdent:
	identifier:head  pathIdentPath(head):pid => pid 
*/
public function pathIdent
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPathIdent;
algorithm
  (outChars, outLineInfo, outPathIdent) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, restIdChars;
      LineInfo linfo;
      String head;
      TplAbsyn.PathIdent pid;
      
    case (chars, linfo) 
      equation
        (chars, head) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdentPath(chars, linfo, head);        
      then (chars, linfo, pid);
          
  end matchcontinue;
end pathIdent;

/*
pathIdentPath(head):
	'.' pathIdent:path  =>  PATH_IDENT(head, path)
	|
	_ =>  IDENT(head)
*/
public function pathIdentPath
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inHeadIdent;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.PathIdent outPathIdent;
algorithm
  (outChars, outLineInfo, outPathIdent) := matchcontinue (inChars, inLineInfo,inHeadIdent)
    local
      list<String> chars;
      LineInfo linfo;
      String head;
      TplAbsyn.PathIdent pid;
      
    case ("." :: chars, linfo, head) 
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdent(chars, linfo);        
      then (chars, linfo, TplAbsyn.PATH_IDENT(head, pid));
    
    case (chars, linfo, head) 
      then (chars, linfo, TplAbsyn.IDENT(head));
        
  end matchcontinue;
end pathIdentPath;


/*
templPackage:
	'spackage'  pathIdent:pid  stringComment
		definitions(pid,{},{}):(astDefs,templDefs)
	endDefPathIdent(pid)	
	=> 	TEMPL_PACKAGE(pid, astDefs,templDefs)
*/
public function templPackage
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TemplPackage outTemplPackage;
algorithm
  (outChars, outLineInfo, outTemplPackage) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent pid;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      list<TplAbsyn.ASTDef> astDefs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> templDefs;
    
    case (chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);        
        ("s"::"p"::"a"::"c"::"k"::"a"::"g"::"e":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, pid) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs,templDefs) = definitions(chars, linfo,{},{}); 
        astDefs = listReverse(astDefs);                      
        templDefs = listReverse(templDefs);                      
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefPathIdent(chars, linfo,pid);       
      then (chars, linfo, TplAbsyn.TEMPL_PACKAGE(pid, astDefs,templDefs));
    
    case (chars, linfo)
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.templPackage failed.\n");
      then fail(); 
        //(chars, linfo, TplAbsyn.TEMPL_PACKAGE(TplAbsyn.IDENT("Tpl failed"),{},{}) );
                
  end matchcontinue;
end templPackage;
/*
definitions(astDefs,templDefs):
	'typeview' stringConstant:strRevList 
	  { ads = typeviewDefsFromFile(stringAppendList(listReverse(strRevList), astDefs) }
	  definitions(ads, templDefs):(ads,tds) 
	  => (ads,tds)
	| 
	absynDef:ad  definitions(ad::astDefs,templDefs):(ads,tds) => (ads,tds)
	|
	templDef:(name, td)  definitions(astDefs,(name,td)::templDefs):(ads,tds) => (ads,tds)
//	|
//	error "Expecting 'end' | ['public' | 'protected' ] 'package' definition | template definition starting with an identifier."
*/
public function definitions
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.ASTDef> inAccASTDefs;
  input list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> inAccTemplDefs;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.ASTDef> outASTDefs;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> outTemplDefs;
algorithm
  (outChars, outLineInfo, outASTDefs, outTemplDefs) := matchcontinue (inChars, inLineInfo, inAccASTDefs, inAccTemplDefs)
    local
      list<String> chars, strRevList;
      String str;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id, name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      TplAbsyn.ASTDef ad;
      TplAbsyn.TemplateDef td;
      list<TplAbsyn.ASTDef> astDefs;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TemplateDef>> templDefs;
    
    case ("t"::"y"::"p"::"e"::"v"::"i"::"e"::"w":: chars, linfo, astDefs, templDefs)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        str = Util.stringAppendList(listReverse(strRevList));
        astDefs = typeviewDefsFromFile(str, astDefs);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs) = definitions(chars, linfo, astDefs, templDefs);
      then (chars, linfo, astDefs, templDefs);
        
    // **** to be deleted, only 'typeview' imports will be used (likely)
    case (chars, linfo, astDefs, templDefs)
      equation
        (chars, linfo, ad) = absynDef(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs) = definitions(chars, linfo, ad::astDefs, templDefs);                                     
      then (chars, linfo, astDefs, templDefs);
    
    case (chars, linfo, astDefs,templDefs)
      equation
        (chars, linfo, name, td) = templDef(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs, templDefs) = definitions(chars, linfo, astDefs, (name,td)::templDefs);                                     
      then (chars, linfo, astDefs, templDefs);
    
    case (chars, linfo, astDefs, templDefs)
      then (chars, linfo, astDefs, templDefs);
                
  end matchcontinue;
end definitions;

/*
typeviewDefs(astDefs):
	absynDef:ad  typeviewDefs(ad::astDefs):ads => ads
	|
	_ => astDefs
*/
public function typeviewDefs
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<TplAbsyn.ASTDef> inAccASTDefs;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.ASTDef> outASTDefs;
algorithm
  (outChars, outLineInfo, outASTDefs) := matchcontinue (inChars, inLineInfo, inAccASTDefs)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.ASTDef ad;
      list<TplAbsyn.ASTDef> astDefs;
      
    case (chars, linfo, astDefs)
      equation
        (chars, linfo, ad) = absynDef(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, astDefs) = typeviewDefs(chars, linfo, ad::astDefs);                                     
      then (chars, linfo, astDefs);
    
    case (chars, linfo, astDefs)
      then (chars, linfo, astDefs);
    
  end matchcontinue;
end typeviewDefs;


/*
typeSig:
    typeSig_base:base  typeSig_array(base):ts  => ts
*/
public function typeSig
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature baseTS, ts;
      
    case (chars, linfo) 
      equation
        (chars, linfo, baseTS) = typeSig_base(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig_array(chars, linfo, baseTS);        
      then (chars, linfo, ts);
    
  end matchcontinue;
end typeSig;

/*
typeSig_base:
	'list' '<' typeSig:tof '>'  =>  LIST_TYPE(tof)
	|
	'Option' '<' typeSig '>'   =>  OPTION_TYPE(tof)
	|
	'tuple' '<' typeSig:ts  typeSig_restList:restLst  '>'  => TUPLE_TYPE(ts::restLst)
	|
	pathIdent:pid  =>  NAMED_TYPE(pid)  // +specializations for String, Integer, .... => STRING_TYPE(), ... 
*/
public function typeSig_base
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts, tof;
      list<TplAbsyn.TypeSignature> restLst;
      TplAbsyn.PathIdent pid;
      
    case ("l"::"i"::"s"::"t" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("<" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (">" :: chars) = chars;               
      then (chars, linfo, TplAbsyn.LIST_TYPE(tof));
    
    case ("O"::"p"::"t"::"i"::"o"::"n" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("<" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (">" :: chars) = chars;               
      then (chars, linfo, TplAbsyn.OPTION_TYPE(tof));
    
    case ("t"::"u"::"p"::"l"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("<" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tof) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, restLst) = typeSig_restList(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (">" :: chars) = chars;               
      then (chars, linfo, TplAbsyn.TUPLE_TYPE(tof::restLst));
    
    case (chars, linfo)
      equation
        (chars, linfo, pid) = pathIdent(chars, linfo);
        ts = typeSigFromPathIdent(pid);                       
      then (chars, linfo, ts);    
        
  end matchcontinue;
end typeSig_base;

/*
typeSig_array(base):
	'[' ':' ']'  typeSig_array(ARRAY_TYPE(base)):ts   =>  ts
	|
	_  =>  base
*/
public function typeSig_array
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.TypeSignature inBaseTypeSignature;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outChars, outLineInfo, outTypeSignature) := matchcontinue (inChars, inLineInfo, inBaseTypeSignature)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts, baseTS;
      
    case ("[" :: chars, linfo, baseTS)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (":" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        ("]" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig_array(chars, linfo, TplAbsyn.ARRAY_TYPE(baseTS));
      then (chars, linfo, ts);
    
    case (chars, linfo, baseTS) then (chars, linfo, baseTS);
    
  end matchcontinue;
end typeSig_array;

/*
typeSig_restList:
    ',' typeSig:ts  typeSig_restList:restLst  =>  ts::restLst
    |
    _  => {}
*/
public function typeSig_restList
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.TypeSignature> outTypeSignatureList;
algorithm
  (outChars, outLineInfo, outTypeSignatureList) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      TplAbsyn.TypeSignature ts;
      list<TplAbsyn.TypeSignature> tsLst;
      
    case ("," :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, tsLst) = typeSig_restList(chars, linfo);                       
      then (chars, linfo, ts::tsLst);
    
    case (chars, linfo) then (chars, linfo, {});

  end matchcontinue;
end typeSig_restList;


public function typeSigFromPathIdent
  input TplAbsyn.PathIdent inPathIdent;
  output TplAbsyn.TypeSignature outTypeSignature;
algorithm
  (outTypeSignature) := matchcontinue (inPathIdent)
    local
      TplAbsyn.PathIdent pid;
      
    case (TplAbsyn.IDENT("String") )  then TplAbsyn.STRING_TYPE();
    case (TplAbsyn.IDENT("Integer") ) then TplAbsyn.INTEGER_TYPE();
    case (TplAbsyn.IDENT("Real") )    then TplAbsyn.REAL_TYPE();
    case (TplAbsyn.IDENT("Boolean") ) then TplAbsyn.BOOLEAN_TYPE();
    
    case (pid) then TplAbsyn.NAMED_TYPE(pid);
                 
  end matchcontinue;    
end typeSigFromPathIdent;

/*
publicProtected:
	'public' => true
	|
	'protected' => false
	|
	_ => true
*/
public function publicProtected
  input list<String> inChars;

  output list<String> outChars;
  output Boolean outIsDefault;
algorithm
  (outChars, outIsDefault) := matchcontinue (inChars)
    local
      list<String> chars;
      
    case ("p"::"u"::"b"::"l"::"i"::"c" :: chars)
      equation
        afterKeyword(chars);
      then (chars, true);
    
    case ("p"::"r"::"o"::"t"::"e"::"c"::"t"::"e"::"d" :: chars)
      equation
        afterKeyword(chars);
      then (chars, false);
    
    case (chars) then (chars, true);

  end matchcontinue;
end publicProtected;	

/*
stringComment:
	'"' stringCommentRest
	|
	_ 
*/
public function stringComment
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      
    case ("\"" :: chars, linfo)
      equation
        (chars, linfo) = stringCommentRest(chars, linfo);
      then (chars, linfo);
    
    case (chars, linfo) then (chars, linfo);

  end matchcontinue;
end stringComment;
/*
stringCommentRest:
	'\\"' stringCommentRest
	|
	'\\' stringCommentRest
	|
	~'"' stringCommentRest
	|
	'"'
*/
public function stringCommentRest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    
    case ("\"" :: chars, linfo)
      then (chars, linfo);
          
    case ("\\"::"\"" :: chars, linfo)
      equation
        (chars, linfo) = stringCommentRest(chars, linfo);
      then (chars, linfo);
    
    case ("\\"::"\\" :: chars, linfo)
      equation
        (chars, linfo) = stringCommentRest(chars, linfo);
      then (chars, linfo);
    
    case (chars, linfo)
      equation
        (chars, linfo) = newLine(chars, linfo); 
        (chars, linfo) = stringCommentRest(chars, linfo);
      then (chars, linfo);
        
    case (_ :: chars, linfo)
      equation
        (chars, linfo) = stringCommentRest(chars, linfo);
      then (chars, linfo);
    
    case ( {}, linfo ) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.stringCommentRest - unmatched \" \" comment - reached end of file.\n");
      then ( {}, linfo );

  end matchcontinue;
end stringCommentRest;


public function semicolon
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      
   case (";":: chars, linfo)
     then (chars, linfo);
   
   case (chars, linfo)
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.semicolon - expected semicolon ';' .\n");                
      then (chars, linfo);
   
  end matchcontinue;
end semicolon;
/*
absynDef:
	publicProtected:isD  'package' pathIdent:pid  stringComment 
	  absynTypes:types
	endDefPathIdent(pid) 
	=>  AST_DEF(pid, isD, types)
*/
public function absynDef
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.ASTDef outASTDef;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
    
    case (chars, linfo)
      equation
        (chars, isD) = publicProtected(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("p"::"a"::"c"::"k"::"a"::"g"::"e" :: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        
        (chars, linfo,pid) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, types) = absynTypes(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefPathIdent(chars, linfo,pid);        
      then (chars, linfo, TplAbsyn.AST_DEF(pid,isD,types));

  end matchcontinue;
end absynDef;

/*
endDefPathIdent(pid):
	'end' pathIdent:pidEnd ';' // pid == pidEnd | warning
*/
public function endDefPathIdent
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inPathIdentToMatch;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inPathIdentToMatch)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid, pidToMatch;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
    
    case ("e"::"n"::"d" :: chars, linfo, pidToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo,pid) = pathIdent(chars, linfo);
        equality(pid = pidToMatch);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);
   
   case ("e"::"n"::"d" :: chars, linfo, pidToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo,pid) = pathIdent(chars, linfo);
        failure(equality(pid = pidToMatch));
        Debug.fprint("failtrace", "Parse warning - TplParser.endDefPathIdent - unmatched ident for 'end' of the definition of '" +& TplAbsyn.pathIdentString(pidToMatch) +& "' ... 'end " +& TplAbsyn.pathIdentString(pid) +& "' found instead.\n");        
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);
   
   //case (chars, linfo, pidToMatch)
   //  equation
   //     Debug.fprint("failtrace", "Parse error - TplParser.endDefPathIdent - other part or an end of the definition of " +& TplAbsyn.pathIdentString(pidToMatch) +& " expected.\n");        
   //  then (chars, linfo);
   
  end matchcontinue;
end endDefPathIdent;

/*
endDefIdent(id):
	'end' identifier:idEnd ';' // id == idEnd | warning
*/
public function endDefIdent
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inIdentToMatch;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo, inIdentToMatch)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id, idToMatch;
      
    case ("e"::"n"::"d" :: chars, linfo, idToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars,id) = identifier(chars);
        equality(id = idToMatch);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);
   
   case ("e"::"n"::"d" :: chars, linfo, idToMatch)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars,id) = identifier(chars);
        failure(equality(id = idToMatch));
        Debug.fprint("failtrace", "Parse warning - TplParser.endDefIdent - unmatched ident for 'end' of the definition of " +& idToMatch +& " ... end " +& id +& " found instead.\n");        
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);
      then (chars, linfo);
   
   //case (chars, linfo, idToMatch)
   //  equation
   //     Debug.fprint("failtrace", "Parse error - TplParser.endDefIdent - other part or an end of the definition of " +& idToMatch +& " expected.\n");        
   //  then (chars, linfo);
   
  end matchcontinue;
end endDefIdent;

/*
absynTypes:
	absynType:(id,ti)  absynTypes:types  => (id,ti) :: types
	|
	_ => {}
*/
public function absynTypes
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> outTypes;
algorithm
  (outChars, outLineInfo, outTypes) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
    
    case (chars, linfo)
      equation
        (chars, linfo, idti) = absynType(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, types) = absynTypes(chars, linfo);        
      then (chars, linfo, idti :: types);
   
   case (chars, linfo)
      then (chars, linfo,{});
   
  end matchcontinue;
end absynTypes;
/*
absynType:
	'uniontype' identifier:id  stringComment
	    recordTags(id):rtags	    
	=> (id, TI_UNION_TYPE(rtags))
	|
	recordType:(id,fields)
	=> (id, TI_RECORD_TYPE(fields))
	|
	'function' identifier:id  stringComment
		inputFunArgs:inArgs
		outputFunArgs:outArgs	  
	endDefIdent(id)
	=> (id, TI_FUN_TYPE(inArgs,outArgs))
	|
	'constant'  typeSig:ts  identifier:id  stringComment  ';'
	=> (id, TI_CONST_TYPE(ts))
	|
	'type' identifier:id '=' typeSig:ts stringComment  ';'
	=> (id, TI_ALIAS_TYPE(ts))	
*/
public function absynType
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> outType;
algorithm
  (outChars, outLineInfo, outType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case ("u"::"n"::"i"::"o"::"n"::"t"::"y"::"p"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo, rtags) = recordTags(chars, linfo,id);
        //(chars, linfo) = interleave(chars, linfo);
        //(chars, linfo) = endDefIdent(chars, linfo,id);        
      then (chars, linfo, (id, TplAbsyn.TI_UNION_TYPE(rtags)));
   
   case (chars, linfo)
      equation
        (chars, linfo, (id,fields)) = recordType(chars, linfo);             
      then (chars, linfo, (id, TplAbsyn.TI_RECORD_TYPE(fields)));
   
   case ("f"::"u"::"n"::"c"::"t"::"i"::"o"::"n":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo, inargs) = inputFunArgs(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, outargs) = outputFunArgs(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = endDefIdent(chars, linfo,id);        
      then (chars, linfo, (id, TplAbsyn.TI_FUN_TYPE(inargs,outargs)));
   
   case ("c"::"o"::"n"::"s"::"t"::"a"::"n"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo) = semicolon(chars, linfo);                
      then (chars, linfo, (id, TplAbsyn.TI_CONST_TYPE(ts)));

   case ("t"::"y"::"p"::"e":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("=" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo) = semicolon(chars, linfo);                
      then (chars, linfo, (id, TplAbsyn.TI_ALIAS_TYPE(ts)));
                
  end matchcontinue;
end absynType;

/*
recordType:
	'record' identifier:id  stringComment
	    typeDecls:tids
	'end' identifier:idEnd ';' // id == idEnd
	=> (id,tids)
*/
public function recordType
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> outRecordType;
algorithm
  (outChars, outLineInfo, outRecordType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case ("r"::"e"::"c"::"o"::"r"::"d":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo, fields) = typeDecls(chars, linfo,id);
        //(chars, linfo) = interleave(chars, linfo);
        //(chars, linfo) = endDefIdent(chars, linfo,id);        
      then (chars, linfo, (id, fields));
                
  end matchcontinue;
end recordType;
/*
typeDecls:
	typeSig:ts  identifier:id  stringComment ';'
	typeDecls:tids  
	=> (id,ts) :: tids
	|
	_ => {}
*/
public function typeDecls
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inRecordId;
   
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypeDecls;
algorithm
  (outChars, outLineInfo, outTypeDecls) := matchcontinue (inChars, inLineInfo,inRecordId)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id,rid;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case (chars, linfo,rid)
      equation
        (chars, linfo) = endDefIdent(chars, linfo,rid);
      then (chars, linfo, {} );
        
    case (chars, linfo,rid)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo) = semicolon(chars, linfo);        
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fields) = typeDecls(chars, linfo,rid);
      then (chars, linfo, (id,ts)::fields );
    
    case (chars, linfo, rid)
     equation
        Debug.fprint("failtrace", "Parse error - TplParser.typeDecls - other field declaration or an 'end' of the definition of " +& rid +& " record expected.\n");        
     then (chars, linfo, {} );
           
  end matchcontinue;
end typeDecls;
/*
recordTags:
	recordType:(id,tids)  recordTags:rtags  => (id,tids) :: rtags
	|
	_ => {}
*/
public function recordTags
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Ident inUnionTypeId;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> outRecordTags;
algorithm
  (outChars, outLineInfo, outRecordTags) := matchcontinue (inChars, inLineInfo,inUnionTypeId)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id, uid;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case (chars, linfo,uid)
      equation
        (chars, linfo) = endDefIdent(chars, linfo,uid);
      then (chars, linfo, {} );
        
    case (chars, linfo,uid)
      equation
        (chars, linfo, rtag) = recordType(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rtags) = recordTags(chars, linfo,uid);
      then (chars, linfo, rtag :: rtags);
    
    case (chars, linfo, uid)
     equation
        Debug.fprint("failtrace", "Parse error - TplParser.recordTags - other union tag declaration or an 'end' of the definition of " +& uid +& " union types expected.\n");        
     then (chars, linfo, {});
                
  end matchcontinue;
end recordTags;
/*
inputFunArgs:
	'input' typeSig:ts  identifier:id  stringComment
	inputFunArgs:iargs
	=> (id,ts) :: iargs
	|
	_ => {} 
*/
public function inputFunArgs
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypedIdents;
algorithm
  (outChars, outLineInfo, outTypedIdents) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case ("i"::"n"::"p"::"u"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);               
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, inargs) = inputFunArgs(chars, linfo);        
      then (chars, linfo, (id,ts) :: inargs);
    
    case (chars, linfo)
      then (chars, linfo, {} );
                
  end matchcontinue;
end inputFunArgs;
/*
outputFunArgs:
	'output' typeSig:ts  identifier:id  stringComment ';'
	outputFunArgs:oargs
	=> (id,ts) :: oargs
	|
	_ => {} 
*/
public function outputFunArgs
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outTypedIdents;
algorithm
  (outChars, outLineInfo, outTypedIdents) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
    
    case ("o"::"u"::"t"::"p"::"u"::"t":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = stringComment(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = semicolon(chars, linfo);               
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, outargs) = outputFunArgs(chars, linfo);        
      then (chars, linfo, (id,ts) :: outargs);
    
    case (chars, linfo)
      then (chars, linfo, {} );
                
  end matchcontinue;
end outputFunArgs;

/*
templDef:
    identifier:name  templDef_ConstOrTempl:td   =>  (name, td)
*/
public function templDef
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Ident outTemplName;
  output TplAbsyn.TemplateDef outTemplDef;
algorithm
  (outChars, outLineInfo, outTemplName, outTemplDef) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
    
    case (chars, linfo)
      equation
        (chars, name) = identifier(chars); 
        (chars, linfo) = interleave(chars, linfo);
        
        (chars, linfo,td) = templDef_ConstOrTempl(chars, linfo);
      then (chars, linfo, name, td);
  end matchcontinue;
end templDef;

/*
templDef_ConstOrTempl:
	'(' templArgs:args ')' templDef_AngleOrDolar:(exp,lesc,resc)  =>  TEMPLATE_DEF(args,lesc,resc,exp)
	|
	'=' constant:cdef  =>  cdef 

*/
public function templDef_ConstOrTempl
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TemplateDef outTemplDef;
algorithm
  (outChars, outLineInfo, outTemplDef) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc, str;
      list<String> chars, strRevList;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      Tpl.StringToken st;
      TplAbsyn.TypeSignature litType;
    
    case ("(" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (")"::chars) = chars;
        (chars, linfo) = interleave(chars, linfo);        
        (chars, linfo, exp,lesc,resc) = templDef_AngleOrDolar(chars, linfo);        
      then (chars, linfo, TplAbsyn.TEMPLATE_DEF(args,lesc,resc,exp));
    
    case ("=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        st = makeStrTokFromRevStrList(strRevList);
      then (chars, linfo, TplAbsyn.STR_TOKEN_DEF(st));
    
    case ("=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, str, litType) = literalConstant(chars, linfo);
      then (chars, linfo, TplAbsyn.LITERAL_DEF(str, litType));
            
  end matchcontinue;
end templDef_ConstOrTempl;


/*
templDef_AngleOrDolar:
	'::='  expression(LEsc = '<',REsc = '>'):exp   => (exp,'<','>')
	|
	'$$='  expression(LEsc = '$',REsc = '$'):exp   => (exp,'$','$')
*/
public function templDef_AngleOrDolar
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
  output String outLeftEsc;
  output String outRightEsc;
algorithm
  (outChars, outLineInfo, outExpression, outLeftEsc, outRightEsc) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
    
    case (":"::":"::"=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, "<", ">");
      then (chars, linfo, exp, "<", ">");
    
    case ("$"::"$"::"=" :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, "$", "$");
      then (chars, linfo, exp, "$", "$");

            
  end matchcontinue;
end templDef_AngleOrDolar;
/*
templArgs:
    templArg0:a0  templArgs_rest:args  =>  a0::args
    |
    _  => {}
*/
public function templArgs
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outArgs;  
algorithm
  (outChars, outLineInfo, outArgs) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature> arg0;
    
    case (chars, linfo)
      equation
        (chars, linfo, arg0) = templArg0(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, args) = templArgs_rest(chars, linfo);
      then (chars, linfo, arg0::args);
    
    case (chars, linfo)
      then (chars, linfo, {});

  end matchcontinue;
end templArgs;
/*
templArg0:
    typeSig:ts  implicitArgName:name  =>  (name,ts) 

*/
public function templArg0
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.TypeSignature> outArg;  
algorithm
  (outChars, outLineInfo, outArg) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;
    
    case (chars, linfo)
      equation
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, name) = implicitArgName(chars);
      then (chars, linfo, (name,ts) );
    
  end matchcontinue;
end templArg0;
/*
implicitArgName:
      IDENT:id  => id  //maybe 'it' explicitly 
      |
      _  => 'it'

*/
public function implicitArgName
  input list<String> inChars;

  output list<String> outChars;
  output TplAbsyn.Ident outArgName;  
algorithm
  (outChars, outArgName) := matchcontinue (inChars)
    local
      String lesc, resc;
      list<String> chars;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;
    
    case (chars)
      equation
        (chars, name) = identifier(chars);
      then (chars, name);
    
    case (chars)
      then (chars, "it");
    
  end matchcontinue;
end implicitArgName;
/*
templArgs_rest
	',' typeSig:ts  argName_nonIt:name  templArgs_rest:rest  =>  (name,ts)::rest
	|
	_  => {}
*/
public function templArgs_rest
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.TypedIdents outArgs;  
algorithm
  (outChars, outLineInfo, outArgs) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;
      TplAbsyn.TypedIdents rest;
    
    case ("," :: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, ts) = typeSig(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, name) = argName_nonIt(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rest) = templArgs_rest(chars, linfo);
      then (chars, linfo, (name,ts) :: rest);
    
    case (chars, linfo)
      then (chars, linfo, {});
    
  end matchcontinue;
end templArgs_rest;

/*
argName_nonIt:
      'it'  =>  Error("Implicit argument 'it' appeared at non-fist position in the template argument list. 'it' can be explicitly only as the first argument.")
      |
      IDENT:id  => id   
*/
public function argName_nonIt
  input list<String> inChars;
  input LineInfo inLineInfo;

  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Ident outArgName;  
algorithm
  (outChars, outLineInfo, outArgName) := matchcontinue (inChars, inLineInfo)
    local
      String lesc, resc;
      list<String> chars;
      LineInfo linfo;
      Boolean isD;
      TplAbsyn.PathIdent pid;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      TplAbsyn.Ident name;
      TplAbsyn.TemplateDef td;
      TplAbsyn.TypedIdents args;
      TplAbsyn.Expression exp;
      TplAbsyn.TypeSignature ts;
      TplAbsyn.TypedIdents rest;
    
    case ("i" :: "t" :: chars, linfo)
      equation
        afterKeyword(chars);
        Debug.fprint("failtrace", "Parse error - implicit argument 'it' appeared at non-first position in the template argument list. 'it' can be explicitly only as the first argument.\n");        
      then (chars, linfo, "it#Error-displaced it#");
    
    case (chars, linfo)
      equation
        (chars, name) = identifier(chars);        
      then (chars, linfo, name);
    
  end matchcontinue;
end argName_nonIt;

/*
expression(lesc,resc):
	'#' nonTemplateExp(lesc,resc):nexp  concatNonTemplExp_rest(lesc,resc):expLst
	   => TEMPLATE(nexp::expLst}, "#", "");
	|
	expression_base(lesc,resc):bexp  expression_tail(bexp,lesc,resc):exp => exp 
*/
public function expression
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, nexp;
      list<TplAbsyn.Expression> expLst;
    
    case ("#" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, nexp) = nonTemplateExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatNonTemplExp_rest(chars, linfo, lesc, resc);        
      then (chars, linfo, TplAbsyn.TEMPLATE(nexp :: expLst, "#", ""));
  
    case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, bexp) = expression_base(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression_tail(chars, linfo, bexp, lesc, resc);
      then (chars, linfo, exp);
                
  end matchcontinue;
end expression;

/*
concatNonTemplExp_rest(lesc,resc):
	'#' nonTemplateExp(lesc,resc):nexp  concatNonTemplExp_rest(lesc,resc):expLst 
	  =>  nexp::expLst
	|
	expression(lesc,resc):exp
	  => {exp}
*/
public function concatNonTemplExp_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, nexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.MatchingExp mexp;
    
    case ("#":: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, nexp) = nonTemplateExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatNonTemplExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, nexp::expLst);

    case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);        
      then (chars, linfo, {exp});
    
  end matchcontinue;
end concatNonTemplExp_rest;

/*
expression_base(lesc,resc):
	stringConstant:strRevList 
	  => STR_TOKEN(makeStrTokFromRevStrList(strRevList))
	|
	literalConstant:(str,litType) 
	  => LITERAL(str,litType)
	|
	templateExp(lesc,resc)
	|
	conditionExp(lesc,resc)
	|
	matchExp(lesc,resc)
	|
	'[' ']'  => MAP_ARG_LIST({})	                                                           
	|
	'[' expression(lesc,resc):exp  expressionList_rest(lesc,resc):expLst ']'   //  list construction with possible mixed scalars and lists 
	                                                           //… useful in map/concatenation context
	   => MAP_ARG_LIST(exp::expLst)	                                                           
	|
	'('  ')' //a variant of an empty expression, equivalent to ""
	   =>  STR_TOKEN(ST_STRING("")) 	
	|
	'(' expressionWithOpts(lesc,resc):exp ')'
	   => exp
	|// TODO: create an optional variant of pathIdent
	pathIdent:name  boundValueOrFunCall(name,lesc,resc):exp  =>  exp
*/
public function expression_base
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, strRevList;
      LineInfo linfo;
      String c, lesc, resc, str;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
    
    case (chars, linfo, _, _)
      equation
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        st = makeStrTokFromRevStrList(strRevList);
      then (chars, linfo, TplAbsyn.STR_TOKEN(st));
        
    case (chars, linfo, _, _)
      equation
        (chars, linfo, str, ts) = literalConstant(chars, linfo);
      then (chars, linfo, TplAbsyn.LITERAL(str, ts));
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = templateExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = conditionExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = matchExp(chars, linfo, lesc, resc);
      then (chars, linfo, exp);

   case ("[" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("]" :: chars) = chars;
      then (chars, linfo, TplAbsyn.MAP_ARG_LIST({}));
   
   case ("[" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        ("]" :: chars) = chars;
      then (chars, linfo, TplAbsyn.MAP_ARG_LIST(exp::expLst));
   
   case ("(" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, TplAbsyn.STR_TOKEN(Tpl.ST_STRING("")) );
 
   case ("(" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expressionWithOpts(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, exp);
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, name) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = boundValueOrFunCall(chars, linfo, name, lesc, resc);
      then (chars, linfo, exp);
        
  end matchcontinue;
end expression_base;

/*
expression_tail(bexp,lesc,resc):
	'of' matchBinding:mexp ':' expression(lesc,resc):exp  =>  MAP(bexp,mexp,exp)
	|
	':' expression(lesc,resc):exp  =>  MAP(bexp,BIND_MATCH('it'),exp)
	|
	'+' expression(lesc,resc):exp  concatExp_rest(lesc,resc):expLst   //  concatenation … same as "<expression><expression>"
	=> TEMPLATE(bexp::exp::expLst, "+", "");
	|
	_ => bexp 
*/
public function expression_tail
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.Expression inBaseExpression;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inBaseExpression, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.MatchingExp mexp;
    
    case ("o"::"f":: chars, linfo, bexp, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (":" :: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.MAP(bexp, mexp, exp) );

    case (":" :: chars, linfo, bexp, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.MAP(bexp, TplAbsyn.BIND_MATCH("it"), exp) );
   
    case ("+" :: chars, linfo, bexp, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.TEMPLATE(bexp::exp::expLst, "+", "") );

    case (chars, linfo, bexp, _, _)
      then (chars, linfo, bexp );

  end matchcontinue;
end expression_tail;

/*
concatExp_rest(lesc,resc):
	'+' expression(lesc,resc):exp  concatExp_rest(lesc,resc):expLst  =>  exp::expLst
	|
	_ => {}
*/
public function concatExp_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.MatchingExp mexp;
    
    case ("+":: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = concatExp_rest(chars, linfo, lesc, resc);
      then (chars, linfo, exp::expLst);

    case (chars, linfo, lesc, resc)
      then (chars, linfo, {});

  end matchcontinue;
end concatExp_rest;

/*
boundValueOrFunCall(name,lesc,resc):
	funCall(name,lesc,resc):exp  => exp
	|
	_ => BOUND_VALUE(name)
*/
public function boundValueOrFunCall
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inName;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inName, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.Expression exp;
      
    case (chars, linfo, name, lesc, resc)
      equation
        (chars, linfo,exp) = funCall(chars, linfo, name, lesc, resc);
      then (chars, linfo, exp);

    case (chars, linfo, name, _, _)
      then (chars, linfo, TplAbsyn.BOUND_VALUE(name));

  end matchcontinue;
end boundValueOrFunCall;

/*
funCall(name,lesc,resc):
	'(' ')' => FUN_CALL(name,{})
	|
	'(' expression(lesc,resc):exp  expressionList_rest(lesc,resc):expLst ')'  //template  or  intrinsic function
	  => FUN_CALL(name,exp::expLst)
*/
public function funCall
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inName;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inName, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;
      
    case ("(":: chars, linfo, name, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, TplAbsyn.FUN_CALL(name,{}));

    case ("(":: chars, linfo, name, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, TplAbsyn.FUN_CALL(name, exp::expLst));

  end matchcontinue;
end funCall;

/*
expressionList_rest(lesc,resc):	
	',' expression(lesc,resc):exp  expressionList_rest(lesc,resc):expLst => exp::expLst
	|
	_ => {} 
*/
public function expressionList_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outChars, outLineInfo, outExpressionList) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.MatchingExp mexp;
    
    case (",":: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expLst) = expressionList_rest(chars, linfo, lesc, resc);
      then (chars, linfo, exp::expLst);

    case (chars, linfo, _, _)
      then (chars, linfo, {});

  end matchcontinue;
end expressionList_rest;


/*
stringConstant:
	'"' doubleQuoteConst({},{}):stRevLst  
	  => stRevLst
	|
	'%'(lquot) stripFirstNewLine verbatimConst(Rquote(lquot),{},{}):stRevLst 
	  => stRevLst
	|
	'\\n' escUnquotedChars({}, {"\n"}):stRevLst
	  => stRevLst
	|
	'\\' escChar:c  escUnquotedChars({c}, {}):stRevLst
	  => stRevLst
*/
public function stringConstant
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, ds, stRevLst;
      LineInfo linfo;
      String lquot,rquot,pm, dn,ex, num, c;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression cexp;
    
    case ("\"" :: chars, linfo)
      equation
        (chars, linfo,stRevLst) = doubleQuoteConst(chars, linfo,{},{});
      then (chars, linfo, stRevLst);
    
    case ("%"::lquot:: chars, linfo)
      equation
        (chars, linfo) = stripFirstNewLine(chars, linfo);        
        rquot = rightVerbatimConstQuote(lquot);
        (chars, linfo,stRevLst) = verbatimConst(chars, linfo, rquot,{},{});
      then (chars, linfo, stRevLst);
    
    case ("\\"::"n":: chars, linfo)
      equation
        (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo, {},{"\n"});
      then (chars, linfo, stRevLst);
    
    case ("\\":: c :: chars, linfo)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo, {c},{});
      then (chars, linfo, stRevLst);
                
  end matchcontinue;
end stringConstant;

/*
literalConstant:
	//(+|-)?d*(.d+)?(('e'|'E')(+|-)?d+)?	
	plusMinus:pm digits:ds dotNumber:(dn,ts) exponent(ts):(ex,ts)
	=> (pm+& string_char_list_string(ds)+&dn+&ex, ts)  //validate the number - must have integer part or dotpart 
	|
	'true' => ("true", BOOLEAN_TYPE())
	|
	'false' => ("false", BOOLEAN_TYPE())
*/
public function literalConstant
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output String outConstantValue;
  output TplAbsyn.TypeSignature outConstantType;
algorithm
  (outChars, outLineInfo, outConstantValue, outConstantType) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, ds;
      LineInfo linfo;
      String lquot,rquot,pm, dn,ex, num, c;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression cexp;
    
     case (chars, linfo)
      equation
        (chars, pm) = plusMinus(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, ds) = digits(chars);
        (chars, dn, ts) = dotNumber(chars);
        //validate the number - must have integer part or dotpart
        num = string_char_list_string(ds)+&dn;
        true = stringLength(num) > 0;
        (chars, ex, ts) = exponent(chars,ts);
        num = pm +& num +& ex;         
      then (chars, linfo, num, ts);
    
    case ("t"::"r"::"u"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);        
      then (chars, linfo, "true",TplAbsyn.BOOLEAN_TYPE());
    
    case ("f"::"a"::"l"::"s"::"e" :: chars, linfo)
      equation
        afterKeyword(chars);        
      then (chars, linfo, "false",TplAbsyn.BOOLEAN_TYPE());
                
  end matchcontinue;
end literalConstant;


public function stripFirstNewLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    case (chars, linfo) 
      equation
        (chars, linfo) = newLine(chars, linfo);
      then (chars, linfo);
    case (chars, linfo) then (chars, linfo);          
  end matchcontinue;
end stripFirstNewLine;

public function rightVerbatimConstQuote
  input  String inLeftQuote;
  output String outRightQuote;
algorithm
  (outRightQuote) := matchcontinue (inLeftQuote)
    local
      String lquot;
    case ("(" ) then ")";
    case ("{" ) then "}";
    case ("<" ) then ">";
    case ("[" ) then "]";
    case (lquot) then lquot;
  end matchcontinue;
end rightVerbatimConstQuote;

/*
doubleQuoteConst(accChars,accStrList):
	'"' => string_char_list_string(listReverse(accChars)) :: accStrList
	|
	newLine doubleQuoteConst({}, string_char_list_string(listReverse('\n'::accChars))::accStrList):stRevLst 
	=> stRevLst
	|
	'\\n' doubleQuoteConst({}, string_char_list_string(listReverse('\n'::accChars))::accStrList):stRevLst
	=> stRevLst
	|
	'\\'escChar:c doubleQuoteConst(c::accChars,accStrList):stRevLst
	=> stRevLst
	|
	c doubleQuoteConst(c::accChars,accStrList):stRevLst
	=> stRevLst
	|
	Error end of file
*/
public function doubleQuoteConst
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<String> inAccChars;
  input list<String> inAccStrList;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo, inAccChars, inAccStrList)
    local
      list<String> chars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String lquot,rquot,c, str;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
    
    case ("\"" :: chars, linfo, accChars, accStrList)
      equation
        str = string_char_list_string(listReverse(accChars));
      then (chars, linfo, str :: accStrList);
    
    //inline new line
    case (chars, linfo, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        str = string_char_list_string(listReverse("\n"::accChars));
        (chars, linfo,stRevLst) = doubleQuoteConst(chars, linfo,{},str :: accStrList);        
      then (chars, linfo, stRevLst);
    //escaped new line
    case ("\\"::"n" :: chars, linfo, accChars, accStrList)
      equation
        str = string_char_list_string(listReverse("\n"::accChars));
        (chars, linfo,stRevLst) = doubleQuoteConst(chars, linfo,{},str :: accStrList);        
      then (chars, linfo, stRevLst);
        
    case ("\\":: c :: chars, linfo, accChars, accStrList)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst) = doubleQuoteConst(chars, linfo, c::accChars, accStrList);        
      then (chars, linfo, stRevLst);
    
    case (c :: chars, linfo, accChars, accStrList)
      equation
        (chars, linfo,stRevLst) = doubleQuoteConst(chars, linfo, c::accChars, accStrList);        
      then (chars, linfo, stRevLst);
    
    case ( {}, linfo, accChars, accStrList) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.doubleQuoteConst - unmatched \' \' quotes for a string constat - reached end of file.\n");
        str = string_char_list_string(listReverse(accChars));
      then ({}, linfo, str :: accStrList);
                
  end matchcontinue;
end doubleQuoteConst;

/*
escChar:
	( '\'' | '"' | '?' |  '\\' | 'a' | 'b' | 'f' | 'n' | 'r' | 't' | 'v' | ' ' )
	=> the escaped char

*/
public function escChar
  input  String inEscChar;
  output String outTheChar;
algorithm
  (outTheChar) := matchcontinue (inEscChar)
    case ("'" ) then "'";
    case ("\"" ) then "\"";
    case ("?" ) then "?";
    case ("\\" ) then "\\";
    /*
    //TODO: Error in the .srz or .c compilation(\r)
    case ("a" ) then "\a"; 
    case ("b" ) then "\b";
    case ("f" ) then "\f";
    case ("r" ) then "\r";
    case ("v" ) then "\v";
    */
    case ("n" ) then "\n";
    case ("t" ) then "\t";
    case (" " ) then " ";
  end matchcontinue;
end escChar;

/*
verbatimConst(rquot, accChars, accStrList):
	//strip a last inline new line
	newLine (rquot)'%' =>  string_char_list_string(listReverse(accChars)) :: accStrList 
	|
	(rquot)'%' =>  string_char_list_string(listReverse(accChars)) :: accStrList 
	|
	newLine verbatimConst(rquot, {}, string_char_list_string(listReverse('\n'::accChars))::accStrList):stRevLst
	  => stRevLst
	|
	c  verbatimConst(rquot, c::accChars,accStrList):stRevLst
	  => stRevLst
	|
	Error end of file
*/
public function verbatimConst
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inRightQuote;
  input list<String> inAccChars;
  input list<String> inAccStrList;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo, inRightQuote, inAccChars, inAccStrList)
    local
      list<String> chars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String lquot,rquot,c,str;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents> rtag;
      tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo> idti;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypeInfo>> types;
      list<tuple<TplAbsyn.Ident, TplAbsyn.TypedIdents>> rtags;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
    
    //strip a last inline new line
    case (chars, linfo, rquot, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (c :: "%" :: chars) = chars;
        equality(c = rquot);
        str = string_char_list_string(listReverse(accChars));
      then (chars, linfo, str :: accStrList);
    
    case (c :: "%" :: chars, linfo, rquot, accChars, accStrList)
      equation
        equality(c = rquot);
        str = string_char_list_string(listReverse(accChars));
      then (chars, linfo, str :: accStrList);
    
    case (chars, linfo, rquot, accChars, accStrList)
      equation
        (chars, linfo) = newLine(chars, linfo);
        str = string_char_list_string(listReverse("\n"::accChars));
        (chars, linfo,stRevLst) = verbatimConst(chars, linfo,rquot,{}, str :: accStrList);        
      then (chars, linfo, stRevLst);
    
    case (c :: chars, linfo, rquot, accChars, accStrList)
      equation
        (chars, linfo,stRevLst) = verbatimConst(chars, linfo, rquot, c::accChars, accStrList);        
      then (chars, linfo, stRevLst);
    
    case ( {}, linfo, rquot, accChars, accStrList) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.verbatimConst - unmatched %"+&rquot+&" "+&rquot+&"% quotes for a verbatim string constant - reached end of file.\n");
        str = string_char_list_string(listReverse(accChars));
      then ({}, linfo, str :: accStrList);
                
  end matchcontinue;
end verbatimConst;

/*
escUnquotedChars(accChars,accStrList):
	'\\n' escUnquotedChars({}, string_char_list_string(listReverse('\n'::accChars)) :: accStrList):stRevLst
	=> stRevLst
	|
	'\\' escChar:c  escUnquotedChars(c::accChars, accStrList):stRevLst
	=> stRevLst
	|
	_ => string_char_list_string(listReverse(accChars)) :: accStrList

*/
public function escUnquotedChars
  input list<String> inChars;
  input LineInfo inLineInfo;
  input list<String> inAccChars;
  input list<String> inAccStrList;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<String> outStrRevList;
algorithm
  (outChars, outLineInfo, outStrRevList) := matchcontinue (inChars, inLineInfo, inAccChars, inAccStrList)
    local
      list<String> chars, accChars, accStrList, stRevLst;
      LineInfo linfo;
      String c, str;
      Tpl.StringToken st;
    
    case ("\\":: "n" :: chars, linfo, accChars, accStrList)
      equation
       str = string_char_list_string(listReverse("\n"::accChars));
       (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo,{},str :: accStrList);        
      then (chars, linfo, stRevLst);
    
    case ("\\":: c :: chars, linfo, accChars, accStrList)
      equation
        c = escChar(c);
        (chars, linfo,stRevLst) = escUnquotedChars(chars, linfo, c::accChars, accStrList);        
      then (chars, linfo, stRevLst);

    case (chars, linfo, accChars, accStrList)
      equation
        str = string_char_list_string(listReverse(accChars));
      then (chars, linfo, str :: accStrList);

  end matchcontinue;
end escUnquotedChars;


public function makeStrTokFromRevStrList
  input list<String> inRevStrList;
  output Tpl.StringToken outStringToken;
algorithm
  (outStringToken) := matchcontinue (inRevStrList)
    local
      list<String> strList;
      String str;
      
    case ( { str } )
      then Tpl.ST_STRING(str);
        
    case ( { "", "\n" } )
      then Tpl.ST_NEW_LINE();
        
    case ( { "" , str} )
      then Tpl.ST_LINE(str);
    
    case ( "" :: strList )
      equation
        strList = listReverse(strList);                
      then Tpl.ST_STRING_LIST(strList, true);
    
    case ( strList as (_ :: _))
      equation
        strList = listReverse(strList);                
      then Tpl.ST_STRING_LIST(strList, false);
    
    // should not ever happen
    case ( _ ) 
      equation
        Debug.fprint("failtrace", "Parse invalid operation error - TplParser.makeStrTokFromRevStrList failed (an empty string list passed?) .\n");
      then fail();
                
  end matchcontinue;
end makeStrTokFromRevStrList;

/*
plusMinus:
	'+' => "+"
	|
	'-' => "-"
	|
	_ => ""
*/
public function plusMinus
  input list<String> inChars;
  
  output list<String> outChars;
  output String outSign;
algorithm
  (outChars, outSign) := matchcontinue (inChars)
    local
      list<String> chars;      
    
    case ("+" :: chars)
      then (chars, "+");
    
    case ("-" :: chars)
      then (chars, "-");
    
    case (chars)
      then (chars, "");
                
  end matchcontinue;
end plusMinus;
/*
digits:
	[0-9]:d  digits:ds => d::ds
	|
	_ => {}
*/
public function digits
  input list<String> inChars;
  
  output list<String> outChars;
  output list<String> outDigits;
algorithm
  (outChars, outDigits) := matchcontinue (inChars)
    local
      String d;
      list<String> chars, ds;
      Integer i;
    
    case (d :: chars)
      equation
        i = stringCharInt(d);
        //[0-9]
        true = ( 48/*0*/ <= i and i <= 57/*9*/);
        (chars,ds) = digits(chars);        
      then (chars, d::ds);
    
    case (chars)
      then (chars, {});
    
  end matchcontinue;
end digits;
/*
dotNumber:
	'.' digits:ds  =>  (string_char_list_string(ds), REAL_TYPE())
	|
	_ => INTEGER_TYPE()	 
*/
public function dotNumber
  input list<String> inChars;
  
  output list<String> outChars;
  output String outDotNumber;
  output TplAbsyn.TypeSignature outLitType;
algorithm
  (outChars, outDotNumber, outLitType) := matchcontinue (inChars)
    local
      String dn;
      list<String> chars, ds;
      Integer i;
    
    case ("." :: chars)
      equation        
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        dn = "." +& string_char_list_string(ds);         
      then (chars, dn, TplAbsyn.REAL_TYPE());
    
    case (chars)
      then (chars, "", TplAbsyn.INTEGER_TYPE());
    
  end matchcontinue;
end dotNumber;

/*
exponent(typ):
	'e' plusMinus:pm  digits:ds => ("e"+&pm+&string_char_list_string(ds), REAL_TYPE())
	|
	'E' plusMinus:pm  digits:ds => ("E"+&pm+&string_char_list_string(ds), REAL_TYPE())
	|
	=> ("",typ)
*/
public function exponent
  input list<String> inChars;
  input TplAbsyn.TypeSignature inLitType;
  
  output list<String> outChars;
  output String outExponent;
  output TplAbsyn.TypeSignature outLitType;
algorithm
  (outChars,outExponent,outLitType) := matchcontinue (inChars,inLitType)
    local
      String ex,pm;
      list<String> chars, ds;
      Integer i;
      TplAbsyn.TypeSignature litType;
    
    case ("e" :: chars, litType)
      equation
        (chars,pm) = plusMinus(chars);
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        ex = "e" +& pm +& string_char_list_string(ds);         
      then (chars, ex, TplAbsyn.REAL_TYPE());
    
    case ("E" :: chars, litType)
      equation
        (chars,pm) = plusMinus(chars);
        (chars,ds) = digits(chars);
        (_::_) = ds; //some digits must be there
        ex = "E" +& pm +& string_char_list_string(ds);         
      then (chars, ex, TplAbsyn.REAL_TYPE());
    
    case (chars, litType)
      then (chars, "", litType);
    
  end matchcontinue;
end exponent;

/*
templateExp(lesc, resc):
	"'" stripFirstNewLine  templateBody(lesc, resc, isSingleQuote = true, {},{},0)
	|
	'<<' stripFirstNewLine templateBody(lesc, resc, isSingleQuote = false,{},{},0 )
*/
public function templateExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars, solChars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      Integer baseInd, lineInd;
    
   case ("'" :: chars, linfo, lesc, resc)
      equation
        //single quotes has no special treatment of indent and new lines
        //i.e., it takes O as the base indent, and it counts every new line 
        (chars, linfo, exp) = templateBody(chars, linfo, lesc, resc, true, {},{},0);
      then (chars, linfo, exp);
   
   case ("<"::"<":: chars, linfo, lesc, resc)
      equation
        //the base indent is the indent of the line where the << appears
        LINE_INFO(startOfLineChars = solChars) = linfo;
        (_, baseInd) = lineIndent(solChars,0);
        //the case when nothing visible is after <<        
        (chars, linfo) = takeSpaceAndNewLine(chars, linfo);
        //(chars, linfo) = templStripFirstNewLine(chars, linfo);
        //push the staring indent on the indentStack
        (chars, linfo, exp) = templateBody(chars, linfo, lesc, resc, false, {}, {}, baseInd);
      then (chars, linfo, exp);
   
   //special treatment when some non-space is right after << 
   case ("<"::"<":: chars, linfo, lesc, resc)
      equation
        //the base indent is the indent of the line where the << appears
        LINE_INFO(startOfLineChars = solChars) = linfo;
        (_, baseInd) = lineIndent(solChars,0);
        //some non-space char(s) is after <<        
        failure( (_,_) = takeSpaceAndNewLine(chars, linfo) );
        (chars, lineInd) = lineIndent(chars,0);
        //correct the indent of the line right after << to baseInd
        lineInd = lineInd + baseInd;
        //push the base indent on the indentStack
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, false, {}, {}, baseInd, lineInd, {});
      then (chars, linfo, exp);     
  end matchcontinue;
end templateExp;



/*
takeSpaceAndNewLine:
	newLine
  |
  ' ' takeSpaceAndNewLine
	|
	'\t' takeSpaceAndNewLine
*/
public function takeSpaceAndNewLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
    
   case (chars, linfo)
     equation
       (chars, linfo) = newLine(chars, linfo);
     then (chars, linfo);
   
   case (" " :: chars, linfo)
      equation
       (chars, linfo) = takeSpaceAndNewLine(chars, linfo); 
      then (chars, linfo);

   case ("\t" :: chars, linfo)
      equation
       (chars, linfo) = takeSpaceAndNewLine(chars, linfo); 
      then (chars, linfo);
        
  end matchcontinue;
end takeSpaceAndNewLine;

/*
templateBody(lesc, resc, isSingleQuote, expList, indStack, actInd):
	lineIndent(0):lineInd  
	  restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, {}):exp
	=> exp
*/
public function templateBody
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean inIsSingleQuote;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) 
  := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc, inIsSingleQuote, inExpressionList, inIndentStack, inActualIndent)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isSQ;
      Integer actInd, lineInd;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
    
   case (chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd)
      equation
        (chars, lineInd) = lineIndent(chars,0);
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, {});
      then (chars, linfo, exp);
    
  end matchcontinue;
end templateBody;

/*
lineIndent(ind):
	' ' lineIndent(ind+1):n  =>  n
	|
	'\t' lineIndent(ind+4):n  =>  n
	|
	_  =>  ind

*/
public function lineIndent
  input list<String> inChars;
  input Integer inLineIndent;
  
  output list<String> outChars;
  output Integer outLineIndent;  
algorithm
  (outChars, outLineIndent) := matchcontinue (inChars, inLineIndent)
    local
      list<String> chars;
      Integer lineInd;
    
   case (" " :: chars, lineInd)
     equation
       (chars, lineInd) = lineIndent(chars, lineInd + 1);
     then (chars, lineInd);
   
   case ("\t" :: chars, lineInd)
     equation
       (chars, lineInd) = lineIndent(chars, lineInd + TabSpaces);
     then (chars, lineInd);
   
   case (chars, lineInd)
     then (chars, lineInd);
        
  end matchcontinue;
end lineIndent;
/*
// & ... no interleave
restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, accStrChars):
	(lesc)'#' nonTemplateExprWithOpts(lesc,resc):eexp  '#'(resc)
	   { (expList, indStack, actInd) = onEscapedExp(eexp, expList, indStack, actInd, lineInd, accStrChars) }
	   & restOfTemplLine(lesc,resc,isSingleQuote, expList, indStack, actInd, actInd, {}):exp
	   => exp
	    
	| 
	(lesc)  (resc)	// a comment | empty expression ... ignore completely   
	   & restOfTemplLineAfterEmptyExp(lesc,resc,isSingleQuote, expList, indStack, actInd, lineInd, accStrChars):exp
	   => exp
	| 
	(lesc) expressionWithOpts(lesc,resc):eexp (resc)
	   { (expList, indStack, actInd) = onEscapedExp(eexp, expList, indStack, actInd, lineInd, accStrChars) }
	   & restOfTemplLine(lesc,resc,isSingleQuote, expList, indStack, actInd, actInd, {}):exp
	   => exp
	   
	| // on \n
	newLine  
	 { (expList, indStack, actInd) = onNewLine(expList, indStack, actInd, lineInd, accStrChars) }
	 & templateBody(lesc, resc, isSingleQuote, expList, indStack, actInd):exp
	=> exp
	  
	| //end
	(isSingleQuote = true) "'" 
	 => 
	  onTemplEnd(expList, indStack, actInd, lineInd, accStrChars) 
	  
	| //end
	(isSingleQuote = false) '>>' 
	 => 
	 onTemplEnd(expList, indStack, actInd, lineInd, accStrChars) 
	 
	|
	'\' & ( '\' | "'" | (lesc) | (resc) ):c 
	 & restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, c :: accStrChars) : exp
	  => exp 
	|
	any:c  
	  & restOfTemplLine(lesc, resc, isSingleQuote, expList, indStack, actInd, lineInd, c :: accStrChars) : exp
	  => exp
*/
public function restOfTemplLine
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean inIsSingleQuote;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) 
  := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc, inIsSingleQuote, inExpressionList, inIndentStack,
                    inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String> chars, accChars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isSQ;
      Integer actInd, lineInd;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, nexp, eexp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
    
   //<# #> or $# #$ 
   case (c :: "#" :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        equality( c  = lesc );
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, eexp) = nonTemplateExprWithOpts(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        ("#" :: c :: chars) = chars;
        equality( c  = resc );
        (chars, linfo, lineInd) = dropNewLineAfterEmptyExp(chars, linfo, lineInd, accChars);
        (expLst, indStack, actInd) = onEscapedExp(eexp, expLst, indStack, actInd, lineInd, accChars);
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, actInd, {});
      then (chars, linfo, exp);
   
   //< > or $ $ empty expression ... i.e. comment or a break in line that is not parsed 
   case (c :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        equality( c  = lesc );
        (chars, linfo) = interleave(chars, linfo);
        (c :: chars) = chars;
        equality( c  = resc );
        (chars, linfo, lineInd) = dropNewLineAfterEmptyExp(chars, linfo, lineInd, accChars);
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars);
        
        //(chars, linfo, exp) = restOfTemplLineAfterEmptyExp(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars);
      then (chars, linfo, exp);
      
   //<expressionWithOpts> or $expressionWithOpts$
   case (c :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        equality( c  = lesc );
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, eexp) = expressionWithOpts(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (c :: chars) = chars;
        equality( c  = resc );
        (expLst, indStack, actInd) = onEscapedExp(eexp, expLst, indStack, actInd, lineInd, accChars);
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, actInd, {});
      then (chars, linfo, exp);
  
   case (chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        (chars, linfo) = newLine(chars, linfo);
        (expLst, indStack, actInd) = onNewLine(expLst, indStack, actInd, lineInd, accChars);
        (chars, linfo, exp) = templateBody(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd);
      then (chars, linfo, exp);
   
   //isSingleQuote = true
   case ("'" :: chars, linfo, lesc, resc, true, expLst, indStack, actInd, lineInd, accChars)
      equation
        expLst = onTemplEnd(false, expLst, indStack, actInd, lineInd, accChars);
        exp = makeTemplateFromExpList(expLst, "'","'");
      then (chars, linfo, exp);
   
   //isDoubleQuote = false =>  << >>
   case (">"::">":: chars, linfo, lesc, resc, false, expLst, indStack, actInd, lineInd, accChars)
      equation
        expLst = onTemplEnd(true, expLst, indStack, actInd, lineInd, accChars);
        exp = makeTemplateFromExpList(expLst, "<<",">>");
      then (chars, linfo, exp);
   
   case ("\\":: c :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = (c ==& "\\" or c ==& "'" or c ==& lesc or c ==& resc); 
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, c :: accChars);
      then (chars, linfo, exp);

   case (c :: chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, c :: accChars);
      then (chars, linfo, exp);
    
  end matchcontinue;
end restOfTemplLine;

/* obsolete
public function restOfTemplLineAfterEmptyExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  input Boolean inIsSingleQuote;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) 
  := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc, inIsSingleQuote, inExpressionList, inIndentStack,
                    inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String> chars, accChars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isSQ;
      Integer actInd, lineInd;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
   
   //ignore a pure-empty-exp line
   //accChars = {} nothing before the empty exp 
   //and [space] and newLine() after it 
   case (chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, _, {})
      equation
        //try take a space and new line
        (chars, linfo) = takeSpaceAndNewLine(chars, linfo);
        (chars, linfo, exp) = templateBody(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd);
      then (chars, linfo, exp);
   
   //simple restOfTemplLine() otherwise ... i.e. continue parsing after the empty exp
   case (chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars)
      equation
        (chars, linfo, exp) = restOfTemplLine(chars, linfo, lesc, resc, isSQ, expLst, indStack, actInd, lineInd, accChars);
      then (chars, linfo, exp);
    
  end matchcontinue;
end restOfTemplLineAfterEmptyExp;
*/

public function dropNewLineAfterEmptyExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output Integer outLineIndent;
algorithm
  (outChars, outLineInfo, outLineIndent) 
  := matchcontinue (inChars, inLineInfo, inLineIndent, inAccStringChars)
    local
      list<String> chars;
      LineInfo linfo;
      Integer lineInd;
      
   //ignore a pure-empty-exp line
   //accChars = {} nothing before the empty exp 
   //and [space] and newLine() after it 
   case (chars, linfo, _, {})
      equation
        (chars, _) = lineIndent(chars,0); //try take a space before newLine() 
        (chars, linfo) = newLine(chars, linfo);
        (chars,lineInd) = lineIndent(chars, 0);
      then (chars, linfo, lineInd);
   
   //do nothing otherwise ... i.e. continue parsing after the empty exp
   case (chars, linfo, lineInd, _)
      then (chars, linfo, lineInd);
    
  end matchcontinue;
end dropNewLineAfterEmptyExp;


public function makeTemplateFromExpList
  input list<TplAbsyn.Expression> inExpressionList;
  input String inLeftQuote;
  input String inRightQuote;
  
  output TplAbsyn.Expression outExpression;
algorithm
  (outExpression) 
  := matchcontinue (inExpressionList, inLeftQuote,inRightQuote)
    local
      String lquote, rquote;
      TplAbsyn.Expression exp;
      list<TplAbsyn.Expression> expLst;

   case ( { } , _ , _)
      then TplAbsyn.STR_TOKEN(Tpl.ST_STRING(""));
        
   case ( { exp } , _ , _)
      then exp;
   
   case (expLst, lquote, rquote)
     equation
       expLst = listReverse(expLst);
     then TplAbsyn.TEMPLATE(expLst, lquote, rquote);
    
  end matchcontinue;
end makeTemplateFromExpList;


public function onEscapedExp
  input TplAbsyn.Expression inExpression;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
algorithm
  (outExpressionList, outIndentStack, outActualIndent) 
  := matchcontinue (inExpression, inExpressionList, inIndentStack,
                    inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String> chars, accChars;
      String c, lesc, resc;
      Boolean isSQ;
      Integer actInd, lineInd, baseInd;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, nexp, eexp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
   
   
   //TODO: optimization for <\n>
   //we need a flag for having something non-space on the line 
   //case (TplAbsyn.STR_TOKEN(value = Tpl.ST_NEW_LINE()), expLst, indStack, actInd, lineInd, accChars)
   //   equation
   //     //equality( lineInd = actInd);
   //     expLst = addAccStringChars(expLst, "\n" :: accChars);        
   //   then (expLst, indStack,  actInd);
        
   //the same indent level 
   case (exp, expLst, indStack, actInd, lineInd, accChars)
      equation
        equality( lineInd = actInd);
        expLst = addAccStringChars(expLst, accChars);
        expLst = finalizeLastStringToken(expLst);
        expLst = exp :: expLst;
      then (expLst, indStack,  actInd);
   
   //push new indent level
   case (exp, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = ( lineInd > actInd );
        expLst = finalizeLastStringToken(expLst);
        indStack = (actInd, expLst) :: indStack;
        expLst = addAccStringChars({}, accChars);
        expLst = finalizeLastStringToken(expLst);
        expLst = exp :: expLst;
      then (expLst, indStack,  lineInd);
   
   //if the indent is under the base indent level, warn and make it 0 level
   case (exp, expLst, {}, baseInd, lineInd, accChars)
      equation
        true = ( lineInd < baseInd );
        Debug.fprint("failtrace", "Parse warning onEscapedExp() - indent level is under the level of the '<<' determined level.\n");
        //call again as  lineInd = baseInd 
        (expLst, indStack,  actInd) = onEscapedExp(exp, expLst, {}, baseInd, baseInd, accChars);        
      then (expLst, indStack,  actInd);
   
   //pop indent level and try again (indStack must have at least one pushed indent level)
   case (exp, expLst, indStack as (_::_), actInd, lineInd, accChars)
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        (expLst, indStack,  actInd) = onEscapedExp(exp, expLst, indStack, actInd, lineInd, accChars);        
      then (expLst, indStack,  lineInd);

   //should not happen
   case (_,_,_,_,_,_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.onEscapedExp failed .\n");
      then fail();
         
  end matchcontinue;
end onEscapedExp;


public function onNewLine
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
algorithm
  (outExpressionList, outIndentStack, outActualIndent) 
  := matchcontinue (inExpressionList, inIndentStack, inActualIndent, inLineIndent, inAccStringChars)
    local
      list<String> chars, accChars, strLst;
      String c, lesc, resc;
      Boolean isSQ;
      Integer actInd, lineInd, baseInd;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, nexp, eexp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
   
   //drop invisible space before new line 
   case (expLst, indStack, actInd, lineInd, c :: accChars)
      equation
        true = (c ==& " " or c ==& "\t");
        (expLst, indStack,  actInd) 
         = onNewLine(expLst, indStack, actInd, lineInd, accChars);
      then (expLst, indStack, actInd);
          
   //AccStringChars = {}
   // expLst = {} -> the 1. and the only \n in the template (special case) - make permanent
   // ignore lineInd - actInd and lineInd should be 0, anyway 
   case ( {}, indStack, actInd, _, {})
      equation
        expLst = addAccStringChars({}, {"\n"} );        
      then (expLst, indStack,  actInd);
   
   //AccStringChars = {}
   // expLst = ST opened :: _ -> a standalone \n on the line - make permanent
   // ignore lineInd  
   case (expLst as (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = (""::_))) :: _),
       indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );        
      then (expLst, indStack,  actInd);

   //TODO: this does not work, because the <\n> finalizes the previous ST to be closed 
   //AccStringChars = {}
   // expLst = <\n> :: _ -> a forced new line - make permanent - replace with \n
   // ignore lineInd - must be lineInd = actInd  (because the <\n> exp made it so) 
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_NEW_LINE()) :: expLst,
       indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );        
      then (expLst, indStack,  actInd);
      
   //AccStringChars = {}
   // expLst = SNL :: _ -> a standalone \n on the line - make permanent
   // ignore lineInd  
   case (expLst as (TplAbsyn.SOFT_NEW_LINE() :: _) , indStack, actInd, _, {})
      equation
        expLst = addAccStringChars(expLst, {"\n"} );        
      then (expLst, indStack,  actInd);
   
   //AccStringChars = {}
   // expLst = some expression :: _ -> an exp must be last --> Soft new line
   // ignore lineInd - must be lineInd = actInd  (because the exp made it so) 
   case (expLst as (_ :: _) , indStack, actInd, _, {})
      equation
        expLst = TplAbsyn.SOFT_NEW_LINE() :: expLst;        
      then (expLst, indStack,  actInd);
   
   //AccStringChars = (_::_)
   // lineInd >= actInd
   // align the string with prefixed space 
   // put a disposable new line - may be disposed by onTemplEnd() or hardened by addAccStringChars() or finalizeLastStringToken()
   case (expLst, indStack, actInd, lineInd, accChars as (_::_) )
      equation
        true = ( lineInd >= actInd );
        accChars = listAppend(accChars, Util.listFill(" ",lineInd - actInd));
        (TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, false)) :: expLst) 
         = addAccStringChars(expLst, accChars); //must create the ST becase of accChars as (_::_)
        //make the opened last ST be disposable new line
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, true)) :: expLst;        
      then (expLst, indStack,  actInd);
   
   //if the indent is under base indent level, warn and make it 0 level
   //AccStringChars = (_::_)
   // lineInd < actInd
   //pop indent level and try again
   case (expLst, {}, baseInd, lineInd, accChars as (_ :: _))
      equation
        true = ( lineInd < baseInd );
        Debug.fprint("failtrace", "Parse warning onNewLine() - indent level is under the level of the '<<' determined level.\n");
        //call again as  lineInd = baseInd         
        (expLst, indStack,  actInd) = onNewLine(expLst, {}, baseInd, baseInd, accChars);        
      then (expLst, indStack,  actInd);
   
   //AccStringChars = (_::_)
   // lineInd < actInd
   //pop indent level and try again
   //(indStack must have at least one pushed indent level)
   case (expLst, indStack as (_::_), actInd, lineInd, accChars as (_ :: _))
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        (expLst, indStack,  actInd) = onNewLine(expLst, indStack, actInd, lineInd, accChars);        
      then (expLst, indStack,  actInd);

   //should not happen
   case (_,_,_,_,_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.onNewLine failed .\n");
      then fail();
         
  end matchcontinue;
end onNewLine;


public function onTemplEnd
  input Boolean inDropLastNewLine;
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  input list<String> inAccStringChars;
  
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList) 
  := matchcontinue (inDropLastNewLine, inExpressionList, inIndentStack, inActualIndent, 
                    inLineIndent, inAccStringChars)
    local
      list<String> chars, accChars, strLst;
      String c, lesc, resc;
      Boolean dropLastNL;
      Integer actInd, lineInd, baseInd;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, nexp, eexp;
      list<TplAbsyn.Expression> expLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
   
   //AccStringChars = {}
   // expLst = {} - special case, only space in the template  
   // make the space and take it 
   case (_, {}, {}, baseInd, lineInd, {})
      equation
        true = (lineInd >= baseInd);
        expLst = addAccStringChars({}, Util.listFill(" ",lineInd-baseInd)); 
        expLst = finalizeLastStringToken(expLst);
      then expLst;
   
   /*
   //same as previous, but under the '<<' determined level
   //AccStringChars = {}
   // expLst = {} - special case, only space in the template  
   // template is empty 
   case (_, {}, {}, baseInd, lineInd, {})
      equation
        true = (lineInd < baseInd);
        Debug.fprint("failtrace", "Parse warning onTemplEnd() - indent level is under the level of the '<<' determined level.\n");        
      then {};
   */
   
   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = SNL :: _ -> dispose the SNL
   // ignore lineInd 
   // pop all indent 
   case (true, TplAbsyn.SOFT_NEW_LINE() :: expLst, indStack, actInd, _, {})
      equation
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);
      then expLst;
   
   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = ST opened with disposable new line :: _ -> dispose the \n on the line 
   // ignore lineInd  
   // pop all indent
   case (true, TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = strLst as (""::_), lastHasNewLine = true)) :: expLst,
       indStack, actInd, _, {})
      equation
        expLst = finalizeLastStringToken(TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST(strLst, false)) :: expLst);
        (expLst, {},_) = popIndentStack(expLst, indStack, actInd, 0);        
        //TODO: warn when >> is under << determined indent         
      then expLst;

   //if drop-the-last-new-line is set
   //AccStringChars = {}
   // expLst = nothing to be stripped 
   // ignore lineInd - it should be the same as actInd  
   // pop all indent 
   case (true, expLst, indStack, actInd, _, {})
      equation
        expLst = finalizeLastStringToken(expLst);
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);        
      then expLst;
   
   //AccStringChars = (_::_)  or  drop-the-last-new-line is set
   // lineInd >= actInd
   // align the string with prefixed space
   // pop all indent 
   case (_, expLst, indStack, actInd, lineInd, accChars)
      equation
        true = ( lineInd >= actInd );
        accChars = listAppend(accChars, Util.listFill(" ",lineInd - actInd));
        expLst = addAccStringChars(expLst, accChars);
        expLst = finalizeLastStringToken(expLst);
        (expLst, {}, _) = popIndentStack(expLst, indStack, actInd, 0);        
      then expLst;
   
   // lineInd < baseInd
   // the indent is under the base indent level, 
   // warn and make it 0 level
   //pop indent level and try again (only the previous case will be the end of the recursion)
   case (dropLastNL, expLst, {}, baseInd, lineInd, accChars)
      equation
        true = ( lineInd < baseInd );
        Debug.fprint("failtrace", "Parse warning onTemplEnd() - indent level is under the level of the '<<' determined level.\n");
        expLst = onTemplEnd(dropLastNL, expLst, {}, baseInd, baseInd, accChars);         
      then expLst;
   
   // lineInd < actInd
   //pop indent level and try again (only the previous case will be the end of the recursion)
   case (dropLastNL, expLst, indStack as (_::_), actInd, lineInd, accChars)
      equation
        true = ( lineInd < actInd );
        expLst = finalizeLastStringToken(expLst);
        (expLst, indStack, actInd) = popIndentStack(expLst, indStack, actInd, lineInd);
        expLst = onTemplEnd(dropLastNL, expLst, indStack, actInd, lineInd, accChars);         
      then expLst;

   //should not happen
   case (_,_,_,_,_,_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.onTemplEnd failed .\n");
      then fail();
         
  end matchcontinue;
end onTemplEnd;


public function popIndentStack
  input list<TplAbsyn.Expression> inExpressionList;
  input list<tuple<Integer,list<TplAbsyn.Expression>>> inIndentStack;
  input Integer inActualIndent;
  input Integer inLineIndent;
  
  output list<TplAbsyn.Expression> outExpressionList;
  output list<tuple<Integer,list<TplAbsyn.Expression>>> outIndentStack;
  output Integer outActualIndent;
algorithm
  (outExpressionList, outIndentStack, outActualIndent) 
  := matchcontinue (inExpressionList, inIndentStack, inActualIndent, inLineIndent)
    local
      Integer actInd, lineInd, baseInd, d, prevInd;
      list<TplAbsyn.Expression> expLst, prevExpLst;
      list<tuple<Integer,list<TplAbsyn.Expression>>> indStack;
   
        
   case (expLst, (prevInd, prevExpLst) :: indStack, actInd, lineInd)
      equation
        true = (lineInd < actInd); //when actInd > 0 --> something has to be on the stack
        d = actInd - prevInd; //must be positive
        expLst = listReverse(expLst);
        expLst = TplAbsyn.INDENTATION(d, expLst) :: prevExpLst;
        (expLst, indStack,  actInd) = popIndentStack(expLst, indStack, prevInd, lineInd);         
      then (expLst, indStack,  actInd);
   
   case (expLst, indStack, actInd, lineInd)
      equation
        true = (lineInd >= actInd);
      then (expLst, indStack,  actInd);
   
   //base indent
   case (expLst, {}, baseInd, _)
      then (expLst, {},  baseInd);
   
   
   //should not happen
   case (_,_,_,_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.popIndentStack failed .\n");
      then fail();
         
  end matchcontinue;
end popIndentStack;


public function addAccStringChars
  input list<TplAbsyn.Expression> inExpressionList;
  input list<String> inAccStringChars;
  
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList) 
  := matchcontinue (inExpressionList, inAccStringChars)
    local
      list<String> accChars, strLst;
      String str, strNonNl;
      list<TplAbsyn.Expression> expLst;
   
   //AccStringChars = {}
   // nothing
   case ( expLst, {})
      then expLst;
   
   
   // add a string
   // expLst = ST opened with new line :: _
   // merge the pushed new line with previous string without new line
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strNonNl :: strLst), lastHasNewLine = true)) :: expLst,
       accChars as (_::_))
      equation
        failure("\n" = stringGetStringChar(strNonNl, stringLength(strNonNl))); 
        // push the disposable new line
        strNonNl = strNonNl +& "\n";
        str = string_char_list_string(listReverse(accChars));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: strNonNl :: strLst, false)) :: expLst;
      then expLst;
   
   // add a string
   // expLst = ST opened with new line :: _
   // push the disposable new line - previous string has new line
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = true)) :: expLst,
       accChars as (_::_))
      equation
        //"\n" = stringGetStringChar(strNonNl, stringLength(strNonNl)); 
        str = string_char_list_string(listReverse(accChars));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: "\n" :: strLst, false)) :: expLst;
      then expLst;
   
   
   // add a string  
   // expLst = ST opened without new line :: _
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = false)) :: expLst,
       accChars as (_::_))
      equation
        str = string_char_list_string(listReverse(accChars));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST("" :: str :: strLst, false)) :: expLst;
      then expLst;
   
   
   // add a string   
   // expLst = no opened ST  :: _
   case ( expLst, accChars as (_::_))
      equation
        str = string_char_list_string(listReverse(accChars));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST({"", str}, false)) :: expLst;
      then expLst;
   
   
   //should not happen
   case (_,_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.addAccStringChars failed .\n");
      then fail();
         
  end matchcontinue;
end addAccStringChars;


public function finalizeLastStringToken
  input list<TplAbsyn.Expression> inExpressionList;
  
  output list<TplAbsyn.Expression> outExpressionList;
algorithm
  (outExpressionList) 
  := matchcontinue (inExpressionList)
    local
      list<String> accChars, strLst;
      String str, strNonNl;
      list<TplAbsyn.Expression> expLst;
      Boolean hasNL;
   
   
   // expLst = ST opened with new line :: _
   // merge the pushed new line with previous string without new line
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strNonNl :: strLst), lastHasNewLine = true)) :: expLst )
      equation
        failure("\n" = stringGetStringChar(strNonNl, stringLength(strNonNl))); 
        // push the disposable new line
        str = strNonNl +& "\n";
        expLst = finalizeLastStringToken(TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( ""::str::strLst, false)) :: expLst);
      then expLst;
   
   // expLst = ST opened with new line :: _
   // the last string has new line (or empty - should not happen)
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = ("" :: strLst), lastHasNewLine = true)) :: expLst)
      equation
        //"\n" = stringGetStringChar(str, stringLength(str));
        expLst = finalizeLastStringToken(TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( ""::"\n"::strLst, false)) :: expLst);
      then expLst;
   
   
   // expLst = ST opened with new line :: _
   // empty ST - for sure - should not happen  
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" }, lastHasNewLine = false)) :: expLst )
      then expLst;
   
   
   // expLst = ST opened with new line :: _
   // the last and only string has new line 
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , "\n" }, lastHasNewLine = false)) :: expLst )
      equation
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_NEW_LINE()) :: expLst;        
      then expLst;
   
   
   // expLst = ST opened with new line :: _
   // the last and only string has new line => ST_LINE
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , str }, lastHasNewLine = false)) :: expLst )
      equation
        "\n" = stringGetStringChar(str, stringLength(str));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_LINE(str)) :: expLst;        
      then expLst;
   
   // expLst = ST opened with new line :: _
   // the last and only string has NOT a new line  => ST_STRING
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST(strList = { "" , str }, lastHasNewLine = false)) :: expLst )
      equation
        failure("\n" = stringGetStringChar(str, stringLength(str)));
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING(str)) :: expLst;        
      then expLst;
   
   
   // expLst = ST is string list :: _
   // make it a ST_STRING_LIST with properly set lastHasNewLine
   case (TplAbsyn.STR_TOKEN(value = Tpl.ST_STRING_LIST( strList = ("" :: (strLst as (str :: _))), lastHasNewLine = false)) :: expLst )
      equation
        hasNL = ("\n" ==& stringGetStringChar(str, stringLength(str))); 
        strLst = listReverse(strLst);
        expLst = TplAbsyn.STR_TOKEN(Tpl.ST_STRING_LIST( strLst, hasNL)) :: expLst;
      then expLst;
   
   //nothing to be finalized
   case (expLst)
      then expLst;
   
   //should ever not happen
   case (_) 
      equation
        Debug.fprint("failtrace", "Parse unexpected error - TplParser.finalizeLastStringToken failed .\n");
      then fail();
         
  end matchcontinue;
end finalizeLastStringToken;

/*
expressionWithOpts(lesc,resc):
	expression(lesc,resc):exp  
	  separator:sopt 
	  escapedOptions:opts	
	=> makeEscapedExp(exp, listAppend(sopt,opts))
*/
public function expressionWithOpts
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      list<TplAbsyn.EscOption> sopt, opts;
    
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, sopt) = separator(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, opts) = escapedOptions(chars, linfo, lesc, resc);
        exp = makeEscapedExp(exp, listAppend(sopt,opts));
      then (chars, linfo, exp);
   
   case (chars, linfo, _, _) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.expressionWithOpts failed .\n");
      then fail();
        
  end matchcontinue;
end expressionWithOpts;


public function makeEscapedExp
  input TplAbsyn.Expression inExpression;
  input list<TplAbsyn.EscOption> inOptions;
  
  output TplAbsyn.Expression outExpression;
algorithm
  (outExpression) := matchcontinue (inExpression, inOptions)
    local
      TplAbsyn.Expression exp;
      list<TplAbsyn.EscOption> opts;
    
   case (exp, {})
      then exp;
   
   case (exp, opts as (_::_))
      then TplAbsyn.ESCAPED(exp, opts);
        
  end matchcontinue;
end makeEscapedExp;
/*
separator(lesc,resc):
	expression(lesc,resc):sep => { ("separator", SOME(exp)) }
	|
	_ => {}

*/
public function separator
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.EscOption> outSepOption;
algorithm
  (outChars, outLineInfo, outSepOption) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, { ("separator",SOME(exp)) } );
   
   case (chars, linfo, _, _)
      then (chars, linfo, { } );
   
  end matchcontinue;
end separator;
/*
escapedOptions(lesc,resc):
	';' identifier:id  escOptionExp(lesc,resc):expOpt  escapedOptions(lesc,resc):opts
	=> (id, expOpt) :: opts
	|
	_ => {} 

*/
public function escapedOptions
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.EscOption> outOptions;
algorithm
  (outChars, outLineInfo, outOptions) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      Option<TplAbsyn.Expression> expOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case (";" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, expOpt) = escOptionExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, opts) = escapedOptions(chars, linfo, lesc, resc);
      then (chars, linfo, (id, expOpt) :: opts);
   
   case (chars, linfo, _, _)
      then (chars, linfo, {} );
   
  end matchcontinue;
end escapedOptions;
/*
escOptionExp(lesc,resc):
	'=' expression(lesc,resc):exp
	  => SOME(exp)
	|
	_ => NONE
*/
public function escOptionExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<TplAbsyn.Expression> outExpOption;
algorithm
  (outChars, outLineInfo, outExpOption) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      Option<TplAbsyn.Expression> expOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("=" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, SOME(exp));
   
   case (chars, linfo, _, _)
      then (chars, linfo, NONE );
   
  end matchcontinue;
end escOptionExp;


/*
nonTemplateExprWithOpts(lesc,resc):
	nonTemplateExp(lesc,resc):exp  
	  escapedOptions:opts	
	=> makeEscapedExp(exp, opts)
*/
public function nonTemplateExprWithOpts
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      list<TplAbsyn.Expression> expLst;
      list<TplAbsyn.EscOption> sopt, opts;
    
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = nonTemplateExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, opts) = escapedOptions(chars, linfo, lesc, resc);
        exp = makeEscapedExp(exp, opts);
      then (chars, linfo, exp);
   
   case (chars, linfo, _, _) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.nonTemplateExprWithOpts failed .\n");
      then fail();
        
  end matchcontinue;
end nonTemplateExprWithOpts;

/*
nonTemplateExp(lesc,resc):
	pathIdent:name   textExpOrFunCall(name,lesc,resc):exp
	  => exp	
	|
	'(' nonTemplateExprWithOpts(lesc,resc):eexp ')'
	  => eexp
*/
public function nonTemplateExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String lesc, resc;
      TplAbsyn.PathIdent name;
      TplAbsyn.Expression exp;
      
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, name) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = textExpOrFunCall(chars, linfo, name, lesc, resc);
      then (chars, linfo, exp);
   
   case ("(" :: chars, linfo, lesc, resc)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = nonTemplateExprWithOpts(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (")" :: chars) = chars;
      then (chars, linfo, exp);
  
   case (_, _, _, _)
     equation
       Debug.fprint("failtrace", "Parse error - TplParser.nonTemplateExp failed.\n");
     then fail();      
  end matchcontinue;
end nonTemplateExp;

/*
textExpOrFunCall(name,lesc,resc):
	 '=' expression(lesc,resc):exp
	     => TEXT_CREATE(ensurePathIdentBeIdent(name),exp)
	 |
	'+=' expression(lesc,resc):exp
	     => TEXT_ADD(ensurePathIdentBeIdent(name),exp)
	 |
	 funCall(name,lesc,resc):exp  	   
	     =>  exp
*/
public function textExpOrFunCall
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inName;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inName, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp;
      Option<TplAbsyn.Expression> expOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("=":: chars, linfo, name, lesc, resc)
      equation
        id = ensurePathIdentBeIdent(name);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.TEXT_CREATE(id, exp));
   
   case ("+"::"=":: chars, linfo, name, lesc, resc)
      equation
        id = ensurePathIdentBeIdent(name);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.TEXT_ADD(id, exp));
   
   case (chars, linfo, name, lesc, resc)
      equation
        (chars, linfo, exp) = funCall(chars, linfo, name, lesc, resc);        
      then (chars, linfo, exp);
   
  end matchcontinue;
end textExpOrFunCall;

public function ensurePathIdentBeIdent
  input TplAbsyn.PathIdent inPathIdent;  
  output TplAbsyn.Ident outIdent;
algorithm
  (outIdent) := 
  matchcontinue (inPathIdent)
    local
      TplAbsyn.Ident id;
      
   case (TplAbsyn.IDENT(id))
      then id;

   case (TplAbsyn.PATH_IDENT(ident = _))
     equation
       Debug.fprint("failtrace", "Parse error - an identifier expected but found a (dot)path.\n");
     then fail();
   
  end matchcontinue;
end ensurePathIdentBeIdent;
/*
conditionExp(lesc,resc):
	'if' condArgExp(lesc,resc):(isNot, lhsExp, rhsMExpOpt)
	'then' expression(lesc,resc):trueBr
	elseBranch(lesc,resc):elseBrOpt
	 => CONDITION(isNot, lhsExp, rhsMExpOpt, trueBr, elseBranch:elseBrOpt)
*/
public function conditionExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("i"::"f":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, isNot, lhsExp, rhsMExpOpt) = condArgExp(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        ("t"::"h"::"e"::"n":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, trueBr) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, elseBrOpt) = elseBranch(chars, linfo, lesc, resc);
      then (chars, linfo, TplAbsyn.CONDITION(isNot, lhsExp, rhsMExpOpt, trueBr, elseBrOpt));
   
  end matchcontinue;
end conditionExp;
/*
elseBranch(lesc,resc):
	'else' expression(lesc,resc):elseBr
	  => SOME(elseBr)
	|
	_ => NONE

*/
public function elseBranch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output Option<TplAbsyn.Expression> outElseBranchOpt;
algorithm
  (outChars, outLineInfo, outElseBranchOpt) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, elseBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("e"::"l"::"s"::"e":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, elseBr) = expression(chars, linfo, lesc, resc);        
      then (chars, linfo, SOME(elseBr));
   
   case (chars, linfo, lesc, resc)
      then (chars, linfo, NONE);
   
  end matchcontinue;
end elseBranch;
/*
condArgExp:
	'not' expression(lesc,resc):lhsExp
	  => (true, lhsExp, NONE)
	|
	expression(lesc,resc):lhsExp
	  condArgRHS:(isNot, rshMExpOpt)
	 => (isNot,lhsExp, rhsMExpOpt)
*/
public function condArgExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output Boolean outIsNot;
  output TplAbsyn.Expression outLHSExpression;
  output Option<TplAbsyn.MatchingExp> outRHSMExpOpt;
algorithm
  (outChars, outLineInfo, outIsNot, outLHSExpression, outRHSMExpOpt) := 
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, elseBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("n"::"o"::"t":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, lhsExp) = expression(chars, linfo, lesc, resc);        
      then (chars, linfo, true, lhsExp, NONE);
   
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, lhsExp) = expression(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, isNot, rhsMExpOpt) = condArgRHS(chars, linfo);        
      then (chars, linfo, isNot, lhsExp, rhsMExpOpt);
   
  end matchcontinue;
end condArgExp;
/*
condArgRHS:
	'is' 'not' matchBinding:rhsMExp  =>  (true, SOME(rhsMexp))
	|
	'is' matchBinding:rhsMExp  =>  (false, SOME(rhsMexp))
	|
	_ => (false, NONE)
*/
public function condArgRHS
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output Boolean outIsNot;
  output Option<TplAbsyn.MatchingExp> outRHSMExpOpt;
algorithm
  (outChars, outLineInfo, outIsNot, outRHSMExpOpt) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, elseBr;
      TplAbsyn.MatchingExp rhsMExp;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("i"::"s":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("n"::"o"::"t":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rhsMExp) = matchBinding(chars, linfo);
      then (chars, linfo, true, SOME(rhsMExp));
   
   case ("i"::"s":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, rhsMExp) = matchBinding(chars, linfo);
      then (chars, linfo, false, SOME(rhsMExp));
   
   
   case (chars, linfo)
      then (chars, linfo, false, NONE);
   
  end matchcontinue;
end condArgRHS;
/*
matchExp(lesc,resc):
	matchClause(lesc,resc):exp
	    matchCase(lesc,resc):mcaseLst  matchCase_rest(lesc,resc):mcrest
	    => MATCH(exp, listAppend(mcaseLst, mcrest))
*/
public function matchExp
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> mcaseLst, mcrest;
    
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, exp) = matchClause(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mcaseLst) = matchCase(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mcrest) = matchCase_rest(chars, linfo, lesc, resc);
        mcaseLst = listAppend(mcaseLst, mcrest);
      then (chars, linfo, TplAbsyn.MATCH(exp, mcaseLst));
   
  end matchcontinue;
end matchExp;

/*
matchClause(lesc,resc):
	'match' expression:exp => exp
	|
	_ => BOUND_VALUE(IDENT("it"))
*/
public function matchClause
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.Expression outExpression;
algorithm
  (outChars, outLineInfo, outExpression) := matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
    
   case ("m"::"a"::"t"::"c"::"h":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
      then (chars, linfo, exp);
   
   case (chars, linfo, lesc, resc)
      then (chars, linfo, TplAbsyn.BOUND_VALUE(TplAbsyn.IDENT("it")));
        
  end matchcontinue;
end matchClause;
/*
matchCase(lesc,resc):
	'case'  matchBinding:mexp	matchCaseHeads(): mexpHeadLst  
	'then'  expression:exp
	   => makeMatchCaseLst(mexp::mexpHeadLst,exp)
*/
public function matchCase
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCaseLst;
algorithm
  (outChars, outLineInfo, outMatchCaseLst) := 
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> matchCaseLst;
    
   case ("c"::"a"::"s"::"e":: chars, linfo, lesc, resc)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexpHeadList) = matchCaseHeads(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);        
        ("t"::"h"::"e"::"n":: chars) = chars;
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, exp) = expression(chars, linfo, lesc, resc);
        matchCaseLst = makeMatchCaseLst(mexp::mexpHeadList,exp);
      then (chars, linfo, matchCaseLst);
        
  end matchcontinue;
end matchCase;

/*
matchCaseHeads(lesc,resc):
	'case'  matchBinding:mexp	matchCaseHeads(): mexpHeadLst  
	   => mexp :: mexpHeadLst
	|
	_ => {}
*/
public function matchCaseHeads
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.MatchingExp> outMExpHeadLst;
algorithm
  (outChars, outLineInfo, outMExpHeadLst) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> matchCaseLst;
    
   case ("c"::"a"::"s"::"e":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexpHeadList) = matchCaseHeads(chars, linfo);        
      then (chars, linfo, mexp :: mexpHeadList);

   case (chars, linfo)
      then (chars, linfo, {});
   
        
  end matchcontinue;
end matchCaseHeads;


public function makeMatchCaseLst
  input list<TplAbsyn.MatchingExp> inMExpHeadLst;
  input TplAbsyn.Expression inExpression;
  
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCaseLst;
algorithm
  (outMatchCaseLst) := 
  matchcontinue (inMExpHeadLst, inExpression)
    local
      TplAbsyn.Expression exp;
      TplAbsyn.MatchingExp mexp;
      list<TplAbsyn.MatchingExp> mexpHeadList;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> matchCaseLst;
    
   case ({}, _)  then {};

   case (mexp :: mexpHeadList, exp)
      equation
        matchCaseLst = makeMatchCaseLst(mexpHeadList,exp);
      then ((mexp, exp) :: matchCaseLst);
        
  end matchcontinue;
end makeMatchCaseLst;

/*
matchCase_rest(lesc,resc):
	matchCase(lesc,resc):mcaseLst  matchCase_rest(lesc,resc):mcrest
	  => listAppend(mcaseLst, mcrest)
	|
	_ => {}
*/
public function matchCase_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  input String inLeftEsc;
  input String inRightEsc;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> outMatchCases;
algorithm
  (outChars, outLineInfo, outMatchCases) := 
  matchcontinue (inChars, inLineInfo, inLeftEsc, inRightEsc)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.TypedIdents fields,inargs,outargs;
      TplAbsyn.TypeSignature ts;
      Tpl.StringToken st;
      TplAbsyn.Expression exp, bexp, lhsExp, trueBr;
      TplAbsyn.MatchingExp mexp;
      Option<TplAbsyn.MatchingExp> rhsMExpOpt;
      Option<TplAbsyn.Expression> elseBrOpt;
      list<TplAbsyn.Expression> expLst;
      TplAbsyn.EscOption sopt;
      list<TplAbsyn.EscOption> opts;
      list<tuple<TplAbsyn.MatchingExp, TplAbsyn.Expression>> mcaseLst, mcrest;
    
   case (chars, linfo, lesc, resc)
      equation
        (chars, linfo, mcaseLst) = matchCase(chars, linfo, lesc, resc);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mcrest) = matchCase_rest(chars, linfo, lesc, resc);
        mcaseLst = listAppend(mcaseLst, mcrest);
      then (chars, linfo, mcaseLst);
   
   case (chars, linfo, _, _)
      then (chars, linfo, {});
        
  end matchcontinue;
end matchCase_rest;
/*
matchBinding:
	matchBinding_base:headMExp  matchBinding_tail(headMExp):mexp
	  => mexp

*/
public function matchBinding
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.MatchingExp headMExp, mexp;
      
   case (chars, linfo)
      equation
        (chars, linfo, headMExp) = matchBinding_base(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding_tail(chars, linfo, headMExp);
      then (chars, linfo, mexp);
   
  end matchcontinue;
end matchBinding;
/*
matchBinding_tail(headMExp):
	'::' matchBinding:restMExp
	  => LIST_CONS_MATCH(headMExp, restMExp)
	|
	_ => headMExp
*/
public function matchBinding_tail
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.MatchingExp inHeadMatchingExp;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo, inHeadMatchingExp)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp;
      
   case (":"::":":: chars, linfo, headMExp)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, restMExp) = matchBinding(chars, linfo);        
      then (chars, linfo, TplAbsyn.LIST_CONS_MATCH(headMExp, restMExp));
   
   case (chars, linfo, headMExp)
      then (chars, linfo, headMExp);
   
  end matchcontinue;
end matchBinding_tail;
/*
matchBinding_base:
	'SOME' someBinding_rest:mexp 
	  => SOME_MATCH(mexp)
	|
	'NONE' takeEmptyBraces
	  => NONE_MATCH()
	|
	'(' matchBinding:headMExp  tupleOrSingleMatch(headMExp):mexp ')'
	  => mexp
	|
	'{' '}'
	  => LIST_MATCH({})
	|
	'{' matchBinding:headMExp  listMatch_rest:mrest '}
	  => LIST_MATCH(headMExp :: mrest)
	|
	stringConstant:strRevList 
	  => STRING_MATCH(stringAppendList(listReverse(strRevList))
	|
	literalConstant:(str,litType) 
	  => LITERAL_MATCH(str,litType)
	|
	'_'
	  => REST_MATCH()
	|
	pathIdent:pid  afterIdentBinding(pid):mexp
	  => mexp
*/
public function matchBinding_base
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, strRevList;
      LineInfo linfo;
      String str;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name, pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp;
      list<TplAbsyn.MatchingExp> mrest;
      TplAbsyn.TypeSignature ts;
      
   case ("S"::"O"::"M"::"E":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = someBinding_rest(chars, linfo);        
      then (chars, linfo, TplAbsyn.SOME_MATCH(mexp));
   
   case ("N"::"O"::"N"::"E":: chars, linfo)
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo) = takeEmptyBraces(chars, linfo);        
      then (chars, linfo, TplAbsyn.NONE_MATCH());

   case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, headMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = tupleOrSingleMatch(chars, linfo, headMExp);
        (chars, linfo) = interleave(chars, linfo);
        (")"::chars) = chars;
      then (chars, linfo, mexp);

   case ("{":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        ("}"::chars) = chars;
      then (chars, linfo, TplAbsyn.LIST_MATCH({}));
   
   case ("{":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, headMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        ("}"::chars) = chars;
      then (chars, linfo, TplAbsyn.LIST_MATCH(headMExp :: mrest));

   case (chars, linfo)
      equation
        (chars, linfo, strRevList) = stringConstant(chars, linfo);
        str = Util.stringAppendList(listReverse(strRevList));
      then (chars, linfo, TplAbsyn.STRING_MATCH(str));

   case (chars, linfo)
      equation
        (chars, linfo, str, ts) = literalConstant(chars, linfo);
      then (chars, linfo, TplAbsyn.LITERAL_MATCH(str,ts));

   case ("_":: chars, linfo)
      then (chars, linfo, TplAbsyn.REST_MATCH());
   
   case (chars, linfo)
      equation
        (chars, linfo, pid) = pathIdent(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = afterIdentBinding(chars, linfo, pid);
      then (chars, linfo, mexp);
  
  case (chars, linfo) 
      equation
        Debug.fprint("failtrace", "Parse error - TplParser.matchBinding_base failed .\n");
      then fail(); 
   
  end matchcontinue;
end matchBinding_base;
/*
someBinding_rest:
	'(' ')'
	  => SOME_MATCH(REST_MATCH())
	|
	'(' matchBinding:mexp ')'
	  => SOME_MATCH(mexp)
	|
	_ => SOME_MATCH(REST_MATCH())
*/
public function someBinding_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, strRevList;
      LineInfo linfo;
      String str;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name, pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp;
      list<TplAbsyn.MatchingExp> mrest;
      TplAbsyn.TypeSignature ts;
      
   case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")"::chars) = chars;
      then (chars, linfo, TplAbsyn.REST_MATCH());

   case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (")"::chars) = chars;
      then (chars, linfo, mexp);

   case (chars, linfo)
      then (chars, linfo, TplAbsyn.REST_MATCH());
 
  end matchcontinue;
end someBinding_rest;
/*
takeEmptyBraces:
	'(' ')'
	|
	_
*/
public function takeEmptyBraces
  input list<String> inChars;
  input LineInfo inLineInfo;
  output list<String> outChars;
  output LineInfo outLineInfo;
algorithm
  (outChars, outLineInfo) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars, strRevList;
      LineInfo linfo;
      String str;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name, pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp;
      list<TplAbsyn.MatchingExp> mrest;
      TplAbsyn.TypeSignature ts;
      
   case ("(":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")"::chars) = chars;
      then (chars, linfo);

   case (chars, linfo)
      then (chars, linfo);
 
  end matchcontinue;
end takeEmptyBraces;
/*
tupleOrSingleMatch(headMExp):
	',' matchBinding:secMExp  listMatch_rest:mrest
	  => TUPLE_MATCH(headMExp :: secMExp :: mrest)
	|
	_ => headMExp 

*/
public function tupleOrSingleMatch
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.MatchingExp inHeadMatchingExp;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo, inHeadMatchingExp)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp, secMExp;
      list<TplAbsyn.MatchingExp> mrest;
      
   case (",":: chars, linfo, headMExp)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, secMExp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);        
      then (chars, linfo, TplAbsyn.TUPLE_MATCH(headMExp :: secMExp :: mrest));
   
   case (chars, linfo, headMExp)
      then (chars, linfo, headMExp);
   
  end matchcontinue;
end tupleOrSingleMatch;
/*
listMatch_rest:
	',' matchBinding:mexp  listMatch_rest:mrest
	  => mexp :: mrest
	|
	_ => {}

*/
public function listMatch_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<TplAbsyn.MatchingExp> outMatchingExpListRest;
algorithm
  (outChars, outLineInfo, outMatchingExpListRest) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent name;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp, secMExp;
      list<TplAbsyn.MatchingExp> mrest;
      
   case (",":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mrest) = listMatch_rest(chars, linfo);        
      then (chars, linfo, mexp :: mrest);
   
   case (chars, linfo)
      then (chars, linfo, {});
   
  end matchcontinue;
end listMatch_rest;
/*
afterIdentBinding(pid):
	'(' ')' 
	  => RECORD_MATCH(pid, {})
	|
	'(' fieldBinding:fb  fieldBinding_rest:fbs ')'
	  => RECORD_MATCH(pid, fb::fbs)
	|
	{pid is PATH_IDENT}
	=> RECORD_MATCH(pid, {}) 
	|
	{pid is IDENT(id)}
	'as' matchBinding:mexp
	  => BIND_AS_MATCH(id, mexp)
	|
	{pid is IDENT(id)}
	_ => BIND_MATCH(id)
*/
public function afterIdentBinding
  input list<String> inChars;
  input LineInfo inLineInfo;
  input TplAbsyn.PathIdent inPathIdent;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output TplAbsyn.MatchingExp outMatchingExp;
algorithm
  (outChars, outLineInfo, outMatchingExp) := 
  matchcontinue (inChars, inLineInfo, inPathIdent)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp, secMExp;
      list<TplAbsyn.MatchingExp> mrest;
      tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> fb;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> fbs;
      
   case ("(":: chars, linfo, pid)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (")":: chars) = chars;
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, {}));
   
   case ("(":: chars, linfo, pid)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fb) = fieldBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fbs) = fieldBinding_rest(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (")":: chars) = chars;
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, fb::fbs));
   
   case (chars, linfo, pid as TplAbsyn.PATH_IDENT(_,_))
      then (chars, linfo, TplAbsyn.RECORD_MATCH(pid, {}));
        
   case ("a"::"s":: chars, linfo, TplAbsyn.IDENT(id))
      equation
        afterKeyword(chars);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
      then (chars, linfo, TplAbsyn.BIND_AS_MATCH(id, mexp));

   case (chars, linfo, TplAbsyn.IDENT(id))
      then (chars, linfo, TplAbsyn.BIND_MATCH(id));
   
  end matchcontinue;
end afterIdentBinding;



/*
fieldBinding:
	identifier:fldId '=' matchBinding:mexp
	  => (fldId, mexp)
*/
public function fieldBinding
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> outFieldBinding;
algorithm
  (outChars, outLineInfo, outFieldBinding) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp, secMExp;
      list<TplAbsyn.MatchingExp> mrest;
      tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> fb;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> fbs;
      
   case (chars, linfo)
      equation
        (chars, id) = identifier(chars);
        (chars, linfo) = interleave(chars, linfo);
        ("=":: chars) = chars;
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, mexp) = matchBinding(chars, linfo);
      then (chars, linfo, (id, mexp));
   
  end matchcontinue;
end fieldBinding;
/*
fieldBinding_rest:
	',' fieldBinding:fb  fieldBinding_rest:fbs
	  => fb :: fbs
	|
	_ => {}

*/
public function fieldBinding_rest
  input list<String> inChars;
  input LineInfo inLineInfo;
  
  output list<String> outChars;
  output LineInfo outLineInfo;
  output list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> outFieldBindingsRest;
algorithm
  (outChars, outLineInfo, outFieldBindingsRest) := 
  matchcontinue (inChars, inLineInfo)
    local
      list<String> chars;
      LineInfo linfo;
      String c, lesc, resc;
      Boolean isD, isNot;
      TplAbsyn.Ident id;
      TplAbsyn.PathIdent pid;
      TplAbsyn.MatchingExp headMExp, mexp, restMExp, secMExp;
      list<TplAbsyn.MatchingExp> mrest;
      tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp> fb;
      list<tuple<TplAbsyn.Ident, TplAbsyn.MatchingExp>> fbs;
      
   case (",":: chars, linfo)
      equation
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fb) = fieldBinding(chars, linfo);
        (chars, linfo) = interleave(chars, linfo);
        (chars, linfo, fbs) = fieldBinding_rest(chars, linfo);
      then (chars, linfo, fb :: fbs);
   
   case (chars, linfo)
      then (chars, linfo, {});
   
  end matchcontinue;
end fieldBinding_rest;


end TplParser;