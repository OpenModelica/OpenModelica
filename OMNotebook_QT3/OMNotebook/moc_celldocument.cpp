/****************************************************************************
** IAEX::CellDocument meta object code from reading C++ file 'celldocument.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_celldocument.cpp,v 1.7 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "celldocument.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::CellDocument::className() const
{
    return "IAEX::CellDocument";
}

QMetaObject *IAEX::CellDocument::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__CellDocument( "IAEX::CellDocument", &IAEX::CellDocument::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::CellDocument::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellDocument", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::CellDocument::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::CellDocument", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::CellDocument::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = Document::staticMetaObject();
    static const QUMethod slot_0 = {"toggleMainTreeView", 0, 0 };
    static const QUParameter param_slot_1[] = {
	{ "editable", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setEditable", 1, param_slot_1 };
    static const QUMethod slot_2 = {"cursorChangedPosition", 0, 0 };
    static const QUParameter param_slot_3[] = {
	{ "selected", &static_QUType_ptr, "Cell", QUParameter::In },
	{ 0, &static_QUType_ptr, "Qt::ButtonState", QUParameter::In }
    };
    static const QUMethod slot_3 = {"selectedACell", 2, param_slot_3 };
    static const QUMethod slot_4 = {"clearSelection", 0, 0 };
    static const QUParameter param_slot_5[] = {
	{ "clickedCell", &static_QUType_ptr, "Cell", QUParameter::In }
    };
    static const QUMethod slot_5 = {"mouseClickedOnCell", 1, param_slot_5 };
    static const QUParameter param_slot_6[] = {
	{ "url", &static_QUType_ptr, "QUrl", QUParameter::In }
    };
    static const QUMethod slot_6 = {"linkClicked", 1, param_slot_6 };
    static const QUParameter param_slot_7[] = {
	{ "aCell", &static_QUType_ptr, "Cell", QUParameter::In },
	{ "open", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_7 = {"cursorMoveAfter", 2, param_slot_7 };
    static const QUParameter param_slot_8[] = {
	{ "b", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_8 = {"showHTML", 1, param_slot_8 };
    static const QMetaData slot_tbl[] = {
	{ "toggleMainTreeView()", &slot_0, QMetaData::Public },
	{ "setEditable(bool)", &slot_1, QMetaData::Public },
	{ "cursorChangedPosition()", &slot_2, QMetaData::Public },
	{ "selectedACell(Cell*,Qt::ButtonState)", &slot_3, QMetaData::Public },
	{ "clearSelection()", &slot_4, QMetaData::Public },
	{ "mouseClickedOnCell(Cell*)", &slot_5, QMetaData::Public },
	{ "linkClicked(QUrl*)", &slot_6, QMetaData::Public },
	{ "cursorMoveAfter(Cell*,const bool)", &slot_7, QMetaData::Public },
	{ "showHTML(bool)", &slot_8, QMetaData::Public }
    };
    static const QUParameter param_signal_0[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod signal_0 = {"widthChanged", 1, param_signal_0 };
    static const QUMethod signal_1 = {"cursorChanged", 0, 0 };
    static const QUParameter param_signal_2[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod signal_2 = {"viewExpression", 1, param_signal_2 };
    static const QMetaData signal_tbl[] = {
	{ "widthChanged(const int)", &signal_0, QMetaData::Public },
	{ "cursorChanged()", &signal_1, QMetaData::Public },
	{ "viewExpression(const bool)", &signal_2, QMetaData::Public }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::CellDocument", parentObject,
	slot_tbl, 9,
	signal_tbl, 3,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__CellDocument.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::CellDocument::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::CellDocument" ) )
	return this;
    return Document::qt_cast( clname );
}

// SIGNAL widthChanged
void IAEX::CellDocument::widthChanged( const int t0 )
{
    activate_signal( staticMetaObject()->signalOffset() + 0, t0 );
}

// SIGNAL cursorChanged
void IAEX::CellDocument::cursorChanged()
{
    activate_signal( staticMetaObject()->signalOffset() + 1 );
}

// SIGNAL viewExpression
void IAEX::CellDocument::viewExpression( const bool t0 )
{
    activate_signal_bool( staticMetaObject()->signalOffset() + 2, t0 );
}

bool IAEX::CellDocument::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: toggleMainTreeView(); break;
    case 1: setEditable((bool)static_QUType_bool.get(_o+1)); break;
    case 2: cursorChangedPosition(); break;
    case 3: selectedACell((Cell*)static_QUType_ptr.get(_o+1),(Qt::ButtonState)(*((Qt::ButtonState*)static_QUType_ptr.get(_o+2)))); break;
    case 4: clearSelection(); break;
    case 5: mouseClickedOnCell((Cell*)static_QUType_ptr.get(_o+1)); break;
    case 6: linkClicked((QUrl*)static_QUType_ptr.get(_o+1)); break;
    case 7: cursorMoveAfter((Cell*)static_QUType_ptr.get(_o+1),(const bool)static_QUType_bool.get(_o+2)); break;
    case 8: showHTML((bool)static_QUType_bool.get(_o+1)); break;
    default:
	return Document::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::CellDocument::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: widthChanged((const int)static_QUType_int.get(_o+1)); break;
    case 1: cursorChanged(); break;
    case 2: viewExpression((const bool)static_QUType_bool.get(_o+1)); break;
    default:
	return Document::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::CellDocument::qt_property( int id, int f, QVariant* v)
{
    return Document::qt_property( id, f, v);
}

bool IAEX::CellDocument::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
