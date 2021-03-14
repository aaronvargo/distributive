{-# Language Trustworthy #-}
{-# Language PatternSynonyms #-}
{-# Language ViewPatterns #-}

module Data.Distributive.Coerce where

import Data.Coerce

(#.) :: Coercible b c => (b -> c) -> (a -> b) -> a -> c
(#.) _ = coerce
{-# inline (#.) #-}

(.#) :: Coercible a b => (b -> c) -> (a -> b) -> a -> c
(.#) f _ = coerce f
{-# inline (.#) #-}

infixr 9 #., .#

pattern Coerce :: Coercible a b => a -> b
pattern Coerce x <- (coerce -> x) where
  Coerce x = coerce x

