class Submission < ActiveRecord::Base
  include Context
  include Creation

  CAUSES = %w(assess download file render run save submit test)
  FILENAME_URL_PLACEHOLDER = '{filename}'

  belongs_to :exercise

  delegate :execution_environment, to: :exercise

  scope :final, -> { where(cause: 'submit') }
  scope :intermediate, -> { where.not(cause: 'submit') }

  validates :cause, inclusion: {in: CAUSES}
  validates :exercise_id, presence: true

  def build_files_hash(files, attribute)
    files.map(&attribute.to_proc).zip(files).to_h
  end
  private :build_files_hash

  def collect_files
    ancestors = build_files_hash(exercise.files, :id)
    descendants = build_files_hash(files, :file_id)
    ancestors.merge(descendants).values
  end

  [:download, :render, :run, :test].each do |action|
    filename = FILENAME_URL_PLACEHOLDER.gsub(/\W/, '')
    define_method("#{action}_url") do
      Rails.application.routes.url_helpers.send(:"#{action}_submission_path", self, filename).sub(filename, FILENAME_URL_PLACEHOLDER)
    end
  end

  def main_file
    collect_files.detect(&:main_file?)
  end

  def normalized_score
    score / exercise.maximum_score if score
  end

  def percentage
    (normalized_score * 100).round if score
  end

  [:score, :stop].each do |action|
    define_method("#{action}_url") do
      Rails.application.routes.url_helpers.send(:"#{action}_submission_path", self)
    end
  end

  def siblings
    user.submissions.where(exercise_id: exercise_id)
  end

  def to_s
    Submission.model_name.human
  end
end
