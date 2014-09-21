## JGUI tests
using Base.Test

## tests should not be interactive, but here we want to test the toolkit
## select toolkit
function select_toolkit()
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
    
if !haskey(ENV, "toolkit")
    select_toolkit()
end
using JGUI


## Okay

# windows
w = window(title="test", size=[300,300])
raise(w)
## children
## add child
b = button(w, "child")
push!(w, b)

## error: add two or more children
b2 = button(w, "error?")
@test_throws ErrorException   push!(w, b2)

## remove child
pop!(w)

## modify property
w[:title] = "new title"
@assert w[:title] == "new title"

## delete
destroy(w)


# Box containers

w = window(title="box containers")
g = hbox(w); push!(w,g)
btns = [button(g, string(i)) for i in 1:4]
map(child -> push!(g, child), btns)
raise(w)

## manipulate queue
### push!
btn = button(g, "5")
push!(g, btn)

## insert!
btn = button(g, "1 1/2")
insert!(g, 2, btn)

## pop! (last)
pop!(g)

## shift!(first)
shift!(g)

## delete!
child = g[2]
delete!(g, child)

destroy(w)

## Sizing, spacing
w = window(title="sizing")
g = vbox(w)
push!(w, g)


## labelframe

## grid container

## notebook container

# Widgets
w = window(title="Widgets")
g = vbox(w)
push!(w, g)

## text

### label
lab = label(g, "text")
push!(g, lab)

@assert lab[:value]  == "text"
lab[:value] = "new text"
@assert lab[:value]  == "new text"

push!(g, separator(g))

### lineedit
ed = lineedit(g, "")
push!(g, ed)

ed[:value] = "new value"
@assert ed[:value] == "new value"

ed1 = lineedit(g, "0", coerce=parseint)
push!(g, ed1)
@assert ed1[:value] == 0
ed1[:value] = 20
@assert ed1[:value] == 20


push!(g, separator(g))

### textedit ###


### action ###

### button

### menubar

### toolbar

## selection

### checkbox

### checkbutton

### radio


####### button group #####
using Base.Test
using JGUI

w = window(title = "Button group")
f = vbox(w); push!(w, f)

## exclusive
choices = ["one", "two", "three"]

### no initial
b1 = buttongroup(f, choices, exclusive=true); push!(b1)

@assert b1[:value] == nothing
b1[:value] = "one"
@assert b1[:value] == "one"

### initial
b2 = buttongroup(f, choices, choices[1], exclusive=true); push!(b2)

@assert b2[:value] == choices[1]

## non-exclusive

### no initial
b3 = buttongroup(f, choices, exclusive=false); push!(b3)

@assert b3[:value] == String[]
b3[:value] = ["one"]
@assert b3[:value] == ["one"]

### initial
b4 = buttongroup(f, choices, choices[1:2], exclusive=false); push!(b4)

@assert b4[:value] == choices[1:2]


### combobox

### table

### slider

### spinbox

### 2dslider

## images

### imageview

### cairographics/pyplot graphics


## models

### treeview


## Dialogs

