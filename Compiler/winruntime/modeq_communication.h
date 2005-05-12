/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2003 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __MODEQ_COMMUNICATION_H__
#define __MODEQ_COMMUNICATION_H__




class ModeqCommunication;
typedef ModeqCommunication *ModeqCommunication_ptr;
typedef ModeqCommunication_ptr ModeqCommunicationRef;
typedef ObjVar< ModeqCommunication > ModeqCommunication_var;
typedef ObjOut< ModeqCommunication > ModeqCommunication_out;




/*
 * Base class and common definitions for interface ModeqCommunication
 */

class ModeqCommunication : 
  virtual public CORBA::Object
{
  public:
    virtual ~ModeqCommunication();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef ModeqCommunication_ptr _ptr_type;
    typedef ModeqCommunication_var _var_type;
    #endif

    static ModeqCommunication_ptr _narrow( CORBA::Object_ptr obj );
    static ModeqCommunication_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static ModeqCommunication_ptr _duplicate( ModeqCommunication_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static ModeqCommunication_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual char* sendExpression( const char* expr ) = 0;
    virtual char* sendClass( const char* model ) = 0;

  protected:
    ModeqCommunication() {};
  private:
    ModeqCommunication( const ModeqCommunication& );
    void operator=( const ModeqCommunication& );
};

// Stub for interface ModeqCommunication
class ModeqCommunication_stub:
  virtual public ModeqCommunication
{
  public:
    virtual ~ModeqCommunication_stub();
    char* sendExpression( const char* expr );
    char* sendClass( const char* model );

  private:
    void operator=( const ModeqCommunication_stub& );
};

#ifndef MICO_CONF_NO_POA

class ModeqCommunication_stub_clp :
  virtual public ModeqCommunication_stub,
  virtual public PortableServer::StubBase
{
  public:
    ModeqCommunication_stub_clp (PortableServer::POA_ptr, CORBA::Object_ptr);
    virtual ~ModeqCommunication_stub_clp ();
    char* sendExpression( const char* expr );
    char* sendClass( const char* model );

  protected:
    ModeqCommunication_stub_clp ();
  private:
    void operator=( const ModeqCommunication_stub_clp & );
};

#endif // MICO_CONF_NO_POA

#ifndef MICO_CONF_NO_POA

class POA_ModeqCommunication : virtual public PortableServer::StaticImplementation
{
  public:
    virtual ~POA_ModeqCommunication ();
    ModeqCommunication_ptr _this ();
    bool dispatch (CORBA::StaticServerRequest_ptr);
    virtual void invoke (CORBA::StaticServerRequest_ptr);
    virtual CORBA::Boolean _is_a (const char *);
    virtual CORBA::InterfaceDef_ptr _get_interface ();
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

    virtual void * _narrow_helper (const char *);
    static POA_ModeqCommunication * _narrow (PortableServer::Servant);
    virtual CORBA::Object_ptr _make_stub (PortableServer::POA_ptr, CORBA::Object_ptr);

    virtual char* sendExpression( const char* expr ) = 0;
    virtual char* sendClass( const char* model ) = 0;

  protected:
    POA_ModeqCommunication () {};

  private:
    POA_ModeqCommunication (const POA_ModeqCommunication &);
    void operator= (const POA_ModeqCommunication &);
};

#endif // MICO_CONF_NO_POA

extern CORBA::StaticTypeInfo *_marshaller_ModeqCommunication;

#endif
