module Specular.Dom.Element where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, mkEffectFn2, runEffectFn1, runEffectFn2)
import Foreign.Object as Object
import Specular.Dom.Browser (Node, createElementImpl, setAttributesImpl)
import Specular.Dom.Builder.Class (liftBuilderWithRun)
import Specular.Dom.Node.Class (Attrs, TagName, removeAttributes)
import Specular.Dom.Widget (class MonadWidget)
import Specular.FRP (Dynamic, _readDynamic, _subscribeEvent, changed)
import Specular.Internal.Effect (DelayedEffects, _newRef, _readRef, _writeRef, pushDelayed)

newtype Prop = Prop (EffectFn2 Node DelayedEffects Unit)

el :: forall m a. MonadWidget m => TagName -> Array Prop -> m a -> m a
el tagName props body = liftBuilderWithRun $ mkEffectFn2 \env run -> do
  node <- runEffectFn1 createElementImpl tagName
  runEffectFn2 foreachEFn props $ mkEffectFn1 \(Prop prop) ->
    runEffectFn2 prop node env.cleanup
  runEffectFn2 run (env { parent = node }) body

foreign import foreachEFn :: forall a. EffectFn2 (Array a) (EffectFn1 a Unit) Unit

attr :: Attrs -> Prop
attr attrs = Prop $ mkEffectFn2 \node _ ->
  runEffectFn2 setAttributesImpl node attrs

attrD :: Dynamic Attrs -> Prop
attrD dynAttrs = Prop $ mkEffectFn2 \node cleanups -> do
  attrsRef <- runEffectFn1 _newRef Object.empty
  let
    resetAttributes = mkEffectFn1 \newAttrs -> do
      oldAttrs <- runEffectFn1 _readRef attrsRef
      runEffectFn2 _writeRef attrsRef newAttrs
      let
        changed = Object.filterWithKey (\k v -> Object.lookup k oldAttrs /= Just v) newAttrs
        removed = Array.filter (\k -> not (k `Object.member` newAttrs)) $ Object.keys oldAttrs

      removeAttributes node removed
      runEffectFn2 setAttributesImpl node changed

  initialAttrs <- runEffectFn1 _readDynamic dynAttrs
  runEffectFn1 resetAttributes initialAttrs
  unsub <- runEffectFn2 _subscribeEvent (runEffectFn1 resetAttributes) (changed dynAttrs)
  pushDelayed cleanups unsub
  pure unit
