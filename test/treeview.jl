ENV["Tk"] = true 
using JGUI
using Base.Test


## Tree view shows nodes with a certain type
if !isdefined(:Test2)
    type Test2 
        x::Int
        y::Real
        z::String
    end
end

t1  = Test2(1, 1.0, "one")
t11 = Test2(11, 11.0, "one-one")
t12 = Test2(12, 12.0, "one-two")
t2  = Test2(2, 2.0, "two")

tstore = treestore()

node = insert!(tstore, nothing, 1, "label1", t1)
insert!(tstore, node, 1, "label11", t11)
insert!(tstore, node, 2, "label12", t12)
node = insert!(tstore, nothing, 2, "label2", t2)

w = window()
view = treeview(w, tstore)      # have to add tpl if tstore is empty
push!(view); raise(w)

## value is path of selected item
view[:value] = [1,2]
@test view[:value] == [1,2]



node = path_to_node(tstore, [1])
expand_node(view, node)


## remove node
node = path_to_node(tstore, [1,1])
pop!(tstore, node)

##