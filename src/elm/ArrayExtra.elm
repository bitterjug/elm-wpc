module ArrayExtra exposing (..)

import Array exposing (Array)


locate : (a -> Bool) -> Array a -> Maybe Int
locate predicate array =
    array
        |> Array.indexedMap (,)
        |> Array.filter (predicate << Tuple.second)
        |> Array.map Tuple.first
        |> Array.get 0
