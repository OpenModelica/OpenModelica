package org.openmodelica.test;

import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaRecord;
import org.openmodelica.ModelicaRecordException;

public class ABC_CONTAINER extends ModelicaRecord implements ABC_UT {
  private static final long serialVersionUID = -3058713121310353198L;

  @SuppressWarnings("unchecked")
  public ABC_CONTAINER(ABC_UT a) throws ModelicaRecordException {
    super(new ModelicaRecord("test.ABC_CONTAINER",new String[]{"a"},new Class[]{ABC_UT.class},a));
  }

  public ABC_CONTAINER(ModelicaObject o) throws ModelicaRecordException {
    super(o);
    if (!getRecordName().equals("test.ABC_CONTAINER"))
      throw new ModelicaRecordException("Record name mismatch");
  }

  public ABC_UT get_a() {return get("a", ABC_UT.class);}
  public void set_a(ABC_UT a) {put("a", a);}
}
