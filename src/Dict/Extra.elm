module Dict.Extra
    exposing
        ( groupBy
        , fromListBy
        , removeWhen
        , removeMany
        , keepOnly
        , mapKeys
        , filterMap
        , invert
        )

{-| Convenience functions for working with `Dict`

# List operations
@docs groupBy, fromListBy

# Manipulation
@docs removeWhen, removeMany, keepOnly, mapKeys, filterMap, invert
-}

import Dict exposing (Dict)
import Set exposing (Set)


{-| Takes a key-fn and a list.
Creates a `Dict` which maps the key to a list of matching elements.

    mary = {id=1, name="Mary"}
    jack = {id=2, name="Jack"}
    jill = {id=1, name="Jill"}
    groupBy .id [mary, jack, jill] == Dict.fromList [(1, [mary, jill]), (2, [jack])]
-}
groupBy : (a -> comparable) -> List a -> Dict comparable (List a)
groupBy keyfn list =
    List.foldr
        (\x acc ->
            Dict.update (keyfn x) (Maybe.map ((::) x) >> Maybe.withDefault [ x ] >> Just) acc
        )
        Dict.empty
        list


{-| Create a dictionary from a list of values, by passing a function that can get a key from any such value.
If the function does not return unique keys, earlier values are discarded.
This can, for instance, be useful when constructing Dicts from a List of records with `id` fields:

    mary = {id=1, name="Mary"}
    jack = {id=2, name="Jack"}
    jill = {id=1, name="Jill"}
    fromListBy .id [mary, jack, jill] == Dict.fromList [(1, jack), (2, jill)]
-}
fromListBy : (a -> comparable) -> List a -> Dict comparable a
fromListBy keyfn xs =
    List.foldl
        (\x acc -> Dict.insert (keyfn x) x acc)
        Dict.empty
        xs


{-| Remove elements which satisfies the predicate.

    removeWhen (\_ v -> v == 1) (Dict.fromList [("Mary", 1), ("Jack", 2), ("Jill", 1)]) == Dict.fromList [("Jack", 2)]
-}
removeWhen : (comparable -> v -> Bool) -> Dict comparable v -> Dict comparable v
removeWhen pred dict =
    Dict.filter (\k v -> not (pred k v)) dict


{-| Remove a key-value pair if its key appears in the set.
-}
removeMany : Set comparable -> Dict comparable v -> Dict comparable v
removeMany set dict =
    Set.foldl Dict.remove dict set


{-| Keep a key-value pair if its key appears in the set.
-}
keepOnly : Set comparable -> Dict comparable v -> Dict comparable v
keepOnly set dict =
    Set.foldl
        (\k acc ->
            Maybe.withDefault acc <| Maybe.map (\v -> Dict.insert k v acc) (Dict.get k dict)
        )
        Dict.empty
        set


{-| Apply a function to all keys in a dictionary
-}
mapKeys : (comparable -> comparable) -> Dict comparable v -> Dict comparable v
mapKeys keyMapper dict =
    let
        addKey key value d =
            Dict.insert (keyMapper key) value d
    in
        Dict.foldl addKey Dict.empty dict


{-| Apply a function that may or may not succeed to all entries in a dictionary,
but only keep the successes.

    isTeen : Int -> String -> Maybe String
    isTeen n a =
        if 13 <= n && n <= 19 then
            Just <| String.toUpper a
        else
            Nothing

    Dict.fromList
        [ ( 5, "Jack" )
        , ( 15, "Jill" )
        , ( 20, "Jones" )
        ]
        |> filterMap isTeen
        == Dict.singleton 15 "JILL"
-}
filterMap :
    (comparable -> a -> Maybe b)
    -> Dict comparable a
    -> Dict comparable b
filterMap f dict =
    Dict.foldl
        (\k v ->
            case f k v of
                Just newVal ->
                    Dict.insert k newVal

                Nothing ->
                    identity
        )
        Dict.empty
        dict


{-| Inverts the keys and values of an array.

    dict = Dict.fromList [("Jill", 5), ("Jack", 10)]
    inverted = Dict.fromList [(5, "Jill"), ("Jack", 10)]
    Dict.invert dict == inverted
-}
invert : Dict comparable1 comparable2 -> Dict comparable2 comparable1
invert dict =
    Dict.foldl
        (\k v acc ->
            Dict.insert v k acc
        )
        Dict.empty
        dict
