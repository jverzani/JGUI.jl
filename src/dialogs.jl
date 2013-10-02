## dialogs -- 


## modal window without methods

## Modal Message box
##
## static (no methods) dialog to display information
##
## Arguments:
##
## * `parent::Widget` used to get toolkit and to locate dialog
## * `text::String` main message
## * `informativeText::String` extra detail for dialog
## * `icon::MaybSymbol` needs implementing
## * `title::MaybeString` title for dialog window, not all OSes display this
##
## Returns
##
## no return value
function messagebox(parent::Widget, text::String; icon::Union(Nothing, String)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) # detail
    messagebox(parent.toolkit, parent, text, icon=icon, title=title, informativeText=informativeText)
    nothing
end

## Modal message box for confirmation 
##
## static (no methods) dialog to get yes/no answer
## 
## Arguments:
##
## * `parent::Widget` used to get toolkit and to locate dialog
## * `text::String` main message
## * `informativeText::String` extra detail for dialog
## * `icon::MaybSymbol` one of `nothing`, `:question`, `:info`, `:warning`, `:critical`
## * `title::MaybeString` title for dialog window, not all OSes display this
##
## Returns:
##
## * returns `:accept` or `:reject` symbol
##
function confirmbox(parent::Widget, text::String; icon::Union(Nothing, Symbol)=nothing,
                    title::Union(Nothing, String)=nothing,
                    informativeText::Union(Nothing, String)=nothing) # detail
    confirmbox(parent.toolkit, parent, text, icon=icon, title=title, informativeText=informativeText)
end

##
## Arguments:
##
## * `mode::Symbol` one of `:open`, `:multiple`, `:directory` or `:save`
## * `:message::String` message
## * `:title::String` title
## * `:filetypes::MaybeVector{Tuple}` a vector of tuples in form
##   `(label, extension`, as in `("jpeg", ".jpg") (In tcltk. For Qt,
##   this can be relaxed to `("Description", "*.jpg *.gif *.png")`,
##   say
## 
## Returns:
##
## depends on `mode`:
## * `:open` a file name or `nothing`
## * `:multiple` a vector of file names or `nothing`
## * `directory` a directory name or `nothing`
## * `save` a filename or `nothing`
##
## TODO:
## setFile, setDirectory..., but hard to do with TclTk
function filedialog(parent::Widget; 
                    mode::Symbol=:open, ## :open, :multiple, :directory, :save
                    message::String="",
                    title::String="",
                    filetypes::Union(Nothing, Vector{Tuple})=nothing)
    
    if findfirst([:open, :multiple, :directory, :save], mode) == 0
        error("mode is one of :open, :multiple, :directory, and :save")
    end

    filedialog(parent.toolkit, parent, mode=mode, message=message, title=title, filetypes=filetypes)
end


## a modeless dialog window

## Esc key in dialog closes window "reject"
## exec() for modal 
type Dialog <: BinContainer
    o
    block
    model
    children
    attrs::Dict
    toolkit
    state::Union(Nothing, Symbol) ## (nothing, :accept, :reject)
    open::Function
    exec::Function
    accept::Function
    reject::Function
    result::Function
    done::Function
    close::Function
    function Dialog(widget, block, toolkit, model) 
        self = new(widget, block,  model, {}, Dict(), toolkit, :reject)
        self.exec = () -> begin
            show_dialog(self.toolkit, self, true)
            setModal(self, true)
        end
        self.open = () -> begin
            show_dialog(self.toolkit, self, true)
        end
        self.done = (value::Symbol) -> begin
            self.state = value
            self.close()
        end
        self.accept = () -> self.done(:accept)
        self.reject = () -> self.done(:reject)
        self.result = () -> self.state
        self.close = () -> begin
            state = self.state
            show_dialog(self.toolkit, self, false)
            notify(self.model, "finished", self.state)
            self.state == :accept ? notify(self.model, "accepted") : 
                                    self.state == :reject ? notify(self.model, "rejected") : nothing
        end
        self
    end
end

## return bin-like container

## Modaless dialog
##
## This constructor produces a non-modal dialog that is used like a bin-container
## Its design follows Qt:
## * one creates a dialog instance with specified buttons, say `dlg`
## * one can add a widget to the dialog through `push!`. This is usually a container for other widgets.
## * One displays the dialog by calling `dlg.exec()` or `dlg.open()`. If possible, `.exec()` will be modal.
## * To get a return value one connects to either the `finished (state)` signal or 
##   the `accepted` or `rejected` signals. Otherwise, `dlg.state` holds the last state of the dialog.
## 
## The dialog is not actually closed, just hidden so one can call `dlg.open()` or `dlg.exec()` again.
##
## Arguments
## * `parent::Widget` used to locate dialog
## * `buttons::Vector{Symbol}=[:ok]` vector of buttons from `:ok`, `:cancel`, `:close`, `:apply`, `:reset`, and `:help`.
## * `default::MaybeSymbol=[:ok]` if specified makes button the default
## * `title::String=""` title for dialog
## * `kwargs...` passed on as properties
##
## Signals
## * `finished (state)` called when button pressed
## * `accepted` called when ok button pressed
## * `rejected` called when cancel or close button pressed.
##
## TODO:
## implement default
function dialog(parent::Widget;
                buttons::Vector{Symbol} = [:ok],
                default::Union(Symbol, Nothing)=nothing,
                title::String="", 
                kwargs...)
    
    model = EventModel()

    widget, block = dialog(parent.toolkit, parent, model, buttons=buttons; default=default, title=title) # use parent for placement too!

    dlg = Dialog(widget, block,  parent.toolkit, model)
    connect(model, "done", state -> dlg.done(state))

    show_dialog(dlg.toolkit, dlg, false)
    add_bindings(dlg.toolkit, dlg)
    for (k, v) in kwargs
        dlg[k] = v
    end
    
    dlg
end

setModal(dlg::Dialog, value::Bool) = setModal(dlg.toolkit, dlg, value)
setModaless(dlg::Dialog, value::Bool) = setModaless(dlg.toolkit, dlg, value)
destroy(dlg::Dialog) = destroy_dialog(dlg.toolkit, dlg)


