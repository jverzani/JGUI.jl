## menus in JGUI

using JGUI



w = window(title="menus")
b = button(w, "button"); push!(w,b)

help = action(w, "help", () -> println("hi"))
file = action(w, "file", () -> println("file"))

m = menubar(w)
sm = addMenu(m, "File")
push!(sm, help)
push!(sm, separator(sm))
push!(sm, file) ## push!

sm = addMenu(m, "Hey")
push!(sm, help)
push!(sm, file) ## push!


## radio button and check button values
if !JGUI.isgtk()
    sm = addMenu(m, "buttons")
    ## radio button
    rb = radiogroup(sm, ["one", "two", "three"])
    widget = push!(sm, rb)
    push!(sm,separator(sm))
    ## check button
    cb = checkbox(sm, true, "label")
    push!(sm, cb)
    push!(sm, separator(sm))

    push!(sm, action(w, "values", () -> println((rb[:value], cb[:value]))))
end

## popup menus
pm = menu(b)
b[:context] = "ping"
push!(pm, action(w, "foo", () -> begin println(b[:context]); b[:context] = "foo" end))
push!(pm, action(w, "bar", () -> begin println(b[:context]); b[:context] = "bar" end))



raise(w)
