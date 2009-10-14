package org.openmodelica.test;

import org.openmodelica.ModelicaInteger;
import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaReal;
import org.openmodelica.ModelicaRecord;

/* The class needs to be public and not a nested class because
 * it has be accessed by the proxy through reflection. If it's part of
 * another class the constructor has a different signature (Java sends the parent
 * class as an argument to nested classes). */

public class abc extends ModelicaRecord implements ABC_UT {
  private static final long serialVersionUID = -2570450403100665253L;

  public abc(ModelicaInteger a,ModelicaInteger b,ModelicaReal c) {
    super(new ModelicaRecord("test.abc", new String[]{"a","b","c"}));
    put("a", a);
    put("b", b);
    put("c", c);
  }

  public abc(ModelicaObject o) {
    super("test.abc",
        new String[]{"a","b","c"},
        new Class[] {ModelicaInteger.class,ModelicaInteger.class,ModelicaReal.class},
        (ModelicaRecord) o);
  }

  public ModelicaInteger get_a() {return get("a", ModelicaInteger.class);}
  public void set_a(ModelicaInteger a) {put("a", a);}

  public ModelicaInteger get_b() {return get("b", ModelicaInteger.class);}
  public void set_b(ModelicaInteger b) {put("b", b);}

  public ModelicaReal get_c() {return get("c", ModelicaReal.class);}
  public void set_c(ModelicaReal c) {put("c", c);}
}
