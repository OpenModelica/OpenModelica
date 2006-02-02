/****************************************************************************
** Meta object code from reading C++ file 'smlinteractiveenvironment.h'
**
** Created: on 2. nov 13:31:55 2005
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "smlinteractiveenvironment.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'smlinteractiveenvironment.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__SmlInteractiveEnvironment[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       2,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // slots: signature, parameters, type, tag, flags
      33,   32,   32,   32, 0x0a,
      48,   32,   32,   32, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__SmlInteractiveEnvironment[] = {
    "IAEX::SmlInteractiveEnvironment\0\0updateOutput()\0updateErrorOutput()\0"
};

const QMetaObject IAEX::SmlInteractiveEnvironment::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_IAEX__SmlInteractiveEnvironment,
      qt_meta_data_IAEX__SmlInteractiveEnvironment, 0 }
};

const QMetaObject *IAEX::SmlInteractiveEnvironment::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::SmlInteractiveEnvironment::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__SmlInteractiveEnvironment))
	return static_cast<void*>(const_cast<SmlInteractiveEnvironment*>(this));
    if (!strcmp(_clname, "InputCellDelegate"))
	return static_cast<InputCellDelegate*>(const_cast<SmlInteractiveEnvironment*>(this));
    return QObject::qt_metacast(_clname);
}

int IAEX::SmlInteractiveEnvironment::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: updateOutput(); break;
        case 1: updateErrorOutput(); break;
        }
        _id -= 2;
    }
    return _id;
}
