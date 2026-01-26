# このサービスオブジェクトは、simulations_controller.rbで使用するものの、
# コントローラーの本来の役割「viewとmodelの仲介」から外れてしまう処理を、コントローラーに負わせないために切り出したものです。
# 単一責任の法則を守るために、コントローラーには「viewとmodelの仲介」という責任を、当サービスオブジェクトには「戦闘ルールの実行」という責任を任せます。
class BattleProcessor
  def self.call(attacker, defender, use_attack)
    attack_result = use_attack.attack_roll

    result_data = {
      attacker_name: attacker.name,
      defender_name: defender.name,
      attack_text: attack_result.text,
      success: attack_result.success?,
      dexterity: attacker.dexterity
    }

    return result_data.merge(status: "失敗") unless attack_result.success?
    # 2 回避難易度決定(character)
    correction = use_attack.success_correction(attack_result)

    # 3 回避判定(character)
    evasion_result = defender.evasion_roll(correction)

    # 6 ログ表示の決定
    if evasion_result.success?
      result_data.merge(status: "回避", evasion_text: evasion_result.text)
    else
      # 4 ダメージの計算
      damage_result = use_attack.damage_roll(attacker.damage_bonus)
      # 5 HPの計算
      remaining_hp = defender.hp_calculation(damage_result)
      result_data.merge(
        status: "成功",
        evasion_text: evasion_result.text,
        damage_text: damage_result.text,
        remaining_hp: remaining_hp
      )
    end
  end
end
