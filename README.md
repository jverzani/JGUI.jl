# JGUI

An package to simplify the creation of GUIs within Julia


The `JGUI` package provides a few different means to ease the
creation of GUIs within `Julia`. These include a simplified
implementation of Mathematica's `Manipulate` function, and a simple
interface for using the `tcl/tk` or `Qt` toolkits within `Julia`.

# Installation

The `JGUI` package installs with `Pkg.add("JGUI")`. For it to work one
needs to have installed the `Tk` package or the `PySide` package. The
latter requires an installation of the `Qt` libraries
(http://qt-project.org/downloads), `Python` (http://www.python.org/download/), the `PySide`
(http://qt-project.org/wiki/Get-PySide) interface between `Python` and
`Qt`, and the `PyCall` package to connect `Python` with `Julia`
(installed with the `PySide` package). The Anaconda
(http://docs.continuum.io/anaconda/) packaging of `Python` should be a
one-stop installation, though the `Qt` part can be buggy.

# Manipulate


The easiest way to create a GUI with this package is to use the
`manipulate` function, which can be used to evaluate an expression
parameterized by values coming from easily specified controls within a
GUI.

As one can use either the Tk libraries or Qt (via the `PySide` module
and `PyCall`), the first line is used to specify the underlying
toolkit. Mixing and matching within a `Julia` session will likely lead
to crashes.


```
ENV["Tk"] = true
using JGUI
```

Now, consider the following expression  which computes a Winston plot object:


```
expr = quote
     plot(x -> sin(u*x), 0, 2pi)
end
```

We can use the `manipulate` function to fill in values for the unbound
variable `u`, when the expression is evaluated. The `plot` command
above returns a Winston plot object, which is then plotted. To create
a control to specify values for `u`, we simply need to specify a
range, as follows:

```
a = manipulate(expr, (:u, 1:10), modules=[:Winston])
```

This call will pop up a simple GUI with a slider that allows one to
adjust the value of `u` from 1 to 10, updating the graphic as this is
done.

Here is a how one can add a title to the plot. First we modify the `plot` call to include a title:

```
expr = quote
     plot(x -> sin(u*x), 0, 2pi, title=title)
end
```

Now `title` is also unbound. To specify a control to set a title, we use a string:

```
a = manipulate(expr, (:u, 1:10), (:title, "A sine plot"), modules=[:Winston])
```

Now when the plot is updated, the title is also taken from a text box.

Manipulate has other simple-to-specify controls:

* `(:symbol, Bool)` - checkbox. Use `{:label=>"some label"}` to label it.
* `(:symbol, Range)` - slider
* `(:symbol, Range, Range)` - 2d slider
* `(:symbol, Vector)` - radio or combobox (depends on size)
* `(:symbol, String)` - text edit 
* `(:symbol, Real)` - text edit with conversion to float via `parsefloat`
* `(:symbol, Int)` - text edit with conversion to integer via `parseint`

The expression can be a Winston plot object or any other object. Plot
objects are plotted in a display.


When using `Qt` (`ENV["Qt"] = true`) one can plot `PyPlot` calls, not
`Winston` calls. The `modules` argument should include `PyPlot`.

## A simplified GUI interface

Though the `Tk` package provides a relatively easy to learn means to
produce GUIs with `tcltk` and `PySide` does the same for `Qt`, this
package makes provides a small API for creating GUIS that makes it
even easier, though sacrificing a fair amount of flexibility. (The
`JGUI` interface is primarily concerned with controls, and not things
like a canvas widget.) 

Here is a simple example where a window has a button which when clicked will destroy the window. 

```
w = window(size=[200, 200])
w[:title] = "hello world"

b = button(w, "Close")
push!(w, b)

connect(b, "clicked", w, destroy)
raise(w)
```

The first line creates a window object with an optional size
specified.


The second line shows how a property of the window object may be
set, using indexing notation with an appropriate symbol, in this case
`:title`. There are relatively few properties for any given
object. For a control, the most important is `:value`. (The method
`properties` will list all of a widget's properties.)

The third line creates a button object. All constructors except
`window` use a parent container for the first argument. (This is
similar to `Tk` and so the widget hierarchy is determined, but not the
actual layout). The `button` constructor has label value for the
second positional argument.

The fourth line is specific to `JGUI`.  Rather than use separate
layout managers, as is done with `Qt` or `Tk`, each container object
is conceptualized as a queue of some sort.  For the window object, the
`push!` method adds the button to the window queue, laying it out as
it does so.

The fifth line is how one connects a callback to an event. In this
case the receiver of a click event, `b`, will emit a signal
`clicked`. The `w` object is passed to its method `destroy` to destroy
the window. This pattern follows Qt's signal-and-slots style. One can
also just pass in a function to call instead of the last two
arguments, something like `connect(b, "clicked", () -> destroy(w))`.

Finally, the window is raised.

Though simple, the above example demonstrates most all the procedures
when creating a GUI: creating GUI objects, accessing their properties,
laying out the objects, and creating interactivity by assigning
callbacks to user-initiated events.


## Basics

### constructors

Let's look at another example, this one mimics, the first manipulate
example.

```
## needs Tk
ENV["Tk"] = true
using JGUI, Winston

w = window()
f = hbox(w); push!(f)

sl = slider(f, 1:10)
cnv = cairographic(f)

append!(f, [sl, cnv])

connect(sl, "valueChanged") do u
  p = plot(x -> sin(u * x), 0, 2pi)
  Winston.display(cnv.o, p)
end
```

In the above we have several constructors: `window`, `hbox`, `slider`,
and `cairographic`. Each produces a widget. The `window` creates a
toplevel window, and `slider` a slider. The `hbox` constructor creates
a horizontal box container, which is used above to hold two children,
the slider and a cairo graphic device produced by
`cairographic`. (The `pyplotgraphic` widget produces a device for
graphics drawn via `PyPlot` and can be use with the `Qt` toolkit.)

As mentioned, constructors in `JGUI`, except for `window`, have a
parent container passed as the first argument. Additional arguments
are used to customize the constructor. For `hbox` and `cairographic`,
there is no needed customization, though the latter may have a width
and height argument specified. For a slider, one needs to specify the
range that is stepped over. Unlike most slider implementations, such as
the one in `Tk`, a slider is used to select amongst the specified
range or sorted vector. This reduces the need to specify a step size
and is more in line with how `julia` produces sequences of values.

For a slider, the `valueChanged` signal passes the new value to the
callback. This value is then used within the callback that produces
the graphic. One could also access this value within the callback with `sl[:value]`.

### Containers

Constructors produce basically two types of objects: controls and
containers. The containers available in this package are few:

* `hbox` and `vbox` produce horizontal and vertical box containers. 

* `grid` makes a container for arranging its children in a grid.

* `notebook` provides a tabbed notebook for organizing its children. 

* `formlayout` provides a simple way to lay out label/controls in a grid

* `labelframe` provides a simple container for holding a single child
  (like `window`), in this case with a label and decorative frame.

Containers are coupled with a layout manager which are utilized in a "julian" manner:

* The `hbox` and `vbox` containers have methods `push!`, `insert!`, and
  `append!` for adding children to the layout;  `pop!` and
  `splice!` for removing children. In the above example, we use
  `append!` to add two children at a time. 

* The `formlayout` and `notebook` containers also implement the above
  for adding a child at a time, with an additional label.

* The single-child containers, `labelframe` and `window`, use `push!` to add their child. 

* Children of a `grid` container are managed via matrix notation. There are two styles. One can add a matrix of widgets:

```
w = window(title="Matrix of widgets")
g = grid(w); push!(g)		# push!(g) is same as push!(w, g)
b1 = button(g, "one")
b2 = button(g, "two")
b3 = button(g, "three")

g[:,:] = [b1 b2; nothing b3]
raise(w)
```

Or one can add a single child using `[row,column]` notation. These may
be specified through a range to span multiple rows or columns.

The expanding and alignment properties of how a child is placed into a
parent are specified for the child, not the container. These are done
through the properties `:sizepolicy` and `:alignment`. Padding is done
through the `:spacing` properties of the containers.

### properties 

Widgets have properties that can be queried and set through index
notation where a symbol is used for indexing. For example, to set the
size policy  of a widget, we have:

```
w = window(size=[300, 300])
f = hbox(w); push!(f)
b = button(f, "expanding")

#b[:sizepolicy] = (:expand, :fixed)  # expand in x direction
b[:sizepolicy] = (:fixed, :expand)   # expand in y direction
#b[:sizepolicy] = (:expand, :expand) # expand in both

push!(b)
raise(w)
```

Some properties are dynamic, this one is not. It should be set before packing into a layout.

The main value of a widget is assigned the `value` property. For a button this is its label:

```
w = window(title="change label")
b = button(w, "old label"); push!(b)
b[:value]			# "old label"
b[:value] = "new label"		# updates button
b[:value]			# "new label"
```

When a property, say ':prop', is looked up a search for
either a `getProp` or `setProp` method is made. Though not exported, save for `getValue` and `setValue`
these functions can be conveniently employed when using the property in a callback.

## signals

The basic `connect` method is used to connect a callback to an
event. The syntax follows Qt's signals and slots usage. It can take
two forms: `connect(receiver, signal, obj, slot)` or
`connect(receiver, signal, slot)`, where `slot` is a function. In the
first instance, the call is `slot(obj, vals...)` and the second, just
`slot(vals...)` where `vals...` depends on the signal: the basic
`valueChanged` signal passes in the value; whereas, a button's
`clicked` signal has no value passed.

Widgets have different signals defined. Mostly the names follow a
small subset of those for the corresponding Qt widget (hence the names
in camelCase format).


The connect method returns an id. This can be used with `disconnect`
to remove an observer of an object. At present there is no way to
temporarily suspend a callback.

As an example,  This is how
one connects a slider value to a label:

```
w = window(title="label and slider")
f = hbox(w); push!(f)
sl = slider(f, 1:20)
l = label(f, sl[:value])
append!(f, [sl, l])

connect(sl, "valueChanged", l, setValue)
raise(w)
```

Some alternatives would be `connect(rb, "valueChanged", l, (l, value)
-> l[:value] = value)` or `connect(rb, "valueChanged", value ->
l[:value] = value)`.


As an aside, this can also be done by sharing the underlying model, as with:

```
w = window(title="label and slider")
f = hbox(w); push!(f)
sl = slider(f, 1:20)
l = label(f, sl.model)
append!(f, [sl, l])
```




## Widgets

The basic widgets are:

* `label` a standard text label

* `separator` used to place a horizontal or vertical line in a layout

* `button` a push button

* `lineedit` a single line text edit

* `textedit` multi-line text edit

* `checkbox` a simple true/false toggle

* `radiogroup` exclusive set of buttons

* `buttongroup` exclusive (or not) set of buttons

* `combobox` a popup selection widget

* `slider` select from numeric range

* `slider2d` select two variables from numeric range

* `listview` Show a vector of values allowing selection of one or more.

* `storeview`  used to display store of records

* `treeview` used to display tree structured records

* `cairographic`  used with `Winston` graphics (`Tk` only)

* `pyplotgraphic` used with `PyPlot` graphics (`Qt` only)

* `imageview` used to display `png` or `gif` image files.


#### XXX example



#### Cairo graphic example

The `cairographic` widget is a light wrapper around
`Tk.Canvas`. Currently, it can only be used within a `Tk` GUI.

To use the canvas, access the `:widget` property of the
`cairographic` object:

```
## update two graphics windows...
ENV["Tk"] = true
using JGUI, Winston
w = window()
f = grid(w); push!(f)
g1 = cairographic(f, width=480, height=400)
g2 = cairographic(f, width=480, height=400)
b = button(f, "update"); b[:alignment] = (:right, :center)
f[:,:] = [g1 g2; nothing b]
connect(b, "clicked") do
   p = FramedPlot(); add(p, Curve(rand(10), rand(10))); Winston.display(g1[:widget], p)
   p = FramedPlot(); add(p, Curve(rand(10), rand(10))); Winston.display(g2[:widget], p)
end
notify(b, "clicked")	# roundabout way to draw initial graphic, ...
```

#### Storeview example

A store is a vector of a composite type displayed in a grid with each
row representing an item.  Here is an example. First we define a type for
our items and some instances:

```
type Test 
    x::Int
    y::Real
    z::String
end


t1 = Test(1, 1.0, "one")
t2 = Test(2, 2.0, "two")
t3 = Test(3, 3.0, "three")
```

Then we can place these into a store to pass to `storeview`:
```
store = Store{Test}([t1, t2, t3])
```

Here is how we lay it out:

```
w = window(size=[300, 300])
sv = storeview(w, store)
push!(sv)

sv[:widths] = [100, 100, 100]	# column widths
sv[:selectmode] = :multiple	# :single or :multiple
id = connect(sv, "rowClicked", (row, col) -> println((row, col))) # sample handler

raise(w)
```

One can add and remove items through `insert!`, `splice!`; one can modify existing items through indexing:

```
t4 = Test(4, 4.0, "four")
push!(sv, t4)
splice!(sv, 1)
item = sv[1]
item.z = uppercase(item.z)
sv[1] = item
```

The `valueChanged` signal passes the index (or indices) that are
selected. These are also given by the `:index` property. The `:value`
property returns the items. One uses `:index` to set the selection, not `:value`.

In addition to `rowClicked`, there are `rowDoubleClicked`, `headerClicked`, and `selectionChanged` signals.


## Treeview example

A treeview uses a treestore to hold the data, again specified using a composite type. Here is a simple example:

```
type Test2 
    x::Int
    y::Real
    z::String
end

t1  = Test2(1, 1.0, "one")
t11 = Test2(11, 11.0, "one-one")
t2  = Test2(2, 2.0, "two")
```

```
tstore = treestore()
w = window(size=[300, 300])
tv = JGUI.treeview(w, tstore, tpl=t1) ## pass in something to determine columns, headers
push!(tv)	      
```

To manage child items, we have `insert!`:

```
node = insert!(tstore, nothing, 1, "label1", t1)
insert!(tstore, node, 1, "label11", t11)
node = insert!(tstore, nothing, 2, "label2", t2)
```

Nodes are related to a `path`, which specifies the ancestry. The path
`[3,2,1]` would be the first child of the second child of the third
child of the root. We use the path to find a node to open via:

```
node = path_to_node(tstore, [1])
expand_node(tstore, node)
```

We can remove nodes via a two-argument form of `pop!`

```
node = path_to_node(tstore, [1,1])
pop!(tstore, node)
```

### Dialogs

There are some standard modal dialogs

* `filedialog`

* `messagebox`

* `confirmbox`

In addition, the `dialog` constructor can be used to generate dialogs, somewhat similar to Qt's base Dialog class:

```
using JGUI
w = window()			        # Some parent to position the dialog near

dlg = dialog(w, buttons=[:cancel, :ok]) # default is just `:ok`
f = vbox(dlg); push!(f)

l = label(f, "More complicated controls go here"); push!(l)

connect(dlg, "finished", state -> println(state))
dlg.exec()
```
