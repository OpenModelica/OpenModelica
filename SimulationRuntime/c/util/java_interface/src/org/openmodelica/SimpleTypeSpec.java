package org.openmodelica;

/**
 * Similar to OpenModelica Absyn.TPATH
 */
public class SimpleTypeSpec<T extends ModelicaObject> extends TypeSpec<T> {
  public SimpleTypeSpec(Class<T> c) {
    super(c);
  }

  public static final TypeSpec<ModelicaObject> modelicaObject = new SimpleTypeSpec<ModelicaObject>(ModelicaObject.class);
}
