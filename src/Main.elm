module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (..)
import Material
import Material.Scheme
import Material.Color as Color
import Material.Layout as Layout
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
    = List
    | Single Int


type Msg
    = PostList (Result Http.Error (List Entry))
    | Mdl (Material.Msg Msg)


init : ( Model, Cmd Msg )
init =
    ( Model
        [ Entry "title" "Loading..." ]
        (Single 0)
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


view : Model -> Html Msg
view model =
    let
        entries =
            case model.displayMode of
                List ->
                    model.entries

                Single index ->
                    model.entries |> List.drop index |> List.take 1
    in
        Layout.render Mdl
            model.mdl
            [ Layout.fixedHeader ]
            { header = [ h1 [] [ text "Bitterjug" ] ]
            , drawer = []
            , tabs = ( [], [] )
            , main =
                [ div [ class "mdl-grid" ]
                    [ div [ class "mdl-cell mdl-cell--1-col mdl-cell--hide-phone mdl-cell--hide-tablet" ] []
                    , div [ class "mdl-cell mdl-cell--10-col" ] [ Entry.viewEntries entries ]
                    , div [ class "mdl-cell mdl-cell--1-col mdl-cell--hide-phone mdl-cell--hide-tablet" ] []
                    ]
                ]
            }


getPostList : Cmd Msg
getPostList =
    let
        url =
            "http://bitterjug.com/wp-json/wp/v2/posts/"
    in
        Http.send PostList (Http.get url Entry.decodeEntries)
