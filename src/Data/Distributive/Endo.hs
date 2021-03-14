{-# Language CPP #-}
{-# Language Safe #-}
{-# Language PatternSynonyms #-}
{-# Language ViewPatterns #-}
-- |
-- Copyright   : (C) 2021 Edward Kmett
-- License     : BSD-style (see the file LICENSE)
--
-- Maintainer  : Edward Kmett <ekmett@gmail.com>
-- Stability   : provisional
-- Portability : non-portable (ghc 8.0+)
--
-- Tabulated endomorphisms
module Data.Distributive.Endo 
( Endo(.., Endo, appEndo)
) where

import Data.Distributive

#if __GLASGOW_HASKELL__ < 804
import Data.Semigroup (Semigroup(..))
#endif

-- | Tabulated endomorphisms.
--
-- Many representable functors can be used to memoize functions.
newtype Endo f = EndoDist { runEndoDist :: f (Log f) }

pattern Endo :: Distributive f => (Log f -> Log f) -> Endo f
pattern Endo { appEndo } = EndoDist (Tabulate appEndo)

{-# complete Endo :: Endo #-}

instance Distributive f => Semigroup (Endo f) where
  Endo f <> Endo g = Endo (f . g)
  {-# inline (<>) #-}

instance Distributive f => Monoid (Endo f) where
#if __GLASGOW_HASKELL__ < 804
  Endo f `mappend` Endo g = Endo (f . g)
  {-# inline mappend #-}
#endif
  mempty = EndoDist askDist
  {-# inline mempty #-}

--instance (Distributive f, Traversable f) => Eq (Endo f) where
--  (==) = liftEqDist (on (==) logToLogarithm)
