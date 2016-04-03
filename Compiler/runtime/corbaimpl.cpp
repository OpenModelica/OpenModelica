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

// includes for both linux and windows
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>

#ifndef NOMICO
#include "omc_communication.h"
#include "omc_communication_impl.h"
#endif //NOMICO

extern "C" {
#include <stdio.h>
#include "settingsimpl.h"
#include "systemimpl.h"

char* corbaObjectReferenceFilePath = 0;
char* corbaSessionName = 0;
const char* omc_cmd_message="";
const char* omc_reply_message="";

#ifndef NOMICO
CORBA::ORB_var orb;
PortableServer::POA_var poa;
CORBA::Object_var poaobj;
PortableServer::POAManager_var mgr;
PortableServer::POA_var omcpoa;
CORBA::PolicyList pl;
CORBA::Object_var omc_ref;
CORBA::String_var str;
#if defined(__MINGW32__) || defined(_MSC_VER)
PortableServer::ObjectId_var *oid;
#else
PortableServer::ObjectId_var oid;
#endif
OmcCommunication_impl* server;
#endif // NOMICO

/* the file in which we have to dump the Corba IOR ID */
std::ostringstream objref_file;

void CorbaImpl__setObjectReferenceFilePath(const char *path)
{
  if (strlen(path) == 0) return;
  if (corbaObjectReferenceFilePath) free(corbaObjectReferenceFilePath);

  if (*path) {
    corbaObjectReferenceFilePath = strdup(path);
  } else {
    corbaObjectReferenceFilePath = NULL;
  }
}

void CorbaImpl__setSessionName(const char *name)
{
  if (strlen(name) == 0) return;
  if (corbaSessionName) free(corbaSessionName);

  if (*name) {
    corbaSessionName = strdup(name);
  } else {
    corbaSessionName = NULL;
  }
}

char** construct_dummy_args(int argc, const char* argv[])
{
  char** args = new char*[argc];

  for(int i = 0; i < argc; ++i) {
    args[i] = strdup(argv[i]);
  }

  return args;
}

void free_dummy_args(int argc, char** argv)
{
  for(int i = 0; i < argc; ++i) {
    free(argv[i]);
  }
  delete [] argv;
}


// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

using namespace std;

CRITICAL_SECTION lock;
HANDLE omc_client_request_event;
HANDLE omc_return_value_ready;
CRITICAL_SECTION clientlock;

DWORD WINAPI runOrb(void* arg);

void display_omc_error(DWORD lastError, LPTSTR lpszMessage)
{
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        lastError,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT,
        (lstrlen((LPCTSTR)lpMsgBuf)+lstrlen((LPCTSTR)lpszMessage)+40)*sizeof(TCHAR));
    wsprintf((LPTSTR)lpDisplayBuf,
        TEXT("%s failed with error %d:\n%s"),
        lpszMessage, lastError, lpMsgBuf);
    MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("OpenModelica OMC Error"), MB_ICONERROR);

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
    ExitProcess(lastError);
}

DWORD WINAPI runOrb(void* arg) {
#ifndef NOMICO
  try
  {
    orb->run();
  } catch (CORBA::Exception&) {
    // run can throw exception when other side closes.
  }

  if (poa)
    poa->destroy(TRUE,TRUE);
  if (server)
    delete server;

#endif // NOMICO
  return 0;
}

/* Windows version */
int CorbaImpl__initialize()
{
#ifndef NOMICO
  int argc = 4;
  const char *dummyArgv[] = {
    "-ORBendPoint",
    "giop:tcp:127.0.0.1:0",
    "-ORBgiopMaxMsgSize",
    "2147483647"
  };
  string omc_client_request_event_name   = "omc_client_request_event";
  string omc_return_value_ready_name     = "omc_return_value_ready";
  DWORD lastError = 0;
  char* errorMessage = (char*)"OpenModelica OMC could not be started.\nAnother OMC is already running.\n\n\
Please stop or kill the other OMC process first!\nOpenModelica OMC will now exit.\n\nCorba.initialize()";

  /* create the events and locks with different names if we have a corba session */
  if (corbaSessionName != NULL) /* yehaa, we have a session name */
  {
    omc_client_request_event_name   += corbaSessionName;
    omc_return_value_ready_name     += corbaSessionName;
  }
  omc_client_request_event = CreateEvent(NULL,FALSE,FALSE,omc_client_request_event_name.c_str());
  lastError = GetLastError();
  if (omc_client_request_event == NULL || (omc_client_request_event != NULL && lastError == ERROR_ALREADY_EXISTS))
  {
    display_omc_error(lastError, errorMessage);
    fprintf(stderr, "CreateEvent '%s' error: %d\n", omc_client_request_event_name.c_str(), lastError);
    return 1;
  }
  omc_return_value_ready = CreateEvent(NULL,FALSE,FALSE,omc_return_value_ready_name.c_str());
  lastError = GetLastError();
  if (omc_return_value_ready == NULL && (omc_return_value_ready != NULL && lastError == ERROR_ALREADY_EXISTS))
  {
    display_omc_error(lastError, errorMessage);
    fprintf(stderr, "CreateEvent '%s' error: %d\n", omc_return_value_ready_name.c_str(), lastError);
    return 1;
  }
  InitializeCriticalSection(&lock);
  InitializeCriticalSection(&clientlock);

  char **argv = construct_dummy_args(argc, dummyArgv);
  orb = CORBA::ORB_init(argc, argv, "omniORB4");
  free_dummy_args(argc, argv);

  poaobj = orb->resolve_initial_references("RootPOA");
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  /* get the temporary directory */
  /* if corbaObjectReferenceFilePath value is set and is a valid directory then use it for dumping the object reference file. */
  const char* tempPath = NULL;
  if (SystemImpl__directoryExists(corbaObjectReferenceFilePath))
    tempPath = corbaObjectReferenceFilePath;
  else
    tempPath = SettingsImpl__getTempDirectoryPath();
  /* start omc differently if we have a corba session name */
  if (corbaSessionName != NULL) /* yehaa, we have a session name */
  {
    /*
     * The RootPOA has the SYSTEM_ID policy, but we want to assign our
     * own IDs, so create a new POA with the USER_ID policy
     *  After we got the RootPOA manager, we need our own POA
     */
    pl.length(1);
    pl[0] = poa->create_id_assignment_policy (PortableServer::USER_ID);
    omcpoa = poa->create_POA ("OMCPOA", mgr, pl);

    oid = new PortableServer::ObjectId_var(PortableServer::string_to_ObjectId (corbaSessionName));
    server = new OmcCommunication_impl();
    omcpoa->activate_object_with_id(*oid, server);
    /*
     * build the reference to store in the file
     */
    omc_ref = omcpoa->id_to_reference (oid->in());
    objref_file << tempPath << "/openmodelica.objid." << corbaSessionName;
  }
  else /* we don't have a session name, start OMC normaly */
  {
      server = new OmcCommunication_impl();
      oid = new PortableServer::ObjectId_var(poa->activate_object(server));
      omc_ref = poa->id_to_reference (oid->in());
      objref_file << tempPath << "/openmodelica.objid";
  }

  str = (const char*)orb->object_to_string (omc_ref.in());
  /* Write reference to file */
  ofstream of (objref_file.str().c_str());
  of << str.in() << endl;
  of.close ();

  mgr->activate();

  // Start thread that listens on incomming messages.
  HANDLE orb_thr_handle;
  DWORD orb_thr_id;

  orb_thr_handle = CreateThread(NULL, 0, runOrb, NULL, 0, &orb_thr_id);

  std::cout << "Created server." << std::endl;
  std::cout << "Dumped Corba IOR in file: " << objref_file.str().c_str() << std::endl;
  std::cout << "Started the Corba ORB thread with id: " << orb_thr_id << std::endl;
  std::cout << "Created Events: " << omc_client_request_event_name.c_str() << ", " << omc_return_value_ready_name.c_str() << std::endl;
#endif //NOMICO
  return 0;
}

#else
/*******************************************************
 * *****************************************************
 *                 linux stuff here
 * *****************************************************
 * *****************************************************
 */

#include <pthread.h>

using namespace std;

pthread_mutex_t omc_corba_lock;
pthread_mutex_t omc_corba_clientlock;

// Condition variable for keeping omc waiting for client requests
pthread_cond_t omc_waitformsg;
pthread_mutex_t omc_waitlock;
bool omc_waiting=false;

// Condition variable for keeping corba waiting for returnvalue from omc
pthread_cond_t corba_waitformsg;
pthread_mutex_t corba_waitlock;
bool corba_waiting=false;

void* runOrb(void* arg)
{
#ifndef NOMICO
  try {
    orb->run();
  } catch (CORBA::Exception&) {
    // run can throw exception when other side closes.
  }

  try {
    if (poa) {
      poa->destroy(true,true);
    }
  } catch (CORBA::Exception&) {
    // silently ignore errors here
  }

  if (server) {
      delete server;
  }
#endif // NOMICO
  return NULL;
}

/* Linux version */
int CorbaImpl__initialize()
{
#ifndef NOMICO
  int argc = 4;
  const char *dummyArgv[] = {
    "-ORBendPoint",
    "giop:tcp:127.0.0.1:0",
    "-ORBgiopMaxMsgSize",
    "2147483647"
  };

  pthread_cond_init(&omc_waitformsg,NULL);
  pthread_cond_init(&corba_waitformsg,NULL);
  pthread_mutex_init(&corba_waitlock,NULL);
  pthread_mutex_init(&omc_waitlock,NULL);
  pthread_mutex_init(&omc_corba_clientlock, NULL);

  char **argv = construct_dummy_args(argc, dummyArgv);

  orb = CORBA::ORB_init(argc, argv, "omniORB4");
  free_dummy_args(argc, argv);
  poaobj = orb->resolve_initial_references("RootPOA");
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  /* get temp dir */
  /* if corbaObjectReferenceFilePath value is set and is a valid directory then use it for dumping the object reference file. */
  const char* tmpDir = NULL;
  if (SystemImpl__directoryExists(corbaObjectReferenceFilePath))
    tmpDir = corbaObjectReferenceFilePath;
  else
    tmpDir = SettingsImpl__getTempDirectoryPath();
  /* get the user name */
  char *tmp_user = getenv("USER");
  string user = tmp_user ? tmp_user : "nobody";

  /* start omc differently if we have a corba session name */
  if (corbaSessionName != NULL) /* yehaa, we have a session name */
  {
    /*
     * The RootPOA has the SYSTEM_ID policy, but we want to assign our
     * own IDs, so create a new POA with the USER_ID policy
     *  After we got the RootPOA manager, we need our own POA
     */
    pl.length(1);
    pl[0] = poa->create_id_assignment_policy (PortableServer::USER_ID);
    omcpoa = poa->create_POA ("OMCPOA", mgr, pl);

    oid = PortableServer::string_to_ObjectId (corbaSessionName);
    server = new OmcCommunication_impl();

    omcpoa->activate_object_with_id(oid, server);

    /*
     * build the reference to store in the file
     */
    omc_ref = omcpoa->id_to_reference (oid.in());
    objref_file << tmpDir << "/openmodelica." << user << ".objid." << corbaSessionName;
  }
  else /* we don't have a session name, start OMC normaly */
  {
      server = new OmcCommunication_impl();
      oid = poa->activate_object(server);
      omc_ref = poa->id_to_reference (oid.in());
      objref_file << tmpDir << "/openmodelica." << user << ".objid";
  }

  str = orb->object_to_string (omc_ref.in());
  /* Write reference to file */
  ofstream of (objref_file.str().c_str());
  of << str.in() << endl;
  of.close ();

  mgr->activate();

  // Start thread that listens on incomming messages.
  pthread_t orb_thr_id;
  if( pthread_create(&orb_thr_id,NULL,&runOrb,NULL)) {
    cerr << "Error creating thread for corba communication." << endl;
    return 1;
  }
  std::cout << "Created server." << std::endl;
  std::cout << "Dumped Corba IOR in file: " << objref_file.str().c_str() << std::endl;
  std::cout << "Started the Corba ORB thread with id: " << orb_thr_id << std::endl;
#endif // NOMICO
  return 0;
}

#endif /* MINGW32 and MSVC*/



const char* CorbaImpl__waitForCommand()
{
#ifndef NOMICO
#if defined(__MINGW32__) || defined(_MSC_VER)
  while (WAIT_OBJECT_0 != WaitForSingleObject(omc_client_request_event,INFINITE) );

#else
  pthread_mutex_lock(&omc_waitlock);
  while (!omc_waiting) pthread_cond_wait(&omc_waitformsg,&omc_waitlock);
  omc_waiting = false;
  pthread_mutex_unlock(&omc_waitlock);
#endif

#if defined(__MINGW32__) || defined(_MSC_VER)
  EnterCriticalSection(&lock); // Lock so no other tread can talk to omc.
#else
  pthread_mutex_lock(&omc_corba_lock); // Lock so no other tread can talk to omc.
#endif
#endif // NOMICO
  return omc_cmd_message;
}

void CorbaImpl__sendreply(const char *msg)
{
#ifndef NOMICO
#if defined(__MINGW32__) || defined(_MSC_VER)
  // Signal to Corba that it can return, taking the value in message
  omc_reply_message = msg;
  SetEvent(omc_return_value_ready);

  LeaveCriticalSection(&lock); // Unlock, so other threads can ask omc stuff.
#else
  // Signal to Corba that it can return, taking the value in message
  pthread_mutex_lock(&corba_waitlock);
  corba_waiting=true;
  omc_reply_message = msg;

  pthread_cond_signal(&corba_waitformsg);
  pthread_mutex_unlock(&corba_waitlock);

  pthread_mutex_unlock(&omc_corba_lock); // Unlock, so other threads can ask omc stuff.
#endif
#endif // NOMICO
}

void CorbaImpl__close()
{
#ifndef NOMICO
#if defined(__MINGW32__) || defined(_MSC_VER)
  try {
    orb->shutdown(FALSE);
  } catch (CORBA::Exception&) {
    cerr << "Error shutting down." << endl;
  }
  remove(objref_file.str().c_str());
#else
  try {
    orb->shutdown(true); // true otherwise we get a crash on Leopard
  } catch (CORBA::Exception&) {
    cerr << "Error shutting down." << endl;
  }
  remove(objref_file.str().c_str());
#ifdef HAVE_PTHREAD_YIELD
   pthread_yield(); // Allowing other thread to shutdown.
#else
  sched_yield(); // use as backup (in cygwin)
#endif

#endif
#endif // NOMICO
}

}
