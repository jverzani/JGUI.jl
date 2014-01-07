The `JGUI` package provides two slider widgets: a basic slider,
available in horizontal or vertical format; and a 2-d slider, inspired
by one in Mathematica's manipulate function. This example shows all
three interconnected.


```
ENV["toolkit"] = "Tk"		# not Gtk!
using JGUI
```

We use a grid to hold our three widgets:

```
w = window()
f = grid(w); push!(f)
```


Here we define three sliders. The basic slider selects from a
specified range or vector. This is unlike traditional sliders, wehre
the widget range is usually specified with a from, to and step
size. The two dimensional slider uses two ranges.

```
slt = slider(f, 1:100)
slr = slider(f, 1:100, orientation=:vertical)
sl2 = slider2d(f, 1:100, 1:100)
```

Grid containers, have a somewhat convenient way to position their children:

```
f[:, :] = [slt nothing; sl2 slr]
```

This connects changes to the two-dimensional slider to the individual sliders.

```
connect(sl2, "valueChanged", value -> slt[:value] = value[1])
connect(sl2, "valueChanged", value -> slr[:value] = value[2])
```

This connects changes from the individual sliders to the two-dimensional slider.

```
connect(slt, "valueChanged", value -> sl2[:value] = [value, sl2[:value][2]])
connect(slr, "valueChanged", value -> sl2[:value] = [sl2[:value][1], value])
```

That's it.

```
raise(w)
```
