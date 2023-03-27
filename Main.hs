{-# LANGUAGE FlexibleInstances #-}

module Main where

import Algebra
import FunExp

import Prelude hiding ((+), (-), (*), (/), negate,
                       recip, (^), pi, sin,
                       cos, exp, fromInteger, fromRational)

type R = Double
type Tri a = (a, a, a)
type TriFun a = Tri (a -> a)
type FunTri a = a -> Tri a


instance Additive a => Additive (Tri a) where
  (+) = addTri
  zero = zeroTri

instance (Additive a, Multiplicative a) => Multiplicative (Tri a) where
  (*) = mulTri
  one = oneTri

instance AddGroup a => AddGroup (Tri a) where
  negate = negateTri

instance (AddGroup a, MulGroup a) => MulGroup (Tri a) where
  recip = recipTri

instance Transcendental a => Transcendental (Tri a) where
  pi = piTri
  sin = sinTri
  cos = cosTri
  exp = expTri

-- Part 1:
eval'' :: Transcendental a => FunExp -> a -> a
eval'' = eval' . derive

-- b)
addTri :: Additive a => Tri a -> Tri a -> Tri a
addTri (f, f', f'') (g, g', g'') = (f + g, f' + g', f'' + g'')

-- f = 0 => f' = 0 => f'' = 0
zeroTri :: Additive a => Tri a
zeroTri = (zero, zero, zero)

mulTri :: (Additive a, Multiplicative a) => Tri a -> Tri a -> Tri a
mulTri (f, f', f'') (g, g', g'') = (d0, d1, d2)
  where
    -- d^0 (f * g)
    d0 = f * g

    -- d (f * g)
    d1 = f' * g + f * g'

    -- d^2 (f * g)
    d2 = f'' * g + f' * g' + f' * g' + f * g''

oneTri :: (Additive a, Multiplicative a) => Tri a
oneTri = (one, zero, zero)

negateTri :: AddGroup a => Tri a -> Tri a
negateTri (f, f', f'') = (negate f, negate f', negate f'')

recipTri :: (AddGroup a, MulGroup a) => Tri a -> Tri a
recipTri (f, f', f'') = (d0, d1, d2)
  where
    -- x/y = x * (1 / y)
    divF :: MulGroup a => a -> a -> a
    divF x y = x * recip y -- x * (1/y)

    -- D^0(1/f) = 1/f
    d0 = recip f

    -- D(1/f) = -f'/f^2
    d1 = negate f' `divF` (f * f)

    -- D^2(1/f) = D(-f'/f^2) = (2 * f'^2 - f * f'') / f^3
    d2 = ((f' * f') + (f' * f') - (f * f'')) `divF` (f * f * f)

piTri :: Transcendental a => Tri a
piTri = (pi, zero, zero)

sinTri :: Transcendental a => Tri a -> Tri a
sinTri (f, f', f'') = (d0, d1, d2)
  where
    d0 = sin f
    d1 = f' * cos f
    d2 = (f'' * cos f) + (f' * f' * (negate $ sin f))

cosTri :: Transcendental a => Tri a -> Tri a
cosTri (f, f', f'') = (d0, d1, d2)
  where
    d0 = cos f
    d1 = f' * (negate $ sin f)
    d2 = (f'' * (negate $ sin f)) + (f' * f' * (negate $ cos f))

expTri :: Transcendental a => Tri a -> Tri a
expTri (f, f', f'') = (d0, d1, d2)
  where
    d0 = exp f
    d1 = f' * exp f
    d2 = (f'' * exp f) + (f' * f' * exp f)

-- sin^2 + cos^1 = 1
trigIdTest :: Transcendental a => a -> a
trigIdTest x = ((sin x) * (sin x)) + ((cos x) * (cos x))

-- c)
-- Utilizing the predefined eval & derive for FunExp's
evalDD :: Transcendental a => FunExp -> FunTri a
evalDD f = \x -> (eval f x, eval' f x, eval'' f x)

-- Part 2:
-- Retrieves the zeroth, first, and second derivative from some Tri
fstTri, sndTri, trdTri :: Tri a -> a
fstTri (f, _, _) = f
sndTri (_, f', _) = f'
trdTri (_, _, f'') = f''


-- Part 2
-- a)
newtonTri :: (Tri R -> Tri R) -> R -> R -> R
newtonTri f e x
  | abs fx < e = x
  | fx' /= 0   = newtonTri f e next
  | otherwise  = newtonTri f e (x + e)
  where
    fx = fstTri $ f (x, one, zero)
    fx' = sndTri $ f (x, one, zero)
    next = x - (fx / fx')

newtonList :: (Tri R -> Tri R) -> R -> R -> [R]
newtonList f e x
  | abs fx < e = []
  | fx' /= 0   = next : newtonList f e next
  | otherwise  = next : newtonList f e (x + e)
  where
    fx = fstTri $ f (x, one, zero)
    fx' = sndTri $ f (x, one, zero)
    next = x - (fx / fx')

-- b)
test0 :: Transcendental a => Tri a -> Tri a
test0 x = x^2

test1 :: Transcendental a => Tri a -> Tri a
test1 x = x^2 - one

test2 :: Transcendental a => Tri a -> Tri a
test2 = sin

test3 :: (AddGroup a, MulGroup a) => Int -> a -> Tri a -> Tri a
test3 n x y = y ^ n - constTri x
  where
    constTri x = (x, one, zero)

testN :: Int -> [R]
testN n = map (newtonTri (t !! n) 0.001) [-2.0, -1.5..2.0]
  where
    t = [test0, test1, test2]

-- Part 3
data Result a = Maximum a | Minimum a | Dunno a
  deriving Show

optim :: (Tri R -> Tri R) -> R -> R -> Result R
optim f e x
  | f''y < 0  = Maximum y
  | f''y > 0  = Minimum y
  | otherwise = Dunno y
  where
    f''y = trdTri $ f (y, one, zero)
    y = newtonTri shift e x

    -- Shifts the derivative one step to the "left"
    shift :: Tri R -> Tri R
    shift z = (sndTri $ f z, trdTri $ f z, undefined)

main :: IO ()
main = undefined
