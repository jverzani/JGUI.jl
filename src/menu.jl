## API for menus
type Action <: Widget
    o
    toolkit
    label
    tooltip
    shortcut
    icon
    command
end

function action(parent, label::String, shortcut::Union(Nothing,String), icon::Union(Nothing, Icon), command::Function)
    o = action(parent.toolkit, parent)
    a = Action(o, parent.toolkit, label, nothing, shortcut, icon, command)
    a[:label] = label
    if !isa(shortcut, Nothing)  a[:shortcut] = shortcut end
    if !isa(icon, Nothing)  a[:icon] = icon end
    a[:command] = command
    a
end

action(parent, label::String, icon::Icon, command::Function) = action(parent, label, nothing, icon, command)
action(parent, label::String, command::Function) = action(parent, label, nothing, nothing, command)

## properties
getWidget(action::Action) = action.o
getEnabled(action::Action) = getEnabled(action.toolkit, action)
setEnabled(action::Action, value::Bool) = setEnabled(action.toolkit, action, value)

getLabel(action::Action)  = getLabel(action.toolkit, action)
setLabel(action::Action, label::String) = setLabel(action.toolkit, action, label)

getIcon(action::Action) = a.icon
function setIcon(action::Action, icon::Icon) 
    action.icon = icon
    setIcon(action.toolkit, action, icon)
end

getShortcut(action::Action) = a.shortcut
function setShortcut(action::Action, shortcut::String)
    action.shortcut = shortcut
    setShortcut(action.toolkit, action, shortcut)
end

getTooltip(action::Action) = action.tooltip
function setTooltip(action::Action, tooltip::String)
    action.tooltip = tooltip
    setTooltip(action.toolkit, action, tooltip)
end

setCommand(action::Action, command::Function) = setCommand(action.toolkit, action, command)

## MenuBar for attaching to a window
type MenuBar <: Container
    o
    toolkit
end

## Menu is flexible (attached to menubar, menu or widget (for popup))
type Menu <: Container
    o
    toolkit
end

function menubar(parent)
    mb = menubar(parent.toolkit, parent::Window)
    MenuBar(mb, parent.toolkit)
end

## return Menu Instance
function addMenu(menubar::MenuBar, label::String)
    menu(menubar, label)
end


## menu is used with menubar and for popups
## parent is
## - MenuBar instance -- toplevel submenu
## - Menu instance -- will be submenu
## - widget -- menu will be popup menu, actions may be passed (i) -> if storeview, ...
function menu(parent::MenuBar, label::String)
    widget = menu(parent.toolkit, parent, label)
    Menu(widget, parent.toolkit)
end

function menu(parent::Menu, label::String)
    widget = menu(parent.toolkit, parent, label)
    Menu(widget, parent.toolkit)
end

function menu(parent::Widget)
    widget = menu(parent.toolkit, parent)
    Menu(widget, parent.toolkit)
end




function addAction(menu::Menu, action::Action)
    addAction(menu.toolkit, menu, action)
end


function addAction(menu::Menu, sep::Separator)
    addAction(menu.toolkit, menu, sep)
end



function addAction(menu::Menu, rg::RadioGroup)
    addAction(menu.toolkit, menu, rg)
end


function addAction(menu::Menu, cb::CheckBox)
    addAction(menu.toolkit, menu, cb)
end
