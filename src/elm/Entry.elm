module Entry exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Markdown


type alias Entry =
    { title : String
    , content : String
    , slug : String
    }


decodeContent : Decoder String
decodeContent =
    Decode.at [ "content", "rendered" ] Decode.string


decodeTitle : Decoder String
decodeTitle =
    Decode.at [ "title", "rendered" ] Decode.string


decodeSlug : Decoder String
decodeSlug =
    Decode.at [ "slug" ] Decode.string


decodeEntry : Decoder Entry
decodeEntry =
    Decode.map3 Entry decodeTitle decodeContent decodeSlug


decodeEntries : Decoder (List Entry)
decodeEntries =
    Decode.list decodeEntry


loading : Entry
loading =
    Entry "..." "Loading..." ""


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
