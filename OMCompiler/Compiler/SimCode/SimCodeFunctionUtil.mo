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

encapsulated package SimCodeFunctionUtil "SimCode functions not related to equation systems"

import DAE;
import HashTableExpToIndex;
import SimCodeFunction;
import SimCodeVar;

protected

import Array;
import Autoconf;
import BaseHashTable;
import CevalScript;
import ComponentReference;
import DAEDump;
import DAEUtil;
import ElementSource;
import Error;
import Expression;
import ExpressionSimplify;
import ExpressionDump;
import Flags;
import Graph;
import List;
import Mod;
import Patternm;
import SCode;
import SCodeUtil;
import Testsuite;

public

public function elementVars
"Used by templates to get a list of variables from a valueblock."
  input list<DAE.Element> ild;
  output list<SimCodeFunction.Variable> vars;
protected
  list<DAE.Element> ld;
algorithm
  ld := List.filterOnTrue(ild, isVarQ);
  vars := List.map(ld, daeInOutSimVar);
end elementVars;

public function crefSubIsScalar
"Used by templates to determine if a component reference's subscripts are
 scalar."
  input DAE.ComponentRef cref;
  output Boolean isScalar;
protected
  list<DAE.Subscript> subs;
algorithm
  subs := ComponentReference.crefSubs(cref);
  isScalar := subsToScalar(subs);
end crefSubIsScalar;

protected function subsToScalar "scalar expression."
  input list<DAE.Subscript> inExpSubscriptLst;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inExpSubscriptLst)
    local
      Boolean b;
      list<DAE.Subscript> r;
    case {} then true;
    case (DAE.SLICE() :: _) then false;
    case (DAE.WHOLEDIM() :: _) then false;
    case (DAE.INDEX() :: r)
      equation
        b = subsToScalar(r);
      then
        b;
  end match;
end subsToScalar;

public function crefNoSub
"Used by templates to determine if a component reference has no subscripts."
  input DAE.ComponentRef cref;
  output Boolean noSub;
algorithm
  noSub := not ComponentReference.crefHaveSubs(cref);
end crefNoSub;

public function inFunctionContext
  input SimCodeFunction.Context inContext;
  output Boolean outInFunction;
algorithm
  outInFunction := match inContext
    case SimCodeFunction.FUNCTION_CONTEXT() then true;
    else false;
  end match;
end inFunctionContext;

public function crefIsScalar
  "Whether a component reference is a scalar depends on what context we are in.
  If we are generating code for a function, then only crefs without subscripts
  are scalar. If we are generating code for simulation though, then crefs with
  only constant subscripts are also scalars, since a variable is generated for
  each element of an array in the model."
  input DAE.ComponentRef cref;
  input SimCodeFunction.Context context;
  output Boolean isScalar;
algorithm
  if inFunctionContext(context) then
    isScalar := listEmpty(ComponentReference.crefLastSubs(cref));
  elseif Flags.isSet(Flags.NF_SCALARIZE) then
    isScalar := ComponentReference.crefHasScalarSubscripts(cref);
  else
    isScalar := not ComponentReference.crefHaveSubs(cref);
  end if;
end crefIsScalar;

public function buildCrefExpFromAsub
"Used by templates to convert an ASUB expression to a component reference
 with subscripts."
  input DAE.Exp cref;
  input list<DAE.Exp> subs;
  output DAE.Exp cRefOut;
algorithm
  cRefOut := matchcontinue(cref, subs)
    local
      DAE.Exp crefExp;
      DAE.Type ty;
      DAE.ComponentRef crNew;
      list<DAE.Subscript> indexes;

    case (_, {}) then cref;
    case (DAE.CREF(componentRef=crNew, ty=ty), _)
      equation
        indexes = List.map(subs, Expression.makeIndexSubscript);
        crNew = ComponentReference.subscriptCref(crNew, indexes);
        crefExp = Expression.makeCrefExp(crNew, ty);
      then
        crefExp;
  end matchcontinue;
end buildCrefExpFromAsub;

public function incrementInt
"Used by templates to create new integers that are increments of another."
  input Integer inInt;
  input Integer increment;
  output Integer outInt;
algorithm
  outInt := inInt + increment;
end incrementInt;

public function decrementInt
"Used by templates to create new integers that are increments of another."
  input Integer inInt;
  input Integer decrement;
  output Integer outInt;
algorithm
  outInt := inInt - decrement;
end decrementInt;


public function protectedVars
    input list<SimCodeVar.SimVar> InSimVars;
    output list<SimCodeVar.SimVar> OutSimVars;
   algorithm
   OutSimVars:= List.filterOnTrue(InSimVars,isNotProtected);
end protectedVars;

protected function isNotProtected
  input SimCodeVar.SimVar simVar;
  output Boolean isProtected;
algorithm
  SimCodeVar.SIMVAR(isProtected=isProtected) := simVar;
  isProtected := not isProtected;
end isNotProtected;


public function makeCrefRecordExp
"Helper function to generate records."
  input DAE.ComponentRef inCRefRecord;
  input DAE.Var inVar;
  output DAE.Exp outExp;
algorithm
  outExp := match (inCRefRecord, inVar)
    local
      DAE.ComponentRef cr, cr1;
      String name;
      DAE.Type tp;
    case (cr, DAE.TYPES_VAR(name=name, ty=tp))
      equation
        cr1 = ComponentReference.crefPrependIdent(cr, name, {}, tp);
        outExp = Expression.makeCrefExp(cr1, tp);
      then
        outExp;
  end match;
end makeCrefRecordExp;

public function splitRecordAssignmentToMemberAssignments
"This function is used by the templates to split up a record assignment to
 assignments of each of the members. This is needed in simulation context
 since there is no 'record' per se. Instead the elements(locations) of the record are
 scattered through the SIMVAR structure.

 Note that this does not recurse to check if a member itself is a record as well i.e.
 we generate an assignment of records. But since these assignments are sent the codegen
 template we will indirectly come back here and resolve them."
  input DAE.ComponentRef lhs_cref;
  input DAE.Type lhs_type;
  input String rhs_cref_str;
  output list<DAE.Statement> outAssigns;
protected
  DAE.ComponentRef rhs_cref;
algorithm

  outAssigns := {};
  rhs_cref := DAE.CREF_IDENT(rhs_cref_str, lhs_type, {});

  _ := match lhs_type
    local
      DAE.ComponentRef l_v_cref,r_v_cref;
      DAE.Exp l_v_exp, r_v_exp;
      DAE.Statement stmt;

    case DAE.T_COMPLEX() algorithm
      for v in lhs_type.varLst loop
        // l_v_cref := ComponentReference.crefPrependIdent(lhs_cref, v.name, {}, v.ty);
        // r_v_cref := ComponentReference.crefPrependIdent(rhs_cref, v.name, {}, v.ty);

        // l_v_exp := Expression.makeCrefExp(l_v_cref, v.ty);
        // r_v_exp := Expression.makeCrefExp(r_v_cref, v.ty);

        l_v_exp := makeCrefRecordExp(lhs_cref, v);
        r_v_exp := makeCrefRecordExp(rhs_cref, v);

        if Types.isArray(v.ty) then
          stmt := DAE.STMT_ASSIGN_ARR(v.ty, l_v_exp, r_v_exp, DAE.emptyElementSource);
        else
          stmt := DAE.STMT_ASSIGN(v.ty, l_v_exp, r_v_exp, DAE.emptyElementSource);
        end if;

        outAssigns := stmt::outAssigns;
      end for;

      outAssigns := listReverse(outAssigns);
    then ();

  end match;
end splitRecordAssignmentToMemberAssignments;

public function derComponentRef
"Used by templates to derrive a cref in a der(cref) expression.
 Particularly, this function is called for the C# code generator,
 while for C/C++, it is solved by prefixing the cref with '$P$DER' in daeExpCall() template.
 The prefixing technique is not usable for C#, because there is no macroprocessor in C#.
 TODO: all der(cref) expressions should be eliminated before the expressions enter templates
       to pull this logic (and this function) out of templates."
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef derCref;
algorithm
  derCref := ComponentReference.crefPrefixDer(inCref);
end derComponentRef;

public function hackArrayReverseToCref
"This is a hack transformation of an expanded array back to its cref.
It is used in daeExpArray() (for C# yet) to optimize the generated code.
TODO: This function should not exist!
Rather the array should not be let expanded when SimCode is entering templates.
"
  input DAE.Exp inExp;
  input SimCodeFunction.Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      list<DAE.Exp> aRest;
      DAE.ComponentRef cr;
      DAE.Type aty;
      DAE.Exp crefExp;

    case(DAE.ARRAY(ty=aty, scalar=true, array =(DAE.CREF(componentRef=cr) ::aRest)), _)
      equation
        failure(SimCodeFunction.FUNCTION_CONTEXT()=context); // only in the function context
        { DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isArrayExpansion(aRest, cr, 2);
        crefExp = Expression.makeCrefExp(cr, aty);
      then
        crefExp;

    else inExp;

  end matchcontinue;
end hackArrayReverseToCref;

protected function isArrayExpansion
"Helper funtion to hackArrayReverseToCref."
  input list<DAE.Exp> inArrayElems;
  input DAE.ComponentRef inCref;
  input Integer index;
  output Boolean isExpanded;
algorithm
  isExpanded := matchcontinue(inArrayElems, inCref, index)
    local
      list<DAE.Exp> aRest;
      Integer i;
      DAE.ComponentRef cr;
    case({}, _, _) then true;
    case (DAE.CREF(componentRef=cr) :: aRest, _, _)
      equation
        { DAE.INDEX(DAE.ICONST(i)) } = ComponentReference.crefLastSubs(cr);
        true = (i == index);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then isArrayExpansion(aRest, inCref, index+1);
    else false;
  end matchcontinue;
end isArrayExpansion;

public function hackMatrixReverseToCref
"This is a hack transformation of an expanded matrix back to its cref.
It is used in daeExpMatrix() (for C# yet) to optimize the generated code.
TODO: This function should not exist!
Rather the matrix should not be let expanded when SimCode is entering templates
"
  input DAE.Exp inExp;
  input SimCodeFunction.Context context;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp, context)
    local
      DAE.ComponentRef cr;
      DAE.Type aty;
      list<list<DAE.Exp>> rows;
      DAE.Exp crefExp;

    case(DAE.MATRIX(ty=aty, matrix = rows as (((DAE.CREF(componentRef=cr))::_)::_) ), _)
      equation
        failure(SimCodeFunction.FUNCTION_CONTEXT()=context);
        { DAE.INDEX(DAE.ICONST(1)), DAE.INDEX(DAE.ICONST(1)) } = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = isMatrixExpansion(rows, cr, 1, 1);
        crefExp = Expression.makeCrefExp(cr, aty);
      then
        crefExp;

    else inExp;

  end matchcontinue;
end hackMatrixReverseToCref;

protected function isMatrixExpansion
"Helper funtion to hackMatrixReverseToCref."
  input list<list<DAE.Exp>> rows;
  input DAE.ComponentRef inCref;
  input Integer rowIndex;
  input Integer colIndex;
  output Boolean isExpanded;
algorithm
  isExpanded := matchcontinue(rows, inCref, rowIndex, colIndex)
    local
      list<list<DAE.Exp>> restRows;
      list<DAE.Exp> restElems;
      Integer r, c;
      DAE.ComponentRef cr;
    case({}, _, _, _) then true;
    case({} :: restRows, _, _, _) then isMatrixExpansion(restRows, inCref, rowIndex+1, 1);
    case ( (DAE.CREF(componentRef=cr) :: restElems) :: restRows, _, _, _)
      equation
        { DAE.INDEX(DAE.ICONST(r)), DAE.INDEX(DAE.ICONST(c)) } = ComponentReference.crefLastSubs(cr);
        true = (r == rowIndex) and (c == colIndex);
        cr = ComponentReference.crefStripLastSubs(cr);
        true = ComponentReference.crefEqualNoStringCompare(inCref, cr);
      then isMatrixExpansion(restElems :: restRows, inCref, rowIndex, colIndex+1);
    else false;
  end matchcontinue;
end isMatrixExpansion;

public function hackGetFirstExternalFunctionLib
"This is a hack to get the original library name given to an external function.
TODO: redesign OMC and Modelica specification so they are not so C/C++ centric."
  input list<String> libs;
  output String outFirstLib;
algorithm
  outFirstLib := matchcontinue (libs)
    local
      String lib;

    case _
      equation
        lib = List.last(libs);
        lib = System.stringReplace(lib, "-l", "");
      then
        lib;

    else "NO_LIB";

  end matchcontinue;
end hackGetFirstExternalFunctionLib;

public function createAssertforSqrt
   input DAE.Exp inExp;
   output DAE.Exp outExp;
algorithm
  outExp :=
  match (inExp)
    case(_)
      equation
        // Simplify things like abs(exp) >= 0 to exp
        (outExp, _) = ExpressionSimplify.simplify(DAE.RELATION(inExp, DAE.GREATEREQ(DAE.T_REAL_DEFAULT), DAE.RCONST(0.0), -1, NONE()));
      then outExp;
  end match;
end createAssertforSqrt;

public function createDAEString
   input String inString;
   output DAE.Exp outExp;
   annotation(__OpenModelica_EarlyInline = true);
algorithm
  outExp := DAE.SCONST(inString);
end createDAEString;

/* end of TypeView published functions */

// =============================================================================
// section to generate SimCode from functions
//
// Finds the called functions in BackendDAE and transforms them to a list of
// libraries and a list of SimCodeFunction.Function uniontypes.
// =============================================================================

protected function orderRecordDecls
  input SimCodeFunction.RecordDeclaration decl1;
  input SimCodeFunction.RecordDeclaration decl2;
  output Boolean b;
algorithm
  b := match (decl1,decl2)
    local
      Absyn.Path path1,path2;
    case (SimCodeFunction.RECORD_DECL_DEF(path=path1),SimCodeFunction.RECORD_DECL_DEF(path=path2)) then AbsynUtil.pathGe(path1,path2);
    else true;
  end match;
end orderRecordDecls;

public function elaborateFunctions
  input Absyn.Program program;
  input list<DAE.Function> daeElements;
  input list<DAE.Type> metarecordTypes;
  input list<DAE.Exp> literals;
  input list<String> includes;
  output list<SimCodeFunction.Function> functions;
  output list<SimCodeFunction.RecordDeclaration> extraRecordDecls;
  output list<String> outIncludes;
  output list<String> includeDirs;
  output list<String> libs;
  output list<String> libpaths;
protected
  list<SimCodeFunction.Function> fns;
  list<String> outRecordTypes;
  HashTableStringToPath.HashTable ht;
  list<tuple<SimCodeFunction.RecordDeclaration,list<SimCodeFunction.RecordDeclaration>>> g;
algorithm
  (extraRecordDecls, outRecordTypes) := elaborateRecordDeclarationsForMetarecords(literals, {}, {});
  (functions, outRecordTypes, extraRecordDecls, outIncludes, includeDirs, libs,libpaths) := elaborateFunctions2(program, daeElements, {}, outRecordTypes, extraRecordDecls, includes, {}, {},{});
  extraRecordDecls := List.unique(extraRecordDecls);
  (extraRecordDecls, _) := elaborateRecordDeclarationsFromTypes(metarecordTypes, extraRecordDecls, outRecordTypes);
  extraRecordDecls := List.sort(extraRecordDecls, orderRecordDecls);
  ht := HashTableStringToPath.emptyHashTableSized(BaseHashTable.lowBucketSize);
  (extraRecordDecls,_) := List.mapFold(extraRecordDecls, aliasRecordDeclarations, ht);
  // Topological sort since we have no guarantees in the order of generated records
  g := Graph.buildGraph(extraRecordDecls, getRecordDependencies, extraRecordDecls);
  (extraRecordDecls, {}) := Graph.topologicalSort(g, isRecordDeclEqual);
end elaborateFunctions;

protected function getRecordDependencies
  input SimCodeFunction.RecordDeclaration decl;
  input list<SimCodeFunction.RecordDeclaration> allDecls;
  output list<SimCodeFunction.RecordDeclaration> dependencies;
algorithm
  dependencies := match (decl,allDecls)
    local
      String name;
      list<SimCodeFunction.Variable> vars;
      list<DAE.Type> tys;
      list<list<DAE.Type>> tyss;
    case (SimCodeFunction.RECORD_DECL_FULL(aliasName=SOME(name)),_)
      then List.select1(allDecls, isRecordDecl, name);
    case (SimCodeFunction.RECORD_DECL_ADD_CONSTRCTOR(name=name),_)
      then List.select1(allDecls, isRecordDecl, name);
    case (SimCodeFunction.RECORD_DECL_FULL(variables=vars),_)
      equation
        tys = list(getVarType(v) for v in vars);
        tyss = List.map1(tys, Types.getAllInnerTypesOfType, Util.anyReturnTrue);
        tys = List.flatten(tyss);
        dependencies = List.filterMap1(tys, getRecordDependenciesFromType, allDecls);
      then List.unique(dependencies);
    else {};
  end match;
end getRecordDependencies;

protected function getVarType
  input SimCodeFunction.Variable var;
  output DAE.Type ty;
algorithm
  ty := match var
    case SimCodeFunction.VARIABLE(ty=ty) then ty;
    else DAE.T_ANYTYPE_DEFAULT;
  end match;
end getVarType;

protected function getRecordDependenciesFromType
  input DAE.Type ty;
  input list<SimCodeFunction.RecordDeclaration> allDecls;
  output SimCodeFunction.RecordDeclaration decl;
protected
  Absyn.Path path;
  String name;
algorithm
  DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path)) := ty;
  name := AbsynUtil.pathStringUnquoteReplaceDot(path, "_");
  decl := List.find1(allDecls, isRecordDecl, name);
end getRecordDependenciesFromType;

protected function isRecordDecl
  input SimCodeFunction.RecordDeclaration decl;
  input String name;
  output Boolean b;
algorithm
  b := match (decl,name)
    local
      String name1;
    case (SimCodeFunction.RECORD_DECL_FULL(name=name1),_) then stringEq(name,name1);
    else false;
  end match;
end isRecordDecl;

protected function isRecordDeclEqual
  input SimCodeFunction.RecordDeclaration decl1;
  input SimCodeFunction.RecordDeclaration decl2;
  output Boolean b;
algorithm
  b := match (decl1,decl2)
    local
      String name1,name2;
      Absyn.Path path1,path2;
    case (SimCodeFunction.RECORD_DECL_FULL(name=name1),SimCodeFunction.RECORD_DECL_FULL(name=name2)) then stringEq(name1,name2);
    case (SimCodeFunction.RECORD_DECL_DEF(path=path1),SimCodeFunction.RECORD_DECL_DEF(path=path2)) then AbsynUtil.pathEqual(path1,path2);
    else false;
  end match;
end isRecordDeclEqual;

protected function elaborateFunctions2
  input Absyn.Program program;
  input list<DAE.Function> daeElements;
  input list<SimCodeFunction.Function> inFunctions;
  input list<String> inRecordTypes;
  input list<SimCodeFunction.RecordDeclaration> inDecls;
  input list<String> inIncludes;
  input list<String> inIncludeDirs;
  input list<String> inLibs;
  input list<String> inPaths;
  output list<SimCodeFunction.Function> outFunctions;
  output list<String> outRecordTypes;
  output list<SimCodeFunction.RecordDeclaration> outDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
  output list<String> outLibsPaths;
algorithm
  (outFunctions, outRecordTypes, outDecls, outIncludes, outIncludeDirs, outLibs,outLibsPaths) :=
  match (program, daeElements, inFunctions, inRecordTypes, inDecls, inIncludes, inIncludeDirs, inLibs,inPaths)
    local
      Boolean b;
      list<SimCodeFunction.Function> accfns, fns;
      SimCodeFunction.Function fn;
      list<String> rt, rt_1, rt_2, includes, libs,libPaths;
      DAE.Function fel;
      list<DAE.Function> rest;
      list<SimCodeFunction.RecordDeclaration> decls;
      String name, fname;
      list<String> includeDirs;
      Absyn.Path path;

    case (_, {}, accfns, rt, decls, includes, includeDirs, libs,libPaths)
    then (listReverse(accfns), rt, decls, includes, includeDirs, libs,libPaths);
    case (_, (DAE.FUNCTION( type_ = DAE.T_FUNCTION(functionAttributes=DAE.FUNCTION_ATTRIBUTES(isBuiltin=DAE.FUNCTION_BUILTIN_PTR()))) :: rest), accfns, rt, decls, includes, includeDirs, libs,libPaths)
      equation
        // skip over builtin functions
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths) = elaborateFunctions2(program, rest, accfns, rt, decls, includes, includeDirs, libs,libPaths);
      then
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths);
    case (_, (DAE.FUNCTION(partialPrefix = true) :: rest), accfns, rt, decls, includes, includeDirs, libs,libPaths)
      equation
        // skip over partial functions
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths) = elaborateFunctions2(program, rest, accfns, rt, decls, includes, includeDirs, libs,libPaths);
      then
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths);
    case (_, (fel as DAE.FUNCTION(path = path, functions = DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(name=name, language="builtin"))::_))::rest, accfns, rt, decls, includes, includeDirs, libs,libPaths)
      equation
        // skip over builtin functions @adrpo: we should skip ONLY IF THE NAME OF THE FUNCTION IS THE SAME AS THE NAME OF THE EXTERNAL FUNCTION!
        fname = AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(path));
        b = stringEq(fname, name);
        if not b then
          (fn,_, decls, includes, includeDirs, libs,libPaths) = elaborateFunction(program, fel, rt, decls, includes, includeDirs, libs,libPaths);
        end if;
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths) = elaborateFunctions2(program, rest, List.consOnTrue(not b, fn, accfns), rt, decls, includes, includeDirs, libs,libPaths);
      then
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths);

    case (_, (fel as DAE.FUNCTION(path = path, functions = DAE.FUNCTION_EXT(externalDecl = DAE.EXTERNALDECL(name=name, language="C"))::_))::rest, accfns, rt, decls, includes, includeDirs, libs,libPaths)
      equation
        // skip over known external C functions @adrpo: we should skip ONLY IF THE NAME OF THE FUNCTION IS THE SAME AS THE NAME OF THE EXTERNAL FUNCTION!
        fname = AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(path));
        b = listMember(name, SCodeUtil.knownExternalCFunctions) and stringEq(fname, name);
        if not b then
          (fn,_, decls, includes, includeDirs, libs,libPaths) = elaborateFunction(program, fel, rt, decls, includes, includeDirs, libs,libPaths);
        end if;
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths) = elaborateFunctions2(program, rest, List.consOnTrue(not b, fn, accfns), rt, decls, includes, includeDirs, libs,libPaths);
      then
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths);

    case (_, (fel :: rest), accfns, rt, decls, includes, includeDirs, libs,libPaths)
      equation
        (fn, rt_1, decls, includes, includeDirs, libs,libPaths) = elaborateFunction(program, fel, rt, decls, includes, includeDirs, libs,libPaths);
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths) = elaborateFunctions2(program, rest, (fn :: accfns), rt_1, decls, includes, includeDirs, libs,libPaths);
      then
        (fns, rt_2, decls, includes, includeDirs, libs,libPaths);
  end match;
end elaborateFunctions2;

/* Does the actual work of transforming a DAE.FUNCTION to a SimCodeFunction.Function. */
protected function elaborateFunction
  input Absyn.Program program;
  input DAE.Function inElement;
  input list<String> inRecordTypes;
  input list<SimCodeFunction.RecordDeclaration> inRecordDecls;
  input list<String> inIncludes;
  input list<String> inIncludeDirs;
  input list<String> inLibs;
  input list<String> inLibPaths;
  output SimCodeFunction.Function outFunction;
  output list<String> outRecordTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<String> outLibs;
  output list<String> outLibPaths;
algorithm
  (outFunction, outRecordTypes, outRecordDecls, outIncludes, outIncludeDirs, outLibs,outLibPaths):=
  matchcontinue (program, inElement, inRecordTypes, inRecordDecls, inIncludes, inIncludeDirs, inLibs,inLibPaths)
    local
      DAE.Function fn;
      String extfnname, lang, str;
      list<DAE.Element> algs, vars; // , bivars, invars, outvars;
      list<String> includes, libs, libPaths, fn_libs,fn_paths, fn_includes, fn_includeDirs, rt, rt_1;
      Absyn.Path fpath;
      list<DAE.FuncArg> args;
      DAE.Type restype, tp;
      list<DAE.ExtArg> extargs;
      list<SimCodeFunction.SimExtArg> simextargs;
      SimCodeFunction.SimExtArg extReturn;
      DAE.ExtArg extretarg;
      Option<SCode.Annotation> ann;
      DAE.ExternalDecl extdecl;
      list<SimCodeFunction.Variable> outVars, inVars, biVars, funArgs, varDecls;
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<DAE.Statement> bodyStmts;
      list<DAE.Element> daeElts;
      Absyn.Path name;
      DAE.ElementSource source;
      SourceInfo info;
      Boolean dynamicLoad, hasIncludeAnnotation, hasLibraryAnnotation;
      list<String> includeDirs;
      DAE.FunctionAttributes funAttrs;
      list<DAE.Var> varlst;
      DAE.VarKind kind;
      SCode.Visibility visibility;

      // Modelica functions.
    case (_, DAE.FUNCTION(path = fpath, source = source, visibility = visibility,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = DAE.T_FUNCTION(funcArg=args, functionAttributes=funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs,libPaths)
      equation

        DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_NON_PARALLEL()) = funAttrs;

        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map1(args, typesSimFunctionArg, NONE());
        (recordDecls, rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filterOnTrue(daeElts, isVarQ);
        varDecls = List.map(vars, daeInOutSimVar);
        bodyStmts = listAppend(elaborateStatement(e) for e guard DAEUtil.isAlgorithm(e) in daeElts);
        info = ElementSource.getElementSourceFileInfo(source);
      then
        (SimCodeFunction.FUNCTION(fpath, outVars, funArgs, varDecls, bodyStmts, visibility, info), rt_1, recordDecls, includes, includeDirs, libs,libPaths);


     case (_, DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = DAE.T_FUNCTION(funcArg=args, functionAttributes=funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs,libPaths)
      equation

        DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_KERNEL_FUNCTION()) = funAttrs;

        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map1(args, typesSimFunctionArg, NONE());
        (recordDecls, rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filterOnTrue(daeElts, isVarNotInputNotOutput);
        varDecls = List.map(vars, daeInOutSimVar);
        bodyStmts = listAppend(elaborateStatement(e) for e guard DAEUtil.isAlgorithm(e) in daeElts);
        info = ElementSource.getElementSourceFileInfo(source);
      then
        (SimCodeFunction.KERNEL_FUNCTION(fpath, outVars, funArgs, varDecls, bodyStmts, info), rt_1, recordDecls, includes, includeDirs, libs,libPaths);


    case (_, DAE.FUNCTION(path = fpath, source = source,
      functions = DAE.FUNCTION_DEF(body = daeElts)::_, // might be followed by derivative maps
      type_ = DAE.T_FUNCTION(funcArg=args, functionAttributes = funAttrs),
      partialPrefix=false), rt, recordDecls, includes, includeDirs, libs,libPaths)
      equation

        DAE.FUNCTION_ATTRIBUTES(functionParallelism=DAE.FP_PARALLEL_FUNCTION()) = funAttrs;

        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        funArgs = List.map1(args, typesSimFunctionArg, NONE());
        (recordDecls, rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        vars = List.filterOnTrue(daeElts, isVarQ);
        varDecls = List.map(vars, daeInOutSimVar);
        bodyStmts = listAppend(elaborateStatement(e) for e guard DAEUtil.isAlgorithm(e) in daeElts);
        info = ElementSource.getElementSourceFileInfo(source);
      then
        (SimCodeFunction.PARALLEL_FUNCTION(fpath, outVars, funArgs, varDecls, bodyStmts, info), rt_1, recordDecls, includes, includeDirs, libs,libPaths);

    // External functions.
    case (_, DAE.FUNCTION(path = fpath, source = source, visibility = visibility,
      functions = DAE.FUNCTION_EXT(body =  daeElts, externalDecl = extdecl)::_, // might be followed by derivative maps
      type_ = (DAE.T_FUNCTION(funcArg = args))), rt, recordDecls, includes, includeDirs, libs,libPaths)
      equation
        DAE.EXTERNALDECL(name=extfnname, args=extargs,
          returnArg=extretarg, language=lang, ann=ann) = extdecl;
        // outvars = DAEUtil.getOutputVars(daeElts);
        // invars = DAEUtil.getInputVars(daeElts);
        // bivars = DAEUtil.getBidirVars(daeElts);
        funArgs = List.map1(args, typesSimFunctionArg, NONE());
        outVars = List.map(DAEUtil.getOutputVars(daeElts), daeInOutSimVar);
        inVars = List.map(DAEUtil.getInputVars(daeElts), daeInOutSimVar);
        biVars = List.map(DAEUtil.getBidirVars(daeElts), daeInOutSimVar);
        (recordDecls, rt_1) = elaborateRecordDeclarations(daeElts, recordDecls, rt);
        info = ElementSource.getElementSourceFileInfo(source);
        (fn_includes, fn_includeDirs, fn_libs, fn_paths,dynamicLoad) = generateExtFunctionIncludes(program, fpath, ann, info);
        includes = List.union(fn_includes, includes);
        includeDirs = List.union(fn_includeDirs, includeDirs);
        libs = List.union(fn_libs, libs);
        libPaths = List.union(fn_paths, libPaths);
        simextargs = List.map(extargs, extArgsToSimExtArgs);
        extReturn = extArgsToSimExtArgs(extretarg);
        (simextargs, extReturn) = fixOutputIndex(outVars, simextargs, extReturn);
        // make lang to-upper as we have FORTRAN 77 and Fortran 77 in the Modelica Library!
        lang = System.toupper(lang);
      then
        (SimCodeFunction.EXTERNAL_FUNCTION(fpath, extfnname, funArgs, simextargs, extReturn,
          inVars, outVars, biVars, fn_includes, fn_libs, lang, visibility, info, dynamicLoad),
          rt_1, recordDecls, includes, includeDirs, libs,libPaths);

        // Record constructor.
    case (_, DAE.RECORD_CONSTRUCTOR(source = source, type_ = DAE.T_FUNCTION(funcArg = args, funcResultType = restype as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(name)))), rt, recordDecls, includes, includeDirs, libs,libPaths)
      equation
        funArgs = List.map1(args, typesSimFunctionArg, NONE());
        (recordDecls, rt_1) = elaborateRecordDeclarationsForRecord(restype, recordDecls, rt);
        DAE.T_COMPLEX(varLst = varlst) = restype;
        // varlst = List.filterOnTrue(varlst, Types.isProtectedVar);
        varlst = List.filterOnFalse(varlst, Types.isModifiableTypesVar);
        varDecls = List.map(varlst, typesVar);
        info = ElementSource.getElementSourceFileInfo(source);
      then
        (SimCodeFunction.RECORD_CONSTRUCTOR(name, funArgs, varDecls, SCode.PUBLIC(), info), rt_1, recordDecls, includes, includeDirs, libs,libPaths);

        // failure
    case (_, fn, _, _, _, _, _,_)
      equation
        Error.addInternalError("function elaborateFunction failed for function: \n" + DAEDump.dumpFunctionStr(fn), sourceInfo());
      then
        fail();
  end matchcontinue;
end elaborateFunction;

protected function typesSimFunctionArg
"Generates code from a function argument."
  input DAE.FuncArg inFuncArg;
  input Option<DAE.Exp> binding;
  output SimCodeFunction.Variable outVar;
algorithm
  outVar := matchcontinue (inFuncArg, binding)
    local
      DAE.Type tty;
      String name;
      DAE.ComponentRef cref_;
      DAE.Const const;
      list<DAE.FuncArg> args;
      DAE.Type res_ty;
      list<SimCodeFunction.Variable> var_args;
      list<DAE.Type> tys;
      DAE.VarKind kind;
      DAE.VarParallelism prl;

    case (DAE.FUNCARG(name=name, ty=DAE.T_FUNCTION(funcArg = args, funcResultType = DAE.T_TUPLE(types = tys))), _)
      equation
        var_args = List.map1(args, typesSimFunctionArg, NONE());
        tys = List.map(tys, Types.simplifyType);
      then
        SimCodeFunction.FUNCTION_PTR(name, tys, var_args, binding);

    case (DAE.FUNCARG(name=name, ty=DAE.T_FUNCTION(funcArg = args, funcResultType = DAE.T_NORETCALL())), _)
      equation
        var_args = List.map1(args, typesSimFunctionArg, NONE());
      then
        SimCodeFunction.FUNCTION_PTR(name, {}, var_args, binding);

    case (DAE.FUNCARG(name=name, ty=DAE.T_FUNCTION(funcArg = args, funcResultType = res_ty)), _)
      equation
        res_ty = Types.simplifyType(res_ty);
        var_args = List.map1(args, typesSimFunctionArg, NONE());
      then
        SimCodeFunction.FUNCTION_PTR(name, {res_ty}, var_args, binding);

    case (DAE.FUNCARG(name=name, ty=tty, par=prl, const=const), _)
      equation
        tty = Types.simplifyType(tty);
        cref_  = ComponentReference.makeCrefIdent(name, tty, {});
        kind = DAEUtil.const2VarKind(const);
      then
        SimCodeFunction.VARIABLE(cref_, tty, binding, {}, prl, kind, false);
  end matchcontinue;
end typesSimFunctionArg;

protected function daeInOutSimVar
  input DAE.Element inElement;
  output SimCodeFunction.Variable outVar;
algorithm
  outVar := matchcontinue(inElement)
    local
      String name;
      DAE.Type daeType;
      DAE.ComponentRef id;
      DAE.VarKind kind;
      DAE.VarParallelism prl;
      list<DAE.Dimension> inst_dims;
      // list<DAE.Exp> inst_dims_exp;
      Option<DAE.Exp> binding;
      SimCodeFunction.Variable var;
    case (DAE.VAR(componentRef = DAE.CREF_IDENT(ident=name), ty = daeType as DAE.T_FUNCTION(), parallelism = prl, binding = binding))
      equation
        var = typesSimFunctionArg(DAE.FUNCARG(name, daeType, DAE.C_VAR(), prl, NONE()), binding);
      then var;

    case (DAE.VAR(componentRef = id,
      parallelism = prl,
      ty = daeType,
      binding = binding,
      dims = inst_dims,
      kind = kind
    ))
      algorithm
        daeType := Types.simplifyType(daeType);
        // inst_dims_exp := List.map(inst_dims, Expression.dimensionSizeExpHandleUnkown);
      then SimCodeFunction.VARIABLE(id, daeType, binding, inst_dims, prl, kind, false);
    else
      equation
        // TODO: ArrayEqn fails here
        Error.addInternalError("function daeInOutSimVar failed\n", sourceInfo());
      then
        fail();
  end matchcontinue;
end daeInOutSimVar;

protected function extArgsToSimExtArgs
  input DAE.ExtArg extArg;
  output SimCodeFunction.SimExtArg simExtArg;
algorithm
  simExtArg :=
  match (extArg)
    local
      DAE.ComponentRef componentRef;
      Absyn.Direction dir;
      DAE.Type type_;
      Boolean isInput;
      Boolean isOutput;
      Boolean isArray;
      DAE.Exp exp_;
      Integer outputIndex;

    case DAE.EXTARG(componentRef, dir, type_)
      equation
        isInput = AbsynUtil.isInput(dir);
        isOutput = AbsynUtil.isOutput(dir);
        outputIndex = if isOutput then -1 else 0; // correct output index is added later by fixOutputIndex
        isArray = Types.isArray(type_);
        type_ = Types.simplifyType(type_);
      then SimCodeFunction.SIMEXTARG(componentRef, isInput, outputIndex, isArray, false /*fixed later*/, type_);

    case DAE.EXTARGEXP(exp_, type_)
      equation
        type_ = Types.simplifyType(type_);
      then SimCodeFunction.SIMEXTARGEXP(exp_, type_);

    case DAE.EXTARGSIZE(componentRef, type_, exp_)
      equation
        type_ = Types.simplifyType(type_);
      then SimCodeFunction.SIMEXTARGSIZE(componentRef, true, 0, type_, exp_);

    case DAE.NOEXTARG() then SimCodeFunction.SIMNOEXTARG();
  end match;
end extArgsToSimExtArgs;

protected function fixOutputIndex
  input list<SimCodeFunction.Variable> outVars;
  input list<SimCodeFunction.SimExtArg> simExtArgsIn;
  input SimCodeFunction.SimExtArg extReturnIn;
  output list<SimCodeFunction.SimExtArg> simExtArgsOut;
  output SimCodeFunction.SimExtArg extReturnOut;
algorithm
  (simExtArgsOut, extReturnOut) := match (outVars, simExtArgsIn, extReturnIn)
    local
    case (_, _, _)
      equation
        simExtArgsOut = List.map1(simExtArgsIn, assignOutputIndex, outVars);
        extReturnOut = assignOutputIndex(extReturnIn, outVars);
      then
        (simExtArgsOut, extReturnOut);
  end match;
end fixOutputIndex;

protected function assignOutputIndex
  input SimCodeFunction.SimExtArg simExtArgIn;
  input list<SimCodeFunction.Variable> outVars;
  output SimCodeFunction.SimExtArg simExtArgOut;
algorithm
  simExtArgOut :=
  matchcontinue (simExtArgIn, outVars)
    local
      DAE.ComponentRef cref, fcref;
      Boolean isInput;
      Integer outputIndex; // > 0 if output
      Boolean isArray, hasBinding;
      DAE.Type type_;
      DAE.Exp exp;
      Integer newOutputIndex;

    case (SimCodeFunction.SIMEXTARG(cref, isInput, outputIndex, isArray, _, type_), _)
      equation
        true = outputIndex == -1;
        fcref = ComponentReference.crefFirstCref(cref);
        (newOutputIndex, hasBinding) = findIndexInList(fcref, outVars, 1);
      then
        SimCodeFunction.SIMEXTARG(cref, isInput, newOutputIndex, isArray, hasBinding, type_);

    case (SimCodeFunction.SIMEXTARGSIZE(cref, isInput, outputIndex, type_, exp), _)
      equation
        true = outputIndex == -1;
        (newOutputIndex, _) = findIndexInList(cref, outVars, 1);
      then
        SimCodeFunction.SIMEXTARGSIZE(cref, isInput, newOutputIndex, type_, exp);

    else
      simExtArgIn;
  end matchcontinue;
end assignOutputIndex;

protected function findIndexInList
  input DAE.ComponentRef cref;
  input list<SimCodeFunction.Variable> outVars;
  input Integer inCurrentIndex;
  output Integer crefIndexInOutVars;
  output Boolean hasBinding;
algorithm
  (crefIndexInOutVars, hasBinding) :=
  matchcontinue (cref, outVars, inCurrentIndex)
    local
      DAE.ComponentRef name;
      list<SimCodeFunction.Variable> restOutVars;
      Option<DAE.Exp> v;
      Integer currentIndex;

    case (_, {}, _) then (-1, false);
    case (_, SimCodeFunction.VARIABLE(name=name, value=v) :: _, currentIndex)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cref, name);
      then (currentIndex, Util.isSome(v));
    case (_, _ :: restOutVars, currentIndex)
      equation
        currentIndex = currentIndex + 1;
        (currentIndex, hasBinding) = findIndexInList(cref, restOutVars, currentIndex);
      then (currentIndex, hasBinding);
  end matchcontinue;
end findIndexInList;

protected function elaborateStatement
  input DAE.Element inElement;
  output list<DAE.Statement> stmts;
algorithm
  DAE.ALGORITHM(algorithm_ = DAE.ALGORITHM_STMTS(statementLst = stmts)) := inElement;
end elaborateStatement;


public function checkValidMainFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input String name;
  input SimCodeFunction.Function fn;
algorithm
  _ := matchcontinue (name, fn)
    local
      list<SimCodeFunction.Variable> inVars;
    case (_, SimCodeFunction.FUNCTION(functionArguments = inVars))
      equation
        failure(_ = List.find(inVars, isFunctionPtr));
      then ();
    case (_, SimCodeFunction.EXTERNAL_FUNCTION(inVars = inVars))
      equation
        failure(_ = List.find(inVars, isFunctionPtr));
      then ();
    else
      equation
        Error.addMessage(Error.GENERATECODE_INVARS_HAS_FUNCTION_PTR, {name});
      then fail();
  end matchcontinue;
end checkValidMainFunction;

public function isBoxedFunction
"Verifies that an in-function can be generated.
This is not the case if the input involves function-pointers."
  input SimCodeFunction.Function fn;
  output Boolean b;
algorithm
  b := matchcontinue fn
    local
      list<SimCodeFunction.Variable> inVars, outVars;
    case (SimCodeFunction.FUNCTION(functionArguments = inVars, outVars = outVars))
      equation
        List.map_0(inVars, isBoxedArg);
        List.map_0(outVars, isBoxedArg);
      then true;
    case (SimCodeFunction.EXTERNAL_FUNCTION(inVars = inVars, outVars = outVars))
      equation
        List.map_0(inVars, isBoxedArg);
        List.map_0(outVars, isBoxedArg);
      then true;
    else false;
  end matchcontinue;
end isBoxedFunction;

protected function isFunctionPtr
"Checks if an input variable is a function pointer"
  input SimCodeFunction.Variable var;
  output Boolean b;
algorithm
  b := match var
      /* Yes, they are VARIABLE, not SimCodeFunction.FUNCTION_PTR. */
    case SimCodeFunction.FUNCTION_PTR() then true;
    else false;
  end match;
end isFunctionPtr;

protected function isBoxedArg
"Checks if a variable is a boxed datatype"
  input SimCodeFunction.Variable var;
algorithm
  _ := match var
    case SimCodeFunction.FUNCTION_PTR() then ();
    case SimCodeFunction.VARIABLE(ty = DAE.T_METABOXED()) then ();
    case SimCodeFunction.VARIABLE(ty = DAE.T_METATYPE()) then ();
    case SimCodeFunction.VARIABLE(ty = DAE.T_STRING()) then ();
  end match;
end isBoxedArg;

public function funcHasParallelInOutArrays
"checks if a boxed function can be generated.
currently this is not the case if the input/output
involves parallel (global/local) array variables."
  input SimCodeFunction.Function fn;
  output Boolean b;
protected
  list<SimCodeFunction.Variable> inVars, outVars;
algorithm
  SimCodeFunction.FUNCTION(functionArguments = inVars, outVars = outVars) := fn;
  for e in inVars loop
    if isParallelArrayVar(e) then
      b := true;
      return;
    end if;
  end for;

  for e in outVars loop
    if isParallelArrayVar(e) then
      b := true;
      return;
    end if;
  end for;

  b := false;
end funcHasParallelInOutArrays;

protected function isParallelArrayVar
"Checks if a variable is a boxed datatype"
  input SimCodeFunction.Variable var;
  output Boolean b;
algorithm
  b := match var
    case SimCodeFunction.VARIABLE(ty = DAE.T_ARRAY(), parallelism = DAE.PARGLOBAL()) then true;
    case SimCodeFunction.VARIABLE(ty = DAE.T_ARRAY(), parallelism = DAE.PARLOCAL()) then true;
    else false;
  end match;
end isParallelArrayVar;

public function findLiterals
  "Finds all literal expressions in functions"
  input list<DAE.Function> fns;
  output list<DAE.Function> ofns;
  output list<DAE.Exp> literals;
algorithm
  (ofns, (_, _, literals)) := DAEUtil.traverseDAEFunctions(
    fns, findLiteralsHelper,
    (0, HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize), {}));
  literals := listReverse(literals);
end findLiterals;

public

function findLiteralsHelper
  input DAE.Exp inExp;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> inTpl;
  output DAE.Exp exp;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> tpl;
algorithm
  exp := inExp;
  tpl := inTpl;
  (exp, tpl) := Expression.traverseExpBottomUp(exp,
    function Patternm.traverseConstantPatternsHelper(func=replaceLiteralExp),
    tpl);
  (exp, tpl) := Expression.traverseExpTopDown(exp, replaceLiteralArrayExp, tpl);
end findLiteralsHelper;

protected

function replaceLiteralArrayExp
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals

  Handles only array expressions (needs to be performed in a top-down fashion)
  "
  input DAE.Exp inExp;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> inTpl;
  output DAE.Exp outExp;
  output Boolean cont=true;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp exp,exp2;
      tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> tpl;
    case (DAE.ARRAY(), tpl)
      algorithm
        try
          isLiteralArrayExp(inExp);
          (exp2, tpl) := replaceLiteralExp2(inExp, tpl);
          cont := false;
        else
          exp2 := inExp;
        end try;
      then (exp2, tpl);
    case (DAE.MATRIX(), tpl)
      algorithm
        try
          isLiteralArrayExp(inExp);
          (exp2, tpl) := replaceLiteralExp2(inExp, tpl);
          cont := false;
        else
          exp2 := inExp;
        end try;
      then (exp2, tpl);
    else (inExp, inTpl);
  end match;
end replaceLiteralArrayExp;

function replaceLiteralExp
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals
  "
  input DAE.Exp inExp;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> inTpl;
  output DAE.Exp outExp;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp;
      String msg;
      tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> t;
      list<DAE.Exp> es;
    case (exp, t)
      equation
        failure(isLiteralExp(exp));
      then (exp, t);
    case (exp, t)
      equation
        isTrivialLiteralExp(exp);
      then (exp, t);
    case (DAE.LIST(valList=es), t)
      equation
        true = listLength(es) > 25;
        (exp,t) = replaceLiteralExp2(inExp, t);
      then (exp, t); // Too large list; causes performance issues to find all sublists...
    case (exp, t)
      equation
        exp = listToCons(exp);
        (exp, t) = Expression.traverseExpBottomUp(exp, replaceLiteralExp, t);
      then (exp, t); // All sublists should also be added as literals...
    case (exp, _)
      equation
        failure(_ = listToCons(exp));
        (exp,t) = replaceLiteralExp2(exp, inTpl);
      then (exp, t);
    case (exp, _)
      equation
        msg = "function replaceLiteralExp failed. Falling back to not replacing "+ExpressionDump.printExpStr(exp)+".";
        Error.addInternalError(msg, sourceInfo());
      then (inExp,inTpl);
  end matchcontinue;
end replaceLiteralExp;

function replaceLiteralExp2
  "The tuples contain:
  * The expression to be replaced (or not)
  * Index of next literal
  * HashTable Exp->Index (Number of the literal)
  * The list of literals
  "
  input DAE.Exp inExp;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> inTpl;
  output DAE.Exp outExp;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp exp, nexp;
      Integer i, ix;
      list<DAE.Exp> l;
      DAE.Type et;
      HashTableExpToIndex.HashTable ht;
    case (exp, (_, ht, _))
      equation
        ix = BaseHashTable.get(exp, ht);
        nexp = DAE.SHARED_LITERAL(ix, exp);
      then (nexp, inTpl);
    case (exp, (i, ht, l))
      equation
        ht = BaseHashTable.add((exp, i), ht);
        nexp = DAE.SHARED_LITERAL(i, exp);
      then (nexp, (i+1, ht, exp::l));
  end matchcontinue;
end replaceLiteralExp2;

function listToCons
"Converts a DAE.LIST to a chain of DAE.CONS"
  input DAE.Exp e;
  output DAE.Exp o;
algorithm
  o := match e
    local
      list<DAE.Exp> es;
    case DAE.LIST(es as _::_) then listToCons2(es);
  end match;
end listToCons;

function listToCons2
"Converts a DAE.LIST to a chain of DAE.CONS"
  input list<DAE.Exp> ies;
  output DAE.Exp o;
algorithm
  o := match ies
    local
      DAE.Exp car, cdr;
      list<DAE.Exp> es;
    case ({}) then DAE.LIST({});
    case (car::es)
      equation
        cdr = listToCons2(es);
      then DAE.CONS(car, cdr);
  end match;
end listToCons2;

function isTrivialLiteralExp
"Succeeds if the expression should not be translated to a constant literal because it is too simple"
  input DAE.Exp exp;
algorithm
  _ := match exp
    case DAE.BOX(DAE.SCONST(_)) then fail();
    case DAE.BOX(DAE.RCONST(_)) then fail();
    case DAE.BOX(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.ENUM_LITERAL() then ();
    case DAE.LIST(valList={}) then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.SHARED_LITERAL() then ();
    else fail();
  end match;
end isTrivialLiteralExp;

function isLiteralArrayExp
  input DAE.Exp iexp;
algorithm
  _ := match iexp
    local
      DAE.Exp e1, e2, exp;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> expll;

    case DAE.SCONST(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.ARRAY(array=expl) equation List.map_0(expl, isLiteralArrayExp); then ();
    case DAE.MATRIX(matrix=expll) equation List.map_0(List.flatten(expll), isLiteralArrayExp); then ();
    case DAE.ENUM_LITERAL() then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.META_OPTION(SOME(exp)) equation isLiteralArrayExp(exp); then ();
    case DAE.BOX(exp) equation isLiteralArrayExp(exp); then ();
    case DAE.CONS(car = e1, cdr = e2) equation isLiteralArrayExp(e1); isLiteralArrayExp(e2); then ();
    case DAE.LIST(valList = expl) equation List.map_0(expl, isLiteralArrayExp); then ();
    case DAE.META_TUPLE(expl) equation List.map_0(expl, isLiteralArrayExp); then ();
    case DAE.METARECORDCALL(args=expl) equation List.map_0(expl, isLiteralArrayExp); then ();
    case DAE.SHARED_LITERAL() then ();
    else fail();
  end match;
end isLiteralArrayExp;

function isLiteralExp
"Returns if the expression may be replaced by a constant literal"
  input DAE.Exp iexp;
algorithm
  _ := match iexp
    local
      DAE.Exp e1, e2, exp;
      list<DAE.Exp> expl;
    case DAE.SCONST(_) then ();
    case DAE.ICONST(_) then ();
    case DAE.RCONST(_) then ();
    case DAE.BCONST(_) then ();
    case DAE.ENUM_LITERAL() then ();
    case DAE.META_OPTION(NONE()) then ();
    case DAE.META_OPTION(SOME(exp)) equation isLiteralExp(exp); then ();
    case DAE.BOX(exp) equation isLiteralExp(exp); then ();
    case DAE.CONS(car = e1, cdr = e2) equation isLiteralExp(e1); isLiteralExp(e2); then ();
    case DAE.LIST(valList = expl) equation List.map_0(expl, isLiteralExp); then ();
    case DAE.META_TUPLE(expl) equation List.map_0(expl, isLiteralExp); then ();
    case DAE.METARECORDCALL(args=expl) equation List.map_0(expl, isLiteralExp); then ();
    case DAE.SHARED_LITERAL() then ();
    case DAE.CALL(path=Absyn.IDENT("listArrayLiteral"), expLst=expl) algorithm List.map_0(expl, isLiteralExp); then ();
    else fail();
  end match;
end isLiteralExp;

protected function elaborateRecordDeclarationsFromTypes
  input list<DAE.Type> inTypes;
  input list<SimCodeFunction.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) :=
  match (inTypes, inAccRecordDecls, inReturnTypes)
    local
      list<SimCodeFunction.RecordDeclaration> accRecDecls;
      DAE.Type firstType;
      list<DAE.Type> restTypes;
      list<String> returnTypes;

    case ({}, accRecDecls, _)
    then (accRecDecls, inReturnTypes);
    case (firstType :: restTypes, accRecDecls, _)
      equation
        (accRecDecls, returnTypes) =
        elaborateRecordDeclarationsForRecord(firstType, accRecDecls, inReturnTypes);
        (accRecDecls, returnTypes) =
        elaborateRecordDeclarationsFromTypes(restTypes, accRecDecls, returnTypes);
      then (accRecDecls, returnTypes);
  end match;
end elaborateRecordDeclarationsFromTypes;

protected function elaborateRecordDeclarations
"Translate all records used by varlist to structs."
  input list<DAE.Element> inVars;
  input list<SimCodeFunction.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) :=
  matchcontinue (inVars, inAccRecordDecls, inReturnTypes)
    local
      DAE.Element var;
      list<DAE.Element> rest;
      DAE.Type ft;
      list<String> rt, rt_1, rt_2;
      list<SimCodeFunction.RecordDeclaration> accRecDecls;
      DAE.Algorithm algorithm_;
      list<DAE.Exp> expl;
      Option<DAE.Exp> binding;

    case ({}, accRecDecls, rt) then (accRecDecls, rt);

    case (((DAE.VAR(ty = ft, binding = binding)) :: rest), accRecDecls, rt)
      equation
        (accRecDecls, rt_1) = elaborateRecordDeclarationsForRecord(ft, accRecDecls, rt);
        if Util.isSome(binding) and Config.acceptMetaModelicaGrammar() then
          (_, expl) = Expression.traverseExpBottomUp(Util.getOption(binding), matchMetarecordCalls, {});
          (accRecDecls, rt_1) = elaborateRecordDeclarationsForMetarecords(expl, accRecDecls, rt_1);
        end if;
        (accRecDecls, rt_2) = elaborateRecordDeclarations(rest, accRecDecls, rt_1);
      then
        (accRecDecls, rt_2);

    case ((DAE.ALGORITHM(algorithm_ = algorithm_) :: rest), accRecDecls, rt)
      equation
        true = Config.acceptMetaModelicaGrammar();
        ((_, expl)) = DAEUtil.traverseAlgorithmExps(algorithm_, Expression.traverseSubexpressionsHelper, (matchMetarecordCalls, {}));
        (accRecDecls, rt_2) = elaborateRecordDeclarationsForMetarecords(expl, accRecDecls, rt);
        // TODO: ? what about rest ? , can be there something else after the ALGORITHM
        (accRecDecls, rt_2) = elaborateRecordDeclarations(rest, accRecDecls, rt_2);
      then
        (accRecDecls, rt_2);

    case ((_ :: rest), accRecDecls, rt)
      equation
        (accRecDecls, rt_1) = elaborateRecordDeclarations(rest, accRecDecls, rt);
      then
        (accRecDecls, rt_1);
  end matchcontinue;
end elaborateRecordDeclarations;

protected function matchMetarecordCalls "Used together with getMatchingExps"
  input DAE.Exp e;
  input list<DAE.Exp> acc;
  output DAE.Exp outExp;
  output list<DAE.Exp> outExps;
algorithm
  (outExp,outExps) := matchcontinue (e,acc)
    local
      Integer index;
    case (DAE.METARECORDCALL(index = index), _)
      equation
        outExps = List.consOnTrue(-1 <> index, e, acc);
      then (e, outExps);
    else (e,acc);
  end matchcontinue;
end matchMetarecordCalls;

protected function isVarQ
"Succeeds if inElement is a variable or constant that is not input."
  input DAE.Element inElement;
  output Boolean outB;
algorithm
  outB := match (inElement)
    local
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(kind=vk, direction=vd)
      guard
        isVarKindVarOrParameter(vk) and
        isDirectionNotInput(vd)
      then true;
    else false;
  end match;
end isVarQ;

protected function isVarNotInputNotOutput
"Succeeds if inElement is a variable or constant that is not input or output.
needed in kernel functions since they shouldn't have output vars."
  input DAE.Element inElement;
  output Boolean outB;
algorithm
  outB := match (inElement)
    local
      DAE.VarKind vk;
      DAE.VarDirection vd;
    case DAE.VAR(kind=vk, direction=vd)
      guard
        isVarKindVarOrParameter(vk) and
        isDirectionNotInputNotOutput(vd)
      then true;
    else false;
  end match;
end isVarNotInputNotOutput;

protected function isVarKindVarOrParameter
  input DAE.VarKind inVarKind;
  output Boolean outB;
algorithm
  outB := match (inVarKind)
    case DAE.VARIABLE() then true;
    case DAE.PARAM() then true;
    case DAE.CONST() then true;
    else false;
  end match;
end isVarKindVarOrParameter;

protected function isDirectionNotInput
  input DAE.VarDirection inVarDirection;
  output Boolean outB;
algorithm
  outB := match (inVarDirection)
    case DAE.OUTPUT() then true;
    case DAE.BIDIR() then true;
    else false;
  end match;
end isDirectionNotInput;

protected function isDirectionNotInputNotOutput
  input DAE.VarDirection inVarDirection;
  output Boolean outB;
algorithm
  outB := match (inVarDirection)
    case DAE.BIDIR() then true;
    else false;
  end match;
end isDirectionNotInputNotOutput;

protected function filterNg "Sets the number of zero crossings to zero if events are disabled."
  input Integer ng;
  output Integer outInteger;
algorithm
  outInteger := if useZerocrossing() then ng else 0;
end filterNg;

protected function useZerocrossing
  output Boolean res;
algorithm
  res := Flags.isSet(Flags.EVENTS);
end useZerocrossing;

protected function getCrefFromExp "Assume input Exp is CREF and return the ComponentRef, fail otherwise."
  input DAE.Exp e;
  output Absyn.ComponentRef c;
algorithm
  c := match (e)
    local
      DAE.ComponentRef crefe;
      Absyn.ComponentRef crefa;

    case(DAE.CREF(componentRef = crefe))
      equation
        crefa = ComponentReference.unelabCref(crefe);
      then
        crefa;

    else
      equation
        Error.addInternalError("function getCrefFromExp failed: input was not of type DAE.CREF", sourceInfo());
      then
        fail();
  end match;
end getCrefFromExp;

protected function elaborateRecordDeclarationsForRecord
"Helper function to generateStructsForRecords."
  input DAE.Type inRecordType;
  input list<SimCodeFunction.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) := match (inRecordType, inAccRecordDecls, inReturnTypes)
    local
      Absyn.Path path;
      list<DAE.Var> varlst;
      String name,sname;
      list<String> rt, rt_1, fieldNames;
      list<SimCodeFunction.RecordDeclaration> accRecDecls;
      list<SimCodeFunction.Variable> vars;
      Integer varnum;
      SimCodeFunction.RecordDeclaration recDecl;
      Boolean is_default;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path), varLst = varlst), accRecDecls, rt)
      algorithm
        name := AbsynUtil.pathStringUnquoteReplaceDot(path, "_");
        rt_1 := rt;

        (sname, is_default) := checkBindingsandGetConstructorName(name, varlst);
        // is_default := stringEqual(sname,name);

        if not listMember(sname, rt_1) then
          rt_1 := sname :: rt_1;

          if is_default then
            (accRecDecls, rt_1) := elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);

            vars := List.map(varlst, typesVar);
            recDecl := SimCodeFunction.RECORD_DECL_FULL(sname, NONE(), path, vars);
          else
            vars := List.map(varlst, typesVar);
            recDecl := SimCodeFunction.RECORD_DECL_ADD_CONSTRCTOR(sname, name, vars);
          end if;

          accRecDecls := List.appendElt(recDecl, accRecDecls);
        end if;

      then (accRecDecls, rt_1);

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)), accRecDecls, rt)
    then (accRecDecls, rt);

    case (DAE.T_METARECORD(path = Absyn.QUALIFIED(name="SourceInfo")), accRecDecls, rt)
      then (accRecDecls, rt);

    case (DAE.T_METARECORD(fields = varlst, path=path), accRecDecls, rt)
      equation
        sname = AbsynUtil.pathStringUnquoteReplaceDot(path, "_");
        if not listMember(sname, rt) then
          fieldNames = List.map(varlst, generateVarName);
          accRecDecls = SimCodeFunction.RECORD_DECL_DEF(path, fieldNames) :: accRecDecls;
          rt_1 = sname::rt;
          (accRecDecls, rt_1) = elaborateNestedRecordDeclarations(varlst, accRecDecls, rt_1);
        else
          rt_1 = rt;
        end if;
      then (accRecDecls, rt_1);

    case (_, accRecDecls, rt)
    then (accRecDecls, rt);

  end match;
end elaborateRecordDeclarationsForRecord;

protected function typesVarNoBinding
  input DAE.Var inTypesVar;
  output SimCodeFunction.Variable outVar;
algorithm
  outVar := match (inTypesVar)
    local
      String name;
      DAE.Type ty;
      DAE.ComponentRef cref_;
      DAE.Attributes attr;
      SCode.Parallelism scPrl;
      DAE.VarParallelism prl;

    case (DAE.TYPES_VAR(name=name, attributes = attr, ty=ty))
      equation
        ty = Types.simplifyType(ty);
        cref_ = ComponentReference.makeCrefIdent(name, ty, {});
        DAE.ATTR(parallelism = scPrl) = attr;
        prl = scodeParallelismToDAEParallelism(scPrl);
      then SimCodeFunction.VARIABLE(cref_, ty, NONE(), {}, prl,DAE.VARIABLE(), false);
  end match;
end typesVarNoBinding;

protected function typesVar
  input DAE.Var inTypesVar;
  output SimCodeFunction.Variable outVar;
algorithm
  outVar := match (inTypesVar)
    local
      String name;
      DAE.Type ty;
      DAE.ComponentRef cref_;
      DAE.Attributes attr;
      SCode.Parallelism scPrl;
      DAE.VarParallelism prl;
      Option<DAE.Exp> bindExp;

    case (DAE.TYPES_VAR(name=name, attributes = attr, ty=ty))
      equation
        ty = Types.simplifyType(ty);
        cref_ = ComponentReference.makeCrefIdent(name, ty, {});
        DAE.ATTR(parallelism = scPrl) = attr;
        prl = scodeParallelismToDAEParallelism(scPrl);
        bindExp = checkSourceAndGetBindingExp(inTypesVar.binding);
      then SimCodeFunction.VARIABLE(cref_, ty, bindExp, {}, prl, DAE.VARIABLE(), inTypesVar.bind_from_outside);
  end match;
end typesVar;

protected function checkBindingsandGetConstructorName
  input String rec_name;
  input list<DAE.Var> vars;
  output String ctor_name;
  output Boolean is_default;
protected
  Integer varnum;
algorithm
  is_default := true;

  ctor_name := rec_name;
  varnum := 1;

  for var in vars loop
    if var.bind_from_outside and not isBindingFromDerivedRecordDeclaration(var.binding) then
      is_default := false;
      ctor_name := ctor_name + "_" + intString(varnum);
    end if;

    varnum := intAdd(varnum,1);
  end for;
end checkBindingsandGetConstructorName;

protected function isBindingFromDerivedRecordDeclaration
  input DAE.Binding bind;
  output Boolean b;
algorithm
  b := match bind
    case DAE.EQBOUND(source=DAE.BINDING_FROM_DERIVED_RECORD_DECL())  then true;
    else false;
  end match;
end isBindingFromDerivedRecordDeclaration;

protected function checkSourceAndGetBindingExp
  input DAE.Binding inBinding;
  output Option<DAE.Exp> bindExp;
algorithm
  bindExp := match (inBinding)
    local
    case DAE.EQBOUND(source=DAE.BINDING_FROM_RECORD_SUBMODS()) then NONE();
    case DAE.EQBOUND() then SOME(inBinding.exp);
    else NONE();
  end match;
end checkSourceAndGetBindingExp;

protected function scodeParallelismToDAEParallelism
  input SCode.Parallelism inParallelism;
  output DAE.VarParallelism outParallelism;
algorithm
  outParallelism := match(inParallelism)
    case(SCode.PARGLOBAL())    then DAE.PARGLOBAL();
    case(SCode.PARLOCAL())     then DAE.PARLOCAL();
    case(SCode.NON_PARALLEL()) then DAE.NON_PARALLEL();
  end match;
end scodeParallelismToDAEParallelism;

protected function variableName
  input SimCodeFunction.Variable v;
  output String s;
algorithm
  s := match v
    case SimCodeFunction.VARIABLE(name=DAE.CREF_IDENT(ident=s)) then s;
    case SimCodeFunction.FUNCTION_PTR(name=s) then s;
  end match;
end variableName;

protected function compareVariable
  input SimCodeFunction.Variable v1;
  input SimCodeFunction.Variable v2;
  output Boolean b;
algorithm
  b := stringCompare(variableName(v1),variableName(v2)) > 0;
end compareVariable;

protected function generateVarName
  input DAE.Var inVar;
  output String outName;
algorithm
  outName :=
  match (inVar)
    local
      DAE.Ident name;
    case DAE.TYPES_VAR(name = name) then name;
    else "NULL";
  end match;
end generateVarName;

protected function elaborateNestedRecordDeclarations
"Helper function to elaborateRecordDeclarations."
  input list<DAE.Var> inRecordTypes;
  input list<SimCodeFunction.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) := matchcontinue (inRecordTypes, inAccRecordDecls, inReturnTypes)
    local
      DAE.Type ty;
      list<DAE.Var> rest;
      list<String> rt, rt_1, rt_2;
      list<SimCodeFunction.RecordDeclaration> accRecDecls;
    case ({}, accRecDecls, rt)
    then (accRecDecls, rt);
    case (DAE.TYPES_VAR(ty = ty as DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(_)))::rest, accRecDecls, rt)
      equation
        (accRecDecls, rt_1) = elaborateRecordDeclarationsForRecord(ty, accRecDecls, rt);
        (accRecDecls, rt_2) = elaborateNestedRecordDeclarations(rest, accRecDecls, rt_1);
      then (accRecDecls, rt_2);
    case (_::rest, accRecDecls, rt)
      equation
        (accRecDecls, rt_1) = elaborateNestedRecordDeclarations(rest, accRecDecls, rt);
      then (accRecDecls, rt_1);
  end matchcontinue;
end elaborateNestedRecordDeclarations;

protected function elaborateRecordDeclarationsForMetarecords
  input list<DAE.Exp> inExpl;
  input list<SimCodeFunction.RecordDeclaration> inAccRecordDecls;
  input list<String> inReturnTypes;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<String> outReturnTypes;
algorithm
  (outRecordDecls, outReturnTypes) := match (inExpl, inAccRecordDecls, inReturnTypes)
    local
      list<String> rt, rt_1, rt_2, fieldNames;
      list<DAE.Exp> rest;
      String name;
      Absyn.Path path;
      list<SimCodeFunction.RecordDeclaration> accRecDecls;
      Boolean b;

    case ({}, accRecDecls, rt) then (accRecDecls, rt);
    case (DAE.METARECORDCALL(path=path, fieldNames=fieldNames)::rest, accRecDecls, rt)
      equation
        name = AbsynUtil.pathStringUnquoteReplaceDot(path, "_");
        b = listMember(name, rt);
        accRecDecls = List.consOnTrue(not b, SimCodeFunction.RECORD_DECL_DEF(path, fieldNames), accRecDecls);
        rt_1 = List.consOnTrue(not b, name, rt);
        (accRecDecls, rt_2) = elaborateRecordDeclarationsForMetarecords(rest, accRecDecls, rt_1);
      then (accRecDecls, rt_2);
   case (_::rest, accRecDecls, rt)
     equation
       (accRecDecls, rt_1) = elaborateRecordDeclarationsForMetarecords(rest, accRecDecls, rt);
     then (accRecDecls, rt_1);
  end match;
end elaborateRecordDeclarationsForMetarecords;


protected function generateExtFunctionIncludes "by investigating the annotation of an external function."
  input Absyn.Program program;
  input Absyn.Path path;
  input Option<SCode.Annotation> inAbsynAnnotationOption;
  input SourceInfo info;
  output list<String> includes;
  output list<String> includeDirs;
  output list<String> libs;
  output list<String> paths;
  output Boolean dynamcLoad;
algorithm
  (includes, includeDirs, libs,paths, dynamcLoad):=
  match (program, path, inAbsynAnnotationOption)
    local
      SCode.Mod mod;
      Boolean b;
      String target;
      Option<String> odir, resources;
      list<String> libNames, fullLibNames, dirs;

    case (_, _, SOME(SCode.ANNOTATION(mod)))
      algorithm
        b := generateExtFunctionDynamicLoad(mod);
        target := Flags.getConfigString(Flags.TARGET);
        (libs, libNames) := generateExtFunctionIncludesLibstr(target,mod);
        includes := generateExtFunctionIncludesIncludestr(mod);
        (libs, dirs, resources) := generateExtFunctionLibraryDirectoryFlags(program, path, mod, libs);
        for name in if Flags.isSet(Flags.CHECK_EXT_LIBS) then libNames else {} loop
          if getGerneralTarget(target)=="msvc" or Autoconf.os=="Windows_NT" then
            fullLibNames := {name + Autoconf.dllExt, "lib" + name + ".a", "lib" + name + ".lib"};
          else
            fullLibNames := {"lib" + name + ".a", "lib" + name + Autoconf.dllExt};
          end if;
          lookForExtFunctionLibrary(fullLibNames, dirs, name, resources, path, info);
        end for;
        paths := generateExtFunctionLibraryDirectoryPaths(program, path, mod);
        includeDirs := generateExtFunctionIncludeDirectoryFlags(program, path, mod, includes);
      then
        (includes, includeDirs, libs,paths, b);
    case (_, _, NONE()) then ({}, {}, {},{}, false);
  end match;
end generateExtFunctionIncludes;

protected function lookForExtFunctionLibrary
  input list<String> names;
  input list<String> dirs;
  input String name;
  input Option<String> resources;
  input Absyn.Path path;
  input SourceInfo info;
protected
  list<String> dirs2;
algorithm
  dirs2 := Settings.getInstallationDirectoryPath() + "/lib/" + Autoconf.triple + "/omc"::"/usr/lib/"+Autoconf.triple::"/lib/"+Autoconf.triple::"/usr/lib/"::"/lib/"::dirs; // We could also try to look in ldconfig, etc for system libraries
  if not max(System.regularFileExists(d+"/"+n) for d in dirs2, n in names) then
    _ := match resources
      local
        String resourcesStr, tmpdir, cmd, pwd, contents, found;
        Integer status;
        Boolean didFind;
      case SOME(resourcesStr)
        algorithm
          if System.directoryExists(resourcesStr) then
            didFind := false;
            for dir in list(dir for dir guard System.regularFileExists(resourcesStr + "/BuildProjects/" + dir + "/autogen.sh") in System.subDirectories(resourcesStr + "/BuildProjects")) loop
              tmpdir := System.createTemporaryDirectory(Settings.getTempDirectoryPath() + "/omc_compile_" + name + "_");
              Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Created directory " + tmpdir}, info);
              cmd := "cp -a \"" + resourcesStr + "\"/* \"" + tmpdir + "\"";
              Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {cmd}, info);
              System.systemCall(cmd);
              pwd := System.pwd();
              if 0==System.cd(tmpdir + "/BuildProjects/" + dir) then
                Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Changed directory to " + System.pwd()}, info);
                // TODO: Add $(host)
                cmd := "sh ./autogen.sh && ./configure --libdir='"+userCompiledBinariesDirectory(path)+"' && make && make install";
                status := System.systemCall(cmd, "log");
                contents := System.readFile("log");
                if status <> 0 then
                  Error.addSourceMessage(Error.COMPILER_WARNING, {"Failed to run "+cmd+": " + contents}, info);
                else
                  Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Succeeded with compilation and installation of the library using:\ncommand: "+cmd+"\n" + contents}, info);
                  didFind := true;
                  for d in dirs2, n in names loop
                    if not System.regularFileExists(d+"/"+n) then
                      Error.addSourceMessage(Error.EXT_LIBRARY_NOT_FOUND_DESPITE_COMPILATION_SUCCESS, {n, cmd, System.pwd()}, info);
                      didFind := false;
                    end if;
                  end for;
                  if didFind then
                    found := listHead(list(x for x guard System.regularFileExists(x) in List.flatten(list(d+"/"+n for d in dirs2, n in names))));
                    Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Compiled "+found+" by running build project " + resourcesStr + "/BuildProjects/" + dir}, info);
                  end if;
                end if;
              else
                Error.addSourceMessage(Error.COMPILER_WARNING, {"Failed to change directory to " + tmpdir + "/BuildProjects/" + dir}, info);
              end if;
              System.cd(pwd);
              System.removeDirectory(tmpdir);
              Error.addSourceMessage(Error.COMPILER_NOTIFICATION, {"Removed directory " + tmpdir}, info);
              if didFind then
                break;
              end if;
            end for;
          end if;
        then ();
      else ();
    end match;
    if not max(System.regularFileExists(d+"/"+n) for d in dirs2, n in names) then
      // suppress this warning if we're running the testsuite
      if not Testsuite.isRunning() then
        Error.addSourceMessage(Error.EXT_LIBRARY_NOT_FOUND, {name, sum("\n  " + d + "/" + n for d in dirs2, n in names)}, info);
      end if;
    end if;
  end if;
end lookForExtFunctionLibrary;

protected function generateExtFunctionIncludeDirectoryFlags
  "Process LibraryDirectory and IncludeDirectory"
  input Absyn.Program program;
  input Absyn.Path path;
  input SCode.Mod inMod;
  input list<String> includes;
  output list<String> outDirs;
algorithm
  outDirs := matchcontinue (program, path, inMod, includes)
    local
      String str,istr;
    case (_, _, _, {}) then {};
    case (_, _, _, _)
      equation
        SCode.MOD(binding = SOME(Absyn.STRING(str))) =
          Mod.getUnelabedSubMod(inMod, "IncludeDirectory");
        str = CevalScript.getFullPathFromUri(program, str, false);
        istr = "\"-I"+str+"\"";
      then if System.directoryExists(str) then {istr} else {};
    case (_, _, _, _)
      equation
        str = "modelica://" + AbsynUtil.pathFirstIdent(path) + "/Resources/Include";
        str = CevalScript.getFullPathFromUri(program, str, false);
        istr = "\"-I"+str+"\"";
      then if System.directoryExists(str) then {istr} else {};
        // Read SourceInfo instead?
    else {};
  end matchcontinue;
end generateExtFunctionIncludeDirectoryFlags;

protected function getLinkerLibraryPaths"Builds search paths for the linker to find external libraries.
 Some libraries need special treatment.
 author: vwaurich TUD 2016-10"
  input String uri;
  input Absyn.Path path;
  input list<String> inLibs;
  output list<String> libPaths;
algorithm
  libPaths := matchcontinue(uri,path,inLibs)
    local
      String str, platform1, platform2;
  case(_, _,{"-lWinmm"}) guard Autoconf.os=="Windows_NT"
    //Winmm has to be linked from the windows system but not from the resource directories.
    //This is a fix for M_DD since otherwise the dummy pthread.dll that breaks the built will be linked
    then {(Settings.getInstallationDirectoryPath() + "/lib/" + Autoconf.triple + "/omc")};
  case(, _,_)
    equation
      platform1 = uri + "/" + System.openModelicaPlatform();
      platform2 = uri + "/" + System.modelicaPlatform();
    then uri::platform2::platform1::(Settings.getHomeDir(false)+"/.openmodelica/binaries/"+AbsynUtil.pathFirstIdent(path))::
      (Settings.getInstallationDirectoryPath() + "/lib/")::(Settings.getInstallationDirectoryPath() + "/lib/" + Autoconf.triple + "/omc")::{};
  end matchcontinue;
end getLinkerLibraryPaths;

protected function generateExtFunctionLibraryDirectoryFlags
  "Process LibraryDirectory and IncludeDirectory"
  input Absyn.Program program;
  input Absyn.Path path;
  input SCode.Mod inMod;
  input list<String> inLibs;
  output list<String> outLibs;
  output list<String> installDirs;
  output Option<String> resources;
algorithm
  (outLibs, installDirs, resources) := matchcontinue (program, path, inMod, inLibs)
    local
      String str, str1, str2, str3, target, dir, resourcesStr;
      list<String> libs, libs2;
      Boolean isLinux;
    case (_, _, _, {}) then ({}, {}, NONE());
    case (_, _, _, libs)
      algorithm
        str := matchcontinue inMod
          case _
            equation
              SCode.MOD(binding = SOME(Absyn.STRING(str))) = Mod.getUnelabedSubMod(inMod, "LibraryDirectory");
            then str;
          else "modelica://" + AbsynUtil.pathFirstIdent(path) + "/Resources/Library";
        end matchcontinue;
        str := CevalScript.getFullPathFromUri(program, str, false);
        resourcesStr := CevalScript.getFullPathFromUri(program, "modelica://" + AbsynUtil.pathFirstIdent(path) + "/Resources", false);
        isLinux := stringEq("linux",Autoconf.os);
        target := Flags.getConfigString(Flags.TARGET);
        // please, take care about ordering these libraries, the most specific should have the highest priority
        libs2 := getLinkerLibraryPaths(str, path, inLibs);
        libs := List.fold2(libs2, generateExtFunctionLibraryDirectoryFlags2, isLinux, target, libs);
      then (libs, listReverse(libs2), SOME(resourcesStr));
    else (inLibs, {}, NONE());
  end matchcontinue;
end generateExtFunctionLibraryDirectoryFlags;

protected function generateExtFunctionLibraryDirectoryFlags2
  input String dir;
  input Boolean isLinux;
  input String target;
  input list<String> inLibs;
  output list<String> libs;
algorithm
  libs := if isLinux then "-Wl,-rpath=\"" + dir + "\""::inLibs else inLibs;
  libs := (if getGerneralTarget(target)=="msvc" then "/LIBPATH:\"" + dir + "\"" else "\"-L" + dir + "\"")::libs;
end generateExtFunctionLibraryDirectoryFlags2;

protected function getGerneralTarget
   input String target;
  output String generalTarget;
algorithm
  generalTarget := if (System.stringFind(target, "msvc") == 0) then "msvc" else target;
end getGerneralTarget;


protected function userCompiledBinariesDirectory
  input Absyn.Path path;
  output String str = Settings.getHomeDir(false)+"/.openmodelica/binaries/"+AbsynUtil.pathFirstIdent(path);
end userCompiledBinariesDirectory;

protected function generateExtFunctionLibraryDirectoryPaths
  "Process LibraryDirectory and IncludeDirectory"
  input Absyn.Program program;
  input Absyn.Path path;
  input SCode.Mod inMod;
  output list<String> outLibs;
algorithm
  outLibs := matchcontinue (program, path, inMod)
    local
      String str, str1, str2, str3, platform1, platform2,target;
      list<String> libs;
      Boolean isLinux;
    case (_, _, _)
      equation
        SCode.MOD(binding = SOME(Absyn.STRING(str))) =
          Mod.getUnelabedSubMod(inMod, "LibraryDirectory");
        str = CevalScript.getFullPathFromUri(program, str, false);
        platform1 = System.openModelicaPlatform();
        platform2 = System.modelicaPlatform();
        isLinux = stringEq("linux",Autoconf.os);
        // please, take care about ordering these libraries, the most specific should go first (in reverse here)
        libs = generateExtFunctionLibraryDirectoryPaths2(true, str, isLinux, {} );
        libs = generateExtFunctionLibraryDirectoryPaths2(not stringEq(platform2,""), str + "/" + platform2, isLinux, libs);
        libs = generateExtFunctionLibraryDirectoryPaths2(not stringEq(platform1,""), str + "/" + platform1, isLinux, libs);
      then libs;
    case (_, _, _)
      equation
        str = "modelica://" + AbsynUtil.pathFirstIdent(path) + "/Resources/Library";
        str = CevalScript.getFullPathFromUri(program, str, false);
        platform1 = System.openModelicaPlatform();
        platform2 = System.modelicaPlatform();
        isLinux = stringEq("linux",Autoconf.os);
        // please, take care about ordering these libraries, the most specific should go first (in reverse here)
        libs = generateExtFunctionLibraryDirectoryPaths2(true, str, isLinux, {} );
        libs = generateExtFunctionLibraryDirectoryPaths2(not stringEq(platform2,""), str + "/" + platform2, isLinux, libs);
        libs = generateExtFunctionLibraryDirectoryPaths2(not stringEq(platform1,""), str + "/" + platform1, isLinux, libs);
      then libs;
    else {};
  end matchcontinue;
end generateExtFunctionLibraryDirectoryPaths;


protected function generateExtFunctionLibraryDirectoryPaths2
  input Boolean add;
  input String dir;
  input Boolean isLinux;
  input list<String> inLibs;
  output list<String> libs;
algorithm
  libs := match (add,dir,isLinux,inLibs)
    local
      Boolean b;
    case (true,_,_,libs)
      equation
        b = System.directoryExists(dir);
        libs = List.consOnTrue(b, dir , libs);
       then libs;
   else inLibs;
  end match;
end generateExtFunctionLibraryDirectoryPaths2;


protected function getLibraryStringInMSVCFormat
"Takes an Absyn.STRING describing a library and outputs a list
of strings corresponding to it.
Note: Normally only outputs a single string, but Lapack on MinGW is special."
  input Absyn.Exp exp;
  output list<String> strs;
  output list<String> names;
algorithm
  (strs,names) := matchcontinue exp
    local
      String str;

    // seems lapack can show on Lapack form or lapack (different case) (MLS revision 6155)
    // Lapack on MinGW/Windows is linked against f2c
    case Absyn.STRING(str) guard str=="Lapack" or str=="lapack"
      then ({"lapack_win32_MT.lib", "f2c.lib"}, {});

    // omcruntime on windows needs linking with mico2313 and wsock and then some :)
    case Absyn.STRING("omcruntime")
      equation
        true = "Windows_NT" == Autoconf.os;
        strs = {"f2c.lib", "initialization.lib", "libexpat.lib", "math-support.lib", "meta.lib", "ModelicaExternalC.lib", "results.lib", "simulation.lib", "solver.lib", "sundials_kinsol.lib", "sundials_nvecserial.lib", "util.lib", "lapack_win32_MT.lib"};
      then
        (strs, {});

    // Wonder if there may be issues if we have duplicates in the Corba libs
    // and the other libs. Some other developer will probably swear over this
    // hack some day, but at least I get an early weekend.
    case Absyn.STRING("OpenModelicaCorba")
      equation
        str = Autoconf.corbaLibs;
      then ({str},{});

    case Absyn.STRING("fmilib")
      then ({"fmilib.lib","shlwapi.lib"},{});

    // If the string starts with a -, it's probably -l or -L gcc flags
    case Absyn.STRING(str)
      equation
        true = "-" == stringGetStringChar(str, 1);
      then ({str},{});

    case Absyn.STRING(str)
      equation
        str = str + ".lib";
      then ({str},{});

    else
      equation
        Error.addInternalError("Failed to process Library annotation for external function", sourceInfo());
      then fail();
  end matchcontinue;
end getLibraryStringInMSVCFormat;

protected function getLibraryStringInGccFormat
"Takes an Absyn.STRING describing a library and outputs a list
of strings corresponding to it.
Note: Normally only outputs a single string, but Lapack on MinGW is special."
  input Absyn.Exp exp;
  output list<String> strs;
  output list<String> names;
algorithm
  (strs,names) := matchcontinue exp
    local
      String str, fopenmp;
      list<String> strs1, strs2, strs3, names1, names2, names3;

    // Lapack is always included
    case Absyn.STRING("lapack") then ({},{});
    case Absyn.STRING("Lapack") then ({},{});

    //pthreads is already linked under windows
    case Absyn.STRING("pthread") guard Autoconf.os=="Windows_NT"
      equation
        Error.addCompilerNotification("pthreads library is already available. It is not linked from the external library resource directory.\n");
      then  ({},{});

   //do not link rt.dll for Modelica Device Drivers as it is not needed under windows
    case Absyn.STRING("rt") guard Autoconf.os=="Windows_NT"
      equation
        Error.addCompilerNotification("rt library is not needed under Windows. It is not linked from the external library resource directory.\n");
      then  ({},{});

   //do not link Ws2_32.dll for Modelica Device Drivers as it is not needed under windows
    case Absyn.STRING("Ws2_32") guard Autoconf.os=="Windows_NT"
      equation
        Error.addCompilerNotification("Ws2_32 library is not needed under Windows. It is not linked from the external library resource directory.\n");
      then  ({},{});

    //user32 is already linked under windows
    case Absyn.STRING("User32") guard Autoconf.os=="Windows_NT"
      equation
        Error.addCompilerNotification("User32 library is already available. It is not linked from the external library resource directory.\n");
      then  ({},{});

    //winmm is a windows system lib
    case Absyn.STRING(str as "Winmm") guard Autoconf.os=="Windows_NT"
      equation
        str = "-l" + str;
        Error.addCompilerNotification("Winmm library is a windows system library. It is not linked from the external library resource directory.\n");
      then  ({str},{});

    //do not link X11.dll for Modelica Device Drivers as it is not needed under windows
    case Absyn.STRING("X11") guard Autoconf.os=="Windows_NT"
      equation
        Error.addCompilerNotification("X11 library is not needed under Windows. It is not linked from the external library resource directory.\n");
      then  ({},{});

    case Absyn.STRING(str as "omcruntime")
      equation
        if "Windows_NT" == Autoconf.os then
          // omcruntime on windows needs linking with mico2313 and wsock and then some :)
          str = "-l" + str;
          strs = str :: "-lintl" :: "-liconv" :: "-lexpat" :: "-lsqlite3" :: "-llpsolve55" :: "-ltre" :: "-lomniORB420_rt" :: "-lomnithread40_rt" :: "-lws2_32" :: "-lRpcrt4" :: "-lregex" :: {};
        else
          strs = Autoconf.systemLibs;
        end if;
      then  (strs,{});

    // Wonder if there may be issues if we have duplicates in the Corba libs
    // and the other libs. Some other developer will probably swear over this
    // hack some day, but at least I get an early weekend.
    case Absyn.STRING("OpenModelicaCorba")
      equation
        str = Autoconf.corbaLibs;
      then ({str},{});

    case Absyn.STRING("fmilib")
      then (if Autoconf.os=="Windows_NT" then {"-lfmilib","-lshlwapi"} else {"-lfmilib"},{});

    case Absyn.STRING(str)
      algorithm
        if str=="ModelicaStandardTables" then
          // MSL 3.2.1 did not have the updated annotations...
          (strs1,names1) := getLibraryStringInGccFormat(Absyn.STRING("ModelicaIO"));
          (strs2,names2) := getLibraryStringInGccFormat(Absyn.STRING("ModelicaMatIO"));
          (strs3,names3) := getLibraryStringInGccFormat(Absyn.STRING("zlib"));
          strs := listAppend(strs1, listAppend(strs2, strs3));
          names := listAppend(names1, listAppend(names2, names3));
        else
          strs := {};
          names := {};
        end if;
        // If the string is a file, return it as it is
        // If the string starts with a -, it's probably -l or -L gcc flags
        if System.regularFileExists(str) or "-" == stringGetStringChar(str, 1) then
          strs := str::strs;
        else
          strs := ("-l" + str)::strs;
          names := str::names;
        end if;

      then (strs,names);

    else
      equation
        Error.addInternalError("Failed to process Library annotation for external function", sourceInfo());
      then fail();
  end matchcontinue;
end getLibraryStringInGccFormat;

protected function generateExtFunctionIncludesLibstr
  input String target;
  input SCode.Mod inMod;
  output list<String> outStringLst;
  output list<String> names;
algorithm
  (outStringLst, names) := matchcontinue (getGerneralTarget(target),inMod)
    local
      list<Absyn.Exp> arr;
      list<String> libs;
      list<list<String>> libsList, namesList;
      Absyn.Exp exp;
    case ("msvc",_)
      equation
        SCode.MOD(binding = SOME(Absyn.ARRAY(arr))) =
          Mod.getUnelabedSubMod(inMod, "Library");
        (libsList, namesList) = List.map_2(arr, getLibraryStringInMSVCFormat);
      then
        (List.flatten(libsList), List.flatten(namesList));
    case ("msvc",_)
      equation
        SCode.MOD(binding = SOME(exp)) =
          Mod.getUnelabedSubMod(inMod, "Library");
        (libs,names) = getLibraryStringInMSVCFormat(exp);
      then
        (libs,names);
    case (_,_)
      equation
        SCode.MOD(binding = SOME(Absyn.ARRAY(arr))) =
          Mod.getUnelabedSubMod(inMod, "Library");
        (libsList, namesList) = List.map_2(arr, getLibraryStringInGccFormat);
      then
        (List.flatten(libsList), List.flatten(namesList));
    case (_,_)
      equation
        SCode.MOD(binding = SOME(exp)) =
          Mod.getUnelabedSubMod(inMod, "Library");
        (libs,names) = getLibraryStringInGccFormat(exp);
      then
        (libs,names);
    else ({},{});
  end matchcontinue;
end generateExtFunctionIncludesLibstr;

protected function generateExtFunctionIncludesIncludestr
  input SCode.Mod inMod;
  output list<String> includes;
algorithm
  includes := matchcontinue (inMod)
    local
      String inc, inc_1;
      Integer lineNumberStart;
      String str,fileName;
    case (_)
      equation
        SCode.MOD(binding = SOME(Absyn.STRING(inc)), info = SOURCEINFO(fileName=fileName,lineNumberStart=lineNumberStart)) =
          Mod.getUnelabedSubMod(inMod, "Include");
        str = "#line "+intString(lineNumberStart)+" \""+fileName+"\"";
        inc_1 = System.unescapedString(inc);
        includes = if Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then {str,inc_1} else {inc_1};
      then includes;
    else {};
  end matchcontinue;
end generateExtFunctionIncludesIncludestr;

protected function generateExtFunctionDynamicLoad
  input SCode.Mod inMod;
  output Boolean outDynamicLoad;
algorithm
  outDynamicLoad:= matchcontinue (inMod)
    local
      Boolean b;
    case (_)
      equation
        SCode.MOD(binding = SOME((Absyn.BOOL(b)))) =
          Mod.getUnelabedSubMod(inMod, "DynamicLoad");
      then
        b;
    else false;
  end matchcontinue;
end generateExtFunctionDynamicLoad;

public function getImplicitRecordConstructors
  "If a record instance is sent to a function we need to generate code for the
  record constructor even if it's not explicitly called, because the constructor
  is used by the generated code. This function checks the arguments of a
  function for these implicit record constructor calls and returns a list of all
  record constructors that are used."
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue(inExpLst)
    local
      DAE.ComponentRef cref;
      DAE.Type record_type;
      Absyn.Path record_path;
      list<DAE.Exp> rest_expr;
      DAE.Exp record_cref;
    case ({}) then {};
      // A record component reference.
    case (DAE.CREF(
      componentRef = cref,
      ty = (DAE.T_COMPLEX(
        complexClassType = ClassInf.RECORD(path = record_path)))) :: rest_expr)
      equation
        // Make sure it has no subscripts, i.e. it's a component reference for
        // an entire record instance.
        {} = ComponentReference.crefLastSubs(cref);
        // Build a DAE.CREF from the record path.
        cref = ComponentReference.pathToCref(record_path);
        record_cref = Expression.crefExp(cref);
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then record_cref :: rest_expr;
    case (_ :: rest_expr)
      equation
        rest_expr = getImplicitRecordConstructors(rest_expr);
      then rest_expr;
  end matchcontinue;
end getImplicitRecordConstructors;

protected function getCalledFunctionsInFunctions "Goes through the given DAE, finds the given functions and collects
  the names of the functions called from within those functions"
  input list<Absyn.Path> paths;
  input HashTableStringToPath.HashTable inHt;
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (paths, inHt, funcs)
    local
      list<Absyn.Path> rest;
      Absyn.Path path;
      HashTableStringToPath.HashTable ht;

    case ({}, ht, _) then ht;
    case (path::rest, ht, _)
      equation
        ht = getCalledFunctionsInFunction2(path, AbsynUtil.pathStringNoQual(path), ht, funcs);
        ht = getCalledFunctionsInFunctions(rest, ht, funcs);
      then ht;
  end match;
end getCalledFunctionsInFunctions;

public function getCalledFunctionsInFunction2 "Goes through the given DAE, finds the given function and collects
  the names of the functions called from within those functions"
  input Absyn.Path inPath;
  input String pathstr;
  input HashTableStringToPath.HashTable inHt "paths to not add";
  input DAE.FunctionTree funcs;
  output HashTableStringToPath.HashTable outHt "paths to not add";
algorithm
  outHt := matchcontinue (inPath, pathstr, inHt, funcs)
    local
      String str;
      Absyn.Path path;
      DAE.Function funcelem;
      list<Absyn.Path> calledfuncs, varfuncs;
      list<DAE.Element> els;
      HashTableStringToPath.HashTable ht;

    case (_, _, ht, _)
      guard BaseHashTable.hasKey(pathstr, ht)
      then ht;

    case (path, _, ht, _)
      equation
        funcelem = DAEUtil.getNamedFunction(path, funcs);
        els = DAEUtil.getFunctionElements(funcelem);
        // SimCodeFunction.Function reference variables are filtered out
        varfuncs = List.fold(els, DAEUtil.collectFunctionRefVarPaths, {});
        (_, (_, varfuncs)) = DAEUtil.traverseDAEElementList(els, Expression.traverseSubexpressionsHelper, (DAEUtil.collectValueblockFunctionRefVars, varfuncs));
        (_, (_, (calledfuncs, _))) = DAEUtil.traverseDAEElementList(els, Expression.traverseSubexpressionsHelper, (matchNonBuiltinCallsAndFnRefPaths, ({}, varfuncs)));
        ht = BaseHashTable.add((pathstr, path), ht);
        ht = addDestructor(funcelem, ht);
        ht = getCalledFunctionsInFunctions(calledfuncs, ht, funcs);
      then ht;

    case (path, _, _, _)
      equation
        failure(_ = DAEUtil.getNamedFunction(path, funcs));
        str = "function getCalledFunctionsInFunction2: Class " + pathstr + " not found in global scope.";
        Error.addInternalError(str, sourceInfo());
      then
        fail();
  end matchcontinue;
end getCalledFunctionsInFunction2;

protected function addDestructor
  input DAE.Function func;
  input HashTableStringToPath.HashTable inHt;
  output HashTableStringToPath.HashTable outHt;
algorithm
  outHt := match (func,inHt)
    local
      Absyn.Path path;
      String pathstr;
    case (DAE.FUNCTION(type_=DAE.T_FUNCTION(funcResultType=DAE.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(path=path)))),_)
      equation
        path = AbsynUtil.joinPaths(path,Absyn.IDENT("destructor"));
      then addDestructor2(path,AbsynUtil.pathStringNoQual(path),inHt);
    else inHt;
  end match;
end addDestructor;

protected function addDestructor2
  input Absyn.Path path;
  input String pathstr;
  input HashTableStringToPath.HashTable inHt;
  output HashTableStringToPath.HashTable ht = inHt;
algorithm
  if not BaseHashTable.hasKey(pathstr, ht) then
    BaseHashTable.add((pathstr, path), ht);
  end if;
end addDestructor2;

protected function matchNonBuiltinCallsAndFnRefPaths "The extra argument is a tuple<list, list>; the second list is the list of variable
  names to filter out (so we don't add function references variables)"
  input DAE.Exp inExp;
  input tuple<list<Absyn.Path>, list<Absyn.Path>> itpl;
  output DAE.Exp outExp;
  output tuple<list<Absyn.Path>, list<Absyn.Path>> otpl;
algorithm
  (outExp,otpl) := matchcontinue (inExp,itpl)
    local
      Absyn.Path path;
      list<Absyn.Path> acc, filter;
    case (DAE.CALL(path = path, attr = DAE.CALL_ATTR(builtin = false)), (acc, filter))
      equation
        path = AbsynUtil.makeNotFullyQualified(path);
        false = List.isMemberOnTrue(path, filter, AbsynUtil.pathEqual);
      then (inExp, (path::acc, filter));
    case (DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path)), (acc, filter))
      equation
        false = List.isMemberOnTrue(path, {Absyn.IDENT("list"),Absyn.IDENT("listReverse"),Absyn.IDENT("array"),Absyn.IDENT("min"),Absyn.IDENT("max"),Absyn.IDENT("sum"),Absyn.IDENT("product")}, AbsynUtil.pathEqual);
        false = List.isMemberOnTrue(path, filter, AbsynUtil.pathEqual);
      then (inExp, (path::acc, filter));
    case (DAE.PARTEVALFUNCTION(path = path), (acc, filter))
      equation
        path = AbsynUtil.makeNotFullyQualified(path);
        false = List.isMemberOnTrue(path, filter, AbsynUtil.pathEqual);
      then (inExp, (path::acc, filter));
    case (DAE.CREF(ty = DAE.T_FUNCTION_REFERENCE_FUNC(builtin = false)), (acc, filter))
      equation
        path = AbsynUtil.crefToPath(getCrefFromExp(inExp));
        false = List.isMemberOnTrue(path, filter, AbsynUtil.pathEqual);
      then (inExp, (path::acc, filter));
    else (inExp,itpl);
  end matchcontinue;
end matchNonBuiltinCallsAndFnRefPaths;

protected function aliasRecordDeclarations
  input SimCodeFunction.RecordDeclaration inDecl;
  input HashTableStringToPath.HashTable inHt;
  output SimCodeFunction.RecordDeclaration decl;
  output HashTableStringToPath.HashTable ht;
algorithm
  (decl,ht) := match (inDecl,inHt)
    local
      list<SimCodeFunction.Variable> vars;
      Absyn.Path name;
      String str,sname;
      Option<String> alias;
    case (SimCodeFunction.RECORD_DECL_FULL(sname, _, name, vars),_)
      equation
        str = stringDelimitList(List.map(vars, variableString), "\n");
        (alias,ht) = aliasRecordDeclarations2(str, name, inHt);
      then (SimCodeFunction.RECORD_DECL_FULL(sname, alias, name, vars),ht);
    else (inDecl,inHt);
  end match;
end aliasRecordDeclarations;

protected function aliasRecordDeclarations2
  input String str;
  input Absyn.Path path;
  input HashTableStringToPath.HashTable inHt;
  output Option<String> alias;
  output HashTableStringToPath.HashTable ht;
algorithm
  (alias,ht) := matchcontinue (str,path,inHt)
    local
      String aliasStr;
    case (_,_,_)
      equation
        aliasStr = AbsynUtil.pathStringUnquoteReplaceDot(BaseHashTable.get(str, inHt),"_");
      then (SOME(aliasStr),inHt);
    else
      equation
        ht = BaseHashTable.add((str,path),inHt);
      then (NONE(),ht);
  end matchcontinue;
end aliasRecordDeclarations2;

protected function variableString
  input SimCodeFunction.Variable var;
  output String str;
algorithm
  str := match var
    local
      DAE.ComponentRef name;
      DAE.Type ty;
    case SimCodeFunction.VARIABLE(name=name, ty=ty)
      then Types.unparseType(ty) + " " + ComponentReference.printComponentRefStr(name);
    case SimCodeFunction.FUNCTION_PTR(name=str)
      then "modelica_fnptr " + str;
  end match;
end variableString;

public function createMakefileParams
  input list<String> includes;
  input list<String> libs;
  input list<String> libPaths;
  input Boolean isFunction;
  input Boolean isFMU=false;
  output SimCodeFunction.MakefileParams makefileParams;
protected
  String omhome, ccompiler, cxxcompiler, linker, exeext, dllext, cflags, ldflags, rtlibs, platform, fopenmp,compileDir;
algorithm
  ccompiler   := if stringEq(Config.simCodeTarget(),"JavaScript") then "emcc" else
                 (if Flags.isSet(Flags.HPCOM) then System.getOMPCCompiler() else System.getCCompiler());
  cxxcompiler := if stringEq(Config.simCodeTarget(),"JavaScript") then "emcc" else System.getCXXCompiler();
  linker := if stringEq(Config.simCodeTarget(),"JavaScript") then "emcc" else System.getLinker();
  exeext := if stringEq(Config.simCodeTarget(),"JavaScript") then ".js" else Autoconf.exeExt;
  dllext := Autoconf.dllExt;
  omhome := Settings.getInstallationDirectoryPath();
  omhome := System.trim(omhome, "\""); // Remove any quotation marks from omhome.
  cflags := System.getCFlags() + " " +
            (if Flags.isSet(Flags.HPCOM) then "-fopenmp" else "");
  cflags := if stringEq(Config.simCodeTarget(),"JavaScript") then "-Os -Wno-warn-absolute-paths" else cflags;
  ldflags := System.getLDFlags();
  if Flags.getConfigBool(Flags.PARMODAUTO) then
    ldflags := "-lParModelicaAuto -ltbb_static " + ldflags;
  end if;
  rtlibs := if isFunction then Autoconf.ldflags_runtime else (if isFMU then Autoconf.ldflags_runtime_fmu else Autoconf.ldflags_runtime_sim);
  platform := System.modelicaPlatform();
  compileDir :=  System.pwd() + Autoconf.pathDelimiter;
  makefileParams := SimCodeFunction.MAKEFILE_PARAMS(ccompiler, cxxcompiler, linker, exeext, dllext,
        omhome, cflags, ldflags, rtlibs, includes, libs,libPaths, platform,compileDir);
end createMakefileParams;

public

function codegenResetTryThrowIndex
algorithm
  setGlobalRoot(Global.codegenTryThrowIndex, {});
end codegenResetTryThrowIndex;

function codegenPushTryThrowIndex
  input Integer i;
protected
  list<Integer> lst;
algorithm
  lst := getGlobalRoot(Global.codegenTryThrowIndex);
  setGlobalRoot(Global.codegenTryThrowIndex, i::lst);
end codegenPushTryThrowIndex;

function codegenPopTryThrowIndex
protected
  list<Integer> lst;
algorithm
  lst := getGlobalRoot(Global.codegenTryThrowIndex);
  _::lst := lst;
  setGlobalRoot(Global.codegenTryThrowIndex, lst);
end codegenPopTryThrowIndex;

function codegenPeekTryThrowIndex
  output Integer i;
protected
  list<Integer> lst;
algorithm
  lst := getGlobalRoot(Global.codegenTryThrowIndex);
  i := match lst
    case i::_ then i;
    else -1;
  end match;
end codegenPeekTryThrowIndex;

public function varIndex
  input SimCodeVar.SimVar var;
  output Integer index;
algorithm
  SimCodeVar.SIMVAR(index=index) := var;
end varIndex;

public function varName
  input SimCodeVar.SimVar var;
  output DAE.ComponentRef name;
algorithm
  SimCodeVar.SIMVAR(name=name) := var;
end varName;

public function isParallelFunctionContext
  input SimCodeFunction.Context context;
  output Boolean outBool;
algorithm
  outBool := match(context)
    case SimCodeFunction.FUNCTION_CONTEXT() then context.is_parallel;
    else false;
  end match;
end isParallelFunctionContext;

function twodigit
  input Integer i;
  output String outS;
algorithm
  outS :=
  matchcontinue (i)
    local String s;
    case _
      equation
        (i < 10) = true;
        s = intString(i);
        s = stringAppend("0", s);
      then
        s;
    else intString(i);
  end matchcontinue;
end twodigit;

public function generateSubPalceholders
  input DAE.ComponentRef cr;
  output String outdef;
protected
  list<DAE.Dimension> dims;
  Integer nrdims;
  list<String> idxstrlst;
algorithm
  dims := ComponentReference.crefDims(cr);
  nrdims := listLength(dims);
  idxstrlst := List.map(List.intRange(nrdims),intString);
  outdef := stringDelimitList(List.threadMap(List.fill("i_", nrdims), idxstrlst, stringAppend), ",");
end generateSubPalceholders;


/* This functions are used to get/append cref prefixes in function contexts.The cref prefix is appended
  to all crefs generated. We use this to generate dependent names in some cases (for example when generating
  code for record constructors) so that every cref we generate while this is set has this prefix applied to it*/
public function getCurrentCrefPrefix
  input SimCodeFunction.Context context;
  output String cref_pref;
algorithm
  cref_pref := match context
    case SimCodeFunction.FUNCTION_CONTEXT(cref_pref, _) then cref_pref;
    else algorithm Error.addInternalError("Tried to get cref prefix from a non FUNCTION_CONTEXT() context. cref_pref is only avaiable in FUNCTION_CONTEXT.", sourceInfo()); then fail();
  end match;
end getCurrentCrefPrefix;

public function appendCurrentCrefPrefix
  input SimCodeFunction.Context context;
  input String in_cref_pref;
  output SimCodeFunction.Context out_context;
protected
  String cref_pref;
  Boolean prl;
algorithm
  out_context := match context
    case SimCodeFunction.FUNCTION_CONTEXT(cref_pref, prl) then SimCodeFunction.FUNCTION_CONTEXT(cref_pref + in_cref_pref, prl);
    else algorithm Error.addInternalError("Tried to append cref prefix from a non FUNCTION_CONTEXT() context. cref_pref is only avaiable in FUNCTION_CONTEXT.", sourceInfo()); then fail();
  end match;
end appendCurrentCrefPrefix;


annotation(__OpenModelica_Interface="backendInterface");
end SimCodeFunctionUtil;
