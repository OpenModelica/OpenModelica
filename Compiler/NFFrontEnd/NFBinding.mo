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

encapsulated package NFBinding

public
  import Expression = NFExpression;
  import NFInstNode.InstNode;
  import SCode;
  import Type = NFType;
  import NFPrefixes.Variability;
  import Error;

protected
  import Dump;

public
  constant Binding EMPTY_BINDING = Binding.UNBOUND({}, false, Absyn.dummyInfo);

uniontype Binding
  record UNBOUND
    // NOTE: Use the EMPTY_BINDING constant above when a default unbound binding
    //       is needed, to save memory. UNBOUND contains this information to be
    //       able to check that 'each' is used correctly, so parents and info
    //       are only needed when isEach is true.
    list<InstNode> parents;
    Boolean isEach;
    SourceInfo info;
  end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    InstNode scope;
    list<InstNode> parents;
    Boolean isEach;
    SourceInfo info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    Expression bindingExp;
    Boolean isProcessing;
    InstNode scope;
    list<InstNode> parents;
    Boolean isEach;
    SourceInfo info;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    Expression bindingExp;
    Type bindingType;
    Variability variability;
    list<InstNode> parents;
    Boolean isEach;
    Boolean evaluated;
    Boolean isFlattened;
    SourceInfo info;
  end TYPED_BINDING;

  record FLAT_BINDING
    Expression bindingExp;
    Variability variability;
  end FLAT_BINDING;

  record CEVAL_BINDING
    "Used by the constant evaluation for generated bindings (e.g. record
     bindings constructed from the record fields) that should be discarded
     during flattening."
    Expression bindingExp;
    list<InstNode> parents;
  end CEVAL_BINDING;

  record INVALID_BINDING
    Binding binding;
    list<Error.TotalMessage> errors;
  end INVALID_BINDING;

public
  function fromAbsyn
    input Option<Absyn.Exp> bindingExp;
    input Boolean eachPrefix;
    input list<InstNode> parents;
    input InstNode scope;
    input SourceInfo info;
    output Binding binding;
  algorithm
    binding := match bindingExp
      local
        Absyn.Exp exp;

      case SOME(exp)
        then RAW_BINDING(exp, scope, parents, eachPrefix, info);

      else if eachPrefix then UNBOUND(parents, true, info) else NFBinding.EMPTY_BINDING;
    end match;
  end fromAbsyn;

  function isBound
    input Binding binding;
    output Boolean isBound;
  algorithm
    isBound := match binding
      case UNBOUND() then false;
      else true;
    end match;
  end isBound;

  function isExplicitlyBound
    input Binding binding;
    output Boolean isBound;
  algorithm
    isBound := match binding
      case UNBOUND() then false;
      case CEVAL_BINDING() then false;
      else true;
    end match;
  end isExplicitlyBound;

  function isUnbound
    input Binding binding;
    output Boolean isUnbound;
  algorithm
    isUnbound := match binding
      case UNBOUND() then true;
      else false;
    end match;
  end isUnbound;

  function untypedExp
    input Binding binding;
    output Option<Expression> exp;
  algorithm
    exp := match binding
      case UNTYPED_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end untypedExp;

  function typedExp
    input Binding binding;
    output Option<Expression> exp;
  algorithm
    exp := match binding
      case TYPED_BINDING() then SOME(binding.bindingExp);
      case FLAT_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end typedExp;

  function getUntypedExp
    input Binding binding;
    output Expression exp;
  algorithm
    UNTYPED_BINDING(bindingExp = exp) := binding;
  end getUntypedExp;

  function getTypedExp
    input Binding binding;
    output Expression exp;
  algorithm
    exp := match binding
      case TYPED_BINDING() then binding.bindingExp;
      case FLAT_BINDING() then binding.bindingExp;
    end match;
  end getTypedExp;

  function setTypedExp
    input Expression exp;
    input output Binding binding;
  protected
    Type ty1, ty2;
  algorithm
    () := match binding
      case TYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

      case FLAT_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();
    end match;
  end setTypedExp;

  function getExp
    input Binding binding;
    output Expression exp;
  algorithm
    exp := match binding
      case UNTYPED_BINDING() then binding.bindingExp;
      case TYPED_BINDING() then binding.bindingExp;
      case FLAT_BINDING() then binding.bindingExp;
    end match;
  end getExp;

  function setExp
    input Expression exp;
    input output Binding binding;
  algorithm
    () := match binding
      case UNTYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

      case TYPED_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

      case FLAT_BINDING()
        algorithm
          binding.bindingExp := exp;
        then
          ();

    end match;
  end setExp;

  function isRecordExp
    input Binding binding;
    output Boolean isRecordExp;
  algorithm
    isRecordExp := match binding
      case TYPED_BINDING(bindingExp = Expression.RECORD()) then true;
      else false;
    end match;
  end isRecordExp;

  function isCrefExp
    input Binding binding;
    output Boolean isCref;
  algorithm
    isCref := match binding
      case TYPED_BINDING(bindingExp = Expression.CREF()) then true;
      else false;
    end match;
  end isCrefExp;

  function recordFieldBinding
    input InstNode fieldNode;
    input Binding recordBinding;
    output Binding fieldBinding = recordBinding;
  protected
    Expression exp;
    Type ty;
    Variability var;
    String field_name = InstNode.name(fieldNode);
  algorithm
    fieldBinding := match fieldBinding
      case UNTYPED_BINDING()
        algorithm
          fieldBinding.bindingExp := Expression.recordElement(field_name, fieldBinding.bindingExp);
        then
          fieldBinding;

      case TYPED_BINDING()
        algorithm
          exp := Expression.recordElement(field_name, fieldBinding.bindingExp);
          ty := Expression.typeOf(exp);
          var := Expression.variability(exp);
        then
          TYPED_BINDING(exp, ty, var, fieldNode :: fieldBinding.parents, fieldBinding.isEach,
                        fieldBinding.evaluated, fieldBinding.isFlattened, fieldBinding.info);

      case FLAT_BINDING()
        algorithm
          exp := Expression.recordElement(field_name, fieldBinding.bindingExp);
          var := Expression.variability(exp);
        then
          FLAT_BINDING(exp, var);

      case CEVAL_BINDING()
        algorithm
          fieldBinding.bindingExp := Expression.recordElement(field_name, fieldBinding.bindingExp);
        then
          fieldBinding;

    end match;
  end recordFieldBinding;

  function variability
    input Binding binding;
    output Variability var;
  algorithm
    var := match binding
      case TYPED_BINDING() then binding.variability;
      case FLAT_BINDING() then binding.variability;
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown binding", sourceInfo());
        then
          fail();
    end match;
  end variability;

  function getInfo
    input Binding binding;
    output SourceInfo info;
  algorithm
    info := match binding
      case UNBOUND() then binding.info;
      case RAW_BINDING() then binding.info;
      case UNTYPED_BINDING() then binding.info;
      case TYPED_BINDING() then binding.info;
      else Absyn.dummyInfo;
    end match;
  end getInfo;

  function getType
    input Binding binding;
    output Type ty;
  algorithm
    TYPED_BINDING(bindingType = ty) := binding;
  end getType;

  function isEach
    input Binding binding;
    output Boolean isEach;
  algorithm
    isEach := match binding
      case UNBOUND() then binding.isEach;
      case RAW_BINDING() then binding.isEach;
      case UNTYPED_BINDING() then binding.isEach;
      case TYPED_BINDING() then binding.isEach;
      else false;
    end match;
  end isEach;

  function isTyped
    input Binding binding;
    output Boolean isTyped;
  algorithm
    isTyped := match binding
      case TYPED_BINDING() then true;
      else false;
    end match;
  end isTyped;

  function parents
    input Binding binding;
    output list<InstNode> parents;
  algorithm
    parents := match binding
      case UNBOUND() then binding.parents;
      case RAW_BINDING() then binding.parents;
      case UNTYPED_BINDING() then binding.parents;
      case TYPED_BINDING() then binding.parents;
      case CEVAL_BINDING() then binding.parents;
      else {};
    end match;
  end parents;

  function parentCount
    input Binding binding;
    output Integer count = listLength(parents(binding));
  end parentCount;

  function addParent
    input InstNode parent;
    input output Binding binding;
  algorithm
    () := match binding
      case UNBOUND(isEach = true)
        algorithm
          binding.parents := parent :: binding.parents;
        then
          ();

      case RAW_BINDING()
        algorithm
          binding.parents := parent :: binding.parents;
        then
          ();

      case UNTYPED_BINDING()
        algorithm
          binding.parents := parent :: binding.parents;
        then
          ();

      case TYPED_BINDING()
        algorithm
          binding.parents := parent :: binding.parents;
        then
          ();

      case CEVAL_BINDING()
        algorithm
          binding.parents := parent :: binding.parents;
        then
          ();

      else ();
    end match;
  end addParent;

  function isClassBinding
    input Binding binding;
    output Boolean isClass;
  algorithm
    for parent in parents(binding) loop
      if InstNode.isClass(parent) then
        isClass := true;
        return;
      end if;
    end for;

    isClass := false;
  end isClassBinding;

  function countPropagatedDims
    "Returns the number of dimensions that the binding was propagated through to
     get to the element it belongs to."
    input Binding binding;
    output Integer count = 0;
  protected
    list<InstNode> pars;
  algorithm
    pars := match binding
      case UNTYPED_BINDING(isEach = false) then listRest(binding.parents);
      case TYPED_BINDING(isEach = false) then listRest(binding.parents);
      else {};
    end match;

    for parent in pars loop
      count := count + Type.dimensionCount(InstNode.getType(parent));
    end for;
  end countPropagatedDims;

  function toString
    input Binding binding;
    input String prefix = "";
    output String string;
  algorithm
    string := match binding
      case UNBOUND() then "";
      case RAW_BINDING() then prefix + Dump.printExpStr(binding.bindingExp);
      case UNTYPED_BINDING() then prefix + Expression.toString(binding.bindingExp);
      case TYPED_BINDING() then prefix + Expression.toString(binding.bindingExp);
      case FLAT_BINDING() then prefix + Expression.toString(binding.bindingExp);
      case CEVAL_BINDING() then prefix + Expression.toString(binding.bindingExp);
      case INVALID_BINDING() then toString(binding.binding, prefix);
    end match;
  end toString;

  function isEqual
    input Binding binding1;
    input Binding binding2;
    output Boolean equal;
  algorithm
    equal := match (binding1, binding2)
      case (UNBOUND(), UNBOUND()) then true;

      // TODO: Handle propagated dims.
      case (RAW_BINDING(), RAW_BINDING())
        then Absyn.expEqual(binding1.bindingExp, binding2.bindingExp);

      case (UNTYPED_BINDING(), UNTYPED_BINDING())
        then Expression.isEqual(binding1.bindingExp, binding2.bindingExp);

      case (TYPED_BINDING(), TYPED_BINDING())
        then Expression.isEqual(binding1.bindingExp, binding2.bindingExp);

      else false;
    end match;
  end isEqual;

  function toDAE
    input Binding binding;
    output DAE.Binding outBinding;
  algorithm
    outBinding := match binding
      case UNBOUND() then DAE.UNBOUND();
      case TYPED_BINDING() then makeDAEBinding(binding.bindingExp, binding.variability);
      case FLAT_BINDING() then makeDAEBinding(binding.bindingExp, binding.variability);
      case CEVAL_BINDING() then DAE.UNBOUND();
      case INVALID_BINDING()
        algorithm
          Error.addTotalMessages(binding.errors);
        then
          fail();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped binding", sourceInfo());
        then
          fail();
    end match;
  end toDAE;

  function makeDAEBinding
    input Expression exp;
    input Variability var;
    output DAE.Binding binding;
  algorithm
    binding := DAE.EQBOUND(
      Expression.toDAE(exp),
      NONE(),
      Variability.variabilityToDAEConst(var),
      DAE.BINDING_FROM_DEFAULT_VALUE() // TODO: revise this.
    );
  end makeDAEBinding;

  function toDAEExp
    input Binding binding;
    output Option<DAE.Exp> bindingExp;
  algorithm
    bindingExp := match binding
      case UNBOUND() then NONE();
      case TYPED_BINDING() then SOME(Expression.toDAE(binding.bindingExp));
      case FLAT_BINDING() then SOME(Expression.toDAE(binding.bindingExp));
      case CEVAL_BINDING() then NONE();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got untyped binding", sourceInfo());
        then
          fail();
    end match;
  end toDAEExp;

  function mapExp
    input output Binding binding;
    input MapFunc mapFn;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  protected
    Expression e1, e2;
  algorithm
    () := match binding
      case UNTYPED_BINDING(bindingExp = e1)
        algorithm
          e2 := mapFn(e1);

          if not referenceEq(e1, e2) then
            binding.bindingExp := e2;
          end if;
        then
          ();

      case TYPED_BINDING(bindingExp = e1)
        algorithm
          e2 := mapFn(e1);

          if not referenceEq(e1, e2) then
            binding.bindingExp := e2;
          end if;
        then
          ();

      case FLAT_BINDING(bindingExp = e1)
        algorithm
          e2 := mapFn(e1);

          if not referenceEq(e1, e2) then
            binding.bindingExp := e2;
          end if;
        then
          ();

      case CEVAL_BINDING(bindingExp = e1)
        algorithm
          e2 := mapFn(e1);

          if not referenceEq(e1, e2) then
            binding.bindingExp := e2;
          end if;
        then
          ();

      else ();
    end match;
  end mapExp;

  function containsExp
    input Binding binding;
    input PredFunc predFn;
    output Boolean res;

    partial function PredFunc
      input Expression exp;
      output Boolean res;
    end PredFunc;
  algorithm
    res := match binding
      case UNTYPED_BINDING() then Expression.contains(binding.bindingExp, predFn);
      case TYPED_BINDING()   then Expression.contains(binding.bindingExp, predFn);
      case FLAT_BINDING()    then Expression.contains(binding.bindingExp, predFn);
      case CEVAL_BINDING()   then Expression.contains(binding.bindingExp, predFn);
      else false;
    end match;
  end containsExp;
end Binding;

annotation(__OpenModelica_Interface="frontend");
end NFBinding;
