 /*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package NFConnectBreakTree
  "A tree structure for handling `break connect` modifiers."
  import AbsynUtil;
  import BaseAvlTree;
  import UnorderedMap;
  import NFInstNode.InstNode;

protected
  import Dump;
  import Lookup = NFLookup;
  import Mutable;

public
  uniontype Entry
    record ENTRY
      Boolean hasMatch;
      SCode.Mod mod;
    end ENTRY;
  end Entry;

  encapsulated package EntryTree
    import BaseAvlTree;
    import NFConnectBreakTree.Entry;

    extends BaseAvlTree(redeclare type Key = Absyn.ComponentRef,
                        redeclare type Value = Mutable<Entry>);

    redeclare function extends keyStr
    algorithm
      outString := Dump.printComponentRefStr(inKey);
    end keyStr;

    redeclare function extends valueStr
    algorithm
      outString := "";
    end valueStr;

    redeclare function extends keyCompare
    algorithm
      outResult := AbsynUtil.crefCompare(inKey1, inKey2);
    end keyCompare;
  end EntryTree;

  type EntryTable = UnorderedMap<String, Entry>;

  extends BaseAvlTree(redeclare type Key = Absyn.ComponentRef,
                      redeclare type Value = EntryTree.Tree);

  redeclare function extends keyStr
  algorithm
    outString := Dump.printComponentRefStr(inKey);
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := AbsynUtil.crefCompare(inKey1, inKey2);
  end keyCompare;

  function appendBreaksInNode
    "Appends any `break connect` modifiers from the node to the given tree, and
     returns the new entries as a list that can be passed to
     checkUnmatchedBreaks once the connects have been processed."
    input InstNode node;
    input output Tree tree;
          output list<Mutable<Entry>> newEntries = {};
  protected
    SCode.Mod mod, break_mod;
    Mutable<Entry> entry;

    function add_entry
      input Absyn.ComponentRef name;
      input Mutable<Entry> entry;
      input Option<EntryTree.Tree> oldTree;
      output EntryTree.Tree outTree;
    algorithm
      if isSome(oldTree) then
        SOME(outTree) := oldTree;
      else
        outTree := EntryTree.new();
      end if;

      outTree := EntryTree.update(outTree, name, entry);
    end add_entry;
  algorithm
    () := match InstNode.extendsDefinition(node)
      case SOME(SCode.Element.EXTENDS(modifications = mod as SCode.Mod.MOD()))
        algorithm
          for sm in mod.subModLst loop
            () := match sm
              case SCode.NAMEMOD(mod = break_mod as SCode.Mod.BREAK_CONNECT())
                algorithm
                  entry := Mutable.create(Entry.ENTRY(false, break_mod));
                  newEntries := entry :: newEntries;

                  // Add both rhs->lhs and lhs->rhs to reduce the amount of lookup needed,
                  // since there's presumably a lot more connects than breaks.
                  tree := addUpdate(tree, break_mod.rhs, function add_entry(name = break_mod.lhs, entry = entry));
                  tree := addUpdate(tree, break_mod.lhs, function add_entry(name = break_mod.rhs, entry = entry));
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      else ();
    end match;
  end appendBreaksInNode;

  function isConnectBroken
    "Checks if there's a matching `break connect` modifier for the given connectors,
     and updates the entry in the tree if there is."
    input Absyn.ComponentRef lhs;
    input Absyn.ComponentRef rhs;
    input InstNode scope;
    input Tree connectBreaks;
    output Boolean isBroken = false;
  protected
    Option<EntryTree.Tree> opt_entry_tree;
    Option<Mutable<Entry>> opt_entry_ptr;
    Mutable<Entry> entry_ptr;
    Entry entry;

    function is_broken
      input Absyn.ComponentRef cref;
      input InstNode scope;
      output Boolean isBroken;
    algorithm
      try
        isBroken := InstNode.isEmpty(Lookup.lookupLocalSimpleName(AbsynUtil.crefFirstIdent(cref), scope));
      else
        isBroken := false;
      end try;
    end is_broken;
  algorithm
    opt_entry_tree := getOpt(connectBreaks, lhs);

    if isSome(opt_entry_tree) then
      opt_entry_ptr := EntryTree.getOpt(Util.getOption(opt_entry_tree), rhs);

      // Mark the entry as having a match if an entry was found, and neither connector has been
      // deselected by a component break. Connections associated with deselected connectors should
      // be removed first, but we do it after this, so just ignore them here.
      if isSome(opt_entry_ptr) and not is_broken(lhs, scope) and not is_broken(rhs, scope) then
        SOME(entry_ptr) := opt_entry_ptr;
        entry := Mutable.access(entry_ptr);
        entry.hasMatch := true;
        Mutable.update(entry_ptr, entry);
        isBroken := true;
      end if;
    end if;
  end isConnectBroken;

  function checkUnmatchedBreaks
    "Prints an error message and fails if any entry in the list hasn't been
     marked as having a matching connect."
    input list<Mutable<Entry>> entries;
  protected
    Entry entry;
    Absyn.ComponentRef lhs, rhs;
    SourceInfo info;
  algorithm
    for e in entries loop
      entry := Mutable.access(e);

      if not entry.hasMatch then
        SCode.Mod.BREAK_CONNECT(lhs = lhs, rhs = rhs, info = info) := entry.mod;
        Error.addSourceMessage(Error.UNMATCHED_BREAK_CONNECT,
          {Dump.printComponentRefStr(lhs), Dump.printComponentRefStr(rhs)}, info);
        fail();
      end if;
    end for;
  end checkUnmatchedBreaks;

  annotation(__OpenModelica_Interface="frontend");
end NFConnectBreakTree;
