require "test_helper"

class SpaceStatusTest < ActiveSupport::TestCase
  REASON_BLANK = "Informe o motivo da indisponibilidade.".freeze
  REASON_TOO_LONG = "O motivo deve ter no máximo 100 caracteres.".freeze

  subject { build(:space) }

  should define_enum_for(:status)
    .with_values(available: "available", unavailable: "unavailable", deactivated: "deactivated")
    .backed_by_column_of_type(:string)

  context "an unavailable space" do
    subject { build(:space, :unavailable) }

    should validate_presence_of(:unavailability_reason).with_message(REASON_BLANK)
    should validate_length_of(:unavailability_reason).is_at_most(100).with_message(REASON_TOO_LONG)
  end

  context "a space that is not unavailable" do
    should_not validate_presence_of(:unavailability_reason)
  end

  test "marks an available space as unavailable with the reason" do
    space = create(:space)

    assert space.mark_unavailable("  Sala   em reforma ")

    space.reload
    assert space.unavailable?
    assert_equal "Sala em reforma", space.unavailability_reason
  end

  test "refuses to mark a space as unavailable without a reason or with a reason too long" do
    space = create(:space)

    [ "", "   ", nil, "a" * 101 ].each do |reason|
      assert_not Space.find(space.id).mark_unavailable(reason), "expected #{reason.inspect} to be refused"
      assert space.reload.available?
    end
  end

  test "accepts a reason with exactly 100 characters" do
    assert create(:space).mark_unavailable("a" * 100)
  end

  test "changes the reason of an unavailable space" do
    space = create(:space, :unavailable)

    assert space.change_unavailability_reason("Sala em reforma até março")

    assert_equal [ "unavailable", "Sala em reforma até março" ], [ space.reload.status, space.unavailability_reason ]
  end

  test "keeps the saved reason when a new one is refused" do
    space = create(:space, :unavailable)

    assert_not space.change_unavailability_reason(" ")

    assert_equal "Sala em reforma", space.reload.unavailability_reason
  end

  test "ends the unavailability and forgets the reason" do
    space = create(:space, :unavailable)

    space.end_unavailability

    space.reload
    assert space.available?
    assert_nil space.unavailability_reason
  end

  test "deactivates an available or unavailable space and forgets the reason" do
    available = create(:space)
    unavailable = create(:space, :unavailable)

    available.deactivate
    unavailable.deactivate

    assert available.reload.deactivated?
    assert unavailable.reload.deactivated?
    assert_nil unavailable.unavailability_reason
  end

  test "reactivates a deactivated space as available" do
    space = create(:space, :deactivated)

    space.reactivate

    assert space.reload.available?
  end

  test "refuses each change from a status it does not start from, and changes nothing" do
    {
      mark_unavailable: [ :unavailable, :deactivated ],
      change_unavailability_reason: [ :available, :deactivated ],
      end_unavailability: [ :available, :deactivated ],
      deactivate: [ :deactivated ],
      reactivate: [ :available, :unavailable ]
    }.each do |change, statuses|
      statuses.each do |status|
        space = create(:space, status)
        arguments = change.in?([ :mark_unavailable, :change_unavailability_reason ]) ? [ "Outro motivo" ] : []

        assert_raises(Space::StatusConflict, "#{change} from #{status}") { space.public_send(change, *arguments) }
        assert_equal [ status.to_s, space.unavailability_reason ], Space.where(id: space.id).pick(:status, :unavailability_reason)
      end
    end
  end

  test "checks the saved status, so a copy loaded before another change cannot undo it" do
    space = create(:space, :unavailable)
    loaded_before = Space.find(space.id)

    space.deactivate

    assert_raises(Space::StatusConflict) { loaded_before.end_unavailability }
    assert_raises(Space::StatusConflict) { loaded_before.change_unavailability_reason("Outro motivo") }
    assert space.reload.deactivated?
  end

  test "keeps the status and the reason when other data of the space changes" do
    space = create(:space, :unavailable)

    space.update!(name: "Sala 2", description: "Outra descrição.")

    space.reload
    assert space.unavailable?
    assert_equal "Sala em reforma", space.unavailability_reason
  end

  test "forgets the reason whenever the space stops being unavailable" do
    space = create(:space, :unavailable)

    space.update!(status: :available)

    assert_nil space.reload.unavailability_reason
  end
end
