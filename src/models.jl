## Models

## A model implements the observable interface
## interface


## methods

##
## signal/slot style
## an observable has events which emit signals
## an observer can connect a slot (a method of the observer)
## connect(observed, signal, observer, slot)

function connect(o::Observable, signal::String, observer, slot)
    if !haskey(o.observers, signal)
        o.observers[signal] = Dict()
    end
    id = randstring(10)
    o.observers[signal][id] = (observer, slot)
    id
end
## A slot can be a simple function too.
function connect(o::Observable, signal::String, slot::Function)
    connect(o, signal, nothing, slot)
end

## for do ntation
connect(slot::Function, o::Observable, signal::String) = connect(o, signal, slot)

## we disconnect by id.
## XXX should include means to block
function disconnect(o::Observable, id::String)
    for (k,v) in o.observers
        if haskey(v, id)
            delete!(v, id)
            break
        end
    end
end

## when calling notify the values must be passed in
##
## XXX put in code to catch if observer is still extant? Remove if not...
function notify(o::Observable, signal, values...)
    if !haskey(o.observers, signal) return end
    obs = o.observers[signal]
    for (k, v) in obs
        observer, slot = v
        if isa(observer, Nothing)
            slot(values...)
#            try slot(value...) catch e nothing end
        else
            slot(observer, values...)
#            try slot(observer, values...) catch e nothing end
        end
    end
end


## methods
## This allows o[:value] to work.
getValue(model::Observable) = model.value
setValue(model::Observable, value::Nothing; signal::Bool=true) = nothing
function setValue(model::Observable, value; signal::Bool=true)
    if value != model.value
        model.value = value
        signal && notify(model, "valueChanged", getValue(model))
    end
    value
end

type EventModel <: Observable
    observers::Dict
    EventModel() = new(Dict())
end

## Model has value
abstract Model <: Observable

type ItemModel <: Model
    observers::Dict
    ##
    value
    ItemModel() = new(Dict(), nothing)
    ItemModel(value) = new(Dict(), value)
end


## signals
## valueChanged, (value)



abstract AbstractArrayModel <: Model
type VectorModel <: AbstractArrayModel
    observers::Dict
    ##
    value
    items::Vector
    VectorModel() = new(Dict(), nothing, {})
    VectorModel(items) = new(Dict(), items[1], items)
    VectorModel(items, value) = new(Dict(), value, items)
end

## store index in 1:100, 1:100, getValue of widget converts
type TwoDSliderModel <: AbstractArrayModel
    observers::Dict
    ##
    value
    items1::Vector
    items2::Vector
    TwoDSliderModel() = new(Dict(), nothing, {}, {})
    TwoDSliderModel(items1, items2) = new(Dict(), [items1[1], items2[1]], items1, items2)
    TwoDSliderModel(items1, items2, value) = new(Dict(), value, items1, items2)
end

function getValue(o::TwoDSliderModel)
    i, j = o.value
    x = iround(1 + (length(o.items1) - 1)/(100 -1)*(i - 1))
    y = iround(1 + (length(o.items2) - 1)/(100 -1)*(j - 1))
    [x,y]
end

## value in items coordinates, convert to index
function setValue(o::TwoDSliderModel, value; signal::Bool=true)
    x, y = value
    function item2ind(item, items) 
        ix = indmin(abs(items - item))
        iround( 1 + (100 - 1)/(length(items) - 1)*(ix -1))
    end
    i = item2ind(x, o.items1)
    j = item2ind(y, o.items2)
    if o.value != [i,j]
        o.value = [i,j]
        signal && notify(o, "valueChanged", getValue(o))
    end
end

type ArrayModel <: AbstractArrayModel
    observers::Dict
    ##
    value
    items::Array
    ArrayModel() = new(Dict(), nothing, {})
    ArrayModel(items) = new(Dict(), items[1], items)
    ArrayModel(value, items) = new(Dict(), value, items)
end

## o[:items] ...
getItems(model::AbstractArrayModel) = model.items
function setItems(model::AbstractArrayModel, items)
    old_items = model.items
    model.items = items
    notify(model, "itemsChanged", items, old_items)
end


### Stores
## A store is comprised of a vector of items wi
## A model item is nothing more than a composite type, but we offer
## this type in case one wants to subtype
abstract AbstractStoreItem


## May be needed by some (e.g., Tk)
to_string(m::Any, x) = string(x)
from_string(m::Any, field::Symbol, x) = convert(eltype(m.(field)), x)

abstract DataStore <: Object


type Store <: DataStore
    model::Observable
    types::Vector{DataType}
    items::Vector
    Store(types...) = new(ItemModel(), [types...],  Vector[])
end


length(s::DataStore) = length(s.items)
size(s::DataStore) = [length(s), length(s.items[1])]

getindex(s::DataStore, i::Int) = s.items[i]
getindex(s::DataStore, i::Int, j::Int) = s.items[i][j]
setindex!(s::DataStore, val, i::Int) = replace!(s, i, val)
function setindex!(s::DataStore, val, i::Int, j::Int) 
    cur = s[i]
    cur[j] = val
    replace!(s, i, cur)
end


function insert!(s::DataStore, i::Int, vals)
    ## verify types
    vals = [convert(T,v) for (T, v) in zip(s.types, vals)]
    insert!(s.items, i, vals)
    notify(s.model, "rowInserted", i)
end

function splice!(s::DataStore, i::Int)
    items = splice!(s.items, i)
    notify(s.model, "rowRemoved", i)
    items
end

function replace!(s::DataStore, i::Int, item)
    if i < 1 || i > length(s.items)
        error("Index is out of bounds for replacing")
    end
    s.items[i] = item
    notify(s.model, "rowUpdated", i)
end

push!(s::DataStore, val) = insert!(s, length(s)+1, val)
prepend!(s::DataStore, val) = insert!(s, 1, val)
append!(s::DataStore, vals::Vector) = map(val -> push!(s, val), vals)

pop!(s::DataStore) = splice!(s::DataStore, length(s))


## Trees
type TreeNode <: Object
    text::String
    icon
    data                        # DataType
    index                       # from treeview (couples to tree view, don't like...)
    parent                      # nothing, 
    children::Vector            # TreeNodes
end

function node_to_values(node::TreeNode)
    ds = node.data
    String[string(d) for d in ds]
end



abstract AbstractTreeStore <: DataStore

## Would like to put in data type here...
type TreeStore <: DataStore
    model::Observable
    types::Vector{DataType}
    children::Vector{TreeNode}
    attrs::Dict
    TreeStore(types...) = new(ItemModel(), [types...], TreeNode[], Dict())
end

## A store for display through `treeview`
## 
## a treestore holds tree nodes. Each node holds a label, optional data [and an icon]. The
## nodes are most easily created from a label and data from insert!
##
## Nodes should have data all from the same CompositeType (as with `storeview`). It is not 
## necessary, as often nodes that expand are not of the same type (directories are different from files, say).
##
## A node in a tree has a corresponding path -- a vector of
## indices. The functions `node_to_path` and `path_to_node`
## translate.
##
## Nodes can be expanded or collapsed through `expand_node` and `collapse_node`
##
##
treestore(types...) = TreeStore(types...)


## some store methods
function index_of(node::TreeNode)
    parentnode = node.parent
    findfirst(parentnode.children, node)
end

## A path is 1-based index through children
## this finds path from a node
function node_to_path(node::TreeNode)
    path = Int[]
    path = [index_of(node)]
    parent = node.parent
    while !isa(parent, Union(TreeStore, Nothing))
        unshift!(path, index_of(parent))
    end
    path
end

## this finds node from a path
function path_to_node(store::TreeStore, path::Vector{Int})
    i = shift!(path)
    node = store.children[i]
    while length(path) > 0
        i = shift!(path)
        node = node.children[i]
    end
    node
end


function insert!(store::TreeStore, parentnode::Union(Nothing, TreeNode), i::Int, childnode::TreeNode)
    if parentnode == nothing
        parentnode = store
    end

    childnode.parent = parentnode
    insert!(parentnode.children, i, childnode)
    notify(store.model, "insertNode", parentnode, i, childnode)
end
## data an instance of a type of nothing
function insert!(store::TreeStore, parentnode::Union(Nothing, TreeNode), i::Int, text::String, data) 
    childnode = TreeNode(text, nothing, data, nothing, parentnode, {})
    insert!(store, parentnode, i, childnode)
    childnode
end
function push!(tr::TreeStore, parentnode::Union(Nothing, TreeNode), node::TreeNode)
    n= parentnode == nothing ? length(tr.children) : length(parentnode.children)
    insert!(tr, parentnode, n+1, node)
end
function push!(tr::TreeStore, parentnode::Union(Nothing, TreeNode), text::String, data) 
    childnode = TreeNode(text, nothing, data, nothing, parentnode, {})
    push!(tr, parentnode, childnode)
end
unshift!(tr::TreeStore, parentnode::Union(Nothing, TreeNode), node::TreeNode) = insert!(tr, parentnode, 1, node)
unshift!(tr::TreeStore, parentnode::Union(Nothing, TreeNode), text::String, data) = insert!(tr, parentnode, 1, node)

function splice!(store::TreeStore, parentnode::Union(Nothing, TreeNode), i::Int)
    if isa(parentnode, Nothing)
        parentnode = store
    end
    splice!(parentnode.children, i)
    notify(store.model, "removeNode", parentnode, i)
end
function pop!(store::TreeStore, node::TreeNode)
    parentnode = node.parent
    ### how to get indexof node
    i = index_of(node)

    splice!(store, parentnode, i)
end

## update node properties text and/or data (XXX Icons!)
function update_node(store::TreeStore, node::TreeNode; text::Union(Nothing, String)=nothing, data::Union(Nothing, Any)=nothing)
    if !isa(text, Nothing)
        node.text = text
    end
    if !isa(data, Nothing)
        node.data = data
    end
    notify(store.model, "updatedNode", node)
end

