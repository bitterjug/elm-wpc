Wordpress REST Api client in Elm
=================================

Currently I'm building and running with this:

```
elm-live --open --pushstate --dir=src/static src/elm/Main.elm --output src/static/Main.js
```
To Do
=====

- [ ] Should we show the Not Found under the bad url route or under the
  original bad route so there is a chance to modify it?  We would need a
  parameter to the NotFound constructor to store the route object.
  

- [ ] Make larger version of the logo man artwork, with neutral background.


- [ ] Fix the layout so #main is only as big as what remains after the header
  is drawn so that the scroll bars are the right size. ???


### Bugs

- [ ] We appear to have a bug where you can scroll quick down past the last
  `card-height` pixels and arrive at the bottom without being spotted by an
  `onScroll` event, and then it doesn't scroll. Not sure how to approach that
  aps I need the target of the `onScroll` event to get the scroll top from.  So
  its not so easy to get it with, say, a timer.


- [x] Here's another interesting looking bug: if you click an entry (like
  'tools' on April 9th) and then reload the resulting url, there are 2 copies
  of the tools entry shown (both expanded). So it looks like the date parsing
  still isn't working properly for some set of dates.

  It looked like this was because Wordpress was using the `date` field, not the
  `date_gmt` field for internal comparisons.  Which means I have to send it
  that one. Now I still have questions about how best to decode it, so Im
  appending Z and decoding as UTC, which is probably wrong. This bug might come
  back if I look for it but testing today on the train I couldn't get
  duplicates in summer or winter.


- [ ] There's probably an error case arising from the fact that when we decide
  whether to fetch earlier (or later) we only check whether **some** later
  batch is currently being fetched. But instead we need to check if the batch
  we're about to fetch is being fetched. I think it's the reason for the bug
  below. 

  It is here to sort of de-bounce the requests. Since when scrolling down
  (earlier) we might have several scroll positions where the condition to fetch
  more is satisfied so if we did a very small scroll within that region we
  would try and 

### Features and enhancements

- [ ] Show feedback on how many entries are remaining when scrolling?

- [ ] Clicking on an open card should maybe close it -- return to the list
    view?

  - [ ] Adding buttons to cards is going to entail giving each one an unique
    button id number

  [ ] Once we have scrolled off the single entry we ought to change the route.
  Maybe we should lose the query parameter and return to '#blog' because
  although there is an expanded card, its no being looked at any more.

- [ ] What happens when we introduce the means to navigate from viewing a
  single expanded entry back to  viewing the list, in the vicinity of that
  entry. Now we can be viewing the list but from the middle. Scrolling to the
  selected item won't work because there won't be one, so we'll have to try and
  preserve the effective offset by adding the height of the newly prepended
  entries.  

- [ ] If there are more to get, could we do a "content first" trick and fill in
  some empty content to allow scrolling to continue, and issue the GET request
  to fetch them, and replace them with real content when the content arrives?
  Problem is we don't know how many columns are incoming

- [ ] Set the default page size to 12 instead of 10 so divisible by 3

  - [ ] Possible fetch 11 or 10 on the first load of the main list so we have
    space for the spacers -- if they're cool

### Code Tweaks

- [ ] We should probably be caching the rendered html in the model because its
  no efficient. We could render it when we receive the data instead of on every
  view.

- [ ] Tidy up all the update logic using
  [Return](http://package.elm-lang.org/packages/Fresheyeball/elm-return/6.0.3/Return)

- [ ]  We're not using the WP API native paging, so we don't actually care how
  many pages there are.  Instead we're taking page-sized chunks earlier than a
  given date.  What would it mean to switch to using internal paging? Would
  that help at all?

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

Done
====

- [ ] looks like the timezone bug is back. When you go directly to the
  [Steps](http://localhost:8000/#blog/steps) entry, you get two copies of the
  entry. Similarly for [fallout](http://localhost:8000/#blog/fallout): The date
  displayed on the card says 22:08, but the date in the model says 23:08.
  The `date_gmt` returned from the API is: 
  
    "date_gmt": "2012-10-13T22:08:28",

  Mayb solved by using the date not date_gmt. If Wordpress is using
  the normal date, not the  GMT date to do the comparisons in the API
