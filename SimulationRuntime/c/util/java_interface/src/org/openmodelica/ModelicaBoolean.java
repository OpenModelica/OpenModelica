package org.openmodelica;

import java.io.IOException;
import java.io.Reader;

import org.openmodelica.corba.parser.ParseException;

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

  public static ModelicaBoolean parse(Reader r) throws ParseException, IOException {
    int i;
    char ch;
    ModelicaAny.skipWhiteSpace(r);
    i = r.read();
    if (i == -1) throw new ParseException("EOF, expected Boolean");
    ch = (char) i;

    char cbuf[];
    if (ch == 't') {
      cbuf = new char[3];
      if (r.read(cbuf,0,3) == -1)
        throw new ParseException("EOF, expected Boolean");
      if (cbuf[0] == 'r' && cbuf[1] == 'u' && cbuf[2] == 'e')
        return new ModelicaBoolean(true);
    } else if (ch == 'f') {
      cbuf = new char[4];
      if (r.read(cbuf,0,4) == -1)
        throw new ParseException("EOF, expected Boolean");
      if (cbuf[0] == 'a' && cbuf[1] == 'l' && cbuf[2] == 's' && cbuf[3] == 'e')
        return new ModelicaBoolean(false);
    }
    throw new ParseException("Expected Boolean");
  }
}
