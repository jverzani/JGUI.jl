
### Simple usage
w = window()
gr = grid(w)
push!(w, gr)

b11 = button(gr, "11")
b22 = button(gr, "22")
b33 = button(gr, "33")

## basic array-like interface to add widget
gr[1,1] = b11
gr[2,2] = b22
gr[3,3] = b33


### alignment
w = window()
gr = grid(w)
push!(w, gr)

b11 = button(gr, "1,1")
b11[:alignment] = (:left, :top)
b11[:sizepolicy] = (:expand, :expand)

b22 = button(gr, "2,2")
b33 = button(gr, "3,3")
b33[:alignment] = (:right, :bottom)

gr[1,1] = b11
gr[2,2] = b22
gr[3,3] = b33

### can add through an array
using JGUI
w = window()
gr = grid(w)
push!(w, gr)

b11 = button(gr, "1,1")
b11[:alignment] = (:left, :top)
b11[:sizepolicy] = (:expand, :expand)

b22 = button(gr, "2,2")
b33 = button(gr, "3,3")
b33[:alignment] = (:right, :bottom)

gr[:,:] = [b11 b22; nothing b33]

### spanning multiple columns
using JGUI
w = window()
gr = grid(w)
push!(w, gr)

b11 = button(gr, "1,1")
b22 = button(gr, "2,2")
b33 = button(gr, "3,3")
[btn[:sizepolicy] = (:expand, :expand) for btn in [b11, b22, b33]]

gr[1:2, 1] = b11
gr[1,3] = b22
gr[2, 2:3] = b33

### configure weights -- abuse of notation

using JGUI
w = window()
gr = grid(w)
push!(w, gr)

b11 = button(gr, "1,1")
b22 = button(gr, "2,2")
b33 = button(gr, "3,3")
[btn[:sizepolicy] = (:expand, :expand) for btn in [b11, b22, b33]]

gr[1,:] = [b11 b22 b33]
column_stretch(gr, 1, 1)
column_stretch(gr, 2, 2)
column_stretch(gr, 3, 3)
