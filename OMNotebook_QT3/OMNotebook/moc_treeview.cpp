/****************************************************************************
** IAEX::TreeView meta object code from reading C++ file 'treeview.h'
**
** Created: ti 25. okt 11:26:38 2005
**      by: The Qt MOC ($Id: moc_treeview.cpp,v 1.6 2005/10/26 07:24:37 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "treeview.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::TreeView::className() const
{
    return "IAEX::TreeView";
}

QMetaObject *IAEX::TreeView::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__TreeView( "IAEX::TreeView", &IAEX::TreeView::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::TreeView::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::TreeView", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::TreeView::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::TreeView", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::TreeView::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QWidget::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ "closed", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"setClosed", 1, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ "sel", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setSelected", 1, param_slot_1 };
    static const QMetaData slot_tbl[] = {
	{ "setClosed(const bool)", &slot_0, QMetaData::Public },
	{ "setSelected(const bool)", &slot_1, QMetaData::Public }
    };
    static const QUParameter param_signal_0[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod signal_0 = {"becomeSelected", 1, param_signal_0 };
    static const QMetaData signal_tbl[] = {
	{ "becomeSelected(bool)", &signal_0, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::TreeView", parentObject,
	slot_tbl, 2,
	signal_tbl, 1,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__TreeView.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::TreeView::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::TreeView" ) )
	return this;
    return QWidget::qt_cast( clname );
}

// SIGNAL becomeSelected
void IAEX::TreeView::becomeSelected( bool t0 )
{
    activate_signal_bool( staticMetaObject()->signalOffset() + 0, t0 );
}

bool IAEX::TreeView::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setClosed((const bool)static_QUType_bool.get(_o+1)); break;
    case 1: setSelected((const bool)static_QUType_bool.get(_o+1)); break;
    default:
	return QWidget::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::TreeView::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: becomeSelected((bool)static_QUType_bool.get(_o+1)); break;
    default:
	return QWidget::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::TreeView::qt_property( int id, int f, QVariant* v)
{
    return QWidget::qt_property( id, f, v);
}

bool IAEX::TreeView::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
