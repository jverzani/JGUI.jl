module JGUI

using Tk
## for Images
using Images
using Cairo
using Base.Graphics


import Base: show
import Base: getindex, setindex!, length, push!, append!, prepend!, insert!, splice!, shift!, unshift!, pop!, findin
import Base: size, endof, ndims
import Base: notify

export getValue, setValue, connect, disconnect,
       destroy

export window, labelframe,
       hbox, vbox, 
       grid, formlayout,
       notebook,
       children,
       row_minimum_height, column_minimum_width, row_stretch, column_stretch

export label, separator, button, lineedit, textedit,
       checkbox, radiogroup, buttongroup, combobox,
       slider, slider2d,
       listview, storeview, treeview, 
       cairographics, imageview

export Store

export treestore, expand_node, collapse_node, node_to_path, path_to_node, update_node

export filedialog, messagebox, confirmbox, dialog

export manipulate


include("types.jl")
include("methods.jl")
include("models.jl")
include("containers.jl")
include("widgets.jl")
include("dialogs.jl")
include("tk.jl")
include("manipulate.jl")


end