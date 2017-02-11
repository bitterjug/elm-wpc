module Main exposing (..)

import Html exposing (..)
import Http exposing (..)
import Json.Decode as Decode
import Markdown
import Material
import Material.Scheme
import Material.Layout as Layout


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Model =
    { entries : List String
    , mdl : Material.Model
    }


type Msg
    = PostList (Result Http.Error (List String))
    | Mdl (Material.Msg Msg)


init : ( Model, Cmd Msg )
init =
    let
        _ =
            Debug.log "init" ()
    in
        ( Model [ "Loading..." ] Material.model, getPostList )


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
    Material.Scheme.top <|
        Layout.render Mdl
            model.mdl
            [ Layout.fixedHeader ]
            { header = [ h1 [] [ text "Bitterjug.com" ] ]
            , drawer = []
            , tabs = ( [], [] )
            , main = [ viewEntries model ]
            }


viewEntries : Model -> Html Msg
viewEntries model =
    let
        viewPost content =
            li [] [ Markdown.toHtml [] content ]
    in
        ul [] (List.map viewPost model.entries)


getPostList : Cmd Msg
getPostList =
    let
        url =
            "http://bitterjug.com/wp-json/wp/v2/posts/"
    in
        Http.send PostList (Http.get url decodeContents)


decodeContents : Decode.Decoder (List String)
decodeContents =
    let
        decodePost =
            Decode.at [ "content", "rendered" ] Decode.string
    in
        Decode.list decodePost
