/****************************************************************************
** IAEX::NotebookWindow meta object code from reading C++ file 'notebook.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_notebook.cpp,v 1.7 2005/10/26 07:24:37 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "notebook.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::NotebookWindow::className() const
{
    return "IAEX::NotebookWindow";
}

QMetaObject *IAEX::NotebookWindow::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__NotebookWindow( "IAEX::NotebookWindow", &IAEX::NotebookWindow::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::NotebookWindow::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::NotebookWindow", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::NotebookWindow::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::NotebookWindow", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::NotebookWindow::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = DocumentView::staticMetaObject();
    static const QUMethod slot_0 = {"setSelectedStyle", 0, 0 };
    static const QUMethod slot_1 = {"updateStyleMenu", 0, 0 };
    static const QUMethod slot_2 = {"newFile", 0, 0 };
    static const QUMethod slot_3 = {"openFile", 0, 0 };
    static const QUParameter param_slot_4[] = {
	{ "filename", &static_QUType_QString, 0, QUParameter::In }
    };
    static const QUMethod slot_4 = {"openFile", 1, param_slot_4 };
    static const QUMethod slot_5 = {"closeFile", 0, 0 };
    static const QUMethod slot_6 = {"aboutQTNotebook", 0, 0 };
    static const QUMethod slot_7 = {"saveas", 0, 0 };
    static const QUMethod slot_8 = {"save", 0, 0 };
    static const QUParameter param_slot_9[] = {
	{ "action", &static_QUType_ptr, "QAction", QUParameter::In }
    };
    static const QUMethod slot_9 = {"changeStyle", 1, param_slot_9 };
    static const QUMethod slot_10 = {"changeStyle", 0, 0 };
    static const QUMethod slot_11 = {"createNewCell", 0, 0 };
    static const QUMethod slot_12 = {"deleteCurrentCell", 0, 0 };
    static const QUMethod slot_13 = {"cutCell", 0, 0 };
    static const QUMethod slot_14 = {"copyCell", 0, 0 };
    static const QUMethod slot_15 = {"pasteCell", 0, 0 };
    static const QUMethod slot_16 = {"moveCursorUp", 0, 0 };
    static const QUMethod slot_17 = {"moveCursorDown", 0, 0 };
    static const QUMethod slot_18 = {"groupCellsAction", 0, 0 };
    static const QUMethod slot_19 = {"inputCellsAction", 0, 0 };
    static const QMetaData slot_tbl[] = {
	{ "setSelectedStyle()", &slot_0, QMetaData::Public },
	{ "updateStyleMenu()", &slot_1, QMetaData::Public },
	{ "newFile()", &slot_2, QMetaData::Private },
	{ "openFile()", &slot_3, QMetaData::Private },
	{ "openFile(const QString&)", &slot_4, QMetaData::Private },
	{ "closeFile()", &slot_5, QMetaData::Private },
	{ "aboutQTNotebook()", &slot_6, QMetaData::Private },
	{ "saveas()", &slot_7, QMetaData::Private },
	{ "save()", &slot_8, QMetaData::Private },
	{ "changeStyle(QAction*)", &slot_9, QMetaData::Private },
	{ "changeStyle()", &slot_10, QMetaData::Private },
	{ "createNewCell()", &slot_11, QMetaData::Private },
	{ "deleteCurrentCell()", &slot_12, QMetaData::Private },
	{ "cutCell()", &slot_13, QMetaData::Private },
	{ "copyCell()", &slot_14, QMetaData::Private },
	{ "pasteCell()", &slot_15, QMetaData::Private },
	{ "moveCursorUp()", &slot_16, QMetaData::Private },
	{ "moveCursorDown()", &slot_17, QMetaData::Private },
	{ "groupCellsAction()", &slot_18, QMetaData::Private },
	{ "inputCellsAction()", &slot_19, QMetaData::Private }
    };
    metaObj = QMetaObject::new_metaobject(
	"IAEX::NotebookWindow", parentObject,
	slot_tbl, 20,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__NotebookWindow.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::NotebookWindow::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::NotebookWindow" ) )
	return this;
    return DocumentView::qt_cast( clname );
}

bool IAEX::NotebookWindow::qt_invoke( int _id, QUObject* _o )
{
    switch ( _id - staticMetaObject()->slotOffset() ) {
    case 0: setSelectedStyle(); break;
    case 1: updateStyleMenu(); break;
    case 2: newFile(); break;
    case 3: openFile(); break;
    case 4: openFile((const QString&)static_QUType_QString.get(_o+1)); break;
    case 5: closeFile(); break;
    case 6: aboutQTNotebook(); break;
    case 7: saveas(); break;
    case 8: save(); break;
    case 9: changeStyle((QAction*)static_QUType_ptr.get(_o+1)); break;
    case 10: changeStyle(); break;
    case 11: createNewCell(); break;
    case 12: deleteCurrentCell(); break;
    case 13: cutCell(); break;
    case 14: copyCell(); break;
    case 15: pasteCell(); break;
    case 16: moveCursorUp(); break;
    case 17: moveCursorDown(); break;
    case 18: groupCellsAction(); break;
    case 19: inputCellsAction(); break;
    default:
	return DocumentView::qt_invoke( _id, _o );
    }
    return TRUE;
}

bool IAEX::NotebookWindow::qt_emit( int _id, QUObject* _o )
{
    return DocumentView::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool IAEX::NotebookWindow::qt_property( int id, int f, QVariant* v)
{
    return DocumentView::qt_property( id, f, v);
}

bool IAEX::NotebookWindow::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
