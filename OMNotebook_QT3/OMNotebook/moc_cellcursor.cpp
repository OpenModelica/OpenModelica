/****************************************************************************
** IAEX::CellCursor meta object code from reading C++ file 'cellcursor.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_cellcursor.cpp,v 1.6 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "cellcursor.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::CellCursor::className() const
{
    return "IAEX::CellCursor";
}

QMetaObject *IAEX::CellCursor::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__CellCursor( "IAEX::CellCursor", &IAEX::CellCursor::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::CellCursor::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellCursor", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::CellCursor::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellCursor", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::CellCursor::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = Cell::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"setFocus", 1, param_slot_0 };
    static const QMetaData slot_tbl[] = {
	{ "setFocus(const bool)", &slot_0, QMetaData::Public }
    };
    static const QUMethod signal_0 = {"changedPosition", 0, 0 };
    static const QUParameter param_signal_1[] = {
	{ "x", &static_QUType_int, 0, QUParameter::In },
	{ "y", &static_QUType_int, 0, QUParameter::In },
	{ "xm", &static_QUType_int, 0, QUParameter::In },
	{ "ym", &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod signal_1 = {"positionChanged", 4, param_signal_1 };
    static const QMetaData signal_tbl[] = {
	{ "changedPosition()", &signal_0, QMetaData::Public },
	{ "positionChanged(int,int,int,int)", &signal_1, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::CellCursor", parentObject,
	slot_tbl, 1,
	signal_tbl, 2,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__CellCursor.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::CellCursor::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::CellCursor" ) )
	return this;
    return Cell::qt_cast( clname );
}

// SIGNAL changedPosition
void IAEX::CellCursor::changedPosition()
{
    activate_signal( staticMetaObject()->signalOffset() + 0 );
}

#include <qobjectdefs.h>
#include <qsignalslotimp.h>

// SIGNAL positionChanged
void IAEX::CellCursor::positionChanged( int t0, int t1, int t2, int t3 )
{
    if ( signalsBlocked() )
	return;
    QConnectionList *clist = receivers( staticMetaObject()->signalOffset() + 1 );
    if ( !clist )
	return;
    QUObject o[5];
    static_QUType_int.set(o+1,t0);
    static_QUType_int.set(o+2,t1);
    static_QUType_int.set(o+3,t2);
    static_QUType_int.set(o+4,t3);
    activate_signal( clist, o );
}

bool IAEX::CellCursor::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setFocus((const bool)static_QUType_bool.get(_o+1)); break;
    default:
	return Cell::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::CellCursor::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: changedPosition(); break;
    case 1: positionChanged((int)static_QUType_int.get(_o+1),(int)static_QUType_int.get(_o+2),(int)static_QUType_int.get(_o+3),(int)static_QUType_int.get(_o+4)); break;
    default:
	return Cell::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::CellCursor::qt_property( int id, int f, QVariant* v)
{
    return Cell::qt_property( id, f, v);
}

bool IAEX::CellCursor::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
