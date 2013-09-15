
## put conditional on Winston load
using Winston
function Display(self::ManipulateObject, x::FramedPlot; kwargs...) 
    if isa(x, Nothing) return end
    oa = self.output_area

    if length(children(oa)) > 0 && isa(oa.children[1], CairoGraphics)
        cnv = oa.children[1]
        Winston.display(cnv.o, x)
        return
    elseif length(children(oa)) > 0
        pop!(oa)
    end
    ## add one
    cnv = cairographic(oa, width=480, height=480)
    cnv[:sizepolicy] = (:expand, :expand)
    push!(oa, cnv)
    Winston.display(cnv.o, x)
end

