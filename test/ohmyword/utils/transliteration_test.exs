defmodule Ohmyword.Utils.TransliterationTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Utils.Transliteration

  describe "to_cyrillic/1" do
    test "converts basic Latin letters" do
      assert Transliteration.to_cyrillic("a") == "а"
      assert Transliteration.to_cyrillic("b") == "б"
      assert Transliteration.to_cyrillic("c") == "ц"
      assert Transliteration.to_cyrillic("d") == "д"
      assert Transliteration.to_cyrillic("e") == "е"
      assert Transliteration.to_cyrillic("f") == "ф"
      assert Transliteration.to_cyrillic("g") == "г"
      assert Transliteration.to_cyrillic("h") == "х"
      assert Transliteration.to_cyrillic("i") == "и"
      assert Transliteration.to_cyrillic("j") == "ј"
      assert Transliteration.to_cyrillic("k") == "к"
      assert Transliteration.to_cyrillic("l") == "л"
      assert Transliteration.to_cyrillic("m") == "м"
      assert Transliteration.to_cyrillic("n") == "н"
      assert Transliteration.to_cyrillic("o") == "о"
      assert Transliteration.to_cyrillic("p") == "п"
      assert Transliteration.to_cyrillic("r") == "р"
      assert Transliteration.to_cyrillic("s") == "с"
      assert Transliteration.to_cyrillic("t") == "т"
      assert Transliteration.to_cyrillic("u") == "у"
      assert Transliteration.to_cyrillic("v") == "в"
      assert Transliteration.to_cyrillic("z") == "з"
    end

    test "converts Serbian diacritics" do
      assert Transliteration.to_cyrillic("č") == "ч"
      assert Transliteration.to_cyrillic("ć") == "ћ"
      assert Transliteration.to_cyrillic("š") == "ш"
      assert Transliteration.to_cyrillic("ž") == "ж"
      assert Transliteration.to_cyrillic("đ") == "ђ"
    end

    test "converts digraphs correctly (must process before single letters)" do
      # These are critical - digraphs must be matched before individual letters
      assert Transliteration.to_cyrillic("lj") == "љ"
      assert Transliteration.to_cyrillic("nj") == "њ"
      assert Transliteration.to_cyrillic("dž") == "џ"
    end

    test "converts words with digraphs" do
      assert Transliteration.to_cyrillic("ljubav") == "љубав"
      assert Transliteration.to_cyrillic("knjiga") == "књига"
      assert Transliteration.to_cyrillic("džem") == "џем"
    end

    test "preserves uppercase letters" do
      assert Transliteration.to_cyrillic("A") == "А"
      assert Transliteration.to_cyrillic("B") == "Б"
      assert Transliteration.to_cyrillic("Č") == "Ч"
      assert Transliteration.to_cyrillic("Š") == "Ш"
      assert Transliteration.to_cyrillic("Đ") == "Ђ"
    end

    test "converts uppercase digraphs" do
      # Title case (first letter uppercase)
      assert Transliteration.to_cyrillic("Lj") == "Љ"
      assert Transliteration.to_cyrillic("Nj") == "Њ"
      assert Transliteration.to_cyrillic("Dž") == "Џ"

      # All caps
      assert Transliteration.to_cyrillic("LJ") == "Љ"
      assert Transliteration.to_cyrillic("NJ") == "Њ"
      assert Transliteration.to_cyrillic("DŽ") == "Џ"
    end

    test "converts phrases and sentences" do
      assert Transliteration.to_cyrillic("Dobro jutro") == "Добро јутро"
      assert Transliteration.to_cyrillic("Ja sam učenik") == "Ја сам ученик"
    end

    test "converts all caps words" do
      assert Transliteration.to_cyrillic("LJUBAV") == "ЉУБАВ"
      assert Transliteration.to_cyrillic("DOBRO") == "ДОБРО"
    end

    test "passes through non-Serbian characters unchanged" do
      assert Transliteration.to_cyrillic("123") == "123"
      assert Transliteration.to_cyrillic("!@#") == "!@#"
      assert Transliteration.to_cyrillic("hello 123!") == "хелло 123!"
    end

    test "handles empty string" do
      assert Transliteration.to_cyrillic("") == ""
    end

    test "handles mixed content" do
      assert Transliteration.to_cyrillic("Cena: 100 dinara") == "Цена: 100 динара"
    end
  end

  describe "to_latin/1" do
    test "converts basic Cyrillic letters" do
      assert Transliteration.to_latin("а") == "a"
      assert Transliteration.to_latin("б") == "b"
      assert Transliteration.to_latin("ц") == "c"
      assert Transliteration.to_latin("д") == "d"
      assert Transliteration.to_latin("е") == "e"
      assert Transliteration.to_latin("ф") == "f"
      assert Transliteration.to_latin("г") == "g"
      assert Transliteration.to_latin("х") == "h"
      assert Transliteration.to_latin("и") == "i"
      assert Transliteration.to_latin("ј") == "j"
      assert Transliteration.to_latin("к") == "k"
      assert Transliteration.to_latin("л") == "l"
      assert Transliteration.to_latin("м") == "m"
      assert Transliteration.to_latin("н") == "n"
      assert Transliteration.to_latin("о") == "o"
      assert Transliteration.to_latin("п") == "p"
      assert Transliteration.to_latin("р") == "r"
      assert Transliteration.to_latin("с") == "s"
      assert Transliteration.to_latin("т") == "t"
      assert Transliteration.to_latin("у") == "u"
      assert Transliteration.to_latin("в") == "v"
      assert Transliteration.to_latin("з") == "z"
    end

    test "converts Serbian Cyrillic special letters" do
      assert Transliteration.to_latin("ч") == "č"
      assert Transliteration.to_latin("ћ") == "ć"
      assert Transliteration.to_latin("ш") == "š"
      assert Transliteration.to_latin("ж") == "ž"
      assert Transliteration.to_latin("ђ") == "đ"
    end

    test "converts digraph Cyrillic letters" do
      assert Transliteration.to_latin("љ") == "lj"
      assert Transliteration.to_latin("њ") == "nj"
      assert Transliteration.to_latin("џ") == "dž"
    end

    test "converts words with digraph letters" do
      assert Transliteration.to_latin("љубав") == "ljubav"
      assert Transliteration.to_latin("књига") == "knjiga"
      assert Transliteration.to_latin("џем") == "džem"
    end

    test "preserves uppercase letters" do
      assert Transliteration.to_latin("А") == "A"
      assert Transliteration.to_latin("Б") == "B"
      assert Transliteration.to_latin("Ч") == "Č"
      assert Transliteration.to_latin("Ш") == "Š"
      assert Transliteration.to_latin("Ђ") == "Đ"
    end

    test "converts uppercase digraph letters" do
      assert Transliteration.to_latin("Љ") == "Lj"
      assert Transliteration.to_latin("Њ") == "Nj"
      assert Transliteration.to_latin("Џ") == "Dž"
    end

    test "converts phrases and sentences" do
      assert Transliteration.to_latin("Добро јутро") == "Dobro jutro"
      assert Transliteration.to_latin("Ја сам ученик") == "Ja sam učenik"
    end

    test "handles empty string" do
      assert Transliteration.to_latin("") == ""
    end

    test "passes through non-Cyrillic characters unchanged" do
      assert Transliteration.to_latin("123") == "123"
      assert Transliteration.to_latin("!@#") == "!@#"
    end
  end

  describe "round-trip conversion" do
    test "Latin -> Cyrillic -> Latin preserves text" do
      originals = [
        "pas",
        "ljubav",
        "knjiga",
        "džem",
        "Dobro jutro",
        "Ja sam učenik",
        "čekati",
        "šetati"
      ]

      for original <- originals do
        assert original
               |> Transliteration.to_cyrillic()
               |> Transliteration.to_latin() == original
      end
    end

    test "Cyrillic -> Latin -> Cyrillic preserves text" do
      originals = [
        "пас",
        "љубав",
        "књига",
        "џем",
        "Добро јутро",
        "Ја сам ученик",
        "чекати",
        "шетати"
      ]

      for original <- originals do
        assert original
               |> Transliteration.to_latin()
               |> Transliteration.to_cyrillic() == original
      end
    end
  end
end
