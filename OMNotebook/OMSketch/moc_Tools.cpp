/****************************************************************************
** Meta object code from reading C++ file 'Tools.h'
**
** Created: Mon 18. Apr 19:15:45 2011
**      by: The Qt Meta Object Compiler version 62 (Qt 4.7.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "Tools.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'Tools.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 62
#error "This file was generated using the moc from 4.7.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_Tools[] = {

 // content:
       5,       // revision
       0,       // classname
       0,    0, // classinfo
      32,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: signature, parameters, type, tag, flags
       7,    6,    6,    6, 0x0a,
      18,    6,    6,    6, 0x0a,
      31,    6,    6,    6, 0x0a,
      43,    6,    6,    6, 0x0a,
      61,    6,    6,    6, 0x0a,
      73,    6,    6,    6, 0x0a,
      90,    6,    6,    6, 0x0a,
     105,    6,    6,    6, 0x0a,
     120,    6,    6,    6, 0x0a,
     136,    6,    6,    6, 0x0a,
     148,    6,    6,    6, 0x0a,
     159,    6,    6,    6, 0x0a,
     171,    6,    6,    6, 0x0a,
     183,    6,    6,    6, 0x0a,
     197,    6,    6,    6, 0x0a,
     213,    6,    6,    6, 0x0a,
     233,    6,    6,    6, 0x0a,
     249,    6,    6,    6, 0x0a,
     267,    6,    6,    6, 0x0a,
     279,    6,    6,    6, 0x0a,
     290,    6,    6,    6, 0x0a,
     303,    6,    6,    6, 0x0a,
     320,  315,    6,    6, 0x0a,
     344,  338,    6,    6, 0x0a,
     362,  315,    6,    6, 0x0a,
     382,    6,    6,    6, 0x0a,
     403,    6,    6,    6, 0x0a,
     423,    6,    6,    6, 0x0a,
     442,    6,    6,    6, 0x0a,
     465,    6,    6,    6, 0x0a,
     491,    6,    6,    6, 0x0a,
     516,  505,    6,    6, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_Tools[] = {
    "Tools\0\0draw_arc()\0draw_arrow()\0"
    "draw_rect()\0draw_round_rect()\0draw_line()\0"
    "draw_linearrow()\0draw_ellipse()\0"
    "draw_polygon()\0draw_triangle()\0"
    "draw_text()\0draw_new()\0draw_save()\0"
    "draw_open()\0draw_shapes()\0msg_save_file()\0"
    "msg_dnt_save_file()\0draw_xml_save()\0"
    "draw_image_save()\0draw_copy()\0draw_cut()\0"
    "draw_paste()\0setColors()\0indx\0"
    "setPenStyles(int)\0width\0setPenWidths(int)\0"
    "setBrushStyles(int)\0pen_lineSolidStyle()\0"
    "pen_lineDashStyle()\0pen_lineDotStyle()\0"
    "pen_lineDashDotStyle()\0pen_lineDashDotDotStyle()\0"
    "brush_color()\0scene_item\0"
    "item_selected(Graph_Scene*)\0"
};

const QMetaObject Tools::staticMetaObject = {
    { &QMainWindow::staticMetaObject, qt_meta_stringdata_Tools,
      qt_meta_data_Tools, 0 }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &Tools::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *Tools::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *Tools::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_Tools))
        return static_cast<void*>(const_cast< Tools*>(this));
    return QMainWindow::qt_metacast(_clname);
}

int Tools::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: draw_arc(); break;
        case 1: draw_arrow(); break;
        case 2: draw_rect(); break;
        case 3: draw_round_rect(); break;
        case 4: draw_line(); break;
        case 5: draw_linearrow(); break;
        case 6: draw_ellipse(); break;
        case 7: draw_polygon(); break;
        case 8: draw_triangle(); break;
        case 9: draw_text(); break;
        case 10: draw_new(); break;
        case 11: draw_save(); break;
        case 12: draw_open(); break;
        case 13: draw_shapes(); break;
        case 14: msg_save_file(); break;
        case 15: msg_dnt_save_file(); break;
        case 16: draw_xml_save(); break;
        case 17: draw_image_save(); break;
        case 18: draw_copy(); break;
        case 19: draw_cut(); break;
        case 20: draw_paste(); break;
        case 21: setColors(); break;
        case 22: setPenStyles((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 23: setPenWidths((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 24: setBrushStyles((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 25: pen_lineSolidStyle(); break;
        case 26: pen_lineDashStyle(); break;
        case 27: pen_lineDotStyle(); break;
        case 28: pen_lineDashDotStyle(); break;
        case 29: pen_lineDashDotDotStyle(); break;
        case 30: brush_color(); break;
        case 31: item_selected((*reinterpret_cast< Graph_Scene*(*)>(_a[1]))); break;
        default: ;
        }
        _id -= 32;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
