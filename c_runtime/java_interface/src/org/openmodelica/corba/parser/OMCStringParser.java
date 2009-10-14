package org.openmodelica.corba.parser;

import org.antlr.runtime.*;
import org.openmodelica.ModelicaAny;
import org.openmodelica.ModelicaObject;

public class OMCStringParser {
  public static ModelicaObject parse(String s) throws ParseException {return parse(s,ModelicaObject.class);}
  public static <T extends ModelicaObject> T parse(String s, Class<T> c) throws ParseException {
    ANTLRStringStream input = new ANTLRStringStream(s);
    OMCorbaLexer lexer = new OMCorbaLexer(input);
    CommonTokenStream tokens = new CommonTokenStream(lexer);
    OMCorbaParser parser = new OMCorbaParser(tokens);
    try {
      parser.prog();
    } catch (RecognitionException e) {
      new ParseException("OMCStringParser: Failed to parse: " + s);
    } catch (ClassCastException e) {
      new ParseException("OMCStringParser: Failed to parse: " + s);
    }
    if (parser.getNumberOfSyntaxErrors() != 0)
      throw new ParseException("OMCStringParser: "+parser.getNumberOfSyntaxErrors()+" syntax errors, failed to parse:\n" + s);
    
    ModelicaObject o = parser.memory;
    try {
      return ModelicaAny.cast(o, c);
    } catch (Exception ex) {
      throw new ParseException(String.format("Failed to cast %s to %s", o.toString(), c.getName()), ex);
    }
  }
}
