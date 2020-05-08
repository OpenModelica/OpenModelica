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

encapsulated uniontype NFAlgorithm
  import Statement = NFStatement;
  import DAE.ElementSource;
  import Expression = NFExpression;

protected
  import Algorithm = NFAlgorithm;

public
  record ALGORITHM
    list<Statement> statements;
    ElementSource source;
  end ALGORITHM;

  partial function ApplyFn
    input Statement alg;
  end ApplyFn;

  function applyList
    input list<Algorithm> algs;
    input ApplyFn func;
  algorithm
    for alg in algs loop
      for s in alg.statements loop
        Statement.apply(s, func);
      end for;
    end for;
  end applyList;

  function apply
    input Algorithm alg;
    input ApplyFn func;
  algorithm
    for s in alg.statements loop
      Statement.apply(s, func);
    end for;
  end apply;

  function applyExp
    input Algorithm alg;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for s in alg.statements loop
      Statement.applyExp(s, func);
    end for;
  end applyExp;

  function applyExpList
    input list<Algorithm> algs;
    input ApplyFunc func;

    partial function ApplyFunc
      input Expression exp;
    end ApplyFunc;
  algorithm
    for alg in algs loop
      applyExp(alg, func);
    end for;
  end applyExpList;

  function mapExp
    input output Algorithm alg;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    alg.statements := Statement.mapExpList(alg.statements, func);
  end mapExp;

  function mapExpList
    input output list<Algorithm> algs;
    input MapFunc func;

    partial function MapFunc
      input output Expression exp;
    end MapFunc;
  algorithm
    algs := list(mapExp(alg, func) for alg in algs);
  end mapExpList;

  function foldExp<ArgT>
    input Algorithm alg;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for s in alg.statements loop
      arg := Statement.foldExp(s, func, arg);
    end for;
  end foldExp;

  function foldExpList<ArgT>
    input list<Algorithm> algs;
    input FoldFunc func;
    input output ArgT arg;

    partial function FoldFunc
      input Expression exp;
      input output ArgT arg;
    end FoldFunc;
  algorithm
    for alg in algs loop
      arg := foldExp(alg, func, arg);
    end for;
  end foldExpList;

  function toString
    input Algorithm alg;
    input String indent = "";
    output String str;
  algorithm
    str := Statement.toStringList(alg.statements, indent);
  end toString;

  annotation(__OpenModelica_Interface="frontend");
end NFAlgorithm;
