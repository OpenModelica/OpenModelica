package org.openmodelica.test;

import java.io.IOException;
import java.io.Reader;
import java.util.Map;

import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaRecord;
import org.openmodelica.ModelicaRecordException;
import org.openmodelica.SimpleTypeSpec;
import org.openmodelica.corba.parser.ParseException;

@SuppressWarnings("unchecked")
public class ABC_CONTAINER extends ModelicaRecord implements ABC_UT {
  private static final long serialVersionUID = -3058713121310353198L;

  private static org.openmodelica.TypeSpec<? extends ModelicaObject>[] fieldTypeSpecs;

  static {
    fieldTypeSpecs = new org.openmodelica.TypeSpec[] {
      new SimpleTypeSpec(ABC_UT.class)
    };
  };

  public ABC_CONTAINER(ABC_UT a) throws ModelicaRecordException {
    super(new ModelicaRecord("test.ABC_CONTAINER",new String[]{"a"},new Class[]{ABC_UT.class},a));
  }

  public ABC_CONTAINER(ModelicaObject o) throws ModelicaRecordException {
    super(o);
    if (!getRecordName().equals("test.ABC_CONTAINER"))
      throw new ModelicaRecordException("Record name mismatch");
  }

  public ABC_CONTAINER(String recordName, Map map) throws ModelicaRecordException {
    super(recordName,map);
  }

  public ABC_UT get_a() {return get("a", ABC_UT.class);}
  public void set_a(ABC_UT a) {put("a", a);}

  public static ABC_CONTAINER parse(Reader r) throws ParseException, IOException {
    return ModelicaRecord.parse(r,ABC_CONTAINER.class,fieldTypeSpecs);
  }
}
