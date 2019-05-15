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

encapsulated package Prefix
" file:        Prefix.mo
  package:     Prefix
  description: Prefix management


  When instantiating an expression, there is a prefix that
  has to be added to each variable name to be able to use it in the
  flattened equation set.

  A prefix for a variable x could be for example a.b.c so that the
  fully qualified name is a.b.c.x.

  For utility function, see PrefixUtil.mo "


public import SCode;
public import ClassInf;
public import DAE;

public
uniontype Prefix "A Prefix has a component prefix and a class prefix.
The component prefix consist of a name an a list of constant valued subscripts.
The class prefix contains the variability of the class, i.e unspecified, parameter or constant."

  record NOPRE "No prefix information" end NOPRE;

  record PREFIX
    ComponentPrefix compPre "component prefixes are stored in inverse order c.b.a";
    ClassPrefix classPre "the class prefix, i.e. variability, var, discrete, param, const";
  end PREFIX;
end Prefix;

type ComponentPrefixOpt = Option<ComponentPrefix> "a type alias for an optional component prefix";

uniontype ComponentPrefix
"Prefix for component name, e.g. a.b[2].c.
 NOTE: Component prefixes are stored in inverse order c.b[2].a!"
  record PRE
    String prefix "prefix name" ;
    list<DAE.Dimension> dimensions "dimensions" ;
    list<DAE.Subscript> subscripts "subscripts" ;
    ComponentPrefix next "next prefix" ;
    ClassInf.State ci_state "to be able to at least partially fill in type information properly for DAE.VAR";
    SourceInfo info;
  end PRE;

  record NOCOMPPRE end NOCOMPPRE;
end ComponentPrefix;

uniontype ClassPrefix "Prefix for classes is its variability"
  record CLASSPRE
    SCode.Variability variability "VAR, DISCRETE, PARAM, or CONST";
  end CLASSPRE;
end ClassPrefix;

annotation(__OpenModelica_Interface="frontend");
end Prefix;
