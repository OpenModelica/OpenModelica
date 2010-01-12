package org.openmodelica.corba.parser;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Date;
import java.util.List;
import java.util.Vector;
import java.util.jar.JarEntry;
import java.util.jar.JarOutputStream;
import java.util.jar.Manifest;
import java.util.zip.CRC32;
import javax.tools.Tool;
import javax.tools.ToolProvider;

public class JarCreator {
  public static int BUFFER_SIZE = 10240;
  protected static File changeExtension(File originalFile, String newExtension) {
    String originalName = originalFile.getAbsolutePath();
    int lastDot = originalName.lastIndexOf(".");
    if (lastDot != -1) {
        return new File(originalName.substring(0, lastDot) + "." + newExtension);
    } else {
        return new File(originalName + newExtension);
    }
  }

  static private List<File> getFileListing(File dir) {
    List<File> res = new Vector<File>();
    File[] dirContent = dir.listFiles();
    for(File file : dirContent) {
      if (file.isDirectory()) {
        List<File> dirRes = getFileListing(file);
        res.addAll(dirRes);
      } else {
        res.add(file);
      }
    }
    return res;
  }


  private static void addEntry(JarOutputStream jarOut, File basePath, File source, byte[] buffer) throws IOException {
    if (source == null || !source.exists() || source.isDirectory())
      throw new IOException(source + " does not exist");
    if (!source.getAbsolutePath().startsWith(basePath.getAbsolutePath()))
      throw new IOException(source + " does not exist inside " + basePath);
    String relativePath = source.getAbsolutePath().substring(basePath.getAbsolutePath().length()+1);
    /* Backslashes are valid in Zip-files, BUT Java expects paths to be delimited by frontslashes !
     * In Windows, filenames are printed using backslashes, so we need to convert them. */
    relativePath = relativePath.replace('\\', '/');

    /* Calculate CRC32 */
    CRC32 crc = new CRC32();
    FileInputStream in = new FileInputStream(source);
    int bytesRead;
    while ((bytesRead = in.read(buffer)) != -1) {
      crc.update(buffer, 0, bytesRead);
    }
    in.close();
    /* Add Jar entry */
    JarEntry jarAdd = new JarEntry(relativePath);
    jarAdd.setSize(source.length());
    jarAdd.setCrc(crc.getValue());
    jarOut.putNextEntry(jarAdd);

    /* Write the file contents */
    in = new FileInputStream(source);
    while (true) {
      int nRead = in.read(buffer, 0, buffer.length);
      if (nRead <= 0)
        break;
      jarOut.write(buffer, 0, nRead);
    }
    in.close();
    jarOut.closeEntry();
  }
  private static void compileSources(File basePath, List<File> sourceFiles) {
    Tool javac = ToolProvider.getSystemJavaCompiler();
    if (javac == null) {
      String message = "The Java implementation couldn't find a Java compiler.";
      if (System.getProperty("os.name").startsWith("Windows"))
        message += "\nNote that Sun Java has a bug that causes getSystemJavaCompiler to return null if you run the JRE instead of JDK (which it does by default since the JRE java version is installed in system32).\n" +
                   "Call JDK_HOME/bin/java.exe instead of java.exe.";
      throw new Error(message);
    }

    for (File sourceFile : sourceFiles) {
      if (javac.run(null, null, null, "-classpath", System.getenv("OPENMODELICAHOME") + "share/java/modelica_java.jar","-sourcepath", basePath.getAbsolutePath(), sourceFile.getAbsolutePath()) != 0)
        throw new RuntimeException("Failed to compile " + sourceFile);
    }
  }

  public static void compileAndCreateJarArchive(File archiveFile, File basePath, List<File> sourceFiles) throws IOException {
    long t1 = new Date().getTime();
    byte buffer[] = new byte[BUFFER_SIZE];

    if (archiveFile == null)
      throw new IOException("Output file is null");
    if (archiveFile == null || archiveFile.isDirectory())
      throw new IOException("Cannot create file at location: " + archiveFile);

    compileSources(basePath, sourceFiles);
    archiveFile.delete();

    FileOutputStream stream = new FileOutputStream(archiveFile);
    Manifest m = new Manifest();
    m.getMainAttributes().putValue("Manifest-Version", "1.0");
    m.getMainAttributes().putValue("Created-By", JarCreator.class.getName());
    JarOutputStream jarOut = new JarOutputStream(stream);
    List<File> allFiles = getFileListing(basePath);
    for (File source : allFiles) {
      // System.out.println("Add entry: " + source);
      addEntry(jarOut, basePath, source, buffer);
    }

    jarOut.close();
    stream.close();

    /*FileInputStream fileInput = new FileInputStream(archiveFile);
    JarInputStream jarInput = new JarInputStream(fileInput, true);
    JarEntry entry;
    while ((entry = jarInput.getNextJarEntry()) != null) {
      System.out.println("Got entry: " + entry.getName());
    }
    jarInput.close();
    fileInput.close();*/

    long t2 = new Date().getTime();
    System.out.println("Created JAR archive at " + archiveFile + " in " + (t2-t1) + " ms");
  }
}