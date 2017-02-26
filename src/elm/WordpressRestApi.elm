module WordpressRestApi exposing (..)

import Entry exposing (Entry)
import Http


getPostList : (Result Http.Error (List Entry) -> a) -> Cmd a
getPostList message =
    let
        url =
            -- "http://bitterjug.com/wp-json/wp/v2/posts/"
            "posts.json"
    in
        Http.send message (Http.get url Entry.decodeEntries)
