package org.openmodelica.test;

import static org.junit.Assert.*;
import static org.openmodelica.corba.parser.OMCStringParser.parse;

import java.util.Arrays;

import org.junit.Test;
import org.openmodelica.ModelicaArray;
import org.openmodelica.ModelicaBoolean;
import org.openmodelica.ModelicaInteger;
import org.openmodelica.ModelicaObject;
import org.openmodelica.ModelicaOption;
import org.openmodelica.ModelicaReal;
import org.openmodelica.ModelicaRecord;
import org.openmodelica.ModelicaRecordException;
import org.openmodelica.ModelicaString;
import org.openmodelica.ModelicaTuple;
import org.openmodelica.corba.parser.*;

public class TestParser {
  
  @Test public void simpleInteger() throws ParseException {
    /* We test 32-bit values although OMC only supports 31-bit integers at the moment */
    int[] testValues = {-2147483648, 2147483647, 0, 42, 1337, -17};
    for (int i : testValues) {
      ModelicaInteger mi = parse(Integer.toString(i), ModelicaInteger.class);
      assertEquals(i, mi.i);
    }
  }
  
  @Test public void simpleEquals() throws ParseException {
    assertEquals(new ModelicaInteger(1), new ModelicaInteger(1));
    assertEquals(new ModelicaReal(1), new ModelicaReal(1));
    assertEquals(new ModelicaBoolean(true), new ModelicaBoolean(true));
    assertEquals(new ModelicaString("true"), new ModelicaString("true"));
    assertEquals(parse("{1,2,3}"), parse("{1,2,3}"));
    assertEquals(parse("(1,2,3)"), parse("(1,2,3)"));
    assertEquals(parse("record abc a=1,b=2,c=3 end abc;"), parse("record abc a=1,b=2,c=3 end abc;"));
    assertFalse(parse("").equals(parse(""))); // Void never equals anything
  }
  
  @Test public void simpleDouble() throws ParseException {
    double[] testValues = {1.23456789, -1.23456789};
    double delta = 0.0000000001;
    for (double d : testValues) {
      ModelicaReal mr = parse(Double.toString(d), ModelicaReal.class);
      assertEquals(d, mr.r, delta);
    }
  }
  
  @Test public void hardDouble() throws ParseException {
    String[] testValues = {
        "22.5", "3.141592653589793", "1.2E-35",
        "13.", "13E0", "1.3e1", ".13E2",
        "0.777777777777777777777777777777777777777",
        };
    double[] testValuesExpected = {
        22.5, 3.141592653589793, 1.2E-35,
        13., 13E0, 1.3e1, .13E2,
        7.0/9.0
        };
    double delta = 0.000000000000000000000000000000000001;
    for (int i=0; i<testValues.length; i++) {
      ModelicaReal mr = parse(testValues[i], ModelicaReal.class);
      assertEquals(testValuesExpected[i], mr.r, delta);
      mr = (ModelicaReal) parse("-"+testValues[i]);
      assertEquals(-testValuesExpected[i], mr.r, delta);
    }
  }
  
  @Test public void simpleBoolean() throws ParseException {
    boolean[] testValues = {true, false};
    for (boolean b : testValues) {
      ModelicaBoolean mb = parse(Boolean.toString(b), ModelicaBoolean.class);
      assertEquals(b, mb.b);
    }
  }
  
  @Test public void intArray() throws ParseException {
    String[] testValues = {"  {1,2,3}", "{4 , 5,6}  ", "{}", "{   }"};
    ModelicaArray<?>[] expectedValues = new ModelicaArray[] {
        new ModelicaArray<ModelicaInteger>
        (
            new ModelicaInteger(1),
            new ModelicaInteger(2),
            new ModelicaInteger(3)
        ),
        new ModelicaArray<ModelicaInteger>(
            new ModelicaInteger(4),
            new ModelicaInteger(5),
            new ModelicaInteger(6)
        ),
        new ModelicaArray<ModelicaInteger>(),
        new ModelicaArray<ModelicaInteger>(),
    };
    for (int i=0; i<testValues.length; i++) {
      ModelicaArray<?> mia;
      mia = parse(testValues[i], ModelicaArray.class);
      assertEquals(expectedValues[i], mia);
    }
  }
  
  @SuppressWarnings("unchecked")
  @Test public void intMulDimArray() throws ParseException {
    String[] testValues = {"{{1,2,3},{4,5,6}}"};
    String[] expectedValues = {"{{1,2,3},{4,5,6}}"};
    for (int i=0; i<testValues.length; i++) {
      ModelicaArray<ModelicaArray<ModelicaInteger>> mia;
      mia = (ModelicaArray<ModelicaArray<ModelicaInteger>>) parse(testValues[i]);
      assertEquals(1, mia.get(0).get(0).i);
      assertEquals(expectedValues[i], mia.toString());
    }
  }
  
  @SuppressWarnings("unchecked")
  @Test public void intCreateMulDimArray() throws ParseException {
    ModelicaInteger[] values = new ModelicaInteger[2*3*4];
    for (int i=0; i<2*3*4; i++)
      values[i] = new ModelicaInteger(i);
    ModelicaArray miarr = ModelicaArray.createMultiDimArray(Arrays.asList(values),2,3,4);
    assertEquals("{{{0,1,2,3},{4,5,6,7},{8,9,10,11}},{{12,13,14,15},{16,17,18,19},{20,21,22,23}}}", miarr.toString());
    assertEquals(parse("{{{0,1,2,3},{4,5,6,7},{8,9,10,11}},{{12,13,14,15},{16,17,18,19},{20,21,22,23}}}"), miarr);
  }
  
 @Test public void realArray() throws ParseException {
    String[] testValues = {"  {1.0,2.0,3.0}", "{4.0 , 5.0,6.0}  ", "{}", "{   }"};
    ModelicaArray<?>[] expectedValues = new ModelicaArray[] {
        new ModelicaArray<ModelicaReal>
        (
            new ModelicaReal(1),
            new ModelicaReal(2),
            new ModelicaReal(3)
        ),
        new ModelicaArray<ModelicaReal>(
            new ModelicaReal(4),
            new ModelicaReal(5),
            new ModelicaReal(6)
        ),
        new ModelicaArray<ModelicaReal>(),
        new ModelicaArray<ModelicaReal>(),
    };
    for (int i=0; i<testValues.length; i++) {
      ModelicaArray<?> mda;
      mda = parse(testValues[i], ModelicaArray.class);
      assertEquals(expectedValues[i], mda);
    }
  }
  
  @Test public void simpleRecord() throws ParseException, ModelicaRecordException {
    String test = "record ABC\na = 13, b = record DEF d=1,e=2,f=4 end DEF;,c=4.0 end ABC;";
    ModelicaRecord expected = new ModelicaRecord(
        "ABC", new String[]{"a","b","c"},
        new ModelicaInteger(13),
        new ModelicaRecord(
            "DEF", new String[]{"d","e","f"},
            new ModelicaInteger(1),
            new ModelicaInteger(2),
            new ModelicaInteger(4)
        ),
        new ModelicaReal(4)
    );
    assertEquals(expected, parse(test));
  }
  
  @Test(expected=ParseException.class)
  public void unbalancedRecord() throws ParseException {
    String test = "record ABC a = 13, b = record DEF d=1,e=2,f=4 end ABC;,c=4.0 end DEF;";
    parse(test);
  }
  
  @Test(expected=ParseException.class)
  public void intDoubleArray() throws ParseException {
    ModelicaObject arr = parse("{1,2.0}");
    System.out.println(String.format("intDoubleArray: %s\n%s", arr, arr.getClass()));
  }
  
  @Test(expected=ParseException.class)
  public void twoValues() throws ParseException {
    System.out.println(parse("1 2"));
  }
  
  @Test public void optionNone() throws ParseException {
    ModelicaOption<ModelicaInteger> test = new ModelicaOption<ModelicaInteger>(null);
    String expected = "NONE()";
    ModelicaObject res = parse(test.toString());
    assertEquals(expected, res.toString());
    assertEquals(test, res);
  }
  
  @Test public void optionSome() throws ParseException {
    ModelicaOption<ModelicaInteger> test = new ModelicaOption<ModelicaInteger>(new ModelicaInteger(1));
    String expected = "SOME(1)";
    ModelicaObject res = parse(test.toString());
    assertEquals(expected, res.toString());
    assertEquals(test, res);
  }
  
  @Test public void simpleTuple() throws ParseException {
    ModelicaTuple test = new ModelicaTuple(new ModelicaInteger(1),new ModelicaInteger(2),new ModelicaInteger(3));
    String expected = "(1,2,3)";
    ModelicaObject res = parse(test.toString());
    assertEquals(expected, res.toString());
    assertEquals(test, res);
  }
  
  @Test public void simpleUnionType() throws ParseException {
   ABC_UT expected = new abc(new ModelicaInteger(1),new ModelicaInteger(2),new ModelicaReal(3));
   String test = "record test.abc a=1, b=2, c=3.0 end test.abc;";
   ABC_UT res = parse(test, ABC_UT.class);
   assertEquals(expected.toString(), res.toString());
   assertEquals(expected, res); 
   assertEquals(1, ((abc)res).get_a().i);
  }
  
  @Test public void nestedUnionType() throws ParseException {
    ABC_UT expected = new ABC_CONTAINER(new ABC_CONTAINER(new abc(new ModelicaInteger(1),new ModelicaInteger(2),new ModelicaReal(3))));
    String test = "record test.ABC_CONTAINER a = record test.ABC_CONTAINER a = record test.abc a=1, b=2, c=3.0 end test.abc; end test.ABC_CONTAINER; end test.ABC_CONTAINER;";
    ABC_UT res = parse(test, ABC_UT.class);
    assertEquals(expected.toString(), res.toString());
    assertEquals(expected, res);
    assertEquals(2, ((abc)((ABC_CONTAINER)((ABC_CONTAINER)res).get_a()).get_a()).get_b().i);
   }
}
