module Entry exposing (..)

import Array exposing (Array)
import Bootstrap.Card as Card
import Date exposing (Date)
import Date.Extra
    exposing
        ( fromIsoString
        , toUtcFormattedString
        )
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder)
import Markdown
import Maybe.Extra exposing (filter, unwrap)


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
            fromIsoString >> Maybe.withDefault boringdDate

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
    Entry "..." "Loading..." "" "" boringdDate


{-| If we have Just slug and it matches the entry slug then
    render the entry details, otherwise render its summary
-}
viewEntry : (Slug -> msg) -> Maybe Slug -> Entry -> Html msg
viewEntry msg slug entry =
    let
        ( typeClass, content ) =
            slug
                |> filter ((==) entry.slug)
                |> unwrap ( "entry-summary", entry.excerpt )
                    (always ( "entry-detail", entry.content ))
    in
        Card.config
            [ Card.attrs
                [ id entry.slug
                , class <| " entry " ++ typeClass
                , onClick <| msg entry.slug
                ]
            ]
            |> Card.block []
                [ Card.titleH4 [] [ text entry.title ]
                , Card.text [] [ Markdown.toHtml [] content ]
                ]
            |> Card.footer [] [ formatDate entry.date ]
            |> Card.view


entryList : (Slug -> msg) -> Entries -> Maybe Slug -> Html msg
entryList msg entries slug =
    entries
        |> Array.map (viewEntry msg slug)
        |> Array.toList
        |> div [ class "entry-list-container" ]


formatDate : Date.Date -> Html msg
formatDate =
    toUtcFormattedString "d MMMM y, HH:mm" >> text


boringdDate =
    Date.fromTime 0


hasSlug : Slug -> Entry -> Bool
hasSlug slug entry =
    entry.slug == slug
