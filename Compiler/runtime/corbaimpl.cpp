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
#endif

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

// windows and mingw32
#if defined(__MINGW32__) || defined(_MSC_VER)

#include <windows.h>

static   char obj_ref[1024];

using namespace std;

HANDLE lock;
HANDLE omc_client_request_event;
HANDLE omc_return_value_ready;

char * omc_message;

#ifndef NOMICO
CORBA::ORB_var orb;
PortableServer::POA_var poa;
CORBA::Object_var poaobj;
PortableServer::POAManager_var mgr;
CORBA::Object_var ref;
CORBA::String_var str;
PortableServer::ObjectId_var oid;
OmcCommunication_impl* server;
#endif

extern "C" {
//void* runOrb(void*arg);
DWORD WINAPI runOrb(void* arg);

void Corba_5finit(void)
{

}

RML_BEGIN_LABEL(Corba__initialize)
{
#ifndef NOMICO
  char *dummyArgv[3];
  dummyArgv[0] = "omc";
  dummyArgv[1] = "-ORBNoResolve";
  dummyArgv[2] = "-ORBIIOPAddr";
  dummyArgv[3] = "inet:127.0.0.1:0";
  int argc=4;

  omc_client_request_event = CreateEvent(NULL,FALSE,FALSE,"omc_client_request_event");
  if (omc_client_request_event == NULL) {
	RML_TAILCALLK(rmlFC);
  }
  omc_return_value_ready = CreateEvent(NULL,FALSE,FALSE,"omc_return_value_ready");
  if (omc_return_value_ready == NULL) {
	RML_TAILCALLK(rmlFC);
  }
  lock = CreateMutex(NULL, FALSE, "lock");

  

  orb = CORBA::ORB_init(argc, dummyArgv, "mico-local-orb");
  poaobj = orb->resolve_initial_references("RootPOA");
  
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  server = new OmcCommunication_impl(); 

  oid = poa->activate_object(server);

  /* Write reference to file */
  char tempPath[1024];
  GetTempPath(1000,tempPath);
  sprintf(obj_ref,"%sopenmodelica.objid", tempPath);
  ofstream of (obj_ref);
  ref = poa->id_to_reference (oid.in());
  str = orb->object_to_string (ref.in());
  of << str.in() << endl;
  of.close ();


  mgr->activate();

  // Start thread that listens on incomming messages.
  HANDLE orb_thr_handle;
  DWORD orb_thr_id;
  
  orb_thr_handle = CreateThread(NULL, 0, runOrb, NULL, 0, &orb_thr_id);

  std::cout << "Created server." << std::endl;
#endif
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

//void* runOrb(void* arg) 
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
#endif
  return 0;
}


RML_BEGIN_LABEL(Corba__waitForCommand)
{
  while (WAIT_OBJECT_0 != WaitForSingleObject(omc_client_request_event,INFINITE) );
  
  rmlA0=mk_scon(omc_message);
  
  WaitForSingleObject(lock,INFINITE); // Lock so no other tread can talk to omc.

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
#ifndef NOMICO
	char *msg=RML_STRINGDATA(rmlA0);

  // Signal to Corba that it can return, taking the value in message
  omc_message = CORBA::string_dup(msg);

  SetEvent(omc_return_value_ready);

  ReleaseMutex(lock); // Unlock, so other threads can ask omc stuff.
#endif
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
  remove(obj_ref);
#endif
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}

#else /* linux stuff here */

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

char *omc_message;

ostringstream objref_file;

CORBA::ORB_var orb;
PortableServer::POA_var poa;
CORBA::Object_var poaobj;
PortableServer::POAManager_var mgr;
CORBA::Object_var ref;
CORBA::String_var str;
PortableServer::ObjectId_var oid;
OmcCommunication_impl * server;

extern "C" {
void* runOrb(void*arg);
  
void Corba_5finit(void)
{

}

RML_BEGIN_LABEL(Corba__initialize)
{
  char *dummyArgv="omc";
  int zero=0;
  pthread_cond_init(&omc_waitformsg,NULL);
  pthread_cond_init(&corba_waitformsg,NULL);
  pthread_mutex_init(&corba_waitlock,NULL);
  pthread_mutex_init(&omc_waitlock,NULL);
  
  orb = CORBA::ORB_init(zero, 0,"mico-local-orb");
  poaobj = orb->resolve_initial_references("RootPOA");
  
  poa = PortableServer::POA::_narrow(poaobj);
  mgr = poa->the_POAManager();

  server = new OmcCommunication_impl(); 

  oid = poa->activate_object(server);

  /* Write reference to file */
  char *user = getenv("USER");
  if (user==NULL) { user="nobody"; }

  
  objref_file << "/tmp/openmodelica." << user << ".objid";
  ofstream of (objref_file.str().c_str());
  ref = poa->id_to_reference (oid.in());
  str = orb->object_to_string (ref.in());
  of << str.in() << endl;
  of.close ();


  mgr->activate();

  // Start thread that listens on incomming messages.
  pthread_t orb_thr_id;
  if( pthread_create(&orb_thr_id,NULL,&runOrb,NULL)) {
    cerr << "Error creating thread for corba communication." << endl;
    RML_TAILCALLK(rmlFC);
  }
  
  //std::cout << "Created server." << std::endl;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

void* runOrb(void* arg) 
{
  try {
    orb->run();
  } catch (CORBA::Exception) {
    // run can throw exception when other side closes.
  }

  poa->destroy(TRUE,TRUE);
  delete server;
  return NULL;
}


RML_BEGIN_LABEL(Corba__waitForCommand)
{
  pthread_mutex_lock(&omc_waitlock);
  while (!omc_waiting) {
    pthread_cond_wait(&omc_waitformsg,&omc_waitlock);
  }
  omc_waiting = false;
  pthread_mutex_unlock(&omc_waitlock);

  rmlA0=mk_scon(omc_message);
  pthread_mutex_lock(&lock); // Lock so no other tread can talk to omc.
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
  char *msg=RML_STRINGDATA(rmlA0);

  // Signal to Corba that it can return, taking the value in message
  pthread_mutex_lock(&corba_waitlock); 
  corba_waiting=true;
  omc_message =CORBA::string_dup(msg);

  pthread_cond_signal(&corba_waitformsg);
  pthread_mutex_unlock(&corba_waitlock);

  pthread_mutex_unlock(&lock); // Unlock, so other threads can ask omc stuff.
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__close)
{
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
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}

#endif /* MINGW32 and MSVC*/
