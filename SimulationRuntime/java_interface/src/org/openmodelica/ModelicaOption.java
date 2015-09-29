package org.openmodelica;

import java.io.IOException;
import java.io.Reader;

import org.openmodelica.corba.parser.ParseException;

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

  @Override
  public String toString() {
    if (o == null)
      return "NONE()";
    StringBuffer buf = new StringBuffer();
    printToBuffer(buf);
    return buf.toString();
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    if (o == null) {
      buffer.append("NONE()");
      return;
    }
    buffer.append("SOME(");
    o.printToBuffer(buffer);
    buffer.append(")");
  }

  public static ModelicaOption<?> parse(Reader r) throws IOException, ParseException {
    return parse(r,SimpleTypeSpec.modelicaObject);
  }

    public static <T extends ModelicaObject> ModelicaOption<T> parse(Reader r, TypeSpec<T> spec) throws IOException, ParseException {
    ModelicaAny.skipWhiteSpace(r);
    char[] cbuf = new char[5];
    r.read(cbuf, 0, 5);
    String s = new String(cbuf);
    if (s.equals("NONE(")) {
      if (r.read() == ')')
        return new ModelicaOption<T>(null);
      throw new ParseException("No closing )");
    }
    if (s.equals("SOME(")) {
      T obj = ModelicaAny.parse(r,spec);
      if (r.read() == ')')
        return new ModelicaOption<T>(obj);
      throw new ParseException("No closing )");
    }
    throw new ParseException(s + "... is not an option");
  }
}
