using JGUI

w = window(title="notebook")
nb = notebook(w); push!(w, nb)
connect(nb, "valueChanged", value -> println("On tab $value"))

b1 = button(nb, "one")
b2 = button(nb, "two")
b3 = button(nb, "three")

push!(nb, b1, "one")
push!(nb, b2, "two")
push!(nb, b3, "three")

setValue(nb, 3)
@assert nb[:value] == 3

pop!(nb, b2)
@assert length(nb) == 2
@assert nb[1][:value] == "one"
