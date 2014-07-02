## This can be added to Gtk, but for now is here

## add these to Gtk lists.jl

## Get an iter corresponding to an index specified as a string
function iter_from_string_index(store, index::String)
    iter = Gtk.mutable(GtkTreeIter)
    Gtk.G_.iter_from_string(GtkTreeModel(store), iter, index)
    if !isvalid(store, iter)
        error("invalid index: $index")
    end
    iter
end
## index is integer for list, vector of ints for tree
iter_from_index(store::GtkListStoreLeaf, index::Int) = iter_from_string_index(store, string(index-1))
iter_from_index(store::GtkTreeStoreLeaf, index::Vector{Int}) = iter_from_string_index(store, join(index.-1, ":"))


function list_store_set_values(store::GtkListStoreLeaf, iter, values)
    for (i,value) in enumerate(values)
        ccall((:gtk_list_store_set_value,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{Gtk.GValue}),
              store,iter,i-1, Gtk.gvalue(value))
    end
end


## insert into a list store after index
function Base.insert!(listStore::GtkListStoreLeaf, index::Int, values)
    index < 1 && return(unshift!(listStore, values))

    index = min(index, length(listStore))
    iter = Gtk.mutable(GtkTreeIter)
    siter = iter_from_index(listStore, index)
    ccall((:gtk_list_store_insert_after,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), listStore, iter, siter)
    list_store_set_values(listStore, iter, values)
    iter
end

function Base.splice!(listStore::GtkListStoreLeaf, index::Int)
    iter = iter_from_index(listStore, index)
    delete!(listStore, iter)
end


## return tuple for a row
function Base.getindex(store::Gtk.GtkListStore, index::Int)
    iter = Gtk.iter_from_index(store, index)
    GtkTreeModel(store)[iter]
end

## return i,j cell from store -- may not be in view coordinates
function Base.getindex(lstore::Gtk.GtkListStore, index::Int, column::Int)
    iter = Gtk.iter_from_index(lstore, index)

    val = Gtk.mutable(Gtk.GValue())
    Gtk.G_.value(GtkTreeModel(lstore), iter, column - 1, val)
    val[Any]
end
function Base.setindex!(lstore::Gtk.GtkListStore, value, index::Int, column::Int)
    iter = Gtk.iter_from_index(lstore, index)
    Gtk.G_.value(lstore, iter, column - 1, Gtk.gvalue(value))
end

## Selection ...

## This is a function of the view -- not the model
## 
## return Int[] of selected indices
function Gtk.selected(view::Gtk.GtkTreeView)
    selection = Gtk.G_.selection(view)
    ret = Int[]

    hasselection(selection) || return ret


    if getproperty(selection, :mode, Int) == Gtk.GConstants.GtkSelectionMode.MULTIPLE
        model = Gtk.mutable(GtkTreeModel(getproperty(view, :model, Gtk.GtkListStore)))
        rows = Gtk.GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, Gtk.libgtk), 
                                    Ptr{Gtk._GSList{Gtk.GtkTreePath}},
                                    (Ptr{GObject}, Ptr{GtkTreeModel}), 
                                    selection, model))

        for path in rows
            i = ccall((:gtk_tree_path_to_string, Gtk.libgtk), Ptr{Uint8}, 
                      ( Ptr{GtkTreePath},),
                      path) |> bytestring |> int |> x -> x + 1
            push!(ret, i)
        end
    else
        ## Gtk.selected *should* work here, but last line gives
        ## coercion issue.
        m, iter = selected(selection) # issue with Gtk.selected

        ## what is row?
        i = ccall((:gtk_tree_model_get_string_from_iter, Gtk.libgtk), 
                  Ptr{Uint8}, 
                  (Ptr{GObject}, Ptr{GtkTreeIter}), m[], iter) |> bytestring |> int |> x -> x+1
        push!(ret, i)
    end
    ret
end

## Add to selection using index
function Base.select!(view::Gtk.GtkTreeViewLeaf, index::Int)
    selection = Gtk.G_.selection(view)
    store = getproperty(view, :model, Gtk.GtkListStoreLeaf)
    iter = Gtk.iter_from_index(store, index)
    Gtk.select!(selection, iter)
end


## Add to selection using index
function Base.select!(view::Gtk.GtkTreeViewLeaf, index::Int)
    selection = Gtk.G_.selection(view)
    store = getproperty(view, :model, Gtk.GtkListStoreLeaf)
    iter = Gtk.iter_from_index(store, index)
    Gtk.select!(selection, iter)
end

function Gtk.unselect!(view::Gtk.GtkTreeViewLeaf, index::Int)
    selection = Gtk.G_.selection(view)
    store = getproperty(view, :model, Gtk.GtkListStoreLeaf)
    iter = Gtk.iter_from_index(store, index)
    Gtk.unselect!(selection, iter)
end


function Gtk.unselectall!(view::Gtk.GtkTreeViewLeaf)
    selection = Gtk.G_.selection(view)
    Gtk.unselectall!(selection)
end


##


## This is Gtk.path_at_pos modified to get more
function tree_view_row_col_from_x_y(treeView::GtkTreeView, x::Integer, y::Integer)
    pathPtr = Gtk.mutable(Ptr{GtkTreePath})
    vcol = Gtk.mutable(@GtkTreeViewColumn())
    path = GtkTreePath() 
    
    ret = bool( ccall((:gtk_tree_view_get_path_at_pos,Gtk.libgtk),Cint,
                      (Ptr{GObject},Cint,Cint,Ptr{Ptr{Void}},Ptr{Ptr{Void}},Ptr{Cint},Ptr{Cint} ),
                       treeView,x,y,pathPtr,vcol,C_NULL,C_NULL) )
    if ret
        path = convert(GtkTreePath, pathPtr[])   
        vcol = vcol[]
        row = int(string(path)) + 1

        columns = Gtk.GList(ccall((:gtk_tree_view_get_columns, Gtk.libgtk), 
                                Ptr{Gtk._GSList{Gtk.GtkTreeViewColumn}}, (Ptr{GObject},), treeView))
        col = filter(i -> getproperty(columns[i], :title, String) == getproperty(vcol, :title, String), 1:length(columns))[1]

        return(row, col)
    end
    return(0,0)
end


### TreeStores ...
##
function tree_store_set_values(treeStore::GtkTreeStoreLeaf, iter, values)
    for (i,value) in enumerate(values)
        ccall((:gtk_tree_store_set_value,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{Gtk.GValue}),
              treeStore,iter,i-1,Gtk.gvalue(value))
    end
    iter[]
end





## insert by index
## index can be :parent or :sibling
## insertion can be :after or :before
function Base.insert!(treeStore::GtkTreeStoreLeaf, index::Vector{Int}, values; how::Symbol=:parent, where::Symbol=:after)


    piter = iter_from_index(treeStore, index)
    iter =  Gtk.mutable(GtkTreeIter)
    if how == :parent
        if where == :after
            ccall((:gtk_tree_store_insert_after,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, piter, C_NULL)
        else
            ccall((:gtk_tree_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, piter, C_NULL)
        end
    else
        if where == :after
            ccall((:gtk_tree_store_insert_after,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        else
            ccall((:gtk_tree_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        end
    end
    
    tree_store_set_values(treeStore, iter, values)
end
    

function Base.splice!(treeStore::GtkTreeStoreLeaf, index::Vector{Int})
    iter = iter_from_index(treeStore, index)
    delete!(treeStore, iter)
end
    

