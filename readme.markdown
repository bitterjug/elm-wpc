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

- [x]  We may chose to use
   [HttpBuilder](http://package.elm-lang.org/packages/lukewestby/elm-http-builder/5.0.0/HttpBuilder)
   for this to make it easier to build up the request.
- [x] Try using [elm-date-extra](http://package.elm-lang.org/packages/justinmimbs/elm-date-extra/2.0.1/Date-Extra#fromIsoString) to parse and format iso dates instead of Date.Format

- [x] Switching to the `date_gmt` -- and adding a Z to force UTC interpretation
when decoding -- has solved, finally, the problem of fetching duplicate
entries as neighbours. But now I notice that the time displayed in each
post is an hour out, as if some time zone is being applied to it without
my approval

- [ ] We need a way to trigger fetching more entries when navigating the 
list view. Ideally that would be triggered by scrolling. Have to look into 
infinite scroll.

  Then we're going to need to extend the model to include some notion of what
  page (s) of the json have been fetched and cached. So that we know when to go
  looking for more of it. 

  A simple model assumes we're starting from the most recent first page And we
  just extend back in time.  But if we're starting from a single entry entered
  in the url bar we probably need two queries, with different orderings,
  heading forward and backward from that entry.

  So, when responding to a request for a specific slug, we will:

  - fetch that entry using a post search by slug:

      http://bitterjug.localhost
      GET /wp-json/wp/v2/posts?slug=minimal-elm-program

  - Find it's date and then fetch the following and previous entires
  with requests like:

      http://bitterjug.localhost
      GET /wp-json/wp/v2/posts?before=2017-02-08T21:01:52

  Not sure yet how we mark the 'before' and 'after' payloads so we know whether
  to prepend or append them to the cached list. To date, while using the page
  number, I encoded it in the type of the message function. Now we _could_ get
  that from the incoming data headers? Perhaps not. The only header that
  identifies what query was used to generate this result is the Link:next one,
  and if we're on the last page, I don't think we actually get that one.  So I
  probably do need to encode the meaning of the request in the return message
  somehow so that we know what to do with it when we get it.

  So we will have options like:
  - Selected post, 
    - replace the current list with this as a singleton
    - set the current index to 0
    - Search for neighbours and set off requests for the next and previous
      pages
  - Previous / Next content
    - Prepend / Append to the list and recalculate the appropriate neighbours

  We can use the index as the neighbour. If current is [0] then we have
  no next and the previous is [1]. 

  I think we might actually use an array for the cache.

  Now the route and model appear to be different for the first time. Or the
  difference is finally meaningful:

  - When we get a location we are going to parse the slug out of it.  Then the
    Msg will be to view the corresponding page.  But, at first, we won't have
    data for that so we will kick off a get request for it (do we need to keep
    the slug in the model at this point, and make a note that we're awaiting
    it?) We will be in a loading state and shoudl probably display a loading
    message (as the page) during that state.

 - Then once we get the data we can store it in the array, and set the current
   page to be the index of the corresponding page in our array.

 - We might get a response that says the slug can't be found in which case were
   going to transition to a proper 404 page.

 - We need a way to get a route from a Location, and a Location (url) from 
   a page.


- [ ] Do we need a way to know if we've reached the actual beginning or end of the 
  list of entries so as to avoid repeatedly requesting the next page at the end?

  The response headers give us that information 

- [ ] Adding buttons to cards is going to entail giving each one an unique button id number

