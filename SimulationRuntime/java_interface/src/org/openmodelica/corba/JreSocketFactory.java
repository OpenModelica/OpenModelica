package org.openmodelica.corba;

import com.sun.corba.se.impl.transport.DefaultSocketFactoryImpl;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;

/**
 * The JreSocketFactory is an alternative to the default one.
 * It reads the org.openmodelica.corba.timeoutval system property
 * to set the timeout.
 *
 * In order to activate this code, the following system properties must be set:
 * com.sun.CORBA.transport.ORBSocketFactoryClass = org.openmodelica.corba.JreSocketFactory
 * com.sun.CORBA.transport.ORBConnectionSocketType = Socket
 *
 */
public class JreSocketFactory extends DefaultSocketFactoryImpl
{
  @Override
  public ServerSocket createServerSocket(String type, InetSocketAddress in)
  throws IOException
  {
    ServerSocket result = super.createServerSocket(type, in);
    String val = System.getProperty("org.openmodelica.corba.timeoutval");
    if (val != null) {
      try {
        result.setSoTimeout(Integer.parseInt(val));
      } catch (NumberFormatException e) {
      }
    }
    return result;
  }

  @Override
  public Socket createSocket(String type, InetSocketAddress in)
  throws IOException
  {
    Socket result = super.createSocket(type, in);
    String val = System.getProperty("org.openmodelica.corba.timeoutval");
    if (val != null) {
      try {
        result.setSoTimeout(Integer.parseInt(val));
      } catch (NumberFormatException e) {
      }
    }
    return result;
  }
}
