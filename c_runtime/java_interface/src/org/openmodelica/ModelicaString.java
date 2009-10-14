package org.openmodelica;

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
        switch(s.charAt(i)) {
        case 'a': res.append('\007'); break;
        case 'b': res.append('\b'); break;
        case 'f': res.append('\f'); break;
        case 'n': res.append('\n'); break;
        case 'r': res.append('\r'); break;
        case 't': res.append('\t'); break;
        case 'v': res.append('\013'); break;
        default: res.append(s.charAt(i)); break;
        }
      } else {
        res.append(s.charAt(i));
      }
    }
    return res.toString();
  }
  
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
}
