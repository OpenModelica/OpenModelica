package org.openmodelica.test;

import static org.junit.Assert.*;

import org.junit.Test;
import org.openmodelica.ModelicaAny;
import org.openmodelica.ModelicaBoolean;
import org.openmodelica.ModelicaInteger;
import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaReal;
import org.openmodelica.ModelicaString;

public class TestObjects {

  @Test
  public void testImplicitTypeConversionBool() throws Exception {
    ModelicaInteger i1 = new ModelicaInteger(1);
    ModelicaInteger i0 = new ModelicaInteger(0);
    assertEquals(new ModelicaBoolean(true), ModelicaAny.cast(i1, ModelicaBoolean.class));
    assertEquals(new ModelicaBoolean(false), ModelicaAny.cast(i0, ModelicaBoolean.class));
  }

  @Test(expected=Exception.class)
  public void testImplicitTypeConversionBoolFail() throws Exception {
    ModelicaInteger i2 = new ModelicaInteger(2);
    ModelicaAny.cast(i2, ModelicaBoolean.class);
  }

  @Test
  public void testImplicitTypeConversionReal() throws Exception {
    ModelicaInteger i2 = new ModelicaInteger(2);
    ModelicaInteger i1 = new ModelicaInteger(1);
    ModelicaInteger i0 = new ModelicaInteger(0);
    assertEquals(new ModelicaReal(2), ModelicaAny.cast(i2, ModelicaReal.class));
    assertEquals(new ModelicaReal(1), ModelicaAny.cast(i1, ModelicaReal.class));
    assertEquals(new ModelicaReal(0), ModelicaAny.cast(i0, ModelicaReal.class));
  }

  @Test
  public void testStringNull() throws Exception {
    String expected = "\"\"";
    assertEquals(expected, new ModelicaString(null, false).toString());
    assertEquals(expected, new ModelicaString(null, true).toString());
    assertEquals(expected, new ModelicaString((String)null).toString());
    assertEquals(expected, new ModelicaString((ModelicaObject)null).toString());
  }
}
