/****************************************************************************
** Meta object code from reading C++ file 'documentview.h'
**
** Created: to 23. mar 15:11:42 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "documentview.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'documentview.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__DocumentView[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       0,    0, // methods
       0,    0, // properties
       0,    0, // enums/sets

       0        // eod
};

static const char qt_meta_stringdata_IAEX__DocumentView[] = {
    "IAEX::DocumentView\0"
};

const QMetaObject IAEX::DocumentView::staticMetaObject = {
    { &QMainWindow::staticMetaObject, qt_meta_stringdata_IAEX__DocumentView,
      qt_meta_data_IAEX__DocumentView, 0 }
};

const QMetaObject *IAEX::DocumentView::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::DocumentView::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__DocumentView))
	return static_cast<void*>(const_cast<DocumentView*>(this));
    return QMainWindow::qt_metacast(_clname);
}

int IAEX::DocumentView::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    return _id;
}
