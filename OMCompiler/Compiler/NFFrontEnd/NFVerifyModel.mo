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

encapsulated uniontype NFVerifyModel
  import FlatModel = NFFlatModel;

protected
  import List;
  import Error;
  import DAE;
  import ElementSource;
  import ExecStat.execStat;
  import ComponentRef = NFComponentRef;
  import Equation = NFEquation;
  import Expression = NFExpression;
  import ExpandExp = NFExpandExp;

public
  function verify
    input FlatModel flatModel;
  algorithm
    for eq in flatModel.equations loop
      verifyEquation(eq);
    end for;

    execStat(getInstanceName());
  end verify;

protected
  function verifyEquation
    input Equation eq;
  algorithm
    () := match eq
      case Equation.WHEN()
        algorithm
          verifyWhenEquation(eq.branches, eq.source);
        then
          ();

      else ();
    end match;
  end verifyEquation;

  function verifyWhenEquation
    "Checks that each branch in a when-equation has the same set of crefs on the lhs."
    input list<Equation.Branch> branches;
    input DAE.ElementSource source;
  protected
    list<ComponentRef> crefs1, crefs2;
    list<Equation.Branch> rest_branches;
    list<Equation> body;
  algorithm
    // Only when-equation with more than one branch needs to be checked.
    if List.hasOneElement(branches) then
      return;
    end if;

    Equation.Branch.BRANCH(body = body) :: rest_branches := branches;
    crefs1 := whenEquationBranchCrefs(body);

    for branch in rest_branches loop
      Equation.Branch.BRANCH(body = body) := branch;
      crefs2 := whenEquationBranchCrefs(body);

      checkCrefSetEquality(crefs1, crefs2, Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, source);
    end for;
  end verifyWhenEquation;

  function whenEquationBranchCrefs
    "Helper function to verifyWhenEquation, returns the set of crefs that the
     given list of equations contains on the lhs."
    input list<Equation> eql;
    output list<ComponentRef> crefs = {};
  algorithm
    for eq in eql loop
      crefs := match eq
        case Equation.EQUALITY()       then whenEquationEqualityCrefs(eq.lhs, crefs);
        case Equation.CREF_EQUALITY()  then eq.lhs :: crefs;
        case Equation.ARRAY_EQUALITY() then whenEquationEqualityCrefs(eq.lhs, crefs);
        case Equation.REINIT()         then whenEquationEqualityCrefs(eq.cref, crefs);
        case Equation.IF()             then whenEquationIfCrefs(eq.branches, eq.source, crefs);
        else crefs;
      end match;
    end for;

    crefs := List.sort(crefs, ComponentRef.isGreater);
    crefs := List.sortedUnique(crefs, ComponentRef.isEqual);
  end whenEquationBranchCrefs;

  function whenEquationEqualityCrefs
    input Expression lhsExp;
    input output list<ComponentRef> crefs;
  algorithm
    crefs := match lhsExp
      case Expression.CREF() then lhsExp.cref :: crefs;
      case Expression.TUPLE()
        then List.fold(lhsExp.elements, whenEquationEqualityCrefs, crefs);
    end match;
  end whenEquationEqualityCrefs;

  function whenEquationIfCrefs
    "Checks that the left-hand sides of the given if-equation branches consists
     of the same set of crefs, and adds that set to the given set of crefs."
    input list<Equation.Branch> branches;
    input DAE.ElementSource source;
    input output list<ComponentRef> crefs;
  protected
    list<ComponentRef> crefs1, crefs2;
    list<Equation.Branch> rest_branches;
    list<Equation> body;
  algorithm
    Equation.Branch.BRANCH(body = body) :: rest_branches := branches;
    crefs1 := whenEquationBranchCrefs(body);

    for branch in rest_branches loop
      Equation.Branch.BRANCH(body = body) := branch;
      crefs2 := whenEquationBranchCrefs(body);

      // All the branches must have the same set of crefs on the lhs.
      checkCrefSetEquality(crefs1, crefs2, Error.WHEN_IF_VARIABLE_MISMATCH, source);
    end for;

    crefs := listAppend(crefs1, crefs);
  end whenEquationIfCrefs;

  function checkCrefSetEquality
    input list<ComponentRef> crefs1;
    input list<ComponentRef> crefs2;
    input Error.Message errMsg;
    input DAE.ElementSource source;
  algorithm
    // Assume the user isn't mixing different ways of subscripting array
    // varibles in the different branches, and just check the sets as is.
    if List.isEqualOnTrue(crefs1, crefs2, ComponentRef.isEqual) then
      return;
    end if;

    // If the sets didn't match, expand arrays into scalars and try again.
    if List.isEqualOnTrue(expandCrefSet(crefs1), expandCrefSet(crefs2), ComponentRef.isEqual) then
      return;
    end if;

    // Couldn't get the sets to match, print an error and fail.
    Error.addSourceMessage(errMsg, {}, ElementSource.getInfo(source));
    fail();
  end checkCrefSetEquality;

  function expandCrefSet
    input list<ComponentRef> crefs;
    output list<ComponentRef> outCrefs = {};
  protected
    Expression exp;
    list<Expression> expl;
  algorithm
    for cref in crefs loop
      exp := Expression.fromCref(cref);
      exp := ExpandExp.expandCref(exp);

      if Expression.isArray(exp) then
        expl := Expression.arrayElements(exp);
        outCrefs := listAppend(list(Expression.toCref(e) for e in expl), outCrefs);
      else
        outCrefs := cref :: outCrefs;
      end if;
    end for;

    outCrefs := List.sort(outCrefs, ComponentRef.isGreater);
    outCrefs := List.sortedUnique(outCrefs, ComponentRef.isEqual);
  end expandCrefSet;

  annotation(__OpenModelica_Interface="frontend");
end NFVerifyModel;
