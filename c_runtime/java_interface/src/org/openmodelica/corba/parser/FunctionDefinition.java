package org.openmodelica.corba.parser;

import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.Vector;

class FunctionDefinition {
  public String name;
  public FunctionDefinition(String name) {
    this.name = name;
    input = new Vector<VariableDefinition>();
    output = new Vector<VariableDefinition>();
  }
  public Vector<VariableDefinition> input;
  public Vector<VariableDefinition> output;
  private Set<String> genericTypes;
  public String generics;
  
  public void fixTypePath(SymbolTable st, String basePackage) {
    genericTypes = new LinkedHashSet<String>();
    StringBuffer buf = new StringBuffer();
    for (VariableDefinition vdef : input) {
      vdef.fixTypePath(st,basePackage);
      String gen = vdef.typeDef.getGenericReference();
      if (gen != null)
        genericTypes.add(gen);
    }
    for (VariableDefinition vdef : output) {
      vdef.fixTypePath(st,basePackage);
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
