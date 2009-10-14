package org.openmodelica;

public class ModelicaFunctionReference implements ModelicaObject {
  public String functionReference;
  public ModelicaFunctionReference(String s) {
    functionReference = s;
  }
  public ModelicaFunctionReference(ModelicaObject o) {
    setObject(o);
  }
  
  public String toString() {
    return functionReference;
  }
  
  @Override
  public boolean equals(Object o) {
    try {
      return functionReference.equals(((ModelicaFunctionReference)o).functionReference);
    } catch (Throwable t) {
      return false;
    }
  }
  
  @Override
  public void setObject(ModelicaObject o) {
    functionReference = ((ModelicaFunctionReference)o).functionReference;
  }
}
