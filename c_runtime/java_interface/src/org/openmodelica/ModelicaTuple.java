package org.openmodelica;

import java.io.IOException;
import java.io.Reader;
import java.util.List;

import org.openmodelica.corba.parser.ParseException;

public class ModelicaTuple extends ModelicaBaseArray<ModelicaObject> implements ModelicaObject {
  private static final long serialVersionUID = -5901839591369712274L;

  public ModelicaTuple(ModelicaObject o) {
    setObject(o);
  }

  public ModelicaTuple() {
  }

  public ModelicaTuple(ModelicaObject... objs) {
    for(ModelicaObject obj : objs) {
      add(obj);
    }
  }

  public ModelicaTuple(List<ModelicaObject> objs) {
    for(ModelicaObject obj : objs) {
      add(obj);
    }
  }

  @Override
  public String toString() {
    StringBuffer buf = new StringBuffer();
    printToBuffer(buf);
    return buf.toString();
  }

  @Override
  public void setObject(ModelicaObject o) {
    ModelicaTuple arr = (ModelicaTuple) o;
    this.clear();
    this.addAll(arr);
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append("(");
    for (int i=0; i<this.elementCount; i++) {
      if (i != 0)
        buffer.append(",");
      get(i).printToBuffer(buffer);
    }
    buffer.append(")");
  }

  public static ModelicaTuple parse(Reader r, TypeSpec<?>[] spec) throws ParseException, IOException {
    ModelicaTuple tuple = new ModelicaTuple();
    ModelicaAny.skipWhiteSpace(r);
    int i,n;
    char ch;
    i = r.read();
    if (i == -1) throw new ParseException("EOF, expected tuple");
    ch = (char) i;
    if (ch != '(') throw new ParseException("Expected tuple");
    n = 0;
    do {
      ModelicaAny.skipWhiteSpace(r);
      if (spec == null)
        tuple.add(ModelicaAny.parse(r));
      else
        tuple.add(ModelicaAny.parse(r,spec[n++]));
      ModelicaAny.skipWhiteSpace(r);
      i = r.read();
      if (i == -1)
        throw new ParseException("EOF, expected a comma or closing tuple");
      ch = (char) i;
    } while (ch == ',');
    if (ch != ')') {
      throw new ParseException("Expected closing tuple");
    }
    return tuple;
  }
}
