package org.openmodelica.corba.parser;

class VariableDefinition {
  public String varName;
  public String packageName;

  public ComplexTypeDefinition typeDef;

  public VariableDefinition(ComplexTypeDefinition typeDef, String varName, String packageName) {
    this.typeDef = typeDef;
    this.varName = varName;
    this.packageName = packageName;
  }

  public void fixTypePath(SymbolTable st, String basePackage) {
    typeDef.fixTypePath(st,packageName,basePackage);
  }

  public String getTypeName() {
    return typeDef.getTypeName();
  }

  public String getTypeClass() {
    return typeDef.getTypeClass();
  }

  public String getTypeSpec() {
    return typeDef.getTypeSpec();
  }

  public boolean getGenericReference() {
    return typeDef.getGenericReference() != null;
  }
}
