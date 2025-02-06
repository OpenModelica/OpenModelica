/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFStructural
  "Contains utility functions for handling structural parameters."

  import Attributes = NFAttributes;
  import Binding = NFBinding;
  import Call = NFCall;
  import Component = NFComponent;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import InstContext = NFInstContext;
  import NFInstNode.InstNode;
  import NFPrefixes.Variability;
  import Subscript = NFSubscript;

protected
  import Util;

public
  function isStructuralComponent
    input Component component;
    input Attributes compAttrs;
    input Binding compBinding;
    input InstNode compNode;
    input Boolean compEval "If the component has an Evaluate=true annotation";
    input Boolean parentEval "If any parent has an Evaluate=true annotation";
    input InstContext.Type context;
    output Boolean isStructural;
  protected
    Boolean is_fixed;
    Binding binding;
  algorithm
    if compAttrs.variability <> Variability.PARAMETER then
      // Only parameters can be structural.
      isStructural := false;
    elseif compEval or parentEval then
      binding := if Binding.isBound(compBinding) then
        compBinding else Component.getTypeAttributeBinding(component, "start");

      // If the component or any of its parents has an Evaluate=true annotation
      // we should probably evaluate the parameter, which we do by marking it as
      // structural.
      if not Component.isFixed(component) then
        // Except non-fixed parameters.
        isStructural := false;
      elseif Component.isExternalObject(component) then
        // Except external objects.
        isStructural := false;
      elseif not (Binding.isBound(binding) or InstNode.hasBinding(compNode)) then
        // Except parameters with no bindings.
        if not parentEval and not InstContext.inRelaxed(context) then
          // Print a warning if a parameter has an Evaluate=true annotation but no binding.
          Error.addSourceMessage(Error.UNBOUND_PARAMETER_EVALUATE_TRUE,
            {InstNode.name(compNode)}, InstNode.info(compNode));
        end if;

        isStructural := false;
      elseif isBindingNotFixed(binding, requireFinal = false) then
        // Except parameters that depend on non-fixed parameters.
        isStructural := false;
      else
        // All other parameters are considered structural in this case.
        isStructural := true;
      end if;
    //elseif Component.isFinal(component) and Component.isFixed(component) then
    //  // If a parameter is fixed and final we might also want to evaluate it,
    //  // since its binding can't be modified. But only if all parameters it
    //  // depends on are also fixed and final.
    //  if Binding.isUnbound(binding) or isBindingNotFixed(binding, requireFinal = true) then
    //    isStructural := false;
    //  else
    //    isStructural := true;
    //  end if;
    else
      isStructural := false;
    end if;
  end isStructuralComponent;

  function isBindingNotFixed
    input Binding binding;
    input Boolean requireFinal;
    input Integer maxDepth = 4;
    output Boolean isNotFixed;
  algorithm
    if maxDepth == 0 then
      isNotFixed := true;
      return;
    end if;

    if Binding.hasExp(binding) then
      isNotFixed := isExpressionNotFixed(Binding.getExp(binding), requireFinal, maxDepth);
    else
      isNotFixed := true;
    end if;
  end isBindingNotFixed;

  function isComponentBindingNotFixed
    input Component component;
    input InstNode node;
    input Boolean requireFinal;
    input Integer maxDepth;
    input Boolean isRecord = false;
    output Boolean isNotFixed;
  protected
    Binding binding;
    InstNode parent;
  algorithm
    binding := Component.getBinding(component);

    if Binding.isUnbound(binding) then
      if isRecord or InstNode.isRecord(node) then
        // TODO: Check whether the record fields have bindings or not.
        isNotFixed := false;
      else
        parent := InstNode.parent(node);

        if InstNode.isComponent(parent) and InstNode.isRecord(parent) then
          isNotFixed := isComponentBindingNotFixed(InstNode.component(parent), parent, requireFinal, maxDepth, true);
        else
          binding := Component.getTypeAttributeBinding(component, "start");
          isNotFixed := isBindingNotFixed(binding, requireFinal, maxDepth);
        end if;
      end if;
    else
      isNotFixed := isBindingNotFixed(binding, requireFinal, maxDepth);
    end if;
  end isComponentBindingNotFixed;

  function isExpressionNotFixed
    input Expression exp;
    input Boolean requireFinal = false;
    input Integer maxDepth = 4;
    output Boolean isNotFixed;
  algorithm
    isNotFixed := match exp
      local
        InstNode node;
        Component c;
        Variability var;
        Expression e;

      case Expression.CREF()
        guard ComponentRef.isCref(exp.cref) and not ComponentRef.isIterator(exp.cref)
        algorithm
          node := ComponentRef.node(exp.cref);

          if InstNode.isComponent(node) then
            c := InstNode.component(node);
            var := Component.variability(c);

            if var <= Variability.STRUCTURAL_PARAMETER then
              isNotFixed := false;
            elseif var == Variability.PARAMETER and
                   (not requireFinal or Component.isFinal(c)) and
                   not Component.isExternalObject(c) and
                   Component.isFixed(c) then
              isNotFixed := isComponentBindingNotFixed(c, node, requireFinal, maxDepth - 1);
            else
              isNotFixed := true;
            end if;
          else
            isNotFixed := true;
          end if;
        then
          isNotFixed or
          Expression.containsShallow(exp,
            function isExpressionNotFixed(requireFinal = requireFinal, maxDepth = maxDepth));

      case Expression.SIZE()
        algorithm
          if isSome(exp.dimIndex) then
            isNotFixed := isExpressionNotFixed(Util.getOption(exp.dimIndex), requireFinal, maxDepth);
          else
            isNotFixed := false;
          end if;
        then
          isNotFixed;

      case Expression.CALL()
        algorithm
          if Call.isImpure(exp.call) or Call.isExternal(exp.call) then
            isNotFixed := true;
          else
            isNotFixed := Expression.containsShallow(exp,
              function isExpressionNotFixed(requireFinal = requireFinal, maxDepth = maxDepth));
          end if;
        then
          isNotFixed;

      else Expression.containsShallow(exp,
        function isExpressionNotFixed(requireFinal = requireFinal, maxDepth = maxDepth));
    end match;
  end isExpressionNotFixed;

  function markDimension
    input Dimension dimension;
  algorithm
    () := match dimension
      case Dimension.UNTYPED()
        algorithm
          markExp(dimension.dimension);
        then
          ();

      case Dimension.EXP()
        algorithm
          markExp(dimension.exp);
        then
          ();

      else ();
    end match;
  end markDimension;

  function markExp
    input Expression exp;
    import NFComponentRef.Origin;
  algorithm
    () := match exp
      local
        InstNode node;
        Component comp;
        Expression e;

      case Expression.CREF(cref = ComponentRef.CREF(node = node, origin = Origin.CREF))
        algorithm
          if InstNode.isComponent(node) then
            comp := InstNode.component(node);

            if Component.variability(comp) == Variability.PARAMETER then
              markComponent(comp, node);
            end if;
          end if;

          Expression.applyShallow(exp, markExp);
        then
          ();

      case Expression.SIZE()
        algorithm
          // The expression in the size expression should not be marked as
          // structural, since only the type of it matters to determine the size.
          // Subscripts in the expression should be marked as structural though.
          markSubscriptsInExp(exp.exp);

          // The optional index should be marked as structural.
          if isSome(exp.dimIndex) then
            SOME(e) := exp.dimIndex;
            markExp(e);
          end if;
        then
          ();

      else
        algorithm
          Expression.applyShallow(exp, markExp);
        then
          ();
    end match;
  end markExp;

  function markSubscriptsInExp
    input Expression exp;
  algorithm
    () := match exp
      case Expression.CREF()
        algorithm
          ComponentRef.applySubscripts(exp.cref, markSubscript);
        then
          ();

      else
        algorithm
          Expression.applyShallow(exp, markSubscriptsInExp);
        then
          ();
    end match;
  end markSubscriptsInExp;

  function markComponent
    input Component component;
    input InstNode node;
  protected
    Component comp;
    Option<Expression> binding;
  algorithm
    comp := Component.setVariability(Variability.STRUCTURAL_PARAMETER, component);
    InstNode.updateComponent(comp, node);

    binding := Binding.untypedExp(Component.getBinding(comp));
    if isSome(binding) then
      markExp(Util.getOption(binding));
    end if;
  end markComponent;

  function markExpSize
    input Expression exp;
  algorithm
    Expression.apply(exp, markExpSize_traverser);
  end markExpSize;

  function markExpSize_traverser
    input Expression exp;
  algorithm
    () := match exp
      local
        list<tuple<InstNode, Expression>> iters;

      case Expression.CALL(call = Call.UNTYPED_ARRAY_CONSTRUCTOR(iters = iters))
        algorithm
          for iter in iters loop
            markExp(Util.tuple22(iter));
          end for;
        then
          ();

      else ();
    end match;
  end markExpSize_traverser;

  function markSubscripts
    input Expression exp;
  algorithm
    () := match exp
      case Expression.CREF()
        algorithm
          ComponentRef.applySubscripts(exp.cref, markSubscript);
        then
          ();

      else ();
    end match;
  end markSubscripts;

  function markSubscript
    input Subscript sub;
  algorithm
    () := match sub
        case Subscript.UNTYPED() algorithm markExp(sub.exp); then ();
        case Subscript.INDEX() algorithm markExp(sub.index); then ();
        case Subscript.SLICE() algorithm markExp(sub.slice); then ();
      else ();
    end match;
  end markSubscript;

  annotation(__OpenModelica_Interface="frontend");
end NFStructural;
