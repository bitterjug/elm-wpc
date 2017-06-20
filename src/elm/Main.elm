module Main exposing (..)

import Array
import ArrayExtra exposing (locate)
import Bootstrap.Navbar as Navbar
import Bootstrap.Grid as Grid
import Date exposing (Date)
import DOM
    exposing
        ( target
        , offsetTop
        )
import Dom.Scroll as Scroll
import Entry
    exposing
        ( Entry(..)
        , Entries
        , padCols
        , fromPosts
        )
import Post
    exposing
        ( Slug
        )
import Html exposing (..)
import Html.Attributes
    exposing
        ( src
        , href
        , classList
        , class
        , style
        , id
        )
import Html.Events exposing (onClick)
import Http
import Maybe.Extra exposing (filter)
import Navigation exposing (Location)
import RouteUrl exposing (UrlChange)
import Scrolling
import Task
import UrlParser as Url exposing ((</>))
import Window
import WordpressRestApi as WP


main =
    RouteUrl.program
        { delta2url = delta2hash
        , location2messages = location2messages
        , init = init
        , update = update
        , view = view
        , subscriptions = subs
        }


location2messages : Location -> List Msg
location2messages location =
    location
        |> Url.parseHash routeParser
        >> Maybe.withDefault BadUrl
        >> Show
        >> List.singleton


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash prevous current =
    current
        |> currentRoute
        |> toUrl
        |> RouteUrl.UrlChange RouteUrl.NewEntry
        |> Just


unknown =
    -1


type alias Model =
    { entries : Entries
    , earlierRequested : Bool
    , earlierRemaining : Int
    , laterRequested : Bool
    , laterRemaining : Int
    , page : Page
    , navbar : Navbar.State
    , cols : Int
    , scrollInfo : Scrolling.Info
    }


type Route
    = BlogList
    | Blog Slug
    | BadUrl


type Page
    = EntryList
    | SingleEntry Int
    | NotFound
    | Loading Route


type Role
    = List
    | Earlier
    | Later
    | Current


type Msg
    = Noop
    | PostList Role (Result Http.Error WP.Payload)
    | Show Route
    | NavbarMsg Navbar.State
    | Resize Window.Size
    | Scroll Scrolling.Info
    | Fetch Role


model : Navbar.State -> Model
model navbarState =
    { entries = Entry.none
    , earlierRequested = False
    , earlierRemaining = unknown
    , laterRequested = False
    , laterRemaining = unknown
    , page = Loading BlogList
    , navbar = navbarState
    , cols = 1
    , scrollInfo = Scrolling.noInfo
    }


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarMsg ) =
            Navbar.initialState NavbarMsg

        getWindowSize =
            Task.perform Resize Window.size
    in
        model navbarState ! [ getWindowSize, navbarMsg ]


currentRoute : Model -> Route
currentRoute model =
    case model.page of
        Loading route ->
            route

        NotFound ->
            BadUrl

        EntryList ->
            BlogList

        SingleEntry index ->
            model.entries
                |> Entry.getPost index
                |> Maybe.map (Blog << .slug)
                |> Maybe.withDefault BadUrl


routeParser : Url.Parser (Route -> Route) Route
routeParser =
    Url.oneOf
        [ Url.map BlogList Url.top
        , Url.map BlogList (Url.s "blog")
        , Url.map Blog (Url.s "blog" </> Url.string)
        ]


toUrl : Route -> String
toUrl route =
    "#"
        ++ case route of
            BlogList ->
                "blog"

            Blog slug ->
                "blog/" ++ slug

            BadUrl ->
                "404"



-- TODO:Can we do away with fetchList an use earlier instead with the current date?
-- TODO: make this return a payload


fetchList : Model -> Cmd Msg
fetchList model =
    case model.page of
        EntryList ->
            if Array.length model.entries < 10 then
                -- WIP: what was the logic of this?
                -- why less than 10? Wy not = 0?
                WP.getPostList (PostList List)
            else
                Cmd.none

        _ ->
            Cmd.none


fetchForSingleEntry : Model -> Cmd Msg
fetchForSingleEntry model =
    case model.page of
        Loading (Blog slug) ->
            -- If we're awaiting the single page, fetch it
            WP.getPost (PostList Current) slug

        SingleEntry index ->
            -- If we've got the current post but any of the neighbours are missing, fetch those
            let
                post =
                    Entry.getPost index model.entries
            in
                Cmd.batch
                    [ Entry.getPost (index + 1) model.entries
                        |> fetchNeighbour post (WP.getEarlierPosts (PostList Earlier))
                    , Entry.getPost (index - 1) model.entries
                        |> fetchNeighbour post (WP.getLaterPosts (PostList Later))
                    ]

        _ ->
            Cmd.none


fetchNeighbour : Maybe Post.Post -> (Date -> Cmd Msg) -> Maybe Post.Post -> Cmd Msg
fetchNeighbour post fetcher neighbourPost =
    if neighbourPost == Nothing then
        Maybe.map (fetcher << .date) post
            |> Maybe.withDefault Cmd.none
    else
        Cmd.none


fetchEarlier : Entries -> Cmd Msg
fetchEarlier entries =
    -- returns a comand to fetch a page that preceed the entries in the model in date order
    Entry.lastPost entries
        |> Maybe.map (WP.getEarlierPosts (PostList Earlier) << .date)
        |> Maybe.withDefault Cmd.none


fetchLater : Entries -> Cmd Msg
fetchLater entries =
    -- returns a comand to fetch a page that follow the entries in the model in date order
    Entry.firstPost entries
        |> Maybe.map (WP.getLaterPosts (PostList Later) << .date)
        |> Maybe.withDefault Cmd.none


scrollToOffset : Int -> Cmd Msg
scrollToOffset pixelOffset =
    Task.attempt (always Noop) <|
        Scroll.toY "main" <|
            toFloat pixelOffset


contentHeight : Int -> Entries -> Int
contentHeight cols entries =
    ((Array.length entries) // cols * card.height)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            model ! []

        PostList Current (Ok { remaining, posts }) ->
            let
                newPage =
                    case model.page of
                        Loading (Blog slug) ->
                            if Array.length posts == 1 then
                                posts
                                    |> Array.get 0
                                    |> filter (.slug >> (==) slug)
                                    |> Maybe.map (always <| SingleEntry 0)
                                    |> Maybe.withDefault model.page
                            else
                                NotFound

                        _ ->
                            let
                                _ =
                                    Debug.log "Current post payload received but not expected: " posts
                            in
                                model.page

                newModel =
                    { model
                        | entries = fromPosts posts
                        , page = newPage
                    }
            in
                newModel
                    ! [ fetchForSingleEntry newModel ]

        PostList Later (Ok { remaining, posts }) ->
            let
                newEntries =
                    padCols model.cols <| fromPosts posts

                ( newPage, cmd ) =
                    case model.page of
                        SingleEntry index ->
                            SingleEntry (index + Array.length newEntries)
                                ! [ scrollToOffset <|
                                        (contentHeight model.cols newEntries)
                                            + model.scrollInfo.scrollTop
                                  ]

                        _ ->
                            model.page ! []

                newModel =
                    { model
                        | entries = Array.append newEntries model.entries
                        , laterRequested = False
                        , laterRemaining = remaining
                        , page = newPage
                    }
            in
                newModel ! [ cmd ]

        PostList Earlier (Ok payload) ->
            { model
                | entries =
                    fromPosts payload.posts
                        |> padCols model.cols
                        |> Array.append model.entries
                , earlierRequested = False
                , earlierRemaining = payload.remaining
            }
                ! []

        -- This should only be used for the initial page load, so it loads the first page
        -- Thus we can safely replace the existing entries with these (there might be timing
        -- cases to worry about here but I don't think so) and there are no later entries
        -- but as many later ones as the total minus the payload count
        PostList List (Ok payload) ->
            let
                newPage =
                    if model.page == Loading BlogList then
                        EntryList
                    else
                        -- actualy, if we werent awaiting the bloglist, what are we doing here?
                        model.page

                newModel =
                    { model
                        | entries = padCols model.cols <| fromPosts payload.posts
                        , earlierRemaining = payload.remaining
                        , laterRemaining = 0
                        , page = newPage
                    }
            in
                newModel ! []

        -- I'm not currently handling errors
        PostList _ (Err _) ->
            model ! []

        Show route ->
            let
                ( page, index ) =
                    case route of
                        BlogList ->
                            ( EntryList, 0 )

                        Blog slug ->
                            let
                                maybeIndex =
                                    locate (Entry.hasSlug slug) model.entries

                                entryIndex =
                                    Maybe.withDefault 0 maybeIndex

                                blog =
                                    maybeIndex
                                        |> Maybe.map SingleEntry
                                        |> Maybe.withDefault (Loading route)
                            in
                                ( blog, entryIndex )

                        BadUrl ->
                            ( NotFound, 0 )

                newModel =
                    { model | page = page }

                newScrollTop =
                    (card.height * index // newModel.cols)
            in
                newModel
                    ! [ fetchForSingleEntry newModel
                      , fetchList newModel
                      , scrollToOffset newScrollTop
                        --  TODO: Do this only if ther is a single entry view??
                      ]

        Resize size ->
            let
                _ =
                    Debug.log "size:" size
            in
                { model | cols = cardColumns size } ! []

        Scroll ({ scrollHeight, scrollTop, offsetHeight } as info) ->
            let
                newModel =
                    { model | scrollInfo = info }

                earlierNeeded =
                    (scrollHeight - scrollTop - card.height <= offsetHeight)
                        && not model.earlierRequested
                        && (model.earlierRemaining > 0)

                laterNeeded =
                    (scrollTop == 0)
                        && not model.laterRequested
                        && (model.laterRemaining > 0)
            in
                if earlierNeeded then
                    { newModel | earlierRequested = True } ! [ fetchEarlier model.entries ]
                else if laterNeeded then
                    { newModel | laterRequested = True } ! [ fetchLater model.entries ]
                else
                    newModel ! []

        NavbarMsg state ->
            { model | navbar = state } ! []

        Fetch Earlier ->
            if model.earlierRequested then
                model ! []
            else
                { model | earlierRequested = True } ! [ fetchEarlier model.entries ]

        Fetch Later ->
            if model.laterRequested then
                model ! []
            else
                { model | laterRequested = True } ! [ fetchLater model.entries ]

        Fetch _ ->
            model ! []


card =
    { height = 420
    , width = 552
    }


{-| 1, 2 or 3 columns of cards for the current window size
-}
cardColumns : Window.Size -> Int
cardColumns size =
    min 3 <| size.width // card.width


{-| fixed width of the card column for current # columns
-}
cardColWidth : Int -> String
cardColWidth cols =
    cols
        |> (*) card.width
        |> toString
        |> flip (++) "px"


view : Model -> Html Msg
view model =
    let
        content =
            case model.page of
                EntryList ->
                    Nothing
                        |> Entry.viewList (Show << Blog) model.entries

                SingleEntry index ->
                    model.entries
                        |> Entry.getPost index
                        |> Maybe.map .slug
                        |> Entry.viewList (Show << Blog) model.entries

                Loading route ->
                    div [] [ text "Loading..." ]

                NotFound ->
                    div [] [ text "404 not found" ]

        earlierButton =
            if model.earlierRemaining == 0 then
                []
            else
                [ moreButton Earlier "Earlier" model.earlierRequested ]

        laterButton =
            if model.laterRemaining == 0 then
                []
            else
                [ moreButton Later "Later" model.laterRequested ]
    in
        div
            [ id "main"
            , Scrolling.onScroll Scroll
            ]
            [ header model.navbar
            , div
                [ class "main-column"
                , style [ ( "width", cardColWidth model.cols ) ]
                ]
              <|
                laterButton
                    ++ [ content ]
                    ++ earlierButton
              {- [ content ] -}
            ]


moreButton : Role -> String -> Bool -> Html Msg
moreButton role label loading =
    a
        [ classList
            [ ( "more-button", True )
            , ( "loading", loading )
            ]
        , onClick <| Fetch role
        ]
        [ text label ]


header : Navbar.State -> Html Msg
header navbar =
    Navbar.config NavbarMsg
        |> Navbar.fixTop
        |> Navbar.attrs [ class "header-row" ]
        |> Navbar.brand
            [ href <| toUrl BlogList ]
            [ img [ src "images/bjlogo.png" ] [ text "Bitterjug.com" ] ]
        |> Navbar.view navbar


subs : Model -> Sub Msg
subs model =
    Sub.batch
        [ Window.resizes Resize ]
