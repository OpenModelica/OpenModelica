/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef NOMICO
#include "omc_communication.h"
#include "omc_communication_impl.h"
#endif //NOMICO

// includes for both linux and windows
extern "C" {
#include "rml.h"
#include "../Values.h"
#include <stdio.h>
#include "../absyn_builder/yacclib.h"
}
#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>

/*
 * @author adrpo
 * @date 2007-02-08
 * This variable is set in rtopts by function setCorbaSessionName(char* name);
 * system independent Corba Session Name
 */
extern "C" {
char* corbaSessionName=0;
}
/* the file in which we have to dump the Corba IOR ID */
std::ostringstream objref_file;

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

using namespace std;

HANDLE lock;
HANDLE omc_client_request_event;
HANDLE omc_return_value_ready;
HANDLE clientlock;

char * omc_cmd_message = "";
char * omc_reply_message = "";

#ifndef NOMICO
CORBA::ORB_var orb;
PortableServer::POA_var poa;
CORBA::Object_var poaobj;
PortableServer::POAManager_var mgr;
PortableServer::POA_var omcpoa;
CORBA::PolicyList pl;
CORBA::Object_var ref;
CORBA::String_var str;
PortableServer::ObjectId_var oid;
OmcCommunication_impl* server;
#endif // NOMICO

extern "C" {
DWORD WINAPI runOrb(void* arg);

void Corba_5finit(void)
{

}

RML_BEGIN_LABEL(Corba__initialize)
{
#ifndef NOMICO
  char *dummyArgv[3];
  dummyArgv[0] = "-ORBNoResolve";
  dummyArgv[1] = "-ORBIIOPAddr";
  dummyArgv[2] = "inet:127.0.0.1:0";
  int argc=3;
  string omc_client_request_event_name 	= "omc_client_request_event";
  string omc_return_value_ready_name   	= "omc_return_value_ready";
  string lock_name 						= "lock";
  string clientlock_name 				= "clientlock";

  /* create the events and locks with different names if we have a corba session */
  if (corbaSessionName != NULL) /* yehaa, we have a session name */
  {
  	omc_client_request_event_name 	+= corbaSessionName;
  	omc_return_value_ready_name   	+= corbaSessionName;
  	lock_name 				      	+= corbaSessionName;
  	clientlock_name 				+= corbaSessionName;
  }
  omc_client_request_event = CreateEvent(NULL,FALSE,FALSE,omc_client_request_event_name.c_str());
  if (omc_client_request_event == NULL) 
  {
    fprintf(stderr, "CreateEvent '%s' error: %d\n", omc_client_request_event_name.c_str(), GetLastError());	
	RML_TAILCALLK(rmlFC);
  }
  omc_return_value_ready = CreateEvent(NULL,FALSE,FALSE,omc_return_value_ready_name.c_str());
  if (omc_return_value_ready == NULL) 
  {
    fprintf(stderr, "CreateEvent '%s' error: %d\n", omc_return_value_ready_name.c_str(), GetLastError());		
	RML_TAILCALLK(rmlFC);
  }
  lock = CreateMutex(NULL, FALSE, lock_name.c_str());
  if (lock == NULL)
  {
    fprintf(stderr, "CreateMutex '%s' error: %d\n", lock_name.c_str(), GetLastError());
	RML_TAILCALLK(rmlFC);    
  }  
  clientlock = CreateMutex(NULL, FALSE, clientlock_name.c_str());
  if (clientlock == NULL)
  {
    fprintf(stderr, "CreateMutex '%s' error: %d\n", clientlock_name.c_str(), GetLastError());
	RML_TAILCALLK(rmlFC);    
  }  
  

  orb = CORBA::ORB_init(argc, dummyArgv, "mico-local-orb");
  poaobj = orb->resolve_initial_references("RootPOA");
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  /* get the temporary directory */
  char tempPath[1024];
  GetTempPath(1000,tempPath);      
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
	  omcpoa->activate_object_with_id(*oid, server);
	  /* 
	   * build the reference to store in the file
	   */  
	  ref = omcpoa->id_to_reference (oid.in());
	  objref_file << tempPath << "openmodelica.objid." << corbaSessionName;
  }  
  else /* we don't have a session name, start OMC normaly */
  {
      server = new OmcCommunication_impl(); 
  	  oid = poa->activate_object(server);
  	  ref = poa->id_to_reference (oid.in());
  	  objref_file << tempPath << "openmodelica.objid";	  
  }

  str = orb->object_to_string (ref.in());
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
  std::cout << "Created Mutexes: " << lock_name.c_str() << ", " << clientlock_name.c_str() << std::endl;
  std::cout << "Created Events: " << omc_client_request_event_name.c_str() << ", " << omc_return_value_ready_name.c_str() << std::endl;      
#endif //NOMICO
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

DWORD WINAPI runOrb(void* arg) {
#ifndef NOMICO
	try 
	{
		orb->run();
	} catch (CORBA::Exception) {
		// run can throw exception when other side closes.
	}

  poa->destroy(TRUE,TRUE);
  delete server;
#endif // NOMICO
  return 0;
}


RML_BEGIN_LABEL(Corba__waitForCommand)
{
#ifndef NOMICO
  while (WAIT_OBJECT_0 != WaitForSingleObject(omc_client_request_event,INFINITE) );
  
  rmlA0=mk_scon(omc_cmd_message);
  
  WaitForSingleObject(lock,INFINITE); // Lock so no other tread can talk to omc.

#endif // NOMICO

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
#ifndef NOMICO
  char *msg=RML_STRINGDATA(rmlA0);

  // Signal to Corba that it can return, taking the value in message
  omc_reply_message = msg;
  SetEvent(omc_return_value_ready);

  ReleaseMutex(lock); // Unlock, so other threads can ask omc stuff.
#endif // NOMICO

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__close)
{
#ifndef NOMICO
  try {
    orb->shutdown(FALSE);
  } catch (CORBA::Exception) {
    cerr << "Error shutting down." << endl;
  }
  remove(objref_file.str().c_str());
#endif // NOMICO
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}

#else 
/*******************************************************
 * *****************************************************
 *                 linux stuff here 
 * *****************************************************
 * *****************************************************
 */

extern "C" {
#include <pthread.h>
}

using namespace std;

pthread_mutex_t lock;
// Condition variable for keeping omc waiting for client requests
pthread_cond_t omc_waitformsg;
pthread_mutex_t omc_waitlock;
bool omc_waiting=false;
// Condition variable for keeping corba waiting for returnvalue from omc
pthread_cond_t corba_waitformsg;
pthread_mutex_t corba_waitlock;
bool corba_waiting=false;

char * omc_cmd_message = "";
char * omc_reply_message = "";

#ifndef NOMICO
CORBA::ORB_var orb;
PortableServer::POA_var poa;
CORBA::Object_var poaobj;
PortableServer::POAManager_var mgr;
PortableServer::POA_var omcpoa;
CORBA::PolicyList pl;
CORBA::Object_var ref;
CORBA::String_var str;
PortableServer::ObjectId_var oid;
OmcCommunication_impl* server;
#endif // NOMICO

extern "C" {
void* runOrb(void*arg);
  
void Corba_5finit(void)
{

}


RML_BEGIN_LABEL(Corba__initialize)
{
#ifndef NOMICO
  char *dummyArgv[3];
  dummyArgv[0] = "-ORBNoResolve";
  dummyArgv[1] = "-ORBIIOPAddr";
  dummyArgv[2] = "inet:127.0.0.1:0";
  int argc=3;
  pthread_cond_init(&omc_waitformsg,NULL);
  pthread_cond_init(&corba_waitformsg,NULL);
  pthread_mutex_init(&corba_waitlock,NULL);
  pthread_mutex_init(&omc_waitlock,NULL);
  
  orb = CORBA::ORB_init(argc, dummyArgv, "mico-local-orb");
  poaobj = orb->resolve_initial_references("RootPOA");
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  /* get the user name */
  char *user = getenv("USER");
  if (user==NULL) { user="nobody"; }
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
	  omcpoa->activate_object_with_id(*oid, server);
	  /* 
	   * build the reference to store in the file
	   */  
	  ref = omcpoa->id_to_reference (oid.in());
	  objref_file << tempPath << "openmodelica." << user << ".objid." << corbaSessionName;
  }  
  else /* we don't have a session name, start OMC normaly */
  {
      server = new OmcCommunication_impl(); 
  	  oid = poa->activate_object(server);
  	  ref = poa->id_to_reference (oid.in());
  	  objref_file << tempPath << "openmodelica." << user << ".objid";	  
  }

  str = orb->object_to_string (ref.in());
  /* Write reference to file */
  ofstream of (objref_file.str().c_str());
  of << str.in() << endl;
  of.close ();

  mgr->activate();

  // Start thread that listens on incomming messages.
  pthread_t orb_thr_id;
  if( pthread_create(&orb_thr_id,NULL,&runOrb,NULL)) {
    cerr << "Error creating thread for corba communication." << endl;
    RML_TAILCALLK(rmlFC);
  }
  std::cout << "Created server." << std::endl;
  std::cout << "Dumped Corba IOR in file: " << objref_file.str().c_str() << std::endl;
  std::cout << "Started the Corba ORB thread with id: " << orb_thr_id << std::endl;
#endif // NOMICO
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void* runOrb(void* arg) 
{
#ifndef NOMICO	
  try {
    orb->run();
  } catch (CORBA::Exception) {
    // run can throw exception when other side closes.
  }

  poa->destroy(TRUE,TRUE);
  delete server;
#endif // NOMICO  
  return NULL;
}


RML_BEGIN_LABEL(Corba__waitForCommand)
{
#ifndef NOMICO
  pthread_mutex_lock(&omc_waitlock);
  while (!omc_waiting) {
    pthread_cond_wait(&omc_waitformsg,&omc_waitlock);
  }
  omc_waiting = false;
  pthread_mutex_unlock(&omc_waitlock);

  rmlA0=mk_scon(omc_cmd_message);
  pthread_mutex_lock(&lock); // Lock so no other tread can talk to omc.
#endif // NOMICO  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
#ifndef NOMICO	
  char *msg=RML_STRINGDATA(rmlA0);

  // Signal to Corba that it can return, taking the value in message
  pthread_mutex_lock(&corba_waitlock); 
  corba_waiting=true;
  omc_reply_message = msg;

  pthread_cond_signal(&corba_waitformsg);
  pthread_mutex_unlock(&corba_waitlock);

  pthread_mutex_unlock(&lock); // Unlock, so other threads can ask omc stuff.
#endif // NOMICO  
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__close)
{
#ifndef NOMICO	
  try {
    orb->shutdown(FALSE);
  } catch (CORBA::Exception) {
    cerr << "Error shutting down." << endl;
  }
  remove(objref_file.str().c_str());
#ifdef HAVE_PTHREAD_YIELD  
    pthread_yield(); // Allowing other thread to shutdown.
#else  
  sched_yield(); // use as backup (in cygwin)
#endif
#endif // NOMICO
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}

#endif /* MINGW32 and MSVC*/
