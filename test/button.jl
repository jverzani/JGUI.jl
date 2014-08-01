using JGUI
using Base.Test


w = window()
f = vbox(w); push!(w, f)

b = button(f, "click me")
push!(f, b); raise(w)


b[:icon] = :ok                  # set icon
@test b[:value] == "click me"   # getValue

b[:value] = "New value"         # setValue
@test b[:value] == "New value"

## Callbacks
ctr = [1]
connect(b, "clicked", () -> ctr[1] = ctr[1] + 1)

## invoke
notify(b.model, "clicked")
@test ctr[1] ==  2
