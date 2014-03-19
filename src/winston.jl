## extensions for Winston

## Pkg.installed() is _slow_
if "Winston" in readdir(Pkg.dir())
    using Winston
    
    ## add display method with graphics device as first argument
    ## not in multimedia spec, but is in winston
    function Base.display(cg::CairoGraphics, pc::Winston.PlotContainer)
        c = cg[:widget]
        c.draw = function(_)
            ctx = Base.Graphics.getgc(c)
            Base.Graphics.set_source_rgb(ctx, 1, 1, 1)
            Cairo.paint(ctx)
            Winston.page_compose(pc, Gtk.cairo_surface(c))
        end
            Gtk.draw(c)
        end
        
        function DisplayPlot(self::ManipulateObject, x::Winston.FramedPlot; kwargs...) 
            if isa(x, Nothing) return end
            oa = self.output_area
            
            if length(children(oa)) > 0 && isa(oa.children[1], CairoGraphics)
                cnv = oa.children[1]
                display(cnv, x)
#                Winston.display(cnv.o, x)
                return
            elseif length(children(oa)) > 0
                pop!(oa)
            end
            ## add one
            cnv = cairographic(oa, width=480, height=480)
            cnv[:sizepolicy] = (:expand, :expand)
            push!(oa, cnv)
            display(cnv, x)
#            Winston.display(cnv.o, x)
        end
        
        ## union has some ambiguity warnings
        Display(::MIME"application/x-tcltk", self::ManipulateObject, x::Winston.FramedPlot; kwargs...) = DisplayPlot(self, x; kwargs...)
        Display(::MIME"application/x-gtk", self::ManipulateObject, x::Winston.FramedPlot; kwargs...) = DisplayPlot(self, x; kwargs...)
                         

end