## General Widget properties

## :value is the main value
@doc "get the `:value` property, the primary value for a control" ->
getValue(o::WidgetModel) = getValue(o.model)

@doc """
Set the `:value` property, the primary value for a control

The `signal::Bool` argument indicates if any events should be signalled.

""" ->
function setValue(o::WidgetModel, value; signal::Bool=true) 
    setValue(o.model, value; signal=signal)
end

## :items is use for vector models to provide the items to select from
@doc """
Get the `:items` property. Used by widgets with VectorModels -- that
is, those widgets which are used to select 0, 1 or more from a
collection.
""" ->
getItems(o::WidgetVectorModel) = getItems(o.model)

@doc "set the `:items` property" ->
setItems(o::WidgetVectorModel, value) = setItems(o.model, value)

## :enabled indicates if a widget is sensitive to user input
@doc "Get the `:enabled` property. This indicates if a widget is sensitive (or not) to user input" ->
getEnabled(o::Widget) = getEnabled(o.toolkit, o)

@doc "Set the `:enabled` property. This indicates if a widget is sensitive (or not) to user input" ->
setEnabled(o::Widget, value::Bool) = setEnabled(o.toolkit, o, value)

## :visible indicates if a widget is drawn to the screen
@doc "Get the `:visible` property. Indicates if a widget is shown" ->
getVisible(o::Widget) = getVisible(o.toolkit, o)

@doc "Set the `:visible` property. Indicates if a widget is shown" ->
setVisible(o::Widget, value::Bool) = setVisible(o.toolkit, o, value)


## :focus inidicates if a control has keyboard focus
@doc "Get the `:focus` property" ->
getFocus(o::Widget) = getFocus(o.toolkit, o)

@doc "Set the `:focus` property. The control with focus receive keyboard input" ->
setFocus(o::Widget, value::Bool) = setFocus(o.toolkit, o, value)

@doc "Get the `:context` property. Context used to pass information to context menus" ->
getContext(o::Widget) = o.attrs[:context]

@doc "Set the `:context` property. Contextis used to pass information to context menus" ->
setContext(o::Widget, ctx) = o.attrs[:context] = ctx

@doc "Get the `:size` property. Indicates the size request of a widget. Can be useful for top-level windows" ->
getSize(o::Widget) = getSize(o.toolkit, o)

@doc "Set the `:size` property. Indicates the size request of a widget. Specified by a `Int[w,h]`" ->
setSize{T <: Int}(o::Widget, sz::Vector{T}) = setSize(o.toolkit, o, sz)



@doc """
Get the `:sizepolicy` property.

The `:sizepolicy` determines how a widget expands to fill its allocated
space.  The value is specified as a tuple (x,y) with each being be
one of `:fixed`, `:expand`, or `nothing`.
""" ->
function getSizepolicy(o::Widget)
    if haskey(o.attrs, :sizepolicy)
        o.attrs[:sizepolicy]
    else
        (nothing, nothing)
    end
end

@doc "set the `:sizepolicy` property" ->
function setSizepolicy(o::Widget, value)
    ## must have proper policy (nothing, :fixed, :expand)
    x, y = value
    ## check
    setSizepolicy(o.toolkit, o, value)

end

@doc """
Get the `:alignment` property.

The `:alignment` property is used to determine how a control is aligned in its
allocated space. The value is specified as a tuple of the form  (xalign, yalign)
with

- xalign in (:left, :right, :center, :justify) 
- yalign one of (:top, :bottom, :center)
""" ->
function getAlignment(o::Widget) 
    if haskey(o.attrs, :alignment)
        o.attrs[:alignment]
    else
        (nothing, nothing)
    end
end

@doc "Set the `:alignment` property" ->
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
@doc "Get the `:stretch` property for a widget. XXX" ->
getStretch(o::Widget) = haskey(o.attrs, :stretch) ? o.attrs[:stretch] : 0

@doc "Set then `:stretch` property for a widget. XXX" ->
setStretch(o::Widget, stretch::Int) = o.attrs[:stretch] = stretch

## icontheme
@doc "Get the `:icontheme` property for a widget. Not yet implemented" ->
getIcontheme(o::Widget) = getIcontheme(o.parent)
getIcontheme(o::Window) = o.attrs[:icontheme]

@doc "Set the `:icontheme` property for a widget. Not yet implemented" ->
setIcontheme(o::Widget, value::Symbol) = setIcontheme(o.parent, value)
setIcontheme(o::Window, value::Symbol) = o.attrs[:icontheme] = value

## get widget. Mostly just obj.o, but there may be exceptions
getWidget(o::Widget) = getWidget(o.toolkit, o)
getBlock(o::Widget) = getBlock(o.toolkit, o)

## list Widget properties
@doc """
List properties available for a  widget

The properties are retrieved and set using indexing notation, where the property is specified through
a symbol, as in `:size` or `:enabled`. 

The underlying toolkits provide significantly more properties to control a widgets display or behaviour.
""" ->
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

@doc """
Basic label widget

## Arguments:
* `parent::Container` parent container
* `value::Union(ItemModel, String)` either a model (for sharing) or string.

## Signals:
* `valueChanged (value)` called when label text is updated.

## Example:
```julia
w = window(title="label")
l = label(w, "label")
push!(w, l)
l[:value] = "new label"
```

""" ->
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
setValue(o::Label, value::Number; signal::Bool=true) = setValue(o, string(value); signal=signal)

## Separator
type Separator <: Style
    o
    block
    parent
    toolkit
    attrs
end

@doc """
Add a horizontal or vertical line to a layout

## Arguments:
* `orientation::Symbol` one of `:horizontal` (default) or `:vertical`

## Example
```julia
w = window(title="separator")
g = vbox(w); push!(w, g)
l1 = label(g, "top label")
s = separator(g)
l2 = label(g, "bottom label")
append!(g, [l1, s, l2])
```


""" ->
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

@doc """
Primary control to initiate an action

## Arguments:
* `parent::Container` a parent container
* `value::Union(ItemModel, String)` If a model, value is shared. If a string, used as label

## Signals:
* `clicked ()`: called when clicked
* `valueChanged (value)`: called when label is changed

## Examples:

```julia
w = window(title="buttons")
g = vbox(w); push!(w, g)
b1 = button(g, "click me")
push!(g, b1)
connect(b1, :clicked, () -> b1[:value] = "that tickled")
```

""" ->
function button(parent::Container, model::Model; kwargs...)
    widget, block = button(parent.toolkit, parent, model)
    obj = Button(widget, block, model,  parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end
button(parent::Container, value::String; kwargs...) = button(parent, ItemModel(value); kwargs...)
button(parent::Container, value::Number; kwargs...) = button(parent, string(value); kwargs...)

@doc "Set `:icon` property for a button. Icon specified by `Icon`, symbol or string." ->
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

@doc """
Single line text entry

## Arguments:
* `value` is an item model (for sharing) or a string or a number
* `coerce` is a function to be called on the string value in the edit
box before getValue. Even if a number is specified as the value,
the return will be a string unless coerced.

## Signals:
* `editingFinished` (value) called when <return> key is pressed or blur
* `focusIn`  called on focus in event
* `focusOut` (value) called on focus out event
* `textChanged` (key) called on each keystroke
* `valueChanged` (value) called on each change, even keystrokes

## TODO
* typeahead values
* validation
* undo/redo stack
* ...

## Examples
```julia
w = window(title="lineedit")
f = formlayout(w); push!(w, f)

le1 = lineedit(f, "test")
push!(f, le1, "vanilla")

le2 = lineedit(f, "")
le2[:typeahead] = ["one", "two", "three"]
push!(f, le2, "typeahead")

le3 = lineedit(f, "", placeholdertext="write something here")
push!(f, le3, "placeholder")

le4 = lineedit(f, "", placeholdertext="type here to get echo")
connect(le4, :textChanged) do key
    println("Typed", key)
end
push!(f, le4, "echo")
```

""" ->
function lineedit(parent::Container, model::Model; coerce::Union(Nothing, Function)=nothing, kwargs...)
    widget, block = lineedit(parent.toolkit, parent, model)


    obj = LineEdit(widget, block, model,  parent, parent.toolkit, coerce, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end

    obj
end
lineedit(parent::Container, value::String=""; kwargs...) = lineedit(parent, ItemModel(value); kwargs...)
lineedit(parent::Container, value::Number; kwargs...) = lineedit(parent, string(value); kwargs...)

function setValue(obj::LineEdit, value; signal::Bool=true) 
    value = string(value)
    if !isa(obj.coerce, Nothing)
        value = string(obj.coerce(value))
    end
    setValue(obj.model, value ; signal=signal)
end

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

@doc """
Multi-line text edit box

Text can be changed by setting the `:value` property. To append text, use `push!`.


## Arguments:
* `parent::Container`: parent container
* `value::Union(ItemModel, String)`: inital string or an `ItemModel` to share

## Signals:
* `activated` (value) called when blur occurs
* `focusIn`  called on focus out event
* `focusOut` (value) called on focus out event
* `textChanged` (key) called on each keystroke
* `valueChanged` (value) called on each change, even keystrokes
* 

## TODO:
* set size, font, ...
* get just the selection
* selection changed signal
* ...

## Examples:
```julia
w = window()
t = textedit(w, "")
t[:value] = "Some new text"
push!(w, t)

connect(t, :focusIn, () -> println("Text edit got focus"))
```


""" ->
function textedit(parent::Container, model::Model; kwargs...)
    widget, block = textedit(parent.toolkit, parent, model)

    obj = TextEdit(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end

    obj
end
textedit(parent::Container, value::String=""; kwargs...) = textedit(parent, ItemModel(value); kwargs...)
textedit(parent::Container, value::Number; kwargs...) = textedit(parent, string(value); kwargs...)

## some presumably common things of interest
setValue(obj::TextEdit, value::Vector) = setValue(obj, join(map(string, value), "\n"))
setValue(obj::TextEdit, value::Number) = setValue(obj, string(value))


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

@doc """
standard toggle for true/false values. Optional label.

## Arguments:

 * `value::Bool` initial state of widget
 * `label::MaybeString` optional label

## Signals:

 * `valueChanged (value)` called when widget toggles state.

## Examples:

```julia
w = window(title="checkbox")
cb = checkbox(w, true, "Check me, please")
push!(w, cb)
connect(cb, :valueChanged) do value
    println("Changed to ", value)
end
```

""" ->
function checkbox(parent::Container, model::Model, label::Union(Nothing, String); kwargs...)
    widget, block = checkbox(parent.toolkit, parent, model, label)
    obj = CheckBox(widget, block, model, parent, parent.toolkit, Dict())
    obj[:label] = label
    for (k, v) in kwargs
        obj[k] = v
    end

    obj
end

function checkbox(parent::Container, value::Bool=true, label::Union(Nothing, String)=nothing; kwargs... )
    model=ItemModel(value)
    checkbox(parent, model, label; kwargs...)
end

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
function setValue(o::StrictWidgetVectorModel, value; signal::Bool=true)
    ## is value in vector?
    if isa(value, Nothing) || any(value .== o[:items])
        setValue(o.model, value; signal=signal)
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

@doc """
Radio button group

Value, not index, is used to store state.

## Arguments:
* `items`: items to choose from
* `value=items[1]`: initial value for selection
* `orientation::Symbol=:horizontal` (or `:vertical`).

## Signals:
* `valueChanged (value)` called when selected value is updated

## TODO
* how to set items to be selected? (need `setItems` method)

## Examples
```julia
w = window(title="radiogroup")
items = ["one", "two", "three"]
rg = radiogroup(w, items)
push!(w, rg)
connect(rg, :valueChanged, val -> println(val))
rg[:value] = "two"
```

""" ->
function radiogroup(parent::Container, model::VectorModel; orientation::Symbol=:horizontal, kwargs...)
    widget, block = radiogroup(parent.toolkit, parent, model, orientation=orientation)
    obj = RadioGroup(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function radiogroup(parent::Container, items::Union(Range,Vector), value=items[1]; orientation::Symbol=:horizontal, kwargs...)
    model = VectorModel(items, value)
    radiogroup(parent, model, orientation=orientation, kwargs...)
end



type ButtonGroup <: StrictWidgetVectorModel
    o
    block
    model
    parent
    toolkit
    attrs
end

@doc """ 

A buttongroup is like a radio group with toggle buttons
(toolbar style). The group can be exclusive (one selected only) or not

Call as `buttongroup(parent, items)` or `buttongroup(parent, items, initialselection)`.

## Arguments:

* `exclusive::Bool` if `true` (the default), then like a radio
   group. Otherwise can select zero, one or more of the buttons.

## Signals

* `valueChanged (value)` when a button is toggled

## TODO

* `setItems` method

## Examples
```julia
w = window(title="buttongroup")
f = formlayout(w); push!(w, f)

ebg = buttongroup(f, ["one", "two", "three"], "one")
push!(f, ebg, "exclusive")

nebg = buttongroup(f, ["one", "two", "three"], exclusive=false)
push!(f, nebg, "non-exclusive")

b = button(f, "print values")
connect(b, :clicked, () -> println("Exclusive:", ebg[:value], "\nNon-exclusive: ", nebg[:value]))
push!(f, b, "")

```
""" ->
function buttongroup(parent::Container, model::VectorModel; exclusive::Bool=true, kwargs...)
    widget, block = buttongroup(parent.toolkit, parent, model, exclusive=exclusive)
    obj = ButtonGroup(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj.attrs[:exclusive] = exclusive
    obj
end

function buttongroup{T <: String}(parent::Container, items::Vector{T}, value=nothing; 
                                  exclusive::Bool=true, kwargs...)
    if !exclusive
        if value == nothing 
            value = String[] 
        end
        if !isa(value, Vector) value = [value] end
    end
    
    model = VectorModel(items, value)
    buttongroup(parent, model, exclusive=exclusive, kwargs...)
end

## set by label
setValue{T <: String}(obj::ButtonGroup, values::Vector{T}) = (obj.model[:value] = map(string, values))

## combobox
type ComboBox <:  WidgetVectorModel
    o
    block
    model
    parent
    toolkit
    attrs
end

@doc """
Combobox


Arguments:

* `parent::Container` parent container `model::VectorModel` model
* (more conveniently items and value can be specifed). The `value`
  defaults to `items[1]`.  
* `editable::Bool` if true, create editable combobox.


Signals:

* `valueChanged (value)` called when combobox is update

TODO:

* `:editable=true` (will add `editingFinished` signal

## Examples
```julia
w = window(title="combobox")
f = formlayout(w); push!(w, f)
xs = ["one", "two", "three"]

cb1 = combobox(f, xs)
push!(f, cb1, "non-editable")

cb2 = combobox(f, xs, editable=true)
push!(f, cb2, "editable")

b = button(f, "values")
push!(f, b, "")

connect(b, :clicked) do
    println("non-editable: ", cb1[:value])
    println("editable: ", cb2[:value])
end
```
""" ->
function combobox(parent::Container, model::VectorModel; editable::Bool=false, kwargs...)
    widget, block = combobox(parent.toolkit, parent, model, editable=editable)
   
    obj = ComboBox(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

function combobox(parent::Container, items::Vector, value=items[1]; editable::Bool=false, kwargs...)
    model = VectorModel(items, value)
    combobox(parent, model, editable=editable, kwargs...)
end




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

@doc """
Slider widget

Slider values are specified as a vector (not a from/to/by specification).

## Arguments:

* `model::VectorModel` a model containing value and vector information. The value is the index of the vector.
* `orientation::Sybol=:horizontal` orientation of slider when rendered
* `items::Vector` vector of items, sortable.
* `items::Range` Range of items to scroll through
* `value::Int` index of initially selected item

## Signals:

* `valueChanged (value)` return value in vector that is selected

## Notes:
use cb[:value] = nothing to deselect all 

## Examples:
```julia
w = window(title="slider")
g = grid(w); push!(w, g)
slh = slider(g, 1:100, size=[200, -1])
g[1,1] = slh

slv = slider(g, 1:100, orientation=:vertical)
slv[:size] = [-1, 200]
g[1:2, 2] = slv

connect(slh, :valueChanged, value -> println(value))
""" ->
function slider(parent::Container, model::VectorModel; orientation::Symbol=:horizontal, kwargs...)
    widget, block = slider(parent.toolkit, parent, model, orientation=orientation)
    obj = Slider(widget, block, model, parent, parent.toolkit, {:orientation=>orientation})

    for (k, v) in kwargs
        obj[k] = v
    end

    obj
end
function slider(parent::Container, items::Vector, value::Int=1; orientation::Symbol=:horizontal,kwargs...)
    model = VectorModel(sort(items), value)
    slider(parent, model; orientation=orientation, kwargs...)
end
function slider(parent::Container, items::Vector; orientation::Symbol=:horizontal, kwargs...)
    items = sort(items)
    model = VectorModel(items, 1)
    slider(parent, model; orientation=orientation, kwargs...)
end

slider(parent::Container, items::Range, value::Int=1; orientation::Symbol=:horizontal, kwargs...) =
    slider(parent, [items], value; orientation=orientation, kwargs...)
slider(parent::Container, items::Range; orientation::Symbol=:horizontal, kwargs...) =
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

@doc """
Two dimensional slider

From Mathematica's mnaipulate feature. Provides a slider for moving x and y simultaneously. Not implemented in `Gtk.jl`.

## Arguments:

* `items1` and `items2` are ranges to choose from

## Signals:

* `valueChanged (value)` is called when slider is moved. The value are [x,y] coordinates

## Examples:
```julia
if !JGUI.isgtk()
  w = window(title="2dslider")
  sl2 = slider2d(w, 1:100, 1:100)
  push!(w, sl2)
  connect(sl2, :valueChanged, value -> println(value))
end
```
""" ->
function slider2d(parent::Container, items1::Range, items2::Range; kwargs...) 
    model = TwoDSliderModel([items1], [items2])
    widget, block = slider2d(parent.toolkit, parent, model)

    obj = Slider2D(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

## get and set value override
getValue(widget::Slider2D) = getValue(widget.toolkit, widget)
setValue{T<:Number}(widget::Slider2D, value::Vector{T}; signal::Bool=true) = setValue(widget.toolkit, widget, value; signal=signal)


## spinbox: integer or real
type SpinBox <: WidgetModel
    o
    block
    model
    parent
    toolkit
    attrs
end    

@doc """  
Spinbox

Widget used to collect numeric information from a specifed range

## Arguments:

* `rng` a range of type `1:10` (Range1) or `0:pi/10:pi` (Range)

## Signals:

* `valueChanged (value)` is called when spinbox is updated
 
## Examples:
```julia
w = window(title="spinbox")
sp = spinbox(w, 1:100)
push!(w, sp)

connect(sp, :valueChanged, value -> println(value))
```
""" ->
function spinbox(parent::Container, model::Model, rng::Range; kwargs...)
    widget, block = spinbox(parent.toolkit, parent, model, rng)
    obj = SpinBox(widget, block, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj.attrs[:range] = rng
    obj
end
spinbox(parent::Container, rng::Range; kwargs...) = spinbox(parent, ItemModel(start(rng)), rng; kwargs...)

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

@doc """
Cairo graphics device for use with Winston graphics, say.

Not available with `Qt`.

Can be called with Winston.display(widget.o, p) 

## Arguments:

## Signals:
* `mousePress (x,y)`
* `mouseRelease (x,y)`
* `mouseDoubleClick (x,y)`
* `keyPress (key)`
* `keyRelease (key)`
* `mouseMotion (x,y)`
* `mouseMove (x, y)`

The context is [x,y] in relative pixel coordinates

## TODO:

* improve interface. (Possible: `push!(cg, p)`)

## Examples:
```julia
if !JGUI.isqt()
  using Winston
  p = plot(sin, 0, 2pi);        # suppress drawing with ";"

  w = window(title="cairographic")
  cg = cairographic(w, size=[480, 400])
  push!(w, cg)
  Winston.display(cg.o, p)
end
```
""" ->
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

@doc """
Widget to display images

## Arguments:

* `img`: if specified, an image file name

Signals:

## Examples
```julia
w = window(title="image")
img = imageview(w)
push!(w, img)
if !JGUI.istk()
    ## tk does not like png files, just .gif or .jpg
    img[:image] = Pkg.dir("JGUI", "icons","default", "car.png")
end
```

""" ->
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

@doc """

A storeview shows a set of items, where each items is displayed as a row.


## Arguments:

* `parent::Container` parent container

* `store::Store` a data store. 

* `selectmode in [:single, :multiple]

## Signals:

* `selectionChanged value` (indices)
* `rowInserted, i`
* `rowRemoved, i`
* `clicked, i,j`
* `doubleClicked, i, j`
* `headerClicked, j`

## TODO: add activated signal

## Methods:

getValue returns selected items as rows
getIndex: return index (:single) or [indices] (:multiple)
setIndex: use 0 (:single) to clear, Int[] (:multiple) to clear, 
getNames: return Vector{String} of names
setNames: pass `Vector{String}` of names

## Examples
```julia
## Create a store
store = Store(String, Float64)
push!(store, ("one", 1.0))
push!(store, ("two", 2.0))
push!(store, ("three", 3.0))
insert!(store, 3, ("two and a half", 2.5))

## display the store
w = window(title="storeview")
sv = storeview(w, store)
push!(w, sv)

connect(sv, :selectionChanged, indices -> println(indices)) ## failing on Gtk.selected
```

""" ->
function storeview(parent::Container, store::Store; selectmode::Symbol=:single, kwargs...)
    model = ItemModel([0])         # for selection
    widget, block = storeview(parent.toolkit, parent, store, model)
    obj = StoreView(widget, block, store, model, parent, parent.toolkit, Dict())

    ## default properties, can be overridden
    obj[:sizepolicy] = (:expand, :expand)
    obj[:selectmode] = selectmode
    obj[:rownamesvisible] = false

    for (k, v) in kwargs
        obj[k] = v
    end

    connect(store.model, "rowInserted") do row
        notify(obj.model, "rowInserted", row)
    end
    connect(store.model, "rowRemoved") do row
        notify(obj.model, "rowRemoved", row)
    end

    obj
end

getindex(s::StoreView, i::Int) = s.store.items[i]
setindex!(s::StoreView, val, i::Int) = replace!(s, i, val)

## Properties
## value is value, but should refer to things by index
function getIndex(s::StoreView)
    val = s.model[:value]
    if s[:selectmode] == :single
        length(val) == 0 && return 0
        return(val[1])
    else
        return(val)
    end
end
function setIndex(s::StoreView, index::Vector{Int}) 
    s.model[:value] = index
end
setIndex(s::StoreView, index::Int)  = setIndex(s, [index])
function getValue(s::StoreView)
    indices = filter(x -> x > 0, s[:index])
    items = s.store.items
    items[collect(indices)]
end
function setValue(s::StoreView, val; signal::Bool=true)
    error("Use storeview[:index] to set by row index")
end
    
## names
getNames(s::ModelView) = getNames(s.toolkit, s)
function setNames{T<:String}(s::StoreView, nms::Vector{T}) 
    @assert length(nms) == size(s.store)[2]
    setNames(s.toolkit, s, nms)
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

@doc """
Listview is a convenience wrapper to `storeview` for displaying a vector of values.

## Arguments:

* `items::Vector` items to select from

* `selectmode::Symbol` which stule of selection

## Signals:

See `storeview`.

## Properties:
`:value` return value or [value] (if :multiple)
`:index` return index or [index] (if :multiple)

## Examples
```julia
w = window(title="listview")
items = ["one", "two", "three"]
lv = listview(w, items)
push!(w, lv)
lv[:names] = ["Numbers"]
```
""" ->
function listview(parent::Container, items::Vector; selectmode::Symbol=:single, kwargs...)
    store = Store(eltype(items))
    for item in items
        push!(store, (item, ))
    end

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

@doc """
treeview widget

## Arguments:

* `parent::Container` parent container

* `store::TreeStore` tree store. Most of action happens with a tree store

* `tpl` optional instance of data type for display. This allows columns to be set up in tree view. If not given, then
the store should have atleast one child node.

## Signals:

* `valueChanged (value)` Selection changes, this passes on selected path

* `activated (value)` Selection is activated, typically double click but may be enter key

* `nodeExpand (path)` gives path when node expands

* `nodeCollapsed (path)` gives path when node expands

* `clicked (path, column)` gives path and column user clicks on

* `doubleClicked(path, column)` gives path and column user clicks on

## Notes:

There are two models: one for the store where we can insert! and friends and one for the widget
where the valueChanged, nodeExpand, ... are held. These are not shared between views of the same model

## Examples
```julia
```

""" ->
function treeview(parent::Container, store::TreeStore;  kwargs...)
    model = ItemModel()
    widget, block = treeview(parent.toolkit, parent, store, model)
    obj = TreeView(widget, block, store, model, parent, parent.toolkit, Dict())
    for (k, v) in kwargs
        obj[k] = v
    end
    obj
end

## properties
## XXX no way to set column of keys...
function setNames{T<:String}(s::TreeView, nms::Vector{T}) 
    @assert length(nms) == length(s.store.types)
    setNames(s.toolkit, s, nms)
end

getKeyname(tr::TreeView) = getKeyname(tr.toolkit, tr)
setKeyname(tr::TreeView, nm::String) = setKeyname(tr.toolkit, tr, nm)

getKeywidth(tr::TreeView) = getKeywidth(tr.toolkit, tr)
setKeywidth(tr::TreeView, width::Int) = setKeywidth(tr.toolkit, tr, width)
list_props(::@PROP("TreeView")) = {:keyname => "Name of column holding keys",
                                   :keywidth => "Width in pixels of column holding keys"
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
