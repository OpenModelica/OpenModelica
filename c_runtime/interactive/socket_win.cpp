/*
 * OpenModelica Interactive (Ver 0.7)
 * Last Modification: 3. October 2009
 *
 * Developed by:
 * EADS IW Germany
 * Developer: Parham Vasaiely
 * Contact: vasaie_p@informatik.haw-hamburg.de
 *
 * File description: socket.cpp
 * Standard Socket only for MS-Windows
 *
 * Full specification available in the bachelor thesis of Parham Vasaiely
 * "Interactive Simulation of SysML Models using Modelica" (Chapter 5)
 */

#include <cstdlib>
#include <winsock.h>
#include <io.h>
#include <iostream>
#include "socket.h"
using namespace std;

// Konstruktor
Socket::Socket() : m_sock(0) {
   // Winsock.DLL Initialisieren
   WORD wVersionRequested;
   WSADATA wsaData;
   wVersionRequested = MAKEWORD (1, 1);
   if (WSAStartup (wVersionRequested, &wsaData) != 0) {
      cout << "Fehler beim Initialisieren von Winsock"
           << endl;
      exit(1);
   }
}

// Destruktor
Socket::~Socket() {
   if ( is_valid() )
      ::closesocket ( m_sock );
}

// Erzeugt das Socket  - TCP
bool Socket::create() {
   m_sock = ::socket(AF_INET,SOCK_STREAM,0);
   if (m_sock < 0) {
      cout << "Fehler beim Anlegen eines Socket" << endl;
      exit(1);
   }
   return true;
}

// Erzeugt das Socket  - UDP
bool Socket::UDP_create() {
   m_sock = ::socket(AF_INET,SOCK_DGRAM,0);
   if (m_sock < 0) {
      cout << "Fehler beim Anlegen eines Socket" << endl;
      exit(1);
   }
   return true;
}

// Erzeugt die Bindung an die Serveradresse
// - genauer an einen bestimmten Port
bool Socket::bind( const int port ) {
   if ( ! is_valid() ) {
      return false;
   }
   m_addr.sin_family = AF_INET;
   m_addr.sin_addr.s_addr = INADDR_ANY;
   m_addr.sin_port = htons ( port );

   int bind_return = ::bind ( m_sock,
      ( struct sockaddr * ) &m_addr, sizeof ( m_addr ) );
   if ( bind_return == -1 ) {
      return false;
   }
   return true;
}

// Teile dem Socket mit, dass Verbindungswünsche
// von Clients entgegengenommen werden
bool Socket::listen() const {
   if ( ! is_valid() ) {
      return false;
   }
   int listen_return = ::listen ( m_sock, MAXCONNECTIONS );
   if ( listen_return == -1 ) {
      return false;
   }
  return true;
}

// Bearbeite die Verbindungswünsche von Clients
// Der Aufruf von accept() blockiert solange,
// bis ein Client Verbindung aufnimmt
bool Socket::accept ( Socket& new_socket ) const {
   int addr_length = sizeof ( m_addr );
   new_socket.m_sock = ::accept( m_sock,
      ( sockaddr * ) &m_addr, ( int * ) &addr_length );
   if ( new_socket.m_sock <= 0 )
      return false;
   else
      return true;
}

// Baut die Verbindung zum Server auf
bool Socket::connect( const string &host, const int port ) {
   if ( ! is_valid() )
      return false;
   struct hostent *host_info;
   unsigned long addr;
   memset( &m_addr, 0, sizeof (m_addr));
   if ((addr = inet_addr( host.c_str() )) != INADDR_NONE) {
       /* argv[1] ist eine numerische IP-Adresse */
       memcpy( (char *)&m_addr.sin_addr,
               &addr, sizeof(addr));
   }
   else {
       /* Für den Fall der Fälle: Wandle den Servernamen  *
        * bspw. "localhost" in eine IP-Adresse um         */
       host_info = gethostbyname( host.c_str() );
       if (NULL == host_info) {
          cout << "Unbekannter Server" << endl;
          exit(1);
       }
       memcpy( (char *)&m_addr.sin_addr, host_info->h_addr,
                host_info->h_length);
   }
   m_addr.sin_family = AF_INET;
   m_addr.sin_port = htons( port );

   int status = ::connect ( m_sock,
      ( sockaddr * ) &m_addr, sizeof ( m_addr ) );

  if ( status == 0 )
    return true;
  else
    return false;
}

// Daten versenden via TCP
bool Socket::send( const string &s ) const {
   int status = ::send ( m_sock, s.c_str(), s.size(),  0 );
   if ( status == -1 ) {
      return false;
   }
   else {
      return true;
   }
}

// Daten empfangen via TCP
int Socket::recv ( string& s ) const {
  char buf [ MAXRECV + 1 ];
  s = "";
  memset ( buf, 0, MAXRECV + 1 );

  int status = ::recv ( m_sock, buf, MAXRECV, 0 );
  if ( status > 0 || status != SOCKET_ERROR ) {
     s = buf;
     return status;
  }
  else {
     cout << "Fehler in Socket::recv" << endl;
     exit(1);
     return 0;
  }
}

// Daten versenden via UDP
bool Socket::UDP_send( const string &addr, const string &s, const int port ) const {
   struct sockaddr_in addr_sento;
   struct hostent *h;
   int rc;

   h = gethostbyname(addr.c_str());
   if (h == NULL) {
      cout << "Unbekannter Host?" << endl;
      exit(1);
   }
   addr_sento.sin_family = h->h_addrtype;
   memcpy ( (char *) &addr_sento.sin_addr.s_addr,
            h->h_addr_list[0], h->h_length);
   addr_sento.sin_port = htons (port);
   rc = sendto( m_sock, s.c_str(), s.size(), 0,
                 (struct sockaddr *) &addr_sento,
                  sizeof (addr_sento));
   if (rc == SOCKET_ERROR) {
      cout << "Konnte Daten nicht senden - sendto()"
           << endl;
      exit(1);
   }
   return true;
}

// Daten empfangen vie UDP
int Socket::UDP_recv( string& s ) const {
   struct sockaddr_in addr_recvfrom;
   int len, n;
   char buf [ MAXRECV + 1 ];
   s = "";
   memset ( buf, 0, MAXRECV + 1 );
   len = sizeof (addr_recvfrom);
   n = recvfrom ( m_sock, buf, MAXRECV, 0,
                  (struct sockaddr *) &addr_recvfrom, &len );
   if (n == SOCKET_ERROR){
      cout << "Fehler bei recvfrom()" << endl;
      exit(1);
      return 0;
   }
   else {
      s = buf;
      return n;
   }
}

// Winsock.dll freigeben
void Socket::cleanup() const {
   /* Cleanup Winsock */
   WSACleanup();
}

// Socket schließen und Winsock.dll freigeben
bool Socket::close() const {
   closesocket(m_sock);
   cleanup();
   return true;
}
