/****************************************************************************
** Meta object code from reading C++ file 'inputcell.h'
**
** Created: ti 31. jan 11:17:16 2006
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "inputcell.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'inputcell.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__InputCell[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      20,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      17,   16,   16,   16, 0x05,
      31,   16,   16,   16, 0x05,

 // slots: signature, parameters, type, tag, flags
      49,   16,   16,   16, 0x0a,
      56,   16,   16,   16, 0x0a,
      66,   16,   16,   16, 0x0a,
      80,   16,   16,   16, 0x0a,
      92,   16,   16,   16, 0x0a,
     105,   16,   16,   16, 0x0a,
     127,  122,   16,   16, 0x0a,
     149,  144,   16,   16, 0x0a,
     177,  170,   16,   16, 0x0a,
     200,  144,   16,   16, 0x0a,
     237,  227,   16,   16, 0x0a,
     261,  255,   16,   16, 0x0a,
     290,  281,   16,   16, 0x0a,
     318,  308,   16,   16, 0x0a,
     344,  337,   16,   16, 0x0a,
     366,  360,   16,   16, 0x0a,
     381,   16,   16,   16, 0x08,
     400,   16,   16,   16, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__InputCell[] = {
    "IAEX::InputCell\0\0textChanged()\0textChanged(bool)\0eval()\0command()\0"
    "nextCommand()\0nextField()\0clickEvent()\0contentChanged()\0text\0"
    "setText(QString)\0html\0setTextHtml(QString)\0output\0"
    "setTextOutput(QString)\0setTextOutputHtml(QString)\0stylename\0"
    "setStyle(QString)\0style\0setStyle(CellStyle)\0readonly\0"
    "setReadOnly(bool)\0evaluated\0setEvaluated(bool)\0closed\0"
    "setClosed(bool)\0focus\0setFocus(bool)\0addToHighlighter()\0"
    "charFormatChanged(QTextCharFormat)\0"
};

const QMetaObject IAEX::InputCell::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__InputCell,
      qt_meta_data_IAEX__InputCell, 0 }
};

const QMetaObject *IAEX::InputCell::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::InputCell::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__InputCell))
	return static_cast<void*>(const_cast<InputCell*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::InputCell::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: textChanged(); break;
        case 1: textChanged(*(bool*)_a[1]); break;
        case 2: eval(); break;
        case 3: command(); break;
        case 4: nextCommand(); break;
        case 5: nextField(); break;
        case 6: clickEvent(); break;
        case 7: contentChanged(); break;
        case 8: setText(*(QString*)_a[1]); break;
        case 9: setTextHtml(*(QString*)_a[1]); break;
        case 10: setTextOutput(*(QString*)_a[1]); break;
        case 11: setTextOutputHtml(*(QString*)_a[1]); break;
        case 12: setStyle(*(QString*)_a[1]); break;
        case 13: setStyle(*(CellStyle*)_a[1]); break;
        case 14: setReadOnly(*(bool*)_a[1]); break;
        case 15: setEvaluated(*(bool*)_a[1]); break;
        case 16: setClosed(*(bool*)_a[1]); break;
        case 17: setFocus(*(bool*)_a[1]); break;
        case 18: addToHighlighter(); break;
        case 19: charFormatChanged(*(QTextCharFormat*)_a[1]); break;
        }
        _id -= 20;
    }
    return _id;
}

// SIGNAL 0
void IAEX::InputCell::textChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::InputCell::textChanged(bool _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}
static const uint qt_meta_data_IAEX__MyTextEdit[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      18,   17,   17,   17, 0x05,
      32,   17,   17,   17, 0x05,
      56,   17,   17,   17, 0x05,
      66,   17,   17,   17, 0x05,
      80,   17,   17,   17, 0x05,
      92,   17,   17,   17, 0x05,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__MyTextEdit[] = {
    "IAEX::MyTextEdit\0\0clickOnCell()\0wheelMove(QWheelEvent*)\0command()\0"
    "nextCommand()\0nextField()\0eval()\0"
};

const QMetaObject IAEX::MyTextEdit::staticMetaObject = {
    { &QTextBrowser::staticMetaObject, qt_meta_stringdata_IAEX__MyTextEdit,
      qt_meta_data_IAEX__MyTextEdit, 0 }
};

const QMetaObject *IAEX::MyTextEdit::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::MyTextEdit::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__MyTextEdit))
	return static_cast<void*>(const_cast<MyTextEdit*>(this));
    return QTextBrowser::qt_metacast(_clname);
}

int IAEX::MyTextEdit::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QTextBrowser::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: clickOnCell(); break;
        case 1: wheelMove(*(QWheelEvent**)_a[1]); break;
        case 2: command(); break;
        case 3: nextCommand(); break;
        case 4: nextField(); break;
        case 5: eval(); break;
        }
        _id -= 6;
    }
    return _id;
}

// SIGNAL 0
void IAEX::MyTextEdit::clickOnCell()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::MyTextEdit::wheelMove(QWheelEvent * _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void IAEX::MyTextEdit::command()
{
    QMetaObject::activate(this, &staticMetaObject, 2, 0);
}

// SIGNAL 3
void IAEX::MyTextEdit::nextCommand()
{
    QMetaObject::activate(this, &staticMetaObject, 3, 0);
}

// SIGNAL 4
void IAEX::MyTextEdit::nextField()
{
    QMetaObject::activate(this, &staticMetaObject, 4, 0);
}

// SIGNAL 5
void IAEX::MyTextEdit::eval()
{
    QMetaObject::activate(this, &staticMetaObject, 5, 0);
}
