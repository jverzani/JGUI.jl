## Gtk implementation

## TODO
## * storeview
## * treeview
## * dialogs
## * others


XXX() = error("not defined")
## Icons
function get_icon(::MIME"application/x-gtk", o::StockIcon)
    if isa(o.nm, Nothing)
        Gtk.GtkImage()
    else
        file = Pkg.dir("JGUI", "icons", string(o.theme), string(o.nm) * ".png")
        Gtk.GtkImage(file)
    end
end
function get_icon(::MIME"application/x-gtk", o::FileIcon)
    Gtk.GtkImage(o.file)
end


## Widget methods
getEnabled(::MIME"application/x-gtk", o::Widget) = o[:widget][:sensitive,Bool]
setEnabled(::MIME"application/x-gtk", o::Widget, value::Bool) = o[:widget][:sensitive] = value

getVisible(::MIME"application/x-gtk", o::Widget) =  o[:widget][:visible, Bool]
setVisible(::MIME"application/x-gtk", o::Widget, value::Bool) = o[:widget][:visible] = value

function getSize(::MIME"application/x-gtk", o::Widget)  
    [size(o[:widget])...]
end

setSize(::MIME"application/x-gtk", o::Widget, value)  =  Gtk.G_.size_request(o[:widget], value...)

getFocus(::MIME"application/x-gtk", o::Widget) = o[:widget][:has_focus,Bool]

function setFocus(::MIME"application/x-gtk", o::Widget, value::Bool) 
    value && 
    ccall((:gtk_widget_grab_focus, Gtk.libgtk), Void, (Ptr{Gtk.GObject},), o[:widget])
end

## Does not preserve types! (1,"one") -> [1, "one"]
getContext(::MIME"application/x-gtk", o::Widget) = o[:widget][:attrs][:context]
function setContext(::MIME"application/x-gtk", o::Widget, ctx)
     o.attrs[:context] = ctx
end
## this is called when a custom context menu is requested. Use pt to add informationt to
## a widget's context
update_context(::MIME"application/x-qt", o::Widget, pt) = nothing


getWidget(::MIME"application/x-gtk", o::Widget) = o.o

### XXX
function setSizepolicy(::MIME"application/x-gtk", o::Widget, policies) 
    o.attrs[:sizepolicy] = policies
end


function align_gtk_widget(o::Widget; xscale=1, yscale=1)
    map_align = {:left => 0.0,
                 :top => 0.0,
                 :center => 0.5,
                 :right => 1.0,
                 :bottom => 1.0,
                 :justify => 0.5,
                 nothing => 0.5
                 }
    


    align = [map_align[k] for k in o[:alignment]]

    println((align, xscale, yscale))


    al = GtkAlignment(align[1], align[2], xscale, yscale)

    if !isa(o[:spacing], Nothing)
        al[:left_padding], al[:right_padding] = o[:spacing][1],o[:spacing][1]
    end
    if !isa(o[:spacing], Nothing)
        al[:top_padding], al[:bottom_padding] = o[:spacing][2],o[:spacing][2]
    end

    push!(al, o.block)
    al
end
## Containers

## get Gtk layout
getLayout(::MIME"application/x-gtk", widget::Container) = widget[:widget][:layout]()
getLayout(widget::Container) = getLayout(widget.toolkit, widget)



## Window
function window(::MIME"application/x-gtk")
    widget = GtkWindow("")
    block = GtkBox(true)
    push!(widget, block)

    menu_block = GtkBox(false)
    ccall((:gtk_box_pack_start, Gtk.libgtk), Void, 
          (Ptr{Gtk.GObject}, Ptr{Gtk.GObject}, Bool, Bool, Int),
          block, menu_block, false, false, 0)

    main_block = GtkBox(false)
    push!(block, main_block)

    status_block = GtkBox(false)
    ccall((:gtk_box_pack_start, Gtk.libgtk), Void, 
          (Ptr{Gtk.GObject}, Ptr{Gtk.GObject}, Bool, Bool, Int),
          block, status_block, false, false, 0)

    (widget, block)
end


### window methods
function raise(::MIME"application/x-gtk", o::Window) 
    o[:widget][:visible] = true
end
lower(::MIME"application/x-gtk", o::Window) = o[:widget][:visible]=false
destroy_window(::MIME"application/x-gtk", o::Window) = Gtk.destroy(o[:widget])

## window properties
getTitle(::MIME"application/x-gtk", o::Window) = o[:widget][:title,String]
setTitle(::MIME"application/x-gtk", o::Window, value::String) = o[:widget][:title] = value

## XXX
getPosition(::MIME"application/x-gtk", o::Window) = [o[:widget][:x](), o[:widget][:y]()]
setPosition(::MIME"application/x-gtk", o::Window, value::Vector{Int}) = o[:widget][:move](value[1], value[2])

## XXX
function getModal(::MIME"application/x-tcltk", o::Window) 

end
function setModal(::MIME"application/x-tcltk", o::Window, value::Bool) 
end

function set_child(::MIME"application/x-gtk", parent::Window, child::Widget)
    Gtk.push!(parent.block[2], child.block)
end

## for BinContainer, only one child we pack and expand...
function set_child(::MIME"application/x-gtk", parent::BinContainer, child::Widget)
    Gtk.push!(parent[:widget], child.block)
end

## Container

## Label frame
function labelframe(::MIME"application/x-gtk", parent::BinContainer, 
                    label::String, alignment::Union(Nothing, Symbol)=nothing)
    widget = GtkFrame(label)

    if isa(alignment, Symbol)
        widget[:label_xalign] = alignment == :left ? 0.0 :(alignment == :right ? 1.0 : 0.5)
    end
    (widget, widget)
end


## Boxes
function boxcontainer(::MIME"application/x-gtk", parent::Container, direction)
    widget = GtkBox(direction == :vertical)
    (widget, widget)
end

## set padx, pady for all the children
function setSpacing(::MIME"application/x-gtk", parent::BoxContainer, px::Vector{Int})
    parent[:widget][:spacing] = px[1] # first one only
end

##
function setMargin(::MIME"application/x-gtk", parent::BoxContainer, px::Vector{Int})
    parent[:widget][:border_width] = px[1] # first only
end


## stretch, strut, spacing
addspacing(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addSpacing](val)
addsstrut(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addStrut](val)
addstretch(::MIME"application/x-qt", parent::BoxContainer, val::Int) = parent[:widget][:layout]()[:addStretch](val)


function insert_child(::MIME"application/x-gtk", parent::BoxContainer, index, child::Widget)
    
    ## we use Gtk.Alignment until deprecated
    expand, fill, padding = false, false, 0
    
    xscale, yscale = (parent[:direction] == :horizontal) ? (0.0, 1.0) : (1.0, 0.0)
    println("yscale=$yscale, xscale=$xscale")
    if parent[:direction] == :horizontal
        if child[:sizepolicy][1] == :expand
            expand=true
            xscale= 1.0
        end
    else
        if child[:sizepolicy][2] == :expand
            expand = true
            yscale = 1.0
        end
    end
    fill = expand


    child_widget = align_gtk_widget(child, xscale=xscale, yscale=yscale)
                                    
    ccall((:gtk_box_pack_start, Gtk.libgtk),
              Void,
              (Ptr{Gtk.GObject},Ptr{Gtk.GObject},Bool, Bool,Int64), 
              parent[:widget], child_widget, expand, fill, padding)
        
    ccall((:gtk_box_reorder_child, Gtk.libgtk), Void,  
          (Ptr{Gtk.GObject},Ptr{Gtk.GObject},Int64), 
          parent[:widget], child_widget, index - 1)
    
    show(child_widget)
    child[:widget][:visible] = parent[:widget][:visible, Bool]

end

function remove_child(::MIME"application/x-gtk", parent::Container, child::Widget)
    delete!(parent[:widget], child[:widget])
end


####
## make a gridq
function grid(::MIME"application/x-gtk", parent::Container)
    ## should dispatch on gtk version type!
    if Gtk.gtk_version >= 3
        ## use ...

    else
        widget = Gtk.GtkTable()
    end
    (widget, widget)
end

## size of grid
function grid_size(::MIME"application/x-gtk", widget::GridContainer)
    ## should dispatch on gtk version type!
    if Gtk.gtk_version >= 3
        ## use ...

    else
        tbl = widget[:widget]
        [tbl[:n_rows,Int], tbl[:n_columns, Int]]
    end
end

## grid spacing
function setSpacing(::MIME"application/x-gtk", parent::GridContainer, px::Vector{Int})
    if Gtk.gtk_version >= 3
        ## use ...
        
    else
        tbl = widget[:widget]
        tbl[:row_spacing] = px[2]
        tbl[:column_spacing] = px[1]
    end
end



## Need to do something to configure rows and columns
## grid add child
function grid_add_child(::MIME"application/x-gtk", parent::GridContainer, child::Widget, i, j)

    ## alignment???
    parent[:widget][j, i] = align_gtk_widget(child) # reversed!!!
    ## need to show XXX will be fixed
    for i in parent[:widget] show(i) end
end

function grid_get_child_at(::MIME"application/x-gtk", parent::GridContainer, i::Int, j::Int)
    error("No method itemAtPosition in Gtk")
end

##XXza
column_minimum_width(::MIME"application/x-qt", object::GridContainer, j::Int, width::Int) = object[:layout]()[:setColumnMinimumWidth](j-1, width)

row_minimum_height(::MIME"application/x-qt", object::GridContainer, j::Int, height::Int) = object[:layout]()[:setRowMinimumdHeight](i-1, height)

column_stretch(::MIME"application/x-qt", object::GridContainer, j::Int, weight::Int) = object[:layout]()[:setColumnStretch](j-1, weight)

row_stretch(::MIME"application/x-qt", object::GridContainer, i::Int, weight::Int) = object[:layout]()[:setRowStretch](i-1, weight)
##################################################

function formlayout(::MIME"application/x-gtk", parent::Container)
 ## should dispatch on gtk version type!
    if Gtk.gtk_version >= 3
        ## use ...

    else
        widget = Gtk.GtkTable(false)
    end
    (widget, widget)
end

## XX labels..
function formlayout_add_child(::MIME"application/x-gtk", parent::FormLayout, child::Widget, label::Union(Nothing, String))
    
    if length(parent[:widget]) == 0
        nrows = 0
    else
        nrows = parent[:widget][:n_rows,Int]
    end

    if !isa(label, Nothing)
        label = Gtk.GtkLabel(label)
        al = Gtk.GtkAlignment(1.0, 0.0, 1.0, 1.0)
        al[:right_padding] = 2
        push!(al, label)
        parent[:widget][1, nrows+1] = al
    end
    parent[:widget][2, nrows+1] = align_gtk_widget(child, xscale=1.0, yscale=0.0)  ## reversed

    map(show,  parent[:widget])

end

function setSpacing(::MIME"application/x-gtk", object::FormLayout, px::Vector{Int})
 if Gtk.gtk_version >= 3
        ## use ...
        
    else
        tbl = widget[:widget]
        tbl[:row_spacing] = px[2]
        tbl[:column_spacing] = px[1]
    end
end

## Notebook
function notebook(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = Gtk.GtkNotebook()


    connect(model, "valueChanged", value -> Gtk.G_.current_page(widget, value-1))
    signal_connect(widget, :switch_page) do obj, ptr, page, args...
        setValue(model, int(page) + 1)
        false
    end

    (widget, widget)
end

## XXX icon, order?
function notebook_insert_child(::MIME"application/x-gtk", parent::NoteBook, child::Widget, i::Int, label::String)
    i = i > length(parent)  ? length(parent) : i-1
    insert!(parent[:widget], i + 1, child.block, label)
    
    map(show, parent[:widget])
end

function notebook_remove_child(::MIME"application/x-gtk", parent::NoteBook, child::Widget)
    ## no findfirst
    n = length(parent.children)
    index = filter(i -> parent.children[i] == child, 1:n)
    splice!(parent[:widget], index[1])
end


##################################################
## Widgets
function label(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = GtkLabel(string(getValue(model)))

    connect(model, "valueChanged") do value
        Gtk.G_.text(widget, string(value))
    end

    (widget, widget)
end

function setAlignment(::MIME"application/x-gtk", o::Label, value)
    als = [:left=>0.0, :right=>1.0, :center=>0.5, :justify=>0.5,
           :top=>0.0, :bottom=>1.0, nothing=>0.5
           ]

 
    o[:widget][:xalign], o[:widget][:yalign] = als[value[1]], als[value[2]]
end


## separator
function separator(::MIME"application/x-gtk", parent::Container; orientation::Symbol=:horizontal)
    widget = Gtk.GtkLabel("----")
    return(widget, widget)
    ## XXX not yet in Gtk.jl
    if orientation == :horizontal
        widget = Gtk.GtkHSeparator()
    else
        widget = Gtk.GtkVSeparator()
    end

    (widget, widget)
end


## Controls
function button(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = GtkButton(getValue(model))
    connect(model, "valueChanged", value -> widget[:label] = value)
    signal_connect(widget, :clicked) do obj, args...
        notify(model, "clicked")
        nothing
    end

    (widget, widget)
end

## XXX
function setIcon(::MIME"application/x-gtk", widget::Button, icon::Union(Nothing, Icon); kwargs...)
    if isa(icon, Nothing)
        icon = Gtk.GtkImage()
    else
        if isa(icon.theme, Nothing) 
            icon.theme = widget[:icontheme]
        end
        icon = get_icon(widget.toolkit, icon)
    end
    Gtk.G_.image(widget[:widget], icon)
end
    
## Linedit
function lineedit(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = GtkEntry()
    widget[:text] = string(getValue(model))
    connect(model, "valueChanged", value -> widget[:text] = string(value))

    ## SIgnals: keyrelease (keycode), activated (value), focusIn, focusOut, textChanged
    signal_connect(widget, :key_release_event) do obj, e, args...
        if e.keyval == Gtk.GdkKeySyms.Return
            notify(model, "editingFinished", getValue(model))
        else
            txt = widget[:text, String]
            setValue(model, txt) # textChanged
            notify(model, "textChanged", txt)
            notify(model, "valueChanged", txt)
        end

        false
    end
    
    signal_connect(widget, :focus_out_event) do widget, e, args...
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
        return(false)
    end
    signal_connect(widget, :focus_in_event) do widget, e, args...
        notify(model, "focusIn")
        return(false)
    end

    signal_connect(widget, :button_press_event) do widget, e, args...
        notify(model, "clicked")
        return(false)
    end

    connect(model, "placeholderTextChanged") do txt
        if Gtk.gtk_version >= 3
            widget[:placeholder_text] = txt
        end
    end


    (widget, widget)
end

## XXX needs GtkEntryCompletion
function setTypeahead(::MIME"application/x-gtk", obj::LineEdit, items)
    XXX()
end    


## Text edit
function textedit(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = GtkTextView()
    buffer = widget[:buffer, Gtk.GtkTextBuffer]

    connect(model, "valueChanged", value -> buffer[:text] = value)
    signal_connect(buffer, :changed) do obj, args...
        model.value = buffer[:text,String]

        return(nothing)
    end

    signal_connect(widget, :focus_out_event) do obj, e, args...
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
        return(false)
    end
    signal_connect(widget, :focus_in_event) do obj, e, args...
        notify(model, "focusIn")
        return(false)
    end

    signal_connect(widget, :key_release_event) do obj, e, args...
        txt = widget[:text, String]
        setValue(model, txt) # textChanged
        notify(model, "textChanged", txt)
        return(false)
    end
    
    signal_connect(widget, :button_press_event) do obj, e, args...
        notify(model, "clicked")
        return(false)
    end


    (widget, widget)
end



## checkbox
function checkbox(::MIME"application/x-gtk", parent::Container, model::Model, label::Union(Nothing, String))
    widget = GtkCheckButton()
    widget[:label] = (isa(label, Nothing) ? "" : label)
    widget[:active] = model.value

    connect(model, "valueChanged", value -> widget[:active] = value)
    signal_connect(widget, :toggled) do obj, args...
        setValue(model, widget[:active,Bool])
    end
    (widget, widget)
end
getLabel(::MIME"application/x-gtk", o::CheckBox) = o[:widget][:label,String]
setLabel(::MIME"application/x-gtk", o::CheckBox, value::String) = o[:widget][:label] = string(value)




## radiogroup
## XXX We don't use radiogroup. This would be useful if we allowed user to
## change items for selection
function radiogroup(::MIME"application/x-gtk", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)

    choices = map(string, copy(model.items))

    g = Gtk.GtkBox(orientation == :vertical)

    btns = [Gtk.GtkRadioButton(shift!(choices))]
    while length(choices) > 0
        push!(btns, Gtk.GtkRadioButton(btns[1], shift!(choices)))
    end
    map(u->push!(g, u), btns)


    selected = findfirst(model.items, model.value)
    btns[selected][:active] = true

    connect(model, "valueChanged") do value 
        ## need to look up which button to set
        selected = findfirst(model.items, value)
        if selected == 0
            error("$value is not one of the labels")
        else
            btns[selected][:active] = true
        end
    end
    for btn in btns
        signal_connect(btn, :toggled) do obj, args...
            if obj[:active, Bool]
                label = obj[:label, String] 
                ## label is string, item may be numeric...
                selected = findfirst(map(string, model.items), label)
                setValue(model, model.items[selected])
            end
        end
    end
    
    (g, g)
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
function combobox(::MIME"application/x-gtk", parent::Container, model::VectorModel; editable::Bool=false)

    ## No way to get editable!
    widget = Gtk.GtkComboBoxText(editable)

    set_index(index) = ccall((:gtk_combo_box_set_active, Gtk.libgtk), Void,
                             (Ptr{Gtk.GObject}, Cint), widget, index-1)
    function set_value(value)
        if isa(value, Nothing)
            set_index(0)
            return
        end
        if widget[:has_entry, Bool]
            ## not easy way to access text area
            entry = ccall((:gtk_bin_get_child, Gtk.libgtk), Gtk.GtkEntry, (Ptr{Gtk.GObject}, ), widget)
             Gtk.G_.text(entry, value)
        else
            i = findfirst(model.items, value) # need index
            set_index(i)
        end
    end

    ## queue like manipulation
    ## push! already defined. Need a length -- but that would need GtkTreeModel
    Base.shift!(widget::Gtk.GtkComboBoxText) = ccall((:gtk_combo_box_text_remove, Gtk.libgtk), Void, (Ptr{Gtk.GObject},Int), widget, 0)
    
    function set_items(items, old_items)
        while length(old_items) > 0
            shift!(old_items)
            shift!(widget)
        end

        for i in items
            push!(widget, string(i))
        end
        set_index(0)            # clear selection?
    end

    set_items(model.items, [])
    set_value(model.value)
    
    connect(model, "valueChanged", value -> set_value(value))
    connect(model, "itemsChanged", set_items)
    
    signal_connect(widget, :changed) do obj, args...
        ## are we editable?
        if widget[:has_entry, Bool]
            ## get active text
            txt = bytestring(Gtk.G_.active_text(widget))
            setValue(model, txt)
        else
            index = widget[:active, Int]
            if index == -1
                setValue(model, nothing)
            else
                setValue(model, model.items[index + 1])
            end
        end
        false
    end


    (widget, widget)
end




## slider
## model stores value, slider is in 1:n
function slider(::MIME"application/x-gtk", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    items = model.items
    initial = model.value
    n = length(items)
    orient = orientation == :horizontal ? false : true

    widget = Gtk.GtkScale(orient, 1, n, 1)
    Gtk.G_.draw_value(widget, false)

    get_value() = Gtk.G_.value(widget)
    set_value(value) = Gtk.G_.value(widget, value)

    connect(model, "valueChanged") do value ## value is in model.items
        ## have to find index from items
        i = indmin(abs(model.items - value))
        set_value(i)
    end

    tooltip_format(x) = string(round(x, 2))
    tooltip_format(x::Int) = string(x)
    tooltip_format(x::String) = x


    ## value is index
    signal_connect(widget, :value_changed) do obj, args...
        value = iround(get_value())
        model_value = model.items[value]
        Gtk.G_.tooltip_text(widget, tooltip_format(model_value))
        setValue(model, model_value)
        return(false)
    end
    (widget, widget)
end

## XXX
## out model stores index
function slider2d(::MIME"application/x-gtk", parent::Container, model::TwoDSliderModel)
    XXX("No slider2d in gtk")
end
getValue(::MIME"application/x-gtk", widget::Slider2D) = getValue(widget.model)
setValue(::MIME"application/x-gtk", widget::Slider2D, value) = setValue(widget.model, value)

## spinbox
function spinbox(::MIME"application/x-gtk", parent::Container, model::ItemModel, rng::Union(Range,Range1))

    widget = Gtk.GtkSpinButton(rng)

    signal_connect(widget, :value_changed) do obj, args...
        value = widget[:value, eltype(rng)]
        println(value)
        setValue(model, value)
    end
    connect(model, "valueChanged", value -> widget[:value] = value)

    (widget, widget)
end

## XXX don't want to suppor this 
# function setRange(::MIME"application/x-qt", obj::SpinBox, rng)
#     step = isa(rng, Range1) ? 1 : rng.step
#     widget = obj[:widget]
# end   

## cairographic
function cairographic(::MIME"application/x-gtk", parent::Container, 
                      model::EventModel; width::Int=480, height::Int=400)

    widget = GtkCanvas(width, height)
    (widget, widget)
end

## Need to do something to display objects along lines of the following but integrated into multimedia display system

function Display(cg::CairoGraphics, pc::PlotContainer)
    c = cg[:widget]
    c.draw = function(_)
        ctx = Base.Graphics.getgc(c)
        Base.Graphics.set_source_rgb(ctx, 1, 1, 1)
        Cairo.paint(ctx)
        Winston.page_compose(pc, Gtk.cairo_surface(c))
    end
    Gtk.draw(c)
end

function Base.display(c::Gtk.GtkCanvas, pc::PlotContainer)
    c.draw = function(_)
        ctx = Base.Graphics.getgc(c)
        Base.Graphics.set_source_rgb(ctx, 1, 1, 1)
        Cairo.paint(ctx)
        Winston.page_compose(pc, Gtk.cairo_surface(c))
    end
    Gtk.draw(c)
end



## Views
## StoreProxyModel
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
            role == convert(Int, qt_enum("DisplayRole")) ?  nms[section + 1] : nothing ##replace(nms[section + 1],"_", " ") : nothing
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
       m[:beginRemoveRows](index, row-1, row - 1 + count - 1)
       m[:endRemoveRows]()
       true
   end

   ## connect model to store so that store changes propogate XXX
   connect(store.model, "rowInserted") do i
       m[:insertRows](i, 1, PySide.QtCore[:QModelIndex]())
   end

    connect(store.model, "rowRemoved") do i
        m[:removeRows](i, 1, PySide.QtCore[:QModelIndex]())
    end

    function rowUpdated(i::Int)
        topleft = m[:index](i-1,0)
        lowerright = m[:index](i, 0)
        m[:emit](PySide.QtCore[:SIGNAL]("dataChanged"))#(topleft, lowerright)
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

    ## configure
    widget[:setAlternatingRowColors](true)
    widget[:horizontalHeader]()[:setStretchLastSection](true)

    ## connect model to view on index changed
    connect(model, "valueChanged") do rows
        map(rows) do row
            widget[:selectRow](row - 1)
        end
    end
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

function update_context(::MIME"application/x-qt", s::StoreView, pt)
    view = s[:widget]
    index = view[:indexAt](pt)
    ## want [i,j] here for row and column
    s[:context] = [index[:row]() + 1, index[:column]() + 1]
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
function imageview(::MIME"application/x-gtk", parent::Container)
    widget = Gtk.GtkImage()
    (widget, widget)
end

function setImage(::MIME"application/x-gtk", o::ImageView, img::String)
    Gtk.G_.from_file(o[:widget], img)
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

    button_box[:setStandardButtons](sum(map(k -> int(defined_btns[k]), buttons)))
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
        s
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

##################################################
## Menus

## XXX there is not GtkAction, or GAction in Gtk (yet), until
## then we follow tk
function action(::MIME"application/x-gtk", parent)
    nothing
end

## XXX Need to do work here, as at present action no knows about its proxies XXX
getEnabled(::MIME"application/x-gtk", action::Action) = nothing
setEnabled(::MIME"application/x-gtk", action::Action, value::Bool) = nothing

## not tk specific bits to add to actions
setLabel(::MIME"application/x-gtk", action::Action, value::String) = nothing
setIcon(::MIME"application/x-gtk", action::Action, value::Icon) = nothing
setShortcut(::MIME"application/x-gtk", action::Action, value::String) = nothing
setTooltip(::MIME"application/x-gtk", action::Action, value::String) = nothing
setCommand(::MIME"application/x-gtk", action::Action, value::Function) = nothing


## menus
function menubar(::MIME"application/x-gtk", parent::Window)
    widget = Gtk.GtkMenuBar()
    push!(parent.block[1], widget)
    show(parent.block[1])
    widget
end

## toplevel menu item
function menu(::MIME"application/x-gtk", parent::MenuBar, label)
    item = Gtk.GtkMenuItem(label)
    mitem = Gtk.GtkMenu(item)
    push!(parent[:widget], item)
    mitem
end

## submenu
function menu(::MIME"application/x-gtk", parent::Menu, label)
    item = Gtk.GtkMenuItem(label)
    mitem = Gtk.GtkMenu(item)
    push!(parent[:widget], item)
    mitem
end

## popup
function menu(::MIME"application/x-gtk", parent::Widget)
    XXX("add me")
    ## needs to bind to thrid mouse event, ...
    parent[:widget][:setContextMenuPolicy](PySide.QtCore["Qt"][:CustomContextMenu])
    m = PySide.Qt.QMenu(parent[:widget])

    qconnect(parent[:widget], :customContextMenuRequested) do pt
        update_context(parent.toolkit, parent, pt)
        m[:popup](parent[:widget][:mapToGlobal](pt))
    end

    m
end

## add actions
function addAction(::MIME"application/x-gtk", parent::Menu, action::Action)
    item = Gtk.GtkMenuItem(action.label)
    if !isa(action.tooltip, Nothing) 
        Gtk.G_.tooltip_text(item, action.tooltip) 
    end
    signal_connect(item, :activate) do widget
        action.command()
    end
    
    push!(parent[:widget], item)
end

function addAction(::MIME"application/x-gtk", parent::Menu, value::Separator)
    push!(parent[:widget], Gtk.SeparatorMenuItem())
end

function addAction(::MIME"application/x-gtk", parent::Menu, value::RadioGroup)
    XXX("Not implemented in Gtk.jl")
    widget = Qt.QActionGroup(parent[:widget])
    widget[:setExclusive](true)
    for item in value.model.items
        action = Qt.QAction(item, parent[:widget])
        action[:setCheckable](true)
        widget[:addAction](action)
        parent[:widget][:addAction](action)
    end
    qconnect(widget, :triggered) do action
        notify(value.model, "valueChanged", action[:text]())
    end
end

function addAction(::MIME"application/x-gtk", parent::Menu, value::CheckBox)
    XXX("Not implemented in Gtk.jl")
    widget = Qt.QAction(value[:label], parent[:widget])
    widget[:setCheckable](true)
    ## widget[:setIcon](...)
    qconnect(widget, :changed) do 
        notify(value.model, "valueChanged", widget[:isChecked]())
    end
    
    parent[:widget][:addAction](widget)
end


## manipulate


function Display(::MIME"application/x-gtk", self::ManipulateObject, x::Any; kwargs...) 
    if isa(x, Nothing) return end
    oa = self.output_area
    
    if length(children(oa)) > 0 && isa(oa.children[1], TextEdit)
        te = oa.children[1]
        te[:value] = string(x)
        return
    elseif length(children(oa)) > 0
        pop!(oa)
    end
    ## add one
    te = textedit(oa)
    te[:sizepolicy] = (:expand, :expand)
    push!(oa, te)
    te[:value] = string(x)
end

function Display(::MIME"application/x-gtk", self::ManipulateObject, x::FramedPlot; kwargs...) 
    if isa(x, Nothing) return end
    oa = self.output_area
    
    if length(children(oa)) > 0 && isa(oa.children[1], CairoGraphics)
        cnv = oa.children[1]
        Winston.display(cnv.o, x)
        return
    elseif length(children(oa)) > 0
        pop!(oa)
    end
    ## add one
    cnv = cairographic(oa, width=480, height=480)
    cnv[:sizepolicy] = (:expand, :expand)
    push!(oa, cnv)
    Display(cnv, x)
end