require 'rails_helper'

describe HintsController do
  let(:execution_environment) { FactoryBot.create(:ruby) }
  let(:hint) { FactoryBot.create(:ruby_syntax_error) }
  let(:user) { FactoryBot.create(:admin) }
  before(:each) { allow(controller).to receive(:current_user).and_return(user) }

  describe 'POST #create' do
    context 'with a valid hint' do
      let(:perform_request) { proc { post :create, params: { execution_environment_id: execution_environment.id, hint: FactoryBot.attributes_for(:ruby_syntax_error) } } }
      before(:each) { perform_request.call }

      expect_assigns(execution_environment: :execution_environment)
      expect_assigns(hint: Hint)

      it 'creates the hint' do
        expect { perform_request.call }.to change(Hint, :count).by(1)
      end

      expect_redirect(Hint.last)
    end

    context 'with an invalid hint' do
      before(:each) { post :create, params: { execution_environment_id: execution_environment.id, hint: {} } }

      expect_assigns(execution_environment: :execution_environment)
      expect_assigns(hint: Hint)
      expect_status(200)
      expect_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before(:each) { delete :destroy, params: { execution_environment_id: execution_environment.id, id: hint.id } }

    expect_assigns(execution_environment: :execution_environment)
    expect_assigns(hint: Hint)

    it 'destroys the hint' do
      hint = FactoryBot.create(:ruby_syntax_error)
      expect { delete :destroy, params: { execution_environment_id: execution_environment.id, id: hint.id } }.to change(Hint, :count).by(-1)
    end

    expect_redirect { execution_environment_hints_path(execution_environment) }
  end

  describe 'GET #edit' do
    before(:each) { get :edit, params: { execution_environment_id: execution_environment.id, id: hint.id } }

    expect_assigns(execution_environment: :execution_environment)
    expect_assigns(hint: Hint)
    expect_status(200)
    expect_template(:edit)
  end

  describe 'GET #index' do
    before(:all) { FactoryBot.create_pair(:ruby_syntax_error) }
    before(:each) { get :index, params: { execution_environment_id: execution_environment.id } }

    expect_assigns(execution_environment: :execution_environment)
    expect_assigns(hints: Hint.all)
    expect_status(200)
    expect_template(:index)
  end

  describe 'GET #new' do
    before(:each) { get :new, params: { execution_environment_id: execution_environment.id } }

    expect_assigns(execution_environment: :execution_environment)
    expect_assigns(hint: Hint)
    expect_status(200)
    expect_template(:new)
  end

  describe 'GET #show' do
    before(:each) { get :show, params: { execution_environment_id: execution_environment.id, id: hint.id } }

    expect_assigns(execution_environment: :execution_environment)
    expect_assigns(hint: :hint)
    expect_status(200)
    expect_template(:show)
  end

  describe 'PUT #update' do
    context 'with a valid hint' do
      before(:each) { put :update, params: { execution_environment_id: execution_environment.id, hint: FactoryBot.attributes_for(:ruby_syntax_error), id: hint.id } }

      expect_assigns(execution_environment: :execution_environment)
      expect_assigns(hint: Hint)
      expect_redirect { hint }
    end

    context 'with an invalid hint' do
      before(:each) { put :update, params: { execution_environment_id: execution_environment.id, hint: {name: ''}, id: hint.id } }

      expect_assigns(execution_environment: :execution_environment)
      expect_assigns(hint: Hint)
      expect_status(200)
      expect_template(:edit)
    end
  end
end
