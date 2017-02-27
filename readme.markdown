Wordpress REST Api client in Elm
=================================

Currently I'm building and running with this:

```
elm-live --open --pushstate --dir=src/static src/elm/Main.elm --output src/static/Main.js
```
To Doer
=======

- [x] Make list entries click through to their corresponding pages

- [x] Add a previous link to the previous blog's address
  So that I don't have to type in a full slug

- [x] At the moment we don't know until we try and render a post page -- and
  its neighbours -- if we need to fetch more data or not. Bu that's the wrong
  place. The right place is in update. So perhaps we should set the previous
  and next as part of the update. Either we set them there or we just check for
  them there. That seems wasteful to calculate the neighbours twice.

- [ ] Now when rendering a blog, if the previous link isn't available, we should
  kick off a request for the next page of entries, and when those arrive we should
  redraw and recalculate whether the previous is available

  - [x] The problem here was that when we're rendering it, its too late, we
    need to do that during update. So first we have to refactor the code
    so that the neighbours get recalculated  when a) we visit a single entry
    page or, b) when we receive more data from the server which might provide
    neighbours for an antry we didnt previously have neighbours for.


- [x] Create separate module for Wordpress REST API

- we're going to need to get at the response headers which means we'll need
  expectStringResponse and the only way to set that up is apparently to 
  build a custom request

   We may chose to use
   [HttpBuilder](http://package.elm-lang.org/packages/lukewestby/elm-http-builder/5.0.0/HttpBuilder)
   for this to make it easier to build up the request.

  Then we're going to need to extend the model to include some notion of what
  page (s) of the json have been fetched and cached. So that we know when to go
  looking for more of it. 

  A simple model assumes we're starting from the most recent first page
  And we just extend back in time.

  But if we're starting from a single entry entered in the url bar
  we probably need two queries, with different orderings, heading
  forward and backward from that entry.


- [ ] Do we need a way to know if we've reached the actual beginning or end of the 
  list of entries so as to avoid repeatedly requesting the next page at the end?

  The response headers give us that information 

- [ ] Adding buttons to cards is going to entail giving each one an unique button id number

