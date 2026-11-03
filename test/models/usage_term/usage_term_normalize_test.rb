require "test_helper"

class UsageTermNormalizeTest < ActiveSupport::TestCase
  test "squishes the title" do
    assert_equal "Termo do Laboratório", build(:usage_term, title: "  Termo   do Laboratório ").title
  end

  test "keeps the letter case and accents typed in the title" do
    assert_equal "TERMO do Laboratório", create(:usage_term, title: "TERMO do Laboratório").reload.title
  end

  test "stores the line breaks sent by the browser as line feeds" do
    assert_equal "Primeira linha.\nSegunda linha.\n\nNovo parágrafo.",
                 build(:usage_term, content: "Primeira linha.\r\nSegunda linha.\r\n\r\nNovo parágrafo.").content
  end

  test "removes spaces and blank lines around the content" do
    assert_equal "Primeiro parágrafo.\n\nSegundo parágrafo.",
                 build(:usage_term, content: " \n\n  Primeiro parágrafo.\n\nSegundo parágrafo.  \n\n ").content
  end

  test "keeps the spaces and blank lines inside the content" do
    content = "Regras:\n\n  1. Chegue no horário.\n  2. Não  coma no laboratório.\n\n\nFim."

    assert_equal content, create(:usage_term, content: content).reload.content
  end
end
