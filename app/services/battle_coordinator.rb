# このサービスオブジェクトは、simulations_controller.rbで使用するものの、
# コントローラーの本来の役割「viewとmodelの仲介」から外れてしまう処理を、コントローラーに負わせないために切り出したものです。
# 単一責任の法則を守るために、コントローラーには「viewとmodelの仲介」という責任を、当サービスオブジェクトには「戦闘における、1ラウンドの管理/実行」という責任を任せます。（ ↓ の「ラウンド」の部分）
# シミュレーション説明　[キャラクターは１ラウンドに１回攻撃（アクション）ができる。全キャラクターがアクションを終えると１ラウンドが終了し、戦闘が終わるまで１ラウンドをループする。]
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
    @turn = 0
  end

  def execute
    combatants = turn_decide
    until battle_ended?
      @turn += 1
      take_action(combatants)
    end
    winner_data = decision
    build_response_data(winner_data)
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
      @results << res.merge(side: c[:side], turn: @turn)

      update_target_hp(defender, res)

      break if defender.fall_down?
    end
  end

  def build_response_data(winner_data) # コントローラーへ送るデータの作成
    {
      results: @results,
      final_hp: { ally: @participants[:ally].current_hp, enemy: @participants[:enemy].current_hp },
      battle_ended: battle_ended?,
      decision: winner_data,
      finish_turn: @turn
    }
  end

  def update_target_hp(defender, res) # 現在HPの更新
    return unless res[:status] == :hit
    defender.current_hp = res[:remaining_hp]
  end

  def battle_ended? # 戦闘終了判定
    @participants[:ally].fall_down? || @participants[:enemy].fall_down?
  end

  def decision # 勝者の判決
    if @participants[:ally].fall_down?
      { winner: @participants[:enemy], loser: @participants[:ally], side: :enemy }
    else
      { winner: @participants[:ally], loser: @participants[:enemy], side: :ally }
    end
  end
end
