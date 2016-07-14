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

// =============================================================================
// For any request about the implementation of this package,
// please contact Filippo Donida (donida@elet.polimi.it).
// =============================================================================


// =============================================================================
// Important discrete states are not recognised as states.
// The varKind shoud be varVariability and another method
// and also the relative structure for the variable should
// be implemented to output the information like: state,
// dummy der, dummy state,...
// =============================================================================


// =============================================================================
// With a delaration like:
// parameter Real a = 1;
// the bindValue Optional value of the BackendDAE.VAR
// record is everytime empty.  Why?
// =============================================================================


// =============================================================================
// In order to compile the XMLDump module (XMLDump.mo package)
// XMLDump.mo text in the Compiler/Makefile.common file (SRCMO
// variable) has been added.
// =============================================================================


// =============================================================================
// Probably it's better to put a link to the corresponging
// algorithm/variable/when/zeroCross/...
// One solution could be to add an attribute like: Algorithm_Number
// to the algorith tab, like:
// <ALGORITHM LABEL=algorithm_Number>
// and then when dumping the algorithm reference in this function put
// the corresponding tag:
// <ANCHOR id=algorithm_Number/>
// within the equation element.
// =============================================================================

encapsulated package XMLDump
" file:        XMLDump.mo
  package:     XMLDump
  description: Dumping of DAE as XML"


public import Absyn;
public import BackendDAE;
public import DAE;
public import Values;
public import SCode;

protected import Array;
protected import BackendDAEUtil;
protected import BackendVariable;
protected import BackendDAETransform;
protected import BackendEquation;
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import ElementSource;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import Print;
protected import Util;
protected import Types;
protected import DAEDump;
protected import ValuesUtil;
protected import ClassInf;
protected import System;        // for stringReplace
import ZeroCrossings;


  protected constant String HEADER        = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  protected constant String DAE_OPEN      = "dae xmlns:p1=\"http://www.w3.org/1998/Math/MathML\"
                                                xmlns:xlink=\"http://www.w3.org/1999/xlink\"
                                                xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                                                xsi:noNamespaceSchemaLocation=\"http://home.dei.polimi.it/donida/Projects/AutoEdit/Images/DAE.xsd\"";
  protected constant String DAE_CLOSE      = "dae";

  protected constant String LABEL          = "label";
  protected constant String ANCHOR         = "anchor";
  protected constant String ALGORITHM_NAME = "algorithmName";

  /*
  This String is used in:
    1 - dunmAbsynPathList - function to print a list of paths:
        <ELEMENT>
          Content
        </ELEMENT>
        <ELEMENT>
          ...
    2 - dumpCrefIdxLst to print a list of BackendDAE.CrefIndex:
        <ELEMENT ID=...>CrefIndex</ELEMENT>
        ...
    3 - dumpStrLst to print a list of String
        <ELEMENT>FirstStringOfList</ELEMENT>
        ...
        <ELEMENT>LastStringOfList</ELEMENT>
  */
  protected constant String ELEMENT  = "element";
  protected constant String ELEMENT_ = "Element";


  protected constant String INDEX = "index";
  protected constant String INTERVAL = "interval";
  protected constant String START = "start";
  protected constant String VALUE = "value";


  protected constant String LIST_ = "List";

  //Is the Dimension attribute of a list element.
  protected constant String DIMENSION              = "dimension";
  //Is the reference attribute for an element.
  protected constant String ID                     = "id";
  protected constant String ID_                    = "Id";
  protected constant String CONDITION              = "Condition";

  protected constant String REINIT                 = "reinit";
  protected constant String ASSERT                 = "assert";
  protected constant String TERMINATE              = "terminate";

  //This is the String attribute for the textual representation of the expressions.
  protected constant String EXP_STRING               = "string";

  //This constant is used when is necessary to bind equations, variables, whenequations,..
  protected constant String INVOLVED = "involved";

  protected constant String ADDITIONAL_INFO = "additionalInfo";
  protected constant String SOLVING_INFO    = "solvingInfo";

  //This is the name that identifies the Variables' block. It's also used to compose the other
  //Variables' names, such as KnownVariables, OrderedVariables, and so on.
  protected constant String VARIABLES  = "variables";
  protected constant String VARIABLES_ = "Variables";

  protected constant String ORDERED  = "ordered";
  protected constant String KNOWN    = "known";
  protected constant String EXTERNAL = "external";
  protected constant String ALIAS = "alias";
  protected constant String CLASSES  = "classes";
  protected constant String CLASSES_ = "Classes";

  protected constant String CLASS   = "class";
  protected constant String CLASS_  = "Class";
  protected constant String NAMES_  = "Names";

  //This is used all the time a variable is referenced.
  protected constant String VARIABLE = "variable";

  protected constant String VAR_ID       = ID;
  protected constant String VAR_NAME     = "name";
  protected constant String VAR_INDEX    = "differentiatedIndex";
  protected constant String VAR_DERNAME    = "derivativeName";
  protected constant String VAR_ORIGNAME = "origName";

  protected constant String STATE_SELECT_NEVER   = "Never";
  protected constant String STATE_SELECT_AVOID   = "Avoid";
  protected constant String STATE_SELECT_DEFAULT = "Default";
  protected constant String STATE_SELECT_PREFER  = "Prefer";
  protected constant String STATE_SELECT_ALWAYS  = "Always";

  protected constant String VAR_FLOW              = "flow";
  protected constant String VAR_FLOW_FLOW         = "Flow";
  protected constant String VAR_FLOW_NONFLOW      = "NonFlow";
  protected constant String VAR_FLOW_NONCONNECTOR = "NonConnector";

  protected constant String VAR_STREAM                     = "stream";
  protected constant String VAR_STREAM_STREAM              = "Stream";
  protected constant String VAR_STREAM_NONSTREAM           = "NonStream";
  protected constant String VAR_STREAM_NONSTREAM_CONNECTOR = "NonStreamConnector";

  ///  TO CORRECT WITHIN THE OMC!!!  ///
  // The variability is related to the
  // possible values a variable can assume
  // In this case also information for the
  // variable are stored. For example it would be useful
  // to print the information about state, dummyState, dummyDer separately.

  //In addition to this there's a problem with the discrete states,
  //since they aren't recognised as states.
  protected constant String VAR_VARIABILITY = "variability";

  protected constant String VARIABILITY_CONTINUOUS            = "continuous";
  protected constant String VARIABILITY_CONTINUOUS_STATE      = "continuousState";
  protected constant String VARIABILITY_CONTINUOUS_DUMMYDER   = "continuousDummyDer";
  protected constant String VARIABILITY_CONTINUOUS_DUMMYSTATE = "continuousDummyState";
  protected constant String VARIABILITY_DISCRETE              = "discrete";
  protected constant String VARIABILITY_PARAMETER             = "parameter";
  protected constant String VARIABILITY_CONSTANT              = "constant";
  protected constant String VARIABILITY_EXTERNALOBJECT        = "externalObject";

  protected constant String VAR_TYPE                    = "type";
  protected constant String VARTYPE_INTEGER             = "Integer";
  protected constant String VARTYPE_REAL                = "Real";
  protected constant String VARTYPE_STRING              = "String";
  protected constant String VARTYPE_BOOLEAN             = "Boolean";
  protected constant String VARTYPE_ENUM                = "Enum";
  protected constant String VARTYPE_ENUMERATION         = "enumeration";
  protected constant String VARTYPE_EXTERNALOBJECT      = "ExternalObject";

  protected constant String VAR_DIRECTION         = "direction";
  protected constant String VARDIR_INPUT          = "input";
  protected constant String VARDIR_OUTPUT         = "output";
  protected constant String VARDIR_NONE           = "none";

  protected constant String VAR_FIXED             = "fixed";
  protected constant String VAR_COMMENT           = "comment";

  protected constant String VAR_ATTRIBUTES_VALUES = "attributesValues";
  protected constant String VAR_ATTR_QUANTITY     = "quantity";
  protected constant String VAR_ATTR_UNIT         = "unit";
  protected constant String VAR_ATTR_DISPLAY_UNIT = "displayUnit";
  protected constant String VAR_ATTR_STATESELECT  = "stateSelect";
  protected constant String VAR_ATTR_MINVALUE     = "minValue";
  protected constant String VAR_ATTR_MAXVALUE     = "maxValue";
  protected constant String VAR_ATTR_NOMINAL      = "nominal";
  protected constant String VAR_ATTR_INITIALVALUE = "initialValue";
  protected constant String VAR_ATTR_FIXED        = "fixed";

  //Name of the element containing the binding information
  //for the variables (both expression (BindExpression) and value (BindValue).
  //For example consider:
  //parameter Real a = 3*2+e; //With Real constant e = 3;
  //BindExpression 3*2+e
  //BindValue = 9
  protected constant String BIND_VALUE_EXPRESSION   = "bindValueExpression";
  protected constant String BIND_EXPRESSION         = "bindExpression";
  protected constant String BIND_VALUE              = "bindValue";

  //Name of the element representing the subscript, for example the array's index.
  protected constant String SUBSCRIPT               = "subscript";

  //Additional info for variables.
  protected constant String HASH_TB_CREFS_LIST          = "hashTb";
  protected constant String HASH_TB_STRING_LIST_OLDVARS = "hashTbOldVars";

  //All this constants below are used in the dumpBackendDAE method.
  protected constant String EQUATIONS          = "equations";
  protected constant String EQUATIONS_         = "Equations";
  protected constant String SIMPLE             = "simple";
  protected constant String INITIAL            = "initial";
  protected constant String ZERO_CROSSING      = "zeroCrossing";
  protected constant String SAMPLES            = "Samples";
  protected constant String ARRAY_OF_EQUATIONS = "arrayOfEquations";//This is used also in the dumpEquation method.
  protected constant String COMPLEX_EQUATION   = "complexequations";

  protected constant String EQUATION     = "equation";
  protected constant String EQUATION_    = "Equation";
  protected constant String SOLVED       = "solved";
  protected constant String SOLVED_      = "Solved";
  protected constant String WHEN         = "when";
  protected constant String WHEN_        = "When";
  protected constant String WHEN_OPERATORS = "WhenOperators";
  protected constant String WHEN_OPERATOR = "WhenOperator";
  protected constant String RESIDUAL     = "residual";
  protected constant String RESIDUAL_    = "Residual";

  /*
  This String constant is used in:
    1 - dumpAlgorithms to print out the list of Algorithms:
        <ALGORITHM LABEL=Algorithm_ID>
          ...
        </ALGORITHM>
    2 - dumpEquation if the equation element is an algorithm:
        <ALGORITHM ID=...>
          <AlgorithmID>...</AlgorithmID>
          <ANCHOR ALGORITHM_NAME=Algorithm_No></ANCHOR>
        </ALGORITHM>
  */
  protected constant String ALGORITHM              = "algorithm";
  /*
  This String constant is used to print the reference to the
  corresponding algorithm.
  */
  protected constant String ALGORITHM_REF          = "algorithm_ref";


  protected constant String CONSTRAINT              = "constraint";
  protected constant String CONSTRAINT_REF          = "constraint_ref";

  /*
  This String constant represents the single equation of an array of
  equations and it is used in:
    1 - dumpArrayEqns to print the list of equations
    2 - dumpEquation to print the list of equations corresponding to
        the array
  */
  protected constant String ARRAY_EQUATION         = "arrayEquation";

  protected constant String ALGORITHMS              = "algorithms";
  protected constant String CONSTRAINTS             = "constraints";
  protected constant String FUNCTIONS               = "functions";
  protected constant String FUNCTION                = "function";
  protected constant String FUNCTION_NAME           = "name";
  protected constant String FUNCTION_ORIGNAME       = VAR_ORIGNAME;
  protected constant String NAME_BINDINGS           = "nameBindings";
  protected constant String C_NAME                  = "cName";
  protected constant String C_IMPLEMENTATIONS       = "cImplementations";
  protected constant String MODELICA_IMPLEMENTATION = "ModelicaImplementation";


  /*This strings here below are used for printing additionalInfo
  concerning the DAE system of equations, such as:
   - the original incidence matrix (before performing matching and BLT
   - the matching algorithm output
   - the blocks obtained after running the BLT algorithm (Tarjan)
   */
  protected constant String MATCHING_ALGORITHM        = "matchingAlgorithm";
  protected constant String SOLVED_IN                 = "solvedIn";
  protected constant String BLT_REPRESENTATION        = "bltRepresentation";
  protected constant String BLT_BLOCK                 = "bltBlock";
  protected constant String ORIGINAL_INCIDENCE_MATRIX = "originalIncidenceMatrix";


  protected constant String MATH                   = "math";
  protected constant String MathML                 = "MathML";
  protected constant String MathMLApply            = "apply";
  protected constant String MathMLWeb              = "http://www.w3.org/1998/Math/MathML";
  protected constant String MathMLXmlns            = "xmlns";
  protected constant String MathMLType             = "type";
  protected constant String MathMLNumber           = "cn";
  protected constant String MathMLVariable         = "ci";
  protected constant String MathMLConstant         = "constant";
  protected constant String MathMLInteger          = "integer";
  protected constant String MathMLReal             = "real";
  protected constant String MathMLVector           = "vector";
  protected constant String MathMLMatrixrow        = "matrixrow";
  protected constant String MathMLMatrix           = "matrix";
  protected constant String MathMLTrue             = "true";
  protected constant String MathMLFalse            = "false";
  protected constant String MathMLAnd              = "and";
  protected constant String MathMLOr               = "or";
  protected constant String MathMLNot              = "not";
  protected constant String MathMLEqual            = "eq";
  protected constant String MathMLLessThan         = "lt";
  protected constant String MathMLLessEqualThan    = "leq";
  protected constant String MathMLGreaterThan      = "gt";
  protected constant String MathMLGreaterEqualThan = "geq";
  protected constant String MathMLEquivalent       = "equivalent";
  protected constant String MathMLNotEqual         = "neq";
  protected constant String MathMLPlus             = "plus";
  protected constant String MathMLMinus            = "minus";
  protected constant String MathMLTimes            = "times";
  protected constant String MathMLDivide           = "divide";
  protected constant String MathMLPower            = "power";
  protected constant String MathMLTranspose        = "transpose";
  protected constant String MathMLScalarproduct    = "scalarproduct";
  protected constant String MathMLVectorproduct    = "vectorproduct";
  protected constant String MathMLInterval         = "interval";
  protected constant String MathMLSelector         = "selector";

  protected constant String MathMLIfClause         = "piecewise";
  protected constant String MathMLIfBranch         = "piece";
  protected constant String MathMLElseBranch       = "otherwise";

  protected constant String MathMLOperator         = "mo";
  protected constant String MathMLArccos           = "arccos";
  protected constant String MathMLArcsin           = "arcsin";
  protected constant String MathMLArctan           = "arctan";
  protected constant String MathMLLn               = "ln";
  protected constant String MathMLLog              = "log";


protected function binopSymbol "
function: binopSymbol
  Return a string representation of the Operator
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    local
      DAE.Ident s;
      DAE.Operator op;
    case op
      equation
        s = binopSymbol2(op);
      then
        s;
  end match;
end binopSymbol;


protected function binopSymbol2 "
Helper function to binopSymbol
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    local String error_msg;
    case (DAE.ADD()) then MathMLPlus;
    case (DAE.SUB()) then MathMLMinus;
    case (DAE.MUL()) then MathMLTimes;
    case (DAE.DIV()) then MathMLDivide;
    case (DAE.POW()) then MathMLPower;
    case (DAE.ADD_ARR()) then MathMLPlus;
    case (DAE.SUB_ARR()) then MathMLMinus;
    case (DAE.MUL_ARRAY_SCALAR()) then MathMLTimes;
    case (DAE.MUL_SCALAR_PRODUCT()) then MathMLScalarproduct;
    case (DAE.MUL_MATRIX_PRODUCT()) then MathMLVectorproduct;
    case (DAE.DIV_ARRAY_SCALAR()) then MathMLDivide;
    else
      equation
        error_msg = "in XMLDump.binopSymbol2 - Unknown operator: ";
        error_msg = error_msg + ExpressionDump.debugBinopSymbol(inOperator);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end binopSymbol2;


protected function dumpAbsynPathLst "
This function prints a list od Absyn.Path using
an XML representation. If the list of element is empty
the the methods doesn't print nothing, otherwise, depending
on the value of the second input (the String content) prints:
<Content>
  ...//List of paths
</Content>
"
  input list<Absyn.Path> absynPathLst;
  input String Content;
algorithm
  _ := matchcontinue (absynPathLst,Content)
    local
      Integer len;
    case ({},_)
      then();
    case (_,_)
      equation
        len = listLength(absynPathLst);
        len >= 1 = false;
      then ();
    case (_,_)
      equation
        len = listLength(absynPathLst);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpAbsynPathLst2(absynPathLst);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpAbsynPathLst;


protected function dumpAbsynPathLst2 "
This is an helper function to the dunmAbsynPathList
method.
"
  input list<Absyn.Path> absynPathLst;
algorithm
  _:= match (absynPathLst)
        local
          list<Absyn.Path> apLst;
          Absyn.Path ap;
          String str;
      case {} then ();
      case (ap :: apLst)
      equation
        str=Absyn.pathStringNoQual(ap);
        dumpStrTagContent(ELEMENT,str);
        dumpAbsynPathLst2(apLst);
      then();
    end match;
end dumpAbsynPathLst2;

protected function dumpConstraints "
This function dumps the list of DAE.Constraint
within using a XML format. If at least one Algorithm
is present the output is:
<CONSTRAINT DIMENSION=...>
  ...
</CONSTRAINT>
"
  input list<DAE.Constraint> constrs;
algorithm
  _:= matchcontinue(constrs)
    local
      Integer len;
    case {} then ();
    case _
      equation
        len = listLength(constrs);
        len >= 1 = false;
    then();
    case _
      equation
        len = listLength(constrs);
        len >= 1 = true;
        dumpStrOpenTagAttr(CONSTRAINTS,DIMENSION,intString(len));
        dumpConstraints2(constrs,0);
        dumpStrCloseTag(CONSTRAINTS);
    then();
  end matchcontinue;
end dumpConstraints;


protected function dumpConstraints2 "
This function dumps a list of DAE.Algorithm in
XML format. The output is something like:
<CONSTRAINT LABEL=Constraint_ID>
  ...
</CONSTRAINT>
<CONSTRAINT LABEL=Constraint_ID+1>
  ...
</CONSTRAINT>
  ...
"
  input list<DAE.Constraint> iConstrs;
  input Integer inConsNo;
algorithm
  _ := match(iConstrs,inConsNo)
    local
      list<DAE.Exp> exps;
      Integer conNo,conNo_1;
      list<DAE.Constraint> constrs;

    case({},_) then ();
    case(DAE.CONSTRAINT_EXPS(exps)::constrs,conNo)
      equation
        dumpStrOpenTagAttr(CONSTRAINT, LABEL, stringAppend(stringAppend(CONSTRAINT_REF,"_"),intString(conNo)));
        Print.printBuf(Util.xmlEscape(DAEDump.dumpConstraintsStr({DAE.CONSTRAINT(DAE.CONSTRAINT_EXPS(exps),DAE.emptyElementSource)})));
        dumpStrCloseTag(CONSTRAINT);
        conNo_1=conNo+1;
        dumpConstraints2(constrs,conNo_1);
      then ();
  end match;
end dumpConstraints2;

protected function dumpBltInvolvedEquations
"function: dumpBltInvolvedEquations"
  input BackendDAE.StrongComponent inComp;
  input Integer offset;
algorithm
  _:=
  match (inComp,offset)
    local
      Integer e;
      list<Integer> elst;
    case (BackendDAE.SINGLEEQUATION(eqn=e),_)
      equation
         dumpStrTagAttrNoChild(stringAppend(INVOLVED,EQUATION_), stringAppend(EQUATION,ID_), intString(e+offset));
      then
        ();
    case (_,_)
      equation
        (elst,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(inComp);
        dumpBltInvolvedEquations1(elst,offset);
      then
        ();
  end match;
end dumpBltInvolvedEquations;

protected function dumpBltInvolvedEquations1 "
This function dumps the equation ID for each block of the BLT
using an xml representation:
<involvedEquation equationId=\"\"/>
...
"
  input list<Integer> inList;
  input Integer offset;
algorithm
  _:=
  match(inList,offset)
      local
        Integer el;
        list<Integer> remList;
    case ({},_) then ();
    case(el :: remList,_)
      equation
        dumpStrTagAttrNoChild(stringAppend(INVOLVED,EQUATION_), stringAppend(EQUATION,ID_), intString(el+offset));
        dumpBltInvolvedEquations1(remList,offset);
      then();
  end match;
end dumpBltInvolvedEquations1;

protected function dumpBindValueExpression "
This function is necessary for printing the
BindValue and BindExpression of a variable,
if present. If there are not DAE.Exp nor
Values.Value passed as input nothing is
printed.
"
  input Option<DAE.Exp> inOptExpExp;
  input Option<Values.Value> inOptValuesValue;
  input Boolean addMathMLCode;

  algorithm
    _:=
  matchcontinue (inOptExpExp,inOptValuesValue,addMathMLCode)
      local
        DAE.Exp e;
        Values.Value b;
        Boolean addMMLCode;
  case(NONE(),NONE(),_)
    equation
    then();
  case(SOME(_),NONE(),addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptExp(inOptExpExp,BIND_EXPRESSION,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(NONE(),SOME(_),addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptValue(inOptValuesValue,BIND_VALUE,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(SOME(_),SOME(_),addMMLCode)
    equation
      dumpStrOpenTag(BIND_VALUE_EXPRESSION);
      dumpOptExp(inOptExpExp,BIND_EXPRESSION,addMMLCode);
      dumpOptValue(inOptValuesValue,BIND_VALUE,addMMLCode);
      dumpStrCloseTag(BIND_VALUE_EXPRESSION);
    then();
  case(_,_,_)
    then ();
  end matchcontinue;
end dumpBindValueExpression;

protected function dumpComment "
Function for adding comments using the XML tag.
"
  input String inComment;
algorithm
  Print.printBuf("<!--");
  Print.printBuf(Util.xmlEscape(inComment));
  Print.printBuf("-->");
end dumpComment;

protected function dumpComponents
"author: Frenkel TUD 2011-05
  This function is used to print BLT information using xml format.
The output is something like:
<bltBlock id=\"\">
  <InvolvedEquation equationID=\"\"/>
  ....
</bltBlock>"
  input BackendDAE.BackendDAE dae;
algorithm
  dumpStrOpenTag(BLT_REPRESENTATION);
  _ := BackendDAEUtil.foldEqSystem(dae,dumpComponentsWork,(0,0));
  dumpStrCloseTag(BLT_REPRESENTATION);
end dumpComponents;

protected function dumpComponentsWork
"author: Frenkel TUD 2011-05
  wrapper for calling dumpComponents for each equation system"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer> inOffset;
  output tuple<Integer,Integer> outOffset;
protected
 array<Integer> v1,v2;
 BackendDAE.StrongComponents comps;
 Integer voffset,eoffset;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,comps)) := syst;
  (voffset,eoffset) := inOffset;
  dumpStrOpenTag(BLT_REPRESENTATION);
  dumpComponents1(comps,voffset,eoffset);
  dumpStrCloseTag(BLT_REPRESENTATION);
  outOffset := ((voffset + arrayLength(v2),eoffset + arrayLength(v1)));
end dumpComponentsWork;

protected function dumpComponents1 "
function: dumpComponents1
This function is used to print BLT information using xml format.
The output is something like:
<bltBlock id=\"\">
  <InvolvedEquation equationID=\"\"/>
  ....
</bltBlock>
"
  input BackendDAE.StrongComponents l;
  input Integer voffset;
  input Integer eoffset;
algorithm
  _:=
  matchcontinue(l,voffset,eoffset)
    case({},_,_)
        then();
    case(_,_,_)
      equation
        dumpComponents2(l,1+voffset,eoffset);
      then();
  end matchcontinue;
end dumpComponents1;


protected function dumpComponents2 "
function: dumpComponents2
  Helper function to dump_components.
"
  input BackendDAE.StrongComponents inIntegerLstLst;
  input Integer i;
  input Integer offset;
algorithm
  _:=
  match (inIntegerLstLst,i,offset)
    local
      BackendDAE.StrongComponent l;
      BackendDAE.StrongComponents lst;
    case ({},_,_) then ();
    case ((l :: lst),_,_)
      equation
        dumpStrOpenTagAttr(BLT_BLOCK, ID, intString(i));
        dumpBltInvolvedEquations(l,offset);
        dumpStrCloseTag(BLT_BLOCK);
        dumpComponents2(lst,i+1,offset);
      then
        ();
  end match;
end dumpComponents2;


protected function dumpCrefIdxLstArr "
This function prints a list from a list
of array of CrefIndex elements in
a XML format. See dumpCrefIdxLst for details.
"
  input array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
  input String Content;
  input Integer inInteger;
algorithm
  _:=
  matchcontinue (crefIdxLstArr,Content,inInteger)
    local String error_msg;
    case (_,_,_)
      equation
        listLength(crefIdxLstArr[inInteger]) >= 1  = true;
        dumpCrefIdxLst(crefIdxLstArr[inInteger],Content);
      then ();
    case (_,_,_)
      equation
        listLength(crefIdxLstArr[inInteger]) >= 1  = false;
      then ();
    case (_,_,_)
      equation
        error_msg = "in XMLDump.dumpCrefIdxLstArr - failed for var number:";
        error_msg = error_msg + intString(inInteger);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then fail();
  end matchcontinue;
end dumpCrefIdxLstArr;


protected function dumpCrefIdxLst "
This function prints a list of CrefIndex elements
in a XML format. It also takes as input a String
for having information about the Content of the elements.
The output is like:
<Content>
  ...//CrefIdxList
<Content>
See dumpCrefIdxLst2 for details.
"
  input list<BackendDAE.CrefIndex> crefIdxLst;
  input String Content;
algorithm
  _ := matchcontinue (crefIdxLst,Content)
   local Integer len;
    case ({},_)
      then ();
    case (_,_)
      equation
        len = listLength(crefIdxLst);
        len >= 1 = false;
      then ();
    else
      equation
        len = listLength(crefIdxLst);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpCrefIdxLst2(crefIdxLst);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpCrefIdxLst;


protected function dumpCrefIdxLst2 "
This function prints a list of CrefIndex adding
information of the index of the element in the list
and using an XML format like:
<ELEMENT ID=...>CrefIndex</ELEMENT>
"
  input list<BackendDAE.CrefIndex> crefIdxLst;
algorithm
  _:=
  match (crefIdxLst)
      local
        list<BackendDAE.CrefIndex> crefIndexList;
        BackendDAE.CrefIndex crefIndex;
        Integer index_c;
        DAE.ComponentRef cref_c;
        String cref;
      case {}  then ();
      case ((BackendDAE.CREFINDEX(cref=cref_c,index=index_c)) :: crefIndexList)
      equation
        cref=ComponentReference.crefStr(cref_c);
        dumpStrOpenTagAttr(ELEMENT,ID,intString(index_c));
        Print.printBuf(cref);
        dumpStrCloseTag(ELEMENT);
        dumpCrefIdxLst2(crefIndexList);
      then ();
  end match;
end dumpCrefIdxLst2;


protected function dumpDAEInstDims "
This function prints a DAE.InstDims (a list of DAE.Subscript)
using an XML format. The input variables are the list of
DAE.Subscript and a String that store information about the
content of the list. The output could be something like:
<Content>
  ...//List of Subscript XML elements
</Content>
"
  input DAE.InstDims arry_Dim;
  input String Content;
algorithm
    _ := matchcontinue (arry_Dim,Content)
   local Integer len;
    case (_,_)
      equation
        len = listLength(arry_Dim);
        len >= 1 = false;
      then ();
    else
      equation
        len = listLength(arry_Dim);
        len >= 1 = true;
        dumpStrOpenTag(Content);
        dumpDAEInstDims2(arry_Dim);
        dumpStrCloseTag(Content);
      then();
  end matchcontinue;
end dumpDAEInstDims;


protected function dumpDAEInstDims2 "
Help function to dumpDAEInstDims. This function here
makes the real job of printing the list of DAE.Subscripts.
The output is something like:
<Subsript>FirstSubscriptOfTheList</Subscript>
...
<Subsript>LastSubscriptOfTheList</Subscript>
See dump Subscript for details.
"
  input DAE.InstDims arry_Dim;
algorithm
  _:= match (arry_Dim)
    local
      list<DAE.Dimension> lDim;
      DAE.Dimension dim;
  case {} then ();
  case (dim :: lDim)
    equation
      dumpStrOpenTag(DIMENSION);
      dumpDimension(dim);
      dumpStrCloseTag(DIMENSION);
      dumpDAEInstDims2(lDim);
    then();
  end match;
end dumpDAEInstDims2;

public function dumpDAEXML "dumps the DAE as xml representation of the current transformation state"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  String fileNamePrefix;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(info=BackendDAE.EXTRA_INFO(fileNamePrefix=fileNamePrefix))) := inDAE;

  Print.clearBuf();
  dumpBackendDAE(inDAE, false, false, false, false, false);
  Print.writeBuf(fileNamePrefix + ".xml");
  Print.clearBuf();
end dumpDAEXML;


public function dumpBackendDAE "
  This function dumps the BackendDAE representaton to stdout as XML format.
  The output is like:

<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?><!DOCTYPE DAE SYSTEM \"http://home.dei.polimi.it/Projects/AutoEdit/DAE.xsd\">
<DAE>
  <VARIABLES DIMENSION=..>
    <stringAppend(ORDERED,VARIABLES_)>
      ...
    </stringAppend(ORDERED,VARIABLES_)>
    <stringAppend(KNOWN,VARIABLES_)>
      ...
    </stringAppend(KNOWN,VARIABLES_)>
    <stringAppend(EXTERNAL,VARIABLES_)>
      ...
    </stringAppend(EXTERNAL,VARIABLES_)>
    <stringAppend(EXTERNAL,CLASSES_)>
      ...
    </stringAppend(EXTERNAL,CLASSES_)>
  </VARIABLES>
  <EQUATIONS>
    ...
  </EQUATIONS>
  <stringAppend(SIMPLE,EQUATIONS_)>
    ...
  </stringAppend(SIMPLE,EQUATIONS_)>
  <stringAppend(INITIAL,EQUATIONS_)>
    ...
  </stringAppend(INITIAL,EQUATIONS_)>
  <stringAppend(ZERO_CROSSING,LIST_)>
    ...
  </stringAppend(ZERO_CROSSING,LIST_)>
  <ARRAY_OF_EQUATIONS>
    ...
  </ARRAY_OF_EQUATIONS>
</DAE>

The XML output could change depending on the content of the BackendDAE structure, in
particular all the elements are optional, it means that if no element is present
the relative tag is not printed.
"
  input BackendDAE.BackendDAE inBackendDAE;
  input Boolean addOriginalIncidenceMatrix;
  input Boolean addSolvingInfo;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input Boolean dumpSolvedEquations;
algorithm
  _ := matchcontinue (inBackendDAE,addOriginalIncidenceMatrix,addSolvingInfo,addMathMLCode,dumpResiduals,dumpSolvedEquations)
    local
      list<BackendDAE.Var> vars,knvars,extvars,aliasvars;

      //Ordered Variables: state & algebraic variables.
      //VARIABLES record for vars.

      //Known Variables: constant & parameter variables.
      BackendDAE.Variables vars_knownVars;
      //VARIABLES record for vars.
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr_knownVars;
      BackendDAE.VariableArray varArr_knownVars;
      Integer bucketSize_knownVars;
      Integer numberOfVars_knownVars;

      //External Object: external variables.
      BackendDAE.Variables vars_externalObject;
      //VARIABLES record for vars.
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr_externalObject;
      BackendDAE.VariableArray varArr_externalObject;
      Integer bucketSize_externalObject;
      Integer numberOfVars_externalObject;

      //Alias Variables: alias variables
      BackendDAE.Variables vars_aliasVars;
      //VARIABLES record for aliasVars.
      array<list<BackendDAE.CrefIndex>> crefIdxLstArr_aliasVars;
      BackendDAE.VariableArray varArr_aliasVars;
      Integer bucketSize_aliasVars;
      Integer numberOfVars_aliasVars;

      //External Classes
      BackendDAE.ExternalObjectClasses extObjCls;

      list<BackendDAE.Equation> eqnsl,reqnsl,ieqnsl;
      BackendDAE.EquationArray reqns,ieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;

      list<DAE.Function> functionsElems;

      Boolean addOrInMatrix,addSolInfo,addMML,dumpRes,dumpSolved;
      BackendDAE.BackendDAEType btp;
      list<BackendDAE.EqSystem> systs;
      BackendDAE.SymbolicJacobians symjacs;
      DAE.FunctionTree funcs;

      list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> eqnsVarsinOrderLst;
      BackendDAE.EventInfo eventInfo;

    case (BackendDAE.DAE(systs,
                 BackendDAE.SHARED(
                 vars_knownVars as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_knownVars),
                 _,
                 vars_externalObject as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_externalObject),
                 vars_aliasVars as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_aliasVars),
                 ieqns,_,constrs,_,_,_,funcs,eventInfo,
                 extObjCls,_,_,_)),addOrInMatrix,addSolInfo,addMML,dumpRes,false)
      equation

        knvars  = BackendVariable.varList(vars_knownVars);
        extvars = BackendVariable.varList(vars_externalObject);
        aliasvars = BackendVariable.varList(vars_aliasVars);

        reqns = BackendDAEUtil.collapseRemovedEqs(inBackendDAE);

        Print.printBuf(HEADER);
        dumpStrOpenTag(DAE_OPEN);
        dumpStrOpenTagAttr(VARIABLES, DIMENSION, intString(List.fold(List.map(systs,BackendDAEUtil.systemSize),intAdd,0)+listLength(knvars)+listLength(extvars)+listLength(aliasvars)));
        //Bucket size info is no longer present.
        vars = List.fold(systs,getOrderedVars,{});
        dumpVars(vars,arrayCreate(1,{}),stringAppend(ORDERED,VARIABLES_),addMML);
        dumpVars(knvars,crefIdxLstArr_knownVars,stringAppend(KNOWN,VARIABLES_),addMML);
        dumpVars(extvars,crefIdxLstArr_externalObject,stringAppend(EXTERNAL,VARIABLES_),addMML);
        dumpVars(aliasvars,crefIdxLstArr_aliasVars,stringAppend(ALIAS,VARIABLES_),addMML);
        dumpExtObjCls(extObjCls,stringAppend(EXTERNAL,CLASSES_));
        dumpStrCloseTag(VARIABLES);
        eqnsl = List.fold(systs,getEqsList,{});
        dumpEqns(eqnsl,EQUATIONS,addMML,dumpRes, false);
        reqnsl = BackendEquation.equationList(reqns);
        dumpEqns(reqnsl,stringAppend(SIMPLE,EQUATIONS_),addMML,dumpRes, false);
        ieqnsl = BackendEquation.equationList(ieqns);
        dumpEqns(ieqnsl,stringAppend(INITIAL,EQUATIONS_),addMML,dumpRes, false);

        dumpEventInfo(eventInfo, addMML);

        dumpConstraints(constrs);
        functionsElems = DAEUtil.getFunctionList(funcs);
        dumpFunctions(functionsElems);
        dumpSolvingInfo(addOrInMatrix,addSolInfo,inBackendDAE);
        dumpStrCloseTag(DAE_CLOSE);
      then ();

    case (BackendDAE.DAE(systs,
                 BackendDAE.SHARED(
                 vars_knownVars as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_knownVars),
                 _,
                 vars_externalObject as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_externalObject),
                 vars_aliasVars as BackendDAE.VARIABLES(crefIndices=crefIdxLstArr_aliasVars),
                 ieqns,_,constrs,_,_,_,funcs,eventInfo,
                 extObjCls,_,_,_,_)),addOrInMatrix,addSolInfo,addMML,dumpRes,true)
      equation

        knvars  = BackendVariable.varList(vars_knownVars);
        extvars = BackendVariable.varList(vars_externalObject);
        aliasvars = BackendVariable.varList(vars_aliasVars);

        reqns = BackendDAEUtil.collapseRemovedEqs(inBackendDAE);

        Print.printBuf(HEADER);
        dumpStrOpenTag(DAE_OPEN);
        dumpStrOpenTagAttr(VARIABLES, DIMENSION, intString(List.fold(List.map(systs,BackendDAEUtil.systemSize),intAdd,0)+listLength(knvars)+listLength(extvars)+listLength(aliasvars)));
        //Bucket size info is no longer present.
        vars = List.fold(systs,getOrderedVars,{});
        dumpVars(vars,arrayCreate(1,{}),stringAppend(ORDERED,VARIABLES_),addMML);
        dumpVars(knvars,crefIdxLstArr_knownVars,stringAppend(KNOWN,VARIABLES_),addMML);
        dumpVars(extvars,crefIdxLstArr_externalObject,stringAppend(EXTERNAL,VARIABLES_),addMML);
        dumpVars(aliasvars,crefIdxLstArr_aliasVars,stringAppend(ALIAS,VARIABLES_),addMML);
        dumpExtObjCls(extObjCls,stringAppend(EXTERNAL,CLASSES_));
        dumpStrCloseTag(VARIABLES);
        eqnsVarsinOrderLst = List.fold(systs,getOrderedEqsandVars,{});

        dumpStrOpenTagAttr(EQUATIONS, DIMENSION, intString(listLength(eqnsVarsinOrderLst)));
        dumpSolvedEqns(eqnsVarsinOrderLst,1,EQUATIONS,addMML,dumpRes, true);
        dumpStrCloseTag(EQUATIONS);

        reqnsl = BackendEquation.equationList(reqns);
        dumpEqns(reqnsl,stringAppend(SIMPLE,EQUATIONS_),addMML,dumpRes, false);
        ieqnsl = BackendEquation.equationList(ieqns);
        dumpEqns(ieqnsl,stringAppend(INITIAL,EQUATIONS_),addMML,dumpRes, false);

        dumpEventInfo(eventInfo, addMML);

        dumpConstraints(constrs);
        functionsElems = DAEUtil.getFunctionList(funcs);
        dumpFunctions(functionsElems);
        dumpSolvingInfo(addOrInMatrix,addSolInfo,inBackendDAE);
        dumpStrCloseTag(DAE_CLOSE);
      then ();
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"XMLDump.dumpBackendDAE failed"});
      then
        fail();
  end matchcontinue;
end dumpBackendDAE;

protected function dumpEventInfo
  input BackendDAE.EventInfo inEventInfo;
  input Boolean addMML;
algorithm
  _ := match(inEventInfo, addMML)
    local
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.ZeroCrossingSet zc;

    case (BackendDAE.EVENT_INFO(timeEvents=timeEvents,
                                zeroCrossings=zc), _)
      equation
        dumpTimeEvents(timeEvents, stringAppend(SAMPLES, LIST_), addMML);
        dumpZeroCrossing(ZeroCrossings.toList(zc), stringAppend(ZERO_CROSSING, LIST_), addMML);
      then
        ();

  end match;
end dumpEventInfo;


protected function getOrderedVars
  input BackendDAE.EqSystem syst;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Var> outVars;
protected
  list<BackendDAE.Var> vars;
algorithm
  vars := BackendVariable.varList(BackendVariable.daeVars(syst));
  outVars := listAppend(inVars,vars);
end getOrderedVars;

protected function getEqsList
  input BackendDAE.EqSystem syst;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
protected
  list<BackendDAE.Equation> eqnsl;
algorithm
  eqnsl := BackendEquation.equationList(BackendEquation.getEqnsFromEqSystem(syst));
  outEqns := listAppend(inEqns,eqnsl);
end getEqsList;

protected function getOrderedEqsandVars
  input BackendDAE.EqSystem syst;
  input list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> inEqnsVars;
  output list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> outEqnsVars;
protected
  list<BackendDAE.Equation> eqnsl;
  list<BackendDAE.Var> varlst;
  BackendDAE.StrongComponents comps;
  BackendDAE.EquationArray eqns;
  BackendDAE.Variables vars;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=eqns,orderedVars=vars,matching=BackendDAE.MATCHING(comps=comps)) := syst;
  outEqnsVars := getOrderedEqs2(comps, eqns, vars, inEqnsVars);
end getOrderedEqsandVars;

protected function getOrderedEqs2
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars;
  input list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> inAccum;
  output list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> outEqnsVarsLst;
algorithm
  outEqnsVarsLst :=
  match(inComps, eqns, vars, inAccum)
    local
      Integer e,v;
      list<Integer> elst,vlst,vlst1,elst1;
      list<list<Integer>> vlst1Lst;
      BackendDAE.StrongComponent comp;
      BackendDAE.StrongComponents rest;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> inAccumVars, varlst, varlst1;
      list<BackendDAE.Equation> inAccumEqns, eqnlst, eqnlst1;
      BackendDAE.InnerEquations innerEquations;
      tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>> eqnsVars;
      list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> result;
    case ({},_,_,_)  then inAccum;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v)::rest,_,_,_)
      equation
        var = BackendVariable.getVarAt(vars,v);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},{var})});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqnlst = BackendEquation.getEqns(elst,eqns);
        result = listAppend(inAccum,{(eqnlst,varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.SINGLEARRAY(eqn=e,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.SINGLEIFEQUATION(eqn=e,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.SINGLEALGORITHM(eqn=e,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.SINGLECOMPLEXEQUATION(eqn=e,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.SINGLEWHENEQUATION(eqn=e,vars=vlst)::rest,_,_,_)
      equation
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        eqn = BackendEquation.equationNth1(eqns,e);
        result = listAppend(inAccum,{({eqn},varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vlst,residualequations=elst,innerEquations=innerEquations))::rest,_,_,_)
      equation
        (elst1,vlst1Lst,_) = List.map_3(innerEquations, BackendDAEUtil.getEqnAndVarsFromInnerEquation);
        vlst1 = List.flatten(vlst1Lst);
        varlst1 = List.map1r(vlst1, BackendVariable.getVarAt, vars);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, vars);
        varlst = listAppend(varlst1,varlst);
        eqnlst1 = BackendEquation.getEqns(elst1,eqns);
        eqnlst = BackendEquation.getEqns(elst,eqns);
        eqnlst = listAppend(eqnlst1,eqnlst);
        result = listAppend(inAccum,{(eqnlst,varlst)});
        result = getOrderedEqs2(rest,eqns,vars,result);
      then
        result;
    case (_::_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("XMLDump.getOrderedEqs2 failed!");
      then
        fail();
  end match;
end getOrderedEqs2;

protected function dumpDAEVariableAttributes "
This function dump the attributes a variable could have,
sudh as:
 - Quantity
 - Unit
 - Unit to diplay
 - State selection
 - Min value
 - Max value
 - Nominal
 - Initial value
 - Fixed
 in a new XML element. The ouptut is like:
<Content>
 <Quantity String=...>
  <MathML>
   ...
  </MathML>
 </Quantity>
 ...
</Content>
"
  input Option<DAE.VariableAttributes> dae_var_attr;
  input String Content;
  input Boolean addMathMLCode;
 algorithm
   _:= matchcontinue(dae_var_attr,Content,addMathMLCode)
     local
       Option<DAE.Exp> min, max;
       Option<DAE.Exp> quant,unit,displayUnit,startOrigin;
       Option<DAE.Exp> Initial,nominal;
       Option<DAE.Exp> fixed;
       Option<DAE.StateSelect> stateSel;
       Option<DAE.Uncertainty> unc;
       Option<DAE.Distribution> distrOpt;
       Boolean addMMLCode;
       Option<DAE.Exp> equationBound;
       Option<Boolean> isProtected;
       Option<Boolean> finalPrefix;

   case (SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),_,_,_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_INT(NONE(),NONE(),NONE(),NONE(),NONE(),_,_,_,_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_BOOL(NONE(),NONE(),NONE(),_,_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_STRING(NONE(),NONE(),_,_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_ENUMERATION(NONE(),NONE(),NONE(),NONE(),NONE(),_,_,_,_)),_,_) then ();
   case (SOME(DAE.VAR_ATTR_REAL(quant,unit,displayUnit,min,max,Initial,fixed,nominal,stateSel,_,_,
                                _,_,_,_)),_,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(unit,VAR_ATTR_UNIT,addMMLCode);
        dumpOptExp(displayUnit,VAR_ATTR_DISPLAY_UNIT,addMMLCode);
        dumpOptionDAEStateSelect(stateSel,VAR_ATTR_STATESELECT);
        dumpOptExp(min,VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(max,VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(nominal,VAR_ATTR_NOMINAL,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        // adrpo: TODO! FIXME! add the new information about equationBound,isProtected,finalPrefix
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_INT(quant,min,max,Initial,fixed,_,_,_,_,_,_)),_,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(min,VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(max,VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_BOOL(quant,Initial,fixed,_,_,_,_)),_,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_STRING(quant,Initial,_,_,_,_)),_,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpStrCloseTag(Content);
      then();
    case (SOME(DAE.VAR_ATTR_ENUMERATION(quant,min,max,Initial,fixed,_,_,_,_)),_,addMMLCode)
      equation
        dumpStrOpenTag(Content);
        dumpOptExp(quant,VAR_ATTR_QUANTITY,addMMLCode);
        dumpOptExp(min,VAR_ATTR_MINVALUE,addMMLCode);
        dumpOptExp(max,VAR_ATTR_MAXVALUE,addMMLCode);
        dumpOptExp(Initial,VAR_ATTR_INITIALVALUE,addMMLCode);
        dumpOptExp(fixed,VAR_ATTR_FIXED,addMMLCode);
        dumpStrCloseTag(Content);
        then();
    case (NONE(),_,_) then ();
    case (_,_,_)
      equation
        dumpComment("unknown VariableAttributes");
      then ();
   end matchcontinue;
end dumpDAEVariableAttributes;


protected function dumpDirectionStr "
This function dumps the varDirection of a variable:
 it could be:
 - input
 - output
"
  input DAE.VarDirection inVarDirection;
  output String outString;
algorithm
  outString:=
  match (inVarDirection)
    local String error_msg;
    case DAE.INPUT()  then VARDIR_INPUT;
    case DAE.OUTPUT() then VARDIR_OUTPUT;
    case DAE.BIDIR()  then VARDIR_NONE;
    else
      equation
        error_msg = "in XMLDump.dumpDirectionStr - Unknown var direction";
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end dumpDirectionStr;


protected function dumpSolvedEqns "

This function prints a system of equation in XML format.
The output is:
<Content DIMENSION=..>
  ...
</Content>
"
  input list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> eqns;
  input Integer inCount;
  input String inContent;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input Boolean dumpSolved;
algorithm
  _:=
  match (eqns,inCount,inContent,addMathMLCode,dumpResiduals,dumpSolved)
    local
      Boolean addMMLCode;
      Integer len;
      list<BackendDAE.Equation> eqnsLst;
      list<BackendDAE.Var> varLst;
      list<tuple<list<BackendDAE.Equation>, list<BackendDAE.Var>>> rest;
    case ({},_,_,_,_,_) then ();
    case (({},_)::rest,_,_,_,_,_)
      equation
        dumpSolvedEqns(rest, inCount, inContent, addMathMLCode,dumpResiduals,dumpSolved);
      then();
    case ((eqnsLst,varLst)::rest,_,_,addMMLCode,_,_)
      equation
        len = listLength(eqnsLst);
        len >= 1 = true;
        dumpEqns2(eqnsLst, varLst, inCount, addMMLCode,dumpResiduals,dumpSolved);
        dumpSolvedEqns(rest, inCount+1, inContent, addMathMLCode,dumpResiduals,dumpSolved);
      then ();
  end match;
end dumpSolvedEqns;

protected function dumpEqns "

This function prints a system of equation in XML format.
The output is:
<Content DIMENSION=..>
  ...
</Content>
"
  input list<BackendDAE.Equation> eqns;
  input String inContent;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input Boolean dumpSolved;
algorithm
  _:=
  matchcontinue (eqns,inContent,addMathMLCode,dumpResiduals,dumpSolved)
    local
      Boolean addMMLCode;
      Integer len;
    case ({},_,_,_,_) then ();
    case (_,_,_,_,_)
      equation
        len = listLength(eqns);
        len >= 1 = false;
      then();
    case (_,_,addMMLCode,_,_)
      equation
        len = listLength(eqns);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpEqns2(eqns, {}, 1,addMMLCode,dumpResiduals,dumpSolved);
        dumpStrCloseTag(inContent);
      then ();
  end matchcontinue;
end dumpEqns;


protected function dumpEqns2 "
  Helper function to dumpEqns
"
  input list<BackendDAE.Equation> inEquationLst;
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
  input Boolean addMathMLCode;
  input Boolean dumpResiduals;
  input Boolean dumpSolved;
algorithm
  _:=
  matchcontinue (inEquationLst,inVarLst,inInteger,addMathMLCode,dumpResiduals,dumpSolved)
    local
      Integer index;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Var var;
      list<BackendDAE.Var> vars;
      Boolean addMMLCode;
      DAE.ComponentRef cref;
      DAE.Exp varexp;
    case ({},_,_,_,_,_) then ();
    case ((eqn :: eqns),_,index,addMMLCode,false,false)
      equation
        dumpEquation(eqn, intString(index),addMMLCode);
        dumpEqns2(eqns, inVarLst, index+1,addMMLCode, false, false);
      then ();
    case ((eqn :: eqns),_,index,addMMLCode,true,false)
      equation
        //dumpEquation(BackendEquation.equationToResidualForm(eqn), intString(index),addMMLCode);
        //This should be done as above. The problem is that the BackendEquation.equationToResidualForm(eqn) method
        //is not working as expected, probably due to the fact that considers only scalar right hand side
        //part of equation, i.e. it works correctly if we have something like a = b (with a and b scalar)
        //thus obtaining a -b = 0.
        //The BackendEquation.equationToResidualForm is not working properly when the right part of the equation is not
        //a scalar. Cosidering the following equation: x = y - z will then results in obtaining the wrong
        //residual equation x - y - z and not x - (y - z).
        //Even if I didn't debug such a method I made some test via printing the equation that confirmed
        //the problem.
        //By the way, when all doubt will be clearified the follow line:
        dumpResidual(eqn, intString(index),addMMLCode);
        //will be substituted with:
        //dumpEquation(BackendEquation.equationToResidualForm(eqn), intString(index),addMMLCode);
        dumpEqns2(eqns, inVarLst, index+1,addMMLCode,true,false);
      then ();
    case ((eqn :: eqns),(var :: vars),index,addMMLCode,false,true)
      equation
        cref = BackendVariable.varCref(var);
        varexp = Expression.crefExp(cref);
        varexp = if BackendVariable.isStateVar(var) then Expression.expDer(varexp) else varexp;
        eqn = BackendEquation.solveEquation(eqn, varexp, NONE());
        dumpEquation(eqn, intString(index),addMMLCode);
        dumpEqns2(eqns, vars, index+1, addMMLCode, false, true);
      then ();
    case ((eqn :: eqns),(_ :: vars),index,addMMLCode,false,true)
      equation
        dumpEquation(eqn, intString(index),addMMLCode);
        dumpEqns2(eqns, vars, index+1, addMMLCode, false, true);
      then ();
  end matchcontinue;
end dumpEqns2;


protected function dumpEquation "
This function is necessary to print an equation element.
Since in Modelica is possible to have different kind of
equations, the BackendDAE representation of the OMC distinguish
between:
 - normal equations
 - array equations
 - solved equations
 - when equations
 - residual equations
 - algorithm references
This function prints the content using XML representation. The
output changes according to the content of the equation.
For example, if the element is an Array of Equations:
<ArrayOfEquations ID=..>
  <ARRAY_EQUATION>
    ..
    <MathML>
     ...
   </MathML>
   <ADDITIONAL_INFO stringAppend(ARRAY_OF_EQUATIONS,ID_)=...>
     <INVOLVEDVARIABLES>
       <VARIABLE>...</VARIABLE>
       ...
       <VARIABLE>...</VARIABLE>
     </INVOLVEDVARIABLES>
   </ADDITIONAL_INFO>
  </ARRAY_EQUATION>
</ARRAY_OF_EQUATIONS>
"
  input BackendDAE.Equation inEquation;
  input String inIndexNumber;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inEquation,inIndexNumber,addMathMLCode)
    local
      String s,s1,s2,res,is,indexS;
      DAE.Exp e1,e2,e;
      DAE.ComponentRef cr;
      Boolean addMMLCode;
      list<DAE.Statement> stmts;
      DAE.ElementSource source;
      list<BackendDAE.WhenOperator> whenStmtLst;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2),indexS,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(EQUATION);
      then ();

    case (BackendDAE.EQUATION(exp = e1,scalar = e2),indexS,false)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(EQUATION);
      then ();

    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2),_,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        s = stringAppendList({s1," = ",s2,"\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(ARRAY_EQUATION);
      then ();

    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2),indexS,false)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(ARRAY_OF_EQUATIONS,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(ARRAY_OF_EQUATIONS);
      then ();

    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2),_,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        s = stringAppendList({s1," = ",s2,"\n"});
        dumpStrOpenTagAttr(COMPLEX_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(COMPLEX_EQUATION);
      then ();

    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2),indexS,_)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
        dumpStrOpenTagAttr(COMPLEX_EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(COMPLEX_EQUATION);
      then ();

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,true)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrMathMLVariable(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,false)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," := ",s2});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();

    case (BackendDAE.WHEN_EQUATION(whenEquation =  BackendDAE.WHEN_STMTS(condition = e1,whenStmtLst=whenStmtLst)),indexS,true)
      equation
        is = printExpStr(e1);
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        dumpWhenOperatorLst(whenStmtLst, addMathMLCode);

        dumpStrOpenTag(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION));
        Print.printBuf("\n");
        Print.printBuf(is);
        dumpExp(e1, true);
        dumpStrCloseTag(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION));

        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(condition = e1,whenStmtLst=whenStmtLst)),indexS,false)
      equation
        is = printExpStr(e1);
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        dumpWhenOperatorLst(whenStmtLst, addMathMLCode);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();

    case (BackendDAE.RESIDUAL_EQUATION(exp = e),indexS,true)
      equation
        s1 = printExpStr(e);
        res = stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e);
        dumpStrMathMLNumber("0");
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();

    case (BackendDAE.RESIDUAL_EQUATION(exp = e),indexS,false)
      equation
        s1 = printExpStr(e);
        res = stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();

    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(stmts),source=source),indexS,_)
      equation
        dumpStrOpenTagAttr(ALGORITHM,ID,indexS);
        Print.printBuf(Util.xmlEscape(DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)})));
        dumpStrCloseTag(ALGORITHM);
      then ();

    else
      equation
        res = "in XMLDump.dumpEquation - Unknown equation";
        Error.addMessage(Error.INTERNAL_ERROR, {res});
      then
        fail();

  end match;
end dumpEquation;

protected function dumpExp
"This function prints a complete expression
  as a MathML. The content is like:
  <MathML>
  <MATH xmlns=\"http://www.w3.org/1998/Math/MathML\">
  DAE.Exp
  </MATH>
  </MathML>"
  input DAE.Exp e;
  //output String s;
  input Boolean addMathMLCode;
algorithm
  _:=
  matchcontinue (e,addMathMLCode)
    local
      DAE.Exp inExp;
    case(inExp,true)
      equation
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpExp2(inExp);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
      then();
    case(_,false)
      then();
    case(_,_) then();
  end matchcontinue;
end dumpExp;


protected function dumpExp2
"Helper function to dumpExpression. It can also
  be used if it's not necessary to print the headers
  (MathML and MATH tags)."
  input DAE.Exp inExp;
algorithm
  _:=
  matchcontinue (inExp)
    local
      DAE.Ident s,sym,res,str;
      DAE.Ident fs;
      Integer x,ival;
      Real rval;
      DAE.ComponentRef c;
      DAE.Type t,tp;
      DAE.Exp e1,e2,e,start,stop,step,cr,dim,cond,tb,fb;
      DAE.Operator op;
      Absyn.Path fcn;
      list<DAE.Exp> args,es;
      list<list<DAE.Exp>> ebs;
    case (DAE.ICONST(integer = x))
      equation
        dumpStrMathMLNumberAttr(intString(x),MathMLType,MathMLInteger);
      then ();
    case (DAE.RCONST(real = rval))
      equation
        dumpStrMathMLNumberAttr(realString(rval),MathMLType,MathMLReal);
      then ();
    case (DAE.SCONST(string = s))
      equation
        dumpStrMathMLNumberAttr(Util.xmlEscape(s),MathMLType,MathMLConstant);
      then ();
    case (DAE.BCONST(bool = false))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLFalse);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.BCONST(bool = true))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTrue);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CREF(componentRef = c))
      equation
        s = ComponentReference.printComponentRefStr(c);
        dumpStrMathMLVariable(s);
      then ();
    case (DAE.BINARY(e1,op,e2))
      equation
        sym = binopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
     case ((DAE.UNARY(op,e1)))
      equation
        sym = unaryopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpStrCloseTag(MathMLApply);
      then ();
   case ((DAE.LBINARY(e1,op,e2)))
      equation
        sym = lbinopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
   case ((DAE.LUNARY(op,e1)))
      equation
        sym = lunaryopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpStrCloseTag(MathMLApply);
      then();
   case ((DAE.RELATION(exp1=e1,operator=op,exp2=e2)))
      equation
        sym = relopSymbol(op);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(sym);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case ((DAE.IFEXP(cond,tb,fb)))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLIfClause);
        dumpStrOpenTag(MathMLIfBranch);
        dumpExp2(tb);
        dumpExp2(cond);
        dumpStrCloseTag(MathMLIfBranch);
        dumpStrOpenTag(MathMLElseBranch);
        dumpExp2(fb);
        dumpStrCloseTag(MathMLElseBranch);
        dumpStrCloseTag(MathMLIfClause);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag("diff");
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "acos"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArccos);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "asin"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArcsin);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "atan"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLArctan);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "atan2"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("atan2");
        dumpStrCloseTag(MathMLOperator);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("(");
        dumpStrCloseTag(MathMLOperator);
        dumpList(args,dumpExp2);
        dumpComment("atan2 is not a MathML element it could be possible to use arg in future");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(")");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "log"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLLn);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CALL(path = Absyn.IDENT(name = "log10"),expLst = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLLog);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
/*
    case (DAE.CALL(path = Absyn.IDENT(name = "pre"),expLst = args))
      equation
        fs = Absyn.pathStringNoQual(fcn);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag("selector");          ----THIS IS FOR ALGORITHM----
        dumpList(args,dumpExp2);
        dumpStrMathMLVariable("t-1");
        dumpStrCloseTag("apMathMLApply;
      then ();
*/
    case (DAE.CALL(path = fcn,expLst = args))
      equation
        // Add the ref to path
        fs = Absyn.pathStringNoQual(fcn);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(fs);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.ARRAY(array = es))//Array are dumped as vector
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTranspose);
        dumpStrOpenTag(MathMLVector);
        dumpList(es,dumpExp2);
        dumpStrCloseTag(MathMLVector);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.TUPLE(PR = es))//Tuple are dumped as vector
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLTranspose);
        dumpStrOpenTag(MathMLVector);
        dumpList(es,dumpExp2);
        dumpStrCloseTag(MathMLVector);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.MATRIX(matrix = ebs))
      equation
        dumpStrOpenTag(MathMLMatrix);
        dumpStrOpenTag(MathMLMatrixrow);
        dumpListSeparator(ebs, dumpRow, stringAppendList({"\n</",MathMLMatrixrow,">\n<",MathMLMatrixrow,">"}));
        dumpStrCloseTag(MathMLMatrixrow);
        dumpStrCloseTag(MathMLMatrix);
      then ();
    case (DAE.RANGE(_,start,NONE(),stop))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLInterval);
        dumpExp2(start);
        dumpExp2(stop);
        dumpStrCloseTag(MathMLInterval);
        dumpStrCloseTag(MathMLApply);
      then ();
    case ((DAE.RANGE(_,start,SOME(step),stop)))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("{");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(start);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(":");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(step);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(":");
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(stop);
        dumpComment("Interval range specification is not supported by MathML standard");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("}");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.T_REAL(),exp = DAE.ICONST(integer = ival)))
      equation
        false = Config.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        dumpStrMathMLNumberAttr(res,MathMLType,MathMLReal);
      then ();
    case (DAE.CAST(ty = DAE.T_REAL(),exp = DAE.UNARY(operator = DAE.UMINUS(),exp = DAE.ICONST(integer = ival))))
      equation
        false = Config.modelicaOutput();
        rval = intReal(ival);
        res = realString(rval);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLMinus);
        dumpStrMathMLNumberAttr(res,MathMLType,MathMLReal);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.T_REAL(),exp = e))
      equation
        false = Config.modelicaOutput();
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLReal);
        dumpExp2(e);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.CAST(ty = DAE.T_REAL(),exp = e))
      equation
        true = Config.modelicaOutput();
        dumpExp2(e);
      then ();
    case (DAE.CAST(ty = tp,exp = e))
      equation
        str = Types.unparseType(tp);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("(");
        dumpStrCloseTag(MathMLOperator);
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf("CAST as ");Print.printBuf(str);
        dumpStrCloseTag(MathMLOperator);
        dumpExp2(e);
        dumpComment("CAST operator is not supported by MathML standard.");
        dumpStrOpenTag(MathMLOperator);
        Print.printBuf(")");
        dumpStrCloseTag(MathMLOperator);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.ASUB(exp = e1,sub = args))
      equation
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLSelector);
        dumpExp2(e1);
        dumpList(args,dumpExp2);
        dumpStrCloseTag(MathMLApply);
      then ();
    case (DAE.ENUM_LITERAL(name = fcn))
      equation
        dumpStrMathMLVariable(Absyn.pathStringNoQual(fcn));
      then ();
    case (DAE.SIZE(sz = SOME(_)))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (DAE.SIZE(sz = NONE()))
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (DAE.REDUCTION())
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then  ();
      // MetaModelica list
    case (DAE.LIST())
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
        // MetaModelica list cons
    case (DAE.CONS())
      equation
        // NOT PART OF THE MODELICA LANGUAGE
      then ();
    case (_)
      equation
        dumpComment("UNKNOWN EXPRESSION: " + ExpressionDump.printExpStr(inExp));
      then ();
  end matchcontinue;
end dumpExp2;

protected function dumpExtObjCls "
Dump classes of external objects within the 'classes' attribute
of the '<stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_)/>' element.
A possible enchancement would be to print the classes as
xml Modelica classes.
"
input BackendDAE.ExternalObjectClasses cls;
input String Content;
algorithm
  _ := matchcontinue(cls,Content)
   local
     Integer len;
     BackendDAE.ExternalObjectClasses xs;
    case ({},_) then ();
    case (xs,_)
      equation
        len = listLength(xs);
        len >= 1 = false;
      then ();
    case (xs,_)
      equation
        len = listLength(xs);
        len >= 1 = true;
        dumpStrOpenTagAttr(stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_),DIMENSION,intString(len));
        dumpExtObjCls2(xs,stringAppend(EXTERNAL,CLASS_));
        dumpStrCloseTag(stringAppend(stringAppend(EXTERNAL,CLASSES_),LIST_));
      then ();
  end matchcontinue;
end dumpExtObjCls;


protected function dumpExtObjCls2 "

Help function to dumpExtObjClsXML. It prints
all the class element of the list in the
Content tag, like:
<Content>
model ...
end ...
</Content>
...
"
input BackendDAE.ExternalObjectClasses cls;
input String Content;
algorithm
  _ := match(cls,Content)
   local
     BackendDAE.ExternalObjectClasses xs;
     Absyn.Path path;
     String c;
     DAE.ElementSource source "the origin of the element";

    case ({},_) then ();
    case (BackendDAE.EXTOBJCLASS(path,_)::xs,c)
      equation
        dumpStrOpenTag(c);
        Print.printBuf("class ");Print.printBuf(Absyn.pathStringNoQual(path));Print.printBuf("\n  extends ExternalObject");
        Print.printBuf("end");Print.printBuf(Absyn.pathStringNoQual(path));
        dumpStrCloseTag(c);
        dumpExtObjCls2(xs,c);
      then ();
  end match;
end dumpExtObjCls2;


protected function dumpFlowStr "
This function returns a string with
the content of the flow type of a variable.
It could be:
 - Flow
 - NonFlow
 - NonConnector
"
  input DAE.ConnectorType inVarFlow;
  output String outString;
algorithm
  outString:=
  match (inVarFlow)
    case DAE.FLOW()          then VAR_FLOW_FLOW;
    case DAE.POTENTIAL()     then VAR_FLOW_NONFLOW;
    case DAE.STREAM()        then VAR_FLOW_NONFLOW;
    case DAE.NON_CONNECTOR() then VAR_FLOW_NONCONNECTOR;
  end match;
end dumpFlowStr;


protected function dumpFunctions "
This function dumps a list of functions
"
  input list<DAE.Function> funcelems;
algorithm
  _ := matchcontinue (funcelems)
    local
    case ({}) then();
    case _
      equation
        dumpStrOpenTag(FUNCTIONS);
        dumpFunctions2(funcelems);
        dumpStrCloseTag(FUNCTIONS);
      then();
  end matchcontinue;
end dumpFunctions;


protected function dumpFunctions2 "
Help function for dumpFunctions
"
  input list<DAE.Function> funcelems;
algorithm
  _ := match (funcelems)
    local
      DAE.Function fun;
      list<DAE.Function> rem_fun;
    case {} then();
    case (fun :: rem_fun)
      equation
        dumpFunctions3(fun);
        dumpFunctions2(rem_fun);
      then();
  end match;
end dumpFunctions2;


protected function dumpFunctions3 "
Help function to dumpFunctions2
"
  input DAE.Function fun;
algorithm
  _:= matchcontinue (fun)
    case DAE.FUNCTION(type_ = DAE.T_FUNCTION(functionAttributes = DAE.FUNCTION_ATTRIBUTES(isBuiltin = DAE.FUNCTION_BUILTIN(_)))) then ();
    case _
      equation
        dumpStrOpenTagAttr(FUNCTION, FUNCTION_NAME, Util.xmlEscape(Absyn.pathStringNoQual(DAEUtil.functionName(fun))));
        dumpStrOpenTag(MODELICA_IMPLEMENTATION);
        Print.printBuf(Util.xmlEscape(DAEDump.dumpFunctionStr(fun)));
        dumpStrCloseTag(MODELICA_IMPLEMENTATION);
        dumpStrCloseTag(FUNCTION);
      then();
    case (_) then();
/*
        dumpStrOpenTag(Function)
        dumpAttribute(name= Absyn.pathStringNoQual(name));
        dumpAttribute(Modelica implementation = DAEDump.dumpFunctionStr(fun));
        dumpStrCloseTag(Function)
*/
   end matchcontinue;
end dumpFunctions3;

protected function dumpIncidenceMatrix
"author: Frenkel TUD 2011-05
  This function dumps a matrix using an xml representation.
<matrix>
     <matrixrow>
          <cn> 0 </cn>
          <cn> 1 </cn>
          <cn> 0 </cn>
     </matrixrow>
     <matrixrow>
     ...
</matrix>"
  input BackendDAE.BackendDAE dae;
algorithm
  dumpStrOpenTag(MathML);
  dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
  dumpStrOpenTag(MathMLMatrix);
  _ := BackendDAEUtil.foldEqSystem(dae,dumpIncidenceMatrixWork,0);
  dumpStrCloseTag(MathMLMatrix);
  dumpStrCloseTag(MATH);
  dumpStrCloseTag(MathML);
end dumpIncidenceMatrix;

protected function dumpIncidenceMatrixWork
"author: Frenkel TUD 2011-05
  wrapper for calling dumpIncidenceMatrix for each equation system"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input Integer inOffset;
  output Integer outOffset;
protected
 BackendDAE.IncidenceMatrix m;
 DAE.FunctionTree funcs;
algorithm
  funcs := BackendDAEUtil.getFunctions(shared);
  (_,m,_) := BackendDAEUtil.getIncidenceMatrixfromOption(syst,BackendDAE.NORMAL(),SOME(funcs));
  _ := Array.fold(m,dumpIncidenceMatrix2,(inOffset,1));
  outOffset := inOffset + arrayLength(m);
end dumpIncidenceMatrixWork;

protected function dumpIncidenceMatrix2 "
Help function to dumpMatrix
"
  input list<Integer> row;
  input tuple<Integer,Integer> inTpl;
  output tuple<Integer,Integer> outTpl;
protected
  Integer offset,c;
algorithm
  (offset,c) := inTpl;
  dumpStrOpenTagAttr(MathMLMatrixrow,"id",intString(c));
  List.map1_0(row,dumpMatrixIntegerRow,offset);
  dumpStrCloseTag(MathMLMatrixrow);
  outTpl := ((offset,c+1));
end dumpIncidenceMatrix2;

protected function dumpMatrixIntegerRow "
Function to print a matrix row of integer elements
using an xml representation, as:
 <cn> integerValue </cn>
 ...
"
  input Integer x;
  input Integer offset;
protected
  Integer e;
  String s;
algorithm
  e := if intGt(x,0) then (x+offset) else (x-offset);
  s := intString(e);
  dumpStrOpenTag(MathMLVariable);
  Print.printBuf(s);
  dumpStrCloseTag(MathMLVariable);
end dumpMatrixIntegerRow;

protected function dumpKind "
This function returns a string containing
the kind of a variable, that could be:
 - Variable
 - State
 - Dummy_der
 - Dummy_state
 - Discrete
 - Parameter
 - Constant
 - ExternalObject:PathRef
"
  input BackendDAE.VarKind inVarKind;
  output String outString;
algorithm
  outString :=
  match (inVarKind)
    local Absyn.Path path; String error_msg;
    case BackendDAE.VARIABLE()     then (VARIABILITY_CONTINUOUS);
    case BackendDAE.STATE()        then (VARIABILITY_CONTINUOUS_STATE);
    case BackendDAE.DUMMY_DER()    then (VARIABILITY_CONTINUOUS_DUMMYDER);
    case BackendDAE.DUMMY_STATE()  then (VARIABILITY_CONTINUOUS_DUMMYSTATE);
    case BackendDAE.DISCRETE()     then (VARIABILITY_DISCRETE);
    case BackendDAE.PARAM()        then (VARIABILITY_PARAMETER);
    case BackendDAE.CONST()        then (VARIABILITY_CONSTANT);
    case BackendDAE.EXTOBJ(path)
      then (stringAppend(VARIABILITY_EXTERNALOBJECT,stringAppend(":",Absyn.pathStringNoQual(path))));
    else
      equation
        error_msg = "in XMLDump.dumpKind - Unknown kind";
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end dumpKind;


protected function dumpList
"Print a list of values given a print
  function."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
    case ({},_)  then ();
    case ({h},r) equation  r(h);  then  ();
    case ((h :: t),r)
      equation
        r(h);
        dumpList(t, r);
      then ();
  end matchcontinue;
end dumpList;


protected function dumpListSeparator
"Print a list of values given a print
  function and a separator string."
  input list<Type_a> inTypeALst;
  input FuncTypeType_aTo inFuncTypeTypeATo;
  input String inString;
  replaceable type Type_a subtypeof Any;
  partial function FuncTypeType_aTo
    input Type_a inTypeA;
  end FuncTypeType_aTo;
algorithm
  _:=
  matchcontinue (inTypeALst,inFuncTypeTypeATo,inString)
    local
      Type_a h;
      FuncTypeType_aTo r;
      list<Type_a> t;
      DAE.Ident sep;
    case ({},_,_)  then ();
    case ({h},r,_) equation  r(h);  then  ();
    case ((h :: t),r,sep)
      equation
        r(h);
        Print.printBuf(sep);
        dumpListSeparator(t, r, sep);
      then ();
  end matchcontinue;
end dumpListSeparator;

protected function printExpStr
  input DAE.Exp e;
  output String s;
algorithm
  s := Util.xmlEscape(ExpressionDump.printExpStr(e));
end printExpStr;

protected function dumpLstInt "
function dumpLsTStr dumps a list
of Integer as a list of XML Element.
The method takes the String list and
the element name as inputs.
The output is:

<ElementName>FirstIntegerOfList</ElementName>
..
<ElementName>LastIntegerOfList</ElementName>

"
  input list<Integer> inLstStr;
  input String inElementName;
algorithm
  _:=
  matchcontinue(inLstStr,inElementName)
      local
        Integer h;
        list<Integer> t;
    case ({},_) then ();
    case ({_},"") then ();
    case ({h},_)
      equation
        dumpStrTagContent(inElementName,intString(h));
    then  ();
    case ((h :: t),_)
      equation
        dumpStrTagContent(inElementName,intString(h));
        dumpLstInt(t,inElementName);
    then();
  end matchcontinue;
end dumpLstInt;


protected function dumpLstIntAttr "
This function, if the list is not empty, prints
the XML delimiters tag of the list.
"
  input list<Integer> lst;
  input String inContent;
  input String inElementContent;
algorithm
  _:= matchcontinue (lst,inContent,inElementContent)
  local
    list<Integer> l;
    String inLst,inEl;
    case ({},_,_) then ();
    case (l,inLst,inEl)
      equation
        dumpStrOpenTag(inLst);
        dumpLstInt(l,inEl);
        dumpStrCloseTag(inLst);
      then();
  end matchcontinue;
end dumpLstIntAttr;

protected function dumpMatching
"author: Frenkel TUD 2011-05
  prints the matching information on stdout."
  input BackendDAE.BackendDAE dae;
algorithm
  dumpStrOpenTag(MATCHING_ALGORITHM);
  _ := BackendDAEUtil.foldEqSystem(dae,dumpMatchingWork,(0,0));
  dumpStrCloseTag(MATCHING_ALGORITHM);
end dumpMatching;

protected function dumpMatchingWork
"author: Frenkel TUD 2011-05
  wrapper for calling dumpMatching for each equation system"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer,Integer> inOffset;
  output tuple<Integer,Integer> outOffset;
protected
 array<Integer> v1,v2;
 Integer voffset,eoffset;
algorithm
  BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(v1,v2,_)) := syst;
  (voffset,eoffset) := inOffset;
  dumpMatching1(v1,voffset,eoffset);
  outOffset := ((voffset + arrayLength(v1),eoffset + arrayLength(v2)));
end dumpMatchingWork;

protected function dumpMatching1
"author: PA
  prints the matching information on stdout."
  input array<Integer> v;
  input Integer voffset;
  input Integer eoffset;
algorithm
   _:=
  matchcontinue(v,voffset,eoffset)
  case(_,_,_)
    equation
      false = intGt(arrayLength(v),0);
    then();
  case(_,_,_)
    equation
      true = intGt(arrayLength(v),0);
      _ = Array.fold(v,dumpMatching2,(1,voffset,eoffset));
  then();
    end matchcontinue;
end dumpMatching1;


protected function dumpMatching2
"Helper function to dumpMatching."
  input Integer eqn;
  input tuple<Integer,Integer,Integer> inTpl;
  output tuple<Integer,Integer,Integer> outTpl;
protected
  Integer v,voffset,eoffset;
  String s,s2;
algorithm
  (v,voffset,eoffset) := inTpl;
  s := intString(v+voffset);
  s2 := intString(eqn+eoffset);
  Print.printBuf(stringAppendList({"\n<",SOLVED_IN," ",VARIABLE,ID_,"=\"",s,"\" ",EQUATION,ID_,"=\"",s2,"\" ","/>"}));
  outTpl := ((v+1,voffset,eoffset));
end dumpMatching2;


protected function dumpOptExp "
This function print to a new line the content of
a Optional<DAE.Exp> in a XML element like:
<Content =ExpressionDump.printExpStr(e)/>. It also print
the content of the expression as MathML like:
<MathML><MATH xmlns=...>DAE.Exp</MATH></MathML>.
See dumpExp function for more details.
"
  input Option<DAE.Exp> inExpExpOption;
  input String Content;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inExpExpOption,Content,addMathMLCode)
    local
      DAE.Exp e;
    case (NONE(),_,_) then ();
    case (SOME(e),_,_)
      equation
        dumpStrOpenTagAttr(Content,EXP_STRING,printExpStr(e));
        dumpExp(e,addMathMLCode);
        dumpStrCloseTag(Content);
      then ();
  end match;
end dumpOptExp;

protected function dumpOptInteger "
This function print to a new line the content of
a Optional<Integer> in a XML element like:
<Content index = intString(e)/>.
"
  input Option<Integer> inOption;
  input String Content;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inOption,Content,addMathMLCode)
    local
      Integer i;

    case (NONE(),_,_) then ();

    case (SOME(i),_,_)
      equation
        dumpStrOpenTagAttr(Content,INDEX,intString(i));
        dumpStrCloseTag(Content);
      then ();

  end match;
end dumpOptInteger;

protected function dumpOptionDAEStateSelect "
This function is used to print in a new line
an element corresponding to the StateSelection
choice of a variable. Depending from the String
input, that defines the element's name, the
element is something like:
<Content=StateSelection/>,
"
  input Option<DAE.StateSelect> ss;
  input String Content;
algorithm
  _ :=
  match (ss,Content)
    case (NONE(),_)
      equation
        Print.printBuf("");
      then ();
    case (SOME(DAE.NEVER()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_NEVER);   then ();
    case (SOME(DAE.AVOID()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_AVOID);   then ();
    case (SOME(DAE.DEFAULT()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_DEFAULT); then ();
    case (SOME(DAE.PREFER()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_PREFER);  then ();
    case (SOME(DAE.ALWAYS()),_)
      equation dumpStrTagContent(Content, STATE_SELECT_ALWAYS);  then ();
  end match;
end dumpOptionDAEStateSelect;


protected function dumpOptValue "
 This function print an Optional Values.Value variable
as one attribute of a within a specific XML element.
It takes the optional Values.Value and element name
as input an prints on a new line a string to the
standard output like:
<Content = \"ExpressionDump.printExpStr(ValuesUtil.valueExp(Optional<Values.Value>)/>
"
  input Option<Values.Value> inValueValueOption;
  input String Content;
  input Boolean addMathMLCode;
algorithm
  _ :=
  match (inValueValueOption,Content,addMathMLCode)
    local
      Values.Value v;
      Boolean addMMLCode;
    case (NONE(),_,_)  then ();
    case (SOME(v),_,addMMLCode)
      equation
        dumpStrOpenTagAttr(Content,EXP_STRING,printExpStr(ValuesUtil.valueExp(v)));
        dumpExp(ValuesUtil.valueExp(v),addMMLCode);
        dumpStrCloseTag(Content);
      then ();
  end match;
end dumpOptValue;


protected function dumpRow
"Prints a list of expressions to a string."
  input list<DAE.Exp> es_1;
  annotation(__OpenModelica_EarlyInline=true);
algorithm
  dumpList(es_1, dumpExp2);
end dumpRow;


protected function dumpSolvingInfo "
  Function necessary to print additional information
  that are useful for solving a DAE system, such as:
  - matching algorithm output
  - BLT form
  This is done using a xml representation such as:
  <AdditionalInfo>
    <SolvingInfo>
      <MatchingAlgorithm>
        <SolvedIn variableID=\"\" equationID=\"\"/>
        ...
        <SolvedIn variableID=\"\" equationID=\"\"/>
      </MatchingAlgorithm>
      <BLTRepresentation>
        <Block id=\"\">
          <InvolvedEquation equationID=\"\"/>
          ....
        </Block>
        ....
      </BLTRepresentation>
    </SolvingInfo>
  </AdditionalInfo>
  "
  input Boolean addOriginalIncidenceMatrix;
  input Boolean addSolvingInfo;
  input BackendDAE.BackendDAE inBackendDAE;
algorithm
  _:=
  match (addOriginalIncidenceMatrix,addSolvingInfo,inBackendDAE)
    local
      BackendDAE.BackendDAE dlow;
  case (false,false,_) then ();
  case (true,true,_)
    equation
      dlow = BackendDAEUtil.transformBackendDAE(inBackendDAE,NONE(),NONE(),NONE());
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpIncidenceMatrix(dlow);
      dumpStrCloseTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpStrOpenTag(SOLVING_INFO);
      dumpMatching(dlow);
      dumpComponents(dlow);
      dumpStrCloseTag(SOLVING_INFO);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  case (true,false,_)
    equation
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpIncidenceMatrix(inBackendDAE);
      dumpStrCloseTag(ORIGINAL_INCIDENCE_MATRIX);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  case (false,true,_)
    equation
      dlow = BackendDAEUtil.transformBackendDAE(inBackendDAE,NONE(),NONE(),NONE());
      dumpStrOpenTag(ADDITIONAL_INFO);
      dumpStrOpenTag(SOLVING_INFO);
      dumpMatching(dlow);
      dumpComponents(dlow);
      dumpStrCloseTag(SOLVING_INFO);
      dumpStrCloseTag(ADDITIONAL_INFO);
    then ();
  end match;
end dumpSolvingInfo;

protected function transformModelicaIdentifierToXMLElementTag
  input String modelicaIdentifier;
  output String xmlElementTag;
algorithm
  // XML element names cannot handle $ in identifiers
  // TODO! FIXME!, there are many other characters valid in Modelica
  // function names and identifiers that aren't valid in XML element tags.
  xmlElementTag := System.stringReplace(modelicaIdentifier, "$", "_dollar_");

  // TODO! FIXME!, we have issues with accented chars in comments
  // that end up in the Model_init.xml file and makes it not well
  // formed but the line below does not work if the xmlElementTag is
  // already UTF-8. We should somehow detect the encoding.
  // xmlElementTag := System.iconv(xmlElementTag, "", "UTF-8");

end transformModelicaIdentifierToXMLElementTag;

protected function dumpStrCloseTag "
  Function necessary to print the end of an
  XML element. The XML element's name is passed as
  a parameter. The result is to print on a new line
  a string like:
  </Content>
  "
  input String inContent;
algorithm
  _:=
  matchcontinue (inContent)
      local String inString;
  case ("")
    equation
    then ();
  case (inString)
    equation
      Print.printBuf("\n</");Print.printBuf(transformModelicaIdentifierToXMLElementTag(inString));Print.printBuf(">");
    then ();
  end matchcontinue;
end dumpStrCloseTag;

protected function dumpStreamStr "
This function returns a string with
the content of the stream type of a variable.
It could be:
 - Stream
 - NonStream
 - NonStreamConnector
"
  input DAE.ConnectorType inVarStream;
  output String outString;
algorithm
  outString:=
  match (inVarStream)
    case DAE.STREAM()               then VAR_STREAM_STREAM;
    case DAE.POTENTIAL()            then VAR_STREAM_NONSTREAM;
    case DAE.FLOW()                 then VAR_STREAM_NONSTREAM;
    case DAE.NON_CONNECTOR()        then VAR_STREAM_NONSTREAM_CONNECTOR;
  end match;
end dumpStreamStr;

protected function dumpStrMathMLNumber "
This function prints a new MathML element
containing a number, like:
<cn> inNumber </cn>
"
  input String inNumber;
algorithm
  dumpStrOpenTag(MathMLNumber);
  Print.printBuf(" ");Print.printBuf(inNumber);Print.printBuf(" ");
  dumpStrCloseTag(MathMLNumber);
end dumpStrMathMLNumber;


protected function dumpStrMathMLNumberAttr "
This function prints a new MathML element
containing a number and one of its attributes,
like:
<cn inAttribute=\"inAttributeValue\"> inNumber
</cn>
"
  input String inNumber;
  input String inAttribute;
  input String inAttributeContent;
algorithm
  dumpStrOpenTagAttr(MathMLNumber, inAttribute, inAttributeContent);
  Print.printBuf(" ");Print.printBuf(inNumber);Print.printBuf(" ");
  dumpStrCloseTag(MathMLNumber);
end dumpStrMathMLNumberAttr;


protected function dumpStrMathMLVariable"
This function prints a new MathML element
containing a variable (identifier), like:
<ci> inVariable </ci>
"
  input String inVariable;
algorithm
  dumpStrOpenTag(MathMLVariable);
  Print.printBuf(" ");Print.printBuf(inVariable);Print.printBuf(" ");
  dumpStrCloseTag(MathMLVariable);
end dumpStrMathMLVariable;


protected function dumpStrOpenTag "
  Function necessary to print the begin of a new
  XML element. The XML element's name is passed as
  a parameter. The result is to print on a new line
  a string like:
  <Content>
  "
  input String inContent;
algorithm
  _:=
  matchcontinue (inContent)
      local String inString;
  case ("")
    equation
      Print.printBuf("");
    then ();
  case (inString)
    equation
      Print.printBuf("\n<");Print.printBuf(transformModelicaIdentifierToXMLElementTag(inString));Print.printBuf(">");
    then ();
  end matchcontinue;
end dumpStrOpenTag;


protected function dumpStrOpenTagAttr "
  Function necessary to print the begin of a new
  XML element containing an attribute. The XML
  element's name, the name and the content of the
  element's attribute are passed as String inputs.
  The result is to print on a new line
  a string like:
  <Content Attribute=AttributeContent>
  "
  input String inContent;
  input String Attribute;
  input String AttributeContent;
algorithm
  _:=
  matchcontinue (inContent,Attribute,AttributeContent)
      local String inString,inAttribute,inAttributeContent;
  case ("",_,_)  equation  Print.printBuf("");  then();
  case (_,"",_)  equation  Print.printBuf("");  then();
  case (_,_,"")  equation  Print.printBuf("");  then();
  case (inString,"",_)  equation dumpStrOpenTag(transformModelicaIdentifierToXMLElementTag(inString));  then ();
  case (inString,_,"")  equation dumpStrOpenTag(transformModelicaIdentifierToXMLElementTag(inString));  then ();
  case (inString,_,inAttributeContent)
    equation
      Print.printBuf("\n<");Print.printBuf(transformModelicaIdentifierToXMLElementTag(inString));Print.printBuf(" ");Print.printBuf(Attribute);Print.printBuf("=\"");Print.printBuf(inAttributeContent);Print.printBuf("\">");
    then();
  end matchcontinue;
end dumpStrOpenTagAttr;


protected function dumpStrTagAttrNoChild "
  Function necessary to print a new
  XML element containing an attribute. The XML
  element's name, the name and the content of the
  element's attribute are passed as String inputs.
  The result is to print on a new line
  a string like:
  <Content Attribute=AttributeContent>
  "
  input String inContent;
  input String Attribute;
  input String AttributeContent;
algorithm
  _:=
  matchcontinue (inContent,Attribute,AttributeContent)
      local String inString,inAttribute,inAttributeContent;
  case ("",_,_)  equation  Print.printBuf("");  then();
  case (_,"",_)  equation  Print.printBuf("");  then();
  case (_,_,"")  equation  Print.printBuf("");  then();
  case (inString,"",_)  equation dumpStrOpenTag(transformModelicaIdentifierToXMLElementTag(inString));  then ();
  case (inString,_,"")  equation dumpStrOpenTag(transformModelicaIdentifierToXMLElementTag(inString));  then ();
  case (inString,_,inAttributeContent)
    equation
      Print.printBuf("\n<");Print.printBuf(transformModelicaIdentifierToXMLElementTag(inString));Print.printBuf(" ");Print.printBuf(Attribute);Print.printBuf("=\"");Print.printBuf(inAttributeContent);Print.printBuf("\" />");
    then();
  end matchcontinue;
end dumpStrTagAttrNoChild;


protected function dumpStrTagContent "
  Function necessary to print an XML element
  with a String content. The XML element's name
  and the content are passed as String inputs.
  The result is to print on a new line
  a string like:
  <inElementName>inContent</inElementName>
  "
  input String inElementName;
  input String inContent;
algorithm
  _:=
  matchcontinue (inElementName,inContent)
      local String inTagString,inTagContent;
  case ("",_)  then ();
  case (_,"")  then ();
  case (inTagString,inTagContent)
    equation
      dumpStrOpenTag(inTagString);
      Print.printBuf("\n");Print.printBuf(inTagContent);
      dumpStrCloseTag(inTagString);
    then ();
  end matchcontinue;
end dumpStrTagContent;


protected function dumpStrVoidTag
"
This function takes as input the name
of the void element to print and then
print on a new line an XML code like:
<ElementName/>
"
  input String inElementName;
algorithm
  _:=matchcontinue(inElementName)
  local String ElementName;
    case("") then();
    case(ElementName)
      equation
         Print.printBuf("\n<");
         Print.printBuf(transformModelicaIdentifierToXMLElementTag(ElementName));
         Print.printBuf("/>");
      then();
  end matchcontinue;
end dumpStrVoidTag;

protected function dumpDimension "
This function print an DAE.Dimension eventually
using the ExpressionDump.printExpStr function.
"
  input DAE.Dimension inDimension;
algorithm
  _:=
  match (inDimension)
    local DAE.Exp e1;
      Integer i;
    case DAE.DIM_INTEGER(i)
      equation
        Print.printBuf(intString(i));
      then
        ();
    case DAE.DIM_ENUM(_,_,_)
      equation
        Print.printBuf("Dim Enum");
      then
        ();
    case DAE.DIM_EXP(e1)
      equation
        Print.printBuf(printExpStr(e1));
      then
        ();
    case DAE.DIM_UNKNOWN()
      equation
        Print.printBuf(":");
      then
        ();
  end match;
end dumpDimension;


protected function dumpTypeStr "
This function output the Type of a variable, it could be:
 - Integer
 - Real
 - Boolean
 - String
 - Enum
 "
  input BackendDAE.Type inType;
  output String outString;
algorithm
  outString:=
  match (inType)
    local
      DAE.Ident s1,s2,str;
      list<DAE.Ident> l;
    case DAE.T_INTEGER() then VARTYPE_INTEGER;
    case DAE.T_REAL()    then VARTYPE_REAL;
    case DAE.T_BOOL()    then VARTYPE_BOOLEAN;
    case DAE.T_STRING()  then VARTYPE_STRING;
    case DAE.T_ENUMERATION(names = l)
      equation
        s1 = stringDelimitList(l, ", ");
        s2 = stringAppend(VARTYPE_ENUMERATION,stringAppend("(", s1));
        str = stringAppend(s2, ")");
      then
        str;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(_))
      then VARTYPE_EXTERNALOBJECT;
  end match;
end dumpTypeStr;


protected function dumpVariable "
This function print to the standard output the
content of a variable. In particular it takes:
* varno: the variable number
* cr: the var name
* kind: variable, state, dummy_der, dummy_state,..
* dir: input, output or bi-directional
* var_type: builtin type or enumeration
* indx: if this is a state, how often this states was differentiated
* derName: if this is a state, the derivative name
* old_name: the original name of the variable
* varFixed: fixed attribute for variables (default fixed
  value is used if not found. Default is true for parameters
  (and constants) and false for variables)
* flowPrefix: tells if it's a flow variable or not
* streamPrefix: tells if it's a stream variable or not
* comment: a comment associated to the variable.
Please note that all the inputs must be passed as String variables.
"
  input String varno,cr,kind,dir,var_type,indx,derName,varFixed,flowPrefix,streamPrefix,comment;
algorithm
  _:=
  matchcontinue (varno,cr,kind,dir,var_type,indx,derName,varFixed,flowPrefix,streamPrefix,comment)
      //local String str;
    case (_,_,_,_,_,_,_,_,_,_,"")
    equation
    /*
      str= stringAppendList({"\n<Variable id=\"",varno,"\" name=\"",cr,"\" varKind=\"",kind,"\" varDirection=\"",dir,"\" varType=\"",var_type,"\" index=\"",indx,"\" derName=derName,origName=\"",
            old_name,"\" fixed=\"",varFixed,"\" flow=\"",flowPrefix,"\" stream=\"",streamPrefix,"\">"});
    then str;
    */
      Print.printBuf("\n<");Print.printBuf(VARIABLE);Print.printBuf(" ");Print.printBuf(VAR_ID);Print.printBuf("=\"");Print.printBuf(varno);
      Print.printBuf("\" ");Print.printBuf(VAR_NAME);Print.printBuf("=\"");Print.printBuf(cr);
      Print.printBuf("\" ");Print.printBuf(VAR_VARIABILITY);Print.printBuf("=\"");Print.printBuf(kind);
      Print.printBuf("\" ");Print.printBuf(VAR_DIRECTION);Print.printBuf("=\"");Print.printBuf(dir);
      Print.printBuf("\" ");Print.printBuf(VAR_TYPE);Print.printBuf("=\"");Print.printBuf(var_type);
      printIndexAndDerName(indx, derName);
      Print.printBuf("\" ");Print.printBuf(VAR_FIXED);Print.printBuf("=\"");Print.printBuf(varFixed);
      Print.printBuf("\" ");Print.printBuf(VAR_FLOW);Print.printBuf("=\"");Print.printBuf(flowPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_STREAM);Print.printBuf("=\"");Print.printBuf(streamPrefix);
      Print.printBuf("\">");
    then();
    case (_,_,_,_,_,_,_,_,_,_,_)
    equation
      Print.printBuf("\n<");Print.printBuf(VARIABLE);Print.printBuf(" ");Print.printBuf(VAR_ID);Print.printBuf("=\"");Print.printBuf(varno);
      Print.printBuf("\" ");Print.printBuf(VAR_NAME);Print.printBuf("=\"");Print.printBuf(cr);
      Print.printBuf("\" ");Print.printBuf(VAR_VARIABILITY);Print.printBuf("=\"");Print.printBuf(kind);
      Print.printBuf("\" ");Print.printBuf(VAR_DIRECTION);Print.printBuf("=\"");Print.printBuf(dir);
      Print.printBuf("\" ");Print.printBuf(VAR_TYPE);Print.printBuf("=\"");Print.printBuf(var_type);
      printIndexAndDerName(indx, derName);
      Print.printBuf("\" ");Print.printBuf(VAR_FIXED);Print.printBuf("=\"");Print.printBuf(varFixed);
      Print.printBuf("\" ");Print.printBuf(VAR_FLOW);Print.printBuf("=\"");Print.printBuf(flowPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_STREAM);Print.printBuf("=\"");Print.printBuf(streamPrefix);
      Print.printBuf("\" ");Print.printBuf(VAR_COMMENT);Print.printBuf("=\"");Print.printBuf(Util.xmlEscape(comment));
      Print.printBuf("\">");
    then ();
      /*
      str= stringAppendList({"\n<Variable id=\"",varno,"\" name=\"",cr,"\" varKind=\"",kind,"\" varDirection=\"",dir,"\" varType=\"",var_type,"\" index=\"",indx,"\" origName=\"",
            old_name,"\" fixed=\"",varFixed,"\" flow=\"",flowPrefix,"\"  stream=\"",streamPrefix,"\" comment=\"",comment,"\">"});
    then str;
    */
  end matchcontinue;
end dumpVariable;

protected function printIndexAndDerName
  input String indx;
  input String derName;
algorithm
  _ := match(indx, derName)
    case ("", "") then ();
    case (_, "")
      equation
        Print.printBuf("\" ");Print.printBuf(VAR_INDEX);Print.printBuf("=\"");Print.printBuf(indx);
      then
        ();
    case ("", _)
      equation
        Print.printBuf("\" ");Print.printBuf(VAR_DERNAME);Print.printBuf("=\"");Print.printBuf(derName);
      then
        ();
    case (_, _)
      equation
        Print.printBuf("\" ");Print.printBuf(VAR_INDEX);Print.printBuf("=\"");Print.printBuf(indx);
        Print.printBuf("\" ");Print.printBuf(VAR_DERNAME);Print.printBuf("=\"");Print.printBuf(derName);
      then
        ();
  end match;
end printIndexAndDerName;

protected function dumpVarsAdditionalInfo "
This function dumps the additional info that a
variable could contain in a XML format.
The output is very simple and is like:
<ADDITIONAL_INFO>
  <CfresList>
    ...
  </CrefList>
  <StringList>
    ...
  </StringList>
</ADDITIONAL_INFO>
"

  input array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
  input Integer i;
algorithm
    _ := matchcontinue (crefIdxLstArr,i)
    local String error_msg;
    case (_,_)
      equation
        listLength(crefIdxLstArr[1]) >= 1  = false;
      then ();
    case (_,_)
      equation
        listLength(crefIdxLstArr[1]) >= 1  = true;
        dumpStrOpenTag(ADDITIONAL_INFO);
        dumpCrefIdxLstArr(crefIdxLstArr,HASH_TB_CREFS_LIST,i);
        dumpStrCloseTag(ADDITIONAL_INFO);
      then ();
    else
      equation
        error_msg = "in XMLDump.dumpVarsAdditionalInfo - Unknown info";
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then ();
  end matchcontinue;
end dumpVarsAdditionalInfo;


protected function dumpVars "
This function prints a list of Var in a XML format. If the
list is not empty (in that case nothing is printed) the output
is:
<Content DIMENSION=...>
  <VariableList>
    ...
  </VariableList>
</Content>
"
  input list<BackendDAE.Var> vars;
  input array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
  input String Content;
  input Boolean addMathMLCode;
algorithm
  _ := matchcontinue (vars,crefIdxLstArr,Content,addMathMLCode)
    local
      Integer len;
      Boolean addMMLCode;
    case ({},_,_,_)
      then();
    case (_,_,_,_)
      equation
        len = listLength(vars);
        len >= 1 = false;
      then ();
    case (_,_,_,addMMLCode)
      equation
        len = listLength(vars);
        len >= 1 = true;
        listLength(crefIdxLstArr[1]) >= 1  = true;
        dumpStrOpenTagAttr(Content,DIMENSION,intString(len));
        dumpStrOpenTag(stringAppend(VARIABLES,LIST_));
        // uncomment because it is not correct implemented,crefIdxLstArr and strIdxLstArr
        // are used in a wrong way
        //dumpVarsAdds2(vars,crefIdxLstArr,strIdxLstArr,1,addMMLCode);
        dumpVars2(vars,1,addMMLCode);
        dumpStrCloseTag(stringAppend(VARIABLES,LIST_));
        dumpStrCloseTag(Content);
      then();
    case (_,_,_,addMMLCode)
      equation
        len = listLength(vars);
        len >= 1 = true;
        listLength(crefIdxLstArr[1]) >= 1  = false;
        dumpStrOpenTagAttr(Content,DIMENSION,intString(len));
        dumpStrOpenTag(stringAppend(VARIABLES,LIST_));
        dumpVars2(vars,1,addMMLCode);
        dumpStrCloseTag(stringAppend(VARIABLES,LIST_));
        dumpStrCloseTag(Content);
      then ();
    case (_,_,_,_)
      equation
        len = listLength(vars);
        len >= 1 = false;
    then ();
  end matchcontinue;
end dumpVars;

protected function getIndex
  input BackendDAE.VarKind kind;
  output String diffIndex;
algorithm
  diffIndex := match(kind)
    local Integer di;
    case (BackendDAE.STATE(index=di)) then intString(di);
    else "";
  end match;
end getIndex;

protected function getDerName
  input BackendDAE.VarKind kind;
  output String derName;
algorithm
  derName := match(kind)
    local String dn; DAE.ComponentRef cr;
    case (BackendDAE.STATE(derName=SOME(cr)))
      equation
        dn = ComponentReference.printComponentRefStr(cr);
      then dn;
    else "";
  end match;
end getDerName;

protected function dumpVars2 "
This function is one of the two help function to the
dumpVar method. The two help functions differ from
the number of the output. This function is used for
printing the content of a variable with no AdditionalInfo.
See dumpVariable for more details on the XML output.
"
  input list<BackendDAE.Var> inVarLst;
  input Integer inInteger;
  input Boolean addMathMLCode;
algorithm
  _ := match (inVarLst,inInteger,addMathMLCode)
    local
      Integer varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.InstDims arry_Dim;
      Option<Values.Value> b;
      Integer var_1;
      Boolean addMMLCode;
      DAE.ElementSource source "the origin of the element";

    case ({},_,_) then ();
    case (((v as BackendDAE.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            bindValue = b,
                            source = source,
                            values = dae_var_attr,
                            comment = comment,
                            connectorType = ct)) :: xs),varno,addMMLCode)
      equation
        dumpVariable(intString(varno),ComponentReference.printComponentRefStr(cr),dumpKind(kind),dumpDirectionStr(dir),dumpTypeStr(var_type),
                     getIndex(kind),getDerName(kind),boolString(BackendVariable.varFixed(v)),dumpFlowStr(ct),
                     dumpStreamStr(ct),unparseCommentOptionNoAnnotation(comment));
        dumpBindValueExpression(e,b,addMMLCode);
        //The command below adds information to the XML about the dimension of the
        //containing vector, in the casse the variable is an element of a vector.
        //dumpDAEInstDims(arry_Dim,"ArrayDims");
        paths = ElementSource.getElementSourceTypes(source);
        dumpAbsynPathLst(paths,stringAppend(CLASSES,NAMES_));
        dumpDAEVariableAttributes(dae_var_attr,VAR_ATTRIBUTES_VALUES,addMMLCode);
        dumpStrCloseTag(VARIABLE);
        var_1=varno+1;
        dumpVars2(xs,var_1,addMMLCode);
      then ();
  end match;
end dumpVars2;


protected function dumpVarsAdds2 "
This function is one of the two help function to the
dumpVar method. The two help functions differ from
the number of the output. This function is used for
printing the content of a variable with AdditionalInfo.
See dumpVariable for more details on the XML output.
"
  input list<BackendDAE.Var> inVarLst;
  input array<list<BackendDAE.CrefIndex>> crefIdxLstArr;
  input Integer inInteger;
  input Boolean addMMLCode;
algorithm
  _ := match (inVarLst,crefIdxLstArr,inInteger,addMMLCode)
    local
      Integer varno;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      Option<DAE.Exp> e;
      list<Absyn.Path> paths;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.ConnectorType ct;
      list<BackendDAE.Var> xs;
      BackendDAE.Type var_type;
      DAE.InstDims arry_Dim;
      Option<Values.Value> b;
      Integer var_1;
      DAE.ElementSource source;
      String error_msg;

    case ({},_,_,_) then ();

    case (((v as BackendDAE.VAR(varName = cr,
                            varKind = kind,
                            varDirection = dir,
                            varType = var_type,
                            bindExp = e,
                            bindValue = b,
                            source = source,
                            values = dae_var_attr,
                            comment = comment,
                            connectorType = ct)) :: xs),_,varno,_)
      equation
        dumpVariable(intString(varno),ComponentReference.printComponentRefStr(cr),dumpKind(kind),dumpDirectionStr(dir),dumpTypeStr(var_type),
                        getIndex(kind),getDerName(kind),boolString(BackendVariable.varFixed(v)),dumpFlowStr(ct),dumpStreamStr(ct),
                        DAEDump.dumpCommentAnnotationStr(comment));
        dumpBindValueExpression(e,b,addMMLCode);
        //The command below adds information to the XML about the dimension of the
        //containing vector, in the casse the variable is an element of a vector.
        //dumpDAEInstDims(arry_Dim,"ArrayDims");
        paths = ElementSource.getElementSourceTypes(source);
        dumpAbsynPathLst(paths,stringAppend(CLASSES,NAMES_));
        dumpDAEVariableAttributes(dae_var_attr,VAR_ATTRIBUTES_VALUES,addMMLCode);
        dumpVarsAdditionalInfo(crefIdxLstArr,varno);
        dumpStrCloseTag(VARIABLE);
        var_1 = varno+1;
        dumpVarsAdds2(xs,crefIdxLstArr,var_1,addMMLCode);
      then ();

    case (_::xs,_,varno,_)
      equation
        error_msg = "in XMLDump.dumpVarsAdds2 - Unknown var: ";
        error_msg = error_msg + intString(varno);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
        var_1 = varno+1;
        dumpVarsAdds2(xs,crefIdxLstArr,var_1,addMMLCode);
      then
        ();

  end match;
end dumpVarsAdds2;

protected function dumpWhenOperators "
This function prints the list of WhenOperators
elements in a XML format. It takes also as input
a string in order to know what is the content of
the zero crossing list. The output is:
<WhenOperators DIMENSION=...>
...
</WhenOperators>
"
  input list<BackendDAE.WhenOperator> inWhenOperators;
  input String inContent;
  input Boolean addMathMLCode;
algorithm
  _:=
  matchcontinue (inWhenOperators,inContent,addMathMLCode)
    local
      Integer len;
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> lst;
      Option<Integer> elseClause;

    case ({},_,_) then ();

    case (lst, _, _)
      equation
        len = listLength(lst);
        len >= 1 = false;
      then ();

    case (lst, _, _)
      equation
        len = listLength(lst);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpWhenOperatorLst(lst, addMathMLCode);
        dumpStrCloseTag(inContent);
      then ();

  end matchcontinue;
end dumpWhenOperators;

protected function dumpWhenOperatorLst "
This function prints the content of a when clause
 "
  input list<BackendDAE.WhenOperator> inWhenOperators;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inWhenOperators,addMathMLCode)
    local
      DAE.ComponentRef stateVar, left;
      DAE.Exp cond, msg, level, e, value, call;
      list<DAE.Exp> exps;
      list<BackendDAE.WhenOperator> lst;
      String str, s1, s2;
      Absyn.Path fn;

    case ({}, _) then ();

    case (BackendDAE.ASSIGN(left, value, _) :: lst, true)
      equation
        s1 = ComponentReference.printComponentRefStr(left);
        s2 = printExpStr(value);
        str = stringAppendList({s1," := ",s2});

        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrMathMLVariable(s1);
        dumpExp2(value);
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();


    case (BackendDAE.ASSIGN(left, value, _) :: lst, false)
      equation
        s1 = ComponentReference.printComponentRefStr(left);
        s2 = printExpStr(value);
        str = stringAppendList({s1," := ",s2});

        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();

    case (BackendDAE.REINIT(stateVar, value, _) :: lst, _)
      equation
        e = Expression.makeCrefExp(stateVar, DAE.T_UNKNOWN_DEFAULT);
        call = DAE.CALL(
          Absyn.IDENT(REINIT), {e, value},
          DAE.callAttrBuiltinOther);
        str = printExpStr(call);

        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpExp(call, addMathMLCode);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();

    case (BackendDAE.ASSERT(cond, msg, level, _) :: lst, _)
      equation
        call = DAE.CALL(
          Absyn.IDENT(ASSERT), {cond, msg, level},
          DAE.callAttrBuiltinOther);
        str = printExpStr(call);

        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpExp(call, addMathMLCode);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();

    case (BackendDAE.TERMINATE(msg, _) :: lst, _)
      equation
        call = DAE.CALL(
          Absyn.IDENT(TERMINATE), {msg},
          DAE.callAttrBuiltinOther);
        str = printExpStr(call);

        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpExp(call, addMathMLCode);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();

    case (BackendDAE.NORETCALL(exp=call) :: lst, _)
      equation
        str = printExpStr(call);
        dumpStrOpenTag(WHEN_OPERATOR);
        Print.printBuf("\n");
        Print.printBuf(str);
        dumpExp(call, addMathMLCode);
        dumpStrCloseTag(WHEN_OPERATOR);

        dumpWhenOperatorLst(lst, addMathMLCode);

      then
        ();

  end match;
end dumpWhenOperatorLst;

protected function dumpTimeEvents "
This function prints the list of Samples
elements in a XML format. It takes also as input
a string in order to know what is the content of
the zero crossing list. The output is:
<Samples DIMENSION=...>
...
</Samples>
"
  input list<BackendDAE.TimeEvent> inTimeEvents;
  input String inContent;
  input Boolean addMathMLCode;
algorithm
  _:=
  matchcontinue (inTimeEvents,inContent,addMathMLCode)
    local
      Integer len;
      list<tuple<Integer, .DAE.Exp, .DAE.Exp>> samples;


    case ({},_,_) then ();

    case (_,_,_)
      equation
        len = listLength(inTimeEvents);
        len >= 1 = false;
      then();

    case (_,_,_)
      equation
        len = listLength(inTimeEvents);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpSampleLst(inTimeEvents, addMathMLCode);
        dumpStrCloseTag(inContent);
      then ();

  end matchcontinue;
end dumpTimeEvents;

protected function dumpSampleLst "
  This function prints the content of a Samples list
  of elements, including the information regarding the origin
  of the zero crossing elements in XML format. The output is:
  <stringAppend(Samples,ELEMENT_)>
    <index value = i>
    <start string = exp>
    <interval string = exp>
  </stringAppend(Samples,ELEMENT_)>"
  input list<BackendDAE.TimeEvent> inSamples;
  input Boolean addMathMLCode;
algorithm
  _ := match (inSamples, addMathMLCode)
    local
      DAE.Exp e1, e2;
      Integer i;
      Boolean addMMLCode;
      list<BackendDAE.TimeEvent> lst;

    case ({}, _) then ();

    case (BackendDAE.SIMPLE_TIME_EVENT()::lst, addMMLCode)
      equation
        /* TODO */

        dumpSampleLst(lst,addMMLCode);
      then ();

    case (BackendDAE.SAMPLE_TIME_EVENT(i, e1, e2)::lst, addMMLCode)
      equation
        dumpStrOpenTag(stringAppend(SAMPLES, ELEMENT_));

        dumpStrOpenTagAttr(INDEX, VALUE, intString(i));
        dumpExp(e1, addMMLCode);
        dumpStrCloseTag(INDEX);

        dumpStrOpenTagAttr(START, EXP_STRING, printExpStr(e1));
        dumpExp(e1, addMMLCode);
        dumpStrCloseTag(START);

        dumpStrOpenTagAttr(INTERVAL, EXP_STRING, printExpStr(e2));
        dumpExp(e2, addMMLCode);
        dumpStrCloseTag(INTERVAL);

        dumpStrCloseTag(stringAppend(SAMPLES, ELEMENT_));
        dumpSampleLst(lst, addMMLCode);
      then ();
  end match;
end dumpSampleLst;

protected function dumpZeroCrossing "
  This function prints the list of ZeroCrossing
  elements in a XML format. It takes also as input
  a string in order to know what is the content of
  the zero crossing list. The output is:
  <zeroCrossings DIMENSION=...>
  ...
  </zeroCrossings>"
  input list<BackendDAE.ZeroCrossing> zeroCross;
  input String inContent;
  input Boolean addMathMLCode;
algorithm
  _:=
  matchcontinue (zeroCross,inContent,addMathMLCode)
    local
      Integer len;
    case ({},_,_) then ();
    case (_,_,_)
      equation
        len = listLength(zeroCross);
        len >= 1 = false;
      then();
    case (_,_,_)
      equation
        len = listLength(zeroCross);
        len >= 1 = true;
        dumpStrOpenTagAttr(inContent, DIMENSION, intString(len));
        dumpZcLst(zeroCross,addMathMLCode);
        dumpStrCloseTag(inContent);
      then ();
  end matchcontinue;
end dumpZeroCrossing;

protected function dumpZcLst "
This function prints the content of a ZeroCrossing list
of elements, including the information regarding the origin
of the zero crossing elements in XML format. The output is:
<stringAppend(ZERO_CROSSING,ELEMENT_) EXP_STRING=DAE.Exp>
  <MathML>
    <MATH>
      ...
    </MATH>
  </MathML>
  <stringAppend(INVOLVED,EQUATIONS_)>
    <stringAppend(EQUATION,ID_)>FirstEquationNo</stringAppend(EQUATION,ID_)>
    ...
    <stringAppend(EQUATION,ID_)>LastEquationNo</stringAppend(EQUATION,ID_)>
  </stringAppend(INVOLVED,EQUATIONS_)>
  <stringAppend(INVOLVED,stringAppend(WHEN_,EQUATIONS_))>
    <stringAppend(stringAppend(WHEN,EQUATION_),ID_)>FirstWhenEquationNo</stringAppend(stringAppend(WHEN,EQUATION_),ID_)>
    ...
    <stringAppend(stringAppend(WHEN,EQUATION_),ID_)>LastWhenEquationNo</stringAppend(stringAppend(WHEN,EQUATION_),ID_)>
  </stringAppend(INVOLVED,stringAppend(WHEN_,EQUATIONS_))>
</stringAppend(ZERO_CROSSING,ELEMENT_)>
 "
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inZeroCrossingLst,addMathMLCode)
    local
      DAE.Exp e;
      Boolean addMMLCode;
      list<Integer> eq,wc;
      list<BackendDAE.ZeroCrossing> zcLst;

    case ({},_) then ();

    case (BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq) :: zcLst,addMMLCode)
      equation
        dumpStrOpenTagAttr(stringAppend(ZERO_CROSSING,ELEMENT_),EXP_STRING,printExpStr(e));
        dumpExp(e,addMMLCode);
        dumpLstIntAttr(eq,stringAppend(INVOLVED,EQUATIONS_),stringAppend(EQUATION,ID_));
        dumpStrCloseTag(stringAppend(ZERO_CROSSING,ELEMENT_));
        dumpZcLst(zcLst,addMMLCode);
      then ();

  end match;
end dumpZcLst;


protected function lbinopSymbol "
function: lbinopSymbol
  Return string representation of logical binary operator.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    local String error_msg;
    case (DAE.AND()) then MathMLAnd;
    case (DAE.OR()) then MathMLOr;
    else
      equation
        error_msg = "in XMLDump.lbinopSymbol - Unknown operator";
        error_msg = error_msg + ExpressionDump.debugBinopSymbol(inOperator);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end lbinopSymbol;

protected function lunaryopSymbol "
function: lunaryopSymbol
  Return string representation of logical unary operator
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    local String error_msg;
    case (DAE.NOT()) then MathMLNot;
    else
      equation
        error_msg = "in XMLDump.lunaryopSymbol - Unknown operator";
        error_msg = error_msg + ExpressionDump.debugBinopSymbol(inOperator);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end lunaryopSymbol;


protected function relopSymbol  "
function: relopSymbol
  Return string representation of function operator.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    local String error_msg;
    case (DAE.LESS()) then MathMLLessThan;
    case (DAE.LESSEQ()) then MathMLLessEqualThan;
    case (DAE.GREATER()) then MathMLGreaterThan;
    case (DAE.GREATEREQ()) then MathMLGreaterEqualThan;
    case (DAE.EQUAL()) then MathMLEquivalent;
    case (DAE.NEQUAL()) then MathMLNotEqual;
    else
      equation
        error_msg = "in XMLDump.relopSymbol - Unknown operator";
        error_msg = error_msg + ExpressionDump.debugBinopSymbol(inOperator);
        Error.addMessage(Error.INTERNAL_ERROR, {error_msg});
      then
        fail();
  end match;
end relopSymbol;


protected function dumpResidual "
This function is necessary to print an equation element as a residual.
Since in Modelica is possible to have different kind of
equations, the BackendDAE representation of the OMC distinguish
between:
 - normal equations
 - array equations
 - solved equations
 - when equations
 - residual equations
 - algorithm references
This function prints the content using XML representation.
The output changes according to the content of the equation.
For example, if the element is an Array of Equations:
<ArrayOfEquations ID=..>
  <ARRAY_EQUATION>
    ..
    <MathML>
     ...
   </MathML>
   <ADDITIONAL_INFO stringAppend(ARRAY_OF_EQUATIONS,ID_)=...>
     <INVOLVEDVARIABLES>
       <VARIABLE>...</VARIABLE>
       ...
       <VARIABLE>...</VARIABLE>
     </INVOLVEDVARIABLES>
   </ADDITIONAL_INFO>
  </ARRAY_EQUATION>
</ARRAY_OF_EQUATIONS>
"
  input BackendDAE.Equation inEquation;
  input String inIndexNumber;
  input Boolean addMathMLCode;
algorithm
  _:=
  match (inEquation,inIndexNumber,addMathMLCode)
    local
      String s,s1,s2,res,is,indexS;
      DAE.Exp e1,e2,e;
      DAE.ComponentRef cr;
      list<DAE.Statement> stmts;
      DAE.ElementSource source;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2),indexS,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," ( ",s2,") = 0"});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(EQUATION);
      then ();

    case (BackendDAE.EQUATION(exp = e1,scalar = e2),indexS,false)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," - ( ",s2, " ) = 0"});
        dumpStrOpenTagAttr(EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(EQUATION);
      then ();

    case (BackendDAE.ARRAY_EQUATION(left = e1,right = e2),_,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        s = stringAppendList({s1," - (",s2,") = 0\n"});
        dumpStrOpenTagAttr(ARRAY_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(ARRAY_EQUATION);
      then ();

    case (BackendDAE.ARRAY_EQUATION(left=e1,right=e2),indexS,false)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," - ( ",s2, " ) = 0"});
        dumpStrOpenTagAttr(ARRAY_OF_EQUATIONS,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(ARRAY_OF_EQUATIONS);
      then ();
    case (BackendDAE.COMPLEX_EQUATION(left = e1,right = e2),_,true)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        s = stringAppendList({s1," - (",s2,") = 0\n"});
        dumpStrOpenTagAttr(COMPLEX_EQUATION, EXP_STRING, s);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        dumpExp2(e1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(COMPLEX_EQUATION);
      then ();

    case (BackendDAE.COMPLEX_EQUATION(left=e1,right=e2),indexS,false)
      equation
        s1 = printExpStr(e1);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," - ( ",s2, " ) = 0"});
        dumpStrOpenTagAttr(COMPLEX_EQUATION,ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(COMPLEX_EQUATION);
      then ();

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,true)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," - ( ",s2," ) := 0"});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        Print.printBuf(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();

    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2),indexS,false)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        res = stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(SOLVED,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(SOLVED,EQUATION_));
      then ();

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(condition = e1,whenStmtLst={BackendDAE.ASSIGN(left = cr,right = e2)})),indexS,true)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        is = printExpStr(e1);
        res = stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpStrOpenTag(MathMLApply);
        dumpStrOpenTag(MathMLMinus);
        Print.printBuf(s1);
        dumpExp2(e2);
        dumpStrCloseTag(MathMLApply);
        dumpExp2(DAE.RCONST(0.0));
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);

        dumpStrOpenTag(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION));
        Print.printBuf("\n");
        Print.printBuf(is);
        dumpExp(e1, true);
        dumpStrCloseTag(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION));

        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(condition = e1,whenStmtLst={BackendDAE.ASSIGN(left = cr,right = e2)})),indexS,false)
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s2 = printExpStr(e2);
        is = printExpStr(e1);
        res = stringAppendList({s1," - (",s2,") := 0"});
        dumpStrOpenTagAttr(stringAppend(WHEN,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrTagContent(stringAppend(stringAppend(WHEN,EQUATION_),CONDITION),is);
        dumpStrCloseTag(stringAppend(WHEN,EQUATION_));
      then ();

    case (BackendDAE.RESIDUAL_EQUATION(exp = e),indexS,true)
      equation
        s1 = printExpStr(e);
        res = stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrOpenTag(MathML);
        dumpStrOpenTagAttr(MATH, MathMLXmlns, MathMLWeb);
        dumpStrOpenTag(MathMLApply);
        dumpStrVoidTag(MathMLEquivalent);
        dumpExp2(e);
        dumpStrMathMLNumber("0");
        dumpStrCloseTag(MathMLApply);
        dumpStrCloseTag(MATH);
        dumpStrCloseTag(MathML);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();

    case (BackendDAE.RESIDUAL_EQUATION(exp = e),indexS,false)
      equation
        s1 = printExpStr(e);
        res = stringAppendList({s1," = 0"});
        dumpStrOpenTagAttr(stringAppend(RESIDUAL,EQUATION_),ID,indexS);
        Print.printBuf(res);
        dumpStrCloseTag(stringAppend(RESIDUAL,EQUATION_));
      then ();

    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(stmts),source=source),indexS,_)
      equation
        dumpStrOpenTagAttr(ALGORITHM,ID,indexS);
        Print.printBuf(Util.xmlEscape(DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(DAE.ALGORITHM_STMTS(stmts),source)})));
        dumpStrCloseTag(ALGORITHM);
      then ();

  end match;
end dumpResidual;

protected function unaryopSymbol "
function: unaryopSymbol
  Return string representation of unary operators
  corresponding to the MathML encode.
"
  input DAE.Operator inOperator;
  output String outString;
algorithm
  outString:=
  match (inOperator)
    case (DAE.UMINUS()) then MathMLMinus;
    case (DAE.UMINUS_ARR()) then MathMLMinus;
  end match;
end unaryopSymbol;


protected function unparseCommentOptionNoAnnotation "
function: unparseCommentOptionNoAnnotation

  Prettyprints a Comment without printing the annotation part.
"
  input Option<SCode.Comment> inAbsynCommentOption;
  output String outString;
algorithm
  outString:=
  matchcontinue (inAbsynCommentOption)
    local String str,cmt;
    case (SOME(SCode.COMMENT(_,SOME(cmt))))
      equation
        //str = stringAppendList({" \"",cmt,"\""});
        str = cmt;
      then
        str;
    case (_) then "";
  end matchcontinue;
end unparseCommentOptionNoAnnotation;

annotation(__OpenModelica_Interface="backend");
end XMLDump;
