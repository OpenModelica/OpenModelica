package org.openmodelica.test;

import static org.junit.Assert.*;
import java.util.Map;
import java.util.TreeMap;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;
import org.openmodelica.*;

public class TestRecord {
  
  ModelicaRecord simpleRecord;
  @Before
  public void init() {
    simpleRecord = new ModelicaRecord("simple", new String[]{"simple"});
  }

  @Test
  public void testModelicaRecordConstructor() {
    // Unsorted array that also won't keep the same order when hashed
    // The test checks that the order is the same - this is important because
    // Modelica requires that it is!
    String[] expectedResult = new String[]{"a","b","123","d","c","f","e","g","h","i","j"};
    ModelicaRecord r = new ModelicaRecord("abc", expectedResult);
    Object[] keys = r.keySet().toArray();
    assertEquals(keys.length, expectedResult.length);
    for (int i=0; i<expectedResult.length; i++)
      assertEquals(keys[i],expectedResult[i]);
    assertEquals("abc", r.getRecordName());
    r.put("a", new ModelicaInteger(1));
    assertEquals(1, r.get("a", ModelicaInteger.class).i);
    // r.toString(); - How to handle null members?
  }
  
  @Test
  public void testSetObject() throws ModelicaRecordException {
    ModelicaRecord r1 = new ModelicaRecord("abc", new String[] {"a","b","c"});
    ModelicaRecord r2 = new ModelicaRecord("abc", new String[] {"a","b","c"}, new ModelicaInteger(1), new ModelicaInteger(2), new ModelicaInteger(3));
    ModelicaRecord r3 = new ModelicaRecord("abc", new String[] {"a","b","c"}, new ModelicaInteger(4), new ModelicaInteger(5), new ModelicaInteger(6));
    ModelicaRecord r4 = new ModelicaRecord("abc", new String[] {"a","b","c"}, new ModelicaInteger(4), new ModelicaInteger(5), new ModelicaInteger(6));
    r1.setObject(r2);
    r1.setObject(r3);
    assertEquals(r1,r4);
  }

  @Test
  public void testModelicaRecordConstructorPutGetInt() {
    String[] keys = new String[]{"a","b","123","d","c","f","e","g","h","i","j"};
    int[] expectedResult = new int[]{1,2,3,5,4,7,13,-25,8,9,0};
    ModelicaRecord r = new ModelicaRecord("abc", keys);
    
    for (int i=0; i<keys.length; i++) {
      r.put(keys[i], new ModelicaInteger(expectedResult[i]));
    }
    for (int i=0; i<keys.length; i++) {
      assertEquals(r.get(keys[i], ModelicaInteger.class).i,expectedResult[i]);
    }
  }

  @Test
  public void testModelicaRecordMapConstructor() {
    Map<String,ModelicaObject> m = new TreeMap<String,ModelicaObject>();
    m.put("a", new ModelicaInteger(1));
    m.put("c", new ModelicaInteger(3));
    m.put("b", new ModelicaInteger(2));
    ModelicaRecord r = new ModelicaRecord("abc", m);
    assertEquals(1, r.get("a", ModelicaInteger.class).i);
    assertEquals(2, r.get("b", ModelicaInteger.class).i);
    assertEquals(3, r.get("c", ModelicaInteger.class).i);
    // Note the order is different from the order the elements were inserted in.
    // TreeMap forced a sorted order
    assertEquals(r.toString(), "abc(a=1,b=2,c=3)");
  }

  @Test
  public void testModelicaRecordValuesConstructor() throws ModelicaRecordException {
    // Checks the same thing as testModelicaRecordStringArray
    // It also checks that all values are set properly when initialized
    String[] expectedResult = new String[]{"a","b","123","d","c","f","e","g","h","i","j"};
    int[] expectedResultValues = new int[]{-123,-145,123,145,17,42,1,0,0,1,124144164};
    assertEquals(expectedResult.length,expectedResultValues.length);
    ModelicaObject[] values = new ModelicaObject[expectedResultValues.length];
    for (int i=0; i<expectedResultValues.length; i++)
      values[i] = new ModelicaInteger(expectedResultValues[i]);
    
    ModelicaRecord r = new ModelicaRecord("abc", expectedResult, values);
    Object[] keys = r.keySet().toArray();
    assertEquals(keys.length, expectedResult.length);
    for (int i=0; i<expectedResult.length; i++)
      assertEquals(keys[i],expectedResult[i]);
    assertEquals("abc", r.getRecordName());
    assertEquals(r.toString(), "abc(a=-123,b=-145,123=123,d=145,c=17,f=42,e=1,g=0,h=0,i=1,j=124144164)");
  }

  @Test(expected=ModelicaRecordException.class)
  public void testModelicaRecordDifferentLength() throws ModelicaRecordException {
    new ModelicaRecord("abc", new String[]{"a","b","c"}, new ModelicaInteger[]{new ModelicaInteger(1)});
  }

  @Ignore
  @Test(expected=ModelicaRecordException.class)
  public void testModelicaRecordNullValues() throws ModelicaRecordException {
    fail("Not yet implemented"); // How do we implement Option type?
  }

  @Test
  public void testGetInt() {
    simpleRecord.put("simple", new ModelicaInteger(32));
    assertEquals(32, simpleRecord.get("simple", ModelicaInteger.class).i);
  }

  @Test
  public void testGetDouble() {
    simpleRecord.put("simple", new ModelicaReal(32.0));
    assertEquals(32, simpleRecord.get("simple", ModelicaReal.class).r, 0.01);
  }

  @Test
  public void testGetBoolean() {
    simpleRecord.put("simple", new ModelicaBoolean(false));
    assertEquals(false, simpleRecord.get("simple", ModelicaBoolean.class).b);
    simpleRecord.put("simple", new ModelicaBoolean(true));
    assertEquals(true, simpleRecord.get("simple", ModelicaBoolean.class).b);
  }

  @Test
  public void testGetString() {
    simpleRecord.put("simple", new ModelicaString("abc\n"));
    assertEquals("abc\n", simpleRecord.get("simple", ModelicaString.class).s);
  }

  @Test
  public void testGetRecord() {
    simpleRecord.put("simple", simpleRecord);
    assertEquals(simpleRecord, simpleRecord.get("simple", ModelicaRecord.class));
  }

  @Test(expected=StackOverflowError.class)
  public void testGetRecordCyclic() {
    simpleRecord.put("simple", simpleRecord);
    simpleRecord.toString();
  }

}
