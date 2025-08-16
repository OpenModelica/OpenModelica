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
