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


blogUrl =
    baseUrl ++ "#blog"


testBlog : Run
testBlog =
    let
        listExpectations =
            [ title <| Expect.equal "Bitterjug.com"
            , url <| Expect.equal blogUrl
            , elementCount "div.entry-summary" <| Expect.atLeast 10
            ]
    in
        group "Tests of blog list"
            [ describe "Base url redirects to blog with list of summaries" <|
                [ visit baseUrl ]
                    ++ listExpectations
            , describe "Blog hash url leads to list of summaries" <|
                [ visit blogUrl ]
                    ++ listExpectations
            ]


testEntry : Run
testEntry =
    let
        goDirectlyToEntry slug =
            [ visit <| blogUrl ++ "/" ++ slug
            , url <| Expect.equal (blogUrl ++ "/" ++ slug)
            ]

        clickThroughToEntry slug =
            [ visit <| blogUrl
            , click <| "." ++ slug
            , url <| Expect.equal (blogUrl ++ "/" ++ slug)
            ]
    in
        group "Tests of blog single entries"
            [ describe "Navigate from list to single entry" <|
                clickThroughToEntry "minimal-elm-program"
                    ++ [ elementCount "div.entry-detail" <| Expect.equal 1 ]
            , describe "Go directly to entry" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ elementCount "div.entry-detail" <| Expect.equal 1 ]
            , describe "Next of previous of next take you back to the same page" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ elementCount "div.entry-summary" <| Expect.equal 1 ]
            ]
