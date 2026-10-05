/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFDefUseChains
  "Serializes the def-use chains found by NFUsedElements.collectUses as JSON,
   see getDefUseChains.

   The names in the abstract syntax don't have a source position, only the
   element, equation or statement they're used in has. The position of a name
   is found by reading the source file and finding the name among the
   identifiers in the span of what it's used in. Each identifier is only given
   to one use, the uses in the smallest spans first, and the names in a span in
   the order they're looked up. Names written the same way in the same span
   refer to the same definition, so the order they're given out doesn't matter.
   The declared names are taken first, so a use can't be given the name of a
   declaration. A use whose name isn't found keeps the span it's used in and
   is marked as not exact."

  import Absyn;
  import NFUsedElements;
  import NFUsedElements.Definition;
  import NFUsedElements.Site;
  import NFUsedElements.Use;

protected
  import AbsynUtil;
  import JSON;
  import List;
  import System;
  import UnorderedMap;
  import UnorderedSet;
  import Util;

  constant Integer IDENT = 1;
  constant Integer DOT = 2;
  constant Integer LBRACKET = 3;
  constant Integer RBRACKET = 4;
  constant Integer LBRACE = 5 "Only the one of a group import, A.{b, c}.";
  constant Integer RBRACE = 6;

  uniontype Token
    record TOKEN
      Integer kind;
      String text;
      Integer line;
      Integer column "The column of the first character, starting at 1.";
      Integer endColumn "The column of the last character.";
    end TOKEN;
  end Token;

  uniontype SourceFile
    record SOURCE_FILE
      array<Token> tokens;
      array<Boolean> taken;
    end SOURCE_FILE;
  end SourceFile;

  uniontype Position
    record POSITION
      String fileName;
      Integer lineStart;
      Integer columnStart;
      Integer lineEnd;
      Integer columnEnd;
      Boolean exact;
    end POSITION;
  end Position;

  type OptSourceFile = Option<SourceFile>;
  type Files = UnorderedMap<String, OptSourceFile>;
  type Placed = tuple<Use, Position>;
  type PlacedList = list<Placed>;
  type OptLines = Option<array<String>>;
  type InfoList = list<SourceInfo>;
  type StringSet = UnorderedSet<String>;

  // The moduli of the hashes of the source of a class, primes small enough that
  // h * 263 + 255 stays below 2^30, so the hashes are the same on 32-bit targets
  // (wasm) as on 64-bit ones.
  constant Integer HASH_MOD1 = 4082651;
  constant Integer HASH_MOD2 = 4082629;

public
  function toJSON
    "Returns the def-use chains of the names used in or declared in a class,
     or of a single definition, as JSON."
    input String className "The class, or the full name of a component.";
    input list<Definition> definitions;
    input list<Use> uses;
    input list<Use> unresolved;
    input String scope "The class the uses are reported in, all if empty.";
    input Boolean prettyPrint;
    output String json;
  protected
    UnorderedMap<String, Definition> defs;
    UnorderedMap<String, list<tuple<Use, Position>>> def_uses;
    UnorderedMap<String, Position> names;
    list<Definition> reported = {};
    list<Use> reported_uses;
    list<tuple<Use, Position>> placed;
    Files files;
    UnorderedSet<String> resolved;
    Boolean single;
    Definition def;
    JSON jdefs, jdef, juses, obj;
    list<JSON> jlist;
    Use u;
    Position pos;
  algorithm
    defs := UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    for d in definitions loop
      UnorderedMap.add(d.key, d, defs);
    end for;

    // A component name gives only its own chain.
    single := false;
    for d in definitions loop
      if d.name == className and d.kind <> "class" then
        reported := {d};
        single := true;
        break;
      end if;
    end for;

    if not single then
      reported := list(d for d guard d.declared and isInClass(d.name, className) in definitions);
      for u in uses loop
        if isInClass(u.site.scope, className) then
          def := UnorderedMap.getOrFail(u.key, defs);
          if not (def.declared and isInClass(def.name, className)) then
            reported := def :: reported;
          end if;
        end if;
      end for;
      reported := uniqueDefinitions(reported);
    end if;

    reported := List.sort(reported, definitionGt);
    def_uses := UnorderedMap.new<PlacedList>(stringHashDjb2, stringEq);
    for d in reported loop
      UnorderedMap.add(d.key, {}, def_uses);
    end for;
    // The class itself is walked also when it isn't in the scope.
    reported_uses := list(u for u guard UnorderedMap.contains(u.key, def_uses) and
      (stringEmpty(scope) or isInClass(u.site.scope, scope) or isInClass(u.site.scope, className)) in uses);

    // Place the declared names first, then the uses, the ones in the smallest spans first.
    files := UnorderedMap.new<OptSourceFile>(stringHashDjb2, stringEq);
    names := UnorderedMap.new<Position>(stringHashDjb2, stringEq);
    for d in definitions loop
      if UnorderedMap.contains(d.info.fileName, files) or UnorderedMap.contains(d.key, def_uses) or
         List.any(reported_uses, function useInFile(fileName = d.info.fileName)) then
        UnorderedMap.add(d.key, placeDefinition(d, files), names);
      end if;
    end for;

    placed := placeUses(reported_uses, defs, files);
    for p in placed loop
      (u, _) := p;
      UnorderedMap.add(u.key, p :: UnorderedMap.getOrFail(u.key, def_uses), def_uses);
    end for;

    // The name after end refers to the class too.
    for d in reported loop
      if d.kind == "class" then
        pos := placeEnd(d, files);
        if pos.exact then
          u := NFUsedElements.USE(d.key, Absyn.IDENT(lastIdent(d.name)), 1,
            NFUsedElements.SITE(d.info, "end", d.name), false);
          UnorderedMap.add(d.key, (u, pos) :: UnorderedMap.getOrFail(d.key, def_uses), def_uses);
        end if;
      end if;
    end for;

    jlist := {};
    for d in reported loop
      jdef := definitionJSON(d, UnorderedMap.getOrDefault(d.key, names, POSITION("", 0, 0, 0, 0, false)));
      juses := JSON.makeArray(list(useJSON(p) for p in List.sort(UnorderedMap.getOrFail(d.key, def_uses), placedGt)));
      jdef := JSON.addPair("uses", juses, jdef);
      jlist := jdef :: jlist;
    end for;

    obj := JSON.emptyListObject();
    obj := JSON.addPair("class", JSON.makeString(className), obj);
    obj := JSON.addPair("definitions", JSON.makeArray(listReverse(jlist)), obj);
    // A name that is only found in the classes a replaceable class is redeclared as isn't unresolved.
    resolved := UnorderedSet.new<String>(stringHashDjb2, stringEq);
    for u in uses loop
      if u.candidate then
        UnorderedSet.add(siteSignature(u), resolved);
      end if;
    end for;
    obj := JSON.addPair("unresolved", JSON.makeArray(list(useJSON(p) for p in
      placeUses(list(u for u guard isInClass(u.site.scope, className) and
        not UnorderedSet.contains(siteSignature(u), resolved) in unresolved), defs, files))), obj);
    json := JSON.toString(obj, prettyPrint);
  end toJSON;

  function dependencyGraphJSON
    "Returns the classes that were walked or used, the hashes of their source and
     the classes they use, as JSON."
    input String scope;
    input list<Definition> definitions;
    input list<Use> uses;
    input Boolean prettyPrint;
    output String json;
  protected
    UnorderedMap<String, Definition> defs = UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    UnorderedMap<String, Definition> classes = UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    UnorderedMap<String, StringSet> deps = UnorderedMap.new<StringSet>(stringHashDjb2, stringEq);
    UnorderedMap<String, InfoList> nested = UnorderedMap.new<InfoList>(stringHashDjb2, stringEq);
    UnorderedMap<String, OptLines> texts = UnorderedMap.new<OptLines>(stringHashDjb2, stringEq);
    Definition def;
    String to, parent;
    StringSet used;
    JSON jclasses = JSON.emptyListObject(), jcls, obj;
  algorithm
    for d in definitions loop
      UnorderedMap.add(d.key, d, defs);

      // A class is identified by its name, the one declared in the walked classes is kept.
      if d.kind == "class" and (d.declared or not UnorderedMap.contains(d.name, classes)) then
        UnorderedMap.add(d.name, d, classes);
      end if;
    end for;

    // The classes declared in a class in the same file, which aren't part of its source.
    for d in UnorderedMap.valueList(classes) loop
      parent := ownerName(d.name);

      if UnorderedMap.contains(parent, classes) then
        def := UnorderedMap.getOrFail(parent, classes);

        if def.info.fileName == d.info.fileName then
          UnorderedMap.add(parent, d.info :: UnorderedMap.getOrDefault(parent, nested, {}), nested);
        end if;
      end if;
    end for;

    for u in uses loop
      if not stringEmpty(u.key) then
        def := UnorderedMap.getOrFail(u.key, defs);

        // A class a name is only looked up through, e.g. P in P.f, isn't used by it.
        if def.kind == "iterator" or (def.kind == "class" and u.index < listLength(
            AbsynUtil.pathToStringList(AbsynUtil.makeNotFullyQualified(u.written)))) then
          continue;
        end if;

        // A component, constant or enumeration literal is part of the class it's declared in.
        to := if def.kind == "class" then def.name else ownerName(def.name);

        if not stringEmpty(to) and to <> u.site.scope then
          used := UnorderedMap.addUpdate(u.site.scope, newStringSet, deps);
          UnorderedSet.add(to, used);
        end if;
      end if;
    end for;

    for d in List.sort(UnorderedMap.valueList(classes), definitionGt) loop
      jcls := JSON.emptyListObject();
      jcls := JSON.addPair("restriction", JSON.makeString(d.detail), jcls);
      jcls := addInfo(d.info, jcls);
      jcls := JSON.addPair("hash", JSON.makeString(sourceHash(d.info,
        List.sort(UnorderedMap.getOrDefault(d.name, nested, {}), infoGt), texts)), jcls);
      // Only the classes that are in the graph, not builtin ones like StateSelect.
      jcls := JSON.addPair("uses", JSON.makeArray(list(JSON.makeString(n) for n guard UnorderedMap.contains(n, classes) in
        List.sort(UnorderedSet.toList(UnorderedMap.getOrDefault(d.name, deps, newStringSet())), stringGt))), jcls);
      jclasses := JSON.addPair(d.name, jcls, jclasses);
    end for;

    obj := JSON.emptyListObject();
    obj := JSON.addPair("scope", JSON.makeString(scope), obj);
    obj := JSON.addPair("classes", jclasses, obj);
    json := JSON.toString(obj, prettyPrint);
  end dependencyGraphJSON;

  function definitionAtJSON
    "Returns the definition of the name at a position in a file as JSON: the
     definition, and the use if the name at the position isn't the declared name."
    input String fileName;
    input Integer line;
    input Integer column;
    input list<Definition> definitions;
    input list<Use> uses;
    input Boolean prettyPrint;
    output String json;
  protected
    UnorderedMap<String, Definition> defs = UnorderedMap.new<Definition>(stringHashDjb2, stringEq);
    Files files = UnorderedMap.new<OptSourceFile>(stringHashDjb2, stringEq);
    Option<Definition> found = NONE();
    Option<Placed> found_use = NONE();
    UnorderedMap<String, Position> names = UnorderedMap.new<Position>(stringHashDjb2, stringEq);
    list<Definition> candidates = {};
    Position pos;
    Use u;
    Definition def;
    JSON obj, jdef;
  algorithm
    for d in definitions loop
      UnorderedMap.add(d.key, d, defs);
    end for;

    // The declared names are placed first, like in toJSON, then the uses.
    for d in definitions loop
      if d.info.fileName == fileName and isInSpan(d.info, line, column) then
        pos := placeDefinition(d, files);
        UnorderedMap.add(d.key, pos, names);

        if isAt(pos, fileName, line, column) then
          found := SOME(d);
        elseif d.kind == "class" then
          pos := placeEnd(d, files);
          if isAt(pos, fileName, line, column) then
            found := SOME(d);
          end if;
        end if;
      end if;
    end for;

    if isNone(found) then
      for p in placeUses(list(u for u guard u.site.info.fileName == fileName and
          isInSpan(u.site.info, line, column) in uses), defs, files) loop
        (u, pos) := p;

        if isAt(pos, fileName, line, column) then
          def := UnorderedMap.getOrFail(u.key, defs);

          if u.candidate then
            candidates := def :: candidates;

            // The use of a name only found in redeclared classes.
            if isNone(found_use) then
              found_use := SOME(p);
            end if;
          elseif isNone(found) then
            found := SOME(def);
            found_use := SOME(p);
          end if;
        end if;
      end for;
    end if;

    obj := JSON.emptyListObject();
    obj := JSON.addPair("file", JSON.makeString(fileName), obj);
    obj := JSON.addPair("line", JSON.makeInteger(line), obj);
    obj := JSON.addPair("column", JSON.makeInteger(column), obj);

    obj := JSON.addPair("definition", match found
      case SOME(def) then definitionJSON(def, namePosition(def, names, files));
      else JSON.makeNull();
    end match, obj);

    obj := JSON.addPair("use", match found_use
      local
        Placed placed;
      case SOME(placed) then useJSON(placed);
      else JSON.makeNull();
    end match, obj);

    obj := JSON.addPair("candidates", JSON.makeArray(list(definitionJSON(c,
      namePosition(c, names, files)) for c in listReverse(candidates))), obj);
    json := JSON.toString(obj, prettyPrint);
  end definitionAtJSON;

protected
  function definitionJSON
    input Definition d;
    input Position name "The position of the declared name.";
    output JSON jdef = JSON.emptyListObject();
  algorithm
    jdef := JSON.addPair("name", JSON.makeString(d.name), jdef);
    jdef := JSON.addPair("kind", JSON.makeString(d.kind), jdef);
    if not stringEmpty(d.detail) then
      jdef := JSON.addPair(if d.kind == "class" then "restriction" else "type", JSON.makeString(d.detail), jdef);
    end if;
    jdef := addInfo(d.info, jdef);
    if name.exact then
      jdef := JSON.addPair("nameLine", JSON.makeInteger(name.lineStart), jdef);
      jdef := JSON.addPair("nameColumnStart", JSON.makeInteger(name.columnStart), jdef);
      jdef := JSON.addPair("nameColumnEnd", JSON.makeInteger(name.columnEnd), jdef);
    end if;
  end definitionJSON;

  function namePosition
    "Returns the position of the declared name of a definition, placing it if it wasn't."
    input Definition d;
    input UnorderedMap<String, Position> names;
    input Files files;
    output Position pos;
  algorithm
    if UnorderedMap.contains(d.key, names) then
      pos := UnorderedMap.getOrFail(d.key, names);
    else
      pos := placeDefinition(d, files);
      UnorderedMap.add(d.key, pos, names);
    end if;
  end namePosition;

  function isInSpan
    input SourceInfo info;
    input Integer line;
    input Integer column;
    output Boolean res = (line > info.lineNumberStart or (line == info.lineNumberStart and column >= info.columnNumberStart)) and
                         (line < info.lineNumberEnd or (line == info.lineNumberEnd and column <= info.columnNumberEnd));
  end isInSpan;

  function isAt
    "Returns true if the exact position of a name covers the given position."
    input Position pos;
    input String fileName;
    input Integer line;
    input Integer column;
    output Boolean res = pos.exact and pos.fileName == fileName and pos.lineStart == line and
      column >= pos.columnStart and column <= pos.columnEnd;
  end isAt;

  function newStringSet
    input Option<StringSet> old = NONE();
    output StringSet set;
  algorithm
    set := match old
      case SOME(set) then set;
      else UnorderedSet.new<String>(stringHashDjb2, stringEq);
    end match;
  end newStringSet;

  function stringGt
    input String s1;
    input String s2;
    output Boolean res = stringCompare(s1, s2) > 0;
  end stringGt;

  function infoGt
    input SourceInfo i1;
    input SourceInfo i2;
    output Boolean res = i1.lineNumberStart > i2.lineNumberStart or
      (i1.lineNumberStart == i2.lineNumberStart and i1.columnNumberStart > i2.columnNumberStart);
  end infoGt;

  function ownerName
    "Returns the name of the class something is declared in, P.A for P.A.x."
    input String name;
    output String owner = "";
  algorithm
    for i in stringLength(name):-1:1 loop
      if stringGet(name, i) == 46 then
        owner := substring(name, 1, i - 1);
        return;
      end if;
    end for;
  end ownerName;

  function sourceHash
    "Hashes the source of a class without the classes declared in it, its
     comments and its whitespace, so it only changes when the class itself does."
    input SourceInfo info;
    input list<SourceInfo> nested "Sorted by position.";
    input UnorderedMap<String, OptLines> texts;
    output String hash = "";
  protected
    array<String> lines;
    Integer line, col, len = 0, h1 = 0, h2 = 0, i, n, c, last = 0;
    Boolean in_string = false, in_line_comment = false, in_block_comment = false,
      space = false;
    list<String> pieces = {};
    String p;
  algorithm
    if not UnorderedMap.contains(info.fileName, texts) then
      UnorderedMap.add(info.fileName, readLines(info.fileName), texts);
    end if;

    () := match UnorderedMap.getOrFail(info.fileName, texts)
      case SOME(lines) then ();
      else algorithm return; then ();
    end match;

    // The pieces of the source between the nested classes.
    line := info.lineNumberStart;
    col := info.columnNumberStart;
    for n in nested loop
      pieces := textRange(lines, line, col, n.lineNumberStart, n.columnNumberStart - 1) :: pieces;
      line := n.lineNumberEnd;
      col := n.columnNumberEnd + 1;
    end for;
    pieces := listReverse(textRange(lines, line, col, info.lineNumberEnd, info.columnNumberEnd) :: pieces);

    // Hash the source without comments and whitespace, except for a space between
    // two identifiers or numbers.
    for p in pieces loop
      n := stringLength(p);
      i := 1;

      while i <= n loop
        c := stringGet(p, i);

        if in_line_comment then
          if c == 10 then
            in_line_comment := false;
            space := true;
          end if;
          i := i + 1;
        elseif in_block_comment then
          if c == 42 and i < n and stringGet(p, i + 1) == 47 then
            in_block_comment := false;
            space := true;
            i := i + 2;
          else
            i := i + 1;
          end if;
        elseif in_string then
          (h1, h2, len) := hashChar(c, h1, h2, len);

          if c == 92 and i < n then // \
            (h1, h2, len) := hashChar(stringGet(p, i + 1), h1, h2, len);
            i := i + 1;
          elseif c == 34 then
            in_string := false;
          end if;
          i := i + 1;
        elseif c == 47 and i < n and stringGet(p, i + 1) == 47 then
          in_line_comment := true;
          i := i + 2;
        elseif c == 47 and i < n and stringGet(p, i + 1) == 42 then
          in_block_comment := true;
          i := i + 2;
        elseif c == 32 or c == 9 or c == 10 or c == 13 then
          space := true;
          i := i + 1;
        else
          if space and isIdentChar(last) and isIdentChar(c) then
            (h1, h2, len) := hashChar(32, h1, h2, len);
          end if;

          space := false;
          (h1, h2, len) := hashChar(c, h1, h2, len);
          last := c;
          in_string := c == 34;
          i := i + 1;
        end if;
      end while;
    end for;

    hash := intString(len) + "-" + intString(h1) + "-" + intString(h2);
  end sourceHash;

  function hashChar
    input Integer c;
    input output Integer h1;
    input output Integer h2;
    input output Integer len;
  algorithm
    h1 := mod(h1 * 257 + c, HASH_MOD1);
    h2 := mod(h2 * 263 + c, HASH_MOD2);
    len := len + 1;
  end hashChar;

  function readLines
    input String fileName;
    output Option<array<String>> lines = NONE();
  algorithm
    try
      if System.regularFileExists(fileName) then
        lines := SOME(listArray(Util.stringSplitAtChar(System.readFile(fileName), "\n")));
      end if;
    else
    end try;
  end readLines;

  function textRange
    "Returns the source from one position to another, both included."
    input array<String> lines;
    input Integer lineStart;
    input Integer colStart;
    input Integer lineEnd;
    input Integer colEnd;
    output String text;
  protected
    list<String> parts = {};
  algorithm
    if lineStart > lineEnd or lineStart < 1 or lineEnd > arrayLength(lines) then
      text := "";
      return;
    end if;

    if lineStart == lineEnd then
      text := lineRange(arrayGet(lines, lineStart), colStart, colEnd);
      return;
    end if;

    parts := {lineRange(arrayGet(lines, lineStart), colStart, stringLength(arrayGet(lines, lineStart)))};
    for l in lineStart + 1:lineEnd - 1 loop
      parts := arrayGet(lines, l) :: parts;
    end for;
    parts := lineRange(arrayGet(lines, lineEnd), 1, colEnd) :: parts;
    text := stringDelimitList(listReverse(parts), "\n");
  end textRange;

  function lineRange
    input String line;
    input Integer colStart;
    input Integer colEnd;
    output String text;
  protected
    Integer stop = min(colEnd, stringLength(line));
  algorithm
    text := if colStart < 1 or colStart > stop then "" else substring(line, colStart, stop);
  end lineRange;

  function isInClass
    "Returns true if the name is the class or declared in it."
    input String name;
    input String className;
    output Boolean res;
  protected
    Integer len = stringLength(className);
  algorithm
    res := name == className or
      (stringLength(name) > len and substring(name, 1, len + 1) == className + ".");
  end isInClass;

  function lastIdent
    input String name;
    output String id = List.last(Util.stringSplitAtChar(name, "."));
  end lastIdent;

  function uniqueDefinitions
    input list<Definition> defs;
    output list<Definition> unique = {};
  protected
    UnorderedSet<String> keys = UnorderedSet.new<String>(stringHashDjb2, stringEq);
  algorithm
    for d in defs loop
      if not UnorderedSet.contains(d.key, keys) then
        UnorderedSet.add(d.key, keys);
        unique := d :: unique;
      end if;
    end for;
  end uniqueDefinitions;

  function definitionGt
    input Definition d1;
    input Definition d2;
    output Boolean res;
  protected
    Integer c = stringCompare(d1.name, d2.name);
  algorithm
    res := c > 0 or (c == 0 and stringCompare(d1.key, d2.key) > 0);
  end definitionGt;

  function useInFile
    input Use u;
    input String fileName;
    output Boolean res = u.site.info.fileName == fileName;
  end useInFile;

  function placedGt
    input tuple<Use, Position> p1;
    input tuple<Use, Position> p2;
    output Boolean res;
  protected
    Position a, b;
    Integer c;
  algorithm
    (_, a) := p1;
    (_, b) := p2;
    c := stringCompare(a.fileName, b.fileName);
    res := c > 0 or (c == 0 and (a.lineStart > b.lineStart or
      (a.lineStart == b.lineStart and a.columnStart > b.columnStart)));
  end placedGt;

  function addInfo
    input SourceInfo info;
    input output JSON obj;
  algorithm
    obj := JSON.addPair("file", JSON.makeString(info.fileName), obj);
    obj := JSON.addPair("lineStart", JSON.makeInteger(info.lineNumberStart), obj);
    obj := JSON.addPair("columnStart", JSON.makeInteger(info.columnNumberStart), obj);
    obj := JSON.addPair("lineEnd", JSON.makeInteger(info.lineNumberEnd), obj);
    obj := JSON.addPair("columnEnd", JSON.makeInteger(info.columnNumberEnd), obj);
  end addInfo;

  function useJSON
    input tuple<Use, Position> placed;
    output JSON obj = JSON.emptyListObject();
  protected
    Use u;
    Position p;
  algorithm
    (u, p) := placed;
    obj := JSON.addPair("file", JSON.makeString(p.fileName), obj);
    obj := JSON.addPair("lineStart", JSON.makeInteger(p.lineStart), obj);
    obj := JSON.addPair("columnStart", JSON.makeInteger(p.columnStart), obj);
    obj := JSON.addPair("lineEnd", JSON.makeInteger(p.lineEnd), obj);
    obj := JSON.addPair("columnEnd", JSON.makeInteger(p.columnEnd), obj);
    obj := JSON.addPair("exact", JSON.makeBoolean(p.exact), obj);
    obj := JSON.addPair("text", JSON.makeString(writtenString(u.written)), obj);
    if not p.exact or AbsynUtil.pathIsQual(AbsynUtil.makeNotFullyQualified(u.written)) then
      obj := JSON.addPair("part", JSON.makeInteger(u.index), obj);
    end if;
    obj := JSON.addPair("in", JSON.makeString(u.site.scope), obj);
    obj := JSON.addPair("role", JSON.makeString(u.site.role), obj);
    if u.candidate then
      obj := JSON.addPair("candidate", JSON.makeBoolean(true), obj);
    end if;
  end useJSON;

  function writtenString
    input Absyn.Path path;
    output String str = (if AbsynUtil.pathIsFullyQualified(path) then "." else "") +
      AbsynUtil.pathString(AbsynUtil.makeNotFullyQualified(path));
  end writtenString;

  function placeUses
    "Finds the positions of the uses, the ones in the smallest spans first. A
     candidate is at the positions of the uses it was found through."
    input list<Use> uses;
    input UnorderedMap<String, Definition> defs;
    input Files files;
    output list<tuple<Use, Position>> placed = {};
  protected
    list<tuple<Integer, Integer, Use>> order = {};
    list<Use> candidates = {};
    Integer i = 0;
    Use u;
    Position pos;
    String sig;
    UnorderedSet<String> found = UnorderedSet.new<String>(stringHashDjb2, stringEq);
    UnorderedMap<String, PlacedList> primaries =
      UnorderedMap.new<PlacedList>(stringHashDjb2, stringEq);
    Use pu, cu;
    Position pp;
    Site site;
  algorithm
    for u in uses loop
      i := i + 1;

      if u.candidate then
        candidates := u :: candidates;
      else
        order := (spanSize(u.site.info), i, u) :: order;
      end if;
    end for;

    // A name can be looked up more than once, e.g. the type of each component
    // in Res r1, r2. A use that isn't found again is dropped if an identical
    // one was.
    order := List.sort(order, orderGt);
    for o in order loop
      (_, _, u) := o;
      pos := placeUse(u, files);
      sig := useSignature(u);

      // A prefix shared by several names, e.g. A in import A.{b, c}, is a single use.
      if pos.exact and UnorderedSet.contains(positionSignature(u.key, pos), found) then
        continue;
      end if;

      if pos.exact then
        UnorderedSet.add(sig, found);
        UnorderedSet.add(positionSignature(u.key, pos), found);
        UnorderedMap.add(siteSignature(u),
          (u, pos) :: UnorderedMap.getOrDefault(siteSignature(u), primaries, {}), primaries);
        placed := (u, pos) :: placed;
      elseif not UnorderedSet.contains(sig, found) then
        placed := (u, pos) :: placed;
      end if;
    end for;

    // A candidate that is what the name refers to anyway, e.g. an inherited
    // element, is left out.
    for u in listReverse(candidates) loop
      // The name wasn't found without the redeclares, the first candidate finds its position.
      if not UnorderedMap.contains(siteSignature(u), primaries) then
        pos := placeUse(u, files);
        UnorderedMap.add(siteSignature(u), {(u, pos)}, primaries);
      end if;

      for p in UnorderedMap.getOrFail(siteSignature(u), primaries) loop
        (pu, pp) := p;
        sig := positionSignature(u.key, pp);

        if not (pu.key == u.key and not pu.candidate) and not UnorderedSet.contains(sig, found) then
          UnorderedSet.add(sig, found);
          cu := u;
          site := cu.site;
          site.role := pu.site.role;
          cu.site := site;
          placed := (cu, pp) :: placed;
        end if;
      end for;
    end for;
  end placeUses;

  function positionSignature
    input String key;
    input Position p;
    output String sig = stringAppendList({key, "|", p.fileName, ":", intString(p.lineStart),
      ":", intString(p.columnStart), "-", intString(p.lineEnd), ":", intString(p.columnEnd)});
  end positionSignature;

  function siteSignature
    "Identifies where a name is used, but not what it refers to."
    input Use u;
    output String sig = stringAppendList({writtenString(u.written), "|",
      intString(u.index), "|", u.site.info.fileName, ":",
      intString(u.site.info.lineNumberStart), ":", intString(u.site.info.columnNumberStart), "-",
      intString(u.site.info.lineNumberEnd), ":", intString(u.site.info.columnNumberEnd)});
  end siteSignature;

  function useSignature
    input Use u;
    output String sig = stringAppendList({u.key, "|", writtenString(u.written), "|",
      intString(u.index), "|", u.site.role, "|", u.site.info.fileName, ":",
      intString(u.site.info.lineNumberStart), ":", intString(u.site.info.columnNumberStart), "-",
      intString(u.site.info.lineNumberEnd), ":", intString(u.site.info.columnNumberEnd)});
  end useSignature;

  function orderGt
    input tuple<Integer, Integer, Use> o1;
    input tuple<Integer, Integer, Use> o2;
    output Boolean res;
  protected
    Integer s1, s2, i1, i2;
  algorithm
    (s1, i1, _) := o1;
    (s2, i2, _) := o2;
    res := s1 > s2 or (s1 == s2 and i1 > i2);
  end orderGt;

  function spanSize
    input SourceInfo info;
    output Integer size = (info.lineNumberEnd - info.lineNumberStart) * 1000000 +
      info.columnNumberEnd - info.columnNumberStart + 1000;
  end spanSize;

  function spanPosition
    input SourceInfo info;
    output Position pos = POSITION(info.fileName, info.lineNumberStart,
      info.columnNumberStart, info.lineNumberEnd, info.columnNumberEnd, false);
  end spanPosition;

  function tokenPosition
    input String fileName;
    input Token t;
    output Position pos = POSITION(fileName, t.line, t.column, t.line, t.endColumn, true);
  end tokenPosition;

  function placeUse
    input Use u;
    input Files files;
    output Position pos = spanPosition(u.site.info);
  protected
    SourceFile file;
    Integer first, last, i;
    list<String> parts;
  algorithm
    try
      SOME(file) := getFile(u.site.info.fileName, files);
      (first, last) := tokenRange(file, u.site.info);

      // What a class extends or a redeclare replaces is referred to by the name it declares.
      if u.site.role == "classExtends" or u.site.role == "redeclare" then
        i := findName(file, first, last, AbsynUtil.pathFirstIdent(u.written), ignoreTaken = true);
    else
      parts := AbsynUtil.pathToStringList(u.written);
      i := findWritten(file, first, last, parts, u.index, AbsynUtil.pathIsFullyQualified(u.written));
    end if;

    if i > 0 then
      arrayUpdate(file.taken, i, true);
      pos := tokenPosition(u.site.info.fileName, arrayGet(file.tokens, i));
    end if;
    else
    end try;
  end placeUse;

  function placeDefinition
    "Finds the declared name of a definition and takes it."
    input Definition def;
    input Files files;
    output Position pos = spanPosition(def.info);
  protected
    SourceFile file;
    Integer first, last, i;
    String name = lastIdent(def.name);
  algorithm
    try
      SOME(file) := getFile(def.info.fileName, files);
      (first, last) := tokenRange(file, def.info);

      if def.kind == "iterator" then
        i := findAfter(file, first, last, "for", name);
    else
      i := findName(file, first, last, name);
    end if;

    if i > 0 then
      arrayUpdate(file.taken, i, true);
      pos := tokenPosition(def.info.fileName, arrayGet(file.tokens, i));
    end if;
    else
    end try;
  end placeDefinition;

  function placeEnd
    "Finds the name after end at the end of a class."
    input Definition def;
    input Files files;
    output Position pos = spanPosition(def.info);
  protected
    SourceFile file;
    Integer first, last;
    Token t;
  algorithm
    try
      SOME(file) := getFile(def.info.fileName, files);
      (first, last) := tokenRange(file, def.info);

      if last > first then
        t := arrayGet(file.tokens, last);
        if t.kind == IDENT and t.text == lastIdent(def.name) and
           tokenText(file, last - 1) == "end" then
          pos := tokenPosition(def.info.fileName, t);
        end if;
      end if;
    else
    end try;
  end placeEnd;

  function findName
    "Returns the index of the first identifier in the range with the given
     name that isn't part of a qualified name, or 0."
    input SourceFile file;
    input Integer first;
    input Integer last;
    input String name;
    input Boolean ignoreTaken = false;
    output Integer index = 0;
  protected
    Token t;
  algorithm
    for i in first:last loop
      t := arrayGet(file.tokens, i);
      if t.kind == IDENT and t.text == name and not isAfterDot(file, i, first) and
         (ignoreTaken or not arrayGet(file.taken, i)) then
        index := i;
        return;
      end if;
    end for;
  end findName;

  function findAfter
    "Returns the index of the first free identifier with the given name that
     follows the given keyword, or 0."
    input SourceFile file;
    input Integer first;
    input Integer last;
    input String keyword;
    input String name;
    output Integer index = 0;
  protected
    Token t;
  algorithm
    for i in first + 1:last loop
      t := arrayGet(file.tokens, i);
      if t.kind == IDENT and t.text == name and not arrayGet(file.taken, i) and
         tokenText(file, i - 1) == keyword then
        index := i;
        return;
      end if;
    end for;
  end findAfter;

  function tokenKind
    input SourceFile file;
    input Integer i;
    output Integer kind;
  protected
    Token t = arrayGet(file.tokens, i);
  algorithm
    kind := t.kind;
  end tokenKind;

  function tokenText
    input SourceFile file;
    input Integer i;
    output String text;
  protected
    Token t = arrayGet(file.tokens, i);
  algorithm
    text := t.text;
  end tokenText;

  function isAfterDot
    input SourceFile file;
    input Integer i;
    input Integer first;
    output Boolean res = i > first and tokenKind(file, i - 1) == DOT;
  end isAfterDot;

  function findWritten
    "Returns the index of the identifier that is the given part of the first
     free occurrence of a name in the range, or 0. Subscripts between the parts
     are skipped."
    input SourceFile file;
    input Integer first;
    input Integer last;
    input list<String> parts;
    input Integer part;
    input Boolean fullyQualified;
    output Integer index = 0;
  protected
    Token t;
    Integer j, k, depth, n, prefix;
    Boolean matched;
  algorithm
    for i in first:last loop
      t := arrayGet(file.tokens, i);

      if t.kind == IDENT and t.text == listHead(parts) and
         isAfterDot(file, i, first) == fullyQualified then
        j := i;
        k := i;
        matched := true;
        n := 1;
        // The parts before the braces of a group import.
        prefix := 0;

        for p in listRest(parts) loop
          // Skip the subscripts, e.g. a[i].b.
          if j < last and tokenKind(file, j + 1) == LBRACKET then
            depth := 0;
            j := j + 1;
            while j <= last loop
              t := arrayGet(file.tokens, j);
              depth := if t.kind == LBRACKET then depth + 1 elseif t.kind == RBRACKET then depth - 1 else depth;
              if depth == 0 then
                break;
              end if;
              j := j + 1;
            end while;
          end if;

          if j + 2 <= last and tokenKind(file, j + 1) == DOT and
             tokenText(file, j + 2) == p then
            j := j + 2;
          elseif j + 2 <= last and tokenKind(file, j + 1) == DOT and
                 tokenKind(file, j + 2) == LBRACE then
            // A group import, A.{b, c}.
            prefix := n;
            k := j + 3;
            matched := false;
            while k <= last and tokenKind(file, k) <> RBRACE loop
              if tokenText(file, k) == p then
                j := k;
                matched := true;
                break;
              end if;
              k := k + 1;
            end while;

            if not matched then
              break;
            end if;
          else
            matched := false;
            break;
          end if;

          n := n + 1;
        end for;

        if matched then
          // The last part is where the name ends, the names before it in a group import aren't parts of it.
          k := if part == listLength(parts) then j else partIndex(file, i, j, part);
          // The prefix of a group import is part of each of its names.
          if k > 0 and (part <= prefix or not arrayGet(file.taken, k)) then
            index := k;
            return;
          end if;
        end if;
      end if;
    end for;
  end findWritten;

  function partIndex
    "Returns the index of the n:th identifier from i to j outside subscripts."
    input SourceFile file;
    input Integer i;
    input Integer j;
    input Integer part;
    output Integer index = 0;
  protected
    Integer n = 0, depth = 0;
    Token t;
  algorithm
    for k in i:j loop
      t := arrayGet(file.tokens, k);
      if t.kind == LBRACKET then
        depth := depth + 1;
      elseif t.kind == RBRACKET then
        depth := depth - 1;
      elseif t.kind == IDENT and depth == 0 then
        n := n + 1;
        if n == part then
          index := k;
          return;
        end if;
      end if;
    end for;
  end partIndex;

  function tokenRange
    "Returns the indices of the first and last token in a span, last < first if none."
    input SourceFile file;
    input SourceInfo info;
    output Integer first;
    output Integer last;
  protected
    Integer lo = 1, hi = arrayLength(file.tokens), mid;
    Token t;
  algorithm
    // The first token that doesn't begin before the span.
    while lo <= hi loop
      mid := intDiv(lo + hi, 2);
      t := arrayGet(file.tokens, mid);
      if t.line < info.lineNumberStart or
         (t.line == info.lineNumberStart and t.column < info.columnNumberStart) then
        lo := mid + 1;
      else
        hi := mid - 1;
      end if;
    end while;

    first := lo;
    last := first - 1;
    while last < arrayLength(file.tokens) loop
      t := arrayGet(file.tokens, last + 1);
      if t.line > info.lineNumberEnd or
         (t.line == info.lineNumberEnd and t.endColumn > info.columnNumberEnd) then
        break;
      end if;
      last := last + 1;
    end while;
  end tokenRange;

  function getFile
    input String fileName;
    input Files files;
    output Option<SourceFile> file;
  algorithm
    if UnorderedMap.contains(fileName, files) then
      file := UnorderedMap.getOrFail(fileName, files);
    else
      file := readSourceFile(fileName);
      UnorderedMap.add(fileName, file, files);
    end if;
  end getFile;

  function readSourceFile
    input String fileName;
    output Option<SourceFile> file = NONE();
  protected
    array<Token> tokens;
  algorithm
    try
      if System.regularFileExists(fileName) then
        tokens := listArray(tokenize(System.readFile(fileName)));
        file := SOME(SOURCE_FILE(tokens, arrayCreate(arrayLength(tokens), false)));
      end if;
    else
    end try;
  end readSourceFile;

  function tokenize
    "Splits Modelica source into identifiers, dots and brackets, skipping
     comments, strings and everything else. Columns count bytes, like the
     parser does."
    input String source;
    output list<Token> tokens = {};
  protected
    Integer len = stringLength(source), i = 1, line = 1, col = 1, c, start, start_col;
    Boolean in_group = false;
    Token t;
  algorithm
    while i <= len loop
      c := stringGet(source, i);

      if c == 10 then // \n
        line := line + 1;
        col := 1;
        i := i + 1;
      elseif c == 47 and i < len and stringGet(source, i + 1) == 47 then // //
        while i <= len and stringGet(source, i) <> 10 loop
          i := i + 1;
          col := col + 1;
        end while;
      elseif c == 47 and i < len and stringGet(source, i + 1) == 42 then // /*
        i := i + 2;
        col := col + 2;
        while i <= len and not (stringGet(source, i) == 42 and i < len and stringGet(source, i + 1) == 47) loop
          if stringGet(source, i) == 10 then
            line := line + 1;
            col := 1;
          else
            col := col + 1;
          end if;
          i := i + 1;
        end while;
        i := i + 2;
        col := col + 2;
      elseif c == 34 or c == 39 then // " or '
        start := i;
        start_col := col;
        i := i + 1;
        col := col + 1;
        while i <= len and stringGet(source, i) <> c loop
          if stringGet(source, i) == 92 then // \
            i := i + 1;
            col := col + 1;
          end if;
          if i <= len and stringGet(source, i) == 10 then
            line := line + 1;
            col := 1;
          else
            col := col + 1;
          end if;
          i := i + 1;
        end while;

        // A quoted identifier is kept with its quotes, like the parser does.
        if c == 39 and i <= len then
          tokens := TOKEN(IDENT, substring(source, start, i), line, start_col, col) :: tokens;
        end if;
        i := i + 1;
        col := col + 1;
      elseif isIdentStart(c) then
        start := i;
        start_col := col;
        while i <= len and isIdentChar(stringGet(source, i)) loop
          i := i + 1;
          col := col + 1;
        end while;
        tokens := TOKEN(IDENT, substring(source, start, i - 1), line, start_col, col - 1) :: tokens;
      elseif isDigit(c) then
        // A number, including its fraction and exponent.
        while i <= len and isDigit(stringGet(source, i)) loop
          i := i + 1;
          col := col + 1;
        end while;
        if i <= len and stringGet(source, i) == 46 then
          i := i + 1;
          col := col + 1;
          while i <= len and isDigit(stringGet(source, i)) loop
            i := i + 1;
            col := col + 1;
          end while;
        end if;
        if i <= len and (stringGet(source, i) == 101 or stringGet(source, i) == 69) then
          i := i + 1;
          col := col + 1;
          if i <= len and (stringGet(source, i) == 43 or stringGet(source, i) == 45) then
            i := i + 1;
            col := col + 1;
          end if;
          while i <= len and isDigit(stringGet(source, i)) loop
            i := i + 1;
            col := col + 1;
          end while;
        end if;
      else
        // An element-wise operator, e.g. .* or ./, isn't a dot in a name.
        if c == 46 and not (i < len and listMember(stringGet(source, i + 1), {42, 47, 43, 45, 94})) then
          tokens := TOKEN(DOT, ".", line, col, col) :: tokens;
        elseif c == 91 then
          tokens := TOKEN(LBRACKET, "[", line, col, col) :: tokens;
        elseif c == 93 then
          tokens := TOKEN(RBRACKET, "]", line, col, col) :: tokens;
        elseif c == 123 and not listEmpty(tokens) then
          t := listHead(tokens);
          if t.kind == DOT then
            tokens := TOKEN(LBRACE, "{", line, col, col) :: tokens;
            in_group := true;
          end if;
        elseif c == 125 and in_group then
          tokens := TOKEN(RBRACE, "}", line, col, col) :: tokens;
          in_group := false;
        end if;
        i := i + 1;
        col := col + 1;
      end if;
    end while;

    tokens := listReverse(tokens);
  end tokenize;

  function isIdentStart
    input Integer c;
    output Boolean res = (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95;
  end isIdentStart;

  function isIdentChar
    input Integer c;
    output Boolean res = isIdentStart(c) or isDigit(c);
  end isIdentChar;

  function isDigit
    input Integer c;
    output Boolean res = c >= 48 and c <= 57;
  end isDigit;

  annotation(__OpenModelica_Interface="nf_frontend");
end NFDefUseChains;
