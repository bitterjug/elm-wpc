module Padding exposing (..)

import Bootstrap.Card as Card
import Html exposing (..)
import Html.Attributes exposing (..)


view : Html msg
view =
    div [ class "padding" ]
        [ img [ src "images/man.front.png" ] [] ]



{-
   Card.config
       [ Card.attrs
           [ class "entry" ]
       ]
       |> Card.block []
           [ Card.titleH4 [] [ text "Padding" ] ]
       |> Card.view
-}
