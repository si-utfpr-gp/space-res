require "test_helper"

class UsageTermAssociationsTest < ActiveSupport::TestCase
  subject { build(:usage_term) }

  should have_many(:spaces).dependent(:restrict_with_error)

  test "keeps a usage term used by spaces and explains why" do
    usage_term = create(:usage_term)
    create(:space, usage_term: usage_term)

    assert_not usage_term.destroy
    assert UsageTerm.exists?(usage_term.id)
    assert usage_term.reload.content.present?
    assert_equal [ "Não é possível excluir o termo porque ele é usado por espaços. Troque ou remova o termo de uso desses espaços antes." ],
                 usage_term.errors.full_messages
  end

  test "deletes a usage term that no space uses" do
    usage_term = create(:usage_term)

    assert usage_term.destroy
    assert_not UsageTerm.exists?(usage_term.id)
  end
end
