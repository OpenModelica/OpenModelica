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

encapsulated package NFEnv
" file:        NFEnv.mo
  package:     NFEnv
  description: Symbol table for lookup


"
public import Absyn;
public import SCode;
public import NFInst;

protected import Debug;
protected import Dump;
protected import Error;
protected import Flags;
protected import List;
protected import Util;

public import Scope = NFInst.Instance;

public uniontype Env
  record ENV
    Integer numScopes;
    array<Scope> scopes;
    ScopeIndex currentScope;
  end ENV;
end Env;

public
type ScopeIndex = Integer;
constant ScopeIndex NO_SCOPE = 0;
constant ScopeIndex BUILTIN_SCOPE = 1;

public function newEnv
  output Env outEnv;
protected
  array<Scope> scopes;
  Scope builtin_scope;
algorithm
  builtin_scope := NFInst.CLASS_INST("<builtin>", {}, 1, NO_SCOPE);
  scopes := MetaModelica.Dangerous.arrayCreateNoInit(1024, builtin_scope);
  arrayUpdate(scopes, 1, builtin_scope);
  outEnv := ENV(1, scopes, BUILTIN_SCOPE);
end newEnv;

public function currentScope
  input Env inEnv;
  output Scope outScope;
protected
  ScopeIndex index;
  array<Scope> scopes;
algorithm
  ENV(scopes = scopes, currentScope = index) := inEnv;
  outScope := arrayGet(scopes, index);
end currentScope;

public function setCurrentScopeIndex
  input ScopeIndex inIndex;
  input Env inEnv;
  output Env outEnv = inEnv;
algorithm
  outEnv := match outEnv
    case ENV()
      algorithm
        outEnv.currentScope := inIndex;
      then
        outEnv;
  end match;
end setCurrentScopeIndex;

public function setCurrentScope
  input Scope inScope;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := setCurrentScopeIndex(scopeIndex(inScope), inEnv);
end setCurrentScope;

public function enclosingScope
  input Env inEnv;
  output Env outEnv = inEnv;
algorithm
  outEnv := match outEnv
    local
      Scope scope;
      ScopeIndex index;

    case ENV()
      algorithm
        scope := arrayGet(outEnv.scopes, outEnv.currentScope);
        outEnv.currentScope := parentScopeIndex(scope);
      then
        outEnv;

  end match;
end enclosingScope;

public function scopeIndex
  input Scope inScope;
  output ScopeIndex outIndex;
algorithm
  NFInst.CLASS_INST(scopeIndex = outIndex) := inScope;
end scopeIndex;

public function parentScopeIndex
  input Scope inScope;
  output ScopeIndex outIndex;
algorithm
  NFInst.CLASS_INST(parentScope = outIndex) := inScope;
end parentScopeIndex;

public function addScope
  input Scope inScope;
  input Env inEnv;
  output Scope outScope = inScope;
  output Env outEnv = inEnv;
algorithm
  (outScope, outEnv) := match(outScope, outEnv)
    case (NFInst.CLASS_INST(), ENV())
      algorithm
        outEnv.numScopes := outEnv.numScopes + 1;
        outScope.scopeIndex := outEnv.numScopes;
        outScope.parentScope := outEnv.currentScope;
        arrayUpdate(outEnv.scopes, outEnv.numScopes, outScope);
        outEnv.currentScope := outScope.scopeIndex;
      then
        (outScope, outEnv);

  end match;
end addScope;

public function updateScope
  input Scope inScope;
  input Env inEnv;
  output Env outEnv = inEnv;
protected
  array<Scope> scopes;
  ScopeIndex index;
algorithm
  NFInst.CLASS_INST(scopeIndex = index) := inScope;
  ENV(scopes = scopes) := inEnv;
  arrayUpdate(scopes, index, inScope);
end updateScope;

public function getScope
  input ScopeIndex inIndex;
  input Env inEnv;
  output Scope outScope;
protected
  array<Scope> scopes;
algorithm
  ENV(scopes = scopes) := inEnv;
  outScope := arrayGet(scopes, inIndex);
end getScope;


//public type EntryOrigin = NFInstTypes.EntryOrigin;
//public type Entry = NFInstTypes.Entry;
//public type ScopeType = NFInstTypes.ScopeType;
//public type Frame = NFInstTypes.Frame;
//public type Env = NFInstTypes.Env;
//public type AvlTree = NFEnvAvlTree.AvlTree;
//public type Modifier = NFInstTypes.Modifier;
//public type Prefix = NFInstPrefix.Prefix;
//
//public constant Env emptyEnv = {};
//public constant Integer tmpTickIndex = 2;
//
//protected function encapsulatedToScopeType
//  input SCode.Encapsulated inEncapsulated;
//  output ScopeType outScopeType;
//algorithm
//  outScopeType := match(inEncapsulated)
//    case SCode.ENCAPSULATED() then NFInstTypes.NORMAL_SCOPE(true);
//    else NFInstTypes.NORMAL_SCOPE(false);
//  end match;
//end encapsulatedToScopeType;
//
//public function openScope
//  input Option<String> inScopeName;
//  input ScopeType inScopeType;
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  outEnv := NFInstTypes.FRAME(inScopeName, NONE(), inScopeType, NFEnvAvlTree.emptyAvlTree) :: inEnv;
//end openScope;
//
//public function openClassScope
//  input String inClassName;
//  input SCode.Encapsulated inEncapsulated;
//  input Env inEnv;
//  output Env outEnv;
//protected
//  ScopeType st;
//algorithm
//  st := encapsulatedToScopeType(inEncapsulated);
//  outEnv := NFInstTypes.FRAME(SOME(inClassName), NONE(), st, NFEnvAvlTree.emptyAvlTree) :: inEnv;
//end openClassScope;
//
//public function exitScope
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  _ :: outEnv := inEnv;
//end exitScope;
//
//public function exitScopes
//  input Env inEnv;
//  input Integer inScopes;
//  output Env outEnv;
//algorithm
//  outEnv := match(inEnv, inScopes)
//    case (_, 0) then inEnv;
//    else exitScopes(exitScope(inEnv), inScopes - 1);
//  end match;
//end exitScopes;
//
//public function topScope
//  input Env inEnv;
//  output Env outEnv;
//protected
//  Frame builtin_frame, top_frame;
//algorithm
//  builtin_frame :: top_frame :: _ := listReverse(inEnv);
//  outEnv := {top_frame, builtin_frame};
//end topScope;
//
//public function builtinScope
//  input Env inEnv;
//  output Env outEnv;
//protected
//  Frame builtin_frame;
//algorithm
//  builtin_frame :: _ := listReverse(inEnv);
//  outEnv := {builtin_frame};
//end builtinScope;
//
//public function isTopScope
//  input Env inEnv;
//  output Boolean outIsTopScope;
//algorithm
//  outIsTopScope := match(inEnv)
//    case NFInstTypes.FRAME(scopeType = NFInstTypes.TOP_SCOPE()) :: _ then true;
//    else false;
//  end match;
//end isTopScope;
//
//public function isBuiltinScope
//  input Env inEnv;
//  output Boolean outIsBuiltinScope;
//algorithm
//  outIsBuiltinScope := match(inEnv)
//    case NFInstTypes.FRAME(scopeType = NFInstTypes.BUILTIN_SCOPE()) :: _ then true;
//    else false;
//  end match;
//end isBuiltinScope;
//
//public function makeInheritedOrigin
//  input SCode.Element inExtends;
//  input Integer inIndex;
//  input Env inEnv;
//  output EntryOrigin outOrigin;
//protected
//  Absyn.Path bc;
//  SourceInfo info;
//algorithm
//  SCode.EXTENDS(baseClassPath = bc, info = info) := inExtends;
//  outOrigin := NFInstTypes.INHERITED_ORIGIN(bc, info, {}, inEnv, inIndex);
//end makeInheritedOrigin;
//
//public function makeImportedOrigin
//  input SCode.Element inImport;
//  input Env inEnv;
//  output EntryOrigin outOrigin;
//protected
//  Absyn.Import imp;
//  SourceInfo info;
//algorithm
//  SCode.IMPORT(imp = imp, info = info) := inImport;
//  outOrigin := NFInstTypes.IMPORTED_ORIGIN(imp, info, inEnv);
//end makeImportedOrigin;
//
//public function makeEntry
//  input SCode.Element inElement;
//  output Entry outEntry;
//protected
//  String name;
//algorithm
//  name := SCode.elementName(inElement);
//  outEntry := NFInstTypes.ENTRY(name, inElement, NFInstTypes.NOMOD(), {});
//end makeEntry;
//
//public function makeEntryWithOrigin
//  input SCode.Element inElement;
//  input list<EntryOrigin> inOrigin;
//  output Entry outEntry;
//protected
//  String name;
//algorithm
//  name := SCode.elementName(inElement);
//  outEntry := NFInstTypes.ENTRY(name, inElement, NFInstTypes.NOMOD(), inOrigin);
//end makeEntryWithOrigin;
//
//public function changeEntryOrigin
//  input Entry inEntry;
//  input list<EntryOrigin> inOrigin;
//  input Env inEnv;
//  output Entry outEntry;
//algorithm
//  outEntry := makeEntryWithOrigin(entryElement(inEntry), inOrigin);
//end changeEntryOrigin;
//
//public function insertEntry
//  input Entry inEntry;
//  input Env inEnv;
//  output Env outEnv;
//protected
//  Option<String> name;
//  Option<Prefix> prefix;
//  ScopeType ty;
//  AvlTree entries;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(name, prefix, ty, entries) :: rest_env := inEnv;
//  entries := NFEnvAvlTree.add(entries, entryName(inEntry), inEntry, mergeEntry);
//  outEnv := NFInstTypes.FRAME(name, prefix, ty, entries) :: rest_env;
//end insertEntry;
//
//protected function mergeEntry
//  "Update function used by insertEntry to resolve conflicts when trying to add
//   an entry which already exists."
//  input Entry inOldEntry;
//  input Entry inNewEntry;
//  output Entry outEntry;
//algorithm
//  outEntry := matchcontinue(inOldEntry, inNewEntry)
//    local
//      String name;
//      SCode.Element old_element, new_element, element;
//      Modifier old_mod, new_mod;
//      list<EntryOrigin> old_origins, new_origins, origins;
//      EntryOrigin origin;
//
//    // Merge the origins to make sure that it's a valid insertion.
//    // Then update the old entry with the new origins.
//    case (NFInstTypes.ENTRY(name, old_element, old_mod, old_origins),
//        NFInstTypes.ENTRY(element = new_element, origins = new_origins))
//      equation
//        // New entries should only have one origin.
//        origin = getSingleOriginFromList(new_origins);
//        element = checkOrigin(origin, old_origins, old_element, new_element);
//        origins = mergeOrigin(origin, old_origins);
//      then
//        NFInstTypes.ENTRY(name, element, old_mod, origins);
//
//    case (NFInstTypes.ENTRY(name = name), _)
//      equation
//        true = Flags.isSet(Flags.FAILTRACE);
//        Debug.traceln("- NFEnv.mergeEntry failed on entry " + name);
//      then
//        fail();
//
//  end matchcontinue;
//end mergeEntry;
//
//protected function getSingleOriginFromList
//  input list<EntryOrigin> inOrigins;
//  output EntryOrigin outOrigin;
//algorithm
//  outOrigin := match(inOrigins)
//    local
//      EntryOrigin origin;
//
//    case {} then NFInstTypes.LOCAL_ORIGIN();
//    case {origin} then origin;
//
//  end match;
//end getSingleOriginFromList;
//
//protected function mergeOrigin
//  "Adds a new origin to a list of origins."
//  input EntryOrigin inNewOrigin;
//  input list<EntryOrigin> inOldOrigins;
//  output list<EntryOrigin> outOrigins;
//algorithm
//  outOrigins := matchcontinue(inNewOrigin, inOldOrigins)
//    local
//      list<EntryOrigin> rest_origins;
//
//    // The new origin is inherited, try to merge it with an existing origin.
//    case (NFInstTypes.INHERITED_ORIGIN(), _)
//      then mergeInheritedOrigin(inNewOrigin, inOldOrigins);
//
//    // The first origin is local. Keep it at the head of the list, so that we
//    // can quickly determine if an entry is local or not.
//    case (_, NFInstTypes.LOCAL_ORIGIN() :: rest_origins)
//      then NFInstTypes.LOCAL_ORIGIN() :: inNewOrigin :: rest_origins;
//
//    // Otherwise, just add the new origin to the head of the list.
//    else inNewOrigin :: inOldOrigins;
//
//  end matchcontinue;
//end mergeOrigin;
//
//protected function mergeInheritedOrigin
//  "This function handles the case when an element has multiple origins from the
//   same base class, i.e. when an element is inherited from multiple sources in a
//   base class. For example:
//
//     class A      class B     class C          class D
//       Real x;      Real x;     extends A;       extends C;
//     end A;       end B;        extends B;     end D;
//                              end C;
//
//   In this example we get two origins for x inherited from C:
//     INHERITED_ORIGIN(baseClass = C, origin = INHERITED_ORIGIN(baseClass = A))
//     INHERITED_ORIGIN(baseClass = C, origin = INHERITED_ORIGIN(baseClass = B))
//
//   This function searches for an existing origin with the same base class as the
//   new origin, and if found it merges them. In the example above we'd then get:
//     INHERITED_ORIGIN(baseClass = C, origin = {INHERITED_ORIGIN(baseClass = A),
//                                               INHERITED_ORIGIN(baseClass = B))
//
//   If no matching origin can be found the function fails."
//  input EntryOrigin inNewOrigin;
//  input list<EntryOrigin> inOldOrigins;
//  output list<EntryOrigin> outOrigins;
//algorithm
//  outOrigins := matchcontinue(inNewOrigin, inOldOrigins)
//    local
//      Absyn.Path bc1, bc2;
//      list<EntryOrigin> origin1, origin2, rest_origins;
//      SourceInfo info;
//      EntryOrigin origin;
//      Env env;
//      Integer idx;
//
//    // Found two origins with the same base class, merge their origins.
//    case (NFInstTypes.INHERITED_ORIGIN(baseClass = bc1, origin = origin1),
//        NFInstTypes.INHERITED_ORIGIN(bc2, info, origin2, env, idx) :: rest_origins)
//      equation
//        true = Absyn.pathEqual(bc1, bc2);
//        origin2 = List.fold(origin1, mergeOrigin, origin2);
//      then
//        NFInstTypes.INHERITED_ORIGIN(bc2, info, origin2, env, idx) :: rest_origins;
//
//    // No match, search the rest.
//    case (_, origin :: rest_origins)
//      equation
//        rest_origins = mergeInheritedOrigin(inNewOrigin, rest_origins);
//      then
//        origin :: rest_origins;
//
//  end matchcontinue;
//end mergeInheritedOrigin;
//
//protected function checkOrigin
//  "Checks that it's possible to merge a new origin with a list of existing
//   origins for an entry. Also determines whether we should keep the old or the
//   new element. Assumes that elements are added in the order local -> imported
//   -> inherited."
//  input EntryOrigin inNewOrigin;
//  input list<EntryOrigin> inOldOrigins;
//  input SCode.Element inOldElement;
//  input SCode.Element inNewElement;
//  output SCode.Element outElement;
//algorithm
//  outElement := match(inNewOrigin, inOldOrigins, inOldElement, inNewElement)
//    local
//      String name, err_msg;
//      EntryOrigin origin;
//
//    // Elements imported with unqualified imports can be shadowed by other
//    // elements, and they have the lowest priority of all entry types. The
//    // shadowing might be on purpose though, since an unqualified import can
//    // import elements the user isn't interested in, so we don't print a warning
//    // for this. It's also illegal to find a name in multiple unqualified
//    // imports, but that's only an error if we actually try to look the name up
//    // so we can't print an error for that here.
//
//    // The new element was imported from an unqualified import, keep the old.
//    case (NFInstTypes.IMPORTED_ORIGIN(imp = Absyn.UNQUAL_IMPORT()), _, _, _)
//      then inOldElement;
//
//    // The old element was imported from an unqualified import, replace with the new.
//    case (_, NFInstTypes.IMPORTED_ORIGIN(imp = Absyn.UNQUAL_IMPORT()) :: _, _, _)
//      then inNewElement;
//
//    // The new element is imported by a named or qualified import, which means
//    // that we either have conflicting imports or that the imported element is
//    // shadowed by a local/inherited element.
//    case (NFInstTypes.IMPORTED_ORIGIN(), _, _, _)
//      equation
//        // Check if we have conflicting imports.
//        List.map1_0(inOldOrigins, checkOriginImportConflict, inNewOrigin);
//
//        // If we reached here there was no conflict, but the imported entry
//        // will be shadowed by the old entry. This makes the import useless, so
//        // we print a warning but keep the old entry and continue.
//        printImportShadowWarning(inNewOrigin, inOldElement);
//      then
//        inOldElement;
//
//    // If the old element was imported, then it will be shadowed by the new
//    // element. Note that if the old element would have had more than one
//    // origin, then we would already have printed a warning in the case above
//    // when it was added.
//    case (_, {origin as NFInstTypes.IMPORTED_ORIGIN()}, _, _)
//      equation
//        printImportShadowWarning(origin, inNewElement);
//      then
//        inNewElement;
//
//    // The new element was inherited, check that it's identical to the existing
//    // element. Keep the old one in that case, so that e.g. error messages favor
//    // the local elements.
//    case (NFInstTypes.INHERITED_ORIGIN(), _, _, _)
//      equation
//        /*********************************************************************/
//        // TODO: Check duplicate elements due to inheritance here.
//        //       Or perhaps we shouldn't check this here, but in NFInstFlatten
//        //       instead so we get the qualified name of the class.
//        /*********************************************************************/
//      then
//        inOldElement;
//
//    // The new element is a local element. Since local elements are added first
//    // this means that we have duplicate elements in the scope. This is not
//    // allowed, so print an error and fail.
//    case (NFInstTypes.LOCAL_ORIGIN(), _, _, _)
//      equation
//        printDoubleDeclarationError(inOldElement, inNewElement);
//      then
//        fail();
//
//    // Same as case above, but with builtin elements.
//    case (NFInstTypes.BUILTIN_ORIGIN(), _, _, _)
//      equation
//        printDoubleDeclarationError(inOldElement, inNewElement);
//      then
//        fail();
//
//    // Other cases shouldn't occur.
//    else
//      equation
//        _ = SCode.elementName(inNewElement);
//        err_msg = "NFEnv.checkOrigin failed on unhandled origin!";
//        Error.addMessage(Error.INTERNAL_ERROR, {err_msg});
//      then
//        fail();
//
//  end match;
//end checkOrigin;
//
//protected function checkOriginImportConflict
//  "Helper function to checkOrigin. Print an error message if the two given
//   origins are both imports, since multiple named/qualified imports may not
//   have the same import name."
//  input EntryOrigin inOldOrigin;
//  input EntryOrigin inNewOrigin;
//algorithm
//  _ := match(inOldOrigin, inNewOrigin)
//    local
//      Absyn.Import imp;
//      String name;
//      SourceInfo info1, info2;
//
//    case (NFInstTypes.IMPORTED_ORIGIN(imp = imp, info = info1), NFInstTypes.IMPORTED_ORIGIN(info = info2))
//      equation
//        name = Absyn.importName(imp);
//        Error.addMultiSourceMessage(Error.MULTIPLE_QUALIFIED_IMPORTS_WITH_SAME_NAME,
//          {name}, {info2, info1});
//      then
//        fail();
//
//    else ();
//  end match;
//end checkOriginImportConflict;
//
//protected function printImportShadowWarning
//  "Prints a warning that an import was shadowed by a local/inherited element.
//   This is allowed, but since it makes the import useless it's almost certainly a
//   user mistake."
//  input EntryOrigin inImportOrigin;
//  input SCode.Element inShadowElement;
//protected
//  Absyn.Import imp;
//  SourceInfo info1, info2;
//  String import_str;
//algorithm
//  info1 := SCode.elementInfo(inShadowElement);
//  NFInstTypes.IMPORTED_ORIGIN(imp = imp, info = info2) := inImportOrigin;
//  import_str := Dump.unparseImportStr(imp);
//  Error.addMultiSourceMessage(Error.LOOKUP_SHADOWING,
//    {import_str}, {info1, info2});
//end printImportShadowWarning;
//
//protected function printDoubleDeclarationError
//  input SCode.Element inOldElement;
//  input SCode.Element inNewElement;
//protected
//  SourceInfo info1, info2;
//  String name;
//algorithm
//  (name, info1) := SCode.elementNameInfo(inNewElement);
//  info2 := SCode.elementInfo(inOldElement);
//  Error.addMultiSourceMessage(Error.DOUBLE_DECLARATION_OF_ELEMENTS,
//    {name}, {info2, info1});
//end printDoubleDeclarationError;
//
//public function collapseInheritedOrigins
//  "Collapses a list of INHERITED_ORIGIN into a list of one nested
//   INHERITED_ORIGIN. This is used when an element is inherited from several
//   levels of extends, e.g. A extends B, B extends C, C extends D. For an element
//   inherited from D we then get a list of origins {D, C, B}, which in this
//   function is turned into {B(C(D))}."
//  input list<EntryOrigin> inOrigins;
//  output list<EntryOrigin> outOrigins;
//algorithm
//  outOrigins := match(inOrigins)
//    local
//      EntryOrigin origin;
//      list<EntryOrigin> rest_origins;
//
//    // One or more origins, collapse with fold.
//    case (origin :: rest_origins)
//      equation
//        origin = List.fold(rest_origins, collapseInheritedOrigins2, origin);
//      then
//        {origin};
//
//    // Already collapsed.
//    else inOrigins;
//
//  end match;
//end collapseInheritedOrigins;
//
//protected function collapseInheritedOrigins2
//  input EntryOrigin inOrigin1;
//  input EntryOrigin inOrigin2;
//  output EntryOrigin outOrigin;
//protected
//  Absyn.Path bc;
//  SourceInfo info;
//  list<EntryOrigin> origins;
//  Env env;
//  Integer idx;
//algorithm
//  NFInstTypes.INHERITED_ORIGIN(bc, info, origins, env, idx) := inOrigin1;
//  origins := inOrigin2 :: origins;
//  outOrigin := NFInstTypes.INHERITED_ORIGIN(bc, info, origins, env, idx);
//end collapseInheritedOrigins2;
//
//public function insertElement
//  input SCode.Element inElement;
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  outEnv := insertEntry(makeEntry(inElement), inEnv);
//end insertElement;
//
//public function insertElementWithOrigin
//  input SCode.Element inElement;
//  input list<EntryOrigin> inOrigin;
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  outEnv := insertEntry(makeEntryWithOrigin(inElement, inOrigin), inEnv);
//end insertElementWithOrigin;
//
//public function replaceElement
//  input SCode.Element inReplacement;
//  input Env inOriginEnv;
//  input Env inEnv;
//  output Env outEnv;
//  output Boolean outWasReplaced;
//protected
//  Entry entry;
//algorithm
//  entry := makeEntry(inReplacement);
//  (outEnv, outWasReplaced) := replaceEntry(entry, inOriginEnv, inEnv);
//end replaceElement;
//
//public function replaceEntry
//  input Entry inReplacement;
//  input Env inOriginEnv;
//  input Env inEnv;
//  output Env outEnv;
//  output Boolean outWasReplaced;
//protected
//  Option<String> name;
//  Option<Prefix> prefix;
//  ScopeType ty;
//  AvlTree entries;
//  Env rest_env;
//  String entry_name;
//  Option<Entry> uentry;
//algorithm
//  NFInstTypes.FRAME(name, prefix, ty, entries) :: rest_env := inEnv;
//  entry_name := entryName(inReplacement);
//  (entries, uentry) :=
//    NFEnvAvlTree.update(entries, entry_name, replaceEntry2, (inReplacement, inOriginEnv));
//  outEnv := NFInstTypes.FRAME(name, prefix, ty, entries) :: rest_env;
//  outWasReplaced := isSome(uentry);
//end replaceEntry;
//
//protected function replaceEntry2
//  input Entry inOldEntry;
//  input tuple<Entry, Env> inNewEntry;
//  output Entry outEntry;
//protected
//  EntryOrigin origin;
//  Entry entry;
//  Env env;
//algorithm
//  (entry, env) := inNewEntry;
//  origin := NFInstTypes.REDECLARED_ORIGIN(inOldEntry, env);
//  outEntry := setEntryOrigin(entry, {origin});
//end replaceEntry2;
//
//public function updateEntry
//  input String inName;
//  input ArgType inArg;
//  input UpdateFunc inUpdateFunc;
//  input Env inEnv;
//  output Env outEnv;
//  output Option<Entry> outUpdatedEntry;
//
//  partial function UpdateFunc
//    input Entry inEntry;
//    input ArgType inArg;
//    output Entry outEntry;
//  end UpdateFunc;
//
//  replaceable type ArgType subtypeof Any;
//protected
//  Option<String> name;
//  Option<Prefix> prefix;
//  ScopeType st;
//  AvlTree entries;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(name, prefix, st, entries) :: rest_env := inEnv;
//  (entries, outUpdatedEntry) :=
//    NFEnvAvlTree.update(entries, inName, inUpdateFunc, inArg);
//  outEnv := NFInstTypes.FRAME(name, prefix, st, entries) :: rest_env;
//end updateEntry;
//
//public function mapScope
//  "Maps over all entries in the current scope."
//  input Env inEnv;
//  input MapFunc inMapFunc;
//  output Env outEnv;
//
//  partial function MapFunc
//    input Entry inEntry;
//    output Entry outEntry;
//  end MapFunc;
//protected
//  Option<String> name;
//  Option<Prefix> prefix;
//  ScopeType st;
//  AvlTree entries;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(name, prefix, st, entries) :: rest_env := inEnv;
//  entries := NFEnvAvlTree.map(entries, inMapFunc);
//  outEnv := NFInstTypes.FRAME(name, prefix, st, entries) :: rest_env;
//end mapScope;
//
//public function foldScope
//  "Folds over the entries in the current scope."
//  input Env inEnv;
//  input FoldFunc inFoldFunc;
//  input FoldArg inFoldArg;
//  output FoldArg outFoldArg;
//
//  partial function FoldFunc
//    input Entry inEntry;
//    input FoldArg inFoldArg;
//    output FoldArg outFoldArg;
//  end FoldFunc;
//
//  replaceable type FoldArg subtypeof Any;
//protected
//  AvlTree entries;
//algorithm
//  NFInstTypes.FRAME(entries = entries) :: _ := inEnv;
//  outFoldArg := NFEnvAvlTree.fold(entries, inFoldFunc, inFoldArg);
//end foldScope;
//
//public function insertIterators
//  "Opens up a new implicit scope in the environment and adds the given
//   iterators."
//  input Absyn.ForIterators inIterators;
//  input Integer inIterIndex;
//  input Env inEnv;
//  output Env outEnv;
//protected
//  AvlTree tree;
//  Frame frame;
//algorithm
//  tree := List.fold(inIterators, insertIterator, NFEnvAvlTree.emptyAvlTree);
//  frame := NFInstTypes.FRAME(SOME("$for$"), NONE(), NFInstTypes.IMPLICIT_SCOPE(inIterIndex), tree);
//  outEnv := frame :: inEnv;
//end insertIterators;
//
//protected function insertIterator
//  input Absyn.ForIterator inIterator;
//  input AvlTree inTree;
//  output AvlTree outTree;
//protected
//  Absyn.Ident iter_name;
//  SCode.Element iter;
//algorithm
//  Absyn.ITERATOR(name = iter_name) := inIterator;
//  iter := SCode.COMPONENT(iter_name, SCode.defaultPrefixes,
//    SCode.ATTR({}, SCode.POTENTIAL(), SCode.NON_PARALLEL(), SCode.CONST(), Absyn.BIDIR()),
//    Absyn.TPATH(Absyn.IDENT(""), NONE()), SCode.NOMOD(),
//    SCode.noComment, NONE(), Absyn.dummyInfo);
//  outTree := NFEnvAvlTree.addUnique(inTree, iter_name, makeEntry(iter));
//end insertIterator;
//
//public function lookupEntry
//  input String inName;
//  input Env inEnv;
//  output Entry outEntry;
//protected
//  AvlTree entries;
//algorithm
//  NFInstTypes.FRAME(entries = entries) :: _ := inEnv;
//  outEntry := NFEnvAvlTree.get(entries, inName);
//end lookupEntry;
//
//public function resolveEntry
//  input Entry inEntry;
//  input Env inEnv;
//  output Entry outEntry;
//  output Env outEnv;
//algorithm
//  (outEntry, outEnv) := match(inEntry, inEnv)
//    local
//      Entry entry;
//      Env env;
//      EntryOrigin origin;
//
//    // Local entry => nothing to resolve.
//    case (NFInstTypes.ENTRY(origins = {}), _) then (inEntry, inEnv);
//    case (NFInstTypes.ENTRY(origins = NFInstTypes.LOCAL_ORIGIN() :: _), _) then (inEntry, inEnv);
//    case (NFInstTypes.ENTRY(origins = NFInstTypes.BUILTIN_ORIGIN() :: _), _) then (inEntry, inEnv);
//
//    // Some origins => choose the first.
//    case (NFInstTypes.ENTRY(origins = origin :: _), _)
//      equation
//        env = originEnv(origin);
//      then
//        (inEntry, env);
//
//  end match;
//end resolveEntry;
//
//protected function originEnv
//  input EntryOrigin inOrigin;
//  output Env outEnv;
//algorithm
//  outEnv := match(inOrigin)
//    local
//      Env env;
//
//    case NFInstTypes.INHERITED_ORIGIN(originEnv = env) then env;
//    case NFInstTypes.REDECLARED_ORIGIN(originEnv = env) then env;
//    case NFInstTypes.IMPORTED_ORIGIN(originEnv = env) then env;
//
//  end match;
//end originEnv;
//
//protected function setEntryOrigin
//  input Entry inEntry;
//  input list<EntryOrigin> inOrigin;
//  output Entry outEntry;
//protected
//  String name;
//  SCode.Element element;
//  Modifier mod;
//algorithm
//  NFInstTypes.ENTRY(name, element, mod, _) := inEntry;
//  outEntry := NFInstTypes.ENTRY(name, element, mod, inOrigin);
//end setEntryOrigin;
//
//public function isScopeEncapsulated
//  input Env inEnv;
//  output Boolean outIsEncapsulated;
//algorithm
//  outIsEncapsulated := match(inEnv)
//    case NFInstTypes.FRAME(scopeType = NFInstTypes.NORMAL_SCOPE(true)) :: _ then true;
//    else false;
//  end match;
//end isScopeEncapsulated;
//
//public function getImplicitScopeIndex
//  "Returns the index of the implicit scope, or fails if the current scope is
//   explicit."
//  input Env inEnv;
//  output Integer outIndex;
//algorithm
//  NFInstTypes.FRAME(scopeType = NFInstTypes.IMPLICIT_SCOPE(iterIndex = outIndex)) :: _ := inEnv;
//end getImplicitScopeIndex;
//
//public function entryHasBuiltinOrigin
//  input Entry inEntry;
//  output Boolean outBuiltin;
//algorithm
//  outBuiltin := match(inEntry)
//    case NFInstTypes.ENTRY(origins = {NFInstTypes.BUILTIN_ORIGIN()}) then true;
//    else false;
//  end match;
//end entryHasBuiltinOrigin;
//
//public function entryName
//  input Entry inEntry;
//  output String outName;
//algorithm
//  NFInstTypes.ENTRY(name = outName) := inEntry;
//end entryName;
//
//public function renameEntry
//  input Entry inEntry;
//  input String inName;
//  output Entry outEntry;
//protected
//  SCode.Element element;
//  Modifier mod;
//  list<EntryOrigin> origins;
//algorithm
//  NFInstTypes.ENTRY(_, element, mod, origins) := inEntry;
//  outEntry := NFInstTypes.ENTRY(inName, element, mod, origins);
//end renameEntry;
//
//public function entryElement
//  input Entry inEntry;
//  output SCode.Element outElement;
//algorithm
//  NFInstTypes.ENTRY(element = outElement) := inEntry;
//end entryElement;
//
//public function entryOrigins
//  input Entry inEntry;
//  output list<EntryOrigin> outOrigins;
//algorithm
//  NFInstTypes.ENTRY(origins = outOrigins) := inEntry;
//end entryOrigins;
//
//public function setEntryModifier
//  input Entry inEntry;
//  input Modifier inModifier;
//  output Entry outEntry;
//protected
//  String name;
//  SCode.Element element;
//  list<EntryOrigin> origins;
//algorithm
//  NFInstTypes.ENTRY(name, element, _, origins) := inEntry;
//  outEntry := NFInstTypes.ENTRY(name, element, inModifier, origins);
//end setEntryModifier;
//
//public function entryModifier
//  input Entry inEntry;
//  output Modifier outMod;
//algorithm
//  NFInstTypes.ENTRY(mod = outMod) := inEntry;
//end entryModifier;
//
//public function isClassEntry
//  input Entry inEntry;
//  output Boolean outIsClass;
//algorithm
//  outIsClass := match(inEntry)
//    case NFInstTypes.ENTRY(element = SCode.CLASS()) then true;
//    else false;
//  end match;
//end isClassEntry;
//
//public function scopeName
//  input Env inEnv;
//  output String outName;
//algorithm
//  NFInstTypes.FRAME(name = SOME(outName)) :: _ := inEnv;
//end scopeName;
//
//public function scopeNames
//  input Env inEnv;
//  output list<String> outNames;
//algorithm
//  outNames := scopeNames2(inEnv, {});
//end scopeNames;
//
//protected function scopeNames2
//  input Env inEnv;
//  input list<String> inAccumNames;
//  output list<String> outNames;
//algorithm
//  outNames := match(inEnv, inAccumNames)
//    local
//      String name;
//      Env env;
//
//    case (NFInstTypes.FRAME(name = SOME(name),
//        scopeType = NFInstTypes.NORMAL_SCOPE()) :: env, _)
//      then scopeNames2(env, name :: inAccumNames);
//
//    case (_ :: env, _) then scopeNames2(env, inAccumNames);
//    case ({}, _) then inAccumNames;
//
//  end match;
//end scopeNames2;
//
//public function stripImplicitScopes
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  outEnv := match(inEnv)
//    local
//      Env rest_env;
//
//    case NFInstTypes.FRAME(scopeType = NFInstTypes.IMPLICIT_SCOPE()) :: rest_env
//      then stripImplicitScopes(rest_env);
//
//    else inEnv;
//  end match;
//end stripImplicitScopes;
//
//public function envPath
//  input Env inEnv;
//  output Absyn.Path outPath;
//protected
//  String name;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(name = SOME(name)) :: rest_env := stripImplicitScopes(inEnv);
//  outPath := envPath2(rest_env, Absyn.IDENT(name));
//end envPath;
//
//protected function envPath2
//  input Env inEnv;
//  input Absyn.Path inAccumPath;
//  output Absyn.Path outPath;
//algorithm
//  outPath := match(inEnv, inAccumPath)
//    local
//      String name;
//      Absyn.Path path;
//      Env env;
//
//    case (NFInstTypes.FRAME(name = SOME(name),
//        scopeType = NFInstTypes.NORMAL_SCOPE()) :: env, _)
//      then envPath2(env, Absyn.QUALIFIED(name, inAccumPath));
//
//    case (NFInstTypes.FRAME(scopeType = NFInstTypes.IMPLICIT_SCOPE()) :: env, _)
//      then envPath2(env, inAccumPath);
//
//    else inAccumPath;
//
//  end match;
//end envPath2;
//
//public function envPrefix
//  "Converts the scope names of the environment to a Prefix."
//  input Env inEnv;
//  output Prefix outPrefix;
//protected
//  list<String> scopes;
//algorithm
//  scopes := scopeNames(inEnv);
//  outPrefix := NFInstPrefix.fromStringList(scopes);
//end envPrefix;
//
//public function prefixIdentWithEnv
//  input String inIdent;
//  input Env inEnv;
//  output Absyn.Path outPath;
//protected
//  list<String> strl;
//algorithm
//  strl := listReverse(scopeNames(inEnv));
//  strl := inIdent :: strl;
//  outPath := Absyn.stringListPathReversed(strl);
//end prefixIdentWithEnv;
//
//public function isEqual
//  "Checks if two environments are equal, with regards to the scope names."
//  input Env inEnv1;
//  input Env inEnv2;
//  output Boolean outIsEqual;
//algorithm
//  outIsEqual := List.isEqualOnTrue(inEnv1, inEnv2, isFrameEqual);
//end isEqual;
//
//protected function isFrameEqual
//  input Frame inFrame1;
//  input Frame inFrame2;
//  output Boolean outIsEqual;
//algorithm
//  outIsEqual := match(inFrame1, inFrame2)
//    local
//      String n1, n2;
//      ScopeType st1, st2;
//
//    case (NFInstTypes.FRAME(name = SOME(n1)),
//          NFInstTypes.FRAME(name = SOME(n2)))
//      then stringEq(n1, n2);
//
//    case (NFInstTypes.FRAME(name = NONE(), scopeType = st1),
//          NFInstTypes.FRAME(name = NONE(), scopeType = st2))
//      then scopeTypeEqual(st1, st2);
//
//    else false;
//  end match;
//end isFrameEqual;
//
//protected function scopeTypeEqual
//  input ScopeType inScopeType1;
//  input ScopeType inScopeType2;
//  output Boolean outIsEqual;
//algorithm
//  outIsEqual := valueEq(inScopeType1, inScopeType2);
//end scopeTypeEqual;
//
//public function isPrefix
//  "Checks if one environment is a prefix of another."
//  input Env inPrefixEnv;
//  input Env inEnv;
//  output Boolean outIsPrefix;
//protected
//  Integer sc1, sc2, sc_diff;
//algorithm
//  sc1 := listLength(inPrefixEnv);
//  sc2 := listLength(inEnv);
//  sc_diff := sc2 - sc1;
//  outIsPrefix := isPrefix2(inPrefixEnv, inEnv, sc_diff);
//end isPrefix;
//
//protected function isPrefix2
//  input Env inPrefixEnv;
//  input Env inEnv;
//  input Integer inScopeDiff;
//  output Boolean outIsPrefix;
//algorithm
//  outIsPrefix := matchcontinue(inPrefixEnv, inEnv, inScopeDiff)
//    local
//      Env rest;
//
//    case (_, _, _)
//      equation
//        true = inScopeDiff >= 0;
//        rest = exitScopes(inEnv, inScopeDiff);
//      then
//        isEqual(inPrefixEnv, rest);
//
//    else false;
//  end matchcontinue;
//end isPrefix2;
//
//public function printEnvPathStr
//  input Env inEnv;
//  output String outString;
//protected
//  list<String> scopes;
//algorithm
//  scopes := scopeNames(inEnv);
//  outString := stringDelimitList(scopes, ".");
//end printEnvPathStr;
//
//public function scopePrefixOpt
//  input Env inEnv;
//  output Option<Prefix> outPrefix;
//protected
//  Env env;
//algorithm
//  env := stripImplicitScopes(inEnv);
//  NFInstTypes.FRAME(prefix = outPrefix) :: _ := inEnv;
//end scopePrefixOpt;
//
//public function scopePrefix
//  input Env inEnv;
//  output Prefix outPrefix;
//protected
//  Option<Prefix> prefix;
//algorithm
//  prefix := scopePrefixOpt(inEnv);
//  outPrefix := Util.getOptionOrDefault(prefix, NFInstPrefix.emptyPrefix);
//end scopePrefix;
//
//public function setScopePrefix
//  input Prefix inPrefix;
//  input Env inEnv;
//  output Env outEnv;
//algorithm
//  outEnv := setScopePrefixOpt(SOME(inPrefix), inEnv);
//end setScopePrefix;
//
//public function setScopePrefixOpt
//  input Option<Prefix> inPrefix;
//  input Env inEnv;
//  output Env outEnv;
//protected
//  Option<String> name;
//  ScopeType st;
//  AvlTree entries;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(name, _, st, entries) :: rest_env := inEnv;
//  outEnv := NFInstTypes.FRAME(name, inPrefix, st, entries) :: rest_env;
//end setScopePrefixOpt;
//
//public function copyScopePrefix
//  input Env inSrc;
//  input Env inDest;
//  output Env outDest;
//protected
//  Option<String> name;
//  Option<Prefix> prefix;
//  ScopeType st;
//  AvlTree entries;
//  Env rest_env;
//algorithm
//  NFInstTypes.FRAME(prefix = prefix) :: _ := inSrc;
//  NFInstTypes.FRAME(name, _, st, entries) :: rest_env := inDest;
//  outDest := NFInstTypes.FRAME(name, prefix, st, entries) :: rest_env;
//end copyScopePrefix;
//
//public function buildInitialEnv
//  input SCode.Program inProgram;
//  input SCode.Program inBuiltin;
//  output Env outEnv;
//protected
//  Env env;
//  SCode.Program prog, builtin;
//algorithm
//  env := openScope(NONE(), NFInstTypes.BUILTIN_SCOPE(), emptyEnv);
//  env := List.fold1(inBuiltin, insertElementWithOrigin, {NFInstTypes.BUILTIN_ORIGIN()}, env);
//  env := openScope(NONE(), NFInstTypes.TOP_SCOPE(), env);
//  outEnv := List.fold(inProgram, insertElement, env);
//end buildInitialEnv;

annotation(__OpenModelica_Interface="frontend");
end NFEnv;
