module WordpressRestApi exposing (..)

import Date exposing (Date)
import Date.Format exposing (formatISO8601)
import Entry exposing (Entry, Entries)
import Http


baseUrl =
    "http://bitterjug.localhost/wp-json/wp/v2"


postUrl =
    baseUrl ++ "/posts"


getPostList : (Result Http.Error Entries -> a) -> Int -> Cmd a
getPostList message page =
    let
        url =
            postUrl ++ "?page=" ++ (toString page)
    in
        Http.send message (Http.get url Entry.decodeEntries)


getEarlierEntries : (Result Http.Error Entries -> a) -> Date.Date -> Cmd a
getEarlierEntries message date =
    let
        url =
            postUrl ++ "?before=" ++ (formatISO8601 date)
    in
        Http.send message (Http.get url Entry.decodeEntries)
