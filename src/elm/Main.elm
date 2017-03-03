module Main exposing (..)

import Array
import ArrayExtra exposing (locate)
import Date exposing (Date)
import Entry
    exposing
        ( Entry
        , Entries
        , Slug
        )
import Html exposing (..)
import Html.Attributes exposing (src)
import Http
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
import UrlParser as Url exposing ((</>))
import WordpressRestApi as WP


main =
    RouteUrl.program
        { delta2url = delta2hash
        , location2messages = location2messages
        , init = init
        , update = update
        , view = view
        , subscriptions = \model -> Layout.subs Mdl model.mdl
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


type alias Model =
    { entries : Entries
    , page : Page
    , mdl : Material.Model
    , raised : Int
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
    = PostList Role (Result Http.Error Entries)
    | Show Route
    | Mdl (Material.Msg Msg)
    | Raise Int


model : Model
model =
    { entries = Entry.none
    , page = Loading BlogList
    , mdl = Material.model
    , raised = -1
    }


init : ( Model, Cmd Msg )
init =
    -- ( model, WP.getPostList (PostList List) 1 )
    model ! []


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
                -- until such time as we have routes that include details of
                -- the list always fetch the first page, later we can maybe
                -- have a list starting from zero or even a partial list with a
                -- start and end.  theres space for some sort of combined
                -- detail and summary view that shows the current entry in
                -- context of its list but I haven't invented that yet.
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
                newPage =
                    case model.page of
                        SingleEntry index ->
                            SingleEntry (index + Array.length entries)

                        _ ->
                            model.page

                newModel =
                    { model
                        | entries = Array.append entries model.entries
                        , page = newPage
                    }
            in
                newModel ! []

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

        Show route ->
            let
                page =
                    case route of
                        BlogList ->
                            EntryList

                        Blog slug ->
                            locate (Entry.hasSlug slug) model.entries
                                |> Maybe.map SingleEntry
                                -- in the default case we also want to return commands to do the loading
                                |>
                                    Maybe.withDefault (Loading route)

                        BadUrl ->
                            NotFound

                newModel =
                    { model | page = page }
            in
                newModel
                    ! [ fetchForSingleEntry newModel
                      , fetchList newModel
                      ]

        Raise id ->
            { model | raised = id } ! []


prevNextButton : Model -> Int -> String -> Maybe Slug -> Html Msg
prevNextButton model buttonId iconName neighbour =
    Button.render Mdl
        [ buttonId ]
        model.mdl
        [ Button.icon
        , Button.ripple
        , neighbour
            |> Maybe.map (Button.link << toUrl << Blog)
            |> Maybe.withDefault Button.disabled
        ]
        [ Icon.i iconName ]


view : Model -> Html Msg
view model =
    let
        viewEntry : (Options.Style Msg -> Entry -> Html Msg) -> Int -> Entry -> Html Msg
        viewEntry cardView cardId entry =
            let
                style =
                    Options.many
                        [ if model.raised == cardId then
                            Elevation.e8
                          else
                            Elevation.e2
                        , Elevation.transition 250
                        , Options.onMouseEnter (Raise cardId)
                        , Options.onMouseLeave (Raise -1)
                        , Options.onClick (Show <| Blog entry.slug)
                        ]
            in
                cardView style entry

        notFound =
            div [] [ text "404 not found" ]

        loading =
            div [] [ text "Loading..." ]

        ( prevSlug, nextSlug, content ) =
            case model.page of
                EntryList ->
                    let
                        entries =
                            model.entries
                                |> Array.indexedMap (viewEntry Entry.viewSummary)
                                |> Array.toList
                                |> Options.div [ Options.cs "entry-list-container" ]
                    in
                        ( Nothing, Nothing, entries )

                SingleEntry index ->
                    let
                        entries =
                            model.entries
                                |> Array.get index
                                |> Maybe.map
                                    (List.singleton
                                        >> List.indexedMap (viewEntry Entry.viewDetail)
                                        >> Options.div []
                                    )
                                |> Maybe.withDefault notFound

                        previous =
                            Array.get (index + 1) model.entries
                                |> Maybe.map .slug

                        next =
                            Array.get (index - 1) model.entries
                                |> Maybe.map .slug
                    in
                        ( previous, next, entries )

                Loading route ->
                    ( Nothing, Nothing, loading )

                NotFound ->
                    ( Nothing, Nothing, notFound )

        header =
            [ Layout.row [ Options.cs "header-row" ]
                [ Layout.navigation [] [ prevNextButton model 0 "arrow_back" prevSlug ]
                , Layout.spacer
                , Layout.title []
                    [ Html.a [ Html.Attributes.href <| (toUrl BlogList) ] [ img [ src "images/bjlogo.png" ] [] ]
                    ]
                , Layout.spacer
                , Layout.navigation [] [ prevNextButton model 1 "arrow_forward" nextSlug ]
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
                [ Grid.grid []
                    [ Grid.cell [ Grid.offset Grid.Desktop 1, Grid.size Grid.Desktop 10 ] [ content ] ]
                ]
            }
