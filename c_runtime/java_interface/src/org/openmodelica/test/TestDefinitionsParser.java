package org.openmodelica.test;

import static org.junit.Assert.*;

import java.io.File;
import java.io.FilenameFilter;
import java.lang.reflect.Constructor;
import java.net.URL;
import java.net.URLClassLoader;

import org.junit.Ignore;
import org.junit.Test;
import org.openmodelica.*;
import org.openmodelica.corba.parser.DefinitionsCreator;

public class TestDefinitionsParser {
  
  public void test_Simple_mo() throws Exception {
    File jarFile = new File("test_files/simple.jar");
    jarFile.delete();
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.program", new File(System.getProperty("user.dir")+"/test_files"), new String[]{"simple.mo"}, true);
  }
  
  @Test
  public void test_Simple_mo_classLoader() throws Exception {
    test_Simple_mo();
    // Works in Linux...
    File jarFile = new File("test_files/simple.jar");
    URLClassLoader cl = new URLClassLoader(new URL[]{new URL("jar:"+jarFile.toURI()+"!/")});
    for (URL url : cl.getURLs())
      System.out.println(url.toString());
    Class<?> c = cl.loadClass("org.openmodelica.program.test.abc");
    Constructor<?> cons = c.getConstructor(ModelicaInteger.class, ModelicaInteger.class, ModelicaReal.class);
    Object o = cons.newInstance(new ModelicaInteger(1), new ModelicaInteger(2), new ModelicaReal(3));
    assertEquals("test.abc(a=1,b=2,c=3.0)", o.toString());
  }
  
  @Test
  public void test_meta_modelica_mo() throws Exception {
    DefinitionsCreator.main("test_files/meta_modelica.jar", "org.openmodelica.metamodelicaprogram",
        new File("test_files").getAbsolutePath(), "meta_modelica.mo");
  }
  
  @Test
  public void test_OMC_Util_mo() throws Exception {
    File jarFile = new File("test_files/OMC_Util.jar");
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.OMC",
        new File("../../Compiler/").getAbsoluteFile(),
        new String[]{
      "Util.mo" /* Lots of "replaceable type X subtypeof Any;" */
      },
      true);
  }
  
  @Ignore
  @Test
  /**
   *  Absyn.mo contains things like "type XXX = tuple<YYY, ZZZ>;"
   *  And some evil class names (like Class !)
   *  However, Values.mo also pulls in this file
   */
  public void test_OMC_Absyn_mo() throws Exception  {
    File jarFile = new File("test_files/OMC_Absyn.jar");
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.OMC",
        new File("../../Compiler/").getAbsoluteFile(),
        new String[]{"Absyn.mo"},
        true);
  }
  
  @Test
  public void test_OMC_Values_mo() throws Exception  {
    File jarFile = new File("test_files/OMC_Values.jar");
    DefinitionsCreator.createDefinitions(
        jarFile,
        "org.openmodelica.OMC",
        new File("../../Compiler/").getAbsoluteFile(),
        new String[]{
          "Absyn.mo", "Values.mo"
          },
        true);
  }
  
  @Ignore
  @Test
  public void test_OMC_ClassInf_mo() throws Exception  {
    File jarFile = new File("test_files/OMC_ClassInf.jar");
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.OMC",
        new File("../../Compiler/").getAbsoluteFile(),
        new String[]{
      "Absyn.mo", "ClassInf.mo", "SCode.mo"
      },
      false);
  }
  
  class MoFilter implements FilenameFilter {
    @Override
    public boolean accept(File dir, String name) {
      return name.endsWith(".mo");
    }   
  }
  
  @Test
  public void test_OMC_mo_stripped() throws Exception {
    File jarFile = new File("test_files/OMC_full_no_functions.jar");
    File compilerDir = new File("../../Compiler/");
    String[] files = compilerDir.list(new MoFilter());
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.OMC",
        compilerDir.getAbsoluteFile(),
        files, false);
  }
  
  /*
   * Takes about 8 minutes to run...
   */
  @Ignore
  @Test
  public void test_OMC_mo() throws Exception {
    File jarFile = new File("test_files/OMC_full.jar");
    File compilerDir = new File("../../Compiler/");
    String[] files = compilerDir.list(new MoFilter());
    DefinitionsCreator.createDefinitions(jarFile, "org.openmodelica.OMC",
        compilerDir.getAbsoluteFile(),
        files, true);
  }
}
