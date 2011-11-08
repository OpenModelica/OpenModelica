package org.openmodelica;

public abstract class TypeSpec<T extends ModelicaObject> {
  protected final Class<T> c;
  public TypeSpec(Class<T> c) {
    this.c = c;
  }
  public Class<T> getClassType() {
    return c;
  }
}
