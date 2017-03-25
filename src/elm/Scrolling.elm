module Scrolling exposing (..)

import Html exposing (Attribute)
import Html.Events exposing (on)
import Json.Decode
    exposing
        ( at
        , int
        , map
        , map3
        )


type alias Info =
    { scrollHeight : Int
    , scrollTop : Int
    , offsetHeight : Int
    }


infoDecoder =
    map3 Info
        (at [ "target", "scrollHeight" ] int)
        (at [ "target", "scrollTop" ] int)
        (at [ "target", "offsetHeight" ] int)


onScroll : (Info -> msg) -> Attribute msg
onScroll msg =
    on "scroll" <| map msg infoDecoder
