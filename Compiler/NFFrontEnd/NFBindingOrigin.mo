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

encapsulated uniontype NFBindingOrigin
  import NFModifier.ModifierScope;

protected
  import BindingOrigin = NFBindingOrigin;

public
  type ElementType = enumeration(COMPONENT, EXTENDS, CLASS);

  record ORIGIN
    Integer level;
    ElementType ty;
    SourceInfo info;
  end ORIGIN;

  function create
    input Boolean eachPrefix;
    input Integer level;
    input ElementType ty;
    input SourceInfo info;
    output BindingOrigin origin;
  algorithm
    origin := ORIGIN(if eachPrefix then -level else level, ty, info);
  end create;

  function level
    input BindingOrigin origin;
    output Integer level = origin.level;
  end level;

  function isEach
    input BindingOrigin origin;
    output Boolean isEach = origin.level < 0;
  end isEach;

  function info
    input BindingOrigin origin;
    output SourceInfo info = origin.info;
  end info;

  function isFromClass
    input BindingOrigin origin;
    output Boolean fromClass;
  protected
    ElementType ty = origin.ty;
  algorithm
    fromClass := ty == ElementType.CLASS;
  end isFromClass;

  annotation(__OpenModelica_Interface="frontend");
end NFBindingOrigin;
