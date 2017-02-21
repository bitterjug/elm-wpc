module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (..)
import Material
import Material.Icon as Icon
import Material.Options as Options
import Material.Color as Color
import Material.Elevation as Elevation
import Material.Layout as Layout
import Material.Button as Button
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>))
import Entry
import Entry exposing (Entry)


main =
    Navigation.program locationChange
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


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


init : Location -> ( Model, Cmd Msg )
init location =
    ( { entries = [ Entry.loading ]
      , page =
            EntryList
            -- TODO: later I want to start with most recent post
      , mdl = Material.model
      , raised = -1
      }
    , getPostList
    )


locationChange : Location -> Msg
locationChange =
    findPage >> Show


findPage : Location -> Page
findPage location =
    location
        |> Url.parsePath routeParser
        |> Maybe.withDefault NotFound


routeParser : Url.Parser (Page -> Page) Page
routeParser =
    Url.oneOf
        [ Url.map EntryList Url.top
        , Url.map SingleEntry (Url.s "blog" </> Url.string)
        ]


toUrl : Page -> String
toUrl route =
    case route of
        EntryList ->
            "/blog/"

        SingleEntry slug ->
            "/blog/" ++ slug

        NotFound ->
            "/404"


{-| Find the index of a post in the list by its slug
   Currently return 0 as fefault but should somehow
   allow us to trigger fetching more ...
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
            let
                _ =
                    Debug.log "OK:" contents
            in
                { model | entries = contents } ! []

        PostList (Err _) ->
            let
                _ =
                    Debug.log "Err:" ()
            in
                model ! []

        Mdl msg_ ->
            Material.update Mdl msg_ model

        Show page ->
            { model | page = page } ! []

        Raise id ->
            { model | raised = id } ! []


view : Model -> Html Msg
view model =
    let
        viewEntry : Int -> Entry.Entry -> Html Msg
        viewEntry cardId entry =
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
                Entry.viewEntry style entry

        content =
            case model.page of
                EntryList ->
                    Options.div [] <|
                        List.indexedMap viewEntry model.entries

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
                            List.indexedMap viewEntry entries

                NotFound ->
                    div [] [ text "404 not found" ]

        header =
            [ Layout.row []
                [ Layout.navigation []
                    [ Button.render Mdl
                        [ 0 ]
                        model.mdl
                        [ Button.icon
                        , Button.ripple
                          -- , Options.onClick Previous
                        ]
                        [ Icon.i "arrow_back" ]
                    ]
                , Layout.spacer
                , Layout.title [] [ text "Bitterjug" ]
                , Layout.spacer
                , Layout.navigation []
                    [ Button.render Mdl
                        [ 1 ]
                        model.mdl
                        [ Button.icon
                        , Button.ripple
                          -- , Options.onClick Next
                        ]
                        [ Icon.i "arrow_forward" ]
                    ]
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
                [ div [ class "mdl-grid" ]
                    [ div [ class "mdl-cell mdl-cell--2-col mdl-cell--hide-phone mdl-cell--hide-tablet" ] []
                    , div [ class "mdl-cell mdl-cell--8-col" ] [ content ]
                    , div [ class "mdl-cell mdl-cell--2-col mdl-cell--hide-phone mdl-cell--hide-tablet" ] []
                    ]
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
