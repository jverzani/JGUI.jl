**write tests**
window: closeHandler (return logical, only one so not a model)
cairographics: (x,y) in which coordinates? pixels? Use Tim Holy's conversion to user coordinates?
storeview: work on passing in type via parameterization {T}
treeview, storeview -- get headers from var names. Use a_b convention to map to "a b"
menubars: shortcuts
svg, html...

# Qt

storeview: update state
icons in storeview
dialog return value -- must look up in dlg.state
<del>menus: radiobuttons and checkbuttons have issues</del>
<del>imageview -- ain't working</del>
<del>storeview: hooke up model -> view callbacks </del>
<del>box: strectch and expand argument...</del>

# Tk

warnings on loading Tk

# Gtk

* need treeview
* spacing, sizing, ..
- implemented for 3.x. It is odd though. Child sizepolicy effects all siblings in a box container.
[The following need constructors...]
* modal window()
* dialogs
* menubars: radio and checkbuttons

# bonepile
<del>spinbox</del>
<del>lineedit: typeahead (Tk) -- too lazy to implement for Tk</del>
<del>combobox: editable -- don't want this</del>
<del>menubar</del>
<del>focus method</del>
<del>connector/plug? some innerbox, outerbox language to refer to block and the reciever of the block</del>
<del>slider2d:  check</del>
<del>window: geometry x,y positions</del>
<del>lineedit: placeholder text</del>
<del>buttons: images (stock gif images?)</del>
<del>child: padding</del>
<del>images: put onto tree/array, </del>
<del>radiobox: (Make sure assignment is valid, before setting); rb should be vector valued.(not restricted to numeric);<del>
<del>image: ? (imageview)</del>
<del>checkbox</del>
<del>slider2d: setValue</del>
<del>separator: broken</del>
<del>listbox</del>
<del>arrayviewer, dataframe viewer, ...?<del>
<del>tree widget (Use items but allow children...)<del>
<del>notebook</del>
<del>slider: valueChanged not working to update button...</del>
