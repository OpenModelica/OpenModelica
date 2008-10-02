/*
 *  MICO --- an Open Source CORBA implementation
 *  Copyright (c) 1997-2006 by The Mico Team
 *
 *  This file was automatically generated. DO NOT EDIT!
 */

#include <omc_communication.h>


using namespace std;

//--------------------------------------------------------
//  Implementation of stubs
//--------------------------------------------------------

/*
 * Base interface for class OmcCommunication
 */

OmcCommunication::~OmcCommunication()
{
}

void *
OmcCommunication::_narrow_helper( const char *_repoid )
{
  if( strcmp( _repoid, "IDL:OmcCommunication:1.0" ) == 0 )
    return (void *)this;
  return NULL;
}

OmcCommunication_ptr
OmcCommunication::_narrow( CORBA::Object_ptr _obj )
{
  OmcCommunication_ptr _o;
  if( !CORBA::is_nil( _obj ) ) {
    void *_p;
    if( (_p = _obj->_narrow_helper( "IDL:OmcCommunication:1.0" )))
      return _duplicate( (OmcCommunication_ptr) _p );
    if (!strcmp (_obj->_repoid(), "IDL:OmcCommunication:1.0") || _obj->_is_a_remote ("IDL:OmcCommunication:1.0")) {
      _o = new OmcCommunication_stub;
      _o->CORBA::Object::operator=( *_obj );
      return _o;
    }
  }
  return _nil();
}

OmcCommunication_ptr
OmcCommunication::_narrow( CORBA::AbstractBase_ptr _obj )
{
  return _narrow (_obj->_to_object());
}

class _Marshaller_OmcCommunication : public ::CORBA::StaticTypeInfo {
    typedef OmcCommunication_ptr _MICO_T;
  public:
    ~_Marshaller_OmcCommunication();
    StaticValueType create () const;
    void assign (StaticValueType dst, const StaticValueType src) const;
    void free (StaticValueType) const;
    void release (StaticValueType) const;
    ::CORBA::Boolean demarshal (::CORBA::DataDecoder&, StaticValueType) const;
    void marshal (::CORBA::DataEncoder &, StaticValueType) const;
};


_Marshaller_OmcCommunication::~_Marshaller_OmcCommunication()
{
}

::CORBA::StaticValueType _Marshaller_OmcCommunication::create() const
{
  return (StaticValueType) new _MICO_T( 0 );
}

void _Marshaller_OmcCommunication::assign( StaticValueType d, const StaticValueType s ) const
{
  *(_MICO_T*) d = ::OmcCommunication::_duplicate( *(_MICO_T*) s );
}

void _Marshaller_OmcCommunication::free( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
  delete (_MICO_T*) v;
}

void _Marshaller_OmcCommunication::release( StaticValueType v ) const
{
  ::CORBA::release( *(_MICO_T *) v );
}

::CORBA::Boolean _Marshaller_OmcCommunication::demarshal( ::CORBA::DataDecoder &dc, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj;
  if (!::CORBA::_stc_Object->demarshal(dc, &obj))
    return FALSE;
  *(_MICO_T *) v = ::OmcCommunication::_narrow( obj );
  ::CORBA::Boolean ret = ::CORBA::is_nil (obj) || !::CORBA::is_nil (*(_MICO_T *)v);
  ::CORBA::release (obj);
  return ret;
}

void _Marshaller_OmcCommunication::marshal( ::CORBA::DataEncoder &ec, StaticValueType v ) const
{
  ::CORBA::Object_ptr obj = *(_MICO_T *) v;
  ::CORBA::_stc_Object->marshal( ec, &obj );
}

::CORBA::StaticTypeInfo *_marshaller_OmcCommunication;


/*
 * Stub interface for class OmcCommunication
 */

OmcCommunication_stub::~OmcCommunication_stub()
{
}

#ifndef MICO_CONF_NO_POA

void *
POA_OmcCommunication::_narrow_helper (const char * repoid)
{
  if (strcmp (repoid, "IDL:OmcCommunication:1.0") == 0) {
    return (void *) this;
  }
  return NULL;
}

POA_OmcCommunication *
POA_OmcCommunication::_narrow (PortableServer::Servant serv) 
{
  void * p;
  if ((p = serv->_narrow_helper ("IDL:OmcCommunication:1.0")) != NULL) {
    serv->_add_ref ();
    return (POA_OmcCommunication *) p;
  }
  return NULL;
}

OmcCommunication_stub_clp::OmcCommunication_stub_clp ()
{
}

OmcCommunication_stub_clp::OmcCommunication_stub_clp (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
  : CORBA::Object(*obj), PortableServer::StubBase(poa)
{
}

OmcCommunication_stub_clp::~OmcCommunication_stub_clp ()
{
}

#endif // MICO_CONF_NO_POA

char* OmcCommunication_stub::sendExpression( const char* _par_expr )
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
OmcCommunication_stub_clp::sendExpression( const char* _par_expr )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_OmcCommunication * _myserv = POA_OmcCommunication::_narrow (_serv);
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

  return OmcCommunication_stub::sendExpression(_par_expr);
}

#endif // MICO_CONF_NO_POA

char* OmcCommunication_stub::sendClass( const char* _par_model )
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
OmcCommunication_stub_clp::sendClass( const char* _par_model )
{
  PortableServer::Servant _serv = _preinvoke ();
  if (_serv) {
    POA_OmcCommunication * _myserv = POA_OmcCommunication::_narrow (_serv);
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

  return OmcCommunication_stub::sendClass(_par_model);
}

#endif // MICO_CONF_NO_POA

struct __tc_init_OMC_COMMUNICATION {
  __tc_init_OMC_COMMUNICATION()
  {
    _marshaller_OmcCommunication = new _Marshaller_OmcCommunication;
  }

  ~__tc_init_OMC_COMMUNICATION()
  {
    delete static_cast<_Marshaller_OmcCommunication*>(_marshaller_OmcCommunication);
  }
};

static __tc_init_OMC_COMMUNICATION __init_OMC_COMMUNICATION;

//--------------------------------------------------------
//  Implementation of skeletons
//--------------------------------------------------------

// PortableServer Skeleton Class for interface OmcCommunication
POA_OmcCommunication::~POA_OmcCommunication()
{
}

::OmcCommunication_ptr
POA_OmcCommunication::_this ()
{
  CORBA::Object_var obj = PortableServer::ServantBase::_this();
  return ::OmcCommunication::_narrow (obj);
}

CORBA::Boolean
POA_OmcCommunication::_is_a (const char * repoid)
{
  if (strcmp (repoid, "IDL:OmcCommunication:1.0") == 0) {
    return TRUE;
  }
  return FALSE;
}

CORBA::InterfaceDef_ptr
POA_OmcCommunication::_get_interface ()
{
  CORBA::InterfaceDef_ptr ifd = PortableServer::ServantBase::_get_interface ("IDL:OmcCommunication:1.0");

  if (CORBA::is_nil (ifd)) {
    mico_throw (CORBA::OBJ_ADAPTER (0, CORBA::COMPLETED_NO));
  }

  return ifd;
}

CORBA::RepositoryId
POA_OmcCommunication::_primary_interface (const PortableServer::ObjectId &, PortableServer::POA_ptr)
{
  return CORBA::string_dup ("IDL:OmcCommunication:1.0");
}

CORBA::Object_ptr
POA_OmcCommunication::_make_stub (PortableServer::POA_ptr poa, CORBA::Object_ptr obj)
{
  return new ::OmcCommunication_stub_clp (poa, obj);
}

bool
POA_OmcCommunication::dispatch (CORBA::StaticServerRequest_ptr __req)
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
POA_OmcCommunication::invoke (CORBA::StaticServerRequest_ptr __req)
{
  if (dispatch (__req)) {
      return;
  }

  CORBA::Exception * ex = 
    new CORBA::BAD_OPERATION (0, CORBA::COMPLETED_NO);
  __req->set_exception (ex);
  __req->write_results();
}

