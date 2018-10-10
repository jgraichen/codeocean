require 'rails_helper'

describe ExercisesController do
  let(:exercise) { FactoryBot.create(:dummy) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'PUT #batch_update' do
    let(:attributes) { { 'public': 'true'} }
    let(:perform_request) { proc { put :batch_update, params: { exercises: {0 => attributes.merge(id: exercise.id)} } } }
    before(:each) { perform_request.call }

    it 'updates the exercises' do
      expect_any_instance_of(Exercise).to receive(:update).with(attributes)
      perform_request.call
    end

    expect_json
    expect_status(200)
  end

  describe 'POST #clone' do
    let(:perform_request) { proc { post :clone, params: { id: exercise.id } } }

    context 'when saving succeeds' do
      before(:each) { perform_request.call }

      expect_assigns(exercise: Exercise)

      it 'clones the exercise' do
        expect_any_instance_of(Exercise).to receive(:duplicate).with(hash_including(public: false, user: user)).and_call_original
        expect { perform_request.call }.to change(Exercise, :count).by(1)
      end

      it 'generates a new token' do
        expect(Exercise.last.token).not_to eq(exercise.token)
      end

      expect_redirect(Exercise.last)
    end

    context 'when saving fails' do
      before(:each) do
        expect_any_instance_of(Exercise).to receive(:save).and_return(false)
        perform_request.call
      end

      expect_assigns(exercise: Exercise)
      expect_flash_message(:danger, :'shared.message_failure')
      expect_redirect(:exercise)
    end
  end

  describe 'POST #create' do
    let(:exercise_attributes) { FactoryBot.build(:dummy).attributes }

    context 'with a valid exercise' do
      let(:perform_request) { proc { post :create, params: { exercise: exercise_attributes } } }
      before(:each) { perform_request.call }

      expect_assigns(exercise: Exercise)

      it 'creates the exercise' do
        expect { perform_request.call }.to change(Exercise, :count).by(1)
      end

      expect_redirect(Exercise.last)
    end

    context 'when including a file' do
      let(:perform_request) { proc { post :create, params: { exercise: exercise_attributes.merge(files_attributes: files_attributes) } } }

      context 'when specifying the file content within the form' do
        let(:files_attributes) { {'0' => FactoryBot.build(:file).attributes} }

        it 'creates the file' do
          expect { perform_request.call }.to change(CodeOcean::File, :count)
        end
      end

      context 'when uploading a file' do
        let(:files_attributes) { {'0' => FactoryBot.build(:file, file_type: file_type).attributes.merge(content: uploaded_file)} }

        context 'when uploading a binary file' do
          let(:file_path) { Rails.root.join('db', 'seeds', 'audio_video', 'devstories.mp4') }
          let(:file_type) { FactoryBot.create(:dot_mp4) }
          let(:uploaded_file) { Rack::Test::UploadedFile.new(file_path, 'video/mp4', true) }

          it 'creates the file' do
            expect { perform_request.call }.to change(CodeOcean::File, :count)
          end

          it 'assigns the native file' do
            perform_request.call
            expect(Exercise.last.files.first.native_file).to be_a(FileUploader)
          end
        end

        context 'when uploading a non-binary file' do
          let(:file_path) { Rails.root.join('db', 'seeds', 'fibonacci', 'exercise.rb') }
          let(:file_type) { FactoryBot.create(:dot_rb) }
          let(:uploaded_file) { Rack::Test::UploadedFile.new(file_path, 'text/x-ruby', false) }

          it 'creates the file' do
            expect { perform_request.call }.to change(CodeOcean::File, :count)
          end

          it 'assigns the file content' do
            perform_request.call
            expect(Exercise.last.files.first.content).to eq(File.read(file_path))
          end
        end
      end
    end

    context 'with an invalid exercise' do
      before(:each) { post :create, params: { exercise: { } } }

      expect_assigns(exercise: Exercise)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) { delete :destroy, params: { id: exercise.id } }

    expect_assigns(exercise: :exercise)

    it 'destroys the exercise' do
      exercise = FactoryBot.create(:dummy)
      expect { delete :destroy, params: { id: exercise.id } }.to change(Exercise, :count).by(-1)
    end

    expect_redirect(:exercises)
  end

  describe 'GET #edit' do
    before(:each) { get :edit, params: { id: exercise.id } }

    expect_assigns(exercise: :exercise)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #implement' do
    let(:perform_request) { proc { get :implement, params: { id: exercise.id } } }

    context 'with an exercise with visible files' do
      let(:exercise) { FactoryBot.create(:fibonacci) }
      before(:each) { perform_request.call }

      expect_assigns(exercise: :exercise)

      context 'with an existing submission' do
        let!(:submission) { FactoryBot.create(:submission, exercise_id: exercise.id, user_id: user.id, user_type: user.class.name) }

        it "populates the editors with the submission's files' content" do
          perform_request.call
          expect(assigns(:files)).to eq(submission.files)
        end
      end

      context 'without an existing submission' do
        it "populates the editors with the exercise's files' content" do
          expect(assigns(:files)).to eq(exercise.files.visible)
        end
      end

      expect_status(200)
      expect_template(:implement)
    end

    context 'with an exercise without visible files' do
      before(:each) { perform_request.call }

      expect_assigns(exercise: :exercise)
      expect_flash_message(:alert, :'exercises.implement.no_files')
      expect_redirect(:exercise)
    end
  end

  describe 'GET #index' do
    let(:scope) { Pundit.policy_scope!(user, Exercise) }
    before(:all) { FactoryBot.create_pair(:dummy) }
    before(:each) { get :index }

    expect_assigns(exercises: :scope)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) { get :new }

    expect_assigns(execution_environments: ExecutionEnvironment.all, exercise: Exercise)
    expect_assigns(exercise: Exercise)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    context 'as admin' do
      before(:each) { get :show, params: { id: exercise.id } }

      expect_assigns(exercise: :exercise)
      expect_status(200)
      expect_template(:show)
    end
  end

  describe 'GET #reload' do
    context 'as anyone' do
      before(:each) { get :reload, format: :json, params: { id: exercise.id } }

      expect_assigns(exercise: :exercise)
      expect_status(200)
      expect_template(:reload)
    end
  end

  describe 'GET #statistics' do
    before(:each) { get :statistics, params: { id: exercise.id } }

    expect_assigns(exercise: :exercise)
    expect_status(200)
    expect_template(:statistics)
  end

  describe 'POST #submit' do
    let(:output) { {} }
    let(:perform_request) { post :submit, format: :json, params: { id: exercise.id, submission: {cause: 'submit', exercise_id: exercise.id} } }
    let!(:external_user) { FactoryBot.create(:external_user) }
    let!(:lti_parameter) { FactoryBot.create(:lti_parameter, external_user: external_user, exercise: exercise) }

    before(:each) do
      allow_any_instance_of(Submission).to receive(:normalized_score).and_return(1)
      expect(controller).to receive(:collect_test_results).and_return([{score: 1, weight: 1}])
      expect(controller).to receive(:score_submission).and_call_original
      controller.session[:consumer_id] = external_user.consumer_id
    end

    context 'when LTI outcomes are supported' do
      before(:each) do
        expect(controller).to receive(:lti_outcome_service?).and_return(true)
      end

      context 'when the score transmission succeeds' do
        before(:each) do
          expect(controller).to receive(:send_score).and_return(status: 'success')
          perform_request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_status(200)
      end

      context 'when the score transmission fails' do
        before(:each) do
          expect(controller).to receive(:send_score).and_return(status: 'unsupported')
          perform_request
        end

        expect_assigns(exercise: :exercise)

        it 'creates a submission' do
          expect(assigns(:submission)).to be_a(Submission)
        end

        expect_json
        expect_status(503)
      end
    end

    context 'when LTI outcomes are not supported' do
      before(:each) do
        expect(controller).to receive(:lti_outcome_service?).and_return(false)
        expect(controller).not_to receive(:send_score)
        perform_request
      end

      expect_assigns(exercise: :exercise)

      it 'creates a submission' do
        expect(assigns(:submission)).to be_a(Submission)
      end

      expect_json
      expect_status(200)
    end
  end

  describe 'PUT #update' do
    context 'with a valid exercise' do
      let(:exercise_attributes) { FactoryBot.build(:dummy).attributes }
      before(:each) { put :update, params: { exercise: exercise_attributes, id: exercise.id } }

      expect_assigns(exercise: Exercise)
      expect_redirect(:exercise)
    end

    context 'with an invalid exercise' do
      before(:each) { put :update, params: { exercise: {title: ''}, id: exercise.id } }

      expect_assigns(exercise: Exercise)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
