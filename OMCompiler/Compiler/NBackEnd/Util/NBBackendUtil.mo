/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NBBackendUtil
" file:         NBBackendUtil.mo
  package:      NBBackendUtil
  description:  This file contains util functions for the backend.
"

public
  // NF imports
  import NFBackendExtension.BackendInfo;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import Operator = NFOperator;
  import Type = NFType;
  import Variable = NFVariable;

  // backend imports
  import BEquation = NBEquation;
  import NBEquation.{Equation, Frame, FrameLocation};
  import Matching = NBMatching;
  import BVariable = NBVariable;

  // Util imports
  import Util;

  // old imports
  import MMath;

  uniontype Rational
    record RATIONAL
      Integer n;
      Integer d;
    end RATIONAL;

    function toString
      input Rational r;
      output String str = intString(r.n) + "/" + intString(r.d);
    end toString;

    function normalize
      input output Rational r;
    algorithm
      if r.n == 0 then
        r.d := 1;
      end if;
    end normalize;

    function add
      input Rational r1;
      input Rational r2;
      output Rational r = finalize(r1.n*r2.d + r2.n*r1.d, r1.d*r2.d);
    end add;

    function multiply
      input Rational r1;
      input Rational r2;
      output Rational r = finalize(r1.n*r2.n, r1.d*r2.d);
    end multiply;

    function isEqual
      input Rational r1;
      input Rational r2;
      output Boolean b = r1.n == r2.n and r1.d == r2.d;
    end isEqual;

    function convert
      input Rational r;
      output MMath.Rational oldR = MMath.RATIONAL(r.n, r.d);
    end convert;

  protected
    function finalize
      input Integer i1;
      input Integer i2;
      output Rational r;
    protected
      Integer d = intGcd(i1,i2);
    algorithm
      r := normalize(RATIONAL(intDiv(i1,d), intDiv(i2,d)));
    end finalize;

    function intGcd "returns the greatest common divisor for two Integers"
      input Integer i1;
      input Integer i2;
      output Integer i;
    algorithm
      i := if i2 == 0 then i1 else intGcd(i2, intMod(i1,i2));
    end intGcd;
  end Rational;

  function findTrueIndices
    "returns all indices of elements that are true"
    input array<Boolean> arr;
    output list<Integer> indices = list(i for i guard arr[i] in arrayLength(arr):-1:1);
  end findTrueIndices;

  function countElem
    input array<list<Integer>> m;
    output Integer count = sum(listLength(lst) for lst in m);
  end countElem;

  function indexTplGt<T>
    "use with List.sort() and a rating function to sort any list"
    input tuple<Integer, T> tpl1;
    input tuple<Integer, T> tpl2;
    output Boolean gt;
  protected
    Integer i1, i2;
  algorithm
    (i1, _) := tpl1;
    (i2, _) := tpl2;
    gt := i1 > i2;
  end indexTplGt;

  public function noNameHashEq
    input BEquation.Equation eq;
    input Integer mod;
    output Integer hash;
  algorithm
    hash := noNameHashExp(BEquation.Equation.getResidualExp(eq), mod);
  end noNameHashEq;

  function noNameHashExp
    "ToDo: is this mod safe? (missing intMod!)"
    input Expression exp;
    input Integer mod;
    output Integer hash = 0;
  algorithm
    hash := match exp
      local
        Variable var;
        Integer hash1, hash2;
      case Expression.INTEGER() then exp.value;
      case Expression.REAL() then realInt(exp.value);
      case Expression.STRING() then stringHashDjb2Mod(exp.value, mod);
      case Expression.BOOLEAN() then Util.boolInt(exp.value);
      case Expression.ENUM_LITERAL() then exp.index; // ty !!
      case Expression.CLKCONST() then 0; // clk !!
      case Expression.CREF() algorithm
        var := BVariable.getVar(exp.cref, sourceInfo());
      then stringHashDjb2Mod(BackendInfo.toString(var.backendinfo), mod);
      case Expression.TYPENAME() then 1; // ty !!
      case Expression.ARRAY() algorithm // ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
        hash := hash + Util.boolInt(exp.literal);
      then hash;
      case Expression.MATRIX() algorithm
        for lst in exp.elements loop
          for elem in lst loop
            hash := hash + noNameHashExp(elem, mod);
          end for;
        end for;
      then hash;
      case Expression.RANGE() algorithm
        if isSome(exp.step) then
          hash := noNameHashExp(Util.getOption(exp.step), mod);
        end if;
      then hash + noNameHashExp(exp.start, mod) + noNameHashExp(exp.stop, mod);
      case Expression.TUPLE() algorithm // ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
      then hash;
      case Expression.RECORD() algorithm // path, ty !!
        for elem in exp.elements loop
          hash := hash + noNameHashExp(elem, mod);
        end for;
      then hash;
      case Expression.CALL() then 2; // call!!
      case Expression.SIZE() algorithm
        if isSome(exp.dimIndex) then
          hash := noNameHashExp(Util.getOption(exp.dimIndex), mod);
        end if;
      then hash + noNameHashExp(exp.exp, mod);
      case Expression.END() then stringHashDjb2Mod("end", mod);
      case Expression.BINARY() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match Operator.classify(exp.operator)
          case (NFOperator.MathClassification.ADDITION, _)        then hash1 + hash2;
          case (NFOperator.MathClassification.SUBTRACTION, _)     then hash1 - hash2;
          case (NFOperator.MathClassification.MULTIPLICATION, _)  then hash1 * hash2;
          case (NFOperator.MathClassification.DIVISION, _)        then realInt(hash1 / hash2);
          case (NFOperator.MathClassification.POWER, _)           then realInt(hash1 ^ hash2);
          case (NFOperator.MathClassification.LOGICAL, _)         then -(hash1 + hash2);
          case (NFOperator.MathClassification.RELATION, _)        then hash2 - hash1;
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.UNARY() then -noNameHashExp(exp.exp, mod);
      case Expression.LBINARY() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match exp.operator.op
          case NFOperator.Op.AND then hash1 + hash2;
          case NFOperator.Op.OR then hash1 - hash2;
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.LUNARY() then -noNameHashExp(exp.exp, mod);
      case Expression.RELATION() algorithm
        hash1 := noNameHashExp(exp.exp1, mod);
        hash2 := noNameHashExp(exp.exp2, mod);
        hash := match exp.operator.op
          case NFOperator.Op.LESS       then hash1 + hash2;
          case NFOperator.Op.LESSEQ     then -(hash1 + hash2);
          case NFOperator.Op.GREATER    then hash1 - hash2;
          case NFOperator.Op.GREATEREQ  then hash2 - hash1;
          case NFOperator.Op.EQUAL      then hash1 * hash2;
          case NFOperator.Op.NEQUAL     then realInt(hash1 ^ hash2);
          else hash2 - hash1;
        end match;
      then hash;
      case Expression.IF() then noNameHashExp(exp.condition, mod) +
                                noNameHashExp(exp.trueBranch, mod) +
                                noNameHashExp(exp.falseBranch, mod);
      case Expression.CAST() then noNameHashExp(exp.exp, mod);
      case Expression.BOX() then noNameHashExp(exp.exp, mod);
      case Expression.UNBOX() then noNameHashExp(exp.exp, mod);
      case Expression.SUBSCRIPTED_EXP() then noNameHashExp(exp.exp, mod); // subscripts!
      case Expression.TUPLE_ELEMENT() then noNameHashExp(exp.tupleExp, mod) + exp.index;
      case Expression.RECORD_ELEMENT() then noNameHashExp(exp.recordExp, mod) + exp.index;
      case Expression.MUTABLE() then noNameHashExp(Mutable.access(exp.exp), mod);
      case Expression.EMPTY() then stringHashDjb2Mod("empty", mod);
      case Expression.PARTIAL_FUNCTION_APPLICATION() algorithm
        //should we hash function names here?
        for arg in exp.args loop
          hash := hash + noNameHashExp(arg, mod);
        end for;
      then hash;
      else 0;
    end match;
    hash := intMod(intAbs(hash), mod);
  end noNameHashExp;

  function isOnlyTimeDependent
    input Expression exp;
    output Boolean b;
  algorithm
    b := Expression.fold(exp, isOnlyTimeDependentFold, true);
  end isOnlyTimeDependent;

  function isOnlyTimeDependentFold
    input Expression exp;
    input output Boolean b;
  algorithm
    if b then
      b := match exp
        case Expression.CREF() then ComponentRef.isTime(exp.cref) or BVariable.checkCref(exp.cref, BVariable.isParamOrConst, sourceInfo());
        else true;
      end match;
    end if;
  end isOnlyTimeDependentFold;

  function isContinuous
    input Expression exp;
    input Boolean init;
    output Boolean b;
  algorithm
    b := Expression.fold(exp, function isContinuousFold(init = init), true);
  end isContinuous;

  function isContinuousFold
    input Expression exp;
    input Boolean init;
    input output Boolean b;
  algorithm
    if b then
      b := match exp
        case Expression.CREF() then BVariable.checkCref(exp.cref, function BVariable.isContinuous(init = init), sourceInfo());
        else true;
      end match;
    end if;
  end isContinuousFold;

  function getLocalSystem
    input array<list<Integer>> m          "global adjacency matrix";
    input Matching matching               "global matching";
    input list<Integer> eqn_indices       "global equation indices to keep";
    output array<list<Integer>> m_loc     "local adjacency matrix";
    output Matching matching_loc          "local matching";
    output array<Integer> map_back        "local to global equation indices";
  protected
    constant Integer N = listLength(eqn_indices);
    array<Integer> var_to_eqn = arrayCreate(N, -1);
    array<Integer> eqn_to_var = arrayCreate(N, -1);
    UnorderedMap<Integer, Integer> eqn_loc = UnorderedMap.new<Integer>(Util.id, intEq, N) "global to local equation indices";
    UnorderedMap<Integer, Integer> var_loc = UnorderedMap.new<Integer>(Util.id, intEq, N) "global to local variable indices";
    Integer j = 1;
  algorithm
    // map matching from full system
    map_back := arrayCreate(N, -1);
    for i in eqn_indices loop
      // set equation maps
      UnorderedMap.addUnique(i, j, eqn_loc);
      map_back[j] := i;

      // set var from matching
      UnorderedMap.addUnique(matching.eqn_to_var[i], j, var_loc);

      // set matching
      eqn_to_var[j] := j;
      var_to_eqn[j] := j;
      j := j + 1;
    end for;

    // filter only local edges of adjacency matrix
    m_loc := arrayCreate(N, {});
    for i in eqn_indices loop
      m_loc[i] := UnorderedMap.getList(m[i], var_loc);
    end for;
    matching_loc := MATCHING(var_to_eqn, eqn_to_var);
  end getLocalSystem;

  annotation(__OpenModelica_Interface="backend");
end NBBackendUtil;
