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

encapsulated package NFDuplicateTree

type EntryType = enumeration(DUPLICATE, REDECLARE, ENTRY);

public
  import NFLookupTree;
  import NFInstNode;
  import List;

 uniontype Entry
    record ENTRY
      NFLookupTree.Entry entry;
      Option<NFInstNode.InstNode> node;
      list<Entry> children;
      EntryType ty;
    end ENTRY;
  end Entry;

  function newRedeclare
    input NFLookupTree.Entry entry;
    output Entry redecl = ENTRY(entry, NONE(), {}, EntryType.REDECLARE);
  end newRedeclare;

  function newDuplicate
    input NFLookupTree.Entry kept;
    input NFLookupTree.Entry duplicate;
    output Entry entry = ENTRY(kept, NONE(), {newEntry(duplicate)}, EntryType.DUPLICATE);
  end newDuplicate;

  function newEntry
    input NFLookupTree.Entry lentry;
    output Entry entry = ENTRY(lentry, NONE(), {}, EntryType.ENTRY);
  end newEntry;

  function idExistsInEntry
    input NFLookupTree.Entry id;
    input Entry entry;
    output Boolean exists;
  algorithm
    exists := NFLookupTree.Entry.isEqual(id, entry.entry) or
        List.any(entry.children, function idExistsInEntry(id = id));
  end idExistsInEntry;

  function getLookupEntries
    input Entry entry;
    output list<NFLookupTree.Entry> entries;
  algorithm
    entries := entry.entry :: listAppend(getLookupEntries(c) for c in entry.children);
  end getLookupEntries;

  function entryToList
    input Entry entry;
    output list<Entry> entries;
  algorithm
    entries := entry :: listAppend(entryToList(c) for c in entry.children);
  end entryToList;

import BaseAvlTree;
extends BaseAvlTree(redeclare type Key = String,
                    redeclare type Value = Entry);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := "";
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;

  annotation(__OpenModelica_Interface="frontend");
end NFDuplicateTree;
