package org.openmodelica.corba;

import org.openmodelica.*;
import org.openmodelica.corba.parser.*;

public class SmartProxy extends OMCProxy {

  public SmartProxy(String corbaSessionName) {
    super(corbaSessionName);
  }

  public SmartProxy(String corbaSessionName, String grammarSyntax, boolean traceOMCCalls, boolean traceOMCStatus)
  {
    super(corbaSessionName, grammarSyntax, traceOMCCalls, traceOMCStatus);
  }

  public ModelicaObject sendModelicaExpression(Object s) throws ParseException, ConnectException {
    return sendModelicaExpression(s, SimpleTypeSpec.modelicaObject);
  }

  public <T extends ModelicaObject> T sendModelicaExpression(Object s, Class<T> c) throws ParseException, ConnectException {
    return sendModelicaExpression(s, new SimpleTypeSpec<T>(c));
  }

  public <T extends ModelicaObject> T sendModelicaExpression(Object s, TypeSpec<T> spec) throws ParseException, ConnectException {
    String str = s.toString();
    Result r = sendExpression(str);
    if (r.err != "")
      throw new ParseException("Expression " + str + " returned an error: " + r.err);
    try {
      return OMCStringParser.parse(r.res, spec);
    } catch (ParseException ex) {
      throw new ParseException("Expression " + str, ex);
    }
  }

  public <T extends ModelicaObject> T callModelicaFunction(String name, TypeSpec<T> spec, ModelicaObject... args) throws ParseException, ConnectException {
    String s = name + "(";
    for (int i=0; i<args.length; i++) {
      if (i!=0)
        s+=",";
      s+=args[i];
    }
    s+=")";

    return sendModelicaExpression(s, spec);
  }

  public <T extends ModelicaObject> T callModelicaFunction(String name, Class<T> c, ModelicaObject... args) throws ParseException, ConnectException {
    return callModelicaFunction(name, new SimpleTypeSpec<T>(c), args);
  }
  
  public ModelicaObject callModelicaFunction(String name, ModelicaObject... args) throws ParseException, ConnectException {
    return callModelicaFunction(name, SimpleTypeSpec.modelicaObject, args);
  }
}
