/****************************************************************************
** IAEX::Cell meta object code from reading C++ file 'cell.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_cell.cpp,v 1.6 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "cell.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::Cell::className() const
{
    return "IAEX::Cell";
}

QMetaObject *IAEX::Cell::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__Cell( "IAEX::Cell", &IAEX::Cell::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::Cell::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::Cell", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::Cell::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::Cell", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::Cell::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QWidget::staticMetaObject();
    static const QUParameter param_slot_0[] = {
	{ "r", &static_QUType_ptr, "Rule", QUParameter::In }
    };
    static const QUMethod slot_0 = {"addRule", 1, param_slot_0 };
    static const QUParameter param_slot_1[] = {
	{ "style", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_1 = {"setStyle", 1, param_slot_1 };
    static const QUParameter param_slot_2[] = {
	{ "name", &static_QUType_QString, 0, QUParameter::In },
	{ "val", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_2 = {"setStyle", 2, param_slot_2 };
    static const QUParameter param_slot_3[] = {
	{ "text", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_3 = {"setText", 1, param_slot_3 };
    static const QUParameter param_slot_4[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_4 = {"setReadOnly", 1, param_slot_4 };
    static const QUParameter param_slot_5[] = {
	{ "color", &static_QUType_varptr, "\x0a", QUParameter::In }
    };
    static const QUMethod slot_5 = {"setBackgroundColor", 1, param_slot_5 };
    static const QUParameter param_slot_6[] = {
	{ "selected", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_6 = {"setSelected", 1, param_slot_6 };
    static const QUParameter param_slot_7[] = {
	{ "focus", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_7 = {"setFocus", 1, param_slot_7 };
    static const QUParameter param_slot_8[] = {
	{ "height", &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod slot_8 = {"setHeight", 1, param_slot_8 };
    static const QUParameter param_slot_9[] = {
	{ "hidden", &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod slot_9 = {"hideTreeView", 1, param_slot_9 };
    static const QUParameter param_slot_10[] = {
	{ "label", &static_QUType_ptr, "QLabel", QUParameter::In }
    };
    static const QUMethod slot_10 = {"setLabel", 1, param_slot_10 };
    static const QUParameter param_slot_11[] = {
	{ "newTreeWidget", &static_QUType_ptr, "TreeView", QUParameter::In }
    };
    static const QUMethod slot_11 = {"setTreeWidget", 1, param_slot_11 };
    static const QUParameter param_slot_12[] = {
	{ "newWidget", &static_QUType_ptr, "QWidget", QUParameter::In }
    };
    static const QUMethod slot_12 = {"setMainWidget", 1, param_slot_12 };
    static const QMetaData slot_tbl[] = {
	{ "addRule(Rule*)", &slot_0, QMetaData::Public },
	{ "setStyle(const QString&)", &slot_1, QMetaData::Public },
	{ "setStyle(const QString&,const QString&)", &slot_2, QMetaData::Public },
	{ "setText(QString)", &slot_3, QMetaData::Public },
	{ "setReadOnly(const bool)", &slot_4, QMetaData::Public },
	{ "setBackgroundColor(const QColor)", &slot_5, QMetaData::Public },
	{ "setSelected(const bool)", &slot_6, QMetaData::Public },
	{ "setFocus(const bool)", &slot_7, QMetaData::Public },
	{ "setHeight(const int)", &slot_8, QMetaData::Public },
	{ "hideTreeView(const bool)", &slot_9, QMetaData::Public },
	{ "setLabel(QLabel*)", &slot_10, QMetaData::Protected },
	{ "setTreeWidget(TreeView*)", &slot_11, QMetaData::Protected },
	{ "setMainWidget(QWidget*)", &slot_12, QMetaData::Protected }
    };
    static const QUParameter param_signal_0[] = {
	{ 0, &static_QUType_ptr, "Cell", QUParameter::In }
    };
    static const QUMethod signal_0 = {"clicked", 1, param_signal_0 };
    static const QUParameter param_signal_1[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod signal_1 = {"doubleClicked", 1, param_signal_1 };
    static const QUParameter param_signal_2[] = {
	{ 0, &static_QUType_int, 0, QUParameter::In }
    };
    static const QUMethod signal_2 = {"changedWidth", 1, param_signal_2 };
    static const QUParameter param_signal_3[] = {
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod signal_3 = {"selected", 1, param_signal_3 };
    static const QUParameter param_signal_4[] = {
	{ 0, &static_QUType_ptr, "Cell", QUParameter::In },
	{ 0, &static_QUType_ptr, "Qt::ButtonState", QUParameter::In }
    };
    static const QUMethod signal_4 = {"cellselected", 2, param_signal_4 };
    static const QUMethod signal_5 = {"heightChanged", 0, 0 };
    static const QUParameter param_signal_6[] = {
	{ "link", &static_QUType_ptr, "QUrl", QUParameter::In }
    };
    static const QUMethod signal_6 = {"openLink", 1, param_signal_6 };
    static const QUParameter param_signal_7[] = {
	{ 0, &static_QUType_ptr, "Cell", QUParameter::In },
	{ 0, &static_QUType_bool, 0, QUParameter::In }
    };
    static const QUMethod signal_7 = {"cellOpened", 2, param_signal_7 };
    static const QMetaData signal_tbl[] = {
	{ "clicked(Cell*)", &signal_0, QMetaData::Protected },
	{ "doubleClicked(int)", &signal_1, QMetaData::Protected },
	{ "changedWidth(const int)", &signal_2, QMetaData::Protected },
	{ "selected(const bool)", &signal_3, QMetaData::Protected },
	{ "cellselected(Cell*,Qt::ButtonState)", &signal_4, QMetaData::Protected },
	{ "heightChanged()", &signal_5, QMetaData::Protected },
	{ "openLink(QUrl*)", &signal_6, QMetaData::Protected },
	{ "cellOpened(Cell*,const bool)", &signal_7, QMetaData::Protected }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::Cell", parentObject,
	slot_tbl, 13,
	signal_tbl, 8,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__Cell.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::Cell::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::Cell" ) )
	return this;
    return QWidget::qt_cast( clname );
}

#include <qobjectdefs.h>
#include <qsignalslotimp.h>

// SIGNAL clicked
void IAEX::Cell::clicked( Cell* t0 )
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

// SIGNAL doubleClicked
void IAEX::Cell::doubleClicked( int t0 )
{
    activate_signal( staticMetaObject()->signalOffset() + 1, t0 );
}

// SIGNAL changedWidth
void IAEX::Cell::changedWidth( const int t0 )
{
    activate_signal( staticMetaObject()->signalOffset() + 2, t0 );
}

// SIGNAL selected
void IAEX::Cell::selected( const bool t0 )
{
    activate_signal_bool( staticMetaObject()->signalOffset() + 3, t0 );
}

// SIGNAL cellselected
void IAEX::Cell::cellselected( Cell* t0, Qt::ButtonState t1 )
{
    if ( signalsBlocked() )
	return;
    QConnectionList *clist = receivers( staticMetaObject()->signalOffset() + 4 );
    if ( !clist )
	return;
    QUObject o[3];
    static_QUType_ptr.set(o+1,t0);
    static_QUType_ptr.set(o+2,&t1);
    activate_signal( clist, o );
}

// SIGNAL heightChanged
void IAEX::Cell::heightChanged()
{
    activate_signal( staticMetaObject()->signalOffset() + 5 );
}

// SIGNAL openLink
void IAEX::Cell::openLink( QUrl* t0 )
{
    if ( signalsBlocked() )
	return;
    QConnectionList *clist = receivers( staticMetaObject()->signalOffset() + 6 );
    if ( !clist )
	return;
    QUObject o[2];
    static_QUType_ptr.set(o+1,t0);
    activate_signal( clist, o );
}

// SIGNAL cellOpened
void IAEX::Cell::cellOpened( Cell* t0, const bool t1 )
{
    if ( signalsBlocked() )
	return;
    QConnectionList *clist = receivers( staticMetaObject()->signalOffset() + 7 );
    if ( !clist )
	return;
    QUObject o[3];
    static_QUType_ptr.set(o+1,t0);
    static_QUType_bool.set(o+2,t1);
    activate_signal( clist, o );
}

bool IAEX::Cell::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: addRule((Rule*)static_QUType_ptr.get(_o+1)); break;
    case 1: setStyle((const QString&)static_QUType_QString.get(_o+1)); break;
    case 2: setStyle((const QString&)static_QUType_QString.get(_o+1),(const QString&)static_QUType_QString.get(_o+2)); break;
    case 3: setText((QString)static_QUType_QString.get(_o+1)); break;
    case 4: setReadOnly((const bool)static_QUType_bool.get(_o+1)); break;
    case 5: setBackgroundColor((const QColor)(*((const QColor*)static_QUType_ptr.get(_o+1)))); break;
    case 6: setSelected((const bool)static_QUType_bool.get(_o+1)); break;
    case 7: setFocus((const bool)static_QUType_bool.get(_o+1)); break;
    case 8: setHeight((const int)static_QUType_int.get(_o+1)); break;
    case 9: hideTreeView((const bool)static_QUType_bool.get(_o+1)); break;
    case 10: setLabel((QLabel*)static_QUType_ptr.get(_o+1)); break;
    case 11: setTreeWidget((TreeView*)static_QUType_ptr.get(_o+1)); break;
    case 12: setMainWidget((QWidget*)static_QUType_ptr.get(_o+1)); break;
    default:
	return QWidget::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::Cell::qt_emit( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->signalOffset() ) {
    case 0: clicked((Cell*)static_QUType_ptr.get(_o+1)); break;
    case 1: doubleClicked((int)static_QUType_int.get(_o+1)); break;
    case 2: changedWidth((const int)static_QUType_int.get(_o+1)); break;
    case 3: selected((const bool)static_QUType_bool.get(_o+1)); break;
    case 4: cellselected((Cell*)static_QUType_ptr.get(_o+1),(Qt::ButtonState)(*((Qt::ButtonState*)static_QUType_ptr.get(_o+2)))); break;
    case 5: heightChanged(); break;
    case 6: openLink((QUrl*)static_QUType_ptr.get(_o+1)); break;
    case 7: cellOpened((Cell*)static_QUType_ptr.get(_o+1),(const bool)static_QUType_bool.get(_o+2)); break;
    default:
	return QWidget::qt_emit(_id,_o);
    }
    return TRUE;
}
#ifndef QT_NO_PROPERTIES

bool IAEX::Cell::qt_property( int id, int f, QVariant* v)
{
    return QWidget::qt_property( id, f, v);
}

bool IAEX::Cell::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
