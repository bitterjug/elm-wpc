module Main exposing (..)

import Entry exposing (Entry, Slug, Neighbours)
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
import Navigation exposing (Location)
import RouteUrl exposing (UrlChange)
import UrlParser as Url exposing ((</>))
import WordpressRestApi as WP


main =
    RouteUrl.program
        { delta2url = delta2hash
        , location2messages = hash2message
        , init = init
        , update = update
        , view = view
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


hash2message : Location -> List Msg
hash2message =
    findPage >> Show >> List.singleton


delta2hash : Model -> Model -> Maybe UrlChange
delta2hash prevous current =
    if prevous.page == current.page then
        Nothing
    else
        current.page
            |> toUrl
            |> RouteUrl.UrlChange RouteUrl.NewEntry
            |> Just


type alias Model =
    { entries : List Entry
    , jsonPage : Int
    , page : Page
    , mdl : Material.Model
    , raised : Int
    }


unknownNeighbours =
    Neighbours Nothing Nothing


type Page
    = EntryList
    | SingleEntry Neighbours Slug
    | NotFound


type Msg
    = PostList Int (Result Http.Error (List Entry))
    | Show Page
    | Mdl (Material.Msg Msg)
    | Raise Int


init : ( Model, Cmd Msg )
init =
    ( { entries = [ Entry.loading ]
      , jsonPage = 0
      , page = EntryList
      , mdl = Material.model
      , raised = -1
      }
    , WP.getPostList (PostList 1) 1
    )


{-| Under what circumstances should this return NotFound?
  | - When the pattern doesn't match any of the routes,
  | - Wheh the pattern is #blog/slug but slug can't be found
  | Now when slug can't be found in the current cache we need to
  | search for it and receive a negative answer before we know its
  | not found.
-}
findPage : Location -> Page
findPage location =
    location
        |> Url.parseHash routeParser
        |> Maybe.withDefault NotFound


routeParser : Url.Parser (Page -> Page) Page
routeParser =
    Url.oneOf
        [ Url.map EntryList Url.top
        , Url.map EntryList (Url.s "blog")
        , Url.map (SingleEntry unknownNeighbours) (Url.s "blog" </> Url.string)
        ]


toUrl : Page -> String
toUrl route =
    "#"
        ++ case route of
            EntryList ->
                "blog"

            SingleEntry _ slug ->
                "blog/" ++ slug

            NotFound ->
                "404"


currentSlug : Model -> Maybe Slug
currentSlug model =
    case model.page of
        SingleEntry _ slug ->
            Just slug

        _ ->
            Nothing


getPageNeighbours : Page -> List Entry -> Int -> ( Page, Cmd Msg )
getPageNeighbours page entries highestJsonPage =
    case page of
        SingleEntry _ slug ->
            let
                neighbours =
                    Entry.neighboursFor slug entries

                nextJsonPage =
                    highestJsonPage + 1

                previousCommand =
                    -- IF previous == Nothing then generate command to fetch earlier entries
                    case neighbours.previous of
                        Nothing ->
                            WP.getPostList (PostList nextJsonPage) nextJsonPage

                        Just _ ->
                            Cmd.none

                _ =
                    Debug.log "Looking for neighbours:" previousCommand
            in
                SingleEntry neighbours slug
                    ! [ previousCommand ]

        -- If next == Nothing then generate command to fetch later entries
        _ ->
            page ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PostList jsonPageNo (Ok contents) ->
            let
                updatedEntries =
                    if model.jsonPage == 0 then
                        -- replace "Loading..." with the first page
                        contents
                    else
                        -- append new entries
                        model.entries ++ contents

                ( pageWithNeighbours, msg ) =
                    getPageNeighbours model.page updatedEntries jsonPageNo
            in
                { model
                    | entries = updatedEntries
                    , jsonPage = jsonPageNo
                    , page = pageWithNeighbours
                }
                    ! [ msg ]

        PostList _ (Err _) ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        Show page ->
            let
                ( pageWithNeighbours, msg ) =
                    getPageNeighbours page model.entries model.jsonPage
            in
                { model | page = pageWithNeighbours } ! [ msg ]

        Raise id ->
            { model | raised = id } ! []


prevNextButton : Model -> Int -> String -> Maybe Slug -> Html Msg
prevNextButton model id iconName neighbour =
    Button.render Mdl
        [ id ]
        model.mdl
        [ Button.icon
        , Button.ripple
        , neighbour
            |> Maybe.map (Button.link << toUrl << SingleEntry unknownNeighbours)
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
                        , Options.onClick (Show <| SingleEntry unknownNeighbours entry.slug)
                        ]
            in
                cardView style entry

        notFound =
            div [] [ text "404 not found" ]

        ( prevSlug, nextSlug, content ) =
            case model.page of
                EntryList ->
                    let
                        entries =
                            Options.div [ Options.cs "entry-list-container" ] <|
                                List.indexedMap (viewEntry Entry.viewSummary) model.entries
                    in
                        ( Nothing, Nothing, entries )

                SingleEntry { previous, next } slug ->
                    let
                        entries =
                            model.entries
                                |> Entry.findPost (Entry.hasSlug slug)
                                |> Maybe.map (flip List.drop model.entries >> List.take 1)
                                |> Maybe.map (Options.div [] << List.indexedMap (viewEntry Entry.viewDetail))
                                |> Maybe.withDefault notFound
                    in
                        ( previous, next, entries )

                NotFound ->
                    ( Nothing, Nothing, notFound )

        header =
            [ Layout.row [ Options.cs "header-row" ]
                [ Layout.navigation [] [ prevNextButton model 0 "arrow_back" prevSlug ]
                , Layout.spacer
                , Layout.title []
                    [ Html.a [ Html.Attributes.href <| toUrl EntryList ] [ img [ src "images/bjlogo.png" ] [] ]
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
