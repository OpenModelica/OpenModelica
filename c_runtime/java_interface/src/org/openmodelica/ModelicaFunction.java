package org.openmodelica;

import org.openmodelica.corba.ConnectException;
import org.openmodelica.corba.SmartProxy;
import org.openmodelica.corba.parser.ParseException;

public abstract class ModelicaFunction {
  protected SmartProxy proxy;
  private String functionName;

  public ModelicaFunction(String functionName, SmartProxy proxy) {
    this.functionName = functionName;
    this.proxy = proxy;
  }
  
  public ModelicaFunctionReference getReference() {
    return new ModelicaFunctionReference(functionName);
  }
  
  protected <T extends ModelicaObject> T call(Class<T> c, ModelicaObject... args) throws ConnectException, ParseException {
    return proxy.callModelicaFunction(functionName, c, args);
  }
}
