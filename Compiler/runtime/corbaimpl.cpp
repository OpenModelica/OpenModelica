
#ifdef __MINGW32__

#include "../winruntime/corbaimpl.cpp"

#else

#include "omc_communication.h"
#include "omc_communication_impl.h"

#include <sstream>


extern "C" {
#include "rml.h"
#include "../Values.h"
#include <stdio.h>
#include "../absyn_builder/yacclib.h"
#include <pthread.h>
}

#include <cstdlib>
#include <iostream>
#include <fstream>


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

char * omc_message;

ostringstream objref_file;

CORBA::ORB_var orb;
PortableServer::POA_var poa;

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
  CORBA::Object_var poaobj = orb->resolve_initial_references("RootPOA");
  
  poa = PortableServer::POA::_narrow(poaobj);
  PortableServer::POAManager_var mgr = poa->the_POAManager();

  server = new OmcCommunication_impl(); 

  PortableServer::ObjectId_var oid = poa->activate_object(server);

  /* Write reference to file */
  char *user = getenv("USER");
  if (user==NULL) { user="nobody"; }

  
  objref_file << "/tmp/openmodelica." << user << ".objid";
  ofstream of (objref_file.str().c_str());
  CORBA::Object_var ref = poa->id_to_reference (oid.in());
  CORBA::String_var str = orb->object_to_string (ref.in());
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


RML_BEGIN_LABEL(Corba__wait_5ffor_5fcommand)
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

#endif /* MINGW32 */