
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

## `:focus` can be used to set the focus on a control
getFocus(o::Widget) = getFocus(o.toolkit, o)
setFocus(o::Widget, value::Bool) = setFocus(o.toolkit, o, value)

## `:context` is used to pass information to context menus
getContext(o::Widget) = o.attrs[:context]
setContext(o::Widget, ctx) = o.attrs[:context] = ctx

## `:size` controls the size request of a widget. Can be useful for top-level windows
getSize(o::Widget) = getSize(o.toolkit, o)
setSize{T <: Int}(o::Widget, sz::Vector{T}) = setSize(o.toolkit, o, sz)


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
    setSizepolicy(o.toolkit, o, value)

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
        if !(x in [:left, :right, :center, :justify])
            error("x-alignment is one of :left, :right, :center, :justify or nothing.") 
        end
    end    
        if isa(y, Symbol)
            if !(y in [:top, :bottom, :center])
                error("y-alignment is one of :top, :bottom, :center or nothing.") 
            end
        end
    o.attrs[:alignment] = value

    ## not enough to use which, as it shows -- not returns.
    if length(methods(setAlignment, map(typeof, (o.toolkit, o, value)))) > 0
        setAlignment(o.toolkit, o, value)
    end
       
end
## for box containers, (not tcltk, but Qt)
getStretch(o::Widget) = haskey(o.attrs, :stretch) ? o.attrs[:stretch] : 0
setStretch(o::Widget, stretch::Int) = o.attrs[:stretch] = stretch

## icontheme
getIcontheme(o::Widget) = getIcontheme(o.parent)
getIcontheme(o::Window) = o.attrs[:icontheme]
setIcontheme(o::Widget, value::Symbol) = setIcontheme(o.parent, value)
setIcontheme(o::Window, value::Symbol) = o.attrs[:icontheme] = value

## get widget. Mostly just obj.o, but there may be exceptions
getWidget(o::Widget) = getWidget(o.toolkit, o)
getBlockt(o::Widget) = getBlock(o.toolkit, o)

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
connect(o::WidgetModel, signal::String, obj, slot::Function) = connect(o.model, signal, obj, slot)
connect(o::WidgetModel, signal::Symbol, obj, slot::Function) = connect(o, string(signal), obj, slot)
connect(o::WidgetModel, signal::String, slot::Function) = connect(o.model, signal, nothing, slot)
connect(o::WidgetModel, signal::Symbol, slot::Function) = connect(o, string(signal), slot)
connect(slot::Function, o::WidgetModel, signal::Union(Symbol, String)) = connect(o, signal, slot)


disconnect(o::WidgetModel, id::String) = disconnect(o.model, id)

notify(o::WidgetModel, signal::String, args...) = notify(o.model, signal, args...)
notify(o::WidgetModel, signal::Symbol, args...) = notify(o, string(signal), args...)


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
function label(parent::Container, model::Model; kwargs...)
    widget, block = label(parent.toolkit, parent, model)
    obj = Label(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
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
function button(parent::Container, model::Model; kwargs...)
    widget, block = button(parent.toolkit, parent, model)
    obj = Button(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
button(parent::Container, value::String; kwargs...) = button(parent, ItemModel(value); kwargs...)
button(parent::Container, value::Number; kwargs...) = button(parent, string(value); kwargs...)

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
setIcon(object::Button, nm::Nothing) = setIcon(object.toolkit, object, StockIcon(nothing, nothing))

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
## * `focusIn`  called on focus in event
## * `focusOut` (value) called on focus out event
## * `textChanged` (key) called on each keystroke
## * `valueChanged` (value) called on each change, even keystrokes
##
## TODO
## * typeahead values
## * validation
## * undo/redo stack
## ...
function lineedit(parent::Container, model::Model; coerce::Union(Nothing, Function)=nothing, kwargs...)
    widget, block = lineedit(parent.toolkit, parent, model)
    obj = LineEdit(widget, block, model, parent, parent.toolkit, coerce, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
lineedit(parent::Container, value::String; kwargs...) = lineedit(parent, ItemModel(value); kwargs...)
lineedit(parent::Container, value::Number; kwargs...) = lineedit(parent, string(value); kwargs...)
lineedit(parent::Container; kwargs...) = lineedit(parent, ""; kwargs...)

## Call coerce if present. If can't be coerced, returns nothing
function getValue(obj::LineEdit)
    val = getValue(obj.model)
    isa(obj.coerce, Nothing) ? val : try obj.coerce(string(val)) catch e nothing end
end

## placeholder text
getPlaceholdertext(obj::LineEdit) = obj.attrs[:placeholdertext]
function setPlaceholdertext(obj::LineEdit, txt::String)
    obj.attrs[:placeholdertext] = txt
    notify(obj.model, "placeholderTextChanged", txt)
end

## typeahead
setTypeahead{T<:String}(obj::LineEdit, items::Vector{T}) = setTypeahead(obj.toolkit, obj, items)

list_props(::@PROP("LineEdit")) = {:placeholdertext => "Text to display when widget has no value and no focus.",
                                   :typeahead => "Items to use for type ahead suggestions (Qt only)"
                                   }

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
## * `focusIn`  called on focus out event
## * `focusOut` (value) called on focus out event
## * `textChanged` (key) called on each keystroke
## * `valueChanged` (value) called on each change, even keystrokes
## * 
## TODO:
## * set size
## * to add text not just replace
## * get just the selection
## * selection changed signal
## * ...
function textedit(parent::Container, model::Model; kwargs...)
    widget, block = textedit(parent.toolkit, parent, model)
    obj = TextEdit(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
textedit(parent::Container, value::String; kwargs...) = textedit(parent, ItemModel(value); kwargs...)
textedit(parent::Container, value::Number; kwargs...) = textedit(parent, string(value); kwargs...)
textedit(parent::Container; kwargs...) = textedit(parent, ""; kwargs...)

## add to textedit via push!
push!(o::TextEdit, value) = push_textedit(o.toolkit, o, value)

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
function checkbox(parent::Container, model::Model, label::Union(Nothing, String); kwargs...)
    widget, block = checkbox(parent.toolkit, parent, model, label)
    obj = CheckBox(widget, block, model, parent, parent.toolkit, Dict())
    obj[:label] = label
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function checkbox(parent::Container, value::Bool, label::Union(Nothing, String); kwargs... )
    model=ItemModel(value)
    checkbox(parent, model, label; kwargs...)
end
    
checkbox(parent::Container, value::Bool; kwargs...) = checkbox(parent, value, nothing; kwargs...)
checkbox(parent::Container, label::String; kwargs...) = checkbox(parent, true, label; kwargs...)

getLabel(o::CheckBox) =  o.attrs[:label]
function setLabel(o::CheckBox, value::String) 
    o.attrs[:label] = value
    setLabel(o.toolkit, o, value)
end
setLabel(o::CheckBox, value::Nothing)  = setLabel(o, "")

list_props(::@PROP("CheckBox")) = {:label => "checkbox label"}

##################################################
## 
## WidgetVectorModel is used for selection
##


abstract StrictWidgetVectorModel <: WidgetVectorModel
function setValue(o::StrictWidgetVectorModel, value)
    ## is value in vector?
    if isa(value, Nothing) || any(value .== o[:items])
        setValue(o.model, value)
    end
end

type RadioGroup <: StrictWidgetVectorModel
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
function radiogroup(parent::Container, model::VectorModel; orientation::Symbol=:horizontal, kwargs...)
    widget, block = radiogroup(parent.toolkit, parent, model, orientation=orientation)
    obj = RadioGroup(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function radiogroup(parent::Container, items::Vector, value; orientation::Symbol=:horizontal, kwargs...)
    model = VectorModel(items, value)
    radiogroup(parent, model, orientation=orientation, kwargs...)
end
radiogroup(parent::Container, items::Vector; orientation::Symbol=:horizontal, kwargs...) = radiogroup(parent, items, items[1], orientation=orientation, kwargs...)



type ButtonGroup <: StrictWidgetVectorModel
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
function buttongroup(parent::Container, model::VectorModel; exclusive::Bool=true, kwargs...)
    widget, block = buttongroup(parent.toolkit, parent, model, exclusive=exclusive)
    obj = ButtonGroup(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function buttongroup(parent::Container, items::Vector, value; exclusive::Bool=true, kwargs...)
    if !exclusive && !isa(value, Nothing)
        if !isa(value, Vector)
            value = [value]
        end
    end
    model = VectorModel(items, value)
    buttongroup(parent, model, exclusive=exclusive, kwargs...)
end
buttongroup(parent::Container, items::Vector; exclusive::Bool=true, kwargs...) = buttongroup(parent, items, nothing, exclusive=exclusive, kwargs...)


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
function combobox(parent::Container, model::VectorModel; editable::Bool=false, kwargs...)
    widget, block = combobox(parent.toolkit, parent, model, editable=editable)
    obj = ComboBox(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function combobox(parent::Container, items::Vector, value; editable::Bool=false, kwargs...)
    model = VectorModel(items, value)
    combobox(parent, model, editable=editable, kwargs...)
end
combobox(parent::Container, items::Vector; editable::Bool=false, kwargs...) = combobox(parent, items, nothing, editable=editable, kwargs...)




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
## Notes:
## use cb[:value] = nothing to deselect all 
function slider(parent::Container, model::VectorModel; orientation::Symbol=:horizontal, kwargs...)
    widget, block = slider(parent.toolkit, parent, model, orientation=orientation)
    obj = Slider(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
function slider(parent::Container, items::Vector, value::Int=1; orientation::Symbol=:horizontal,kwargs...)
    model = VectorModel(sort(items), value)
    slider(parent, model, orientation=orientation, kwargs...)
end
function slider(parent::Container, items::Vector; orientation::Symbol=:horizontal, kwargs...)
    items = sort(items)
    model = VectorModel(items, 1)
    slider(parent, model, orientation=orientation, kwargs...)
end

slider(parent::Container, items::Union(Range, Range1,Ranges), value::Int=1; orientation::Symbol=:horizontal, kwargs...) =
    slider(parent, [items], value; orientation=orientation, kwargs...)
slider(parent::Container, items::Union(Range, Range1,Ranges); orientation::Symbol=:horizontal, kwargs...) =
    slider(parent, [items]; orientation=orientation, kwargs...)

    
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
function slider2d(parent::Container, items1::Union(Range, Range1,Ranges), items2::Union(Range, Range1,Ranges); kwargs...) 
    model = TwoDSliderModel(items1, items2)
    widget, block = slider2d(parent.toolkit, parent, model)

    obj = Slider2D(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
## get and set value override
getValue(widget::Slider2D) = getValue(widget.toolkit, widget)
setValue(widget::Slider2D, value) = setValue(widget.toolkit, widget, value)


## spinbox: integer or real
type SpinBox <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end    
  
## Spinbox
##
## widget used to collect numeric information from a specifed range
##
## Arguments:
##
## * `rng` a range of type `1:10` (Range1) or `0:pi/10:pi` (Range)
##
## Signals:
##
## * `valueChanged (value)` is called when spinbox is updated
##  
function spinbox(parent::Container, model::Model, rng::Union(Range, Range1,Ranges); kwargs...)
    widget, block = spinbox(parent.toolkit, parent, model, rng)
    obj = SpinBox(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj.attrs[:range] = rng
    obj
end
spinbox(parent::Container, rng::Union(Range, Range1); kwargs...) = spinbox(parent, ItemModel(rng.start), rng; kwargs...)

## XXX deprecate (issue with integer vs. real...)
##setRange(obj::SpinBox, value) = setRange(obj.toolkit, obj, value)
##list_props(::@PROP("SpinBox")) = {:range => "Range to select values from"}

##################################################
##
## Graphics


## CairoGraphics (for Winston)
type CairoGraphics <: WidgetModel
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
## The context is [x,y] in relative pixel coordinates
## TODO:
##
function cairographic(parent::Widget; width::Int=480, height::Int=400, kwargs...)
    model = EventModel()  # for event handling
    widget, block = cairographic(parent.toolkit, parent, model, width=width, height=height)
    obj = CairoGraphics(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end


##################################################
## 
## Images


type ImageView <: Widget
    o
    block
    parent
    toolkit
    attrs
end

## Image viewer
##
## Widget to hold an image
##
## Arguments:
##
## * `img`: if specified, an image file name
##
## Signals:
##
## 
function imageview(parent::Container, img::Union(Nothing, String); kwargs...)
    widget, block = imageview(parent.toolkit, parent)
    obj = ImageView(widget, block, parent, parent.toolkit, Dict())
    if !isa(img, Nothing) obj[:image] = img end
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
imageview(parent::Container; kwargs...) = imageview(parent, nothing; kwargs...)

function setImage(o::ImageView, img::String)
    if isfile(img)
        o.attrs[:image] = img
        setImage(o.toolkit, o, img)
    end
end
list_props(::@PROP("ImageView")) = {:image => "filename of image"}

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
## * `clicked, i,j`
## * `doubleClicked, i, j`
## * `headerClicked, j`
## 
## TODO: add activated signal
##
## Methods:
##
## getValue returns selected items
## getIndex: return index (:single) or [indices] (:multiple)
function storeview(parent::Container, store::Store; tpl=nothing, selectmode::Symbol=:single, kwargs...)
    model = ItemModel()         # for selection
    widget, block = storeview(parent.toolkit, parent, store, model)
    obj = StoreView(widget, block, store, model, parent, parent.toolkit, Dict())

    ## default properties, can be overridden
    obj[:sizepolicy] = (:expand, :expand)
    obj[:selectmode] = selectmode
    obj[:rownamesvisible] = false

    for (k, v) in kwargs
        obj[k] = v
    end
    obj
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
getHeadervisible(s::StoreView) = setHeadervisible(s.toolkit, s)
setHeadervisible(s::StoreView, visible::Bool) = setHeadervisible(s.toolkit, s, visible)
getRownamesvisible(s::StoreView) = setRownamesvisible(s.toolkit, s)
setRownamesvisible(s::StoreView, visible::Bool) = setRownamesvisible(s.toolkit, s, visible)

getSelectmode(s::ModelView) = getSelectmode(s.toolkit, s)
function setSelectmode(s::ModelView, val::Symbol)
    if any(val .== [:single, :multiple])
        setSelectmode(s.toolkit, s, val)
    end
end
getWidths(s::ModelView) = getWidths(s.toolkit, s)
setWidths(s::ModelView, widths::Vector{Int}) = setWidths(s.toolkit, s, widths)
setWidths(s::ModelView, widths::Int) = setWidths(s, [widths])
getHeights(s::ModelView) = getHeights(s.toolkit, s)
setHeights(s::ModelView, heights::Vector{Int}) = setHeights(s.toolkit, s, heights)
setHeights(s::ModelView, heights::Int) = setHeights(s, [heights])

setIcon(s::StoreView, i::Int, icon::Icon) = setIcon(s.toolkit, s, i, icon)
setIcon(s::StoreView, i::Int, icon::Symbol) = setIcon(s, i, StockIcon(icon, s[:icontheme]))
setIcon(s::StoreView, i::Int, icon::String) = setIcon(s, i, FileIcon(icon))
    

list_props(::@PROP("ModelView")) = {:selectmode => "Either :single or :multiple",
                                    :widths => "Vector of column widths, in pixels",
                                    :heights => "Vector of row heights, in pixels"
                                    }

list_props(::@PROP("StoreView")) = {:headervisible => "Adjust if headers are displayed (if possible)",
                                    :rownamesvisible => "Adjust if rownames are displayed (if possible)",
}

## methods
insert!(s::StoreView, i::Int, val)   = insert!(s.store, i, val)
push!(s::StoreView, val)             = push!(s.store, val)
unshift!(s::StoreView, val)          = prepend!(s.store, val)
append!(s::StoreView, vals::Vector)  = append!(s.store, vals)
splice!(s::StoreView, i::Int)        = splice!(s.store, i)
pop!(s::StoreView)                   = splice!(s.store, length(s))
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
function listview(parent::Container, items::Vector; selectmode::Symbol=:single, kwargs...)
    items =  map(x -> ListItem(x), items)
    store = Store{ListItem}(items)

    obj = storeview(parent, store, selectmode=selectmode)
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

##################################################
### Tree

type TreeView <: ModelView
    o
    block
    store
    model
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
## * `valueChanged (value)` gives selected path
##
## * `nodeExpand (path)` gives path when node expands
##
## * `nodeCollapsed (path)` gives path when node expands
##
## * `clicked (path, column)` gives path and column user clicks on
## 
## * `doubleClicked(path, column)` gives path and column user clicks on
##
## Notes:
## There are two models: one for the store where we can insert! and friends and one for the widget
## where the valueChanged, nodeExpand, ... are held. These are not shared between views of the same model
function treeview(parent::Container, store::TreeStore; tpl=nothing, kwargs...)
    model = ItemModel()
    widget, block = treeview(parent.toolkit, parent, store, model; tpl=tpl)
    obj = TreeView(widget, block, store, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

## properties
getKeywidth(tr::TreeView) = getKeywidth(tr.toolkit, tr)
setKeywidth(tr::TreeView, width::Int) = setKeywidth(tr.toolkit, tr, width)
list_props(::@PROP("TreeView")) = {:keywidth => "Width in pixels of column holding keys"
                                 }
                                 

setIcon(s::TreeView, path::Vector{Int}, icon::Icon) = setIcon(s.toolkit, s, path, icon)
setIcon(s::TreeView, path::Vector{Int}, icon::Symbol) = setIcon(s, path, StockIcon(icon, s[:icontheme]))
setIcon(s::TreeView, path::Vector{Int}, icon::String) = setIcon(s, path, FileIcon(icon))
    
## expand the node is a view property, not model
expand_node(view::TreeView, node::TreeNode) = notify(view.model, "expandNode", node)
collapse_node(view::TreeView, node::TreeNode) = notify(view.model, "collapseNode", node)

## svg device

## html device

## XXX document main methods with objects
## XXX add destroy method for windows
## XXX add destroy handler
## XXX push!(child) shortcut to push!(child.parent, child)
## XXX delete! not splice!
