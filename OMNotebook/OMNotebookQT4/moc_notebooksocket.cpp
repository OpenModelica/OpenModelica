/****************************************************************************
** Meta object code from reading C++ file 'notebooksocket.h'
**
** Created: on 3. maj 10:58:53 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "notebooksocket.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'notebooksocket.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__NotebookSocket[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       2,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // slots: signature, parameters, type, tag, flags
      22,   21,   21,   21, 0x08,
      45,   21,   21,   21, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__NotebookSocket[] = {
    "IAEX::NotebookSocket\0\0receiveNewConnection()\0receiveNewSocketMsg()\0"
};

const QMetaObject IAEX::NotebookSocket::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_IAEX__NotebookSocket,
      qt_meta_data_IAEX__NotebookSocket, 0 }
};

const QMetaObject *IAEX::NotebookSocket::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::NotebookSocket::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__NotebookSocket))
	return static_cast<void*>(const_cast<NotebookSocket*>(this));
    return QObject::qt_metacast(_clname);
}

int IAEX::NotebookSocket::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: receiveNewConnection(); break;
        case 1: receiveNewSocketMsg(); break;
        }
        _id -= 2;
    }
    return _id;
}
