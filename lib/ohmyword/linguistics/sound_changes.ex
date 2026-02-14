defmodule Ohmyword.Linguistics.SoundChanges do
  @moduledoc """
  Handles common sound changes in Serbian language.
  """

  alias Ohmyword.Linguistics.Helpers

  # Voiced → voiceless mapping for voice assimilation
  @voiced_to_voiceless %{"ž" => "š", "z" => "s", "b" => "p", "d" => "t", "g" => "k", "đ" => "ć"}
  @voiceless ~w(p t k s š č ć f h c)

  # Palatalization (k, g, h -> č, ž, š)
  # Usually triggered by: e, i, a (in some cases)
  def palatalize(stem) do
    last_char = String.last(stem)

    case last_char do
      "k" -> String.slice(stem, 0..-2//1) <> "č"
      "g" -> String.slice(stem, 0..-2//1) <> "ž"
      "h" -> String.slice(stem, 0..-2//1) <> "š"
      "c" -> String.slice(stem, 0..-2//1) <> "č"
      "z" -> String.slice(stem, 0..-2//1) <> "ž"
      _ -> stem
    end
  end

  # Sibilarization (k, g, h -> c, z, s)
  # Triggered by: i (in Dat/Loc sg of Nouns)
  def sibilarize(stem) do
    last_char = String.last(stem)

    case last_char do
      "k" -> String.slice(stem, 0..-2//1) <> "c"
      "g" -> String.slice(stem, 0..-2//1) <> "z"
      "h" -> String.slice(stem, 0..-2//1) <> "s"
      _ -> stem
    end
  end

  # Iotation (J-change)
  # Merging consonant with 'j'
  def iotate(stem) do
    # Remove final 'j' if it exists to prepare for merge? No, typically iotation happens when adding 'j'
    # Actually, for verbs like "pis-ati", stem is "pis". We add "j" -> "pisj". Then apply iotation.
    # So this function should take the stem + j combination, or just the stem and assume J is being added.
    # Let's assume input is "stem". The caller is responsible for knowing "j" is being added.

    last_char = String.last(stem)
    base = String.slice(stem, 0..-2//1)

    case last_char do
      # pis-j -> piš
      "s" -> base <> "š"
      # brz-j -> brž
      "z" -> base <> "ž"
      # smrt-j -> smrć
      "t" -> base <> "ć"
      # glod-j -> glođ
      "d" -> base <> "đ"
      # bac-j -> bač
      "c" -> base <> "č"
      # jak-j -> jač
      "k" -> base <> "č"
      # blag-j -> blaž
      "g" -> base <> "ž"
      # tih-j -> tiš
      "h" -> base <> "š"
      # vesel-j -> veselj
      "l" -> base <> "lj"
      # crn-j -> crnj
      "n" -> base <> "nj"
      # Labials: p, b, m, v -> plj, blj, mlj, vlj
      "p" -> base <> "plj"
      "b" -> base <> "blj"
      "m" -> base <> "mlj"
      "v" -> base <> "vlj"
      # No change for others or already soft
      _ -> stem
    end
  end

  # L-O Alternation
  # L at the end of syllable changes to O
  # e.g., beo (nom sg m) -> beli (nom pl m)
  # This usually means checking if word ends in "o" and changing back to "l" before adding endings,
  # OR checking if stem ends in "l" and changing to "o" if it's at end of word.
  # Since our inflector starts with "beo", the stem might be extracted as "be".
  # But "beo" comes from "bel".
  # If we have "beo", we need to know the underlying stem "bel".
  # This is tricky without a dictionary.
  # However, for generation, if we have "beo", and we want plural "beli",
  # we need to recognize "beo" -> stem "bel".
  def resolve_l_o_alternation(term) do
    if String.ends_with?(term, "eo") do
      # beo -> bel
      String.slice(term, 0..-3//1) <> "el"
    else
      if String.ends_with?(term, "o") do
        # Check preceeding vowel. If vowel, likely not L-O (e.g., "zoološki"? No that's adj).
        # "sto" -> "stol"? "posao" -> "posl"?
        # Simple heuristic: -ao -> -al
        if String.ends_with?(term, "ao") do
          String.slice(term, 0..-3//1) <> "al"
        else
          term
        end
      else
        term
      end
    end
  end

  # Voice Assimilation (Jednačenje po zvučnosti)
  # Serbian has voice assimilation where consonants change voicing to match adjacent consonants.
  # Voiced: b, d, g, z, ž, dž, đ
  # Voiceless: p, t, k, s, š, č, ć, f, h, c
  #
  # Rules:
  # 1. Voiced -> Voiceless before voiceless consonants
  # 2. Voiceless -> Voiced before voiced consonants (less common in morphological changes)
  def assimilate_voice(term) do
    result =
      Enum.reduce(@voiced_to_voiceless, term, fn {voiced, voiceless}, acc ->
        Enum.reduce(@voiceless, acc, fn vl, acc2 ->
          String.replace(acc2, voiced <> vl, voiceless <> vl)
        end)
      end)

    # Cascade: one assimilation may expose another (e.g., razžk → razšk → rasšk)
    if result == term, do: term, else: assimilate_voice(result)
  end

  defdelegate is_vowel?(char), to: Helpers
end
