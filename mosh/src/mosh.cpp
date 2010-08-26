/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
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
#include "omc_communication.h"
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
#else
#include <wordexp.h>
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

const char* historyfile = NULL;
int maxhistoryfileentries = 3000;

/* Main function, handles options: -noserv -corba
   and calls appropriate function. */
int main(int argc, char* argv[])
{
  bool corba_comm=false;
  bool noserv=false;

#if defined(__MINGW32__) || defined(_MSC_VER)
  historyfile = "mosh_history";
#else
  wordexp_t p;
  char **w;
  int i;
  wordexp("~/.mosh_history",&p,0);
  if (p.we_wordc == 1) {
    w = p.we_wordv;
    historyfile = strdup(w[0]);
  } else {
    historyfile = "mosh_history";
  }
  wordfree(&p);
#endif

  char * omhome=check_omhome();
  const char* dateStr = __DATE__; // "Mmm dd yyyy", so dateStr+7 = "yyyy"

  corba_comm = flagSet("corba",argc,argv);
  const string *scriptname = getFlagValue("f",argc,argv);
  if ((noserv=flagSet("noserv",argc,argv))&&!scriptname){
    cout << "Skip starting server, assumed to be running" << endl;
  }
  if ((corba_comm=flagSet("corba",argc,argv))&& !scriptname) {

    cout << "Using corba communication" << endl;
  }
  if(!scriptname) {
    cout << "OMShell "
	       << "Copyright 1997-" << dateStr+7 << ", Linkoping University" << endl
         << "Distributed under OMSC-PL and GPL, see www.openmodelica.org" << endl << endl
         << "To get help on using OMShell and OpenModelica, type \"help()\" and press enter" << endl;
  }
  const char* errorfile = "/tmp/omshell.log";
  if (corba_comm) {
    if (!noserv) {
      // Starting background server using corba
      char systemstr[1024];
      sprintf(systemstr, "%s/bin/omc +d=interactiveCorba > %s 2>&1 &", omhome, errorfile);
      int res = system(systemstr);
      if (!scriptname)
        cout << "Started server using:"<< systemstr << "\n res = " << res << endl;
    }
    sleep(1); // wait a second for the server to start
    doCorbaCommunication(argc,argv,scriptname);
  } else {
    if (!noserv) {
     // Starting background server using corba
      char systemstr[1024];
      sprintf(systemstr,"%s/bin/omc +d=interactive > %s 2>&1 &",
	      omhome, errorfile);
      int res = system(systemstr);
      if (!scriptname)
	cout << "Started server using:"<< systemstr << "\n res = " << res << endl;
    }
    sleep(1); // wait a second for the server to start
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
  const char *user = getenv("USER");
  if (user == NULL) { user = "nobody"; }
  sprintf (uri, "file:///tmp/openmodelica.%s.objid",user);

  CORBA::Object_var obj = orb->string_to_object(uri);

  OmcCommunication_var client = OmcCommunication::_narrow(obj);

  char cd_buf[MAXPATHLEN];
  char cd_cmd[MAXPATHLEN+6];
  if (NULL != getcwd(cd_buf,MAXPATHLEN)) {
    sprintf(cd_cmd,"cd(\"%s\")",cd_buf);
    char* res = client->sendExpression(cd_cmd);
    CORBA::string_free(res);
  }

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
      if (!done) add_history(line);
      char *res =client->sendExpression(line);
      if (done) {
        sleep(1);
      }
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
      if (!done) add_history(line);
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
