package org.openmodelica.corba.parser;

import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.Vector;

class RecordDefinition {
  public RecordDefinition(String name, String packageName) {
    this.name = name;
    fields = new Vector<Object>();
    this.packageName = packageName;
    this.uniontype = null;
    this.ctor_index = -1;
  }
  public RecordDefinition(String name, String uniontype, int ctor_index, String packageName) {
    this.name = name;
    fields = new Vector<Object>();
    this.packageName = packageName;
    this.ctor_index = ctor_index;
    this.uniontype = uniontype;
  }
  public final String name;
  public final String uniontype;
  public final int ctor_index;
  private boolean fixed = false;
  public String packageName;
  public Vector<Object> fields;

  private Set<String> genericTypes;
  public String generics;

  public void fixTypePaths(SymbolTable st, String basePackage) {
    if (fixed)
      return;
    fixed = true;
    genericTypes = new LinkedHashSet<String>();
    StringBuffer buf = new StringBuffer();

    Vector<Object> newFields = new Vector<Object>();
    for (Object field : fields) {
      if (field instanceof VariableDefinition) {
        VariableDefinition vdef = (VariableDefinition)field;
        vdef.fixTypePath(st, basePackage);
        newFields.add(vdef);
      } else if (field instanceof String) {
        String s = org.openmodelica.corba.parser.ComplexTypeDefinition.fixTypePath((String)field,st,packageName);

        Object o = st.get(s);
        System.out.println(s);
        if (o instanceof VariableDefinition) {
          VariableDefinition vdef = (VariableDefinition) o;
          vdef.fixTypePath(st, basePackage);
          String newPath = vdef.getTypeName();
          o = st.get(newPath);
          if (o == null && newPath.startsWith(basePackage)) {
            newPath = newPath.substring(basePackage.length()+1);
            o = st.get(newPath);
          }
        }
        RecordDefinition rec = (RecordDefinition) o;
        rec.fixTypePaths(st, basePackage);
        for (Object o2 : rec.fields) {
          newFields.add(o2);
        }
      }
    }
    fields = newFields;

    for (Object o : fields) {
      VariableDefinition vdef = (VariableDefinition) o;
      String gen = vdef.typeDef.getGenericReference();
      if (gen != null)
        genericTypes.add(gen);
    }

    if (genericTypes.size() > 0) {
      buf.append("<");
      Iterator<String> it = genericTypes.iterator();
      while (it.hasNext()) {
        buf.append(it.next());
        buf.append(" extends ModelicaObject");
        if (it.hasNext())
          buf.append(",");
      }
      buf.append(">");
      generics = buf.toString();
    } else {
      generics = "";
    }
  }
}
