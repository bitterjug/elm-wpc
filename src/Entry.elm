module Entry exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Markdown


type alias Entry =
    { title : String
    , content : String
    }


decodeContent : Decode.Decoder String
decodeContent =
    Decode.at [ "content", "rendered" ] Decode.string


decodeTitle : Decode.Decoder String
decodeTitle =
    Decode.at [ "title", "rendered" ] Decode.string


decodeEntry : Decode.Decoder Entry
decodeEntry =
    Decode.map2 Entry decodeTitle decodeContent


decodeEntries : Decode.Decoder (List Entry)
decodeEntries =
    Decode.list decodeEntry


viewEntry : Entry -> Html msg
viewEntry entry =
    main_
        [ class "mdl-shadow--4dp post" ]
        [ h1 [ class "mdl-typography--headline" ] [ text entry.title ]
        , Markdown.toHtml [] entry.content
        ]


viewEntries : List Entry -> Html msg
viewEntries entries =
    div [] (List.map viewEntry entries)
