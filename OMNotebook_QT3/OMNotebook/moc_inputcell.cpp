/****************************************************************************
** IAEX::InputCell meta object code from reading C++ file 'inputcell.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_inputcell.cpp,v 1.7 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "inputcell.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::InputCell::className() const
{
    return "IAEX::InputCell";
}

QMetaObject *IAEX::InputCell::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__InputCell( "IAEX::InputCell", &IAEX::InputCell::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::InputCell::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::InputCell", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::InputCell::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::InputCell", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::InputCell::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = Cell::staticMetaObject();
    static const QUMethod slot_0 = {"eval", 0, 0 };
    static const QUMethod slot_1 = {"contentChanged", 0, 0 };
    static const QUParameter param_slot_2[] = {
	{ "closed", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"setClosed", 1, param_slot_2 };
    static const QUParameter param_slot_3[] = {
	{ "focus", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_3 = {"setFocus", 1, param_slot_3 };
    static const QUParameter param_slot_4[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In },
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_4 = {"clickEvent", 2, param_slot_4 };
    static const QUParameter param_slot_5[] = {
	{ "style", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_5 = {"setStyle", 1, param_slot_5 };
    static const QUParameter param_slot_6[] = {
	{ "name", &static_QUType_QString, 0, QUParameter::In },
	{ "val", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_6 = {"setStyle", 2, param_slot_6 };
    static const QMetaData slot_tbl[] = {
	{ "eval()", &slot_0, QMetaData::Public },
	{ "contentChanged()", &slot_1, QMetaData::Public },
	{ "setClosed(const bool)", &slot_2, QMetaData::Public },
	{ "setFocus(const bool)", &slot_3, QMetaData::Public },
	{ "clickEvent(int,int)", &slot_4, QMetaData::Public },
	{ "setStyle(const QString&)", &slot_5, QMetaData::Public },
	{ "setStyle(const QString&,const QString&)", &slot_6, QMetaData::Public }
    };
    static const QUMethod signal_0 = {"textChanged", 0, 0 };
    static const QMetaData signal_tbl[] = {
	{ "textChanged()", &signal_0, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::InputCell", parentObject,
	slot_tbl, 7,
	signal_tbl, 1,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__InputCell.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::InputCell::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::InputCell" ) )
	return this;
    return Cell::qt_cast( clname );
}

// SIGNAL textChanged
void IAEX::InputCell::textChanged()
{
    activate_signal( staticMetaObject()->signalOffset() + 0 );
}

bool IAEX::InputCell::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: eval(); break;
    case 1: contentChanged(); break;
    case 2: setClosed((const bool)static_QUType_bool.get(_o+1)); break;
    case 3: setFocus((const bool)static_QUType_bool.get(_o+1)); break;
    case 4: clickEvent((int)static_QUType_int.get(_o+1),(int)static_QUType_int.get(_o+2)); break;
    case 5: setStyle((const QString&)static_QUType_QString.get(_o+1)); break;
    case 6: setStyle((const QString&)static_QUType_QString.get(_o+1),(const QString&)static_QUType_QString.get(_o+2)); break;
    default:
	return Cell::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::InputCell::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: textChanged(); break;
    default:
	return Cell::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::InputCell::qt_property( int id, int f, QVariant* v)
{
    return Cell::qt_property( id, f, v);
}

bool IAEX::InputCell::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
