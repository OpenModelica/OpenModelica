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
encapsulated uniontype NBRemoveSimpleEquations
"file:        NBRemoveSimpleEquations.mo
 package:     NBRemoveSimpleEquations
 description: This file contains the functions for the remove simple equations
              module.
"

public
  import Module = NBModule;
protected
  // OF imports
  import DAE;

  // NF imports
  import BackendExtension = NFBackendExtension;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import HashTableCrToExp = NFHashTableCrToExp;
  import Operator = NFOperator;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import HashTableCrToCrEqLst = NBHashTableCrToCrEqLst;
  import VariableReplacements = NBVariableReplacements;
public
  function main
    "Wrapper function for any detect states function. This will be
     called during simulation and gets the corresponding subfunction from
     Config."
    extends Module.wrapper;
  protected
    Module.removeSimpleEquationsInterface func;
  algorithm
    (func) := getModule();

    bdae := match bdae
      local
        BVariable.VarData varData         "Data containing variable pointers";
        BEquation.EqData eqData           "Data containing equation pointers";
      case BackendDAE.BDAE(varData = varData, eqData = eqData)
        algorithm
          func(varData, eqData);
        then bdae;
    end match;
  end main;

  function getModule
    "Returns the module function that was chosen by the user."
    output Module.removeSimpleEquationsInterface func;
  protected
    String flag = "default"; //Flags.getConfigString(Flags.REMOVE_SIMPLE_EQUATIONS)
  algorithm
    func := match flag
      case "default" then removeSimpleEquationsDefault;
      /* ... New remove simple equations modules have to be added here */
      else fail();
    end match;
  end getModule;

protected
  function removeSimpleEquationsDefault extends Module.removeSimpleEquationsInterface;
    algorithm
    _ := match (varData, eqData)
      local
        BVariable.VariablePointers variables, aliasVars;
        BEquation.EquationPointers simulation, initials;
        Integer size;
        HashTableCrToCrEqLst.HashTable HTCrToCrEqLst;
        HashTableCrToExp.HashTable HTCrToExp;
        VariableReplacements repl;

      case (BVariable.VAR_DATA_SIM(variables = variables, aliasVars = aliasVars), BEquation.EQ_DATA_SIM(simulation = simulation, initials = initials))
        algorithm
          // ToDo: sizes of Hash tables are system dependent!
          size := BVariable.VariablePointers.size(variables);
          size := intMax(BaseHashTable.defaultBucketSize, realInt(realMul(intReal(size), 0.7)));
          HTCrToExp := HashTableCrToExp.emptyHashTableSized(size);
          HTCrToCrEqLst := HashTableCrToCrEqLst.emptyHashTableSized(size);
          repl := VariableReplacements.empty(size);

      then ();
      else ();
    end match;
  end removeSimpleEquationsDefault;

  function findSimpleEquations
    "BB,  main function for detecting simple equations"
    input BEquation.Equation inEq;
    input tuple <BVariable.VariablePointers, HashTableCrToExp.HashTable, HashTableCrToCrEqLst.HashTable, list<BEquation.Equation>, list<BEquation.Equation>> inTuple;
    input Boolean findAliases;
    output BEquation.Equation outEq = inEq;
    output tuple <BVariable.VariablePointers, HashTableCrToExp.HashTable, HashTableCrToCrEqLst.HashTable, list<BEquation.Equation>, list<BEquation.Equation>> outTuple = inTuple;
  algorithm
    /*
    (outEq, outTuple) := matchcontinue(inEq, inTuple)
      local
        BEquation.Equation eq, eqSolved;
        HashTableCrToExp.HashTable HTCrToExp;
        HashTableCrToCrEqLst.HashTable HTCrToCrEqLst;
        list<ComponentRef> cr_lst;
        list<Expression> exp_lst;
        list<BackendDAE.Var> varList;
        list<BEquation.Equation> eqList;
        list<BEquation.Equation> simpleEqList;
        Integer count, paramCount;
        ComponentRef cr, cr1, cr2;
        Expression res, value, exp1, exp2;
        BVariable.VariablePointers vars;
        Boolean keepEquation, cont;
        DAE.ElementSource source;
        BEquation.EquationAttributes eqAttr;

// ToDo case simple equation

      case (eq ,(vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList)) equation
          res = BEquation.Equation.getRHS(eq);
          (cr_lst,_,count,paramCount,true) = Expression.fold(res, findCrefs, ({},vars,0,0,true));
          res = BEquation.Equation.getLHS(eq);
          (cr_lst,_,count,_,true) = Expression.fold(res, findCrefs, (cr_lst,vars,count,paramCount,true));
          keepEquation = true;
          if (count == 1) then
            if Flags.isSet(Flags.DEBUG_ALIAS) then
              print("Found Equation knw0: " + BackendDump.equationString(eq) + "\n");
            end if;
            {cr} = cr_lst;
            // ToDo: allow state replacement
            false = BVariable.isState(BVariable.getVarPointer(cr));
            //false = BackendVariable.isClockedState(cr,vars);
            //false = BackendVariable.isOutput(cr,vars);
            false =  BVariable.isDiscrete(BVariable.getVarPointer(cr));
            exp1 = Expression.crefExp(cr);
            true = Types.isSimpleType(Expression.typeof(exp1));
            eqSolved as BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp1,NONE());
            true = isSimple(res);
            if Flags.isSet(Flags.DEBUG_ALIAS) then
              print("Found Equation knw1: " + BackendDump.equationString(eq) + "\n");
            end if;
            HTCrToExp = addToCrToExp(cr, eqSolved, HTCrToExp, HTCrToCrEqLst);
            keepEquation = false;
         elseif (count == 2) and findAliases then
            if Flags.isSet(Flags.DEBUG_ALIAS) then
              print("Found Equation al0: " + BackendDump.equationString(eq) + "\n");
            end if;
            {cr2, cr1} = cr_lst;
            // Be careful, when replacing states!!!
            // if BackendVariable.isState(cr1,vars) then
              // true = BackendVariable.isState(cr2,vars);
            // end if;
            false = BackendVariable.isState(cr1,vars) or BackendVariable.isState(cr2,vars);
            false = BackendVariable.isClockedState(cr1,vars) or BackendVariable.isClockedState(cr2,vars);
            false = BackendVariable.isOutput(cr1,vars) or BackendVariable.isOutput(cr2,vars);
            false = BackendVariable.isDiscrete(cr1,vars) or BackendVariable.isDiscrete(cr2,vars);
            exp1 = Expression.crefExp(cr1);
            true = Types.isSimpleType(Expression.typeof(exp1));
            exp2 = Expression.crefExp(cr2);

            BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp2,NONE());
            true = isSimple(res);
            BackendDAE.EQUATION(scalar=res) = BackendEquation.solveEquation(eq,exp1,NONE());
            true = isSimple(res);
            if Flags.isSet(Flags.DEBUG_ALIAS) then
              print("Found Equation al1: "  + BackendDump.equationString(eq) + "\n");
            end if;

            HTCrToCrEqLst = addToCrAndEqLists(cr2, cr1, inEq, HTCrToCrEqLst);
            HTCrToCrEqLst = addToCrAndEqLists(cr1, cr2, inEq, HTCrToCrEqLst);

            if (BaseHashTable.hasKey(cr2, HTCrToExp)) then
              value = BaseHashTable.get(cr2, HTCrToExp);
              BackendDAE.EQUATION(scalar=res, source=source, attr=eqAttr) = BackendEquation.solveEquation(eq, Expression.crefExp(cr1),NONE());
              (res,_) = Expression.replaceExp(res,Expression.crefExp(cr2),value);
              (res,_) = ExpressionSimplify.simplify(res);
              HTCrToExp = addToCrToExp(cr1, BackendDAE.EQUATION(Expression.crefExp(cr1), res, source, eqAttr), HTCrToExp, HTCrToCrEqLst);
            else
              if (BaseHashTable.hasKey(cr1, HTCrToExp)) then
                value = BaseHashTable.get(cr1, HTCrToExp);
                BackendDAE.EQUATION(scalar=res, source=source, attr=eqAttr) = BackendEquation.solveEquation(eq, Expression.crefExp(cr2),NONE());
                (res,_) = Expression.replaceExp(res,Expression.crefExp(cr1),value);
                (res,_) = ExpressionSimplify.simplify(res);
                HTCrToExp = addToCrToExp(cr2, BackendDAE.EQUATION(Expression.crefExp(cr2), res, source, eqAttr), HTCrToExp, HTCrToCrEqLst);
              end if;
            end if;
            keepEquation = false;
        end if;
        if (keepEquation) then
          eqList = inEq::eqList;
        else
          simpleEqList = inEq::simpleEqList;
        end if;
      then (inEq, (vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList));
      case (_,(vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList))equation
         eqList = inEq::eqList;
      then (inEq, (vars, HTCrToExp, HTCrToCrEqLst, eqList, simpleEqList));
      else equation
        print("\n++++++++++ Error in RemoveSimpleEquations.findSimpleEquations ++++++++++\n");
      then (inEq, inTuple);
    end matchcontinue;
    */
  end findSimpleEquations;

  function findCrefs "BB,
  looks for variable crefs in Expressions, if more then 2 are found stop searching
  also stop if complex structures appear, e.g. IFEXP
  "
     input output Expression exp;
     output Boolean cont;
     input output tuple<list<ComponentRef>, BVariable.VariablePointers, Integer, Integer, Boolean> tpl;
  algorithm
      (exp, cont, tpl) := match(exp,tpl)
      local
        ComponentRef cr;
        list<ComponentRef> cr_lst;
        Integer count, paramCount;
        BackendExtension.VariableKind kind;
        BVariable.VariablePointers vars;
      case(_,(_,_,_,_,cont)) guard(not cont) algorithm return; then (exp, cont, tpl);
      case(_,(_,vars,count,_,_)) guard(count<0) then(exp, false, ({},vars,-1,-1,false));
      case (Expression.CREF(cref=cr),(cr_lst,vars,count,paramCount,true))
        guard(count < 2 and not (ComponentRef.isTime(cr)) and not BVariable.isParamOrConstant(BVariable.getVarPointer(cr)))
      then (exp, true, (cr::cr_lst,vars,count+1,paramCount,true));
      case (Expression.CREF(cref=cr),(cr_lst,vars,count,paramCount,true))
        guard(count < 2 and not (ComponentRef.isTime(cr)))
      then (exp, true, (cr_lst,vars,count,paramCount+1,true));
      case (Expression.CREF(),(_,vars,_,_,true))
      then (exp, false, ({},vars,-1,-1,false));
      case (Expression.RELATION(),(_,vars,_,_,_))
      then (exp, false, ({},vars,-1,-1,false));
      case (Expression.IF(),(_,vars,_,_,_))
      then (exp, false, ({},vars,-1,-1,false));
      case (Expression.CALL(),(_,vars,_,_,_))
      then (exp, false, ({},vars,-1,-1,false));
      case (Expression.RECORD(),(_,vars,_,_,_))
      then (exp, false, ({},vars,-1,-1,false));
      // ToDo: maybe more cases to stop
      else (exp, true, tpl);
    end match;
  end findCrefs;

  function isSimple
    "BB start module for detecting simple equation/expressions"
    input Expression exp;
    output Boolean isSimple;
  algorithm
     //print("Traverse "  + ExpressionDump.printExpStr(inExp) + "\n");
    isSimple := Expression.fold(exp, checkOperator, true);
    //print("Simple: " +  boolString(outIsSimple) + "\n");
  end isSimple;

  function checkOperator "BB
  check, if left and right expression of an equation are simple:
  a = b, a = -b, a = not b, a = 2.0, etc.
  this module will be extended in the future!
  "
    input Expression exp;
    input output Boolean simple;
  protected
    function checkOp
      "BB"
      input Operator.Op op;
      output Boolean b;
    algorithm
      b := match(op)
        case NFOperator.Op.ADD        then true;
        case NFOperator.Op.SUB        then true;
        case NFOperator.Op.UMINUS     then true;
        case NFOperator.Op.MUL        then false;
        case NFOperator.Op.EQUAL      then false;
        case NFOperator.Op.DIV        then false;
        case NFOperator.Op.POW        then false;
                                      else false;
      end match;
    end checkOp;
  algorithm
    simple := match(exp)
      local
        Expression exp1, exp2;
        Operator op;
        Boolean check;
      case Expression.BINARY(exp1, op, exp2) equation
        true = checkOp(op.op);
        true = checkOperator(exp1,simple);
        true = checkOperator(exp2,simple);
      then true;
      case Expression.UNARY(_,exp1)
      then checkOperator(exp1,simple);
      case Expression.LUNARY(_,exp1)
      then checkOperator(exp1,simple);
      case Expression.CREF()
      then true;
      case Expression.INTEGER()
      then true;
      case Expression.REAL()
      then true;
      case Expression.BOOLEAN()
      then true;
      case Expression.STRING()
      then true;
      else false;
    end match;
  end checkOperator;

  annotation(__OpenModelica_Interface="backend");
end NBRemoveSimpleEquations;
