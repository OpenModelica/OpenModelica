/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <cstdio>
#include <strstream>

#include <readline/readline.h>
#include <readline/history.h>

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/unistd.h>
#include <sys/stat.h>

#include <netinet/in.h>
#include <netdb.h>

void open_socket(char* hostname, int port);

char * check_moshhome(void);

void init_sockaddr (struct sockaddr_in *name,
                             const char *hostname,
                             int port);
int main(int argc, char* argv[])
{
  char buf[40000];
  
  
  char * moshhome=check_moshhome();
  
  if (argc==1) 
    {
      // Starting background server.
      char systemstr[255];
      sprintf(systemstr,"%s/../modeq/modeq +d=interactive > %s/error.log 2>&1 &",
	      moshhome,moshhome);
      int res = system(systemstr);
      std::cout << "Started server using:"<< systemstr << "\n res = " << res << std::endl;
    }
  
  else if (argc == 2 && strcmp(argv[1],"-noserv")==0)
    {
      std::cout << "Skip starting server, assumed to be running" << std::endl;
    }
  else {
      std::cerr << "Incorrect number of arguments\n";
      return EXIT_FAILURE;    
  }
  
  std::cout << "Open Source Modelica 0.1" << std::endl;
  std::cout << "Copyright 2002, PELAB, Linkoping University" << std::endl;
      
  int port=29500;
  
  char* hostname ="localhost";
  // TODO: add port nr. and host as command line option
  
  
 /* Create the socket. */
  int sock = socket (PF_INET, SOCK_STREAM, 0);
  if (sock < 0)
    {
      perror ("socket (client)");
      exit (EXIT_FAILURE);
    }


  int tryconnect = 0;
  bool connected=false;
  while (!connected && tryconnect < 10 ) {
    /* Connect to the server. */
    struct sockaddr_in servername;
    init_sockaddr (&servername, hostname, port);
    if (0 > connect (sock,
		     (struct sockaddr *) &servername,
		     sizeof (servername)))
    {
      tryconnect++;
      if(connected % 3 == 0) {sleep(1); } // Sleep a second every third try...
      
    } else {
      connected=true;
    }
  }
  if (!connected) {
    perror("Error connecting to modeq server in interactive mode.\n");
    exit(1);
  }

  // Change directory for server to the same directory as client has
  char cd_buf[MAXPATHLEN];
  char cd_cmd[MAXPATHLEN+6];
  getcwd(cd_buf,MAXPATHLEN);
  sprintf(cd_cmd,"cd(\"%s\")",cd_buf);
  int cd_nbytes = write(sock,cd_cmd,strlen(cd_cmd)+1);
  int cd_recvbytes = read(sock,buf,40000);

  bool done=false;	
  while (!done) {
    char* line = readline(">>> ");
    if ( line == 0 || strcmp(line,"quit()") == 0 ) {
      done =true;
      if (line == 0)  { line = "quit()"; }
    }
    if (strcmp(line,"\n")!=0 && strcmp(line,"") != 0) { 
      add_history(line);
      int nbytes = write(sock,line,strlen(line)+1);
      if (nbytes == 0) {
	std::cout << "Error writing to server" << std::endl;
	done = true;
	break;
      }
      int recvbytes = read(sock,buf,40000);
      if (recvbytes == 0) {
	std::cout << "Recieved 0 bytes, exiting" << std::endl;
	done = true;
	break;
      }
      std::cout << buf;
    }
    free(line);
  }
  close (sock);  
  return EXIT_SUCCESS;
}

char * check_moshhome(void)
{
  char *str;
  
  str=getenv("MOSHHOME");
  if (str == NULL) {
    printf("Error, MOSHHOME not set. Set MOSHHOME to the directory where mosh resides (top dir)\n");
    exit(1);
  }
  return str;
}

void
init_sockaddr (struct sockaddr_in *name,
               const char *hostname,
               int port)
{
  struct hostent *hostinfo;

  name->sin_family = AF_INET;
  name->sin_port = htons (port);
  hostinfo = gethostbyname (hostname);
  if (hostinfo == NULL)
    {
      fprintf (stderr, "Unknown host %s.\n", hostname);
      exit (EXIT_FAILURE);
    }
  name->sin_addr = *(struct in_addr *) hostinfo->h_addr;
}
