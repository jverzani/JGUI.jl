
## General Widget properties

## the `:value` property is the primary one for a control
getValue(o::WidgetModel) = getValue(o.model)
setValue(o::WidgetModel, value) = setValue(o.model, value)

## the `:items` property is used by widgets with VectorModels -- that
## is, those widgets which are used to select 0, 1 or more from a
## collection.
getItems(o::WidgetVectorModel) = getItems(o.model)
setItems(o::WidgetVectorModel, value) = setItems(o.model, value)

## `:enabled` is used to make a widget sensitive (or not) to user input
getEnabled(o::Widget) = getEnabled(o.toolkit, o)
setEnabled(o::Widget, value::Bool) = setEnabled(o.toolkit, o, value)

## `:visible` controls if a widget is shown
getVisible(o::Widget) = getVisible(o.toolkit, o)
setVisible(o::Widget, value::Bool) = setVisible(o.toolkit, o, value)

## `:size` controls the size request of a widget. Can be useful for top-level windows
getSize(o::Widget) = getSize(o.toolkit, o)
setSize{T <: Int}(o::Widget, sz::Vector{T}) = setSize(o.toolkit, o, sz)

## `:focus` can be used to set the focus on a control
getFocus(o::Widget) = getFocus(o.toolkit, o)
setFocus(o::Widget, value::Bool) = setFocus(o.toolkit, o, value)

## `:sizepolicy` determines how a widget expands to fill its allocated
## space.  The value is specified as a tuple (x,y) with each being be
## one of `:fixed`, `:expand`, or `nothing`.
function getSizepolicy(o::Widget)
    if haskey(o.attrs, :sizepolicy)
        o.attrs[:sizepolicy]
    else
        (nothing, nothing)
    end
end
function setSizepolicy(o::Widget, value)
    ## must have proper policy (nothing, :fixed, :expand)
    x, y = value
    ## check
    o.attrs[:sizepolicy] = value
end

## `:alignment` is used to determine how a control is aligned in its
## allocated space. The value is specified as a tuple (xalign, yalign)
## where xaligh is in (:left, :right, :center, :justify) and yalign
## one of (:top, :bottom, :center).
function getAlignment(o::Widget) 
    if haskey(o.attrs, :alignment)
        o.attrs[:alignment]
    else
        (nothing, nothing)
    end
end

function setAlignment(o::Widget, value) #x::Union(Symbol, Nothing), y::Union(Symbol, Nothing))
    x, y = value
    if isa(x, Symbol)
        if !contains([:left, :right, :center, :justify], x) 
            error("x-alignment is one of :left, :right, :center, :justify or nothing.") 
        end
    end    
    if isa(y, Symbol)
        if !contains([:top, :bottom, :center], y) 
            error("y-alignment is one of :top, :bottom, :center or nothing.") 
        end
    end
    o.attrs[:alignment] = value
end

## icontheme
getIcontheme(o::Widget) = getIcontheme(o.parent)
getIcontheme(o::Window) = o.attrs[:icontheme]
setIcontheme(o::Widget, value::Symbol) = setIcontheme(o.parent, value)
setIcontheme(o::Window, value::Symbol) = o.attrs[:icontheme] = value

## get widget. Mostly just obj.o, but there may be exceptions
getWidget(o::Widget) = getWidget(o.toolkit, o)

## list Widget properties
list_props(::@PROP("Widget")) = {:value => "Value of object",
                                 :items => "Any items to select from",
                                 :enabled => "is widget sensitive to user input",
                                 :visible => "is widget drawn",
                                 :size => "widget size (width, height) in pixels",
                                 :focus => "Does control have focus",
                                 :sizepolicy => "(x,y) with x and y being nothing, :fixed or :expand",
                                 :alignment => "(x,y) with x in (:left, :right, :center, :justify), y in (:top, :bottom, :center)",
                                 :icontheme => "set theme for any icons to be added"
                                 }



## WidgetModel
##
## The signals are emitted by the model. These definitions bring
## connect, disconnect and notify to the widget for convenience
function connect(o::WidgetModel, signal::String, obj, slot::Function)
    connect(o.model, signal, obj, slot)
end
function connect(o::WidgetModel, signal::String, slot::Function)
    connect(o.model, signal, nothing, slot)
end
connect(slot::Function, o::WidgetModel, signal::String) = connect(o, signal, slot)
disconnect(o::WidgetModel, id::String) = disconnect(o.model, id)
notify(o::WidgetModel, signal::String) = notify(o.model, signal)


##################################################
## Basic widgets for drawing to window

## Label

type Label <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Basic label widget
##
## Arguments:
## * `parent::Container` parent container
## * `value::Union(ItemModel, String)` either a model (for sharing) or string.
##
## Signals:
## * `valueChanged (value)` called when label text is updated.
function label(parent::Container, model::Model)
    widget, block = label(parent.toolkit, parent, model)
    Label(widget, block, model, parent, parent.toolkit, Dict())
end
label(parent::Container, value::String) = label(parent, ItemModel(value))
label(parent::Container, value::Number) = label(parent, string(value))
setValue(o::Label, value::Number) = setValue(o, string(value))
## Separator
type Separator <: Style
    o
    block
    parent
    toolkit
    attrs
end

## Add a horizontal or vertical line to a layout
##
## Arguments:
## * `orientation::Symbol` one of `:horizontal` (default) or `:vertical`
function separator(parent::Container; orientation::Symbol=:horizontal)
    widget, block = separator(parent.toolkit, parent, orientation=orientation)
    Separator(widget, block, parent, parent.toolkit, Dict())
end

##################################################
## Button widget

type Button <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## A button object
##
## Arguments:
## * `parent::Container` a parent container
## * `value::Union(ItemModel, String)` If a model, value is shared. If a string, used as label
##
## Signals:
## * `clicked ()`: called when clicked
## * `valueChanged (value)`: called when label is changed
##
function button(parent::Container, model::Model)
    widget, block = button(parent.toolkit, parent, model)
    Button(widget, block, model, parent, parent.toolkit, Dict())
end
button(parent::Container, value::String) = button(parent, ItemModel(value))
button(parent::Container, value::Number) = button(parent, string(value))

function setIcon(object::Button, icon::Icon;
                 theme::Union(Nothing, Symbol) = nothing,
                 size::Union(Nothing, Vector{Int}) = nothing)
    if theme == nothing
        theme = object[:icontheme]
    end
    if size == nothing
        size = [16, 16]
    end
    setIcon(object.toolkit, object, icon)#; theme=theme, size=size)
end
setIcon(object::Button, nm::Union(Symbol, String)) = setIcon(object, icon(nm))
setIcon(object::Button, nm::Nothing) = setIcon(object.toolkit, object, icon)

list_props(::@PROP("Button")) = {:icon => "Set accompanying icon"}
##################################################
## Text controls

## LineEdit

## signals
## (valueChanged, (value))
## (activated, ())
## (keystroke, (key))
type LineEdit <: WidgetModel
    o
    block
    model
    parent
    toolkit
    coerce
    attrs
end

## single line text entry
##
## Arguments:
## * `value` is an item model (for sharing) or a string or a number
## * `coerce` is a function to be called on the string value in the edit
## box before getValue. Even if a number is specified as the value,
## the return will be a string unless coerced.
## 
## Signals:
## * `editingFinished` (value) called when <return> key is pressed or blur
## * `blur` (value) called on focus out event
## * `textChanged` (key) called on each keystroke
## * `valueChanged` (value) called on each change, even keystrokes
##
## TODO
## * typeahead values
## * validation
## * undo/redo stack
## ...
function lineedit(parent::Container, model::Model; coerce::Union(Nothing, Function)=nothing)
    widget, block = lineedit(parent.toolkit, parent, model)
    LineEdit(widget, block, model, parent, parent.toolkit, coerce, Dict())
end
lineedit(parent::Container, value::String; kwargs...) = lineedit(parent, ItemModel(value); kwargs...)
lineedit(parent::Container, value::Number; kwargs...) = lineedit(parent, string(value); kwargs...)

## Call coerce if present. If can't be coerced, returns nothing
function getValue(obj::LineEdit)
    val = getValue(obj.model)
    isa(obj.coerce, Nothing) ? val : try obj.coerce(val) catch e nothing end
end

## TextEdit
type TextEdit <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Multi-line text edit
## Arguments:
## * `parent::Container`: parent container
## * `value::Union(ItemModel, String)`: inital string or an `ItemModel` to share
##
## Signals:
## * `activated` (value) called when blur occurs
## * `blur` (value) called on focus out event
## * `textChanged` (key) called on each keystroke
## * `valueChanged` (value) called on each change, even keystrokes
## * 
## TODO:
## * set size
## * to add text not just replace
## * get just the selection
## * selection changed signal
## * ...
function textedit(parent::Container, model::Model)
    widget, block = textedit(parent.toolkit, parent, model)
    TextEdit(widget, block, model, parent, parent.toolkit, Dict())
end
textedit(parent::Container, value::String) = textedit(parent, ItemModel(value))
textedit(parent::Container, value::Number) = textedit(parent, string(value))


##################################################
##
## Selection widgets

## checkbox
type CheckBox <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## checkbox
## 
## standard toggle for true/false values. Optional label.
##
## Arguments:
## * `value::Bool` initial state of widget
## * `label::MaybeString` optional label
##
## Signals:
##
## * `valueChanged (value)` called when widget toggles state.
##
function checkbox(parent::Container, model::Model, label::Union(Nothing, String))
    widget, block = checkbox(parent.toolkit, parent, model, label)
    CheckBox(widget, block, model, parent, parent.toolkit, Dict())
end

function checkbox(parent::Container, value::Bool, label::Union(Nothing, String) )
    model=ItemModel(value)
    checkbox(parent, model, label)
end
    
checkbox(parent::Container, value::Bool) = checkbox(parent, value, nothing)
checkbox(parent::Container, label::String) = checkbox(parent, true, label)

getLabel(o::CheckBox) = getLabel(o.toolkit, o)
setLabel(o::CheckBox, value::String) = setLabel(o.toolkit, o, value)

list_props(::@PROP("CheckBox")) = {:label => "checkbox label"}

##################################################
## 
## WidgetVectorModel is used for selection
##


function setValue(o::WidgetVectorModel, value)
    ## is value in vector?
    if any(value .== o[:items])
        setValue(o.model, value)
    end
end

type RadioGroup <: WidgetVectorModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Radio button group
##
## Value, not index, is used to store state.
##
## Arguments:
##
##
## Signals:
## * `valueChanged (value)` called when selected value is updated
##
## TODO
## * how to set items to be selected? (need `setItems` method)
function radiogroup(parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    widget, block = radiogroup(parent.toolkit, parent, model, orientation=orientation)
    RadioGroup(widget, block, model, parent, parent.toolkit, Dict())
end

function radiogroup(parent::Container, items::Vector, value; orientation::Symbol=:horizontal)
    model = VectorModel(items, value)
    radiogroup(parent, model, orientation=orientation)
end
radiogroup(parent::Container, items::Vector; orientation::Symbol=:horizontal) = radiogroup(parent, items, items[1], orientation=orientation)


type ButtonGroup <: WidgetVectorModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## buttongroup (Like radio group with buttons, toolbar style, exclusive=true)
##
## Arguments:
## * `exclusive::Bool` if `true` (the default), then like a radio
##    group. Otherwise can select zero, one or more of the buttons.
##
## Signals
## * `valueChanged (value)` when a button is toggled
##
## TODO
## * `setItems` method
function buttongroup(parent::Container, model::VectorModel; exclusive::Bool=true)
    widget, block = buttongroup(parent.toolkit, parent, model, exclusive=exclusive)
    ButtonGroup(widget, block, model, parent, parent.toolkit, Dict())
end

function buttongroup(parent::Container, items::Vector, value; exclusive::Bool=true)
    if !exclusive && !isa(value, Nothing)
        if !isa(value, Vector)
            value = [value]
        end
    end
    model = VectorModel(items, value)
    buttongroup(parent, model, exclusive=exclusive)
end
buttongroup(parent::Container, items::Vector; exclusive::Bool=true) = buttongroup(parent, items, nothing, exclusive=exclusive)


## combobox
type ComboBox <:  WidgetVectorModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Combobox
##
## Arguments:
##
## * `parent::Container` parent container
## * `model::VectorModel` model (more conveniently items and value can be specifed)
## * `editable::Bool` if true, create editable combobox.
##
## Signals:
##
## * `valueChanged (value)` called when combobox is update
##
## TODO:
##
## * `:editable=true` (will add `editingFinished` signal
##
function combobox(parent::Container, model::VectorModel; editable::Bool=false)
    widget, block = combobox(parent.toolkit, parent, model, editable=editable)
    ComboBox(widget, block, model, parent, parent.toolkit, Dict())
end

function combobox(parent::Container, items::Vector, value; editable::Bool=false)
    model = VectorModel(items, value)
    combobox(parent, model, editable=editable)
end
combobox(parent::Container, items::Vector; editable::Bool=false) = combobox(parent, items, items[1], editable=editable)




## slider
## Slider slides over indices in a sortable vector (not low to high, use linspace or range to control)
## so model has items as items to select from, value an index
type Slider <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Slider widget
## 
## Slider values are specified as a vector (not a from/to/by specification).
##
## Arguments:
##
## * `model::VectorModel` a model containing value and vector information. The value is the index of the vector.
## * `orientation::Sybol=:horizontal` orientation of slider when rendered
## * `items::Vector` vector of items, sortable.
## * `items::Range` Range of items to scroll through
## * `value::Int` index of initially selected item
##
## Signals:
##
## * `valueChanged (value)` return value in vector that is selected
##
function slider(parent::Container, model::VectorModel; orientation::Symbol=:horizontal)
    widget, block = slider(parent.toolkit, parent, model, orientation=orientation)
    Slider(widget, block, model, parent, parent.toolkit, Dict())
end
function slider(parent::Container, items::Vector, value::Int=1; orientation::Symbol=:horizontal)
    model = VectorModel(sort(items), value)
    slider(parent, model, orientation=orientation)
end
function slider(parent::Container, items::Vector; orientation::Symbol=:horizontal)
    items = sort(items)
    model = VectorModel(items, 1)
    slider(parent, model, orientation=orientation)
end

slider(parent::Container, items::Union(Range, Range1), value::Int=1; orientation::Symbol=:horizontal) =
    slider(parent, [items], value; orientation=orientation)
slider(parent::Container, items::Union(Range, Range1); orientation::Symbol=:horizontal) =
    slider(parent, [items]; orientation=orientation)

    
## slider2d
type Slider2D <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end

## Two dimensional slider
##
## from Mathematica's mnaipulate feature. Provides a slider for moving x and y simultaneously
##
## Arguments:
##
## * `items1` and `items2` are ranges to choose from
##
## Signals:
##
## * `valueChanged (value)` is called when slider is moved. The value are [x,y] coordinates
##
function slider2d(parent::Container, items1::Union(Range, Range1), items2::Union(Range, Range1)) 
    model = TwoVectorModel(items1, items2)
    widget, block = slider2d(parent.toolkit, parent, model)

    Slider2D(widget, block, model, parent, parent.toolkit, Dict())
end

getValue(o::Slider2D) = getValue(o.toolkit, o)
setValue{T <: Real}(o::Slider2D, value::Vector{T}) = setValue(o.toolkit, o, value)

## spinbox


##################################################
##
## Graphics


## CairoGraphics (for Winston)
type CairoGraphics <: Widget
    o
    block
    model
    parent
    toolkit
    attrs
end

## Cairo graphics device for use with Winston graphics, say
##
## Can be called with Winston.display(widget.o, p) -- need to make nicer 
##
## Arguments:
##
## Signals:
## * `mousePress (x,y)`
## * `mouseRelease (x,y)`
## * `mouseDoubleClick (x,y)`
## * `keyPress (key)`
## * `keyRelease (key)`
## * `mouseMotion (x,y)`
## * `mouseMove (x, y)`
##
## TODO:
##
function cairographics(parent::Container; width::Int=480, height::Int=400)
    model = EventModel()  # for event handling
    widget, block = cairographics(parent.toolkit, parent, model, width=width, height=height)
    CairoGraphics(widget, block, model, parent, parent.toolkit, Dict())
end


##################################################
## 
## Images

# type ImageView <: WidgetModel
#     o
#     block
#     model
#     parent
#     toolkit
#     attrs
#     img
#     draw
#     function ImageView(widget, block, model, parent, toolkit, attrs, img)
#         self = new(widget, block, model, parent, toolkit, attrs, img, nothing)
#         self.draw = () -> image_draw(self.toolkit, self, self.img)
#         self
#     end
# end


# ## image viewer
# ##
# ## Display an Image image. 
# ##
# ## Arguments:
# ##
# ## * `img::Image` an `Images.Image` instance (use `imread`, say)
# ##
# ## Signals
# ## * `mousePress (x,y)`
# ## * `mouseRelease (x, y)`
# ## * `mouseDoubleClick (x, y)`
# ##
# ## Status:
# ##
# ## Might work for you, but is flaky on the mac. (Size issues, need to have realized...)
# ##
# ## call the objects `.draw()` method to see the graphic, as in `obj.draw()`.
# function imageview(parent::Container, img::Image)
#     model = EventModel()
#     widget, block = imageview(parent.toolkit, parent, model, img)
#     o = ImageView(widget, block, model, parent, parent.toolkit, Dict(), img)
#     ## Can't draw to a Cairo backend until it is realized
#     connect(o.model, "realized") do 
#         o.draw()
#     end
#     o
# end

type ImageView <: Widget
    o
    block
    parent
    toolkit
    attrs
end

function imageview(parent::Container, img::Union(Nothing, String))
    widget, block = imageview(parent.toolkit, parent)
    o = ImageView(widget, block, parent, parent.toolkit, Dict())
    if !isa(img, Nothing)
        o[:image] = img
    end
    o
end

function setImage(o::ImageView, img::String)
    if isfile(img)
        o.attrs[:image] = img
        setImage(o.toolkit, o, img)
    end
end
##################################################
##
## Widgets with array or tree models

abstract ModelView <: WidgetModel
## StoreView
type StoreView <: ModelView
    o
    block
    store
    model
    parent
    toolkit
    attrs
end

## A storeview shows a set of items, where each items is displayed as a row.
##
## The items are all instances of a composite type
##
## Arguments:
## 
## * `parent::Container` parent container
##
## * `store::Store` a data store. 
##
## * `tpl` an instance of the composite type to display. Needed to determine
##   number of columns and headers if store is empty when passed in.
##
## * `selectmode in [:single, :multiple]
##
## Signals:
##
## * `valueChanged value` index (single) or [indices] (multiple)
## * `selectionChanged value` (indices)
## * `rowInserted, i`
## * `rowRemoved, i`
## * `rowClicked, i,j`
## * `rowDoubleClicked, i, j`
## * `headerClicked, j`
##
##
## Methods:
##
## getValue returns selected items
## getIndex: return index (:single) or [indices] (:multiple)
function storeview(parent::Container, store::Store; tpl=nothing, selectmode::Symbol=:single, kwargs...)
    model = ItemModel()         # for selection
    widget, block = storeview(parent.toolkit, parent, store, model)
    self = StoreView(widget, block, store, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        self[k] = v
    end
    self[:sizepolicy] = (:expand, :expand)
    self[:selectmode] = selectmode
    self
end

getindex(s::StoreView, i::Int) = s.store.items[i]
setindex!(s::StoreView, val, i::Int) = replace!(s, i, val)

## Properties
## value is value, but should refer to things by index
function getIndex(s::StoreView)
    val = s.model[:value]
    s[:selectmode] == :single ? val[1] : val
end
function setIndex(s::StoreView, index::Int) 
    s.model[:value] = isa(index, Vector) ? index : [index]
end
function getValue(s::StoreView)
    indices = s[:index]
    items = s.store.items
    items[indices]
end
function setValue(s::StoreView, val)
    println("Use s[:index] to set by row index")
end
    

## is header visible? (Can't suppress in Tk)
getHeader(s::StoreView) = setHeader(s.toolkit, s)
setHeader(s::StoreView, visible::Bool) = setHeader(s.toolkit, s, visible)

getSelectmode(s::ModelView) = getSelectmode(s.toolkit, s)
function setSelectmode(s::ModelView, val::Symbol)
    if any(val .== [:single, :multiple])
        setSelectmode(s.toolkit, s, val)
    end
end
getWidths(s::ModelView) = getWidths(s.toolkit, s)
setWidths(s::ModelView, widths::Vector{Int}) = setWidths(s.toolkit, s, widths)
setWidths(s::ModelView, widths::Int) = setWidths(s, [widths])

setIcon(s::StoreView, i::Int, icon::Icon) = setIcon(s.toolkit, s, i, icon)
setIcon(s::StoreView, i::Int, icon::Symbol) = setIcon(s, i, StockIcon(icon, s[:icontheme]))
setIcon(s::StoreView, i::Int, icon::String) = setIcon(s, i, FileIcon(icon))
    

list_props(::@PROP("ModelView")) = {:selectmode => "Either :single or :multiple",
                                    :widths => "Vector of column widths, in pixels"
                                 }

list_props(::@PROP("StoreView")) = {:header => "Adjust if headers are displayed"}

## methods
insert!(s::StoreView, i::Int, val) = insert!(s.store, i, val)
push!(s::StoreView, val) = push!(s.store, val)
unshift!(s::StoreView, val) = prepend!(s.store, val)
append!(s::StoreView, vals::Vector) = append!(s.store, vals)
splice!(s::StoreView, i::Int) = splice!(s.store, i)
pop!(s::StoreView) = splice!(s.store, length(s))
replace!(s::StoreView, i::Int, item) = replace!(s.store, i, item)

## list view
type ListItem <: AbstractStoreItem
    value
end

## A listview displays a vector. User can adjust selection to indicate
## selected values. There can be single or multiple selection.
##
## Arguments:
##
## * `items::Vector` items to select from
## * `selectmode::Symbol` which stule of selection
##
## Signals:
## 
## Come from `storeview`
##
## Properties:
## `:value` return value or [value] (if :multiple)
## `:index` return index or [index] (if :multiple)
function listview(parent::Container, items::Vector; selectmode::Symbol=:single)
    items =  map(x -> ListItem(x), items)
    store = Store{ListItem}(items)

    self = storeview(parent, store, selectmode=selectmode)

    self
end

##################################################
### Tree

type TreeView <: ModelView
    o
    block
    store
    parent
    toolkit
    attrs
end

## treeview widget
##
## Arguments:
##
## * `parent::Container` parent container
##
## * `store::TreeStore` tree store. Most of action happens with a tree store
##
## * `tpl` optional instance of data type for display. This allows columns to be set up in tree view. If not given, then
## the store should have atleast one child node.
##
## Signals:
##
## * `valueChanged (value)` gives selected paths
##
## * `nodeExpand (path)` gives path when node expands
##
## * `nodeCollapsed (path)` gives path when node expands
##
## * `clicked (path, column)` gives path and column user clicks on
## 
## * `DoubleClicked(path, column)` gives path and column user clicks on
##
function treeview(parent::Container, store::TreeStore; tpl=nothing)
    widget, block = treeview(parent.toolkit, parent, store; tpl=tpl)
    TreeView(widget, block, store, parent, parent.toolkit, Dict())
end

## properties
getKeywidth(tr::TreeView) = getKeywidth(tr.toolkit, tr)
setKeywidth(tr::TreeView, width::Int) = setKeywidth(tr.toolkit, tr, width)
list_props(::@PROP("TreeView")) = {:keywidth => "Width in pixels of column holding keys"
                                 }
                                 

setIcon(s::TreeView, path::Vector{Int}, icon::Icon) = setIcon(s.toolkit, s, path, icon)
setIcon(s::TreeView, path::Vector{Int}, icon::Symbol) = setIcon(s, path, StockIcon(icon, s[:icontheme]))
setIcon(s::TreeView, path::Vector{Int}, icon::String) = setIcon(s, path, FileIcon(icon))
    

## svg device

## html device

## XXX document main methods with objects
## XXX add destroy method for windows
## XXX add destroy handler
## XXX push!(child) shortcut to push!(child.parent, child)
## XXX delete! not splice!
