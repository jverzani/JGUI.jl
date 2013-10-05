ENV["Tk"] = true
using JGUI

w = window(); w[:size] = [300, 300]

## Toplevel menu bar is added to a window object
m = menubar(w)

## submenus are created by passing just a label to `addMenu`
filemenu = addMenu(m, "Files")

## menus proxy actions:
edita = action(filemenu, "edit", () -> println("edit"))
opena = action(filemenu, "open", () -> println("open"))

## we add actions or separators similarly
addAction(filemenu, edita)
addAction(filemenu, separator(filemenu))
addAction(filemenu, opena)

## submenus
submenu = menu(filemenu, "Submenu")
cuta = action(submenu, "cut", () -> println("cut"))
addAction(submenu, cuta)

addAction(submenu, separator(submenu))

## can add radiogroups and checkboxes
rb = radiogroup(submenu, ["one", "two"])
connect(rb, "valueChanged", (value) -> println(value))
addAction(submenu, rb)

addAction(submenu, separator(submenu))

cb = checkbox(submenu, "check me")
connect(cb, "valueChanged", (value) -> println(value))
addAction(submenu, cb)


## Context menu
## XXX This needs fleshing out. Currently Tk has no widget[:context] set, and Qt has this
## only for storeview
e = lineedit(w, "click me for context")
push!(e)
m = menu(e)


edita = action(m, "edit", () -> println("context edit"))
opena = action(m, "open", () -> println("context open"))
addAction(m, edita)
addAction(m, opena)


raise(w)