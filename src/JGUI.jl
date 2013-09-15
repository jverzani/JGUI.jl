module JGUI


## for Images
##using Images XXX  merge in possibly...
##using Cairo
##using Base.Graphics


import Base: show
import Base: getindex, setindex!, length, push!, append!, prepend!, insert!, splice!, shift!, unshift!, pop!, findin
import Base: size, endof, ndims
import Base: connect, notify


export properties

export getValue, setValue, setIcon

export disconnect


export window, 
       destroy, raise, lower

export labelframe,
       hbox, vbox, 
       formlayout,
       notebook,
       children,
       grid,
       row_minimum_height, column_minimum_width, row_stretch, column_stretch

export label, separator, button, lineedit, textedit,
       checkbox, radiogroup, buttongroup, combobox,
       slider, slider2d,
       listview, storeview, treeview, 
       imageview,
       icon

export Store, TreeStore

export treestore, expand_node, collapse_node, node_to_path, path_to_node, update_node

export filedialog, messagebox, confirmbox, dialog
export manipulate


include("types.jl")
include("methods.jl")
include("icons.jl")
include("models.jl")
include("containers.jl")
include("widgets.jl")
include("dialogs.jl")


## To use different toolkit try ENV["Tk"] = true, or ENV["Qt"] = true
istk() = haskey(ENV,"Tk") && ENV["Tk"] == "true"
isqt() = !istk()

include("manipulate.jl")
if istk()
    default_toolkit = MIME("application/x-tcltk")
    include("tk.jl")
    export cairographic
elseif isqt()
    default_toolkit = MIME("application/x-qt")
    include("qt.jl")
    export pyplotgraphic
end





end