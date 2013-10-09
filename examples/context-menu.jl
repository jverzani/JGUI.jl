An example of using a context menu with cairo graphics.

Cairo graphics only work with `Tk` (not `Qt`) so we specify that, then load our packages:

```
ENV["Tk"] = true
using JGUI, Winston
```

Our GUI is basic, consisting of a top-level window and a graphic window.

```
w = window()
c = cairographic(w)
push!(w, c)
```

We can plot to the `cairographic` window via `Winston.display`:

```
f(x) = sin(x)
p = plot(f, 0, pi)
Winston.display(c[:widget], p)
```

Adding a context menu is easy. We just pass a widget to the `menu`
constructor instead of a top-level window (which is how we add a menu
bar).


```
m = menu(c)
```

The menu actions are added as with any menu.
The context value is the pixel coordinates of the mouse click (this needs work!):

```
a1 = action(m, "Position", () -> println(c[:context]))
addAction(m, a1)
```


Radio groups can be easily added to a menu bar. Just pass the context menu to the constructor as the parent. Checkboxes can also be added this way.

```
rb = radiogroup(m, ["one", "two"])
connect(rb, "valueChanged") do value
    value == "one" && println("one")
    value == "two" && println("two")
end

addAction(m, separator(m))
addAction(m, rb)
```






