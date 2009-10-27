package org.openmodelica;

public class ModelicaOption<T extends ModelicaObject> implements ModelicaObject {

  public T o;
  
  public ModelicaOption() {
  }
  
  @SuppressWarnings("unchecked")
  public ModelicaOption(ModelicaObject o) {
    if (o == null) {
      this.o = null;
      return;
    }
    this.o = (T) o;
  }

  @Override
  public boolean equals(Object o) {
    if (o instanceof ModelicaOption<?>) {
      ModelicaObject o1 = this.o;
      ModelicaObject o2 = ((ModelicaOption<?>)o).o;
      if (o1 == null && o2 == null)
        return true;
      if (o1 == null || o2 == null)
        return false;
      return o1.equals(o2);
    }
    return false;
  }
  
  @SuppressWarnings("unchecked")
  @Override
  public void setObject(ModelicaObject o) {
    ModelicaObject o2 = ((ModelicaOption<?>)o).o;
    if (o2 == null)
      this.o = null;
    else
      this.o = (T) o2;
  }
  
  public String toString() {
    if (o == null)
      return "NONE()";
    return "SOME("+o.toString()+")";
  }
}
