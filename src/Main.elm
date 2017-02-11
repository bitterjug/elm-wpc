module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http exposing (..)
import Material
import Material.Scheme
import Material.Color as Color
import Material.Layout as Layout
import Entry exposing (..)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Model =
    { entries : List Entry
    , mdl : Material.Model
    }


type Msg
    = PostList (Result Http.Error (List Entry))
    | Mdl (Material.Msg Msg)


init : ( Model, Cmd Msg )
init =
    ( Model [ Entry "title" "Loading..." ] Material.model, getPostList )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PostList (Ok contents) ->
            let
                _ =
                    Debug.log "OK:" contents
            in
                Model contents model.mdl ! []

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
    Material.Scheme.topWithScheme Color.Grey Color.Red <|
        Layout.render Mdl
            model.mdl
            [ Layout.fixedHeader ]
            { header = [ h1 [] [ text "Bitterjug" ] ]
            , drawer = []
            , tabs = ( [], [] )
            , main =
                [ div [ class "mdl-grid", style [ ( "background-color", "#f5f5f5" ) ] ]
                    [ div [ class "mdl-cell mdl-cell--1-col mdl-cell--hide-phone mdl-cell--hide-tablet" ] []
                    , div [ class "mdl-cell mdl-cell--10-col" ] [ viewEntries model.entries ]
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
        Http.send PostList (Http.get url decodeEntries)
