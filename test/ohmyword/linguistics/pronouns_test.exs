defmodule Ohmyword.Linguistics.PronounsTest do
  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Pronouns
  alias Ohmyword.Vocabulary.Word

  describe "applicable?/1" do
    test "returns true for pronouns" do
      word = %Word{term: "ja", part_of_speech: :pronoun, gender: :masculine}
      assert Pronouns.applicable?(word)
    end

    test "returns false for nouns" do
      word = %Word{term: "kuća", part_of_speech: :noun, gender: :feminine}
      refute Pronouns.applicable?(word)
    end

    test "returns false for verbs" do
      word = %Word{term: "raditi", part_of_speech: :verb}
      refute Pronouns.applicable?(word)
    end

    test "returns false for adjectives" do
      word = %Word{term: "dobar", part_of_speech: :adjective, gender: :masculine}
      refute Pronouns.applicable?(word)
    end
  end

  describe "generate_forms/1 - personal pronoun ja (1st person singular)" do
    setup do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 1,
          "number" => "singular"
        }
      }

      forms = Pronouns.generate_forms(word)

      {:ok,
       word: word, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates correct number of forms", %{forms: forms} do
      # nom, gen, gen_clitic, dat, dat_clitic, acc, acc_clitic, ins, ins_alt, loc
      assert length(forms) == 10
    end

    test "nominative is ja", %{forms_map: fm} do
      assert fm["nom"] == "ja"
    end

    test "genitive is mene", %{forms_map: fm} do
      assert fm["gen"] == "mene"
    end

    test "genitive clitic is me", %{forms_map: fm} do
      assert fm["gen_clitic"] == "me"
    end

    test "dative is meni", %{forms_map: fm} do
      assert fm["dat"] == "meni"
    end

    test "dative clitic is mi", %{forms_map: fm} do
      assert fm["dat_clitic"] == "mi"
    end

    test "accusative is mene", %{forms_map: fm} do
      assert fm["acc"] == "mene"
    end

    test "accusative clitic is me", %{forms_map: fm} do
      assert fm["acc_clitic"] == "me"
    end

    test "instrumental is mnom", %{forms_map: fm} do
      assert fm["ins"] == "mnom"
    end

    test "instrumental alternate is mnome", %{forms_map: fm} do
      assert fm["ins_alt"] == "mnome"
    end

    test "locative is meni", %{forms_map: fm} do
      assert fm["loc"] == "meni"
    end
  end

  describe "generate_forms/1 - personal pronoun ti (2nd person singular)" do
    setup do
      word = %Word{
        term: "ti",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 2,
          "number" => "singular"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is ti", %{forms_map: fm} do
      assert fm["nom"] == "ti"
    end

    test "genitive is tebe", %{forms_map: fm} do
      assert fm["gen"] == "tebe"
    end

    test "genitive clitic is te", %{forms_map: fm} do
      assert fm["gen_clitic"] == "te"
    end

    test "dative is tebi", %{forms_map: fm} do
      assert fm["dat"] == "tebi"
    end

    test "dative clitic is ti", %{forms_map: fm} do
      assert fm["dat_clitic"] == "ti"
    end

    test "accusative is tebe", %{forms_map: fm} do
      assert fm["acc"] == "tebe"
    end

    test "instrumental is tobom", %{forms_map: fm} do
      assert fm["ins"] == "tobom"
    end

    test "vocative is ti", %{forms_map: fm} do
      assert fm["voc"] == "ti"
    end
  end

  describe "generate_forms/1 - personal pronoun on (3rd person singular masculine)" do
    setup do
      word = %Word{
        term: "on",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 3,
          "number" => "singular"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is on", %{forms_map: fm} do
      assert fm["nom"] == "on"
    end

    test "genitive is njega", %{forms_map: fm} do
      assert fm["gen"] == "njega"
    end

    test "genitive clitic is ga", %{forms_map: fm} do
      assert fm["gen_clitic"] == "ga"
    end

    test "dative is njemu", %{forms_map: fm} do
      assert fm["dat"] == "njemu"
    end

    test "dative clitic is mu", %{forms_map: fm} do
      assert fm["dat_clitic"] == "mu"
    end

    test "instrumental is njim", %{forms_map: fm} do
      assert fm["ins"] == "njim"
    end

    test "instrumental alternate is njime", %{forms_map: fm} do
      assert fm["ins_alt"] == "njime"
    end
  end

  describe "generate_forms/1 - personal pronoun ona (3rd person singular feminine)" do
    setup do
      word = %Word{
        term: "ona",
        part_of_speech: :pronoun,
        gender: :feminine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 3,
          "number" => "singular"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is ona", %{forms_map: fm} do
      assert fm["nom"] == "ona"
    end

    test "genitive is nje", %{forms_map: fm} do
      assert fm["gen"] == "nje"
    end

    test "genitive clitic is je", %{forms_map: fm} do
      assert fm["gen_clitic"] == "je"
    end

    test "dative is njoj", %{forms_map: fm} do
      assert fm["dat"] == "njoj"
    end

    test "dative clitic is joj", %{forms_map: fm} do
      assert fm["dat_clitic"] == "joj"
    end

    test "accusative is nju", %{forms_map: fm} do
      assert fm["acc"] == "nju"
    end

    test "accusative clitic is je", %{forms_map: fm} do
      assert fm["acc_clitic"] == "je"
    end

    test "accusative clitic alternate is ju", %{forms_map: fm} do
      assert fm["acc_clitic_alt"] == "ju"
    end

    test "instrumental is njom", %{forms_map: fm} do
      assert fm["ins"] == "njom"
    end
  end

  describe "generate_forms/1 - personal pronoun mi (1st person plural)" do
    setup do
      word = %Word{
        term: "mi",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 1,
          "number" => "plural"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is mi", %{forms_map: fm} do
      assert fm["nom"] == "mi"
    end

    test "genitive is nas", %{forms_map: fm} do
      assert fm["gen"] == "nas"
    end

    test "dative is nama", %{forms_map: fm} do
      assert fm["dat"] == "nama"
    end

    test "dative clitic is nam", %{forms_map: fm} do
      assert fm["dat_clitic"] == "nam"
    end

    test "instrumental is nama", %{forms_map: fm} do
      assert fm["ins"] == "nama"
    end
  end

  describe "generate_forms/1 - personal pronoun oni (3rd person plural)" do
    setup do
      word = %Word{
        term: "oni",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "personal",
          "person" => 3,
          "number" => "plural"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "has gendered nominative forms", %{forms_map: fm} do
      assert fm["nom_m"] == "oni"
      assert fm["nom_f"] == "one"
      assert fm["nom_n"] == "ona"
    end

    test "genitive is njih", %{forms_map: fm} do
      assert fm["gen"] == "njih"
    end

    test "genitive clitic is ih", %{forms_map: fm} do
      assert fm["gen_clitic"] == "ih"
    end

    test "dative is njima", %{forms_map: fm} do
      assert fm["dat"] == "njima"
    end

    test "dative clitic is im", %{forms_map: fm} do
      assert fm["dat_clitic"] == "im"
    end
  end

  describe "generate_forms/1 - reflexive pronoun sebe" do
    setup do
      word = %Word{
        term: "sebe",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "reflexive",
          "manual_forms_only" => true
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "has no nominative form", %{forms_map: fm} do
      refute Map.has_key?(fm, "nom")
    end

    test "genitive is sebe", %{forms_map: fm} do
      assert fm["gen"] == "sebe"
    end

    test "genitive clitic is se", %{forms_map: fm} do
      assert fm["gen_clitic"] == "se"
    end

    test "dative is sebi", %{forms_map: fm} do
      assert fm["dat"] == "sebi"
    end

    test "dative clitic is si", %{forms_map: fm} do
      assert fm["dat_clitic"] == "si"
    end

    test "accusative is sebe", %{forms_map: fm} do
      assert fm["acc"] == "sebe"
    end

    test "accusative clitic is se", %{forms_map: fm} do
      assert fm["acc_clitic"] == "se"
    end

    test "instrumental is sobom", %{forms_map: fm} do
      assert fm["ins"] == "sobom"
    end

    test "locative is sebi", %{forms_map: fm} do
      assert fm["loc"] == "sebi"
    end
  end

  describe "generate_forms/1 - possessive pronoun moj" do
    setup do
      word = %Word{
        term: "moj",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "possessive"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates forms including alternates", %{forms: forms} do
      # Hardcoded paradigm includes main forms + alternates
      assert length(forms) > 42
    end

    test "nominative singular masculine is moj", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "moj"
    end

    test "nominative singular feminine is moja", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "moja"
    end

    test "nominative singular neuter is moje", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "moje"
    end

    test "genitive singular masculine is mog (contracted)", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "mog"
    end

    test "genitive singular masculine alternate is moga", %{forms_map: fm} do
      assert fm["gen_sg_m_alt"] == "moga"
    end

    test "genitive singular feminine is moje", %{forms_map: fm} do
      assert fm["gen_sg_f"] == "moje"
    end

    test "dative singular masculine is mom (contracted)", %{forms_map: fm} do
      assert fm["dat_sg_m"] == "mom"
    end

    test "dative singular masculine alternate is mome", %{forms_map: fm} do
      assert fm["dat_sg_m_alt"] == "mome"
    end

    test "dative singular feminine is mojoj", %{forms_map: fm} do
      assert fm["dat_sg_f"] == "mojoj"
    end

    test "instrumental singular masculine is mojim (not contracted)", %{forms_map: fm} do
      assert fm["ins_sg_m"] == "mojim"
    end

    test "locative singular masculine is mom (contracted)", %{forms_map: fm} do
      assert fm["loc_sg_m"] == "mom"
    end

    test "nominative plural masculine is moji", %{forms_map: fm} do
      assert fm["nom_pl_m"] == "moji"
    end

    test "nominative plural feminine is moje", %{forms_map: fm} do
      assert fm["nom_pl_f"] == "moje"
    end

    test "nominative plural neuter is moja", %{forms_map: fm} do
      assert fm["nom_pl_n"] == "moja"
    end

    test "genitive plural is mojih", %{forms_map: fm} do
      assert fm["gen_pl_m"] == "mojih"
      assert fm["gen_pl_f"] == "mojih"
      assert fm["gen_pl_n"] == "mojih"
    end
  end

  describe "generate_forms/1 - demonstrative pronoun ovaj" do
    setup do
      word = %Word{
        term: "ovaj",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "demonstrative"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is ovaj", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "ovaj"
    end

    test "nominative singular feminine is ova", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "ova"
    end

    test "nominative singular neuter is ovo", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "ovo"
    end

    test "genitive singular masculine is ovog", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "ovog"
    end

    test "dative singular masculine is ovom", %{forms_map: fm} do
      assert fm["dat_sg_m"] == "ovom"
    end

    test "dative singular feminine is ovoj", %{forms_map: fm} do
      assert fm["dat_sg_f"] == "ovoj"
    end

    test "instrumental singular masculine is ovim", %{forms_map: fm} do
      assert fm["ins_sg_m"] == "ovim"
    end
  end

  describe "generate_forms/1 - demonstrative pronoun taj" do
    setup do
      word = %Word{
        term: "taj",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "demonstrative"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is taj", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "taj"
    end

    test "nominative singular feminine is ta", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "ta"
    end

    test "nominative singular neuter is to", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "to"
    end

    test "genitive singular masculine is tog", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "tog"
    end
  end

  describe "generate_forms/1 - interrogative pronoun ko" do
    setup do
      word = %Word{
        term: "ko",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "interrogative",
          "manual_forms_only" => true
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is ko", %{forms_map: fm} do
      assert fm["nom"] == "ko"
    end

    test "genitive is koga", %{forms_map: fm} do
      assert fm["gen"] == "koga"
    end

    test "dative is kome", %{forms_map: fm} do
      assert fm["dat"] == "kome"
    end

    test "dative alternate is komu", %{forms_map: fm} do
      assert fm["dat_alt"] == "komu"
    end

    test "accusative is koga", %{forms_map: fm} do
      assert fm["acc"] == "koga"
    end

    test "instrumental is kim", %{forms_map: fm} do
      assert fm["ins"] == "kim"
    end

    test "instrumental alternate is kime", %{forms_map: fm} do
      assert fm["ins_alt"] == "kime"
    end

    test "locative is kome", %{forms_map: fm} do
      assert fm["loc"] == "kome"
    end
  end

  describe "generate_forms/1 - interrogative pronoun šta" do
    setup do
      word = %Word{
        term: "šta",
        part_of_speech: :pronoun,
        gender: :neuter,
        grammar_metadata: %{
          "pronoun_type" => "interrogative",
          "manual_forms_only" => true
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is šta", %{forms_map: fm} do
      assert fm["nom"] == "šta"
    end

    test "genitive is čega", %{forms_map: fm} do
      assert fm["gen"] == "čega"
    end

    test "dative is čemu", %{forms_map: fm} do
      assert fm["dat"] == "čemu"
    end

    test "accusative is šta", %{forms_map: fm} do
      assert fm["acc"] == "šta"
    end

    test "instrumental is čim", %{forms_map: fm} do
      assert fm["ins"] == "čim"
    end

    test "locative is čemu", %{forms_map: fm} do
      assert fm["loc"] == "čemu"
    end
  end

  describe "generate_forms/1 - interrogative pronoun koji (adjective-like)" do
    setup do
      word = %Word{
        term: "koji",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "interrogative"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms: forms, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "generates 42 forms", %{forms: forms} do
      assert length(forms) == 42
    end

    test "nominative singular masculine is koji", %{forms_map: fm} do
      assert fm["nom_sg_m"] == "koji"
    end

    test "nominative singular feminine is koja", %{forms_map: fm} do
      assert fm["nom_sg_f"] == "koja"
    end

    test "nominative singular neuter is koje", %{forms_map: fm} do
      assert fm["nom_sg_n"] == "koje"
    end

    test "genitive singular masculine is kojeg (soft stem)", %{forms_map: fm} do
      assert fm["gen_sg_m"] == "kojeg"
    end
  end

  describe "generate_forms/1 - negative pronoun niko" do
    setup do
      word = %Word{
        term: "niko",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "pronoun_type" => "negative"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is niko", %{forms_map: fm} do
      assert fm["nom"] == "niko"
    end

    test "genitive is nikoga", %{forms_map: fm} do
      assert fm["gen"] == "nikoga"
    end

    test "dative is nikome", %{forms_map: fm} do
      assert fm["dat"] == "nikome"
    end

    test "accusative is nikoga", %{forms_map: fm} do
      assert fm["acc"] == "nikoga"
    end

    test "instrumental is nikim", %{forms_map: fm} do
      assert fm["ins"] == "nikim"
    end
  end

  describe "generate_forms/1 - negative pronoun ništa" do
    setup do
      word = %Word{
        term: "ništa",
        part_of_speech: :pronoun,
        gender: :neuter,
        grammar_metadata: %{
          "pronoun_type" => "negative"
        }
      }

      forms = Pronouns.generate_forms(word)
      {:ok, forms_map: Map.new(forms, fn {form, tag} -> {tag, form} end)}
    end

    test "nominative is ništa", %{forms_map: fm} do
      assert fm["nom"] == "ništa"
    end

    test "genitive is ničega", %{forms_map: fm} do
      assert fm["gen"] == "ničega"
    end

    test "dative is ničemu", %{forms_map: fm} do
      assert fm["dat"] == "ničemu"
    end

    test "accusative is ništa", %{forms_map: fm} do
      assert fm["acc"] == "ništa"
    end

    test "instrumental is ničim", %{forms_map: fm} do
      assert fm["ins"] == "ničim"
    end
  end

  describe "generate_forms/1 - manual_forms_only flag" do
    test "respects manual_forms_only for personal pronouns" do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "manual_forms_only" => true
        }
      }

      forms = Pronouns.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["nom"] == "ja"
      assert forms_map["gen"] == "mene"
    end

    test "returns empty for unknown pronoun with manual_forms_only" do
      word = %Word{
        term: "nepoznat",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{
          "manual_forms_only" => true
        }
      }

      forms = Pronouns.generate_forms(word)
      assert forms == []
    end
  end

  describe "generate_forms/1 - auto-detection" do
    test "auto-detects personal pronoun ja" do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{}
      }

      forms = Pronouns.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["nom"] == "ja"
    end

    test "auto-detects reflexive pronoun sebe" do
      word = %Word{
        term: "sebe",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{}
      }

      forms = Pronouns.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["gen"] == "sebe"
      assert forms_map["acc_clitic"] == "se"
    end

    test "auto-detects possessive pronoun moj with contracted forms" do
      word = %Word{
        term: "moj",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{}
      }

      forms = Pronouns.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)

      assert forms_map["nom_sg_m"] == "moj"
      assert forms_map["nom_sg_f"] == "moja"
      assert forms_map["gen_sg_m"] == "mog"
    end
  end

  describe "edge cases" do
    test "handles nil grammar_metadata" do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: nil
      }

      forms = Pronouns.generate_forms(word)
      assert length(forms) > 0
    end

    test "handles empty grammar_metadata" do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{}
      }

      forms = Pronouns.generate_forms(word)
      assert length(forms) > 0
    end

    test "lowercases the term" do
      word = %Word{
        term: "JA",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{"pronoun_type" => "personal"}
      }

      forms = Pronouns.generate_forms(word)
      forms_map = Map.new(forms, fn {form, tag} -> {tag, form} end)
      assert forms_map["nom"] == "ja"
    end

    test "returns empty list for unknown pronoun" do
      word = %Word{
        term: "nepoznat",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{}
      }

      forms = Pronouns.generate_forms(word)
      assert forms == []
    end

    test "returns empty list for unknown demonstrative" do
      word = %Word{
        term: "nepoznat",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{"pronoun_type" => "demonstrative"}
      }

      forms = Pronouns.generate_forms(word)
      assert forms == []
    end
  end

  describe "form tag format" do
    test "personal pronoun tags are simple case names" do
      word = %Word{
        term: "ja",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{"pronoun_type" => "personal"}
      }

      forms = Pronouns.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      assert "nom" in tags
      assert "gen" in tags
      assert "gen_clitic" in tags
      assert "dat" in tags
      assert "dat_clitic" in tags
      assert "acc" in tags
      assert "acc_clitic" in tags
      assert "ins" in tags
      assert "loc" in tags
    end

    test "possessive pronoun moj tags follow expected patterns" do
      word = %Word{
        term: "moj",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{"pronoun_type" => "possessive"}
      }

      forms = Pronouns.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      # Hardcoded paradigm includes main forms + alternates
      assert length(tags) > 42

      # All tags should follow the pattern (with optional _alt, _alt2, _anim suffixes)
      Enum.each(tags, fn tag ->
        assert tag =~ ~r/^(nom|gen|dat|acc|voc|ins|loc)_(sg|pl)_(m|f|n)(_alt|_alt2|_anim)?$/
      end)
    end

    test "regular possessive pronoun naš tags follow pattern {case}_{number}_{gender}" do
      word = %Word{
        term: "naš",
        part_of_speech: :pronoun,
        gender: :masculine,
        grammar_metadata: %{"pronoun_type" => "possessive"}
      }

      forms = Pronouns.generate_forms(word)
      tags = Enum.map(forms, &elem(&1, 1))

      # Regular possessives generate exactly 42 forms
      assert length(tags) == 42

      Enum.each(tags, fn tag ->
        assert tag =~ ~r/^(nom|gen|dat|acc|voc|ins|loc)_(sg|pl)_(m|f|n)$/
      end)
    end
  end
end
