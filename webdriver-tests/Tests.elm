module Tests exposing (all)

import Webdriver as W exposing (..)
import Webdriver.Assert exposing (..)
import Webdriver.Runner as R exposing (Run, group, describe)
import Expect


all : Run
all =
    group "All Tests"
        [ testBlog
        , testEntry
        ]


baseUrl =
    "http://localhost:8000/"


goDirectlyToEntry slug =
    [ visit <| baseUrl ++ "#blog/" ++ slug ]


testBlog : Run
testBlog =
    group "Tests of blog list"
        [ describe "Base url redirects to blog with list of summaries"
            [ visit baseUrl
            , title <| Expect.equal "Bitterjug.com"
            , url <| Expect.equal (baseUrl ++ "#blog")
            , elementCount "div.entry-summary" <| Expect.atLeast 10
            ]
        , describe "Blog hash url leads to list of summaries"
            [ visit <| baseUrl ++ "#blog"
            , title <| Expect.equal "Bitterjug.com"
            , url <| Expect.equal (baseUrl ++ "#blog")
            , elementCount "div.entry-summary" <| Expect.atLeast 10
            ]
        , describe "Navigate from list to single entry"
            [ visit <| baseUrl ++ "#blog"
            , click ".entry-summary:nth-child(2)"
            , url <| Expect.equal (baseUrl ++ "#blog/minimal-elm-program")
            , elementCount "div.entry-summary" <| Expect.equal 1
            ]
        ]


testEntry : Run
testEntry =
    group "Tests of blog single entries"
        [ describe "Next of previous of next take you back to the same page" <|
            goDirectlyToEntry "minimal-elm-program"
                ++ [ url <| Expect.equal (baseUrl ++ "#blog/minimal-elm-program")
                   , elementCount "div.entry-summary" <| Expect.equal 1
                   ]
        ]
