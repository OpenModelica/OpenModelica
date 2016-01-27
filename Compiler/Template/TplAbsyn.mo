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
encapsulated package TplAbsyn
"
  file:        TplAbsyn.mo
  package:     TplAbsyn
  description: Susan abstract syntax

  $Id$
"

protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import System;
protected import Util;

public import Tpl;
protected import TplCodegen;


/* Input AST */
public type Ident = String;
public type TypedIdents = list<tuple<Ident, TypeSignature>>;
public type EscOption = tuple<Ident, Option<Expression>>;
public type StringToken = Tpl.StringToken;
public type Tokens = Tpl.Tokens;

constant SourceInfo dummySourceInfo = SOURCEINFO("NoFileName.xxx", false, 0, 0, 0, 0, 0.0);

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

public
type Expression = tuple<ExpressionBase, SourceInfo>;

public
uniontype ExpressionBase
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
    Option<MatchingExp> rhsValue "always NONE() for now; it is a residuum from the form 'if exp is PATTERN then ...'";
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
    Option<Ident> hasIndexIdentOpt;
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

  record LET
    Expression letExp;
    Expression exp;
  end LET;
  /*
  record LET_BINDING
    Ident name;
    Expression exp;
  end LET_BINDING;
  */
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


  record ERROR_EXP "Parse error expression used when parser error occured."
  end ERROR_EXP;

end ExpressionBase;

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
    TypeSignature litType "only INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE";
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
    list<Ident> tyVars;
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
    String annotationFooter;
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
    String annotationFooter;
  end MM_PACKAGE;
end MMPackage;

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

    GenInfo genInfoOpt "internal use only - a type of elaboration of the funtion.";
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

public type MMMatchCase = tuple<list<MatchingExp>, list<MMExp>>;

constant Ident imlicitTxt = "txt";
constant Ident inPrefix = "in_";
constant Ident outPrefix = "out_";
//constant Ident imlicitInTxt = "intxt"; //not used ... there can be the same names for in/ou values
//constant Ident imlicitOutTxt = "outtxt";

constant Ident funArgNamePrefix = "a_";
constant Ident extArgNamePrefix = "e_";
constant Ident letValueNamePrefix = "l_";
constant Ident indexNamePrefix = "x_";
constant Ident caseBindingNamePrefix = "i_";
constant Ident returnTempVarNamePrefix = "ret_";
constant Ident constantNamePrefix = "c_";
constant Ident textTempVarNamePrefix = "txt_";
constant Ident textToStringNamePrefix = "str_";

constant Ident matchFunPrefix = "fun_";
constant Ident listMapFunPrefix = "lm_";
constant Ident scalarMapFunPrefix = "smf_";

//constant Ident implicitTxtInArgName = "inTxt";
constant Ident matchDefaultArgName = "mArg";


constant Ident impossibleIdent = "*none*";

constant tuple<Ident,TypeSignature> imlicitTxtArg = (imlicitTxt, TEXT_TYPE());
//constant tuple<Ident,TypeSignature> imlicitTxtInputArg = (implicitTxtInArgName, TEXT_TYPE());

/* internal types */
protected

constant MatchingExp imlicitTxtMExp = BIND_MATCH(imlicitTxt);
constant Expression emptyExpression = (STR_TOKEN(Tpl.ST_STRING("")), dummySourceInfo) ;

constant Ident emptyTxt = "Tpl.emptyTxt";
constant Ident errorIdent = "!error!";

constant Tpl.IterOptions defaultIterOptions
  = Tpl.ITER_OPTIONS(0, NONE(), NONE(), 0, 0, Tpl.ST_NEW_LINE(), 0, Tpl.ST_NEW_LINE());


public //only achievable by the 'from' clause
constant Ident indexOffsetOptionId    = "$indexOffset";

protected

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
  (separatorOptionId, (MM_LITERAL("NONE()"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),

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
  (emptyOptionId, (MM_LITERAL("NONE()"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),
  (separatorOptionId, (MM_LITERAL("NONE()"), OPTION_TYPE(STRING_TOKEN_TYPE())) ),

  (alignNumOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (alignNumOffsetOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (alignSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE()) ),

  (wrapWidthOptionId, (MM_LITERAL("0"), INTEGER_TYPE()) ),
  (wrapSeparatorOptionId, (MM_STR_TOKEN(Tpl.ST_NEW_LINE()), STRING_TOKEN_TYPE()))
};


public

type MMEscOption = tuple<Ident,tuple<MMExp, TypeSignature>>;
type ScopeEnv = list<Scope>;


uniontype Scope
  record FUN_SCOPE
    TypedIdents args;
    TypedIdents localArgs "local encoded args; used to elaborate the actual args of closures";
    //TypedIdents usedArgs; ... will be derived from MMExp
    //TypedIdents outArgs; ... will be derived from MMExp
  end FUN_SCOPE;

  record CASE_SCOPE
    MatchingExp mExp;
    TypeSignature mType;
    list<tuple<Ident,Ident>> localNames "source name -> local declaration name table";
    TypedIdents accLocals "accumulated locals used by the cases in this match elaborated level";
    TypedIdents extArgs "local args from the upper scope - all of them are from their upper FUN_SCOPE()";
    Ident matchArgName "local name of the match argument";
    Boolean hasImplicitScope "true for 'match' or 'map', false for 'if' elaborated cases; desides if the implicit record fields' lookup can continue upwards the scope stack.";
  end CASE_SCOPE;

  record LET_SCOPE
    Ident ident "original ident";
    TypeSignature idType;
    Ident freshIdent "encoded ident with prefix and suffix unique for the local scope";
    Boolean isUsed "true when found by resolveBoundPath()";
  end LET_SCOPE;

  record RECURSIVE_SCOPE
    "forbidden access - scope of a text add ident; to prevent recursive usage of texts;
     or scope of an elaborated let binding; to force a fresh local ident to be created when the same name is re-bound inside the let expression."
    Ident recIdent;
    Ident freshIdent "local name";
  end RECURSIVE_SCOPE;

end Scope;


uniontype MapContext
  record MAP_CONTEXT
    //list<TypeSignature, MMDeclaration> mapFunctions;
    MatchingExp ofBinding;
    Expression mapExp;
    list<MMEscOption> iterMMExpOptions;
    Option<Ident> hasIndexIdentOpt "used index variable";
    Boolean useIter "Whether PushIter/NextIter/PopIter is necessary.";
  end MAP_CONTEXT;
end MapContext;


uniontype GenInfo
  record GI_TEMPL_FUN end GI_TEMPL_FUN;
  record GI_MATCH_FUN end GI_MATCH_FUN;
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
  outMMPackage := match (inTplPackage)
    local
      PathIdent name;
      list<tuple<Ident,TemplateDef>>  templateDefs;
      list<MMDeclaration> mmDeclarations;
      TemplPackage tp;
      list<ASTDef> astDefs;
      String annotationFooter;

    case _
      equation
        tp = fullyQualifyTemplatePackage(inTplPackage);
        TEMPL_PACKAGE(name, astDefs, templateDefs, annotationFooter) = tp;
        mmDeclarations = importDeclarations(astDefs, {});
        mmDeclarations
         = transformTemplateDefs(templateDefs, tp, mmDeclarations);
        mmDeclarations = listReverse(mmDeclarations);
      then
        MM_PACKAGE(name, mmDeclarations, annotationFooter);
  end match;
end transformAST;

public function fullyQualifyTemplatePackage
  input TemplPackage inTplPackage;
  output TemplPackage outTplPackage;
algorithm
  outTplPackage := match (inTplPackage)
    local
      PathIdent name;
      list<tuple<Ident,TemplateDef>>  templateDefs;
      list<ASTDef> astDefs;
      String ann;

    case TEMPL_PACKAGE(name,astDefs,templateDefs,ann)
      equation
        astDefs = fullyQualifyASTDefs(astDefs);
        templateDefs = listMap1Tuple22(templateDefs, fullyQualifyTemplateDef, astDefs);
      then
        TEMPL_PACKAGE(name, astDefs, templateDefs,ann);
  end match;
end fullyQualifyTemplatePackage;


public function importDeclarations
  input list<ASTDef> inASTDefs;
  input list<MMDeclaration> inAccMMDecls;

  output list<MMDeclaration> outMMDecls;
algorithm
  outMMDecls := match (inASTDefs, inAccMMDecls)
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

  end match;
end importDeclarations;

public function transformTemplateDefs
  input list<tuple<Ident,TemplateDef>>  inTemplateDefsRest;
  input TemplPackage inTplPackage;
  input list<MMDeclaration> inAccMMDecls;

  output list<MMDeclaration> outMMDecls;
algorithm
  outMMDecls := match (inTemplateDefsRest, inTplPackage, inAccMMDecls)
    local
      Ident tplname;
      list<tuple<Ident,TemplateDef>> restTDefs;
      TemplPackage tplPackage;
      list<MMDeclaration> mmDecls, accMMDecls;
      StringToken stvalue;
      TypedIdents targs, encArgs, locals, iargs, oargs;
      Expression texp;
      list<MMExp> stmts;
      MMDeclaration mmFun;
      String svalue;
      TypeSignature litType;

    case ( {} , _, accMMDecls )
      then accMMDecls;

    case ( (tplname, STR_TOKEN_DEF(value = stvalue)) :: restTDefs, tplPackage, accMMDecls )
      equation
        tplname = constantNamePrefix + tplname; //no encoding needed, just denoting it is a constant (only for readibility)
        mmDecls = transformTemplateDefs(restTDefs, tplPackage,
                  (MM_STR_TOKEN_DECL(true, tplname, stvalue) :: accMMDecls));
      then mmDecls;

    case ( (tplname, LITERAL_DEF(value = svalue, litType = litType)) :: restTDefs, tplPackage, accMMDecls )
      equation
        tplname = constantNamePrefix + tplname; //actually, literals are inlined, so this is just for presence of the constant in the source
        mmDecls = transformTemplateDefs(restTDefs, tplPackage,
                  (MM_LITERAL_DECL(true, tplname, svalue, litType) :: accMMDecls));
      then mmDecls;

    case ( (tplname, TEMPLATE_DEF(args = targs, exp = texp)) :: restTDefs, tplPackage, accMMDecls )
      equation

        encArgs = List.map1(targs, encodeTypedIdent, funArgNamePrefix);

        //only out parameters (all are Texts only) in the assignments ':=' will have the "out_" prefix in the statements
        //the rest is tailored into templates
        //... but function signatures have no prefixes in their AST representations (iargs, oargs, ...)
        (stmts, locals, _, accMMDecls,_)
          = statementsFromExp(texp, {}, {}, imlicitTxt, /*outPrefix +*/ imlicitTxt, {},
               { FUN_SCOPE(targs, encArgs) },  tplPackage, accMMDecls);


        //template functions will have unencoded original names
        //TODO: should be done some checks for uniqueness / keywords collisions ...
        //tplname = encodeIdent(tplname);
        iargs = imlicitTxtArg :: encArgs;
        oargs = List.filter(iargs, isText);
        stmts = listReverse(stmts);
        stmts = addOutPrefixes(stmts, oargs, {});
        (stmts, locals, accMMDecls) = inlineLastFunIfSingleCall(iargs, oargs, stmts, locals, accMMDecls);
        mmFun = MM_FUN(true, tplname, iargs, oargs, locals, stmts, GI_TEMPL_FUN());
      then
        transformTemplateDefs(restTDefs, tplPackage, mmFun :: accMMDecls);

  end match;
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
  (outStmts, outLocals, outMMDecls) := matchcontinue (inInArgs, inOutArgs, inStmts, inLocals, inAccMMDecls)
    local
      list<MMExp> stmts;
      Ident fidCalled, fidLast;
      TypedIdents locals, iargs, oargs, iargsL, oargsL;
      list<MMDeclaration> accMMDecls;
      GenInfo genInfo;

    // the last call is the only call of the last elaborated function (from makeMatchFun)
    case ( iargs, oargs,
          { MM_ASSIGN(rhs = MM_FN_CALL(fnName = IDENT(fidCalled)) ) },
          {},
          MM_FUN(_, fidLast, iargsL, oargsL, locals, stmts, genInfo) :: accMMDecls)
      equation
        true = stringEq(fidCalled, fidLast);
        failure(GI_TEMPL_FUN() = genInfo); //we can inline only generated helper functions, not regular template functions
        equality(iargs = iargsL);
        equality(oargs = oargsL);
      then ( stmts, locals, accMMDecls );

    // otherwise nothing
    case ( _, _, stmts, locals, accMMDecls)
      then ( stmts, locals, accMMDecls );
  end matchcontinue;
end inlineLastFunIfSingleCall;

//prepend "i" in front of the ident to obey the MM rule that no identifier can start with "_"
public function encodeIdent
  input Ident inIdent;
  input Ident prefix;
  output Ident outIdent;
algorithm
  outIdent := prefix + encodeIdentNoPrefix(inIdent);
end encodeIdent;

//every ident to be encoded as ".ident"
//where "." is encoded as "_" or "_0" in the case it is followed with "_" (idents starting with _)
protected function encodeIdentNoPrefix
  input Ident inIdent "original ident; it can be sringified dot path, too";
  output Ident outIdent "unambiguous,ono-one back-convertible legal ident; can start with '_' ";
algorithm
  (outIdent) := matchcontinue (inIdent)
    local
      Ident ident;

    //to prevent ambiguity when prefixing the encoded ident,
    //when the first character is "_", encode it as "_0" (although this is not relevant for MM yet)
    case ( ident  )
      equation
        true = (stringLength(ident) > 0) and (stringGetStringChar(ident,1) == "_");
        ident = System.stringReplace(ident, "_", "__");
        ident = System.stringReplace(ident, "._", "_0");
        ident = System.stringReplace(ident, ".", "_");
        ident = "0" + ident;
      then
        ( ident );

    case ( ident  )
      equation
        //false = (stringLength(ident) > 0) and (stringGetStringChar(ident,1) == "_");

        ident = System.stringReplace(ident, "_", "__");
        ident = System.stringReplace(ident, "._", "_0");
        ident = System.stringReplace(ident, ".", "_");
      then
        ( ident );

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!encodeIdentNoPrefix failed\n");
      then
        fail();
  end matchcontinue;
end encodeIdentNoPrefix;

public function encodePathIdent
  input PathIdent inPath;
  input Ident prefix;
  output Ident outEncIdent;
algorithm
  outEncIdent := encodeIdent(pathIdentString(inPath), prefix);
end encodePathIdent;


public function encodeTypedIdent
  input tuple<Ident,TypeSignature> inTypedIdent;
  input Ident prefix;
  output tuple<Ident,TypeSignature> outTypedIdent;
algorithm
  (outTypedIdent) := matchcontinue (inTypedIdent, prefix)
    local
      Ident ident;
      TypeSignature ts;

    case ((ident,ts),_)
      equation
        ident = encodeIdent(ident, prefix);
      then
        ((ident,ts));

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!encodeTypedIdent failed\n");
      then
        fail();
  end matchcontinue;
end encodeTypedIdent;


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
      TypedIdents txtargs;
      list<Ident> largs;
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addOutPrefixes failed\n");
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
      list<MMExp>  fargs;
      MMExp stmt;
      Ident ident, outident;
      PathIdent fpath;
      list<tuple<Ident,Ident>> trIdents;

    case ( MM_IDENT(IDENT(ident = ident)), trIdents)
      equation
        outident = lookupTupleList(trIdents, ident);
      then ( MM_IDENT(IDENT(outident)) );

    case ( MM_FN_CALL(fnName = fpath, args = fargs), trIdents)
      equation
        fargs = List.map1(fargs, addOutPrefixesRhs, trIdents);
      then ( MM_FN_CALL(fpath, fargs) );

    else inStmt;

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
      Ident ident;
      TypedIdents txtargs;
      list<Ident> largs;
      String outident;
      list<tuple<Ident,Ident>> trIdents;

    case (  {},_, trIdents)
      then ( {}, trIdents );

    case ( ident :: largs, txtargs, trIdents)
      equation
        _ = lookupTupleList(txtargs, ident);
        outident = outPrefix + ident;
        trIdents = updateTupleList(trIdents, (ident,outident) );
        (largs, trIdents) = addOutPrefixesLhs(largs, txtargs, trIdents);
      then ( outident :: largs, trIdents );

    case ( ident :: largs, txtargs, trIdents)
      equation
        failure(_ = lookupTupleList(txtargs, ident));
        (largs, trIdents) = addOutPrefixesLhs(largs, txtargs, trIdents);
      then ( ident :: largs, trIdents );

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addOutPrefixesLhs failed\n");
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
      String outident;
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
        outident = outPrefix + ident;
        stmts = addOutTextAssigns( restArgs, trIdents);
      then ( MM_ASSIGN({outident},MM_IDENT(IDENT(ident))) :: stmts );

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addOutTextAssigns failed\n");
      then
        fail();
  end matchcontinue;
end addOutTextAssigns;


public function isAssignedIdent
  input list<MMExp> inStatementList;
  input Ident inIdent;

  output Boolean outIsAssigned;
algorithm
  (outIsAssigned) := match (inStatementList, inIdent)
    local
      Ident ident;
      list<Ident> largs;
      list<MMExp> rest;

    case ( {}, _ )  then  false;

    case ( MM_ASSIGN(lhsArgs = largs) :: _, ident ) guard listMember(ident, largs)
      then
        true;

    case ( _ :: rest, ident )
      then
        isAssignedIdent(rest, ident);

  end match;
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
      list<MMExp> stmts,  popstmts;
      MMExp stmt, mmexp;
      ScopeEnv scEnv;
      Ident intxt, outtxt, ident, encIdent, letOuttxt, freshIdent;
      list<Ident> tyVars;
      PathIdent path, fname;
      TypedIdents locals, iargs, oargs;
      TypeSignature idtype, exptype,  rettype;
      tuple<MMExp, TypeSignature, SourceInfo> argval;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      Expression exp, tbranch, argexp, mapexp, txtexp;
      list<Expression> explst;
      Option<Expression> ebranch;
      SourceInfo sinfo, sinfo2;
      list<tuple<MatchingExp,Expression>> mcases;
      MatchingExp ofbind;
      Option<MatchingExp> rhsval;
      list<EscOption> opts;
      list<MMEscOption> mmopts;
      Boolean hasretval, isnot, isUsed;
      Integer n;
      StringToken st;
      list<ASTDef> astDefs;
      String litvalue, istr;
      MapContext mapctx;
      Option<Ident> idxNmOpt;

      TemplPackage tplPackage;
      list<MMDeclaration> accMMDecls;

    case ( (TEMPLATE(items = explst), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExpList(explst, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    //inline a literal in its string-token form
    case ( (LITERAL(value = litvalue), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", { MM_STR_TOKEN(Tpl.ST_STRING(litvalue)) }, intxt, outtxt);
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);

    case ( (SOFT_NEW_LINE(), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("softNewLine", { }, intxt, outtxt);
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);

    //empty string -> nothing
    case ( (STR_TOKEN(value = Tpl.ST_STRING("")), _), mmopts,
           stmts, intxt, _, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    case ( (STR_TOKEN(value = st), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, _, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", { MM_STR_TOKEN(st) }, intxt, outtxt);
      then ( stmt :: stmts, locals, scEnv, accMMDecls, outtxt);

    case ( (BOUND_VALUE(boundPath = path), sinfo), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n BOUND_VALUE resolving boundPath = " + pathIdentString(path));
        end if;
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        //Debug.fprint(Flags.FAILTRACE,"\n BEFORE boundPath = " + pathIdentString(path) + "\n");
        checkResolvedType(path, idtype, "bound value", sinfo);
        //Debug.fprint(Flags.FAILTRACE,"\n AFTER boundPath = " + pathIdentString(path) + "\n");
        //ensure non-recursive Text evaluation - only this level ...
        //TODO: for indirect reference, too, like <# buf += templ(buf) #>
        //true = ensureNotUsingTheSameText(path, mmexp, idtype, outtxt);
        exptype = deAliasedType(idtype, astDefs);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n BOUND_VALUE resolved mmexp = " + mmExpString(mmexp) + " : "
                     + typeSignatureString(idtype) + " (dealiased: "
                     + typeSignatureString(exptype) + ")");
        end if;
        (stmts, locals, scEnv, accMMDecls, intxt)
          = addWriteCallFromMMExp(true, mmexp, exptype, sinfo, mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        // fprint(Flags.FAILTRACE," BOUND_VALUE after writeCall stmts (in reverse order) =\n" + stmtsString(stmts) + "\n");
      then ( stmts, locals, scEnv, accMMDecls, intxt);


    case ( (FUN_CALL(name = fname, args = explst), sinfo), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n FUN_CALL fname = " + pathIdentString(fname));
        end if;
        (fname, iargs, oargs, tyVars) = getFunSignature(fname, sinfo, tplPackage);
        // fprint(Flags.FAILTRACE," after fname = " + pathIdentString(fname) + "\n");

        //explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls)
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);

        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace(" FUN_CALL argList stmts generation passed\n");
        end if;
        //fprint(Flags.FAILTRACE," FUN_CALL after argList stmts (in reverse order) =\n" + stmtsString(stmts) + "\n");

        (hasretval, stmt, mmexp, rettype, locals, intxt)
          = statementFromFun(argvals, fname, iargs, oargs, tyVars, intxt, outtxt, locals, tplPackage, sinfo);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace(" FUN_CALL stmt =\n" + stmtsString({stmt}) + "\n");
        end if;

        rettype = deAliasedType(rettype, astDefs);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = addWriteCallFromMMExp(hasretval, mmexp, rettype, sinfo, mmopts, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    //previous fail on error, just go on .. TODO: after bootstrapping, the logic --> match
    //case ( (FUN_CALL(name = fname, args = explst), sinfo), mmopts,
    //       stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
    //  equation
    //    //TODO: make this nicer ..
    //    stmt = MM_FN_CALL(IDENT("#ERROR#"), {});
    //    then ( stmt :: stmts, locals, scEnv, accMMDecls, intxt);


    case ( (MATCH(matchExp = exp, cases = mcases), sinfo), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (argval, stmts, locals, scEnv, accMMDecls)
          = statementsFromArg(exp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (argval, exp, stmts, locals)
          = adaptTextToString(argval, exp, stmts, locals, tplPackage);
        (argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun(argval, mcases, exp, true, scEnv, tplPackage, accMMDecls);
        (_, stmt, _, _, locals, intxt)
          = statementFromFun(argvals, fname, iargs, oargs, {}, intxt, outtxt, locals, tplPackage, sinfo);
      then ( (stmt :: stmts),  locals, scEnv, accMMDecls, intxt);

    case ( (CONDITION( isNot = isnot, lhsExp = exp,
                      rhsValue = rhsval, trueBranch = tbranch, elseBranch = ebranch), sinfo), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        (argval, stmts, locals, scEnv, accMMDecls)
          = statementsFromArg(exp, stmts, locals, scEnv, tplPackage, accMMDecls);
        //(argval, stmts, locals)
        //  = adaptTextToString(argval, stmts, locals, tplPackage);
        (_,exptype,_) = argval;
        exptype = deAliasedType(exptype, astDefs);
        mcases
          = elabCasesFromCondition(exptype, isnot, rhsval, tbranch, ebranch, tplPackage);
        ( argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun(argval, mcases, exp, false, scEnv, tplPackage, accMMDecls);
        (_, stmt, _, _, locals, intxt)
          = statementFromFun(argvals, fname, iargs, oargs, {}, intxt, outtxt, locals, tplPackage, sinfo);
      then ( (stmt :: stmts),  locals, scEnv, accMMDecls, intxt);

    case ( (MAP(argExp = argexp, ofBinding = ofbind, mapExp = mapexp, hasIndexIdentOpt = idxNmOpt), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        explst = getExpListForMap(argexp);
        (argvals, stmts, locals, scEnv, accMMDecls)
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);
        mapctx = MAP_CONTEXT(ofbind, mapexp, mmopts, idxNmOpt, false);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, argvals, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);

        /*(stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromEscapedExp(exp, {},
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);*/
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    case ( (MAP_ARG_LIST(parts = explst), _), mmopts,
           stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        (argvals, stmts, locals, scEnv, accMMDecls)
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);
        mapctx = MAP_CONTEXT(BIND_MATCH("it"), (BOUND_VALUE(IDENT("it")), dummySourceInfo), mmopts, NONE(), false);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, argvals, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        /*
        //when no options, MAP_ARG_LIST is identical to TEMPLATE
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExpList(explst, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);*/
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    case ( (ESCAPED(exp = exp, options = opts), _), mmopts,
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

    case ( (INDENTATION(width = n, items = explst), _), mmopts,
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

    //TODO: let _ =  ....
    case ( (LET(letExp = (TEXT_CREATE(name = ident, exp = txtexp), _),
               exp = exp), _),
           mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        //allowing hiddening of let bindings
        //(_, UNRESOLVED_TYPE(reason), scEnv)
        //  = resolveBoundPath(IDENT(ident), scEnv, tplPackage);
        //fprint(Flags.FAILTRACE,"\n TEXT_CREATE ident = " + ident + " is fresh (reason = " + reason + ")\n");
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n TEXT_CREATE ident = " + ident);
        end if;

        encIdent = encodeIdent(ident, letValueNamePrefix);
        (freshIdent, locals)  = updateLocalsForLetExp(ident, encIdent, 0, TEXT_TYPE(), locals, scEnv);

        (stmts, locals, _ :: scEnv, accMMDecls, letOuttxt)
          = statementsFromExp(txtexp, {}, stmts, emptyTxt, freshIdent, locals,
               RECURSIVE_SCOPE(ident, freshIdent) :: scEnv, tplPackage, accMMDecls);
        //explicitly initialize when  let &ident = buffer ""
        stmts = if letOuttxt == emptyTxt then
                  MM_ASSIGN({freshIdent}, MM_IDENT(IDENT(emptyTxt))) :: stmts else
                  stmts;
        //push the ident in the let scope
        scEnv = LET_SCOPE(ident, TEXT_TYPE(), freshIdent, false) :: scEnv;
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExp(exp, {}, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        //pop the let scope
        (LET_SCOPE() :: scEnv) = scEnv;
        //TODO: worn when not used
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    //TODO: make this warning only, and only when the hidden binding is not used
    /*
    case ( LET(letExp = TEXT_CREATE(name = ident, exp = txtexp),
               exp = exp),
           mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        (_, idtype, _)
          = resolveBoundPath(IDENT(ident), scEnv, tplPackage);
        failure(UNRESOLVED_TYPE(_) = idtype);
        fprint(Flags.FAILTRACE,"\nError - TEXT_CREATE ident = '" + ident + "' is NOT fresh (type = " + typeSignatureString(idtype) + ")\n Only new (fresh) variable can be used in a Text assignment (creation).\n");
      then fail();
    */

    case ( (LET(letExp = (TEXT_ADD(name = ident, exp = txtexp),sinfo2),
               exp = exp), _),
           mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        path = IDENT(ident);
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        checkResolvedType(path, idtype, "let +=", sinfo2);
        idtype = checkTextType(idtype, ident, "let +=", sinfo2);
        MM_IDENT(IDENT(encIdent)) = mmexp;
        //TEXT_TYPE() = idtype;
        //prevent recursive usage of the ident iside of the addition
        //error will be caught when BOUND_VALUE with the ident occur in the txtexp
        scEnv = RECURSIVE_SCOPE(ident, encIdent) :: scEnv;
        (stmts, locals, scEnv, accMMDecls, _)
          = statementsFromExp(txtexp, {}, stmts, encIdent, encIdent, locals, scEnv, tplPackage, accMMDecls);
        (RECURSIVE_SCOPE() :: scEnv) = scEnv;

        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExp(exp, {}, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    /*
    case ( (LET(letExp = (TEXT_ADD(name = ident, exp = txtexp),_),
               exp = exp), sinfo),
           mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls )
      equation
        path = IDENT(ident);
        (_, idtype, _) = resolveBoundPath(path, scEnv, tplPackage);
        failure(UNRESOLVED_TYPE(_) = idtype);
        failure(TEXT_TYPE() = idtype);
        fprint(Flags.FAILTRACE,"\nError - TEXT_ADD ident = '" + ident + "' is NOT of Text& type but " + typeSignatureString(idtype) + ")\n Only Text& typed variables can be appended to.\n");
      then fail();
    */

    case ( (LET(letExp = (NORET_CALL(name = fname, args = explst),sinfo2),
               exp = exp), _),
           mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(), accMMDecls )
      equation
        warnIfSomeOptions(mmopts);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n NORET_CALL fname = " + pathIdentString(fname));
        end if;
        (fname, iargs, oargs, tyVars) = getFunSignature(fname, sinfo2, tplPackage);
        //fprint(Flags.FAILTRACE," after fname = " + pathIdentString(fname) + "\n");

        {} = oargs;
        //explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls)
          = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);

        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace(" NORET_CALL argList stmts generation passed.\n");
        end if;
        //fprint(Flags.FAILTRACE," NORET_CALL after argList stmts (in reverse order) =\n" + stmtsString(stmts) + "\n");

        (_, stmt,_,_, locals, intxt)
          = statementFromFun(argvals, fname, iargs, oargs, tyVars, intxt, outtxt, locals, tplPackage, sinfo2);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln(" NORET_CALL stmt =\n" + stmtsString({stmt}));
        end if;
        stmts = stmt::stmts;

        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromExp(exp, {}, stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);

      then ( stmts, locals, scEnv, accMMDecls, intxt);

    case ( (LET(letExp = (NORET_CALL(name = fname),sinfo2)), _),
           _, _, _, _, _, _, tplPackage as TEMPL_PACKAGE(), _ )
      equation
        (fname,_, oargs,_) = getFunSignature(fname, sinfo2, tplPackage);
        //fprint(Flags.FAILTRACE," after fname = " + pathIdentString(fname) + "\n");
        (_::_) = oargs;

        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("Error - NORET_CALL with a '" + pathIdentString(fname) + "' template or function that has output argument(s).\n");
        end if;
      then fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!statementsFromExp failed\n");
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!statementsFromExpList failed\n");
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
      Ident optid;

    //ok, no options
    case ( {} ) then ();

    //warning - more options than expected
    case ( (optid,_) ::_ )
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - more options specified than expected for an expression (first option is '" + optid + "').\n");
       then fail();

    //cannot happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- warnIfSomeOptions failed.\n");
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
      ScopeEnv scEnv;
      TypedIdents locals;
      tuple<MMExp, TypeSignature>  defoptval;
      MMExp  mmarg;
      TypeSignature  exptype, opttype;
      SourceInfo sinfo;
      Expression    optexp;
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
    case ( (optid,NONE()) :: opts, accMMEscOpts,
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
        ((mmarg,exptype,sinfo), stmts, locals, scEnv, accMMDecls)
          = statementsFromArg(optexp, stmts, locals, scEnv, tplPackage, accMMDecls);
        (mmarg, stmts, locals) = typeAdaptMMOption(mmarg, exptype, sinfo, opttype, stmts, locals, astdefs);
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - an unknown option'" + optid + "' was specified. \n");
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
          = statementsFromEscOptions(opts, accMMEscOpts, stmts, locals, scEnv, tplPackage, accMMDecls);
      then
        fail();
        //(accMMEscOpts, stmts, locals, scEnv, accMMDecls);

    //warning - duplicit option
    case ( (optid, _) :: opts, accMMEscOpts,
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        _ = lookupTupleList(defaultEscOptions, optid);
        _ = lookupTupleList(accMMEscOpts, optid);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Warning - a duplicit option'" + optid + "' was specified. It will be ignored (not evaluated).\n");
        (accMMEscOpts, stmts, locals, scEnv, accMMDecls)
         = statementsFromEscOptions(opts, accMMEscOpts, stmts, locals, scEnv, tplPackage, accMMDecls);
      then
         (accMMEscOpts, stmts, locals, scEnv, accMMDecls);

    //can fail on error
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace(" -statementsFromEscOptions failed\n");
      then
        fail();
  end matchcontinue;
end statementsFromEscOptions;


public function getExpListForMap
  input Expression inExp;
  output list<Expression> outExpsForMap;
algorithm
  outExpsForMap := match inExp
    local
      list<Expression> explst;

    case ( (MAP_ARG_LIST(parts = explst), _) )  then explst;
    else {inExp};
  end match;
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

    case ( mmopts, _, _, stmts, popstmts, intxt, _)
      //equation
        //failure(((mmexp,_), mmopts) = lookupDeleteTupleList(mmopts, optid));
      then ( mmopts, stmts, popstmts, intxt);

    //cannot happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!pushPopBlock failed\n");
      then
        fail();
  end matchcontinue;
end pushPopBlock;

/*
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

    //when the function is a non-template function
    //and the signature has the only one argument and none is specified on the call
    // assume the 'it'
    //- case with an output argument (check if it is not a template function with no argument - i.e. only one text input argument)
    case ( {}, { iarg }, oarg :: _ , tplPackage)
      equation
        failure(areTextInOutArgs(iarg, oarg, tplPackage));
      then { BOUND_VALUE(IDENT("it")) };

    //when the function is a non-template function
    //and the signature has the only one argument and none is specified on the call
    // assume the 'it'
    //- case with no output argument (evidently a no-ret non-template function)
    case ( {}, { iarg }, {} , tplPackage)
      then { BOUND_VALUE(IDENT("it")) };


    //otherwise no change
    else inArgLst;

  end matchcontinue;
end addImplicitArgument;
*/

public function statementsFromArg
  input Expression inExp;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage;
  input list<MMDeclaration> inAccMMDecls;

  output tuple<MMExp, TypeSignature, SourceInfo> outArgValue;
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
      Ident  outtxt;
      list<Ident> tyVars;
      TypedIdents locals;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      MMExp mmexp;
      PathIdent path, fname;
      TypeSignature idtype,  rettype, littype;
      list<Expression> explst;
      SourceInfo sinfo;
      TypedIdents iargs, oargs;
      Expression exp;
      String litvalue, fileName, lineStr, colStr;
      StringToken st;
      Integer lineNumberStart, columnNumberStart;

      TemplPackage tplPackage;
      list<MMDeclaration> accMMDecls;

    case ( (LITERAL(value = litvalue, litType = littype), sinfo),
           stmts, locals, scEnv, _, accMMDecls )
      then ( (MM_LITERAL(litvalue),littype,sinfo), stmts, locals, scEnv, accMMDecls);

    case ( (STR_TOKEN(value = st), sinfo),
           stmts, locals, scEnv, _, accMMDecls )
      then ( (MM_STR_TOKEN(st),STRING_TOKEN_TYPE(),sinfo), stmts, locals, scEnv, accMMDecls);

    case ( (BOUND_VALUE(boundPath = path), sinfo),
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        //Debug.fprint(Flags.FAILTRACE,"\n arg BOUND_VALUE resolving boundPath = " + pathIdentString(path) + "\n");
        (mmexp, idtype, scEnv) = resolveBoundPath(path, scEnv, tplPackage);
        checkResolvedType(path, idtype, "argument", sinfo);
        //Debug.fprint(Flags.FAILTRACE," arg BOUND_VALUE resolved mmexp = " + mmExpString(mmexp) + " : "
        //             + typeSignatureString(idtype) + "\n");
      then ( (mmexp,idtype,sinfo), stmts, locals, scEnv, accMMDecls);

    //or embed it into the FUN_CALL ??... --> match
    case ( (FUN_CALL(name = IDENT("sourceInfo"), args = {}),
            sinfo as SOURCEINFO(fileName = fileName, lineNumberStart = lineNumberStart, columnNumberStart = columnNumberStart)),
           stmts, locals, scEnv, _, accMMDecls )
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace(" arg sourceInfo \n");
        end if;
        fname = PATH_IDENT("Tpl", IDENT("sourceInfo"));
        rettype = NAMED_TYPE(PATH_IDENT("builtin", IDENT("SourceInfo")));
        lineStr = intString(lineNumberStart);
        colStr = intString(columnNumberStart);
        mmexp = MM_FN_CALL(fname, { MM_STRING(fileName), MM_LITERAL(lineStr), MM_LITERAL(colStr) });
      then ( (mmexp, rettype, sinfo), stmts, locals, scEnv, accMMDecls);


    case ( (FUN_CALL(name = fname, args = explst), sinfo),
           stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        (fname, iargs, oargs, tyVars) = getFunSignature(fname, sinfo, tplPackage);
        //explst = addImplicitArgument(explst, iargs, oargs, tplPackage);
        (argvals, stmts, locals, scEnv, accMMDecls)
           = statementsFromArgList(explst, stmts, locals, scEnv, tplPackage, accMMDecls);
        outtxt = textTempVarNamePrefix + intString(listLength(locals));
        (_, stmt, mmexp, rettype, locals, outtxt)
           = statementFromFun(argvals, fname, iargs, oargs, tyVars, emptyTxt, outtxt, locals, tplPackage, sinfo);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln(" arg FUN_CALL stmt =\n" + stmtsString({stmt}));
        end if;
        //if emptyList in case of non-template function, not to be included to locals
        locals = addLocalValue(outtxt, TEXT_TYPE(), locals);
      then ( (mmexp, rettype, sinfo), stmt :: stmts, locals, scEnv, accMMDecls);

    //previous fail on error, go on
    //case ( (FUN_CALL(name = fname, args = explst), sinfo),
    //       stmts, locals, scEnv, tplPackage, accMMDecls )
    //  equation
    //      //TODO: make this nicer ?
    //      mmexp = MM_FN_CALL(IDENT("#ERROR#"), {});
    //      rettype = UNRESOLVED_TYPE("#ERROR#");
    //    then ( (mmexp, rettype, sinfo), stmts, locals, scEnv, accMMDecls);

    // all the other are texts:
    // TEMPLATE, CONDITION, MATCH, MAP, MAP_ARG_LIST (forced MV separation - cannot construct true lists),
    // ESCAPED and INDENTATION
    case ( exp as (_,sinfo), stmts, locals, scEnv, tplPackage, accMMDecls )
      equation
        outtxt = textTempVarNamePrefix + intString(listLength(locals));
        (stmts, locals, scEnv, accMMDecls, outtxt)
          = statementsFromExp(exp, {}, stmts, emptyTxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
        locals = addLocalValue(outtxt, TEXT_TYPE(), locals); //if emptyList, not to be included to locals
        mmexp = MM_IDENT(IDENT(outtxt));
      then ( (mmexp, TEXT_TYPE(),sinfo), stmts, locals, scEnv, accMMDecls);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!statementsFromArg failed\n");
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

  output list<tuple<MMExp, TypeSignature, SourceInfo>> outArgValues;
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
      tuple<MMExp, TypeSignature, SourceInfo> argval;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!statementsFromArgList failed\n");
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
  annotation(__OpenModelica_EarlyInline = true);
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
  annotation(__OpenModelica_EarlyInline = true);
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
  input SourceInfo inSourceInfo;
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
  := matchcontinue (inHasRetValue, inMMExp, inType, inSourceInfo, inMMEscOptions, inStmts, inInText, inOutText, inLocals, inScopeEnv, inTplPackage, inAccMMDecls)
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
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      MapContext mapctx;
      list<MMEscOption> mmopts;

    //it is not a ret value,
    //if it is from a temlate call or a non-template call without a return value,
    //the statement is already added, nothing to do here
    case (false, _, _, _, _, stmts, intxt, _, locals, scEnv, _,  accMMDecls)
      then
        ( stmts, locals, scEnv, accMMDecls, intxt);

    //an option -> match it case SOME(val) then val // if exp = SOME(val) then val
    case (_, mmexp, exptype as OPTION_TYPE(), _, mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        //internal encodeing of val is not needed as the val is bound tightly, it hides possible val from upper scope
        // /* encode the val as "val." that will be encoded as _val_ that is impossible to create from a source code -> no name collision */
        (argvals, fname, iargs, oargs, scEnv, accMMDecls)
          = makeMatchFun((mmexp, exptype, inSourceInfo),
              {(SOME_MATCH(BIND_MATCH("val")), (BOUND_VALUE(IDENT("val")),dummySourceInfo) ) },
              emptyExpression, //ignore the argument
              true, scEnv, tplPackage, accMMDecls);
        (_, stmt, _, _, locals, intxt)
          = statementFromFun(argvals, fname, iargs, oargs, {}, intxt, outtxt, locals, tplPackage, inSourceInfo);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, intxt);

    //a list expression -> concat
    case (_, mmexp, exptype as LIST_TYPE(), _, mmopts, stmts, intxt, outtxt, locals, scEnv, tplPackage,  accMMDecls)
      equation
        mapctx = MAP_CONTEXT(BIND_MATCH("it"), (BOUND_VALUE(IDENT("it")),dummySourceInfo) , mmopts, NONE(), false);
        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(true, {(mmexp, exptype,inSourceInfo)}, mapctx,
               stmts, intxt, outtxt, locals, scEnv, tplPackage, accMMDecls);
      then
        ( stmts, locals, scEnv, accMMDecls, intxt);

    //string const - inline or defined by the user as an ident
    case (_, mmexp, STRING_TOKEN_TYPE(), _, mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeTok", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);

    //text -> writeText
    case (_, mmexp, TEXT_TYPE(), _, mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        stmt = tplStatement("writeText", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);

    //try to-string conversion
    case (_, mmexp, exptype, _, mmopts, stmts, intxt, outtxt, locals, scEnv, _,  accMMDecls)
      equation
        warnIfSomeOptions(mmopts);
        mmexp = mmExpToString(mmexp, exptype, inSourceInfo);
        stmt = tplStatement("writeStr", {mmexp}, intxt, outtxt);
      then
        ( (stmt :: stmts), locals, scEnv, accMMDecls, outtxt);

    //fail / error - is in  mmExpToString
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addWriteCallFromMMExp failed\n");
      then
        fail();
  end matchcontinue;
end addWriteCallFromMMExp;

//no fail
public function mmExpToString
  input MMExp inMMExp;
  input TypeSignature inType;
  input SourceInfo inSourceInfo;

  output MMExp outMMExp;
algorithm
  outMMExp := matchcontinue (inMMExp, inType, inSourceInfo)
    local
      MMExp mmexp;
      String reason, str;
      StringToken st;
      TypeSignature ts;

    case (mmexp, STRING_TYPE(), _)
      then
        mmexp;

    //a literal constant to string - inline it as a special MM_STRING
    case (MM_LITERAL(value = str), _, _)
      then
        MM_STRING(str);

    //an inlined string constant, can be inlined as MM_STRING
    case (MM_STR_TOKEN(value = st), _, _)
      equation
        str = Tpl.strTokString(st);
      then
        MM_STRING(str);

    //runtime strTokString
    case (mmexp, STRING_TOKEN_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("strTokString")), { mmexp });

    //runtime textString
    case (mmexp, TEXT_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl",IDENT("textString")), { mmexp });

    //runtime integer type conversion
    case (mmexp, INTEGER_TYPE(), _)
      then
        MM_FN_CALL(IDENT("intString"),{ mmexp });

    //runtime real type conversion
    case (mmexp, REAL_TYPE(), _)
      then
        MM_FN_CALL(IDENT("realString"),{ mmexp });

    //runtime boolean type conversion
    case (mmexp, BOOLEAN_TYPE(), _)
      then
        MM_FN_CALL(PATH_IDENT("Tpl", IDENT("booleanString")),{ mmexp });


    //trying to convert an unresolved value
    //it is already reported as an error, just embed and continue
    //or it is an illegal no-ret fun call (to be auto-converted to "" in the future??)
    case (mmexp, UNRESOLVED_TYPE(reason = reason), _)
      equation
        reason = "#UnresType# " + reason + " #";
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("Error - an unresolved value trying to convert to string. Unresolution reason:\n    " + reason);
        end if;
      then
        MM_FN_CALL(IDENT(reason),{ mmexp });

    //trying to convert a value when there is no conversion for its type
    case (mmexp, ts, _)
      equation
        str = "Elaborated expression '" + mmExpString(mmexp) + "' of type '"
           + typeSignatureString(ts) + "' has no automatic to-string conversion.";
        addSusanError(str, inSourceInfo);
        reason = "Error# " + str + " #";
      then
        MM_FN_CALL(IDENT(reason),{ mmexp });

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!mmExpToString failed\n");
      then
        fail();
  end matchcontinue;
end mmExpToString;


public function statementFromFun
  input list<tuple<MMExp, TypeSignature, SourceInfo>> inArgValues;
  input PathIdent inFunName;
  input TypedIdents inInArgs;
  input TypedIdents inOutArgs;
  input list<Ident> inTypeVars;
  input Ident inInText;
  input Ident inOutText;
  input TypedIdents inLocals;
  input TemplPackage inTplPackage;
  input SourceInfo inInfo;

  output Boolean outHasRetValue;
  output MMExp outStmt;
  output MMExp outRetMMExp;
  output TypeSignature outRetType;
  output TypedIdents outLocals;
  output Ident outOutText;
algorithm
  (outHasRetValue, outStmt, outRetMMExp, outRetType, outLocals, outOutText)
    := matchcontinue (inArgValues, inFunName, inInArgs, inOutArgs, inTypeVars, inInText, inOutText, inLocals, inTplPackage, inInfo)
    local

      PathIdent fname;
      TypedIdents iargs, oargs, locals, setTyVars;
      tuple<Ident,TypeSignature> iarg, oarg;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      list<tuple<MMExp, TypeSignature>> errArgVals;
      list<MMExp> mmargs;

      Ident     intxt, outtxt, retval;
      list<Ident> lhsArgs, tyVars;
      TypeSignature  outtype;
      TemplPackage tplPackage;
      list<ASTDef> astDefs;
      MMExp mmexp,  mmtxt;
      String  str;


    //simple template function - one implicit text argument
    //- make a template call statement and return the out argument
    case (argvals, fname, ( iarg  :: iargs ),  { oarg }, tyVars,
          intxt, outtxt, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), _)
      equation
        areTextInOutArgs(iarg, oarg, tplPackage); //texts and equal or equal without conventional prefixes in/out, i.e. inId = outId
        //equality(listLength(argvals) = listLength(iargs));
        (mmargs,_) = typeAdaptMMArgsForFun(argvals, iargs, tyVars, {}, astDefs);
        mmtxt = MM_IDENT(IDENT(outtxt));
        mmexp = MM_FN_CALL(fname, MM_IDENT(IDENT(intxt)) :: mmargs);
      then
        (false, MM_ASSIGN({outtxt}, mmexp), mmtxt, TEXT_TYPE(), locals, outtxt );

    //multi output template function - one implicit text argument + extra text in/out arguments
    //- make a template call statement and return only the first out argument
    case (argvals, fname,
           ( iarg :: iargs ),
           ( oarg :: (oargs as (_::_)) ), tyVars,
           intxt, outtxt, locals, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), _)
      equation
        areTextInOutArgs(iarg, oarg, tplPackage); //texts and equal or equal without conventional prefixes in/out, i.e. inId = outId
        //equality(listLength(argvals) = listLength(iargs));
        (mmargs,_) = typeAdaptMMArgsForFun(argvals, iargs, tyVars, {}, astDefs);
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage); //assuming the same lengths (from above typeAdaptMMArgsForFun)
        lhsArgs = outtxt :: lhsArgs;
        mmtxt = MM_IDENT(IDENT(outtxt));
        mmexp = MM_FN_CALL(fname, (MM_IDENT(IDENT(intxt)) :: mmargs) );
      then
        (false, MM_ASSIGN(lhsArgs, mmexp), mmtxt, TEXT_TYPE(), locals, outtxt );

    //a non-template function - no implicit text argument
    //one return value
    //- make a locally bound return value and assign the function to it
    case (argvals, fname, iargs,  { (_, outtype) }, tyVars,
         intxt, _, locals, TEMPL_PACKAGE(astDefs = astDefs), _)
      equation
        //equality(listLength(argvals) = listLength(iargs));
        (mmargs, setTyVars) = typeAdaptMMArgsForFun(argvals, iargs, tyVars, {}, astDefs);
        outtype = specializeType(outtype, tyVars, setTyVars);
        //make a separate locally bound return value
        retval = returnTempVarNamePrefix + intString(listLength(locals));
        locals = addLocalValue(retval, outtype, locals);
        mmexp = MM_FN_CALL(fname, mmargs);
      then
        ( true, MM_ASSIGN({retval}, mmexp), MM_IDENT(IDENT(retval)), outtype, locals, intxt );

    //---no--- TODO: move this to be available only for # context
    //TODO: lagalize this to be convertible to string, so that an effective result is ""
    //a non-template function - no implicit text argument
    //no return value - i.e. an intrinsic call like <# fun(arg) #>
    //- inline it as it is
    case (argvals, fname, iargs,  {}, tyVars,
          intxt, _, locals, TEMPL_PACKAGE(astDefs = astDefs), _)
      equation
        //equality(listLength(argvals) = listLength(iargs));
        (mmargs,_) = typeAdaptMMArgsForFun(argvals, iargs, tyVars, {}, astDefs);
        mmexp = MM_FN_CALL(fname, mmargs);
      then
        //perhaps, UNIT_TYPE() or VOID_TYPE will fit here better
        ( false, mmexp, mmexp, UNRESOLVED_TYPE("No return value."), locals, intxt );

    case (argvals, fname, iargs,  oargs, _, _, _, _, _, _)
      equation
        errArgVals = List.map(argvals, Util.tuple312);
        str = "Cannot elaborate function\n  "
          + Tpl.tplString3(TplCodegen.sFunSignature, fname, iargs, oargs)
          + "\n  for actual parameters  "
          + Tpl.tplString(TplCodegen.sActualMMParams, errArgVals)
          + "\n  --> Invalid types (cannot convert) or number of in/out arguments (text in/out arguments must match by order and name equality where prefixes 'in' and 'out' can be used; A function has valid template signature only if all text out params have corresponding in text arguments.).\n";
        addSusanError(str,inInfo);
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

    // equals with no prefix ... internal only for defined tempates
    case ((inid,itype), (outid,otype), TEMPL_PACKAGE(astDefs = astdefs))
      equation
        true = stringEq(inid, outid);
        TEXT_TYPE() = deAliasedType(itype, astdefs);
        TEXT_TYPE() = deAliasedType(otype, astdefs);
      then
        ();

    // equals with usage of in/out prefixes ... for external templates from an ast definition
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
  input list<tuple<MMExp, TypeSignature, SourceInfo>> inArgValues;
  input TypedIdents inInArgs;
  input list<Ident> inTypeVars;
  input TypedIdents inSetTypeVars;
  input list<ASTDef> inASTDefs;

  output list<MMExp> outMMArguments;
  output TypedIdents outSetTypeVars;
algorithm
  (outMMArguments,outSetTypeVars)
  := matchcontinue (inArgValues, inInArgs, inTypeVars, inSetTypeVars, inASTDefs)
    local
      TypedIdents iargs, setTyVars;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      SourceInfo sinfo;
      MMExp mmarg;
      list<MMExp> mmargs;
      TypeSignature argtype, sigArgtype;
      list<ASTDef> astdefs;
      list<Ident> tyVars;

    case ( {}, {}, _,setTyVars,  _)
      then
        ({}, setTyVars);

    case ( (mmarg, argtype, sinfo) :: argvals, (_, sigArgtype) :: iargs, tyVars, setTyVars, astdefs)
      equation
        argtype = deAliasedType(argtype, astdefs);
        (mmarg, setTyVars) = typeAdaptMMArg(mmarg, argtype, sinfo, true, sigArgtype, tyVars, setTyVars, astdefs);
        (mmargs, setTyVars) = typeAdaptMMArgsForFun(argvals, iargs, tyVars, setTyVars, astdefs);
      then
        ( mmarg :: mmargs, setTyVars );

    case ( {}, (_ :: _), _,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - more arguments expected for a function.\n");
      then
        fail();

    case ( (_ :: _), {}, _,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - less number of arguments expected for a function.\n");
      then
        fail();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!! - typeAdaptMMArgsForFun failed\n");
      then
        fail();
  end matchcontinue;
end typeAdaptMMArgsForFun;


public function typeAdaptMMArg
  input MMExp inMMArg;
  input TypeSignature inArgType "assumed to be dealiased";
  input SourceInfo inSourceInfo;
  input Boolean errorWhenFail;
  input TypeSignature inTargetType "not dealiased - must check for type vars first";
  input list<Ident> inTypeVars;
  input TypedIdents inSetTypeVars;
  input list<ASTDef> inASTDefs;

  output MMExp outMMArg;
  output TypedIdents outSetTypeVars;
algorithm
  (outMMArg, outSetTypeVars)
  := matchcontinue (inMMArg, inArgType, inSourceInfo, errorWhenFail, inTargetType, inTypeVars, inSetTypeVars, inASTDefs)
    local
      TypedIdents  setTyVars;
      MMExp mmarg, mmexp;
      TypeSignature argtype, targettype;
      list<ASTDef> astdefs;
      list<Ident> tyVars;
      SourceInfo sinfo;
      String msg;


    //special case when argtype is STRING_TOKEN_TYPE()
    //to-string conversion will take precedence (is default) when targettype is an unbound type variable
    //this is to prevent the surprise when imported function with type variable has a template expression as argument (the result is converted to string by default as user would expect intuitively)
    case ( mmexp, argtype as STRING_TOKEN_TYPE(), sinfo, _, targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, STRING_TYPE(), tyVars, setTyVars, astdefs);
        mmarg = mmExpToString(mmexp, argtype, sinfo);
      then
        (mmarg, setTyVars);

    //special case when argtype is TEXT_TYPE()
    //to-string conversion will take precedence (is default) when targettype is an unbound type variable
    //this is to prevent the surprise when imported function with type variable has a template expression as argument (the result is converted to string by default as user would expect intuitively)
    case ( mmexp, argtype as TEXT_TYPE(), sinfo, _,targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, STRING_TYPE(), tyVars, setTyVars, astdefs);
        mmarg = mmExpToString(mmexp, argtype, sinfo);
      then
        (mmarg, setTyVars);


    //no conversion when equal ...
    case ( mmarg, argtype, _, _, targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, argtype, tyVars, setTyVars, astdefs);
      then
        (mmarg, setTyVars);

    //convert to string when tagettype = STRING_TYPE()
    case ( mmexp, argtype, sinfo, _, targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, STRING_TYPE(), tyVars, setTyVars, astdefs);
        mmarg = mmExpToString(mmexp, argtype, sinfo);
      then
        (mmarg, setTyVars);


    ////when target type is TEXT_TYPE() ... special case
    //strTokText -> directly TEXT_TYPE()
    case ( mmarg, STRING_TOKEN_TYPE(), _, _, targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, TEXT_TYPE(), tyVars, setTyVars, astdefs);
      then
        ( MM_FN_CALL(PATH_IDENT("Tpl",IDENT("strTokText")), { mmarg }),  setTyVars);




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

    //when target type is TEXT_TYPE()
    // _ -> text ... to string and -> text
    case ( mmarg, argtype, sinfo, _, targettype, tyVars, setTyVars, astdefs)
      equation
        setTyVars = typesEqual(targettype, TEXT_TYPE(), tyVars, setTyVars, astdefs);
        mmarg = mmExpToString(mmarg, argtype, sinfo);
      then
        ( MM_FN_CALL(PATH_IDENT("Tpl",IDENT("stringText")), { mmarg }),  setTyVars);

    //no fail branch
    case ( mmarg, argtype, sinfo, true, targettype,_,setTyVars,_)
      equation
        msg = "Elaborated expression '" + mmExpString(mmarg) + "' of type '"
           + typeSignatureString(argtype)
           + "' failed to type adapt to its inferred type '"
           + typeSignatureString(targettype) + "'.";
        addSusanError(msg, sinfo);
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeAdaptMMArg failed\n");
        msg = "#Error# " + msg + " #";
      then
        ( MM_FN_CALL(IDENT(msg),{ mmarg }), setTyVars);

    //fail when no case is useful and no error shoud be reported
    case ( _, _, _, false, _,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Fail branch- typeAdaptMMArg failed\n");
      then
        fail();
  end matchcontinue;
end typeAdaptMMArg;


public function typeAdaptMMOption
  input MMExp inMMArg;
  input TypeSignature inArgType;
  input SourceInfo sinfo;
  input TypeSignature inTargetType;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input list<ASTDef> inASTDefs;

  output MMExp outMMArg;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outMMArg, outStmts, outLocals) :=
  matchcontinue (inMMArg, inArgType, sinfo, inTargetType, inStmts, inLocals, inASTDefs)
    local
      MMExp mmarg;
      TypeSignature argtype, targettype;
      list<ASTDef> astdefs;
      list<MMExp> stmts;
      TypedIdents locals;

    //concrete type to its option SOME - when from a value of the concrete type
    case ( mmarg, argtype, _, OPTION_TYPE(ofType = targettype), stmts, locals, astdefs)
      equation
        targettype = deAliasedType(targettype, astdefs);
        (mmarg, stmts, locals) = typeAdaptMMOption(mmarg, argtype, sinfo, targettype, stmts, locals, astdefs);
        mmarg = MM_FN_CALL(IDENT("SOME"), { mmarg });
      then
        (mmarg, stmts, locals);

    case ( mmarg, argtype, _, targettype, stmts, locals, astdefs)
      equation
        argtype = deAliasedType(argtype, astdefs);
        (mmarg,_) = typeAdaptMMArg(mmarg, argtype, sinfo, false, targettype, {}, {}, astdefs);
        (mmarg, stmts, locals) = mmEnsureNonFunctionArg(mmarg, targettype, stmts, locals);
      then
        (mmarg, stmts, locals);

    //textStrTok -  when from a template
    case ( mmarg, TEXT_TYPE(), _, STRING_TOKEN_TYPE(), stmts, locals, _)
      equation
        mmarg = MM_FN_CALL(PATH_IDENT("Tpl",IDENT("textStrTok")), { mmarg });
        (mmarg, stmts, locals) = mmEnsureNonFunctionArg(mmarg, STRING_TOKEN_TYPE(), stmts, locals);
      then
        (mmarg, stmts, locals);

    //stringStrTok - when from a value of type string or others (int, real, bool)
    case ( mmarg, argtype, _, STRING_TOKEN_TYPE(), stmts, locals, _)
      equation
        mmarg = mmExpToString(mmarg, argtype, sinfo);
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeAdaptMMOption failed\n");
      then
        fail();
  end matchcontinue;
end typeAdaptMMOption;


public function mmEnsureNonFunctionArg
  input MMExp inMMArg;
  input TypeSignature inTargetType;
  //input SourceInfo sinfo;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;

  output MMExp outMMArg;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outMMArg, outStmts, outLocals) :=
  matchcontinue (inMMArg, inTargetType, inStmts, inLocals)
    local
      MMExp mmarg;
      TypeSignature  targettype;
      String  retval;
      list<MMExp> stmts;
      TypedIdents locals;

    case ( mmarg as MM_FN_CALL(), targettype, stmts, locals)
      equation
         //make a separate locally bound return value
        retval = returnTempVarNamePrefix + intString(listLength(locals));
        locals = addLocalValue(retval, targettype, locals);
        stmts = MM_ASSIGN({retval}, mmarg) :: stmts;
      then
        (MM_IDENT(IDENT(retval)), stmts, locals);

    case ( mmarg, _, stmts, locals)
      equation
        failure(MM_FN_CALL() = mmarg);
      then
        (mmarg, stmts, locals);

    //may fail, when addLocalValue fails
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!- mmEnsureNonFunctionArg failed\n");
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
      list<MMExp> mmargs;
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
    case ( MM_IDENT(IDENT(txtarg)) :: mmargs, _ :: iargs, _ :: oargs, tplPackage)
      equation
        // obsolete ... "_" = stringGetStringChar(txtarg, 1);
        //areEqualInOutArgs(iarg , oarg);
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage);
      then
        ( txtarg :: lhsArgs );

    //a text argument that is input and output
    //an actual parameter is not a local text value (it is a constant/function) - put it as '_'
    case ( _ :: mmargs, _ :: iargs, _ :: oargs, tplPackage)
      equation
        //failure(MM_IDENT(IDENT()) = mmarg);
        //failure("_" = stringGetStringChar(txtarg, 1));
        //areEqualInOutArgs(iarg , oarg);
        lhsArgs = elabOutTextArgs(mmargs, iargs, oargs, tplPackage);
      then
        ( "_" :: lhsArgs );

    case ( {}, {}, _::_, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - inconsistent in/out Text arguments for a template function (Output texts are not a subset of input texts).\n");
      then
        fail();

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("!!!- elabOutTextArgs failed\n");
      then
        fail();
  end matchcontinue;
end elabOutTextArgs;


public function statementsFromMapExp
  input Boolean inIsFirstArgToMap;
  input list<tuple<MMExp, TypeSignature,SourceInfo>> inArgValuesToMap;
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
      Ident intxt, outtxt, fname,   idxName, freshIdxName;
      TypedIdents locals,  localArgs, encodedExtargs, maplocals, caseLocals,   iargs, oargs;
      MapContext mapctx;
      TemplPackage tplPackage;
      list<MMDeclaration> accMMDecls;
      tuple<MMExp, TypeSignature, SourceInfo>  argtomap;
      list<tuple<MMExp, TypeSignature, SourceInfo>> extargvals, inMapExtargvals, restargs;
      MatchingExp ofbind, ofbindEnc, mexp;
      Expression mapexp;
      list<MMEscOption> iopts;
      list<ASTDef> astDefs;
      MMMatchCase mmmcEmptyList, mmmcCons, mmFailCons;
      Boolean isfirst, useiter,  isUsed;
      MMDeclaration mmFun;
      list<tuple<MatchingExp, TypedIdents, list<MMExp>>> elabcases;
      list<MMMatchCase> mmmcases;
      list<Ident> lhsArgs, assignedIdents;
      Option <Ident> hasIndexIdentOpt;
      list<tuple<Ident, Ident>> localNames;
      SourceInfo sinfo;

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
    case ( isfirst, (argtomap as (_,argtype,_)) :: restargs,
             MAP_CONTEXT(ofBinding = ofbind,
                         mapExp = mapexp as (_,sinfo),
                         iterMMExpOptions = iopts,
                         hasIndexIdentOpt = hasIndexIdentOpt,
                         useIter = useiter),
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        LIST_TYPE(ofType = oftype) = deAliasedType(argtype, astDefs);

        ofbindEnc = typeCheckMatchingExp(ofbind, oftype, astDefs);
        //ofbindEnc = encodeMatchingExp(ofbindEnc);
        idxName = Util.getOptionOrDefault(hasIndexIdentOpt, impossibleIdent);
        freshIdxName = indexNamePrefix + idxName;// + "_" + intString(listLength(locals));

        //i0ti = ("i_i0",INTEGER_TYPE());
        //i1ti = ("i_i1",INTEGER_TYPE());
        //elaborate statemennts and gather extra arguments and usage of i0 and i1
        (mapstmts, maplocals, scEnv, accMMDecls, _)
          = statementsFromExp(mapexp,{}, {}, imlicitTxt, imlicitTxt, {},
              LET_SCOPE(idxName, INTEGER_TYPE(), freshIdxName, false)
              :: CASE_SCOPE(ofbindEnc, oftype, {}, {}, {}, impossibleIdent, true)
              :: FUN_SCOPE({},{})
              :: scEnv,
              tplPackage, accMMDecls);
        (LET_SCOPE(_, _, _, isUsed)
         :: CASE_SCOPE(mexp, _, localNames, caseLocals, encodedExtargs, _, _)
         :: FUN_SCOPE(_,localArgs)
         :: scEnv) = scEnv; //releaseImmediateLocalScope(scEnv);

        (mexp,_) = rewriteMatchExpByLocalNames(mexp, oftype, localNames,{}, astDefs);
        maplocals = listAppend(caseLocals, maplocals);

        //put nextIter() if needed
        useiter = shouldUseIterFunctions(isfirst, useiter, true, isUsed, iopts, restargs);
        //add nextIter() if needed
        stmt = tplStatement("nextIter", {}, imlicitTxt, imlicitTxt);
        mapstmts = if useiter then stmt :: mapstmts else mapstmts;
        //(mapstmts,_) = addNextIter(useiter, mapstmts, imlicitTxt, imlicitTxt);
        //create a new list-map function
        fname = listMapFunPrefix + intString(listLength(accMMDecls));
        iargs = imlicitTxtArg :: ("items",argtype) :: encodedExtargs;
        assignedIdents = getAssignedIdents(mapstmts, {});
        //oargs = List.filter(extargs, isText);
        oargs = List.filter1(encodedExtargs, isAssignedText, assignedIdents);
        oargs = imlicitTxtArg :: oargs;
        lhsArgs = List.map(oargs, Util.tuple21);
        inMapExtargvals =  List.map(encodedExtargs, makeMMArgValue);
        rhsMMArgs = List.map(inMapExtargvals, Util.tuple31);
        //recursive call
        mmRecCall = MM_ASSIGN(
            lhsArgs,
            MM_FN_CALL(IDENT(fname), MM_IDENT(IDENT(imlicitTxt)) :: MM_IDENT(IDENT("rest")) :: rhsMMArgs)
        );
        //add the recursive call for the "rest" and revese statemnts
        mapstmts = listReverse(mmRecCall :: mapstmts);
        //add indexed value if needed
        (mapstmts, maplocals)
          = addGetIndex(isUsed, freshIdxName, mapstmts, imlicitTxt, maplocals);

        //make the empty case, cons case and a failing cons case (only recusive call for the rest)
        mmmcEmptyList = makeMMMatchCase( (LIST_MATCH({}), {},{}), encodedExtargs, oargs);
        mmmcCons = makeMMMatchCase(
          (LIST_CONS_MATCH(mexp, BIND_MATCH("rest")), encodedExtargs, mapstmts),
          encodedExtargs, oargs);
        //TODO: the fail recursive call could be made conditional, only when the mexp can fail
        // or, maybe, always like it is, to make easier location of failing of (badly)imported functions(they should not fail)
        mmFailCons = makeMMMatchCase(
          (LIST_CONS_MATCH(REST_MATCH(), BIND_MATCH("rest")), encodedExtargs, {mmRecCall}),
          encodedExtargs, oargs);
        mmmcases = if isAlwaysMatchedBool(mexp) then { mmmcEmptyList, mmmcCons } else { mmmcEmptyList, mmmcCons, mmFailCons };
         //  listAppend({ mmmcEmptyList, mmmcCons },
         //  { makeMMMatchCase(
         // (LIST_CONS_MATCH(REST_MATCH(), BIND_MATCH("rest")), encodedExtargs, {mmRecCall}),
         // encodedExtargs, oargs) } );

        mapctx = MAP_CONTEXT(ofbind, mapexp, iopts, hasIndexIdentOpt, useiter);
        maplocals = listAppend(encodedExtargs, maplocals);
        maplocals = imlicitTxtArg :: ("rest",argtype) :: maplocals;

        // make fun
        mmFun = MM_FUN(false,fname, iargs, oargs, maplocals,
                        { MM_MATCH( mmmcases /*{ mmmcEmptyList, mmmcCons, mmFailCons } */ ) },
                        GI_MAP_FUN(argtype, mapctx)
                );

        //add pushIter() if it is the first element of MAP_ARG_LIST (like <[exp1,exp2,...] : mapexp> ) or a simple one (list)exp to be mapped (like <exp of mexp: mapexp>)
        (stmts, intxt) = addPushIter((isfirst and useiter), iopts, stmts, intxt, outtxt);
        extargvals = List.map(localArgs, makeMMArgValue);
        //call the elaborated function
        (_, stmt, _, _, locals, intxt)
          = statementFromFun(argtomap :: extargvals, IDENT(fname), iargs, oargs, {}, intxt, outtxt, locals, tplPackage, sinfo);

        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(false, restargs, mapctx, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, mmFun :: accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    //scalar map - <argtomap of ofbind: mapexp; iopts>
    //TODO: try to inline or eliminate this at all ... design problems with mixed list/scalar arguments in { }, i.e. MAP_ARG_LIST
    case ( isfirst, (argtomap as (_,argtype,_)) :: restargs,
             MAP_CONTEXT(ofBinding = ofbind,
                         mapExp = mapexp as (_,sinfo),
                         iterMMExpOptions = iopts,
                         hasIndexIdentOpt = hasIndexIdentOpt,
                         useIter = useiter),
           stmts, intxt, outtxt, locals, scEnv, tplPackage as TEMPL_PACKAGE(astDefs = astDefs), accMMDecls )
      equation
        failure(LIST_TYPE() = deAliasedType(argtype, astDefs));

        ofbindEnc = typeCheckMatchingExp(ofbind, argtype, astDefs);
        //ofbindEnc = encodeMatchingExp(ofbindEnc);
        idxName = Util.getOptionOrDefault(hasIndexIdentOpt, impossibleIdent);
        freshIdxName = indexNamePrefix + idxName;// + "_" + intString(listLength(locals));

        //i0ti = ("i_i0",INTEGER_TYPE());
        //i1ti = ("i_i1",INTEGER_TYPE());
        //matchArgName = getMatchArgName(inArgExp);//getItNameFromArg(argmmexp, argtype, ofbindEnc, astDefs);

        //elaborate statemennts and gather extra arguments and usage of i0 and i1
        (mapstmts, maplocals, scEnv, accMMDecls, _)
          = statementsFromExp(mapexp,{}, {}, imlicitTxt, imlicitTxt, {},
              LET_SCOPE(idxName, INTEGER_TYPE(), freshIdxName, false)
              :: CASE_SCOPE(ofbindEnc, argtype, {}, {}, {}, impossibleIdent, true)
              :: FUN_SCOPE({},{})
              :: scEnv,
              tplPackage, accMMDecls);
        (LET_SCOPE(_, _, _, isUsed)
         :: CASE_SCOPE(mexp, _, localNames, caseLocals, encodedExtargs, _, _)
         :: FUN_SCOPE(_,localArgs)
         :: scEnv) = scEnv; //releaseImmediateLocalScope(scEnv);

        (mexp,_) = rewriteMatchExpByLocalNames(mexp, argtype, localNames,{}, astDefs);
        maplocals = listAppend(caseLocals, maplocals);

        //put nextIter() if needed
        useiter = shouldUseIterFunctions(isfirst, useiter, false, isUsed, iopts, restargs);

        //make scalar map

        //add nextIter() if needed
        stmt = tplStatement("nextIter", {}, imlicitTxt, imlicitTxt);
        mapstmts = if useiter then stmt :: mapstmts else mapstmts;
        //(mapstmts,_) = addNextIter(useiter, mapstmts, imlicitTxt, imlicitTxt);

        //create a new scalar-map function,
        //where ofbind is not a simple BIND_MATCH -> it must be a match fun
        fname = scalarMapFunPrefix + intString(listLength(accMMDecls));
        iargs = imlicitTxtArg :: ("it",argtype) :: encodedExtargs;
        assignedIdents = getAssignedIdents(mapstmts, {});
        //oargs = List.filter(extargs, isText); //it can be actually Text, but not to be as output stream
        oargs = List.filter1(encodedExtargs, isAssignedText, assignedIdents);
        oargs = imlicitTxtArg :: oargs;
        mapstmts = listReverse(mapstmts);
        //add indexed value if needed
        (mapstmts, maplocals)
          = addGetIndex(isUsed, freshIdxName, mapstmts, imlicitTxt, maplocals);

        elabcases = addRestElabCase({(mexp, encodedExtargs, mapstmts)});
        mmmcases = List.map2(elabcases, makeMMMatchCase, encodedExtargs, oargs);
        mapctx = MAP_CONTEXT(ofbind, mapexp, iopts, hasIndexIdentOpt, useiter);
        maplocals = listAppend(encodedExtargs, maplocals);
        maplocals = imlicitTxtArg :: maplocals;
        // make fun
        mmFun = MM_FUN(false, fname, iargs, oargs,
                       maplocals,
                       { MM_MATCH( mmmcases  ) },
                       GI_MAP_FUN(argtype, mapctx)
                );

        //add pushIter() if it is the first element of MAP_ARG_LIST (like <[exp1,exp2,...] : mapexp> ) or a simple one (list)exp to be mapped (like <exp of mexp: mapexp>)
        (stmts, intxt) = addPushIter((isfirst and useiter), iopts, stmts, intxt, outtxt);
        extargvals = List.map(localArgs, makeMMArgValue);
        //call the elaborated function
        (_, stmt, _, _, locals, intxt)
          = statementFromFun(argtomap :: extargvals, IDENT(fname), iargs, oargs, {}, intxt, outtxt, locals, tplPackage, sinfo);

        (stmts, locals, scEnv, accMMDecls, intxt)
          = statementsFromMapExp(false, restargs, mapctx, stmt::stmts, intxt, outtxt, locals, scEnv, tplPackage, mmFun :: accMMDecls);
      then ( stmts, locals, scEnv, accMMDecls, intxt);

    //may fail on error
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!statementsFromMapExp failed\n");
      then
        fail();
  end matchcontinue;
end statementsFromMapExp;

/*
function isIndexArg
  input tuple<Ident, TypeSignature> inArg;
  output Boolean outIsIndexArg;
algorithm
  outIsIndexArg := match inArg
    case ( ("i_i0" , _) )  then true;
    case ( ("i_i1" , _) )  then true;
    case ( _ )            then false;
  end match;
end isIndexArg;
*/

public function shouldUseIterFunctions
  input Boolean inIsFirstArgToMap;
  input Boolean inUseIterLast;
  input Boolean inIsListArgToMap;
  input Boolean wasIndexVarUsed;
  input list<MMEscOption> inIterOptions;
  input list<tuple<MMExp, TypeSignature, SourceInfo>> inRestArgValsToMap;

  output Boolean outUseIterFuns;
algorithm
  (outUseIterFuns)
  := matchcontinue (inIsFirstArgToMap, inUseIterLast, inIsListArgToMap, wasIndexVarUsed, inIterOptions, inRestArgValsToMap)
    local
      Boolean useiter;
      list<MMEscOption> iopts;

    //already decided by the first argval to be mapped
    case (false, useiter, _, _, _, _)
      then useiter;

    //- list argument to be mapped,
    //- no index var was used,
    //- iter options are like these
    //then there is no usage of the iteration environment from the user expression
    case (true, _, true, false, iopts, _)
      equation
        iopts = listAppend(iopts, nonSpecifiedIterOptions);
        ((MM_LITERAL("NONE()"),_)) = lookupTupleList(iopts, emptyOptionId);
        ((MM_LITERAL("NONE()"),_)) = lookupTupleList(iopts, separatorOptionId);
        ((MM_LITERAL("0"),_))    = lookupTupleList(iopts, alignNumOptionId);
        ((MM_LITERAL("0"),_))    = lookupTupleList(iopts, wrapWidthOptionId);
      then false;

    //- scalar argument to be mapped,
    //- no index var was used,
    //- no empty option specified
    //- this is the only argument to be mapped
    //then there is no usage of the iteration environment from the user expression
    case (true, _, false, false, iopts, {})
      equation
        iopts = listAppend(iopts, nonSpecifiedIterOptions);
        ((MM_LITERAL("NONE()"),_)) = lookupTupleList(iopts, emptyOptionId);
      then false;

    //otherwise use it
    else true;

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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addNextIter failed\n");
      then
        fail();
  end matchcontinue;
end addNextIter;
*/

public function addGetIndex
  input Boolean wasIndexUsed;
  input Ident inLocalIdxValIdent;
  input list<MMExp> inStmts;
  input Ident inInText;
  input TypedIdents inLocals;

  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outStmts, outLocals)
  := matchcontinue (wasIndexUsed, inLocalIdxValIdent, inStmts, inInText, inLocals)
    local
      list<MMExp> stmts;
      MMExp stmt;
      Ident  localidxid, intxt;
      TypedIdents  locals;

    // add the getIter_ix() when the ixti is used by mapexp
    case ( true, localidxid, stmts, intxt, locals)
      equation
        //true = listMember(ixti, foundIdxArgs);
        stmt = tplStatement("getIteri_i0", {}, intxt, localidxid);
        locals = addLocalValue(localidxid, INTEGER_TYPE(), locals);
      then ( stmt :: stmts, locals );

    case ( false, _, stmts, _, locals)
      then ( stmts, locals);

    //should not happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addGetIndex failed\n");
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addNextIter failed\n");
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
      equation
        warnIfSomeOptions(specopts);
      then ({}, specopts);

    case ( (optid, _) :: rest,  specopts )
      equation
        ((mexpopt,_), specopts) = lookupDeleteTupleList(specopts, optid);
        (mexpOpts, specopts) = makeMMExpOptions(rest, specopts);
      then ((mexpopt :: mexpOpts), specopts);

    case ( (_, (mexpopt,_)) :: rest,  specopts )
      equation
        //failure( _ = lookupTupleList(specopts, optid));
        (mexpOpts, specopts) = makeMMExpOptions(rest, specopts);
      then ((mexpopt :: mexpOpts), specopts);

    //cannot happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeMMExpOptions failed\n");
      then
        fail();
  end matchcontinue;
end makeMMExpOptions;

/*
public function mmexpFromStrTokOption
  input Option<StringToken> inStrTokOption;
  output MMExp outMMExp;
algorithm
  outMMExp := match inStrTokOption
    local
      StringToken st;

    case NONE()
      then MM_LITERAL("NONE()");

    case ( SOME(st) )
      then MM_FN_CALL(IDENT("SOME"), { MM_STR_TOKEN(st) });

  end match;
end mmexpFromStrTokOption;
*/

//fail and error
public function makeMatchFun
  input tuple<MMExp, TypeSignature, SourceInfo> inArgval;
  input list<tuple<MatchingExp,Expression>> inMCases;
  input Expression inArgExp "only to identify the original argument name when argument is a bound value";
  input Boolean hasImplicitLookup;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage;
  input list<MMDeclaration> inAccMMDecls;

  output list<tuple<MMExp, TypeSignature, SourceInfo>> outArgvals;
  output PathIdent outFunName;
  output TypedIdents outInArgs;
  output TypedIdents outOutArgs;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;

algorithm
  (outArgvals, outFunName, outInArgs, outOutArgs, outScopeEnv, outMMDecls)
  := matchcontinue (inArgval, inMCases, inArgExp, hasImplicitLookup, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      ScopeEnv scEnv;
      tuple<MMExp, TypeSignature, SourceInfo> argval;
      list<tuple<MMExp, TypeSignature, SourceInfo>> argvals;
      SourceInfo sinfo;
      MMExp mmexp;
      TypeSignature exptype;
      TypedIdents iargs, oargs, extargs, localArgs, encodedExtargs, funLocals;
      list<tuple<MatchingExp,Expression>> mcases;
      list<tuple<MatchingExp, TypedIdents, list<MMExp>>> elabcases;
      list<MMMatchCase> mmmcases;
      TemplPackage tplPackage;
      list<MMDeclaration> accMMDecls;
      MMDeclaration mmFun;
      Ident fname, matchArgName, implicitValueName;
      list<Ident> assignedIdents;

    case ( argval as (mmexp, exptype, _), mcases, _, _, scEnv, tplPackage, accMMDecls )
      equation
        //TODO: when mmexp is an identifier, it should be made available through implicit context
        //so we will prepend it before each mexp in every case (instead 'it')
        //then, mexps should be cleaned off the unused bindings ??....
        //this is not critical, the value will be now passed as another parameter (a duplicity value)
        (implicitValueName, matchArgName) = getMatchArgName(inArgExp); //path -> pathString encoded ident
        (elabcases, funLocals, (FUN_SCOPE(extargs,localArgs) :: scEnv), accMMDecls, assignedIdents)
          = elabMatchCases((mmexp, exptype) /*argval*/, implicitValueName, mcases, hasImplicitLookup, {}, {}, (FUN_SCOPE( {},{} ) :: scEnv), tplPackage, accMMDecls);
        elabcases = addRestElabCase(elabcases);
        (extargs, localArgs) = alignExtArgsToScopeEnv(extargs, localArgs, scEnv); //order the args by the upper scope -> when the match function will be pulled to the top-level, the arguments must be ordered the same way ... MM stuff

        encodedExtargs = List.map1(extargs, encodeTypedIdent, funArgNamePrefix);

        iargs = imlicitTxtArg :: (matchArgName, exptype) :: encodedExtargs;

        oargs = List.filter1(encodedExtargs, isAssignedText, assignedIdents);
        oargs = imlicitTxtArg :: oargs;

        funLocals = listAppend(encodedExtargs, funLocals);

        mmmcases = List.map2(elabcases, makeMMMatchCase, encodedExtargs, oargs);
        fname = stringAppend(matchFunPrefix, intString(listLength(accMMDecls)));
        mmFun = MM_FUN(false, fname, iargs, oargs,
                  imlicitTxtArg :: funLocals,
                  { MM_MATCH(mmmcases) },
                  GI_MATCH_FUN()
                );
        argvals = List.map(localArgs, makeMMArgValue);
        argvals = argval :: argvals;
      then ( argvals, IDENT(fname), iargs, oargs, scEnv, (mmFun :: accMMDecls));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeMatchFun failed\n");
      then
        fail();
  end matchcontinue;
end makeMatchFun;

//no fail
public function alignExtArgsToScopeEnv
  input TypedIdents inExtraArgs;
  input TypedIdents inEncExtraArgs;
  input ScopeEnv inScopeEnv;

  output TypedIdents outExtraArgs;
  output TypedIdents outEncExtraArgs;
algorithm
  (outExtraArgs,outEncExtraArgs) :=
  matchcontinue (inExtraArgs, inEncExtraArgs, inScopeEnv)
    local
      TypedIdents extargs, encExtargs, extargsAligned, encExtargsAligned, fargs, localArgs;

    case ( extargs, encExtargs,
           FUN_SCOPE(args = fargs, localArgs = localArgs) :: _)
      equation
        extargsAligned = alignTupleList(extargs, fargs);
        encExtargsAligned = alignTupleList(encExtargs, localArgs);
        //assure no lost of arguments, all extra args must come from the function call that takes the args from its args
        true = (listLength(extargsAligned) == listLength(extargs));
        true = (listLength(encExtargsAligned) == listLength(encExtargs));
      then (extargsAligned, encExtargsAligned);

    else (inExtraArgs,inEncExtraArgs);

  end matchcontinue;
end alignExtArgsToScopeEnv;

//no fail
public function getMatchArgName "to enable 'routing' of values via match function argument - preventing unnecessary additional extra arguments"
  input Expression inArgExp;
  output Ident outInputValueName;
  output Ident outMatchArgName;
algorithm
  (outInputValueName, outMatchArgName)
   := matchcontinue inArgExp
    local
      PathIdent path;
    case ( (BOUND_VALUE(path), _) )
      equation
        outInputValueName = pathIdentString(path);
        outMatchArgName = encodeIdent(outInputValueName, funArgNamePrefix);
      then (outInputValueName, outMatchArgName);
    else
      (impossibleIdent, matchDefaultArgName);
  end matchcontinue;
end getMatchArgName;

//no fail
public function makeMMArgValue
  input tuple<Ident,TypeSignature> inTypedIdent;
  output tuple<MMExp, TypeSignature, SourceInfo> outArgValue;
algorithm
  outArgValue := match  inTypedIdent
    local
      Ident argname;
      TypeSignature ts;

    case ( (argname, ts) )  then ( (MM_IDENT(IDENT(argname)) , ts, dummySourceInfo) );

  end match;
end makeMMArgValue;


public function isText
  input tuple<Ident, TypeSignature> inArg;
algorithm
  _:= match(inArg)
    case ( (_ , TEXT_TYPE()) )
      then ();
  end match;
end isText;

function isAssignedText
  input tuple<Ident, TypeSignature> inArg;
  input list<Ident> inAssignedTexts;
algorithm
  _:= match(inArg, inAssignedTexts)
    local
      Ident ident;
      list<Ident> assignedTexts;
    case ( (ident , TEXT_TYPE()), assignedTexts )
      equation
        true = listMember(ident,assignedTexts);
      then ();
  end match;
end isAssignedText;


public function elabMatchCases
  input tuple<MMExp, TypeSignature> inItArgVal;
  input Ident inImplicitValueName;
  input list<tuple<MatchingExp,Expression>> inMCases;
  input Boolean hasImplicitLookup;
  input TypedIdents inLocals;
  input TypedIdents inAccCaseLocals;
  input ScopeEnv inScopeEnv;
  input TemplPackage inTplPackage;
  input list<MMDeclaration> inAccMMDecls;

  output list<tuple<MatchingExp, TypedIdents, list<MMExp>>> outMMMCases;
  output TypedIdents outLocals;
  output ScopeEnv outScopeEnv;
  output list<MMDeclaration> outMMDecls;
  output list<Ident> outAssignedIdents;
algorithm
  (outMMMCases, outLocals, outScopeEnv, outMMDecls, outAssignedIdents)
  := matchcontinue (inItArgVal, inImplicitValueName, inMCases, hasImplicitLookup, inLocals, inAccCaseLocals, inScopeEnv, inTplPackage, inAccMMDecls)
    local
      ScopeEnv scEnv;
      TypedIdents locals, accCaseLocals;
      TypeSignature exptype;
      TypedIdents extargs;
      list<tuple<MatchingExp,Expression>> mcases;
      MatchingExp mexp;
      Expression exp;
      list<tuple<MatchingExp, TypedIdents, list<MMExp>>> elabcases;
      TemplPackage tplPackage;
      list<ASTDef> astdefs;
      list<MMDeclaration> accMMDecls;
      MMExp mmexp;
      list<MMExp> stmts;
      tuple<MMExp, TypeSignature> argval;
      list<Ident> assignedIdents;
      list<tuple<Ident, Ident>> localNames;

    case ( _, _, {}, _, locals, _, scEnv, _, accMMDecls)
      equation
        locals = listAppend(inAccCaseLocals, locals);
      then
        ( {}, locals, scEnv, accMMDecls, {});

    case ( argval as (_, exptype), _,
           (mexp,exp) :: mcases,
           _, locals, accCaseLocals, scEnv,
           tplPackage as TEMPL_PACKAGE(astDefs = astdefs), accMMDecls )
      equation
        mexp = typeCheckMatchingExp(mexp, exptype, astdefs);
        //mexp = encodeMatchingExp(mexp);
        //matchLocalArgName = getMatchArgName(mmexp);
        (stmts, locals, scEnv, accMMDecls, _)
          = statementsFromExp(exp,{}, {}, imlicitTxt, imlicitTxt, locals,
              (CASE_SCOPE(mexp, exptype, {}, accCaseLocals, {}, inImplicitValueName, hasImplicitLookup) :: scEnv), tplPackage, accMMDecls);
        (CASE_SCOPE(mexp, _, localNames, accCaseLocals, extargs, _, _) :: scEnv) = scEnv; //releaseImmediateLocalScope(scEnv);
        stmts = listReverse(stmts);
        //TODO: locals can be gathered with introduction of another function scope
        //and then to see what was used, the rest can be eliminated with the typecheck function
        //--->
        (mexp, _) = rewriteMatchExpByLocalNames(mexp, exptype, localNames, {}, astdefs);
        //(locals, mexp) = localsFromMatchExp(mexp, exptype, locals, astdefs);
        (elabcases, locals, scEnv, accMMDecls, assignedIdents)
          = elabMatchCases(argval, inImplicitValueName, mcases, hasImplicitLookup, locals, accCaseLocals, scEnv, tplPackage, accMMDecls );
        assignedIdents = getAssignedIdents(stmts, assignedIdents);
      then
        ( (mexp, extargs, stmts) :: elabcases, locals, scEnv, accMMDecls, assignedIdents);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!elabMatchCases failed\n");
      then
        fail();
  end matchcontinue;
end elabMatchCases;


public function getAssignedIdents
  input list<MMExp> inStatements;
  input list<Ident> inAssignedIdents;

  output list<Ident> outAssignedIdents;
algorithm
  (outAssignedIdents)
  := matchcontinue (inStatements, inAssignedIdents)
    local
       list<MMExp> stmts;
      list<Ident> assignedIdents, largs;

    case ( {}, assignedIdents)
      then
        ( assignedIdents);

    case ( MM_ASSIGN(lhsArgs = largs) :: stmts, assignedIdents)
      equation
        assignedIdents = List.fold(largs, List.unionElt, assignedIdents);
      then
        getAssignedIdents(stmts, assignedIdents);

    case ( _ :: stmts, assignedIdents)
      then
        getAssignedIdents(stmts, assignedIdents);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!getAssignedTexts failed\n");
      then
        fail();
  end matchcontinue;
end getAssignedIdents;

/*
public function getItNameFromArg
  input MMExp inItArgMMExp;
  input TypeSignature inMType;
  input MatchingExp inMatchingExp;
  input list<ASTDef> inASTDefs;

  output Ident outItName;
algorithm
  outItName := matchcontinue (inItArgMMExp, inMType, inMatchingExp, inASTDefs)
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
    else "it";

  end matchcontinue;
end getItNameFromArg;
*/

//fail and error
public function typeCheckMatchingExp
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;

  output MatchingExp outTransformedMatchingExp;
algorithm
  (outTransformedMatchingExp)
    := matchcontinue (inMatchingExp, inMType, inASTDefs)
    local
      Ident bid;
      PathIdent tagpath;
      TypeSignature mtype, ot;
      list<TypeSignature> otLst;
      MatchingExp mexp, restmexp;
      list<MatchingExp> mexpLst;
      list<tuple<String, MatchingExp>> fms;
      TypedIdents fields;
      list<ASTDef> astDefs;

    case ( BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs)
      equation
        mexp = typeCheckMatchingExp(mexp, mtype, astDefs);
      then
        (BIND_AS_MATCH(bid, mexp));

    //try if it is a record ident
    //-> convert to RECORD_MATCH()
    /*
    case ( BIND_MATCH(bindIdent = bid), mtype, astDefs)
      equation
        NAMED_TYPE(typepath) = deAliasedType(mtype, astDefs);
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (typepckg, typeinfo) = getTypeInfo(typepckgOpt, typeident, astDefs);
        isRecordTag(bid, typeinfo, typeident);
        tagpath = makePathIdent(typepckg, bid);
      then
        (RECORD_MATCH(tagpath, {} ));
    */

    //otherwise it is like REST_MATCH ... nothing to check
    case ( mexp as BIND_MATCH(), _, _)
      then
        mexp;

    //TODO: a HACK!!; this only can happen for "if" condition with a TEXT argument to be tested for emptiness
    case ( mexp as RECORD_MATCH(), TEXT_TYPE(), _ )
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
        OPTION_TYPE() = deAliasedType(mtype, astDefs);
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
        otLst = List.fill(ot, listLength(mexpLst));
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
    case ( mexp as STRING_MATCH(),
           mtype, astDefs )
      equation
        STRING_TYPE() = deAliasedType(mtype, astDefs);
      then
        mexp;

    // TODO - failure message when not equal types
    case ( mexp as LITERAL_MATCH(litType = ot),
           mtype, astDefs )
      equation
        typesEqualConcrete(deAliasedType(ot, astDefs), deAliasedType(mtype, astDefs), astDefs);
      then
        mexp;

    case ( mexp as REST_MATCH(), _, _)
      then
        mexp;


    // ** failures ***
    //TODO: will be concrete with output message

    else
      equation
        //locals = addLocalValue("#Error - type check#", mtype, locals);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeCheckMatchingExp failed\n");
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
      list<ASTDef> astDefs;

    case ( {}, _, _)
      then
        {};

    case ( (ident, mexp) :: fms, _, astDefs)
      equation
        mtype = lookupTupleList(fields, ident);
        mexp = typeCheckMatchingExp(mexp, mtype, astDefs);
        fms  = typeCheckMatchingExpRecord(fms, fields, astDefs);
      then
        ((ident, mexp) :: fms);

    case ( (ident, _) :: _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure( _ = lookupTupleList(fields, ident) );
        //reason = "#Error - unresolved type - cannot find field '" + ident + "'#";
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeCheckMatchingExpRecord failed to find field '" + ident + "'\n");
        //(locals, fms) = localsFromMatchExpAndTypeCheckRecord(fms, fields, locals, astDefs);
      then
        fail();
        //(locals, (ident, mexp) :: fms);

    // can fail on error
    /*
    case (_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!localsFromMatchExpAndTypeCheckRecord failed\n");
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
    := match (inMatchingExpLst, inTypeLst, inASTDefs)
    local
      MatchingExp mexp;
      list<MatchingExp> mexpLst;
      TypeSignature mtype;
      list<TypeSignature> tsLst;

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

    case ( (_ :: _), {}, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeCheckMatchingExpList more expressions to chceck than required (a tuple type has less arguments than provided?).\n");
      then
        fail();

    case ( {}, _ :: _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - typeCheckMatchingExpList more arguments expected (the tuple type has more arguments than provided).\n");
      then
        fail();

    // can fail on error
    /*
    case (_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!localsFromMatchExpAndTypeCheckList failed\n");
      then
        fail();
    */
  end match;
end typeCheckMatchingExpList;

public function eliminateWildAs
  input MatchingExp inMatchingExp;

  output MatchingExp outRewrittenMatchingExp;
algorithm
  outRewrittenMatchingExp := match (inMatchingExp)
    local
      Ident bid;

    case ( BIND_AS_MATCH(bid, REST_MATCH()))  then   BIND_MATCH(bid);
    else inMatchingExp;

  end match;
end eliminateWildAs;

public function rewriteMatchExpByLocalNames
  input MatchingExp inMatchingExp;
  input TypeSignature inMType;
  input list<tuple<Ident, Ident>> inLocalNames;
  input TypedIdents inUsedLocals "accumulated list of already rewrited locals - to check duplicitly bound names";
  input list<ASTDef> inASTDefs;

  output MatchingExp outRewrittenMatchingExp;
  output TypedIdents outUsedLocals;
algorithm
  (outRewrittenMatchingExp, outUsedLocals)
    := matchcontinue (inMatchingExp, inMType, inLocalNames, inUsedLocals, inASTDefs)
    local
      Ident bid, fldId, localIdent;
      PathIdent tagpath;
      TypeSignature mtype, ot;
      list<TypeSignature> otLst;
      MatchingExp mexp, restmexp;
      list<MatchingExp> mexpLst;
      list<tuple<String, MatchingExp>> fms;
      TypedIdents fields, usedLocals;
      list<ASTDef> astDefs;

    case ( BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, _, usedLocals, astDefs)
      equation
        localIdent = lookupTupleList(inLocalNames, bid);
        //TODO: a better error report - non stopping one here
        usedLocals = addLocalValue(bid, mtype, usedLocals);
        (mexp, usedLocals) = rewriteMatchExpByLocalNames(mexp, mtype, inLocalNames, usedLocals, astDefs);
        mexp = eliminateWildAs( BIND_AS_MATCH(localIdent, mexp) );
      then
        (mexp, usedLocals);

    //eliminate the non-used binding
    case ( BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, _, usedLocals, astDefs)
      equation
        failure(_ = lookupTupleList(inLocalNames, bid));
        (mexp, usedLocals) = rewriteMatchExpByLocalNames(mexp, mtype, inLocalNames, usedLocals, astDefs);
      then
        (mexp, usedLocals);

    case ( BIND_MATCH(bindIdent = bid), mtype, _, usedLocals, _)
      equation
        localIdent = lookupTupleList(inLocalNames, bid);
        //TODO: a better error report - use match expression source info
        usedLocals = addLocalValue(bid, mtype, usedLocals);
      then
        (BIND_MATCH(localIdent), usedLocals);

    //eliminate the non-used binding
    case ( BIND_MATCH(bindIdent = bid), _, _, usedLocals, _)
      equation
        failure(_ = lookupTupleList(inLocalNames, bid));
      then
        (REST_MATCH(), usedLocals);

    // a record with some fields is matched but no fields were used
    //-> adjust it to match the first field with "_" to obey MM semantics
    //TODO: when bootstrapped MM, make it (__) matching
    case ( RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = {} ),
           mtype, _,usedLocals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        ((fldId,_)::_, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs);
      then
        (RECORD_MATCH(tagpath, {(fldId, REST_MATCH())} ), usedLocals);

    case ( RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ),
           mtype, _, usedLocals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs);
        (fms, usedLocals) = rewriteMatchExpByLocalNamesRecord(fms, fields, inLocalNames, usedLocals, astDefs);
      then
        (RECORD_MATCH(tagpath, fms ), usedLocals);

    case ( SOME_MATCH(
             value = mexp ), mtype, _, usedLocals, astDefs)
      equation
        OPTION_TYPE(ofType = mtype) = deAliasedType(mtype, astDefs);
        (mexp, usedLocals) = rewriteMatchExpByLocalNames(mexp, mtype, inLocalNames, usedLocals, astDefs);
      then
        (SOME_MATCH(mexp), usedLocals);

    case ( TUPLE_MATCH(
             tupleArgs = mexpLst),
           mtype, _, usedLocals, astDefs )
      equation
        TUPLE_TYPE(ofTypes = otLst) = deAliasedType(mtype, astDefs);
        //equality( listLength(mexpLst) = listLength(otLst) );
        (mexpLst, usedLocals) = rewriteMatchExpByLocalNamesList(mexpLst, otLst, inLocalNames, usedLocals, astDefs);
      then
        (TUPLE_MATCH(mexpLst), usedLocals);

    case ( LIST_MATCH(
             listElts = mexpLst),
           mtype, _, usedLocals, astDefs )
      equation
        LIST_TYPE(ofType = ot) = deAliasedType(mtype, astDefs);
        otLst = List.fill(ot, listLength(mexpLst));
        (mexpLst, usedLocals) = rewriteMatchExpByLocalNamesList(mexpLst, otLst, inLocalNames, usedLocals, astDefs);
      then
        (LIST_MATCH(mexpLst), usedLocals);

    case ( LIST_CONS_MATCH(
             head = mexp,
             rest = restmexp),
           mtype, _, usedLocals, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        LIST_TYPE(ofType = ot) = mtype;
        (mexp, usedLocals) = rewriteMatchExpByLocalNames(mexp, ot, inLocalNames, usedLocals, astDefs);
        (restmexp, usedLocals) = rewriteMatchExpByLocalNames(restmexp, mtype, inLocalNames, usedLocals, astDefs);
      then
        (LIST_CONS_MATCH(mexp, restmexp), usedLocals);

    // the rest - NONE_MATCH, STRING_MATCH, LITERAL_MATCH, REST_MATCH
    case ( mexp ,_,_,usedLocals,_)
      then
        (mexp, usedLocals);

    //TODO: error reporting is not complete here
    //-> it must be done through Error to actually catch the duplicity errors


  end matchcontinue;
end rewriteMatchExpByLocalNames;


public function rewriteMatchExpByLocalNamesRecord
  input list<tuple<Ident, MatchingExp>> inFieldMatchings;
  input TypedIdents fields;
  input list<tuple<Ident, Ident>> inLocalNames;
  input TypedIdents inUsedLocals "accumulated list of already rewrited locals - to check duplicitly bound names";
  input list<ASTDef> inASTDefs;

  output list<tuple<Ident, MatchingExp>> outRewrittenMatchingExp;
  output TypedIdents outUsedLocals;
algorithm
  (outRewrittenMatchingExp, outUsedLocals)
    := matchcontinue (inFieldMatchings, fields, inLocalNames, inUsedLocals, inASTDefs)
    local
      Ident ident;
      MatchingExp mexp;
      TypeSignature mtype;
      list<tuple<Ident, MatchingExp>> fms;
      TypedIdents usedLocals;
      list<ASTDef> astDefs;
      String reason;

    case ( {}, _, _, _, _)
      then
        ({}, inUsedLocals);

    case ( (ident, mexp) :: fms, _, _, usedLocals, astDefs)
      equation
        mtype = lookupTupleList(fields, ident);
        (mexp, usedLocals) = rewriteMatchExpByLocalNames(mexp, mtype, inLocalNames, usedLocals, astDefs);
        (fms, usedLocals)  = rewriteMatchExpByLocalNamesRecord(fms, fields, inLocalNames, usedLocals, astDefs);
      then
        ((ident, mexp) :: fms, usedLocals);

    //TODO: should we report an error here? ... perhaps, only internal as the mexp shpuld be already checked
    case ( (ident, mexp) :: fms, _, _, usedLocals, astDefs)
      equation
        failure( _ = lookupTupleList(fields, ident) );
        //locals = addLocalValue(ident, UNRESOLVED_TYPE(reason), locals);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("Error - rewriteMatchExpByLocalNamesRecord failed to find field '" + ident + "'\n");
        end if;
        (fms, usedLocals) = rewriteMatchExpByLocalNamesRecord(fms, fields, inLocalNames, usedLocals, astDefs);
      then
        ((ident, mexp) :: fms, usedLocals);

    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!rewriteMatchExpByLocalNamesRecord failed\n");
      then
        fail();

  end matchcontinue;
end rewriteMatchExpByLocalNamesRecord;


public function rewriteMatchExpByLocalNamesList
  input list<MatchingExp> inMatchingExpLst;
  input list<TypeSignature> inTypeLst;
  input list<tuple<Ident, Ident>> inLocalNames;
  input TypedIdents inUsedLocals "accumulated list of already rewrited locals - to check duplicitly bound names";
  input list<ASTDef> inASTDefs;

  output list<MatchingExp> outRewrittenMatchingExp;
  output TypedIdents outUsedLocals;
algorithm
  (outRewrittenMatchingExp, outUsedLocals)
    := matchcontinue (inMatchingExpLst, inTypeLst, inLocalNames, inUsedLocals, inASTDefs)
    local
      MatchingExp mexp;
      list<MatchingExp> mexpLst;
      TypeSignature mtype;
      list<TypeSignature> tsLst;

      TypedIdents usedLocals;
      list<ASTDef> astDefs;

    case ( {}, {}, _,usedLocals,_)
      then
        ({}, usedLocals);

    case ( mexp :: mexpLst, mtype :: tsLst, _, usedLocals, astDefs)
      equation
        (mexp, usedLocals)    = rewriteMatchExpByLocalNames(mexp, mtype, inLocalNames, usedLocals, astDefs);
        (mexpLst, usedLocals) = rewriteMatchExpByLocalNamesList(mexpLst, tsLst, inLocalNames, usedLocals, astDefs);
      then
        (mexp :: mexpLst, usedLocals);

    // should not ever happen - when type check was successful
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!localsFromMatchExpList failed\n");
      then
        fail();

  end matchcontinue;
end rewriteMatchExpByLocalNamesList;


public function addLocalValue
  input Ident inIdent;
  input TypeSignature inMType;
  //input SourceInfo sinfo;
  input TypedIdents inLocals;

  output TypedIdents outLocals;
algorithm
  outLocals := matchcontinue (inIdent, inMType, inLocals)
    local
      Ident ident;
      TypeSignature mtype;
      TypedIdents locals;
      String msg;

    // special case when no local statement where added to an empty text
    case ( ident, TEXT_TYPE(), locals)
      equation
        true = stringEq(ident, emptyTxt);
      then
        locals;

    case ( ident, mtype, locals)
      equation
        failure( _ = lookupTupleList(locals, ident) );
      then
        ((ident, mtype) :: locals);

    case ( ident, mtype, locals)
      equation
        _ = lookupTupleList(locals, ident);
        msg = "A duplicite identifier '" + ident + "' bound in a matching expression.";
        addSusanError(msg, dummySourceInfo); //TODO: Match expressions source info here
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - (addLocalValue) a duplicite identifier '" + ident + "' bound in a matching expression. \n");
      then
        ((ident, mtype) :: locals);

  end matchcontinue;
end addLocalValue;


public function makeMMMatchCase
  input tuple<MatchingExp, TypedIdents, list<MMExp>> inElabCase "(Mexp, extargs, mexp list)";
  input TypedIdents inExtraArgs;
  input TypedIdents inOutArgs;

  output MMMatchCase outMMMCase;
algorithm
  (outMMMCase)
  := matchcontinue (inElabCase, inExtraArgs, inOutArgs)
    local
      MatchingExp mexp;
      TypedIdents  caseargs, extargs, oargs;
      MMMatchCase mmmcase;
      list<MMExp> stmts;
      list<MatchingExp> mexpLst;

    case ( (mexp, caseargs, stmts), extargs, oargs)
      equation
        mexpLst = List.map2(extargs, makeExtraArgBinding, caseargs, oargs);
        mmmcase = (imlicitTxtMExp :: mexp :: mexpLst,  stmts);
      then mmmcase;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeMMMatchCase failed\n");
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeExtraArgBinding failed\n");
      then
        fail();
  end matchcontinue;
end makeExtraArgBinding;


public function addRestElabCase
  input list<tuple<MatchingExp, TypedIdents, list<MMExp>>> inElabCases;

  output list<tuple<MatchingExp, TypedIdents, list<MMExp>>> outElabCases;
algorithm
  outElabCases := matchcontinue (inElabCases)
    local
      MatchingExp mexp;
      tuple<MatchingExp, TypedIdents, list<MMExp>> elabcase;
      list<tuple<MatchingExp, TypedIdents, list<MMExp>>> restcases;

    case ( {} )
      then
        ( { (REST_MATCH(),{},{}) } );

    case ( restcases as ( (mexp, _, _) :: _) )
      equation
        isAlwaysMatched(mexp);
      then
        ( restcases );

    case ( (elabcase as (_, _, _)) :: restcases )
      equation
        //failure(isAlwaysMatched(mexp));
        restcases = addRestElabCase(restcases);
      then
        ( elabcase :: restcases );

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!addRestElabCase failed\n");
      then
        fail();
  end matchcontinue;
end addRestElabCase;


public function isAlwaysMatched "Takes a MatchingExp and fails when it is not a rest case for sure (statically tested)."
  //TODO: evaluation when there are two cases with  {} and (always :: _) ... or  NONE() and SOME(always)
  input MatchingExp inMatchingExp;

algorithm
  _ := match (inMatchingExp)
    local
      MatchingExp mexp;
      list<MatchingExp> mexplst;

    case ( BIND_AS_MATCH(matchingExp = mexp) )
      equation
        isAlwaysMatched(mexp);
      then ();

    case ( BIND_MATCH() )
      then ();

    case ( TUPLE_MATCH(tupleArgs = mexplst) )
      equation
        List.map_0(mexplst, isAlwaysMatched);
      then ();

    case ( REST_MATCH() )
      then ();
  end match;
end isAlwaysMatched;

public function isAlwaysMatchedBool "Takes a MatchingExp and fails when it is not a rest case for sure (statically tested)."
  //TODO: evaluation when there are two cases with  {} and (always :: _) ... or  NONE() and SOME(always)
  input MatchingExp inMatchingExp;
  output Boolean isAlwaysMatched;
algorithm
  isAlwaysMatched := matchcontinue (inMatchingExp)
    local
      MatchingExp mexp;
    case (mexp)
      equation
        isAlwaysMatched(mexp);
      then true;

    else false;
  end matchcontinue;
end isAlwaysMatchedBool;

public function adaptTextToString
  input tuple<MMExp, TypeSignature, SourceInfo> inArgValue;
  input Expression inArgExp;
  input list<MMExp> inStmts;
  input TypedIdents inLocals;
  input TemplPackage inTplPackage;

  output tuple<MMExp, TypeSignature, SourceInfo> outArgValue;
  output Expression outArgExp;
  output list<MMExp> outStmts;
  output TypedIdents outLocals;
algorithm
  (outArgValue, outArgExp, outStmts, outLocals)
    := matchcontinue (inArgValue, inArgExp, inStmts, inLocals, inTplPackage)
    local
      list<MMExp> stmts;
      MMExp stmt, mmexp;
      Ident strid;
      TypedIdents locals;
      tuple<MMExp, TypeSignature, SourceInfo> argval;
      SourceInfo sinfo;
      TypeSignature exptype;
      list<ASTDef> astdefs;

    //every Text value is converted/rendered to string when it is a matching argument (match and map exps)
    //if it is needed to match against the Text structure, a simple deconstruction functions can be used,
    //one of type Text -> list<StringToken>, the second of type Text -> list<tuple<Tokens,BlockType>> for the stack
    //but who will need this, anyway ? (maybe for debugging of Susan it can help)
    case ( (mmexp, exptype, sinfo), _, stmts, locals,  TEMPL_PACKAGE(astDefs = astdefs))
      equation
        TEXT_TYPE() = deAliasedType(exptype, astdefs);
        strid = textToStringNamePrefix + intString(listLength(locals));
        locals = addLocalValue(strid, STRING_TYPE(), locals);
        mmexp = mmExpToString(mmexp, TEXT_TYPE(), sinfo);
        stmt = MM_ASSIGN({strid}, mmexp);
      then
        ( (MM_IDENT(IDENT(strid)), STRING_TYPE(), sinfo), emptyExpression, stmt::stmts,  locals);

   //other types are ok for the match statement
   case ( argval, _, stmts, locals, _)
      then
        ( argval, inArgExp, stmts,  locals);

    //cannot happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!adaptTextToString failed\n");
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
      Expression tbranch;
      Option<Expression> ebranchOpt;
      TemplPackage tplPackage;

    /* from the "if EXP is PATTERN then ..." form
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
    */

    // List ... if valLst then / if not valLst then
    case ( LIST_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, LIST_MATCH({}), tbranch, ebranchOpt);
    // Option
    case ( OPTION_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, NONE_MATCH(), tbranch, ebranchOpt);
    // String and Text (auto-converted to String)
    case ( STRING_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, STRING_MATCH(""), tbranch, ebranchOpt);
    //Integer
    case ( INTEGER_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("0", INTEGER_TYPE()), tbranch, ebranchOpt);
    //Real
    case ( REAL_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("0.0", REAL_TYPE()), tbranch, ebranchOpt);
    //Boolean
    case ( BOOLEAN_TYPE(), isnot,NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot, LITERAL_MATCH("false", BOOLEAN_TYPE()), tbranch, ebranchOpt);

    case ( TEXT_TYPE(), isnot, NONE(), tbranch, ebranchOpt, _)
      then
       casesForTrueFalseCondition(isnot,
          //MEM_TEXT( tokens = {} )
          RECORD_MATCH( PATH_IDENT("Tpl", IDENT("MEM_TEXT")),
                        {("tokens",LIST_MATCH({}))} ),
          tbranch, ebranchOpt);

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!elabCasesFromCondition failed\n");
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

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!casesForTrueFalseCondition failed\n");
      then
        fail();
  end matchcontinue;
end casesForTrueFalseCondition;


public function getElseBranch
  input Option<Expression> inElseBranchOpt;
  output Expression outElseBranch;
algorithm
  outElseBranch := match inElseBranchOpt
    local
      Expression ebranch;

    case ( SOME(ebranch) ) then ebranch;

    //empty map-argument list will generate no code
    case NONE() then emptyExpression;

    //cannot happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!getElseBranch failed\n");
      then
        fail();
  end match;
end getElseBranch;

//does not fail, when not resolved ... UNRESOLVED_TYPE() is returned
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

      PathIdent path,  typepckg;
      Ident ident,  typeident;
      TypeSignature idtype;
      ScopeEnv scEnv;
      list<ASTDef> astDefs;
      TemplateDef tpldef;
      list<tuple<Ident,TemplateDef>> tpldefs;
      Option<PathIdent> typepckgOpt;
      MMExp mmexp;
      String reason;
      //Boolean hasImplicitScope;


    // look up the scope
    case (path, scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        //(ident, _) = encodePathIdent(path);
        ident = pathIdentString(path);
        //Debug.fprint(Flags.FAILTRACE,"\n encoded path = " + pathIdentString(path) + ", ident = "+ ident + "\n");
        (ident, idtype, scEnv) = resolvePathInScopeEnv(ident, path, true, scEnv, astDefs);
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
        reason = "Unresolved path - imported symbol '" + pathIdentString(path) + "' other than a constant used in a value context (missing parenthesis ?).";
        idtype = UNRESOLVED_TYPE(reason);
        path = makePathIdent(typepckg, typeident);
      then
        ( MM_IDENT(path), idtype, scEnv);


    // imlicit record lookup failed
    /*
    case (path,
          (scope as CASE_SCOPE(
             mExp = mexp,
             mType = mtype,
             extArgs = extargs)) :: scEnv, TEMPL_PACKAGE(astDefs = astDefs)  )
      equation
        (ident, encpath) = encodePathIdent(path);
        failure( (_,_) = lookupUpdateMatchingExp(ident, encpath, mexp, mtype, astDefs) );
        (UNRESOLVED_TYPE(reason), mexp) = lookupUpdateMExpDotPath(ident, path, mexp, mtype, astDefs);
        reason = "Unresolved path '" + pathIdentString(path) + "'- after try of imlicit case lookup got:\n   " + reason;
        idtype = UNRESOLVED_TYPE(reason);
      then
        ( MM_IDENT(IDENT(ident)), idtype, (scope :: scEnv));
    */

    // all the rest
    case (path, scEnv, _  )
      equation
        reason = "Unresolved path '" + pathIdentString(path) + "'.";
        idtype = UNRESOLVED_TYPE(reason);
      then
        ( MM_IDENT(path), idtype, scEnv);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!resolveBoundPath failed\n");
      then
        fail();
  end matchcontinue;
end resolveBoundPath;


public function checkResolvedType
  input PathIdent inPath;
  input TypeSignature inType;
  input String inUnresolvedMsg;
  input SourceInfo inInfo;

algorithm
  _ := matchcontinue (inPath, inType, inUnresolvedMsg, inInfo)
    local
      PathIdent path;
      String reason, msg;

    case ( _, UNRESOLVED_TYPE(reason), msg, _)
      equation

        //true = Flags.isSet(Flags.FAILTRACE);
        //msg = msg + " unresolved type of '" + pathIdentString(path) + "', reason = '" + reason + "'.\n";
        msg = "(" + msg + ") " + reason;
        //true = Flags.isSet(Flags.FAILTRACE); Debug.trace("ADD Error: " + msg + "\n");  //+ " unresolved path '" + pathIdentString(path) + "', reason = '" + reason + "'.\n");
        addSusanError(msg, inInfo);
      then
        ();

    else ();

  end matchcontinue;
end checkResolvedType;


public function checkTextType
  input TypeSignature inType;
  input Ident inIdent;
  input String inUnresolvedMsg;
  input SourceInfo inInfo;
  output TypeSignature outType;
algorithm
  outType := matchcontinue (inType, inIdent, inUnresolvedMsg, inInfo)
    local
      String msg;
      TypeSignature ts;

    //OK
    case (TEXT_TYPE(),_, _, _) then inType;

    //already handled by checkResolvedType
    case (UNRESOLVED_TYPE(),_ , _, _) then inType;

    case ( ts, _, msg, _)
      equation
        msg = "(" + msg + ") identifier '" + inIdent + "' was expected to have Text& type but resolved to " + typeSignatureString(ts)
           + ".\n Only Text& typed variables can be appended to.";
        addSusanError(msg, inInfo);
      then
        UNRESOLVED_TYPE(msg);

  end matchcontinue;
end checkTextType;


public function makeMMExpFromTemplateConstant
  input TemplateDef inTplDef;
  input Ident inTemplIdent;

  output MMExp outMMExp;
  output TypeSignature outConstType;
algorithm
  (outMMExp, outConstType) := matchcontinue (inTplDef, inTemplIdent)
    local
      Ident ident;
      TypeSignature idtype, lt;
      StringToken st;
      String litstr, reason;

    // string constants are of StringToken type and does not involve a type conversion, use them through idents
    case ( STR_TOKEN_DEF(), ident)
      equation
        ident = constantNamePrefix + ident; //no encoding needed, just prefix, it is a constant
      then
        (MM_IDENT(IDENT(ident)), STRING_TOKEN_TYPE());

    // literal constants of primitive types besides string : INTEGER_TYPE, REAL_TYPE or BOOLEAN_TYPE
    // make them inline
    case ( LITERAL_DEF(value = litstr, litType = lt), _)
      then
        (MM_LITERAL(litstr), lt);

    // Error - a template in a value context ... maybe, this can be with lower priority, after of trying of imlicit record lookup
    case ( TEMPLATE_DEF(), ident)
      equation
        reason = "Unresolved identifier - the template '" + ident + "'in a value context found (missing parenthesis ?) .";
        idtype = UNRESOLVED_TYPE(reason);
        //ident = encodeIdent(ident);
      then
        ( MM_IDENT(IDENT(ident)), idtype);

    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeMMExpFromTemplateConstant failed\n");
      then
        fail();
  end matchcontinue;
end makeMMExpFromTemplateConstant;

public function prepareMatchArgument
  input MatchingExp inMExp;
  input Ident inMatchArgName;

  output Ident outIdent;
  output MatchingExp outMExp;
algorithm
  (outIdent, outMExp) := matchcontinue (inMExp, inMatchArgName)
    local
      MatchingExp mexp;
      Ident ident;

    case (mexp as BIND_MATCH(bindIdent = ident), _ )
      then
        (ident, mexp);

    case (mexp as BIND_AS_MATCH(bindIdent = ident), _)
      then
        (ident, mexp);

    //replace a wild match with the inMatchArgName
    case (REST_MATCH(), _)
      then
        (inMatchArgName, BIND_MATCH(inMatchArgName));

    //all the rest cases creates an "as" binding of matchArgName
    //no need to addToLocals because it is already in the locals
    else (inMatchArgName, BIND_AS_MATCH(inMatchArgName, inMExp) );

  end matchcontinue;
end prepareMatchArgument;


public function resolvePathInScopeEnv
  input Ident inIdent "path string ident name of the looked up ident - to be a new bound name (internally)" ;
  input PathIdent inPath "path of the looked up ident";
  input Boolean canDoImplicitLookup;
  input ScopeEnv inScopeEnv;
  input list<ASTDef> inASTDefs;

  output Ident outLocalIdent "resolved local name";
  output TypeSignature outType;
  output ScopeEnv outScopeEnv;
algorithm
  (outLocalIdent, outType, outScopeEnv)
  := matchcontinue (inIdent, inPath, canDoImplicitLookup, inScopeEnv, inASTDefs)
    local
      MatchingExp mexp;
      TypedIdents extargs, fargs, accLocals, localArgs;
      PathIdent path;
      Ident ident, matchArgName, letIdent, freshIdent,  encident, localIdent;
      TypeSignature idtype, mtype;
      Scope scope;
      ScopeEnv scEnv, restEnv;
      list<ASTDef> astdefs;
      Boolean hasImplicitScope;
      list<tuple<Ident,Ident>> localNames;

    //Error - test recursive usage of TEXT_ADD ident or an actually elaborated let expression
    case (ident, _, _,
          (RECURSIVE_SCOPE(recIdent = letIdent) :: _), _)
      equation
        true = stringEq(ident, letIdent);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - trying to use '" + ident
           + "' recursively inside a let scope or text addition. Use an additional Text variable if a self addition/duplication is needed, like  let b = a  let &a += b ... \n");
      then
        fail();

    //OK - no recursive usage, look up
    case (ident, path, _,
          (scope as RECURSIVE_SCOPE(recIdent = letIdent)) :: restEnv, astdefs)
      equation
        false = stringEq(ident, letIdent);
        (ident, idtype, restEnv)
         = resolvePathInScopeEnv(ident, path, canDoImplicitLookup, restEnv, astdefs);
      then
        (ident, idtype, scope :: restEnv);


    //let scope, found
    case (ident, _, _,
          LET_SCOPE(ident = letIdent, idType = idtype, freshIdent = freshIdent) :: restEnv, _)
      equation
        true = stringEq(ident, letIdent);
      then
        (freshIdent, idtype,
         LET_SCOPE(letIdent, idtype, freshIdent, true) :: restEnv);

    //let scope failed - look up
    case (ident, path, _,
          (scope as LET_SCOPE()) :: restEnv, astdefs)
      equation
        // false = stringEq(ident, letIdent);
        (ident, idtype, restEnv)
         = resolvePathInScopeEnv(ident, path, canDoImplicitLookup, restEnv, astdefs);
      then
        (ident, idtype, scope :: restEnv);


    //found in the function scope
    case ( ident, path , _,
           scEnv as (FUN_SCOPE(args = fargs) :: _ ), _  )
      equation
        idtype = lookupTupleList(fargs, ident);
        //encode the ident ... a_ident
        ident = encodePathIdent(path, funArgNamePrefix);
      then
        (ident, idtype, scEnv);

    //not in the function scope, look up
    case (ident, path, _,
          FUN_SCOPE(args = fargs, localArgs = localArgs)::restEnv, astdefs)
      equation
        //failure(_ = lookupTupleList(fargs, ident));
        //FUN_SCOPE hides the local names from the upper scope
        (localIdent, idtype, restEnv)
          = resolvePathInScopeEnv(ident, path, canDoImplicitLookup, restEnv, astdefs);
        //fargs = updateTupleList(fargs, (ident, idtype));
        fargs = (ident, idtype) :: fargs; //not there yet
        localArgs = (localIdent, idtype) :: localArgs;
        //encode the ident ... a_ident
        ident = encodeIdent(ident, funArgNamePrefix);
      then
        (ident, idtype, FUN_SCOPE(fargs, localArgs) :: restEnv);

    //bound in the matching expression, update it with the ident if needed
    case ( ident, path, _,
           CASE_SCOPE(
             mExp = mexp,
             mType = mtype,
             localNames = localNames,
             accLocals = accLocals,
             extArgs = extargs,
             matchArgName = matchArgName,
             hasImplicitScope = hasImplicitScope) :: restEnv, astdefs  )
      equation
        (idtype, mexp) = lookupUpdateMatchingExp(ident, path, mexp, mtype, astdefs);
        encident = encodeIdent(ident, caseBindingNamePrefix);
        (encident, localNames, accLocals) = updateLocalsForMatchingExp(ident, encident, 0, idtype, localNames, accLocals);
      then
        (encident, idtype,
          CASE_SCOPE(mexp, mtype, localNames, accLocals, extargs, matchArgName, hasImplicitScope) :: restEnv);

    //try "implicit" record lookup ~ [it.]path
    //now, the implicit scoped fields can hide upper idents from upper scope when there is an overlap
    //TODO: a warning when the hidening has happen;
    //TODO: also warning when hidening of a binding that has the same name as a field but it is not the field(should it be hidden, too?, ... not now a name conflict would be there ...)
    case ( ident, path, true,
           CASE_SCOPE(
             mExp = mexp,
             mType = mtype,
             localNames = localNames,
             accLocals = accLocals,
             extArgs = extargs,
             matchArgName = matchArgName,
             hasImplicitScope = true) :: restEnv, astdefs  )
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n trying [it.]path for '" + ident + " / " + pathIdentString(path) + "' : "
                    + typeSignatureString(mtype));
        end if;
        (idtype, mexp) = lookupUpdateMExpDotPath(ident, path, mexp, mtype, astdefs);
        failure(UNRESOLVED_TYPE() = idtype);
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.traceln("\n [it.]path for '" + pathIdentString(path) + "' : "
                    + typeSignatureString(idtype));
        end if;

        encident = encodePathIdent(path, caseBindingNamePrefix);
        (encident, localNames, accLocals)
         = updateLocalsForMatchingExp(ident, encident, 0, idtype, localNames, accLocals);
      then
        (encident, idtype,
           CASE_SCOPE(mexp, mtype, localNames, accLocals, extargs, matchArgName, true) :: restEnv);


    //ident refers to the matched argument itself (originally to 'it')
    //avoid to look up --> find/create the binding of the whole pattern expression
    case ( ident, _, _,
           CASE_SCOPE(
             mExp = mexp,
             mType = mtype,
             localNames = localNames,
             accLocals = accLocals,
             extArgs = extargs,
             matchArgName = matchArgName,
             hasImplicitScope = hasImplicitScope) :: restEnv , _  )
      equation
        true = stringEq(ident, matchArgName);
        (ident, mexp) = prepareMatchArgument(mexp, matchArgName);

        encident = encodeIdent(ident, caseBindingNamePrefix);
        (encident, localNames, accLocals)
         = updateLocalsForMatchingExp(ident, encident, 0, mtype, localNames, accLocals);
      then
        (encident, mtype,
          CASE_SCOPE(mexp, mtype, localNames, accLocals, extargs, matchArgName, hasImplicitScope) :: restEnv);

    //already in the extra args
    /* do not check this as the extargs have local names from the upper FUN_SCOPE
    case ( ident, _, _,
           scEnv as (CASE_SCOPE(extArgs = extargs) :: _ ), _  )
      equation
        idtype = lookupTupleList(extargs, ident);
      then
        (ident, idtype, scEnv);
    */

    //not in the case scope, look up
    case ( ident, path, _,
           CASE_SCOPE(
             mExp = mexp,
             mType = mtype,
             localNames = localNames,
             accLocals = accLocals,
             extArgs = extargs,
             matchArgName = matchArgName,
             hasImplicitScope = hasImplicitScope)  :: restEnv, astdefs )
      equation
        //failure( (_,_) = lookupUpdateMatchingExp(ident, path, mexp, mtype, astdefs));
        (encident, idtype, restEnv) = resolvePathInScopeEnv(ident, path,
              (canDoImplicitLookup and not hasImplicitScope), restEnv, astdefs);
        //updating the the extra args with the encoded returned local ident ... it must belong to the immediate upper FUN_SCOPE
        extargs = updateTupleList(extargs, (encident, idtype));
      then
        (encident, idtype, CASE_SCOPE(mexp, mtype, localNames, accLocals, extargs, matchArgName, hasImplicitScope) :: restEnv);

    // can normally fail for template or external constants
    //case ( ident, _, _, _ )
    //  equation
    //    true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-resolvePathInScopeEnv failed for ident '" + ident + "'.\n");
    //  then
    //    fail();
  end matchcontinue;
end resolvePathInScopeEnv;

public function addPostfixToIdent
  input Ident inIdent;
  input Integer inPostfix "postfix to be added; 0 -> no postfix";

  output Ident outPostfixedIdent;
algorithm
  (outPostfixedIdent) :=
  match (inIdent, inPostfix)
    local
      Ident ident;

    case ( _, 0)
      then
        inIdent;

    case ( ident, _)
      equation
        ident = ident + "_" + intString(inPostfix);
      then
        ident;

  end match;
end addPostfixToIdent;

public function updateLocalsForMatchingExp
  input Ident inIdent "path ident string - using dots, e.g. 'rec.field'";
  input Ident inEncIdent "encoded ident string as to be in locals";
  input Integer inPostfix "postfix used to make the created local name unique; 0->no postfix";
  input TypeSignature inType;
  input list<tuple<Ident,Ident>> inLocalNames;
  input TypedIdents inLocals;

  output Ident outLocalIdent;
  output list<tuple<Ident,Ident>> outLocalNames;
  output TypedIdents outLocals;
algorithm
  (outLocalIdent, outLocalNames, outLocals) :=
  matchcontinue (inIdent, inEncIdent, inPostfix, inType, inLocalNames, inLocals)
    local
      Ident ident, encIdent;
      TypeSignature loctype;
      TypedIdents locals;
      list<tuple<Ident,Ident>> localNames;

    //already in localNames
    case ( ident, _, _, _, localNames, locals)
      equation
        encIdent = lookupTupleList(localNames, ident);
      then
        (encIdent, localNames, locals);

    //not yet in locals
    case ( ident, _, _, _, localNames, locals)
      equation
        failure( _ = lookupTupleList(localNames, ident) );
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        failure( _ = lookupTupleList(locals, encIdent));
      then
        (encIdent,
         (ident, encIdent) :: localNames,
         (encIdent, inType) :: locals);

    //re-use from locals
    case ( ident, _, _, _, localNames, locals)
      equation
        failure( _ = lookupTupleList(localNames, ident) );
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        loctype = lookupTupleList(locals, encIdent);
        equality(loctype = inType);
      then
        (encIdent, (ident, encIdent) :: localNames, locals);

    //try the next postfix
    case ( ident, _, _, _, localNames, locals)
      equation
        failure( _ = lookupTupleList(localNames, ident) );
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        loctype = lookupTupleList(locals, encIdent);
        failure(equality(loctype = inType));
        (encIdent, localNames, locals)
         = updateLocalsForMatchingExp(ident, inEncIdent, inPostfix + 1, inType, localNames, locals);
      then
        (encIdent, localNames, locals);


    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!updateLocalsForMatchingExp failed\n");
      then
        fail();
  end matchcontinue;
end updateLocalsForMatchingExp;


public function usedInImmediateLetScope
  input Ident inIdent ;
  input Ident inFreshIdent;
  input ScopeEnv inScopeEnv;

  output Boolean outIsUsed;
algorithm
  outIsUsed
  := matchcontinue (inIdent, inFreshIdent, inScopeEnv)
    local
      Ident letIdent, freshIdent;
      ScopeEnv restEnv;

    case (_, _,
           LET_SCOPE(ident = letIdent, freshIdent = freshIdent) :: _)
      equation
        true = stringEq(inIdent, letIdent);
        true = stringEq(inFreshIdent, freshIdent);
      then
        true;

    case (_, _,
           LET_SCOPE() :: restEnv)
      //equation
        //false = stringEq(_, letIdent) and stringEq(_, freshIdent);
      then
        usedInImmediateLetScope(inIdent, inFreshIdent, restEnv);

    case (_, _,
           RECURSIVE_SCOPE(recIdent = letIdent, freshIdent = freshIdent) :: _)
      equation
        true = stringEq(inIdent, letIdent);
        true = stringEq(inFreshIdent, freshIdent);
      then
        true;

    case (_, _,
           RECURSIVE_SCOPE() :: restEnv)
      //equation
        //false = stringEq(_, letIdent) and stringEq(_, freshIdent);
      then
        usedInImmediateLetScope(inIdent, inFreshIdent, restEnv);

    else false;

  end matchcontinue;
end usedInImmediateLetScope;


public function updateLocalsForLetExp
  input Ident inIdent "original Susan ident";
  input Ident inEncIdent "encoded ident to be in locals";
  input Integer inPostfix "postfix used to make the created local name unique; 0->no postfix";
  input TypeSignature inType;
  input TypedIdents inLocals;
  input ScopeEnv inScopeEnv;

  output Ident outLocalIdent;
  output TypedIdents outLocals;
algorithm
  (outLocalIdent, outLocals) :=
  matchcontinue (inIdent, inEncIdent, inPostfix, inType, inLocals, inScopeEnv)
    local
      Ident  encIdent;
      TypeSignature loctype;
      TypedIdents locals;

    //not yet in locals, add
    case (_, _, _, _, _, _)
      equation
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        failure( _ = lookupTupleList(inLocals, encIdent));
      then
        (encIdent, (encIdent, inType) :: inLocals);

    //already in locals, but not the same type, try postfix+1
    case (_, _, _, _, _, _)
      equation
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        loctype = lookupTupleList(inLocals, encIdent);
        failure(equality(loctype = inType));
        (encIdent, locals)
         = updateLocalsForLetExp(inIdent, inEncIdent, inPostfix + 1, inType, inLocals, inScopeEnv);
      then
        (encIdent, locals);

    //already in locals, the same type, not used in the immediate scope, OK
    case (_, _, _, _, _, _)
      equation
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        loctype = lookupTupleList(inLocals, encIdent);
        equality(loctype = inType);
        false = usedInImmediateLetScope(inIdent, encIdent, inScopeEnv);
      then
        (encIdent, inLocals);

    //already in locals, the same type, but used in the immediate scope, try postfix+1
    case (_, _, _, _, _, _)
      equation
        encIdent = addPostfixToIdent(inEncIdent, inPostfix);
        loctype = lookupTupleList(inLocals, encIdent);
        equality(loctype = inType);
        true = usedInImmediateLetScope(inIdent, encIdent, inScopeEnv);
        (encIdent, locals)
         = updateLocalsForLetExp(inIdent, inEncIdent, inPostfix + 1, inType, inLocals, inScopeEnv);
      then
        (encIdent, locals);


    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!updateLocalsForLetExp failed\n");
      then
        fail();
  end matchcontinue;
end updateLocalsForLetExp;



public function lookupUpdateMatchingExp
  input Ident inIdent "path string ident to be the temporary internal local value name";
  input PathIdent inPathIdent "original path";
  input MatchingExp inMatchingExp "matching expression";
  input TypeSignature inMType;
  input list<ASTDef> inASTDefs;

  output TypeSignature outValueType;
  output MatchingExp outMatchingExp;
algorithm
  (outValueType, outMatchingExp)
    := matchcontinue (inIdent, inPathIdent, inMatchingExp, inMType, inASTDefs)
    local
      Ident inid, id, bid;
      PathIdent path, tagpath;
      TypeSignature mtype, otype, valtype;
      list<TypeSignature> mtypeLst;
      list<ASTDef> astDefs;

      String reason;
      list<tuple<String, MatchingExp>> fms;
      MatchingExp inmexp, mexp, restmexp;
      list<MatchingExp> mexpLst;
      TypedIdents fields;


    case ( _, IDENT(ident = id),
          inmexp as BIND_AS_MATCH(
                      bindIdent = bid ), mtype, _ )
      equation
        true = stringEq(id, bid);
      then
        ( mtype, inmexp );

    case ( inid, PATH_IDENT(ident = id, path = path ),
           BIND_AS_MATCH(
             bindIdent = bid,
             matchingExp = mexp ), mtype, astDefs )
      equation
        true = stringEq(id, bid);
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
        true = stringEq(id, bid);
      then
        ( mtype, inmexp );

    case ( inid, PATH_IDENT(ident = id),
           inmexp as BIND_MATCH(
             bindIdent = bid ), _, _ )
      equation
        true = stringEq(id, bid);
        reason = "Unresolved path '" + inid + "' after first dot - only the first part '" + id + "' resolved as a bind match.";
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
        mtypeLst = List.fill(mtype, listLength(mexpLst));
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
        reason = "Unresolved path - failed in lookup for field '" + id + "' at the end of the path '" + inid
                 + "', no such field in '" + pathIdentString(tagpath) + "' record fields.\n";
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

    case ( inid, PATH_IDENT(ident = id),
           RECORD_MATCH(
             tagName = tagpath,
             fieldMatchings = fms ), mtype, astDefs )
      equation
        mtype = deAliasedType(mtype, astDefs);
        (fields, tagpath) = getFieldsForRecord(mtype, tagpath, astDefs); // this should not fail as we have type-checked the matching expression
        failure( _ = lookupTupleList(fields, id));
        reason = "Unresolved path - failed in lookup for field '" + id + "' inside the (encoded) path '" + inid
              + "', no such field in '" + pathIdentString(tagpath) + "' record fields.\n";
        valtype = UNRESOLVED_TYPE( reason );
      then
        ( valtype, RECORD_MATCH(tagpath, fms) );

    // here we can insert an implicit resolution for pure record types (not embedded in a union)
    // just check the type if it is a pure record type and then expand the mexp with the record match
    case ( inid, path, mexp, _, _ )
      equation
        reason = "Unresolved path (encoded) '" + inid
                 + "', cannot follow the rest path '" + pathIdentString(path) + "', no record match available to look down the path.";
        valtype = UNRESOLVED_TYPE(reason);
      then
        ( valtype, mexp );


    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!lookupUpdateMExpDotPath failed for ident '" + inIdent + "'.\n");
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
  (outFieldMatchings) := matchcontinue (inIdent, inField, inFieldMatchings)
    local
      Ident inid, fieldid, ident;
      list<tuple<Ident, MatchingExp>> fms;
      tuple<Ident, MatchingExp> fm;
      MatchingExp mexp;

    case ( inid, fieldid, {} )
      then
        ( {(fieldid, BIND_MATCH(inid))} );

    case ( inid, fieldid,(ident, mexp) :: fms)
      equation
        true = stringEq(fieldid, ident);
        mexp = makeBindAs(inid, mexp); // cannot fail
      then
        ( (fieldid, mexp) :: fms );

    case ( inid, fieldid, fm :: fms )
      equation
        // failure(equation(fieldid = ident));
        fms = updateFieldMatchingsForField(inid, fieldid, fms);
      then
        ( fm :: fms );

    // should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!updateFieldMatchingsForField failed.\n");
      then
        fail();
  end matchcontinue;
end updateFieldMatchingsForField;

public function makeBindAs
  input Ident inIdent;
  input MatchingExp inMExp;

  output MatchingExp outMExp;
algorithm
  (outMExp) := matchcontinue (inIdent, inMExp)
    local
      Ident inid, bid;
      MatchingExp mexp, inmexp;

    case ( inid, inmexp as BIND_AS_MATCH(bindIdent = bid) )
      equation
        true = stringEq(inid, bid);
      then
        inmexp;

    case ( inid, BIND_AS_MATCH(
                   bindIdent = bid,
                   matchingExp = mexp ) )
      equation
        // false = stringEq(inid, bid);
        mexp = makeBindAs(inid, mexp); //we should do this to handle multiple path ambiguity ... i.e. when mexpr is  (c as REC(fld = a as REC2(fld2 = b)))  and  c.fld.fl2, a.fld2 and b are used simultanosly, then we will get (c as REC(fld = a as REC2(fld2 = b as c_fld_fld2 as a_fld)))
      then
        BIND_AS_MATCH(bid, mexp);

    case ( inid, inmexp as BIND_MATCH(
                             bindIdent = bid ) )
      equation
        true = stringEq(inid, bid);
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makeBindAs failed.\n");
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
  (outValueType, outFieldMatchings) := matchcontinue (inIdent, inField, inPathIdent, inFieldMatchings, inMType, inASTDefs)
    local
      Ident inid, fieldid, ident;
      PathIdent path;
      TypeSignature mtype, valtype;
      list<ASTDef> astDefs;

      list<tuple<Ident, MatchingExp>> fms;
      tuple<Ident, MatchingExp> fm;
      MatchingExp mexp;
      String reason;

    case ( inid, fieldid, _, {}, _, _ )
      equation
        reason = "Unresolved path '" + inid + "', cannot follow the path after a dot, no record match available to look down the path after '" + fieldid + "'.\n";
        valtype = UNRESOLVED_TYPE(reason);
      then
        ( valtype, {} );

    case ( inid, fieldid, path, (ident, mexp) :: fms, mtype, astDefs )
      equation
        true = stringEq(fieldid, ident);
        ( valtype, mexp ) = lookupUpdateMExpDotPath(inid, path, mexp, mtype, astDefs);
      then
        ( valtype, (ident, mexp) :: fms );

    case ( inid, fieldid, path, fm :: fms, mtype, astDefs )
      equation
        // false = stringEq(fieldid, ident) );
        ( valtype, fms ) = lookupUpdateMExpDotPathRecord(inid, fieldid, path, fms, mtype, astDefs);
      then
        ( valtype, fm :: fms );

    //shold not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!lookupUpdateMExpDotPathRecord failed for ident '" + inIdent + "'.\n");
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
  (outValueType, outFieldMatchings)
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

    case ( _, _, (ident, _) :: _, fields, _ )
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure( _ = lookupTupleList(fields, ident) );
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-Error!!!lookupUpdateMExpRecord failed in lookup for field (type) ident '" + ident + "'.\n");
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

    case ( inid, path, (mexp :: mexpLst), (mtype :: _), astDefs )
      equation
        ( valtype, mexp ) = lookupUpdateMatchingExp(inid, path, mexp, mtype, astDefs);
      then
        ( valtype, (mexp :: mexpLst) );

    case ( inid, path, (mexp :: mexpLst), (_ :: mtypeLst), astDefs )
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

    case ( NAMED_TYPE(), tagpath, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - (getFieldsForRecord) for case tag '" + pathIdentString(tagpath) + "' failed for reason above.\n");
      then
        fail();

    case ( _, tagpath, _)
      equation
        //failure(NAMED_TYPE(_) = mtype);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - for case tag '" + pathIdentString(tagpath) + "' the input type is not a NAME_TYPE hence not a union/record type.\n");
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
      Ident typeident, pckgident;
      PathIdent  typepath, typepckg;

    case ( IDENT(ident = typeident) )
      then
        (NONE(), typeident );

    case ( PATH_IDENT(ident = pckgident, path = IDENT(ident = typeident) ) )
      then
        ( SOME(IDENT(pckgident)), typeident);

    case ( PATH_IDENT(ident = pckgident, path = typepath as PATH_IDENT() ) )
      equation
        (SOME(typepckg), typeident) = splitPackageAndIdent(typepath);
      then
        ( SOME(PATH_IDENT(pckgident, typepckg)), typeident) ;

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!splitPackageAndIdent failed.\n");
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!makePathIdent failed.\n");
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

    case (NONE(), typeident,
          AST_DEF(
            importPackage = importckg,
            isDefault = true,
            types = typeLst) :: _ )
      equation
        typeinfo = lookupTupleList(typeLst, typeident);
      then
        (importckg, typeinfo);

    case ( SOME(typepckg), typeident,
          AST_DEF(
            importPackage = importckg,
            types = typeLst) :: _ )
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - getTypeInfo failed to lookup the type '" + typeident + "' for package '" + pathIdentString(typepckg) + "'.\n");
      then
        fail();
    */

    case ( typepckgOpt, typeident, ( _ :: astDefs) )
      equation
        (typepckg, typeinfo) = getTypeInfo(typepckgOpt, typeident, astDefs);
      then
        (typepckg, typeinfo);

    case (NONE(), typeident, {} )
      equation
        addSusanNotification("Error - getTypeInfo failed to lookup the type '" + typeident + "' after looking up all AST definitions.", dummySourceInfo);
      then fail();

    case ( SOME(typepckg), typeident, {} )
      equation
        addSusanNotification("getTypeInfo failed to lookup the type '" + pathIdentString(typepckg) + "." + typeident + "' after looking up all AST definitions.", dummySourceInfo);
      then fail();

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
      PathIdent  typepath;
      Option<PathIdent> typepckgOpt;
      list<ASTDef> astDefs;

    case ( NAMED_TYPE(name = typepath), astDefs )
      equation
        (typepckgOpt, typeident) = splitPackageAndIdent(typepath);
        (_, TI_ALIAS_TYPE(aliasType = dt)) = getTypeInfo(typepckgOpt, typeident, astDefs);
      then
        deAliasedType(dt, astDefs);

    else inType;

  end matchcontinue;
end deAliasedType;


protected function typesEqual "function typesEqual:
This function compares two type signatures.
Typed variables and already set type variables can be specified.
"
  input TypeSignature inType "may have type variables - not dealiased";
  input TypeSignature inTypeConcrete "must be conrete - not dealiased";
  input list<Ident> inTypeVars;
  input TypedIdents inSetTypeVars;
  input list<ASTDef> inASTDefs;

  output TypedIdents outSetTypeVars;
algorithm
  outSetTypeVars := matchcontinue(inType, inTypeConcrete, inTypeVars, inSetTypeVars, inASTDefs)
    local
      TypeSignature ota, otb, ty, tyConcrete, tyConcreteDA;
      list<TypeSignature> otaLst, otbLst;
      Ident tid;
      list<Ident> tyVars;
      TypedIdents setTyVars;
      list<ASTDef> astDefs;


    case ( LIST_TYPE(ofType = ota), LIST_TYPE(ofType = otb), tyVars, setTyVars, astDefs )
      then
        typesEqual(ota, otb, tyVars, setTyVars, astDefs);

    case ( ARRAY_TYPE(ofType = ota), ARRAY_TYPE(ofType = otb), tyVars, setTyVars, astDefs )
      then
        typesEqual(ota, otb, tyVars, setTyVars, astDefs);

    case ( OPTION_TYPE(ofType = ota), OPTION_TYPE(ofType = otb), tyVars, setTyVars, astDefs )
      then
        typesEqual(ota, otb, tyVars, setTyVars, astDefs);

    case ( TUPLE_TYPE(ofTypes = otaLst), TUPLE_TYPE(ofTypes = otbLst), tyVars, setTyVars, astDefs )
      then
        typesEqualList(otaLst, otbLst, tyVars, setTyVars, astDefs);

    //concrete named type with PathIdent that is not a type variable
    case ( NAMED_TYPE(name = PATH_IDENT()), tyConcrete, _, setTyVars, astDefs )
      equation
        ty = deAliasedType(inType, astDefs);
        tyConcrete = deAliasedType(tyConcrete, astDefs);
        typesEqualConcrete(ty, tyConcrete, astDefs);
      then
        setTyVars;

    //concrete named type with Ident that is not a type variable
    case ( NAMED_TYPE(name = IDENT(tid)), tyConcrete, tyVars, setTyVars, astDefs )
      equation
        false = listMember(tid, tyVars);
        ty = deAliasedType(inType, astDefs);
        tyConcrete = deAliasedType(tyConcrete, astDefs);
        typesEqualConcrete(ty, tyConcrete, astDefs);
      then
        setTyVars;

    //try set type vars first
    case ( NAMED_TYPE(name = IDENT(tid)), tyConcrete, (_::_), setTyVars, astDefs )
      equation
        ty = lookupTupleList(setTyVars, tid);
        //true = listMember(na, tyVars); //must be true
        tyConcreteDA = deAliasedType(tyConcrete, astDefs);
        typesEqualConcrete(ty, tyConcreteDA, astDefs);
      then
        setTyVars;

    //failed after found set type var
    case ( NAMED_TYPE(name = IDENT(tid)), tyConcrete, (_::_), setTyVars, astDefs )
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        ty = lookupTupleList(setTyVars, tid);
        //true = listMember(na, tyVars); //must be true
        tyConcreteDA = deAliasedType(tyConcrete, astDefs);
        failure( typesEqualConcrete(ty, tyConcreteDA, astDefs) );
        Debug.trace("Error - unmatched type for type variable '" + tid
           + "'. Firstly inferred '" + typeSignatureString(ty)
           + "', next inferred '" + typeSignatureString(tyConcrete)
           + "'(dealiased '" + typeSignatureString(tyConcreteDA) + "').\n"
            );
      then
        fail();


    //infer/make a new set type var
    case ( NAMED_TYPE(name = IDENT(tid)), tyConcrete, tyVars as (_::_), setTyVars, astDefs )
      equation
        failure(_ = lookupTupleList(setTyVars, tid));
        true = listMember(tid, tyVars);
        tyConcreteDA = deAliasedType(tyConcrete, astDefs);
      then
        (tid, tyConcreteDA) :: setTyVars;


    //?? don't know if this is needed
    case ( UNRESOLVED_TYPE(), UNRESOLVED_TYPE(_), _, setTyVars, _ )
      then
        setTyVars;

    // all the others can be matched structurally (as they have no structure)
    //except NAMED_TYPE that was matched above
    case ( ty, tyConcrete, _, setTyVars,_ )
      equation
        failure(NAMED_TYPE() = ty);
        equality(ty = tyConcrete);
      then
        setTyVars;

  end matchcontinue;
end typesEqual;


protected function typesEqualConcrete "function typesEqualConcrete:
This function compares two type signatures.
It assumes the input types are deAliasedType-ed.
"
  input TypeSignature inTypeA "must be concrete - dealiased without type variables";
  input TypeSignature inTypeB "must be concrete - dealiased without type variables";
  input list<ASTDef> inASTDefs;

algorithm
  _:= matchcontinue(inTypeA, inTypeB, inASTDefs)
    local
      TypeSignature tyA, tyB;
      PathIdent na, nb;
      list<ASTDef> astDefs;

    //named types
    case ( NAMED_TYPE(name = na), NAMED_TYPE(name = nb), _ )
      equation
        equality(na = nb);
      then
        ();

    //non-NAME_TYPE can call typesEqual ... the above case prevents infinite recursion loop for NAMED_TYPE
    case ( tyA, tyB, astDefs )
      equation
        failure(NAMED_TYPE() = tyA);
        _ = typesEqual(tyA, tyB, {},{}, astDefs);
      then
        ();

  end matchcontinue;
end typesEqualConcrete;


protected function typesEqualList
  input list<TypeSignature> inTypeAList;
  input list<TypeSignature> inTypeBList;
  input list<Ident> inTypeVars;
  input TypedIdents inSetTypeVars;
  input list<ASTDef> inASTDefs;

  output TypedIdents outSetTypeVars;
algorithm
  outSetTypeVars := match(inTypeAList, inTypeBList, inTypeVars, inSetTypeVars, inASTDefs)
    local
      TypeSignature ota, otb;
      list<TypeSignature> otaLst, otbLst;
      list<ASTDef> astDefs;
      list<Ident> tyVars;
      TypedIdents setTyVars;

    case ( {}, {},_ , setTyVars, _)
      then setTyVars;

    case ( ota :: otaLst, otb :: otbLst, tyVars, setTyVars, astDefs )
      equation
        setTyVars = typesEqual(ota, otb, tyVars, setTyVars, astDefs);
      then
        typesEqualList(otaLst, otbLst, tyVars, setTyVars, astDefs);

  end match;
end typesEqualList;


protected function specializeType "function specializeType:
This function specializes type with set type variables and checks if all of them are replaced.
"
  input TypeSignature inType "may have type variables";
  input list<Ident> inTypeVars;
  input TypedIdents inSetTypeVars;

  output TypeSignature outType;
algorithm
  outType := matchcontinue(inType, inTypeVars, inSetTypeVars)
    local
      TypeSignature ota,  tyConcrete;
      list<TypeSignature> otaLst;
      Ident tid;
      list<Ident> tyVars;
      TypedIdents setTyVars;


    case ( LIST_TYPE(ofType = ota), tyVars, setTyVars)
      equation
        ota = specializeType(ota, tyVars, setTyVars);
      then
        LIST_TYPE(ota);

    case ( ARRAY_TYPE(ofType = ota), tyVars, setTyVars)
      equation
        ota = specializeType(ota, tyVars, setTyVars);
      then
        ARRAY_TYPE(ota);

    case ( OPTION_TYPE(ofType = ota), tyVars, setTyVars)
      equation
        ota = specializeType(ota, tyVars, setTyVars);
      then
        OPTION_TYPE(ota);

    case ( TUPLE_TYPE(ofTypes = otaLst), tyVars, setTyVars)
      equation
        otaLst = List.map2(otaLst, specializeType, tyVars, setTyVars);
      then
        TUPLE_TYPE(otaLst);

    //normal named type that is not a type variable
    case ( tyConcrete as NAMED_TYPE(name = IDENT(tid)), tyVars, _)
      equation
        false = listMember(tid, tyVars);
      then
        tyConcrete;

    //try set type vars first
    case ( NAMED_TYPE(name = IDENT(tid)), (_::_), setTyVars)
      equation
        tyConcrete = lookupTupleList(setTyVars, tid);
      then
        tyConcrete;

    //error - is type var but not assigned/inferred
    case ( NAMED_TYPE(name = IDENT(tid)), tyVars as (_::_), setTyVars )
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        true = listMember(tid, tyVars);
        failure(_ = lookupTupleList(setTyVars, tid));
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - cannot infer type variable '" + tid + "'.\n" );
      then
        fail();


    // all the others are concrete already
    //except NAMED_TYPE with ident that was dealt above
    case ( tyConcrete, _, _)
      equation
        failure(NAMED_TYPE(name = IDENT()) = tyConcrete);
      then
        tyConcrete;

  end matchcontinue;
end specializeType;

//for now, succeed or  error + fail
public function getFunSignature
  input PathIdent inFunName;
  input SourceInfo inSourceInfo;
  input TemplPackage inTplPackage;

  output PathIdent outPath;
  output TypedIdents outInArgs;
  output TypedIdents outOutArgs;
  output list<Ident> outTypeVars;
algorithm
  (outPath, outInArgs, outOutArgs, outTypeVars)
  := matchcontinue (inFunName, inSourceInfo, inTplPackage)
    local
      PathIdent fname, funpckg;
      Option<PathIdent> funpckgOpt;
      Ident templname, fident;
      list<Ident> tyVars;
      list<tuple<Ident,TemplateDef>> templateDefs;
      list<ASTDef> astDefs;
      TypedIdents iargs, oargs;
      String msg;

    case (fname as IDENT(ident = templname), _, TEMPL_PACKAGE(templateDefs = templateDefs))
      equation
        TEMPLATE_DEF(args = iargs)  =  lookupTupleList(templateDefs, templname);
        iargs = imlicitTxtArg :: iargs;
        oargs = List.filter(iargs, isText); //just for now, it is not inferred from the usage
        //not encoding templates now
        //templname = encodeIdent(templname);
        //fname = IDENT( templname );
      then
        (fname, iargs, oargs, {});

    case (IDENT(templname), _, TEMPL_PACKAGE(templateDefs = templateDefs))
      equation
        _  =  lookupTupleList(templateDefs, templname);
        msg = "Constant template '" + templname + "' is used in a function/template context (while it is defined as a constant).";
        addSusanError(msg, inSourceInfo);
      then
        fail();

    case (fname, _, TEMPL_PACKAGE(astDefs = astDefs))
      equation
        NAMED_TYPE(fname) = deAliasedType(NAMED_TYPE(fname), astDefs);
        (funpckgOpt, fident) = splitPackageAndIdent(fname);
        (funpckg, TI_FUN_TYPE(inArgs = iargs, outArgs = oargs, tyVars = tyVars))
         = getTypeInfo(funpckgOpt, fident, astDefs);
        fname = if valueEq(IDENT("builtin"), funpckg) then IDENT(fident) else makePathIdent(funpckg, fident);
      then
        (fname, iargs, oargs, tyVars);

    else
      equation
        msg = "Unresolved template/function name '" + pathIdentString(inFunName) + "'.";
        addSusanError(msg, inSourceInfo);
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

    case ( _,NONE())
      then
        ();

    case ( path, SOME(pckgpath) )
      equation
        equality(path = pckgpath);
      then
        ();

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!checkPackageOpt failed - package paths are not the same.\n");
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
  (outFields) := matchcontinue (inTagIdent, inTypeInfo, inTypeIdent)
    local
      Ident typeident, tagident;
      TypeInfo typeinfo;
      TypedIdents fields;
      list<tuple<Ident, TypedIdents>> rectags;

    case ( tagident, TI_UNION_TYPE(recTags = rectags) , _)
      equation
        fields = lookupTupleList(rectags, tagident);
      then
        fields;

    case ( tagident, TI_UNION_TYPE(recTags = rectags) , typeident)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure(_ = lookupTupleList(rectags, tagident));
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - getFields failed to lookup the union tag '" + tagident + "', that is not found in type '" + typeident + "'.\n");
      then
        fail();

    case ( tagident, TI_RECORD_TYPE(fields = fields), typeident )
      equation
        true = stringEq(tagident, typeident);
      then
        fields;

    case ( tagident, TI_RECORD_TYPE(), typeident )
      equation
        false = stringEq(tagident, typeident);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("Error - getFields failed to match the tag '" + tagident + "', the type '" + typeident + "' expected.\n");
      then
        fail();

    //should not ever happen
    case ( _, typeinfo, _ )
      equation
        failure(TI_UNION_TYPE() = typeinfo);
        failure(TI_RECORD_TYPE() = typeinfo);
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- getFields failed - the typeinfo is neither union nor record type.\n");
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
  match (inTagIdent, inTypeInfo, inTypeIdent)
    local
      Ident typeident, tagident;
      list<tuple<Ident, TypedIdents>> rectags;

    case ( tagident, TI_UNION_TYPE(recTags = rectags) , _)
      equation
        _ = lookupTupleList(rectags, tagident);
      then ();

    case ( tagident, TI_RECORD_TYPE(), typeident )
      equation
        true = stringEq(tagident, typeident);
      then ();
  end match;
end isRecordTag;

public function fullyQualifyASTDefs
  input list<ASTDef> inASTDefs;
  output list<ASTDef> outFullyQualifiedASTDefs;
algorithm
  outFullyQualifiedASTDefs := matchcontinue inASTDefs
    local
      list<tuple<Ident, TypeInfo>> typeLst;
      PathIdent importckg;
      list<ASTDef> restAstDefs;
      Boolean isdefault;

    case ( {} ) then {};

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
            types         = typeLst) :: _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        failure(typeLst = listMap1Tuple22(typeLst, fullyQualifyAstTypeInfo, importckg));
        Debug.trace("-fullyQualifyASTDefs failed for importckg = " + pathIdentString(importckg) + " .\n");
      then
        fail();

    //should not happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!! fullyQualifyASTDefs failed .\n");
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
      list<Ident> tyvars;

    case ( TI_UNION_TYPE( recTags = recTags ) , importpckg )
      equation
        recTags = listMap2Tuple22(recTags, fullyQualifyAstTypedIdents, importpckg, {});
      then
        TI_UNION_TYPE(recTags);

    case ( TI_RECORD_TYPE( fields = fields ) , importpckg )
      equation
        fields = fullyQualifyAstTypedIdents(fields, importpckg, {});
      then
        TI_RECORD_TYPE(fields);

    case ( TI_ALIAS_TYPE( aliasType = aliasType ) , importpckg )
      equation
        aliasType = fullyQualifyAstTypeSignature(aliasType, importpckg, {});
      then
        TI_ALIAS_TYPE(aliasType);

    case ( TI_FUN_TYPE( inArgs = inArgs, outArgs = outArgs, tyVars = tyvars) , importpckg )
      equation
        inArgs  = fullyQualifyAstTypedIdents(inArgs, importpckg, tyvars);
        outArgs = fullyQualifyAstTypedIdents(outArgs, importpckg, tyvars);
      then
        TI_FUN_TYPE( inArgs, outArgs, tyvars);

    case ( TI_CONST_TYPE( constType = constType ) , importpckg )
      equation
        constType = fullyQualifyAstTypeSignature(constType, importpckg, {});
      then
        TI_CONST_TYPE( constType );


    //should not happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!! fullyQualifyAstTypeInfo failed .\n");
      then
        fail();
  end matchcontinue;
end fullyQualifyAstTypeInfo;


public function fullyQualifyAstTypedIdents
  input TypedIdents inASTDefTypedIdents;
  input PathIdent inImportPackage;
  input list<Ident> inTypeVars;

  output TypedIdents outASTDefTypedIdents;
algorithm
  outASTDefTypedIdents :=
  listMap2Tuple22(inASTDefTypedIdents, fullyQualifyAstTypeSignature, inImportPackage, inTypeVars);
end fullyQualifyAstTypedIdents;


public function fullyQualifyAstTypeSignature
  input TypeSignature inASTDefTypeSignature;
  input PathIdent inImportPackage;
  input list<Ident> inTypeVars;

  output TypeSignature outASTDefTypeSignature;
algorithm
  outASTDefTypeSignature := matchcontinue (inASTDefTypeSignature, inImportPackage, inTypeVars)
    local
      list<TypeSignature> typeLst;
      Ident typeident;
      list<Ident> tyVars;
      PathIdent importpckg, na;
      TypeSignature ota, ts;

    case ( LIST_TYPE(ofType = ota), importpckg, tyVars )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg, tyVars);
      then
        LIST_TYPE(ota);

    case ( ARRAY_TYPE(ofType = ota), importpckg, tyVars )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg, tyVars);
      then
        ARRAY_TYPE(ota);

    case ( OPTION_TYPE(ofType = ota), importpckg, tyVars )
      equation
        ota = fullyQualifyAstTypeSignature(ota, importpckg, tyVars);
      then
        OPTION_TYPE(ota);

    case ( TUPLE_TYPE(ofTypes = typeLst), importpckg, tyVars )
      equation
        typeLst = List.map2(typeLst, fullyQualifyAstTypeSignature, importpckg, tyVars);
      then
        TUPLE_TYPE(typeLst);

    //exclude a type variable from qualification
    case ( ts as NAMED_TYPE(name = IDENT(ident = typeident)),  _, tyVars )
      equation
        true = listMember(typeident, tyVars);
      then
        ts;


    //qualify  and convert  Tpl.Text -> TEXT_TYPE()
    case ( NAMED_TYPE(name = IDENT(ident = typeident)),  importpckg, _ )
      equation
        na = makePathIdent(importpckg, typeident);
        ts = convertNameTypeIfIntrinsic(na);
      then
        ts;

    //convert  Tpl.Text -> TEXT_TYPE()
    case ( NAMED_TYPE(name = na as PATH_IDENT()),  _, _ )
      equation
        ts = convertNameTypeIfIntrinsic(na);
      then
        ts;

    //all the others
    else inASTDefTypeSignature;

  end matchcontinue;
end fullyQualifyAstTypeSignature;


public function convertNameTypeIfIntrinsic
  input PathIdent inNameOfType;
  output TypeSignature outTypeSignature;
algorithm
  outTypeSignature := match (inNameOfType)

    case ( PATH_IDENT(ident = "Tpl", path = IDENT("Text")) )
      then
        TEXT_TYPE();

    //case ( PATH_IDENT(ident = "Tpl", path = IDENT("StringToken")) )
    //  then
    //    STRING_TOKEN_TYPE();


    else NAMED_TYPE(inNameOfType);

  end match;
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

    case ( def as STR_TOKEN_DEF(), _)
      then
        def;

    case ( TEMPLATE_DEF(args = targs, lesc = lesc, resc = resc, exp = texp), astDefs)
      equation
        targs = listMap1Tuple22(targs, fullyQualifyTemplateTypeSignature, astDefs);
      then
        TEMPLATE_DEF(targs, lesc, resc, texp);

    //can fail on errror
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("- fullyQualifyTemplateDef failed .\n");
      then
        fail();

  end matchcontinue;
end fullyQualifyTemplateDef;


public function fullyQualifyTemplateTypeSignature
  input TypeSignature inTemplateTypeSignature;
  input list<ASTDef> inASTDefs;

  output TypeSignature outFullyQualifiedTypeSignature;
algorithm
  outFullyQualifiedTypeSignature := matchcontinue (inTemplateTypeSignature, inASTDefs)
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
        typeLst = List.map1(typeLst, fullyQualifyTemplateTypeSignature, astDefs);
      then
        TUPLE_TYPE(typeLst);

    //a special case for Text ... Text is an intrinsic type from Susan's viewpoint
    case ( NAMED_TYPE(name = IDENT("Text")),  _ )
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
    else inTemplateTypeSignature;
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

    case ( (a, itemB) :: _, itemA )
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

    else (inTuple :: inList);
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
Assuming the lists have distinct tuples (no multiple first elements occurrences)."
  input list<tuple<Type_a,Type_b>> inListToAlign;
  input list<tuple<Type_a,Type_c>> inListAlignBy;

  output list<tuple<Type_a,Type_b>> outAlignedList;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
algorithm
  outAlignedList := matchcontinue(inListToAlign, inListAlignBy)
    local
       Type_a a;
       Type_b b;
       list<tuple<Type_a,Type_b>> lst, lstAl;
       list<tuple<Type_a,Type_c>> lstBy;

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
  outList := match(inList, inFun_Tbd_to_Tc, inExtraArg)
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


  end match;
end listMap1Tuple22;


protected function listMap2Tuple22
  input list<tuple<Type_a,Type_b>> inList;
  input Fun_Tbde_to_Tc inFun_Tbde_to_Tc;
  input Type_d inExtraArg;
  input Type_e inExtraArg2;

  output list<tuple<Type_a,Type_c>> outList;

  partial function Fun_Tbde_to_Tc
    input Type_b inTypeB;
    input Type_d inTypeD;
    input Type_e inExtraArg2;
    output Type_c outTypeC;
    replaceable type Type_b subtypeof Any;
    replaceable type Type_c subtypeof Any;
  end Fun_Tbde_to_Tc;
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;
  replaceable type Type_c subtypeof Any;
  replaceable type Type_d subtypeof Any;
  replaceable type Type_e subtypeof Any;
algorithm
  outList := match(inList, inFun_Tbde_to_Tc, inExtraArg, inExtraArg2)
    local
       Type_a a;
       Type_b itemB;
       Type_c itemC;
       Type_d extarg;
       Type_e extarg2;
       Fun_Tbde_to_Tc funBDEtoC;
       list<tuple<Type_a,Type_b>> restB;
       list<tuple<Type_a,Type_c>> restC;

    case ( {}, _, _, _) then {};

    case ( (a, itemB) :: restB, funBDEtoC, extarg, extarg2 )
      equation
        itemC = funBDEtoC(itemB, extarg, extarg2);
        restC = listMap2Tuple22(restB, funBDEtoC, extarg, extarg2);
      then
        ((a, itemC) :: restC);


  end match;
end listMap2Tuple22;

//**************************************
// *** debug output functions
//**************************************

public function addSusanError
  input String inErrMsg;
  input SourceInfo inInfo;
algorithm
  if Flags.isSet(Flags.FAILTRACE) then
    Debug.traceln("Error - " + inErrMsg);
  end if;
  Error.addSourceMessage(Error.SUSAN_ERROR, {inErrMsg}, inInfo);
end addSusanError;

protected function addSusanNotification
  input String inErrMsg;
  input SourceInfo inInfo;
algorithm
  Error.addSourceMessage(Error.SUSAN_NOTIFY, {inErrMsg}, inInfo);
end addSusanNotification;

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
    else
        false;

  end matchcontinue;
end canBeEscapedUnquoted;


protected function canBeEscapedUnquotedChars
  input list<String> inChars;
  output Boolean outCanBeUnquoted;
algorithm
  outCanBeUnquoted :=
  match(inChars)
    local
      String c;
      list<String> chars;

    case ({}) then true;

        // \a \b \f \r \v  ... TODO: Error in the .srz or .c compilation(\r)
    case ( c  :: chars)
      guard (c == "\'")
         or (c == "\"")
         or (c == "?")
         or (c == "\\")
         or (c == "\n")
         or (c == "\t")
         or (c == " ")
      then canBeEscapedUnquotedChars(chars);

    else false;

  end match;
end canBeEscapedUnquotedChars;


public function canBeOnOneLine
    input list<String> inStringList;
    output Boolean outCanBeOnOneLine;
algorithm
  outCanBeOnOneLine :=
        (listLength(inStringList) <= 4)
        and stringLength(stringAppendList(inStringList)) <= 10;
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
        ident = ident + "." + pathIdentString(path);
      then
        ident;

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!pathIdentString failed.\n");
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

annotation(__OpenModelica_Interface="susan");
end TplAbsyn;
