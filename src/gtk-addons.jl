## This can be added to Gtk, but for now is here

## add these to Gtk lists.jl



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

function selected(selection::GtkTreeSelection)
    model = Gtk.mutable(Ptr{GtkTreeModel})
    iter = Gtk.mutable(GtkTreeIter)

    if !hasselection(selection)
        return (model[], {})

    elseif getproperty(selection, :mode, Int) == Gtk.GConstants.GtkSelectionMode.MULTIPLE
        rows = Gtk.GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, Gtk.libgtk), 
                                    Ptr{Gtk._GSList{Ptr{Gtk.GtkTreePath}}},
                                    (Ptr{GObject}, Ptr{GtkTreeModel}), 
                                    selection, model))
        function path_to_iter(path)
            iter = Gtk.mutable(GtkTreeIter)
            ret = bool(ccall((:gtk_tree_model_get_iter, Gtk.libgtk), 
                             Cint, 
                             (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}, Ptr{Gtk.GtkTreePath}),
                             model[], iter, path))
            if !ret
                error("No selection of GtkTreeSelection")
            end
            iter[]
        end
        return (model[], [path_to_iter(row) for row in  rows])
    else
        ret = bool(ccall((:gtk_tree_selection_get_selected,Gtk.libgtk),Cint,
                         (Ptr{GObject},Ptr{Ptr{GtkTreeModel}},Ptr{GtkTreeIter}),
                         selection, model, iter))
        if !ret
            error("No selection of GtkTreeSelection")
        end
        return (model[],{iter[]})
    end
end
        
        ## This is a function of the view -- not the model
## 
## return Int[] of selected indices
function gtk_jgui_selected(view::Gtk.GtkTreeView)
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
                      path) |> bytestring |> int |> x -> x .+ 1
            push!(ret, i)
        end
    else
        ## Gtk.selected *should* work here, but last line gives
        ## coercion issue.
        ## m, iter = selected(selection) # issue with Gtk.selected
        m = Gtk.mutable(Ptr{GtkTreeModel})
        iter = Gtk.mutable(GtkTreeIter)
        res = bool(ccall((:gtk_tree_selection_get_selected,Gtk.libgtk),Cint,
                         (Ptr{GObject},Ptr{Ptr{GtkTreeModel}},Ptr{GtkTreeIter}),
                         selection,m,iter))

        !res && error("No selection of GtkTreeSelection")
        ## what is row?
        i = ccall((:gtk_tree_model_get_string_from_iter, Gtk.libgtk), 
                  Ptr{Uint8}, 
                  (Ptr{GObject}, Ptr{GtkTreeIter}), m[], iter) |> bytestring |> int |> x -> x+1
        push!(ret, i)
    end
    ret
end

## return path of selected
function gtk_jgui_tree_selected(view::Gtk.GtkTreeView)
    selection = Gtk.G_.selection(view)
    ret = Any[]

    hasselection(selection) || return ret

    ## convert i:j:k -> [i+1, j+1, k+1]
    path_to_index(p) =  map(x -> x+1, map(int, split(p, ":") ))

    
    if getproperty(selection, :mode, Int) == Gtk.GConstants.GtkSelectionMode.MULTIPLE
        model = Gtk.mutable(GtkTreeModel(getproperty(view, :model, Gtk.GtkListStore)))
        rows = Gtk.GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, Gtk.libgtk), 
                                    Ptr{Gtk._GSList{Gtk.GtkTreePath}},
                                    (Ptr{GObject}, Ptr{GtkTreeModel}), 
                                    selection, model))

        for path in rows
            i = ccall((:gtk_tree_path_to_string, Gtk.libgtk), Ptr{Uint8}, 
                      ( Ptr{GtkTreePath},),
                      path) |> bytestring |> path_to_index
            push!(ret, i)
        end
    else
        ## Gtk.selected *should* work here, but last line gives
        ## coercion issue.
        ## m, iter = selected(selection) # issue with Gtk.selected
        m = Gtk.mutable(Ptr{GtkTreeModel})
        iter = Gtk.mutable(GtkTreeIter)
        res = bool(ccall((:gtk_tree_selection_get_selected,Gtk.libgtk),Cint,
                         (Ptr{GObject},Ptr{Ptr{GtkTreeModel}},Ptr{GtkTreeIter}),
                         selection,m,iter))

        !res && error("No selection of GtkTreeSelection")
        ## what is row?
        i = ccall((:gtk_tree_model_get_string_from_iter, Gtk.libgtk), 
                  Ptr{Uint8}, 
                  (Ptr{GObject}, Ptr{GtkTreeIter}), m[], iter) |> bytestring |> path_to_index
        push!(ret, i)
    end
    ## return just one for tree
    ret[1]
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

## Names
function get_tree_view_names(treeView::GtkTreeView)
    columns = Gtk.GList(ccall((:gtk_tree_view_get_columns, Gtk.libgtk), 
                              Ptr{Gtk._GSList{Gtk.GtkTreeViewColumn}}, (Ptr{GObject},), treeView))
    [getproperty(column, :title, String) for column in columns]
end

function set_tree_view_names(treeView::GtkTreeView, nms::Vector)
    columns = Gtk.GList(ccall((:gtk_tree_view_get_columns, Gtk.libgtk), 
                              Ptr{Gtk._GSList{Gtk.GtkTreeViewColumn}}, (Ptr{GObject},), treeView))
    [setproperty!(column, :title, nm) for (column, nm) in zip(columns, nms)]
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






