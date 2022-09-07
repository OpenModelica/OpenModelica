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
encapsulated uniontype NSimGenericCall
"file:        NSimGenericCall.mo
 package:     NSimGenericCall
 description: This file contains the data types and functions for generic for loop calls.
"
public
  // self import
  import SimGenericCall = NSimGenericCall;


protected
  // NB import
  import NBEquation.{Equation, Iterator};

  // NF import
  import Expression = NFExpression;
  import ComponentRef = NFComponentRef;

  // old simcode import
  import OldSimCode = SimCode;

public
  record SINGLE_GENERIC_CALL
    Integer index;
    list<SimIterator> iters;
    Expression lhs;
    Expression rhs;
  end SINGLE_GENERIC_CALL;

  function toString
    input SimGenericCall call;
    output String str;
  algorithm
    str := match call
      case SINGLE_GENERIC_CALL() then "single generic call [index " + intString(call.index)  + "]: "
        + List.toString(call.iters, SimIterator.toString) + "\n\t"
        + Expression.toString(call.lhs) + " = " + Expression.toString(call.rhs);
      else "CALL_NOT_SUPPORTED";
    end match;
  end toString;

  function fromEquation
    input tuple<Pointer<Equation>, Integer> eqn_tpl;
    output SimGenericCall call;
  protected
    Pointer<Equation> eqn_ptr;
    Integer index;
    Equation body, eqn;
  algorithm
    (eqn_ptr, index) := eqn_tpl;
    eqn := Pointer.access(eqn_ptr);
    call := match eqn
      case Equation.FOR_EQUATION(body = {body})
      then SINGLE_GENERIC_CALL(
          index = index,
          iters = SimIterator.fromIterator(eqn.iter),
          lhs   = Equation.getLHS(body),
          rhs   = Equation.getRHS(body));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect equation: " + Equation.toString(eqn)});
      then fail();
    end match;
  end fromEquation;

  function convert
    input SimGenericCall call;
    output OldSimCode.SimGenericCall old_call;
  algorithm
    old_call := match call
      case SINGLE_GENERIC_CALL() then OldSimCode.SINGLE_GENERIC_CALL(
        index = call.index,
        iters = list(SimIterator.convert(iter) for iter in call.iters),
        lhs = Expression.toDAE(call.lhs),
        rhs = Expression.toDAE(call.rhs));
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect call: " + toString(call)});
      then fail();
     end match;
  end convert;

  uniontype SimIterator
    record SIM_ITERATOR
      ComponentRef name;
      Integer start;
      Integer step;
      Integer size;
    end SIM_ITERATOR;

    function toString
      input SimIterator iter;
      output String str = "{" + ComponentRef.toString(iter.name) + " | start:" + intString(iter.start) + ", step:" + intString(iter.step) + ", size: " + intString(iter.size) + "}";
    end toString;

    function fromIterator
      input Iterator iter;
      output list<SimIterator> sim_iter = {};
    protected
      list<ComponentRef> names;
      list<Expression> ranges;
      ComponentRef name;
      Expression range;
      Integer start, step, stop;
    algorithm
      (names, ranges) := Iterator.getFrames(iter);
      for tpl in listReverse(List.zip(names, ranges)) loop
        (name, range) := tpl;
        (start, step, stop) := match range
          case Expression.RANGE() then (Expression.integerValue(range.start), Expression.integerValue(Util.getOptionOrDefault(range.step, Expression.INTEGER(1))), Expression.integerValue(range.stop));
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for incorrect range: " + Expression.toString(range)});
          then fail();
        end match;
        sim_iter := SIM_ITERATOR(name, start, step, intDiv(stop-start,step)+1) :: sim_iter;
      end for;
    end fromIterator;

    function convert
      input SimIterator iter;
      output OldSimCode.SimIterator old_iter = OldSimCode.SIM_ITERATOR(ComponentRef.toDAE(iter.name), iter.start, iter.step, iter.size);
    end convert;
  end SimIterator;

  annotation(__OpenModelica_Interface="backend");
end NSimGenericCall;
