/****************************************************************************
** IAEX::SmlInteractiveEnvironment meta object code from reading C++ file 'smlinteractiveenvironment.h'
**
** Created: ti 25. okt 11:26:38 2005
**      by: The Qt MOC ($Id: moc_smlinteractiveenvironment.cpp,v 1.6 2005/10/26 07:24:37 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "smlinteractiveenvironment.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::SmlInteractiveEnvironment::className() const
{
    return "IAEX::SmlInteractiveEnvironment";
}

QMetaObject *IAEX::SmlInteractiveEnvironment::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__SmlInteractiveEnvironment( "IAEX::SmlInteractiveEnvironment", &IAEX::SmlInteractiveEnvironment::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::SmlInteractiveEnvironment::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::SmlInteractiveEnvironment", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::SmlInteractiveEnvironment::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::SmlInteractiveEnvironment", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::SmlInteractiveEnvironment::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QObject::staticMetaObject();
    static const QUMethod slot_0 = {"updateOutput", 0, 0 };
    static const QUMethod slot_1 = {"updateErrorOutput", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "updateOutput()", &slot_0, QMetaData::Public },
	{ "updateErrorOutput()", &slot_1, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::SmlInteractiveEnvironment", parentObject,
	slot_tbl, 2,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__SmlInteractiveEnvironment.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::SmlInteractiveEnvironment::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::SmlInteractiveEnvironment" ) )
	return this;
    if ( !qstrcmp( clname, "InputCellDelegate" ) )
	return (InputCellDelegate*)this;
    return QObject::qt_cast( clname );
}

bool IAEX::SmlInteractiveEnvironment::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: updateOutput(); break;
    case 1: updateErrorOutput(); break;
    default:
	return QObject::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::SmlInteractiveEnvironment::qt_emit( int _id, QUObject* _o )
{
    return QObject::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool IAEX::SmlInteractiveEnvironment::qt_property( int id, int f, QVariant* v)
{
    return QObject::qt_property( id, f, v);
}

bool IAEX::SmlInteractiveEnvironment::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
