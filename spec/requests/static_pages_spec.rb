require 'rails_helper'

RSpec.describe "StaticPages", type: :request do
  describe "GET / (top page)" do
    before { get root_path }

    it "正常にレスポンスを返すこと" do
      expect(response).to have_http_status(:ok)
    end

    describe "OGP メタタグ" do
      it "og:title が含まれること" do
        expect(response.body).to include('property="og:title"')
      end

      it "og:title の内容が正しいこと" do
        expect(response.body).to include("CoC Fight Simulator｜新クトゥルフ神話TRPG 戦闘シミュレーター")
      end

      it "og:description が含まれること" do
        expect(response.body).to include('property="og:description"')
      end

      it "og:description の内容が正しいこと" do
        expect(response.body).to include("TRPG（CoC7版）シナリオ制作者向けの戦闘シミュレーションツール")
      end

      it "og:type が website であること" do
        expect(response.body).to include('property="og:type"')
        expect(response.body).to include('content="website"')
      end

      it "og:url が含まれること" do
        expect(response.body).to include('property="og:url"')
      end

      it "og:image が /ogp.jpg を指していること" do
        expect(response.body).to include('property="og:image"')
        expect(response.body).to include('/ogp.jpg')
      end

      it "og:site_name が CoC Fight Simulator であること" do
        expect(response.body).to include('property="og:site_name"')
        expect(response.body).to include("CoC Fight Simulator")
      end

      it "og:locale が含まれること" do
        expect(response.body).to include('property="og:locale"')
      end

      it "description メタタグが含まれること" do
        expect(response.body).to include('name="description"')
      end
    end

    describe "Twitter Card メタタグ" do
      it "twitter:card が summary_large_image であること" do
        expect(response.body).to include('name="twitter:card"')
        expect(response.body).to include('content="summary_large_image"')
      end

      it "twitter:title が含まれること" do
        expect(response.body).to include('name="twitter:title"')
      end

      it "twitter:description が含まれること" do
        expect(response.body).to include('name="twitter:description"')
      end

      it "twitter:image が /ogp.jpg を指していること" do
        expect(response.body).to include('name="twitter:image"')
        expect(response.body).to include('/ogp.jpg')
      end
    end
  end
end
