/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <CORBA.h>
#include <mico/throw.h>

#ifndef __OMC_COMMUNICATION_H__
#define __OMC_COMMUNICATION_H__




class OmcCommunication;
typedef OmcCommunication *OmcCommunication_ptr;
typedef OmcCommunication_ptr OmcCommunicationRef;
typedef ObjVar< OmcCommunication > OmcCommunication_var;
typedef ObjOut< OmcCommunication > OmcCommunication_out;




/*
 * Base class and common definitions for interface OmcCommunication
 */

class OmcCommunication : 
  virtual public CORBA::Object
{
  public:
    virtual ~OmcCommunication();

    #ifdef HAVE_TYPEDEF_OVERLOAD
    typedef OmcCommunication_ptr _ptr_type;
    typedef OmcCommunication_var _var_type;
    #endif

    static OmcCommunication_ptr _narrow( CORBA::Object_ptr obj );
    static OmcCommunication_ptr _narrow( CORBA::AbstractBase_ptr obj );
    static OmcCommunication_ptr _duplicate( OmcCommunication_ptr _obj )
    {
      CORBA::Object::_duplicate (_obj);
      return _obj;
    }

    static OmcCommunication_ptr _nil()
    {
      return 0;
    }

    virtual void *_narrow_helper( const char *repoid );

    virtual char* sendExpression( const char* expr ) = 0;
    virtual char* sendClass( const char* model ) = 0;

  protected:
    OmcCommunication() {};
  private:
    OmcCommunication( const OmcCommunication& );
    void operator=( const OmcCommunication& );
};

// Stub for interface OmcCommunication
class OmcCommunication_stub:
  virtual public OmcCommunication
{
  public:
    virtual ~OmcCommunication_stub();
    char* sendExpression( const char* expr );
    char* sendClass( const char* model );

  private:
    void operator=( const OmcCommunication_stub& );
};

#ifndef MICO_CONF_NO_POA

class OmcCommunication_stub_clp :
  virtual public OmcCommunication_stub,
  virtual public PortableServer::StubBase
{
  public:
    OmcCommunication_stub_clp (PortableServer::POA_ptr, CORBA::Object_ptr);
    virtual ~OmcCommunication_stub_clp ();
    char* sendExpression( const char* expr );
    char* sendClass( const char* model );

  protected:
    OmcCommunication_stub_clp ();
  private:
    void operator=( const OmcCommunication_stub_clp & );
};

#endif // MICO_CONF_NO_POA

#ifndef MICO_CONF_NO_POA

class POA_OmcCommunication : virtual public PortableServer::StaticImplementation
{
  public:
    virtual ~POA_OmcCommunication ();
    OmcCommunication_ptr _this ();
    bool dispatch (CORBA::StaticServerRequest_ptr);
    virtual void invoke (CORBA::StaticServerRequest_ptr);
    virtual CORBA::Boolean _is_a (const char *);
    virtual CORBA::InterfaceDef_ptr _get_interface ();
    virtual CORBA::RepositoryId _primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr);

    virtual void * _narrow_helper (const char *);
    static POA_OmcCommunication * _narrow (PortableServer::Servant);
    virtual CORBA::Object_ptr _make_stub (PortableServer::POA_ptr, CORBA::Object_ptr);

    virtual char* sendExpression( const char* expr ) = 0;
    virtual char* sendClass( const char* model ) = 0;

  protected:
    POA_OmcCommunication () {};

  private:
    POA_OmcCommunication (const POA_OmcCommunication &);
    void operator= (const POA_OmcCommunication &);
};

#endif // MICO_CONF_NO_POA

extern CORBA::StaticTypeInfo *_marshaller_OmcCommunication;

#endif
