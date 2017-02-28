module WordpressRestApi exposing (..)

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
