/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: socket.h
 * Standard Socket only for MS-Windows
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#ifndef SOCKET_H_
#define SOCKET_H_
#include <string>

#if defined(__MINGW32__) || defined(_MSC_VER)
	#include <winsock.h>
#else
	#include <sys/socket.h>
	#include <sys/types.h>
	#include <netinet/in.h>
	#include <netdb.h>
#endif

// Max. Anzahl Verbindungen
const int MAXCONNECTIONS = 5;
// Max. Anzahl an Daten die aufeinmal empfangen werden
const int MAXRECV = 1024;

// Die Klasse Socket
class Socket {
   private:
   // Socketnummer (Socket-Deskriptor)
   int m_sock;
	 int m_socket_type;
   // Struktur sockaddr_in
   sockaddr_in m_addr;
	 
   public:
   // Konstruktor
   Socket();
   // virtueller Destruktor
   virtual ~Socket();

   // Socket erstellen - TCP
   bool create();
   // Socket erstellen - UDP
   bool UDP_create();
   bool bind( const int port );
   bool listen() const;
   bool accept( Socket& ) const;
   bool connect ( const std::string &host, const int port );
   // Datenübertragung - TCP
   bool send ( const std::string& ) const;
   int recv ( std::string& ) const;
   // Datenübertragung - UDP
   bool UDP_send( const std::string&, const std::string&,
                  const int port ) const;
   int UDP_recv( std::string& ) const;
   // Socket schließen
   bool close() const;
   // WSAcleanup()
   void cleanup() const;
   bool is_valid() const { return m_sock != -1; }
};
#endif
