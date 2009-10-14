package org.openmodelica.corba.parser;

public class ComplexTypeDefinition {
  public enum ComplexType {ARRAY,DEFINED_TYPE,TYPE_REFERENCE,BUILT_IN, LIST_TYPE, OPTION_TYPE, TUPLE_TYPE, GENERIC_TYPE, FUNCTION_REFERENCE;}
  
  private ComplexType t;
  private String typeName;
  private ComplexTypeDefinition complexType;
  private int dim = 0;
  
  public ComplexTypeDefinition(ComplexType t) {
    this.t = t;
    
    switch (t) {
    case LIST_TYPE:
      dim = 1;
    case OPTION_TYPE:
    case TUPLE_TYPE:
      break;
    case FUNCTION_REFERENCE:
      break;
    default:
      throw new RuntimeException("Constructor wants more arguments for type " + t);
    }
  }
  
  public ComplexTypeDefinition(ComplexType t, String s) {
    this.t = t;
    switch (t) {
    case DEFINED_TYPE:
    case GENERIC_TYPE:
    case BUILT_IN:
    case TYPE_REFERENCE:
      typeName = s;
      break;
    default:
      throw new RuntimeException("Constructor wants other arguments for type " + t);
    }
  }
  
  public ComplexTypeDefinition(ComplexType t, ComplexTypeDefinition def, int i) {
    this.t = t;
    switch (t) {
    case ARRAY:
      complexType = def;
      dim = i;
      break;
    default:
      throw new RuntimeException("Constructor wants more arguments for type " + t);
    }
  }
  
  public static String fixTypePath(String typeName, SymbolTable st, String pack) {
    String curPack = pack;
    while (true) {
      String relative = (curPack != null ? curPack+"." : "") + typeName;
      if (st.containsKey(relative)) {
        return relative;
      }
      if (curPack == null)
        throw new RuntimeException(String.format("%s not in the symbol table (%s as top package)", typeName, pack));
      int lastDot = curPack.lastIndexOf(".");
      if (lastDot != -1) {
        curPack = curPack.substring(0, lastDot);
      } else {
        curPack = null;
      }
    }
  }
  
  public void fixTypePath(SymbolTable st, String curPackage, String basePackage) {
    switch (t) {
    case DEFINED_TYPE:
      String res = fixTypePath(typeName, st, curPackage);
      if (st.get(res) instanceof VariableDefinition) {
        VariableDefinition vdef = (VariableDefinition) st.get(res);
        vdef.fixTypePath(st, basePackage);
        //System.out.println(res + " is: " + vdef.typeDef.t);
        switch (vdef.typeDef.t) {
        case DEFINED_TYPE:
          typeName = (basePackage != null ? basePackage+"." : "") + res;
          t = ComplexType.BUILT_IN;
          break;
        case GENERIC_TYPE:
          t = ComplexType.GENERIC_TYPE;
          break;
        default:
          t = vdef.typeDef.t;
          typeName = vdef.typeDef.typeName;
          complexType = vdef.typeDef.complexType;
          dim = vdef.typeDef.dim;
        }
      } else {
        typeName = (basePackage != null ? basePackage+"." : "") + res;
        t = ComplexType.BUILT_IN;
      }
      break;
    case LIST_TYPE:
    case OPTION_TYPE:
    case ARRAY:
      complexType.fixTypePath(st, curPackage, basePackage);
      break;
    case FUNCTION_REFERENCE:
    case TUPLE_TYPE:
    case BUILT_IN:
    case GENERIC_TYPE:
    case TYPE_REFERENCE:
        break;
    }
  }
  
  public void add(ComplexTypeDefinition def) {
    switch (t) {
    case OPTION_TYPE:
    case LIST_TYPE:
      complexType = def;
      break;
    default:
      throw new RuntimeException("Can't add element for type " + t);
    }
  }
  
  public String getTypeName() {
    String res = "";
    
    switch (t) {
    case BUILT_IN:
    case GENERIC_TYPE:
    case DEFINED_TYPE:
      return typeName;
    case LIST_TYPE:
    case ARRAY:
      for (int i=0; i<dim; i++)
        res += "ModelicaArray<";
      res += complexType.getTypeName();
      for (int i=0; i<dim; i++)
        res += ">";
      return res;
    case FUNCTION_REFERENCE:
      return "ModelicaFunctionReference";
    case TUPLE_TYPE:
      return "ModelicaTuple";
    case OPTION_TYPE:
      return "ModelicaOption<" + complexType.getTypeName() + ">";
    case TYPE_REFERENCE:
    default:
      throw new RuntimeException("Developer forgot to add case here...");
    }
  }

  public String getTypeClass() {
    switch (t) {
    case GENERIC_TYPE:
      return "__outClass";
    case BUILT_IN:
    case DEFINED_TYPE:
      return typeName + ".class";
    case FUNCTION_REFERENCE:
      return "ModelicaFunctionReference.class";
    case TUPLE_TYPE:
      return "ModelicaTuple.class";
    case OPTION_TYPE:
      return "ModelicaOption.class";
    case LIST_TYPE:
    case ARRAY:
      return "ModelicaArray.class";
    default:
      throw new RuntimeException("Developer forgot to add case here...");
    }
  }

  public String getGenericReference() {
    if (t == ComplexType.GENERIC_TYPE)
      return typeName;
    if (complexType != null)
      return complexType.getGenericReference();
    return null;
  }

}
