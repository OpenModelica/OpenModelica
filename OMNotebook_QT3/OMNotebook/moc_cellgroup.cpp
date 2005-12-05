/****************************************************************************
** IAEX::CellGroup meta object code from reading C++ file 'cellgroup.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_cellgroup.cpp,v 1.6 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "cellgroup.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::CellGroup::className() const
{
    return "IAEX::CellGroup";
}

QMetaObject *IAEX::CellGroup::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__CellGroup( "IAEX::CellGroup", &IAEX::CellGroup::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::CellGroup::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellGroup", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::CellGroup::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellGroup", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::CellGroup::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = Cell::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ "style", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"setStyle", 1, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ "name", &static_QUType_QString, 0, QUParameter::In },
	{ "val", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setStyle", 2, param_slot_1 };
    static const QUParameter param_slot_2[] = {
	{ "closed", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"setClosed", 1, param_slot_2 };
    static const QUParameter param_slot_3[] = {
	{ "focus", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_3 = {"setFocus", 1, param_slot_3 };
    static const QUMethod slot_4 = {"adjustHeight", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "setStyle(const QString&)", &slot_0, QMetaData::Public },
	{ "setStyle(const QString&,const QString&)", &slot_1, QMetaData::Public },
	{ "setClosed(const bool)", &slot_2, QMetaData::Public },
	{ "setFocus(const bool)", &slot_3, QMetaData::Public },
	{ "adjustHeight()", &slot_4, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::CellGroup", parentObject,
	slot_tbl, 5,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__CellGroup.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::CellGroup::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::CellGroup" ) )
	return this;
    return Cell::qt_cast( clname );
}

bool IAEX::CellGroup::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setStyle((const QString&)static_QUType_QString.get(_o+1)); break;
    case 1: setStyle((const QString&)static_QUType_QString.get(_o+1),(const QString&)static_QUType_QString.get(_o+2)); break;
    case 2: setClosed((const bool)static_QUType_bool.get(_o+1)); break;
    case 3: setFocus((const bool)static_QUType_bool.get(_o+1)); break;
    case 4: adjustHeight(); break;
    default:
	return Cell::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::CellGroup::qt_emit( int _id, QUObject* _o )
{
    return Cell::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool IAEX::CellGroup::qt_property( int id, int f, QVariant* v)
{
    return Cell::qt_property( id, f, v);
}

bool IAEX::CellGroup::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
