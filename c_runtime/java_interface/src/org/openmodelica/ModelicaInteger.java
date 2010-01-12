package org.openmodelica;

public class ModelicaInteger implements ModelicaObject {
  public int i;
  public ModelicaInteger(ModelicaObject o) {
    setObject(o);
  }
  public ModelicaInteger(int i) {
    this.i = i;
  }
  public ModelicaInteger(Integer i) {
    this.i = i;
  }

  @Override
  public String toString() {
    return Integer.toString(i);
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append(i);
  }

  @Override
  public boolean equals(Object o) {
    try {
      return i == ((ModelicaInteger)o).i;
    } catch (Throwable t) {
      return false;
    }
  }

  @Override
  public void setObject(ModelicaObject o) {
    i = ((ModelicaInteger) o).i;
  }
}
