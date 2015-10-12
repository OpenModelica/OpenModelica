package org.openmodelica.corba.parser;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.LineNumberReader;

import org.openmodelica.ModelicaAny;
import org.openmodelica.ModelicaObject;
import org.openmodelica.SimpleTypeSpec;
import org.openmodelica.TypeSpec;

public class OMCStringParser {
  private static int sizeError = 300;
  public static ModelicaObject parse(String s) throws ParseException {
    return parse(s,SimpleTypeSpec.modelicaObject);
  }

  public static <T extends ModelicaObject> T parse(String s, Class<T> c) throws ParseException {
    return parse(s,new SimpleTypeSpec<T>(c));
  }
  public static <T extends ModelicaObject> T parse(String s, TypeSpec<T> spec) throws ParseException {
    LineNumberReader input = new LineNumberReader(new StringReader(s));
    try {
      return parse(input,spec);
    } catch (ParseException ex) {
      char[] cbuf = new char[sizeError];
      String str;
      try {
        input.read(cbuf,0,sizeError);
        str = new String(cbuf);
        File f = File.createTempFile("OMCStringParser", ".log");
        FileWriter fw = new FileWriter(f);
        fw.write(s);
        fw.close();
        throw new ParseException("Original string saved to file "+f+"\nFailed at line: "+input.getLineNumber()+", next characters in stream: " + str,ex);
      } catch (IOException ex2) {
        throw new ParseException(ex);
      }
    }
  }

  public static <T extends ModelicaObject> T parse(Reader input, TypeSpec<T> spec) throws ParseException {
    try {
      T o = ModelicaAny.parse(input,spec);
      System.gc();
      ModelicaAny.skipWhiteSpace(input);
      if (input.read() != -1)
        throw new ParseException("Expected EOF");
      return o;
    } catch (ClassCastException ex) {
      throw new ParseException(ex);
    } catch (IOException ex) {
      throw new ParseException(ex);
    }
  }

  public static ModelicaObject parse(File f) throws ParseException, FileNotFoundException {
    return parse(f,SimpleTypeSpec.modelicaObject);
  }

  public static <T extends ModelicaObject> T parse(File f, Class<T> c) throws ParseException, FileNotFoundException {
    return parse(f,new SimpleTypeSpec<T>(c));
  }
  public static <T extends ModelicaObject> T parse(File f, TypeSpec<T> spec) throws ParseException, FileNotFoundException {
    LineNumberReader input;
    input = new LineNumberReader(new BufferedReader(new FileReader(f)));
    try {
      return parse(input,spec);
    } catch (ParseException ex) {
      char[] cbuf = new char[sizeError];
      String str;
      try {
        input.read(cbuf,0,sizeError);
        str = new String(cbuf);
        throw new ParseException("Original file: "+f+"\nFailed at line: "+input.getLineNumber()+", next characters in stream: " + str,ex);
      } catch (IOException ex2) {
        throw new ParseException(ex);
      }
    }
  }
}
