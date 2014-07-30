using JGUI
using Base.Test
## react widget

## connect values
w = window()
f = vbox(w)
push!(f)

ed = lineedit(f, "")
lab = label(f, "")
append!(f, [ed, lab])

lab[:value] = ed
ed[:value] = "new value"
@assert lab[:value] == ed[:value]



## cairographics
w = window()
f=vbox(w)
push!(f)

n = slider(f, 1:10)
g = cairographic(f)

append!(f, [n, g])

@wlift display(g, plot(sin, 0, n*pi))
