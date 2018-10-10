# consumers
FactoryBot.create(:consumer)
FactoryBot.create(:consumer, name: 'openSAP')

# users
# Set default_url_options explicitly, required for rake task
Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
[:admin, :external_user, :teacher].each { |factory_name| FactoryBot.create(factory_name) }

# execution environments
ExecutionEnvironment.create_factories

# errors
CodeOcean::Error.create_factories

# exercises
@exercises = find_factories_by_class(Exercise).map(&:name).map { |factory_name| [factory_name, FactoryBot.create(factory_name)] }.to_h

# file types
FileType.create_factories

# hints
Hint.create_factories

# submissions
FactoryBot.create(:submission, exercise: @exercises[:fibonacci])
