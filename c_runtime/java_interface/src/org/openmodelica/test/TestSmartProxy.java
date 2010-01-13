package org.openmodelica.test;

import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.openmodelica.ModelicaArray;
import org.openmodelica.ModelicaBoolean;
import org.openmodelica.ModelicaInteger;
import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaReal;
import org.openmodelica.ModelicaRecord;
import org.openmodelica.ModelicaString;
import org.openmodelica.ModelicaTuple;
import org.openmodelica.corba.ConnectException;
import org.openmodelica.corba.SmartProxy;
import org.openmodelica.corba.parser.*;

import static org.junit.Assert.*;

public class TestSmartProxy {
  private static SmartProxy proxy;

  @BeforeClass
  public static void initClass() throws ConnectException, ParseException {
    proxy = new SmartProxy("junit", "Modelica", true, true);
    proxy.sendExpression("cd(\""+System.getProperty("user.dir").replace("\\", "/")+"/test_files\")");
    if (true != proxy.sendModelicaExpression("loadFile(\"simple.mo\")", ModelicaBoolean.class).b)
      throw new ParseException("Failed to load file");
  }

  @AfterClass
  public static void destroyClass() throws ConnectException {
    proxy.stopServer();
  }

  @Before
  public void clear() throws ConnectException {
    proxy.sendExpression("clearVariables();");
  }

  @Test
  public void testStrings() throws ConnectException, ParseException {
    ModelicaRecord abc1 = proxy.sendModelicaExpression(" test.abc\t(1 ,\n2,3)", ModelicaRecord.class);
    ModelicaRecord abc2 = proxy.sendModelicaExpression("test.abc(4,5, 6)", ModelicaRecord.class);
    ModelicaRecord abc3 = proxy.sendModelicaExpression("test.abc(7, 8,9)", ModelicaRecord.class);

    ModelicaRecord def = proxy.sendModelicaExpression("test.def ( "+abc1+","+abc2+","+abc3+")", ModelicaRecord.class);

    assertEquals("test.def(d=test.abc(a=1,b=2,c=3.0),e=test.abc(a=4,b=5,c=6.0),f=test.abc(a=7,b=8,c=9.0))", def.toString());
  }

  @Test
  public void testFunctionCall() throws Exception {
    ModelicaObject abc_test = new abc(proxy.sendModelicaExpression(" test.abc\t(1 ,\n2,3)", ModelicaRecord.class));
    abc abc1 = new abc(abc_test);
    abc abc2 = proxy.sendModelicaExpression("test.abc(4,5, 6)", abc.class);

    /* If only Java supported C#-style getter/setter which allow you to override a = b (set) and a (get)... */
    abc1.set_b(new ModelicaInteger(abc2.get_b().i+1));

    abc abc3 = new abc(proxy.sendModelicaExpression("test.abc(7, 8,9)", ModelicaRecord.class));

    ModelicaRecord def = proxy.callModelicaFunction("test.def", ModelicaRecord.class, abc1, abc2, abc3);

    assertEquals("test.def(d=test.abc(a=1,b=6,c=3.0),e=test.abc(a=4,b=5,c=6.0),f=test.abc(a=7,b=8,c=9.0))", def.toString());
  }

  private ModelicaReal AddOne(ModelicaInteger mi) throws ConnectException, ParseException {
    return proxy.callModelicaFunction("test.AddOne", ModelicaReal.class, mi);
  }

  //(Integer)->(Integer,Integer) ; (i) -> (i+1,i+2)
  private ModelicaTuple AddTwo(ModelicaInteger mi) throws ConnectException, ParseException {
    return proxy.callModelicaFunction("test.AddTwo", ModelicaTuple.class, mi);
  }

  @Test
  public void testAddOne() throws ConnectException, ParseException {
    ModelicaInteger mi = new ModelicaInteger(42);

    ModelicaReal mr = AddOne(mi);
    assertEquals(mi.i+1.0, mr.r, 0.01);
  }

  @Test
  public void testAddTwo() throws ConnectException, ParseException {
    ModelicaInteger mi = new ModelicaInteger(42);

    ModelicaTuple mtp = AddTwo(mi);

    assertEquals(mi.i+1, mtp.get(0, ModelicaInteger.class).i);
    assertEquals(mi.i+2, mtp.get(1, ModelicaInteger.class).i);
  }

  @Test
  public void testModelicaString() throws ConnectException, ParseException {
    String start = "test\"abc";
    ModelicaString s = new ModelicaString(start);
    s = proxy.sendModelicaExpression(s, ModelicaString.class);

    assertEquals(start, s.s);
  }

  @SuppressWarnings("unchecked")
  @Test
  public void testRange() throws ConnectException, ParseException {
    String start = "0:29";

    ModelicaArray<ModelicaInteger> arr = (ModelicaArray<ModelicaInteger>) proxy.sendModelicaExpression(start);

    for (int i=0; i<30; i++) {
      assertEquals(i, arr.get(i).i);
    }
  }
}