/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ResidualCmp
" file:        ResidualCmp.mo
  package:     ResidualCmp
  description: Code generation using Susan templates

  RCS: $Id: ResidualCmp.mo 12794 2012-09-05 16:52:31Z perost $

  The entry point to this module is the generateModelCode function.

  Except for the entry point, the only other public functions are those that
  can be imported and called from templates.

  The number of imported functions should be kept as low as possible. Today
  some of them are needed to generate target code from templates. More careful
  design of data structures passed to templates should reduce the number of
  imported functions needed.
.
"

// public imports
public import Absyn;
public import BackendDAE;
public import Ceval;
public import DAE;
public import SimCode;

// protected imports
protected import CevalScript;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import List;
protected import PartFn;
protected import SCode;
protected import SimCodeUtil;


/************ public functions ***************************/


public function generateModelCode
  "Generates code for a model by creating a ResidualCmp structure and calling the
   template-based code generator on it."

  input Absyn.Program p;
  input DAE.DAElist dae;
  input DAE.FunctionTree functionTree;
  input Absyn.Path className;
  input String filenamePrefix;
  input Absyn.FunctionArgs args;
  output list<String> libs;
  output String fileDir;
protected
  Absyn.ComponentRef a_cref;
  list<String> includes,includeDirs;
  list<SimCode.Function> functions;
  String filename, funcfilename;
  SimCode.SimCode residualcmp;
  list<SimCode.RecordDeclaration> recordDecls;
algorithm
  a_cref := Absyn.pathToCref(className);
  fileDir := CevalScript.getFileDir(a_cref, p);
  (libs, includes, includeDirs, recordDecls, functions) := createFunctions(p, dae, functionTree, className);
  residualcmp := createResidualCmp(dae,className, filenamePrefix, fileDir, functions, includes, includeDirs, libs, recordDecls, args);

  Debug.execStat("ResidualCmp",CevalScript.RT_CLOCK_SIMCODE);

  //Tpl.tplNoret(CodegenCSharp.translateModel, simCode);
end generateModelCode;

/*********************************************************/

/***************** protected functions *******************/

/* Finds the called functions in BackendDAE and transforms them to a list of
 libraries and a list of SimCode.Function uniontypes. */
public function createFunctions
  input Absyn.Program program;
  input DAE.DAElist inDAElist;
  input DAE.FunctionTree functionTree;
  input Absyn.Path inPath;
  output list<String> libs;
  output list<String> includes;
  output list<String> includeDirs;
  output list<SimCode.RecordDeclaration> recordDecls;
  output list<SimCode.Function> functions;
algorithm
  (libs, includes, includeDirs, recordDecls, functions) :=
  matchcontinue (program,inDAElist,functionTree,inPath)
    local
      list<String> libs2,includes2,includeDirs2;
      list<DAE.Function> funcelems,part_func_elems;
      DAE.DAElist dae;
      Absyn.Path path;
      list<SimCode.Function> fns;
      list<DAE.Exp> lits;

    case (_,dae,_,path)
      equation
        // get all the used functions from the function tree
        funcelems = DAEUtil.getFunctionList(functionTree);
        part_func_elems = PartFn.createPartEvalFunctions(funcelems);
        (dae, part_func_elems) = PartFn.partEvalDAE(dae, part_func_elems);
        funcelems = List.union(part_func_elems, part_func_elems);
        //funcelems = List.union(funcelems, part_func_elems);
        (fns, recordDecls, includes2, includeDirs2, libs2) = SimCodeUtil.elaborateFunctions(program, funcelems, {}, {}, {}); // Do we need metarecords here as well?
      then
        (libs2, includes2, includeDirs2, recordDecls, fns);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Creation of Modelica functions failed. "});
      then
        fail();
  end matchcontinue;
end createFunctions;


protected function createResidualCmp
  input DAE.DAElist dae;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String fileDir;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input list<SimCode.RecordDeclaration> recordDecls;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode residualcmp;
algorithm
  residualcmp :=
  matchcontinue (dae,inClassName,filenamePrefix,fileDir,functions,externalFunctionIncludes,includeDirs,libs,recordDecls,args)
    local
      list<DAE.Element> daevars,elementLst;
      SimCode.SimVars simvars;
      SimCode.VarInfo varinfo;
      SimCode.ModelInfo modelInfo;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.SimCode rescmp;
      list<SimCode.SimEqSystem> allEquations,allInitEquations;
      SimCode.DelayedExpression delayexp;
      SimCode.HashTableCrefToSimVar hashTable;
    case (DAE.DAE(elementLst=elementLst),_,_,_,_,_,_,_,_,_)
      equation
        // generate all residual equations
        (daevars,_,allEquations,allInitEquations) = generateEquationscollectVars(elementLst,{},1,{},{});
        // generate variable definitions
        simvars = SimCode.SIMVARS({},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{});
        varinfo = SimCode.VARINFO(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,NONE(),NONE());

        modelInfo = SimCode.MODELINFO(inClassName,fileDir,varinfo,simvars,functions,{});
        extObjInfo = SimCode.EXTOBJINFO({},{});
        makefileParams = SimCode.MAKEFILE_PARAMS("","","","","","","","","",includeDirs,libs,"");
        delayexp = SimCode.DELAYED_EXPRESSIONS({},0);
        hashTable = SimCodeUtil.emptyHashTable();
        rescmp = SimCode.SIMCODE(modelInfo,{},recordDecls,externalFunctionIncludes,{},{},{},allEquations,false,allInitEquations,{},{},{},{},{},{},{},{},{},{},BackendDAE.SAMPLE_LOOKUP(0,{}),{},{},extObjInfo,makefileParams,delayexp,{},NONE(),filenamePrefix,hashTable);
      then
        rescmp;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"ResidualCmp.createResidualCmp failed!"});
      then
        fail();
  end matchcontinue;
end createResidualCmp;


protected function generateEquationscollectVars
  input list<DAE.Element> inElements;
  input list<DAE.Element> iVars;
  input Integer equationindex;
  input list<SimCode.SimEqSystem> iEquations;
  input list<SimCode.SimEqSystem> iInitialEquations;
  output list<DAE.Element> oVars;
  output Integer oequationindex;
  output list<SimCode.SimEqSystem> oEquations;
  output list<SimCode.SimEqSystem> oInitialEquations;
algorithm
  (oVars,oequationindex,oEquations,oInitialEquations) := match(inElements,iVars,equationindex,iEquations,iInitialEquations)
    local
      DAE.Element elem;
      list<DAE.Element>  rest,daeElts,vars;
      list<SimCode.SimEqSystem> simeqns,initsimeqns;
      Integer index;

    case ({},_,_,_,_) then (iVars,equationindex,iEquations,iInitialEquations);

    // external Objects
    case ((elem as DAE.EXTOBJECTCLASS(path=_))::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    // Variables
    case ((elem as DAE.VAR(componentRef = _))::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,elem::iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    // equations
    case((elem as DAE.EQUATION(exp=_))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // initial equations
    case ((elem as DAE.INITIALEQUATION(exp1 = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // effort variable equality equations
    case ((elem as DAE.EQUEQUATION(cr1 = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // a solved equation
    case ((elem as DAE.DEFINE(componentRef = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // complex initial equations
    case ((elem as DAE.INITIAL_COMPLEX_EQUATION(lhs = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // array equations
    case ((elem as DAE.ARRAY_EQUATION(dimension=_))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // initial array equations
    case ((elem as DAE.INITIAL_ARRAY_EQUATION(exp = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // when equations
    case (DAE.WHEN_EQUATION(equations = _)::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    // if equation
    case ((elem as DAE.IF_EQUATION(equations2 = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);
    // initial if equation
    case ((elem as DAE.INITIAL_IF_EQUATION(condition1 = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // algorithm
    case ((elem as DAE.ALGORITHM(algorithm_ = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // initial algorithm
    case ((elem as DAE.INITIALALGORITHM(algorithm_ = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // flat class / COMP
    case (DAE.COMP(dAElist = daeElts)::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(daeElts,iVars,equationindex,iEquations,iInitialEquations);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,vars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // reinit
    case (DAE.REINIT(componentRef = _)::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    // assert in equation
    case ((elem as DAE.ASSERT(condition = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    // terminate in equation section is converted to ALGORITHM
    case ((elem as DAE.TERMINATE(message = _))::rest,_,_,_,_)
      equation
        (simeqns,initsimeqns,index) = generateEquation(elem,iEquations,iInitialEquations,equationindex);
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,index,simeqns,initsimeqns);
      then
        (vars,index,simeqns,initsimeqns);

    case (DAE.NORETCALL(functionName = _)::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case (DAE.CONSTRAINT(constraints = _)::rest,_,_,_,_)
      equation
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);

    case (elem::rest,_,_,_,_)
      equation
        Debug.traceln("- ResidualCmp.generateEquationscollectVars skipp: " +& DAEDump.dumpElementsStr({elem}));
        (vars,index,simeqns,initsimeqns) = generateEquationscollectVars(rest,iVars,equationindex,iEquations,iInitialEquations);
      then
        (vars,index,simeqns,initsimeqns);
  end match;
end generateEquationscollectVars;


protected function generateEquation
  input DAE.Element inElement;
  input list<SimCode.SimEqSystem> iEquations;
  input list<SimCode.SimEqSystem> iInitialEquations;
  input Integer index;
  output list<SimCode.SimEqSystem> oEquations;
  output list<SimCode.SimEqSystem> oInitialEquations;
  output Integer oindex;
algorithm
  (oEquations,oInitialEquations,oindex) := match(inElement,iEquations,iInitialEquations,index)
    local
      DAE.Exp e1,e2,res;
      DAE.ComponentRef cr1,cr2;
      DAE.ElementSource source;
      SimCode.SimEqSystem simeqn;

    // equations
    case(DAE.EQUATION(exp=e1,scalar=e2,source=source),_,_,_)
      equation
        res = Expression.expSub(e1,e2);
        simeqn = SimCode.SES_RESIDUAL(index,res,source);
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // initial equations
    case (DAE.INITIALEQUATION(exp1=e1,exp2=e2,source=source),_,_,_)
      equation
        res = Expression.expSub(e1,e2);
        simeqn = SimCode.SES_RESIDUAL(0,res,source);
      then
        (iEquations,simeqn::iInitialEquations,index+1);

    // effort variable equality equations
    case (DAE.EQUEQUATION(cr1=cr1,cr2=cr2,source=source),_,_,_)
      equation
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
        res = Expression.expSub(e1,e2);
        simeqn = SimCode.SES_RESIDUAL(0,res,source);
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // a solved equation
    case (DAE.DEFINE(componentRef=cr1,exp=e2,source=source),_,_,_)
      equation
        e1 = Expression.crefExp(cr1);
        res = Expression.expSub(e1,e2);
        simeqn = SimCode.SES_RESIDUAL(0,res,source);
      then
        (simeqn::iEquations,iInitialEquations,index+1);

/*
    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = _)),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // complex initial equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // array equations
    case ((elem as DAE.ARRAY_EQUATION(dimension=_)),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // initial array equations
    case (DAE.INITIAL_ARRAY_EQUATION(exp = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // when equations
    case (DAE.WHEN_EQUATION(equations = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // if equation that cannot be translated to if expression but have initial() as condition
    case (DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))}),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // if equation
    case (DAE.IF_EQUATION(equations2 = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);
    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(condition1 = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // algorithm
    case (DAE.ALGORITHM(algorithm_ = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // assert in equation
    case (DAE.ASSERT(condition = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);

    // terminate in equation section is converted to ALGORITHM
    case (DAE.TERMINATE(message = _),_,_,_)
      equation
      then
        (simeqn::iEquations,iInitialEquations,index+1);;
*/
    case (_,_,_,_)
      equation
        Debug.traceln("- ResidualCmp.generateEquation skipped: " +& DAEDump.dumpElementsStr({inElement}));
      then
        (iEquations,iInitialEquations,index);

  end match;
end generateEquation;

protected function generateVars
  input DAE.Element inElement;
  input list<SimCode.SimVar> irealVars;
  input list<SimCode.SimVar> iintVars;
  input list<SimCode.SimVar> iboolVars;
  input list<SimCode.SimVar> istringVars;
  input list<SimCode.SimVar> iextVars;
  output list<SimCode.SimVar> orealVars;
  output list<SimCode.SimVar> ointVars;
  output list<SimCode.SimVar> oboolVars;
  output list<SimCode.SimVar> ostringVars;
  output list<SimCode.SimVar> oextVars;
algorithm
  (orealVars,ointVars,oboolVars,ostringVars,oextVars) := match(inElement,irealVars,iintVars,iboolVars,istringVars,iextVars)
    local
      list<SimCode.SimVar> realVars,intVars,boolVars,stringVars,extVars;

    // Variables
    case (DAE.VAR(ty=DAE.T_REAL(source=_)),_,_,_,_,_)
      equation
        realVars = generateVar(inElement,irealVars);
      then
        (realVars,iintVars,iboolVars,istringVars,iextVars);

    case (DAE.VAR(ty=DAE.T_INTEGER(source=_)),_,_,_,_,_)
      equation
        intVars = generateVar(inElement,iintVars);
      then
        (irealVars,intVars,iboolVars,istringVars,iextVars);

    case (DAE.VAR(ty=DAE.T_BOOL(source=_)),_,_,_,_,_)
      equation
        boolVars = generateVar(inElement,iboolVars);
      then
        (irealVars,iintVars,boolVars,istringVars,iextVars);


    case (DAE.VAR(ty=DAE.T_STRING(source=_)),_,_,_,_,_)
      equation
        stringVars = generateVar(inElement,istringVars);
      then
        (irealVars,iintVars,iboolVars,stringVars,iextVars);

    case (_,_,_,_,_,_)
      equation
        Debug.traceln("- ResidualCmp.generateVar skipped: " +& DAEDump.dumpElementsStr({inElement}));
      then
        (irealVars,iintVars,iboolVars,istringVars,iextVars);

  end match;
end generateVars;

protected function generateVar
  input DAE.Element inElement;
  input list<SimCode.SimVar> ivars;
  output list<SimCode.SimVar> ovars;
algorithm
  ovars := match (inElement,ivars)
    local
      DAE.ComponentRef cr;
      DAE.VarKind daekind;
      BackendDAE.VarKind kind;
      list<Expression.Subscript> inst_dims;
      list<String> numArrayElement;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BackendDAE.Type tp;
      String  commentStr,  unit, displayUnit;
      Option<DAE.Exp> minValue,maxValue,nomVal;
      DAE.Type type_;
      Option<DAE.ComponentRef> arrayCref;
      DAE.ElementSource source;
    case (DAE.VAR(componentRef = cr,
      kind = daekind,
      dims = inst_dims,
      variableAttributesOption = dae_var_attr,
      ty = tp,
      source = source),_)
      equation
        commentStr = "";
        unit = "";
        displayUnit = "";
        minValue = NONE();
        maxValue = NONE();
        nomVal = NONE();
        type_ = tp;
        arrayCref = SimCodeUtil.getArrayCref(cr);
        numArrayElement = List.map(inst_dims, ExpressionDump.subscriptString);
        kind = daeKindtoBackendDAEKind(daekind);
      then
        SimCode.SIMVAR(cr, kind, commentStr, unit, displayUnit, -1 /* use -1 to get an error in simulation if something failed */,
        minValue, maxValue, NONE(), nomVal, false, type_, false, arrayCref, SimCode.NOALIAS(), source, SimCode.NONECAUS(),NONE(),numArrayElement)::ivars;
  end match;
end generateVar;

protected function daeKindtoBackendDAEKind
  input DAE.VarKind ikind;
  output BackendDAE.VarKind okind;
algorithm
  okind := match(ikind)
    case DAE.VARIABLE() then BackendDAE.VARIABLE();
    case DAE.DISCRETE() then BackendDAE.DISCRETE();
    case DAE.PARAM() then BackendDAE.PARAM();
    case DAE.CONST() then BackendDAE.CONST();
  end match;
end daeKindtoBackendDAEKind;

end ResidualCmp;
