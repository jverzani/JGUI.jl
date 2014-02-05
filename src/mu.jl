## Example of how to parse mustache template to insert
## graphic. This could be part of mustache bit
## wish there were a way to *easily* get markup in the text buffer...
using Mustache, Gtk

tpl = mt"""
This is a mustache
template bold
complete with lots of stuff
what is --> {{x}} <--?
and 
{{p}}
and whatever
"""

x = "this is x"
p = "/Users/verzani/test.png"

## in Gtk
using Gtk


function Base.push!(tview::GtkTextView, str::String)
    buffer = tview[:buffer, GtkTextBuffer]
    insert!(buffer, str)
end

function Base.push!(tview::GtkTextView, child::Gtk.GtkImage)
    buffer = tview[:buffer, GtkTextBuffer]

    ## make an end iter
    enditer = Gtk.GtkTextIter(buffer)
    ccall((:gtk_text_buffer_get_end_iter, Gtk.libgtk), Void, (Ptr{Gtk.GObject}, Ptr{Void}), buffer, enditer.handle)

    anchor = ccall((:gtk_text_buffer_create_child_anchor, Gtk.libgtk),Ptr{Void},
                   (Ptr{Gtk.GObject},Ptr{Void}),buffer, enditer.handle)

    ccall((:gtk_text_view_add_child_at_anchor, Gtk.libgtk),Void,
          (Ptr{Gtk.GObject},Ptr{Gtk.GObject},Ptr{Void}), tview, child, anchor)
    
    child[:visible] = true
end


## show tpl
w = GtkWindow()
tv = GtkTextView()
push!(w, tv)

function add_tpl(tpl, x="this is x")
    tv[:buffer, Gtk.GtkTextBuffer][:text] = ""
    ## how to show a mustache template
    for (t, l, b, e) in tpl.tokens
        if t == "text"
            push!(tv, l)
        else ## if type == "name"
            ## look up and render accordingly
            obj = Main.(symbol(l))
            if isfile(obj)
                child = Gtk.Image(obj)
                push!(tv, child)
            else
                push!(tv, string(obj))
            end
        end
    end
end

for i in 1:10
    x =i
    add_tpl(tpl, i)
end