require "test_helper"

# Two admins saving the same title at the same time both pass the uniqueness validation, and
# the unique index rejects the second INSERT. Skipping the validator reproduces that second save.
class UsageTermConcurrentSaveTest < ActiveSupport::TestCase
  setup do
    create(:usage_term, title: "Termo do Laboratório")
    NormalizedUniquenessValidator.any_instance.stubs(:validate_each)
  end

  test "turns a title saved by another request into a taken error on create" do
    usage_term = build(:usage_term, title: "Termo do Laboratório")

    assert_no_difference -> { UsageTerm.count } do
      assert_not usage_term.save
    end
    assert_equal [ "Já existe um termo cadastrado com este título." ], usage_term.errors[:title]
    assert usage_term.new_record?
    assert_nil usage_term.id
  end

  test "turns a title saved by another request into a taken error on update" do
    usage_term = create(:usage_term, title: "Termo da Quadra")

    assert_not usage_term.update(title: "Termo do Laboratório")
    assert_equal [ "Já existe um termo cadastrado com este título." ], usage_term.errors[:title]
    assert_equal "Termo do Laboratório", usage_term.title
    assert_equal "Termo da Quadra", usage_term.title_in_database
    assert_equal "Termo da Quadra", usage_term.reload.title
  end

  test "still raises a unique violation that is not about the title" do
    existing = UsageTerm.sole

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:usage_term, id: existing.id, title: "Termo da Quadra").save
    end
  end
end
