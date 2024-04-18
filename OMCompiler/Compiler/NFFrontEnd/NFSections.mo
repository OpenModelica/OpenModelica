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
  import SCodeUtil;
  import IOStream;

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
    Option<Annotation> ann;
    Boolean explicit;
    SourceInfo info;
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

  function equations
    input Sections sections;
    output list<Equation> equations;
  algorithm
    equations := match sections
      case SECTIONS() then sections.equations;
      else {};
    end match;
  end equations;

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

  function prependAlgorithm
    input Algorithm alg;
    input output Sections sections;
    input Boolean isInitial = false;
  algorithm
    sections := match sections
      case SECTIONS()
        algorithm
          if isInitial then
            sections.initialAlgorithms := alg :: sections.initialAlgorithms;
          else
            sections.algorithms := alg :: sections.algorithms;
          end if;
        then
          sections;

      case EMPTY()
        then if isInitial then SECTIONS({}, {}, {}, {alg}) else SECTIONS({}, {}, {alg}, {});

      else
        algorithm
          Error.assertion(false, getInstanceName() +
            " got invalid Sections to prepend algorithm to", sourceInfo());
        then
          fail();

    end match;
  end prependAlgorithm;

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
    input EquationFn eqFn = eqId;
    input AlgorithmFn algFn = algId;
    input EquationFn ieqFn = eqFn;
    input AlgorithmFn ialgFn = algFn;

    partial function EquationFn
      input output Equation eq;
    end EquationFn;

    partial function AlgorithmFn
      input output Algorithm alg;
    end AlgorithmFn;

    function eqId
      input output Equation eq;
    end eqId;

    function algId
      input output Algorithm alg;
    end algId;
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

  function mapExp
    input output Sections sections;
    input MapFn mapFn;

    partial function MapFn
      input output Expression exp;
    end MapFn;
  protected
    list<Equation> eq, ieq;
    list<Algorithm> alg, ialg;
  algorithm
    sections := match sections
      case SECTIONS()
        algorithm
          eq := Equation.mapExpList(sections.equations, mapFn);
          ieq := Equation.mapExpList(sections.initialEquations, mapFn);
          alg := Algorithm.mapExpList(sections.algorithms, mapFn);
          ialg := Algorithm.mapExpList(sections.initialAlgorithms, mapFn);
        then
          SECTIONS(eq, ieq, alg, ialg);

      case EXTERNAL()
        algorithm
          sections.args := list(mapFn(e) for e in sections.args);
        then
          sections;

      else sections;
    end match;
  end mapExp;

  function foldExp<ArgT>
    input Sections sections;
    input FoldFn foldFn;
    input output ArgT arg;

    partial function FoldFn
      input Expression exp;
      input output ArgT arg;
    end FoldFn;
  algorithm
    arg := match sections
      case SECTIONS()
        algorithm
          arg := Equation.foldExpList(sections.equations, foldFn, arg);
          arg := Equation.foldExpList(sections.initialEquations, foldFn, arg);
          arg := Algorithm.foldExpList(sections.algorithms, foldFn, arg);
          arg := Algorithm.foldExpList(sections.initialAlgorithms, foldFn, arg);
        then
          arg;

      case EXTERNAL()
        then List.fold(sections.args, foldFn, arg);

      else arg;
    end match;
  end foldExp;

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

  function toFlatStream
    input Sections sections;
    input Absyn.Path scopeName;
    input String indent;
    input output IOStream.IOStream s;
  protected
    Annotation ann;
    SCode.Mod mod, modLib, modInc, modLibDir, modIncDir;
  algorithm
    () := match sections
      case SECTIONS()
        algorithm
          for alg in sections.algorithms loop
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "algorithm\n");
            s := Statement.toFlatStreamList(alg.statements, indent + "  ", s);
          end for;
        then ();
      case EXTERNAL()
        algorithm
          s := IOStream.append(s, indent);
          s := IOStream.append(s, "external \"");
          s := IOStream.append(s, sections.language);
          s := IOStream.append(s, "\"");
          if sections.explicit then
            if not ComponentRef.isEmpty(sections.outputRef) then
              s := IOStream.append(s, " ");
              s := IOStream.append(s, ComponentRef.toFlatString(sections.outputRef));
              s := IOStream.append(s, " =");
            end if;
            s := IOStream.append(s, " ");
            s := IOStream.append(s, sections.name);
            s := IOStream.append(s, "(");
            s := IOStream.append(s, stringDelimitList(list(Expression.toFlatString(e) for e in sections.args), ", "));
            s := IOStream.append(s, ")");
          end if;
          if isSome(sections.ann) then
            SOME(ann) := sections.ann;
            mod := ann.modification;
            modLib := SCodeUtil.filterSubMods(mod, function SCodeUtil.filterGivenSubModNames(namesToKeep={"Library"}));
            modInc := SCodeUtil.filterSubMods(mod, function SCodeUtil.filterGivenSubModNames(namesToKeep={"Include"}));
            if SCodeUtil.isEmptyMod(modLib) then
              modLibDir := SCode.NOMOD();
            else
              modLibDir := SCodeUtil.filterSubMods(mod, function SCodeUtil.filterGivenSubModNames(namesToKeep={"LibraryDirectory"}));
              if SCodeUtil.isEmptyMod(modLibDir) then
                modLibDir := SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {SCode.NAMEMOD("LibraryDirectory", SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {}, SOME(Absyn.STRING("modelica://" + AbsynUtil.pathFirstIdent(scopeName) + "/Resources/Library")), Error.dummyInfo))}, NONE(), Error.dummyInfo);
              end if;
            end if;
            if SCodeUtil.isEmptyMod(modInc) then
              modIncDir := SCode.NOMOD();
            else
              modIncDir := SCodeUtil.filterSubMods(mod, function SCodeUtil.filterGivenSubModNames(namesToKeep={"IncludeDirectory"}));
              if SCodeUtil.isEmptyMod(modLibDir) then
                modLibDir := SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {SCode.NAMEMOD("IncludeDirectory", SCode.MOD(SCode.NOT_FINAL(), SCode.NOT_EACH(), {}, SOME(Absyn.STRING("modelica://" + AbsynUtil.pathFirstIdent(scopeName) + "/Resources/Include")), Error.dummyInfo))}, NONE(), Error.dummyInfo);
              end if;
            end if;
            ann.modification := SCodeUtil.mergeSCodeMods(SCodeUtil.mergeSCodeMods(modLib, modLibDir), SCodeUtil.mergeSCodeMods(modInc, modIncDir));
            s := IOStream.append(s, SCodeDump.printAnnotationStr(SCode.COMMENT(SOME(ann), NONE())));
          end if;
          s := IOStream.append(s, ";\n");
        then ();
      else ();
    end match;
  end toFlatStream;

annotation(__OpenModelica_Interface="frontend");
end NFSections;
