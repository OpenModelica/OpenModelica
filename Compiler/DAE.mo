package DAE "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet, Department of
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
  contributors may be used to endorse or promote products derived from
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

  
  file:	 DAE.mo
  module:      DAE
  description: DAE management and output
 
  RCS: $Id$
  
  This module defines data structures for DAE equations and 
  declarations of variables and functions. It also exports some help
  functions for other modules. The DAE data structure is the result of
  flattening, containing only flat modelica, i.e. equations, algorithms,
  variables and functions. 
 
  

  - Module header"

public import Absyn;
public import Exp;
public import Algorithm;
public import Types;
public import Values;
public import ClassInf;

public 
type Ident = String;

public 
type InstDims = list<Exp.Subscript>;

public 
type StartValue = Option<Exp.Exp>;

public 
uniontype VarKind
  record VARIABLE end VARIABLE;

  record DISCRETE end DISCRETE;

  record PARAM end PARAM;

  record CONST end CONST;

end VarKind;

public 
uniontype Type
  record REAL end REAL;

  record INT end INT;

  record BOOL end BOOL;

  record STRING end STRING;

  record ENUM end ENUM;

  record ENUMERATION
    list<String> stringLst;
  end ENUMERATION;
  
  record EXT_OBJECT
    Absyn.Path fullClassName;
  end EXT_OBJECT;  

end Type;

public 
uniontype Flow "The Flow of a variable indicates if it is a Flow variable or not, or if
   it is not a connector variable at all."
  record FLOW end FLOW;

  record NON_FLOW end NON_FLOW;

  record NON_CONNECTOR end NON_CONNECTOR;

end Flow;

public 
uniontype VarDirection
  record INPUT end INPUT;

  record OUTPUT end OUTPUT;

  record BIDIR end BIDIR;

end VarDirection;

public 
uniontype Element
  record VAR
    Exp.ComponentRef componentRef " The variable name";
    VarKind varible "varible kind" ;
    VarDirection variable "variable, constant, parameter, etc." ;
    Type input_ "input, output or bidir" ;
    Option<Exp.Exp> one "one of the builtin types" ;
    InstDims binding "Binding expression e.g. for parameters" ;
    StartValue dimension "dimension of original component" ;
    Flow value "value of start attribute" ;
    list<Absyn.Path> flow_ "Flow of connector variable. Needed for 
						unconnected flow variables" ;
    Option<VariableAttributes> variableAttributesOption;
    Option<Absyn.Comment> absynCommentOption;
    Absyn.InnerOuter innerOuter "inner/outer required to 'change' outer references";
    Types.Type fullType "Full type information required to analyze inner/outer elements";
  end VAR;

  record DEFINE "A solved equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end DEFINE;

  record INITIALDEFINE " A solved initial equation"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end INITIALDEFINE;

  record EQUATION "Scalar equation"
    Exp.Exp exp;
    Exp.Exp scalar ;
  end EQUATION;

  record ARRAY_EQUATION " an array equation"
    list<Integer> dimension "dimension sizes" ;
    Exp.Exp exp;
    Exp.Exp array  ;
  end ARRAY_EQUATION;

  record WHEN_EQUATION " a when equation"
    Exp.Exp condition "Condition" ;
    list<Element> equations "Equations" ;
    Option<Element> elsewhen_ "Elsewhen should be of type WHEN_EQUATION" ;
  end WHEN_EQUATION;

  record IF_EQUATION " an if-equation"
    Exp.Exp condition1 "Condition" ;
    list<Element> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end IF_EQUATION;

  record INITIAL_IF_EQUATION "An initial if-equation"
    Exp.Exp condition1 "Condition" ;
    list<Element> equations2 "Equations of true branch" ;
    list<Element> equations3 "Equations of false branch" ;
  end INITIAL_IF_EQUATION;

  record INITIALEQUATION " An initial equaton"
    Exp.Exp exp1;
    Exp.Exp exp2;
  end INITIALEQUATION;

  record ALGORITHM " An algorithm section"
    Algorithm.Algorithm algorithm_;
  end ALGORITHM;

  record INITIALALGORITHM " An initial algorithm section"
    Algorithm.Algorithm algorithm_;
  end INITIALALGORITHM;

  record COMP
    Ident ident;
    DAElist dAElist "a component with 
						    subelements, normally 
						    only used at top level." ;
  end COMP;

  record FUNCTION " A Modelica function"
    Absyn.Path path;
    DAElist dAElist;
    Types.Type type_;
  end FUNCTION;

  record EXTFUNCTION "An external function"
    Absyn.Path path;
    DAElist dAElist;
    Types.Type type_;
    ExternalDecl externalDecl;
  end EXTFUNCTION;
  
  record EXTOBJECTCLASS "The 'class' of an external object"
    Absyn.Path path "className of external object";
    Element constructor "constructor is an EXTFUNCTION";
    Element destructor "destructor is an EXTFUNCTION";
  end EXTOBJECTCLASS;
  
  record ASSERT " The Modelica builtin assert"
    Exp.Exp exp;
  end ASSERT;

  record REINIT " reinit operator for reinitialization of states"
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end REINIT;

end Element;

public 
uniontype VariableAttributes
  record VAR_ATTR_REAL
    Option<String> quantity "quantity" ;
    Option<String> unit "unit" ;
    Option<String> displayUnit "displayUnit" ;
    tuple<Option<Real>, Option<Real>> min "min , max" ;
    Option<Real> initial_ "Initial value" ;
    Option<Boolean> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
    Option<Real> nominal "nominal" ;
    Option<StateSelect> stateSelectOption;
  end VAR_ATTR_REAL;

  record VAR_ATTR_INT
    Option<String> quantity "quantity" ;
    tuple<Option<Integer>, Option<Integer>> min "min , max" ;
    Option<Integer> initial_ "Initial value" ;
    Option<Boolean> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
  end VAR_ATTR_INT;

  record VAR_ATTR_BOOL
    Option<String> quantity "quantity" ;
    Option<Boolean> initial_ "Initial value" ;
    Option<Boolean> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
  end VAR_ATTR_BOOL;

  record VAR_ATTR_STRING
    Option<String> quantity "quantity" ;
    Option<String> initial_ "Initial value" ;
  end VAR_ATTR_STRING;

  record VAR_ATTR_ENUMERATION
    Option<String> quantity "quantity" ;
    tuple<Option<Exp.Exp>, Option<Exp.Exp>> min "min , max" ;
    Option<Exp.Exp> start "start" ;
    Option<Boolean> fixed "fixed - true: default for parameter/constant, false - default for other variables" ;
  end VAR_ATTR_ENUMERATION;

end VariableAttributes;

public 
uniontype StateSelect
  record NEVER end NEVER;

  record AVOID end AVOID;

  record DEFAULT end DEFAULT;

  record PREFER end PREFER;

  record ALWAYS end ALWAYS;

end StateSelect;

public 
uniontype ExtArg
  record EXTARG
    Exp.ComponentRef componentRef;
    Types.Attributes attributes;
    Types.Type type_;
  end EXTARG;

  record EXTARGEXP
    Exp.Exp exp;
    Types.Type type_;
  end EXTARGEXP;

  record EXTARGSIZE
    Exp.ComponentRef componentRef;
    Types.Attributes attributes;
    Types.Type type_;
    Exp.Exp exp;
  end EXTARGSIZE;

  record NOEXTARG end NOEXTARG;

end ExtArg;

public 
uniontype ExternalDecl
  record EXTERNALDECL
    Ident ident;
    list<ExtArg> external_ "external function name" ;
    ExtArg parameters "parameters" ;
    String returnType "return type" ;
    Option<Absyn.Annotation> language "language e.g. Library" ;
  end EXTERNALDECL;

end ExternalDecl;

public 
uniontype DAElist "A DAElist is a list of Elements. Variables, equations, functions, 
  algorithms, etc. are all found in this list.
"
  record DAE
    list<Element> elementLst;
  end DAE;

end DAElist;

protected import RTOpts;
protected import Graphviz;
protected import Dump;
protected import Print;
protected import Util;
protected import Ceval;
protected import ModUtil;
protected import Debug;
protected import Error;
protected import SCode;
protected import Env;

public function removeEquations "Removes all equations and algorithms, from the dae"
	input list<Element> inDae;
	output list<Element> outDae;
algorithm
	inDae := matchcontinue(inDae)
	local Element v,e;
	      list<Element> elts,elts2,elts22,elts1,elts11;
	      Ident  id;
	  case({}) then  {};
	    
	  case((v as VAR(componentRef=_))::elts) equation
	    elts2=removeEquations(elts);
	    then v::elts2;
	  case(COMP(id,DAE(elts1))::elts2) equation
	    elts11 = removeEquations(elts1);
	    elts22 = removeEquations(elts2);
	  then COMP(id,DAE(elts11))::elts22;
	  case(EQUATION(_,_)::elts2) then removeEquations(elts2);
	  case(INITIALEQUATION(_,_)::elts2) then removeEquations(elts2);
	  case(ARRAY_EQUATION(_,_,_)::elts2) then removeEquations(elts2);
	  case(INITIALDEFINE(_,_)::elts2) then removeEquations(elts2);	    
	  case(DEFINE(_,_)::elts2) then removeEquations(elts2);	    	    
	  case(WHEN_EQUATION(_,_,_)::elts2) then removeEquations(elts2);	    	    
	  case(IF_EQUATION(_,_,_)::elts2) then removeEquations(elts2);	    	    	    
	  case(INITIAL_IF_EQUATION(_,_,_)::elts2) then removeEquations(elts2);	    	    	    	    
	  case(ALGORITHM(_)::elts2) then removeEquations(elts2);
	  case(INITIALALGORITHM(_)::elts2) then removeEquations(elts2);
	  case((e as FUNCTION(path=_))::elts2) equation
	    elts22 = removeEquations(elts2);
    then e::elts22;
	  case((e as EXTFUNCTION(path=_))::elts2) equation
	    elts22 = removeEquations(elts2);
    then e::elts22;	      
	  case((e as EXTOBJECTCLASS(path=_))::elts2) equation
	    elts22 = removeEquations(elts2);
    then e::elts22;	            
	  case(ASSERT(_)::elts2) then removeEquations(elts2);
	  case(REINIT(_,_)::elts2) then removeEquations(elts2);	    
	end matchcontinue;  
  
end removeEquations;

public function removeVariables "Remove the variables in the list from the DAE"
  input list<Element> dae;
  input list<Exp.ComponentRef> vars;
  output list<Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeVariable,dae);
end removeVariables;

public function removeVariable "Remove the variable from the DAE"
  input Exp.ComponentRef var;
  input list<Element> dae;
  output list<Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
   			local Exp.ComponentRef cr;
   			  list<Element> elist,elist2;
   			  Element e,v;
   			  Ident id;
     case(var,{}) then {};
     case(var,(v as VAR(componentRef = cr))::dae) equation
       true = Exp.crefEqual(var,cr);
     then dae;
     case(var,COMP(id,DAE(elist))::dae) equation
       elist2=removeVariable(var,elist);
       dae = removeVariable(var,dae);
     then COMP(id,DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeVariable(var,dae);
      then e::dae;        
   end matchcontinue;
end removeVariable;

public function removeInnerAttrs "Remove the inner attribute of all vars in list"
  input list<Element> dae;
  input list<Exp.ComponentRef> vars;
  output list<Element> outDae;
algorithm
  outDae := Util.listFold(vars,removeInnerAttr,dae);
end removeInnerAttrs;

public function removeInnerAttr "Remove the inner attribute from variable in the DAE"
  input Exp.ComponentRef var;
  input list<Element> dae;
  output list<Element> outDae;
algorithm
   outDae := matchcontinue(var,dae)
   			local Exp.ComponentRef cr;
   			  list<Element> elist,elist2;
   			  Element e,v;
   			  Ident id;
   			  Exp.ComponentRef cr;
   			  VarKind kind;
   			  VarDirection dir;
    			Type tp;
   			  Option<Exp.Exp> bind;
   			  InstDims dim;
    			StartValue start;
    			Flow flow_;
   			  list<Absyn.Path> cls;
    			Option<VariableAttributes> attr;
   			  Option<Absyn.Comment> cmt;
    			Absyn.InnerOuter io,io2;
   			  Types.Type ftp;
     case(var,{}) then {};
     case(var,VAR(cr,kind,dir,tp,bind,dim,start,flow_,cls,attr,cmt,io,ftp)::dae) equation
       true = Exp.crefEqual(var,cr);
       io2 = removeInnerAttribute(io);
     then VAR(cr,kind,dir,tp,bind,dim,start,flow_,cls,attr,cmt,io2,ftp)::dae;
     case(var,COMP(id,DAE(elist))::dae) equation
       elist2=removeInnerAttr(var,elist);
       dae = removeInnerAttr(var,dae);
     then COMP(id,DAE(elist2))::dae;
     case(var,e::dae) equation
         dae = removeInnerAttr(var,dae);
      then e::dae;        
   end matchcontinue;
end removeInnerAttr;

protected function removeInnerAttribute "Help function to removeInnerAttr"
	 input Absyn.InnerOuter io;
	 output Absyn.InnerOuter ioOut;
algorithm
  ioOut := matchcontinue(io)
    case(Absyn.INNER()) then Absyn.UNSPECIFIED();
    case(Absyn.INNEROUTER()) then Absyn.OUTER();
    case(io) then io;
  end matchcontinue;
end removeInnerAttribute;

public function varCref " returns the component reference of a variable"
input Element elt;
output Exp.ComponentRef cr;
algorithm
  cr := matchcontinue(elt)
    case(VAR(componentRef = cr)) then cr;
  end matchcontinue;
end varCref;

public function printDAE "function: printDEA
 
  This function prints out a list of elements (i.e. a DAE)
  to the stdout. Useful for example when called from Inst.instClass"
  input DAElist inDAElist;
algorithm  
  _:=
  matchcontinue (inDAElist)
    local
    	DAElist dae;
    	String str;
    case dae 
      equation
        Print.clearBuf();
        dump2(dae);
        str = Print.getString();
        print(str);
      then 
        ();
  end matchcontinue;
end printDAE;        


public function dump "function: dump
 
  This function prints the DAE in the standard output format.
"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local list<Element> daelist;
    case DAE(elementLst = daelist)
      equation 
        Util.listMap0(daelist, dumpFunction);
        Util.listMap0(daelist, dumpExtObjectClass);
        Util.listMap0(daelist, dumpCompElement);
      then
        ();
  end matchcontinue;
end dump;

public function dump2 "function: dump2
 
  Helper function to dump. Prints the DAE using module Print.
"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local
      Ident comment_str,ident,str,extdeclstr;
      Exp.ComponentRef cr;
      Exp.Exp e,e1,e2;
      InstDims dims;
      Option<Exp.Exp> start;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<Element> xs;
      DAElist lst,dae;
      Absyn.Path path;
      tuple<Types.TType, Option<Absyn.Path>> tp;
      ExternalDecl extdecl;
    case DAE(elementLst = (VAR(componentRef = cr,one = SOME(e),binding = dims,dimension = start,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf("=");
        Exp.printExp(e);
        Print.printBuf(",dims=");
        Dump.printList(dims, Exp.printSubscript, ", ");
        comment_str = Dump.unparseCommentOption(comment) "	dump_start_value start &" ;
        print("  comment:");
        print(comment_str);
        print(",\n ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (VAR(componentRef = cr,one = NONE,dimension = start,variableAttributesOption = dae_var_attr,absynCommentOption = comment) :: xs))
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        comment_str = Dump.unparseCommentOption(comment) "	dump_start_value start &" ;
        print("  comment:");
        print(comment_str);
        print(",\n ");
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (DEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (INITIALDEFINE(componentRef = cr) :: xs))
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case DAE(elementLst = (INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (ALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("ALGORITHM(...)");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (INITIALALGORITHM(algorithm_ = _) :: xs)))
      equation 
        Print.printBuf("INITIALALGORITHM(...)");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (COMP(ident = ident,dAElist = lst) :: xs)))
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(ident);
        dump2(lst);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (FUNCTION(path = _) :: xs)))
      equation 
        Print.printBuf("FUNCTION(...)\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (EXTFUNCTION(path = path,dAElist = dae,type_ = tp,externalDecl = extdecl) :: xs)))
      equation 
        Print.printBuf("EXTFUNCTION(\n");
        str = Absyn.pathString(path);
        Print.printBuf(str);
        Print.printBuf(", ");
        dump2(dae);
        Print.printBuf(", ");
        Types.printType(tp);
        Print.printBuf(", ");
        extdeclstr = dumpExtDeclStr(extdecl);
        Print.printBuf(extdeclstr);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = (ASSERT(exp = e) :: xs)))
      equation 
        Print.printBuf("ASSERT(\n");
        Exp.printExp(e);
        Print.printBuf(")\n");
        dump2(DAE(xs));
      then
        ();
    case (DAE(elementLst = {})) then (); 
    case (_)
      equation 
        Print.printBuf("dump2 failed\n");
      then
        ();
  end matchcontinue;
end dump2;

protected function dumpStartValue "function: dumpStartValue
 
  Dumps the StartValue for a variable.
"
  input StartValue inStartValue;
algorithm 
  _:=
  matchcontinue (inStartValue)
    local Exp.Exp e;
    case (SOME(e))
      equation 
        Print.printBuf("(start=");
        Exp.printExp(e);
        Print.printBuf(")");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpStartValue;

protected function dumpStartValueStr "function: dumpStartValueStr
 
  Dumps the start value for a variable to a string.
"
  input StartValue inStartValue;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStartValue)
    local
      Ident s,res;
      Exp.Exp e;
    case (SOME(e))
      equation 
        s = Exp.printExpStr(e);
        res = Util.stringAppendList({"(start=",s,")"});
      then
        res;
    case (_) then ""; 
  end matchcontinue;
end dumpStartValueStr;

public function dumpExtDeclStr "function: dumpExtDeclStr
 
  Dumps the external declaration to a string.
"
  input ExternalDecl inExternalDecl;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExternalDecl)
    local
      Ident extargsstr,rettystr,str,id,lang;
      list<ExtArg> extargs;
      ExtArg retty;
      Option<Absyn.Annotation> ann;
    case EXTERNALDECL(ident = id,external_ = extargs,parameters = retty,returnType = lang,language = ann)
      equation 
        extargsstr = Dump.getStringList(extargs, dumpExtArgStr, ",");
        rettystr = dumpExtArgStr(retty);
        str = Util.stringAppendList(
          {"EXTERNALDECL(",id,", (",extargsstr,"), ",rettystr,", \"",
          lang,"\")"});
      then
        str;
  end matchcontinue;
end dumpExtDeclStr;

public function dumpExtArgStr "function: dumpExtArgStr
 
  Helper function to dump_ext_decl_str
"
  input ExtArg inExtArg;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExtArg)
    local
      Ident crstr,dirstr,tystr,str,dimstr;
      Exp.ComponentRef cr;
      Boolean fl;
      SCode.Accessibility acc;
      SCode.Variability var;
      Absyn.Direction dir;
      tuple<Types.TType, Option<Absyn.Path>> ty;
      Exp.Exp exp,dim;
      Types.Attributes attr;
    case NOEXTARG() then "void"; 
    case EXTARG(componentRef = cr,attributes = Types.ATTR(flow_ = fl,accessibility = acc,parameter_ = var,direction = dir),type_ = ty)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dirstr = Dump.directionSymbol(dir);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({dirstr," ",tystr," ",crstr});
      then
        str;
    case EXTARGEXP(exp = exp,type_ = ty)
      equation 
        crstr = Exp.printExpStr(exp);
        tystr = Types.getTypeName(ty);
        str = Util.stringAppendList({"(",tystr,") ",crstr});
      then
        str;
    case EXTARGSIZE(componentRef = cr,attributes = attr,type_ = ty,exp = dim)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        dimstr = Exp.printExpStr(dim);
        str = Util.stringAppendList({"size(",crstr,",",dimstr,")"});
      then
        str;
  end matchcontinue;
end dumpExtArgStr;

public function dumpStr "function: dumpStr
  
  This function prints the DAE to a string.
"
  input DAElist inDAElist;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inDAElist)
    local
      list<Ident> flist,clist,slist,extlist;
      Ident str;
      list<Element> daelist;
    case DAE(elementLst = daelist)
      equation 
        flist = Util.listMap(daelist, dumpFunctionStr);
        extlist = Util.listMap(daelist, dumpExtObjClassStr);
        clist = Util.listMap(daelist, dumpCompElementStr);
        slist = Util.listFlatten({flist,extlist, clist});
        str = Util.stringAppendList(slist);
      then
        str;
  end matchcontinue;
end dumpStr;

protected function dumpCompElement "function: dumpCompElement
 
  Dumps Component elements.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident n;
      list<Element> l;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        Print.printBuf("fclass ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        Print.printBuf("class ");
        Print.printBuf(n);
        Print.printBuf("\n");
        dumpElements(l);
        Print.printBuf("end ");
        Print.printBuf(n);
        Print.printBuf(";\n");
      then
        ();
    case _ then ();  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElement;

protected function dumpCompElementStr "function: dumpCompElementStr
 
  Dumps components to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,s5,s6,str,n;
      list<Element> l;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        false = RTOpts.modelicaOutput();
        s1 = stringAppend("fclass ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case COMP(ident = n,dAElist = DAE(elementLst = l))
      equation 
        true = RTOpts.modelicaOutput();
        s1 = stringAppend("class ", n);
        s2 = stringAppend(s1, "\n");
        s3 = dumpElementsStr(l);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, "end ");
        s6 = stringAppend(s5, n);
        str = stringAppend(s6, ";\n");
      then
        str;
    case _ then "";  /* LS: for non-COMPS, which are only FUNCTIONS at the moment */ 
  end matchcontinue;
end dumpCompElementStr;

public function dumpElements "function: dumpElements
 
  Dump elements. 
"
  input list<Element> l;
algorithm 
  dumpVars(l);
  Util.listMap0(l, dumpExtObjectClass);
  Print.printBuf("initial equation\n");
  Util.listMap0(l, dumpInitialequation);
  Print.printBuf("equation\n");
  Util.listMap0(l, dumpEquation);
  Util.listMap0(l, dumpInitialalgorithm);
  Util.listMap0(l, dumpAlgorithm);
  Util.listMap0(l, dumpCompElement);
  
end dumpElements;

public function dumpElementsStr "function: dumpElementsStr
 
  Dump elements to a string
"
  input list<Element> l;
  output String str;
  Ident s0,s1,s2,s3,s4,s5,initeqstr,initalgstr,eqstr,algstr;
  Boolean noiniteq,noinitalg,noeq,noalg;
algorithm 
  s1 := dumpVarsStr(l);
  s2 := dumpInitialequationsStr(l);
  s3 := dumpEquationsStr(l);
  s4 := dumpInitialalgorithmsStr(l);
  s5 := dumpAlgorithmsStr(l);
  noiniteq := stringEqual(s2, "");
  noinitalg := stringEqual(s4, "");
  noeq := stringEqual(s3, "");
  noalg := stringEqual(s5, "");
  initeqstr := Dump.selectString(noiniteq, "", "initial equation\n");
  initalgstr := Dump.selectString(noinitalg, "", "initial algorithm\n");
  eqstr := Dump.selectString(noeq, "", "equation\n");
  algstr := Dump.selectString(noalg, "", "algorithm\n");
  s0 := Util.stringDelimitListNonEmptyElts(Util.listMap(l,dumpExtObjClassStr),"\n");
  str := Util.stringAppendList({s0,s1,initeqstr,s2,initalgstr,s4,eqstr,s3,algstr,s5});
end dumpElementsStr;

public function dumpAlgorithmsStr "function: dumpAlgorithmsStr
 
  Dump algorithms to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,str;
      list<Algorithm.Statement> stmts;
      list<Element> xs;
    case ((ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpAlgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpAlgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpAlgorithmsStr;

protected function dumpInitialalgorithmsStr "function: dumpInitialalgorithmsStr
 
  Dump initialalgorithms to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,str;
      list<Algorithm.Statement> stmts;
      list<Element> xs;
    case ((INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts)) :: xs))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        s2 = stringAppend("algorithm\n", s1);
        s3 = dumpInitialalgorithmsStr(xs);
        str = stringAppend(s1, s3);
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialalgorithmsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialalgorithmsStr;

protected function dumpEquationsStr "function: dumpEquationsStr
 
  Dump equations to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,s4,s4_1,s5,s6,str,s;
      Exp.Exp e1,e2,e;
      list<Element> xs,xs1,xs2;
      Exp.ComponentRef c,cr;
    case ((EQUATION(exp = e1,scalar = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((ARRAY_EQUATION(exp = e1,array = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((DEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpEquationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((ASSERT(exp = e) :: xs))
      equation 
        s = Exp.printExpStr(e);
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({s,";\n",s2});
      then
        str;
    case ((IF_EQUATION(condition1 = c,equations2 = xs1,equations3 = xs2) :: xs))
      local Exp.Exp c;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr(xs2);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = SOME(xs2)) :: xs))
      local
        Exp.Exp c;
        Element xs2;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s2 = dumpEquationsStr((xs2 :: xs));
        str = Util.stringAppendList({"when ",s," then\n",s1,"  else",s2});
      then
        str;
    case ((WHEN_EQUATION(condition = c,equations = xs1,elsewhen_ = NONE) :: xs))
      local Exp.Exp c;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpEquationsStr(xs1);
        s3 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  when ",s," then\n",s1,"  end when;\n",s3});
      then
        str;
    case ((REINIT(componentRef = cr,exp = e) :: xs))
      equation 
        s = Exp.printComponentRefStr(cr);
        s1 = Exp.printExpStr(e);
        s2 = dumpEquationsStr(xs);
        str = Util.stringAppendList({"  reinit(",s,",",s1,");\n",s2});
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpEquationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpEquationsStr;

protected function dumpInitialequationsStr "function: dumpInitialequationsStr
 
  Dump initial equations to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,s3,s4,s4_1,s5,s6,str,s;
      Exp.Exp e1,e2,e;
      list<Element> xs,xs1,xs2;
      Exp.ComponentRef c;
    case ((INITIALEQUATION(exp1 = e1,exp2 = e2) :: xs))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((INITIALDEFINE(componentRef = c,exp = e) :: xs))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " := ");
        s4 = Exp.printExpStr(e);
        s4_1 = stringAppend(s3, s4);
        s5 = stringAppend(s4_1, ";\n");
        s6 = dumpInitialequationsStr(xs);
        str = stringAppend(s5, s6);
      then
        str;
    case ((INITIAL_IF_EQUATION(condition1 = c,equations2 = xs1,equations3 = xs2) :: xs))
      local Exp.Exp c;
      equation 
        s = Exp.printExpStr(c);
        s1 = dumpInitialequationsStr(xs1);
        s2 = dumpInitialequationsStr(xs2);
        s3 = dumpInitialequationsStr(xs);
        str = Util.stringAppendList({"  if ",s," then\n",s1,"  else\n",s2,"  end if;\n",s3});
      then
        str;
    case ((_ :: xs))
      equation 
        str = dumpInitialequationsStr(xs);
      then
        str;
    case ({}) then ""; 
  end matchcontinue;
end dumpInitialequationsStr;

protected function dumpVars "function: dumpVars
 
  Dump variables to Print buffer.
"
  input list<Element> lst;
  Ident str;
algorithm 
  str := dumpVarsStr(lst);
  Print.printBuf(str);
end dumpVars;

protected function dumpVarsStr "function: dumpVarsStr
 
  Dump variables to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident s1,s2,str;
      Element first;
      list<Element> rest;
    case {} then ""; 
    case (first :: rest)
      equation 
        s1 = dumpVarStr(first);
        s2 = dumpVarsStr(rest);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end dumpVarsStr;

protected function dumpKind "function: dumpKind
 
  Dump VarKind.
"
  input VarKind inVarKind;
algorithm 
  _:=
  matchcontinue (inVarKind)
    case CONST()
      equation 
        Print.printBuf(" constant  ");
      then
        ();
    case PARAM()
      equation 
        Print.printBuf(" parameter ");
      then
        ();
    case DISCRETE()
      equation 
        Print.printBuf(" discrete  ");
      then
        ();
    case VARIABLE()
      equation 
        Print.printBuf("           ");
      then
        ();
  end matchcontinue;
end dumpKind;

protected function dumpKindStr "function: dumpKindStr 
 
  Dump VarKind to a string.
"
  input VarKind inVarKind;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarKind)
    case CONST() then "constant "; 
    case PARAM() then "parameter "; 
    case DISCRETE() then "discrete "; 
    case VARIABLE() then ""; 
  end matchcontinue;
end dumpKindStr;

protected function dumpDirection "function: dumpDirection
 
  Dump VarDirection.
"
  input VarDirection inVarDirection;
algorithm 
  _:=
  matchcontinue (inVarDirection)
    case INPUT()
      equation 
        Print.printBuf(" input  ");
      then
        ();
    case OUTPUT()
      equation 
        Print.printBuf(" output ");
      then
        ();
    case BIDIR()
      equation 
        Print.printBuf("        ");
      then
        ();
  end matchcontinue;
end dumpDirection;

public function dumpDirectionStr "function: dumpDirectionStr
 
  Dump VarDirection to a string
"
  input VarDirection inVarDirection;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVarDirection)
    case INPUT() then "input "; 
    case OUTPUT() then "output "; 
    case BIDIR() then ""; 
  end matchcontinue;
end dumpDirectionStr;

protected function dumpStateSelectStr "function dumpStateSelectStr
 
  Dump StateSelect to a string.
"
  input StateSelect inStateSelect;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStateSelect)
    case (NEVER()) then "StateSelect.never"; 
    case (AVOID()) then "StateSelect.avoid"; 
    case (PREFER()) then "StateSelect.prefer"; 
    case (ALWAYS()) then "StateSelect.always"; 
    case (DEFAULT()) then "StateSelect.default"; 
  end matchcontinue;
end dumpStateSelectStr;

public function dumpVariableAttributes "function: dumpVariableAttributes 
 
  Dump VariableAttributes option.
"
  input Option<VariableAttributes> attr;
  Ident res;
algorithm 
  res := dumpVariableAttributesStr(attr);
  Print.printBuf(res);
end dumpVariableAttributes;

public function getStartAttrString "function: getStartAttrString
 
  Return the start attribute as a string.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      Ident s;
      Real r;
      Integer i;
    case (NONE) then ""; 
    case (SOME(VAR_ATTR_REAL(_,_,_,_,SOME(r),_,_,_)))
      equation 
        s = realString(r);
      then
        s;
    case (SOME(VAR_ATTR_INT(_,_,SOME(i),_)))
      equation 
        s = intString(i);
      then
        s;
    case (_) then ""; 
  end matchcontinue;
end getStartAttrString;

protected function stringToString "function: stringToString
 
  Convert a string to a Modelica string, enclosed in citation marks.
"
  input String str;
  output String str_1;
  Ident str_1;
algorithm 
  str_1 := Util.stringAppendList({"\"",str,"\""});
end stringToString;

public function dumpVariableAttributesStr "function: dumpVariableAttributesStr
 
  Dump VariableAttributes option to a string.
"
  input Option<VariableAttributes> inVariableAttributesOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inVariableAttributesOption)
    local
      Ident quantity,unit_str,displayUnit_str,stateSel_str,min_str,max_str,nominal_str,Initial_str,fixed_str,res_1,res1,res;
      Boolean is_empty;
      Option<Ident> quant,unit,displayUnit;
      Option<Real> min,max,Initial,nominal;
      Option<Boolean> fixed;
      Option<StateSelect> stateSel;
    case (SOME(VAR_ATTR_REAL(quant,unit,displayUnit,(min,max),Initial,fixed,nominal,stateSel)))
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, stringToString, "quantity = ");
        unit_str = Dump.getOptionWithConcatStr(unit, stringToString, "unit = ");
        displayUnit_str = Dump.getOptionWithConcatStr(displayUnit, stringToString, "displayUnit = ");
        stateSel_str = Dump.getOptionWithConcatStr(stateSel, dumpStateSelectStr, "StateSelect = ");
        min_str = Dump.getOptionWithConcatStr(min, real_string, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, real_string, "max = ");
        nominal_str = Dump.getOptionWithConcatStr(nominal, real_string, "nominal = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, real_string, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Dump.printBoolStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts(
          {quantity,unit_str,displayUnit_str,min_str,max_str,
          Initial_str,fixed_str,nominal_str,stateSel_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_INT(quant,(min,max),Initial,fixed)))
      local Option<Integer> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, stringToString, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, int_string, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, int_string, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, int_string, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Dump.printBoolStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_BOOL(quant,Initial,fixed)))
      local Option<Boolean> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, stringToString, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Dump.printBoolStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Dump.printBoolStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_STRING(quant,Initial)))
      local Option<Ident> Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, stringToString, "quantity = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, stringToString, "start = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,Initial_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (SOME(VAR_ATTR_ENUMERATION(quant,(min,max),Initial,fixed)))
      local Option<Exp.Exp> min,max,Initial;
      equation 
        quantity = Dump.getOptionWithConcatStr(quant, stringToString, "quantity = ");
        min_str = Dump.getOptionWithConcatStr(min, Exp.printExpStr, "min = ");
        max_str = Dump.getOptionWithConcatStr(max, Exp.printExpStr, "max = ");
        Initial_str = Dump.getOptionWithConcatStr(Initial, Exp.printExpStr, "start = ");
        fixed_str = Dump.getOptionWithConcatStr(fixed, Dump.printBoolStr, "fixed = ");
        res_1 = Util.stringDelimitListNonEmptyElts({quantity,min_str,max_str,Initial_str,fixed_str}, ", ");
        res1 = Util.stringAppendList({"(",res_1,")"});
        is_empty = Util.isEmptyString(res_1);
        res = Util.if_(is_empty, "", res1);
      then
        res;
    case (NONE) then ""; 
    case (_) then "unknown VariableAttributes"; 
  end matchcontinue;
end dumpVariableAttributesStr;

public function dumpType "function: dumpType
 
  Dump Type.
"
  input Type inType;
algorithm 
  _:=
  matchcontinue (inType)
    local list<Ident> l;
    case INT()
      equation 
        Print.printBuf("Integer ");
      then
        ();
    case REAL()
      equation 
        Print.printBuf("Real    ");
      then
        ();
    case BOOL()
      equation 
        Print.printBuf("Boolean ");
      then
        ();
    case STRING()
      equation 
        Print.printBuf("String  ");
      then
        ();
    case ENUM()
      equation 
        Print.printBuf("Enum ");
      then
        ();
    case ENUMERATION(stringLst = l)
      equation 
        Print.printBuf("Enumeration(");
        Dump.printList(l, print, ",");
        Print.printBuf(") ");
      then
        ();
     case EXT_OBJECT(_)
      equation 
        Print.printBuf("ExternalObject   ");
      then
        ();
  end matchcontinue;
end dumpType;

public function dumpTypeStr "function: dumpTypeStr
 
  Dump Type to a string.
"
  input Type inType;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inType)
    local
      Ident s1,s2,str;
      list<Ident> l;
    case INT() then "Integer "; 
    case REAL() then "Real "; 
    case BOOL() then "Boolean "; 
    case STRING() then "String "; 
    case ENUM() then "Enum "; 
    case ENUMERATION(stringLst = l)
      equation 
        s1 = Util.stringDelimitList(l, ", ");
        s2 = stringAppend("enumeration(", s1);
        str = stringAppend(s2, ")");
      then
        str;
    case EXT_OBJECT(_) then "ExternalObject ";    
  end matchcontinue;
end dumpTypeStr;

protected function dumpVar "function: dumpVar
 
  Dump Var.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef id;
      VarKind kind;
      VarDirection dir;
      Type typ;
      Option<Exp.Exp> start;
      Flow flow_;
      list<Absyn.Path> classlst,class_;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e;
    case VAR(componentRef = id,varible = kind,variable = dir,input_ = typ,one = NONE,dimension = start,value = flow_,flow_ = classlst,variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        dumpType(typ);
        Exp.printComponentRef(id);
        dumpCommentOption(comment) "	dump_start_value start &" ;
        dumpVariableAttributes(dae_var_attr);
        Print.printBuf(";\n") "	Util.list_map(classlst,Absyn.path_string) => classstrlst & 
	Util.string_delimit_list(classstrlst, \", \") => classstr &
	Print.printBuf \" \"{\" &
	Print.printBuf classstr &
	Print.printBuf \"}\" \" &" ;
      then
        ();
    case VAR(componentRef = id,varible = kind,variable = dir,input_ = typ,one = SOME(e),dimension = start,value = flow_,flow_ = class_,variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        dumpKind(kind);
        dumpDirection(dir);
        dumpType(typ);
        Exp.printComponentRef(id);
        dumpVariableAttributes(dae_var_attr) "	dump_start_value start &" ;
        Print.printBuf(" = ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (_) then (); 
  end matchcontinue;
end dumpVar;

protected function dumpVarStr "function: dumpVarStr
 
  Dump var to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,comment_str,s5,str,s6;
      Exp.ComponentRef id;
      VarKind kind;
      VarDirection dir;
      Type typ;
      Option<Exp.Exp> start;
      Flow flow_;
      list<Absyn.Path> classlst;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e;
    case VAR(componentRef = id,varible = kind,variable = dir,input_ = typ,one = NONE,dimension = start,value = flow_,flow_ = classlst,variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = dumpTypeStr(typ);
        s4 = Exp.printComponentRefStr(id);
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value_str start => s5 &" ;
        s5 = dumpVariableAttributesStr(dae_var_attr);
        str = Util.stringAppendList({s1,s2,s3,s4,s5,comment_str,";\n"}) "	Util.list_map(classlst,Absyn.path_string) => classstrlst & 
	Util.string_delimit_list(classstrlst, \", \") => classstr &" ;
      then
        str;
    case VAR(componentRef = id,varible = kind,variable = dir,input_ = typ,one = SOME(e),dimension = start,value = flow_,flow_ = classlst,variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        s1 = dumpKindStr(kind);
        s2 = dumpDirectionStr(dir);
        s3 = dumpTypeStr(typ);
        s4 = Exp.printComponentRefStr(id);
        s5 = Exp.printExpStr(e);
        comment_str = dumpCommentOptionStr(comment) "	dump_start_value_str start => s6 &" ;
        s6 = dumpVariableAttributesStr(dae_var_attr);
        str = Util.stringAppendList({s1,s2,s3,s4,s6," = ",s5,comment_str,";\n"}) "	Util.list_map(classlst,Absyn.path_string) => classstrlst & 
	Util.string_delimit_list(classstrlst, \", \") => classstr &" ;
      then
        str;
    case (_) then ""; 
  end matchcontinue;
end dumpVarStr;

protected function dumpCommentOptionStr "function: dumpCommentOptionStr
 
  Dump Comment option to a string.
"
  input Option<Absyn.Comment> inAbsynCommentOption;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAbsynCommentOption)
    local
      Ident str,cmt;
      Option<Absyn.Annotation> annopt;
    case (NONE) then ""; 
    case (SOME(Absyn.COMMENT(annopt,SOME(cmt))))
      equation 
        str = Util.stringAppendList({" \"",cmt,"\""});
      then
        str;
    case (SOME(Absyn.COMMENT(annopt,NONE))) then ""; 
  end matchcontinue;
end dumpCommentOptionStr;

protected function dumpCommentOption "function: dumpCommentOption_str
 
  Dump Comment option.
"
  input Option<Absyn.Comment> comment;
  Ident str;
algorithm 
  str := dumpCommentOptionStr(comment);
  Print.printBuf(str);
end dumpCommentOption;

protected function dumpEquation "function: dumpEquation
 
  Dump equation.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c;
    case (EQUATION(exp = e1,scalar = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    case (DEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (ASSERT(exp = e))
      equation 
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpEquation;

protected function dumpInitialequation "function: dumpInitialequation
 
  Dump initial equation.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c;
    case (INITIALEQUATION(exp1 = e1,exp2 = e2))
      equation 
        Print.printBuf("  ");
        Exp.printExp(e1);
        Print.printBuf(" = ");
        Exp.printExp(e2);
        Print.printBuf(";\n");
      then
        ();
    case (INITIALDEFINE(componentRef = c,exp = e))
      equation 
        Print.printBuf("  ");
        Exp.printComponentRef(c);
        Print.printBuf(" ::= ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialequation;

protected function dumpEquationStr "function: dumpEquationStr
 
  Dump equation to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,s2,s3,s4,s5,str,s;
      Exp.Exp e1,e2,e;
      Exp.ComponentRef c;
    case (EQUATION(exp = e1,scalar = e2))
      equation 
        s1 = Exp.printExpStr(e1);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(s2, " = ");
        s4 = Exp.printExpStr(e2);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case (DEFINE(componentRef = c,exp = e))
      equation 
        s1 = Exp.printComponentRefStr(c);
        s2 = stringAppend("  ", s1);
        s3 = stringAppend(" ::= ", s2);
        s4 = Exp.printExpStr(e);
        s5 = stringAppend(s3, s4);
        str = stringAppend(s5, ";\n");
      then
        str;
    case (ASSERT(exp = e))
      equation 
        s = Exp.printExpStr(e);
        str = stringAppend(s, ";\n");
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpEquationStr;

public function dumpAlgorithm "function: dumpAlgorithm
 
  Dump algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<Algorithm.Statement> stmts;
    case ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        Print.printBuf("algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpAlgorithm;

protected function dumpInitialalgorithm "function: dump_algorithm
 
  Dump initial algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local list<Algorithm.Statement> stmts;
    case INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        Print.printBuf("initial algorithm\n");
        Dump.printList(stmts, ppStatement, "");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpInitialalgorithm;

public function dumpAlgorithmStr "function: dumpAlgorithmStr
 
  Dump algorithm to a string
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,str;
      list<Algorithm.Statement> stmts;
    case ALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("algorithm\n", s1);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpAlgorithmStr;

protected function dumpInitialalgorithmStr "function: dump_algorithm_str
 
  Dump initial algorithm to a string
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident s1,str;
      list<Algorithm.Statement> stmts;
    case INITIALALGORITHM(algorithm_ = Algorithm.ALGORITHM(statementLst = stmts))
      equation 
        s1 = Dump.getStringList(stmts, ppStatementStr, "");
        str = stringAppend("initial algorithm\n", s1);
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpInitialalgorithmStr;

protected function dumpExtObjectClass "function: dumpExtObjectClass
 
  Dump External Object class
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident fstr;
      Absyn.Path fpath;
      Element constr,destr;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case EXTOBJECTCLASS(path = fpath,constructor=constr,destructor=destr)
      equation 
        Print.printBuf("class ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n extends ExternalObject;\n");
        dumpFunction(constr);
        dumpFunction(destr);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n");
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpExtObjectClass;

protected function dumpFunction "function: dumpFunction
 
  Dump function
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident fstr;
      Absyn.Path fpath;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case FUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        Print.printBuf("function ");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf("\n");
        dumpElements(dae);
        Print.printBuf("end ");
        Print.printBuf(fstr);
        Print.printBuf(";\n\n");
      then
        ();
     case EXTFUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
       local String fstr,daestr,str;
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"\nexternal \"C\";\nend ",fstr,";\n\n"});
        Print.printBuf(str);
      then
        ();
    case _ then (); 
  end matchcontinue;
end dumpFunction;

public function dumpFunctionStr "function: dumpFunctionStr
 
  Dump function to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident fstr,daestr,str;
      Absyn.Path fpath;
      list<Element> dae;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case FUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"end ",fstr,";\n\n"});
      then
        str;
    case EXTFUNCTION(path = fpath,dAElist = DAE(elementLst = dae),type_ = t)
      equation 
        fstr = Absyn.pathString(fpath);
        daestr = dumpElementsStr(dae);
        str = Util.stringAppendList({"function ",fstr,"\n",daestr,"\nexternal \"C\";\nend ",fstr,";\n\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpFunctionStr;

protected function dumpExtObjClassStr "function: dumpExtObjStr
 
  Dump external object class to a string.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident fstr,daestr,str,c_str,d_str;
      Absyn.Path fpath;
      list<Element> dae;
      Element constr,destr;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case EXTOBJECTCLASS(path = fpath,constructor = constr, destructor = destr)
      equation 
        fstr = Absyn.pathString(fpath);
        c_str = dumpFunctionStr(constr);
        d_str = dumpFunctionStr(destr);
        str = Util.stringAppendList({"class  ",fstr,"\n  extends ExternalObject;\n",c_str,
          d_str,"end ",fstr,";\n"});
      then
        str;
    case _ then ""; 
  end matchcontinue;
end dumpExtObjClassStr;

protected function ppStatement "function: ppStatement
 
  Prettyprint an algorithm statement
"
  input Algorithm.Statement alg;
algorithm 
  ppStmt(alg, 2);
end ppStatement;

protected function ppStatementStr "function: ppStatementStr
 
  Prettyprint an algorithm statement to a string.
"
  input Algorithm.Statement alg;
  output String str;
algorithm 
  str := ppStmtStr(alg, 2);
end ppStatementStr;

protected function ppStmt "function: ppStmt
 
  Helper function to pp_statement.
"
  input Algorithm.Statement inStatement;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inStatement,inInteger)
    local
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg;
      Integer i,i_1;
      Ident s1,s2,s3,str,id;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.ASSIGN(componentRef = c,exp = e),i)
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (Algorithm.ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        indent(i);
        Exp.printComponentRef(c);
        Print.printBuf(" := ");
        Exp.printExp(e);
        Print.printBuf(";\n");
      then
        ();
    case (Algorithm.TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
        Print.printBuf(str);
      then
        ();
    case (Algorithm.IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("if ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
        indent(i);
        Print.printBuf("end if;\n");
      then
        ();
    case (Algorithm.FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("for ");
        Print.printBuf(id);
        Print.printBuf(" in ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end for;\n");
      then
        ();
    case (Algorithm.WHILE(exp = e,statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("while ");
        Exp.printExp(e);
        Print.printBuf(" loop\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
        indent(i);
        Print.printBuf("end while;\n");
      then
        ();
    case (stmt as Algorithm.WHEN(exp = _),i)
      equation 
        indent(i);
        Print.printBuf(ppWhenStmtStr(stmt,1));
      then
        ();
    case (Algorithm.ASSERT(exp1 = cond,exp2 = msg),i)
      equation 
        indent(i);
        Print.printBuf("assert( ");
        Exp.printExp(cond);
        Print.printBuf(", ");
        Exp.printExp(msg);
        Print.printBuf(");\n");
      then
        ();
    case (Algorithm.BREAK(),i)
      equation 
        indent(i);
        Print.printBuf("break;\n");
      then
        ();
    case (Algorithm.REINIT(e1,e2),i)
           local Exp.Exp e1,e2;
      equation 
        indent(i);
        Print.printBuf("reinit(");
        Exp.printExp(e1); 
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(");\n");         
      then
        ();
    case (_,i)
      equation 
        indent(i);
        Print.printBuf("**ALGORITHM**;\n");
      then
        ();
  end matchcontinue;
end ppStmt;


protected function ppWhenStmtStr
  input Algorithm.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg;
      Integer i,i_1;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.WHEN(exp = e,statementLst = stmts, elseWhen=NONE),i)
      equation 
        s3 = stringAppend("when ",Exp.printExpStr(e));
        s5 = stringAppend(s3, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end when;\n");
      then
        str;
    case (Algorithm.WHEN(exp = e,statementLst = stmts, elseWhen=SOME(stmt)),i)
      equation 
        s3 = Exp.printExpStr(e);
        s4 = stringAppend("when ", s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppWhenStmtStr(stmt,i);
        s9 = stringAppend(indentStr(i),"else");
        s10= stringAppend(s7,s9);
        str = stringAppend(s10, s8);
      then
        str;
   end matchcontinue;
end ppWhenStmtStr;

protected function ppStmtStr "function: ppStmtStr
 
  Helper function to pp_statement_str
"
  input Algorithm.Statement inStatement;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inStatement,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,str,s7,s8,s9,s10,s11,id,cond_str,msg_str;
      Exp.ComponentRef c;
      Exp.Exp e,cond,msg;
      Integer i,i_1;
      list<Ident> es;
      list<Exp.Exp> expl;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Statement stmt;
      Algorithm.Else else_;
    case (Algorithm.ASSIGN(componentRef = c,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (Algorithm.ASSIGN_ARR(componentRef = c,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printComponentRefStr(c);
        s3 = stringAppend(s1, s2);
        s4 = stringAppend(s3, " := ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        str = stringAppend(s6, ";\n");
      then
        str;
    case (Algorithm.TUPLE_ASSIGN(expExpLst = expl,exp = e),i)
      equation 
        s1 = indentStr(i);
        s2 = Exp.printExpStr(e);
        es = Util.listMap(expl, Exp.printExpStr);
        s3 = Util.stringDelimitList(es, ", ");
        str = Util.stringAppendList({s1,"(",s3,") := ",s2,";\n"});
      then
        str;
    case (Algorithm.IF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "if ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end if;\n");
      then
        str;
    case (Algorithm.FOR(ident = id,exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "for ");
        s3 = stringAppend(s2, id);
        s4 = stringAppend(s3, " in ");
        s5 = Exp.printExpStr(e);
        s6 = stringAppend(s4, s5);
        s7 = stringAppend(s6, " loop\n");
        i_1 = i + 2;
        s8 = ppStmtListStr(stmts, i_1);
        s9 = stringAppend(s7, s8);
        s10 = indentStr(i);
        s11 = stringAppend(s9, s10);
        str = stringAppend(s11, "end for;\n");
      then
        str;
    case (Algorithm.WHILE(exp = e,statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "while ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " loop\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(stmts, i_1);
        s7 = stringAppend(s5, s6);
        s8 = indentStr(i);
        s9 = stringAppend(s7, s8);
        str = stringAppend(s9, "end while;\n");
      then
        str;
    case (stmt as Algorithm.WHEN(exp = _),i)
      equation 
        s1 = indentStr(i);
        s2 = ppWhenStmtStr(stmt,i);
        str = stringAppend(s1,s2);
      then
        str;
    case (Algorithm.ASSERT(exp1 = cond,exp2 = msg),i)
      equation 
        s1 = indentStr(i);
        cond_str = Exp.printExpStr(cond);
        msg_str = Exp.printExpStr(msg);
        str = Util.stringAppendList({s1,"assert(",cond_str,", ",msg_str,");\n"});
      then
        str;
    case (Algorithm.BREAK(),i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "break;\n");
      then
        str;
    case (Algorithm.REINIT(e1,e2),i)
      local Exp.Exp e1,e2; String e1_str,e2_str;
        equation
          s1 = indentStr(i);
          e1_str = Exp.printExpStr(e1);
          e2_str = Exp.printExpStr(e2);
          str = Util.stringAppendList({s1,"reinit(",e1_str,", ",e2_str,");\n"});
        then str;
    case (_,i)
      equation 
        s1 = indentStr(i);
        str = stringAppend(s1, "**ALGORITHM**;\n");
      then
        str;
  end matchcontinue;
end ppStmtStr;

protected function ppStmtList "function: ppStmtList
 
  Helper function to pp_stmt
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      Algorithm.Statement stmt;
      list<Algorithm.Statement> stmts;
      Integer i;
    case ({},_) then (); 
    case ((stmt :: stmts),i)
      equation 
        ppStmt(stmt, i);
        ppStmtList(stmts, i);
      then
        ();
  end matchcontinue;
end ppStmtList;

protected function ppStmtListStr "function: ppStmtListStr
 
  Helper function to pp_stmt_str
"
  input list<Algorithm.Statement> inAlgorithmStatementLst;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inAlgorithmStatementLst,inInteger)
    local
      Ident s1,s2,str;
      Algorithm.Statement stmt;
      list<Algorithm.Statement> stmts;
      Integer i;
    case ({},_) then ""; 
    case ((stmt :: stmts),i)
      equation 
        s1 = ppStmtStr(stmt, i);
        s2 = ppStmtListStr(stmts, i);
        str = stringAppend(s1, s2);
      then
        str;
  end matchcontinue;
end ppStmtListStr;

protected function ppElse "function: ppElse
 
  Helper function to pp_stmt
"
  input Algorithm.Else inElse;
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inElse,inInteger)
    local
      Integer i_1,i;
      Exp.Exp e;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
    case (Algorithm.NOELSE(),_) then (); 
    case (Algorithm.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        indent(i);
        Print.printBuf("elseif ");
        Exp.printExp(e);
        Print.printBuf(" then\n");
        i_1 = i + 2;
        ppStmtList(then_, i_1);
        ppElse(else_, i);
      then
        ();
    case (Algorithm.ELSE(statementLst = stmts),i)
      equation 
        indent(i);
        Print.printBuf("else\n");
        i_1 = i + 2;
        ppStmtList(stmts, i_1);
      then
        ();
  end matchcontinue;
end ppElse;

protected function ppElseStr "function: pp_else
 
  Helper function to ppElseStr
"
  input Algorithm.Else inElse;
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElse,inInteger)
    local
      Ident s1,s2,s3,s4,s5,s6,s7,s8,str;
      Integer i_1,i;
      Exp.Exp e;
      list<Algorithm.Statement> then_,stmts;
      Algorithm.Else else_;
    case (Algorithm.NOELSE(),_) then ""; 
    case (Algorithm.ELSEIF(exp = e,statementLst = then_,else_ = else_),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "elseif ");
        s3 = Exp.printExpStr(e);
        s4 = stringAppend(s2, s3);
        s5 = stringAppend(s4, " then\n");
        i_1 = i + 2;
        s6 = ppStmtListStr(then_, i_1);
        s7 = stringAppend(s5, s6);
        s8 = ppElseStr(else_, i);
        str = stringAppend(s7, s8);
      then
        str;
    case (Algorithm.ELSE(statementLst = stmts),i)
      equation 
        s1 = indentStr(i);
        s2 = stringAppend(s1, "else\n");
        i_1 = i + 2;
        s3 = ppStmtListStr(stmts, i_1);
        str = stringAppend(s2, s3);
      then
        str;
  end matchcontinue;
end ppElseStr;

protected function indent "function: indent
 
  Print an indentation, given an indent level.
"
  input Integer inInteger;
algorithm 
  _:=
  matchcontinue (inInteger)
    local Integer i_1,i;
    case 0 then (); 
    case i
      equation 
        Print.printBuf(" ");
        i_1 = i - 1;
        indent(i_1);
      then
        ();
  end matchcontinue;
end indent;

protected function indentStr "function: indentStr
 
  Print an indentation to a string, given an indent level.
"
  input Integer inInteger;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inInteger)
    local
      Integer i_1,i;
      Ident s1,str;
    case 0 then ""; 
    case i
      equation 
        i_1 = i - 1;
        s1 = indentStr(i_1);
        str = stringAppend(" ", s1);
      then
        str;
  end matchcontinue;
end indentStr;

public function getMatchingElements "function getMatchingElements
  author:  LS 
 
  Retrive the elements for which the function given as second argument
  succeeds.
"
  input list<Element> elist;
  input FuncTypeElementTo cond;
  output list<Element> elist;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  elist := Util.listFilter(elist, cond);
end getMatchingElements;

public function getAllMatchingElements "function getAllMatchingElements
  author:  PA 
 
  Similar to getMatchingElements but traverses down in COMP elements also.
"
  input list<Element> elist;
  input FuncTypeElementTo cond;
  output list<Element> elist;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  
  elist := matchcontinue(elist,cond)
  local list<Element> elist2; Element e;
    case({},_) then {};
    case(COMP(_,DAE(elist))::elist2,cond) equation
      elist= getAllMatchingElements(elist,cond);
      elist2 = getAllMatchingElements(elist2,cond);
      elist2 = listAppend(elist,elist2);
      then elist2;
    case(e::elist,cond) equation
      cond(e);
      elist = getAllMatchingElements(elist,cond);
    then e::elist;

    case(e::elist,cond) equation
      elist = getAllMatchingElements(elist,cond);
    then elist;
  end matchcontinue;
end getAllMatchingElements;


public function isParameter "function isParameter
  author: LS 
 
  Succeeds if element is parameter.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(varible = PARAM()) then (); 
  end matchcontinue;
end isParameter;

public function isInnerVar "function isInnerVar
  author: PA 
 
  Succeeds if element is a variable with prefix inner.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(innerOuter = Absyn.INNER()) then (); 
    case VAR(innerOuter = Absyn.INNEROUTER()) then ();       
  end matchcontinue;
end isInnerVar;

public function isOuterVar "function isOuterVar
  author: PA 
 
  Succeeds if element is a variable with prefix outer.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(innerOuter = Absyn.OUTER()) then (); 
    case VAR(innerOuter = Absyn.INNEROUTER()) then ();       
  end matchcontinue;
end isOuterVar;

public function isComp "function isComp
  author: LS 
 
  Succeeds if element is component, COMP.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case COMP(ident = _) then (); 
  end matchcontinue;
end isComp;

public function getOutputVars "function getOutputVars
  author: LS 
 
  Retrieve all output variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isOutputVar);
end getOutputVars;

public function getBidirVars "function get_output_vars
  author: LS 
 
  Retrieve all bidirectional variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isBidirVar);
end getBidirVars;

public function getInputVars "function getInputVars
  author: HJ 
 
  Retrieve all input variables from an Element list.
"
  input list<Element> vl;
  output list<Element> vl_1;
  list<Element> vl_1;
algorithm 
  vl_1 := getMatchingElements(vl, isInputVar);
end getInputVars;

public function generateDaeType "function generateDaeType
 
  Generate a Types.Type from a DAE.Type
  Is needed when investigating the DAE and want to e.g. evaluate expressions.
"
  input Type inType;
  output Types.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    case (REAL()) then ((Types.T_REAL({}),NONE)); 
    case (INT()) then ((Types.T_INTEGER({}),NONE)); 
    case (BOOL()) then ((Types.T_BOOL({}),NONE)); 
    case (STRING()) then ((Types.T_STRING({}),NONE)); 
  end matchcontinue;
end generateDaeType;

public function setComponentType "function: setComponentType
  
  This function takes a dae element list and a type name and 
  inserts the type name into each Var (variable) of the dae.
  This type name is the origin of the variable.
"
  input list<Element> inElementLst;
  input Absyn.Path inPath;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst,inPath)
    local
      list<Element> xs_1,xs;
      Exp.ComponentRef cr;
      VarKind kind;
      VarDirection dir;
      Type tp;
      Option<Exp.Exp> bind,start;
      InstDims dim;
      Flow flow_;
      list<Absyn.Path> lst;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Absyn.Path newtype;
      Element x;
			Absyn.InnerOuter io;
			Types.Type ftp;
    case ({},_) then {}; 
    case ((VAR(componentRef = cr,varible = kind,variable = dir,input_ = tp,one = bind,binding = dim,dimension = start,value = flow_,flow_ = lst,variableAttributesOption = dae_var_attr,absynCommentOption = comment,innerOuter=io,fullType=ftp) :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (VAR(cr,kind,dir,tp,bind,dim,start,flow_,(newtype :: lst),
          dae_var_attr,comment,io,ftp) :: xs_1);
    case ((x :: xs),newtype)
      equation 
        xs_1 = setComponentType(xs, newtype);
      then
        (x :: xs_1);
  end matchcontinue;
end setComponentType;

public function isOutputVar "function: isOutputVar 
  author: LS 
 
  Succeeds if Element is an output variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,varible = VARIABLE(),variable = OUTPUT(),input_ = ty) then (); 
  end matchcontinue;
end isOutputVar;

public function isBidirVar "function: isBidirVar 
  author: LS 
 
  Succeeds if Element is a bidirectional variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,varible = VARIABLE(),variable = BIDIR(),input_ = ty) then (); 
  end matchcontinue;
end isBidirVar;

public function isInputVar "function: isInputVar 
  author: HJ
 
  Succeeds if Element is an input variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Exp.ComponentRef n;
      Type ty;
    case VAR(componentRef = n,varible = VARIABLE(),variable = INPUT(),input_ = ty) then (); 
  end matchcontinue;
end isInputVar;

protected function isNotVar "function: isNotVar 
  author: LS
 
  Succeeds if Element is not a variable.
"
  input Element e;
algorithm 
  failure(isVar(e));
end isNotVar;

public function isVar "function: isVar 
  author: LS
 
  Succeeds if Element is a variable.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case VAR(componentRef = _) then (); 
  end matchcontinue;
end isVar;

public function isAlgorithm "function: isAlgorithm
  author: LS
 
  Succeeds if Element is an algorithm.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case ALGORITHM(algorithm_ = _) then (); 
  end matchcontinue;
end isAlgorithm;

public function isFunction "function: isFunction
  author: LS
 
  Succeeds if Element is not a function.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    case FUNCTION(path = _) then (); 
    case EXTFUNCTION(path = _) then (); 
  end matchcontinue;
end isFunction;

public function dumpDebug "

 Dump the data structures in a 
 paranthesised way

"
  input DAElist inDAElist;
algorithm 
  _:=
  matchcontinue (inDAElist)
    local list<Element> elist;
    case DAE(elementLst = elist)
      equation 
        Print.printBuf("DAE(");
        dumpDebugElist(elist);
        Print.printBuf(")");
      then
        ();
  end matchcontinue;
end dumpDebug;

protected function dumpDebugElist "function: dumpDebugElist
 
  Helper function to dump_debug.
"
  input list<Element> inElementLst;
algorithm 
  _:=
  matchcontinue (inElementLst)
    local
      Element first;
      list<Element> rest;
    case {} then (); 
    case (first :: rest)
      equation 
        dumpDebugElement(first);
        Print.printBuf("\n");
        dumpDebugElist(rest);
      then
        ();
  end matchcontinue;
end dumpDebugElist;

public function dumpDebugElement "function: dumpDebugElement
 
  Dump element using parenthesis.
"
  input Element inElement;
algorithm 
  _:=
  matchcontinue (inElement)
    local
      Ident comment_str,tmp_str,n,fstr;
      Exp.ComponentRef cr;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e,exp,e1,e2;
      DAElist l;
      Absyn.Path fpath;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = NONE,variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        comment_str = Dump.unparseCommentOption(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = SOME(e),variableAttributesOption = dae_var_attr,absynCommentOption = comment)
      equation 
        Print.printBuf("VAR(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        dumpKind(vk);
        Print.printBuf(", ");
        comment_str = Dump.unparseCommentOption(comment);
        Print.printBuf("  comment:");
        Print.printBuf(comment_str);
        tmp_str = dumpVariableAttributesStr(dae_var_attr);
        Exp.printExp(e);
        Print.printBuf(tmp_str);
        Print.printBuf(")");
      then
        ();
    case DEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("DEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        Print.printBuf("INITIALDEFINE(");
        Exp.printComponentRef(cr);
        Print.printBuf(", ");
        Exp.printExp(exp);
        Print.printBuf(")");
      then
        ();
    case EQUATION(exp = e1,scalar = e2)
      equation 
        Print.printBuf("EQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        Print.printBuf("INITIALEQUATION(");
        Exp.printExp(e1);
        Print.printBuf(",");
        Exp.printExp(e2);
        Print.printBuf(")");
      then
        ();
    case ALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("ALGORITHM()");
      then
        ();
    case INITIALALGORITHM(algorithm_ = _)
      equation 
        Print.printBuf("INITIALALGORITHM()");
      then
        ();
    case COMP(ident = n,dAElist = l)
      equation 
        Print.printBuf("COMP(");
        Print.printBuf(n);
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
    case FUNCTION(path = fpath,dAElist = l,type_ = t)
      equation 
        Print.printBuf("FUNCTION(");
        fstr = Absyn.pathString(fpath);
        Print.printBuf(fstr);
        Print.printBuf(",");
        Types.printType(t);
        Print.printBuf(",");
        dumpDebug(l);
        Print.printBuf(")");
      then
        ();
    case _
      equation 
        Print.printBuf("UNKNOWN ");
      then
        ();
  end matchcontinue;
end dumpDebugElement;

public function findElement "function: findElement
 
  Search for an element for which the function passed as second 
  argument succeds. If no element is found return NONE.
"
  input list<Element> inElementLst;
  input FuncTypeElementTo inFuncTypeElementTo;
  output Option<Element> outElementOption;
  partial function FuncTypeElementTo
    input Element inElement;
  end FuncTypeElementTo;
algorithm 
  outElementOption:=
  matchcontinue (inElementLst,inFuncTypeElementTo)
    local
      Element e;
      list<Element> rest;
      FuncTypeElementTo f;
      Option<Element> e_1;
    case ({},_) then NONE; 
    case ((e :: rest),f)
      equation 
        f(e);
      then
        SOME(e);
    case ((e :: rest),f)
      equation 
        failure(f(e));
        e_1 = findElement(rest, f);
      then
        e_1;
  end matchcontinue;
end findElement;

public function dumpGraphviz "
 Graphviz functions to visualize 
 the dae
"
  input DAElist dae;
  Graphviz.Node r;
algorithm 
  r := buildGraphviz(dae);
  Graphviz.dump(r);
end dumpGraphviz;

protected function buildGraphviz "function: buildGraphviz
 
  Builds the graphviz node from a dae list.
"
  input DAElist inDAElist;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inDAElist)
    local
      list<Element> vars,nonvars,els;
      list<Graphviz.Node> nonvarnodes,varnodes,nodelist;
    case DAE(elementLst = els)
      equation 
        vars = getMatchingElements(els, isVar);
        nonvars = getMatchingElements(els, isNotVar);
        nonvarnodes = buildGrList(nonvars);
        varnodes = buildGrVars(vars);
        nodelist = listAppend(nonvarnodes, varnodes);
      then
        Graphviz.NODE("DAE",{},nodelist);
  end matchcontinue;
end buildGraphviz;

protected function buildGrList "function buildGrList
 
  Helper function to build_graphviz.
"
  input list<Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inElementLst)
    local
      Graphviz.Node node;
      list<Graphviz.Node> nodelist;
      Element el;
      list<Element> rest;
    case {} then {}; 
    case (el :: rest)
      equation 
        node = buildGrElement(el);
        nodelist = buildGrList(rest);
      then
        (node :: nodelist);
  end matchcontinue;
end buildGrList;

protected function buildGrVars "function buildGrVars
 
  Helper function to build_graphviz.
"
  input list<Element> inElementLst;
  output list<Graphviz.Node> outGraphvizNodeLst;
algorithm 
  outGraphvizNodeLst:=
  matchcontinue (inElementLst)
    local
      list<Ident> strlist;
      list<Element> vars;
    case {} then {}; 
    case vars
      equation 
        (strlist,_) = buildGrStrlist(vars, buildGrVarStr, 10);
      then
        {Graphviz.LNODE("VARS",strlist,{Graphviz.box},{})};
  end matchcontinue;
end buildGrVars;

public function buildGrStrlist "function buildGrStrlist
 
  Helper function to build_graphviz.
"
  input list<Type_a> inTypeALst;
  input FuncTypeType_aToString inFuncTypeTypeAToString;
  input Integer inInteger;
  output list<String> outStringLst;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aToString
    input Type_a inTypeA;
    output String outString;
  end FuncTypeType_aToString;
algorithm 
  (outStringLst,outTypeALst):=
  matchcontinue (inTypeALst,inFuncTypeTypeAToString,inInteger)
    local
      list<Type_a> ignored,rest;
      FuncTypeType_aToString printer;
      Integer count,count_1;
      list<Ident> strlist;
      Ident str;
      Type_a var;
    case ({},_,_) then ({},{}); 
    case (ignored,printer,count)
      equation 
        (count <= 0) = true;
      then
        ({"..."},ignored);
    case ((var :: rest),printer,count)
      equation 
        (count > 0) = true;
        count_1 = count - 1;
        (strlist,ignored) = buildGrStrlist(rest, printer, count_1);
        str = printer(var);
      then
        ((str :: strlist),ignored);
  end matchcontinue;
end buildGrStrlist;

protected function buildGrVarStr "function buildGrVarStr
 
  Helper function to build_graphviz.
"
  input Element inElement;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElement)
    local
      Ident str,expstr,str_1,str_2;
      Exp.ComponentRef cr;
      Exp.Exp exp;
    case VAR(componentRef = cr,one = NONE)
      equation 
        str = Exp.printComponentRefStr(cr);
      then
        str;
    case VAR(componentRef = cr,one = SOME(exp))
      equation 
        str = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        str_1 = stringAppend(str, " = ");
        str_2 = stringAppend(str_1, expstr);
      then
        str_2;
  end matchcontinue;
end buildGrVarStr;

protected function printExpStrSpecial "function: printExpStrSpecial
 
  Prints an expression to a string suitable for graphviz.
"
  input Exp.Exp inExp;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inExp)
    local
      Ident s_1,s_2,s,str;
      Exp.Exp exp;
    case Exp.SCONST(string = s)
      equation 
        s_1 = stringAppend("\\\"", s);
        s_2 = stringAppend(s_1, "\\\"");
      then
        s_2;
    case exp
      equation 
        str = Exp.printExpStr(exp);
      then
        str;
  end matchcontinue;
end printExpStrSpecial;

protected function buildGrElement "function: buildGrElement
 
  Builds a Graphviz.Node from an element.
"
  input Element inElement;
  output Graphviz.Node outNode;
algorithm 
  outNode:=
  matchcontinue (inElement)
    local
      Ident crstr,vkstr,expstr,expstr_1,e1str,e2str,n,fstr;
      Exp.ComponentRef cr;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Exp.Exp exp,e1,e2;
      Graphviz.Node node;
      DAElist dae;
      Absyn.Path fpath;
    case VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = NONE)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr},{},{});
    case VAR(componentRef = cr,varible = vk,variable = vd,input_ = ty,one = SOME(exp))
      equation 
        crstr = Exp.printComponentRefStr(cr);
        vkstr = dumpKindStr(vk);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("VAR",{crstr,vkstr,expstr_1},{},{});
    case DEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("DEFINE",{crstr,expstr_1},{},{});
    case EQUATION(exp = e1,scalar = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("EQUATION",{e1str,"=",e2str},{},{});
    case ALGORITHM(algorithm_ = _) then Graphviz.NODE("ALGORITHM",{},{}); 
    case INITIALDEFINE(componentRef = cr,exp = exp)
      equation 
        crstr = Exp.printComponentRefStr(cr);
        expstr = printExpStrSpecial(exp);
        expstr_1 = stringAppend("= ", expstr);
      then
        Graphviz.LNODE("INITIALDEFINE",{crstr,expstr_1},{},{});
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      equation 
        e1str = printExpStrSpecial(e1);
        e2str = printExpStrSpecial(e2);
      then
        Graphviz.LNODE("INITIALEQUATION",{e1str,"=",e2str},{},{});
    case INITIALALGORITHM(algorithm_ = _) then Graphviz.NODE("INITIALALGORITHM",{},{}); 
    case COMP(ident = n,dAElist = dae)
      equation 
        node = buildGraphviz(dae);
      then
        Graphviz.LNODE("COMP",{n},{},{node});
    case FUNCTION(path = fpath,dAElist = dae,type_ = ty)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        node = buildGraphviz(dae);
        fstr = Absyn.pathString(fpath);
      then
        Graphviz.LNODE("FUNCTION",{fstr},{},{node});
  end matchcontinue;
end buildGrElement;

public function getVariableBindingsStr "function: getVariableBindingsStr
 
  This function takes a `DAE.Element\' list and returns a comma separated 
  string of variable bindings.
  E.g. model A Real x=1; Real y=2; end A; => \"1,2\"
"
  input list<Element> elts;
  output String str;
  list<Element> varlst;
algorithm 
  varlst := getVariableList(elts);
  str := getBindingsStr(varlst);
end getVariableBindingsStr;

protected function getVariableList "function: getVariableList
 
  Return all variables from an Element list.
"
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      list<Element> res,lst;
      Exp.ComponentRef a;
      VarKind b;
      VarDirection c;
      Type d;
      Option<Exp.Exp> e,g;
      InstDims f;
      Flow h;
      list<Absyn.Path> i;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Absyn.InnerOuter io;
      Types.Type tp;
    case (VAR(componentRef = a,varible = b,variable = c,input_ = d,one = e,binding = f,dimension = g,value = h,flow_ = i,variableAttributesOption = dae_var_attr,absynCommentOption = comment,innerOuter=io,fullType=tp) :: lst)
      equation 
        res = getVariableList(lst);
      then
        (VAR(a,b,c,d,e,f,g,h,i,dae_var_attr,comment,io,tp) :: res);
    case (_ :: lst)
      equation 
        res = getVariableList(lst);
      then
        res;
    case {} then {}; 
  end matchcontinue;
end getVariableList;

protected function getBindingsStr "function: getBindingsStr
 
  Retrive the bindings from a list of Elements and output to a string.
"
  input list<Element> inElementLst;
  output String outString;
algorithm 
  outString:=
  matchcontinue (inElementLst)
    local
      Ident expstr,s3,s4,str,s1,s2;
      Element v;
      Exp.ComponentRef cr;
      Exp.Exp e;
      list<Element> lst;
    case (((v as VAR(componentRef = cr,one = SOME(e))) :: (lst as (_ :: _))))
      equation 
        expstr = Exp.printExpStr(e);
        s3 = stringAppend(expstr, ",");
        s4 = getBindingsStr(lst);
        str = stringAppend(s3, s4);
      then
        str;
    case (((v as VAR(componentRef = cr,one = NONE)) :: (lst as (_ :: _))))
      equation 
        s1 = "-,";
        s2 = getBindingsStr(lst);
        str = stringAppend(s1, s2);
      then
        str;
    case ({(v as VAR(componentRef = cr,one = SOME(e)))})
      equation 
        str = Exp.printExpStr(e);
      then
        str;
    case ({(v as VAR(componentRef = cr,one = NONE))}) then ""; 
  end matchcontinue;
end getBindingsStr;

public function toFlow "function: toFlow
 
  Create a Flow, given a ClassInf.State and a boolean flow value.
"
  input Boolean inBoolean;
  input ClassInf.State inState;
  output Flow outFlow;
algorithm 
  outFlow:=
  matchcontinue (inBoolean,inState)
    case (true,_) then FLOW(); 
    case (_,ClassInf.CONNECTOR(string = _)) then NON_FLOW(); 
    case (_,_) then NON_CONNECTOR(); 
  end matchcontinue;
end toFlow;

public function getFlowVariables "function: getFlowVariables
 
  Retrive the flow variables of an Element list.
"
  input list<Element> inElementLst;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inElementLst)
    local
      list<Exp.ComponentRef> res,res1,res1_1,res2;
      Exp.ComponentRef cr;
      list<Element> xs,lst;
      Ident id;
    case ({}) then {}; 
    case ((VAR(componentRef = cr,value = FLOW()) :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        (cr :: res);
    case ((COMP(ident = id,dAElist = DAE(elementLst = lst)) :: xs))
      equation 
        res1 = getFlowVariables(lst);
        res1_1 = getFlowVariables2(res1, id);
        res2 = getFlowVariables(xs);
        res = listAppend(res1_1, res2);
      then
        res;
    case ((_ :: xs))
      equation 
        res = getFlowVariables(xs);
      then
        res;
  end matchcontinue;
end getFlowVariables;

protected function getFlowVariables2 "function: getFlowVariables2
 
  Helper function to get_flow_variables.
"
  input list<Exp.ComponentRef> inExpComponentRefLst;
  input Ident inIdent;
  output list<Exp.ComponentRef> outExpComponentRefLst;
algorithm 
  outExpComponentRefLst:=
  matchcontinue (inExpComponentRefLst,inIdent)
    local
      Ident id;
      list<Exp.ComponentRef> res,xs;
      Exp.ComponentRef cr_1,cr;
    case ({},id) then {}; 
    case ((cr :: xs),id)
      equation 
        res = getFlowVariables2(xs, id);
        cr_1 = Exp.joinCrefs(Exp.CREF_IDENT(id,{}), cr);
      then
        (cr_1 :: res);
  end matchcontinue;
end getFlowVariables2;

public function daeToRecordValue "function: daeToRecordValue
  Transforms a list of elements into a record value.
  TODO: This does not work for records inside records. 
  For a general approach we need to build an environment from the DAE and then
  instead investigate the variables and lookup their values from the created environment.
"
  input Absyn.Path inPath;
  input list<Element> inElementLst;
  input Boolean inBoolean;
  output Values.Value outValue;
algorithm 
  outValue:=
  matchcontinue (inPath,inElementLst,inBoolean)
    local
      Absyn.Path cname;
      Values.Value value,res;
      list<Values.Value> vals;
      list<Ident> names;
      Ident cr_str;
      Exp.ComponentRef cr;
      Exp.Exp rhs;
      list<Element> rest;
      Boolean impl;
    case (cname,{},_) then Values.RECORD(cname,{},{});  /* impl */ 
    case (cname,(EQUATION(exp = Exp.CREF(componentRef = cr),scalar = rhs) :: rest),impl)
      equation 
        (_,value,_) = Ceval.ceval(Env.emptyCache,{}, rhs, impl, NONE, NONE, Ceval.MSG());
        Values.RECORD(cname,vals,names) = daeToRecordValue(cname, rest, impl);
        cr_str = Exp.printComponentRefStr(cr);
      then
        Values.RECORD(cname,(value :: vals),(cr_str :: names));
    case (cname,(_ :: rest),impl)
      equation 
        res = daeToRecordValue(cname, rest, impl);
      then
        res;
    case (_,_,_)
      equation 
        Debug.fprint("failtrace", "-dae_to_record_value failed\n");
      then
        fail();
  end matchcontinue;
end daeToRecordValue;

public function toModelicaForm "function toModelicaForm.
 
  Transforms all variables from a.b.c to a_b_c, etc
"
  input DAElist inDAElist;
  output DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local list<Element> elts_1,elts;
    case (DAE(elementLst = elts))
      equation 
        elts_1 = toModelicaFormElts(elts);
      then
        DAE(elts_1);
  end matchcontinue;
end toModelicaForm;

protected function toModelicaFormElts "function: toModelicaFormElts
 
  Helper function to to_modelica_form.
"
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElementLst)
    local
      Ident str,str_1,id;
      list<Element> elts_1,elts,welts_1,welts,telts_1,eelts_1,telts,eelts;
      Option<Exp.Exp> d_1,d,f;
      Exp.ComponentRef cr,cr_1;
      VarKind a;
      VarDirection b;
      Type c;
      InstDims e;
      Flow g;
      list<Absyn.Path> h;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      Exp.Exp e_1,e1_1,e2_1,e1,e2;
      Element elt_1,elt;
      DAElist dae_1,dae;
      Absyn.Path p;
      tuple<Types.TType, Option<Absyn.Path>> t;
      Types.Type tp;
      Absyn.InnerOuter io;
    case ({}) then {}; 
    case ((VAR(componentRef = cr,varible = a,variable = b,input_ = c,one = d,binding = e,dimension = f,value = g,flow_ = h,variableAttributesOption = dae_var_attr,absynCommentOption = comment,innerOuter=io,fullType=tp) :: elts))
      equation 
        str = Exp.printComponentRefStr(cr);
        str_1 = Util.stringReplaceChar(str, ".", "_");
        elts_1 = toModelicaFormElts(elts);
        d_1 = toModelicaFormExpOpt(d);
      then
        (VAR(Exp.CREF_IDENT(str_1,{}),a,b,c,d_1,e,f,g,h,dae_var_attr,
          comment,io,tp) :: elts_1);
    case ((DEFINE(componentRef = cr,exp = e) :: elts))
      local Exp.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (DEFINE(cr_1,e_1) :: elts_1);
    case ((INITIALDEFINE(componentRef = cr,exp = e) :: elts))
      local Exp.Exp e;
      equation 
        e_1 = toModelicaFormExp(e);
        cr_1 = toModelicaFormCref(cr);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALDEFINE(cr_1,e_1) :: elts_1);
    case ((EQUATION(exp = e1,scalar = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (EQUATION(e1_1,e2_1) :: elts_1);
    case ((WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = SOME(elt)) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        {elt_1} = toModelicaFormElts({elt});
        elts_1 = toModelicaFormElts(elts);
      then
        (WHEN_EQUATION(e1_1,welts_1,SOME(elt_1)) :: elts_1);
    case ((WHEN_EQUATION(condition = e1,equations = welts,elsewhen_ = NONE) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        welts_1 = toModelicaFormElts(welts);
        elts_1 = toModelicaFormElts(elts);
      then
        (WHEN_EQUATION(e1_1,welts_1,NONE) :: elts_1);
    case ((IF_EQUATION(condition1 = e1,equations2 = telts,equations3 = eelts) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        telts_1 = toModelicaFormElts(telts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (IF_EQUATION(e1_1,telts_1,eelts_1) :: elts_1);
    case ((INITIAL_IF_EQUATION(condition1 = e1,equations2 = telts,equations3 = eelts) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        telts_1 = toModelicaFormElts(telts);
        eelts_1 = toModelicaFormElts(eelts);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIAL_IF_EQUATION(e1_1,telts_1,eelts_1) :: elts_1);
    case ((INITIALEQUATION(exp1 = e1,exp2 = e2) :: elts))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALEQUATION(e1_1,e2_1) :: elts_1);
    case ((ALGORITHM(algorithm_ = a) :: elts))
      local Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(ALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (ALGORITHM(a) :: elts_1);
    case ((INITIALALGORITHM(algorithm_ = a) :: elts))
      local Algorithm.Algorithm a;
      equation 
        print("to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n");
        elts_1 = toModelicaFormElts(elts);
      then
        (INITIALALGORITHM(a) :: elts_1);
    case ((COMP(ident = id,dAElist = dae) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (COMP(id,dae_1) :: elts_1);
    case ((FUNCTION(path = p,dAElist = dae,type_ = t) :: elts))
      equation 
        dae_1 = toModelicaForm(dae);
        elts_1 = toModelicaFormElts(elts);
      then
        (FUNCTION(p,dae_1,t) :: elts_1);
    case ((EXTFUNCTION(path = p,dAElist = dae,type_ = t,externalDecl = d) :: elts))
      local ExternalDecl d;
      equation 
        elts_1 = toModelicaFormElts(elts);
        dae_1 = toModelicaForm(dae);
      then
        (EXTFUNCTION(p,dae,t,d) :: elts_1);
    case ((ASSERT(exp = e) :: elts))
      local Exp.Exp e;
      equation 
        elts_1 = toModelicaFormElts(elts);
        e_1 = toModelicaFormExp(e);
      then
        (ASSERT(e_1) :: elts_1);
  end matchcontinue;
end toModelicaFormElts;

protected function toModelicaFormExpOpt "function: toModelicaFormExpOpt
 
  Helper function to to_mdelica_form_elts.
"
  input Option<Exp.Exp> inExpExpOption;
  output Option<Exp.Exp> outExpExpOption;
algorithm 
  outExpExpOption:=
  matchcontinue (inExpExpOption)
    local Exp.Exp e_1,e;
    case (SOME(e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        SOME(e_1);
    case (NONE) then NONE; 
  end matchcontinue;
end toModelicaFormExpOpt;

protected function toModelicaFormCref "function: toModelicaFormCref
 
  Helper function to to_modelica_form_elts.
"
  input Exp.ComponentRef cr;
  output Exp.ComponentRef outComponentRef;
  Ident str,str_1;
algorithm 
  str := Exp.printComponentRefStr(cr);
  str_1 := Util.stringReplaceChar(str, ".", "_");
  outComponentRef := Exp.CREF_IDENT(str_1,{});
end toModelicaFormCref;

protected function toModelicaFormExp "function: toModelicaFormExp
 
  Helper function to to_modelica_form_elts.
"
  input Exp.Exp inExp;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inExp)
    local
      Exp.ComponentRef cr_1,cr;
      Exp.Type t;
      Exp.Exp e1_1,e2_1,e1,e2,e_1,e,e3_1,e3;
      Exp.Operator op;
      list<Exp.Exp> expl_1,expl;
      Absyn.Path f;
      Boolean b;
      Integer i;
      Option<Exp.Exp> eopt_1,eopt;
    case (Exp.CREF(componentRef = cr,ty = t))
      equation 
        cr_1 = toModelicaFormCref(cr);
      then
        Exp.CREF(cr_1,t);
    case (Exp.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.BINARY(e1_1,op,e2_1);
    case (Exp.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.LBINARY(e1_1,op,e2_1);
    case (Exp.UNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.UNARY(op,e_1);
    case (Exp.LUNARY(operator = op,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.LUNARY(op,e_1);
    case (Exp.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
      then
        Exp.RELATION(e1_1,op,e2_1);
    case (Exp.IFEXP(expCond = e1,expThen = e2,expElse = e3))
      equation 
        e1_1 = toModelicaFormExp(e1);
        e2_1 = toModelicaFormExp(e2);
        e3_1 = toModelicaFormExp(e3);
      then
        Exp.IFEXP(e1_1,e2_1,e3_1);
    case (Exp.CALL(path = f,expLst = expl,tuple_ = t,builtin = b,ty=tp))
      local Boolean t; Exp.Type tp;
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.CALL(f,expl_1,t,b,tp);
    case (Exp.ARRAY(ty = t,scalar = b,array = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.ARRAY(t,b,expl_1);
    case (Exp.TUPLE(PR = expl))
      equation 
        expl_1 = Util.listMap(expl, toModelicaFormExp);
      then
        Exp.TUPLE(expl_1);
    case (Exp.CAST(ty = t,exp = e))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.CAST(t,e_1);
    case (Exp.ASUB(exp = e,sub = i))
      equation 
        e_1 = toModelicaFormExp(e);
      then
        Exp.ASUB(e_1,i);
    case (Exp.SIZE(exp = e,sz = eopt))
      equation 
        e_1 = toModelicaFormExp(e);
        eopt_1 = toModelicaFormExpOpt(eopt);
      then
        Exp.SIZE(e_1,eopt_1);
    case (e) then e; 
  end matchcontinue;
end toModelicaFormExp;

public function getNamedFunction "function: getNamedFunction
 
  return the FUNCTION with the given name. Returns empty list if not found
  TODO: Only top level functions are checked. Add recursing into the DAE
  and path name checking.
  TODO: External functions?
"
  input Absyn.Path inPath;
  input list<Element> inElementLst;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inPath,inElementLst)
    local
      Absyn.Path path,elpath;
      Element el;
      list<Element> rest,res;
    case (_,{}) then {}; 
    case (path,((el as FUNCTION(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath);
      then
        {el};
    case (path,((el as EXTFUNCTION(path = elpath)) :: rest))
      equation 
        true = ModUtil.pathEqual(path, elpath);
      then
        {el};
    case (path,(el :: rest))
      equation 
        res = getNamedFunction(path, rest);
      then
        res;
    case (_,_)
      equation 
        Debug.fprintln("failtrace", "-- get_named_function failed");
      then
        fail();
  end matchcontinue;
end getNamedFunction;

public function getAllExps "function: getAllExps
  
  This function goes through the DAE structure and finds all the
  expressions and returns them in a list
"
  input list<Element> elements;
  output list<Exp.Exp> exps;
  list<list<Exp.Exp>> expslist;
algorithm 
  expslist := Util.listMap(elements, getAllExpsElement);
  exps := Util.listFlatten(expslist);
end getAllExps;

protected function crefToExp "function: crefToExp
 
  Makes an expression from a ComponentRef.
"
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef)
    local Exp.ComponentRef cref;
    case cref then Exp.CREF(cref,Exp.OTHER()); 
  end matchcontinue;
end crefToExp;

protected function getAllExpsElement "function: getAllExpsElement
  
  Helper to get_all_exps. Implements get_all_exps for different kinds of
  elements 
"
  input Element inElement;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inElement)
    local
      list<Exp.Exp> e1,e2,e3,exps,explist1,explist2,exps1,exps2,exps3;
      Exp.Exp crefexp,exp,cond;
      Exp.ComponentRef cref;
      VarKind vk;
      VarDirection vd;
      Type ty;
      Option<Exp.Exp> bndexp,startvalexp;
      InstDims instdims;
      Flow flow_;
      list<Absyn.Path> pathlist;
      Option<VariableAttributes> dae_var_attr;
      Option<Absyn.Comment> comment;
      list<Element> ellist,elements,eqs,eqstrueb,eqsfalseb;
      Option<Element> elsewhenopt;
      Algorithm.Algorithm alg;
      Ident id,fname,lang;
      Absyn.Path path;
      list<list<Exp.Exp>> argexps,expslist;
      list<ExtArg> args;
      ExtArg retarg;
      Option<Absyn.Annotation> ann;
    case VAR(componentRef = cref,varible = vk,variable = vd,input_ = ty,one = bndexp,binding = instdims,dimension = startvalexp,value = flow_,flow_ = pathlist,variableAttributesOption = dae_var_attr,absynCommentOption = comment) /* VAR */ 
      equation 
        e1 = Util.optionToList(bndexp);
        e2 = Util.optionToList(startvalexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        crefexp = crefToExp(cref);
        exps = Util.listFlatten({e1,e2,e3,{crefexp}});
      then
        exps;
    case DEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case INITIALDEFINE(componentRef = cref,exp = exp)
      equation 
        crefexp = crefToExp(cref);
      then
        {crefexp,exp};
    case EQUATION(exp = e1,scalar = e2)
      local Exp.Exp e1,e2;
      then
        {e1,e2};
    case WHEN_EQUATION(condition = cond,equations = eqs,elsewhen_ = elsewhenopt)
      equation 
        ellist = Util.optionToList(elsewhenopt);
        elements = listAppend(eqs, ellist);
        exps = getAllExps(elements);
      then
        (cond :: exps);
    case IF_EQUATION(condition1 = cond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = getAllExps(eqstrueb);
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({{cond},explist1,explist2});
      then
        exps;
    case INITIAL_IF_EQUATION(condition1 = cond,equations2 = eqstrueb,equations3 = eqsfalseb)
      equation 
        explist1 = getAllExps(eqstrueb);
        explist2 = getAllExps(eqsfalseb);
        exps = Util.listFlatten({{cond},explist1,explist2});
      then
        exps;
    case INITIALEQUATION(exp1 = e1,exp2 = e2)
      local Exp.Exp e1,e2;
      then
        {e1,e2};
    case ALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case INITIALALGORITHM(algorithm_ = alg)
      equation 
        exps = Algorithm.getAllExps(alg);
      then
        exps;
    case COMP(ident = id,dAElist = DAE(elementLst = elements))
      equation 
        exps = getAllExps(elements);
      then
        exps;
    case FUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty)
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps = listAppend(exps1, exps2);
      then
        exps;
    case EXTFUNCTION(path = path,dAElist = DAE(elementLst = elements),type_ = ty,externalDecl = EXTERNALDECL(ident = fname,external_ = args,parameters = retarg,returnType = lang,language = ann))
      local tuple<Types.TType, Option<Absyn.Path>> ty;
      equation 
        exps1 = getAllExps(elements);
        exps2 = Types.getAllExps(ty);
        exps3 = getAllExpsExtarg(retarg);
        argexps = Util.listMap(args, getAllExpsExtarg);
        expslist = listAppend({exps1,exps2,exps3}, argexps);
        exps = Util.listFlatten(expslist);
      then
        exps;
    case ASSERT(exp = exp) then {exp}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_element failed");
      then
        fail();
  end matchcontinue;
end getAllExpsElement;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  
  Get all exps from a Subscript 
"
  input Exp.Subscript inSubscript;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inSubscript)
    local Exp.Exp e;
    case Exp.WHOLEDIM() then {}; 
    case Exp.SLICE(exp = e) then {e}; 
    case Exp.INDEX(exp = e) then {e}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_subscript failed");
      then
        fail();
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsExtarg "function: getAllExpsExtarg
  
  Get all exps from an ExtArg 
"
  input ExtArg inExtArg;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inExtArg)
    local
      Exp.Exp exp1,crefexp,exp;
      list<Exp.Exp> explist,exps,tyexps;
      Exp.ComponentRef cref;
      Types.Attributes attr;
      tuple<Types.TType, Option<Absyn.Path>> ty;
    case EXTARG(componentRef = cref,attributes = attr,type_ = ty)
      equation 
        exp1 = crefToExp(cref);
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case EXTARGEXP(exp = exp1,type_ = ty)
      equation 
        explist = Types.getAllExps(ty);
        exps = listAppend({exp1}, explist);
      then
        exps;
    case EXTARGSIZE(componentRef = cref,attributes = attr,type_ = ty,exp = exp)
      equation 
        crefexp = crefToExp(cref);
        tyexps = Types.getAllExps(ty);
        exps = Util.listFlatten({{crefexp},tyexps,{exp}});
      then
        exps;
    case NOEXTARG() then {}; 
    case _
      equation 
        Debug.fprintln("failtrace", "-- get_all_exps_extarg failed");
      then
        fail();
  end matchcontinue;
end getAllExpsExtarg;

public function transformIfEqToExpr "function: transformIfEqToExpr
  transform all if equations to ordinary equations involving if-expressions
"
  input DAElist inDAElist;
  output DAElist outDAElist;
algorithm 
  outDAElist:=
  matchcontinue (inDAElist)
    local
      DAElist sublist_result,result,sublist;
      list<Element> rest_result,rest,res2,res1,res;
      Element subresult,el;
      Ident name;
    case (DAE(elementLst = {})) then DAE({}); 
    case (DAE(elementLst = (COMP(ident = name,dAElist = sublist) :: rest)))
      equation 
        sublist_result = transformIfEqToExpr(sublist);
        DAE(rest_result) = transformIfEqToExpr(DAE(rest));
        subresult = COMP(name,sublist_result);
        result = DAE((subresult :: rest_result));
      then
        result;
    case (DAE(elementLst = (el :: rest)))
      equation 
        DAE(res2) = transformIfEqToExpr(DAE(rest));
        res1 = ifEqToExpr(el);
        res = listAppend(res1, res2);
      then
        DAE(res);
    case (DAE(elementLst = (el :: rest)))
      equation 
        DAE(res) = transformIfEqToExpr(DAE(rest));
      then
        DAE((el :: res));
  end matchcontinue;
end transformIfEqToExpr;

protected function ifEqToExpr "function: ifEqToExpr
  Transform one if-equation into equations involving if-expressions
"
  input Element inElement;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inElement)
    local
      Integer true_eq,false_eq;
      Ident elt_str;
      Element elt;
      Exp.Exp cond;
      list<Element> true_branch,false_branch,equations;
    case ((elt as IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch)))
      equation 
        true_eq = listLength(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = false;
        elt_str = dumpEquationsStr({elt});
        Error.addMessage(Error.DIFFERENT_NO_EQUATION_IF_BRANCHES, {elt_str});
      then
        {};
    case (IF_EQUATION(condition1 = cond,equations2 = true_branch,equations3 = false_branch))
      equation 
        true_eq = listLength(true_branch);
        false_eq = listLength(false_branch);
        (true_eq == false_eq) = true;
        equations = makeEquationsFromIf(cond, true_branch, false_branch);
      then
        equations;
    case (_) then fail(); 
  end matchcontinue;
end ifEqToExpr;

protected function makeEquationsFromIf
  input Exp.Exp inExp1;
  input list<Element> inElementLst2;
  input list<Element> inElementLst3;
  output list<Element> outElementLst;
algorithm 
  outElementLst:=
  matchcontinue (inExp1,inElementLst2,inElementLst3)
    local
      list<Element> rest_res,rest1,rest2;
      Exp.Exp tb,fb,cond,exp1,exp2,exp3,exp4;
      Element eq;
    case (_,{},{}) then {}; 
    case (cond,(EQUATION(exp = exp1,scalar = exp2) :: rest1),(EQUATION(exp = exp3,scalar = exp4) :: rest2))
      equation 
        rest_res = makeEquationsFromIf(cond, rest1, rest2);
        tb = Exp.BINARY(exp1,Exp.SUB(Exp.REAL()),exp2);
        fb = Exp.BINARY(exp3,Exp.SUB(Exp.REAL()),exp4);
        eq = EQUATION(Exp.RCONST(0.0),Exp.IFEXP(cond,tb,fb));
      then
        (eq :: rest_res);
  end matchcontinue;
end makeEquationsFromIf;
end DAE;

