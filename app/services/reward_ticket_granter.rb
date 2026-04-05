class RewardTicketGranter
  ACTION_MILESTONE_MAP = {
    registration:     [ "first_registration" ],
    profile_view:     [ "first_profile_view" ],
    dice_update:      [ "first_dice_update" ],
    character_create: [ "first_character_create" ],
    character_index:  [ "first_character_index" ],
    character_show:   [ "first_character_show" ],
    character_edit:   [ "first_character_edit" ],
    simulation:       [ "first_simulation" ]
  }.freeze

  def self.call(user, action:)
    new(user, action).grant
  end

  def initialize(user, action)
    @user = user
    @action = action
  end

  def grant
    # 達成済みキーを1クエリで一括取得 → Set で O(1) ルックアップ
    achieved_keys = @user.reward_milestones.pluck(:milestone_key).to_set

    # カウンター値を事前にまとめて取得（ループ内でクエリを発行しない）
    counters = build_counters

    granted = []
    RewardMilestoneDefinitions::DEFINITIONS.each do |key, definition|
      next if achieved_keys.include?(key)
      next unless milestone_achieved?(key, definition, counters)

      @user.transaction do
        @user.reward_milestones.create!(milestone_key: key)
        @user.increment!(:reward_tickets)
      end
      granted << key
    end
    granted
  end

  private

  def build_counters
    {
      characters_count:      @user.characters.count,
      simulations_count:     @user.simulations_count,
      character_edits_count: @user.character_edits_count,
      dice_updates_count:    @user.dice_updates_count
    }
  end

  def milestone_achieved?(key, definition, counters)
    case definition[:category]
    when :first_use
      first_use_action_matches?(key)
    when :milestone
      counters[definition[:counter]] >= definition[:threshold]
    end
  end

  def first_use_action_matches?(key)
    ACTION_MILESTONE_MAP[@action]&.include?(key) || false
  end
end
