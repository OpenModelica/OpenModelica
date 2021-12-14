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

encapsulated package NFInstUtil
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import FlatModel = NFFlatModel;
  import NFFlatten.FunctionTree;
  import NFFunction.Function;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

protected
  import Flags;

public
  function dumpFlatModelDebug
    input String stage;
    input FlatModel flatModel;
    input FunctionTree functions = FunctionTree.new();
  protected
    FlatModel flat_model = flatModel;
  algorithm
    // --dumpFlatModel=stage dumps specific stages, --dumpFlatModel dumps all stages.
    if Flags.isConfigFlagSet(Flags.DUMP_FLAT_MODEL, stage) or
       listEmpty(Flags.getConfigStringList(Flags.DUMP_FLAT_MODEL)) then
      flat_model := combineSubscripts(flatModel);

      print("########################################\n");
      print(stage);
      print("\n########################################\n\n");

      if Flags.getConfigBool(Flags.FLAT_MODELICA) then
        FlatModel.printFlatString(flat_model, FunctionTree.listValues(functions));
      else
        FlatModel.printString(flat_model);
      end if;

      print("\n");
    end if;
  end dumpFlatModelDebug;

  function combineSubscripts
    input output FlatModel flatModel;
  algorithm
    if Flags.isSet(Flags.COMBINE_SUBSCRIPTS) then
      flatModel := FlatModel.mapExp(flatModel, combineSubscriptsExp);
    end if;
  end combineSubscripts;

  function combineSubscriptsExp
    input output Expression exp;
  protected
    function traverser
      input output Expression exp;
    algorithm
      () := match exp
        case Expression.CREF()
          algorithm
            exp.cref := ComponentRef.combineSubscripts(exp.cref);
          then
            ();

        else ();
      end match;
    end traverser;
  algorithm
    exp := Expression.map(exp, traverser);
  end combineSubscriptsExp;

  function printStructuralParameters
    input FlatModel flatModel;
  protected
    list<Variable> params;
    list<String> names;
  algorithm
    if Flags.isSet(Flags.PRINT_STRUCTURAL) then
      params := list(v for v guard Variable.isStructural(v) in flatModel.variables);

      if not listEmpty(params) then
        names := list(ComponentRef.toString(v.name) for v in params);
        Error.addMessage(Error.NOTIFY_FRONTEND_STRUCTURAL_PARAMETERS,
          {stringDelimitList(names, ", ")});
      end if;
    end if;
  end printStructuralParameters;

  function dumpFlatModel
    input FlatModel flatModel;
    input FunctionTree functions;
    output String str;
  protected
    FlatModel flat_model;
  algorithm
    flat_model := combineSubscripts(flatModel);
    str := FlatModel.toFlatString(flat_model, FunctionTree.listValues(functions));
  end dumpFlatModel;

  function replaceEmptyArrays
    input output FlatModel flatModel;
  algorithm
    flatModel := FlatModel.mapExp(flatModel, replaceEmptyArraysExp);
  end replaceEmptyArrays;

  function replaceEmptyArraysExp
    "Variables with 0-dimensions are not present in the flat model, so replace
     any cref that refers to such a variable with an empty array expression."
    input output Expression exp;
  protected
    function traverser
      input Expression exp;
      output Expression outExp;
    protected
      ComponentRef cref;
      list<Subscript> subs;
      Type ty;
    algorithm
      outExp := match exp
        case Expression.CREF(cref = cref)
          guard ComponentRef.isEmptyArray(cref)
          algorithm
            if ComponentRef.hasSubscripts(cref) then
              cref := ComponentRef.fillSubscripts(cref);
              cref := ComponentRef.replaceWholeSubscripts(cref);
              subs := ComponentRef.subscriptsAllFlat(cref);
              cref := ComponentRef.stripSubscriptsAll(cref);
              ty := ComponentRef.getSubscriptedType(cref);
            else
              subs := {};
              ty := exp.ty;
            end if;

            outExp := Expression.makeDefaultValue(ty);

            if not listEmpty(subs) then
              outExp := Expression.SUBSCRIPTED_EXP(outExp, subs, exp.ty, false);
            end if;
          then
            outExp;

        else exp;
      end match;
    end traverser;
  algorithm
    exp := Expression.map(exp, traverser);
  end replaceEmptyArraysExp;

annotation(__OpenModelica_Interface="frontend");
end NFInstUtil;
