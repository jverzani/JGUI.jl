## Container widgets defined here

## methods
connect(object::Container, signal::Union(Symbol,String), obj, slot::Function) = connect(object.model, string(signal), obj, slot)
connect(object::Container, signal::Union(Symbol,String), slot::Function) = connect(object.model, string(signal), slot)
disconnect(o::Container, id::String) = disconnect(o.model, id)

## think of containers as Widget[] containers

@doc "Return all children of a container" ->
children(object::Container) = object.children

@doc "access children of a container by index" ->
getindex(object::Container, i::Union(Int, Range, Vector)) = children(object)[i]

## `push!(parent, child)` is the typical way a child is added to a
## container. This is a convenience as the child holds a reference to
## the parent.
push!(child::Widget) = push!(child.parent, child)

## Bin containers only allow one child
abstract BinContainer <: Container 

## Children are added to a bin container by `push!`
function push!(parent::BinContainer, child::Widget)
    if parent != child.parent
        error("Window is not parent's child?")
    end

    if length(children(parent)) >= 1
        error("Can only add one child to a $(typeof(parent)) object")
    end
    ##
    push!(parent.children, child)

    set_child(parent.toolkit, parent, child)
end

@doc "Remove (alias for `pop!`) child of a bin container" ->
clear(parent::BinContainer) = pop!(parent)
length(parent::BinContainer) = length(children(parent))

##################################################
##
## Top-level window
##
type Window <: BinContainer
    o                           # frame
    block                       # window
    parent
    model
    toolkit
    children
    attrs::Dict
end

@doc """
Constructor for a toplevel window

A toplevel window is a `BinContainer` and can hold only one child.

## arguments

* `visible::Bool=true` if `false` suppress the initial drawing of the window

## Examples
```julia
w = window(title="title")
b = button(w, "delete")
connect(b, :clicked, () -> destroy(w))
raise(w)
```
""" ->
function window(;toolkit::MIME=default_toolkit, visible::Bool=true, kwargs...)
    widget, block = window(toolkit, visible=visible)
    obj = Window(widget, block, nothing, EventModel(), toolkit, {}, Dict())
    obj[:icontheme] = :default
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

@doc "Raise window to top of viewable stack" ->
raise(o::Window) = raise(o.toolkit, o)
raise(o::Widget) = raise(o.parent)

@doc "lower window to bottom of visible stack" ->
lower(o::Widget) = lower(o.parent)
lower(o::Window) = lower(o.toolkit, o)

@doc "Destroy the window" ->
function destroy(o::Window)
    ## XXX call method that can intercept?
    destroy_window(o.toolkit, o)
end
destroy(o::Widget) = destroy(o.parent)


## properties
getTitle(o::Window) = getTitle(o.toolkit, o)
setTitle(o::Window, value::String) = setTitle(o.toolkit, o, value)
getModal(o::Window) = getModal(o.toolkit, o)
setModal(o::Window, value::Bool) = setModal(o.toolkit, o, value)
getPosition(o::Window) = getPosition(o.toolkit, o)
setPosition(o::Window, value::Vector{Int}) = setPosition(o.toolkit, o, value)
list_props(::@PROP("Window")) = {:title => "window title",
                                 :modal => "make window modal",
                                 :position => "move to position [x,y]"
                                 }
                                 
## XXX addToolBar, addMenuBar, addStatusBar...

## what name for this?
## not that useful as is, need to use Module.DataType, as these aren't exported
function lookup(o::Container, by::DataType)
    ## return all children of the given data type recursing over children
    function add_children(obj)
        for child in children(obj)
            isa(child, by) && push!(out, child)
            isa(child, Container) && add_children(child)
        end
    end
    out = {}
    add_children(o)
    out
end
    
    
## labelframe
type LabelFrame <: BinContainer
    o
    block
    parent
    model
    toolkit
    children
    attrs::Dict
end

@doc """
Label frame is a bin container to surround another container in a frame with a title.

## Arguments:

* `(parent, label::String; kwargs...)`    
* `alignment::MaybeSymbol`, one of (nothing, :left, :center, :right)

## Examples
```julia
w = window(title="labelframe")
lf = labelframe(w, "A label")
push!(w, lf)
b = button(lf, "button")
push!(lf, b)
```

""" ->
function labelframe(parent::Container, label::String; alignment::Union(Nothing, Symbol)=nothing, kwargs...)
    (widget, block) = labelframe(parent.toolkit, parent, label, alignment=alignment)
    obj = LabelFrame(widget, block, parent, EventModel(), parent.toolkit, {}, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end


##################################################
## 
## Box containers

type BoxContainer <: Container
    o
    block
    parent
    toolkit
    children
    attrs::Dict
end

@doc """
A boxcontainer holds child objects either horizontally (`hbox`) or vertically (`vbox`)

Like Gtk, and not Qt or TclTk the container and the layout are coupled. Box containers are basically
frames with a box-like layout. By contrast, grid containers are frames with grid-like layouts.

Conceptually a box container is treated like a queue. Children are
pushed, appended, prepended, or inserted into it. They can be
popped, shifted, or spliced by index. Child components may be
referenced by integer indices.

Children are placed in box with size policies set by the
`sizepolicy` property. These are specified by direction `x` or `y`. The
value can be `nothing`, `:fixed`, or `:expand`. By default, widgets
will expand in the direction orthogonal to the packing direction
(horizontally for vertical boxes).

When a child does not expand to fill the allocated space, it can be
aligned within the cell. The `alignment` property sets attributes
that control this, again with `x` and `y` values in `(:left,
:right, :center, :justify)`, `(:top, :bottom, :center)`
respectively.

## Methods

The boxcontainer is viewed as a queue. These methods allow on to place children, as though into a vector

* `push!`
* `insert!`
* `unshift!`
* `append!`
* `prepend!`
* `splice!`
* `delete!`
* `pop!`
* `shift!`

""" ->
function boxcontainer(parent::Container; direction::Symbol=:horizontal, kwargs...)
    ## Toolkit
    widget, block = boxcontainer(parent.toolkit, parent, direction)


    ##
    obj = BoxContainer(widget, block, parent, parent.toolkit, {}, Dict())

    obj.attrs[:direction] = direction
    obj.attrs[:spacing] = [2,2]

    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

@doc "short form of `boxcontainer`" ->
box(parent::Container, direction=:h; kwargs...) = boxcontainer(parent, direction=direction==:h ? :horizontal : :vertical, kwargs...)


@doc "short form for a horizontal `boxcontainer`" ->
hbox(parent::Container; kwargs...) = boxcontainer(parent, direction=:horizontal, kwargs...)

@doc "short form for a vertical `boxcontainer`" ->
vbox(parent::Container; kwargs...) = boxcontainer(parent, direction=:vertical, kwargs...)

@doc "Returns number of children in box container" ->
length(object::BoxContainer) = length(children(object))

@doc "Remove all children in box container" ->
clear(object::BoxContainer)  = splice!(object, 1:length(object))

@doc "add strut (minimum height or width) to box container" ->
addstrut(parent::BoxContainer, px::Int) = addstruct(parent.toolkit, parent, px)

@doc "addStretch a stretching blank box" ->
addstretch(parent::BoxContainer, stretch::Int) = addstretch(parent.toolkit, parent, stretch)

@doc "addSpacing add blank space to layout" ->
addspacing(parent::BoxContainer, spacing::Int) = addspacing(parent.toolkit, parent, spacing)


## properties
## may be dynamic and adjust for just current chidren
## spacing around each child
getSpacing(object::BoxContainer) = object.attrs[:spacing]
setSpacing(object::BoxContainer, px::Int) = setSpacing(object, [px,px])
function setSpacing(object::BoxContainer, px::Vector{Int})
    object.attrs[:spacing] = px
    setSpacing(object.toolkit, object, px)
end
## margin around insider of container
setMargin(object::BoxContainer, px::Int) = setMargin(object::BoxContainer, [px,px])
setMargin(object::BoxContainer, px::Vector{Int}) = setMargin(object.toolkit, object, px)

list_props(::@PROP("BoxContainer")) = {:margin  => "[x,y] area in pixels around interior of box",
                                       :spacing => "[x,y] padding around each child widget"
                                       }

## findin
## return index of child in parent or 0 if not present
function findin(child::Widget, parent::Container) 
    kids = children(parent)
    n = length(kids)
    out = [1:n][child .== kids]
    length(out) == 0 ? 0 : out[1] 
end

## add child to parent

## add child widget to box container" 
function push!(parent::BoxContainer, child::Widget)
    insert!(parent, length(parent) + 1, child)
end

## insert child into box container. index in `1:(n+1)`
function insert!(parent::BoxContainer, index::Int, child::Widget)
    insert!(parent.children, index, child)
    insert_child(parent.toolkit, parent, index, child)
    child
end

## insert child into first position of a box container
unshift!(parent::BoxContainer, child::Widget) = insert!(parent, 1, child)

## append several children to a box container
function append!{T <: Widget}(parent::BoxContainer, children::Vector{T})
    for child in children
        push!(parent, child)
    end
    children
end

## prepend severak children to a box container
function prepend!{T <: Widget}(parent::BoxContainer, children::Vector{T})
    for child in reverse(children)
        insert!(parent, 1, child)
    end
    children
end
prepend!(parent::BoxContainer, child) = prepend!(parent, [child])


@doc "Remove a child from a box container by index" ->
function splice!(parent::Container, index::Int)
    child = children(parent)[index]
    splice!(parent.children, index)
    remove_child(parent.toolkit, parent, child)
    child
end

## remove a child
function delete!(parent::Container, child::Widget)
    splice!(parent, findin(child, parent))
end

## Remove last child from a container
function pop!(parent::Container) 
    splice!(parent, length(parent))
end

## Remove first child from a box container
shift!(parent::Container) = splice!(parent, 1)

 

##################################################
##
## Grid container
##

type GridContainer <: Container
    o
    block
    parent
    toolkit
    children
    attrs::Dict
end

@doc """
Grid

a grid-like container

Conceptually a grid is treated like a matrix.

One can add children by index:
- `parent[i,j] = child`
- `parent[:,:] = [child1 child2; nothing child3]`

Children can span multiple cells if added as follows
- `parent[i:(i+k), j:(j+l)] = child`

children can be referenced by index, as in `parent[i,j]`.

Children can be removed via `pop!(parent, child)`.

the size policy and alignment policies are used to position children within a cell

Rows and columns can be configured to have a minimum height, width or relative size through
`row_minimum_height`, `column_minimum_width`, `row_stretch`, `column_stretch`.

## Examples:
```julia
w = window(title="grid")
g = grid(w); push!(w, g)
g[1:2,1:2] = button(g, "1:2,1:2")
g[1:2, 3] = slider(g, 1:10, orientation=:vertical, size=[-1, 200])
g[3, 1:3] = slider(g, 1:10, size=[200, -1])
```

""" ->
function grid(parent::Container; kwargs...)

    widget, block = grid(parent.toolkit, parent)
    obj = GridContainer(widget, block, parent, parent.toolkit, {}, Dict())

    obj.attrs[:size] = [0,0]
    obj.attrs[:spacing] = [2,2]
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

## XXX Document, but should these relate to addStretch, addSpacing for box containers (they play the same role)
function column_minimum_width(object::GridContainer, j::Int, width::Int)
    column_minimum_width(object.toolkit, object, j, width)
end

function row_minimum_height(object::GridContainer, i::Int, height::Int)
    row_minimum_width(object.toolkit, object, i, height)
end

function column_stretch(object::GridContainer, j::Int, weight::Int)
    column_stretch(object.toolkit, object, j, weight)
end
function row_stretch(object::GridContainer, i::Int, weight::Int)
    row_stretch(object.toolkit, object, i, weight)
end

## Properties
getSpacing(object::GridContainer) = object.attrs[:spacing]
setSpacing(object::GridContainer, px::Int) = setSpacing(object, [px, px])
function setSpacing(object::GridContainer, px::Vector{Int}) 
    object.attrs[:spacing] = px
    setSpacing(object.toolkit, object, px)
end

list_props(::@PROP("GridContainer")) = {:spacing => "[x,y] padding around each child widget"
                                       }

## return number of rows and columns
@doc "number of rows and columns of a grid container" ->
size(object::GridContainer) = grid_size(object.toolkit, object)
size(object::GridContainer, i::Int) = grid_size(object.toolkit, object)[i]
endof(object::GridContainer) = prod(size(object))
ndims(object::GridContainer) = 2

@doc "remove all children from a grid container" ->
function clear(object::GridContainer)
    for child in children(object)
        remove_child(child.toolkit, child.parent, child)
    end
    object.children = {}
end

@doc """
add children to grid container using array notation

* `parent[i,j] = child` places child at grid location i, j
* `parent[1:4, 2:3] = child` will place over multiple cells
""" ->
function setindex!(parent::GridContainer, child::Widget, i::Union(Int, Range1), j::Union(Int, Range1))
    ## must check that parents agree
    if parent != child.parent
        error("Parents are not the same")
    end

    ## How to organize children here? Could be a matrix, could carry ind info.... Useful for getindex..
    push!(parent.children, child) ## just a vector for now
    grid_add_child(parent.toolkit, parent, child, i, j)
end

## place children through grid notation
##
## * `parent[:,:] = [w1 w2; nothing w3]` will place the three children in cells (1,1), (1,2) and (2,2).
function setindex!(parent::GridContainer, children::Array, i::Union(Int, Range1), j::Union(Int, Range1))
    nr, nc = size(parent)
    if length(i) == nr && length(j) == nc
        clear(parent)
    end

    nr, nc = size(children)
    for i in 1:nr, j in 1:nc
        child = children[i, j]
        if isa(child, Widget)
            parent[i, j] = child
        end
    end
end

## retrieve children from a grid container through array notation
function getindex(object::GridContainer, i::Int, j::Int)
    grid_get_child_at(object.toolkit, object, i, j)
end

function getindex(object::GridContainer, i::Union(Vector, Range1), j::Union(Vector, Range1))
    [object[ii, jj] for j in jj, ii in i]
end

@doc "Remove a child from a grid container" ->
function delete!(parent::GridContainer, child::Widget)
    filter!(x -> !(x == child), parent.children)
    remove_child(parent.toolkit, parent, child)
end

###
type FormLayout <: Container
    o
    block
    parent
    toolkit
    children
    child_labels
    attrs::Dict
end

@doc """
formlayout

container to layout children in simple "label: control" form

children are pushed onto the end with an additional label (which may be null):
- `push!(parent, child, label)`

The `getValue` method will return a dictionary of control values keyed by the labels.

## Examples:
```julia
w = window(title = "formlayout")
fl = formlayout(w); push!(w, fl)
ed = lineedit(fl, "lineedit 1")
push!(fl, ed, "lineedit 1")
ed = lineedit(fl, "lineedit 2")
push!(fl, ed, "lineedit 2")
b = button(fl, "click")
push!(fl, b, "")
connect(b, :clicked, () -> println(fl[:value])) ## current values
```

""" ->
function formlayout(parent::Container;  kwargs...)
  
    widget, block = formlayout(parent.toolkit, parent)

    obj = FormLayout(widget, block, parent, parent.toolkit, {}, {}, Dict())

    obj.attrs[:nrows] = 0
    obj.attrs[:spacing] = [5,2]
    obj[:sizepolicy] = (:expand, :expand)
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

@doc "add children to a `formlayout` is done via `push!(lty, child, label)`:" ->
function push!(parent::FormLayout, child::Widget, label::Union(Nothing, String))
    push!(parent.children, child)
    push!(parent.child_labels, label)
    formlayout_add_child(parent.toolkit, parent, child, label)
end

push!(parent::FormLayout, child::Widget; label::String="") = push!(parent, child, label)

## return dictionary of control values
function getValue(widget::FormLayout)
    kids = children(widget)
    labels = widget.child_labels
    d = Dict()
    for i in 1:length(kids)
        if !isa(kids[i], Control) next end
        label = labels[i]
        key = isa(label, Nothing) ? string("control i") : label
        d[key] = getValue(kids[i])
    end
    d
end


## Properties
getSpacing(object::FormLayout) = object.attrs[:spacing]
setSpacing(object::FormLayout, px::Int) = setSpacing(object, [px, px])
function setSpacing(object::FormLayout, px::Vector{Int}) 
    object.attrs[:spacing] = px
    setSpacing(object.toolkit, object, px)
end

list_props(::@PROP("FormLayout")) = {:spacing => "[x,y] padding around each child widget",
                                     :value => "read only. Returns dictionary of widget values"}

##################################################
##    
## notebook

type NoteBook <: Container
    o
    block
    parent
    toolkit
    children
    model
    attrs::Dict
end

@doc """
notebook container

## Arugments

* `parent::Container` parent container

## Signals

* `valueChanged (value)` value is currently selected tab index

## Methods

* `length` number of tables
* `insert!` insert at `i` with label i in {1, 2, ..., length + 1}

## TODO: rename label

## Examples:
```julia
w = window(title="notebook")
nb = notebook(w); push!(w, nb)

push!(nb, button(nb, "one"), "one")
push!(nb, button(nb, "two"), "two")
b =  button(nb, "pop! last child")
push!(nb, b, "three")

connect(nb, :valueChanged, value -> println("On tab ", value))
connect(b, :clicked, () -> pop!(nb))
```

""" ->
function notebook(parent::Container, kwargs...)
    model = ItemModel(0)
    widget, block = notebook(parent.toolkit, parent, model)

    obj = NoteBook(widget, block, parent, parent.toolkit, {}, model, Dict())

    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

## interface
length(object::NoteBook) = length(object.children)
function setValue(object::NoteBook, i::Int; signal::Bool=true) 
    if i < 1 || i > length(object)
        return
    end
    setValue(object.model, i; signal=signal)
end
getValue(object::NoteBook) = getValue(object.model)

function insert!(parent::NoteBook,  i::Int, child::Widget, label::String)
    if i < 0 || i > length(parent) + 1
        error("Index needs to be between 1 and n+1")
    end

    notebook_insert_child(parent.toolkit, parent, child, i, label)
    insert!(parent.children, i, child)

end
push!(parent::NoteBook, child::Widget, label::String) = insert!(parent,  length(parent) + 1, child, label)
unshift!(parent::NoteBook, child::Widget, label::String) = insert!(parent, 1, child, label)

## Remove a child by index
function splice!(parent::NoteBook, index::Int)
    child = children(parent)[index]
    notebook_remove_child(parent.toolkit, parent, child)
    splice!(parent.children, index)
    child
end
pop!(parent::NoteBook) = splice!(parent, length(parent))
shift!(parent::NoteBook) = splice!(parent, 1)

pop!(parent::NoteBook, child::Widget) = splice!(parent, findin(child, parent))



## panedgroup
## expandgroup...
