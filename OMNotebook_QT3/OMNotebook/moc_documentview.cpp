/****************************************************************************
** IAEX::DocumentView meta object code from reading C++ file 'documentview.h'
**
** Created: ti 25. okt 11:26:39 2005
**      by: The Qt MOC ($Id: moc_documentview.cpp,v 1.6 2005/10/26 07:24:36 x05andfe Exp $)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#undef QT_NO_COMPAT
#include "documentview.h"
#include <qmetaobject.h>
#include <qapplication.h>

#include <private/qucomextra_p.h>
#if !defined(Q_MOC_OUTPUT_REVISION) || (Q_MOC_OUTPUT_REVISION != 26)
#error "This file was generated using the moc from 3.3.5. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

const char *IAEX::DocumentView::className() const
{
    return "IAEX::DocumentView";
}

QMetaObject *IAEX::DocumentView::metaObj = 0;
static QMetaObjectCleanUp cleanUp_IAEX__DocumentView( "IAEX::DocumentView", &IAEX::DocumentView::staticMetaObject );

#ifndef QT_NO_TRANSLATION
QString IAEX::DocumentView::tr( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::DocumentView", s, c, QApplication::DefaultCodec );
    else
	return QString::fromLatin1( s );
}
#ifndef QT_NO_TRANSLATION_UTF8
QString IAEX::DocumentView::trUtf8( const char *s, const char *c )
{
    if ( qApp )
	return qApp->translate( "IAEX::DocumentView", s, c, QApplication::UnicodeUTF8 );
    else
	return QString::fromUtf8( s );
}
#endif // QT_NO_TRANSLATION_UTF8

#endif // QT_NO_TRANSLATION

QMetaObject* IAEX::DocumentView::staticMetaObject()
{
    if ( metaObj )
	return metaObj;
    QMetaObject* parentObject = QMainWindow::staticMetaObject();
    metaObj = QMetaObject::new_metaobject(
	"IAEX::DocumentView", parentObject,
	0, 0,
	0, 0,
#ifndef QT_NO_PROPERTIES
	0, 0,
	0, 0,
#endif // QT_NO_PROPERTIES
	0, 0 );
    cleanUp_IAEX__DocumentView.setMetaObject( metaObj );
    return metaObj;
}

void* IAEX::DocumentView::qt_cast( const char* clname )
{
    if ( !qstrcmp( clname, "IAEX::DocumentView" ) )
	return this;
    return QMainWindow::qt_cast( clname );
}

bool IAEX::DocumentView::qt_invoke( int _id, QUObject* _o )
{
    return QMainWindow::qt_invoke(_id,_o);
}

bool IAEX::DocumentView::qt_emit( int _id, QUObject* _o )
{
    return QMainWindow::qt_emit(_id,_o);
}
#ifndef QT_NO_PROPERTIES

bool IAEX::DocumentView::qt_property( int id, int f, QVariant* v)
{
    return QMainWindow::qt_property( id, f, v);
}

bool IAEX::DocumentView::qt_static_property( QObject* , int , int , QVariant* ){ return FALSE; }
#endif // QT_NO_PROPERTIES
