Wordpress REST Api client in Elm
=================================

Currently I'm building and running with this:

```
elm-live --open --pushstate --dir=src/static src/elm/Main.elm --output src/static/Main.js
```
To Do
=====

- [x]  In case the contents aren't a multiple of the column number we need a
  way to make it up to a multiple of column count to keep the layout looking
  okay. Since the padding items will be be rendered differently from post
  entries, they should be of another type. So we will probably need a new type
  for the elements of this array: a union type with branches for entries and
  padding items. Initially something like:

      type DisplayEntry 
        = AnEntry Entry
        | Padding


      paddToColumnWidth : List Entry -> List DisplayEntry
      paddToColumnWidth : List Entry -> List DisplayEntry

  Put these in another module. Maybe called posts as that's what wordpress has.

  Change the main model to refer to an array of these.  Major refactor to separate
  server-side posts and client side entries.??

- [ ] Add the actual padding. Currently `Entry.padCols` is the identify function.
Make it insert padding up to mod cols 

- [ ] Set the default page size to 12 instead of 10 so divisible by 3


- [ ] If there are more to get, could we do a "content first" trick and fill in
  some empty content to allow scrolling to continue, and issue the GET request
  to fetch them, and replace them with real content when the content arrives?
  Problem is we don't know how many columns are incoming

- [ ] Do we even need `getPostList`? Isn't it the same as 

    `getEarlier <curent date>`?

  Uh! But to get the current date we need to run a task.

  We do this when we start the app or when we visit the top level url.  If this
  is at start up we could request the current time as one of the commands
  sent by `init`.

  Technically, if I published a blog while I was in a session with this client, 
  Id want the now date updated in order to include it in the main list. 
  So when do we update the now date? On app start would miss this case.
  Unless we had to hit reload to refresh... is that acceptable? 

  If not we have to refresh it each time he main list is requested which means
  we would want to defer the load for the content until after receiving the 
  new current time. It's quick, sure, but there would need to be another
  internal state where the now date was "unknown" until it arrived. 
  Maybe we need a `Maybe Date` for `Model.now`?

- [ ] What happens when we introduce the means to navigate from viewing a
  single expanded entry back to  viewing the list, in the vicinity of that
  entry. Now we can be viewing the list but from the middle. Scrolling to the
  selected item won't work because there won't be one, so we'll have to try and
  preserve the effective offset by adding the height of the newly prepended
  entries.  

  - [ ] Clicking on an open card should maybe close it -- return to the list
    view?

- [ ] Once we have scrolled off the single entry we ought to change the route.
  Maybe we should lose the query parameter and return to '#blog' because
  although there is an expanded card, its no being looked at any more.


 -[ ] There's probably an error case arising from the fact that when we decide
 whether to fetch earlier (or later) we only check whether **some** later batch
 is currently being fetched. But instead we need to check if the batch we're
 about to fetch is being fetched. I think it's the reason for the bug below. 

  It is here to sort of de-bounce the requests. Since when scrolling down
  (earlier) we might have several scroll positions where the condition to fetch
  more is satisfied so if we did a very small scroll within that region we
  would try and 



- [ ] Check how we handle an invalid slug in url

- [x] The variable column version of this is going to create some
  interesting maths for this because sometimes the number of cards arriving
  will not be equivalent to a whole number of additional rows. 

  This should be handled by 

- [ ] Fix the layout so #main is only as big as what remains after the header
  is drawn so that the scroll bars are the right size.

- [ ] Here's another interesting looking bug: if you click an entry (like
  'tools' on April 9th) and then reload the resulting url, there are 2 copies
  of the tools entry shown (both expanded). So it looks like the date parsing
  still isn't working properly for some set of dates.

- [ ] looks like the timezone bug is back. When you go directly to the
  [Steps](http://localhost:8000/#blog/steps) entry, you get two copies of the
  entry. Similarly for [fallout](http://localhost:8000/#blog/fallout): The date
  displayed on the card says 22:08, but the date in the model says 23:08.
  The `date_gmt` returned from the API is: 
  
    "date_gmt": "2012-10-13T22:08:28",

- [ ] We appear to have a bug where you can scroll quick down past the last
    `card-height` pixels and arrive at the bottom without being spotted by an
    `onScroll` event, and then it doesn't scroll. Not sure how to approach that
    aps I need the target of the `onScroll` event to get the scroll top from.
    So its not so easy to get it with, say, a timer.

- [ ] Tidy up all the update logic using
  [Return](http://package.elm-lang.org/packages/Fresheyeball/elm-return/6.0.3/Return)


- [ ]  We're not using the WP API native paging, so we don't actually care how
  many pages there are.  Instead we're taking page-sized chunks earlier than a
  given date.  What would it mean to switch to using internal paging? Would
  that help at all?

- [ ] Show feedback on how many entries are remaining when scrolling?

- [ ] We need a way to trigger fetching more entries when navigating the list
  view. Ideally that would be triggered by scrolling. 
  
 - [ ] We might get a response that says the slug can't be found in which case
   were going to transition to a proper 404 page.

- [ ] Adding buttons to cards is going to entail giving each one an unique button id number


Done
====
- [x] Add classes or ids on summary cards in list view to help testing

- [x] Make list entries click through to their corresponding pages

- [x] Add a previous link to the previous blog's address
  So that I don't have to type in a full slug

- [x] At the moment we don't know until we try and render a post page -- and
  its neighbours -- if we need to fetch more data or not. Bu that's the wrong
  place. The right place is in update. So perhaps we should set the previous
  and next as part of the update. Either we set them there or we just check for
  them there. That seems wasteful to calculate the neighbours twice.

- [x] Now when rendering a blog, if the previous link isn't available, we should
  kick off a request for the next page of entries, and when those arrive we should
  redraw and recalculate whether the previous is available

  - [x] The problem here was that when we're rendering it, its too late, we
    need to do that during update. So first we have to refactor the code
    so that the neighbours get recalculated  when a) we visit a single entry
    page or, b) when we receive more data from the server which might provide
    neighbours for an antry we didnt previously have neighbours for.


- [x] Create separate module for Wordpress REST API


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

- [x]: Do the same for Fetch Later as we have done for Fetch Earlier and make
  upward scrolling work.

  This is kinda working: the more button gets displayed and you can click on it
  to trigger a fetch. But:

  - [x] The action isn't yet triggered by a scroll event

    On a scroll message, if the offset is zero (is it reduntant to say "and if
    we're scrolling upwarsd?) we trigger the command to fetch earlier.

- [x] Now I can't add an `onScroll` handler to the element that is scrolling in
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

- [x] We still fetch earlier or later when we scroll to the top or bottom
  whether or not the button is shown. Check the moreRemaining count before
  requesting on scroll

- [x] Refactor: move the remaining calculation into the Wp api module so it is
  not repeated in Main.

- [x] The more button, (and scroll activation) both happen whether or not we are
  at the start of the list. 

  To detect the start of the list we need to access Wordpress headers.
  Specifically:

    X-WP-Total: 528
    X-WP-TotalPages: 53

  - To access these the http request must have a custom expect built on top of
    `exopectStringResponse`:

       expectStringResponse
           :  (Response String -> Result String a)
               -> Expect a

    Then, when we have constructed a function: `Response String -> Result String a`
    we can use it to make an expect and add it to the reponse using `withExpect`
    in http-builder.

    For reference the response looks like this:

        type alias Response String = 
            { url : String
            , status : { code : Int, message : String }
            , headers : Dict String String
            , body : String
            }

    - body is JSON -- decode as before:


    - headers is a dict from strings to strings; get the total number out with
      dictionary lookup.  This gives `Maybe String`, for the `Nothing` case,
      either use a default (say zero, as we don't expect Wordpress to give us
      no header) or an error. Default is simplest:

        Dict.get "X-WP-Total" header |> Maybe.withDefault 0

      - [ ] Do proper error handling for this and return an error in the
        `Result`

    Say the function is

        type alias Payload = (Entries, Int)

        expectEntriesAndTotal : (Response String -> Result String Payload)
        expectEntriesAndTotal response = 
          let
            total = 
              Dict.get "X-WP-Total" response.header 
              |> Maybe.withDefault 0

            decodeEntries =
              Entry.decodeEntry
                  |> Decode.list
                  -- |> Decode.map (List.reverse >> Array.fromList)
                  |> Decode.map Array.fromList

            entryResult =
              Json.Decode.decodeString decodeEntries response.body
            
          in
            case entryResult of 
              Ok entires -> 
                Ok (entries, total)

              err -> 
                err

    Then we say something like:

        get postUrl
            |> withQueryParams [ ( "before", (toUtcIsoString date) ) ]
            |> withExpect (expectStringResponse expectEntriesAndTotal)
            |> send message

  But unlike just pulling out all the entries in the list, we want some
  additional information now: whether we are at the end or not. So the expected
  type parameter isn't `Expect Entries` (where `Entries` is an array of
  `Entry`) but something like `Expect (Entries, Bool)` or `(Entries, Int)`
  where the Int is total number of entries in the current query. I the total
  number of entries is equal to the size of the entry array, we're at the end.

  - [x] So the handler for the incoming data is going to have to change to
    handle the total entries count as well as the entries itself. For which
    there must be somewhere to store it. Do we want the total numner of entries
    or just inforation about whether there are any more before the earliest or
    after the latest in the current view?

    Perhaps we subtract the number in the array from the total number of
    entries, and store it along witht the direction (earlier or later) as the
    number remaining. Then we can show the more button only if that number
    is greater than zero. (and optionally show some feedback on how many 
    are remaining).
  
- [x] The `PostList Later` branch of `update` does a `scrollToEntry` to
  position the selected entry in the right place, which has the effect of
  zipping us back to the focussed item rather than letting us scroll up. 

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


  I wonder if there is a more general solution?

  - If we know what the current scroll offset is, and the size of content being
    added above. But we don't always know the current scroll top. We get it
    only when we receive the `scrollInfo` from a scroll event. But prior to any
    scroll event, the `scrolltop` is 0. And after we insert something at top
    it's the size of that.

  -  We have the current scroll info stored in the model.  If the load is
     triggered by a scroll-up event, we actually have the current scroll top.
     Except before any scroll event. But if there has not been a scroll event
     is it true that `scrollTop` is zero?

  -  When loading a new url, and backfilling earlier entries, we don't know
     what the scroll offset and height are. But since no scrolling has happened
     yet, `scrollTop` is 0.

  - So instead of `scrollToEntry` we need something like `scrollToOffset` which
    can take the pixel height of the new content just added as a parameter.

    - [x] As a first step: create `scrollToOffset` function and use it with the
      offset calculated from the index of the currently expanded item, if there
      is one.

  - And then, in `PostList Later` we will receive the payload containing the
    new entries, calculate he height of those entries, with another function,
    and pass that to the scroll to offset function.

  - [x] So We need a function that takes `Array Entry` and a number of columns,
    and can return an integer for the pixel height of displaying it in the
    those columns. 

      contentHeight : Int -> Array e -> Int
      contentHeight cols entries =
              ((Array.length entries) // cols * card.height ) + headerHeight
    
    And then we're going to scroll to:

      scrollToOffset 
        (contentHeight model.cols entries) 
          + model.scrollInfo.scrollTop

  - [x]  We need to make sure that when we prepend later items above an
    expanded item, and then scroll to the new scroll offset, that we update the
    `scrollTop` in scroll info in the model, in case the generated `scrollTo`
    command doesn't trigger a `Scroll` event. (But it appears to do it.)
