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
        load_configurations(file, true)
      end

      private

      def load_configurations(file, is_model = false)
        yaml_config = YAML.load_file(file)[Rails.env]

        config_hash = {}
        yaml_config.each do |config_key, config_values|
          config_object = if is_model
             config_values.delete(MODEL_CLASS_KEY).constantize.find(config_values.delete(MODEL_ID_KEY))
          else
            config_values.delete(CONFIG_CLASS_KEY).constantize.new
          end

          config_values.each do |key, value|
            cache_key = config_object.preference_cache_key(key)
            config_hash[cache_key] = value
          end
        end

        Spree::Preferences::InMemoryStore.instance.add_config_values!(config_hash)
      end

    end
  end
end

