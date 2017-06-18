module Padding exposing (..)

import Bootstrap.Card as Card
import Html exposing (..)
import Html.Attributes exposing (..)


view : Html msg
view =
    Card.config
        [ Card.attrs
            [ class "post" ]
        ]
        |> Card.block []
            [ Card.titleH4 [] [ text "Padding" ] ]
        |> Card.view
