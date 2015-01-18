module JGUI


import Base: show
import Base: getindex, setindex!, length, 
             push!, append!, prepend!, insert!, splice!, delete!, shift!, unshift!, pop!,
             findin
import Base: size, endof, ndims
import Base: connect, notify

export properties

export getValue, setValue, setIcon
export replace!

export disconnect


export window, 
       destroy, raise, lower

export labelframe,
       box, hbox, vbox, addstretch, addstrut, addspacing,
       formlayout,
       notebook,
       children,
       grid,
       row_minimum_height, column_minimum_width, row_stretch, column_stretch

export label, separator, button, lineedit, textedit,
       checkbox, radiogroup, buttongroup, combobox,
       slider, slider2d, spinbox,
       listview, storeview, treeview, 
       imageview,
       icon

export Store, TreeStore

export treestore, expand_node, collapse_node, node_to_path, path_to_node, update_node

export filedialog, messagebox, confirmbox, dialog

export action, menubar, menu,
       addMenu, addAction



## adjust this to pick a gtoolkit
function pick_toolkit()
    toolkits = ["Gtk", "Tk", "Qt"]
    toolkit_map = {"Gtk"=>"Gtk", "Tk"=>"Tk", "Qt"=>"PySide"}

    ## filter these

    println("Which toolkit to use:")
    for (i, kit) in enumerate(toolkits)
        println("\t[$i] $kit")
    end
    i = parseint(chomp(readline()))

    toolkit = toolkits[i]
    ENV["toolkit"] = toolkit
end

## which toolkit?
#__init__() = haskey(ENV, "toolkit") || pick_toolkit()
if !haskey(ENV, "toolkit")
    ENV["toolkit"] = "Gtk"      # default to Gtk for now
end

export manipulate



isqt() = lowercase(ENV["toolkit"]) == lowercase("Qt")
istk() = lowercase(ENV["toolkit"]) == lowercase("Tk") 
isgtk() = lowercase(ENV["toolkit"]) == lowercase("Gtk")

if istk()
    using Tk
elseif isqt()
    using PyCall
    using PySide
    import PySide: raise, setFocus, setIcon
elseif isgtk()
    using Gtk, Cairo
end

using Docile
@docstrings



include("types.jl")


include("methods.jl")
include("icons.jl")
include("models.jl")
include("containers.jl")
include("widgets.jl")
include("dialogs.jl")
include("menu.jl")
include("manipulate.jl")        # code depends on Tk or Qt


if istk()
    default_toolkit = MIME("application/x-tcltk")
    include("tk.jl")
    ENV["WINSTON_OUTPUT"] = :tk
    export cairographic
    include("winston.jl")
elseif isqt()
    default_toolkit = MIME("application/x-qt")
    include("qt.jl")
    export pyplotgraphic
elseif isgtk()
    default_toolkit = MIME("application/x-gtk")
    include("gtk.jl")
    ENV["WINSTON_OUTPUT"] = :gtk
    export cairographic
    include("winston.jl")
end







end
