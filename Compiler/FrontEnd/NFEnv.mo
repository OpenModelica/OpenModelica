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

encapsulated package NFEnv
" file:  NFEnv.mo
  package:     NFEnv
  description: Symbol table for lookup

  RCS: $Id$

"
public import Absyn;
public import SCode;

protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import NFBuiltin;
protected import NFLookup;
protected import Util;

public constant Integer tmpTickIndex = 2;

public uniontype EntryOrigin
  record LOCAL_ORIGIN "An entry declared in the local scope." end LOCAL_ORIGIN;
  record BUILTIN_ORIGIN "An entry declared in the builtin scope." end BUILTIN_ORIGIN;

  record INHERITED_ORIGIN
    "An entry that has been inherited through an extends clause."
    Absyn.Path baseClass "The path of the baseclass the entry was inherited from.";
    Absyn.Info info "The info of the extends clause.";
    list<EntryOrigin> origin "The origins of the element in the baseclass.";
    Env originEnv "The environment the entry was inherited from.";
  end INHERITED_ORIGIN;

  record REDECLARED_ORIGIN
    "An entry that has replaced another entry through redeclare."
    Env originEnv "The environment the replacement came from.";
  end REDECLARED_ORIGIN;

  record IMPORTED_ORIGIN
    "An entry that has been imported with an import statement."
    Absyn.Import imp;
    Absyn.Info info;
    Env originEnv "The environment the entry was imported from.";
  end IMPORTED_ORIGIN;
end EntryOrigin;

public uniontype Entry
  record ENTRY
    String name;
    SCode.Element element;
    Integer scopeLevel;
    list<EntryOrigin> origins;
  end ENTRY;
end Entry;

public uniontype ScopeType
  record NORMAL_SCOPE end NORMAL_SCOPE;
  record ENCAPSULATED_SCOPE end ENCAPSULATED_SCOPE;
  record IMPLICIT_SCOPE "This scope contains one or more iterators; they are made unique by the following index (plus their name)" Integer iterIndex; end IMPLICIT_SCOPE;
end ScopeType;

public uniontype Env
  record ENV
    Option<String> name;
    ScopeType scopeType;
    list<Env> scopes;
    Integer scopeCount;
    AvlTree entries;
  end ENV;
end Env;

public constant Env emptyEnv = ENV(NONE(), NORMAL_SCOPE(), {}, 0, emptyAvlTree);

public function openScope
  input Option<String> inScopeName;
  input SCode.Encapsulated inEncapsulated;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inScopeName, inEncapsulated, inEnv)
    local
      list<Env> scopes;
      AvlTree entries;
      ScopeType ty;
      Integer sc;

    case (_, SCode.NOT_ENCAPSULATED(), ENV(_, ty, scopes, sc, entries))
      equation
  sc = sc + 1;
      then
  ENV(inScopeName, ty, inEnv :: scopes, sc, entries);

    case (_, _, ENV(_, _, scopes, sc, _))
      equation
  sc = sc + 1;
      then
  ENV(inScopeName, ENCAPSULATED_SCOPE(), inEnv :: scopes, sc, emptyAvlTree);

  end match;
end openScope;

public function exitScope
  input Env inEnv;
  output Env outEnv;
algorithm
  ENV(scopes = outEnv :: _) := inEnv;
end exitScope;

public function exitScopes
  input Env inEnv;
  input Integer inScopes;
  output Env outEnv;
algorithm
  outEnv := match(inEnv, inScopes)
    case (_, 0) then inEnv;
    else exitScopes(exitScope(inEnv), inScopes - 1);
  end match;
end exitScopes;

public function topScope
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEnv)
    local
      list<Env> scopes;

    case ENV(scopes = {_}) then inEnv;
    case ENV(scopes = scopes) then List.secondLast(scopes);
  end match;
end topScope;

public function builtinScope
  input Env inEnv;
  output Env outEnv;
protected
  list<Env> scopes;
algorithm
  ENV(scopes = scopes) := inEnv;
  outEnv := List.last(scopes);
end builtinScope;

public function isTopScope
  input Env inEnv;
  output Boolean outIsTopScope;
algorithm
  outIsTopScope := match(inEnv)
    case ENV(scopes = {_}) then true;
    else false;
  end match;
end isTopScope;

public function isBuiltinScope
  input Env inEnv;
  output Boolean outIsBuiltinScope;
algorithm
  outIsBuiltinScope := match(inEnv)
    case ENV(scopes = {}) then true;
    else false;
  end match;
end isBuiltinScope;

public function makeEntry
  input SCode.Element inElement;
  input Env inEnv;
  output Entry outEntry;
protected
  Integer scope_lvl;
  String name;
algorithm
  scope_lvl := scopeCount(inEnv);
  name := SCode.elementName(inElement);
  outEntry := ENTRY(name, inElement, scope_lvl, {});
end makeEntry;

public function makeEntryWithOrigin
  input SCode.Element inElement;
  input list<EntryOrigin> inOrigin;
  input Env inEnv;
  output Entry outEntry;
protected
  Integer scope_lvl;
  String name;
algorithm
  scope_lvl := scopeCount(inEnv);
  name := SCode.elementName(inElement);
  outEntry := ENTRY(name, inElement, scope_lvl, inOrigin);
end makeEntryWithOrigin;

public function insertEntry
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  ScopeType ty;
  list<Env> scopes;
  Integer sc;
  AvlTree entries;
algorithm
  ENV(name, ty, scopes, sc, entries) := inEnv;
  entries := avlTreeAdd(entries, entryName(inEntry), inEntry, mergeEntry);
  outEnv := ENV(name, ty, scopes, sc, entries);
end insertEntry;

protected function mergeEntry
  "Update function used by insertEntry to resolve conflicts when trying to add
   an entry which already exists."
  input Entry inOldEntry;
  input Entry inNewEntry;
  output Entry outEntry;
algorithm
  outEntry := matchcontinue(inOldEntry, inNewEntry)
    local
      String name;
      SCode.Element old_element, new_element, element;
      Integer old_scope, new_scope, scope;
      list<EntryOrigin> old_origins, new_origins, origins;
      EntryOrigin origin;

    // If the scope level of the new entry is larger than the old, then it will
    // simply shadowe the old entry.
    case (ENTRY(name = name, scopeLevel = old_scope), ENTRY(scopeLevel = new_scope))
      equation
  true = new_scope > old_scope;
      then
  inNewEntry;

    // Otherwise, merge the origins to make sure that it's a valid insertion.
    // Then update the old entry with the new origins.
    case (ENTRY(name, old_element, scope, old_origins),
    ENTRY(element = new_element, origins = new_origins))
      equation
  // New entries should only have one origin.
  origin = getSingleOriginFromList(new_origins);
  element = checkOrigin(origin, old_origins, old_element, new_element);
  origins = mergeOrigin(origin, old_origins);
      then
  ENTRY(name, element, scope, origins);

    case (ENTRY(name = name), _)
      equation
  true = Flags.isSet(Flags.FAILTRACE);
  Debug.traceln("- NFEnv.mergeEntry failed on entry " +& name);
      then
  fail();

  end matchcontinue;
end mergeEntry;

protected function getSingleOriginFromList
  input list<EntryOrigin> inOrigins;
  output EntryOrigin outOrigin;
algorithm
  outOrigin := match(inOrigins)
    local
      EntryOrigin origin;

    case {} then LOCAL_ORIGIN();
    case {origin} then origin;

  end match;
end getSingleOriginFromList;

protected function mergeOrigin
  "Adds a new origin to a list of origins."
  input EntryOrigin inNewOrigin;
  input list<EntryOrigin> inOldOrigins;
  output list<EntryOrigin> outOrigins;
algorithm
  outOrigins := matchcontinue(inNewOrigin, inOldOrigins)
    local
      list<EntryOrigin> rest_origins;

    // The new origin is inherited, try to merge it with an existing origin.
    case (INHERITED_ORIGIN(baseClass = _), _)
      then mergeInheritedOrigin(inNewOrigin, inOldOrigins);

    // The first origin is local. Keep it at the head of the list, so that we
    // can quickly determine if an entry is local or not.
    case (_, LOCAL_ORIGIN() :: rest_origins)
      then LOCAL_ORIGIN() :: inNewOrigin :: rest_origins;

    // Otherwise, just add the new origin to the head of the list.
    else inNewOrigin :: inOldOrigins;

  end matchcontinue;
end mergeOrigin;

protected function mergeInheritedOrigin
  "This function handles the case when an element has multiple origins from the
   same base class, i.e. when an element is inherited from multiple sources in a
   base class. In that case we can merge the sub-origins of those origins. Fails
   if no matching origin is found."
  input EntryOrigin inNewOrigin;
  input list<EntryOrigin> inOldOrigins;
  output list<EntryOrigin> outOrigins;
algorithm
  outOrigins := matchcontinue(inNewOrigin, inOldOrigins)
    local
      Absyn.Path bc1, bc2;
      list<EntryOrigin> origin1, origin2, rest_origins;
      Absyn.Info info;
      EntryOrigin origin;
      Env env;

    // Found two origins with the same base class, merge their origins.
    case (INHERITED_ORIGIN(baseClass = bc1, origin = origin1),
  INHERITED_ORIGIN(bc2, info, origin2, env) :: rest_origins)
      equation
  true = Absyn.pathEqual(bc1, bc2);
  origin2 = List.fold(origin1, mergeOrigin, origin2);
      then
  INHERITED_ORIGIN(bc2, info, origin2, env) :: rest_origins;

    // No match, search the rest.
    case (_, origin :: rest_origins)
      equation
  rest_origins = mergeInheritedOrigin(inNewOrigin, rest_origins);
      then
  origin :: rest_origins;

  end matchcontinue;
end mergeInheritedOrigin;

protected function checkOrigin
  "Checks that it's possible to merge a new origin with a list of existing
   origins for an entry. Also determines whether we should keep the old or the
   new element. Assumes that elements are added in the order local -> imported
   -> inherited."
  input EntryOrigin inNewOrigin;
  input list<EntryOrigin> inOldOrigins;
  input SCode.Element inOldElement;
  input SCode.Element inNewElement;
  output SCode.Element outElement;
algorithm
  outElement := match(inNewOrigin, inOldOrigins, inOldElement, inNewElement)
    local
      String name, err_msg;
      EntryOrigin origin;

    // Elements imported with unqualified imports can be shadowed by other
    // elements, and they have the lowest priority of all entry types. The
    // shadowing might be on purpose though, since an unqualified import can
    // import elements the user isn't interested in, so we don't print a warning
    // for this. It's also illegal to find a name in multiple unqualified
    // imports, but that's only an error if we actually try to look the name up
    // so we can't print an error for that here.

    // The new element was imported from an unqualified import, keep the old.
    case (IMPORTED_ORIGIN(imp = Absyn.UNQUAL_IMPORT(path = _)), _, _, _)
      then inOldElement;

    // The old element was imported from an unqualified import, replace with the new.
    case (_, IMPORTED_ORIGIN(imp = Absyn.UNQUAL_IMPORT(path = _)) :: _, _, _)
      then inNewElement;

    // The new element is imported by a named or qualified import, which means
    // that we either have conflicting imports or that the imported element is
    // shadowed by a local/inherited element.
    case (IMPORTED_ORIGIN(imp = _), _, _, _)
      equation
  // Check if we have conflicting imports.
  List.map1_0(inOldOrigins, checkOriginImportConflict, inNewOrigin);

  // If we reached here there was no conflict, but the imported entry
  // will be shadowed by the old entry. This makes the import useless, so
  // we print a warning but keep the old entry and continue.
  printImportShadowWarning(inNewOrigin, inOldElement);
      then
  inOldElement;

    // If the old element was imported, then it will be shadowed by the new
    // element. Note that if the old element would have had more than one
    // origin, then we would already have printed a warning in the case above
    // when it was added.
    case (_, {origin as IMPORTED_ORIGIN(imp = _)}, _, _)
      equation
  printImportShadowWarning(origin, inNewElement);
      then
  inNewElement;

    // The new element was inherited, check that it's identical to the existing
    // element. Keep the old one in that case, so that e.g. error messages favor
    // the local elements.
    case (INHERITED_ORIGIN(baseClass = _), _, _, _)
      equation
  /*********************************************************************/
  // TODO: Check duplicate elements due to inheritance here.
  //       Or perhaps we shouldn't check this here, but in NFInstFlatten
  //       instead so we get the qualified name of the class.
  /*********************************************************************/
      then
  inOldElement;

    // The new element is a local element. Since local elements are added first
    // this means that we have duplicate elements in the scope. This is not
    // allowed, so print an error and fail.
    case (LOCAL_ORIGIN(), _, _, _)
      equation
  printDoubleDeclarationError(inOldElement, inNewElement);
      then
  fail();

    // Same as case above, but with builtin elements.
    case (BUILTIN_ORIGIN(), _, _, _)
      equation
  printDoubleDeclarationError(inOldElement, inNewElement);
      then
  fail();

    // Other cases shouldn't occur.
    else
      equation
  name = SCode.elementName(inNewElement);
  err_msg = "NFEnv.checkOrigin failed on unhandled origin!";
  Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
      then
  fail();

  end match;
end checkOrigin;

protected function checkOriginImportConflict
  "Helper function to checkOrigin. Print an error message if the two given
   origins are both imports, since multiple named/qualified imports may not
   have the same import name."
  input EntryOrigin inOldOrigin;
  input EntryOrigin inNewOrigin;
algorithm
  _ := match(inOldOrigin, inNewOrigin)
    local
      Absyn.Import imp;
      String name;
      Absyn.Info info1, info2;

    case (IMPORTED_ORIGIN(imp = imp, info = info1), IMPORTED_ORIGIN(info = info2))
      equation
  name = Absyn.importName(imp);
  Error.addMultiSourceMessage(Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,
    {name}, {info2, info1});
      then
  fail();

    else ();
  end match;
end checkOriginImportConflict;

protected function printImportShadowWarning
  "Prints a warning that an import was shadowed by a local/inherited element.
   This is allowed, but since it makes the import useless it's almost certainly a
   user mistake."
  input EntryOrigin inImportOrigin;
  input SCode.Element inShadowElement;
protected
  Absyn.Import imp;
  Absyn.Info info1, info2;
  String import_str;
algorithm
  info1 := SCode.elementInfo(inShadowElement);
  IMPORTED_ORIGIN(imp = imp, info = info2) := inImportOrigin;
  import_str := Dump.unparseImportStr(imp);
  Error.addMultiSourceMessage(Error.LOOKUP_SHADOWING,
    {import_str}, {info1, info2});
end printImportShadowWarning;

protected function printDoubleDeclarationError
  input SCode.Element inOldElement;
  input SCode.Element inNewElement;
protected
  Absyn.Info info1, info2;
  String name;
algorithm
  (name, info1) := SCode.elementNameInfo(inNewElement);
  info2 := SCode.elementInfo(inOldElement);
  Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
    {name}, {info2, info1});
end printDoubleDeclarationError;

public function insertElement
  input SCode.Element inElement;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := insertEntry(makeEntry(inElement, inEnv), inEnv);
end insertElement;

public function insertElementWithOrigin
  input SCode.Element inElement;
  input list<EntryOrigin> inOrigin;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := insertEntry(makeEntryWithOrigin(inElement, inOrigin, inEnv), inEnv);
end insertElementWithOrigin;

public function replaceElement
  input SCode.Element inReplacement;
  input Env inEnv;
  output Env outEnv;
protected
  Entry entry;
algorithm
  entry := makeEntry(inReplacement, inEnv);
  outEnv := replaceEntry(entry, inEnv);
end replaceElement;

public function replaceEntry
  input Entry inReplacement;
  input Env inEnv;
  output Env outEnv;
protected
  Option<String> name;
  ScopeType ty;
  list<Env> scopes;
  Integer sc;
  AvlTree entries;
  String entry_name;
algorithm
  ENV(name, ty, scopes, sc, entries) := inEnv;
  entry_name := entryName(inReplacement);
  //entries := avlTreeUpdate(entries, entry_name, replaceElement2, inReplacement);
  outEnv := ENV(name, ty, scopes, sc, entries);
end replaceEntry;

public function insertIterators
  "Opens up a new implicit scope in the environment and adds the given
   iterators."
  input Absyn.ForIterators inIterators;
  input Integer inIterIndex;
  input Env inEnv;
  output Env outEnv;
protected
  Env env;
  list<Env> scopes;
  Integer sc;
  AvlTree entries;
algorithm
  ENV(_, _, scopes, sc, entries) := inEnv;
  sc := sc + 1;
  scopes := inEnv :: scopes;
  env := ENV(SOME("$for$"), IMPLICIT_SCOPE(inIterIndex), scopes, sc, entries);
  outEnv := List.fold(inIterators, insertIterator, env);
end insertIterators;

protected function insertIterator
  input Absyn.ForIterator inIterator;
  input Env inEnv;
  output Env outEnv;
protected
  Absyn.Ident iter_name;
  SCode.Element iter;
algorithm
  Absyn.ITERATOR(name = iter_name) := inIterator;
  iter := SCode.COMPONENT(iter_name, SCode.defaultPrefixes,
    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()),
    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
    SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := insertElement(iter, inEnv);
end insertIterator;

public function lookupEntry
  input String inName;
  input Env inEnv;
  output Entry outEntry;
protected
  AvlTree entries;
algorithm
  ENV(entries = entries) := inEnv;
  outEntry := avlTreeGet(entries, inName);
end lookupEntry;

public function entryEnv
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := matchcontinue(inEntry, inEnv)
    local
      Integer scope_lvl, scope_count;
      list<Env> scopes;

    case (ENTRY(scopeLevel = scope_lvl), ENV(scopeCount = scope_count))
      equation
  true = intEq(scope_lvl, scope_count);
      then
  inEnv;

    case (ENTRY(scopeLevel = scope_lvl),
    ENV(scopeCount = scope_count, scopes = scopes))
      equation
  scope_lvl = scope_count - scope_lvl;
      then
  listGet(scopes, scope_lvl);

  end matchcontinue;
end entryEnv;

public function resolveEntry
  input Entry inEntry;
  input Env inEnv;
  output Entry outEntry;
  output Env outEnv;
algorithm
  (outEntry, outEnv) := match(inEntry, inEnv)
    local
      Entry entry;
      Env env;
      EntryOrigin origin;

    // Local entry => nothing to resolve.
    case (ENTRY(origins = {}), _) then (inEntry, inEnv);
    case (ENTRY(origins = LOCAL_ORIGIN() :: _), _) then (inEntry, inEnv);
    case (ENTRY(origins = BUILTIN_ORIGIN() :: _), _) then (inEntry, inEnv);

    // Some origins => choose the first.
    case (ENTRY(origins = origin :: _), _)
      equation
  env = originEnv(origin);
  entry = setEntryScope(inEntry, env);
      then
  (entry, env);

  end match;
end resolveEntry;

protected function originEnv
  input EntryOrigin inOrigin;
  output Env outEnv;
algorithm
  outEnv := match(inOrigin)
    local
      Env env;

    case INHERITED_ORIGIN(originEnv = env) then env;
    case REDECLARED_ORIGIN(originEnv = env) then env;
    case IMPORTED_ORIGIN(originEnv = env) then env;

  end match;
end originEnv;

protected function setEntryOrigin
  input Entry inEntry;
  input list<EntryOrigin> inOrigin;
  output Entry outEntry;
protected
  String name;
  SCode.Element element;
  Integer scope;
algorithm
  ENTRY(name, element, scope, _) := inEntry;
  outEntry := ENTRY(name, element, scope, inOrigin);
end setEntryOrigin;

protected function setEntryScope
  input Entry inEntry;
  input Env inEnv;
  output Entry outEntry;
protected
  String name;
  SCode.Element element;
  list<EntryOrigin> origins;
  Integer scope;
algorithm
  ENTRY(name, element, _, origins) := inEntry;
  scope := scopeCount(inEnv);
  outEntry := ENTRY(name, element, scope, origins);
end setEntryScope;

protected function entryScopeLevel
  input Entry inEntry;
  output Integer outScopeLevel;
algorithm
  ENTRY(scopeLevel = outScopeLevel) := inEntry;
end entryScopeLevel;

protected function scopeCount
  "Returns the number of scopes in the environment."
  input Env inEnv;
  output Integer outScopeCount;
algorithm
  ENV(scopeCount = outScopeCount) := inEnv;
end scopeCount;

protected function scopeExplicitCount
  "Counts the number of explicit scopes in the environment, i.e. disregarding
   any implicit scopes such as for-loop scopes. Assumes that implicit scopes are
   always the most nested of the scopes."
  input Env inEnv;
  output Integer outScopeCount;
algorithm
  outScopeCount := match(inEnv)
    local
      Integer sc;

    case ENV(scopeType = IMPLICIT_SCOPE(iterIndex = _))
      then scopeExplicitCount(exitScope(inEnv));

    case ENV(scopeCount = sc) then sc;
  end match;
end scopeExplicitCount;

public function isScopeEncapsulated
  input Env inEnv;
  output Boolean outIsEncapsulated;
algorithm
  outIsEncapsulated := match(inEnv)
    case ENV(scopeType = ENCAPSULATED_SCOPE()) then true;
    else false;
  end match;
end isScopeEncapsulated;

public function getImplicitScopeIndex
  "Returns the index of the implicit scope, or fails if the current scope is
   explicit."
  input Env inEnv;
  output Integer outIndex;
algorithm
  ENV(scopeType = IMPLICIT_SCOPE(iterIndex = outIndex)) := inEnv;
end getImplicitScopeIndex;

public function isLocalScopeEntry
  input Entry inEntry;
  input Env inEnv;
  output Boolean outIsLocal;
algorithm
  outIsLocal := intGe(entryScopeLevel(inEntry), scopeExplicitCount(inEnv));
end isLocalScopeEntry;

public function entryHasBuiltinOrigin
  input Entry inEntry;
  output Boolean outBuiltin;
algorithm
  outBuiltin := match(inEntry)
    case ENTRY(origins = {BUILTIN_ORIGIN()}) then true;
    else false;
  end match;
end entryHasBuiltinOrigin;

public function entryName
  input Entry inEntry;
  output String outName;
algorithm
  ENTRY(name = outName) := inEntry;
end entryName;

public function renameEntry
  input Entry inEntry;
  input String inName;
  output Entry outEntry;
protected
  SCode.Element element;
  Integer scope;
  list<EntryOrigin> origins;
algorithm
  ENTRY(_, element, scope, origins) := inEntry;
  outEntry := ENTRY(inName, element, scope, origins);
end renameEntry;

public function entryElement
  input Entry inEntry;
  output SCode.Element outElement;
algorithm
  ENTRY(element = outElement) := inEntry;
end entryElement;

public function isClassEntry
  input Entry inEntry;
  output Boolean outIsClass;
algorithm
  outIsClass := match(inEntry)
    case ENTRY(element = SCode.CLASS(name = _)) then true;
    else false;
  end match;
end isClassEntry;

public function scopeName
  input Env inEnv;
  output String outString;
algorithm
  outString := match(inEnv)
    local
      String name;

    case ENV(name = SOME(name)) then name;
    case ENV(scopes = {}) then "<builtin>";
    else "<global>";

  end match;
end scopeName;

public function scopeNames
  input Env inEnv;
  output list<String> outNames;
algorithm
  outNames := scopeNames2(inEnv, {});
end scopeNames;

protected function scopeNames2
  input Env inEnv;
  input list<String> inAccumNames;
  output list<String> outNames;
algorithm
  outNames := match(inEnv, inAccumNames)
    local
      String name;
      Env env;

    case (ENV(name = SOME(name), scopes = env :: _), _)
      then scopeNames2(env, name :: inAccumNames);

    case (ENV(scopes = env :: _), _)
      then scopeNames2(env, inAccumNames);

    case (ENV(name = SOME(name), scopes = {}), _)
      then name :: inAccumNames;

    case (ENV(scopes = {}), _)
      then inAccumNames;

  end match;
end scopeNames2;

public function envPath
  input Env inEnv;
  output Absyn.Path outPath;
algorithm
  outPath := match(inEnv)
    local
      String name;
      Absyn.Path path;
      Env env;

    case ENV(name = SOME(name), scopes = ENV(name = NONE()) :: _)
      then Absyn.IDENT(name);

    case ENV(name = SOME(name))
      equation
  env = exitScope(inEnv);
  path = envPath(env);
      then
  Absyn.QUALIFIED(name, path);

  end match;
end envPath;

public function prefixIdentWithEnv
  input String inIdent;
  input Env inEnv;
  output Absyn.Path outPath;
protected
  list<String> strl;
algorithm
  strl := listReverse(scopeNames(inEnv));
  strl := inIdent :: strl;
  outPath := Absyn.stringListPathReversed(strl);
end prefixIdentWithEnv;

public function isEqual
  "Checks if two environments are equal, with regards to the scope names."
  input Env inEnv1;
  input Env inEnv2;
  output Boolean outIsEqual;
algorithm
  outIsEqual := matchcontinue(inEnv1, inEnv2)
    local
      String n1, n2;
      Env rest1, rest2;

    case (ENV(name = SOME(n1)), ENV(name = SOME(n2)))
      equation
  false = stringEq(n1, n2);
      then
  false;

    case (ENV(scopes = {}), ENV(scopes = {})) then true;

    else
      equation
  rest1 = exitScope(inEnv1);
  rest2 = exitScope(inEnv2);
      then
  isEqual(rest1, rest2);

  end matchcontinue;
end isEqual;

public function isPrefix
  "Checks if one environment is a prefix of another."
  input Env inPrefixEnv;
  input Env inEnv;
  output Boolean outIsPrefix;
algorithm
  outIsPrefix := matchcontinue(inPrefixEnv, inEnv)
    local
      Env  rest2;
      Integer sc1, sc2, sc_diff;

    // If the first environment has more scopes than the second, then it can't
    // be a prefix.
    case (ENV(scopeCount = sc1), ENV(scopeCount = sc2))
      equation
  true = intGt(sc1, sc2);
      then
  false;

    // Otherwise, remove scopes from the second environment until they are the
    // same length, and check if they are equal or not.
    case (ENV(scopeCount = sc1), ENV(scopeCount = sc2))
      equation
  sc_diff = sc2 - sc1;
  rest2 = exitScopes(inEnv, sc_diff);
      then
  isEqual(inPrefixEnv, rest2);

  end matchcontinue;
end isPrefix;

public function printEnvPathStr
  input Env inEnv;
  output String outString;
protected
  list<String> scopes;
algorithm
  scopes := scopeNames(inEnv);
  outString := stringDelimitList(scopes, ".");
end printEnvPathStr;

public function buildInitialEnv
  input SCode.Program inProgram;
  output Env outEnv;
protected
  Env env;
  SCode.Program prog, builtin;
algorithm
  env := emptyEnv;
  env := insertElement(NFBuiltin.BUILTIN_TIME, env);
  (builtin, prog) := List.splitOnTrue(inProgram, SCode.isBuiltinElement);
  env := List.fold1(builtin, insertElementWithOrigin, {BUILTIN_ORIGIN()}, env);
  env := openScope(NONE(), SCode.NOT_ENCAPSULATED(), env);
  outEnv := List.fold(prog, insertElement, env);
end buildInitialEnv;

public function enterEntryScope
  input Entry inEntry;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEntry, inEnv)
    local
      Env env;
      SCode.ClassDef cdef;
      Absyn.Info info;
      Absyn.TypeSpec ty;
      Entry entry;

    case (ENTRY(element = SCode.CLASS(classDef = cdef, info = info)), _)
      equation
  env = openClassEntryScope(inEntry, inEnv);
  env = populateEnvWithClassDef(cdef, SCode.PUBLIC(), {}, env,
    elementSplitterRegular, info, env);
      then
  env;

    case (ENTRY(element = SCode.COMPONENT(typeSpec = ty, info = info)), _)
      equation
  (entry, env) = NFLookup.lookupTypeSpec(ty, inEnv, info);
  env = enterEntryScope(entry, env);
      then
  env;

  end match;
end enterEntryScope;

protected function openClassEntryScope
  input Entry inClass;
  input Env inEnv;
  output Env outEnv;
protected
  String name;
  SCode.Encapsulated ep;
algorithm
  ENTRY(element = SCode.CLASS(name = name, encapsulatedPrefix = ep)) := inClass;
  outEnv := openScope(SOME(name), ep, inEnv);
end openClassEntryScope;

protected function elementSplitterRegular
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.EXTENDS(baseClassPath = _), _, _, _)
      then (inClsAndVars, inElement :: inExtends, inImports);

    case (SCode.IMPORT(imp = _), _, _, _)
      then (inClsAndVars, inExtends, inElement :: inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterRegular;

partial function SplitFunc
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
end SplitFunc;

protected function populateEnvWithClassDef
  input SCode.ClassDef inClassDef;
  input SCode.Visibility inVisibility;
  input list<EntryOrigin> inOrigins;
  input Env inEnv;
  input SplitFunc inSplitFunc;
  input Absyn.Info inInfo;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inClassDef, inVisibility, inOrigins, inEnv, inSplitFunc,
      inInfo, inAccumEnv)
    local
      list<SCode.Element> elems, cls_vars, exts, imps;
      Env env;
      list<EntryOrigin> origin;
      Entry entry;
      list<SCode.Enum> enums;
      Absyn.Path path;
      SCode.ClassDef cdef;
      Absyn.TypeSpec ty;

    case (SCode.PARTS(elementLst = elems), _, _, _, _, _, env)
      equation
  (cls_vars, exts, imps) =
    populateEnvWithClassDef2(elems, inSplitFunc, {}, {}, {});
  cls_vars = applyVisibilityToElements(cls_vars, inVisibility);
  exts = applyVisibilityToElements(exts, inVisibility);

  origin = collapseInheritedOrigins(inOrigins);
  // Add classes, component and imports first, so that extends can be found.
  env = populateEnvWithElements(cls_vars, origin, env);
  env = populateEnvWithImports(imps, env, false);
  env = populateEnvWithExtends(exts, inOrigins, inEnv, env);
      then
  env;

    case (SCode.CLASS_EXTENDS(composition = cdef), _, _, _, _, _, _)
      then populateEnvWithClassDef(cdef, inVisibility, inOrigins, inEnv,
  inSplitFunc, inInfo, inAccumEnv);

    case (SCode.DERIVED(typeSpec = ty), _, _, _, _, _, _)
      equation
  (entry, env) = NFLookup.lookupTypeSpec(ty, inEnv, inInfo);
  ENTRY(element = SCode.CLASS(classDef = cdef)) = entry;
  // TODO: Only create this environment if needed, i.e. if the cdef
  // contains extends.
  env = openClassEntryScope(entry, env);
  env = populateEnvWithClassDef(cdef, inVisibility, inOrigins, env,
    elementSplitterExtends, inInfo, inAccumEnv);
  env = populateEnvWithClassDef(cdef, inVisibility, inOrigins, env,
    inSplitFunc, inInfo, inAccumEnv);
      then
  env;

    case (SCode.ENUMERATION(enumLst = enums), _, _, _, _, _, env)
      equation
  path = envPath(inEnv);
  env = insertEnumLiterals(enums, path, 1, env);
      then
  env;

  end match;
end populateEnvWithClassDef;

protected function applyVisibilityToElements
  input list<SCode.Element> inElements;
  input SCode.Visibility inVisibility;
  output list<SCode.Element> outElements;
algorithm
  outElements := match(inElements, inVisibility)
    case (_, SCode.PUBLIC()) then inElements;
    else List.map1(inElements, SCode.setElementVisibility, inVisibility);
  end match;
end applyVisibilityToElements;

protected function populateEnvWithClassDef2
  input list<SCode.Element> inElements;
  input SplitFunc inSplitFunc;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElements, inSplitFunc, inClsAndVars, inExtends, inImports)
    local
      SCode.Element el;
      list<SCode.Element> rest_el, cls_vars, exts, imps;

    case (el :: rest_el, _, cls_vars, exts, imps)
      equation
  (cls_vars, exts, imps) = inSplitFunc(el, cls_vars, exts, imps);
  (cls_vars, exts, imps) =
    populateEnvWithClassDef2(rest_el, inSplitFunc, cls_vars, exts, imps);
      then
  (cls_vars, exts, imps);

    case ({}, _, _, _, _) then (inClsAndVars, inExtends, inImports);

  end match;
end populateEnvWithClassDef2;

protected function insertEnumLiterals
  input list<SCode.Enum> inEnum;
  input Absyn.Path inEnumPath;
  input Integer inNextValue;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inEnum, inEnumPath, inNextValue, inEnv)
    local
      SCode.Enum lit;
      list<SCode.Enum> rest_lits;
      Env env;

    case (lit :: rest_lits, _, _, _)
      equation
  env = insertEnumLiteral(lit, inEnumPath, inNextValue, inEnv);
      then
  insertEnumLiterals(rest_lits, inEnumPath, inNextValue + 1, env);

    case ({}, _, _, _) then inEnv;

  end match;
end insertEnumLiterals;

protected function insertEnumLiteral
  "Extends the environment with an enumeration."
  input SCode.Enum inEnum;
  input Absyn.Path inEnumPath;
  input Integer inValue;
  input Env inEnv;
  output Env outEnv;
protected
  SCode.Element enum_lit;
  SCode.Ident lit_name;
  Absyn.TypeSpec ty;
  String index;
algorithm
  SCode.ENUM(literal = lit_name) := inEnum;
  index := intString(inValue);
  ty := Absyn.TPATH(Absyn.QUALIFIED("$EnumType",
    Absyn.QUALIFIED(index, inEnumPath)), NONE());
  enum_lit := SCode.COMPONENT(lit_name, SCode.defaultPrefixes, SCode.ATTR({},
    SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()), ty,
    SCode.NOMOD(), SCode.noComment, NONE(), Absyn.dummyInfo);
  outEnv := insertElement(enum_lit, inEnv);
end insertEnumLiteral;

protected function populateEnvWithElements
  input list<SCode.Element> inElements;
  input list<EntryOrigin> inOrigin;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := List.fold1(inElements, insertElementWithOrigin, inOrigin, inEnv);
end populateEnvWithElements;

protected function populateEnvWithImports
  input list<SCode.Element> inImports;
  input Env inEnv;
  input Boolean inIsExtended;
  output Env outEnv;
algorithm
  outEnv := match(inImports, inEnv, inIsExtended)
    local
      Env top_env, env;

    case (_, _, true) then inEnv;
    case ({}, _, _) then inEnv;

    else
      equation
  top_env = topScope(inEnv);
  env = List.fold1(inImports, populateEnvWithImport, top_env, inEnv);
      then
  env;

  end match;
end populateEnvWithImports;

protected function populateEnvWithImport
  input SCode.Element inImport;
  input Env inTopScope;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inImport, inTopScope, inEnv)
    local
      Absyn.Import imp;
      Absyn.Info info;
      Absyn.Path path;
      Entry entry;
      Env env;
      EntryOrigin origin;

    case (SCode.IMPORT(imp = imp, info = info), _, _)
      equation
  // Look up the import name.
  path = Absyn.importPath(imp);
  (entry, env) = NFLookup.lookupImportPath(path, inTopScope, info);
  // Convert the entry to an entry imported into the given environment.
  origin = IMPORTED_ORIGIN(imp, info, env);
  entry = makeEntryWithOrigin(entryElement(entry), {origin}, inEnv);
  // Add the imported entry to the environment.
  env = populateEnvWithImport2(imp, entry, env, info, inEnv);
      then
  env;

  end match;
end populateEnvWithImport;

protected function populateEnvWithImport2
  input Absyn.Import inImport;
  input Entry inEntry;
  input Env inEnv;
  input Absyn.Info inInfo;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inImport, inEntry, inEnv, inInfo, inAccumEnv)
    local
      String name;
      Env env;
      Entry entry;
      SCode.ClassDef cdef;
      list<EntryOrigin> origins;

    // A renaming import, 'import D = A.B.C'.
    case (Absyn.NAMED_IMPORT(name = name), _, _, _, _)
      equation
  entry = renameEntry(inEntry, name);
  env = insertEntry(entry, inAccumEnv);
      then
  env;

    // A qualified import, 'import A.B.C'.
    case (Absyn.QUAL_IMPORT(path = _), _, _, _, _)
      equation
  env = insertEntry(inEntry, inAccumEnv);
      then
  env;

    // An unqualified import, 'import A.B.*'.
    case (Absyn.UNQUAL_IMPORT(path = _),
  ENTRY(element = SCode.CLASS(classDef = cdef), origins = origins), _, _, _)
      equation
  env = populateEnvWithClassDef(cdef, SCode.PUBLIC(), origins, inEnv,
    elementSplitterRegular, inInfo, inAccumEnv);
      then
  env;

    // This should not happen, group imports are split into separate imports by
    // SCodeUtil.translateImports.
    case (Absyn.GROUP_IMPORT(prefix = _), _, _, _, _)
      equation
  Error.addSourceMessage(Error.INTERNAL_ERROR,
    {"NFEnv.populateEnvWithImport2 got unhandled group import!\n"}, inInfo);
      then
  inEnv;

  end match;
end populateEnvWithImport2;

protected function collapseInheritedOrigins
  "Collapses a list of INHERITED_ORIGIN into a list of one nested
   INHERITED_ORIGIN."
  input list<EntryOrigin> inOrigins;
  output list<EntryOrigin> outOrigins;
algorithm
  outOrigins := match(inOrigins)
    local
      EntryOrigin origin;
      list<EntryOrigin> rest_origins;

    // One or more origins, collapse with fold.
    case (origin :: rest_origins)
      equation
  origin = List.fold(rest_origins, collapseInheritedOrigins2, origin);
      then
  {origin};

    // Already collapsed.
    else inOrigins;

  end match;
end collapseInheritedOrigins;

protected function collapseInheritedOrigins2
  input EntryOrigin inOrigin1;
  input EntryOrigin inOrigin2;
  output EntryOrigin outOrigin;
protected
  Absyn.Path bc;
  Absyn.Info info;
  list<EntryOrigin> origins;
  Env env;
algorithm
  INHERITED_ORIGIN(bc, info, origins, env) := inOrigin1;
  origins := inOrigin2 :: origins;
  outOrigin := INHERITED_ORIGIN(bc, info, origins, env);
end collapseInheritedOrigins2;

protected function populateEnvWithExtends
  input list<SCode.Element> inExtends;
  input list<EntryOrigin> inOrigins;
  input Env inEnv;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := List.fold2(inExtends, populateEnvWithExtend, inOrigins, inEnv,
    inAccumEnv);
end populateEnvWithExtends;

protected function populateEnvWithExtend
  input SCode.Element inExtends;
  input list<EntryOrigin> inOrigins;
  input Env inEnv;
  input Env inAccumEnv;
  output Env outAccumEnv;
algorithm
  outAccumEnv := match(inExtends, inOrigins, inEnv, inAccumEnv)
    local
      Entry entry;
      Env env, accum_env;
      SCode.ClassDef cdef;
      EntryOrigin origin;
      list<EntryOrigin> origins;
      Absyn.Path bc;
      Absyn.Info info;
      SCode.Visibility vis;

    case (SCode.EXTENDS(baseClassPath = bc, visibility = vis, info = info), _, _, _)
      equation
  // Look up the base class and check that it's a valid base class.
  (entry, env) = NFLookup.lookupBaseClassName(bc, inEnv, info);
  checkRecursiveExtends(bc, env, inEnv, info);

  // Check entry: not var, not replaceable
  // Create an environment for the base class if needed.
  ENTRY(element = SCode.CLASS(classDef = cdef)) = entry;
  env = openClassEntryScope(entry, env);
  env = populateEnvWithClassDef(cdef, SCode.PUBLIC(), {}, env,
    elementSplitterExtends, info, env);
  // Populate the accumulated environment with the inherited elements.
  origin = INHERITED_ORIGIN(bc, info, {}, env);
  origins = origin :: inOrigins;
  accum_env = populateEnvWithClassDef(cdef, vis, origins, env,
    elementSplitterInherited, info, inAccumEnv);
      then
  accum_env;

  end match;
end populateEnvWithExtend;

protected function checkRecursiveExtends
  input Absyn.Path inExtendedClass;
  input Env inFoundEnv;
  input Env inOriginEnv;
  input Absyn.Info inInfo;
algorithm
  _ := matchcontinue(inExtendedClass, inFoundEnv, inOriginEnv, inInfo)
    local
      String bc_name, path_str;
      Env env;

    case (_, _, _, _)
      equation
  bc_name = Absyn.pathLastIdent(inExtendedClass);
  env = openScope(SOME(bc_name), SCode.NOT_ENCAPSULATED(), inFoundEnv);
  false = isPrefix(env, inOriginEnv);
      then
  ();

    else
      equation
  path_str = Absyn.pathString(inExtendedClass);
  Error.addSourceMessage(Error.RECURSIVE_EXTENDS, {path_str}, inInfo);
      then
  fail();

  end matchcontinue;
end checkRecursiveExtends;

protected function elementSplitterExtends
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.IMPORT(imp = _), _, _, _)
      then (inClsAndVars, inExtends, inElement :: inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterExtends;

protected function elementSplitterInherited
  input SCode.Element inElement;
  input list<SCode.Element> inClsAndVars;
  input list<SCode.Element> inExtends;
  input list<SCode.Element> inImports;
  output list<SCode.Element> outClsAndVars;
  output list<SCode.Element> outExtends;
  output list<SCode.Element> outImports;
algorithm
  (outClsAndVars, outExtends, outImports) :=
  match(inElement, inClsAndVars, inExtends, inImports)
    case (SCode.COMPONENT(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.CLASS(name = _), _, _, _)
      then (inElement :: inClsAndVars, inExtends, inImports);

    case (SCode.EXTENDS(baseClassPath = _), _, _, _)
      then (inClsAndVars, inElement :: inExtends, inImports);

    else (inClsAndVars, inExtends, inImports);

  end match;
end elementSplitterInherited;

// AVL Tree implementation
public type AvlKey = String;
public type AvlValue = Entry;

protected constant AvlTree emptyAvlTree = AVLTREENODE(NONE(), 0, NONE(), NONE());

public uniontype AvlTree
  "The binary tree data structure"
  record AVLTREENODE
    Option<AvlTreeValue> value "Value";
    Integer height "height of tree, used for balancing";
    Option<AvlTree> left "left subtree";
    Option<AvlTree> right "right subtree";
  end AVLTREENODE;
end AvlTree;

public uniontype AvlTreeValue
  "Each node in the binary tree can have a value associated with it."
  record AVLTREEVALUE
    AvlKey key "Key" ;
    AvlValue value "Value" ;
  end AVLTREEVALUE;
end AvlTreeValue;

protected function avlTreeNew
  "Return an empty tree"
  output AvlTree tree;
algorithm
  tree := emptyAvlTree;
end avlTreeNew;

protected function avlTreeAdd
  "Inserts a new value into the tree. If the key already exists, then the value
   is updated with the given update function."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  input UpdateFunc inUpdateFunc;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inOldValue;
    input AvlValue inNewValue;
    output AvlValue outValue;
  end UpdateFunc;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue, inUpdateFunc)
    local
      AvlKey key;
      Integer key_comp;
      AvlTree tree;

    // Empty node, create a new node for the value.
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = key))), _, _, _)
      equation
  key_comp = stringCompare(inKey, key);
  tree = avlTreeAdd2(inAvlTree, key_comp, inKey, inValue, inUpdateFunc);
  tree = avlBalance(tree);
      then
  tree;

  end match;
end avlTreeAdd;

protected function avlTreeAdd2
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  input UpdateFunc inUpdateFunc;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inOldValue;
    input AvlValue inNewValue;
    output AvlValue outValue;
  end UpdateFunc;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue, inUpdateFunc)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Existing node, update it with the given update function.
    case (AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
  value = inUpdateFunc(value, inValue);
      then
  AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(oval, h, left, right), 1, _, _, _)
      equation
  t = avlCreateEmptyIfNone(right);
  t = avlTreeAdd(t, inKey, inValue, inUpdateFunc);
      then
  AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(oval, h, left, right), -1, _, _, _)
      equation
  t = avlCreateEmptyIfNone(left);
  t = avlTreeAdd(t, inKey, inValue, inUpdateFunc);
      then
  AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeAdd2;

protected function avlTreeAddUnique
  "Inserts a new value into the tree. Fails if the key already exists in the tree."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    // empty tree
    case (AVLTREENODE(value = NONE(), left = NONE(), right = NONE()), _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), 1, NONE(), NONE());

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlBalance(avlTreeAddUnique2(inAvlTree, stringCompare(key, rkey), key, value));

    else
      equation
  Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeAddUnique failed"});
      then fail();

  end match;
end avlTreeAddUnique;

protected function avlTreeAddUnique2
  "Helper function to avlTreeAddUnique."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;
      Absyn.Info info;

    // Insert into right subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
  1, key, value)
      equation
  t = avlCreateEmptyIfNone(right);
  t = avlTreeAddUnique(t, key, value);
      then
  AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(value = oval, height = h, left = left, right = right),
  -1, key, value)
      equation
  t = avlCreateEmptyIfNone(left);
  t = avlTreeAddUnique(t, key, value);
      then
  AVLTREENODE(oval, h, SOME(t), right);
  end match;
end avlTreeAddUnique2;

protected function avlTreeGet
  "Get a value from the binary tree given a key."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  output AvlValue outValue;
protected
  AvlKey rkey;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))) := inAvlTree;
  outValue := avlTreeGet2(inAvlTree, stringCompare(inKey, rkey), inKey);
end avlTreeGet;

protected function avlTreeGet2
  "Helper function to avlTreeGet."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  output AvlValue outValue;
algorithm
  outValue := match(inAvlTree, inKeyComp, inKey)
    local
      AvlKey key;
      AvlValue rval;
      AvlTree left, right;

    // Found match.
    case (AVLTREENODE(value = SOME(AVLTREEVALUE(value = rval))), 0, _)
      then rval;

    // Search to the right.
    case (AVLTREENODE(right = SOME(right)), 1, key)
      then avlTreeGet(right, key);

    // Search to the left.
    case (AVLTREENODE(left = SOME(left)), -1, key)
      then avlTreeGet(left, key);
  end match;
end avlTreeGet2;

protected function avlTreeReplace
  "Replaces the value of an already existing node in the tree with a new value."
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKey, inValue)
    local
      AvlKey key, rkey;
      AvlValue value;

    case (AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey))), key, value)
      then avlTreeReplace2(inAvlTree, stringCompare(key, rkey), key, value);

    else
      equation
  Error.addMessage(Error.INTERNAL_ERROR, {"Env.avlTreeReplace failed"});
      then fail();

  end match;
end avlTreeReplace;

protected function avlTreeReplace2
  "Helper function to avlTreeReplace."
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input AvlValue inValue;
  output AvlTree outAvlTree;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inValue)
    local
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    // Replace this node.
    case (AVLTREENODE(SOME(_), h, left, right), 0, _, _)
      then AVLTREENODE(SOME(AVLTREEVALUE(inKey, inValue)), h, left, right);

    // Insert into right subtree.
    case (AVLTREENODE(oval, h, left, SOME(t)), 1, _, _)
      equation
  t = avlTreeReplace(t, inKey, inValue);
      then
  AVLTREENODE(oval, h, left, SOME(t));

    // Insert into left subtree.
    case (AVLTREENODE(oval, h, SOME(t), right), -1, _, _)
      equation
  t = avlTreeReplace(t, inKey, inValue);
      then
  AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeReplace2;

protected function avlTreeUpdate
  input AvlTree inAvlTree;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
protected
  AvlKey key;
  Integer key_comp;
algorithm
  AVLTREENODE(value = SOME(AVLTREEVALUE(key = key))) := inAvlTree;
  key_comp := stringCompare(key, inKey);
  outAvlTree := avlTreeUpdate2(inAvlTree, key_comp, inKey, inUpdateFunc, inArg);
end avlTreeUpdate;

protected function avlTreeUpdate2
  input AvlTree inAvlTree;
  input Integer inKeyComp;
  input AvlKey inKey;
  input UpdateFunc inUpdateFunc;
  input ArgType inArg;
  output AvlTree outAvlTree;

  partial function UpdateFunc
    input AvlValue inValue;
    input ArgType inArg;
    output AvlValue outValue;
  end UpdateFunc;

  replaceable type ArgType subtypeof Any;
algorithm
  outAvlTree := match(inAvlTree, inKeyComp, inKey, inUpdateFunc, inArg)
    local
      AvlKey key;
      AvlValue value;
      Option<AvlTree> left, right;
      Integer h;
      AvlTree t;
      Option<AvlTreeValue> oval;

    case (AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right), 0, _, _, _)
      equation
  value = inUpdateFunc(value, inArg);
      then
  AVLTREENODE(SOME(AVLTREEVALUE(key, value)), h, left, right);

    case (AVLTREENODE(oval, h, left, SOME(t)), 1, _, _, _)
      equation
  t = avlTreeUpdate(t, inKey, inUpdateFunc, inArg);
      then
  AVLTREENODE(oval, h, left, SOME(t));

    case (AVLTREENODE(oval, h, SOME(t), right), -1, _, _, _)
      equation
  t = avlTreeUpdate(t, inKey, inUpdateFunc, inArg);
      then
  AVLTREENODE(oval, h, SOME(t), right);

  end match;
end avlTreeUpdate2;

protected function avlCreateEmptyIfNone
  "Help function to AvlTreeAdd"
    input Option<AvlTree> t;
    output AvlTree outT;
algorithm
  outT := match(t)
    case (NONE()) then avlTreeNew();
    case (SOME(outT)) then outT;
  end match;
end avlCreateEmptyIfNone;

protected function avlBalance
  "Balances an AvlTree"
  input AvlTree bt;
  output AvlTree outBt;
protected
  Integer d;
algorithm
  d := avlDifferenceInHeight(bt);
  outBt := avlDoBalance(d, bt);
end avlBalance;

protected function avlDoBalance
  "Performs balance if difference is > 1 or < -1"
  input Integer difference;
  input AvlTree bt;
  output AvlTree outBt;
algorithm
  outBt := match(difference, bt)
    case(-1, _) then avlComputeHeight(bt);
    case( 0, _) then avlComputeHeight(bt);
    case( 1, _) then avlComputeHeight(bt);
    // d < -1 or d > 1
    else avlDoBalance2(difference < 0, bt);
  end match;
end avlDoBalance;

protected function avlDoBalance2
"help function to doBalance"
  input Boolean inDiffIsNegative;
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := match(inDiffIsNegative,inBt)
    local AvlTree bt;
    case(true,bt)
      equation
  bt = avlDoBalance3(bt);
  bt = avlRotateLeft(bt);
      then bt;
    case(false,bt)
      equation
  bt = avlDoBalance4(bt);
  bt = avlRotateRight(bt);
      then bt;
  end match;
end avlDoBalance2;

protected function avlDoBalance3 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rr,bt;
    case(bt)
      equation
  true = avlDifferenceInHeight(Util.getOption(avlRightNode(bt))) > 0;
  rr = avlRotateRight(Util.getOption(avlRightNode(bt)));
  bt = avlSetRight(bt,SOME(rr));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance3;

protected function avlDoBalance4 "help function to doBalance2"
  input AvlTree inBt;
  output AvlTree outBt;
algorithm
  outBt := matchcontinue(inBt)
    local
      AvlTree rl,bt;
    case (bt)
      equation
  true = avlDifferenceInHeight(Util.getOption(avlLeftNode(bt))) < 0;
  rl = avlRotateLeft(Util.getOption(avlLeftNode(bt)));
  bt = avlSetLeft(bt,SOME(rl));
      then bt;
    else inBt;
  end matchcontinue;
end avlDoBalance4;

protected function avlSetRight
  "set right treenode"
  input AvlTree node;
  input Option<AvlTree> right;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> l;
  Integer height;
algorithm
  AVLTREENODE(value, height, l, _) := node;
  outNode := AVLTREENODE(value, height, l, right);
end avlSetRight;

protected function avlSetLeft
  "set left treenode"
  input AvlTree node;
  input Option<AvlTree> left;
  output AvlTree outNode;
protected
  Option<AvlTreeValue> value;
  Option<AvlTree> r;
  Integer height;
algorithm
  AVLTREENODE(value, height, _, r) := node;
  outNode := AVLTREENODE(value, height, left, r);
end avlSetLeft;

protected function avlLeftNode
  "Retrieve the left subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(left = subNode) := node;
end avlLeftNode;

protected function avlRightNode
  "Retrieve the right subnode"
  input AvlTree node;
  output Option<AvlTree> subNode;
algorithm
  AVLTREENODE(right = subNode) := node;
end avlRightNode;

protected function avlExchangeLeft
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetRight(inParent, avlLeftNode(inNode));
  parent := avlBalance(parent);
  node := avlSetLeft(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeLeft;

protected function avlExchangeRight
  "help function to balance"
  input AvlTree inNode;
  input AvlTree inParent;
  output AvlTree outParent "updated parent";
protected
  AvlTree parent, node;
algorithm
  parent := avlSetLeft(inParent, avlRightNode(inNode));
  parent := avlBalance(parent);
  node := avlSetRight(inNode, SOME(parent));
  outParent := avlBalance(node);
end avlExchangeRight;

protected function avlRotateLeft
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeLeft(Util.getOption(avlRightNode(node)), node);
end avlRotateLeft;

protected function avlRotateRight
  "help function to balance"
  input AvlTree node;
  output AvlTree outNode "updated node";
algorithm
  outNode := avlExchangeRight(Util.getOption(avlLeftNode(node)), node);
end avlRotateRight;

protected function avlDifferenceInHeight
  "help function to balance, calculates the difference in height between left
  and right child"
  input AvlTree node;
  output Integer diff;
protected
  Option<AvlTree> l, r;
algorithm
  AVLTREENODE(left = l, right = r) := node;
  diff := avlGetHeight(l) - avlGetHeight(r);
end avlDifferenceInHeight;

protected function avlComputeHeight
  "Compute the height of the AvlTree and store in the node info."
  input AvlTree bt;
  output AvlTree outBt;
protected
  Option<AvlTree> l,r;
  Option<AvlTreeValue> v;
  AvlValue val;
  Integer hl,hr,height;
algorithm
  AVLTREENODE(value = v as SOME(AVLTREEVALUE(value = val)),
    left = l, right = r) := bt;
  hl := avlGetHeight(l);
  hr := avlGetHeight(r);
  height := intMax(hl, hr) + 1;
  outBt := AVLTREENODE(v, height, l, r);
end avlComputeHeight;

protected function avlGetHeight
  "Retrieve the height of a node"
  input Option<AvlTree> bt;
  output Integer height;
algorithm
  height := match(bt)
    case(NONE()) then 0;
    case(SOME(AVLTREENODE(height = height))) then height;
  end match;
end avlGetHeight;

protected function avlPrintTreeStrPP
  input AvlTree inTree;
  output String outString;
algorithm
  outString := avlPrintTreeStrPP2(SOME(inTree), "");
end avlPrintTreeStrPP;

protected function avlPrintTreeStrPP2
  input Option<AvlTree> inTree;
  input String inIndent;
  output String outString;
algorithm
  outString := match(inTree, inIndent)
    local
      AvlKey rkey;
      Option<AvlTree> l, r;
      String s1, s2, res, indent;

    case (NONE(), _) then "";

    case (SOME(AVLTREENODE(value = SOME(AVLTREEVALUE(key = rkey)), left = l, right = r)), _)
      equation
  indent = inIndent +& "  ";
  s1 = avlPrintTreeStrPP2(l, indent);
  s2 = avlPrintTreeStrPP2(r, indent);
  res = "\n" +& inIndent +& rkey +& s1 +& s2;
      then
  res;

    case (SOME(AVLTREENODE(value = NONE(), left = l, right = r)), _)
      equation
  indent = inIndent +& "  ";
  s1 = avlPrintTreeStrPP2(l, indent);
  s2 = avlPrintTreeStrPP2(r, indent);
  res = "\n" +& s1 +& s2;
      then
  res;
  end match;
end avlPrintTreeStrPP2;

end NFEnv;
