module Entry exposing (..)

import Array exposing (Array)
import Array.Extra exposing (filterMap)
import Maybe.Extra exposing (isJust)
import Html exposing (..)
import Html.Attributes exposing (..)
import Padding
import Post
    exposing
        ( Post
        , Slug
        )


type Entry
    = Post Post
    | Padding


type alias Entries =
    Array Entry


none : Entries
none =
    Array.empty


toPost : Entry -> Maybe Post
toPost entry =
    case entry of
        Post post ->
            Just post

        Padding ->
            Nothing


getPost : Int -> Entries -> Maybe Post
getPost index entries =
    Array.get index entries
        |> Maybe.andThen toPost


hasSlug : Slug -> Entry -> Bool
hasSlug slug entry =
    case entry of
        Post post ->
            post.slug == slug

        Padding ->
            False


{-| For the moment we ignore cols
-}
padCols : Int -> Entries -> Entries
padCols cols entries =
    -- TODO: padding here
    -- Don't pad the first entry. OR the last one for that matter
    entries


fromPosts : Post.Posts -> Entries
fromPosts posts =
    Array.map Post posts


firstPost : Entries -> Maybe Post
firstPost entries =
    filterMap toPost entries
        |> Array.get 0


lastPost : Entries -> Maybe Post
lastPost entries =
    let
        posts =
            filterMap toPost entries
    in
        Array.get (Array.length posts - 1) posts


viewList : (Slug -> msg) -> Entries -> Maybe Slug -> Html msg
viewList msg entries slug =
    let
        render entry =
            case entry of
                Post post ->
                    Post.viewPost msg slug post

                Padding ->
                    Padding.view
    in
        entries
            |> Array.map render
            |> Array.toList
            |> div [ class "entry-list-container" ]
