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


#include <sys/param.h> /* MAXPATHLEN */
#include "options.h"
#include "omcinteractiveenvironment.h"

#if defined(__MINGW32__) || defined(_MSC_VER)
#else
#include <wordexp.h>
#endif

using namespace std;

/* Local functios */
void doOMCCommunication(const string *);


/* Global variables */

const char* historyfile = NULL;
int maxhistoryfileentries = 3000;

/* Main function, handles options: -noserv -corba
   and calls appropriate function. */
int main(int argc, char* argv[])
{
  MMC_INIT();
#if defined(__MINGW32__) || defined(_MSC_VER)
  historyfile = "mosh_history";
#else
  wordexp_t p;
  char **w;
  wordexp("~/.mosh_history",&p,0);
  if (p.we_wordc == 1) {
    w = p.we_wordv;
    historyfile = strdup(w[0]);
  } else {
    historyfile = "mosh_history";
  }
  wordfree(&p);
#endif

  const char* dateStr = __DATE__; // "Mmm dd yyyy", so dateStr+7 = "yyyy"

  const string *scriptname = getFlagValue("f",argc,argv);
  if(!scriptname) {
    cout << "OMShell "
         << "Copyright 1997-" << dateStr+7 << ", Open Source Modelica Consortium (OSMC)" << endl
         << "Distributed under OMSC-PL and GPL, see www.openmodelica.org" << endl << endl
         << "To get help on using OMShell and OpenModelica, type \"help()\" and press enter" << endl;
  }
  doOMCCommunication(scriptname);

  delete scriptname;
  return EXIT_SUCCESS;
}

void doOMCCommunication(const string *scriptname)
{
  OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
  env->evalExpression("setCommandLineOptions(\"+d=shortOutput\")");
  string cmdLine = env->getResult();
  cout << "Set shortOutput flag: " << cmdLine.c_str() << std::endl;

  if (scriptname) { // Execute script and output return value
    cout << "executing <" << scriptname << ">" << endl;
    const char * str=("runScript(\""+*scriptname+"\")").c_str();
    env->evalExpression(str);
    string res = env->getResult();
    cout << res << endl;
    return;
  }

  // initialize history usage
  using_history();

  // Read the history file
  read_history(historyfile);

  bool done=false;
  while (!done) {
    char* line = readline(">>> ");
    if ( line == 0 || strncmp(line,"quit()",6) == 0 ) {
      done = true;
      if (line == 0)  { line = strdup("quit()"); }
    }
    if (strcmp(line,"\n")!=0 && strcmp(line,"") != 0) {
      if (!done) add_history(line);
      env->evalExpression(line);
      string res = env->getResult();
      cout << res << endl;
    }
    free(line);
  }
  // write history file
  write_history(historyfile);
  history_truncate_file(historyfile, maxhistoryfileentries);
}
