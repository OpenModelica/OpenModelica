package org.openmodelica.corba.parser;

import java.util.HashMap;
import java.util.Vector;

class PackageDefinition {
  public String name;
  public HashMap<String,FunctionDefinition> functions;
  public HashMap<String,RecordDefinition> records;
  public HashMap<String,String> unionTypes;
  public HashMap<String,VariableDefinition> typeDefs;
  
  public PackageDefinition(String name) {
    this.name = name;
    functions = new HashMap<String,FunctionDefinition>();
    records = new HashMap<String,RecordDefinition>();
    unionTypes = new HashMap<String,String>();
    typeDefs = new HashMap<String,VariableDefinition>();
  }
  
  public void add(Object o) {
    if (o == null) {
    } else if (o instanceof FunctionDefinition) {
      FunctionDefinition fd = (FunctionDefinition) o;
      functions.put(fd.name, fd);
    } else if (o instanceof RecordDefinition) {
      RecordDefinition rd = (RecordDefinition) o;
      records.put(rd.name, rd);
    } else if (o instanceof VariableDefinition) {
      VariableDefinition vd = (VariableDefinition) o;
      typeDefs.put(vd.varName, vd);
    } else if (o instanceof UniontypeDefinition) {
      UniontypeDefinition utd = (UniontypeDefinition) o;
      unionTypes.put(utd.name, utd.name);
    }
  }

  public boolean contains(String s) {
    if (records.containsKey(s)) return true;
    if (unionTypes.containsKey(s)) return true;
    if (typeDefs.containsKey(s)) return true;
    return false;
  }
  
  public void fixTypePath(SymbolTable st, String basePackage) {
    for (RecordDefinition rec : records.values()) {
      rec.fixTypePaths(st, basePackage);
    }
    for (VariableDefinition td : typeDefs.values()) {
      td.fixTypePath(st, basePackage);
    }
    for (FunctionDefinition fun : functions.values()) {
      fun.fixTypePath(st, basePackage);
    }
  }
}
