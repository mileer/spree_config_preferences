module Spree
  class ConfigPreferenceLoader
    class << self

      MODEL_ID_KEY     = 'id'
      MODEL_CLASS_KEY  = 'model_class'
      CONFIG_CLASS_KEY = 'config_class'

      def load(file)
        load_configurations(file)
      end

      def load_model_preferences(file)
        load_configurations(file, true, false)
      end

      def load_environment_agnostic_preferences(file)
        load_configurations(file, false, true)
      end

      private

      def load_configurations(file, is_model = false, is_environment_agnostic = false)
        yaml_config = YAML.load_file(file) || {}
        yaml_config = yaml_config[Rails.env] || {} unless is_environment_agnostic

        config_hash = {}
        yaml_config.each do |config_key, config_values|
          begin
            config_object = if is_model
               config_values.delete(MODEL_CLASS_KEY).constantize.find(config_values.delete(MODEL_ID_KEY))
            else
              config_values.delete(CONFIG_CLASS_KEY).constantize.new
            end

            config_values.each do |key, value|
              cache_key = config_object.set_preference(key, value)
              config_hash[cache_key] = value
            end
          rescue StandardError => e
            if e.is_a?(ActiveRecord::ActiveRecordError)
              handle_activerecord_error(e)
            else
              raise e unless e.message =~ /database .* does not exist/ && !Rails.env.production?
            end
          rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound => e
            handle_activerecord_error(e)
          end
        end

        Spree::Preferences::InMemoryStore.instance.add_config_values!(config_hash)
      end

      def handle_activerecord_error(error)
        raise error if Rails.env.production?
        puts "**** WARNING **** Spree::ConfigPreferenceLoader unable to load record from database"
        puts error.message
      end

    end
  end
end

