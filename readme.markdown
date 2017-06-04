Wordpress REST Api client in Elm
=================================

Currently I'm building and running with this:

```
elm-live --open --pushstate --dir=src/static src/elm/Main.elm --output src/static/Main.js
```
To Do
=====

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

- [x] Try using
  [elm-date-extra](http://package.elm-lang.org/packages/justinmimbs/elm-date-extra/2.0.1/Date-Extra#fromIsoString)
  to parse and format iso dates instead of Date.Format

- [x] Switching to the `date_gmt` -- and adding a Z to force UTC interpretation
  when decoding -- has solved, finally, the problem of fetching duplicate
  entries as neighbours. But now I notice that the time displayed in each post
  is an hour out, as if some time zone is being applied to it without my
  approval

- [x] Make the single page view just expand one entry in the list flow

- [x] When we click a card to view the details, that card's `offsetTop`
  should be stored and we should scroll to that position.
   
  We get the new scroll distance from a card when we click it which is of
  course before we render the new page.  There are problems with this. If there
  is an expanded card above the one you click the scroll height we move to
  includes the height of that expanded card which won't be there after we
  redraw. So the new height isn't right.  And if we go to a card directly via
  the url we don't have a scroll distance for it. 

  So we need to calculate the appropriate new scroll height either from 
  first principles about the height and number of cards in the stack (which
  might lay the groundwork for reverse infinite scroll) or after we have
  rendered the new page, when things are in their correct final positions.

  - So what if we knew the width of the containing div, and of the cards?
    Cards could have fixed width, and probably should. And we can get the size
    of the div using DOM library in a task. Kick off a task when we start the
    program (do we need to have rendered a frame yet?) and have a subscription
    for window resize events and check it again.  As we have to reflow anyway.
    Then we know how the cards stack in the grid and we should be able to
    calculate the position that the top of a given expanded card *should* be.

 - If we get the window size, and maintain it, we can override the MDL
   calculated column widths and set the main column size to something we 
   know is an exact multiple of the card width.

- [x] Calculate exact widths for 1, 2 and 3 columns of cards. 

- [x] Find out the breakpoints MDL uses, or chose breakpoints for column
  counts. (Maybe switch to mobile first and just use one column while we get
  the maths sorted?

  - This kinda works where we just divide the main column width by up to 
  three times the card width. And pad it out to make it look centred if its bigger
  than one of those.

- [x] Hard code the style attribute on the main column to allow exactly 1 2 or
  3 card columns withing it and keep the number of card columns in the model
  (or calculable from the current screen size in the model).

- [x] Calculate and cache the main column width when the window resizes, not
  every time we render. I expect us to render lots more times than the window
  resizes. Probably don't need to store the actual window width at all.

  Actually cache the number of columns as a compromise as it makes it easier
  to calculate the `scrollY` distance.

- [x] When we open a card we calculate the scroll distance to its top not from
  the position where we clicked (because of the problem above with expanded
  cards above) but from the number of cards before it in the column and the
  current column width and known height of compact cards.

- [x] Now, when we visit a card in the middle of a run it probably calculates
  the scroll distance correctly initially, but when the predecessors arrive we
  don't re-calculate or re-adjust the `scrollY` to account for inserting them
  so we end up in the wrong place.

  Interestingly this looks pretty much like the solution to the reverse infinite
  scroll problem of adding predecessors. 

  1. When you're looking at a single entry, receiving later entries can still
     scroll to the current item (there is a case where we have scrolled off
     since the initial display, which we might want to catch later by watching
     the on scroll event, in which case, 2. below applies).

  2. When you're looking at a list of entries and you receive later ones (later
     ones are higher up the page, so this is the reverse scroll case) you need
     to work out how far you are currently scrolled, then how much height the
     additional previous entries will account for and then ask to scroll to
     that amount. 

- [ ] WIP: Do the same for Fetch Later as we have done for Fetch Earlier and make
  upward scrolling work.

  This is kinda working: the more button gets displayed and you can click on it
  to trigger a fetch. But:

  - The action isn't yet triggered by a scroll event

  - The `PostList Later` branch of `update` does a `scrollToEntry` to position
    the selected entry in the right place, which has the effect of zipping us
    back to the focussed item rather than letting us scroll up. 

  Now this is correct behaviour when we're viewing a single item and we just
  fetched the single page of entries that precede it: we didn't get triggered
  by a scroll event, or a click on he button, we were triggered automatically
  because only one entry was fetched and we need its neighbours to have a
  proper up to date display. Because rebuilding the page with entries above
  changes the layout and the result is that the focussed entry effectively 
  moves down the page, so we need to move to it.  

  But its not the right behaviour when we were triggered by a scroll event (or
  click on the more button). In this case we assume the user is no longer
  looking at the current entry (although the URL/route hasn't yet been updated
  to suggest that his is no longer the case) but at, for example, whatever item
  is the first one after that button. So maybe we should in this case do
  `scrollToEntry` to refocus that one?

  [ ] The proper handling of this case is actually more subtle because once we
  have scrolled off the single entry we ought to change the route.  But in a
  three column layout, we have no way of knowing what entry is being looked at.
  In a sense maybe we should lose the query parameter and return to '#blog'
  because although there is an expanded card, its no being looked at any more.


- [ ] Now we appear to have a bug where you can scroll quick down past the last
  `card-height` pixels and arrive at the bottom without being spotted by an
  `onScroll` event, and then it doesn't scroll. Not sure how to approach that
  as I need the target of the `onScroll` event to get the scroll top from. So
  its not so easy to get it with, say, a timer.

- [ ] Here's another interesting looking bug: if you click an entry (like
  'tools' on April 9th) and then reload the resulting url, there are 2 copies
  of the tools entry shown (both expanded). So it looks like the date parsing
  still isn't working properly for some set of dates.


  [ ] Interestingly the variable column version of this is going to create some
  interesting maths for this because sometimes the number of cards arriving
  will not be equivalent to a whole number of additional rows. 

- [ ] Don't show the 'more' (and don't handle scroll up events) when we are at
  the genuine top.

  So, how do you find out if you're on the first one?

  I think it's in the headings returned from the API:

    X-WP-Total: 4
    X-WP-TotalPages: 1

  If `TotalPages` is 1, there's nothing more to get.

  Getting at those is going to entail using [elm-http-extra](http://package.elm-lang.org/packages/lukewestby/elm-http-extra/5.2.0/Http-Extra#Response)

  Alternatively, you try and get the next page, and it it returns an empty
  list, we have reached the end.

- Now I can't add an `onScroll` handler to the element that is scrolling in
  the page because that is the `<main>` element which is created behind the
  scenes by `elm-mdl` and it adds its own event handlers to it, but doesn't
  give me a chance. 

  [x] Thinking of switching over to [Elm
  Bootstrap](http://elm-bootstrap.info/getting-started) especially as there is
  talk on the `elm-mdl` issues of Google switching to polymer like components
  for the future of Material Design for the web.

  - [x] That didn't actually work yet because now the `<body>` element is
    scrolling not the div. It doesn't have an id. I could give it one in the
    html I guess but I need the scrolling element to be one I'm generating so I
    can add an `onScroll` event handler to it. So I want to look at the css for
    the top level of MDL and see how come the body wasn't the scrolling element
    there.

    Here's an outline of how to fix it.
    http://dabblet.com/gist/3a79af10b5e4588ec48f468cdf177e72

- [ ] Fix the layout so #main is only as big as what remains after the header
  is drawn so that the scroll bars are the right size.

- [ ] looks like the timezone bug is back. When you go directly to the
  [Steps](http://localhost:8000/#blog/steps) entry, you get two copies of the
  entry. Similarly for [fallout](http://localhost:8000/#blog/fallout): The date
  displayed on the card says 22:08, but the date in the model says 23:08.
  The `date_gmt` returned from the API is: 
  
    "date_gmt": "2012-10-13T22:08:28",

- [ ] Tidy up all the update logic using
  [Return](http://package.elm-lang.org/packages/Fresheyeball/elm-return/6.0.3/Return)

- [ ] Clicking on an open card should maybe close it -- return to the list view?

- [ ] Should scrolling off an open entry also close it?

- [ ] Going straight to the url of a single page view needs to scroll us to the
relevant entry otherwise we cant see it.

- [ ] use continuous scroll

- [ ] We need a way to trigger fetching more entries when navigating the list
  view. Ideally that would be triggered by scrolling. 
  
  - [x] Have to look into infinite scroll.

  In fact the whole thing could work like this and we can:

- [x] get rid of those pesky prev and next arrows. Which means we don't need to
  always be showing the header bar!

- [ ] Do we need a way to know if we've reached the actual beginning or end of the 
  list of entries so as to avoid repeatedly requesting the next page at the end?

  The response headers give us that information, or maybe just getting back
  fewer than the expected page number.

- [x] Add classes or ids on summary cards in list view to help testing

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


- [ ] Adding buttons to cards is going to entail giving each one an unique button id number

