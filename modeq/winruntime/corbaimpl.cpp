#include "modeq_communication.h"
#include "modeq_communication_impl.h"



extern "C" {
#include "rml.h"
#include "../values.h"
#include <stdio.h>
#include "../absyn_builder/yacclib.h"
//#include <pthread.h>
}

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <windows.h>

static   char obj_ref[1024];

using namespace std;

HANDLE lock;
HANDLE modeq_client_request_event;
HANDLE modeq_return_value_ready;

char * modeq_message;


CORBA::ORB_var orb;
PortableServer::POA_var poa;

ModeqCommunication_impl * server;

extern "C" {
//void* runOrb(void*arg);
DWORD WINAPI runOrb(void* arg);

void Corba_5finit(void)
{

}

RML_BEGIN_LABEL(Corba__initialize)
{
  char *dummyArgv="modeq";
  int zero=0;

  modeq_client_request_event = CreateEvent(NULL,FALSE,FALSE,"modeq_client_request_event");
  if (modeq_client_request_event == NULL) {
	RML_TAILCALLK(rmlFC);
  }
  modeq_return_value_ready = CreateEvent(NULL,FALSE,FALSE,"modeq_return_value_ready");
  if (modeq_return_value_ready == NULL) {
	RML_TAILCALLK(rmlFC);
  }
  lock = CreateMutex(NULL, FALSE, "lock");

  orb = CORBA::ORB_init(zero, 0,"mico-local-orb");
  CORBA::Object_var poaobj = orb->resolve_initial_references("RootPOA");
  
  poa = PortableServer::POA::_narrow(poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  server = new ModeqCommunication_impl(); 

  PortableServer::ObjectId_var oid = poa->activate_object(server);

  /* Write reference to file */
  char tempPath[1024];
  GetTempPath(1000,tempPath);
  sprintf(obj_ref,"%sopenmodelica.objid", tempPath);
  ofstream of (obj_ref);
  CORBA::Object_var ref = poa->id_to_reference (oid.in());
  CORBA::String_var str = orb->object_to_string (ref.in());
  of << str.in() << endl;
  of.close ();


  mgr->activate();

  // Start thread that listens on incomming messages.
  HANDLE orb_thr_handle;
  DWORD orb_thr_id;
  
  orb_thr_handle = CreateThread(NULL, 0, runOrb, NULL, 0, &orb_thr_id);

  std::cout << "Created server." << std::endl;
  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

//void* runOrb(void* arg) 
DWORD WINAPI runOrb(void* arg) {
  try {
    orb->run();
  } catch (CORBA::Exception) {
    // run can throw exception when other side closes.
  }

  poa->destroy(TRUE,TRUE);
  delete server;
  return NULL;
}


RML_BEGIN_LABEL(Corba__wait_5ffor_5fcommand)
{
  while (WAIT_OBJECT_0 != WaitForSingleObject(modeq_client_request_event,INFINITE) );
  
  rmlA0=mk_scon(modeq_message);
  
  WaitForSingleObject(lock,INFINITE); // Lock so no other tread can talk to modeq.

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL

RML_BEGIN_LABEL(Corba__sendreply)
{
  char *msg=RML_STRINGDATA(rmlA0);

  // Signal to Corba that it can return, taking the value in message
  modeq_message = CORBA::string_dup(msg);

  SetEvent(modeq_return_value_ready);

  ReleaseMutex(lock); // Unlock, so other threads can ask modeq stuff.
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
  remove(obj_ref);

  RML_TAILCALLK(rmlSC);
}
RML_END_LABEL
}
