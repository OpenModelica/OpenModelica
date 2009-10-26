package org.openmodelica.corba.parser;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.List;
import java.util.Date;
import java.util.Vector;

import org.antlr.runtime.ANTLRStringStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.stringtemplate.StringTemplate;
import org.antlr.stringtemplate.StringTemplateGroup;
import org.openmodelica.*;
import org.openmodelica.corba.SmartProxy;

public class DefinitionsCreator {
  private static File writeSTResult(StringTemplate st, File basepath, String basepackage, String packagename, String classname) {
    String filename = String.format("%s/%s/%s%s.java", basepath.getAbsolutePath(), basepackage.replace('.', '/'), (packagename != null ? packagename.replace('.', '/')+"/" : ""), classname);
    File f = new File(filename);
    try {
      f.mkdirs();
      f.delete();
      f.createNewFile();
      FileWriter fw = new FileWriter(f);
      fw.write(st.toString());
      fw.close();
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
    return f;
  }

  private static File tempBaseDir = new File(System.getProperty("java.io.tmpdir")+"/modelica.java.definitions");  

  public static Vector<File> parseString(String s, String basepackage) throws Exception {
    ANTLRStringStream input = new ANTLRStringStream(s);
    OMCorbaDefinitionsLexer lexer = new OMCorbaDefinitionsLexer(input);
    CommonTokenStream tokens = new CommonTokenStream(lexer);
    OMCorbaDefinitionsParser parser = new OMCorbaDefinitionsParser(tokens);
    
    File flog = new File("DefinitionsCreator.log");
    FileWriter fw = new FileWriter(flog, false);
    fw.write(s);
    fw.close();
    
    long t1 = new Date().getTime();
    parser.definitions();
    long t2 = new Date().getTime();
    System.out.println("Parsed input in " + (t2-t1) + " ms");
    
    if (0 != parser.getNumberOfSyntaxErrors()) {
      String msg = String.format("OMCorbaDefinitions.g found syntax errors in input. The input has been logged to %s", flog.getAbsolutePath());
      throw new Exception(msg);
    }

    String[] templates = new String[] {
        "function", "header", "myFQName", "record", "uniontype"
    };
    
    String base = "org/openmodelica/corba/parser/JavaDefinitions/";
    StringTemplateGroup group = new StringTemplateGroup("corbadefs");
    
    for (String template : templates) {
      group.defineTemplate(template, group.getInstanceOf(base+template).getTemplate());
    }
    
    Vector<File> sourceFiles = new Vector<File>();

    deleteDir(tempBaseDir);
    if (!tempBaseDir.mkdir())
      throw new RuntimeException("Couldn't mkdir " + tempBaseDir.getAbsolutePath());

    StringTemplate st;

    for (PackageDefinition pack : parser.defs) {
      long t4 = new Date().getTime();
      pack.fixTypePath(parser.st, basepackage);
      
      for (FunctionDefinition fun : pack.functions.values()) {
        st = group.getInstanceOf(base+"function");
        st.setAttribute("basepackage", basepackage);
        st.setAttribute("package", pack);
        st.setAttribute("function", fun);
        sourceFiles.add(writeSTResult(st, tempBaseDir, basepackage, pack.name, fun.name));
      }
      
      for (RecordDefinition rec : pack.records.values()) {
        st = group.getInstanceOf("record");
        st.setAttribute("basepackage", basepackage);
        st.setAttribute("package", pack);
        st.setAttribute("record", rec);
        sourceFiles.add(writeSTResult(st, tempBaseDir, basepackage, pack.name, rec.name));
      }

      for (String uniontype : pack.unionTypes.values()) {
        st = group.getInstanceOf("uniontype");
        st.setAttribute("basepackage", basepackage);
        st.setAttribute("package", pack);
        st.setAttribute("uniontype", uniontype);
        sourceFiles.add(writeSTResult(st, tempBaseDir, basepackage, pack.name, uniontype));
      }
      
      long t5 = new Date().getTime();
      System.out.println("Finished creating Java sources for package " + pack.name + " in " + (t5-t4) + " ms");
    }
    long t3 = new Date().getTime();
    System.out.println("Finished creating Java sources for all packages in " + (t3-t2) + " ms");
    return sourceFiles;
  }

  private static void deleteDir(File dir) throws IOException {
    if (dir.isDirectory()) {
      for (File child : dir.listFiles()) {
        deleteDir(child);
      }
    }
    dir.delete();
  }

  public static void createDefinitions(File archiveFile, String basePackage, File modelicaSourceDirectory, String[] modelicaSources, boolean addFunctions) throws Exception {
    if (!modelicaSourceDirectory.isDirectory())
      throw new Exception(modelicaSourceDirectory + " is not a directory");
    deleteDir(tempBaseDir);
    
    long t1 = new Date().getTime();
    SmartProxy proxy = new SmartProxy("modelica.java.definitions", "MetaModelica", true, true);
    
    try {
      System.out.println(proxy.sendModelicaExpression(String.format("cd(\"%s\")", ModelicaString.escapeOMC(modelicaSourceDirectory.getAbsolutePath()))));

      for (String source : modelicaSources) {
        if (true != proxy.sendModelicaExpression(String.format("loadFile(\"%s\")", source), ModelicaBoolean.class).b)
          throw new Exception("Failed to load " + source);
      }
      String s = proxy.sendExpression("getDefinitions("+addFunctions+")").res;
      proxy.sendModelicaExpression("clear()");
      proxy.stopServer();
      long t2 = new Date().getTime();
      System.out.println("Note: All times measured use real time, not CPU time. Scheduling and system load will affect these figures.");
      System.out.println("Got definitions (" + s.length()/1024 + "kB) from OMC in " + (t2-t1) + " ms");
      s = OMCStringParser.parse(s, ModelicaString.class).s;
      long t2_1 = new Date().getTime();
      System.out.println("Parsed the OMC String to ModelicaString " + (t2_1-t2) + " ms");
      
      Vector<File> sourceFiles = parseString(s, basePackage);
      JarCreator.compileAndCreateJarArchive(archiveFile, tempBaseDir, sourceFiles);
      long t3 = new Date().getTime();
      System.out.println("Total time to create JAR file:" + (t3-t1) + " ms");
    } catch (Exception ex) {
      proxy.stopServer();
      throw ex;
    }
    deleteDir(tempBaseDir);    
  }
  
  public static String toolUsage =
    "Usage: org.openmodelica.corba.parser.DefinitionsCreator outfile.jar base.java.package.name source_directory Model1.mo [Model2.mo ...]";
  
  public static boolean isJavaIdentifier(String s) {
    if (s.length() == 0 || !Character.isJavaIdentifierStart(s.charAt(0))) {
        return false;
    }
    for (int i=1; i<s.length(); i++) {
        if (!Character.isJavaIdentifierPart(s.charAt(i))) {
            return false;
        }
    }
    return true;
  }
  
  public static boolean isJavaPackageName(String s) {
    String[] components = s.split("\\.");
    int len = components.length;
    if (s.equals(""))
      return false;
    if (len == 1)
      return isJavaIdentifier(components[0]);
    if (!components[0].toLowerCase().equals(components[0]))
      return false;
    for (int i=1; i<len; i++)
      if (!isJavaIdentifier(components[i]))
        return false;
    return true;
  }

  
  public static void main(String... args) throws Exception {
    PrintStream out = System.out;
    
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    System.setOut(new PrintStream(baos, false));
    
    try {
      
      List<String> argsLst = Arrays.asList(args);
      
      if (argsLst.size() < 4) {
        throw new Exception("Too few arguments");
      }
      
      if (!argsLst.get(0).endsWith(".jar")) {
        throw new Exception("Is not a .jar file: " + argsLst.get(0));
      }
      File jarFile = new File(argsLst.get(0)).getAbsoluteFile();
      if (!jarFile.getParentFile().isDirectory()) {
        throw new Exception("Directory does not exist: " + jarFile.getParent());
      }
      
      if (!isJavaPackageName(argsLst.get(1))) {
        throw new Exception("Is not a valid Java package name: " + argsLst.get(1));
      }
      
      File sourceDir = new File(argsLst.get(2)).getAbsoluteFile();
      if (!sourceDir.isDirectory()) {
        throw new Exception("Source directory does not exist: " + sourceDir);
      }
      
      List<String> sourcesLst = argsLst.subList(3, argsLst.size());
      String[] sources = new String[sourcesLst.size()];
      
      for (int i=0; i<sources.length; i++) {
        String s = sourcesLst.get(i);
        if (!s.endsWith(".mo"))
          throw new Exception("Is not a .mo file: " + s);
        sources[i] = s;
      }
      
      createDefinitions(jarFile, argsLst.get(1), sourceDir, sources, true);
    } catch (Exception ex) {
      baos.flush();
      baos.writeTo(out);
      out.println(toolUsage);
      throw new Error(ex);
    } finally {
      System.setOut(out);
    }
  }
}
