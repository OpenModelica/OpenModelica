package org.openmodelica;

/**
 * Similar to OpenModelica TCOMPLEX
 */
public class ComplexTypeSpec<T extends ModelicaObject> extends TypeSpec<T> {
  private final TypeSpec<? extends ModelicaObject>[] spec;
  public ComplexTypeSpec(Class<T> c,TypeSpec<? extends ModelicaObject>[] spec) {
    super(c);
    this.spec = spec;
  }
  public TypeSpec<? extends ModelicaObject>[] getSubClassType() {
    return spec;
  }
}
