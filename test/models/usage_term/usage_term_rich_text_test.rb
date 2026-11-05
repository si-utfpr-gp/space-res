require "test_helper"

class UsageTermRichTextTest < ActiveSupport::TestCase
  test "keeps the formatting of the content" do
    usage_term = create(:usage_term, content: "<div>Regras:</div><ol><li><strong>Chegue</strong> no horário.</li></ol>")

    content = usage_term.reload.content
    assert_equal "Regras:\n1. Chegue no horário.", content.to_plain_text
    assert_equal 1, content.body.fragment.find_all("ol li strong").size
  end

  test "deletes the content along with the term" do
    usage_term = create(:usage_term)

    assert_difference -> { ActionText::RichText.count }, -1 do
      usage_term.destroy
    end
  end
end
