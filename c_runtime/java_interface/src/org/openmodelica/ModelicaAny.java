package org.openmodelica;

import java.lang.reflect.Constructor;

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
      String[] recordNameParts = recordName.split("\\.");
      recordName = recordNameParts[recordNameParts.length-1];
      String className = c.getPackage().getName()+"."+recordName;
      /* Load the class of the record and verify that it is of the expected Uniontype */
      ClassLoader cl = c.getClassLoader();
      Class<?> nc = cl.loadClass(className);
      if (nc == null)
        throw new Exception("Couldn't find class " + className);
      if (!ModelicaObject.class.isAssignableFrom(nc))
        throw new Exception(nc + " is not a ModelicaObject");
      for (Class<?> iface : nc.getInterfaces()) {
        if (iface == c)
          return c.cast(ModelicaAny.cast(o, (Class<? extends ModelicaObject>) nc));
      }
      throw new Exception(nc + " is not a " + c);
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
}