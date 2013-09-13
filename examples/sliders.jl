## interacting sliders
## 
## shows, 2d slider, and interactive controls

using JGUI

w = window()
f = grid(w); push!(f)

slt = slider(f, 1:100)
slr = slider(f, 1:100, orientation=:vertical)
sl2 = slider2d(f, 1:100, 1:100)

f[:, :] = [slt nothing; sl2 slr]

connect(sl2, "valueChanged", value -> slt[:value] = value[1])
connect(sl2, "valueChanged", value -> slr[:value] = value[2])

connect(slt, "valueChanged", value -> sl2[:value] = [value, sl2[:value][2]])
connect(slr, "valueChanged", value -> sl2[:value] = [sl2[:value][1], value])

raise(w)