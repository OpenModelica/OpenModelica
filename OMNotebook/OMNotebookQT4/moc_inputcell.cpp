/****************************************************************************
** Meta object code from reading C++ file 'inputcell.h'
**
** Created: fr 3. feb 16:00:33 2006
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
      23,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      17,   16,   16,   16, 0x05,
      31,   16,   16,   16, 0x05,
      49,   16,   16,   16, 0x05,

 // slots: signature, parameters, type, tag, flags
      70,   16,   16,   16, 0x0a,
      77,   16,   16,   16, 0x0a,
      87,   16,   16,   16, 0x0a,
     101,   16,   16,   16, 0x0a,
     113,   16,   16,   16, 0x0a,
     126,   16,   16,   16, 0x0a,
     145,   16,   16,   16, 0x0a,
     167,  162,   16,   16, 0x0a,
     189,  184,   16,   16, 0x0a,
     217,  210,   16,   16, 0x0a,
     240,  184,   16,   16, 0x0a,
     277,  267,   16,   16, 0x0a,
     301,  295,   16,   16, 0x0a,
     330,  321,   16,   16, 0x0a,
     358,  348,   16,   16, 0x0a,
     384,  377,   16,   16, 0x0a,
     406,  400,   16,   16, 0x0a,
     421,  400,   16,   16, 0x0a,
     442,   16,   16,   16, 0x08,
     461,   16,   16,   16, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__InputCell[] = {
    "IAEX::InputCell\0\0textChanged()\0textChanged(bool)\0"
    "clickedOutput(Cell*)\0eval()\0command()\0nextCommand()\0nextField()\0"
    "clickEvent()\0clickEventOutput()\0contentChanged()\0text\0"
    "setText(QString)\0html\0setTextHtml(QString)\0output\0"
    "setTextOutput(QString)\0setTextOutputHtml(QString)\0stylename\0"
    "setStyle(QString)\0style\0setStyle(CellStyle)\0readonly\0"
    "setReadOnly(bool)\0evaluated\0setEvaluated(bool)\0closed\0"
    "setClosed(bool)\0focus\0setFocus(bool)\0setFocusOutput(bool)\0"
    "addToHighlighter()\0charFormatChanged(QTextCharFormat)\0"
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
        case 2: clickedOutput(*(Cell**)_a[1]); break;
        case 3: eval(); break;
        case 4: command(); break;
        case 5: nextCommand(); break;
        case 6: nextField(); break;
        case 7: clickEvent(); break;
        case 8: clickEventOutput(); break;
        case 9: contentChanged(); break;
        case 10: setText(*(QString*)_a[1]); break;
        case 11: setTextHtml(*(QString*)_a[1]); break;
        case 12: setTextOutput(*(QString*)_a[1]); break;
        case 13: setTextOutputHtml(*(QString*)_a[1]); break;
        case 14: setStyle(*(QString*)_a[1]); break;
        case 15: setStyle(*(CellStyle*)_a[1]); break;
        case 16: setReadOnly(*(bool*)_a[1]); break;
        case 17: setEvaluated(*(bool*)_a[1]); break;
        case 18: setClosed(*(bool*)_a[1]); break;
        case 19: setFocus(*(bool*)_a[1]); break;
        case 20: setFocusOutput(*(bool*)_a[1]); break;
        case 21: addToHighlighter(); break;
        case 22: charFormatChanged(*(QTextCharFormat*)_a[1]); break;
        }
        _id -= 23;
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

// SIGNAL 2
void IAEX::InputCell::clickedOutput(Cell * _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
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
