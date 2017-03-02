module WordpressRestApi
    exposing
        ( getPostList
        , getEarlierEntries
        , getLaterEntries
        , getEntry
        )

import Date exposing (Date)
import Date.Extra exposing (toUtcIsoString)
import Entry exposing (Entry, Slug, Entries)
import Http
import HttpBuilder exposing (..)


baseUrl =
    "http://bitterjug.localhost/wp-json/wp/v2"


postUrl =
    baseUrl ++ "/posts"


expectEntries : Http.Expect Entries
expectEntries =
    Http.expectJson Entry.decodeEntries


getPostList : (Result Http.Error Entries -> a) -> Int -> Cmd a
getPostList message page =
    get postUrl
        |> withQueryParams [ ( "page", toString page ) ]
        |> withExpect expectEntries
        |> send message


getEarlierEntries : (Result Http.Error Entries -> a) -> Date.Date -> Cmd a
getEarlierEntries message date =
    get postUrl
        |> withQueryParams [ ( "before", (toUtcIsoString date) ) ]
        |> withExpect expectEntries
        |> send message


getLaterEntries : (Result Http.Error Entries -> a) -> Date.Date -> Cmd a
getLaterEntries message date =
    get postUrl
        |> withQueryParams
            [ ( "after", (toUtcIsoString date) )
            , ( "order", "asc" )
            ]
        |> withExpect expectEntries
        |> send message


getEntry : (Result Http.Error Entries -> a) -> Slug -> Cmd a
getEntry message slug =
    get postUrl
        |> withQueryParams [ ( "slug", slug ) ]
        |> withExpect (Http.expectJson Entry.decodeEntries)
        |> send message
