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
        , find
        )

{-| Convenience functions for working with `Dict`


# List operations

@docs groupBy, fromListBy


# Manipulation

@docs removeWhen, removeMany, keepOnly, mapKeys, filterMap, invert


# Find

@docs find

-}

import Dict exposing (Dict)
import Set exposing (Set)


{-| Takes a key-fn and a list.
Creates a `Dict` which maps the key to a list of matching elements.

    >>> import Dict

    >>> groupBy String.length [ "tree" , "apple" , "leaf" ]
    Dict.fromList [ ( 4, [ "tree", "leaf" ] ), ( 5, [ "apple" ] ) ]

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

    >>> fromListBy String.length [ "tree" , "apple" , "leaf" ]
    Dict.fromList [ ( 4, "leaf" ), ( 5, "apple" ) ]

-}
fromListBy : (a -> comparable) -> List a -> Dict comparable a
fromListBy keyfn xs =
    List.foldl
        (\x acc -> Dict.insert (keyfn x) x acc)
        Dict.empty
        xs


{-| Remove elements which satisfies the predicate.

    >>> Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ]
    ...     |> removeWhen (\_ value -> value == 1 )
    Dict.fromList [ ( "Jack", 2 ) ]

-}
removeWhen : (comparable -> v -> Bool) -> Dict comparable v -> Dict comparable v
removeWhen pred dict =
    Dict.filter (\k v -> not (pred k v)) dict


{-| Remove a key-value pair if its key appears in the set.

    >>> import Set

    >>> Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ]
    ...     |> removeMany (Set.fromList [ "Mary", "Jill" ])
    Dict.fromList [ ( "Jack", 2 ) ]

-}
removeMany : Set comparable -> Dict comparable v -> Dict comparable v
removeMany set dict =
    Set.foldl Dict.remove dict set


{-| Keep a key-value pair if its key appears in the set.

    >>> Dict.fromList [ ( "Mary", 1 ), ( "Jack", 2 ), ( "Jill", 1 ) ]
    ...     |> keepOnly (Set.fromList [ "Jack", "Jill" ])
    Dict.fromList [ ( "Jack", 2 ), ( "Jill", 1 ) ]

-}
keepOnly : Set comparable -> Dict comparable v -> Dict comparable v
keepOnly set dict =
    Set.foldl
        (\k acc ->
            Maybe.withDefault acc <| Maybe.map (\v -> Dict.insert k v acc) (Dict.get k dict)
        )
        Dict.empty
        set


{-| Apply a function to all keys in a dictionary.

    >>> Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ) ]
    ...     |> mapKeys (\x -> x + 1)
    Dict.fromList [ ( 6, "Jack" ), ( 11, "Jill" ) ]

    >>> Dict.fromList [ ( 5, "Jack" ), ( 10, "Jill" ) ]
    ...     |> mapKeys toString
    Dict.fromList [ ( "5", "Jack" ), ( "10", "Jill" ) ]

-}
mapKeys : (comparable -> comparable1) -> Dict comparable v -> Dict comparable1 v
mapKeys keyMapper dict =
    Dict.foldl
        (\k v acc ->
            Dict.insert (keyMapper k) v acc
        )
        Dict.empty
        dict


{-| Apply a function that may or may not succeed to all entries in a dictionary,
but only keep the successes.

    >>> let
    ...     isTeen n a =
    ...         if 13 <= n && n <= 19 then
    ...             Just <| String.toUpper a
    ...         else
    ...             Nothing
    ... in
    ...     Dict.fromList [ ( 5, "Jack" ), ( 15, "Jill" ), ( 20, "Jones" ) ]
    ...         |> filterMap isTeen
    Dict.fromList [ ( 15, "JILL" ) ]

-}
filterMap : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable b
filterMap f dict =
    Dict.foldl
        (\k v acc ->
            case f k v of
                Just newVal ->
                    Dict.insert k newVal acc

                Nothing ->
                    acc
        )
        Dict.empty
        dict


{-| Inverts the keys and values of an array.

    >>> Dict.fromList [ ("key", "value")  ]
    ...     |> invert
    Dict.fromList [ ( "value", "key" ) ]

-}
invert : Dict comparable1 comparable2 -> Dict comparable2 comparable1
invert dict =
    Dict.foldl
        (\k v acc ->
            Dict.insert v k acc
        )
        Dict.empty
        dict


{-| Find the first key/value pair that matches a predicate.

    >>> Dict.fromList [ ( 9, "Jill" ), ( 7, "Jill" ) ]
    ...     |> find (\_ value -> value == "Jill")
    Just ( 7, "Jill" )

    >>> Dict.fromList [ ( 9, "Jill" ), ( 7, "Jill" ) ]
    ...     |> find (\key _ -> key == 5)
    Nothing

-}
find : (comparable -> a -> Bool) -> Dict comparable a -> Maybe ( comparable, a )
find predicate dict =
    Dict.foldl
        (\k v acc ->
            case acc of
                Just _ ->
                    acc

                Nothing ->
                    if predicate k v then
                        Just ( k, v )
                    else
                        Nothing
        )
        Nothing
        dict
