using JGUI

# Box containers are manipulated like queues

# Adding objects

## push! 
w = window(); f = vbox(w); push!(w, f)

## push!
btns = [push!(f, button(f, string("button $i"))) for i in 1:2]

## append! is more convenient
btns = [button(f, string("button $i")) for i in 3:4]
append!(f, btns)

## prepend!
prepend!(f, [button(f, "button 0")])

## insert! Index is 1:(n+1)
insert!(f, 3, button(f, "button 1.5"))

# removing widgets

## pop! (last)
pop!(f)

## shift! (first
shift!(f)

## splice! (by index)
splice!(f, 2)

## remove by item
item = f[2]
splice!(f, findin(item, f))

# indexing
f[2]


## Alignment
w = window(title="alignment")
b = vbox(w); push!(w,b)

nw = button(b, "northwest")
nw[:alignment] = (:left, :top)

center = button(b, "center")
center[:alignment] = (nothing, nothing)

sw = button(b, "southwest")
JGUI.setAlignment(sw, (:right, :bottom))

[JGUI.setSizepolicy(btn, (:fixed, :fixed)) for btn in [nw, center, sw]]

append!(b, [nw, center, sw])



raise(w)
