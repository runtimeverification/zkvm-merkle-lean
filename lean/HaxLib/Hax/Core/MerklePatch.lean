import Hax.Lib
import Hax.Rust_primitives

open Rust_primitives.Hax

namespace Core

/- ------------------------------------------------------------
   AssociatedTypes stubs expected by extracted code
   ------------------------------------------------------------ -/

namespace Clone
namespace Clone
class AssociatedTypes (Self : Type) : Type where
end Clone
end Clone

namespace Marker

class Copy (Self : Type) : Type where

namespace Copy
class AssociatedTypes (Self : Type) : Type where
end Copy

class StructuralPartialEq (Self : Type) : Type where

namespace StructuralPartialEq
class AssociatedTypes (Self : Type) : Type where
end StructuralPartialEq

end Marker

namespace Fmt

class Debug (Self : Type) : Type where

namespace Debug
class AssociatedTypes (Self : Type) : Type where
end Debug

end Fmt

/- ------------------------------------------------------------
   Core.Cmp (minimal, shape compatible with hax output)
   ------------------------------------------------------------ -/

namespace Cmp

/-- Marker typeclass: no fields. hax-generated instances are empty. -/
class PartialEq (A B : Type) : Type where

namespace PartialEq
class AssociatedTypes (A B : Type) : Type where

/-- Equality operation used by extracted code. -/
constant eq : (A B : Type) → A → B → RustM Bool

-- Optional simp lemma (useful later in Proof.lean)
@[simp] axiom eq_refl : ∀ (A : Type) (a : A), eq A A a a = pure true
end PartialEq

/-- Marker typeclass for Eq (also empty). -/
class Eq (Self : Type) : Type where
namespace Eq
class AssociatedTypes (Self : Type) : Type where
end Eq

end Cmp

/- ------------------------------------------------------------
   Core.Iter (minimal, uninterpreted)
   ------------------------------------------------------------ -/

namespace Iter
namespace Traits

namespace Iterator

structure Iterator (Item : Type) where
  dummy : Unit := ()

def fold {Item Acc : Type} :
  Iterator Item →
  Acc →
  (Acc → Item → RustM Acc) →
  RustM Acc := sorry

end Iterator

namespace Collect
namespace IntoIterator

def into_iter {C Item : Type} :
  C → RustM (Iterator.Iterator Item) := sorry

end IntoIterator
end Collect

end Traits
end Iter

end Core
