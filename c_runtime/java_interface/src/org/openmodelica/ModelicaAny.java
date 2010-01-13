package org.openmodelica;

import java.io.IOException;
import java.io.Reader;
import java.lang.reflect.Constructor;

import org.openmodelica.corba.parser.ParseException;

public class ModelicaAny {
  @SuppressWarnings("unchecked")
  public static <T extends ModelicaObject> T cast(ModelicaObject o, Class<T> c) throws Exception {
    /* ModelicaObject -> ModelicaObject: Simple */
    if (c == ModelicaObject.class) {
      return c.cast(o);
      /* ModelicaObject -> Interface extends ModelicaObject (must be Uniontype) */
    } else if (c.isInterface()) {
      if (!(o instanceof ModelicaRecord))
        throw new Exception(o + " is not a record, but tried to cast it to Uniontype " + c);
      /* Find the Java name of the record. We know the record will be part of the same package */
      ModelicaRecord rec = ModelicaRecord.class.cast(o);
      String recordName = rec.getRecordName();
      Class<?> nc = findUniontypeRecordClass(c,recordName);
      return c.cast(ModelicaAny.cast(o, (Class<? extends ModelicaObject>) nc));
    } else {
      try {
        if (c.isAssignableFrom(o.getClass()))
          return c.cast(o);
        Constructor<T> cons = c.getConstructor(ModelicaObject.class);
        return cons.newInstance(o);
      } catch (NoSuchMethodException ex) {
        String constructors = "";
        for (Constructor<?> cons : c.getConstructors())
          constructors += cons.toString() + "\n";
        throw new RuntimeException(String.format("Failed to find constructor for class %s\n" +
            "All ModelicaObjects need to support a public constructor taking a ModelicaObject as parameter.\n" +
            "Because of this, a ModelicaObject cannot be defined as an \"inner\" class\n" +
            "The following constructors were defined for the wanted class:\n%s", c, constructors));
      } catch (Throwable t) {
        throw new Exception(t);
      }
    }
  }

  @SuppressWarnings("unchecked")
  private static <T extends ModelicaObject> Class<? extends T> findUniontypeRecordClass(Class<T> c,String recordName) throws ParseException {
    String[] recordNameParts = recordName.split("\\.");
    recordName = recordNameParts[recordNameParts.length-1];
    String className = c.getPackage().getName()+"."+recordName;
    /* Load the class of the record and verify that it is of the expected Uniontype */
    ClassLoader cl = c.getClassLoader();
    Class<?> nc;
    try {
      nc = cl.loadClass(className);
    } catch (ClassNotFoundException e) {
      throw new ParseException(e);
    }
    if (nc == null)
      throw new ParseException("Couldn't find class " + className);
    if (!ModelicaObject.class.isAssignableFrom(nc))
      throw new ParseException(nc + " is not a ModelicaObject");
    for (Class<?> iface : nc.getInterfaces()) {
      if (iface == c)
        return (Class<? extends T>) nc;
    }
    throw new ParseException(nc + " is not a " + c);
  }

  public static ModelicaObject parse(Reader r) throws IOException, ParseException {
    skipWhiteSpace(r);
    r.mark(1);
    if (r.read() == -1) return new ModelicaVoid();
    r.reset();
    r.mark(6);
    char[] cbuf = new char[6];
    r.read(cbuf, 0, 6);
    r.reset();
    String s = new String(cbuf);
    if (cbuf[0] == '{') return ModelicaArray.parse(r,SimpleTypeSpec.modelicaObject);
    if (cbuf[0] == '(') return ModelicaTuple.parse(r,null);
    if (cbuf[0] == '\"') return ModelicaString.parse(r);
    if (s.startsWith("NONE(")) return ModelicaOption.parse(r,SimpleTypeSpec.modelicaObject);
    if (s.startsWith("SOME(")) return ModelicaOption.parse(r,SimpleTypeSpec.modelicaObject);
    if (s.startsWith("record")) return ModelicaRecord.parse(r);
    if (s.startsWith("true")) return ModelicaBoolean.parse(r);
    if (s.startsWith("false")) return ModelicaBoolean.parse(r);

    try {
      r.mark(100);
      StringBuilder b = new StringBuilder();
      Boolean bool = parseIntOrReal(r,b);
      if (bool) {
        return new ModelicaReal(Double.parseDouble(b.toString()));
      } else {
        return new ModelicaInteger(Integer.parseInt(b.toString()));
      }
    } catch (NumberFormatException e) {
      r.reset();
      throw new ParseException("Couldn't match any object");
    }
  }

  public static void skipWhiteSpace(Reader r) throws IOException {
    int i;
    char c;
    do {
      r.mark(1);
      i = r.read();
      if (i == -1)
        return;
      c = (char) i;
    } while (Character.isWhitespace(c));
    r.reset();
  }

  /**
   * Returns true if the value is a Real, else returns an Integer
   */
  public static boolean parseIntOrReal(Reader r, StringBuilder b) throws ParseException, IOException {
    boolean bool = false;
    int i;
    char ch;
    skipWhiteSpace(r);
    do {
      r.mark(1);
      i = r.read();
      if (i == -1)
        break;
      ch = (char) i;
      if (Character.isDigit(ch) || ch == '-')
        b.append(ch);
      else if (ch == 'e' || ch == 'E' || ch == '+' || ch == '.') {
        b.append(ch);
        bool = true;
      } else {
        r.reset();
        break;
      }
    } while (true);
    return bool;
  }

  static String lexIdent(Reader r) throws IOException, ParseException {
    return lexIdent(r,true);
  }

  static String lexIdent(Reader r, boolean mark) throws IOException, ParseException {
    int i;
    char ch;
    do {
      i = r.read();
      if (i == -1)
        throw new ParseException("Expected identifier, got EOF");
      ch = (char) i;
    } while (Character.isWhitespace(ch));

    StringBuffer b = new StringBuffer();
    do {
      if (ch == '_' || ch == '.' || Character.isLetterOrDigit(ch))
        b.append(ch);
      else {
        break;
      }
      if (mark) r.mark(1);
      i = r.read();
      if (i == -1)
        break;
      ch = (char) i;
    } while (true);
    if (mark) r.reset();
    if (b.length() == 0)
      throw new ParseException("Expected identifier");
    return b.toString();
  }

  @SuppressWarnings("unchecked")
  public static <T extends ModelicaObject> T parse(Reader r, TypeSpec<T> spec) throws IOException, ParseException {
    if (spec instanceof ComplexTypeSpec)
      return parseComplex(r,(ComplexTypeSpec<T>) spec);
    else
      return parse(r,spec.getClassType());
  }

  @SuppressWarnings("unchecked")
  private static <T extends ModelicaObject> T parse(Reader r, Class<T> c) throws IOException, ParseException {
    if (c == ModelicaObject.class)
      return (T)parse(r);
    if (c.isInterface()) {
      /* Uniontypes are special */
      r.mark(500);
      String rec = lexIdent(r,false);
      if (!rec.equals("record"))
        throw new ParseException("Expected 'record' got " + rec);
      String id = lexIdent(r,false);
      r.reset();
      return parse(r,new SimpleTypeSpec<T>((Class<T>)findUniontypeRecordClass(c,id)));
    }
    try {
      return (T) c.getMethod("parse", java.io.Reader.class).invoke(null, r);
    } catch (Exception e) {
      throw new ParseException(e);
    }
  }

  @SuppressWarnings("unchecked")
  public static <T extends ModelicaObject> T parseComplex(Reader r, ComplexTypeSpec<T> spec) throws IOException, ParseException {
    Class<T> c = spec.getClassType();
    TypeSpec<? extends ModelicaObject>[] specs = spec.getSubClassType();
    if (specs.length > 1) {
      if (c == ModelicaTuple.class)
        return (T)ModelicaTuple.parse(r, specs);
    } else if (specs.length == 1){
      if (c == ModelicaArray.class)
        return (T) ModelicaArray.parse(r, spec.getSubClassType()[0]);
      if (c == ModelicaOption.class)
        return (T)ModelicaOption.parse(r, spec.getSubClassType()[0]);
    }
    throw new ParseException("Couldn't find a complex class for " + c.getName() + " with " + specs.length + " types");
  }
}