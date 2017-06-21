module Post exposing (..)

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


type alias Post =
    { title : String
    , content : String
    , excerpt : String
    , slug : Slug
    , date : Date
    }


type alias Posts =
    Array Post


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
        -- Decode.field "date_gmt" decodeGmtDate
        Decode.field "date" decodeGmtDate


decodeExcerpt : Decoder String
decodeExcerpt =
    Decode.at [ "excerpt", "rendered" ] Decode.string


decodeTitle : Decoder String
decodeTitle =
    Decode.at [ "title", "rendered" ] Decode.string


decodeSlug : Decoder String
decodeSlug =
    Decode.field "slug" Decode.string


decodePost : Decoder Post
decodePost =
    Decode.map5
        Post
        decodeTitle
        decodeContent
        decodeExcerpt
        decodeSlug
        decodeDate


loading : Post
loading =
    Post "..." "Loading..." "" "" boringdDate


{-| If we have Just slug and it matches the post slug then
    render the post details, otherwise render its summary
-}
viewPost : (Slug -> msg) -> Maybe Slug -> Post -> Html msg
viewPost msg slug post =
    let
        ( typeClass, content ) =
            slug
                |> filter ((==) post.slug)
                |> unwrap ( "entry-summary", post.excerpt )
                    (always ( "entry-detail", post.content ))
    in
        Card.config
            [ Card.attrs
                [ id post.slug
                , class <| " entry " ++ typeClass
                , onClick <| msg post.slug
                ]
            ]
            |> Card.block []
                [ Card.titleH4 [] [ text post.title ]
                , Card.text [] [ Markdown.toHtml [] content ]
                ]
            |> Card.footer [] [ formatDate post.date ]
            |> Card.view


formatDate : Date.Date -> Html msg
formatDate =
    toUtcFormattedString "d MMMM y, HH:mm" >> text


boringdDate =
    Date.fromTime 0


hasSlug : Slug -> Post -> Bool
hasSlug slug post =
    post.slug == slug
