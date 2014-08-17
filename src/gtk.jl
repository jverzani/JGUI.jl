## Gtk implementation

include("gtk-addons.jl")

## TODO
## * dialogs
## * others


XXX() = error("not defined")
XXX(msg) = println(msg)
## Icons
function get_icon(::MIME"application/x-gtk", o::StockIcon)
    if isa(o.nm, Nothing)
        Gtk.GtkImage()
    else
        file = Pkg.dir("JGUI", "icons", string(o.theme), string(o.nm) * ".png")
        @GtkImage(file)
    end
end
function get_icon(::MIME"application/x-gtk", o::FileIcon)
    @GtkImage(o.file)
end


## Widget methods
getEnabled(::MIME"application/x-gtk", o::Widget) = getproperty(o[:widget], :sensitive,Bool)
setEnabled(::MIME"application/x-gtk", o::Widget, value::Bool) = setproperty!(o[:widget], :sensitive, value)

getVisible(::MIME"application/x-gtk", o::Widget) =  getproperty(o[:widget], :visible, Bool)
function setVisible(::MIME"application/x-gtk", o::Widget, value::Bool) 
    setproperty!(o[:widget], :visible,  value)
    showall(o[:widget])
end

function getSize(::MIME"application/x-gtk", o::Widget)  
    [size(o[:block])...]
end

setSize(::MIME"application/x-gtk", o::Widget, value)  =  Gtk.G_.size_request(o[:block], value...)

getFocus(::MIME"application/x-gtk", o::Widget) = getproperty(o[:widget],:has_focus,Bool)

function setFocus(::MIME"application/x-gtk", o::Widget, value::Bool) 
    value && 
    ccall((:gtk_widget_grab_focus, Gtk.libgtk), Void, (Ptr{Gtk.GObject},), o[:widget])
end

## Does not preserve types! (1,"one") -> [1, "one"]
getContext(::MIME"application/x-gtk", o::Widget) = o.attrs[:context]
function setContext(::MIME"application/x-gtk", o::Widget, ctx)
     o.attrs[:context] = ctx
end
## this is called when a custom context menu is requested. Use pt to add informationt to
## a widget's context
update_context(::MIME"application/x-qt", o::Widget, pt) = nothing


getWidget(::MIME"application/x-gtk", o::Widget) = o.o
getBlock(::MIME"application/x-gtk", o::Widget) = o.block

function setSizepolicy(::MIME"application/x-gtk", o::Widget, policies) 
    o.attrs[:sizepolicy] = policies
    ## modify widget!
    if Gtk.gtk_version >= 3    
        hexpand = policies[1] == :expand ? true : false
        vexpand = policies[2] == :expand ? true : false
        Gtk.G_.hexpand(o[:block], hexpand)
        Gtk.G_.vexpand(o[:block], vexpand)
    else
        "XXX"
    end
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
    

    if Gtk.gtk_version >= 3
#        Gtk.G_.halign(o[:block], align[1])
#        Gtk.G_.valign(o[:block], align[2])
    else
        al = GtkAlignment(align[1], align[2], xscale, yscale)

        if !isa(o[:spacing], Nothing)
            setproperty!(al, :left_padding, o[:spacing][1])
            setproperty!(al, :right_padding, o[:spacing][2])
        end
        if !isa(o[:spacing], Nothing)
            setproperty!(al, :top_padding, o[:spacing][2]) # is 2 right? XXX
            setproperty!(al, :bottom_padding, o[:spacing][2])
        end
        
        push!(al, o.block)
        al
    end
end
    ## Containers
    
## get Gtk layout
getLayout(::MIME"application/x-gtk", widget::Container) = widget[:widget][:layout]()
getLayout(widget::Container) = getLayout(widget.toolkit, widget)



## Window
function window(::MIME"application/x-gtk"; visible::Bool=true, kwargs...)
    widget = @GtkWindow("")
    !visible && setproperty!(widget, :visible, false) 

    block = @GtkBox(true)
    push!(widget, block)

## XXX clean this up by setting size on object...
    menu_block = @GtkBox(false)
    ccall((:gtk_box_pack_start, Gtk.libgtk), Void, 
          (Ptr{Gtk.GObject}, Ptr{Gtk.GObject}, Bool, Bool, Int),
          block, menu_block, false, false, 0)

    main_block = @GtkBox(false)
    push!(block, main_block)

    status_block = @GtkBox(false)
    ccall((:gtk_box_pack_start, Gtk.libgtk), Void, 
          (Ptr{Gtk.GObject}, Ptr{Gtk.GObject}, Bool, Bool, Int),
          block, status_block, false, false, 0)

    (widget, block)
end


### window methods
function raise(::MIME"application/x-gtk", o::Window) 
    setproperty!(o[:widget], :visible, true)
end
lower(::MIME"application/x-gtk", o::Window) = setproperty!(o[:widget], :visible, false)
destroy_window(::MIME"application/x-gtk", o::Window) = Gtk.destroy(o[:widget])

## window properties
getTitle(::MIME"application/x-gtk", o::Window) = getproperty(o[:widget], :title, String)
function setTitle(::MIME"application/x-gtk", o::Window, value::String) 
    setproperty!(o[:widget], :title, value)
end


## XXX
getPosition(::MIME"application/x-gtk", o::Window) = [o[:widget][:x](), o[:widget][:y]()]
setPosition(::MIME"application/x-gtk", o::Window, value::Vector{Int}) = o[:widget][:move](value[1], value[2])

## XXX
function getModal(::MIME"application/x-tcltk", o::Window) 

end

## XXX
function setModal(::MIME"application/x-tcltk", o::Window, value::Bool) 
end

function set_child(::MIME"application/x-gtk", parent::Window, child::Widget)
    if Gtk.gtk_version >= 3
        Gtk.G_.hexpand(child.block, true)
        Gtk.G_.vexpand(child.block, true)
    else
        "XXX"
    end
    Gtk.push!(parent.block[2], child.block)
    showall(parent.o)
end

## don't expand in all directions for box containers. Hacky!
function set_child(::MIME"application/x-gtk", parent::Window, child::BoxContainer)
    if child.attrs[:direction] == :horizontal
        Gtk.G_.vexpand(child.block, true)
    else
         Gtk.G_.hexpand(child.block, true)
    end
    Gtk.push!(parent.block[2], child.block)
    showall(parent.o)
end

## for BinContainer, only one child we pack and expand...
function set_child(::MIME"application/x-gtk", parent::BinContainer, child::Widget)
    if Gtk.gtk_version >= 3
        Gtk.G_.hexpand(child.block, true)
        Gtk.G_.vexpand(child.block, true)
    else
        "XXX"
    end
    Gtk.push!(parent[:widget], child.block)
    parent[:visible] && showall(parent[:widget])
end

## Container

## Label frame
function labelframe(::MIME"application/x-gtk", parent::BinContainer, 
                    label::String, alignment::Union(Nothing, Symbol)=nothing)
    widget = @GtkFrame(label)

    if isa(alignment, Symbol)
        widget[:label_xalign] = alignment == :left ? 0.0 :(alignment == :right ? 1.0 : 0.5)
    end
    (widget, widget)
end


## Boxes
function boxcontainer(::MIME"application/x-gtk", parent::Container, direction)
    widget = @GtkBox(direction == :vertical)
    (widget, widget)
end

## set padx, pady for all the children
function setSpacing(::MIME"application/x-gtk", parent::BoxContainer, px::Vector{Int})
    setproperty!(parent[:widget], :spacing, px[1]) # first one only
end

##
function setMargin(::MIME"application/x-gtk", parent::BoxContainer, px::Vector{Int})
    setproperty!(parent[:widget], :border_width, px[1]) # first only
end


## stretch, strut, spacing XXX
function addspacing(::MIME"application/x-gtk", parent::BoxContainer, val::Int) 
    box = parent[:widget]
    if parent.attrs[:direction] == :horizontal
        child = vbox(parent)
        child[:size] = [val, 1]
        push!(parent, child)
    else
        child = hbox(parent)
        child[:size] = [1, val]
        push!(parent, child)
    end
end

function addsstrut(::MIME"application/x-gtk", parent::BoxContainer, val::Int) 
    box = parent[:widget]
    if parent.attrs[:direction] == :horizontal
        child = vbox(parent)
        child[:size] = [1, val]
        push!(parent, child)
    else
        child = hbox(parent)
        child[:size] = [val, 1]
        push!(parent, child)
    end
end
function addstretch(::MIME"application/x-gtk", parent::BoxContainer, val::Int) 
    box = parent[:widget]
    if parent.attrs[:direction] == :horizontal
        child = vbox(parent)
        child[:sizepolicy] = (:expand, :fixed)
        push!(parent, child)
    else
        child = hbox(parent)
        child[:sizepolicy] = (:fixed, :expand)
        push!(parent, child)
    end
end


function insert_child(::MIME"application/x-gtk", parent::BoxContainer, index, child::Widget)
    
    ## XXX -- update this for v3
    ## we use Gtk.Alignment until deprecated
    expand, fill, padding = true, true, 0
    
    xscale, yscale = (parent[:direction] == :horizontal) ? (0.0, 1.0) : (1.0, 0.0)
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

    child_widget = child[:block]
#    child_widget = align_gtk_widget(child, xscale=xscale, yscale=yscale)

    ccall((:gtk_box_pack_start, Gtk.libgtk),
              Void,
              (Ptr{Gtk.GObject},Ptr{Gtk.GObject}, Bool, Bool,Int64), 
              parent[:widget], child_widget, expand, fill, padding)
        
    ccall((:gtk_box_reorder_child, Gtk.libgtk), Void,  
          (Ptr{Gtk.GObject},Ptr{Gtk.GObject},Int64), 
          parent[:widget], child_widget, index - 1)
    
    show(child_widget)
    setproperty!(child[:widget], :visible, getproperty(parent[:widget], :visible, Bool))

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
        widget = @GtkGrid()
    else
        widget = @GtkTable()
    end
    (widget, widget)
end

## size of grid
function grid_size(::MIME"application/x-gtk", widget::GridContainer)
    ## should dispatch on gtk version type!
    if Gtk.gtk_version >= 3
       widget.attrs[:size]      # internal book-keeping, no method
    else
        tbl = widget[:widget]
        [getproperty(tbl, :n_rows, Int), getproperty(tbl, :n_columns, Int)]
    end
end

## grid spacing
function setSpacing(::MIME"application/x-gtk", parent::GridContainer, px::Vector{Int})
    if Gtk.gtk_version >= 3
        ## use ... XXX
        
    else
        tbl = widget[:widget]
        setproperty(tbl, :column_spacing, px[1])
        setproperty(tbl, :row_spacing, px[2])
    end
end

##XXXXXXX
column_minimum_width(::MIME"application/x-gtk", object::GridContainer, j::Int, width::Int) = XXX("column_minimum_width")

row_minimum_height(::MIME"application/x-gtk", object::GridContainer, j::Int, height::Int) = XXX("row_minimum_width")

column_stretch(::MIME"application/x-gtk", object::GridContainer, j::Int, weight::Int) = XXX("Column_stretch")

row_stretch(::MIME"application/x-gtk", object::GridContainer, i::Int, weight::Int) = XXX("row_stretch")



## Need to do something to configure rows and columns
## grid add child
function grid_add_child(::MIME"application/x-gtk", parent::GridContainer, child::Widget, i, j)

    ## alignment???
    parent[:widget][j, i] = align_gtk_widget(child) # reversed!!!

    ## manage size for v3
    sz = parent.attrs[:size]
    sz[1] = max(sz[1], i...)
    sz[2] = max(sz[2], j...)
    parent.attrs[:size] = sz

    ## need to show XXX will be fixed
    for i in parent[:widget] show(i) end
end

## XXX  -- hack this in during add?
function grid_get_child_at(::MIME"application/x-gtk", parent::GridContainer, i::Int, j::Int)
    error("No method itemAtPosition in Gtk.")
end

##################################################
## XXX too much code duplication with grid
function formlayout(::MIME"application/x-gtk", parent::Container)
    if Gtk.gtk_version >= 3
        widget = @GtkGrid()
    else
        widget = @GtkTable()
    end
    (widget, widget)
end

## XXX unify alignment here...
function formlayout_add_child(::MIME"application/x-gtk", parent::FormLayout, child::Widget, label::Union(Nothing, String))
    if Gtk.gtk_version >= 3
        nrows = parent.attrs[:nrows]
        if isa(label, Nothing)
            label == ""
        end
        ## XXX spacing...
        parent[:widget][1, nrows+1] = @GtkLabel(label)
        parent[:widget][2, nrows+1] = child.block

        parent.attrs[:nrows] = nrows + 1

    else
        ## gtk2
        if length(parent[:widget]) == 0
            nrows = 0
        else
            nrows = getproperty(parent[:widget], :n_rows, Int)
        end
        
        if !isa(label, Nothing)
            label = @GtkLabel(label)
            al = @GtkAlignment(1.0, 0.0, 1.0, 1.0)
            setproperty!(al, :right_padding, 2)
            push!(al, label)
            parent[:widget][1, nrows+1] = al
        end
        parent[:widget][2, nrows+1] = align_gtk_widget(child, xscale=1.0, yscale=0.0)  ## reversed
        
    end
    map(show,  parent[:widget])

end

function setSpacing(::MIME"application/x-gtk", object::FormLayout, px::Vector{Int})
    if Gtk.gtk_version >= 3
        ## use ... XXX see grid..
        
    else
        tbl = widget[:widget]
        setproperty(tbl, :column_spacing, px[1])
        setproperty(tbl, :row_spacing, px[2])
    end
end

## Notebook
function notebook(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = @GtkNotebook()

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
    widget = @GtkLabel(string(getValue(model)))

    connect(model, "valueChanged") do value
        Gtk.G_.text(widget, string(value))
    end

    (widget, widget)
end

function setAlignment(::MIME"application/x-gtk", o::Label, value)
    als = [:left=>0.0, :right=>1.0, :center=>0.5, :justify=>0.5,
           :top=>0.0, :bottom=>1.0, nothing=>0.5
           ]

    setproperty!(o[:widget], :xalign, als[value[1]])
    setproperty!(o[:widget], :yalign, als[value[2]])
end


## separator
function separator(::MIME"application/x-gtk", parent::Container; orientation::Symbol=:horizontal)
    widget = @GtkLabel("----")
    return(widget, widget)
    ## XXX not yet in Gtk.jl
#    if orientation == :horizontal
#        widget = @GtkHSeparator()
#    else
#        widget = @GtkVSeparator()
#    end

    (widget, widget)
end


## Controls
function button(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = @GtkButton(string(getValue(model)))
    connect(model, "valueChanged", 
            value -> setproperty!(widget,:label, string(value)))
    signal_connect(widget, :clicked) do obj, args...
        notify(model, "clicked")
        nothing
    end

    (widget, widget)
end

## XXX
function setIcon(::MIME"application/x-gtk", widget::Button, icon::Union(Nothing, Icon); kwargs...)
    if isa(icon, Nothing)
        icon = @GtkImage()
    else
        if isa(icon.theme, Nothing) 
            icon.theme = widget[:icontheme]
        end
        icon = get_icon(widget.toolkit, icon)
    end
    Gtk.G_.image(widget[:widget], icon)
    show(icon)
end
    
## Linedit
function lineedit(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = @GtkEntry()
    setproperty!(widget, :text, string(getValue(model)))
    connect(model, "valueChanged", value -> setproperty!(widget, :text, string(value)))

    ## SIgnals: keyrelease (keycode), activated (value), focusIn, focusOut, textChanged
    signal_connect(widget, :key_release_event) do obj, e, args...
        if e.keyval == Gtk.GdkKeySyms.Return
            notify(model, "editingFinished", getValue(model))
        else
            txt = getproperty(widget, :text, String)
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
            setproperty!(widget, :placeholder_text, txt)
        end
    end


    (widget, widget)
end

## XXX needs GtkEntryCompletion XXX It is there now!
function setTypeahead(::MIME"application/x-gtk", obj::LineEdit, items)
    compl = @GtkEntryCompletion()
    ## make model, set as model
    mod = @GtkListStore
    [push!(mod, (item,)) for item in items]
    Gtk.G_.model(compl, mod)
    Gtk.G_.text_column(compl, 0)
    ## set' completion
    Gtk.G_.completion(obj[:widget], compl)
end    


## Text edit
function textedit(::MIME"application/x-gtk", parent::Container, model::Model)
    widget = @GtkTextView()
    block = @GtkScrolledWindow()
    [setproperty!(widget, x, true) for  x in [:hexpand, :vexpand]]
    push!(block, widget)


    buffer = getproperty(widget, :buffer, GtkTextBuffer)

    get_value() = join([i for i in buffer], "")

    connect(model, "valueChanged", value -> setproperty!(buffer, :text, join(value, "\n")))
    signal_connect(buffer, :changed) do obj, args...
        model.value = get_value()

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
        txt = get_value()
        setValue(model, txt) # textChanged
        notify(model, "textChanged", txt)
        return(false)
    end
    
    signal_connect(widget, :button_press_event) do obj, e, args...
        notify(model, "clicked")
        return(false)
    end


    (widget, block)
end

## used to add to non-editable text eidt
function push_textedit(::MIME"application/x-gtk", o::TextEdit, value::String)
    widget = o[:widget]
    buffer = getproperty(widget, :buffer, Gtk.GtkTextBuffer)
    setproperty!(widget, :editable, false)

    insert!(buffer, value)
end
    
function push_textedit(::MIME"application/x-gtk", o::TextEdit, value::CairoGraphics)
    widget = o[:widget]
    child = value[:widget]

    buffer = getproperty(widget, :buffer, Gtk.GtkTextBuffer)
    
    ## make an end iter
    enditer = Gtk.mutable(Gtk.GtkTextIter)
    ccall((:gtk_text_buffer_get_iter_at_offset, Gtk.libgtk),Void,
          (Ptr{Gtk.GObject},Ptr{Gtk.GtkTextIter},Cint),buffer,enditer,-1)

    anchor = ccall((:gtk_text_buffer_create_child_anchor, Gtk.libgtk),Ptr{Void},
                   (Ptr{Gtk.GObject},Ptr{Gtk.GtkTextIter}),buffer, enditer)
    
    ccall((:gtk_text_view_add_child_at_anchor, Gtk.libgtk),Void,
          (Ptr{Gtk.GObject},Ptr{Gtk.GObject},Ptr{Void}), widget, child, anchor)
    
    setproperty!(child, :visible, true)
end
    
## checkbox
function checkbox(::MIME"application/x-gtk", parent::Container, model::Model, label::Union(Nothing, String))
    widget = @GtkCheckButton()
    setproperty!(widget, :label, (isa(label, Nothing) ? "" : label))
    setproperty!(widget, :active, model.value)

    connect(model, "valueChanged", value -> setproperty!(widget, :active, value))
    signal_connect(widget, :toggled) do obj, args...
        setValue(model, getproperty(widget, :active,Bool))
    end
    (widget, widget)
end
getLabel(::MIME"application/x-gtk", o::CheckBox) = getproperty(o[:widget],:label,String)
setLabel(::MIME"application/x-gtk", o::CheckBox, value::String) = setproperty!(o[:widget],:label, string(value))




## radiogroup
## XXX We don't use radiogroup. This would be useful if we allowed user to
## change items for selection
function radiogroup(::MIME"application/x-gtk", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)

    choices = map(string, copy(model.items))

    g = @GtkBox(orientation == :vertical)

    btns = [@GtkRadioButton(shift!(choices))]
    while length(choices) > 0
        push!(btns, @GtkRadioButton(btns[1], shift!(choices)))
    end
    map(u->push!(g, u), btns)


    selected = findfirst(model.items, model.value)
    setproperty!(btns[selected], :active, true)

    connect(model, "valueChanged") do value 
        ## need to look up which button to set
        selected = findfirst(model.items, value)
        if selected == 0
            error("$value is not one of the labels")
        else
            setproperty!(btns[selected], :active, true)
        end
    end
    for btn in btns
        signal_connect(btn, :toggled) do obj, args...
            if getproperty(obj, :active, Bool)
                label = getproperty(obj, :label, String)
                ## label is string, item may be numeric...
                selected = findfirst(map(string, model.items), label)
                setValue(model, model.items[selected])
            end
        end
    end
    
    ## XXX must call vsibile here
    setproperty!(g, :visible,  true)
    showall(g)

    (g, g)
end

## buttongroup XXX
function buttongroup(::MIME"application/x-gtk", parent::Container, model::VectorModel; exclusive::Bool=false)
    if exclusive
        error("exclusive not implemented")
    end

    block = @GtkBox(false)

    function exclusive_handler(btn)
        ## XXX write me
    end
    function non_exclusive_handler(btn)
        buttons = collect(block)
        chosen = Bool[getproperty(btn, :active, Bool) for btn in buttons]
        names = [getproperty(btn, :label, String) for btn in buttons]
        model[:value] = names[chosen]
    end

    choices = map(string, copy(model.items))
    for choice in choices
        btn = Gtk.@GtkToggleButton(choice)
        signal_connect(exclusive ? exclusive_handler : non_exclusive_handler, btn, :toggled)
        push!(block, btn)
    end
    
    connect(model, "valueChanged") do values
        if exclusive
            "XXX"
        else
            buttons = collect(block)
            for button in buttons
                label = getproperty(button, :label, String)
                setproperty!(button, :active, label in values)
            end
        end
    end

    (block, block)
    
end

## 
function combobox(::MIME"application/x-gtk", parent::Container, model::VectorModel; editable::Bool=false)

    ## No way to get editable!
    widget = @GtkComboBoxText(editable)

    set_index(index) = ccall((:gtk_combo_box_set_active, Gtk.libgtk), Void,
                             (Ptr{Gtk.GObject}, Cint), widget, index-1)
    function set_value(value)
        if isa(value, Nothing)
            set_index(0)
            return
        end
        if getproperty(widget, :has_entry, Bool)
            entry = Gtk.G_.child(widget)
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
## XXX        set_index(0)            # clear selection?
    end

    set_items(model.items, [])
    set_value(model.value)
    
    connect(model, "valueChanged", value -> set_value(value))
    connect(model, "itemsChanged", set_items)
    
    signal_connect(widget, :changed) do obj, args...
        ## are we editable?
        if getproperty(widget, :has_entry, Bool)
            ## get active text
            txt = bytestring(Gtk.G_.active_text(widget))
            setValue(model, txt)
        else
            index = getproperty(widget, :active, Int)
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

    widget = @GtkScale(orient, 1, n, 1)
    Gtk.G_.draw_value(widget, false)

    get_value() = Gtk.G_.value(widget)
    set_value(value) = Gtk.G_.value(widget, value)

    connect(model, "valueChanged") do value ## value is in model.items
        ## have to find index from items
        i = indmin(abs(model.items .- value))
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
function spinbox(::MIME"application/x-gtk", parent::Container, model::ItemModel, rng::Range)

    widget = @GtkSpinButton(rng)

    signal_connect(widget, :value_changed) do obj, args...
        value = getproperty(widget, :value, eltype(rng))
        setValue(model, value)
    end
    connect(model, "valueChanged", value -> setproperty!(widget, :value, value))

    (widget, widget)
end


## cairographic
function cairographic(::MIME"application/x-gtk", parent::Container, 
                      model::EventModel; width::Int=480, height::Int=400)

    widget = @GtkCanvas(width, height)
    (widget, widget)
end


## Views XXX
## StoreProxyModel

function store_proxy_model(parent, store::Store)

    m = @GtkListStore(store.types...)

    ## add in any in store
    for record in store.items
        push!(m, tuple(record...))
    end

   ## connect model to store so that store changes propogate XXX
    connect(store.model, "rowInserted") do i
        record = store.items[i]
        push!(m, tuple(record...))
    end

    connect(store.model, "rowRemoved") do i
        splice!(m, i)
    end

    function rowUpdated(i::Int)
        record = store.items[i]
        map(j -> m[i,j] = record[j], 1:length(record))
    end
    connect(store.model, "rowUpdated", rowUpdated)



   ## return model
   m
end

## storeview XXX
function make_column{T <: String}(::Type{T}, nm::String, col::Int)
    cr =  @GtkCellRendererText()
    col = @GtkTreeViewColumn(nm, cr, {"text" => col-1})
    col
end

function make_column{T<:Number}(::Type{T}, nm::String, col::Int)
    cr =  @GtkCellRendererText()
    col = @GtkTreeViewColumn(nm, cr, {"text" => col-1})
    col
end

function make_column(::Type{Bool}, nm::String, col::Int)
    cr = @GtkCellRendererToggle()
    col = @GtkTreeViewColumn(nm, cr, {"active"=> col-1 })
end


function storeview(::MIME"application/x-gtk", parent::Container, store::Store, model::ItemModel; kwargs...)
    

    ## Set up view
    widget = @GtkTreeView()
    block = @GtkScrolledWindow()
    [setproperty!(widget, x, true) for  x in [:hexpand, :vexpand]]
    push!(block, widget)

    ## set up model
    m = store_proxy_model(widget, store)
    Gtk.G_.model(widget, m)

    ## selection model
    sel = Gtk.G_.selection(widget) 
    ## add cell renderers

    for j in 1:length(store.types)
        col = make_column(store.types[j], "Column $j", j)
        signal_connect(col, :clicked) do _
            notify(model, "headerClicked", j)
        end

        push!(widget, col)
    end

    ## configure
#    widget[:setAlternatingRowColors](true)
#    widget[:horizontalHeader]()[:setStretchLastSection](true)
    Gtk.G_.headers_clickable(widget, true)

    ## notify JGUI model of changes to selection
#    id = signal_connect(sel, :changed) do sel
#        indices = selected(widget)
#        setValue(model, indices; signal=false) # model holds selection, store.model.value the value
#        notify(model, "selectionChanged", indices)
#        false
#    end

    # ## connect model to view on index changed
    connect(model, "valueChanged") do indices
        if Gtk.G_.mode(sel) == Gtk.GConstants.GtkSelectionMode.MULTIPLE
            unselectall!(widget)
        else
            if indices == [0] & Gtk.hasselection(sel)
                m, iter = selected(sel)
                ccall((:gtk_tree_selection_unselect_iter, Gtk.libgtk), Void,
                      (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}),
                      sel, iter)
                return
            end
        end
        
        indices = filter(x -> 0 < x <= length(store), indices) 
        map(index -> select!(widget, index), indices)
    end
 

    ## clicked and doubleClicked
    ## issue with clicking on the header!
    signal_connect(widget, :button_press_event) do w, e
        row, col = tree_view_row_col_from_x_y(w, int(e.x), int(e.y))

        if row > 0
            if e.event_type == Gtk.GdkEventType.GDK_2BUTTON_PRESS
                notify(model, "doubleClicked", row, col)
            else
                notify(model, "clicked", row, col)
            end
        end
        return false
    end


    (widget, block)
end


function getSelectmode(::MIME"application/x-gtk", s::ModelView) 
    sel = Gtk.G_.selection(s[:widget])
    if Gtk.G_.mode(sel) == Gtk.GConstants.GtkSelectionMode.SINGLE
        return :single
    else
        return :multiple
    end
end
## val is single, multiple
function setSelectmode(::MIME"application/x-gtk", s::ModelView, val::Symbol)
    sel =  Gtk.G_.selection(s[:widget])
    Gtk.G_.mode(sel, val == :single ? Gtk.GConstants.GtkSelectionMode.SINGLE : Gtk.GConstants.GtkSelectionMode.MULTIPLE)
end

## getWidths
function getWidths(::MIME"application/x-gtk", s::StoreView)
    n = size(s.store)[2]
    [Gtk.G_.min_width(Gtk.G_.column(s.o,i-1)) for i in 1:n]
end

function setWidths(::MIME"application/x-gtk", s::StoreView, widths::Vector{Int})
    for (i, width) in enumerate(widths)
        Gtk.G_.min_width(Gtk.G_.column(s.o,i-1), width)
    end
end

function getNames(::MIME"application/x-gtk", s::StoreView)
    get_tree_view_names(s[:widget])
end

function setNames(::MIME"application/x-gtk", s::StoreView, nms::Vector)
    set_tree_view_names(s[:widget], nms)
end


## heights
function getHeights(::MIME"application/x-gtk", s::ModelView)
    XXX("no heights")
end

function setHeights(::MIME"application/x-gtk", s::ModelView, heights::Vector{Int})
    XXX("no heights")
end


function getHeadervisible(::MIME"application/x-gtk", s::StoreView)
    Gtk.G_.headers_visible(s[:widget])
end
function setHeadervisible(::MIME"application/x-gtk", s::StoreView, val::Bool)
    XXX("Warning, this seems broken...")
     Gtk.G_.headers_visible(s[:widget], val)
end


function getRownamesvisible(::MIME"application/x-gtk", s::StoreView)
    XXX("no rownames")
end
function setRownamesvisible(::MIME"application/x-qt", s::StoreView, val::Bool)
    XXX("no rownames")
end



function setIcon(::MIME"application/x-qt", s::StoreView, i::Int, icon::Icon)
    XXX("no icons")
end


## Tree view
function store_proxy_model(::MIME"application/x-gtk", store::TreeStore)
    ## proxy gtkTreeStore to JGUI::TreeStore

    gtkstore = Gtk.@TreeStore(String, store.types...)

    
    ## Intial synchronize jgui store with gtkstore
    function add_children(parentnode; node=nothing)
        if length(parentnode.children) > 0
            for i in 1:length(parentnode.children)
                child = parentnode.children[i]
                cnode = push!(gtkstore, tuple(child.text, child.data...), node)
                add_children(child, node=cnode)
            end
        end
    end
    add_children(store)

    ## connect tree store to gtkstore
    connect(store.model, "insertNode") do parent, ind, child
        ## how to get index from parent!!!
    insert!(gtkstore, node_to_path(parent), child.data, how=:parent, where=:after)
    end

    connect(store.model, "removeNode") do parent, ind
        if isa(parent, Union(TreeStore, Nothing))
            path = [ind]
        else
            path = [node_to_path(parent), ind]
        end
        splice!(gtkstore, path)
    end
    
    connect(store.model, "updatedNode") do node
        ## XXX how to update in place? I can delete then remove, but this seems wrong
        ind = node.index
        splice!(gtkstore, ind)
        insert!(gtkstore, ind, node.data, how=:sibling, where=:after)
    end
    
    gtkstore
end

## tpl: a template for the type, otherwise from tr.children[1]
function treeview(::MIME"application/x-gtk", parent::Container, store::TreeStore, model::ItemModel)

    ## get store
    gtkstore = store_proxy_model(parent.toolkit, store)

    ## view of store
    widget = @GtkTreeView(Gtk.TreeModel(gtkstore))
    block = @GtkScrolledWindow()
    [setproperty!(widget, x, true) for  x in [:hexpand, :vexpand]]
    push!(block, widget)

    ## make cell renderers
    ## key is a string
    rend = Gtk.@CellRendererText()
    col = Gtk.@TreeViewColumn("", rend, {"text" => 0})
    push!(widget, col)
    ## others
    for j in 1:length(store)
        col = make_column(store.types[j], "Column $j", j)
        signal_connect(col, :clicked) do _
            notify(model, "headerClicked", j)
        end
        push!(widget, col)
    end

    
    ## XXX
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

    ## 
    function expandNode(tview, gtkstore, node)
        ind = node_to_path(node)
        path = Gtk.path(Gtk.TreeModel(gtkstore), Gtk.iter_from_index(gtkstore, ind)[])
        ccall((:gtk_tree_view_expand_row, Gtk.libgtk), Bool, 
              (Ptr{GObject}, Ptr{Gtk.GtkTreePath}, Cint), 
              tview, path, false)
    end
    function collapseNode(tview, gtkstore, node)
        ind = node_to_path(node)
        path = Gtk.path(Gtk.TreeModel(gtkstore), Gtk.iter_from_index(gtkstore, ind)[])
        ccall((:gtk_tree_view_collapse_row, Gtk.libgtk), Bool, 
              (Ptr{GObject}, Ptr{Gtk.GtkTreePath}), 
              tview, path)
    end
    

    ###########################
    ## connect model and widget
    connect(model, "expandNode", expandNode)
    connect(model, "collapseNode", collapseNode)


    
    connect(model, "valueChanged") do value
        ## XXX set selection. Fails!! selection is matching 
        return()
        selection = Gtk.G_.selection(widget)
        function path_from_index(index)
            ind = join(index - 1, ":")
            ccall((:gtk_tree_path_new_from_string,Gtk.libgtk), GtkTreePath, (Ptr{Uint8}, ), bytestring(ind))
        end
        path = path_from_index(value)
        ccall((:gtk_tree_selection_select_path, Gtk.libgtk), Void,
              (Gtk.GtkTreeSelection, Gtk.GtkTreePath), selection, path)

    end

    ##

    ## connect widget to model
    ## selection changed, set model
    selection = Gtk.G_.selection(widget)
    signal_connect(selection, :changed) do sel
        ## XXX this function call is a hack to be addressed at Gtk level
        index = JGUI.gtk_jgui_tree_selected(widget)
        notify(store.model, "valueChanged", index)
        false
    end

    ## connect expand node event to model
    signal_connect(widget, :row_activated) do view, path, col
        ## XXX this function call is a hack to be addressed at Gtk level
        index = JGUI.gtk_jgui_tree_selected(widget)
        notify(model, "activated", index)
        false
    end

    ## connect expand node event to model
    signal_connect(widget, :row_expanded) do view, path, col
        ## XXX this function call is a hack to be addressed at Gtk level
        index = JGUI.gtk_jgui_tree_selected(widget)
        notify(model, "nodeExpand", index)
        false
    end


    signal_connect(widget, :row_collapsed) do view, path, col
        ## XXX this function call is a hack to be addressed at Gtk level
        index = JGUI.gtk_jgui_tree_selected(widget)
        notify(model, "nodeCollapse", index)
    end

    ## more issues?
    signal_connect(widget, :button_press_event) do widget, event
        ## look up path, column
        ## check state for double, single click
        ## notify
        if event.event_type in [Gtk.GdkEventType.GDK_2BUTTON_PRESS, Gtk.GdkEventType.GDK_BUTTON_PRESS]
            double = event.event_type == Gtk.GdkEventType.GDK_2BUTTON_PRESS
            signal = double ? "doubleClicked" : "clicked"
            index = JGUI.gtk_jgui_tree_selected(widget)
            column = 0          # XXX Get column!!!
            notify(model, signal, index, column)
        end
        false
    end

    
    
    (widget, block)
end

## Properties
function getNames(::MIME"application/x-gtk", tr::TreeView)
    tview = tr[:widget]
    n = length(tr.store)
    function get_name(i)
        col = Gtk.G_.column(tview, i)
        bytestring(Gtk.G_.title(col))
    end
    String[get_name(i) for i in 1:n]
end

function setNames{T<:String}(::MIME"application/x-gtk", tr::TreeView, nms::Vector{T})
    tview = tr[:widget]
    @assert length(tview.store) == length(names)
    for (i, nm) in enumerate(names)
        col = Gtk.G_.column(tview, i)
        Gtk.G_.title(col, nm)
    end

end

function getKeyname(::MIME"application/x-gtk", tr::TreeView)
    tview = tr[:widget]
    col = Gtk.G_.column(tview, 0)
    bytestring(Gtk.G_.title(col))
end
function setKeyname(::MIME"application/x-gtk", tr::TreeView, nm::String)
    tview = tr[:widget]
    col = Gtk.G_.column(tview, 0)
    Gtk.G_.title(col, nm)
end


## keywidth is first column
function getKeywidth(::MIME"application/x-gtk", tr::TreeView)
    tview = tr[:widget]
    col = Gtk.G_.column(tview, 0)
    Gtk.G_.width(col)
end
function setKeywidth(::MIME"application/x-gtk", tr::TreeView, width::Int)
    tview = tr[:widget]
    col = Gtk.G_.column(tview, 0)
    Gtk.G_.min_width(col, width)
end
function getWidths(::MIME"application/x-gtk", tr::TreeView)
    tview = tr[:widget]
    widths = Int[]
    for (i, width) in enumerate(widths)
        col = Gtk.G_.column(tview, i)
        push!(widths, Gtk.G_.width(col))
    end
    widths
end
function setWidths(::MIME"application/x-gtk", tr::TreeView, widths::Vector{Int})
    @assert length(tr.store) == length(widths)
    tview = tr[:widget]
    for (i, width) in enumerate(widths)
        col = Gtk.G_.column(tview, i)
        Gtk.G_.min_width(col, width)
    end

end
function getHeights(::MIME"application/x-gtk", tr::TreeView)
    "XXX"  ## height is only fixed or floating in gtk(???)
end
function setHeights(::MIME"application/x-gtk", tr::TreeView, heights::Vector{Int})
    "XXX"
end


function setIcon(::MIME"application/x-gtk", tr::TreeView, path::Vector{Int}, icon::Icon)
    tview = tr[:widget]
    XXX("Set icons")
    ## XXX  do I need a column in our gtkstore for icon?
end

## Images

## place to put a png image
function imageview(::MIME"application/x-gtk", parent::Container)
    widget = @GtkImage()
    (widget, widget)
end

function setImage(::MIME"application/x-gtk", o::ImageView, img::String)
    Gtk.G_.from_file(o[:widget], img)
end



##################################################
##
## Dialogs
## XXX Need to do these ... XXX
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
    widget = Gtk.@GtkMenuBar()
    Gtk.G_.hexpand(widget, true)
    push!(parent.block[1], widget)
    showall(parent.block[1])
    widget
end

## toplevel menu item
function menu(::MIME"application/x-gtk", parent::MenuBar, label)
    item = Gtk.@GtkMenuItem(label)
    mitem = Gtk.@GtkMenu(item)
    push!(parent[:widget], item)
    showall(parent[:widget])
    mitem
end

## submenu
function menu(::MIME"application/x-gtk", parent::Menu, label)
    item = @GtkMenuItem(label)
    mitem = @GtkMenu(item)
    push!(parent[:widget], item)
    showall(parent[:widget])
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
    item = @GtkMenuItem(action.label)
    if !isa(action.tooltip, Nothing) 
        Gtk.G_.tooltip_text(item, action.tooltip) 
    end
    signal_connect(item, :activate) do widget
        action.command()
    end
    
    push!(parent[:widget], item)
    showall(parent[:widget])
end

function addAction(::MIME"application/x-gtk", parent::Menu, value::Separator)
    push!(parent[:widget], Gtk.@SeparatorMenuItem())
    showall(parent[:widget])
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


function Display(::MIME"application/x-gtk", self::ManipulateObject, x::Mustache.MustacheTokens; context=nothing, kwargs...) 
    if isa(x, Nothing) return end
    oa = self.output_area
    
    if length(children(oa)) > 0 && isa(oa.children[1], TextEdit)
        te = oa.children[1]
    elseif length(children(oa)) > 0
        te = pop!(oa)
    else
        te = textedit(oa)
        te[:sizepolicy] = (:expand, :expand)
        push!(oa, te)
    end
    te[:value] = ""

    function add_tpl(tpl)
        ## how to show a mustache template
        for (t, l, b, e) in tpl.tokens
            if t == "text"
                push!(te, l)
            else ## if type == "name"
                ## look up and render accordingly
                obj = context.(symbol(l))
                if isa(obj, Winston.FramedPlot)
                    c = cairographic(oa)
                    display(c, obj)
                    push!(te, c)
                else
                    push!(te, string(obj))
                end
            end
        end
    end
    
    add_tpl(x)
end
