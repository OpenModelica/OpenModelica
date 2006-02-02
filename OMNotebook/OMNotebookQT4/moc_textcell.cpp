/****************************************************************************
** Meta object code from reading C++ file 'textcell.h'
**
** Created: må 30. jan 11:51:23 2006
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "textcell.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'textcell.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__TextCell[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      14,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      16,   15,   15,   15, 0x05,
      30,   15,   15,   15, 0x05,

 // slots: signature, parameters, type, tag, flags
      48,   15,   15,   15, 0x0a,
      66,   61,   15,   15, 0x0a,
      95,   83,   15,   15, 0x0a,
     133,  128,   15,   15, 0x0a,
     164,  154,   15,   15, 0x0a,
     188,  182,   15,   15, 0x0a,
     217,  208,   15,   15, 0x0a,
     241,  235,   15,   15, 0x0a,
     256,   15,   15,   15, 0x09,
     277,  273,   15,   15, 0x09,
     307,   15,   15,   15, 0x09,
     329,   15,   15,   15, 0x09,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__TextCell[] = {
    "IAEX::TextCell\0\0textChanged()\0textChanged(bool)\0clickEvent()\0text\0"
    "setText(QString)\0text,format\0setText(QString,QTextCharFormat)\0html\0"
    "setTextHtml(QString)\0stylename\0setStyle(QString)\0style\0"
    "setStyle(CellStyle)\0readonly\0setReadOnly(bool)\0focus\0setFocus(bool)\0"
    "contentChanged()\0url\0openLinkInternal(const QUrl*)\0"
    "textChangedInternal()\0charFormatChanged(QTextCharFormat)\0"
};

const QMetaObject IAEX::TextCell::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__TextCell,
      qt_meta_data_IAEX__TextCell, 0 }
};

const QMetaObject *IAEX::TextCell::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::TextCell::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__TextCell))
	return static_cast<void*>(const_cast<TextCell*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::TextCell::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: textChanged(); break;
        case 1: textChanged(*(bool*)_a[1]); break;
        case 2: clickEvent(); break;
        case 3: setText(*(QString*)_a[1]); break;
        case 4: setText(*(QString*)_a[1],*(QTextCharFormat*)_a[2]); break;
        case 5: setTextHtml(*(QString*)_a[1]); break;
        case 6: setStyle(*(QString*)_a[1]); break;
        case 7: setStyle(*(CellStyle*)_a[1]); break;
        case 8: setReadOnly(*(bool*)_a[1]); break;
        case 9: setFocus(*(bool*)_a[1]); break;
        case 10: contentChanged(); break;
        case 11: openLinkInternal(*(const QUrl**)_a[1]); break;
        case 12: textChangedInternal(); break;
        case 13: charFormatChanged(*(QTextCharFormat*)_a[1]); break;
        }
        _id -= 14;
    }
    return _id;
}

// SIGNAL 0
void IAEX::TextCell::textChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::TextCell::textChanged(bool _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}
static const uint qt_meta_data_IAEX__MyTextBrowser[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      21,   20,   20,   20, 0x05,
      43,   20,   20,   20, 0x05,
      57,   20,   20,   20, 0x05,

 // slots: signature, parameters, type, tag, flags
      86,   81,   20,   20, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__MyTextBrowser[] = {
    "IAEX::MyTextBrowser\0\0openLink(const QUrl*)\0clickOnCell()\0"
    "wheelMove(QWheelEvent*)\0name\0setSource(QUrl)\0"
};

const QMetaObject IAEX::MyTextBrowser::staticMetaObject = {
    { &QTextBrowser::staticMetaObject, qt_meta_stringdata_IAEX__MyTextBrowser,
      qt_meta_data_IAEX__MyTextBrowser, 0 }
};

const QMetaObject *IAEX::MyTextBrowser::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::MyTextBrowser::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__MyTextBrowser))
	return static_cast<void*>(const_cast<MyTextBrowser*>(this));
    return QTextBrowser::qt_metacast(_clname);
}

int IAEX::MyTextBrowser::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QTextBrowser::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: openLink(*(const QUrl**)_a[1]); break;
        case 1: clickOnCell(); break;
        case 2: wheelMove(*(QWheelEvent**)_a[1]); break;
        case 3: setSource(*(QUrl*)_a[1]); break;
        }
        _id -= 4;
    }
    return _id;
}

// SIGNAL 0
void IAEX::MyTextBrowser::openLink(const QUrl * _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void IAEX::MyTextBrowser::clickOnCell()
{
    QMetaObject::activate(this, &staticMetaObject, 1, 0);
}

// SIGNAL 2
void IAEX::MyTextBrowser::wheelMove(QWheelEvent * _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}
