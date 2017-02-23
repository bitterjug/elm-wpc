module Entry exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Markdown
import Material.Card as Card
import Material.Options as Options


type alias Entry =
    { title : String
    , content : String
    , excerpt : String
    , slug : String
    }


decodeContent : Decoder String
decodeContent =
    Decode.at [ "content", "rendered" ] Decode.string


decodeExcerpt : Decoder String
decodeExcerpt =
    Decode.at [ "excerpt", "rendered" ] Decode.string


decodeTitle : Decoder String
decodeTitle =
    Decode.at [ "title", "rendered" ] Decode.string


decodeSlug : Decoder String
decodeSlug =
    Decode.at [ "slug" ] Decode.string


decodeEntry : Decoder Entry
decodeEntry =
    Decode.map4 Entry decodeTitle decodeContent decodeExcerpt decodeSlug


decodeEntries : Decoder (List Entry)
decodeEntries =
    Decode.list decodeEntry


loading : Entry
loading =
    Entry "..." "Loading..." "" ""


viewEntry : Options.Style msg -> Entry -> Html msg
viewEntry style entry =
    Card.view
        [ style ]
        [ Card.title [] [ text entry.title ]
        , Card.text [] [ Markdown.toHtml [] entry.content ]
        ]


viewSummary : Options.Style msg -> Entry -> Html msg
viewSummary style entry =
    Card.view
        [ style ]
        [ Card.title [] [ Card.head [] [ text entry.title ] ]
        , Card.text [] [ Markdown.toHtml [] entry.excerpt ]
        ]
