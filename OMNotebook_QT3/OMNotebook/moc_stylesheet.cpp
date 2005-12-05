/****************************************************************************
** IAEX::Stylesheet meta object code from reading C++ file 'stylesheet.h'
**
** Created: ti 25. okt 11:26:38 2005
**      by: The Qt MOC ($Id: moc_stylesheet.cpp,v 1.6 2005/10/26 07:24:37 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "stylesheet.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::Stylesheet::className() const
{
    return "IAEX::Stylesheet";
}

QMetaObject *IAEX::Stylesheet::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__Stylesheet( "IAEX::Stylesheet", &IAEX::Stylesheet::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::Stylesheet::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::Stylesheet", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::Stylesheet::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::Stylesheet", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::Stylesheet::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QObject::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"IAEX::Stylesheet", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__Stylesheet.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::Stylesheet::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::Stylesheet" ) )
	return this;
    return QObject::qt_cast( clname );
}

bool IAEX::Stylesheet::qt_invoke( int _id, QUObject* _o )
{
    return QObject::qt_invoke(_id,_o);
}

bool IAEX::Stylesheet::qt_emit( int _id, QUObject* _o )
{
    return QObject::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool IAEX::Stylesheet::qt_property( int id, int f, QVariant* v)
{
    return QObject::qt_property( id, f, v);
}

bool IAEX::Stylesheet::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
