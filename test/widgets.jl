## test of basic widgets
using JGUI
using Base.Test

w = window()
g = vbox(w); push!(w, g)

lab = label(w, "label")
btn = button(w, "text")
ed = lineedit(w, "text")
## XXX txt = textedit(w, "more text")
cb = checkbox(w, true, "fred")
rad = radiogroup(w, map(string, [1:3]))
## XXX bgp = buttongroup(w, ["a", "b", "c"])
cmb = combobox(w,  ["a", "b", "c"])
## XXX cmb_ed = combobox(w,  ["a", "b", "c"], editable=true)
sl = slider(w, 1:100)
sp = spinbox(w, 1:100)
im = imageview(w, "/tmp/trash.png")


widgets = [lab, btn, ed, cb, rad, cmb, sl,sp, im]
append!(g, widgets)
       
raise(w)
