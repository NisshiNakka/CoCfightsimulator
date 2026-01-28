# このサービスオブジェクトは、simulations_controller.rbで使用するものの、
# コントローラーの本来の役割「viewとmodelの仲介」から外れてしまう処理を、コントローラーに負わせないために切り出したものです。
# 単一責任の法則を守るために、コントローラーには「viewとmodelの仲介」という責任を、当サービスオブジェクトには「戦闘ルールの管理/実行」という責任を任せます。
class BattleProcessor
  def self.call(attacker, defender, use_attack)
    new(attacker, defender, use_attack).execute
  end

  def initialize(attacker, defender, use_attack) # 引数をインスタンス化し、すべてのメソッドで使用できるようにする
    @attacker = attacker
    @defender = defender
    @use_attack = use_attack
  end

  def execute # １アクションのルールを担当
    attack_result = attack

    result_data = build_result_data(attack_result)

    return result_data.merge(status: :failed) unless attack_result.success?

    evasion_result = evasion(attack_result)

    process_action(evasion_result, result_data)
  end

  private

  def attack # 攻撃の実行
    @use_attack.attack_roll
  end

  def build_result_data(attack_result) # リザルトデータ作成
    {
      attacker_name: @attacker.name,
      defender_name: @defender.name,
      attack_text: attack_result.text,
      success: attack_result.success?,
      dexterity: @attacker.dexterity
    }
  end

  def evasion(attack_result) # 回避の実行
    correction = @use_attack.success_correction(attack_result)
    @defender.evasion_roll(correction)
  end

  def damage # ダメージの計算
    damage_result = @use_attack.damage_roll(@attacker.damage_bonus)
    remaining_hp = @defender.hp_calculation(damage_result)

    {
      text: damage_result.text,
      hp: remaining_hp[:hp],
      damage: remaining_hp[:damage]
    }
  end

  def process_action(evasion_result, result_data) # リザルトにどの内容を渡すか
    if evasion_result.success?
      result_data.merge(status: :evaded, evasion_text: evasion_result.text)
    else
      damage_data = damage
      result_data.merge(
        status: :hit,
        evasion_text: evasion_result.text,
        damage_text: damage_data[:text],
        remaining_hp: damage_data[:hp],
        final_damage: damage_data[:damage],
        armor: @defender.armor
      )
    end
  end
end
