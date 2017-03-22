module Main exposing (..)

import Array
import ArrayExtra exposing (locate)
import Date exposing (Date)
import DOM exposing (target, offsetTop)
import Dom.Scroll as Scroll
import Entry
    exposing
        ( Entry
        , Entries
        , Slug
        )
import Html exposing (..)
import Html.Attributes exposing (src)
import Http
import Json.Decode as Decode
import Material
import Material.Icon as Icon
import Material.Options as Options
import Material.Color as Color
import Material.Grid as Grid
import Material.Elevation as Elevation
import Material.Layout as Layout
import Material.Button as Button
import Maybe.Extra exposing (filter)
import Navigation exposing (Location)
import RouteUrl exposing (UrlChange)
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
        >> Show 0
        >> List.singleton


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash prevous current =
    current
        |> currentRoute
        |> toUrl
        |> RouteUrl.UrlChange RouteUrl.NewEntry
        |> Just


type alias Model =
    { entries : Entries
    , page : Page
    , mdl : Material.Model
    , raised : Int
    , cols : Int
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
    | PostList Role (Result Http.Error Entries)
    | Show Float Route
    | Mdl (Material.Msg Msg)
    | Raise Int
    | Resize Window.Size


model : Model
model =
    { entries = Entry.none
    , page = Loading BlogList
    , mdl = Material.model
    , raised = -1
    , cols = 1
    }


init : ( Model, Cmd Msg )
init =
    model ! [ Task.perform Resize Window.size ]


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
                |> Array.get index
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


fetchList : Model -> Cmd Msg
fetchList model =
    case model.page of
        EntryList ->
            if Array.length model.entries < 10 then
                WP.getPostList (PostList List) 1
            else
                Cmd.none

        _ ->
            Cmd.none


fetchForSingleEntry : Model -> Cmd Msg
fetchForSingleEntry model =
    case model.page of
        Loading (Blog slug) ->
            -- If we're awaiting the single page, fetch it
            WP.getEntry (PostList Current) slug

        SingleEntry index ->
            -- If we've got the current entry but any of the neighbours are missing, fetch those
            let
                entry =
                    Array.get index model.entries
            in
                Cmd.batch
                    [ Array.get (index + 1) model.entries
                        |> fetchNeighbour entry (WP.getEarlierEntries (PostList Earlier))
                    , Array.get (index - 1) model.entries
                        |> fetchNeighbour entry (WP.getLaterEntries (PostList Later))
                    ]

        _ ->
            Cmd.none


fetchNeighbour : Maybe Entry -> (Date -> Cmd Msg) -> Maybe Entry -> Cmd Msg
fetchNeighbour entry fetcher neighbour =
    if neighbour == Nothing then
        Maybe.map (fetcher << .date) entry
            |> Maybe.withDefault Cmd.none
    else
        Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            model ! []

        PostList Current (Ok entries) ->
            let
                newPage =
                    case model.page of
                        Loading (Blog slug) ->
                            entries
                                |> Array.get 0
                                |> filter (.slug >> (==) slug)
                                |> Maybe.map (always <| SingleEntry 0)
                                |> Maybe.withDefault model.page

                        _ ->
                            model.page

                newModel =
                    { model
                        | entries = entries
                        , page = newPage
                    }
            in
                newModel
                    ! [ fetchForSingleEntry newModel ]

        PostList Later (Ok entries) ->
            let
                ( newPage, cmd ) =
                    case model.page of
                        SingleEntry index ->
                            SingleEntry (index + Array.length entries)
                                ! [ Task.attempt
                                        (always Noop)
                                        (Scroll.toY "elm-mdl-layout-main" (cardTopY model.cols <| index + Array.length entries))
                                  ]

                        _ ->
                            model.page ! []

                newModel =
                    { model
                        | entries = Array.append entries model.entries
                        , page = newPage
                    }
            in
                newModel ! [ cmd ]

        PostList Earlier (Ok entries) ->
            let
                newModel =
                    { model | entries = Array.append model.entries entries }
            in
                newModel ! []

        PostList List (Ok entries) ->
            let
                newModel =
                    { model
                      -- always replace the current batch with this group
                      -- is that the best thing to do ?
                        | entries = entries
                        , page =
                            if model.page == Loading BlogList then
                                EntryList
                            else
                                model.page
                    }
            in
                newModel ! []

        PostList _ (Err _) ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        Show _ route ->
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
            in
                newModel
                    ! [ fetchForSingleEntry newModel
                      , fetchList newModel
                      , Task.attempt
                            (always Noop)
                            (Scroll.toY "elm-mdl-layout-main" (cardTopY model.cols index))
                        -- This has no value for a list?
                      ]

        Raise id ->
            { model | raised = id } ! []

        Resize size ->
            let
                _ =
                    Debug.log "size:" size
            in
                { model | cols = cardColumns size } ! []


card =
    { height = 340
    , width = 552
    }


{-| 1, 2 or 3 columns of cards for the current window size
-}
cardColumns : Window.Size -> Int
cardColumns size =
    min 3 <| size.width // card.width


{-| pixed width of the card column for current # columns
-}
cardColWidth : Int -> String
cardColWidth cols =
    cols
        |> (*) card.width
        |> toString
        |> flip (++) "px"


{-| scrollY of the top of the given card in the column
-}
cardTopY : Int -> Int -> Float
cardTopY cols index =
    (card.height * (index // cols))
        |> toFloat
        |> Debug.log "scroll-y:"


view : Model -> Html Msg
view model =
    let
        cardStyle : Int -> Entry -> Options.Style Msg
        cardStyle cardId entry =
            Options.many
                [ if model.raised == cardId then
                    Elevation.e8
                  else
                    Elevation.e2
                , Elevation.transition 250
                , Options.onMouseEnter (Raise cardId)
                , Options.onMouseLeave (Raise -1)
                , Options.on "click" <|
                    Decode.map (\scrollY -> Show scrollY <| Blog entry.slug) ((Decode.field "currentTarget") offsetTop)
                ]

        entryList slugM =
            model.entries
                |> Array.indexedMap
                    (\id entry -> Entry.viewEntry slugM (cardStyle id entry) entry)
                |> Array.toList
                |> Options.div [ Options.cs "entry-list-container" ]

        content =
            case model.page of
                EntryList ->
                    entryList Nothing

                SingleEntry index ->
                    -- TODO if slugM is Nothing, we should be saying something different here?
                    -- should we have fetched the right entry by slug? At what point
                    -- do we decide that the slug is invalid?
                    let
                        content =
                            model.entries
                                |> Array.get index
                                |> Maybe.map .slug
                                |> entryList
                    in
                        content

                Loading route ->
                    let
                        content =
                            Options.div [] [ text "Loading..." ]
                    in
                        content

                NotFound ->
                    let
                        content =
                            Options.div [] [ text "404 not found" ]
                    in
                        content

        header =
            [ Layout.row [ Options.cs "header-row" ]
                [ Layout.spacer
                , Layout.title []
                    [ Html.a [ Html.Attributes.href <| toUrl BlogList ] [ img [ src "images/bjlogo.png" ] [] ]
                    ]
                , Layout.spacer
                ]
            ]
    in
        Layout.render Mdl
            model.mdl
            [ Layout.fixedHeader ]
            { header = header
            , drawer = []
            , tabs = ( [], [] )
            , main =
                [ Options.div
                    [ Options.cs "main-column", Options.css "width" <| cardColWidth model.cols ]
                    [ content ]
                ]
            }


subs : Model -> Sub Msg
subs model =
    Sub.batch
        [ Layout.subs Mdl model.mdl
        , Window.resizes Resize
        ]
