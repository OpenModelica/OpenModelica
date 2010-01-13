package org.openmodelica;

import java.io.IOException;
import java.io.Reader;

import org.openmodelica.corba.parser.ParseException;

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

  @Override
  public String toString() {
    return Double.toString(r);
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append(r);
  }

  public static ModelicaReal parse(Reader r) throws ParseException, IOException {
    StringBuilder b = new StringBuilder();
    ModelicaAny.parseIntOrReal(r, b);
    return new ModelicaReal(Double.parseDouble(b.toString()));
  }
}
