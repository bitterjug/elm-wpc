module WordpressRestApi
    exposing
        ( getPostList
        , getEarlierPosts
        , getLaterPosts
        , getPost
        , Payload
        )

import Array exposing (Array)
import Date exposing (Date)
import Date.Extra exposing (toUtcIsoString)
import Dict
import Post exposing (Post, Slug, Posts)
import Http
import HttpBuilder exposing (..)
import Json.Decode as Decode exposing (Decoder)


baseUrl =
    "http://bitterjug.localhost/wp-json/wp/v2"


postUrl =
    baseUrl ++ "/posts"


type alias Payload =
    { remaining : Int
    , posts : Posts
    }


type alias Preprocessor =
    List Post -> List Post


{-| Post list to Array decoder with preprocessing
 (decodePosts id) preserves order
 (decodePosts List.reverse) reverses it
-}
decodePosts : Preprocessor -> Decoder Posts
decodePosts preprocessList =
    Post.decodePost
        |> Decode.list
        |> Decode.map (preprocessList >> Array.fromList)


expectPostsAndTotal : Preprocessor -> Http.Response String -> Result String Payload
expectPostsAndTotal preprocessList response =
    let
        total =
            Dict.get "X-WP-Total" response.headers
                |> Maybe.map String.toInt
                |> Maybe.andThen (Result.toMaybe)
                |> Maybe.withDefault 0

        postResult =
            Decode.decodeString (decodePosts preprocessList) response.body

        buildResult posts =
            Payload (total - Array.length posts) posts
    in
        Result.map buildResult postResult


getPostList : (Result Http.Error Payload -> a) -> Cmd a
getPostList message =
    get postUrl
        |> withExpect
            (Http.expectStringResponse
                (expectPostsAndTotal (\a -> a))
             -- (expectPostsAndTotal List.reverse) For some reason this is no longer needed. What did I do?
            )
        |> send message


getEarlierPosts : (Result Http.Error Payload -> a) -> Date.Date -> Cmd a
getEarlierPosts message date =
    get postUrl
        |> withQueryParams
            [ ( "before", (toUtcIsoString date) ) ]
        |> withExpect
            (Http.expectStringResponse
                (expectPostsAndTotal (\a -> a))
            )
        |> send message


getLaterPosts : (Result Http.Error Payload -> a) -> Date.Date -> Cmd a
getLaterPosts message date =
    get postUrl
        |> withQueryParams
            [ ( "after", (toUtcIsoString date) )
            , ( "order", "asc" )
            ]
        |> withExpect
            (Http.expectStringResponse
                (expectPostsAndTotal List.reverse)
            )
        |> send message


getPost : (Result Http.Error Payload -> a) -> Slug -> Cmd a
getPost message slug =
    get postUrl
        |> withQueryParams [ ( "slug", slug ) ]
        |> withExpect
            (Http.expectStringResponse
                (expectPostsAndTotal (\a -> a))
            )
        |> send message
