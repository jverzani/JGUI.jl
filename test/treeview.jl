## ENV["toolkit"] = "Tk"
using JGUI
using Base.Test


tstore = treestore(Int, Float64, String)

t1 = (1, 1.0, "one")
t11 = (11, 11.0, "one-one")
t12 = (12, 12.0, "one-two")
t2  = (2, 2.0, "two")

node = insert!(tstore, nothing, 1, "label1", t1)
insert!(tstore, node, 1, "label11", t11)
insert!(tstore, node, 2, "label12", t12)
node = insert!(tstore, nothing, 2, "label2", t2)

w = window()
view = treeview(w, tstore)      # have to add tpl if tstore is empty
view[:names] = ["Int", "Float", "String"]
view[:widths] =  [50,50,-1]


tv[:keyname] = "key"
tv[:keywidth] = 100

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
