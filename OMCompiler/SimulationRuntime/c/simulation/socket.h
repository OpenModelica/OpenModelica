/*
 * OpenModelica Interactive (Ver 0.75)
 * Last Modification: 26. December 2010
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: Parham.Vasaiely@gmx.de
 *
 * File description: socket.h
 * Standard Socket only for MS-Windows
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#ifndef SOCKET_H_
#define SOCKET_H_

#if defined(__MINGW32__) || defined(_MSC_VER)
  #include <winsock2.h>
#else
  #include <sys/socket.h>
  #include <sys/types.h>
  #include <netinet/in.h>
  #include <netdb.h>
#endif

// Max. number of connections
const int MAXCONNECTIONS = 5;
// Max. number of data to receive at once
const int MAXRECV = 1024;

#ifdef __cplusplus
#include <string>
// Socket class
class Socket
{
private:
  // Socket number (Socket-Descriptor)
  int m_sock;
  int m_socket_type;
  // struct sockaddr_in
  sockaddr_in m_addr;

public:
  // Constructor
  Socket();
  // virtual destructor
  virtual ~Socket();


  bool create();      // Create Socket - TCP
  bool UDP_create();  // Create Socket - UDP
  bool bind(const int port);
  bool listen() const;
  bool accept( Socket& ) const;
  bool connect(const std::string &host, const int port );

  // Data transmission - TCP
  bool send( const std::string& ) const;
  bool sendBytes(char* msg, int size) const;
  int recv ( std::string& ) const;

  // Data transmission - UDP
  bool UDP_send( const std::string&, const std::string&,
  const int port ) const;
  int UDP_recv( std::string& ) const;

  //  Close Socket
  bool close() const;

  // WSAcleanup()
  void cleanup() const;
  bool is_valid() const { return m_sock != -1; }
};

#endif /* c++ */

#endif