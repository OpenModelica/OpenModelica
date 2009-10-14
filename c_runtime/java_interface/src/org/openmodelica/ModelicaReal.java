package org.openmodelica;

public class ModelicaReal implements ModelicaObject {
  public double r;
  public ModelicaReal(ModelicaObject o) {
    setObject(o);
  }
  public ModelicaReal(double d) {
    this.r = d;
  }
  public ModelicaReal(Double d) {
    this.r = d;
  }
  public String toString() {
    return Double.toString(r);
  }
  
  @Override
  public boolean equals(Object o) {
    try {
      return r == ((ModelicaReal)o).r;
    } catch (Throwable t) {
      return false;      
    }
  }
  
  @Override
  public void setObject(ModelicaObject o) {
    if (o instanceof ModelicaInteger) {
      r = ((ModelicaInteger)o).i;
    } else {
      r = ((ModelicaReal)o).r;
    }
  }
}
