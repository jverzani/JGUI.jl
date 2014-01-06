## icon support

## Theme points to a directory :default...


abstract Icon
type StockIcon <: Icon
    nm::Union(Nothing, Symbol)
    theme::Union(Nothing, Symbol)
end

type FileIcon <: Icon
    file::String
end

## constructor
icon(nm::Symbol, theme::Symbol=nothing) = StockIcon(nm, theme)
icon(nm::Symbol) = StockIcon(nm, nothing)
function icon(nm::String)
    isfile(nm) || error("Not a file name: $nm")
    FileIcon(nm)
end

