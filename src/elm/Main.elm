module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (src)
import Http exposing (..)
import Material
import Material.Icon as Icon
import Material.Options as Options
import Material.Color as Color
import Material.Grid as Grid
import Material.Elevation as Elevation
import Material.Layout as Layout
import Material.Button as Button
import RouteUrl exposing (UrlChange)
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>))
import Entry
import Entry exposing (Entry)


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
    , page : Page
    , mdl : Material.Model
    , raised : Int
    }


type Page
    = EntryList
    | SingleEntry String
    | NotFound


type Msg
    = PostList (Result Http.Error (List Entry))
    | Show Page
    | Mdl (Material.Msg Msg)
    | Raise Int


init : ( Model, Cmd Msg )
init =
    ( { entries = [ Entry.loading ]
      , page = EntryList
      , mdl = Material.model
      , raised = -1
      }
    , getPostList
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
        , Url.map SingleEntry (Url.s "blog" </> Url.string)
        ]


toUrl : Page -> String
toUrl route =
    "#"
        ++ case route of
            EntryList ->
                "blog"

            SingleEntry slug ->
                "blog/" ++ slug

            NotFound ->
                "404"


{-| Find the index of a post in the list by its slug
  | Currently return 0 as fefault but should somehow
  |  allow us to trigger fetching more ...
-}
findPost : Model -> String -> Int
findPost model slug =
    model.entries
        |> List.map .slug
        |> List.indexedMap (,)
        |> List.filter (\( i, entrySlug ) -> entrySlug == slug)
        |> List.head
        |> Maybe.map Tuple.first
        |> Maybe.withDefault 0


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PostList (Ok contents) ->
            { model | entries = contents } ! []

        PostList (Err _) ->
            model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        Show page ->
            { model | page = page } ! []

        Raise id ->
            { model | raised = id } ! []


prevNextButton : Material.Model -> Int -> String -> Maybe String -> Html Msg
prevNextButton mdl id iconName maybeUrl =
    Button.render Mdl
        [ id ]
        mdl
        [ Button.icon
        , Button.ripple
        , maybeUrl
            |> Maybe.map Button.link
            |> Maybe.withDefault Button.disabled
        ]
        [ Icon.i iconName ]


view : Model -> Html Msg
view model =
    let
        viewEntry : (Options.Style Msg -> Entry.Entry -> Html Msg) -> Int -> Entry.Entry -> Html Msg
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
                        , Options.onClick (Show <| SingleEntry entry.slug)
                        ]
            in
                cardView style entry

        content =
            case model.page of
                EntryList ->
                    Options.div [ Options.cs "entry-list-container" ] <|
                        List.indexedMap (viewEntry Entry.viewSummary) model.entries

                SingleEntry slug ->
                    let
                        index =
                            findPost model slug

                        entries =
                            model.entries
                                |> List.drop index
                                |> List.take 1
                    in
                        Options.div [] <|
                            List.indexedMap (viewEntry Entry.viewDetail) entries

                NotFound ->
                    div [] [ text "404 not found" ]

        previousButton =
            prevNextButton model.mdl 0 "arrow_back" Nothing

        nextButton =
            prevNextButton model.mdl 1 "arrow_forward" Nothing

        header =
            [ Layout.row [ Options.cs "header-row" ]
                [ Layout.navigation [] [ previousButton ]
                , Layout.spacer
                , Layout.title []
                    [ Html.a [ Html.Attributes.href <| toUrl EntryList ] [ img [ src "images/bjlogo.png" ] [] ]
                    ]
                , Layout.spacer
                , Layout.navigation [] [ nextButton ]
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


getPostList : Cmd Msg
getPostList =
    let
        url =
            -- "http://bitterjug.com/wp-json/wp/v2/posts/"
            "posts.json"
    in
        Http.send PostList (Http.get url Entry.decodeEntries)
