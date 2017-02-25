module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
import ListLib exposing (..)


all : Test
all =
    describe "All tests"
        [ testIndexOf
        , testGetPrevious
        , testGetNext
        ]


testIndexOf : Test
testIndexOf =
    describe "Test my indexOf function"
        [ test "Index of not found is nothing" <|
            \() ->
                indexOf ((==) 1) []
                    |> Expect.equal Nothing
        , test "Index of first item is Just 0" <|
            \() ->
                indexOf ((==) 1) [ 1 ]
                    |> Expect.equal (Just 0)
        , test "Index of second is 1" <|
            \() ->
                indexOf ((==) 2) [ 1, 2 ]
                    |> Expect.equal (Just 1)
        , test "Index of last is length -1" <|
            \() ->
                let
                    ints =
                        [ 1, 2, 3 ]
                in
                    indexOf ((==) 3) ints
                        |> Expect.equal (Just <| List.length ints - 1)
        , test "Index of fourth is 3" <|
            \() ->
                indexOf ((==) "d") [ "a", "b", "c", "d", "e", "f" ]
                    |> Expect.equal (Just 3)
        ]


testGetNext : Test
testGetNext =
    describe "Test my get Previous function"
        [ test "Next of first element is second " <|
            \() ->
                getNext [ "a", "b", "c" ] ((==) "a")
                    |> Expect.equal (Just "b")
        , test "Next of not found is Nothing" <|
            \() ->
                getNext [] ((==) 1)
                    |> Expect.equal Nothing
        , test "Next of median element " <|
            \() ->
                getNext [ "a", "b", "c" ] ((==) "b")
                    |> Expect.equal (Just "c")
        , test "Next of median element " <|
            \() ->
                getNext [ "a", "b", "c" ] ((==) "c")
                    |> Expect.equal Nothing
        , test "Next of median element " <|
            \() ->
                getNext [ "c" ] ((==) "c")
                    |> Expect.equal Nothing
        ]


testGetPrevious : Test
testGetPrevious =
    describe "Test my get Previous function"
        [ test "previous of last element is penultimate element" <|
            \() ->
                getPrevious [ "a", "b", "c" ] ((==) "c")
                    |> Expect.equal (Just "b")
        , test "Previous of thrid element is second element" <|
            \() ->
                getPrevious [ 10, 20, 30, 40 ] ((==) 30)
                    |> Expect.equal (Just 20)
        , test "Previous of median element is element before" <|
            \() ->
                getPrevious [ 1, 2, 3 ] ((==) 2)
                    |> Expect.equal (Just 1)
        , test "no previous if item not found" <|
            \() ->
                getPrevious [] ((==) 3)
                    |> Expect.equal Nothing
        , test "no previous of first in list" <|
            \() ->
                getPrevious [ 1 ] ((==) 1)
                    |> Expect.equal Nothing
        ]
