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
#include <sstream>

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

#include <sys/param.h> /* MAXPATHLEN */
#include "options.h"
#ifdef USE_CORBA
#include <CORBA.h>
#include "omc_communication.h"
#endif

using namespace std;

/* Local functios */
void open_socket(char* hostname, int port);

char * check_omhome(void);

void init_sockaddr (struct sockaddr_in *name,
                             const char *hostname,
                             int port);

void doCorbaCommunication(int argc, char **argv,const string *);
void doSocketCommunication(const string*);


/* Global variables */

char* historyfile = "mosh_history";
int maxhistoryfileentries = 3000;


pthread_mutex_t lock;

// Condition variable for keeping omc waiting for client requests
pthread_cond_t omc_waitformsg;
pthread_mutex_t omc_waitlock;
bool omc_waiting=false;

// Condition variable for keeping corba waiting for returnvalue from omc
pthread_cond_t corba_waitformsg;
pthread_mutex_t corba_waitlock;
bool corba_waiting=false;

char * omc_message;


/* Main function, handles options: -noserv -corba 
   and calls appropriate function. */
int main(int argc, char* argv[])
{
  bool corba_comm=false;
  bool noserv=false;
  

  char * omhome=check_omhome();

  corba_comm = flagSet("corba",argc,argv);
  const string *scriptname = getFlagValue("f",argc,argv);
  if ((noserv=flagSet("noserv",argc,argv))&&!scriptname){
    cout << "Skip starting server, assumed to be running" << endl;
  }
  if ((corba_comm=flagSet("corba",argc,argv))&& !scriptname) {

    cout << "Using corba communication" << endl;
  }  
  if(!scriptname) {
    cout << "Open Source Modelica 1.3.2" << endl
	 << "Copyright 1997-2006, PELAB, Linkoping University" << endl << endl
	 << "To get help on using Mosh and OpenModelica, type \"help()\" and press enter" << endl;
  }
  if (corba_comm) {
    if (!noserv) {
      // Starting background server using corba
      char systemstr[1024];
      sprintf(systemstr, "%s/omc +d=interactiveCorba > %s/error.log 2>&1 &", omhome, omhome);
      int res = system(systemstr);
      if (!scriptname)
	cout << "Started server using:"<< systemstr << "\n res = " << res << endl;
    }
    doCorbaCommunication(argc,argv,scriptname);
  } else {
    if (!noserv) {
     // Starting background server using corba
      char systemstr[1024];
      sprintf(systemstr,"%s/omc +d=interactive > %s/error.log 2>&1 &",
	      omhome, omhome);
      int res = system(systemstr);
      if (!scriptname)
	cout << "Started server using:"<< systemstr << "\n res = " << res << endl;
    } 
    doSocketCommunication(scriptname);
  }

  delete scriptname;
  return EXIT_SUCCESS;
}

#ifdef USE_CORBA
void doCorbaCommunication(int argc, char **argv, const string *scriptname)
{
 CORBA::ORB_var orb = CORBA::ORB_init(argc,argv);  
  char uri[300];
  char *user = getenv("USER");
  if (user == NULL) { user = "nobody"; }
  sprintf (uri, "file:///tmp/openmodelica.%s.objid",user);

  CORBA::Object_var obj = orb->string_to_object(uri);

  OmcCommunication_var client = OmcCommunication::_narrow(obj);

  char cd_buf[MAXPATHLEN];
  char cd_cmd[MAXPATHLEN+6];
  getcwd(cd_buf,MAXPATHLEN);
  sprintf(cd_cmd,"cd(\"%s\")",cd_buf);
  char* res = client->sendExpression(cd_cmd);
  CORBA::string_free(res);

  if (scriptname) { // Execute script and output return value 
    const char * str=("runScript(\""+*scriptname+"\")").c_str();
    char *res=client->sendExpression(str);
    CORBA::string_free(res);
    cout << res << endl;
    return;
  }

  if (CORBA::is_nil(client)) {
    cerr << "Could not locate omc server." << endl;
    exit(1);
  }
  // initialize history usage
  using_history();

  // Read the history file
  read_history(historyfile);

  bool done=false;	
  while (!done) {
    char* line = readline(">>> ");
    if ( line == 0 || strcmp(line,"quit()") == 0 ) {
      done =true;
      if (line == 0)  { line = strdup("quit()"); }
    }
    if (strcmp(line,"\n")!=0 && strcmp(line,"") != 0) { 
      add_history(line);
      char *res =client->sendExpression(line);
      cout << res;
      CORBA::string_free(res);
    }
    free(line);
  }
  // write history file
  write_history(historyfile);
  history_truncate_file(historyfile, maxhistoryfileentries);
}
#else
void doCorbaCommunication(int argc, char **argv, const string *scriptname)
{
  cerr << "CORBA support disabled. configure with --with-CORBA to enable and recompile." << endl;
  exit(1);
}
#endif

void doSocketCommunication(const string * scriptname)
{
  int port=29500; 
  char buf[40000];
  
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
    perror("Error connecting to omc server in interactive mode.\n");
    exit(1);
  }

  // Change directory for server to the same directory as client has
  char cd_buf[MAXPATHLEN];
  char cd_cmd[MAXPATHLEN+6];
  getcwd(cd_buf,MAXPATHLEN);
  sprintf(cd_cmd,"cd(\"%s\")",cd_buf);
  write(sock,cd_cmd,strlen(cd_cmd)+1);
  read(sock,buf,40000);

  if (scriptname) {
    const char *str= ("runScript("+*scriptname+")").c_str();
    int nbytes = write(sock,str,strlen(str)+1);
    int recvbytes = read(sock,buf,40000);
    cout << buf << endl;
    return;
  }
  // initialize history usage
  using_history();

  // Read the history file
  read_history(historyfile);


  bool done=false;	
  while (!done) {
    char* line = readline(">>> ");
    if ( line == 0 || strcmp(line,"quit()") == 0 ) {
      done =true;
      if (line == 0)  { line = strdup("quit()"); }
    }
    if (strcmp(line,"\n")!=0 && strcmp(line,"") != 0) { 
      add_history(line);
      int nbytes = write(sock,line,strlen(line)+1);
      if (nbytes == 0) {
	cout << "Error writing to server" << endl;
	done = true;
	break;
      }
      int recvbytes = read(sock,buf,40000);
      if (recvbytes == 0) {
	cout << "Recieved 0 bytes, exiting" << endl;
	done = true;
	break;
      }
      cout << buf;
    }
    free(line);
  }
  close (sock);

  // write history file
  write_history(historyfile);
  history_truncate_file(historyfile, maxhistoryfileentries);
}


char * check_omhome(void)
{
  char *str;
  
  str=getenv("OPENMODELICAHOME");
  if (str == NULL) {
    printf("Error, OPENMODELICAHOME not set. Set OPENMODELICAHOME to the root directory of the OpenModlica installation\n");
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
