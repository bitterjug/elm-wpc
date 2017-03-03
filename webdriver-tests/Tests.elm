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
        group "Entry list"
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
        expectEntry slug =
            [ url <| Expect.equal (blogUrl ++ "/" ++ slug)
            , elementCount "div.entry-detail" <| Expect.equal 1
            ]

        goDirectlyToEntry slug =
            [ visit <| blogUrl ++ "/" ++ slug
            ]

        clickThroughToEntry slug =
            [ visit <| blogUrl
            , click <| "." ++ slug
            ]

        clickPrevious =
            click ".header-row >nav:nth-of-type(1) > a"

        clickNext =
            click ".header-row >nav:nth-of-type(2) > a"

        clickLastEntry =
            click ".entry-summary:nth-last-of-type(1)"
    in
        group "Single entry pages"
            [ describe "Navigate from list to single entry" <|
                clickThroughToEntry "minimal-elm-program"
                    ++ expectEntry "minimal-elm-program"
            , describe "Go directly to entry" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ expectEntry "minimal-elm-program"
            , describe "Next of previous of direct takes you back to the same page" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ clickPrevious, clickNext ]
                    ++ expectEntry "minimal-elm-program"
            , describe "Next of previous of click through takes you back to the same page" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ clickPrevious, clickNext ]
                    ++ expectEntry "minimal-elm-program"
            , describe "previous of next  of direct takes you back to the same page" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ clickNext, clickPrevious ]
                    ++ expectEntry "minimal-elm-program"
            , describe "previous of next of click through takes you back to the same page" <|
                goDirectlyToEntry "minimal-elm-program"
                    ++ [ clickNext, clickPrevious ]
                    ++ expectEntry "minimal-elm-program"
            , describe "next of last adds to the list" <|
                [ visit <| blogUrl
                , elementCount "div.entry-summary" <| Expect.equal 10
                , clickLastEntry
                , clickNext
                , click ".mdl-layout__title>a"
                , elementCount "div.entry-summary" <| Expect.atLeast 20
                ]
            ]
