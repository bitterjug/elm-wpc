module Entry exposing (..)

import Array exposing (Array)
import Date exposing (Date)
import Date.Extra
    exposing
        ( fromIsoString
        , toFormattedString
        )
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Markdown
import Material.Card as Card
import Material.Options as Options


type alias Slug =
    String


type alias Entry =
    { title : String
    , content : String
    , excerpt : String
    , slug : String
    , date : Date
    }


type alias Entries =
    Array Entry


none : Entries
none =
    Array.empty


decodeContent : Decoder String
decodeContent =
    Decode.at [ "content", "rendered" ] Decode.string


decodeDate : Decoder Date.Date
decodeDate =
    let
        stringToDate =
            fromIsoString >> Maybe.withDefault borindDate

        ensureZulu dateString =
            if dateString |> String.endsWith "Z" then
                dateString
            else
                dateString ++ "Z"

        decodeGmtDate =
            Decode.string
                |> Decode.map (ensureZulu >> stringToDate)
    in
        Decode.field "date_gmt" decodeGmtDate


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


decodeEntries : Decoder Entries
decodeEntries =
    decodeEntry
        |> Decode.list
        |> Decode.map Array.fromList


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
    toFormattedString "d MMMM y, HH:mm" >> text


borindDate =
    Date.fromTime 0


hasSlug : Slug -> Entry -> Bool
hasSlug slug entry =
    entry.slug == slug
