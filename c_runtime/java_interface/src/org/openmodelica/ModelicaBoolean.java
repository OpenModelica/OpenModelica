package org.openmodelica;

public class ModelicaBoolean implements ModelicaObject {
  public boolean b;
  public ModelicaBoolean(ModelicaObject o) {
    setObject(o);
  }
  public ModelicaBoolean(boolean b) {
    this.b = b;
  }
  public ModelicaBoolean(Boolean b) {
    this.b = b;
  }
  @Override
  public String toString() {
    return Boolean.toString(b);
  }
  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append(b);
  }

  @Override
  public boolean equals(Object o) {
    try {
      return b == ((ModelicaBoolean)o).b;
    } catch (Throwable t) {
      return false;
    }
  }

  @Override
  public void setObject(ModelicaObject o) {
    if (o instanceof ModelicaInteger) {
      switch (((ModelicaInteger)o).i) {
      case 0: b = false; break;
      case 1: b = true; break;
      default:
        throw new RuntimeException("Can only cast integers 0 and 1 to boolean (was " + o.getClass().getName() + ": " + o + ")");
      }
    } else {
      b = ((ModelicaBoolean) o).b;
    }
  }
}
