package org.openmodelica;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;

public class ModelicaHelper {
  public static String getStackTrace(Throwable t) {
    final Writer stringWriter = new StringWriter();
    final PrintWriter printWriter = new PrintWriter(stringWriter);
    t.printStackTrace(printWriter);
    return stringWriter.toString();
  }
}
