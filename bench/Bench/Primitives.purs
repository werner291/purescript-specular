module Bench.Primitives
  ( dynamicTests
  , weakDynamicTests
  ) where

import Prelude

import Bench.Types (Tests)
import Control.Monad.Cleanup (CleanupT, runCleanupT)
import Effect (Effect)
import Data.Tuple (Tuple(..), fst)
import Specular.FRP (Dynamic, WeakDynamic, holdDyn, holdWeakDyn, never, newEvent, subscribeWeakDyn_)
import Specular.FRP.Base (subscribeDyn_)

dynamicTests :: Tests
dynamicTests =
  [ Tuple "dyn" $ testDynFn1 pure
  , Tuple "dyn fmap" $ testDynFn1 \d -> pure (add 1 <$> d)
  , Tuple "dyn ap pure" $ testDynFn1 \d -> pure (pure (const 1) <*> d)
  , Tuple "dyn ap self" $ testDynFn1 \d -> pure (add <$> d <*> d)
  , Tuple "dyn bind self" $ testDynFn1 \d -> pure (d >>= \_ -> d)
  , Tuple "dyn bind inner" $ testDynFn1 \d -> pure (pure 10 >>= \_ -> d)
  , Tuple "dyn bind outer" $ testDynFn1 \d -> pure (d >>= \_ -> pure 10)
  ]

testDynFn1 :: (Dynamic Int -> Host (Dynamic Int)) -> Effect (Effect Unit)
testDynFn1 fn =
  runHost do
    event <- newEvent
    dyn <- holdDyn 0 event.event
    dyn' <- fn dyn
    subscribeDyn_ (\_ -> pure unit) dyn'
    pure (event.fire 1)

testDynFn2 :: (Dynamic Int -> Dynamic Int -> Host (Dynamic Int)) -> Effect (Effect Unit)
testDynFn2 fn =
  runHost do
    event <- newEvent
    dyn <- holdDyn 0 event.event
    dyn2 <- holdDyn 0 never
    dyn' <- fn dyn dyn2
    subscribeDyn_ (\_ -> pure unit) dyn'
    pure (event.fire 1)

type Host = CleanupT Effect

runHost :: forall a. Host a -> Effect a
runHost = map fst <<< runCleanupT

weakDynamicTests :: Tests
weakDynamicTests =
  [ Tuple "weak dyn" $ testWeakDynFn1 pure
  , Tuple "weak dyn fmap" $ testWeakDynFn1 \d -> pure (add 1 <$> d)
  , Tuple "weak dyn ap pure" $ testWeakDynFn1 \d -> pure (pure (const 1) <*> d)
  , Tuple "weak dyn ap self" $ testWeakDynFn1 \d -> pure (add <$> d <*> d)
  , Tuple "weak dyn bind self" $ testWeakDynFn1 \d -> pure (d >>= \_ -> d)
  , Tuple "weak dyn bind inner" $ testWeakDynFn1 \d -> pure (pure 10 >>= \_ -> d)
  , Tuple "weak dyn bind outer" $ testWeakDynFn1 \d -> pure (d >>= \_ -> pure 10)
  ]

testWeakDynFn1 :: (WeakDynamic Int -> Host (WeakDynamic Int)) -> Effect (Effect Unit)
testWeakDynFn1 fn =
  runHost do
    event <- newEvent
    dyn <- holdWeakDyn event.event
    dyn' <- fn dyn
    subscribeWeakDyn_ (\_ -> pure unit) dyn'
    pure ( event.fire 1)
