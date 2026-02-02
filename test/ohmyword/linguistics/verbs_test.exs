defmodule Ohmyword.Linguistics.VerbsTest do
  use Ohmyword.DataCase, async: true

  alias Ohmyword.Linguistics.Verbs
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for verbs" do
      word = %Word{part_of_speech: :verb, verb_aspect: :imperfective}
      assert Verbs.applicable?(word)
    end

    test "returns false for nouns" do
      word = %Word{part_of_speech: :noun, gender: :masculine, animate: true}
      refute Verbs.applicable?(word)
    end

    test "returns false for adjectives" do
      word = %Word{part_of_speech: :adjective, gender: :masculine}
      refute Verbs.applicable?(word)
    end

    test "returns false for non-Word structs" do
      refute Verbs.applicable?(%{part_of_speech: :verb})
      refute Verbs.applicable?(nil)
    end
  end

  describe "generate_forms/1 - A-Verb (čitati)" do
    setup do
      word = %Word{
        term: "čitati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb"
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive is unchanged", %{forms: forms} do
      assert {"čitati", "inf"} in forms
    end

    test "present 1sg adds -m", %{forms: forms} do
      assert {"čitam", "pres_1sg"} in forms
    end

    test "present 2sg adds -š", %{forms: forms} do
      assert {"čitaš", "pres_2sg"} in forms
    end

    test "present 3sg has no ending", %{forms: forms} do
      assert {"čita", "pres_3sg"} in forms
    end

    test "present 1pl adds -mo", %{forms: forms} do
      assert {"čitamo", "pres_1pl"} in forms
    end

    test "present 2pl adds -te", %{forms: forms} do
      assert {"čitate", "pres_2pl"} in forms
    end

    test "present 3pl adds -ju", %{forms: forms} do
      assert {"čitaju", "pres_3pl"} in forms
    end

    test "imperative 2sg adds -j", %{forms: forms} do
      assert {"čitaj", "imp_2sg"} in forms
    end

    test "imperative 1pl adds -jmo", %{forms: forms} do
      assert {"čitajmo", "imp_1pl"} in forms
    end

    test "imperative 2pl adds -jte", %{forms: forms} do
      assert {"čitajte", "imp_2pl"} in forms
    end

    test "past masculine singular ends in -ao", %{forms: forms} do
      assert {"čitao", "past_m_sg"} in forms
    end

    test "past feminine singular ends in -la", %{forms: forms} do
      assert {"čitala", "past_f_sg"} in forms
    end

    test "past neuter singular ends in -lo", %{forms: forms} do
      assert {"čitalo", "past_n_sg"} in forms
    end

    test "past masculine plural ends in -li", %{forms: forms} do
      assert {"čitali", "past_m_pl"} in forms
    end

    test "past feminine plural ends in -le", %{forms: forms} do
      assert {"čitale", "past_f_pl"} in forms
    end

    test "past neuter plural ends in -la", %{forms: forms} do
      assert {"čitala", "past_n_pl"} in forms
    end
  end

  describe "generate_forms/1 - I-Verb (govoriti)" do
    setup do
      word = %Word{
        term: "govoriti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "i-verb"
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive is unchanged", %{forms: forms} do
      assert {"govoriti", "inf"} in forms
    end

    test "present 1sg adds -im", %{forms: forms} do
      assert {"govorim", "pres_1sg"} in forms
    end

    test "present 2sg adds -iš", %{forms: forms} do
      assert {"govoriš", "pres_2sg"} in forms
    end

    test "present 3sg adds -i", %{forms: forms} do
      assert {"govori", "pres_3sg"} in forms
    end

    test "present 1pl adds -imo", %{forms: forms} do
      assert {"govorimo", "pres_1pl"} in forms
    end

    test "present 2pl adds -ite", %{forms: forms} do
      assert {"govorite", "pres_2pl"} in forms
    end

    test "present 3pl adds -e", %{forms: forms} do
      assert {"govore", "pres_3pl"} in forms
    end

    test "imperative 2sg adds -i", %{forms: forms} do
      assert {"govori", "imp_2sg"} in forms
    end

    test "imperative 1pl adds -imo", %{forms: forms} do
      assert {"govorimo", "imp_1pl"} in forms
    end

    test "imperative 2pl adds -ite", %{forms: forms} do
      assert {"govorite", "imp_2pl"} in forms
    end

    test "past masculine singular ends in -io", %{forms: forms} do
      assert {"govorio", "past_m_sg"} in forms
    end

    test "past feminine singular ends in -ila", %{forms: forms} do
      assert {"govorila", "past_f_sg"} in forms
    end

    test "past neuter singular ends in -ilo", %{forms: forms} do
      assert {"govorilo", "past_n_sg"} in forms
    end

    test "past masculine plural ends in -ili", %{forms: forms} do
      assert {"govorili", "past_m_pl"} in forms
    end

    test "past feminine plural ends in -ile", %{forms: forms} do
      assert {"govorile", "past_f_pl"} in forms
    end

    test "past neuter plural ends in -ila", %{forms: forms} do
      assert {"govorila", "past_n_pl"} in forms
    end
  end

  describe "generate_forms/1 - E-Verb with present stem (pisati)" do
    setup do
      word = %Word{
        term: "pisati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "e-verb",
        grammar_metadata: %{"present_stem" => "piš"}
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive is unchanged", %{forms: forms} do
      assert {"pisati", "inf"} in forms
    end

    test "present 1sg uses present stem with -em", %{forms: forms} do
      assert {"pišem", "pres_1sg"} in forms
    end

    test "present 2sg uses present stem with -eš", %{forms: forms} do
      assert {"pišeš", "pres_2sg"} in forms
    end

    test "present 3sg uses present stem with -e", %{forms: forms} do
      assert {"piše", "pres_3sg"} in forms
    end

    test "present 1pl uses present stem with -emo", %{forms: forms} do
      assert {"pišemo", "pres_1pl"} in forms
    end

    test "present 2pl uses present stem with -ete", %{forms: forms} do
      assert {"pišete", "pres_2pl"} in forms
    end

    test "present 3pl uses present stem with -u", %{forms: forms} do
      assert {"pišu", "pres_3pl"} in forms
    end

    test "imperative 2sg uses present stem with -i", %{forms: forms} do
      assert {"piši", "imp_2sg"} in forms
    end

    test "imperative 1pl uses present stem with -imo", %{forms: forms} do
      assert {"pišimo", "imp_1pl"} in forms
    end

    test "imperative 2pl uses present stem with -ite", %{forms: forms} do
      assert {"pišite", "imp_2pl"} in forms
    end

    test "past uses infinitive stem (not present stem)", %{forms: forms} do
      assert {"pisao", "past_m_sg"} in forms
      assert {"pisala", "past_f_sg"} in forms
      assert {"pisalo", "past_n_sg"} in forms
    end
  end

  describe "generate_forms/1 - Reflexive verb (smejati se)" do
    setup do
      word = %Word{
        term: "smejati se",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "e-verb",
        reflexive: true,
        grammar_metadata: %{"present_stem" => "smej"}
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive includes se", %{forms: forms} do
      assert {"smejati se", "inf"} in forms
    end

    test "present forms include se", %{forms: forms} do
      assert {"smejem se", "pres_1sg"} in forms
      assert {"smeješ se", "pres_2sg"} in forms
      assert {"smeje se", "pres_3sg"} in forms
      assert {"smejemo se", "pres_1pl"} in forms
      assert {"smejete se", "pres_2pl"} in forms
      assert {"smeju se", "pres_3pl"} in forms
    end

    test "past forms include se", %{forms: forms} do
      assert {"smejao se", "past_m_sg"} in forms
      assert {"smejala se", "past_f_sg"} in forms
      assert {"smejalo se", "past_n_sg"} in forms
    end

    test "imperative forms include se", %{forms: forms} do
      assert {"smeji se", "imp_2sg"} in forms
      assert {"smejimo se", "imp_1pl"} in forms
      assert {"smejite se", "imp_2pl"} in forms
    end
  end

  describe "generate_forms/1 - Highly irregular verb (biti) with overrides" do
    setup do
      word = %Word{
        term: "biti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "auxiliary" => true,
          "irregular_forms" => %{
            "pres_1sg" => "sam",
            "pres_2sg" => "si",
            "pres_3sg" => "je",
            "pres_1pl" => "smo",
            "pres_2pl" => "ste",
            "pres_3pl" => "su",
            "imp_2sg" => "budi",
            "imp_1pl" => "budimo",
            "imp_2pl" => "budite"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "uses irregular present forms", %{forms: forms} do
      assert {"sam", "pres_1sg"} in forms
      assert {"si", "pres_2sg"} in forms
      assert {"je", "pres_3sg"} in forms
      assert {"smo", "pres_1pl"} in forms
      assert {"ste", "pres_2pl"} in forms
      assert {"su", "pres_3pl"} in forms
    end

    test "uses irregular imperative forms", %{forms: forms} do
      assert {"budi", "imp_2sg"} in forms
      assert {"budimo", "imp_1pl"} in forms
      assert {"budite", "imp_2pl"} in forms
    end

    test "past participle is regular (bio, bila, etc.)", %{forms: forms} do
      assert {"bio", "past_m_sg"} in forms
      assert {"bila", "past_f_sg"} in forms
      assert {"bilo", "past_n_sg"} in forms
      assert {"bili", "past_m_pl"} in forms
      assert {"bile", "past_f_pl"} in forms
      assert {"bila", "past_n_pl"} in forms
    end
  end

  describe "generate_forms/1 - Impersonal verb (trebati)" do
    setup do
      word = %Word{
        term: "trebati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb",
        grammar_metadata: %{"impersonal" => true}
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "generates all forms (design decision: generate all)", %{forms: forms} do
      assert length(forms) == 16
    end

    test "3rd person singular present is correct", %{forms: forms} do
      assert {"treba", "pres_3sg"} in forms
    end
  end

  describe "generate_forms/1 - Perfective verb (napisati)" do
    setup do
      word = %Word{
        term: "napisati",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        conjugation_class: "e-verb",
        grammar_metadata: %{"present_stem" => "napiš"}
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "conjugation follows e-verb pattern", %{forms: forms} do
      assert {"napišem", "pres_1sg"} in forms
      assert {"napišeš", "pres_2sg"} in forms
      assert {"napiše", "pres_3sg"} in forms
      assert {"napišemo", "pres_1pl"} in forms
      assert {"napišete", "pres_2pl"} in forms
      assert {"napišu", "pres_3pl"} in forms
    end

    test "past uses infinitive stem", %{forms: forms} do
      assert {"napisao", "past_m_sg"} in forms
      assert {"napisala", "past_f_sg"} in forms
    end
  end

  describe "generate_forms/1 - JE-Verb (piti)" do
    setup do
      word = %Word{
        term: "piti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "je-verb"
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "present uses -j- insertion", %{forms: forms} do
      assert {"pijem", "pres_1sg"} in forms
      assert {"piješ", "pres_2sg"} in forms
      assert {"pije", "pres_3sg"} in forms
      assert {"pijemo", "pres_1pl"} in forms
      assert {"pijete", "pres_2pl"} in forms
      assert {"piju", "pres_3pl"} in forms
    end

    test "past participle is correct", %{forms: forms} do
      assert {"pio", "past_m_sg"} in forms
      assert {"pila", "past_f_sg"} in forms
      assert {"pilo", "past_n_sg"} in forms
    end
  end

  describe "generate_forms/1 - case sensitivity" do
    test "handles uppercase input and returns lowercase output" do
      word = %Word{
        term: "ČITATI",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb"
      }

      forms = Verbs.generate_forms(word)
      assert {"čitati", "inf"} in forms
      assert {"čitam", "pres_1sg"} in forms
    end

    test "handles mixed case input" do
      word = %Word{
        term: "Govoriti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "i-verb"
      }

      forms = Verbs.generate_forms(word)
      assert {"govoriti", "inf"} in forms
      assert {"govorim", "pres_1sg"} in forms
    end
  end

  describe "generate_forms/1 - irregular form overrides" do
    test "respects partial irregular form overrides" do
      word = %Word{
        term: "moći",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "mogu",
            "pres_2sg" => "možeš",
            "pres_3sg" => "može",
            "pres_1pl" => "možemo",
            "pres_2pl" => "možete",
            "pres_3pl" => "mogu"
          }
        }
      }

      forms = Verbs.generate_forms(word)
      assert {"mogu", "pres_1sg"} in forms
      assert {"možeš", "pres_2sg"} in forms
      assert {"može", "pres_3sg"} in forms
      assert {"možemo", "pres_1pl"} in forms
      assert {"možete", "pres_2pl"} in forms
      assert {"mogu", "pres_3pl"} in forms
    end

    test "irregular overrides are case-insensitive" do
      word = %Word{
        term: "biti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "SAM"
          }
        }
      }

      forms = Verbs.generate_forms(word)
      assert {"sam", "pres_1sg"} in forms
    end
  end

  describe "generate_forms/1 - output format" do
    test "all forms are tuples of {term, form_tag}" do
      word = %Word{
        term: "čitati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb"
      }

      forms = Verbs.generate_forms(word)

      Enum.each(forms, fn form ->
        assert is_tuple(form)
        assert tuple_size(form) == 2
        {term, tag} = form
        assert is_binary(term)
        assert is_binary(tag)
      end)
    end

    test "form tags follow expected pattern" do
      word = %Word{
        term: "čitati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb"
      }

      forms = Verbs.generate_forms(word)
      tags = Enum.map(forms, fn {_, tag} -> tag end)

      # Check all expected tags are present
      expected_tags = [
        "inf",
        "pres_1sg",
        "pres_2sg",
        "pres_3sg",
        "pres_1pl",
        "pres_2pl",
        "pres_3pl",
        "past_m_sg",
        "past_f_sg",
        "past_n_sg",
        "past_m_pl",
        "past_f_pl",
        "past_n_pl",
        "imp_2sg",
        "imp_1pl",
        "imp_2pl"
      ]

      Enum.each(expected_tags, fn expected ->
        assert expected in tags, "Expected tag #{expected} not found"
      end)
    end
  end

  describe "generate_forms/1 - default conjugation class" do
    test "handles nil conjugation_class as a-verb" do
      word = %Word{
        term: "gledati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: nil
      }

      forms = Verbs.generate_forms(word)
      assert {"gledam", "pres_1sg"} in forms
      assert {"gledaju", "pres_3pl"} in forms
    end
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - -ći verb (ići)" do
    setup do
      word = %Word{
        term: "ići",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "idem",
            "pres_2sg" => "ideš",
            "pres_3sg" => "ide",
            "pres_1pl" => "idemo",
            "pres_2pl" => "idete",
            "pres_3pl" => "idu",
            "imp_2sg" => "idi",
            "imp_1pl" => "idimo",
            "imp_2pl" => "idite",
            "past_m_sg" => "išao",
            "past_f_sg" => "išla",
            "past_n_sg" => "išlo",
            "past_m_pl" => "išli",
            "past_f_pl" => "išle",
            "past_n_pl" => "išla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive is ići", %{forms: forms} do
      assert {"ići", "inf"} in forms
    end

    test "present uses irregular forms via overrides", %{forms: forms} do
      assert {"idem", "pres_1sg"} in forms
      assert {"ideš", "pres_2sg"} in forms
      assert {"ide", "pres_3sg"} in forms
      assert {"idemo", "pres_1pl"} in forms
      assert {"idete", "pres_2pl"} in forms
      assert {"idu", "pres_3pl"} in forms
    end

    test "past masculine singular is išao", %{forms: forms} do
      assert {"išao", "past_m_sg"} in forms
    end

    test "past feminine singular is išla", %{forms: forms} do
      assert {"išla", "past_f_sg"} in forms
    end

    test "imperative uses irregular forms", %{forms: forms} do
      assert {"idi", "imp_2sg"} in forms
      assert {"idimo", "imp_1pl"} in forms
      assert {"idite", "imp_2pl"} in forms
    end
  end

  describe "generate_forms/1 - -ći verb with stem changes (moći)" do
    setup do
      word = %Word{
        term: "moći",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "mogu",
            "pres_2sg" => "možeš",
            "pres_3sg" => "može",
            "pres_1pl" => "možemo",
            "pres_2pl" => "možete",
            "pres_3pl" => "mogu",
            "past_m_sg" => "mogao",
            "past_f_sg" => "mogla",
            "past_n_sg" => "moglo",
            "past_m_pl" => "mogli",
            "past_f_pl" => "mogle",
            "past_n_pl" => "mogla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is mogu (not možem)", %{forms: forms} do
      assert {"mogu", "pres_1sg"} in forms
    end

    test "present 2sg shows stem change (možeš)", %{forms: forms} do
      assert {"možeš", "pres_2sg"} in forms
    end

    test "present 3pl is mogu (same as 1sg)", %{forms: forms} do
      assert {"mogu", "pres_3pl"} in forms
    end

    test "past masculine singular is mogao", %{forms: forms} do
      assert {"mogao", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - prefixed -ći verb (doći)" do
    setup do
      word = %Word{
        term: "doći",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "dođem",
            "pres_2sg" => "dođeš",
            "pres_3sg" => "dođe",
            "pres_1pl" => "dođemo",
            "pres_2pl" => "dođete",
            "pres_3pl" => "dođu",
            "imp_2sg" => "dođi",
            "imp_1pl" => "dođimo",
            "imp_2pl" => "dođite",
            "past_m_sg" => "došao",
            "past_f_sg" => "došla",
            "past_n_sg" => "došlo",
            "past_m_pl" => "došli",
            "past_f_pl" => "došle",
            "past_n_pl" => "došla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is dođem", %{forms: forms} do
      assert {"dođem", "pres_1sg"} in forms
    end

    test "present 3pl is dođu", %{forms: forms} do
      assert {"dođu", "pres_3pl"} in forms
    end

    test "past masculine singular is došao", %{forms: forms} do
      assert {"došao", "past_m_sg"} in forms
    end

    test "past feminine singular is došla", %{forms: forms} do
      assert {"došla", "past_f_sg"} in forms
    end
  end

  describe "generate_forms/1 - irregular verb (hteti)" do
    setup do
      word = %Word{
        term: "hteti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "hoću",
            "pres_2sg" => "hoćeš",
            "pres_3sg" => "hoće",
            "pres_1pl" => "hoćemo",
            "pres_2pl" => "hoćete",
            "pres_3pl" => "hoće",
            "imp_2sg" => "htej",
            "imp_1pl" => "htejmo",
            "imp_2pl" => "htejte",
            "past_m_sg" => "hteo",
            "past_f_sg" => "htela",
            "past_n_sg" => "htelo",
            "past_m_pl" => "hteli",
            "past_f_pl" => "htele",
            "past_n_pl" => "htela"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is hoću", %{forms: forms} do
      assert {"hoću", "pres_1sg"} in forms
    end

    test "present 2sg is hoćeš", %{forms: forms} do
      assert {"hoćeš", "pres_2sg"} in forms
    end

    test "past masculine singular is hteo", %{forms: forms} do
      assert {"hteo", "past_m_sg"} in forms
    end

    test "past feminine singular is htela", %{forms: forms} do
      assert {"htela", "past_f_sg"} in forms
    end
  end

  describe "generate_forms/1 - reflexive verb (bojati se)" do
    setup do
      word = %Word{
        term: "bojati se",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb",
        reflexive: true
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "returns 16 forms", %{forms: forms} do
      assert length(forms) == 16
    end

    test "infinitive includes se", %{forms: forms} do
      assert {"bojati se", "inf"} in forms
    end

    test "all present forms end with ' se'", %{forms: forms} do
      assert {"bojam se", "pres_1sg"} in forms
      assert {"bojaš se", "pres_2sg"} in forms
      assert {"boja se", "pres_3sg"} in forms
      assert {"bojamo se", "pres_1pl"} in forms
      assert {"bojate se", "pres_2pl"} in forms
      assert {"bojaju se", "pres_3pl"} in forms
    end

    test "all past forms end with ' se'", %{forms: forms} do
      assert {"bojao se", "past_m_sg"} in forms
      assert {"bojala se", "past_f_sg"} in forms
      assert {"bojalo se", "past_n_sg"} in forms
    end

    test "all imperative forms end with ' se'", %{forms: forms} do
      assert {"bojaj se", "imp_2sg"} in forms
      assert {"bojajmo se", "imp_1pl"} in forms
      assert {"bojajte se", "imp_2pl"} in forms
    end
  end

  # ============================================================================
  # ADDITIONAL EDGE CASES
  # ============================================================================

  describe "generate_forms/1 - irregular present stem (jesti)" do
    setup do
      word = %Word{
        term: "jesti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "e-verb",
        grammar_metadata: %{
          "present_stem" => "jed",
          "irregular_forms" => %{
            "past_m_sg" => "jeo",
            "past_f_sg" => "jela",
            "past_n_sg" => "jelo",
            "past_m_pl" => "jeli",
            "past_f_pl" => "jele",
            "past_n_pl" => "jela"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is jedem", %{forms: forms} do
      assert {"jedem", "pres_1sg"} in forms
    end

    test "present 3pl is jedu", %{forms: forms} do
      assert {"jedu", "pres_3pl"} in forms
    end

    test "past masculine singular is jeo", %{forms: forms} do
      assert {"jeo", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - short a-verb (dati)" do
    setup do
      word = %Word{
        term: "dati",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "dam",
            "pres_2sg" => "daš",
            "pres_3sg" => "da",
            "pres_1pl" => "damo",
            "pres_2pl" => "date",
            "pres_3pl" => "daju",
            "imp_2sg" => "daj",
            "imp_1pl" => "dajmo",
            "imp_2pl" => "dajte",
            "past_m_sg" => "dao",
            "past_f_sg" => "dala",
            "past_n_sg" => "dalo",
            "past_m_pl" => "dali",
            "past_f_pl" => "dale",
            "past_n_pl" => "dala"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is dam", %{forms: forms} do
      assert {"dam", "pres_1sg"} in forms
    end

    test "past masculine singular is dao", %{forms: forms} do
      assert {"dao", "past_m_sg"} in forms
    end

    test "imperative 2sg is daj", %{forms: forms} do
      assert {"daj", "imp_2sg"} in forms
    end
  end

  describe "generate_forms/1 - a-verb present (znati)" do
    setup do
      word = %Word{
        term: "znati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "a-verb"
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is znam", %{forms: forms} do
      assert {"znam", "pres_1sg"} in forms
    end

    test "present 3pl is znaju", %{forms: forms} do
      assert {"znaju", "pres_3pl"} in forms
    end

    test "past masculine singular is znao", %{forms: forms} do
      assert {"znao", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - irregular present (spati → spavam)" do
    setup do
      word = %Word{
        term: "spati",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "spavam",
            "pres_2sg" => "spavaš",
            "pres_3sg" => "spava",
            "pres_1pl" => "spavamo",
            "pres_2pl" => "spavate",
            "pres_3pl" => "spavaju",
            "imp_2sg" => "spavaj",
            "imp_1pl" => "spavajmo",
            "imp_2pl" => "spavajte",
            "past_m_sg" => "spavao",
            "past_f_sg" => "spavala",
            "past_n_sg" => "spavalo",
            "past_m_pl" => "spavali",
            "past_f_pl" => "spavale",
            "past_n_pl" => "spavala"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is spavam", %{forms: forms} do
      assert {"spavam", "pres_1sg"} in forms
    end

    test "past masculine singular is spavao", %{forms: forms} do
      assert {"spavao", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - e-verb perfective (uzeti)" do
    setup do
      word = %Word{
        term: "uzeti",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        conjugation_class: "e-verb",
        grammar_metadata: %{
          "present_stem" => "uzm",
          "irregular_forms" => %{
            "past_m_sg" => "uzeo",
            "past_f_sg" => "uzela",
            "past_n_sg" => "uzelo",
            "past_m_pl" => "uzeli",
            "past_f_pl" => "uzele",
            "past_n_pl" => "uzela"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is uzmem", %{forms: forms} do
      assert {"uzmem", "pres_1sg"} in forms
    end

    test "past masculine singular is uzeo", %{forms: forms} do
      assert {"uzeo", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - i-verb with j (kriti)" do
    setup do
      word = %Word{
        term: "kriti",
        part_of_speech: :verb,
        verb_aspect: :imperfective,
        conjugation_class: "je-verb"
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is krijem", %{forms: forms} do
      assert {"krijem", "pres_1sg"} in forms
    end

    test "present 3pl is kriju", %{forms: forms} do
      assert {"kriju", "pres_3pl"} in forms
    end

    test "past masculine singular is krio", %{forms: forms} do
      assert {"krio", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - prefixed -ći verb (naći)" do
    setup do
      word = %Word{
        term: "naći",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "nađem",
            "pres_2sg" => "nađeš",
            "pres_3sg" => "nađe",
            "pres_1pl" => "nađemo",
            "pres_2pl" => "nađete",
            "pres_3pl" => "nađu",
            "imp_2sg" => "nađi",
            "imp_1pl" => "nađimo",
            "imp_2pl" => "nađite",
            "past_m_sg" => "našao",
            "past_f_sg" => "našla",
            "past_n_sg" => "našlo",
            "past_m_pl" => "našli",
            "past_f_pl" => "našle",
            "past_n_pl" => "našla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is nađem", %{forms: forms} do
      assert {"nađem", "pres_1sg"} in forms
    end

    test "past masculine singular is našao", %{forms: forms} do
      assert {"našao", "past_m_sg"} in forms
    end

    test "imperative 2sg is nađi", %{forms: forms} do
      assert {"nađi", "imp_2sg"} in forms
    end
  end

  describe "generate_forms/1 - prefixed -ći verb (otići)" do
    setup do
      word = %Word{
        term: "otići",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "odem",
            "pres_2sg" => "odeš",
            "pres_3sg" => "ode",
            "pres_1pl" => "odemo",
            "pres_2pl" => "odete",
            "pres_3pl" => "odu",
            "imp_2sg" => "odi",
            "imp_1pl" => "odimo",
            "imp_2pl" => "odite",
            "past_m_sg" => "otišao",
            "past_f_sg" => "otišla",
            "past_n_sg" => "otišlo",
            "past_m_pl" => "otišli",
            "past_f_pl" => "otišle",
            "past_n_pl" => "otišla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is odem", %{forms: forms} do
      assert {"odem", "pres_1sg"} in forms
    end

    test "past masculine singular is otišao", %{forms: forms} do
      assert {"otišao", "past_m_sg"} in forms
    end
  end

  describe "generate_forms/1 - irregular -ći verb (reći)" do
    setup do
      word = %Word{
        term: "reći",
        part_of_speech: :verb,
        verb_aspect: :perfective,
        grammar_metadata: %{
          "irregular_forms" => %{
            "pres_1sg" => "reknem",
            "pres_2sg" => "rekneš",
            "pres_3sg" => "rekne",
            "pres_1pl" => "reknemo",
            "pres_2pl" => "reknete",
            "pres_3pl" => "reknu",
            "imp_2sg" => "recni",
            "imp_1pl" => "recnimo",
            "imp_2pl" => "recnite",
            "past_m_sg" => "rekao",
            "past_f_sg" => "rekla",
            "past_n_sg" => "reklo",
            "past_m_pl" => "rekli",
            "past_f_pl" => "rekle",
            "past_n_pl" => "rekla"
          }
        }
      }

      {:ok, word: word, forms: Verbs.generate_forms(word)}
    end

    test "present 1sg is reknem", %{forms: forms} do
      assert {"reknem", "pres_1sg"} in forms
    end

    test "past masculine singular is rekao", %{forms: forms} do
      assert {"rekao", "past_m_sg"} in forms
    end

    test "past feminine singular is rekla", %{forms: forms} do
      assert {"rekla", "past_f_sg"} in forms
    end
  end

end
