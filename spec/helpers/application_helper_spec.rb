require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "#ogp_image_url" do
    it "絶対URLで /ogp.jpg を返すこと" do
      expect(helper.ogp_image_url).to match(%r{\Ahttps?://.+/ogp\.jpg\z})
    end

    it "リクエストのベースURLを含むこと" do
      expect(helper.ogp_image_url).to start_with(request.base_url)
    end
  end
end
