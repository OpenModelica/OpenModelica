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

encapsulated package Values
" file:        Values.mo
  package:     Values
  description: Evaluated expression values


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

  record ENUM_LITERAL
    Absyn.Path name;
    Integer index;
  end ENUM_LITERAL;

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

  record META_BOX
    Value value;
  end META_BOX;

  record META_FAIL
    "If the result of constant evaluation of a MetaModelica function call is fail(),
    we need to propagate this value in order to avoid running the code over and over again.
    This is mostly an optimization."
  end META_FAIL;

  record EMPTY
    "an empty value, meaning a constant without a binding. is used to be able to continue the evaluation of a model even if there are constants with
     no bindings. at the end, when we have the DAE we should have no EMPTY values or expressions in it when we need to simulate the model.
     From Modelica specification: a package may we look inside should not be partial in a simulation model!"
    String scope "the scope where we could not find the binding";
    String name "the name of the variable";
    Value ty "the DAE.Type translated to Value using defaults";
    String tyStr "the type of the variable";
  end EMPTY;
end Value;

public uniontype IntRealOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
  record LESSEQOP end LESSEQOP;
end IntRealOp;

annotation(__OpenModelica_Interface="frontend");
end Values;
