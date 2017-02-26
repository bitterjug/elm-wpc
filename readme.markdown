Wordpress REST Api client in Elm
=================================

Currently I'm building and running with this:

```
elm-live --open --pushstate --dir=src/static src/elm/Main.elm --output src/static/Main.js
```
To Do
=======

- [x] Make list entries click through to their corresponding pages

- [x] Add a previous link to the previous blog's address
  So that I don't have to type in a full slug

- [ ] Now when rendering a blog, if the previous link isn't available, we should
  kick off a request for the next page of entries, and when those arrive we should
  redraw and recalculate whether the previous is available

- [ ] Adding buttons to cards is going to entail giving each one an unique button id number
