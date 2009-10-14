package org.openmodelica.corba;

public class Result {
  public final String res;
  public final String err;
  
  public Result(String res, String err) {
    this.res = res;
    this.err = err;
  }
}
