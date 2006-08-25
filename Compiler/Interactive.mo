package Interactive "
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)
 

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
 
 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Linköpings universitet nor the names of its
  contributors may be used toendorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  $Id$
  
  This module contain functionality for model management, expression evaluation, etc. 
  in the interactive environment.
  The module defines a symboltable used in the interactive environment containing:
  - Modelica models (described using Absyn AST)
  - Variable bindings
  - Compiled functions (so they do not need to be recompiled)
  - Instantiated classes (that can be reused, not impl. yet)
  - Modelica models in SCode form (to speed up instantiation. not impl. yet)
"

public import OpenModelica.Compiler.Absyn;

public import OpenModelica.Compiler.SCode;

public import OpenModelica.Compiler.DAE;

public import OpenModelica.Compiler.Types;

public import OpenModelica.Compiler.Values;

public import OpenModelica.Compiler.Env;

public import OpenModelica.Compiler.Settings;

public 
uniontype InteractiveStmt "An Statement given in the interactive environment can either be 
    an Algorithm statement or an expression.

  - Interactive Statement"
  record IALG
    Absyn.AlgorithmItem algItem "algItem" ;
  end IALG;

  record IEXP
    Absyn.Exp exp "exp" ;
  end IEXP;

end InteractiveStmt;

public 
uniontype InteractiveStmts "Several interactive statements are used in Modelica scripts.
  - Interactive Statements"
  record ISTMTS
    list<InteractiveStmt> interactiveStmtLst "interactiveStmtLst" ;
    Boolean semicolon "semicolon; true = statement ending with a semicolon. The result will not be shown in the interactive environment." ;
  end ISTMTS;

end InteractiveStmts;

public 
uniontype InstantiatedClass "- Instantiated Class"
  record INSTCLASS
    Absyn.Path qualName "qualName ;  The F.Q.name of the inst:ed class" ;
    list<DAE.Element> daeElementLst "daeElementLst ; The list of DAE elements" ;
    Env.Env env "env ; The env of the inst:ed class" ;
  end INSTCLASS;

end InstantiatedClass;

public 
uniontype InteractiveVariable "- Interactive Variable"
  record IVAR
    Absyn.Ident varIdent "varIdent ; The variable identifier" ;
    Values.Value value "value ; The value" ;
    Types.Type type_ "type ; The type of the expression" ;
  end IVAR;

end InteractiveVariable;

public 
uniontype InteractiveSymbolTable "- Interactive Symbol Table"
  record SYMBOLTABLE
    Absyn.Program ast "ast ; The ast" ;
    SCode.Program explodedAst "explodedAst ; The exploded ast" ;
    list<InstantiatedClass> instClsLst "instClsLst ;  List of instantiated classes" ;
    list<InteractiveVariable> lstVarVal "lstVarVal ; List of variables with values" ;
    list<tuple<Absyn.Path, Types.Type>> compiledFunctions "compiledFunctions ; List of compiled functions, F.Q name + type" ;
  end SYMBOLTABLE;

end InteractiveSymbolTable;

public 
uniontype Component "- a component in a class
  this is used in extracting all the components in all the classes"
  record COMPONENTITEM
    Absyn.Path the1 "the class where the component is" ;
    Absyn.Path the2 "the type of the component" ;
    Absyn.ComponentRef the3 "the name of the component" ;
  end COMPONENTITEM;

  record EXTENDSITEM
    Absyn.Path the1 "the class which is extended" ;
    Absyn.Path the2 "the class which is the extension" ;
  end EXTENDSITEM;

end Component;

public 
uniontype Components
  record COMPONENTS
    list<Component> componentLst;
    Integer the "the number of components in list. used to optimize the get_dependency_on_class" ;
  end COMPONENTS;

end Components;

public 
uniontype ComponentReplacement
  record COMPONENTREPLACEMENT
    Absyn.Path which1 "which class contain the old cref" ;
    Absyn.ComponentRef the2 "the old cref" ;
    Absyn.ComponentRef the3 "the new cref" ;
  end COMPONENTREPLACEMENT;

end ComponentReplacement;

public 
uniontype ComponentReplacementRules
  record COMPONENTREPLACEMENTRULES
    list<ComponentReplacement> componentReplacementLst;
    Integer the "the number of rules" ;
  end COMPONENTREPLACEMENTRULES;

end ComponentReplacementRules;

protected import OpenModelica.Compiler.Connect;

protected import OpenModelica.Compiler.Dump;

protected import OpenModelica.Compiler.Debug;

protected import OpenModelica.Compiler.Util;

protected import OpenModelica.Compiler.Parser;

protected import OpenModelica.Compiler.Prefix;

protected import OpenModelica.Compiler.Mod;

protected import OpenModelica.Compiler.Lookup;

protected import OpenModelica.Compiler.ClassInf;

protected import OpenModelica.Compiler.Exp;

protected import OpenModelica.Compiler.Inst;

protected import OpenModelica.Compiler.Static;

protected import OpenModelica.Compiler.ModUtil;

protected import OpenModelica.Compiler.Print;

protected import OpenModelica.Compiler.System;

protected import OpenModelica.Compiler.ClassLoader;

protected import OpenModelica.Compiler.Ceval;

protected import OpenModelica.Compiler.Error;

public constant InteractiveSymbolTable emptySymboltable=SYMBOLTABLE(Absyn.PROGRAM({},Absyn.TOP()),{},{},
          {},{}) "Empty Interactive Symbol Table" ;

public function evaluate "function: evaluate
 
  This function evaluates expressions or statements feed interactively to the compiler.
 
  inputs:   (InteractiveStmts, InteractiveSymbolTable, bool /* verbose */) 
  outputs:   string:  
                     The resulting string after evaluation. If an error has occurred, this string
                     will be empty. The error messages can be retrieved by calling print_messages_str()
                     in Error.rml.
             InteractiveSymbolTable 
"
  input InteractiveStmts inInteractiveStmts;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  input Boolean inBoolean;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inInteractiveStmts,inInteractiveSymbolTable,inBoolean)
    local
      String res,res_1,res2,res_2;
      InteractiveSymbolTable newst,st,newst_1;
      Boolean echo,semicolon,verbose;
      InteractiveStmt x;
      list<InteractiveStmt> xs;
    case (ISTMTS(interactiveStmtLst = {x},semicolon = semicolon),st,verbose)
      equation 
        (res,newst) = evaluate2(ISTMTS({x},verbose), st);
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
      then
        (res_1,newst);
    case (ISTMTS(interactiveStmtLst = (x :: xs),semicolon = semicolon),st,verbose)
      equation 
        (res,newst) = evaluate2(ISTMTS({x},semicolon), st);
        echo = getEcho();
        res_1 = selectResultstr(res, semicolon, verbose, echo);
        (res2,newst_1) = evaluate(ISTMTS(xs,semicolon), newst, verbose);
        res_2 = Util.stringAppendList({res_1,res2});
      then
        (res_2,newst_1);
  end matchcontinue;
end evaluate;



protected function selectResultstr "function: selectResultstr
 
  Returns result string depending on three boolean variables
  - semicolon
  - verbose
  - echo
  
  inputs:  (string,
              bool, /* semicolon */
              bool, /* verbose */
              bool  /* echo */)
  outputs:  string
"
  input String inString1;
  input Boolean inBoolean2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString1,inBoolean2,inBoolean3,inBoolean4)
    local String str;
    case (str,_,_,false) then "";  /* echo off allways empty string */ 
    case (str,_,true,_) then str;  /* .. verbose on allways return str */ 
    case (str,true,_,_) then "";  /* ... semicolon, no resultstr */ 
    case (str,false,_,_) then str; 
  end matchcontinue;
end selectResultstr;

protected function getEcho "function: getEcho
 
  Return echo variable, which determines if result should be printed or not.
"
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inInteractiveSymbolTable)
    local
      list<Env.Frame> env;
      Boolean res;
      InteractiveSymbolTable st;
    case ()
      equation 
        0 = Settings.getEcho();
      then
        false;
    case () then true; 
  end matchcontinue;
end getEcho;

public function typeCheckFunction "function: typeCheckFunction
 
  Type check a function. 
  The function will fail iff a function has illegally typed. Errors are handled
  using side effects in Error.rml
"
  input Absyn.Program inProgram;
  input InteractiveSymbolTable inInteractiveSymbolTable;
algorithm 
  _:=
  matchcontinue (inProgram,inInteractiveSymbolTable)
    local
      Absyn.Restriction restriction;
      InteractiveSymbolTable st;
      list<Env.Frame> env,env_1;
      SCode.Class scode_class;
      list<DAE.Element> d;
      Absyn.Class absyn_class,cls;
      Integer len;
      list<Absyn.Class> class_list,morecls;
      Absyn.Within w;
    case (Absyn.BEGIN_DEFINITION(path = _),_) then ();  /* Do not typecheck the following */ 
    case (Absyn.END_DEFINITION(name = _),_) then (); 
    case (Absyn.COMP_DEFINITION(element = _),_) then (); 
    case (Absyn.IMPORT_DEFINITION(importElementFor = _),_) then (); 
    case (Absyn.PROGRAM(classes = {Absyn.CLASS(restricion = restriction)}),st) /* If it is not a function, return succeess */ 
      equation 
        failure(equality(restriction = Absyn.R_FUNCTION()));
      then
        ();
    case (Absyn.PROGRAM(classes = {absyn_class}),st) /* Type check the function */ 
      equation 
        env = buildEnvFromSymboltable(st);
        scode_class = SCode.elabClass(absyn_class);
        (_,env_1,d) = Inst.implicitFunctionInstantiation(Env.emptyCache,env, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          scode_class, {});
      then
        ();
    case (Absyn.PROGRAM(classes = (class_list as (cls :: morecls)),within_ = w),st) /* Recursively go through all classes */ 
      equation 
        len = listLength(class_list);
        failure(equality(len = 1)) "avoid recurs forever" ;
        typeCheckFunction(Absyn.PROGRAM({cls},w), st);
        typeCheckFunction(Absyn.PROGRAM(morecls,w), st);
      then
        ();
  end matchcontinue;
end typeCheckFunction;

public function evaluate2 "function: evaluate2
 
  Helper function to evaluate.
"
  input InteractiveStmts inInteractiveStmts;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inInteractiveStmts,inInteractiveSymbolTable)
    local
      String vars,str,str_1;
      InteractiveSymbolTable st,newst,st_1;
      InteractiveStmts stmts;
      Absyn.AlgorithmItem algitem;
      Boolean outres;
      Absyn.Exp exp;
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "listVariables"),functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = {})))}),(st as SYMBOLTABLE(lstVarVal = vars)))
      equation 
        vars = getVariableNames(vars);
        str = stringAppend(vars, "\n");
      then
        (str,st);
    case ((stmts as ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = _))})),st)
      equation 
        (str,newst) = evaluateGraphicalApi(stmts, st);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,newst);
    case ((stmts as ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = _))})),st)
      equation 
        (str,newst) = evaluateGraphicalApi2(stmts, st);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,newst);
    case (ISTMTS(interactiveStmtLst = {IALG(algItem = (algitem as Absyn.ALGORITHMITEM(algorithm_ = _)))},semicolon = outres),st) /* Evaluate algorithm statements in  evaluate_alg_stmt() */ 
      equation 
        (str,st_1) = evaluateAlgStmt(algitem, st);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,st_1);
    case ((stmts as ISTMTS(interactiveStmtLst = {IEXP(exp = exp)})),st) /* Evaluate expressions in evaluate_expr_to_str() */ 
      equation 
        (str,st_1) = evaluateExprToStr(exp, st);
        str_1 = stringAppend(str, "\n");
      then
        (str_1,st_1);
  end matchcontinue;
end evaluate2;

protected function evaluateAlgStmt "function: evaluateAlgStmt
  
   This function takes an \'AlgorithmItem\', i.e. a statement located in an 
   algorithm section, and a symboltable as input arguments. The statements 
   are recursivly evalutated and a new interactive symbol table is returned.
"
  input Absyn.AlgorithmItem inAlgorithmItem;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inAlgorithmItem,inInteractiveSymbolTable)
    local
      list<Env.Frame> env;
      Exp.Exp econd,msg_1,sexp,srexp;
      Types.Properties prop,rprop;
      InteractiveSymbolTable st_1,st_2,st_3,st_4,st,newst;
      Absyn.Exp cond,msg,exp,rexp;
      Absyn.Program p;
      String str,ident;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Values.Value value;
      list<tuple<Types.TType, Option<Absyn.Path>>> types;
      list<String> idents;
      list<Values.Value> values;
      list<Absyn.Exp> crefexps;
      tuple<Absyn.Exp, list<Absyn.AlgorithmItem>> cond1;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> cond2,cond3,elseifexpitemlist;
      list<Absyn.AlgorithmItem> algitemlist,elseitemlist;
      String iter;
			list<Absyn.AlgorithmItem> algItemList;
      Values.Value startv, stepv, stopv;
      Absyn.Exp starte, stepe, stope;			
    case (Absyn.ALGORITHMITEM(
      		algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),
      		functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg}))),
      		(st as SYMBOLTABLE(ast = p)))
      equation  
        env = buildEnvFromSymboltable(st);
        (_,econd,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache,env, cond, true, SOME(st));
        (_,Values.BOOL(true),SOME(st_2)) = Ceval.ceval(Env.emptyCache,env, econd, true, SOME(st_1), NONE, Ceval.MSG());
      then 
        ("",st_2);
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_NORETCALL(functionCall = Absyn.CREF_IDENT(name = "assert"),functionArgs = Absyn.FUNCTIONARGS(args = {cond,msg}))),(st as SYMBOLTABLE(ast = p)))
      equation 
        env = buildEnvFromSymboltable(st);
        (_,msg_1,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache,env, msg, true, SOME(st));
        (_,Values.STRING(str),SOME(st_2)) = Ceval.ceval(Env.emptyCache,env, msg_1, true, SOME(st_1), NONE, Ceval.MSG());
      then
        (str,st_2);
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_ASSIGN(assignComponent = Absyn.CREF_IDENT(name = ident,subscripts = {}),value = exp)),(st as SYMBOLTABLE(ast = p)))
      equation 
        env = buildEnvFromSymboltable(st);
        (_,sexp,Types.PROP(t,_),SOME(st_1)) = Static.elabExp(Env.emptyCache,env, exp, true, SOME(st));
        (_,value,SOME(st_2)) = Ceval.ceval(Env.emptyCache,env, sexp, true, SOME(st_1), NONE, Ceval.MSG());
        str = Values.valString(value);
        newst = addVarToSymboltable(ident, value, t, st_2);
      then
        (str,newst);
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_TUPLE_ASSIGN(tuple_ = Absyn.TUPLE(expressions = crefexps),value = rexp)),(st as SYMBOLTABLE(ast = p))) /* Since expressions cannot be tuples an empty string is returned */ 
      equation 
        env = buildEnvFromSymboltable(st);
        (_,srexp,rprop,SOME(st_1)) = Static.elabExp(Env.emptyCache,env, rexp, true, SOME(st));
        ((Types.T_TUPLE(types),_)) = Types.getPropType(rprop);
        idents = Util.listMap(crefexps, getIdentFromTupleCrefexp);
        (_,Values.TUPLE(values),SOME(st_2)) = Ceval.ceval(Env.emptyCache,env, srexp, true, SOME(st_1), NONE, Ceval.MSG());
        newst = addVarsToSymboltable(idents, values, types, st_2);
      then
        ("",newst);
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_IF(ifExp = exp,trueBranch = algitemlist,elseIfAlgorithmBranch = elseifexpitemlist,elseBranch = elseitemlist)),st) /* IF-statement */ 
      equation 
        cond1 = (exp,algitemlist);
        cond2 = (cond1 :: elseifexpitemlist);
        cond3 = listAppend(cond2, {(Absyn.BOOL(true),elseitemlist)});
        st_1 = evaluateIfStatementLst(cond3, st);
      then
        ("",st_1);
		 /* while-statement */ 
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_WHILE(whileStmt = exp,whileBody = algitemlist)),st)
      equation 
        (value,st_1) = evaluateExpr(exp, st);
        st_2 = evaluateWhileStmt(value, exp, algitemlist, st_1);
      then 
        ("",st_2);  
        
    /* for-statement, optimized case, e.g.: for i in 1:1000 loop */ 
    case (Absyn.ALGORITHMITEM(algorithm_ =  
      	Absyn.ALG_FOR(forVariable = iter, forStmt = Absyn.RANGE(start=starte,step=NONE, stop=stope),
        forBody = algItemList)),st)       
      equation 
        (startv,st_1) = evaluateExpr(starte, st);
        (stopv,st_2) = evaluateExpr(stope, st_1);
        st_3 = evaluateForStmtRangeOpt(iter, startv, Values.INTEGER(1), stopv, algItemList, st_2);
     then
        ("",st_3);

    /* for-statement, optimized case, e.g.: for i in 7.3:0.4:1000.3 loop */ 
    case (Absyn.ALGORITHMITEM(algorithm_ = 
      	Absyn.ALG_FOR(forVariable = iter, forStmt = Absyn.RANGE(start=starte, step=SOME(stepe), stop=stope),
        forBody = algItemList)),st)       
      equation 
        (startv,st_1) = evaluateExpr(starte, st);
        (stepv,st_2) = evaluateExpr(stepe, st_1);
        (stopv,st_3) = evaluateExpr(stope, st_2);
        st_4 = evaluateForStmtRangeOpt(iter, startv, stepv, stopv, algItemList, st_3);
      then
        ("",st_4);
        
    /* for-statement, general case */ //DABR
    case (Absyn.ALGORITHMITEM(algorithm_ = 
      	Absyn.ALG_FOR(forVariable = iter, forStmt = exp,forBody = algItemList)),st) 
      local
        input list<Values.Value> valList;
      equation 
        (Values.ARRAY(valList),st_1) = evaluateExpr(exp, st);
        st_2 = evaluateForStmt(iter, valList, algItemList, st_1);
      then
        ("",st_2);
    /* for-statement - not an array type */ 
    case (Absyn.ALGORITHMITEM(algorithm_ = Absyn.ALG_FOR(forStmt = exp)),st) 
      local
        String estr;
      equation 
        estr = stringRepresOfExpr(exp, st);
        Error.addMessage(Error.NOT_ARRAY_TYPE_IN_FOR_STATEMENT, {estr});
      then 
        fail();
  end matchcontinue;
end evaluateAlgStmt; 
 


protected function evaluateForStmt "evaluates a for-statement in an algorithm section"
  input String iter "The iterator variable which will be assigned different values";
  input list<Values.Value> valList "List of values that the iterator later will be assigned to";
	input list<Absyn.AlgorithmItem> algItemList;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (forVar,valList,algItemList, inInteractiveSymbolTable)
    local
      Values.Value val;
      list<Values.Value> vallst;
      list<Absyn.AlgorithmItem> algItems;
      InteractiveSymbolTable st1,st2,st3,st4,st5;
    case (iter, val::vallst, algItems, st1)
    equation
      st2 = appendVarToSymboltable(iter, val, Types.typeOfValue(val), st1); 
			st3 = evaluateAlgStmtLst(algItems, st2); 
			st4 = deleteVarFromSymboltable(iter, st3);
			st5 = evaluateForStmt(iter, vallst, algItems, st4);
		then 
			st5;
    case (_, {}, _, st1) 
		then
			st1;			
  end matchcontinue;
end evaluateForStmt;


protected function evaluateForStmtRangeOpt 
  "Optimized version of for statement. In this case, we do not create a large array if 
  a range expression is given. E.g. for i in 1:10000 loop"
  input String iter "The iterator variable which will be assigned different values";
  input Values.Value startVal;
  input Values.Value stepVal;
  input Values.Value stopVal;
	input list<Absyn.AlgorithmItem> algItemList;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (forVar, startVal, stepVal, stopVal, algItemList, inInteractiveSymbolTable)
    local
      Values.Value startv, stepv, stopv, nextv;
      list<Values.Value> vallst;
      list<Absyn.AlgorithmItem> algItems;
      InteractiveSymbolTable st1,st2,st3,st4,st5;
      Boolean startIsLess;
    case (iter, startv, stepv, stopv, algItems, st1)
    equation
      startIsLess = Values.safeLessEq(startv, stopv);
      equality(startIsLess = true);
      st2 = appendVarToSymboltable(iter, startv, Types.typeOfValue(startv), st1); 
			st3 = evaluateAlgStmtLst(algItems, st2); 
			st4 = deleteVarFromSymboltable(iter, st3);
			nextv = Values.safeIntRealOp(startv, stepv, Values.ADDOP);
			st5 = evaluateForStmtRangeOpt(iter, nextv, stepv, stopv, algItems, st4);
		then 
			st5;
    case (_,_,_,_,_,st1) 
		then
			st1;			
  end matchcontinue;
end evaluateForStmtRangeOpt;


protected function evaluateWhileStmt "function: evaluateWhileStmt
  
  Recursively evaluates the while statement. Note that it is tail-recursive, so we should result
  in a iterative implementation.
"
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inInteractiveSymbolTable)
    local
      InteractiveSymbolTable st,st_1,st_2,st_3;
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      String estr,tstr;
      tuple<Types.TType, Option<Absyn.Path>> vtype;
    case (Values.BOOL(boolean = false),_,_,st) 
      equation
      then 
      	st; 
    case (Values.BOOL(boolean = true),exp,algitemlst,st)
      equation 
        st_1 = evaluateAlgStmtLst(algitemlst, st);
        (value,st_2) = evaluateExpr(exp, st_1);
        st_3 = evaluateWhileStmt(value, exp, algitemlst, st_2); /* Tail recursive */
      then
        st_3;
    case (Values.BOOL(_), _,_,st) // An error occured when evaluating the algorithm items
	    then 
	      st;
    case (value,exp,_,st) // The condition value was not a boolean 
      equation 
        estr = stringRepresOfExpr(exp, st); 
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addMessage(Error.WHILE_CONDITION_TYPE_ERROR, {estr,tstr});
      then
        fail();
  end matchcontinue;
end evaluateWhileStmt;

protected function evaluatePartOfIfStatement "function: evaluatePartOfIfStatement
   
  Evaluates one part of a if statement, i.e. one \"case\". If the condition is true, the algorithm items
  associated with this condition are evaluated. The first argument returned is set to true if the 
  condition was evaluated to true. Fails if the value is not a boolean.
  Note that we are sending the expression as an value, so that it does not need to be evaluated twice.
 
"
  input Values.Value inValue;
  input Absyn.Exp inExp;
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inValue,inExp,inAbsynAlgorithmItemLst,inTplAbsynExpAbsynAlgorithmItemLstLst,inInteractiveSymbolTable)
    local
      InteractiveSymbolTable st_1,st;
      Boolean exp_val;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
      String estr,tstr;
      tuple<Types.TType, Option<Absyn.Path>> vtype;
      Values.Value value;
      Absyn.Exp exp;
    case (Values.BOOL(boolean = exp_val),_,algitemlst,_,st)
      equation 
        equality(exp_val = true);
        st_1 = evaluateAlgStmtLst(algitemlst, st);
      then
        st_1;
    case (Values.BOOL(boolean = exp_val),_,algitemlst,algrest,st)
      equation 
        equality(exp_val = false);
        st_1 = evaluateIfStatementLst(algrest, st);
      then
        st_1;
    case (value,exp,_,_,st) /* Report type error */ 
      equation 
        estr = stringRepresOfExpr(exp, st);
        vtype = Types.typeOfValue(value);
        tstr = Types.unparseType(vtype);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {estr,tstr});
      then
        fail();
  end matchcontinue;
end evaluatePartOfIfStatement;

protected function evaluateIfStatementLst "function: evaluateIfStatementLst
   
  Evaluates all parts of a if statement (i.e. a list of exp  statements)
"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inTplAbsynExpAbsynAlgorithmItemLstLst,inInteractiveSymbolTable)
    local
      InteractiveSymbolTable st,st_1,st_2;
      Values.Value value;
      Absyn.Exp exp;
      list<Absyn.AlgorithmItem> algitemlst;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> algrest;
    case ({},st) then st; 
    case (((exp,algitemlst) :: algrest),st)
      equation 
        (value,st_1) = evaluateExpr(exp, st);
        st_2 = evaluatePartOfIfStatement(value, exp, algitemlst, algrest, st_1);
      then
        st_2;
  end matchcontinue;
end evaluateIfStatementLst;

protected function evaluateAlgStmtLst "function: evaluateAlgStmtLst
    
   Evaluates a list of algorithm statements
"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inAbsynAlgorithmItemLst,inInteractiveSymbolTable)
    local
      InteractiveSymbolTable st,st_1,st_2;
      Absyn.AlgorithmItem algitem;
      list<Absyn.AlgorithmItem> algrest;
    case ({},st) then st; 
    case ((algitem :: algrest),st)
      equation 
        (_,st_1) = evaluateAlgStmt(algitem, st);
        st_2 = evaluateAlgStmtLst(algrest, st_1);
      then
        st_2;
  end matchcontinue;
end evaluateAlgStmtLst;

protected function evaluateExpr "function: evaluateExpr
  
   Evaluates an expression and returns its value. 
   We need to return the symbol table, since the command loadFile()
   reads in data to the interactive environment.
   Note that this function may fail.
  
   Input:  Absyn.Exp - Expression to be evaluated
           InteractiveSymbolTable - The symbol table
   Output: Values.Value - Resulting value of the expression
"
  input Absyn.Exp inExp;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output Values.Value outValue;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outValue,outInteractiveSymbolTable):=
  matchcontinue (inExp,inInteractiveSymbolTable)
    local
      list<Env.Frame> env;
      Exp.Exp sexp;
      Types.Properties prop;
      InteractiveSymbolTable st_1,st_2,st;
      Values.Value value;
      Absyn.Exp exp;
      Absyn.Program p;
    case (exp,(st as SYMBOLTABLE(ast = p)))
      equation 
        env = buildEnvFromSymboltable(st);
        (_,sexp,prop,SOME(st_1)) = Static.elabExp(Env.emptyCache,env, exp, true, SOME(st));
        (_,value,SOME(st_2)) = Ceval.ceval(Env.emptyCache,env, sexp, true, SOME(st_1), NONE, Ceval.MSG());
      then
        (value,st_2);
  end matchcontinue;
end evaluateExpr;

protected function stringRepresOfExpr "function: stringRepresOfExpr
  
   This function returns a string representation of an expression. For example expression
   33+22 will result in \"55\" and expression: \"my\" + \"string\" will result in  \"\"my\"+\"string\"\". 
"
  input Absyn.Exp exp;
  input InteractiveSymbolTable st;
  output String estr;
  list<Env.Frame> env;
  Exp.Exp sexp;
  Types.Properties prop;
  InteractiveSymbolTable st_1;
algorithm 
  env := buildEnvFromSymboltable(st);
  (_,sexp,prop,SOME(st_1)) := Static.elabExp(Env.emptyCache,env, exp, true, SOME(st));
  estr := Exp.printExpStr(sexp);
end stringRepresOfExpr;

protected function evaluateExprToStr "function: evaluateExprToStr
  
   This function is similar to evaluate_expr, with the difference that it returns a string
   and that it never fails. If the expression contain errors, an empty string will be returned
   and the errors will be stated using Error.rml
  
   Input:  Absyn.Exp - Expression to be evaluated
           InteractiveSymbolTable - The symbol table
   Output: string - The resulting value represented as a string
"
  input Absyn.Exp inExp;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inExp,inInteractiveSymbolTable)
    local
      Values.Value value;
      InteractiveSymbolTable st_1,st;
      String str;
      Absyn.Exp exp;
    case (exp,st)
      equation 
        (value,st_1) = evaluateExpr(exp, st);
        str = Values.valString(value);
      then
        (str,st_1);
    case (_,st) then ("",st); 
  end matchcontinue;
end evaluateExprToStr;

protected function getIdentFromTupleCrefexp "function: getIdentFromTupleCrefexp
 
  Return the (first) identifier of a Component Reference in an expression.
"
  input Absyn.Exp inExp;
  output Absyn.Ident outIdent;
algorithm 
  outIdent:=
  matchcontinue (inExp)
    local
      String id,str;
      Absyn.Exp exp;
    case Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = id)) then id; 
    case exp
      equation 
        str = Dump.printExpStr(exp);
        Error.addMessage(Error.INVALID_TUPLE_CONTENT, {str});
      then
        fail();
  end matchcontinue;
end getIdentFromTupleCrefexp;

protected function getVariableNames "function: getVariableNames
 
  Return a string containing a comma separated list of variables.
"
  input list<InteractiveVariable> vars;
  output String res;
  list<String> strlst;
  String str;
algorithm 
  strlst := getVariableListStr(vars);
  str := Util.stringDelimitList(strlst, ", ");
  res := Util.stringAppendList({"{",str,"}"});
end getVariableNames;

protected function getVariableListStr "function: getVariableListStr
 
  Helper function to get_variable_names
"
  input list<InteractiveVariable> inInteractiveVariableLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inInteractiveVariableLst)
    local
      list<String> res;
      list<InteractiveVariable> vs;
      String p;
    case ({}) then {}; 
    case ((IVAR(varIdent = "$echo") :: vs))
      equation 
        res = getVariableListStr(vs);
      then
        res;
    case ((IVAR(varIdent = p) :: vs))
      equation 
        res = getVariableListStr(vs);
      then
        (p :: res);
  end matchcontinue;
end getVariableListStr;

public function getTypeOfVariable "function: getTypeOfVariables
 
  Return the type of an interactive variable, given a list of variables 
  and a variable identifier.
"
  input Absyn.Ident inIdent;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inIdent,inInteractiveVariableLst)
    local
      String id,varid;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<InteractiveVariable> rest;
    case (id,{}) then fail(); 
    case (varid,(IVAR(varIdent = id,type_ = tp) :: rest))
      equation 
        equality(varid = id);
      then
        tp;
    case (varid,(IVAR(varIdent = id) :: rest))
      equation 
        failure(equality(varid = id));
        tp = getTypeOfVariable(varid, rest);
      then
        tp;
  end matchcontinue;
end getTypeOfVariable;

protected function addVarsToSymboltable "function: addVarsToSymboltable
 
  Add a list of variables to the interactive symboltable given names, 
  values and types.
"
  input list<Absyn.Ident> inAbsynIdentLst;
  input list<Values.Value> inValuesValueLst;
  input list<Types.Type> inTypesTypeLst;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inAbsynIdentLst,inValuesValueLst,inTypesTypeLst,inInteractiveSymbolTable)
    local
      InteractiveSymbolTable st,st_1,st_2;
      String id;
      list<String> idrest;
      Values.Value v;
      list<Values.Value> vrest;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<tuple<Types.TType, Option<Absyn.Path>>> trest;
    case ({},_,_,st) then st; 
    case ((id :: idrest),(v :: vrest),(t :: trest),st)
      equation 
        st_1 = addVarToSymboltable(id, v, t, st);
        st_2 = addVarsToSymboltable(idrest, vrest, trest, st_1);
      then
        st_2;
  end matchcontinue;
end addVarsToSymboltable;

public function addVarToSymboltable "function: addVarToSymboltable
 
  Helper function to add_vars_to_symboltable.
"
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input Types.Type inType;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inIdent,inValue,inType,inInteractiveSymbolTable)
    local
      list<InteractiveVariable> vars_1,vars;
      String ident;
      Values.Value v;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<InstantiatedClass> id;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
    case (ident,v,t,SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = id,lstVarVal = vars,compiledFunctions = cf))
      equation 
        vars_1 = addVarToVarlist(ident, v, t, vars);
      then
        SYMBOLTABLE(p,sp,id,vars_1,cf);
  end matchcontinue;
end addVarToSymboltable;

public function appendVarToSymboltable "
  Appends a variable to the interactive symbol table. Compared to addVarToSymboltable, this
  function does not search for the identifier, it adds the variable to the beginning of the list.
  Used in for example iterators in for statements.
"
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input Types.Type inType;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inIdent,inValue,inType,inInteractiveSymbolTable)
    local
      list<InteractiveVariable> vars_1,vars;
      String ident;
      Values.Value v;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<InstantiatedClass> id;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
    case (ident,v,t,SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = id,lstVarVal = vars,compiledFunctions = cf))
      equation 
        vars_1 = (IVAR(ident,v,t))::vars;
      then
        SYMBOLTABLE(p,sp,id,vars_1,cf);
  end matchcontinue;
end appendVarToSymboltable;



public function deleteVarFromSymboltable 
  input Absyn.Ident inIdent;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  outInteractiveSymbolTable:=
  matchcontinue (inIdent,inInteractiveSymbolTable)
    local
      list<InteractiveVariable> vars_1,vars;
      String ident;
      Absyn.Program p;
      list<SCode.Class> sp;
      list<InstantiatedClass> id;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
    case (ident,SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = id,lstVarVal = vars,compiledFunctions = cf))
      equation 
        vars_1 = deleteVarFromVarlist(ident, vars);
      then
        SYMBOLTABLE(p,sp,id,vars_1,cf);
  end matchcontinue;
end deleteVarFromSymboltable;



protected function deleteVarFromVarlist "deletes the first variable found"
  input Absyn.Ident inIdent;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output list<InteractiveVariable> outInteractiveVariableLst;
algorithm
  outInteractiveVariableLst:=
  matchcontinue (inIdent,inInteractiveVariableLst)
    local
      String ident,id2;
      Values.Value v,val2;
      list<InteractiveVariable> rest, rest2;
      InteractiveVariable var;
    case (ident,(IVAR(varIdent = id2) :: rest))
      equation 
        equality(ident = id2);
      then
        rest;
    case (ident,var::rest)
      equation 
        rest2 = deleteVarFromVarlist(ident, rest);
      then
        var::rest2;
    case (ident,{}) 
      then {};       
  end matchcontinue;
end deleteVarFromVarlist;

protected function addVarToVarlist "
  Assignes a value to a variable with a specific identifier. 
"
  input Absyn.Ident inIdent;
  input Values.Value inValue;
  input Types.Type inType;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output list<InteractiveVariable> outInteractiveVariableLst;
algorithm 
  outInteractiveVariableLst:=
  matchcontinue (inIdent,inValue,inType,inInteractiveVariableLst)
    local
      String ident,id2;
      Values.Value v,val2;
      tuple<Types.TType, Option<Absyn.Path>> t,t2;
      list<InteractiveVariable> rest,rest_1;
    case (ident,v,t,(IVAR(varIdent = id2) :: rest))
      equation 
        equality(ident = id2);
      then
        (IVAR(ident,v,t) :: rest);
    case (ident,v,t,(IVAR(varIdent = id2,value = val2,type_ = t2) :: rest))
      equation 
        failure(equality(ident = id2));
        rest_1 = addVarToVarlist(ident, v, t, rest);
      then
        (IVAR(id2,val2,t2) :: rest_1);
    case (ident,v,t,{}) then {IVAR(ident,v,t)}; 
  end matchcontinue;
end addVarToVarlist;

public function buildEnvFromSymboltable "function: buildEnvFromSymboltable
   author: PA
   
   Builds an environment from a symboltable by adding all interactive variables
   and their bindings to the environment.
"
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output Env.Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inInteractiveSymbolTable)
    local
      list<SCode.Class> p_1,sp;
      list<Env.Frame> env,env_1;
      Absyn.Program p;
      list<InstantiatedClass> ic;
      list<InteractiveVariable> vars;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
    case (SYMBOLTABLE(ast = p,explodedAst = sp,instClsLst = ic,lstVarVal = vars,compiledFunctions = cf))
      equation 
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        env_1 = addVarsToEnv(vars, env);
	    then
        env_1;
  end matchcontinue;
end buildEnvFromSymboltable;

protected function addVarsToEnv "function: addVarsToEnv
 
  Helper function to build_env_from_symboltable.
"
  input list<InteractiveVariable> inInteractiveVariableLst;
  input Env.Env inEnv;
  output Env.Env outEnv;
algorithm 
  outEnv:=
  matchcontinue (inInteractiveVariableLst,inEnv)
    local
      list<Env.Frame> env_1,env_2,env;
      String id;
      Values.Value v;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      list<InteractiveVariable> rest;
    case ((IVAR(varIdent = id,value = v,type_ = tp) :: rest),env)
      equation 
        (_,_,_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(id,{}));
        env_1 = Env.updateFrameV(env, 
          Types.VAR(id,Types.ATTR(false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()),
          false,tp,Types.VALBOUND(v)), Env.VAR_TYPED(), {});
        env_2 = addVarsToEnv(rest, env_1);
      then
        env_2;
    case ((IVAR(varIdent = id,value = v,type_ = tp) :: rest),env)
      equation 
        failure((_,_,_,_) = Lookup.lookupVar(Env.emptyCache,env, Exp.CREF_IDENT(id,{})));
        env_1 = Env.extendFrameV(env, 
          Types.VAR(id,Types.ATTR(false,SCode.RW(),SCode.VAR(),Absyn.BIDIR()),
          false,tp,Types.VALBOUND(v)), NONE, Env.VAR_UNTYPED(), {});
        env_2 = addVarsToEnv(rest, env_1);
      then
        env_2;
    case ({},env) then env; 
  end matchcontinue;
end addVarsToEnv;

protected function evaluateGraphicalApi2 "function: evaluateGraphicalApi2
 
  Second function for evaluating graphical api. 
  The reason for having two function is that the generated c-code can
  not be complied in Visual studio if the number of rules are large.
  This was actually fixed in the latest version of RML!
"
  input InteractiveStmts inInteractiveStmts;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inInteractiveStmts,inInteractiveSymbolTable)
    local
      Absyn.Program newp,p,p_1,p1;
      String resstr,ident,filename,cmt,variability,causality,name,value,top_names_str;
      Absyn.ComponentRef class_,subident,comp_ref,cr;
      Absyn.Modification mod;
      InteractiveSymbolTable st;
      list<SCode.Class> s;
      list<InstantiatedClass> ic;
      list<InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Absyn.Path p_class;
      Boolean final_,flow_,protected_,repl,dref1,dref2;
      Integer rest;
      
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setExtendsModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = Absyn.CREF_QUAL(name = ident,componentRef = subident)),Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (newp,resstr) = setExtendsModifierValue(class_, Absyn.CREF_IDENT(ident,{}), subident, mod, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getExtendsModifierNames"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = ident)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.ComponentRef ident;
      equation 
        resstr = getExtendsModifierNames(class_, ident, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getExtendsModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = Absyn.CREF_QUAL(name = ident,componentRef = subident))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getExtendsModifierValue(class_, Absyn.CREF_IDENT(ident,{}), subident, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponentModifierNames"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = ident)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.ComponentRef ident;
      equation 
        resstr = getComponentModifierNames(class_, ident, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponentModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = Absyn.CREF_QUAL(name = ident,componentRef = subident))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getComponentModifierValue(class_, Absyn.CREF_IDENT(ident,{}), subident, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponentModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = ident))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getComponentBinding(class_, Absyn.CREF_IDENT(ident,{}), p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getSourceFile"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getSourceFile(class_, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setSourceFile"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.STRING(value = filename)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (resstr,newp) = setSourceFile(class_, filename, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setComponentComment"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = comp_ref),Absyn.STRING(value = cmt)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (resstr,newp) = setComponentComment(class_, comp_ref, cmt, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setComponentProperties"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = comp_ref),Absyn.ARRAY(arrayExp = {Absyn.BOOL(value = final_),Absyn.BOOL(value = flow_),Absyn.BOOL(value = protected_),Absyn.BOOL(value = repl)}),Absyn.ARRAY(arrayExp = {Absyn.STRING(value = variability)}),Absyn.ARRAY(arrayExp = {Absyn.BOOL(value = dref1),Absyn.BOOL(value = dref2)}),Absyn.ARRAY(arrayExp = {Absyn.STRING(value = causality)})},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        p_class = Absyn.crefToPath(class_);
        (resstr,p_1) = setComponentProperties(p_class, comp_ref, final_, flow_, protected_, repl, 
          variability, {dref1,dref2}, causality, p);
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getElementsInfo"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-03 */ 
      equation 
        resstr = getElementsInfo(cr, p);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getEnvironmentVar"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-24 */ 
      equation 
        resstr = System.readEnv(name);
      then
        (resstr,st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getEnvironmentVar"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-24 */ 
      equation 
        failure(resstr = System.readEnv(name));
      then
        ("error",st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setEnvironmentVar"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name),Absyn.STRING(value = value)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-24 */ 
      equation 
        0 = System.setEnv(name, value, 1) "overwrite" ;
      then
        ("Ok",st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setEnvironmentVar"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name),Absyn.STRING(value = value)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-24 */ 
      equation 
        rest = System.setEnv(name, value, 1) "overwrite" ;
        (rest == 0) = false;
      then
        ("error",st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractiveQualified"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-12-16 */ 
      equation 
        0 = System.regularFileExists(name);
        p1 = Parser.parse(name);
        newp = updateProgram(p1, p);
        top_names_str = getTopQualifiedClassnames(p1);
      then
        (top_names_str,SYMBOLTABLE(newp,s,ic,iv,cf));
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractiveQualified"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-12-16 it the rule above have failed then check if file exists without this omc crashes */ 
      equation 
        rest = System.regularFileExists(name);
        (rest > 0) = true;
      then
        ("error",st);
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractiveQualified"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-12-16 check if the parse went wrong */ 
      equation 
        failure(p1 = Parser.parse(name));
      then
        ("error",st);
  end matchcontinue;
end evaluateGraphicalApi2;

protected function evaluateGraphicalApi "function: evaluateGraphicalApi
  
   Thisfunction evaluates all primitives in the graphical api.
   NOTE: Do NOT ADD more rules to thisfunction, instead add them
   to evaluate_graphical_api2, since it wont compile in Visual Studio 
   otherwise.
"
  input InteractiveStmts inInteractiveStmts;
  input InteractiveSymbolTable inInteractiveSymbolTable;
  output String outString;
  output InteractiveSymbolTable outInteractiveSymbolTable;
algorithm 
  (outString,outInteractiveSymbolTable):=
  matchcontinue (inInteractiveStmts,inInteractiveSymbolTable)
    local
      Absyn.Program p_1,p,newp,p1,newp_1;
      String resstr,name,top_names_str,str,resstr_1,res,cmt,s1,res_str;
      Absyn.ComponentRef class_,ident,subident,cr,path,tp,model_,cr1,cr2,c1,c2,old_cname,new_cname,cname,from_ident,to_ident;
      Absyn.Exp exp;
      InteractiveSymbolTable st,newst;
      list<SCode.Class> s,s_1;
      list<InstantiatedClass> ic;
      list<InteractiveVariable> iv;
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cf;
      Absyn.Modification mod;
      Absyn.Path path_1,wpath;
      Integer rest,count,n;
      list<Absyn.NamedArg> nargs;
      Boolean b1,b2;
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setComponentModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = (ident as Absyn.CREF_IDENT(name = _))),Absyn.CODE(code = Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(expOption = SOME(exp))))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (p_1,resstr) = setParameterValue(class_, ident, exp, p) "expressions" ;
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));

			//special case for clearing modifier simple name.	
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setComponentModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = (ident as Absyn.CREF_IDENT(name = _))),Absyn.CODE(code = Absyn.C_MODIFICATION(modification = (mod as Absyn.CLASSMOD(elementArgLst = {},expOption = NONE))))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (p_1,resstr) = setComponentModifier(class_, ident, Absyn.CREF_IDENT("",{}),mod, p)  ;
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));
        
          
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setComponentModifierValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = Absyn.CREF_QUAL(name = ident,componentRef = subident)),Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local String ident;
      equation 
        (p_1,resstr) = setComponentModifier(class_, Absyn.CREF_IDENT(ident,{}), subident, mod, p);
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getParameterValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = ident)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getComponentBinding(class_, ident, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setParameterValue"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.CREF(componentReg = ident),exp},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (p_1,resstr) = setParameterValue(class_, ident, exp, p);
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getParameterNames"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getParameterNames(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "createModel"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = name))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        newp = updateProgram(
          Absyn.PROGRAM(
          {
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("",false,0,0,0,0))},Absyn.TOP()), p);
        newst = SYMBOLTABLE(newp,s,ic,iv,cf);
      then
        ("true",newst);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "createModel"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = (path as Absyn.CREF_QUAL(name = _)))},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        path_1 = Absyn.crefToPath(path);
        name = Absyn.pathLastIdent(path_1);
        wpath = Absyn.stripLast(path_1);
        newp = updateProgram(
          Absyn.PROGRAM(
          {
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("",false,0,0,0,0))},Absyn.WITHIN(wpath)), p);
        newst = SYMBOLTABLE(newp,s,ic,iv,cf);
      then
        ("true",newst);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "newModel"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = name)),Absyn.CREF(componentReg = cr)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        newp = updateProgram(
          Absyn.PROGRAM(
          {
          Absyn.CLASS(name,false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("",false,0,0,0,0))},Absyn.WITHIN(path)), p);
        newst = SYMBOLTABLE(newp,s,ic,iv,cf);
        resstr = stringAppend(name, "\n");
      then
        ("true",newst);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractive"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        p1 = ClassLoader.loadFile(name) "System.regularFileExists(name) => 0 & 	 Parser.parse(name) => p1 &" ;
        newp = updateProgram(p1, p);
        top_names_str = getTopClassnames(p1);
      then
        (top_names_str,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractive"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* it the rule above have failed then check if file exists without this omc crashes */ 
      equation 
        rest = System.regularFileExists(name);
        (rest > 0) = true;
      then
        ("error",st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "loadFileInteractive"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = name)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* check if the parse went wrong */ 
      equation 
        failure(p1 = Parser.parse(name));
      then
        ("error",st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "deleteClass"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)},argNames = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (resstr,newp) = deleteClass(cr, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "addComponent"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = name)),Absyn.CREF(componentReg = tp),Absyn.CREF(componentReg = model_)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (newp,resstr) = addComponent(name, tp, model_, nargs, p);
        str = Print.getString();
        resstr_1 = stringAppend(resstr, str);
      then
        ("true",SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "updateComponent"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = name)),Absyn.CREF(componentReg = tp),Absyn.CREF(componentReg = model_)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (newp,res) = updateComponent(name, tp, model_, nargs, p) "delete_component(name,model,p) => (newp,resstr) &
	 add_component(name,tp,model,nargs,newp) => (newp2,resstr)" ;
      then
        (res,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "deleteComponent"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = Absyn.CREF_IDENT(name = name)),Absyn.CREF(componentReg = model_)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (newp,resstr) = deleteComponent(name, model_, p);
        str = Print.getString();
        resstr_1 = stringAppend(resstr, str);
      then
        ("true",SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "addClassAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        newp = addClassAnnotation(cr, nargs, p);
        newst = SYMBOLTABLE(newp,s,ic,iv,cf);
      then
        ("true",newst);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponentCount"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        count = getComponentCount(cr, p);
        resstr = intString(count);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthComponent"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthComponent(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponents"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getComponents(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getComponentAnnotations"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getComponentAnnotations(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthComponentAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthComponentAnnotation(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthComponentModification"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthComponentModification(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getInheritanceCount"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        count = getInheritanceCount(cr, p);
        resstr = intString(count);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthInheritedClass"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthInheritedClass(cr, n, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getConnectionCount"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getConnectionCount(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthConnection"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthConnection(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setConnectionComment"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = cr1),Absyn.CREF(componentReg = cr2),Absyn.STRING(value = cmt)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (newp,resstr) = setConnectionComment(cr, cr1, cr2, cmt, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "addConnection"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = c1),Absyn.CREF(componentReg = c2),Absyn.CREF(componentReg = cr)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (resstr,newp) = addConnection(cr, c1, c2, nargs, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "deleteConnection"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = c1),Absyn.CREF(componentReg = c2),Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (resstr,newp) = deleteConnection(cr, c1, c2, p);
      then
        (resstr,SYMBOLTABLE(newp,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "updateConnection"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = c1),Absyn.CREF(componentReg = c2),Absyn.CREF(componentReg = cr)},argNames = nargs)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (s1,newp) = deleteConnection(cr, c1, c2, p);
        (resstr,newp_1) = addConnection(cr, c1, c2, nargs, newp);
      then
        (resstr,SYMBOLTABLE(newp_1,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthConnectionAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthConnectionAnnotation(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getConnectorCount"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getConnectorCount(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthConnector"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthConnector(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getNthConnectorIconAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.INTEGER(value = n)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getNthConnectorIconAnnotation(cr, p, n);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getIconAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        resstr = getIconAnnotation(path, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getDiagramAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        resstr = getDiagramAnnotation(path, p);
      then
        (resstr,st);

     case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getDocumentationAnnotation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        resstr = getDocumentationAnnotation(path, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getPackages"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        resstr = getPackagesInPath(path, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getPackages"),functionArgs = Absyn.FUNCTIONARGS(args = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        s1 = getTopPackages(p);
        resstr = stringAppend(s1, "\n");
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassNames"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Absyn.Path path;
      equation 
        path = Absyn.crefToPath(cr);
        resstr = getClassnamesInPath(path, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassNames"),functionArgs = Absyn.FUNCTIONARGS(args = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getTopClassnames(p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassNames"),functionArgs = Absyn.FUNCTIONARGS(args = _)))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) then ("{}",st); 

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassNamesForSimulation"),functionArgs = Absyn.FUNCTIONARGS(args = {})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = System.getClassnamesForSimulation();
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setClassNamesForSimulation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.STRING(value = str)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        System.setClassnamesForSimulation(str);
      then
        ("true",st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassInformation"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getClassInformation(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "setClassComment"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = class_),Absyn.STRING(value = str)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (p_1,resstr) = setClassComment(class_, str, p);
      then
        (resstr,SYMBOLTABLE(p_1,s,ic,iv,cf));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassRestriction"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        resstr = getClassRestriction(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isPrimitive"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isPrimitive(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isType"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isType(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isConnector"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isConnector(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isModel"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isModel(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isRecord"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isRecord(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isBlock"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isBlock(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isFunction"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isFunction(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isPackage"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isPackage(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isClass"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isClass(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isParameter"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = class_)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isParameter(cr, class_, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isProtected"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = class_)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isProtected(cr, class_, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "isConstant"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr),Absyn.CREF(componentReg = class_)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = isConstant(cr, class_, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "existClass"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        b1 = existClass(cr, p);
        resstr = Util.boolString(b1);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "existModel"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Boolean res;
      equation 
        b1 = existClass(cr, p);
        b2 = isModel(cr, p);
        res = boolAnd(b1, b2);
        resstr = Util.boolString(res);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "existPackage"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      local Boolean res;
      equation 
        b1 = existClass(cr, p);
        b2 = isPackage(cr, p);
        res = boolAnd(b1, b2);
        resstr = Util.boolString(res);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "renameClass"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = old_cname),Absyn.CREF(componentReg = new_cname)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (res,p_1) = renameClass(p, old_cname, new_cname) "For now, renaming a class clears all caches... Substantial analysis required to find out what to keep in cache
	   and what must be thrown out" ;
        s_1 = SCode.elaborate(p_1);
      then
        (res,SYMBOLTABLE(p_1,s_1,{},{},{}));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "renameComponent"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cname),Absyn.CREF(componentReg = from_ident),Absyn.CREF(componentReg = to_ident)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))
      equation 
        (res_str,p_1) = renameComponent(p, cname, from_ident, to_ident);
      then
        (res_str,SYMBOLTABLE(p_1,s,{},{},{}));

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getCrefInfo"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* adrpo added 2005-11-03 */ 
      equation 
        resstr = getCrefInfo(cr, p);
      then
        (resstr,st);

    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "getClassAttributes"),functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),(st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf))) /* added by adrpo, 2006-02-24 */ 
      equation 
        resstr = getClassAttributes(cr, p);
      then
        (resstr,st);

        // list(cr) added here to speed up model editor. Also exists in Ceval
    case (ISTMTS(interactiveStmtLst = {IEXP(exp = Absyn.CALL(function_ = Absyn.CREF_IDENT(name = "list"),
           functionArgs = Absyn.FUNCTIONARGS(args = {Absyn.CREF(componentReg = cr)})))}),
          (st as SYMBOLTABLE(ast = p,explodedAst = s,instClsLst = ic,lstVarVal = iv,compiledFunctions = cf)))  
      equation 
        resstr = listClass(cr, p); 
        resstr = Util.stringAppendList({"\"",resstr,"\""});
      then
        (resstr,st);
  end matchcontinue;
end evaluateGraphicalApi;

protected function listClass "Unparse a class definition and return it in a String"
  input Absyn.ComponentRef cr "Class name as a ComponentRef";
  input Absyn.Program p "AST - Program";
  output String classStr "Class defintition";
protected  
	Absyn.Path path;
	Absyn.Class cl;
algorithm
	 path := Absyn.crefToPath(cr);
   cl := getPathedClassInProgram(path, p);
   classStr := Dump.unparseStr(Absyn.PROGRAM({cl},Absyn.TOP())) ",false" ;  
  
end listClass;

protected function extractAllComponentreplacements "function extractAllComponentreplacements
  author: x02lucpo
 
  extracts all the componentreplacementrules from program.
  This is done by extracting all the components and then extracting the rules
"
  input Absyn.Program p;
  input Absyn.ComponentRef class_;
  input Absyn.ComponentRef cref1;
  input Absyn.ComponentRef cref2;
  output ComponentReplacementRules comp_reps;
  Components comps;
  Absyn.Path class_path;
  ComponentReplacementRules comp_repsrules;
algorithm 
  comps := extractAllComponents(p) "class in package" ;
  class_path := Absyn.crefToPath(class_);
  comp_repsrules := COMPONENTREPLACEMENTRULES({COMPONENTREPLACEMENT(class_path,cref1,cref2)},1);
  comp_reps := getComponentreplacementsrules(comps, comp_repsrules, 0);
end extractAllComponentreplacements;

protected function renameComponent "function: renameComponent
  author: x02lucpo
 
  This function renames a component in a class
 
  inputs:  (Absyn.Program, 
              Absyn.ComponentRef, /* old class as qualified name */
              Absyn.ComponentRef) /* new class, as identifier */
  outputs:  Absyn.Program
"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.ComponentRef inComponentRef4;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inProgram1,inComponentRef2,inComponentRef3,inComponentRef4)
    local
      Absyn.Path class_path;
      ComponentReplacementRules comp_reps;
      Absyn.Program p_1,p;
      list<String> paths;
      String paths_1,paths_2;
      Absyn.ComponentRef class_,old_comp,new_comp;
    case (p,class_,old_comp,new_comp)
      equation 
        class_path = Absyn.crefToPath(class_) "class in package" ;
        comp_reps = extractAllComponentreplacements(p, class_, old_comp, new_comp);
        p_1 = renameComponentFromComponentreplacements(p, comp_reps);
        paths = extractRenamedClassesAsStringList(comp_reps);
        paths_1 = Util.stringDelimitList(paths, ",");
        paths_2 = Util.stringAppendList({"{",paths_1,"}"});
      then
        (paths_2,p_1);
    case (p,_,_,_)
      equation 
        Debug.fprint("failtrace", "rename_component failed\n");
      then
        ("error",p);
  end matchcontinue;
end renameComponent;

protected function extractRenamedClassesAsStringList "function extractRenamedClassesAsStringList
  author: x02lucpo
 
  this iterates through the Componentreplacementrules and returns the string list
  with all the changed classes
"
  input ComponentReplacementRules inComponentReplacementRules;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inComponentReplacementRules)
    local
      ComponentReplacementRules comp_reps,res;
      Absyn.Path path;
      String path_str;
      list<String> res_1,res_2;
    case (comp_reps)
      equation 
        true = emptyComponentReplacementRules(comp_reps);
      then
        {};
    case (comp_reps)
      equation 
        COMPONENTREPLACEMENT(path,_,_) = firstComponentReplacement(comp_reps);
        path_str = Absyn.pathString(path);
        res = restComponentReplacementRules(comp_reps);
        res_1 = extractRenamedClassesAsStringList(res);
        res_2 = Util.listUnion({path_str}, res_1);
      then
        res_2;
    case (_)
      equation 
        print("-extract_renamed_classes_as_string_list failed\n");
      then
        fail();
  end matchcontinue;
end extractRenamedClassesAsStringList;

protected function renameComponentFromComponentreplacements "function renameComponentFromComponentreplacements
  author: x02lucpo
 
  this iterates through the Componentreplacementrules and renames the 
  componentes by traversing all the classes
"
  input Absyn.Program inProgram;
  input ComponentReplacementRules inComponentReplacementRules;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inProgram,inComponentReplacementRules)
    local
      Absyn.Program p,p_1,p_2;
      ComponentReplacementRules comp_reps,res;
      ComponentReplacement comp_rep;
    case (p,comp_reps)
      equation 
        true = emptyComponentReplacementRules(comp_reps);
      then
        p;
    case (p,comp_reps)
      equation 
        comp_rep = firstComponentReplacement(comp_reps);
        ((p_1,_,_)) = traverseClasses(p, NONE, renameComponentVisitor, comp_rep, true) "traverse protected" ;
        res = restComponentReplacementRules(comp_reps);
        p_2 = renameComponentFromComponentreplacements(p_1, res);
      then
        p_2;
    case (_,_)
      equation 
        print("-rename_component_from_componentreplacements failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentFromComponentreplacements;

protected function renameComponentVisitor "function renameComponentVisitor
 
  author: x02lucpo
  this is a visitor for traverse class in rename components 
"
  input tuple<Absyn.Class, Option<Absyn.Path>, ComponentReplacement> inTplAbsynClassAbsynPathOptionComponentReplacement;
  output tuple<Absyn.Class, Option<Absyn.Path>, ComponentReplacement> outTplAbsynClassAbsynPathOptionComponentReplacement;
algorithm 
  outTplAbsynClassAbsynPathOptionComponentReplacement:=
  matchcontinue (inTplAbsynClassAbsynPathOptionComponentReplacement)
    local
      Absyn.Path path_1,pa,class_id;
      Absyn.Class class_1,class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.ComponentRef old_comp,new_comp;
      ComponentReplacement args;
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),SOME(pa),COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation 
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = ModUtil.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,SOME(pa),
          COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),NONE,COMPONENTREPLACEMENT(which1 = class_id,the2 = old_comp,the3 = new_comp)))
      equation 
        path_1 = Absyn.IDENT(id);
        true = ModUtil.pathEqual(class_id, path_1);
        class_1 = renameComponentInClass(class_, old_comp, new_comp);
      then
        ((class_1,NONE,
          COMPONENTREPLACEMENT(class_id,old_comp,new_comp)));
    case ((class_,pa,args))
      local Option<Absyn.Path> pa;
      then
        ((class_,pa,args));
  end matchcontinue;
end renameComponentVisitor;

protected function renameComponentInClass "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id;
      Boolean partial_,final_,encapsulated_;
      Absyn.Restriction restriction;
      Option<String> a,c;
      Absyn.Info file_info;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.ElementArg> b;
      Absyn.Class class_;
    case (Absyn.CLASS(name = id,partial_ = partial_,final_ = final_,encapsulated_ = encapsulated_,restricion = restriction,body = Absyn.PARTS(classParts = parts,comment = a),info = file_info),old_comp,new_comp) /* the class with the component the old name for the component */ 
      equation 
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(id,partial_,final_,encapsulated_,restriction,
          Absyn.PARTS(parts_1,a),file_info);
    case (Absyn.CLASS(name = id,partial_ = partial_,final_ = final_,encapsulated_ = encapsulated_,restricion = restriction,body = Absyn.CLASS_EXTENDS(name = a,arguments = b,comment = c,parts = parts),info = file_info),old_comp,new_comp)
      local String a;
      equation 
        parts_1 = renameComponentInParts(parts, old_comp, new_comp);
      then
        Absyn.CLASS(id,partial_,final_,encapsulated_,restriction,
          Absyn.CLASS_EXTENDS(a,b,c,parts_1),file_info);
    case (class_,old_comp,new_comp) then class_; 
  end matchcontinue;
end renameComponentInClass;

protected function renameComponentInParts "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ClassPart> res_1,res;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.ComponentRef old_comp,new_comp;
      list<Absyn.EquationItem> equations_1,equations;
      list<Absyn.AlgorithmItem> algorithms_1,algorithms;
      Absyn.ExternalDecl external_decl_1,external_decl;
      Option<Absyn.Annotation> ano;
      Absyn.ClassPart a;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PUBLIC(elements_1) :: res_1);
    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        elements_1 = renameComponentInElements(elements, old_comp, new_comp);
      then
        (Absyn.PROTECTED(elements_1) :: res_1);
    case ((Absyn.EQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.EQUATIONS(equations_1) :: res_1);
    case ((Absyn.INITIALEQUATIONS(contents = equations) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        (Absyn.INITIALEQUATIONS(equations_1) :: res_1);
    case ((Absyn.ALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.ALGORITHMS(algorithms_1) :: res_1);
    case ((Absyn.INITIALALGORITHMS(contents = algorithms) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        algorithms_1 = renameComponentInAlgorithms(algorithms, old_comp, new_comp);
      then
        (Absyn.INITIALALGORITHMS(algorithms_1) :: res_1);
    case ((Absyn.EXTERNAL(externalDecl = external_decl,annotation_ = ano) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
        external_decl_1 = renameComponentInExternalDecl(external_decl, old_comp, new_comp);
      then
        (Absyn.EXTERNAL(external_decl_1,ano) :: res_1);
    case ((a :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInParts(res, old_comp, new_comp);
      then
        (a :: res_1);
  end matchcontinue;
end renameComponentInParts;

protected function renameComponentInElements "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ElementItem> res_1,res;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Boolean final_;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constraint;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case (((element as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = final_,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,specification = elementspec,info = info,constrainClass = constraint))) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,redeclare_,inner_outer,name,elementspec_1,info,
          constraint));
      then
        (element_1 :: res_1);
    case ((element :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInElements(res, old_comp, new_comp);
        element_1 = element;
      then
        (element_1 :: res_1);
  end matchcontinue;
end renameComponentInElements;

protected function renameComponentInElementSpec "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inElementSpec1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.ComponentItem> comps_1,comps;
      Absyn.ElementAttributes attr;
      Absyn.Path path;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.ElementSpec elementspec;
    case (Absyn.COMPONENTS(attributes = attr,typeName = path,components = comps),old_comp,new_comp) /* the old name for the component */ 
      equation 
        comps_1 = renameComponentInComponentitems(comps, old_comp, new_comp);
      then
        Absyn.COMPONENTS(attr,path,comps_1);
    case (elementspec,old_comp,new_comp) then elementspec; 
  end matchcontinue;
end renameComponentInElementSpec;

protected function renameComponentInComponentitems "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path old_comp_path,new_comp_path;
      String old_comp_string,new_comp_string,name;
      list<Absyn.ComponentItem> res_1,res;
      Absyn.ComponentItem comp_1,comp;
      list<Absyn.Subscript> arrayDim;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> comment;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case (((comp as Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name,arrayDim = arrayDim,modification = mod),condition = cond,comment = comment)) :: res),old_comp,new_comp)
      equation 
        old_comp_path = Absyn.crefToPath(old_comp);
        old_comp_string = Absyn.pathString(old_comp_path);
        equality(name = old_comp_string);
        new_comp_path = Absyn.crefToPath(new_comp);
        new_comp_string = Absyn.pathString(new_comp_path);
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
        comp_1 = Absyn.COMPONENTITEM(Absyn.COMPONENT(new_comp_string,arrayDim,mod),cond,comment);
      then
        (comp_1 :: res_1);
    case (((comp as Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name,arrayDim = arrayDim,modification = mod),condition = cond,comment = comment)) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInComponentitems(res, old_comp, new_comp);
      then
        (comp :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_componentitems failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInComponentitems;

protected function renameComponentInEquationList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm 
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> res_1,res;
      Absyn.Equation equation_1,equation_;
      Option<Absyn.Comment> cmt;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((Absyn.EQUATIONITEM(equation_ = equation_,comment = cmt) :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
        equation_1 = renameComponentInEquation(equation_, old_comp, new_comp);
      then
        (Absyn.EQUATIONITEM(equation_1,cmt) :: res_1);
    case ((equation_ :: res),old_comp,new_comp)
      local Absyn.EquationItem equation_1,equation_;
      equation 
        res_1 = renameComponentInEquationList(res, old_comp, new_comp);
        equation_1 = equation_;
      then
        (equation_1 :: res_1);
  end matchcontinue;
end renameComponentInEquationList;

protected function renameComponentInExpEquationitemList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> inTplAbsynExpAbsynEquationItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> outTplAbsynExpAbsynEquationItemLstLst;
algorithm 
  outTplAbsynExpAbsynEquationItemLstLst:=
  matchcontinue (inTplAbsynExpAbsynEquationItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp1;
      list<Absyn.EquationItem> eqn_item_1,eqn_item;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {}; 
    case (((exp1,eqn_item) :: res),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        eqn_item_1 = renameComponentInEquationList(eqn_item, old_comp, new_comp);
        res_1 = renameComponentInExpEquationitemList(res, old_comp, new_comp);
      then
        ((exp1_1,eqn_item_1) :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_exp_equationitem_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpEquationitemList;

protected function renameComponentInEquation "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.Equation inEquation1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Equation outEquation;
algorithm 
  outEquation:=
  matchcontinue (inEquation1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.EquationItem> true_items_1,elses_1,true_items,elses,equations_1,equations;
      list<tuple<Absyn.Exp, list<Absyn.EquationItem>>> exp_elseifs_1,exp_elseifs,exp_equations_1,exp_equations;
      Absyn.ComponentRef old_comp,new_comp,cref1_1,cref2_1,cref1,cref2;
      String ident;
      Absyn.FunctionArgs function_args;
    case (Absyn.EQ_IF(ifExp = exp,equationTrueItems = true_items,elseIfBranches = exp_elseifs,equationElseItems = elses),old_comp,new_comp) /* the old name for the component */ 
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        true_items_1 = renameComponentInEquationList(true_items, old_comp, new_comp);
        exp_elseifs_1 = renameComponentInExpEquationitemList(exp_elseifs, old_comp, new_comp);
        elses_1 = renameComponentInEquationList(elses, old_comp, new_comp);
      then
        Absyn.EQ_IF(exp_1,true_items_1,exp_elseifs_1,elses_1);
    case (Absyn.EQ_EQUALS(leftSide = exp1,rightSide = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.EQ_EQUALS(exp1_1,exp2_1);
    case (Absyn.EQ_CONNECT(connector1 = cref1,connector2 = cref2),old_comp,new_comp)
      equation 
        cref1_1 = replaceStartInComponentRef(cref1, old_comp, new_comp);
        cref2_1 = replaceStartInComponentRef(cref2, old_comp, new_comp) "print \"-rename_component_in_equation EQ_CONNECT not implemented yet\\n\"" ;
      then
        Absyn.EQ_CONNECT(cref1_1,cref2_1);
    case (Absyn.EQ_FOR(forVariable = ident,forExp = exp,forEquations = equations),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
      then
        Absyn.EQ_FOR(ident,exp_1,equations_1);
    case (Absyn.EQ_WHEN_E(whenExp = exp,whenEquations = equations,elseWhenEquations = exp_equations),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        equations_1 = renameComponentInEquationList(equations, old_comp, new_comp);
        exp_equations_1 = renameComponentInExpEquationitemList(exp_equations, old_comp, new_comp);
      then
        Absyn.EQ_WHEN_E(exp_1,equations_1,exp_equations_1);
    case (Absyn.EQ_NORETCALL(functionName = ident,functionArgs = function_args),old_comp,new_comp)
      equation 
        print(
          "-rename_component_in_equation EQ_NORETCALL not implemented yet\n");
      then
        Absyn.EQ_NORETCALL(ident,function_args);
    case (_,old_comp,new_comp)
      equation 
        print("-rename_component_in_equation failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInEquation;

protected function renameComponentInExpList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.Exp> inAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.Exp> outAbsynExpLst;
algorithm 
  outAbsynExpLst:=
  matchcontinue (inAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.Exp> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((exp :: res),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInExpList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_exp_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpList;

protected function renameComponentInExpListList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<list<Absyn.Exp>> inAbsynExpLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<list<Absyn.Exp>> outAbsynExpLstLst;
algorithm 
  outAbsynExpLstLst:=
  matchcontinue (inAbsynExpLstLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exp_1,exp;
      list<list<Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((exp :: res),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExpList(exp, old_comp, new_comp);
        res_1 = renameComponentInExpListList(res, old_comp, new_comp);
      then
        (exp_1 :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_exp_list_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpListList;

protected function renameComponentInExpTupleList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<tuple<Absyn.Exp, Absyn.Exp>> inTplAbsynExpAbsynExpLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, Absyn.Exp>> outTplAbsynExpAbsynExpLst;
algorithm 
  outTplAbsynExpAbsynExpLst:=
  matchcontinue (inTplAbsynExpAbsynExpLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp1_1,exp2_1,exp1,exp2;
      list<tuple<Absyn.Exp, Absyn.Exp>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {}; 
    case (((exp1,exp2) :: res),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        res_1 = renameComponentInExpTupleList(res, old_comp, new_comp);
      then
        ((exp1_1,exp2_1) :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_exp_tuple_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpTupleList;

protected function renameComponentInElementArgList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.ElementArg> inAbsynElementArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.ElementArg element_arg_1,element_arg;
      list<Absyn.ElementArg> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((element_arg :: res),old_comp,new_comp)
      equation 
        element_arg_1 = renameComponentInElementArg(element_arg, old_comp, new_comp);
        res_1 = renameComponentInElementArgList(res, old_comp, new_comp);
      then
        (element_arg_1 :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_element_arg_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInElementArgList;

protected function renameComponentInElementArg "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.ElementArg inElementArg1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ElementArg outElementArg;
algorithm 
  outElementArg:=
  matchcontinue (inElementArg1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef cr_1,cr,old_comp,new_comp;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
      Boolean b;
      Absyn.Each each_;
      Option<String> str;
      Absyn.ElementSpec element_spec_1,element_spec2_1,element_spec,element_spec2;
      Absyn.RedeclareKeywords redecl;
      Option<Absyn.Comment> c;
    case (Absyn.MODIFICATION(finalItem = b,each_ = each_,componentReg = cr,modification = SOME(Absyn.CLASSMOD(element_args,SOME(exp))),comment = str),old_comp,new_comp) /* the old name for the component */ 
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,
          SOME(Absyn.CLASSMOD(element_args_1,SOME(exp_1))),str);
    case (Absyn.MODIFICATION(finalItem = b,each_ = each_,componentReg = cr,modification = SOME(Absyn.CLASSMOD(element_args,NONE)),comment = str),old_comp,new_comp)
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,SOME(Absyn.CLASSMOD(element_args_1,NONE)),str);
    case (Absyn.MODIFICATION(finalItem = b,each_ = each_,componentReg = cr,modification = NONE,comment = str),old_comp,new_comp)
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.MODIFICATION(b,each_,cr_1,NONE,str);
    case (Absyn.REDECLARATION(finalItem = b,redeclareKeywords = redecl,each_ = each_,elementSpec = element_spec,constrainClass = SOME(Absyn.CONSTRAINCLASS(element_spec2,c))),old_comp,new_comp)
      equation 
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
        element_spec2_1 = renameComponentInElementSpec(element_spec2, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,
          SOME(Absyn.CONSTRAINCLASS(element_spec2_1,c)));
    case (Absyn.REDECLARATION(finalItem = b,redeclareKeywords = redecl,each_ = each_,elementSpec = element_spec,constrainClass = NONE),old_comp,new_comp)
      equation 
        element_spec_1 = renameComponentInElementSpec(element_spec, old_comp, new_comp);
      then
        Absyn.REDECLARATION(b,redecl,each_,element_spec_1,NONE);
  end matchcontinue;
end renameComponentInElementArg;

protected function renameComponentInCode "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.Code inCode1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Code outCode;
algorithm 
  outCode:=
  matchcontinue (inCode1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path path;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr;
      list<Absyn.EquationItem> eqn_items_1,eqn_items;
      Boolean b,final_;
      list<Absyn.AlgorithmItem> algs_1,algs;
      Absyn.ElementSpec elementspec_1,elementspec;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constraint;
      Absyn.Exp exp_1,exp;
      list<Absyn.ElementArg> element_args_1,element_args;
    case (Absyn.C_TYPENAME(path = path),old_comp,new_comp) then Absyn.C_TYPENAME(path);  /* the old name for the component */ 
    case (Absyn.C_VARIABLENAME(componentRef = cr),old_comp,new_comp)
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.C_VARIABLENAME(cr_1);
    case (Absyn.C_EQUATIONSECTION(boolean = b,equationItemLst = eqn_items),old_comp,new_comp)
      equation 
        eqn_items_1 = renameComponentInEquationList(eqn_items, old_comp, new_comp);
      then
        Absyn.C_EQUATIONSECTION(b,eqn_items_1);
    case (Absyn.C_ALGORITHMSECTION(boolean = b,algorithmItemLst = algs),old_comp,new_comp)
      equation 
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.C_ALGORITHMSECTION(b,algs_1);
    case (Absyn.C_ELEMENT(element = Absyn.ELEMENT(final_ = final_,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,specification = elementspec,info = info,constrainClass = constraint)),old_comp,new_comp)
      equation 
        elementspec_1 = renameComponentInElementSpec(elementspec, old_comp, new_comp);
      then
        Absyn.C_ELEMENT(
          Absyn.ELEMENT(final_,redeclare_,inner_outer,name,elementspec_1,info,
          constraint));
    case (Absyn.C_EXPRESSION(exp = exp),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.C_EXPRESSION(exp_1);
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,expOption = SOME(exp))),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,SOME(exp_1)));
    case (Absyn.C_MODIFICATION(modification = Absyn.CLASSMOD(elementArgLst = element_args,expOption = NONE)),old_comp,new_comp)
      equation 
        element_args_1 = renameComponentInElementArgList(element_args, old_comp, new_comp);
      then
        Absyn.C_MODIFICATION(Absyn.CLASSMOD(element_args_1,NONE));
  end matchcontinue;
end renameComponentInCode;

protected function renameComponentInExp "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.Exp inExp1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp1,inComponentRef2,inComponentRef3)
    local
      Integer a;
      Absyn.ComponentRef old_comp,new_comp,cr_1,cr,cref;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2,exp_1,exp,exp3_1,exp3;
      Absyn.Operator op;
      list<tuple<Absyn.Exp, Absyn.Exp>> exp_tuple_list_1,exp_tuple_list;
      Absyn.FunctionArgs func_args;
      list<Absyn.Exp> exp_list_1,exp_list;
      list<list<Absyn.Exp>> exp_list_list_1,exp_list_list;
      Absyn.Code code_1,code;
    case (Absyn.INTEGER(value = a),old_comp,new_comp) then Absyn.INTEGER(a);  /* the old name for the component */ 
    case (Absyn.REAL(value = a),old_comp,new_comp)
      local Real a;
      then
        Absyn.REAL(a);
    case (Absyn.CREF(componentReg = cr),old_comp,new_comp)
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
      then
        Absyn.CREF(cr_1);
    case (Absyn.STRING(value = a),old_comp,new_comp)
      local String a;
      then
        Absyn.STRING(a);
    case (Absyn.BOOL(value = a),old_comp,new_comp)
      local Boolean a;
      then
        Absyn.BOOL(a);
    case (Absyn.BINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.BINARY(exp1_1,op,exp2_1);
    case (Absyn.UNARY(op = op,exp = exp),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.UNARY(op,exp);
    case (Absyn.LBINARY(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.LBINARY(exp1_1,op,exp2_1);
    case (Absyn.LUNARY(op = op,exp = exp),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.LUNARY(op,exp);
    case (Absyn.RELATION(exp1 = exp1,op = op,exp2 = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.RELATION(exp1_1,op,exp2_1);
    case (Absyn.IFEXP(ifExp = exp1,trueBranch = exp2,elseBranch = exp3,elseIfBranch = exp_tuple_list),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
        exp_tuple_list_1 = renameComponentInExpTupleList(exp_tuple_list, old_comp, new_comp);
      then
        Absyn.IFEXP(exp1_1,exp2_1,exp3_1,exp_tuple_list_1);
    case (Absyn.CALL(function_ = cref,functionArgs = func_args),old_comp,new_comp)
      equation 
        print(
          "-rename_component_in_exp for Absyn.CALL not implemented yet\n");
      then
        Absyn.CALL(cref,func_args);
    case (Absyn.ARRAY(arrayExp = exp_list),old_comp,new_comp)
      equation 
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.ARRAY(exp_list_1);
    case (Absyn.MATRIX(matrix = exp_list_list),old_comp,new_comp)
      equation 
        exp_list_list_1 = renameComponentInExpListList(exp_list_list, old_comp, new_comp);
      then
        Absyn.MATRIX(exp_list_list_1);
    case (Absyn.RANGE(start = exp1,step = SOME(exp2),stop = exp3),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,SOME(exp2_1),exp3_1);
    case (Absyn.RANGE(start = exp1,step = NONE,stop = exp3),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp3_1 = renameComponentInExp(exp3, old_comp, new_comp);
      then
        Absyn.RANGE(exp1_1,NONE,exp3_1);
    case (Absyn.TUPLE(expressions = exp_list),old_comp,new_comp)
      equation 
        exp_list_1 = renameComponentInExpList(exp_list, old_comp, new_comp);
      then
        Absyn.TUPLE(exp_list_1);
    case (Absyn.END(),old_comp,new_comp) then Absyn.END(); 
    case (Absyn.CODE(code = code),old_comp,new_comp)
      equation 
        code_1 = renameComponentInCode(code, old_comp, new_comp);
      then
        Absyn.CODE(code_1);
    case (_,old_comp,new_comp)
      equation 
        print("-rename_component_in_exp failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExp;

protected function renameComponentInAlgorithms "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.AlgorithmItem> outAbsynAlgorithmItemLst;
algorithm 
  outAbsynAlgorithmItemLst:=
  matchcontinue (inAbsynAlgorithmItemLst1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.AlgorithmItem> res_1,res;
      Absyn.AlgorithmItem algorithm_1,algorithm_;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((algorithm_ :: res),old_comp,new_comp)
      equation 
        res_1 = renameComponentInAlgorithms(res, old_comp, new_comp);
        algorithm_1 = algorithm_;
      then
        (algorithm_1 :: res_1);
  end matchcontinue;
end renameComponentInAlgorithms;

protected function renameComponentInAlgorithm "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.Algorithm inAlgorithm1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Algorithm outAlgorithm;
algorithm 
  outAlgorithm:=
  matchcontinue (inAlgorithm1,inComponentRef2,inComponentRef3)
    local
      Absyn.ComponentRef cr_1,cr,old_comp,new_comp;
      Absyn.Exp exp_1,exp,exp1_1,exp2_1,exp1,exp2;
      list<Absyn.AlgorithmItem> algs1_1,algs2_1,algs1,algs2,algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> exp_algs_list_1,exp_algs_list;
      String id;
      Absyn.FunctionArgs func_args_1,func_args;
    case (Absyn.ALG_ASSIGN(assignComponent = cr,value = exp),old_comp,new_comp) /* the old name for the component */ 
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
      then
        Absyn.ALG_ASSIGN(cr_1,exp_1);
    case (Absyn.ALG_TUPLE_ASSIGN(tuple_ = exp1,value = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.ALG_TUPLE_ASSIGN(exp1_1,exp2_1);
    case (Absyn.ALG_IF(ifExp = exp,trueBranch = algs1,elseIfAlgorithmBranch = exp_algs_list,elseBranch = algs2),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs1_1 = renameComponentInAlgorithms(algs1, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
        algs2_1 = renameComponentInAlgorithms(algs2, old_comp, new_comp);
      then
        Absyn.ALG_IF(exp_1,algs1_1,exp_algs_list_1,algs2_1);
    case (Absyn.ALG_FOR(forVariable = id,forStmt = exp,forBody = algs),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_FOR(id,exp_1,algs_1);
    case (Absyn.ALG_WHILE(whileStmt = exp,whileBody = algs),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
      then
        Absyn.ALG_WHILE(exp_1,algs_1);
    case (Absyn.ALG_WHEN_A(whenStmt = exp,whenBody = algs,elseWhenAlgorithmBranch = exp_algs_list),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        exp_algs_list_1 = renameComponentInExpAlgoritmsList(exp_algs_list, old_comp, new_comp);
      then
        Absyn.ALG_WHEN_A(exp_1,algs_1,exp_algs_list_1);
    case (Absyn.ALG_NORETCALL(functionCall = cr,functionArgs = func_args),old_comp,new_comp)
      equation 
        cr_1 = replaceStartInComponentRef(cr, old_comp, new_comp);
        func_args_1 = renameComponentInFunctionArgs(func_args, old_comp, new_comp);
      then
        Absyn.ALG_NORETCALL(cr_1,func_args_1);
  end matchcontinue;
end renameComponentInAlgorithm;

protected function renameComponentInExpAlgoritmsList "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> inTplAbsynExpAbsynAlgorithmItemLstLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> outTplAbsynExpAbsynAlgorithmItemLstLst;
algorithm 
  outTplAbsynExpAbsynAlgorithmItemLstLst:=
  matchcontinue (inTplAbsynExpAbsynAlgorithmItemLstLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.AlgorithmItem> algs_1,algs;
      list<tuple<Absyn.Exp, list<Absyn.AlgorithmItem>>> res_1,res;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {}; 
    case (((exp,algs) :: res),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        algs_1 = renameComponentInAlgorithms(algs, old_comp, new_comp);
        res_1 = renameComponentInExpAlgoritmsList(res, old_comp, new_comp);
      then
        ((exp_1,algs_1) :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_exp_algoritms_list failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInExpAlgoritmsList;

protected function renameComponentInFunctionArgs "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.FunctionArgs inFunctionArgs1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm 
  outFunctionArgs:=
  matchcontinue (inFunctionArgs1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.Exp> exps_1,exps;
      list<Absyn.NamedArg> namedArg_1,namedArg;
      Absyn.ComponentRef old_comp,new_comp;
      Absyn.Exp exp1_1,exp2_1,exp1,exp2;
      String id;
    case (Absyn.FUNCTIONARGS(args = exps,argNames = namedArg),old_comp,new_comp) /* the old name for the component */ 
      equation 
        exps_1 = renameComponentInExpList(exps, old_comp, new_comp);
        namedArg_1 = renameComponentInNamedArgs(namedArg, old_comp, new_comp);
      then
        Absyn.FUNCTIONARGS(exps_1,namedArg_1);
    case (Absyn.FOR_ITER_FARG(from = exp1,var = id,to = exp2),old_comp,new_comp)
      equation 
        exp1_1 = renameComponentInExp(exp1, old_comp, new_comp);
        exp2_1 = renameComponentInExp(exp2, old_comp, new_comp);
      then
        Absyn.FOR_ITER_FARG(exp1_1,id,exp2_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_function_args failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInFunctionArgs;

protected function renameComponentInNamedArgs "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.NamedArg> outAbsynNamedArgLst;
algorithm 
  outAbsynNamedArgLst:=
  matchcontinue (inAbsynNamedArgLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Exp exp_1,exp;
      list<Absyn.NamedArg> res_1,res;
      String id;
      Absyn.ComponentRef old_comp,new_comp;
    case ({},_,_) then {};  /* the old name for the component */ 
    case ((Absyn.NAMEDARG(argName = id,argValue = exp) :: res),old_comp,new_comp)
      equation 
        exp_1 = renameComponentInExp(exp, old_comp, new_comp);
        res_1 = renameComponentInNamedArgs(res, old_comp, new_comp);
      then
        (Absyn.NAMEDARG(id,exp_1) :: res_1);
    case (_,_,_)
      equation 
        print("-rename_component_in_namedArgs failed\n");
      then
        fail();
  end matchcontinue;
end renameComponentInNamedArgs;

protected function renameComponentInExternalDecl "
  author: x02lucpo
 
  helper function to rename_component_visitor
"
  input Absyn.ExternalDecl external_;
  input Absyn.ComponentRef old_comp;
  input Absyn.ComponentRef new_comp;
  output Absyn.ExternalDecl external_1;
  Absyn.ExternalDecl external_1;
algorithm 
  print("-rename_component_in_external_decl not implemented yet\n");
  external_1 := external_;
end renameComponentInExternalDecl;

protected function replaceStartInComponentRef "function replaceStartInComponentRef
  author x02lucpo
 
  this replace the start of a ComponentRef with another
  ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
"
  input Absyn.ComponentRef cr1;
  input Absyn.ComponentRef cr2;
  input Absyn.ComponentRef cr3;
  output Absyn.ComponentRef res;
algorithm 
  res := replaceStartInComponentRef2(cr1, cr2, cr3) "Dump.print_component_ref_str(cr1) => cref_str_tmp & print \" \" & print cref_str_tmp & Dump.print_component_ref_str(cr2) => cref_str_tmp & print \" \" & print cref_str_tmp & Dump.print_component_ref_str(cr3) => cref_str_tmp & print \" \" & print cref_str_tmp & Dump.print_component_ref_str(res) => cref_str_tmp & print \" res \" & print cref_str_tmp & print \"\\n\"" ;
end replaceStartInComponentRef;

protected function replaceStartInComponentRef2 "function replaceStartInComponentRef2 
  author x02lucpo
 
  this replace the start of a ComponentRef with another
  ie: (a.b.c.d, a.b, c.f) => c.f.c.d
     (a.b.c.d, d.c, c.f) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     (a.b.c.d, a.b, c.f.r) => a.b.c.d
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
     WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! 
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.ComponentRef outComponentRef;
algorithm 
  outComponentRef:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3)
    local
      String id,id2,id3;
      Absyn.ComponentRef res,cr1,cr,cr2,cr3,orig_cr;
      list<Absyn.Subscript> a;
    case (Absyn.CREF_IDENT(name = id),Absyn.CREF_IDENT(name = id2),(res as Absyn.CREF_IDENT(name = id3)))
      equation 
        equality(id = id2);
      then
        res;
    case (Absyn.CREF_QUAL(name = id,subScripts = a,componentRef = cr1),Absyn.CREF_IDENT(name = id2),Absyn.CREF_IDENT(name = id3))
      equation 
        equality(id = id2);
      then
        Absyn.CREF_QUAL(id3,a,cr1);
    case (Absyn.CREF_QUAL(name = id,subScripts = a,componentRef = cr1),Absyn.CREF_QUAL(name = id2,componentRef = cr2),Absyn.CREF_QUAL(name = id3,componentRef = cr3))
      equation 
        equality(id = id2);
        cr = replaceStartInComponentRef2(cr1, cr2, cr3);
      then
        Absyn.CREF_QUAL(id3,a,cr);
    case (orig_cr,_,_) then orig_cr; 
  end matchcontinue;
end replaceStartInComponentRef2;

protected function getComponentreplacementsrules "function getComponentreplacementsrules
  author: x02lucpo
 
  this extracts all the componentreplacementrules by searching for new rules until the
  list-size does not grow any more
"
  input Components inComponents;
  input ComponentReplacementRules inComponentReplacementRules;
  input Integer inInteger;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm 
  outComponentReplacementRules:=
  matchcontinue (inComponents,inComponentReplacementRules,inInteger)
    local
      Integer len,old_len;
      Components comps;
      ComponentReplacementRules comp_reps,comp_reps_1,comp_reps_2,comp_reps_res;
    case (comps,comp_reps,old_len)
      equation 
        len = lengthComponentReplacementRules(comp_reps);
        (len == old_len) = true;
      then
        comp_reps;
    case (comps,comp_reps,len)
      equation 
        old_len = lengthComponentReplacementRules(comp_reps);
        comp_reps_1 = getNewComponentreplacementsrulesForEachRule(comps, comp_reps);
        comp_reps_2 = joinComponentReplacementRules(comp_reps_1, comp_reps);
        comp_reps_res = getComponentreplacementsrules(comps, comp_reps_2, old_len);
      then
        comp_reps_res;
    case (comps,comp_reps,_)
      equation 
        print("-get_componentreplacementsrules failed\n");
      then
        fail();
  end matchcontinue;
end getComponentreplacementsrules;

protected function getNewComponentreplacementsrulesForEachRule "function getNewComponentreplacementsrulesForEachRule
  author: x02lucpo
 
 extracts the replacement rules from the components:
 {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},{REP_RULE(path_2,cr_1a,cr_1b)} 
           => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}
"
  input Components inComponents;
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm 
  outComponentReplacementRules:=
  matchcontinue (inComponents,inComponentReplacementRules)
    local
      Components comps,comps_1;
      ComponentReplacementRules comp_reps,comp_reps_1,res,comp_reps_2,comp_reps_3;
      Absyn.Path path;
      Absyn.ComponentRef cr1,cr2;
    case (comps,comp_reps)
      equation 
        true = emptyComponentReplacementRules(comp_reps);
      then
        comp_reps;
    case (comps,comp_reps)
      equation 
        COMPONENTREPLACEMENT(path,cr1,cr2) = firstComponentReplacement(comp_reps);
        comps_1 = getComponentsWithType(comps, path);
        comp_reps_1 = makeComponentsReplacementRulesFromComponents(comps_1, cr1, cr2);
        res = restComponentReplacementRules(comp_reps);
        comp_reps_2 = getNewComponentreplacementsrulesForEachRule(comps, res);
        comp_reps_3 = joinComponentReplacementRules(comp_reps_1, comp_reps_2);
      then
        comp_reps_3;
    case (_,_)
      equation 
        print(
          "-get_new_componentreplacementsrules_for_each_rule failed\n");
      then
        fail();
  end matchcontinue;
end getNewComponentreplacementsrulesForEachRule;

protected function makeComponentsReplacementRulesFromComponents "function makeComponentsReplacementRulesFromComponents
  author: x02lucpo
 
  this makes the replacementrules from each component in the first parameter:
  {COMP(path_1,path_2,cr1),COMP(path_3,path_2,cr2)},cr_1a,cr_1b 
            => {REP_RULE(path_1,cr1.cr_1a,cr1.cr_1b),REP_RULE(path_3,cr2.cr_1a,cr2.cr_1b)}
  
"
  input Components inComponents1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm 
  outComponentReplacementRules:=
  matchcontinue (inComponents1,inComponentRef2,inComponentRef3)
    local
      Components comps,res;
      Absyn.ComponentRef cr_from,cr_to,cr,cr_from_1,cr_to_1;
      Absyn.Path path_class,path_type;
      ComponentReplacement comp_rep;
      ComponentReplacementRules comps_1,comp_reps_res;
    case (comps,cr_from,cr_to)
      equation 
        true = emptyComponents(comps);
      then
        COMPONENTREPLACEMENTRULES({},0);
    case (comps,cr_from,cr_to)
      equation 
        COMPONENTITEM(path_class,path_type,cr) = firstComponent(comps);
        cr_from_1 = Absyn.joinCrefs(cr, cr_from);
        cr_to_1 = Absyn.joinCrefs(cr, cr_to);
        comp_rep = COMPONENTREPLACEMENT(path_class,cr_from_1,cr_to_1);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    case (comps,cr_from,cr_to)
      equation 
        EXTENDSITEM(path_class,path_type) = firstComponent(comps);
        comp_rep = COMPONENTREPLACEMENT(path_class,cr_from,cr_to);
        res = restComponents(comps);
        comps_1 = makeComponentsReplacementRulesFromComponents(res, cr_from, cr_to);
        comp_reps_res = joinComponentReplacementRules(comps_1, COMPONENTREPLACEMENTRULES({comp_rep},1));
      then
        comp_reps_res;
    case (_,_,_)
      equation 
        print("-make_componentsReplacementRules_from_components failed\n");
      then
        fail();
  end matchcontinue;
end makeComponentsReplacementRulesFromComponents;

protected function emptyComponentReplacementRules "function emptyComponentReplacementRules
  author: x02lucpo
 
  returns true if the componentReplacementRules are empty
"
  input ComponentReplacementRules inComponentReplacementRules;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentReplacementRules)
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then true; 
    case (_) then false; 
  end matchcontinue;
end emptyComponentReplacementRules;

protected function joinComponentReplacementRules "function joinComponentReplacementRules
 author: x02lucpo
 
 joins two componentReplacementRules lists by union
"
  input ComponentReplacementRules inComponentReplacementRules1;
  input ComponentReplacementRules inComponentReplacementRules2;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm 
  outComponentReplacementRules:=
  matchcontinue (inComponentReplacementRules1,inComponentReplacementRules2)
    local
      list<ComponentReplacement> comps,comps1,comps2;
      Integer len,len1,len2;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = comps1,the = len1),COMPONENTREPLACEMENTRULES(componentReplacementLst = comps2,the = len2))
      equation 
        comps = Util.listUnion(comps1, comps2);
        len = listLength(comps);
      then
        COMPONENTREPLACEMENTRULES(comps,len);
  end matchcontinue;
end joinComponentReplacementRules;

protected function lengthComponentReplacementRules "function lengthComponentReplacementRules
  author: x02lucpo
 
  return the number of the componentReplacementRules
"
  input ComponentReplacementRules inComponentReplacementRules;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inComponentReplacementRules)
    local Integer len;
    case (COMPONENTREPLACEMENTRULES(the = len)) then len; 
  end matchcontinue;
end lengthComponentReplacementRules;

protected function dumpComponentReplacementRulesToString "
  author: x02lucpo
 
  dumps all the componentReplacementRules to string
"
  input ComponentReplacementRules inComponentReplacementRules;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentReplacementRules)
    local
      ComponentReplacementRules res,comps;
      String s1,pa_str,cr1_str,cr2_str,res_str;
      Absyn.Path cr1_pa,cr2_pa,pa;
      Absyn.ComponentRef cr1,cr2;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then ""; 
    case ((comps as COMPONENTREPLACEMENTRULES(componentReplacementLst = (COMPONENTREPLACEMENT(which1 = pa,the2 = cr1,the3 = cr2) :: res))))
      equation 
        res = restComponentReplacementRules(comps);
        s1 = dumpComponentReplacementRulesToString(res);
        pa_str = Absyn.pathString(pa);
        cr1_pa = Absyn.crefToPath(cr1);
        cr1_str = Absyn.pathString(cr1_pa);
        cr2_pa = Absyn.crefToPath(cr2);
        cr2_str = Absyn.pathString(cr2_pa);
        res_str = Util.stringAppendList({s1,"In class: ",pa_str,"( ",cr1_str," => ",cr2_str," )\n"});
      then
        res_str;
  end matchcontinue;
end dumpComponentReplacementRulesToString;

protected function firstComponentReplacement "
  author: x02lucpo
 
 extract the first componentReplacement in the componentReplacementReplacementRules
"
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacement outComponentReplacement;
algorithm 
  outComponentReplacement:=
  matchcontinue (inComponentReplacementRules)
    local
      ComponentReplacement comp;
      list<ComponentReplacement> res;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {}))
      equation 
        print(
          "-first_componentReplacement failed: no componentReplacementReplacementRules\n");
      then
        fail();
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = (comp :: res))) then comp; 
  end matchcontinue;
end firstComponentReplacement;

protected function restComponentReplacementRules "
  author: x02lucpo
 
 extract the rest componentReplacementRules from the compoents
"
  input ComponentReplacementRules inComponentReplacementRules;
  output ComponentReplacementRules outComponentReplacementRules;
algorithm 
  outComponentReplacementRules:=
  matchcontinue (inComponentReplacementRules)
    local
      Integer len_1,len;
      ComponentReplacement comp;
      list<ComponentReplacement> res;
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = {})) then COMPONENTREPLACEMENTRULES({},0); 
    case (COMPONENTREPLACEMENTRULES(componentReplacementLst = (comp :: res),the = len))
      equation 
        len_1 = len - 1;
      then
        COMPONENTREPLACEMENTRULES(res,len_1);
  end matchcontinue;
end restComponentReplacementRules;

protected function getDependencyOnClass "
  author:x02lucpo
 
 returns _all_ the Components that the class depends on. It can be components or extends
  i.e if a class b has a component of type a and this is called with (<components>,\"a\")
  the it will also return b
"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps_types,comps_types2,comps2,comps;
      String str;
      Absyn.Path path;
    case (comps,path)
      equation 
        comps_types = getComponentsFromClass(comps, path);
        comps_types2 = getDependencyWithType(comps, comps_types, 0);
        str = dumpComponentsToString(comps_types);
        print("---------comps_types----------\n");
        print(str);
        print("===================\n");
        str = dumpComponentsToString(comps_types2);
        print("---------DEPENDENCIES----------\n");
        print(str);
        print("===================\n");
        comps2 = joinComponents(comps_types, comps_types2);
      then
        comps2;
    case (_,_)
      equation 
        print("-get_dependency_on_class failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyOnClass;

protected function getDependencyWithType "
author: x02lucpo
 
helper function to get_dependency_on_class
 extracts all the components that have the dependency on type
"
  input Components inComponents1;
  input Components inComponents2;
  input Integer inInteger3;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents1,inComponents2,inInteger3)
    local
      Integer len,old_len;
      Components comps,in_comps,in_comps_1,comps_1,out_comps;
    case (comps,in_comps,old_len) /* rule  dump_components_to_string(comps) => str & print \"---------comps----------\\n\" & print str & print \"===================\\n\" & dump_components_to_string(in_comps) => str & print \"---------in_comps----------\\n\" & print str & print \"===================\\n\" & int_eq(1,2) => true --------------------------- get_dependency_with_type(comps, in_comps, old_len) => in_comps */ 
      equation 
        len = lengthComponents(in_comps);
        (old_len == len) = true;
      then
        in_comps;
    case (comps,in_comps,old_len)
      equation 
        len = lengthComponents(in_comps);
        in_comps_1 = getComponentsWithComponentsClass(comps, in_comps) "get_components_with_components_type(comps,in_comps) => in_comps\' &" ;
        comps_1 = joinComponents(in_comps_1, in_comps);
        out_comps = getDependencyWithType(comps, comps_1, len);
      then
        out_comps;
    case (_,_,_)
      equation 
        print("-get_dependency_with_type failed\n");
      then
        fail();
  end matchcontinue;
end getDependencyWithType;

protected function getComponentsWithComponentsClass "
author x02lucpo
 
  extracts all the components with class == the class of the components 
  in the second list 
  from first list of Components 
"
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path;
    case (comps,in_comps)
      equation 
        true = emptyComponents(in_comps);
      then
        COMPONENTS({},0);
    case (comps,in_comps)
      equation 
        ((comp as COMPONENTITEM(comp_path,_,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation 
        ((comp as EXTENDSITEM(comp_path,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsClass(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (_,_)
      equation 
        print("-get_components_with_components_class failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsClass;

protected function getComponentsWithComponentsType "
author x02lucpo
 
 extracts all the components with class == the type of the components 
  in the second list 
 from first list of Components 
"
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      Components comps,in_comps,in_comps_1,comp1,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path;
    case (comps,in_comps)
      equation 
        true = emptyComponents(in_comps);
      then
        COMPONENTS({},0);
    case (comps,in_comps)
      equation 
        ((comp as COMPONENTITEM(_,comp_path,_))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (comps,in_comps)
      equation 
        ((comp as EXTENDSITEM(_,comp_path))) = firstComponent(in_comps);
        in_comps_1 = restComponents(in_comps);
        comp1 = getComponentsWithType(comps, comp_path);
        comps_1 = getComponentsWithComponentsType(comps, in_comps_1);
        comps_2 = joinComponents(comp1, comps_1);
      then
        comps_2;
    case (_,_)
      equation 
        print("-get_components_with_components_type failed\n");
      then
        fail();
  end matchcontinue;
end getComponentsWithComponentsType;

protected function getComponentsFromClass "
 author: x02lucpo
 
 extracts all the components that are in the class
"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps,res,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_from_class(comps,path) => comps */ 
      equation 
        true = emptyComponents(comps);
      then
        COMPONENTS({},0);
    case (comps,path)
      equation 
        ((comp as COMPONENTITEM(comp_path,_,_))) = firstComponent(comps);
        true = ModUtil.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation 
        ((comp as EXTENDSITEM(comp_path,_))) = firstComponent(comps);
        true = ModUtil.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation 
        res = restComponents(comps);
        comps_1 = getComponentsFromClass(res, path);
      then
        comps_1;
    case (_,_)
      equation 
        print("-get_components_from_class failed\n");
      then
        COMPONENTS({},0);
  end matchcontinue;
end getComponentsFromClass;

protected function getComponentsWithType "
 author: x02lucpo
 
 extracts all the components that have the type
"
  input Components inComponents;
  input Absyn.Path inPath;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents,inPath)
    local
      Components comps,res,comps_1,comps_2;
      Component comp;
      Absyn.Path comp_path,path;
    case (comps,_) /* rule  Absyn.path_string(path) => comp_path & print \"extracting comps for: \" & print comp_path & print \"\\n\" & int_eq(1,2) => true --------------------------- get_components_with_type(comps,path) => comps */ 
      equation 
        true = emptyComponents(comps);
      then
        COMPONENTS({},0);
    case (comps,path)
      equation 
        ((comp as COMPONENTITEM(_,comp_path,_))) = firstComponent(comps);
        true = ModUtil.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation 
        ((comp as EXTENDSITEM(_,comp_path))) = firstComponent(comps);
        true = ModUtil.pathEqual(comp_path, path);
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
        comps_2 = addComponentToComponents(comp, comps_1);
      then
        comps_2;
    case (comps,path)
      equation 
        res = restComponents(comps);
        comps_1 = getComponentsWithType(res, path);
      then
        comps_1;
    case (_,_)
      equation 
        print("-get_components_with_type failed\n");
      then
        COMPONENTS({},0);
  end matchcontinue;
end getComponentsWithType;

protected function extractAllComponents "
  author: x02lucpo
  
 this traverse all the classes and extracts all the components and \"extends\"
"
  input Absyn.Program p;
  output Components comps;
  Absyn.Program p_1;
  list<Env.Frame> env;
algorithm 
  p_1 := SCode.elaborate(p);
  (_,env) := Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
  ((p_1,_,(comps,p,env))) := traverseClasses(p, NONE, extractAllComponentsVisitor, 
          (COMPONENTS({},0),p,env), true) "traverse protected" ;
end extractAllComponents;

protected function extractAllComponentsVisitor "function extractAllComponentsVisitor 
  author: x02lucpo
 
  the visitor for traverse-classes that extracts all the components and extends
  from all classes
"
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<Components, Absyn.Program, Env.Env>> inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Components, Absyn.Program, Env.Env>> outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv;
algorithm 
  outTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplComponentsAbsynProgramEnvEnv)
    local
      Absyn.Path path_1,pa_1,pa;
      list<Env.Frame> cenv,env;
      Components comps_1,comps;
      Absyn.Class class_;
      String id;
      Boolean a,b,c;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.Program p;
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),SOME(pa),(comps,p,env)))
      equation 
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,SOME(pa),(comps_1,p,env)));
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),NONE,(comps,p,env)))
      equation 
        path_1 = Absyn.IDENT(id);
        cenv = getClassEnvNoElaboration(p, path_1, env);
        (_,pa_1) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        comps_1 = extractComponentsFromClass(class_, pa_1, comps, cenv);
      then
        ((class_,NONE,(comps_1,p,env)));
  end matchcontinue;
end extractAllComponentsVisitor;

protected function extractComponentsFromClass "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inClass,inPath,inComponents,inEnv)
    local
      Components comps_1,comps;
      String id;
      Absyn.ClassDef classdef;
      Absyn.Info info;
      Absyn.Path pa;
      list<Env.Frame> env;
    case (Absyn.CLASS(name = id,body = classdef,info = info),pa,comps,env) /* the QUALIFIED path */ 
      equation 
        comps_1 = extractComponentsFromClassdef(pa, classdef, comps, env);
      then
        comps_1;
    case (_,_,comps,env)
      equation 
        print("-extract_components_from_class failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromClass;

protected function extractComponentsFromClassdef "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Path inPath;
  input Absyn.ClassDef inClassDef;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inClassDef,inComponents,inEnv)
    local
      Components comps_1,comps;
      Absyn.Path pa,path;
      list<Absyn.ClassPart> parts;
      list<Env.Frame> env;
      list<Absyn.ElementArg> elementargs,elementarg;
      String id_ex;
    case (pa,Absyn.PARTS(classParts = parts),comps,env) /* the QUALIFIED path for the class */ 
      equation 
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    case (pa,Absyn.DERIVED(path = path,arguments = elementargs),comps,env)
      equation 
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env) "& print \"extract_components_from_classdef for DERIVED not implemented yet\\n\"" ;
      then
        comps_1;
    case (pa,Absyn.CLASS_EXTENDS(name = id_ex,arguments = elementarg,parts = parts),comps,env)
      equation 
        comps_1 = extractComponentsFromClassparts(pa, parts, comps, env);
      then
        comps_1;
    case (pa,_,comps,env) then comps; 
  end matchcontinue;
end extractComponentsFromClassdef;

protected function extractComponentsFromClassparts "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Path inPath;
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inAbsynClassPartLst,inComponents,inEnv)
    local
      Components comps,comps_1,comps_2;
      list<Env.Frame> env;
      Absyn.Path pa;
      list<Absyn.ElementItem> elements;
      list<Absyn.ClassPart> res;
    case (_,{},comps,env) then comps;  /* the QUALIFIED path for the class */ 
    case (pa,(Absyn.PUBLIC(contents = elements) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;
    case (pa,(Absyn.PROTECTED(contents = elements) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromClassparts(pa, res, comps, env);
        comps_2 = extractComponentsFromElements(pa, elements, comps_1, env);
      then
        comps_2;
    case (_,_,comps,env) then comps; 
  end matchcontinue;
end extractComponentsFromClassparts;

protected function extractComponentsFromElements "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inAbsynElementItemLst,inComponents,inEnv)
    local
      Components comps,comps_1,comps_2;
      list<Env.Frame> env;
      Absyn.Path pa;
      Absyn.ElementSpec elementspec;
      list<Absyn.ElementItem> res;
      Absyn.ElementItem element;
    case (_,{},comps,env) then comps;  /* the QUALIFIED path for the class */ 
    case (pa,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = elementspec)) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromElements(pa, res, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec, comps_1, env);
      then
        comps_2;
    case (pa,(element :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromElements(pa, res, comps, env);
      then
        comps;
  end matchcontinue;
end extractComponentsFromElements;

protected function extractComponentsFromElementspec "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Path inPath;
  input Absyn.ElementSpec inElementSpec;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inElementSpec,inComponents,inEnv)
    local
      String id;
      list<Env.Frame> cenv,env;
      Absyn.Path path_1,path,pa;
      Components comps_1,comps,comps_2;
      list<Absyn.ComponentItem> comp_items;
      Component comp;
      list<Absyn.ElementArg> elementargs;
    case (pa,Absyn.COMPONENTS(typeName = path_1,components = comp_items),comps,env) /* the QUALIFIED path for the class */ 
      equation 
        (_,SCode.CLASS(id,_,_,_,_),cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        path_1 = Absyn.IDENT(id);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        comps_1 = extractComponentsFromComponentitems(pa, path, comp_items, comps, env);
      then
        comps_1;
    case (pa,Absyn.EXTENDS(path = path_1,elementArg = elementargs),comps,env)
      equation 
        (_,_,cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false) "print \"extract_components_from_elementspec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        comp = EXTENDSITEM(pa,path);
        comps_1 = addComponentToComponents(comp, comps);
        comps_2 = extractComponentsFromElementargs(pa, elementargs, comps_1, env);
      then
        comps_2;
    case (_,_,comps,env) then comps;  /* rule  extract_components_from_class(class,pa,comps,env) => comps\' ------------------------------- extract_components_from_elementspec(pa,Absyn.CLASSDEF(_,class), comps,env) => comps\' */ 
  end matchcontinue;
end extractComponentsFromElementspec;

protected function extractComponentsFromComponentitems "
  author: x02lucpo
 
  help function to extract_all_components_visitor
"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst3;
  input Components inComponents4;
  input Env.Env inEnv5;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath1,inPath2,inAbsynComponentItemLst3,inComponents4,inEnv5)
    local
      Components comps,comps_1,comps_2,comps_3;
      list<Env.Frame> env;
      Absyn.ComponentRef comp;
      Absyn.Path pa,path;
      String id;
      Option<Absyn.Modification> mod_opt;
      list<Absyn.ComponentItem> res;
    case (_,_,{},comps,env) then comps;  /* the QUALIFIED path for the class the fully qualifired path for the type of the component */ 
    case (pa,path,(Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,modification = mod_opt)) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromComponentitems(pa, path, res, comps, env);
        comp = Absyn.CREF_IDENT(id,{});
        comps_2 = addComponentToComponents(COMPONENTITEM(pa,path,comp), comps_1);
        comps_3 = extractComponentsFromModificationOption(pa, mod_opt, comps_2, env);
      then
        comps_3;
    case (_,_,_,_,env)
      equation 
        print("-extract_components_from_componentitems failed\n");
      then
        fail();
  end matchcontinue;
end extractComponentsFromComponentitems;

protected function extractComponentsFromElementargs
  input Absyn.Path inPath;
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inAbsynElementArgLst,inComponents,inEnv)
    local
      Absyn.Path pa;
      Components comps,comps_1,comps_2,comps_3;
      list<Env.Frame> env;
      Absyn.ElementSpec elementspec,elementspec2;
      list<Absyn.ElementArg> res;
      Absyn.ConstrainClass constrainclass;
      Option<Absyn.Modification> mod_opt;
      Absyn.ElementArg a;
    case (pa,{},comps,env) then comps;  /* the QUALIFIED path for the class */ 
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(Absyn.CONSTRAINCLASS(elementspec2,_))) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementspec(pa, elementspec2, comps_1, env);
        comps_3 = extractComponentsFromElementargs(pa, res, comps_2, env);
      then
        comps_3;
    case (pa,(Absyn.REDECLARATION(elementSpec = elementspec,constrainClass = SOME(constrainclass)) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromElementspec(pa, elementspec, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(Absyn.MODIFICATION(modification = mod_opt) :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromModificationOption(pa, mod_opt, comps, env);
        comps_2 = extractComponentsFromElementargs(pa, res, comps_1, env);
      then
        comps_2;
    case (pa,(a :: res),comps,env)
      equation 
        comps_1 = extractComponentsFromElementargs(pa, res, comps, env);
      then
        comps_1;
  end matchcontinue;
end extractComponentsFromElementargs;

protected function extractComponentsFromModificationOption
  input Absyn.Path inPath;
  input Option<Absyn.Modification> inAbsynModificationOption;
  input Components inComponents;
  input Env.Env inEnv;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inPath,inAbsynModificationOption,inComponents,inEnv)
    local
      Absyn.Path pa;
      Components comps,comps_1;
      list<Env.Frame> env;
      list<Absyn.ElementArg> elementargs;
    case (pa,NONE,comps,env) then comps;  /* the QUALIFIED path for the class */ 
    case (pa,SOME(Absyn.CLASSMOD(elementargs,_)),comps,env)
      equation 
        comps_1 = extractComponentsFromElementargs(pa, elementargs, comps, env);
      then
        comps_1;
  end matchcontinue;
end extractComponentsFromModificationOption;

protected function joinComponents "
 author: x02lucpo
 joins two components lists by union
"
  input Components inComponents1;
  input Components inComponents2;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents1,inComponents2)
    local
      list<Component> comps,comps1,comps2;
      Integer len,len1,len2;
    case (COMPONENTS(componentLst = comps1,the = len1),COMPONENTS(componentLst = comps2,the = len2))
      equation 
        comps = Util.listUnion(comps1, comps2);
        len = listLength(comps);
      then
        COMPONENTS(comps,len);
  end matchcontinue;
end joinComponents;

protected function existsComponentInComponents "
author: x02lucpo
checks if a component exists in the components
"
  input Components inComponents;
  input Component inComponent;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponents,inComponent)
    local
      Component comp;
      Absyn.Path a,b,ap,bp;
      Absyn.ComponentRef c,cr;
      Components comps;
      Boolean res;
    case (COMPONENTS(componentLst = {}),comp) then false; 
    case (comps,COMPONENTITEM(the1 = ap,the2 = bp,the3 = cr))
      equation 
        COMPONENTITEM(a,b,c) = firstComponent(comps);
        true = ModUtil.pathEqual(a, ap);
        true = ModUtil.pathEqual(b, bp);
        true = Absyn.crefEqual(c, cr);
      then
        true;
    case (comps,EXTENDSITEM(the1 = ap,the2 = bp))
      equation 
        EXTENDSITEM(a,b) = firstComponent(comps);
        true = ModUtil.pathEqual(a, ap);
        true = ModUtil.pathEqual(b, bp);
      then
        true;
    case (comps,comp)
      equation 
        res = existsComponentInComponents(comps, comp);
      then
        res;
  end matchcontinue;
end existsComponentInComponents;

protected function emptyComponents "
  author: x02lucpo
  returns true if the components are empty
"
  input Components inComponents;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponents)
    case (COMPONENTS(componentLst = {})) then true; 
    case (_) then false; 
  end matchcontinue;
end emptyComponents;

protected function firstComponent "
  author: x02lucpo
 extract the first component in the components
"
  input Components inComponents;
  output Component outComponent;
algorithm 
  outComponent:=
  matchcontinue (inComponents)
    local
      Component comp;
      list<Component> res;
    case (COMPONENTS(componentLst = {}))
      equation 
        print("-first_component failed: no components\n");
      then
        fail();
    case (COMPONENTS(componentLst = (comp :: res))) then comp; 
  end matchcontinue;
end firstComponent;

protected function restComponents "
  author: x02lucpo
 extract the rest components from the compoents
"
  input Components inComponents;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponents)
    local
      Integer len_1,len;
      Component comp;
      list<Component> res;
    case (COMPONENTS(componentLst = {})) then COMPONENTS({},0); 
    case (COMPONENTS(componentLst = (comp :: res),the = len))
      equation 
        len_1 = len - 1;
      then
        COMPONENTS(res,len_1);
  end matchcontinue;
end restComponents;

protected function lengthComponents "
  author: x02lucpo
  return the number of the components
"
  input Components inComponents;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inComponents)
    local Integer len;
    case (COMPONENTS(the = len)) then len; 
  end matchcontinue;
end lengthComponents;

protected function addComponentToComponents "
  author: x02lucpo
  add a component to components
"
  input Component inComponent;
  input Components inComponents;
  output Components outComponents;
algorithm 
  outComponents:=
  matchcontinue (inComponent,inComponents)
    local
      Integer len_1,len;
      Component comp;
      list<Component> comps;
    case (comp,COMPONENTS(componentLst = comps,the = len))
      equation 
        len_1 = len + 1;
      then
        COMPONENTS((comp :: comps),len_1);
  end matchcontinue;
end addComponentToComponents;

protected function dumpComponentsToString "
  author: x02lucpo
  dumps all the components to string
"
  input Components inComponents;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponents)
    local
      Components res,comps;
      String s1,pa_str,path_str,cr_str,res_str;
      Absyn.Path cr_pa,pa,path;
      Absyn.ComponentRef cr;
    case (COMPONENTS(componentLst = {})) then ""; 
    case ((comps as COMPONENTS(componentLst = (COMPONENTITEM(the1 = pa,the2 = path,the3 = cr) :: res))))
      equation 
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        cr_pa = Absyn.crefToPath(cr);
        cr_str = Absyn.pathString(cr_pa);
        res_str = Util.stringAppendList(
          {s1,"cl: ",pa_str,"\t type: ",path_str,"\t\t name: ",cr_str,
          "\n"});
      then
        res_str;
    case ((comps as COMPONENTS(componentLst = (EXTENDSITEM(the1 = pa,the2 = path) :: res))))
      equation 
        res = restComponents(comps);
        s1 = dumpComponentsToString(res);
        pa_str = Absyn.pathString(pa);
        path_str = Absyn.pathString(path);
        res_str = Util.stringAppendList({s1,"ex: ",pa_str,"\t exte: ",path_str,"\n"});
      then
        res_str;
  end matchcontinue;
end dumpComponentsToString;

protected function isParameterElement "function: isParameterElement
  
   Returns true if Element is a component of variability parameter, 
   false otherwise.
"
  input Absyn.Element inElement;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inElement)
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = Absyn.ATTR(variability = Absyn.PARAM())))) then true; 
    case (_) then false; 
  end matchcontinue;
end isParameterElement;

protected function getParameterNames "function: getParameterNames
  
   Retrieves the names of all parameters in the class 
  
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.Program)
   outputs:  string 
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      list<Absyn.Element> comps,comps_1;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<String> names;
      String res,res_1;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        comps_1 = Util.listSelect(comps, isParameterElement);
        compelts = Util.listMap(comps_1, getComponentitemsInElement);
        compelts_1 = Util.listFlatten(compelts);
        names = Util.listMap(compelts_1, getComponentitemName);
        res = Util.stringDelimitList(names, ", ");
        res_1 = Util.stringAppendList({"{",res,"}"});
      then
        res_1;
    case (_,_) then "Error"; 
  end matchcontinue;
end getParameterNames;

protected function getClassEnv "function: getClassEnv
  
   Retrieves the environment of the class, including the frame of the class
   itself by partially instantiating it.
"
  input Absyn.Program p;
  input Absyn.Path p_class;
  output Env.Env env_2;
  list<SCode.Class> p_1;
  list<Env.Frame> env,env_1,env2,env_2;
  SCode.Class cl;
  String id;
  Boolean encflag;
  SCode.Restriction restr;
  ClassInf.State ci_state;
algorithm 
  env_2 := matchcontinue (p,p_class)
   case (p,p_class) // Special case for derived classes. When instantiating a derived class, the environment
   									// of the derived class is returned, which can be a totally different scope.
     local Absyn.Path tp;								
      equation 
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,(cl as SCode.CLASS(id,_,encflag,restr,SCode.DERIVED(short=tp))),env_1) = Lookup.lookupClass(Env.emptyCache,env, p_class, false);
      then env_1;
        
    case (p,p_class) 
      equation 
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,(cl as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(Env.emptyCache,env, p_class, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,env_2,_) = Inst.partialInstClassIn(Env.emptyCache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, cl, false, {});
      then env_2;
    case (p,p_class) then {};
  end matchcontinue;
end getClassEnv;

protected function getClassEnvNoElaboration "function: getClassEnvNoElaboration
  
   Retrieves the environment of the class, including the frame of the class
   itself by partially instantiating it.
"
  input Absyn.Program p;
  input Absyn.Path p_class;
  input Env.Env env;
  output Env.Env env_2;
  SCode.Class cl;
  String id;
  Boolean encflag;
  SCode.Restriction restr;
  list<Env.Frame> env_1,env2,env_2;
  ClassInf.State ci_state;
algorithm 
  (_,(cl as SCode.CLASS(id,_,encflag,restr,_)),env_1) := Lookup.lookupClass(Env.emptyCache,env, p_class, false);
  env2 := Env.openScope(env_1, encflag, SOME(id));
  ci_state := ClassInf.start(restr, id);
  (_,env_2,_) := Inst.partialInstClassIn(Env.emptyCache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, cl, false, {});
end getClassEnvNoElaboration;

protected function setComponentProperties "function: setComponentProperties
 
  Sets the following \"properties\" of a component.
  - final 
  - flow
  - protected(true) or public(false)
  - replaceable 
  - variablity: \"constant\" or \"discrete\" or \"parameter\" or \"\"
  - dynamic_ref: {inner, outer} - two boolean values.
  - causality: \"input\" or \"output\" or \"\"
 
  inputs:  (Absyn.Path, /* class */
              Absyn.ComponentRef, /* component_ref */
              bool, /* final = true */
              bool, /* flow = true */
              bool, /* protected = true, public=false */
              bool,  /* replaceable = true */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string, /* causality */
              Absyn.Program)
  outputs: (string, Absyn.Program) 
"
  input Absyn.Path inPath1;
  input Absyn.ComponentRef inComponentRef2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  input Boolean inBoolean5;
  input Boolean inBoolean6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  input Absyn.Program inProgram10;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inPath1,inComponentRef2,inBoolean3,inBoolean4,inBoolean5,inBoolean6,inString7,inBooleanLst8,inString9,inProgram10)
    local
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.Path p_class;
      String varname,variability,causality;
      Boolean final_,flow_,prot,repl;
      list<Boolean> dyn_ref;
    case (p_class,Absyn.CREF_IDENT(name = varname),final_,flow_,prot,repl,variability,dyn_ref,causality,p)
      equation 
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentPropertiesInClass(cdef, varname, final_, flow_, prot, repl, variability, 
          dyn_ref, causality);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        ("Ok",newp);
    case (_,_,_,_,_,_,_,_,_,p) then ("Error",p); 
  end matchcontinue;
end setComponentProperties;

protected function setComponentPropertiesInClass "function: setComponentPropertiesInClass
 
  Helperfunction to set_component_properties.
 
  inputs:  (Absyn.Class,
              string, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* prot */
              bool, /* repl */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs: Absyn.Class 
"
  input Absyn.Class inClass1;
  input String inString2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  input Boolean inBoolean5;
  input Boolean inBoolean6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inString2,inBoolean3,inBoolean4,inBoolean5,inBoolean6,inString7,inBooleanLst8,inString9)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,varname,variability,causality;
      Boolean p,f,e,final_,flow_,prot,repl;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      list<Boolean> dyn_ref;
    case (Absyn.CLASS(name = id,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),varname,final_,flow_,prot,repl,variability,dyn_ref,causality)
      equation 
        parts_1 = setComponentPropertiesInClassparts(parts, varname, final_, flow_, prot, repl, variability, 
          dyn_ref, causality);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(parts_1,cmt),file_info);
  end matchcontinue;
end setComponentPropertiesInClass;

protected function setComponentPropertiesInClassparts "function: setComponentPropertiesInClassparts
  
   Helperfunction to set_component_properties_in_class.
  
   inputs: (Absyn.ClassPart list, 
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* prot */
              bool, /* repl */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
   outputs: Absyn.ClassPart list
"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Ident inIdent2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  input Boolean inBoolean5;
  input Boolean inBoolean6;
  input String inString7;
  input list<Boolean> inBooleanLst8;
  input String inString9;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inIdent2,inBoolean3,inBoolean4,inBoolean5,inBoolean6,inString7,inBooleanLst8,inString9)
    local
      list<Absyn.ElementItem> publst,publst_1,protlst,protlst_1,elts_1,elts;
      Absyn.Element elt,elt_1;
      list<Absyn.ClassPart> parts_1,parts_2,parts,rest,rest_1;
      String cr,variability,causality;
      Boolean final_,flow_,repl,prot;
      list<Boolean> dyn_ref;
      Absyn.ClassPart part;
    case ({},_,_,_,_,_,_,_,_) then {}; 
    case (parts,cr,final_,flow_,true,repl,variability,dyn_ref,causality) /* public moved to protected protected moved to public */ 
      equation 
        publst = getPublicList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), publst);
        elt_1 = setComponentPropertiesInElement(elt, cr, final_, flow_, repl, variability, dyn_ref, 
          causality);
        publst_1 = deleteComponentFromElementitems(cr, publst);
        protlst = getProtectedList(parts);
        protlst_1 = listAppend(protlst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replaceProtectedList(parts, protlst_1);
        parts_2 = replacePublicList(parts_1, publst_1);
      then
        parts_2;
    case (parts,cr,final_,flow_,false,repl,variability,dyn_ref,causality) /* protected moved to public protected attr not changed. */ 
      equation 
        protlst = getProtectedList(parts);
        Absyn.ELEMENTITEM(elt) = getElementitemContainsName(Absyn.CREF_IDENT(cr,{}), protlst);
        elt_1 = setComponentPropertiesInElement(elt, cr, final_, flow_, repl, variability, dyn_ref, 
          causality);
        protlst_1 = deleteComponentFromElementitems(cr, protlst);
        publst = getPublicList(parts);
        publst_1 = listAppend(publst, {Absyn.ELEMENTITEM(elt_1)});
        parts_1 = replacePublicList(parts, publst_1);
        parts_2 = replaceProtectedList(parts_1, protlst_1);
      then
        parts_2;
    case ((Absyn.PUBLIC(contents = elts) :: rest),cr,final_,flow_,prot,repl,variability,dyn_ref,causality) /* protected attr not changed. protected attr not changed, 2. */ 
      equation 
        rest = setComponentPropertiesInClassparts(rest, cr, final_, flow_, prot, repl, variability, dyn_ref, 
          causality);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, final_, flow_, repl, variability, dyn_ref, 
          causality);
      then
        (Absyn.PUBLIC(elts_1) :: rest);
    case ((Absyn.PROTECTED(contents = elts) :: rest),cr,final_,flow_,prot,repl,variability,dyn_ref,causality) /* protected attr not changed, 2. */ 
      equation 
        rest = setComponentPropertiesInClassparts(rest, cr, final_, flow_, prot, repl, variability, dyn_ref, 
          causality);
        elts_1 = setComponentPropertiesInElementitems(elts, cr, final_, flow_, repl, variability, dyn_ref, 
          causality);
      then
        (Absyn.PROTECTED(elts_1) :: rest);
    case ((part :: rest),cr,final_,flow_,prot,repl,variability,dyn_ref,causality) /* protected attr not changed, 3. */ 
      equation 
        rest_1 = setComponentPropertiesInClassparts(rest, cr, final_, flow_, prot, repl, variability, dyn_ref, 
          causality);
      then
        (part :: rest_1);
  end matchcontinue;
end setComponentPropertiesInClassparts;

protected function setComponentPropertiesInElementitems "function: setComponentPropertiesInElementitems
 
  Helperfunction to set_component_properties_in_classparts.
 
  inputs:  (Absyn.ElementItem list,
              Absyn.Ident, /* comp_name */
              bool, /* final */
              bool, /* flow */
              bool, /* repl */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs:  Absyn.ElementItem list
"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Ident inIdent2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  input Boolean inBoolean5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst1,inIdent2,inBoolean3,inBoolean4,inBoolean5,inString6,inBooleanLst7,inString8)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String cr,va,cau;
      Boolean final_,flow_,repl;
      list<Boolean> dr;
    case ({},_,_,_,_,_,_,_) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),cr,final_,flow_,repl,va,dr,cau)
      equation 
        res = setComponentPropertiesInElementitems(rest, cr, final_, flow_, repl, va, dr, cau);
        elt_1 = setComponentPropertiesInElement(elt, cr, final_, flow_, repl, va, dr, cau);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elt :: rest),cr,final_,flow_,repl,va,dr,cau)
      local Absyn.ElementItem elt;
      equation 
        res = setComponentPropertiesInElementitems(rest, cr, final_, flow_, repl, va, dr, cau);
      then
        (elt :: res);
  end matchcontinue;
end setComponentPropertiesInElementitems;

protected function setComponentPropertiesInElement "function: setComponentPropertiesInElement
  
  Helperfunction to e.g. set_component_properties_in_elementitems.
 
  inputs:  (Absyn.Element,
              Absyn.Ident,
              bool, /* final */
              bool, /* flow */
              bool, /* repl */
              string, /* variability */
              bool list, /* dynamic_ref, two booleans */
              string) /* causality */
  outputs: Absyn.Element
"
  input Absyn.Element inElement1;
  input Absyn.Ident inIdent2;
  input Boolean inBoolean3;
  input Boolean inBoolean4;
  input Boolean inBoolean5;
  input String inString6;
  input list<Boolean> inBooleanLst7;
  input String inString8;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inElement1,inIdent2,inBoolean3,inBoolean4,inBoolean5,inString6,inBooleanLst7,inString8)
    local
      Option<Absyn.RedeclareKeywords> redeclkw_1,redeclkw;
      Absyn.InnerOuter inout_1,inout;
      Absyn.ElementSpec spec_1,spec;
      String id,cr,va,cau;
      list<Absyn.ComponentItem> ellst;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Boolean final_,flow_,repl;
      list<Boolean> dr;
      Absyn.Element elt;
    case (Absyn.ELEMENT(redeclareKeywords = redeclkw,innerOuter = inout,name = id,specification = (spec as Absyn.COMPONENTS(components = ellst)),info = info,constrainClass = constr),cr,final_,flow_,repl,va,dr,cau)
      equation 
        _ = getCompitemNamed(Absyn.CREF_IDENT(cr,{}), ellst);
        redeclkw_1 = setReplaceableKeywordAttributes(redeclkw, repl);
        inout_1 = setInnerOuterAttributes(dr);
        spec_1 = setComponentPropertiesInElementspec(spec, cr, flow_, va, cau);
      then
        Absyn.ELEMENT(final_,redeclkw_1,inout_1,id,spec_1,info,constr);
    case (elt,cr,_,_,_,_,_,_) then elt; 
  end matchcontinue;
end setComponentPropertiesInElement;

protected function setReplaceableKeywordAttributes "function: setReplaceableKeywordAttributes
 
  Sets The RedeclareKeywords of an Element given a boolean \'replaceable\'.
 
  inputs:  (Absyn.RedeclareKeywords option, 
              bool /* repl */)
  outputs: Absyn.RedeclareKeywords option =
"
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  input Boolean inBoolean;
  output Option<Absyn.RedeclareKeywords> outAbsynRedeclareKeywordsOption;
algorithm 
  outAbsynRedeclareKeywordsOption:=
  matchcontinue (inAbsynRedeclareKeywordsOption,inBoolean)
    case (NONE,false) then NONE;  /* false */ 
    case (SOME(Absyn.REPLACEABLE()),false) then NONE; 
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),false) then SOME(Absyn.REDECLARE()); 
    case (SOME(Absyn.REDECLARE()),false) then SOME(Absyn.REDECLARE()); 
    case (NONE,true) then SOME(Absyn.REPLACEABLE());  /* true */ 
    case (SOME(Absyn.REDECLARE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE()); 
    case (SOME(Absyn.REPLACEABLE()),true) then SOME(Absyn.REPLACEABLE()); 
    case (SOME(Absyn.REDECLARE_REPLACEABLE()),true) then SOME(Absyn.REDECLARE_REPLACEABLE()); 
  end matchcontinue;
end setReplaceableKeywordAttributes;

protected function setInnerOuterAttributes "function: setInnerOuterAttributes
 
 
  Sets InnerOuter according to a list of two booleans, {inner, outer}.
"
  input list<Boolean> inBooleanLst;
  output Absyn.InnerOuter outInnerOuter;
algorithm 
  outInnerOuter:=
  matchcontinue (inBooleanLst)
    case ({false,false}) then Absyn.UNSPECIFIED(); 
    case ({true,false}) then Absyn.INNER(); 
    case ({false,true}) then Absyn.OUTER(); 
    case ({true,true}) then Absyn.INNEROUTER(); 
  end matchcontinue;
end setInnerOuterAttributes;

protected function setComponentPropertiesInElementspec "function: setComponentPropertiesInElementspec
 
  Sets component attributes on an elements spec if identifier matches.
  
  inputs:  (Absyn.ElementSpec,
              Absyn.Ident,
              bool, /* flow */
              string, /* variability */
              string) /* causality */
  outputs:  Absyn.ElementSpec
"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Ident inIdent2;
  input Boolean inBoolean3;
  input String inString4;
  input String inString5;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inElementSpec1,inIdent2,inBoolean3,inString4,inString5)
    local
      Absyn.ElementAttributes attr_1,attr;
      Absyn.Path path;
      list<Absyn.ComponentItem> items;
      String cr,va,cau;
      Boolean flow_;
      Absyn.ElementSpec spec;
    case (Absyn.COMPONENTS(attributes = attr,typeName = path,components = items),cr,flow_,va,cau)
      equation 
        itemsContainCompname(items, cr);
        attr_1 = setElementAttributes(attr, flow_, va, cau);
      then
        Absyn.COMPONENTS(attr_1,path,items);
    case (spec,_,_,_,_) then spec; 
  end matchcontinue;
end setComponentPropertiesInElementspec;

protected function itemsContainCompname "function: itemsContainCompname
 
  Checks if a list of ElementItems contain a component named \'cr\'.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
algorithm 
  _:=
  matchcontinue (inAbsynComponentItemLst,inIdent)
    local
      String cr1,cr2,cr;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = cr1)) :: _),cr2)
      equation 
        equality(cr1 = cr2);
      then
        ();
    case ((_ :: rest),cr)
      equation 
        itemsContainCompname(rest, cr);
      then
        ();
  end matchcontinue;
end itemsContainCompname;

protected function setElementAttributes "function: setElementAttributes
 
  Sets  attributes associated with ElementAttribues.
 
  inputs: (Absyn.ElementAttributes,
             bool, /* flow */
             string, /* variability */
             string) /*causality */
  outputs: Absyn.ElementAttributes
"
  input Absyn.ElementAttributes inElementAttributes1;
  input Boolean inBoolean2;
  input String inString3;
  input String inString4;
  output Absyn.ElementAttributes outElementAttributes;
algorithm 
  outElementAttributes:=
  matchcontinue (inElementAttributes1,inBoolean2,inString3,inString4)
    local
      Absyn.Variability va_1;
      Absyn.Direction cau_1;
      list<Absyn.Subscript> dim;
      Boolean flow_;
      String va,cau;
    case (Absyn.ATTR(arrayDim = dim),flow_,va,cau)
      equation 
        va_1 = setElementVariability(va);
        cau_1 = setElementCausality(cau);
      then
        Absyn.ATTR(flow_,va_1,cau_1,dim);
  end matchcontinue;
end setElementAttributes;

protected function setElementVariability "function setElementVariability 
 
  Sets Variability according to string value.
"
  input String inString;
  output Absyn.Variability outVariability;
algorithm 
  outVariability:=
  matchcontinue (inString)
    case ("") then Absyn.VAR(); 
    case ("discrete") then Absyn.DISCRETE(); 
    case ("parameter") then Absyn.PARAM(); 
    case ("constant") then Absyn.CONST(); 
  end matchcontinue;
end setElementVariability;

protected function setElementCausality "function setElementCausality 
 
  Sets Direction (causality) according to string value.
"
  input String inString;
  output Absyn.Direction outDirection;
algorithm 
  outDirection:=
  matchcontinue (inString)
    case ("") then Absyn.BIDIR(); 
    case ("input") then Absyn.INPUT(); 
    case ("output") then Absyn.OUTPUT(); 
  end matchcontinue;
end setElementCausality;

protected function selectString "function: selectString
   author: adrpo@ida
   date  : 2006-02-05 
   if bool is true select first string, otherwise the second one
"
  input Boolean inBoolean1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inBoolean1,inString2,inString3)
    local String s1,s2;
    case (true,s1,_) then s1; 
    case (false,_,s2) then s2; 
  end matchcontinue;
end selectString;

protected function getCrefInfo "function: getCrefInfo
   author: adrpo@ida
   date  : 2005-11-03, changed 2006-02-05 to match new Absyn.INFO 
   Retrieves the Info attribute of a Class.
   When parsing classes, the source:
   file name + isReadOnly + start lineno + start columnno + end lineno + end columnno is added to the Class 
   definition and to all Elements, see Absyn.Info. This function retrieves the
   Info contents.
   
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.Program) 
   outputs:   string
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String id,filename,str_sline,str_scol,str_eline,str_ecol,s,str_readonly;
      Boolean isReadOnly;
      Integer sline,scol,eline,ecol;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        Absyn.CLASS(name = id,info = Absyn.INFO(fileName = filename,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)) = cdef;
        str_sline = intString(sline);
        str_scol = intString(scol);
        str_eline = intString(eline);
        str_ecol = intString(ecol);
        s = stringAppend(filename, ",");
        str_readonly = selectString(isReadOnly, "readonly", "writable");
        s = stringAppend(s, str_readonly);
        s = stringAppend(s, ",");
        s = stringAppend(s, str_sline);
        s = stringAppend(s, ",");
        s = stringAppend(s, str_scol);
        s = stringAppend(s, ",");
        s = stringAppend(s, str_eline);
        s = stringAppend(s, ",");
        s = stringAppend(s, str_ecol);
      then
        s;
    case (_,_) then "Error"; 
  end matchcontinue;
end getCrefInfo;

protected function getImportString "function: getImportString
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to get_element_type 
"
  input Absyn.Import inImport;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inImport)
    local
      String path_str,str,id;
      Absyn.Path path;
    case (Absyn.NAMED_IMPORT(name = id,path = path))
      equation 
        path_str = Absyn.pathString(path);
        str = Util.stringAppendList({"kind=named, id=",id,", path=",path_str});
      then
        str;
    case (Absyn.QUAL_IMPORT(path = path))
      equation 
        path_str = Absyn.pathString(path);
        str = Util.stringAppendList({"kind=qualified, path=",path_str});
      then
        str;
    case (Absyn.UNQUAL_IMPORT(path = path))
      equation 
        path_str = Absyn.pathString(path);
        str = Util.stringAppendList({"kind=unqualified, path=",path_str});
      then
        str;
  end matchcontinue;
end getImportString;

protected function getElementType "function: getElementType
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to get_element_info 
"
  input Absyn.ElementSpec inElementSpec;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementSpec)
    local
      String path_str,str,import_str,typename,flow_str,variability_str,dir_str,names_str;
      Absyn.Path path,path_type;
      Absyn.Import import_;
      list<String> names;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> lst;
    case (Absyn.EXTENDS(path = path))
      equation 
        path_str = Absyn.pathString(path);
        str = Util.stringAppendList({"elementtype=extends, path=",path_str});
      then
        str;
    case (Absyn.IMPORT(import_ = import_))
      equation 
        import_str = getImportString(import_);
        str = Util.stringAppendList({"elementtype=import, ",import_str});
      then
        str;
    case (Absyn.COMPONENTS(attributes = attr,typeName = path_type,components = lst))
      equation 
        typename = Absyn.pathString(path_type);
        names = getComponentitemsName(lst);
        flow_str = attrFlowStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        names_str = Util.stringDelimitList(names, ", ");
        str = Util.stringAppendList(
          {"elementtype=component, typename=",typename,", names={",
          names_str,"}, flow=",flow_str,", variability=",variability_str,", direction=",
          dir_str});
      then
        str;
  end matchcontinue;
end getElementType;

protected function getElementInfo "function: getElementInfo
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to construct_element_info & get_elements_info 
"
  input Absyn.ElementItem inElementItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementItem)
    local
      String final_,repl,inout_str,str_restriction,element_str,sline_str,scol_str,eline_str,ecol_str,readonly_str,str,id,file;
      Boolean r_1,f,p,fi,e,isReadOnly;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.Restriction restr;
      Integer sline,scol,eline,ecol;
      Absyn.ElementSpec elementSpec;
      Absyn.Info info;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,partial_ = p,final_ = fi,encapsulated_ = e,restricion = restr,info = Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol)))))) /* ok, first see if is a classdef if is not a classdef, just follow the normal stuff */ 
      equation 
        final_ = Util.boolString(f);
        r_1 = keywordReplaceable(r);
        repl = Util.boolString(r_1);
        inout_str = innerOuterStr(inout);
        str_restriction = Absyn.restrString(restr) "compile the classdef string" ;
        element_str = Util.stringAppendList(
          {"elementtype=classdef, classname=",id,
          ", classrestriction=",str_restriction});
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        str = Util.stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",final_,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,name = id,specification = elementSpec,info = (info as Absyn.INFO(fileName = file,isReadOnly = isReadOnly,lineNumberStart = sline,columnNumberStart = scol,lineNumberEnd = eline,columnNumberEnd = ecol))))) /* if is not a classdef, just follow the normal stuff */ 
      equation 
        final_ = Util.boolString(f);
        r_1 = keywordReplaceable(r);
        repl = Util.boolString(r_1);
        inout_str = innerOuterStr(inout);
        element_str = getElementType(elementSpec);
        sline_str = intString(sline);
        scol_str = intString(scol);
        eline_str = intString(eline);
        ecol_str = intString(ecol);
        readonly_str = selectString(isReadOnly, "readonly", "writable");
        str = Util.stringAppendList(
          {"elementfile=\"",file,"\", elementreadonly=\"",
          readonly_str,"\", elementStartLine=",sline_str,", elementStartColumn=",scol_str,
          ", elementEndLine=",eline_str,", elementEndColumn=",ecol_str,", final=",final_,
          ", replaceable=",repl,", inout=",inout_str,", ",element_str});
      then
        str;
    case (_) then "elementtype=annotation";  /* for annotations we don\'t care */ 
  end matchcontinue;
end getElementInfo;

protected function constructElementsInfo "function: constructElementsInfo
   author: adrpo@ida
   date  : 2005-11-11
   helperfunction to get_elements_info
  
   inputs:  (string /* \"public\" or \"protected\" */, Absyn.ElementItem list) 
   outputs:  string
"
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString,inAbsynElementItemLst)
    local
      String visibility_str,s1,element_str,res,s2;
      Absyn.ElementItem current;
      list<Absyn.ElementItem> rest;
    case (visibility_str,{}) /* Util.string_append_list({\"{ elementvisibility=\", visibility_str,\" }\"}) => res */  then ""; 
    case (visibility_str,(current :: {})) /* deal with the last element */ 
      equation 
        s1 = getElementInfo(current);
        element_str = Util.stringAppendList({"{ elementvisibility=",visibility_str,", ",s1," }"});
        res = Util.stringAppendList({element_str,"\n"});
      then
        res;
    case (visibility_str,(current :: rest))
      equation 
        s1 = getElementInfo(current);
        element_str = Util.stringAppendList({"{ elementvisibility=",visibility_str,", ",s1," }"});
        s2 = constructElementsInfo(visibility_str, rest);
        res = Util.stringAppendList({element_str,",\n",s2});
      then
        res;
  end matchcontinue;
end constructElementsInfo;

protected function appendNonEmptyStrings "function: appendNonEmptyStrings
   author: adrpo@ida
   date  : 2005-11-11
   helper to get_elements_info
   input: \"\", \"\", \",\" => \"\"
          \"some\", \"\", \",\" => \"some\"
          \"some\", \"some\", \",\" => \"some, some\" 
"
  input String inString1;
  input String inString2;
  input String inString3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString1,inString2,inString3)
    local String s1,s2,str,delimiter;
    case ("","",_) then ""; 
    case (s1,"",_) then s1; 
    case ("",s2,_) then s2; 
    case (s1,s2,delimiter)
      equation 
        str = Util.stringAppendList({s1,delimiter,s2});
      then
        str;
  end matchcontinue;
end appendNonEmptyStrings;

protected function getElementsInfo "function: getElementsInfo
   author: adrpo@ida
   date  : 2005-11-11, changed 2006-02-06 to mirror the new Absyn.INFO
   Retrieves the Info attribute of an element.
   When parsing elements of the class composition, the source:
    -> file name + readonly + start lineno + start columnno + end lineno + end columnno is added to the Element 
   and to the Class definition, see Absyn.Info. 
   This function retrieves the Info contents of the elements of a class.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      String i,public_str,protected_str,elements_str,str;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> public_elementitem_list,protected_elementitem_list;
      Absyn.ComponentRef model_;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        public_elementitem_list = getPublicList(parts);
        protected_elementitem_list = getProtectedList(parts);
        public_str = constructElementsInfo("public", public_elementitem_list);
        protected_str = constructElementsInfo("protected", protected_elementitem_list);
        elements_str = appendNonEmptyStrings(public_str, protected_str, ", ");
        str = Util.stringAppendList({"{ ",elements_str," }"});
      then
        str;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        Absyn.CLASS(i,p,f,e,r,_,_) = getPathedClassInProgram(modelpath, p) "there are no elements in DERIVED, ENUMERATION, OVERLOAD, CLASS_EXTENDS and PDER
		    maybe later we can give info about that also" ;
      then
        "{ }";
    case (_,_) then "Error"; 
  end matchcontinue;
end getElementsInfo;

protected function getSourceFile "function: getSourceFile
   author: PA
  
   Retrieves the Source file attribute of a Class.
   When parsing classes, the source file name is added to the Class 
   definition and to all Elements, see Absyn. Thisfunction retrieves the
   source file of the Class.
   
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.Program)
   outputs: string
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef;
      String filename;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,p) /* class */ 
      equation 
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        filename = Absyn.classFilename(cdef);
      then
        filename;
    case (_,_) then "Error"; 
  end matchcontinue;
end getSourceFile;

protected function setSourceFile "function: setSourceFile
   author: PA
  
   Sets the source file of a Class. Is for instance used
   when adding a new class to an aldready stored package.
   The class should then have the same file as the package.
  
   inputs:   (Absyn.ComponentRef, /* class */
                string, /* filename */
                Absyn.Program) 
   outputs: (string, Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  input Absyn.Program inProgram;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inComponentRef,inString,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Class cdef,cdef_1;
      Absyn.Within within_;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      String filename;
    case (class_,filename,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        cdef = getPathedClassInProgram(p_class, p);
        within_ = buildWithin(p_class);
        cdef_1 = Absyn.setClassFilename(cdef, filename);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        ("Ok",newp);
    case (_,_,p) then ("Error",p); 
  end matchcontinue;
end setSourceFile;

protected function setExtendsModifierValue "function: setExtendsModifierValue
  
   Thisfunction sets the submodifier value of an extends clause in a Class.
   for instance,
   model test extends A(p1=3,p2(z=3));end test;
   setExtendsModifierValue(test,A,p1,Code(=4)) => OK
   => model test extends A(p1=4,p2(z=3));end test;
  
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.ComponentRef, /* inherit class */
                Absyn.ComponentRef, /* subident */
                Absyn.Modification,
                Absyn.Program)
   outputs:  (Absyn.Program,string)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Modification inModification4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inModification4,inProgram5)
    local
      Absyn.Path p_class,inherit_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      list<Env.Frame> env;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,inheritclass,subident;
      Absyn.Modification mod;
    case (class_,inheritclass,subident,mod,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        inherit_class = Absyn.crefToPath(inheritclass);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        cdef_1 = setExtendsSubmodifierInClass(cdef, inherit_class, subident, mod, env);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error"); 
  end matchcontinue;
end setExtendsModifierValue;

protected function setExtendsSubmodifierInClass "function: setExtendsSubmodifierInClass
   author: PA
  
   Sets a modifier of an extends clause for a given subcomponent.
   For instance, 
   extends A(b=4); // b is subcomponent
  
   inputs:  (Absyn.Class, 
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               Env.Env)
   outputs: Absyn.Class
"
  input Absyn.Class inClass;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Path inherit_name;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
    case (Absyn.CLASS(name = id,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),inherit_name,submod,mod,env)
      equation 
        parts_1 = setExtendsSubmodifierInClassparts(parts, inherit_name, submod, mod, env);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(parts_1,cmt),file_info);
  end matchcontinue;
end setExtendsSubmodifierInClass;

protected function setExtendsSubmodifierInClassparts "function: setExtendsSubmodifierInClassparts
  
   Helperfunction to set_extends_submodifier_in_class
   
   inputs:   (Absyn.ClassPart list, 
                Absyn.Path, /* inherit_name */
                Absyn.ComponentRef, /* submodifier */
                Absyn.Modification,
                Env.Env)
   outputs:  Absyn.ClassPart list
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
      Absyn.ClassPart elt;
    case ({},_,_,_,_) then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest),inherit,submod,mod,env)
      equation 
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PUBLIC(elts_1) :: res);
    case ((Absyn.PROTECTED(contents = elts) :: rest),inherit,submod,mod,env)
      equation 
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
        elts_1 = setExtendsSubmodifierInElementitems(elts, inherit, submod, mod, env);
      then
        (Absyn.PROTECTED(elts_1) :: res);
    case ((elt :: rest),inherit,submod,mod,env)
      equation 
        res = setExtendsSubmodifierInClassparts(rest, inherit, submod, mod, env);
      then
        (elt :: res);
  end matchcontinue;
end setExtendsSubmodifierInClassparts;

protected function setExtendsSubmodifierInElementitems "function: setExtendsSubmodifierInElementitems
  
   Helperfunction to set_extends_submodifier_in_classparts
  
   inputs:  (Absyn.ElementItem list,
               Absyn.Path, /* inherit_name */
               Absyn.ComponentRef, /* submodifier */
               Absyn.Modification,
               Env.Env)
   outputs:  Absyn.ElementItem list
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inPath,inComponentRef,inModification,inEnv)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      Absyn.Path inherit;
      Absyn.ComponentRef submod;
      Absyn.Modification mod;
      list<Env.Frame> env;
    case ({},_,_,_,_) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),inherit,submod,mod,env)
      equation 
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
        elt_1 = setExtendsSubmodifierInElement(elt, inherit, submod, mod, env);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elt :: rest),inherit,submod,mod,env)
      local Absyn.ElementItem elt;
      equation 
        res = setExtendsSubmodifierInElementitems(rest, inherit, submod, mod, env);
      then
        (elt :: res);
  end matchcontinue;
end setExtendsSubmodifierInElementitems;

protected function setExtendsSubmodifierInElement "function: setExtendsSubmodifierInElement
  
   Helperfunction to set_extends_submodifier_in_elementitems
   
   inputs: (Absyn.Element, 
              Absyn.Path, /* inherit_name */
              Absyn.ComponentRef, /* submodifier */
              Absyn.Modification,
              Env.Env)
   outputs:  Absyn.Element
"
  input Absyn.Element inElement;
  input Absyn.Path inPath;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  input Env.Env inEnv;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inElement,inPath,inComponentRef,inModification,inEnv)
    local
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n;
      Absyn.Path path,inherit,path_1;
      list<Absyn.ElementArg> eargs,eargs_1;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ComponentRef submod;
      list<Env.Frame> env;
      Absyn.Modification mod;
      Absyn.Element elt;
      /* special case for clearing modifications */  
   /* case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs),info = info,constrainClass = constr),
      inherit,submod,Absyn.CLASSMOD(elementArgLst = {},expOption = NONE),env) 
      
      then Absyn.ELEMENT(f,r,i,n,Absyn.EXTENDS(path,{}),info,constr); */
        
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.EXTENDS(path = path,elementArg = eargs),info = info,constrainClass = constr),
      inherit,submod,mod,env)
      equation 
        (_,path_1) = Inst.makeFullyQualified(Env.emptyCache,env, path);
        true = ModUtil.pathEqual(inherit, path_1);
        eargs_1 = setSubmodifierInElementargs(eargs, submod, mod);
      then
        Absyn.ELEMENT(f,r,i,n,Absyn.EXTENDS(path,eargs_1),info,constr);
    case (elt,_,_,_,_) then elt; 
  end matchcontinue;
end setExtendsSubmodifierInElement;

protected function getExtendsModifierValue "function: getExtendsModifierValue
  
   Return the submodifier value of an extends clause
   for instance,
   model test extends A(p1=3,p2(z=3));end test;
   getExtendsModifierValue(test,A,p1) => =3
   
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.ComponentRef, /* subident */
               Absyn.Program) 
   outputs:  string 
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      list<Env.Frame> env;
      list<Absyn.ElementSpec> exts,exts_1;
      list<Absyn.ElementArg> extmod;
      Absyn.Modification mod;
      String res;
      Absyn.ComponentRef class_,inherit_name,subident;
      Absyn.Program p;
    case (class_,inherit_name,subident,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        env = getClassEnv(p, p_class);
        exts = getExtendsElementspecInClass(cdef);
        exts_1 = Util.listMap1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(extpath,extmod)} = Util.listSelect1(exts_1, name, extendsElementspecNamed);
        mod = getModificationValue(extmod, subident);
        res = Dump.unparseModificationStr(mod);
      then
        res;
    case (_,_,_,_) then "Error"; 
  end matchcontinue;
end getExtendsModifierValue;

protected function makeExtendsFullyQualified "function: makeExtendsFullyQualified
  
   Makes an EXTENDS ElementSpec having a fully qualified extends path.
"
  input Absyn.ElementSpec inElementSpec;
  input Env.Env inEnv;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inElementSpec,inEnv)
    local
      Absyn.Path path_1,path;
      list<Absyn.ElementArg> earg;
      list<Env.Frame> env;
    case (Absyn.EXTENDS(path = path,elementArg = earg),env)
      equation 
        (_,path_1) = Inst.makeFullyQualified(Env.emptyCache,env, path);
      then
        Absyn.EXTENDS(path_1,earg);
  end matchcontinue;
end makeExtendsFullyQualified;

protected function getExtendsModifierNames "function: getExtendsModifierNames
  
   Return the modifier names of a modification on an extends clause.
   For instance,
   model test extends A(p1=3,p2(z=3));end test;
   getExtendsModifierNames(test,A) => {p1,p2}
  
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* inherited class */
               Absyn.Program) 
   outputs: (string)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class,name,extpath;
      Absyn.Class cdef;
      list<Absyn.ElementSpec> exts,exts_1;
      list<Env.Frame> env;
      list<Absyn.ElementArg> extmod;
      list<String> res;
      String res_1,res_2;
      Absyn.ComponentRef class_,inherit_name;
      Absyn.Program p;
    case (class_,inherit_name,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        name = Absyn.crefToPath(inherit_name);
        cdef = getPathedClassInProgram(p_class, p);
        exts = getExtendsElementspecInClass(cdef);
        env = getClassEnv(p, p_class);
        exts_1 = Util.listMap1(exts, makeExtendsFullyQualified, env);
        {Absyn.EXTENDS(extpath,extmod)} = Util.listSelect1(exts_1, name, extendsElementspecNamed);
        res = getModificationNames(extmod);
        res_1 = Util.stringDelimitList(res, ", ");
        res_2 = Util.stringAppendList({"{",res_1,"}"});
      then
        res_2;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getExtendsModifierNames;

protected function extendsElementspecNamed "function extends_elementspec_name
 
  Returns true if elementspec of EXTENDS has the name given as path, 
  false otherwise.
"
  input Absyn.ElementSpec inElementSpec;
  input Absyn.Path inPath;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inElementSpec,inPath)
    local
      Boolean res;
      Absyn.Path extpath,path;
    case (Absyn.EXTENDS(path = extpath),path)
      equation 
        res = ModUtil.pathEqual(path, extpath);
      then
        res;
  end matchcontinue;
end extendsElementspecNamed;

protected function extendsName "function extendsName
 
  Return the class name of an EXTENDS element spec.
"
  input Absyn.ElementSpec inElementSpec;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inElementSpec)
    local Absyn.Path path;
    case (Absyn.EXTENDS(path = path)) then path; 
  end matchcontinue;
end extendsName;

protected function getExtendsElementspecInClass "function: getExtendsElementspecInClass
 
  Retrieve all ElementSpec of a class that are EXTENDS.
"
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementSpec> ext;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> eltArg;
      Absyn.Path tp;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        ext = getExtendsElementspecInClassparts(parts);
      then
        ext;
    case (Absyn.CLASS(body = Absyn.DERIVED(path=tp, arguments=eltArg)))
      then
        {Absyn.EXTENDS(tp,eltArg)}; // Note: the array dimensions of DERIVED are lost. They must be 
        														// queried by another api-function
    case (_) then {}; 
  end matchcontinue;
end getExtendsElementspecInClass;

protected function getExtendsElementspecInClassparts "function: getExtendsElementspecInClassparts
 
  Helperfunction to get_extends_elementspec_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      Absyn.ClassPart elt;
    case ({}) then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation 
        lst1 = getExtendsElementspecInClassparts(rest);
        lst2 = getExtendsElementspecInElementitems(elts);
        res = listAppend(lst1, lst2);
      then
        res;
    case ((elt :: rest))
      equation 
        res = getExtendsElementspecInClassparts(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInClassparts;

protected function getExtendsElementspecInElementitems "function: getExtendsElementspecInElementitems
 
  Helperfunction to get_extends_elementspec_in_classparts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.ElementSpec elt;
      list<Absyn.ElementSpec> res;
      list<Absyn.ElementItem> rest;
    case ({}) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest))
      equation 
        elt = getExtendsElementspecInElement(elt) "Bug in RML. If the two premisses below are in swapped order
	  the compiler enters infinite loop (but no stack overflow)" ;
        res = getExtendsElementspecInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation 
        res = getExtendsElementspecInElementitems(rest);
      then
        res;
  end matchcontinue;
end getExtendsElementspecInElementitems;

protected function getExtendsElementspecInElement "function: getExtendsElementspecInElement
 
  Helperfunction to get_extends_elementspec_in_elementitems.
"
  input Absyn.Element inElement;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inElement)
    local Absyn.ElementSpec ext;
    case (Absyn.ELEMENT(specification = (ext as Absyn.EXTENDS(path = _)))) then ext; 
  end matchcontinue;
end getExtendsElementspecInElement;

protected function setComponentModifier "function: setComponentModifier
  
   Sets a submodifier of a component.
   
   inputs:   (Absyn.ComponentRef, /* class */
                Absyn.ComponentRef, /* variable name */
                Absyn.ComponentRef, /* submodifier name */
                Absyn.Modification, 
                Absyn.Program)
   outputs: (Absyn.Program, string)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Modification inModification4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inModification4,inProgram5)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,subident;
      String varname;
      Absyn.Modification mod;
    case (class_,Absyn.CREF_IDENT(name = varname),subident,mod,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentSubmodifierInClass(cdef, varname, subident, mod);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error"); 
  end matchcontinue;
end setComponentModifier;

protected function setComponentSubmodifierInClass "function: setComponentSubmodifierInClass
  
   Sets a sub modifier on a component in a class.
  
   inputs: (Absyn.Class, 
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.Class
"
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,varname;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
    case (Absyn.CLASS(name = id,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),varname,submodident,mod)
      equation 
        parts_1 = setComponentSubmodifierInClassparts(parts, varname, submodident, mod);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(parts_1,cmt),file_info);
  end matchcontinue;
end setComponentSubmodifierInClass;

protected function setComponentSubmodifierInClassparts "function: setComponentSubmodifierInClassparts
  
   Helperfunction to set_component_submodifier_in_class
   
   inputs:  (Absyn.ClassPart list, 
               Absyn.Ident, /* component name */
               Absyn.ComponentRef, /* subvariable path */
               Absyn.Modification)
   outputs:  Absyn.ClassPart list
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      String varname;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      Absyn.ClassPart elt;
    case ({},_,_,_) then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest),varname,submodident,mod)
      equation 
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
        elts_1 = setComponentSubmodifierInElementitems(elts, varname, submodident, mod);
      then
        (Absyn.PUBLIC(elts_1) :: res);
    case ((Absyn.PROTECTED(contents = elts) :: rest),varname,submodident,mod)
      equation 
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
        elts_1 = setComponentSubmodifierInElementitems(elts, varname, submodident, mod);
      then
        (Absyn.PROTECTED(elts_1) :: res);
    case ((elt :: rest),varname,submodident,mod)
      equation 
        res = setComponentSubmodifierInClassparts(rest, varname, submodident, mod);
      then
        (elt :: res);
  end matchcontinue;
end setComponentSubmodifierInClassparts;

protected function setComponentSubmodifierInElementitems "function: setComponentSubmodifierInElementitems
  
   Helperfunction to set_component_submodifier_in_classparts
   
   inputs: (Absyn.ElementItem list,
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* subvariable path */
              Absyn.Modification)
   outputs: Absyn.ElementItem list
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String varname;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
    case ({},_,_,_) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),varname,submodident,mod)
      equation 
        res = setComponentSubmodifierInElementitems(rest, varname, submodident, mod);
        elt_1 = setComponentSubmodifierInElement(elt, varname, submodident, mod);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elt :: rest),varname,submodident,mod)
      local Absyn.ElementItem elt;
      equation 
        res = setComponentSubmodifierInElementitems(rest, varname, submodident, mod);
      then
        (elt :: res);
  end matchcontinue;
end setComponentSubmodifierInElementitems;

protected function setComponentSubmodifierInElement "function: setComponentSubmodifierInElement
  
   Helperfunction to set_component_submodifier_in_elementitems
  
   inputs: (Absyn.Element, 
              Absyn.Ident, /* component name */
              Absyn.ComponentRef, /* submodifier path */
              Absyn.Modification)
   outputs: Absyn.Element
"
  input Absyn.Element inElement;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inElement,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ComponentItem> compitems_1,compitems;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n,varname;
      Absyn.ElementAttributes attr;
      Absyn.Path tp;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.ComponentRef submodident;
      Absyn.Modification mod;
      Absyn.Element elt;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = i,name = n,
      specification = Absyn.COMPONENTS(attributes = attr,typeName = tp,components = compitems),
      info = info,constrainClass = constr),varname,submodident,mod)
      equation 
        compitems_1 = setComponentSubmodifierInCompitems(compitems, varname, submodident, mod);
      then
        Absyn.ELEMENT(f,r,i,n,Absyn.COMPONENTS(attr,tp,compitems_1),info,constr);
    case (elt,_,_,_) then elt; 
  end matchcontinue;
end setComponentSubmodifierInElement;

protected function setComponentSubmodifierInCompitems "function: setComponentSubmodifierInCompitems
  
   Helperfunction to set_component_submodifier_in_element
   
   inputs:  (Absyn.ComponentItem list,
               Absyn.Ident, /* component name */
               Absyn.ComponentRef, /* submodifier path */
               Absyn.Modification)
   outputs: (Absyn.ComponentItem list)
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst,inIdent,inComponentRef,inModification)
    local
      list<Absyn.ElementArg> args_1,args;
      Option<Absyn.Modification> optmod;
      String id,varname;
      list<Absyn.Subscript> dim;
      Option<Absyn.Exp> expopt,cond;
      Option<Absyn.Comment> cmt;
      list<Absyn.ComponentItem> rest,res;
      Absyn.ComponentRef submodpath,submod,submodident;
      Absyn.Modification mod;
      Absyn.ComponentItem comp;
    case ({},_,_,_) then {}; 
      
      // remove modifier.
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(args,expopt))),condition = cond,comment = cmt) :: rest),varname,Absyn.CREF_IDENT("",{}),mod)
      equation 
        equality(varname = id);
        optmod = createOptModificationFromEltargs(args,NONE);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,optmod),cond,cmt) :: rest);
        
       // remove modifier.
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE),condition = cond,comment = cmt) :: rest),varname,Absyn.CREF_IDENT("",{}),mod)
      equation 
        equality(varname = id);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,NONE),cond,cmt) :: rest);
        
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(args,expopt))),condition = cond,comment = cmt) :: rest),varname,submodpath,mod)
      equation 
        equality(varname = id);
        args_1 = setSubmodifierInElementargs(args, submodpath, mod);
        optmod = createOptModificationFromEltargs(args_1,expopt);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,optmod),cond,cmt) :: rest);
        
        case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE),condition = cond,comment = cmt) :: rest),varname,submod,Absyn.CLASSMOD({},NONE))
      equation 
        equality(varname = id);
      then
        (Absyn.COMPONENTITEM(
          Absyn.COMPONENT(id,dim,NONE),cond,cmt) :: rest);
          
        
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE),condition = cond,comment = cmt) :: rest),varname,submod,mod)
      equation 
        equality(varname = id);
      then
        (Absyn.COMPONENTITEM(
          Absyn.COMPONENT(id,dim,
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),submod,SOME(mod),NONE)},NONE))),cond,cmt) :: rest);
    case ((comp :: rest),varname,submodident,mod)
      equation 
        res = setComponentSubmodifierInCompitems(rest, varname, submodident, mod);
      then
        (comp :: res);
    case (_,_,_,_)
      equation 
        print("-set_component_submodifier_in_compitems failed\n");
      then
        fail();
  end matchcontinue;
end setComponentSubmodifierInCompitems;

protected function createOptModificationFromEltargs "function: createOptModificationFromEltargs
 
  Creates an Modification option from an ElementArg list.
  If list is empty, NONE is created.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Option<Absyn.Exp> inExpOpt;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  outAbsynModificationOption:=
  matchcontinue (inAbsynElementArgLst,inExpOpt)
    local 
      list<Absyn.ElementArg> args;
      Option<Absyn.Exp> expOpt;
      Absyn.Exp e;
    case({},SOME(e)) then SOME(Absyn.CLASSMOD({},SOME(e)));
    case ({},_) then NONE; 
    case (args,expOpt) then SOME(Absyn.CLASSMOD(args,expOpt)); 
  end matchcontinue;
end createOptModificationFromEltargs;

protected function setSubmodifierInElementargs "function: setSubmodifierInElementargs
  
   Helperfunction to set_component_submodifier_in_compitems
   
   inputs:  (Absyn.ElementArg list,
               Absyn.ComponentRef, /* subcomponent name */
               Absyn.Modification)
   outputs:  Absyn.ElementArg list
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Modification inModification;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementArgLst,inComponentRef,inModification)
    local
      Absyn.ComponentRef cref,cr1,cr2,cr;
      Absyn.Modification mod;
      Option<Absyn.Modification> mod2,modM;
      Boolean f;
      Absyn.Each each_;
      String name,submodident,name1,name2;
      list<Absyn.Subscript> idx;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args_1,args,res,submods;
      Option<Absyn.Exp> exp;
      Absyn.Exp e;
      Absyn.ElementArg m;
  	case ({},cref,Absyn.CLASSMOD({},NONE)) then {}; // Empty modification.
    case ({},cref,mod) then {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),cref,SOME(mod),NONE)};  
          
       //Clear modification m(...) 
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = (cr as Absyn.CREF_IDENT(name = name,subscripts = idx)),comment = cmt,modification=SOME(Absyn.CLASSMOD((submods as _::_),_))) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD( {}, NONE)))  
      equation 
        equality(name = submodident);
      then
        Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD(submods,NONE)),cmt)::rest;
        
        //Clear modification, m with no submodifiers
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_IDENT(name = name,subscripts = idx),comment = cmt,modification=SOME(Absyn.CLASSMOD({},_))) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD( {}, NONE)))  
      equation 
        equality(name = submodident);
      then
        rest;
        // modfication, m=e
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_IDENT(name = name,subscripts = idx),modification=SOME(Absyn.CLASSMOD(submods,_)),comment = cmt) :: rest),Absyn.CREF_IDENT(name = submodident),(mod as Absyn.CLASSMOD({},SOME(e)))) /* update modification */ 
      equation 
        equality(name = submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.CREF_IDENT(name,idx),SOME(Absyn.CLASSMOD(submods,SOME(e))),cmt) :: rest);
        
        // modfication, m(...)=e
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_IDENT(name = name,subscripts = idx),modification=mod2,comment = cmt) :: rest),Absyn.CREF_IDENT(name = submodident),mod) /* update modification */ 
      equation 
        equality(name = submodident);
      then
        (Absyn.MODIFICATION(f,each_,Absyn.CREF_IDENT(name,idx),SOME(mod),cmt) :: rest);

    // Clear modification, m.n
     case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = (cr1 as Absyn.CREF_QUAL(name = _)),comment = cmt) :: rest),cr2,Absyn.CLASSMOD({},NONE))
      equation 
        true = Absyn.crefEqual(cr1, cr2);
      then
        (rest);

     //Clear modification m.n first part matches. Check that m is not present in rest of list.
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_QUAL(name = name1),comment = cmt) :: rest),cr as Absyn.CREF_IDENT(name = name2,subscripts = idx),Absyn.CLASSMOD({},NONE))
      equation 
        equality(name1 = name2);
        false = findCrefModification(cr,rest);
      then
        (rest);
        
   // Clear modification m(...)
   case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,NONE)),comment = cmt) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),Absyn.CLASSMOD({},NONE))
      equation 
        equality(name1 = name2);
        {} = setSubmodifierInElementargs(args, cr1, Absyn.CLASSMOD({},NONE));
      then
        (Absyn.MODIFICATION(f,each_,cr,NONE,cmt) :: rest);
   
   // Clear modification m(...)=expr
   case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,SOME(e))),comment = cmt) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),Absyn.CLASSMOD({},NONE))
      equation 
        equality(name1 = name2);
        {} = setSubmodifierInElementargs(args, cr1, Absyn.CLASSMOD({},NONE));
      then
        (Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD({},SOME(e))),cmt) :: rest);
   
        // modification, m for m.n
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = (cr as Absyn.CREF_IDENT(name = name2)),modification = SOME(Absyn.CLASSMOD(args,exp)),comment = cmt) :: rest),Absyn.CREF_QUAL(name = name1,componentRef = cr1),mod)
      equation 
        equality(name1 = name2);
        args_1 = setSubmodifierInElementargs(args, cr1, mod);
      then
        (Absyn.MODIFICATION(f,each_,cr,SOME(Absyn.CLASSMOD(args_1,exp)),cmt) :: rest);
        
        // next element
    case ((m :: rest),submodident,mod)
      local Absyn.ComponentRef submodident;
      equation 
        res = setSubmodifierInElementargs(rest, submodident, mod);
      then
        (m :: res); 
    case (_,_,_)
      equation 
        print("-set_submodifier_in_elementargs failed\n");
      then
        fail();
  end matchcontinue;
end setSubmodifierInElementargs;

protected function findCrefModification
  input Absyn.ComponentRef cr;
  input list<Absyn.ElementArg> rest;
  output Boolean found;
algorithm
  
  found := matchcontinue(cr,rest)
    local Absyn.ComponentRef cr2;		  
    case (cr,Absyn.MODIFICATION(componentReg = cr2)::_) 
      equation
        true = Absyn.crefEqual(cr,cr2); then true;
    case (cr,_::rest) then findCrefModification(cr,rest);
    case (cr,{}) then false;
  end matchcontinue;
end findCrefModification;

protected function getComponentModifierValue "function: getComponentModifierValue(class,ident,subident,p) => resstr 
  
   Returns the modifier value of component ident for modifier subident.
   For instance, 
   model A
    B b1(a1(p1=0,p2=0));
  end A;
   getComponentModifierValues(A,b1,a1) => Code((p1=0,p2=0))
  
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* variable name */
               Absyn.ComponentRef, /* submodifier name */
               Absyn.Program)
   outputs: string
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.Modification mod;
      Absyn.ComponentRef class_,ident,subident;
      Absyn.Program p;
    case (class_,ident,subident,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = Util.listMap(comps, getComponentitemsInElement);
        compelts_1 = Util.listFlatten(compelts);
        {Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,SOME(Absyn.CLASSMOD(mod,_))),_,_)} = Util.listSelect1(compelts_1, name, componentitemNamed);
        mod = getModificationValue(mod, subident);
        res = Dump.unparseModificationStr(mod);
      then
        res;
    case (_,_,_,_) then "Error"; 
  end matchcontinue;
end getComponentModifierValue;

public function getModificationValue "function: getModificationValue
  
   Helperfunction to get_component_modifier_value
   Investigates modifications to find submodifier.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  output Absyn.Modification outModification;
algorithm 
  outModification:=
  matchcontinue (inAbsynElementArgLst,inComponentRef)
    local
      Boolean f;
      Absyn.Each each_;
      Absyn.ComponentRef cr1,cr2,name;
      Absyn.Modification mod,res;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      String name1,name2;
      Option<Absyn.Exp> exp;
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = cr1,modification = SOME(mod),comment = cmt) :: rest),cr2)
      equation 
        true = Absyn.crefEqual(cr1, cr2);
      then
        mod;
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_IDENT(name = name1),modification = SOME(Absyn.CLASSMOD(args,exp)),comment = cmt) :: rest),Absyn.CREF_QUAL(name = name2,componentRef = cr2))
      equation 
        equality(name1 = name2);
        res = getModificationValue(args, cr2);
      then
        res;
    case ((_ :: rest),name)
      equation 
        mod = getModificationValue(rest, name);
      then
        mod;
  end matchcontinue;
end getModificationValue;

protected function getComponentModifierNames "function: getComponentModifierNames
  
   Return the modifiernames of a component, i.e. Foo f( )
  
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* variable name */
               Absyn.Program) 
   outputs:  string
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res_1,res_2;
      Absyn.Class cdef;
      list<Absyn.Element> comps;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      list<Absyn.ElementArg> mod;
      list<String> res;
      Absyn.ComponentRef class_,ident;
      Absyn.Program p;
    case (class_,ident,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(ident);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = Util.listMap(comps, getComponentitemsInElement);
        compelts_1 = Util.listFlatten(compelts);
        {Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,SOME(Absyn.CLASSMOD(mod,_))),_,_)} = Util.listSelect1(compelts_1, name, componentitemNamed);
        res = getModificationNames(mod);
        res_1 = Util.stringDelimitList(res, ", ");
        res_2 = Util.stringAppendList({"{",res_1,"}"});
      then
        res_2;
    case (_,_,_) then "{}"; 
  end matchcontinue;
end getComponentModifierNames;

protected function getModificationNames "function: getModificationNames
 
  Helperfunction to get_component_modifier_names
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<String> names,names2,names2_1,names2_2,res;
      Boolean f;
      Absyn.Each each_;
      String name;
      Option<String> cmt;
      list<Absyn.ElementArg> rest,args;
      Absyn.ComponentRef cr;
    case ({}) then {}; 
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = Absyn.CREF_IDENT(name = name),modification = NONE,comment = cmt) :: rest))
      equation 
        names = getModificationNames(rest);
      then
        (name :: names);
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = cr,modification = SOME(Absyn.CLASSMOD({},_)),comment = cmt) :: rest))
      equation 
        name = Dump.printComponentRefStr(cr);
        names = getModificationNames(rest);
      then
        (name :: names);
        // modifier with submodifiers -and- binding, e.g. m(...)=2, add also m to list
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = cr,modification = SOME(Absyn.CLASSMOD(args,SOME(_))),comment = cmt) :: rest))
      equation 
        name = Dump.printComponentRefStr(cr);
        names2 = getModificationNames(args);
        names2_1 = Util.listMap1r(names2, string_append, ".");
        names2_2 = Util.listMap1r(names2_1, string_append, name);
        names = getModificationNames(rest);
        res = listAppend(names2_2, names);
      then
        name::res;
      // modifier with submodifiers, e.g. m(...)  
    case ((Absyn.MODIFICATION(finalItem = f,each_ = each_,componentReg = cr,modification = SOME(Absyn.CLASSMOD(args,_)),comment = cmt) :: rest))
      equation 
        name = Dump.printComponentRefStr(cr);
        names2 = getModificationNames(args);
        names2_1 = Util.listMap1r(names2, string_append, ".");
        names2_2 = Util.listMap1r(names2_1, string_append, name);
        names = getModificationNames(rest);
        res = listAppend(names2_2, names);
      then
        res;
    case ((_ :: rest))
      equation 
        names = getModificationNames(rest);
      then
        names;
  end matchcontinue;
end getModificationNames;

protected function getComponentBinding "function: getComponentBinding
  
   Returns the value of a component in a class.
   
   For example, the component
   Real x=1; 
   returns 1.
  This can be used for both parameters, constants and variables.
  
   inputs: (Absyn.ComponentRef, /* class */
              Absyn.ComponentRef, /* variable name */
              Absyn.Program)
   outputs: string
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path p_class;
      String name,res;
      Absyn.Class cdef;
      list<Absyn.Element> comps,comps_1;
      list<list<Absyn.ComponentItem>> compelts;
      list<Absyn.ComponentItem> compelts_1;
      Absyn.ComponentItem compitem;
      Absyn.Exp exp;
      Absyn.ComponentRef class_;
      Absyn.Program p;
    case (class_,name,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(name) = Absyn.crefToPath(name);
        cdef = getPathedClassInProgram(p_class, p);
        comps = getComponentsInClass(cdef);
        compelts = Util.listMap(comps, getComponentitemsInElement);
        compelts_1 = Util.listFlatten(compelts);
        {compitem} = Util.listSelect1(compelts_1, name, componentitemNamed);
        exp = getVariableBindingInComponentitem(compitem);
        res = Dump.printExpStr(exp);
      then
        res;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getComponentBinding;

protected function getVariableBindingInComponentitem "function: get_variable_binding_in_componenitem
  
   Retrieve the variable binding from an ComponentItem
"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentItem)
    local Absyn.Exp e;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(Absyn.CLASSMOD(_,SOME(e)))))) then e; 
  end matchcontinue;
end getVariableBindingInComponentitem;

protected function setParameterValue "function: setParameterValue
  
   Sets the parameter value of a class and returns the updated program.
  
   inputs:  (Absyn.ComponentRef, /* class */
               Absyn.ComponentRef, /* ident */
               Absyn.Exp,          /* exp */
               Absyn.Program) 
   outputs: (Absyn.Program,string) 
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Exp inExp3;
  input Absyn.Program inProgram4;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inExp3,inProgram4)
    local
      Absyn.Path p_class;
      String varname;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,name;
      Absyn.Exp exp;
    case (class_,name,exp,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        Absyn.IDENT(varname) = Absyn.crefToPath(name);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setVariableBindingInClass(cdef, varname, exp);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    case (_,_,_,p) then (p,"Error"); 
  end matchcontinue;
end setParameterValue;

protected function setVariableBindingInClass "function: setVariableBindingInClass
  
   Takes a class and an identifier and value an sets the variable binding to 
   the passed expression.
"
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inIdent,inExp)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String id,id2;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Exp exp;
    case (Absyn.CLASS(name = id,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),id2,exp)
      equation 
        parts_1 = setVariableBindingInClassparts(parts, id2, exp);
      then
        Absyn.CLASS(id,p,f,e,r,Absyn.PARTS(parts_1,cmt),file_info);
  end matchcontinue;
end setVariableBindingInClass;

protected function setVariableBindingInClassparts "function: setVariableBindingInClassparts
  
   Sets a binding of a variable in a ClassPart list, named by the passed 
   argument.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inIdent,inExp)
    local
      list<Absyn.ClassPart> res,rest;
      list<Absyn.ElementItem> elts_1,elts;
      String id;
      Absyn.Exp exp;
      Absyn.ClassPart elt;
    case ({},_,_) then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest),id,exp)
      equation 
        res = setVariableBindingInClassparts(rest, id, exp);
        elts_1 = setVariableBindingInElementitems(elts, id, exp);
      then
        (Absyn.PUBLIC(elts_1) :: res);
    case ((Absyn.PROTECTED(contents = elts) :: rest),id,exp)
      equation 
        res = setVariableBindingInClassparts(rest, id, exp);
        elts_1 = setVariableBindingInElementitems(elts, id, exp);
      then
        (Absyn.PROTECTED(elts_1) :: res);
    case ((elt :: rest),id,exp)
      equation 
        res = setVariableBindingInClassparts(rest, id, exp);
      then
        (elt :: res);
  end matchcontinue;
end setVariableBindingInClassparts;

protected function setVariableBindingInElementitems "function: setVariableBindingInElementitems
  
   Sets a variable binding in a list of ElementItems
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inIdent,inExp)
    local
      list<Absyn.ElementItem> res,rest;
      Absyn.Element elt_1,elt;
      String id;
      Absyn.Exp exp;
    case ({},_,_) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest),id,exp)
      equation 
        res = setVariableBindingInElementitems(rest, id, exp);
        elt_1 = setVariableBindingInElement(elt, id, exp);
      then
        (Absyn.ELEMENTITEM(elt_1) :: res);
    case ((elt :: rest),id,exp)
      local Absyn.ElementItem elt;
      equation 
        res = setVariableBindingInElementitems(rest, id, exp);
      then
        (elt :: res);
  end matchcontinue;
end setVariableBindingInElementitems;

protected function setVariableBindingInElement "function: setVariableBindingInElement
  
   Sets a variable binding in an Element.
"
  input Absyn.Element inElement;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inElement,inIdent,inExp)
    local
      list<Absyn.ComponentItem> compitems_1,compitems;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter i;
      String n,id;
      Absyn.ElementAttributes attr;
      Absyn.Path tp;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Absyn.Exp exp;
      Absyn.Element elt;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = i,name = n,specification = Absyn.COMPONENTS(attributes = attr,typeName = tp,components = compitems),info = info,constrainClass = constr),id,exp)
      equation 
        compitems_1 = setVariableBindingInCompitems(compitems, id, exp);
      then
        Absyn.ELEMENT(f,r,i,n,Absyn.COMPONENTS(attr,tp,compitems_1),info,constr);
    case (elt,id,exp) then elt; 
  end matchcontinue;
end setVariableBindingInElement;

protected function setVariableBindingInCompitems "function: setVariableBindingInCompitems
  
   Sets a variable binding in a ComponentItem list
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.Ident inIdent;
  input Absyn.Exp inExp;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst,inIdent,inExp)
    local
      String id,id2;
      list<Absyn.Subscript> dim;
      list<Absyn.ElementArg> arg;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> cmt;
      list<Absyn.ComponentItem> rest,res;
      Absyn.Exp exp;
      Absyn.ComponentItem item;
    case ({},_,_) then {}; 
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = SOME(Absyn.CLASSMOD(arg,_))),condition = cond,comment = cmt) :: rest),id2,exp)
      equation 
        equality(id = id2);
      then
        (Absyn.COMPONENTITEM(
          Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD(arg,SOME(exp)))),cond,cmt) :: rest);
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = dim,modification = NONE),condition = cond,comment = cmt) :: rest),id2,exp)
      equation 
        equality(id = id2);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,dim,SOME(Absyn.CLASSMOD({},SOME(exp)))),
          cond,cmt) :: rest);
    case ((item :: rest),id,exp)
      equation 
        res = setVariableBindingInCompitems(rest, id, exp);
      then
        (item :: res);
  end matchcontinue;
end setVariableBindingInCompitems;

public function buildWithin "function: buildWithin
  
   From a fully qualified model name, build a suitable within clause
"
  input Absyn.Path inPath;
  output Absyn.Within outWithin;
algorithm 
  outWithin:=
  matchcontinue (inPath)
    local Absyn.Path w_path,path;
    case (Absyn.IDENT(name = _)) then Absyn.TOP(); 
    case (path)
      equation 
        w_path = Absyn.stripLast(path);
      then
        Absyn.WITHIN(w_path);
  end matchcontinue;
end buildWithin;

protected function componentitemNamed "function: componentitemNamed
  
   Returns true if the component item has the name matching the second 
   argument.
"
  input Absyn.ComponentItem inComponentItem;
  input Absyn.Ident inIdent;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentItem,inIdent)
    local String id,id2;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)),id2)
      equation 
        equality(id = id2);
      then
        true;
    case (_,_) then false; 
  end matchcontinue;
end componentitemNamed;

protected function getComponentitemName "function: getComponentitemName
  
   Returns the name of a ComponentItem
"
  input Absyn.ComponentItem inComponentItem;
  output Absyn.Ident outIdent;
algorithm 
  outIdent:=
  matchcontinue (inComponentItem)
    local String id;
    case (Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id))) then id; 
  end matchcontinue;
end getComponentitemName;

protected function getComponentitemsInElement "function: getComponentitemsInElement
  
   Retrieves the ComponentItems of a component Element.
   If Element is not a component, empty list is returned.
"
  input Absyn.Element inElement;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inElement)
    local list<Absyn.ComponentItem> l;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = l))) then l; 
    case (_) then {}; 
  end matchcontinue;
end getComponentitemsInElement;

protected function renameClass "function: renameClass
  
   Thisfunction renames a class (given as a qualified path name) to a 
   new name -in the same scope-. All references to the class name in the
   program is updated to the new name. Thefunction does not allow a 
   renaming that will move the class to antoher package. To do this, the 
   class must be copied.
  
   inputs:  (Absyn.Program, 
               Absyn.ComponentRef, /* old class as qualified name A.B.C */
               Absyn.ComponentRef) /* new class, as identifier D */
   outputs:  Absyn.Program
"
  input Absyn.Program inProgram1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inProgram1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path new_path,old_path,new_path_1,old_path_no_last;
      String tmp_str,path_str_lst_no_empty,res;
      Absyn.Program p,p_1;
      Absyn.ComponentRef old_class,new_name;
      list<SCode.Class> pa_1;
      list<Env.Frame> env;
      list<String> path_str_lst;
    case (p,old_class,(new_name as Absyn.CREF_QUAL(name = _)))
      equation 
        new_path = Absyn.crefToPath(new_name) "class in package" ;
        tmp_str = Absyn.pathString(new_path);
        print(tmp_str);
        print("\n") "the path is qualified so it cannot be renamed" ;
      then
        ("error",p);
    case (p,(old_class as Absyn.CREF_IDENT(name = _)),new_name)
      equation 
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path = Absyn.crefToPath(new_name);
        pa_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,pa_1, Absyn.IDENT(""));
        ((p_1,_,(_,_,_,path_str_lst,_))) = traverseClasses(p, NONE, renameClassVisitor, (old_path,new_path,p,{},env), 
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNoEmpty(path_str_lst, ",");
        res = Util.stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
    case (p,(old_class as Absyn.CREF_QUAL(name = _)),new_name)
      equation 
        old_path = Absyn.crefToPath(old_class) "class in package" ;
        new_path_1 = Absyn.crefToPath(new_name);
        old_path_no_last = Absyn.stripLast(old_path);
        new_path = Absyn.joinPaths(old_path_no_last, new_path_1);
        pa_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,pa_1, Absyn.IDENT(""));
        ((p_1,_,(_,_,_,path_str_lst,_))) = traverseClasses(p, NONE, renameClassVisitor, (old_path,new_path,p,{},env), 
          true) "traverse protected" ;
        path_str_lst_no_empty = Util.stringDelimitListNoEmpty(path_str_lst, ",");
        res = Util.stringAppendList({"{",path_str_lst_no_empty,"}"});
      then
        (res,p_1);
  end matchcontinue;
end renameClass;

protected function renameClassVisitor "function: renameClassVisitor
  
   This visitor renames a class given a new name
"
  input tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, Env.Env>> inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
  output tuple<Absyn.Class, Option<Absyn.Path>, tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, Env.Env>> outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv;
algorithm 
  outTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv:=
  matchcontinue (inTplAbsynClassAbsynPathOptionTplAbsynPathAbsynPathAbsynProgramStringLstEnvEnv)
    local
      Absyn.Path path_1,pa,old_class_path,new_class_path;
      String new_name,path_str,id,path_str_1;
      Boolean a,b,c,changed;
      Absyn.Restriction d;
      Absyn.ClassDef e;
      Absyn.Info file_info;
      Absyn.Program p;
      list<String> path_str_lst;
      list<Env.Frame> env,cenv;
      Absyn.Class class_1,class_;
      tuple<Absyn.Path, Absyn.Path, Absyn.Program, list<String>, list<Env.Frame>> args;
    case ((Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation 
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        true = ModUtil.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    case ((Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info),NONE,(old_class_path,new_class_path,p,path_str_lst,env)))
      equation 
        path_1 = Absyn.IDENT(id);
        true = ModUtil.pathEqual(old_class_path, path_1);
        new_name = Absyn.pathLastIdent(new_class_path);
        path_str = Absyn.pathString(new_class_path);
      then
        ((Absyn.CLASS(new_name,a,b,c,d,e,file_info),NONE,
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),SOME(pa),(old_class_path,new_class_path,p,path_str_lst,env)))
      equation 
        path_1 = Absyn.joinPaths(pa, Absyn.IDENT(id));
        cenv = getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str_1 = Absyn.pathString(path_1);
        path_str = Util.if_(changed, path_str_1, "");
      then
        ((class_1,SOME(pa),
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    case (((class_ as Absyn.CLASS(name = id,partial_ = a,final_ = b,encapsulated_ = c,restricion = d,body = e,info = file_info)),NONE,(old_class_path,new_class_path,p,path_str_lst,env)))
      equation 
        path_1 = Absyn.IDENT(id);
        cenv = getClassEnvNoElaboration(p, path_1, env) "get_class_env(p,path\') => cenv &" ;
        (class_1,changed) = renameClassInClass(class_, old_class_path, new_class_path, cenv);
        path_str_1 = Absyn.pathString(path_1);
        path_str = Util.if_(changed, path_str_1, "");
      then
        ((class_1,NONE,
          (old_class_path,new_class_path,p,(path_str :: path_str_lst),
          env)));
    case ((class_,pa,args))
      local Option<Absyn.Path> pa;
      then
        ((class_,pa,args));
  end matchcontinue;
end renameClassVisitor;

protected function renameClassInClass "
  author: x02lucpo
 
  helper function to rename_class_visitor
  renames all the references to a class to another
"
  input Absyn.Class inClass1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.Class outClass;
  output Boolean outBoolean;
algorithm 
  (outClass,outBoolean):=
  matchcontinue (inClass1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      Boolean changed,partial_,final_,encapsulated_;
      String id;
      Absyn.Restriction restriction;
      Option<String> a,c;
      Absyn.Info file_info;
      Absyn.Path old_comp,new_comp,path_1,path,new_path;
      list<Env.Frame> env,cenv;
      list<Absyn.ElementArg> b,elementarg;
      Option<Absyn.Comment> co;
      Absyn.Class class_;
    case (Absyn.CLASS(name = id,partial_ = partial_,final_ = final_,encapsulated_ = encapsulated_,restricion = restriction,body = Absyn.PARTS(classParts = parts,comment = a),info = file_info),old_comp,new_comp,env) /* the class with the component the old name for the component signal if something in class have been changed */ 
      equation 
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(id,partial_,final_,encapsulated_,restriction,
          Absyn.PARTS(parts_1,a),file_info),changed);
    case (Absyn.CLASS(name = id,partial_ = partial_,final_ = final_,encapsulated_ = encapsulated_,restricion = restriction,body = Absyn.CLASS_EXTENDS(name = a,arguments = b,comment = c,parts = parts),info = file_info),old_comp,new_comp,env)
      local String a;
      equation 
        (parts_1,changed) = renameClassInParts(parts, old_comp, new_comp, env);
      then
        (Absyn.CLASS(id,partial_,final_,encapsulated_,restriction,
          Absyn.CLASS_EXTENDS(a,b,c,parts_1),file_info),changed);
    case (Absyn.CLASS(name = id,partial_ = partial_,final_ = final_,encapsulated_ = encapsulated_,restricion = restriction,body = Absyn.DERIVED(path = path_1,arrayDim = a,attributes = b,arguments = elementarg,comment = co),info = file_info),old_comp,new_comp,env)
      local
        Option<list<Absyn.Subscript>> a;
        Absyn.ElementAttributes b;
      equation 
        (_,SCode.CLASS(id,_,_,_,_),cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        path_1 = Absyn.IDENT(id);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.CLASS(id,partial_,final_,encapsulated_,restriction,
          Absyn.DERIVED(new_path,a,b,elementarg,co),file_info),true);
    case (class_,old_comp,new_comp,env) then (class_,false); 
  end matchcontinue;
end renameClassInClass;

protected function renameClassInParts "
  author: x02lucpo
 
  helper function to rename_class_visitor
"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
  output Boolean outBoolean;
algorithm 
  (outAbsynClassPartLst,outBoolean):=
  matchcontinue (inAbsynClassPartLst1,inPath2,inPath3,inEnv4)
    local
      list<Env.Frame> env;
      list<Absyn.ClassPart> res_1,res;
      Boolean changed1,changed2,changed;
      list<Absyn.ElementItem> elements_1,elements;
      Absyn.Path old_comp,new_comp;
      Absyn.ClassPart a;
    case ({},_,_,env) then ({},false);  /* the old name for the component signal if something in class have been changed rule  Absyn.path_string(old_comp) => old_str & Absyn.path_string(new_comp) => new_str & Util.string_append_list({old_str,\" => \", new_str,\"\\n\"}) => print_str & print print_str & int_eq(1,2) => true --------- rename_class_in_parts(_,old_comp,new_comp,env) => ({},false) */ 
    case ((Absyn.PUBLIC(contents = elements) :: res),old_comp,new_comp,env)
      equation 
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = Util.boolOrList({changed1,changed2});
      then
        ((Absyn.PUBLIC(elements_1) :: res_1),changed);
    case ((Absyn.PROTECTED(contents = elements) :: res),old_comp,new_comp,env)
      equation 
        (res_1,changed1) = renameClassInParts(res, old_comp, new_comp, env);
        (elements_1,changed2) = renameClassInElements(elements, old_comp, new_comp, env);
        changed = Util.boolOrList({changed1,changed2});
      then
        ((Absyn.PROTECTED(elements_1) :: res_1),changed);
    case ((a :: res),old_comp,new_comp,env)
      equation 
        (res_1,changed) = renameClassInParts(res, old_comp, new_comp, env);
      then
        ((a :: res_1),changed);
  end matchcontinue;
end renameClassInParts;

protected function renameClassInElements "
  author: x02lucpo
 
  helper function to rename_class_visitor
"
  input list<Absyn.ElementItem> inAbsynElementItemLst1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
  output Boolean outBoolean;
algorithm 
  (outAbsynElementItemLst,outBoolean):=
  matchcontinue (inAbsynElementItemLst1,inPath2,inPath3,inEnv4)
    local
      list<Absyn.ElementItem> res_1,res;
      Boolean changed1,changed2,changed,final_;
      Absyn.ElementSpec elementspec_1,elementspec;
      Absyn.ElementItem element_1,element;
      Option<Absyn.RedeclareKeywords> redeclare_;
      Absyn.InnerOuter inner_outer;
      String name;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constraint;
      Absyn.Path old_comp,new_comp;
      list<Env.Frame> env;
    case ({},_,_,_) then ({},false);  /* the old name for the component signal if something in class have been changed */ 
    case (((element as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = final_,redeclareKeywords = redeclare_,innerOuter = inner_outer,name = name,specification = elementspec,info = info,constrainClass = constraint))) :: res),old_comp,new_comp,env)
      equation 
        (res_1,changed1) = renameClassInElements(res, old_comp, new_comp, env);
        (elementspec_1,changed2) = renameClassInElementSpec(elementspec, old_comp, new_comp, env);
        element_1 = Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,redeclare_,inner_outer,name,elementspec_1,info,
          constraint));
        changed = Util.boolOrList({changed1,changed2});
      then
        ((element_1 :: res_1),changed);
    case ((element :: res),old_comp,new_comp,env)
      equation 
        (res_1,changed) = renameClassInElements(res, old_comp, new_comp, env);
        element_1 = element;
      then
        ((element_1 :: res_1),changed);
  end matchcontinue;
end renameClassInElements;

protected function renameClassInElementSpec "
  author: x02lucpo
 
  helper function to rename_class_visitor
"
  input Absyn.ElementSpec inElementSpec1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.ElementSpec outElementSpec;
  output Boolean outBoolean;
algorithm 
  (outElementSpec,outBoolean):=
  matchcontinue (inElementSpec1,inPath2,inPath3,inEnv4)
    local
      String id;
      list<Env.Frame> cenv,env;
      Absyn.Path path_1,path,new_path,old_comp,new_comp,comps;
      Absyn.ElementAttributes a;
      list<Absyn.ComponentItem> comp_items;
      Absyn.Import import_1,import_;
      Boolean changed;
    case (Absyn.COMPONENTS(attributes = a,typeName = path_1,components = comp_items),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed rule  Absyn.path_string(old_comp) => old_str & Absyn.path_string(new_comp) => new_str & Util.string_append_list({old_str,\" ==> \", new_str,\"\\n\"}) => print_str & print print_str & int_eq(1,2) => true --------- rename_class_in_element_spec(A,old_comp,new_comp,env) => (A,false) */ 
      equation 
        (_,SCode.CLASS(id,_,_,_,_),cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        path_1 = Absyn.IDENT(id);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path, new_comp) "& Absyn.path_string(path) => old_str & Absyn.path_string(new_comp) => new_str & Absyn.path_string(new_path) => new2_str & Util.string_append_list({old_str,\" =E=> \", new_str,\" \",new2_str ,\"\\n\"}) => print_str & print print_str &" ;
      then
        (Absyn.COMPONENTS(a,new_path,comp_items),true);
    case (Absyn.EXTENDS(path = path_1,elementArg = a),old_comp,new_comp,env)
      local list<Absyn.ElementArg> a;
      equation 
        (_,_,cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false) "print \"rename_class_in_element_spec Absyn.EXTENDS(path,_) not implemented yet\"" ;
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.EXTENDS(new_path,a),true);
    case (Absyn.IMPORT(import_ = import_,comment = a),old_comp,new_comp,env)
      local Option<Absyn.Comment> a;
      equation 
        (import_1,changed) = renameClassInImport(import_, old_comp, new_comp, env) "print \"rename_class_in_element_spec Absyn.EXTENDS(path,_) not implemented yet\"" ;
      then
        (Absyn.IMPORT(import_1,a),changed);
    case (a,_,comps,env)
      local Absyn.ElementSpec a;
      then
        (a,false);
  end matchcontinue;
end renameClassInElementSpec;

protected function renameClassInImport "
  author: x02lucpo
 
  helper function to rename_class_visitor
"
  input Absyn.Import inImport1;
  input Absyn.Path inPath2;
  input Absyn.Path inPath3;
  input Env.Env inEnv4;
  output Absyn.Import outImport;
  output Boolean outBoolean;
algorithm 
  (outImport,outBoolean):=
  matchcontinue (inImport1,inPath2,inPath3,inEnv4)
    local
      list<Env.Frame> cenv,env;
      Absyn.Path path,new_path,path_1,old_comp,new_comp;
      String id;
      Absyn.Import import_;
    case (Absyn.NAMED_IMPORT(name = id,path = path_1),old_comp,new_comp,env) /* the old name for the component signal if something in class have been changed */ 
      equation 
        (_,_,cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.NAMED_IMPORT(id,new_path),true);
    case (Absyn.QUAL_IMPORT(path = path_1),old_comp,new_comp,env)
      equation 
        (_,_,cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.QUAL_IMPORT(new_path),true);
    case (Absyn.NAMED_IMPORT(name = id,path = path_1),old_comp,new_comp,env)
      equation 
        (_,_,cenv) = Lookup.lookupClass(Env.emptyCache,env, path_1, false);
        (_,path) = Inst.makeFullyQualified(Env.emptyCache,cenv, path_1);
        true = ModUtil.pathEqual(path, old_comp);
        new_path = changeLastIdent(path_1, new_comp);
      then
        (Absyn.UNQUAL_IMPORT(new_path),true);
    case (import_,old_comp,new_comp,env) then (import_,false); 
  end matchcontinue;
end renameClassInImport;

protected function changeLastIdent "function changeLastIdent
  author: x02lucpo
 
  chages the last ident of the first path to the last path ident ie:
  (A.B.CC,C.DD) => (A.B.DD)
"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  output Absyn.Path outPath;
algorithm 
  outPath:=
  matchcontinue (inPath1,inPath2)
    local
      String a,b,b_1;
      Absyn.Path a_1,res;
    case (Absyn.IDENT(name = a),Absyn.IDENT(name = b)) then Absyn.IDENT(b); 
    case ((a as Absyn.IDENT(name = _)),(b as Absyn.QUALIFIED(name = _)))
      local Absyn.Path a,b;
      equation 
        b_1 = Absyn.pathLastIdent(b);
      then
        Absyn.IDENT(b_1);
    case ((a as Absyn.QUALIFIED(name = _)),(b as Absyn.IDENT(name = _)))
      local Absyn.Path a,b;
      equation 
        a_1 = Absyn.stripLast(a);
        res = Absyn.joinPaths(a_1, b);
      then
        res;
    case ((a as Absyn.QUALIFIED(name = _)),(b as Absyn.QUALIFIED(name = _)))
      local Absyn.Path a,b;
      equation 
        a_1 = Absyn.stripLast(a);
        b_1 = Absyn.pathLastIdent(b);
        res = Absyn.joinPaths(a_1, Absyn.IDENT(b_1));
      then
        res;
  end matchcontinue;
end changeLastIdent;

public function traverseClasses "function: traverseClasses
   
   Thisfunction traverses all classes of a program and applies afunction 
   to each class. Thefunction takes the Absyn.Class, Absyn.Path option 
   and an additional argument and returns an updated class and the 
   additional values. The Absyn.Path option contains the path to the class
   that is traversed.
  
   inputs:  (Absyn.Program, 
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option  \'a)),  /* rel-ation to apply */
			      \'a, /* extra value passed to re-lation */
			      bool) /* true = traverse protected elements */
   outputs: (Absyn.Program   Absyn.Path option  \'a)
"
  input Absyn.Program inProgram;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<Absyn.Program, Option<Absyn.Path>, Type_a> outTplAbsynProgramAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynProgramAbsynPathOptionTypeA:=
  matchcontinue (inProgram,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      list<Absyn.Class> lst_1,lst;
      Option<Absyn.Path> pa_1,pa;
      Type_a args_1,args;
      Absyn.Within within_;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Boolean traverse_prot;
    case (Absyn.PROGRAM(classes = lst,within_ = within_),pa,visitor,args,traverse_prot)
      equation 
        ((lst_1,pa_1,args_1)) = traverseClasses2(lst, pa, visitor, args, traverse_prot);
      then
        ((Absyn.PROGRAM(lst_1,within_),pa_1,args_1));
  end matchcontinue;
end traverseClasses;

protected function traverseClasses2 "function: traverseClasses2
  
   Helperfunction to traverse_classes.
  
   inputs: (Absyn.Class list,
              Absyn.Path option,
              ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class   Absyn.Path option \'a)),  /* rel-ation to apply */
	   \'a, /* extra value passed to re-lation */
	   bool) /* true = traverse protected elements */
   outputs: (Absyn.Class list  Absyn.Path option  \'a)
"
  input list<Absyn.Class> inAbsynClassLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<list<Absyn.Class>, Option<Absyn.Path>, Type_a> outTplAbsynClassLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynClassLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynClassLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2,pa_3;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Type_a args,args_1,args_2,args_3;
      Absyn.Class class_1,class_2,class_;
      list<Absyn.Class> classes_1,classes;
      Boolean traverse_prot;
    case ({},pa,visitor,args,_) then (({},pa,args)); 
    case ((class_ :: classes),pa,visitor,args,traverse_prot)
      equation 
        ((class_1,pa_1,args_1)) = visitor((class_,pa,args));
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, traverse_prot);
        ((classes_1,pa_3,args_3)) = traverseClasses2(classes, pa, visitor, args_2, traverse_prot);
      then
        (((class_2 :: classes_1),pa_3,args_3));
    case (_,_,_,_,_)
      equation 
        print("-traverse_classes2 failed\n");
      then
        fail();
  end matchcontinue;
end traverseClasses2;

protected function traverseInnerClass "function: traverseInnerClass
  
   Helperfunction to traverse_classes2. Thisfunction traverses all 
   inner classes of a class.
   
   inputs:  (Absyn.Class, /* class to traverse inner classes in */
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class   Absyn.Path option \'a)), /* visitor rlation */
               \'a /* extra argument */,
               bool ) /* true = traverse protected elts */
   outputs: (Absyn.Class  Absyn.Path option  \'a)
"
  input Absyn.Class inClass;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynClassAbsynPathOptionTypeA:=
  matchcontinue (inClass,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Absyn.Path tmp_pa,pa;
      list<Absyn.ClassPart> parts_1,parts;
      Option<Absyn.Path> pa_1;
      Type_a args_1,args;
      String name;
      Boolean p,f,e,visit_prot;
      Absyn.Restriction r;
      Option<String> str_opt;
      Absyn.Info file_info;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.Class cl;
    case (Absyn.CLASS(name = name,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = str_opt),info = file_info),SOME(pa),visitor,args,visit_prot)
      equation 
        tmp_pa = Absyn.joinPaths(pa, Absyn.IDENT(name));
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(tmp_pa), visitor, args, visit_prot);
      then
        ((
          Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(parts_1,str_opt),file_info),pa_1,args_1));
    case (Absyn.CLASS(name = name,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = str_opt),info = file_info),NONE,visitor,args,visit_prot)
      equation 
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, SOME(Absyn.IDENT(name)), visitor, args, visit_prot);
      then
        ((
          Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(parts_1,str_opt),file_info),pa_1,args_1));
    case (Absyn.CLASS(name = name,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = str_opt),info = file_info),pa,visitor,args,visit_prot)
      local Option<Absyn.Path> pa;
      equation 
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa, visitor, args, visit_prot);
      then
        ((
          Absyn.CLASS(name,p,f,e,r,Absyn.PARTS(parts_1,str_opt),file_info),pa_1,args_1));
    case (cl,pa,_,args,_)
      local Option<Absyn.Path> pa;
      then
        ((cl,pa,args));
  end matchcontinue;
end traverseInnerClass;

protected function traverseInnerClassParts "function: traverseInnerClassParts
  
   Helperfunction to traverse_inner_class
  
   inputs:  (Absyn.ClassPart list,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class   Absyn.Path option \'a)), /* visitor */
               \'a,
               bool) /* true = visit protected elements */
   outputs: (Absyn.ClassPart list  Absyn.Path option  \'a)
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<list<Absyn.ClassPart>, Option<Absyn.Path>, Type_a> outTplAbsynClassPartLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynClassPartLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynClassPartLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      list<Absyn.ElementItem> elts_1,elts;
      list<Absyn.ClassPart> parts_1,parts;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Boolean visit_prot;
      Absyn.ClassPart part;
    case ({},pa,_,args,_) then (({},pa,args)); 
    case ((Absyn.PUBLIC(contents = elts) :: parts),pa,visitor,args,visit_prot)
      equation 
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, visit_prot);
      then
        (((Absyn.PUBLIC(elts_1) :: parts_1),pa_2,args_2));
    case ((Absyn.PROTECTED(contents = elts) :: parts),pa,visitor,args,true)
      equation 
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, true);
        ((parts_1,pa_2,args_2)) = traverseInnerClassParts(parts, pa, visitor, args_1, true);
      then
        (((Absyn.PROTECTED(elts_1) :: parts_1),pa_2,args_2));
    case ((part :: parts),pa,visitor,args,true)
      equation 
        ((parts_1,pa_1,args_1)) = traverseInnerClassParts(parts, pa, visitor, args, true);
      then
        (((part :: parts_1),pa_1,args_1));
  end matchcontinue;
end traverseInnerClassParts;

protected function traverseInnerClassElements "function traverseInnerClassElements
  
   Helperfunction to traverse_inner_class_parts.
   
   inputs:  (Absyn.ElementItem list,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option  \'a)), /* visitor */
               \'a,
               bool)  /* visit protected elts */
   outputs: (Absyn.ElementItem list  Absyn.Path option  \'a)
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<list<Absyn.ElementItem>, Option<Absyn.Path>, Type_a> outTplAbsynElementItemLstAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynElementItemLstAbsynPathOptionTypeA:=
  matchcontinue (inAbsynElementItemLst,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Option<Absyn.Path> pa,pa_1,pa_2;
      Type_a args,args_1,args_2;
      Absyn.ElementSpec elt_spec_1,elt_spec;
      list<Absyn.ElementItem> elts_1,elts;
      Boolean f,visit_prot;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter io;
      String n;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.ElementItem elt;
    case ({},pa,_,args,_) then (({},pa,args)); 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = io,name = n,specification = elt_spec,info = info,constrainClass = constr)) :: elts),pa,visitor,args,visit_prot)
      equation 
        ((elt_spec_1,pa_1,args_1)) = traverseInnerClassElementspec(elt_spec, pa, visitor, args, visit_prot);
        ((elts_1,pa_2,args_2)) = traverseInnerClassElements(elts, pa, visitor, args_1, visit_prot);
      then
        ((
          (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,io,n,elt_spec_1,info,constr)) :: elts_1),pa_2,args_2));
    case ((elt :: elts),pa,visitor,args,visit_prot)
      equation 
        ((elts_1,pa_1,args_1)) = traverseInnerClassElements(elts, pa, visitor, args, visit_prot);
      then
        (((elt :: elts_1),pa_1,args_1));
  end matchcontinue;
end traverseInnerClassElements;

protected function traverseInnerClassElementspec "function: traverseInnerClassElementspec
  
   Helperfunction to traverse_inner_class_elements
  
   inputs:  (Absyn.ElementSpec,
               Absyn.Path option,
               ((Absyn.Class  Absyn.Path option  \'a) => (Absyn.Class  Absyn.Path option   \'a)), /* visitor */
               \'a,
               bool) /* visit protected elts */
   outputs: (Absyn.ElementSpec  Absyn.Path option  \'a)
"
  input Absyn.ElementSpec inElementSpec;
  input Option<Absyn.Path> inAbsynPathOption;
  input FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA;
  input Type_a inTypeA;
  input Boolean inBoolean;
  output tuple<Absyn.ElementSpec, Option<Absyn.Path>, Type_a> outTplAbsynElementSpecAbsynPathOptionTypeA;
  partial function FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a
    input tuple<Absyn.Class, Option<Absyn.Path>, Type_a> inTplAbsynClassAbsynPathOptionTypeA;
    output tuple<Absyn.Class, Option<Absyn.Path>, Type_a> outTplAbsynClassAbsynPathOptionTypeA;
    replaceable type Type_a;
  end FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a;
  replaceable type Type_a;
algorithm 
  outTplAbsynElementSpecAbsynPathOptionTypeA:=
  matchcontinue (inElementSpec,inAbsynPathOption,inFuncTypeTplAbsynClassAbsynPathOptionTypeAToTplAbsynClassAbsynPathOptionTypeA,inTypeA,inBoolean)
    local
      Absyn.Class class_1,class_2,class_;
      Option<Absyn.Path> pa_1,pa_2,pa;
      Type_a args_1,args_2,args;
      Boolean repl,visit_prot;
      FuncTypeTplAbsyn_ClassAbsyn_PathOptionType_aToTplAbsyn_ClassAbsyn_PathOptionType_a visitor;
      Absyn.ElementSpec elt_spec;
    case (Absyn.CLASSDEF(replaceable_ = repl,class_ = class_),pa,visitor,args,visit_prot)
      equation 
        ((class_1,pa_1,args_1)) = visitor((class_,pa,args));
        ((class_2,pa_2,args_2)) = traverseInnerClass(class_1, pa, visitor, args_1, visit_prot);
      then
        ((Absyn.CLASSDEF(repl,class_2),pa_2,args_2));
    case (elt_spec,pa,_,args,_) then ((elt_spec,pa,args)); 
  end matchcontinue;
end traverseInnerClassElementspec;

public function isPrimitive "function: isPrimitive 
 
  Thisfunction takes a component reference and a program. 
  It returns the true if the refrenced type is a primitive type, otherwise 
  it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.Class class_;
      Boolean res;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        class_ = getPathedClassInProgram(path, p);
        res = isPrimitiveClass(class_, p);
      then
        res;
    case (Absyn.CREF_IDENT(name = "Real"),_) then true;  /* Instead of elaborating and lookup these in env, we optimize a bit and just return true for these */ 
    case (Absyn.CREF_IDENT(name = "Integer"),_) then true; 
    case (Absyn.CREF_IDENT(name = "String"),_) then true; 
    case (Absyn.CREF_IDENT(name = "Boolean"),_) then true; 
    case (_,_) then false; 
  end matchcontinue;
end isPrimitive;

protected function deleteClass "function: deleteClass
  
   Thisfunction takes a component reference and a program. 
   It deletes the class specified by the component reference from the 
   given program.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path cpath,parentcpath,parentparentcpath;
      Absyn.Class cdef,parentcdef,parentcdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      list<Absyn.Class> clist,clist_1;
      Absyn.Within w;
    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w)))
      equation 
        cpath = Absyn.crefToPath(class_) "Class inside another class, inside another class" ;
        parentcpath = Absyn.stripLast(cpath);
        parentparentcpath = Absyn.stripLast(parentcpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(
          Absyn.PROGRAM({parentcdef_1},Absyn.WITHIN(parentparentcpath)), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w)))
      equation 
        cpath = Absyn.crefToPath(class_) "Class inside other class" ;
        parentcpath = Absyn.stripLast(cpath);
        cdef = getPathedClassInProgram(cpath, p);
        parentcdef = getPathedClassInProgram(parentcpath, p);
        parentcdef_1 = removeInnerClass(cdef, parentcdef);
        newp = updateProgram(Absyn.PROGRAM({parentcdef_1},Absyn.TOP()), p);
      then
        ("true",newp);
    case (class_,(p as Absyn.PROGRAM(classes = clist,within_ = w)))
      equation 
        cpath = Absyn.crefToPath(class_) "Top level class" ;
        cdef = getPathedClassInProgram(cpath, p);
        clist_1 = deleteClassFromList(cdef, clist);
      then
        ("true",Absyn.PROGRAM(clist_1,w));
    case (_,p) then ("false",p); 
  end matchcontinue;
end deleteClass;

protected function deleteClassFromList "function: deleteClassFromList
 
  Helperfunction to delete_class.
"
  input Absyn.Class inClass;
  input list<Absyn.Class> inAbsynClassLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm 
  outAbsynClassLst:=
  matchcontinue (inClass,inAbsynClassLst)
    local
      String name,name2;
      list<Absyn.Class> xs,res;
      Absyn.Class cdef,x;
    case (_,{}) then {};  /* Empty list */ 
    case (Absyn.CLASS(name = name),(Absyn.CLASS(name = name2) :: xs))
      equation 
        equality(name = name2);
      then
        xs;
    case ((cdef as Absyn.CLASS(name = name)),((x as Absyn.CLASS(name = name2)) :: xs))
      equation 
        failure(equality(name = name2));
        res = deleteClassFromList(cdef, xs);
      then
        (x :: res);
    case ((cdef as Absyn.CLASS(name = name)),(x :: xs))
      equation 
        res = deleteClassFromList(cdef, xs);
      then
        (x :: res);
  end matchcontinue;
end deleteClassFromList;

protected function setClassComment "function: setClassComment
  author: PA
 
  Sets the class comment.
"
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inComponentRef,inString,inProgram)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_;
      String str;
    case (class_,str,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setClassCommentInClass(cdef, str);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    case (_,_,p) then (p,"Error"); 
  end matchcontinue;
end setClassComment;

protected function setClassCommentInClass "function: setClassCommentInClass
  author: PA
  
  Helperfunction to set_class_comment
"
  input Absyn.Class inClass;
  input String inString;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inString)
    local
      Absyn.ClassDef cdef_1,cdef;
      String id,cmt;
      Boolean p,f,e;
      Absyn.Restriction r;
      Absyn.Info info;
    case (Absyn.CLASS(name = id,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = cdef,info = info),cmt)
      equation 
        cdef_1 = setClassCommentInClassdef(cdef, cmt);
      then
        Absyn.CLASS(id,p,f,e,r,cdef_1,info);
  end matchcontinue;
end setClassCommentInClass;

protected function setClassCommentInClassdef "function: setClassCommentInClassdef
  author: PA
  
  Helperfunction to set_class_comment_in_class
"
  input Absyn.ClassDef inClassDef;
  input String inString;
  output Absyn.ClassDef outClassDef;
algorithm 
  outClassDef:=
  matchcontinue (inClassDef,inString)
    local
      list<Absyn.ClassPart> p;
      String cmt,strcmt,id;
      Option<Absyn.Comment> cmt_1;
      Option<list<Absyn.Subscript>> ad;
      Absyn.ElementAttributes attr;
      list<Absyn.ElementArg> arg,args;
      Absyn.EnumDef edef;
      list<Absyn.Path> plst;
      Absyn.ClassDef c;
    case (Absyn.PARTS(classParts = p),"") then Absyn.PARTS(p,NONE); 
    case (Absyn.PARTS(classParts = p),cmt) then Absyn.PARTS(p,SOME(cmt)); 
    case (Absyn.DERIVED(path = p,arrayDim = ad,attributes = attr,arguments = arg,comment = cmt),strcmt)
      local
        Absyn.Path p;
        Option<Absyn.Comment> cmt;
      equation 
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.DERIVED(p,ad,attr,arg,cmt_1);
    case (Absyn.ENUMERATION(enumLiterals = edef,comment = cmt),strcmt)
      local Option<Absyn.Comment> cmt;
      equation 
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.ENUMERATION(edef,cmt_1);
    case (Absyn.OVERLOAD(functionNames = plst,comment = cmt),strcmt)
      local Option<Absyn.Comment> cmt;
      equation 
        cmt_1 = setClassCommentInCommentOpt(cmt, strcmt);
      then
        Absyn.OVERLOAD(plst,cmt_1);
    case (Absyn.CLASS_EXTENDS(name = id,arguments = args,parts = p),"") then Absyn.CLASS_EXTENDS(id,args,NONE,p); 
    case (Absyn.CLASS_EXTENDS(name = id,arguments = args,parts = p),cmt) then Absyn.CLASS_EXTENDS(id,args,SOME(cmt),p); 
    case (c,_) then c; 
  end matchcontinue;
end setClassCommentInClassdef;

protected function setClassCommentInCommentOpt "function: setClassCommentInCommentOpt
  author: PA
  
  Sets the string comment in an Comment option.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
  input String inString;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm 
  outAbsynCommentOption:=
  matchcontinue (inAbsynCommentOption,inString)
    local
      Option<Absyn.Annotation> ann;
      String cmt;
    case (SOME(Absyn.COMMENT(ann,_)),"") then SOME(Absyn.COMMENT(ann,NONE)); 
    case (SOME(Absyn.COMMENT(ann,_)),cmt) then SOME(Absyn.COMMENT(ann,SOME(cmt))); 
    case (NONE,cmt) then SOME(Absyn.COMMENT(NONE,SOME(cmt))); 
  end matchcontinue;
end setClassCommentInCommentOpt;

protected function getClassInformation "function: getClassInformation
  author: PA
 
  Returns all the possible class information.
  changed by adrpo 2006-02-24 (latest 2006-03-14) to return more info and in a different format:
  {\"restriction\",\"comment\",\"filename.mo\",{bool,bool,bool},{\"readonly|writable\",int,int,int,int}}
  if you like more named attributes, use getClassAttributes API which uses get_class_attributes function
"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
  Absyn.Path path;
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol,res_1;
  Boolean partial_,final_,encapsulated_,isReadOnly;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
algorithm 
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(name,partial_,final_,encapsulated_,restr,cdef,Absyn.INFO(file,isReadOnly,sl,sc,el,ec)) := getPathedClassInProgram(path, p);
  strPartial := Util.boolString(partial_) "handling boolean attributes of the class" ;
  strFinal := Util.boolString(final_);
  strEncapsulated := Util.boolString(encapsulated_);
  res := Dump.unparseRestrictionStr(restr) "handling restriction" ;
  cmt := getClassComment(cdef) "handling class comment from the definition" ;
  str_readonly := selectString(isReadOnly, "readonly", "writable") "handling positional information" ;
  str_sline := intString(sl);
  str_scol := intString(sc);
  str_eline := intString(el);
  str_ecol := intString(ec);
  res_1 := Util.stringAppendList(
          {"{\"",res,"\",",cmt,",\"",file,"\",{",strPartial,",",
          strFinal,",",strEncapsulated,"},{\"",str_readonly,"\",",str_sline,",",
          str_scol,",",str_eline,",",str_ecol,"}}"}) "composing the final returned string" ;
end getClassInformation;

protected function getClassAttributes "function: getClassAttributes
  author: Adrian Pop, 2006-02-24
 
  Returns all the possible class information in this format:
  { name=\"Ident\", partial=(true|false), final=(true|false),
    encapsulated=(true|false), restriction=\"PACKAGE|CLASS|..\",
    comment=\"comment\", file=\"filename.mo\",  readonly=\"(readonly|writable)\",  
    startLine=number,  startColumn=number,
    endLine=number, endColumn=number }
"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
  Absyn.Path path;
  String name,file,strPartial,strFinal,strEncapsulated,res,cmt,str_readonly,str_sline,str_scol,str_eline,str_ecol,res_1;
  Boolean partial_,final_,encapsulated_,isReadOnly;
  Absyn.Restriction restr;
  Absyn.ClassDef cdef;
  Integer sl,sc,el,ec;
algorithm 
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(name,partial_,final_,encapsulated_,restr,cdef,Absyn.INFO(file,isReadOnly,sl,sc,el,ec)) := getPathedClassInProgram(path, p);
  strPartial := Util.boolString(partial_) "handling boolean attributes of the class" ;
  strFinal := Util.boolString(final_);
  strEncapsulated := Util.boolString(encapsulated_);
  res := Absyn.restrString(restr) "handling restriction" ;
  cmt := getClassComment(cdef) "handling class comment from the definition" ;
  str_readonly := selectString(isReadOnly, "readonly", "writable") "handling positional information" ;
  str_sline := intString(sl);
  str_scol := intString(sc);
  str_eline := intString(el);
  str_ecol := intString(ec);
  res_1 := Util.stringAppendList(
          {"{name=\"",name,"\", partial=",strPartial,", final=",
          strFinal,", encapsulated=",strEncapsulated,", restriction=",res,", comment=",
          cmt,", file=\"",file,"\", readonly=\"",str_readonly,"\", startLine=",
          str_sline,", startColumn=",str_scol,", endLine=",str_eline,", endColumn=",
          str_ecol,"}"}) "composing the final returned string" ;
end getClassAttributes;

protected function getClassComment "function: getClassComment
  author: PA
 
  Returns the class comment of a Absyn.ClassDef
"
  input Absyn.ClassDef cdef;
  output String res;
  String s;
algorithm 
  s := getClassComment2(cdef);
  res := Util.stringAppendList({"\"",s,"\""});
end getClassComment;

protected function getClassComment2 "function: getClassComment2
  
  Helperfunction to get_class_comment.
"
  input Absyn.ClassDef inClassDef;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClassDef)
    local
      String str,res;
      Option<Absyn.Comment> cmt;
    case (Absyn.PARTS(comment = SOME(str))) then str; 
    case (Absyn.DERIVED(comment = cmt))
      equation 
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.ENUMERATION(comment = cmt))
      equation 
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.ENUMERATION(comment = cmt))
      equation 
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.OVERLOAD(comment = cmt))
      equation 
        res = getStringComment2(cmt);
      then
        res;
    case (Absyn.CLASS_EXTENDS(comment = SOME(str))) then str; 
    case (_) then ""; 
  end matchcontinue;
end getClassComment2;

protected function getClassRestriction "function: getClassRestriction
  author: PA
 
  Returns the class restriction of a class as a string.
"
  input Absyn.ComponentRef cr;
  input Absyn.Program p;
  output String res_1;
  Absyn.Path path;
  Absyn.Restriction restr;
  String res,res_1;
algorithm 
  path := Absyn.crefToPath(cr);
  Absyn.CLASS(_,_,_,_,restr,_,_) := getPathedClassInProgram(path, p);
  res := Dump.unparseRestrictionStr(restr);
  res_1 := Util.stringAppendList({"\"",res,"\""});
end getClassRestriction;

protected function isType "function: isType 
 
  Thisfunction takes a component reference and a program. 
  It returns true if the refrenced class has the restriction \"type\", 
  otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_TYPE(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isType;

protected function isConnector "function: isConnector
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"connector\", 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isConnector;

protected function isModel "function: isModel
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"model\", 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_MODEL(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isModel;

protected function isRecord "function: isRecord
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"record\", 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_RECORD(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isRecord;

protected function isBlock "function: isBlock
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"block\", 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_BLOCK(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isBlock;

protected function isFunction "function: isFunction
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"function\", 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_FUNCTION(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isFunction;

public function isPackage "function: isPackage
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"package\", otherwise it returns 
   false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_PACKAGE(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isPackage;

protected function isClass "function: isClass
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class has the restriction \"class\", 
   otherwise it returns  false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        Absyn.CLASS(_,_,_,_,Absyn.R_CLASS(),_,_) = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end isClass;

protected function isParameter "function: isParameter
  
   Thisfunction takes a class and a component reference and a program
   and returns true if the component referenced is a parameter.
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path path;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
    case (cr,classname,p)
      equation 
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,Absyn.PARAM(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end isParameter;

protected function isProtected "function: isProtected
  
   Thisfunction takes a class and a component reference and a program
   and returns true if the component referenced is in a protected section.
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path path;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst,protlst;
      Absyn.ComponentRef cr,classname;
    case (cr,classname,p)
      equation 
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        _ = getComponentsContainsName(cr, publst);
      then
        false;
    case (cr,classname,p)
      equation 
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(path, p);
        protlst = getProtectedList(parts);
        _ = getComponentsContainsName(cr, protlst);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end isProtected;

protected function isConstant "function: isConstant
  
   Thisfunction takes a class and a component reference and a program
   and returns true if the component referenced is a constant.
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.Program inProgram3;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef1,inComponentRef2,inProgram3)
    local
      Absyn.Path path;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementItem> publst;
      Absyn.ComponentRef cr,classname;
    case (cr,classname,p)
      equation 
        path = Absyn.crefToPath(classname);
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(path, p);
        publst = getPublicList(parts);
        Absyn.COMPONENTS(Absyn.ATTR(_,Absyn.CONST(),_,_),_,_) = getComponentsContainsName(cr, publst);
      then
        true;
    case (_,_,_) then false; 
  end matchcontinue;
end isConstant;

protected function getElementitemContainsName "function: getElementitemContainsName
 
  Returns the element that has the component name given as argument.
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementItem outElementItem;
algorithm 
  outElementItem:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementItem elt,res;
      list<Absyn.ElementItem> rest;
    case (cr,(elt :: _))
      equation 
        _ = getComponentsContainsName(cr, {elt});
      then
        elt;
    case (cr,(_ :: rest))
      equation 
        res = getElementitemContainsName(cr, rest);
      then
        res;
  end matchcontinue;
end getElementitemContainsName;

protected function getComponentsContainsName "function: getComponentsContainsName
 
  Return the ElementSpec containing the name given as argument from a list
  of ElementItems
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.ElementSpec res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (res as Absyn.COMPONENTS(components = ellst)))) :: xs))
      equation 
        _ = getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(x :: xs))
      equation 
        res = getComponentsContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getComponentsContainsName;

protected function getElementContainsName "function: getElementContainsName
 
  Return the Element containing the component name given as argument from
  a list of ElementItems.
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inComponentRef,inAbsynElementItemLst)
    local
      Absyn.ComponentRef cr;
      Absyn.Element res;
      list<Absyn.ComponentItem> ellst;
      list<Absyn.ElementItem> xs;
      Absyn.ElementItem x;
    case (cr,(Absyn.ELEMENTITEM(element = (res as Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = ellst)))) :: xs))
      equation 
        _ = getCompitemNamed(cr, ellst);
      then
        res;
    case (cr,(x :: xs))
      equation 
        res = getElementContainsName(cr, xs);
      then
        res;
  end matchcontinue;
end getElementContainsName;

protected function getCompitemNamed "function: getCompitemNamed
 
  Helperfunction to get_components_contains_name.
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output Absyn.ComponentItem outComponentItem;
algorithm 
  outComponentItem:=
  matchcontinue (inComponentRef,inAbsynComponentItemLst)
    local
      String id1,id2;
      Absyn.ComponentItem x,res;
      list<Absyn.ComponentItem> xs;
      Absyn.ComponentRef cr;
    case (Absyn.CREF_IDENT(name = id1),((x as Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id2))) :: xs))
      equation 
        equality(id1 = id2);
      then
        x;
    case (cr,(x :: xs))
      equation 
        res = getCompitemNamed(cr, xs);
      then
        res;
  end matchcontinue;
end getCompitemNamed;

public function existClass "function: existClass
  
   Thisfunction takes a component reference and a program. 
   It returns true if the refrenced class exists in the symbol table, 
   otherwise it returns false.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path path;
      Absyn.ComponentRef cr;
      Absyn.Program p;
    case (cr,p)
      equation 
        path = Absyn.crefToPath(cr);
        _ = getPathedClassInProgram(path, p);
      then
        true;
    case (cr,p) then false; 
  end matchcontinue;
end existClass;

public function isPrimitiveClass "function: isPrimitiveClass
 
  Return true of a class is a primitive class, i.e. one of the builtin 
  classes or the \'type\' restricted class. It also checks derived classes
  using short class definition.
"
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inClass,inProgram)
    local
      Absyn.Path inmodel,path;
      Absyn.Class cdef;
      Boolean res;
      String cname;
      Absyn.Program p;
    case (Absyn.CLASS(restricion = Absyn.R_PREDEFINED_INT()),_) then true; 
    case (Absyn.CLASS(restricion = Absyn.R_PREDEFINED_REAL()),_) then true; 
    case (Absyn.CLASS(restricion = Absyn.R_PREDEFINED_STRING()),_) then true; 
    case (Absyn.CLASS(restricion = Absyn.R_PREDEFINED_BOOL()),_) then true; 
    case (Absyn.CLASS(restricion = Absyn.R_TYPE()),_) then true; 
    case (Absyn.CLASS(name = cname,restricion = Absyn.R_CLASS(),body = Absyn.DERIVED(path = path)),p)
      equation 
        inmodel = Absyn.crefToPath(Absyn.CREF_IDENT(cname,{}));
        (cdef,_) = lookupClassdef(path, inmodel, p);
        res = isPrimitiveClass(cdef, p);
      then
        res;
  end matchcontinue;
end isPrimitiveClass;

public function removeCompiledFunctions "function: removeCompiledFunctions
  
   A Compiled function should be removed if its definition is updated.
"
  input Absyn.Program inProgram;
  input list<tuple<Absyn.Path, Types.Type>> inTplAbsynPathTypesTypeLst;
  output list<tuple<Absyn.Path, Types.Type>> outTplAbsynPathTypesTypeLst;
algorithm 
  outTplAbsynPathTypesTypeLst:=
  matchcontinue (inProgram,inTplAbsynPathTypesTypeLst)
    local
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> cfs_1,cfs;
      String id;
    case (Absyn.PROGRAM(classes = {Absyn.CLASS(name = id,restricion = Absyn.R_FUNCTION())}),cfs)
      equation 
        cfs_1 = removeCf(id, cfs);
      then
        cfs_1;
    case (_,cfs) then cfs; 
  end matchcontinue;
end removeCompiledFunctions;

protected function removeCf "function: removeCf
 
  Helperfunction to remove_compiled_functions.
"
  input Absyn.Ident inIdent;
  input list<tuple<Absyn.Path, Types.Type>> inTplAbsynPathTypesTypeLst;
  output list<tuple<Absyn.Path, Types.Type>> outTplAbsynPathTypesTypeLst;
algorithm 
  outTplAbsynPathTypesTypeLst:=
  matchcontinue (inIdent,inTplAbsynPathTypesTypeLst)
    local
      list<tuple<Absyn.Path, tuple<Types.TType, Option<Absyn.Path>>>> res,rest;
      String id1,id2;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (_,{}) then {}; 
    case (id1,((Absyn.IDENT(name = id2),t) :: rest))
      equation 
        equality(id1 = id2);
        res = removeCf(id1, rest);
      then
        res;
    case (id1,((Absyn.IDENT(name = id2),t) :: rest))
      equation 
        failure(equality(id1 = id2));
        res = removeCf(id1, rest);
      then
        ((Absyn.IDENT(id2),t) :: res);
  end matchcontinue;
end removeCf;

public function updateProgram "function: updateProgram
  
   Thisfunction takes an old program (second argument), i.e. the old 
   symboltable, and a new program (first argument), i.e. a new set of
   classes and updates the old program with the definitions in the new one.
"
  input Absyn.Program inProgram1;
  input Absyn.Program inProgram2;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inProgram1,inProgram2)
    local
      Absyn.Program prg,newp,oldp,pnew,p2,pnew_1,a,b;
      Absyn.Class newclass,c1,cdef,newcdef;
      String name;
      Absyn.Restriction restr;
      Boolean p,e;
      Absyn.Path w,path,modelwithin;
      list<Absyn.Class> c2,c3;
      Absyn.Within w2;
      Absyn.ElementSpec elt;
    case (Absyn.PROGRAM(classes = {}),prg) then prg; 
    case (Absyn.BEGIN_DEFINITION(path = Absyn.IDENT(name = name),restriction = restr,partial_ = p,encapsulated_ = e),oldp)
      equation 
        newclass = Absyn.CLASS(name,p,false,e,restr,Absyn.PARTS({Absyn.PUBLIC({})},NONE),
          Absyn.INFO("",false,0,0,0,0)) "For split definitions at top, when introducing new model, eg. \"package A\"" ;
        newp = updateProgram(Absyn.PROGRAM({newclass},Absyn.TOP()), oldp);
      then
        newp;
    case (Absyn.BEGIN_DEFINITION(path = (path as Absyn.QUALIFIED(name = _)),restriction = restr,partial_ = p,encapsulated_ = e),oldp)
      equation 
        w = Absyn.stripLast(path) "For split definitions not at top,  eg. \"package A.B\"" ;
        name = Absyn.pathLastIdent(path);
        newclass = Absyn.CLASS(name,p,false,e,restr,Absyn.PARTS({Absyn.PUBLIC({})},NONE),
          Absyn.INFO("",false,0,0,0,0));
        newp = updateProgram(Absyn.PROGRAM({newclass},Absyn.WITHIN(w)), oldp);
      then
        newp;
    case (Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name)) :: c2),within_ = (w as Absyn.TOP())),(p2 as Absyn.PROGRAM(classes = c3,within_ = w2)))
      local Absyn.Within w;
      equation 
        false = classInProgram(name, p2);
        pnew = updateProgram(Absyn.PROGRAM(c2,w), Absyn.PROGRAM((c1 :: c3),w2));
      then
        pnew;
    case (Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name)) :: c2),within_ = (w as Absyn.TOP())),p2)
      local Absyn.Within w;
      equation 
        true = classInProgram(name, p2);
        pnew = updateProgram(Absyn.PROGRAM(c2,w), p2);
        pnew_1 = replaceClassInProgram(c1, pnew);
      then
        pnew_1;
    case (Absyn.PROGRAM(classes = (c1 :: c2),within_ = (w as Absyn.WITHIN(path = path))),p2)
      local Absyn.Within w;
      equation 
        pnew = insertClassInProgram(c1, w, p2);
        pnew_1 = updateProgram(Absyn.PROGRAM(c2,w), pnew);
      then
        pnew_1;
    case (Absyn.COMP_DEFINITION(element = elt,insertInto = SOME((path as Absyn.QUALIFIED(_,_)))),p)
      local Absyn.Program p;
      equation 
        cdef = getPathedClassInProgram(path, p) "nested packages (of form A.B)" ;
        modelwithin = Absyn.stripLast(path);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",elt,
          Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        newp;
    case (Absyn.COMP_DEFINITION(element = elt,insertInto = SOME((path as Absyn.IDENT(_)))),p)
      local Absyn.Program p;
      equation 
        cdef = getPathedClassInProgram(path, p) "top package" ;
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",elt,
          Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        newp;
    case (Absyn.IMPORT_DEFINITION(importElementFor = elt,insertInto = SOME((path as Absyn.QUALIFIED(_,_)))),p)
      local Absyn.Program p;
      equation 
        cdef = getPathedClassInProgram(path, p) "nested packages ( e.g. A.B )" ;
        modelwithin = Absyn.stripLast(path);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",elt,
          Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        newp;
    case (Absyn.IMPORT_DEFINITION(importElementFor = elt,insertInto = SOME((path as Absyn.IDENT(_)))),p)
      local Absyn.Program p;
      equation 
        cdef = getPathedClassInProgram(path, p) "top level package e.g. A" ;
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",elt,
          Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        newp;
    case (a,b)
      equation 
        Print.printBuf("Further program merging not implemented yet\n");
      then
        b;
  end matchcontinue;
end updateProgram;

public function addScope "function: addScope
  
    Thisfunction adds the scope of the scope variable to the program,
   so it can be inserted at the correct place.
   It also adds the scope to BEGIN_DEFINITION, COMP_DEFINITION and 
   IMPORT_DEFINITION so an empty class definition
   can be inserted at the correct place.
"
  input Absyn.Program inProgram;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inProgram,inInteractiveVariableLst)
    local
      Absyn.Path path,newpath,path2;
      list<Absyn.Class> cls;
      list<InteractiveVariable> vars;
      Absyn.Within w;
      Absyn.Restriction restr;
      Boolean p,e;
      Absyn.ElementSpec elt;
    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.TOP()),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(path));
    case (Absyn.PROGRAM(classes = cls,within_ = w),vars)
      equation 
        failure(_ = getVariableValue("scope", vars));
      then
        Absyn.PROGRAM(cls,w);
    case (Absyn.PROGRAM(classes = cls,within_ = Absyn.WITHIN(path = path2)),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars) "This should probably be forbidden." ;
        newpath = Absyn.joinPaths(path, path2);
      then
        Absyn.PROGRAM(cls,Absyn.WITHIN(newpath));
    case (Absyn.BEGIN_DEFINITION(path = path2,restriction = restr,partial_ = p,encapsulated_ = e),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
        newpath = Absyn.joinPaths(path, path2);
      then
        Absyn.BEGIN_DEFINITION(newpath,restr,p,e);
    case (Absyn.COMP_DEFINITION(element = elt,insertInto = NONE),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
      then
        Absyn.COMP_DEFINITION(elt,SOME(path));
    case (Absyn.IMPORT_DEFINITION(importElementFor = elt,insertInto = NONE),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars);
      then
        Absyn.IMPORT_DEFINITION(elt,SOME(path));
    case (p,_)
      local Absyn.Program p;
      then
        p;
  end matchcontinue;
end addScope;

public function updateScope "function: updateScope
   Thisfunction takes a PROGRAM and updates the variable scope to according
   to the value of program:
   1. BEGIN_DEFINITION ident appends ident to scope
   2.END_DEFINITION ident removes ident from scope
"
  input Absyn.Program inProgram;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output list<InteractiveVariable> outInteractiveVariableLst;
algorithm 
  outInteractiveVariableLst:=
  matchcontinue (inProgram,inInteractiveVariableLst)
    local
      Absyn.Path path,newscope,path_1;
      Values.Value newscope_1;
      list<InteractiveVariable> vars_1,vars;
      String id,id2,id1;
    case (Absyn.BEGIN_DEFINITION(path = Absyn.IDENT(name = id)),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars) "If not top scope" ;
        newscope = Absyn.joinPaths(path, Absyn.IDENT(id));
        newscope_1 = Values.CODE(Absyn.C_TYPENAME(newscope));
        vars_1 = addVarToVarlist("scope", newscope_1, 
          (Types.T_COMPLEX(ClassInf.UNKNOWN("TypeName"),{},NONE),NONE), vars);
      then
        vars_1;
    case (Absyn.BEGIN_DEFINITION(path = Absyn.IDENT(name = id)),vars)
      equation 
        newscope_1 = Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(id))) "If top scope" ;
        vars_1 = addVarToVarlist("scope", newscope_1, 
          (Types.T_COMPLEX(ClassInf.UNKNOWN("TypeName"),{},NONE),NONE), vars);
      then
        vars_1;
    case (Absyn.END_DEFINITION(name = id1),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(path)) = getVariableValue("scope", vars) "If not top scope" ;
        id2 = Absyn.pathLastIdent(path);
        equality(id1 = id2);
        newscope = Absyn.stripLast(path);
        newscope_1 = Values.CODE(Absyn.C_TYPENAME(newscope));
        path_1 = Absyn.stripLast(path);
        vars_1 = addVarToVarlist("scope", newscope_1, 
          (Types.T_COMPLEX(ClassInf.UNKNOWN("TypeName"),{},NONE),NONE), vars);
      then
        vars_1;
    case (Absyn.END_DEFINITION(name = id1),vars)
      equation 
        Values.CODE(Absyn.C_TYPENAME(Absyn.IDENT(id2))) = getVariableValue("scope", vars);
        equality(id1 = id2);
        vars_1 = removeVarFromVarlist("scope", vars);
      then
        vars_1;
    case (_,vars) then vars; 
  end matchcontinue;
end updateScope;

protected function removeVarFromVarlist "function: removeVarFromVarlist
 
  Helperfunction to update_scope.
"
  input Absyn.Ident inIdent;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output list<InteractiveVariable> outInteractiveVariableLst;
algorithm 
  outInteractiveVariableLst:=
  matchcontinue (inIdent,inInteractiveVariableLst)
    local
      String id1,id2;
      list<InteractiveVariable> rest,rest_1;
      InteractiveVariable v;
    case (_,{}) then {}; 
    case (id1,(IVAR(varIdent = id2) :: rest))
      equation 
        equality(id1 = id2);
      then
        rest;
    case (id1,((v as IVAR(varIdent = id2)) :: rest))
      equation 
        failure(equality(id1 = id2));
        rest_1 = removeVarFromVarlist(id1, rest);
      then
        (v :: rest_1);
  end matchcontinue;
end removeVarFromVarlist;

protected function getVariableValue "function: getVariableValue
 
  Return the value of an interactive variable from a list of 
  InteractiveVariable.
"
  input Absyn.Ident inIdent;
  input list<InteractiveVariable> inInteractiveVariableLst;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inIdent,inInteractiveVariableLst)
    local
      String id1,id2;
      Values.Value v;
      list<InteractiveVariable> rest;
    case (id1,(IVAR(varIdent = id2,value = v) :: _))
      equation 
        equality(id1 = id2);
      then
        v;
    case (id1,(IVAR(varIdent = id2,value = v) :: rest))
      equation 
        failure(equality(id1 = id2));
        v = getVariableValue(id1, rest);
      then
        v;
  end matchcontinue;
end getVariableValue;

protected function lookupClassdef "function: lookupClassdef
  
   Thisfunction takes a Path of a class to lookup and a Path as a 
   starting point for the lookup rules and a Program.
   It returns the Class definition and the complete Path to the class.
"
  input Absyn.Path inPath1;
  input Absyn.Path inPath2;
  input Absyn.Program inProgram3;
  output Absyn.Class outClass;
  output Absyn.Path outPath;
algorithm 
  (outClass,outPath):=
  matchcontinue (inPath1,inPath2,inProgram3)
    local
      Absyn.Class inmodeldef,cdef;
      Absyn.Path newpath,path,inmodel,innewpath,respath,inpath;
      Absyn.Program p;
      String s1,s2;
    case (path,inmodel,p)
      equation 
        inmodeldef = getPathedClassInProgram(inmodel, p) "Look first inside \'inmodel\'" ;
        cdef = getPathedClassInProgram(path, Absyn.PROGRAM({inmodeldef},Absyn.TOP()));
        newpath = Absyn.joinPaths(inmodel, path);
      then
        (cdef,newpath);
    case (path,inmodel,p) /* Then look inside next level */ 
      equation 
        innewpath = Absyn.stripLast(inmodel);
        (cdef,respath) = lookupClassdef(path, innewpath, p);
      then
        (cdef,respath);
    case (path,_,p)
      equation 
        cdef = getPathedClassInProgram(path, p) "Finally look in top level" ;
      then
        (cdef,path);
    case (Absyn.IDENT(name = "Real"),_,_) then (Absyn.CLASS("Real",false,false,false,Absyn.R_PREDEFINED_REAL(),
          Absyn.PARTS({},NONE),Absyn.INFO("",false,0,0,0,0)),Absyn.IDENT("Real")); 
    case (Absyn.IDENT(name = "Integer"),_,_) then (Absyn.CLASS("Integer",false,false,false,Absyn.R_PREDEFINED_INT(),
          Absyn.PARTS({},NONE),Absyn.INFO("",false,0,0,0,0)),Absyn.IDENT("Integer")); 
    case (Absyn.IDENT(name = "String"),_,_) then (Absyn.CLASS("String",false,false,false,Absyn.R_PREDEFINED_STRING(),
          Absyn.PARTS({},NONE),Absyn.INFO("",false,0,0,0,0)),Absyn.IDENT("String")); 
    case (Absyn.IDENT(name = "Boolean"),_,_) then (Absyn.CLASS("Boolean",false,false,false,Absyn.R_PREDEFINED_BOOL(),
          Absyn.PARTS({},NONE),Absyn.INFO("",false,0,0,0,0)),Absyn.IDENT("Boolean")); 
    case (path,inpath,_)
      equation 
        s1 = Absyn.pathString(path);
        s2 = Absyn.pathString(inpath);
        Error.addMessage(Error.LOOKUP_ERROR, {s1,s2});
      then
        fail();
  end matchcontinue;
end lookupClassdef;

protected function deleteComponent "function: deleteComponent
  
   Thisfunction deletes a component from a class given the name of the 
   component instance, the model in which the component is instantiated in, 
   and the Program.
  
   Both public and protected lists are searched.
"
  input String inString;
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inString,inComponentRef,inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      String name;
      Absyn.ComponentRef model_;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Absyn.Within w;
    case (name,model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        failure(_ = getPathedClassInProgram(modelpath, p));
      then
        (p,"false\n");
    case (name,(model_ as Absyn.CREF_QUAL(name = _)),(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteComponentFromClass(name, cdef);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (newp,"true\n");
    case (name,(model_ as Absyn.CREF_IDENT(name = _)),(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteComponentFromClass(name, cdef);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (newp,"true\n");
    case (_,_,p) then (p,"false\n"); 
  end matchcontinue;
end deleteComponent;

protected function deleteComponentFromClass "function: deleteComponentFromClass
  
   Thisfunction deletes a component from a class given the name of the component instance, and a \'Class\'.
   
   Both public and protected lists are searched.
"
  input String inString;
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inString,inClass)
    local
      list<Absyn.ElementItem> publst,publst2,protlst,protlst2;
      Integer l2,l1,l1_1;
      list<Absyn.ClassPart> parts2,parts;
      String name,i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
    case (name,Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info))
      equation 
        publst = getPublicList(parts) "Search in public list" ;
        publst2 = deleteComponentFromElementitems(name, publst);
        l2 = listLength(publst2);
        l1 = listLength(publst);
        l1_1 = l1 - 1;
        equality(l1_1 = l2);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
    case (name,Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info)) /* Search in protected list */ 
      equation 
        protlst = getProtectedList(parts);
        protlst2 = deleteComponentFromElementitems(name, protlst);
        l2 = listLength(protlst2);
        l1 = listLength(protlst);
        l1_1 = l1 - 1;
        equality(l1_1 = l2);
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
  end matchcontinue;
end deleteComponentFromClass;

protected function deleteComponentFromElementitems "function: deleteComponentFromElementitems
 
  Helperfunction to delete_component_from_class.
"
  input String inString;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inString,inAbsynElementItemLst)
    local
      String name,name2;
      list<Absyn.ElementItem> xs,res;
      Absyn.ElementItem x;
    case (_,{}) then {}; 
    case (name,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2))}))) :: xs))
      equation 
        equality(name = name2);
      then
        xs;
    case (name,((x as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = {Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = name2))})))) :: xs))
      equation 
        failure(equality(name = name2));
        res = deleteComponentFromElementitems(name, xs);
      then
        (x :: res);
    case (name,(x :: xs))
      equation 
        res = deleteComponentFromElementitems(name, xs);
      then
        (x :: res);
  end matchcontinue;
end deleteComponentFromElementitems;

public function addComponent "function addComponent
  
   Thisfunction takes:  
   arg1 - string giving the instancename, 
   arg2 - `ComponentRef\' giving the component type
   arg3 - ComponentRef giving the model to instantiate the component within,
   arg4 - `NamedArg\' list of annotations 
   arg5 - a Program. 
   The result is an updated program with the component and its annotations 
   inserted, and a string \"OK\" for success. If the insertion fails, a
   suitable error string is given along with the input Program.
"
  input String inString1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inString1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,modelwithin,tppath;
      String name;
      Absyn.ComponentRef tp,model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Program p,newp;
      Absyn.Class cdef,newcdef;
      Option<Absyn.Comment> annotation_;
      Option<Absyn.Modification> modification;
      Absyn.Within w;
    case (name,tp,model_,nargs,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        failure(_ = getPathedClassInProgram(modelpath, p));
      then
        (p,"false\n");
    case (name,tp,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w))) /* Adding component to model that resides inside package */ 
      equation 
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        annotation_ = annotationListToAbsynComment(nargs, NONE);
        modification = modificationToAbsyn(nargs, NONE);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),tppath,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),NONE,annotation_)}),Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (newp,"Ok\n");
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w))) /* Adding component to model that resides on top level */ 
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        annotation_ = annotationListToAbsynComment(nargs, NONE);
        modification = modificationToAbsyn(nargs, NONE);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),tppath,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),NONE,annotation_)}),Absyn.INFO("",false,0,0,0,0),NONE)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (newp,"Ok\n");
    case (_,_,_,_,p) then (p,"Error"); 
  end matchcontinue;
end addComponent;

protected function updateComponent "function: updateComponent
  
   Thisfunction updates a component in a class. The reason for having 
   thisfunction is that a deletion followed by an addition would mean that 
   all optional arguments must be present to the add_componentfunction 
   in order to get the same component attributes,etc. as previous. 
"
  input String inString1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inString1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,modelwithin,tp,tppath;
      Absyn.Program p_1,newp,p;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef,newcdef;
      list<Absyn.ElementItem> publst,protlst;
      Boolean final_;
      Option<Absyn.RedeclareKeywords> repl;
      Absyn.InnerOuter inout;
      String id,name;
      Absyn.ElementAttributes attr;
      list<Absyn.ComponentItem> items;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      Option<Absyn.Modification> mod,modification;
      Option<Absyn.Exp> cond;
      Option<Absyn.Comment> ann,annotation_;
      Absyn.ComponentRef model_;
      list<Absyn.NamedArg> nargs;
      Absyn.Within w;
    case (name,tp,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_) "Updating a public component to model that resides inside package" ;
        modelwithin = Absyn.stripLast(modelpath);
        (p_1,_) = deleteComponent(name, model_, p);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        publst = getPublicList(parts);
        Absyn.ELEMENT(final_,repl,inout,id,Absyn.COMPONENTS(attr,tp,items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), publst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,repl,inout,id,
          Absyn.COMPONENTS(attr,tp,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (newp,"true");
    case (name,tp,(model_ as Absyn.CREF_QUAL(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_) "Updating a protected component to model that resides inside package" ;
        modelwithin = Absyn.stripLast(modelpath);
        (p_1,_) = deleteComponent(name, model_, p);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        protlst = getProtectedList(parts);
        Absyn.ELEMENT(final_,repl,inout,id,Absyn.COMPONENTS(attr,tp,items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), protlst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToProtected(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,repl,inout,id,
          Absyn.COMPONENTS(attr,tp,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        (newp,"true");
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_) "Updating a public component to model that resides on top level" ;
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        (p_1,_) = deleteComponent(name, model_, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        publst = getPublicList(parts);
        Absyn.ELEMENT(final_,repl,inout,id,Absyn.COMPONENTS(attr,tp,items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), publst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToPublic(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,repl,inout,id,
          Absyn.COMPONENTS(attr,tppath,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (newp,"true");
    case (name,tp,(model_ as Absyn.CREF_IDENT(name = _)),nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_) "Updating a protected component to model that resides on top level" ;
        cdef = getPathedClassInProgram(modelpath, p);
        tppath = Absyn.crefToPath(tp);
        (p_1,_) = deleteComponent(name, model_, p);
        cdef = getPathedClassInProgram(modelpath, p_1);
        Absyn.CLASS(_,_,_,_,_,Absyn.PARTS(parts,_),_) = getPathedClassInProgram(modelpath, p);
        protlst = getProtectedList(parts);
        Absyn.ELEMENT(final_,repl,inout,id,Absyn.COMPONENTS(attr,tp,items),info,constr) = getElementContainsName(Absyn.CREF_IDENT(name,{}), protlst);
        Absyn.COMPONENTITEM(Absyn.COMPONENT(_,_,mod),cond,ann) = getCompitemNamed(Absyn.CREF_IDENT(name,{}), items);
        annotation_ = annotationListToAbsynComment(nargs, ann);
        modification = modificationToAbsyn(nargs, mod);
        newcdef = addToProtected(cdef, 
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(final_,repl,inout,id,
          Absyn.COMPONENTS(attr,tppath,
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT(name,{},modification),cond,annotation_)}),info,constr)));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        (newp,"true");
  end matchcontinue;
end updateComponent;

protected function addClassAnnotation "function:addClassAnnotation 
  
   Thisfunction takes a `ComponentRef\' and an `Exp\' expression and a 
   `Program\' and adds the expression as a annotation to the specified 
   model in the program, returning the updated program.
"
  input Absyn.ComponentRef inComponentRef;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inComponentRef,inAbsynNamedArgLst,inProgram)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_;
      list<Absyn.NamedArg> nargs;
    case ((model_ as Absyn.CREF_QUAL(name = _)),nargs,p)
      equation 
        modelpath = Absyn.crefToPath(model_) "Class inside other class" ;
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        cdef_1 = addClassAnnotationToClass(cdef, nargs);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},Absyn.WITHIN(modelwithin)), p);
      then
        newp;
    case ((model_ as Absyn.CREF_IDENT(name = _)),nargs,p)
      equation 
        modelpath = Absyn.crefToPath(model_) "Class on top level" ;
        cdef = getPathedClassInProgram(modelpath, p);
        cdef_1 = addClassAnnotationToClass(cdef, nargs);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},Absyn.TOP()), p);
      then
        newp;
  end matchcontinue;
end addClassAnnotation;

protected function addClassAnnotationToClass "function: addClassAnnotationToClass
  
   Thisfunction adds an annotation on element level to a `Class´.
"
  input Absyn.Class inClass;
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inAbsynNamedArgLst)
    local
      list<Absyn.ElementItem> publst,publst2;
      Absyn.Annotation annotation_,oldann,newann,newann_1;
      Absyn.Class cdef_1,cdef;
      list<Absyn.ClassPart> parts,parts2;
      list<Absyn.NamedArg> nargs;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
    case ((cdef as Absyn.CLASS(body = Absyn.PARTS(classParts = parts))),nargs)
      equation 
        publst = getPublicList(parts) "No annotation element found in class" ;
        failure(_ = getElementAnnotationInElements(publst));
        annotation_ = annotationListToAbsyn(nargs);
        cdef_1 = addToPublic(cdef, Absyn.ANNOTATIONITEM(annotation_));
      then
        cdef_1;
    case ((cdef as Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info)),nargs)
      equation 
        publst = getPublicList(parts);
        Absyn.ANNOTATIONITEM(oldann) = getElementAnnotationInElements(publst);
        newann = annotationListToAbsyn(nargs);
        newann_1 = mergeAnnotations(oldann, newann);
        publst2 = replaceElementAnnotationInElements(publst, newann_1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
  end matchcontinue;
end addClassAnnotationToClass;

protected function replaceElementAnnotationInElements "function: replaceElementAnnotationInElements
  
   Thisfunction takes an element list and replaces the first annotation 
   with the one given as argument.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Annotation inAnnotation;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inAnnotation)
    local
      list<Absyn.ElementItem> xs,res;
      Absyn.Annotation a,a2;
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: xs),a) then (Absyn.ANNOTATIONITEM(a) :: xs); 
    case ((a :: xs),a2)
      local Absyn.ElementItem a;
      equation 
        res = replaceElementAnnotationInElements(xs, a2);
      then
        (a :: res);
    case ({},_) then {}; 
  end matchcontinue;
end replaceElementAnnotationInElements;

protected function getElementAnnotationInElements "function: getElementAnnotationInElements
  
   Thisfunction retrieves the forst Annotation among the elements 
   taken as argument
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Absyn.ElementItem outElementItem;
algorithm 
  outElementItem:=
  matchcontinue (inAbsynElementItemLst)
    local
      Absyn.ElementItem a;
      list<Absyn.ElementItem> xs;
    case (((a as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs)) then a; 
    case ((_ :: xs))
      equation 
        a = getElementAnnotationInElements(xs);
      then
        a;
  end matchcontinue;
end getElementAnnotationInElements;

protected function mergeAnnotations "function: mergeAnnotations
  
   Thisfunction takes an old annotation as first argument and a new 
   annotation as  second argument and merges the two.
   Annotation \"parts\" that exist in both the old and the new annotation 
   will be changed according to the new definition. For instance,
   merge_annotations(annotation(x=1,y=2),annotation(x=3)) 
   => annotation(x=3,y=2)
"
  input Absyn.Annotation inAnnotation1;
  input Absyn.Annotation inAnnotation2;
  output Absyn.Annotation outAnnotation;
algorithm 
  outAnnotation:=
  matchcontinue (inAnnotation1,inAnnotation2)
    local
      list<Absyn.ElementArg> neweltargs,oldrest,eltargs,eltargs_1;
      Absyn.ElementArg mod;
      Absyn.ComponentRef cr;
      Absyn.Annotation a;
    case (Absyn.ANNOTATION(elementArgs = ((mod as Absyn.MODIFICATION(componentReg = cr)) :: oldrest)),Absyn.ANNOTATION(elementArgs = eltargs))
      equation 
        failure(_ = removeModificationInElementargs(eltargs, cr));
        Absyn.ANNOTATION(neweltargs) = mergeAnnotations(Absyn.ANNOTATION(oldrest), Absyn.ANNOTATION(eltargs));
      then
        Absyn.ANNOTATION((mod :: neweltargs));
    case (Absyn.ANNOTATION(elementArgs = ((mod as Absyn.MODIFICATION(componentReg = cr)) :: oldrest)),Absyn.ANNOTATION(elementArgs = eltargs))
      equation 
        eltargs_1 = removeModificationInElementargs(eltargs, cr);
        Absyn.ANNOTATION(neweltargs) = mergeAnnotations(Absyn.ANNOTATION(oldrest), Absyn.ANNOTATION(eltargs));
      then
        Absyn.ANNOTATION(neweltargs);
    case (Absyn.ANNOTATION(elementArgs = {}),a) then a; 
  end matchcontinue;
end mergeAnnotations;

protected function removeModificationInElementargs "function: removeModificationInElementargs
  
   Thisfunction removes the class modification named by the second argument.
   If no such class modification is found thefunction fails.
   Currently, only identifiers are allowed as class modifiers, 
   i.e. a(...) and not a.b(...)
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  input Absyn.ComponentRef inComponentRef;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementArgLst,inComponentRef)
    local
      String id,id2;
      Absyn.ComponentRef cr;
      Absyn.ElementArg m;
      list<Absyn.ElementArg> res,xs;
    case ({Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id))},(cr as Absyn.CREF_IDENT(name = id2)))
      equation 
        equality(id = id2);
      then
        {};
    case ({(m as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id)))},(cr as Absyn.CREF_IDENT(name = id2)))
      equation 
        failure(equality(id = id2));
      then
        fail();
    case ((Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id)) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation 
        equality(id = id2);
        res = removeModificationInElementargs(xs, cr);
      then
        res;
    case (((m as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id))) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation 
        failure(equality(id = id2));
        res = removeModificationInElementargs(xs, cr);
      then
        (m :: res);
    case (((m as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id))) :: xs),(cr as Absyn.CREF_IDENT(name = id2)))
      equation 
        res = removeModificationInElementargs(xs, cr);
      then
        (m :: res);
  end matchcontinue;
end removeModificationInElementargs;

protected function getInheritanceCount "function: getInheritanceCount
 
  Thisfunction takes a `ComponentRef\' and a `Program\' and returns the 
  number of inherited classes in the class referenced by the 
  `ComponentRef\'.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        count = countBaseClasses(cdef);
      then
        count;
    case (_,_) then 0; 
  end matchcontinue;
end getInheritanceCount;

protected function getNthInheritedClass "function: get_inheritance_count
  Thisfunction takes a `ComponentRef\' and a `Program\' and returns the 
  number of inherited classes in the class referenced by the `ComponentRef\'.
"
  input Absyn.ComponentRef inComponentRef;
  input Integer inInteger;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inInteger,inProgram)
    local
      Absyn.Path modelpath,path;
      Absyn.Class cdef;
      list<SCode.Class> p_1;
      list<Env.Frame> env,env_1;
      SCode.Class c;
      String id,str,s;
      Boolean encflag;
      SCode.Restriction restr;
      Absyn.ComponentRef model_;
      Integer n,n_1;
      Absyn.Program p;
      list<Absyn.ElementSpec> extends_;
    case (model_,n,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(Env.emptyCache,env, modelpath, false);
        str = getNthInheritedClass2(c, cdef, n, env_1);
      then
        str;
    case (model_,n,p) /* if above fails, baseclass not defined. return its name */ 
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        extends_ = getExtendsInClass(cdef);
        n_1 = n - 1;
        Absyn.EXTENDS(path,_) = listNth(extends_, n_1);
        s = Absyn.pathString(path);
      then
        s;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthInheritedClass;

protected function getExtendsInClass "function: getExtendsInClass
 
  Returns all ElementSpec of EXTENDS in a class.
"
  input Absyn.Class inClass;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementSpec> res;
      String n;
      Boolean p,f,e;
      Absyn.Restriction r;
      list<Absyn.ClassPart> parts;
    case (Absyn.CLASS(name = n,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts)))
      equation 
        res = getExtendsInParts(parts);
      then
        res;
  end matchcontinue;
end getExtendsInClass;

protected function getExtendsInParts "function: getExtendsInParts
  author: PA
 
  Helper function to get_extends_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementSpec> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> parts;
    case {} then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: parts))
      equation 
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: parts))
      equation 
        l1 = getExtendsInParts(parts);
        l2 = getExtendsInElementitems(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: parts))
      equation 
        res = getExtendsInParts(parts);
      then
        res;
  end matchcontinue;
end getExtendsInParts;

protected function getExtendsInElementitems "function: getExtendsInElementitems
  author: PA
 
  Helper function to get_extends_in_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementSpec> outAbsynElementSpecLst;
algorithm 
  outAbsynElementSpecLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.ElementSpec> res;
      Absyn.ElementSpec e;
      list<Absyn.ElementItem> es;
    case ({}) then {}; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = (e as Absyn.EXTENDS(path = _)))) :: es))
      equation 
        res = getExtendsInElementitems(es);
      then
        (e :: res);
    case ((_ :: es))
      equation 
        res = getExtendsInElementitems(es);
      then
        res;
  end matchcontinue;
end getExtendsInElementitems;

protected function getNthInheritedClass2 "function: getNthInheritedClass2
 
  Helperfunction to get_nth_inherited_class.
"
  input SCode.Class inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input Env.Env inEnv4;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClass1,inClass2,inInteger3,inEnv4)
    local
      list<Absyn.ComponentRef> lst;
      Integer n_1,n;
      Absyn.ComponentRef cref;
      Absyn.Path path;
      String str,id;
      SCode.Class c;
      Absyn.Class cdef;
      list<Env.Frame> env,env2,env_2;
      ClassInf.State ci_state;
      Boolean encflag;
      SCode.Restriction restr;
    case ((c as SCode.CLASS(name = _)),cdef,n,env)
      equation 
        lst = getBaseClasses(cdef, env) "First try without instantiating, if class is in parents" ;
        n_1 = n - 1;
        cref = listNth(lst, n_1);
        path = Absyn.crefToPath(cref);
        str = Absyn.pathString(path);
      then
        str;
    case ((c as SCode.CLASS(name = id,encapsulated_ = encflag,restricion = restr)),cdef,n,env)
      equation 
        env2 = Env.openScope(env, encflag, SOME(id)) "If that fails, instantiate, which takes more time" ;
        ci_state = ClassInf.start(restr, id);
        (_,env_2,_) = Inst.partialInstClassIn(Env.emptyCache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        lst = getBaseClasses(cdef, env_2);
        n_1 = n - 1;
        cref = listNth(lst, n_1);
        path = Absyn.crefToPath(cref);
        str = Absyn.pathString(path);
      then
        str;
  end matchcontinue;
end getNthInheritedClass2;

public function getComponentCount "function: getComponentCount
  
   Thisfunction takes a `ComponentRef\' and a `Program\' and returns the 
   number of public components in the class referenced by the `ComponentRef\'.
"
  input Absyn.ComponentRef model_;
  input Absyn.Program p;
  output Integer count;
  Absyn.Path modelpath;
  Absyn.Class cdef;
algorithm 
  modelpath := Absyn.crefToPath(model_);
  cdef := getPathedClassInProgram(modelpath, p);
  count := countComponents(cdef);
end getComponentCount;

protected function countComponents "function: countComponents
  
   Thisfunction takes a `Class\' and returns the number of components 
   in that class
"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inClass)
    local
      Integer c1,c2,res;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      Absyn.Info file_info;
    case Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info)
      equation 
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),info = file_info)
      equation 
        c1 = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        c2 = countComponentsInElts(elt);
      then
        c1 + c2;
    case Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info)
      equation 
        res = countComponents(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
      then
        res;
    case Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {})) then 0; 
    case Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.DERIVED(path = _)) then -1; 
  end matchcontinue;
end countComponents;

protected function countComponentsInElts "function: countComponentsInElts
 
  Helperfunction to count_components
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inAbsynElementItemLst)
    local
      Integer c1,ncomps,res;
      list<Absyn.ComponentItem> complst;
      list<Absyn.ElementItem> lst;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = complst),constrainClass = NONE)) :: lst))
      equation 
        c1 = countComponentsInElts(lst);
        ncomps = listLength(complst);
      then
        c1 + ncomps;
    case ((_ :: lst))
      equation 
        res = countComponentsInElts(lst);
      then
        res;
    case ({}) then 0; 
  end matchcontinue;
end countComponentsInElts;

protected function getNthComponent "function: getNthComponent
  
   Thisfunction takes a `ComponentRef\', a `Program\' and an int and 
   returns a comma separated string of names containing the name, type 
   and comment of that component.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      list<SCode.Class> p_1;
      list<Env.Frame> env,env_1;
      SCode.Class c;
      String id,str;
      Boolean encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(Env.emptyCache,env, modelpath, false);
        cdef = getPathedClassInProgram(modelpath, p);
        str = getNthComponent2(c, cdef, n, env_1);
      then
        str;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthComponent;

protected function getNthComponent2 "function: getNthComponent2
 
  Helperfunction to get_nth_component.
"
  input SCode.Class inClass1;
  input Absyn.Class inClass2;
  input Integer inInteger3;
  input Env.Env inEnv4;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClass1,inClass2,inInteger3,inEnv4)
    local
      list<Env.Frame> env2,env_2,env;
      ClassInf.State ci_state;
      Absyn.Element comp;
      String s1,s2,str,id;
      SCode.Class c;
      Boolean encflag;
      SCode.Restriction restr;
      Absyn.Class cdef;
      Integer n;
    case ((c as SCode.CLASS(name = id,encapsulated_ = encflag,restricion = restr)),cdef,n,env)
      equation 
        env2 = Env.openScope(env, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,env_2,_) = Inst.partialInstClassIn(Env.emptyCache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        comp = getNthComponentInClass(cdef, n);
        {s1} = getComponentInfoOld(comp, env_2);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case (_,_,_,_)
      equation 
        print("get_nth_component2 failed\n");
      then
        fail();
  end matchcontinue;
end getNthComponent2;

public function getComponents "function: getComponents
  
   Thisfunction takes a `ComponentRef\', a `Program\' and an int and  returns 
   a list of all components, as returned by get_nth_component.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<SCode.Class> p_1;
      list<Env.Frame> env,env_1,env2,env_2;
      SCode.Class c;
      String id,s1,s2,str,res;
      Boolean encflag;
      SCode.Restriction restr;
      ClassInf.State ci_state;
      list<Absyn.Element> comps1,comps2;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,(c as SCode.CLASS(id,_,encflag,restr,_)),env_1) = Lookup.lookupClass(Env.emptyCache,env, modelpath, false);
        env2 = Env.openScope(env_1, encflag, SOME(id));
        ci_state = ClassInf.start(restr, id);
        (_,env_2,_) = Inst.partialInstClassIn(Env.emptyCache,env2, Types.NOMOD(), Prefix.NOPRE(), Connect.emptySet, 
          ci_state, c, false, {});
        comps1 = getPublicComponentsInClass(cdef);
        s1 = getComponentsInfo(comps1, "\"public\"", env_2);
        comps2 = getProtectedComponentsInClass(cdef);
        s2 = getComponentsInfo(comps2, "\"protected\"", env_2);
        str = Util.stringDelimitListNoEmpty({s1,s2}, ",");
        res = Util.stringAppendList({"{",str,"}"});
      then
        res;
    case (_,_) then "Error"; 
  end matchcontinue;
end getComponents;

protected function getComponentAnnotations "function: getComponentAnnotations
  
   Thisfunction takes a `ComponentRef\', a `Program\' and
   returns a list of all component annotations, as returned by 
   get_nth_component_annotation.
   Both public and protected components are returned, but they need to
   be in the same order as get_componentsfunctions, i.e. first public 
   components then protected ones.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      list<Absyn.Element> comps1,comps2,comps;
      String s1,s2,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comps1 = getPublicComponentsInClass(cdef);
        comps2 = getProtectedComponentsInClass(cdef);
        comps = listAppend(comps1, comps2);
        s1 = getComponentAnnotationsFromElts(comps);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case (_,_) then "Error"; 
  end matchcontinue;
end getComponentAnnotations;

protected function getNthComponentAnnotation "function: getNthComponentAnnotation
  
   Thisfunction takes a `ComponentRef\', a `Program\' and an int and  
   returns a comma separated string of values corresponding to the flat 
   record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String s1,s2,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        s1 = getComponentAnnotation(comp);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthComponentAnnotation;

protected function getNthComponentModification "function: getNthComponentModification
 
  Thisfunction takes a `ComponentRef\', a `Program\' and an int and 
  returns a comma separated string of values corresponding to the 
  flat record for component annotations.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Element comp;
      String str,str_1;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        comp = getNthComponentInClass(cdef, n);
        str = getComponentModification(comp);
        str_1 = Util.stringAppendList({"{",str,"}"});
      then
        str_1;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthComponentModification;

protected function getConnectionCount "function: getConnectionCount
 
  Thisfunction takes a `ComponentRef\' and a `Program\' and returns a 
  string containing the number of connections in the model identified by 
  the `ComponentRef\'.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer numconn;
      String res;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        numconn = countConnections(cdef);
        res = intString(numconn);
      then
        res;
    case (_,_) then "Error"; 
  end matchcontinue;
end getConnectionCount;

protected function getNthConnection "function: getNthConnection
 
  Thisfunction takes a `ComponentRef\' and a `Program\' and an int and 
  returns a comma separated string for the nth connection, e.g. \"R1.n,C.p\".
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.Equation eq;
      Option<Absyn.Comment> cmt;
      String str2,str,res;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        Absyn.EQUATIONITEM(eq,cmt) = getNthConnectionitemInClass(cdef, n);
        str2 = getStringComment(cmt);
        str = getConnectionStr(eq);
        res = Util.stringAppendList({"{",str,", ",str2,"}"});
      then
        res;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthConnection;

protected function getStringComment "function: getStringComment
 
  Returns the string comment or empty string from a Comment option.
"
  input Option<Absyn.Comment> cmt;
  output String res;
  String s;
algorithm 
  s := getStringComment2(cmt);
  res := Util.stringAppendList({"\"",s,"\""});
end getStringComment;

protected function getStringComment2
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
    local String str;
    case (SOME(Absyn.COMMENT(_,SOME(str)))) then str; 
    case (_) then ""; 
  end matchcontinue;
end getStringComment2;

protected function addConnection "function: addConnection
 
  Adds a connect equation to the model, i..e connect(c1,c2)
 
  inputs: (Absyn.ComponentRef, /* model name */
             Absyn.ComponentRef, /* c1 */
             Absyn.ComponentRef, /* c2 */
             Absyn.NamedArg list, /* annotations */
             Absyn.Program) => 
  outputs: (string, Absyn.Program)
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input list<Absyn.NamedArg> inAbsynNamedArgLst4;
  input Absyn.Program inProgram5;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inAbsynNamedArgLst4,inProgram5)
    local
      Absyn.Path modelpath,package_;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;
      Option<Absyn.Comment> cmt;
      list<Absyn.NamedArg> nargs;
    case ((model_ as Absyn.CREF_IDENT(name = _)),c1,c2,{},(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE));
        newp = updateProgram(Absyn.PROGRAM({newcdef},w), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_QUAL(name = _)),c1,c2,{},(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),NONE));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_IDENT(name = _)),c1,c2,nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        cmt = annotationListToAbsynComment(nargs, NONE);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt));
        newp = updateProgram(Absyn.PROGRAM({newcdef},w), p);
      then
        ("Ok",newp);
    case ((model_ as Absyn.CREF_QUAL(name = _)),c1,c2,nargs,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        package_ = Absyn.stripLast(modelpath);
        cmt = annotationListToAbsynComment(nargs, NONE);
        newcdef = addToEquation(cdef, Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),cmt));
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(package_)), p);
      then
        ("Ok",newp);
  end matchcontinue;
end addConnection;

protected function deleteConnection "function: deleteConnection
 
  Delete the connection connect(c1,c2) from a model.
 
  inputs:  (Absyn.ComponentRef, /* model name */
              Absyn.ComponentRef, /* c1 */
              Absyn.ComponentRef, /* c2 */
              Absyn.Program)
  outputs:  (string,Absyn.Program) 
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inProgram4)
    local
      Absyn.Path modelpath,modelwithin;
      Absyn.Class cdef,newcdef;
      Absyn.Program newp,p;
      Absyn.ComponentRef model_,c1,c2;
      Absyn.Within w;
    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        modelwithin = Absyn.stripLast(modelpath);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.WITHIN(modelwithin)), p);
      then
        ("Ok",newp);
    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w)))
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        newcdef = deleteEquationInClass(cdef, c1, c2);
        newp = updateProgram(Absyn.PROGRAM({newcdef},Absyn.TOP()), p);
      then
        ("Ok",newp);
    case (model_,c1,c2,(p as Absyn.PROGRAM(within_ = w))) then ("Error",p); 
  end matchcontinue;
end deleteConnection;

protected function deleteEquationInClass "function: deleteEquationInClass
 
  Helperfunction to delete_connection.
"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inComponentRef2,inComponentRef3)
    local
      list<Absyn.EquationItem> eqlst,eqlst_1;
      list<Absyn.ClassPart> parts2,parts;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ComponentRef c1,c2;
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),c1,c2)
      equation 
        eqlst = getEquationList(parts);
        eqlst_1 = deleteEquationInEqlist(eqlst, c1, c2);
        parts2 = replaceEquationList(parts, eqlst_1);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
  end matchcontinue;
end deleteEquationInClass;

protected function deleteEquationInEqlist "function: deleteEquationInEqlist
 
  Helperfunction to delete_connection.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm 
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3)
    local
      Absyn.Path p1,p2,pn1,pn2;
      String s1,s2,sn1,sn2;
      list<Absyn.EquationItem> res,xs;
      Absyn.ComponentRef cn1,cn2,c1,c2;
      Absyn.EquationItem x;
    case ({},_,_) then {}; 
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = cn1,connector2 = cn2)) :: xs),c1,c2)
      equation 
        p1 = Absyn.crefToPath(c1);
        s1 = Absyn.pathString(p1);
        p2 = Absyn.crefToPath(c2);
        s2 = Absyn.pathString(p2);
        pn1 = Absyn.crefToPath(cn1);
        sn1 = Absyn.pathString(pn1);
        pn2 = Absyn.crefToPath(cn2);
        sn2 = Absyn.pathString(pn2);
        equality(s1 = sn1);
        equality(s2 = sn2);
        res = deleteEquationInEqlist(xs, c1, c2);
      then
        res;
    case ((x :: xs),c1,c2)
      equation 
        res = deleteEquationInEqlist(xs, c1, c2);
      then
        (x :: res);
  end matchcontinue;
end deleteEquationInEqlist;

protected function setComponentComment "function: setComponentComment
  author :PA
 
  Sets the component commment given by class name and ComponentRef.
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input String inString3;
  input Absyn.Program inProgram4;
  output String outString;
  output Absyn.Program outProgram;
algorithm 
  (outString,outProgram):=
  matchcontinue (inComponentRef1,inComponentRef2,inString3,inProgram4)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1;
      String cmt;
    case (class_,cr1,cmt,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setComponentCommentInClass(cdef, cr1, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        ("Ok",newp);
    case (class_,cr1,cmt,p) then ("Error",p); 
  end matchcontinue;
end setComponentComment;

protected function setComponentCommentInClass "function: setComponentCommentInClass
  author: PA
  
  Helperfunction to set_component_comment. 
"
  input Absyn.Class inClass;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inComponentRef,inString)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      Absyn.Info info;
      Absyn.ComponentRef cr1;
    case (Absyn.CLASS(name = name,partial_ = p,final_ = f,encapsulated_ = e,restricion = restr,body = Absyn.PARTS(classParts = parts,comment = pcmt),info = info),cr1,cmt)
      equation 
        parts_1 = setComponentCommentInParts(parts, cr1, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(parts_1,pcmt),info);
  end matchcontinue;
end setComponentCommentInClass;

protected function setComponentCommentInParts "function: setComponentCommentInParts
  author: PA
  
  Helperfunction to set_component_comment_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inComponentRef,inString)
    local
      list<Absyn.ElementItem> elts_1,elts,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.PUBLIC(contents = elts) :: xs),cr1,cmt)
      equation 
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PUBLIC(elts_1) :: xs);
    case ((Absyn.PUBLIC(contents = e) :: xs),cr1,cmt) /* rule above failed */ 
      equation 
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PUBLIC(e) :: xs_1);
    case ((Absyn.PROTECTED(contents = elts) :: xs),cr1,cmt)
      equation 
        elts_1 = setComponentCommentInElementitems(elts, cr1, cmt);
      then
        (Absyn.PROTECTED(elts_1) :: xs);
    case ((Absyn.PROTECTED(contents = e) :: xs),cr1,cmt) /* rule above failed */ 
      equation 
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (Absyn.PROTECTED(e) :: xs_1);
    case ((p :: xs),cr1,cmt)
      equation 
        xs_1 = setComponentCommentInParts(xs, cr1, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setComponentCommentInParts;

protected function setComponentCommentInElementitems "function: setComponentCommentInElementitems
  author: PA
  
  Helperfunction to set_component_parts. 
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inComponentRef,inString)
    local
      Absyn.ElementSpec spec_1,spec;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      String n,cmt;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> constr;
      list<Absyn.ElementItem> es,es_1;
      Absyn.ComponentRef cr1;
      Absyn.ElementItem e;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,name = n,specification = spec,info = info,constrainClass = constr)) :: es),cr1,cmt)
      equation 
        spec_1 = setComponentCommentInElementspec(spec, cr1, cmt);
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(f,r,inout,n,spec_1,info,constr)) :: es);
    case ((e :: es),cr1,cmt)
      equation 
        es_1 = setComponentCommentInElementitems(es, cr1, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setComponentCommentInElementitems;

protected function setComponentCommentInElementspec "function: setComponentCommentInElementspec
  author: PA
  
  Helperfunction to set_component_elementitems. 
"
  input Absyn.ElementSpec inElementSpec;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output Absyn.ElementSpec outElementSpec;
algorithm 
  outElementSpec:=
  matchcontinue (inElementSpec,inComponentRef,inString)
    local
      list<Absyn.ComponentItem> citems_1,citems;
      Absyn.ElementAttributes attr;
      Absyn.Path tp;
      Absyn.ComponentRef cr;
      String cmt;
    case (Absyn.COMPONENTS(attributes = attr,typeName = tp,components = citems),cr,cmt)
      equation 
        citems_1 = setComponentCommentInCompitems(citems, cr, cmt);
      then
        Absyn.COMPONENTS(attr,tp,citems_1);
  end matchcontinue;
end setComponentCommentInElementspec;

protected function setComponentCommentInCompitems "function: setComponentCommentInCompitems
  author: PA
  
  Helperfunction to set_component_elementspec. 
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Absyn.ComponentRef inComponentRef;
  input String inString;
  output list<Absyn.ComponentItem> outAbsynComponentItemLst;
algorithm 
  outAbsynComponentItemLst:=
  matchcontinue (inAbsynComponentItemLst,inComponentRef,inString)
    local
      Option<Absyn.Comment> compcmt_1,compcmt;
      String id,cmt;
      list<Absyn.Subscript> ad;
      Option<Absyn.Modification> mod;
      Option<Absyn.Exp> cond;
      list<Absyn.ComponentItem> cs,cs_1;
      Absyn.ComponentRef cr;
      Absyn.ComponentItem c;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id,arrayDim = ad,modification = mod),condition = cond,comment = compcmt) :: cs),cr,cmt)
      equation 
        true = Absyn.crefEqual(Absyn.CREF_IDENT(id,{}), cr);
        compcmt_1 = setClassCommentInCommentOpt(compcmt, cmt);
      then
        (Absyn.COMPONENTITEM(Absyn.COMPONENT(id,ad,mod),cond,compcmt_1) :: cs);
    case ((c :: cs),cr,cmt)
      equation 
        cs_1 = setComponentCommentInCompitems(cs, cr, cmt);
      then
        (c :: cs_1);
  end matchcontinue;
end setComponentCommentInCompitems;

protected function setConnectionComment "function: setConnectionComment
  author: PA
 
  Sets the nth connection comment.
"
  input Absyn.ComponentRef inComponentRef1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  input Absyn.Program inProgram5;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inComponentRef1,inComponentRef2,inComponentRef3,inString4,inProgram5)
    local
      Absyn.Path p_class;
      Absyn.Within within_;
      Absyn.Class cdef,cdef_1;
      Absyn.Program newp,p;
      Absyn.ComponentRef class_,cr1,cr2;
      String cmt;
    case (class_,cr1,cr2,cmt,p)
      equation 
        p_class = Absyn.crefToPath(class_);
        within_ = buildWithin(p_class);
        cdef = getPathedClassInProgram(p_class, p);
        cdef_1 = setConnectionCommentInClass(cdef, cr1, cr2, cmt);
        newp = updateProgram(Absyn.PROGRAM({cdef_1},within_), p);
      then
        (newp,"Ok");
    case (_,_,_,_,p) then (p,"Error"); 
  end matchcontinue;
end setConnectionComment;

protected function setConnectionCommentInClass "function: setConnectionCommentInClass
  author: PA
 
  Sets a connection comment in a Absyn.Class given two Absyn,ComponentRef
"
  input Absyn.Class inClass1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.ClassPart> parts_1,parts;
      String name,cmt;
      Boolean p,f,e;
      Absyn.Restriction restr;
      Option<String> pcmt;
      Absyn.Info info;
      Absyn.ComponentRef cr1,cr2;
    case (Absyn.CLASS(name = name,partial_ = p,final_ = f,encapsulated_ = e,restricion = restr,body = Absyn.PARTS(classParts = parts,comment = pcmt),info = info),cr1,cr2,cmt)
      equation 
        parts_1 = setConnectionCommentInParts(parts, cr1, cr2, cmt);
      then
        Absyn.CLASS(name,p,f,e,restr,Absyn.PARTS(parts_1,pcmt),info);
  end matchcontinue;
end setConnectionCommentInClass;

protected function setConnectionCommentInParts "function: setConnectionCommentInParts
  author: PA
 
  Helperfunction to set_connection_comment_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst1,inComponentRef2,inComponentRef3,inString4)
    local
      list<Absyn.EquationItem> e_1,e;
      list<Absyn.ClassPart> xs,xs_1;
      Absyn.ComponentRef cr1,cr2;
      String cmt;
      Absyn.ClassPart p;
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt)
      equation 
        e_1 = setConnectionCommentInEquations(e, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e_1) :: xs);
    case ((Absyn.EQUATIONS(contents = e) :: xs),cr1,cr2,cmt) /* rule above failed */ 
      equation 
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (Absyn.EQUATIONS(e) :: xs_1);
    case ((p :: xs),cr1,cr2,cmt)
      equation 
        xs_1 = setConnectionCommentInParts(xs, cr1, cr2, cmt);
      then
        (p :: xs_1);
  end matchcontinue;
end setConnectionCommentInParts;

protected function setConnectionCommentInEquations "function: setConnectionCommentInEquations
  author: PA
 
  Helperfunction to set_connection_comment_in_parts
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst1;
  input Absyn.ComponentRef inComponentRef2;
  input Absyn.ComponentRef inComponentRef3;
  input String inString4;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm 
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynEquationItemLst1,inComponentRef2,inComponentRef3,inString4)
    local
      Option<Absyn.Comment> eqcmt_1,eqcmt;
      Absyn.ComponentRef c1,c2,cr1,cr2;
      list<Absyn.EquationItem> es,es_1;
      String cmt;
      Absyn.EquationItem e;
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = c1,connector2 = c2),comment = eqcmt) :: es),cr1,cr2,cmt)
      equation 
        true = Absyn.crefEqual(cr1, c1);
        true = Absyn.crefEqual(cr2, c2);
        eqcmt_1 = setClassCommentInCommentOpt(eqcmt, cmt);
      then
        (Absyn.EQUATIONITEM(Absyn.EQ_CONNECT(c1,c2),eqcmt_1) :: es);
    case ((e :: es),cr1,cr2,cmt)
      equation 
        es_1 = setConnectionCommentInEquations(es, cr1, cr2, cmt);
      then
        (e :: es_1);
  end matchcontinue;
end setConnectionCommentInEquations;

protected function getNthConnectionAnnotation "function: getNthConnectionAnnotation
 
  Thisfunction takes a `ComponentRef\' and a `Program\' and an int and 
  returns a comma separated string  of values for the annotation of the 
  nth connection.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Absyn.EquationItem citem;
      String s1,s2,str;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        citem = getNthConnectionitemInClass(cdef, n);
        s1 = getConnectionAnnotationStr(citem);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case (_,_,_) then "{}"; 
  end matchcontinue;
end getNthConnectionAnnotation;

protected function getConnectorCount "function: getConnectorCount
 
  Thisfunction takes a ComponentRef and a Program and returns the number
  of connector components in the class given by the classname in the 
  ComponentRef. A partial instantiation of the inheritance structure is 
  performed in order to find all connectors of the class.
 
  inputs:  (/* Env.Env, */ Absyn.ComponentRef, 
              Absyn.Program) 
  outputs: string
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram)
    local
      Absyn.Path modelpath;
      Absyn.Class cdef;
      Integer count;
      String countstr;
      Absyn.ComponentRef model_;
      Absyn.Program p;
    case (model_,p)
      equation 
        modelpath = Absyn.crefToPath(model_) "A complete instantiation is far too expensive. Instead we only 
	  look through the components of the class for types declared using 
	  the \"connector\" restricted class keyword. We also look in
	  base classes  (recursively)  
	" ;
        cdef = getPathedClassInProgram(modelpath, p);
        count = countPublicConnectors(modelpath, p, cdef);
        countstr = intString(count);
      then
        countstr;
    case (_,_) then "Error"; 
  end matchcontinue;
end getConnectorCount;

protected function getNthConnector "function: getNthConnector
  Thisfunction takes a ComponentRef and a Program and an int and returns 
  a string with the name of the nth
  connector component in the class given by ComponentRef in the Program.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String str,tpstr,s1,resstr;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        (str,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        tpstr = Absyn.pathString(tp);
        s1 = stringAppend(str, ",");
        resstr = stringAppend(s1, tpstr);
      then
        resstr;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthConnector;

protected function getNthConnectorIconAnnotation "function: get_nth_connector
  
   Thisfunction takes a ComponentRef and a Program and an int and returns 
   a string with the name of the nth connectors icon annotation in the 
   class given by ComponentRef in the Program.
"
  input Absyn.ComponentRef inComponentRef;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inComponentRef,inProgram,inInteger)
    local
      Absyn.Path modelpath,tp;
      Absyn.Class cdef;
      String resstr;
      Absyn.ComponentRef model_;
      Absyn.Program p;
      Integer n;
    case (model_,p,n)
      equation 
        modelpath = Absyn.crefToPath(model_);
        cdef = getPathedClassInProgram(modelpath, p);
        (resstr,tp) = getNthPublicConnectorStr(modelpath, cdef, p, n);
        resstr = getIconAnnotation(tp, p);
      then
        resstr;
    case (_,_,_) then "Error"; 
  end matchcontinue;
end getNthConnectorIconAnnotation;

protected function getDiagramAnnotation "function: getDiagramAnnotation
 
  Thisfunction takes a Path and a Program and returns a comma separated 
  string of values for the diagram annotation for the class named by the 
  first argument.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation 
        cdef = getPathedClassInProgram(modelpath, p);
        str = getDiagramAnnotationInClass(cdef);
      then
        str;
    case (_,_) then "get_diagram_annotation failed!"; 
  end matchcontinue;
end getDiagramAnnotation;

protected function getDocumentationAnnotation "function: getDocumentationAnnotation
 
  Thisfunction takes a Path and a Program and returns a comma separated 
  string of values for the Documentation annotation for the class named by the 
  first argument.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation 
        cdef = getPathedClassInProgram(modelpath, p);
        str = getDocumentationAnnotationInClass(cdef);
      then
        str;
    case (_,_) then "{}"; 
  end matchcontinue;
end getDocumentationAnnotation;

protected function getIconAnnotation "function: getIconAnnotation
  Thisfunction takes a Path and a Program and returns a comma separated
  string of values for the icon annotation for the class named by the 
  first argument. 	
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation 
        cdef = getPathedClassInProgram(modelpath, p);
        str = getIconAnnotationInClass(cdef);
      then
        str;
    case (_,_) then ""; 
  end matchcontinue;
end getIconAnnotation;

protected function getPackagesInPath "function: getPackagesInPath
  
   Thisfunction takes a Path and a Program and returns a list of the 
   names of the packages found in the Path.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str,s1,res;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation 
        cdef = getPathedClassInProgram(modelpath, p);
        str = getPackagesInClass(modelpath, p, cdef);
        s1 = stringAppend("{", str);
        res = stringAppend(s1, "}");
      then
        res;
    case (_,_) then "Error"; 
  end matchcontinue;
end getPackagesInPath;

protected function getTopPackages "function: getTopPackages 
  
   Thisfunction takes a Path and a Program and returns a list of the 
   names of the packages found in the Path.
"
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProgram)
    local
      list<String> strlist;
      String str,s1,res;
      Absyn.Program p;
    case (p)
      equation 
        strlist = getTopPackagesInProgram(p);
        str = Util.stringDelimitList(strlist, ",");
        s1 = stringAppend("{", str);
        res = stringAppend(s1, "}");
      then
        res;
    case (_) then "Error"; 
  end matchcontinue;
end getTopPackages;

protected function getTopPackagesInProgram "function: getTopPackagesInProgram
 
  Helperfunction to get_top_packages.
"
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;
    case Absyn.PROGRAM(classes = {}) then {}; 
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id,restricion = Absyn.R_PACKAGE()) :: rest),within_ = w))
      equation 
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation 
        res = getTopPackagesInProgram(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopPackagesInProgram;

protected function getPackagesInClass "function: getPackagesInClass
  
   Thisfunction takes a `Class\' definition and a Path identifying 
   the class. It returns a string containing comma separated package
   names found in the class definition.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram,inClass)
    local
      list<String> strlist;
      String res;
      list<Absyn.ClassPart> parts;
      Option<String> cmt;
      Absyn.Class cdef;
      Absyn.Path newpath,inmodel,path;
      Absyn.Program p;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts,comment = cmt)))
      equation 
        strlist = getPackagesInParts(parts);
        res = Util.stringDelimitList(strlist, ",");
      then
        res;
    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(path = path)))
      equation 
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getPackagesInClass(newpath, p, cdef);
      then
        res;
  end matchcontinue;
end getPackagesInClass;

protected function getPackagesInParts "function: getPackagesInParts
 
  Helperfunction to get_packages_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        l1 = getPackagesInElts(elts);
        l2 = getPackagesInParts(rest);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest))
      equation 
        res = getPackagesInParts(rest);
      then
        res;
  end matchcontinue;
end getPackagesInParts;

protected function getPackagesInElts "function: getPackagesInElts
 
  Helperfunction to get_packages_in_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
    case {} then {}; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id,restricion = Absyn.R_PACKAGE())),constrainClass = NONE)) :: rest))
      equation 
        res = getPackagesInElts(rest);
      then
        (id :: res);
    case ((_ :: rest))
      equation 
        res = getPackagesInElts(rest);
      then
        res;
  end matchcontinue;
end getPackagesInElts;

protected function getClassnamesInPath "function: getClassnamesInPath
 
  Return a comma separated list of classes in a given Path.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String str,s1,res;
      Absyn.Path modelpath;
      Absyn.Program p;
    case (modelpath,p)
      equation 
        cdef = getPathedClassInProgram(modelpath, p);
        str = getClassnamesInClass(modelpath, p, cdef);
        s1 = stringAppend("{", str);
        res = stringAppend(s1, "}");
      then
        res;
    case (_,_) then "Error"; 
  end matchcontinue;
end getClassnamesInPath;

public function getTopClassnames "function: getTopClassnames
  
   Thisfunction takes a Path and a Program and returns a list of
   the names of the packages found at the top scope.
"
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProgram)
    local
      list<String> strlist;
      String str,s1,res;
      Absyn.Program p;
    case (p)
      equation 
        strlist = getTopClassnamesInProgram(p);
        str = Util.stringDelimitList(strlist, ",");
        s1 = stringAppend("{", str);
        res = stringAppend(s1, "}");
      then
        res;
    case (_) then "Error"; 
  end matchcontinue;
end getTopClassnames;

public function getTopClassnamesInProgram "function: getTopClassnamesInProgram
 
  Helperfunction to get_top_classnames.
"
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inProgram)
    local
      list<String> res;
      String id;
      list<Absyn.Class> rest;
      Absyn.Within w;
    case Absyn.PROGRAM(classes = {}) then {}; 
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w))
      equation 
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w));
      then
        (id :: res);
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation 
        res = getTopClassnamesInProgram(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopClassnamesInProgram;

protected function getTopQualifiedClassnames "adrpo added 2005-12-16
  function: getTopQualifiedClassnames
  
   Thisfunction takes a Program and returns a list of
   the fully top_qualified names of the packages found at the top scope.
   ex. within X.Y class Z -> X.Y.Z;
"
  input Absyn.Program inProgram;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProgram)
    local
      list<String> strlist;
      String str,s1,res;
      Absyn.Program p;
    case (p)
      equation 
        strlist = getTopQualifiedClassnamesInProgram(p);
        str = Util.stringDelimitList(strlist, ",");
        s1 = stringAppend("{", str);
        res = stringAppend(s1, "}");
      then
        res;
    case (_) then "Error"; 
  end matchcontinue;
end getTopQualifiedClassnames;

protected function getTopQualifiedClassnamesInProgram "adrpo added 2005-12-16
  function: getTopQualifiedClassnamesInProgram
 
  Helperfunction to get_top_qualified_classnames.
"
  input Absyn.Program inProgram;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inProgram)
    local
      String str_path,id;
      list<String> res,result;
      list<Absyn.Class> rest;
      Absyn.Within w;
    case Absyn.PROGRAM(classes = {}) then {}; 
    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: rest),within_ = w))
      equation 
        str_path = getQualified(id, w);
        res = getTopQualifiedClassnamesInProgram(Absyn.PROGRAM(rest,w));
        result = listAppend({str_path}, res);
      then
        result;
    case (Absyn.PROGRAM(classes = (_ :: rest),within_ = w))
      equation 
        res = getTopQualifiedClassnamesInProgram(Absyn.PROGRAM(rest,w));
      then
        res;
  end matchcontinue;
end getTopQualifiedClassnamesInProgram;

protected function getQualified "adrpo added 2005-12-16
  function: getQualified
 
  Helperfunction to get_top_qualified_classnames_in_program.
"
  input String inString;
  input Absyn.Within inWithin;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inString,inWithin)
    local
      String id,str_path,str_path1,result;
      Absyn.Path path;
    case (id,Absyn.TOP()) then id; 
    case (id,Absyn.WITHIN(path = path))
      equation 
        str_path = Absyn.pathString(path);
        str_path1 = stringAppend(str_path, ".");
        result = stringAppend(str_path1, id);
      then
        result;
  end matchcontinue;
end getQualified;

protected function getClassnamesInClass "function: getClassnamesInClass
  
   Thisfunction takes a `Class\' definition and a Path identifying the
   class. 
   It returns a string containing comma separated package names found 
   in the class definition.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inPath,inProgram,inClass)
    local
      list<String> strlist;
      String res;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef;
      Absyn.Path newpath,inmodel,path;
      Absyn.Program p;
    case (_,_,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        strlist = getClassnamesInParts(parts);
        res = Util.stringDelimitList(strlist, ",");
      then
        res;
    case (inmodel,p,Absyn.CLASS(body = Absyn.DERIVED(path = path)))
      equation 
        (cdef,newpath) = lookupClassdef(path, inmodel, p);
        res = getClassnamesInClass(newpath, p, cdef);
      then
        res;
  end matchcontinue;
end getClassnamesInClass;

protected function getClassnamesInParts "function: getClassnamesInParts
  
  Helperfunction to get_classnames_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<String> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        l1 = getClassnamesInElts(elts);
        l2 = getClassnamesInParts(rest);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest))
      equation 
        res = getClassnamesInParts(rest);
      then
        res;
  end matchcontinue;
end getClassnamesInParts;

public function getClassnamesInElts "function: getClassnamesInElts
 
  Helperfunction to get_classnames_in_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<String> res;
      String id;
      list<Absyn.ElementItem> rest;
    case {} then {}; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(name = id)),constrainClass = NONE)) :: rest))
      equation 
        res = getClassnamesInElts(rest);
      then
        (id :: res);
    case ((_ :: rest))
      equation 
        res = getClassnamesInElts(rest);
      then
        res;
  end matchcontinue;
end getClassnamesInElts;

protected function getBaseClasses "function: getBaseClasses
  
   Thisfunction gets all base classes of a class, NOT Recursive.
   It uses the environment to get the fully qualified names of the classes.
"
  input Absyn.Class inClass;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inClass,inEnv)
    local
      list<Absyn.ComponentRef> res;
      list<Absyn.ClassPart> parts;
      list<Env.Frame> env;
      Absyn.Path tp;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),env)
      equation 
        res = getBaseClassesFromParts(parts, env);
      then
        res;
    case (Absyn.CLASS(body = Absyn.DERIVED(path=tp)),env)
      local 
        Env.Env cenv;
        Absyn.Path envpath,p1;
        String tpname,str;
        Absyn.ComponentRef cref;
        SCode.Class c;
      equation
        (_,c,cenv) = Lookup.lookupClass(Env.emptyCache,env, tp, true);
        SOME(envpath) = Env.getEnvPath(cenv);
        tpname = Absyn.pathLastIdent(tp);
        p1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p1);
        str = Absyn.pathString(p1);
      then {cref};
    case (Absyn.CLASS(body = Absyn.DERIVED(path=tp)),env)
      local 
        Env.Env cenv;
        Absyn.Path envpath,p1;
        String tpname,str;
        Absyn.ComponentRef cref;

        SCode.Class c;
      equation
        (_,c,cenv) = Lookup.lookupClass(Env.emptyCache,env, tp, true);
        NONE = Env.getEnvPath(cenv);
        cref = Absyn.pathToCref(tp);
        then {cref};
    case (_,_) then {}; 
  end matchcontinue;
end getBaseClasses;

protected function getBaseClassesFromParts "function: getBaseClassesFromParts
 
  Helperfunction to get_base_classes.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inAbsynClassPartLst,inEnv)
    local
      list<Absyn.ComponentRef> c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      list<Env.Frame> env;
    case ((Absyn.PUBLIC(contents = elts) :: rest),env)
      equation 
        c1 = getBaseClassesFromElts(elts, env);
        c2 = getBaseClassesFromParts(rest, env);
        res = listAppend(c1, c2);
      then
        res;
    case ((_ :: rest),env)
      equation 
        res = getBaseClassesFromParts(rest, env);
      then
        res;
    case ({},env) then {}; 
  end matchcontinue;
end getBaseClassesFromParts;

protected function getBaseClassesFromElts "function: getBaseClassesFromElts
 
  Helperfunction to get_base_classes_from_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Env.Env inEnv;
  output list<Absyn.ComponentRef> outAbsynComponentRefLst;
algorithm 
  outAbsynComponentRefLst:=
  matchcontinue (inAbsynElementItemLst,inEnv)
    local
      list<Env.Frame> env,env_1;
      list<Absyn.ComponentRef> cl;
      SCode.Class c;
      Absyn.Path envpath,p_1,path;
      String tpname;
      Absyn.ComponentRef cref;
      list<Absyn.ElementItem> rest;
    case ({},env) then {}; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation 
        cl = getBaseClassesFromElts(rest, env) "Inherited class is defined inside package" ;
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache,env, path, true);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(path);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        cref = Absyn.pathToCref(p_1);
      then
        (cref :: cl);
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest),env)
      equation 
        cl = getBaseClassesFromElts(rest, env) "Inherited class defined on top level scope" ;
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache,env, path, true);
        NONE = Env.getEnvPath(env_1);
        cref = Absyn.pathToCref(path);
      then
        (cref :: cl);
    case ((_ :: rest),env)
      equation 
        cl = getBaseClassesFromElts(rest, env);
      then
        cl;
  end matchcontinue;
end getBaseClassesFromElts;

protected function countBaseClasses "function: countBaseClasses
  
   Thisfunction counts the number of base classes of a class
"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inClass)
    local
      Integer res;
      list<Absyn.ClassPart> parts;
      Absyn.Path tp;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        res = countBaseClassesFromParts(parts);
      then
        res;
    case (Absyn.CLASS(body = Absyn.DERIVED(path=tp))) then 1;
    case (_) then 0; 
  end matchcontinue;
end countBaseClasses;

protected function countBaseClassesFromParts "function: countBaseClassesFromParts
 
  Helperfunction to count_base_classes.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inAbsynClassPartLst)
    local
      Integer c1,c2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        c1 = countBaseClassesFromElts(elts);
        c2 = countBaseClassesFromParts(rest);
      then
        c1 + c2;
    case ((_ :: rest))
      equation 
        res = countBaseClassesFromParts(rest);
      then
        res;
    case ({}) then 0; 
  end matchcontinue;
end countBaseClassesFromParts;

protected function countBaseClassesFromElts "function: countBaseClassesFromElts
 
  Helperfunction to count_base_classes_from_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inAbsynElementItemLst)
    local
      Integer cl;
      Absyn.Path path;
      list<Absyn.ElementItem> rest;
    case ({}) then 0; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = path))) :: rest))
      equation 
        cl = countBaseClassesFromElts(rest) "Inherited class" ;
      then
        cl + 1;
    case ((_ :: rest))
      equation 
        cl = countBaseClassesFromElts(rest);
      then
        cl;
  end matchcontinue;
end countBaseClassesFromElts;

protected function getIconAnnotationInClass "function: getIconAnnotationInClass
 
  Helperfunction to get_icon_annotation.
"
  input Absyn.Class inClass;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementArg> annlst;
      String s1,s2,str;
      list<Absyn.ClassPart> parts;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        annlst = getIconAnnotationFromParts(parts) "class definitions" ;
        s1 = getIconAnnotationStr(annlst);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case (Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_))))) /* short class definitions */ 
      equation 
        s1 = getIconAnnotationStr(annlst);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
  end matchcontinue;
end getIconAnnotationInClass;

protected function getIconAnnotationFromParts "function: getIconAnnotationFromParts
 
  Helperfunction to get_icon_annotation_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementArg> res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
      list<Absyn.EquationItem> eqns;
      list<Absyn.AlgorithmItem> algs;
    case {} then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        res = getIconAnnotationFromElts(elts);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation 
        res = getIconAnnotationFromElts(elts);
      then
        res;
    case ((Absyn.EQUATIONS(contents = eqns) :: rest))
      equation 
        res = getIconAnnotationFromEqns(eqns);
      then
        res;
    case ((Absyn.INITIALEQUATIONS(contents = eqns) :: rest))
      equation 
        res = getIconAnnotationFromEqns(eqns);
      then
        res;
    case ((Absyn.ALGORITHMS(contents = algs) :: rest))
      equation 
        res = getIconAnnotationFromAlgs(algs);
      then
        res;
    case ((Absyn.INITIALALGORITHMS(contents = algs) :: rest))
      equation 
        res = getIconAnnotationFromAlgs(algs);
      then
        res;
    case ((_ :: rest))
      equation 
        res = getIconAnnotationFromParts(rest);
      then
        res;
  end matchcontinue;
end getIconAnnotationFromParts;

protected function getIconAnnotationFromElts "function: getIconAnnotationFromElts
 
  Helperfunction to get_icon_annotation_from_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.ElementItem> rest;
    case ((Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest))
      equation 
        containIconAnnotation(lst);
      then
        lst;
    case ((_ :: rest))
      equation 
        res = getIconAnnotationFromElts(rest);
      then
        res;
  end matchcontinue;
end getIconAnnotationFromElts;

protected function containIconAnnotation "function: containIconAnnotation
  
  Helperfunction to get_icon_annotation_from_elts.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
algorithm 
  _:=
  matchcontinue (inAbsynElementArgLst)
    local list<Absyn.ElementArg> lst;
    case ((Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon")) :: _)) then (); 
    case ((_ :: lst))
      equation 
        containIconAnnotation(lst);
      then
        ();
  end matchcontinue;
end containIconAnnotation;

protected function getIconAnnotationFromEqns "function: getIconAnnotationFromEqns
 
  Helperfunction to get_icon_annotation_from_parts.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynEquationItemLst)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.EquationItem> rest;
    case {} then {}; 
    case ((Absyn.EQUATIONITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest))
      equation 
        containIconAnnotation(lst);
      then
        lst;
    case ((_ :: rest))
      equation 
        res = getIconAnnotationFromEqns(rest);
      then
        res;
  end matchcontinue;
end getIconAnnotationFromEqns;

protected function getIconAnnotationFromAlgs "function: getIconAnnotationFromAlgs
 
  Helperfunction to get_icon_annotation_from_parts
"
  input list<Absyn.AlgorithmItem> inAbsynAlgorithmItemLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst;
algorithm 
  outAbsynElementArgLst:=
  matchcontinue (inAbsynAlgorithmItemLst)
    local
      list<Absyn.ElementArg> lst,res;
      list<Absyn.AlgorithmItem> rest;
    case {} then {}; 
    case ((Absyn.ALGORITHMITEMANN(annotation_ = Absyn.ANNOTATION(elementArgs = lst)) :: rest))
      equation 
        containIconAnnotation(lst);
      then
        lst;
    case ((_ :: rest))
      equation 
        res = getIconAnnotationFromAlgs(rest);
      then
        res;
  end matchcontinue;
end getIconAnnotationFromAlgs;

protected function getIconAnnotationStr "function: getIconAnnotationStr
 
  Helperfunction to get_icon_annotation_in_class.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementArgLst)
    local
      String str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
    case (((ann as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon"),modification = mod)) :: _))
      equation 
        str = getAnnotationString(iconProgram, Absyn.ANNOTATION({ann}));
      then
        str;
    case ((_ :: xs))
      equation 
        str = getIconAnnotationStr(xs);
      then
        str;
  end matchcontinue;
end getIconAnnotationStr;

protected function getDiagramAnnotationInClass "function: getDiagramAnnotationInClass
 
  Retrieve the diagram annotation as a string from the class passed as 
  argument.
"
  input Absyn.Class inClass;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementItem> publst,protlst,lst;
      String str,res;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> annlst;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        publst = getPublicList(parts) "class def." ;
        protlst = getProtectedList(parts);
        lst = listAppend(publst, protlst);
        str = getDiagramAnnotationInElementitemlist(lst);
      then
        str;
    case (Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))))
      equation 
        str = getDiagramAnnotationStr(annlst);
        res = Util.stringAppendList({"{",str,"}"});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end getDiagramAnnotationInClass;

protected function getDocumentationAnnotationInClass "function: getDocumentationAnnotationInClass
 
  Retrieve the documentation annotation as a string from the class passed as 
  argument.
"
  input Absyn.Class inClass;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementItem> publst,protlst,lst;
      String str,res;
      list<Absyn.ClassPart> parts;
      list<Absyn.ElementArg> annlst;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        publst = getPublicList(parts) "class def." ;
        protlst = getProtectedList(parts);
        lst = listAppend(publst, protlst);
        str = getDocumentationAnnotationInElementitemlist(lst);
      then
        str;
    case (Absyn.CLASS(body = Absyn.DERIVED(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION(annlst)),_)))))
      equation 
        str = getDocumentationAnnotationStr(annlst);
        res = Util.stringAppendList({"{",str,"}"});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end getDocumentationAnnotationInClass;

protected function getDiagramAnnotationInElementitemlist "function: getDiagramAnnotationInElementitemlist
 
  Retrieve the diagram annotation from an element item list passed as
  argument.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementItemLst)
    local
      String s1,s2,str;
      list<Absyn.ElementArg> annlst;
      list<Absyn.ElementItem> xs;
    case {} then ""; 
    case ((Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = annlst)) :: _))
      equation 
        s1 = getDiagramAnnotationStr(annlst);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case ((_ :: xs))
      equation 
        str = getDiagramAnnotationInElementitemlist(xs);
      then
        str;
  end matchcontinue;
end getDiagramAnnotationInElementitemlist;

protected function getDocumentationAnnotationInElementitemlist "function: getDocumentationAnnotationInElementitemlist
 
  Retrieve the into annotation from an element item list passed as
  argument.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementItemLst)
    local
      String s1,s2,str;
      list<Absyn.ElementArg> annlst;
      list<Absyn.ElementItem> xs;
    case {} then ""; 
    case ((Absyn.ANNOTATIONITEM(annotation_ = Absyn.ANNOTATION(elementArgs = annlst)) :: _))
      equation 
        s1 = getDocumentationAnnotationStr(annlst);
        s2 = stringAppend("{", s1);
        str = stringAppend(s2, "}");
      then
        str;
    case ((_ :: xs))
      equation 
        str = getDocumentationAnnotationInElementitemlist(xs);
      then
        str;
  end matchcontinue;
end getDocumentationAnnotationInElementitemlist;


protected function getDiagramAnnotationStr "function: getDiagramAnnotationStr
 
  Helperfunction to get_diagram_anonotation_in_elementitemlist.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementArgLst)
    local
      String str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
    case (((ann as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Diagram"),modification = mod)) :: _))
      equation 
        str = getAnnotationString(diagramProgram, Absyn.ANNOTATION({ann}));
      then
        str;
    case ((_ :: xs))
      equation 
        str = getDiagramAnnotationStr(xs);
      then
        str;
  end matchcontinue;
end getDiagramAnnotationStr;

protected function getDocumentationAnnotationStr "function: getDocumentationAnnotationStr
 
  Helperfunction to getDocumentationAnnotationInElementitemlist.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementArgLst)
    local
      String str;
      Absyn.ElementArg ann;
      Option<Absyn.Modification> mod;
      list<Absyn.ElementArg> xs;
    case (((ann as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Documentation"),modification = mod)) :: _))
      equation 
        str = getDocumentationAnnotationString(mod);
      then
        str;
    case ((_ :: xs))
      equation 
        str = getDocumentationAnnotationStr(xs);
      then
        str;
  end matchcontinue;
end getDocumentationAnnotationStr;

protected function getDocumentationAnnotationString
  input Option<Absyn.Modification> mod;
  output String docStr;
algorithm
  docStr := matchcontinue (mod)
  local list<Absyn.ElementArg> arglst; 
  case (SOME(Absyn.CLASSMOD(elementArgLst = arglst)))
  	local	
    list<String> strs;
    String s;
  	equation 
  	  strs = getDocumentationAnnotationString2(arglst);
  	  s = Util.stringDelimitList(strs,",");
   then 	s;
  case (_)
    then "";
  end matchcontinue;
end getDocumentationAnnotationString;       

protected function getDocumentationAnnotationString2 "Helper function to getDocumentationAnnotationString"
  input list<Absyn.ElementArg> eltArgs;
  output list<String> strs;
algorithm
  strs := matchcontinue (eltArgs) 
  local Absyn.Exp exp;
    list<Absyn.ElementArg> xs;
		case ({}) then {};
		case (Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "info"),
		  		modification=SOME(Absyn.CLASSMOD(expOption=SOME(exp))))::xs) 
		  local String s; list<String> ss;		
		  equation
		  		s = Dump.printExpStr(exp);
		  		ss = getDocumentationAnnotationString2(xs);
		  then s::ss;
		    
		case (Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "revisions"),
		  		modification=SOME(Absyn.CLASSMOD(expOption=SOME(exp))))::xs) 
		  local String s; list<String> ss;		
		  equation
		  		s = Dump.printExpStr(exp);
		  		ss = getDocumentationAnnotationString2(xs);
		  then s::ss;
		case (_::xs) 
      local list<String> ss;		
		  equation
		  		ss = getDocumentationAnnotationString2(xs);
		  then ss;
		end matchcontinue;
end getDocumentationAnnotationString2;

protected function getNthPublicConnectorStr "function: getNthPublicConnectorStr
 
  Helperfunction to get_nth_connector.
"
  input Absyn.Path inPath;
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm 
  (outString,outPath):=
  matchcontinue (inPath,inClass,inProgram,inInteger)
    local
      String str,a;
      Absyn.Path tp,modelpath;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Absyn.Program p;
      Integer n,c1,c2;
      Option<String> cmt;
      Absyn.Info file_info;
    case (modelpath,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst))),p,n)
      equation 
        (str,tp) = getNthConnectorStr(p, modelpath, elt, n);
      then
        (str,tp);
    case (modelpath,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info),p,n) /* The rule above failed, count the number of connectors in the first public list, subtract the number 
	   and try the rest of the list */ 
      equation 
        c1 = countPublicConnectors(modelpath, p, 
          Absyn.CLASS(a,b,c,d,e,Absyn.PARTS({Absyn.PUBLIC(elt)},cmt),file_info));
        c2 = n - c1;
        (str,tp) = getNthPublicConnectorStr(modelpath, 
          Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info), p, c2);
      then
        (str,tp);
    case (modelpath,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info),p,n)
      equation 
        (str,tp) = getNthPublicConnectorStr(modelpath, 
          Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info), p, n);
      then
        (str,tp);
  end matchcontinue;
end getNthPublicConnectorStr;

protected function getNthConnectorStr "function: getNthConnectorStr
  
   Thisfunction takes an ElementItem list and an int and  returns the name of the nth connector component
   in that list. 
"
  input Absyn.Program inProgram;
  input Absyn.Path inPath;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output String outString;
  output Absyn.Path outPath;
algorithm 
  (outString,outPath):=
  matchcontinue (inProgram,inPath,inAbsynElementItemLst,inInteger)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,tp,modelpath;
      String str;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      Integer n,c1,c2,newn;
      list<Absyn.ComponentItem> complst;
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE)) :: lst),n)
      equation 
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        (str,tp) = getNthPublicConnectorStr(newmodelpath, cdef, p, n);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE)) :: lst),n)
      equation 
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, c2);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeName = tp,components = complst),constrainClass = NONE)) :: lst),n)
      equation 
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        str = getNthCompname(complst, n);
      then
        (str,tp);
    case (p,modelpath,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeName = tp,components = complst),constrainClass = NONE)) :: lst),n)
      equation 
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p) "Not so fast, since we lookup and instantiate two times just because this was not 
	   the connector we were looking for." ;
        c1 = listLength(complst);
        newn = n - c1;
        (str,tp) = getNthConnectorStr(p, modelpath, lst, newn);
      then
        (str,tp);
    case (p,modelpath,(_ :: lst),n)
      equation 
        (str,tp) = getNthConnectorStr(p, modelpath, lst, n);
      then
        (str,tp);
    case (p,modelpath,{},n) then fail(); 
  end matchcontinue;
end getNthConnectorStr;

protected function getNthCompname "function: getNthCompname
  
  Returns the nth component name from a list of ComponentItem\'s.
  Index is from 1..n.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynComponentItemLst,inInteger)
    local
      String id,res;
      list<Absyn.ComponentItem> lst,xs;
      Integer n1,n;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = id)) :: lst),1) then id; 
    case ((_ :: xs),n)
      equation 
        n1 = n - 1;
        res = getNthCompname(xs, n1);
      then
        res;
    case ({},_) then fail(); 
  end matchcontinue;
end getNthCompname;

protected function countPublicConnectors "function: countPublicConnectors
  Thisfunction takes a Class and counts the number of connector 
  components in the class. This also includes counting in inherited classes.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inPath,inProgram,inClass)
    local
      Integer c1,c2,res;
      Absyn.Path modelpath,newmodelpath,cname;
      Absyn.Program p;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.Class cdef;
    case (modelpath,p,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info))
      equation 
        c1 = countPublicConnectors(modelpath, p, 
          Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        c2 = countConnectors(modelpath, p, elt);
      then
        c1 + c2;
    case (modelpath,p,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info))
      equation 
        res = countPublicConnectors(modelpath, p, 
          Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
      then
        res;
    case (modelpath,p,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt),info = file_info)) then 0; 
    case (modelpath,p,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.DERIVED(path = cname)))
      equation 
        (cdef,newmodelpath) = lookupClassdef(cname, modelpath, p);
        res = countPublicConnectors(newmodelpath, p, cdef);
      then
        res;
  end matchcontinue;
end countPublicConnectors;

protected function countConnectors "function: countConnectors
 
  Thisfunction takes a Path to the current model and a ElementItem list 
  and returns the number of connector components in that list.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inPath,inProgram,inAbsynElementItemLst)
    local
      Absyn.Class cdef;
      Absyn.Path newmodelpath,modelpath,tp;
      Integer c1,c2,res;
      Absyn.Program p;
      list<Absyn.ElementItem> lst;
      list<Absyn.ComponentItem> complst;
    case (modelpath,p,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.EXTENDS(path = tp),constrainClass = NONE)) :: lst))
      equation 
        (cdef,newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = countPublicConnectors(newmodelpath, p, cdef);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;
    case (modelpath,p,(Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(typeName = tp,components = complst),constrainClass = NONE)) :: lst))
      equation 
        (Absyn.CLASS(_,_,_,_,Absyn.R_CONNECTOR(),_,_),newmodelpath) = lookupClassdef(tp, modelpath, p);
        c1 = listLength(complst);
        c2 = countConnectors(modelpath, p, lst);
      then
        c1 + c2;
    case (modelpath,p,(_ :: lst)) /* Rule above didn\'t match => element not connector components, try rest of list */ 
      equation 
        res = countConnectors(modelpath, p, lst);
      then
        res;
    case (_,_,{}) then 0; 
  end matchcontinue;
end countConnectors;

protected function getConnectionAnnotationStr "function: getConnectionAnnotationStr
  
   Thisfunction takes an `EquationItem\' and returns a comma separated 
   string of values  from the flat record of a connection annotation that 
   is found in the `EquationItem\'.
"
  input Absyn.EquationItem inEquationItem;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEquationItem)
    local
      Absyn.FunctionArgs fargs;
      list<SCode.Class> p_1;
      list<Env.Frame> env;
      Exp.Exp newexp;
      String gexpstr;
      list<Absyn.ElementArg> elts;
    case (Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _),comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION({Absyn.MODIFICATION(_,_,Absyn.CREF_IDENT("Line",_),SOME(Absyn.CLASSMOD(elts,NONE)),_)})),_))))
      equation 
        fargs = createFuncargsFromElementargs(elts);
        p_1 = SCode.elaborate(lineProgram);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
        (_,newexp,_) = Static.elabGraphicsExp(Env.emptyCache,env, Absyn.CALL(Absyn.CREF_IDENT("Line",{}),fargs), false) "impl" ;
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = Exp.printExpStr(newexp);
      then
        gexpstr;
    case (Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _),comment = NONE)) then fail(); 
  end matchcontinue;
end getConnectionAnnotationStr;

protected function createFuncargsFromElementargs "function: create_functionargs_from_elementargs
 
  Trasform an ElementArg list to function argments. This is used when
  translating a graphical annotation to a record constructor.
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output Absyn.FunctionArgs outFunctionArgs;
algorithm 
  outFunctionArgs:=
  matchcontinue (inAbsynElementArgLst)
    local
      list<Absyn.Exp> expl;
      list<Absyn.NamedArg> narg;
      String id;
      Absyn.Exp exp;
      list<Absyn.ElementArg> xs;
    case ({}) then Absyn.FUNCTIONARGS({},{}); 
    case ((Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = id),modification = SOME(Absyn.CLASSMOD(_,SOME(exp)))) :: xs))
      equation 
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,(Absyn.NAMEDARG(id,exp) :: narg));
    case ((_ :: xs))
      equation 
        Absyn.FUNCTIONARGS(expl,narg) = createFuncargsFromElementargs(xs);
      then
        Absyn.FUNCTIONARGS(expl,narg);
  end matchcontinue;
end createFuncargsFromElementargs;

protected function getNthConnectionitemInClass "function: getNthConnectionitemInClass
  
   Thisfunction takes a `Class\' and  an int ane returns the nth 
   `EquationItem\' containing a connect statement in that class.
"
  input Absyn.Class inClass;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm 
  outEquationItem:=
  matchcontinue (inClass,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.ClassPart> parts;
      Integer n;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),n)
      equation 
        eq = getNthConnectionitemInClassparts(parts, n);
      then
        eq;
  end matchcontinue;
end getNthConnectionitemInClass;

protected function getNthConnectionitemInClassparts "function: getNthConnectionitemInClassparts
 
  Thisfunction takes a `ClassPart\' list and an int and returns 
  the nth connections as an `EquationItem\'.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm 
  outEquationItem:=
  matchcontinue (inAbsynClassPartLst,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.EquationItem> e;
      list<Absyn.ClassPart> xs;
      Integer n,c1,newn;
    case ((Absyn.EQUATIONS(contents = e) :: xs),n)
      equation 
        eq = getNthConnectionitemInEquations(e, n);
      then
        eq;
    case ((Absyn.EQUATIONS(contents = e) :: xs),n) /* The rule above failed, subtract the number of connections in the first equation section and try with the rest of the classparts */ 
      equation 
        c1 = countConnectionsInEquations(e);
        newn = n - c1;
        eq = getNthConnectionitemInClassparts(xs, newn);
      then
        eq;
    case ((_ :: xs),n)
      equation 
        eq = getNthConnectionitemInClassparts(xs, n);
      then
        eq;
  end matchcontinue;
end getNthConnectionitemInClassparts;

protected function getNthConnectionitemInEquations "function: get_nth_connection_in_equations
  
   Thisfunction takes  an `Equation\' list and an int and 
   returns the nth connection as an `Equation\'. If the number is 
   larger than the number of connections in the list, thefunction fails.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  input Integer inInteger;
  output Absyn.EquationItem outEquationItem;
algorithm 
  outEquationItem:=
  matchcontinue (inAbsynEquationItemLst,inInteger)
    local
      Absyn.EquationItem eq;
      list<Absyn.EquationItem> xs;
      Integer newn,n;
    case (((eq as Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _))) :: xs),1) then eq; 
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _)) :: xs),n)
      equation 
        newn = n - 1;
        eq = getNthConnectionitemInEquations(xs, newn);
      then
        eq;
    case ((_ :: xs),n)
      equation 
        eq = getNthConnectionitemInEquations(xs, n);
      then
        eq;
    case ({},_) then fail(); 
  end matchcontinue;
end getNthConnectionitemInEquations;

protected function getConnectionStr "function: getConnectionStr
  
   Thisfunction takes an `Equation\' assumed to contain a connection and 
   returns a comma separated string of componentreferences, e.g \"R1.n,C.p\" 
   for  connect(R1.n,C.p).
"
  input Absyn.Equation inEquation;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inEquation)
    local
      Absyn.Path p1,p2;
      String s1,s2,s3,str;
      Absyn.ComponentRef cr1,cr2;
    case Absyn.EQ_CONNECT(connector1 = cr1,connector2 = cr2)
      equation 
        s1 = Dump.printComponentRefStr(cr1);
        s2 = Dump.printComponentRefStr(cr2);
        str = Util.stringAppendList({s1,",",s2});
      then
        str;
  end matchcontinue;
end getConnectionStr;

protected function countConnections "function: countConnections
 
  Thisfunction takes a `Class\' and returns an int with the number of 
  connections in the `Class\'.
"
  input Absyn.Class inClass;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inClass)
    local
      Integer count;
      list<Absyn.ClassPart> parts;
    case Absyn.CLASS(body = Absyn.PARTS(classParts = parts))
      equation 
        count = countConnectionsInClassparts(parts);
      then
        count;
    case Absyn.CLASS(body = Absyn.DERIVED(path = _)) then 0; 
  end matchcontinue;
end countConnections;

protected function countConnectionsInClassparts "function: countConnectionsInClassparts
  
   Thisfunction takes a `ClassPart\' list and returns an int with the 
   number of connections in that list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inAbsynClassPartLst)
    local
      Integer r1,r2,res;
      list<Absyn.EquationItem> eqlist;
      list<Absyn.ClassPart> xs;
    case ((Absyn.EQUATIONS(contents = eqlist) :: xs))
      equation 
        r1 = countConnectionsInEquations(eqlist);
        r2 = countConnectionsInClassparts(xs);
      then
        r1 + r2;
    case ((_ :: xs))
      equation 
        res = countConnectionsInClassparts(xs);
      then
        res;
    case ({}) then 0; 
  end matchcontinue;
end countConnectionsInClassparts;

protected function countConnectionsInEquations "function: countConnectionsInEquations
  
   Thisfunction takes an `Equation\' list and returns  an int 
   with the number of connect statements in that list.
"
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output Integer outInteger;
algorithm 
  outInteger:=
  matchcontinue (inAbsynEquationItemLst)
    local
      Integer r1,res;
      list<Absyn.EquationItem> xs;
    case ((Absyn.EQUATIONITEM(equation_ = Absyn.EQ_CONNECT(connector1 = _)) :: xs))
      equation 
        r1 = countConnectionsInEquations(xs);
      then
        r1 + 1;
    case ((_ :: xs))
      equation 
        res = countConnectionsInEquations(xs);
      then
        res;
    case ({}) then 0; 
  end matchcontinue;
end countConnectionsInEquations;

protected function getComponentAnnotationsFromElts "function: getComponentAnnotationsFromElts
 
  Helperfunction to get_component_annotations.
"
  input list<Absyn.Element> comps;
  output String res_1;
  list<SCode.Class> p_1;
  list<Env.Frame> env;
  list<String> res;
  String res_1;
algorithm 
  p_1 := SCode.elaborate(placementProgram);
  (_,env) := Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(""));
  res := getComponentitemsAnnotations(comps, env);
  res_1 := Util.stringDelimitList(res, ",");
end getComponentAnnotationsFromElts;

protected function getComponentitemsAnnotations "function: getComponentitemsAnnotations
 
  Helperfunction to get_component_annotations_from_elts
"
  input list<Absyn.Element> inAbsynElementLst;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementLst,inEnv)
    local
      list<String> res1,res2,res;
      list<Absyn.ComponentItem> items;
      list<Absyn.Element> rest;
      list<Env.Frame> env;
    case ({},_) then {}; 
    case ((Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items)) :: rest),env)
      equation 
        res1 = getComponentitemsAnnotationsFromItems(items, env);
        res2 = getComponentitemsAnnotations(rest, env);
        res = listAppend(res1, res2);
      then
        res;
    case ((Absyn.ELEMENT(specification = Absyn.COMPONENTS(attributes = _)) :: rest),env)
      equation 
        res2 = getComponentitemsAnnotations(rest, env);
        res = listAppend({"{}"}, res2);
      then
        res;
    case ((_ :: rest),env)
      equation 
        res = getComponentitemsAnnotations(rest, env);
      then
        res;
  end matchcontinue;
end getComponentitemsAnnotations;

protected function getComponentitemsAnnotationsFromItems "function: getComponentitemsAnnotationsFromItems
 
  Helperfunction to get_componentitems_annotations.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynComponentItemLst,inEnv)
    local
      list<Env.Frame> env,env_1;
      SCode.Class c,c_1;
      SCode.Mod mod_1;
      Types.Mod mod_2;
      list<DAE.Element> dae,dae_1;
      Connect.Sets cs;
      tuple<Types.TType, Option<Absyn.Path>> t;
      ClassInf.State state;
      String gexpstr,gexpstr_1;
      list<String> res;
      list<Absyn.ElementArg> mod;
      list<Absyn.ComponentItem> rest;
    case ({},env) then {}; 
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((Absyn.MODIFICATION(_,_,Absyn.CREF_IDENT("Placement",_),SOME(Absyn.CLASSMOD(mod,NONE)),_) :: _))),_))) :: rest),env)
      equation 
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache,env, Absyn.IDENT("Placement"), false);
        mod_1 = SCode.buildMod(SOME(Absyn.CLASSMOD(mod,NONE)), false, Absyn.NON_EACH());
        (_,mod_2) = Mod.elabMod(Env.emptyCache,env_1, Prefix.NOPRE(), mod_1, false);
        c_1 = SCode.classSetPartial(c, false);
        (_,dae,_,cs,t,state) = Inst.instClass(Env.emptyCache,env_1, mod_2, Prefix.NOPRE(), Connect.emptySet, c_1, {}, 
          false, Inst.TOP_CALL());
        dae_1 = Inst.initVarsModelicaOutput(dae) "Put bindings of variables as expressions inside variable elements of the dae instead of equations" ;
        gexpstr = DAE.getVariableBindingsStr(dae_1);
        gexpstr_1 = Util.stringAppendList({"{",gexpstr,"}"});
        res = getComponentitemsAnnotationsFromItems(rest, env);
      then
        (gexpstr_1 :: res);
    case ((Absyn.COMPONENTITEM(comment = NONE) :: (rest as (_ :: _))),env)
      equation 
        res = getComponentitemsAnnotationsFromItems(rest, env);
      then
        ("{}" :: res);
    case ({Absyn.COMPONENTITEM(comment = NONE)},env) then {"{}"}; 
  end matchcontinue;
end getComponentitemsAnnotationsFromItems;

protected function getComponentAnnotation "function: getComponentAnnotation
 
  Thisfunction takes an `Element\' and returns a comma separated string 
  of values corresponding to the flat record for a component annotation. 
  If several components are declared within the eleement, a list of values
  is given for each of them.
"
  input Absyn.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst),constrainClass = NONE))
      equation 
        str = getComponentitemsAnnotation(lst);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end getComponentAnnotation;

protected function getComponentitemsAnnotation "function: getComponentitemsAnnotation
 
  Helperfunction to get_component_annotation.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,s2,s3,str,res;
      list<Absyn.ElementArg> mod;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(_,_,Absyn.CREF_IDENT("Placement",_),_,_) :: _)))),_))) :: (rest as (_ :: _))))
      equation 
        s1 = getAnnotationString(placementProgram, Absyn.ANNOTATION(mod));
        s2 = stringAppend("{", s1);
        s3 = stringAppend(s2, "},");
        str = getComponentitemsAnnotation(rest);
        res = stringAppend(s3, str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(SOME(Absyn.ANNOTATION((mod as (Absyn.MODIFICATION(_,_,Absyn.CREF_IDENT("Placement",_),_,_) :: _)))),_)))})
      equation 
        s1 = getAnnotationString(placementProgram, Absyn.ANNOTATION(mod));
        s2 = stringAppend("{", s1);
        res = stringAppend(s2, "}");
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = SOME(Absyn.COMMENT(NONE,_))) :: (rest as (_ :: _))))
      equation 
        str = getComponentitemsAnnotation(rest);
        res = stringAppend("{nada},", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(comment = NONE) :: (rest as (_ :: _))))
      equation 
        str = getComponentitemsAnnotation(rest);
        res = stringAppend("{},", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE)})
      equation 
        res = "{}";
      then
        res;
  end matchcontinue;
end getComponentitemsAnnotation;

public function getComponentModification "function: getComponentModification
  
   Thisfunction takes an `Element\' and returns a comma separated list of 
   Code expression for the modification of the component.
"
  input Absyn.Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      String str;
      list<Absyn.ComponentItem> lst;
    case (Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst),constrainClass = NONE))
      equation 
        str = getComponentitemsModification(lst);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end getComponentModification;

protected function getComponentitemsModification "function: getComponentitemsModification
 
  Helperfunction to get_component_modification.
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,s2,res,str;
      Absyn.Modification mod;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod))) :: (rest as (_ :: _))))
      equation 
        s1 = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
        s2 = getComponentitemsModification(rest);
        res = Util.stringAppendList({s1,",",s2});
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = SOME(mod)))})
      equation 
        res = Dump.printExpStr(Absyn.CODE(Absyn.C_MODIFICATION(mod)));
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE)) :: (rest as (_ :: _))))
      equation 
        str = getComponentitemsModification(rest);
        res = stringAppend("Code(),", str);
      then
        res;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(modification = NONE)) :: (rest as (_ :: _))))
      equation 
        str = getComponentitemsModification(rest);
        res = stringAppend("Code(),", str);
      then
        res;
    case ({Absyn.COMPONENTITEM(comment = NONE)})
      equation 
        res = "Code()";
      then
        res;
  end matchcontinue;
end getComponentitemsModification;

protected function getAnnotationString "function_ getAnnotationString
  
   Thisfunction takes an annotation and returns a comma separates string 
   of values representing the flat record of the specific annotation.
   Thefunction as two special rules for handling of Icon and Diagram 
   annotations since these two contain graphic primitives, which must be
   handled specially because Modelica does not have the possibility to store 
   polymorphic values (e.g. different record classes with the same baseclass)
   in for instance an array.
"
  input Absyn.Program inProgram;
  input Absyn.Annotation inAnnotation;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inProgram,inAnnotation)
    local
      list<Absyn.ElementArg> stripmod,mod,gxmods;
      Absyn.Exp graphicexp;
      SCode.Mod mod_1;
      list<SCode.Class> p_1;
      list<Env.Frame> env;
      Absyn.Class placementc;
      SCode.Class placementclass;
      Types.Mod mod_2;
      list<DAE.Element> dae,dae_1;
      Connect.Sets cs;
      tuple<Types.TType, Option<Absyn.Path>> t;
      ClassInf.State state;
      String str,gexpstr,s1,totstr,anncname;
      Exp.Exp graphicexp2;
      Types.Properties prop;
      Absyn.Program p;
    case (p,Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon"),modification = SOME(Absyn.CLASSMOD(mod,_)))}))
      equation 
        (stripmod,{Absyn.MODIFICATION(_,_,_,SOME(Absyn.CLASSMOD(_,SOME(graphicexp))),_)}) = stripGraphicsModification(mod);
        mod_1 = SCode.buildMod(SOME(Absyn.CLASSMOD(stripmod,NONE)), false, 
          Absyn.NON_EACH());
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeSimpleEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT("Icon"));
        placementc = getClassInProgram("Icon", p);
        placementclass = SCode.elabClass(placementc);
        (_,mod_2) = Mod.elabMod(Env.emptyCache,env, Prefix.NOPRE(), mod_1, false);
        (_,dae,_,cs,t,state) = Inst.instClass(Env.emptyCache,env, mod_2, Prefix.NOPRE(), Connect.emptySet, 
          placementclass, {}, false, Inst.TOP_CALL());
        dae_1 = Inst.initVarsModelicaOutput(dae) "Put bindings of variables as expressions inside variable elements of the dae instead of equations" ;
        str = DAE.getVariableBindingsStr(dae_1);
        (_,graphicexp2,prop) = Static.elabGraphicsExp(Env.emptyCache,env, graphicexp, false) "impl" ;
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = Exp.printExpStr(graphicexp2);
        s1 = stringAppend(str, ",");
        totstr = stringAppend(s1, gexpstr);
      then
        totstr;
    case (p,Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Icon"),modification = SOME(Absyn.CLASSMOD(mod,_)))})) /* First line in the first rule above fails if return value from strip_graphics_modification doesn\'t match the rhs of => */ 
      equation 
        (stripmod,gxmods) = stripGraphicsModification(mod);
        mod_1 = SCode.buildMod(SOME(Absyn.CLASSMOD(stripmod,NONE)), false, 
          Absyn.NON_EACH());
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeSimpleEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT("Icon"));
        placementc = getClassInProgram("Icon", p);
        placementclass = SCode.elabClass(placementc);
        (_,mod_2) = Mod.elabMod(Env.emptyCache,env, Prefix.NOPRE(), mod_1, true);
        (_,dae,_,cs,t,state) = Inst.instClass(Env.emptyCache,env, mod_2, Prefix.NOPRE(), Connect.emptySet, 
          placementclass, {}, false, Inst.TOP_CALL());
        dae_1 = Inst.initVarsModelicaOutput(dae) "Put bindings of variables as expressions inside variable elements of the dae instead of equations" ;
        str = DAE.getVariableBindingsStr(dae_1);
      then
        str;
    case (p,Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "Diagram"),modification = SOME(Absyn.CLASSMOD(mod,_)))}))
      equation 
        (stripmod,{Absyn.MODIFICATION(_,_,_,SOME(Absyn.CLASSMOD(_,SOME(graphicexp))),_)}) = stripGraphicsModification(mod);
        mod_1 = SCode.buildMod(SOME(Absyn.CLASSMOD(stripmod,NONE)), false, 
          Absyn.NON_EACH());
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT("Diagram"));
        placementc = getClassInProgram("Diagram", p);
        placementclass = SCode.elabClass(placementc);
        (_,mod_2) = Mod.elabMod(Env.emptyCache,env, Prefix.NOPRE(), mod_1, false);
        (_,dae,_,cs,t,state) = Inst.instClass(Env.emptyCache,env, mod_2, Prefix.NOPRE(), Connect.emptySet, 
          placementclass, {}, false, Inst.TOP_CALL());
        dae_1 = Inst.initVarsModelicaOutput(dae) "Put bindings of variables as expressions inside variable elements of the dae instead of equations" ;
        str = DAE.getVariableBindingsStr(dae_1);
        (_,graphicexp2,prop) = Static.elabGraphicsExp(Env.emptyCache,env, graphicexp, false) "impl" ;
        Print.clearErrorBuf() "this is to clear the error-msg generated by the annotations." ;
        gexpstr = Exp.printExpStr(graphicexp2);
        s1 = stringAppend(str, ",");
        totstr = stringAppend(s1, gexpstr);
      then
        totstr;
    case (p,Absyn.ANNOTATION(elementArgs = {Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = anncname),modification = SOME(Absyn.CLASSMOD(mod,_)))}))
      equation 
        mod_1 = SCode.buildMod(SOME(Absyn.CLASSMOD(mod,NONE)), false, Absyn.NON_EACH());
        p_1 = SCode.elaborate(p);
        (_,env) = Inst.makeEnvFromProgram(Env.emptyCache,p_1, Absyn.IDENT(anncname));
        placementc = getClassInProgram(anncname, p);
        placementclass = SCode.elabClass(placementc);
        (_,mod_2) = Mod.elabMod(Env.emptyCache,env, Prefix.NOPRE(), mod_1, false);
        (_,dae,_,cs,t,state) = Inst.instClass(Env.emptyCache,env, mod_2, Prefix.NOPRE(), Connect.emptySet, 
          placementclass, {}, false, Inst.TOP_CALL());
        dae_1 = Inst.initVarsModelicaOutput(dae) "Put bindings of variables as expressions inside variable elements of the dae instead of equations" ;
        str = DAE.getVariableBindingsStr(dae_1);
      then
        str;
    case (_,_)
      equation 
        Print.printBuf("get_annotation_string failed!\n");
      then
        fail();
  end matchcontinue;
end getAnnotationString;

protected function stripGraphicsModification "function: stripGraphicsModification
   
   Thisfunction strips out the `graphics\' modification from an ElementArg 
   list and return two lists, one with the other modifications and the 
   second with the `graphics\' modification
"
  input list<Absyn.ElementArg> inAbsynElementArgLst;
  output list<Absyn.ElementArg> outAbsynElementArgLst1;
  output list<Absyn.ElementArg> outAbsynElementArgLst2;
algorithm 
  (outAbsynElementArgLst1,outAbsynElementArgLst2):=
  matchcontinue (inAbsynElementArgLst)
    local
      Absyn.ElementArg mod;
      list<Absyn.ElementArg> rest,l1,l2;
    case (((mod as Absyn.MODIFICATION(componentReg = Absyn.CREF_IDENT(name = "graphics"))) :: rest)) then (rest,{mod}); 
    case (((mod as Absyn.MODIFICATION(finalItem = _)) :: rest))
      equation 
        (l1,l2) = stripGraphicsModification(rest);
      then
        ((mod :: l1),l2);
    case ({}) then ({},{}); 
  end matchcontinue;
end stripGraphicsModification;

public function getComponentsInClass "function: getComponentsInClass
   
   Both public and protected lists are searched.
"
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm 
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt))) then {}; 
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in public list */ 
      equation 
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in protected list */ 
      equation 
        lst1 = getComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (_) then {}; 
  end matchcontinue;
end getComponentsInClass;

protected function getPublicComponentsInClass "function: getPublicComponentsInClass
   
   Public lists are searched.
"
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm 
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt))) then {}; 
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in public list */ 
      equation 
        lst1 = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info))
      equation 
        res = getPublicComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
      then
        res;
    case (_) then {}; 
  end matchcontinue;
end getPublicComponentsInClass;

protected function getProtectedComponentsInClass "function: getProtectedComponentsInClass
   
   Protected lists are searched.
"
  input Absyn.Class inClass;
  output list<Absyn.Element> outAbsynElementLst;
algorithm 
  outAbsynElementLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.Element> lst1,lst2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> lst;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt))) then {}; 
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in protected list */ 
      equation 
        lst1 = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst2 = getComponentsInElementitems(elts);
        res = listAppend(lst2, lst1);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info))
      equation 
        res = getProtectedComponentsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
      then
        res;
    case (_) then {}; 
  end matchcontinue;
end getProtectedComponentsInClass;

protected function getComponentsInElementitems "function: getComponentsInElementitems
 
  Helperfunction to get_components_in_class.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Element> outAbsynElementLst;
algorithm 
  outAbsynElementLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.Element> res;
      Absyn.Element elt;
      list<Absyn.ElementItem> rest;
    case ({}) then {}; 
    case ((Absyn.ELEMENTITEM(element = elt) :: rest))
      equation 
        res = getComponentsInElementitems(rest);
      then
        (elt :: res);
    case ((_ :: rest))
      equation 
        res = getComponentsInElementitems(rest);
      then
        res;
  end matchcontinue;
end getComponentsInElementitems;

protected function getNthComponentInClass "function: getNthComponentInClass
 
  Returns the nth Component of a class. Indexed from 1..n.
"
  input Absyn.Class inClass;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inClass,inInteger)
    local
      Integer count,n,c1,newn;
      Absyn.Element res;
      String a,newnstr;
      Boolean b,c,d;
      Absyn.Restriction e;
      list<Absyn.ElementItem> elt;
      list<Absyn.ClassPart> lst,rest;
      Option<String> cmt;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: lst),comment = cmt),info = file_info),n)
      equation 
        count = countComponentsInElts(elt);
        (n <= count) = true;
        res = getNthComponentInElementitems(elt, n);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elt) :: rest),comment = cmt),info = file_info),n) /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */ 
      equation 
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        newnstr = intString(newn);
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(rest,cmt),file_info), 
          newn);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: lst),comment = cmt),info = file_info),n)
      equation 
        res = getNthComponentInElementitems(elt, n);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elt) :: rest),comment = cmt),info = file_info),n) /* The rule above failed, i.e the nth number is larger than # elements in first public list subtract and try next public list */ 
      equation 
        c1 = countComponentsInElts(elt);
        newn = n - c1;
        (newn > 0) = true;
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(rest,cmt),file_info), 
          newn);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (_ :: lst),comment = cmt),info = file_info),n)
      equation 
        res = getNthComponentInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info), n);
      then
        res;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt),info = file_info),_) then fail(); 
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.DERIVED(path = _),info = file_info),_) then fail(); 
  end matchcontinue;
end getNthComponentInClass;

public function getElementitemsInClass "function: getElementitemsInClass
   
   Both public and protected lists are searched.
"
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inClass)
    local
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      list<Absyn.ElementItem> lst1,lst,elts;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = {},comment = cmt))) then {}; 
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PUBLIC(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in public list */ 
      equation 
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst = listAppend(elts, lst1);
      then
        lst;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = (Absyn.PROTECTED(contents = elts) :: lst),comment = cmt),info = file_info)) /* Search in protected list */ 
      equation 
        lst1 = getElementitemsInClass(Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(lst,cmt),file_info));
        lst = listAppend(elts, lst1);
      then
        lst;
    case (_) then {}; 
  end matchcontinue;
end getElementitemsInClass;

protected function getNthComponentInElementitems "function: get_nth_component_in_elementintems 
  
   Thisfunction takes an `ElementItem\' list and and integer and returns 
   the nth component in the list, indexed from 1..n.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Integer inInteger;
  output Absyn.Element outElement;
algorithm 
  outElement:=
  matchcontinue (inAbsynElementItemLst,inInteger)
    local
      Boolean a;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.InnerOuter c;
      String d;
      Absyn.ElementAttributes e;
      Absyn.Path f;
      Absyn.ComponentItem elt;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> i;
      Integer numcomps,newn,n,n_1;
      Absyn.Element res;
      list<Absyn.ComponentItem> lst;
      list<Absyn.ElementItem> rest;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = a,redeclareKeywords = b,innerOuter = c,name = d,specification = Absyn.COMPONENTS(attributes = e,typeName = f,components = (elt :: _)),info = info,constrainClass = i)) :: _),1) then Absyn.ELEMENT(a,b,c,d,Absyn.COMPONENTS(e,f,{elt}),info,i); 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = lst))) :: rest),n)
      equation 
        numcomps = listLength(lst);
        (n > numcomps) = true;
        newn = n - numcomps;
        res = getNthComponentInElementitems(rest, newn);
      then
        res;
    case ((Absyn.ELEMENTITEM(element = (elt as Absyn.ELEMENT(final_ = a,redeclareKeywords = b,innerOuter = c,name = d,specification = Absyn.COMPONENTS(attributes = e,typeName = f,components = lst),info = info,constrainClass = i))) :: rest),n)
      equation 
        numcomps = listLength(lst);
        (n <= numcomps) = true;
        n_1 = n - 1;
        elt = listNth(lst, n_1);
      then
        Absyn.ELEMENT(a,b,c,d,Absyn.COMPONENTS(e,f,{elt}),info,i);
    case ((_ :: rest),n)
      equation 
        res = getNthComponentInElementitems(rest, n);
      then
        res;
    case ({},_) then fail(); 
  end matchcontinue;
end getNthComponentInElementitems;

protected function getComponentsInfo "function: getComponentsInfo
 
  Helperfunction to get_components.
  Return all the info as a comma separated list of values.
  get_component_info => {{name, type, comment, access, final, flow, 
  replaceable, variability,innerouter,vardirection},..}
  where access is one of: \"public\", \"protected\"
  where final is one of: true, false
  where flow is one of: true, false
  where replaceable is one of: true, false
  where variability is one of: \"constant\", \"parameter\", \"discrete\" 
   or \"unspecified\"
  where innerouter is one of: \"inner\", \"outer\", (\"innerouter\") or \"none\"
  where vardirection is one of: \"input\", \"output\" or \"unspecified\".
 
  inputs:  (Absyn.Element list,
              string, /* \"public\" or \"protected\" */
              Env.Env)
  outputs:  string
"
  input list<Absyn.Element> inAbsynElementLst;
  input String inString;
  input Env.Env inEnv;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynElementLst,inString,inEnv)
    local
      list<String> lst;
      String lst_1,res,access;
      list<Absyn.Element> elts;
      list<Env.Frame> env;
    case (elts,access,env)
      equation 
        ((lst as (_ :: _))) = getComponentsInfo2(elts, access, env);
        lst_1 = Util.stringDelimitList(lst, "},{");
        res = Util.stringAppendList({"{",lst_1,"}"});
      then
        res;
    case (_,_,_) then ""; 
  end matchcontinue;
end getComponentsInfo;

protected function getComponentsInfo2 "function: getComponentsInfo2
 
  Helperfunction to get_components_info
 
  inputs: (Absyn.Element list, 
             string, /* \"public\" or \"protected\" */
             Env.Env)  
  outputs: string list 
"
  input list<Absyn.Element> inAbsynElementLst;
  input String inString;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynElementLst,inString,inEnv)
    local
      list<String> lst1,lst2,res;
      Absyn.Element elt;
      list<Absyn.Element> rest;
      String access;
      list<Env.Frame> env;
    case ({},_,_) then {}; 
    case ((elt :: rest),access,env)
      equation 
        lst1 = getComponentInfo(elt, access, env);
        lst2 = getComponentsInfo2(rest, access, env);
        res = listAppend(lst1, lst2);
      then
        res;
  end matchcontinue;
end getComponentsInfo2;

protected function getComponentInfo "function: getComponentInfo
  
   Thisfunction takes an `Element\' and returns a list of strings 
   of comma separated values of the 
   type and name and comment, and attributes of  of the component, 
   If Element is not a component, the empty string is returned
  
   inputs: (Absyn.Element,
              string, /* \"public\" or \"protected\" */
              Env.Env) 
   outputs: string list
"
  input Absyn.Element inElement;
  input String inString;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inElement,inString,inEnv)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env;
      Absyn.Path envpath,p_1,p;
      String tpname,typename,final_,repl,inout_str,flow_str,variability_str,dir_str,str,access;
      list<String> names,lst,lst_1;
      Boolean r_1,f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.ElementAttributes attr;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.COMPONENTS(attributes = attr,typeName = p,components = lst)),access,env)
      equation 
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache,env, p, true);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(p);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        typename = Absyn.pathString(p_1);
        names = getComponentitemsName(lst);
        lst = prefixTypename(typename, names);
        final_ = Util.boolString(f);
        r_1 = keywordReplaceable(r);
        repl = Util.boolString(r_1);
        inout_str = innerOuterStr(inout);
        flow_str = attrFlowStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        str = Util.stringDelimitList(
          {access,final_,flow_str,repl,variability_str,inout_str,
          dir_str}, ", ");
        lst_1 = suffixInfos(lst, str);
      then
        lst_1;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.COMPONENTS(attributes = attr,typeName = p,components = lst)),access,env)
      equation 
        typename = Absyn.pathString(p);
        names = getComponentitemsName(lst);
        lst = prefixTypename(typename, names);
        final_ = Util.boolString(f);
        r_1 = keywordReplaceable(r);
        repl = Util.boolString(r_1);
        inout_str = innerOuterStr(inout);
        flow_str = attrFlowStr(attr);
        variability_str = attrVariabilityStr(attr);
        dir_str = attrDirectionStr(attr);
        str = Util.stringDelimitList(
          {access,final_,flow_str,repl,variability_str,inout_str,
          dir_str}, ", ");
        lst_1 = suffixInfos(lst, str);
      then
        lst_1;
    case (_,_,env) then {}; 
    case (_,_,_)
      equation 
        print("get_component_info failed\n");
      then
        fail();
  end matchcontinue;
end getComponentInfo;

protected function keywordReplaceable "function: keywordReplaceable 
 
  Returns true if RedeclareKeywords contains replaceable.
"
  input Option<Absyn.RedeclareKeywords> inAbsynRedeclareKeywordsOption;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inAbsynRedeclareKeywordsOption)
    case (SOME(Absyn.REPLACEABLE())) then true; 
    case (SOME(Absyn.REDECLARE_REPLACEABLE())) then true; 
    case (_) then false; 
  end matchcontinue;
end keywordReplaceable;

protected function getComponentInfoOld "function: getComponentInfoOld
  
   Thisfunction takes an `Element\' and returns a list of strings 
   of comma separated values of the 
    type and name and comment of the component, e.g. \'Resistor,R1, \"comment\"\' 
   or \'Resistor,R1,\"comment1\",R2,\"comment2\"\'
   If Element is not a component, the empty string is returned
"
  input Absyn.Element inElement;
  input Env.Env inEnv;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inElement,inEnv)
    local
      SCode.Class c;
      list<Env.Frame> env_1,env;
      Absyn.Path envpath,p_1,p;
      String tpname,typename;
      list<String> names,lst;
      Boolean f;
      Option<Absyn.RedeclareKeywords> r;
      Absyn.InnerOuter inout;
      Absyn.ElementAttributes attr;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.COMPONENTS(attributes = attr,typeName = p,components = lst)),env)
      equation 
        (_,c,env_1) = Lookup.lookupClass(Env.emptyCache,env, p, true);
        SOME(envpath) = Env.getEnvPath(env_1);
        tpname = Absyn.pathLastIdent(p);
        p_1 = Absyn.joinPaths(envpath, Absyn.IDENT(tpname));
        typename = Absyn.pathString(p_1);
        names = getComponentitemsName(lst);
        lst = prefixTypename(typename, names);
      then
        lst;
    case (Absyn.ELEMENT(final_ = f,redeclareKeywords = r,innerOuter = inout,specification = Absyn.COMPONENTS(attributes = attr,typeName = p,components = lst)),env)
      equation 
        typename = Absyn.pathString(p);
        names = getComponentitemsName(lst);
        lst = prefixTypename(typename, names);
      then
        lst;
    case (_,env) then {}; 
    case (_,_)
      equation 
        print("get_component_info_old failed\n");
      then
        fail();
  end matchcontinue;
end getComponentInfoOld;

protected function innerOuterStr "function: innerOuterStr
 
  Helperfunction to get_component_info, retrieve the inner outer string.
"
  input Absyn.InnerOuter inInnerOuter;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInnerOuter)
    case (Absyn.INNER()) then "\"inner\""; 
    case (Absyn.OUTER()) then "\"outer\""; 
    case (Absyn.UNSPECIFIED()) then "\"none\""; 
    case (Absyn.INNEROUTER()) then "\"innerouter\""; 
  end matchcontinue;
end innerOuterStr;

protected function attrFlowStr "function: attrFlowStr
 
  Helperfunction to get_component_info, retrieve flow attribite as bool 
  string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementAttributes)
    local
      String res;
      Boolean f;
    case (Absyn.ATTR(flow_ = f))
      equation 
        res = Util.boolString(f);
      then
        res;
  end matchcontinue;
end attrFlowStr;

protected function attrVariabilityStr "function: attrVariabilityStr
 
  Helperfunction to get_component_info, retrieve variability as a 
  string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementAttributes)
    case (Absyn.ATTR(variability = Absyn.VAR())) then "\"unspecified\""; 
    case (Absyn.ATTR(variability = Absyn.DISCRETE())) then "\"discrete\""; 
    case (Absyn.ATTR(variability = Absyn.PARAM())) then "\"parameter\""; 
    case (Absyn.ATTR(variability = Absyn.CONST())) then "\"constant\""; 
  end matchcontinue;
end attrVariabilityStr;

protected function attrDirectionStr "function: attrDirectionStr
 
  Helperfunction to get_component_info, retrieve direction as a 
  string.
"
  input Absyn.ElementAttributes inElementAttributes;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementAttributes)
    case (Absyn.ATTR(direction = Absyn.INPUT())) then "\"input\""; 
    case (Absyn.ATTR(direction = Absyn.OUTPUT())) then "\"output\""; 
    case (Absyn.ATTR(direction = Absyn.BIDIR())) then "\"unspecified\""; 
  end matchcontinue;
end attrDirectionStr;

protected function suffixInfos "function: suffixInfos
 
  Helperfunction to get_component_info. Add suffix info to 
  element names, etc.
"
  input list<String> inStringLst;
  input String inString;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inStringLst,inString)
    local
      list<String> res,rest;
      String str_1,str,suffix;
    case ({},_) then {}; 
    case ((str :: rest),suffix)
      equation 
        res = suffixInfos(rest, suffix);
        str_1 = Util.stringAppendList({str,", ",suffix});
      then
        (str_1 :: res);
  end matchcontinue;
end suffixInfos;

protected function prefixTypename "function: prefixTypename 
 
  Helperfunction to get_component_info. Add a prefix typename to each
  string in the list.
"
  input String inString;
  input list<String> inStringLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inString,inStringLst)
    local
      list<String> res,rest;
      String str_1,tp,str;
    case (_,{}) then {}; 
    case (tp,(str :: rest))
      equation 
        res = prefixTypename(tp, rest);
        str_1 = Util.stringAppendList({tp,",",str});
      then
        (str_1 :: res);
  end matchcontinue;
end prefixTypename;

public function getComponentitemsName "function_getComponentitemsName
  
   Thisfunction takes a `ComponentItems\' list and returns a 
   comma separated list of all
   component names and comments (if any).
"
  input list<Absyn.ComponentItem> inAbsynComponentItemLst;
  output list<String> outStringLst;
algorithm 
  outStringLst:=
  matchcontinue (inAbsynComponentItemLst)
    local
      String s1,str,c1,s2;
      list<String> lst,res;
      Absyn.ComponentItem c2;
      list<Absyn.ComponentItem> rest;
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,SOME(s2)))) :: (c2 :: rest)))
      equation 
        s1 = stringAppend(c1, ",");
        lst = getComponentitemsName((c2 :: rest));
        str = Util.stringAppendList({s1,"\"",s2,"\""});
      then
        (str :: lst);
    case ((Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = NONE) :: (c2 :: rest)))
      equation 
        s1 = stringAppend(c1, ",");
        lst = getComponentitemsName((c2 :: rest));
        str = Util.stringAppendList({s1,"\"\""});
      then
        (str :: lst);
    case ((_ :: rest))
      equation 
        res = getComponentitemsName(rest);
      then
        res;
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1),comment = SOME(Absyn.COMMENT(_,SOME(s2))))})
      local String res;
      equation 
        res = Util.stringAppendList({c1,",\"",s2,"\""});
      then
        {res};
    case ({Absyn.COMPONENTITEM(component = Absyn.COMPONENT(name = c1))})
      local String res;
      equation 
        res = Util.stringAppendList({c1,",\"\""});
      then
        {res};
    case ({_}) then {}; 
  end matchcontinue;
end getComponentitemsName;

public function addToPublic "function: addToPublic
  
   Thisfunction takes a \'Class\' definition and adds an `ElementItem\' to the first public list in the class.
   If no public list is available in the class one is created.
"
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ElementItem eitem;
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem)
      equation 
        publst = getPublicList(parts);
        publst2 = listAppend(publst, {eitem});
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.DERIVED(path = _),info = file_info),eitem) then fail(); 
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem) then Absyn.CLASS(i,p,f,e,r,
          Absyn.PARTS((Absyn.PUBLIC({eitem}) :: parts),cmt),file_info); 
  end matchcontinue;
end addToPublic;

protected function addToProtected "function: addToProtected
  
   Thisfunction takes a \'Class\' definition and adds an `ElementItem\' to 
   the first protected list in the class.
   If no protected list is available in the class one is created.
"
  input Absyn.Class inClass;
  input Absyn.ElementItem inElementItem;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inElementItem)
    local
      list<Absyn.ElementItem> protlst,protlst2;
      list<Absyn.ClassPart> parts2,parts;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.ElementItem eitem;
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem)
      equation 
        protlst = getProtectedList(parts);
        protlst2 = listAppend(protlst, {eitem});
        parts2 = replaceProtectedList(parts, protlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.DERIVED(path = _),info = file_info),eitem) then fail(); 
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem) then Absyn.CLASS(i,p,f,e,r,
          Absyn.PARTS((Absyn.PROTECTED({eitem}) :: parts),cmt),file_info); 
  end matchcontinue;
end addToProtected;

protected function addToEquation "function: addToEquation
   Thisfunction takes a \'Class\' definition and adds an `EquationItem\' to 
   the first equation list in the class.
   If no public list is available in the class one is created.
"
  input Absyn.Class inClass;
  input Absyn.EquationItem inEquationItem;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inEquationItem)
    local
      list<Absyn.EquationItem> eqlst,eqlst2;
      list<Absyn.ClassPart> parts2,parts,newparts;
      String i;
      Boolean p,f,e;
      Absyn.Restriction r;
      Option<String> cmt;
      Absyn.Info file_info;
      Absyn.EquationItem eitem;
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem)
      equation 
        eqlst = getEquationList(parts);
        eqlst2 = (eitem :: eqlst);
        parts2 = replaceEquationList(parts, eqlst2);
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(parts2,cmt),file_info);
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.DERIVED(path = _),info = file_info),eitem) then fail(); 
    case (Absyn.CLASS(name = i,partial_ = p,final_ = f,encapsulated_ = e,restricion = r,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info),eitem)
      equation 
        newparts = listAppend(parts, {Absyn.EQUATIONS({eitem})}) "Add the equations last, to make nicer output if public section present" ;
      then
        Absyn.CLASS(i,p,f,e,r,Absyn.PARTS(newparts,cmt),file_info);
  end matchcontinue;
end addToEquation;

protected function replaceClassInProgram "function: replaceClassInProgram
  
   Thisfunction takes a `Class\' and a `Program\' and replaces the class 
   definition at the top level in the program by the class definition of 
   the `Class\'.
"
  input Absyn.Class inClass;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inClass,inProgram)
    local
      Absyn.Class c,c1;
      Absyn.Within w;
      String name1,name2;
      list<Absyn.Class> clst,newclst;
      Absyn.Program p;
    case (c,Absyn.PROGRAM(classes = {},within_ = w)) then Absyn.PROGRAM({c},w); 
    case ((c as Absyn.CLASS(name = name1)),Absyn.PROGRAM(classes = (Absyn.CLASS(name = name2) :: clst),within_ = w))
      equation 
        equality(name1 = name2);
      then
        Absyn.PROGRAM((c :: clst),w);
    case ((c as Absyn.CLASS(name = name1)),Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = name2)) :: clst),within_ = w))
      equation 
        failure(equality(name1 = name2));
        Absyn.PROGRAM(newclst,w) = replaceClassInProgram(c, Absyn.PROGRAM(clst,w));
      then
        Absyn.PROGRAM((c1 :: newclst),w);
    case (c,p)
      equation 
        Print.printBuf("replace_class_in_program failed \n class:");
        Debug.fcall("dump", Dump.dump, Absyn.PROGRAM({c},Absyn.TOP()));
        Print.printBuf("\nprogram: \n");
        Debug.fcall("dump", Dump.dump, p);
      then
        fail();
  end matchcontinue;
end replaceClassInProgram;

protected function insertClassInProgram "function: insertClassInProgram 
  
   Thisfunction inserts the class into the Program at the scope given by the
   within argument. If the class referenced by the within argument is not 
   defined, thefunction prints an error message and fails.
"
  input Absyn.Class inClass;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inClass,inWithin,inProgram)
    local
      Absyn.Class c2,c3,c1;
      Absyn.Program pnew,p;
      Absyn.Within w;
      String n1,s1,name;
    case (c1,(w as Absyn.WITHIN(path = Absyn.QUALIFIED(name = n1))),p)
      equation 
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p);
      then
        pnew;
    case (c1,(w as Absyn.WITHIN(path = Absyn.IDENT(name = n1))),p)
      equation 
        c2 = getClassInProgram(n1, p);
        c3 = insertClassInClass(c1, w, c2);
        pnew = updateProgram(Absyn.PROGRAM({c3},Absyn.TOP()), p);
      then
        pnew;
    case ((c1 as Absyn.CLASS(name = name)),w,p)
      equation 
        print("Error inserting in class. (");
        s1 = Dump.unparseWithin(0, w);
        print(s1);
        print(") program = \n") "& Dump.unparse_str p => pstr & print pstr & print \"\\n\"" ;
      then
        fail();
  end matchcontinue;
end insertClassInProgram;

protected function insertClassInClass "function: insertClassInClass
   
   Thisfunction takes a class to update (the first argument)  and an inner 
   class (which is either replacing
   an earlier class or is a new inner definition) and a within statement
   pointing inside the class (including the class itself in the reference), 
   and updates the class with the inner class.
"
  input Absyn.Class inClass1;
  input Absyn.Within inWithin2;
  input Absyn.Class inClass3;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inWithin2,inClass3)
    local
      Absyn.Class cnew,c1,c2,cinner,cnew_1;
      String name,name2;
      Absyn.Path path;
    case (c1,Absyn.WITHIN(path = Absyn.IDENT(name = name)),c2)
      equation 
        cnew = replaceInnerClass(c1, c2);
      then
        cnew;
    case (c1,Absyn.WITHIN(path = Absyn.QUALIFIED(name = name,path = path)),c2)
      equation 
        name2 = getFirstIdentFromPath(path);
        cinner = getInnerClass(c2, name2);
        cnew = insertClassInClass(c1, Absyn.WITHIN(path), cinner);
        cnew_1 = replaceInnerClass(cnew, c2);
      then
        cnew_1;
    case (_,_,_)
      equation 
        Print.printBuf("insert_class_in_class failed\n");
      then
        fail();
  end matchcontinue;
end insertClassInClass;

protected function getFirstIdentFromPath "function: getFirstIdentFromPath
  
   Thisfunction takes a `Path` as argument and returns the first `Ident\' 
   of the path.
"
  input Absyn.Path inPath;
  output Absyn.Ident outIdent;
algorithm 
  outIdent:=
  matchcontinue (inPath)
    local
      String name;
      Absyn.Path path;
    case (Absyn.IDENT(name = name)) then name; 
    case (Absyn.QUALIFIED(name = name,path = path)) then name; 
  end matchcontinue;
end getFirstIdentFromPath;

protected function removeInnerClass "function: removeInnerClass 
  
   Thisfunction takes two class definitions. The first one is the local 
   class that should be removed from the second one.
"
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
    case (c1,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info))
      equation 
        publst = getPublicList(parts);
        publst2 = removeClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(parts2,cmt),file_info);
    case (_,_)
      equation 
        Print.printBuf("Failed in remove_inner_class\n");
      then
        fail();
  end matchcontinue;
end removeInnerClass;

protected function removeClassInElementitemlist "function: removeClassInElementitemlist
  
   Thisfunction takes an Element list and a Class and returns a modified 
   element list where the class definition of the class is removed.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c,c1,c2;
      String name1,name,d;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> h;
    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation 
        res = removeClassInElementitemlist(xs, c);
      then
        (a1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE))) :: xs),(c as Absyn.CLASS(name = name)))
      equation 
        failure(equality(name1 = name));
        res = removeClassInElementitemlist(xs, c);
      then
        (e1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = a,redeclareKeywords = b,innerOuter = c,name = d,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = Absyn.CLASS(name = name1)),info = info,constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      local Absyn.InnerOuter c;
      equation 
        equality(name1 = name);
      then
        xs;
    case ((c1 :: xs),c)
      local Absyn.ElementItem c1;
      equation 
        res = removeClassInElementitemlist(xs, c);
      then
        (c1 :: res);
    case ({},c) then {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",Absyn.CLASSDEF(false,c),
          Absyn.INFO("",false,0,0,0,0),NONE))}; 
  end matchcontinue;
end removeClassInElementitemlist;

protected function replaceInnerClass "function: replaceInnerClass 
 
  Thisfunction takes two class definitions. The first one is 
  inserted/replaced as a local class inside the second one.
"
  input Absyn.Class inClass1;
  input Absyn.Class inClass2;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass1,inClass2)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      Absyn.Class c1;
      String a;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
    case (c1,Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = parts,comment = cmt),info = file_info))
      equation 
        publst = getPublicList(parts);
        publst2 = replaceClassInElementitemlist(publst, c1);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(parts2,cmt),file_info);
    case (_,_)
      equation 
        Print.printBuf("Failed in replace_inner_class\n");
      then
        fail();
  end matchcontinue;
end replaceInnerClass;

protected function replaceClassInElementitemlist "function: replaceClassInElementitemlist
 
  Thisfunction takes an Element list and a Class and returns a modified 
  element list where the class definition of the class is updated or added.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Class inClass;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inClass)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1;
      Absyn.Class c,c1,c2;
      String name1,name,d;
      Boolean a,e;
      Option<Absyn.RedeclareKeywords> b;
      Absyn.Info info;
      Option<Absyn.ConstrainClass> h;
    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation 
        res = replaceClassInElementitemlist(xs, c);
      then
        (a1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE))) :: xs),(c as Absyn.CLASS(name = name)))
      equation 
        failure(equality(name1 = name));
        res = replaceClassInElementitemlist(xs, c);
      then
        (e1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(final_ = a,redeclareKeywords = b,innerOuter = c,name = d,specification = Absyn.CLASSDEF(replaceable_ = e,class_ = Absyn.CLASS(name = name1)),info = info,constrainClass = h))) :: xs),(c2 as Absyn.CLASS(name = name)))
      local Absyn.InnerOuter c;
      equation 
        equality(name1 = name);
      then
        (Absyn.ELEMENTITEM(Absyn.ELEMENT(a,b,c,d,Absyn.CLASSDEF(e,c2),info,h)) :: xs);
    case ((c1 :: xs),c)
      local Absyn.ElementItem c1;
      equation 
        res = replaceClassInElementitemlist(xs, c);
      then
        (c1 :: res);
    case ({},c) then {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"",Absyn.CLASSDEF(false,c),
          Absyn.INFO("",false,0,0,0,0),NONE))}; 
  end matchcontinue;
end replaceClassInElementitemlist;

protected function getInnerClass "function: getInnerClass
 
  Thisfunction takes a class name and a class and return the inner class 
  definition having that name.
"
  input Absyn.Class inClass;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass,inIdent)
    local
      list<Absyn.ElementItem> publst;
      Absyn.Class c1,c;
      list<Absyn.ClassPart> parts;
      String name,str,s1;
    case (Absyn.CLASS(body = Absyn.PARTS(classParts = parts)),name)
      equation 
        publst = getPublicList(parts);
        c1 = getClassFromElementitemlist(publst, name);
      then
        c1;
    case (c,name)
      equation 
        str = Print.getString();
        Print.clearBuf();
        Print.printBuf("get_inner_class failed, c:");
        Dump.dump(Absyn.PROGRAM({c},Absyn.TOP()));
        Print.printBuf("name :");
        Print.printBuf(name);
        s1 = Print.getString();
        Print.clearBuf() "print s1 &" ;
        Print.printBuf(str);
      then
        fail();
  end matchcontinue;
end getInnerClass;

protected function replacePublicList "function: replacePublicList
  
   Thisfunction replaces the `ElementItem\' list in the `ClassPart\' list, 
   and returns the updated list.
   If no public list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newpublst,new,newpublist;
    case (((lst as Absyn.PUBLIC(contents = _)) :: rest),newpublst)
      equation 
        rest_1 = deletePublicList(rest);
      then
        (Absyn.PUBLIC(newpublst) :: rest_1);
    case ((x :: xs),new)
      equation 
        ys = replacePublicList(xs, new);
      then
        (x :: ys);
    case ({},newpublist) then {Absyn.PUBLIC(newpublist)}; 
  end matchcontinue;
end replacePublicList;

protected function replaceProtectedList "function: replaceProtectedList
 
  Thisfunction replaces the `ElementItem\' list in the `ClassPart\' list, 
  and returns the updated list.
  If no protected list is available, one is created.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynElementItemLst)
    local
      list<Absyn.ClassPart> rest_1,rest,ys,xs;
      Absyn.ClassPart lst,x;
      list<Absyn.ElementItem> newprotlist,new;
    case (((lst as Absyn.PROTECTED(contents = _)) :: rest),newprotlist)
      equation 
        rest_1 = deleteProtectedList(rest);
      then
        (Absyn.PROTECTED(newprotlist) :: rest_1);
    case ((x :: xs),new)
      equation 
        ys = replaceProtectedList(xs, new);
      then
        (x :: ys);
    case ({},newprotlist) then {Absyn.PROTECTED(newprotlist)}; 
  end matchcontinue;
end replaceProtectedList;

protected function deletePublicList "function: deletePublicList
 
  Deletes all PULIC classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {}; 
    case ((Absyn.PUBLIC(contents = _) :: xs))
      equation 
        res = deletePublicList(xs);
      then
        res;
    case ((x :: xs))
      equation 
        res = deletePublicList(xs);
      then
        (x :: res);
  end matchcontinue;
end deletePublicList;

protected function deleteProtectedList "function: deleteProtectedList
 
  Deletes all PROTECTED classparts from the list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ClassPart> res,xs;
      Absyn.ClassPart x;
    case ({}) then {}; 
    case ((Absyn.PROTECTED(contents = _) :: xs))
      equation 
        res = deleteProtectedList(xs);
      then
        res;
    case ((x :: xs))
      equation 
        res = deleteProtectedList(xs);
      then
        (x :: res);
  end matchcontinue;
end deleteProtectedList;

protected function replaceEquationList "function: replaceEquationList
  
   Thisfunction replaces the `EquationItem\' list in the `ClassPart\' list, 
   and returns the updated list.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  input list<Absyn.EquationItem> inAbsynEquationItemLst;
  output list<Absyn.ClassPart> outAbsynClassPartLst;
algorithm 
  outAbsynClassPartLst:=
  matchcontinue (inAbsynClassPartLst,inAbsynEquationItemLst)
    local
      Absyn.ClassPart lst,x;
      list<Absyn.ClassPart> rest,ys,xs;
      list<Absyn.EquationItem> newpublst,new;
    case (((lst as Absyn.EQUATIONS(contents = _)) :: rest),newpublst) then (Absyn.EQUATIONS(newpublst) :: rest); 
    case ((x :: xs),new)
      equation 
        ys = replaceEquationList(xs, new);
      then
        (x :: ys);
    case ({},_) then {}; 
  end matchcontinue;
end replaceEquationList;

protected function getPublicList "function: getPublicList
 
  Thisfunction takes a ClassPart List and returns an appended list of 
  all public lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {}; 
    case (Absyn.PUBLIC(contents = res1) :: rest)
      equation 
        res2 = getPublicList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((x :: xs))
      equation 
        ys = getPublicList(xs);
      then
        ys;
  end matchcontinue;
end getPublicList;

protected function getProtectedList "function: getProtectedList
   Thisfunction takes a ClassPart List and returns an appended list of 
   all protected lists.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.ElementItem> res2,res,res1,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case ({}) then {}; 
    case (Absyn.PROTECTED(contents = res1) :: rest)
      equation 
        res2 = getProtectedList(rest);
        res = listAppend(res1, res2);
      then
        res;
    case ((x :: xs))
      equation 
        ys = getProtectedList(xs);
      then
        ys;
  end matchcontinue;
end getProtectedList;

protected function getEquationList "function: getEquationList
 
  Thisfunction takes a ClassPart List and returns the first EquationItem 
  list of the class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.EquationItem> outAbsynEquationItemLst;
algorithm 
  outAbsynEquationItemLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.EquationItem> lst,ys;
      list<Absyn.ClassPart> rest,xs;
      Absyn.ClassPart x;
    case (Absyn.EQUATIONS(contents = lst) :: rest) then lst; 
    case ((x :: xs))
      equation 
        ys = getEquationList(xs);
      then
        ys;
    case (_) then fail(); 
  end matchcontinue;
end getEquationList;

protected function getClassFromElementitemlist "function: getClassFromElementitemlist
 
  Thisfunction takes an ElementItem list and an Ident and returns the 
  class definition among the element list having that identifier.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input Absyn.Ident inIdent;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inAbsynElementItemLst,inIdent)
    local
      Absyn.Class res,c1;
      list<Absyn.ElementItem> xs;
      String name,name1,name2;
    case ((Absyn.ANNOTATIONITEM(annotation_ = _) :: xs),name)
      equation 
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE)) :: xs),name2)
      equation 
        equality(name1 = name2);
      then
        c1;
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = (c1 as Absyn.CLASS(name = name1))),constrainClass = NONE)) :: xs),name)
      equation 
        failure(equality(name1 = name));
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ((_ :: xs),name)
      equation 
        res = getClassFromElementitemlist(xs, name);
      then
        res;
    case ({},_) then fail(); 
  end matchcontinue;
end getClassFromElementitemlist;

protected function classInProgram "function: classInProgram
 
  Thisfunction takes a name and a Program and returns true if the name 
  exists as a top class in the program.
"
  input String inString;
  input Absyn.Program inProgram;
  output Boolean outBoolean;
algorithm 
  outBoolean:=
  matchcontinue (inString,inProgram)
    local
      String str,c1;
      Boolean res;
      list<Absyn.Class> p;
      Absyn.Within w;
    case (str,Absyn.PROGRAM(classes = {})) then false; 
    case (str,Absyn.PROGRAM(classes = (Absyn.CLASS(name = c1) :: p),within_ = w))
      equation 
        failure(equality(str = c1));
        res = classInProgram(str, Absyn.PROGRAM(p,w));
      then
        res;
    case (_,_) then true; 
  end matchcontinue;
end classInProgram;

public function getPathedClassInProgram "function: getPathedClassInProgram
 
  Thisfunction takes a `Path\' and a `Program` and retrieves the class 
  definition referenced by the `Path\' from the `Program\'.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class c1,c1def,res;
      String str;
      Absyn.Program p;
      list<Absyn.Class> classes;
      Absyn.Path path,prest;
      Absyn.Within w;
    case (Absyn.IDENT(name = str),p)
      equation 
        c1 = getClassInProgram(str, p);
      then
        c1;
    case ((path as Absyn.QUALIFIED(name = c1,path = prest)),(p as Absyn.PROGRAM(within_ = w)))
      local String c1;
      equation 
        c1def = getClassInProgram(c1, p);
        classes = getClassesInClass(Absyn.IDENT(c1), p, c1def);
        res = getPathedClassInProgram(prest, Absyn.PROGRAM(classes,w));
      then
        res;
  end matchcontinue;
end getPathedClassInProgram;

protected function getClassesInClass "function: getClassesInClass
  Thisfunction takes a `Class\' definition and returns a list of local 
  `Class\' definitions of that class.
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  input Absyn.Class inClass;
  output list<Absyn.Class> outAbsynClassLst;
algorithm 
  outAbsynClassLst:=
  matchcontinue (inPath,inProgram,inClass)
    local
      list<Absyn.Class> res;
      Absyn.Path modelpath,newpath,path;
      Absyn.Program p;
      list<Absyn.ClassPart> parts;
      Absyn.Class cdef;
    case (modelpath,p,Absyn.CLASS(body = Absyn.PARTS(classParts = parts)))
      equation 
        res = getClassesInParts(parts);
      then
        res;
    case (modelpath,p,Absyn.CLASS(body = Absyn.DERIVED(path = path)))
      equation 
        (cdef,newpath) = lookupClassdef(path, modelpath, p);
        res = getClassesInClass(newpath, p, cdef);
      then
        res;
  end matchcontinue;
end getClassesInClass;

protected function getClassesInParts "function: getClassesInParts
 
  Helperfunction to get_classes_in_class.
"
  input list<Absyn.ClassPart> inAbsynClassPartLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm 
  outAbsynClassLst:=
  matchcontinue (inAbsynClassPartLst)
    local
      list<Absyn.Class> l1,l2,res;
      list<Absyn.ElementItem> elts;
      list<Absyn.ClassPart> rest;
    case {} then {}; 
    case ((Absyn.PUBLIC(contents = elts) :: rest))
      equation 
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((Absyn.PROTECTED(contents = elts) :: rest))
      equation 
        l1 = getClassesInParts(rest);
        l2 = getClassesInElts(elts);
        res = listAppend(l1, l2);
      then
        res;
    case ((_ :: rest))
      equation 
        res = getClassesInParts(rest);
      then
        res;
  end matchcontinue;
end getClassesInParts;

protected function getClassesInElts "function: getClassesInElts
 
  Helperfunction to get_classes_in_parts.
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  output list<Absyn.Class> outAbsynClassLst;
algorithm 
  outAbsynClassLst:=
  matchcontinue (inAbsynElementItemLst)
    local
      list<Absyn.Class> res;
      Absyn.Class class_;
      list<Absyn.ElementItem> rest;
    case {} then {}; 
    case ((Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = class_),constrainClass = NONE)) :: rest))
      equation 
        res = getClassesInElts(rest);
      then
        (class_ :: res);
    case ((_ :: rest))
      equation 
        res = getClassesInElts(rest);
      then
        res;
  end matchcontinue;
end getClassesInElts;

protected function getClassInProgram "function: getClassInProgram
  
   Thisfunction takes a Path and a Program and returns the class with 
   the name `Path\'.
   If that class does not exist, thefunction fail
"
  input String inString;
  input Absyn.Program inProgram;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inString,inProgram)
    local
      String str,c1,c1name;
      Absyn.Class res;
      list<Absyn.Class> p;
      Absyn.Within w;
    case (str,Absyn.PROGRAM(classes = {})) then fail(); 
    case (str,Absyn.PROGRAM(classes = (Absyn.CLASS(name = c1) :: p),within_ = w))
      equation 
        failure(equality(str = c1));
        res = getClassInProgram(str, Absyn.PROGRAM(p,w));
      then
        res;
    case (str,Absyn.PROGRAM(classes = ((c1 as Absyn.CLASS(name = c1name)) :: p),within_ = w))
      local Absyn.Class c1;
      equation 
        equality(str = c1name);
      then
        c1;
  end matchcontinue;
end getClassInProgram;

protected function modificationToAbsyn "function: modificationToAbsyn
  
   Thisfunction takes a list of `NamedArg\' and returns an absyn 
   `Modification option\'. It collects binding equation from the named 
   argument binding=<expr> and creates
   corresponding Modification option Absyn node.
   Future extension: add general modifiers. Problem: how to express this using named 
   arguments. This is not possible. Instead we need a new data type for storing AST, 
   and a constructor function for AST, 
   e.g. AST x = ASTModification(redeclare R2 r, x=4.2); // new datatype AST
  					 // new constructor operator ASTModification
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Modification> inAbsynModificationOption;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  outAbsynModificationOption:=
  matchcontinue (inAbsynNamedArgLst,inAbsynModificationOption)
    local
      Absyn.Modification mod;
      list<Absyn.NamedArg> nargs;
      Option<Absyn.Modification> oldmod;
    case (nargs,oldmod)
      equation 
        SOME(mod) = modificationToAbsyn2(nargs);
      then
        SOME(mod);
    case (nargs,oldmod) then oldmod; 
  end matchcontinue;
end modificationToAbsyn;

protected function modificationToAbsyn2 "function: modificationToAbsyn2
 
  Helperfunction to modification_to_absyn.
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<Absyn.Modification> outAbsynModificationOption;
algorithm 
  outAbsynModificationOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      Absyn.Exp exp;
      list<Absyn.NamedArg> xs;
      Absyn.Modification mod;
      Option<Absyn.Modification> res;
      Absyn.NamedArg x;
    case ({}) then NONE; 
    case ((Absyn.NAMEDARG(argName = "binding",argValue = exp) :: xs)) then SOME(Absyn.CLASSMOD({},SOME(exp))); 
    case ((Absyn.NAMEDARG(argName = "modification",argValue = Absyn.CODE(code = Absyn.C_MODIFICATION(modification = mod))) :: xs)) then SOME(mod); 
    case ((x :: xs))
      equation 
        res = modificationToAbsyn2(xs);
      then
        res;
  end matchcontinue;
end modificationToAbsyn2;

protected function annotationListToAbsynComment "function: annotationListToAbsynComment
  
   Thisfunction takes a list of `NamedArg\' and returns an absyn Comment.
   for instance {annotation = Placement( ...), comment=\"stringcomment\" } 
   is converted to SOME(COMMENT(ANNOTATION(Placement(...),
  					      SOME(\"stringcomment\")))) 
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  input Option<Absyn.Comment> inAbsynCommentOption;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm 
  outAbsynCommentOption:=
  matchcontinue (inAbsynNamedArgLst,inAbsynCommentOption)
    local
      Absyn.Comment ann;
      list<Absyn.NamedArg> nargs;
      Option<Absyn.Comment> oldann;
    case (nargs,oldann)
      equation 
        SOME(ann) = annotationListToAbsynComment2(nargs);
      then
        SOME(ann);
    case (nargs,oldann) then oldann; 
  end matchcontinue;
end annotationListToAbsynComment;

protected function annotationListToAbsynComment2 "function: annotationListToAbsynComment2
 
  Helperfunction to annotation_list_to_absyn_comment2.
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<Absyn.Comment> outAbsynCommentOption;
algorithm 
  outAbsynCommentOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      list<Absyn.NamedArg> nargs;
      String strcmt;
      Absyn.Annotation annotation_;
    case (nargs)
      equation 
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs) "special case for empty string" ;
        SOME("") = commentToAbsyn(nargs);
      then
        NONE;
    case (nargs)
      equation 
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs);
        SOME(strcmt) = commentToAbsyn(nargs);
      then
        SOME(Absyn.COMMENT(NONE,SOME(strcmt)));
    case (nargs)
      equation 
        Absyn.ANNOTATION({}) = annotationListToAbsyn(nargs);
        NONE = commentToAbsyn(nargs);
      then
        NONE;
    case (nargs)
      local Option<String> strcmt;
      equation 
        annotation_ = annotationListToAbsyn(nargs);
        strcmt = commentToAbsyn(nargs);
      then
        SOME(Absyn.COMMENT(SOME(annotation_),strcmt));
    case (_) then NONE; 
  end matchcontinue;
end annotationListToAbsynComment2;

protected function commentToAbsyn "function: commentToAbsyn
 
  Helperfunction to annotation_list_to_absyn_comment2.
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Option<String> outStringOption;
algorithm 
  outStringOption:=
  matchcontinue (inAbsynNamedArgLst)
    local
      String str;
      Option<String> res;
      list<Absyn.NamedArg> rest;
    case ((Absyn.NAMEDARG(argName = "comment",argValue = Absyn.STRING(value = str)) :: _))
      equation 
        failure(equality(str = ""));
      then
        SOME(str);
    case ((_ :: rest))
      equation 
        res = commentToAbsyn(rest);
      then
        res;
    case (_) then NONE; 
  end matchcontinue;
end commentToAbsyn;

protected function annotationListToAbsyn "function: annotationListToAbsyn
 
  Thisfunction takes a list of `NamedArg\' and returns an absyn `Annotation\'.
  for instance {annotation = Placement( ...) } is converted to 
  ANNOTATION(Placement(...)) 
"
  input list<Absyn.NamedArg> inAbsynNamedArgLst;
  output Absyn.Annotation outAnnotation;
algorithm 
  outAnnotation:=
  matchcontinue (inAbsynNamedArgLst)
    local
      Absyn.ElementArg eltarg;
      Absyn.Exp e;
      Absyn.Annotation annres;
      Absyn.NamedArg a;
      list<Absyn.NamedArg> al;
    case ({}) then Absyn.ANNOTATION({}); 
    case ((Absyn.NAMEDARG(argName = "annotate",argValue = e) :: _))
      equation 
        eltarg = recordConstructorToModification(e);
      then
        Absyn.ANNOTATION({eltarg});
    case ((a :: al))
      equation 
        annres = annotationListToAbsyn(al);
      then
        annres;
  end matchcontinue;
end annotationListToAbsyn;

protected function recordConstructorToModification "function:recordConstructorToModification
  
   Thisfunction takes a record constructor expression and translates it 
   into a `ElementArg\'. Since modifications must be named, only named 
   arguments are treated in the record constructor.
"
  input Absyn.Exp inExp;
  output Absyn.ElementArg outElementArg;
algorithm 
  outElementArg:=
  matchcontinue (inExp)
    local
      list<Absyn.ElementArg> eltarglst;
      Absyn.ElementArg res,emod;
      Absyn.ComponentRef cr;
      list<Absyn.NamedArg> nargs;
      Absyn.Exp e;
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))
      equation 
        eltarglst = Util.listMap(nargs, namedargToModification) "Covers the case annotate=Diagram(x=1,y=2)" ;
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr,
          SOME(Absyn.CLASSMOD(eltarglst,NONE)),NONE);
      then
        res;
    case (Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {(e as Absyn.CALL(function_ = _))},argNames = nargs)))
      equation 
        eltarglst = Util.listMap(nargs, namedargToModification) "Covers the case annotate=Diagram(SOMETHING(x=1,y=2))" ;
        emod = recordConstructorToModification(e);
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr,
          SOME(Absyn.CLASSMOD((emod :: eltarglst),NONE)),NONE);
      then
        res;
    case (e)
      equation 
        Print.printBuf("record_constructor_to_modification failed, exp=");
        Absyn.printAbsynExp(e);
        Print.printBuf("\n");
      then
        fail();
  end matchcontinue;
end recordConstructorToModification;

protected function namedargToModification "function: namedargToModification
 
  Thisfunction takes a `NamedArg\' and translates it into a `ElementArg\'.
"
  input Absyn.NamedArg inNamedArg;
  output Absyn.ElementArg outElementArg;
algorithm 
  outElementArg:=
  matchcontinue (inNamedArg)
    local
      list<Absyn.ElementArg> elts;
      Absyn.ComponentRef cr_1,cr;
      Absyn.ElementArg res;
      String id;
      Absyn.Exp c,e;
      list<Absyn.NamedArg> nargs;
    case (Absyn.NAMEDARG(argName = id,argValue = (c as Absyn.CALL(function_ = cr,functionArgs = Absyn.FUNCTIONARGS(args = {},argNames = nargs)))))
      equation 
        Absyn.MODIFICATION(_,_,_,SOME(Absyn.CLASSMOD(elts,_)),NONE) = recordConstructorToModification(c);
        cr_1 = Absyn.CREF_IDENT(id,{});
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),cr_1,
          SOME(Absyn.CLASSMOD(elts,NONE)),NONE);
      then
        res;
    case (Absyn.NAMEDARG(argName = id,argValue = e))
      equation 
        res = Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT(id,{}),
          SOME(Absyn.CLASSMOD({},SOME(e))),NONE);
      then
        res;
    case (_)
      equation 
        Print.printBuf("- namedarg_to_modification failed\n");
      then
        fail();
  end matchcontinue;
end namedargToModification;

public function addInstantiatedClass "function: addInstantiatedClass
  
   Thisfunction adds an instantiated class to the list of instantiated 
   classes. If the class path already exists, the class is replaced. 
"
  input list<InstantiatedClass> inInstantiatedClassLst;
  input InstantiatedClass inInstantiatedClass;
  output list<InstantiatedClass> outInstantiatedClassLst;
algorithm 
  outInstantiatedClassLst:=
  matchcontinue (inInstantiatedClassLst,inInstantiatedClass)
    local
      InstantiatedClass cl,newc,x;
      Absyn.Path path,path2;
      list<DAE.Element> dae,dae_1;
      list<Env.Frame> env,env_1;
      list<InstantiatedClass> xs,res;
    case ({},cl) then {cl}; 
    case ((INSTCLASS(qualName = path,daeElementLst = dae,env = env) :: xs),(newc as INSTCLASS(qualName = path2,daeElementLst = dae_1,env = env_1)))
      equation 
        true = ModUtil.pathEqual(path, path2);
      then
        (newc :: xs);
    case (((x as INSTCLASS(qualName = path)) :: xs),(newc as INSTCLASS(qualName = path2)))
      equation 
        false = ModUtil.pathEqual(path, path2);
        res = addInstantiatedClass(xs, newc);
      then
        (x :: res);
  end matchcontinue;
end addInstantiatedClass;

public function getInstantiatedClass "function: getInstantiatedClass
 
  Thisfunction get an instantiated class from the list of instantiated 
  classes.
"
  input list<InstantiatedClass> inInstantiatedClassLst;
  input Absyn.Path inPath;
  output InstantiatedClass outInstantiatedClass;
algorithm 
  outInstantiatedClass:=
  matchcontinue (inInstantiatedClassLst,inPath)
    local
      InstantiatedClass x,res;
      Absyn.Path path,path2;
      list<DAE.Element> dae;
      list<Env.Frame> env;
      list<InstantiatedClass> xs;
    case (((x as INSTCLASS(qualName = path,daeElementLst = dae,env = env)) :: xs),path2)
      equation 
        true = ModUtil.pathEqual(path, path2);
      then
        x;
    case (((x as INSTCLASS(qualName = path)) :: xs),path2)
      equation 
        false = ModUtil.pathEqual(path, path2);
        res = getInstantiatedClass(xs, path2);
      then
        res;
  end matchcontinue;
end getInstantiatedClass;

public function getContainedClassAndFile "function: getContainedClassAndFile
   author: PA
   
   Returns the package or class in which the model is saved and the file 
   name it is saved in. This is used to save a model in a package when the 
   whole package is saved in a file.
  
   inputs:   (Absyn.Path, 
                Absyn.Program)
   outputs:  (Absyn.Program,
                string) /* filename */
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
  output String outString;
algorithm 
  (outProgram,outString):=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef;
      String filename;
      Absyn.Program p_1,p_2,p;
      Absyn.Path classname;
    case (classname,p)
      equation 
        cdef = getPathedClassInProgram(classname, p);
        filename = Absyn.classFilename(cdef);
        p_1 = getSurroundingPackage(classname, p);
        p_2 = removeInnerDiffFiledClasses(p_1);
      then
        (p_2,filename);
  end matchcontinue;
end getContainedClassAndFile;

protected function removeInnerDiffFiledClasses "function removeInnerDiffFiledClasses
   author: PA
  
   Removes all inner classes that have different file name than the class 
   itself. The filename of the class is passed as argument.
  
   inputs: (Absyn.Program) /* package as program. */
   outputs: Absyn.Program =
"
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inProgram)
    local
      list<Absyn.Class> classlst_1,classlst;
      Absyn.Within within_;
    case (Absyn.PROGRAM(classes = classlst,within_ = within_))
      equation 
        classlst_1 = Util.listMap(classlst, removeInnerDiffFiledClass);
      then
        Absyn.PROGRAM(classlst_1,within_);
  end matchcontinue;
end removeInnerDiffFiledClasses;

protected function removeInnerDiffFiledClass "function: removeInnerDiffFiledClass
   author: PA
   
   Helperfunction to remove_inner_diff_filed_classes, removes all local classes in class
   that does not have the same filename as the class iteself.
"
  input Absyn.Class inClass;
  output Absyn.Class outClass;
algorithm 
  outClass:=
  matchcontinue (inClass)
    local
      list<Absyn.ElementItem> publst,publst2;
      list<Absyn.ClassPart> parts2,parts;
      String a,file;
      Boolean b,c,d;
      Absyn.Restriction e;
      Option<String> cmt;
      Absyn.Info file_info;
    case (Absyn.CLASS(name = a,partial_ = b,final_ = c,encapsulated_ = d,restricion = e,body = Absyn.PARTS(classParts = parts,comment = cmt),info = (file_info as Absyn.INFO(fileName = file))))
      equation 
        publst = getPublicList(parts);
        publst2 = removeClassDiffFiledInElementitemlist(publst, file);
        parts2 = replacePublicList(parts, publst2);
      then
        Absyn.CLASS(a,b,c,d,e,Absyn.PARTS(parts2,cmt),file_info);
  end matchcontinue;
end removeInnerDiffFiledClass;

protected function removeClassDiffFiledInElementitemlist "function: removeClassDiffFiledInElementitemlist
  author: PA 
 
  Thisfunction takes an Element list and a filename and returns a 
  modified element list where the elements not stored in filename are 
  removed.
 
  inputs: (Absyn.ElementItem list, 
             string /* filename */)
  outputs: Absyn.ElementItem list 
"
  input list<Absyn.ElementItem> inAbsynElementItemLst;
  input String inString;
  output list<Absyn.ElementItem> outAbsynElementItemLst;
algorithm 
  outAbsynElementItemLst:=
  matchcontinue (inAbsynElementItemLst,inString)
    local
      list<Absyn.ElementItem> res,xs;
      Absyn.ElementItem a1,e1,c1;
      String c,filename2,filename1,filename;
    case (((a1 as Absyn.ANNOTATIONITEM(annotation_ = _)) :: xs),c)
      equation 
        res = removeClassDiffFiledInElementitemlist(xs, c) "annotations are kept" ;
      then
        (a1 :: res);
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(info = Absyn.INFO(fileName = filename2)))))) :: xs),filename1)
      equation 
        failure(equality(filename1 = filename2));
        res = removeClassDiffFiledInElementitemlist(xs, filename1);
      then
        res;
    case (((e1 as Absyn.ELEMENTITEM(element = Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(info = Absyn.INFO(fileName = filename2)))))) :: xs),filename1)
      equation 
        equality(filename1 = filename2);
        res = removeClassDiffFiledInElementitemlist(xs, filename1);
      then
        (e1 :: res);
    case ((c1 :: xs),filename)
      equation 
        res = removeClassDiffFiledInElementitemlist(xs, filename);
      then
        (c1 :: res);
    case ({},filename) then {}; 
  end matchcontinue;
end removeClassDiffFiledInElementitemlist;

protected function getSurroundingPackage "function: getSurroundingPackage
   author: PA
  
   Thisfunction investigates the surrounding packages and returns the outermost package
   that has the same filename as the class
"
  input Absyn.Path inPath;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm 
  outProgram:=
  matchcontinue (inPath,inProgram)
    local
      Absyn.Class cdef,pdef;
      String filename1,filename2;
      Absyn.Path ppath,classpath;
      Absyn.Program res,p;
      Absyn.Within within_;
    case (classpath,p)
      equation 
        cdef = getPathedClassInProgram(classpath, p);
        filename1 = Absyn.classFilename(cdef);
        ppath = Absyn.stripLast(classpath);
        pdef = getPathedClassInProgram(ppath, p);
        filename2 = Absyn.classFilename(pdef);
        equality(filename1 = filename2);
        res = getSurroundingPackage(ppath, p);
      then
        res;
    case (classpath,p)
      equation 
        cdef = getPathedClassInProgram(classpath, p) "No package with same filename" ;
        within_ = buildWithin(classpath);
      then
        Absyn.PROGRAM({cdef},within_);
  end matchcontinue;
end getSurroundingPackage;

protected constant Absyn.Program graphicsProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Arrow"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("BorderPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("TextStyle"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0))},Absyn.TOP()) "AST for the builtin graphical classes" ;

protected constant Absyn.Program iconProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("GraphicItem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("CoordinateSystem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Icon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("CoordinateSystem"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("coordinateSystem",{},
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT("extent",{}),
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.ARRAY(
          {Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(10.0)),
          Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(10.0))}),Absyn.ARRAY({Absyn.REAL(10.0),Absyn.REAL(10.0)})})))),NONE)},NONE))),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Arrow"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("BorderPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("TextStyle"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0))},Absyn.TOP());

protected constant Absyn.Program diagramProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("GraphicItem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("CoordinateSystem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Diagram",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("CoordinateSystem"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("coordinateSystem",{},
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT("extent",{}),
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.ARRAY(
          {Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(100.0)),
          Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(100.0))}),Absyn.ARRAY({Absyn.REAL(100.0),Absyn.REAL(100.0)})})))),NONE)},NONE))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Arrow"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("BorderPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("FillPattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("TextStyle"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("String"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0))},Absyn.TOP());

protected constant Absyn.Program lineProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Integer"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("LinePattern"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Arrow"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("line.mo",true,0,0,0,0))},Absyn.TOP());

protected constant Absyn.Program placementProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("Transformation",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("x",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("y",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("scale",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(1.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("aspectRatio",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(1.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("flipHorizontal",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("flipVertical",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Real"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("rotation",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE))})},NONE),Absyn.INFO("placement.mo",true,0,0,0,0)),
          Absyn.CLASS("Placement",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Boolean"),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Transformation"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("transformation",{},NONE),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.IDENT("Transformation"),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("iconTransformation",{},NONE),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE))})},NONE),Absyn.INFO("placement.mo",true,0,0,0,0))},Absyn.TOP());
end Interactive;

