
## Icons
function get_icon(::MIME"application/x-tcltk", o::StockIcon)
    nm = "icon_" * string(o.theme) * "_" * string(o.nm)
    file = Pkg.dir("JGUI", "icons", string(o.theme), string(o.nm) * ".png")
    Tk.tcl("image", "create", "photo", nm, file=file)
    nm
end
function get_icon(::MIME"application/x-tcltk", o::FileIcon)
    nm = "icon_" * replace(basename(o.file), ".", "_")
    Tk.tcl("image", "create", "photo", nm, file=o.file)
    nm
end


## Widget methods
getEnabled(::MIME"application/x-tcltk", o::Widget) = Tk.get_enabled(getWidget(o))
setEnabled(::MIME"application/x-tcltk", o::Widget, value::Bool) = Tk.set_enabled(getWidget(o), value)
getVisible(::MIME"application/x-tcltk", o::Widget) = Tk.get_visible(getWidget(o))
setVisible(::MIME"application/x-tcltk", o::Widget, value::Bool) = Tk.set_visible(getWidget(o), value)
getSize(::MIME"application/x-tcltk", o::Widget)  = [Tk.width(getWidget(o)), Tk.height(getWidget(o))]
function setSize(::MIME"application/x-tcltk", o::Widget, value)  
    try
        Tk.set_size(o.block, value)
    catch e
        Tk.configure(o.block, width=value[1], height=value[2])
    end
end
getFocus(::MIME"application/x-tcltk", o::Widget) = nothing
setFocus(::MIME"application/x-tcltk", o::Widget, value::Bool) = value ? Tk.focus(getWidget(o)) : nothing
getWidget(::MIME"application/x-tcltk", o::Widget) = o.o
getContext(::MIME"application/x-tcltk", o::Widget) = o.attrs[:context]
setContext(::MIME"application/x-tcltk", o::Widget, ctx) = o.attrs[:context] = ctx

setSizepolicy(::MIME"application/x-tcltk", o::Widget, policies) =  o.attrs[:sizepolicy] = policies

## Containers

## Window
function window(::MIME"application/x-tcltk"; kwargs...)
    widget = Tk.Toplevel()
    block = Frame(widget)
    pack(block, expand=true, fill="both")
    (widget, block)
end
## widget is all messed up, need to use block when it is a parent
getWidget(::MIME"application/x-tcltk", o::Window) = o.block


### window methods
raise(::MIME"application/x-tcltk", o::Window) = Tk.raise(o.o)
lower(::MIME"application/x-tcltk", o::Window) = tcl("lower", o.o)
destroy_window(::MIME"application/x-tcltk", o::Window) = tcl("destroy", o.o)


### window properties
function setSize(::MIME"application/x-tcltk", o::Window, sz::Vector{Int}) 
    Tk.pack_stop_propagate(o.o)
    Tk.configure(o.o, width=sz[1], height=sz[2])
end
getTitle(::MIME"application/x-tcltk", o::Window) = Tk.wm(o.o, "title")
setTitle(::MIME"application/x-tcltk", o::Window, value::String) = Tk.wm(o.o, "title", Tk.tk_string_escape(value))
getPosition(::MIME"application/x-tcltk", o::Window) = [int(Tk.winfo(o[:widget], prop)) for prop in ["rootx", "rooty"]]
function setPosition(::MIME"application/x-tcltk", o::Window, value::Vector{Int}) 
    toplevel = Tk.winfo(o[:widget], "toplevel")
    x, y = value[1:2]
    Tk.wm(toplevel, "geometry", "+$x+$y")
end


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


## for BinContainer, only one child we pack and expand...
function set_child(::MIME"application/x-tcltk", parent::BinContainer, child::Widget)
    Tk.pack(child.block, expand=true, fill="both")
end

## Label frame
function labelframe(::MIME"application/x-tcltk", parent::BinContainer, label::String, alignment::Union(Nothing, Symbol)=nothing)
    widget = Tk.Labelframe(getWidget(parent), string(label))
    if isa(alignment, Symbol)
        Tk.configure(widget, labelanchor=(alignment==:left ? "nw" : alignment==:center ? "n" : alignment==:right ? "ne" : "n"))
    end
    (widget, widget)
end
function boxcontainer(::MIME"application/x-tcltk", parent::Container, direction)
    widget = Tk.Frame(getWidget(parent))
    (widget, widget)
end

## set padx, pady for all the children
function setSpacing(::MIME"application/x-tcltk", parent::BoxContainer, px::Vector{Int})
    children= split(Tk.winfo(parent[:widget], "children"))
    [Tk.tcl("pack", "configure", child, padx=px[1], pady=px[2]) for child in children]
end

function setMargin(::MIME"application/x-tcltk", parent::BoxContainer, px::Vector{Int})
    Tk.configure(parent[:widget], padding=[px[1], px[2], px[1], px[2]])
end

## XXX implement
function addstrut(::MIME"application/x-tcltk", parent::BoxContainer, px::Int) 
    label = Tk.Label(parent[:widget], " ")
    parent[:direction] == :vertical ? Tk.configure(label, width=px) : Tk.configure(label, height=px)
    Tk.pack(label)
end

function addstretch(::MIME"application/x-tcltk", parent::BoxContainer, stretch::Int)
    label = Tk.Label(parent[:widget])
    Tk.pack(label, expand=true, fill= parent[:direction] == :vertical ? "y" : "x")
end
function addspacing(::MIME"application/x-tcltk", parent::BoxContainer, spacing::Int) 
    label = Tk.Label(parent[:widget], " ")
    parent[:direction] == :vertical ? Tk.configure(label, width=px) : Tk.configure(label, height=px)
    Tk.pack(label)
end
 


function compute_anchor(child::Widget)
    ## (:left, :right, :center, :justify), (:top, :bottom, :center) -> "news"
    d = {:left=>"w", :right=>"e", :center=>"", :justify=>"", :top=>"n", :bottom=>"s", nothing=>""}
    (x, y) = child[:alignment]
    anchor = d[y] * d[x]
    anchor
end
    
function compute_expand_fill_anchor(parent::BoxContainer, child::Widget) 

    anchor = compute_anchor(child)

    policy = child[:sizepolicy]
    side = getProp(parent, :direction)

    if anchor == "" && policy[1] == nothing
        policy = (side == :horizontal ? :fixed : :expand, policy[2])
    end
    if anchor == "" && policy[2] == nothing
        policy = (policy[1], side == :horizontal ? :expand : :fixed)
    end
    
    
    if policy == (:expand, :expand)
        expand=true; fill="both"
    elseif policy == (:expand, :fixed)
        expand=true; fill = "x"
    elseif policy == (:fixed, :expand)
        expand=true; fill = "y"
    else
        expand=false; fill="none"
    end
   

    expand, fill, anchor == "" ? "center" : anchor
end




function insert_child(::MIME"application/x-tcltk", parent::BoxContainer, index, child::Widget)
    slaves = split(Tk.tcl("pack", "slaves", getWidget(parent)))
    side = (getProp(parent, :direction) == :horizontal) ? "left" : "top"
    expand, fill, anchor =  compute_expand_fill_anchor(parent, child) 
    spacing = parent.attrs[:spacing]

    ## println(("Debug", expand, fill, anchor))

    if length(slaves) == 0
        Tk.pack(child.block,                                   side=side, expand=expand, fill=fill, anchor=anchor, 
                padx=spacing[1], pady=spacing[2]) 
    elseif index <= length(slaves)
        slave = slaves[index]
        Tk.tcl("pack", "configure", child.block, before=slave, side=side, expand=expand, fill=fill, anchor=anchor,
               padx=spacing[1], pady=spacing[2]) 
    else
        slave = slaves[end]
        Tk.tcl("pack", "configure", child.block, after=slave,  side=side, expand=expand, fill=fill, anchor=anchor,
               padx=spacing[1], pady=spacing[2]) 
    end
end


function remove_child(::MIME"application/x-tcltk", parent::Container, child::Widget)
    Tk.forget(child.block)
end

## make a grid
function grid(::MIME"application/x-tcltk", parent::Container)
    widget = Tk.Frame(getWidget(parent))
    (widget, widget)
end

## size of grid
function grid_size(::MIME"application/x-tcltk", widget::GridContainer)
     map(parseint, split(tcl("grid", "size", getWidget(widget))))
end

## grid spacing
function setSpacing(::MIME"application/x-tcltk", parent::GridContainer, px::Vector{Int})
    children= split(Tk.winfo(parent[:widget], "children"))
    [Tk.tcl("grid", "configure", child, padx=px[1], pady=px[2]) for child in children]
end



function compute_sticky(child::Widget)
    spx, spy = child[:sizepolicy]
    ax, ay = child[:alignment]
    d = {:left=>"w", :right=>"e", :center=>"", :justify=>"", :top=>"n", :bottom=>"s", nothing=>""}
    

    sticky = ASCIIString[]
    if spx == :expand
        append!(sticky, ["e","w"])
    end
    if spy == :expand
        append!(sticky, ["n", "s"])
    end
    append!(sticky, [d[ax], d[ay]])
    filter!(x -> x != "", sticky)
    join(sticky)
end


## Need to do something to configure rows and columns
## grid add child
function grid_add_child(::MIME"application/x-tcltk", parent::GridContainer, child::Widget, i, j)
    sticky = compute_sticky(child)
    Tk.grid(child.block, i, j, sticky= (sticky == "" ? "{}" : sticky))
end

## not too efficient, must match children in vector to child found using array notation given as Tk.id
function grid_get_child_at(::MIME"application/x-tcltk", parent::GridContainer, i::Int, j::Int)
    id = Tk.tcl("grid", "slaves", getWidget(parent), row=i-1, column=j-1)
    if id == ""
        return nothing
    end

    child = filter(child -> Tk.get_path(child.block) == id, children(parent))
    length(child) == 1 ? child[1] : nothing
end

column_minimum_width(::MIME"application/x-tcltk", object::GridContainer, j::Int, width::Int) = Tk.tcl("grid", "columnconfigure", getWidget(object), j-1, minsize=width)
row_minimum_height(::MIME"application/x-tcltk", object::GridContainer, j::Int, height::Int)= Tk.tcl("grid", "rowconfigure", getWidget(object), i-1, minsize=height)
column_stretch(::MIME"application/x-tcltk", object::GridContainer, j::Int, weight::Int) = Tk.tcl("grid", "columnconfigure", getWidget(object), j-1, weight=weight)
row_stretch(::MIME"application/x-tcltk", object::GridContainer, i::Int, weight::Int)= Tk.tcl("grid", "rowconfigure", getWidget(object), i-1, weight=weight)
##################################################

function formlayout(::MIME"application/x-tcltk", parent::Container)
    widget = Frame(getWidget(parent))
    (widget, widget)
end

function formlayout_add_child(::MIME"application/x-tcltk", parent::FormLayout, child::Widget, label::Union(Nothing, String))
    Tk.formlayout(child.block, label)
end

function setSpacing(::MIME"application/x-tcltk", object::FormLayout, px::Vector{Int})
    children= split(Tk.winfo(parent[:widget], "children"))
    [Tk.tcl("grid", "configure", child, padx=px[1], pady=px[2]) for child in children]
end

## Notebook
function notebook(::MIME"application/x-tcltk", parent::Container, model::Model)
    widget = Tk.Notebook(getWidget(parent))
    connect(model, "valueChanged", widget, Tk.set_value)
    bind(widget, "<<NotebookTabChanged>>") do path
        tab = Tk.tcl(widget, "index", "current") |> parseint |> x -> x+1
        setValue(model, tab)
    end
    (widget, widget)
end

function notebook_insert_child(::MIME"application/x-tcltk", parent::NoteBook, child::Widget, i::Int, label::String)
    i = i > length(parent) ? "end" : i-1
    Tk.tcl(getWidget(parent), "insert", i, child.o, text="{$label}")
end

function notebook_remove_child(::MIME"application/x-tcltk", parent::NoteBook, child::Widget)
    index = collect(Filter(i -> parent[i] == child, 1:length(parent)))[1]
    if index != 0
        Tk.tcl(getWidget(parent), "forget", index-1)
    end
end

##################################################
## Widgets
function label(::MIME"application/x-tcltk", parent::Container, model::Model)
    widget = Tk.Label(getWidget(parent), string(getValue(model)))
    connect(model, "valueChanged", widget, (widget, value) -> Tk.set_value(widget, string(value)))

    (widget, widget)
end
setValue(::MIME"application/x-tcltk",obj::Label, value::Number) = setValue(obj, string(value))

## separator
function separator(::MIME"application/x-tcltk", parent::Container; orientation::Symbol=:horizontal)
    widget = Tk.Separator(getWidget(parent), orientation == :horizontal)
    (widget, widget)
end

## Controles
function button(::MIME"application/x-tcltk", parent::Container, model::Model)
    
    widget = Tk.Button(getWidget(parent), getValue(model))
    connect(model, "valueChanged", widget, Tk.set_value)

    bind(widget, "command", (path) -> notify(model, "clicked"))

    (widget, widget)
end

## XXX remove icon... 

function setIcon(::MIME"application/x-tcltk", widget::Button, icon::Union(Nothing, Icon); kwargs...)
    if isa(icon, Nothing)
        Tk.configure(widget[:widget], compound="text")
    else

        if isa(icon.theme, Nothing) 
            icon.theme = widget[:icontheme]
        end
        nm = get_icon(widget.toolkit, icon)
        ## scale...
        Tk.configure(widget[:widget], image=nm, compound="left")
    end
end
    

function lineedit(::MIME"application/x-tcltk", parent::Container, model::Model)
    
    widget = Tk.Entry(getWidget(parent), getValue(model))
    placeholdertext = [""]


    connect(model, "valueChanged") do value
        Tk.configure(widget, foreground="black")
        Tk.set_value(widget, string(value))
    end
    
    ## SIgnals: keyrelease (keycode), activated (value), focusIn, focusOut, textChanged
    bind(widget, "<Return>", (path) -> notify(model, "editingFinished", getValue(model)))
    bind(widget, "<FocusOut>") do path
        if length(model.value) == 0 && length(placeholdertext[1]) > 0
            Tk.tcl(widget, "delete", "@0", "end")
            Tk.tcl(widget, "insert", "@0", Tk.tk_string_escape(placeholdertext[1]))
            Tk.configure(widget, foreground="gray")
        end
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
    end
    bind(widget, "<FocusIn>") do path
        if model.value == ""
            Tk.tcl(widget, "delete", "@0", "end")
            Tk.tcl(widget, "insert", "@0", "{}")
            Tk.configure(widget, foreground="black") # theme dependent?
        end
        notify(model, "focusIn")
    end
    bind(widget, "<KeyRelease>") do path, W, A
        setValue(model, tcl(widget, "get")) # calls valueChanged
        notify(model, "textChanged", A)
    end
    bind(widget, "<Button-1>") do path
        notify(model, "clicked")
    end
    connect(model, "placeholderTextChanged") do txt
        placeholdertext[1] = txt
        Tk.tcl("event", "generate", widget,  "<FocusOut>")
    end


    (widget, widget)
end

## XXX implement
setTypeahead(::MIME"application/x-tcltk", obj::LineEdit, items) = nothing


function textedit(::MIME"application/x-tcltk", parent::Container, model::Model)
    
    block = Tk.Frame(getWidget(parent))
    widget = Tk.Text(block)
    Tk.scrollbars_add(block, widget)

    Tk.set_value(widget, getValue(model))

    connect(model, "valueChanged", widget, Tk.set_value)

    ## Signals: valueChanged, editingFinished, focusIn, focusOut, textChanged
    bind(widget, "<FocusIn>") do path
        notify(model, "focusIn")
    end
    bind(widget, "<FocusOut>") do path
        notify(model, "focusOut", getValue(model))
        notify(model, "editingFinished", getValue(model))
    end
    bind(widget, "<KeyRelease>") do path, W, A
        setValue(model, Tk.get_value(widget))  # calls valueChanged
        notify(model, "textChanged", A)
    end

    (widget, block)
end

## push! text onto widget -- without updating model
function push!(::MIME"application/x-tcltk", text_widget::TextEdit, value::String)
    widget = text_widget[:widget]
    tcl(widget, "insert", "end", join(value, "\n"))
end

## push! graphic onto widget
function push!(::MIME"application/x-tcltk",text_widget::TextEdit, value::CairoGraphics)
    widget = text_widget[:widget]
    tcl(widget, "window", "create", "end", window=value[:widget], align="top")
    tcl(widget, "insert", "end", "\n")
end
    

## checkbox
function checkbox(::MIME"application/x-tcltk", parent::Container, model::Model, label::Union(Nothing, String))
    widget = Tk.Checkbutton(getWidget(parent), isa(label, Nothing) ? "" : label)
    set_value(widget, model.value)
    connect(model, "valueChanged", widget, Tk.set_value)
    bind(widget, "command") do path
        setValue(model, get_value(widget))
    end
    (widget, widget)
end
getLabel(::MIME"application/x-tcltk", o::CheckBox) = string(Tk.cget(getWidget(o), "text"))
setLabel(::MIME"application/x-tcltk", o::CheckBox, value::String) =Tk.configure(getWidget(o), text=Tk.tk_string_escape(value))


## radiogroup

function radiogroup(::MIME"application/x-tcltk", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    widget = Tk.Radio(getWidget(parent), getItems(model), orientation == :horizontal ? "horizontal" : "vertical")

    connect(model, "valueChanged", widget, Tk.set_value)
    bind(widget, "command") do path
        value = Tk.get_value(widget)
        setValue(model, value)  # valueChanged
    end
    (widget, widget)
end

## buttongroup
function buttongroup(::MIME"application/x-tcltk", parent::Container, model::VectorModel; exclusive::Bool=true)
    ## pack buttons into box, exclusive or not
    widget = Tk.Frame(getWidget(parent))
    function add_button(val)
        b = Tk.Button(widget, val)
        Tk.configure(b, style="Toolbutton")
        Tk.pack(b, side="left")
        b
    end
    btns = [val=>add_button(val) for val in getItems(model)]
    ## set intial value
    if !isa(model.value, Nothing)
        map(val -> Tk.set_enabled(btns[val], false), model.value)
    end

    if exclusive
        function click_handler(path, W)
            val = Tk.cget(W, "text")
            if val == model.value
                return
            end
            for (k, v) in btns
                Tk.set_enabled(btns[k], k != val)
            end
            setValue(model, val)
        end
    else
        function click_handler(path, W)
            val = Tk.cget(W, "text")
            Tk.set_enabled(btns[val], !Tk.get_enabled(btns[val]))
            vals = filter(val -> !Tk.get_enabled(btns[val]), [k for (k,v) in btns])
            setValue(model, vals)
        end
    end
    for (k,v) in btns
        Tk.bind(v, "<ButtonRelease>", click_handler)
    end

    (widget, widget)
end


## 
function combobox(::MIME"application/x-tcltk", parent::Container, model::VectorModel; editable::Bool=false)
    widget = Tk.Combobox(getWidget(parent), getItems(model))
    
    if editable
        error("Need to implement editable")
    end
    
    if !isa(getValue(model), Nothing)
        Tk.set_value(widget, getValue(model))
    end

    function new_items(items, old_items)
        Tk.set_items(widget, items)
    end

    connect(model, "valueChanged", widget, Tk.set_value)
    connect(model, "itemsChanged", new_items)

    bind(widget, "<<ComboboxSelected>>") do path
        value = Tk.get_value(widget)
        setValue(model, value)  # valueChanged
    end
    (widget, widget)
end

## slider
## model stores value, slider is in 1:n
function slider(::MIME"application/x-tcltk", parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    items = model.items
    initial = model.value
    n = length(items)
    orient = orientation == :horizontal ? "horizontal" : "vertical"
    widget = Tk.Slider(getWidget(parent), 1, n, orient=orient)
    
    connect(model, "valueChanged") do value
        ## have to find index from items
        i = indmin(abs(items - value))
        Tk.set_value(widget, i)
    end

    ## throttle requests
    ms = 50 #100
    ids = Any[]
    function callback(path, xs...)
        while length(ids) > 0
            id = pop!(ids)
            Tk.tcl("after", "cancel", id)
        end
        ## add this one
        push!(ids, Tk.tcl("after", ms, function(args...)
            value = int(Tk.get_value(widget))
            setValue(model, items[value])
        end))
    end
    bind(widget, "command", callback)

    (widget, widget)
end


## slider2d
type TkSlider2D <: Tk.Tk_Widget
    w
    lastpos::Vector{Int}
    moving::Bool
    range1::Vector
    range2::Vector
    cnv
    callback::Union(Nothing, Function)
end

function slider2d(::MIME"application/x-tcltk", parent::Container, model::TwoDSliderModel)
    fr = Tk.Frame(getWidget(parent))
    cnv = TkCanvas(fr)
    cnv[:width] = 100; cnv[:height] = 100
    pack(cnv, side="left")

    r = 5
    xline = tcl(cnv, "create", "line", 0, 50, 100, 50)
    yline = tcl(cnv, "create", "line", 50, 0, 50, 100)
    item = tcl(cnv, "create", "oval", 50 - r, 50-r, 50+r, 50+4, width=1, outline="black", fill="black")

    self = TkSlider2D(fr, [50,50], false, model.items1, model.items2, cnv, nothing)

    
    tcl(cnv, "addtag", "xline", "withtag", xline)
    tcl(cnv, "addtag", "yline", "withtag", yline)
    tcl(cnv, "addtag", "point", "withtag", item)

    function tag_selected(path, W, x, y)
        tcl(W, "addtag", "selected", "withtag", "current")
        tcl(W, "raise", "current")
        self.moving = true
        self.lastpos[:] = map(parseint, [x,y])
    end
    
    function move_selected(path, W, x, y)
        pos = map(parseint, [x,y])
        if self.moving && 5 < pos[1] < 95 && 5 < pos[2] < 95
            tcl(W, "move", "xline",    0,                        pos[2] - self.lastpos[2])
            tcl(W, "move", "yline",    pos[1] - self.lastpos[1], 0)
            tcl(W, "move", "selected", pos[1] - self.lastpos[1], pos[2] - self.lastpos[2])
            self.lastpos[:] = pos
        end
    end
    
    
    function release_selected (path, W, x, y) 
        tcl(W, "dtag", "selected")
        pos = map(parseint, [x, y])
        pos = [a < 5 ? 5 : (a > 95 ? 95 : a) for a in pos]
        self.lastpos[:] = pos
        self.moving = false

        notify(model, "valueChanged", getValue(self))
        setValue(model, self.lastpos)
    end

    tcl(cnv, "bind", "point", "<Button-1>", tag_selected)
    bind(cnv, "<B1-Motion>", move_selected)
    bind(cnv, "<ButtonRelease-1>", release_selected)
    
    ## return widget block
    (self, fr)
end

getValue(::MIME"application/x-tcltk", widget::Slider2D) = getValue(getWidget(widget))
function getValue(widget::TkSlider2D)
    x, y = widget.lastpos
    y = 100 - y

    i = max(1, iceil((x - 5) / (90/length(widget.range1))))
    j = max(1, iceil((y - 5) / (90/length(widget.range2))))

    [widget.range1[i], widget.range2[j]]
end

setValue(::MIME"application/x-tcltk", widget::Slider2D, value)  = setValue(getWidget(widget), value)
function setValue{T <: Real}(widget::TkSlider2D, value::Vector{T})
    ix = indmin(abs((widget.range1) - value[1]))
    iy = indmin(abs((widget.range2) - (max(widget.range2) - value[2])))

    ixx = iceil(5 + 90 * ix /length(widget.range1))
    iyy = iceil(5 + 90 * iy /length(widget.range2))

    x, y = widget.lastpos

    ## move by ixx - x, iyy - y
    cnv = widget.cnv
    Tk.tcl(cnv, "move", "xline",  0      , iyy - y)
    Tk.tcl(cnv, "move", "yline",  ixx - x, 0)
    Tk.tcl(cnv, "move", "point" ,  ixx - x, iyy - y)

    widget.lastpos = [ixx, iyy]
    nothing
    
end

## spinbox
function spinbox(::MIME"application/x-tcltk", parent::Container, model::ItemModel, rng::Range)
    widget = Tk.Spinbox(parent[:widget])
    ## work around integer values in Tk.Spinbox
    step = !isa(rng, UnitRange) ? 1 : step(rng)
    Tk.configure(widget, from=first(rng), to=first(rng) + (length(rng)-1)*step, increment=step)
    Tk.tcl(widget, "set", first(rng))

    connect(model, "valueChanged") do value
        value = isa(first(rng), Integer) ? int(value) : value
        Tk.tcl(widget, "set", value)
    end

    function handler(path) 
        value = parsefloat(tcl(widget, "get"))
        value = isa(first(rng), Integer) ? int(value) : value
        setValue(model, value)
    end
    bind(widget, "command", handler)
    bind(widget, "<Return>", handler)

    (widget, widget)
end


## cairographic
function cairographic(::MIME"application/x-tcltk", parent::Container, model::EventModel; width::Int=480, height::Int=400)
    block = Frame(getWidget(parent))
    widget = c = Tk.Canvas(block, width, height)
    pack(widget, expand=true, fill="both")

    ## can't put signal on canvas Map...
    bind(block, "<Map>", (path) -> notify(model, "realized"))

    ## mousebindings ...
    bind(c, "<ButtonPress-1>",   (path,x,y)->notify(model, "mousePress", x, y))
    bind(c, "<ButtonRelease-1>", (path,x,y)->notify(model, "mouseRelease", x, y))
    bind(c, "<Double-Button-1>", (path,x,y)->notify(model, "mouseDoubleClick", x, y))
    bind(c, "<KeyPress>",        (path, A) ->notify(model, "keyPress", A))
    bind(c, "<KeyRelease>",      (path, A) ->notify(model, "keyRelease", A))
    # The cursor is in motion over a widget
    bind(c, "<Motion>",          (path,x,y)->notify(model, "mouseMotion", x, y)) # name?
    bind(c, "<Button1-Motion>",  (path,x,y)->notify(model, "mouseMove", x, y))
    ##
    (widget, block)
end

function menu(::MIME"application/x-tcltk", parent::CairoGraphics)
    m = Tk.Menu(parent.block)
    ## tk_popup code here
    function handler(path, X, Y, x, y)
        parent[:context] = [int(x), int(y)]
        tcl("tk_popup", m, X, Y)
    end
        
    if OS_NAME == :Darwin
        Tk.bind(parent[:widget].c.path, "<Button-2>", handler)
    end
    Tk.bind(parent[:widget].c.path, "<Control-Button-1>", handler)

    m
end


## Views
## storeview
function storeview(::MIME"application/x-tcltk", parent::Container, store::Store, model::ItemModel; tpl=nothing)
    ## Widget
    block = Tk.Frame(getWidget(parent))
    widget = Tk.Treeview(block)
    Tk.scrollbars_add(block, widget)

    ## Configure based on store
    if isa(tpl, Nothing)
        tpl = store.items[1]
    end
    nms = map(string, names(tpl))
    configure(widget, show="headings", columns = [1:length(nms)])
    ## headers, initial widths
    map(1:length(nms)) do i
        Tk.tcl(widget, "heading", i, 
               text=Tk.tk_string_escape(string(nms[i])), 
               command=(path) -> notify(model, "headerClicked", i))
        Tk.tcl(widget, "column", i, width=100) # initial size, not 200
    end

    Tk.tcl(widget, "column", length(nms), stretch=true)

    ## main callbacks
    function insert_row(i::Int, item)
        values = composite_instance_to_values(item)
        tcl(widget, "insert", "{}", i-1, values=values)
    end
    connect(store.model, "rowInserted", i -> insert_row(i, store.items[i]))

    function remove_row(i::Int)
        item = split(Tk.tcl(widget, "children", "{}"))[i]
        Tk.tcl(widget, "delete", item)
    end
    connect(store.model, "rowRemoved", remove_row)
    

    function update_row(i::Int)
        item = store.items[i]
        row = split(Tk.tcl(widget, "children", "{}"))[i]
        values = composite_instance_to_values(item)
        tcl(widget, "item", row, values=values)
    end
    connect(store.model, "rowUpdated", update_row)
    ## connect clicks to model...
    function selected_nodes()
        sel = tcl(widget, "selection")
        if length(sel) == 0
           return(nothing)      # 0?
        end
        selected = split(sel)
        all_nodes = split(tcl(widget, "children", "{}"))
        findin(all_nodes, selected)
    end

    ## TreeviewSelect signal
    bind(widget, "<<TreeviewSelect>>") do path
        sel = selected_nodes()
        setValue(model, sel)
        notify(model, "selectionChanged", model[:value])
    end


    ## update selection if model changesq
    function select_nodes(inds::Vector{Int})
        nodes = split(Tk.tcl(widget, "children", "{}"))[inds]
        Tk.tcl(widget, "selection", "set", nodes)
    end
    select_nodes(i::Int) = select_nodes([i])
    connect(model, "valueChanged", select_nodes)
    ## 
    function find_row_col(W, x, y)
        col = Tk.tcl(W,"identify", "column", x, y)  #   "#3"
        row = Tk.tcl(W,"identify", "row", x, y)     #   "I002"

        col = parseint(col[2:end])
        row = findfirst(split(Tk.tcl(W, "children", "{}")), row)
        (row, col)
    end
    
    Tk.bind(widget, "<Button-1>") do path, W, x, y
        (row, col) = find_row_col(W, x, y)
        notify(model, "clicked", row, col)
    end
    Tk.bind(widget, "<Double-Button-1>") do path, W, x, y
        (row, col) = find_row_col(W, x, y)
        notify(model, "doubleClicked", row, col)
    end

    ## arrow navigation when widget has focus


    ## insert initial rows
    for i in 1:length(store.items)
        item = store.items[i]
        insert_row(i, item)
    end


    

    (widget, block)
end

## context menu
function menu(::MIME"application/x-tcltk", parent::StoreView)
    m = Tk.Menu(parent[:widget])

    function find_row_col(W, x, y)
        col = Tk.tcl(W,"identify", "column", x, y)  #   "#3"
        row = Tk.tcl(W,"identify", "row", x, y)     #   "I002"
        
        col = parseint(col[2:end])
        row = findfirst(split(Tk.tcl(W, "children", "{}")), row)
        (row, col)
    end
    
    ## tk_popup code here
    function handler(path, W, X, Y, x, y)
        parent[:context] = find_row_col(W, x, y)
        tcl("tk_popup", m, X, Y)
    end
        
    if OS_NAME == :Darwin
        Tk.bind(parent[:widget], "<Button-2>", handler)
    end
    Tk.bind(parent[:widget], "<Control-Button-1>", handler)

    m
end


function getSelectmode(::MIME"application/x-tcltk", s::ModelView) 
    val = Tk.cget(s.o, "selectmode")
    {"browse" => :single, "extended" => :multiple}[val]
end
## val is single, multiple
function setSelectmode(::MIME"application/x-tcltk", s::ModelView, val::Symbol)
    val = {:single => "browse", :multiple => "extended"}[val]
    Tk.configure(s.o, selectmode=val)
end

## This needs to be generalized
#function setSize(::MIME"application/x-tcltk", s::StoreView, value)
#    Tk.configure(s.block, width=value[1], height=value[2])
#end

## getWidths
function getWidths(::MIME"application/x-tcltk", s::ModelView)
    get_width(i) = parseint(Tk.tcl(s.o, "column", i, "-width"))
    ncols = Tk.cget(s.o, "columns") |> parseint
    Int[get_width(i) for i in 1:ncols]
end
function setWidths(::MIME"application/x-tcltk", s::ModelView, widths::Vector{Int})
    for i in 1:length(widths)
        Tk.tcl(s.o, "column", i, width=widths[i])
    end
end
## XXX set these?
getHeights(::MIME"application/x-tcltk", s::ModelView) = nothing
setHeights(::MIME"application/x-tcltk", s::ModelView, heights::Vector{Int}) = nothing


function getHeadervisible(::MIME"application/x-tcltk", s::StoreView)
    true
end
function setHeadervisible(::MIME"application/x-tcltk", s::StoreView, val::Bool)
    if !val
        println("Can't hide header")
    end
end

function getRownamesvisible(::MIME"application/x-tcltk", s::StoreView)
    true
end
function setRownamesvisible(::MIME"application/x-tcltk", s::StoreView, val::Bool)
end

function setIcon(::MIME"application/x-tcltk", s::StoreView, i::Int, icon::Icon)
    widget = s.o
    item = split(Tk.tcl(widget, "children", "{}"))[i]
    Tk.tcl(widget, "item", item, image=get_icon(s.toolkit, icon))
    Tk.tcl(widget, "column", "#0", width=40)
    Tk.configure(widget, show="tree headings")
end

##################################################
## Tree view
## tpl: a template for the type, otherwise from tr.children[1]
function treeview(::MIME"application/x-tcltk", parent::Container, store::TreeStore, model::ItemModel; tpl=nothing)
    block = Tk.Frame(getWidget(parent))
    widget = Tk.Treeview(block)
    scrollbars_add(block, widget)
    
    ## add headers from type, connect header click
    if isa(tpl, Nothing)
        tpl = store.children[1]
    end
    nms = map(string, names(tpl.data))
    configure(widget, show="tree headings", columns = [1:length(nms)])
    ## headers
    map(i -> tcl(widget, "heading", i, 
                 text=Tk.tk_string_escape(string(nms[i])), 
                 command=(path) -> notify(model, "headerClicked", i)),
        1:length(nms))
    Tk.tcl(widget, "column", length(nms), stretch=true)

    ## connect to model
    ## insertNode, removeNode, updatedNode, expandNode, collapseNode
    function insertNode(parent, i, child)
        index = isa(parent, Union(TreeStore, Nothing)) ? "{}" : parent.index
        if isa(child.data, Nothing)
            index = Tk.tcl(widget, "insert", index, i, text=child.text)
        else
            index = Tk.tcl(widget, "insert", index, i, text=child.text, values=node_to_values(child))
        end
        child.index = index     # can I look this up? Can get index from item, but item from index?
    end
    connect(store.model, "insertNode", insertNode)

    connect(store.model, "removeNode") do parent, i
        child = parent.children[i]
        Tk.tcl(widget, "detach", child.index)
    end
    connect(store.model, "updatedNode") do node
        if isa(node.data, Nothing)
            Tk.tcl(widget, "item", node.index, text=node.text, values = node_to_values(node))
        else
            Tk.tcl(widget, "item", node.index, text=node.text)
        end
    end
    connect(model, "expandNode") do node
        Tk.tcl(widget, "item", node.index, open=true)
    end
    connect(model, "collapseNode") do node
        Tk.tcl(widget, "item", node.index, open=false)
    end
    ## movenode?


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


    ## signal changes back to model
    tk_selected_items() = split(Tk.tcl(widget, "selection"))
    function tk_xy_to_path(x, y)
        col = Tk.tcl(widget, "identify", "column", x, y)
        col = parseint(col[2:end]) + 1 # strip off #
        item = Tk.tcl(widget, "identify", "item", x, y)
        item == "" && error("no item at x, y")

        (tk_item_to_path(widget, item), col)
    end

    bind(widget, "<<TreeviewSelect>>") do path
        sel_items = tk_selected_items()
        paths = map(item -> tk_item_to_path(widget, item), sel_items)
        setValue(model, paths)
    end
    bind(widget, "<<TreeviewOpen>>") do path
        item = Tk.tcl(widget, "focus")
        path = tk_item_to_path(widget, item)
        notify(model, "nodeExpanded", path)
    end
    bind(widget, "<<TreeviewClose>>") do path
        item = Tk.tcl(widget, "focus")
        path = tk_item_to_path(widget, item)
        notify(model, "nodeCollapsed", path)
    end
    bind(widget, "<Button-1>") do path,  x, y
        try
            item, column = tk_xy_to_path(x, y)
            notify(model, "clicked", path, column)
        catch e
        end
    end
    bind(widget, "<Double-Button-1>") do path, x, y
        try
            item, column = tk_xy_to_path(x, y)
            notify(model, "doubleClicked", path, column)
        catch e
        end
    end
    
    (widget, block)
end

function tk_item_to_path(widget, item)
    path = [parseint(Tk.tcl(widget, "index", item)) + 1]
    parent = Tk.tcl(widget, "parent", item)
    while parent != ""
            unshift!(path, parseint(Tk.tcl(widget, "index", parent)) + 1)
        parent = Tk.tcl(widget, "parent", parent)
    end
    path
end

## path --> item
function tk_path_to_item(widget, path::Vector{Int})
    ## Is there no better way then to list all children
    item = "{}"
    while length(path) > 0
        i = shift!(path)
        item = split(Tk.tcl(widget, "children", item))[i]
    end
    item
end
## Properties
function getKeywidth(::MIME"application/x-tcltk", tr::TreeView)
    parseint(Tk.tcl(tr.o, "column", "#0", "-width"))
end
function setKeywidth(::MIME"application/x-tcltk", tr::TreeView, width::Int)
    Tk.tcl(tr.o, "column", "#0", width=width)
end
    


function setIcon(::MIME"application/x-tcltk", s::TreeView, path::Vector{Int}, icon::Icon)
    widget = s.o
    item = tk_path_to_item(widget, path)
    Tk.tcl(widget, "item", item, image=get_icon(s.toolkit, icon), text=txt)
end

## Images
# function imageview(::MIME"application/x-tcltk", parent::Container, model::EventModel, img)

#     d, w, h = size(img)
#     block = Tk.Frame(parent[:widget])
#     widget = Tk.Canvas(block, w, h)
#     pack(widget, expand=true, fill="both")

#     bind(block, "<Map>") do path
#         notify(model, "realized") 
#     end


#     ## Do I have any signals?
#     bind(widget, "<ButtonPress-1>",   (path,x,y)->notify(model, "mousePress", x, y))
#     bind(widget, "<ButtonRelease-1>", (path,x,y)->notify(model, "mouseRelease", x, y))
#     bind(widget, "<Double-Button-1>", (path,x,y)->notify(model, "mouseDoubleClick", x, y))

   

#     (widget, block)
# end
# function image_draw(::MIME"application/x-tcltk", o::ImageView, img::Image)
#     buf = uint32color(img)'
#     ctx = Base.Graphics.getgc(o[:widget])
#     d, w, h = size(img)
#     Tk.configure(o.block, width=w, height=h)
#     image(ctx, buf, 0, 0, w, h)
#     Tk.reveal(o[:widget])
# end

## place to put a png image
function imageview(::MIME"application/x-tcltk", parent::Container)
    widget = block = Tk.Label(parent[:widget], "")
    Tk.configure(widget, compound="image")
    (widget, block)
end

function setImage(o::ImageView, img::String)
    nm = get_icon(o.toolkit. o, FileIcon(img))
    Tk.tcl("image", "create", "photo", nm, file=img)
    Tk.configure(o[:widget], image=nm, compound="image")
end



##################################################
##
## Dialogs

## modeless dialog
##
function dialog(::MIME"application/x-tcltk", parent::Widget, model;
                buttons::Vector{Symbol}=[:ok],
                default::Union(Symbol, Nothing)=nothing,
                title::String="")
    
    window = Tk.Toplevel()
    Tk.wm(window, "withdraw")

    ## parent, title, 

    outer = Frame(window)
    pack(outer, expand=true, fill="both")

    frame = Tk.Frame(outer)
    sep = Tk.Separator(outer, orient=:horizontal)
    bbox = Tk.Frame(outer)

    Tk.grid(frame, 1, 1, sticky="news")
    Tk.grid(sep, 2, 1, sticky="ew")
    Tk.grid(bbox, 3, 1, sticky="ew")

    Tk.tcl("grid", "rowconfigure",    outer, 0, weight=100, pad=3)
    Tk.tcl("grid", "columnconfigure", outer, 0, weight=100)

    
    defined_btns = {
                    :ok => ("ok", :accept),
                    :cancel => ("cancel", :reject),
                    :close => ("close", :reject),
                    :apply  => ("apply", :apply),
                    :reset => ("reset", :reset),
                    :help => ("help", :help)
                    }
    
    for b in reverse!(buttons)
        nm, state = defined_btns[b]
        btn = Tk.Button(bbox, nm)
        Tk.pack(btn, side="right", padx=2, pady=2)
        bind(btn, "command") do path
            notify(model, "done", state)
        end
    end
    



    (window, frame)
end

getWidget(::MIME"application/x-tcltk", dlg::Dialog) = dlg.block

setSize(::MIME"application/x-tcltk", dlg::Dialog, value::Vector{Int}) = Tk.set_size(dlg.o, value)

## bind escape key
function add_bindings(::MIME"application/x-tcltk", dlg::Dialog)
    bind(dlg.o, "<Escape>") do path
        tcl("grab", "release", dlg.block)
        tcl("destroy", dlg.block)
        dlg.reject()
    end
end

function show_dialog(::MIME"application/x-tcltk", dlg::Dialog, value::Bool)
    Tk.wm(dlg.o, value ? "deiconify" : "withdraw")
end
function setModal(::MIME"application/x-tcltk", dlg::Dialog, value::Bool)
    ## need to wait for a variable.... to get blocking behaviour
    if value
#        tcl("tkwait", "window", dlg.block) ## THIS IS A BIG ISSUE
        tcl("grab", "set", "-global", dlg.o)
    else
        tcl("grab", "release", dlg.o)
    end
end
function setModaless(::MIME"application/x-tcltk", dlg::Dialog, value::Bool)
    tcl("grab", value ? "set" : "release", dlg.o)
end
function destroy(::MIME"application/x-tcltk", dlg::Dialog)
    setModal(dlg, false)
    tcl("destroy", dlg.o)
end


### special dialogs
##
## Returns file, directory, files or nothing
function filedialog(::MIME"application/x-tcltk", 
                    parent::Widget; 
                    mode::Symbol=:open, ## :open, :multiple, :directory, :save
                    message::String="",
                    title::String="",
                    filetypes::Union(Nothing, Vector{Tuple})=nothing)

    args = {"parent"=>getWidget(parent), 
            "message"=>message,
            "title" => title
            }
           

    if mode == :save
        ret = tcl("tk_getSaveFile", args)
        if ret == "" ret=nothing end
        return ret
    elseif mode == :directory
        ret = tcl("tk_chooseDirectory", args)
        if ret == "" ret=nothing end
        return ret
    end
    ## do filetypes an array [(name, ext)]
    if !isa(filetypes, Nothing)
        tmp = "{"
        for (nm, ext) in filetypes
            tmp = tmp * " {{$nm} {$ext}} "
        end
        tmp = tmp * "}"         # how to match all?
        args["filetypes"] = tmp
    end

    if mode == :open
        ret = tcl("tk_getOpenFile", args)
        if ret == "" ret=nothing end
        return ret
    elseif mode == :multiple
        args["multiple"] == true
        ret = tcl("tk_getOpenFile", args)
        ret = (ret == "" ? nothing : split(ret))
        return ret
    end
end
        
    



function messagebox(::MIME"application/x-tcltk", parent::Widget, text::String; icon::Union(Nothing, String)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) # detail
    args = {"parent" => isa(parent, Window) ? parent.block : getWidget(parent), "message" => text}
    if !isa(title, Nothing) args["title"] = title end
    if !isa(informativeText, Nothing) args["detail"] = informativeText end
    
    icons = {:question=>"question",
             :info => "info", 
             :warning=>"warning", 
             :critical=>"error"}
    if !isa(icon, Nothing)
        args["icon"] = icons[icon]
    end
    
    args["type"] = "okcancel"
    ret = Tk.tcl("tk_messageBox", args)
    ret == "ok" ? :accept : :reject
end

function confirmbox(::MIME"application/x-tcltk", parent::Widget, text::String; icon::Union(Nothing, Symbol)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) # detail
    args = {"parent" => isa(parent, Window) ? parent.block : getWidget(parent), "message" => text}
    if !isa(title, Nothing) args["title"] = title end
    if !isa(informativeText, Nothing) args["detail"] = informativeText end

    icons = {:question=>"question",
             :info => "info", 
             :warning=>"warning", 
             :critical=>"error"}
    if !isa(icon, Nothing)
        args["icon"] = icons[icon]
    end

    args["type"] = "okcancel"
    ret = Tk.tcl("tk_messageBox", args)
    ret == "ok" ? :accept : :reject
end

##################################################
## Menus


function action(::MIME"application/x-tcltk", parent)
    nothing
end

## XXX Need to do work here, as at present action no knows about its proxies XXX
getEnabled(::MIME"application/x-tcltk", action::Action) = nothing
setEnabled(::MIME"application/x-tcltk", action::Action, value::Bool) = nothing

## not tk specific bits to add to actions
setLabel(::MIME"application/x-tcltk", action::Action, value::String) = nothing
setIcon(::MIME"application/x-tcltk", action::Action, value::Icon) = nothing
setShortcut(::MIME"application/x-tcltk", action::Action, value::String) = nothing
setTooltip(::MIME"application/x-tcltk", action::Action, value::String) = nothing
setCommand(::MIME"application/x-tcltk", action::Action, value::Function) = nothing


## menus
function menubar(::MIME"application/x-tcltk", parent::Window)
    Tk.Menu(parent.o)           # not :widget!
end

## toplevel menu item
function menu(::MIME"application/x-tcltk", parent::MenuBar, label)
    Tk.menu_add(parent[:widget], label)
end

## submenu
function menu(::MIME"application/x-tcltk", parent::Menu, label)
    Tk.menu_add(parent[:widget], label)
end

## popup
function menu(::MIME"application/x-tcltk", parent::Widget)
    m = Tk.Menu(parent[:widget])
    Tk.tk_popup(parent[:widget], m)
    m
end

## add actions
function addAction(::MIME"application/x-tcltk", parent::Menu, action::Action)
    Tk.menu_add(parent[:widget], action.label, (path) -> action.command()) # icon, ...
end

function addAction(::MIME"application/x-tcltk", parent::Menu, value::Separator)
    Tk.menu_add(parent[:widget], value[:widget])
end

function addAction(::MIME"application/x-tcltk", parent::Menu, value::RadioGroup)
    ## bypass Tk.menu_add
    var = Tk.cget(value[:widget].buttons[1], "variable")
    items = value[:items]
    for i in 1:length(items)
        tcl(parent[:widget], "add", "radiobutton", label = items[i], value = items[i],
            variable = var,
            command = (path) -> value[:value] = items[i])
    end
end

function addAction(::MIME"application/x-tcltk", parent::Menu, value::CheckBox)
    ## bypass Tk.menu_add
    Tk.tcl(parent[:widget], "add", "checkbutton", label=value[:label], 
           variable = value[:widget][:variable],
           command = (path) -> value[:value] = Tk.get_value(value[:widget])
           ) 
end


### Manipulate. Display FramedPlot

## Default is text
function Display(::MIME"application/x-tcltk", self::ManipulateObject, x; kwargs...) 
    if isa(x, Nothing) return end
    value = string(x)

    oa = self.output_area
    ## add new textedit area if needed
    if length(children(oa)) > 0 && isa(oa.children[1], TextEdit)
        setValue(oa.children[1], value)
        return
    elseif length(children(oa)) > 0
        pop!(oa)
    end
    ## add one
    te = textedit(oa, value)
    te[:sizepolicy] = (:expand, :expand)
    push!(oa, te)
end

