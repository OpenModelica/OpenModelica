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
import SCode;
import DAE;
//import NFEnvScope.ScopeIndex;

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
    //ScopeIndex scope;
    Integer propagatedDims;
    SourceInfo info;
  end RAW_BINDING;

  record UNTYPED_BINDING
    DAE.Exp bindingExp;
    Boolean isProcessing;
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
    input Option<Absyn.Exp> inBinding;
    input SCode.Final inFinal;
    input SCode.Each inEach;
    input SourceInfo inInfo;
    output Binding outBinding;
  algorithm
    outBinding := match inBinding
      local
        Absyn.Exp exp;

      case SOME(exp)
        then RAW_BINDING(exp, inFinal, inEach, 0, inInfo);

      else UNBOUND();
    end match;
  end fromAbsyn;

  function isBound
    input Binding inBinding;
    output Boolean outIsBound;
  algorithm
    outIsBound := match inBinding
      case UNBOUND() then false;
      else true;
    end match;
  end isBound;

  function untypedExp
    input Binding inBinding;
    output Option<DAE.Exp> outExp;
  algorithm
    outExp := match inBinding
      case UNTYPED_BINDING() then SOME(inBinding.bindingExp);
      else NONE();
    end match;
  end untypedExp;

  function toString
    input Binding inBinding;
    input String inPrefix = "";
    output String outString;
  algorithm
    outString := match inBinding
      case UNBOUND() then "";
      case RAW_BINDING() then inPrefix + Dump.printExpStr(inBinding.bindingExp);
      case UNTYPED_BINDING() then inPrefix + ExpressionDump.printExpStr(inBinding.bindingExp);
      case TYPED_BINDING() then inPrefix + ExpressionDump.printExpStr(inBinding.bindingExp);
    end match;
  end toString;

end Binding;

annotation(__OpenModelica_Interface="frontend");
end NFBinding;
