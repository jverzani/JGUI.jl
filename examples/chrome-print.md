The print dialog of the chrome browser has a useful little way to select which pages to print consisting of a radio button group (to toggle between "all pages" or "some pages") and an entry box to specify a range in the latter case. This example shows how to layout such a GUI, and more importantly how to connect the pieces together to make it work.

However, the radio buttons aren't really radio buttons, as the label for one is an entry box. Here we mimic the basic setup using checkboxes:

```
using JGUI
w = window()
g = grid(w)
push!(g)
```

We have four widgets:

```
all_cb = checkbox(g, true,nothing)
all_label = label(g, "All"); all_label[:alignment] = (:left, nothing)
pages_cb = checkbox(g, false)
pages_edit = lineedit(g, "")
pages_edit[:placeholdertext] = "e.g., 1-5, 8, 11-13"


g[:,:] = [all_cb all_label; pages_cb pages_edit]
```

The subtle part above is getting the labeling to align. Rather than use the built-in label for `all_cb`, we push a label into the grid. We need to specify its alignment though, as left alignment is not the default. Otherwise, this is a fairly straightforward usage of `grid`.

Now we wire up the pieces. The checkboxes are not exclusive. We need to manage that. In the `valueChanged` handlers for the checkboxes we do so as follows:

```
notSetValue(object, value::Bool) = setValue(object, !value)
connect(all_cb, "valueChanged", pages_cb, notSetValue)
connect(pages_cb, "valueChanged", all_cb, notSetValue)
```

The entry box to specify a page range should be enabled and focused when the `pages_cb` checkbox is selected:

```
connect(pages_cb, "valueChanged", pages_edit, JGUI.setEnabled)
connect(pages_cb, "valueChanged", pages_edit, JGUI.setFocus)
```

This has the added bonus of also disabling when the `all_cb` is selected, as those buttons are already linked.

If the user click into the  `pages_edit` area it should select the checkbox:

```
connect(pages_edit, "clicked", ()->pages_cb[:value] = true)
```

(In `Tk`, tabbing will not enter that box while it is disabled. For mouseless navigatione, one can tab to the accompanying checkbox and select that with the space bar.)

Finally, we set the value of `all_cb` to the initial state:

```
all_cb[:value] = true
all_cb[:focus] = true
```
