package org.openmodelica;

import java.util.Vector;

public abstract class ModelicaBaseArray<T extends ModelicaObject> extends Vector<T> implements ModelicaObject {
  private static final long serialVersionUID = 8935452322737749111L;

  public <TT extends T> TT get(int key, Class<TT> c) {
    return c.cast(get(key));
  }
}
