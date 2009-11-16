/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Convert
" file:	 Convert.mo
  package:      Convert
  description: This file is part of a work-around implemented for the
  valueblock construct in order to avoid ciruclar file dependencies.
  It converts uniontypes located in Exp to similiar uniontypes located in DAE
  and vise versa.

  RCS: $Id$"

public import Exp;
public import Algorithm;
public import DAE;
public import Types;
public import Values;
public import Absyn;
public import Util;
public import SCode;
public import ClassInf;
public import Debug;
protected import DAEUtil;
type Ident = String;

//---------------------------------------------------------
// Convert DAE.Element => Exp.DAEElement
//---------------------------------------------------------
public function fromDAEElemsToExpElems "function: fromDAEElemsToExpElems
  DAE.Element 'list => Exp.DAEElement 'list"
	input list<DAE.Element> daeElems;
	input list<Exp.DAEElement> accList;
	output list<Exp.DAEElement> outList;
algorithm
  outList :=
  matchcontinue (daeElems,accList)
    local
	 		list<Exp.DAEElement> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
  	local
  	  list<DAE.Element> rest;
  	  list<Exp.DAEElement> lst;
    	DAE.Element first;
  		Exp.DAEElement first2;
  	equation
  	  first2 = fromDAEElemToExpElem(first);
  	  localAccList = listAppend(localAccList,Util.listCreate(first2));
     	lst = fromDAEElemsToExpElems(rest,localAccList);
    	then lst;
  end matchcontinue;
end fromDAEElemsToExpElems;


public function fromDAEElemToExpElem "function: fromDAEElemToExpElem
  DAE.Element  => Exp.DAEElement"
	input DAE.Element daeElem;
	output Exp.DAEElement outElem;
algorithm
  outElem := matchcontinue (daeElem)
    local
      Exp.ComponentRef compRef " The variable name";
      DAE.VarKind varKind "varible kind: variable, constant, parameter, etc." ;
      DAE.VarDirection varDirection "direction: input/output/bidirectional" ;
      DAE.VarProtection varProt "protected or not" ;
      Types.Type ty;
      Option<Exp.Exp> binding "Binding expression e.g. for parameters, value of start attribute" ; 
      DAE.InstDims dims "dimensions"; 
      DAE.Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables" ;
      DAE.Stream streamPrefix "Stream connector variables." ;
      list<Absyn.Path> pathLst "class names" ;
      Option<DAE.VariableAttributes> varAttr;
      Option<SCode.Comment> absynComment;
      Absyn.InnerOuter innerOut "inner/outer required to 'change' outer references";
      Exp.DAEElement elem;
      Exp.VarKind varKind2;
      Exp.VarDirection varDirection2;
      Exp.VarProtection varProt2;
      Exp.TypeTypes ty2;
      Exp.Flow flowPrefix2;
      Exp.Stream streamPrefix2;
      Option<Exp.VariableAttributes> varAttr2;
      Exp.TypeTypes fType2;
      list<Exp.Exp> e;
      list<list<DAE.Element>> elemList1;
      list<DAE.Element> elemList2;
      list<list<Exp.DAEElement>> elems1;
      list<Exp.DAEElement> elems2;
      Exp.DAEElement elem;      
    case (DAE.VAR(compRef,varKind,varDirection,varProt,ty,binding,dims,flowPrefix,streamPrefix,pathLst,varAttr,absynComment,innerOut))
      equation
        varKind2 = varKindConvert(varKind);
        varDirection2 = varDirConvert(varDirection);
        varProt2 = varProtConvert(varProt);
        ty2 = fromTypeToTypeTypes(ty);
        flowPrefix2 = flowConvert(flowPrefix);
        streamPrefix2 = streamConvert(streamPrefix);
        varAttr2 = varAttrConvert(varAttr);
        elem = Exp.VAR(compRef,varKind2,varDirection2,varProt2,ty2,binding,dims,flowPrefix2,streamPrefix2,pathLst,varAttr2,absynComment,innerOut);
      then elem;
    case (DAE.DEFINE(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        Exp.DAEElement elem;
      equation
        elem = Exp.DEFINE(c,e);
      then elem;
    case (DAE.INITIALDEFINE(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        Exp.DAEElement elem;
      equation
        elem = Exp.INITIALDEFINE(c,e);
      then elem;
    case (DAE.EQUATION(e1,e2))
      local
        Exp.Exp e1,e2;
        Exp.DAEElement elem;
      equation
        elem = Exp.EQUATION(e1,e2);
      then elem;
    case (DAE.ARRAY_EQUATION(intList,e1,e2))
      local
        list<Integer> intList "dimension sizes" ;
        Exp.Exp e1;
        Exp.Exp e2;
        Exp.DAEElement elem;
      equation
        elem = Exp.ARRAY_EQUATION(intList,e1,e2);
      then elem;
        
    case (DAE.WHEN_EQUATION(e,elemList,NONE()))
      local
        Exp.Exp e;
        list<DAE.Element> elemList;
        list<Exp.DAEElement> elemList2;
        Exp.DAEElement elem;
      equation
        elemList2 = fromDAEElemsToExpElems(elemList,{});
        elem = Exp.WHEN_EQUATION(e,elemList2,NONE());
      then elem;
        
    case (DAE.WHEN_EQUATION(e,elemList,SOME(elsewhen_)))
      local
        Exp.Exp e;
        list<DAE.Element> elemList;
        list<Exp.DAEElement> elemList2;
        Exp.DAEElement elem,elsewhen2;
        DAE.Element elsewhen_;
      equation
        elemList2 = fromDAEElemsToExpElems(elemList,{});
        elsewhen2 = fromDAEElemToExpElem(elsewhen_);
        elem = Exp.WHEN_EQUATION(e,elemList2,SOME(elsewhen2));
      then elem;
        
    case (DAE.IF_EQUATION(e,elemList1,elemList2))
      equation
        elems1 = Util.listMap1(elemList1, fromDAEElemsToExpElems, {});
        elems2 = fromDAEElemsToExpElems(elemList2,{});
        elem = Exp.IF_EQUATION(e,elems1,elems2);
      then elem;

    case (DAE.INITIAL_IF_EQUATION(e,elemList1,elemList2))
      equation
        elems1 = Util.listMap1(elemList1, fromDAEElemsToExpElems, {});
        elems2 = fromDAEElemsToExpElems(elemList2,{});
        elem = Exp.INITIAL_IF_EQUATION(e,elems1,elems2);
      then elem;

    case (DAE.INITIALEQUATION(e1,e2))
      local
        Exp.Exp e1;
        Exp.Exp e2;
        Exp.DAEElement elem;
      equation
        elem = Exp.INITIALEQUATION(e1,e2);
      then elem;

    case (DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg)))
    local
      list<Algorithm.Statement> alg;
      Exp.DAEElement elem;
      list<Exp.Statement> temp;
    equation
      temp = fromAlgStatesToExpStates(alg,{});
      elem = Exp.ALGORITHM(Exp.ALGORITHM2(temp));
    then elem;
      // MISSING record COMP, record FUNCTION, record EXTFUNCTION
    case (DAE.EXTOBJECTCLASS(p,elem1,elem2))
      local
        Absyn.Path p;
        DAE.Element elem1,elem2;
        Exp.DAEElement elem3,elem4,elem;
      equation
        elem3 = fromDAEElemToExpElem(elem1);
        elem4 = fromDAEElemToExpElem(elem2);
        elem = Exp.EXTOBJECTCLASS(p,elem3,elem4);
        then elem;
    case (DAE.ASSERT(e1,e2))
      local
        Exp.Exp e1,e2;
        Exp.DAEElement elem;
      equation
        elem = Exp.ASSERT(e1,e2);
      then elem;
    case (DAE.REINIT(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        Exp.DAEElement elem;
      equation
        elem = Exp.REINIT(c,e);
      then elem;
    case (DAE.NORETCALL(fn,explist))
      local
        Absyn.Path fn;
        list<Exp.Exp> explist;
      then Exp.DAENORETCALL(fn,explist);
    case daeElem
      local
        String str;
      equation
        str = DAEUtil.dumpElementsStr({daeElem});
        Debug.fprintln("failtrace", "- Convert.fromDAEElemToExpElem failed" +& str);
      then fail();
  end matchcontinue;
end fromDAEElemToExpElem;

public function varProtConvert "function: varProtConvert
  DAE.VarProtection => Exp.VarProtection"
	input DAE.VarProtection inVar;
	output Exp.VarProtection outVar;
algorithm
  outVar :=
  matchcontinue (inVar)
    case (DAE.PUBLIC()) then Exp.PUBLIC();
    case (DAE.PROTECTED()) then Exp.PROTECTED();
  end matchcontinue;
end varProtConvert;

public function varKindConvert "function: varKindConvert
  DAE.VarKind => Exp.VarKind"
	input DAE.VarKind var;
	output Exp.VarKind outVar;
algorithm
  outVar :=
  matchcontinue (var)
    case (DAE.VARIABLE()) equation then Exp.VARIABLE();
    case (DAE.DISCRETE()) equation then Exp.DISCRETE();
    case (DAE.PARAM()) equation then Exp.PARAM();
    case (DAE.CONST()) equation then Exp.CONST();
  end matchcontinue;
end varKindConvert;

public function varDirConvert "function: varDirConvert
  DAE.VarDirection => Exp.VarDirection"
	input DAE.VarDirection varDir;
	output Exp.VarDirection outVarDir;
algorithm
  outVarDir :=
  matchcontinue (varDir)
    case (DAE.INPUT()) equation then Exp.INPUT();
    case (DAE.OUTPUT()) equation then Exp.OUTPUT();
    case (DAE.BIDIR()) equation then Exp.BIDIR();
  end matchcontinue;
end varDirConvert;

public function flowConvert "function: flowConvert
  DAE.Flow => Exp.Flow"
	input DAE.Flow val;
	output Exp.Flow outVal;
algorithm
  outVal :=
  matchcontinue (val)
    case (DAE.FLOW()) equation then Exp.FLOW();
    case (DAE.NON_FLOW()) equation then Exp.NON_FLOW();
    case (DAE.NON_CONNECTOR()) equation then Exp.NON_CONNECTOR();
  end matchcontinue;
end flowConvert;

public function streamConvert "function: streamConvert
  DAE.Stream => Exp.Stream"
	input DAE.Stream val;
	output Exp.Stream outVal;
algorithm
  outVal :=
  matchcontinue (val)
    case (DAE.STREAM()) equation then Exp.STREAM();
    case (DAE.NON_STREAM()) equation then Exp.NON_STREAM();
    case (DAE.NON_STREAM_CONNECTOR()) equation then Exp.NON_STREAM_CONNECTOR();
  end matchcontinue;
end streamConvert;

public function varAttrConvert "function: varAttrConvert
  DAE.VariableAttributres 'option => Exp.VariableAttributes 'option"
	input Option<DAE.VariableAttributes> varAttr;
	output Option<Exp.VariableAttributes> outVarAttr;
algorithm
  outVarAttr := matchcontinue (varAttr)
    local
      Option<Exp.VariableAttributes> elem;
    case (NONE()) equation then NONE();
    case (SOME(DAE.VAR_ATTR_REAL(quant,u,dUnit,min,init,f,nom,sSelectOption,_,_,_)))
      local
        Option<Exp.Exp> quant "quantity" ;
        Option<Exp.Exp> u "unit" ;
        Option<Exp.Exp> dUnit "displayUnit" ;
        tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
        Option<Exp.Exp> init "Initial value" ;
        Option<Exp.Exp> f;
        Option<Exp.Exp> nom "nominal" ;
        Option<DAE.StateSelect> sSelectOption;
        Option<Exp.StateSelect> sSelectOption2;
      equation
        sSelectOption2 = convertStateSelect(sSelectOption);
        elem = SOME(Exp.VAR_ATTR_REAL(quant,u,dUnit,min,init,f,nom,sSelectOption2));
      then elem;
    case (SOME(DAE.VAR_ATTR_INT(quan,min,init,fixed,_,_,_)))
      local
        Option<Exp.Exp> quan "quantity" ;
        tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
        Option<Exp.Exp> init "Initial value" ;
        Option<Exp.Exp> fixed;
      equation
        elem = SOME(Exp.VAR_ATTR_INT(quan,min,init,fixed));
      then elem;
    case (SOME(DAE.VAR_ATTR_BOOL(quan,init,f,_,_,_)))
      local
        Option<Exp.Exp> quan "quantity" ;
        Option<Exp.Exp> init "Initial value" ;
        Option<Exp.Exp> f;
      equation
        elem = SOME(Exp.VAR_ATTR_BOOL(quan,init,f));
      then elem;
    case (SOME(DAE.VAR_ATTR_STRING(quan,init,_,_,_)))
      local
        Option<Exp.Exp> quan "quantity" ;
        Option<Exp.Exp> init "Initial value" ;
      equation
        elem = SOME(Exp.VAR_ATTR_STRING(quan,init));
      then elem;
  end matchcontinue;
end varAttrConvert;

public function convertStateSelect "function: convertStateSelect
  DAE.StateSelect 'option => Exp.StateSelect 'option"
	input Option<DAE.StateSelect> ss;
	output Option<Exp.StateSelect> outSs;
algorithm
	outSs := matchcontinue (ss)
	  case (NONE()) equation then NONE();
	  case (SOME(DAE.NEVER())) equation then SOME(Exp.NEVER());
	  case (SOME(DAE.AVOID())) equation then SOME(Exp.AVOID());
	  case (SOME(DAE.DEFAULT())) equation then SOME(Exp.DEFAULT());
	  case (SOME(DAE.PREFER())) equation then SOME(Exp.PREFER());
	  case (SOME(DAE.ALWAYS())) equation then SOME(Exp.ALWAYS());
	end matchcontinue;
end convertStateSelect;

public function fromAlgStatesToExpStates "function: fromAlgStatesToExpStates
  Algorithm.Statement 'list => Exp.Statement 'list"
	input list<Algorithm.Statement> algStates;
	input list<Exp.Statement> accList;
	output list<Exp.Statement> outList;
algorithm
  outList :=
  matchcontinue (algStates,accList)
    local
	 		list<Exp.Statement> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
  	local
  	  list<Algorithm.Statement> rest;
    	Algorithm.Statement first;
  	  Exp.Statement first2;
    	list<Exp.Statement> lst;
  	equation
    	first2 = fromAlgStateToExpState(first);
    	localAccList = listAppend(localAccList,Util.listCreate(first2));
     	lst = fromAlgStatesToExpStates(rest,localAccList);
  	then lst;
  end matchcontinue;
end fromAlgStatesToExpStates;

public function fromAlgStateToExpState "function: fromAlgStateToExpState
  Algorithm.Statement => Exp.Statement"
	input Algorithm.Statement algState;
	output Exp.Statement outState;
algorithm
  outState := matchcontinue (algState)
    case (DAE.STMT_ASSIGN(t,e1,e))
      local
    		Exp.Type t;
    		Exp.Exp e,e1;
    		Exp.Statement elem;
      equation
        elem = Exp.ASSIGN(t,e1,e);
      then elem;
    case (DAE.STMT_TUPLE_ASSIGN(t,expLst,e))
    	local
    		Exp.Type t;
    		list<Exp.Exp> expLst;
    		Exp.Exp e;
    		Exp.Statement elem;
    	equation
    	  elem = Exp.TUPLE_ASSIGN(t,expLst,e);
    	then elem;
    case (DAE.STMT_ASSIGN_ARR(t,compRef,e))
       local
         Exp.Type t;
    		 Exp.ComponentRef compRef;
         Exp.Exp e;
         Exp.Statement elem;
       equation
         elem = Exp.ASSIGN_ARR(t,compRef,e);
       then elem;
    case (DAE.STMT_IF(e,sLst,else_))
      	local
      	  Exp.Exp e;
      	  list<Algorithm.Statement> sLst;
    			Algorithm.Else else_;
    			Exp.Statement elem;
    			list<Exp.Statement> sLst2;
        	Exp.Else else_2;
    		equation
    		  sLst2 = fromAlgStatesToExpStates(sLst,{});
    		  else_2 = fromAlgElseToExpElse(else_);
    		  elem = Exp.IF(e,sLst2,else_2);
    		  then elem;
    case (DAE.STMT_FOR(t,bool,i,e,sLst))
				local
		    	Exp.Type t;
    			Boolean bool;
    			Ident i;
    			Exp.Exp e;
    			list<Algorithm.Statement> sLst;
    			Exp.Statement elem;
    			list<Exp.Statement> sLst2;
    		equation
    		  sLst2 = fromAlgStatesToExpStates(sLst,{});
    		  elem = Exp.FOR(t,bool,i,e,sLst2);
    		then elem;
    case (DAE.STMT_WHILE(e,sLst))
    		local
    			Exp.Exp e;
    			list<Algorithm.Statement> sLst;
    			Exp.Statement elem;
    			list<Exp.Statement> sLst2;
    		equation
    		  sLst2 = fromAlgStatesToExpStates(sLst,{});
    		  elem = Exp.WHILE(e,sLst2);
    		then elem;
    case (DAE.STMT_WHEN(e,sLst,SOME(eWhen),helpVar))
    		local
    			Exp.Exp e;
    			list<Algorithm.Statement> sLst;
    			Algorithm.Statement eWhen;
    			list<Integer> helpVar;
    			Exp.Statement elem;
    			list<Exp.Statement> sLst2;
    			Exp.Statement eWhen2;
    		equation
    		  sLst2 = fromAlgStatesToExpStates(sLst,{});
    		  eWhen2 = fromAlgStateToExpState(eWhen);
    		  elem = Exp.WHEN(e,sLst2,SOME(eWhen2),helpVar);
    		then elem;
   case (DAE.STMT_WHEN(e,sLst,NONE(),helpVar))
    		local
    			Exp.Exp e;
    			list<Algorithm.Statement> sLst;
    			Option<Algorithm.Statement> eWhen;
    			list<Integer> helpVar;
    			Exp.Statement elem;
    			list<Exp.Statement> sLst2;
    		equation
    		  sLst2 = fromAlgStatesToExpStates(sLst,{});
    		  elem = Exp.WHEN(e,sLst2,NONE(),helpVar);
    		then elem;
    case (DAE.STMT_ASSERT(e1,e2))
      local
		    Exp.Exp e1;
    		Exp.Exp e2;
    		Exp.Statement elem;
			equation
			  elem = Exp.ASSERTSTMT(e1,e2);
			  then elem;
    case (DAE.STMT_REINIT(var,value))
      local
        Exp.Exp var "Variable";
    		Exp.Exp value "Value ";
        Exp.Statement elem;
      equation
        elem = Exp.REINITSTMT(var,value);
        then elem;
    case (DAE.STMT_RETURN())
    local
      Exp.Statement elem;
    equation
      elem = Exp.RETURN();
      then elem;
	  case (DAE.STMT_BREAK())
    local
      Exp.Statement elem;
    equation
      elem = Exp.BREAK();
    then elem;
	// Part of MetaModelica extension
	  case (DAE.STMT_TRY(b))
		  local
    		list<Algorithm.Statement> b;
    		Exp.Statement elem;
    		list<Exp.Statement> b2;
    	equation
    	  b2 = fromAlgStatesToExpStates(b,{});
    		elem = Exp.TRY(b2);
    	then elem;
		case (DAE.STMT_CATCH(b))
    	local
	    	list<Algorithm.Statement> b;
	    	Exp.Statement elem;
	    	list<Exp.Statement> b2;
	    equation
	      b2 = fromAlgStatesToExpStates(b,{});
	      elem = Exp.CATCH(b2);
	      then elem;
		case (DAE.STMT_THROW())
		  local
      Exp.Statement elem;
    equation
      elem = Exp.THROW();
    then elem;
		case (DAE.STMT_GOTO(s))
		  local
		    Exp.Statement elem;
		    String s;
		  equation
		    elem = Exp.GOTO(s);
		  then elem;
		case (DAE.STMT_LABEL(s))
		  local
		    Exp.Statement elem;
		    String s;
		  equation
		    elem = Exp.LABEL(s);
		  then elem;
	  case (DAE.STMT_MATCHCASES(exps)) // matchcontinue helper
      local
        list<Exp.Exp> exps;
      then Exp.MATCHCASES(exps);
	  case (DAE.STMT_NORETCALL(exp))
	    local
	      Exp.Exp exp;
	    then Exp.NORETCALL(exp);
	    
		case (alg)
		  local
		    Algorithm.Statement alg;
		  equation
		    Debug.fprintln("failtrace", "- Convert.fromAlgStateToExpState failed");
		  then fail();
  end matchcontinue;
end fromAlgStateToExpState;

public function fromAlgElseToExpElse "function: fromAlgElseToExpElse
  Algorithm.Else => Exp.Else"
	input Algorithm.Else elseIn;
	output Exp.Else elseOut;
algorithm
	elseOut :=
	matchcontinue (elseIn)
	  case (DAE.NOELSE())
	    equation then Exp.NOELSE();
	  case (DAE.ELSEIF(e,sLst,else_))
	   local
	     Exp.Exp e;
	     list<Algorithm.Statement> sLst;
	     Algorithm.Else else_;
	     Exp.Else elem;
	     list<Exp.Statement> sLst2;
	     Exp.Else else_2;
    equation
      sLst2 = fromAlgStatesToExpStates(sLst,{});
      else_2 = fromAlgElseToExpElse(else_);
      elem = Exp.ELSEIF(e,sLst2,else_2);
	  then elem;
	  case (DAE.ELSE(sLst))
	   local
	     list<Algorithm.Statement> sLst;
	     Exp.Else elem;
	     list<Exp.Statement> sLst2;
    equation
      sLst2 = fromAlgStatesToExpStates(sLst,{});
      elem = Exp.ELSE(sLst2);
	  then elem;
	end matchcontinue;
end fromAlgElseToExpElse;


//---------------------------------------------------------
// Convert Exp.DAEElement => DAE.Element
//---------------------------------------------------------

public function fromExpElemsToDAEElems "function: fromExpElemsToDAEElems
  Exp.DAEElement 'list => DAE.Element 'list"
	input list<Exp.DAEElement> daeElems;
	input list<DAE.Element> accList;
	output list<DAE.Element> outList;
algorithm
  outList :=
  matchcontinue (daeElems,accList)
    local
	 		list<DAE.Element> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
  	local
  	  list<Exp.DAEElement> rest;
    	Exp.DAEElement first;
  	  DAE.Element first2;
  	  list<DAE.Element> lst;
  	equation
    	first2 = fromExpElemToDAEElem(first);
  	  localAccList = listAppend(localAccList,Util.listCreate(first2));
    	lst = fromExpElemsToDAEElems(rest,localAccList);
    	then lst;
  end matchcontinue;
end fromExpElemsToDAEElems;

public function fromExpElemToDAEElem 
"function fromExpElemToDAEElem
  Exp.DAEElement => DAE.Element"
	input Exp.DAEElement daeElem;
	output DAE.Element outElem;
algorithm
  outElem := matchcontinue (daeElem)
    local
      list<Exp.Exp> e;
      list<list<Exp.DAEElement>> elemList1;
      list<Exp.DAEElement> elemList2;
      list<list<DAE.Element>> elems1;
      list<DAE.Element> elems2;
      DAE.Element elem;
      Exp.ComponentRef compRef " The variable name";
      Exp.VarKind var "varible kind: variable, constant, parameter, etc." ;
      Exp.VarDirection varDirection " input/output/bidirectional ";
      Exp.VarProtection varProt "protected or not";
      Exp.TypeTypes ty;
      Option<Exp.Exp> binding "Binding expression e.g. for parameters, i.e. value of start attribute";
      Exp.InstDims dims "dimensions"; 
      Exp.Flow flowPrefix "Flow of connector variable. Needed for unconnected flow variables";
      Exp.Stream streamPrefix "Stream variables" ;
      list<Absyn.Path> pathLst;
      Option<Exp.VariableAttributes> varAttr;
      Option<SCode.Comment> absynComment;
      Absyn.InnerOuter innerOut "inner/outer required to 'change' outer references";
      DAE.Element elem;
      DAE.VarKind var2;
      DAE.VarDirection varDirection2;
      Types.Type ty2;
      DAE.VarProtection varProt2;
      DAE.Flow flowPrefix2;
      DAE.Stream streamPrefix2;
      Option<DAE.VariableAttributes> varAttr2;
      Types.Type fType2;
      
    case (Exp.VAR(compRef,var,varDirection,varProt,ty,binding,dims,flowPrefix,streamPrefix,pathLst,varAttr,absynComment,innerOut))
      equation
        var2 = varKindConvert2(var);
        varDirection2 = varDirConvert2(varDirection);
        varProt2 = varProtConvert2(varProt);
        varAttr2 = varAttrConvert2(varAttr);
        ty2 = fromTypeTypesToType(ty);
        flowPrefix2 = flowConvert2(flowPrefix);
        streamPrefix2 = streamConvert2(streamPrefix);
        elem = DAE.VAR(compRef,var2,varDirection2,varProt2,ty2,binding,dims,flowPrefix2,streamPrefix2,pathLst,varAttr2,absynComment,innerOut);
      then elem;

    case (Exp.DEFINE(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        DAE.Element elem;
      equation
        elem = DAE.DEFINE(c,e);
      then elem;
        
    case (Exp.INITIALDEFINE(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        DAE.Element elem;
      equation
        elem = DAE.INITIALDEFINE(c,e);
      then elem;

    case (Exp.EQUATION(e1,e2))
      local
        Exp.Exp e1,e2;
        DAE.Element elem;
      equation
        elem = DAE.EQUATION(e1,e2);
      then elem;

    case (Exp.ARRAY_EQUATION(intList,e1,e2))
      local
        list<Integer> intList "dimension sizes" ;
        Exp.Exp e1;
        Exp.Exp e2;
        DAE.Element elem;
      equation
        elem = DAE.ARRAY_EQUATION(intList,e1,e2);
      then elem;

    case (Exp.WHEN_EQUATION(e,elemList,NONE()))
      local
        Exp.Exp e;
        list<DAE.Element> elemList2;
        list<Exp.DAEElement> elemList;
        DAE.Element elem;
      equation
        elemList2 = fromExpElemsToDAEElems(elemList,{});
        elem = DAE.WHEN_EQUATION(e,elemList2,NONE());
      then elem;

    case (Exp.WHEN_EQUATION(e,elemList,SOME(elsewhen_)))
      local
        Exp.Exp e;
        list<DAE.Element> elemList2;
        list<Exp.DAEElement> elemList;
        DAE.Element elem,elsewhen2;
        Exp.DAEElement elsewhen_;
      equation
        elemList2 = fromExpElemsToDAEElems(elemList,{});
        elsewhen2 = fromExpElemToDAEElem(elsewhen_);
        elem = DAE.WHEN_EQUATION(e,elemList2,SOME(elsewhen2));
      then elem;

    case (Exp.IF_EQUATION(e,elemList1,elemList2))
      equation
        elems1 = Util.listMap1(elemList1, fromExpElemsToDAEElems, {});
        elems2 = fromExpElemsToDAEElems(elemList2,{});
        elem = DAE.IF_EQUATION(e,elems1,elems2);
      then elem;

    case (Exp.INITIAL_IF_EQUATION(e,elemList1,elemList2))
      equation
        elems1 = Util.listMap1(elemList1, fromExpElemsToDAEElems, {});
        elems2 = fromExpElemsToDAEElems(elemList2,{});
        elem = DAE.INITIAL_IF_EQUATION(e,elems1,elems2);
      then elem;

    case (Exp.INITIALEQUATION(e1,e2))
      local
        Exp.Exp e1;
        Exp.Exp e2;
        DAE.Element elem;
      equation
        elem = DAE.INITIALEQUATION(e1,e2);
      then elem;

    case (Exp.ALGORITHM(Exp.ALGORITHM2(alg)))
    local
      list<Exp.Statement> alg;
      DAE.Element elem;
      list<Algorithm.Statement> alg2;
    equation
      alg2 = fromExpStatesToAlgStates(alg,{});
      elem = DAE.ALGORITHM(DAE.ALGORITHM_STMTS(alg2));
    then elem;

      // MISSING record COMP, record FUNCTION, record EXTFUNCTION

    case (Exp.EXTOBJECTCLASS(p,elem1,elem2))
      local
        Absyn.Path p;
        Exp.DAEElement elem1,elem2;
        DAE.Element elem3,elem4,elem;
      equation
        elem3 = fromExpElemToDAEElem(elem1);
        elem4 = fromExpElemToDAEElem(elem2);
        elem = DAE.EXTOBJECTCLASS(p,elem3,elem4);
        then elem;
    case (Exp.ASSERT(e1,e2))
      local
        Exp.Exp e1,e2;
        DAE.Element elem;
      equation
        elem = DAE.ASSERT(e1,e2);
      then elem;
    case (Exp.REINIT(c,e))
      local
        Exp.ComponentRef c;
        Exp.Exp e;
        DAE.Element elem;
      equation
        elem = DAE.REINIT(c,e);
      then elem;
    
    case (Exp.DAENORETCALL(fn,explist))
      local
        Absyn.Path fn;
        list<Exp.Exp> explist;
      then DAE.NORETCALL(fn,explist);
    
    case _
      equation
        Debug.fprintln("failtrace", "- Convert.fromExpElemToDAEElem failed");
      then fail();

  end matchcontinue;  
end fromExpElemToDAEElem;

public function varProtConvert2 "function: varProtConvert2
  Exp.VarProtection => DAE.VarProtection"
	input Exp.VarProtection inVar;
	output DAE.VarProtection outVar;
algorithm
  outVar :=
  matchcontinue (inVar)
    case (Exp.PUBLIC()) then DAE.PUBLIC();
    case (Exp.PROTECTED()) then DAE.PROTECTED();
  end matchcontinue;
end varProtConvert2;

public function varKindConvert2 "function: varKindConvert2
  Exp.VarKind => DAE.VarKind"
	input Exp.VarKind var;
	output DAE.VarKind outVar;
algorithm
  outVar :=
  matchcontinue (var)
    case (Exp.VARIABLE()) equation then DAE.VARIABLE();
    case (Exp.DISCRETE()) equation then DAE.DISCRETE();
    case (Exp.PARAM()) equation then DAE.PARAM();
    case (Exp.CONST()) equation then DAE.CONST();
  end matchcontinue;
end varKindConvert2;

public function varDirConvert2 "function: varDirConvert2
  Exp.VarDirection => DAE.VarDirection"
	input Exp.VarDirection varDir;
	output DAE.VarDirection outVarDir;
algorithm
  outVarDir :=
  matchcontinue (varDir)
    case (Exp.INPUT()) equation then DAE.INPUT();
    case (Exp.OUTPUT()) equation then DAE.OUTPUT();
    case (Exp.BIDIR()) equation then DAE.BIDIR();
  end matchcontinue;
end varDirConvert2;

public function flowConvert2 "function: flowConvert2
  Exp.Flow => DAE.Flow"
	input Exp.Flow val;
	output DAE.Flow outVal;
algorithm
  outVal :=
  matchcontinue (val)
    case (Exp.FLOW()) equation then DAE.FLOW();
    case (Exp.NON_FLOW()) equation then DAE.NON_FLOW();
    case (Exp.NON_CONNECTOR()) equation then DAE.NON_CONNECTOR();
  end matchcontinue;
end flowConvert2;

public function streamConvert2 "function: streamConvert2
  Exp.Stream => DAE.Stream"
	input Exp.Stream val;
	output DAE.Stream outVal;
algorithm
  outVal :=
  matchcontinue (val)
    case (Exp.STREAM()) equation then DAE.STREAM();
    case (Exp.NON_STREAM()) equation then DAE.NON_STREAM();
    case (Exp.NON_STREAM_CONNECTOR()) equation then DAE.NON_STREAM_CONNECTOR();
  end matchcontinue;
end streamConvert2;

public function varAttrConvert2 "function: varAttrConvert2
  Exp.VariableAttributes 'option => DAE.VariableAttributes 'option"
	input Option<Exp.VariableAttributes> varAttr;
	output Option<DAE.VariableAttributes> outVarAttr;
algorithm
  outVarAttr := matchcontinue (varAttr)
    local
      Option<DAE.VariableAttributes> elem;
     	DAE.VariableAttributes temp;
    case (NONE()) equation then NONE();
    case (SOME(Exp.VAR_ATTR_REAL(q,u,d,m,i,f,n,s)))
    local
      Option<Exp.Exp> q "quantity" ;
    	Option<Exp.Exp> u "unit" ;
    	Option<Exp.Exp> d "displayUnit" ;
    	tuple<Option<Exp.Exp>, Option<Exp.Exp>> m "min , max" ;
    	Option<Exp.Exp> i "Initial value" ;
    	Option<Exp.Exp> f;
    	Option<Exp.Exp> n "nominal" ;
    	Option<Exp.StateSelect> s;
    	Option<DAE.StateSelect> sSelectOption2;
    equation
      sSelectOption2 = convertStateSelect2(s);
      elem = SOME(DAE.VAR_ATTR_REAL(q,u,d,m,i,f,n,sSelectOption2,NONE(),NONE(),NONE()));
    then elem;
   case (SOME(Exp.VAR_ATTR_INT(q,m,i,f)))
		local
			Option<Exp.Exp> q "quantity" ;
    	tuple<Option<Exp.Exp>, Option<Exp.Exp>> m "min , max" ;
    	Option<Exp.Exp> i "Initial value" ;
    	Option<Exp.Exp> f;
    equation
      elem = SOME(DAE.VAR_ATTR_INT(q,m,i,f,NONE(),NONE(),NONE()));
    then elem;
	  case (SOME(Exp.VAR_ATTR_BOOL(q,i,f)))
	  local
	    Option<Exp.Exp> q "quantity" ;
    	Option<Exp.Exp> i "Initial value" ;
    	Option<Exp.Exp> f;
    equation
      elem = SOME(DAE.VAR_ATTR_BOOL(q,i,f,NONE(),NONE(),NONE()));
      then elem;
    case (SOME(Exp.VAR_ATTR_STRING(q,i)))
    local
      Option<Exp.Exp> q "quantity" ;
    	Option<Exp.Exp> i "Initial value" ;
   	equation
   	  elem = SOME(DAE.VAR_ATTR_STRING(q,i,NONE(),NONE(),NONE()));
   	then elem;
  case (SOME(Exp.VAR_ATTR_ENUMERATION(q,m,st,f)))
    local
    Option<Exp.Exp> q "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> m "min , max" ;
    Option<Exp.Exp> st "start" ;
    Option<Exp.Exp> f "fixed - true: default for parameter/constant, false - default for other variables" ;
    equation
       elem = SOME(DAE.VAR_ATTR_ENUMERATION(q,m,st,f,NONE(),NONE(),NONE()));
   	then elem;
  end matchcontinue;
end varAttrConvert2;

public function convertStateSelect2 "function: convertStateSelect2
  Exp.StateSelect 'option => DAE.StateSelect 'option"
	input Option<Exp.StateSelect> ss;
	output Option<DAE.StateSelect> outSs;
algorithm
	outSs :=
	matchcontinue (ss)
	  case (NONE()) equation then NONE();
	  case (SOME(Exp.NEVER())) equation then SOME(DAE.NEVER());
	  case (SOME(Exp.AVOID())) equation then SOME(DAE.AVOID());
	  case (SOME(Exp.DEFAULT())) equation then SOME(DAE.DEFAULT());
	  case (SOME(Exp.PREFER())) equation then SOME(DAE.PREFER());
	  case (SOME(Exp.ALWAYS())) equation then SOME(DAE.ALWAYS());
	end matchcontinue;
end convertStateSelect2;

public function fromExpStatesToAlgStates "function: fromExpStatesToAlgStates
  Exp.Statement 'list => Algorithm.Statement 'list"
	input list<Exp.Statement> algStates;
	input list<Algorithm.Statement> accList;
	output list<Algorithm.Statement> outList;
algorithm
  outList :=
  matchcontinue (algStates,accList)
    local
	 		list<Algorithm.Statement> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first  :: rest,localAccList)
  	local
  	  list<Exp.Statement> rest;
    	Exp.Statement first;
  	  Algorithm.Statement first2;
    	list<Algorithm.Statement> lst;
  	equation
    	first2 = fromExpStateToAlgState(first);
  	  localAccList = listAppend(localAccList,Util.listCreate(first2));
    	lst = fromExpStatesToAlgStates(rest,localAccList);
    	then lst;
  end matchcontinue;
end fromExpStatesToAlgStates;

public function fromExpStateToAlgState "function: fromExpStateToAlgState
  Exp.Statement => Algorithm.Statement"
	input Exp.Statement algState;
	output Algorithm.Statement outState;
algorithm
  outState :=
  matchcontinue (algState)
    case (Exp.ASSIGN(t,e1,e))
      local
    		Exp.Type t;
    		Exp.Exp e,e1;
    		Algorithm.Statement elem;
      equation
        elem = DAE.STMT_ASSIGN(t,e1,e);
      then elem;
    case (Exp.TUPLE_ASSIGN(t,expLst,e))
    	local
    		Exp.Type t;
    		list<Exp.Exp> expLst;
    		Exp.Exp e;
    		Algorithm.Statement elem;
    	equation
    	  elem = DAE.STMT_TUPLE_ASSIGN(t,expLst,e);
    	then elem;
    case (Exp.ASSIGN_ARR(t,compRef,e))
       local
         Exp.Type t;
    		 Exp.ComponentRef compRef;
         Exp.Exp e;
         Algorithm.Statement elem;
       equation
         elem = DAE.STMT_ASSIGN_ARR(t,compRef,e);
         then elem;
    case (Exp.IF(e,sLst,else_))
      	local
      	  Exp.Exp e;
      	  list<Exp.Statement> sLst;
    			Exp.Else else_;
    			Algorithm.Statement elem;
    			list<Algorithm.Statement> sLst2;
      	  Algorithm.Else else_2;
    		equation
    		  sLst2 = fromExpStatesToAlgStates(sLst,{});
    		  else_2 = fromExpElseToAlgElse(else_);
    		  elem = DAE.STMT_IF(e,sLst2,else_2);
    		  then elem;
    case (Exp.FOR(t,bool,i,e,sLst))
				local
		    	Exp.Type t;
    			Boolean bool;
    			Ident i;
    			Exp.Exp e;
    			list<Exp.Statement> sLst;
    			Algorithm.Statement elem;
    			list<Algorithm.Statement> sLst2;
    		equation
    		  sLst2 = fromExpStatesToAlgStates(sLst,{});
    		  elem = DAE.STMT_FOR(t,bool,i,e,sLst2);
    		then elem;
    case (Exp.WHILE(e,sLst))
    		local
    			Exp.Exp e;
    			list<Exp.Statement> sLst;
    			Algorithm.Statement elem;
    			list<Algorithm.Statement> sLst2;
    		equation
    		  sLst2 = fromExpStatesToAlgStates(sLst,{});
    		  elem = DAE.STMT_WHILE(e,sLst2);
    		then elem;
    case (Exp.WHEN(e,sLst,NONE(),helpVar))
    		local
    			Exp.Exp e;
    			list<Exp.Statement> sLst;
    			Option<Exp.Statement> eWhen;
    			list<Integer> helpVar;
    			Algorithm.Statement elem;
    			list<Algorithm.Statement> sLst2;
    		equation
    		  sLst2 = fromExpStatesToAlgStates(sLst,{});
    		  elem = DAE.STMT_WHEN(e,sLst2,NONE(),helpVar);
    		then elem;
    case (Exp.WHEN(e,sLst,SOME(eWhen),helpVar))
    		local
    			Exp.Exp e;
    			list<Exp.Statement> sLst;
    			Exp.Statement eWhen;
    			list<Integer> helpVar;
    			Algorithm.Statement elem;
    			list<Algorithm.Statement> sLst2;
    			Algorithm.Statement eWhen2;
    		equation
    		  sLst2 = fromExpStatesToAlgStates(sLst,{});
    		  eWhen2 = fromExpStateToAlgState(eWhen);
    		  elem = DAE.STMT_WHEN(e,sLst2,SOME(eWhen2),helpVar);
    		then elem;
    case (Exp.ASSERTSTMT(e1,e2))
      local
		    Exp.Exp e1;
    		Exp.Exp e2;
    		Algorithm.Statement elem;
			equation
			  elem = DAE.STMT_ASSERT(e1,e2);
			  then elem;
    case (Exp.REINITSTMT(var,value))
      local
        Exp.Exp var "Variable";
    		Exp.Exp value "Value ";
        Algorithm.Statement elem;
      equation
        elem = DAE.STMT_REINIT(var,value);
        then elem;
    case (Exp.RETURN())
    local
      Algorithm.Statement elem;
    equation
      elem = DAE.STMT_RETURN();
      then elem;
	  case (Exp.BREAK())
    local
      Algorithm.Statement elem;
    equation
      elem = DAE.STMT_BREAK();
    then elem;
	// Part of MetaModelica extension
	  case (Exp.TRY(b))
		  local
    		list<Exp.Statement> b;
    		Algorithm.Statement elem;
    		list<Algorithm.Statement> b2;
    	equation
    	  b2 = fromExpStatesToAlgStates(b,{});
    		elem = DAE.STMT_TRY(b2);
    	then elem;
		case (Exp.CATCH(b))
    	local
	    	list<Exp.Statement> b;
	    	Algorithm.Statement elem;
    		list<Algorithm.Statement> b2;
	    equation
	      b2 = fromExpStatesToAlgStates(b,{});
	      elem = DAE.STMT_CATCH(b2);
	      then elem;
		case (Exp.THROW())
		  local
		    Algorithm.Statement elem;
		  equation
		    elem = DAE.STMT_THROW();
		  then elem;
		case (Exp.GOTO(s))
		  local
		    Algorithm.Statement elem;
		    String s;
		  equation
		    elem = DAE.STMT_GOTO(s);
		  then elem;
		case (Exp.LABEL(s))
		  local
		    String s;
		    Algorithm.Statement elem;
		  equation
		    elem = DAE.STMT_LABEL(s);
		  then elem;
	  case (Exp.MATCHCASES(exps)) // matchcontinue helper
      local
        list<Exp.Exp> exps;
      then DAE.STMT_MATCHCASES(exps);
	  case (Exp.NORETCALL(exp))
	    local
	      Exp.Exp exp;
	    then DAE.STMT_NORETCALL(exp);
	  case _
	    equation
	      Debug.fprintln("failtrace", "- Convert.fromExpStateToAlgState failed");
	    then fail();
  end matchcontinue;
end fromExpStateToAlgState;


public function fromExpElseToAlgElse "function: fromExpElseToAlgElse
  Exp.Else => Algorithm.Else"
	input Exp.Else elseIn;
	output Algorithm.Else elseOut;
algorithm
	elseOut :=
	matchcontinue (elseIn)
	  case (Exp.NOELSE())
	    equation then DAE.NOELSE();
	  case (Exp.ELSEIF(e,sLst,else_))
	   local
	     Exp.Exp e;
	     list<Exp.Statement> sLst;
	     Exp.Else else_;
	     Algorithm.Else elem;
	     list<Algorithm.Statement> sLst2;
	     Algorithm.Else else_2;
    equation
      sLst2 = fromExpStatesToAlgStates(sLst,{});
      else_2 = fromExpElseToAlgElse(else_);
      elem = DAE.ELSEIF(e,sLst2,else_2);
	  then elem;
	  case (Exp.ELSE(sLst))
	   local
	     list<Exp.Statement> sLst;
	     Algorithm.Else elem;
	     list<Algorithm.Statement> sLst2;
    equation
      sLst2 = fromExpStatesToAlgStates(sLst,{});
      elem = DAE.ELSE(sLst2);
	  then elem;
	end matchcontinue;
end fromExpElseToAlgElse;

//---------------------------------------------------------
// Type conversion
//---------------------------------------------------------
// Exp.TypeTypes => Types.Type
//---------------------------------------------------------

public function fromTypeTypesToType "function: fromTypeTypesToType
  Exp.TypeTypes => Types.Type"
	input Exp.TypeTypes inType;
	output Types.Type outType;
algorithm
	outType :=
	matchcontinue (inType)
	  local
	    Option<Absyn.Path> p;
	    Types.Type ret;
	  case ((Exp.T_INTEGERTYPES(lst),p))
	  local
    	list<Exp.VarTypes> lst "varLstInt" ;
    	list<Types.Var> lst2;
    equation
      lst2 = fromVarTypesListToVarList(lst,{});
    	ret = ((DAE.T_INTEGER(lst2),p));
    then ret;

   case ((Exp.T_REALTYPES(lst),p))
	  local
    	list<Exp.VarTypes> lst "varLstInt" ;
    	list<Types.Var> lst2;
    equation
      lst2 = fromVarTypesListToVarList(lst,{});
    	ret = ((DAE.T_REAL(lst2),p));
    then ret;

    case ((Exp.T_STRINGTYPES(lst),p))
	  local
    	list<Exp.VarTypes> lst "varLstInt" ;
    	list<Types.Var> lst2;
    equation
      lst2 = fromVarTypesListToVarList(lst,{});
    	ret = ((DAE.T_STRING(lst2),p));
    then ret;

   	case ((Exp.T_BOOLTYPES(lst),p))
	  local
    	list<Exp.VarTypes> lst "varLstInt" ;
    	list<Types.Var> lst2;
    equation
      lst2 = fromVarTypesListToVarList(lst,{});
    	ret = ((DAE.T_BOOL(lst2),p));
    then ret;

   	case ((Exp.T_LISTTYPES(lType),p))
	  local
    	Exp.TypeTypes lType;
    	Types.Type lType2;
    equation
      lType2 = fromTypeTypesToType(lType);
    	ret = ((DAE.T_LIST(lType2),p));
    then ret;

   	case ((Exp.T_METAOPTIONTYPES(lType),p))
	  local
    	Exp.TypeTypes lType;
    	Types.Type lType2;
    equation
      lType2 = fromTypeTypesToType(lType);
    	ret = ((DAE.T_METAOPTION(lType2),p));
    then ret;

   	case ((Exp.T_METATUPLETYPES(lType),p))
	  local
    	list<Exp.TypeTypes> lType;
    	list<Types.Type> lType2;
    equation
      lType2 = Util.listMap(lType,fromTypeTypesToType);
    	ret = ((DAE.T_METATUPLE(lType2),p));
    then ret;
      
   	case ((Exp.T_UNIONTYPETYPES(records),p))
   	  local
   	    list<Absyn.Path> records;
   	  equation
   	    ret = ((DAE.T_UNIONTYPE(records),p));
   	  then ret;

//	  case ((Exp.T_ENUMTYPES(),p))
//    equation
//      ret = ((DAE.T_ENUMERATION(SOME(0),Absyn.IDENT(""),{},{}),p));
//      ret = ((DAE.T_ENUM(),p));
//    then ret;

	  case ((Exp.T_ENUMERATIONTYPES(idx,pp,lst1,lst2),p))
	  local
	    Option<Integer> idx;
	    Absyn.Path pp;
	    list<String> lst1 "names" ;
    	list<Exp.VarTypes> lst2 "varLst" ;
    	list<Types.Var> lst3;
    equation
      lst3 = fromVarTypesListToVarList(lst2,{});
      ret = ((DAE.T_ENUMERATION(idx,pp,lst1,lst3),p));
    then ret;

	  case ((Exp.T_ARRAYTYPES(arrDim,arrType),p))
	  local
	    Exp.ArrayDimTypes arrDim "arrayDim" ;
      Exp.TypeTypes arrType "arrayType" ;
      Types.ArrayDim arrDim2;
      Types.Type arrType2;
	  equation
	    arrDim2 =fromArrayDimTypesToArrayDim(arrDim);
	    arrType2 = fromTypeTypesToType(arrType);
	    ret = ((DAE.T_ARRAY(arrDim2,arrType2),p));
	  then ret;

	  case ((Exp.T_COMPLEXTYPES(s,lst,SOME(cType)),p))
	  local
		  ClassInf.State s;
      list<Exp.VarTypes> lst;
      Exp.TypeTypes cType;
      list<Types.Var> lst2;
      Types.Type cType2;
    equation
      lst2 =fromVarTypesListToVarList(lst,{});
      cType2 = fromTypeTypesToType(cType);
      ret = ((DAE.T_COMPLEX(s,lst2,SOME(cType2),NONE),p));
    then ret;

 	  case ((Exp.T_COMPLEXTYPES(s,lst,NONE()),p))
	  local
		  ClassInf.State s;
      list<Exp.VarTypes> lst;
      list<Types.Var> lst2;
		equation
		  lst2 = fromVarTypesListToVarList(lst,{});
		  ret = ((DAE.T_COMPLEX(s,lst2,NONE(),NONE),p));
		then ret;

	  case ((Exp.T_FUNCTIONTYPES(lst,fType),p))
	  local
      list<Exp.FuncArgTypes> lst;
      Exp.TypeTypes fType;
      list<Types.FuncArg> lst2;
      Types.Type fType2;
	  equation
	    lst2 = fromFuncArgTypesListToFuncArgList(lst,{});
	    fType2 = fromTypeTypesToType(fType);
	    ret = ((DAE.T_FUNCTION(lst2,fType2),p));
	  then ret;

   	case ((Exp.T_POLYMORPHICTYPES(id),p))
   	  local
   	    String id;
   	  equation
   	    ret = ((DAE.T_POLYMORPHIC(id),p));
   	  then ret;

	  case ((Exp.T_NOTYPETYPES(),p))
	  equation
	    ret = ((DAE.T_NOTYPE(),p));
	  then ret;

	  case ((Exp.T_ANYTYPETYPES(s),p))
	  local
	    Option<ClassInf.State> s;
	  equation
	  	ret = ((DAE.T_ANYTYPE(s),p));
	  then ret;
	  
	  case _
	    equation
	      Debug.fprintln("failtrace", "- Convert.fromTypeTypesToType failed");
	    then fail();
	end matchcontinue;
end fromTypeTypesToType;

public function fromVarTypesListToVarList "function: fromVarTypesListToVarList
  Exp.VarTypes 'list => Types.Var 'list"
	 input list<Exp.VarTypes> lst;
	 input list<Types.Var> accList;
	 output list<Types.Var> outLst;
algorithm
  outLst :=
  matchcontinue (lst,accList)
    local
      list<Types.Var> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
    local
      list<Exp.VarTypes> rest;
      Exp.VarTypes first;
      list<Types.Var> first2;
      list<Types.Var> lst;
    equation
      first2 = Util.listCreate(fromVarTypesToVar(first));
    	localAccList = listAppend(localAccList,first2);
     	lst = fromVarTypesListToVarList(rest,localAccList);
    	then lst;
  end matchcontinue;
end fromVarTypesListToVarList;

public function fromVarTypesToVar "function: fromVarTypesToVar
  Exp.VarTypes => Types.Var"
	input Exp.VarTypes inType;
	output Types.Var outType;
algorithm
  outType :=
  matchcontinue (inType)
    local
      Ident n;
      Exp.AttributesTypes attType;
      Boolean pro;
      Exp.TypeTypes tt;
      Types.Var ret;
    case (Exp.VARTYPES(n,attType,pro,tt,Exp.UNBOUND()))
      local
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
        ret = DAE.TYPES_VAR(n,attType2,pro,
        			tt2,DAE.UNBOUND());
      then ret;

   case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,NONE(),Exp.C_CONST())))
  	  local
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
       ret = DAE.TYPES_VAR(n,attType2,pro,
             tt2,DAE.EQBOUND(e,NONE(),DAE.C_CONST()));
      then ret;


  	case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,SOME(val),Exp.C_CONST())))
  	  local
        Values.Value val;
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
        ret = DAE.TYPES_VAR(n,attType2,pro,
          tt2,DAE.EQBOUND(e,SOME(val),DAE.C_CONST()));
      then ret;

  case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,NONE(),Exp.C_PARAM())))
  	  local
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
        ret = DAE.TYPES_VAR(n,attType2,pro,
        tt2,DAE.EQBOUND(e,NONE(),DAE.C_PARAM()));
      then ret;

  	case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,SOME(val),Exp.C_PARAM())))
  	  local
        Values.Value val;
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
        ret = DAE.TYPES_VAR(n,attType2,pro,
        tt2,DAE.EQBOUND(e,SOME(val),DAE.C_PARAM()));
      then ret;

    case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,NONE(),Exp.C_VAR())))
      local
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 = fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
      ret = DAE.TYPES_VAR(n,attType2,pro,
           tt2,DAE.EQBOUND(e,NONE(),DAE.C_VAR()));
      then ret;

    case (Exp.VARTYPES(n,attType,pro,tt,Exp.EQBOUND(e,SOME(val),Exp.C_VAR())))
      local
        Values.Value val;
        Exp.Exp e;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 = fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
      ret = DAE.TYPES_VAR(n,attType2,pro,
           tt2,DAE.EQBOUND(e,SOME(val),DAE.C_VAR()));
      then ret;

    case (Exp.VARTYPES(n,attType,pro,tt,Exp.VALBOUND(val)))
      local
        Values.Value val;
        Types.Attributes attType2;
        Types.Type tt2;
      equation
        attType2 =fromAttributesTypesToAttributes(attType);
        tt2 = fromTypeTypesToType(tt);
        ret = DAE.TYPES_VAR(n,attType2,pro,tt2,DAE.VALBOUND(val));
      then ret;
  end matchcontinue;
end fromVarTypesToVar;

public function fromAttributesTypesToAttributes "function: fromAttributesTypesToAttributes
  Exp.AttributesTypes => Types.Attributes"
	input Exp.AttributesTypes attType;
	output Types.Attributes outType;
algorithm
  outType :=
  matchcontinue (attType)
    case (Exp.ATTRTYPES(f,s,acc,par,d))
    local
    	Boolean f,s;
    	SCode.Accessibility acc;
    	SCode.Variability par;
    	Absyn.Direction d;
    	Types.Attributes ret;
    equation
      ret = DAE.ATTR(f,s,acc,par,d, Absyn.UNSPECIFIED());
    then ret;
  end matchcontinue;
end fromAttributesTypesToAttributes;

public function fromArrayDimTypesToArrayDim "function: fromArrayDimTypesToArrayDim
  Exp.ArrayDimTypes => Types.ArrayDim"
	input Exp.ArrayDimTypes arrDim;
	output Types.ArrayDim outDim;
algorithm
  outDim :=
  matchcontinue (arrDim)
    case (Exp.DIM(arg))
      local
      Types.ArrayDim ret;
      Option<Integer> arg;
      equation
      ret = DAE.DIM(arg);
    then ret;
  end matchcontinue;
end fromArrayDimTypesToArrayDim;

public function fromFuncArgTypesListToFuncArgList "function: fromFuncArgTypesListToFuncArgList
  Exp.FuncArgTypes 'list => Types.FuncArg 'list"
	 input list<Exp.FuncArgTypes> lst;
	 input list<Types.FuncArg> accList;
	 output list<Types.FuncArg> outLst;
algorithm
  outLst :=
  matchcontinue (lst,accList)
    local
      list<Types.FuncArg> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
    local
      list<Exp.FuncArgTypes> rest;
      Exp.FuncArgTypes first;
      list<Types.FuncArg> first2;
      list<Types.FuncArg> lst;
    equation
      first2 = Util.listCreate(fromFuncArgTypesToFuncArg(first));
    	localAccList = listAppend(localAccList,first2);
     	lst = fromFuncArgTypesListToFuncArgList(rest,localAccList);
    	then lst;
  end matchcontinue;
end fromFuncArgTypesListToFuncArgList;

public function fromFuncArgTypesToFuncArg "function: fromFuncArgTypesToFuncArg
  Exp.FuncArgTypes => Types.FuncArg"
	input Exp.FuncArgTypes argType;
	output Types.FuncArg outType;
algorithm
  outType :=
  matchcontinue (argType)
    case ((n,tt))
    local
    	Ident n;
    	Exp.TypeTypes tt;
    	Types.FuncArg ret;
    	Types.Type tt2;
    equation
      tt2 = fromTypeTypesToType(tt);
    	ret = ((n,tt2));
    then ret;
  end matchcontinue;
end fromFuncArgTypesToFuncArg;


//---------------------------------------------------------
// Types.Type => Exp.TypeTypes
//---------------------------------------------------------

public function fromTypeToTypeTypes "function: fromTypeToTypeTypes
  Types.Type => Exp.TypeTypes"
	input Types.Type inType;
	output Exp.TypeTypes outType;
algorithm
	outType :=
	matchcontinue (inType)
	  local
	    Option<Absyn.Path> p;
	    Exp.TypeTypes ret;
	  case ((DAE.T_INTEGER(lst),p))
	  local
    	list<Types.Var> lst "varLstInt" ;
    	list<Exp.VarTypes> temp;
    equation
      temp = fromVarListToVarTypesList(lst,{});
    	ret = ((Exp.T_INTEGERTYPES(temp),p));
    then ret;

	  case ((DAE.T_REAL(lst),p))
	  local
    	list<Types.Var> lst "varLstInt" ;
    	list<Exp.VarTypes> temp;
    equation
      temp = fromVarListToVarTypesList(lst,{});
    	ret = ((Exp.T_REALTYPES(temp),p));
    then ret;

    case ((DAE.T_STRING(lst),p))
	  local
    	list<Types.Var> lst "varLstInt" ;
    	list<Exp.VarTypes> temp;
    equation
      temp = fromVarListToVarTypesList(lst,{});
    	ret = ((Exp.T_STRINGTYPES(temp),p));
    then ret;

    case ((DAE.T_BOOL(lst),p))
	  local
    	list<Types.Var> lst "varLstInt" ;
    	list<Exp.VarTypes> temp;
    equation
      temp = fromVarListToVarTypesList(lst,{});
    	ret = ((Exp.T_BOOLTYPES(temp),p));
    then ret;

    case ((DAE.T_LIST(lType),p))
	  local
    	Exp.TypeTypes lType2;
    	Types.Type lType;
    equation
      lType2 = fromTypeToTypeTypes(lType);
    	ret = ((Exp.T_LISTTYPES(lType2),p));
    then ret;

    case ((DAE.T_METAOPTION(lType),p))
	  local
    	Exp.TypeTypes lType2;
    	Types.Type lType;
    equation
      lType2 = fromTypeToTypeTypes(lType);
    	ret = ((Exp.T_METAOPTIONTYPES(lType2),p));
    then ret;

    case ((DAE.T_METATUPLE(lType),p))
	  local
    	list<Exp.TypeTypes> lType2;
    	list<Types.Type> lType;
    equation
      lType2 = Util.listMap(lType,fromTypeToTypeTypes);
    	ret = ((Exp.T_METATUPLETYPES(lType2),p));
    then ret;

	  case ((DAE.T_UNIONTYPE(records),p))
	    local
	      list<Absyn.Path> records;
	    equation
	      ret = (Exp.T_UNIONTYPETYPES(records),p);
	    then ret;
	    
	  case ((DAE.T_ENUMERATION(idx,tp,lst1,lst2),p))
//	  case ((DAE.T_ENUM(),p))
	  local
	    Option<Integer> idx;
    	Absyn.Path tp;
	    list<String> lst1 "names" ;
    	list<Types.Var> lst2 "varLst" ;
    	list<Exp.VarTypes> temp;
    equation
      temp = fromVarListToVarTypesList(lst2,{});
      ret = ((Exp.T_ENUMERATIONTYPES(idx,tp,lst1,temp),p));
    then ret;

	  case ((DAE.T_ARRAY(arrDim,arrType),p))
	  local
	    Types.ArrayDim arrDim "arrayDim" ;
      Types.Type arrType "arrayType" ;
      Exp.ArrayDimTypes arrDim2;
      Exp.TypeTypes arrType2;
	  equation
	    arrDim2 = fromArrayDimToArrayDimTypes(arrDim);
      arrType2 = fromTypeToTypeTypes(arrType);
	    ret = ((Exp.T_ARRAYTYPES(arrDim2,arrType2),p));
	  then ret;

	  case ((DAE.T_COMPLEX(s,lst,SOME(cType),_),p))
	  local
		  ClassInf.State s;
      list<Types.Var> lst;
      Types.Type cType;
      list<Exp.VarTypes> temp;
      Exp.TypeTypes cType2;
    equation
      temp = fromVarListToVarTypesList(lst,{});
      cType2 = fromTypeToTypeTypes(cType);
      ret = ((Exp.T_COMPLEXTYPES(s,temp,SOME(cType2)),p));
    then ret;

 	  case ((DAE.T_COMPLEX(s,lst,NONE(),_),p))
	  local
		  ClassInf.State s;
      list<Types.Var> lst;
      list<Exp.VarTypes> temp;
		equation
		  temp = fromVarListToVarTypesList(lst,{});
		  ret = ((Exp.T_COMPLEXTYPES(s,temp,NONE()),p));
		then ret;

	  case ((DAE.T_FUNCTION(lst,fType),p))
	  local
      list<Types.FuncArg> lst;
      Types.Type fType;
      list<Exp.FuncArgTypes> lst2;
      Exp.TypeTypes fType2;
	  equation
	    lst2 = fromFuncArgListToFuncArgTypesList(lst,{});
	    fType2 = fromTypeToTypeTypes(fType);
	    ret = ((Exp.T_FUNCTIONTYPES(lst2,fType2),p));
	  then ret;
	    
	  case ((DAE.T_POLYMORPHIC(id),p))
	    local
	      String id;
	    equation
	      ret = (Exp.T_POLYMORPHICTYPES(id),p);
	    then ret;

	  case ((DAE.T_NOTYPE(),p))
	  equation
	    ret = ((Exp.T_NOTYPETYPES(),p));
	  then ret;

	  case ((DAE.T_ANYTYPE(s),p))
	  local
	    Option<ClassInf.State> s;
	  equation
	  	ret = ((Exp.T_ANYTYPETYPES(s),p));
	  then ret;
	    
	  case inType
	    local
	      String str;
	    equation
	      str = Types.unparseType(inType);
	      Debug.fprintln("failtrace", "- Convert.fromTypeToTypeTypes " +& str);
	    then fail();
	end matchcontinue;
end fromTypeToTypeTypes;

public function fromVarListToVarTypesList "function: fromVarListToVarTypesList
   Types.Var 'list => Exp.VarTypes 'list"
	 input list<Types.Var> lst;
	 input list<Exp.VarTypes> accList;
	 output list<Exp.VarTypes> outLst;
algorithm
  outLst :=
  matchcontinue (lst,accList)
    local
      list<Exp.VarTypes> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
    local
      list<Types.Var> rest;
      Types.Var first;
      list<Exp.VarTypes> first2,lst;
    equation
      first2 = Util.listCreate(fromVarToVarTypes(first));
    	localAccList = listAppend(localAccList,first2);
     	lst = fromVarListToVarTypesList(rest,localAccList);
    	then lst;
 end matchcontinue;
end fromVarListToVarTypesList;

public function fromVarToVarTypes "function: fromVarToVarTypes
  Types.Var => Exp.VarTypes"
	input Types.Var inType;
	output Exp.VarTypes outType;
algorithm
  outType :=
  matchcontinue (inType)
    local
      Ident n;
      Types.Attributes attType;
      Boolean pro;
      Types.Type tt;
      Exp.VarTypes ret;
    case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.UNBOUND()))
      local
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
        ret = Exp.VARTYPES(n,attType2,pro,
        			tt2,Exp.UNBOUND());
      then ret;
    case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,NONE(),DAE.C_CONST())))
  	  local
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
       ret = Exp.VARTYPES(n,attType2,pro,
             tt2,Exp.EQBOUND(e,NONE(),Exp.C_CONST()));
      then ret;

  	case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,SOME(val),DAE.C_CONST())))
  	  local
        Values.Value val;
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
        ret = Exp.VARTYPES(n,attType2,pro,tt2,Exp.EQBOUND(e,SOME(val),Exp.C_CONST()));
      then ret;

  	case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,NONE(),DAE.C_PARAM())))
  	  local
        Values.Value val;
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
        ret = Exp.VARTYPES(n,attType2,pro,
        tt2,Exp.EQBOUND(e,NONE(),Exp.C_PARAM()));
      then ret;

  	case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,SOME(val),DAE.C_PARAM())))
  	  local
        Values.Value val;
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
        ret = Exp.VARTYPES(n,attType2,pro,
        tt2,Exp.EQBOUND(e,SOME(val),Exp.C_PARAM()));
      then ret;

   case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,NONE(),DAE.C_VAR())))
      local
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 =fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
      ret = Exp.VARTYPES(n,attType2,pro,
           tt2,Exp.EQBOUND(e,NONE(),Exp.C_VAR()));
      then ret;

    case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.EQBOUND(e,SOME(val),DAE.C_VAR())))
      local
        Values.Value val;
        Exp.Exp e;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 =fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
        ret = Exp.VARTYPES(n,attType2,pro,
          tt2,Exp.EQBOUND(e,SOME(val),Exp.C_VAR()));
      then ret;

    case (DAE.TYPES_VAR(n,attType,pro,tt,DAE.VALBOUND(val)))
      local
        Values.Value val;
        Exp.AttributesTypes attType2;
        Exp.TypeTypes tt2;
      equation
        attType2 = fromAttributesToAttributesTypes(attType);
        tt2 = fromTypeToTypeTypes(tt);
     		ret = Exp.VARTYPES(n,attType2,pro,tt2,Exp.VALBOUND(val));
      then ret;
  end matchcontinue;
end fromVarToVarTypes;

public function fromAttributesToAttributesTypes "function: fromAttributesToAttributesTypes
  Types.Attributes => Exp.AttributesTypes"
	input Types.Attributes attType;
	output Exp.AttributesTypes outType;
algorithm
  outType :=
  matchcontinue (attType)
    case (DAE.ATTR(f,s,acc,par,d,io))
    local
    	Boolean f,s;
    	SCode.Accessibility acc;
    	SCode.Variability par;
    	Absyn.Direction d;
    	Absyn.InnerOuter io;
    	Exp.AttributesTypes ret;
    equation
      ret = Exp.ATTRTYPES(f,s,acc,par,d);
    then ret;
  end matchcontinue;
end fromAttributesToAttributesTypes;

public function fromArrayDimToArrayDimTypes "function: fromArrayDimToArrayDimTypes
  Types.ArrayDim => Exp.ArrayDimTypes"
	input Types.ArrayDim arrDim;
	output Exp.ArrayDimTypes outDim;
algorithm
  outDim :=
  matchcontinue (arrDim)
    case (DAE.DIM(arg))
      local
      Exp.ArrayDimTypes ret;
      Option<Integer> arg;
      equation
      ret = Exp.DIM(arg);
    then ret;
  end matchcontinue;
end fromArrayDimToArrayDimTypes;

public function fromFuncArgListToFuncArgTypesList "function: fromFuncArgListToFuncArgTypesList
   Types.FuncArg 'list => Exp.FuncArgTypes 'list"
	 input list<Types.FuncArg> lst;
	 input list<Exp.FuncArgTypes> accList;
	 output list<Exp.FuncArgTypes> outLst;
algorithm
  outLst :=
  matchcontinue (lst,accList)
    local
      list<Exp.FuncArgTypes> localAccList;
    case ({},localAccList) equation then localAccList;
    case (first :: rest,localAccList)
    local
      list<Types.FuncArg> rest;
      Types.FuncArg first;
      list<Exp.FuncArgTypes> first2,lst;
    equation
      first2 = Util.listCreate(fromFuncArgToFuncArgTypes(first));
    	localAccList = listAppend(localAccList,first2);
     	lst = fromFuncArgListToFuncArgTypesList(rest,localAccList);
    	then lst;
 end matchcontinue;
end fromFuncArgListToFuncArgTypesList;

public function fromFuncArgToFuncArgTypes "function: fromFuncArgToFuncArgTypes
  Types.FuncArg => Exp.FuncArgTypes"
	input Types.FuncArg argType;
	output Exp.FuncArgTypes outType;
algorithm
  outType :=
  matchcontinue (argType)
    case ((n,tt))
    local
    	Ident n;
    	Types.Type tt;
    	Exp.FuncArgTypes ret;
    	Exp.TypeTypes tt2;
    equation
      tt2 = fromTypeToTypeTypes(tt);
    	ret = ((n,tt2));
    then ret;
  end matchcontinue;
end fromFuncArgToFuncArgTypes;

public function fromDAEeqsToAbsynAlg "function: fromDAEeqsToAbsynAlg"
  input list<DAE.Element> ld;
  input list<Absyn.AlgorithmItem> accList1;
  input list<DAE.Element> accList2;
  output list<Absyn.AlgorithmItem> outList;
  output list<DAE.Element> outLd;
algorithm
  (outList,outLd) :=
  matchcontinue (ld,accList1,accList2)
    local
      list<Absyn.AlgorithmItem> localAccList1;
      list<DAE.Element> restLd,localAccList2;
    case ({},localAccList1,localAccList2) then (localAccList1,localAccList2);
    case (DAE.EQUATION(exp1,exp2) :: restLd,localAccList1,localAccList2)
      local
        list<Absyn.AlgorithmItem> stmt;
        Exp.Exp exp1,exp2;
        Absyn.Exp left,right;
      equation
        left = fromExpExpToAbsynExp(exp1);
        right = fromExpExpToAbsynExp(exp2);
        stmt = {Absyn.ALGORITHMITEM(Absyn.ALG_ASSIGN(left,right),NONE())};
        localAccList1 = listAppend(localAccList1,stmt);
        (localAccList1,localAccList2) = fromDAEeqsToAbsynAlg(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
    case (firstLd :: restLd,localAccList1,localAccList2)
      local
        DAE.Element firstLd;
      equation
        localAccList2 = listAppend(localAccList2,{firstLd});
        (localAccList1,localAccList2) = fromDAEeqsToAbsynAlg(restLd,localAccList1,localAccList2);
      then (localAccList1,localAccList2);
  end matchcontinue;
end fromDAEeqsToAbsynAlg;

// More expressions have to be added?
public function fromExpExpToAbsynExp "function: fromExpExpToAbsynExp"
  input Exp.Exp exp1;
  output Absyn.Exp expOut;
algorithm
  expOut :=
  matchcontinue (exp1)
    case (Exp.ICONST(i)) local Integer i; equation then Absyn.INTEGER(i);
    case (Exp.RCONST(r)) local Real r; equation then Absyn.REAL(r);
    case (Exp.SCONST(s)) local String s; equation then Absyn.STRING(s);
    case (Exp.BCONST(b)) local Boolean b; equation then Absyn.BOOL(b);
    case (Exp.CREF(cr,_))
      local
        Exp.ComponentRef cr;
        Absyn.ComponentRef c;
      equation
        c = fromExpCrefToAbsynCref(cr);
      then Absyn.CREF(c);
  end matchcontinue;
end fromExpExpToAbsynExp;

public function fromExpCrefToAbsynCref
  input Exp.ComponentRef cIn;
  output Absyn.ComponentRef cOut;
algorithm
  cOut := matchcontinue (cIn)
      local
        Exp.Ident id;
        list<Exp.Subscript> subScriptList;
        list<Absyn.Subscript> subScriptList2;
        Exp.ComponentRef cRef;
        Absyn.ComponentRef elem,cRef2;  
    case (Exp.CREF_QUAL(id,_,subScriptList,cRef))
      equation
        cRef2 = fromExpCrefToAbsynCref(cRef);
        subScriptList2 = fromExpSubsToAbsynSubs(subScriptList,{});
        elem = Absyn.CREF_QUAL(id,subScriptList2,cRef2);
      then elem;
    case (Exp.CREF_IDENT(id,_,subScriptList))
      equation
        subScriptList2 = fromExpSubsToAbsynSubs(subScriptList,{});
        elem = Absyn.CREF_IDENT(id,subScriptList2);
      then elem;
  end matchcontinue;
  end fromExpCrefToAbsynCref;

public function fromExpSubsToAbsynSubs
  input list<Exp.Subscript> inList;
  input list<Absyn.Subscript> accList;
  output list<Absyn.Subscript> outList;
algorithm
  outList :=
  matchcontinue (inList,accList)
    local
      list<Absyn.Subscript> localAccList;
    case ({},localAccList) then localAccList;
    case (Exp.INDEX(e) :: restList,localAccList)
      local
        Exp.Exp e;
        Absyn.Exp e2;
        Absyn.Subscript elem;
        list<Exp.Subscript> restList;
      equation
        e2 = fromExpExpToAbsynExp(e);
        elem = Absyn.SUBSCRIPT(e2);
        localAccList = listAppend(localAccList,{elem});
        localAccList = fromExpSubsToAbsynSubs(restList,localAccList);
      then localAccList;
  end matchcontinue;
end fromExpSubsToAbsynSubs;

end Convert;





