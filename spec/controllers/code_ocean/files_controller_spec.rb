require 'rails_helper'

describe CodeOcean::FilesController do
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    let(:submission) { FactoryBot.create(:submission, user: user) }

    context 'with a valid file' do
      let(:perform_request) { proc { post :create, params: { code_ocean_file: FactoryBot.build(:file, context: submission).attributes, format: :json } } }
      before(:each) { perform_request.call }

      expect_assigns(file: CodeOcean::File)

      it 'creates the file' do
        expect { perform_request.call }.to change(CodeOcean::File, :count)
      end

      expect_json
      expect_status(201)
    end

    context 'with an invalid file' do
      before(:each) { post :create, params: { code_ocean_file: {context_id: submission.id, context_type: Submission}, format: :json } }

      expect_assigns(file: CodeOcean::File)
      expect_json
      expect_status(422)
    end
  end

  describe 'DELETE #destroy' do
    let(:exercise) { FactoryBot.create(:fibonacci) }
    let(:perform_request) { proc { delete :destroy, params: { id: exercise.files.first.id } } }
    before(:each) { perform_request.call }

    expect_assigns(file: CodeOcean::File)

    it 'destroys the file' do
      FactoryBot.create(:fibonacci)
      expect { perform_request.call }.to change(CodeOcean::File, :count).by(-1)
    end

    expect_redirect(:exercise)
  end
end
