{-# OPTIONS --rewriting #-}
module rewriting.examples.CastGradualGuarantee where

open import Data.List using (List; []; _∷_; length)
open import Data.Nat
open import Data.Bool using (true; false) renaming (Bool to 𝔹)
open import Data.Nat.Properties
open import Data.Product using (_,_;_×_; proj₁; proj₂; Σ-syntax; ∃-syntax)
open import Data.Unit using (⊤; tt)
open import Data.Unit.Polymorphic renaming (⊤ to topᵖ; tt to ttᵖ)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality as Eq
  using (_≡_; _≢_; refl; sym; cong; subst; trans)
open import Relation.Nullary using (¬_; Dec; yes; no)
open import Var
open import rewriting.examples.Cast
open import rewriting.examples.CastDeterministic
open import rewriting.examples.StepIndexedLogic2

ℰ⊎𝒱-type : Set
ℰ⊎𝒱-type = (Prec × Term × Term) ⊎ (Prec × Term × Term)

ℰ⊎𝒱-ctx : Context
ℰ⊎𝒱-ctx = ℰ⊎𝒱-type ∷ []

ℰˢ⟦_⟧ : Prec → Term → Term → Setˢ ℰ⊎𝒱-ctx (cons Now ∅)
ℰˢ⟦ A⊑B ⟧ M M′ = (inj₂ (A⊑B , M , M′)) ∈ zeroˢ

𝒱ˢ⟦_⟧ : Prec → Term → Term → Setˢ ℰ⊎𝒱-ctx (cons Now ∅)
𝒱ˢ⟦ A⊑B ⟧ V V′ = (inj₁ (A⊑B , V , V′)) ∈ zeroˢ

pre-𝒱 : Prec → Term → Term → Setˢ ℰ⊎𝒱-ctx (cons Later ∅)
pre-𝒱 (.★ , ★ , unk⊑) (V ⟨ G !⟩) (V′ ⟨ H !⟩)
    with G ≡ᵍ H
... | yes refl = let g = gnd⇒ty G in
                 (Value V)ˢ ×ˢ (Value V′)ˢ
                 ×ˢ (▷ˢ (𝒱ˢ⟦ (g , g , Refl⊑) ⟧ V V′))
... | no neq = ⊥ ˢ
pre-𝒱 (.★ , $ₜ ι′ , unk⊑) (V ⟨ $ᵍ ι !⟩) ($ c)
    with ($ᵍ ι) ≡ᵍ ($ᵍ ι′)
... | yes refl = (Value V)ˢ ×ˢ ▷ˢ (𝒱ˢ⟦ ($ₜ ι , $ₜ ι , Refl⊑) ⟧ V ($ c))
... | no new = ⊥ ˢ
pre-𝒱 (.★ , A′ ⇒ B′ , unk⊑) (V ⟨ ★⇒★ !⟩) V′ =
    (Value V)ˢ ×ˢ (Value V′)ˢ
    ×ˢ ▷ˢ (𝒱ˢ⟦ (★ ⇒ ★ , A′ ⇒ B′ , fun⊑ unk⊑ unk⊑) ⟧ V V′)
pre-𝒱 ($ₜ ι , $ₜ ι , base⊑) ($ c) ($ c′) = (c ≡ c′) ˢ
pre-𝒱 ((A ⇒ B) , (A′ ⇒ B′) , fun⊑ A⊑A′ B⊑B′) (ƛ N) (ƛ N′) =
    ∀ˢ[ W ] ∀ˢ[ W′ ] ▷ˢ (𝒱ˢ⟦ (A , A′ , A⊑A′) ⟧ W W′)
                  →ˢ ▷ˢ (ℰˢ⟦ (B , B′ , B⊑B′) ⟧ (N [ W ]) (N′ [ W′ ])) 
pre-𝒱 (A , A′ , A⊑A′) V V′ = ⊥ ˢ

pre-ℰ : Prec → Term → Term → Setˢ ℰ⊎𝒱-ctx (cons Later ∅)
pre-ℰ (A , A′ , A⊑A′) M M′ =
    (pre-𝒱 (A , A′ , A⊑A′) M M′ ⊎ˢ (reducible M)ˢ ⊎ˢ (reducible M′)ˢ
         ⊎ˢ (Blame M′)ˢ)
    ×ˢ ((∀ˢ[ N ] (M —→ N)ˢ →ˢ ▷ˢ (ℰˢ⟦ (A , A′ , A⊑A′) ⟧ N M′))
     ×ˢ (∀ˢ[ N′ ] (M′ —→ N′)ˢ →ˢ ▷ˢ (ℰˢ⟦ (A , A′ , A⊑A′) ⟧ M N′)))

pre-ℰ⊎𝒱 : ℰ⊎𝒱-type → Setˢ ℰ⊎𝒱-ctx (cons Later ∅)
pre-ℰ⊎𝒱 (inj₁ ((A , A′ , A⊑A′) , V , V′)) = pre-𝒱 (A , A′ , A⊑A′) V V′
pre-ℰ⊎𝒱 (inj₂ ((A , A′ , A⊑A′) , M , M′)) = pre-ℰ (A , A′ , A⊑A′) M M′

ℰ⊎𝒱 : ℰ⊎𝒱-type → Setᵒ
ℰ⊎𝒱 X = μᵒ pre-ℰ⊎𝒱 X

𝒱⟦_⟧ : (c : Prec) → Term → Term → Setᵒ
𝒱⟦ c ⟧ V V′ = ℰ⊎𝒱 (inj₁ (c , V , V′))

ℰ⟦_⟧ : (c : Prec) → Term → Term → Setᵒ
ℰ⟦ c ⟧ M M′ = ℰ⊎𝒱 (inj₂ (c , M , M′))

progress : (A A′ : Type) → A ⊑ A′ → Term → Term → Setᵒ
progress A A′ A⊑A′ M M′ =
    𝒱⟦ (A , A′ , A⊑A′) ⟧ M M′ ⊎ᵒ (reducible M)ᵒ ⊎ᵒ (reducible M′)ᵒ
                 ⊎ᵒ (Blame M′)ᵒ

preservation : (A A′ : Type) → A ⊑ A′ → Term → Term → Setᵒ
preservation A A′ A⊑A′ M M′ = 
    (∀ᵒ[ N ] (M —→ N)ᵒ →ᵒ ▷ᵒ (ℰ⟦ (A , A′ , A⊑A′) ⟧ N M′))
    ×ᵒ (∀ᵒ[ N′ ] (M′ —→ N′)ᵒ →ᵒ ▷ᵒ (ℰ⟦ (A , A′ , A⊑A′) ⟧ M N′))

ℰ-stmt : ∀{A A′}{A⊑A′ : A ⊑ A′}{M M′}
  → ℰ⟦ (A , A′ , A⊑A′) ⟧ M M′ ≡ᵒ progress A A′ A⊑A′ M M′
      ×ᵒ preservation A A′ A⊑A′ M M′
ℰ-stmt {A}{A′}{A⊑A′}{M}{M′} =
  let p = (A , A′ , A⊑A′) in
  let X₁ = inj₁ (p , M , M′) in
  let X₂ = inj₂ (p , M , M′) in
  ℰ⟦ p ⟧ M M′                                                 ⩦⟨ ≡ᵒ-refl refl ⟩
  μᵒ pre-ℰ⊎𝒱 X₂                                      ⩦⟨ fixpointᵒ pre-ℰ⊎𝒱 X₂ ⟩
  # (pre-ℰ⊎𝒱 X₂) (ℰ⊎𝒱 , ttᵖ)
                           ⩦⟨ cong-×ᵒ (cong-⊎ᵒ (≡ᵒ-sym (fixpointᵒ pre-ℰ⊎𝒱 X₁))
                                (≡ᵒ-refl refl)) (≡ᵒ-refl refl) ⟩
  progress A A′ A⊑A′ M M′ ×ᵒ preservation A A′ A⊑A′ M M′
  ∎

{- Relate Open Terms -}

𝓖⟦_⟧ : (Γ : List Prec) → Subst → Subst → List Setᵒ
𝓖⟦ [] ⟧ σ σ′ = []
𝓖⟦ c ∷ Γ ⟧ σ σ′ = (𝒱⟦ c ⟧ (σ 0) (σ′ 0))
                     ∷ 𝓖⟦ Γ ⟧ (λ x → σ (suc x)) (λ x → σ′ (suc x))

_⊨_⊑_⦂_ : List Prec → Term → Term → Prec → Set
Γ ⊨ M ⊑ M′ ⦂ c = ∀ (γ γ′ : Subst) → 𝓖⟦ Γ ⟧ γ γ′ ⊢ᵒ ℰ⟦ c ⟧ (⟪ γ ⟫ M) (⟪ γ′ ⟫ M′)

{- Related values are syntactic values -}

𝒱⇒Value : ∀ {k} c M M′
   → # (𝒱⟦ c ⟧ M M′) (suc k)
     ------------------------
   → Value M × Value M′
𝒱⇒Value {k} (.★ , ★ , unk⊑) (V ⟨ G !⟩) (V′ ⟨ H !⟩) 𝒱MM′
    with G ≡ᵍ H
... | no neq = ⊥-elim 𝒱MM′
... | yes refl
    with 𝒱MM′
... | v , v′ , _ = (v 〈 G 〉) , (v′ 〈 G 〉)
𝒱⇒Value {k} (.★ , $ₜ ι′ , unk⊑) (V ⟨ $ᵍ ι !⟩) ($ c) 𝒱MM′
    with  ($ᵍ ι) ≡ᵍ ($ᵍ ι′)
... | no neq = ⊥-elim 𝒱MM′
... | yes refl
    with 𝒱MM′
... | v , _ = (v 〈 $ᵍ ι′ 〉) , ($̬ c)
𝒱⇒Value {k} (.★ , A′ ⇒ B′ , unk⊑) (V ⟨ ★⇒★ !⟩) V′ 𝒱VV′
    with 𝒱VV′
... | v , v′ , _ = (v 〈 ★⇒★ 〉) , v′
𝒱⇒Value {k} ($ₜ ι , $ₜ ι , base⊑) ($ c) ($ c′) refl = ($̬ c) , ($̬ c)
𝒱⇒Value {k} ((A ⇒ B) , (A′ ⇒ B′) , fun⊑ A⊑A′ B⊑B′) (ƛ N) (ƛ N′) 𝒱VV′ =
    (ƛ̬ N) , (ƛ̬ N′)

{- Related values are related expressions -}

𝒱⇒ℰ : ∀{c : Prec}{𝒫}{V V′}
   → 𝒫 ⊢ᵒ 𝒱⟦ c ⟧ V V′
     -----------------
   → 𝒫 ⊢ᵒ ℰ⟦ c ⟧ V V′
𝒱⇒ℰ {c}{𝒫}{V}{V′} ⊢𝒱VV′ = substᵒ (≡ᵒ-sym ℰ-stmt) (prog ,ᵒ pres)
  where
  prog = inj₁ᵒ ⊢𝒱VV′
  pres = (Λᵒ[ N ] →ᵒI (constᵒE Zᵒ λ V—→N →
            ⊢ᵒ-sucP (⊢ᵒ-weaken ⊢𝒱VV′) λ 𝒱VV →
              ⊥-elim (value-irreducible (proj₁ (𝒱⇒Value c V V′ 𝒱VV)) V—→N)))
         ,ᵒ
         (Λᵒ[ N′ ] →ᵒI (constᵒE Zᵒ λ V′—→N′ →
            ⊢ᵒ-sucP (⊢ᵒ-weaken ⊢𝒱VV′) λ 𝒱VV →
              ⊥-elim (value-irreducible (proj₂ (𝒱⇒Value c V V′ 𝒱VV)) V′—→N′)))

{- ℰ-bind (Monadic Bind Lemma) -}

𝒱→ℰF : Prec → Prec → Frame → Term → Term → Setᵒ
𝒱→ℰF c d F M M′ = ∀ᵒ[ V ] ∀ᵒ[ V′ ] (M —↠ V)ᵒ →ᵒ (M′ —↠ V′)ᵒ
                   →ᵒ 𝒱⟦ d ⟧ V V′ →ᵒ ℰ⟦ c ⟧ (F ⟦ V ⟧) (F ⟦ V′ ⟧)

𝒱→ℰF-expansion-L : ∀{𝒫}{c}{d}{F}{M}{M′}{N}
   → M —→ N
   → 𝒫 ⊢ᵒ 𝒱→ℰF c d F M M′
     --------------------
   → 𝒫 ⊢ᵒ 𝒱→ℰF c d F N M′
𝒱→ℰF-expansion-L {𝒫}{c}{d}{F}{M}{M′}{N} M→N 𝒱→ℰF[MM′] =
  Λᵒ[ V ] Λᵒ[ V′ ]
  let 𝒱→ℰF[NM′] : 𝒱⟦ d ⟧ V V′ ∷ (M′ —↠ V′)ᵒ ∷ (N —↠ V)ᵒ ∷ 𝒫
               ⊢ᵒ ℰ⟦ c ⟧  (F ⟦ V ⟧) (F ⟦ V′ ⟧)
      𝒱→ℰF[NM′] = ⊢ᵒ-sucP (Sᵒ Zᵒ) λ M′—↠V′ →
               ⊢ᵒ-sucP (Sᵒ (Sᵒ Zᵒ)) λ N—↠V →
               let M—↠V = constᵒI (M —→⟨ M→N ⟩ N—↠V) in
               let 𝒱→ℰF[MM′]VV′ = ⊢ᵒ-weaken (⊢ᵒ-weaken (⊢ᵒ-weaken
                                    (instᵒ (instᵒ 𝒱→ℰF[MM′] V) V′)))
               in appᵒ (appᵒ (appᵒ 𝒱→ℰF[MM′]VV′ M—↠V) (constᵒI M′—↠V′)) Zᵒ
  in →ᵒI (→ᵒI (→ᵒI 𝒱→ℰF[NM′]))

ℰ-bind-M : Prec → Prec → Frame → Term → Term → Setᵒ
ℰ-bind-M c d F M M′ = ℰ⟦ d ⟧ M M′ →ᵒ 𝒱→ℰF c d F M M′
    →ᵒ ℰ⟦ c ⟧ (F ⟦ M ⟧) (F ⟦ M′ ⟧)

ℰ-bind-prop : Prec → Prec → Frame → Setᵒ
ℰ-bind-prop c d F = ∀ᵒ[ M ] ∀ᵒ[ M′ ] ℰ-bind-M c d F M M′

ℰ-bind-aux : ∀{𝒫}{c}{d}{F} → 𝒫 ⊢ᵒ ℰ-bind-prop c d F
ℰ-bind-aux {𝒫}{c}{d}{F} = lobᵒ Goal
 where     
 Goal : ▷ᵒ ℰ-bind-prop c d F ∷ 𝒫 ⊢ᵒ ℰ-bind-prop c d F
 Goal = Λᵒ[ M ] Λᵒ[ M′ ] →ᵒI (→ᵒI Goal′)
  where
  Goal′ : ∀{M}{M′}
     → (𝒱→ℰF c d F M M′) ∷ ℰ⟦ d ⟧ M M′ ∷ ▷ᵒ ℰ-bind-prop c d F ∷ 𝒫
        ⊢ᵒ ℰ⟦ c ⟧ (F ⟦ M ⟧) (F ⟦ M′ ⟧)
  Goal′{M}{M′} = {!!}
  
