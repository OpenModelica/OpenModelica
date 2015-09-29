package org.openmodelica.corba.parser;

import java.util.HashMap;

public class SymbolTable extends HashMap<String,Object> {
  private static final long serialVersionUID = -4397140748624770527L;

  private void add(String pack, String name, Object o) {
    if (name != null)
      name = name.replace(".inner.", ".");
    if (pack == null)
      put(name, o);
    else
      put(pack + "." + name, o);
  }

  public void add(RecordDefinition rec, String curPackage) {
    add(curPackage, rec.name, rec);
  }
  public void add(FunctionDefinition fun, String curPackage) {
    add(curPackage, fun.name, fun);
  }
  public void add(UniontypeDefinition ut, String curPackage) {
    add(curPackage, ut.name, ut);
  }
  public void add(PackageDefinition pack, String curPackage) {
    add(null, pack.name, pack);
  }
  public void add(VariableDefinition typedef, String curPackage) {
    add(curPackage, typedef.varName, typedef);
  }

}
