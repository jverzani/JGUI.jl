using JGUI
using Base.Test

# Box containers are manipulated like queues

# Adding objects

## push! 
w = window(); f = vbox(w); push!(w, f)

## push!
btns = [push!(button(f, string("button $i"))) for i in 1:2]

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





