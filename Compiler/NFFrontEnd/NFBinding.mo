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
" file:        NFMod.mo
  package:     NFMod
  description: A type for bindings in NFInst.
"

public
import DAE;
import NFComponent.Component;
import NFInstNode.InstNode;
import SCode;

protected
import Dump;
import ExpressionDump;

public
uniontype Binding
  record UNBOUND end UNBOUND;

  record RAW_BINDING
    Absyn.Exp bindingExp;
    SCode.Final finalPrefix;
    SCode.Each eachPrefix;
    Component.Scope scope;
    Integer propagatedDims;
    SourceInfo info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    Absyn.Exp bindingExp;
    Boolean isProcessing;
    Component.Scope scope;
    Integer propagatedDims;
    SourceInfo info;
  end UNTYPED_BINDING;

  record TYPED_BINDING
    DAE.Exp bindingExp;
    DAE.Type bindingType;
    Integer propagatedDims;
    SourceInfo info;
  end TYPED_BINDING;

public
  function fromAbsyn
    input Option<Absyn.Exp> bindingExp;
    input SCode.Final finalPrefix;
    input SCode.Each eachPrefix;
    input Integer dimensions;
    input SourceInfo info;
    output Binding binding;
  algorithm
    binding := match bindingExp
      local
        Absyn.Exp exp;
        Integer pd;
        Component.Scope scope;

      case SOME(exp)
        algorithm
          pd := if SCode.eachBool(eachPrefix) then -1 else dimensions;
          scope := Component.Scope.RELATIVE_COMP(0);
        then
          RAW_BINDING(exp, finalPrefix, eachPrefix, scope, pd, info);

      else UNBOUND();
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

  function untypedExp
    input Binding binding;
    output Option<Absyn.Exp> exp;
  algorithm
    exp := match binding
      case UNTYPED_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end untypedExp;

  function typedExp
    input Binding binding;
    output Option<DAE.Exp> exp;
  algorithm
    exp := match binding
      case TYPED_BINDING() then SOME(binding.bindingExp);
      else NONE();
    end match;
  end typedExp;

  function getInfo
    input Binding binding;
    output SourceInfo info;
  algorithm
    info := match binding
      case UNBOUND() then Absyn.dummyInfo;
      case RAW_BINDING() then binding.info;
      case UNTYPED_BINDING() then binding.info;
      case TYPED_BINDING() then binding.info;
    end match;
  end getInfo;

  function isEach
    input Binding binding;
    output Boolean isEach;
  algorithm
    isEach := match binding
      case RAW_BINDING() then binding.propagatedDims == -1;
      case UNTYPED_BINDING() then binding.propagatedDims == -1;
      case TYPED_BINDING() then binding.propagatedDims == -1;
      else false;
    end match;
  end isEach;

  function toString
    input Binding binding;
    input String prefix = "";
    output String string;
  algorithm
    string := match binding
      case UNBOUND() then "";
      case RAW_BINDING() then prefix + Dump.printExpStr(binding.bindingExp);
      case UNTYPED_BINDING() then prefix + Dump.printExpStr(binding.bindingExp);
      case TYPED_BINDING() then prefix + ExpressionDump.printExpStr(binding.bindingExp);
    end match;
  end toString;

end Binding;

annotation(__OpenModelica_Interface="frontend");
end NFBinding;
