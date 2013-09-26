## Qt implementations


## use PySide here
using PyCall
using PySide
QtGui = PyCall.pyimport("PySide.QtGui")
QStyle = QtGui["QStyle"]

## Icons
function get_icon(::MIME"application/x-qt", o::StockIcon)
    if isa(o.nm, Nothing)
        Qt.QIcon()
    else
        file = Pkg.dir("JGUI", "icons", string(o.theme), string(o.nm) * ".png")
        Qt.QIcon(file)
    end
end
function get_icon(::MIME"application/x-qt", o::FileIcon)
    Qt.QIcon(o.file)
end


## Widget methods
getEnabled(::MIME"application/x-qt", o::Widget) = o[:widget][:enabled]
setEnabled(::MIME"application/x-qt", o::Widget, value::Bool) = o[:widget][:setEnabled](true)

getVisible(::MIME"application/x-qt", o::Widget) =  o[:widget][:visible]
setVisible(::MIME"application/x-qt", o::Widget, value::Bool) = o[:widget][:setVisible](value)

function getSize(::MIME"application/x-qt", o::Widget)  
    sz = o[:widget][:size]()
    [sz[:width](), sz[:height]()]
end
setSize(::MIME"application/x-qt", o::Widget, value)  =  o[:widget][:resize](value[1], value[2])

getFocus(::MIME"application/x-qt", o::Widget) = o[:widget][:focus]
setFocus(::MIME"application/x-qt", o::Widget, value::Bool) =  o[:widget][:setFocus](value)

getWidget(::MIME"application/x-qt", o::Widget) = o.o

function setSizepolicy(::MIME"application/x-qt", o::Widget, policies) 
    o.attrs[:sizepolicy] = policies
    hpolicies = {:fixed => QtGui["QSizePolicy"]["Fixed"],
                :expand => QtGui["QSizePolicy"]["Expanding"],
                nothing => QtGui["QSizePolicy"]["Fixed"]
                }
    vpolicies = {:fixed => QtGui["QSizePolicy"]["Fixed"],
                :expand => QtGui["QSizePolicy"]["Expanding"],
                nothing => QtGui["QSizePolicy"]["Fixed"]
                }
    
    o[:widget][:setSizePolicy](hpolicies[policies[1]], vpolicies[policies[2]])
end

function get_alignment(o::Widget)
    halign = {:left => "AlignLeft",
              :center=> "AlignHCenter",
              :right => "AlignRight",
              :justify => "AlignJustify",
              nothing =>  "AlignHCenter"
              }
    valign = {:top => "AlignTop",
              :center => "AlignVCenter",
              :bottom => "AlignBottom",
              nothing => "AlignVCenter"
              }
    qt_enum([halign[o[:alignment][1]], valign[o[:alignment][2]]])
end
## Containers

## get Qt layout
getLayout(::MIME"application/x-qt", widget::Container) = widget[:widget][:layout]()
getLayout(widget::Container) = getLayout(widget.toolkit, widget)



## Window
function window(::MIME"application/x-qt")
    widget = Qt.QMainWindow()
    (widget, widget)
end


### window methods
function raise(::MIME"application/x-qt", o::Window) 
    o[:widget][:show]()
    convert(Function, o[:widget][:raise])()
end
lower(::MIME"application/x-qt", o::Window) = o[:widget][:lower]()
destroy_window(::MIME"application/x-qt", o::Window) = o[:widget][:destroy](true)

## window properties
getTitle(::MIME"application/x-qt", o::Window) = o[:widget][:windowTitle]()
setTitle(::MIME"application/x-qt", o::Window, value::String) = o[:widget][:setWindowTitle](value)
getPosition(::MIME"application/x-qt", o::Window) = [o[:widget][:x](), o[:widget][:y]()]
setPosition(::MIME"application/x-qt", o::Window, value::Vector{Int}) = o[:widget][:move](value[1], value[2])

## XXX
function getModal(::MIME"application/x-tcltk", o::Window) 
    val = tcl("grab", "status", o.o)
    val == "" ? false : true
end
function setModal(::MIME"application/x-tcltk", o::Window, value::Bool) 
    if value
        function callback(path)
            tcl("grab", "release", o.o)
            ## Insert method here ...
            destroy(o)
        end
        Tk.wm(o.o, "protocol", "WM_DELETE_WINDOW", callback)
#        tcl("tkwait", "window", o.o)
        ## This make Tk window modal, but not console...
        tcl("grab", "set", "-global", o.o)
    else
       tcl("grab", "release", o.o)
    end
end

function set_child(::MIME"application/x-qt", parent::Window, child::Widget)
    parent[:widget][:setCentralWidget](child.block)
end

## for BinContainer, only one child we pack and expand...
function set_child(::MIME"application/x-qt", parent::BinContainer, child::Widget)
    lyt = Qt.QHBoxLayout(parent[:widget])
    lyt[:addWidget](child.block)
    lyt[:setStretch](2,2)
    parent[:widget][:setLayout](lyt)
end


## Label frame
function labelframe(::MIME"application/x-qt", parent::BinContainer, label::String, alignment::Union(Nothing, Symbol)=nothing)
    widget = Qt.QFrame(parent[:widget])
    widget[:setFrameStyle](widget[:Sunken])

    if isa(alignment, Symbol)
        ## XXX how to set label
    end
    (widget, widget)
end


## Boxes
function boxcontainer(::MIME"application/x-qt", parent::Container)
    widget = Qt.QFrame(parent[:widget])
    (widget, widget)
end

## set padx, pady for all the children
function setSpacing(::MIME"application/x-qt", parent::BoxContainer, px::Vector{Int})
    parent[:widget][:layout]()[:setSpacing](px[1]) # first one only
end

##
function setMargin(::MIME"application/x-qt", parent::BoxContainer, px::Vector{Int})
    parent[:widget][:setContentsMargin](px[1], px[2], px[1], px[2])
end


## stretch, strut, spacing
addspacing(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addSpacing](val)
addsstrut(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addStrut](val)
addstretch(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addStretch](val)


function insert_child(::MIME"application/x-qt", parent::BoxContainer, index, child::Widget)
    
    direction = getProp(parent, :direction)
    lyt = parent[:layout]
    if isa(lyt, Nothing)
        lyt = (direction == :horizontal) ? Qt.QHBoxLayout(parent[:widget]) : Qt.QVBoxLayout(parent[:widget])
        parent[:widget][:setLayout](lyt)
    end
    
    stretch = child[:stretch]
    
    if direction == :horizontal
        if child[:sizepolicy][2] == nothing
            child[:sizepolicy] = (child[:sizepolicy][1], :expand)
        end
    else
        if child[:sizepolicy][1] == nothing
            child[:sizepolicy] = (:expand, child[:sizepolicy][1])
        end
    end
        
    alignment = get_alignment(child)

    lyt[:insertWidget](index - 1, child.block, stretch,  alignment) 


end

function remove_child(::MIME"application/x-qt", parent::Container, child::Widget)
    child[:widget][:setVisible](false)
    parent[:widget][:layout]()[:removeWidget](child.block)
end

####
## make a grid
function grid(::MIME"application/x-qt", parent::Container)
    widget = Qt.QFrame(parent[:widget])
    lyt = Qt.QGridLayout(widget)
    widget[:setLayout](lyt)
    (widget, widget)
end

## size of grid
function grid_size(::MIME"application/x-qt", widget::GridContainer)
    lty = widget[:widget][:layout]()
    [lty[:rowCount](), lty[:columnCount]()]
end

## grid spacing
function setSpacing(::MIME"application/x-qt", parent::GridContainer, px::Vector{Int})
    lyt = parent[:widget][:layout]()
    lyt[:setHorizontalSpacing][px[1]]
    lyt[:setVerticalSpacing][px[2]]
end



## Need to do something to configure rows and columns
## grid add child
function grid_add_child(::MIME"application/x-qt", parent::GridContainer, child::Widget, i, j)
    lyt = parent[:widget][:layout]()
    alignment = get_alignment(child)
    lyt[:addWidget](child.block, min(i), min(j), max(i) - min(i) + 1, max(j) - min(j) + 1, alignment)
end

function grid_get_child_at(::MIME"application/x-qt", parent::GridContainer, i::Int, j::Int)
    pyo = parent[:widget][:itemAtPosition](i, j)
    child = filter(kid -> kid.o == pyo, children(parent))
    length(child) == 1 ? child[1] : nothing
end

##XXza
column_minimum_width(::MIME"application/x-qt", object::GridContainer, j::Int, width::Int) = object[:layout]()[:setColumnMinimumWidth](j-1, width)

row_minimum_height(::MIME"application/x-qt", object::GridContainer, j::Int, height::Int) = object[:layout]()[:setRowMinimumdHeight](i-1, height)

column_stretch(::MIME"application/x-qt", object::GridContainer, j::Int, weight::Int) = object[:layout]()[:setColumnStretch](j-1, weight)

row_stretch(::MIME"application/x-qt", object::GridContainer, i::Int, weight::Int) = object[:layout]()[:setRowStretch](i-1, weight)
##################################################

function formlayout(::MIME"application/x-qt", parent::Container)
    widget = Qt.QWidget(parent[:widget])
    lyt = Qt.QFormLayout(widget)
    widget[:setLayout](lyt)
                      
    (widget, widget)
end

## XX labels..
function formlayout_add_child(::MIME"application/x-qt", parent::FormLayout, child::Widget, label::Union(Nothing, String))
    parent[:layout][:addRow](label, child.block)
end

function setSpacing(::MIME"application/x-qt", object::FormLayout, px::Vector{Int})
    parent[:layout][:setHorizontalSpacing](px[1])
    parent[:layout][:setVerticalSpacing](px[2])
end

## Notebook
function notebook(::MIME"application/x-qt", parent::Container, model::Model)
    widget = Qt.QTabWidget(parent[:widget])

    connect(model, "valueChanged", value -> widget[:setCurrentIndex](value-1))
    qconnect(widget, :currentChanged) do value # XXX check value is index 0-based
        setValue(model, value + 1)
        false
    end

    (widget, widget)
end

## XXX icon, order?
function notebook_insert_child(::MIME"application/x-qt", parent::NoteBook, child::Widget, i::Int, label::String)
    i = i > length(parent) ? length(parent) : i-1
    parent[:widget][:insertTab](i, child.block,  label)
end

function notebook_remove_child(::MIME"application/x-qt", parent::NoteBook, child::Widget)
    ## no findfirst
    n = length(parent.children)
    index = filter(i -> parent.children[i] == child, 1:n)
    parent[:widget][:removeTab](index[1] - 1)
end

##################################################
## Widgets
function label(::MIME"application/x-qt", parent::Container, model::Model)
    widget = Qt.QLabel(string(getValue(model)), parent[:widget])
    connect(model, "valueChanged", widget, (widget, value) -> widget[:setText](string(value)))

    (widget, widget)
end


## separator
function separator(::MIME"application/x-qt", parent::Container; orientation::Symbol=:horizontal)
    widget = Qt.QFrame(parent[:widget])
    shape = widget[orientation == :horizontal ? :HLine : :VLine]
    widget[:setFrameShape](shape)
    widget[:setFrameShadow](widget[:Sunken])

    (widget, widget)
end

## Controls
function button(::MIME"application/x-qt", parent::Container, model::Model)
    widget = Qt.QPushButton(getValue(model), parent[:widget])
    connect(model, "valueChanged", value -> widget[:setText](value))
    qconnect(widget, :clicked, () -> notify(model, "clicked"))

    (widget, widget)
end

function setIcon(::MIME"application/x-qt", widget::Button, icon::Union(Nothing, Icon); kwargs...)
    if isa(icon, Nothing)
        widget[:widget][:setIcon](Qt.QIcon())
    else
        if isa(icon.theme, Nothing) 
            icon.theme = widget[:icontheme]
        end
        widget[:widget][:setIcon](get_icon(widget.toolkit, icon))
    end
end
    
## Need to subclass to get desired signals

qnew_class("OLineEdit", "QtGui.QLineEdit") ## QtGui -- not just Qt.    
function lineedit(::MIME"application/x-qt", parent::Container, model::Model)
    widget = qnew_class_instance("OLineEdit")
    widget[:setParent](parent[:widget])
    widget[:setText](string(getValue(model)))
    connect(model, "valueChanged", value -> widget[:setText](string(value)))

    ## SIgnals: keyrelease (keycode), activated (value), focusIn, focusOut, textChanged
    qconnect(widget, :returnPressed, () -> notify(model, "editingFinished", getValue(model)))
    qconnect(widget, :textChanged) do txt
        setValue(model, txt)
        true
    end

    qset_method(widget, :focusOutEvent) do e
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
        return(false)
    end
    qset_method(widget, :focusInEvent) do e
        notify(model, "focusIn")
        return(false)
    end
    # qset_method(widget, :keyPressEvent) do e
    #     notify(model, "textChanged", e[:text]())
    #     true
    # end
    qset_method(widget, :mousePressEvent) do e
        notify(model, "clicked")
        return(false)
    end

    connect(model, "placeholderTextChanged") do txt
        widget[:setPlaceholderText](txt)
    end


    (widget, widget)
end

qnew_class("OTextEdit", "QtGui.QTextEdit") ## QtGui -- not just Qt.
function textedit(::MIME"application/x-qt", parent::Container, model::Model)
    widget = qnew_class_instance("OTextEdit")    
    widget[:setParent](parent[:widget])

    connect(model, "valueChanged", value -> widget[:setPlainText](value))
    qconnect(widget, :textChanged, () -> model.value = widget[:toPlainText]()) # XXX Where to put cursor (and how)

    qset_method(widget, :focusOutEvent) do e
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
        return(false)
    end
    qset_method(widget, :focusInEvent) do e
        notify(model, "focusIn")
        return(false)
    end
    # qset_method(widget, :keyPressEvent) do e
    #     notify(model, "textChanged", e[:text]())
    #     true
    # end

    qset_method(widget, :mousePressEvent) do e
        notify(model, "clicked")
        return(false)
    end


    (widget, widget)
end


## checkbox
function checkbox(::MIME"application/x-qt", parent::Container, model::Model, label::Union(Nothing, String))
    widget = Qt.QCheckBox(parent[:widget])
    if !isa(label, Nothing)
        widget[:setText](string(label))
    end
    widget[:setChecked](model.value)

    connect(model, "valueChanged", value -> widget[:setChecked](value))
    qconnect(widget, :stateChanged) do state 
        setValue(model, state == int(qt_enum("Checked")))
    end
    (widget, widget)
end
getLabel(::MIME"application/x-qt", o::CheckBox) = o[:widget][:text]
setLabel(::MIME"application/x-qt", o::CheckBox, value::String) = o[:widget][:setText](string(value))


## radiogroup
function radiogroup(::MIME"application/x-qt", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    block = Qt.QGroupBox(parent[:widget])
    widget = Qt.QButtonGroup(parent[:widget])

    lyt = orientation == :horizontal ? Qt.QHBoxLayout(block) : Qt.QVBoxLayout(block)
    block[:setLayout](lyt)

    
    btns = map(model.items) do label
        btn = Qt.QRadioButton(parent[:widget])
        btn[:setText](label)
        widget[:addButton](btn)
        lyt[:addWidget](btn)
        btn
    end

    selected = findfirst(model.items, model.value)
    btns[selected][:setChecked](true)

    connect(model, "valueChanged") do value 
        ## need to look up which button to set
        selected = findfirst(model.items, value)
        if selected == 0
            error("$value is not one of the labels")
        else
            btns[selected][:setChecked](true)
        end
    end
    qconnect(widget, :buttonClicked) do btn
        setValue(model, btn[:text]())
    end
    
    (widget, block)
end

## buttongroup
function buttongroup(::MIME"application/x-qt", parent::Container, model::VectorModel; exclusive::Bool=false)
    block = Qt.QGroupBox(parent[:widget])
    lyt = Qt.QHBoxLayout(block)
    block[:setLayout](lyt)

    widget = Qt.QButtonGroup(parent[:widget])
    widget[:setExclusive](exclusive)



    
    btns = map(model.items) do label
        btn = Qt.QPushButton(parent[:widget])
        btn[:setText](label)
        btn[:setCheckable](true)
        widget[:addButton](btn)
        lyt[:addWidget](btn)
        btn
    end

#    selected = findfirst(model.items, model.value)
#    btns[selected][:setChecked](true)

    connect(model, "valueChanged") do value 
        ## XXX need to look up which button to set
        ## value is a vector of String[] type
        btns = widget[:buttons]()

        map(btns) do btn
            btn[:setChecked](btn[:text]() in  model.items)
        end
    end
    qconnect(widget, :buttonReleased) do btn
        checked = filter(b -> b[:isChecked](), widget[:buttons]())
        vals = String[b[:text]() for b in  checked]
        if length(checked) == 0
            setValue(model, String[])
        else
            setValue(model, vals)
        end
    end
    
    (widget, block)
end


## 
function combobox(::MIME"application/x-qt", parent::Container, model::VectorModel; editable::Bool=false)
    widget = Qt.QComboBox(parent[:widget])
    qmodel = Qt.QStandardItemModel(widget)
    widget[:setModel](qmodel)

    set_index(index) = widget[:setCurrentIndex](index-1)
    set_value(value) =  if isa(value, Nothing)
        set_index(0)
    else
        i = findfirst(model.items, value) # need index
        set_index(i)
    end

    function set_items(items)
        for i in 1:length(items)
            qmodel[:setItem](i-1, Qt.QStandardItem(items[i]))
        end
        set_index(0)            # clear selection?
    end

    set_items(model.items)
    set_value(model.value)
    
    connect(model, "valueChanged", value -> set_value(value))
    connect(model, "itemsChanged", set_items)

    qconnect(widget, :currentIndexChanged) do index
        if index == -1
            setValue(model, nothing)
        else
            setValue(model, model.items[index + 1])
        end
        false
    end


    (widget, widget)
end




## slider
## model stores value, slider is in 1:n
function slider(::MIME"application/x-qt", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    items = model.items
    initial = model.value
    n = length(items)
    orient = orientation == :horizontal ? qt_enum("Horizontal") : qt_enum("Vertical")


    widget = Qt.QSlider(parent[:widget])
    widget[:setOrientation](orient)

    widget[:setRange](1, n)
    widget[:setPageStep](1)
    
    connect(model, "valueChanged") do value ## value is in model.items
        ## have to find index from items
        i = indmin(abs(model.items - value))
        widget[:setValue](i)
    end

    ## value is index
    qconnect(widget, :valueChanged, value -> setValue(model, model.items[value]))

    (widget, widget)
end

## out model stores index
function slider2d(::MIME"application/x-qt", parent::Container, model::TwoDSliderModel)
    rectF(x,y,w,h) = PySide.QtCore[:QRectF](x,y,w,h)
    lineF(x1, y1, x2, y2) = PySide.QtCore[:QLineF](x1,y1,x2,y2)

    scene = Qt.QGraphicsScene()
    scene[:setSceneRect](0.0, 0.0, 100.0, 100.0)

    ## styles
    dash = Qt.QPen()
    dash[:setStyle](qt_enum("DashDotLine"))
    dash[:setWidth](2)
    dash[:setBrush](qt_enum("gray"))
    
    solid = Qt.QPen()
    solid[:setWidth](3)
    solid[:setBrush](Qt.QBrush(qt_enum("black"), qt_enum("SolidPattern")))
    
    hor = scene[:addLine](lineF(0, 50, 100, 50), dash)
    ver = scene[:addLine](lineF(50, 0, 50, 100), dash)
    
    pt = Qt.QGraphicsEllipseItem()
    r = 3
    pt[:setRect](rectF(50-r, 50-r, 2r, 2r))
    pt[:setPen](solid)
    pt[:setFlags](pt[:ItemIsMovable])
    
    scene[:addItem](pt)
    


    qconnect(scene, :changed) do l     
        x = pt[:x](); y = pt[:y]()
        ## move lines
        hor[:setY](y)
        ver[:setX](x)

        ## constrain
        x > 50 && pt[:setX](50)
        x <= -50 && pt[:setX](-49)
        y > 50 && pt[:setY](50)
        y <= -50 && pt[:setY](-49)

        ## put into coordinates
        i = min(100, max(1, x + 50))
        j = min(100, max(1, -y + 50))

        ## update model, but use index..
        if model.value != [i,j]
            model.value = [i,j]
            notify(model, "valueChanged", getValue(model))
        end
    end
    
    connect(model, "valueChanged") do value
        x, y = model.value

        x = x - 50
        y = 50 - y

        pt[:setX](x)
        pt[:setY](y)
    end

    view = Qt.QGraphicsView(scene)
    view[:setHorizontalScrollBarPolicy](qt_enum("ScrollBarAlwaysOff"))
    view[:setVerticalScrollBarPolicy](qt_enum("ScrollBarAlwaysOff"))
    view[:setSceneRect](1.0, 1.0, 100.0, 100.0)
    ## adjust to remove scrollbar
    view[:setMaximumWidth](100)
    view[:setMinimumWidth](100)
    view[:setMaximumHeight](100)
    view[:setMinimumHeight](100)

    (scene, view)
end
getValue(::MIME"application/x-qt", widget::Slider2D) = getValue(widget.model)
setValue(::MIME"application/x-qt", widget::Slider2D, value) = setValue(widget.model, value)

## spinbox

## PyPlot graphics Figure
## https://github.com/matplotlib/matplotlib/blob/master/examples/user_interfaces/embedding_in_qt4.py
import PyPlot: Gcf, pltm

type PyPlotGraphic <: Widget
    o
    block
    id::String
    parent
    toolkit
    attrs
end


## For use with PyPlot graphics. 
##
## Very hacky
##
## Arguments:
## * `parent::Container` parent container
##
## Properties
## * `:active` call `obj[:active] = true` to make current figure
##
function pyplotgraphic(parent::Container)
    ## width height in inches, or pixels?
    widget = Qt.QWidget(parent[:widget])
    id = randstring(10)
    pltm[:figure](id) # super hacky
    manager = Gcf[:get_active]()
    

    canvas = manager["canvas"]

    canvas[:parent]()[:setVisible](false)
    canvas[:setParent](nothing)
    canvas[:setParent](widget)
    #canvas[:setSizePolicy]( QtGui["QSizePolicy"]["Expanding"], QtGui["QSizePolicy"]["Expanding"])

    lyt = Qt.QHBoxLayout()
    widget[:setLayout](lyt)
    lyt[:addWidget](canvas)

    PyPlotGraphic(canvas, widget, id, parent, parent.toolkit, Dict())
end

## set this as active
setActive(o::PyPlotGraphic, value) = pltm[:figure](o.id)



## Views
## StoreProxyModel
qnew_class("StoreProxyModel", "QtCore.QAbstractTableModel")
function store_proxy_model(parent, store::Store; tpl=nothing)
    if tpl == nothing
        record = store.items[1]
    else
        record = tpl
    end
    nms = names(record)

    m = qnew_class_instance("StoreProxyModel")
    m[:setParent](parent)       
    ## add functions
    m[:rowCount] = (index) -> length(store.items)
    m[:columnCount] = (index) -> length(names(record))
    m[:headerData] = (section::Int, orient, role) -> begin
        if orient.o ==  qt_enum("Horizontal").o #  match pointers
            ## column, section is column
            role == convert(Int, qt_enum("DisplayRole")) ?  nms[section + 1] : nothing
        else
             role == convert(Int, qt_enum("DisplayRole")) ?  string(section + 1) : nothing
        end
    end
    m[:data] = (index, role) -> begin
        record = store.items[1]
        nms = names(record)
        
        row = index[:row]() + 1
        col = index[:column]() + 1
        ## http://qt-project.org/doc/qt-5.0/qtcore/qt.html#ItemDataRole-enum
        roles = ["DisplayRole"] 
        for r in roles
            if role == int(qt_enum(r))
                item = store.items[row]
                nm = nms[col]
               return(string(item.(symbol(nm))))
            end
        end
        if role == int(qt_enum("TextAlignmentRole")) 
            return(qt_enum("AlignLeft")) ## XXX adjust to variable type?
        end
        if row == 1 && role == int(qt_enum("DecorationRole"))
            return(nothing) # XXX icons...
        end
        ## More roles, but not now...: "EditRole",  "BackgroundRole", "ForegroundRole", "ToolTipRole", "WhatsThisRole"]
        return(nothing)
    end

   m[:insertRows] = (row, count, index) -> begin
       m[:beginInsertRows](index, row-1, row-1)
       m[:endInsertRows]()
       ## notify model? Was getting recursive call in that case.
       true
   end
   m[:removeRows] = (row, count, index) -> begin
       m[:beginRemoveRows](index, row-1, 1)
       m[:endRemoveRows]()
       true
   end

   ## connect model to store so that store changes propogate XXX
   connect(store.model, "rowInserted") do i
       m[:insertRows](i, 1, PySide.QtCore[:QModelIndex]())
   end

    connect(store.model, "rowRemoved", i -> m[:removeRows](i, 1, PySide.QtCore[:QModelIndex]()))
    function rowUpdated(i::Int)
        topleft = m[:index](i-1,0)
        lowerright = m[:index](i, 0)
        m[:emit](PySide.QtCore[:SIGNAL]("dataChanged"))(topleft, lowerright)
    end
    connect(store.model, "rowUpdated", rowUpdated)



   ## return model
   m
end

## storeview
function storeview(::MIME"application/x-qt", parent::Container, store::Store, model::ItemModel; tpl=nothing)
    ## Widget
    widget = Qt.QTableView(parent[:widget])
    proxy_model = store_proxy_model(widget, store, tpl=tpl)
    widget[:setModel](proxy_model)

    widget[:setSelectionBehavior](widget[:SelectRows])

    ## set up callbacks
    ## this uses a slot
    qconnect(widget[:selectionModel](), :selectionChanged) do selected, deselected
        indices = unique([idx[:row]() + 1 for idx in selected[:indexes]()])
        setValue(model, indices)
        notify(model, "selectionChanged", indices)
    end
    qconnect(widget, :clicked) do index
        notify(model, "clicked", index[:row]() + 1, index[:column]() + 1)
    end
    qconnect(widget, :doubleClicked) do index
        notify(model, "doubleClick", index[:row]() + 1, index[:column]() + 1)
    end
    qconnect(widget[:horizontalHeader](), :sectionClicked) do index
        notify(model, "headerClicked", index + 1)
    end

    (widget, widget)
end


function getSelectmode(::MIME"application/x-qt", s::ModelView) 
    s[:widget][:selectionMode]() == s[:widget][:SingleSelection] ? :single : :multiple
end
## val is single, multiple
function setSelectmode(::MIME"application/x-qt", s::ModelView, val::Symbol)
    s[:widget][:setSelectionMode](val == :single ? s[:widget][:SingleSelection] : s[:widget][:ExtendedSelection])
end

## getWidths
function getWidths(::MIME"application/x-qt", s::ModelView)
    n = size(s.store)[2]
    [s[:widget][:columnWidth](i-1) for i in 1:n]
end

function setWidths(::MIME"application/x-qt", s::ModelView, widths::Vector{Int})
    for i in 1:length(widths)
        s[:widget][:setColumnWidth](i-1, widths[i])
    end
end

## heights
function getHeights(::MIME"application/x-qt", s::ModelView)
    n = size(s.store)[1]
    [s[:widget][:rowHeight](i-1) for i in 1:n]
end

function setHeights(::MIME"application/x-qt", s::ModelView, heights::Vector{Int})
    for i in 1:size(s.store)[1]
        s[:widget][:setRowHeight](i-1, heights[i])
    end
end


function getHeadervisible(::MIME"application/x-qt", s::StoreView)
    s[:widget][:horizontalHeader]()[:isVisible]()
end
function setHeadervisible(::MIME"application/x-qt", s::StoreView, val::Bool)
    s[:widget][:horizontalHeader]()[val ? :show : :hide]()
end


function getRownamesvisible(::MIME"application/x-qt", s::StoreView)
    s[:widget][:verticalHeader]()[:isVisible]()
end
function setRownamesvisible(::MIME"application/x-qt", s::StoreView, val::Bool)
  s[:widget][:verticalHeader]()[val ? :show : :hide]()
end



function setIcon(::MIME"application/x-qt", s::StoreView, i::Int, icon::Icon)
    ## XXX need to set decoration role for item in row i, column 1
end

##################################################
##
## StoreProxyModel
## XXX This failed due to inability to write [:parent] method...
# qnew_class("TreeStoreProxyModel", "QtCore.QAbstractItemModel")
# function tree_store_proxy_model(parent, store::TreeStore; tpl=nothing)
#     if tpl == nothing
#         record = store.items[1]
#     else
#         record = tpl
#     end
#     nms = names(record)

#     m = qnew_class_instance("TreeStoreProxyModel")

#     ## helpers to translate qtmodel <--> treestore
#     function index_to_path(index)
#         ind = index
#         ## return node in tree store for index
#         ## get path by crawling back
#         path = Int[]
#         println("index_to_node, index:", ind)
#         while ind[:isValid]()
#             println((ind[:isValid](),  ind[:row]() ))
#             path = unshift!(path, ind[:row]() + 1)
#             println((path, ind))
#             ind = ind[:parent]()
#         end
#         println("====")
#         path
#     end
#     function index_to_node(index)
#         path = index_to_path(index)
#         if length(path) > 0
#             path_to_node(store, path) # in models.jl
#         else
#             nothing
#         end
#     end
#     function node_to_index(node)
#         ## return qtindex fro a give node
#         path = node_to_path(node) # in models.jl
#         path_to_index(path)
#     end
#     function path_to_index(path)
#         ## return index from 1-based path
#         index = Qt.QModelIndex()
#         println("path to index")
#         println((path, index))
#         while length(path) > 0
#             r = shift!(path)
#             index = m[:index](r + 1, 0, index)
#             println((path, index))
#         end
#         println("====")
#         index
#     end

#     m[:setParent](parent)       
#     ## add functions
#     ## parent, rowcount, columncount, data

#     ## Returns the parent of the model item with the given index. 
#     ## If the item has no parent, an invalid QModelIndex is returned.
#     m[:parent] = (index) -> begin
#         path = index_to_path(index)
#         if length(path) > 1
#             pop!(path)
#             path_to_index(path)
#         else
#             PySide.QtCore.QModelIndex()
#         end
#     end
#     m[:rowCount] = (index) -> begin
#         println("rowCount")
#         node = index_to_node(index)
#         if isa(node, Nothing)
#             return 0
#         else
#             parent = node.parent
#             length(parent.items)
#         end
#     end
#     m[:columnCount] = (index) -> length(names(record))
#     m[:headerData] = (section::Int, orient, role) -> begin
#         if orient.o ==  qt_enum("Horizontal").o #  match pointers
#             ## column, section is column
#             role == convert(Int, qt_enum("DisplayRole")) ?  nms[section + 1] : nothing
#         else
#              role == convert(Int, qt_enum("DisplayRole")) ?  string(section + 1) : nothing
#         end
#     end
#     m[:data] = (index, role) -> begin
#         println("data")
#         node = index_to_node(index)
#         if isa(node, Nothing)
#             return nothing
#         end

#         record = node.data
#         nms = names(record)
        
#         col = index[:column]() + 1
#         ## http://qt-project.org/doc/qt-5.0/qtcore/qt.html#ItemDataRole-enum
#         if role == int(qt_enum("DisplayRole"))
#             nm = nms[col]
#             return(string(node.(symbol(nm))))
#         end
#         other_roles = ["EditRole", "DecorationRole", "TextAlignmentRole", "BackgroundRole", "ForegroundRole", "ToolTipRole", "WhatsThisRole"]
#         for r in other_roles
#             if role == int(qt_enum(r))
#                 if haskey(store.attrs, r)
#                     ## store roles in dict keyed by hash(row, col) 
#                     ## e.g., store.attrs[RoleName][hash(row, col)] = value
#                     ## XXX need to do icon via
#                     ## store.attrs["DecorationRole"] = Dict()
#                     ## store.attrs["DecorationRole"][hash(1, 3)] = Qt.QIcon("ok.gif") ...
#                     d = store.attrs[r]
#                     key = hash(index[row]() + 1, col)
#                     if haskey(d, key)
#                         return string(d[key])
#                     end
#                 end
#                 return nothing
#             end
#         end
#         if role == int(qt_enum("TextAlignmentRole")) 
#             return(qt_enum("AlignLeft")) ## XXX adjust to variable type?
#         end
#         return(nothing)
#     end
#     m[:index] = (row, column, parent) -> begin
#         m[:createIndex](row, column)
#     end
#     m[:insertRows] = (row, count, index) -> begin
#        println("insert rows")
#        m[:beginInsertRows](index, row-1, row-1)
#        m[:endInsertRows]()
#        notify(store.model, "rowInserted", index_to_node(index), row)
#        true
#    end
#    m[:removeRows] = (row, count, index) -> begin
#        println("remove rows")
#        m[:beginRemoveRows](index, row-1, 1)
#        m[:endRemoveRows]()
#        notify(store.model, "rowRemoved", index_to_node(index), row)
#        true
#    end

#    ## connect model to store so that store changes propagate XXX
#    connect(store.model, "rowInserted") do parent_node, i
#        m[:insertRows](i, 1, node_to_index(parent_node))
#    end

#    connect(store.model, "rowRemoved") do parent_node, i 
#        m[:removeRows](i, 1, node_to_index(parent_node))
#    end
#    connect(store.model, "rowUpdated") do parent_node, i 
#        ## XXX
#        topleft = m[:index](i-1,0)
#        lowerright = m[:index](i, 0)
#        m[:emit](PySide.QtCore[:SIGNAL]("dataChanged"))(topleft, lowerright)
#    end



#    ## return model
#    m
# end

## Tree view
## tpl: a template for the type, otherwise from tr.children[1]
function treeview(::MIME"application/x-qt", parent::Container, store::TreeStore, model::ItemModel; tpl=nothing)
    widget = Qt.QTreeWidget(parent[:widget])

    ## headers
    if isa(tpl, Nothing)
        tpl = store.children[1].data
    end
    ## first column is for key
    widget[:setHeaderLabels](append([""],names(tpl)))

    ## set flags ...

    ## helper functions relating
    function path_to_item(path)
        ## return QTreeWidgetItem from path
        path = copy(path)
        length(path) == 0 && return nothing
        root = shift!(path)
        item = widget[:topLevelItem](root - 1)
        while length(path) > 0
            i = shift!(path)
            item = item[:child](i-1)
        end
        item
    end
    function node_to_item(node)
        path_to_item(node_to_path(node))
    end
    function item_to_path(item)
        path = Int[]
        parent = item[:parent]()
        while !isa(parent, Nothing)
            unshift!(path, parent[:indexOfChild](item) + 1)
            item = parent
            parent = parent[:parent]()
        end
        unshift!(path, widget[:indexOfTopLevelItem](item) + 1)
        path
    end
    
    ###########################
    ## connect model and widget
    function insertNode(parentnode, i, childnode)
        vals = [child.text]
        if !isa(child.data, Nothing)
            vals = append!(vals, node_to_values(childnode))
        end
        item = PySide.Qt.QTreeWidgetItem(vals)

        if isa(parentnode, Union(Nothing, TreeStore)) # TreeStore is root, TreeNode is node
            widget[:insertTopLevelItem](i-1, item)
        else
            parent_path = node_to_path(parentnode)
            parent_item = path_to_item(parent_path)
            parent_item[:insertChild](i-1, item)
        end
    end
    connect(store.model, "insertNode", insertNode)

    function removeNode(parentnode, i)
        if isa(parentnode, TreeStore) 
            widget[:takeTopLevelItem](i-1)
        else
            item = node_to_item(parentnode)
            item[:takeChild](i-1)
        end
    end
    connect(store.model, "removeNode", removeNode)

    function updatedNode(node)
        item = node_to_item(node)
        nms = names(node.data)
        for i in 1:length(nms)
            item[:setText](i-1, to_string(node, node.data.(nms[i])))
        end
    end
    connect(store.model, "updatedNode", updatedNode)
    
    ## expand Node on view model, not store model
    function expandNode(node)
        item = node_to_item(node)
        item[:setExpanded](true)
    end
    connect(model, "expandNode", expandNode)

    function collapseNode(node)
        item = node_to_item(node)
        item[:setExpanded](false)
    end
    connect(model, "collapseNode", collapseNode)

    connect(model, "valueChanged") do value
        item = path_to_item(value)
        widget[:setCurrentItem](item)
    end

    ## iterate of tstore children to set things
    function add_children(parentnode)
        if length(parentnode.children) > 0
            for i in 1:length(parentnode.children)
                child = parentnode.children[i]
                insertNode(parentnode, i, child)
                add_children(child)
            end
        end
    end
    add_children(store)



    ## connect widget to model
    qconnect(widget, :itemSelectionChanged) do
        sel_item = widget[:selectedItems]()[1]
        path = item_to_path(sel_item)
        ## some how this totally fails, yet
        setValue(model, path)
    end
    qconnect(widget, :itemExpanded) do item
        path = item_to_path(item)
        notify(model, "nodeExpand", path)
    end
    qconnect(widget, :itemCollapsed) do item
        path = item_to_path(item)
        notify(model, "nodeCollapse", path)
    end
    qconnect(widget, :itemClicked) do item, column
        path = item_to_path(item)
        notify(model, "clicked", path, column + 1)
    end
    qconnect(widget, :itemDoubleClicked) do item, column
        path = item_to_path(item)
        notify(model, "doubleClicked", path, column + 1)
    end

    
    
    (widget, widget)
end

## Properties


## keywidth is first column
function getKeywidth(::MIME"application/x-qt", tr::TreeView)
    tr[:widget][:columnWidth](0)
end
function setKeywidth(::MIME"application/x-qt", tr::TreeView, width::Int)
    tr[:widget][:setColumnWidth](0, width)
end
function getWidths(::MIME"application/x-qt", tr::TreeView)
    "XXX"
end
function setWidths(::MIME"application/x-qt", tr::TreeView, widths::Vector{Int})
    "XXX"
end
function getHeights(::MIME"application/x-qt", tr::TreeView)
    "XXX"
end
function setHeights(::MIME"application/x-qt", tr::TreeView, heights::Vector{Int})
    "XXX"
end


function setIcon(::MIME"application/x-qt", s::TreeView, path::Vector{Int}, icon::Icon)
    widget = s[:widget]
    function path_to_item(path) # DRY!!
        ## return QTreeWidgetItem from path
        length(path) == 0 && return nothing
        root = shift!(path)
        item = widget[:topLevelItem](root - 1)
        while length(path) > 0
            i = shift!(path)
            item = item[:child](i-1)
        end
        item
    end
    item = path_to_item(path)
    if isa(icon.theme, Nothing) 
        icon.theme = s[:icontheme]
    end
    widget[:widget][:setIcon]()
    item[:setIcon](get_icon(s.toolkit, icon))
end

## Images

## place to put a png image
## Ain't working???
function imageview(::MIME"application/x-qt", parent::Container)
    ## use a QLabel to display an image
    widget = block = Qt.QLabel(parent[:widget])
    (widget, block)
end

function setImage(::MIME"application/x-qt", o::ImageView, img::String)
    pixmap = Qt.QPixmap(img)
    o[:widget][:setPixmap](pixmap)
end



##################################################
##
## Dialogs

function dialog(::MIME"application/x-qt", parent::Widget, model;
                buttons::Vector{Symbol}=[:ok],
                default::Union(Symbol, Nothing)=:ok,
                title::String="")

    dlg = Qt.QDialog(parent[:widget])
    
    if !isa(title, Nothing)
        dlg[:setWindowTitle](title)
    end

    button_box = Qt.QDialogButtonBox(dlg)
    defined_btns = {
                    :ok      => button_box[:Ok], 
                    :cancel  => button_box[:Cancel],
                    :close   => button_box[:Close], 
                    :apply  => button_box[:Apply], 
                    :reset   => button_box[:Reset], 
                    :help    => button_box[:Help], 
                    }

    button_box[:setStandardButtons](sum(map(k -> int(defined_btns[k]), btns)))
    if !isa(default, Nothing)
        button = button_box[:button](defined_btns[default])
        button[:setDefault](true)
    end

   
    ## Layout button box
    lyt = Qt.QVBoxLayout(dlg)
    dlg[:setLayout](lyt)
    lyt[:addWidget](button_box)

    (dlg, dlg)
end

## properties
getTitle(::MIME"application/x-qt", parent::Dialog) = dlg[:widget][:windowTitle]()
setTitle(::MIME"application/x-qt", parent::Dialog, value::String) = dlg[:widget][:setWindowTitle](value)

## make deafult button a property?

function set_child(::MIME"application/x-qt", parent::Dialog, child::Widget)
    lyt = parent[:layout]
#    child[:sizepolicy] = (:expand, :expand)
    lyt[:insertWidget](0, child.block, 100)
end


## add here so that we have dlg object, not QDialog
function add_bindings(::MIME"application/x-qt", dlg::Dialog)
    n = dlg[:widget][:layout]()[:count]()
    button_box = dlg[:widget][:layout]()[:itemAt](n-1)[:widget]()
     ## need to connect buttons and close dialog
    f(x, s) = () -> begin 
        dlg.state = s
        dlg[:widget][:done](1)
        if !isa(x, Nothing)
            notify(dlg.model, x)
        end
    end
    qconnect(button_box, :accepted,      f("accepted", :accept))
    qconnect(button_box, :rejected,      f("rejected", :reject))
    qconnect(button_box, :helpRequested, f(nothing,    :help))
    qconnect(button_box, :clicked) do button
        notify(dlg.model, "finished", button) # need to see what button is
    end


end
function show_dialog(::MIME"application/x-qt", dlg::Dialog, value::Bool)
    if value
        dlg[:widget][:show]()
        convert(Function, dlg[:widget][:raise])()
    else
        dlg[:widget][:hide]()
    end
end

function setModal(::MIME"application/x-qt", dlg::Dialog, value::Bool)
    if value
        convert(Function, dlg[:widget][:exec])()
    end
end
function setModaless(::MIME"application/x-qt", dlg::Dialog, value::Bool)
    convert(Function, dlg[:widget][:open])()
end
function destroy(::MIME"application/x-qt", dlg::Dialog)
    convert(Function, dlg[:widget][:destroy])()
end


### special dialogs
##
## Returns file, directory, files or nothing
function filedialog(::MIME"application/x-qt", 
                    parent::Widget; 
                    mode::Symbol=:open, ## :open, :multiple, :directory, :save
                    message::String="",
                    title::String="",
                    filetypes::Union(Nothing, Vector{Tuple})=nothing)

    dlg = (isa(parent, Nothing) ? Qt.QFileDialog() : Qt.QFileDialog(parent[:widget]))
    ## title
    dlg[:setWindowTitle](title)
    
    ## mode
    file_mode = {:open => :ExistingFile,
                 :multiple => :ExistingFiles,
                 :directory => :Directory,
                 :save => :AnyFile
                 }
    dlg[:setFileMode](dlg[file_mode[mode]])

    ##  Filter
    ## do filetypes an array [(name, ext)]
    if !isa(filetypes, Nothing)
        push!(filetypes, ("All files", "*.*"))
        dlg[:setNameFilters](["$val ($descr)" for (val, descr) in filetypes])
    end
    
    
    dlg[:show]()
    convert(Function, dlg[:raise])()
    ret = convert(Function, dlg[:exec])()
    if ret != 0
        files = dlg[:selectedFiles]()
        length(files) == 0 && return(nothing)
        mode == :multiple ? files : files[1]
    else
        nothing
    end
end



function messagebox(::MIME"application/x-qt", parent::Widget, text::String; icon::Union(Nothing, String)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) 

    msgbox = Qt.QMessageBox(parent[:widget])
    msgbox[:setText](text)


    if !isa(icon, Nothing)
        icons = {:question=>:Question,
                 :info =>   :Information, 
                 :warning=> :Warning, 
                 :critical=>:Critical}
        msgbox[:setIcon](msgbox[icons[icon]])
    end
    if !isa(title, Nothing)
        msgbox[:setWindowTitle](title)
    end
    if !isa(informativeText, Nothing)
        msgbox[:setInformativeText](informativeText)
    end
    if !isa(icon, Nothing)
        args["icon"] = icons[icon]
    end

    msgbox[:show]()
    convert(Function, msgbox[:raise])()
    convert(Function, msgbox[:exec])()
end

function confirmbox(::MIME"application/x-qt", parent::Widget, text::String; icon::Union(Nothing, Symbol)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) # detail


    msgbox = Qt.QMessageBox(parent[:widget])
    msgbox[:setText](text)


    if !isa(icon, Nothing)
        icons = {:question=>:Question,
                 :info =>   :Information, 
                 :warning=> :Warning, 
                 :critical=>:Critical}
        msgbox[:setIcon](msgbox[icons[icon]])
    end
    if !isa(title, Nothing)
        msgbox[:setWindowTitle](title)
    end
    if !isa(informativeText, Nothing)
        msgbox[:setInformativeText](informativeText)
    end
    if !isa(icon, Nothing)
        args["icon"] = icons[icon]
    end

    msgbox[:setStandardButtons](int(msgbox[:Ok]) + int(msgbox[:Cancel]))

    msgbox[:show]()
    convert(Function, msgbox[:raise])()
    ret = convert(Function, msgbox[:exec])()
    ret == int(msgbox[:Ok]) ? :accept : :reject
end





## manipulate
function Display(::MIME"application/x-qt", self::ManipulateObject, x; kwargs...) 
    "XXX nothing here, though should do text output..."
end
