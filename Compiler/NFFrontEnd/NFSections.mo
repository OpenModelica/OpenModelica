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

encapsulated uniontype NFSections
  import Equation = NFEquation;
  import Algorithm = NFAlgorithm;
  import Statement = NFStatement;
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import SCode.Annotation;

protected
  import Sections = NFSections;

public
  record SECTIONS
    list<Equation> equations;
    list<Equation> initialEquations;
    list<Algorithm> algorithms;
    list<Algorithm> initialAlgorithms;
  end SECTIONS;

  record EXTERNAL
    String name;
    list<Expression> args;
    ComponentRef outputRef;
    String language;
    Option<SCode.Annotation> ann;
    Boolean explicit;
  end EXTERNAL;

  record EMPTY end EMPTY;

  function new
    input list<Equation> equations;
    input list<Equation> initialEquations;
    input list<Algorithm> algorithms;
    input list<Algorithm> initialAlgorithms;
    output Sections sections;
  algorithm
    if listEmpty(equations) and listEmpty(initialEquations) and
       listEmpty(algorithms) and listEmpty(initialAlgorithms) then
      sections := EMPTY();
    else
      sections := SECTIONS(equations, initialEquations, algorithms, initialAlgorithms);
    end if;
  end new;

  function prepend
    input list<Equation> equations;
    input list<Equation> initialEquations;
    input list<Algorithm> algorithms;
    input list<Algorithm> initialAlgorithms;
    input output Sections sections;
  algorithm
    sections := match sections
      case SECTIONS()
        then SECTIONS(
          listAppend(equations, sections.equations),
          listAppend(initialEquations, sections.initialEquations),
          listAppend(algorithms, sections.algorithms),
          listAppend(initialAlgorithms, sections.initialAlgorithms));

      else SECTIONS(equations, initialEquations, algorithms, initialAlgorithms);
    end match;
  end prepend;

  function prependEquation
    input Equation eq;
    input output Sections sections;
    input Boolean isInitial = false;
  algorithm
    sections := match sections
      case SECTIONS()
        algorithm
          if isInitial then
            sections.initialEquations := eq :: sections.initialEquations;
          else
            sections.equations := eq :: sections.equations;
          end if;
        then
          sections;

      case EMPTY()
        then if isInitial then SECTIONS({}, {eq}, {}, {}) else SECTIONS({eq}, {}, {}, {});

      else
        algorithm
          Error.assertion(false, getInstanceName() +
            " got invalid Sections to prepend equation to", sourceInfo());
        then
          fail();

    end match;
  end prependEquation;

  function append
    input list<Equation> equations;
    input list<Equation> initialEquations;
    input list<Algorithm> algorithms;
    input list<Algorithm> initialAlgorithms;
    input output Sections sections;
  algorithm
    sections := match sections
      case SECTIONS()
        then SECTIONS(
          listAppend(sections.equations, equations),
          listAppend(sections.initialEquations, initialEquations),
          listAppend(sections.algorithms, algorithms),
          listAppend(sections.initialAlgorithms, initialAlgorithms));

      else SECTIONS(equations, initialEquations, algorithms, initialAlgorithms);
    end match;
  end append;

  function join
    input Sections sections1;
    input Sections sections2;
    output Sections sections;
  algorithm
    sections := match (sections1, sections2)
      case (EMPTY(), _) then sections2;
      case (_, EMPTY()) then sections1;

      case (SECTIONS(), SECTIONS())
        then SECTIONS(
          listAppend(sections1.equations, sections2.equations),
          listAppend(sections1.initialEquations, sections2.initialEquations),
          listAppend(sections1.algorithms, sections2.algorithms),
          listAppend(sections1.initialAlgorithms, sections2.initialAlgorithms));

    end match;
  end join;

  function map
    input output Sections sections;
    input EquationFn eqFn;
    input AlgorithmFn algFn;
    input EquationFn ieqFn = eqFn;
    input AlgorithmFn ialgFn = algFn;

    partial function EquationFn
      input output Equation eq;
    end EquationFn;

    partial function AlgorithmFn
      input output Algorithm alg;
    end AlgorithmFn;
  protected
    list<Equation> eq, ieq;
    list<Algorithm> alg, ialg;
  algorithm
    () := match sections
      case SECTIONS()
        algorithm
          eq := list(eqFn(e) for e in sections.equations);
          ieq := list(ieqFn(e) for e in sections.initialEquations);
          alg := list(algFn(a) for a in sections.algorithms);
          ialg := list(ialgFn(a) for a in sections.initialAlgorithms);
          sections := SECTIONS(eq, ieq, alg, ialg);
        then
          ();

      else ();
    end match;
  end map;

  function map1<ArgT>
    input output Sections sections;
    input ArgT arg;
    input EquationFn eqFn;
    input AlgorithmFn algFn;
    input EquationFn ieqFn = eqFn;
    input AlgorithmFn ialgFn = algFn;

    partial function EquationFn
      input output Equation eq;
      input ArgT arg;
    end EquationFn;

    partial function AlgorithmFn
      input output Algorithm alg;
      input ArgT arg;
    end AlgorithmFn;
  protected
    list<Equation> eq, ieq;
    list<Algorithm> alg, ialg;
  algorithm
    () := match sections
      case SECTIONS()
        algorithm
          eq := list(eqFn(e, arg) for e in sections.equations);
          ieq := list(ieqFn(e, arg) for e in sections.initialEquations);
          alg := list(algFn(a, arg) for a in sections.algorithms);
          ialg := list(ialgFn(a, arg) for a in sections.initialAlgorithms);
          sections := SECTIONS(eq, ieq, alg, ialg);
        then
          ();

      else ();
    end match;
  end map1;

  function apply
    input Sections sections;
    input EquationFn eqFn;
    input AlgorithmFn algFn;
    input EquationFn ieqFn = eqFn;
    input AlgorithmFn ialgFn = algFn;

    partial function EquationFn
      input Equation eq;
    end EquationFn;

    partial function AlgorithmFn
      input Algorithm alg;
    end AlgorithmFn;
  algorithm
    () := match sections
      case SECTIONS()
        algorithm
          for eq in sections.equations loop
            eqFn(eq);
          end for;

          for ieq in sections.initialEquations loop
            ieqFn(ieq);
          end for;

          for alg in sections.algorithms loop
            algFn(alg);
          end for;

          for ialg in sections.initialAlgorithms loop
            ialgFn(ialg);
          end for;
        then
          ();

      else ();
    end match;
  end apply;

  function isEmpty
    input Sections sections;
    output Boolean isEmpty;
  algorithm
    isEmpty := match sections
      case EMPTY() then true;
      else false;
    end match;
  end isEmpty;

annotation(__OpenModelica_Interface="frontend");
end NFSections;
