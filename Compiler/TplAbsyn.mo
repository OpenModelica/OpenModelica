package TplAbsyn

public import Debug;
public import Util;
public import System;

public import Tpl;
protected import TplCodegen;

/* Input AST */
public type Ident = String;
public type TypedIdents = list<tuple<Ident, TypeSignature>>;
public type EscOption = tuple<Ident, Option<Expression>>;  
public type StringToken = Tpl.StringToken;
public type Tokens = Tpl.Tokens;


public
uniontype PathIdent
  record IDENT
    Ident ident;    
  end IDENT;
  
  record PATH_IDENT
    Ident ident;
    PathIdent path;
  end PATH_IDENT;
end PathIdent;

public
uniontype TypeSignature
  record LIST_TYPE
    TypeSignature ofType;
  end LIST_TYPE;
  
  record ARRAY_TYPE  // one-dimensional arrays --> with only (safe) list behaviour
    TypeSignature ofType;
  end ARRAY_TYPE;
  
  record OPTION_TYPE
    TypeSignature ofType;
  end OPTION_TYPE;
  
  record TUPLE_TYPE
    list<TypeSignature> ofTypes;
  end TUPLE_TYPE;
  
  record NAMED_TYPE "key/path to a TypeInfo list from an AST definition"
    PathIdent name;
  end NAMED_TYPE;
  
  record STRING_TYPE  end STRING_TYPE;
  record TEXT_TYPE    end TEXT_TYPE;
  record STRING_TOKEN_TYPE "Used only for internal string constants." end STRING_TOKEN_TYPE;
  
  record INTEGER_TYPE end INTEGER_TYPE;
  record REAL_TYPE    end REAL_TYPE;
  record BOOLEAN_TYPE end BOOLEAN_TYPE;

  record UNRESOLVED_TYPE "Errorneous resolving type. Only used during elaboration phase."
    String reason; 
  end UNRESOLVED_TYPE;
end TypeSignature;

uniontype ParseInfo 
  record PARSE_INFO
    String fileName;
    //Boolean isReadOnly "isReadOnly : (true|false). Should be true for libraries" ;
    Integer lineNumberStart "lineNumberStart" ;
    Integer columnNumberStart "columnNumberStart" ;
    Integer lineNumberEnd "lineNumberEnd" ;
    Integer columnNumberEnd "columnNumberEnd" ;
    //TimeStamp buildTimes "Build and edit times";   
  end PARSE_INFO;
end ParseInfo;

public
uniontype Expression
  record TEMPLATE
    list<Expression> items;
    String lquote; // just preserved for effective quoted dump
    String rquote;
  end TEMPLATE;
  
  record STR_TOKEN
    StringToken value; //only one of ST_STRING, ST_NEW_LINE or ST_STRING_LIST
  end STR_TOKEN;
  
  record LITERAL
    String value;
    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
  end LITERAL;
  
  record SOFT_NEW_LINE end SOFT_NEW_LINE; //appears only in a TEMPLATE
    
  record BOUND_VALUE
    PathIdent boundPath;
  end BOUND_VALUE;

  record FUN_CALL
    PathIdent name;
    list<Expression> args;
  end FUN_CALL;
  
  record CONDITION
    Boolean isNot "Is not or inequal";
    Expression lhsExp;
    Option<MatchingExp> rhsValue;
    Expression trueBranch;
    Option<Expression> elseBranch;
  end CONDITION;

  record MATCH
    Expression matchExp;
    list<tuple<MatchingExp,Expression>> cases;
  end MATCH;
  
  record MAP
    //list<tuple<Expression, MatchingExp>> bindings; // default/empty MatchingExp is 'it'
    //only 1 argument allowed in the first impl
    Expression argExp;
    MatchingExp ofBinding; // default/empty MatchingExp is 'it'
    Expression mapExp;
  end MAP;

  record MAP_ARG_LIST
    list<Expression> parts; // a part is a scalar or a list
  end MAP_ARG_LIST;
  
  record ESCAPED
    Expression exp;
    //Option<Expression> separator;
    list<EscOption> options;
  end ESCAPED;
  
  record INDENTATION "Indented block."
    Integer width;
    list<Expression> items;
  end INDENTATION;
  
  record TEXT_CREATE
    Ident name;
    Expression exp;
  end TEXT_CREATE;

  record TEXT_ADD
    Ident name;
    Expression exp;
  end TEXT_ADD;
  
  record NORET_CALL
    PathIdent name;
    list<Expression> args;
  end NORET_CALL;
  
end Expression;

public
uniontype MatchingExp
  record BIND_AS_MATCH
    Ident bindIdent;
    MatchingExp matchingExp;
  end BIND_AS_MATCH;
  
  record BIND_MATCH 
    Ident bindIdent;
  end BIND_MATCH;
  
  record RECORD_MATCH
    PathIdent tagName;
    list<tuple<Ident, MatchingExp>> fieldMatchings;
  end RECORD_MATCH;
  
  record SOME_MATCH
    MatchingExp value;
  end SOME_MATCH;
  
  record NONE_MATCH end NONE_MATCH;
  
  record TUPLE_MATCH
    list<MatchingExp> tupleArgs;
  end TUPLE_MATCH;

  record LIST_MATCH
    list<MatchingExp> listElts; //empty list included  
  end LIST_MATCH;
  
  record LIST_CONS_MATCH
    MatchingExp head;
    MatchingExp rest;
  end LIST_CONS_MATCH;
  
  record STRING_MATCH
    String value;
  end STRING_MATCH;
  
  record LITERAL_MATCH
    String value;
    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
  end LITERAL_MATCH;
  
  record REST_MATCH end REST_MATCH;
end MatchingExp;


public
uniontype TypeInfo
  record TI_UNION_TYPE
    list<tuple<Ident, TypedIdents>> recTags;
  end TI_UNION_TYPE;
  
  record TI_RECORD_TYPE
    TypedIdents fields;
  end TI_RECORD_TYPE;
  
  record TI_ALIAS_TYPE
    TypeSignature aliasType;
  end TI_ALIAS_TYPE;
  
  record TI_FUN_TYPE "Imported AST/builtin functions."
    TypedIdents inArgs;
    TypedIdents outArgs;
    //Ident callName; ... can be made as direct/wrapper calls
  end TI_FUN_TYPE;
  
  record TI_CONST_TYPE "Imported AST constants."
    TypeSignature constType;
  end TI_CONST_TYPE;  
end TypeInfo;

public
uniontype ASTDef
  record AST_DEF
    PathIdent importPackage;
    Boolean isDefault;
    list<tuple<Ident, TypeInfo>> types;
  end AST_DEF;
end ASTDef;    


public
uniontype TemplPackage
  record TEMPL_PACKAGE
    PathIdent name;
    //list<PathIdent> extendsList;
    list<ASTDef> astDefs;
    list<tuple<Ident,TemplateDef>> templateDefs;     
  end TEMPL_PACKAGE;
end TemplPackage;

public
uniontype TemplateDef
  record STR_TOKEN_DEF
    StringToken value; //only one of ST_STRING, ST_NEW_LINE, ST_LINE or ST_STRING_LIST
  end STR_TOKEN_DEF;
  
  record LITERAL_DEF
    String value;
    TypeSignature litType; // only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
  end LITERAL_DEF;
  
  record TEMPLATE_DEF
    TypedIdents args;
    String lesc; // just preserved for original-like quoted dump
    String resc;
    Expression exp;
  end TEMPLATE_DEF;
end TemplateDef;

/* Output AST */
//type MMPublic = Boolean;
public
uniontype MMPackage
  record MM_PACKAGE
    PathIdent name;
    list<MMDeclaration> mmDeclarations;      
  end MM_PACKAGE;
end MMPackage;

public type MMMatchCase = tuple<list<MatchingExp>, TypedIdents, list<MMExp>>;

public  
uniontype MMDeclaration
  record MM_IMPORT
    Boolean isPublic;
    PathIdent packageName;
  end MM_IMPORT;
  
  record MM_STR_TOKEN_DECL
    Boolean isPublic;
    Ident name;
    StringToken value;
  end MM_STR_TOKEN_DECL;
  
  record MM_LITERAL_DECL
    Boolean isPublic;
    Ident name;
    String value;
    TypeSignature litType;
  end MM_LITERAL_DECL;
  
  
  record MM_FUN
    Boolean isPublic;
    Ident name;
    TypedIdents inArgs; //inTxt inclusive
    TypedIdents outArgs; // outTxt + extra Texts
    TypedIdents locals;
    list<MMExp> statements;
    
    Option<GenInfo> genInfoOpt "internal use only";       
  end MM_FUN;    
end MMDeclaration;

public
uniontype MMExp
  record MM_ASSIGN
    list<Ident> lhsArgs;
    MMExp rhs;
  end MM_ASSIGN;
  
  record MM_FN_CALL
    PathIdent fnName;
    list<MMExp> args;
  end MM_FN_CALL;
  
  record MM_IDENT
    PathIdent ident;
  end MM_IDENT;
  
  record MM_STR_TOKEN "constructor of type StringToken"
    StringToken value;
  end MM_STR_TOKEN;
  
  record MM_STRING "to pass a string constant as parameter of type String" 
    String value;
  end MM_STRING;
  
  record MM_LITERAL "to pass a literal constant as parameter of type Integer, Real or Boolean" 
    String value;    
  end MM_LITERAL;
  
  record MM_MATCH
    list<MMMatchCase> matchCases;
  end MM_MATCH;  
end MMExp;



/* internal types */
constant Ident imlicitTxt = "txt";
constant Ident inPrefix = "in_";
constant Ident outPrefix = "out_";
//constant Ident imlicitInTxt = "intxt"; //not used ... there can be the same names for in/ou values 
//constant Ident imlicitOutTxt = "outtxt";

constant tuple<Ident,TypeSignature> imlicitTxtArg = (imlicitTxt, TEXT_TYPE());
constant MatchingExp imlicitTxtMExp = BIND_MATCH(imlicitTxt);

constant Ident emptyTxt = "emptyTxt";
constant Ident errorIdent = "!error!";

constant Tpl.IterOptions defaultIterOptions 
  = Tpl.ITER_OPTIONS(0, NONE, NONE, 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE());


constant Ident indexOffsetOptionId    = "indexOffset";
constant Ident emptyOptionId          = "empty";
constant Ident separatorOptionId      = "separator";
constant Ident alignNumOptionId       = "align";
constant Ident alignNumOffsetOptionId = "alignOffset";
constant Ident alignSeparatorOptionId = "alignSeparator";
constant Ident wrapWidthOptionId      = "wrap";
constant Ident wrapSeparatorOptionId  = "wrapSeparator";

constant Ident indentOptionId    = "indent";
constant Ident absIndentOptionId = "absIndent";
constant Ident relIndentOptionId = "relIndent";
constant Ident anchorOptionId    = "anchor";

//constant defaultMMOptions
constant list<MMEscOption> defaultEscOptions = {
  (indexOffsetOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (emptyOptionId, (MM_FN_CALL(IDENT("SOME"), {MM_STR_TOKEN(Tpl.ST_STRING(""))}), OPTION_TYPE(STRING_TOKEN_TYPE())) ),
  (separatorOptionId, (MM_LITERAL("NONE"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),  
  
  (alignNumOptionId, (MM_LITERAL("10"), INTEGER_TYPE()) ),
  (alignNumOffsetOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (alignSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE()) ),
  
  (wrapWidthOptionId, (MM_LITERAL("100"), INTEGER_TYPE()) ),
  (wrapSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE())),
  
  (indentOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (absIndentOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (relIndentOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (anchorOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) )

  //("noIndent", (MM_LITERAL("true"),BOOLEAN_TYPE()) ),
  
  //("parseNewLine", (MM_LITERAL("true"), UNRESOLVED_TYPE("No value - only compile time option.")) )
};



constant list<MMEscOption> nonSpecifiedIterOptions = {
  (indexOffsetOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (emptyOptionId, (MM_LITERAL("NONE"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),
  (separatorOptionId, (MM_LITERAL("NONE"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),  
  
  (alignNumOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (alignNumOffsetOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (alignSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE()) ),
  
  (wrapWidthOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (wrapSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE()))  
};


type MMEscOption = tuple<Ident,tuple<MMExp, TypeSignature>>;
type ScopeEnv = list<Scope>;

uniontype Scope
  record FUN_SCOPE
    TypedIdents args;
    //TypedIdents usedArgs; ... will be derived from MMExp 
    //TypedIdents outArgs; ... will be derived from MMExp
  end FUN_SCOPE;
  
  record CASE_SCOPE
    MatchingExp mExp;
    TypeSignature mType;
    TypedIdents extArgs;
    Ident itName;
  end CASE_SCOPE;
  
  record LOCAL_SCOPE
    Ident ident;
    TypeSignature idType;
    //Boolean isUsed;    
  end LOCAL_SCOPE;  
end Scope;


uniontype MapContext
  record MAP_CONTEXT
    //list<TypeSignature, MMDeclaration> mapFunctions;
    MatchingExp ofBinding;
    Expression mapExp;
    list<MMEscOption> iterMMExpOptions;
    TypedIdents indexedArgs "i0 and/or i1";
    Boolean useIter "Whether PushIter/NextIter/PopIter is necessary.";   
  end MAP_CONTEXT;
end MapContext;

uniontype GenInfo
  record GI_MAP_FUN
    TypeSignature mapType;
    MapContext mapContext;
  end GI_MAP_FUN;
end GenInfo;


// *** functions ***

public function transformAST
  input TemplPackage inTplPackage;
  output MMPackage outMMPackage;
algorithm
  outMMPackage := matchcontinue (inTplPackage)
    local
      PathIdent name;
      list<tuple<Ident,TemplateDef>>  templateDefs;
      list<MMDeclaration> mmDeclarations;
      TemplPackage tp;
      list<ASTDef> astDefs;
      
    case (TEMPL_PACKAGE(
            name = name,
            astDefs = astDefs,
            templateDefs = templateDefs))
      equation
        astDefs = fullyQualifyASTDefs(astDefs);
        templateDefs = listMap1Tuple22(templateDefs, fullyQualifyTemplateDef, astDefs);        
        mmDeclarations = importDeclarations(astDefs, {}); 
        mmDeclarations 
         = transformTemplateDefs(templateDefs, TEMPL_PACKAGE(name,astDefs,templateDefs), mmDeclarations);
        mmDeclarations = listReverse(mmDeclarations); 
      then 
        MM_PACKAGE(name, mmDeclarations);
  end matchcontinue;           
end transformAST;


public function importDeclarations
  input list<ASTDef> inASTDefs;
  input list<MMDeclaration> inAccMMDecls;
  
  output list<MMDeclaration> outMMDecls;
algorithm
  outMMDecls := matchcontinue (inASTDefs, inAccMMDecls)
    local
      list<ASTDef> restASTDefs;
      PathIdent importPackage;
      Boolean isDefault;
      list<MMDeclaration> accMMDecls;
      
    case ( {} , accMMDecls ) 
      then accMMDecls;

    case ( AST_DEF(importPackage = importPackage, isDefault = isDefault) :: restASTDefs, accMMDecls )
      then 
        importDeclarations(restASTDefs, 
                          (MM_IMPORT(isDefault, importPackage) :: accMMDecls));
    
  end matchcontinue;           
end importDeclarations;

public function transformTemplateDefs
  input list<tuple<Ident,TemplateDef>>  inTemplateDefsRest;
  input TemplPackage inTplPackage;
  input list<MMDeclaration> inAccMMDecls;
  
  output list<MMDeclaration> outMMDecls;
algorithm
  outMMDecls := matchcontinue (inTemplateDefsRest, inTplPackage, inAccMMDecls)
    local
      Ident tplname;
      list<tuple<Ident,TemplateDef>> restTDefs;
      TemplPackage tplPackage;
      list<MMDeclaration> mmDecls, accMMDecls;
      StringToken stvalue;
      TypedIdents targs, locals, iargs, oargs;
      Expression texp;
      list<MMExp> stmts;
      MMDeclaration mmFun;
      String svalue;
      TypeSignature litType; 
      
    case ( {} , _, accMMDecls ) 
      then accMMDecls;

    case ( (tplname, STR_TOKEN_DEF(value = stvalue)) :: restTDefs, tplPackage, accMMDecls )
      equation
        tplname = "c_" +& tplname; //no encoding needed, just denoting it is a constant (only for readibility)
        mmDecls = transformTemplateDefs(restTDefs, tplPackage,
                  (MM_STR_TOKEN_DECL(true, tplname, stvalue) :: accMMDecls));
      then mmDecls;
    
    case ( (tplname, LITERAL_DEF(value = svalue, litType = litType)) :: restTDefs, tplPackage, accMMDecls )
      equation
        tplname = "c_" +& tplname; //actually, literals are inlined, so this is just for presence of the constant in the source
        mmDecls = transformTemplateDefs(restTDefs, tplPackage,
                  (MM_LITERAL_DECL(true, tplname, svalue, litType) :: accMMDecls));
      then mmDecls;
    
    case ( (tplname, TEMPLATE_DEF(args = targs, exp = texp)) :: restTDefs, tplPackage, accMMDecls )
      equation
        targs = Util.listMap(targs, encodeTypedIdent);
        
        //only out parameters (all are Texts only) in the assignments ':=' will have the "out_" prefix in the statements
        //the rest is tailored into templates
        //... but function signatures have no prefixes in their AST representations (iargs, oargs, ...)
        (stmts, locals, _, accMMDecls,_) 
          = statementsFromExp(texp, {}, {}, imlicitTxt, /*outPrefix +&*/ imlicitTxt, {},  
               { FUN_SCOPE(targs) },  tplPackage, accMMDecls);
        
        //template functions will have unencoded original names
        //TODO: should be done some checks for uniqueness / keywords collisions ...   
        //tplname = encodeIdent(tplname);
        iargs = imlicitTxtArg :: targs;
        oargs = Util.listFilter(iargs, isText);
        stmts = listReverse(stmts);
        stmts = addOutPrefixes(stmts, oargs, {});
        (stmts, locals, accMMDecls) = inlineLastFunIfSingleCall(iargs, oargs, stmts, locals, accMMDecls);
        mmFun = MM_FUN(true, tplname, iargs, oargs, locals, stmts, NONE);
      then 
        transformTemplateDefs(restTDefs, tplPackage, mmFun :: accMMDecls);
    
  end matchcontinue;           
end transformTemplateDefs;


public function inlineLastFunIfSingleCall
  input TypedIdents inInArgs;
  input TypedIdents inOutArgs;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input list<MMDeclaration> inAccMMDecls;
  
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output list<MMDeclaration> outMMDecls;
algorithm
  (outStmts, outLocals, outMMDecls)
  := matchcontinue (inInArgs, inOutArgs, inStmts, inLocals, inAccMMDecls)
    local
      list<MMExp> stmts;
      Ident fidCalled, fidLast;
      TypedIdents locals, iargs, oargs, iargsL, oargsL;
      list<MMDeclaration> accMMDecls;
    
    // the last call is the only call of the last elaborated function (from makeMatchFun)  
    case ( iargs, oargs, 
          { MM_ASSIGN(rhs = MM_FN_CALL(fnName = IDENT(fidCalled)) ) },
          {}, 
          MM_FUN(_, fidLast, iargsL, oargsL, locals, stmts, NONE) :: accMMDecls)
      equation
        equality(fidCalled = fidLast);
        equality(iargs = iargsL);
        equality(oargs = oargsL);
      then ( stmts, locals, accMMDecls );
    
    //otherwise nothing
    case ( _, _, stmts, locals, accMMDecls)
      then ( stmts, locals, accMMDecls );
    
  end matchcontinue;           
end inlineLastFunIfSingleCall;


//prepend "i" in front of the ident to obey the MM rule that no identifier can start with "_"
public function encodeIdent
  input Ident inIdent;
  output Ident outIdent;  
algorithm
  outIdent := "i" +& encodeIdentNoPrefix(inIdent);          
end encodeIdent;

//every ident encode as ".ident"
//where "." is encoded as "_" or "_0" in the case it is followed with "_" (ident starts with _)
public function encodeIdentNoPrefix
  input Ident inIdent;
  output Ident outIdent;  
algorithm
  (outIdent) := matchcontinue (inIdent)
    local
      Ident ident;                  

    //to prevent ambiguity when the first character is "_", encode the dot as "_0"
    case ( ident  )
      equation
        true = (stringLength(ident) > 0) and (stringGetStringChar(ident,1) ==& "_"); 
        ident = "_0" +& System.stringReplace(ident, "_", "__");        
      then
        ( ident );
        
    case ( ident  )
      equation
        //false = (stringLength(ident) > 0) and (stringGetStringChar(ident,1) ==& "_");
        ident = "_" +& System.stringReplace(ident, "_", "__");
        
        //the following is not needed now
        //internal idents encodings can use a "." after the indent to prevent name collitions
        //used for example for auto to-string conversion of Option values, see addWriteCallFromMMExp()
        //ident = System.stringReplace(ident, ".", "_");
      then
        ( ident );
    
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!encodeIdentNoPrefix failed\n");
      then
        fail();
  end matchcontinue;           
end encodeIdentNoPrefix;

//only the "head" of the PathIdent to be encoded
//but the encoded outIdent has encoded all parts of the inPath and concatenated
public function encodePathIdent
  input PathIdent inPath;
  output Ident outIdent;
  output PathIdent outPath;  
algorithm
  (outIdent, outPath) := matchcontinue (inPath)
    local
      PathIdent path;
      Ident ident, encident, encpath;
      
    case ( IDENT(ident = ident) )
      equation
        encident = encodeIdent(ident);
      then
        (encident, IDENT(encident));
        
    case ( PATH_IDENT(ident = ident, path = path) )
      equation
        encident = encodeIdent(ident);
        ident = encident  +&  encodePath(path);
      then
        (ident, PATH_IDENT(encident, path)); //only the head of the PATH_IDENT
    
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!encodePathIdent failed\n");
      then
        fail();
  end matchcontinue;           
end encodePathIdent;

//concatenation of ecoded ".ident" on the path
//use encodeIdentNoPrefix as all of the encoded parts are appended to a head that already has an alpha letter at start
public function encodePath
  input PathIdent inPath;
  output Ident outIdent;
algorithm
  (outIdent) := matchcontinue (inPath)
    local
      PathIdent path;
      Ident ident;
      
    case ( IDENT(ident = ident) )
      equation
        ident = encodeIdentNoPrefix(ident);
      then
        ident;
        
    case ( PATH_IDENT(ident = ident, path = path) )
      equation
        ident = encodeIdentNoPrefix(ident)  +&  encodePath(path);
      then
        ident;
    
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!encodePath failed\n");
      then
        fail();
  end matchcontinue;           
end encodePath;


public function encodeTypedIdent
  input tuple<Ident,TypeSignature> inTypedIdent;
  output tuple<Ident,TypeSignature> outTypedIdent;  
algorithm
  (outTypedIdent) := matchcontinue (inTypedIdent)
    local
      Ident ident;
      TypeSignature ts;
      
    case ( (ident, ts) )
      equation
        ident = encodeIdent(ident);
      then
        ( (ident, ts) );
        
    //should not ever happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!encodeTypedIdent failed\n");
      then
        fail();
  end matchcontinue;           
end encodeTypedIdent;


public function encodeMatchingExp 
  input MatchingExp inMExp;
  output MatchingExp outMExp;
algorithm 
  outMExp := matchcontinue (inMExp)
    local
      Ident ident;
      PathIdent tagn;
      list<tuple<Ident, MatchingExp>> fms;
      MatchingExp mexp, restmexp;
      list<MatchingExp> mexpLst;
    
    case ( BIND_AS_MATCH(
             bindIdent = ident,
             matchingExp = mexp
           ) )
      equation
        ident = encodeIdent(ident);
        mexp = encodeMatchingExp(mexp);
      then 
        BIND_AS_MATCH(ident, mexp);
    
    case ( BIND_MATCH( bindIdent = ident ) )
      equation
        ident = encodeIdent(ident);
      then 
        BIND_MATCH(ident);
    
    case ( RECORD_MATCH(
             tagName = tagn,
             fieldMatchings = fms
           ) )
      equation
        fms = Util.listMap(fms, encodeFieldMatching);
      then 
        RECORD_MATCH(tagn, fms);

    case ( SOME_MATCH( value = mexp ) )
      equation
        mexp = encodeMatchingExp(mexp);
      then 
        SOME_MATCH(mexp);
    
    case ( TUPLE_MATCH( tupleArgs = mexpLst ) )
      equation
        mexpLst = Util.listMap(mexpLst, encodeMatchingExp);
      then 
        TUPLE_MATCH(mexpLst);
    
    case ( LIST_MATCH( listElts = mexpLst ) )
      equation
        mexpLst = Util.listMap(mexpLst, encodeMatchingExp);
      then 
        LIST_MATCH(mexpLst);
    
    case ( LIST_CONS_MATCH( 
             head = mexp,
             rest = restmexp
           ) )
      equation
        mexp = encodeMatchingExp(mexp);
        restmexp = encodeMatchingExp(restmexp);
      then 
        LIST_CONS_MATCH(mexp, restmexp);
    
    case ( mexp ) //LITERAL_MATCH, NONE_MATCH and REST_MATCH 
      then 
        mexp;
            
      end matchcontinue;
end encodeMatchingExp;


public function encodeFieldMatching 
  input tuple<Ident, MatchingExp> inFieldMatching;
  output tuple<Ident, MatchingExp> outFieldMatching;
algorithm 
  outFieldMatching := matchcontinue (inFieldMatching)
    local
      Ident ident;
      MatchingExp mexp;

    case ( (ident, mexp) )
      equation
        mexp = encodeMatchingExp(mexp);
      then 
        ((ident, mexp));

    //should not ever happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!encodeFieldMatching failed\n");
      then
        fail();
  end matchcontinue;
end encodeFieldMatching;


public function addOutPrefixes
  input list<MMExp> inStmts;
  input TypedIdents inTextArgs;
  input list<tuple<Ident,Ident>> inTranslatedTextArgs;
  
  output list<MMExp> outStmts;
algorithm
  (outStmts) := matchcontinue (inStmts, inTextArgs, inTranslatedTextArgs)
    local
      list<MMExp> stmts;
      MMExp stmt, rhs;
      Ident ident;
      TypedIdents txtargs;
      list<Ident> largs;
      String outident, inident;
      list<tuple<Ident,Ident>> trIdents;
      
    case (  {}, txtargs, trIdents)
      equation
        stmts = addOutTextAssigns(txtargs, trIdents);
      then ( stmts );
    
    case ( MM_ASSIGN(lhsArgs = largs, rhs = rhs) :: stmts, txtargs, trIdents)
      equation
        rhs = addOutPrefixesRhs(rhs, trIdents);
        (largs, trIdents) = addOutPrefixesLhs(largs, txtargs, trIdents);
        stmts = addOutPrefixes(stmts, txtargs, trIdents);       
      then ( MM_ASSIGN(largs, rhs) :: stmts );
    
    case ( stmt :: stmts, txtargs, trIdents)
      equation
        stmts = addOutPrefixes(stmts, txtargs, trIdents);       
      then ( stmt :: stmts );
    
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addOutPrefixes failed\n");
      then
        fail();
  end matchcontinue;           
end addOutPrefixes;

public function addOutPrefixesRhs
  input MMExp inStmt;
  input list<tuple<Ident,Ident>> inTranslatedTextArgs;
  
  output MMExp outStmt;
algorithm
  (outStmt) := matchcontinue (inStmt, inTranslatedTextArgs)
    local
      list<MMExp> stmts, fargs;
      MMExp stmt, rhs;
      Ident ident, outident;
      PathIdent fpath;
      list<Ident> largs;
      String outident, inident;
      list<tuple<Ident,Ident>> trIdents; 
      
    case ( MM_IDENT(IDENT(ident = ident)), trIdents)
      equation
        outident = lookupTupleList(trIdents, ident);               
      then ( MM_IDENT(IDENT(outident)) );
    
    case ( MM_FN_CALL(fnName = fpath, args = fargs), trIdents)
      equation
        fargs = Util.listMap1(fargs, addOutPrefixesRhs, trIdents); 
      then ( MM_FN_CALL(fpath, fargs) );
    
    case ( stmt, _)
      then stmt;
    
  end matchcontinue;           
end addOutPrefixesRhs;


public function addOutPrefixesLhs
  input list<Ident> inLhsArgs;
  input TypedIdents inTextArgs;
  input list<tuple<Ident,Ident>> inTranslatedTextArgs;
  
  output list<Ident> outLhsArgs;
  output list<tuple<Ident,Ident>> outTranslatedTextArgs;
algorithm
  (outLhsArgs, outTranslatedTextArgs) := matchcontinue (inLhsArgs, inTextArgs, inTranslatedTextArgs)
    local
      list<MMExp> stmts;
      MMExp stmt, rhs;
      Ident ident;
      TypedIdents txtargs;
      list<Ident> largs;
      String outident, inident;
      list<tuple<Ident,Ident>> trIdents; 
      
    case (  {},_, trIdents)
      then ( {}, trIdents );
    
    case ( ident :: largs, txtargs, trIdents)
      equation
        _ = lookupTupleList(txtargs, ident);
        outident = outPrefix +& ident;
        trIdents = updateTupleList(trIdents, (ident,outident) );
        (largs, trIdents) = addOutPrefixesLhs(largs, txtargs, trIdents);
      then ( outident :: largs, trIdents );
    
    case ( ident :: largs, txtargs, trIdents)
      equation
        failure(_ = lookupTupleList(txtargs, ident));
        (largs, trIdents) = addOutPrefixesLhs(largs, txtargs, trIdents);
      then ( ident :: largs, trIdents );
    
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addOutPrefixesLhs failed\n");
      then
        fail();
  end matchcontinue;           
end addOutPrefixesLhs;


public function addOutTextAssigns
  input TypedIdents inTextArgs;
  input list<tuple<Ident,Ident>> inTranslatedTextArgs;
  
  output list<MMExp> outStmts;
algorithm
  (outStmts) := matchcontinue (inTextArgs, inTranslatedTextArgs)
    local
      list<MMExp> stmts;
      TypedIdents restArgs;
      Ident ident;
      String outident, inident;
      list<tuple<Ident,Ident>> trIdents;
      
    case (  {} , _)
      then ( {} );
    
    case (  (ident, _) :: restArgs , trIdents)
      equation
        _ = lookupTupleList(trIdents, ident);
        stmts = addOutTextAssigns( restArgs, trIdents);       
      then ( stmts );
    
    case ( (ident, _) :: restArgs , trIdents)
      equation
        //failure(_ = lookupTupleList(trIdents, ident));
        outident = outPrefix +& ident;         
        stmts = addOutTextAssigns( restArgs, trIdents);       
      then ( MM_ASSIGN({outident},MM_IDENT(IDENT(ident))) :: stmts );
    
    case (_,_)
      equation
        Debug.fprint("failtrace", "-!!!addOutTextAssigns failed\n");
      then
        fail();
  end matchcontinue;           
end addOutTextAssigns;


public function isAssignedIdent
  input list<MMExp> inStatementList;
  input Ident inIdent;
  
  output Boolean outIsAssigned;  
algorithm
  (outIsAssigned) := matchcontinue (inStatementList, inIdent)
    local
      Ident ident;
      list<Ident> largs;
      list<MMExp> rest;
      
    case ( {}, _ )  then  false;
    
    case ( MM_ASSIGN(lhsArgs = largs) :: _, ident )  
      equation
        true = listMember(ident, largs);
      then
        true;
    
    case ( _ :: rest, ident )  
      then
        isAssignedIdent(rest, ident);
        
  end matchcontinue;           
end isAssignedIdent;


public function statementsFromExp
  input Expression inExp;
  input list<MMEscOption> inMMEscOptions;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output Ident outInText;    
algorithm
  (outStmts, outLocals, outScopeEnv, outMMDecls, outInText) 
  := matchcontinue (inExp, inMMEscOptions, inStmts, inInText, inOutText, 
                    inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts, mmargs, popstmts;
      MMExp stmt, mmexp, mmarg;
      ScopeEnv scEnv;
      Ident intxt, outtxt, ident, txtIdent;
      PathIdent path, fname;
      TypedIdents locals, iargs, oargs;
      TypeSignature idtype, exptype, elabtype, rettype, littype;
      list<TypeSignature> argstypes, exptypes;
      tuple<MMExp, TypeSignature> argval;
      list<tuple<MMExp, TypeSignature>> argvals;
      Expression exp, tbranch, argexp, mapexp;
      list<Expression> explst;
      Option<Expression> ebranch;
      list<tuple<MatchingExp,Expression>> mcases;
      MatchingExp ofbind;
      Option<MatchingExp> rhsval;
      list<EscOption> opts;
      list<MMEscOption> mmopts;
      Boolean hasretval, isnot;
      Integer n;
      StringToken st;
      list<ASTDef> astDefs;
      String litvalue, istr, reason;
      MapContext mapctx;
      
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      
    case ( TEMPLATE(items = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = statementsFromExpList(explst, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    //inline a literal in its string-token form
    case ( LITERAL(value = litvalue), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", { MM_STR_TOKEN(Tpl.ST_STRING(litvalue)) }, intxt, outtxt);                
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);    
    
    case ( SOFT_NEW_LINE(), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("softNewLine", { }, intxt, outtxt);                
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);    
    
    //empty string -> nothing
    case ( STR_TOKEN(value = Tpl.ST_STRING("")), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
      then ( stmts, locals, scEnv, accMMDecls, intxt);    
    
    case ( STR_TOKEN(value = st), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", { MM_STR_TOKEN(st) }, intxt, outtxt);        
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);    
    
    case ( BOUND_VALUE(boundPath = path), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        //Debug.fprint("failtrace","\n BOUND_VALUE resolving boundPath = " +& pathIdentString(path) +& "\n");
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        ensureResolvedType(path, idtype, " BOUND_VALUE");
        //ensure non-recursive Text evaluation - only this level ... TODO: for indirect reference, too, like <# buf += templ(buf) #>
        true = ensureNotUsingTheSameText(path, mmexp, idtype, intxt);        
        exptype = deAliasedType(idtype, astDefs);
        Debug.fprint("failtrace","\n BOUND_VALUE resolved mmexp = " +& mmExpString(mmexp) +& " : "
                     +& typeSignatureString(idtype) +& " (dealiased: "
                     +& typeSignatureString(exptype) +& ")\n");
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = addWriteCallFromMMExp(true, mmexp, exptype, mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        //Debug.fprint("failtrace"," BOUND_VALUE after writeCall stmts (in reverse order) =\n" +& stmtsString(stmts) +& "\n");        
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    
    case ( FUN_CALL(name = fname, args = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        Debug.fprint("failtrace","\n FUN_CALL fname = " +& pathIdentString(fname) +& "\n");
        (fname, iargs, oargs) = getFunSignature(fname, tplPackage);
        //Debug.fprint("failtrace"," after fname = " +& pathIdentString(fname) +& "\n");
        
        explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);        
        
        Debug.fprint("failtrace"," FUN_CALL argList stmts generation passed\n");
        //Debug.fprint("failtrace"," FUN_CALL after argList stmts (in reverse order) =\n" +& stmtsString(stmts) +& "\n");
        
        (hasretval, stmt, mmexp, rettype, locals, intxt) 
          = statementFromFun(argvals, fname, iargs, oargs, intxt, outtxt, locals, tplPackage);
        Debug.fprint("failtrace"," FUN_CALL stmt =\n" +& stmtsString({stmt}) +& "\n");
        
        rettype = deAliasedType(rettype, astDefs);
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = addWriteCallFromMMExp(hasretval, mmexp, rettype, mmopts, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( MATCH(matchExp = exp, cases = mcases), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (argval, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArg(exp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (argval, stmts, locals) 
          = adaptTextToString(argval, stmts, locals, tplPackage);
        (argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun(argval, mcases, scEnv, tplPackage, accMMDecls);          
        (_, stmt, _, _, locals, intxt) 
          = statementFromFun(argvals, fname, iargs, oargs, intxt, outtxt, locals, tplPackage);
      then ( (stmt :: stmts),  locals, scEnv, accMMDecls, intxt);
    
    case ( CONDITION( isNot = isnot, lhsExp = exp,
                      rhsValue = rhsval, trueBranch = tbranch, elseBranch = ebranch), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (argval, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArg(exp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (argval, stmts, locals) 
          = adaptTextToString(argval, stmts, locals, tplPackage);
        (_,exptype) = argval;
        exptype = deAliasedType(exptype, astDefs);
        mcases 
          = elabCasesFromCondition(exptype, isnot, rhsval, tbranch, ebranch, tplPackage);  
        ( argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun(argval, mcases, scEnv, tplPackage, accMMDecls);          
        (_, stmt, _, _, locals, intxt) 
          = statementFromFun(argvals, fname, iargs, oargs, intxt, outtxt, locals, tplPackage);
      then ( (stmt :: stmts),  locals, scEnv, accMMDecls, intxt);
    
    case ( MAP(argExp = argexp, ofBinding = ofbind, mapExp = mapexp), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        explst = getExpListForMap(argexp);
        (argvals, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);        
        mapctx = MAP_CONTEXT(ofbind, mapexp, mmopts, {}, false);        
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, argvals, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        
        /*(stmts, locals, scEnv, accMMDecls, intxt) 
          = statementsFromEscapedExp(exp, {},
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);*/
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( MAP_ARG_LIST(parts = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        (argvals, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);        
        mapctx = MAP_CONTEXT(BIND_MATCH("it"), BOUND_VALUE(IDENT("it")), mmopts, {}, false); 
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, argvals, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        /*
        //when no options, MAP_ARG_LIST is identical to TEMPLATE
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = statementsFromExpList(explst, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);*/
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( ESCAPED(exp = exp, options = opts), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts); // new options will be elaborated
        (mmopts, stmts, locals, scEnv, accMMDecls) 
          = statementsFromEscOptions(opts, {}, stmts, locals, scEnv, tplPackage, accMMDecls);
        
        (mmopts, stmts, popstmts, intxt) 
         = pushPopBlock(mmopts, absIndentOptionId, "BT_ABS_INDENT", stmts, {}, intxt, outtxt);
        (mmopts, stmts, popstmts, intxt) 
         = pushPopBlock(mmopts, indentOptionId, "BT_INDENT", stmts, popstmts, intxt, outtxt);
        (mmopts, stmts, popstmts, intxt) 
         = pushPopBlock(mmopts, relIndentOptionId, "BT_REL_INDENT", stmts, popstmts, intxt, outtxt);
        (mmopts, stmts, popstmts, intxt) 
         = pushPopBlock(mmopts, anchorOptionId, "BT_ANCHOR", stmts, popstmts, intxt, outtxt);
               
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = statementsFromExp(exp, mmopts,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
               
         stmts = listAppend(popstmts, stmts);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( INDENTATION(width = n, items = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
         warnIfSomeOptions(mmopts);
        istr = intString(n);
        stmt = pushBlockStatement("BT_INDENT", MM_LITERAL(istr), intxt, outtxt);         
        (stmts, locals, scEnv, accMMDecls, _) 
          = statementsFromExpList(explst, stmt::stmts, outtxt, outtxt, locals, scEnv, tplPackage, accMMDecls);        
        //(stmts, locals, scEnv, accMMDecls, _) 
        //  = statementsFromExp(exp, (stmt :: stmts), outtxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        stmt = tplStatement("popBlock", {}, outtxt, outtxt);                  
      then ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);
                
    case ( TEXT_CREATE(name = ident, exp = exp), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (_, UNRESOLVED_TYPE(reason), scEnv) 
          = resolveBoundPath(IDENT(ident), scEnv, tplPackage);
        Debug.fprint("failtrace","\n TEXT_CREATE ident = " +& ident +& " is fresh (reason = " +& reason +& ")\n");
        txtIdent = encodeIdent(ident);
        scEnv = LOCAL_SCOPE(txtIdent, TEXT_TYPE()) :: scEnv;
        locals = addLocalValue(txtIdent, TEXT_TYPE(), locals);
        (stmts, locals, scEnv, accMMDecls, outtxt) 
          = statementsFromExp(exp, {}, stmts, emptyTxt, txtIdent, locals, scEnv, tplPackage, accMMDecls);
        
        stmts = Util.if_(outtxt ==& emptyTxt, 
                  MM_ASSIGN({txtIdent}, MM_IDENT(IDENT(emptyTxt))) :: stmts,
                  stmts);        
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( TEXT_CREATE(name = ident, exp = exp), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        (_, idtype, _) 
          = resolveBoundPath(IDENT(ident), scEnv, tplPackage);
        failure(UNRESOLVED_TYPE(_) = idtype);
        Debug.fprint("failtrace","\nError - TEXT_CREATE ident = '" +& ident +& "' is NOT fresh (type = " +& typeSignatureString(idtype) +& ")\n Only new (fresh) variable can be used in a Text assignment (creation).\n");
      then fail();
    
    
    case ( TEXT_ADD(name = ident, exp = exp), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        path = IDENT(ident);       
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        ensureResolvedType(path, idtype, " TEXT_ADD");
        MM_IDENT(IDENT(txtIdent)) = mmexp;
        TEXT_TYPE() = idtype;
        //TODO: ensureNotUsingTheSameText(txtIdent, exp); ... maybe in the BOUND_VALUE with context of the active inText  
        (stmts, locals, scEnv, accMMDecls, _) 
          = statementsFromExp(exp, {}, stmts, txtIdent, txtIdent, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( NORET_CALL(name = fname, args = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        Debug.fprint("failtrace","\n NORET_CALL fname = " +& pathIdentString(fname) +& "\n");
        (fname, iargs, oargs) = getFunSignature(fname, tplPackage);
        //Debug.fprint("failtrace"," after fname = " +& pathIdentString(fname) +& "\n");

        {} = oargs;
        explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);        
        
        Debug.fprint("failtrace"," NORET_CALL argList stmts generation passed.\n" );        
        //Debug.fprint("failtrace"," NORET_CALL after argList stmts (in reverse order) =\n" +& stmtsString(stmts) +& "\n");
        
        (hasretval, stmt, mmexp, rettype, locals, intxt) 
          = statementFromFun(argvals, fname, iargs, oargs, intxt, outtxt, locals, tplPackage);
        Debug.fprint("failtrace"," NORET_CALL stmt =\n" +& stmtsString({stmt}) +& "\n");        
      then ( stmt::stmts, locals, scEnv, accMMDecls, intxt);
    
    case ( NORET_CALL(name = fname, args = explst), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        (fname, iargs, oargs) = getFunSignature(fname, tplPackage);
        //Debug.fprint("failtrace"," after fname = " +& pathIdentString(fname) +& "\n");
        (_::_) = oargs;
        
        Debug.fprint("failtrace","Error - NORET_CALL with a '" +& pathIdentString(fname) 
          +& "' template or function that has output argument(s).\n");
      then fail();
    
    case (_,_,_,_,_, _,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromExp failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromExp;


public function statementsFromExpList
  input list<Expression> inExpLst;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output Ident outInText;
    
algorithm
  (outStmts, outLocals, outScopeEnv, outMMDecls, outInText)
  := matchcontinue (inExpLst, inStmts, inInText, inOutText, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts;
      MMExp stmt;    
      ScopeEnv scEnv;
      Ident intxt, outtxt;
      TypedIdents locals;
      list<Expression> explst;
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      Expression exp;
    
    case ( {}, stmts, intxt, _, locals, scEnv, _, accMMDecls )
      then ( stmts, locals, scEnv, accMMDecls, intxt);
        
    case ( (exp :: explst ),
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        (stmts, locals, scEnv, accMMDecls, intxt) 
          = statementsFromExp(exp, {}, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExpList(explst, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
        
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromExpList failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromExpList;


public function warnIfSomeOptions
  input list<MMEscOption> inMMEscOptions;
      
algorithm
  _ := 
  matchcontinue (inMMEscOptions)
    local
      list<MMEscOption> opts;
      Ident optid;
    
    //ok, no options  
    case ( {} ) then ();

    //warning - more options than expected   
    case ( (optid,_) ::_ )
      equation
        Debug.fprint("failtrace", "Warning - more options specified than expected for an expression (first option is '" +& optid +& "').\n");
       then ();
    
    //cannot happen
    case (_) equation
        Debug.fprint("failtrace", "- warnIfSomeOptions failed.\n");
      then fail();
  end matchcontinue;           
end warnIfSomeOptions;



public function statementsFromEscOptions
  input list<EscOption> inOptions;
  input list<MMEscOption> inAccMMEscOptions;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<MMEscOption> outAccMMEscOptions;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
algorithm
  (outAccMMEscOptions, outStmts, outLocals, outScopeEnv, outMMDecls) 
  := matchcontinue (inOptions, inAccMMEscOptions, inStmts, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts;
      MMExp stmt;    
      ScopeEnv scEnv;
      TypedIdents locals;
      tuple<MMExp, TypeSignature> argval, defoptval;
      list<tuple<MMExp, TypeSignature>> argvals;
      MMExp mexp, mmarg, defmmexp;
      PathIdent path;
      TypeSignature idtype, exptype, opttype;
      list<TypeSignature> argstypes, exptypes;
      list<MMExp> mmargs;
      Boolean istempl, isnot;
      TypedIdents iargs, oargs;
      Expression exp, tbranch, argexp, optexp;
      list<EscOption> opts;
      Ident optid;
      list<MMEscOption> accMMEscOpts;
      list<ASTDef> astdefs;
      
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      
    
    case ( {}, accMMEscOpts, stmts, locals, scEnv, _, accMMDecls )
      then
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls);
    
    //option without "="
    case ( (optid, NONE) :: opts, accMMEscOpts,
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        defoptval = lookupTupleList(defaultEscOptions, optid);
        failure(_ = lookupTupleList(accMMEscOpts, optid)); //no duplicity
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
         = statementsFromEscOptions(opts, (optid, defoptval) :: accMMEscOpts, 
          stmts, locals, scEnv, tplPackage, accMMDecls); 
      then
         (accMMEscOpts, stmts, locals, scEnv, accMMDecls);
    
    //option = exp
    case ( (optid, SOME(optexp)) :: opts, accMMEscOpts,
           stmts, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astdefs), accMMDecls )
      equation
        ((_, opttype)) = lookupTupleList(defaultEscOptions, optid);
        failure(_ = lookupTupleList(accMMEscOpts, optid)); //no duplicity
        ((mmarg,exptype), stmts, locals, scEnv, accMMDecls) 
          = statementsFromArg(optexp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (mmarg, stmts, locals) = typeAdaptMMOption(mmarg, exptype, opttype, stmts, locals, astdefs);      
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
         = statementsFromEscOptions(opts, (optid, (mmarg,opttype)) :: accMMEscOpts, 
          stmts, locals, scEnv, tplPackage, accMMDecls); 
      then 
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls); 
    
    //warning - unknown option
    case ( (optid, _) :: opts, accMMEscOpts,
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        failure(_ = lookupTupleList(defaultEscOptions, optid));
        Debug.fprint("failtrace", "Warning - an unknown option'" +& optid +& "' was specified. It will be ignored (not evaluated).\n");
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
          = statementsFromEscOptions(opts, accMMEscOpts, stmts, locals, scEnv, tplPackage, accMMDecls);
      then 
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls); 
    
    //warning - duplicit option    
    case ( (optid, _) :: opts, accMMEscOpts,
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        _ = lookupTupleList(defaultEscOptions, optid);
        _ = lookupTupleList(accMMEscOpts, optid);
        Debug.fprint("failtrace", "Warning - a duplicit option'" +& optid +& "' was specified. It will be ignored (not evaluated).\n");
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
         = statementsFromEscOptions(opts, accMMEscOpts, stmts, locals, scEnv, tplPackage, accMMDecls);
      then 
         (accMMEscOpts, stmts, locals, scEnv, accMMDecls);

    //can fail on error
    case (_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", " -statementsFromEscOptions failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromEscOptions;


public function getExpListForMap
  input Expression inExp;
  output list<Expression> outExpsForMap;
algorithm
  outExpsForMap := matchcontinue inExp
    local
      Expression exp;
      list<Expression> explst;
      
    case ( MAP_ARG_LIST(parts = explst) )   then explst;
    case ( exp )                           then { exp };

    //cannot happen            
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromExp failed\n");
      then
        fail();
  end matchcontinue;           
end getExpListForMap;

        
public function pushPopBlock
  input list<MMEscOption> inMMEscOptions;
  input Ident inOptionIdent;
  input Ident inBlockTypeIdent;
  input list<MMExp> inStmts;
  input list<MMExp> inPopBlockStmts;
  input Ident inInText;
  input Ident inOutText;
  
  output list<MMEscOption> outMMEscOptions;
  output list<MMExp> outStmts;
  output list<MMExp> outPopBlockStmts;
  output Ident outInText;    
algorithm
  (outMMEscOptions, outStmts, outPopBlockStmts, outInText) 
  := matchcontinue (inMMEscOptions, inOptionIdent, inBlockTypeIdent, inStmts, inPopBlockStmts, inInText, inOutText)
    local
      list<MMExp> stmts, popstmts;
      MMExp stmt, pstmt, mmexp;
      Ident intxt, outtxt, optid, btid;
      list<MMEscOption> mmopts;
      
    case ( mmopts, optid, btid, stmts, popstmts, intxt, outtxt)
      equation
        ((mmexp,_), mmopts) = lookupDeleteTupleList(mmopts, optid);
        stmt = pushBlockStatement(btid, mmexp, intxt, outtxt);
        pstmt = tplStatement("popBlock", {}, outtxt, outtxt);         
        popstmts = listAppend(popstmts, {pstmt} );                
      then ( mmopts, (stmt :: stmts), popstmts, outtxt);
    
    case ( mmopts, optid, btid, stmts, popstmts, intxt, _)
      //equation
        //failure(((mmexp,_), mmopts) = lookupDeleteTupleList(mmopts, optid));
      then ( mmopts, stmts, popstmts, intxt);
   
    //cannot happen            
    case (_,_,_,_, _,_,_)
      equation
        Debug.fprint("failtrace", "-!!!pushPopBlock failed\n");
      then
        fail();
  end matchcontinue;           
end pushPopBlock;


public function addImplicitArgument
  input list<Expression> inArgLst;
  input TypedIdents inInArgs;
  input TypedIdents inOutArgs;
  input TemplPackage inTplPackage;

  output list<Expression> outArgLst;    
algorithm
  outArgLst := matchcontinue (inArgLst, inInArgs, inOutArgs, inTplPackage)
    local
      list<Expression> explst;
      tuple<Ident,TypeSignature> iarg, oarg;
      TemplPackage tplPackage;
      
    //when the function is a template function
    //and the signature has the only one argument and none is specified on call
    // assume the 'it'
    case ( {}, { iarg, _ }, oarg :: _ , tplPackage)
      equation
        areTextInOutArgs(iarg, oarg, tplPackage);
      then { BOUND_VALUE(IDENT("it")) };
        
    //otherwise no change
    case ( explst, _, _, _ )
      then explst;
        
    //cannot happen
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addImplicitArgument failed\n");
      then
        fail();
  end matchcontinue;           
end addImplicitArgument;


public function statementsFromArg
  input Expression inExp;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output tuple<MMExp, TypeSignature> outArgValue;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
algorithm
  (outArgValue, outStmts, outLocals, outScopeEnv, outMMDecls) 
  := matchcontinue (inExp, inStmts, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts;
      MMExp stmt;    
      ScopeEnv scEnv;
      Ident intxt, outtxt, ident;
      TypedIdents locals;
      tuple<MMExp, TypeSignature> argval;
      list<tuple<MMExp, TypeSignature>> argvals;
      MMExp mmexp, mmarg;
      PathIdent path, fname;
      TypeSignature idtype, exptype, rettype, littype;
      list<TypeSignature> argstypes, exptypes;
      list<Expression> explst;
      list<MMExp> mmargs;
      Boolean istempl, isnot;
      TypedIdents iargs, oargs;
      Expression exp, tbranch, argexp;
      Option<Expression> ebranch;
      list<tuple<MatchingExp,Expression>> mcases;
      MatchingExp ofbind;
      Option<Expression> rhsval;
      list<EscOption> opts;
      Integer n;
      String litvalue;
      StringToken st;
      
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      
    case ( LITERAL(value = litvalue, litType = littype),
           stmts, locals, scEnv, _, accMMDecls )
      then ( (MM_LITERAL(litvalue),littype), stmts, locals, scEnv, accMMDecls);    
    
    case ( STR_TOKEN(value = st),
           stmts, locals, scEnv, _, accMMDecls )
      then ( (MM_STR_TOKEN(st),STRING_TOKEN_TYPE()), stmts, locals, scEnv, accMMDecls);    
    
    case ( BOUND_VALUE(boundPath = path),
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        //Debug.fprint("failtrace","\n arg BOUND_VALUE resolving boundPath = " +& pathIdentString(path) +& "\n");        
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        ensureResolvedType(path, idtype, " arg BOUND_VALUE");
        Debug.fprint("failtrace"," arg BOUND_VALUE resolved mmexp = " +& mmExpString(mmexp) +& " : "
                     +& typeSignatureString(idtype) +& "\n");
      then ( (mmexp,idtype), stmts, locals, scEnv, accMMDecls);
    
    case ( FUN_CALL(name = fname, args = explst),
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        (fname, iargs, oargs) = getFunSignature(fname, tplPackage);
        explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls) 
           = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);        
        outtxt = "txt_" +& intString(listLength(locals));
        (_, stmt, mmexp, rettype, locals, outtxt) 
           = statementFromFun(argvals, fname, iargs, oargs, emptyTxt, outtxt, locals, tplPackage);
        Debug.fprint("failtrace"," arg FUN_CALL stmt =\n" +& stmtsString({stmt}) +& "\n");
        //if emptyList in case of non-template function, not to be included to locals
        locals = addLocalValue(outtxt, TEXT_TYPE(), locals);
      then ( (mmexp, rettype), stmt :: stmts, locals, scEnv, accMMDecls);
    
    // all the other are texts: 
    // TEMPLATE, CONDITION, MATCH, MAP, MAP_ARG_LIST (forced MV separation - cannot construct true lists),
    // ESCAPED and INDENTATION
    case ( exp, stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        outtxt = "txt_" +& intString(listLength(locals));
        (stmts, locals, scEnv, accMMDecls, outtxt) 
          = statementsFromExp(exp, {}, stmts, emptyTxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        locals = addLocalValue(outtxt, TEXT_TYPE(), locals); //if emptyList, not to be included to locals
        mmexp = MM_IDENT(IDENT(outtxt));        
      then ( (mmexp, TEXT_TYPE()), stmts, locals, scEnv, accMMDecls);
    
    //should not ever happen            
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromArg failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromArg;


public function statementsFromArgList
  input list<Expression> inExpLst;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<tuple<MMExp, TypeSignature>> outArgValues;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
    
algorithm
  (outArgValues, outStmts, outLocals, outScopeEnv, outMMDecls) 
  := matchcontinue (inExpLst, inStmts, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts;
      ScopeEnv scEnv;
      TypedIdents locals;
      list<Expression> explst;
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      tuple<MMExp, TypeSignature> argval;
      list<tuple<MMExp, TypeSignature>> argvals;
      Expression exp;
    
    case ( {}, stmts, locals, scEnv, _, accMMDecls )
      then ( {}, stmts, locals, scEnv, accMMDecls);
        
    case ( (exp :: explst ),
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        (argval, stmts, locals, scEnv, accMMDecls) 
          = statementsFromArg(exp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (argvals, stmts, locals, scEnv, accMMDecls)
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);
      then ( (argval :: argvals), stmts, locals, scEnv, accMMDecls);
        
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromArgList failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromArgList;


public function tplStatement
  input Ident inFunName;
  input list<MMExp> inArgs;
  input Ident inInText;
  input Ident inOutArg;
  
  output MMExp outStmt;
algorithm
  outStmt := MM_ASSIGN( {inOutArg}, 
                MM_FN_CALL( PATH_IDENT("Tpl",IDENT(inFunName)), 
                            MM_IDENT(IDENT(inInText)) :: inArgs ));    
end tplStatement;

public function pushBlockStatement
  input Ident inBlockType;
  input MMExp inArg;
  input Ident inInText;
  input Ident inOutArg;
  
  output MMExp outStmt;
algorithm
  outStmt := 
   MM_ASSIGN( 
     {inOutArg}, 
     MM_FN_CALL( 
        PATH_IDENT("Tpl",IDENT("pushBlock")), 
        { MM_IDENT(IDENT(inInText)),  
          MM_FN_CALL(
              PATH_IDENT("Tpl",IDENT(inBlockType)),
              { inArg }) } ));    
end pushBlockStatement;


public function addWriteCallFromMMExp
  input Boolean inHasRetValue;
  input MMExp inMMExp;
  input TypeSignature inType;
  input list<MMEscOption> inMMEscOptions;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output Ident outInText;  
algorithm
  (outStmts, outLocals, outScopeEnv, outMMDecls, outInText) 
  := matchcontinue (inHasRetValue, inMMExp, inType, inMMEscOptions, inStmts, inInText, inOutText, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      Ident intxt, outtxt;
      PathIdent fname;
      TypeSignature exptype;
      MMExp mmexp, stmt;
      list<MMExp> stmts;
      TypedIdents locals, iargs, oargs;
      ScopeEnv scEnv;
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      list<tuple<MMExp, TypeSignature>> argvals;
      MapContext mapctx;
      list<MMEscOption> mmopts;
      
    //it is not a ret value, 
    //if it is from a temlate call or a non-template call without a return value,
    //the statement is already added, nothing to do here 
    case (false, _, _, _, stmts, intxt, _, locals, scEnv, _,  accMMDecls)
      then
        ( stmts, locals, scEnv, accMMDecls, intxt);
    
    //an option -> match it case SOME(val) then val // if exp = SOME(val) then val 
    case (_, mmexp, exptype as OPTION_TYPE(_), mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        //internal encodeing of val is not needed as the val is bound tightly, it hides possible val from upper scope 
        // /* encode the val as "val." that will be encoded as _val_ that is impossible to create from a source code -> no name collision */
        (argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun((mmexp, exptype), 
              {(SOME_MATCH(BIND_MATCH("val")), BOUND_VALUE(IDENT("val"))) }, scEnv, tplPackage, accMMDecls);          
        (_, stmt, _, _, locals, intxt) 
          = statementFromFun(argvals, fname, iargs, oargs, intxt, outtxt, locals, tplPackage);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, intxt);
    
    //a list expression -> concat 
    case (_, mmexp, exptype as LIST_TYPE(_), mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage,  accMMDecls)
      equation
        mapctx = MAP_CONTEXT(BIND_MATCH("it"), BOUND_VALUE(IDENT("it")), mmopts, {}, false);        
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, {(mmexp, exptype)}, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then
        ( stmts, locals, scEnv, accMMDecls, intxt);
    
    //string const - inline or defined by the user as an ident 
    case (_, mmexp, STRING_TOKEN_TYPE(), mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);
    
    //text -> writeText
    case (_, mmexp, TEXT_TYPE(), mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeText", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);
        
    //try to-string conversion
    case (_, mmexp, exptype, mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        mmexp = mmExpToString(mmexp, exptype);
        stmt = tplStatement("writeStr", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);
    
    //fail / error - is in  mmExpToString
    case ( _, _, _, _, _, _, _, _,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addWriteCallFromMMExp failed\n");
      then
        fail();
  end matchcontinue;           
end addWriteCallFromMMExp;


public function mmExpToString
  input MMExp inMMExp;
  input TypeSignature inType;
  
  output MMExp outMMExp;
algorithm
  outMMExp := matchcontinue (inMMExp, inType)
    local
      MMExp mmexp;
      String reason, str;
      StringToken st;
      TypeSignature ts;        
    
    case (mmexp, STRING_TYPE())
      then
        mmexp;
    
    //a literal constant to string - inline it as a special MM_STRING
    case (MM_LITERAL(value = str), _)
      then
        MM_STRING(str);
    
    //an inlined string constant, can be inlined as MM_STRING
    case (MM_STR_TOKEN(value = st), _)
      equation
        str = Tpl.strTokString(st);
      then
        MM_STRING(str);
    
    //runtime strTokString
    case (mmexp, STRING_TOKEN_TYPE())
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("strTokString")), { mmexp });
    
    //runtime textString
    case (mmexp, TEXT_TYPE())
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("textString")), { mmexp });
    
    //runtime integer type conversion
    case (mmexp, INTEGER_TYPE())
      then
        MM_FN_CALL(IDENT("intString"),{ mmexp });
    
    //runtime real type conversion
    case (mmexp, REAL_TYPE())
      then
        MM_FN_CALL(IDENT("realString"),{ mmexp });
    
    //runtime boolean type conversion
    case (mmexp, BOOLEAN_TYPE())
      then
        MM_FN_CALL(PATH_IDENT("Tpl", IDENT("booleanString")),{ mmexp });
    
    //trying to convert an unresolved value
    case (mmexp, UNRESOLVED_TYPE(reason = reason))
      equation
        Debug.fprint("failtrace", "Error - an unresolved value trying to convert to string. Unresolution reason:\n    " +& reason);
      then
        fail();
    
    //trying to convert a value when there is no conversion for its type
    case (mmexp, ts)
      equation
        Debug.fprint("failtrace", "Error - expression '" +& mmExpString(mmexp) +& "' of type '" 
           +& typeSignatureString(ts) +& "' has no automatic to-string conversion.\n");
      then
        fail();
    
    //should not ever happen
    case ( _, _)
      equation
        Debug.fprint("failtrace", "-!!!mmExpToString failed\n");
      then
        fail();
  end matchcontinue;           
end mmExpToString;


public function statementFromFun
  input list<tuple<MMExp, TypeSignature>> inArgValues;
  input PathIdent inFunName;
  input TypedIdents inInArgs;
  input TypedIdents inOutArgs;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input TemplPackage inTplPackage; 
  
  output Boolean outHasRetValue; 
  output MMExp outStmt;
  output MMExp outRetMMExp;
  output TypeSignature outRetType;
  output TypedIdents outLocals;
  output Ident outOutText; 
algorithm
  (outIsTemplate, outStmt, outRetMMExp, outRetType, outLocals) 
    := matchcontinue (inArgValues, inFunName, inInArgs, inOutArgs, inInText, inOutText, inLocals, inTplPackage)
    local
      
      PathIdent fname, itpath, typepckg;
      TypedIdents iargs, oargs, locals;
      tuple<Ident,TypeSignature> iarg, oarg; 
      list<tuple<MMExp, TypeSignature>> argvals;
      list<MMExp> mmargs;
      
      Ident inid, outid, ident, typeident, intxt, outtxt, retval;
      TypeSignature idtype, outtype;
      Scope scope;
      ScopeEnv scEnv;
      TemplPackage tplPackage;
      list<ASTDef> astDefs;
      list<tuple<Ident,TemplateDef>> tpldefs;
      Option<PathIdent> typepckgOpt;
      TypeInfo typeinfo;
      MMExp mmexp, stmt, mmtxt;
      list<MMExp> stmts;
      StringToken st;
      Integer ival;
      Real rval;
      Boolean bval;
      String reason;
      list<Ident> lhsArgs;        
      
    
    //simple template function - one implicit text argument 
    //- make a template call statement and return the out argument
    case (argvals, fname, ( iarg  :: iargs ),  { oarg }, 
          intxt, outtxt, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs))
      equation
        areTextInOutArgs(iarg, oarg, tplPackage); //texts and equal or equal without conventional prefixes in/out, i.e. inId = outId 
        //equality(listLength(argvals) = listLength(iargs));
        mmargs = typeAdaptMMArgsForFun(argvals, iargs, astDefs);
        mmtxt = MM_IDENT(IDENT(outtxt));
        mmexp = MM_FN_CALL(fname, MM_IDENT(IDENT(intxt)) :: mmargs); 
      then
        (false, MM_ASSIGN({outtxt}, mmexp), mmtxt, TEXT_TYPE(), locals, outtxt );
    
    //multi output template function - one implicit text argument + extra text in/out arguments 
    //- make a template call statement and return only the first out argument
    case (argvals, fname, 
           ( iarg :: iargs ), 
           ( oarg :: (oargs as (_::_)) ), 
           intxt, outtxt, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs))
      equation
        areTextInOutArgs(iarg, oarg, tplPackage); //texts and equal or equal without conventional prefixes in/out, i.e. inId = outId
        //equality(listLength(argvals) = listLength(iargs));        
        mmargs = typeAdaptMMArgsForFun(argvals, iargs, astDefs); 
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage); //assuming the same lengths (from above typeAdaptMMArgsForFun)
        lhsArgs = outtxt :: lhsArgs;
        mmtxt = MM_IDENT(IDENT(outtxt));
        mmexp = MM_FN_CALL(fname, (MM_IDENT(IDENT(intxt)) :: mmargs) );
      then
        (false, MM_ASSIGN(lhsArgs, mmexp), mmtxt, TEXT_TYPE(), locals, outtxt );
    
    //a non-template function - no implicit text argument 
    //one return value
    //- make a locally bound return value and assign the function to it
    case (argvals, fname, iargs,  { (_, outtype) }, 
         intxt, _, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs))
      equation
        //equality(listLength(argvals) = listLength(iargs));
        mmargs = typeAdaptMMArgsForFun(argvals, iargs, astDefs);
        //make a separate locally bound return value
        retval = "ret_" +& intString(listLength(locals));
        locals = addLocalValue(retval, outtype, locals);          
        mmexp = MM_FN_CALL(fname, mmargs); 
      then
        ( true, MM_ASSIGN({retval}, mmexp), MM_IDENT(IDENT(retval)), outtype, locals, intxt );

    
    //a non-template function - no implicit text argument 
    //no return value - i.e. an intrinsic call like <# fun(arg) #>
    //- inline it as it is
    case (argvals, fname, iargs,  {}, 
          intxt, _, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs))
      equation
        //equality(listLength(argvals) = listLength(iargs));
        mmargs = typeAdaptMMArgsForFun(argvals, iargs, astDefs);
        mmexp = MM_FN_CALL(fname, mmargs); 
      then
        ( false, mmexp, mmexp, UNRESOLVED_TYPE("No return value."), locals, intxt );
    
    case (argvals, fname, iargs,  oargs, intxt, outtxt, locals, tplPackage)
      equation
        Debug.fprint("failtrace", "Error - cannot elaborate function '" +& pathIdentString(fname) +& "'.\n Invalid types (cannot convert) or number of in/out arguments (text in/out arguments must match by order and name equality where prefixes 'in' and 'out' can be used; A function has valid template signature only if all text out params have corresponding in text arguments.).\n");
      then
        fail();
    
    //should not ever happen
    case ( _, _, _, _, _, _ ,_ ,_)
      equation
        Debug.fprint("failtrace", "-!!!mmExpFromFun failed\n");
      then
        fail();
  end matchcontinue;           
end statementFromFun;


public function areTextInOutArgs
  input tuple<Ident,TypeSignature> inInArg;
  input tuple<Ident,TypeSignature> inOutArg;
  input TemplPackage inTplPackage;    
algorithm
  _ := matchcontinue (inInArg, inOutArg, inTplPackage)
    local
      Ident inid, outid;
      TypeSignature itype, otype;
      list<String> inlst, outlst;
      list<ASTDef> astdefs;
              
    //equals with no prefix ... internal only for defined tempates  
    case ((inid,itype), (outid,otype), TEMPL_PACKAGE(astDefs = astdefs))
      equation
        equality(inid = outid);
        TEXT_TYPE() = deAliasedType(itype, astdefs);
        TEXT_TYPE() = deAliasedType(otype, astdefs);
      then
        ();
    
    //equals with usage of in/out prefixes ... for external templates from an ast definition
    case ((inid,itype), (outid,otype), TEMPL_PACKAGE(astDefs = astdefs))
      equation
        ("i" :: "n" :: inlst) = stringListStringChar(inid);
        ("o" :: "u" :: "t" :: outlst) = stringListStringChar(outid);
        equality(inlst = outlst);
        TEXT_TYPE() = deAliasedType(itype, astdefs);
        TEXT_TYPE() = deAliasedType(otype, astdefs);
      then
        ();
  
  //otherwise fail
    
  end matchcontinue;           
end areTextInOutArgs;


public function typeAdaptMMArgsForFun
  input list<tuple<MMExp, TypeSignature>> inArgValues;
  input TypedIdents inInArgs;
  input list<ASTDef> inASTDefs;
  
  output list<MMExp> outMMArguments;
algorithm
  outMMArguments  := matchcontinue (inArgValues, inInArgs, inASTDefs)
    local
      TypedIdents iargs;
      list<tuple<MMExp, TypeSignature>> argvals;
      MMExp mmarg;
      list<MMExp> mmargs;
      TypeSignature argtype, sigArgtype;
      list<ASTDef> astdefs;      
    
    case ( {}, {}, _)
      then
        {};
        
    case ( (mmarg, argtype) :: argvals, (_, sigArgtype) :: iargs, astdefs)
      equation
        argtype = deAliasedType(argtype, astdefs);
        sigArgtype = deAliasedType(sigArgtype, astdefs);
        mmarg = typeAdaptMMArg(mmarg, argtype, sigArgtype, astdefs);
        mmargs = typeAdaptMMArgsForFun(argvals, iargs, astdefs);
      then
        ( mmarg :: mmargs );
    
    case ( {}, (_ :: _), _)
      equation
        Debug.fprint("failtrace", "Error - more arguments expected for a function.\n");
      then
        fail();
    
    case ( (_ :: _), {}, _)
      equation
        Debug.fprint("failtrace", "Error - less number of arguments expected for a function.\n");
      then
        fail();
        
    case ( _, _, _)
      equation
        Debug.fprint("failtrace", "!!! - typeAdaptMMArgsForFun failed\n");
      then
        fail();
  end matchcontinue;           
end typeAdaptMMArgsForFun;


public function typeAdaptMMArg
  input MMExp inMMArg;
  input TypeSignature inArgType;
  input TypeSignature inTargetType;
  input list<ASTDef> inASTDefs;
  
  output MMExp outMMArg;
algorithm
  outMMArg := matchcontinue (inMMArg, inArgType, inTargetType, inASTDefs)
    local
      TypedIdents iargs;
      MMExp mmarg, mmexp;
      list<tuple<MMExp, TypeSignature>> argvals;
      list<MMExp> mmargs;
      TypeSignature argtype, targettype;
      list<ASTDef> astdefs; 
      String str;
      StringToken strtok;     

    //no conversion ... 
    case ( mmarg, argtype, targettype, astdefs)
      equation
        typesEqual(argtype, targettype, astdefs); //assumes the arguments are deAliasedType-ed
      then
        mmarg;
    
    //convert to string
    case ( mmexp, argtype, STRING_TYPE(), _)
      then
        mmExpToString(mmexp, argtype);
    
    //strTokText 
    case ( mmarg, STRING_TOKEN_TYPE(), TEXT_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("strTokText")), { mmarg });
    
    /* no convertion to stringtoken yet, ... every string will be stringtoken then
    //textStrTok - useful for options when from a template
    case ( mmarg, TEXT_TYPE(), STRING_TOKEN_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("textStrTok")), { mmarg });
    
    
    //stringStrTok - useful for options when from a value of type string
    case ( mmarg, STRING_TYPE(), STRING_TOKEN_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("ST_STRING")), { mmarg });
    */
    
    // _ -> text ... to string and -> text 
    case ( mmarg, argtype, TEXT_TYPE(), _)
      equation
        mmarg = mmExpToString(mmarg, argtype);
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("stringText")), { mmarg });
    
    
    case ( _, _, _, _)
      equation
        Debug.fprint("failtrace", "Error - typeAdaptMMArg failed\n");
      then
        fail();
  end matchcontinue;           
end typeAdaptMMArg;


public function typeAdaptMMOption
  input MMExp inMMArg;
  input TypeSignature inArgType;
  input TypeSignature inTargetType;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input list<ASTDef> inASTDefs;
  
  output MMExp outMMArg;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outMMArg, outStmts, outLocals) := 
  matchcontinue (inMMArg, inArgType, inTargetType, inStmts, inLocals, inASTDefs)
    local
      TypedIdents iargs;
      MMExp mmarg, mmexp;
      list<tuple<MMExp, TypeSignature>> argvals;
      list<MMExp> mmargs;
      TypeSignature argtype, targettype;
      list<ASTDef> astdefs; 
      String str;
      StringToken strtok;
      list<MMExp> stmts;
      TypedIdents locals;     

    case ( mmarg, argtype, targettype, stmts, locals, astdefs)
      equation
        mmarg = typeAdaptMMArg(mmarg, argtype, targettype, astdefs);
        (mmarg, stmts, locals) = mmEnsureNonFunctionArg(mmarg, targettype, stmts, locals);
      then
        (mmarg, stmts, locals);
   
    //textStrTok -  when from a template
    case ( mmarg, TEXT_TYPE(), STRING_TOKEN_TYPE(), stmts, locals, astdefs)
      equation
        mmarg = MM_FN_CALL(PATH_IDENT("Tpl",IDENT("textStrTok")), { mmarg });
        (mmarg, stmts, locals) = mmEnsureNonFunctionArg(mmarg, STRING_TOKEN_TYPE(), stmts, locals);
      then
        (mmarg, stmts, locals);
    
    //stringStrTok - when from a value of type string or others (int, real, bool)
    case ( mmarg, argtype, STRING_TOKEN_TYPE(), stmts, locals, astdefs)
      equation
        mmarg = mmExpToString(mmarg, argtype);
        (mmarg, stmts, locals) = mmEnsureNonFunctionArg(mmarg, STRING_TYPE(), stmts, locals);
        mmarg = MM_FN_CALL(PATH_IDENT("Tpl",IDENT("ST_STRING")), { mmarg });
      then
        (mmarg, stmts, locals);
    
    /*
    //stringStrTok - useful for options when from a value of type string
    case ( mmarg, STRING_TYPE(), STRING_TOKEN_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("ST_STRING")), { mmarg });
    */
    //concrete type to its option SOME - when from a value of the concrete type
    case ( mmarg, argtype, OPTION_TYPE(ofType = targettype), stmts, locals, astdefs)
      equation
        targettype = deAliasedType(targettype, astdefs);
        (mmarg, stmts, locals) = typeAdaptMMOption(mmarg, argtype, targettype, stmts, locals, astdefs);
        mmarg = MM_FN_CALL(IDENT("SOME"), { mmarg });
      then
        (mmarg, stmts, locals);
       
    case ( _, _, _, _, _, _)
      equation
        Debug.fprint("failtrace", "Error - typeAdaptMMArg failed\n");
      then
        fail();
  end matchcontinue;           
end typeAdaptMMOption;


public function mmEnsureNonFunctionArg
  input MMExp inMMArg;
  input TypeSignature inTargetType;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  
  output MMExp outMMArg;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outMMArg, outStmts, outLocals) := 
  matchcontinue (inMMArg, inTargetType, inStmts, inLocals)
    local
      TypedIdents iargs;
      MMExp mmarg, mmexp;
      list<tuple<MMExp, TypeSignature>> argvals;
      list<MMExp> mmargs;
      TypeSignature argtype, targettype;
      list<ASTDef> astdefs; 
      String str, retval;
      StringToken strtok;
      list<MMExp> stmts;
      TypedIdents locals;     

    case ( mmarg as MM_FN_CALL(fnName = _), targettype, stmts, locals)
      equation
         //make a separate locally bound return value
        retval = "ret_" +& intString(listLength(locals));
        locals = addLocalValue(retval, targettype, locals);          
        stmts = MM_ASSIGN({retval}, mmarg) :: stmts;
      then
        (MM_IDENT(IDENT(retval)), stmts, locals);

    case ( mmarg, _, stmts, locals)
      equation
        failure(MM_FN_CALL(fnName = _) = mmarg);
      then
        (mmarg, stmts, locals);
   
    //may fail, when addLocalValue fails
    case ( _, _, _, _)
      equation
        Debug.fprint("failtrace", "!!!- mmEnsureNonFunctionArg failed\n");
      then
        fail();
  end matchcontinue;           
end mmEnsureNonFunctionArg;


public function elabOutTextArgs
  input list<MMExp> inMMArguments;
  input TypedIdents inInArgs;
  input TypedIdents inOutArgs;
  input TemplPackage inTplPackage;
  
  output list<Ident> outLhsArgs;
algorithm
  outLhsArgs  := matchcontinue (inMMArguments, inInArgs, inOutArgs, inTplPackage)
    local
      Ident txtarg;
      TypedIdents iargs, oargs;
      tuple<Ident, TypeSignature> iarg, oarg;
      list<tuple<MMExp, TypeSignature>> argvals;
      MMExp mmarg;
      list<MMExp> mmargs;
      TypeSignature argtype, sigArgtype;
      list<ASTDef> astdefs;
      list<Ident> lhsArgs;
      TemplPackage tplPackage;              

    case ( _, _, {}, _)
      then
        {};
        
    //not a text in/out parameter, search on
    case ( _ :: mmargs, iarg :: iargs, oargs as (oarg :: _), tplPackage)
      equation
        failure(areTextInOutArgs(iarg , oarg, tplPackage));
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage);
      then
        lhsArgs;

    //a text argument that is input and output 
    //an actual parameter ident ... non-internal idents all starts with "_" 
    //- put it out
    case ( MM_IDENT(IDENT(txtarg)) :: mmargs, iarg :: iargs, oarg :: oargs, tplPackage)
      equation
        // obsolete ... "_" = stringGetStringChar(txtarg, 1);
        //areEqualInOutArgs(iarg , oarg);
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage);
      then
        ( txtarg :: lhsArgs );
    
    //a text argument that is input and output 
    //an actual parameter is not a local text value (it is a constant/function) - put it as '_'
    case ( _ :: mmargs, iarg :: iargs, oarg :: oargs, tplPackage)
      equation
        //failure(MM_IDENT(IDENT()) = mmarg);
        //failure("_" = stringGetStringChar(txtarg, 1));
        //areEqualInOutArgs(iarg , oarg);
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage);
      then
        ( "_" :: lhsArgs );
    
    case ( {}, {}, _::_, _)
      equation
        Debug.fprint("failtrace", "Error - inconsistent in/out Text arguments for a template function (Output texts are not a subset of input texts).\n");
      then
        fail();

    //should not ever happen
    case ( _, _, _, _)
      equation
        Debug.fprint("failtrace", "!!!- elabOutTextArgs failed\n");
      then
        fail();
  end matchcontinue;           
end elabOutTextArgs;


public function statementsFromMapExp
  input Boolean inIsFirstArgToMap;
  input list<tuple<MMExp, TypeSignature>> inArgValuesToMap;
  input MapContext inMapContext;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<MMExp> outStmts;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output Ident outInText;
    
algorithm
  (outStmts, outLocals, outScopeEnv, outMMDecls, outInText)
  := matchcontinue (inIsFirstArgToMap, inArgValuesToMap, inMapContext, inStmts, inInText, inOutText, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      list<MMExp> stmts, mapstmts, rhsMMArgs;
      MMExp stmt, argmmexp, mmRecCall; 
      TypeSignature argtype, oftype;   
      ScopeEnv scEnv;
      Ident intxt, outtxt, fname, matchident, itName;
      TypedIdents locals, extargs, maplocals, idxargs, foundIdxArgs, iargs, oargs;
      list<Expression> explst;
      MapContext mapctx;
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      tuple<MMExp, TypeSignature> argval, argtomap;
      list<tuple<MMExp, TypeSignature>> extargvals, restargs;
      MatchingExp ofbind, ofbindEnc, mexp;
      Expression mapexp;
      list<MMEscOption> iopts;
      list<ASTDef> astDefs;
      MMMatchCase mmmcEmptyList, mmmcCons, mmFailCons;
      Boolean isfirst, useiter, newUseiter;
      tuple<Ident, TypeSignature> i0ti, i1ti;
      MMDeclaration mmFun;
      list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> elabcases;
      list<MMMatchCase> mmmcases;
      list<Ident> lhsArgs, assignedTexts;
      
    //all args was mapped, the popIter() at last
    case ( _, {}, MAP_CONTEXT( useIter = true ), 
         stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        stmt = tplStatement("popIter", {}, intxt, outtxt);
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);
    
    //all args was mapped (or there were no exps to map), the iter functions was not used     
    case ( _, {}, MAP_CONTEXT( useIter = false ), 
         stmts, intxt, _, locals, scEnv, _, accMMDecls )
      then ( stmts, locals, scEnv, accMMDecls, intxt);
        
    //List map - elaborate the list-mapping function
    case ( isfirst, (argtomap as (argmmexp,argtype)) :: restargs, 
             MAP_CONTEXT(ofBinding = ofbind, 
                         mapExp = mapexp,
                         iterMMExpOptions = iopts,
                         indexedArgs = idxargs,
                         useIter = useiter),
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        LIST_TYPE(ofType = oftype) = deAliasedType(argtype, astDefs);
        
        ofbindEnc = typeCheckMatchingExp(ofbind, oftype, astDefs);
        ofbindEnc = encodeMatchingExp(ofbindEnc);
        i0ti = ("i_i0",INTEGER_TYPE());
        i1ti = ("i_i1",INTEGER_TYPE());
        //elaborate statemennts and gather extra arguments and usage of i0 and i1
        (mapstmts, maplocals, scEnv, accMMDecls, _)
          = statementsFromExp(mapexp,{}, {}, imlicitTxt, imlicitTxt, {},
              CASE_SCOPE(ofbindEnc, oftype, {}, "it") :: FUN_SCOPE({i0ti, i1ti}) :: scEnv,
              tplPackage, accMMDecls);
        (CASE_SCOPE(mexp, _, extargs, _) :: _ :: scEnv) = releaseImmediateLocalScope(scEnv);
        //extract if i0/i1 was used
        (foundIdxArgs, extargs) = Util.listSplitOnTrue(extargs, isIndexArg);
        //put nextIter() if needed
        useiter = shouldUseIterFunctions(isfirst, useiter, true, foundIdxArgs, iopts, restargs); 
        //add nextIter() if needed
        stmt = tplStatement("nextIter", {}, imlicitTxt, imlicitTxt);
        mapstmts = Util.if_(useiter, stmt :: mapstmts, mapstmts);
        //(mapstmts,_) = addNextIter(useiter, mapstmts, imlicitTxt, imlicitTxt);
        //create a new list-map function
        fname = "lm_" +& intString(listLength(accMMDecls));
        iargs = imlicitTxtArg :: ("items",argtype) :: extargs;
        assignedTexts = getAssignedTexts(mapstmts, {});
        //oargs = Util.listFilter(extargs, isText);
        oargs = Util.listFilter1(extargs, isAssignedText, assignedTexts);
        oargs = imlicitTxtArg :: oargs;
        lhsArgs = Util.listMap(oargs, Util.tuple21);
        extargvals = Util.listMap(extargs, makeMMArgValue);
        rhsMMArgs = Util.listMap(extargvals, Util.tuple21); 
        //recursive call
        mmRecCall = MM_ASSIGN(
            lhsArgs, 
            MM_FN_CALL(IDENT(fname), MM_IDENT(IDENT(imlicitTxt)) :: MM_IDENT(IDENT("rest")) :: rhsMMArgs) 
        );
        //add the recursive call for the "rest" and revese statemnts        
        mapstmts = listReverse(mmRecCall :: mapstmts);
        //add indexed values if needed
        (mapstmts, maplocals)
          = addGetIndex(i0ti, foundIdxArgs, "i_i0", mapstmts, imlicitTxt, maplocals);
        (mapstmts, maplocals)
          = addGetIndex(i1ti, foundIdxArgs, "i_i1", mapstmts, imlicitTxt, maplocals);
        
        (maplocals, mexp) = localsFromMatchExp(mexp, oftype, maplocals, astDefs);
        //make the empty case, cons case and a failing cons case (only recusive call for the rest)
        mmmcEmptyList = makeMMMatchCase( (LIST_MATCH({}), {},{},{}), extargs, oargs);
        mmmcCons = makeMMMatchCase( 
          (LIST_CONS_MATCH(mexp, BIND_MATCH("rest")), extargs, ("rest",argtype)::maplocals, mapstmts),
          extargs, oargs);
        //TODO: the fail recursive call could be made conditional, only when the mexp can fail
        // or, maybe, always like it is, to make easier location of failing of (badly)imported functions(they should not fail) 
        mmFailCons = makeMMMatchCase( 
          (LIST_CONS_MATCH(REST_MATCH(), BIND_MATCH("rest")), extargs, {("rest",argtype)}, {mmRecCall}),
          extargs, oargs);
        mapctx = MAP_CONTEXT(ofbind, mapexp, iopts, foundIdxArgs, useiter);
        // make fun
        mmFun = MM_FUN(false,fname, iargs, oargs, imlicitTxtArg :: extargs,
                        { MM_MATCH( { mmmcEmptyList, mmmcCons, mmFailCons }  ) },
                        SOME(GI_MAP_FUN(argtype, mapctx))
                );
        
        //add pushIter() if it is the first element of MAP_ARG_LIST (like <[exp1,exp2,...] : mapexp> ) or a simple one (list)exp to be mapped (like <exp of mexp: mapexp>)
        (stmts, intxt) = addPushIter((isfirst and useiter), iopts, stmts, intxt, outtxt);
        
        //call the elaborated function
        (_, stmt, _, _, locals, intxt) 
          = statementFromFun(argtomap :: extargvals, IDENT(fname), iargs, oargs, intxt, outtxt, locals, tplPackage);
          
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(false, restargs, mapctx, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, mmFun :: accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
    
    //scalar map - <argtomap of ofbind: mapexp; iopts>
    case ( isfirst, (argtomap as (argmmexp,argtype)) :: restargs, 
             MAP_CONTEXT(ofBinding = ofbind, 
                         mapExp = mapexp,
                         iterMMExpOptions = iopts,
                         indexedArgs = idxargs,
                         useIter = useiter),
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        failure(LIST_TYPE(_) = deAliasedType(argtype, astDefs));
        
        ofbindEnc = typeCheckMatchingExp(ofbind, argtype, astDefs);
        ofbindEnc = encodeMatchingExp(ofbindEnc);
        i0ti = ("i_i0",INTEGER_TYPE());
        i1ti = ("i_i1",INTEGER_TYPE());
        itName = getItNameFromArg(argmmexp, argtype, ofbindEnc, astDefs); 
        //elaborate statemennts and gather extra arguments and usage of i0 and i1        
        (mapstmts, maplocals, scEnv, accMMDecls, _)
          = statementsFromExp(mapexp,{}, {}, imlicitTxt, imlicitTxt, {},
              CASE_SCOPE(ofbindEnc, argtype, {}, itName) :: FUN_SCOPE({i0ti, i1ti}) :: scEnv,
              tplPackage, accMMDecls);
        (CASE_SCOPE(mexp, _, extargs, _) :: _ :: scEnv) = releaseImmediateLocalScope(scEnv);
        //extract if i0/i1 was used
        (foundIdxArgs, extargs) = Util.listSplitOnTrue(extargs, isIndexArg);
        //put nextIter() if needed
        useiter = shouldUseIterFunctions(isfirst, useiter, false, foundIdxArgs, iopts, restargs); 
        
        //make scalar map
        
        //add nextIter() if needed
        stmt = tplStatement("nextIter", {}, imlicitTxt, imlicitTxt);
        mapstmts = Util.if_(useiter, stmt :: mapstmts, mapstmts);
        //(mapstmts,_) = addNextIter(useiter, mapstmts, imlicitTxt, imlicitTxt);
        
        //create a new scalar-map function, 
        //where ofbind is not a simple BIND_MATCH -> it must be a match fun
        fname = "smf_" +& intString(listLength(accMMDecls));
        iargs = imlicitTxtArg :: ("it",argtype) :: extargs;
        assignedTexts = getAssignedTexts(mapstmts, {});
        //oargs = Util.listFilter(extargs, isText); //it can be actually Text, but not to be as output stream
        oargs = Util.listFilter1(extargs, isAssignedText, assignedTexts);
        oargs = imlicitTxtArg :: oargs;
        extargvals = Util.listMap(extargs, makeMMArgValue);
        mapstmts = listReverse(mapstmts);
        //add indexed values if needed
        (mapstmts, maplocals)
          = addGetIndex(i0ti, foundIdxArgs, "i_i0", mapstmts, imlicitTxt, maplocals);
        (mapstmts, maplocals)
          = addGetIndex(i1ti, foundIdxArgs, "i_i1", mapstmts, imlicitTxt, maplocals);
        
        (maplocals, mexp) = localsFromMatchExp(mexp, argtype, maplocals, astDefs);
        
        elabcases = addRestElabCase({(mexp, extargs, maplocals, mapstmts)});
        mmmcases = Util.listMap2(elabcases, makeMMMatchCase, extargs, oargs);
        mapctx = MAP_CONTEXT(ofbind, mapexp, iopts, foundIdxArgs, useiter);
        // make fun
        mmFun = MM_FUN(false, fname, iargs, oargs, imlicitTxtArg :: extargs,
                       { MM_MATCH( mmmcases  ) },
                       SOME(GI_MAP_FUN(argtype, mapctx))
                );
        
        //add pushIter() if it is the first element of MAP_ARG_LIST (like <[exp1,exp2,...] : mapexp> ) or a simple one (list)exp to be mapped (like <exp of mexp: mapexp>)
        (stmts, intxt) = addPushIter((isfirst and useiter), iopts, stmts, intxt, outtxt);
        
        //call the elaborated function
        (_, stmt, _, _, locals, intxt) 
          = statementFromFun(argtomap :: extargvals, IDENT(fname), iargs, oargs, intxt, outtxt, locals, tplPackage);
          
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(false, restargs, mapctx, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, mmFun :: accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);
        
    //may fail on error
    case (_,_,_,_,_, _,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!statementsFromMapExp failed\n");
      then
        fail();
  end matchcontinue;           
end statementsFromMapExp;

function isIndexArg
  input tuple<Ident, TypeSignature> inArg;
  output Boolean outIsIndexArg;
algorithm
  outIsIndexArg := matchcontinue inArg
    case ( ("i_i0" , _) )  then true;
    case ( ("i_i1" , _) )  then true;
    case ( _ )            then false;    
  end matchcontinue;           
end isIndexArg;


public function shouldUseIterFunctions
  input Boolean inIsFirstArgToMap;
  input Boolean inUseIterLast;
  input Boolean inIsListArgToMap;
  input TypedIdents inFoundIdxArgs;
  input list<MMEscOption> inIterOptions;
  input list<tuple<MMExp, TypeSignature>> inRestArgValsToMap;
  
  output Boolean outUseIterFuns;    
algorithm
  (outUseIterFuns)
  := matchcontinue (inIsFirstArgToMap, inUseIterLast, inIsListArgToMap, inFoundIdxArgs, inIterOptions, inRestArgValsToMap)
    local
      Boolean useiter;
      list<MMEscOption> iopts;
    
    //already decided by the first argval to be mapped  
    case (false, useiter, _, _, _, _)
      then useiter;    
  
    //- list argument to be mapped,
    //- no i0 or i1 are used,
    //- iter options are like these
    //then there is no usage of the iteration environment from the user expression    
    case (true, _, true, {}, iopts, _)
      equation
        iopts = listAppend(iopts, nonSpecifiedIterOptions); 
        ((MM_LITERAL("NONE"),_)) = lookupTupleList(iopts, emptyOptionId);
        ((MM_LITERAL("NONE"),_)) = lookupTupleList(iopts, separatorOptionId);
        ((MM_LITERAL("0"),_))    = lookupTupleList(iopts, alignNumOptionId);
        ((MM_LITERAL("0"),_))    = lookupTupleList(iopts, wrapWidthOptionId);
      then false;
    
    //- scalar argument to be mapped,
    //- no i0 or i1 are used,
    //- no empty option specified
    //- this is the only argument to be mapped
    //then there is no usage of the iteration environment from the user expression    
    case (true, _, false, {}, iopts, {})
      equation
        iopts = listAppend(iopts, nonSpecifiedIterOptions); 
        ((MM_LITERAL("NONE"),_)) = lookupTupleList(iopts, emptyOptionId);        
      then false;
    
    //otherwise use it 
    case (_, _, _, _, _, _)
      then true;
 
  end matchcontinue;           
end shouldUseIterFunctions;

/*
public function addNextIter
  input Boolean inUseIterFun;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  
  output list<MMExp> outStmts;
  output Ident outInText;   
algorithm
  (outStmts, outInText)
  := matchcontinue (inUseIterFun, inStmts, inInText, inOutText)
    local
      list<MMExp> stmts;
      MMExp stmt; 
      Ident intxt, outtxt;
      
    case ( true, stmts, intxt, outtxt)
      equation
        stmt = tplStatement("nextIter", {}, intxt, outtxt);
      then ( stmt :: stmts, outtxt );
    
    case ( false, stmts, intxt, _)
      then ( stmts, intxt );
        
    //cannot happen
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addNextIter failed\n");
      then
        fail();
  end matchcontinue;           
end addNextIter;
*/

public function addGetIndex
  input tuple<Ident, TypeSignature> inIdxTypedIdent;
  input TypedIdents inFoundIdxArgs;
  input Ident inLocalIdxValIdent;
  input list<MMExp> inStmts;
  input Ident inInText;
  input TypedIdents inLocals;
  
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outStmts, outLocals)
  := matchcontinue (inIdxTypedIdent, inFoundIdxArgs, inLocalIdxValIdent, inStmts, inInText, inLocals)
    local
      list<MMExp> stmts;
      MMExp stmt; 
      Ident ixid, localidxid, intxt, outtxt;
      tuple<Ident, TypeSignature> ixti;
      TypedIdents foundIdxArgs, locals;
      TypeSignature ts;
      
    // add the getIter_ix() when the ixti is used by mapexp
    case ( ixti as (ixid,ts), foundIdxArgs, localidxid, stmts, intxt, locals)
      equation
        true = listMember(ixti, foundIdxArgs);
        stmt = tplStatement("getIter" +& ixid, {}, intxt, localidxid);
        locals = addLocalValue(localidxid, ts, locals);
      then ( stmt :: stmts, locals );
    
    case ( ixti, foundIdxArgs, _, stmts, intxt, locals)
      equation
        false = listMember(ixti, foundIdxArgs);
      then ( stmts, locals);
        
    //should not happen
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addGetIndex failed\n");
      then
        fail();
  end matchcontinue;           
end addGetIndex;

public function addPushIter
  input Boolean inDoAddPushIter;
  input list<MMEscOption> inMMEscOptions;
  input list<MMExp> inStmts;
  input Ident inInText;
  input Ident inOutText;
  
  output list<MMExp> outStmts;
  output Ident outInText;   
algorithm
  (outStmts, outInText)
  := matchcontinue (inDoAddPushIter, inMMEscOptions, inStmts, inInText, inOutText)
    local
      list<MMExp> stmts, mmopts;
      MMExp stmt; 
      Ident intxt, outtxt;
      list<MMEscOption> opts;
      
    case ( false, _, stmts, intxt, _)
      then ( stmts, intxt );
    
    case ( true, opts, stmts, intxt, outtxt)
      equation
        (mmopts,_) = makeMMExpOptions(nonSpecifiedIterOptions, opts);
        stmt = tplStatement("pushIter", 
           { MM_FN_CALL(PATH_IDENT("Tpl", IDENT("ITER_OPTIONS")), mmopts)},
           intxt, outtxt);
      then ( stmt :: stmts, outtxt );
        
    //cannot happen
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addNextIter failed\n");
      then
        fail();
  end matchcontinue;           
end addPushIter;


public function makeMMExpOptions
  input list<MMEscOption> inMMEscOptions;
  input list<MMEscOption> inSpecifiedMMEscOptions;
   
  output list<MMExp> outMMExpOpts;
  output list<MMEscOption> outRestSpecifiedMMExpOpts;
algorithm
  (outMMExpOpts, outRestSpecifiedMMExpOpts)
   := matchcontinue (inMMEscOptions, inSpecifiedMMEscOptions)
    local
      list<MMEscOption> rest, specopts;
      list<MMExp> mexpOpts;
      MMExp mexpopt;
      Ident optid;
      
    case ( {}, specopts )
      then ({}, specopts);
    
    case ( (optid, _) :: rest,  specopts )
      equation
        ((mexpopt,_), specopts) = lookupDeleteTupleList(specopts, optid);
        (mexpOpts, specopts) = makeMMExpOptions(rest, specopts);
      then ((mexpopt :: mexpOpts), specopts);
    
    case ( (optid, (mexpopt,_)) :: rest,  specopts )
      equation
        //failure( _ = lookupTupleList(specopts, optid));
        (mexpOpts, specopts) = makeMMExpOptions(rest, specopts);
      then ((mexpopt :: mexpOpts), specopts);
    
    //cannot happen
    case (_, _)
      equation
        Debug.fprint("failtrace", "-!!!makeMMExpOptions failed\n");
      then
        fail();
  end matchcontinue;           
end makeMMExpOptions;

/*
public function mmexpFromStrTokOption
  input Option<StringToken> inStrTokOption;  
  output MMExp outMMExp;
algorithm
  outMMExp := matchcontinue inStrTokOption
    local
      StringToken st;
      
    case ( NONE )
      then MM_LITERAL("NONE");
    
    case ( SOME(st) )
      then MM_FN_CALL(IDENT("SOME"), { MM_STR_TOKEN(st) });
    
    //cannot happen
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!mmexpFromStrTokOption failed\n");
      then
        fail();
  end matchcontinue;           
end mmexpFromStrTokOption;
*/

public function makeMatchFun
  input tuple<MMExp, TypeSignature> inArgval;
  input list<tuple<MatchingExp,Expression>> inMCases;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<tuple<MMExp, TypeSignature>> outArgvals;
  output PathIdent outFunName;
  output TypedIdents outInArgs;
  output TypedIdents outOutArgs;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
   
algorithm
  (outArgvals, outFunName, outInArgs, outOutArgs, outScopeEnv, outMMDecls) 
  := matchcontinue (inArgval, inMCases, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      ScopeEnv scEnv;
      tuple<MMExp, TypeSignature> argval;
      list<tuple<MMExp, TypeSignature>> argvals;
      MMExp mmexp;
      TypeSignature exptype;
      TypedIdents iargs, oargs, extargs, locals;
      list<tuple<MatchingExp,Expression>> mcases;
      list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> elabcases;
      list<MMMatchCase> mmmcases;
      TemplPackage tplPackage;            
      list<MMDeclaration> accMMDecls;
      MMDeclaration mmFun;
      Ident fname, matchident;
      list<Ident> assignedTexts;
    
    case ( argval as (mmexp, exptype), mcases, scEnv, tplPackage, accMMDecls )
      equation
        //TODO: when mmexp is an identifier, it should be made available through implicit context
        //so we will prepend it before each mexp in every case (instead 'it')
        //then, mexps should be cleaned off the unused bindings ??....
        //this is not critical, the value will be now passed as another parameter (a duplicity value) 
        (elabcases, (FUN_SCOPE(extargs) :: scEnv), accMMDecls, assignedTexts)
          = elabMatchCases(argval, mcases, (FUN_SCOPE( {} ) :: scEnv), tplPackage, accMMDecls);
        elabcases = addRestElabCase(elabcases);
        extargs = alignExtArgsToScopeEnv(extargs, scEnv); //order the args by the upper scope -> when the match function will be pulled to the top-level, the arguments must be ordered the same way ... MM stuff
        
        matchident = getMatchIdent(mmexp); //when an ident, give it the same name
        iargs = imlicitTxtArg :: (matchident,exptype) :: extargs;
        oargs = Util.listFilter1(extargs, isAssignedText, assignedTexts);
        oargs = imlicitTxtArg :: oargs;
        
        mmmcases = Util.listMap2(elabcases, makeMMMatchCase, extargs, oargs);
        fname = stringAppend("fun_", intString(listLength(accMMDecls)));
        mmFun = MM_FUN(false, fname, iargs, oargs,
                  imlicitTxtArg :: extargs,
                  { MM_MATCH(mmmcases) },
                  NONE
                );
        argvals = Util.listMap(extargs, makeMMArgValue);
        argvals = argval :: argvals;
      then ( argvals, IDENT(fname), iargs, oargs, scEnv, (mmFun :: accMMDecls));
    
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!makeMatchFun failed\n");
      then
        fail();
  end matchcontinue;           
end makeMatchFun;


public function alignExtArgsToScopeEnv
  input TypedIdents inExtraArgs;
  input ScopeEnv inScopeEnv;
  
  output TypedIdents outExtraArgs;
algorithm
  (outExtraArgs) := 
  matchcontinue (inExtraArgs, inScopeEnv)
    local
      ScopeEnv scEnv;
      TypedIdents extargs, extargsAligned, fargs;
      
    case ( extargs,  scEnv as (FUN_SCOPE(args = fargs) :: _))
      equation
        extargsAligned = alignTupleList(extargs, fargs);
        //assure no lost of arguments, all extra args must come from the function call that takes the args from its args   
        true = (listLength(extargsAligned) == listLength(extargs));
      then extargsAligned;
    
    case (extargs,_)
      then
        extargs;
        
  end matchcontinue;           
end alignExtArgsToScopeEnv;


public function getMatchIdent
  input MMExp inMMArg;
  output Ident outMatchArgName;
algorithm
  outMatchArgName := matchcontinue inMMArg
    local
      Ident matchident;
    case ( MM_IDENT(IDENT(matchident)) )  
      equation //now idents starts with "i_"
        true = stringLength(matchident) > 2;
        "i" = stringGetStringChar(matchident, 1); //it is not an internally elaborated ident (that does not have "i_" at the start)
        "_" = stringGetStringChar(matchident, 2); 
      then matchident;
    case ( _ )  
      then "it";
  end matchcontinue;           
end getMatchIdent;

public function makeMMArgValue
  input tuple<Ident,TypeSignature> inTypedIdent;
  output tuple<MMExp, TypeSignature> outArgValue;   
algorithm
  outArgValue := matchcontinue  inTypedIdent
    local
      Ident argname;
      TypeSignature ts;
    case ( (argname, ts) )
      then 
        ( (MM_IDENT(IDENT(argname)) , ts) );
        
    //cannot happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!makeMMArgValue failed\n");
      then
        fail();
  end matchcontinue;           
end makeMMArgValue;


function isText
  input tuple<Ident, TypeSignature> inArg;
algorithm
  _:= matchcontinue(inArg)
    case ( (_ , TEXT_TYPE()) )
      then ();
  end matchcontinue;           
end isText;

function isAssignedText
  input tuple<Ident, TypeSignature> inArg;
  input list<Ident> inAssignedTexts;
algorithm
  _:= matchcontinue(inArg, inAssignedTexts)
    case ( (ident , TEXT_TYPE()), assignedTexts )
      local 
        Ident ident;
        list<Ident> assignedTexts;
      equation
        true = listMember(ident,assignedTexts); 
      then ();
  end matchcontinue;           
end isAssignedText;


public function elabMatchCases
  input tuple<MMExp, TypeSignature> inItArgVal;
  input list<tuple<MatchingExp,Expression>> inMCases;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  input list<MMDeclaration> inAccMMDecls;

  output list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> outMMMCases;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output list<Ident> outAssignedTexts;
algorithm
  (outMMMCases, outScopeEnv, outMMDecls, outAssignedTexts) 
  := matchcontinue (inItArgVal, inMCases, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      ScopeEnv scEnv;
      TypedIdents locals;
      TypeSignature exptype;
      TypedIdents extargs;
      list<tuple<MatchingExp,Expression>> mcases;
      MatchingExp mexp;
      Expression exp;      
      list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> elabcases;
      TemplPackage tplPackage;
      list<ASTDef> astdefs;
      list<MMDeclaration> accMMDecls;
      MMExp mmexp;
      list<MMExp> stmts;
      tuple<MMExp, TypeSignature> argval;
      Ident itName;
      list<Ident> assignedTexts;
       
    case ( _, {}, scEnv, _, accMMDecls)
      then 
        ( {}, scEnv, accMMDecls, {});
        
    case ( argval as (mmexp, exptype), (mexp,exp) :: mcases, scEnv, 
           tplPackage as TEMPL_PACKAGE(astDefs = astdefs), accMMDecls )
      equation
        mexp = typeCheckMatchingExp(mexp, exptype, astdefs); //also converts idents to records when resolved
        mexp = encodeMatchingExp(mexp);
        itName = getItNameFromArg(mmexp, exptype, mexp, astdefs); 
        (stmts, locals, scEnv, accMMDecls, _)
          = statementsFromExp(exp,{}, {}, imlicitTxt, imlicitTxt, {},
              (CASE_SCOPE(mexp, exptype, {}, itName ) :: scEnv), tplPackage, accMMDecls);
        (CASE_SCOPE(mexp, _, extargs, _) :: scEnv) = releaseImmediateLocalScope(scEnv);
        stmts = listReverse(stmts);
        //TODO: locals can be gathered with introduction of another function scope
        //and then to see what was used, the rest can be eliminated with the typecheck function
        (locals, mexp) = localsFromMatchExp(mexp, exptype, locals, astdefs);
        (elabcases, scEnv, accMMDecls, assignedTexts)
          = elabMatchCases(argval, mcases, scEnv, tplPackage, accMMDecls );
        assignedTexts = getAssignedTexts(stmts, assignedTexts);        
      then 
        ( (mexp, extargs, locals, stmts) :: elabcases, scEnv, accMMDecls, assignedTexts);
    
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!elabMatchCases failed\n");
      then
        fail();
  end matchcontinue;           
end elabMatchCases;


public function getAssignedTexts
  input list<MMExp> inStatements;
  input list<Ident> inAssignedTexts;
  
  output list<Ident> outAssignedTexts;
algorithm
  (outAssignedTexts) 
  := matchcontinue (inStatements, inAssignedTexts)
    local
       list<MMExp> stmts;
      list<Ident> assignedTexts, largs;
       
    case ( {}, assignedTexts)
      then 
        ( assignedTexts);
        
    case ( MM_ASSIGN(lhsArgs = largs) :: stmts, assignedTexts)
      equation
        assignedTexts = Util.listFold(largs, Util.listUnionElt, assignedTexts);        
      then 
        getAssignedTexts(stmts, assignedTexts);
    
    case ( _ :: stmts, assignedTexts)
      then 
        getAssignedTexts(stmts, assignedTexts);
    
    case (_,_)
      equation
        Debug.fprint("failtrace", "-!!!getAssignedTexts failed\n");
      then
        fail();
  end matchcontinue;           
end getAssignedTexts;


public function getItNameFromArg
  input MMExp inItArgMMExp;
  input TypeSignature inMType;
  input MatchingExp inMatchingExp;
  input list<ASTDef> inASTDefs;
  
  output Ident outItName;   
algorithm
  (outMatchingExp) 
  := matchcontinue (inItArgMMExp, inMType, inMatchingExp, inASTDefs)
    local
      TypeSignature exptype;
      MatchingExp mexp;
      list<ASTDef> astdefs;
      MMExp mmexp;
      PathIdent path;
      Ident argid;
    
    //name it by the arg name if the name is not bound
    case ( MM_IDENT(path as IDENT(argid)), exptype, mexp, astdefs)
      equation
        //only when the argid is not yet bound by the user to do it explicit or hide the name from the upper scope
        failure( (_,_) = lookupUpdateMatchingExp(argid, path, mexp, exptype, astdefs) );
      then 
        argid;
    
    //otherwise return "it" as the name
    case (_,_,_,_)
      then
        "it";
        
  end matchcontinue;           
end getItNameFromArg;



public function typeCheckMatchingExp 
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;
  
  output MatchingExp outTransformedMatchingExp;
algorithm 
  (outTransformedMatchingExp) 
    := matchcontinue (inMatchingExp, inMType, inASTDefs)
    local
      Ident bid, fldId, typeident;
      PathIdent tagpath, typepath, typepckg;
      Option<PathIdent> typepckgOpt;
      TypeInfo typeinfo;
      TypeSignature mtype, ot;
      list<TypeSignature> otLst;
      MatchingExp mexp, restmexp, omexp;
      list<MatchingExp> mexpLst;
      list<tuple<String, MatchingExp>> fms;
      TypedIdents fields, locals;
      list<ASTDef> astDefs;
      String litval;      
    
    case ( BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs)
      equation
        mexp = typeCheckMatchingExp(mexp, mtype, astDefs);
      then 
        (BIND_AS_MATCH(bid, mexp));
    
    //try if it is a record ident
    //-> convert to RECORD_MATCH()
    case ( BIND_MATCH(bindIdent = bid), mtype, astDefs)
      equation
        NAMED_TYPE(typepath) = deAliasedType(mtype, astDefs);
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (typepckg, typeinfo) = getTypeInfo(typepckgOpt, typeident, astDefs);
        isRecordTag(bid, typeinfo, typeident);
        tagpath = makePathIdent(typepckg, bid);
      then 
        (RECORD_MATCH(tagpath, {} ));
    
    //otherwise it is like REST_MATCH ... nothing to check
    case ( mexp as BIND_MATCH(_), _, _)
      then 
        mexp;
    
    case ( RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), 
           mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs);
        fms = typeCheckMatchingExpRecord(fms, fields, astDefs);
      then 
        RECORD_MATCH(tagpath, fms);
        
    case ( SOME_MATCH(
             value = mexp ), mtype, astDefs)
      equation
        OPTION_TYPE(ofType = mtype) = deAliasedType(mtype, astDefs);
        mexp = typeCheckMatchingExp(mexp, mtype, astDefs);
      then 
        SOME_MATCH(mexp);
    
    // TODO - failure message when not Option
    case ( mexp as NONE_MATCH(), mtype, astDefs)
      equation
        OPTION_TYPE(_) = deAliasedType(mtype, astDefs);
      then 
        mexp;
    
    // TODO - failure message when not Tuple / not the same length
    case ( TUPLE_MATCH(
             tupleArgs = mexpLst), 
           mtype, astDefs )
      equation
        TUPLE_TYPE(ofTypes = otLst) = deAliasedType(mtype, astDefs);
        //equality( listLength(mexpLst) = listLength(otLst) );
        mexpLst = typeCheckMatchingExpList(mexpLst, otLst, astDefs);
      then 
        TUPLE_MATCH(mexpLst);
    
    // TODO - failure message when not List      
    case ( LIST_MATCH(
             listElts = mexpLst), 
           mtype, astDefs )
      equation
        LIST_TYPE(ofType = ot) = deAliasedType(mtype, astDefs);
        otLst = Util.listFill(ot, listLength(mexpLst));
        mexpLst = typeCheckMatchingExpList(mexpLst, otLst, astDefs);
      then 
        LIST_MATCH(mexpLst);
    
    // TODO - failure message when not List      
    case ( LIST_CONS_MATCH(
             head = mexp,
             rest = restmexp), 
           mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        LIST_TYPE(ofType = ot) = mtype;
        mexp = typeCheckMatchingExp(mexp, ot, astDefs);
        restmexp = typeCheckMatchingExp(restmexp, mtype, astDefs);
      then 
        LIST_CONS_MATCH(mexp, restmexp);

    // TODO - failure message when not equal types
    case ( mexp as STRING_MATCH(_), 
           mtype, astDefs )
      equation
        STRING_TYPE() = deAliasedType(mtype, astDefs);
      then 
        mexp;
          
    // TODO - failure message when not equal types
    case ( mexp as LITERAL_MATCH(litType = ot), 
           mtype, astDefs )
      equation
        typesEqual(deAliasedType(ot, astDefs), deAliasedType(mtype, astDefs), astDefs);         
      then 
        mexp;
    
    case ( mexp as REST_MATCH(), _, _)
      then 
        mexp;
    
    
    // ** failures ***
    //TODO: will be concrete with output message
    
    case (mexp, mtype,_)
      equation
        //locals = addLocalValue("#Error - type check#", mtype, locals);
        Debug.fprint("failtrace", "Error - typeCheckMatchingExp failed\n");
      then
        fail();
    
    // should not ever happen
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!typeCheckMatchingExp failed\n");
      then
        fail();
        
  end matchcontinue;
end typeCheckMatchingExp;


public function typeCheckMatchingExpRecord 
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  input TypedIdents fields;
  input list<ASTDef> inASTDefs;
  
  output list<tuple<Ident, MatchingExp>> outTransformedMatchingExp;  
algorithm 
  (outTransformedMatchingExp) 
    := matchcontinue (inFieldMatchings, fields, inASTDefs)
    local
      Ident ident;
      MatchingExp mexp;
      TypeSignature mtype;
      list<tuple<Ident, MatchingExp>> fms;
      TypedIdents locals, fields;
      list<ASTDef> astDefs;
      String reason;      
    
    case ( {}, _, _)
      then 
        {};
    
    case ( (ident, mexp) :: fms, fields, astDefs)
      equation
        mtype = lookupTupleList(fields, ident);
        mexp = typeCheckMatchingExp(mexp, mtype, astDefs);
        fms  = typeCheckMatchingExpRecord(fms, fields, astDefs);        
      then 
        ((ident, mexp) :: fms);
    
    case ( (ident, mexp) :: fms, fields, astDefs)
      equation
        failure( _ = lookupTupleList(fields, ident) );
        //reason = "#Error - unresolved type - cannot find field '" +& ident +& "'#";
        Debug.fprint("failtrace", "Error - typeCheckMatchingExpRecord failed to find field '" +& ident +& "'\n");
        //(locals, fms) = localsFromMatchExpAndTypeCheckRecord(fms, fields, locals, astDefs);        
      then
        fail(); 
        //(locals, (ident, mexp) :: fms);
    
    // can fail on error
    /*
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!localsFromMatchExpAndTypeCheckRecord failed\n");
      then
        fail();
    */    
  end matchcontinue;
end typeCheckMatchingExpRecord;


public function typeCheckMatchingExpList 
  input list<MatchingExp> inMatchingExpLst;
  input list<TypeSignature> inTypeLst;
  input list<ASTDef> inASTDefs;
  
  output list<MatchingExp> outTransformedMatchingExp;
algorithm 
  (outTransformedMatchingExp) 
    := matchcontinue (inMatchingExpLst, inTypeLst, inASTDefs)
    local
      Ident ident;
      MatchingExp mexp;
      list<MatchingExp> mexpLst;
      TypeSignature mtype;
      list<TypeSignature> tsLst;
      list<tuple<Ident, MatchingExp>> fms;
      
      TypedIdents locals, fields;
      list<ASTDef> astDefs;      
    
    case ( {}, {}, _)
      then 
        {};
    
    case ( mexp :: mexpLst, mtype :: tsLst, astDefs)
      equation
        mexp  = typeCheckMatchingExp(mexp, mtype, astDefs);
        mexpLst = typeCheckMatchingExpList(mexpLst, tsLst, astDefs);        
      then 
        (mexp :: mexpLst);
    
    case ( mexpLst as (_ :: _), {}, _)
      equation
        Debug.fprint("failtrace", "Error - typeCheckMatchingExpList more expressions to chceck than required (a tuple type has less arguments than provided?).\n");
      then 
        fail();
    
    case ( {}, _ :: _, _)
      equation
        Debug.fprint("failtrace", "Error - typeCheckMatchingExpList more arguments expected (the tuple type has more arguments than provided).\n");
      then 
        fail();
    
    // can fail on error
    /*
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!localsFromMatchExpAndTypeCheckList failed\n");
      then
        fail();
    */    
  end matchcontinue;
end typeCheckMatchingExpList;


public function localsFromMatchExp 
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input TypedIdents inLocals;
  input list<ASTDef> inASTDefs;
  
  output TypedIdents outLocals;
  output MatchingExp outFullyQualifiedMatchingExp;
algorithm 
  (outLocals, outFullyQualifiedMatchingExp) 
    := matchcontinue (inMatchingExp, inMType, inLocals, inASTDefs)
    local
      Ident bid, fldId;
      PathIdent tagpath;
      TypeSignature mtype, ot;
      list<TypeSignature> otLst;
      MatchingExp mexp, restmexp, omexp;
      list<MatchingExp> mexpLst;
      list<tuple<String, MatchingExp>> fms;
      TypedIdents fields, locals;
      list<ASTDef> astDefs;
      String litval;      
    
    case ( BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, locals, astDefs)
      equation
        locals = addLocalValue(bid, mtype, locals);
        (locals, mexp) = localsFromMatchExp(mexp, mtype, locals, astDefs);
      then 
        (locals, BIND_AS_MATCH(bid, mexp));
    
    case ( mexp as BIND_MATCH(
                      bindIdent = bid), mtype, locals, _)
      equation
        locals = addLocalValue(bid, mtype, locals);        
      then 
        (locals, mexp);
    
    // a record with some fields is matched but no fields were used
    //-> adjust it to match the first field with "_" to obey MM semantics 
    case ( RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = {} ), 
           mtype, locals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        ((fldId,_)::_, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs);
      then 
        (locals, RECORD_MATCH(tagpath, {(fldId, REST_MATCH())} ));
    
    case ( RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), 
           mtype, locals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs);
        (locals, fms) = localsFromMatchExpRecord(fms, fields, locals, astDefs);
      then 
        (locals, RECORD_MATCH(tagpath, fms ));
        
    case ( SOME_MATCH(
             value = mexp ), mtype, locals, astDefs)
      equation
        OPTION_TYPE(ofType = mtype) = deAliasedType(mtype, astDefs);
        (locals, mexp) = localsFromMatchExp(mexp, mtype, locals, astDefs);
      then 
        (locals, SOME_MATCH(mexp));
    
    case ( TUPLE_MATCH(
             tupleArgs = mexpLst), 
           mtype, locals, astDefs )
      equation
        TUPLE_TYPE(ofTypes = otLst) = deAliasedType(mtype, astDefs);
        //equality( listLength(mexpLst) = listLength(otLst) );
        (locals, mexpLst) = localsFromMatchExpList(mexpLst, otLst, locals, astDefs);
      then 
        (locals, TUPLE_MATCH(mexpLst));
    
    case ( LIST_MATCH(
             listElts = mexpLst), 
           mtype, locals, astDefs )
      equation
        LIST_TYPE(ofType = ot) = deAliasedType(mtype, astDefs);
        otLst = Util.listFill(ot, listLength(mexpLst));
        (locals, mexpLst) = localsFromMatchExpList(mexpLst, otLst, locals, astDefs);
      then 
        (locals, LIST_MATCH(mexpLst));
    
    case ( LIST_CONS_MATCH(
             head = mexp,
             rest = restmexp), 
           mtype, locals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        LIST_TYPE(ofType = ot) = mtype;
        (locals, mexp) = localsFromMatchExp(mexp, ot, locals, astDefs);
        (locals, restmexp) = localsFromMatchExp(restmexp, mtype, locals, astDefs);
      then 
        (locals, LIST_CONS_MATCH(mexp, restmexp));

    // the rest - NONE_MATCH, STRING_MATCH, LITERAL_MATCH, REST_MATCH
    case ( mexp , _, locals, _)
      then 
        (locals, mexp);
    
    
    // should not ever happen
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!localsFromMatchExp failed\n");
      then
        fail();
        
  end matchcontinue;
end localsFromMatchExp;


public function addLocalValue 
  input Ident inIdent;
  input TypeSignature inMType;
  input TypedIdents inLocals;
  
  output TypedIdents outLocals;
algorithm 
  outLocals := matchcontinue (inIdent, inMType, inLocals)
    local
      Ident ident;
      TypeSignature mtype;
      TypedIdents locals;
      
    // special case when no local statement where added to an empty text
    case ( ident, TEXT_TYPE(), locals)
      equation
        equality(ident = emptyTxt);
      then 
        locals;
        
    case ( ident, mtype, locals)
      equation
        failure( _ = lookupTupleList(locals, ident) );
      then 
        ((ident, mtype) :: locals);
    
    //i0 and i1 could be already there, they are "reused"
    case ( ident, INTEGER_TYPE(), locals)
      equation
        true = (ident ==& "i0") or (ident ==& "i1");
      then 
        locals;
        
    case ( ident, mtype, locals)
      equation
        _ = lookupTupleList(locals, ident);
        Debug.fprint("failtrace", "Error - addLocalValue added duplicite local value '" +& ident +& "' - a matching expression contain the duplicitly bound identifier. \n");
      then 
        ((ident, mtype) :: locals);
    
    // should not ever happen
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!addLocalValue failed\n");
      then
        fail();
  end matchcontinue;
end addLocalValue;


public function localsFromMatchExpRecord 
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  input TypedIdents fields;
  input TypedIdents inLocals;
  input list<ASTDef> inASTDefs;
  
  output TypedIdents outLocals;
  output list<tuple<Ident, MatchingExp>> outFullyQualifiedFieldMatchings;  
algorithm 
  (outLocals, outFullyQualifiedFieldMatchings) 
    := matchcontinue (inFieldMatchings, fields, inLocals, inASTDefs)
    local
      Ident ident;
      MatchingExp mexp;
      TypeSignature mtype;
      list<tuple<Ident, MatchingExp>> fms;
      TypedIdents locals, fields;
      list<ASTDef> astDefs;
      String reason;      
    
    case ( {}, _, locals, _)
      then 
        (locals, {});
    
    case ( (ident, mexp) :: fms, fields, locals, astDefs)
      equation
        mtype = lookupTupleList(fields, ident);
        (locals, mexp) = localsFromMatchExp(mexp, mtype, locals, astDefs);
        (locals, fms)  = localsFromMatchExpRecord(fms, fields, locals, astDefs);        
      then 
        (locals, (ident, mexp) :: fms);
    
    case ( (ident, mexp) :: fms, fields, locals, astDefs)
      equation
        failure( _ = lookupTupleList(fields, ident) );
        reason = "#Error - unresolved type - cannot find field '" +& ident +& "'#";
        locals = addLocalValue(ident, UNRESOLVED_TYPE(reason), locals);        
        Debug.fprint("failtrace", "Error - localsFromMatchExpRecord failed to find field '" +& ident +& "'\n");
        (locals, fms) = localsFromMatchExpRecord(fms, fields, locals, astDefs);        
      then 
        (locals, (ident, mexp) :: fms);
    
    // should not ever happen
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!localsFromMatchExpRecord failed\n");
      then
        fail();
        
  end matchcontinue;
end localsFromMatchExpRecord;


public function localsFromMatchExpList 
  input list<MatchingExp> inMatchingExpLst;
  input list<TypeSignature> inTypeLst;
  input TypedIdents inLocals;
  input list<ASTDef> inASTDefs;
  
  output TypedIdents outLocals;
  output list<MatchingExp> outFullyQualifiedMatchingExpLst;
algorithm 
  (outLocals, outFullyQualifiedMatchingExpLst) 
    := matchcontinue (inMatchingExpLst, inTypeLst, inLocals, inASTDefs)
    local
      Ident ident;
      MatchingExp mexp;
      list<MatchingExp> mexpLst;
      TypeSignature mtype;
      list<TypeSignature> tsLst;
      list<tuple<Ident, MatchingExp>> fms;
      
      TypedIdents locals, fields;
      list<ASTDef> astDefs;      
    
    case ( {}, {}, locals, _)
      then 
        (locals, {});
    
    case ( mexp :: mexpLst, mtype :: tsLst, locals, astDefs)
      equation
        (locals, mexp)    = localsFromMatchExp(mexp, mtype, locals, astDefs);
        (locals, mexpLst) = localsFromMatchExpList(mexpLst, tsLst, locals, astDefs);        
      then 
        (locals, mexp :: mexpLst);
    
    // should not ever happen - when type check was successful
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!localsFromMatchExpList failed\n");
      then
        fail();
        
  end matchcontinue;
end localsFromMatchExpList;


public function makeMMMatchCase
  input tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>> inElabCase;
  input TypedIdents inExtraArgs;
  input TypedIdents inOutArgs;
  
  output MMMatchCase outMMMCase;   
algorithm
  (outMMMCase) 
  := matchcontinue (inElabCase, inExtraArgs, inOutArgs)
    local
      MatchingExp mexp;
      TypedIdents locals, caseargs, extargs, oargs;
      MMMatchCase mmmcase;
      list<MMExp> stmts;
      list<MatchingExp> mexpLst;
      
    case ( (mexp, caseargs, locals, stmts), extargs, oargs)
      equation
        mexpLst = Util.listMap2(extargs, makeExtraArgBinding, caseargs, oargs);
        mmmcase = ( (imlicitTxtMExp :: mexp :: mexpLst),
                   locals, stmts );
      then mmmcase;
    
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!makeMMMatchCase failed\n");
      then
        fail();
  end matchcontinue;           
end makeMMMatchCase;


public function makeExtraArgBinding
  input tuple<Ident,TypeSignature> inExtraArg;
  input TypedIdents inCaseArgs;
  input TypedIdents inOutArgs;
  
  output MatchingExp outExtraArgBinding;   
algorithm
  outExtraArgBinding := matchcontinue (inExtraArg, inCaseArgs, inOutArgs)
    local
      Ident argname;
      TypedIdents caseargs, oargs;
      
    //out args are always passed through
    case ( (argname, _), _, oargs)
      equation
        _ = lookupTupleList(oargs, argname);                
      then 
        BIND_MATCH(argname);
    
    case ( (argname, _), caseargs, _)
      equation
        _ = lookupTupleList(caseargs, argname);                
      then 
        BIND_MATCH(argname);
    
    case ( _, _, _)
      //equation
      //  failure(_ = lookupTupleList(inCaseArgs, argname));                
      then 
        REST_MATCH();
        
    case (_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!makeExtraArgBinding failed\n");
      then
        fail();
  end matchcontinue;           
end makeExtraArgBinding;


public function addRestElabCase
  input list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> inElabCases;

  output list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> outElabCases;
algorithm
  outElabCases := matchcontinue (inElabCases)
    local
      MatchingExp mexp;
      tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>> elabcase;
      list<tuple<MatchingExp, TypedIdents, TypedIdents, list<MMExp>>> restcases;

    case ( {} )
      then 
        ( { (REST_MATCH(),{},{},{}) } );
        
    case ( restcases as ( (mexp, _, _, _) :: _) )
      equation
        isAlwaysMatched(mexp);
      then 
        ( restcases );

    case ( (elabcase as (mexp, _, _, _)) :: restcases )
      equation
        //failure(isAlwaysMatched(mexp));
        restcases = addRestElabCase(restcases);      
      then 
        ( elabcase :: restcases );
            
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!addRestElabCase failed\n");
      then
        fail();
  end matchcontinue;           
end addRestElabCase;


public function isAlwaysMatched "function isAlwaysMatched
  Takes a MatchingExp and fails when it is not a rest case for sure (statically tested)."
  //no evaluation when there are two cases with  {} and (_ :: _) ... 
  input MatchingExp inMatchingExp;

algorithm
  _ := matchcontinue (inMatchingExp)
    local
      MatchingExp mexp;
      list<MatchingExp> mexplst;

    case ( BIND_AS_MATCH(matchingExp = mexp) )
      equation
        isAlwaysMatched(mexp);
      then ();
    
    case ( BIND_MATCH(_) )
      then ();
        
    case ( TUPLE_MATCH(tupleArgs = mexplst) )
      equation
        Util.listMap0(mexplst, isAlwaysMatched);
      then ();
        
    case ( REST_MATCH() )
      then ();
  end matchcontinue;           
end isAlwaysMatched;


public function adaptTextToString
  input tuple<MMExp, TypeSignature> inArgValue;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input TemplPackage inTplPackage; 

  output tuple<MMExp, TypeSignature> outArgValue;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outArgValue, outStmts, outLocals)
    := matchcontinue (inArgValue, inStmts, inLocals, inTplPackage)
    local
      list<MMExp> stmts;
      MMExp stmt, mmexp;    
      Ident strid;
      TypedIdents locals;
      tuple<MMExp, TypeSignature> argval;
      TypeSignature exptype;
      TemplPackage tplPackage;
      list<ASTDef> astdefs;           
    
    //every Text value is converted/rendered to string when it is a matching argument (match, condition and map exps)  
    //if it is needed to match against the Text structure, a simple deconstruction functions can be used,
    //one of type Text -> list<StringToken>, the second of type Text -> list<tuple<Tokens,BlockType>> for the stack
    //but who will need this, anyway ? (maybe for debugging of Susan it can help) 
    case ( (mmexp, exptype), stmts, locals,  TEMPL_PACKAGE(astDefs = astdefs))
      equation
        TEXT_TYPE() = deAliasedType(exptype, astdefs); 
        strid = "str_" +& intString(listLength(locals));
        locals = addLocalValue(strid, STRING_TYPE(), locals);          
        mmexp = mmExpToString(mmexp, TEXT_TYPE());
        stmt = MM_ASSIGN({strid}, mmexp);
      then 
        ( (MM_IDENT(IDENT(strid)), STRING_TYPE()), stmt::stmts,  locals);
        
   //other types are ok for the match statement
   case ( argval, stmts, locals, _)
      then 
        ( argval, stmts,  locals);
        
    //cannot happen
    case ( _, _, _, _ )
      equation
        Debug.fprint("failtrace", "-!!!adaptTextToString failed\n");
      then
        fail();
  end matchcontinue;           
end adaptTextToString;


public function elabCasesFromCondition
  input TypeSignature inArgType "deAliasedType"; 
  input Boolean inIsNot;
  input Option<MatchingExp> inRhsValue;
  input Expression inTrueBranch;
  input Option<Expression> inElseBranchOpt;
  input TemplPackage inTplPackage; 
  
  output list<tuple<MatchingExp,Expression>> outMCases;   
algorithm
  outMCases := matchcontinue (inArgType, inIsNot, inRhsValue, inTrueBranch, inElseBranchOpt, inTplPackage)
    local
      Boolean isnot;
      MatchingExp rhsMExp;
      Expression tbranch, ebranch;
      Option<Expression> ebranchOpt;
      TemplPackage tplPackage;
    
    // if  exp = mexp  then
    case ( _, false, SOME(rhsMExp), tbranch, ebranchOpt, tplPackage)
      equation
        ebranch = getElseBranch(ebranchOpt);
      then
        { (rhsMExp,tbranch), (REST_MATCH(),ebranch) };
        
    // if  exp <> mexp then
    case ( _, true, SOME(rhsMExp), tbranch, ebranchOpt, tplPackage)
      equation
        ebranch = getElseBranch(ebranchOpt);
      then
        { (rhsMExp,ebranch), (REST_MATCH(),tbranch) };
    
    // List ... if valLst then / if not valLst then
    case ( LIST_TYPE(_), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, LIST_MATCH({}), tbranch, ebranchOpt);
    // Option 
    case ( OPTION_TYPE(_), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, NONE_MATCH(), tbranch, ebranchOpt);
    // String and Text (auto-converted to String)
    case ( STRING_TYPE(), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, STRING_MATCH(""), tbranch, ebranchOpt);
    //Integer
    case ( INTEGER_TYPE(), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("0", INTEGER_TYPE()), tbranch, ebranchOpt);
    //Real
    case ( REAL_TYPE(), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("0.0", REAL_TYPE()), tbranch, ebranchOpt);
    //Boolean
    case ( BOOLEAN_TYPE(), isnot, NONE, tbranch, ebranchOpt, tplPackage)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("false", BOOLEAN_TYPE()), tbranch, ebranchOpt);
    
    case (_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!elabCasesFromCondition failed\n");
      then
        fail();
  end matchcontinue;           
end elabCasesFromCondition;


public function casesForTrueFalseCondition
  input Boolean inIsNot;
  input MatchingExp inNotMatchingExp;
  input Expression inTrueBranch;
  input Option<Expression> inElseBranchOpt;
  
  output list<tuple<MatchingExp,Expression>> outMCases;   
algorithm
  outMCases := matchcontinue (inIsNot, inNotMatchingExp, inTrueBranch, inElseBranchOpt)
    local
      MatchingExp notmexp;
      Boolean isnot;
      Expression tbranch, ebranch;
      Option<Expression> ebranchOpt;
    
    // true condition, e.g.  if exp then ...
    case ( false, notmexp, tbranch, ebranchOpt)
      equation
        ebranch = getElseBranch(ebranchOpt);
      then
        { (notmexp,ebranch), (REST_MATCH(),tbranch) };
    
    // not condition, e.g.  if not exp then ...
    case ( true, notmexp, tbranch, ebranchOpt)
      equation
        ebranch = getElseBranch(ebranchOpt);
      then
        { (notmexp,tbranch), (REST_MATCH(),ebranch) };
    
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!casesForTrueFalseCondition failed\n");
      then
        fail();
  end matchcontinue;           
end casesForTrueFalseCondition;


public function getElseBranch
  input Option<Expression> inElseBranchOpt;
  output Expression outElseBranch;   
algorithm
  outElseBranch := matchcontinue inElseBranchOpt
    local
      Expression ebranch;
      
    case ( SOME(ebranch) ) then  ebranch;
    
    //empty map-argument list will generate no code
    case ( NONE )          then  MAP_ARG_LIST({});
    
    //cannot happen
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!getElseBranch failed\n");
      then
        fail();
  end matchcontinue;           
end getElseBranch;


public function resolveBoundPath
  input PathIdent inPath;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage; 
  
  output MMExp outMMExp;
  output TypeSignature outType;
  output ScopeEnv outScopeEnv;
algorithm
  (outMMExp, outType, outScopeEnv) := matchcontinue (inPath, inScopeEnv, inTplPackage)
    local
      MatchingExp mexp;
      
      PathIdent path, itpath, typepckg, encpath;
      Ident ident, locId, typeident, itname;
      TypeSignature idtype, mtype;
      TypedIdents extargs;
      Scope scope;
      ScopeEnv scEnv;
      TemplPackage tplPackage;
      list<ASTDef> astDefs;
      TemplateDef tpldef;
      list<tuple<Ident,TemplateDef>> tpldefs;
      Option<PathIdent> typepckgOpt;
      TypeInfo typeinfo;
      MMExp mmexp;
      StringToken st;
      String reason;         
    
    //local scope (Text variables)  
    case (IDENT(ident = ident), 
          scEnv as (LOCAL_SCOPE(ident = locId, idType = idtype) :: _), _)
      equation
        ident = encodeIdent(ident);
        equality(ident = locId);
      then
        (MM_IDENT(IDENT(ident)), idtype, scEnv);
    
    //local scope failed - look up in the immediate scope 
    case (path,  
          (scope as LOCAL_SCOPE(ident = _)) :: scEnv, tplPackage)
      equation
        // ident = encodeIdent(ident);
        // failure (equality(ident = locId));
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
      then
        (mmexp, idtype, scope :: scEnv);
    
    //plain 'it'
    case (IDENT(ident = "it"), scEnv, _  )
      equation
        (ident, idtype, scEnv) = resolveIt(scEnv);
      then
        (MM_IDENT(IDENT(ident)), idtype, scEnv);
        
    // 'it.path' in a function scope is error 
    //-> fail ... must be checked here to prevent trying looking up the scope that can be possibly successful, but semantically wrong ('it' cannot skip its scope up) 
    case ( path as PATH_IDENT(ident = "it"), 
           scEnv as (FUN_SCOPE(_) :: _), _ )
      equation
        reason = "Unresolved path after 'it' - cannot lookup path '" +& pathIdentString(path) +& "'in a function scope. A dot path can be used only in a record match case scope.";
        idtype = UNRESOLVED_TYPE(reason);
        ident  = "it" +& encodePath(path); //makes "it" a head and all parts from the path separated with "_" or "_0"                              
      then
        (MM_IDENT(IDENT(ident)), idtype, scEnv);
    
    // 'it.path' in a case scope
    case ( path as PATH_IDENT(ident = "it", path = itpath), 
          (CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs,
             itName = itname) :: scEnv), TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        ident  = "it" +& encodePath(path); //makes "it" a head and all parts from the path separated with "_" or "_0"  
        ( idtype, mexp ) = lookupUpdateMExpDotPath(ident, itpath, mexp, mtype, astDefs);
      then
        (MM_IDENT(IDENT(ident)), idtype, CASE_SCOPE( mexp, mtype, extargs, itname) :: scEnv);
    
    //try "implicit" record lookup ~ [it.]path
    //now, the implicit scoped fields can hide upper idents from upper scope when there is an overlap
    //TODO: a warning when the hidening has happen;
    //TODO: also warning when hidening of a binding that has the same name as a field but it is not the field(should it be hidden, too?, ... not now a name conflict would be there ...) 
    case (path, 
          (CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs,
             itName = itname) :: scEnv), TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (ident, encpath) = encodePathIdent(path);
        //prevent from hidening an immediate case binding
        //if not failure, the next resolvePathInScopeEnv will catch it
        failure( (_,_) = lookupUpdateMatchingExp(ident, encpath, mexp, mtype, astDefs) );
        (idtype, mexp) = lookupUpdateMExpDotPath(ident, path, mexp, mtype, astDefs);
        failure(UNRESOLVED_TYPE(_) = idtype);
        Debug.fprint("failtrace","\n [it.]path for '" +& pathIdentString(path) +& "' : "
                    +& typeSignatureString(idtype) +& " \n");
        
      then
        ( MM_IDENT(IDENT(ident)), idtype, CASE_SCOPE( mexp, mtype, extargs, itname) :: scEnv);
    
    // look up the scope ?
    case (path, scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (ident, path) = encodePathIdent(path);
        //Debug.fprint("failtrace","\n encoded path = " +& pathIdentString(path) +& ", ident = "+& ident +& "\n");
        (ident, idtype, scEnv) = resolvePathInScopeEnv(ident, path, scEnv, astDefs);
      then
        (MM_IDENT(IDENT(ident)), idtype, scEnv);
    
    // a defined constant ?
    case (IDENT(ident = ident), scEnv, TEMPL_PACKAGE(templateDefs = tpldefs)  )
      equation
        tpldef = lookupTupleList(tpldefs, ident);
        (mmexp, idtype) = makeMMExpFromTemplateConstant(tpldef, ident);
      then
        (mmexp, idtype, scEnv);
    
    // an imported constant ?
    case (path, scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(path);
        (typepckg, TI_CONST_TYPE(constType = idtype)) 
          = getTypeInfo(typepckgOpt, typeident, astDefs);
        path = makePathIdent(typepckg, typeident);
      then
        (MM_IDENT(path), idtype, scEnv);
    
    
    
    
    
    // ** failure reasons ***
    
    // an imported symbol other than constant ? 
    case (path, scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(path);
        (typepckg, _) 
          = getTypeInfo(typepckgOpt, typeident, astDefs);
        reason = "Unresolved path - imported symbol '" +& pathIdentString(path) +& "' other than a constant used in a value context (missing parenthesis ?).";
        idtype = UNRESOLVED_TYPE(reason);
        path = makePathIdent(typepckg, typeident);
      then
        ( MM_IDENT(path), idtype, scEnv);
    
    // imlicit record lookup failed
    case (path,
          (scope as CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs)) :: scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (ident, _) = encodePathIdent(path);
        (UNRESOLVED_TYPE(reason), mexp) = lookupUpdateMExpDotPath(ident, path, mexp, mtype, astDefs);
        reason = "Unresolved path '" +& pathIdentString(path) +& "'- after try of imlicit case lookup got:\n   " +& reason;
        idtype = UNRESOLVED_TYPE(reason);
      then
        ( MM_IDENT(IDENT(ident)), idtype, (scope :: scEnv));
    
    
    // all the rest  
    case (path, scEnv, _  )
      equation
        reason = "Unresolved path '" +& pathIdentString(path) +& "'.";
        idtype = UNRESOLVED_TYPE(reason);
      then
        ( MM_IDENT(path), idtype, scEnv);
            
    //should not ever happen
    case ( _, _, _ )
      equation
        Debug.fprint("failtrace", "-!!!resolveBoundPath failed\n");
      then
        fail();
  end matchcontinue;           
end resolveBoundPath;


public function ensureResolvedType
  input PathIdent inPath;
  input TypeSignature inType;
  input String inUnresolvedMsg;

algorithm
  _ := matchcontinue (inPath, inType, inUnresolvedMsg)
    local
      PathIdent path;
      String reason, msg;           
      TypeSignature ts;
      
    case ( _, ts, _)
      equation
        failure(UNRESOLVED_TYPE(_) = ts);
      then
        ();
    
    case ( path, UNRESOLVED_TYPE(reason), msg)
      equation
        Debug.fprint("failtrace", msg +& " unresolved path '" +& pathIdentString(path) +& "', reason = '" +& reason +& "'.\n");
      then
        fail();
      end matchcontinue;           
end ensureResolvedType;


public function ensureNotUsingTheSameText
  input PathIdent inPath;
  input MMExp inMMExpIdent;
  input TypeSignature inType;
  input Ident inText;
  output Boolean isOK;
algorithm
  isOK := matchcontinue (inPath, inMMExpIdent, inType, inText)
    local
      PathIdent path;
      Ident txtIdent, intxt;
    
    case ( path, MM_IDENT(IDENT(txtIdent)), TEXT_TYPE(), intxt)
      equation
        equality(txtIdent = intxt);
        Debug.fprint("failtrace", "Error - trying to use '" +& pathIdentString(path) +& "' Text recursively during self evaluation. Use an additional Text variable if a self addition/duplication is needed, like  # b = a # a += 'pref<b>' ... \n");
      then
        false;
        
    case ( _, _, _, _) then true;
    
  end matchcontinue;           
end ensureNotUsingTheSameText;


public function makeMMExpFromTemplateConstant
  input TemplateDef inTplDef;
  input Ident inTemplIdent;
  
  output MMExp outMMExp;
  output TypeSignature outConstType;  
algorithm
  (outMMExp, outConstType) := matchcontinue (inTplDef, inTemplIdent)
    local
      MatchingExp mexp;
      
      PathIdent path;
      Ident ident;
      TypeSignature idtype, lt;
      Scope scope;
      ScopeEnv scEnv;
      TemplPackage tplPackage;
      list<ASTDef> astdefs;
      TemplateDef tpldef;
      list<tuple<Ident,TemplateDef>> tpldefs;
      StringToken st;
      String litstr, reason;           
      
    //string constants are of StringToken type and does not involve a type conversion, use them through idents 
    case ( STR_TOKEN_DEF(value = st), ident)
      equation
        ident = "c_" +& ident; //no encoding needed, just prefix, it is a constant
      then
        (MM_IDENT(IDENT(ident)), STRING_TOKEN_TYPE());
        
    //literal constants of primitive types besides string : INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE
    //make them inline  
    case ( LITERAL_DEF(value = litstr, litType = lt), _)
      then
        (MM_LITERAL(litstr), lt);
    
    //Error - a template in a value context ... maybe, this can be with lower priority, after of trying of imlicit record lookup
    case ( TEMPLATE_DEF(_,_,_,_), ident)
      equation
        reason = "Unresolved identifier - the template '" +& ident +& "'in a value context found (missing parenthesis ?) .";
        idtype = UNRESOLVED_TYPE(reason);
        //ident = encodeIdent(ident);
      then
        ( MM_IDENT(IDENT(ident)), idtype);
                    
    //should not ever happen
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!!makeMMExpFromTemplateConstant failed\n");
      then
        fail();
  end matchcontinue;           
end makeMMExpFromTemplateConstant;


public function resolveIt
  input ScopeEnv inScopeEnv;
  
  output Ident outIdent;
  output TypeSignature outType;
  output ScopeEnv outScopeEnv;
algorithm
  (outIdent, outType, outScopeEnv) := matchcontinue (inScopeEnv)
    local
      MatchingExp mexp;
      Ident ident, itname;
      TypeSignature idtype;
      TypedIdents extargs;
      Scope scope;
      ScopeEnv scEnv;
      list<ASTDef> astDefs;
      
    //look up in the immediate scope
    case ( (scope as LOCAL_SCOPE(ident = _)) :: scEnv )
      equation
        (itname, idtype, scEnv) = resolveIt(scEnv);
      then
        ( itname, idtype, scope :: scEnv);
    
    case ( scEnv as (FUN_SCOPE(
                      args = {}
                     ) :: _) )
      then
        ( "it", UNRESOLVED_TYPE(
            "Unresolved 'it' - cannot choose first argument as implicit, function with no arguments."),
          scEnv );
    
    case ( scEnv as (FUN_SCOPE(
                      args = (ident, idtype) :: _
                    ) :: _) )
      then
        (ident, idtype, scEnv);
        
    case ( scEnv as (CASE_SCOPE(
                      mExp = BIND_AS_MATCH(bindIdent = ident), 
                      mType = idtype) :: _)) 
      then
        (ident, idtype, scEnv);
    
    case ( scEnv as (CASE_SCOPE(
                      mExp = BIND_MATCH(bindIdent = ident), 
                      mType = idtype) :: _) ) 
      then
        (ident, idtype, scEnv);
    
    //replace a wild match with the itName
    case ( CASE_SCOPE(
             mExp = REST_MATCH(), 
             mType = idtype, 
             extArgs = extargs,
             itName = itname) :: scEnv ) 
      then
        (itname, idtype, CASE_SCOPE(
                          BIND_MATCH(itname), 
                          idtype, 
                          extargs,
                          itname) :: scEnv);
    
    //all the rest cases creates an "as" binding of itName
    case ( CASE_SCOPE(
             mExp = mexp, 
             mType = idtype, 
             extArgs = extargs,
             itName = itname) :: scEnv) 
      then
        (itname, idtype, CASE_SCOPE(
                         BIND_AS_MATCH(itname, mexp), 
                         idtype, 
                         extargs,
                         itname) :: scEnv);
            
    //should not ever happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!resolveIt failed\n");
      then
        fail();
  end matchcontinue;           
end resolveIt;


public function resolvePathInScopeEnv
  input Ident inIdent;
  input PathIdent inPath;
  input ScopeEnv inScopeEnv;
  input list<ASTDef> inASTDefs; 
  
  output Ident outIdent;
  output TypeSignature outType;
  output ScopeEnv outScopeEnv;
algorithm
  (outIdent, outType, outScopeEnv) 
  := matchcontinue (inIdent, inPath, inScopeEnv, inASTDefs)
    local
      MatchingExp mexp;
      TypedIdents extargs, fargs;
      PathIdent path;
      Ident ident, itname, locId;
      TypeSignature idtype, mtype;
      Scope scope;
      ScopeEnv scEnv, restEnv;
      TemplPackage tplPackage;
      list<ASTDef> astdefs;            
      
    //local scope (Text variables)  
    case (ident, _, 
          scEnv as (LOCAL_SCOPE(ident = locId, idType = idtype) :: _), _)
      equation
        equality(ident = locId);
      then
        (ident, idtype, scEnv);
    
    //local scope failed - look up
    case (ident, path,  
          (scope as LOCAL_SCOPE(ident = _)) :: restEnv, astdefs)
      equation
        // failure (equality(ident = locId));
        (ident, idtype, restEnv) = resolvePathInScopeEnv(ident, path, restEnv, astdefs);        
      then
        (ident, idtype, scope :: restEnv);
        
    //already in the function scope
    case ( ident, _ , 
           scEnv as (FUN_SCOPE(args = fargs) :: _ ), _  )
      equation
        idtype = lookupTupleList(fargs, ident);        
      then
        (ident, idtype, scEnv);
        
    //not in the function scope, look up
    case ( ident, path, 
           FUN_SCOPE(args = fargs) :: restEnv, astdefs  )
      equation
        //failure(_ = lookupTupleList(fargs, ident));
        (ident, idtype, restEnv) = resolvePathInScopeEnv(ident, path, restEnv, astdefs);
        //a different ident could be returned, update only when not present 
        fargs = updateTupleList(fargs, (ident, idtype));
      then
        (ident, idtype, FUN_SCOPE(fargs) :: restEnv);
    
    //bound in the matching expression, update it with the ident if needed
    case ( ident, path, 
           CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs,
             itName = itname) :: restEnv, astdefs  )
      equation
        (idtype, mexp) = lookupUpdateMatchingExp(ident, path, mexp, mtype, astdefs);        
      then
        (ident, idtype, CASE_SCOPE(mexp, mtype, extargs, itname) :: restEnv);
    
    //ident refers to original name of 'it'
    //avoid to look up --> resolve the actual 'it'
    case ( ident, path, 
           scEnv as (CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs,
             itName = itname) ::_ ), astdefs  )
      equation
        equality(ident = itname);
        (ident, idtype, scEnv) = resolveIt(scEnv);        
      then
        (ident, idtype, scEnv);
    
    //already in the extra args
    case ( ident, _, 
           scEnv as (CASE_SCOPE(extArgs = extargs) :: _ ), _  )
      equation
        idtype = lookupTupleList(extargs, ident);        
      then
        (ident, idtype, scEnv);
    
    //not in the case scope, look up
    case ( ident, path, 
           CASE_SCOPE(
             mExp = mexp, 
             mType = mtype, 
             extArgs = extargs,
             itName = itname) :: restEnv, astdefs )
      equation
        //failure( (_,_) = lookupUpdateMatchingExp(ident, path, mexp, mtype, astdefs));
        //failure( _ = lookupTupleList(extargs, ident) );
        (ident, idtype, restEnv) = resolvePathInScopeEnv(ident, path, restEnv, astdefs);
        extargs = updateTupleList(extargs, (ident, idtype));        
      then
        (ident, idtype, CASE_SCOPE(mexp, mtype, extargs, itname) :: restEnv);
    
    // can normally fail for template or external constants
    //case ( ident, _, _, _ )
    //  equation
    //    Debug.fprint("failtrace", "-resolvePathInScopeEnv failed for ident '" +& ident +& "'.\n");
    //  then
    //    fail();
  end matchcontinue;           
end resolvePathInScopeEnv;


public function releaseImmediateLocalScope
  input ScopeEnv inScopeEnv;
  output ScopeEnv outScopeEnv;
algorithm
  (outScopeEnv) := matchcontinue (inScopeEnv)
    local
      ScopeEnv scEnv;
      
    case ( LOCAL_SCOPE(ident = _) :: scEnv )
      then
        releaseImmediateLocalScope(scEnv);
    
    case ( scEnv )
      then
        scEnv;
        
  end matchcontinue;           
end releaseImmediateLocalScope;


public function lookupUpdateMatchingExp 
  input Ident inIdent;
  input PathIdent inPathIdent;
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;
  
  output TypeSignature outValueType;
  output MatchingExp outMatchingExp;
algorithm 
  (outValueType, outMatchingExp) 
    := matchcontinue (inIdent, inPathIdent, inMatchingExp, inMType, inASTDefs)
    local
      Ident inid, id, bid;
      PathIdent path, tagpath, oIdent;
      TypeSignature mtype, otype, valtype;
      list<TypeSignature> mtypeLst;
      list<ASTDef> astDefs;
      
      list<TypeSignature> otLst;
      String bid, id, reason;
      PathIdent tagn;
      list<tuple<String, MatchingExp>> fms;
      MatchingExp inmexp, mexp, restmexp;
      list<MatchingExp> mexpLst;
      TypedIdents fields;
      list<String, TypedIdents> rts;
    
    
    case ( _, IDENT(ident = id), 
          inmexp as BIND_AS_MATCH(
                      bindIdent = bid ), mtype, _ )
      equation
        equality(id = bid);
      then 
        ( mtype, inmexp );
    
    case ( inid, PATH_IDENT(ident = id, path = path ),
           BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs )
      equation
        equality(id = bid);
        ( valtype, mexp ) = lookupUpdateMExpDotPath(inid, path, mexp, mtype, astDefs); 
      then 
        ( valtype, BIND_AS_MATCH(bid, mexp) );
    
    case ( inid, path, 
           BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs )
      equation
        //failure(equality(id = bid));
        ( valtype, mexp ) = lookupUpdateMatchingExp(inid, path, mexp, mtype, astDefs);
      then 
        ( valtype, BIND_AS_MATCH(bid, mexp) );
    
    
    case ( _, IDENT(ident = id), 
          inmexp as BIND_MATCH(
                      bindIdent = bid ), mtype, _ )
      equation
        equality(id = bid);
      then 
        ( mtype, inmexp );        
    
    case ( inid, PATH_IDENT(ident = id, path = path ),
           inmexp as BIND_MATCH(
             bindIdent = bid ), mtype, astDefs )
      equation
        equality(id = bid);
        reason = "Unresolved path '" +& inid +& "' after first dot - only the first part '" +& id +& "' resolved as a bind match.";
        valtype = UNRESOLVED_TYPE(reason); 
      then 
        (valtype , inmexp );
    
    
    case ( inid, path, 
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields,_) = getFieldsForRecord(mtype, tagpath, astDefs);
        ( valtype, fms ) = lookupUpdateMExpRecord(inid, path, fms, fields, astDefs);
      then 
        ( valtype, RECORD_MATCH(tagpath, fms) );
    
    case ( inid, path, 
           SOME_MATCH(
             value = mexp ), mtype, astDefs )
      equation
        OPTION_TYPE(ofType = mtype) = deAliasedType(mtype, astDefs);
        ( valtype, mexp ) = lookupUpdateMatchingExp(inid, path, mexp, mtype, astDefs);
      then 
        ( valtype, SOME_MATCH(mexp) );
    
    case ( inid, path, 
           TUPLE_MATCH(
             tupleArgs = mexpLst ), mtype, astDefs )
      equation
        TUPLE_TYPE(ofTypes = mtypeLst) = deAliasedType(mtype, astDefs);
        ( valtype, mexpLst ) = lookupUpdateMExpList(inid, path, mexpLst, mtypeLst, astDefs);
      then 
        ( valtype, TUPLE_MATCH(mexpLst) );
        
    case ( inid, path, 
           LIST_MATCH(
             listElts = mexpLst ), mtype, astDefs )
      equation
        LIST_TYPE(ofType = mtype) = deAliasedType(mtype, astDefs);
        mtypeLst = Util.listFill(mtype, listLength(mexpLst));
        ( valtype, mexpLst ) = lookupUpdateMExpList(inid, path, mexpLst, mtypeLst, astDefs);
      then 
        ( valtype, LIST_MATCH(mexpLst) );
    
    case ( inid, path, 
           LIST_CONS_MATCH(
             head = mexp,
             rest = restmexp ), mtype, astDefs )
      equation
        LIST_TYPE(ofType = otype) = deAliasedType(mtype, astDefs);
        ( valtype, {mexp, restmexp} ) = lookupUpdateMExpList(inid, path, { mexp, restmexp}, {otype, mtype}, astDefs);
      then 
        ( valtype, LIST_CONS_MATCH(mexp, restmexp) );
    
    
    //otherwise fail     
        
  end matchcontinue;
end lookupUpdateMatchingExp;


public function lookupUpdateMExpDotPath 
  input Ident inIdent;
  input PathIdent inPathIdent;
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;
  
  output TypeSignature outValueType;
  output MatchingExp outMatchingExp;
algorithm 
  (outValueType, outMatchingExp) 
    := matchcontinue (inIdent, inPathIdent, inMatchingExp, inMType, inASTDefs)
    local
      Ident inid, id, bid, ident;
      PathIdent path, tagpath;
      TypeSignature mtype, valtype;
      list<ASTDef> astDefs;
      
      list<tuple<String, MatchingExp>> fms;
      MatchingExp mexp;
      TypedIdents fields;
      String reason;
    
    case ( inid, path, 
           BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs )
      equation
        ( valtype, mexp ) = lookupUpdateMExpDotPath(inid, path, mexp, mtype, astDefs);
      then 
        ( valtype, BIND_AS_MATCH(bid, mexp) );
    
    case ( inid, IDENT(ident = id), 
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, _) = getFieldsForRecord(mtype, tagpath, astDefs); // this should not fail as we have type-checked the matching expression
        valtype = lookupTupleList(fields, id);
        fms = updateFieldMatchingsForField(inid, id, fms);
      then 
        ( valtype, RECORD_MATCH(tagpath, fms) );
    
    case ( inid, IDENT(ident = id), 
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields,tagpath) = getFieldsForRecord(mtype, tagpath, astDefs); // this should not fail as we have type-checked the matching expression
        failure( _ = lookupTupleList(fields, id));
        reason = "Unresolved path - failed in lookup for field '" +& id +& "' at the end of (encoded) path '" +& inid 
                 +& "', no such field in '" +& pathIdentString(tagpath) +& "' record fields.\n";
        valtype = UNRESOLVED_TYPE(reason);
      then 
        ( valtype, RECORD_MATCH(tagpath, fms) );
    
    case ( inid, PATH_IDENT(ident = id, path = path), 
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields,_) = getFieldsForRecord(mtype, tagpath, astDefs); // this should not fail as we have type-checked the matching expression
        mtype = lookupTupleList(fields, id);
        ( valtype, fms ) = lookupUpdateMExpDotPathRecord(inid, id, path, fms, mtype, astDefs);
      then 
        ( valtype, RECORD_MATCH(tagpath, fms) );
    
    case ( inid, PATH_IDENT(ident = id, path = path), 
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs); // this should not fail as we have type-checked the matching expression
        failure( _ = lookupTupleList(fields, id));
        reason = "Unresolved path - failed in lookup for field '" +& id +& "' inside the (encoded) path '" +& inid 
              +& "', no such field in '" +& pathIdentString(tagpath) +& "' record fields.\n";
        valtype = UNRESOLVED_TYPE( reason );
      then 
        ( valtype, RECORD_MATCH(tagpath, fms) );
    
    // here we can insert an implicit resolution for pure record types (not embedded in a union)
    // just check the type if it is a pure record type and then expand the mexp with the record match
    case ( inid, path, mexp, mtype, astDefs )
      equation
        reason = "Unresolved path (encoded) '" +& inid 
                 +& "', cannot follow the rest path '" +& pathIdentString(path) +& "', no record match available to look down the path."; 
        valtype = UNRESOLVED_TYPE(reason);
      then 
        ( valtype, mexp );
    
    
    //should not ever happen
    case ( ident, _, _, _, _)
      equation
        Debug.fprint("failtrace", "-!!!lookupUpdateMExpRecord failed for ident '" +& ident +& "'.\n");
      then
        fail();
        
  end matchcontinue;
end lookupUpdateMExpDotPath;


public function updateFieldMatchingsForField 
  input Ident inIdent;
  input Ident inField;
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  
  output list<tuple<Ident, MatchingExp>> outFieldMatchings;
algorithm 
  (outFieldMatchings) 
    := matchcontinue (inIdent, inField, inFieldMatchings)
    local
      Ident inid, fieldid, ident;
      PathIdent path;
      TypeSignature mtype, valtype;
      list<ASTDef> astDefs;
      
      list<tuple<Ident, MatchingExp>> fms;
      tuple<Ident, MatchingExp> fm;
      MatchingExp mexp;
      TypedIdents fields;
      
    case ( inid, fieldid, {} )
      then 
        ( {(fieldid, BIND_MATCH(inid))} );
        
    case ( inid, fieldid,(ident, mexp) :: fms)
      equation
        equality(fieldid = ident);
        mexp = makeBindAs(inid, mexp); //cannot fail   
      then 
        ( (fieldid, mexp) :: fms );
    
    case ( inid, fieldid, fm :: fms )
      equation
        //failure(equation(fieldid = ident));
        fms = updateFieldMatchingsForField(inid, fieldid, fms);
      then 
        ( fm :: fms );
    
    //should not ever happen
    case ( _, _, _)
      equation
        Debug.fprint("failtrace", "-!!!updateFieldMatchingsForField failed.\n");
      then
        fail();
        
  end matchcontinue;
end updateFieldMatchingsForField;


public function makeBindAs 
  input Ident inIdent;
  input MatchingExp inMExp;
  
  output MatchingExp outMExp;
algorithm 
  (outMExp) 
    := matchcontinue (inIdent, inMExp)
    local
      Ident inid, bid;
      MatchingExp mexp, inmexp;
      
    case ( inid, inmexp as BIND_AS_MATCH(
                             bindIdent = bid,
                             matchingExp = mexp ) )
      equation
        equality(inid = bid);
      then 
        inmexp;
    
    case ( inid, BIND_AS_MATCH(
                   bindIdent = bid,
                   matchingExp = mexp ) )
      equation
        //failure(equality(inid = bid));
        mexp = makeBindAs(inid, mexp); //we should do this to handle multiple path ambiguity ... i.e. when mexpr is  (c as REC(fld = a as REC2(fld2 = b)))  and  c.fld.fl2, a.fld2 and b are used simultanosly, then we will get (c as REC(fld = a as REC2(fld2 = b as c_fld_fld2 as a_fld)))   
      then 
        BIND_AS_MATCH(bid, mexp);

    case ( inid, inmexp as BIND_MATCH(
                             bindIdent = bid ) )
      equation
        equality(inid = bid);
      then 
        inmexp;
    
    /* //can be here to "optimize" the "_"
    case ( inid, REST_MATCH())
      then 
        BIND_MATCH(inid);    
    */
    case ( inid, mexp )
      then 
        BIND_AS_MATCH(inid, mexp);    
    
    
    //should not ever happen
    case ( _, _)
      equation
        Debug.fprint("failtrace", "-!!!makeBindAs failed.\n");
      then
        fail();
        
  end matchcontinue;
end makeBindAs;


public function lookupUpdateMExpDotPathRecord 
  input Ident inIdent;
  input Ident inField;
  input PathIdent inPathIdent;
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;
  
  output TypeSignature outValueType;
  output list<tuple<Ident, MatchingExp>> outFieldMatchings;
algorithm 
  (outValueType, outFieldMatchings) 
    := matchcontinue (inIdent, inField, inPathIdent, inFieldMatchings, inMType, inASTDefs)
    local
      Ident inid, fieldid, ident;
      PathIdent path;
      TypeSignature mtype, valtype;
      list<ASTDef> astDefs;
      
      list<tuple<Ident, MatchingExp>> fms;
      tuple<Ident, MatchingExp> fm;
      MatchingExp mexp;
      String reason;
      
    case ( inid, fieldid, path, {}, mtype, astDefs )
      equation
        reason = "Unresolved path '" +& inid +& "', cannot follow the path after a dot, no record match available to look down the path after '" +& fieldid +& "'.\n"; 
        valtype = UNRESOLVED_TYPE(reason);
      then 
        ( valtype, {} );
    
    case ( inid, fieldid, path, (ident, mexp) :: fms, mtype, astDefs )
      equation
        equality(fieldid = ident);
         ( valtype, mexp ) = lookupUpdateMExpDotPath(inid, path, mexp, mtype, astDefs);        
      then 
        ( valtype, (ident, mexp) :: fms );
    
    case ( inid, fieldid, path, fm :: fms, mtype, astDefs )
      equation
        //failure( equality(fieldid = ident) );
        ( valtype, fms ) = lookupUpdateMExpDotPathRecord(inid, fieldid, path, fms, mtype, astDefs);        
      then 
        ( valtype, fm :: fms );
    
    //shold not ever happen
    case ( inid, _, _, _, _, _)
      equation
        Debug.fprint("failtrace", "-!!!lookupUpdateMExpDotPathRecord failed for ident '" +& inid +& "'.\n");
      then
        fail();
        
  end matchcontinue;
end lookupUpdateMExpDotPathRecord;


public function lookupUpdateMExpRecord 
  input Ident inIdent;
  input PathIdent inPathIdent;
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  input TypedIdents inFields;
  input list<ASTDef> inASTDefs;
  
  output TypeSignature outValueType;
  output list<tuple<Ident, MatchingExp>> outFieldMatchings;
algorithm 
  (outValueType, outMatchingExp) 
    := matchcontinue (inIdent, inPathIdent, inFieldMatchings, inFields, inASTDefs)
    local
      Ident inid, ident;
      PathIdent path;
      TypeSignature mtype, valtype;
      list<ASTDef> astDefs;
      
      list<tuple<Ident, MatchingExp>> fms;
      tuple<Ident, MatchingExp> fm;
      MatchingExp mexp;
      TypedIdents fields;
      
    //case ( _, _, {}, _, _)
    //  then 
    //    fail();
        
    case ( inid, path, (ident, mexp) :: fms, fields, astDefs )
      equation
        mtype = lookupTupleList(fields, ident);
        ( valtype, mexp ) = lookupUpdateMatchingExp(inid, path, mexp, mtype, astDefs);        
      then 
        ( valtype, (ident, mexp) :: fms );
    
    case ( inid, path, (ident, mexp) :: fms, fields, astDefs )
      equation
        failure( _ = lookupTupleList(fields, ident) );
        Debug.fprint("failtrace", "-Error!!!lookupUpdateMExpRecord failed in lookup for field (type) ident '" +& ident +& "'.\n");
      then 
        fail(); //?? will fail the whole lookupUpdateMExpRecord or retry the next case ?
    
    case ( inid, path, fm :: fms, fields, astDefs )
      equation
        ( valtype, fms ) = lookupUpdateMExpRecord(inid, path, fms, fields, astDefs);        
      then 
        ( valtype, fm :: fms );
    
  end matchcontinue;
end lookupUpdateMExpRecord;


public function lookupUpdateMExpList 
  input Ident inIdent;
  input PathIdent inPathIdent;
  input list<MatchingExp> inMExpList;
  input list<TypeSignature> inMTypeList;
  input list<ASTDef> inASTDefs;
  
  output TypeSignature outValueType;
  output list<MatchingExp> outMExpList;
algorithm 
  (outValueType, outMExpList) 
    := matchcontinue (inIdent, inPathIdent, inMExpList, inMTypeList, inASTDefs)
    local
      Ident inid;
      PathIdent path;
      TypeSignature mtype, valtype;
      list<TypeSignature> mtypeLst;
      list<ASTDef> astDefs;
      MatchingExp mexp;
      list<MatchingExp> mexpLst;

    //case ( _, _, {}, _, _ )
    //  then 
    //    fail();
    
    case ( inid, path, (mexp :: mexpLst), (mtype :: mtypeLst), astDefs )
      equation
        ( valtype, mexp ) = lookupUpdateMatchingExp(inid, path, mexp, mtype, astDefs);        
      then 
        ( valtype, (mexp :: mexpLst) );
    
    case ( inid, path, (mexp :: mexpLst), (mtype :: mtypeLst), astDefs )
      equation
        ( valtype, mexpLst ) = lookupUpdateMExpList(inid, path, mexpLst, mtypeLst, astDefs);        
      then 
        ( valtype, (mexp :: mexpLst) );
    
  end matchcontinue;
end lookupUpdateMExpList;


public function getFieldsForRecord 
  input TypeSignature inMType;
  input PathIdent inTagPath;
  input list<ASTDef> inASTDefs;
  
  output TypedIdents outFields;
  output PathIdent inFullyQualifiedTagPath;
algorithm 
  (outFields, inFullyQualifiedTagPath) 
    := matchcontinue (inMType, inTagPath, inASTDefs)
    local
      TypeSignature mtype;
      Ident typeident, tagident;
      PathIdent typepath, tagpath, typepckg;
      Option<PathIdent> typepckgOpt, tagpckgOpt;
      TypeInfo typeinfo;
      list<ASTDef> astDefs;
      TypedIdents fields;
    
    case ( NAMED_TYPE(name = typepath), tagpath, astDefs )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (typepckg, typeinfo) = getTypeInfo(typepckgOpt, typeident, astDefs);
        (tagpckgOpt, tagident) = splitPackageAndIdent(tagpath);
        checkPackageOpt(typepckg, tagpckgOpt);
        fields = getFields(tagident, typeinfo, typeident);
        typepath = makePathIdent(typepckg, tagident);
      then 
        (fields, typepath);
    
    case ( mtype as NAMED_TYPE(name = _), tagpath, _)
      equation
        Debug.fprint("failtrace", "Error - (getFieldsForRecord) for case tag '" +& pathIdentString(tagpath) +& "' failed for reason above.\n");
      then 
        fail();
        
    case ( mtype, tagpath, _)
      equation
        //failure(NAMED_TYPE(_) = mtype);
        Debug.fprint("failtrace", "Error - for case tag '" +& pathIdentString(tagpath) +& "' the input type is not a NAME_TYPE hence not a union/record type.\n");
      then
        fail();         
    
    
    
  end matchcontinue;
end getFieldsForRecord;


public function splitPackageAndIdent 
  input PathIdent inTypePathIdent;
  
  output Option<PathIdent> outPackagePath;
  output Ident outTypeIdent;
algorithm 
  (outPackagePath, outTypeIdent) := matchcontinue (inTypePathIdent)
    local
      TypeSignature mtype;
      Ident typeident, pckgident, pckgident2;
      PathIdent path, typepath, typepckg;
      Option<PathIdent> typepckgOpt, tagpckgOpt;
      TypeInfo typeinfo;
      list<ASTDef> astDefs;
      TypedIdents fields;
    
    case ( IDENT(ident = typeident) )
      then 
        ( NONE, typeident );
    
    case ( PATH_IDENT(ident = pckgident, path = IDENT(ident = typeident) ) )
      then 
        ( SOME(IDENT(pckgident)), typeident);
        
    case ( PATH_IDENT(ident = pckgident, path = typepath as PATH_IDENT(_,_) ) )
      equation
        (SOME(typepckg), typeident) = splitPackageAndIdent(typepath);
      then 
        ( SOME(PATH_IDENT(pckgident, typepckg)), typeident) ;
    
    //should not ever happen    
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!splitPackageAndIdent failed.\n");
      then 
        fail();
    
  end matchcontinue;
end splitPackageAndIdent;


public function makePathIdent 
  input PathIdent inPackage;
  input Ident inIdent;
  
  output PathIdent outPathIdent;
algorithm 
  (outPathIdent) := matchcontinue (inPackage, inIdent)
    local
      Ident pckgident, ident;
      PathIdent pckgpath, path;
      
    case ( IDENT(ident = pckgident), ident )
      then 
        PATH_IDENT(pckgident, IDENT(ident));
    
    case ( PATH_IDENT(ident = pckgident, path = pckgpath ), ident )
      equation
        path = makePathIdent(pckgpath, ident);
      then 
        PATH_IDENT(pckgident, path);

    //should not ever happen    
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!!makePathIdent failed.\n");
      then 
        fail();
    
  end matchcontinue;
end makePathIdent;


public function getTypeInfo 
  input Option<PathIdent> inTypePackageOpt;
  input Ident inTypeIdent;
  input list<ASTDef> inASTDefs;
  
  output PathIdent outTypePackage;
  output TypeInfo outTypeInfo;
algorithm 
  (outTypePackage,outTypeInfo ) 
    := matchcontinue (inTypePackageOpt, inTypeIdent, inASTDefs)
    local
      list<tuple<Ident, TypeInfo>> typeLst;
      Ident typeident;
      PathIdent typepckg, importckg;
      Option<PathIdent> typepckgOpt;
      TypeInfo typeinfo;
      list<ASTDef> astDefs;
      
    case ( NONE, typeident, 
          AST_DEF(
            importPackage = importckg,
            isDefault = true,
            types = typeLst) :: astDefs )
      equation
        typeinfo = lookupTupleList(typeLst, typeident);
      then 
        (importckg, typeinfo);
    
    case ( SOME(typepckg), typeident, 
          AST_DEF(
            importPackage = importckg,
            types = typeLst) :: astDefs )
      equation
        equality(typepckg = importckg);
        typeinfo = lookupTupleList(typeLst, typeident);
      then 
        (typepckg, typeinfo);
    
    /*
    case ( SOME(typepckg), typeident, 
          AST_DEF(
            importPackage = importckg,
            types = typeLst) :: astDefs )
      equation
        equality(typepckg = importckg);
        failure(_ = lookupTupleList(typeLst, typeident));
        Debug.fprint("failtrace", "Error - getTypeInfo failed to lookup the type '" +& typeident +& "' for package '" +& pathIdentString(typepckg) +& "'.\n");
      then 
        fail();
    */
    
    case ( typepckgOpt, typeident, ( _ :: astDefs) )
      equation
        (typepckg, typeinfo) = getTypeInfo(typepckgOpt, typeident, astDefs);
      then 
        (typepckg, typeinfo);
    
    case ( NONE, typeident, {} )
      equation
        Debug.fprint("failtrace", "Error - getTypeInfo failed to lookup the type '" +& typeident +& "' after looking up all AST definitions.\n");
      then 
        fail();
        
    case ( SOME(typepckg), typeident, {} )
      equation
        Debug.fprint("failtrace", "Error - getTypeInfo failed to lookup the type '" +& pathIdentString(typepckg) +& "." +& typeident +& "' after looking up all AST definitions.\n");
      then 
        fail();
        
  end matchcontinue;
end getTypeInfo;


protected function deAliasedType
  input TypeSignature inType;
  input list<ASTDef> inASTDefs;
    
  output TypeSignature outType;
algorithm
  outType := matchcontinue(inType, inASTDefs)
    local
      TypeSignature dt;
      Ident typeident;
      PathIdent typepckg, typepath;
      Option<PathIdent> typepckgOpt;
      list<ASTDef> astDefs;
      
    case ( NAMED_TYPE(name = typepath), astDefs )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (_, TI_ALIAS_TYPE(aliasType = dt)) = getTypeInfo(typepckgOpt, typeident, astDefs);        
      then 
        deAliasedType(dt, astDefs);
    
    case (dt, _)
      then dt; 
        
  end matchcontinue;
end deAliasedType;


protected function typesEqual "function typesEqual:
This function compares two type signatures. It assumes the input types are deAliasedType-ed"
  input TypeSignature inTypeA;
  input TypeSignature inTypeB;
  input list<ASTDef> inASTDefs;
algorithm
  _ := matchcontinue(inTypeA, inTypeB, inASTDefs)
    local
      TypeSignature ota, otb;
      list<TypeSignature> otaLst, otbLst;
      Ident typeident;
      PathIdent na, nb;
      Option<PathIdent> typepckgOpt;
      list<ASTDef> astDefs;
      
    case ( LIST_TYPE(ofType = ota), LIST_TYPE(ofType = otb), astDefs )
      equation
        ota = deAliasedType(ota, astDefs);
        otb = deAliasedType(otb, astDefs);
        typesEqual(ota, otb, astDefs);
      then 
        ();
    
    case ( ARRAY_TYPE(ofType = ota), ARRAY_TYPE(ofType = otb), astDefs )
      equation
        ota = deAliasedType(ota, astDefs);
        otb = deAliasedType(otb, astDefs);
        typesEqual(ota, otb, astDefs);
      then 
        ();
    
    case ( OPTION_TYPE(ofType = ota), OPTION_TYPE(ofType = otb), astDefs )
      equation
        ota = deAliasedType(ota, astDefs);
        otb = deAliasedType(otb, astDefs);
        typesEqual(ota, otb, astDefs);
      then 
        ();
    
    case ( TUPLE_TYPE(ofTypes = otaLst), TUPLE_TYPE(ofTypes = otbLst), astDefs )
      equation 
        typesEqualList(otaLst, otbLst, astDefs);
      then ();
    
    case ( NAMED_TYPE(name = na), NAMED_TYPE(name = nb), _ )
      equation
        equality(na = nb);
      then 
        ();
    
    case ( UNRESOLVED_TYPE(_), UNRESOLVED_TYPE(_), _ )
      then 
        ();
    
    // all the others can be matched structurally (as they have no structure)
    case ( ota, otb, _ )
      equation
        equality(ota = otb);
      then 
        ();
    
  end matchcontinue;
end typesEqual;




protected function typesEqualList
  input list<TypeSignature> inTypeAList;
  input list<TypeSignature> inTypeBList;
  input list<ASTDef> inASTDefs;
algorithm
  _ := matchcontinue(inTypeAList, inTypeBList, inASTDefs)
    local
      TypeSignature ota, otb;
      list<TypeSignature> otaLst, otbLst;
      list<ASTDef> astDefs;
      
    case ( {}, {}, _)
      then ();
          
    case ( ota :: otaLst, otb :: otbLst, astDefs )
      equation
        ota = deAliasedType(ota, astDefs);
        otb = deAliasedType(otb, astDefs);
        typesEqual(ota, otb, astDefs);
        typesEqualList(otaLst, otbLst, astDefs);
      then 
        ();
        
  end matchcontinue;
end typesEqualList;


public function getFunSignature
  input PathIdent inFunName;
  input TemplPackage inTplPackage;
  
  output PathIdent outPath;
  output TypedIdents outInArgs;
  output TypedIdents outOutArgs;
algorithm
  outMMPackage := matchcontinue (inFunName, inTplPackage)
    local
      PathIdent fname, funpckg;
      Option<PathIdent> funpckgOpt;
      Ident templname, fident;
      list<tuple<Ident,TemplateDef>> templateDefs;
      list<MMDeclaration> mmDeclarations;
      TemplPackage tp;
      list<ASTDef> astDefs;
      TypedIdents iargs, oargs;
      
    case (fname as IDENT(ident = templname), TEMPL_PACKAGE(templateDefs = templateDefs))
      equation
        TEMPLATE_DEF(args = iargs)  =  lookupTupleList(templateDefs, templname);
        iargs = imlicitTxtArg :: iargs;
        oargs = Util.listFilter(iargs, isText); //just for now, it is not inferred from the usage
        //not encoding templates now
        //templname = encodeIdent(templname);
        fname = IDENT( templname );
      then 
        (fname, iargs, oargs);
    
    case (fname as IDENT(templname), TEMPL_PACKAGE(templateDefs = templateDefs))
      equation
        _  =  lookupTupleList(templateDefs, templname);
        Debug.fprint("failtrace", "Error - '" +& templname +& "' is used in a function/template context while it is defined as a constant.\n");
      then 
        fail();
    
    case (fname, TEMPL_PACKAGE(astDefs = astDefs))
      equation
        NAMED_TYPE(fname) = deAliasedType(NAMED_TYPE(fname), astDefs);
        (funpckgOpt, fident) = splitPackageAndIdent(fname);
        (funpckg, TI_FUN_TYPE(inArgs = iargs, outArgs = oargs)) = getTypeInfo(funpckgOpt, fident, astDefs);
        fname = Util.if_(Util.equal(IDENT("builtin"), funpckg), 
                     IDENT(fident),
                     makePathIdent(funpckg, fident)); 
      then 
        (fname, iargs, oargs);
        
    case (fname, _)
      equation
        Debug.fprint("failtrace", "Error - cannot resolve a function reference '" +& pathIdentString(fname) +& "'.\n");
      then 
        fail();
  end matchcontinue;           
end getFunSignature;


public function checkPackageOpt 
  input PathIdent inPackage;
  input Option<PathIdent> inPackageOpt;
algorithm 
  _ := matchcontinue (inPackage, inPackageOpt)
    local
      PathIdent path, pckgpath;

    case ( _, NONE )
      then 
        ();
    
    case ( path, SOME(pckgpath) )
      equation
        equality(path = pckgpath);
      then
        ();

    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!!checkPackageOpt failed - package paths are not the same.\n");
      then 
        fail();
    
  end matchcontinue;
end checkPackageOpt;


public function getFields 
  input Ident inTagIdent;
  input TypeInfo inTypeInfo;
  input Ident inTypeIdent;
  
  output TypedIdents outFields;
algorithm 
  (outFields) 
    := matchcontinue (inTagIdent, inTypeInfo, inTypeIdent)
    local
      TypeSignature mtype;
      Ident typeident, tagident;
      PathIdent path, tagpath, typepckg;
      Option<PathIdent> typepckgOpt, tagpckgOpt;
      TypeInfo typeinfo;
      list<ASTDef> astDefs;
      TypedIdents fields;
      list<tuple<Ident, TypedIdents>> rectags;
    
    case ( tagident, TI_UNION_TYPE(recTags = rectags) , _)
      equation
        fields = lookupTupleList(rectags, tagident);
      then 
        fields;
    
    case ( tagident, TI_UNION_TYPE(recTags = rectags) , typeident)
      equation
        failure(_ = lookupTupleList(rectags, tagident));
        Debug.fprint("failtrace", "Error - getFields failed to lookup the union tag '" +& tagident +& "', that is not found in type '" +& typeident +& "'.\n");
      then 
        fail();
    
    case ( tagident, TI_RECORD_TYPE(fields = fields), typeident )
      equation
        equality(tagident = typeident);
      then 
        fields;
    
    case ( tagident, TI_RECORD_TYPE(fields = fields), typeident )
      equation
        failure(equality(tagident = typeident));
        Debug.fprint("failtrace", "Error - getFields failed to match the tag '" +& tagident +& "', the type '" +& typeident +& "' expected.\n");
      then 
        fail();
    
    //should not ever happen    
    case ( _, typeinfo, _ )
      equation
        failure(TI_UNION_TYPE(_) = typeinfo); 
        failure(TI_RECORD_TYPE(_) = typeinfo);
        Debug.fprint("failtrace", "- getFields failed - the typeinfo is neither union nor record type.\n");
      then 
        fail();
    
  end matchcontinue;
end getFields;


public function isRecordTag 
  input Ident inTagIdent;
  input TypeInfo inTypeInfo;
  input Ident inTypeIdent;
  
algorithm 
  _ := 
  matchcontinue (inTagIdent, inTypeInfo, inTypeIdent)
    local
      Ident typeident, tagident;
      list<tuple<Ident, TypedIdents>> rectags;
    
    case ( tagident, TI_UNION_TYPE(recTags = rectags) , _)
      equation
        _ = lookupTupleList(rectags, tagident);
      then ();
    
    case ( tagident, TI_RECORD_TYPE(fields = _), typeident )
      equation
        equality(tagident = typeident);
      then ();

  end matchcontinue;
end isRecordTag;


public function fullyQualifyASTDefs 
  input list<ASTDef> inASTDefs;  
  output list<ASTDef> outFullyQualifiedASTDefs;  
algorithm 
  outFullyQualifiedASTDef := matchcontinue inASTDefs
    local
      list<tuple<Ident, TypeInfo>> typeLst;
      PathIdent importckg;
      list<ASTDef> restAstDefs;
      Boolean isdefault;
    
    case ( {})
      then 
        {};
      
    case ( AST_DEF(
            importPackage = importckg,
            isDefault     = isdefault,
            types         = typeLst) :: restAstDefs)
      equation
        typeLst = listMap1Tuple22(typeLst, fullyQualifyAstTypeInfo, importckg);
        restAstDefs = fullyQualifyASTDefs(restAstDefs); 
      then 
        (AST_DEF(importckg, isdefault, typeLst) :: restAstDefs);
    
    case ( AST_DEF(
            importPackage = importckg,
            isDefault     = isdefault,
            types         = typeLst) :: restAstDefs)
      equation
        failure(typeLst = listMap1Tuple22(typeLst, fullyQualifyAstTypeInfo, importckg));
        Debug.fprint("failtrace", "-fullyQualifyASTDefs failed for importckg = " +& pathIdentString(importckg) +& " .\n"); 
      then
        fail();
    
    //should not happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!! fullyQualifyASTDefs failed .\n");
      then 
        fail();
  end matchcontinue;
end fullyQualifyASTDefs;


public function fullyQualifyAstTypeInfo 
  input TypeInfo inASTTypeInfo;
  input PathIdent inImportPackage;
    
  output TypeInfo outFullyQualifiedASTTypeInfo;  
algorithm 
  outFullyQualifiedASTTypeInfo := matchcontinue (inASTTypeInfo, inImportPackage)
    local
      PathIdent importpckg;
      list<tuple<Ident, TypedIdents>> recTags;
      TypedIdents fields, inArgs, outArgs;
      TypeSignature aliasType, constType;
      
    case ( TI_UNION_TYPE( recTags = recTags ) , importpckg )
      equation
        recTags = listMap1Tuple22(recTags, fullyQualifyAstTypedIdents, importpckg);
      then 
        TI_UNION_TYPE(recTags);
    
    case ( TI_RECORD_TYPE( fields = fields ) , importpckg )
      equation
        fields = fullyQualifyAstTypedIdents(fields, importpckg);
      then 
        TI_RECORD_TYPE(fields);
    
    case ( TI_ALIAS_TYPE( aliasType = aliasType ) , importpckg )
      equation
        aliasType = fullyQualifyAstTypeSignature(aliasType, importpckg);
      then 
        TI_ALIAS_TYPE(aliasType);
    
    case ( TI_FUN_TYPE( inArgs = inArgs, outArgs = outArgs) , importpckg )
      equation
        inArgs  = fullyQualifyAstTypedIdents(inArgs, importpckg);
        outArgs = fullyQualifyAstTypedIdents(outArgs, importpckg);
      then 
        TI_FUN_TYPE( inArgs, outArgs);
    
    case ( TI_CONST_TYPE( constType = constType ) , importpckg )
      equation
        constType = fullyQualifyAstTypeSignature(constType, importpckg);
      then 
        TI_CONST_TYPE( constType );
    
    
    //should not happen
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!! fullyQualifyAstTypeInfo failed .\n");
      then 
        fail();
  end matchcontinue;
end fullyQualifyAstTypeInfo;


public function fullyQualifyAstTypedIdents 
  input TypedIdents inASTDefTypedIdents;
  input PathIdent inImportPackage;
    
  output TypedIdents outASTDefTypedIdents;  
algorithm 
  outASTDefTypedIdents := 
    listMap1Tuple22(inASTDefTypedIdents, fullyQualifyAstTypeSignature, inImportPackage); 
end fullyQualifyAstTypedIdents;


public function fullyQualifyAstTypeSignature 
  input TypeSignature inASTDefTypeSignature;
  input PathIdent inImportPackage;
    
  output TypeSignature outASTDefTypeSignature;  
algorithm 
  outASTDefTypeSignature := matchcontinue (inASTDefTypeSignature, inImportPackage)
    local
      list<TypeSignature> typeLst;
      Ident typeident;
      PathIdent importpckg, na;
      TypeSignature ota, ts;
      
    case ( LIST_TYPE(ofType = ota), importpckg )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg);        
      then 
        LIST_TYPE(ota);
    
    case ( ARRAY_TYPE(ofType = ota), importpckg )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg);
      then 
        ARRAY_TYPE(ota);
    
    case ( OPTION_TYPE(ofType = ota), importpckg )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg);
      then 
        OPTION_TYPE(ota);
    
    case ( TUPLE_TYPE(ofTypes = typeLst), importpckg )
      equation
        typeLst = Util.listMap1(typeLst, fullyQualifyAstTypeSignature, importpckg);
      then 
        TUPLE_TYPE(typeLst);
        
    //qualify  and convert  Tpl.Text -> TEXT_TYPE() 
    case ( NAMED_TYPE(name = IDENT(ident = typeident)),  importpckg )
      equation
        na = makePathIdent(importpckg, typeident);
        ts = convertNameTypeIfIntrinsic(na);
      then 
        ts;
    
    //convert  Tpl.Text -> TEXT_TYPE()
    case ( NAMED_TYPE(name = na as PATH_IDENT(_,_)),  importpckg )
      equation
        ts = convertNameTypeIfIntrinsic(na);
      then 
        ts;
    
    //all the others
    case ( ts , _ )
      then 
        ts;
    
    
    //should not happen
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!! fullyQualifyAstTypeSignature failed .\n");
      then 
        fail();
  end matchcontinue;
end fullyQualifyAstTypeSignature;


public function convertNameTypeIfIntrinsic 
  input PathIdent inNameOfType;
  output TypeSignature outTypeSignature;  
algorithm 
  outTypeSignature := matchcontinue (inNameOfType)
    local
      PathIdent na;
      
    case ( PATH_IDENT(ident = "Tpl", path = IDENT("Text")) )
      then 
        TEXT_TYPE();
    
    //case ( PATH_IDENT(ident = "Tpl", path = IDENT("StringToken")) )
    //  then 
    //    STRING_TOKEN_TYPE();
    
    
    case ( na  )
      then 
        NAMED_TYPE(na);
    
    //cannot happen
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!! convertNameTypeIfTextType failed .\n");
      then 
        fail();
  end matchcontinue;
end convertNameTypeIfIntrinsic;


public function fullyQualifyTemplateDef
  input TemplateDef inTemplateDef;
  input list<ASTDef> inASTDefs;
  
  output TemplateDef outTemplateDef;
algorithm
  outTemplateDef := matchcontinue (inTemplateDef, inASTDefs)
    local
      TypedIdents targs;
      Expression texp;
      String lesc, resc, str;
      TypeSignature litType;
      list<ASTDef> astDefs;
      TemplateDef def;
      
    
    case ( LITERAL_DEF(value = str, litType = litType), astDefs)
      equation
        litType = fullyQualifyTemplateTypeSignature(litType, astDefs); //only for a future ... it can be now only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE 
      then 
        LITERAL_DEF(str, litType);
    
    case ( def as STR_TOKEN_DEF(_), _)
      then 
        def;
        
    case ( TEMPLATE_DEF(args = targs, lesc = lesc, resc = resc, exp = texp), astDefs)
      equation
        targs = listMap1Tuple22(targs, fullyQualifyTemplateTypeSignature, astDefs);
      then 
        TEMPLATE_DEF(targs, lesc, resc, texp);
    
    //can fail on errror
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "- fullyQualifyTemplateDef failed .\n");
      then 
        fail();
    
  end matchcontinue;           
end fullyQualifyTemplateDef;


public function fullyQualifyTemplateTypeSignature 
  input TypeSignature inTemplateTypeSignature;
  input list<ASTDef> inASTDefs;
    
  output TypeSignature outFullyQualifiedTypeSignature;  
algorithm 
  outASTDefTypeSignature := matchcontinue (inTemplateTypeSignature, inASTDefs)
    local
      list<TypeSignature> typeLst;
      Ident typeident;
      TypeSignature ota, ts;
      list<ASTDef> astDefs;
      PathIdent typepckg, typepath;
      Option<PathIdent> typepckgOpt;
      
      
    case ( LIST_TYPE(ofType = ota), astDefs )
      equation
        ota = fullyQualifyTemplateTypeSignature(ota, astDefs);        
      then 
        LIST_TYPE(ota);
    
    case ( ARRAY_TYPE(ofType = ota), astDefs )
      equation
        ota = fullyQualifyTemplateTypeSignature(ota, astDefs);
      then 
        ARRAY_TYPE(ota);
    
    case ( OPTION_TYPE(ofType = ota), astDefs )
      equation
        ota = fullyQualifyTemplateTypeSignature(ota, astDefs);
      then 
        OPTION_TYPE(ota);
    
    case ( TUPLE_TYPE(ofTypes = typeLst), astDefs )
      equation
        typeLst = Util.listMap1(typeLst, fullyQualifyTemplateTypeSignature, astDefs);
      then 
        TUPLE_TYPE(typeLst);
    
    //a special case for Text ... Text is an intrinsic type from Susan's viewpoint
    case ( NAMED_TYPE(name = IDENT("Text")),  astDefs )
      then 
        TEXT_TYPE();
        
    //check existence and qualify if needed
    case ( NAMED_TYPE(name = typepath),  astDefs )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (typepckg, _) = getTypeInfo(typepckgOpt, typeident, astDefs);
         typepath = makePathIdent(typepckg, typeident);
      then 
        NAMED_TYPE(typepath);
    
    //all the others
    case ( ts , _ )
      then 
        ts;
    
    
    //should not happen
    case ( _, _ )
      equation
        Debug.fprint("failtrace", "-!!! fullyQualifyTemplateTypeSignature failed .\n");
      then 
        fail();
  end matchcontinue;
end fullyQualifyTemplateTypeSignature;



protected function lookupTupleList
  input list<tuple<Type_a,Type_b>> inList;
  input Type_a inItemA;
  output Type_b outItemB;
    
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outItemB := matchcontinue(inList, inItemA)
    local
       Type_a a, itemA;
       Type_b itemB;
       list<tuple<Type_a,Type_b>> rest;
       
    case ( (a, itemB) :: rest, itemA )
      equation
        equality(a = itemA);
        then itemB;
    case ( _ :: rest, itemA)
      then lookupTupleList(rest, itemA);   
  end matchcontinue;
end lookupTupleList;


protected function updateTupleList
  input list<tuple<Type_a,Type_b>> inList;
  input tuple<Type_a,Type_b> inTuple;
  
  output list<tuple<Type_a,Type_b>> outList;
    
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outList := matchcontinue(inList, inTuple)
    local
       Type_a a;
       tuple<Type_a,Type_b> tpl;
       list<tuple<Type_a,Type_b>> lst;
    
    case (lst, (a,_))
      equation
        _ = lookupTupleList(lst, a);
      then lst;
    
    case (lst, tpl)
      then (tpl :: lst);

  end matchcontinue;
end updateTupleList;


protected function lookupDeleteTupleList
  input list<tuple<Type_a,Type_b>> inList;
  input Type_a inItemA;
  output Type_b outItemB;
  output list<tuple<Type_a,Type_b>> outList;
    
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  (outItemB, outList) := matchcontinue(inList, inItemA)
    local
       Type_a a, itemA;
       Type_b itemB;
       list<tuple<Type_a,Type_b>> rest;
       tuple<Type_a,Type_b> h;
       
    case ( (a, itemB) :: rest, itemA )
      equation
        equality(a = itemA);
      then 
        (itemB, rest);
    
    case ( h :: rest, itemA)
      equation
        (itemB, rest) = lookupDeleteTupleList(rest, itemA);
      then 
        (itemB, h :: rest);  
  end matchcontinue;
end lookupDeleteTupleList;

protected function alignTupleList "
Alignes the first list to be ordered by the second list with respect of the first elements of the (double) tuples.
Only those tuples from the first list that have a corresponding tuple with the same first element in the second list will be included.
Assuming the lists have distinct tuples (no multiple first elements occurences)."
  input list<tuple<Type_a,Type_b>> inListToAlign;
  input list<tuple<Type_a,Type_b>> inListAlignBy;
  
  output list<tuple<Type_a,Type_b>> outAlignedList;
    
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
algorithm
  outList := matchcontinue(inListToAlign, inListAlignBy)
    local
       Type_a a;
       Type_b b;
       tuple<Type_a,Type_b> tpl;
       list<tuple<Type_a,Type_b>> lst, lstAl, lstBy;
    
    case (lstAl, (a,_) :: lstBy)
      equation
        b = lookupTupleList(lstAl, a);
        lst = alignTupleList(lstAl, lstBy);
      then (a,b) :: lst;
    
    case (lstAl, _ :: lstBy)
      equation
        //failure(b = lookupTupleList(lstAl, a));
        lst = alignTupleList(lstAl, lstBy);
      then lst;
    
    case (_, {} )
      then {};
    
  end matchcontinue;
end alignTupleList;

protected function listMap1Tuple22
  input list<tuple<Type_a,Type_b>> inList;
  input Fun_Tbd_to_Tc inFun_Tbd_to_Tc;
  input Type_d inExtraArg;
  
  output list<tuple<Type_a,Type_c>> outList;
    
  partial function Fun_Tbd_to_Tc
    input Type_b inTypeB;
    input Type_d inTypeD;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end Fun_Tbd_to_Tc;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;  
algorithm
  outList := matchcontinue(inList, inFun_Tbd_to_Tc, inExtraArg)
    local
       Type_a a;
       Type_b itemB;
       Type_c itemC;
       Type_d extarg;
       Fun_Tbd_to_Tc funBDtoC;
       list<tuple<Type_a,Type_b>> restB;
       list<tuple<Type_a,Type_c>> restC;
       
    case ( {}, _, _) then {};
    
    case ( (a, itemB) :: restB, funBDtoC, extarg )
      equation
        itemC = funBDtoC(itemB, extarg);
        restC = listMap1Tuple22(restB, funBDtoC, extarg); 
      then 
        ((a, itemC) :: restC);
        
       
  end matchcontinue;
end listMap1Tuple22;



//**************************************
// *** debug output functions
//**************************************

public function canBeEscapedUnquoted
	  input list<String> inStringList;
	  output Boolean outCanBeUnquoted;
algorithm 
  outCanBeUnquoted := 
  matchcontinue (inStringList)
    local
      String str;
      list<String> rest;
    
    case ( { str } )
      equation
        true = stringLength(str) > 0;
        true = canBeEscapedUnquotedChars(stringListStringChar(str));
      then 
        true;
    
    case ( str :: (rest as (_::_)) )
      equation
        true = stringLength(str) > 0;
        true = canBeEscapedUnquotedChars(stringListStringChar(str));
      then 
        canBeEscapedUnquoted(rest);
    
    //can not be unquoted or empty list(should not happen)
    case ( _ )
      then 
        false;
    
  end matchcontinue;	 
end canBeEscapedUnquoted;


protected function canBeEscapedUnquotedChars
  input list<String> inChars;
  output Boolean outCanBeUnquated;
algorithm
  outCanBeUnquated :=
  matchcontinue(inChars)
    local
      String c;
      list<String> chars;
    
    case ({}) then true; 
    
    case ( c  :: chars) 
      equation
        // \a \b \f \r \v  ... TODO: Error in the .srz or .c compilation(\r)
        true = 
            (c ==& "\'") 
         or (c ==& "\"") 
         or (c ==& "?") 
         or (c ==& "\\") 
         or (c ==& "\n") 
         or (c ==& "\t") 
         or (c ==& " ");
      then canBeEscapedUnquotedChars(chars);
    
    case ( _ ) then false;
      
  end matchcontinue;
end canBeEscapedUnquotedChars;


public function canBeOnOneLine
	  input list<String> inStringList;
	  output Boolean outCanBeOnOneLine;
algorithm 
  outCanBeOnOneLine := 
        (listLength(inStringList) <= 4) 
        and stringLength(Util.stringAppendList(inStringList)) <= 10;
end canBeOnOneLine;


public function pathIdentString 
  input PathIdent inPathIndent;
  output String outPathIdentString;
algorithm 
  (outPathIdentString) := matchcontinue (inPathIndent)
    local
      Ident ident;
      PathIdent path;
      
    case ( IDENT(ident = ident) )
      then 
        ident;
    
    case ( PATH_IDENT(ident = ident, path = path ) )
      equation
        ident = ident +& "." +& pathIdentString(path);
      then 
        ident;

    //should not ever happen    
    case ( _ )
      equation
        Debug.fprint("failtrace", "-!!!pathIdentString failed.\n");
      then 
        fail();
    
  end matchcontinue;
end pathIdentString;


protected
constant Tpl.Text eTxt = Tpl.MEM_TEXT({}, {}); 

public function typeSignatureString
  input TypeSignature inTS;
  output String outStr;
  
  protected
   Tpl.Text txt;
algorithm
  txt := TplCodegen.typeSig(eTxt, inTS);
  outStr := Tpl.textString(txt);
end typeSignatureString;

public function mmExpString
  input MMExp inMMExp;
  output String outStr;
  
  protected
   Tpl.Text txt;
algorithm
  txt := TplCodegen.mmExp(eTxt, inMMExp,"=");
  outStr := Tpl.textString(txt);
end mmExpString;

public function stmtsString
  input list<MMExp> inStmts;
  output String outStr;
  
  protected
   Tpl.Text txt;
   //list<MMExp> v_statements;
algorithm
  txt := TplCodegen.mmStatements(eTxt, inStmts); //<statements : mmExp(it, '=')\n>      
  outStr := Tpl.textString(txt);
end stmtsString;



end TplAbsyn;
  
  