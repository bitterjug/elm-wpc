module WordpressRestApi
    exposing
        ( getPostList
        , getEarlierEntries
        , getLaterEntries
        , getEntry
        )

import Date exposing (Date)
import Date.Format exposing (formatISO8601)
import Entry exposing (Entry, Slug, Entries)
import Http


baseUrl =
    "http://bitterjug.localhost/wp-json/wp/v2"


postUrl =
    baseUrl ++ "/posts"


getEntries : String -> String -> (Result Http.Error Entries -> a) -> Cmd a
getEntries param value message =
    let
        url =
            postUrl ++ "?" ++ param ++ "=" ++ value
    in
        Http.send message (Http.get url Entry.decodeEntries)


getPostList : (Result Http.Error Entries -> a) -> Int -> Cmd a
getPostList message page =
    getEntries "page" (toString page) message


getEarlierEntries : (Result Http.Error Entries -> a) -> Date.Date -> Cmd a
getEarlierEntries message date =
    getEntries "before" (formatISO8601 date) message


getLaterEntries : (Result Http.Error Entries -> a) -> Date.Date -> Cmd a
getLaterEntries message date =
    getEntries "after" (formatISO8601 date) message


getEntry : (Result Http.Error Entries -> a) -> Slug -> Cmd a
getEntry message slug =
    getEntries "slug" slug message
