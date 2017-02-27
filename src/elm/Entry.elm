module Entry exposing (..)

import Date
import Date.Format exposing (format)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import ListLib
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
    , date : Date.Date
    }


type alias Neighbours =
    { previous : Maybe Slug
    , next : Maybe Slug
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


findPost : (Entry -> Bool) -> List Entry -> Maybe Int
findPost predicate entries =
    entries
        |> List.indexedMap (,)
        |> List.filter (predicate << Tuple.second)
        |> List.head
        |> Maybe.map Tuple.first


hasSlug : Slug -> Entry -> Bool
hasSlug slug entry =
    entry.slug == slug


neighboursFor : Slug -> List Entry -> Neighbours
neighboursFor slug entries =
    { previous =
        hasSlug slug
            |> ListLib.getNext entries
            |> Maybe.map .slug
    , next =
        hasSlug slug
            |> ListLib.getPrevious entries
            |> Maybe.map .slug
    }
