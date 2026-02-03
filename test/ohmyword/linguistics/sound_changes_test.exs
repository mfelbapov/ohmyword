defmodule Ohmyword.Linguistics.SoundChangesTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.SoundChanges

  # ============================================================================
  # PALATALIZATION TESTS
  # ============================================================================

  describe "palatalize/1" do
    test "k -> č" do
      assert SoundChanges.palatalize("vojnik") == "vojnič"
    end

    test "g -> ž" do
      assert SoundChanges.palatalize("drug") == "druž"
    end

    test "h -> š" do
      assert SoundChanges.palatalize("duh") == "duš"
    end

    test "c -> č" do
      assert SoundChanges.palatalize("otac") == "otač"
    end

    test "z -> ž" do
      assert SoundChanges.palatalize("knez") == "knež"
    end

    test "returns unchanged if no palatalizable consonant" do
      assert SoundChanges.palatalize("brat") == "brat"
      assert SoundChanges.palatalize("sin") == "sin"
      assert SoundChanges.palatalize("dom") == "dom"
    end

    test "handles single character" do
      assert SoundChanges.palatalize("k") == "č"
      assert SoundChanges.palatalize("g") == "ž"
    end

    test "handles already palatalized consonant" do
      assert SoundChanges.palatalize("nož") == "nož"
      assert SoundChanges.palatalize("ključ") == "ključ"
    end
  end

  # ============================================================================
  # SIBILARIZATION TESTS
  # ============================================================================

  describe "sibilarize/1" do
    test "k -> c" do
      # sibilarize only transforms the last character
      assert SoundChanges.sibilarize("ruk") == "ruc"
      assert SoundChanges.sibilarize("devojk") == "devojc"
    end

    test "g -> z" do
      assert SoundChanges.sibilarize("nog") == "noz"
      assert SoundChanges.sibilarize("slog") == "sloz"
    end

    test "h -> s" do
      assert SoundChanges.sibilarize("muh") == "mus"
      assert SoundChanges.sibilarize("snah") == "snas"
    end

    test "returns unchanged if no sibilarizable consonant" do
      # Last character is not k, g, or h
      assert SoundChanges.sibilarize("žena") == "žena"
      assert SoundChanges.sibilarize("kuć") == "kuć"
    end

    test "handles single character" do
      assert SoundChanges.sibilarize("k") == "c"
      assert SoundChanges.sibilarize("g") == "z"
      assert SoundChanges.sibilarize("h") == "s"
    end
  end

  # ============================================================================
  # IOTATION TESTS
  # ============================================================================

  describe "iotate/1" do
    test "s -> š (e.g., pisati -> pišem)" do
      assert SoundChanges.iotate("pis") == "piš"
    end

    test "z -> ž (e.g., brz -> brži)" do
      assert SoundChanges.iotate("brz") == "brž"
    end

    test "t -> ć (e.g., smrt -> smrć)" do
      assert SoundChanges.iotate("smrt") == "smrć"
    end

    test "d -> đ (e.g., glod -> glođ)" do
      assert SoundChanges.iotate("glod") == "glođ"
    end

    test "k -> č (e.g., jak -> jač)" do
      assert SoundChanges.iotate("jak") == "jač"
    end

    test "g -> ž (e.g., blag -> blaž)" do
      assert SoundChanges.iotate("blag") == "blaž"
    end

    test "h -> š (e.g., tih -> tiš)" do
      assert SoundChanges.iotate("tih") == "tiš"
    end

    test "l -> lj (e.g., vesel -> veselj)" do
      assert SoundChanges.iotate("vesel") == "veselj"
    end

    test "n -> nj (e.g., crn -> crnj)" do
      assert SoundChanges.iotate("crn") == "crnj"
    end

    # Labials: p, b, m, v -> plj, blj, mlj, vlj
    test "p -> plj (e.g., kap -> kaplj)" do
      assert SoundChanges.iotate("kap") == "kaplj"
    end

    test "b -> blj (e.g., grub -> grublj)" do
      assert SoundChanges.iotate("grub") == "grublj"
    end

    test "m -> mlj (e.g., lom -> lomlj)" do
      assert SoundChanges.iotate("lom") == "lomlj"
    end

    test "v -> vlj (e.g., lov -> lovlj)" do
      assert SoundChanges.iotate("lov") == "lovlj"
    end

    test "returns unchanged for non-iotatable consonants" do
      assert SoundChanges.iotate("car") == "car"
      assert SoundChanges.iotate("miš") == "miš"
    end

    test "handles single character" do
      assert SoundChanges.iotate("s") == "š"
      assert SoundChanges.iotate("t") == "ć"
    end
  end

  # ============================================================================
  # L-O ALTERNATION TESTS
  # ============================================================================

  describe "resolve_l_o_alternation/1" do
    test "-eo -> -el (e.g., beo -> bel)" do
      assert SoundChanges.resolve_l_o_alternation("beo") == "bel"
    end

    test "-ao -> -al (e.g., posao -> posal)" do
      assert SoundChanges.resolve_l_o_alternation("posao") == "posal"
    end

    test "-ao -> -al (e.g., anđeo -> anđel)" do
      # anđeo ends in -eo
      assert SoundChanges.resolve_l_o_alternation("anđeo") == "anđel"
    end

    test "returns unchanged if not -eo or -ao ending" do
      assert SoundChanges.resolve_l_o_alternation("novo") == "novo"
      assert SoundChanges.resolve_l_o_alternation("selo") == "selo"
      assert SoundChanges.resolve_l_o_alternation("auto") == "auto"
    end

    test "returns unchanged if doesn't end in -o" do
      assert SoundChanges.resolve_l_o_alternation("bel") == "bel"
      assert SoundChanges.resolve_l_o_alternation("mali") == "mali"
    end

    test "handles short words" do
      # Short -eo word
      assert SoundChanges.resolve_l_o_alternation("leo") == "lel"
    end
  end

  # ============================================================================
  # VOICE ASSIMILATION TESTS
  # ============================================================================

  describe "assimilate_voice/1" do
    # ž -> š before voiceless
    test "žk -> šk (e.g., težak stem težk -> tešk)" do
      assert SoundChanges.assimilate_voice("težk") == "tešk"
    end

    test "žt -> št" do
      assert SoundChanges.assimilate_voice("mažta") == "mašta"
    end

    test "žs -> šs" do
      assert SoundChanges.assimilate_voice("nožs") == "nošs"
    end

    test "žš -> šš" do
      assert SoundChanges.assimilate_voice("žš") == "šš"
    end

    test "žč -> šč" do
      assert SoundChanges.assimilate_voice("žč") == "šč"
    end

    test "žć -> šć" do
      assert SoundChanges.assimilate_voice("žć") == "šć"
    end

    test "žp -> šp" do
      assert SoundChanges.assimilate_voice("žp") == "šp"
    end

    # z -> s before voiceless
    test "zs -> ss (e.g., razstati -> rastati)" do
      assert SoundChanges.assimilate_voice("razs") == "rass"
    end

    test "zš -> sš" do
      assert SoundChanges.assimilate_voice("izšao") == "isšao"
    end

    test "zk -> sk" do
      assert SoundChanges.assimilate_voice("izk") == "isk"
    end

    test "zt -> st" do
      assert SoundChanges.assimilate_voice("izt") == "ist"
    end

    test "zp -> sp" do
      assert SoundChanges.assimilate_voice("izp") == "isp"
    end

    test "zč -> sč" do
      assert SoundChanges.assimilate_voice("bezčastan") == "besčastan"
    end

    test "zć -> sć" do
      assert SoundChanges.assimilate_voice("izćutati") == "isćutati"
    end

    test "zh -> sh" do
      assert SoundChanges.assimilate_voice("izhoditi") == "ishoditi"
    end

    # b -> p before voiceless
    test "bt -> pt" do
      assert SoundChanges.assimilate_voice("obt") == "opt"
    end

    test "bk -> pk" do
      assert SoundChanges.assimilate_voice("obk") == "opk"
    end

    test "bs -> ps" do
      assert SoundChanges.assimilate_voice("obs") == "ops"
    end

    test "bš -> pš" do
      assert SoundChanges.assimilate_voice("obš") == "opš"
    end

    test "bč -> pč" do
      assert SoundChanges.assimilate_voice("obč") == "opč"
    end

    # d -> t before voiceless
    test "dt -> tt" do
      assert SoundChanges.assimilate_voice("odt") == "ott"
    end

    test "dk -> tk" do
      assert SoundChanges.assimilate_voice("odk") == "otk"
    end

    test "ds -> ts" do
      assert SoundChanges.assimilate_voice("ods") == "ots"
    end

    test "dš -> tš" do
      assert SoundChanges.assimilate_voice("odš") == "otš"
    end

    test "dč -> tč" do
      assert SoundChanges.assimilate_voice("odč") == "otč"
    end

    test "dć -> tć" do
      assert SoundChanges.assimilate_voice("odć") == "otć"
    end

    # g -> k before voiceless
    test "gt -> kt" do
      assert SoundChanges.assimilate_voice("ogt") == "okt"
    end

    test "gk -> kk" do
      assert SoundChanges.assimilate_voice("ogk") == "okk"
    end

    test "gs -> ks" do
      assert SoundChanges.assimilate_voice("ogs") == "oks"
    end

    test "gš -> kš" do
      assert SoundChanges.assimilate_voice("ogš") == "okš"
    end

    test "gč -> kč" do
      assert SoundChanges.assimilate_voice("ogč") == "okč"
    end

    # đ -> ć before voiceless
    test "đk -> ćk" do
      assert SoundChanges.assimilate_voice("đk") == "ćk"
    end

    test "đt -> ćt" do
      assert SoundChanges.assimilate_voice("đt") == "ćt"
    end

    test "đs -> ćs" do
      assert SoundChanges.assimilate_voice("đs") == "ćs"
    end

    # Multiple assimilations in one word
    test "handles multiple assimilations" do
      # Both z and ž assimilate
      assert SoundChanges.assimilate_voice("razžk") == "rasšk"
    end

    # No change needed
    test "returns unchanged when no assimilation needed" do
      assert SoundChanges.assimilate_voice("nova") == "nova"
      assert SoundChanges.assimilate_voice("kuća") == "kuća"
      assert SoundChanges.assimilate_voice("selo") == "selo"
    end
  end

  # ============================================================================
  # IS_VOWEL? TESTS
  # ============================================================================

  describe "is_vowel?/1" do
    test "returns true for vowels" do
      assert SoundChanges.is_vowel?("a") == true
      assert SoundChanges.is_vowel?("e") == true
      assert SoundChanges.is_vowel?("i") == true
      assert SoundChanges.is_vowel?("o") == true
      assert SoundChanges.is_vowel?("u") == true
    end

    test "returns false for consonants" do
      assert SoundChanges.is_vowel?("b") == false
      assert SoundChanges.is_vowel?("c") == false
      assert SoundChanges.is_vowel?("č") == false
      assert SoundChanges.is_vowel?("k") == false
      assert SoundChanges.is_vowel?("s") == false
    end

    test "returns false for empty string" do
      assert SoundChanges.is_vowel?("") == false
    end
  end

  # ============================================================================
  # INTEGRATION / EDGE CASE TESTS
  # ============================================================================

  describe "integration tests" do
    test "težak adjective voice assimilation: težk -> tešk" do
      # This is the key case from the plan
      # When fleeting_a is removed from "težak", we get "težk"
      # Voice assimilation should give us "tešk"
      # Then adding feminine -a gives "teška"
      stem = "težk"
      assimilated = SoundChanges.assimilate_voice(stem)
      assert assimilated == "tešk"
      assert assimilated <> "a" == "teška"
    end

    test "beo adjective L-O alternation: beo -> bel" do
      # The adjective "beo" has L-O alternation
      # The stem should be "bel" for adding endings
      resolved = SoundChanges.resolve_l_o_alternation("beo")
      assert resolved == "bel"
      assert resolved <> "i" == "beli"
    end

    test "devojka noun sibilarization for dative: devojk -> devojc" do
      # The noun "devojka" has sibilarization in dative/locative
      stem = "devojk"
      sibilarized = SoundChanges.sibilarize(stem)
      assert sibilarized == "devojc"
      assert sibilarized <> "i" == "devojci"
    end

    test "pisati verb iotation: pis -> piš" do
      # The verb "pisati" has iotation in present tense
      stem = "pis"
      iotated = SoundChanges.iotate(stem)
      assert iotated == "piš"
      assert iotated <> "em" == "pišem"
    end

    test "vocative palatalization: vojnik -> vojniče" do
      stem = "vojnik"
      palatalized = SoundChanges.palatalize(stem)
      assert palatalized == "vojnič"
      assert palatalized <> "e" == "vojniče"
    end
  end

  # ============================================================================
  # EDGE CASES FOR SERBIAN DIACRITICS
  # ============================================================================

  describe "Serbian diacritics handling" do
    test "palatalize handles č correctly" do
      # č should not change (already palatalized)
      assert SoundChanges.palatalize("ključ") == "ključ"
    end

    test "palatalize handles ć correctly" do
      # ć should not change
      assert SoundChanges.palatalize("noć") == "noć"
    end

    test "palatalize handles đ correctly" do
      # đ should not change
      assert SoundChanges.palatalize("vođ") == "vođ"
    end

    test "palatalize handles š correctly" do
      # š should not change
      assert SoundChanges.palatalize("miš") == "miš"
    end

    test "palatalize handles ž correctly" do
      # ž should not change
      assert SoundChanges.palatalize("muž") == "muž"
    end

    test "iotate preserves diacritics in stem" do
      # The stem has diacritics that should be preserved
      assert SoundChanges.iotate("držat") == "držać"
    end

    test "voice assimilation with đ" do
      # đ before voiceless should become ć
      assert SoundChanges.assimilate_voice("vođk") == "voćk"
    end
  end
end
