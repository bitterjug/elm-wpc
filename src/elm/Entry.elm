module Entry exposing (..)

import Date
import Date.Format exposing (format)
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
    , date : Date.Date
    }


decodeContent : Decoder String
decodeContent =
    Decode.at [ "content", "rendered" ] Decode.string


decodeDate : Decoder Date.Date
decodeDate =
    let
        stringToDate =
            Date.fromString >> Result.withDefault borindDate

        decodeDate =
            Decode.map stringToDate Decode.string
    in
        Decode.field "date" decodeDate


decodeExcerpt : Decoder String
decodeExcerpt =
    Decode.at [ "excerpt", "rendered" ] Decode.string


decodeTitle : Decoder String
decodeTitle =
    Decode.at [ "title", "rendered" ] Decode.string


decodeSlug : Decoder String
decodeSlug =
    Decode.field "slug" Decode.string


decodeEntry : Decoder Entry
decodeEntry =
    Decode.map5
        Entry
        decodeTitle
        decodeContent
        decodeExcerpt
        decodeSlug
        decodeDate


decodeEntries : Decoder (List Entry)
decodeEntries =
    Decode.list decodeEntry


loading : Entry
loading =
    Entry "..." "Loading..." "" "" borindDate


viewEntry : String -> (Entry -> String) -> Options.Style msg -> Entry -> Html msg
viewEntry typeClass getContent style entry =
    Card.view
        [ style, Options.cs <| "entry " ++ typeClass ]
        [ Card.title []
            [ Card.head [] [ text entry.title ]
            , Card.subhead [] [ formatDate entry.date ]
            ]
        , Card.text [] [ Markdown.toHtml [] (getContent entry) ]
        ]


viewDetail : Options.Style msg -> Entry -> Html msg
viewDetail =
    viewEntry "entry-detail" .content


viewSummary : Options.Style msg -> Entry -> Html msg
viewSummary =
    viewEntry "entry-summary" .excerpt


formatDate : Date.Date -> Html msg
formatDate =
    format "%e %B %Y" >> String.trim >> text


borindDate =
    Date.fromTime 0
