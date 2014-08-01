using JGUI
using Base.Test

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

raise(w)

if !JGUI.isqt()

    ## cairographics
    ## manipulate like
    w = window()
    f=vbox(w)
    push!(f)
    
    n = slider(f, 1:10)
    g = cairographic(f)
    
    append!(f, [n, g])

    @wlift display(g, plot(sin, 0, n*pi))

end
