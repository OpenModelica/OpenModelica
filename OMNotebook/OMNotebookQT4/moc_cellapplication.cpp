/****************************************************************************
** Meta object code from reading C++ file 'cellapplication.h'
**
** Created: to 23. mar 15:11:42 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "cellapplication.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'cellapplication.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__CellApplication[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       0,    0, // methods
       0,    0, // properties
       0,    0, // enums/sets

       0        // eod
};

static const char qt_meta_stringdata_IAEX__CellApplication[] = {
    "IAEX::CellApplication\0"
};

const QMetaObject IAEX::CellApplication::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_IAEX__CellApplication,
      qt_meta_data_IAEX__CellApplication, 0 }
};

const QMetaObject *IAEX::CellApplication::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::CellApplication::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__CellApplication))
	return static_cast<void*>(const_cast<CellApplication*>(this));
    if (!strcmp(_clname, "Application"))
	return static_cast<Application*>(const_cast<CellApplication*>(this));
    return QObject::qt_metacast(_clname);
}

int IAEX::CellApplication::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    return _id;
}
