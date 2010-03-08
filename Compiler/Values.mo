/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Values
" file:        Values.mo
  package:     Values
  description: Evaluated expression values

  RCS: $Id$

  The package Values contains data structures for representing
  constant Modelica values.  These include integer, real, string and
  boolean values, and also arrays of any dimensionality and type.
  Multidimensional arrays are represented as arrays of arrays.

  The code is excluded from the report, since they convey no
  semantic information."

public import Absyn;

public
uniontype Value
  record INTEGER
    Integer integer;
  end INTEGER;

  record REAL
    Real real;
  end REAL;

  record STRING
    String string;
  end STRING;

  record BOOL
    Boolean boolean;
  end BOOL;

  record ENUM
    Integer index;
    Absyn.Path path "The path corresponding to the cref in the type";
    list<String> names;
  end ENUM;

  record ARRAY
    list<Value> valueLst;
    list<Integer> dimLst;
  end ARRAY;

  record LIST "MetaModelica list"
    list<Value> valueLst;
  end LIST;

  record META_ARRAY "MetaModelica array"
    list<Value> valueLst;
  end META_ARRAY;

  record TUPLE "Modelica Tuple"
    list<Value> valueLst;
  end TUPLE;

  record META_TUPLE "MetaModelica Tuple"
    list<Value> valueLst;
  end META_TUPLE;

  record RECORD
    Absyn.Path record_ "record name" ;
    list<Value> orderd "orderd set of values" ;
    list<String> comp "comp names for each value" ;
    Integer index "-1 for regular records, 0..n-1 for uniontypes containing n records";
  end RECORD;

  record OPTION
    Option<Value> some;
  end OPTION;

  record CODE
    Absyn.CodeNode A "A record consist of value  Ident pairs" ;
  end CODE;

  record NORETCALL
  end NORETCALL;

end Value;

public uniontype IntRealOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
  record LESSEQOP end LESSEQOP;
end IntRealOp;

end Values;

