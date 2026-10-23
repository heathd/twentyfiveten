require 'rails_helper'

RSpec.describe "Administrators", type: :request do
  describe "registering" do
    it "creates an administrator and logs them in" do
      expect { post administrators_path }.to change(Administrator, :count).by(1)

      expect(response).to redirect_to(admin_challenges_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it "does not create another administrator for someone who is already logged in" do
      post administrators_path

      expect { post administrators_path }.not_to change(Administrator, :count)
      expect(response).to redirect_to(admin_challenges_path)
    end

    it "replaces a session that refers to an administrator that no longer exists" do
      post administrators_path
      Administrator.destroy_all

      expect { post administrators_path }.to change(Administrator, :count).by(1)
      expect(response).to redirect_to(admin_challenges_path)
    end
  end

  describe "logging in and out" do
    let(:administrator) { Administrator.create! }

    it "logs in with a valid administrator token" do
      post login_administrators_path, params: { administrator_id: administrator.administrator_id }

      expect(response).to redirect_to(admin_challenges_path)
      get admin_challenges_path
      expect(response).to have_http_status(:ok)
    end

    it "does not log in with an unknown token" do
      post login_administrators_path, params: { administrator_id: "nope" }

      expect(response).to redirect_to(root_path)
      get admin_challenges_path
      expect(response).to redirect_to("/")
    end

    it "logs out" do
      post login_administrators_path, params: { administrator_id: administrator.administrator_id }
      post logout_administrators_path

      expect(response).to redirect_to(root_path)
      get admin_challenges_path
      expect(response).to redirect_to("/")
    end
  end

  describe "unused scaffold routes" do
    let(:administrator) { Administrator.create! }

    it "does not list or show administrators" do
      get "/administrators"
      expect(response).to have_http_status(:not_found)

      get "/administrators/#{administrator.id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
