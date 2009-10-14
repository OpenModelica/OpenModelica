package org.openmodelica.test;

import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaRecord;

public class ABC_CONTAINER extends ModelicaRecord implements ABC_UT {
  private static final long serialVersionUID = -3058713121310353198L;
  
  public ABC_CONTAINER(ABC_UT a) {
    super(new ModelicaRecord("test.ABC_CONTAINER", new String[]{"a"}));
    put("a", a);
  }

  public ABC_CONTAINER(ModelicaObject o) {
    super("test.ABC_CONTAINER",
        new String[]{"a"},
        new Class[] {ABC_UT.class},
        (ModelicaRecord) o);
  }

  public ABC_UT get_a() {return get("a", ABC_UT.class);}
  public void set_a(ABC_UT a) {put("a", a);}
}
