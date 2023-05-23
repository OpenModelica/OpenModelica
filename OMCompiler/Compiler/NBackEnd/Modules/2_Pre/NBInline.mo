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
encapsulated uniontype NBInline<T>
" file:         NBInline.mo
  package:      NBInline
  description:  This file contains functions for inlining operations.
"

protected
  import Inline = NBInline;

  // OF imports
  import Absyn;
  import AbsynUtil;
  import DAE;
  import DAEUtil;

  // NF imports
  import NFFunction.Function;
  import NFFlatten.FunctionTree;
  import Statement = NFStatement;

  // NB imports
  import Module = NBModule;
  import BackendDAE = NBackendDAE;
  import NBEquation.EqData;
  import Replacements = NBReplacements;
  import NBVariable.VarData;

  // Util imports
  import BaseAvlTree;

// =========================================================================
//                      MAIN ROUTINE, PLEASE DO NOT CHANGE
// =========================================================================
public
  function main
    "Wrapper function for any inlining function. This will be
     called during simulation and gets the corresponding subfunction from
     the given input."
    extends Module.wrapper;
    input list<DAE.InlineType> inline_types;
  algorithm
    bdae := match bdae
      case BackendDAE.MAIN()
        algorithm
          bdae.eqData := inline(bdae.eqData, bdae.funcTree, inline_types);
        then bdae;

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end main;

// =========================================================================
//                    TYPES, UNIONTYPES AND MEMBER FUNCTIONS
// =========================================================================
  function inline extends Module.inlineInterface;
  protected
    UnorderedMap<Absyn.Path, Function> replacements "rules for replacements are stored inside here";
  algorithm
    // collect functions
    replacements := UnorderedMap.new<Function>(AbsynUtil.pathHash, AbsynUtil.pathEqual);
    replacements := FunctionTree.fold(funcTree, function collectInlineFunctions(inline_types = inline_types), replacements);

    // apply replacements
    eqData := Replacements.replaceFunctions(eqData, replacements);
  end inline;

  function collectInlineFunctions
    "collects all functions that have one of the inline types,
    use with FunctionTree.fold()"
    input Absyn.Path key;
    input Function value;
    input output UnorderedMap<Absyn.Path, Function> replacements;
    input list<DAE.InlineType> inline_types;
  algorithm
    // only add to the map if the function has one of the inline types and is inlineable
    if List.contains(inline_types, Function.inlineBuiltin(value), DAEUtil.inlineTypeEqual) and functionInlineable(value) then
      UnorderedMap.add(key, value, replacements);
    end if;
  end collectInlineFunctions;

  function functionInlineable
    "returns true if the function can be inlined"
    input Function fn;
    output Boolean b;
  algorithm
    // currently we only inline single assignments
    // also check for single output?
    b := match Function.getBody(fn)
      case {Statement.ASSIGNMENT()} then true;
      else false;
    end match;
  end functionInlineable;
  annotation(__OpenModelica_Interface="backend");
end NBInline;
