/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2003 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include "modeq_communication.h"


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------

/*
 * Base interface for class ModeqCommunication
 */

ModeqCommunication::~ModeqCommunication()
{
}

void *
ModeqCommunication::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:ModeqCommunication:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

ModeqCommunication_ptr
ModeqCommunication::_narrow( CORBA::Object_ptr _obj )
{
  ModeqCommunication_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:ModeqCommunication:1.0" )))
      return _duplicate( (ModeqCommunication_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:ModeqCommunication:1.0") || _obj->_is_a_remote ("IDL:ModeqCommunication:1.0")) {
      _o = new ModeqCommunication_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

ModeqCommunication_ptr
ModeqCommunication::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_ModeqCommunication : public ::CORBA::StaticTypeInfo {
    typedef ModeqCommunication_ptr _MICO_T;
  public:
    ~_Marshaller_ModeqCommunication();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_ModeqCommunication::~_Marshaller_ModeqCommunication()
{
}

::CORBA::StaticValueType _Marshaller_ModeqCommunication::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_ModeqCommunication::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::ModeqCommunication::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_ModeqCommunication::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_ModeqCommunication::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_ModeqCommunication::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::ModeqCommunication::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_ModeqCommunication::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_ModeqCommunication;


/*
 * Stub interface for class ModeqCommunication
 */

ModeqCommunication_stub::~ModeqCommunication_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_ModeqCommunication::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:ModeqCommunication:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_ModeqCommunication *
POA_ModeqCommunication::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:ModeqCommunication:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_ModeqCommunication *) p;
  }
  return NULL;
}

ModeqCommunication_stub_clp::ModeqCommunication_stub_clp ()
{
}

ModeqCommunication_stub_clp::ModeqCommunication_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

ModeqCommunication_stub_clp::~ModeqCommunication_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

char* ModeqCommunication_stub::sendExpression( const char* _par_expr )
{
  CORBA::StaticAny _sa_expr( CORBA::_stc_string, &_par_expr );
  char* _res = NULL;
  CORBA::StaticAny __res( CORBA::_stc_string, &_res );

  CORBA::StaticRequest __req( this, "sendExpression" );
  __req.add_in_arg( &_sa_expr );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


#ifndef MICO_CONF_NO_POA

char*
ModeqCommunication_stub_clp::sendExpression( const char* _par_expr )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_ModeqCommunication * _myserv = POA_ModeqCommunication::_narrow (_serv);
    if (_myserv) {
      char* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->sendExpression(_par_expr);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return ModeqCommunication_stub::sendExpression(_par_expr);
}

#endif // MICO_CONF_NO_POA

char* ModeqCommunication_stub::sendClass( const char* _par_model )
{
  CORBA::StaticAny _sa_model( CORBA::_stc_string, &_par_model );
  char* _res = NULL;
  CORBA::StaticAny __res( CORBA::_stc_string, &_res );

  CORBA::StaticRequest __req( this, "sendClass" );
  __req.add_in_arg( &_sa_model );
  __req.set_result( &__res );

  __req.invoke();

  mico_sii_throw( &__req, 
    0);
  return _res;
}


#ifndef MICO_CONF_NO_POA

char*
ModeqCommunication_stub_clp::sendClass( const char* _par_model )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_ModeqCommunication * _myserv = POA_ModeqCommunication::_narrow (_serv);
    if (_myserv) {
      char* __res;

      #ifdef HAVE_EXCEPTIONS
      try {
      #endif
        __res = _myserv->sendClass(_par_model);
      #ifdef HAVE_EXCEPTIONS
      }
      catch (...) {
        _myserv->_remove_ref();
        _postinvoke();
        throw;
      }
      #endif

      _myserv->_remove_ref();
      _postinvoke ();
      return __res;
    }
    _postinvoke ();
  }

  return ModeqCommunication_stub::sendClass(_par_model);
}

#endif // MICO_CONF_NO_POA

struct __tc_init_MODEQ_COMMUNICATION {
  __tc_init_MODEQ_COMMUNICATION()
  {
    _marshaller_ModeqCommunication = new _Marshaller_ModeqCommunication;
  }

  ~__tc_init_MODEQ_COMMUNICATION()
  {
    delete static_cast<_Marshaller_ModeqCommunication*>(_marshaller_ModeqCommunication);
  }
};

static __tc_init_MODEQ_COMMUNICATION __init_MODEQ_COMMUNICATION;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------

// PortableServer Skeleton Class for interface ModeqCommunication
POA_ModeqCommunication::~POA_ModeqCommunication()
{
}

::ModeqCommunication_ptr
POA_ModeqCommunication::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::ModeqCommunication::_narrow (obj);
}

CORBA::Boolean
POA_ModeqCommunication::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:ModeqCommunication:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_ModeqCommunication::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:ModeqCommunication:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_ModeqCommunication::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:ModeqCommunication:1.0");
}

CORBA::Object_ptr
POA_ModeqCommunication::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::ModeqCommunication_stub_clp (poa, obj);
}

bool
POA_ModeqCommunication::dispatch (CORBA::StaticServerRequest_ptr __req)
{
  #ifdef HAVE_EXCEPTIONS
  try {
  #endif
    if( strcmp( __req->op_name(), "sendExpression" ) == 0 ) {
      CORBA::String_var _par_expr;
      CORBA::StaticAny _sa_expr( CORBA::_stc_string, &_par_expr._for_demarshal() );

      char* _res;
      CORBA::StaticAny __res( CORBA::_stc_string, &_res );
      __req->add_in_arg( &_sa_expr );
      __req->set_result( &__res );

      if( !__req->read_args() )
        return true;

      _res = sendExpression( _par_expr.inout() );
      __req->write_results();
      CORBA::string_free( _res );
      return true;
    }
    if( strcmp( __req->op_name(), "sendClass" ) == 0 ) {
      CORBA::String_var _par_model;
      CORBA::StaticAny _sa_model( CORBA::_stc_string, &_par_model._for_demarshal() );

      char* _res;
      CORBA::StaticAny __res( CORBA::_stc_string, &_res );
      __req->add_in_arg( &_sa_model );
      __req->set_result( &__res );

      if( !__req->read_args() )
        return true;

      _res = sendClass( _par_model.inout() );
      __req->write_results();
      CORBA::string_free( _res );
      return true;
    }
  #ifdef HAVE_EXCEPTIONS
  } catch( CORBA::SystemException_catch &_ex ) {
    __req->set_exception( _ex->_clone() );
    __req->write_results();
    return true;
  } catch( ... ) {
    CORBA::UNKNOWN _ex (CORBA::OMGVMCID | 1, CORBA::COMPLETED_MAYBE);
    __req->set_exception (_ex->_clone());
    __req->write_results ();
    return true;
  }
  #endif

  return false;
}

void
POA_ModeqCommunication::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}

