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

encapsulated package NFInline

import Expression = NFExpression;
import NFCall.Call;
import Statement = NFStatement;
import ComponentRef = NFComponentRef;
import DAE.InlineType;
import NFFunction.Function;
import NFInstNode.InstNode;
import Subscript = NFSubscript;
import Dimension = NFDimension;
import Type = NFType;

function inlineCallExp
  input Expression callExp;
  output Expression result;
algorithm
  result := match callExp
    local
      Call call;
      Boolean shouldInline;

    case Expression.CALL(call = call as Call.TYPED_CALL())
      algorithm
        shouldInline := match Call.inlineType(call)
          case DAE.InlineType.BUILTIN_EARLY_INLINE() then true;
          case DAE.InlineType.EARLY_INLINE()
            guard Flags.isSet(Flags.INLINE_FUNCTIONS) then true;
          else false;
        end match;
      then
        if shouldInline then inlineCall(call) else callExp;

    else callExp;
  end match;
end inlineCallExp;

function inlineCall
  input Call call;
  output Expression exp;
algorithm
  exp := match call
    local
      Function fn;
      Expression arg;
      list<Expression> args;
      list<InstNode> inputs, outputs, locals;
      list<Statement> body;
      Statement stmt;

    case Call.TYPED_CALL(fn = fn as Function.FUNCTION(inputs = inputs, outputs = outputs, locals = locals),
                         arguments = args)
      algorithm
        body := Function.getBody(fn);

        // This function can so far only handle functions with exactly one
        // statement and output and no local variables.
        if listLength(body) <> 1 or listLength(outputs) <> 1 or listLength(locals) > 0 then
          exp := Expression.CALL(call);
          return;
        end if;

        Error.assertion(listLength(inputs) == listLength(args),
          getInstanceName() + " got wrong number of arguments for " +
          Absyn.pathString(Function.name(fn)), sourceInfo());

        stmt := listHead(body);

        // TODO: Instead of repeating this for each input we should probably
        //       just build a lookup tree or hash table and go through the
        //       statement once.
        for i in inputs loop
          arg :: args := args;
          stmt := Statement.mapExp(stmt,
            function Expression.map(func = function replaceCrefNode(node = i, value = arg)));
        end for;
      then
        getOutputExp(stmt, listHead(outputs), call);

    else Expression.CALL(call);
  end match;
end inlineCall;

protected
function replaceCrefNode
  input output Expression exp;
  input InstNode node;
  input Expression value;
protected
  InstNode cr_node;
  ComponentRef rest_cr;
  list<Subscript> subs;
  Type ty, repl_ty;
algorithm
  exp := match exp

    // TODO: This only works for simple crefs, for complex crefs (i.e. records)
    //       we need to somehow replace the rest of the cref with nodes from the
    //       record.
    case Expression.CREF(cref = ComponentRef.CREF(node = cr_node, subscripts = subs, restCref = rest_cr))
      guard InstNode.refEqual(node, cr_node) and not ComponentRef.isFromCref(rest_cr)
      then Expression.applySubscripts(subs, value);

    else exp;
  end match;

  // Replace expressions in dimensions too.
  ty := Expression.typeOf(exp);
  repl_ty := Type.mapDims(ty, function replaceDimExp(node = node, value = value));

  if not referenceEq(ty, repl_ty) then
    exp := Expression.setType(repl_ty, exp);
  end if;
end replaceCrefNode;

function replaceDimExp
  input output Dimension dim;
  input InstNode node;
  input Expression value;
algorithm
  dim := match dim
    local
      Expression exp;

    case Dimension.EXP()
      algorithm
        exp := Expression.map(dim.exp, function replaceCrefNode(node = node, value = value));
      then
        Dimension.fromExp(exp, dim.var);

    else dim;
  end match;
end replaceDimExp;

function getOutputExp
  input Statement stmt;
  input InstNode outputNode;
  input Call call;
  output Expression exp;
algorithm
  exp := match stmt
    local
      InstNode cr_node;
      ComponentRef rest_cr;

    case Statement.ASSIGNMENT(lhs = Expression.CREF(
        cref = ComponentRef.CREF(node = cr_node, subscripts = {}, restCref = rest_cr)))
      guard InstNode.refEqual(outputNode, cr_node) and not ComponentRef.isFromCref(rest_cr)
      then stmt.rhs;

    else Expression.CALL(call);
  end match;
end getOutputExp;

annotation(__OpenModelica_Interface="frontend");
end NFInline;

