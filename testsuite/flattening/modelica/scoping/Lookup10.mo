// name:     Lookup10
// keywords: lookup, extends, scoping, bug1151
// status:   correct
//
// Fix for bug #1151: http://openmodelica.ida.liu.se:8080/cb/issue/1151?navigation=true
//

model t1
  constant Integer i = 4;
end t1;

package icons
  extends universals.icon_folder;
  package universals
    model icon_folder
    end icon_folder;
  end universals;
end icons;

package TOOLS
  extends icons;

  package surf_orient
    class surf_orient_alias_def
      extends t1;
      constant Integer n_of_surf_orient_def = i;
    end surf_orient_alias_def;
  end surf_orient;
end TOOLS;

model Lookup10
  extends TOOLS.surf_orient.surf_orient_alias_def;
end Lookup10;

// Result:
// class Lookup10
//   constant Integer i = 4;
// end Lookup10;
// endResult
