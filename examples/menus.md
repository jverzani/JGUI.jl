An example showing how menus may be constructed. Menus include menubars, submenus and context menus. 

Here we work with `Tk`, though this also works with `Qt`.

```
ENV["toolkit"] = "Tk"
using JGUI
w = window()
w[:size] = [300, 300]		# Tk likes to be sized
```

A toplevel menu bar is created via the `menubar` constructor. The argument is a `window` instance.

```
m = menubar(w)
```

That call can also be simply `menu`, a generic function for creating submenus.

A submenu of the top-level menu bar (or another menu) is created by passing `menu` passing  a toplevel menu bar and a string for a label.

```
filemenu = menu(m, "Files")
```

Menu items are primarily proxies for actions. Here we create two
actions. The main arguments are a parent menu, a label and an action
(a callback):

```
edita = action(filemenu, "edit", () -> println("edit"))
opena = action(filemenu, "open", () -> println("open"))
```

We add actions to menus via `addAction`. Notice, here we can also add
a separator by passing the menu as a parent:

```
addAction(filemenu, edita)
addAction(filemenu, separator(filemenu))
addAction(filemenu, opena)
```

A submenu is like a menu: we just pass in the menu as a parent and a label:

```
submenu = menu(filemenu, "Submenu")
```

We can add actions to the submenu as before.

```
cuta = action(submenu, "cut", () -> println("cut"))
addAction(submenu, cuta)
addAction(submenu, separator(submenu))
```


Actions can also be radio groups -- just pass in the menu as the parent.

```
rb = radiogroup(submenu, ["one", "two"])
connect(rb, "valueChanged", (value) -> println(value))
addAction(submenu, rb)
```

```
addAction(submenu, separator(submenu))
```

As well, we can use check boxes within a menu:

```
cb = checkbox(submenu, "check me")
connect(cb, "valueChanged", (value) -> println(value))
addAction(submenu, cb)
```

### Context menus

Context menus are menus attached to widgets which are popped up by a third mouse action (or some other OS dependent manner). Here we define a widget. The context menu is created with `menu`, as before, only we pass a widget:

```
e = lineedit(w, "click me for context")
push!(e)
m = menu(e)
```

This menu has actions added as before:


```
edita = action(m, "edit", () -> println("context edit"))
opena = action(m, "open", () -> println("context open"))
addAction(m, edita)
addAction(m, opena)
```



```
raise(w)
```
