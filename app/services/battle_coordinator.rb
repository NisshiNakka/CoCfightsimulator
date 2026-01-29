class BattleCoordinator
  def self.call(ally_character, enemy_character, ally_attack, enemy_attack, ally_hp, enemy_hp)
    new(ally_character, enemy_character, ally_attack, enemy_attack, ally_hp, enemy_hp).execute
  end

  def initialize(ally_character, enemy_character, ally_attack, enemy_attack, ally_hp, enemy_hp) # 引数をインスタンス化し、すべてのメソッドで使用できるようにする
    @participants = { ally: ally_character, enemy: enemy_character }
    @attacks = { ally: ally_attack, enemy: enemy_attack }
    @participants[:ally].current_hp = ally_hp || ally_character.hitpoint
    @participants[:enemy].current_hp = enemy_hp || enemy_character.hitpoint
    @results = []
  end

  def execute
    combatants = turn_decide
    take_action(combatants)
    build_response_data
  end

  private

  def turn_decide # 戦闘順番の決定
    [
      { side: :ally, target: :enemy },
      { side: :enemy, target: :ally }
    ].sort_by { |c| -@participants[c[:side]].dexterity }
  end

  def take_action(combatants) # 戦闘の実行
    combatants.each do |c|
      attacker = @participants[c[:side]]
      defender = @participants[c[:target]]
      attack = @attacks[c[:side]]
      target_hp = defender.current_hp


      res = BattleProcessor.call(attacker, defender, attack, target_hp)
      @results << res.merge(side: c[:side])

      update_target_hp(defender, res)

      break if defender.fall_down?
    end
  end

  def build_response_data
    {
      results: @results,
      final_hp: { ally: @participants[:ally].current_hp, enemy: @participants[:enemy].current_hp },
      battle_ended: battle_ended?
    }
  end

  def update_target_hp(defender, res) # 現在HPの更新
    return unless res[:status] == :hit
    defender.current_hp = res[:remaining_hp]
  end

  def battle_ended? # 戦闘終了判定
    @participants[:ally].fall_down? || @participants[:enemy].fall_down?
  end
end
