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

encapsulated uniontype NFCallAttributes
protected
  import DAE;
  import NFType;
public
  record CALL_ATTR
    Boolean tuple_ "tuple" ;
    Boolean builtin "builtin Function call" ;
    Boolean isImpure "if the function has prefix *impure* is true, else false";
    Boolean isFunctionPointerCall;
    DAE.InlineType inlineType;
    DAE.TailCall tailCall "Input variables of the function if the call is tail-recursive";
  end CALL_ATTR;

  function toDAE
    input NFCallAttributes attr;
    input NFType returnType;
    output DAE.CallAttributes fattr;
  algorithm
    fattr := DAE.CALL_ATTR(NFType.toDAE(returnType), attr.tuple_, attr.builtin,
      attr.isImpure, attr.isFunctionPointerCall, attr.inlineType, attr.tailCall);
  end toDAE;

annotation(__OpenModelica_Interface="frontend");
end NFCallAttributes;
