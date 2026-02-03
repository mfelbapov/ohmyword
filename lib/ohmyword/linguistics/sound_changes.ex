defmodule Ohmyword.Linguistics.SoundChanges do
  @moduledoc """
  Handles common sound changes in Serbian language.
  """

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
    term
    # Voiced -> Voiceless before voiceless consonants
    # ž -> š before voiceless (k, t, s, š, č, ć, p, f, h, c)
    |> String.replace("žk", "šk")
    |> String.replace("žt", "št")
    |> String.replace("žs", "šs")
    |> String.replace("žš", "šš")
    |> String.replace("žč", "šč")
    |> String.replace("žć", "šć")
    |> String.replace("žp", "šp")
    |> String.replace("žf", "šf")
    |> String.replace("žh", "šh")
    |> String.replace("žc", "šc")
    # z -> s before voiceless
    |> String.replace("zs", "ss")
    |> String.replace("zš", "sš")
    |> String.replace("zk", "sk")
    |> String.replace("zt", "st")
    |> String.replace("zp", "sp")
    |> String.replace("zč", "sč")
    |> String.replace("zć", "sć")
    |> String.replace("zf", "sf")
    |> String.replace("zh", "sh")
    |> String.replace("zc", "sc")
    # b -> p before voiceless
    |> String.replace("bt", "pt")
    |> String.replace("bk", "pk")
    |> String.replace("bs", "ps")
    |> String.replace("bš", "pš")
    |> String.replace("bč", "pč")
    |> String.replace("bć", "pć")
    |> String.replace("bp", "pp")
    |> String.replace("bf", "pf")
    |> String.replace("bh", "ph")
    |> String.replace("bc", "pc")
    # d -> t before voiceless
    |> String.replace("dt", "tt")
    |> String.replace("dk", "tk")
    |> String.replace("ds", "ts")
    |> String.replace("dš", "tš")
    |> String.replace("dč", "tč")
    |> String.replace("dć", "tć")
    |> String.replace("dp", "tp")
    |> String.replace("df", "tf")
    |> String.replace("dh", "th")
    |> String.replace("dc", "tc")
    # g -> k before voiceless
    |> String.replace("gt", "kt")
    |> String.replace("gk", "kk")
    |> String.replace("gs", "ks")
    |> String.replace("gš", "kš")
    |> String.replace("gč", "kč")
    |> String.replace("gć", "kć")
    |> String.replace("gp", "kp")
    |> String.replace("gf", "kf")
    |> String.replace("gh", "kh")
    |> String.replace("gc", "kc")
    # đ -> ć before voiceless (đ is voiced, ć is voiceless palatal)
    |> String.replace("đk", "ćk")
    |> String.replace("đt", "ćt")
    |> String.replace("đs", "ćs")
    |> String.replace("đš", "ćš")
    |> String.replace("đč", "ćč")
    |> String.replace("đć", "ćć")
    |> String.replace("đp", "ćp")
    |> String.replace("đf", "ćf")
    |> String.replace("đh", "ćh")
    |> String.replace("đc", "ćc")
  end

  def is_vowel?(char) when is_binary(char) do
    char in ~w(a e i o u)
  end
end
