encapsulated package NFLookupTree
public
  uniontype Entry
    record CLASS
      Integer index;
    end CLASS;

    record COMPONENT
      Integer index;
    end COMPONENT;

    record IMPORT
      Integer index;
    end IMPORT;

    function index
      input Entry entry;
      output Integer index;
     algorithm
       index := match entry
         case CLASS() then entry.index;
         case COMPONENT() then entry.index;
         case IMPORT() then entry.index;
       end match;
    end index;

    function isEqual
      input Entry entry1;
      input Entry entry2;
      output Boolean isEqual = index(entry1) == index(entry2);
    end isEqual;

    function isImport
      input Entry entry;
      output Boolean isImport;
    algorithm
      isImport := match entry
        case IMPORT() then true;
        else false;
      end match;
    end isImport;
  end Entry;

public
import BaseAvlTree;
extends BaseAvlTree(redeclare type Key = String,
                    redeclare type Value = Entry);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := match inValue
      case Entry.CLASS() then "class " + String(inValue.index);
      case Entry.COMPONENT() then "comp " + String(inValue.index);
    end match;
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;

  annotation(__OpenModelica_Interface="util");
end NFLookupTree;
