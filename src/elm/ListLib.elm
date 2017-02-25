module ListLib exposing (indexOf, getPrevious, getNext)


indexOf : (a -> Bool) -> List a -> Maybe Int
indexOf predicate list =
    list
        |> List.indexedMap (,)
        |> List.filter (\( i, val ) -> predicate val)
        |> List.head
        |> Maybe.map Tuple.first


getPrevious : List a -> (a -> Bool) -> Maybe a
getPrevious list predicate =
    let
        decrement n =
            if n > 0 then
                Just (n - 1)
            else
                Nothing
    in
        list
            |> indexOf predicate
            |> Maybe.andThen decrement
            |> Maybe.map (flip List.drop list)
            |> Maybe.andThen List.head


getNext : List a -> (a -> Bool) -> Maybe a
getNext list predicate =
    list
        |> indexOf predicate
        |> Maybe.map ((+) 1)
        |> Maybe.map (flip List.drop list)
        |> Maybe.andThen List.head
