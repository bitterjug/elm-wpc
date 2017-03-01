module Tests exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int, tuple, string)
import String
import Array
import ArrayExtra exposing (locate)


all : Test
all =
    describe "All tests"
        [ testLocate ]


testLocate : Test
testLocate =
    describe "locate should give the index of the first array result satisfying a predicate or Nothing"
        [ test "location of not found is nothing" <|
            \() ->
                Array.empty
                    |> locate ((==) 1)
                    |> Expect.equal Nothing
        , test "Index of first element" <|
            \() ->
                [ 1 ]
                    |> Array.fromList
                    |> locate ((==) 1)
                    |> Expect.equal (Just 0)
        , test "Index of third and last element" <|
            \() ->
                [ 1, 2, 3 ]
                    |> Array.fromList
                    |> locate ((==) 3)
                    |> Expect.equal (Just 2)
        , test "Index of middle element" <|
            \() ->
                [ 1, 2, 3 ]
                    |> Array.fromList
                    |> locate ((==) 2)
                    |> Expect.equal (Just 1)
        , test "Index first of repeated" <|
            \() ->
                [ 1, 2, 3, 2 ]
                    |> Array.fromList
                    |> locate ((==) 2)
                    |> Expect.equal (Just 1)
        ]
