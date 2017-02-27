module WordpressRestApi exposing (..)

import Entry exposing (Entry)
import Http


getPostList : (Result Http.Error (List Entry) -> a) -> Int -> Cmd a
getPostList message page =
    let
        url =
            -- "http://bitterjug.com/wp-json/wp/v2/posts/"
            "posts.json" ++ "-page" ++ (toString page)
    in
        Http.send message (Http.get url Entry.decodeEntries)
