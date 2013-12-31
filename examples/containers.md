This is an example of a GUI for editing some records. The main point
is to illustrate the usage of different containers for layout
purposes, but it also illustrates how we can connect components to
make the user experience a bit easier.

For now, we demonstrate with `Tk`:
```
ENV["toolkit"] = "Tk"
using JGUI
```

A `storeview` widget shows records as rows. A record is nothing more
than an instance of some composite type. This ensures that each column
in the store view has the same type of data, similar to a data
frame. One type we want, is a factor type, where a value is chosen from a given set of levels.
In this example, we don't pull in the `DataFrame` class, rather
we create a rather inefficient means to hold a factor (as each instance keeps the
levels):

```
if !isdefined(:Factor)
    type Factor
        x::Union(Nothing, ASCIIString)
        levels::Vector{ASCIIString}
    end
end
import Base.string
Base.string(x::Factor) = string(x.x)
```


The record is straightforward:

```
if !isdefined(:Record)
    type Record
        name::String
        rank::Factor
        serial::Integer
    end
end
```

We have some simple functions that should be cleaned up for
abstracting the getting and setting of values from the record.

```
set_value!(item::Record, nm, ::Factor, value) = item.(nm).x = value
set_value!(item::Record, nm, ::Any, value) = item.(nm) = value
_get_value(x::Factor) = x.x
_get_value(x) = x
```

We will have use of a blank record:
```
blank_record() = Record("", Factor(nothing, ["General", "Sergeant", "Private"]), 0)
```

Each value in the store view may be edited by row. We could hardcode
the editors, but rather use the more `Julian` multiple dispatch to
pick the editor for us. The basic editor for strings is a line edit widget:

```
function editor(x::String, container; empty::Bool=false)
    widget = lineedit(container, "")
    !empty && (widget[:value] = x)
    widget
end
```

For a factor, where we select a single level from potentially many a combobox is typical. 

```
function editor(x::Factor, container; empty::Bool=false)
    widget = combobox(container, x.levels)
    !empty && (widget[:value] = x.x)
    widget
end
```

Integer values can be edited in different ways. Here we use a line edit widget with coercion to integer:

```
function editor(x::Integer, container; empty::Bool=false)
    widget = lineedit(container, "", coerce=parseint)
    !empty && (widget[:value] = string(x))
    widget
end
```


Okay, with those details out of the way, we illustrate the laying out
of the GUI. This GUI has two panels: one to edit a record and one to
show the records using a store view. We lay these out using the `grid`
container. This container uses matrix notation to specify the layout:

```
w = window()
w[:title] = "Containers"

g = grid(w)
push!(g)

lp = vbox(g)
lp[:sizepolicy] = [:expand, :expand]
rp = vbox(g)

g[1,1] = lp
g[1,2] = rp
```

The `sizepolicy` call instructs the `lp` box container to expand in
both directions if space is available.


In the left panel, we will pack in a `formlayout` wich makes arranging
a widget with a label easy.  First we add the `formlayout` object into
the box container `lp`:

```
fl = formlayout(lp)
push!(lp, fl)
```

We keep track of the editors in a dictionary keyed by the name. The
following loops over the names of a record and makes the corresponding
editor:

```
widgets = Dict()
blank = blank_record()
for i in names(blank)
    x = blank.(i)
    widget = editor(x, fl, empty=true)
    widgets[i] = widget
   push!(fl, widget, string(i))
end
```

We see that widgets are added to a form layout container using `push!`
with a third argument for the label. We next add a button to show that
specifying `nothing` for this third argument suppresses a label:

```
submit_button = button(fl, "submit")
push!(fl, submit_button, nothing)
```

Now to set up the right panel. This will be a store view along with
some buttons to manage the addition and deletion of items.

```
store = Store{Record}([blank_record()])
view = storeview(rp, store, size=[300, 200]) # for Tk
view[:sizepolicy] = [:expand, :expand]
```

We will place the buttons controlling the number of items in a box container.

```
button_group = hbox(rp)
append!(rp, [view, button_group])
```

These buttons use left alignment to push things to the left. A similar
effect can often be achieved with `addstretch`:

```
add_record = button(button_group, "+")
add_record[:alignment] = (:left, nothing)

remove_record = button(button_group, "-")
remove_record[:alignment] = (:left, nothing)

append!(button_group, [add_record, remove_record])
```


Now we connect the various components together. Here we do what is
necessary when we add a record. The basic bit is to add a blank record
to the store. Additionally, we adjust the sensitivity of the other
buttons and then set the focus for edition.

```
connect(add_record, "clicked") do
    item = blank_record()
    push!(store, item)
    view[:index] = length(store)
    ## move focus
    widgets[names(item)[1]][:focus] = true
end
## adjust sensitity of remove button
connect(add_record, "clicked") do
    remove_record[:enabled] = length(store) > 0
    submit_button[:enabled] = length(store) > 0
end
```

In most case, when we remove a record we just want to set the index to
a new record. However, when there are no more records we need to be a
bit more careful. The following wipes clean the editors and sets the
focus to adding a new item.

```
connect(remove_record, "clicked") do
    i = view[:index]
    splice!(store, i)
    if length(store) >= i
        view[:index] = i
    elseif length(store)  > 0
        view[:index] = length(store)
    elseif length(store) == 0
        ## zero out and set focus on add, as this is needed
        item = blank_record()
        for i in names(item)
            val = _get_value(item.(i))
            widgets[i][:value] = val
        end
        add_record[:focus] = true
    end
end
connect(remove_record, "clicked") do
    remove_record[:enabled] = length(store) > 0
    submit_button[:enabled] = length(store) > 0
end
```

When the selection changes on the view, we adjust the editors to match
the currently selected item.

```
connect(view, "selectionChanged") do row
    item = store.items[row[1]]
    for i in names(item)
        val = _get_value(item.(i))
        widgets[i][:value] = val
    end
end
```

When the user double clicks on an item, it is selected and the focus
is set to an editor.

```
connect(view, "doubleClicked") do i, j
    item = store.items[i]
    widgets[names(item)[1]][:focus] = true
end
```

When the submit button is clicked, the values in the editors are used
to update a record. When this is done, the focus is set on the
view. This allows the user to navigate between records with the arrow keys.

```
connect(submit_button, "clicked") do
    row = view[:index]
    item = store.items[row]
    for i in names(item)
        set_value!(item, i, item.(i), widgets[i][:value])
    end
    replace!(store, row, item)
end
connect(submit_button, "clicked", () -> view[:focus] = true)
```

Finally, we set the initial index and then display the window.

```
view[:index] = 1
raise(w)
```




    






