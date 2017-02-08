module Main exposing (..)

import Html exposing (..)
import Http exposing (..)
import Json.Decode as Decode
import Markdown


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Model =
    List String


type Msg
    = PostList (Result Http.Error (List String))


init : ( Model, Cmd Msg )
init =
    let
        _ =
            Debug.log "init" ()
    in
        ( [ "Loading..." ], getPostList )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PostList (Ok contents) ->
            let
                _ =
                    Debug.log "OK:" contents
            in
                contents ! []

        PostList (Err _) ->
            let
                _ =
                    Debug.log "Err:" ()
            in
                model ! []


view : Model -> Html Msg
view model =
    let
        viewPost content =
            li [] [ Markdown.toHtml [] content ]
    in
        ul [] (List.map viewPost model)


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
