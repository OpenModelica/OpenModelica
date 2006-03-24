/****************************************************************************
** Meta object code from reading C++ file 'document.h'
**
** Created: to 23. mar 15:11:42 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "document.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'document.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__Document[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // slots: signature, parameters, type, tag, flags
      16,   15,   15,   15, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__Document[] = {
    "IAEX::Document\0\0updateScrollArea()\0"
};

const QMetaObject IAEX::Document::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_IAEX__Document,
      qt_meta_data_IAEX__Document, 0 }
};

const QMetaObject *IAEX::Document::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::Document::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__Document))
	return static_cast<void*>(const_cast<Document*>(this));
    return QObject::qt_metacast(_clname);
}

int IAEX::Document::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: updateScrollArea(); break;
        }
        _id -= 1;
    }
    return _id;
}
