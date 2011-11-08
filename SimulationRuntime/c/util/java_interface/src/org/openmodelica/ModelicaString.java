package org.openmodelica;

import java.io.IOException;
import java.io.Reader;

import org.openmodelica.corba.parser.ParseException;

public class ModelicaString implements ModelicaObject {
  public String s;
  public ModelicaString(ModelicaObject o) {
    setObject(o);
  }

  public ModelicaString(String s) {
    this.s = s;
  }

  public ModelicaString(String s, boolean escapeString) {
    if (escapeString)
      this.s = unescapeOMC(s);
    else
      this.s = s;
  }

  public static String escapeOMC(String s) {
    if (s == null)
      return "";
    String res = s;
    res = res.replace("\\", "\\\\");
    res = res.replace("\"", "\\\"");
    return res;
  }

  public static String unescapeOMC(String s) {
    if (s == null)
      return "";
    StringBuffer res = new StringBuffer("");
    for (int i=0; i<s.length(); i++) {
      if (s.charAt(i) == '\\') {
        i++;
        res.append(unescapeChar(s.charAt(i)));
      } else {
        res.append(s.charAt(i));
      }
    }
    return res.toString();
  }

  public static char unescapeChar(char ch) {
    switch(ch) {
    case 'a': return '\007';
    case 'b': return '\b';
    case 'f': return '\f';
    case 'n': return '\n';
    case 'r': return '\r';
    case 't': return '\t';
    case 'v': return '\013';
    default: return ch;
    }
  }

  @Override
  public String toString() {
    return "\"" + escapeOMC(s) + "\"";
  }

  public String toEscapedString() {
    return escapeOMC(s);
  }

  @Override
  public boolean equals(Object o) {
    try {
      return s.equals(((ModelicaString)o).s);
    } catch (Throwable t) {
      return false;
    }
  }

  @Override
  public void setObject(ModelicaObject o) {
    if (o == null)
      s = "";
    else
      s = ((ModelicaString) o).s;
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    buffer.append(toString());
  }

  public static ModelicaString parse(Reader r) throws ParseException, IOException {
    StringBuilder b = new StringBuilder();
    int i;
    char ch;
    ModelicaAny.skipWhiteSpace(r);
    i = r.read();
    if (i == -1)
      throw new ParseException("EOF, expected String");
    ch = (char) i;

    if (ch != '\"')
      throw new ParseException("Expected String");

    do {
      i = r.read();
      if (i == -1)
        throw new ParseException("EOF, expected String");
      ch = (char) i;

      if (ch == '\\') {
        i = r.read();
        if (i == -1)
          throw new ParseException("EOF, expected String");
        ch = (char) i;
        b.append(unescapeChar(ch));
      } else if (ch != '\"')
        b.append(ch);
      else
        break;
    } while (true);
    return new ModelicaString(b.toString(),false);
  }
}
