A storeview is used to display a grid of records.

```
ENV["toolkit"] = "Tk"
using JGUI
```

Each record is an instance of a composite type. Here we define one,
being careful not to redefine it if this example is tried more than
once:

```
if !isdefined(:Test1)
    type Test1
        x::Int
        y::Real
        z::String
    end
end
```

Here are some instances:

```
t1 = Test1(1, 1.0, "one")
t2 = Test1(2, 2.0, "two")
t3 = Test1(3, 3.0, "three")
```


A `Store` is a container for instances of our type. Here we pass in the type and an initial instance:
```
store = Store{Test1}([t1])
```

(Oh, this should be `Store([t1])`, but that needs tidying up...)

Our GUI is very basic. We create a window and then a view of the `Store` instance:
```
w = window()
view = storeview(w, store)
push!(view); raise(w)
w[:size] = [300, 300]
```

Modifications made to the store are propagated to the view(s).
```
append!(store, [t2, t3])
```

A storeview may have a context menu. The context is the row and column
that the user clicks on. The context is available through the value
`view[:context]` (which currently can not be used to parameterize the
context menu). Context menus are created likemenubars, only one passes
a widget and not a top level window to the `menu` constructor.

```
m = menu(view)

a1 = action(m, "Position", () -> println(("row, col:", view[:context])))
rb = radiogroup(m, ["one", "two"])
connect(rb, "valueChanged") do value
    value == "one" && println("do one")
    value == "two" && println("do two")
end

addAction(m, a1)
addAction(m, rb)
```
