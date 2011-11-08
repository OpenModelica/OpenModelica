package org.openmodelica.corba.parser;

public class ParseException extends Exception {
  private static final long serialVersionUID = 7375523880830831417L;

  public ParseException(String message) {
    super(message);
  }

  public ParseException(Throwable cause) {
    super(cause);
  }

  public ParseException(String message, Throwable cause) {
    super(message, cause);
  }
}
