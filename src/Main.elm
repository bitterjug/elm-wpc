module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (..)
import Material
import Material.Icon as Icon
import Material.Options as Options
import Material.Color as Color
import Material.Layout as Layout
import Material.Button as Button
import Entry
import Entry exposing (Entry)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


type alias Model =
    { entries : List Entry
    , displayMode : DisplayMode
    , mdl : Material.Model
    }


type DisplayMode
    = EntryList
    | SingleEntry Int


type Msg
    = PostList (Result Http.Error (List Entry))
    | Previous
    | Next
    | Mdl (Material.Msg Msg)


init : ( Model, Cmd Msg )
init =
    ( Model
        [ Entry "title" "Loading..." ]
        (SingleEntry 0)
        Material.model
    , getPostList
    )


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

        Previous ->
            case model.displayMode of
                EntryList ->
                    model ! []

                SingleEntry index ->
                    { model | displayMode = SingleEntry (index + 1) } ! []

        Next ->
            case model.displayMode of
                EntryList ->
                    model ! []

                SingleEntry index ->
                    { model | displayMode = SingleEntry (index - 1) } ! []


view : Model -> Html Msg
view model =
    let
        entries =
            case model.displayMode of
                EntryList ->
                    model.entries

                SingleEntry index ->
                    model.entries
                        |> List.drop index
                        |> List.take 1

        header =
            [ Layout.row []
                [ Layout.navigation []
                    [ Button.render Mdl
                        [ 0 ]
                        model.mdl
                        [ Button.icon
                        , Button.ripple
                        , Options.onClick Previous
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
                        , Options.onClick Next
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
                    , div [ class "mdl-cell mdl-cell--8-col" ] [ Entry.viewEntries entries ]
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
