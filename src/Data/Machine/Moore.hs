{-# Language CPP #-}
{-# Language DerivingStrategies #-}
{-# Language DeriveGeneric #-}
{-# Language TypeFamilies #-}
{-# Language DeriveFunctor #-}
{-# Language MultiParamTypeClasses #-}
{-# Language Safe #-}
#if __GLASGOW_HASKELL__ >= 806
{-# Language DerivingVia #-}
#endif
-- |
-- Copyright   :  (C) 2012-2021 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  provisional
-- Portability :  portable
--
-- <http://en.wikipedia.org/wiki/Moore_machine>

module Data.Machine.Moore
  ( Moore(..)
  , logMoore
  , unfoldMoore
  ) where

import Control.Applicative
import Control.Monad.Fix
import Control.Monad.Zip
import Control.Monad.Reader.Class
import Data.Distributive
import qualified Data.Semigroup as Semigroup
#if __GLASGOW_HASKELL__ < 804
import Data.Semigroup (Semigroup(..))
#endif
import GHC.Generics
import Numeric
import Prelude

-- data Moore a b where
--   Moore :: Distributive f => f b -> (a -> Endo f) -> Log f -> Moore a b

-- | obvious 'Moore' machines
data Moore a b = Moore b (a -> Moore a b)
  deriving stock (Functor, Generic1)
#if __GLASGOW_HASKELL__ >= 806
  deriving
    ( Applicative, Monad, MonadFix
    , MonadZip, MonadReader [a]
    ) via Dist (Moore a)
  deriving
    ( Semigroup
    , Monoid
    ) via Ap (Moore a) b
  deriving
    ( Num, Fractional, Floating
    )  via Dist (Moore a) b
#endif

instance Distributive (Moore a) where
  type Log (Moore a) = [a]
  index (Moore b _) [] = b
  index (Moore _ k) (a:as) = index (k a) as
  tabulate f = Moore (f []) $ \a -> tabulate (f.(a:))

-- | Accumulate the input as a sequence.
logMoore :: Monoid m => Moore m m
logMoore = h mempty where
  h m = Moore m (\a -> h (m `mappend` a))
{-# INLINE logMoore #-}

-- | Construct a Moore machine from a state valuation and transition function
unfoldMoore :: (s -> (b, a -> s)) -> s -> Moore a b
unfoldMoore f = go where
  go s = case f s of
    (b, g) -> Moore b (go . g)
{-# INLINE unfoldMoore #-}

#if __GLASGOW_HASKELL__ < 806
instance Applicative (Moore a) where
  pure = pureDist
  {-# inline pure #-}
  (<*>) = apDist
  {-# inline (<*>) #-}
  liftA2 = liftD2
  {-# inline liftA2 #-}
  m <* _ = m
  {-# inline (<*) #-}
  _ *> n = n
  {-# inline (*>) #-}

-- | slow diagonalization
instance Monad (Moore a) where
  (>>=) = bindDist
  {-# inline (>>=) #-}
  (>>) = (*>)
  {-# inline (>>) #-}

instance MonadFix (Moore a) where
  mfix = mfixDist
  {-# inline mfix #-}

instance MonadZip (Moore a) where
  mzipWith = mzipWithDist
  {-# inline mzipWith #-}

instance MonadReader [a] (Moore a) where
  ask = askDist
  {-# inline ask #-}
  local = localDist
  {-# inline local #-}

instance Semigroup b => Semigroup (Moore a b) where
  Moore x f <> Moore y g = Moore (x Semigroup.<> y) (f Semigroup.<> g)
  {-# inline (<>) #-}

instance Monoid b => Monoid (Moore a b) where
  mempty = Moore mempty mempty
  {-# inline mempty #-}
#if !(MIN_VERSION_base(4,11,0))
  Moore x f `mappend` Moore y g = Moore (x `mappend` y) (f `mappend` g)
  {-# inline mappend #-}
#endif

instance Num b => Num (Moore a b) where
  (+) = liftA2 (+)
  (-) = liftA2 (-)
  (*) = liftA2 (*)
  negate = fmap negate
  abs = fmap abs
  signum = fmap signum
  fromInteger = pure . fromInteger
  {-# inline (+) #-}
  {-# inline (-) #-}
  {-# inline (*) #-}
  {-# inline negate #-}
  {-# inline abs #-}
  {-# inline signum #-}
  {-# inline fromInteger #-}

instance Fractional b => Fractional (Moore a b) where
  (/) = liftA2 (/)
  recip = fmap recip
  fromRational = pure . fromRational
  {-# inline (/) #-}
  {-# inline recip #-}
  {-# inline fromRational #-}

instance Floating b => Floating (Moore a b) where
  pi = pure pi
  exp = fmap exp
  log = fmap log
  sqrt = fmap sqrt
  (**) = liftA2 (**)
  logBase = liftA2 logBase
  sin = fmap sin
  cos = fmap cos
  tan = fmap tan
  asin = fmap asin
  acos = fmap acos
  atan = fmap atan
  sinh = fmap sinh
  cosh = fmap cosh
  tanh = fmap tanh
  asinh = fmap asinh
  acosh = fmap acosh
  atanh = fmap atanh
  log1p = fmap log1p
  expm1 = fmap expm1
  log1pexp = fmap log1pexp
  log1mexp = fmap log1mexp
  {-# inline pi #-}
  {-# inline exp #-}
  {-# inline log #-}
  {-# inline sqrt #-}
  {-# inline (**) #-}
  {-# inline logBase #-}
  {-# inline sin #-}
  {-# inline cos #-}
  {-# inline tan #-}
  {-# inline asin #-}
  {-# inline acos #-}
  {-# inline atan #-}
  {-# inline sinh #-}
  {-# inline cosh #-}
  {-# inline tanh #-}
  {-# inline asinh #-}
  {-# inline acosh #-}
  {-# inline atanh #-}
  {-# inline log1p #-}
  {-# inline expm1 #-}
  {-# inline log1pexp #-}
  {-# inline log1mexp #-}

#endif
