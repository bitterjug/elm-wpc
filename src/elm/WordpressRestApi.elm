module WordpressRestApi
    exposing
        ( getPostList
        , getEarlierEntries
        , getLaterEntries
        , getEntry
        , Payload
        )

import Array exposing (Array)
import Date exposing (Date)
import Date.Extra exposing (toUtcIsoString)
import Dict
import Entry exposing (Entry, Slug, Entries)
import Http
import HttpBuilder exposing (..)
import Json.Decode as Decode exposing (Decoder)


baseUrl =
    "http://bitterjug.localhost/wp-json/wp/v2"


postUrl =
    baseUrl ++ "/posts"


type alias Payload =
    { remaining : Int
    , entries : Entries
    }


type alias Preprocessor =
    List Entry -> List Entry


{-| Entry list to Array decoder with preprocessing
 (decodeEntries id) preserves order
 (decodeEntries List.reverse) reverses it
-}
decodeEntries : Preprocessor -> Decoder Entries
decodeEntries preprocessList =
    Entry.decodeEntry
        |> Decode.list
        |> Decode.map (preprocessList >> Array.fromList)


expectEntriesAndTotal : Preprocessor -> Http.Response String -> Result String Payload
expectEntriesAndTotal preprocessList response =
    let
        total =
            Dict.get "X-WP-Total" response.headers
                |> Maybe.map String.toInt
                |> Maybe.andThen (Result.toMaybe)
                |> Maybe.withDefault 0

        entryResult =
            Decode.decodeString (decodeEntries preprocessList) response.body

        buildResult entries =
            Payload (total - Array.length entries) entries
    in
        Result.map buildResult entryResult


getPostList : (Result Http.Error Payload -> a) -> Cmd a
getPostList message =
    get postUrl
        |> withExpect
            (Http.expectStringResponse
                (expectEntriesAndTotal List.reverse)
            )
        |> send message


getEarlierEntries : (Result Http.Error Payload -> a) -> Date.Date -> Cmd a
getEarlierEntries message date =
    get postUrl
        |> withQueryParams
            [ ( "before", (toUtcIsoString date) ) ]
        |> withExpect
            (Http.expectStringResponse
                (expectEntriesAndTotal (\a -> a))
            )
        |> send message


getLaterEntries : (Result Http.Error Payload -> a) -> Date.Date -> Cmd a
getLaterEntries message date =
    get postUrl
        |> withQueryParams
            [ ( "after", (toUtcIsoString date) )
            , ( "order", "asc" )
            ]
        |> withExpect
            (Http.expectStringResponse
                (expectEntriesAndTotal List.reverse)
            )
        |> send message


getEntry : (Result Http.Error Payload -> a) -> Slug -> Cmd a
getEntry message slug =
    get postUrl
        |> withQueryParams [ ( "slug", slug ) ]
        |> withExpect
            (Http.expectStringResponse
                (expectEntriesAndTotal (\a -> a))
            )
        |> send message
