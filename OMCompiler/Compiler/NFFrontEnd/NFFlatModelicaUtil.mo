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

encapsulated package NFFlatModelicaUtil
  import Absyn;
  import AbsynUtil;
  import DAE;
  import DAEDump;
  import Dump;
  import ElementSource;
  import IOStream;
  import SCode;
  import SCodeUtil;
  import System;
  import Util;

  // Used to indicate what type of element an annotation comes from, to allow
  // filtering out specific annotations for dumping.
  type ElementType = enumeration(
    ROOT_CLASS,
    CLASS,
    FUNCTION,
    COMPONENT,
    EQUATION,
    ALGORITHM,
    OTHER
  );

  function appendElementSourceCommentString
    input DAE.ElementSource source;
    input output IOStream.IOStream s;
  algorithm
    s := appendCommentString(ElementSource.getOptComment(source), s);
  end appendElementSourceCommentString;

  function appendElementSourceCommentAnnotation
    input DAE.ElementSource source;
    input ElementType elementType;
    input String indent;
    input String ending;
    input output IOStream.IOStream s;
  algorithm
    s := appendCommentAnnotation(ElementSource.getOptComment(source), elementType, indent, ending, s);
  end appendElementSourceCommentAnnotation;

  function appendElementSourceComment
    input DAE.ElementSource source;
    input ElementType elementType;
    input output IOStream.IOStream s;
  algorithm
    s := appendComment(ElementSource.getOptComment(source), elementType, s);
  end appendElementSourceComment;

  function appendComment
    input Option<SCode.Comment> comment;
    input ElementType elementType;
    input output IOStream.IOStream s;
  algorithm
    s := appendCommentString(comment, s);
    s := appendCommentAnnotation(comment, elementType, " ", "", s);
  end appendComment;

  function appendCommentString
    input Option<SCode.Comment> comment;
    input output IOStream.IOStream s;
  protected
    String str;
  algorithm
    () := match comment
      case SOME(SCode.Comment.COMMENT(comment = SOME(str)))
        algorithm
          s := IOStream.append(s, " \"");
          s := IOStream.append(s, System.escapedString(str, false));
          s := IOStream.append(s, "\"");
        then
          ();

      else ();
    end match;
  end appendCommentString;

  function appendCommentAnnotation
    input Option<SCode.Comment> comment;
    input ElementType elementType;
    input String indent;
    input String ending;
    input output IOStream.IOStream s;
  protected
    SCode.Mod mod;
  algorithm
    () := match comment
      case SOME(SCode.Comment.COMMENT(annotation_ =
          SOME(SCode.Annotation.ANNOTATION(modification = mod))))
        algorithm
          mod := match elementType
            case ElementType.ROOT_CLASS then filterRootClassAnnotations(mod);
            else DAEDump.filterStructuralMods(mod);
          end match;

          if not SCodeUtil.isEmptyMod(mod) then
            s := IOStream.append(s, indent);
            s := IOStream.append(s, "annotation");
            s := appendAnnotationMod(mod, s);
            s := IOStream.append(s, ending);
          end if;
        then
          ();

      else ();
    end match;
  end appendCommentAnnotation;

  function filterRootClassAnnotations
    input output SCode.Mod mod;
  protected
    function filter
      input SCode.SubMod smod;
      output Boolean keep;
    algorithm
      keep := match smod.ident
        case "experiment" then true;
        else false;
      end match;
    end filter;
  algorithm
    mod := SCodeUtil.filterSubMods(mod, filter);
  end filterRootClassAnnotations;

  function appendAnnotationMod
    input SCode.Mod mod;
    input output IOStream.IOStream s;
  algorithm
    () := match mod
      case SCode.Mod.MOD()
        algorithm
          if not listEmpty(mod.subModLst) then
            s := IOStream.append(s, "(");
            s := appendAnnotationSubMod(listHead(mod.subModLst), s);

            for m in listRest(mod.subModLst) loop
              s := IOStream.append(s, ", ");
              s := appendAnnotationSubMod(m, s);
            end for;

            s := IOStream.append(s, ")");
          end if;

          if isSome(mod.binding) then
            s := IOStream.append(s, " = ");
            s := appendExp(Util.getOption(mod.binding), s);
          end if;
        then
          ();

      else ();
    end match;
  end appendAnnotationMod;

  function appendAnnotationSubMod
    input SCode.SubMod mod;
    input output IOStream.IOStream s;
  protected
    SCode.Mod m = mod.mod;
  algorithm
    () := match m
      case SCode.Mod.MOD()
        algorithm
          if SCodeUtil.finalBool(m.finalPrefix) then
            s := IOStream.append(s, "final ");
          end if;

          if SCodeUtil.eachBool(m.eachPrefix) then
            s := IOStream.append(s, "each ");
          end if;

          s := IOStream.append(s, mod.ident);
          s := appendAnnotationMod(m, s);
        then
          ();

      else ();
    end match;
  end appendAnnotationSubMod;

  function appendExp
    input Absyn.Exp exp;
    input output IOStream.IOStream s;
  protected
    Absyn.Exp e;
  algorithm
    (e, _) := AbsynUtil.traverseExp(exp, quoteCref, 0);
    s := IOStream.append(s, Dump.printExpStr(e));
  end appendExp;

  function quoteCref
    input output Absyn.Exp exp;
    input output Integer dummy;
  protected
    String str;
  algorithm
    () := match exp
      case Absyn.Exp.CREF()
        guard not AbsynUtil.crefIsWild(exp.componentRef)
        algorithm
          str := Dump.printComponentRefStr(exp.componentRef);

          if str <> "time" then
            str := Util.makeQuotedIdentifier(str);
            exp.componentRef := Absyn.ComponentRef.CREF_IDENT(str, {});
          end if;
        then
          ();

      else ();
    end match;
  end quoteCref;

annotation(__OpenModelica_Interface="frontend");
end NFFlatModelicaUtil;
