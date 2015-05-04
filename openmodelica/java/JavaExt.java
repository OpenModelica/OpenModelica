import org.openmodelica.*;
import org.openmodelica.corba.SmartProxy;
import static org.openmodelica.corba.parser.OMCStringParser.parse;
import org.openmodelica.JavaExtTest.JavaTest.myRecord;
import org.openmodelica.JavaExtTest.JavaTest.myEmptyRecord;
import org.openmodelica.JavaExtTest.JavaTest.APPLE;
import org.openmodelica.JavaExtTest.JavaTest.Expression_UT;
import org.openmodelica.JavaExtTest.JavaTest.ICONST;
import org.openmodelica.JavaExtTest.JavaTest.RCONST;
import org.openmodelica.JavaExtTest.JavaTest.IFEXP;
import org.openmodelica.JavaExtTest.JavaTest.ADD;
import org.openmodelica.JavaExtTest.JavaTest.STRLEN;
import org.openmodelica.JavaExtTest.JavaTest.SUB;
import org.openmodelica.AbsynTest.Absyn.Program_UT;
import java.io.*;

public class JavaExt {

public static ModelicaInteger SumArray(ModelicaArray<ModelicaInteger> iarr) {
  ModelicaInteger sum = new ModelicaInteger(0);
  for (ModelicaInteger mi : iarr) {
    sum.i += mi.i;
  }
  return sum;
}

public static ModelicaObject ObjectToObject(ModelicaObject mo) {
  if (mo instanceof ModelicaReal) {
    ModelicaReal mr = (ModelicaReal) mo;
    return RealToReal(mr);
  } else if (mo instanceof ModelicaInteger) {
    ModelicaInteger mi = (ModelicaInteger) mo;
    return IntegerToInteger(mi);
  } else if (mo instanceof ModelicaBoolean) {
    ModelicaBoolean mb = (ModelicaBoolean) mo;
    return BooleanToBoolean(mb);
  } else if (mo instanceof ModelicaString) {
    ModelicaString ms = (ModelicaString) mo;
    return StringToString(ms);
  } else
    throw new RuntimeException("ObjectToObject failed: " + mo);
}

public static ModelicaInteger IntegerToInteger(ModelicaInteger mi) {
  return new ModelicaInteger(mi.i * 2);
}

public static ModelicaReal RealToReal(ModelicaReal mr) {
  return new ModelicaReal(mr.r * 2.5);
}

public static ModelicaBoolean BooleanToBoolean(ModelicaBoolean mb) {
  return new ModelicaBoolean(!mb.b);
}

public static ModelicaString StringToString(ModelicaString ms) {
  return new ModelicaString(ms.s + ":" + ms.s);
}

public static void testArrays(ModelicaArray<?> marr, ModelicaArray<?> marr2) {
  marr2.setObject(marr);
  marr2.unflattenModelicaArray();

  marr2.flattenModelicaArray();
  for (ModelicaObject mo : marr2) {
    mo.setObject(ObjectToObject(mo));
  }

  marr2.unflattenModelicaArray();
}

public static ModelicaReal MultipleIO(ModelicaReal i0, ModelicaReal i1, ModelicaReal i2, ModelicaReal i3, ModelicaReal o0, ModelicaReal o1, ModelicaReal o2) {
  o0.r = i0.r*1.5;
  o1.r = i1.r*2.5;
  o2.r = i2.r*3.5;
  return new ModelicaReal(i3.r*4.5);
}

public static ModelicaString RecordToString(ModelicaRecord rec) {
  return new ModelicaString(rec.toString());
}

public static void RecordToRecord(ModelicaRecord rec, ModelicaRecord out) {
  // System.out.println("rec: "+rec.get_ctor_index()+": "+rec);
  // System.out.println("out: "+out.get_ctor_index()+": "+out);
  out.setObject(rec);
}

public static ModelicaReal calcExpression(IModelicaRecord rec) throws Exception
{
  Expression_UT exp = ModelicaAny.cast(rec, Expression_UT.class);
  if (exp instanceof ADD) {
    ADD add = (ADD) exp;
    return new ModelicaReal(calcExpression(add.get_lhs()).r + calcExpression(add.get_rhs()).r);
  }
  if (exp instanceof SUB) {
    SUB sub = (SUB) exp;
    return new ModelicaReal(calcExpression(sub.get_lhs()).r - calcExpression(sub.get_rhs()).r);
  }
  if (exp instanceof ICONST) {
    ICONST iconst = (ICONST) exp;
    return new ModelicaReal(iconst.get_value().i);
  }
  if (exp instanceof RCONST) {
    RCONST rconst = (RCONST) exp;
    return rconst.get_value();
  }
  if (exp instanceof IFEXP) {
    IFEXP ifexp = (IFEXP) exp;
    if (ifexp.get_cond().b)
      return calcExpression(ifexp.get_trueExp());
    else
      return calcExpression(ifexp.get_falseExp());
  }
  if (exp instanceof STRLEN) {
    STRLEN strlen = (STRLEN) exp;
    return new ModelicaReal(strlen.get_str().s.length());
  }
  throw new Exception("Unknown Modelica Expression : " + exp);
}

public static IModelicaRecord expIdent(IModelicaRecord rec) throws Exception
{
  Expression_UT exp = ModelicaAny.cast(rec, Expression_UT.class);
  return exp;
}

public static void expIdent(IModelicaRecord rec, IModelicaRecord out) throws Exception
{
  Expression_UT exp = ModelicaAny.cast(rec, Expression_UT.class);
  out.setObject(exp);
}

/** Extend the ModelicaRecord so we can return whatever we want without warnings :)
 */
static class DummyRecordDoNotUse extends ModelicaRecord {
  public DummyRecordDoNotUse(ModelicaOption<?> none, ModelicaOption<?> some, ModelicaArray<?> arr) throws ModelicaRecordException {
    super("dummy", new String[]{"none", "some", "arr"}, none, some, arr);
  }
  @Override
  public int get_ctor_index() {
    return 3000;
  }
}

public static IModelicaRecord testAllMMCTypes() throws Exception
{
  ModelicaInteger mi = new ModelicaInteger(1);
  ModelicaReal mr = new ModelicaReal(2.5);
  ModelicaBoolean mb = new ModelicaBoolean(false);
  ModelicaString ms = new ModelicaString("OpenModelica Test");
  ModelicaTuple tup = new ModelicaTuple(mi,mr,mb,ms);
  ModelicaOption none = new ModelicaOption(null);
  ModelicaOption some = new ModelicaOption(tup);
  ModelicaArray<ModelicaObject> arr = new ModelicaArray<ModelicaObject>(mi,mr,mb,ms);
  return new DummyRecordDoNotUse(none, some, arr);
}

public static void DummyTest(ModelicaObject obj)
{
  System.out.println(obj.getClass().getName() + ": " + obj.toString());
}

private static org.openmodelica.JavaExtTest.JavaTest.GetOMCInternalValues GetOMCInternalValues;
private static SmartProxy proxy;

// Do this by a separate call because the file is used by several test cases
private static void setProxy() throws Exception {
  if (GetOMCInternalValues != null)
    return;
  
  proxy = new SmartProxy("JavaExtTest", "MetaModelica", true, false);
  // The spawned OMC shell can be in somewhat random locations...
  proxy.sendExpression(String.format("cd(\"%s\")", ModelicaString.escapeOMC(System.getProperty("user.dir"))));
  if (proxy.sendModelicaExpression("loadFile(\"JavaExt.mo\")",ModelicaBoolean.class).b != true)
    throw new Exception("Failed to load file JavaExt.mo");
  proxy.sendExpression("setLinker(\"g++ -shared -export-dynamic -g -fPIC\");");
  GetOMCInternalValues = new org.openmodelica.JavaExtTest.JavaTest.GetOMCInternalValues(proxy);
}

public static void GetValuesFromOMCThroughJava(ModelicaInteger in_i, ModelicaReal in_r, ModelicaInteger out_i, ModelicaReal out_r, ModelicaString out_s) throws Exception {
  PrintStream out = System.out;
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  System.setOut(new PrintStream(baos, false));

  setProxy();
  GetOMCInternalValues.call(in_i, in_r, out_i, out_r, out_s);
  out_s.s = "Java function got: " + out_s.s;
  
  System.setOut(out);
}

public static ModelicaBoolean RunProgramParseTest(ModelicaString filename) throws Exception {
  ModelicaObject o = parse(new File(filename.s),Program_UT.class);
  return new ModelicaBoolean(o.toString().startsWith("Absyn.PROGRAM(classes={"));
}

private static String TestFunction(String fnname, Class<? extends ModelicaObject> c, ModelicaObject expected, ModelicaObject... args) {
  try {
  ModelicaObject res = proxy.callModelicaFunction(fnname, c, args);
  
  if (expected.equals(res))
    return String.format("%-30s [OK]\n", fnname);
  return String.format("%-30s [failed]\nWrong result: %s != %s\n", fnname, expected.toString(), res.toString());
  } catch (Throwable t) {
    return String.format("%-30s [failed]\n%s\n", fnname, t.getMessage()); // ModelicaHelper.getStackTrace(t));
  }
}

public static ModelicaString RunInteractiveTestsuite() throws Exception {
  PrintStream out = System.out;
  ByteArrayOutputStream baos = new ByteArrayOutputStream();
  System.setOut(new PrintStream(baos, false));
  String res = "RunInteractiveTestsuite\n";
  
  try {
  setProxy();
  res += "Modelica Constructs:\n";
  
  res += TestFunction(
    "JavaTest.JavaIntegerToInteger", ModelicaInteger.class,
    new ModelicaInteger(2),
    new ModelicaInteger(1));
  
  res += TestFunction(
    "JavaTest.JavaRealToReal", ModelicaReal.class,
    new ModelicaReal(2.5),
    new ModelicaReal(1));
  
  res += TestFunction(
    "JavaTest.JavaBooleanToBoolean", ModelicaBoolean.class,
    new ModelicaBoolean(true),
    new ModelicaBoolean(false));
  
  res += TestFunction(
    "JavaTest.JavaStringToString", ModelicaString.class,
    new ModelicaString("Test:Test"),
    new ModelicaString("Test"));

  res += TestFunction(
    "JavaTest.JavaMultipleInOut", ModelicaTuple.class,
    new ModelicaTuple(new ModelicaReal(1.5), new ModelicaReal(5.0), new ModelicaReal(10.5), new ModelicaReal(18.0)),
    new ModelicaReal(1.0), new ModelicaReal(2.0), new ModelicaReal(3.0), new ModelicaReal(4.0));
  
  res += TestFunction(
    "JavaTest.arrayTestInteger", ModelicaArray.class,
    new ModelicaArray<ModelicaInteger>(new ModelicaInteger[]{
      new ModelicaInteger(2),
      new ModelicaInteger(4),
      new ModelicaInteger(6)
    }),
    new ModelicaArray<ModelicaInteger>(new ModelicaInteger[]{
      new ModelicaInteger(1),
      new ModelicaInteger(2),
      new ModelicaInteger(3)
    }));
  
  res += TestFunction(
     "JavaTest.arrayTestReal", ModelicaArray.class,
     ModelicaArray.createMultiDimArray(new ModelicaReal[]{
       new ModelicaReal(2.5),
       new ModelicaReal(5),
       new ModelicaReal(7.5)
     },1,1,3),
     ModelicaArray.createMultiDimArray(new ModelicaReal[]{
       new ModelicaReal(1),
       new ModelicaReal(2),
       new ModelicaReal(3)
     },1,1,3));
  
  res += TestFunction(
    "JavaTest.arrayTestReal", ModelicaArray.class,
    ModelicaArray.createMultiDimArray(new ModelicaReal[]{
      new ModelicaReal(2.5),
      new ModelicaReal(5),
      new ModelicaReal(7.5)
    },1,1,3),
    ModelicaArray.createMultiDimArray(new ModelicaReal[]{
      new ModelicaReal(1),
      new ModelicaReal(2),
      new ModelicaReal(3)
    },1,1,3));
  
  res += TestFunction(
    "JavaTest.arrayTestBoolean", ModelicaArray.class,
    ModelicaArray.createMultiDimArray(new ModelicaBoolean[]{
      new ModelicaBoolean(true),
      new ModelicaBoolean(false),
      new ModelicaBoolean(true)
    },3),
    ModelicaArray.createMultiDimArray(new ModelicaBoolean[]{
      new ModelicaBoolean(false),
      new ModelicaBoolean(true),
      new ModelicaBoolean(false)
    },3));
  
  res += TestFunction(
    "JavaTest.arrayTestString", ModelicaArray.class,
    ModelicaArray.createMultiDimArray(new ModelicaString[]{
      new ModelicaString("1:1"),
      new ModelicaString("2:2"),
      new ModelicaString("3:3")
    },3),
    ModelicaArray.createMultiDimArray(new ModelicaString[]{
      new ModelicaString("1"),
      new ModelicaString("2"),
      new ModelicaString("3")
    },3));
  
  res += TestFunction(
    "JavaTest.RecordToRecord", myRecord.class,
    new myRecord(new ModelicaInteger(1), new ModelicaReal(1.5), new ModelicaBoolean(true), new ModelicaString("test")),
    new myRecord(new ModelicaInteger(1), new ModelicaReal(1.5), new ModelicaBoolean(true), new ModelicaString("test")));
  
  res += TestFunction(
    "JavaTest.RecordToString", ModelicaString.class,
    new ModelicaString("JavaTest.myRecord(a=1,b=1.5,c=true,d=\"test\")"),
    new myRecord(new ModelicaInteger(1), new ModelicaReal(1.5), new ModelicaBoolean(true), new ModelicaString("test")));

  res += TestFunction(
    "JavaTest.EmptyRecordToString", ModelicaString.class,
    new ModelicaString("JavaTest.myEmptyRecord()"),
    new myEmptyRecord());

  res += "MetaModelica Constructs:\n";

  res += TestFunction( // lists are the same as arrays for the Java implementation
    "JavaTest.listIntegerIdent", ModelicaArray.class,
    new ModelicaArray<ModelicaInteger>(new ModelicaInteger[]{new ModelicaInteger(1), new ModelicaInteger(2)}),
    new ModelicaArray<ModelicaInteger>(new ModelicaInteger[]{new ModelicaInteger(1), new ModelicaInteger(2)}));
  
  res += TestFunction(
    "JavaTest.someToNone", ModelicaOption.class,
    new ModelicaOption<ModelicaInteger>(null),
    new ModelicaOption<ModelicaInteger>(new ModelicaInteger(1)));
  
  res += TestFunction(
    "JavaTest.tupleIdent", ModelicaTuple.class,
    new ModelicaTuple(new ModelicaInteger[]{new ModelicaInteger(1), new ModelicaInteger(2)}),
    new ModelicaTuple(new ModelicaInteger[]{new ModelicaInteger(1), new ModelicaInteger(2)}));
  
  res += TestFunction(
    "JavaTest.ApplyIntOp", ModelicaInteger.class,
    new ModelicaInteger(2),
    new org.openmodelica.JavaExtTest.JavaTest.JavaIntegerToInteger(proxy).getReference(),
    new ModelicaInteger(1));

  res += TestFunction(
    "JavaTest.anyToString", ModelicaString.class,
    new ModelicaString("OK"),
    new ModelicaInteger(1));

  res += TestFunction(
    "JavaTest.anyToString", ModelicaString.class,
    new ModelicaString("OK"),
    new ModelicaBoolean(false));

  res += TestFunction(
    "JavaTest.uniontypeIdent", APPLE.class,
    new APPLE(),
    new APPLE());

  Expression_UT exp = parse("record JavaTest.ADD\n" +
"  lhs = record JavaTest.ICONST\n" +
"  value = 2\n" +
"end JavaTest.ICONST;,\n" +
"  rhs = record JavaTest.SUB\n" +
"  lhs = record JavaTest.ICONST\n" +
"  value = 5\n" +
"end JavaTest.ICONST;,\n" +
"  rhs = record JavaTest.ICONST\n" +
"  value = 1\n" +
"end JavaTest.ICONST;\n" +
"end JavaTest.SUB;\n" +
"end JavaTest.ADD;\n", Expression_UT.class);

  res += TestFunction(
    "JavaTest.calcExpressionDummy", ModelicaInteger.class,
    new ModelicaInteger(6),
    exp);

  res += TestFunction(
    "JavaTest.calcExpressionExtJava", ModelicaReal.class,
    new ModelicaReal(6.0),
    exp);

  res += TestFunction(
    "JavaTest.calcExpressionMatchcontinue", ModelicaInteger.class,
    new ModelicaInteger(6),
    exp);

  proxy.stopServer();

  } catch (Exception ex) {
    res += "Exception:\n" + ModelicaHelper.getStackTrace(ex);
  } finally {
    System.setOut(out);
    baos.flush();
    FileOutputStream fout = new FileOutputStream("JavaExtInteractiveTrace.txt");
    baos.writeTo(fout);
    fout.close();
  }
  
  return new ModelicaString(res);
}

}
