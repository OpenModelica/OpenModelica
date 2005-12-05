/****************************************************************************
** IAEX::TextCell meta object code from reading C++ file 'textcell.h'
**
** Created: ti 25. okt 11:26:38 2005
**      by: The Qt MOC ($Id: moc_textcell.cpp,v 1.6 2005/10/26 07:24:37 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "textcell.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::TextCell::className() const
{
    return "IAEX::TextCell";
}

QMetaObject *IAEX::TextCell::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__TextCell( "IAEX::TextCell", &IAEX::TextCell::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::TextCell::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::TextCell", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::TextCell::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::TextCell", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::TextCell::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = Cell::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ "para", &static_QUType_int, 0, QUParameter::In },
	{ "pos", &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"clickEvent", 2, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ "readonly", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setReadOnly", 1, param_slot_1 };
    static const QUParameter param_slot_2[] = {
	{ "text", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"setText", 1, param_slot_2 };
    static const QUParameter param_slot_3[] = {
	{ "style", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_3 = {"setStyle", 1, param_slot_3 };
    static const QUParameter param_slot_4[] = {
	{ "name", &static_QUType_QString, 0, QUParameter::In },
	{ "val", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_4 = {"setStyle", 2, param_slot_4 };
    static const QUParameter param_slot_5[] = {
	{ "focus", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_5 = {"setFocus", 1, param_slot_5 };
    static const QUParameter param_slot_6[] = {
	{ "expr", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_6 = {"viewExpression", 1, param_slot_6 };
    static const QUMethod slot_7 = {"contentChanged", 0, 0 };
    static const QUParameter param_slot_8[] = {
	{ "url", &static_QUType_ptr, "QUrl", QUParameter::In }
    };
    static const QUMethod slot_8 = {"openLinkInternal", 1, param_slot_8 };
    static const QUMethod slot_9 = {"textChangedInternal", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "clickEvent(int,int)", &slot_0, QMetaData::Public },
	{ "setReadOnly(const bool)", &slot_1, QMetaData::Public },
	{ "setText(QString)", &slot_2, QMetaData::Public },
	{ "setStyle(const QString&)", &slot_3, QMetaData::Public },
	{ "setStyle(const QString&,const QString&)", &slot_4, QMetaData::Public },
	{ "setFocus(const bool)", &slot_5, QMetaData::Public },
	{ "viewExpression(const bool)", &slot_6, QMetaData::Public },
	{ "contentChanged()", &slot_7, QMetaData::Protected },
	{ "openLinkInternal(QUrl*)", &slot_8, QMetaData::Protected },
	{ "textChangedInternal()", &slot_9, QMetaData::Protected }
    };
    static const QUMethod signal_0 = {"textChanged", 0, 0 };
    static const QMetaData signal_tbl[] = {
	{ "textChanged()", &signal_0, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::TextCell", parentObject,
	slot_tbl, 10,
	signal_tbl, 1,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__TextCell.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::TextCell::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::TextCell" ) )
	return this;
    return Cell::qt_cast( clname );
}

// SIGNAL textChanged
void IAEX::TextCell::textChanged()
{
    activate_signal( staticMetaObject()->signalOffset() + 0 );
}

bool IAEX::TextCell::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: clickEvent((int)static_QUType_int.get(_o+1),(int)static_QUType_int.get(_o+2)); break;
    case 1: setReadOnly((const bool)static_QUType_bool.get(_o+1)); break;
    case 2: setText((QString)static_QUType_QString.get(_o+1)); break;
    case 3: setStyle((const QString&)static_QUType_QString.get(_o+1)); break;
    case 4: setStyle((const QString&)static_QUType_QString.get(_o+1),(const QString&)static_QUType_QString.get(_o+2)); break;
    case 5: setFocus((const bool)static_QUType_bool.get(_o+1)); break;
    case 6: viewExpression((const bool)static_QUType_bool.get(_o+1)); break;
    case 7: contentChanged(); break;
    case 8: openLinkInternal((QUrl*)static_QUType_ptr.get(_o+1)); break;
    case 9: textChangedInternal(); break;
    default:
	return Cell::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::TextCell::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: textChanged(); break;
    default:
	return Cell::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::TextCell::qt_property( int id, int f, QVariant* v)
{
    return Cell::qt_property( id, f, v);
}

bool IAEX::TextCell::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES


const char *IAEX::MyTextBrowser::className() const
{
    return "IAEX::MyTextBrowser";
}

QMetaObject *IAEX::MyTextBrowser::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__MyTextBrowser( "IAEX::MyTextBrowser", &IAEX::MyTextBrowser::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::MyTextBrowser::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::MyTextBrowser", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::MyTextBrowser::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::MyTextBrowser", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::MyTextBrowser::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QTextBrowser::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ "name", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_0 = {"setSource", 1, param_slot_0 };
    static const QMetaData slot_tbl[] = {
	{ "setSource(const QString&)", &slot_0, QMetaData::Public }
    };
    static const QUParameter param_signal_0[] = {
	{ 0, &static_QUType_ptr, "QUrl", QUParameter::In }
    };
    static const QUMethod signal_0 = {"openLink", 1, param_signal_0 };
    static const QMetaData signal_tbl[] = {
	{ "openLink(QUrl*)", &signal_0, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::MyTextBrowser", parentObject,
	slot_tbl, 1,
	signal_tbl, 1,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__MyTextBrowser.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::MyTextBrowser::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::MyTextBrowser" ) )
	return this;
    return QTextBrowser::qt_cast( clname );
}

#include <qobjectdefs.h>
#include <qsignalslotimp.h>

// SIGNAL openLink
void IAEX::MyTextBrowser::openLink( QUrl* t0 )
{
    if ( signalsBlocked() )
	return;
    QConnectionList *clist = receivers( staticMetaObject()->signalOffset() + 0 );
    if ( !clist )
	return;
    QUObject o[2];
    static_QUType_ptr.set(o+1,t0);
    activate_signal( clist, o );
}

bool IAEX::MyTextBrowser::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setSource((const QString&)static_QUType_QString.get(_o+1)); break;
    default:
	return QTextBrowser::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::MyTextBrowser::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: openLink((QUrl*)static_QUType_ptr.get(_o+1)); break;
    default:
	return QTextBrowser::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::MyTextBrowser::qt_property( int id, int f, QVariant* v)
{
    return QTextBrowser::qt_property( id, f, v);
}

bool IAEX::MyTextBrowser::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
